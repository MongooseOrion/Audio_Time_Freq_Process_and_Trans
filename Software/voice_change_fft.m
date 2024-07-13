% ��ȥ��Ч�����з���

%% ��ȡ�ļ�
raw_file = '����������Ƶ����2.mp3';
posted_file = 'split.wav';
[audio1, fs1] = audioread(raw_file);

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

%%
% ����ÿ�� FFT �Ĵ��ڴ�С
window_size = 1024;
% ����������ݵ��ܳ���
total_samples = length(audio1);
% ����һ���������洢ÿ����FFT��Ľ��
ifft_results= zeros(length(audio1), 1);
real_result = zeros(1024, 1);           % ���ڴ洢ÿ����FFT������ʵ�����
sin_window = zeros(1024, 1);
window_move_size=window_size/2;
num_fft = floor(total_samples / window_move_size);%��֡��
%����������
for i=1:1024
    sin_window(i) = sin( pi * (i-1) / window_size);
end



% ��ԭʼ�ļ����������д���
for j = 1:num_fft - 1
    % ��ȡ��ǰ���ڵĲ�������
    start_index = (j-1) * window_move_size + 1;
    end_index = start_index + window_size - 1;
    window_data = audio1(start_index:end_index);
    window_data = window_data .* sin_window;
    % �Ե�ǰ���ڵĲ������ݽ��� FFT
    fft_result = fft(window_data);
    shifted_fft = shift_fft(fft_result,10, 'right');
    real_result = real(ifft(shifted_fft)); %��任
    real_result = real_result .* sin_window ;
    
    % ����FFT�������������
    ifft_results(start_index:end_index) = ifft_results(start_index:end_index) + real_result(1:window_size);
    
end
%% ������ս��
sound(ifft_results,fs1);
%audiowrite(posted_file, ifft_results, fs1);



%% ����Ƶ�׶Ա�
figure;
subplot(4,2, 1);
plot(audio1);
title('ԭ����ʱ��ͼ');
xlabel('ʱ��');
ylabel('���')
subplot(4, 2, 2);
plot(abs(audio_fft1));
title('ԭ����Ƶ��');
xlabel('Ƶ�� (Hz)');
ylabel('���');

subplot(4, 2, 3);
plot(ifft_results);
title('������ʱ��ͼ');
xlabel('ʱ�� ');
ylabel('���')
subplot(4, 2, 4);
plot(abs(fft(ifft_results)));
title('������Ƶ��');
xlabel('Ƶ�� (Hz)');
ylabel('���');

grid on;

function shifted_fft = shift_fft(signal_fft, k, direction)
    % signal_fft: �����źŵ�FFT���
    % k: ���Ƶ�Ƶ��λ��
    % direction: ���Ʒ���'left' �� 'right'

    N = length(signal_fft);
    shifted_fft = zeros(size(signal_fft));
    
    % ����ֱ������������Ƶ�ʷ�������
    shifted_fft(1) = signal_fft(1); % ֱ������
    shifted_fft(N/2 + 1) = signal_fft(N/2 + 1); % ����Ƶ�ʷ���
    
    if strcmp(direction, 'left')
        % ��2��N/2��������ƽ��
        shifted_fft(2:(N/2)-k) = signal_fft(2+k:(N/2));
        % N/2+2��N��������ƽ��
        shifted_fft((N/2 + 2 + k):N) = signal_fft((N/2 + 2 ):N-k);
    elseif strcmp(direction, 'right')
        % ��2��N/2��������ƽ��
        shifted_fft(2+k:(N/2)) = signal_fft(2:(N/2)-k);
        % N/2+2��N��������ƽ��
        shifted_fft((N/2 + 2 ):N-k) = signal_fft((N/2 + 2 + k ):N);
    else
        error('δ֪�İ��Ʒ�����ѡ�� "left" �� "right"��');
    end
end