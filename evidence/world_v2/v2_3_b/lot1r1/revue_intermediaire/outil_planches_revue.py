#!/usr/bin/env python3
"""Planches de la revue intermédiaire LOT 1.R.1 — numérotées, SANS noms.

Trois sorties sous evidence/world_v2/v2_3_b/lot1r1/revue_intermediaire/ :
  * planche_joueur_anonyme.png   — les 6 vues joueur, ordre mélangé, étiquettes 1..6 ;
  * planche_couleur_numerotee.png — 6 joueur + 5 identité, étiquettes 1..11 ;
  * planche_gris.png              — la même planche en niveaux de gris.
La clé numéro→fichier vit dans cle_planches.json, JAMAIS sur les images :
la directive demande une lecture à l'aveugle.

Le mélange est semé sur le sha du commit courant : reproductible, et
personne ne choisit l'ordre à la main.
"""
import json
import random
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, "tools")
from lot1r_planches import _charger, _etiquette, _grille, _reduire  # noqa: E402

E = Path("evidence/world_v2/v2_3_b/lot1r1/revue_intermediaire")
V = E / "vues"
LARGEUR_TUILE = 640

JOUEUR = ["watchtower_ruin", "overlook_summit", "turquoise_spring",
          "forest_shrine", "barrow_cemetery", "flower_field"]
IDENTITE = ["watchtower_ruin", "overlook_summit", "turquoise_spring",
            "forest_shrine", "barrow_cemetery"]


def main() -> int:
    sha = subprocess.run(["git", "rev-parse", "--short", "HEAD"],
                         capture_output=True, text=True,
                         check=True).stdout.strip()
    rng = random.Random(sha)

    joueur = [(f"{n}_joueur", V / f"{n}_joueur.png") for n in JOUEUR]
    identite = [(f"{n}_identite", V / f"{n}_identite.png") for n in IDENTITE]
    absents = [str(p) for _, p in joueur + identite if not p.exists()]
    if absents:
        print("ABSENT :", "\n  ".join(absents), file=sys.stderr)
        return 2

    cle: dict[str, dict[str, str]] = {"commit": sha}

    ordre_j = list(joueur)
    rng.shuffle(ordre_j)
    tuiles = [_etiquette(_reduire(_charger(p), LARGEUR_TUILE), str(i + 1))
              for i, (_, p) in enumerate(ordre_j)]
    _grille(tuiles, 3).save(E / "planche_joueur_anonyme.png")
    cle["planche_joueur_anonyme"] = {
        str(i + 1): nom for i, (nom, _) in enumerate(ordre_j)}

    ordre_c = list(joueur) + list(identite)
    rng.shuffle(ordre_c)
    tuiles_c = [_etiquette(_reduire(_charger(p), LARGEUR_TUILE), str(i + 1))
                for i, (_, p) in enumerate(ordre_c)]
    planche_c = _grille(tuiles_c, 4)
    planche_c.save(E / "planche_couleur_numerotee.png")
    planche_c.convert("L").save(E / "planche_gris.png")
    cle["planche_couleur_numerotee"] = {
        str(i + 1): nom for i, (nom, _) in enumerate(ordre_c)}

    (E / "cle_planches.json").write_text(
        json.dumps(cle, indent=1, ensure_ascii=False), encoding="utf-8")
    for f in ("planche_joueur_anonyme.png", "planche_couleur_numerotee.png",
              "planche_gris.png", "cle_planches.json"):
        print("écrit :", E / f)
    return 0


if __name__ == "__main__":
    sys.exit(main())
