% 对去噪效果进行仿真

%% 读取文件
raw_file = '人声分离测试音频样本.m4a';
noise_file = '人声分离测试音频样本_去配乐.m4a';
voice_file = '旋律.m4a';
posted_file = 'split.wav';
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
window_size = 1024;
% 计算采样数据的总长度
total_samples = length(audio1);
% 计算 FFT 的次数（向下取整）
num_fft = floor(total_samples / window_size);
% 创建一个数组来存储每次逆FFT后的结果
ifft_results= zeros(length(audio1), 1);
sum_fft_results2= zeros(45,window_size);
sum_fft_results3= zeros(45,window_size);
real_result = zeros(1024, 1);           % 用于存储每次逆FFT处理后的实部结果
comparison_result = zeros(45,1024);      % 用于标记每个频率分量是否为噪声（1 表示是噪声，0 表示不是）
sin_window = zeros(1024, 1);
window_move_size=window_size/2;
num_fft2 = floor(total_samples / window_move_size);%总帧数
num_fft3 = floor(num_fft2/45);
%窗函数采样
for i=1:1024
    sin_window(i) = sin( pi * (i-1) / window_size);
    
end

% 噪声
for j=1:45
    for i = 1:num_fft3
    % 获取当前窗口的采样数据
        start_index = ((j-1)*num_fft3+i - 1) * window_move_size + 1;
        end_index = start_index + window_size - 1;
        window_data = audio3(start_index:end_index);
        window_data = window_data .* sin_window;
    % 对当前窗口的采样数据进行 FFT
        fft_result = fft(window_data);
        sum_fft_results2(j, :)  = sum_fft_results2(j, :)  + abs(fft_result).';
    end
end

% 人声
for j=1:45
    for i = 1:num_fft3
    % 获取当前窗口的采样数据
        start_index = ((j-1)*num_fft3+i - 1) * window_move_size + 1;
        end_index = start_index + window_size - 1;
        window_data = audio1(start_index:end_index);
        window_data = window_data .* sin_window;
    % 对当前窗口的采样数据进行 FFT
        fft_result = fft(window_data);
        sum_fft_results3(j, :)  = sum_fft_results3(j, :)  + abs(fft_result).';
    end
end

% 两组对应的频率分量比较，噪声高于人声往矩阵里写入 1
for i=1:45
    for j=1:1024
        if sum_fft_results3(i,j,1)/sum_fft_results2(i,j,1)>0.8
            comparison_result(i,j)=1;
%         elseif (sum_fft_results3(j)/sum_fft_results2(j)>0.4)&&(sum_fft_results3(j)/sum_fft_results2(j)<=0.90)
%             comparison_result(j)=2;
%         elseif (sum_fft_results3(j)/sum_fft_results2(j)>0.3)&&(sum_fft_results3(j)/sum_fft_results2(j)<=0.3)
%             comparison_result(j)=3;
%         elseif (sum_fft_results3(j)/sum_fft_results2(j)>0.3)&&(sum_fft_results3(j)/sum_fft_results2(j)<=0.3)
%             comparison_result(j)=4;
        end      
    end
end

for i=1:45
    comparison_result(i,1) = 0;
end



% 对原始文件的数据序列处理
for j = 1:45
    for i = 1:num_fft3
        % 获取当前窗口的采样数据
        start_index = ((j-1)*num_fft3+i - 1) * window_move_size + 1;
        end_index = start_index + window_size - 1;
        window_data = audio1(start_index:end_index);
        window_data = window_data .* sin_window;
        % 对当前窗口的采样数据进行 FFT
        fft_result = fft(window_data);
        for k=1:1024
            if comparison_result(j,k) == 1
                fft_result(k)=fft_result(k)*0;            % 噪音频率分量置0
            end
        end
        real_result = real(ifft(fft_result)); %逆变换
        real_result = real_result .* sin_window ;

        % 将逆FFT结果放入数组中
        ifft_results(start_index:end_index) = ifft_results(start_index:end_index) + real_result(1:window_size);
    end
end
%% 输出最终结果
sound(ifft_results,fs1);
%audiowrite(posted_file, ifft_results, fs1);

% 初始化一个用于存储结果的字符串数组
binary_strings = strings(1024, 1);

% 遍历每一行
for i = 1:1024
    % 将每一行的值转换成字符串数组
    str_array = string(comparison_result(:,i));
    
    % 使用strjoin函数拼接字符串数组为一个二进制字符串
    binary_str = strjoin(str_array, '');
    
    % 将拼接的二进制字符串写入结果数组
    binary_strings(i) = binary_str;
end

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
title('人声的时域图');
xlabel('频率 (Hz)');
ylabel('振幅')
subplot(4, 2, 4);
plot(abs(audio_fft2));
title('人声的频谱');
xlabel('频率 (Hz)');
ylabel('振幅');

subplot(4, 2, 5);
plot(audio3);
title('伴奏的时域图');
xlabel('频率 (Hz)');
ylabel('振幅')
subplot(4, 2, 6);
plot(abs(audio_fft3));
title('伴奏的频谱');
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