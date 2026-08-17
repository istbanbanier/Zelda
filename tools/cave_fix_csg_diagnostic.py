#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""LE DÉFAUT CSG DE L'AGENT B EST-IL LE MÊME QUE MES 2 PAIRES À 0,0006 m ?

LES DEUX QUESTIONS, ET ELLES SONT DISTINCTES
============================================

L'agent B mesure qu'un booléen avec un cube **à 500 m**, sans la moindre
intersection, **ouvre 3 bords libres** sur `cc3596c5` ET sur `c184c8dc`,
alors qu'il laisse R2a-3.4 intacte. Un booléen qui ne devrait rien faire
modifie quand même le maillage : le solveur exact y supprime une face de
lui-même.

Ma chaîne, elle, publie « auto-intersection du livrable : 2 paire(s),
repli maximal 0,0006 m » — sur le candidat comme sur ma géométrie.

Deux symptômes. Une cause, ou deux ? Et la cause naît-elle dans la SOURCE
ou dans la CHAÎNE ? Ce script répond aux deux sans toucher à la géométrie :

  1. il rejoue `controle_repli()` — la fonction du générateur, pas une
     réécriture — sur les CINQ maillages d'étape et sur les trois
     géométries finales, et publie l'EXEMPLE, c'est-à-dire la position ;
  2. il rejoue le booléen inoffensif, relève les bords libres, et
     IDENTIFIE LES FACES DISPARUES par leur centroïde ;
  3. il compare les deux localisations. Même endroit = un seul défaut,
     nommable. Endroits différents = il y en a deux, et il faut le dire.

CE QU'IL NE FAIT PAS
====================

Il ne modifie ni le générateur, ni aucune géométrie livrée. Il importe des
GLB, mesure, imprime. Le cube témoin est posé à 500 m et détruit avec la
scène.

POURQUOI COMPARER PAR CENTROÏDE ET NON PAR INDICE
=================================================

Le booléen renumérote tout. Un indice de face avant l'opération ne désigne
rien après. On apparie donc par position du centroïde, à une tolérance
serrée — et on publie le nombre de faces appariées, sans quoi « 3 faces
disparues » pourrait tout aussi bien vouloir dire « mon appariement a
échoué ».

