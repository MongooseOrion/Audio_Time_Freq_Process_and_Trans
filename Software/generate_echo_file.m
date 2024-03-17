% 将正常的声音转换为有回声的声音，并获得频谱

%% 获取源文件
raw_file_path = '../Sample/人声分离测试音频样本.m4a';
[digital_simple,fs] = audioread(raw_file_path); 

%% 对原始数字信号序列进行运算
digital_simple = digital_simple(:,1);       % 取单声道，直接用双声道图像会重叠
window_range = 16000;                       % 定义要制造回声的样本数
delay_matrix = zeros(window_range,1);       % 创建全零矩阵以延迟
process_range_1 = [digital_simple;delay_matrix];
process_range_2 = [delay_matrix;digital_simple];
process_range_3 = process_range_1 + 0.5 * process_range_2; 

%% 验证消除回声效果
% x = length(digital_simple);
% b = zeros(x,1);
% b(1) = 1;
% b(window_range+1) = 0.5;
% process_range_4 = filter(1,b,process_range_3);

%% 播放声音
%sound(process_range_3,fs);


%% 生成谱图
raw_fft = fft(process_range_1);
post_fft = fft(process_range_3);

figure;
subplot(2,1, 1);
plot(abs(post_fft));
title('原声的时域图');
xlabel('频率 (Hz)');
ylabel('振幅');
subplot(2, 1, 2);
plot(abs(raw_fft));
title('原声的频谱');
xlabel('频率 (Hz)');
ylabel('振幅');