import tkinter as tk
from tkinter import messagebox
from tkinter.scrolledtext import ScrolledText  # 导入ScrolledText模块
import serial
import time
import threading
import threading
import socket
import numpy as np
import time
from queue import Queue
import numpy as np
import librosa
import tensorflow as tf
import numpy as np
import gc
from tkinter import ttk, messagebox
import serial.tools.list_ports
def clear_log():
    log_text.config(state='normal')  # 确保日志区是可编辑的
    log_text.delete(1.0, tk.END)  # 删除日志区的所有内容

loop_flag2 = False

def audio_start(flag):
    global loop_flag2
    send_serial_command("00")
    if flag == True:
        loop_flag2 = True
        log_message1("接收 UDP 音频数据并播放...")
        thread2 = threading.Thread(target=audio_play)
        thread2.start()
    elif flag == False:
        loop_flag2 = False
        log_message1("接收停止。")
def audio_play():
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
    RATE = 48000
    # 设置音频参数
    FORMAT = pyaudio.paInt16
    CHANNELS = 1
    CHUNK = 1024  # 每次读取的音频数据大小

    # 设置 UDP 参数
    UDP_IP = "192.168.0.3"
    UDP_PORT = 8080
    global loop_flag2
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
        while loop_flag2:
            data, addr = sock.recvfrom(1024)  # 从UDP套接字接收数据

            stream.write(data)  # 播放音频数据

    except KeyboardInterrupt:
        print("接收停止。")

    finally:
        stream.stop_stream()
        stream.close()
        p.terminate()
        sock.close()

def wait_for_serial_data(serial_port='/dev/ttyUSB0', baud_rate=9600, timeout=10):
    """
    等待并接收串口数据，直到有数据接入或超时。
    
    参数:
    - serial_port: 串口名称
    - baud_rate: 波特率
    - timeout: 超时时间（秒）
    
    返回:
    - 接收到的数据字符串，如果超时则返回None
    """
    end_time = time.time() + timeout
    try:
        with serial.Serial(serial_port, baud_rate, timeout=1) as ser:
            while time.time() < end_time:
                if ser.in_waiting > 0:
                    #不编码，16进制显示
                    data = ser.read(ser.in_waiting).hex()
                    if str(data) == '00':
                        return '说话人0'
                    elif str(data) == '01':
                        return '说话人1'
                    elif str(data) == '02':
                        return '说话人2'
                    elif str(data) == '03':
                        return '说话人3'
                    else:
                        return "无匹配结果"
            return "没有接收到结果"
    except serial.SerialException as e:
        print(f"打开串口时发生错误: {e}")
        return None
#串口端口设置
def list_serial_ports():
    """列出所有可用的串口"""
    ports = serial.tools.list_ports.comports()
    return [port.device for port in ports]

def open_serial_port(port):
    """打开选定的串口"""
    try:
        ser = serial.Serial(port, 9600, timeout=1)
        messagebox.showinfo("成功", f"已连接到串口 {port}")
        return ser
    except serial.SerialException as e:
        messagebox.showerror("错误", f"无法连接到串口 {port}\n{e}")
        return None

def create_serial_window():
    """创建串口检测窗口"""
    
    def refresh_ports():
        ports = list_serial_ports()
        port_combobox['values'] = ports
        if ports:
            port_combobox.current(0)

    def connect_port():
        global select_port
        selected_port = port_combobox.get()
        if selected_port:
            ser = open_serial_port(selected_port)
            if ser:
                select_port = selected_port
                pass

    window = tk.Toplevel()
    window.title("串口检测")

    frame = ttk.Frame(window, padding="10")
    frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

    port_label = ttk.Label(frame, text="选择串口:")
    port_label.grid(row=0, column=0, padx=5, pady=5)

    port_combobox = ttk.Combobox(frame, state="readonly")
    port_combobox.grid(row=0, column=1, padx=5, pady=5)

    refresh_button = ttk.Button(frame, text="刷新", command=refresh_ports)
    refresh_button.grid(row=0, column=2, padx=5, pady=5)

    connect_button = ttk.Button(frame, text="连接", command=connect_port)
    connect_button.grid(row=1, column=0, columnspan=3, pady=10)

    refresh_ports()
    window.grab_set()  # 确保窗口是模态的

