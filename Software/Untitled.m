% ��ȡ��Ƶ�ļ�
raw_file = '����������Ƶ����1.m4a';
[audioIn, fs] = audioread(raw_file); % �滻Ϊ�����Ƶ�ļ�·��

% ��Ƶ�ͨ�˲���
lpFilt = designfilt('lowpassiir', 'FilterOrder', 8, ...
    'PassbandFrequency', 300, 'PassbandRipple', 0.2, ...
    'SampleRate', fs);

% Ӧ�õ�ͨ�˲���
audioLowPass = filter(lpFilt, audioIn);

% ���Ŵ�������Ƶ
sound(audioLowPass, fs);

% ���洦������Ƶ
audiowrite('output_audio_lowpass.wav', audioLowPass, fs); % �滻Ϊ����Ҫ�����·��
