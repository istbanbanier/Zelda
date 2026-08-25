#!/usr/bin/env python3
"""Part de cadre occupée par l'eau turquoise, et sa boîte — sur une capture.

BANDE CALIBRÉE SUR LA CAPTURE DE RÉFÉRENCE, pas devinée. Échantillons pris
sur `lot1r1/revue_intermediaire/vues/turquoise_spring_joueur.png` :

  eau de la vasque   H 189–192   S 0,54    V 0,45–0,49
  fil du déversoir   H 185       S 0,51    V 0,45
  herbe du pad       H 135–149   S 0,25–0,28
  roche des masses   H 213       S 0,28    V 0,38–0,40
  ciel (brume)       H 180       S 0,04    V 0,27

Une bande large (H 150–212, S ≥ 0,20) attrapait l'HERBE ENTIÈRE et rendait
« 21 % du cadre » : un compteur qui mesure autre chose que ce qu'il nomme est
exactement le défaut d'ISS-018. La bande retenue — H 180–205 et S ≥ 0,40 —
exclut l'herbe (S trop bas ET H trop bas), la roche (H trop haut) et le ciel
(S 0,04), et ne peut donc pas gonfler le chiffre avec du décor.

Ce que l'outil fait : il classe en « eau » les pixels de cette bande, puis
rend leur nombre, leur part du cadre, leur boîte englobante et leur teinte
moyenne. Il ne juge RIEN : il compte.

CE QU'IL PEUT ATTRAPER DE TRAVERS, ET IL FAUT LE SAVOIR : la rivière V2.2
visible au loin, ou un ciel très bleu, tombent dans la même bande. D'où
`--zone` — on restreint le compte à un rectangle de l'image, et on l'écrit
dans le rapport.

Il PEUT rougir : sur une image sans un pixel turquoise il rend 0, et le
compare au seuil passé par `--min-part`.

Usage :
  python3 mesurer_eau.py capture.png [--zone x0,y0,x1,y1] [--min-part 0.0]
"""
import sys
from PIL import Image
import colorsys


def mesurer(chemin, zone=None):
    im = Image.open(chemin).convert("RGB")
    W, H = im.size
    x0, y0, x1, y1 = zone if zone else (0, 0, W, H)
    px = im.load()
    n = 0
    bx0, by0, bx1, by1 = W, H, -1, -1
    sh = sv = ss = 0.0
    colonnes = {}
    for y in range(y0, y1):
        for x in range(x0, x1):
            r, g, b = (c / 255.0 for c in px[x, y])
            h, s, v = colorsys.rgb_to_hsv(r, g, b)
            hd = h * 360.0
            if 180.0 <= hd <= 205.0 and s >= 0.40 and v >= 0.18:
                n += 1
                sh += hd
                ss += s
                sv += v
                bx0, by0 = min(bx0, x), min(by0, y)
                bx1, by1 = max(bx1, x), max(by1, y)
                colonnes[x] = colonnes.get(x, 0) + 1
    aire = (x1 - x0) * (y1 - y0)
    r = {"fichier": chemin, "zone": [x0, y0, x1, y1], "pixels": n,
         "part_zone_pct": 100.0 * n / max(aire, 1),
         "part_cadre_pct": 100.0 * n / (W * H)}
    if n:
        r["boite"] = [bx0, by0, bx1, by1]
        r["largeur_px"] = bx1 - bx0 + 1
        r["hauteur_px"] = by1 - by0 + 1
        r["H_moy"] = sh / n
        r["S_moy"] = ss / n
        r["V_moy"] = sv / n
        r["colonne_max_px"] = max(colonnes.values())
    return r


if __name__ == "__main__":
    args = sys.argv[1:]
    zone = None
    seuil = -1.0
    fichiers = []
    i = 0
    while i < len(args):
        if args[i] == "--zone":
            zone = tuple(int(v) for v in args[i + 1].split(","))
            i += 2
        elif args[i] == "--min-part":
            seuil = float(args[i + 1])
            i += 2
        else:
            fichiers.append(args[i])
            i += 1
    code = 0
    for f in fichiers:
        r = mesurer(f, zone)
        print("%s" % r["fichier"])
        print("  zone %s  pixels d'eau %d  = %.2f %% de la zone, "
              "%.2f %% du cadre" % (r["zone"], r["pixels"],
                                    r["part_zone_pct"], r["part_cadre_pct"]))
        if r["pixels"]:
            print("  boite %s  (%d x %d px)  colonne la plus haute %d px"
                  % (r["boite"], r["largeur_px"], r["hauteur_px"],
                     r["colonne_max_px"]))
            print("  H %.1f deg  S %.3f  V %.3f"
                  % (r["H_moy"], r["S_moy"], r["V_moy"]))
        if seuil >= 0.0 and r["part_cadre_pct"] < seuil:
            print("  ECHEC : %.2f %% < seuil %.2f %%"
                  % (r["part_cadre_pct"], seuil))
            code = 1
    sys.exit(code)
