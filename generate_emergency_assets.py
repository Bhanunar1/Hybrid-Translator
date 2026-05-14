from gtts import gTTS
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

emergency_codes = {
    "E01": "I need medical help immediately",
    "E02": "Please call the police now",
    "E03": "I am lost, please help me find my way",
    "E04": "I need water and food",
    "E05": "There is danger nearby, stay away",
    "E06": "I need a doctor urgently",
    "E07": "Please call an ambulance"
}

output_dir = "frontend/assets/emergency"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Save JSON metadata
with open(os.path.join(output_dir, "emergency_codes.json"), "w") as f:
    json.dump(emergency_codes, f, indent=4)

# Generate audio clips
print("Generating 7 emergency audio clips...")
for code, text in emergency_codes.items():
    try:
        tts = gTTS(text=text, lang='en')
        tts.save(os.path.join(output_dir, f"{code}.mp3"))
        print(f"✅ Generated {code}.mp3")
    except Exception as e:
        print(f"❌ Failed to generate {code}.mp3: {e}")

print("\nAll assets ready in frontend/assets/emergency")
