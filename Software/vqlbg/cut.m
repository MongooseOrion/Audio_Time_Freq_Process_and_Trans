
function [y1,fs]=cut(s_address)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function: cut() 把静音段裁剪掉
% input :   音频文件地址
% output:   裁剪之后的音频
% author:   yuhansgg（Shi Gaige）
% time:     2017.4.9
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[y,fs]=audioread(s_address);
h=hamming(320);
y = y(:, 1); 
plot(y);
% 计算短时平均能量SAE（short average energe）
%信号的平方在与窗函数相卷
% E(n)＝[x(m)]^2*h(n-m),m从负无穷到正无穷求和，h(n-m)为汉明窗
e=conv(y.*y,h);    % y.*2对y中各元素平方；conv(u,v) 求u与v的卷积

% 对语音信号进行切割，当SAE小于能量大值的1/100时，认为是起点或终点

mx=max(e);
n=length(e);
y(n)=0; % 将原始语音信号矩阵扩充至n维
for i=1:n
    if e(i)<mx*0.01
        e(i)=0;
    else e(i)=1;    % e中非0的数用1来代替
    end
end
y1=y.*e;
y1(find(y1==0))=[]; % 把0元素剔除

pause(5);
plot(y1);
%fs=16000;
%audiowrite(s_address,y1,fs);
