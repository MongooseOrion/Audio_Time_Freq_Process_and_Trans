% 将输入音频时域抽样实现变声效果
clear;
% 遍历读取音频文件
file_directory = 'C:\Users\smn90\repo\FPGA_Audio_Noise_Gate\dataset\E_classification\speaker11\';
% 获取目录中的所有文件和文件夹信息
files = dir(file_directory);
% 遍历所有文件和文件夹
for n = 1:length(files)
    % 获取文件或文件夹的名称
    fileName = files(n).name;
    % 跳过 '.' 和 '..' 目录
    if strcmp(fileName, '.') || strcmp(fileName, '..')
        continue;
    end
    % 生成完整的文件路径
    fullFilePath = fullfile(file_directory, fileName);
    disp(fullFilePath);
    [audio1, fs1] = audioread(fullFilePath);

    % 双通道变单通道
    audio1 = audio1(:, 1);


    % 定义每次 FFT 的窗口大小
    window_size = 960;
    % 计算采样数据的总长度
    total_samples = length(audio1);

    % 计算 FFT 的次数（向下取整）
    num_fft = floor(total_samples / window_size);
    resample = zeros(960,1);
    for i = 1:num_fft
        % 获取当前窗口的采样数据
        start_index = (i - 1) * window_size + 1;
        end_index = i * window_size;
        window_data = audio1(start_index:end_index);

         % 对当前窗口的采样数据进行 FFT
         fft_result = fft(window_data);
         %男声变女声
         for j=1:window_size/2
             if(j>2)
             resample(j)=(window_data(2*j-1)+window_data(2*j)+window_data(2*j-2)/3);
             else
                 resample(j)=(window_data(2*j-1));
             end
         end
         resample(window_size/2+1:end) = resample(1:window_size/2);
        k=0;
        %女声变男声
%         for j=1:window_size/3*2-1
% 
%             if  mod(j,3)==0
%                 resample(k+1:k+2)=window_data(j);
%                 k=k+2;
%             else
%                 k=k+1;
%                 resample(k)=window_data(j);
%             end
%         end

         ifft_results(start_index:end_index) = resample(1:960);
        % 在这里进行你想要的操作，例如获取幅度谱、相位谱等

        % 注意：在这里仅显示示例，实际情况下你可能会进行更多的处理

        % 每次 FFT 的结果，可以在这里进行进一步处理或保存
    end
    output_name = ['output_', fileName];
    audiowrite(output_name, ifft_results, fs1);
end