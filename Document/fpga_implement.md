<!-- =====================================================================
* Copyright (c) 2023, MongooseOrion.
* All rights reserved.
*
* The following code snippet may contain portions that are derived from
* OPEN-SOURCE communities, and these portions will be licensed with: 
*
* <NULL>
*
* If there is no OPEN-SOURCE licenses are listed, it indicates none of
* content in this Code document is sourced from OPEN-SOURCE communities. 
*
* In this case, the document is protected by copyright, and any use of
* all or part of its content by individuals, organizations, or companies
* without authorization is prohibited, unless the project repository
* associated with this document has added relevant OPEN-SOURCE licenses
* by github.com/MongooseOrion. 
*
* Please make sure using the content of this document in accordance with 
* the respective OPEN-SOURCE licenses. 
* 
* THIS CODE IS PROVIDED BY https://github.com/MongooseOrion. 
* FILE ENCODER TYPE: UTF-8
* ========================================================================
-->
# 相关功能的 FPGA 实现 

## 短时能量和短时过零率计算实现

### 过零率

过零率（Zero Crossing Rate, ZCR）是衡量语音信号中符号变化频率的指标，反映了信号的频率内容。

  * 经过阈值判断的过零率（`zeroCrossing_cnt`）:
      
      当信号的符号位（最高位，`wr_data[15]`）与前一时刻信号的符号位不同（即从正到负或从负到正的过零情况），且信号的绝对值大于给定的阈值或小于时，过零次数 `zeroCrossing_cnt` 加 1。

  * 未经阈值判断的过零率（`zeroCrossing_cnt2`）:
      
      同样地，当前后两个信号的符号位不同，无论信号的幅度大小，`zeroCrossing_cnt2` 都会加 1。

### 短时能量

短时能量用于衡量语音信号在某个短时间段内的能量大小，这对于检测语音信号的存在与否非常有效。

在时钟的上升沿，信号被累加到 `short_time_energy` 中（由于是有符号数，因此负数就应该是减），用于计算短时能量。

如果累加的短时能量超过总的阈值 `threshold_hign`，能量值会被保持（即能量不会再增加）。

在每 512 个时钟周期后，`short_time_energy` 被重置为零，以开始新一轮的累加。

### 语音标志的设置

在每 512 个时钟周期后，`voice_flag` 会根据当前的 `short_time_energy` 大小决定是否设置为 1。

如果短时能量超过阈值 `threshold_hign`，则标志 `voice_flag` 被置为 1，表明当前帧中可能包含有效的语音信号。

## 声纹识别功能

### 音频数据幅值归一化

为使性能不受输入音频音量的影响，需要对数据进行归一化。通过双门限法检测有效音频，然后将有效音频数据存储进 DDR3，当音频数据连续小于阈值 0.6s 或者达到最大地址计数值 `MFCC_ADDR_MAX`，停止存储 DDR。然后将数据读出，均乘以 65536，再除以绝对值最大的数值，实现归一化，并保证数据范围在 -65536~65535 之内。

在 FPGA 实现上，涉及三个模块的信号处理操作：

  * 在 MFCC 特征提取模块发出 `voice_flag` 信号指示帧是有效还是无效。
  * 使用 `voice_flag` 来控制 AXI 写模块，当为高（即认为当前帧数据有效）时开始存数据，并向外发出监听幅值最大值信号 `mfcc_valid_1` 。当 `voice_flag` 从高变低（即认为当前帧是无效数据）时开始计数，直到该信号连续为低计数到 $60000000/100\text{MHz}\approx 0.6$ 秒，又或者是写入 DDR 的数据达到最大地址 `MFCC_ADDR_MAX` 时，停止存储，并发出一个 AXI 读指示信号 `rd_start`。
  * 使用 `mfcc_valid_1` 作为使能信号，在 AXI 写模块写数据的同时，在 AXI 读模块中监听幅值的最大值。当 `rd_start` 为高时，读取 DDR 的数据，并乘以 65536（向左移位 16 位）再除以绝对值最大的数值。此处使用的是逐位减法的方法来实现除法运算，需要 32 个时钟周期来完成一次除法运算。

### 声纹特征提取

系统采用 MFCC 作为用于 VQ 计算的特征参数，设置梅尔滤波器组由 30 个滤波器组成，因此每个 FFT 帧计算出 31 个 MFCC 系数。

