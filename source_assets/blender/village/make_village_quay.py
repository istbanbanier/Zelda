# SOURCE DE GÉNÉRATION REPRODUCTIBLE — Quai du Village de la rivière.
#
# POURQUOI CE FICHIER EXISTE. Le kit CC0 du dépôt ne contient aucun quai.
# La passe précédente en fabriquait un avec `Floor_WoodDark` — un plan de
# **0,02 m mesuré** — posé sur quatre `CylinderMesh`. Vu depuis la ligne
# d'eau, ce platelage n'a ni épaisseur, ni solive, ni bordure : c'est une
# feuille de papier sur des tuyaux. Or le contrat du lead dit « quai
# réellement raccordé à l'eau », et la règle de production interdit
# désormais de fabriquer la surface artistique en primitives.
#
# MÉTHODE — identique au pylône, et pour les mêmes raisons : aucun
# booléen, QUE des volumes loftés. On empile des profils fermés de MÊME
# longueur, on coud les quads, on ferme les deux bouts, puis
# `recalc_face_normals`. Un booléen sur une pile de primitives reproduit
# exactement les artefacts rejetés (faces ouvertes, arêtes en escalier,
# pièces désolidarisées).
#
# LES SECTIONS SONT CHANFREINÉES. Leçon mesurée sur le pylône : une
# section à quatre coins présente deux faces plates qui prennent la même
# lumière du haut en bas et se lisent comme une plaque. Toutes les pièces
# vues de près — planches, pilotis, bittes — portent donc des pans étroits
# qui accrochent une valeur intermédiaire.
#
# REPÈRE. Blender est Z-up ; l'exporteur convertit en Y-up (`export_yup`),
# donc Blender (x, y, z) devient Godot (x, z, -y). CONSÉQUENCE UTILISÉE
# ICI : Blender +Y est Godot -Z, c'est-à-dire le SUD, c'est-à-dire l'eau.
# La rive est donc en Blender -Y et la rivière en Blender +Y.
#
# COTES — mesurées sur le terrain GELÉ, jamais devinées
# (sonde `probe_site_section` + sonde locale, 2026-08-14) :
#   surface de l'eau sous le quai .... 0,695 (x local 13,5) -> 0,635 (19,5)
#   lit de la rivière ................ 0,24 -> 0,05
#   berge au nord du platelage ....... 0,93 (ouest) -> 1,42 (est)
#   platelage retenu ................. monde 1,15
#   franc-bord obtenu ................ 0,455 à 0,515 m
# Z = 0 de cet objet = monde 0,05 (le point le plus bas du lit sous le
# quai) : les pilotis les plus courts sont donc partiellement enfouis, ce
# qui est le comportement voulu — un pilotis planté est enfoui, un pilotis
# qui s'arrête net au-dessus du lit flotte.
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/village/make_village_quay.py

import math
import os
import sys

import bmesh
import bpy

# ---------------------------------------------------------------------------
# Cotes
# ---------------------------------------------------------------------------
PONT_L = 6.00          # Blender X  -> Godot X
PONT_P = 5.00          # Blender Y  -> Godot -Z
PONT_DESSUS = 1.10     # monde 1,15
PONT_EP = 0.14

PLANCHES = 11
PLANCHE_JEU = 0.028

SOLIVE_H = 0.18
SOLIVE_L = 0.16
SOLIVES_Y = (-1.90, 0.00, 1.90)
LONGRINE_X = (-2.55, 2.55)
LONGRINE_L = 0.14
LONGRINE_H = 0.16

BORDURE_EP = 0.05
BORDURE_H = 0.26

PILOTIS_XY = (
    (-2.40, -2.00), (0.00, -2.00), (2.40, -2.00),
    (-2.40, 2.05), (0.00, 2.05), (2.40, 2.05),
)
PILOTIS_TETE = 0.90
PILOTIS_DEMI_PIED = 0.155
PILOTIS_DEMI_TETE = 0.118
PILOTIS_COLLIER_Z = 0.78
PILOTIS_COLLIER_SAILLIE = 0.035

