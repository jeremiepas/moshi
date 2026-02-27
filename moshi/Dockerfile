# Multi-stage Dockerfile for Moshi PyTorch Backend
# Production-ready with CUDA support

FROM nvidia/cuda:12.1.0-devel-ubuntu22.04 as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /build

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-dev \
    python3-pip \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN python3.10 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy requirements first for better layer caching
COPY requirements.txt .
RUN python3.10 -m pip install --no-cache-dir -r requirements.txt

# Copy the package
COPY . /build/moshi/

# Install moshi
RUN cd /build/moshi && python3.10 -m pip install --no-cache-dir -e .

# Runtime stage
FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV HF_REPO=kyutai/moshiko-pytorch-bf16
ENV PYTHONPATH=/app

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-distutils \
    libportaudio2 \
    libsndfile1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy Python and installed packages from builder
COPY --from=builder /usr/local/lib/python3.10 /usr/local/lib/python3.10
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/lib/python3.10 /usr/lib/python3.10

# Set working directory
WORKDIR /app

# Copy application code
COPY --from=builder /build/moshi /app/moshi

# Create cache directory for huggingface
RUN mkdir -p /root/.cache/huggingface

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8998/health 2>/dev/null || python3.10 -c "import urllib.request; urllib.request.urlopen('http://localhost:8998/health')" 2>/dev/null || exit 1

# Expose the port
EXPOSE 8998

# Run the server
CMD ["python3.10", "-m", "moshi.server", "--gradio-tunnel", "--hf-repo", "kyutai/moshiko-pytorch-bf16"]
