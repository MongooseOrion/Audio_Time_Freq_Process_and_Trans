import librosa
import numpy as np

def extract_mfcc(audio_path, n_mfcc=13, sr=22050, hop_length=512, n_fft=2048):
    """
    提取指定路径音频的MFCC特征。

    参数:
    - audio_path: 音频文件的路径。
    - n_mfcc: 要提取的MFCC特征的数量。
    - sr: 音频的采样率。
    - hop_length: 帧移，即每个窗口的样本数。
    - n_fft: FFT窗口的大小。

    返回:
    - mfccs: 音频的MFCC特征。
    """
    # 加载音频文件
    audio, sr = librosa.load(audio_path, sr=sr)
    # 提取MFCC特征
    mfccs = librosa.feature.mfcc(y=audio, sr=sr, n_mfcc=n_mfcc, hop_length=hop_length, n_fft=n_fft)
    # 转置MFCC特征，使其维度为(时间步长, 特征数量)
    mfccs = mfccs.T

    return mfccs