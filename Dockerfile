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

# Install PyTorch and requirements
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
CMD ["flask", "run", "--host=0.0.0.0", "--port=6969", "--reload"]
