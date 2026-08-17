#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""FABRIQUE DE CONTROLES NEGATIFS FERMES pour `cave_oracle_global.py`.

POURQUOI CE FICHIER EXISTE, ET POURQUOI IL APPELLE BLENDER
==========================================================

Le sabotage de la passe R2a-3.5.2 percait en RETIRANT DES TRIANGLES. Cela
rend le maillage OUVERT, la parite n'y definit plus de dedans, et l'oracle
d'alors rebouchait le trou par un vote a trois axes : cinq controles negatifs
sur six restaient verts avec un tunnel de 0,35 a 0,65 m de rayon libre
MESURE. Le cadrage en tire la regle, et elle est juste :

    « un sabotage utile doit laisser le maillage FERME et manifold, et
      prouver qu'il l'est. »

Un tunnel ferme ne s'obtient pas en enlevant des faces : il faut lui donner
ses PAROIS. C'est ce que fait une soustraction booleenne exacte. D'ou
Blender — non par gout de la dependance, mais parce que retirer des
triangles ne peut pas produire l'objet demande.

CE QUI A CHANGE A R2a-3.5.4, ET POURQUOI
========================================

MESURE DU 2026-08-16 : cette fabrique fonctionnait sur `cc3596c5` et
echouait sur R2a-3.4 — cinq sabotages sur sept `INEXPLOITABLE`, le booleen
OUVRANT le maillage. Le refus etait correct, mais il etablissait que la
fabrique DEPENDAIT DE LA GEOMETRIE : ses trois nombres cles
(`--graine 2.62,2.58,0.99`, `--point 1.50,-0.40,2.00`, `--rayon 0.30`)
etaient des constantes du candidat.

Deux corrections, et la seconde compte autant que la premiere :

  1. LES PLACEMENTS SONT DERIVES du maillage vise, par
     `cave_oracle_placement.py`, avant tout appel a Blender. Aucun reglage
     a la main par geometrie : ce serait une fabrique calibree trois fois,
     pas une fabrique generique.

  2. LA FERMETURE EST VERIFIEE DANS BLENDER, immediatement apres le
     booleen, et l'echec declenche une NOUVELLE TENTATIVE avec un decalage
     deterministe. Le solveur `EXACT` se degrade sur les configurations
     coincidentes — faces coplanaires, sommet du cutter exactement sur une
     arete du massif. Un ecart de quelques millimetres et une rotation de
     quelques dixiemes de degre suffisent a les defaire, et ils ne changent
     rien a ce que le sabotage demontre.

     Le jitter est une FONCTION PURE du numero de tentative : aucun
     `random`, deux executions donnent le meme resultat. Le nombre de
     tentatives est PUBLIE — un sabotage qui passe du premier coup sur une
     geometrie et au cinquieme sur une autre dit quelque chose qu'un simple
     « CONFORME » cacherait.

CE QUE CHAQUE SABOTAGE PRODUIT
==============================

  `temoin`          import + export sans aucune modification. CONTROLE ZERO :
                    sans lui, un ROUGE pourrait venir de l'aller-retour glTF
                    plutot que du sabotage. Attendu VERT.
  `placebo`         reunion d'une petite bosse a demi enfouie dans la peau
                    EXTERIEURE, la ou la roche est epaisse. Le maillage
                    change vraiment — sha et nombre de faces differents —
                    et AUCUN defaut n'est cree : une reunion n'ouvre aucun
                    passage et n'isole aucun volume. Attendu VERT.

                    Sans ce controle, la batterie ne sait qu'affirmer
                    « detecte » : tous ses sabotages attendent ROUGE, donc
                    un oracle qui rougirait sur TOUT passerait la batterie.
                    Le placebo est le seul controle capable de faire
                    echouer la batterie pour SUR-SENSIBILITE, c'est-a-dire
                    dans l'autre sens.

  `toit`            tunnel cylindrique de la salle vers le haut, jusque
                    dehors.
  `paroi_est`       idem vers +X.
  `paroi_ouest`     idem vers -X.
  `plancher`        idem vers le bas.
  `poche`           sphere entierement NOYEE dans la roche : cavite interne
                    fermee, donc une seconde composante d'AIR.
  `roche_flottante` cube ferme dans l'air libre, disjoint du massif : une
                    seconde composante de ROCHE.

