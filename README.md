# FlexTTS API

A flexible Text-to-Speech API service powered by [Coqui TTS](https://github.com/coqui-ai/TTS) using the XTTS v2 model. Supports multiple languages and speakers with a clean REST API and a web interface for testing and demos.

## Features

- 🚀 CUDA GPU support (optional)
- 🌐 Multi-language support with high-quality voices
- 👥 Multiple speaker voices per language
- 🔄 REST API with JSON responses
- 🏠 Ready for Home Assistant integration
- 🎵 Audio delivery via URL or base64
- 🐳 Docker support for easy deployment
- 🔒 Production-ready with error handling
- 🧹 Automatic cleanup of old audio files
- 🎯 Simple web interface for testing and demos
- 🎛️ Platform-optimized builds (ARM/x86)
- 🤖 OpenAI API-compatible interface

### Ready for Home Assistant

- Add the service to your Home Assistant configuration
- Use the `tts.flextts_speak` service to convert any text to speech
(see [Home Assistant integration](#home-assistant-integration))

## Requirements

- Python 3.9
- Docker (optional, but recommended)
- 16 GB of disk space
- 8 GB of RAM or for CUDA support (optional but recommended for better performance):
  - NVIDIA GPU with CUDA capability 
  - NVIDIA drivers installed
  - NVIDIA Container Toolkit (for Docker)

### CUDA Setup (Optional)

For Docker Container with GPU acceleration:

1. Install NVIDIA Container Toolkit (Ubuntu/Debian):
```bash
# Add NVIDIA package repositories
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install NVIDIA Container Toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

2. Verify CUDA setup:
```bash
sudo docker run --rm --runtime=nvidia --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

## Quick Start

### Using Docker (Recommended)

NOTE: The docker setup is messed up... it works fine with rasp pi, but for x86/x64 it's a bit tricky to get working... good luck :)

1. Clone the repository
2. Set up your speaker voice samples in `data/speaker/{language}/{speaker}.wav`
3. Run with Setup-Script for Docker Compose:

The setup script will automatically detect your hardware and use the appropriate configuration:
- If an NVIDIA GPU is detected, it will use CUDA acceleration
- If running on ARM architecture, it will use ARM-optimized builds
- Otherwise, it will use the standard CPU build

```bash
chmod +x docker-setup.sh  # Make script executable (Unix/Linux only)
./docker-setup.sh        # Unix/Linux
# or
sh docker-setup.sh      # Windows
```

#### Manual Platform Selection

For ARM devices (working on a Raspberry Pi 5 with 8 GB RAM):
```bash
docker compose -f docker-compose.yml -f docker-compose.arm.yml up -d
```

For standard x86/x64 systems:
```bash
docker compose up -d
```

For CUDA-enabled systems:
```bash
docker compose -f docker-compose.yml -f docker-compose.cuda.yml up -d
```

The API will be available at `http://localhost:6969` / `http://<your-ip>:6969`
(or the port specified in `docker-compose.yml`).

### Platform-Specific Notes

#### CUDA-enabled Systems
- Automatically uses NVIDIA GPU for faster inference
- Requires NVIDIA Container Toolkit
- Optimized PyTorch CUDA build
- Significantly faster processing times

#### Raspberry Pi / ARM Devices
- Uses optimized ARM-specific builds
- Includes additional dependencies for better ARM compatibility
- Configured for optimal performance on limited resources
- Special PyTorch CPU build for ARM

#### Standard x86/x64 Systems
- Uses standard Python packages
- Simpler dependency structure
- Compatible with CUDA if available
- Optimized for desktop/server performance

### Manual Setup

1. Clone the repository
2. Create a virtual environment and install dependencies:

Required Python Version: 3.9 !

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

3. Set up your environment variables in `.env`:

```env
DEFAULT_LANGUAGE=en
DEFAULT_SPEAKER=donald_trump
```

4. Run the Flask application:

```bash
python flextts.py
```

## Speaker Setup

1. Create language directories under `data/speaker/`, e.g., `data/speaker/en/` for English
2. Add WAV files for each speaker, named as `speaker_name.wav`, e.g., `donald_trump.wav`
3. Files should be high-quality voice samples in the target language
4. Speaker names in the filename should use underscores _ instead of spaces

Example structure:
```
data/speaker/
├── en/
│   ├── donald_trump.wav
│   └── joe_biden.wav
└── de/
    └── angela_merkel.wav
```

## Development Mode

The application supports hot-reloading in development mode. When running with Docker, code changes will be automatically detected and the server will restart. This is enabled by:

- Volume mounting of the app directory
- Flask debug mode
- Auto-reload capability

This makes it easy to:
- Make code changes without rebuilding
- Test changes immediately
- Debug issues in real-time

Note: Dependency changes still require a rebuild with `docker compose up --build`

To run in debug mode, set `DEBUG=true` in your environment variables. This enables detailed logging.

## API Documentation

### Native API

#### GET /

Returns the web interface - or API information if JSON is requested.

```bash
curl -H "Accept: application/json" http://localhost:6969/
```

### POST /

Converts text to speech using the specified speaker and language.

#### Parameters

- `text` (required) - Text to convert to speech
- `language` (optional) - Language code (default: from environment)
- `speaker` (optional) - Speaker name (default: from environment)
- `response_type` (optional) - Response format, either "url" (default) or "base64"

#### Example with URL response

```bash
curl -X POST http://localhost:6969/ \
    -H "Content-Type: application/json" \
    -d '{
        "text": "I will make text to speech great again!",
        "language": "en",
        "speaker": "donald_trump",
        "response_type": "url"
    }'
```

Response:
```json
{
    "text": "I will make text to speech great again!",
    "url": "http://localhost:6969/static/audio/<unique-id>.wav",
    "format": "wav"
}
```

#### Example with base64 response

```bash
curl -X POST http://localhost:6969/ \
    -H "Content-Type: application/json" \
    -d '{
        "text": "I will make text to speech great again!",
        "language": "en",
        "speaker": "donald_trump",
        "response_type": "base64"
    }'
```

Response:
```json
{
    "text": "I will make text to speech great again!",
    "audio_data": "base64_encoded_audio_data",
    "format": "wav",
    "encoding": "base64"
}
```

### GET /speakers

List all available languages and their speakers.

```bash
curl http://localhost:6969/speakers
```

Response:
```json
{
    "en": [
        "donald_trump",
        "joe_biden"
    ],
    "de": [
        "angela_merkel"
    ]
}
```

### GET /speakers/{language}

List available speakers for a specific language.

```bash
curl http://localhost:6969/speakers/en
```

Response:
```json
{
    "language": "en",
    "speakers": [
        "donald_trump",
        "joe_biden"
    ]
}
```

## Home Assistant Integration

FlexTTS can be integrated with Home Assistant using the command_line TTS platform. Add the following to your `configuration.yaml`:

```yaml
tts:
  - platform: command_line
    name: FlexTTS
    command: 'curl -X POST -H "Content-Type: application/json" -d "{\"text\":\"{{ message }}\"}" http://<ip>:6969/'
```

### Configuration Options

- **platform**: Must be set to `command_line`
- **name**: The name to use for this TTS service (can be anything)
- **command**: The curl command that sends the text to FlexTTS
  - Replace `<ip>` with your FlexTTS server address (e.g., `192.168.1.100`)

Note: FlexTTS automatically cleans up its own generated files after 1 hour. Home Assistant manages its cache separately.

### Using in Automations

Use the service in your automations like this:

```yaml
service: tts.flextts_speak
target:
  entity_id: media_player.living_room_speaker
data:
  message: "I will make text to speech great again!"
```

For advanced usage with language/speaker selection:

```yaml
service: tts.flextts_speak
target:
  entity_id: media_player.living_room_speaker
data:
  message: "I will make text to speech great again!"
  language: "en"
  speaker: "donald_trump"
```

## Project Structure

```
.
├── data/
│   └── speaker/         # Speaker voice samples (example)
│       ├── en/
│       │   ├── donald_trump.wav
│       │   └── joe_biden.wav
│       └── de/
├── static/
│   └── audio/          # Generated audio files (auto-cleaned)
├── templates/
│   └── index.html      # Web interface
├── docker-setup.sh     # Platform detection and setup script
├── Dockerfile          # Standard x86/x64 build configuration
├── Dockerfile.arm      # Optimized ARM build configuration
├── Dockerfile.cuda     # CUDA-enabled build configuration
├── docker-compose.yml  # Base Docker configuration
├── docker-compose.arm.yml  # ARM-specific configuration
├── docker-compose.cuda.yml # CUDA-specific configuration
├── flextts.py         # Main application
├── requirements.txt    # Python dependencies
└── README.md          # This Documentation
```

### Key Components

- **Docker Configuration**
  - `Dockerfile`: Standard build for x86/x64 systems
  - `Dockerfile.arm`: Optimized build for ARM devices (Raspberry Pi)
  - `Dockerfile.cuda`: CUDA-enabled build for GPU acceleration
  - `docker-compose.yml`: Base configuration for all platforms
  - `docker-compose.arm.yml`: Additional settings for ARM
  - `docker-compose.cuda.yml`: Additional settings for CUDA
  - `docker-setup.sh`: Automatic platform detection and setup

- **Application Core**
  - `flextts.py`: Main Flask application with TTS logic
  - `requirements.txt`: Python package dependencies
  - `templates/index.html`: Web interface template

- **Data Directories**
  - `data/speaker/`: Voice samples for TTS cloning
  - `static/audio/`: Generated audio files (cleaned hourly)
  - `data/`: TTS model storage (downloaded on first run)

### OpenAI-Compatible API

FlexTTS now includes an OpenAI-compatible API interface that works with applications expecting the OpenAI TTS API format. This makes it compatible with tools like Open WebUI and other applications that use OpenAI's API.

#### POST /v1/audio/speech

Converts text to speech using the OpenAI-compatible interface.

```bash
curl -X POST http://localhost:6969/v1/audio/speech \
    -H "Content-Type: application/json" \
    -d '{
        "model": "tts-1",
        "input": "I will make text to speech great again!",
        "voice": "alloy",
        "response_format": "wav"
    }' \
    --output speech.wav
```

Parameters:
- `model`: "tts-1" or "tts-1-hd" (both map to the same XTTS v2 model)
- `input`: Text to convert to speech
- `voice`: One of "alloy", "echo", "fable", "onyx", "nova", "shimmer"
- `response_format`: Currently only "wav" is supported

#### GET /v1/models

Lists available TTS models in OpenAI-compatible format.

```bash
curl http://localhost:6969/v1/models
```

Response:
```json
{
  "data": [
    {
      "id": "tts-1",
      "object": "model",
      "owned_by": "flextts"
    },
    {
      "id": "tts-1-hd",
      "object": "model",
      "owned_by": "flextts"
    }
  ],
  "object": "list"
}
```

#### GET /v1/models/{model_id}

Get details for a specific model.

```bash
curl http://localhost:6969/v1/models/tts-1
```

Response:
```json
{
  "id": "tts-1",
  "object": "model",
  "owned_by": "flextts",
  "permissions": []
}
```

#### GET /v1/voices

Lists available voices in a format compatible with Open WebUI.

```bash
curl http://localhost:6969/v1/voices
```

Response:
```json
{
  "voices": [
    {
      "voice_id": "alloy",
      "name": "Alloy"
    },
    {
      "voice_id": "en_donald_trump",
      "name": "En - Donald Trump"
    }
  ]
}
```

## Important Notes

- Audio files returned via URL are automatically deleted after 1 hour
- Speaker names are case-insensitive and spaces can be replaced with underscores
- Base64 responses can be directly embedded in web pages or saved as WAV files
- All API responses include appropriate HTTP status codes and error messages
- The web interface automatically updates speaker options based on selected language
- Generated audio files are stored in `static/audio/` with unique filenames
- Default port is 6969 (both in Docker and standalone mode)
- CUDA GPU acceleration is used automatically if available (optional, but recommended)
- On first start, the model is downloaded and saved to persistent storage (~1.9GB) before the app is ready to use
- On container-startup, the xtts model is loaded into memory before the app is ready to use
- On installing, the first build on a Pi5 will take up to 10-15 minutes (with a good internet connection)
- The OpenAI-compatible API maps standard OpenAI voices to your speakers as configured in the OPENAI_VOICE_MAPPING dictionary

## License

This project uses the Coqui TTS XTTS v2 model, which is subject to the Coqui Public Model License. For more information, visit [Coqui's website](https://coqui.ai/).