#串口发送指令
def send_serial_command(command_hex):
    global select_port
    port = select_port  # 串口
    baudrate = 9600  # 波特率
    try:
        ser = serial.Serial(port, baudrate, timeout=1)
        ser.write(bytes.fromhex(command_hex))
        #根据command_hex参数，在日志区显示相应的模式
        if command_hex == '00':
            clear_log()
            log_message("当前 FPGA 模式为音频回传")
        elif command_hex == '10':
            clear_log()
            log_message("当前 FPGA 模式为回声消除")
        elif command_hex == '19':
            log_message("增大衰减系数")
        elif command_hex == '1a':
            log_message("减小衰减系数")
        elif command_hex == '11':
            log_message("增大延迟系数")
        elif command_hex == '12':
            log_message("减小延迟系数")
        elif command_hex == '21':
            clear_log()
            log_message("当前 FPGA 模式为变童声")
        elif command_hex == '22':
            log_message("当前 FPGA 模式为变男声")
        elif command_hex == '30':
            clear_log()
            log_message("当前 FPGA 模式为音频去噪")
        elif command_hex == '41':
            clear_log()
            log_message("当前 FPGA 模式为分离人声")
        elif command_hex == '42':
            log_message("当前 FPGA 模式为分离音乐")
        elif command_hex == '43':
            log_message("当前 FPGA 模式为去除旋律")
        elif command_hex == '44':
            log_message("当前 FPGA 模式为分离旋律")
        elif command_hex == '45':
            log_message("当前 FPGA 模式为分离歌声中的人声")
        elif command_hex == '50':
            clear_log()
            log_message("当前 FPGA 模式为声纹识别")
            log_message("正在进行声纹训练(说话人 0)")
        elif command_hex == '51':
            log_message("正在进行声纹训练(说话人 1)")
        elif command_hex == '52':
            log_message("正在进行声纹训练(说话人 2)")
        elif command_hex == '53':
            log_message("正在进行声纹训练(说话人 3)")
        elif command_hex == '58':
            log_message("正在进行声纹识别")
        elif command_hex == 'a1':
            clear_log()
            log_message("开始录音")
        elif command_hex == 'a2':
            log_message("停止录音")
        elif command_hex == 'a8':
            log_message("录音播放")

        time.sleep(0.05)
        ser.close()
    except serial.SerialException as e:
        log_message(f"发送指令时出错: {e}")

def log_message(message):
    # 定义红色文本标签
    log_text.tag_configure('gray', foreground='#888888')
    
    # 插入消息
    log_text.insert(tk.END, message + "\n", 'gray')
    log_text.see(tk.END)  # 自动滚动到最新的日志消息

#人物画像####################################################################################
def calculate_short_term_energy(audio_data, frame_size=2048, hop_length=512):
    energy = np.array([
        sum(abs(audio_data[i:i+frame_size]**2))
        for i in range(0, len(audio_data), hop_length)
    ])
    return energy


def is_silence(energy, threshold=0.00005):
    # 计算小于阈值的元素所占的比例
    silence_ratio = np.mean(energy < threshold)
    # 判断比例是否超过0.4
    #print(silence_ratio)
    return silence_ratio > 0.6

