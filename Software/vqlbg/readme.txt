步骤：
1 训练
在Command windows中输入
train('train\',8) 
这是将train文件夹中的wav文件进行特征提取并产生VQ码本，

2 识别
在Command windows中输入
test('test/',8,ans)
其中的ans 就是步骤1产生的码本。此时就会显示结果。

注：
在制作训练集和测试集的时候，为了方便知道结果是否正确，我将
train文件里s1-s4的说话者的录音对应为test文件夹里s1-s4的逆序
train文件里s5-s8对应test文件夹里s5-s8，由运行结果可知程序是正确的。

分工：

陈蔓：trian()说话人识别测试、test()训练出语音文件、Demo显示出产生的所有图表

丘柏俊：blockFrames对信号进行分帧（分段，加窗）、mfcc特征提取、mel过滤器组


朱海霞：disteu() 求欧式距离、vqlbg（）用lbg算法形成码本

拟解决问题：
1.比赛要求的数据集庞大且命名无规则
2.比赛要求输出的.csv文件格式






 
 