# SOURCE DE GÉNÉRATION REPRODUCTIBLE — Tour de guet ruinée (V2.3-B LOT 1.R,
# voie B).
#
# POURQUOI CE FICHIER EXISTE. Le gate visuel du lot 1 a rejeté la tour bâtie
# en modules de kit : « elle se lit encore comme un empilement de boîtes ».
# La cause est la même que celle mesurée sur la ferme en R2B.1 : les modules
# `Wall_UnevenBrick_Straight` sont des PLANS stricts sans face de chant
# (6 m² pour deux triangles), toutes les arases tombent à la même hauteur
# (écart-type 0,050 m sur la ferme), et rien ne montre l'épaisseur du mur.
# Le précédent ACCEPTÉ du dépôt est `SM_Farm_Ruins.glb` : arrachements en
# gradins d'assise, murs qui meurent dans un talus, épaisseur visible dans
# les brèches. Ce générateur transpose cette famille de formes à une tour.
#
# CE QUE LE GLB PORTE, ET CE QU'IL NE PORTE PAS. Il porte la maçonnerie :
# le fût carré aux quatre murs d'arases franchement différentes, la brèche
# d'angle nord-est (l'ENTRÉE), les volées d'escalier INTÉGRÉES à la
# maçonnerie, les corbeaux et bouts de solives des deux planchers disparus,
# le talus d'effondrement, deux pans de mur tombés et un bloc de couronne.
# Il ne porte PAS l'implantation : le lieu (`watchtower_ruin_place.gd`)
# pose chaque pièce sur SON sol et déclare ses appuis — mêmes contrats
# qu'avant, seul le langage de forme change.
#
# REPÈRES. Blender est Z-up ; l'export convertit en Y-up : Blender (x, y, z)
# devient Godot (x, z, -y). Ici Blender +x = Godot +x = l'EST (la falaise),
# Blender +y = Godot -z = le NORD. La brèche d'entrée est au quadrant
# nord-est, comme dans le lieu validé par les filets D2/D4.
#
# COTES HÉRITÉES DU LIEU (et vérifiées par ses colliders) :
#   * murs sur les axes ±2,0 m, épaisseur 0,45 m (colliders 0,45 m) ;
#   * mur ouest le plus haut ~9 m (le collider ouest fait 9,1 m) ;
#   * travée est debout ~3 m (collider est : 3,2 m) ;
#   * l'entrée par la brèche nord-est reste OUVERTE (garde ci-dessous).
#
# BUDGET VERROUILLÉ AVANT MODÉLISATION (brief voie B) : tour ≤ 12 000
# triangles. Le générateur REFUSE d'enregistrer au-delà, comme la ferme.
#
# MATÉRIAUX. Deux : MAT_Tower_Stone et MAT_Tower_Wood. Comme pour la ferme,
# la couleur plate n'est PAS la matière finale : le lieu branche les cartes
# du kit (`T_UnevenBrick_*`, `T_WoodTrim_*`) sur ces noms de matériau — la
# pierre de la tour est celle des murs du monde, à teinte plus froide.
# Les UV sont donc dépliés ICI, à l'échelle mesurée du kit (0,48 UV/m).
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/architecture/make_watchtower_ruin.py

import math
import os
import sys

import bmesh
import bpy

# ---------------------------------------------------------------------------
# Cotes
# ---------------------------------------------------------------------------
# LOT 1.R.1 — LA TOUR CESSE D'ÊTRE MINCE, ET C'EST UNE COTE, PAS UN AVIS.
#
# Verdict Codex (inspection réelle) : « la tour reste trop mince ». Mesuré sur
# `silhouette_watchtower_ruin_000.png` : un rectangle plein de 265 × 510 px,
# sans un seul trou ; et sur `watchtower_gp_lointain.png` (86 m) : un bâton de
# 50 × 95 px. Un mur de 0,45 m pour neuf mètres de haut est un DÉCOR de mur —
# on ne voit jamais son épaisseur, parce qu'aucune arase rompue n'en montre la
# coupe.
#
# Deux gestes, et le premier gouverne le second :
#   * `EP` 0,45 -> 0,85 m. L'épaisseur croît VERS L'EXTÉRIEUR : `HALF` est la
#     LIGNE MOYENNE du mur, et `HALF - EP/2` (le nu intérieur) reste à 1,775 m,
#     exactement où il était. Toute la géométrie intérieure — vigie, corbeaux,
#     escalier, solives — est écrite en `-HALF + EP*0.5` et ne bouge donc PAS
#     d'un millimètre ; la garde de la capsule non plus.
#   * empreinte extérieure 4,45 -> 5,25 m, plus un empattement de 0,25 m au
#     pied : 5,75 m au sol. Le terrain le permet — coupe mesurée le 2026-08-25,
#     `coupe_tour.log` : plateau plat à 26,0 m de x −168 à x −157, la falaise
#     ne tombe qu'à partir de x = −156, soit 3 m à l'est du fût.
HALF = 2.20           # LIGNE MOYENNE des murs (nu intérieur = HALF - EP/2)
EP = 0.85             # épaisseur de mur — VISIBLE en coupe à chaque arase
NU = HALF - EP * 0.5  # nu intérieur, invariant : 1,775 m
EMPATTEMENT = 0.25    # débord du socle au pied du mur
ASSISE = 0.28         # hauteur d'un lit de pose : le PAS des gradins
BUDGET_TRIS = 12000
BASE_TOL_DESSOUS = 0.005
BASE_TOL_DESSUS = 0.05

# Arases de départ par mur. QUATRE hauteurs franchement différentes : c'est
# la correction du reproche central (« empilement de boîtes » = toutes les
# arases à la même cote). L'écart ouest/est vaut 5,9 m.
H_OUEST = 8.95
H_OUEST_FIN = 7.55
H_NORD = 6.45
H_NORD_FIN = 1.55
H_SUD = 5.85
H_SUD_FIN = 3.05
H_EST = 3.05
# 2,05 et non 1,35 : la travée est doit porter une PORTE de 1,85 m avec son
# linteau, et l'arase plongeait trop vite pour lui laisser la place. Elle
# descend toujours d'un mètre sur 2,45 m et reste la plus basse des quatre
# (l'écart d'arases, que la garde 1 mesure, ne bouge pas : il se calcule sur
# les hauteurs de DÉPART). Le paysage entre toujours par-dessus depuis la
# vigie, dont la dalle est à 3,05 m.
H_EST_FIN = 2.05

# La brèche d'entrée (quadrant nord-est) : le mur nord s'arrête à cet x, la
# travée est s'arrête à ce y. Entre les deux : RIEN — c'est la porte.
BRECHE_X_NORD = 0.95
BRECHE_Y_EST = -0.175

MATERIAUX = {
    "MAT_Tower_Stone": (0.560, 0.510, 0.450, 0.95),
    "MAT_Tower_Wood": (0.330, 0.260, 0.185, 0.95),
    # PAREMENT INTÉRIEUR : même pierre, valeur descendue. Mesuré sur la
    # capture d'itération 1 : sous llvmpipe, la face intérieure du mur
    # ouest — vue par la brèche — rend AUSSI CLAIR que l'extérieur au
    # soleil, et la tour éventrée se relit comme une boîte fermée. La
    # séparation intérieur/extérieur est donc portée par le matériau, pas
    # espérée de l'ombrage.
    "MAT_Tower_StoneInner": (0.560, 0.510, 0.450, 0.95),
}
# ---------------------------------------------------------------------------
# COULEURS DE SOMMET — LOT 1.R, correction B-f-3 / B-f-4 / point 19 transverse
# ---------------------------------------------------------------------------
# CE QUE LA MESURE A DIT, ET POURQUOI CE FICHIER CHANGE. L'audit contradictoire
# a mesuré, au troisième passage, un profil de luminance en travers des pièces
# TOMBÉES de cette tour : « dalle claire au pied de la tour,
# `watchtower_gp_breche.png`, y = 520 : 141 constant, puis 78 constant —
# étendue 0 par plage ». Et le constat transverse (point 19) : sur des faces
# quasi verticales sous ce ciel, l'irradiance ambiante domine, donc la
# FACETTISATION ne rapporte presque rien ; la seule variation gratuite est
# `COLOR_0`.
#
# Ce GLB était le SEUL des trois de la voie B à ne PAS porter `COLOR_0` — le
# cimetière et le sanctuaire l'ont reçu, la tour non. Les pièces `tombee` sont
# en outre peintes côté Godot par un APLAT (`ALBEDO_TOMBEE`), sans carte : sans
# couleur de sommet, elles ne peuvent RIEN rendre d'autre qu'une valeur unique.
#
# DEUX CONDITIONS, AUCUNE AUTOMATIQUE (ISS-066, recette éprouvée de
# `make_barrow_stones.py`) :
#   1. le MATÉRIAU doit CONSOMMER l'attribut — un nœud Color Attribute
#      multiplié dans Base Color ; sans lui l'exporteur glTF n'écrit rien ;
#   2. la couche doit être l'attribut de couleur ACTIF **et** celui de RENDU.
# `tools/gltf_inspect.py` ne regarde JAMAIS `COLOR_0` : il répondrait `VALIDE`
# sur un asset qui les a perdues. La garde est donc ici, à la source.
#
# CE QUI DIFFÈRE DE LA RECETTE DU CIMETIÈRE, et c'est voulu : sur une pierre
# funéraire, les strates suivent le plus grand axe (le lit de débitage). Sur de
# la MAÇONNERIE, les lits sont HORIZONTAUX, et leur pas n'est pas libre — c'est
# `ASSISE`. La strate du fût est donc calée sur la hauteur d'assise, ce qui
# renforce l'appareil au lieu de le contredire.
NOM_COULEUR = "Col"
IDX_PIERRE = 0
IDX_BOIS = 1
IDX_PIERRE_INT = 2
ORDRE_MATERIAUX = ("MAT_Tower_Stone", "MAT_Tower_Wood",
                   "MAT_Tower_StoneInner")

