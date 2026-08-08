#!/usr/bin/env python3
"""Contrôle des bandes de valeurs de la vue North Star (VISUAL_ASSET_BIBLE §1.5).

Ce que §1.5 impose, et que rien ne vérifiait avant ce fichier :

    Ciel lumineux ........ 75-95 % de valeur
    Sol et roche moyens .. 35-65 %
    Ombres ............... 18-38 %

Une lecture littérale (« aucun pixel de sol au-dessus de 65 % ») échoue : une
poignée de pixels spéculaires et les fleurs blanches montent toujours à 100 %,
et l'herbe ÉCLAIRÉE du plan moyen a le droit d'être claire (§1.4). Le contrôle
porte donc sur la HIÉRARCHIE, qui est ce que §1.5 énonce vraiment :

    le sol ne peut pas être plus clair que le ciel.

Concrètement : le 95e centile de valeur du bandeau bas doit rester SOUS la
médiane du bandeau de ciel. Le 95e centile, pas le maximum — sinon trois pixels
de reflet suffisent à faire échouer une image saine.

Étalonnage, mesuré le 2026-08-08 sur les deux captures d'ISS-037 :

    avant correction : ciel p50 = 83 %, sol p95 = 100 %  -> VIOLATION
    après correction : ciel p50 = 83 %, sol p95 =  74 %  -> conforme

C'est le défaut qui avait survécu à quatre itérations (v0->v3) et à une
évaluation sévère à 58/100, faute d'un test qui le cherche.

Usage :
    python3 tools/check_value_bands.py <capture.png> [--verbose]

Codes retour : 0 conforme · 1 violation · 2 usage/fichier · 3 BLOQUÉ (Pillow
absent). Jamais 0 quand le contrôle n'a pas pu être exécuté.
"""

import sys

# Bandeaux échantillonnés, en fraction de la hauteur d'image. Le cadrage North
# Star (§1.1) place le ciel en haut et le premier plan végétal sur les 22-30 %
# du bas ; ces bornes suivent ce contrat, pas une commodité.
SKY_TOP, SKY_BOTTOM = 0.00, 0.30
GROUND_TOP, GROUND_BOTTOM = 0.78, 1.00
GROUND_PERCENTILE = 0.95
STEP = 2  # échantillonnage : 1 pixel sur 2 en X et en Y


def values(image, y0, y1, step):
    """Valeurs HSV (max des canaux) du bandeau, triées."""
    width = image.size[0]
    out = []
    for y in range(y0, y1, step):
        for x in range(0, width, step):
            r, g, b = image.getpixel((x, y))
            out.append(max(r, g, b) / 255.0)
    out.sort()
    return out


def percentile(sorted_values, quantile):
    if not sorted_values:
        return 0.0
    index = min(len(sorted_values) - 1, int(len(sorted_values) * quantile))
    return sorted_values[index]


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("-")]
    verbose = "--verbose" in argv
    if len(args) != 1:
        print(__doc__)
        return 2

    try:
        from PIL import Image
    except ImportError:
        print("BLOQUÉ: Pillow absent — le contrôle des bandes de valeurs n'a "
              "PAS été exécuté. Installer avec: pip install pillow")
        return 3

    try:
        image = Image.open(args[0]).convert("RGB")
    except OSError as error:
        print("ERREUR: image illisible: %s" % error)
        return 2

    height = image.size[1]
    sky = values(image, int(height * SKY_TOP), int(height * SKY_BOTTOM), STEP)
    ground = values(image, int(height * GROUND_TOP),
                    int(height * GROUND_BOTTOM), STEP)
    if not sky or not ground:
        print("ERREUR: image trop petite pour les deux bandeaux")
        return 2

    sky_median = percentile(sky, 0.50)
    ground_p95 = percentile(ground, GROUND_PERCENTILE)

    if verbose:
        print("  ciel   p50=%3.0f %%  p95=%3.0f %%"
              % (sky_median * 100, percentile(sky, 0.95) * 100))
        print("  sol    p50=%3.0f %%  p95=%3.0f %%  max=%3.0f %%"
              % (percentile(ground, 0.50) * 100, ground_p95 * 100,
                 ground[-1] * 100))

    if ground_p95 >= sky_median:
        print("VIOLATION §1.5: le sol est plus clair que le ciel — "
              "sol p95 = %.0f %% >= ciel p50 = %.0f %%."
              % (ground_p95 * 100, sky_median * 100))
        print("  Le regard ira au sol avant la citadelle (§1.2). Cause "
              "habituelle : une couleur de PALETTE utilisée telle quelle "
              "comme albédo, sans tenir compte du gain lumineux (ISS-037).")
        return 1

    print("OK §1.5: sol p95 = %.0f %% sous ciel p50 = %.0f %%."
          % (ground_p95 * 100, sky_median * 100))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
