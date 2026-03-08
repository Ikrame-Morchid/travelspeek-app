"""
ROUTES API — Traduction Image
EasyOCR + better-profanity + Deep Translator + Image Enhancement
"""

import shutil
import uuid
from pathlib import Path
from typing import Optional
from fastapi import APIRouter, File, Form, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from image_translation import get_image_service, IMAGE_UPLOADS_DIR

router = APIRouter(prefix="/api/image", tags=["Image Translation"])

ALLOWED = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".webp"}


@router.post("/translate", summary="Image → OCR → Détection haine → Traduction")
async def translate_image(
    image:       UploadFile = File(...,     description="Image (jpg, png, bmp, webp)"),
    source_lang: str        = Form("auto",  description="Langue source : auto | en | fr | ar"),
    target_lang: str        = Form("fr",    description="Langue cible  : fr | en | ar | es"),
    enhance:     bool       = Form(True,    description="Améliorer qualité image avant OCR"),
):
    """
    Pipeline complet de traduction d'image :
    1. Amélioration qualité (optionnel)
    2. OCR (EasyOCR) → Extraction du texte
    3. Analyse toxicité (better-profanity)
    4. Traduction (Deep Translator)
    """
    ext = Path(image.filename or "image.jpg").suffix.lower()
    if ext not in ALLOWED:
        raise HTTPException(400, f"Format non supporté : '{ext}'")

    uid        = uuid.uuid4().hex
    image_path = IMAGE_UPLOADS_DIR / f"{uid}{ext}"
    with open(image_path, "wb") as f:
        shutil.copyfileobj(image.file, f)

    try:
        result   = get_image_service().process_image(
            image_path  = str(image_path),
            source_lang = source_lang,
            target_lang = target_lang,
            enhance     = enhance,
        )
        toxicity = result.get("toxicity_scores", {})
        return JSONResponse({
            "success":               True,
            "extracted_text":        result.get("extracted_text", ""),
            "total_blocks":          result.get("total_blocks", 0),
            "ocr_blocks":            result.get("ocr_blocks", []),
            "translated_text":       result.get("translated_text", ""),
            "source_lang":           result.get("source_lang", source_lang),
            "target_lang":           result.get("target_lang", target_lang),
            "has_offensive_content": result.get("has_offensive_content", False),
            "hate_speech_message":   toxicity.get("message", ""),
            "offensive_words":       toxicity.get("offensive_words", []),
            "censored_text":         toxicity.get("censored_text", ""),
            "error":                 result.get("error", None),
        })
    except Exception as e:
        raise HTTPException(500, f"Erreur interne : {e}")
    finally:
        image_path.unlink(missing_ok=True)


@router.post("/test-ocr", summary="TEST EasyOCR : Image → Texte")
async def test_ocr(
    image:       UploadFile    = File(...,     description="Image"),
    source_lang: Optional[str] = Form("auto",  description="Langue : auto | en | fr | ar"),
    enhance:     bool          = Form(True,    description="Améliorer qualité image"),
):
    """
    Test de reconnaissance de texte (OCR) uniquement
    """
    ext        = Path(image.filename or "image.jpg").suffix.lower()
    uid        = uuid.uuid4().hex
    image_path = IMAGE_UPLOADS_DIR / f"{uid}{ext}"
    with open(image_path, "wb") as f:
        shutil.copyfileobj(image.file, f)
    try:
        result = get_image_service().extract_text(
            str(image_path), 
            source_lang=source_lang or "auto",
            enhance=enhance
        )
        return JSONResponse({"success": True, **result})
    except Exception as e:
        raise HTTPException(500, f"Erreur OCR : {e}")
    finally:
        image_path.unlink(missing_ok=True)


@router.post("/test-toxicity", summary="TEST Détection haine : Texte → Analyse")
async def test_toxicity(
    text: str = Form(..., description="Texte à analyser (ex: Hello world / I hate you)"),
):
    """
    Test de détection de contenu haineux/offensant
    """
    if not text.strip():
        raise HTTPException(400, "Texte vide.")
    try:
        result = get_image_service().analyze_toxicity(text.strip())
        return JSONResponse({
            "success":         True,
            "text":            text.strip(),
            "is_offensive":    result["is_offensive"],
            "message":         result["message"],
            "offensive_words": result["offensive_words"],
            "censored_text":   result["censored_text"],
            "main_category":   result["main_category"],
            "method":          result["method"],
        })
    except Exception as e:
        raise HTTPException(500, f"Erreur : {e}")


@router.post("/test-translate-text", summary="TEST Traduction : Texte → Texte traduit")
async def test_translate_text(
    text:        str = Form(...,    description="Texte à traduire"),
    source_lang: str = Form("auto", description="Langue source : auto | en | fr | ar"),
    target_lang: str = Form("fr",   description="Langue cible : fr | en | ar | es"),
):
    """
    Test de traduction de texte uniquement
    """
    if not text.strip():
        raise HTTPException(400, "Texte vide.")
    try:
        translated = get_image_service().translate_text(text.strip(), source_lang, target_lang)
        return JSONResponse({
            "success":         True,
            "original_text":   text.strip(),
            "translated_text": translated,
            "source_lang":     source_lang,
            "target_lang":     target_lang,
        })
    except Exception as e:
        raise HTTPException(500, f"Erreur : {e}")


@router.post("/test-enhancement", summary="TEST Amélioration : Image → Image améliorée")
async def test_enhancement(
    image: UploadFile = File(..., description="Image à améliorer"),
):
    """
    Test d'amélioration de qualité d'image
    """
    ext        = Path(image.filename or "image.jpg").suffix.lower()
    uid        = uuid.uuid4().hex
    image_path = IMAGE_UPLOADS_DIR / f"{uid}{ext}"
    
    with open(image_path, "wb") as f:
        shutil.copyfileobj(image.file, f)
    
    try:
        from image_enhancement import get_enhancement_service
        enhanced_path = get_enhancement_service().enhance_for_ocr(str(image_path))
        
        return JSONResponse({
            "success": True,
            "message": "Image améliorée avec succès",
            "original_path": str(image_path),
            "enhanced_path": enhanced_path,
        })
    except Exception as e:
        raise HTTPException(500, f"Erreur amélioration : {e}")
    finally:
        image_path.unlink(missing_ok=True)