def process_mfcc_audio(voice,model_select):
    # 加载音频文件并设置采样率为44100
    orig_sr = 48000
    target_sr = 44100
    resampled_audio = librosa.resample(voice, orig_sr=orig_sr, target_sr=target_sr)
    #归一化
    resampled_audio = resampled_audio / np.max(np.abs(resampled_audio))
    # 对于少于4秒的音频文件，在末尾用零填充
    if len(resampled_audio) < 2 * target_sr:
        resampled_audio = np.pad(resampled_audio, pad_width=(0, 2 * target_sr - len(resampled_audio)), mode='constant')
    
    # 将音频文件转换为mfcc
    signal = librosa.feature.mfcc(y=resampled_audio, sr=target_sr, n_mfcc=80)
    signal = np.array(signal)
    if model_select == 0:
        signal = (signal + 3.123193) / 45.4772
    elif model_select == 1:
        signal = (signal + 0.7870202) / 32.789604
    elif model_select == 2:
        signal = (signal + 1.908909) / 37.53181
    signal = np.expand_dims(signal, axis=0)
    signal = np.expand_dims(signal, axis=-1)

    # 返回处理后的音频特征
    return signal

voice_queue = Queue()

loop_flag = False
loop_flag1 = False
model_select = 3          # 0: 人物画像 1: 声音分类   2：变声检测

#以太网接收数据
def udp_receive_data():
    log_message("udp_receive_data start")
    received_data_list = []  # 使用列表收集数据
    global loop_flag
    global model_select
    UDP_IP = "192.168.0.3"
    UDP_PORT = 8080
    BUFFER_SIZE = 1024
    udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_socket.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, BUFFER_SIZE*10)
    udp_socket.bind((UDP_IP, UDP_PORT))
    sr = 48000
    a = int(sr/512)
    i = 0
    while loop_flag:
        data, addr = udp_socket.recvfrom(BUFFER_SIZE)
        #打印data的长度
        #print(len(data))
        data1 = np.frombuffer(data, dtype=np.int16)
        received_data_list.append(data1)  # 将数据添加到列表中
        if len(received_data_list) >= 2*a:
            received_data = np.concatenate(received_data_list)  # 将列表中的数据合并为一个numpy数组
            #清楚前面0.7s数据
            if model_select == 0:
                received_data_list = received_data_list[int(a*0.7):]
            else :
                received_data_list = received_data_list[int(a*1):]
            audio = received_data.astype(np.float32)
            audio = audio / 32768.0
            voice_queue.put(audio)
    log_message("udp_receive_data exit")


def model_load(queue):
    global loop_flag
    global model_select
    
    # 模型路径
    #model_path = 'emotion_recognition_mel_spec.keras'
    if model_select == 0:
        model_path = r'C:\Users\smn90\repo\FPGA_Audio_Noise_Gate\model\emotion_recognition_mfcc_batch_16_trim_not_1_2s_mfcc80_nomaliza.keras'
        log_message("人物画像启动")
        labels = ['女性 愤怒',
          '女性 快乐',
          '女性 中性',
          '女性 悲伤',
          '女性 惊讶',
          '男性 愤怒',
          '男性 快乐',
          '男性 中性',
          '男性 悲伤',
          '男性 惊讶']
    elif model_select == 1:
        model_path = r'C:\Users\smn90\repo\FPGA_Audio_Noise_Gate\model\sound_classification_sound8k_xiaoai.keras'
        log_message("声音分类启动")
        labels = [
        "空调外机声",
        "喇叭声",
        "儿童嬉闹声",
        "狗吠声",
        "钻孔声",
        "引擎轰鸣声",
        "爆炸声",
        "枪击声",
        "手提钻运行声",
        "尖叫声",
        "警笛声",
        "街头音乐声",
        "唤醒声（小爱同学）"
         ]
    elif model_select == 2:
        model_path = r'C:\Users\smn90\repo\FPGA_Audio_Noise_Gate\model\change_voice.keras'
        log_message("变声检测启动")
        labels = [ "伪造声音", "真实声音"]  
    # 加载模型
    model = tf.keras.models.load_model(model_path)
    # 生成一个随机的音频文件mel_spectrogram，预启动模型
    mel_spectrogram = np.random.rand(1, 80,173, 1)
    prediction = model.predict(mel_spectrogram)
    while loop_flag :
        if not queue.empty():
            audio_data = queue.get()
            energy = calculate_short_term_energy(audio_data)
            # 判断是否为无声段
            if is_silence(energy):
                continue  # 如果是无声段，则跳过后续处理
            mel_spectrogram = process_mfcc_audio(audio_data,model_select)
            # 使用模型进行预测
            prediction = model.predict(mel_spectrogram)
            # 使用np.argmax找到最高概率的索引
            predicted_index = np.argmax(prediction)
            # 使用索引从标签列表中获取情感标签
            emotion = labels[predicted_index]

            if np.max(prediction) > 0.92 and emotion != '女性 悲伤' and emotion != '狗吠声' :
                log_message1(emotion + "  " + str(np.max(prediction)))
            elif np.max(prediction) > 0.99:
                log_message1(emotion + "  " + str(np.max(prediction)))
            else:
                log_message1("none")
    model_select = 3
    log_message(f"模型推理线程已经退出")
    del model  # 假设model是全局变量，如果不是，需要适当调整
    gc.collect()
