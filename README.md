# FlexTTS API

A flexible Text-to-Speech API service powered by [Coqui TTS](https://github.com/coqui-ai/TTS) using the XTTS v2 model. Supports multiple languages and speakers with a clean REST API and web interface.

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

### Ready for Home Assistant

- Add the service to your Home Assistant configuration
- Use the `tts.flextts_speak` service to convert any text to speech
(see [Home Assistant integration](#home-assistant-integration))

## Requirements

- Python 3.9
- Docker (optional, but recommended)
- 8 GB of RAM and 16 GB of disk space
- CUDA GPU recommended for better performance, but not required

## Quick Start

### Using Docker (Recommended)

1. Clone the repository
2. Set up your speaker voice samples in `data/speaker/{language}/{speaker}.wav`
3. Run with Docker Compose:

#### Automatic Platform Detection (Recommended)
Use the setup script which automatically detects your platform and uses the appropriate configuration:

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

The API will be available at `http://localhost:6969` / `http://<your-ip>:6969`
(or the port specified in `docker-compose.yml`).

### Platform-Specific Notes

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

## API Documentation

### GET /

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

FlexTTS can be easily integrated with Home Assistant using the generic TTS platform. Add the following to your `configuration.yaml`:

```yaml
tts:
  - platform: generic
    name: FlexTTS
    base_url: http://<ip>:6969
    cache: true
    cache_dir: /tmp/tts
    service_name: flextts
    timeout: 120  # Increased timeout (in seconds)
```

### Configuration Options

- **base_url**: Your FlexTTS server address (e.g., `http://192.168.1.100:6969`)
- **cache**: Enable caching of generated audio files (recommended)
- **cache_dir**: Where Home Assistant stores the cached audio files
- **service_name**: The service name to use in automations
- **timeout**: Time to wait for TTS generation (default: 30s)
  - The timeout is depending on your usage and the hardware used.
  - For Raspberry Pi: For short text use 120 (seconds), for longer texts 300 (seconds)
  - For CUDA systems: 60s should be sufficient, if not sending a lot of text.
  - While there's no documented maximum timeout, keeping it under 300s (5 min) is recommended (?)
  - Consider splitting very long texts into smaller chunks if you hit timeouts

Note: FlexTTS automatically cleans up its own generated files after 1 hour. Home Assistant manages its cache separately.

In Home Assistant automations or scripts:

```yaml
service: tts.flextts_speak
data:
  entity_id: media_player.living_room_speaker
  message: "I will make text to speech great again!"
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
├── docker-compose.yml  # Base Docker configuration
├── docker-compose.arm.yml  # ARM-specific configuration
├── flextts.py          # Main application
├── requirements.txt    # Python dependencies
└── README.md           # This Documentation

### Key Components

- **Docker Configuration**
  - `Dockerfile`: Standard build for x86/x64 systems
  - `Dockerfile.arm`: Optimized build for ARM devices (Raspberry Pi)
  - `docker-compose.yml`: Base configuration for all platforms
  - `docker-compose.arm.yml`: Additional settings for ARM
  - `docker-setup.sh`: Automatic platform detection and setup

- **Application Core**
  - `flextts.py`: Main Flask application with TTS logic
  - `requirements.txt`: Python package dependencies
  - `templates/index.html`: Web interface template

- **Data Directories**
  - `data/speaker/`: Voice samples for TTS cloning
  - `static/audio/`: Generated audio files (cleaned hourly)
  - `data/`: TTS model storage (downloaded on first run)

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

## Development

To run in debug mode, set `DEBUG=true` in your environment variables. This enables detailed logging.

## License

This project uses the Coqui TTS XTTS v2 model, which is subject to the Coqui Public Model License. For more information, visit [Coqui's website](https://coqui.ai/).
