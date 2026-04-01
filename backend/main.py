# ========================================
# backend/main.py
# ========================================

from fastapi import FastAPI, Depends, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime, timedelta
from pydantic import BaseModel as PydanticBase
import json
import logging

from database import Base, engine, SessionLocal
from schemas import *
from crud import *
from models import User, Feedback, Commentaire
from security import create_access_token, create_refresh_token, decode_token
from email_service import (
    send_verification_email,
    send_welcome_email,
    generate_verification_code
)

from translation_routes import router as voice_router
from image_routes import router as image_router
from chatbot_routes import router as chatbot_router
from search_routes import router as search_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

Base.metadata.create_all(bind=engine)

# ========================================
# SCHEMAS LOCAUX
# ========================================

class ProfileUpdate(PydanticBase):
    username: Optional[str] = None
    email: Optional[str] = None

# ========================================
# APPLICATION
# ========================================

app = FastAPI(
    title="TravelSpeek API",
    version="6.1.0",
    description="🌍 API complète pour TravelSpeek",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(voice_router)
app.include_router(image_router)
app.include_router(chatbot_router)
app.include_router(search_router)

# ========================================
# DEPENDENCIES
# ========================================

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(
    authorization: str = Header(...),
    db: Session = Depends(get_db)
) -> User:
    try:
        if not authorization.startswith("Bearer "):
            raise HTTPException(401, "Invalid authorization header format")
        token = authorization.replace("Bearer ", "")
        payload = decode_token(token)
        if not payload:
            raise HTTPException(401, "Invalid or expired token")
        user = get_user_by_id(db, payload["user_id"])
        if not user:
            raise HTTPException(401, "User not found")
        return user
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(401, "Authentication failed")


def get_optional_user(
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db)
) -> Optional[User]:
    if not authorization:
        return None
    try:
        if not authorization.startswith("Bearer "):
            return None
        token = authorization.replace("Bearer ", "")
        payload = decode_token(token)
        if not payload:
            return None
        return get_user_by_id(db, payload["user_id"])
    except Exception:
        return None

# ========================================
# HELPER
# ========================================

def build_monument_response(m, lang: str = "fr") -> dict:
    description = m.description_fr or m.description or ""
    nom   = m.nom or ""
    ville = m.ville or ""

    if lang == 'en':
        description = m.description_en or description
        nom   = m.nom_en   or nom
        ville = m.ville_en or ville
    elif lang == 'ar':
        description = m.description_ar or description
        nom   = m.nom_ar   or nom
        ville = m.ville_ar or ville
    elif lang == 'es':
        description = m.description_es or description
        nom   = m.nom_es   or nom
        ville = m.ville_es or ville

    images = []
    if m.images:
        if isinstance(m.images, str):
            try:
                images = json.loads(m.images)
            except:
                images = [m.images] if m.images else []
        elif isinstance(m.images, list):
            images = m.images

    image_url = images[0] if images else None

    return {
        "id":           m.id,
        "nom":          nom,
        "ville":        ville,
        "description":  description,
        "localisation": m.localisation or '',
        "images":       images,
        "image_url":    image_url,
    }

# ========================================
# MONUMENTS
# ========================================

@app.get("/monuments", response_model=List[MonumentResponse], tags=["Monuments"])
def list_monuments(lang: str = "fr", db: Session = Depends(get_db)):
    monuments = get_all_monuments(db)
    return [build_monument_response(m, lang) for m in monuments]


@app.get("/monuments/search", response_model=List[MonumentResponse], tags=["Monuments"])
def search_monuments_endpoint(q: str, lang: str = "fr", db: Session = Depends(get_db)):
    monuments = search_monuments(db, q)
    return [build_monument_response(m, lang) for m in monuments]


@app.get("/monuments/{monument_id}", response_model=MonumentResponse, tags=["Monuments"])
def get_monument(monument_id: int, lang: str = "fr", db: Session = Depends(get_db)):
    m = get_monument_by_id(db, monument_id)
    if not m:
        raise HTTPException(404, "Monument not found")
    return build_monument_response(m, lang)

# ========================================
# AUTHENTIFICATION
# ========================================

