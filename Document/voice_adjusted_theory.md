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
# 回声消除、去噪和音色调整的原理

## 回声消除原理

由于声波在传播过程中遇到了墙壁或其他障碍物而反射，会导致回声影响。当录制音频时，这种反射会被同时记录下来，导致原始声音与回声的重叠。通过引入一定程度的信号延迟，并通过信号加权相减的方式可以消除延迟引起的回声。

具体而言，可以采用一种简单的线性加权相减方式，信号输出函数如下述公式所示：

$$y(n)=x(n) - \alpha x(n-N)$$

其中， $x(n)$ 表示序列索引为 $n$ 的量化数据， $\alpha$ 表示权重系数， $N$ 表示延迟样本数（窗口样本）。

上述公式通过引入延迟并进行加权相减的处理，尽量减少了原始信号与延迟信号之间的重叠，从而减少了回声的影响。

## 音色调整原理

在进行人声调整时，人声的基音频率是一个重要的参数。在频域分析中，基音频率和其谐波通常会在频谱图中呈现为峰值。这些峰值对应于声音信号中不同频率成分的能量。基音频率对应于声谱图中的第一个主要峰值，而其他谐波对应于较高的峰值，其频率是基音频率的整数倍。

男性的声音通常具有较低的基音频率，而女性的声音则具有较高的基音频率。通过增加声音的基音频率，可以使男性声音听起来更像女性声音。这通常通过改变基音周期来实现。

## 去除背景声原理

去除音频中背景声的基本原理是抑制频域中的某些频率成分的幅值，和（或）提升某些频率成分的幅值。然而在 FPGA 流式处理的过程中，如果 FFT 窗口宽度与滑动步长相同，也即每次处理的批数据两两均无重叠，则输出的声音可能会有咔哒声，这是因为每次处理的数据流都是孤立的，那么在频域进行处理后反傅里叶变换时前一段序列与后一段序列间不是平滑变化的，而是呈现出峰值。

为了使得流式处理时音频是平滑、连续的，滑动处理的步长应当小于 FFT 窗口宽度，例如 $\frac{1}{2}$ 。如下图所示：



对于重叠 FFT 处理的部分，可以在 FFT 正变换前和 FFT 逆变换之后分别应用正弦窗函数。这是因为正弦窗乘以正弦窗等于汉宁窗，而汉宁窗重叠一半相加恒等于 1，所以如果在正变换之前和逆变换之后分别应用正弦窗，然后再对序列重叠相加，就可以得到较好效果的信号。