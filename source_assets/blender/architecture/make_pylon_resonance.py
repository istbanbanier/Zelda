# SOURCE DE GÉNÉRATION REPRODUCTIBLE — Pylône de Résonance.
#
# POURQUOI CE FICHIER EXISTE. Le lead a rejeté trois passes où la surface
# artistique était fabriquée en GDScript par empilement de `BoxMesh` :
# « des blocs disjoints et des silhouettes de prototype ». La règle a
# changé — un script de scène instancie et implante, il ne modèle plus.
# Le pylône est un hero asset ORIGINAL (VISUAL_ASSET_BIBLE §11.2) et
# aucun des modules CC0 du dépôt ne parle sa langue : ni fût à dosserets,
# ni anneau incomplet, ni couronne bifide, ni canal creux. Blender était
# donc la seule voie honnête.
#
# MÉTHODE : aucun booléen. Toutes les pièces sont des VOLUMES LOFTÉS —
# on empile des profils fermés et on les coud. Un booléen sur une pile de
# primitives produit exactement les artefacts que le lead a rejetés
# (faces ouvertes, arêtes en escalier, pièces désolidarisées) ; un loft
# produit par construction un volume continu, fermé et manifold.
#
# LES TROIS CANAUX SONT DANS LE PROFIL, pas creusés après coup : le rayon
# du profil chute de `CANAL_PROFONDEUR` sur trois secteurs angulaires. Le
# canal a donc de vraies joues verticales et un vrai fond, et il se lit en
# contre-jour à 96 m.
#
# Blender est Z-up ; l'exporteur glTF convertit en Y-up (`export_yup`).
# On modèle donc en Z vertical, base à Z = 0.
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/architecture/make_pylon_resonance.py

import math
import os
import sys

import bmesh
import bpy

# ---------------------------------------------------------------------------
# Cotes — VISUAL_ASSET_BIBLE §11.2 (pylône 28–36 m) et le filet
# `test_le_pylone_est_un_repere_majeur` (26 ≤ h ≤ 40 m, ≥ 8 MeshInstance3D).
# ---------------------------------------------------------------------------
SOCLE_Z0, SOCLE_Z1 = 0.0, 1.70
SOCLE_R0, SOCLE_R1 = 5.30, 4.35

PIED_Z0, PIED_Z1 = 1.55, 6.60
PIED_R0, PIED_R1 = 4.05, 2.45
PIED_LARGE0, PIED_LARGE1 = 2.90, 1.45
PIEDS = 3

COLLIER_Z0, COLLIER_Z1 = 6.30, 7.40
COLLIER_R0, COLLIER_R1 = 2.95, 2.60

FUT_Z0, FUT_Z1 = 7.10, 25.20
FUT_R0, FUT_R1 = 2.50, 1.60
CANAL_PROFONDEUR = 0.62
CANAL_DEMI_DEG = 13.0
CANAUX_DEG = (30.0, 150.0, 270.0)

CEINTURES_Z = (12.20, 18.60)
CEINTURE_HAUTEUR = 0.62
CEINTURE_DEBORD = 0.26

ANNEAU_Z = 22.30
ANNEAU_R = 4.35
ANNEAU_SECTION = (0.62, 0.78)   # épaisseur radiale, hauteur — CONSTANTES
ANNEAU_OUVERTURE_DEG = 74.0     # le cercle reste INCOMPLET (Œil-Tempête)

COURONNE_Z = 24.60
DENTS = (
    # (décalage X du pied, hauteur, demi-largeur au pied, demi-largeur au sommet)
    (1.55, 9.10, 0.95, 0.42),
    (-1.30, 6.40, 0.80, 0.36),
)

VEINE_LARGEUR = 0.30
VEINE_Z0, VEINE_Z1 = 8.20, 24.00

SEGMENTS = 72   # 5° — assez fin pour un fût rond, assez grossier pour rester facetté