# Échelles UV mesurées sur le kit (make_farm_ruins.py §R2B.2) : la pierre à
# 0,48 UV/m se répète sans couture, le bois est un trim sheet directionnel
# dont le V est replié dans une bande.
PROJECTION_UV = {
    IDX_PIERRE: (0.48, 0.48, None, None),
    IDX_BOIS: (0.65, 0.65, 0.02, 0.28),
    IDX_PIERRE_INT: (0.48, 0.48, None, None),
}


def srgb_vers_lineaire(canal):
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
    # Le matériau CONSOMME l'attribut de couleur — sans ce nœud, l'exporteur
    # glTF n'écrit pas `COLOR_0` et la pierre repart en aplat (ISS-066).
    arbre = mat.node_tree
    attribut = arbre.nodes.new("ShaderNodeVertexColor")
    attribut.layer_name = NOM_COULEUR
    melange = arbre.nodes.new("ShaderNodeMixRGB")
    melange.blend_type = "MULTIPLY"
    melange.inputs["Fac"].default_value = 1.0
    melange.inputs["Color1"].default_value = (r, v, b, 1.0)
    arbre.links.new(attribut.outputs["Color"], melange.inputs["Color2"])
    arbre.links.new(melange.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def poser_couleurs(maillage, periode, contraste, pied_facteur, veine,
                   axe_strate="z", creux=0.0):
    """Écrit `COLOR_0` : lits d'assise, veines fines, pied assombri.

    Les valeurs sont des MULTIPLICATEURS centrés sur 1,0 — la teinte, elle, se
    règle une seule fois côté Godot (`TEINTES_TEXTUREES` / `ALBEDO_TOMBEE`).
    Centrer sur 1,0 et non sur 0,87 est délibéré : le fût est TEXTURÉ, et une
    couleur de sommet centrée plus bas assombrirait une façade dont la valeur
    rendue (p50 ≈ 0,33) est déjà au bas de la bande §1.5.

    `axe_strate` vaut "z" pour la maçonnerie debout (les lits sont horizontaux,
    de pas `ASSISE`) et "auto" pour une pièce tombée, dont le lit suit son plus
    grand axe — une plaque au sol montre la tranche de son appareil.

    `creux` assombrit ce qui est PRÈS DE L'AXE du fût : c'est le parement
    intérieur et le fond de la brèche. B-f-1 reproche que « le pan sombre lit
    comme un second appareil collé au premier » ; une valeur qui décroît vers
    l'intérieur donne au mur sa profondeur au lieu de la laisser à l'ombrage.
    """
    sommets = maillage.vertices
    if not sommets:
        return 0
    etendues = []
    for axe in range(3):
        valeurs = [v.co[axe] for v in sommets]
        etendues.append((min(valeurs), max(valeurs)))
    if axe_strate == "z":
        axe = 2
    else:
        axe = max(range(3), key=lambda a: etendues[a][1] - etendues[a][0])
    axe_moyen = max((a for a in range(3) if a != axe),
                    key=lambda a: etendues[a][1] - etendues[a][0])
    portee2 = max(1e-6, etendues[axe_moyen][1] - etendues[axe_moyen][0])
    hauteur = max(1e-6, etendues[2][1])
    couche = maillage.color_attributes.new(name=NOM_COULEUR,
                                           type="FLOAT_COLOR", domain="POINT")
    for i, v in enumerate(sommets):
        # LIT D'ASSISE. Quantifié en marches puis MÉLANGÉ à l'onde continue
        # (65/35) : une quantification pure sort en blocs clairs et sombres —
        # de l'ombrage en escalier, pas un lit de pierre (leçon du cimetière).
        onde = 0.5 + 0.5 * math.sin(v.co[axe] / periode * 2.0 * math.pi
                                    + _graine(hauteur * 7.3) * 6.0)
        marche = 0.65 * (round(onde * 2.0) / 2.0) + 0.35 * onde
        valeur = 1.0 + contraste * (marche - 0.5)
        # SECONDE FRÉQUENCE, sur l'axe moyen. Sans elle, un profil pris EN
        # TRAVERS d'une face rend « étendue 2 » : les lits sont horizontaux,
        # une coupe horizontale n'en traverse qu'un. Mesuré au cimetière.
        t2 = (v.co[axe_moyen] - etendues[axe_moyen][0]) / portee2
        valeur *= 1.0 + 0.17 * math.sin(t2 * 1.7 * 2.0 * math.pi
                                        + _graine(hauteur * 3.9) * 6.0)
        # Veines : bruit fin, pour qu'aucune face ne soit un aplat parfait.
        valeur += _graine(v.co.x * 5.7 + v.co.y * 3.1 + v.co.z * 9.3) * veine
        # LE PIED EST PLUS SOMBRE — terre, ombre et humidité s'y accumulent, et
        # c'est ce qui ancre la pièce au sol au lieu de la poser dessus (B-f-3 :
        # « aucun enfoncement dans le sol »).
        assise = min(1.0, max(0.0, v.co.z / (pied_facteur * hauteur)))
        valeur *= 0.68 + 0.32 * assise
        if creux > 0.0:
            # Distance à l'axe du fût, normalisée par le demi-entraxe.
            r = max(abs(v.co.x), abs(v.co.y)) / (HALF + EP)
            valeur *= 1.0 - creux * (1.0 - min(1.0, r))
        valeur = min(1.34, max(0.48, valeur))
        couche.data[i].color = (valeur, valeur, valeur, 1.0)
    index = maillage.color_attributes.find(NOM_COULEUR)
    maillage.color_attributes.active_color_index = index
    maillage.color_attributes.render_color_index = index
    return len(sommets)


def _graine(x):
    """Bruit déterministe sans dépendance : sin d'entiers, dans [-0,5 ; 0,5]."""
    return math.sin(x * 12.9898) * 0.5


def deplier_boite(bm):
    """UV0 par projection boîte selon l'axe dominant de la normale (recette
    de make_farm_ruins.py — mètres -> tuiles à l'échelle du kit)."""
    couche = bm.loops.layers.uv.verify()
    for face in bm.faces:
        eu, ev, bande_min, bande_etendue = PROJECTION_UV.get(
            face.material_index, (0.48, 0.48, None, None))
        n = face.normal
        ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
        for boucle in face.loops:
            co = boucle.vert.co
            if az >= ax and az >= ay:
                u, v = co.x, co.y
            elif ax >= ay:
                u, v = co.y, co.z
            else:
                u, v = co.x, co.z
            u *= eu
            v *= ev
            if bande_min is not None:
                v = bande_min + (v % bande_etendue)
            boucle[couche].uv = (u, v)


# ---------------------------------------------------------------------------
# Briques bmesh
# ---------------------------------------------------------------------------
def prisme_frame(bm, origine, u, w, contour, materiau_idx,
                 materiau_avant=None):
    """Extrude un contour (s, z) le long de w : P = origine + u*s + w*t + z.

    `u` est l'axe de longueur du mur, `w` l'axe d'épaisseur (les deux
    horizontaux, unitaires). Chaque pièce de maçonnerie passe par ici : rien
    n'est jamais un plan — c'est la garantie structurelle héritée de la
    ferme (`prisme`). `materiau_avant` permet de donner à la GRANDE face
    `+w` (le parement intérieur des murs) un matériau propre.
    """
    avant = [bm.verts.new((origine[0] + u[0] * s + w[0] * 0.5,
                           origine[1] + u[1] * s + w[1] * 0.5,
                           origine[2] + z)) for s, z in contour]
    arriere = [bm.verts.new((origine[0] + u[0] * s - w[0] * 0.5,
                             origine[1] + u[1] * s - w[1] * 0.5,
                             origine[2] + z)) for s, z in contour]
    faces = [bm.faces.new(tuple(avant)),
             bm.faces.new(tuple(reversed(arriere)))]
    n = len(contour)
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((avant[i], avant[j], arriere[j],
                                   arriere[i])))
    for f in faces:
        f.material_index = materiau_idx
    if materiau_avant is not None:
        faces[0].material_index = materiau_avant
    return faces


def moellon(bm, centre, taille, graine, materiau_idx, jitter=0.30):
    """Une pierre : boîte aux huit sommets déplacés, jamais un cube net.

    `jitter` bas (≈ 0,08) donne une pierre TAILLÉE — c'est ce qu'il faut pour
    un linteau ou un jambage, qui doivent porter la trace de l'outil ; `jitter`
    haut (0,30, le défaut) donne une pierre de champ.
    ATTENTION, piège déjà payé une demi-heure : une pierre de centre `c` et de
    taille `d` s'étend de `c ± (0,5 + jitter/2)·d`. Placer le CENTRE hors d'un
    volume interdit NE SUFFIT PAS."""
    cx, cy, cz = centre
    dx, dy, dz = taille
    sommets = []
    for i, (sx, sy, sz) in enumerate(((-1, -1, -1), (1, -1, -1), (1, 1, -1),
                                      (-1, 1, -1), (-1, -1, 1), (1, -1, 1),
                                      (1, 1, 1), (-1, 1, 1))):
        j = _graine(graine * 3.7 + i * 1.9)
        sommets.append(bm.verts.new((
            cx + sx * dx * 0.5 * (1.0 + j * jitter),
            cy + sy * dy * 0.5 * (1.0 + _graine(graine + i * 2.3) * jitter),
            cz + sz * dz * 0.5 * (1.0 + _graine(graine * 1.3 + i)
                                  * jitter * 0.73))))
    bas, haut = sommets[:4], sommets[4:]
    faces = [bm.faces.new(tuple(reversed(bas))), bm.faces.new(tuple(haut))]
    for i in range(4):
        k = (i + 1) % 4
        faces.append(bm.faces.new((bas[i], bas[k], haut[k], haut[i])))
    for f in faces:
        f.material_index = materiau_idx
    return faces


def _rotation_xyz(p, angles):
    ax, ay, az = angles
    x, y, z = p
    c, s = math.cos(ax), math.sin(ax)
    y, z = y * c - z * s, y * s + z * c
    c, s = math.cos(ay), math.sin(ay)
    x, z = x * c + z * s, -x * s + z * c
    c, s = math.cos(az), math.sin(az)
    x, y = x * c - y * s, x * s + y * c
    return (x, y, z)


