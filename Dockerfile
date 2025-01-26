FROM python:3.9-slim

# Set environment variables to suppress warnings and configure build
ENV PYTHONWARNINGS=ignore
ENV TRANSFORMERS_VERBOSITY=error
ENV TORCH_WARN_ONCE=1
ENV DEBIAN_FRONTEND=noninteractive
ENV MAKEFLAGS="-j4"
ENV CFLAGS="-march=armv8-a"
# Don't write .pyc files
ENV PYTHONDONTWRITEBYTECODE=1
# Don't buffer output
ENV PYTHONUNBUFFERED=1

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
    mecab \
    mecab-ipadic \
    python3-tk \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Rust compiler
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Create app directory
RUN mkdir -p /app
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install PyTorch CPU version for ARM first
RUN pip install --no-cache-dir torch==2.1.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cpu

# Pre-install problematic packages for ARM
RUN pip install --no-cache-dir blis==0.7.11 spacy==3.7.2 spacy-legacy==3.0.12
RUN pip install --no-cache-dir https://github.com/explosion/spacy-models/releases/download/ja_core_news_sm-3.7.0/ja_core_news_sm-3.7.0-py3-none-any.whl

# Install the rest of requirements
RUN pip install --no-cache-dir -r requirements.txt

# Copy all application files
COPY . /app/

# Create necessary directories
RUN mkdir -p /app/data/speakers /app/static/audio

# Set TTS_HOME for model storage
ENV TTS_HOME=/app/data

# Expose the port the app runs on
EXPOSE 6969

# Command to run the app with reload
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0", "--port=6969", "--reload"]
