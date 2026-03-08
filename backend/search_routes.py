# ══════════════════════════════════════════════════════
# Recherche Fuzzy monuments avec RapidFuzz
# ══════════════════════════════════════════════════════

from fastapi import APIRouter, Query
from rapidfuzz import fuzz, process
import json
import os
import unicodedata
import re

router = APIRouter(prefix="/api/search", tags=["Search"])

# Charger data.json
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(BASE_DIR, "data.json")

with open(DATA_PATH, "r", encoding="utf-8") as f:
    MONUMENTS = json.load(f)

# Normaliser texte (enlever accents, lowercase) 
def normalize(text: str) -> str:
    text = text.lower().strip()
    text = unicodedata.normalize("NFD", text)
    text = "".join(c for c in text if unicodedata.category(c) != "Mn")
    text = re.sub(r"[^\w\s]", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()

# ── Préparer index de recherche ───────────────────────
search_index = []
for i, m in enumerate(MONUMENTS):
    nom     = m.get("NOM", "")
    ville   = m.get("VILLE", "")
    combined = f"{nom} {ville}"
    search_index.append({
        "idx":           i,
        "nom":           nom,
        "ville":         ville,
        "combined":      combined,
        "combined_norm": normalize(combined),
        "nom_norm":      normalize(nom),
        "ville_norm":    normalize(ville),
    })

# GET /api/search/suggestions  → live typing (max 5)
@router.get("/suggestions")
async def get_suggestions(
    q:     str = Query(..., min_length=1),
    limit: int = Query(5, ge=1, le=10),
):
    """Suggestions rapides pendant la frappe."""
    q_norm = normalize(q)

    if len(q_norm) < 2:
        # 1 caractère : correspondances qui commencent par cette lettre
        suggestions = []
        for item in search_index:
            if item["nom_norm"].startswith(q_norm):
                m = MONUMENTS[item["idx"]]
                suggestions.append({
                    "nom":   m.get("NOM", ""),
                    "ville": m.get("VILLE", ""),
                    "image": (m.get("IMAGE") or [None])[0],
                })
        return {"suggestions": suggestions[:limit], "query": q}

    # 2+ caractères : rapidfuzz
    nom_list = [item["nom_norm"] for item in search_index]
    matches  = process.extract(
        q_norm,
        nom_list,
        scorer=fuzz.partial_ratio,
        limit=limit * 3,
    )

    suggestions = []
    seen = set()
    for _, score, idx in matches:
        if score < 45 or idx in seen:
            continue
        seen.add(idx)
        m = MONUMENTS[idx]
        suggestions.append({
            "nom":   m.get("NOM", ""),
            "ville": m.get("VILLE", ""),
            "image": (m.get("IMAGE") or [None])[0],
            "_score": score,
        })

    suggestions.sort(key=lambda x: x.pop("_score"), reverse=True)
    return {"suggestions": suggestions[:limit], "query": q}

# GET /api/search/monuments  → recherche complète
@router.get("/monuments")
async def search_monuments(
    q:     str = Query(..., min_length=1),
    limit: int = Query(10, ge=1, le=30),
    ville: str = Query(None, description="Filtrer par ville"),
):
    """Recherche fuzzy complète avec scores."""
    q_norm  = normalize(q)
    results = []

    for item in search_index:
        # Filtre ville optionnel
        if ville and q_norm not in item["ville_norm"] and normalize(ville) not in item["ville_norm"]:
            pass  # pas de filtre strict ici, on laisse le score décider

        nom_norm      = item["nom_norm"]
        combined_norm = item["combined_norm"]
        scores        = []

        # Priorité : commence par la query
        if nom_norm.startswith(q_norm):
            scores.append(100)
        elif combined_norm.startswith(q_norm):
            scores.append(95)

        # Contient exactement
        if q_norm in nom_norm:
            scores.append(90)
        elif q_norm in combined_norm:
            scores.append(82)

        # Fuzzy scores
        scores.append(fuzz.partial_ratio(q_norm, nom_norm)      * 0.90)
        scores.append(fuzz.token_sort_ratio(q_norm, nom_norm)   * 0.85)
        scores.append(fuzz.partial_ratio(q_norm, combined_norm) * 0.80)

        final_score = max(scores) if scores else 0

        if final_score < 45:
            continue

        # Filtre ville strict si paramètre ville fourni
        if ville and normalize(ville) not in item["ville_norm"]:
            continue

        m = MONUMENTS[item["idx"]]
        results.append({
            "score":        round(final_score, 1),
            "nom":          m.get("NOM", ""),
            "ville":        m.get("VILLE", ""),
            "description":  (m.get("DESCRIPTION") or "")[:150] + "...",
            "image":        (m.get("IMAGE") or [None])[0],
            "localisation": m.get("LOCALISATION", ""),
            "all_images":   m.get("IMAGE", []),
        })

    results.sort(key=lambda x: x["score"], reverse=True)
    return {
        "results": results[:limit],
        "query":   q,
        "total":   len(results[:limit]),
    }

# GET /api/search/villes  → liste des villes
@router.get("/villes")
async def get_villes():
    """Liste toutes les villes disponibles."""
    villes = sorted(set(m.get("VILLE", "") for m in MONUMENTS if m.get("VILLE")))
    return {"villes": villes, "total": len(villes)}