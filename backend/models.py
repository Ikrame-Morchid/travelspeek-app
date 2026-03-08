# ========================================
# backend/models.py
# ========================================

from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, JSON, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base


class User(Base):
    __tablename__ = "users"

    id                        = Column(Integer, primary_key=True, index=True)
    username                  = Column(String, unique=False, index=True, nullable=False)
    email                     = Column(String, unique=True, index=True, nullable=False)
    password_hash             = Column(String, nullable=False)
    is_email_verified         = Column(Boolean, default=False)
    email_verification_token  = Column(String, nullable=True)
    email_verification_sent_at= Column(DateTime, nullable=True)
    refresh_token             = Column(String, nullable=True)
    created_at                = Column(DateTime, default=datetime.utcnow)
    updated_at                = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login                = Column(DateTime, nullable=True)

    favoris      = relationship("Favoris",      back_populates="user", cascade="all, delete")
    commentaires = relationship("Commentaire",  back_populates="user", cascade="all, delete")
    translations = relationship("Translation",  back_populates="user", cascade="all, delete")
    messages     = relationship("Message",      back_populates="user", cascade="all, delete")
    searches     = relationship("Search",       back_populates="user", cascade="all, delete")
    feedbacks    = relationship("Feedback",     back_populates="user", cascade="all, delete")


class Translation(Base):
    __tablename__ = "translations"

    id                   = Column(Integer, primary_key=True)
    user_id              = Column(Integer, ForeignKey("users.id"))
    source_text          = Column(String, nullable=False)
    translated_text      = Column(String, nullable=False)
    source_language      = Column(String, nullable=False)
    target_language      = Column(String, nullable=False)
    type                 = Column(String, nullable=False)
    has_offensive_content= Column(Boolean, default=False)
    created_at           = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="translations")


class Message(Base):
    __tablename__ = "messages"

    id              = Column(Integer, primary_key=True)
    user_id         = Column(Integer, ForeignKey("users.id"))
    role            = Column(String, nullable=False)
    content         = Column(String, nullable=False)
    conversation_id = Column(String, nullable=True)
    created_at      = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="messages")


class Search(Base):
    __tablename__ = "searches"

    id           = Column(Integer, primary_key=True)
    user_id      = Column(Integer, ForeignKey("users.id"))
    query        = Column(String, nullable=False)
    result_count = Column(Integer, default=0)
    created_at   = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="searches")


class Monument(Base):
    __tablename__ = "monuments"

    id             = Column(Integer, primary_key=True)
    nom            = Column(String, index=True)
    ville          = Column(String, index=True)
    description    = Column(Text)
    localisation   = Column(String)
    images         = Column(JSON)
    description_fr = Column(Text)
    description_en = Column(Text)
    description_ar = Column(Text)
    description_es = Column(Text)
    nom_en         = Column(String)
    nom_ar         = Column(String)
    nom_es         = Column(String)
    ville_en       = Column(String)
    ville_ar       = Column(String)
    ville_es       = Column(String)

    favoris      = relationship("Favoris",     back_populates="monument", cascade="all, delete")
    commentaires = relationship("Commentaire", back_populates="monument", cascade="all, delete")


class Favoris(Base):
    __tablename__ = "favoris"

    id          = Column(Integer, primary_key=True)
    user_id     = Column(Integer, ForeignKey("users.id"))
    monument_id = Column(Integer, ForeignKey("monuments.id"))
    created_at  = Column(DateTime, default=datetime.utcnow)

    user     = relationship("User",     back_populates="favoris")
    monument = relationship("Monument", back_populates="favoris")


class Commentaire(Base):
    __tablename__ = "commentaires"

    id          = Column(Integer, primary_key=True)
    user_id     = Column(Integer, ForeignKey("users.id"))
    monument_id = Column(Integer, ForeignKey("monuments.id"))
    texte       = Column(String)
    username    = Column(String, nullable=True)  # ✅ snapshot
    created_at  = Column(DateTime, default=datetime.utcnow)

    user     = relationship("User",     back_populates="commentaires")
    monument = relationship("Monument", back_populates="commentaires")


class Feedback(Base):
    __tablename__ = "feedback"

    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id"), nullable=True)
    username   = Column(String, nullable=True)  # ✅ snapshot
    rating     = Column(Integer, nullable=False)
    comment    = Column(Text, nullable=True)
    category   = Column(String, default="general")
    status     = Column(String, default="pending")
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="feedbacks")