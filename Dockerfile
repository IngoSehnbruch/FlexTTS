# Use CUDA-enabled Python base image
FROM nvidia/cuda:12.1.0-devel-ubuntu22.04

# Set environment variables
ENV PYTHONWARNINGS=ignore
ENV TRANSFORMERS_VERBOSITY=error
ENV TORCH_WARN_ONCE=1
ENV DEBIAN_FRONTEND=noninteractive
# Don't write .pyc files
ENV PYTHONDONTWRITEBYTECODE=1
# Don't buffer output
ENV PYTHONUNBUFFERED=1

# Install system dependencies and Python 3.9
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y \
    python3.9 \
    python3.9-dev \
    python3.9-distutils \
    build-essential \
    libsndfile1 \
    pkg-config \
    git \
    curl \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.9 \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
RUN mkdir -p /app
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Check CUDA availability and install appropriate PyTorch version
RUN if nvidia-smi; then \
        echo "*** CUDA IS AVAILABLE *** -> installing PyTorch with CUDA support" && \
        python3.9 -m pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121; \
    fi

RUN if ! nvidia-smi; then \
        echo "*** CUDA IS NOT AVAILABLE *** -> installing CPU-only PyTorch" && \
        python3.9 -m pip install --no-cache-dir torch torchvision torchaudio; \
    fi

# Install Python dependencies
RUN python3.9 -c "import torch; print('CUDA installed:', torch.cuda.is_available()); print('CUDA device count:', torch.cuda.device_count()); print('CUDA version:', torch.version.cuda if torch.cuda.is_available() else 'N/A')" && \
    python3.9 -m pip install --no-cache-dir -r requirements.txt

# Copy all application files
COPY . /app/

# Create necessary directories
RUN mkdir -p /app/data/speakers /app/static/audio

# Set TTS_HOME for model storage
ENV TTS_HOME=/app/data

# Expose the port the app runs on
EXPOSE 6969

# Command to run the app with reload
CMD ["flask", "run", "--host=0.0.0.0", "--port=6969", "--reload"]
