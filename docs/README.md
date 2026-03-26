# Hybrid Speech-to-Speech Translator PRO 🚀

A high-performance, cross-platform translator with advanced security and emergency features.

## 🌟 Pro Features
- **Secure Authentication**: JWT-based login/signup with SQLite database storage.
- **Admin Dashboard Ready**: Developer/Admin can manage users and assist with account recovery.
- **Online/Offline Hybrid**: Smart switching between Cloud AI and Google ML Kit.
- **Multilingual SOS**: Emergency phrases are translated instantly to the target language and spoken out loud.
- **Micro-Animations**: Uses `animate_do` for a premium, responsive feel.

## 🛠️ Tech Stack
- **Frontend**: Flutter (Material 3, Provider, Google Fonts, Animate_do)
- **Backend**: FastAPI (Python, SQLAlchemy, JWT, Bcrypt)
- **AI/ML**: 
  - **Online**: Premium Cloud API (OpenAI/Azure/Google)
  - **Offline**: Google ML Kit (On-device Translation)
  - **TTS**: Multilingual Text-to-Speech

## 🚀 Getting Started

### 1. Backend Setup
```bash
cd backend
pip install fastapi uvicorn sqlalchemy passlib[bcrypt] python-jose[cryptography] "bcrypt<4.0.0"
python create_admin.py # Creates default admin: admin@translator.com / admin123
python main.py
```

### 2. Frontend Setup
```bash
cd frontend
flutter pub get
flutter run -d chrome # or windows/android
```

## 🚨 Emergency Code Mode
Accessible via the toggle in the main screen. Phrases like "I need medical help" are translated to your target language (e.g., Hindi, Telugu, Japanese) automatically.
