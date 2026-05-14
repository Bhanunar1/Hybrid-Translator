import time
import os
from datetime import timedelta, datetime, timezone
from typing import List, Optional

from fastapi import FastAPI, Depends, HTTPException, status, Query
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi import UploadFile, File
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from deep_translator import GoogleTranslator
import models
import database
import auth
from database import engine, get_db
from gtts import gTTS
import io
from fastapi.responses import StreamingResponse

# ── App Init ───────────────────────────────────────────────────────────────────
models.Base.metadata.create_all(bind=engine)

limiter = Limiter(key_func=get_remote_address)

app = FastAPI(
    title="Hylator API",
    description="Production-grade multi-engine translation backend with live profile, voice, and map support.",
    version="3.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure uploads directory exists
os.makedirs("uploads/profiles", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# ── Language map ───────────────────────────────────────────────────────────────
LANG_MAP = {
    "English": "en", "Hindi": "hi", "Telugu": "te", "Kannada": "kn",
    "Tamil": "ta", "Marathi": "mr", "Japanese": "ja", "Spanish": "es",
    "French": "fr", "German": "de", "Arabic": "ar", "Chinese": "zh-CN",
    "Korean": "ko", "Portuguese": "pt", "Russian": "ru", "Malayalam": "ml",
    "Gujarati": "gu", "Bengali": "bn", "Italian": "it", "Dutch": "nl",
    "Turkish": "tr", "Thai": "th", "Vietnamese": "vi",
}

# ── Schemas ────────────────────────────────────────────────────────────────────
class Token(BaseModel):
    access_token: str
    token_type: str

class UserCreate(BaseModel):
    email: str
    password: str
    full_name: str
    phone: Optional[str] = None

class UserOut(BaseModel):
    id: int
    email: str
    full_name: str
    is_admin: bool
    created_at: Optional[datetime] = None
    preferred_source_lang: Optional[str] = None
    preferred_target_lang: Optional[str] = None
    bio: Optional[str] = None
    dob: Optional[str] = None
    nationality: Optional[str] = None
    home_country: Optional[str] = None
    current_destination: Optional[str] = None
    travel_history: Optional[str] = None
    profile_image_url: Optional[str] = None

    class Config:
        from_attributes = True

class UserPrefsUpdate(BaseModel):
    preferred_source_lang: Optional[str] = None
    preferred_target_lang: Optional[str] = None
    full_name: Optional[str] = None
    phone: Optional[str] = None
    bio: Optional[str] = None
    dob: Optional[str] = None
    nationality: Optional[str] = None
    home_country: Optional[str] = None
    current_destination: Optional[str] = None
    travel_history: Optional[str] = None
    profile_image_url: Optional[str] = None

class TranslationRequest(BaseModel):
    text: str
    source_lang: str
    target_lang: str
    was_voice_input: bool = False

class TranslationResponse(BaseModel):
    original: str
    translated: str
    source_lang: str
    target_lang: str
    engine: str
    latency_ms: float
    timestamp: str

class HistoryItem(BaseModel):
    id: int
    source_text: str
    translated_text: str
    source_lang: str
    target_lang: str
    engine: str
    latency_ms: Optional[float]
    was_voice_input: bool
    created_at: Optional[datetime]

    class Config:
        from_attributes = True

class UserStats(BaseModel):
    total_translations: int
    cloud_translations: int
    offline_translations: int
    favorite_target_lang: Optional[str]
    avg_latency_ms: Optional[float]
    member_since: Optional[datetime]

class PasswordVerify(BaseModel):
    password: str

# ── Root ───────────────────────────────────────────────────────────────────────
@app.get("/", tags=["System"])
async def root():
    return {
        "status": "online",
        "version": "3.0.0",
        "message": "Hylator Backend — Production Ready 🌿",
        "supported_languages": len(LANG_MAP),
    }

@app.get("/health", tags=["System"])
async def health():
    return {"status": "healthy", "timestamp": datetime.now(timezone.utc).isoformat()}

@app.get("/languages", tags=["System"])
async def get_languages():
    return {"languages": list(LANG_MAP.keys()), "count": len(LANG_MAP)}

# ── Auth Routes ────────────────────────────────────────────────────────────────
@app.post("/register", response_model=UserOut, tags=["Auth"])
def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    if len(user.password) < 6:
        raise HTTPException(status_code=422, detail="Password must be at least 6 characters")

    hashed_pwd = auth.get_password_hash(user.password)
    new_user = models.User(
        email=user.email,
        hashed_password=hashed_pwd,
        full_name=user.full_name,
        phone=user.phone,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/upload-profile-image", tags=["Auth"])
async def upload_profile_image(
    file: UploadFile = File(...),
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """Uploads and saves a profile image for the current user."""
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image files are allowed")
    
    file_ext = file.filename.split(".")[-1]
    file_name = f"user_{current_user.id}_{int(time.time())}.{file_ext}"
    file_path = f"uploads/profiles/{file_name}"
    
    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())
    
    # Store relative path or full URL
    image_url = f"/uploads/profiles/{file_name}"
    current_user.profile_image_url = image_url
    db.commit()
    
    return {"image_url": image_url}

@app.post("/token", response_model=Token, tags=["Auth"])
async def login_for_access_token(
    db: Session = Depends(get_db),
    form_data: OAuth2PasswordRequestForm = Depends(),
):
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is deactivated")

    # Update last login
    user.last_login = datetime.now(timezone.utc)
    db.commit()

    expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(data={"sub": user.email}, expires_delta=expires)
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/users/me", response_model=UserOut, tags=["User"])
async def read_users_me(current_user: models.User = Depends(auth.get_current_user)):
    return current_user

def _apply_prefs(current_user: models.User, prefs: UserPrefsUpdate):
    """Apply all non-None fields from prefs onto the user model."""
    field_map = {
        'preferred_source_lang': prefs.preferred_source_lang,
        'preferred_target_lang': prefs.preferred_target_lang,
        'full_name': prefs.full_name,
        'phone': prefs.phone,
        'bio': prefs.bio,
        'dob': prefs.dob,
        'nationality': prefs.nationality,
        'home_country': prefs.home_country,
        'current_destination': prefs.current_destination,
        'travel_history': prefs.travel_history,
    }
    for field, value in field_map.items():
        if value is not None:
            setattr(current_user, field, value)

@app.patch("/users/me", response_model=UserOut, tags=["User"])
async def update_user_prefs_patch(
    prefs: UserPrefsUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    _apply_prefs(current_user, prefs)
    db.commit()
    db.refresh(current_user)
    return current_user

@app.put("/users/me", response_model=UserOut, tags=["User"])
async def update_user_prefs_put(
    prefs: UserPrefsUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    _apply_prefs(current_user, prefs)
    db.commit()
    db.refresh(current_user)
    return current_user

@app.post("/users/me/verify-password", tags=["User"])
async def verify_password(
    data: PasswordVerify,
    current_user: models.User = Depends(auth.get_current_user),
):
    is_valid = auth.verify_password(data.password, current_user.hashed_password)
    if not is_valid:
        raise HTTPException(status_code=400, detail="Incorrect password")
    return {"status": "success"}

@app.delete("/users/me", tags=["User"])
async def delete_user(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    db.delete(current_user)
    db.commit()
    return {"status": "success"}

# ── Translation ────────────────────────────────────────────────────────────────
@app.post("/translate", response_model=TranslationResponse, tags=["Translation"])
async def translate(
    request: TranslationRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    if not request.text.strip():
        raise HTTPException(status_code=422, detail="Text cannot be empty")
    if len(request.text) > 5000:
        raise HTTPException(status_code=422, detail="Text too long (max 5000 characters)")

    target = LANG_MAP.get(request.target_lang, request.target_lang.lower())
    engine_label = "cloud"
    t_start = time.perf_counter()

    try:
        # Attempt cloud translation
        translator = GoogleTranslator(source="auto", target=target)
        translated = translator.translate(request.text)
        
        if not translated:
            raise ValueError("Empty response from translation engine")
            
        engine_label = "cloud"
    except Exception as e:
        print(f"Translation Error: {str(e)}")
        # If cloud fails, return the original text marked as fallback
        translated = f"[Offline Fallback] {request.text}"
        engine_label = "fallback"

    latency_ms = round((time.perf_counter() - t_start) * 1000, 1)

    # Persist to history
    history_entry = models.TranslationHistory(
        user_id=current_user.id,
        source_text=request.text,
        translated_text=translated,
        source_lang=request.source_lang,
        target_lang=request.target_lang,
        engine=engine_label,
        latency_ms=latency_ms,
        was_voice_input=request.was_voice_input,
    )
    db.add(history_entry)
    db.commit()

    return TranslationResponse(
        original=request.text,
        translated=translated,
        source_lang=request.source_lang,
        target_lang=request.target_lang,
        engine=engine_label,
        latency_ms=latency_ms,
        timestamp=datetime.now(timezone.utc).isoformat(),
    )

@app.get("/tts", tags=["Translation"])
async def get_tts(text: str, lang: str):
    """Generates and streams audio for the given text and language."""
    if not text:
        raise HTTPException(status_code=400, detail="Text is required")
    
    # Map to gTTS code (e.g. Hindi -> 'hi')
    lang_code = LANG_MAP.get(lang, "en")
    
    try:
        tts = gTTS(text=text, lang=lang_code)
        mp3_fp = io.BytesIO()
        tts.write_to_fp(mp3_fp)
        mp3_fp.seek(0)
        return StreamingResponse(mp3_fp, media_type="audio/mpeg")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ── History ────────────────────────────────────────────────────────────────────
@app.get("/history", response_model=List[HistoryItem], tags=["History"])
async def get_history(
    limit: int = Query(default=50, le=200),
    offset: int = Query(default=0, ge=0),
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    items = (
        db.query(models.TranslationHistory)
        .filter(models.TranslationHistory.user_id == current_user.id)
        .order_by(models.TranslationHistory.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return items

@app.delete("/history/{item_id}", tags=["History"])
async def delete_history_item(
    item_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    item = db.query(models.TranslationHistory).filter(
        models.TranslationHistory.id == item_id,
        models.TranslationHistory.user_id == current_user.id,
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="History item not found")
    db.delete(item)
    db.commit()
    return {"detail": "Deleted"}

@app.delete("/history", tags=["History"])
async def clear_history(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    db.query(models.TranslationHistory).filter(
        models.TranslationHistory.user_id == current_user.id
    ).delete()
    db.commit()
    return {"detail": "History cleared"}

# ── Stats ──────────────────────────────────────────────────────────────────────
@app.get("/stats/me", response_model=UserStats, tags=["Stats"])
async def get_my_stats(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    from sqlalchemy import func as sqlfunc
    records = db.query(models.TranslationHistory).filter(
        models.TranslationHistory.user_id == current_user.id
    ).all()

    total = len(records)
    cloud = sum(1 for r in records if r.engine == "cloud")
    offline = sum(1 for r in records if r.engine in ("offline", "fallback"))
    latencies = [r.latency_ms for r in records if r.latency_ms is not None]
    avg_lat = round(sum(latencies) / len(latencies), 1) if latencies else None

    # Favourite target language
    from collections import Counter
    target_counter = Counter(r.target_lang for r in records)
    fav_target = target_counter.most_common(1)[0][0] if target_counter else None

    return UserStats(
        total_translations=total,
        cloud_translations=cloud,
        offline_translations=offline,
        favorite_target_lang=fav_target,
        avg_latency_ms=avg_lat,
        member_since=current_user.created_at,
    )

# ── Admin ──────────────────────────────────────────────────────────────────────
@app.get("/admin/users", response_model=List[UserOut], tags=["Admin"])
async def admin_list_users(
    current_user: models.User = Depends(auth.get_current_admin),
    db: Session = Depends(get_db),
):
    return db.query(models.User).all()

@app.get("/admin/users/{contact}", response_model=UserOut, tags=["Admin"])
async def admin_get_user(
    contact: str,
    current_user: models.User = Depends(auth.get_current_admin),
    db: Session = Depends(get_db),
):
    user = db.query(models.User).filter(
        (models.User.email == contact) | (models.User.phone == contact)
    ).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.patch("/admin/users/{user_id}/toggle-active", tags=["Admin"])
async def admin_toggle_user_active(
    user_id: int,
    current_user: models.User = Depends(auth.get_current_admin),
    db: Session = Depends(get_db),
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot deactivate yourself")
    user.is_active = not user.is_active
    db.commit()
    return {"user_id": user_id, "is_active": user.is_active}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
