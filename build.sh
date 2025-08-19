#!/bin/bash

# AI语音助手后端 - 离线版本构建脚本
# 此脚本将构建一个包含所有预下载模型的Docker镜像

echo "=================================="
echo "AI语音助手后端 - 离线版本构建"
echo "=================================="

# 检查模型目录是否存在
if [ ! -d "models_cache" ]; then
    echo "错误: models_cache 目录不存在！"
    echo "请确保您已经下载了所需的模型到 models_cache 目录中"
    exit 1
fi


# 显示模型目录大小
echo "正在检查模型文件大小..."
MODELS_SIZE=$(du -sh models_cache/ | cut -f1)
echo "models_cache 目录大小: $MODELS_SIZE"

# 设置构建标签
IMAGE_NAME="ai-voice-backend"
TAG="v1.1"

echo ""
echo "开始构建 Docker 镜像..."
echo "镜像名称: $IMAGE_NAME:$TAG"

# 构建镜像
docker build \
    --no-cache \
    --tag "$IMAGE_NAME:$TAG" \
    --file Dockerfile \
    . 

# 检查构建结果
if [ $? -eq 0 ]; then
    echo ""
    echo "=================================="
    echo "构建成功完成！"
    echo "=================================="
    echo "镜像标签:"
    echo "  - $IMAGE_NAME:$TAG"
    
    # 显示镜像信息
    echo ""
    echo "镜像信息:"
    docker images | grep "$IMAGE_NAME" | head -1
    
    echo ""
    echo "使用方法:"
    echo "直接运行容器:"
    echo "   docker run -d --gpus all -p 8000:8000 -p 9000:9000 $IMAGE_NAME:$TAG"
    
else
    echo ""
    echo "=================================="
    echo "构建失败！"
    echo "=================================="
    echo "请检查构建日志中的错误信息"
    exit 1
fi 