# ---------------------------------------------------------------------------
# Matériaux — nommés, comme l'exige `docs/assets/IMPORT_RULES.md`.
#
# LES VALEURS CI-DESSOUS SONT EN sRGB, c'est-à-dire la valeur que l'œil
# doit lire. Elles sont converties en LINÉAIRE avant d'entrer dans Blender.
#
# Pourquoi, et c'est mesuré le 2026-08-14. Le premier jet posait ces
# nombres directement comme Base Color. glTF stocke `baseColorFactor` en
# **linéaire**, et Godot le réencode en sRGB pour `albedo_color`. Relevé
# par `tools/godot/probe_asset_materials.gd` sur l'asset importé :
#
#   pierre    0,40 écrit  ->  0,67 dans Godot
#   ivoire    0,62 écrit  ->  0,81
#   cuivre    0,30 écrit  ->  0,58
#   fond      0,14 écrit  ->  0,41
#
# Toutes les valeurs remontaient dans une bande 0,41–0,81 : le contraste
# était écrasé, le fond des canaux n'était plus sombre, et le pylône
# rendait BLANC — précisément ce que le lead interdit. Ce n'était pas une
# erreur de goût, c'était une erreur d'espace colorimétrique.
#
# Les cibles sRGB visent les bandes de VALEUR RENDUE de §1.5 en tenant
# compte du gain de lumière ≈ 1,8 de ce monde (scripts/CLAUDE.md) :
# masse de pierre 35–65 %, creux et ombres 18–38 %.
# ---------------------------------------------------------------------------
MATERIAUX = {
    "MAT_Pylon_Stone": (0.34, 0.31, 0.27, 0.92, None),
    "MAT_Pylon_Copper": (0.26, 0.30, 0.25, 0.62, None),
    "MAT_Pylon_Ivory": (0.52, 0.49, 0.42, 0.55, None),
    "MAT_Pylon_CoreStone": (0.11, 0.11, 0.10, 0.96, None),
    "MAT_Pylon_Cyan": (0.08, 0.24, 0.27, 0.35, (0.13, 0.85, 0.93)),
}


def srgb_vers_lineaire(canal):
    """sRGB -> linéaire. glTF attend du linéaire ; l'œil pense en sRGB."""
    if canal <= 0.04045:
        return canal / 12.92
    return ((canal + 0.055) / 1.055) ** 2.4


def materiau(nom):
    if nom in bpy.data.materials:
        return bpy.data.materials[nom]
    r, v, b, rugosite, emission = MATERIAUX[nom]
    r, v, b = (srgb_vers_lineaire(c) for c in (r, v, b))
    mat = bpy.data.materials.new(nom)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (r, v, b, 1.0)
    bsdf.inputs["Roughness"].default_value = rugosite
    bsdf.inputs["Metallic"].default_value = 0.0
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 1.4
    return mat


# ---------------------------------------------------------------------------
# Outillage de loft — le cœur de la méthode.
# ---------------------------------------------------------------------------
def cercle(rayon, z, segments=SEGMENTS, deformation=None):
    """Profil fermé à `segments` sommets, éventuellement déformé par angle."""
    points = []
    for i in range(segments):
        angle = 2.0 * math.pi * i / segments
        r = rayon if deformation is None else deformation(math.degrees(angle), rayon)
        points.append((math.cos(angle) * r, math.sin(angle) * r, z))
    return points


def profil_a_canaux(deg, rayon):
    """Le rayon chute sur trois secteurs : les canaux sont DANS le profil."""
    for centre in CANAUX_DEG:
        ecart = abs(((deg - centre + 180.0) % 360.0) - 180.0)
        if ecart <= CANAL_DEMI_DEG:
            return rayon - CANAL_PROFONDEUR
    return rayon


def loft(bm, anneaux, fermer_bas=True, fermer_haut=True):
    """Coud une pile de profils de MÊME longueur en un volume continu."""
    sommets = [[bm.verts.new(p) for p in anneau] for anneau in anneaux]
    for etage in range(len(sommets) - 1):
        bas, haut = sommets[etage], sommets[etage + 1]
        n = len(bas)
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((bas[i], bas[j], haut[j], haut[i]))
    if fermer_bas:
        bm.faces.new(tuple(reversed(sommets[0])))
    if fermer_haut:
        bm.faces.new(tuple(sommets[-1]))
    return sommets


def objet(nom, anneaux, nom_materiau, fermer_bas=True, fermer_haut=True):
    """Crée un objet Blender à partir d'une pile de profils."""
    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()
    loft(bm, anneaux, fermer_bas, fermer_haut)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(maillage)
    bm.free()
    obj = bpy.data.objects.new(nom, maillage)
    obj.data.materials.append(materiau(nom_materiau))
    bpy.context.collection.objects.link(obj)
    return obj