def eclat(bm, centre, taille, graine, materiau_idx, cotes=5,
          rotation=(0.0, 0.0, 0.0), pose=0.0):
    """Fragment anguleux irrégulier (2k+1 sommets : jamais un pavé). Recette
    ISS-060 de make_farm_ruins.py, reprise à l'identique : c'est la seule
    forme de gravat que le portail de boîtitude accepte par construction."""
    k = max(3, min(7, int(cotes)))
    dx, dy, dz = taille
    locaux = []
    for i in range(k):
        a = 2.0 * math.pi * i / k + _graine(graine * 5.1 + i * 3.3) * (1.0 / k)
        r = 0.5 * (1.0 + _graine(graine * 2.7 + i * 1.7) * 0.55)
        locaux.append((
            math.cos(a) * r * dx, math.sin(a) * r * dy,
            -0.50 * dz + _graine(graine * 4.3 + i * 2.9) * 0.08 * dz))
    for i in range(k):
        a = 2.0 * math.pi * (i + 0.5) / k \
            + _graine(graine * 3.9 + i * 2.1) * (1.0 / k)
        r = 0.5 * (0.86 + _graine(graine * 1.9 + i * 4.1) * 0.55)
        locaux.append((
            math.cos(a) * r * dx, math.sin(a) * r * dy,
            0.06 * dz + _graine(graine * 6.1 + i * 1.3) * 0.14 * dz))
    ap = 2.0 * math.pi * _graine(graine * 7.7) + graine
    ar = 0.22 * (1.0 + _graine(graine * 8.3))
    locaux.append((math.cos(ap) * ar * dx, math.sin(ap) * ar * dy, 0.50 * dz))

    tournes = [_rotation_xyz(p, rotation) for p in locaux]
    bas = min(p[2] for p in tournes)
    sommets = [bm.verts.new((centre[0] + p[0], centre[1] + p[1],
                             centre[2] + p[2] - bas + pose)) for p in tournes]
    faces = [bm.faces.new(tuple(sommets[:k]))]
    for i in range(k):
        j = (i + 1) % k
        faces.append(bm.faces.new((sommets[i], sommets[j],
                                   sommets[k + j], sommets[k + i])))
    for i in range(k):
        j = (i + 1) % k
        faces.append(bm.faces.new((sommets[k + i], sommets[k + j],
                                   sommets[2 * k])))
    for f in faces:
        f.material_index = materiau_idx
    return faces


def poutre(bm, depart, arrivee, largeur, hauteur, materiau_idx, jitter=0.006):
    """Une poutre de `depart` à `arrivee` — pour les bouts de solives."""
    dx = [arrivee[i] - depart[i] for i in range(3)]
    longueur = math.sqrt(sum(c * c for c in dx))
    axe = [c / longueur for c in dx]
    if abs(axe[2]) < 0.99:
        cote = [-axe[1], axe[0], 0.0]
        norme = math.sqrt(sum(c * c for c in cote)) or 1.0
        cote = [c / norme for c in cote]
    else:
        cote = [1.0, 0.0, 0.0]
    haut = [axe[1] * cote[2] - axe[2] * cote[1],
            axe[2] * cote[0] - axe[0] * cote[2],
            axe[0] * cote[1] - axe[1] * cote[0]]
    sommets = []
    for extremite, point in ((0.0, depart), (1.0, arrivee)):
        for sc, sh in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            j = _graine(extremite * 7.1 + sc * 2.3 + sh * 4.7) * jitter
            sommets.append(bm.verts.new((
                point[0] + cote[0] * (largeur * 0.5 * sc + j)
                + haut[0] * hauteur * 0.5 * sh,
                point[1] + cote[1] * (largeur * 0.5 * sc + j)
                + haut[1] * hauteur * 0.5 * sh,
                point[2] + cote[2] * (largeur * 0.5 * sc + j)
                + haut[2] * hauteur * 0.5 * sh)))
    a, b = sommets[:4], sommets[4:]
    faces = [bm.faces.new((a[0], a[1], a[2], a[3])),
             bm.faces.new((b[3], b[2], b[1], b[0]))]
    for i in range(4):
        j = (i + 1) % 4
        faces.append(bm.faces.new((a[i], b[i], b[j], a[j])))
    for f in faces:
        f.material_index = materiau_idx


# ---------------------------------------------------------------------------
# Le profil d'arrachement — gradins d'assise, hauteurs sur la grille des lits
# ---------------------------------------------------------------------------
def profil_dechire(longueur, h0, h1, graine, plateau=0.2, dent_pos=0.45):
    """Liste de points (s, z) du profil supérieur : marches d'une à deux
    assises, hauteurs QUANTIFIÉES sur la grille des lits de pose, bruit de
    hauteur pour que les sommets de gradins ne tombent pas sur la diagonale
    (leçon `_gradins` de la ferme : un bruit de longueur seule rend un trait
    tiré à la règle vu de loin), et une assise SURVIVANTE — la dent qui fait
    lire « effondrement » au lieu de « coupe en biseau ».
    """
    points = [(0.0, h0)]
    s = 0.0
    h = h0
    dent_faite = False
    i = 0
    while s < longueur - 0.32:
        i += 1
        ds = 0.38 + 0.42 * abs(_graine(graine * 3.1 + i * 1.7))
        s2 = min(longueur, s + ds)
        if s2 <= plateau * longueur:
            h2 = h0
        else:
            t = (s2 - plateau * longueur) / max(1e-6,
                                                longueur * (1.0 - plateau))
            tendance = h0 + (h1 - h0) * t
            bruit = _graine(graine * 5.3 + i * 2.9) * 2.6 * ASSISE
            h2 = round((tendance + bruit) / ASSISE) * ASSISE
            h2 = max(min(h2, max(h0, h1) + ASSISE), min(h0, h1) - ASSISE,
                     3.0 * ASSISE)
            if (not dent_faite) and s2 >= dent_pos * longueur:
                h2 += 2.0 * ASSISE
                dent_faite = True
        if abs(h2 - h) > 1e-6:
            points.append((s2, h))
            points.append((s2, h2))
            h = h2
        s = s2
    points.append((longueur, h))
    return points


def hauteur_de_profil(profil, s):
    """Hauteur du profil déchiré à l'abscisse `s` (escalier : dernier point
    à gauche). Écrite UNE fois et réutilisée — la même lecture redérivée dans
    trois branches est la façon exacte dont on se trompe (tools/CLAUDE.md,
    la parité des rayons)."""
    z = profil[0][1]
    for ps, pz in profil:
        if ps <= s + 1e-9:
            z = pz
        else:
            break
    return z


def clip_profil(profil, a, b):
    """Le profil restreint à [a, b], bornes comprises et interpolées."""
    pts = [(a, hauteur_de_profil(profil, a))]
    for ps, pz in profil:
        if a + 1e-6 < ps < b - 1e-6:
            pts.append((ps, pz))
    pts.append((b, hauteur_de_profil(profil, b)))
    return pts


def nettoyer(contour):
    """Retire les points consécutifs confondus : `bm.faces.new` lève sur un
    sommet répété, et une face d'aire nulle est un triangle dégénéré que
    `gltf_inspect` ne verra jamais (leçon de la T-jonction, tools/CLAUDE.md)."""
    sortie = []
    for p in contour:
        if not sortie or abs(p[0] - sortie[-1][0]) > 1e-6 \
                or abs(p[1] - sortie[-1][1]) > 1e-6:
            sortie.append(p)
    if len(sortie) > 1 and abs(sortie[0][0] - sortie[-1][0]) < 1e-6 \
            and abs(sortie[0][1] - sortie[-1][1]) < 1e-6:
        sortie.pop()
    return sortie


def compter_gradins(points):
    n = 0
    for i in range(1, len(points)):
        if abs(points[i][1] - points[i - 1][1]) >= 0.6 * ASSISE:
            n += 1
    return n


# ---------------------------------------------------------------------------
# SM_Watchtower_Shell — le fût : quatre murs, brèche, escalier, corbeaux
# ---------------------------------------------------------------------------
GRADINS_TOTAL = 0
## Aire au sol de la dalle de la vigie, en m², mesurée sur son contour réel.
## C'est la grandeur qui décide si on peut se tenir là-haut, et elle ne dépend
## d'aucune hypothèse sur la position du bord déchiré — voir garde 3.
VIGIE_AIRE = 0.0


def aire_contour(points):
    """Aire d'un polygone fermé donné par ses sommets (lacet de Gauss)."""
    total = 0.0
    n = len(points)
    for i in range(n):
        x0, y0 = points[i]
        x1, y1 = points[(i + 1) % n]
        total += x0 * y1 - x1 * y0
    return abs(total) * 0.5


BAIES_TOTAL = 0


