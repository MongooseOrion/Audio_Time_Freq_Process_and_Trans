% ������������ת��Ϊ�л����������������Ƶ��

%% ��ȡԴ�ļ�
raw_file_path = '../Sample/�������������Ƶ����.m4a';
[digital_simple,fs] = audioread(raw_file_path); 

%% ��ԭʼ�����ź����н�������
digital_simple = digital_simple(:,1);       % ȡ��������ֱ����˫����ͼ����ص�
window_range = 16000;                       % ����Ҫ���������������
delay_matrix = zeros(window_range,1);       % ����ȫ��������ӳ�
process_range_1 = [digital_simple;delay_matrix];
process_range_2 = [delay_matrix;digital_simple];
process_range_3 = process_range_1 + 0.5 * process_range_2; 

%% ��֤��������Ч��
% x = length(digital_simple);
% b = zeros(x,1);
% b(1) = 1;
% b(window_range+1) = 0.5;
% process_range_4 = filter(1,b,process_range_3);

%% ��������
%sound(process_range_3,fs);


%% ������ͼ
raw_fft = fft(process_range_1);
post_fft = fft(process_range_3);

figure;
subplot(2,1, 1);
plot(abs(post_fft));
title('ԭ����ʱ��ͼ');
xlabel('Ƶ�� (Hz)');
ylabel('���');
subplot(2, 1, 2);
plot(abs(raw_fft));
title('ԭ����Ƶ��');
xlabel('Ƶ�� (Hz)');
ylabel('���');