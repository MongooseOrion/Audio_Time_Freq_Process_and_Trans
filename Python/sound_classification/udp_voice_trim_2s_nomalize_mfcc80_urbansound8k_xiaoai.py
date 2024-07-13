import threading
import socket
import numpy as np
import time
from queue import Queue
import numpy as np
import librosa
import tensorflow as tf
import os
import matplotlib.pyplot as plt
import numpy as np
# 全局变量和锁

lock = threading.Lock()
exit_event = threading.Event()
voice_queue = Queue()


def udp_receive_data():
    received_data_list = []  # 使用列表收集数据
    UDP_IP = "192.168.0.3"
    UDP_PORT = 8080
    BUFFER_SIZE = 1024
    udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_socket.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, BUFFER_SIZE*10)
    udp_socket.bind((UDP_IP, UDP_PORT))
    sr = 48000
    a = int(sr/512)
    i = 0
    while not exit_event.is_set():
        data, addr = udp_socket.recvfrom(BUFFER_SIZE)
        #打印data的长度
        #print(len(data))
        data1 = np.frombuffer(data, dtype=np.int16)
        received_data_list.append(data1)  # 将数据添加到列表中
        if len(received_data_list) >= 2*a:
            received_data = np.concatenate(received_data_list)  # 将列表中的数据合并为一个numpy数组
            #清楚前面的数据，滑窗
            received_data_list = received_data_list[int(a*1):]
            audio = received_data.astype(np.float32)
            audio = audio / 32768.0
            voice_queue.put(audio)

        if exit_event.is_set():
            break



def process_mfcc_audio(voice):
    # 加载音频文件并设置采样率为44100
    orig_sr = 48000
    target_sr = 44100
    resampled_audio = librosa.resample(voice, orig_sr=orig_sr, target_sr=target_sr)
    #resampled_audio = resampled_audio / np.max(np.abs(resampled_audio))
    
    # 创建一个图形窗口和两个子图
    # fig, axs = plt.subplots(2, 1, figsize=(10, 8))
    
    # 绘制原始音频波形
    # axs[0].plot(voice)
    # axs[0].set_title('Original Audio Waveform')
    # axs[0].set_ylabel('Amplitude')
    # axs[0].set_xlabel('Sample Index')
    
   # print(len(resampled_audio))
    # average_amplitude = np.mean(np.abs(resampled_audio))

    # 找到第一个大于平均幅值的索引
    # for index, value in enumerate(resampled_audio):
    #     if np.abs(value) > 0.025:
    #         break
    # # 再从后面往前找到第一个大于平均幅值的索引
    # for index2, value in enumerate(resampled_audio[::-1]):
    #     if np.abs(value) > 0.025:
    #         break

    # # 计算从后往前的索引对应的正向索引
    # index2 = len(resampled_audio) - index2 - 1
    # resampled_audio = resampled_audio[index:]
    #归一化
    resampled_audio = resampled_audio / np.max(np.abs(resampled_audio))
    # 绘制处理后的音频波形
    # axs[1].plot(resampled_audio)
    # axs[1].set_title('Processed Audio Waveform')
    # axs[1].set_ylabel('Amplitude')
    # axs[1].set_xlabel('Sample Index')
    
    # 显示图形
    # plt.tight_layout()  # 调整子图间距
    # plt.show()
    
    # print(len(resampled_audio))
    
    # 对于少于4秒的音频文件，在末尾用零填充
    if len(resampled_audio) < 2 * target_sr:
        resampled_audio = np.pad(resampled_audio, pad_width=(0, 2 * target_sr - len(resampled_audio)), mode='constant')
    
    # 将音频文件转换为mfcc
    signal = librosa.feature.mfcc(y=resampled_audio, sr=target_sr, n_mfcc=80)
    signal = np.array(signal)
    signal = (signal + 0.7870202) / 32.789604
    signal = np.expand_dims(signal, axis=0)
    signal = np.expand_dims(signal, axis=-1)

    # 返回处理后的音频特征
    return signal
# 音频情绪推理线程

def calculate_short_term_energy(audio_data, frame_size=2048, hop_length=512):
    energy = np.array([
        sum(abs(audio_data[i:i+frame_size]**2))
        for i in range(0, len(audio_data), hop_length)
    ])
    return energy


def is_silence(energy, threshold=0.0001):
    # 计算小于阈值的元素所占的比例
    silence_ratio = np.mean(energy < threshold)
    # 判断比例是否超过0.4
    #print(silence_ratio)
    return silence_ratio > 0.5

def voice_emotion_prosse(queue):
    # 模型路径
    #model_path = 'emotion_recognition_mel_spec.keras'
    model_path = r'C:\Users\paihui\Speech-Emotion-Recognition-in-Tensorflow-Using-CNNs\sound_classification\sound_classification_sound8k_xiaoai.keras'
    # 加载模型
    model = tf.keras.models.load_model(model_path)
    labels = [
    "air_conditioner",
    "car_horn",
    "children_playing",
    "dog_bark",
    "drilling",
    "engine_idling",
    "explosion",
    "gun_shot",
    "jackhammer",
    "scream",
    "siren",
    "street_music",
    "xiaoai"
]
    while not exit_event.is_set() :
        if not queue.empty():
            audio_data = queue.get()
            energy = calculate_short_term_energy(audio_data)
            # 判断是否为无声段
            if is_silence(energy):
                continue  # 如果是无声段，则跳过后续处理
            mel_spectrogram = process_mfcc_audio(audio_data)
            # 使用模型进行预测
            prediction = model.predict(mel_spectrogram)
            # 使用np.argmax找到最高概率的索引
            predicted_index = np.argmax(prediction)
            # 使用索引从标签列表中获取情感标签
            emotion = labels[predicted_index]
            print(emotion)

# 创建并启动线程
thread1 = threading.Thread(target=udp_receive_data)
thread2 = threading.Thread(target=voice_emotion_prosse, args=(voice_queue,))

thread1.start()
thread2.start()

try:
    while not exit_event.is_set():
        time.sleep(0.1)
except KeyboardInterrupt:
    exit_event.set()
    print("Exit event set by KeyboardInterrupt")

# 等待线程执行完毕
thread1.join()
thread2.join()

print("Main thread exiting.")
