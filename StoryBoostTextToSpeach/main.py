import requests
import json
import logging
import os
from requests.exceptions import RequestException
from pydub import AudioSegment

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
import secrets
# Constants
CHUNK_SIZE = 1024
XI_API_KEY = secrets.api_key # Replace with your actual API key
CONVERSATION_FILE = "conversation.json"
OUTPUT_FOLDER = "output_conversation"


def fetch_voice_ids(api_key):
    """Fetch and display available voice IDs from the ElevenLabs API."""
    url = "https://api.elevenlabs.io/v1/voices"
    headers = {
        "Accept": "application/json",
        "xi-api-key": api_key,
        "Content-Type": "application/json",
    }
    try:
        response = requests.get(url, headers=headers)
        if response.ok:
            data = response.json()
            print("Available voices:")
            for voice in data["voices"]:
                print(f"{voice['name']} - ID: {voice['voice_id']}")
            return True
        else:
            logging.error(f"Failed to fetch voice IDs: {response.text}")
            return False
    except RequestException as e:
        logging.error(f"Request failed: {e}")
        return False


def create_conversation_json():
    """Prompt the user to create a conversation and save it to a JSON file."""
    conversation = []
    num_parts = int(input("Enter the number of parts in the conversation: "))
    for i in range(num_parts):
        print(f"\nPart {i+1}:")
        voice_id = input("Enter voice ID: ")
        text = input("Enter text: ")
        conversation.append({"voice_id": voice_id, "text": text})
    with open(CONVERSATION_FILE, "w") as file:
        json.dump(conversation, file, indent=4)
    logging.info("Conversation saved to JSON file.")


def convert_conversation_to_speech(conversation_file, api_key, output_folder):
    os.makedirs(output_folder, exist_ok=True)
    try:
        with open(conversation_file, "r") as file:
            conversation = json.load(file)
    except FileNotFoundError:
        logging.error("The conversation file does not exist.")
        return
    except json.JSONDecodeError:
        logging.error(
            "Error decoding the JSON file. Please ensure it's properly formatted."
        )
        return

    for i, part in enumerate(conversation, start=1):
        if not convert_text_to_speech(
            part["text"],
            part["voice_id"],
            api_key,
            os.path.join(output_folder, f"part_{i}.mp3"),
        ):
            break
        logging.info(f"Part {i} saved successfully.")


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
    """Merges all MP3 files from a directory into one, with a 1-second gap between each."""
    silence = AudioSegment.silent(duration=250)  # .25 seconds of silence
    combined = AudioSegment.empty()  # Start with an empty audio segment

    # Get a sorted list of all MP3 files in the directory
    file_paths = sorted(
        [
            os.path.join(input_directory, f)
            for f in os.listdir(input_directory)
            if os.path.isfile(os.path.join(input_directory, f)) and f.endswith(".mp3")
        ],
        key=str.lower,
    )  # Sorting to ensure order, case-insensitive

    for file_path in file_paths:
        audio = AudioSegment.from_mp3(file_path)
        combined += audio + silence  # Append audio and a silence segment

    # Remove the silence at the end of the last audio clip
    combined = combined[:-1000]

    # Export the combined audio to a file
    combined.export(output_file, format="mp3")
    print(f"Merged file created at: {output_file}")


if __name__ == "__main__":
    try:
        assert XI_API_KEY != "<xi-api-key>", "API key is not set."
        if fetch_voice_ids(XI_API_KEY):
            action = (
                input("\nDo you want to create a new conversation? (yes/no): ")
                .strip()
                .lower()
            )
            if action == "yes":
                create_conversation_json()
            convert_conversation_to_speech(CONVERSATION_FILE, XI_API_KEY, OUTPUT_FOLDER)
    except AssertionError as e:
        logging.error(e)
    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}")

    # Path to the directory containing the MP3 files
    input_directory = OUTPUT_FOLDER

    # Specify the output file for the merged audio
    output_file = f"{OUTPUT_FOLDER}/full_conversation.mp3"

    # Call the function to merge MP3 files from the directory
    merge_mp3_files_from_directory(input_directory, output_file)
