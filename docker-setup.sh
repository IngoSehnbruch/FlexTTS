#!/bin/bash

# Detect architecture
ARCH=$(uname -m)

# Use ARM compose file if on ARM architecture
if [[ "$ARCH" == "aarch64" || "$ARCH" == "armv7l" ]]; then
    echo "Detected ARM architecture, using ARM-optimized build..."
    docker compose -f docker-compose.yml -f docker-compose.arm.yml up --build
else
    echo "Using standard build..."
    docker compose up --build
fi