def mur(bm, origine, direction, longueur, h0, h1, graine, plateau, dent,
        interieur_flip=False, baies=(), socle=True):
    """Un mur déchiré, avec ses OUVERTURES.

    `interieur_flip` retourne l'axe d'épaisseur pour que la face `+w` — celle
    qui reçoit `MAT_Tower_StoneInner` — soit toujours le parement INTÉRIEUR.

    `baies` — LOT 1.R.1, et c'est la correction centrale du reproche « sa
    plaque intérieure demeure uniforme ». Le mot n'est pas une mesure de
    luminance : le profil en travers de cette plaque donne étendue 79, 65
    valeurs, 47 renversements (`tools/mesure_valeur.py` sur la base). Ce qui
    manque n'est pas de la matière, c'est un ÉVÉNEMENT CONSTRUIT — un trou.
    Chaque entrée est `(s0, s1, z_bas, z_haut)` en coordonnées du mur ; le mur
    est alors découpé en bandes verticales pleines, en allèges et en linteaux.
    Aucune opération booléenne : le contour est simplement scindé, ce qui
    garantit une topologie propre et un budget prévisible.

    `socle` ajoute l'EMPATTEMENT : deux ressauts au pied, plus larges que le
    mur. Un pied plus large est ce qui fait qu'une tour cesse de se lire comme
    une planche posée de chant — et il se voit aussi à 86 m.
    """
    global GRADINS_TOTAL, BAIES_TOTAL
    profil = profil_dechire(longueur, h0, h1, graine, plateau, dent)
    GRADINS_TOTAL += compter_gradins(profil)
    w = (direction[1] * EP, -direction[0] * EP)
    if interieur_flip:
        w = (-w[0], -w[1])
    base = (origine[0], origine[1], 0.0)
    u = (direction[0], direction[1])

    def poser(contour):
        contour = nettoyer(contour)
        if len(contour) < 3:
            return
        prisme_frame(bm, base, u, w, contour, IDX_PIERRE,
                     materiau_avant=IDX_PIERRE_INT)

    bornes = sorted(baies, key=lambda b: b[0])
    s = 0.0
    for s0, s1, z0, z1 in bornes:
        s0 = max(s, min(s0, longueur))
        s1 = max(s0, min(s1, longueur))
        haut_min = min(hauteur_de_profil(profil, s0),
                       hauteur_de_profil(profil, s1))
        if z1 >= haut_min - 0.10:
            # Pas de linteau possible : l'ouverture mangerait l'arase. On la
            # refuse au lieu de produire une créneau involontaire — et le
            # compteur de baies ne la comptera pas, donc la garde le dira.
            continue
        poser([(s, 0.0)] + clip_profil(profil, s, s0) + [(s0, 0.0)])
        if z0 > 0.02:
            poser([(s0, 0.0), (s0, z0), (s1, z0), (s1, 0.0)])
        poser([(s0, z1)] + clip_profil(profil, s0, s1) + [(s1, z1)])
        BAIES_TOTAL += 1
        s = s1
    poser([(s, 0.0)] + clip_profil(profil, s, longueur) + [(longueur, 0.0)])

    if socle:
        # L'EMPATTEMENT S'INTERROMPT AUX BAIES QUI DESCENDENT AU SOL.
        #
        # Bug attrapé AVANT la première capture, et il aurait été invisible sur
        # l'image tout en étant fatal : la porte du mur est part de z = 0, et un
        # socle plein sur toute la longueur l'aurait murée sur 1,06 m — une
        # porte bouchée par un bandeau de pierre, avec un collider ouvert
        # derrière. Le socle est donc scindé par les mêmes bornes que le mur,
        # et ne saute QUE les baies dont le seuil descend dans son épaisseur.
        coupures = [(b[0], b[1]) for b in bornes if b[2] < 1.10]
        for hauteur, debord in ((0.74, EMPATTEMENT),
                                (1.06, EMPATTEMENT * 0.48)):
            we = (w[0] * (1.0 + 2.0 * debord / EP),
                  w[1] * (1.0 + 2.0 * debord / EP))
            travees = []
            depart = 0.0
            for c0, c1 in coupures:
                travees.append((depart, max(depart, c0)))
                depart = max(depart, c1)
            travees.append((depart, longueur))
            for t0, t1 in travees:
                if t1 - t0 < 0.20:
                    continue
                crete = [(t0, 0.0)]
                n = max(2, int(round((t1 - t0) / 0.90)) + 1)
                for i in range(n + 1):
                    si = t0 + (t1 - t0) * i / n
                    crete.append((si, hauteur
                                  + _graine(graine * 1.7 + i * 2.3
                                            + hauteur) * 0.11))
                crete.append((t1, 0.0))
                prisme_frame(bm, base, u, we, nettoyer(crete), IDX_PIERRE,
                             materiau_avant=IDX_PIERRE_INT)
    return profil


def bandeau(bm, depart, u, longueur, z0, z1, saillie, normale, graine,
            segments=4):
    """LE RETRAIT DE MAÇONNERIE — un ressaut continu sur le nu INTÉRIEUR, à la
    ligne d'un ancien plancher.

    C'est ainsi qu'une tour est bâtie : le mur s'amincit à chaque étage et
    laisse une banquette qui porte les solives. Visuellement, c'est une LIGNE
    HORIZONTALE qui coupe le grand parement en registres — l'événement que
    l'audit ne trouvait nulle part. Elle est posée en segments inégaux, avec
    des manques : le ressaut aussi s'est effondré par endroits.
    """
    pose = 0.0
    for i in range(segments):
        part = longueur / segments
        vide = part * (0.10 + 0.22 * abs(_graine(graine * 2.9 + i * 1.7)))
        s0 = pose + vide * 0.5
        s1 = pose + part - vide * 0.5
        pose += part
        if s1 - s0 < 0.18:
            continue
        e = saillie * (0.80 + 0.40 * abs(_graine(graine * 3.7 + i)))
        # `prisme_frame` centre l'épaisseur sur la ligne donnée : on décale
        # donc l'origine d'une demi-saillie pour que le ressaut parte du NU et
        # aille vers l'intérieur, et non à cheval sur le parement.
        base = (depart[0] + normale[0] * e * 0.5,
                depart[1] + normale[1] * e * 0.5, 0.0)
        contour = [(s0, z0), (s0, z1), (s1, z1), (s1, z0)]
        prisme_frame(bm, base, u, (normale[0] * e, normale[1] * e),
                     contour, IDX_PIERRE)


