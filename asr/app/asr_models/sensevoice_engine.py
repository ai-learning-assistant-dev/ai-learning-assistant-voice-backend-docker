import os
import time
from io import StringIO
from typing import Union, Tuple

import torch
from funasr import AutoModel
from funasr.utils.postprocess_utils import rich_transcription_postprocess
from app.utils import ResultWriter, WriteJSON, WriteSRT, WriteTSV, WriteTXT, WriteVTT

from app.asr_models.asr_model import ASRModel
from app.config import CONFIG


class SenseVoiceEngine(ASRModel):
    """
    SenseVoice ASR engine implementation.
    """

    def __init__(self):
        super().__init__()
        self.model_name = CONFIG.SENSEVOICE_MODEL

    def load_model(self):
        """
        Loads the SenseVoice model.
        """
        with self.model_lock:
            if self.model is None:
                # 强制使用本地缓存的模型路径
                local_model_path = os.getenv("SENSEVOICE_MODEL", self.model_name)
                vad_model_path = os.getenv("MODELSCOPE_CACHE", "/app/models_cache/modelscope") + "/models/iic/speech_fsmn_vad_zh-cn-16k-common-pytorch"
                
                # 检查本地模型是否存在
                if os.path.exists(local_model_path):
                    print(f"使用本地SenseVoice模型: {local_model_path}")
                    model_to_use = local_model_path
                else:
                    print(f"本地模型不存在，使用模型ID: {self.model_name}")
                    model_to_use = self.model_name
                
                # 检查VAD模型是否存在
                if os.path.exists(vad_model_path):
                    print(f"使用本地VAD模型: {vad_model_path}")
                    vad_model_to_use = vad_model_path
                else:
                    print(f"本地VAD模型不存在，使用默认: fsmn-vad")
                    vad_model_to_use = "fsmn-vad"
                
                # 在Docker环境中，需要移除remote_code参数或使用绝对路径
                # 因为SenseVoice官方模型已经包含了所需的代码
                self.model = AutoModel(
                    model=model_to_use,
                    trust_remote_code=True,
                    # 移除remote_code参数，让模型使用内置代码
                    # remote_code="./model.py",
                    vad_model=vad_model_to_use,
                    vad_kwargs={"max_single_segment_time": 30000},
                    device=CONFIG.DEVICE,
                )
                self.last_activity_time = time.time()

    def transcribe(
        self,
        audio,
        task: Union[str, None],
        language: Union[str, None],
        initial_prompt: Union[str, None],
        vad_filter: Union[bool, None],
        word_timestamps: Union[bool, None],
        options: Union[dict, None],
        output,
    ):
        """
        Perform transcription using SenseVoice.
        """
        self.load_model()
        self.last_activity_time = time.time()

        # 设置语言，优先使用中文，避免Docker环境下的语言检测问题
        if language is None:
            # 在Docker环境中默认使用中文，避免多语言混合识别
            language = CONFIG.ASR_DEFAULT_LANGUAGE
            print(f"未指定语言，使用默认语言: {language}")
        
        print(f"使用语言设置: {language}")

        # 执行转录 - 添加更严格的语言控制
        result = self.model.generate(
            input=audio,
            cache={},
            language=language,  # "zh", "en", "yue", "ja", "ko", "nospeech"
            use_itn=True,
            batch_size_s=60,
            merge_vad=True,
            merge_length_s=15,
            # 添加更严格的参数控制，避免多语言混合
            ban_emo_unk=True,  # 禁用情感和未知标记
        )

        # 处理输出
        if isinstance(result, list):
            text = rich_transcription_postprocess(result[0]["text"])
            detected_language = result[0].get("language", "unknown")
        else:
            text = rich_transcription_postprocess(result["text"])
            detected_language = result.get("language", "unknown")


        # 构建结果字典，确保格式与 ResultWriter 期望的一致
        result_dict = {
            "text": text,
            "segments": [{
                "text": text,
                "start": 0.0,
                "end": 0.0,
                "words": []
            }],
            "language": detected_language if language == "auto" else language
        }

        # 创建输出文件
        output_file = StringIO()
        self.write_result(result_dict, output_file, output)
        output_file.seek(0)

        return output_file

    def write_result(self, result: dict, file: StringIO, output: Union[str, None]):
        """
        Write the transcription result to the specified output format.
        """
        options = {
            "max_line_width": CONFIG.SUBTITLE_MAX_LINE_WIDTH,
            "max_line_count": CONFIG.SUBTITLE_MAX_LINE_COUNT,
            "highlight_words": CONFIG.SUBTITLE_HIGHLIGHT_WORDS
        }
        
        if output == "srt":
            WriteSRT("").write_result(result, file, options)
        elif output == "vtt":
            WriteVTT("").write_result(result, file, options)
        elif output == "tsv":
            WriteTSV("").write_result(result, file, options)
        elif output == "json":
            WriteJSON("").write_result(result, file, options)
        else:
            WriteTXT("").write_result(result, file, options)

    def language_detection(self, audio) -> Tuple[str, float]:
        """
        Perform language detection using SenseVoice.
        Returns a tuple of (language_code, confidence).
        """
        self.load_model()
        self.last_activity_time = time.time()

        # 使用 SenseVoice 进行语言检测
        result = self.model.generate(
            input=audio,
            cache={},
            language="auto",
            use_itn=False,
            batch_size_s=60,
            merge_vad=True,
            merge_length_s=15,
        )

        # 返回检测到的语言代码和置信度
        if isinstance(result, list):
            return result[0].get("language", "unknown"), 1.0
        return result.get("language", "unknown"), 1.0 