#!/usr/bin/env python3
"""Contrôle des bandes de valeurs (VISUAL_ASSET_BIBLE §1.5) — deux modes.

MODE HISTORIQUE (inchangé) — hiérarchie North Star :

    python3 tools/check_value_bands.py <capture.png> [--verbose]

    le 95e centile de valeur du bandeau bas doit rester SOUS la médiane du
    bandeau de ciel. Consommé par `validate_release.sh` (étape 5b) et
    `capture_vslice_gate.sh` : ses codes retour (0 conforme · 1 violation ·
    2 usage/fichier · 3 BLOQUÉ) et sa sortie ne changent pas.

MODE CROP NOMMÉ (V2.3-A.R2B, agent C) — bande de valeur d'une zone :

    python3 tools/check_value_bands.py <capture.png> \\
        --crop=margelle:0.25,0.45,0.75,0.80 \\
        --p50-min=35 --p50-max=65 --p90-max=70 [--verbose]

    Chaque `--crop=nom:x0,y0,x1,y1` (coordonnées NORMALISÉES 0..1, origine en
    haut à gauche) est mesuré : p50 et p90 de la VALEUR (max des canaux RGB,
    la même grandeur que le mode historique et que §1.5 — pas une luminance
    pondérée, pour que les deux modes parlent le même chiffre). Les seuils
    viennent des ARGUMENTS, jamais du code : la commande archivée dans le
    journal dit exactement ce qui a été exigé.

    Codes retour du mode crop : 0 conforme · 1 violation · 3 BLOQUÉ
    (Pillow absent, image illisible, crop invalide ou vide). Jamais 0 quand
    la mesure n'a pas eu lieu.

    JETON `FIN NOMINALE` : imprimé en DERNIÈRE ligne quand la mesure a été
    réellement exécutée (verdict 0 ou 1). Convention du dépôt
    (`tools/CLAUDE.md`) : la preuve de succès est écrite par l'outil surveillé
    lui-même — un RC avalé par un tube ou une enveloppe ne prouve rien.

NOTE DE PROVENANCE : ce fichier existait déjà (commit 5f27c31) quand la
mission R2B a demandé de « l'écrire » ; le mode historique est conservé tel
quel, le mode crop est AJOUTÉ. Écraser l'outil §1.5 aurait cassé
`validate_release.sh` sans que rien ne rougisse avant la release.
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


def crop_values(image, x0, y0, x1, y1, step):
    """Valeurs HSV (max des canaux) d'un rectangle normalisé, triées."""
    width, height = image.size
    px0, px1 = int(width * x0), int(width * x1)
    py0, py1 = int(height * y0), int(height * y1)
    out = []
    for y in range(py0, py1, step):
        for x in range(px0, px1, step):
            r, g, b = image.getpixel((x, y))
            out.append(max(r, g, b) / 255.0)
    out.sort()
    return out


def percentile(sorted_values, quantile):
    if not sorted_values:
        return 0.0
    index = min(len(sorted_values) - 1, int(len(sorted_values) * quantile))
    return sorted_values[index]


def parse_crop(spec):
    """`nom:x0,y0,x1,y1` -> (nom, x0, y0, x1, y1) ou None si invalide."""
    if ":" not in spec:
        return None
    name, _, coords = spec.partition(":")
    parts = coords.split(",")
    if not name or len(parts) != 4:
        return None
    try:
        x0, y0, x1, y1 = (float(p) for p in parts)
    except ValueError:
        return None
    if not (0.0 <= x0 < x1 <= 1.0 and 0.0 <= y0 < y1 <= 1.0):
        return None
    return (name, x0, y0, x1, y1)


def parse_threshold(argv, flag):
    """Valeur de `--flag=N` (en %), ou None si absent."""
    prefix = "--%s=" % flag
    for arg in argv:
        if arg.startswith(prefix):
            try:
                return float(arg[len(prefix):])
            except ValueError:
                print("BLOQUÉ: seuil illisible: %s" % arg)
                return "invalid"
    return None


