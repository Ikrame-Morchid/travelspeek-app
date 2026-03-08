# ========================================
# backend/crud.py
# ========================================

from sqlalchemy.orm import Session
from sqlalchemy import or_
from datetime import datetime
import secrets
from models import User, Monument, Favoris, Commentaire, Translation, Message, Search
from security import hash_password, verify_password

# ========================================
# 🔹 USERS
# ========================================

def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def get_user_by_username(db: Session, username: str):
    return db.query(User).filter(User.username == username).first()

def get_user_by_id(db: Session, user_id: int):
    return db.query(User).filter(User.id == user_id).first()

def create_user(db: Session, username: str, email: str, password: str):
    user = User(
        username=username,
        email=email,
        password_hash=hash_password(password),
        is_email_verified=False,
        email_verification_token=secrets.token_urlsafe(32),
        email_verification_sent_at=datetime.utcnow()
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

def authenticate_user(db: Session, email: str, password: str):
    # ✅ Chercher par email OU username
    user = db.query(User).filter(
        or_(User.email == email, User.username == email)
    ).first()

    if not user or not verify_password(password, user.password_hash):
        return None
    
    user.last_login = datetime.utcnow()
    db.commit()
    
    return user

def verify_user_email(db: Session, token: str):
    user = db.query(User).filter(User.email_verification_token == token).first()
    if user:
        user.is_email_verified = True
        user.email_verification_token = None
        db.commit()
        return user
    return None

def update_user(db: Session, user_id: int, **kwargs):
    user = get_user_by_id(db, user_id)
    if user:
        for key, value in kwargs.items():
            if hasattr(user, key):
                setattr(user, key, value)
        user.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(user)
    return user


# ========================================
# 🔹 MONUMENTS
# ========================================

def get_all_monuments(db: Session):
    return db.query(Monument).all()

def get_monument_by_id(db: Session, monument_id: int):
    return db.query(Monument).filter(Monument.id == monument_id).first()

def search_monuments(db: Session, query: str):
    return db.query(Monument).filter(
        Monument.nom.ilike(f'%{query}%') | 
        Monument.ville.ilike(f'%{query}%') |
        Monument.description.ilike(f'%{query}%')
    ).all()


# ========================================
# 🔹 FAVORIS
# ========================================

def add_favoris(db: Session, user_id: int, monument_id: int):
    existing = db.query(Favoris).filter_by(
        user_id=user_id,
        monument_id=monument_id
    ).first()
    
    if existing:
        return existing
    
    fav = Favoris(user_id=user_id, monument_id=monument_id)
    db.add(fav)
    db.commit()
    db.refresh(fav)
    return fav

def get_user_favoris(db: Session, user_id: int):
    return db.query(Favoris).filter(Favoris.user_id == user_id).all()

def delete_favoris(db: Session, user_id: int, monument_id: int):
    fav = db.query(Favoris).filter_by(
        user_id=user_id,
        monument_id=monument_id
    ).first()
    if fav:
        db.delete(fav)
        db.commit()
        return True
    return False

def is_favorite(db: Session, user_id: int, monument_id: int):
    return db.query(Favoris).filter_by(
        user_id=user_id,
        monument_id=monument_id
    ).first() is not None


# ========================================
# 🔹 COMMENTAIRES
# ========================================

def add_commentaire(db: Session, user_id: int, monument_id: int, texte: str):
    comment = Commentaire(
        user_id=user_id,
        monument_id=monument_id,
        texte=texte
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)
    
    return {
        'id': comment.id,
        'user_id': comment.user_id,
        'monument_id': comment.monument_id,
        'texte': comment.texte,
        'created_at': comment.created_at,
        'username': comment.user.username if comment.user else 'Utilisateur',
        'user_email': comment.user.email if comment.user else None,
        'user_avatar': None,
    }

def get_comments_by_monument(db: Session, monument_id: int):
    comments = db.query(Commentaire).filter(
        Commentaire.monument_id == monument_id
    ).order_by(Commentaire.created_at.desc()).all()
    
    result = []
    for comment in comments:
        result.append({
            'id': comment.id,
            'user_id': comment.user_id,
            'monument_id': comment.monument_id,
            'texte': comment.texte,
            'created_at': comment.created_at,
            'username': comment.user.username if comment.user else 'Utilisateur',
            'user_email': comment.user.email if comment.user else None,
            'user_avatar': None,
        })
    
    return result

def get_user_comments(db: Session, user_id: int):
    comments = db.query(Commentaire).filter(
        Commentaire.user_id == user_id
    ).order_by(Commentaire.created_at.desc()).all()
    
    result = []
    for comment in comments:
        result.append({
            'id': comment.id,
            'user_id': comment.user_id,
            'monument_id': comment.monument_id,
            'texte': comment.texte,
            'created_at': comment.created_at,
            'username': comment.user.username if comment.user else 'Utilisateur',
            'user_email': comment.user.email if comment.user else None,
            'user_avatar': None,
        })
    
    return result

def delete_commentaire(db: Session, comment_id: int, user_id: int):
    comment = db.query(Commentaire).filter_by(
        id=comment_id,
        user_id=user_id
    ).first()
    if comment:
        db.delete(comment)
        db.commit()
        return True
    return False


# ========================================
# 🔹 TRANSLATIONS
# ========================================

def add_translation(
    db: Session,
    user_id: int,
    source_text: str,
    translated_text: str,
    source_language: str,
    target_language: str,
    type: str = 'text',
    has_offensive_content: bool = False
):
    translation = Translation(
        user_id=user_id,
        source_text=source_text,
        translated_text=translated_text,
        source_language=source_language,
        target_language=target_language,
        type=type,
        has_offensive_content=has_offensive_content
    )
    db.add(translation)
    db.commit()
    db.refresh(translation)
    return translation

def get_user_translations(db: Session, user_id: int, limit: int = 50):
    return db.query(Translation).filter(
        Translation.user_id == user_id
    ).order_by(Translation.created_at.desc()).limit(limit).all()

def delete_translation(db: Session, translation_id: int, user_id: int):
    translation = db.query(Translation).filter_by(
        id=translation_id,
        user_id=user_id
    ).first()
    if translation:
        db.delete(translation)
        db.commit()
        return True
    return False


# ========================================
# 🔹 MESSAGES (ChatBot)
# ========================================

def add_message(
    db: Session,
    user_id: int,
    role: str,
    content: str,
    conversation_id: str = None
):
    message = Message(
        user_id=user_id,
        role=role,
        content=content,
        conversation_id=conversation_id
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    return message

def get_user_messages(db: Session, user_id: int, conversation_id: str = None):
    query = db.query(Message).filter(Message.user_id == user_id)
    
    if conversation_id:
        query = query.filter(Message.conversation_id == conversation_id)
    
    return query.order_by(Message.created_at.asc()).all()

def get_conversations(db: Session, user_id: int):
    conversations = db.query(Message.conversation_id).filter(
        Message.user_id == user_id,
        Message.conversation_id.isnot(None)
    ).distinct().all()
    
    return [conv[0] for conv in conversations]


# ========================================
# 🔹 SEARCHES
# ========================================

def add_search(db: Session, user_id: int, query: str, result_count: int = 0):
    search = Search(
        user_id=user_id,
        query=query,
        result_count=result_count
    )
    db.add(search)
    db.commit()
    db.refresh(search)
    return search

def get_user_searches(db: Session, user_id: int, limit: int = 50):
    return db.query(Search).filter(
        Search.user_id == user_id
    ).order_by(Search.created_at.desc()).limit(limit).all()

def get_search_statistics(db: Session, user_id: int):
    total_searches = db.query(Search).filter(Search.user_id == user_id).count()
    
    popular_searches = db.query(
        Search.query,
        db.func.count(Search.id).label('count')
    ).filter(
        Search.user_id == user_id
    ).group_by(Search.query).order_by(
        db.func.count(Search.id).desc()
    ).limit(10).all()
    
    return {
        'total': total_searches,
        'popular': [{'query': q, 'count': c} for q, c in popular_searches]
    }


# ========================================
# 🔹 HISTORIQUE
# ========================================

def get_user_history(db: Session, user_id: int):
    history = {
        'translations': get_user_translations(db, user_id, limit=20),
        'searches': get_user_searches(db, user_id, limit=20),
        'comments': get_user_comments(db, user_id),
        'favoris': get_user_favoris(db, user_id),
    }
    return history