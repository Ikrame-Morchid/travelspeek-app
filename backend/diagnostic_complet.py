"""
Diagnostic complet - Trouvons le problème exact
"""
import sqlite3

DB_PATH = r'C:\Users\HP\travelspeek_app\backend\travelspeek.db'

print("\n" + "="*80)
print(" DIAGNOSTIC COMPLET - SYSTÈME MULTILINGUE")
print("="*80)

conn = sqlite3.connect(DB_PATH)
cursor = conn.cursor()

# ========================================
# TEST 1: Structure de la base
# ========================================
print("\n TEST 1: STRUCTURE DE LA TABLE")
print("-"*80)

cursor.execute("PRAGMA table_info(monuments)")
columns = [col[1] for col in cursor.fetchall()]

print(f"Colonnes trouvées: {', '.join(columns)}")

has_desc_fr = 'description_fr' in columns
has_desc_en = 'description_en' in columns
has_desc_ar = 'description_ar' in columns
has_desc_es = 'description_es' in columns

print(f"\n✓ description_fr: {'' if has_desc_fr else ''}")
print(f"✓ description_en: {'' if has_desc_en else ''}")
print(f"✓ description_ar: {'' if has_desc_ar else ''}")
print(f"✓ description_es: {'' if has_desc_es else ''}")

# ========================================
# TEST 2: Contenu de la base
# ========================================
print("\n TEST 2: CONTENU DES TRADUCTIONS")
print("-"*80)

cursor.execute("SELECT COUNT(*) FROM monuments")
total = cursor.fetchone()[0]
print(f"Total monuments: {total}")

if has_desc_fr:
    cursor.execute("SELECT COUNT(*) FROM monuments WHERE description_fr IS NOT NULL AND description_fr != ''")
    print(f"  FR remplis: {cursor.fetchone()[0]}/{total}")

if has_desc_en:
    cursor.execute("SELECT COUNT(*) FROM monuments WHERE description_en IS NOT NULL AND description_en != ''")
    count_en = cursor.fetchone()[0]
    print(f"  EN remplis: {count_en}/{total}")
else:
    count_en = 0

if has_desc_ar:
    cursor.execute("SELECT COUNT(*) FROM monuments WHERE description_ar IS NOT NULL AND description_ar != ''")
    count_ar = cursor.fetchone()[0]
    print(f"  AR remplis: {count_ar}/{total}")
else:
    count_ar = 0

if has_desc_es:
    cursor.execute("SELECT COUNT(*) FROM monuments WHERE description_es IS NOT NULL AND description_es != ''")
    count_es = cursor.fetchone()[0]
    print(f"  ES remplis: {count_es}/{total}")
else:
    count_es = 0

# ========================================
# TEST 3: Exemple concret (Monument 1)
# ========================================
print("\n TEST 3: MONUMENT ID=1 (détails complets)")
print("-"*80)

query = "SELECT id, nom, description"
if has_desc_fr:
    query += ", description_fr"
if has_desc_en:
    query += ", description_en"
if has_desc_ar:
    query += ", description_ar"
if has_desc_es:
    query += ", description_es"
query += " FROM monuments WHERE id=1"

cursor.execute(query)
row = cursor.fetchone()

if row:
    print(f"ID: {row[0]}")
    print(f"Nom: {row[1]}")
    print(f"\ndescription (colonne originale):")
    print(f"  {row[2][:100] if row[2] else 'VIDE'}...")
    
    idx = 3
    if has_desc_fr:
        print(f"\ndescription_fr:")
        print(f"  {row[idx][:100] if row[idx] else 'VIDE'}...")
        idx += 1
    
    if has_desc_en:
        print(f"\ndescription_en:")
        print(f"  {row[idx][:100] if row[idx] else 'VIDE'}...")
        idx += 1
    
    if has_desc_ar:
        print(f"\ndescription_ar:")
        print(f"  {row[idx][:100] if row[idx] else 'VIDE'}...")
        idx += 1
    
    if has_desc_es:
        print(f"\ndescription_es:")
        print(f"  {row[idx][:100] if row[idx] else 'VIDE'}...")

conn.close()

# ========================================
# DIAGNOSTIC FINAL
# ========================================
print("\n" + "="*80)
print(" DIAGNOSTIC FINAL")
print("="*80)

if not (has_desc_fr and has_desc_en and has_desc_ar and has_desc_es):
    print("\n PROBLÈME: Les colonnes de traduction manquent!")
    print("\n SOLUTION:")
    print("   1. Créer les colonnes avec add_translations_column.py")
    
elif count_en == 0 and count_ar == 0 and count_es == 0:
    print("\n PROBLÈME: Les colonnes existent mais sont VIDES!")
    print("\n SOLUTION:")
    print("   1. Lancez: pip install deep-translator")
    print("   2. Lancez: python translate_monuments_FINAL.py")
    print("   3. Attendez 10-15 minutes")
    
elif count_ar > 0:
    print("\n LA BASE DE DONNÉES EST CORRECTE!")
    print(f"   {count_ar} monuments traduits en arabe")
    print("\n LE PROBLÈME EST DANS LE CODE BACKEND (main.py)")
    print("\n SOLUTION:")
    print("   1. Remplacez main.py par main_CORRECTED.py")
    print("   2. Redémarrez le backend")
    print("   3. Testez: http://100.81.116.14:8000/monuments?lang=ar")
    
else:
    print("\n  SITUATION PARTIELLE")
    print(f"   Traductions EN: {count_en}/{total}")
    print(f"   Traductions AR: {count_ar}/{total}")
    print(f"   Traductions ES: {count_es}/{total}")
    print("\n Relancez le script de traduction pour compléter")

print("="*80 + "\n")