def run_crop_mode(argv, image_path, crop_specs):
    """Mode crop nommé. RC 0 conforme / 1 violation / 3 BLOQUÉ."""
    verbose = "--verbose" in argv
    p50_min = parse_threshold(argv, "p50-min")
    p50_max = parse_threshold(argv, "p50-max")
    p90_max = parse_threshold(argv, "p90-max")
    if "invalid" in (p50_min, p50_max, p90_max):
        return 3
    if p50_min is None and p50_max is None and p90_max is None:
        print("BLOQUÉ: mode crop sans aucun seuil (--p50-min/--p50-max/"
              "--p90-max) — une mesure sans exigence ne juge rien.")
        return 3

    crops = []
    for spec in crop_specs:
        parsed = parse_crop(spec)
        if parsed is None:
            print("BLOQUÉ: crop invalide: %s (attendu nom:x0,y0,x1,y1 "
                  "normalisés, x0<x1, y0<y1)" % spec)
            return 3
        crops.append(parsed)

    try:
        from PIL import Image
    except ImportError:
        print("BLOQUÉ: Pillow absent — la mesure de bande de valeur n'a PAS "
              "été exécutée. Installer avec: pip install pillow")
        return 3
    try:
        image = Image.open(image_path).convert("RGB")
    except OSError as error:
        print("BLOQUÉ: image illisible: %s" % error)
        return 3

    violations = 0
    for name, x0, y0, x1, y1 in crops:
        sample = crop_values(image, x0, y0, x1, y1, STEP)
        if not sample:
            print("BLOQUÉ: crop « %s » vide (%.2f,%.2f)-(%.2f,%.2f) sur "
                  "%d×%d px" % (name, x0, y0, x1, y1, *image.size))
            return 3
        p50 = percentile(sample, 0.50) * 100.0
        p90 = percentile(sample, 0.90) * 100.0
        # La taille de l'échantillon est PUBLIÉE : un verdict sans « sur N
        # pixels » ne prouve rien (tools/CLAUDE.md, règle du diff vide).
        print("crop %-12s (%.2f,%.2f)-(%.2f,%.2f)  p50=%5.1f %%  "
              "p90=%5.1f %%  (%d px échantillonnés)"
              % (name, x0, y0, x1, y1, p50, p90, len(sample)))
        if verbose:
            print("  min=%.1f %%  p95=%.1f %%  max=%.1f %%"
                  % (sample[0] * 100.0, percentile(sample, 0.95) * 100.0,
                     sample[-1] * 100.0))
        if p50_min is not None and p50 < p50_min:
            print("VIOLATION %s: p50 = %.1f %% < plancher %.1f %% — la zone "
                  "est plus sombre que la bande exigée." % (name, p50, p50_min))
            violations += 1
        if p50_max is not None and p50 > p50_max:
            print("VIOLATION %s: p50 = %.1f %% > plafond %.1f %% — la zone "
                  "est plus claire que la bande exigée." % (name, p50, p50_max))
            violations += 1
        if p90_max is not None and p90 > p90_max:
            print("VIOLATION %s: p90 = %.1f %% > plafond %.1f %% — les "
                  "hautes valeurs de la zone débordent la bande."
                  % (name, p90, p90_max))
            violations += 1

    verdict = 1 if violations else 0
    if verdict == 0:
        print("OK bandes: %d crop(s) dans les seuils demandés." % len(crops))
    else:
        print("ÉCHEC bandes: %d violation(s) sur %d crop(s)."
              % (violations, len(crops)))
    # Le jeton dit « la mesure a eu lieu jusqu'au bout », pas « c'est bon » :
    # il sort sur 0 COMME sur 1 — jamais sur un BLOQUÉ.
    print("FIN NOMINALE")
    return verdict


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("-")]
    crop_specs = [a[len("--crop="):] for a in argv[1:]
                  if a.startswith("--crop=")]
    verbose = "--verbose" in argv
    if len(args) != 1:
        print(__doc__)
        return 3 if crop_specs else 2

    if crop_specs:
        return run_crop_mode(argv, args[0], crop_specs)

    # ------------------------------------------------------------------
    # MODE HISTORIQUE — inchangé (validate_release.sh, capture_vslice_gate.sh).
    # ------------------------------------------------------------------
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
