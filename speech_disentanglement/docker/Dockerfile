# Reproducible training environment for PVT-Lite.
# Use CUDA image on a GPU host; for CPU-only smoke tests, base off python:3.11-slim.
FROM nvcr.io/nvidia/pytorch:24.04-py3

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /workspace

RUN apt-get update && apt-get install -y --no-install-recommends \
        libsndfile1 ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY speech_disentanglement/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Source mounted at /workspace at run-time:
#   docker run --gpus all -v "$PWD":/workspace pvt-lite \
#       python -m speech_disentanglement.training.pretrain_speaker --config ...
