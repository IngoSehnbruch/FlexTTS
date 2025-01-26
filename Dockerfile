FROM python:3.9-slim

# Set environment variables to suppress warnings
ENV PYTHONWARNINGS=ignore
ENV TRANSFORMERS_VERBOSITY=error
ENV TORCH_WARN_ONCE=1

WORKDIR /app

# Install system dependencies required for TTS
RUN apt-get update && apt-get install -y \
    build-essential \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Create directories for static files
RUN mkdir -p static/audio

# Expose port 5000
EXPOSE 5000

# Command to run the application
CMD ["python", "FlexTTS.py"]