# ---------------------------------------------------------------------------
# Les pièces.
# ---------------------------------------------------------------------------
def socle():
    """Plinthe étagée — trois ressauts, pas trois blocs posés."""
    anneaux = []
    marches = 3
    for i in range(marches + 1):
        t = i / marches
        z = SOCLE_Z0 + (SOCLE_Z1 - SOCLE_Z0) * t
        r = SOCLE_R0 + (SOCLE_R1 - SOCLE_R0) * t
        # Chaque marche est un ressaut franc : on double l'anneau.
        anneaux.append(cercle(r, z, 24))
        if i < marches:
            z_haut = SOCLE_Z0 + (SOCLE_Z1 - SOCLE_Z0) * ((i + 0.72) / marches)
            anneaux.append(cercle(r, z_haut, 24))
            r_suivant = SOCLE_R0 + (SOCLE_R1 - SOCLE_R0) * ((i + 1) / marches)
            anneaux.append(cercle(r_suivant, z_haut, 24))
    return objet("SM_Pylon_Plinth", anneaux, "MAT_Pylon_Stone")


def pied(indice):
    """Un montant du tripode : section rectangulaire loftée, penchée vers l'axe.

    C'est ce qui remplace « un amas de blocs » : le pied est UN volume qui
    naît large au sol et se resserre en montant vers le collier.
    """
    angle = 2.0 * math.pi * indice / PIEDS + 0.42
    ux, uy = math.cos(angle), math.sin(angle)
    tx, ty = -uy, ux            # tangente : la largeur du pied
    anneaux = []
    etages = 6
    for i in range(etages + 1):
        t = i / etages
        z = PIED_Z0 + (PIED_Z1 - PIED_Z0) * t
        r = PIED_R0 + (PIED_R1 - PIED_R0) * t
        demi = (PIED_LARGE0 + (PIED_LARGE1 - PIED_LARGE0) * t) * 0.5
        # Épaisseur radiale : plus fine en haut, le pied « s'affile ».
        epaisseur = 1.55 - 0.72 * t
        cx, cy = ux * r, uy * r
        coins = [
            (cx + tx * demi - ux * epaisseur * 0.5, cy + ty * demi - uy * epaisseur * 0.5, z),
            (cx - tx * demi - ux * epaisseur * 0.5, cy - ty * demi - uy * epaisseur * 0.5, z),
            (cx - tx * demi + ux * epaisseur * 0.5, cy - ty * demi + uy * epaisseur * 0.5, z),
            (cx + tx * demi + ux * epaisseur * 0.5, cy + ty * demi + uy * epaisseur * 0.5, z),
        ]
        anneaux.append(coins)
    return objet("SM_Pylon_Leg_%s" % "ABC"[indice], anneaux, "MAT_Pylon_Stone")


def collier():
    """La bague où les trois pieds rejoignent le fût — la jointure se VOIT."""
    anneaux = [
        cercle(COLLIER_R0, COLLIER_Z0, 36),
        cercle(COLLIER_R0 + 0.22, COLLIER_Z0 + 0.34, 36),
        cercle(COLLIER_R0 + 0.22, COLLIER_Z1 - 0.34, 36),
        cercle(COLLIER_R1, COLLIER_Z1, 36),
    ]
    return objet("SM_Pylon_Collar", anneaux, "MAT_Pylon_Ivory")


def fut():
    """Le fût effilé, ses TROIS CANAUX creusés dans le profil lui-même."""
    anneaux = []
    etages = 14
    for i in range(etages + 1):
        t = i / etages
        z = FUT_Z0 + (FUT_Z1 - FUT_Z0) * t
        rayon = FUT_R0 + (FUT_R1 - FUT_R0) * t
        anneaux.append(cercle(rayon, z, SEGMENTS, profil_a_canaux))
    return objet("SM_Pylon_Shaft", anneaux, "MAT_Pylon_Copper")


def noyau():
    """Le fond d'ombre des canaux : un cylindre plein, plus sombre.

    Sans lui, le canal laisse voir le ciel au travers et cesse d'être un
    creux. Mesuré à la passe précédente : c'est la valeur sombre au fond
    qui fait lire le canal, pas sa largeur.
    """
    anneaux = []
    etages = 8
    for i in range(etages + 1):
        t = i / etages
        z = FUT_Z0 - 0.10 + (FUT_Z1 - FUT_Z0 + 0.20) * t
        rayon = (FUT_R0 + (FUT_R1 - FUT_R0) * t) - CANAL_PROFONDEUR - 0.06
        anneaux.append(cercle(rayon, z, 36))
    return objet("SM_Pylon_ShaftCore", anneaux, "MAT_Pylon_CoreStone")


