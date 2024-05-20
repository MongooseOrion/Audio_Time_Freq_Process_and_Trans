''' ======================================================================
* Copyright (c) 2023, MongooseOrion.
* All rights reserved.
*
* The following code snippet may contain portions that are derived from
* OPEN-SOURCE communities, and these portions will be licensed with: 
*
* <NULL>
*
* If there is no OPEN-SOURCE licenses are listed, it indicates none of
* content in this Code document is sourced from OPEN-SOURCE communities. 
*
* In this case, the document is protected by copyright, and any use of
* all or part of its content by individuals, organizations, or companies
* without authorization is prohibited, unless the project repository
* associated with this document has added relevant OPEN-SOURCE licenses
* by github.com/MongooseOrion. 
*
* Please make sure using the content of this document in accordance with 
* the respective OPEN-SOURCE licenses. 
* 
* THIS CODE IS PROVIDED BY https://github.com/MongooseOrion. 
* FILE ENCODER TYPE: UTF-8
* ========================================================================
'''
# 使用串口控制的所有功能

def command_send(port = 'COM19', baudrate = 9600):
    '''
    将 FPGA 功能控制命令发送到板上。

    参数：
    port : str
        UART 端口号
    baudrate : int
        波特率

    输出：
        NULL
    '''
    import serial

    # 打开串口
    ser = serial.Serial(port=port, baudrate=baudrate, timeout=1)

    data = int(input('Please input function index: '))
    # 将数据转换为十六进制格式
    hex_data = format(data, '02x')

    # 发送数据
    ser.write(bytearray.fromhex(hex_data))
    # 关闭串口
    ser.close()
    print(f"成功发送数据: {hex_data}")



def audio_play(RATE = 48000):
    '''
    将 UDP 传输的音频数据编码并播放。

    参数：
    RATE : int
        采样率

    输出：
        NULL
    '''
    import pyaudio
    import socket

    # 初始化PyAudio
    p = pyaudio.PyAudio()

    # 设置音频参数
    FORMAT = pyaudio.paInt16
    CHANNELS = 1
    CHUNK = 1024  # 每次读取的音频数据大小

    # 设置 UDP 参数
    UDP_IP = "192.168.0.3"
    UDP_PORT = 8080

    # 创建UDP套接字
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((UDP_IP, UDP_PORT))

    print("接收 UDP 音频数据并播放...")

    # 接收并播放音频数据
    try:
        stream = p.open(format=FORMAT,
                        channels=CHANNELS,
                        rate=RATE,
                        output=True,
                        frames_per_buffer=CHUNK)

        # 持续接收，直到接收到带有起始标识符的数据包
        while True:
            data, addr = sock.recvfrom(1024)  # 从UDP套接字接收数据

            stream.write(data)  # 播放音频数据

    except KeyboardInterrupt:
        print("接收停止。")

    finally:
        stream.stop_stream()
        stream.close()
        p.terminate()
        sock.close()



def audio_decode(num_samples, sample_rate = 48000, time = 2):
    '''
    将从 UDP 接收的音频数据编组，以便后续输入深度学习模型。

    参数：
    num_samples : 
    '''
    import socket

    # 设置 UDP 参数
    UDP_IP = "192.168.0.3"
    UDP_PORT = 8080
    
    # 创建UDP套接字
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((UDP_IP, UDP_PORT))

    recv_data = b''
    data = b''
    while True:
        if(len(recv_data) < sample_rate * time): 
            data, addr = sock.recvfrom(1024)  # 从UDP套接字接收数据
            recv_data = recv_data + data
            continue
        else:
            recv_data = recv_data[0 : num_samples]
            return recv_data



