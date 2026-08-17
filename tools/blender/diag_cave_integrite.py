#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""A QUELLE ETAPE NAIT CHAQUE DEFAUT D'INTEGRITE ? — attribution rejouee.

POURQUOI CE SCRIPT EXISTE
=========================
L'attribution heritee de la passe precedente dit : le repli nait a la
DECIMATION, le triangle d'aire nulle nait a la SOUSTRACTION. Ces deux
phrases ont ete mesurees sur `cc3596c5`, pas sur le socle courant, et avec
l'instrument dont B1 vient de montrer qu'il sous-compte (2 annoncees, 6
reelles ; 0 annoncee sur R2a-3.4, 10 reelles).

Une attribution obtenue avec un compteur aveugle doit etre rejouee avec un
compteur qui voit. C'est ce que fait ce script.

CE QU'IL NE TOUCHE PAS
======================
Il ne modifie pas une ligne du generateur. Il le CHARGE comme module — donc
sans declencher `main()`, qui ne part que sous `__name__ == "__main__"` —,
enveloppe les fonctions d'etape pour mesurer juste apres leur passage, puis
appelle `main()`. La sequence executee est exactement celle du generateur :
aucune cote, aucun seuil, aucun parametre de decimation n'est modifie.

LE BUDGET, ET POURQUOI IL EST HONNETE
=====================================
Le verdict exact sur 136 428 triangles couterait des heures. On mesure donc :

  * les aires EXACTEMENT nulles a CHAQUE etape, sans exception — le calcul
    est lineaire, il n'y a aucune raison de s'en priver ;
  * les penetrations exactes dans les REGIONS D'INTERET a chaque etape,
    c'est-a-dire aux endroits ou B1 a localise les defauts ;
  * les penetrations exactes sur TOUT le maillage aux etapes legeres.

Une region d'interet ne peut pas faire apparaitre un defaut qui n'existe
pas ; elle peut seulement en rater un ailleurs. On le dit au lieu de laisser
croire a une couverture totale.

