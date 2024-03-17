% 对去噪效果进行仿真

%% 读取文件
raw_file = '../Sample/去噪测试音频样本1.m4a';
noise_file = '../Sample/noise_splited.m4a';
voice_file = '../Sample/voice_splited.m4a';
posted_file = '../Sample/noise_reduced.wav';
[audio1, fs1] = audioread(raw_file);
[audio2, fs2] = audioread(noise_file);
[audio3, fs3] = audioread(voice_file);

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

%% 处理噪声文件
% 双通道变单通道
audio2 = audio2(:, 1);
audio2 = audio2-mean(audio2);                             % 消除直流分量
audio2 = audio2/max(abs(audio2));                         % 幅值归一化
% 获取音频长度和采样间隔
n2 = length(audio2);
T2 = 1/fs2;
audio_fft2 = fft(audio2, n1);
c2=abs(audio_fft2);

%% 处理人声文件
% 双通道变单通道
audio3 = audio3(:, 1);
audio3 = audio3-mean(audio3);                             % 消除直流分量
audio3 = audio3/max(abs(audio3));                         % 幅值归一化
% 获取音频长度和采样间隔
n3 = length(audio3);
% 进行快速傅里叶变换
audio_fft3 = fft(audio3, n1);
c3=abs(audio_fft3);

%% 
% 定义每次 FFT 的窗口大小
window_size = 3200;
% 计算采样数据的总长度
total_samples = length(audio2);
% 计算 FFT 的次数（向下取整）
num_fft = floor(total_samples / window_size);
% 创建一个数组来存储每次逆FFT后的结果
ifft_results= zeros(length(audio1), 1);
sum_ifft_results2= zeros(window_size, 1);
sum_ifft_results3= zeros(window_size, 1);
real_result = zeros(3200, 1);           % 用于存储每次逆FFT处理后的实部结果
comparison_result = zeros(3200,1);      % 用于标记每个频率分量是否为噪声（1 表示是噪声，0 表示不是）

% 噪声
for i = 1:num_fft
    % 获取当前窗口的采样数据
    start_index = (i - 1) * window_size + 1;
    end_index = i * window_size;
    window_data = audio2(start_index:end_index);
    
    % 对当前窗口的采样数据进行 FFT
    fft_result = fft(window_data);
    sum_ifft_results2 = sum_ifft_results2 + abs(fft_result);
end

% 人声
for i = 1:num_fft
    % 获取当前窗口的采样数据
    start_index = (i - 1) * window_size + 1;
    end_index = i * window_size;
    window_data = audio3(start_index:end_index);
    
    % 对当前窗口的采样数据进行 FFT
    fft_result = fft(window_data);
    sum_ifft_results3 = sum_ifft_results3 + abs(fft_result);
end

% 两组对应的频率分量比较，噪声高于人声往矩阵里写入 1
for j=1:3200
    if sum_ifft_results3(j)<sum_ifft_results2(j)
        comparison_result(j)=1;
    end
end

% 对原始文件的数据序列处理
for i = 1:num_fft-2
    % 获取当前窗口的采样数据
    start_index = (i - 1) * window_size + 1;
    end_index = i * window_size;
    window_data = audio1(start_index:end_index);
    
    % 对当前窗口的采样数据进行 FFT
    fft_result = fft(window_data);
    for j=1:3200
        if comparison_result(j) == 1
            fft_result(j)=0;            % 噪音频率分量置0
        end
    end
    real_result = real(ifft(fft_result));
    % 将逆FFT结果放入数组中
    ifft_results(start_index:end_index) = real_result(1:3200);
end

%% 输出最终结果
% sound(ifft_results,fs1);
audiowrite(posted_file, ifft_results, fs1);

%% 绘制频谱对比
figure;
subplot(4,2, 1);
plot(audio1);
title('原声的时域图');
xlabel('频率 (Hz)');
ylabel('振幅')
subplot(4, 2, 2);
plot(abs(audio_fft1));
title('原声的频谱');
xlabel('频率 (Hz)');
ylabel('振幅');

subplot(4, 2, 3);
plot(audio2);
title('噪音的时域图');
xlabel('频率 (Hz)');
ylabel('振幅')
subplot(4, 2, 4);
plot(abs(audio_fft2));
title('噪音的频谱');
xlabel('频率 (Hz)');
ylabel('振幅');

subplot(4, 2, 5);
plot(audio3);
title('人声的时域图');
xlabel('频率 (Hz)');
ylabel('振幅')
subplot(4, 2, 6);
plot(abs(audio_fft3));
title('人声的频谱');
xlabel('频率 (Hz)');
ylabel('振幅');

fft_result3=fft(ifft_results);
subplot(4, 2, 7);
plot(ifft_results);
title('降噪的时域图');
xlabel('频率 (Hz)');
ylabel('振幅')
subplot(4, 2, 8);
plot(abs(fft_result3));
title('降噪的频谱');
xlabel('频率 (Hz)');
ylabel('振幅');
grid on;