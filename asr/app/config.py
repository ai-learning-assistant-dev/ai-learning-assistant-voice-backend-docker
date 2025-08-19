import os

import torch


class CONFIG:
    """
    Configuration class for ASR models.
    Reads environment variables for runtime configuration, with sensible defaults.
    """
    # Determine the ASR engine (only 'sensevoice' is supported)
    ASR_ENGINE = os.getenv("ASR_ENGINE", "sensevoice")

    # Retrieve Huggingface Token (used by some models for downloading)
    HF_TOKEN = os.getenv("HF_TOKEN", "")

    # Determine the computation device (GPU or CPU)
    DEVICE = os.getenv("ASR_DEVICE", "cuda" if torch.cuda.is_available() else "cpu")

    # 注意：SenseVoice使用自己的模型配置，不需要传统的MODEL_NAME和MODEL_PATH

    # SenseVoice specific configurations
    SENSEVOICE_MODEL = os.getenv("SENSEVOICE_MODEL", "iic/SenseVoiceSmall")
    SENSEVOICE_MODEL_REVISION = os.getenv("SENSEVOICE_MODEL_REVISION", "v1.0.0")

    # ASR默认语言设置（用于避免Docker环境中的语言检测问题）
    ASR_DEFAULT_LANGUAGE = os.getenv("ASR_DEFAULT_LANGUAGE", "zh")

    # 注意：SenseVoice不使用量化配置，此配置已移除

    # Idle timeout in seconds. If set to a non-zero value, the model will be unloaded
    # after being idle for this many seconds. A value of 0 means the model will never be unloaded.
    MODEL_IDLE_TIMEOUT = int(os.getenv("MODEL_IDLE_TIMEOUT", 0))

    # Default sample rate for audio input. 16 kHz is commonly used in speech-to-text tasks.
    SAMPLE_RATE = int(os.getenv("SAMPLE_RATE", 16000))

    # Subtitle output options
    SUBTITLE_MAX_LINE_WIDTH = int(os.getenv("SUBTITLE_MAX_LINE_WIDTH", 1000))
    SUBTITLE_MAX_LINE_COUNT = int(os.getenv("SUBTITLE_MAX_LINE_COUNT", 2))
    SUBTITLE_HIGHLIGHT_WORDS = os.getenv("SUBTITLE_HIGHLIGHT_WORDS", "false").lower() == "true"

    # FFmpeg configuration - 优先使用本地FFmpeg
    @staticmethod
    def get_ffmpeg_path():
        """
        获取FFmpeg可执行文件路径，优先使用项目本地版本
        """
        # 项目根目录
        project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        
        # 本地FFmpeg路径
        local_ffmpeg = os.path.join(project_root, "packages", "ffmpeg-win64", 
                                  "ffmpeg-master-latest-win64-gpl", "bin", "ffmpeg.exe")
        
        # 如果本地FFmpeg存在，使用本地版本
        if os.path.exists(local_ffmpeg):
            print(f"使用本地FFmpeg: {local_ffmpeg}")
            return local_ffmpeg
        
        # 否则使用环境变量或系统PATH中的FFmpeg
        ffmpeg_path = os.getenv("FFMPEG_PATH", "ffmpeg")
        print(f"使用系统FFmpeg: {ffmpeg_path}")
        return ffmpeg_path

    # FFmpeg路径
    FFMPEG_PATH = get_ffmpeg_path.__func__()
