#!/bin/bash

# AI语音助手后端 - 停止脚本
# 根据SERVICE_TYPE环境变量停止相应服务

SERVICE_TYPE=${SERVICE_TYPE:-both}

echo "AI语音助手后端停止中..."
echo "停止服务类型: $SERVICE_TYPE"

# 停止ASR服务的函数
stop_asr() {
    echo "停止ASR服务..."
    # 查找并终止ASR相关进程
    pids=$(ps aux | grep '[p]ython.*launcher.py' | awk '{print $2}')
    if [ -n "$pids" ]; then
        for pid in $pids; do
            echo "终止ASR进程 PID: $pid"
            kill -TERM $pid 2>/dev/null
            sleep 1
            # 如果进程仍在运行，强制终止
            if kill -0 $pid 2>/dev/null; then
                echo "强制终止ASR进程 PID: $pid"
                kill -KILL $pid 2>/dev/null
            fi
        done
        echo "ASR服务已停止"
    else
        echo "未找到运行中的ASR服务"
    fi
}

# 停止TTS服务的函数
stop_tts() {
    echo "停止TTS服务..."
    # 查找并终止TTS相关进程
    pids=$(ps aux | grep '[p]ython.*cli.py' | grep 'tts\|run' | awk '{print $2}')
    if [ -n "$pids" ]; then
        for pid in $pids; do
            echo "终止TTS进程 PID: $pid"
            kill -TERM $pid 2>/dev/null
            sleep 1
            # 如果进程仍在运行，强制终止
            if kill -0 $pid 2>/dev/null; then
                echo "强制终止TTS进程 PID: $pid"
                kill -KILL $pid 2>/dev/null
            fi
        done
        echo "TTS服务已停止"
    else
        echo "未找到运行中的TTS服务"
    fi
}

# 根据SERVICE_TYPE参数执行相应的停止操作
if [ "$SERVICE_TYPE" = "asr" ]; then
    stop_asr
elif [ "$SERVICE_TYPE" = "tts" ]; then
    stop_tts
else
    echo "停止所有服务..."
    stop_tts
    stop_asr
fi

echo "服务停止完成" 