FROM python:3.9-slim

# Set environment variables to suppress warnings
ENV PYTHONWARNINGS=ignore
ENV TRANSFORMERS_VERBOSITY=error
ENV TORCH_WARN_ONCE=1
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# Install system dependencies required for TTS and build tools
RUN apt-get update && apt-get install -y \
    build-essential \
    libsndfile1 \
    pkg-config \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install numpy first to avoid dependency issues
RUN pip install --no-cache-dir numpy==1.24.3

# Install torch CPU version to avoid CUDA issues
RUN pip install --no-cache-dir torch==2.1.2 --index-url https://download.pytorch.org/whl/cpu

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install requirements with specific versions for ARM64 compatibility
RUN pip install --no-cache-dir \
    flask==3.1.0 \
    python-dotenv==1.0.1 \
    TTS==0.21.1 \
    && rm -rf /root/.cache/pip

# Copy the rest of the application
COPY . .

# Create necessary directories
RUN mkdir -p /app/data/speakers /app/static/audio

# Expose the port the app runs on
EXPOSE 6969

# Command to run the app
CMD ["python", "flextts.py"]