#传入一个启动或者关闭的标志位
def voice_emotion(flag):
    global loop_flag
    global model_select
    send_serial_command('00')
    clear_log1()
    if  loop_flag == True and flag == True:
        log_message("请先停止当前模式")
    else:
        model_select = 0
        loop_flag = flag
        if loop_flag:
            clear_log()
            thread1 = threading.Thread(target=udp_receive_data)
            thread2 = threading.Thread(target=model_load, args=(voice_queue,))
            thread1.start()
            thread2.start()

#声音分类####################################################################################
def sound_classification(flag):
    global loop_flag
    global model_select
    clear_log1()
    send_serial_command('00')
    if  loop_flag == True and flag == True:
        log_message("请先停止当前模式")
    else:
        model_select = 1
        loop_flag = flag
        if loop_flag:
            clear_log()
            thread1 = threading.Thread(target=udp_receive_data)
            thread2 = threading.Thread(target=model_load, args=(voice_queue,))
            thread1.start()
            thread2.start()

#变声检测####################################################################################
def change_voice(flag):
    global loop_flag
    global model_select
    send_serial_command('00')
    clear_log1()
    if  loop_flag == True and flag == True:
        log_message("请先停止当前模式")
    else:
        model_select = 2
        loop_flag = flag
        if loop_flag:
            clear_log()
            thread1 = threading.Thread(target=udp_receive_data)
            thread2 = threading.Thread(target=model_load, args=(voice_queue,))
            thread1.start()
            thread2.start()

#声纹分类####################################################################################
def udp_receive_data1():
    received_data_list = []  # 使用列表收集数据
    log_message("以太网接收数据线程启动")
    global loop_flag1
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
    while loop_flag1:
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

        if flag == 0 and len(received_data_list) > 0.6*a :   #没有检测到声音，每1s清掉前一半一次数据，防止数据过多
            received_data_list = received_data_list[int(a*0.3):]
        elif flag == 1 and j > 0.4*a:  #检测到声音，且连续0.4s没有声音，音频采集结束
            flag = 0
            received_data = np.concatenate(received_data_list)  # 将列表中的数据合并为一个numpy数组
            audio = received_data.astype(np.float32)
            voice_queue.put(audio)
            log_message('当前说话人采集完成')

    log_message("分类完成，以太网接收数据线程退出")


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
    global loop_flag1
    audio_to_codebook = []
    while loop_flag1 :
        if not queue.empty():
            print('queue is not empty')
            start_timo = time.time()
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
            
            print('min_distortion:',min_distortion)
            # 判断是否生成新码本
            if min_distortion > 74:
                codebooks.append(lbg(mfcc, 32))  # 创建新的码本
                log_message("为当前说话人创建新码本"+str(len(codebooks)-1))
                log_message1("出现新声纹，定义为说话人"+str(len(codebooks)-1))
            # 归类到现有码本，新建一个表格，记录音频文件和码本的索引
            else:
                log_message("归类到现有码本"+str(min_codebook_index))
                log_message1("归类到现有声纹：说话人"+str(min_codebook_index))
            end_time = time.time()
            print('time:',end_time-start_timo)
    log_message(f"声纹分类线程已经退出")

