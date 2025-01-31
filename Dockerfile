FROM python:3.9-slim

# Set environment variables
ENV PYTHONWARNINGS=ignore
ENV TRANSFORMERS_VERBOSITY=error
ENV TORCH_WARN_ONCE=1
ENV DEBIAN_FRONTEND=noninteractive
# Don't write .pyc files
ENV PYTHONDONTWRITEBYTECODE=1
# Don't buffer output
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
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

# Install base PyTorch first to check CUDA availability
RUN pip install --no-cache-dir torch torchvision torchaudio && \
    CUDA_AVAILABLE=$(python -c "import torch; print(1 if torch.cuda.is_available() else 0)") && \
    if [ "$CUDA_AVAILABLE" = "1" ] ; then \
        echo "CUDA is available, installing PyTorch with CUDA support" && \
        pip uninstall -y torch torchvision torchaudio && \
        pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 ; \
    else \
        echo "CUDA is not available, using CPU-only PyTorch" ; \
    fi && \
    python -c "import torch; print('CUDA available:', torch.cuda.is_available()); print('CUDA device count:', torch.cuda.device_count()); print('CUDA version:', torch.version.cuda if torch.cuda.is_available() else 'N/A')" && \
    pip install --no-cache-dir -r requirements.txt

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
