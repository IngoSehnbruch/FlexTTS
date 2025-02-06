# This python file uses the following encoding: utf-8

import warnings
import logging
import os
import sys
from io import StringIO

# Check if environment variables are set
if os.getenv("DEFAULT_LANGUAGE") is None:
    # load .env file
    from dotenv import load_dotenv
    load_dotenv()

DEBUG = (os.getenv("DEBUG", "false").lower()=="true")

if DEBUG:
    print(" > Debug mode enabled")

if not DEBUG:
    # Filter out specific warnings
    warnings.filterwarnings('ignore')  # Ignore all warnings
    warnings.filterwarnings('ignore', message="The attention mask is not set and cannot be inferred from input*")  # Exact message
    os.environ['PYTHONWARNINGS'] = 'ignore'
    os.environ['TRANSFORMERS_VERBOSITY'] = 'critical'  # Set transformers to only show critical errors
    os.environ['FLASK_LOG_LEVEL'] = 'ERROR'  # Suppress Flask startup messages
    
    # Disable all logging except errors
    logging.getLogger('werkzeug').setLevel(logging.ERROR)  # Flask logging
    logging.getLogger('flask').setLevel(logging.ERROR)  # More Flask logging
    logging.getLogger('transformers').setLevel(logging.CRITICAL)  # Transformers logging more strict
    logging.getLogger('TTS').setLevel(logging.ERROR)  # TTS library logging

import base64
import re
import uuid
from datetime import datetime, timedelta

from flask import Flask, request, render_template, jsonify, url_for, send_file

import torch
from TTS.api import TTS

if not DEBUG:
    torch.set_warn_always(False)  # Disable PyTorch warnings

# ##### Basics

def log(*args):
    if args:
        print(" > [" + datetime.now().strftime("%Y-%m-%d %H:%M:%S") + "] " + " ".join(str(arg) for arg in args))

log("Loading FlexTTS")

app_path = os.getenv("APP_PATH", os.getcwd())  # Use APP_PATH if set, otherwise getcwd
speaker_path = os.path.join(app_path, "data", "speakers")
static_audio_path = os.path.join(app_path, "static", "audio")

if not os.path.exists(speaker_path):
    os.makedirs(speaker_path)

if not os.path.exists(static_audio_path):
    os.makedirs(static_audio_path)

# Check if DEFAULT_LANGUAGE and DEFAULT_SPEAKER are set and valid

default = {
    "language": os.getenv("DEFAULT_LANGUAGE"),
    "speaker": os.getenv("DEFAULT_SPEAKER").lower().replace(" ", "_")
}

if not default["language"] or not default["speaker"]:
    raise ValueError("Fatal Error: DEFAULT_LANGUAGE and DEFAULT_SPEAKER environment variables must be set")

if not os.path.exists(os.path.join(speaker_path, default["language"])):
    raise ValueError("Fatal Error: DEFAULT_LANGUAGE has no speaker files")
    
if not os.path.exists(os.path.join(speaker_path, default["language"], default["speaker"] + ".wav")):
    raise ValueError("Fatal Error: DEFAULT_SPEAKER does not exist", os.path.join(speaker_path, default["language"], default["speaker"] + ".wav"))


# Initialize TTS model
os.environ['TTS_HOME'] = os.path.join(app_path, "data") # Save to permanent storage (for Docker)
os.environ['COQUI_TOS_AGREED'] = "1" # Required for uninterrupted TTS Model Download

class TTSManager:
    _instance = None
    _model = None

    @classmethod
    def get_model(cls):
        if cls._model is None:
            log("Loading TTS model...")
            if torch.cuda.is_available():
                # Clear CUDA cache before loading model
                torch.cuda.empty_cache()
                # Set memory usage limits for CUDA
                torch.cuda.set_per_process_memory_fraction(0.8)  # Use up to 80% of available VRAM
            cls._model = TTS(model_name="tts_models/multilingual/multi-dataset/xtts_v2", gpu=torch.cuda.is_available())
        return cls._model

    @classmethod
    def clear_cuda(cls):
        if torch.cuda.is_available():
            torch.cuda.empty_cache()

# Initialize Flask app
app = Flask(__name__, static_url_path='/static')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Configure server name if running in Docker
docker_port = os.getenv('DOCKER_PORT', '6969')  # Default to 6969 if not set

# Initialize TTS model at startup
log("Loading TTS model at startup...")
TTSManager.get_model()

# ##### Helper functions

