% Demo��ʾ������������ͼ���֤�����ǵĽ���
 
[s1 fs1] = wavread('train\s1.wav');
[s2 fs2] = wavread('train\s2.wav');
%Question 2��S1-�����źţ�fs1-����Ƶ�ʣ�wavread��file��--�������ļ�file�����ز�������s1�Ͳ�������f1
disp('> Question 2');
t = 0:1/fs1:(length(s1) - 1)/fs1;
plot(t, s1), axis([0, (length(s1) - 1)/fs1 -0.4 0.5]);
title('Plot of signal s1.wav');
xlabel('Time [s]');
ylabel('Amplitude (normalized)')
pause
close all
%Question 3 (linear)
disp('> Question 3: linear spectrum plot'); %������ͼ
M = 100;%�������źŽ��з�֡��ÿ֡����256�������㣬M-��֮֡��ľ���
N = 256;
frames = blockFrames(s1, fs1, M, N);
t = N / 2;
tm = length(s1) / fs1;
subplot(121);%������ͼ��1-X�ᣬ2-Y��У�1-��ͼ�ϵ��ĸ�����
imagesc([0 tm], [0 fs1/2], abs(frames(1:t, :)).^2), axis xy;
title('Power Spectrum (M = 100, N = 256)');
xlabel('Time [s]');
ylabel('Frequency [Hz]');
colorbar;
%Question 3 (logarithmic)
disp('> Question 3: logarithmic spectrum plot'); %������ͼ
subplot(122);
imagesc([0 tm], [0 fs1/2], 20 * log10(abs(frames(1:t, :)).^2)), axis xy;
title('Logarithmic Power Spectrum (M = 100, N = 256)');
xlabel('Time [s]');
ylabel('Frequency [Hz]');
colorbar;
D=get(gcf,'Position');
set(gcf,'Position',round([D(1)*.5 D(2)*.5 D(3)*2 D(4)*1.3]))
pause
close all
%Question 4
disp('> Question 4: Plots for different values for N');% N�Ĳ�ֵͬ�Ļ�ͼ
lN = [128 256 512];%�ı�ÿ֡�вɼ���ĸ���N
u=220;
for i = 1:length(lN)
N = lN(i);
M = round(N / 3);
frames = blockFrames(s1, fs1, M, N);
t = N / 2;
temp = size(frames);
nbframes = temp(2);
u=u+1;
subplot(u)
imagesc([0 tm], [0 fs1/2], 20 * log10(abs(frames(1:t, :)).^2)), axis xy;
 
title(sprintf('Power Spectrum (M = %i, N = %i, frames = %i)', M, N, nbframes));
xlabel('Time [s]');
ylabel('Frequency [Hz]');
colorbar
end
D=get(gcf,'Position');
set(gcf,'Position',round([D(1)*.5 D(2)*.5 D(3)*1.5 D(4)*1.5]))
pause
close all
%Question 5
disp('> Question 5: Mel Space'); %Mel�ռ�
plot(linspace(0, (fs1/2), 129), (melfb(20, 256, fs1))');
title('Mel-Spaced Filterbank');
xlabel('Frequency [Hz]');
pause
close all
%Question 6
disp('> Question 6: Modified spectrum'); %������
M = 100;
N = 256;
frames = blockFrames(s1, fs1, M, N);
n2 = 1 + floor(N / 2);
m = melfb(20, N, fs1);
z = m * abs(frames(1:n2, :)).^2;
t = N / 2;
tm = length(s1) / fs1;
subplot(121)
imagesc([0 tm], [0 fs1/2], abs(frames(1:n2, :)).^2), axis xy;
title('Power Spectrum unmodified');
xlabel('Time [s]');
ylabel('Frequency [Hz]');
colorbar;
subplot(122)
imagesc([0 tm], [0 20], z), axis xy;
title('Power Spectrum modified through Mel Cepstrum filter');
xlabel('Time [s]');
ylabel('Number of Filter in Filter Bank');
colorbar;
D=get(gcf,'Position');
set(gcf,'Position',[0 D(2) D(3)*2 D(4)])
pause
close all
%Question 7
disp('> Question 7: 2D plot of accustic vectors'); %�ۻ������Ķ�άͼ
c1 = mfcc(s1, fs1);
c2 = mfcc(s2, fs2);
plot(c1(5, :), c1(6, :), 'or');
hold on;
plot(c2(5, :), c2(6, :), 'xb');
xlabel('5th Dimension');
ylabel('6th Dimension');
legend('Signal 1', 'Signal 2');
title('2D plot of accoustic vectors');
pause
close all
%Question 8
disp('> Question 8: Plot of the 2D trained VQ codewords') %��άѵ��ʸ���������ֵĻ���
d1 = vqlbg(c1,16);
d2 = vqlbg(c2,16);
plot(c1(5, :), c1(6, :), 'xr')
hold on
plot(d1(5, :), d1(6, :), 'vk')
plot(c2(5, :), c2(6, :), 'xb')
plot(d2(5, :), d2(6, :), '+k')
xlabel('5th Dimension');
ylabel('6th Dimension');
legend('Speaker 1', 'Codebook 1', 'Speaker 2', 'Codebook 2');
title('2D plot of accoustic vectors');
pause
close all