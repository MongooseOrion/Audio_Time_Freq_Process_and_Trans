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
# 基于时间抽取（Decimation-In-Time, DIT）的 Radix-2 FFT 算法

Radix-2 FFT 是一种特殊的 FFT 算法，它的基本思想是 “分治法”（Divide and Conquer）。在每一步中，算法将长度为 $N$ 的序列分解为两个长度为 $N/2$ 的子序列，分别进行处理，最后将结果组合起来。

## 数据重排

在计算 Radix-2 FFT 之前，首先需要对输入数据序列进行“按位反转”（Bit-Reversal）重排。假设 $N=8$ ：

原序列索引：

```
3'b000, 3'b001, 3'b010, 3'b011, 3'b100, 3'b101, 3'b110, 3'b111
```

将其数位顺序调换，高位变低位，低位变高位，则原序列变为：

```
3'b000, 3'b100, 3'b010, 3'b110, 3'b001, 3'b101, 3'b011, 3'b111
```

按位反转后，数据的顺序如下：

原序列：x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7]

重排后：x[0], x[4], x[2], x[6], x[1], x[5], x[3], x[7]

## 递归分解

首先，观察 DFT 公式，可以将 $n$ 分为偶数和奇数：

$$X[k] = \sum_{n=0}^{N-1} x[n] \cdot e^{-j\frac{2\pi}{N}kn}$$

将 $n$ 分为偶数 $2m$ 和奇数 $2m+1$ ：

$$X[k] = \sum_{m=0}^{\frac{N}{2}-1}x[2m] \cdot e^{-j\frac{2\pi}{N}k(2m)} + \sum_{m=0}^{\frac{N}{2}-1} x[2m+1] \cdot e^{-j\frac{2\pi}{N}k(2m+1)}$$

将旋转因子 $W_N = e^{-j\frac{2\pi}{N}}$ 引入，得到：

$$X[k] = \sum_{m=0}^{\frac{N}{2}-1}x[2m] \cdot e^{-j\frac{2\pi}{N/2}km} + e^{-j\frac{2\pi}{N}} \sum_{m=0}^{\frac{N}{2}-1} x[2m+1] \cdot e^{-j\frac{2\pi}{N/2}km}$$

进一步简化得：

$$X[k] = X_{\text{even}}[k] + W_N^k \cdot X_{\text{odd}}[k]$$

$$X[k+{N/2}] = X_{\text{even}}[k] - W_N^k \cdot X_{\text{odd}}[k]$$

其中， $X_{\text{even}}[k]$ 是对偶数序列 $x[2m]$ 计算得 $N/2$ 点 DFT； $X_{\text{odd}}[k]$ 是对奇数序列 $x[2m+1]$ 计算得 $N/2$ 点 DFT； $W_N^k$ 是旋转因子。

### 递归分解的层次

在 FPGA 部署算法时，需要先计算出来每一个 FFT 点的对应的计算参数，画出信号流图，这就需要一步一步分解得到。假设 $N=8$ ，那么就需要 $\log_2(8)=3$ 层，从后往前依次推导。

#### 第三层蝶形运算参数

<div align='center'><img src='.\pic\屏幕截图 2024-09-03 173758.png' width='300px'></div>

右端以 4 个为一组，从偶数区域指向奇数区域，或者从奇数区域指向偶数区域。

#### 第二层蝶形运算

<div align='center'><img src='.\pic\屏幕截图 2024-09-03 174104.png' width='350px'></div>

按照前述的规则，这时按 2 个分组，分别指向对向位置。

#### 第一层蝶形运算

<div align='center'><img src='.\pic\屏幕截图 2024-09-03 174409.png' width='350px'></div>

此时按 1 个分组，分别指向对向位置。注意到左边就是按照前面所做的数据重排的顺序排列的。

根据该信号流图，即可得到给定 FFT 点 $X[k]$ 对应的计算公式。

### 