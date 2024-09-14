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
>> signed 8'b1111 0001 == 8'sd-15
```

因此，在获得最高位为 1 的二进制有符号数时，需要经过如下方法计算才能知道对应的十进制数：

  1. 减去 1；
  2. 按位取反；
  3. 计算对应的十进制数，并添加负号。

现在来考虑将一个较小位宽的有符号数赋值给一个较大位宽的有符号数。假设有：

```verilog
reg signed [3:0] b;
reg signed [7:0] c;

always @(*) begin
  b = 4'sb1011; // b = -5 in decimal
  c = b;
end
```

`b` 是 4 位的有符号数，值为 `4'sb1011`，其二进制表示是 1011，对应十进制的 -5（因为最高位 1 表示负数，采用补码表示）。

当将 `b` 幅值给 `c` 时需要进行符号扩展:

`b` 的符号位是 1（表示负数）。当 `b` 被赋值给 `c` 时，`c` 需要扩展到 8 位。为了保持原始值的符号和数值，Verilog 会将 `b` 的符号位（1）扩展到 `c` 的高位。因此，`c` 会变为 `8'sb11111011`。

`c` 的值将是 `11111011`，也就是十进制的 -5。通过符号扩展，Verilog 确保了即使位宽增加，数值仍然保持不变。

# 整数、定点数和浮点数的区别

## 整数

整数是最简单的数值表示，它没有小数部分，仅用于表示正数或负数的整数值。

表示范围：整数的表示范围由位宽决定。例如，一个 8 位的无符号整数可以表示 0 到 255（ $2^8-1$ ），而一个 8 位有符号整数可以表示 -128 到 127（使用补码表示法）。

例如：

  * 8 位无符号整数（`uint8_t`）：表示范围为 0 到 255。
  * 8 位有符号整数（`int8_t`）：表示范围为 -128 到 127。

## 定点数 

定点数是介于整数和浮点数之间的一种数值表示方式，允许在固定的位置进行小数点的运算。定点数使用固定的位宽来表示数值，同时定义了一部分位用于表示整数，另一部分位用于表示小数。定点数通常被用于硬件设计中（例如 FPGA、DSP 等），因为它能够在较小的位宽下表示带小数的数值。

定点数由位宽和小数点位置决定。假设我们有一个 16 位定点数：

  * 整数部分：前 8 位。
  * 小数部分：后 8 位。

例如：

假设有一个 8 位定点数表示形式为 Q4.4，即 4 位用于整数部分，4 位用于小数部分。假设这个定点数为 `00011010`：

  * 二进制数：`0001 1010` ；
  * 整数部分：前 4 位 `0001` 表示 $1$ ；
  * 小数部分：后 4 位 `1010` 表示 $10/16=0.625$ ；
  * 实际值： $1.625$ 。


## 浮点数

浮点数的一般形式为：

$$\text{浮点数}=\text{码值} \times 2^{\text{数位}}$$

例如，浮点数 `1.25` 二进制表示为：

  * 整数部分： $1$ ；
  * 小数部分： $01$ ；
  * 合并为： $1.01$ 。

