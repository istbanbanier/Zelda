#!/usr/bin/env python3
"""Montage A/B R2B.2 → R2B.3, à caméra STRICTEMENT identique.

Le montage n'est une preuve que si les deux panneaux viennent du même plan de
caméra. Cet outil ne se contente donc pas de coller deux images : il lit les
DEUX manifestes, compare `from`, `look` et `fov` champ par champ, et **refuse**
au premier écart. Un A/B dont les caméras ont bougé compare deux mondes, pas
deux états.

Il refuse aussi deux panneaux de tailles différentes — même raison, mesurée en
R2B.2 : un redimensionnement silencieux fabrique une différence visuelle qui
n'est pas dans le jeu.

Usage :
    python3 compose_ab.py <dir_avant> <dir_apres> <dir_sortie>
"""

import json
import os
import sys

from PIL import Image, ImageDraw

BANDE = 26          # hauteur de l'étiquette
MARGE = 8


def plans(dossier):
    with open(os.path.join(dossier, "manifest.json"), encoding="utf-8") as h:
        d = json.load(h)
    return {s["name"]: s for s in d["shots"]}, d


def main():
    if len(sys.argv) != 4:
        sys.stderr.write(__doc__)
        return 2
    d_av, d_ap, d_out = sys.argv[1:4]
    p_av, m_av = plans(d_av)
    p_ap, m_ap = plans(d_ap)
    os.makedirs(d_out, exist_ok=True)

    communs = sorted(set(p_av) & set(p_ap))
    if not communs:
        sys.stderr.write("ECHEC : aucun plan commun aux deux manifestes\n")
        return 1
    manquants = sorted((set(p_av) | set(p_ap)) - set(p_av) & set(p_ap))
    if manquants:
        print("plans présents d'un seul côté, ignorés : %s" % ", ".join(manquants))

    ecarts = []
    for nom in communs:
        a, b = p_av[nom], p_ap[nom]
        for champ in ("from", "look", "fov"):
            if a[champ] != b[champ]:
                ecarts.append("%s.%s : %r != %r" % (nom, champ, a[champ], b[champ]))
    if ecarts:
        sys.stderr.write("ECHEC : les caméras ont bougé — l'A/B ne prouve rien\n")
        for e in ecarts:
            sys.stderr.write("  %s\n" % e)
        return 1
    print("caméras : %d/%d identiques champ par champ" % (len(communs), len(communs)))
    print("AVANT commit %s (dirty=%s) | APRÈS commit %s (dirty=%s)" % (
        m_av.get("commit", "?")[:10], m_av.get("repo_dirty"),
        m_ap.get("commit", "?")[:10], m_ap.get("repo_dirty")))

    for nom in communs:
        ia = Image.open(os.path.join(d_av, "%s.png" % nom)).convert("RGB")
        ib = Image.open(os.path.join(d_ap, "%s.png" % nom)).convert("RGB")
        if ia.size != ib.size:
            sys.stderr.write("ECHEC : %s — tailles %s vs %s\n" % (nom, ia.size, ib.size))
            return 1
        w, h = ia.size
        out = Image.new("RGB", (w * 2 + MARGE, h + BANDE), (18, 18, 20))
        out.paste(ia, (0, BANDE))
        out.paste(ib, (w + MARGE, BANDE))
        d = ImageDraw.Draw(out)
        d.text((6, 7), "R2B.2  —  %s" % nom, fill=(215, 215, 215))
        d.text((w + MARGE + 6, 7), "R2B.3  —  %s" % nom, fill=(215, 215, 215))
        chemin = os.path.join(d_out, "ab_%s.png" % nom)
        out.save(chemin)
        print("  %s" % chemin)
    return 0


if __name__ == "__main__":
    sys.exit(main())