为确保输出特征参数稳定，系统设置捕获的音频数据帧数量为活动值，通过双门限法截取输入音频数据的有效部分，然后逐帧 FFT，帧长为 1024，滑窗宽度为 768，数量最大为 400 帧，约 6s。最后在特征提取阶段可获得维度为 $31\times M,M\in [70,400]$ 的特征矩阵。

每一帧 MFCC 提取的流程如下：

#### 预加重
      
预加重是一种常见的处理步骤，用于增强高频成分。预加重通常通过一个简单的高通滤波器实现，其公式为：

$$y[n] = x[n] - \alpha \cdot x[n-1]$$

其中， $y[n]$ 是预加重后的信号， $x[n]$ 是原始信号， $\alpha$ 是预加重系数。

在 FPGA 实现中，通过一个简单的乘法器模块 `simple_multi_16x9` 来实现预加重系数的乘法运算，输入 `a` 是 16 位的 `data_in`，输入 `b` 是 9 位的常数 `16`，乘法器的输出 `p` 是 25 位的 `pre_p`，通过将 `pre_p` 右移 9 位实现除以 512，因此 $\alpha = 16/512$，由于乘法器需要一个周期才能计算出结果，因此实现的功能就是 $\alpha \cdot x[n-1]$。

#### 分帧加窗

将预处理后的音频信号帧长设置为 1024，帧移设置为 768，窗函数设置成汉明窗，窗函数的作用是将帧的边缘信号逐渐衰减，以减少频谱泄露。汉明窗量化成 8bit 固化在 ROM 中，由于帧长为 1024，因此 ROM 地址数也应该是 1024。

通过乘法器将一帧内的每个样本与窗函数的对应系数相乘，即可实现加窗，显然样本索引就是 ROM 地址。

值得注意的是，帧的数量就对应于产生的 MFCC 向量数量，因此通过在此计数帧数量，就可以为后续的训练模块提供 MFCC 向量数量信息。此处通过 `mfcc_number` 向外发信，由训练模块接收，以便进行求均值向量操作。 

#### FFT 变换 

由上述分析可知，分帧加窗后的数据至多有 $16+8=24$ 位。由于 FFT IP 核输入为 32 位且高 16 位为虚部、低 16 位为实部，因此送入 FFT 核的部分可以是 `{16{1'b0}, sin_result[23:8]}`。

#### 求能量谱

对加窗后的每一帧信号进行 FFT，再求实部虚部的平方和得到能量谱。在 FPGA 实现上，PDS FFT IP 核计算获得的频域实部虚部数据位宽均为 `DATA_WIDTH + FFT_WINDOW_WIDTH = 16 + log(1024) + 1 = 27`，因此实部为 `xk_axi4s_data_tdata_real = xk_axi4s_data_tdata[26:0];`，虚部为 `xk_axi4s_data_tdata_imag = xk_axi4s_data_tdata['d26+'d32:32]`。通过使用两个乘法器来计算实部平方和虚部平方，相加得到能量谱。

FFT IP 核可以得到的最大频谱范围是 48kHz 的一半，即 24kHz，因此 1024 样本数的分辨率为：$24000/1024\approx 23 \text{Hz}$ 。

为降低计算时延，仅对 FFT 结果的前一半（即 512 个数据的实部虚部）进行计算，也足够满足要求，因为 512 个样本数也能达到 12kHz 的范围，这已经是一些人的耳朵可以感知的极限了。
  
#### 梅尔滤波器组

将频谱映射到梅尔频率尺度上，应用多组三角滤波器实现。