LE FICHIER D'ORIGINE N'EST JAMAIS REECRIT
=========================================

Chaque sabotage lit le GLB source et ecrit une COPIE. La « restauration
byte-identique » est donc obtenue par construction et non par une manoeuvre :
le sha256 de la source est imprime avant et apres, et il doit etre le meme.

Usage :
    python3 tools/cave_oracle_sabotage.py --entree <glb> --sortie <dir> \\
            --type toit [--reperes f.gd] [--tentatives 6]

Repere : MODELE Blender (1 unite = 1 m, Z vertical).

Codes de sortie : 0 = fabrique · 2 = erreur · 3 = BLOQUE (Blender absent, ou
placements non derivables).
"""

import argparse
import hashlib
import json
import math
import os
import subprocess
import sys

NOEUD = "SM_WaterfallCave"

TYPES = ("temoin", "placebo", "toit", "paroi_est", "paroi_ouest",
         "plancher", "poche", "roche_flottante")

TENTATIVES_DEFAUT = 6


# ===========================================================================
# Jitter deterministe. Fonction pure du numero de tentative.
# ===========================================================================

def jitter(n):
    """(angle en radians, decalage en metres, facteur de rayon).

    Aucun `random` : deux executions donnent la meme suite, et un journal
    est rejouable. Les trois grandeurs bougent ensemble parce qu'une
    coincidence peut tenir a l'angle (faces coplanaires), a la position
    (sommet du cutter sur une arete) ou au rayon (paroi tangente).
    """
    if n == 0:
        return 0.0, 0.0, 1.0
    return (math.radians(0.37 * n), 0.0131 * n, 1.0 + 0.017 * n)


# ===========================================================================
# Partie executee DANS Blender.
# ===========================================================================

def _fermeture(ob):
    """(bords libres, aretes non-manifold) MESURES sur le maillage Blender.

    On mesure ICI, et non sur le GLB exporte, pour pouvoir RECOMMENCER. Le
    controle sur le GLB exporte reste fait par la batterie, avec un autre
    code et apres soudure par position : deux mesures independantes valent
    mieux qu'une repetee.
    """
    import bmesh                                               # noqa: PLC0415
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bords = nonman = 0
    for e in bm.edges:
        n = len(e.link_faces)
        if n == 1:
            bords += 1
        elif n > 2:
            nonman += 1
    bm.free()
    return bords, nonman


def _nettoyer(bpy, ob):
    """Triangulation SEULE, et c'est deliberement tout.

    MESURE DU 2026-08-16 — le menage d'apres booleen etait NUISIBLE. Sur
    R2a-3.4, sortie brute du booleen puis chaque etape ajoutee une a une :

        apres booleen (aucun menage)   bords 0   non-manifold 10
        + remove_doubles 1e-5          bords 1   non-manifold  5
        + dissolve_degenerate          bords 1   non-manifold  2
        + delete_loose                 bords 1   non-manifold  2

    C'est `remove_doubles` qui OUVRE le maillage : il fusionne, a 10
    microns, des sommets que le booleen venait de placer distinctement sur
    la paroi du cutter. Le bord libre unique qui condamnait cinq sabotages
    n'etait donc pas produit par le booleen — il etait produit par le
    menage cense le reparer.

    Les 10 non-manifold, eux, venaient de `use_self` (voir `_tenter`). Une
    fois ce drapeau retire, la sortie brute du booleen est deja fermee et
    manifold, et il ne reste rien a nettoyer : on triangule, parce que
    l'export glTF triangule de toute facon, et qu'on veut verifier
    exactement ce qu'on exporte.
    """
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.quads_convert_to_tris(quad_method="BEAUTY",
                                       ngon_method="BEAUTY")
    bpy.ops.object.mode_set(mode="OBJECT")


def _souder(bpy, ob, seuil=1e-5):
    """Soudure des sommets par position. A FAIRE AVANT TOUT BOOLEEN.

    MESURE DU 2026-08-16, ET C'EST LA VRAIE CAUSE DES `INEXPLOITABLE`.
    Un GLB indexe ses sommets PAR PRIMITIVE : les six matieres de cet asset
    dedoublent chaque sommet de couture. A l'import, Blender ne recolle
    rien. Mesure sur les deux geometries, juste apres import :

        R2a-3.4  V=55542 E=57702 F=19954   bords libres 55542
        candidat V=54810 E=57541 F=20090   bords libres 54812

    Le maillage est une SOUPE DE TRIANGLES. Soude a 10 microns, il devient
    ferme et manifold sur les deux :

        R2a-3.4  V=9975  E=29931 F=19954   bords libres 0   non-manifold 0
        candidat V=10045 E=30135 F=20090   bords libres 0   non-manifold 0

    La fabrique precedente lancait le booleen sur la soupe et ne soudait
    qu'APRES. Demander une difference exacte a un maillage sans topologie
    est la configuration degeneree par excellence : sur R2a-3.4 elle
    laissait invariablement 1 bord libre et 3 aretes non-manifold — les
    memes chiffres a chaque tentative, quel que soit le jitter, ce qui
    montrait bien que le cutter n'y etait pour rien.

    Souder d'abord rend l'operation deterministe et fermee sur les deux
    geometries. C'est aussi ce que le contrat exige a l'etape 1 : prouver
    la fermeture AVANT de saboter.

    SECONDE CAUSE, MESUREE SUR LA GEOMETRIE CORRIGEE DE L'AGENT A
    -------------------------------------------------------------
    Souder ne suffit pas. Test decisif : un booleen avec un cube place a
    500 m, donc SANS AUCUNE INTERSECTION. Sur un solide valide il doit
    rendre le maillage inchange. Mesure :

        c184c8dc  V=10038 F=20072 bords 0  ->  V=10038 F=20071 bords 3
        cc3596c5  V=10045 F=20090 bords 0  ->  V=10045 F=20089 bords 3
        R2a-3.4   V=9975  F=19954 bords 0  ->  INCHANGE

    Les deux geometries issues de l'enveloppe R2a-3.5.2 portent donc une
    face que le solveur exact SUPPRIME de lui-meme, ouvrant un trou de
    trois aretes — avant meme qu'on lui demande de couper quoi que ce soit.
    C'est la vraie origine des « 3 bords libres et 82 aretes a trois
    faces » rapportes par la passe precedente : les 3 viennent de la
    SOURCE, les 82 de la paroi du cutter.

    La parade est generique et ne suppose rien de la geometrie : on dissout
    soi-meme les faces degenerees, puis on rebouche le trou qu'elles
    laissent. Le maillage retrouve exactement son compte de sommets et de
    faces — l'operation est neutre — et le booleen sans intersection
    redevient reellement neutre.
    """
    def _en_edition(action):
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        action()
        bpy.ops.object.mode_set(mode="OBJECT")

    _en_edition(lambda: bpy.ops.mesh.remove_doubles(threshold=seuil))
    _en_edition(lambda: bpy.ops.mesh.quads_convert_to_tris(
        quad_method="BEAUTY", ngon_method="BEAUTY"))
    _en_edition(lambda: bpy.ops.mesh.dissolve_degenerate(threshold=1e-6))
    _en_edition(lambda: bpy.ops.mesh.fill_holes(sides=0))
    _en_edition(lambda: bpy.ops.mesh.quads_convert_to_tris(
        quad_method="BEAUTY", ngon_method="BEAUTY"))


def _charger(bpy, chemin):
    """Scene vierge + import + transformations appliquees + SOUDURE.

    Les transformations sont appliquees parce que le lecteur de GLB de
    l'oracle REFUSE de mesurer un noeud porteur d'une transformation, et il
    a raison : mesurer a cote est le piege de ce dossier.

    Recharger a chaque tentative coute un import, et garantit qu'une
    tentative ratee ne laisse aucun residu dans la suivante.
    """
    from mathutils import Vector                               # noqa: PLC0415
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=chemin)
    cible = None
    for ob in bpy.data.objects:
        if ob.type == "MESH" and ob.name.startswith(NOEUD):
            cible = ob
            break
    if cible is None:
        return None, None, None
    for ob in bpy.data.objects:
        if ob.type == "MESH":
            ob.select_set(True)
            bpy.context.view_layer.objects.active = ob
            bpy.ops.object.transform_apply(location=True, rotation=True,
                                           scale=True)
            ob.select_set(False)
    _souder(bpy, cible)
    bb = [cible.matrix_world @ Vector(c) for c in cible.bound_box]
    lo = [min(v[k] for v in bb) for k in range(3)]
    hi = [max(v[k] for v in bb) for k in range(3)]
    return cible, lo, hi


def _tenter(bpy, args, plc, n):
    """Une tentative. Rend (cible, ferme, bords, nonman, note d'erreur)."""
    from mathutils import Matrix, Vector                       # noqa: PLC0415

    angle, decal, facteur = jitter(n)
    cible, lo, hi = _charger(bpy, args.entree)
    if cible is None:
        return None, False, -1, -1, "noeud %s absent" % NOEUD

    ## CONTRAT §3, ETAPE 1 : prouver la fermeture AVANT de saboter. Un
    ## sabotage pose sur un maillage deja ouvert ne prouve rien, et son
    ## rouge serait attribue au sabotage a tort.
    b0, n0 = _fermeture(cible)
    if n == 0:
        print("SABOTAGE-AABB : x[%.3f %.3f] y[%.3f %.3f] z[%.3f %.3f]"
              % (lo[0], hi[0], lo[1], hi[1], lo[2], hi[2]))
        print("SABOTAGE-FERMETURE-AVANT : bords libres %d  non-manifold %d  "
              "%s" % (b0, n0, "FERME" if (b0 == 0 and n0 == 0) else "OUVERT"))
        print("SABOTAGE-FACES-AVANT : %d" % len(cible.data.polygons))
    if b0 or n0:
        return None, False, b0, n0, (
            "le maillage SOURCE est deja ouvert apres soudure (%d bord(s) "
            "libre(s), %d non-manifold) : aucun sabotage pose dessus ne "
            "prouverait quoi que ce soit sur l'oracle" % (b0, n0))

    graine = Vector(plc["graine"]["point"])
    rayon = plc["rayon"] * facteur
    longueur = plc["longueur"]

    def orthogonal(d):
        base = Vector((0.0, 0.0, 1.0))
        if abs(d.dot(base)) > 0.9:
            base = Vector((1.0, 0.0, 0.0))
        return d.cross(base).normalized()

    def poser_cylindre(direction):
        """Cylindre partant DERRIERE la graine et sortant du massif.

        Il part en retrait dans le vide de la cavite : son couvercle amont
        est donc dans l'air, et le tunnel debouche vraiment sur la galerie
        au lieu de laisser une cloison residuelle.
        """
        d = Vector(direction).normalized()
        perp = orthogonal(d)
        if angle:
            d = d.copy()
            d.rotate(Matrix.Rotation(angle, 3, perp))
            d.normalize()
        depart = graine - d * 0.60 + perp * decal
        centre = depart + d * (longueur / 2.0)
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=64, radius=rayon, depth=longueur, location=centre)
        cyl = bpy.context.active_object
        cyl.rotation_mode = "QUATERNION"
        cyl.rotation_quaternion = Vector(
            (0.0, 0.0, 1.0)).rotation_difference(d)
        bpy.ops.object.transform_apply(location=True, rotation=True,
                                       scale=True)
        return cyl

    def poser_sphere(point, r):
        p = Vector(point) + Vector((decal, decal * 0.5, 0.0))
        bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16,
                                             radius=r * facteur, location=p)
        ob = bpy.context.active_object
        bpy.ops.object.transform_apply(location=True, rotation=True,
                                       scale=True)
        return ob

    outil = None
    operation = "DIFFERENCE"

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
        outil = poser_sphere(plc["poche"]["point"], plc["rayon_poche"])
    elif args.type == "placebo":
        outil = poser_sphere(plc["placebo"]["point"], plc["placebo"]["rayon"])
        operation = "UNION"
    elif args.type == "roche_flottante":
        bpy.ops.mesh.primitive_cube_add(size=2.0 * plc["bloc"]["rayon"],
                                        location=Vector(plc["bloc"]["point"]))
        outil = bpy.context.active_object
        bpy.ops.object.transform_apply(location=True, rotation=True,
                                       scale=True)
    else:
        return None, False, -1, -1, "type inconnu %s" % args.type

    if outil is not None:
        bb = [outil.matrix_world @ Vector(c) for c in outil.bound_box]
        olo = [min(v[k] for v in bb) for k in range(3)]
        ohi = [max(v[k] for v in bb) for k in range(3)]
        if n == 0:
            print("SABOTAGE-OUTIL-AABB : x[%.3f %.3f] y[%.3f %.3f] "
                  "z[%.3f %.3f]" % (olo[0], ohi[0], olo[1], ohi[1],
                                    olo[2], ohi[2]))

        if args.type == "roche_flottante":
            # reunion de solides DISJOINTS : on JOINT les maillages plutot
            # que d'appeler un booleen, qui n'aurait rien a resoudre. Le
            # resultat porte deux composantes de surface, chacune fermee.
            outil.select_set(True)
            cible.select_set(True)
            bpy.context.view_layer.objects.active = cible
            bpy.ops.object.join()
        else:
            mod = cible.modifiers.new(name="sabotage", type="BOOLEAN")
            mod.operation = operation
            mod.solver = "EXACT"
            ## MESURE DU 2026-08-16 — POURQUOI CES DEUX DRAPEAUX SONT FAUX.
            ##
            ## La passe precedente les avait actives apres avoir vu, sur un
            ## tunnel de toit, « 3 bords libres et 82 aretes a trois
            ## faces ». Le diagnostic d'alors — artefact du solveur sur la
            ## paroi du cylindre — etait errone : ces 82 aretes venaient de
            ## ce que le booleen operait sur un maillage NON SOUDE (voir
            ## `_souder`). `use_self` masquait le symptome sur le candidat
            ## et echouait sur R2a-3.4.
            ##
            ## Matrice mesuree sur R2a-3.4, entree soudee, tunnel de toit,
            ## sortie brute du booleen sans aucun menage :
            ##
            ##   use_self=False hole_tolerant=False -> bords 0  non-man  0
            ##   use_self=False hole_tolerant=True  -> bords 0  non-man  0
            ##   use_self=True  hole_tolerant=False -> bords 0  non-man 10
            ##   use_self=True  hole_tolerant=True  -> bords 0  non-man 10
            ##
            ## Resultat identique avec le cutter triangule au prealable.
            ## `use_self` est donc la CAUSE des 10 non-manifold, pas leur
            ## remede : on demande au solveur de resoudre des
            ## auto-recouvrements qui n'existent pas, et il en cree.
            ##
            ## Les deux drapeaux restent nommes explicitement plutot
            ## qu'omis : leur valeur est un resultat de mesure, et un futur
            ## lecteur doit voir qu'elle a ete choisie, pas heritee.
            mod.use_self = False
            mod.use_hole_tolerant = False
            mod.object = outil
            bpy.context.view_layer.objects.active = cible
            bpy.ops.object.modifier_apply(modifier=mod.name)
            bpy.data.objects.remove(outil, do_unlink=True)
            _nettoyer(bpy, cible)

    bords, nonman = _fermeture(cible)
    return cible, (bords == 0 and nonman == 0), bords, nonman, ""