def get_languages_data():
    """Get all available languages and their speakers"""
    languages = {}
    if os.path.exists(speaker_path):
        for language in os.listdir(speaker_path):
            language_path = os.path.join(speaker_path, language)
            if os.path.isdir(language_path):
                speakers = []
                for file in os.listdir(language_path):
                    if file.endswith('.wav'):
                        speaker_name = file[:-4].replace('_', ' ')  # Remove .wav and format
                        speaker_name = ' '.join(word.capitalize() for word in speaker_name.split())
                        speakers.append(speaker_name)
                if speakers:
                    languages[language] = sorted(speakers)
    return languages

def cleanup_old_files(directory, max_age_hours=1):
    """Clean up files older than max_age_hours"""
    now = datetime.now()
    for filename in os.listdir(directory):
        if filename == '.gitkeep':
            continue
        filepath = os.path.join(directory, filename)
        file_modified = datetime.fromtimestamp(os.path.getmtime(filepath))
        if now - file_modified > timedelta(hours=max_age_hours):
            try:
                os.remove(filepath)
            except Exception as e:
                log(f"Error removing old file {filepath}: {e}")


# ##### Flask routes

@app.route('/speakers', methods=['GET', 'POST'])
def list_all_speakers():
    """List all available languages and their speakers"""
    try:
        if not os.path.exists(speaker_path):
            return jsonify({'error': 'Speakers directory not found'}), 404

        # Get all language directories
        languages = get_languages_data()
        
        return jsonify(languages)
        
    except Exception as e:
        error_message = str(e)
        log("ERROR:", error_message)
        return jsonify({'error': error_message}), 500


@app.route('/speakers/<language>', methods=['GET', 'POST'])
def list_speakers(language):
    """List available speakers for a given language"""
    try:
        speaker_dir = os.path.join(speaker_path, language)
        
        if not os.path.exists(speaker_dir):
            if DEBUG:
                log("ERROR - Language not found: " + language)
            return jsonify({
                'error': f'Language not found: {language}',
                'available_languages': [d for d in os.listdir(speaker_path) 
                                     if os.path.isdir(os.path.join(speaker_path, d))]
            }), 404
            
        # Get all .wav files and format their names
        speakers = []
        for file in os.listdir(speaker_dir):
            if file.endswith('.wav'):
                # Remove .wav and format the name
                speaker_name = file[:-4]  # Remove .wav extension
                speaker_name = speaker_name.replace('_', ' ')  # Replace underscores with spaces
                speaker_name = ' '.join(word.capitalize() for word in speaker_name.split())  # Capitalize each word
                speakers.append(speaker_name)
                
        return jsonify({
            'language': language,
            'speakers': sorted(speakers)  # Sort alphabetically
        })
        
    except Exception as e:
        error_message = str(e)
        log("ERROR:", error_message)
        return jsonify({'error': error_message}), 500


