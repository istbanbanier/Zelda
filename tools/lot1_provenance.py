#!/usr/bin/env python3
"""PROVENANCE du lot 1 — aucun asset n'entre dans le build sans licence.

`.claude/rules/assets.md` : « Aucune ressource sans licence claire n'entre dans
le build », et son inscription se fait **avant** l'ajout, pas après. Cette règle
n'était vérifiée par rien d'exécutable : elle vivait dans un document, donc elle
pouvait se dégrader en silence — le mode de panne que `PROMPT4_METHOD` §0
décrit comme le seul qui compte.

CE QU'IL FAIT. Pour chaque scène de lieu du lot 1, il relève tout chemin
`res://assets/...` réellement référencé par la scène ou son script, puis exige
que chacun apparaisse à la fois dans `docs/assets/ASSET_MANIFEST.csv` et dans
`ATTRIBUTIONS.md`.

CE QU'IL NE FAIT PAS, et il faut le dire : il ne LIT pas une licence, il vérifie
qu'elle est DÉCLARÉE. Un manifeste qui mentirait sur une licence passerait ici.
Le garde-fou contre ça reste humain — la revue du diff — et prétendre le
contraire serait exactement la sur-affirmation que ce dépôt sanctionne.

Usage :
    python3 tools/lot1_provenance.py
Codes : 0 = tout est attribué · 1 = au moins un asset sans provenance
        3 = BLOQUÉ (aucun lieu du lot enregistré : rien à vérifier)
"""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

LOT1 = [
    "valley.poi.watchtower_ruin.01",
    "valley.poi.overlook_summit.01",
    "valley.poi.turquoise_spring.01",
    "valley.poi.forest_shrine.01",
    "valley.poi.barrow_cemetery.01",
    "valley.poi.flower_field.01",
]
REGISTRY = Path("scripts/world_v2/poi/world_v2_places_builder.gd")
MANIFESTE = Path("docs/assets/ASSET_MANIFEST.csv")
ATTRIBUTIONS = Path("ATTRIBUTIONS.md")
ASSET = re.compile(r'res://(assets/[^"\'\s\)]+)')


def scene_de(place_id: str, registre: str) -> str:
    m = re.search(r'&"' + re.escape(place_id) + r'"\s*:\s*\n?\s*"res://([^"]+)"',
                  registre)
    return m.group(1) if m else ""


def script_de(scene: Path) -> str:
    if not scene.exists():
        return ""
    m = re.search(r'\[ext_resource type="Script"[^\]]*path="res://([^"]+)"',
                  scene.read_text(encoding="utf-8"))
    return m.group(1) if m else ""


def main() -> int:
    registre = REGISTRY.read_text(encoding="utf-8")
    connus: set[str] = set()
    # Un asset dont le manifeste dit qu'il est du PROJET n'a rien à faire dans
    # ATTRIBUTIONS.md, qui recense les ressources EXTERNES. L'exigence se lit
    # donc dans le manifeste (`auteur`, `licence`) plutôt que d'être la même
    # pour tout le monde — sinon les hero assets générés par nos propres
    # scripts Blender seraient signalés à vie, et le contrôle serait ignoré.
    du_projet: set[str] = set()
    if MANIFESTE.exists():
        with MANIFESTE.open(encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                interne = ((row.get("auteur") or "").strip() == "projet"
                           or (row.get("licence") or "").strip() == "licence_projet")
                for champ in ("export", "fichier_maitre"):
                    valeur = (row.get(champ) or "").strip()
                    if valeur:
                        connus.add(valeur)
                        if interne:
                            du_projet.add(valeur)
    attributions = ATTRIBUTIONS.read_text(encoding="utf-8") \
        if ATTRIBUTIONS.exists() else ""

    presents = 0
    manquants: list[str] = []
    non_verifiables: list[str] = []
    total = 0
    for pid in LOT1:
        scene = scene_de(pid, registre)
        if not scene:
            print(f"{pid:40s} ABSENT DU REGISTRE")
            continue
        presents += 1
        fichiers = [Path(scene)]
        script = script_de(Path(scene))
        if script:
            fichiers.append(Path(script))
        vus: set[str] = set()
        for f in fichiers:
            if f.exists():
                vus |= set(ASSET.findall(f.read_text(encoding="utf-8")))
        # Un chemin construit à l'exécution (« res://assets/x/ » + un nom) ne
        # se vérifie pas statiquement. On le SORT du décompte et on le NOMME,
        # au lieu de le compter en faute — ce qui rendrait le contrôle faux —
        # ou de le taire — ce qui le rendrait complaisant.
        dynamiques = sorted(c for c in vus if c.endswith("/"))
        fixes = sorted(c for c in vus if not c.endswith("/"))
        for c in dynamiques:
            non_verifiables.append(f"{pid} → res://{c}… (chemin construit à "
                                   "l'exécution)")
        total += len(fixes)
        for chemin in fixes:
            au_manifeste = chemin in connus
            # L'attribution se cherche sur le nom de fichier : ATTRIBUTIONS.md
            # décrit des LOTS d'assets (« 42 gltf Quaternius »), pas toujours un
            # chemin exact. On cherche donc le nom, puis le répertoire parent.
            nom = Path(chemin).name
            parent = Path(chemin).parent.name
            interne = chemin in du_projet
            attribue = interne or nom in attributions \
                or (parent and parent in attributions)
            if au_manifeste and attribue:
                continue
            raisons = []
            if not au_manifeste:
                raisons.append("absent d'ASSET_MANIFEST.csv")
            if not attribue:
                raisons.append("externe et absent d'ATTRIBUTIONS.md")
            manquants.append(f"{pid} → {chemin} ({', '.join(raisons)})")
        print(f"{pid:40s} {len(fixes):3d} asset(s) fixe(s), "
              f"{len(dynamiques)} chemin(s) dynamique(s)")

    print()
    if non_verifiables:
        print("NON VÉRIFIABLE STATIQUEMENT — à contrôler à la main :")
        for n in non_verifiables:
            print(f"  {n}")
        print()
    if presents == 0:
        print("BLOQUÉ : aucun lieu du lot 1 n'est enregistré — rien à vérifier.")
        print("Un contrôle qui n'inspecte rien est vert pour rien.")
        return 3
    if manquants:
        print(f"SANS PROVENANCE ({len(manquants)} sur {total}) :")
        for m in manquants:
            print(f"  {m}")
        print()
        print("Règle : tout asset externe entre dans ATTRIBUTIONS.md et dans")
        print("docs/assets/ASSET_MANIFEST.csv AVANT d'entrer dans le build.")
        return 1
    print(f"PASS — {total} asset(s) référencé(s) par {presents} lieu(x), "
          "tous au manifeste et attribués.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