def dans_blender(args):
    import bpy                                                 # noqa: PLC0415

    plc = json.load(open(args.placements, encoding="utf-8"))
    print("SABOTAGE-PLACEMENTS : %s" % args.placements)

    cible = None
    retenu = None
    for n in range(args.tentatives):
        cible, ferme, bords, nonman, note = _tenter(bpy, args, plc, n)
        if note:
            print("SABOTAGE-ERREUR : %s" % note)
            return 2
        angle, decal, facteur = jitter(n)
        print("SABOTAGE-TENTATIVE %d : angle %.3f deg  decalage %.4f m  "
              "rayon x%.3f  ->  bords libres %d  non-manifold %d  %s"
              % (n + 1, math.degrees(angle), decal, facteur, bords, nonman,
                 "FERME" if ferme else "OUVERT"))
        if ferme:
            retenu = n
            break

    if retenu is None:
        print("SABOTAGE-ECHEC-FERMETURE : %d tentative(s), aucune n'a rendu "
              "un maillage ferme. Ce n'est PAS un constat sur l'oracle : "
              "c'est la fabrique qui n'a pas su produire l'objet demande."
              % args.tentatives)
        return 2

    print("SABOTAGE-TENTATIVES : %d" % (retenu + 1))
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
# Partie executee hors Blender : elle derive, puis rappelle Blender.
# ===========================================================================

