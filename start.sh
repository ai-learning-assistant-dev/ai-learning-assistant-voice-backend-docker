#!/bin/bash

# AI语音助手后端 - 主启动脚本
# 根据SERVICE_TYPE环境变量启动相应服务

SERVICE_TYPE=${SERVICE_TYPE:-both}

echo "AI语音助手后端启动中..."
echo "服务类型: $SERVICE_TYPE"

if [ "$SERVICE_TYPE" = "asr" ]; then
    echo "启动ASR服务..."
    ./start_asr.sh
elif [ "$SERVICE_TYPE" = "tts" ]; then
    echo "启动TTS服务..."
    ./start_tts.sh
else
    echo "启动所有服务..."
    # 后台启动TTS服务
    ./start_tts.sh &
    # 前台启动ASR服务
    ./start_asr.sh
fi 