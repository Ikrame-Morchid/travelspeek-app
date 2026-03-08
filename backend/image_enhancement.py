"""
✨ IMAGE ENHANCEMENT SERVICE
Améliore la qualité des images avant OCR
"""

import cv2
import numpy as np
from pathlib import Path
import logging
from typing import Optional

logger = logging.getLogger(__name__)


class ImageEnhancementService:

    def __init__(self):
        logger.info("Initialisation Image Enhancement Service...")
        logger.info("Image Enhancement prêt !")

    def enhance_for_ocr(self, image_path: str, output_path: Optional[str] = None) -> str:
        """
        Pipeline d'amélioration pour OCR — VERSION CORRIGÉE
        
        Supprimé : binarisation adaptative (détruisait le texte)
        Conservé : redimensionnement + contraste léger
        """
        logger.info(f"✨ Amélioration : {image_path}")

        img = cv2.imread(image_path)
        if img is None:
            raise ValueError(f"Impossible de charger l'image : {image_path}")

        # 1. Redimensionner si trop petite (améliore l'OCR)
        img = self._resize_if_needed(img)

        # 2. Contraste léger (CLAHE sur luminosité seulement)
        img = self._enhance_contrast(img)

        # 3. Légère netteté
        img = self._sharpen(img)

        if output_path is None:
            output_path = str(Path(image_path).with_suffix('.enhanced.jpg'))

        cv2.imwrite(output_path, img, [cv2.IMWRITE_JPEG_QUALITY, 95])
        logger.info(f"Image améliorée : {output_path}")

        return output_path

    def _resize_if_needed(self, img: np.ndarray) -> np.ndarray:
        """
        Redimensionne si l'image est trop petite.
        EasyOCR fonctionne mieux sur des images >= 640px de large.
        """
        height, width = img.shape[:2]
        min_width = 640

        if width < min_width:
            scale  = min_width / width
            new_w  = int(width  * scale)
            new_h  = int(height * scale)
            img    = cv2.resize(img, (new_w, new_h),
                                interpolation=cv2.INTER_CUBIC)
            logger.info(f"Redimensionné : {width}x{height} → {new_w}x{new_h}")

        return img

    def _enhance_contrast(self, img: np.ndarray) -> np.ndarray:
        """
        CLAHE léger sur le canal L uniquement.
        Améliore la lisibilité sans déformer les couleurs.
        """
        lab       = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        l, a, b   = cv2.split(lab)

        # clipLimit bas (2.0) = effet léger, non destructif
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        l     = clahe.apply(l)

        lab = cv2.merge([l, a, b])
        return cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)

    def _sharpen(self, img: np.ndarray) -> np.ndarray:
        """
        Netteté légère pour rendre les contours du texte plus nets.
        """
        kernel = np.array([
            [ 0, -1,  0],
            [-1,  5, -1],
            [ 0, -1,  0]
        ])
        return cv2.filter2D(img, -1, kernel)

    def quick_enhance(self, image_path: str, output_path: Optional[str] = None) -> str:
        """
        Amélioration rapide = même pipeline que enhance_for_ocr.
        """
        return self.enhance_for_ocr(image_path, output_path)


# Singleton
_enhancement_service = None

def get_enhancement_service() -> ImageEnhancementService:
    global _enhancement_service
    if _enhancement_service is None:
        _enhancement_service = ImageEnhancementService()
    return _enhancement_service