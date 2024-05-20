% ��������Ƶʱ�����ʵ�ֱ���Ч��
clear;
% ������ȡ��Ƶ�ļ�
file_directory = 'C:\Users\smn90\repo\FPGA_Audio_Noise_Gate\dataset\E_classification\speaker11\';
% ��ȡĿ¼�е������ļ����ļ�����Ϣ
files = dir(file_directory);
% ���������ļ����ļ���
for n = 1:length(files)
    % ��ȡ�ļ����ļ��е�����
    fileName = files(n).name;
    % ���� '.' �� '..' Ŀ¼
    if strcmp(fileName, '.') || strcmp(fileName, '..')
        continue;
    end
    % �����������ļ�·��
    fullFilePath = fullfile(file_directory, fileName);
    disp(fullFilePath);
    [audio1, fs1] = audioread(fullFilePath);

    % ˫ͨ���䵥ͨ��
    audio1 = audio1(:, 1);


    % ����ÿ�� FFT �Ĵ��ڴ�С
    window_size = 960;
    % ����������ݵ��ܳ���
    total_samples = length(audio1);

    % ���� FFT �Ĵ���������ȡ����
    num_fft = floor(total_samples / window_size);
    resample = zeros(960,1);
    for i = 1:num_fft
        % ��ȡ��ǰ���ڵĲ�������
        start_index = (i - 1) * window_size + 1;
        end_index = i * window_size;
        window_data = audio1(start_index:end_index);

         % �Ե�ǰ���ڵĲ������ݽ��� FFT
         fft_result = fft(window_data);
         %������Ů��
         for j=1:window_size/2
             if(j>2)
             resample(j)=(window_data(2*j-1)+window_data(2*j)+window_data(2*j-2)/3);
             else
                 resample(j)=(window_data(2*j-1));
             end
         end
         resample(window_size/2+1:end) = resample(1:window_size/2);
        k=0;
        %Ů��������
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
        % �������������Ҫ�Ĳ����������ȡ�����ס���λ�׵�

        % ע�⣺���������ʾʾ����ʵ�����������ܻ���и���Ĵ���

        % ÿ�� FFT �Ľ����������������н�һ������򱣴�
    end
    output_name = ['output_', fileName];
    audiowrite(output_name, ifft_results, fs1);
end