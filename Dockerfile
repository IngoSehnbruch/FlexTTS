FROM python:3.9-slim

# Set environment variables to suppress warnings and configure build
ENV PYTHONWARNINGS=ignore
ENV TRANSFORMERS_VERBOSITY=error
ENV TORCH_WARN_ONCE=1
ENV DEBIAN_FRONTEND=noninteractive
ENV MAKEFLAGS="-j4"
ENV CFLAGS="-march=armv8-a"

WORKDIR /app

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

# Install numpy and other dependencies first
RUN pip install --no-cache-dir \
    setuptools==65.5.1 \
    wheel==0.40.0 \
    numpy==1.24.3

# Install PyTorch CPU version for ARM
RUN pip install --no-cache-dir torch==2.1.2 --index-url https://download.pytorch.org/whl/cpu

# Copy requirements first to leverage Docker cache
COPY requirements.txt /app/

# Install TTS without dependencies first (we'll install them manually)
RUN pip install --no-cache-dir \
    flask==3.1.0 \
    python-dotenv==1.0.1 \
    && pip install --no-cache-dir TTS==0.21.1 --no-deps

# Install remaining TTS dependencies manually (avoiding problematic ones)
RUN pip install --no-cache-dir \
    trainer==0.0.31 \
    tensorboardX==2.6.2.2 \
    librosa==0.10.1 \
    unidecode==1.3.7 \
    phonemizer==3.2.1 \
    scipy==1.11.4 \
    && rm -rf /root/.cache/pip

# Create necessary directories
RUN mkdir -p /app/data/speakers /app/static/audio

# Copy application files
COPY flextts.py /app/
COPY templates /app/templates/

# Set TTS_HOME for model storage
ENV TTS_HOME=/app/data

# Verify files exist
RUN ls -la /app/

# Expose the port the app runs on
EXPOSE 6969

# Command to run the app
CMD ["python", "/app/flextts.py"]
