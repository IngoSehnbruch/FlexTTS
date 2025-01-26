FROM python:3.9-slim

# Set environment variables to suppress warnings and configure build
ENV PYTHONWARNINGS=ignore
ENV TRANSFORMERS_VERBOSITY=error
ENV TORCH_WARN_ONCE=1
ENV DEBIAN_FRONTEND=noninteractive
ENV MAKEFLAGS="-j4"
ENV CFLAGS="-march=armv8-a"

# Install system dependencies required for TTS and build tools
RUN apt-get update && apt-get install -y \
    build-essential \
    libsndfile1 \
    pkg-config \
    git \
    cmake \
    gfortran \
    libatlas-base-dev \
    libopenblas-dev \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
RUN mkdir -p /app
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install PyTorch CPU version for ARM
RUN pip install --no-cache-dir torch==2.1.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cpu

# Install other requirements including TTS with its dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy all application files
COPY . /app/

# Create necessary directories
RUN mkdir -p /app/data/speakers /app/static/audio

# Set TTS_HOME for model storage
ENV TTS_HOME=/app/data

# Expose the port the app runs on
EXPOSE 6969

# Command to run the app
CMD ["python", "flextts.py"]