def vocal_classification_start(flag):
    send_serial_command('00')
    global loop_flag1
    if flag == True:
        loop_flag1 = True
    elif flag == False:
        loop_flag1 = False
    if loop_flag1:
        clear_log()
        log_message("声纹分类启动")
        thread1 = threading.Thread(target=udp_receive_data1)
        thread2 = threading.Thread(target=vocal_classification, args=(voice_queue,))
        thread1.start()
        thread2.start()
    else:
        loop_flag1 = False



def show_options(category):
    # 清除右边Frame中的所有内容
    for widget in options_frame.winfo_children():
        widget.destroy()

    # 定义一个字典，将每个分类映射到对应的选项和处理函数
    options_functions = {
        "音频回传": {"音频回传": lambda: send_serial_command('00'),
            "以太网音频播放": lambda:audio_start(True) ,
            "停止以太网音频播放":lambda:audio_start(False)},
        "回声消除": {
            "回声消除": lambda: send_serial_command('10'),
            "增大衰减系数": lambda: send_serial_command('19'),
            "减小衰减系数": lambda: send_serial_command('1a'),
            "增大延迟系数": lambda: send_serial_command('11'),
            "减小延迟系数": lambda: send_serial_command('12')
        },
        "人声调整": {
            "变得稍尖锐": lambda: send_serial_command('21'),
            "变得稍低沉": lambda: send_serial_command('22')
        },
        "音频去噪": {"音频去噪": lambda: send_serial_command('30'),
                    "伪自适应去噪": lambda: send_serial_command('31')},
        "人声分离": {
            "仅保留说话人声": lambda: send_serial_command('41'),
            "保留旋律和唱歌人声": lambda: send_serial_command('42'),
            "保留唱歌人声和说话人声": lambda: send_serial_command('43'),
            "仅保留旋律": lambda: send_serial_command('44'),
            "仅保留唱歌人声": lambda: send_serial_command('45')
        },
        "声纹识别": {
            "训练说话人 0": lambda: send_serial_command('50'),
            "训练说话人 1": lambda: send_serial_command('51'),
            "训练说话人 2": lambda: send_serial_command('52'),
            "训练说话人 3": lambda: send_serial_command('53'),
            "声纹识别": lambda: send_serial_command('58')
        },
        "人声分类": {
            "启动人声分类": lambda: vocal_classification_start(True),
            "停止人声分类": lambda: vocal_classification_start(False)
        },
        "人物画像": {
            "启动人物画像": lambda: voice_emotion(True),
            "停止人物画像": lambda: voice_emotion(False)
        },
        "声音分类": {
            "启动声音分类": lambda: sound_classification(True),
            "停止声音分类": lambda: sound_classification(False)
        },
        "变声检测": {
            "启动变声检测": lambda: change_voice(True),
            "停止变声检测": lambda: change_voice(False)
        },
        "音频录音": {
            "开始录音": lambda: send_serial_command('a1'),
            "停止录音": lambda: send_serial_command('a2'),
            "录音播放": lambda: send_serial_command('a8')
        },
        "串口设置": {
             "打开串口检测窗口": lambda: create_serial_window()
        }

    }
    # 计数器，用于跟踪当前是第几个按钮
    counter = 0
    # 根据点击的大分区，动态添加选项按钮,选项按钮大于5个的，后面5个按钮从右边另起一列布局
    left_frame = tk.Frame(options_frame)
    right_frame = tk.Frame(options_frame)
    # 将框架放置在窗口中
    left_frame.pack(side=tk.LEFT, fill="both", expand=True)
    right_frame.pack(side=tk.RIGHT, fill="both", expand=True)
    for option, function in options_functions.get(category, {}).items():
        # 根据counter的值决定使用哪个框架
        if counter < 5:
            parent_frame = left_frame
        else:
            parent_frame = right_frame
        
        # 创建按钮并放置在相应的框架中
        button = tk.Button(parent_frame, text=option, command=function, bg="#eeeeee", fg="black", borderwidth=2, font=('微软雅黑', 14), relief=tk.FLAT)
        button.pack(pady=7, padx=20, fill="x")
        button.pack_propagate(False)  # 防止按钮调整到文本大小
        button.config(width=20)  # 设置所有按钮的宽度相同
        
        # 更新计数器
        counter += 1

