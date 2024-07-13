% 读取音频文件
raw_file = '变声测试音频样本1.m4a';
[audioIn, fs] = audioread(raw_file); % 替换为你的音频文件路径

% 设计低通滤波器
lpFilt = designfilt('lowpassiir', 'FilterOrder', 8, ...
    'PassbandFrequency', 300, 'PassbandRipple', 0.2, ...
    'SampleRate', fs);

% 应用低通滤波器
audioLowPass = filter(lpFilt, audioIn);

% 播放处理后的音频
sound(audioLowPass, fs);

% 保存处理后的音频
audiowrite('output_audio_lowpass.wav', audioLowPass, fs); % 替换为你想要保存的路径
