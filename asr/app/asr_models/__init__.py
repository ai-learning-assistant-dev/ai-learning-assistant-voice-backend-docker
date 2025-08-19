"""
ASR模型实现模块 - 仅支持SenseVoice
"""

from .asr_model import ASRModel
from .sensevoice_engine import SenseVoiceEngine

__all__ = [
    'ASRModel',
    'SenseVoiceEngine'
] 