具体 FPGA 实现，使用 matlab 生成并量化了 9bit 的梅尔滤波器系数。在[算法细节](./algorithm_specific.md#mfcc-参数计算)中描述了梅尔滤波器的基本数学公式，现在先去掉取对数的部分，令 $|X_a(k)|^2$ 等于 $E[k]$ ，那么式子就可以简化为：

$$S_m = \sum_{k=0}^{N-1} E[k] \cdot H_m(f_k)$$

其中， $S_m$ 表示第 $m$ 个梅尔滤波器的输出， $E(k)$ 表示第 $k$ 个点的能量谱， $H_m(f_k)$ 表示第 $m$ 个梅尔滤波器在第 $k$ 个频率点的系数。

在[梅尔滤波器系数查找表文件](../FPGA/proc_dat/melfb_data.dat)中，你可以发现系数个数正好是 $31 \times 512=15872$ 个。

在代码实现中， $H_m(f_k)$ 表示为 `melfb_rd_data`； $E(k)$ 表示为 `rd_data5`，它的数据来源于上述的对前 512 个数据的实部虚部求平方和的结果； $S_m$ 表示为 `wr_data6`，数量是 31 个，即地址是 31。
  
#### 对数功率谱

对通过梅尔滤波器组的结果取自然对数。由于 PDS 没有自然对数 IP 核，因此对数计算通过固化参数的模块 `log_e_data_rom`，数据通过此模块后，可将 57bit 的数据量化到 39 个数据段内。在代码实现上，是直接与上一段的操作共享 RAM，计算时取数，计算完成后重新存到对应的地址上。假设上一个操作得到的数据信号是 `wr_data6_1`，这一次操作得到的数据信号是 `wr_data6_2`，则实际存到 RAM 的数据为 `wr_data6_act = (MODE==MEL_FILTER) ? wr_data6_1[65:9] : wr_data6_2[56:0]`。

#### 离散余弦变换（DCT）

DCT 系数通过在 matlab 中使用 DCT 计算公式导出，量化后的固化到 FPGA ROM 中。现在我们来简化一下[算法细节](./algorithm_specific.md#mfcc-参数计算)中 DCT 计算公式，令系数 $\cos\left[\frac{\pi n (2m + 1)}{2M}\right] $ 等于 $\varphi$ ，则式子变为：

$$C_n = \sum_{m=0}^{M-1} S_m \cdot \varphi,\quad n=0,1,\dots,M-1$$

因此，DCT 系数应该有 $M^2=31^2=961$ 个，可以发现[DCT 系数查找表文件](../FPGA/proc_dat/dct_data.dat)中系数数量对得上。

$S_m$ 表示为上一步存储到 RAM 中的数据，即 `rd_data6`； $\varphi$ 表示为信号 `dct_rd_data`；通过一个乘法器可以计算 $S_m \cdot \varphi$ ，结果存储在 `p5` 中；在 `DCT_COMPUTE` 状态下，累加 `p5` 的值，结果存储在 `wr_data7` 中，为减少计算开销，取高 9 位；表示 DCT 的输出 `C_n`，它的数量应该是 31 个。

在完成 MFCC 特征提取后，向外发送 `mfcc_extraction_end` 信号。

### 声纹训练

系统采用 VQ-LBG 算法作为训练和识别的算法，其中训练的码矢数量设置为 $N=16$ ，失真阈值设置为 3/127，最大说话人数量为 4。因此，存储到 RAM 中的矩阵维度应该为 $31 \times 16 \times 4$ 。

#### 计算均值模块

模块用于对一个 $31\times \text{frameIndex}$ 的矩阵数据按列求均值。通过使用列索引和行偏移量从外部 RAM 中读取数据，并经过累加和除法运算，最终输出一个长度为 31 的均值向量。具体流程如下：

  1. 配置列索引
      
      通过 `cfg_data` 输入列索引，并写入内部 RAM `mean_cfg_ram`，这样的设计是因为在后续的码矢分裂中可能需要取出不同位置的向量，那么仅需要给出列索引即可定位外部 MFCC RAM 的对应列向量的首地址。
  
  2. 计算列基地址
  
      通过将列索引和预设的向量数据个数 `MEAN_RESULT_NUBMER` 通过乘法器，可以计算列索引对应的外部 RAM 列首地址 `p`。

  3. 累加行数据
  
      通过偏移量 `addr_bias` 就可以确定数据位置，并进行累加 `addr <= p + addr_bias`，即可取数。

  4. 计算均值
  
      `addr` 会顺序取出每列在该行位置的数据，累加后通过除法器，除数 `divide` 是统计出来的 cfg_data 个数，可以直接用 `mean_cfg_ram` 的 `wr_addr` 来代替。

这样就可以依次输出每行的均值，形成一个 $31\times 1$ 的输出向量。

以下的握手信号需注意：

  * `cfg_valid`：主模块请求输入列索引配置数据 `cfg_data`；
  * `o_ready`：从模块准备好接收列索引配置数据 `cfg_data`。当上一笔事务完成时，主模块应拉高 `cfg_last`，当其为高时，从模块也拉高 `o_ready`。
  * `o_valid`：从模块输出均值数据 `o_data` 有效信号。模块设置了输出缓冲（FIFO），在完成了均值向量的所有数据计算后，突发传输输出。

#### 计算欧氏几何距离模块（不开平方）

与计算均值模块相同，通过外部输入的列索引来求取对应的外部 RAM 向量数据基地址。该模块有 3 种工作模式，不同工作模式的地址信号和数据信号有所不同，分别是：

  1. 单列对单列计算欧式距离（`cfg_mode_data[5:4] == 2'b00`）

      此模式计算的是 `cfg_data` 指定的列（输出 RAM 读地址线 `rd_addr_d`）与 `cfg_mode_data[3:0]` 指定的列（输出 RAM 读地址线 `rd_addr_r`）之间的欧式几何距离。通过在状态 `COMPUTE_INIT` 分别给出列基地址后，在状态 `COMPUTE` 分别读取其对应的 31 个数据，两两求平方和再相减，最后全部相加求得平方和 `sum_data`。
      
      由于只有一个数据，未进入缓存，将会直接输出。`o_valid` 也将同步拉高。

  2. 多列对多列计算，输出最小值索引（`cfg_mode_data[5:4] == 2'b01`）

      此模式用于比较一个向量 $\mathbf{\alpha}$ 与多个向量 $\mathbf{\beta_1}, \mathbf{\beta_2}, \dots, \mathbf{\beta_n}$ 之间的欧式距离，当有多个 $\mathbf{\alpha_1}, \mathbf{\alpha_2}, \dots, \mathbf{\alpha_i}$ 时依次输出对应欧氏距离最小的 $\mathbf{\beta}$ 列索引。

      通过 `cfg_mode_data_reg[3:0]` 来配置要进行比较的列索引数 $\mathbf{\beta_n}$ ，由于码矢数量设置为 16，因此可选的数值是 1-15。`cnt_2` 的作用是遍历到指定配置的最后一列，在状态 `COMPUTE_INIT` 中，通过 `rd_addr_d <= p[ADDR_WIDTH-1'b1:0]` 和 `rd_addr_r <= addr_start[cnt2]` 来分别遍历由 `cfg_data` 和 `cnt2` 指定的列。计算的顺序是将 `cfg_data` 指定的向量 $\mathbf{\alpha_i}$ 与每一个 `cnt_2` 指定的向量 $\mathbf{\beta_n}$ 比较，直到 `cfg_data` 也被取完。由于该状态只停留一个周期，因此每次只会取出 2 个向量。注意向量的来源包含 `cfg_data` 和 `addr_start` 两个位置。

      由于模式不同会导致输出缓冲（FIFO）的输入数据有所不同，因此在 `RESULT_SAVE` 状态要进行处理。`cnt4` 计数器递增，用于记录当前正在处理的列号（`addr_start` 来源的索引）。对于第一列数据，不进行比较，直接将其设为当前最小值，并将 `wr_data_fifo` 设置为第一列的索引。然后开始比较这一轮中 `cfg_data` 与每一个 `addr_start[cnt2]` 所代表的向量的欧氏距离，比较过程中更小的欧氏距离所代表的 `addr_start[cnt2]` 的向量索引 `cnt4` 将赋值给 FIFO 写数据信号 `wr_data_fifo`，当比较完成时使能 FIFO 将结果保存到 FIFO 中，直到所有的 `cfg_data`-`addr_start[cnt2]` 向量对比较全部完成。

      因此，FIFO 应该输出与输入 `cfg_data` 数量相同的数据。将突发输出，主设备应准备好接收，`o_valid` 将同步拉高。

  3. 多列对多列，输出每轮比较最小值之和（`cfg_mode_data[5:4] == 2'b10`）

      此模式与模式 2 类似，不同点仅在于模式 3 输出的是一个数值而不是列表。

      累加每一个 $\mathbf{\alpha_i}$ 所对应的欧氏几何距离最小的 $\mathbf{\beta_n}$ 的欧氏距离数值，`sum_data_end1 <= sum_data_end1 + sum_data`。

      由于是 1 个数据，因此直接输出，`o_valid` 会同步拉高。

---

在[算法描述](./algorithm_specific.md#lbg-方法描述)中对整个 LBG 流程有详细的描述，此处不再赘述其数学原理，**生成码本的实现流程如下：**

#### 对全体特征向量求均值向量

在状态 `MFCC_MEAN_CFG` 中，在时钟的上升沿对 `cfg_data` 加 1，直到达到 MFCC 模块输出的 `mfcc_number` 指定的大小。这样就能使得计算均值的模块对全体特征向量求均值向量。将此向量按顺序放到数据线 `vqlbg_wr_data` 上存入 RAM。

#### 码本分裂

通过乘法器和移位，实现加减一个扰动系数（3/128）`p_1` ：

```verilog
vqlbg_division1 <= vqlbg_rd_data_reg + p_1;
vqlbg_division2 <= vqlbg_rd_data_reg - p_1;
```

然后将这两个向量先送入 RAM 缓存。
  
#### 迭代优化

对 MFCC 全部向量应用聚类。计算 MFCC 特征向量到码本的欧氏几何距离，然后找出每个码矢到 MFCC 特征欧氏几何距离最小的列。将这些列求均值更新该列码本。

在状态 `DISTEU_CFG` 中，配置计算欧式距离模块为模式 2：`cfg_mode_data_disteu <={2'b01,cruent_vqlbg_number[cnt2]}`，这样就可获得 MFCC 向量关于码矢 $\mathbf{c_n^{(i)}}$ 集合 $\mathbf{S_n}$ 的相关的索引标识。

在状态 `DISTEU_COMPUTE` 中，配置计算欧氏距离模块为模式 1，以获得确切的欧氏距离数值，`sum_disteu_data` 用于累加计算欧式距离模块输出的多个平方和，这将用于阈值判断，对应于平均失真度指标，是训练终止条件。

在状态 `MEAN_COMPUTE` 中，之前存储在 RAM 中的扰动后的质心向量会被读取出来，用作质心更新的初始值，然后与在状态 `DISTEU_CFG` 中获得的聚类向量组一起计算均值向量，更新后的质心会再次写回 RAM，以便在下一轮迭代中使用。

#### 停止条件

当小于等于失真度阈值并且达到指定迭代次数 `cnt2 == VQLBG_NUMBER - 1'b1` 后，停止训练。

在状态 `RESULT_JUDGMENT` 表示的条件为 `(sum_disteu_data + p2[39:7]) > sum_disteu_data_reg`，即 

$$\frac{D_{\text{avg}}^{i-1}-D_{\text{avg}}^{i}}{D_{\text{avg}}^{i}} < \frac{3}{128}$$

其中 `p_2` 使用乘法器实现。

### 声纹识别

在执行声纹识别时，系统通过计算输入特征向量在 $P=4$ 个训练数据集（每个数据集有 16 个码矢）上的平均失真测度最小值来判断属于哪个样本的声音。

通过 `vqlbg_addr_bias` 规定了 4 个码本在 RAM 中的基地址，计算欧氏几何距离模块被配置为 `6'b101111`，即模式 3，输入的向量与全部向量（码本的全部码矢）进行比对，并依次累加最小欧式几何距离数值，输入向量全部被比较后输出数值。

在 `MEAN_RESULT` 状态中，`cnt1` 用来遍历所有的码书（说话人的码书集合）。在这个状态中，每次计算都会比较当前的欧式距离总和，并更新最小值和相应的码书索引。当 `cnt1 == 'd0` 时，`o_data_disteu_reg` 被初始化为第一个码书的欧式距离总和，`recognition_result` 也被设置为当前码书的索引，在随后的比较中，如果发现当前码书的欧式距离总和比之前的最小值更小（`o_data_disteu_reg > o_data_disteu`），则更新 `o_data_disteu_reg` 和 `recognition_result`。

当遍历所有码书后（`cnt1 == SPEAKER_NUMBER - 1'b1`），输出最终的识别结果 `recognition_result`。如果最小距离超过某个阈值（`22200`），则认为输入向量与任何一个码书都不匹配，并输出无效结果。同时拉高 `recognition_result_flag` 用于指示识别结果的有效性。

值得注意的是，除法器正忙时（`busy`），此功能应当需要等待。

## 去噪和声音分离

### 给定音频

在设计时，去噪功能与声音分离功能只需固化不同 ROM 的配置文件，例化成两个模块即可。去噪模块分为 46 个处理段，多重声音分离模块分为 45 个处理段，每段满足 21 个 1024 FFT 处理帧。由于是实时处理，音频起始点通过采用双门限算法检测。

**具体的流程如下：**

#### 数据预存（2-FIFO 乒乓结构）

FIFO1 缓存 1024 个数据，并在第 512 个数据时同时将数据缓存到 FIFO2 中，在满足 1 个 FFT 帧长样本数量后各取 512 个数据存到 FIFO3 中，这样的操作就可以模拟出 1024 帧长 512 帧移的效果。

#### 加正弦窗

对 FIFO3 读出的数据与 ROM 中固化的[正弦窗数据](../FPGA/proc_dat/sin_window.dat)对应位置的数据相乘，在状态 `SIN_WINDOW` 中将两者数据分别赋值给乘法器的两个输入 `a` 和 `b`。不难发现 sin 窗的系数数据个数也是 1024 个，量化为 8bit。此处只能使用正弦窗，并且必须要求 512 帧移，原因详见[算法细节](./algorithm_specific.md#去除背景声和多重声音分离原理)。

#### 频域处理（如果双门限法使能）

使用双门限法检测有效音频是否到来，是否要进行频域处理，控制信号为 `frame_valid_en`；用于计数每段处理帧数量的信号为 `frame_valid_cnt`，当其到达预设的 21 时，用于计数处理段数量的信号 `frame_CNT` 加 1。

ROM 文件中对频域处理配置数据的存放规则是：行为 1024，代表频率轴；列为 46/45，代表处理段，从左至右为正向。因此在 FFT 数据输出后（状态 `FFT_DATA_OUT`）的每个时钟沿（即代表每个频率）都将增加地址 `noise_addr <= noise_addr + 1'b1` 以取出对应频率的所有分段的数据，根据当前处理段的计数信号来判断应该取出哪一位信号，**因此在 FFT 结果输出的同时，频域处理就同时进行了**。如果这一位数据为 `1'b1` 则将这个频率值的 FFT 数据置为 0，否则不处理，都存储到 RAM 中 `wr_data4`。通过这种方式，即实现了在频域上置零或者不处理的频域滤波器效果。

FFT 后，对实部虚部进行了阈值处理，超出阈值的部分赋阈值，否则赋低 16 位。

使用的是哪一个配置文件（共有噪声抑制、仅提取唱歌人声、提取唱歌人声和说话人声等 6 个频率配置文件）的数据取决于 UART 命令，例如：

```verilog
else if (SPLIT_MODE == 'd1) begin
        split_rd_data <= vocal_rd_data ;
        fft_result_data <= {imag1,real1};
    end
else if (SPLIT_MODE == 'd2) begin
    split_rd_data <= sing_rd_data ;
    fft_result_data <= {imag1,real1};
end
```

#### 反傅里叶变换

在代码设计时，设计了 5 个参与信号处理状态，分别是FFT IP 核模式控制 `FFT_MODE_CFG`、加正弦窗 `SIN_WINDOW`、FFT IP 核数据输入 `FFT_DATA_IN`、FFT IP 核数据输出 `FFT_DATA_OUT` 和 iFFT 数据最终处理 `END_DATA_OUT`，我们分别标识为 `0,1,2,3,4`，一个完整的状态转移流程应该是：`0-1-2-3-0-2-3-(1)-4`（在状态 4 中直接进行加窗操作，因此实际上没有再进入 1）。这是因为 FFT IP 核只需要通过输入不同的模式配置参数即可实现 FFT 或者是 iFFT 功能。

通过读取前述所述的 `wr_data4` RAM 即可返回时域数据。iFFT 后对实部进行了阈值处理，FFT IP 核 iFFT 的结果扩大了 256 位，因此在没有超过阈值的情况下，一般来说实际应该赋值 `[23:8]`。**但是由于此处在 FFT 时加窗操作已经缩小了 256 倍，因此此处应该直接赋值 `[15:0]`，然后进行相关阈值限幅处理**。

注意到，一次处理调用了两次 IP 核，是否可能导致数据来不及处理？答案是不会，因为频域处理使用了 100MHz 的快时钟，FFT 前和 iFFT 经过 FIFO 之后都是 48kHz 的音频采样时钟，快时钟远远快于满时钟。

#### iFFT 后的最终处理

FFT IP 核的特性使得 iFFT 后也包含虚部数据，可以直接丢去。

为实现重叠部分相加，应该将 512-1023 个数据缓存到 FIFO 中，然后将 0-511 个数据与前一次事务中缓存在 FIFO 内的 512-1023 个数据按顺序叠加。重叠相加后幅值超出阈值的部分应该限幅。

请注意在进行上述操作前，需要先对 iFFT 输出的数据应用正弦窗，这个操作可以直接在 IP 核输出一个数据后就立即与对应位置的 sin 窗系数相乘完成，那么就仅耗时一个时钟周期。

### 自适应去除稳态噪声

当启动该功能时，系统会采集约 1.5s 的声音数据，并进行短时傅里叶变换，将在这个期间所有进行 FFT 的结果按频率进行幅值累加，最后使用排序算法按照从大到小的进行排序（排序前 30），这些结果所对应的频率即为需要抑制的底噪或者噪声，将需要抑制的频段写入 RAM 中。