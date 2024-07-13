function r = mfcc(s, fs)   %   s声音信号的向量   fs取样频率 r-mfcc系数
% MFCC 求解信号s的mfcc参数
m = 100;
n = 256;
%预加重
a=0.98;

s = s(:, 1);
% s = s-mean(s);                             % 消除直流分量
% s = s/max(abs(s));                         % 幅值归一化

l=length(s);
for i=2:l
    s1(i)=s(i)-a*s(i-1);%形成了一个新的信号s1；
end
nbFrame = floor((l - n) / m) + 1;
for i = 1:n
for j = 1:nbFrame
M(i, j) = s1(((j - 1) * m) + i); %对矩阵M赋值
end
end
h = hamming(n); %加 hamming 窗，以增加音框左端和右端的连续性
M2 = diag(h) * M;
for i = 1:nbFrame
frame(:,i) = floor(36767*fft(M2(:, i)));%对信号进行快速傅里叶变换FFT  
end
t = n / 2;
tmax = l / fs;
m = melfb(20, n, fs);%%将上述线性频谱通过Mel 频率滤波器组得到Mel 频谱,下面在将其转化成对数频谱
n2 = 1 + floor(n / 2);
z = floor(m * abs(frame(1:n2, :)).^2);
r1 = round(log(z));
r1(r1 < 0) = 0;
r = dct(r1); %将上述对数频谱，经过离散余弦变换(DCT)变换到倒谱域，即可得到Mel 倒谱系数(MFCC参数)
 save('mfcc1.mat', 'r');
