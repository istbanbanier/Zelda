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

PIEDS = 3
PIED_ANCRAGE_R = 4.05   # rayon des appuis déclarés côté GDScript — ne pas désaccorder

# R2a-4.1 — LE PIED N'EST PLUS UN TRONC DE PYRAMIDE À QUATRE ARÊTES.
#
# Le lead a lu « de grandes plaques rectangulaires ». C'est exact et c'est
# géométrique : une section à quatre coins présente, à toute distance, deux
# faces plates de plus d'un mètre de large qui prennent la même lumière du
# haut en bas. Deux corrections, pas une :
#   1. la section devient OCTOGONALE CHANFREINÉE — les quatre arêtes vives
#      sont remplacées par des pans étroits qui accrochent une valeur
#      intermédiaire, et la plaque cesse d'être plate ;
#   2. le montant reçoit une TRANSITION CONSTRUITE aux deux bouts — un
#      sabot noyé dans la plinthe en bas, un chapiteau évasé sous le
#      collier en haut. Un pied qui s'arrête net est un bloc posé ; un pied
#      qui s'évase à sa rencontre est une structure.
#
# LARGEUR TANGENTIELLE RÉDUITE APRÈS MESURE SUR SILHOUETTE. Le premier jet
# R2a-4.1 donnait 1,80 m de demi-largeur au sabot : sur la silhouette
# isolée à 90°, les trois pieds se rejoignaient en une jupe trapézoïdale
# percée de deux fentes. Trois volumes séparés dans le maillage ne font pas
# trois pieds séparés à l'œil — c'est la PROJECTION qui décide. À 1,32 m,
# la corde entre deux pieds voisins (7,01 m à r = 4,05) laisse passer le
# fond entre eux sous tout azimut.
#
# L'épaisseur RADIALE reste supérieure à la largeur : proportion de
# contrefort. Vue de face le pied est étroit, vu de côté il est profond —
# jamais une plaque, quel que soit l'angle.
#
# (z, rayon du centre, demi-largeur, épaisseur radiale, chanfrein)
PIED_ETAGES = (
    (0.85, PIED_ANCRAGE_R, 1.32, 1.86, 0.14),   # NOYÉ dans la plinthe
    (1.58, PIED_ANCRAGE_R, 1.32, 1.86, 0.30),   # corps du sabot
    (1.84, 3.96, 1.16, 1.62, 0.32),             # ressaut : la jointure se VOIT
    (2.30, 3.88, 1.06, 1.50, 0.32),             # naissance du montant
    (3.20, 3.55, 0.96, 1.34, 0.30),
    (4.10, 3.20, 0.86, 1.18, 0.28),
    (5.00, 2.90, 0.76, 1.04, 0.26),
    (5.85, 2.66, 0.68, 0.92, 0.22),
    (6.20, 2.60, 0.65, 0.88, 0.18),
    (6.48, 2.58, 0.78, 1.04, 0.16),             # chapiteau : le pied s'ÉVASE
    (7.10, 2.56, 0.70, 0.94, 0.12),             # noyé dans le collier
)

COLLIER_Z0, COLLIER_Z1 = 6.30, 7.40
COLLIER_R0, COLLIER_R1 = 2.95, 2.60

FUT_Z0, FUT_Z1 = 7.10, 25.20
FUT_R0, FUT_R1 = 2.50, 1.60
CANAL_PROFONDEUR = 0.62
CANAL_DEMI_DEG = 13.0
CANAUX_DEG = (30.0, 150.0, 270.0)
# R2a-4.1 : deux nervures encadrent chaque canal. Voir `profil_a_canaux`.
NERVURE_DEMI_DEG = 6.0
NERVURE_SAILLIE = 0.22

CEINTURES_Z = (12.20, 18.60)
CEINTURE_HAUTEUR = 0.62
CEINTURE_DEBORD = 0.34   # > NERVURE_SAILLIE : le bandeau reste en saillie sur les nervures

