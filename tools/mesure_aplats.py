#!/usr/bin/env python3
"""Mesure la part d'image occupée par des APLATS UNIS beiges.

POURQUOI CET OUTIL EXISTE (R2B.1). Le lead a rejeté la ferme abandonnée pour
une raison qu'aucun contrôle géométrique n'attrape : « se lit comme une boîte
beige inachevée ». Le défaut EST mesurable — les modules `Wall_UnevenBrick_*`
du kit décrivent leur face intérieure par UN quad de 2,00 x 3,00 m en DEUX
triangles, sans aucune face de chant entre la face brique (plan strict
Z = 0,000) et la face plâtre (plan strict Z = -0,200 ; inspection glTF du
2026-08-19). À l'écran, un plan unique produit une surface sans gradient.

SEUIL CALIBRÉ SUR MESURE, jamais choisi au jugé. Distribution du gradient
local (somme des écarts par canal sur 765, voisins à +/- 3 px), relevée sur la
baseline `evidence/world_v2/v2_3_r2b1/avant/` le 2026-08-19 :

    zone                              p10   p50   p75   p90
    panneau beige (plan unique)         4     9    15    28
    mur de pierre texturé               8    44    66    95

Un facteur 5 sépare les deux médianes. SEUIL = 18 retient environ 78 % des
pixels d'un plan et 22 % de ceux d'une pierre texturée ; la connexité fait le
reste, les pixels d'une pierre restant dispersés en îlots sous MIN_COMPOSANTE.

PIÈGE MESURÉ : un premier essai à SEUIL = 7 a rendu 3,08 % sur `ferme_laterale`
là où le panneau occupe visiblement un quart de l'image. Cause : les caméras
R2B.1 sont en plein soleil, et un plan unique sous une directionnelle porte un
gradient LENT mais non nul. Un seuil absolu trop serré mesure l'éclairage, pas
la géométrie.

TROIS SORTIES, dont deux portent le portail du lead et une le sens :
  * `max_pct`        — plus grande composante d'un seul tenant, en % d'écran ;
  * `total_pct`      — somme des composantes retenues, en % d'écran ;
  * `plats_pct_beige`— part de la surface bâtie beige décrite par un plan.
    Celle-ci ne dépend pas du cadrage : c'est la question réellement posée,
    « quelle part du bâti est décrite par un seul plan ? ».

Portail R2B.1 fixé par le lead le 2026-08-19, NON modifié ici :
    max_pct <= 8 % et total_pct <= 12 %.

Usage :
  python3 tools/mesure_aplats.py <image.png> [image2.png ...]
  python3 tools/mesure_aplats.py --json <image.png> ...
"""
import json
import sys
from collections import deque

from PIL import Image

RAYON = 3
SEUIL = 18
MIN_COMPOSANTE = 1500
PORTAIL_MAX_PCT = 8.0
PORTAIL_TOTAL_PCT = 12.0


def est_beige(couleur):
    """Teintes de plâtre, de brique teintée et de terre cuite du lieu."""
    r, v, b = couleur
    return r > 60 and r > v > b and 18 < (r - b) < 110


def mesure(chemin):
    image = Image.open(chemin).convert("RGB")
    largeur, hauteur = image.size
    px = image.load()
    plat = [[False] * hauteur for _ in range(largeur)]
    beige = 0
    plats = 0
    for x in range(RAYON, largeur - RAYON):
        for y in range(RAYON, hauteur - RAYON):
            couleur = px[x, y]
            if not est_beige(couleur):
                continue
            beige += 1
            uni = True
            for dx, dy in ((RAYON, 0), (-RAYON, 0), (0, RAYON), (0, -RAYON)):
                voisin = px[x + dx, y + dy]
                if (abs(couleur[0] - voisin[0]) + abs(couleur[1] - voisin[1])
                        + abs(couleur[2] - voisin[2])) > SEUIL:
                    uni = False
                    break
            if uni:
                plat[x][y] = True
                plats += 1
    vu = [[False] * hauteur for _ in range(largeur)]
    composantes = []
    for x in range(RAYON, largeur - RAYON):
        for y in range(RAYON, hauteur - RAYON):
            if not plat[x][y] or vu[x][y]:
                continue
            attente = deque([(x, y)])
            vu[x][y] = True
            taille = 0
            while attente:
                cx, cy = attente.popleft()
                taille += 1
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1),
                               (cx, cy - 1)):
                    if (RAYON <= nx < largeur - RAYON
                            and RAYON <= ny < hauteur - RAYON
                            and plat[nx][ny] and not vu[nx][ny]):
                        vu[nx][ny] = True
                        attente.append((nx, ny))
            if taille >= MIN_COMPOSANTE:
                composantes.append(taille)
    composantes.sort(reverse=True)
    pixels = largeur * hauteur
    return {
        "image": chemin,
        "pixels": pixels,
        "composantes": len(composantes),
        "max_px": composantes[0] if composantes else 0,
        "max_pct": round(100.0 * (composantes[0] if composantes else 0) / pixels, 2),
        "total_px": sum(composantes),
        "total_pct": round(100.0 * sum(composantes) / pixels, 2),
        "beige_px": beige,
        "plats_px": plats,
        "plats_pct_beige": round(100.0 * plats / max(beige, 1), 1),
    }


def main(argv):
    en_json = "--json" in argv
    chemins = [a for a in argv if not a.startswith("--")]
    if not chemins:
        print("usage: mesure_aplats.py [--json] <image.png> ...", file=sys.stderr)
        return 2
    resultats = [mesure(c) for c in chemins]
    if en_json:
        print(json.dumps({
            "rayon": RAYON, "seuil": SEUIL, "min_composante": MIN_COMPOSANTE,
            "portail_max_pct": PORTAIL_MAX_PCT,
            "portail_total_pct": PORTAIL_TOTAL_PCT,
            "mesures": resultats}, indent=2))
        return 0
    print("%-26s %8s %8s %6s %10s" % ("image", "max %", "total %", "n",
                                      "plat/beige"))
    for r in resultats:
        print("%-26s %8.2f %8.2f %6d %9.1f%%"
              % (r["image"].split("/")[-1], r["max_pct"], r["total_pct"],
                 r["composantes"], r["plats_pct_beige"]))
    print("portail R2B.1 (lead) : max <= %.1f %%, total <= %.1f %%"
          % (PORTAIL_MAX_PCT, PORTAIL_TOTAL_PCT))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
