from app.asr_models.asr_model import ASRModel
from app.asr_models.sensevoice_engine import SenseVoiceEngine
from app.config import CONFIG


class ASRModelFactory:
    @staticmethod
    def create_asr_model() -> ASRModel:
        if CONFIG.ASR_ENGINE == "sensevoice":
            return SenseVoiceEngine()
        else:
            raise ValueError(f"Unsupported ASR engine: {CONFIG.ASR_ENGINE}. Only 'sensevoice' is supported.")
