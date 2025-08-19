import importlib.metadata
import os
from os import path
from typing import Annotated, Optional, Union
from urllib.parse import quote

import click
import uvicorn
from fastapi import FastAPI, File, Query, UploadFile, applications
from fastapi.openapi.docs import get_swagger_ui_html
from fastapi.responses import RedirectResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from app.config import CONFIG
from app.factory.asr_model_factory import ASRModelFactory
from app.utils import load_audio

# SenseVoice支持的语言列表
SENSEVOICE_LANGUAGES = {
    "zh": "Chinese",
    "en": "English", 
    "ja": "Japanese",
    "ko": "Korean",
    "yue": "Cantonese"
}

# 延迟模型加载，避免导入时的错误
asr_model = None

def get_asr_model():
    """获取ASR模型，延迟加载"""
    global asr_model
    if asr_model is None:
        print("正在加载ASR模型...")
        asr_model = ASRModelFactory.create_asr_model()
        asr_model.load_model()
        print(f"✓ ASR模型加载完成: {CONFIG.ASR_ENGINE}")
    return asr_model

LANGUAGE_CODES = sorted(SENSEVOICE_LANGUAGES.keys())

# 使用默认的应用元数据
try:
    # 预留扩展：将来可能从自定义包获取元数据
    raise importlib.metadata.PackageNotFoundError("使用默认配置")
except importlib.metadata.PackageNotFoundError:
    # 默认元数据（当包未正式安装时使用）
    app_name = "VoiceWebserver SenseVoice Edition"
    app_description = "VoiceWebserver - 专注于SenseVoice的语音识别Web服务"
    app_version = "2.0-sensevoice-only"
    app_homepage = "https://github.com/iic/SenseVoice"
    app_license = "MIT License"

app = FastAPI(
    title=app_name,
    description=app_description,
    version=app_version,
    contact={"url": app_homepage},
    swagger_ui_parameters={"defaultModelsExpandDepth": -1},
    license_info={"name": "MIT License", "url": app_license},
)

assets_path = os.getcwd() + "/swagger-ui-assets"
if path.exists(assets_path + "/swagger-ui.css") and path.exists(assets_path + "/swagger-ui-bundle.js"):
    app.mount("/assets", StaticFiles(directory=assets_path), name="static")

    def swagger_monkey_patch(*args, **kwargs):
        return get_swagger_ui_html(
            *args,
            **kwargs,
            swagger_favicon_url="",
            swagger_css_url="/assets/swagger-ui.css",
            swagger_js_url="/assets/swagger-ui-bundle.js",
        )

    applications.get_swagger_ui_html = swagger_monkey_patch


@app.get("/", response_class=RedirectResponse, include_in_schema=False)
async def index():
    return "/docs"


@app.post("/asr", tags=["Endpoints"])
async def asr(
    audio_file: UploadFile = File(...),  # noqa: B008
    encode: bool = Query(default=True, description="Encode audio first through ffmpeg"),
    task: Union[str, None] = Query(default="transcribe", enum=["transcribe", "translate"]),
    language: Union[str, None] = Query(default=None, enum=LANGUAGE_CODES),
    initial_prompt: Union[str, None] = Query(default=None),
    vad_filter: Annotated[
        Optional[bool],
        Query(
            description="Enable the voice activity detection (VAD) to filter out parts of the audio without speech",
            include_in_schema=False,  # SenseVoice不支持VAD配置
        ),
    ] = False,
    word_timestamps: bool = Query(
        default=False,
        description="Word level timestamps",
        include_in_schema=False,  # SenseVoice不支持词级时间戳
    ),
    output: Union[str, None] = Query(default="txt", enum=["txt", "vtt", "srt", "tsv", "json"]),
):
    # 在使用时才加载模型
    model = get_asr_model()
    result = model.transcribe(
        load_audio(audio_file.file, encode),
        task,
        language,
        initial_prompt,
        vad_filter,
        word_timestamps,
        {},  # SenseVoice暂不支持说话人分离功能
        output,
    )
    return StreamingResponse(
        result,
        media_type="text/plain",
        headers={
            "Asr-Engine": CONFIG.ASR_ENGINE,
            "Content-Disposition": f'attachment; filename="{quote(audio_file.filename)}.{output}"',
        },
    )


@app.post("/detect-language", tags=["Endpoints"])
async def detect_language(
    audio_file: UploadFile = File(...),  # noqa: B008
    encode: bool = Query(default=True, description="Encode audio first through FFmpeg"),
):
    # 在使用时才加载模型
    model = get_asr_model()
    detected_lang_code, confidence = model.language_detection(load_audio(audio_file.file, encode))
    return {
        "detected_language": SENSEVOICE_LANGUAGES.get(detected_lang_code, "Unknown"),
        "language_code": detected_lang_code,
        "confidence": confidence,
    }


@click.command()
@click.option(
    "-h",
    "--host",
    metavar="HOST",
    default="0.0.0.0",
    help="Host for the webservice (default: 0.0.0.0)",
)
@click.option(
    "-p",
    "--port",
    metavar="PORT",
    default=9000,
    help="Port for the webservice (default: 9000)",
)
@click.version_option(version=app_version)  # 使用我们定义的版本变量
def start(host: str, port: Optional[int] = None):
    # 在启动服务前预加载模型
    print("正在启动VoiceWebserver...")
    get_asr_model()  # 预加载模型
    print(f"服务启动在 http://{host}:{port}")
    uvicorn.run(app, host=host, port=port)


if __name__ == "__main__":
    start()
