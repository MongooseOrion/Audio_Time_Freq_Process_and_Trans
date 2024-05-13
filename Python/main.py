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
# 主处理程序
import func_ctrl as fc

# 文件路径
sound_model_file = '../model/sound_classification.h5'
sound_classes = '../model/classes.txt'

emotion_model_file = '../model/emotion_voice_detection.h5'
emotion_model_config = '../model/model.json'
emotion_classes = '../model/Predictions.csv'

#fc.sound_classify_predict(sound_model_file, sound_classes)
#fc.emotion_gender_classify_predict(emotion_model_file, emotion_model_config, emotion_classes)
fc.audio_play()