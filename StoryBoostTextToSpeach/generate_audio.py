from flask import Flask, request, send_file
import requests
import json
import logging
import os
from requests.exceptions import RequestException
from pydub import AudioSegment
import tempfile
import shutil

import codes

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Constants
CHUNK_SIZE = 1024
XI_API_KEY = codes.api_key  # Replace with your actual API key

def convert_text_to_speech(text, voice_id, api_key, output_path):
    tts_url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}/stream"
    headers = {"Accept": "application/json", "xi-api-key": api_key}
    data = {
        "text": text,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.8,
            "style": 0.0,
            "use_speaker_boost": True,
        },
    }
    try:
        response = requests.post(tts_url, headers=headers, json=data, stream=True)
        if response.ok:
            with open(output_path, "wb") as f:
                for chunk in response.iter_content(chunk_size=CHUNK_SIZE):
                    f.write(chunk)
            return True
        else:
            logging.error(f"Failed to convert text to speech: {response.text}")
            return False
    except RequestException as e:
        logging.error(f"Request failed: {e}")
        return False

def merge_mp3_files_from_directory(input_directory, output_file):
    silence = AudioSegment.silent(duration=250)
    combined = AudioSegment.empty()
    file_paths = sorted(
        [
            os.path.join(input_directory, f)
            for f in os.listdir(input_directory)
            if os.path.isfile(os.path.join(input_directory, f)) and f.endswith(".mp3")
        ],
        key=str.lower,
    )

    for file_path in file_paths:
        audio = AudioSegment.from_mp3(file_path)
        combined += audio + silence

    combined = combined[:-250]
    combined.export(output_file, format="mp3")

@app.route('/generateAudio', methods=['POST'])
def generate_audio():
    if not request.json or 'conversation' not in request.json:
        return "Invalid request", 400

    conversation = request.json['conversation']
    with tempfile.TemporaryDirectory() as tempdir:
        output_files = []
        for i, part in enumerate(conversation, start=1):
            output_path = os.path.join(tempdir, f"part_{i}.mp3")
            if not convert_text_to_speech(
                part["text"],
                part["voice_id"],
                XI_API_KEY,
                output_path,
            ):
                return "Failed to convert text to speech for one of the parts.", 500
            output_files.append(output_path)

        final_output = os.path.join(tempdir, "final_output.mp3")
        merge_mp3_files_from_directory(tempdir, final_output)

        return send_file(final_output, as_attachment=True)

if __name__ == '__main__':
    app.run(debug=True)
