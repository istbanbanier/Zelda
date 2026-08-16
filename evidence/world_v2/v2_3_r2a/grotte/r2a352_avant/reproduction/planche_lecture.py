#!/usr/bin/env python3
"""Planche de LECTURE — releve le gamma d'une capture pour ouvrir les noirs.

CE QUE C'EST, ET CE QUE CE N'EST PAS.

Ce n'est PAS une capture. C'est une derivee, produite par une operation
documentee et reproductible a partir d'un PNG deja verse comme preuve. La
preuve reste le PNG brut ; cette planche sert uniquement a REGARDER dedans.
Elle va dans un sous-dossier `lecture/`, son nom porte le gamma applique, et
un `.txt` a cote redit tout cela. Elle ne doit jamais etre comptee dans le
lot de captures ni presentee comme un rendu du moteur a cette exposition.

POURQUOI ELLE EXISTE. `tools/godot/check_capture_exposure.gd` mesure
l'ecretage HAUT (blocs 32x32 dont le luma depasse 0,86) et la fluorescence
verte. Il ne mesure RIEN dans les noirs. Or le porche de la grotte est en
« ombre propre » assumee — le lieu l'ecrit noir sur blanc, la bouche etant
a 146 deg du soleil — et la question « son dessous cree-t-il une poche ou
une ombre parasite » se joue precisement la. C'est une limite d'instrument,
pas seulement une gene de lecture.

L'OPERATION. Correction de gamma pure sur les canaux lineaires perçus :
    sortie = 255 * (entree/255) ** (1/gamma)
Aucun recadrage, aucun contraste local, aucune saturation, aucun debruitage.
Un gamma > 1 ouvre les tons sombres. La transformation est monotone : elle
ne peut pas creer un detail absent, seulement rendre visible un detail
present. C'est ce qui la rend admissible comme aide a la lecture.

Le script publie aussi le taux de pixels sous le seuil de lecture AVANT et
APRES, pour que le lecteur sache combien d'image etait effectivement
bouchee.

Usage :
    python3 planche_lecture.py <capture.png> [--gamma=2.2] [--out-dir=...]

Code retour : 0 produit · 2 image illisible · 3 BLOQUE (Pillow absent).
"""
from __future__ import annotations

import argparse
import os
import sys

try:
    from PIL import Image
except ImportError:
    print("BLOQUE : Pillow absent — aucune planche de lecture possible",
          file=sys.stderr)
    raise SystemExit(3)

SEUIL_NOIR = 24 / 255.0   # sous ce luma, un ecran ordinaire ne montre plus rien


def part_bouchee(im: Image.Image) -> float:
    gris = im.convert("L")
    h = gris.histogram()
    total = sum(h) or 1
    sous = sum(h[:int(SEUIL_NOIR * 255) + 1])
    return 100.0 * sous / total


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("capture")
    p.add_argument("--gamma", type=float, default=2.2)
    p.add_argument("--out-dir", default="")
    a = p.parse_args()

    if a.gamma <= 1.0:
        print("BLOQUE : un gamma <= 1 ferme les noirs au lieu de les ouvrir",
              file=sys.stderr)
        return 2
    try:
        src = Image.open(a.capture).convert("RGB")
    except Exception as exc:
        print("image illisible : %s" % exc, file=sys.stderr)
        return 2

    avant = part_bouchee(src)
    table = [min(255, int(round(255.0 * ((i / 255.0) ** (1.0 / a.gamma)))))
             for i in range(256)]
    out = src.point(table * 3)
    apres = part_bouchee(out)

    dossier = a.out_dir or os.path.join(os.path.dirname(
        os.path.abspath(a.capture)), "lecture")
    os.makedirs(dossier, exist_ok=True)
    tige = os.path.splitext(os.path.basename(a.capture))[0]
    nom = "%s_LECTURE_gamma%.2f.png" % (tige, a.gamma)
    chemin = os.path.join(dossier, nom)
    out.save(chemin)

    note = os.path.join(dossier, "%s_LECTURE_gamma%.2f.txt" % (tige, a.gamma))
    with open(note, "w", encoding="utf-8") as f:
        f.write(
            "PLANCHE DE LECTURE — DERIVEE, PAS UNE CAPTURE\n"
            "=============================================\n\n"
            "source        : %s\n"
            "operation     : gamma pur, sortie = 255*(entree/255)**(1/%.4f)\n"
            "               aucun recadrage, aucun contraste local, aucune\n"
            "               saturation, aucun debruitage. Transformation\n"
            "               monotone : ne peut pas creer un detail absent.\n"
            "pixels sous luma %.3f : %.2f %% avant  ->  %.2f %% apres\n\n"
            "STATUT. Cette image n'est PAS un rendu du moteur a cette\n"
            "exposition et ne doit jamais etre comptee dans le lot de\n"
            "captures. La preuve est le PNG source. Cette planche sert a\n"
            "regarder sous le surplomb, la ou `check_capture_exposure.gd`\n"
            "ne mesure rien : il ne voit que l'ecretage HAUT et la\n"
            "fluorescence, jamais des noirs bouches.\n"
            % (os.path.abspath(a.capture), a.gamma, SEUIL_NOIR, avant, apres))

    print("[lecture] %s" % chemin)
    print("[lecture] gamma %.2f — pixels sous luma %.3f : %.2f %% -> %.2f %%"
          % (a.gamma, SEUIL_NOIR, avant, apres))
    print("[lecture] note : %s" % note)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