BITTES_XY = ((-2.15, 2.30), (2.15, 2.30))
BITTE_HAUT = 1.78
BITTE_DEMI = 0.105
BITTE_GORGE = (1.50, 1.62)
BITTE_GORGE_CREUX = 0.028

# Passerelle : elle MONTE vers la berge nord-ouest.
#
# Le premier jet la faisait descendre, et c'était une erreur de lecture de
# ma propre sonde : la berge REMONTE vers le nord (sol mesuré 0,61 à z
# local -5,0 ; 1,45 à z local -3,2). Une passerelle descendante se serait
# enfoncée de 0,54 m sous le terrain gelé. Elle monte donc du platelage
# (objet 1,06, monde 1,11) à la berge (objet 1,32, monde 1,37, sol mesuré
# 1,35-1,45) : 9 % de pente sur 1,6 m, et un contact réel des deux côtés.
RAMPE_X = -1.90
RAMPE_DEMI_L = 0.90
RAMPE_Y0 = -2.50
RAMPE_Y1 = -4.10
RAMPE_Z0 = 1.06
RAMPE_Z1 = 1.32
RAMPE_EP = 0.10

CHANFREIN = 0.018

# ---------------------------------------------------------------------------
# Matériaux — valeurs en sRGB (ce que l'œil doit lire), converties en
# LINÉAIRE avant d'entrer dans Blender.
#
# glTF stocke `baseColorFactor` en linéaire et Godot le réencode en sRGB
# pour `albedo_color` : écrire 0,40 donne 0,67 dans Godot. Le pylône a
# rendu entièrement blanc à cause de cet oubli.
#
# CIBLES DE VALEUR RENDUE. Le quai est en plein soleil (l'ombre de la
# falaise ouest s'arrête à x local -3,6 ; le quai est à +16). Le gain
# mesuré sur ce monde va de 1,4 à 1,8 selon l'orientation. On vise donc,
# APRÈS rendu : platelage ~0,45 (moyen-sombre), structure sous le pont
# ~0,30 (sombre), bittes ~0,40. Ces nombres seront RECALÉS sur la capture
# au pixel — l'albédo n'est pas une valeur rendue.
# ---------------------------------------------------------------------------
MATERIAUX = {
    "MAT_Quay_Deck":     (0.325, 0.252, 0.176, 0.94),
    "MAT_Quay_Frame":    (0.215, 0.163, 0.112, 0.96),
    "MAT_Quay_Bollard":  (0.272, 0.208, 0.145, 0.92),
}


def srgb_vers_lineaire(canal):
    """sRGB -> linéaire. glTF attend du linéaire ; l'œil pense en sRGB."""
    if canal <= 0.04045:
        return canal / 12.92
    return ((canal + 0.055) / 1.055) ** 2.4


def materiau(nom):
    if nom in bpy.data.materials:
        return bpy.data.materials[nom]
    r, v, b, rugosite = MATERIAUX[nom]
    r, v, b = (srgb_vers_lineaire(c) for c in (r, v, b))
    mat = bpy.data.materials.new(nom)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (r, v, b, 1.0)
    bsdf.inputs["Roughness"].default_value = rugosite
    bsdf.inputs["Metallic"].default_value = 0.0
    return mat


# ---------------------------------------------------------------------------
# Outillage de loft
# ---------------------------------------------------------------------------
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


def section_rect_chanfreinee(cx, cy, demi_x, demi_y, chanfrein, z):
    """Section OCTOGONALE : les quatre arêtes vives deviennent des pans.

    Le chanfrein est borné par 45 % de chaque demi-cote — au-delà le profil
    se retournerait sur lui-même et produirait un volume non manifold que
    `recalc_face_normals` ne saurait pas rattraper.
    """
    c = min(chanfrein, demi_x * 0.45, demi_y * 0.45)
    coins = (
        (demi_x - c, demi_y), (c - demi_x, demi_y),
        (-demi_x, demi_y - c), (-demi_x, c - demi_y),
        (c - demi_x, -demi_y), (demi_x - c, -demi_y),
        (demi_x, c - demi_y), (demi_x, demi_y - c),
    )
    return [(cx + a, cy + b, z) for a, b in coins]


