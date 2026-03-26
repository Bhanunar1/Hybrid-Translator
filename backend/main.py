from datetime import timedelta
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel
import models, database, auth
from database import engine, get_db
from fastapi.middleware.cors import CORSMiddleware
from deep_translator import GoogleTranslator

# Initialize DB
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Hybrid Translator Secure API v2.0")

# CORS for Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Schemas ---
class Token(BaseModel):
    access_token: str
    token_type: str

class UserCreate(BaseModel):
    email: str
    password: str
    full_name: str
    phone: str = None

class UserOut(BaseModel):
    id: int
    email: str
    full_name: str
    is_admin: bool

class TranslationRequest(BaseModel):
    text: str
    source_lang: str
    target_lang: str

# --- Auth Routes ---
@app.post("/register", response_model=UserOut)
def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_pwd = auth.get_password_hash(user.password)
    new_user = models.User(
        email=user.email,
        hashed_password=hashed_pwd,
        full_name=user.full_name,
        phone=user.phone
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/token", response_model=Token)
async def login_for_access_token(db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/users/me", response_model=UserOut)
async def read_users_me(current_user: models.User = Depends(auth.get_current_user)):
    return current_user

# Admin-only route to search user by phone/email (for "Forgotten Password" support)
@app.get("/admin/users/{contact}", response_model=UserOut)
async def admin_get_user(contact: str, current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(get_db)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin privileges required")
    user = db.query(models.User).filter((models.User.email == contact) | (models.User.phone == contact)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# --- Core Translation ---
@app.get("/")
async def root():
    return {"status": "online", "message": "Ultra-Secure Hybrid Translator Backend Operational"}

@app.post("/translate")
async def translate(request: TranslationRequest, current_user: models.User = Depends(auth.get_current_user)):
    try:
        # Map some common names just in case deep-translator doesn't like the full name
        lang_map = {
            "English": "en",
            "Hindi": "hi",
            "Telugu": "te",
            "Kannada": "kn",
            "Tamil": "ta",
            "Marathi": "mr",
            "Japanese": "ja",
            "Spanish": "es",
            "French": "fr",
            "German": "de",
            "Arabic": "ar",
            "Chinese": "zh-CN",
            "Korean": "ko",
            "Portuguese": "pt",
            "Russian": "ru",
            "Malayalam": "ml"
        }
        
        target = lang_map.get(request.target_lang, request.target_lang.lower())
        
        translated = GoogleTranslator(source='auto', target=target).translate(request.text)
        
        return {
            "original": request.text,
            "translated": translated,
            "engine": "Premium Cloud AI (Powered by DeepTranslator)",
            "served_by": current_user.full_name
        }
    except Exception as e:
        return {
            "original": request.text,
            "translated": f"[Fallback] {request.text}",
            "error": str(e)
        }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
