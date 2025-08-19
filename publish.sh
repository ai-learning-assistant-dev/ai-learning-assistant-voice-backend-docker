#!/bin/bash

# AI语音服务后端 - Docker镜像发布脚本
# 支持发布到多个容器镜像仓库

set -e

# 配置参数
IMAGE_NAME="ai-voice-backend"
TAG="v1.0"
LOCAL_IMAGE="${IMAGE_NAME}:${TAG}"

# 用户配置 - 请修改以下参数
DOCKER_HUB_USERNAME="your-dockerhub-username"
ALIYUN_REGION="cn-hangzhou"  # 可选: cn-beijing, cn-shanghai, cn-hangzhou, cn-shenzhen
ALIYUN_USERNAME="your-aliyun-username"
ALIYUN_NAMESPACE="your-aliyun-namespace"
GITHUB_USERNAME="your-github-username"
TENCENT_USERNAME="your-tencent-username"
TENCENT_NAMESPACE="your-tencent-namespace"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查本地镜像是否存在
check_local_image() {
    if ! docker images | grep -q "^${IMAGE_NAME}.*${TAG}"; then
        print_error "本地镜像 ${LOCAL_IMAGE} 不存在"
        print_info "请先运行: docker build -t ${LOCAL_IMAGE} ."
        exit 1
    fi
    print_info "找到本地镜像: ${LOCAL_IMAGE}"
}

# 发布到Docker Hub
publish_to_dockerhub() {
    print_info "准备发布到Docker Hub..."
    
    if [ "$DOCKER_HUB_USERNAME" = "your-dockerhub-username" ]; then
        print_warn "请先在脚本中配置 DOCKER_HUB_USERNAME"
        return 1
    fi
    
    # 打标签
    DOCKERHUB_IMAGE="${DOCKER_HUB_USERNAME}/${IMAGE_NAME}"
    docker tag ${LOCAL_IMAGE} ${DOCKERHUB_IMAGE}:${TAG}
    
    # 推送
    print_info "推送到Docker Hub: ${DOCKERHUB_IMAGE}:${TAG}"
    docker push ${DOCKERHUB_IMAGE}:${TAG}
    
    # 可选：如果这是最新版本，也推送latest标签
    read -p "是否同时推送latest标签? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker tag ${LOCAL_IMAGE} ${DOCKERHUB_IMAGE}:latest
        docker push ${DOCKERHUB_IMAGE}:latest
        print_info "latest标签也已推送"
    fi
    
    print_info "Docker Hub发布成功!"
    print_info "拉取命令: docker pull ${DOCKERHUB_IMAGE}:${TAG}"
}

# 发布到阿里云
publish_to_aliyun() {
    print_info "准备发布到阿里云容器镜像服务..."
    
    if [ "$ALIYUN_USERNAME" = "your-aliyun-username" ] || [ "$ALIYUN_NAMESPACE" = "your-aliyun-namespace" ]; then
        print_warn "请先在脚本中配置 ALIYUN_USERNAME 和 ALIYUN_NAMESPACE"
        return 1
    fi
    
    # 打标签
    ALIYUN_REGISTRY="registry.${ALIYUN_REGION}.aliyuncs.com"
    ALIYUN_IMAGE="${ALIYUN_REGISTRY}/${ALIYUN_NAMESPACE}/${IMAGE_NAME}"
    docker tag ${LOCAL_IMAGE} ${ALIYUN_IMAGE}:${TAG}
    docker tag ${LOCAL_IMAGE} ${ALIYUN_IMAGE}:latest
    
    # 推送
    print_info "推送到阿里云: ${ALIYUN_IMAGE}:${TAG}"
    docker push ${ALIYUN_IMAGE}:${TAG}
    docker push ${ALIYUN_IMAGE}:latest
    
    print_info "阿里云发布成功!"
    print_info "拉取命令: docker pull ${ALIYUN_IMAGE}:${TAG}"
}

# 发布到GitHub Container Registry
publish_to_github() {
    print_info "准备发布到GitHub Container Registry..."
    
    if [ "$GITHUB_USERNAME" = "your-github-username" ]; then
        print_warn "请先在脚本中配置 GITHUB_USERNAME"
        return 1
    fi
    
    # 打标签
    GITHUB_IMAGE="ghcr.io/${GITHUB_USERNAME}/${IMAGE_NAME}"
    docker tag ${LOCAL_IMAGE} ${GITHUB_IMAGE}:${TAG}
    docker tag ${LOCAL_IMAGE} ${GITHUB_IMAGE}:latest
    
    # 推送
    print_info "推送到GitHub: ${GITHUB_IMAGE}:${TAG}"
    docker push ${GITHUB_IMAGE}:${TAG}
    docker push ${GITHUB_IMAGE}:latest
    
    print_info "GitHub Container Registry发布成功!"
    print_info "拉取命令: docker pull ${GITHUB_IMAGE}:${TAG}"
}

# 发布到腾讯云
publish_to_tencent() {
    print_info "准备发布到腾讯云容器镜像服务..."
    
    if [ "$TENCENT_USERNAME" = "your-tencent-username" ] || [ "$TENCENT_NAMESPACE" = "your-tencent-namespace" ]; then
        print_warn "请先在脚本中配置 TENCENT_USERNAME 和 TENCENT_NAMESPACE"
        return 1
    fi
    
    # 打标签
    TENCENT_IMAGE="ccr.ccs.tencentyun.com/${TENCENT_NAMESPACE}/${IMAGE_NAME}"
    docker tag ${LOCAL_IMAGE} ${TENCENT_IMAGE}:${TAG}
    
    # 推送
    print_info "推送到腾讯云: ${TENCENT_IMAGE}:${TAG}"
    docker push ${TENCENT_IMAGE}:${TAG}
    
    print_info "腾讯云发布成功!"
    print_info "拉取命令: docker pull ${TENCENT_IMAGE}:${TAG}"
}

# 显示帮助信息
show_help() {
    echo "AI语音服务后端 - Docker镜像发布脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  dockerhub    发布到Docker Hub"
    echo "  aliyun       发布到阿里云容器镜像服务"
    echo "  github       发布到GitHub Container Registry"
    echo "  tencent      发布到腾讯云容器镜像服务"
    echo "  all          发布到所有已配置的仓库"
    echo "  help|-h      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 aliyun          # 仅发布到阿里云"
    echo "  $0 dockerhub       # 仅发布到Docker Hub"
    echo "  $0 all             # 发布到所有仓库"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi
    
    check_local_image
    
    case "$1" in
        "dockerhub")
            publish_to_dockerhub
            ;;
        "aliyun")
            publish_to_aliyun
            ;;
        "github")
            publish_to_github
            ;;
        "tencent")
            publish_to_tencent
            ;;
        "all")
            print_info "发布到所有已配置的仓库..."
            publish_to_dockerhub || true
            publish_to_aliyun || true
            publish_to_github || true
            publish_to_tencent || true
            ;;
        "help"|"-h")
            show_help
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@" 