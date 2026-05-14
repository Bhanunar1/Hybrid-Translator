from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, Float, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_admin = Column(Boolean, default=False)
    full_name = Column(String)
    phone = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_login = Column(DateTime(timezone=True), nullable=True)
    is_active = Column(Boolean, default=True)
    preferred_source_lang = Column(String, default="English")
    preferred_target_lang = Column(String, default="Telugu")
    
    # New Personal & Travel Fields
    bio = Column(Text, nullable=True)
    dob = Column(String, nullable=True)
    nationality = Column(String, nullable=True)
    home_country = Column(String, nullable=True)
    current_destination = Column(String, nullable=True)
    travel_history = Column(Text, nullable=True) # Comma separated list
    profile_image_url = Column(String, nullable=True)

    translations = relationship("TranslationHistory", back_populates="user", cascade="all, delete-orphan")


class TranslationHistory(Base):
    __tablename__ = "translation_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    source_text = Column(Text, nullable=False)
    translated_text = Column(Text, nullable=False)
    source_lang = Column(String, nullable=False)
    target_lang = Column(String, nullable=False)
    engine = Column(String, default="cloud")          # 'cloud' | 'offline' | 'emergency'
    latency_ms = Column(Float, nullable=True)
    was_voice_input = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="translations")
