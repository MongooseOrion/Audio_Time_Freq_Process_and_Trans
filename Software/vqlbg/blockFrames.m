function M3 = blockFrames(s, fs, m, n) % ���ź�s���з�֡���ֶΣ��Ӵ���

% s �����ź�
% fs ����Ƶ��
% m����֡��ʼ֮��ľ��루m=100��
% n��һ֮֡�еĲ������� ��n=256��

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
M3(:, i) = fft(M2(:, i)); % M3�ǰ������п�ܵľ���
end