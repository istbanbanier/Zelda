#!/usr/bin/env python3
"""Tunique du héros IVOIRE (§13.2) — casse la lecture « archer vert à capuche ».

Deux playtests en boîte noire indépendants ont décrit le héros comme
« visuellement très proche d'un personnage connu d'une autre licence » :
tunique VERTE + capuche + arc au dos. Le vert est la signature du personnage
en question ; la spec §13.2 demande une sous-tunique IVOIRE cassé et un
mantelet turquoise (déjà dérivé par tools/godot/recolor_hero_hood.gd).

Méthode : masque par TEINTE sur la texture déjà dérivée
`T_Ranger_Hero_BaseColor.png` — tout pixel de teinte verte (H 72°..162°,
S > 0,22) est viré vers l'ivoire #D8C8A1 en CONSERVANT sa luminance (les
plis et ombres cuites survivent). La capuche turquoise (H ≈ 186°) est hors
du masque et ne bouge pas. Déterministe, rejouable, manifeste JSON à côté.

Usage : python3 tools/recolor_hero_tunic.py
"""
import hashlib
import json
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image

TEXTURE = Path("assets/characters/hero/T_Ranger_Hero_BaseColor.png")
MANIFEST = Path("assets/characters/hero/T_Ranger_Hero_BaseColor.manifest.json")
# Bande de teinte du tissu vert (degrés HSV).
HUE_MIN, HUE_MAX = 72.0, 162.0
SAT_MIN = 0.22
# Ivoire cassé §1.4 (#D8C8A1) : teinte 33°, saturation basse.
IVORY_HUE = 33.0 / 360.0
IVORY_SAT = 0.24


def main() -> int:
    image = Image.open(TEXTURE).convert("RGBA")
    rgba = np.asarray(image).astype(np.float32) / 255.0
    rgb = rgba[..., :3]
    maxc = rgb.max(axis=-1)
    minc = rgb.min(axis=-1)
    delta = maxc - minc
    sat = np.where(maxc > 0, delta / np.maximum(maxc, 1e-6), 0.0)
    # Teinte (degrés), calcul vectorisé standard.
    hue = np.zeros_like(maxc)
    mask_d = delta > 1e-6
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    rc = np.where(mask_d, (maxc - r) / np.maximum(delta, 1e-6), 0.0)
    gc = np.where(mask_d, (maxc - g) / np.maximum(delta, 1e-6), 0.0)
    bc = np.where(mask_d, (maxc - b) / np.maximum(delta, 1e-6), 0.0)
    hue = np.where(r == maxc, bc - gc,
          np.where(g == maxc, 2.0 + rc - bc, 4.0 + gc - rc))
    hue = (hue / 6.0) % 1.0 * 360.0

    green = (hue >= HUE_MIN) & (hue <= HUE_MAX) & (sat >= SAT_MIN) & mask_d
    count = int(green.sum())
    if count == 0:
        print("aucun pixel vert — rien à faire (déjà dérivé ?)")
        return 0

    # Remplacement : teinte/saturation de l'ivoire, LUMINANCE conservée.
    import colorsys
    v = maxc[green]
    s = np.full_like(v, IVORY_SAT)
    h = np.full_like(v, IVORY_HUE)
    i = np.floor(h * 6.0)
    f = h * 6.0 - i
    p = v * (1.0 - s)
    q = v * (1.0 - f * s)
    t = v * (1.0 - (1.0 - f) * s)
    # h = 0.0917 -> i == 0 partout : rgb = (v, t, p)
    new_rgb = np.stack([v, t, p], axis=-1)
    rgb_out = rgb.copy()
    rgb_out[green] = new_rgb
    out = (np.concatenate([rgb_out, rgba[..., 3:]], axis=-1) * 255.0
           ).round().astype(np.uint8)
    Image.fromarray(out, "RGBA").save(TEXTURE)

    digest = hashlib.sha256(TEXTURE.read_bytes()).hexdigest()
    commit = subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True,
                            text=True).stdout.strip()
    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
    manifest["tunique_ivoire"] = {
        "outil": "tools/recolor_hero_tunic.py",
        "masque": "teinte %g-%g deg, saturation >= %g" % (HUE_MIN, HUE_MAX,
                                                          SAT_MIN),
        "cible": "ivoire #D8C8A1 (teinte 33 deg, sat 0.24), luminance conservee",
        "pixels_modifies": count,
        "sha256_apres": digest,
        "commit_de_derivation": commit,
        "raison": "deux playtests independants lisent la tunique verte comme "
                  "la silhouette d'une licence existante (invariant Nintendo)",
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False))
    print("OK : %d pixels vires a l'ivoire, sha256 %s" % (count, digest[:16]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
