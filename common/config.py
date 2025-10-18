# ===========================
# common/config.py (Updated Robust Version)
# ===========================
from pydantic_settings import BaseSettings
from typing import Optional
import logging

class Settings(BaseSettings):
    DATABASE_URL: str
    REDIS_URL: str
    HUGGINGFACE_API_KEY: Optional[str] = None
    ENV: str = "development"

    class Config:
        env_file = ".env"

settings = Settings()

# Log missing API key warning
if not settings.HUGGINGFACE_API_KEY:
    logging.warning("⚠️  HUGGINGFACE_API_KEY not found. AI generation features may fail.")