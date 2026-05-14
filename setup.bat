@echo off
echo 🚀 Setting up Hybrid Translator Pro...

echo 📦 Installing Backend Dependencies...
cd backend
pip install -r requirements.txt
echo 👤 Creating Admin User...
python create_admin.py
cd ..

echo 📱 Setting up Frontend...
cd frontend
flutter pub get
echo 🔊 Generating Emergency Audio Assets...
python ../generate_emergency_assets.py
cd ..

echo ✅ Setup Complete! Use run_app.bat to start.
pause