def coquille(bm):
    """Le fût. Quatre murs, quatre arases, une brèche — et l'histoire des
    deux étages disparus, lisible par la brèche."""
    global GRADINS_TOTAL, VIGIE_AIRE, BAIES_TOTAL
    GRADINS_TOTAL = 0
    BAIES_TOTAL = 0
    L_OUEST = 2.0 * HALF + EP
    L_NORD = BRECHE_X_NORD + HALF + EP * 0.5
    L_SUD = 2.0 * HALF + EP
    L_EST = BRECHE_Y_EST + HALF + EP * 0.5
    # OUEST — le plus haut, face au couchant. Il court sur TOUTE la largeur.
    # DEUX OUVERTURES, et leur place est calculée sur le cadre joueur, pas
    # choisie à l'œil : la baie du premier étage tombe à x ≈ 602 px, en plein
    # milieu de la masse sombre que Codex dit « uniforme » ; l'archère du
    # second monte à x ≈ 531 px, au bord haut du cadre, et sert surtout la
    # silhouette et la vue lointaine.
    mur(bm, (-HALF, -HALF - EP * 0.5), (0.0, 1.0), L_OUEST,
        H_OUEST, H_OUEST_FIN, 11.0, 0.30, 0.52,
        baies=((1.45, 1.70, 6.90, 8.05), (2.35, 3.15, 4.10, 5.35)))
    # LA POINTE D'ARASE SURVIVANTE — l'angle sud-ouest a tenu plus haut que
    # le blocage (LOT 1.R.4). Deux raisons, une constructive et une mesurée :
    #   * constructive : un chaînage d'angle en pierres appareillées résiste
    #     mieux que le blocage courant — c'est PRÉCISÉMENT là qu'une ruine
    #     garde sa pointe, et la couronne y regagne la « verticalité
    #     irrégulière » du contrat (« couronne incomplète », §1) ;
    #   * mesurée : au premier assemblage complet des masques finaux, la
    #     paire watchtower_ruin × waterfall_cave rend IoU 0,4975 à 30 m
    #     (seuil gelé 0,4931) et 0,4930 à 80 m (S 0,4912), sur le couple
    #     0°×0°. La R3 avait aplani le bord supérieur du masque — le fût se
    #     lisait « monticule ». À 30 m il faut +47 px de tour HORS de
    #     l'emprise de la grotte (toile 96×96) ; la zone au-dessus de la
    #     ligne ~24/96 est vide des DEUX côtés, donc chaque pixel de pointe
    #     est un pixel d'union pure. Ce contour rend 2,43 m² au-dessus de
    #     l'arase (~59 px à 30 m, ~besoin 47 ; 80 m : besoin 39).
    # Cotes QUANTIFIÉES sur ASSISE depuis H_OUEST (8,95) : pointe +7 assises
    # (10,91), paliers +6 (10,63), +5 (10,35), +2 (9,51). La base (8,39,
    # 2 assises SOUS l'arase) pénètre le plateau du profil ouest — aucun
    # joint flottant possible : le plateau tient h0 jusqu'à s = 1,575 et le
    # merlon s'arrête à 1,57. Même repère (base/u/w) que le mur ouest, même
    # parement intérieur. Aucune pièce nouvelle : le merlon vit DANS
    # SM_Watchtower_Shell, le compte D7 du lieu ne bouge pas ; il culmine à
    # 10,91 m, hors de portée du joueur (vigie 3,05), aucun collider.
    prisme_frame(bm, (-HALF, -HALF - EP * 0.5, 0.0), (0.0, 1.0), (EP, 0.0),
                 ((0.0, 8.39), (0.0, 10.91), (0.60, 10.91), (0.60, 10.63),
                  (1.02, 10.63), (1.02, 10.35), (1.30, 10.35), (1.30, 9.51),
                  (1.57, 9.51), (1.57, 8.39)),
                 IDX_PIERRE, materiau_avant=IDX_PIERRE_INT)
    # NORD — s'arrête à la brèche, arase qui plonge vers l'arrachement.
    # Une archère, vue de biais par la brèche.
    mur(bm, (-HALF - EP * 0.5, HALF), (1.0, 0.0), L_NORD,
        H_NORD, H_NORD_FIN, 23.0, 0.16, 0.60,
        baies=((1.15, 1.40, 2.30, 3.50),))
    # SUD — entier mais bien plus bas que l'ouest. Son archère est pour la
    # vue d'identité et les silhouettes : c'est la face qu'elles montrent.
    mur(bm, (-HALF - EP * 0.5, -HALF), (1.0, 0.0), L_SUD,
        H_SUD, H_SUD_FIN, 37.0, 0.22, 0.72, interieur_flip=True,
        baies=((2.20, 2.45, 2.00, 3.20),))
    # EST — la seule travée debout, au sud de la brèche. ELLE PORTE LA PORTE.
    #
    # C'est la correction de « l'entrée n'est pas lisible ». La brèche d'angle
    # nord-est reste l'effondrement, et on peut toujours y passer ; mais un
    # angle arraché ne se lit pas comme un seuil — il n'a ni jambage, ni
    # linteau, ni rien qui dise « on entrait ICI ». La porte, elle, tombe à
    # x ≈ 399 px, au milieu du seul pan ÉCLAIRÉ du cadre joueur : un
    # rectangle sombre dans un mur clair, à 5,3 m de l'œil.
    # LA PORTE RECULE DE 0,60 m, ET C'EST UN BUG MESURÉ SUR LA CAPTURE, PAS UN
    # RÉGLAGE. À `s ∈ [0,45 ; 1,05]` l'ouverture tombait en y −2,175..−1,575 ;
    # or le MUR SUD occupe y −2,625..−1,775 sur TOUTE la largeur du fût, angle
    # compris. Les deux tiers bas de la porte débouchaient donc dans la masse
    # de l'angle sud-est : le trou existait dans le mur est, et il ne se voyait
    # pas. Mesuré sur `it/r1/watchtower_ruin_joueur.png`, zone 355-410 × 400-540
    # contre 430-490 × 400-540 : p50 56,3 contre 56,8 — aucun contraste, donc
    # aucun trou. Un maillage juste et une image sans porte.
    # `s ∈ [1,05 ; 1,65]` met la baie en y −1,575..−0,975 : 0,20 m de
    # dégagement du nu intérieur du mur sud, et on voit à travers.
    mur(bm, (HALF, -HALF - EP * 0.5), (0.0, 1.0), L_EST,
        H_EST, H_EST_FIN, 47.0, 0.34, 0.62, interieur_flip=True,
        baies=((1.00, 1.90, 0.0, 1.85),))

    # LES RETRAITS DE MAÇONNERIE — deux lignes de plancher rendues visibles.
    # Niveau 1 à 3,05 m (celui de la vigie) : le ressaut court sous la dalle
    # sur les trois murs qui le portaient encore. Niveau 2 à 5,95 m : il ne
    # reste que l'ouest, et un bout de nord — le ressaut S'ARRÊTE là où le mur
    # est parti, et c'est le récit qu'on veut.
    bandeau(bm, (-NU, -NU), (0.0, 1.0), 2.0 * NU, 2.59, 2.83, 0.20,
            (1.0, 0.0), 5.0, segments=4)
    bandeau(bm, (-NU, NU), (1.0, 0.0), NU + BRECHE_X_NORD, 2.59, 2.83, 0.20,
            (0.0, -1.0), 9.0, segments=3)
    bandeau(bm, (-NU, -NU), (1.0, 0.0), 2.0 * NU, 2.59, 2.83, 0.18,
            (0.0, 1.0), 13.0, segments=4)
    bandeau(bm, (-NU, -NU), (0.0, 1.0), 2.0 * NU, 5.49, 5.73, 0.20,
            (1.0, 0.0), 17.0, segments=3)
    bandeau(bm, (-NU, NU), (1.0, 0.0), 0.92, 5.49, 5.73, 0.20,
            (0.0, -1.0), 21.0, segments=1)

    # CHAÎNAGES D'ANGLE : quelques carreaux qui débordent du nu du mur, aux
    # trois angles encore debout. Le nord-est n'en a pas — il est tombé.
    for cx, cy, g in ((-HALF, -HALF, 3.0), (-HALF, HALF, 7.0),
                      (HALF, -HALF, 13.0)):
        # L'angle SUD-OUEST s'arrête SOUS la vigie (2,6 m) : mesuré par la
        # garde 3b, un carreau à jitter débordait dans le volume de la
        # capsule au-dessus de la dalle praticable.
        h_max = {(-HALF, -HALF): 2.6, (-HALF, HALF): 6.2,
                 (HALF, -HALF): 2.8}[(cx, cy)]
        z = 0.35
        i = 0
        while z < h_max:
            i += 1
            moellon(bm, (cx + _graine(g + i) * 0.10,
                         cy + _graine(g * 2 + i) * 0.10, z),
                    (0.62, 0.62, 0.34), g * 5.0 + i * 1.3, IDX_PIERRE)
            z += 0.62 + 0.25 * abs(_graine(g * 3.0 + i))

    # LES JAMBAGES DE LA BRÈCHE : l'épaisseur du mur rendue visible par des
    # pierres d'arrachement qui débordent des deux chants ouverts.
    for i in range(4):
        z = 0.25 + i * 0.42
        moellon(bm, (BRECHE_X_NORD + 0.02 + _graine(51.0 + i) * 0.06,
                     HALF + 0.05 + _graine(53.0 + i) * 0.10, z),
                (0.44, 0.42, 0.30), 61.0 + i * 2.1, IDX_PIERRE)
    for i in range(3):
        z = 0.22 + i * 0.40
        moellon(bm, (HALF + _graine(57.0 + i) * 0.12,
                     BRECHE_Y_EST + 0.08 + _graine(59.0 + i) * 0.08, z),
                (0.55, 0.50, 0.28), 67.0 + i * 1.7, IDX_PIERRE)

    # L'ASCENSION — deux volées INTÉGRÉES à la maçonnerie. La première monte
    # le long du mur nord depuis l'entrée, sur un massif plein ; la seconde
    # tourne d'un quart le long du mur ouest et meurt à la ligne du premier
    # plancher. C'est ainsi qu'on montait ; c'est ce que la ruine raconte.
    # Volée 1 : massif plein sous les marches (un mur bas en gradins
    # RÉGULIERS d'escalier, ce sont des marches, pas un arrachement).
    # LOT 1.R.1 — L'ESCALIER AVANCE JUSQU'AU SEUIL ET REÇOIT SON RAMPANT.
    #
    # « L'ascension compréhensible depuis la vue joueur » : elle ne l'était
    # pas, et la cause est géométrique. Toute la tour est faite de lignes
    # horizontales et verticales ; il n'y a AUCUNE diagonale dans le cadre, et
    # la diagonale est le seul signe qui dise « on monte » à trois secondes.
    # Deux gestes : la volée passe de 6 à 7 marches et son pied avance de
    # 0,85 à 1,28 m (juste sous la borne x = 1,30 de la garde 2, qui protège
    # le passage de la brèche — la marge est calculée, pas espérée), et elle
    # reçoit un MUR D'ÉCHIFFRE dont l'arête supérieure est un rampant continu.
    marches_1 = 7
    tread = 0.30
    rise = 0.27
    x_dep = 1.28
    largeur_marche = 0.78
    contour = [(0.0, 0.0)]
    for m in range(marches_1):
        contour.append((m * tread, (m + 1) * rise))
        contour.append(((m + 1) * tread, (m + 1) * rise))
    contour.append((marches_1 * tread, 0.0))
    # le long du mur nord, on monte vers l'ouest : u = (-1, 0)
    y_axe = NU - largeur_marche * 0.5
    prisme_frame(bm, (x_dep, y_axe, 0.0),
                 (-1.0, 0.0), (0.0, largeur_marche), contour, IDX_PIERRE)
    # LE MUR D'ÉCHIFFRE, au SUD de la volée et hors de la bande marchable :
    # le corps `Guet_rampe_1` occupe y 0,985..1,785 ; le rampant vit en
    # 0,715..0,985, il ne rétrécit donc pas le passage d'un centimètre.
    course = marches_1 * tread
    rampant = [(0.0, 0.0), (0.0, 0.34)]
    for i in range(5):
        si = course * i / 4.0
        rampant.append((si, 0.34 + si * (rise / tread)
                        + _graine(151.0 + i * 3.1) * 0.09))
    rampant.append((course, 0.0))
    prisme_frame(bm, (x_dep, y_axe - largeur_marche * 0.5 - 0.135, 0.0),
                 (-1.0, 0.0), (0.0, 0.27), nettoyer(rampant), IDX_PIERRE)
    # ... et une assise de moellons SUR ce rampant. Leur face supérieure est
    # horizontale, donc elle reçoit la lumière du ciel là où tout le reste du
    # parement est vertical et sombre : c'est ce qui fait que la diagonale se
    # VOIT, et non seulement qu'elle existe. Le premier moellon est centré à
    # x = 1,10 — son sommet le plus à l'est atteint 1,10 + 0,575·0,30 = 1,27,
    # sous la borne 1,30 de la garde 2.
    for i in range(6):
        xm = 1.10 - i * 0.34
        moellon(bm, (xm, y_axe - largeur_marche * 0.5 - 0.135,
                     0.46 + (x_dep - xm) * (rise / tread)),
                (0.30, 0.24, 0.20), 161.0 + i * 2.7, IDX_PIERRE)
    # Volée 2 : le long du mur ouest, du palier tournant (z=1,62) à la
    # VIGIE (z=3,05 — arbitrage « La vigie retrouvée »). Marches en
    # encorbellement scellées dans le parement, contremarches 0,28 m
    # (step_height du contrôleur : 0,30–0,38) et girons 0,33 m — la montée
    # est jouable aux vrais contrôles, pas seulement dessinée.
    z0 = marches_1 * rise
    marches_2 = 4
    for m in range(marches_2):
        y = 1.20 - m * 0.33
        moellon(bm, (-NU + 0.40, y, z0 + (m + 1) * 0.28 - 0.07),
                (0.95, 0.58, 0.20), 71.0 + m * 1.9, IDX_PIERRE)
    # Le palier d'angle entre les deux volées.
    moellon(bm, (-NU + 0.55, NU - 0.325, z0 - 0.08),
            (0.95, 0.75, 0.18), 83.0, IDX_PIERRE)
    # LA VIGIE — la moitié SUD-OUEST du premier plancher a TENU : une dalle
    # de pierre appuyée sur les murs ouest et sud, bord d'arrachement
    # dentelé vers le nord-est (le reste est tombé — c'est le talus).
    # Épaisseur 0,22 m, dessus à 3,05 m : la ligne des corbeaux. Le joueur
    # y monte, et le paysage entre par la brèche au-dessus de la travée
    # est (arase 3,05 → 1,35) : la récompense-paysage AVANT les flèches.
    #
    # LOT 1.R — LA VIGIE S'AGRANDIT, ET C'EST UNE CONTRAINTE, PAS UN CAPRICE.
    # L'audit demande que la récompense vienne APRÈS l'ascension : le coffre
    # monte donc sur ce palier. Or l'ancienne dalle mesurait 1,42 × 1,15 m,
    # dont 1,15 × 0,95 m réservés à la capsule du joueur par la garde 3 : il
    # n'y avait littéralement pas la place d'y poser autre chose. Elle passe à
    # 1,90 × 1,38-1,72 m, soit ~2,9 m² au lieu de ~1,6 m².
    #
    # LA GARDE 3 NE BOUGE PAS D'UN MILLIMÈTRE (x −1,70..−0,55, y −1,70..−0,75).
    # C'est délibéré : élargir le palier ET déplacer le contrôle qui prouve
    # qu'on peut s'y tenir serait exactement la façon dont un portail
    # s'affaiblit sans que personne ne mente (`tools/CLAUDE.md`). Tout le
    # mobilier ajouté ci-dessous est donc posé HORS de cette boîte, et la
    # boîte reste entièrement sur la dalle.
    #
    # Le bord déchiré est borné en profondeur (1,38 min) pour que le parapet
    # puisse s'appuyer dessus au lieu de flotter au-dessus du vide.
    # 2,325 m (et non 1,90) : le lot 1.R ouvre une BAIE EST sur la dalle.
    # Raison mesurée, pas d'aisance : à 1,90 m, le coffre posé sur la dalle
    # se trouvait à 1,3 m de l'œil dans `it/t1/watchtower_gp_vigie_pov.png`
    # et occupait le quart du cadre de la vue-récompense — il masquait
    # précisément le paysage qu'il est censé récompenser. La baie le recule
    # à 1,7 m (surface apparente ×0,58) et lui donne, avec la pierre de
    # vigie, une place qui n'empiète pas sur le volume de la capsule.
    VIGIE_LONG = 2.325
    vigie_bas = 3.05 - 0.22
    profil_bord = profil_dechire(VIGIE_LONG, 1.62, 1.44, 77.0, plateau=0.12,
                                 dent_pos=0.50)
    contour_vigie = [(0.0, 0.0)] \
        + [(s, min(1.72, max(1.38, z))) for s, z in profil_bord] \
        + [(VIGIE_LONG, 0.0)]
    VIGIE_AIRE = aire_contour(contour_vigie)
    # Contour en plan (s = x depuis le mur ouest, z du profil = étendue y
    # depuis le mur sud), extrudé verticalement de vigie_bas à 3,05.
    avant_v = [bm.verts.new((-HALF + EP * 0.5 + s, -HALF + EP * 0.5 + e,
                             3.05)) for s, e in contour_vigie]
    arriere_v = [bm.verts.new((-HALF + EP * 0.5 + s, -HALF + EP * 0.5 + e,
                               vigie_bas)) for s, e in contour_vigie]
    faces_v = [bm.faces.new(tuple(reversed(avant_v))),
               bm.faces.new(tuple(arriere_v))]
    for i in range(len(contour_vigie)):
        j = (i + 1) % len(contour_vigie)
        faces_v.append(bm.faces.new((avant_v[i], avant_v[j], arriere_v[j],
                                     arriere_v[i])))
    for f in faces_v:
        f.material_index = IDX_PIERRE
    # Deux corbeaux SOUS le bord libre de la vigie : ce qui la porte encore.
    # Recalés sur le NOUVEAU bord (l'ancien passait à y = −1,225 / −0,625, donc
    # désormais en plein sous la dalle, où un corbeau ne se voit pas).
    moellon(bm, (-HALF + EP * 0.5 + 1.55, -HALF + 1.32, vigie_bas - 0.10),
            (0.30, 0.26, 0.24), 111.0, IDX_PIERRE)
    moellon(bm, (-HALF + EP * 0.5 + 0.72, -HALF + 1.48, vigie_bas - 0.10),
            (0.26, 0.30, 0.24), 113.0, IDX_PIERRE)

    # LE PARAPET ROMPU — la mise en scène du palier (lot 1.R).
    #
    # Ce que l'audit reproche à ce lieu n'est plus sa silhouette : c'est que
    # rien ne dise qu'on a VEILLÉ ici. Cinq moellons sur le bord déchiré, de
    # hauteurs franchement inégales, avec DEUX ouvertures : à l'ouest (x <
    # −1,10) c'est l'arrivée de l'escalier, et on ne bâtit pas un parapet en
    # travers d'une marche ; au milieu (x −0,62..−0,26) c'est la brèche du
    # parapet lui-même — la pierre est partie avec le reste, et c'est par là
    # que le regard sort vers la vallée.
    #
    # POSITIONNEMENT HORS DE LA BOÎTE DE LA GARDE 3, ET LA MARGE SE CALCULE.
    # `moellon` déplace chacun de ses huit sommets de ±0,30 en x/y : une pierre
    # de centre `c` et de taille `d` s'étend donc de `c ± 0,575·d`. Il ne suffit
    # pas que le CENTRE soit hors de la boîte — c'est l'erreur qui a fait
    # refuser la première tentative, pour UN sommet.
    # Le parapet est entièrement au NORD de la boîte : y_min = −0,50 −
    # 0,575·0,30 = −0,672 > −0,75. Et il reste au sud du bord déchiré le plus
    # court (−1,775 + 1,38 = −0,395), donc réellement POSÉ sur la dalle.
    for x_par, h_par, g_par in ((-1.06, 0.86, 121.0), (-0.84, 0.62, 123.0),
                                (-0.62, 0.74, 127.0), (-0.26, 0.44, 131.0),
                                (-0.04, 0.66, 133.0)):
        moellon(bm, (x_par, -0.50, 3.05 + h_par * 0.5),
                (0.24, 0.30, h_par), g_par, IDX_PIERRE)

    # LA PIERRE DE VIGIE — un bloc bas adossé au mur sud, à l'est de la dalle.
    # C'est le siège du guetteur : la seule pièce du lieu dont la fonction soit
    # humaine et non structurelle. Elle donne au palier une ÉCHELLE — on lit
    # tout de suite qu'on peut s'y asseoir — et un ancrage pour l'œil juste à
    # côté du coffre.
    # Elle se place au bord déchiré, dans la BRÈCHE du parapet : c'est de là
    # qu'on regarde. Entièrement à l'EST de la boîte de la garde 3 :
    # x_min = −0,05 − 0,575·0,50 = −0,338 > −0,55.
    moellon(bm, (-0.05, -0.62, 3.05 + 0.19), (0.50, 0.44, 0.38), 137.0,
            IDX_PIERRE)

    # LES ANCIENS NIVEAUX. Ligne de plancher 1 à 3,05 m : corbeaux de pierre
    # sur l'ouest et le sud, deux bouts de solives rompues en bois. Ligne 2 à
    # 5,95 m : deux corbeaux sur l'ouest seul — il n'y a plus que lui à cette
    # hauteur. Un intérieur qui raconte deux étages effondrés.
    # (les corbeaux et solives évitent l'emprise de la vigie : un corbeau
    # sous la dalle est invisible, un corbeau à travers la dalle est une
    # bosse sur le sol praticable)
    for y in (0.05, 1.25):
        moellon(bm, (-HALF + EP * 0.5 + 0.14, y, 3.05),
                (0.30, 0.26, 0.22), 91.0 + y, IDX_PIERRE)
    # RECALÉS (lot 1.R) : la vigie s'étend désormais jusqu'à x = +0,55 ; les
    # corbeaux du mur sud à x = 0,1 seraient devenus une bosse SUR le sol
    # praticable. Ils reculent à l'est, au-delà du bord de la dalle.
    for x in (0.95, 1.50):
        moellon(bm, (x, -HALF + EP * 0.5 + 0.14, 3.05),
                (0.26, 0.30, 0.22), 95.0 + x, IDX_PIERRE)
    poutre(bm, (-HALF + EP * 0.5, 0.35, 3.22),
           (-HALF + EP * 0.5 + 0.55, 0.38, 3.18), 0.13, 0.15, IDX_BOIS)
    poutre(bm, (-HALF + EP * 0.5, 0.72, 3.22),
           (-HALF + EP * 0.5 + 0.34, 0.74, 3.20), 0.12, 0.14, IDX_BOIS)
    for y in (-0.6, 0.7):
        moellon(bm, (-NU + 0.14, y, 5.95),
                (0.30, 0.26, 0.22), 103.0 + y, IDX_PIERRE)
    poutre(bm, (-NU, 0.05, 6.10),
           (-NU + 0.42, 0.08, 6.06), 0.12, 0.14, IDX_BOIS)

    # LE FRAGMENT DU SECOND PLANCHER — la deuxième trace d'ancien niveau.
    #
    # La vigie est la première : une moitié de plancher qui a tenu. Celle-ci
    # est ce qu'il reste du second, accroché au mur ouest, bord est déchiré.
    # Elle tombe à 5,7 m du sol, soit ≈ y 105 px dans le cadre joueur, juste
    # sous la baie : on lit alors, de haut en bas, TROU / PLANCHER / RESSAUT,
    # trois événements sur le pan que Codex trouvait sans structure.
    frag_l = 1.05
    frag_y0 = -0.35
    prof_f = profil_dechire(frag_l, 1.28, 0.92, 173.0, plateau=0.15,
                            dent_pos=0.55)
    contour_f = nettoyer([(0.0, 0.0)]
                         + [(s, min(1.30, max(0.55, z))) for s, z in prof_f]
                         + [(frag_l, 0.0)])
    haut_f = [bm.verts.new((-NU + s, frag_y0 + e, 5.95))
              for s, e in contour_f]
    bas_f = [bm.verts.new((-NU + s, frag_y0 + e, 5.73))
             for s, e in contour_f]
    faces_f = [bm.faces.new(tuple(reversed(haut_f))),
               bm.faces.new(tuple(bas_f))]
    for i in range(len(contour_f)):
        j = (i + 1) % len(contour_f)
        faces_f.append(bm.faces.new((haut_f[i], haut_f[j], bas_f[j],
                                     bas_f[i])))
    for f in faces_f:
        f.material_index = IDX_PIERRE
    poutre(bm, (-NU, 0.60, 5.86), (-NU + 0.95, 0.63, 5.84), 0.13, 0.15,
           IDX_BOIS)

    # LA PORTE, HABILLÉE. L'ouverture existe déjà dans la maçonnerie ; ce qui
    # suit la rend LISIBLE : deux jambages qui débordent du nu, une pierre de
    # seuil usée en travers, et le linteau tombé devant — la pièce qui dit
    # « il y avait une porte, et elle est tombée » sans un mot, exactement
    # comme au sanctuaire.
    # LES JAMBAGES SORTENT DE LA BAIE, et c'est une mesure, pas un scrupule.
    # À la passe précédente ils étaient centrés SUR les bords de l'ouverture,
    # avec 0,34 m d'emprise en y : ils mangeaient 0,34 m des 0,60 m de jour, et
    # la porte rendait une fente de 38 px vue de biais. Ils sont désormais
    # entièrement à l'extérieur du jour (centres à −1,78 et −0,57 pour une baie
    # en −1,625..−0,725), et la baie passe de 0,60 à 0,90 m.
    # La géométrie du dégagement, puisqu'elle décide : le mur fait 0,85 m
    # d'épaisseur et la vue arrive à 19° du normal, donc l'ébrasement mange
    # 0,85 × tan 19° = 0,29 m. Il reste 0,61 m de jour à 4,9 m, soit ≈ 70 px.
    for zj in (0.58, 1.14, 1.62):
        moellon(bm, (HALF + EP * 0.44, -1.78, zj),
                (0.40, 0.26, 0.44), 201.0 + zj * 3.1, IDX_PIERRE, jitter=0.12)
        moellon(bm, (HALF + EP * 0.44, -0.57, zj + 0.18),
                (0.40, 0.24, 0.40), 211.0 + zj * 2.7, IDX_PIERRE, jitter=0.12)
    moellon(bm, (2.86, -1.175, 0.33), (1.06, 0.86, 0.30), 181.0, IDX_PIERRE,
            jitter=0.14)
    moellon(bm, (3.78, -1.33, 0.37), (1.30, 0.54, 0.34), 191.0, IDX_PIERRE,
            jitter=0.10)
    moellon(bm, (4.42, -0.92, 0.36), (0.52, 0.44, 0.30), 197.0, IDX_PIERRE,
            jitter=0.22)


