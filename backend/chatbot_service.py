"""
CHATBOT SERVICE — TravelSpeak
Groq (llama3) + Open-Meteo + OpenStreetMap + Wikipedia + Wikidata + data.json
+ Rate limiting + Cache local + Prompt système avancé
"""

import json, logging, re, os, time, sqlite3
from pathlib import Path
from typing import Optional
from datetime import datetime, date
import httpx
import wikipediaapi
from groq import Groq
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger(__name__)

# ════════════════════════════════════════════════════════
# CONFIGURATION
# ════════════════════════════════════════════════════════

GROQ_API_KEY  = os.getenv("GROQ_API_KEY", "")
GROQ_MODEL    = "llama-3.1-8b-instant"  #  modèle actif

# Limites
MAX_MESSAGE_LENGTH  = 500    # caractères max par message
MAX_REQUESTS_PER_DAY = 50   # requêtes max par utilisateur/jour
MAX_HISTORY_MESSAGES = 10   # messages gardés en contexte

# Chemins
JSON_PATH  = Path(__file__).parent / "data.json"  # même dossier que les .py
CACHE_DB   = Path(__file__).parent / "chatbot_cache.db"
LIMITS_DB  = Path(__file__).parent / "chatbot_limits.db"

# ════════════════════════════════════════════════════════
# SYSTEM PROMPT — Trilingue, structuré, touristique
# ════════════════════════════════════════════════════════

SYSTEM_PROMPT = """You are TravelBot, an expert tourist guide assistant for the TravelSpeak app, specialized in Morocco and international travel.

═══════════════════════════════════════════
LANGUAGE RULE — CRITICAL
═══════════════════════════════════════════
• Detect the language of the user's message AUTOMATICALLY
• ALWAYS respond in the EXACT SAME language as the user
• Arabic message  → respond in Arabic (العربية)
• French message  → respond in French (Français)
• English message → respond in English
• Mixed message   → use the dominant language
• NEVER switch language mid-response

═══════════════════════════════════════════
RESPONSE STRUCTURE
═══════════════════════════════════════════
For MONUMENTS / PLACES:
  [Name]
  Location: [city, region]
  istory: [2-3 sentences]
  Why visit: [key highlights]
  Practical tip: [opening hours, best time, etc.]

For WEATHER:
  Weather in [city]
  Temperature: X°C
  Conditions: [description]
 Advice: [what to wear/bring]

For LOCATION:
  [Place name]
  Coordinates provided
  How to get there: [brief tip]

For GENERAL QUESTIONS:
  Answer clearly in 3-5 sentences maximum
  Use bullet points for lists
  Always end with a helpful travel tip

═══════════════════════════════════════════
BEHAVIOR RULES
═══════════════════════════════════════════
Use ONLY the context data provided — never invent facts
If context has monument data → present it with the structure above
If context has weather data → present it clearly
Be warm, friendly, and enthusiastic like a local friend
Use relevant emojis to make responses lively
Keep responses concise (max 5-6 sentences for general questions)
NEVER invent monument names, dates, or historical facts
NEVER answer questions unrelated to tourism/travel/Morocco
NEVER translate place names — keep them in original language
"""

# ════════════════════════════════════════════════════════
# BASE DE DONNÉES — Cache + Rate Limiting
# ════════════════════════════════════════════════════════

def init_databases():
    """Initialise les bases SQLite pour cache et rate limiting."""
    # Cache Wikidata/Wikipedia
    with sqlite3.connect(CACHE_DB) as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS cache (
                query      TEXT PRIMARY KEY,
                data       TEXT NOT NULL,
                source     TEXT NOT NULL,
                created_at REAL NOT NULL
            )
        """)
        conn.commit()
    logger.info("Cache DB initialisée")

    # Rate limiting
    with sqlite3.connect(LIMITS_DB) as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS usage (
                user_id    TEXT NOT NULL,
                date       TEXT NOT NULL,
                count      INTEGER DEFAULT 0,
                PRIMARY KEY (user_id, date)
            )
        """)
        conn.commit()
    logger.info("Limits DB initialisée")

