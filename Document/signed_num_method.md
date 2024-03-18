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
# 有符号数（补码）与无符号数转换方法

音频文件的采样序列是有符号数（补码）表示方法，围绕参考电平采样朝向为正和朝向为负的幅值数据。因此在 FPGA 中处理时，应考虑到负半轴的幅值数据是区别于正数的运算方法，以免因计算错误引入杂声。

对于二进制数而言，存在两种数据表示方法。若采用无符号表示方法，则所有数位均为数值有效位，例如：

```
8'b1000 0000 == 8'd128
```

其表示范围为 `0~255` 。

而采用有符号表示方法，那么最高位则作为正负号表示位，最高位为 0 则代表为正数，为 1 则代表为负数。因此会牺牲一位数据位（相对无符号数而言）， 8 位数据能表示的数据范围变为 `-128~+127`。

计算机运算时，有符号数的显示方法并不是正负数仅在最高位有区别，而是采用了 “补码” 方式来存储有符号数。如果是正数，则与无符号数是同一表示方法；而如果是负数，则需要特别运算：首先获得其绝对值，然后按位取反，最后再加上 1，即为实际的值。以下显示了十进制数字 `-15` 显示为有符号二进制表示的运算方法。

```
// 获得 -15 的绝对值
signed 8'b0000 1111 == 8'd+15       // +15 的有符号表示方法

// 按位取反
>> signed 8'b1111 0000

// 补 1 
>> signed 8'b1111 0001 == 8'd-15
```

因此，在获得最高位为 1 的二进制有符号数时，需要经过如下方法计算才能知道对应的十进制数：

  1. 减去 1；
  2. 按位取反；
  3. 计算对应的十进制数，并添加负号。

