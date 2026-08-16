#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""FABRIQUE DE CONTROLES NEGATIFS FERMES pour `cave_oracle_global.py`.

POURQUOI CE FICHIER EXISTE, ET POURQUOI IL APPELLE BLENDER
==========================================================

Le sabotage de la passe precedente percait en RETIRANT DES TRIANGLES. Cela
rend le maillage OUVERT, la parite n'y definit plus de dedans, et l'oracle
d'alors rebouchait le trou par un vote a trois axes : cinq controles negatifs
sur six restaient verts avec un tunnel de 0,35 a 0,65 m de rayon libre
MESURE. Le cadrage en tire la regle, et elle est juste :

    « un sabotage utile doit laisser le maillage FERME et manifold, et
      prouver qu'il l'est. »

Un tunnel ferme ne s'obtient pas en enlevant des faces : il faut lui donner
ses PAROIS. C'est exactement ce que fait une soustraction booleenne exacte.
D'ou Blender — non par gout de la dependance, mais parce que retirer des
triangles ne peut pas produire l'objet demande.

CE QUE CHAQUE SABOTAGE PRODUIT
==============================

  `temoin`          import + export sans aucune modification. CONTROLE ZERO,
                    et il n'est pas decoratif : sans lui, un ROUGE pourrait
                    venir de l'aller-retour glTF plutot que du sabotage.
  `toit`            tunnel cylindrique de la salle vers le haut, a travers
                    le toit, jusque dehors.
  `paroi_est`       idem vers +X.
  `paroi_ouest`     idem vers -X.
  `plancher`        idem vers le bas, a travers le plancher.
  `poche`           sphere entierement NOYEE dans la roche sous la visiere :
                    cavite interne fermee, donc une seconde composante de
                    surface et une seconde composante d'AIR.
  `roche_flottante` cube ferme pose dans l'air libre, disjoint du massif :
                    seconde composante de surface et seconde composante de
                    ROCHE.

Les quatre tunnels et la poche sont des DIFFERENCES booleennes (solveur
`EXACT`) ; la roche flottante est une reunion de solides disjoints. Dans tous
les cas le resultat reste un solide ferme, et
`cave_oracle_global.py --topologie-seule` le verifie sans rien croire sur
parole.

LE FICHIER D'ORIGINE N'EST JAMAIS REECRIT
=========================================

Chaque sabotage lit le GLB source et ecrit une COPIE dans le repertoire de
sortie. La « restauration byte-identique » est donc obtenue par construction
et non par une manoeuvre : le sha256 de la source est imprime avant et apres
chaque fabrication, et il doit etre le meme.

