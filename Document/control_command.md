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

| 控制信道[7:4] | 说明 | 受支持的值[3:0] |
| :--- | :--- | :--- |
| 4'b0000 | 音频回传 | 不限 |
| 4'b0001 | 回声消除 | 4'b0001：增加延迟系数 $N$ <br>4'b0010：减小延迟系数 $N$ <br>4'b1001：增大衰减系数 $\alpha$ <br>4'b1010：减小衰减系数 $\alpha$ <br> |
| 4'b0010 | 实时人声调整 | 4'b0001：变得低沉<br>4'b0010：变得尖锐 |
| 4'b0011 | 音频去噪  | 4'b0000：给定音频 1 去噪<br> 4'b0001：伪自适应去噪 |
| 4'b0100 | 人声分离 | 4'b0001：仅保留说话的人声<br> 4'b0010：保留旋律和唱歌的人声 <br> 4'b0011：保留唱歌人声和说话的人声<br>  4'b0100：仅保留旋律  <br>4'b0101：仅保留唱歌的人声 |
| 4'b0101 | 声纹训练和识别 | 4'b000x, x=1,2,3,4：训练索引为 x 的人声声纹 <br>4'b1000：识别当前输入的人声 |
| 4'b1010 | 音频录音 | 4'b0001：开始录制 <br> 4'b0010：停止录制<br> 4'b0000：重新从第一段开始录制 <br> 4'b1xxx：播放第 x 段录制的音频 |