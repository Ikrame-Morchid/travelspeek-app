# ========================================
# backend/voice_translation.py
# Service de traduction vocale
# ========================================

import os
import tempfile
import logging
from pathlib import Path
from typing import Optional
from faster_whisper import WhisperModel
from deep_translator import GoogleTranslator
from gtts import gTTS

logger = logging.getLogger(__name__)

# ── Configuration ──────────────────────────────────────────
MODEL_SIZE   = "base"   # tiny | base | small | medium | large-v3
DEVICE       = "cpu"    # "cpu" ou "cuda" si vous avez un GPU NVIDIA
COMPUTE_TYPE = "int8"   # "int8" pour CPU (rapide), "float16" pour GPU

AUDIO_UPLOADS_DIR = Path("audio_uploads")
AUDIO_OUTPUTS_DIR = Path("audio_outputs")
AUDIO_UPLOADS_DIR.mkdir(exist_ok=True)
AUDIO_OUTPUTS_DIR.mkdir(exist_ok=True)


class VoiceTranslationService:
    """Service de traduction vocale avec Faster-Whisper + Deep Translator + gTTS"""

    def __init__(self):
        logger.info(f"⚡ Chargement du modèle Faster-Whisper '{MODEL_SIZE}'...")
        self.model = WhisperModel(MODEL_SIZE, device=DEVICE, compute_type=COMPUTE_TYPE)
        logger.info("Modèle Whisper prêt !")

    def transcribe(self, audio_path: str, language: Optional[str] = None) -> dict:
        """
        Transcrit un fichier audio en texte.
        
        Args:
            audio_path: Chemin vers le fichier audio
            language: Code langue (ex: 'fr', 'en', 'ar') ou None pour auto-détection
            
        Returns:
            Dict avec text, language, confidence, segments
        """
        logger.info(f"🎤 Transcription de : {audio_path}")

        segments, info = self.model.transcribe(
            audio_path,
            language=language,
            beam_size=5,
            vad_filter=True,  # Voice Activity Detection
            vad_parameters=dict(min_silence_duration_ms=500),
        )

        full_text = ""
        segments_list = []
        
        for seg in segments:
            full_text += seg.text
            segments_list.append({
                "start": round(seg.start, 2),
                "end":   round(seg.end, 2),
                "text":  seg.text.strip(),
            })

        logger.info(f"Transcription terminée ({info.language}) : '{full_text.strip()}'")
        
        return {
            "text":                full_text.strip(),
            "language":            info.language,
            "language_confidence": round(info.language_probability, 2),
            "segments":            segments_list,
        }

    def translate(self, text: str, source_lang: str = "auto", target_lang: str = "fr") -> str:
        """
        Traduit un texte d'une langue à une autre.
        
        Args:
            text: Texte à traduire
            source_lang: Langue source ('auto' pour auto-détection)
            target_lang: Langue cible
            
        Returns:
            Texte traduit
        """
        if not text.strip():
            return ""
            
        logger.info(f"Traduction {source_lang} → {target_lang}")
        
        translated = GoogleTranslator(source=source_lang, target=target_lang).translate(text)
        
        logger.info(f"Traduction : '{translated}'")
        return translated

    def synthesize(self, text: str, lang: str = "fr", output_path: Optional[str] = None) -> str:
        """
        Génère un fichier audio MP3 à partir du texte (TTS).
        
        Args:
            text: Texte à synthétiser
            lang: Code langue pour la voix
            output_path: Chemin de sortie (créé automatiquement si None)
            
        Returns:
            Chemin du fichier audio généré
        """
        if not text.strip():
            raise ValueError("Texte vide, impossible de générer l'audio.")
            
        if output_path is None:
            tmp = tempfile.NamedTemporaryFile(suffix=".mp3", dir=AUDIO_OUTPUTS_DIR, delete=False)
            output_path = tmp.name
            
        logger.info(f"Synthèse vocale ({lang})...")
        gTTS(text=text, lang=lang, slow=False).save(output_path)
        logger.info(f"Audio généré : {output_path}")
        
        return output_path

    def translate_audio(
        self,
        audio_path: str,
        source_lang: Optional[str] = None,
        target_lang: str = "fr",
        tts_lang: Optional[str] = None,
    ) -> dict:
        """
        Pipeline complet : Audio → Transcription → Traduction → Audio traduit.
        
        Args:
            audio_path: Chemin vers le fichier audio source
            source_lang: Langue source (None pour auto-détection)
            target_lang: Langue cible pour la traduction
            tts_lang: Langue pour la synthèse vocale (par défaut = target_lang)
            
        Returns:
            Dict avec tous les résultats
        """
        # Étape 1 : Transcription
        transcription = self.transcribe(audio_path, language=source_lang)
        original_text = transcription["text"]
        detected_lang = transcription["language"]

        if not original_text:
            raise ValueError("Aucun texte détecté dans l'audio.")

        # Étape 2 : Traduction
        translated_text = self.translate(
            original_text, 
            source_lang=detected_lang, 
            target_lang=target_lang
        )

        # Étape 3 : Synthèse vocale
        audio_output = self.synthesize(translated_text, lang=tts_lang or target_lang)

        return {
            "original_text":     original_text,
            "translated_text":   translated_text,
            "detected_language": detected_lang,
            "target_language":   target_lang,
            "audio_output_path": audio_output,
            "segments":          transcription["segments"],
        }


# ========================================
# SINGLETON - Instance unique
# ========================================

_service: Optional[VoiceTranslationService] = None

def get_voice_service() -> VoiceTranslationService:
    """
    Retourne l'instance unique du service (chargé une seule fois).
    """
    global _service
    if _service is None:
        _service = VoiceTranslationService()
    return _service