@app.post("/auth/register", response_model=TokenResponse, tags=["Authentication"])
def register(user: UserCreate, db: Session = Depends(get_db)):
    if get_user_by_email(db, user.email):
        raise HTTPException(400, "Email already registered")

    new_user = create_user(db, user.username, user.email, user.password)

    verification_code = generate_verification_code()
    new_user.email_verification_token = verification_code
    new_user.email_verification_sent_at = datetime.utcnow()
    db.commit()
    db.refresh(new_user)

    try:
        send_verification_email(
            to_email=new_user.email,
            code=verification_code,
            username=new_user.username
        )
    except Exception as e:
        logger.error(f"⚠️ Email sending failed: {e}")

    access_token  = create_access_token({"user_id": new_user.id})
    refresh_token = create_refresh_token({"user_id": new_user.id})

    return {
        "access_token":  access_token,
        "refresh_token": refresh_token,
        "user": {
            "id":                new_user.id,
            "username":          new_user.username,
            "email":             new_user.email,
            "is_email_verified": new_user.is_email_verified,
        },
    }


@app.post("/auth/login", response_model=TokenResponse, tags=["Authentication"])
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    user = authenticate_user(db, credentials.email, credentials.password)
    if not user:
        raise HTTPException(401, "Invalid email or password")

    access_token  = create_access_token({"user_id": user.id})
    refresh_token = create_refresh_token({"user_id": user.id})

    return {
        "access_token":  access_token,
        "refresh_token": refresh_token,
        "user": {
            "id":                user.id,
            "username":          user.username,
            "email":             user.email,
            "is_email_verified": user.is_email_verified,
        },
    }


@app.get("/auth/me", response_model=UserResponse, tags=["Authentication"])
def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@app.post("/auth/verify-email", tags=["Authentication"])
def verify_email(request: EmailVerificationRequest, db: Session = Depends(get_db)):
    user = get_user_by_email(db, request.email)
    if not user:
        raise HTTPException(404, "User not found")
    if user.email_verification_token != request.code:
        raise HTTPException(400, "Invalid verification code")
    if user.email_verification_sent_at:
        expiry_time = user.email_verification_sent_at + timedelta(minutes=10)
        if datetime.utcnow() > expiry_time:
            raise HTTPException(400, "Verification code expired")

    user.is_email_verified = True
    user.email_verification_token = None
    db.commit()
    db.refresh(user)

    try:
        send_welcome_email(to_email=user.email, username=user.username)
    except Exception as e:
        logger.error(f"⚠️ Welcome email failed: {e}")

    return {
        "message": "Email verified successfully",
        "user": {
            "id":                user.id,
            "username":          user.username,
            "email":             user.email,
            "is_email_verified": user.is_email_verified,
        },
    }


@app.post("/auth/resend-verification", tags=["Authentication"])
def resend_verification(request: ResendVerificationRequest, db: Session = Depends(get_db)):
    user = get_user_by_email(db, request.email)
    if not user:
        raise HTTPException(404, "User not found")
    if user.is_email_verified:
        raise HTTPException(400, "Email already verified")

    new_code = generate_verification_code()
    user.email_verification_token = new_code
    user.email_verification_sent_at = datetime.utcnow()
    db.commit()

    try:
        send_verification_email(
            to_email=user.email,
            code=new_code,
            username=user.username
        )
        return {"message": "Verification code sent successfully"}
    except Exception as e:
        raise HTTPException(500, f"Failed to send email: {str(e)}")