def ceinture(indice, z):
    """Bandeau de céramique : anneau CONTINU, épaisseur constante."""
    rayon = FUT_R0 + (FUT_R1 - FUT_R0) * ((z - FUT_Z0) / (FUT_Z1 - FUT_Z0))
    externe = rayon + CEINTURE_DEBORD
    anneaux = [
        cercle(rayon, z - CEINTURE_HAUTEUR * 0.5, 48),
        cercle(externe, z - CEINTURE_HAUTEUR * 0.28, 48),
        cercle(externe, z + CEINTURE_HAUTEUR * 0.28, 48),
        cercle(rayon, z + CEINTURE_HAUTEUR * 0.5, 48),
    ]
    return objet("SM_Pylon_Belt_%d" % indice, anneaux, "MAT_Pylon_Ivory")


def anneau_incomplet():
    """L'anneau de l'Œil-Tempête : arc à section CONSTANTE, cercle ouvert.

    Balayage d'un profil rectangulaire le long d'un arc — l'épaisseur ne
    peut pas varier, elle est dans le profil. C'est ce que le lead veut
    dire par « anneaux continus avec épaisseur constante ».
    """
    maillage = bpy.data.meshes.new("SM_Pylon_Ring")
    bm = bmesh.new()
    epaisseur, hauteur = ANNEAU_SECTION
    couvert = 360.0 - ANNEAU_OUVERTURE_DEG
    pas = 44
    anneaux = []
    for i in range(pas + 1):
        deg = -couvert * 0.5 + couvert * i / pas
        a = math.radians(deg)
        ux, uy = math.cos(a), math.sin(a)
        interieur = ANNEAU_R - epaisseur * 0.5
        exterieur = ANNEAU_R + epaisseur * 0.5
        anneaux.append([
            (ux * interieur, uy * interieur, ANNEAU_Z - hauteur * 0.5),
            (ux * exterieur, uy * exterieur, ANNEAU_Z - hauteur * 0.5),
            (ux * exterieur, uy * exterieur, ANNEAU_Z + hauteur * 0.5),
            (ux * interieur, uy * interieur, ANNEAU_Z + hauteur * 0.5),
        ])
    loft(bm, anneaux, fermer_bas=True, fermer_haut=True)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(maillage)
    bm.free()
    obj = bpy.data.objects.new("SM_Pylon_Ring", maillage)
    obj.data.materials.append(materiau("MAT_Pylon_Copper"))
    bpy.context.collection.objects.link(obj)
    obj.rotation_euler = (math.radians(9.0), 0.0, math.radians(24.0))
    return obj


def console(indice):
    """Les deux consoles qui rattachent l'anneau au fût — sinon il flotte."""
    a = math.radians(90.0 + 180.0 * indice + 24.0)
    ux, uy = math.cos(a), math.sin(a)
    tx, ty = -uy, ux
    anneaux = []
    for i in range(4):
        t = i / 3.0
        r = 1.75 + (ANNEAU_R - 0.55 - 1.75) * t
        demi = 0.46 - 0.14 * t
        haut = 0.50 - 0.10 * t
        z = ANNEAU_Z - 0.30 - 0.16 * t
        cx, cy = ux * r, uy * r
        anneaux.append([
            (cx + tx * demi, cy + ty * demi, z - haut),
            (cx - tx * demi, cy - ty * demi, z - haut),
            (cx - tx * demi, cy - ty * demi, z + haut),
            (cx + tx * demi, cy + ty * demi, z + haut),
        ])
    return objet("SM_Pylon_RingBracket_%d" % indice, anneaux, "MAT_Pylon_Copper")


def dent(indice):
    """Une dent de la couronne bifide — un volume qui s'affile, pas un empilement."""
    decalage, hauteur, demi0, demi1 = DENTS[indice]
    anneaux = []
    etages = 7
    for i in range(etages + 1):
        t = i / etages
        z = COURONNE_Z + hauteur * t
        # La dent s'écarte de l'axe en montant : la fourche s'OUVRE.
        x = decalage * (0.72 + 0.55 * t)
        demi = demi0 + (demi1 - demi0) * t
        prof = demi * 1.12
        anneaux.append([
            (x - demi, -prof, z), (x + demi, -prof, z),
            (x + demi, prof, z), (x - demi, prof, z),
        ])
    return objet("SM_Pylon_Crown_%s" % ("Tall" if indice == 0 else "Short"),
                 anneaux, "MAT_Pylon_Copper")


