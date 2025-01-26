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

```bash
docker-compose up -d
```

The API will be available at `http://localhost:6969` / `http://<your-ip>:6969`
(or the port specified in `docker-compose.yml`).

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
DEFAULT_SPEAKER=Donald_Trump
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
        "speaker": "Donald Trump",
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
        "speaker": "Donald Trump",
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
        "Donald Trump",
        "Joe Biden"
    ],
    "de": [
        "Angela Merkel"
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
        "Donald Trump",
        "Joe Biden"
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
    input_template: "{{ text }}"
```

### Configuration Variables

- **platform** (required): Always set to `"generic"`
- **name** (optional): The name for this TTS platform in Home Assistant
- **base_url** (required): The URL of your FlexTTS instance (replace `<ip>` with your server's IP address)
- **input_template** (required): Leave as `"{{ text }}"` to pass the message correctly

### Example Usage

In Home Assistant automations or scripts:

```yaml
service: tts.flextts_speak
data:
  entity_id: media_player.living_room_speaker
  message: "Welcome home!"
```

To use different languages or speakers, you can format your message with the appropriate parameters:

```yaml
service: tts.flextts_speak
data:
  entity_id: media_player.living_room_speaker
  message: |
    {"text": "Welcome home!", "language": "en", "speaker": "Donald Trump"}
```

The TTS will be processed by FlexTTS and played through your specified media player. The audio files are automatically cleaned up after 1 hour.

## Project Structure

```
.
├── data/
│   └── speaker/          # Speaker voice samples (example)
│       ├── en/
│       │   ├── donald_trump.wav
│       │   └── joe_biden.wav
│       └── de/
│           └── angela_merkel.wav
├── static/
│   └── audio/           # Generated audio files (auto-cleaned)
├── templates/
│   └── index.html       # Web interface
├── flextts.py          # Main application
├── requirements.txt    # Python dependencies
├── Dockerfile         # Docker build instructions
└── docker-compose.yml # Docker compose configuration
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

## Development

To run in debug mode, set `DEBUG=true` in your environment variables. This enables detailed logging.


## License

This project uses the Coqui TTS XTTS v2 model, which is subject to the Coqui Public Model License. For more information, visit [Coqui's website](https://coqui.ai/).
