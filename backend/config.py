import os

# Configuration sécurité
SECRET_KEY = "SUPER_SECRET_CHANGE_ME"
ALGORITHM = "HS256"

# Tokens
ACCESS_TOKEN_EXPIRE_MINUTES = 60
REFRESH_TOKEN_EXPIRE_DAYS = 7

# ✅ CORRECTION : Chemin absolu vers la base de données
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE_URL = f"sqlite:///{os.path.join(BASE_DIR, 'travelspeek.db')}"

# Pour debug : afficher le chemin utilisé
print(f"Base de données : {DATABASE_URL}")