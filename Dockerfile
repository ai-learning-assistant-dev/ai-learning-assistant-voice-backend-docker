# AI语音助手后端 - 统一Dockerfile（离线版本-预打包模型）
# 包含ASR和TTS两个服务，共享相同的运行环境，模型预打包在镜像中
# 使用CUDA 12.6基础镜像以支持最新GPU架构（如RTX 4060的compute_89）
FROM docker.io/pytorch/pytorch:2.7.0-cuda12.6-cudnn9-runtime

# 设置工作目录
WORKDIR /app

# 更换为国内软件源（解决网络问题）
# 选项1: 阿里云源
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

# RUN sed -i 's/archive.ubuntu.com/repo.huaweicloud.com/g' /etc/apt/sources.list && \
#     sed -i 's/security.ubuntu.com/repo.huaweicloud.com/g' /etc/apt/sources.list

# RUN sed -i 's/archive.ubuntu.com/mirrors.cloud.tencent.com/g' /etc/apt/sources.list && \
#     sed -i 's/security.ubuntu.com/mirrors.cloud.tencent.com/g' /etc/apt/sources.list


# 安装基础依赖和CUDA 12.x工具包
RUN apt-get update && \
    apt-get install -y ffmpeg wget gnupg2 && \
    # 添加NVIDIA CUDA软件源
    wget -O /tmp/cuda-keyring.deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i /tmp/cuda-keyring.deb && \
    apt-get update && \
    # 安装CUDA 12.6工具包（与基础镜像版本匹配）
    apt-get install -y cuda-toolkit-12-6 && \
    # 清理缓存
    rm -rf /var/lib/apt/lists/* /tmp/cuda-keyring.deb

# 配置pip源和超时设置
RUN pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/ && \
    pip3 config set global.extra-index-url "https://pypi.org/simple/ https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple/" && \
    pip3 config set global.timeout 300 && \
    pip3 config set global.retries 3

RUN pip3 install --no-cache-dir --timeout 60 --retries 3 \
    https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.7.1/en_core_web_sm-3.7.1-py3-none-any.whl || \
    pip3 install --no-cache-dir --timeout 60 --retries 3 en_core_web_sm==3.7.1 || \
    echo "Warning: spacy model download failed, will download at runtime"

# 复制项目代码
COPY asr/ /app/asr/
COPY tts/ /app/tts/
COPY requirements.txt /app/requirements.txt

# 安装统一依赖 - 分步安装解决依赖冲突
RUN pip3 install --no-cache-dir num2words && \
    pip3 install --no-cache-dir -r /app/requirements.txt

# 安装各个TTS模型的特定依赖
RUN cd /app/tts/models/index-tts && pip3 install --no-cache-dir -r requirements.txt

# 复制预下载的模型文件到镜像中
# 这样模型就直接打包在镜像里，不需要运行时下载或挂载
COPY models_cache/ /app/models_cache/

# 确保模型目录权限正确
RUN chmod -R 755 /app/models_cache/

# 设置环境变量 - 使用镜像内的模型路径
ENV ASR_ENGINE=sensevoice
ENV ASR_DEVICE=cuda
ENV DEFAULT_MODEL=kokoro
ENV AUDIO_SAMPLE_RATE=24000
ENV CUDA_VISIBLE_DEVICES=0
ENV MODELSCOPE_CACHE=/app/models_cache/modelscope
ENV HF_HOME=/app/models_cache/huggingface
ENV SENSEVOICE_MODEL=/app/models_cache/modelscope/models/iic/SenseVoiceSmall

# 设置CUDA环境变量
ENV CUDA_HOME=/usr/local/cuda-12.6
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# 复制启动脚本
COPY start.sh /app/start.sh
COPY start_asr.sh /app/start_asr.sh
COPY start_tts.sh /app/start_tts.sh
COPY stop.sh /app/stop.sh
COPY status.sh /app/status.sh

# 设置脚本权限
RUN chmod +x /app/start.sh /app/start_asr.sh /app/start_tts.sh

# 暴露端口
EXPOSE 8000 9000

# 设置启动命令 - 保持容器运行，等待手动启动服务
CMD ["tail", "-f", "/dev/null"] 