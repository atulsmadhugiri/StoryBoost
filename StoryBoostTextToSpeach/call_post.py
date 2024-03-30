import requests
import json

url = 'http://127.0.0.1:5000/generateAudio'

# Load your JSON file
with open('conversation.json', 'r') as file:
    data = json.load(file)

# Send POST request
response = requests.post(url, json={'conversation': data})

# Assuming the server responds with the generated audio file
with open('output.mp3', 'wb') as output_file:
    output_file.write(response.content)

print('Audio file has been saved as output.mp3')
