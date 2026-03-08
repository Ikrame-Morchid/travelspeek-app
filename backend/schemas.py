# ========================================
# backend/schemas.py
# ========================================

from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional
from datetime import datetime

# ========================================
# 🔹 AUTH
# ========================================

class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    user: dict

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    is_email_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True


# ========================================
# 🔹 EMAIL VERIFICATION
# ========================================

class EmailVerificationRequest(BaseModel):
    email: EmailStr
    code: str

class ResendVerificationRequest(BaseModel):
    email: EmailStr


# ========================================
# 🔹 MONUMENT
# ========================================

class MonumentResponse(BaseModel):
    id: int
    nom: str
    ville: str
    description: str
    localisation: str
    images: List[str]
    image_url: Optional[str] = None

    @classmethod
    def from_orm(cls, obj):
        images = obj.images if obj.images else []
        image_url = images[0] if images else None
        return cls(
            id=obj.id,
            nom=obj.nom,
            ville=obj.ville,
            description=obj.description,
            localisation=obj.localisation,
            images=images,
            image_url=image_url
        )

    class Config:
        from_attributes = True


# ========================================
# 🔹 FAVORIS
# ========================================

class FavorisCreate(BaseModel):
    monument_id: int

class FavorisResponse(BaseModel):
    id: int
    monument_id: int
    created_at: datetime
    monument: Optional[MonumentResponse] = None

    class Config:
        from_attributes = True


# ========================================
# 🔹 COMMENTAIRES
# ========================================

class CommentaireCreate(BaseModel):
    monument_id: int
    texte: str

class CommentaireResponse(BaseModel):
    id: int
    user_id: int
    monument_id: int
    texte: str
    created_at: datetime
    username: Optional[str] = "Anonyme"  # ✅ Optional avec valeur par défaut
    user_email: Optional[str] = None
    user_avatar: Optional[str] = None

    class Config:
        from_attributes = True


# ========================================
# 🔹 TRANSLATIONS
# ========================================

class TranslationCreate(BaseModel):
    source_text: str
    source_language: str
    target_language: str
    type: str = 'text'

class TranslationResponse(BaseModel):
    id: int
    source_text: str
    translated_text: str
    source_language: str
    target_language: str
    type: str
    has_offensive_content: bool
    created_at: datetime

    class Config:
        from_attributes = True


# ========================================
# 🔹 MESSAGES (ChatBot)
# ========================================

class MessageCreate(BaseModel):
    content: str
    conversation_id: Optional[str] = None

class MessageResponse(BaseModel):
    id: int
    role: str
    content: str
    conversation_id: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class ChatResponse(BaseModel):
    message: MessageResponse
    response: str
    conversation_id: str


# ========================================
# 🔹 SEARCHES
# ========================================

class SearchCreate(BaseModel):
    query: str

class SearchResponse(BaseModel):
    id: int
    query: str
    result_count: int
    created_at: datetime

    class Config:
        from_attributes = True


# ========================================
# 🔹 HISTORIQUE
# ========================================

class HistoryResponse(BaseModel):
    translations: List[TranslationResponse]
    searches: List[SearchResponse]
    comments: List[CommentaireResponse]
    favoris: List[FavorisResponse]

class StatisticsResponse(BaseModel):
    total_translations: int
    total_searches: int
    total_comments: int
    total_favoris: int
    popular_searches: List[dict]


# ========================================
# 🔹 FEEDBACK
# ========================================

class FeedbackCreate(BaseModel):
    rating: int = Field(..., ge=1, le=5, description="Note de 1 à 5 étoiles")
    comment: Optional[str] = None
    category: Optional[str] = "general"

class FeedbackResponse(BaseModel):
    id: int
    user_id: Optional[int] = None
    username: Optional[str] = "Anonyme"
    rating: int
    comment: Optional[str] = None
    category: str
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True