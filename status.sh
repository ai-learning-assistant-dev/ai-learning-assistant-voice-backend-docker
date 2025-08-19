#!/bin/bash

# AI语音助手后端 - 状态检查脚本
# 根据SERVICE_TYPE环境变量检查相应服务状态和使用的模型

SERVICE_TYPE=${SERVICE_TYPE:-both}

# 检测CUDA环境是否可用（与cli.py中的逻辑一致）
detect_cuda_environment() {
    # 检查nvidia-smi是否可用
    if nvidia-smi >/dev/null 2>&1; then
        return 0  # CUDA可用
    else
        return 1  # CUDA不可用
    fi
}

# 获取ASR模型信息
get_asr_model() {
    # ASR默认使用sensevoice模型，可以通过环境变量ASR_ENGINE自定义
    local asr_engine="${ASR_ENGINE:-sensevoice}"
    echo "$asr_engine"
}

# 检查ASR服务状态
check_asr_status() {
    local asr_pid=$(ps aux | grep '[p]ython.*launcher.py' | awk '{print $2}' | head -1)
    if [ -n "$asr_pid" ]; then
        local model=$(get_asr_model)
        echo "{\"asr\": {\"status\": \"running\", \"model\": \"$model\", \"pid\": $asr_pid}}"
    else
        echo "{\"asr\": {\"status\": \"stopped\"}}"
    fi
}

# 获取TTS进程中使用的模型
get_tts_model_from_process() {
    local tts_process=$(ps aux | grep '[p]ython.*cli.py' | grep 'run' | head -1)
    
    if [ -z "$tts_process" ]; then
        return 1
    fi
    
    # 检查进程参数中是否有 --model-names
    if echo "$tts_process" | grep -q '\--model-names'; then
        # 提取 --model-names 后的模型名
        local model=$(echo "$tts_process" | sed -n 's/.*--model-names[[:space:]]\+\([^[:space:]]\+\).*/\1/p')
        echo "$model"
        return 0
    fi
    
    # 检查是否有 --auto-detect 参数或没有指定模型（自动检测模式）
    if echo "$tts_process" | grep -q '\--auto-detect' || ! echo "$tts_process" | grep -q '\--model-names'; then
        # 根据CUDA环境自动推断模型
        if detect_cuda_environment; then
            echo "index-tts"
        else
            echo "kokoro"
        fi
        return 0
    fi
    
    # 默认返回空
    return 1
}

# 检查TTS服务状态
check_tts_status() {
    local tts_pid=$(ps aux | grep '[p]ython.*cli.py' | grep 'run' | awk '{print $2}' | head -1)
    
    if [ -n "$tts_pid" ]; then
        local model=$(get_tts_model_from_process)
        if [ -n "$model" ]; then
            echo "{\"tts\": {\"status\": \"running\", \"model\": \"$model\", \"pid\": $tts_pid}}"
        else
            echo "{\"tts\": {\"status\": \"running\", \"model\": \"unknown\", \"pid\": $tts_pid}}"
        fi
    else
        echo "{\"tts\": {\"status\": \"stopped\"}}"
    fi
}

# 检查所有服务状态
check_all_status() {
    local asr_pid=$(ps aux | grep '[p]ython.*launcher.py' | awk '{print $2}' | head -1)
    local tts_pid=$(ps aux | grep '[p]ython.*cli.py' | grep 'run' | awk '{print $2}' | head -1)
    
    local asr_status="stopped"
    local tts_status="stopped"
    local asr_model=""
    local tts_model="unknown"
    
    if [ -n "$asr_pid" ]; then
        asr_status="running"
        asr_model=$(get_asr_model)
    fi
    
    if [ -n "$tts_pid" ]; then
        tts_status="running"
        tts_model=$(get_tts_model_from_process)
        if [ -z "$tts_model" ]; then
            tts_model="unknown"
        fi
    fi
    
    if [ "$asr_status" = "running" ]; then
        asr_json="\"asr\": {\"status\": \"$asr_status\", \"model\": \"$asr_model\", \"pid\": $asr_pid}"
    else
        asr_json="\"asr\": {\"status\": \"$asr_status\"}"
    fi
    
    if [ "$tts_status" = "running" ]; then
        tts_json="\"tts\": {\"status\": \"$tts_status\", \"model\": \"$tts_model\", \"pid\": $tts_pid}"
    else
        tts_json="\"tts\": {\"status\": \"$tts_status\"}"
    fi
    
    echo "{$asr_json, $tts_json}"
}

# 根据SERVICE_TYPE参数执行相应的检查操作
case "$SERVICE_TYPE" in
    "asr")
        check_asr_status
        ;;
    "tts")
        check_tts_status
        ;;
    "both"|*)
        check_all_status
        ;;
esac 