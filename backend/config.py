import os

# Configuration sécurité
SECRET_KEY = os.getenv("SECRET_KEY", "SUPER_SECRET_CHANGE_ME")
ALGORITHM = "HS256"

# Tokens
ACCESS_TOKEN_EXPIRE_MINUTES = 60
REFRESH_TOKEN_EXPIRE_DAYS = 7

# ✅ Base de données :
# - En local      → backend/travelspeek.db
# - Sur Render    → /data/travelspeek.db (disque persistant)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_DIR = "/data" if os.path.exists("/data") else BASE_DIR
DATABASE_URL = f"sqlite:///{os.path.join(DB_DIR, 'travelspeek.db')}"

print(f"📁 Base de données : {DATABASE_URL}")