# VQ-LBG 算法

步骤：

  1. 训练
      在 Command windows 中输入 train('train\',8)，这是将 train 文件夹中的 wav 文件进行特征提取并产生 VQ 码本。

  2. 识别
      在Command windows中输入 test('test/',8,ans), 其中的 ans 就是步骤 1 产生的码本。此时就会显示结果。

注：
在制作训练集和测试集的时候，为了方便知道结果是否正确，我将 train 文件里 s1-s4 的说话者的录音对应为 test 文件夹里 s1-s4 的逆序

train文件里s5-s8对应test文件夹里s5-s8，由运行结果可知程序是正确的。
