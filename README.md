# TTS自动模型选择功能说明

## 功能概述

该功能允许TTS服务根据运行环境自动选择最合适的模型：
- **CUDA环境**：自动选择 `index-tts` 模型（GPU加速）
- **CPU环境**：自动选择 `kokoro` 模型（CPU优化）

## 音色控制

本地对应模型/voices挂载到 /app/tts/models/index-tts/voices 和 /app/tts/models/kokoro/voices

# 使用方法
## 启动容器
```bash
# 导入镜像
docker load -i ai-voice-backend-image-1.0.tar

docker run -d --name ai-voice-backend --gpus all -p 8000:8000 -p 9000:9000 ai-voice-backend:v1.0 tail -f /dev/null
```
## 关闭容器
```bash
docker stop ai-voice-backend
```

## docker exec 启动服务

### 自动检测模式（默认）
```bash
# 启动所有服务
docker exec ai-voice-backend ./start.sh

# 只启动ASR服务
docker exec -e SERVICE_TYPE=asr ai-voice-backend ./start.sh

# 只启动TTS服务
docker exec -e SERVICE_TYPE=tts ai-voice-backend ./start.sh
```

### 手动指定模型
如果需要强制使用特定模型，可以设置环境变量：

```bash
# 强制使用kokoro模型
docker exec -e TTS_MODELS=kokoro ai-voice-backend ./start.sh

# 强制使用index-tts模型
docker exec -e TTS_MODELS=index-tts ai-voice-backend ./start.sh
```

# 关闭服务

```bash
# 关闭所有服务
docker exec ai-voice-backend ./stop.sh

# 只关闭ASR服务
docker exec -e SERVICE_TYPE=asr ai-voice-backend ./stop.sh

# 只关闭TTS服务
docker exec -e SERVICE_TYPE=tts ai-voice-backend ./stop.sh
```

# 服务监控

```bash
# 关闭所有服务
# 测试TTS服务状态
docker exec -e SERVICE_TYPE=tts ai-voice-backend ./status.sh

# 测试ASR服务状态  
docker exec -e SERVICE_TYPE=asr ai-voice-backend ./status.sh

# 测试所有服务状态
docker exec ai-voice-backend ./status.sh
# 返回结果
{  
    "asr": {"status": "running", "model": "sensevoice", "pid": 31}, 
    "tts": {"status": "stopped"}
}
```

# 镜像构建与导出

```bash
./build.sh

docker save ai-voice-backend:v1.0 -o ai-voice-backend-image-1.0.tar

```
