function code = train(traindir, n)  % ����wav�ļ���VQ���뱾��ѵ���������ļ����뱾
k = 8;                             % �뱾������16

for i = 1:n                         % Ϊÿһ����ѵ��һ��vq�뱾
    file = sprintf('%ss%d.wav', traindir, i);           
    disp(file);
   
    [s, fs] = audioread(file);       %�������źŽ��в���


    v = mfcc(s, fs);               % ���� MFCC's
   
    code{i} = vqlbg(v, k);         % ѵ��vq�뱾
end