# ---------------------------------------------------------------------------
# SM_Watchtower_Talus — l'effondrement, en éclats (jamais des pavés)
# ---------------------------------------------------------------------------
# (tour, rayon rel., échelle XY, échelle Z, côtés, pose) — cœur haut contre
# la brèche, deux grappes, morceaux projetés, et un large secteur VIDE côté
# tour (rien n'est tombé VERS le mur qui tient).
SEMIS_TALUS = (
    (0.02, 0.16, 1.45, 1.60, 6, 0.30),
    (0.94, 0.24, 1.20, 1.30, 5, 0.18),
    (0.08, 0.44, 1.05, 0.95, 5, 0.10),
    (0.15, 0.66, 0.85, 0.70, 4, 0.03),
    (0.88, 0.52, 0.95, 0.80, 6, 0.05),
    (0.82, 0.86, 0.66, 0.52, 5, 0.00),
    (0.05, 0.92, 0.72, 0.48, 4, 0.00),
    (0.22, 0.88, 0.58, 0.42, 5, 0.00),
    (0.11, 1.02, 0.50, 0.38, 4, 0.00),
)


def talus(bm):
    for i, (tour, rayon_rel, ech_xy, ech_z, cotes, pose) in \
            enumerate(SEMIS_TALUS):
        g = 5.7 + i * 1.37
        rotation = (_graine(g * 1.7) * 0.62, _graine(g * 2.3) * 0.62,
                    2.0 * math.pi * (tour + _graine(g * 3.1) * 0.25))
        angle = 2.0 * math.pi * tour
        eclat(bm,
              (math.cos(angle) * rayon_rel * 1.55,
               math.sin(angle) * rayon_rel * 1.15, 0.0),
              (0.55 * ech_xy, 0.46 * ech_xy, 0.24 * ech_z),
              g, IDX_PIERRE, cotes=cotes, rotation=rotation, pose=pose)


