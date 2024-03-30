from pydub import AudioSegment
import os


def merge_mp3_files_from_directory(input_directory, output_file):
    """Merges all MP3 files from a directory into one, with a 1-second gap between each."""
    silence = AudioSegment.silent(duration=1000)  # 1 second of silence
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

    # Path to the directory containing the MP3 files
    input_directory = (
        "/Users/jaredstrober/StoryBoost/StoryBoostTextToSpeach/output_conversation"
    )

    # Specify the output file for the merged audio
    output_file = "/Users/jaredstrober/StoryBoost/StoryBoostTextToSpeach/output_conversation/full_conversation.mp3"

    # Call the function to merge MP3 files from the directory
    merge_mp3_files_from_directory(input_directory, output_file)
