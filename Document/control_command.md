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
# ʹ�� UART �԰��ϵĹ��ܿ���˵��

| �����ŵ�[7:4] | ˵�� | ��֧�ֵ�ֵ[3:0] |
| :--- | :--- | :--- |
| 4'b0000    | loop �ش� | ���� |
| 4'b0001    | �������� | 4'b0001�������ӳ�ϵ��<br>4'b0010�������ӳ�ϵ��<br>4'b1001������˥��ϵ��<br>4'b1010����С˥��ϵ��<br> |
| 4'b0010    | ʵʱ�������� | 4'b0001��������<br>4'b0010����Ů��|
| 4'b0011    | ��Ƶȥ��  | 4'b0000��������Ƶ 1 ȥ��<br> 4'b0001��������Ƶ 2 ȥ��|
| 4'b0100 | �������� | 4'b0001�������˵������������������ȥ����<br> 4'b0010����������� <br> 4'b0011��ȥ�������е�����<br>  4'b0100�����������������  <br>4'b0101������������е�����|
| 4'b0101    | ����ѧϰ��ʶ�� | 4��b000x, x=1,2,3,4��ѵ������Ϊ x ���������� <br>4'b1000��ʶ�����|
| 4'b1000 | ����Ƶʵʱ�������ࡢ������� | ���� |
| 4'b1001 | ����Ƶʵʱ����ʶ�� | ���� |
| 4'b1010 | ��Ƶ¼�� | 4'b0001����ʼ¼�� <br> 4'b0010��ֹͣ¼��<br> 4'b0000�����´ӵ�һ�ο�ʼ¼�� <br> 4'b1xxx�����ŵ�x��¼�Ƶ���Ƶ|