@app.route('/', methods=['GET', 'POST'])
def handle_tts():
    """Handle TTS requests and index page"""
    if request.method == 'GET':
        # Get all speakers for the template
        languages = get_languages_data()
        selected_language = default['language']
        selected_speaker = default['speaker'].replace('_', ' ').title()
        
        if request.headers.get('Accept', '').find('application/json') != -1 or request.is_json:
            return jsonify({
                'info': 'FlexTTS API',
                'methods': {
                    'GET': 'Returns this info',
                    'POST': {
                        'parameters': {
                            'text': 'Text to convert to speech',
                            'language': f'Language code (default: {default["language"]})',
                            'speaker': f'Speaker file name (default: {default["speaker"]})',
                            'response_type': 'Response type: "base64", "file" or "url" (default: "url")'
                        },
                        'returns': {
                            'text': 'Text to convert to speech',
                            'audio_data': 'Base64 encoded WAV audio (when response_type=base64)',
                            'url': 'URL to the generated audio file (when response_type=url)',
                            'format': 'Audio format (wav)'
                            # or the file itself if response_type=file
                        }
                    }
                }
            })
        return render_template('index.html', languages=languages, selected_language=selected_language, selected_speaker=selected_speaker)
        
    try:
        # Clean up old files
        cleanup_old_files(static_audio_path)

        # Get text from request
        text = request.form.get('text', '')
        language = request.form.get('language', default['language'])
        speaker = request.form.get('speaker', default['speaker'])
        response_type = request.form.get('response_type', 'url')
        trackingid = request.form.get('trackingid', "NONE")

        if request.is_json:
            data = request.get_json()
            if not text:
                text = data.get('text', '')
            if not language:
                language = data.get('language', default['language'])
            if speaker == default['speaker']:
                speaker = data.get('speaker', default['speaker'])
            response_type = data.get('response_type', 'url')

        # Convert display speaker name to filename format
        speaker = speaker.lower().replace(' ', '_')

        # Validate response_type
        if response_type not in ['base64', 'url', "file"]:
            return jsonify({'error': 'Invalid response_type. Must be either "base64", "file" or "url"'}), 400

        # speaker_regex test: only letters, underscores and dashes and numbers allowed!
        if not re.match("^[a-zA-Z0-9_\-]+$", speaker):
            log("ERROR - Invalid speaker name: " + speaker)
            return jsonify({'error': 'Invalid speaker name'}), 400

        speaker_wav = os.path.join(speaker_path, language, speaker + ".wav")
        if not os.path.exists(speaker_wav):
            log("ERROR - Speaker not found: " + speaker + " (language: " + language + ") - " + speaker_wav)
            return jsonify({'error': 'Speaker not found: ' + speaker + ' (language: ' + language + ')'}), 400
        
        if not text:
            return jsonify({'error': 'No text provided'}), 400
        
        # Generate unique filename for the audio
        output_filename = f"{uuid.uuid4()}.wav"
        output_path = os.path.join(static_audio_path, output_filename)
        
        # Generate speech using the speaker.wav file as reference
        if not DEBUG:
            # Redirect stdout during TTS synthesis
            old_stdout = sys.stdout
            sys.stdout = StringIO()
            
        try:
            tts_model = TTSManager.get_model()
            tts_model.tts_to_file(
                text=text,
                file_path=output_path,
                speaker_wav=speaker_wav,
                language=language
            )
        finally:
            if not DEBUG:
                # Restore stdout
                sys.stdout = old_stdout
        
        # Prepare response based on response_type
        response_data = {
            'text': text,
            'format': 'wav'
        }

        if response_type == 'base64':
            with open(output_path, 'rb') as audio_file:
                audio_data = base64.b64encode(audio_file.read()).decode('utf-8')
                
            # Clean up the file since we've encoded it
            try:
                os.remove(output_path)
            except Exception as e:
                log(f"Error removing temporary file {output_path}: {e}")
                
            # Clear CUDA cache after generation
            TTSManager.clear_cuda()
            
            response_data['audio_data'] = audio_data
            response_data['encoding'] = 'base64'
        
        else:  # URL response
            # Generate URL for the audio file
            audio_url = url_for('static', filename=f'audio/{output_filename}', _external=True)
            if docker_port:
                # Replace port in URL if running in Docker
                audio_url = re.sub(r':\d+/', f':{docker_port}/', audio_url)
            
            # Clear CUDA cache after generation
            TTSManager.clear_cuda()
            
            response_data['url'] = audio_url

        if trackingid != "NONE":
            response_data['trackingid'] = trackingid

        if DEBUG:
            log("SUCCESS: Audio synthesized [" + response_type + "]")

        # Return the response based on the request type / platform

        # FILE RESPONSE:
        if response_type == 'file':
            return send_file(
                output_path,
                mimetype="audio/wav",
                as_attachment=False)

        # JSON RESPONSE:
        if request.headers.get('Accept', '').find('application/json') != -1 or request.is_json:
            return jsonify(response_data)
        
        # HTML INTERFACE ONLY:
        return render_template('index.html', 
                             audio_data=response_data.get('audio_data'), 
                             input_text=text,
                             languages=get_languages_data(),
                             selected_language=language,
                             selected_speaker=speaker.replace('_', ' ').title())
        
    except Exception as e:
        error_message = str(e)
        log("ERROR:", error_message)
        if request.headers.get('Accept', '').find('application/json') != -1 or request.is_json:
            return jsonify({'error': error_message}), 500
        return f'Error: {error_message}', 500


# ##### Run the app without WSGI 
# for limited usage, e.g. local network only
# Use an WSGI server to expose to the internet (if your server can handle that...)
if __name__ == "__main__":
    print(" > FlexTTS running without WSGI server. Do NOT expose to the internet.")
    if not DEBUG:
        cli = sys.modules['flask.cli']
        cli.show_server_banner = lambda *x: None  # Disable Flask startup banner
    else:
        log("Listening for requests...")
    app.run(host="0.0.0.0", port=6969, debug=DEBUG)