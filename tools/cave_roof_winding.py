#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""DEDANS OU DEHORS — décidé par le nombre d'enlacement, pas par la parité.

POURQUOI CE TROISIÈME OUTIL EXISTE
==================================

`tools/CLAUDE.md` impose la règle de parité et raconte trois verdicts faux
nés de sa redérivation. La règle y est juste — mais elle a une hypothèse
tacite : **le maillage ne se traverse pas lui-même**.

Or celui-ci se traverse. `controle_repli` du générateur mesure et TOLÈRE un
repli jusqu'à `REPLI_LIVRABLE_MAX_M`, et la colonne verticale en
(0,50 ; 5,80) rend la séquence de normales

    entree, entree, sortie, sortie, entree, entree, sortie, sortie

qui n'alterne pas. Une parité appliquée là compte une région COUVERTE DEUX
FOIS comme si elle était vide. Ce n'est pas une subtilité de convention :
c'est la différence entre 3,8 cm de roche et 3,06 m.

LE NOMBRE D'ENLACEMENT tranche sans hypothèse de non-auto-intersection. On
lance un rayon depuis le point testé et on SOMME les traversées signées
(+1 si la face tourne le dos au rayon, -1 sinon). Pour un maillage fermé et
orienté, le résultat ne dépend PAS de la direction du rayon — et c'est
exactement ce qui en fait une preuve : on le calcule dans plusieurs
directions et on exige l'accord. Si les directions se contredisent, la
question n'a pas de réponse et il faut le dire au lieu de choisir.

Enlacement 0 = dehors. >= 1 = dans la matière. Négatif = normales inversées.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cave_roof_glb import charger, triangles_modele        # noqa: E402

## Directions d'épreuve. Ni axes purs ni symétriques : un axe pur frappe
## trop souvent une arête exactement, et deux directions opposées partagent
## leurs dégénérescences. Celles-ci sont irrationnelles et dispersées.
DIRECTIONS = [
    (0.8017, 0.2673, 0.5345), (-0.4243, 0.8485, 0.3162),
    (0.3015, -0.9045, 0.3015), (-0.5774, -0.5774, 0.5774),
    (0.9177, -0.3058, -0.2547), (-0.2182, 0.4364, -0.8729),
    (0.1690, 0.5071, -0.8452), (-0.8321, -0.2774, -0.4804),
]


def _traverse(orig, dire, a, b, c):
    """Möller-Trumbore. Rend (t, signe) ou None.

    `signe` vaut +1 si la normale géométrique s'oppose au rayon (le rayon
    ENTRE) et -1 sinon (il SORT).
    """
    e1 = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    e2 = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    p = (dire[1] * e2[2] - dire[2] * e2[1],
         dire[2] * e2[0] - dire[0] * e2[2],
         dire[0] * e2[1] - dire[1] * e2[0])
    det = e1[0] * p[0] + e1[1] * p[1] + e1[2] * p[2]
    if abs(det) < 1e-12:
        return None
    inv = 1.0 / det
    s = (orig[0] - a[0], orig[1] - a[1], orig[2] - a[2])
    u = (s[0] * p[0] + s[1] * p[1] + s[2] * p[2]) * inv
    if u < -1e-9 or u > 1.0 + 1e-9:
        return None
    q = (s[1] * e1[2] - s[2] * e1[1],
         s[2] * e1[0] - s[0] * e1[2],
         s[0] * e1[1] - s[1] * e1[0])
    v = (dire[0] * q[0] + dire[1] * q[1] + dire[2] * q[2]) * inv
    if v < -1e-9 or u + v > 1.0 + 1e-9:
        return None
    t = (e2[0] * q[0] + e2[1] * q[1] + e2[2] * q[2]) * inv
    if t < 1e-7:
        return None
    return (t, 1 if det < 0.0 else -1)


def enlacement(triangles, point, directions=DIRECTIONS):
    """Rend (valeur, accord, votes). `accord` est True si toutes les
    directions donnent le même nombre — seul cas où l'on a le droit de
    conclure."""
    votes = []
    for dire in directions:
        total = 0
        for (a, b, c) in triangles:
            r = _traverse(point, dire, a, b, c)
            if r is not None:
                total += r[1]
        votes.append(total)
    accord = len(set(votes)) == 1
    return (votes[0] if accord else None), accord, votes


def main():
    if len(sys.argv) < 3:
        print("usage: cave_roof_winding.py <glb> ax,ay,z [ax,ay,z ...]")
        return 2
    chemin = sys.argv[1]
    # LE FILTRE DE MAILLAGE EST OBLIGATOIRE ICI AUSSI. Sans lui ce script
    # additionnait SM_WaterfallCave et COL_WaterfallCave — la coque de
    # collision, tube plein qui rebouche la galerie. Toutes les
    # verifications d'enlacement faites avant ce correctif portaient donc
    # sur un solide qui n'existe pas. Meme faute que dans `charger()`,
    # trouvee au meme endroit, corrigee au meme moment.
    tris = triangles_modele(chemin, "SM_WaterfallCave")
    _, empreinte, n = charger(chemin)
    print("fichier   : %s" % chemin)
    print("sha256    : %s" % empreinte)
    print("triangles : %d" % n)
    print("directions d'epreuve : %d" % len(DIRECTIONS))
    print()
    faux = 0
    for texte in sys.argv[2:]:
        ax, ay, z = [float(v) for v in texte.split(",")]
        val, accord, votes = enlacement(tris, (ax, ay, z))
        if accord:
            etat = "DANS LA MATIERE" if val >= 1 else (
                "DEHORS (vide)" if val == 0 else "NORMALES INVERSEES")
            print("(%6.2f ; %6.2f ; %6.2f)  enlacement %+d  -> %s"
                  % (ax, ay, z, val, etat))
        else:
            faux += 1
            print("(%6.2f ; %6.2f ; %6.2f)  DESACCORD entre directions : %s"
                  % (ax, ay, z, votes))
            print("      -> la question n'a pas de reponse en ce point ; "
                  "ne rien conclure")
    return 1 if faux else 0


if __name__ == "__main__":
    sys.exit(main())
