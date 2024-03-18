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
# �з����������룩���޷�����ת������

��Ƶ�ļ��Ĳ����������з����������룩��ʾ������Χ�Ʋο���ƽ��������Ϊ���ͳ���Ϊ���ķ�ֵ���ݡ������ FPGA �д���ʱ��Ӧ���ǵ�������ķ�ֵ���������������������㷽��������������������������

���ڶ����������ԣ������������ݱ�ʾ�������������޷��ű�ʾ��������������λ��Ϊ��ֵ��Чλ�����磺

```
8'b1000 0000 == 8'd128
```

���ʾ��ΧΪ `0~255` ��

�������з��ű�ʾ��������ô���λ����Ϊ�����ű�ʾλ�����λΪ 0 �����Ϊ������Ϊ 1 �����Ϊ��������˻�����һλ����λ������޷��������ԣ��� 8 λ�����ܱ�ʾ�����ݷ�Χ��Ϊ `-128~+127`��

���������ʱ���з���������ʾ�����������������������λ�����𣬶��ǲ����� �����롱 ��ʽ���洢�з�����������������������޷�������ͬһ��ʾ������������Ǹ���������Ҫ�ر����㣺���Ȼ�������ֵ��Ȼ��λȡ��������ټ��� 1����Ϊʵ�ʵ�ֵ��������ʾ��ʮ�������� `-15` ��ʾΪ�з��Ŷ����Ʊ�ʾ�����㷽����

```
// ��� -15 �ľ���ֵ
signed 8'b0000 1111 == 8'd+15       // +15 ���з��ű�ʾ����

// ��λȡ��
>> signed 8'b1111 0000

// �� 1 
>> signed 8'b1111 0001 == 8'd-15
```

��ˣ��ڻ�����λΪ 1 �Ķ������з�����ʱ����Ҫ�������·����������֪����Ӧ��ʮ��������

  1. ��ȥ 1��
  2. ��λȡ����
  3. �����Ӧ��ʮ�������������Ӹ��š�
