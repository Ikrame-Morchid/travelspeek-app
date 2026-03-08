# ========================================
# Détection discours haineux : better-profanity + regex multilingue
# ========================================

import shutil, uuid, re
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, File, Form, UploadFile, HTTPException
from fastapi.responses import FileResponse, JSONResponse

from voice_translation import get_voice_service, AUDIO_UPLOADS_DIR, AUDIO_OUTPUTS_DIR

# Import better-profanity (déjà installé via requirements image)
try:
    from better_profanity import profanity
    profanity.load_censor_words()
    BETTER_PROFANITY_AVAILABLE = True
except ImportError:
    BETTER_PROFANITY_AVAILABLE = False

router = APIRouter(prefix="/api/voice", tags=["Voice Translation"])

# ========================================
# MOTEUR DÉTECTION DISCOURS HAINEUX
# Couche 1 : better-profanity (EN principalement)
# Couche 2 : regex multilingue FR + AR + EN
# ========================================

HATE_CATEGORIES = {
    "violence": [
        "tuer", "kill", "murder", "mort subite", "die", "bombe", "bomb",
        "attentat", "terroriste", "terrorist", "اقتل", "موت", "إرهابي",
        "assassin", "massacre", "exterminer", "genocide", "égorger",
    ],
    "insultes": [
        "idiot", "imbécile", "crétin", "connard", "asshole", "bitch",
        "stupid", "moron", "غبي", "كلب", "حمار", "abruti", "enculé",
        "ordure", "salaud", "va te faire",
    ],
    "discrimination": [
        "négro", "nègre", "bougnoule", "nigger", "faggot", "racist",
        "nazi", "raton", "bicot", "youpin", "feuj", "rebeu",
    ],
    "sexuel": [
        "viol", "violer", "rape", "salope", "cunt", "niquer", "putain",
    ],
}

def analyze_hate_speech(text: str, lang: str = "auto") -> dict:
    """
    Analyse combinée :
    - better-profanity  → détection EN rapide
    - regex maison      → FR, AR, mots spécifiques
    """
    if not text or not text.strip():
        return {
            "is_hate_speech": False, "confidence": 0.0, "level": "safe",
            "categories": [], "flagged_words": [], "message": "Aucun texte détecté",
        }

    text_lower       = text.lower()
    flagged_words    = []
    detected_cats    = []
    better_profanity_hit = False

    # ── Couche 1 : better-profanity ──────────────────
    if BETTER_PROFANITY_AVAILABLE:
        if profanity.contains_profanity(text):
            better_profanity_hit = True
            # Extraire les mots détectés par better-profanity
            words = text_lower.split()
            for w in words:
                clean = re.sub(r'[^\w]', '', w)
                if clean and profanity.contains_profanity(clean):
                    if clean not in flagged_words:
                        flagged_words.append(clean)
            if "insultes" not in detected_cats:
                detected_cats.append("insultes")

    # ── Couche 2 : regex multilingue maison ──────────
    for category, words in HATE_CATEGORIES.items():
        for word in words:
            pattern = r'\b' + re.escape(word) + r'\b'
            if re.search(pattern, text_lower, re.IGNORECASE | re.UNICODE):
                if word not in flagged_words:
                    flagged_words.append(word)
                if category not in detected_cats:
                    detected_cats.append(category)

    # ── Calcul score ─────────────────────────────────
    nb = len(flagged_words)

    if nb == 0 and not better_profanity_hit:
        confidence, level, is_hate = 0.0, "safe", False
    elif nb <= 1 and not better_profanity_hit:
        confidence, level, is_hate = 0.35, "warning", False
    elif nb <= 1 and better_profanity_hit:
        confidence, level, is_hate = 0.6, "warning", False
    elif nb == 2:
        confidence, level, is_hate = 0.75, "danger", True
    else:
        confidence = min(0.95, 0.65 + nb * 0.08)
        level, is_hate = "danger", True

    # Boost violence
    if "violence" in detected_cats:
        confidence = min(0.99, confidence + 0.2)
        is_hate, level = True, "danger"

    # Construire message
    if level == "safe":
        msg = "Aucun contenu offensant détecté"
    elif level == "warning":
        msg = f"Contenu potentiellement sensible : {', '.join(detected_cats)}"
    else:
        msg = f"Discours haineux détecté : {', '.join(detected_cats)}"

    return {
        "is_hate_speech": is_hate,
        "confidence":     round(confidence, 2),
        "level":          level,
        "categories":     detected_cats,
        "flagged_words":  flagged_words,
        "message":        msg,
        "engine":         "better-profanity+regex" if BETTER_PROFANITY_AVAILABLE else "regex",
    }


def censor_text(text: str, flagged_words: list) -> str:
    """Censure les mots interdits. Utilise better-profanity si disponible."""
    if BETTER_PROFANITY_AVAILABLE:
        text = profanity.censor(text)  # censure EN automatique
    for word in flagged_words:
        repl = word[0] + '*' * (len(word) - 2) + word[-1] if len(word) > 2 else '***'
        text = re.sub(r'\b' + re.escape(word) + r'\b', repl, text, flags=re.IGNORECASE | re.UNICODE)
    return text


# ========================================
# ROUTES
# ========================================

@router.post("/translate")
async def voice_translate(
    audio:             UploadFile = File(...),
    target_lang:       str  = Form("fr"),
    source_lang:       str  = Form("auto"),
    return_audio:      bool = Form(True),
    check_hate_speech: bool = Form(False),
    censor_output:     bool = Form(False),
):
    ALLOWED = {".mp3", ".wav", ".m4a", ".ogg", ".webm", ".flac", ".aac"}
    ext = Path(audio.filename or "audio.m4a").suffix.lower()
    if ext not in ALLOWED:
        raise HTTPException(400, f"Format non supporté : {ext}. Acceptés : {', '.join(ALLOWED)}")

    uid = uuid.uuid4().hex
    upload_path = AUDIO_UPLOADS_DIR / f"{uid}{ext}"

    with open(upload_path, "wb") as f:
        shutil.copyfileobj(audio.file, f)

    try:
        service = get_voice_service()
        result  = service.translate_audio(
            audio_path  = str(upload_path),
            source_lang = None if source_lang == "auto" else source_lang,
            target_lang = target_lang,
        )

        original_text   = result["original_text"]
        translated_text = result["translated_text"]
        hate_analysis   = None

        if check_hate_speech:
            a1 = analyze_hate_speech(original_text,   result["detected_language"])
            a2 = analyze_hate_speech(translated_text, target_lang)
            hate_analysis = a1 if a1["confidence"] >= a2["confidence"] else a2

            if censor_output and hate_analysis["is_hate_speech"]:
                original_text   = censor_text(original_text,   hate_analysis["flagged_words"])
                translated_text = censor_text(translated_text, hate_analysis["flagged_words"])

        response = {
            "success":           True,
            "original_text":     original_text,
            "translated_text":   translated_text,
            "detected_language": result["detected_language"],
            "target_language":   result["target_language"],
            "segments":          result["segments"],
        }
        if hate_analysis:
            response["hate_speech"] = hate_analysis
        if return_audio:
            filename = Path(result["audio_output_path"]).name
            response["audio_url"] = f"/api/voice/audio/{filename}"

        return JSONResponse(response)

    except ValueError as e:
        raise HTTPException(422, str(e))
    except Exception as e:
        raise HTTPException(500, f"Erreur serveur : {e}")
    finally:
        upload_path.unlink(missing_ok=True)


@router.post("/analyze-hate-speech")
async def analyze_text(text: str = Form(...), lang: str = Form("auto")):
    """Analyser un texte seul sans audio."""
    return JSONResponse(analyze_hate_speech(text, lang))


@router.get("/audio/{filename}")
async def get_audio(filename: str):
    path = AUDIO_OUTPUTS_DIR / filename
    if not path.exists():
        raise HTTPException(404, "Fichier audio introuvable")
    return FileResponse(str(path), media_type="audio/mpeg", filename=filename)


@router.get("/languages")
async def supported_languages():
    return JSONResponse({"languages": {
        "en": "English", "fr": "Français", "ar": "العربية", "es": "Español",
        "de": "Deutsch", "it": "Italiano", "pt": "Português", "zh": "中文",
        "ja": "日本語",  "ru": "Русский",  "nl": "Nederlands", "tr": "Türkçe",
        "ko": "한국어",  "hi": "हिन्दी",
    }})


@router.get("/health")
async def health_check():
    return JSONResponse({
        "status":  "healthy",
        "service": "voice-translation",
        "model":   "faster-whisper-base",
        "hate_speech_engine": "better-profanity+regex" if BETTER_PROFANITY_AVAILABLE else "regex-only",
    })