@app.put("/auth/profile", response_model=UserResponse, tags=["Authentication"])
def update_profile(
    update_data: ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        if update_data.email and update_data.email != current_user.email:
            existing = db.query(User).filter(
                User.email == update_data.email
            ).first()
            if existing:
                raise HTTPException(400, "Email already in use")

        if update_data.username:
            current_user.username = update_data.username

        if update_data.email:
            current_user.email = update_data.email
            current_user.is_email_verified = False

        current_user.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(current_user)

        return current_user

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(500, f"Failed to update profile: {str(e)}")


@app.delete("/auth/delete-account", tags=["Authentication"])
def delete_account(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        db.delete(current_user)
        db.commit()
        return {"message": "Account deleted successfully"}
    except Exception as e:
        db.rollback()
        raise HTTPException(500, f"Failed to delete account: {str(e)}")

# ========================================
# FEEDBACK
# ========================================

@app.post("/feedbacks", response_model=FeedbackResponse, tags=["Feedback"])
def create_feedback(
    feedback: FeedbackCreate,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_user),
):
    new_feedback = Feedback(
        user_id=current_user.id if current_user else None,
        username=current_user.username if current_user else "Anonyme",
        rating=feedback.rating,
        comment=feedback.comment,
        category=feedback.category or "general",
        status="pending",
    )
    db.add(new_feedback)
    db.commit()
    db.refresh(new_feedback)
    return new_feedback


@app.get("/feedbacks", response_model=List[FeedbackResponse], tags=["Feedback"])
def get_all_feedbacks(db: Session = Depends(get_db)):
    feedbacks = db.query(Feedback).order_by(Feedback.created_at.desc()).all()
    result = []
    for f in feedbacks:
        result.append({
            "id":         f.id,
            "user_id":    f.user_id,
            "username":   f.username or "Anonyme",
            "rating":     f.rating,
            "comment":    f.comment,
            "category":   f.category,
            "status":     f.status,
            "created_at": f.created_at,
        })
    return result


@app.get("/feedbacks/stats", tags=["Feedback"])
def get_feedback_stats(db: Session = Depends(get_db)):
    total = db.query(Feedback).count()
    if total == 0:
        return {
            "total": 0,
            "average_rating": 0,
            "rating_distribution": {str(i): 0 for i in range(1, 6)}
        }

    avg_rating = db.query(func.avg(Feedback.rating)).scalar() or 0
    distribution = {
        str(i): db.query(Feedback).filter(Feedback.rating == i).count()
        for i in range(1, 6)
    }

    return {
        "total": total,
        "average_rating": round(avg_rating, 1),
        "rating_distribution": distribution
    }

# ========================================
# FAVORIS
# ========================================

@app.post("/favoris", response_model=FavorisResponse, tags=["Favoris"])
def add_favoris_endpoint(
    fav: FavorisCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    favoris = add_favoris(db, current_user.id, fav.monument_id)
    return favoris


@app.get("/favoris", response_model=List[FavorisResponse], tags=["Favoris"])
def get_favoris_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return get_user_favoris(db, current_user.id)


@app.delete("/favoris/{monument_id}", tags=["Favoris"])
def delete_favoris_endpoint(
    monument_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    success = delete_favoris(db, current_user.id, monument_id)
    if not success:
        raise HTTPException(404, "Favoris not found")
    return {"message": "Favoris deleted successfully"}

# ========================================
# COMMENTAIRES
# ========================================

@app.post("/commentaires", response_model=CommentaireResponse, tags=["Commentaires"])
def add_comment_endpoint(
    comment: CommentaireCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_comment = Commentaire(
        user_id=current_user.id,
        monument_id=comment.monument_id,
        texte=comment.texte,
        username=current_user.username,  # ✅ snapshot
    )
    db.add(new_comment)
    db.commit()
    db.refresh(new_comment)
    return new_comment


@app.get("/commentaires/monument/{monument_id}", response_model=List[CommentaireResponse], tags=["Commentaires"])
def get_monument_comments(monument_id: int, db: Session = Depends(get_db)):
    # ✅ Query directe — PAS get_comments_by_monument qui retourne des dicts
    comments = db.query(Commentaire).filter(
        Commentaire.monument_id == monument_id
    ).order_by(Commentaire.created_at.desc()).all()
    result = []
    for c in comments:
        result.append({
            "id":          c.id,
            "user_id":     c.user_id,
            "monument_id": c.monument_id,
            "texte":       c.texte,
            "username":    c.username or "Anonyme",  # ✅ snapshot
            "created_at":  c.created_at,
        })
    return result


@app.delete("/commentaires/{comment_id}", tags=["Commentaires"])
def delete_comment_endpoint(
    comment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    comment = db.query(Commentaire).filter(Commentaire.id == comment_id).first()
    if not comment:
        raise HTTPException(404, "Commentaire not found")
    if comment.user_id != current_user.id:
        raise HTTPException(403, "Not authorized to delete this comment")

    db.delete(comment)
    db.commit()
    return {"message": "Commentaire deleted successfully"}

# ========================================
# SYSTÈME
# ========================================

@app.get("/", tags=["System"])
def root():
    return {
        "message":  "TravelSpeek API ✅",
        "version":  "6.1.0",
        "docs":     "/docs",
        "languages": ["fr", "en", "ar", "es"],
        "monuments": 120,
    }


@app.get("/health", tags=["System"])
def health_check():
    return {
        "status":    "healthy",
        "timestamp": datetime.utcnow().isoformat(),
    }

# ========================================
# LANCEMENT
# ========================================

if __name__ == "__main__":
    import uvicorn
    print("=" * 60)
    print("🚀 TravelSpeek API v6.1.0")
    print(f"📝 Docs : http://100.81.116.14:8000/docs")
    print("=" * 60)
    uvicorn.run(app, host="0.0.0.0", port=8000)