#!/usr/bin/env python3
"""SOCLE CHIFFRÉ — les nombres de l'audit, mesurés à la main, hors agents.

POURQUOI CET OUTIL EXISTE. Un audit conduit par des sous-agents produit des
chiffres que personne n'a vérifiés. Ce script mesure INDÉPENDAMMENT les
grandeurs structurantes, pour que les rapports puissent être confrontés à une
base qu'ils n'ont pas écrite. C'est l'application de la règle du dépôt :
un verdict doit publier la TAILLE de ce qu'il a examiné.

Il ne lance ni Godot ni Blender. Il lit le dépôt et l'historique git.
"""
from __future__ import annotations

import json
import pathlib
import re
import subprocess

SORTIE = "evidence/world_v2/audit_jeu_long/mesures_independantes.md"
# Premier commit du chantier World V2, ancre stable de l'historique.
ANCRE_V2 = "62ef876"
LIEUX = ["riverside_village", "abandoned_farm", "stone_bridge",
         "waterfall_cave", "thunderstruck_tree", "ember_raider",
         "conductive_basin", "watchtower_ruin", "overlook_summit",
         "turquoise_spring", "forest_shrine", "barrow_cemetery",
         "flower_field"]


def sh(c: str) -> str:
    return subprocess.run(c, shell=True, capture_output=True,
                          text=True).stdout.strip()


def main() -> int:
    d = json.loads(pathlib.Path(
        "resources/world_v2/world_v2_layout.json").read_text(encoding="utf-8"))
    src = pathlib.Path(
        "scripts/world_v2/poi/world_v2_places_builder.gd").read_text(
            encoding="utf-8")
    bloc = src[src.index("const REGISTRY"):]
    bloc = bloc[:bloc.index("\n}")]
    montes = set(re.findall(r'&"([^"]+)"', bloc))
    pois = {p["id"] for p in d["pois"]}
    sites = {p["id"] for p in d["systemic_sites"]}
    declares = pois | sites
    reste = sorted(declares - montes)

    # État de l'arbre EN EXCLUANT le fichier qu'on est en train d'écrire :
    # se déclarer sale à cause de sa propre sortie serait une fausse alerte.
    sale = [l for l in sh("git status --porcelain").splitlines()
            if SORTIE not in l]

    out: list[str] = []
    w = out.append
    w("# Mesures indépendantes — socle chiffré de l'audit\n")
    w("Produit par `tools/mesures_socle.py`. Prises **avant** de lire les")
    w("rapports des sous-agents, pour que ces rapports puissent être")
    w("confrontés à une base qu'ils n'ont pas écrite. Aucun chiffre de cette")
    w("page ne vient d'un agent.\n")
    w(f"Commit : `{sh('git rev-parse HEAD')[:7]}` · arbre "
      + ("**propre**" if not sale
         else f"**{len(sale)} fichier(s) modifié(s)** hors cette sortie")
      + "\n")

    b = d["bounds"]
    w("## Le monde\n")
    w("| Grandeur | Valeur |\n|---|---:|")
    w(f"| Étendue du terrain | {b['extent_m']} × {b['extent_m']} m |")
    w(f"| Rayon jouable max | {b['playable_radius_max_m']} m |")
    w(f"| Régions déclarées | {len(d['regions'])} |")
    w(f"| Lignes de vue | {len(d['sightlines'])} |")
    w(f"| Checkpoints | {len(d['checkpoints'])} |")
    w(f"| Espaces de donjon | {len(d['dungeon_spaces'])} |")
    w(f"| Étapes de progression | {len(d['progression'])} |")

    w("\n## Lieux : construits contre déclarés\n")
    w("| | Nombre |\n|---|---:|")
    w(f"| POI déclarés au layout | {len(pois)} |")
    w(f"| Sites systémiques déclarés | {len(sites)} |")
    w(f"| **Total déclaré** | **{len(declares)}** |")
    w(f"| Montés dans le REGISTRY | {len(montes)} |")
    w(f"| dont hors liste (camp, pylône) | {len(montes - declares)} |")
    w(f"| **Déclarés et NON construits** | **{len(reste)}** |")
    pct = 100 * len(montes & declares) // len(declares)
    w(f"\nAchèvement de la région 1 : **{pct} %** des sujets déclarés.\n")
    w("Non construits :\n")
    for r in reste:
        w(f"- `{r}`")

    w("\n## Coût de production mesuré\n")
    debut = sh("git log --reverse --format=%ad --date=short "
               "-- scripts/world_v2/ | head -1")
    fin = sh("git log -1 --format=%ad --date=short -- scripts/world_v2/")
    n = sh(f"git log --oneline {ANCRE_V2}..HEAD | wc -l")
    w(f"Chantier World V2 : **{debut} → {fin}**, **{n} commits** au total.\n")
    w("Commits touchant les fichiers de chaque lieu construit :\n")
    w("| Lieu | Commits |\n|---|---:|")
    vals: list[int] = []
    for p in LIEUX:
        v = int(sh(f'git log --oneline {ANCRE_V2}..HEAD -- "*{p}*" | wc -l'))
        vals.append(v)
        w(f"| {p} | {v} |")
    vals.sort()
    med = vals[len(vals) // 2]
    w(f"\nMédiane **{med} commits par lieu** ; minimum {vals[0]}, "
      f"maximum {vals[-1]}.\n")
    w("**Projection — c'est une ESTIMATION, pas une mesure.** Au rythme")
    w(f"observé, les **{len(reste)} lieux restants de la SEULE région 1**")
    w(f"représentent de l'ordre de **{med * len(reste)} commits**. Le chiffre")
    w("vaut pour l'ordre de grandeur, pas pour la décimale : il suppose que")
    w("les lieux restants coûtent comme les précédents, ce qui est faux dans")
    w("les deux sens — le pipeline s'est amélioré, mais les sujets faciles")
    w("ont été faits en premier.\n")

    w("## Code et tests\n")
    w("| Domaine | Fichiers `.gd` |\n|---|---:|")
    for dd in sorted(pathlib.Path("scripts").iterdir()):
        if dd.is_dir():
            w(f"| scripts/{dd.name} | {len(list(dd.rglob('*.gd')))} |")
    w("\n| Suite | Fichiers `.gd` |\n|---|---:|")
    for dd in sorted(pathlib.Path("tests").iterdir()):
        if dd.is_dir():
            w(f"| tests/{dd.name} | {len(list(dd.rglob('*.gd')))} |")
    w(f"\nScènes `.tscn` : **{len(list(pathlib.Path('scenes').rglob('*.tscn')))}**"
      f" · ressources `.tres` : "
      f"**{len(list(pathlib.Path('resources').rglob('*.tres')))}**")

    chemin = pathlib.Path(SORTIE)
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"écrit -> {SORTIE}")
    print(f"  {len(declares)} sujets déclarés, {len(montes)} montés, "
          f"{len(reste)} restants ; médiane {med} commits/lieu")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
