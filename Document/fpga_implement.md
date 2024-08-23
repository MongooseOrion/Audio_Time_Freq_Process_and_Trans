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
* FILE ENCODER TYPE: GBK
* ========================================================================
-->
# 相关功能的 FPGA 实现 

## 声纹识别 

### 音频数据幅值归一化

为使性能不受输入音频音量的影响，需要对数据进行归一化。在 FPGA 实现上，通过短时能量检测有效音频，将整段有效音频数据存储进 DDR3，然后将数据均乘以 65536，再除以绝对值最大的数值，实现归一化，并保证数据范围在 -65536~65535 之内。

### 声纹特征提取

系统采用梅尔倒谱系数（Mel-scale Frequency Cepstral Coefficients，MFCC）作为用于 VQ 计算的特征参数，设置梅尔滤波器组由 30 个滤波器组成，因此每个 FFT 帧计算出 31 个 MFCC 系数。

为确保输出特征参数稳定，系统设置捕获的音频数据帧数量为活动值，通过双门限法截取输入音频数据的有效部分，然后逐帧 FFT，帧长为 1024，滑窗宽度为 768，数量最大为 400 帧，约 6s。最后在特征提取阶段可获得维度为 $31\times M,M\in [70,400]$ 的特征矩阵。

每一帧 MFCC 提取的流程如下：

  1. **预处理**：对输入的音频信号进行预加重处理，以增强高频部分的能量，这有助于平衡频谱，提升后续特征提取的效果，例化一个乘法器IP核即可实现。
  2. **分帧加窗**：将预处理后的音频信号帧长设置为 1024，帧移设置为 768，窗函数设置成汉明窗，窗函数的作用是将帧的边缘信号逐渐衰减，以减少频谱中的假频成分，为了减少 FPGA 资源使用，已将汉明窗量化成 9bit 固化在 ROM 中。
  3. **求能量谱**：对加窗后的每一帧信号进行 FFT，以将时域信号转换为频域信号，再求实部虚部的平方和得到能量谱。
  4. **梅尔滤波器组**：将频谱映射到梅尔频率尺度上，应用一组三角滤波器。梅尔尺度是基于人耳对频率的感知定义的，低频部分分辨率高，高频部分分辨率低。在该模块中，使用固定的 31 组梅尔滤波器，为了减少 FPGA 资源开销，已在 matlab 中应用梅尔滤波器计算公式计算滤波系数且小数部分量化并导出然后固化到 ROM 中。
  5. **对数功率谱**：对通过梅尔滤波器组的结果取自然对数。由于PDS没有自然对数 IP 核，故在该模块中对数计算通过查表法的方式计算。
  6. **离散余弦变换（DCT）**：对得到的梅尔频率对数能量谱进行离散余弦变换，得到最终倒谱系数（MFCC）。其中，DCT 系数通过在 matlab 中使用 DCT 计算公式导出，量化后的固化到 FPGA ROM 中。

### 声纹训练

系统采用 VQ-LBG 算法作为训练和识别的算法，其中训练阶段用于迭代的码矢数量设置为 $N=16$ ，失真阈值设置为 0.02（FPGA 实际运算是 3/127）。因此，存储到 RAM 中的矩阵维度为 $31 \times 16 \times 4$ 。

生成码本流程如下（采用状态机实现）：
  1. **初始化**：对多组特征向量求得平均值作为初始码本。
  2. **码本分裂**：通过在初始码本中心上添加微小的扰动来分裂成新的码本（码矢数量翻倍）。这种扰动通常是一个小值，如 0.02（FPGA 实际运算是 3/128），并分别加到初始码本中心和减去初始码本中心，形成两个初始簇。
  3. **迭代优化**：聚类，计算MFCC特征到码本的欧氏几何距离，然后找出每个码矢到MFCC特征欧氏几何距离最小的列。将这些列求均值更新该列码本。计算失真度量：计算量化误差，即每个特征向量与其所属簇中心之间的距离的平方和。判断是否达到收敛条件（如失真度量变化小于设定阈值），否则继续迭代。
  4. 重复码本分裂生成新的码本，并重复迭代优化过程，直到码本数量达到预定值。
  5. **终止条件**：当码本的数量达到预定值且迭代计算的变化小于设定的阈值时，算法终止。

### 声纹识别

在执行声纹识别时，系统通过计算输入特征向量在 $P=4$ 个训练数据集（每个数据集有 16 个码矢）上的平均失真测度最小值来判断属于哪个样本的声音，如下式所示。

$$D_{\text{avg}}^{(P)} = \frac{1}{Mk}\sum_{n=0}^{N-1} \text{min}(||x_m - c_n^{(P)}||^2),\quad m=0,1,2,\dots, M-1$$

其中， $k$ 表示码矢的维度， $x_m$ 表示输入特征向量， $c_n$ 表示训练得到的码矢， 记 $||x_m - c_n^{(P)}||^2$ 为欧式几何距离。

## 去噪和声音分离

### 给定音频

在设计时，去噪功能与声音分离功能只需固化不同 ROM 的配置文件，例化成两个模块即可。去噪模块分为 46 个处理段，多重声音分离模块分为 45 个处理段，每段满足 21 个 1024 FFT 处理帧。由于是实时处理，音频起始点通过采用双门限算法检测。

### 自适应去除稳态噪声

当启动该功能时，系统会采集约 1.5s 的声音数据，并进行短时傅里叶变换，将在这个期间所有进行 FFT 的结果幅值累加，最后使用排序算法按照从大到小的进行排序（排序前 30），这些结果所对应的频率即为需要抑制的底噪或者噪声，将需要抑制的频段写入 RAM 中。