#!/usr/bin/env python3
"""Empreinte canonique d'un manifeste ISS-071.

POURQUOI CET OUTIL EXISTE (correction de contre-revue, défaut C8).
`docs/DECISIONS.md` affirmait que le manifeste éditeur d'AVANT correctif et
celui d'APRÈS sont identiques, et citait une empreinte à l'appui. Cette
empreinte n'était reproductible par AUCUN outil du dépôt : personne ne pouvait
la recalculer, donc personne ne pouvait constater qu'elle avait cessé d'être
vraie. C'est exactement l'ancre morte que `CLAUDE.md` interdit — « un document
cite des chemins stables, des symboles exportés, des tests épinglés ; jamais un
nombre ».

Ce script rend le nombre vivant. La canonicalisation retire les champs qui
varient légitimement d'une exécution à l'autre ou d'une passe à l'autre, et
seulement ceux-là ; elle est déclarée ici, en clair, et versionnée avec la
valeur qu'elle produit.

Usage :
    python3 tools/iss071_empreinte_manifeste.py <manifeste.json> [autres…]
    python3 tools/iss071_empreinte_manifeste.py --comparer <a.json> <b.json>

Code retour : 0 si tout va bien ; avec --comparer, 1 si les empreintes
diffèrent.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path
from typing import Any

# Champs retirés avant l'empreinte, et la RAISON de chacun. Toute addition à
# cette liste élargit ce que l'empreinte cesse de voir : elle se justifie dans
# `docs/DECISIONS.md`, jamais en silence.
VOLATILS: dict[str, str] = {
    "chargeabilite": "ajouté APRÈS la mesure d'avant correctif ; le comparer "
                     "reviendrait à comparer un champ à son absence",
}


def canoniser(obj: Any) -> Any:
    """Retire récursivement les champs volatils, sans rien trier ni réordonner
    d'autre — l'ordre des listes (répertoires, collisions) EST une donnée."""
    if isinstance(obj, dict):
        return {k: canoniser(v) for k, v in obj.items() if k not in VOLATILS}
    if isinstance(obj, list):
        return [canoniser(v) for v in obj]
    return obj


def empreinte(chemin: Path) -> str:
    data = json.loads(chemin.read_text(encoding="utf-8"))
    # `sort_keys` neutralise l'ordre d'écriture des CLÉS, qui dépend de l'ordre
    # d'itération d'un Dictionary Godot et n'a aucune signification.
    canon = json.dumps(canoniser(data), sort_keys=True, ensure_ascii=False,
                       separators=(",", ":"))
    return hashlib.sha256(canon.encode("utf-8")).hexdigest()[:16]


def main(argv: list[str]) -> int:
    if len(argv) >= 3 and argv[0] == "--comparer":
        a, b = Path(argv[1]), Path(argv[2])
        ea, eb = empreinte(a), empreinte(b)
        print(f"{ea}  {a}")
        print(f"{eb}  {b}")
        if ea == eb:
            print("IDENTIQUES (hors champs volatils : "
                  f"{', '.join(sorted(VOLATILS))})")
            return 0
        print("DIFFÉRENTS")
        return 1
    if not argv:
        print(__doc__, file=sys.stderr)
        return 2
    for nom in argv:
        print(f"{empreinte(Path(nom))}  {nom}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
