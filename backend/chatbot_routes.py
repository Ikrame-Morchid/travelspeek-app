"""
ROUTES FastAPI — Chatbot TravelSpeak
Avec rate limiting + validation + audio
"""

import logging, os, tempfile
from typing import Optional
from fastapi import APIRouter, HTTPException, UploadFile, File, Header
from fastapi.responses import JSONResponse
from pydantic import BaseModel, validator
from chatbot_service import (
    process_message, get_weather, get_location,
    MONUMENTS, MAX_MESSAGE_LENGTH, MAX_REQUESTS_PER_DAY,
    check_rate_limit,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/chatbot", tags=["Chatbot"])

# ── Modèles ────────────────────────────────────────────────

class ChatRequest(BaseModel):
    message:  str
    city:     Optional[str] = None
    history:  list          = []
    user_id:  str           = "default"

    @validator("message")
    def message_not_empty(cls, v):
        if not v.strip():
            raise ValueError("Message vide.")
        if len(v) > MAX_MESSAGE_LENGTH:
            raise ValueError(
                f"Message trop long ({len(v)} car.). Max : {MAX_MESSAGE_LENGTH}.")
        return v.strip()

class WeatherRequest(BaseModel):
    city: str

class LocationRequest(BaseModel):
    place: str

# ── POST /api/chatbot/message ─────────────────────────────

@router.post("/message")
async def chat(req: ChatRequest):
    """
    Message texte → pipeline complet.
    Inclut rate limiting, cache, Wikidata, météo, localisation.
    """
    try:
        result = await process_message(
            message = req.message,
            city    = req.city,
            history = req.history,
            user_id = req.user_id,
        )
        # Si rate limit ou erreur → retourner quand même 200 avec le message
        return JSONResponse({
            "success":    result.get("error") is None,
            "reply":      result["reply"],
            "weather":    result.get("weather"),
            "location":   result.get("location"),
            "monument":   result.get("monument"),
            "source":     result.get("source"),
            "rate_limit": result.get("rate_limit"),
            "error":      result.get("error"),
        })
    except Exception as e:
        logger.error(f"Chat : {e}")
        raise HTTPException(500, str(e))

# ── POST /api/chatbot/audio ───────────────────────────────

@router.post("/audio")
async def chat_audio(
    audio:   UploadFile = File(...),
    city:    Optional[str] = None,
    user_id: str           = "default",
):
    """
    Audio → Faster-Whisper (transcription) → pipeline chatbot.
    Réutilise le service Whisper déjà installé.
    """
    try:
        suffix = os.path.splitext(audio.filename or "audio.m4a")[1] or ".m4a"
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(await audio.read())
            tmp_path = tmp.name

        # Transcription via Whisper existant
        from voice_translation_service import get_voice_service
        voice_svc     = get_voice_service()
        transcription = voice_svc.transcribe(tmp_path)
        os.unlink(tmp_path)

        text = transcription.get("text", "").strip()
        if not text:
            raise HTTPException(400, "Transcription vide — audio non reconnu.")

        result = await process_message(message=text, city=city, user_id=user_id)

        return JSONResponse({
            "success":       result.get("error") is None,
            "transcription": text,
            "reply":         result["reply"],
            "weather":       result.get("weather"),
            "location":      result.get("location"),
            "monument":      result.get("monument"),
            "source":        result.get("source"),
            "rate_limit":    result.get("rate_limit"),
            "error":         result.get("error"),
        })
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Audio chat : {e}")
        raise HTTPException(500, str(e))

# ── POST /api/chatbot/weather ─────────────────────────────

@router.post("/weather")
async def weather_only(req: WeatherRequest):
    w = await get_weather(req.city.strip())
    if not w:
        raise HTTPException(404, f"Ville '{req.city}' introuvable.")
    return JSONResponse({"success": True, "weather": w})

# ── POST /api/chatbot/location ────────────────────────────

@router.post("/location")
async def location_only(req: LocationRequest):
    loc = await get_location(req.place.strip())
    if not loc:
        raise HTTPException(404, f"'{req.place}' introuvable.")
    return JSONResponse({"success": True, "location": loc})

# ── GET /api/chatbot/usage/{user_id} ─────────────────────

@router.get("/usage/{user_id}")
async def get_usage(user_id: str):
    """Vérifie le quota restant d'un utilisateur."""
    info = check_rate_limit(user_id)
    return JSONResponse({
        "user_id":   user_id,
        "used":      info["count"],
        "remaining": info["remaining"],
        "limit":     info["limit"],
        "reset_at":  info["reset_at"],
        "allowed":   info["allowed"],
    })

# ── GET /api/chatbot/health ───────────────────────────────

@router.get("/health")
async def health():
    return JSONResponse({
        "status":           "ok",
        "model":            "llama3-8b-8192 (Groq)",
        "monuments_count":  len(MONUMENTS),
        "json_loaded":      len(MONUMENTS) > 0,
        "max_msg_length":   MAX_MESSAGE_LENGTH,
        "max_req_per_day":  MAX_REQUESTS_PER_DAY,
        "features": [
            "rate_limiting", "local_cache", "wikidata",
            "wikipedia", "open_meteo", "openstreetmap",
            "speech_to_text", "multilingual"
        ],
    })