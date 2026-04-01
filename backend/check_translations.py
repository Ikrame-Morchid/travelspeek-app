"""
Script pour vérifier les traductions - VERSION CORRIGÉE
"""
import sqlite3
import os

print("\n" + "="*70)
print("RECHERCHE DES BASES DE DONNÉES")
print("="*70 + "\n")

# Chemins possibles
possible_dbs = [
    r'C:\Users\HP\travelspeek_app\backend\travelspeek.db',
    r'C:\Users\HP\travelspeek_app\backend\travel_speak.db',
    r'C:\Users\HP\travelspeek_app\backend\monuments.db',
]

found_db = None
for db_path in possible_dbs:
    if os.path.exists(db_path):
        print(f"Base trouvée: {db_path}")
        found_db = db_path
        break

if not found_db:
    print("Aucune base de données trouvée!")
    print("\nVérifiez les fichiers dans votre dossier backend.")
    exit(1)

print(f"\n Analyse de: {found_db}")
print("="*70)

# Connexion
conn = sqlite3.connect(found_db)
cursor = conn.cursor()

# Vérifier si la table 'monuments' existe
cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='monuments'")
if not cursor.fetchone():
    print("\n Table 'monuments' introuvable dans cette base!")
    print("\n Peut-être que les monuments sont dans l'autre fichier .db")
    conn.close()
    
    # Essayer l'autre base
    if 'travelspeek.db' in found_db:
        other_db = found_db.replace('travelspeek.db', 'monuments.db')
    else:
        other_db = found_db.replace('monuments.db', 'travelspeek.db')
    
    if os.path.exists(other_db):
        print(f"\n Tentative avec: {other_db}")
        found_db = other_db
        conn = sqlite3.connect(found_db)
        cursor = conn.cursor()
    else:
        exit(1)

print("\n STRUCTURE DE LA TABLE 'monuments':")
print("-" * 70)
cursor.execute("PRAGMA table_info(monuments)")
columns = cursor.fetchall()

column_names = []
for col in columns:
    column_names.append(col[1])
    print(f"  ✓ {col[1]:20s} ({col[2]})")

# Vérifier les colonnes de traduction
print("\n COLONNES DE TRADUCTION:")
print("-" * 70)

has_fr = 'description_fr' in column_names
has_en = 'description_en' in column_names
has_ar = 'description_ar' in column_names
has_es = 'description_es' in column_names

print(f"  description_fr : {'EXISTE' if has_fr else 'MANQUANTE'}")
print(f"  description_en : {'EXISTE' if has_en else 'MANQUANTE'}")
print(f"  description_ar : {'EXISTE' if has_ar else 'MANQUANTE'}")
print(f"  description_es : {'EXISTE' if has_es else 'MANQUANTE'}")

# Compter les monuments
cursor.execute("SELECT COUNT(*) FROM monuments")
total = cursor.fetchone()[0]

print(f"\nSTATISTIQUES:")
print("-" * 70)
print(f"  Total monuments : {total}")

# Compter les traductions
if has_fr:
    cursor.execute("SELECT COUNT(*) FROM monuments WHERE description_fr IS NOT NULL AND description_fr != ''")
    fr_count = cursor.fetchone()[0]
    print(f"  Avec texte FR   : {fr_count}/{total}")

if has_en:
    cursor.execute("SELECT COUNT(*) FROM monuments WHERE description_en IS NOT NULL AND description_en != ''")
    en_count = cursor.fetchone()[0]
    print(f"  Avec texte EN   : {en_count}/{total}")

if has_ar:
    cursor.execute("SELECT COUNT(*) FROM monuments WHERE description_ar IS NOT NULL AND description_ar != ''")
    ar_count = cursor.fetchone()[0]
    print(f"  Avec texte AR   : {ar_count}/{total}")

if has_es:
    cursor.execute("SELECT COUNT(*) FROM monuments WHERE description_es IS NOT NULL AND description_es != ''")
    es_count = cursor.fetchone()[0]
    print(f"  Avec texte ES   : {es_count}/{total}")

# Montrer un exemple
print(f"\n EXEMPLE (Monument ID=1):")
print("-" * 70)

cursor.execute("SELECT nom FROM monuments WHERE id=1")
nom = cursor.fetchone()
if nom:
    print(f"  Nom: {nom[0]}")

if has_fr:
    cursor.execute("SELECT description_fr FROM monuments WHERE id=1")
    desc = cursor.fetchone()
    if desc and desc[0]:
        print(f"  FR : {desc[0][:80]}...")
    else:
        print(f"  FR : VIDE")

if has_en:
    cursor.execute("SELECT description_en FROM monuments WHERE id=1")
    desc = cursor.fetchone()
    if desc and desc[0]:
        print(f"  EN : {desc[0][:80]}...")
    else:
        print(f"  EN : VIDE")

if has_ar:
    cursor.execute("SELECT description_ar FROM monuments WHERE id=1")
    desc = cursor.fetchone()
    if desc and desc[0]:
        print(f"  AR : {desc[0][:80]}...")
    else:
        print(f"  AR : VIDE")

if has_es:
    cursor.execute("SELECT description_es FROM monuments WHERE id=1")
    desc = cursor.fetchone()
    if desc and desc[0]:
        print(f"  ES : {desc[0][:80]}...")
    else:
        print(f"  ES : VIDE")

conn.close()

# Diagnostic final
print("\n" + "="*70)
print("DIAGNOSTIC:")
print("="*70)

if not (has_fr and has_en and has_ar and has_es):
    print("\n PROBLÈME: Les colonnes de traduction manquent!")
    print("\n SOLUTION:")
    print("   1. Téléchargez: create_translations_table.py")
    print("   2. Modifiez le chemin de la base dedans:")
    print(f"      DB_PATH = r'{found_db}'")
    print("   3. Lancez: python create_translations_table.py")
elif has_ar and ar_count == 0:
    print("\n PROBLÈME: Les colonnes existent mais sont VIDES!")
    print("\n SOLUTION:")
    print("   1. pip install deep-translator")
    print("   2. Téléchargez: translate_monuments_script.py")
    print("   3. Modifiez le chemin de la base dedans:")
    print(f"      DB_PATH = r'{found_db}'")
    print("   4. Lancez: python translate_monuments_script.py")
    print("      (Durée: 10-15 minutes)")
else:
    print("\n TOUT EST OK! Les traductions sont présentes!")
    print("\n Vous pouvez maintenant:")
    print("   - Tester l'API: http://100.81.116.14:8000/monuments?lang=ar")
    print("   - Les descriptions devraient être en arabe!")

print("="*70 + "\n")