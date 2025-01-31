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

# Check for NVIDIA GPU first
if check_nvidia; then
    echo "NVIDIA GPU detected -> using CUDA-enabled build..."
    docker compose -f docker-compose.yml -f docker-compose.cuda.yml up --build
    exit 0
fi

# Use ARM compose file if on ARM architecture
if [[ "$ARCH" == "aarch64" || "$ARCH" == "armv7l" ]]; then
    echo "Detected ARM architecture -> using ARM-optimized build..."
    docker compose -f docker-compose.yml -f docker-compose.arm.yml up --build
else
    echo "Using standard CPU build..."
    docker compose up --build
fi