def classify_recog_predict(model_path, class_file, sample_rate = 48000):
    '''
    对多个声音类别进行分类推理，使用 tensorflow 模型。

    参数：

    '''
    from tensorflow.keras.models import load_model
    from clean import downsample_mono, envelope
    from kapre.time_frequency import STFT, Magnitude, ApplyFilterbank, MagnitudeToDecibel
    import numpy as np
    import socket
    import time

    model = load_model(model_path,
                       custom_objects={'STFT':STFT,
                                       'Magnitude':Magnitude,
                                       'ApplyFilterbank':ApplyFilterbank,
                                       'MagnitudeToDecibel':MagnitudeToDecibel})

    # 创建UDP套接字
    UDP_IP = '192.168.0.3'
    UDP_PORT = 8080
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((UDP_IP, UDP_PORT))

    print("接收 UDP 音频数据并实时进行推理分类...")

    # 从classes.txt文件中加载类别名称
    with open(class_file, 'r') as file:
        classes = file.readlines()
    class_list = [cls.strip() for cls in classes]

    try:
        recv_data = b''
        data = b''
        while True:
            if(len(recv_data) < 48000 * 2): 
                data, addr = sock.recvfrom(1024)  # 从UDP套接字接收数据
                recv_data = recv_data + data
                continue
            else:
                recv_data = recv_data[0 : 48000*2]

            # 对接收到的音频数据进行分类推理
            start_time = time.time()
            rate, wav = downsample_mono(recv_data, 16000, 2)
            mask, env = envelope(wav, rate, 20)
            clean_wav = wav[mask]
            if(len(clean_wav) != 16000): 
                print(None)
                recv_data = b''
                time.sleep(1)
                continue
            X = clean_wav.reshape(1, -1, 1)
            y_pred = model.predict(X)
            class_index = np.argmax(y_pred)
            predicted_class = class_list[class_index]
            print(predicted_class)
            recv_data = b''
            end_time = time.time()
            print(f'识别时间为：{end_time-start_time}')

    except KeyboardInterrupt:
        print("接收停止。")

    finally:
        # 关闭UDP套接字
        sock.close()



def emotion_gender_classify_predict(model_path, model_config, class_file):
    '''
    对人声进行性别和情绪分析，使用 tensorflow 模型。

    参数：

    '''
    from keras.models import model_from_json
    import librosa
    import numpy as np
    import pandas as pd
    from sklearn.preprocessing import LabelEncoder
    import socket
    import os
    import wave
    import time

    lb = LabelEncoder()

    # 从CSV文件中读取数据
    df = pd.read_csv(class_file)
    actual_values = df['actualvalues']
    predicted_values = df['predictedvalues']
    all_values = actual_values.append(predicted_values)
    # 创建并拟合标签编码器
    lb = LabelEncoder()
    lb.fit(all_values)

    # 加载模型文件
    json_file = open(model_config, 'r')
    loaded_model_json = json_file.read()
    json_file.close()
    loaded_model = model_from_json(loaded_model_json)
    loaded_model.load_weights(model_path)
    print("Loaded model from disk")

    # 创建UDP套接字
    UDP_IP = '192.168.0.3'
    UDP_PORT = 8080
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((UDP_IP, UDP_PORT))

    print("接收 UDP 音频数据并实时进行推理分类...")

    try: 
        recv_data = b''
        data = b''
        while True:
            if(len(recv_data) < 48000 * 6): 
                data, addr = sock.recvfrom(1024)  # 从UDP套接字接收数据
                recv_data = recv_data + data
                continue
            else:
                recv_data = recv_data[0:269000]
            
            # 写入音频数据到一个临时的 WAV 文件
            wav_data = np.frombuffer(recv_data, dtype=np.int16)
            rms_value = np.sqrt(np.mean(wav_data ** 2))     # 计算均方根以判定当前是否处于空闲状态
            if(rms_value < 10): 
                print(None)
                recv_data = b''
                continue
            with wave.open('received_audio.wav', 'wb') as wf:
                # 设置音频参数
                wf.setnchannels(1)  # 单声道
                wf.setsampwidth(2)  # 16位
                wf.setframerate(48000)  # 采样率为 48kHz
                wf.writeframes(wav_data)  

            start_time = time.time()
            X, sample_rate = librosa.load('received_audio.wav', res_type='kaiser_fast',duration=2.5,sr=48000,offset=0.5)
            sample_rate = np.array(sample_rate)
            mfccs = np.mean(librosa.feature.mfcc(y=X, sr=sample_rate, n_mfcc=13),axis=0)
            livedf2 = mfccs
            livedf2= pd.DataFrame(data=livedf2)
            livedf2 = livedf2.stack().to_frame().T
            twodim= np.expand_dims(livedf2, axis=2)
            livepreds = loaded_model.predict(twodim, 
                                    batch_size=32, 
                                    verbose=0)
            livepreds1=livepreds.argmax(axis=1)
            liveabc = livepreds1.astype(int).flatten()
            livepredictions = (lb.inverse_transform((liveabc)))
            gender, emotion = livepredictions[0].split('_')
            print(gender, emotion)
            os.remove('received_audio.wav')
            recv_data = b''
            end_time = time.time()
            print(f'计算时间为：{end_time-start_time}')

    except KeyboardInterrupt:
            sock.close()
            print("接收停止。")

    finally:
        # 删除临时文件
        if os.path.exists('received_audio.wav'):
            os.remove('received_audio.wav')