function r = mfcc(s, fs)   %   s�����źŵ�����   fsȡ��Ƶ�� r-mfccϵ��
% MFCC ����ź�s��mfcc����
m = 100;
n = 256;
%Ԥ����
a=0.98;

s = s(:, 1);
% s = s-mean(s);                             % ����ֱ������
% s = s/max(abs(s));                         % ��ֵ��һ��

l=length(s);
for i=2:l
    s1(i)=s(i)-a*s(i-1);%�γ���һ���µ��ź�s1��
end
nbFrame = floor((l - n) / m) + 1;
for i = 1:n
for j = 1:nbFrame
M(i, j) = s1(((j - 1) * m) + i); %�Ծ���M��ֵ
end
end
h = hamming(n); %�� hamming ����������������˺��Ҷ˵�������
M2 = diag(h) * M;
for i = 1:nbFrame
frame(:,i) = floor(36767*fft(M2(:, i)));%���źŽ��п��ٸ���Ҷ�任FFT  
end
t = n / 2;
tmax = l / fs;
m = melfb(20, n, fs);%%����������Ƶ��ͨ��Mel Ƶ���˲�����õ�Mel Ƶ��,�����ڽ���ת���ɶ���Ƶ��
n2 = 1 + floor(n / 2);
z = floor(m * abs(frame(1:n2, :)).^2);
r1 = round(log(z));
r1(r1 < 0) = 0;
r = dct(r1); %����������Ƶ�ף�������ɢ���ұ任(DCT)�任�������򣬼��ɵõ�Mel ����ϵ��(MFCC����)
 save('mfcc1.mat', 'r');
