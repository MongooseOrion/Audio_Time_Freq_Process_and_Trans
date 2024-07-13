function code = train(traindir, n)  % 计算wav文件的VQ码码本，训练出语音文件的码本
k = 8;                             % 码本的容量16

for i = 1:n                         % 为每一个人训练一个vq码本
    file = sprintf('%ss%d.wav', traindir, i);           
    disp(file);
   
    [s, fs] = audioread(file);       %对语音信号进行采样


    v = mfcc(s, fs);               % 计算 MFCC's
   
    code{i} = vqlbg(v, k);         % 训练vq码本
end