Usage (hors Blender — c'est ce fichier qui rappelle Blender) :

    python3 tools/cave_oracle_sabotage.py --entree <glb> --sortie <dir> \\
            --type toit [--rayon 0.30] [--graine x,y,z]

Repere : MODELE Blender (1 unite = 1 m, Z vertical), le meme que celui
qu'emploient l'oracle et `waterfall_cave_place.gd` apres conversion.

Codes de sortie : 0 = fabrique · 2 = erreur · 3 = BLOQUE (Blender absent).
"""

import argparse
import hashlib
import os
import subprocess
import sys

NOEUD = "SM_WaterfallCave"

## Longueur de tunnel par defaut : le massif fait moins de 17 m dans sa plus
## grande dimension, 26 m depassent donc toujours des deux cotes. Un tunnel
## qui s'arreterait DANS la roche serait un cul-de-sac, pas une fuite — et
## l'oracle aurait raison de rester vert.
LONGUEUR_M = 26.0

TYPES = ("temoin", "toit", "paroi_est", "paroi_ouest", "plancher",
         "poche", "roche_flottante")


# ===========================================================================
# Partie executee DANS Blender.
# ===========================================================================

def _nettoyer(bpy, ob, seuil=1e-5):
    """Soudure, degeneres, ilots perdus, retriangulation.

    Le booleen exact produit des T-jonctions et des faces coincidentes sur
    la paroi du cutter. Ce menage les resorbe. Il ne DEPLACE aucune paroi :
    le seuil de soudure vaut 10 microns, cinq mille fois plus fin que le pas
    de grille le plus serre employe par l'oracle. Si malgre lui le maillage
    reste ouvert, le controle negatif est declare INEXPLOITABLE plutot que
    joue — un sabotage ouvert ne prouve rien, c'est la lecon de la passe
    precedente.
    """
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=seuil)
    bpy.ops.mesh.dissolve_degenerate(threshold=seuil)
    bpy.ops.mesh.delete_loose()
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.quads_convert_to_tris(quad_method="BEAUTY",
                                       ngon_method="BEAUTY")
    bpy.ops.object.mode_set(mode="OBJECT")


def dans_blender(args):
    import bpy                                                 # noqa: PLC0415
    from mathutils import Vector                               # noqa: PLC0415

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=args.entree)

    cible = None
    for ob in bpy.data.objects:
        if ob.type == "MESH" and ob.name.startswith(NOEUD):
            cible = ob
            break
    if cible is None:
        print("SABOTAGE-ERREUR : noeud %s absent" % NOEUD)
        return 2

    # Les transformations du noeud sont appliquees : le lecteur de GLB de
    # l'oracle REFUSE de mesurer un noeud porteur d'une transformation, et
    # il a raison — mesurer a cote est exactement le piege de ce dossier.
    for ob in bpy.data.objects:
        if ob.type == "MESH":
            ob.select_set(True)
            bpy.context.view_layer.objects.active = ob
            bpy.ops.object.transform_apply(location=True, rotation=True,
                                           scale=True)
            ob.select_set(False)

    bb = [cible.matrix_world @ Vector(c) for c in cible.bound_box]
    lo = [min(v[k] for v in bb) for k in range(3)]
    hi = [max(v[k] for v in bb) for k in range(3)]
    print("SABOTAGE-AABB : x[%.3f %.3f] y[%.3f %.3f] z[%.3f %.3f]"
          % (lo[0], hi[0], lo[1], hi[1], lo[2], hi[2]))
    print("SABOTAGE-FACES-AVANT : %d" % len(cible.data.polygons))

    graine = [float(v) for v in args.graine.split(",")]
    outil = None

    def poser_cylindre(direction):
        """Cylindre partant DERRIERE la graine et sortant du massif.

        Il part en retrait dans le vide de la cavite : son couvercle amont
        est donc dans l'air, et le tunnel debouche vraiment sur la galerie
        au lieu de laisser une cloison residuelle.
        """
        d = Vector(direction).normalized()
        depart = Vector(graine) - d * 0.60
        centre = depart + d * (args.longueur / 2.0)
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=64, radius=args.rayon, depth=args.longueur,
            location=centre)
        cyl = bpy.context.active_object
        cyl.rotation_mode = "QUATERNION"
        cyl.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(d)
        bpy.ops.object.transform_apply(location=True, rotation=True,
                                       scale=True)
        return cyl

    if args.type == "temoin":
        pass
    elif args.type == "toit":
        outil = poser_cylindre((0.0, 0.0, 1.0))
    elif args.type == "plancher":
        outil = poser_cylindre((0.0, 0.0, -1.0))
    elif args.type == "paroi_est":
        outil = poser_cylindre((1.0, 0.0, 0.0))
    elif args.type == "paroi_ouest":
        outil = poser_cylindre((-1.0, 0.0, 0.0))
    elif args.type == "poche":
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=32, ring_count=16, radius=args.rayon,
            location=Vector([float(v) for v in args.point.split(",")]))
        outil = bpy.context.active_object
        bpy.ops.object.transform_apply(location=True, rotation=True,
                                       scale=True)
    elif args.type == "roche_flottante":
        bpy.ops.mesh.primitive_cube_add(
            size=2.0 * args.rayon,
            location=Vector([float(v) for v in args.point.split(",")]))
        outil = bpy.context.active_object
        bpy.ops.object.transform_apply(location=True, rotation=True,
                                       scale=True)
    else:
        print("SABOTAGE-ERREUR : type inconnu %s" % args.type)
        return 2

    if outil is not None:
        bb = [outil.matrix_world @ Vector(c) for c in outil.bound_box]
        olo = [min(v[k] for v in bb) for k in range(3)]
        ohi = [max(v[k] for v in bb) for k in range(3)]
        print("SABOTAGE-OUTIL-AABB : x[%.3f %.3f] y[%.3f %.3f] z[%.3f %.3f]"
              % (olo[0], ohi[0], olo[1], ohi[1], olo[2], ohi[2]))

        if args.type == "roche_flottante":
            # reunion de solides DISJOINTS : on joint les maillages plutot
            # que d'appeler un booleen, qui n'aurait rien a resoudre. Le
            # resultat porte deux composantes de surface, chacune fermee.
            outil.select_set(True)
            cible.select_set(True)
            bpy.context.view_layer.objects.active = cible
            bpy.ops.object.join()
            outil = None
        else:
            mod = cible.modifiers.new(name="sabotage", type="BOOLEAN")
            mod.operation = "DIFFERENCE"
            mod.solver = "EXACT"
            ## MESURE DU 2026-08-16 — pourquoi ces deux drapeaux.
            ## Un premier tunnel de toit, solveur EXACT nu, a rendu un
            ## maillage a 3 bords libres et 82 aretes a trois faces. Les 82
            ## etaient a EXACTEMENT 0,300 m de l'axe, c'est-a-dire sur la
            ## paroi du cylindre : artefact du solveur, pas defaut du
            ## massif. `use_self` fait resoudre au solveur ses propres
            ## recouvrements, `use_hole_tolerant` lui interdit de laisser
            ## un bord ouvert.
            mod.use_self = True
            mod.use_hole_tolerant = True
            mod.object = outil
            bpy.context.view_layer.objects.active = cible
            bpy.ops.object.modifier_apply(modifier=mod.name)
            bpy.data.objects.remove(outil, do_unlink=True)
            _nettoyer(bpy, cible)

    print("SABOTAGE-FACES-APRES : %d" % len(cible.data.polygons))
    cible.name = NOEUD
    cible.data.name = NOEUD

    bpy.ops.export_scene.gltf(
        filepath=args.sortie, export_format="GLB",
        export_apply=True, use_selection=False,
        export_yup=True, export_materials="EXPORT")
    print("SABOTAGE-ECRIT : %s" % args.sortie)
    return 0


# ===========================================================================
# Partie executee hors Blender : elle rappelle Blender.
# ===========================================================================

def hors_blender():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--entree", required=True)
    ap.add_argument("--sortie", required=True,
                    help="repertoire de sortie ; le GLB source n'est JAMAIS "
                         "reecrit")
    ap.add_argument("--type", required=True, choices=TYPES)
    ap.add_argument("--rayon", type=float, default=0.30)
    ap.add_argument("--longueur", type=float, default=LONGUEUR_M)
    ap.add_argument("--graine", default="2.62,2.58,0.99")
    ap.add_argument("--point", default="1.50,-0.40,2.00",
                    help="centre de la poche (dans la roche, sous la "
                         "visiere) ou du bloc flottant (dans l'air). "
                         "MESURE, pas devine : voir le rapport.")
    ap.add_argument("--blender", default="blender")
    args = ap.parse_args()

    entree = os.path.abspath(args.entree)
    if not os.path.isfile(entree):
        print("BLOQUE : entree introuvable : %s" % entree)
        return 3
    sha_avant = hashlib.sha256(open(entree, "rb").read()).hexdigest()

    from shutil import which
    if which(args.blender) is None:
        print("BLOQUE : blender absent (%s). Un tunnel FERME ne peut pas "
              "etre fabrique en retirant des triangles ; sans booleen "
              "exact, ce controle negatif n'existe pas." % args.blender)
        return 3

    os.makedirs(args.sortie, exist_ok=True)
    cible = os.path.join(os.path.abspath(args.sortie),
                         "SABOTAGE_%s.glb" % args.type)

    cmd = [args.blender, "--background", "--factory-startup",
           "--python", os.path.abspath(__file__), "--",
           "--entree", entree, "--sortie", cible, "--type", args.type,
           "--rayon", "%.4f" % args.rayon,
           "--longueur", "%.4f" % args.longueur,
           "--graine", args.graine, "--point", args.point]
    print("commande blender : %s" % " ".join(cmd))
    proc = subprocess.run(cmd, capture_output=True, text=True)
    for ligne in proc.stdout.splitlines():
        if ligne.startswith("SABOTAGE-"):
            print("   %s" % ligne)
    if proc.returncode != 0 or not os.path.isfile(cible):
        print("SABOTAGE ECHOUE (rc=%d)" % proc.returncode)
        sys.stdout.write(proc.stdout[-4000:])
        sys.stderr.write(proc.stderr[-4000:])
        return 2

    sha_apres = hashlib.sha256(open(entree, "rb").read()).hexdigest()
    print("source sha256 AVANT : %s" % sha_avant)
    print("source sha256 APRES : %s" % sha_apres)
    if sha_avant != sha_apres:
        print("SABOTAGE-ERREUR : la source a ete modifiee !")
        return 2
    print("source INTACTE (byte-identique)")
    print("sabotage : %s" % cible)
    print("sabotage sha256 : %s"
          % hashlib.sha256(open(cible, "rb").read()).hexdigest())
    return 0


def _args_blender():
    argv = sys.argv[sys.argv.index("--") + 1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("--entree", required=True)
    ap.add_argument("--sortie", required=True)
    ap.add_argument("--type", required=True)
    ap.add_argument("--rayon", type=float, default=0.30)
    ap.add_argument("--longueur", type=float, default=LONGUEUR_M)
    ap.add_argument("--graine", default="2.62,2.58,0.99")
    ap.add_argument("--point", default="1.50,-0.40,2.00")
    return ap.parse_args(argv)


if __name__ == "__main__":
    if "--" in sys.argv and any("blender" in a for a in sys.argv[:2]):
        sys.exit(dans_blender(_args_blender()))
    try:
        import bpy                                             # noqa: F401
        sys.exit(dans_blender(_args_blender()))
    except ImportError:
        sys.exit(hors_blender())
