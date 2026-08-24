#!/usr/bin/env python3
"""VOIE A — MONTAGE A/B ANNOTÉ DES DEUX EAUX (lot 1.R).

POURQUOI CE FICHIER EXISTE. Sur `spring_promesse_p1.png`, la vasque de la
source rend un RUBAN BLANC. Le rejet Codex du lot 1 disait « supprimer la
nappe blanche ». Un relecteur qui ouvre cette image seule conclura que le
défaut rejeté est toujours là — et il aura tort, mais on ne peut pas le lui
reprocher : rien dans l'image ne le détrompe.

Ce que le montage démontre, avec les valeurs mesurées à côté des vignettes :
la MÊME image contient DEUX nappes d'eau, la vasque locale et l'affluent
V2.2 GELÉ, et elles rendent le même blanc au même angle. Ce blanc n'est donc
pas une propriété du maillage de la source ; c'est le miroir spéculaire du
ciel que le shader `SH_WorldV2Water` (SPECULAR 0,4 · ROUGHNESS 0,18, lu sans
être modifié) produit à incidence rasante, sur TOUTE l'eau du monde.

La seconde rangée donne le contre-exemple au même moteur : à incidence
moyenne, la vasque et la rivière gelée rendent le même sarcelle.

Usage :
    python3 voie_a_montage_eau.py
    (lit `evidence/world_v2/v2_3_b/lot1r/voie_a/final/`, écrit
     `comparatif_eau_final.png` dans le même dossier)

Le montage est une PREUVE, pas une illustration : les valeurs affichées sont
recalculées sur les pixels au moment du montage, jamais recopiées à la main.
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RACINE = Path(__file__).resolve().parent
FINAL = RACINE / "evidence/world_v2/v2_3_b/lot1r/voie_a/final"
SORTIE = FINAL / "comparatif_eau_final.png"
POLICE = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
POLICE_GRAS = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"

# (titre, fichier, boîte de recadrage, boîte d'échantillon dans l'image source)
VIGNETTES = [
    ("P1 — vasque de la source (locale)", "spring_promesse_p1.png",
     (520, 300, 780, 420), (600, 352, 690, 364)),
    ("P1 — affluent V2.2 GELÉ, même image", "spring_promesse_p1.png",
     (900, 370, 1160, 490), (940, 405, 1120, 440)),
    ("Gros plan — vasque de la source (locale)", "spring_gros_eau.png",
     (460, 330, 900, 530), (500, 360, 860, 440)),
    ("Gué — rivière V2.2 GELÉE, même moteur", "spring_gue_riviere.png",
     (660, 480, 1100, 680), (820, 510, 880, 570)),
]


def moyenne(image: Image.Image, boite: tuple[int, int, int, int]) -> tuple[int, int, int]:
    pixels = list(image.crop(boite).convert("RGB").getdata())
    n = len(pixels)
    return tuple(round(sum(p[i] for p in pixels) / n) for i in range(3))


def saturation(couleur: tuple[int, int, int]) -> float:
    bas, haut = min(couleur), max(couleur)
    return 0.0 if haut == 0 else (haut - bas) / haut


def main() -> int:
    if not FINAL.is_dir():
        print(f"ECHEC: dossier absent — {FINAL}", file=sys.stderr)
        return 2
    largeur_vig, hauteur_vig = 520, 240
    marge, bandeau, entete = 18, 74, 96
    colonnes, lignes = 2, 2
    largeur = marge + colonnes * (largeur_vig + marge)
    hauteur = entete + lignes * (hauteur_vig + bandeau + marge)
    toile = Image.new("RGB", (largeur, hauteur), (22, 24, 28))
    dessin = ImageDraw.Draw(toile)
    titre_f = ImageFont.truetype(POLICE_GRAS, 21)
    petit_f = ImageFont.truetype(POLICE, 15)
    mono_f = ImageFont.truetype(POLICE_GRAS, 16)

    dessin.text((marge, 16),
                "LES DEUX EAUX DE LA MÊME IMAGE — voie A, lot 1.R",
                font=titre_f, fill=(235, 235, 230))
    dessin.text((marge, 46),
                "Haut : incidence rasante (P1). Bas : incidence moyenne. "
                "Valeurs RGB = moyenne recalculée sur la zone encadrée.",
                font=petit_f, fill=(170, 175, 180))

    manquantes: list[str] = []
    for index, (titre, fichier, recadrage, echantillon) in enumerate(VIGNETTES):
        chemin = FINAL / fichier
        if not chemin.is_file():
            manquantes.append(fichier)
            continue
        source = Image.open(chemin).convert("RGB")
        couleur = moyenne(source, echantillon)
        vignette = source.crop(recadrage).resize((largeur_vig, hauteur_vig),
                                                 Image.LANCZOS)
        col, ligne = index % colonnes, index // colonnes
        x = marge + col * (largeur_vig + marge)
        y = entete + ligne * (hauteur_vig + bandeau + marge)
        toile.paste(vignette, (x, y))
        dessin.rectangle([x, y, x + largeur_vig - 1, y + hauteur_vig - 1],
                         outline=(90, 95, 100))
        # report du cadre d'échantillon sur la vignette
        ex0 = (echantillon[0] - recadrage[0]) * largeur_vig / (recadrage[2] - recadrage[0])
        ey0 = (echantillon[1] - recadrage[1]) * hauteur_vig / (recadrage[3] - recadrage[1])
        ex1 = (echantillon[2] - recadrage[0]) * largeur_vig / (recadrage[2] - recadrage[0])
        ey1 = (echantillon[3] - recadrage[1]) * hauteur_vig / (recadrage[3] - recadrage[1])
        dessin.rectangle([x + ex0, y + ey0, x + ex1, y + ey1],
                         outline=(255, 210, 90), width=2)
        dessin.text((x, y + hauteur_vig + 6), titre, font=petit_f,
                    fill=(225, 225, 220))
        dessin.text((x, y + hauteur_vig + 28),
                    "RGB %d, %d, %d   ·   saturation %.3f"
                    % (couleur[0], couleur[1], couleur[2], saturation(couleur)),
                    font=mono_f, fill=(255, 210, 90))
        dessin.text((x, y + hauteur_vig + 50), fichier, font=petit_f,
                    fill=(130, 135, 140))

    if manquantes:
        print("ECHEC: image(s) absente(s) — " + ", ".join(manquantes),
              file=sys.stderr)
        return 2
    toile.save(SORTIE)
    print(f"écrit : {SORTIE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
