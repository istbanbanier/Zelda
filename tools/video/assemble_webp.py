#!/usr/bin/env python3
"""Lot 3 — assemblage de la séquence Movie Maker en WebP animé.

Pas de ffmpeg dans le conteneur ; PIL sait écrire du WebP animé
(vérifié : features.check('webp') == True). Entrée : les
frameNNNNNNNN.png écrits par --write-movie ; sortie : un .webp animé
à la cadence fixe de la capture, réduit à 640x360 pour tenir dans le
dépôt, plus une bande de 4 images-clés pleines pour l'examen fixe.
"""
import sys
import glob
from PIL import Image

def main() -> int:
    if len(sys.argv) != 4:
        print("usage: assemble_webp.py <frames_dir/prefix> <out.webp> <fps>")
        return 2
    prefix, out, fps = sys.argv[1], sys.argv[2], int(sys.argv[3])
    paths = sorted(glob.glob(prefix + "*.png"))
    if len(paths) < 24:
        print(f"ECHEC: {len(paths)} frames — séquence trop courte")
        return 1
    duration_ms = round(1000 / fps)
    frames = []
    for p in paths:
        img = Image.open(p).convert("RGB")
        frames.append(img.resize((640, 360), Image.LANCZOS))
    frames[0].save(
        out, save_all=True, append_images=frames[1:],
        duration=duration_ms, loop=0, method=4, quality=78)
    # Bande d'images-clés : arrêt initial / fin de marche / fin de
    # sprint / milieu de rotation, en pleine résolution de capture.
    keys = [len(paths) * 3 // 36, len(paths) * 9 // 18,
            len(paths) * 13 // 18, len(paths) * 31 // 36]
    strip = Image.new("RGB", (960 * 2, 540 * 2))
    for i, k in enumerate(keys):
        img = Image.open(paths[k]).convert("RGB").resize((960, 540))
        strip.paste(img, ((i % 2) * 960, (i // 2) * 540))
    strip_path = out.rsplit(".", 1)[0] + "_cles.png"
    strip.save(strip_path)
    secs = len(paths) / fps
    print(f"OK: {out} ({len(paths)} frames, {secs:.1f} s @ {fps} fps) "
          f"+ {strip_path}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