ANNEAU_Z = 22.30
ANNEAU_R = 4.35
ANNEAU_SECTION = (0.62, 0.78)   # épaisseur radiale, hauteur — CONSTANTES
ANNEAU_OUVERTURE_DEG = 84.0     # le cercle reste INCOMPLET (Œil-Tempête)
ANNEAU_BASCULE_DEG = 14.0       # l'anneau se lit comme un anneau, pas comme un trait
# L'OUVERTURE NE REGARDE PAS LA CAMÉRA, ELLE SE PRÉSENTE DE PROFIL.
# Premier jet R2a-4.1 : ouverture pointée droit sur l'objectif (azimut monde
# 130°, caméras de composition et de 96 m à 128° et 130,5°). Vérifié sur la
# capture : les deux extrémités de l'arc viennent vers l'objectif et
# l'anneau se lit comme une BARRE horizontale — à 96 m, deux cornes. On
# voyait l'ouverture sans voir l'anneau, ce qui ne remplit qu'une moitié de
# la demande. À 90° de l'axe de vue, l'arc se projette en ellipse et la
# morsure tombe sur son bord : anneau ET ouverture lisibles d'un coup.
# Azimut monde de l'ouverture = -(180 + ANNEAU_ORIENTATION_DEG) = 218°.
ANNEAU_ORIENTATION_DEG = -38.0
ANNEAU_CONSOLES_DEG = (-90.0, 90.0)   # de part et d'autre de l'ouverture

COURONNE_Z = 24.60
# LA FOURCHE N'EST PLUS PLANE, et c'est une correction de LISIBILITÉ, pas
# de style. Mesuré sur la silhouette isolée : deux dents décalées sur le
# seul axe X s'alignent exactement l'une derrière l'autre vue selon X — à
# 0°, la couronne bifide se lisait comme une simple flèche. Un repère
# majeur visible de toute la vallée ne peut pas perdre sa signature sur un
# demi-tour. Un décalage Y en sens opposé garantit deux pointes distinctes
# sous tout azimut.
# (décalage X, décalage Y, hauteur, demi-largeur au pied, demi-largeur au sommet)
DENTS = (
    (1.55, 0.62, 9.10, 0.92, 0.28),
    (-1.30, -0.70, 6.40, 0.78, 0.24),
)

VEINE_LARGEUR = 0.30
# R2a-4.1 : le cyan n'est plus un tube continu. Une seule LECTURE verticale,
# mais interrompue — et les coupures tombent aux deux bandeaux de céramique,
# qui traversent le canal. Longueurs décroissantes vers le haut : l'œil monte.
VEINE_INSERTS = (
    (8.30, 10.30),
    (10.75, 11.80),
    (12.60, 14.20),
    (14.65, 16.00),
    (16.45, 17.55),
    (18.95, 20.15),
    (20.60, 21.60),
    (22.05, 22.85),
    (23.25, 23.90),
)

