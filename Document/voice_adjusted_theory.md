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

