function M3 = blockFrames(s, fs, m, n) % 对信号s进行分帧（分段，加窗）

% s 输入信号
% fs 采样频率
% m是两帧开始之间的距离（m=100）
% n是一帧之中的采样点数 （n=256）

l = length(s); 
nbFrame = floor((l - n) / m) + 1;
for i = 1:n
for j = 1:nbFrame
M(i, j) = s(((j - 1) * m) + i);
end
end
h = hamming(n);
M2 = diag(h) * M;
for i = 1:nbFrame
M3(:, i) = fft(M2(:, i)); % M3是包含所有框架的矩阵
end