def hors_blender():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--entree", required=True)
    ap.add_argument("--sortie", required=True,
                    help="repertoire de sortie ; le GLB source n'est JAMAIS "
                         "reecrit")
    ap.add_argument("--type", required=True, choices=TYPES)
    ap.add_argument("--reperes", default=None,
                    help="script de LIEU accompagnant CETTE geometrie")
    ap.add_argument("--tentatives", type=int, default=TENTATIVES_DEFAUT)
    ap.add_argument("--placements", default=None,
                    help="JSON de placements deja derive ; sinon derive ici")
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
    sortie = os.path.abspath(args.sortie)

    # --- placements DERIVES du maillage vise -----------------------------
    if args.placements:
        chemin_plc = os.path.abspath(args.placements)
    else:
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import cave_oracle_placement as PL                     # noqa: PLC0415
        chemin_plc = os.path.join(sortie, "PLACEMENTS.json")
        plc = PL.deriver(entree, NOEUD, args.reperes, bavard=False)
        json.dump(plc, open(chemin_plc, "w"), indent=2)
        if plc.get("bloque"):
            print("BLOQUE : placements non derivables : %s" % plc["bloque"])
            return 3

    cible = os.path.join(sortie, "SABOTAGE_%s.glb" % args.type)
    cmd = [args.blender, "--background", "--factory-startup",
           "--python", os.path.abspath(__file__), "--",
           "--entree", entree, "--sortie", cible, "--type", args.type,
           "--placements", chemin_plc,
           "--tentatives", str(args.tentatives)]
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
    sha_cible = hashlib.sha256(open(cible, "rb").read()).hexdigest()
    print("sabotage : %s" % cible)
    print("sabotage sha256 : %s" % sha_cible)
    return 0


def _args_blender():
    argv = sys.argv[sys.argv.index("--") + 1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("--entree", required=True)
    ap.add_argument("--sortie", required=True)
    ap.add_argument("--type", required=True)
    ap.add_argument("--placements", required=True)
    ap.add_argument("--tentatives", type=int, default=TENTATIVES_DEFAUT)
    return ap.parse_args(argv)


if __name__ == "__main__":
    if "--" in sys.argv and any("blender" in a for a in sys.argv[:2]):
        sys.exit(dans_blender(_args_blender()))
    try:
        import bpy                                             # noqa: F401
        sys.exit(dans_blender(_args_blender()))
    except ImportError:
        sys.exit(hors_blender())
