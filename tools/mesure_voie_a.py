#!/usr/bin/env python3
"""Mesure des zones de calibration de la voie A (belvédère, source).

POURQUOI CET OUTIL. Le contrat du lot exige, pour la source, une eau
« turquoise PERÇUE DANS LE RENDU — calibrée contre une référence d'eau V2.2
dans le même moteur, même exposition, avec mesure avant/après ; jamais
seulement l'albédo ». Une mesure faite à la main dans un shell n'est ni
reproductible ni relisible : elle vit ici, avec ses fenêtres nommées.

CE QUE CET OUTIL N'EST PAS. Les nombres qu'il rend sont des repères de
CALIBRATION — ils disent dans quel sens tourner un levier et permettent un
avant/après honnête. Ce ne sont PAS des seuils de gate : aucun contrat du
projet ne porte de plancher de saturation. Le verdict artistique appartient
au lead et au propriétaire.

Deux précautions mesurées :
  * on publie la TAILLE de chaque fenêtre (« n=... »). Un « aucune
    différence » sans « sur N pixels » ne prouve rien (tools/CLAUDE.md) ;
  * on refuse une fenêtre vide ou hors image plutôt que de rendre une
    moyenne sur zéro pixel.

Usage :
  python3 tools/mesure_voie_a.py <dossier_de_captures> [<dossier_avant>]
"""
import colorsys
import os
import sys

from PIL import Image

# vue | libellé | fenêtre (gauche, haut, droite, bas) en pixels d'une image
# 1280×720. Les fenêtres sont posées sur des zones NOMMÉES, pas sur « la
# partie qui arrange » : elles restent identiques entre l'avant et l'après.
FENETRES = [
    ("overlook_summit_identite", "belvedere masse (soleil)", (590, 250, 700, 330)),
    # FENETRE CORRIGEE (meme faute que celle de la riviere, trouvee de la
    # meme facon) : (710,290,780,370) tombait sur la FALAISE V2.2 du fond, et
    # rendait donc exactement la meme valeur avant et apres chaque changement
    # — un « delta 0,000 » parfaitement stable qui ne mesurait pas le sujet.
    # Reposee sur l'eperon apres verification a l'oeil sur l'image.
    ("overlook_summit_identite", "belvedere eperon", (310, 288, 375, 350)),
    ("overlook_summit_identite", "falaise V2.2 (fond, reference)", (950, 60, 1100, 220)),
    ("overlook_summit_identite", "herbe du sommet", (400, 420, 600, 520)),
    ("overlook_summit_joueur", "belvedere masse proche", (880, 190, 1140, 320)),
    ("turquoise_spring_joueur", "EAU camera joueur (GELEE)", (560, 378, 740, 398)),
    ("turquoise_spring_identite", "eau vasque", (505, 352, 640, 385)),
    ("turquoise_spring_identite", "RIVIERE V2.2 (reference)", (930, 470, 1230, 555)),
    ("spring_gros_eau", "eau gros plan", (430, 300, 850, 430)),
    # FENETRE CORRIGEE. La premiere (430,330,900,520) tombait sur l'HERBE de
    # la rive gauche et rendait H=122 deg : une « reference d'eau » qui mesurait
    # de la prairie. C'est la meme famille qu'ISS-018 — un chiffre juste sur la
    # mauvaise chose. Verifie a l'oeil sur l'image avant d'etre repose ici.
    ("spring_gue_riviere", "RIVIERE V2.2 au gue (reference)", (600, 640, 860, 715)),
    ("spring_gue_riviere", "RIVIERE V2.2 au gue, amont", (830, 470, 930, 560)),
]


def mesure(chemin, boite):
    image = Image.open(chemin).convert("RGB")
    largeur, hauteur = image.size
    g, h, d, b = boite
    if largeur != 1280 or hauteur != 720:
        # Les fenêtres sont posées en 1280×720 : on les met à l'échelle plutôt
        # que de mesurer ailleurs sans le dire.
        fx, fy = largeur / 1280.0, hauteur / 720.0
        g, h, d, b = int(g * fx), int(h * fy), int(d * fx), int(b * fy)
    if d <= g or b <= h or d > largeur or b > hauteur:
        return None
    pixels = list(image.crop((g, h, d, b)).getdata())
    n = len(pixels)
    if n == 0:
        return None
    r = sum(p[0] for p in pixels) / n
    v = sum(p[1] for p in pixels) / n
    bl = sum(p[2] for p in pixels) / n
    teinte, sat, val = colorsys.rgb_to_hsv(r / 255, v / 255, bl / 255)
    return n, r, v, bl, teinte * 360, sat, val


def lot(dossier):
    resultats = {}
    for vue, libelle, boite in FENETRES:
        chemin = os.path.join(dossier, vue + ".png")
        if not os.path.exists(chemin):
            continue
        m = mesure(chemin, boite)
        if m is None:
            print("  REFUS : fenetre invalide pour %s / %s" % (vue, libelle))
            continue
        resultats[(vue, libelle)] = m
    return resultats


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    apres = lot(sys.argv[1])
    avant = lot(sys.argv[2]) if len(sys.argv) > 2 else {}
    if not apres:
        print("ECHEC : aucune fenetre mesuree dans %s" % sys.argv[1])
        return 2
    entete = "%-30s %-34s %7s %-22s %6s %6s %6s"
    print(entete % ("vue", "zone", "n", "RGB", "H", "S", "V"))
    for (vue, libelle), m in apres.items():
        n, r, v, b, teinte, sat, val = m
        print(entete % (vue, libelle, n,
                        "(%5.1f,%5.1f,%5.1f)" % (r, v, b),
                        "%6.1f" % teinte, "%.3f" % sat, "%.3f" % val))
        if (vue, libelle) in avant:
            n0, r0, v0, b0, t0, s0, val0 = avant[(vue, libelle)]
            print(entete % ("", "  ^ AVANT (n=%d)" % n0, "",
                            "(%5.1f,%5.1f,%5.1f)" % (r0, v0, b0),
                            "%6.1f" % t0, "%.3f" % s0, "%.3f" % val0))
            print(entete % ("", "  ^ DELTA", "", "",
                            "%+6.1f" % (teinte - t0), "%+.3f" % (sat - s0),
                            "%+.3f" % (val - val0)))
    print("\n%d fenetre(s) mesuree(s) dans %s%s"
          % (len(apres), sys.argv[1],
             (", %d comparee(s) a %s" % (len(avant), sys.argv[2]))
             if avant else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