root = tk.Tk()
root.title("功能选择")
root.geometry("1180x705")

# 创建左边的Frame用于显示大分区
categories_frame = tk.Frame(root, width=200, height=705, bg="lightgrey")  # 蓝色背景
categories_frame.place(x=0, y=0)  # 放置在窗口的左上角

# 创建右边的Frame用于动态显示内容
options_frame = tk.Frame(root, width=590, height=300, bg="#dddddd")  # 绿色背景
options_frame.place(x=200, y=0)  # 放置在categories_frame的右边

# 创建日志区的Frame
log_frame = tk.Frame(root, width=980, height=405, bg="#dddddd")  # 黄色背景
log_frame.place(x=200, y=300)  # 放置在options_frame的下方
# 创建ScrolledText控件用于显示日志
log_text = ScrolledText(log_frame, height=5, font=('微软雅黑', 13))  # 将字体大小调整为14
log_text.place(x=0, y=0, width=980, height=405)  # 填充log_frame的整个区域

# #再创建一个结果区的Frame
result_frame = tk.Frame(root, width=390, height=300, bg="#dddddd")  # 黄色背景
result_frame.place(x=790, y=0)  # 放置在options_frame的右边
# 创建ScrolledText控件用于显示日志
result_text = ScrolledText(result_frame, height=5, font=('微软雅黑', 15))  # 将字体大小调整为14
result_text.place(x=50, y=50, width=300, height=200)  # 填充log_frame的整个区域
# 创建一个函数，用于清除日志区的内容
def clear_log1():
    result_text.config(state='normal')  # 确保日志区是可编辑的
    result_text.delete(1.0, tk.END)  # 删除日志区的所有内容

# 创建一个函数，用于日志区添加新的消息
def log_message1(message):
    result_text.insert(tk.END, message + "\n")
    result_text.see(tk.END)  # 自动滚动到最新的日志消息

# 在左边的Frame中添加大分区按钮，同时调整样式
buttons_info = [
    ("音频回传", lambda: show_options("音频回传")),
    ("回声消除", lambda: show_options("回声消除")),
    ("人声调整", lambda: show_options("人声调整")),
    ("音频去噪", lambda: show_options("音频去噪")),
    ("人声分离", lambda: show_options("人声分离")),
    ("声纹识别", lambda: show_options("声纹识别")),
    ("人声分类", lambda: show_options("人声分类")),  # 注意：重复的按钮，可能需要调整
    ("人物画像", lambda: show_options("人物画像")),
    ("声音分类", lambda: show_options("声音分类")),
    ("变声检测", lambda: show_options("变声检测")),
    ("音频录音", lambda: show_options("音频录音")),
    ("串口设置", lambda: show_options("串口设置"))
]

for text, command in buttons_info:
    tk.Button(categories_frame, \
              text=text, \
              command=command, \
              bg="lightgrey", \
              fg="black", \
              borderwidth=2, \
              font=('微软雅黑', 16), \
              relief=tk.FLAT).pack(pady=5, padx=48, fill="x")


# 示例：向日志区写入信息
log_text.insert(tk.END, "日志信息显示区...\n")



root.mainloop()