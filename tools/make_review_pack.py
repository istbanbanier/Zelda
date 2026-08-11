#!/usr/bin/env python3
"""Paquet de revue d'une capture : vignette, niveaux de gris, mesures.

POURQUOI CE FICHIER. `VISUAL_ASSET_BIBLE` §30.1 impose d'examiner chaque
capture en vignette 320x180, en niveaux de gris et en plein cadre — et le
prompt de reprise du 2026-08-11 exige la même chose pour chaque lot. Ces
dérivées étaient jusqu'ici fabriquées à la main, donc irrégulièrement, donc
pas du tout. `check_value_bands.py` vérifie UNE règle (le sol ne peut pas être
plus clair que le ciel) ; celui-ci produit les IMAGES de revue et les mesures
qui accompagnent une comparaison avant/après.

CE QU'IL NE FAIT PAS. Il ne juge pas. Aucune de ces mesures ne dit qu'une
image est belle : l'écart de valeur entre les tiers dit seulement que trois
plans se DISTINGUENT, pas qu'ils sont bien composés. Le verdict reste à l'œil,
sur un vrai écran (ISS-002).

Usage :
    python3 tools/make_review_pack.py capture.png [capture2.png ...]
    python3 tools/make_review_pack.py capture.png --out-dir=evidence/x

Sorties, à côté de la capture (ou dans --out-dir) :
    <stem>_vignette.png   320x180, pour lire la hiérarchie immédiate
    <stem>_gris.png       niveaux de gris, pour lire les valeurs seules
    <stem>_revue.json     mesures

Codes retour : 0 mesuré · 2 usage/fichier · 3 BLOQUÉ (Pillow absent).
Jamais 0 quand rien n'a pu être mesuré.
"""

import json
import os
import sys

VIGNETTE = (320, 180)
# Trois bandes horizontales de hauteur égale. Ce découpage est grossier et
# assumé : il ne connaît pas la composition, il constate seulement si le haut,
# le milieu et le bas de l'image se ressemblent.
THIRDS = (("haut", 0.00, 0.33), ("milieu", 0.33, 0.66), ("bas", 0.66, 1.00))
# §1.5 : les bandeaux du contrôle de hiérarchie, alignés sur check_value_bands.
SKY_BAND = (0.00, 0.30)
GROUND_BAND = (0.78, 1.00)
STEP = 2


def _luma_samples(image, y0, y1, step):
    width, _ = image.size
    px = image.load()
    out = []
    for y in range(y0, y1, step):
        for x in range(0, width, step):
            r, g, b = px[x, y][:3]
            # Rec. 709 : la même pondération que la conversion en gris ci-dessous,
            # pour que la mesure et l'image de revue racontent la même chose.
            out.append((0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0)
    out.sort()
    return out


def _value_samples(image, y0, y1, step):
    """Valeur HSV (max des canaux) — la grandeur de §1.5."""
    width, _ = image.size
    px = image.load()
    out = []
    for y in range(y0, y1, step):
        for x in range(0, width, step):
            r, g, b = px[x, y][:3]
            out.append(max(r, g, b) / 255.0)
    out.sort()
    return out


def _saturation_mean(image, step):
    width, height = image.size
    px = image.load()
    total = 0.0
    count = 0
    for y in range(0, height, step * 2):
        for x in range(0, width, step * 2):
            r, g, b = px[x, y][:3]
            high = max(r, g, b)
            low = min(r, g, b)
            total += 0.0 if high == 0 else (high - low) / high
            count += 1
    return total / max(1, count)


def _pct(sorted_values, quantile):
    if not sorted_values:
        return 0.0
    index = min(len(sorted_values) - 1,
                max(0, int(round(quantile * (len(sorted_values) - 1)))))
    return sorted_values[index]


def review(path, out_dir=None):
    from PIL import Image

    image = Image.open(path).convert("RGB")
    width, height = image.size
    stem = os.path.splitext(os.path.basename(path))[0]
    directory = out_dir or os.path.dirname(os.path.abspath(path))
    os.makedirs(directory, exist_ok=True)

    vignette_path = os.path.join(directory, "%s_vignette.png" % stem)
    grey_path = os.path.join(directory, "%s_gris.png" % stem)
    json_path = os.path.join(directory, "%s_revue.json" % stem)

    image.resize(VIGNETTE, Image.LANCZOS).save(vignette_path)
    image.convert("L").save(grey_path)

    thirds = {}
    for name, low, high in THIRDS:
        samples = _luma_samples(image, int(low * height), int(high * height), STEP)
        thirds[name] = {
            "p05": round(_pct(samples, 0.05) * 100.0, 1),
            "p50": round(_pct(samples, 0.50) * 100.0, 1),
            "p95": round(_pct(samples, 0.95) * 100.0, 1),
        }

    sky = _value_samples(image, int(SKY_BAND[0] * height),
                         int(SKY_BAND[1] * height), STEP)
    ground = _value_samples(image, int(GROUND_BAND[0] * height),
                            int(GROUND_BAND[1] * height), STEP)
    sky_p50 = _pct(sky, 0.50) * 100.0
    ground_p95 = _pct(ground, 0.95) * 100.0

    report = {
        "source": path,
        "width": width,
        "height": height,
        "vignette": vignette_path,
        "greyscale": grey_path,
        "thirds_luma_pct": thirds,
        # Trois plans distincts (§1.3) : si le haut et le milieu ont la même
        # valeur médiane, l'image n'a pas d'étagement, quoi qu'on ait modélisé.
        "separation_haut_milieu": round(
            abs(thirds["haut"]["p50"] - thirds["milieu"]["p50"]), 1),
        "separation_milieu_bas": round(
            abs(thirds["milieu"]["p50"] - thirds["bas"]["p50"]), 1),
        "sky_p50_value_pct": round(sky_p50, 1),
        "ground_p95_value_pct": round(ground_p95, 1),
        "hierarchy_ok": bool(ground_p95 < sky_p50),
        "saturation_mean": round(_saturation_mean(image, STEP) * 100.0, 1),
    }
    with open(json_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, ensure_ascii=False, sort_keys=True)
    return report


def main(argv):
    paths = []
    out_dir = None
    for arg in argv[1:]:
        if arg.startswith("--out-dir="):
            out_dir = arg[len("--out-dir="):]
        elif arg.startswith("-"):
            print("argument inconnu : %s" % arg, file=sys.stderr)
            return 2
        else:
            paths.append(arg)
    if not paths:
        print(__doc__)
        return 2
    try:
        import PIL  # noqa: F401
    except ImportError:
        print("BLOQUÉ : Pillow absent — `pip install Pillow`", file=sys.stderr)
        return 3
    for path in paths:
        if not os.path.isfile(path):
            print("fichier introuvable : %s" % path, file=sys.stderr)
            return 2
        report = review(path, out_dir)
        print("%-52s haut %5.1f  milieu %5.1f  bas %5.1f  "
              "sep(h-m) %4.1f  ciel_p50 %5.1f  sol_p95 %5.1f  %s"
              % (os.path.basename(path),
                 report["thirds_luma_pct"]["haut"]["p50"],
                 report["thirds_luma_pct"]["milieu"]["p50"],
                 report["thirds_luma_pct"]["bas"]["p50"],
                 report["separation_haut_milieu"],
                 report["sky_p50_value_pct"],
                 report["ground_p95_value_pct"],
                 "hiérarchie OK" if report["hierarchy_ok"] else "HIÉRARCHIE VIOLÉE"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
