#!/usr/bin/env python3
"""LOT 1.R — PLANCHES DE PREUVE avant/après pour la revue humaine.

À partir de DEUX dossiers de captures prises AUX MÊMES CAMÉRAS (le plan gelé
`shots_lot1.json`), produit quatre familles de sorties dans `--out` :

  1. `ab_<vue>.png`            — montage A/B côte à côte, une image par vue
                                 commune, étiquettes AVANT / APRÈS.
  2. `planche_couleur.png`     — planche de contact du lot (toutes les vues
                                 APRÈS, nommées).
  3. `planche_gris.png`        — la même planche en NIVEAUX DE GRIS (le test
                                 des valeurs de la bible §30.1 : la hiérarchie
                                 doit tenir sans la couleur).
  4. `planche_anonyme.png`     — SIX VUES JOUEUR numérotées 1-6, SANS nom de
                                 lieu, ordre aléatoire à graine fixée ; la
                                 correspondance numéro → lieu est écrite À
                                 CÔTÉ dans `planche_anonyme_cle.json`, jamais
                                 sur l'image. Destinée à la revue humaine en
                                 aveugle.

RÈGLE DE BRUIT (piège mesuré du dépôt, tools/CLAUDE.md : « diff sur deux
fichiers ABSENTS rend un diff vide ») : toute entrée absente est un ÉCHEC
bruyant, jamais un vert silencieux. Une vue présente d'un seul côté, un
dossier vide, un PNG illisible → code 2 et la liste exacte de ce qui manque.
Le script publie la taille de ce qu'il a examiné (« N vues appariées »), pas
seulement son résultat.

Usage :
    python3 tools/lot1r_planches.py --avant <dir> --apres <dir> --out <dir>
    python3 tools/lot1r_planches.py --avant <dir> --apres <dir> --out <dir> \
        --seed 20260824 --colonnes 3

Codes : 0 = toutes les planches écrites · 2 = entrée absente ou invalide.
"""

from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

# Graine PAR DÉFAUT de la planche anonyme — fixée pour que deux exécutions
# rendent le même ordre, et que la clé écrite hier corresponde à la planche
# imprimée aujourd'hui.
SEED_DEFAUT = 20260824
MARGE_PX = 12
BANDEAU_PX = 44
FOND = (24, 24, 28)
ENCRE = (235, 235, 238)


def _police(taille: int) -> ImageFont.ImageFont:
    try:
        return ImageFont.load_default(taille)
    except TypeError:  # Pillow < 10 : police par défaut sans taille
        return ImageFont.load_default()


def _die(message: str) -> None:
    print(f"ECHEC: {message}", file=sys.stderr)
    sys.exit(2)


def _pngs(dossier: Path) -> dict[str, Path]:
    if not dossier.is_dir():
        _die(f"dossier absent — {dossier}")
    vues = {p.stem: p for p in sorted(dossier.glob("*.png"))}
    if not vues:
        _die(f"aucun PNG dans {dossier}")
    return vues


def _charger(chemin: Path) -> Image.Image:
    try:
        image = Image.open(chemin)
        image.load()
        return image.convert("RGB")
    except OSError as erreur:
        _die(f"PNG illisible — {chemin} ({erreur})")
        raise  # jamais atteint


def _etiquette(image: Image.Image, texte: str, taille: int = 26) -> Image.Image:
    """Ajoute un bandeau de titre SOUS l'image (jamais par-dessus les pixels
    de preuve : recadrer une capture pour écrire dessus est exactement le
    contournement que l'audit doit chercher)."""
    sortie = Image.new("RGB", (image.width, image.height + BANDEAU_PX), FOND)
    sortie.paste(image, (0, 0))
    dessin = ImageDraw.Draw(sortie)
    police = _police(taille)
    boite = dessin.textbbox((0, 0), texte, font=police)
    x = (image.width - (boite[2] - boite[0])) // 2
    y = image.height + (BANDEAU_PX - (boite[3] - boite[1])) // 2 - boite[1]
    dessin.text((x, y), texte, fill=ENCRE, font=police)
    return sortie


def _grille(images: list[Image.Image], colonnes: int) -> Image.Image:
    largeur = max(im.width for im in images)
    hauteur = max(im.height for im in images)
    lignes = (len(images) + colonnes - 1) // colonnes
    toile = Image.new(
        "RGB",
        (colonnes * largeur + (colonnes + 1) * MARGE_PX,
         lignes * hauteur + (lignes + 1) * MARGE_PX),
        FOND,
    )
    for i, im in enumerate(images):
        c, l = i % colonnes, i // colonnes
        toile.paste(im, (MARGE_PX + c * (largeur + MARGE_PX),
                         MARGE_PX + l * (hauteur + MARGE_PX)))
    return toile


def _reduire(image: Image.Image, largeur_max: int) -> Image.Image:
    if image.width <= largeur_max:
        return image
    ratio = largeur_max / image.width
    return image.resize((largeur_max, round(image.height * ratio)),
                        Image.Resampling.LANCZOS)


