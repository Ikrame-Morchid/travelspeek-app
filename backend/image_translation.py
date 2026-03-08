"""
📷 IMAGE TRANSLATION SERVICE
EasyOCR + better-profanity + Deep Translator + Image Enhancement
"""

import logging
from pathlib import Path
from typing import Optional
import easyocr
from better_profanity import profanity
from deep_translator import GoogleTranslator

logger = logging.getLogger(__name__)

IMAGE_UPLOADS_DIR = Path("image_uploads")
IMAGE_UPLOADS_DIR.mkdir(exist_ok=True)

profanity.load_censor_words()

HATE_PHRASES = [
    "i hate you", "i hate", "kill yourself", "kill you",
    "i will kill", "go die", "you are stupid", "you are idiot",
    "you are dumb", "drop dead", "you suck", "get lost",
    "shut up", "i despise", "you disgust", "worthless",
    "you are worthless", "nobody likes you", "go to hell",
    "you are trash", "you are garbage", "die", "idiot",
    "moron", "imbecile", "loser", "freak", "ugly",
    "أكره", "اقتل", "أنت غبي", "يلعن",
    "je te déteste", "va mourir", "ferme ta gueule",
    "tu es nul", "idiot", "imbécile", "crétin",
]


def _check_hate(text: str) -> tuple[bool, list]:
    text_lower = text.lower()
    found = [p for p in HATE_PHRASES if p.lower() in text_lower]
    return len(found) > 0, found


