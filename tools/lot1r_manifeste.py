#!/usr/bin/env python3
"""LOT 1.R — VÉRIFICATEUR DE MANIFESTES d'un dossier de captures.

Un dossier de preuves n'est probant que si chaque manifeste dit d'où viennent
ses images : `repo_dirty: false` (capture d'un arbre COMMITTÉ — règle
`.claude/rules/evidence.md`) et UN SEUL commit pour tout le dossier — deux
commits mélangés, c'est deux états du monde présentés comme un seul.

Ce script lit tous les `manifest*.json` du dossier, vérifie :

  - `repo_dirty` est présent et vaut `false` dans CHAQUE manifeste ;
  - le champ `commit` est présent, non vide, et IDENTIQUE partout ;
  - chaque image référencée (`shots[].image` ou `vues[].image`) existe sur le
    disque, en absolu ou relative à la racine du dépôt ou au dossier ;

puis imprime le tableau. Il ÉCHOUE BRUYAMMENT (code 2) sur : dossier absent,
aucun manifeste, JSON illisible, champ manquant, arbre sale, commits
multiples, image absente — jamais un 0 obtenu en ne vérifiant rien (piège
mesuré du dépôt : « diff sur deux fichiers absents rend IDENTIQUE »). Il
publie la taille de ce qu'il a examiné : N manifestes, M images.

Usage :
    python3 tools/lot1r_manifeste.py <dossier>
    python3 tools/lot1r_manifeste.py evidence/world_v2/v2_3_b/lot1/poi

Codes : 0 = tout vérifié conforme · 2 = écart ou entrée invalide.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


def _racine_depot(depart: Path) -> Path | None:
    try:
        sortie = subprocess.run(
            ["git", "-C", str(depart), "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True)
        return Path(sortie.stdout.strip())
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def _images_de(manifeste: dict) -> list[str]:
    chemins: list[str] = []
    for cle in ("shots", "vues"):
        entrees = manifeste.get(cle)
        if isinstance(entrees, list):
            for entree in entrees:
                if isinstance(entree, dict) and isinstance(entree.get("image"), str):
                    chemins.append(entree["image"])
    return chemins


def main() -> int:
    parseur = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parseur.add_argument("dossier", type=Path,
                         help="dossier de captures portant des manifest*.json")
    args = parseur.parse_args()

    if not args.dossier.is_dir():
        print(f"ECHEC: dossier absent — {args.dossier}", file=sys.stderr)
        return 2

    manifestes = sorted(args.dossier.glob("manifest*.json"))
    if not manifestes:
        print(f"ECHEC: aucun manifest*.json dans {args.dossier} — un dossier "
              "sans manifeste n'est pas un dossier de preuves", file=sys.stderr)
        return 2

    racine = _racine_depot(args.dossier)
    ecarts: list[str] = []
    lignes: list[tuple[str, str, str, str]] = []
    commits: set[str] = set()
    images_vues = 0

    for chemin in manifestes:
        try:
            with open(chemin, encoding="utf-8") as f:
                donnees = json.load(f)
        except (OSError, json.JSONDecodeError) as erreur:
            ecarts.append(f"{chemin.name} : JSON illisible ({erreur})")
            lignes.append((chemin.name, "?", "?", "illisible"))
            continue
        if not isinstance(donnees, dict):
            ecarts.append(f"{chemin.name} : le manifeste n'est pas un objet JSON")
            continue

        commit = str(donnees.get("commit", "") or "")
        if not commit:
            ecarts.append(f"{chemin.name} : champ `commit` absent ou vide")
        else:
            commits.add(commit)

        if "repo_dirty" not in donnees:
            ecarts.append(f"{chemin.name} : champ `repo_dirty` ABSENT — "
                          "impossible de savoir si l'arbre était committé")
            proprete = "?"
        elif donnees["repo_dirty"] is not False:
            ecarts.append(f"{chemin.name} : repo_dirty={donnees['repo_dirty']!r} — "
                          "une capture d'arbre sale ne prouve rien")
            proprete = "SALE"
        else:
            proprete = "propre"

        images = _images_de(donnees)
        absentes: list[str] = []
        for image in images:
            images_vues += 1
            candidats = [Path(image)]
            if racine is not None:
                candidats.append(racine / image)
            candidats.append(args.dossier / Path(image).name)
            if not any(c.is_file() for c in candidats):
                absentes.append(image)
        if not images:
            ecarts.append(f"{chemin.name} : aucune image référencée "
                          "(ni `shots`, ni `vues`)")
        for image in absentes:
            ecarts.append(f"{chemin.name} : image référencée ABSENTE — {image}")

        lignes.append((chemin.name, commit[:12] or "?", proprete,
                       f"{len(images) - len(absentes)}/{len(images)} image(s)"))

    if len(commits) > 1:
        ecarts.append("plusieurs commits dans le même dossier : "
                      + ", ".join(sorted(c[:12] for c in commits))
                      + " — deux états du monde présentés comme un seul")

    largeur = max(len(l[0]) for l in lignes)
    print(f"{'manifeste'.ljust(largeur)}  {'commit':<12}  {'arbre':<6}  images")
    for nom, commit, proprete, compte in lignes:
        print(f"{nom.ljust(largeur)}  {commit:<12}  {proprete:<6}  {compte}")
    print(f"\n{len(manifestes)} manifeste(s), {images_vues} image(s) référencée(s), "
          f"{len(commits)} commit(s) distinct(s).")

    if ecarts:
        print(f"\nECHEC — {len(ecarts)} écart(s) :", file=sys.stderr)
        for ecart in ecarts:
            print(f"  - {ecart}", file=sys.stderr)
        return 2
    print("CONFORME : arbre propre, SHA unique, toutes les images présentes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
