from gtts import gTTS
import json
import os

emergency_codes = {
    "E01": "I need medical help",
    "E02": "Call the police",
    "E03": "I am lost",
    "E04": "I need water",
    "E05": "Danger nearby"
}

output_dir = "assets/emergency"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Save JSON metadata
with open(os.path.join(output_dir, "emergency_codes.json"), "w") as f:
    json.dump(emergency_codes, f, indent=4)

# Generate audio clips
for code, text in emergency_codes.items():
    tts = gTTS(text=text, lang='en')
    tts.save(os.path.join(output_dir, f"{code}.mp3"))
    print(f"Generated {code}.mp3")
