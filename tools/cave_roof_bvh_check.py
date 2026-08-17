#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ARBITRAGE : la BVH de Blender et le lecteur pur-Python, sur LE MÊME maillage.

Le contrôle de domaine, exécuté DANS le générateur, annonce une plaque de
0,050 m en (0,53 ; 5,77). Le lecteur pur-Python, exécuté sur le `.glb`
EXPORTÉ, annonce 3,014 m de roche au même endroit. L'un des deux se trompe,
et il est hors de question de choisir celui qui arrange.

Deux causes possibles, qu'il faut séparer avant de corriger quoi que ce soit :

  (a) mon code BVH est faux ;
  (b) le maillage mesuré dans le générateur n'est pas celui qui est exporté.

Ce script importe le `.glb` DANS Blender et y rejoue la lecture BVH. Le
maillage devient alors le même des deux côtés :

  * si BVH-sur-glb == pur-Python-sur-glb  -> le code est bon, cause (b) ;
  * s'ils divergent                        -> cause (a), le code est faux.

Usage (sous verrou) :
    blender --background --python-exit-code 1 \\
        --python tools/cave_roof_bvh_check.py -- <fichier.glb> ax,ay [ax,ay ...]
"""

import sys

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree


def tranches_bvh(arbre, ax, ay, z_ciel, z_fond):
    """COPIE EXACTE de `_tranches_verticales` du générateur.

    Recopiée et non importée : le but est d'éprouver CE code-là. L'importer
    depuis le générateur ferait dépendre l'arbitrage du chargement d'un
    module de 5 600 lignes, et masquerait l'objet du test.
    """
    depart = Vector((ax, ay, z_ciel))
    direction = Vector((0.0, 0.0, -1.0))
    portee = (z_ciel - z_fond)
    impacts = []
    parcouru = 0.0
    for _ in range(64):
        touche = arbre.ray_cast(depart, direction, portee - parcouru)
        if touche is None or touche[0] is None:
            break
        z = touche[0].z
        nz = touche[1].z
        if abs(nz) > 1e-6:
            delta = +1 if nz > 0.0 else -1
            if not impacts or abs(impacts[-1][0] - z) > 1e-4 \
                    or impacts[-1][1] != delta:
                impacts.append((z, delta))
        avance = (touche[0] - depart).length + 1e-4
        parcouru += avance
        depart = touche[0] + direction * 1e-4
        if parcouru >= portee:
            break
    brut, enlacement = [], 0
    for k in range(len(impacts) - 1):
        enlacement += impacts[k][1]
        brut.append(("roche" if enlacement >= 1 else "vide",
                     impacts[k][0], impacts[k + 1][0]))
    tranches = []
    for nature, haut, bas in brut:
        if tranches and tranches[-1][0] == nature:
            tranches[-1] = (nature, tranches[-1][1], bas)
        else:
            tranches.append((nature, haut, bas))
    return impacts, tranches


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if len(argv) < 2:
        print("[arb] usage: ... -- <glb> ax,ay [ax,ay ...]")
        return 2
    chemin, points = argv[0], argv[1:]

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=chemin)
    objets = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if len(objets) != 1:
        print("[arb] BLOQUE: %d maillage(s) importe(s), 1 attendu"
              % len(objets))
        return 3
    obj = objets[0]
    bpy.context.view_layer.update()

    # L'import glTF pose une rotation de conversion Y-up -> Z-up sur l'objet.
    # On l'APPLIQUE, pour que les coordonnees locales soient le repere
    # MODELE — le meme que CAVITE, le meme que le lecteur pur-Python.
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    sommets = [v.co for v in obj.data.vertices]
    print("[arb] fichier   : %s" % chemin)
    print("[arb] sommets   : %d, triangles %d"
          % (len(sommets), sum(len(p.vertices) - 2 for p in obj.data.polygons)))
    print("[arb] emprise   : x [%.2f ; %.2f] y [%.2f ; %.2f] z [%.2f ; %.2f]"
          % (min(v.x for v in sommets), max(v.x for v in sommets),
             min(v.y for v in sommets), max(v.y for v in sommets),
             min(v.z for v in sommets), max(v.z for v in sommets)))

    arbre = BVHTree.FromPolygons(
        [tuple(v.co) for v in obj.data.vertices],
        [tuple(p.vertices) for p in obj.data.polygons], all_triangles=False)
    z_ciel = max(v.z for v in sommets) + 1.0
    z_fond = min(v.z for v in sommets) - 1.0

    for texte in points:
        ax, ay = [float(v) for v in texte.split(",")]
        impacts, tranches = tranches_bvh(arbre, ax, ay, z_ciel, z_fond)
        print("[arb] --- (%.2f ; %.2f) : %d impact(s) ---"
              % (ax, ay, len(impacts)))
        for z, d in impacts:
            print("[arb]     z %8.4f  delta %+d" % (z, d))
        for nature, haut, bas in tranches:
            print("[arb]     %-5s z %7.3f -> %7.3f  %.3f m"
                  % (nature, haut, bas, haut - bas))
    return 0


if __name__ == "__main__":
    sys.exit(main())