`retirer_bulles` est appele DEUX fois par la chaine — apres remaillage et
apres soustraction. Les appels sont numerotes, sans quoi la seconde mesure
ecraserait la premiere en silence.
"""

import os
import sys
import types

import bpy

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.dirname(ICI)
sys.path.insert(0, os.path.join(RACINE))          # pour tools/
sys.path.insert(0, os.path.dirname(RACINE))       # racine du worktree

from cave_exact_intersect import (aire_double_carree, classer_paire,   # noqa
                                  en_fractions, paires_candidates)

SOURCE = os.path.join(os.path.dirname(RACINE), "source_assets", "blender",
                      "environment", "make_waterfall_cave.py")

## Les regions ou B1 a localise les defauts, en REPERE BLENDER. Le GLB est
## en Y-up : (x, y, z)_blender -> (x, z, -y)_gltf. On travaille ici du cote
## Blender, donc on convertit les centres publies par B1.
REGIONS = (
    ("amas A", (0.28, -2.24, 1.78), 0.80),
    ("amas B", (2.20, -2.20, -0.68), 1.00),
    ("face nulle", (-1.504, -3.099, -0.639), 0.80),
)

## Au-dela, on ne fait que les aires nulles et les regions.
PLAFOND_GLOBAL = 26000


def _sommets_et_tris(maillage):
    """Triangule en eventail. Les faces de la chaine sont des triangles ou
    des n-gones convexes issus de `holes_fill` ; l'eventail est exact pour
    les premiers et suffisant pour localiser les seconds."""
    sommets = [tuple(v.co) for v in maillage.vertices]
    tris = []
    for poly in maillage.polygons:
        idx = list(poly.vertices)
        for k in range(1, len(idx) - 1):
            tris.append((idx[0], idx[k], idx[k + 1]))
    return sommets, tris


def _dans_region(sommets, tri, centre, rayon):
    for i in tri:
        p = sommets[i]
        if (abs(p[0] - centre[0]) <= rayon and abs(p[1] - centre[1]) <= rayon
                and abs(p[2] - centre[2]) <= rayon):
            return True
    return False


def mesurer(etiquette, obj):
    maillage = obj.data
    sommets, tris = _sommets_et_tris(maillage)
    frac = en_fractions(sommets)

    nulles = []
    for indice, tri in enumerate(tris):
        if aire_double_carree([frac[i] for i in tri]) == 0:
            nulles.append(indice)

    print("[integrite] --- %s : %d sommets, %d tris" % (etiquette,
                                                        len(sommets),
                                                        len(tris)))
    print("[integrite]     aire EXACTEMENT nulle : %d" % len(nulles))
    for indice in nulles[:6]:
        pts = [sommets[i] for i in tris[indice]]
        centre = tuple(sum(p[k] for p in pts) / 3.0 for k in range(3))
        aretes = []
        for k in range(3):
            a, b = pts[k], pts[(k + 1) % 3]
            aretes.append(sum((a[j] - b[j]) ** 2 for j in range(3)) ** 0.5)
        print("[integrite]       nulle en (%.4f, %.4f, %.4f)  aretes "
              "%.6f/%.6f/%.6f m" % (centre + tuple(aretes)))

    if len(tris) <= PLAFOND_GLOBAL:
        total = 0
        for a, b in paires_candidates(sommets, tris, 0.25):
            verdict, _ = classer_paire([frac[i] for i in tris[a]],
                                       [frac[i] for i in tris[b]])
            if verdict == "PENETRATION":
                total += 1
        print("[integrite]     PENETRATIONS (maillage entier) : %d" % total)
    else:
        print("[integrite]     PENETRATIONS (maillage entier) : non mesure "
              "(%d tris > plafond %d)" % (len(tris), PLAFOND_GLOBAL))

    for nom, centre, rayon in REGIONS:
        locaux = [i for i, t in enumerate(tris)
                  if _dans_region(sommets, t, centre, rayon)]
        if not locaux:
            print("[integrite]     region %-11s : aucun triangle" % nom)
            continue
        sous = [tris[i] for i in locaux]
        compte = 0
        for a, b in paires_candidates(sommets, sous, 0.25):
            verdict, _ = classer_paire([frac[i] for i in sous[a]],
                                       [frac[i] for i in sous[b]])
            if verdict == "PENETRATION":
                compte += 1
        print("[integrite]     region %-11s : %d tris, %d penetration(s)"
              % (nom, len(locaux), compte))
    sys.stdout.flush()


def main():
    module = types.ModuleType("make_waterfall_cave")
    module.__file__ = SOURCE
    with open(SOURCE, "r", encoding="utf-8") as flux:
        code = flux.read()
    ## `DIAGNOSTIC` est evalue A L'IMPORT, pas dans `main()`. Positionner
    ## `sys.argv` apres l'exec ne servirait donc a rien, et la chaine
    ## s'arreterait au premier portail rouge sans le dire clairement.
    sys.argv = ["make_waterfall_cave.py", "--", "--diagnostic"]
    exec(compile(code, SOURCE, "exec"), module.__dict__)

    compteurs = {}

    def envelopper(nom):
        original = getattr(module, nom)

        def enveloppe(*args, **kwargs):
            resultat = original(*args, **kwargs)
            compteurs[nom] = compteurs.get(nom, 0) + 1
            cible = resultat if isinstance(resultat, bpy.types.Object) \
                else (args[0] if args and isinstance(args[0], bpy.types.Object)
                      else None)
            if cible is not None:
                mesurer("%s #%d" % (nom, compteurs[nom]), cible)
            return resultat
        setattr(module, nom, enveloppe)

    for nom in ("joindre", "remailler_voxel", "retirer_bulles", "stratifier",
                "decimer", "soustraire"):
        envelopper(nom)

    code_retour = module.main()
    print("[integrite] main() rend %s" % code_retour)
    return 0


if __name__ == "__main__":
    sys.exit(main())