init_databases()

# ════════════════════════════════════════════════════════
# RATE LIMITING
# ════════════════════════════════════════════════════════

def check_rate_limit(user_id: str) -> dict:
    """
    Vérifie si l'utilisateur a dépassé sa limite quotidienne.
    Returns: {"allowed": bool, "count": int, "remaining": int, "reset_at": str}
    """
    today = date.today().isoformat()
    with sqlite3.connect(LIMITS_DB) as conn:
        row = conn.execute(
            "SELECT count FROM usage WHERE user_id=? AND date=?",
            (user_id, today)
        ).fetchone()
        count = row[0] if row else 0

    remaining = max(0, MAX_REQUESTS_PER_DAY - count)
    allowed   = count < MAX_REQUESTS_PER_DAY

    return {
        "allowed":   allowed,
        "count":     count,
        "remaining": remaining,
        "reset_at":  f"demain à 00:00",
        "limit":     MAX_REQUESTS_PER_DAY,
    }

def increment_usage(user_id: str):
    """Incrémente le compteur d'usage de l'utilisateur."""
    today = date.today().isoformat()
    with sqlite3.connect(LIMITS_DB) as conn:
        conn.execute("""
            INSERT INTO usage (user_id, date, count) VALUES (?, ?, 1)
            ON CONFLICT(user_id, date) DO UPDATE SET count = count + 1
        """, (user_id, today))
        conn.commit()

def validate_message(message: str) -> dict:
    """
    Valide le message de l'utilisateur.
    Returns: {"valid": bool, "error": str|None}
    """
    if not message.strip():
        return {"valid": False, "error": "Le message est vide."}
    if len(message) > MAX_MESSAGE_LENGTH:
        return {
            "valid": False,
            "error": f"Message trop long ({len(message)} caractères). "
                     f"Maximum autorisé : {MAX_MESSAGE_LENGTH} caractères."
        }
    return {"valid": True, "error": None}

# ════════════════════════════════════════════════════════
# CACHE LOCAL
# ════════════════════════════════════════════════════════

CACHE_TTL_SECONDS = 7 * 24 * 3600  # 7 jours

def cache_get(query: str) -> Optional[dict]:
    """Récupère une entrée du cache si elle existe et n'est pas expirée."""
    try:
        with sqlite3.connect(CACHE_DB) as conn:
            row = conn.execute(
                "SELECT data, source, created_at FROM cache WHERE query=?",
                (query.lower().strip(),)
            ).fetchone()
            if not row:
                return None
            data, source, created_at = row
            # Vérifier expiration
            if time.time() - created_at > CACHE_TTL_SECONDS:
                conn.execute("DELETE FROM cache WHERE query=?", (query.lower().strip(),))
                conn.commit()
                return None
            logger.info(f"Cache HIT : '{query[:40]}' (source: {source})")
            return {"data": json.loads(data), "source": source}
    except Exception as e:
        logger.warning(f"Cache GET erreur : {e}")
        return None

