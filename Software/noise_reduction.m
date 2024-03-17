% ��ȥ��Ч�����з���

%% ��ȡ�ļ�
raw_file = '../Sample/ȥ�������Ƶ����1.m4a';
noise_file = '../Sample/noise_splited.m4a';
voice_file = '../Sample/voice_splited.m4a';
posted_file = '../Sample/noise_reduced.wav';
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
T2 = 1/fs2;
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
window_size = 3200;
% ����������ݵ��ܳ���
total_samples = length(audio2);
% ���� FFT �Ĵ���������ȡ����
num_fft = floor(total_samples / window_size);
% ����һ���������洢ÿ����FFT��Ľ��
ifft_results= zeros(length(audio1), 1);
sum_ifft_results2= zeros(window_size, 1);
sum_ifft_results3= zeros(window_size, 1);
real_result = zeros(3200, 1);           % ���ڴ洢ÿ����FFT������ʵ�����
comparison_result = zeros(3200,1);      % ���ڱ��ÿ��Ƶ�ʷ����Ƿ�Ϊ������1 ��ʾ��������0 ��ʾ���ǣ�

% ����
for i = 1:num_fft
    % ��ȡ��ǰ���ڵĲ�������
    start_index = (i - 1) * window_size + 1;
    end_index = i * window_size;
    window_data = audio2(start_index:end_index);
    
    % �Ե�ǰ���ڵĲ������ݽ��� FFT
    fft_result = fft(window_data);
    sum_ifft_results2 = sum_ifft_results2 + abs(fft_result);
end

% ����
for i = 1:num_fft
    % ��ȡ��ǰ���ڵĲ�������
    start_index = (i - 1) * window_size + 1;
    end_index = i * window_size;
    window_data = audio3(start_index:end_index);
    
    % �Ե�ǰ���ڵĲ������ݽ��� FFT
    fft_result = fft(window_data);
    sum_ifft_results3 = sum_ifft_results3 + abs(fft_result);
end

% �����Ӧ��Ƶ�ʷ����Ƚϣ���������������������д�� 1
for j=1:3200
    if sum_ifft_results3(j)<sum_ifft_results2(j)
        comparison_result(j)=1;
    end
end

% ��ԭʼ�ļ����������д���
for i = 1:num_fft-2
    % ��ȡ��ǰ���ڵĲ�������
    start_index = (i - 1) * window_size + 1;
    end_index = i * window_size;
    window_data = audio1(start_index:end_index);
    
    % �Ե�ǰ���ڵĲ������ݽ��� FFT
    fft_result = fft(window_data);
    for j=1:3200
        if comparison_result(j) == 1
            fft_result(j)=0;            % ����Ƶ�ʷ�����0
        end
    end
    real_result = real(ifft(fft_result));
    % ����FFT�������������
    ifft_results(start_index:end_index) = real_result(1:3200);
end

%% ������ս��
% sound(ifft_results,fs1);
audiowrite(posted_file, ifft_results, fs1);

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
title('������ʱ��ͼ');
xlabel('Ƶ�� (Hz)');
ylabel('���')
subplot(4, 2, 6);
plot(abs(audio_fft3));
title('������Ƶ��');
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