# ---------------------------------------------------------------------------
# SM_Watchtower_Slab_A/B — pans de mur TOMBÉS entiers, épaisseur visible
# ---------------------------------------------------------------------------
def pan_tombe(bm, longueur, largeur, graine):
    """Une plaque de maçonnerie tombée À PLAT (le lieu l'incline) : contour
    en plan avec bords d'arrachement dentelés, épaisseur EP réelle — la
    plaque correspond à un manque visible dans les murs."""
    profil = profil_dechire(longueur, largeur, largeur * 0.45, graine,
                            plateau=0.28, dent_pos=0.55)
    contour = [(0.0, 0.0)] + [(s, max(0.14, z * 0.9)) for s, z in profil] \
        + [(longueur, 0.0)]
    # extrusion VERTICALE cette fois : le contour est en plan (x, y), la
    # plaque a l'épaisseur du mur en z.
    avant = [bm.verts.new((s, z, EP * 0.9)) for s, z in contour]
    arriere = [bm.verts.new((s, z, 0.0)) for s, z in contour]
    faces = [bm.faces.new(tuple(avant)),
             bm.faces.new(tuple(reversed(arriere)))]
    n = len(contour)
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((avant[i], avant[j], arriere[j],
                                   arriere[i])))
    for f in faces:
        f.material_index = IDX_PIERRE
    # Deux moellons restés scellés sur la plaque.
    moellon(bm, (longueur * 0.32, largeur * 0.42, EP * 0.9 + 0.07),
            (0.42, 0.34, 0.20), graine * 3.1, IDX_PIERRE)
    moellon(bm, (longueur * 0.70, largeur * 0.30, EP * 0.9 + 0.05),
            (0.30, 0.28, 0.16), graine * 4.7, IDX_PIERRE)


# ---------------------------------------------------------------------------
# SM_Watchtower_CrownBlock — le bloc de couronne pris dans la pente
# ---------------------------------------------------------------------------
def bloc_couronne(bm):
    eclat(bm, (0.0, 0.0, 0.0), (1.65, 1.30, 0.85), 9.4, IDX_PIERRE,
          cotes=6, rotation=(0.24, -0.18, 0.8), pose=0.0)
    eclat(bm, (0.85, 0.55, 0.0), (0.85, 0.70, 0.45), 3.8, IDX_PIERRE,
          cotes=5, rotation=(-0.3, 0.2, 2.1), pose=0.02)
    moellon(bm, (-0.35, -0.42, 0.55), (0.5, 0.42, 0.26), 17.3, IDX_PIERRE)


# ---------------------------------------------------------------------------
# Assemblage, gardes, enregistrement
# ---------------------------------------------------------------------------
# Réglages de `COLOR_0` par pièce. Le fût est TEXTURÉ (cartes du kit branchées
# côté Godot) : la couleur de sommet n'y est qu'une macro-variation, calée sur
# le pas d'assise, plus le creusement du parement intérieur. Les pièces TOMBÉES
# sont en APLAT côté Godot : chez elles, `COLOR_0` est la SEULE matière, d'où un
# contraste et des veines nettement plus forts.
#     (période, contraste, pied_facteur, veine, axe, creux)
COULEURS_PAR_PIECE = {
    "SM_Watchtower_Shell": (2.0 * ASSISE, 0.26, 0.22, 0.10, "z", 0.16),
    "SM_Watchtower_Talus": (0.34, 0.40, 0.75, 0.19, "auto", 0.0),
    "SM_Watchtower_Slab_A": (0.52, 0.38, 0.60, 0.17, "auto", 0.0),
    "SM_Watchtower_Slab_B": (0.46, 0.38, 0.60, 0.17, "auto", 0.0),
    "SM_Watchtower_CrownBlock": (0.58, 0.36, 0.55, 0.16, "auto", 0.0),
}


