![Licence](https://img.shields.io/github/license/ahmetoner/whisper-asr-webservice.svg)

# VoiceWebserver

VoiceWebserver 是一个通用的语音工具包。基于[Whisper ASR Box](https://github.com/ahmetoner/whisper-asr-webservice)开发。

## 特性

当前版本仅支持以下语音识别引擎：
- [SenseVoice](https://github.com/iic/SenseVoice) - 专注于中文语音识别，效果优秀

## 快速开始

### 内置FFmpeg支持
项目已包含FFmpeg，无需单独安装：
- FFmpeg位于: `packages/ffmpeg-win64/ffmpeg-master-latest-win64-gpl/bin/`
- 项目会自动优先使用本地FFmpeg，确保即开即用

### 一键部署
```shell
1.安装依赖（首次运行）：
点击install.bat，安装完成后配置PATH环境变量。

2.启动服务：
点击start_smart.bat

3.打开浏览器访问 http://localhost:9000
```

### 使用 Poetry 安装
```shell
# 安装 poetry（如果尚未安装）
pip3 install poetry

# 安装依赖
poetry install

# 运行服务
ASR_ENGINE=sensevoice ASR_DEVICE=cuda python launcher.py --host 0.0.0.0 --port 9000
```

## 主要特性

- 专注于 SenseVoice 引擎，提供优质的中文语音识别
- 支持多种输出格式（文本、JSON、VTT、SRT、TSV）
- 支持词级时间戳
- 支持语音活动检测（VAD）过滤
- 集成 FFmpeg 支持多种音频/视频格式
- 支持 GPU 加速
- 可配置的模型加载/卸载
- REST API 和 Swagger 文档

## 环境变量配置

主要配置选项：

- `ASR_ENGINE`: 引擎选择（固定为 sensevoice）
- `ASR_DEVICE`: 设备选择（cuda, cpu）
- `MODEL_IDLE_TIMEOUT`: 模型卸载超时时间
- `SENSEVOICE_MODEL`: SenseVoice 模型名称（默认为 "iic/SenseVoiceSmall"）
- `SENSEVOICE_MODEL_REVISION`: SenseVoice 模型版本（默认为 "v1.0.0"）

## 开发

启动服务后，访问 `http://localhost:9000` 或 `http://0.0.0.0:9000` 查看 Swagger UI 文档并测试 API 端点。

## 故障排除

### 常见问题
1. **CUDA问题**: 设置环境变量 `ASR_DEVICE=cpu`
2. **模型下载**: SenseVoice模型会自动下载，首次运行需要时间
3. **FFmpeg**: 项目已包含本地FFmpeg，无需额外安装

## 致谢

- 本项目使用了 [FFmpeg](http://ffmpeg.org) 项目的库，遵循 [LGPLv2.1](http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html) 许可