def cache_set(query: str, data: dict, source: str):
    """Sauvegarde une entrée dans le cache."""
    try:
        with sqlite3.connect(CACHE_DB) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO cache (query, data, source, created_at)
                VALUES (?, ?, ?, ?)
            """, (query.lower().strip(), json.dumps(data, ensure_ascii=False),
                  source, time.time()))
            conn.commit()
        logger.info(f"Cache SET : '{query[:40]}' (source: {source})")
    except Exception as e:
        logger.warning(f"Cache SET erreur : {e}")

# ════════════════════════════════════════════════════════
# JSON LOCAL — Monuments
# ════════════════════════════════════════════════════════

def load_monuments() -> list:
    try:
        with open(JSON_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        logger.info(f"{len(data)} monuments chargés depuis data.json")
        return data
    except FileNotFoundError:
        logger.warning(f"data.json non trouvé : {JSON_PATH}")
        return []
    except Exception as e:
        logger.error(f"Erreur data.json : {e}")
        return []

MONUMENTS = load_monuments()

def search_monument_local(query: str) -> Optional[dict]:
    """Cherche dans data.json par score de correspondance."""
    query_lower = query.lower()
    best, score = None, 0
    for m in MONUMENTS:
        nom   = m.get("NOM", "").lower()
        ville = m.get("VILLE", "").lower()
        desc  = m.get("DESCRIPTION", "").lower()
        s = 0
        if nom in query_lower or query_lower in nom: s += 10
        for word in query_lower.split():
            if len(word) > 3:
                if word in nom:   s += 5
                if word in ville: s += 3
                if word in desc:  s += 1
        if s > score:
            score, best = s, m
    return best if score >= 3 else None

def format_monument(m: dict) -> str:
    parts = []
    if m.get("NOM"):          parts.append(f"Monument: {m['NOM']}")
    if m.get("VILLE"):        parts.append(f"Ville: {m['VILLE']}")
    if m.get("DESCRIPTION"):  parts.append(f"Description: {m['DESCRIPTION']}")
    if m.get("LOCALISATION"): parts.append(f"Maps: {m['LOCALISATION']}")
    return "\n".join(parts)

# ════════════════════════════════════════════════════════
# WIKIDATA — Source structurée (fallback si JSON vide)
# ════════════════════════════════════════════════════════

async def search_wikidata(query: str, lang: str = "fr") -> Optional[dict]:
    """
    Cherche sur Wikidata via SPARQL si l'info n'est pas en local.
    Retourne données structurées : nom, description, coordonnées, image.
    Résultat mis en cache automatiquement.
    """
    # Vérifier cache d'abord
    cache_key = f"wikidata:{lang}:{query}"
    cached = cache_get(cache_key)
    if cached:
        return cached["data"]

    try:
        async with httpx.AsyncClient(timeout=15) as client:
            # Recherche entité Wikidata
            search_resp = await client.get(
                "https://www.wikidata.org/w/api.php",
                params={
                    "action":   "wbsearchentities",
                    "search":   query,
                    "language": lang,
                    "format":   "json",
                    "limit":    3,
                    "type":     "item",
                },
                headers={"User-Agent": "TravelSpeak/1.0"},
            )
            search_data = search_resp.json()
            results     = search_data.get("search", [])
            if not results:
                return None

            # Prendre le premier résultat
            entity_id = results[0]["id"]
            label     = results[0].get("label", query)
            desc      = results[0].get("description", "")

            # Récupérer détails de l'entité
            entity_resp = await client.get(
                f"https://www.wikidata.org/wiki/Special:EntityData/{entity_id}.json",
                headers={"User-Agent": "TravelSpeak/1.0"},
            )
            entity_data = entity_resp.json()
            entity      = entity_data.get("entities", {}).get(entity_id, {})
            claims      = entity.get("claims", {})

            # Extraire coordonnées (P625)
            coords = None
            if "P625" in claims:
                coord_data = claims["P625"][0].get("mainsnak", {}).get("datavalue", {}).get("value", {})
                if coord_data:
                    coords = {
                        "lat": coord_data.get("latitude"),
                        "lon": coord_data.get("longitude"),
                    }

            # Extraire image (P18)
            image_url = None
            if "P18" in claims:
                img_name = claims["P18"][0].get("mainsnak", {}).get("datavalue", {}).get("value", "")
                if img_name:
                    img_name  = img_name.replace(" ", "_")
                    image_url = f"https://commons.wikimedia.org/wiki/Special:FilePath/{img_name}?width=400"

            result = {
                "entity_id":   entity_id,
                "label":       label,
                "description": desc,
                "coords":      coords,
                "image_url":   image_url,
                "wikidata_url": f"https://www.wikidata.org/wiki/{entity_id}",
            }

            # Sauvegarder en cache
            cache_set(cache_key, result, "wikidata")
            logger.info(f"✅ Wikidata : '{label}' ({entity_id})")
            return result

    except Exception as e:
        logger.warning(f"⚠️ Wikidata erreur : {e}")
        return None

# ════════════════════════════════════════════════════════
# WIKIPEDIA — Résumé texte (complément Wikidata)
# ════════════════════════════════════════════════════════

def search_wikipedia(query: str, lang: str = "fr") -> Optional[str]:
    """Cherche sur Wikipedia, avec cache local."""
    cache_key = f"wikipedia:{lang}:{query}"
    cached = cache_get(cache_key)
    if cached:
        return cached["data"].get("summary")

    try:
        wiki = wikipediaapi.Wikipedia(language=lang, user_agent="TravelSpeak/1.0")
        page = wiki.page(query)
        if page.exists():
            summary = page.summary[:600]
            cache_set(cache_key, {"summary": summary}, "wikipedia")
            return summary
        # Fallback anglais
        if lang != "en":
            wiki_en = wikipediaapi.Wikipedia(language="en", user_agent="TravelSpeak/1.0")
            p2 = wiki_en.page(query)
            if p2.exists():
                summary = p2.summary[:600]
                cache_set(cache_key, {"summary": summary}, "wikipedia_en")
                return summary
        return None
    except Exception as e:
        logger.warning(f"⚠️ Wikipedia erreur : {e}")
        return None

# ════════════════════════════════════════════════════════
# OPEN-METEO — Météo sans clé API
# ════════════════════════════════════════════════════════

WEATHER_CODES = {
    0:  "Ciel dégagé ☀️",       1: "Principalement dégagé 🌤️",
    2:  "Partiellement nuageux ⛅", 3: "Couvert ☁️",
    45: "Brouillard 🌫️",        51: "Bruine légère 🌦️",
    61: "Pluie légère 🌧️",      63: "Pluie modérée 🌧️",
    65: "Pluie forte 🌧️",       80: "Averses 🌦️",
    95: "Orage ⛈️",
}

async def get_weather(city: str) -> Optional[dict]:
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            # Géocodage
            geo = await client.get(
                "https://nominatim.openstreetmap.org/search",
                params={"q": city, "format": "json", "limit": 1},
                headers={"User-Agent": "TravelSpeak/1.0"},
            )
            geo_data = geo.json()
            if not geo_data:
                return None
            lat  = float(geo_data[0]["lat"])
            lon  = float(geo_data[0]["lon"])
            name = geo_data[0].get("display_name", city).split(",")[0]
            # Météo
            wr = await client.get(
                "https://api.open-meteo.com/v1/forecast",
                params={
                    "latitude": lat, "longitude": lon,
                    "timezone": "auto",
                    "current":  "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code",
                },
            )
            w = wr.json().get("current", {})
            return {
                "city":        name,
                "temp":        round(w.get("temperature_2m", 0)),
                "humidity":    w.get("relative_humidity_2m", 0),
                "wind":        round(w.get("wind_speed_10m", 0)),
                "description": WEATHER_CODES.get(w.get("weather_code", 0), "🌡️"),
                "lat": lat, "lon": lon,
            }
    except Exception as e:
        logger.error(f"Météo : {e}")
        return None

# ════════════════════════════════════════════════════════
# OPENSTREETMAP — Localisation sans clé API
# ════════════════════════════════════════════════════════

async def get_location(place: str) -> Optional[dict]:
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(
                "https://nominatim.openstreetmap.org/search",
                params={"q": place, "format": "json", "limit": 1},
                headers={"User-Agent": "TravelSpeak/1.0"},
            )
            d = r.json()
            if not d:
                return None
            return {
                "place":    d[0].get("display_name", place),
                "lat":      float(d[0]["lat"]),
                "lon":      float(d[0]["lon"]),
                "maps_url": f"https://maps.google.com/?q={d[0]['lat']},{d[0]['lon']}",
            }
    except Exception as e:
        logger.error(f"Location : {e}")
        return None

# ════════════════════════════════════════════════════════
# DÉTECTION LANGUE + INTENTION
# ════════════════════════════════════════════════════════

def detect_lang(text: str) -> str:
    if len(re.findall(r'[\u0600-\u06FF]', text)) > 2:
        return "ar"
    fr_words = ["le","la","les","de","du","est","une","que",
                "comment","où","quel","quelle","parle","dis"]
    if any(w in text.lower().split() for w in fr_words):
        return "fr"
    return "en"

def detect_intent(msg: str) -> dict:
    m = msg.lower()
    weather_kw  = ["météo","meteo","temps","température","weather",
                   "chaud","froid","pluie","الطقس","درجة","مطر","il fait"]
    location_kw = ["où est","ou est","localisation","adresse","comment aller",
                   "where is","location","أين","موقع","عنوان","carte","map"]
    monument_kw = ["monument","musée","mosquée","palais","kasbah","médina",
                   "visiter","voir","plage","jardin","متحف","مسجد","قصبة","زيارة"]
    return {
        "weather":  any(k in m for k in weather_kw),
        "location": any(k in m for k in location_kw),
        "monument": any(k in m for k in monument_kw),
        "lang":     detect_lang(msg),
    }

# ════════════════════════════════════════════════════════
# GROQ — LLM Brain
# ════════════════════════════════════════════════════════

_groq_client = None

def get_groq() -> Groq:
    global _groq_client
    if _groq_client is None:
        if not GROQ_API_KEY:
            raise ValueError("GROQ_API_KEY manquante dans .env")
        _groq_client = Groq(api_key=GROQ_API_KEY)
        logger.info("Groq initialisé (llama3-8b-8192)")
    return _groq_client

def ask_groq(message: str, context: str = "", history: list = []) -> str:
    try:
        client   = get_groq()
        messages = [{"role": "system", "content": SYSTEM_PROMPT}]
        # Historique (max 10)
        for h in history[-MAX_HISTORY_MESSAGES:]:
            messages.append({"role": h["role"], "content": h["content"]})
        # Message avec contexte
        user_msg = message
        if context:
            user_msg = f"[CONTEXT DATA]\n{context}\n\n[USER QUESTION]\n{message}"
        messages.append({"role": "user", "content": user_msg})

        response = client.chat.completions.create(
            model=GROQ_MODEL, messages=messages,
            max_tokens=600, temperature=0.6,
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        logger.error(f"Groq : {e}")
        return "Désolé, une erreur est survenue. Veuillez réessayer."

# ════════════════════════════════════════════════════════
# PIPELINE PRINCIPAL
# ════════════════════════════════════════════════════════

async def process_message(
    message:  str,
    city:     Optional[str] = None,
    history:  list = [],
    user_id:  str  = "default",
) -> dict:
    """
    Pipeline complet avec rate limiting, validation, cache :

    1. Valider message (longueur)
    2. Vérifier rate limit (quota journalier)
    3. Chercher dans data.json LOCAL
    4. Si absent → Wikidata (structuré) + Wikipedia (texte)
    5. Si météo → Open-Meteo
    6. Si localisation → OpenStreetMap
    7. Groq formate la réponse avec le contexte assemblé
    8. Incrémenter compteur d'usage
    """
    # ── 1. Validation message ──────────────────────────────
    validation = validate_message(message)
    if not validation["valid"]:
        return {
            "reply":    f"⚠️ {validation['error']}",
            "error":    "validation",
            "weather":  None, "location": None,
            "monument": None, "source":   "error",
        }

    # ── 2. Rate limiting ───────────────────────────────────
    limit_info = check_rate_limit(user_id)
    if not limit_info["allowed"]:
        lang = detect_lang(message)
        if lang == "ar":
            msg = (f"لقد وصلت إلى الحد اليومي ({MAX_REQUESTS_PER_DAY} رسالة). "
                   f"يرجى الانتظار حتى {limit_info['reset_at']}.")
        elif lang == "fr":
            msg = (f"Vous avez atteint la limite quotidienne "
                   f"({MAX_REQUESTS_PER_DAY} messages/jour). "
                   f"Réessayez {limit_info['reset_at']}.")
        else:
            msg = (f"Daily limit reached ({MAX_REQUESTS_PER_DAY} messages/day). "
                   f"Please try again {limit_info['reset_at']}.")
        return {
            "reply":      msg,
            "error":      "rate_limit",
            "rate_limit": limit_info,
            "weather":    None, "location": None,
            "monument":   None, "source":   "rate_limit",
        }

    logger.info(f"[{user_id}] '{message[:60]}' | usage: {limit_info['count']}/{MAX_REQUESTS_PER_DAY}")

    intent   = detect_intent(message)
    context  = []
    weather  = None
    location = None
    monument = None
    source   = "groq"

    # ── 3. Chercher dans data.json LOCAL ───────────────────
    monument = search_monument_local(message)
    if monument:
        context.append("=== MONUMENT (source: data.json local) ===")
        context.append(format_monument(monument))
        source = "json"
        logger.info(f"✅ JSON local : {monument.get('NOM')}")

    # ── 4. Wikidata + Wikipedia si absent du JSON ──────────
    if not monument:
        # Wikidata (données structurées)
        wikidata = await search_wikidata(message, lang=intent["lang"])
        if wikidata:
            context.append("=== INFO WIKIDATA (structurée) ===")
            context.append(f"Nom: {wikidata['label']}")
            context.append(f"Description: {wikidata['description']}")
            if wikidata.get("coords"):
                context.append(
                    f"Coordonnées: {wikidata['coords']['lat']}, {wikidata['coords']['lon']}")
            source = "wikidata"
            logger.info(f"Wikidata : {wikidata['label']}")

        # Wikipedia (résumé texte complémentaire)
        wiki_text = search_wikipedia(message, lang=intent["lang"])
        if wiki_text:
            context.append("=== INFO WIKIPEDIA ===")
            context.append(wiki_text)
            if source == "groq":
                source = "wikipedia"

    # ── 5. Météo ───────────────────────────────────────────
    if intent["weather"] and city:
        weather = await get_weather(city)
        if weather:
            context.append(f"=== MÉTÉO {weather['city'].upper()} ===")
            context.append(
                f"Température: {weather['temp']}°C | {weather['description']} | "
                f"Humidité: {weather['humidity']}% | Vent: {weather['wind']} km/h"
            )
            logger.info(f"🌤️ Météo : {weather['city']} {weather['temp']}°C")

    # ── 6. Localisation ────────────────────────────────────
    if intent["location"]:
        place = monument.get("NOM") if monument else city
        if place:
            if monument and monument.get("LOCALISATION"):
                location = {
                    "place":    monument.get("NOM", place),
                    "maps_url": monument["LOCALISATION"],
                    "source":   "json",
                }
            else:
                location = await get_location(place)
            if location:
                context.append(f"=== LOCALISATION : {location.get('maps_url', '')}")
                logger.info(f"Location : {location.get('place', '')[:40]}")

    # ── 7. Groq formate la réponse ─────────────────────────
    reply = ask_groq(message, context="\n".join(context), history=history)

    # ── 8. Incrémenter usage ───────────────────────────────
    increment_usage(user_id)
    updated_limit = check_rate_limit(user_id)
    logger.info(f"Réponse (source: {source}) | remaining: {updated_limit['remaining']}")

    return {
        "reply":      reply,
        "weather":    weather,
        "location":   location,
        "monument":   monument,
        "source":     source,
        "rate_limit": updated_limit,
    }