#!/bin/bash

# TTS服务启动脚本

echo "启动TTS服务..."
cd /app/tts

# 检查是否指定了具体的TTS模型
if [ -n "${TTS_MODELS}" ]; then
    echo "使用指定的TTS模型: ${TTS_MODELS}"
    python3 cli.py run --model-names ${TTS_MODELS} --port ${TTS_PORT:-8000}
else
    echo "未指定TTS模型，启用自动检测模式"
    python3 cli.py run --auto-detect --port ${TTS_PORT:-8000}
fi 