class ImageTranslationService:

    def __init__(self):
        logger.info("Chargement EasyOCR Latin (en, fr, es, de)...")
        self.reader_latin  = easyocr.Reader(['en', 'fr', 'es', 'de'], gpu=False)
        logger.info("EasyOCR Latin prêt !")

        logger.info("Chargement EasyOCR Arabe (ar, en)...")
        self.reader_arabic = easyocr.Reader(['ar', 'en'], gpu=False)
        logger.info("EasyOCR Arabe prêt !")

        logger.info("better-profanity + hate-list prêts !")

    def _get_reader(self, source_lang: str):
        if source_lang in ('ar', 'fa', 'ur'):
            return self.reader_arabic
        return self.reader_latin

    def extract_text(self, image_path: str, source_lang: str = 'auto',
                     enhance: bool = True) -> dict:
        """Image → Texte (EasyOCR)"""
        logger.info(f"OCR ({source_lang}) : {image_path}")

        # Amélioration image (optionnelle)
        ocr_path = image_path
        if enhance:
            try:
                from image_enhancement import get_enhancement_service
                ocr_path = get_enhancement_service().enhance_for_ocr(image_path)
                logger.info("Image améliorée avec succès")
            except Exception as e:
                logger.warning(f"Échec amélioration, image originale : {e}")
                ocr_path = image_path

        # ── Inverser fond noir → fond blanc pour améliorer OCR ──────
        import cv2
        import numpy as np
        img_cv = cv2.imread(ocr_path)
        if img_cv is not None:
            gray      = cv2.cvtColor(img_cv, cv2.COLOR_BGR2GRAY)
            mean_val  = np.mean(gray)
            # Si fond sombre (moyenne < 127), inverser l'image
            if mean_val < 127:
                logger.info(f"Fond sombre détecté (moy={mean_val:.0f}), inversion...")
                img_cv   = cv2.bitwise_not(img_cv)
                inv_path = ocr_path.replace('.jpg', '_inv.jpg').replace('.png', '_inv.png')
                cv2.imwrite(inv_path, img_cv)
                ocr_path = inv_path

        reader  = self._get_reader(source_lang)
        is_rtl  = source_lang in ('ar', 'fa', 'ur', 'auto')

        results = reader.readtext(ocr_path, detail=1, paragraph=False)

        # ── Trier les blocs par ligne (y) puis par x selon la direction ──
        def _top_y(item):
            bbox = item[0]
            return min(pt[1] for pt in bbox)

        def _left_x(item):
            bbox = item[0]
            return min(pt[0] for pt in bbox)

        # Grouper par lignes (tolérance 20px)
        results_sorted = sorted(results, key=_top_y)
        lines, current_line, last_y = [], [], -1
        for item in results_sorted:
            y = _top_y(item)
            if last_y == -1 or abs(y - last_y) < 20:
                current_line.append(item)
            else:
                lines.append(current_line)
                current_line = [item]
            last_y = y
        if current_line:
            lines.append(current_line)

        # Dans chaque ligne : RTL = trier par x décroissant, LTR = croissant
        ordered = []
        for line in lines:
            sorted_line = sorted(line, key=_left_x, reverse=is_rtl)
            ordered.extend(sorted_line)

        blocks, text_parts = [], []
        for (bbox, text, confidence) in ordered:
            logger.debug(f"  OCR block: '{text}' conf={confidence:.3f}")
            if confidence > 0.1:
                text_parts.append(text)
                blocks.append({
                    "text":       text,
                    "confidence": round(confidence, 3),
                    "bbox":       [list(map(int, point)) for point in bbox],
                })

        full_text = " ".join(text_parts).strip()
        logger.info(f"'{full_text[:80]}' ({len(blocks)} blocs)")

        return {
            "full_text":    full_text,
            "blocks":       blocks,
            "total_blocks": len(blocks),
        }

    def analyze_toxicity(self, text: str) -> dict:
        """Texte → Analyse haine/gros mots"""
        if not text.strip():
            return {
                "is_offensive":    False,
                "toxicity":        0.0,
                "offensive_words": [],
                "censored_text":   text,
                "main_category":   "none",
                "message":         "Le texte ne contient aucun contenu haineux.",
                "method":          "better-profanity + hate-list (offline)",
            }

        logger.info(f"🛡️  Analyse : '{text[:60]}'")

        has_profanity    = profanity.contains_profanity(text)
        censored_text    = profanity.censor(text)
        profanity_words  = [w for w in text.split()
                            if profanity.contains_profanity(w)]
        has_hate, hate_found = _check_hate(text)

        is_offensive    = has_profanity or has_hate
        offensive_words = list(set(profanity_words + hate_found))

        if is_offensive:
            parts = []
            if has_profanity: parts.append("gros mots")
            if has_hate:      parts.append("discours haineux")
            message = f"Ce texte contient du contenu haineux ({', '.join(parts)})."
        else:
            message = "Le texte ne contient aucun contenu haineux."

        logger.info(f"{'OFFENSANT' if is_offensive else '✅ Propre'}")
        return {
            "is_offensive":    is_offensive,
            "toxicity":        0.95 if is_offensive else 0.02,
            "offensive_words": offensive_words,
            "censored_text":   censored_text,
            "main_category":   "hate_speech" if has_hate
                               else ("profanity" if has_profanity else "none"),
            "message":         message,
            "method":          "better-profanity + hate-list (offline)",
        }

    def translate_text(self, text: str, source_lang: str = "auto",
                       target_lang: str = "fr") -> str:
        """Texte → Texte traduit"""
        if not text.strip():
            return ""
        logger.info(f"{source_lang} → {target_lang}")
        return GoogleTranslator(
            source=source_lang, target=target_lang).translate(text)

    def process_image(self, image_path: str, source_lang: str = "auto",
                      target_lang: str = "fr", enhance: bool = True) -> dict:
        """Pipeline complet : Image → OCR → Analyse → Traduction"""
        ocr       = self.extract_text(image_path,
                                      source_lang=source_lang,
                                      enhance=enhance)
        extracted = ocr["full_text"]

        if not extracted:
            return {
                "extracted_text":        "",
                "translated_text":       "",
                "source_lang":           source_lang,
                "target_lang":           target_lang,
                "has_offensive_content": False,
                "toxicity_scores": {
                    "is_offensive": False,
                    "toxicity":     0.0,
                    "message":      "Aucun texte détecté dans l'image.",
                },
                "ocr_blocks":   [],
                "total_blocks": 0,
                "error":        "No text detected in the image",
            }

        toxicity   = self.analyze_toxicity(extracted)
        translated = self.translate_text(extracted, source_lang, target_lang)

        return {
            "extracted_text":        extracted,
            "translated_text":       translated,
            "source_lang":           source_lang,
            "target_lang":           target_lang,
            "has_offensive_content": toxicity["is_offensive"],
            "toxicity_scores":       toxicity,
            "ocr_blocks":            ocr["blocks"],
            "total_blocks":          ocr["total_blocks"],
        }


_service: Optional[ImageTranslationService] = None

def get_image_service() -> ImageTranslationService:
    global _service
    if _service is None:
        _service = ImageTranslationService()
    return _service