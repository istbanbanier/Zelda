#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""EMPRISE RÉELLE de `OUTIL_Cavite` — la sonde qui tranche une contradiction.

LA CONTRADICTION
================

`CAVITE` s'arrête à la station `(3,58 ; 3,17)` et `CAVITE_APEX` à
`(3,72 ; 3,25 ; 0,70)`. Le tube ne devrait donc rien creuser au-delà de
`ay ≈ 4,3`, marge prise pour l'inclinaison des sections. Or la différence
de colonne entre `etape_3_decime.glb` et `etape_4_soustrait.glb` montre du
creusement jusqu'à `ay ≈ 7,0`, et c'est ce creusement qui met le plafond du
vide à 4 cm sous le sommet du massif en `(0,55 ; 5,95)` — la percée.

Deux lectures possibles, et il faut choisir par la mesure et non par
l'intuition : ou bien l'outil est réellement plus long qu'il n'en a l'air,
ou bien ma différence de colonnes se trompe. On mesure donc l'outil
lui-même, avant tout booléen.

CE QU'IL FAIT
=============

Charge le générateur comme module — sans déclencher `main()` —, appelle
`cavite_solide()` avec les arguments exacts de `main()`, construit l'objet,
et publie : boîte englobante, volume, et le profil vertical de l'outil aux
mêmes points témoins que `cave_fix_etapes.py`. Aucune écriture dans le
générateur.

Usage (Blender, sous verrou d'outil lourd) :
    flock /home/user/Zelda/.git/heavy_tools.lock -c \\
      'cd <worktree> && blender --background \\
       --python-exit-code 1 --python tools/cave_fix_outil.py'
"""

import os
import sys
import types

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(RACINE, "source_assets", "blender", "environment",
                      "make_waterfall_cave.py")

POINTS = (("defaut", 0.55, 5.95), ("amont", 0.55, 5.20),
          ("aval", 0.55, 6.40), ("galerie", 0.55, 2.60),
          ("apex", 3.60, 3.20), ("loin", 0.55, 7.20))


def main():
    source = open(SOURCE, "r", encoding="utf-8").read()
    module = types.ModuleType("gen_cave_sujet")
    module.__file__ = SOURCE
    sys.modules["gen_cave_sujet"] = module
    exec(compile(source, SOURCE, "exec"), module.__dict__)

    module.vider_scene()
    for nom in module.ORDRE_MATIERES:
        module.materiau(nom)
    s, f, fam = module.cavite_solide(module.SEGMENTS, module.SAG, 0.0, 0.0)
    outil = module.objet("OUTIL_Cavite", s, f, fam, True)

    xs = [v.co.x for v in outil.data.vertices]
    ys = [v.co.y for v in outil.data.vertices]
    zs = [v.co.z for v in outil.data.vertices]
    bords, nm, vol = module.controle_fermeture(outil)
    print("[outil] OUTIL_Cavite : %d sommets, %d faces, volume %.1f m3, "
          "%d bord(s), %d non-manifold"
          % (len(outil.data.vertices), len(outil.data.polygons), abs(vol),
             bords, nm))
    print("[outil] BOITE : x [%+.3f ; %+.3f]  y [%+.3f ; %+.3f]  "
          "z [%+.3f ; %+.3f]"
          % (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
    print("[outil] CAVITE derniere station %s, APEX %s"
          % (str(module.CAVITE[-1]), str(module.CAVITE_APEX)))
    print("[outil] PROLONGE_PORCHE_M = %.2f m vers -Y"
          % module.PROLONGE_PORCHE_M)

    # Les 12 sommets les plus au NORD (+y) : d'où vient la longueur.
    ordre = sorted(range(len(outil.data.vertices)),
                   key=lambda i: -outil.data.vertices[i].co.y)
    print("[outil] 12 sommets les plus au +Y :")
    for i in ordre[:12]:
        p = outil.data.vertices[i].co
        print("[outil]    (%+.3f ; %+.3f ; %+.3f)" % (p.x, p.y, p.z))

    # PAR STATION — c'est ce qui NOMME le coupable. Le tube est bâti anneau
    # par anneau ; publier l'emprise en Y de chaque anneau dit lequel jette
    # la section vers le nord, et donc où la roche doit être ajoutée.
    t_cav = module.tangentes(module.CAVITE)
    ph_c = module.phases(len(module.CAVITE), 7.0)
    print("[outil] emprise Y de chaque anneau (station : ax, ay, hw, cle) :")
    for i, st in enumerate(module.CAVITE):
        den = module.PORCHE_DENIVELE if i == 0 else 0.0
        pts = module.anneau_interieur(i, st, t_cav[i], module.SEGMENTS,
                                      ph_c[i], 0.0, 0.0, den, module.SAG)
        ys = [p.y for p in pts]
        xs = [p.x for p in pts]
        k = max(range(len(pts)), key=lambda q: pts[q].y)
        g, d, _inc = module.CAVITE_ASYM[i]
        print("[outil]   st%d (%.2f ; %.2f) hw %.2f  gauche %.2f droite %.2f "
              "-> y [%+.2f ; %+.2f]  x [%+.2f ; %+.2f]  extreme +Y en "
              "(%+.2f ; %+.2f ; %+.2f)"
              % (i, st[0], st[1], st[2], g, d, min(ys), max(ys),
                 min(xs), max(xs), pts[k].x, pts[k].y, pts[k].z))

    arbre = BVHTree.FromPolygons(
        [tuple(v.co) for v in outil.data.vertices],
        [tuple(p.vertices) for p in outil.data.polygons], all_triangles=False)
    z_ciel, z_fond = max(zs) + 1.0, min(zs) - 1.0
    for nom, ax, ay in POINTS:
        depart = Vector((ax, ay, z_ciel))
        direction = Vector((0.0, 0.0, -1.0))
        portee, parcouru, impacts = z_ciel - z_fond, 0.0, []
        for _ in range(64):
            touche = arbre.ray_cast(depart, direction, portee - parcouru)
            if touche is None or touche[0] is None:
                break
            impacts.append(touche[0].z)
            parcouru += (touche[0] - depart).length + 1e-4
            depart = touche[0] + direction * 1e-4
            if parcouru >= portee:
                break
        print("[outil] %-8s (%.2f ; %.2f) : %d impact(s) %s"
              % (nom, ax, ay, len(impacts),
                 " ".join("%.3f" % z for z in impacts) or "aucun"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
