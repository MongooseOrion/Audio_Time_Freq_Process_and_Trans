% ��ȥ��Ч�����з���

%% ��ȡ�ļ�
raw_file = '�������������Ƶ����.m4a';
noise_file = '�������������Ƶ����_ȥ����.m4a';
voice_file = '����.m4a';
posted_file = 'split.wav';
[audio1, fs1] = audioread(raw_file);  
[audio2, fs2] = audioread(noise_file);
[audio3, fs3] = audioread(voice_file);
%% ����ԭʼ�ļ�
% ˫ͨ���䵥ͨ��
audio1 = audio1(:, 1);
audio1 = audio1-mean(audio1);                             % ����ֱ������
audio1 = audio1/max(abs(audio1));                         % ��ֵ��һ��
% ��ȡ��Ƶ���ȺͲ������
n1 = length(audio1); 
T1 = 1/fs1;
% ���п��ٸ���Ҷ�任
audio_fft1 = fft(audio1, n1);
c1=abs(audio_fft1);
audio_fft1_1 = audio_fft1;

%% ���������ļ�
% ˫ͨ���䵥ͨ��
audio2 = audio2(:, 1);
audio2 = audio2-mean(audio2);                             % ����ֱ������
audio2 = audio2/max(abs(audio2));                         % ��ֵ��һ��
% ��ȡ��Ƶ���ȺͲ������
n2 = length(audio2);
audio_fft2 = fft(audio2, n1);
c2=abs(audio_fft2);

%% ���������ļ�
% ˫ͨ���䵥ͨ��
audio3 = audio3(:, 1);
audio3 = audio3-mean(audio3);                             % ����ֱ������
audio3 = audio3/max(abs(audio3));                         % ��ֵ��һ��
% ��ȡ��Ƶ���ȺͲ������
n3 = length(audio3);
% ���п��ٸ���Ҷ�任
audio_fft3 = fft(audio3, n1);
c3=abs(audio_fft3);

%% 
% ����ÿ�� FFT �Ĵ��ڴ�С
window_size = 1024;
% ����������ݵ��ܳ���
total_samples = length(audio1);
% ���� FFT �Ĵ���������ȡ����
num_fft = floor(total_samples / window_size);
% ����һ���������洢ÿ����FFT��Ľ��
ifft_results= zeros(length(audio1), 1);
sum_fft_results2= zeros(45,window_size);
sum_fft_results3= zeros(45,window_size);
real_result = zeros(1024, 1);           % ���ڴ洢ÿ����FFT������ʵ�����
comparison_result = zeros(45,1024);      % ���ڱ��ÿ��Ƶ�ʷ����Ƿ�Ϊ������1 ��ʾ��������0 ��ʾ���ǣ�
sin_window = zeros(1024, 1);
window_move_size=window_size/2;
num_fft2 = floor(total_samples / window_move_size);%��֡��
num_fft3 = floor(num_fft2/45);
%����������
for i=1:1024
    sin_window(i) = sin( pi * (i-1) / window_size);
    
end

% ����
for j=1:45
    for i = 1:num_fft3
    % ��ȡ��ǰ���ڵĲ�������
        start_index = ((j-1)*num_fft3+i - 1) * window_move_size + 1;
        end_index = start_index + window_size - 1;
        window_data = audio3(start_index:end_index);
        window_data = window_data .* sin_window;
    % �Ե�ǰ���ڵĲ������ݽ��� FFT
        fft_result = fft(window_data);
        sum_fft_results2(j, :)  = sum_fft_results2(j, :)  + abs(fft_result).';
    end
end

% ����
for j=1:45
    for i = 1:num_fft3
    % ��ȡ��ǰ���ڵĲ�������
        start_index = ((j-1)*num_fft3+i - 1) * window_move_size + 1;
        end_index = start_index + window_size - 1;
        window_data = audio1(start_index:end_index);
        window_data = window_data .* sin_window;
    % �Ե�ǰ���ڵĲ������ݽ��� FFT
        fft_result = fft(window_data);
        sum_fft_results3(j, :)  = sum_fft_results3(j, :)  + abs(fft_result).';
    end
end

% �����Ӧ��Ƶ�ʷ����Ƚϣ���������������������д�� 1
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



% ��ԭʼ�ļ����������д���
for j = 1:45
    for i = 1:num_fft3
        % ��ȡ��ǰ���ڵĲ�������
        start_index = ((j-1)*num_fft3+i - 1) * window_move_size + 1;
        end_index = start_index + window_size - 1;
        window_data = audio1(start_index:end_index);
        window_data = window_data .* sin_window;
        % �Ե�ǰ���ڵĲ������ݽ��� FFT
        fft_result = fft(window_data);
        for k=1:1024
            if comparison_result(j,k) == 1
                fft_result(k)=fft_result(k)*0;            % ����Ƶ�ʷ�����0
            end
        end
        real_result = real(ifft(fft_result)); %��任
        real_result = real_result .* sin_window ;

        % ����FFT�������������
        ifft_results(start_index:end_index) = ifft_results(start_index:end_index) + real_result(1:window_size);
    end
end
%% ������ս��
sound(ifft_results,fs1);
%audiowrite(posted_file, ifft_results, fs1);

% ��ʼ��һ�����ڴ洢������ַ�������
binary_strings = strings(1024, 1);

% ����ÿһ��
for i = 1:1024
    % ��ÿһ�е�ֵת�����ַ�������
    str_array = string(comparison_result(:,i));
    
    % ʹ��strjoin����ƴ���ַ�������Ϊһ���������ַ���
    binary_str = strjoin(str_array, '');
    
    % ��ƴ�ӵĶ������ַ���д��������
    binary_strings(i) = binary_str;
end

%% ����Ƶ�׶Ա�
figure;
subplot(4,2, 1);
plot(audio1);
title('ԭ����ʱ��ͼ');
xlabel('Ƶ�� (Hz)');
ylabel('���')
subplot(4, 2, 2);
plot(abs(audio_fft1));
title('ԭ����Ƶ��');
xlabel('Ƶ�� (Hz)');
ylabel('���');

subplot(4, 2, 3);
plot(audio2);
title('������ʱ��ͼ');
xlabel('Ƶ�� (Hz)');
ylabel('���')
subplot(4, 2, 4);
plot(abs(audio_fft2));
title('������Ƶ��');
xlabel('Ƶ�� (Hz)');
ylabel('���');

subplot(4, 2, 5);
plot(audio3);
title('�����ʱ��ͼ');
xlabel('Ƶ�� (Hz)');
ylabel('���')
subplot(4, 2, 6);
plot(abs(audio_fft3));
title('�����Ƶ��');
xlabel('Ƶ�� (Hz)');
ylabel('���');

fft_result3=fft(ifft_results); 
subplot(4, 2, 7);
plot(ifft_results);
title('�����ʱ��ͼ');
xlabel('Ƶ�� (Hz)');
ylabel('���')
subplot(4, 2, 8);
plot(abs(fft_result3));
title('�����Ƶ��');
xlabel('Ƶ�� (Hz)');
ylabel('���');
grid on;