Usage (Blender, sous verrou d'outil lourd) :
    flock /home/user/Zelda/.git/heavy_tools.lock -c \\
      'cd <worktree> && blender --background \\
       --python-exit-code 1 --python tools/cave_fix_csg_diagnostic.py'
"""

import os
import sys
import types

import bpy

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(RACINE, "source_assets", "blender", "environment",
                      "make_waterfall_cave.py")
ETAPES = os.path.join(RACINE, "evidence", "world_v2", "v2_3_r2a", "grotte",
                      "r2a354_percee", "etapes")

## Les cinq étapes de la chaîne, produites AVANT la correction : c'est
## exactement ce qu'il faut, puisque le défaut est HÉRITÉ du candidat.
SUJETS = [
    (os.path.join(ETAPES, "etape_0_joint.glb"), "0 joint (avant remesh)"),
    (os.path.join(ETAPES, "etape_1_remaille.glb"), "1 remaille"),
    (os.path.join(ETAPES, "etape_2_stratifie.glb"), "2 stratifie"),
    (os.path.join(ETAPES, "etape_3_decime.glb"), "3 decime"),
    (os.path.join(ETAPES, "etape_4_soustrait.glb"), "4 soustrait"),
    ("/tmp/ref354/SM_WaterfallCave_cc3596c5.glb", "FINAL candidat cc3596c5"),
    (os.path.join(RACINE, "assets", "environment", "caves",
                  "SM_WaterfallCave.glb"), "FINAL corrige c184c8dc"),
    (os.environ.get("GLB_R2A34", "assets/environment/caves/SM_WaterfallCave.glb"),
     "FINAL R2a-3.4 livree"),
]

TOLERANCE_APPARIEMENT = 1e-4


def vider():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for bloc in list(bpy.data.meshes):
        bpy.data.meshes.remove(bloc)


def importer(chemin):
    """Importe un GLB et rend l'objet du maillage VISUEL, jamais le collider.

    Le filtre n'est pas un confort : `COL_WaterfallCave` rebouche la
    galerie, et le mesurer à la place du visuel a déjà produit
    « 3,06 m de roche continue » là où il y en a 0,038.
    """
    vider()
    bpy.ops.import_scene.gltf(filepath=chemin)
    vise = [o for o in bpy.context.scene.objects
            if o.type == "MESH" and o.name.startswith("SM_WaterfallCave")]
    if not vise:
        raise SystemExit("BLOQUE: aucun objet SM_WaterfallCave dans %s"
                         % chemin)
    # Le plus dense : l'importeur peut suffixer (.001) sur une re-import.
    return max(vise, key=lambda o: len(o.data.polygons))


def souder(obj):
    """Soude par position et rend (avant, apres) le compte d'aretes de bord.

    INDISPENSABLE, ET C'EST LE PIEGE DOCUMENTE DU CADRAGE : « un GLB range
    par materiau DUPLIQUE les sommets a chaque couture ; sans soudure par
    position, un compteur d'aretes rend des milliers de faux bords libres ».
    Mesure : 54 812 « bords libres » sur un maillage dont le genre est 0 et
    dont l'oracle d'inondation dit qu'il est ferme. On soude, et on PUBLIE
    les deux nombres, sans quoi le lecteur ne peut pas distinguer un vrai
    bord d'un artefact d'import.
    """
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    avant = sum(1 for e in bm.edges if len(e.link_faces) == 1)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    apres = sum(1 for e in bm.edges if len(e.link_faces) == 1)
    degenerees = sum(1 for f in bm.faces if f.calc_area() < 1e-9)
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return avant, apres, degenerees


def centroides(obj):
    sortie = {}
    for p in obj.data.polygons:
        c = p.center
        cle = (round(c.x / TOLERANCE_APPARIEMENT),
               round(c.y / TOLERANCE_APPARIEMENT),
               round(c.z / TOLERANCE_APPARIEMENT))
        sortie[cle] = (c.x, c.y, c.z)
    return sortie


def main():
    source = open(SOURCE, "r", encoding="utf-8").read()
    module = types.ModuleType("gen_cave_sujet")
    module.__file__ = SOURCE
    sys.modules["gen_cave_sujet"] = module
    exec(compile(source, SOURCE, "exec"), module.__dict__)

    print("[csg] " + "=" * 70)
    print("[csg] QUESTION 1 — ou vit le repli, et a quelle etape apparait-il ?")
    print("[csg] " + "=" * 70)
    replis = {}
    for chemin, etiquette in SUJETS:
        if not os.path.isfile(chemin):
            print("[csg] %-28s ABSENT : %s" % (etiquette, chemin))
            continue
        obj = importer(chemin)
        b_avant, b_apres, degen = souder(obj)
        bords, nm, vol = module.controle_fermeture(obj)
        n, prof, exemple = module.controle_repli(obj)
        replis[etiquette] = exemple
        print("[csg] %-28s %6d faces  bords libres %d -> %d apres soudure  "
              "(nm %d)  %d face(s) degeneree(s)  vol %8.1f m3"
              % (etiquette, len(obj.data.polygons), b_avant, b_apres, nm,
                 degen, abs(vol)))
        print("[csg]     repli : %d paire(s), profondeur max %.6f m" % (n, prof))
        if exemple:
            print("[csg]     exemple : %s" % exemple)

    print("[csg] " + "=" * 70)
    print("[csg] QUESTION 2 — le booleen INOFFENSIF (cube a 500 m) ouvre-t-il ?")
    print("[csg] " + "=" * 70)
    for chemin, etiquette in SUJETS:
        if not os.path.isfile(chemin):
            continue
        obj = importer(chemin)
        _, avant_b, _ = souder(obj)
        _, avant_nm, avant_vol = module.controle_fermeture(obj)
        avant_c = centroides(obj)

        bpy.ops.mesh.primitive_cube_add(size=2.0, location=(500.0, 500.0, 500.0))
        cube = bpy.context.active_object
        mod = obj.modifiers.new("temoin", "BOOLEAN")
        mod.object = cube
        mod.operation = "DIFFERENCE"
        mod.solver = "EXACT"          # meme solveur que `soustraire()`
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)

        _, apres_b, _ = souder(obj)
        _, apres_nm, apres_vol = module.controle_fermeture(obj)
        apres_c = centroides(obj)
        disparues = [v for k, v in avant_c.items() if k not in apres_c]
        apparues = [v for k, v in apres_c.items() if k not in avant_c]
        print("[csg] %-28s faces %d -> %d ; bords libres (soudes) %d -> %d ; "
              "nm %d -> %d ; vol %.3f -> %.3f m3"
              % (etiquette, len(avant_c), len(apres_c), avant_b, apres_b,
                 avant_nm, apres_nm, abs(avant_vol), abs(apres_vol)))
        print("[csg]     appariement par centroide : %d disparue(s), "
              "%d apparue(s)" % (len(disparues), len(apparues)))
        for c in disparues[:6]:
            print("[csg]       DISPARUE  (%.3f, %.3f, %.3f)" % c)
        for c in apparues[:6]:
            print("[csg]       APPARUE   (%.3f, %.3f, %.3f)" % c)
        ex = replis.get(etiquette)
        if ex:
            print("[csg]     a comparer au repli : %s" % ex)
        bpy.data.objects.remove(cube, do_unlink=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
