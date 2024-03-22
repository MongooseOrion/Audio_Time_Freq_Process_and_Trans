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
# 使用 UART 对板上的功能控制说明

| 控制信道[3:0] | 说明 | 受支持的值[3:0] |
| :--- | :--- | :--- |
| 4'b0010 | 使用基本功能 | 4'b0001：实时人声调整<br>4'b0010：音频回声消除<br>4'b0011：音频去噪<br>4'b0100：背景声与人声分离 |
| 4'b0100 | 对音频进行实时人物画像 | 不限 |
| 4'b1000 | 对音频实时人声分类、变声检测 | 不限 |
| 4'b1001 | 对音频实时声纹识别 | 不限 |