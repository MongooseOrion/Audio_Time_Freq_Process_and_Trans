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
    i = 0 # 用于检测连续有声段
    j = 0 # 用于检测连续无声段 
    flag = 0  # 用于标记是否检测到开始的声音
    while not exit_event.is_set():
        data, addr = udp_socket.recvfrom(BUFFER_SIZE)
        #打印data的长度
        #print(len(data))
        data1 = np.frombuffer(data, dtype=np.int16)
        data1 = data1 / 32768.0  
        received_data_list.append(data1)  # 将数据添加到列表中
        if sum(abs(data1[:]**2))>0.0001:
            i = i + 1
            j = 0
            # print('11111111111111')
        else:
            i = 0
            j = j + 1

        if i > 3:
            flag = 1

        if flag == 0 and len(received_data_list) > 0.7*a :   #没有检测到声音，每1s清掉前一半一次数据，防止数据过多
            received_data_list = received_data_list[int(a*0.35):]
        elif flag == 1 and j > 0.4*a:  #检测到声音，且连续0.5s没有声音，音频采集结束
            flag = 0
            received_data = np.concatenate(received_data_list)  # 将列表中的数据合并为一个numpy数组
            audio = received_data.astype(np.float32)
            voice_queue.put(audio)
            print('当前说话人采集完成')

        if exit_event.is_set():
            break


def extract_mfcc(audio, n_mfcc=30, sr=48000, hop_length=512, n_fft=1024):
    """
    提取指定路径音频的MFCC特征。

    参数:
    - audio: 音频数据。
    - n_mfcc: 要提取的MFCC特征的数量。
    - sr: 音频的采样率。
    - hop_length: 帧移，即每个窗口的样本数。
    - n_fft: FFT窗口的大小。

    返回:
    - mfccs: 音频的MFCC特征。
    """

    #剪掉开头和结尾的静音部分
    audio, _ = librosa.effects.trim(audio)
    #归一化音频数据
    audio = audio / np.max(np.abs(audio))
    # 提取MFCC特征
    mfccs = librosa.feature.mfcc(y=audio, sr=sr, n_mfcc=n_mfcc, hop_length=hop_length, n_fft=n_fft)
    # 转置MFCC特征，使其维度为(时间步长, 特征数量)
    mfccs = mfccs.T

    return mfccs

def lbg(features, M):
    """
    LBG算法实现矢量量化。

    参数:
    - features: 特征矩阵，形状为(N, D)，其中N是样本数，D是特征维度。
    - M: 码本的大小。

    返回:
    - codebook: 生成的码本，形状为(M, D)。
    """
    eps = 0.01  # 用于初始化码本分裂的小扰动值
    N, D = features.shape
    codebook = np.mean(features, axis=0).reshape(1, -1)  # 初始化码本为所有特征的平均值

    while codebook.shape[0] < M:
        # 分裂步骤
        new_codebook = []
        for code in codebook:
            new_codebook.append(code * (1 + eps))
            new_codebook.append(code * (1 - eps))
        codebook = np.array(new_codebook)

        i = 0
        while True:
            i += 1
            # 分配步骤
            distances = np.sqrt(((features[:, np.newaxis, :] - codebook[np.newaxis, :, :]) ** 2).sum(axis=2))
            closest_code_indices = np.argmin(distances, axis=1)

            # 更新步骤
            new_codebook = []
            for j in range(codebook.shape[0]):
                if np.any(closest_code_indices == j):
                    # 如果某个码本被分配到至少一个样本，则计算新的码本值
                    new_codebook.append(features[closest_code_indices == j].mean(axis=0))
                else:
                    # 如果某个码本没有被分配到任何样本，则不进行更新，保留原码本值
                    new_codebook.append(codebook[j])
            new_codebook = np.array(new_codebook)

            if np.linalg.norm(codebook - new_codebook) < eps:
                # print(f'Converged in {i} iterations.')
                break
            codebook = new_codebook

    return codebook

#计算当前的mfcc结果到码本的最小距离，将features的每个样本与codebook的每个码本计算距离，返回当前样本到码本的最小距离，重复操作，返回所有样本到码本的最小距离和
def calculate_distortion(features, codebook):
    """
    计算当前的mfcc结果到码本的最小距离

    参数:
    - features: 特征矩阵，形状为(N, D)，其中N是样本数，D是特征维度。
    - codebook: 码本，形状为(M, D)。

    返回:
    - distortion: 失真度。
    """
    # 计算每个样本到每个码本的距离
    distances = np.sqrt(((features[:, np.newaxis, :] - codebook[np.newaxis, :, :]) ** 2).sum(axis=2))
    # 计算每个样本到最近码本的距离
    min_distances = np.min(distances, axis=1)
    # 计算失真度
    distortion = min_distances.sum()/features.shape[0]

    return distortion



def vocal_classification(queue):
    #如果queue 不为空，取出音频数据，提取mfcc特征，进行分类
    print('vocal_classification')
    codebooks = []
    audio_to_codebook = []
    while not exit_event.is_set() :
        if not queue.empty():
            print('queue is not empty')
            audio = queue.get()
            #绘制出音频波形
            # plt.figure()
            # plt.plot(audio)
            # plt.show()
            mfcc = extract_mfcc(audio)
            min_distortion = float('inf')
            min_codebook_index = -1

            # 计算与现有码本的calculate_distortion
            for i, codebook in enumerate(codebooks):
                distortion = calculate_distortion(mfcc, codebook)
                if distortion < min_distortion:
                    min_distortion = distortion
                    min_codebook_index = i

            # 判断是否生成新码本
            if min_distortion > 73:
                codebooks.append(lbg(mfcc, 32))  # 创建新的码本
                print(f"为当前说话人创建新码本",len(codebooks)-1)
            # 归类到现有码本，新建一个表格，记录音频文件和码本的索引

            else:
                print(f"归类到现有码本{min_codebook_index}")


# 创建并启动线程
thread1 = threading.Thread(target=udp_receive_data)
thread2 = threading.Thread(target=vocal_classification, args=(voice_queue,))

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
