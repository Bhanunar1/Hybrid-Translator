# Hybrid Translator Pro 3.0

The most advanced, production-grade hybrid translation application built with Flutter & FastAPI. It offers a secure, high-performance solution for both online and offline translation scenarios with an integrated emergency SOS system.

## 🚀 Key Features

### 🔹 Advanced Frontend (Flutter)
- **Hybrid Engine**: Automatically switches between Cloud AI and local ML models based on connectivity.
- **Bi-Mode Input**: Support for crystal-clear Voice-to-Text (STT) and Manual Typing.
- **Interactive UI**: Futuristic, glass-morphism design with real-time mic pulse animations and smooth page transitions.
- **Persistent History**: Full history of all translations with filtering (Cloud/Offline/Voice) and swipe-to-delete functionality.
- **User Profiles & Preferences**: Personalized settings including default source/target languages and detailed usage stats.
- **Copy & Share**: Quick clipboard integration for input and output texts.
- **Full Dark Mode**: Sleek, eye-comfortable dark theme with adaptive UI.

### 🔹 High-Scale Backend (FastAPI)
- **Secure Authentication**: JWT-based auth with salted & hashed passwords and admin-only routes.
- **Comprehensive History API**: Full CRUD support for translation history synced across devices.
- **Real-Time Usage Stats**: Aggregated metrics for total uses, favorite languages, and average latency.
- **Production Performance**: SQLite optimization with WAL (Write-Ahead Logging) and `pool_pre_ping`.
- **Advanced Engine Logic**: Intelligent fallback logic with detailed latency tracking and engine logging.
- **Rate Limiting**: Integrated `slowapi` to protect against brute-force and high-frequency requests.
- **Admin Command Center**: List all users, search by phone/email, and manage account status.

### 🆘 Emergency SOS Module
- **7 Critical Codes**: Predefined quick-trigger distress signals (Medical, Police, Lost, Water/Food, Danger, Doctor, Ambulance).
- **Auto-Broadcasting**: Generates and plays audio distress messages in the target language.
- **Distress Visualization**: High-impact UI alert states with broadcasting indicators.

## 🛠️ Tech Stack
- **Frontend**: Flutter (3.x), Provider, Google Fonts, Animate Do, Shimmer, Google ML Kit Translation.
- **Backend**: FastAPI, SQLAlchemy, deep-translator, slowapi, python-jose, passlib.
- **Database**: SQLite (Optimized for performance).
- **Security**: JWT tokens, Bcrypt hashing.

## 📦 Setup & Installation

### Backend
1. `cd backend`
2. `pip install -r requirements.txt`
3. Optional: Configure `.env` for `HYBRID_SECRET_KEY`
4. `python main.py`

### Frontend
1. `cd frontend`
2. `flutter pub get`
3. Generate assets: `python ../generate_emergency_assets.py` (requires internet for gTTS)
4. `flutter run`

---
*Developed for the Hybrid Translator team - 2026*