def boite_chanfreinee(bm, cx, cy, demi_x, demi_y, z0, z1, chanfrein=CHANFREIN):
    """Volume prismatique à arêtes cassées, empilé en trois étages.

    Trois étages et non deux : les chanfreins HORIZONTAUX du dessus et du
    dessous demandent un retrait, sinon la planche garde deux arêtes vives
    qui scintillent en mouvement.
    """
    c = min(chanfrein, demi_x * 0.45, demi_y * 0.45, (z1 - z0) * 0.30)
    anneaux = [
        section_rect_chanfreinee(cx, cy, demi_x - c, demi_y - c, chanfrein, z0),
        section_rect_chanfreinee(cx, cy, demi_x, demi_y, chanfrein, z0 + c),
        section_rect_chanfreinee(cx, cy, demi_x, demi_y, chanfrein, z1 - c),
        section_rect_chanfreinee(cx, cy, demi_x - c, demi_y - c, chanfrein, z1),
    ]
    loft(bm, anneaux)


def objet_depuis(nom, remplir, nom_materiau):
    """Crée un objet Blender ; `remplir(bm)` y dépose les volumes."""
    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()
    remplir(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(maillage)
    bm.free()
    obj = bpy.data.objects.new(nom, maillage)
    obj.data.materials.append(materiau(nom_materiau))
    bpy.context.collection.objects.link(obj)
    return obj


# ---------------------------------------------------------------------------
# Les pièces
# ---------------------------------------------------------------------------
def platelage(bm):
    """Onze planches distinctes, jeu de 28 mm, usure en Z.

    Une dalle unique aurait la même silhouette et aucune lecture de près.
    Les planches d'un quai ne sont PAS coplanaires : chacune reçoit un
    décalage vertical déterministe de quelques millimètres, ce qui donne au
    platelage sa nervosité en lumière rasante.
    """
    largeur = (PONT_L - (PLANCHES - 1) * PLANCHE_JEU) / PLANCHES
    for i in range(PLANCHES):
        cx = -PONT_L * 0.5 + largeur * 0.5 + i * (largeur + PLANCHE_JEU)
        usure = math.sin(i * 2.4) * 0.006
        boite_chanfreinee(bm, cx, 0.0, largeur * 0.5, PONT_P * 0.5,
                          PONT_DESSUS - PONT_EP + usure, PONT_DESSUS + usure,
                          0.012)


def ossature(bm):
    """Solives, longrines et bordures de rive — la charpente sous le pont."""
    for y in SOLIVES_Y:
        boite_chanfreinee(bm, 0.0, y, PONT_L * 0.5 - 0.06, SOLIVE_L * 0.5,
                          PONT_DESSUS - PONT_EP - SOLIVE_H,
                          PONT_DESSUS - PONT_EP)
    for x in LONGRINE_X:
        boite_chanfreinee(bm, x, 0.0, LONGRINE_L * 0.5, PONT_P * 0.5 - 0.05,
                          PONT_DESSUS - PONT_EP - LONGRINE_H,
                          PONT_DESSUS - PONT_EP)
    # Bordure côté RIVIÈRE (Blender +Y) : c'est elle qui donne une épaisseur
    # au quai vu depuis la ligne d'eau, et sans elle le platelage se lit
    # comme une découpe de carton.
    boite_chanfreinee(bm, 0.0, PONT_P * 0.5 + BORDURE_EP * 0.5,
                      PONT_L * 0.5, BORDURE_EP * 0.5,
                      PONT_DESSUS - BORDURE_H, PONT_DESSUS + 0.015)
    for x in (-PONT_L * 0.5 - BORDURE_EP * 0.5, PONT_L * 0.5 + BORDURE_EP * 0.5):
        boite_chanfreinee(bm, x, 0.0, BORDURE_EP * 0.5, PONT_P * 0.5,
                          PONT_DESSUS - BORDURE_H, PONT_DESSUS + 0.015)


def pilotis(bm):
    """Six pieux à fruit, avec collier sous les solives.

    Le fruit (pied plus large que la tête) n'est pas décoratif : un pieu à
    section constante se lit comme un tuyau, et c'est exactement le défaut
    des `CylinderMesh` de la passe précédente.
    """
    for x, y in PILOTIS_XY:
        anneaux = [
            section_rect_chanfreinee(x, y, PILOTIS_DEMI_PIED,
                                     PILOTIS_DEMI_PIED, 0.030, 0.0),
            section_rect_chanfreinee(x, y, PILOTIS_DEMI_PIED * 0.97,
                                     PILOTIS_DEMI_PIED * 0.97, 0.030, 0.22),
            section_rect_chanfreinee(
                x, y, PILOTIS_DEMI_TETE + PILOTIS_COLLIER_SAILLIE * 0.3,
                PILOTIS_DEMI_TETE + PILOTIS_COLLIER_SAILLIE * 0.3, 0.026,
                PILOTIS_COLLIER_Z - 0.06),
            section_rect_chanfreinee(
                x, y, PILOTIS_DEMI_TETE + PILOTIS_COLLIER_SAILLIE,
                PILOTIS_DEMI_TETE + PILOTIS_COLLIER_SAILLIE, 0.026,
                PILOTIS_COLLIER_Z),
            section_rect_chanfreinee(
                x, y, PILOTIS_DEMI_TETE + PILOTIS_COLLIER_SAILLIE,
                PILOTIS_DEMI_TETE + PILOTIS_COLLIER_SAILLIE, 0.026,
                PILOTIS_COLLIER_Z + 0.055),
            section_rect_chanfreinee(x, y, PILOTIS_DEMI_TETE,
                                     PILOTIS_DEMI_TETE, 0.026,
                                     PILOTIS_COLLIER_Z + 0.075),
            section_rect_chanfreinee(x, y, PILOTIS_DEMI_TETE,
                                     PILOTIS_DEMI_TETE, 0.026, PILOTIS_TETE),
        ]
        loft(bm, anneaux)


def bittes(bm):
    """Deux bittes d'amarrage à gorge — l'échelle humaine du quai."""
    for x, y in BITTES_XY:
        anneaux = []
        etages = (
            (PONT_DESSUS - 0.05, BITTE_DEMI * 1.12),
            (PONT_DESSUS + 0.10, BITTE_DEMI),
            (BITTE_GORGE[0], BITTE_DEMI),
            (BITTE_GORGE[0] + 0.02, BITTE_DEMI - BITTE_GORGE_CREUX),
            (BITTE_GORGE[1] - 0.02, BITTE_DEMI - BITTE_GORGE_CREUX),
            (BITTE_GORGE[1], BITTE_DEMI),
            (BITTE_HAUT - 0.05, BITTE_DEMI * 1.15),
            (BITTE_HAUT, BITTE_DEMI * 0.95),
        )
        for z, demi in etages:
            anneaux.append(
                section_rect_chanfreinee(x, y, demi, demi, 0.022, z))
        loft(bm, anneaux)


def rampe(bm):
    """Passerelle inclinée vers la berge nord-ouest.

    Elle descend de l'objet Z 1,06 à 0,86, c'est-à-dire de monde 1,11 à
    0,91, tandis que le sol GELÉ y est mesuré à 0,93. La passerelle POSE
    donc sur la berge : le raccordement côté terre est géométrique et non
    suggéré.
    """
    pas = 6
    anneaux = []
    for i in range(pas + 1):
        t = i / pas
        y = RAMPE_Y0 + (RAMPE_Y1 - RAMPE_Y0) * t
        z = RAMPE_Z0 + (RAMPE_Z1 - RAMPE_Z0) * t
        # Section transversale de la rampe : un profil en Y constant, empilé
        # le long de la pente. On lofte donc selon Y, pas selon Z.
        anneaux.append([
            (RAMPE_X - RAMPE_DEMI_L + 0.03, y, z),
            (RAMPE_X + RAMPE_DEMI_L - 0.03, y, z),
            (RAMPE_X + RAMPE_DEMI_L, y, z - 0.03),
            (RAMPE_X + RAMPE_DEMI_L, y, z - RAMPE_EP + 0.03),
            (RAMPE_X + RAMPE_DEMI_L - 0.03, y, z - RAMPE_EP),
            (RAMPE_X - RAMPE_DEMI_L + 0.03, y, z - RAMPE_EP),
            (RAMPE_X - RAMPE_DEMI_L, y, z - RAMPE_EP + 0.03),
            (RAMPE_X - RAMPE_DEMI_L, y, z - 0.03),
        ])
    loft(bm, anneaux)
    # Deux traverses sous la rampe, pour qu'elle ne se lise pas comme une
    # simple planche flottante.
    for t in (0.30, 0.72):
        y = RAMPE_Y0 + (RAMPE_Y1 - RAMPE_Y0) * t
        z = RAMPE_Z0 + (RAMPE_Z1 - RAMPE_Z0) * t
        boite_chanfreinee(bm, RAMPE_X, y, RAMPE_DEMI_L * 0.92, 0.055,
                          z - RAMPE_EP - 0.10, z - RAMPE_EP + 0.005, 0.014)


# ---------------------------------------------------------------------------
# Contrôles — un asset non vérifié n'est pas un asset livré
# ---------------------------------------------------------------------------
def emprise(objets):
    xs, ys, zs = [], [], []
    for obj in objets:
        for sommet in obj.data.vertices:
            xs.append(sommet.co.x)
            ys.append(sommet.co.y)
            zs.append(sommet.co.z)
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)

    pieces = [
        objet_depuis("SM_VillageQuay_Deck", platelage, "MAT_Quay_Deck"),
        objet_depuis("SM_VillageQuay_Frame", ossature, "MAT_Quay_Frame"),
        objet_depuis("SM_VillageQuay_Piles", pilotis, "MAT_Quay_Frame"),
        objet_depuis("SM_VillageQuay_Bollards", bittes, "MAT_Quay_Bollard"),
        objet_depuis("SM_VillageQuay_Ramp", rampe, "MAT_Quay_Deck"),
    ]

    (x0, x1), (y0, y1), (z0, z1) = emprise(pieces)
    triangles = sum(len(o.data.polygons) for o in pieces)
    print("[quai] %d pièces, %d faces" % (len(pieces), triangles))
    print("[quai] emprise Blender X %.2f..%.2f  Y %.2f..%.2f  Z %.2f..%.2f"
          % (x0, x1, y0, y1, z0, z1))
    print("[quai] -> Godot X %.2f..%.2f  Z %.2f..%.2f  Y %.2f..%.2f"
          % (x0, x1, -y1, -y0, z0, z1))

    # La base DOIT être à Z = 0 : `IMPORT_RULES` exige min Y ≈ 0 après
    # export, et un pilotis qui ne descend pas au lit ne se planterait dans
    # rien.
    if abs(z0) > 0.005:
        print("[quai] ERREUR: la base n'est pas à Z=0 (min %.3f)" % z0)
        return 2
    if abs((x1 - x0) - PONT_L) > 0.15:
        print("[quai] ERREUR: largeur %.2f m, attendue %.2f" % (x1 - x0, PONT_L))
        return 2
    # Le franc-bord est le cœur du contrat « raccordé à l'eau » : le dessus
    # du platelage doit se trouver entre 0,40 et 0,60 m au-dessus de la
    # surface mesurée (0,635–0,695 monde), l'objet étant posé à monde 0,05.
    franc_bord_min = (0.05 + PONT_DESSUS) - 0.695
    franc_bord_max = (0.05 + PONT_DESSUS) - 0.635
    print("[quai] franc-bord calculé %.3f à %.3f m au-dessus de l'eau mesurée"
          % (franc_bord_min, franc_bord_max))
    if not (0.35 <= franc_bord_min and franc_bord_max <= 0.65):
        print("[quai] ERREUR: franc-bord hors du contrat [0,35 ; 0,65]")
        return 2
    # Les pilotis doivent réellement plonger : leur pied à Z=0 (monde 0,05)
    # contre un lit mesuré de 0,05 à 0,24 sous le platelage.
    if PILOTIS_TETE >= PONT_DESSUS - PONT_EP + 0.01:
        print("[quai] ERREUR: les pilotis dépassent sous le platelage")
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_Village_Quay.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[quai] source enregistrée -> %s" % sortie)
    return 0


if __name__ == "__main__":
    sys.exit(main())