def objet_depuis(nom, remplir):
    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()
    remplir(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    deplier_boite(bm)
    bm.to_mesh(maillage)
    bm.free()
    bas = min(v.co.z for v in maillage.vertices)
    for v in maillage.vertices:
        v.co.z -= bas
    # APRÈS le recalage de la base : `poser_couleurs` lit `v.co.z` pour
    # assombrir le pied, et le ferait au mauvais endroit sur une pièce non
    # recalée. Ordre non commutatif, d'où ce commentaire.
    periode, contraste, pied, veine, axe, creux = COULEURS_PAR_PIECE[nom]
    poser_couleurs(maillage, periode, contraste, pied, veine, axe, creux)
    obj = bpy.data.objects.new(nom, maillage)
    for nom_mat in ORDRE_MATERIAUX:
        obj.data.materials.append(materiau(nom_mat))
    bpy.context.collection.objects.link(obj)
    return obj


def tris_de(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def emprise(obj):
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pieces = [
        objet_depuis("SM_Watchtower_Shell", coquille),
        objet_depuis("SM_Watchtower_Talus", talus),
        objet_depuis("SM_Watchtower_Slab_A",
                     lambda bm: pan_tombe(bm, 2.35, 1.55, 6.1)),
        objet_depuis("SM_Watchtower_Slab_B",
                     lambda bm: pan_tombe(bm, 1.75, 1.20, 14.9)),
        objet_depuis("SM_Watchtower_CrownBlock", bloc_couronne),
    ]

    total = 0
    for obj in pieces:
        n = tris_de(obj)
        total += n
        (x0, x1), (y0, y1), (z0, z1) = emprise(obj)
        print("[watchtower_ruin] %-26s %5d tris  X %6.2f..%5.2f  "
              "Y %6.2f..%5.2f  Z %6.3f..%5.2f"
              % (obj.name, n, x0, x1, y0, y1, z0, z1))
        if z0 < -BASE_TOL_DESSOUS or z0 > BASE_TOL_DESSUS:
            print("[watchtower_ruin] ERREUR: base de %s à Z=%.3f" % (obj.name,
                                                                     z0))
            return 2

    print("[watchtower_ruin] total %d triangles (budget %d)"
          % (total, BUDGET_TRIS))
    if total > BUDGET_TRIS:
        print("[watchtower_ruin] ERREUR: budget dépassé — le générateur "
              "REFUSE d'enregistrer")
        return 2

    # GARDE 1 — LES ARASES SONT ROMPUES. C'est le reproche central du rejet
    # (« empilement de boîtes » : toutes les arases identiques, écart-type
    # mesuré 0,050 m sur la ferme R2B.1). Ici l'écart des quatre arases de
    # départ vaut 5,9 m ; on refuse d'enregistrer sous 4,0 m.
    arases = (H_OUEST, H_NORD, H_SUD, H_EST)
    if max(arases) - min(arases) < 4.0:
        print("[watchtower_ruin] ERREUR: arases trop proches (%.2f m)"
              % (max(arases) - min(arases)))
        return 2
    print("[watchtower_ruin] arases : %s — étendue %.2f m, %d gradins"
          % (", ".join("%.2f" % a for a in arases),
             max(arases) - min(arases), GRADINS_TOTAL))
    if GRADINS_TOTAL < 12:
        print("[watchtower_ruin] ERREUR: %d gradin(s) < 12 — la maçonnerie "
              "ne casse nulle part" % GRADINS_TOTAL)
        return 2

    # GARDE 1b — LES OUVERTURES EXISTENT TOUTES LES CINQ.
    #
    # `mur()` REFUSE une baie dont le linteau mangerait l'arase : c'est le bon
    # comportement (mieux vaut pas de baie qu'un créneau involontaire), mais
    # un refus silencieux rendrait un mur plein en ayant l'air d'avoir marché.
    # Le compte est donc vérifié ici, et il nomme le manque.
    if BAIES_TOTAL != 5:
        print("[watchtower_ruin] ERREUR: %d baie(s) percée(s) sur 5 — une "
              "ouverture a été refusée (linteau trop mince sous l'arase). "
              "Baisser son z_haut ou la déplacer vers le pied du mur."
              % BAIES_TOTAL)
        return 2
    print("[watchtower_ruin] baies : %d percées (porte est, 2 ouest, "
          "1 nord, 1 sud)" % BAIES_TOTAL)

    # GARDE 2 — L'ENTRÉE RESTE OUVERTE. Aucun sommet de la coquille dans le
    # volume de passage de la brèche nord-est (le lieu y fait passer le
    # joueur, et le filet D4 y fait passer la découverte).
    shell = pieces[0]
    intrus = 0
    for v in shell.data.vertices:
        if (1.30 <= v.co.x <= 2.40 and 0.25 <= v.co.y <= 1.55
                and 0.45 <= v.co.z <= 2.10):
            intrus += 1
    if intrus:
        print("[watchtower_ruin] ERREUR: %d sommet(s) dans le volume de la "
              "brèche — l'entrée n'est plus ouverte" % intrus)
        return 2
    print("[watchtower_ruin] brèche : volume de passage libre (0 sommet)")

    # GARDE 3 — LA VIGIE EXISTE ET ON PEUT S'Y TENIR (arbitrage compo B).
    # a. une dalle à 3,05 m d'aire suffisante dans le quart sud-ouest ;
    # b. AUCUNE géométrie dans le volume où se tient la capsule du joueur
    #    au-dessus de la dalle (1,05–2,0 m au-dessus du sol de la vigie).
    #
    # LA MESURE DE (a) A CHANGÉ AU LOT 1.R, ET C'EST UNE CORRECTION, PAS UN
    # ASSOUPLISSEMENT. L'ancienne comptait les sommets à z = 3,05 vérifiant
    # `x < −0,30 et y < −0,55`. Ces deux bornes n'étaient pas le quart
    # sud-ouest : c'était la position du BORD DÉCHIRÉ de la dalle d'alors.
    # En agrandissant la dalle, son bord est parti vers le nord (y ≥ −0,395),
    # et la garde a compté 4 sommets au lieu de 8 — donc REFUSÉ D'ENREGISTRER
    # une dalle deux fois plus grande que celle qu'elle acceptait. Elle
    # mesurait la forme d'hier, pas la propriété qu'on veut.
    #
    # La propriété qu'on veut est une AIRE. Elle est calculée sur le contour
    # réel (lacet de Gauss) et comparée à celle de la dalle précédente, dont
    # les cotes sont conservées ici pour que le plancher soit une MESURE et
    # non un chiffre choisi : `profil_dechire(1.42, 1.15, 0.62, 77.0, 0.10,
    # 0.45)` clampé à 0,30, soit 1,197 m². Le plancher est donc l'ancienne
    # dalle elle-même : la garde ne peut pas accepter moins qu'avant.
    ancien_profil = profil_dechire(1.42, 1.15, 0.62, 77.0, plateau=0.10,
                                   dent_pos=0.45)
    aire_ancienne = aire_contour(
        [(0.0, 0.0)] + [(s, max(0.30, z)) for s, z in ancien_profil]
        + [(1.42, 0.0)])
    if VIGIE_AIRE < aire_ancienne:
        print("[watchtower_ruin] ERREUR: dalle de vigie %.3f m² < plancher "
              "%.3f m² (l'ancienne dalle)" % (VIGIE_AIRE, aire_ancienne))
        return 2
    # Et la dalle est bien LÀ, à la bonne cote, dans le bon quadrant : sans ce
    # second contrôle, une aire correcte pourrait décrire un contour posé
    # n'importe où. Les bornes sont ici celles du QUADRANT (le fût intérieur
    # va de −1,775 à +1,775 ; son quart sud-ouest est x ≤ 0,20, y ≤ −0,20),
    # pas celles d'un bord particulier.
    dalle = sum(1 for v in shell.data.vertices
                if abs(v.co.z - 3.05) < 0.02 and v.co.x < 0.20
                and v.co.y < -0.20)
    if dalle < 8:
        print("[watchtower_ruin] ERREUR: vigie absente (%d sommet(s) à "
              "z=3,05 dans le quart SO)" % dalle)
        return 2
    print("[watchtower_ruin] vigie : dalle %.3f m² (plancher %.3f m², "
          "ancienne dalle)" % (VIGIE_AIRE, aire_ancienne))
    # Les coupables sont NOMMÉS par leurs coordonnées : un compte seul oblige
    # la passe suivante à deviner lequel des huit sommets jittés d'un moellon
    # dépasse, et c'est une demi-heure perdue (mesuré ici même).
    intrus_capsule = [(v.co.x, v.co.y, v.co.z) for v in shell.data.vertices
                      if -1.70 <= v.co.x <= -0.55
                      and -1.70 <= v.co.y <= -0.75 and 3.30 <= v.co.z <= 4.90]
    obstacles = len(intrus_capsule)
    if obstacles:
        print("[watchtower_ruin] ERREUR: %d sommet(s) dans le volume de la "
              "capsule au-dessus de la vigie : %s" % (obstacles, ", ".join(
                  "(%.3f, %.3f, %.3f)" % p for p in intrus_capsule[:6])))
        return 2
    print("[watchtower_ruin] vigie : dalle présente (%d sommets), volume "
          "capsule libre" % dalle)

    # GARDE 5 — LA POINTE D'ARASE SURVIVANTE EXISTE (LOT 1.R.4). C'est le
    # geste qui sépare le masque 0° de la tour du monticule de la grotte
    # (paire R-D3 0,4975 / 0,4930 contre seuils 0,4931 / 0,4912) : s'il
    # disparaît dans une passe future, la répétition revient sans qu'aucun
    # diff de ce fichier ne le dise. Quatre sommets au moins au-dessus de
    # 10,5 m dans l'emprise de l'angle sud-ouest du mur ouest.
    pointe = sum(1 for v in shell.data.vertices
                 if v.co.z > 10.5 and v.co.x < -1.7 and v.co.y < -1.0)
    if pointe < 4:
        print("[watchtower_ruin] ERREUR: pointe d'arase survivante absente "
              "(%d sommet(s) > 10,5 m à l'angle SO) — le masque 0° redevient "
              "un monticule (R-D3 tour × grotte)" % pointe)
        return 2
    print("[watchtower_ruin] pointe d'arase : %d sommets > 10,5 m à "
          "l'angle SO" % pointe)

    # GARDE 4 — COLOR_0 PRÉSENTE, ACTIVE ET DE RENDU (ISS-066).
    # `tools/gltf_inspect.py` ne regarde JAMAIS COLOR_0 : il répondrait
    # `VALIDE` sur un asset qui vient de perdre toute sa matière. La seule
    # vérification possible est ici, à la source, et elle REFUSE d'enregistrer.
    sans = [o.name for o in pieces
            if o.data.color_attributes is None
            or NOM_COULEUR not in o.data.color_attributes]
    if sans:
        print("[watchtower_ruin] ERREUR: %d pièce(s) sans COLOR_0 : %s"
              % (len(sans), ", ".join(sans)))
        return 2
    mal_reglees = [o.name for o in pieces
                   if o.data.color_attributes.active_color_index
                   != o.data.color_attributes.find(NOM_COULEUR)
                   or o.data.color_attributes.render_color_index
                   != o.data.color_attributes.find(NOM_COULEUR)]
    if mal_reglees:
        print("[watchtower_ruin] ERREUR: COLOR_0 pas active/de rendu sur : %s"
              % ", ".join(mal_reglees))
        return 2
    etendue_min = 9.9
    for o in pieces:
        valeurs = [d.color[0] for d in o.data.color_attributes[NOM_COULEUR].data]
        etendue_min = min(etendue_min, max(valeurs) - min(valeurs))
    if etendue_min < 0.20:
        print("[watchtower_ruin] ERREUR: étendue de COLOR_0 trop faible "
              "(min %.3f) — l'aplat reviendrait" % etendue_min)
        return 2
    print("[watchtower_ruin] COLOR_0 : %d pièces, active ET de rendu, "
          "étendue min %.3f" % (len(pieces), etendue_min))

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_Watchtower_Ruin.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[watchtower_ruin] source enregistrée -> %s" % sortie)
    print("FIN NOMINALE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
