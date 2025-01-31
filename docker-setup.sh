#!/bin/bash

# Detect architecture
ARCH=$(uname -m)

# Function to check for NVIDIA GPU
check_nvidia() {
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi &> /dev/null
        return $?
    fi
    return 1
}

# Check for USE_CUDA environment variable
if [[ "${USE_CUDA}" == "1" ]]; then
    if check_nvidia; then
        echo "CUDA enabled build requested and NVIDIA GPU detected..."
        docker compose -f docker-compose.yml -f docker-compose.cuda.yml up --build
        exit 0
    else
        echo "Warning: CUDA build requested but no NVIDIA GPU detected. Falling back to CPU build..."
    fi
fi

# Use ARM compose file if on ARM architecture
if [[ "$ARCH" == "aarch64" || "$ARCH" == "armv7l" ]]; then
    echo "Detected ARM architecture, using ARM-optimized build..."
    docker compose -f docker-compose.yml -f docker-compose.arm.yml up --build
else
    echo "Using standard build..."
    docker compose up --build
fi
