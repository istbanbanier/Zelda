#!/usr/bin/env python3
"""Compare l'emprise de deux manifestes de silhouette AVANT de composer un A/B.

POURQUOI. `tools/godot/capture_silhouette.gd` n'accepte AUCUN argument de
cadrage — ses neuf arguments sont --scene --out-dir --name --place
--clip-below --provenance --build-frames --angles --size. Le cadrage vient
entierement de :

    boite            = _emprise(sujet)                 # AABB du sujet monte
    largeur_apparente= max(boite.size.x, boite.size.z)
    hauteur_requise  = max(boite.size.y, largeur_apparente * H / W)
    camera.size      = hauteur_requise * (1 + 2*MARGE)  # MARGE est un const

Donc DEUX GEOMETRIES DIFFERENTES SONT CADREES A DEUX ECHELLES DIFFERENTES,
et rien dans l'image ne le dit. Sur l'axe de l'A/B officiel la difference
est reelle : bbox GLB 17,205 x 13,194 x 16,243 (`8bf1a1b3`) contre
16,946 x 11,743 x 15,129 (`cc3596c5`), soit -1,451 m de hauteur (-11,0 %).

Un cadrage automatique EFFACE ce changement de taille au lieu de le
montrer : c'est une regression de preuve. A defaut de pouvoir imposer une
emprise commune, on PUBLIE l'ecart, et la planche le porte.

Ce script ne corrige rien et ne touche a aucun outil du depot. Il lit les
deux manifestes reels, refait le calcul de l'outil, et rend le rapport
d'echelle et le decalage de centre a inscrire sur la planche.

Usage :
    python3 comparer_emprises.py <manifeste_avant.json> <manifeste_apres.json>

Code retour : 0 emprises compatibles (ecart < seuil) · 1 ECART A PUBLIER ·
2 manifeste illisible ou champ absent.
"""
from __future__ import annotations

import json
import sys

MARGE = 0.10          # const de capture_silhouette.gd
ECART_NEGLIGEABLE = 0.005   # 0,5 % — en deca, l'A/B est lisible tel quel


def charger(chemin: str) -> dict:
    with open(chemin, encoding="utf-8") as f:
        return json.load(f)


def taille_camera(emprise: list[float], largeur_px: int, hauteur_px: int) -> float:
    """Refait EXACTEMENT le calcul de `_capturer()`."""
    sx, sy, sz = emprise
    largeur_apparente = max(sx, sz)
    hauteur_requise = max(sy, largeur_apparente * hauteur_px / largeur_px)
    return hauteur_requise * (1.0 + MARGE * 2.0)


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    try:
        av, ap = charger(sys.argv[1]), charger(sys.argv[2])
    except Exception as exc:
        print("BLOQUE : manifeste illisible — %s" % exc, file=sys.stderr)
        return 2

    for nom, m in (("AVANT", av), ("APRES", ap)):
        if "emprise_m" not in m:
            print("BLOQUE : `emprise_m` absent du manifeste %s — ce n'est pas "
                  "une sortie de capture_silhouette.gd" % nom, file=sys.stderr)
            return 2

    px = {}
    for nom, m in (("AVANT", av), ("APRES", ap)):
        w, h = (int(v) for v in str(m.get("size", "900x1200")).split("x"))
        px[nom] = (w, h)
    if px["AVANT"] != px["APRES"]:
        print("BLOQUE : resolutions differentes %s vs %s — un A/B n'a de sens "
              "qu'a cadre identique" % (px["AVANT"], px["APRES"]), file=sys.stderr)
        return 2
    w, h = px["AVANT"]

    ea, eb = av["emprise_m"], ap["emprise_m"]
    ca = taille_camera(ea, w, h)
    cb = taille_camera(eb, w, h)
    rapport = cb / ca if ca else float("nan")
    ecart = abs(rapport - 1.0)

    print("=== EMPRISES MONTEES (AABB du lieu, props compris) ===")
    print("  AVANT  %8.3f x %8.3f x %8.3f m   clip_below=%s   %s"
          % (ea[0], ea[1], ea[2], av.get("clip_below"),
             av.get("preuve", {}).get("geometrie", {}).get("sha256_court", "?")))
    print("  APRES  %8.3f x %8.3f x %8.3f m   clip_below=%s   %s"
          % (eb[0], eb[1], eb[2], ap.get("clip_below"),
             ap.get("preuve", {}).get("geometrie", {}).get("sha256_court", "?")))
    print()
    print("=== CADRAGE ORTHO RECALCULE (formule de l'outil) ===")
    print("  camera.size AVANT : %.4f m" % ca)
    print("  camera.size APRES : %.4f m" % cb)
    print("  RAPPORT D'ECHELLE : %.4f  (le sujet APRES parait %+.2f %% "
          "par rapport a AVANT)" % (rapport, (rapport - 1.0) * 100.0))
    print()
    print("  Ce rapport est le facteur d'echelle a INSCRIRE SUR LA PLANCHE.")
    print("  Le sujet n'a pas change de taille de ce facteur : c'est la")
    print("  CAMERA qui a change, parce qu'elle se cadre sur l'AABB.")
    print()
    if ecart <= ECART_NEGLIGEABLE:
        print("VERDICT : ecart <= %.1f %%, l'A/B est lisible tel quel."
              % (ECART_NEGLIGEABLE * 100))
        print("          Publier quand meme les deux emprises a cote.")
        return 0
    print("VERDICT : ECART A PUBLIER — %.2f %%. Inscrire le rapport et les"
          % (ecart * 100))
    print("          deux emprises sur la planche, en clair.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
