% 对去噪效果进行仿真

%% 读取文件
raw_file = '变声测试音频样本2.mp3';
posted_file = 'split.wav';
[audio1, fs1] = audioread(raw_file);

%% 处理原始文件
% 双通道变单通道
audio1 = audio1(:, 1);
audio1 = audio1-mean(audio1);                             % 消除直流分量
audio1 = audio1/max(abs(audio1));                         % 幅值归一化
% 获取音频长度和采样间隔
n1 = length(audio1);
T1 = 1/fs1;
% 进行快速傅里叶变换
audio_fft1 = fft(audio1, n1);
c1=abs(audio_fft1);
audio_fft1_1 = audio_fft1;

%%
% 定义每次 FFT 的窗口大小
window_size = 1024;
% 计算采样数据的总长度
total_samples = length(audio1);
% 创建一个数组来存储每次逆FFT后的结果
ifft_results= zeros(length(audio1), 1);
real_result = zeros(1024, 1);           % 用于存储每次逆FFT处理后的实部结果
sin_window = zeros(1024, 1);
window_move_size=window_size/2;
num_fft = floor(total_samples / window_move_size);%总帧数
%窗函数采样
for i=1:1024
    sin_window(i) = sin( pi * (i-1) / window_size);
end



% 对原始文件的数据序列处理
for j = 1:num_fft - 1
    % 获取当前窗口的采样数据
    start_index = (j-1) * window_move_size + 1;
    end_index = start_index + window_size - 1;
    window_data = audio1(start_index:end_index);
    window_data = window_data .* sin_window;
    % 对当前窗口的采样数据进行 FFT
    fft_result = fft(window_data);
    shifted_fft = shift_fft(fft_result,10, 'right');
    real_result = real(ifft(shifted_fft)); %逆变换
    real_result = real_result .* sin_window ;
    
    % 将逆FFT结果放入数组中
    ifft_results(start_index:end_index) = ifft_results(start_index:end_index) + real_result(1:window_size);
    
end
%% 输出最终结果
sound(ifft_results,fs1);
%audiowrite(posted_file, ifft_results, fs1);



%% 绘制频谱对比
figure;
subplot(4,2, 1);
plot(audio1);
title('原声的时域图');
xlabel('时间');
ylabel('振幅')
subplot(4, 2, 2);
plot(abs(audio_fft1));
title('原声的频谱');
xlabel('频率 (Hz)');
ylabel('振幅');

subplot(4, 2, 3);
plot(ifft_results);
title('变声的时域图');
xlabel('时间 ');
ylabel('振幅')
subplot(4, 2, 4);
plot(abs(fft(ifft_results)));
title('人声的频谱');
xlabel('频率 (Hz)');
ylabel('振幅');

grid on;

function shifted_fft = shift_fft(signal_fft, k, direction)
    % signal_fft: 输入信号的FFT结果
    % k: 搬移的频率位置
    % direction: 搬移方向，'left' 或 'right'

    N = length(signal_fft);
    shifted_fft = zeros(size(signal_fft));
    
    % 保持直流分量和中心频率分量不变
    shifted_fft(1) = signal_fft(1); % 直流分量
    shifted_fft(N/2 + 1) = signal_fft(N/2 + 1); % 中心频率分量
    
    if strcmp(direction, 'left')
        % 第2到N/2分量向左平移
        shifted_fft(2:(N/2)-k) = signal_fft(2+k:(N/2));
        % N/2+2到N分量向右平移
        shifted_fft((N/2 + 2 + k):N) = signal_fft((N/2 + 2 ):N-k);
    elseif strcmp(direction, 'right')
        % 第2到N/2分量向右平移
        shifted_fft(2+k:(N/2)) = signal_fft(2:(N/2)-k);
        % N/2+2到N分量向左平移
        shifted_fft((N/2 + 2 ):N-k) = signal_fft((N/2 + 2 + k ):N);
    else
        error('未知的搬移方向。请选择 "left" 或 "right"。');
    end
end