SEGMENTS = 120   # 3° — il FAUT résoudre une nervure de 6°, que 5° écrasait


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
# R2a-4.1 : trois VALEURS séparées, pas trois teintes voisines. Au premier
# jet, pierre 0,31 et cuivre 0,27 ne différaient que de quatre centièmes :
# la masse lisait uniformément pâle, exactement ce que le lead refuse. La
# hiérarchie est maintenant portée par l'ÉCART DE VALEUR — bronze oxydé
# sombre, pierre moyenne, ivoire clair — et non par la teinte.
#
# CALIBRÉ SUR LA CAPTURE, PAS SUR L'INTENTION. Le premier jet R2a-4.1
# posait pierre 0,34 / cuivre 0,21 / ivoire 0,44 en pensant tenir une
# hiérarchie. Mesuré ensuite au pixel sur `pylone_composition.png` :
#
#   fût (cuivre) éclairé   0,486      anneau (cuivre) à l'ombre  0,300
#   plinthe (pierre) éclairée 0,609   pied (pierre) à l'ombre    0,447
#   collier (ivoire) éclairé  0,782   bandeau (ivoire) à l'ombre 0,403
#
# L'écart d'ÉCLAIREMENT (×1,63 entre face au soleil et face à l'ombre)
# égalait exactement l'écart de MATIÈRE (0,34/0,21 = ×1,62). Résultat : le
# cuivre éclairé (0,49) tombait sur la pierre ombrée (0,45) et l'ivoire
# ombré (0,40). Trois matières, une seule valeur perçue — « une masse
# uniformément pâle », le défaut nommé par le lead. À 96 m, le pylône ne se
# détachait plus des falaises claires du fond.
#
# La correction n'est pas cosmétique : pour qu'une hiérarchie de matière
# SURVIVE à l'éclairement, son écart doit le dépasser. Le cuivre descend
# donc à 0,145 (rendu attendu ≈ 0,36 éclairé), la pierre à 0,30 (≈ 0,54),
# l'ivoire à 0,37 (≈ 0,65) — trois valeurs séparées d'environ 0,15 chacune,
# soit plus que ce que l'ombre peut combler.
MATERIAUX = {
    "MAT_Pylon_Stone": (0.30, 0.275, 0.23, 0.92, None),
    "MAT_Pylon_Copper": (0.145, 0.175, 0.15, 0.58, None),
    "MAT_Pylon_Ivory": (0.37, 0.355, 0.30, 0.52, None),
    "MAT_Pylon_CoreStone": (0.045, 0.05, 0.045, 0.96, None),
    "MAT_Pylon_Cyan": (0.05, 0.15, 0.175, 0.35, (0.12, 0.82, 0.90)),
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
        # R2a-4.1 : 1,4 faisait de la veine la source de lumière du sujet et
        # noyait les joues du canal. Le cyan est un ACCENT ; la lecture du
        # creux appartient à la géométrie.
        bsdf.inputs["Emission Strength"].default_value = 0.85
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
    """Le rayon chute sur trois secteurs : les canaux sont DANS le profil.

    R2a-4.1 — LE CREUX DOIT SE LIRE CYAN COUPÉ. Un simple décrochement
    radial ne donne qu'une bande sombre ; à contre-jour elle se confond
    avec l'ombre propre du fût. On ajoute donc, de part et d'autre de
    chaque canal, une NERVURE en saillie : le canal est alors encadré de
    deux arêtes qui prennent la lumière, et l'œil lit un creux entre deux
    reliefs — même sans une seule lumière cyan. C'est la géométrie qui
    porte le canal, jamais l'émission.
    """
    for centre in CANAUX_DEG:
        ecart = abs(((deg - centre + 180.0) % 360.0) - 180.0)
        if ecart <= CANAL_DEMI_DEG:
            return rayon - CANAL_PROFONDEUR
        if ecart <= CANAL_DEMI_DEG + NERVURE_DEMI_DEG:
            return rayon + NERVURE_SAILLIE
    return rayon


def section_chanfreinee(cx, cy, tx, ty, ux, uy, demi, epaisseur, chanfrein, z):
    """Section OCTOGONALE : les quatre arêtes vives deviennent des pans.

    `t` = axe tangent (la largeur du montant), `u` = axe radial (l'épaisseur).
    Le chanfrein est borné par la moitié de chaque demi-cote : une valeur
    trop grande retournerait le profil sur lui-même et produirait un volume
    non manifold que `recalc_face_normals` ne saurait pas rattraper.
    """
    demi_ep = epaisseur * 0.5
    c = min(chanfrein, demi * 0.45, demi_ep * 0.45)
    coins = (
        (demi - c, demi_ep), (c - demi, demi_ep),
        (-demi, demi_ep - c), (-demi, c - demi_ep),
        (c - demi, -demi_ep), (demi - c, -demi_ep),
        (demi, c - demi_ep), (demi, demi_ep - c),
    )
    return [(cx + tx * a + ux * b, cy + ty * a + uy * b, z) for a, b in coins]


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
    """Un montant du tripode : section OCTOGONALE loftée, effilée vers l'axe.

    Les trois pieds restent CLAIREMENT SÉPARÉS — ils ne se rejoignent qu'au
    collier — et chacun descend jusqu'à z = 0,85, sous le dessus de la
    plinthe (z = 1,70) : le pied SORT de la maçonnerie au lieu d'être posé
    dessus. C'est ce que veut dire « réellement ancrés ».
    """
    angle = 2.0 * math.pi * indice / PIEDS + 0.42
    ux, uy = math.cos(angle), math.sin(angle)
    tx, ty = -uy, ux            # tangente : la largeur du pied
    anneaux = []
    for z, rayon, demi, epaisseur, chanfrein in PIED_ETAGES:
        anneaux.append(section_chanfreinee(
            ux * rayon, uy * rayon, tx, ty, ux, uy,
            demi, epaisseur, chanfrein, z))
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
    """Le fond d'ombre des canaux : un cylindre plein, nettement plus sombre.

    IL RESSORT MAINTENANT DE 4 cm DANS LE CANAL, et c'est tout le sujet.
    Auparavant il était 6 cm DERRIÈRE le fond du canal — donc invisible :
    le profil du fût porte son propre fond, et c'était lui qu'on voyait, en
    bronze. Balayage horizontal d'une bande sans insert cyan, avant
    correction : flanc 0,203 · nervure 0,262 · FOND DU CANAL 0,203. Le
    creux avait exactement la valeur de la surface qui l'entoure ; seule la
    veine cyan le signalait, ce que le lead refuse expressément.

    À +0,04, la pierre sombre devient la surface vue au fond du canal, et
    le fût reste intact partout ailleurs — hors des trois secteurs, son
    rayon est supérieur de 0,58 m.
    """
    anneaux = []
    etages = 8
    for i in range(etages + 1):
        t = i / etages
        z = FUT_Z0 - 0.10 + (FUT_Z1 - FUT_Z0 + 0.20) * t
        rayon = (FUT_R0 + (FUT_R1 - FUT_R0) * t) - CANAL_PROFONDEUR + 0.04
        anneaux.append(cercle(rayon, z, 48))
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


def repere_anneau(point):
    """Repère LOCAL de l'anneau (centre à l'origine, plan XY) -> monde.

    POURQUOI CETTE FONCTION EXISTE — c'est la cause mesurée du défaut que le
    lead décrit par « une portion semble flotter ou seulement traverser le
    fût ». La passe précédente basculait l'anneau par `obj.rotation_euler`,
    et une rotation d'objet tourne autour de l'ORIGINE DE L'OBJET, qui est
    au sol. Un basculement de 9° appliqué à un anneau situé à z = 22,30
    déplace donc son centre de 22,30 × sin 9° = **3,49 m** de côté. Rayon
    intérieur 4,04, décentrement 3,49 : la bande passait littéralement à
    travers le fût d'un côté et pendait dans le vide de l'autre.
    Ce n'était pas un défaut de dessin, c'était un pivot au mauvais endroit.

    Ici le basculement est appliqué AUTOUR DU CENTRE DE L'ANNEAU, dans les
    coordonnées mêmes des sommets, puis l'ouverture est orientée. Les
    consoles empruntent le même repère : elles ne peuvent plus se décoller.
    """
    x, y, z = point
    c, s = math.cos(math.radians(ANNEAU_BASCULE_DEG)), math.sin(math.radians(ANNEAU_BASCULE_DEG))
    y, z = y * c - z * s, y * s + z * c
    c, s = math.cos(math.radians(ANNEAU_ORIENTATION_DEG)), math.sin(math.radians(ANNEAU_ORIENTATION_DEG))
    x, y = x * c - y * s, x * s + y * c
    return (x, y, z + ANNEAU_Z)


def anneau_incomplet():
    """L'anneau de l'Œil-Tempête : arc à section CONSTANTE, cercle ouvert.

    Balayage d'un profil rectangulaire le long d'un arc — l'épaisseur ne
    peut pas varier, elle est dans le profil. C'est ce que le lead veut
    dire par « anneaux continus avec épaisseur constante ».

    L'ouverture est centrée sur l'azimut local 180°, donc sur
    `180 + ANNEAU_ORIENTATION_DEG` en monde : elle regarde les caméras de
    composition et de 96 m. Corde de l'ouverture : 2 × 4,35 × sin 42° =
    5,82 m — mesurable à l'œil à cette distance.
    """
    maillage = bpy.data.meshes.new("SM_Pylon_Ring")
    bm = bmesh.new()
    epaisseur, hauteur = ANNEAU_SECTION
    couvert = 360.0 - ANNEAU_OUVERTURE_DEG
    pas = 60
    anneaux = []
    for i in range(pas + 1):
        a = math.radians(-couvert * 0.5 + couvert * i / pas)
        ux, uy = math.cos(a), math.sin(a)
        interieur = ANNEAU_R - epaisseur * 0.5
        exterieur = ANNEAU_R + epaisseur * 0.5
        anneaux.append([repere_anneau(p) for p in (
            (ux * interieur, uy * interieur, -hauteur * 0.5),
            (ux * exterieur, uy * exterieur, -hauteur * 0.5),
            (ux * exterieur, uy * exterieur, hauteur * 0.5),
            (ux * interieur, uy * interieur, hauteur * 0.5),
        )])
    loft(bm, anneaux, fermer_bas=True, fermer_haut=True)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(maillage)
    bm.free()
    obj = bpy.data.objects.new("SM_Pylon_Ring", maillage)
    obj.data.materials.append(materiau("MAT_Pylon_Copper"))
    bpy.context.collection.objects.link(obj)
    return obj


def console(indice):
    """Les deux consoles qui rattachent l'anneau au fût — sinon il flotte.

    Construites DANS LE REPÈRE DE L'ANNEAU : la console naît au cœur du fût
    (rayon local 1,10, sous le rayon du fût à cette hauteur ≈ 1,74) et meurt
    exactement sur la face intérieure de l'anneau. Aucun jeu possible.

    Elle est LISIBLE parce qu'elle est une vraie pièce et non un tirant :
    haute à la naissance, effilée à l'arrivée, avec un tasseau sous
    l'anneau. À 96 m on doit voir DEUX bras porter la couronne ouverte.
    """
    base = math.radians(180.0 + ANNEAU_CONSOLES_DEG[indice])
    ux, uy = math.cos(base), math.sin(base)
    tx, ty = -uy, ux
    # (rayon local, demi-largeur, demi-hauteur, décalage vertical)
    etages = (
        (1.10, 0.52, 0.72, -0.02),
        (1.95, 0.48, 0.66, -0.06),
        (3.05, 0.36, 0.48, -0.12),
        (ANNEAU_R - ANNEAU_SECTION[0] * 0.5 - 0.02, 0.30, 0.40, -0.16),
        (ANNEAU_R + ANNEAU_SECTION[0] * 0.5 * 0.4, 0.28, 0.30, -0.20),
    )
    anneaux = []
    for rayon, demi, haut, dz in etages:
        cx, cy = ux * rayon, uy * rayon
        anneaux.append([repere_anneau(p) for p in (
            (cx + tx * demi, cy + ty * demi, dz - haut),
            (cx - tx * demi, cy - ty * demi, dz - haut),
            (cx - tx * demi, cy - ty * demi, dz + haut),
            (cx + tx * demi, cy + ty * demi, dz + haut),
        )])
    return objet("SM_Pylon_RingBracket_%d" % indice, anneaux, "MAT_Pylon_Copper")


def dent(indice):
    """Une dent de la couronne bifide — un volume qui s'affile, pas un empilement.

    R2a-4.1 : section octogonale chanfreinée et effilement porté à 3,3× (la
    dent passe de 0,92 m à 0,28 m de demi-largeur). L'ancienne dent perdait
    à peine la moitié de sa cote sur neuf mètres : en miniature elle lisait
    comme une barre à section constante, et sa coiffe comme un cube posé.
    """
    dx, dy, hauteur, demi0, demi1 = DENTS[indice]
    anneaux = []
    etages = 9
    for i in range(etages + 1):
        t = i / etages
        z = COURONNE_Z + hauteur * t
        # La dent s'écarte de l'axe en montant : la fourche s'OUVRE.
        ouverture = 0.72 + 0.55 * t
        # Effilement en puissance : la dent garde du corps en bas et se
        # resserre franchement dans le dernier tiers.
        demi = demi0 + (demi1 - demi0) * (t ** 0.72)
        anneaux.append(section_chanfreinee(
            dx * ouverture, dy * ouverture, 1.0, 0.0, 0.0, 1.0,
            demi, demi * 2.24, demi * 0.34, z))
    return objet("SM_Pylon_Crown_%s" % ("Tall" if indice == 0 else "Short"),
                 anneaux, "MAT_Pylon_Copper")


def coiffe(indice):
    """Coiffe de céramique : ce qui capte la foudre, et la seule masse claire en haut.

    Ce n'était PAS une coiffe mais trois carrés empilés — d'où « des pointes
    qui ressemblent à des cubes posés ». C'est maintenant un volume unique :
    un col, un léger débord, puis un effilement jusqu'à une facette de
    quelques centimètres. La pointe se termine, elle ne s'arrête pas.
    """
    dx, dy, hauteur, _, demi1 = DENTS[indice]
    ouverture = 0.72 + 0.55
    x, y = dx * ouverture, dy * ouverture
    z = COURONNE_Z + hauteur
    # (dz, facteur de demi-largeur)
    etages = ((-0.18, 1.06), (0.10, 1.34), (0.42, 1.18), (0.86, 0.66), (1.24, 0.22))
    anneaux = []
    for dz, facteur in etages:
        demi = max(demi1 * facteur, 0.04)
        anneaux.append(section_chanfreinee(
            x, y, 1.0, 0.0, 0.0, 1.0,
            demi, demi * 2.0, demi * 0.36, z + dz))
    return objet("SM_Pylon_CrownCap_%s" % ("Tall" if indice == 0 else "Short"),
                 anneaux, "MAT_Pylon_Ivory")


def veines():
    """Le courant : des INSERTS séparés au fond de chaque canal.

    « Cyan contenu dans les canaux » — la lame est plus étroite que le
    canal et plus profonde que ses joues : vue de face elle brille, vue de
    côté elle disparaît. Le cyan ne peut pas déborder sur la masse.

    R2a-4.1 — LE TUBE LUMINEUX CONTINU EST SUPPRIMÉ. Une bande unique de
    quinze mètres se lit comme un néon, et c'est la lumière qui portait
    alors le canal : cyan coupé, il ne restait qu'un décrochement. Le
    courant est maintenant découpé en neuf inserts dont les coupures
    tombent aux bandeaux, avec des longueurs décroissantes vers le haut.
    La LECTURE reste une seule verticale ; le RYTHME en fait un mécanisme.
    """
    maillage = bpy.data.meshes.new("SM_Pylon_Vein")
    bm = bmesh.new()
    demi = VEINE_LARGEUR * 0.5
    for centre in CANAUX_DEG:
        a = math.radians(centre)
        ux, uy = math.cos(a), math.sin(a)
        tx, ty = -uy, ux
        for z0, z1 in VEINE_INSERTS:
            anneaux = []
            for z in (z0, z0 + (z1 - z0) * 0.5, z1):
                part = (z - FUT_Z0) / (FUT_Z1 - FUT_Z0)
                # +0,14 et non +0,05 : le noyau sombre affleure désormais à
                # +0,04 dans le canal, et une veine à +0,05 s'y serait
                # enterrée à moitié. Elle reste 0,10 devant lui, et 0,48
                # sous le nu du fût — le cyan ne peut pas déborder.
                r = (FUT_R0 + (FUT_R1 - FUT_R0) * part) - CANAL_PROFONDEUR + 0.14
                cx, cy = ux * r, uy * r
                anneaux.append([
                    (cx + tx * demi, cy + ty * demi, z),
                    (cx - tx * demi, cy - ty * demi, z),
                    (cx - tx * demi - ux * 0.05, cy - ty * demi - uy * 0.05, z),
                    (cx + tx * demi - ux * 0.05, cy + ty * demi - uy * 0.05, z),
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


def rayon_fut(z):
    """Rayon nominal du fût à l'altitude z (hors nervures et canaux)."""
    t = min(max((z - FUT_Z0) / (FUT_Z1 - FUT_Z0), 0.0), 1.0)
    return FUT_R0 + (FUT_R1 - FUT_R0) * t


def controle_anneau(objet_anneau):
    """L'anneau ne doit NI traverser le fût, NI se décentrer.

    C'est le contrôle qui aurait rougi sur la passe précédente, et c'est
    pour cela qu'il existe. Basculé par `rotation_euler` autour de l'origine
    du monde, l'anneau était décentré de 3,49 m : son sommet le plus proche
    de l'axe tombait à 0,86 m du centre, pour un fût de 1,74 m de rayon —
    la bande passait DANS le fût. Mesure d'aujourd'hui imprimée ci-dessous.

    On ne mesure PAS un « centre » : l'arc est incomplet, sa moyenne est
    biaisée du côté couvert et ne prouverait rien. On mesure la distance à
    l'axe de chaque sommet. Un anneau bien basculé autour de son centre se
    projette en ellipse : toutes les distances tombent dans
    [R·cos(bascule) − e/2 ; R + e/2], soit ici [3,91 ; 4,66] m.

    Retourne (distance minimale à l'axe, rayon du fût à cette hauteur,
    distance maximale à l'axe).
    """
    sommets = [v.co for v in objet_anneau.data.vertices]
    mini, rayon_local, maxi = None, 0.0, 0.0
    for co in sommets:
        distance = math.hypot(co.x, co.y)
        maxi = max(maxi, distance)
        if mini is None or distance < mini:
            mini, rayon_local = distance, rayon_fut(co.z)
    return mini, rayon_local, maxi


def main():
    vider_scene()
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0

    anneau = anneau_incomplet()
    pieces = [socle(), collier(), noyau(), fut(), anneau, veines()]
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

    mini, rayon_local, maxi = controle_anneau(anneau)
    print("[pylone] anneau : distance à l'axe %.2f–%.2f m (étalement %.2f), "
          "fût %.2f m au plus près" % (mini, maxi, maxi - mini, rayon_local))
    if mini <= rayon_local + 0.40:
        print("[pylone] ERREUR: l'anneau traverse le fût (%.2f m contre %.2f m) — "
              "pivot de basculement au mauvais endroit" % (mini, rayon_local))
        return 2
    # Le minimum a une forme fermée EXACTE : il est atteint au sommet de
    # l'arc situé sur l'axe de basculement, arête intérieure haute.
    # (Le maximum, lui, tombe à un azimut intermédiaire et ne se met pas
    # proprement en formule — on le borne par l'étalement, qui est le vrai
    # invariant : un anneau centré se projette en ellipse étroite.)
    attendu = ((ANNEAU_R - ANNEAU_SECTION[0] * 0.5)
               * math.cos(math.radians(ANNEAU_BASCULE_DEG))
               - ANNEAU_SECTION[1] * 0.5 * math.sin(math.radians(ANNEAU_BASCULE_DEG)))
    if abs(mini - attendu) > 0.03:
        print("[pylone] ERREUR: l'anneau est décentré (min %.3f, attendu %.3f)"
              % (mini, attendu))
        return 2
    # Étalement d'un anneau centré : 0,85 m. Décentré de 3,49 m comme à la
    # passe précédente : plus de 7 m. Le seuil ne peut pas se tromper.
    if maxi - mini > 1.10:
        print("[pylone] ERREUR: l'anneau n'est pas centré sur l'axe "
              "(étalement %.2f m, attendu ≈ 0,85)" % (maxi - mini))
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_Pylon_Resonance.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[pylone] source enregistrée -> %s" % sortie)
    return 0


if __name__ == "__main__":
    sys.exit(main())