def main() -> int:
    parseur = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parseur.add_argument("--avant", required=True, type=Path,
                         help="dossier des captures AVANT (mêmes caméras)")
    parseur.add_argument("--apres", required=True, type=Path,
                         help="dossier des captures APRÈS (mêmes caméras)")
    parseur.add_argument("--out", required=True, type=Path,
                         help="dossier de sortie des planches")
    parseur.add_argument("--seed", type=int, default=SEED_DEFAUT,
                         help="graine de l'ordre anonyme (défaut %(default)s)")
    parseur.add_argument("--colonnes", type=int, default=2,
                         help="colonnes des planches de contact (défaut 2)")
    parseur.add_argument("--largeur-vignette", type=int, default=640,
                         help="largeur max d'une vignette de planche (défaut 640)")
    parseur.add_argument("--sans-anonyme", action="store_true",
                         help="ne pas produire la planche anonyme (run sur UN "
                              "seul lieu : moins de 6 vues joueur). Sans ce "
                              "drapeau, moins de 6 vues joueur est un ÉCHEC, "
                              "jamais un saut silencieux.")
    args = parseur.parse_args()

    avant = _pngs(args.avant)
    apres = _pngs(args.apres)

    communes = sorted(set(avant) & set(apres))
    seulement_avant = sorted(set(avant) - set(apres))
    seulement_apres = sorted(set(apres) - set(avant))
    if seulement_avant or seulement_apres:
        _die("les deux dossiers ne portent pas les mêmes vues — "
             f"AVANT seulement : {seulement_avant or 'aucune'} ; "
             f"APRÈS seulement : {seulement_apres or 'aucune'}. "
             "Un appariement partiel rendrait une planche qui a l'air complète.")
    if not communes:
        _die("aucune vue commune entre les deux dossiers")

    args.out.mkdir(parents=True, exist_ok=True)
    ecrites: list[str] = []

    # 1. Montages A/B par vue.
    for vue in communes:
        gauche = _etiquette(_reduire(_charger(avant[vue]), args.largeur_vignette),
                            f"AVANT : {vue}")
        droite = _etiquette(_reduire(_charger(apres[vue]), args.largeur_vignette),
                            f"APRES : {vue}")
        hauteur = max(gauche.height, droite.height)
        toile = Image.new(
            "RGB", (gauche.width + droite.width + 3 * MARGE_PX,
                    hauteur + 2 * MARGE_PX), FOND)
        toile.paste(gauche, (MARGE_PX, MARGE_PX))
        toile.paste(droite, (gauche.width + 2 * MARGE_PX, MARGE_PX))
        chemin = args.out / f"ab_{vue}.png"
        toile.save(chemin)
        ecrites.append(chemin.name)

    # 2 + 3. Planche de contact couleur du lot (vues APRÈS), puis en gris.
    vignettes = [
        _etiquette(_reduire(_charger(apres[vue]), args.largeur_vignette), vue)
        for vue in communes
    ]
    planche = _grille(vignettes, max(1, args.colonnes))
    planche.save(args.out / "planche_couleur.png")
    ecrites.append("planche_couleur.png")
    ImageOps.grayscale(planche).save(args.out / "planche_gris.png")
    ecrites.append("planche_gris.png")

    # 4. Planche anonyme : les SIX vues joueur, numérotées, sans nom.
    if args.sans_anonyme:
        print(f"{len(communes)} vue(s) appariée(s), {len(ecrites)} fichier(s) "
              f"écrit(s) dans {args.out} (planche anonyme SAUTÉE sur demande) :")
        for nom in ecrites:
            print(f"  {nom}")
        return 0
    joueur = [v for v in communes if v.endswith("_joueur")]
    if len(joueur) != 6:
        _die(f"la planche anonyme exige exactement 6 vues '*_joueur' — "
             f"trouvées : {len(joueur)} ({joueur}). Les vues secondaires "
             "('_joueur_b', gros plans) n'y entrent pas.")
    ordre = list(joueur)
    random.Random(args.seed).shuffle(ordre)
    anonymes = [
        _etiquette(_reduire(_charger(apres[vue]), args.largeur_vignette),
                   f"vue {i + 1}", taille=30)
        for i, vue in enumerate(ordre)
    ]
    _grille(anonymes, max(1, args.colonnes)).save(args.out / "planche_anonyme.png")
    ecrites.append("planche_anonyme.png")
    cle = {
        "seed": args.seed,
        "correspondance": {str(i + 1): vue.removesuffix("_joueur")
                           for i, vue in enumerate(ordre)},
        "avertissement": "à ne pas ouvrir avant la revue en aveugle",
    }
    with open(args.out / "planche_anonyme_cle.json", "w", encoding="utf-8") as f:
        json.dump(cle, f, ensure_ascii=False, indent=1)
    ecrites.append("planche_anonyme_cle.json")

    print(f"{len(communes)} vue(s) appariée(s), {len(ecrites)} fichier(s) écrit(s) "
          f"dans {args.out} :")
    for nom in ecrites:
        print(f"  {nom}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
