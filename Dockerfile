# Use CUDA-enabled Python base image
FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

# Set environment variables
ENV PYTHONWARNINGS=ignore
ENV TRANSFORMERS_VERBOSITY=error
ENV TORCH_WARN_ONCE=1
ENV DEBIAN_FRONTEND=noninteractive
# Don't write .pyc files
ENV PYTHONDONTWRITEBYTECODE=1
# Don't buffer output
ENV PYTHONUNBUFFERED=1

# Install system dependencies and Python
RUN apt-get update && apt-get install -y \
    python3.9 \
    python3-pip \
    python3.9-dev \
    build-essential \
    libsndfile1 \
    pkg-config \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
RUN mkdir -p /app
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install PyTorch with CUDA support and other requirements
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 && \
    python3 -c "import torch; print('CUDA available:', torch.cuda.is_available()); print('CUDA device count:', torch.cuda.device_count()); print('CUDA version:', torch.version.cuda if torch.cuda.is_available() else 'N/A')" && \
    pip3 install --no-cache-dir -r requirements.txt

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