def coiffe(indice):
    """Coiffe de céramique : ce qui capte la foudre, et la seule masse claire en haut."""
    decalage, hauteur, _, demi1 = DENTS[indice]
    x = decalage * 1.27
    z = COURONNE_Z + hauteur
    demi = demi1 * 1.45
    anneaux = [
        [(x - demi, -demi, z), (x + demi, -demi, z),
         (x + demi, demi, z), (x - demi, demi, z)],
        [(x - demi * 1.12, -demi * 1.12, z + 0.34),
         (x + demi * 1.12, -demi * 1.12, z + 0.34),
         (x + demi * 1.12, demi * 1.12, z + 0.34),
         (x - demi * 1.12, demi * 1.12, z + 0.34)],
        [(x - demi * 0.60, -demi * 0.60, z + 0.86),
         (x + demi * 0.60, -demi * 0.60, z + 0.86),
         (x + demi * 0.60, demi * 0.60, z + 0.86),
         (x - demi * 0.60, demi * 0.60, z + 0.86)],
    ]
    return objet("SM_Pylon_CrownCap_%s" % ("Tall" if indice == 0 else "Short"),
                 anneaux, "MAT_Pylon_Ivory")


def veines():
    """Le courant : une lame mince au FOND de chaque canal.

    « Cyan contenu dans les canaux » — la lame est plus étroite que le
    canal et plus profonde que ses joues : vue de face elle brille, vue de
    côté elle disparaît. Le cyan ne peut pas déborder sur la masse.
    """
    maillage = bpy.data.meshes.new("SM_Pylon_Vein")
    bm = bmesh.new()
    for centre in CANAUX_DEG:
        a = math.radians(centre)
        ux, uy = math.cos(a), math.sin(a)
        tx, ty = -uy, ux
        anneaux = []
        for i in range(9):
            t = i / 8.0
            z = VEINE_Z0 + (VEINE_Z1 - VEINE_Z0) * t
            part = (z - FUT_Z0) / (FUT_Z1 - FUT_Z0)
            r = (FUT_R0 + (FUT_R1 - FUT_R0) * part) - CANAL_PROFONDEUR + 0.05
            demi = VEINE_LARGEUR * 0.5
            cx, cy = ux * r, uy * r
            anneaux.append([
                (cx + tx * demi, cy + ty * demi, z),
                (cx - tx * demi, cy - ty * demi, z),
                (cx - tx * demi - ux * 0.09, cy - ty * demi - uy * 0.09, z),
                (cx + tx * demi - ux * 0.09, cy + ty * demi - uy * 0.09, z),
            ])
        loft(bm, anneaux)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(maillage)
    bm.free()
    obj = bpy.data.objects.new("SM_Pylon_Vein", maillage)
    obj.data.materials.append(materiau("MAT_Pylon_Cyan"))
    bpy.context.collection.objects.link(obj)
    return obj


# ---------------------------------------------------------------------------
def vider_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for bloc in (bpy.data.meshes, bpy.data.materials):
        for element in list(bloc):
            if element.users == 0:
                bloc.remove(element)


def main():
    vider_scene()
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0

    pieces = [socle(), collier(), noyau(), fut(), anneau_incomplet(), veines()]
    pieces += [pied(i) for i in range(PIEDS)]
    pieces += [ceinture(i, z) for i, z in enumerate(CEINTURES_Z)]
    pieces += [console(i) for i in range(2)]
    pieces += [dent(i) for i in range(2)]
    pieces += [coiffe(i) for i in range(2)]

    # Transforms appliqués et origines à zéro : exigence `IMPORT_RULES.md`.
    for obj in pieces:
        obj.location = (0.0, 0.0, 0.0)
        obj.scale = (1.0, 1.0, 1.0)

    minimum = min(min(v.co.z for v in o.data.vertices) for o in pieces)
    maximum = max(max(v.co.z for v in o.data.vertices) for o in pieces)
    triangles = sum(len(o.data.polygons) for o in pieces)
    print("[pylone] %d objets, %d faces, hauteur %.2f m (base z=%.3f)"
          % (len(pieces), triangles, maximum - minimum, minimum))
    if abs(minimum) > 0.01:
        print("[pylone] ERREUR: la base n'est pas à z=0 (min Y après export)")
        return 2
    if not (26.0 <= maximum - minimum <= 40.0):
        print("[pylone] ERREUR: hauteur hors du contrat [26 ; 40] m")
        return 2
    if len(pieces) < 8:
        print("[pylone] ERREUR: moins de 8 objets — le filet du pylône exige 8 MeshInstance3D")
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_Pylon_Resonance.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[pylone] source enregistrée -> %s" % sortie)
    return 0


if __name__ == "__main__":
    sys.exit(main())
