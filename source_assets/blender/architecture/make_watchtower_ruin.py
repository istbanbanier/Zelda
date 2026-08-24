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
HALF = 2.0            # demi-entraxe des murs
EP = 0.45             # épaisseur de mur — VISIBLE dans les brèches
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
H_EST_FIN = 1.35

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
    return mat


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


def moellon(bm, centre, taille, graine, materiau_idx):
    """Une pierre : boîte aux huit sommets déplacés, jamais un cube net."""
    cx, cy, cz = centre
    dx, dy, dz = taille
    sommets = []
    for i, (sx, sy, sz) in enumerate(((-1, -1, -1), (1, -1, -1), (1, 1, -1),
                                      (-1, 1, -1), (-1, -1, 1), (1, -1, 1),
                                      (1, 1, 1), (-1, 1, 1))):
        j = _graine(graine * 3.7 + i * 1.9)
        sommets.append(bm.verts.new((
            cx + sx * dx * 0.5 * (1.0 + j * 0.30),
            cy + sy * dy * 0.5 * (1.0 + _graine(graine + i * 2.3) * 0.30),
            cz + sz * dz * 0.5 * (1.0 + _graine(graine * 1.3 + i) * 0.22))))
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


def mur(bm, origine, direction, longueur, h0, h1, graine, plateau, dent,
        interieur_flip=False):
    """Un mur déchiré. `interieur_flip` retourne l'axe d'épaisseur pour que
    la face `+w` — celle qui reçoit `MAT_Tower_StoneInner` — soit toujours
    le parement INTÉRIEUR, quel que soit le côté du fût."""
    global GRADINS_TOTAL
    profil = profil_dechire(longueur, h0, h1, graine, plateau, dent)
    GRADINS_TOTAL += compter_gradins(profil)
    contour = [(0.0, 0.0)] + profil + [(longueur, 0.0)]
    w = (direction[1] * EP, -direction[0] * EP)
    if interieur_flip:
        w = (-w[0], -w[1])
    prisme_frame(bm, (origine[0], origine[1], 0.0),
                 (direction[0], direction[1]), (w[0], w[1]),
                 contour, IDX_PIERRE, materiau_avant=IDX_PIERRE_INT)
    return profil


def coquille(bm):
    """Le fût. Quatre murs, quatre arases, une brèche — et l'histoire des
    deux étages disparus, lisible par la brèche."""
    global GRADINS_TOTAL
    GRADINS_TOTAL = 0
    # OUEST — le plus haut, face au couchant. Il court sur TOUTE la largeur.
    mur(bm, (-HALF, -HALF - EP * 0.5), (0.0, 1.0), 2.0 * HALF + EP,
        H_OUEST, H_OUEST_FIN, 11.0, 0.30, 0.52)
    # NORD — s'arrête à la brèche, arase qui plonge vers l'arrachement.
    mur(bm, (-HALF - EP * 0.5, HALF), (1.0, 0.0),
        BRECHE_X_NORD + HALF + EP * 0.5, H_NORD, H_NORD_FIN, 23.0, 0.16, 0.60)
    # SUD — entier mais bien plus bas que l'ouest.
    mur(bm, (-HALF - EP * 0.5, -HALF), (1.0, 0.0), 2.0 * HALF + EP,
        H_SUD, H_SUD_FIN, 37.0, 0.22, 0.72, interieur_flip=True)
    # EST — la seule travée debout, au sud de la brèche.
    mur(bm, (HALF, -HALF - EP * 0.5), (0.0, 1.0),
        BRECHE_Y_EST + HALF + EP * 0.5, H_EST, H_EST_FIN, 47.0, 0.34, 0.62,
        interieur_flip=True)

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
    marches_1 = 6
    tread = 0.30
    rise = 0.27
    x_dep = 0.85
    largeur_marche = 0.78
    contour = [(0.0, 0.0)]
    for m in range(marches_1):
        contour.append((m * tread, (m + 1) * rise))
        contour.append(((m + 1) * tread, (m + 1) * rise))
    contour.append((marches_1 * tread, 0.0))
    # le long du mur nord, on monte vers l'ouest : u = (-1, 0)
    prisme_frame(bm, (x_dep, HALF - EP * 0.5 - largeur_marche * 0.5, 0.0),
                 (-1.0, 0.0), (0.0, largeur_marche), contour, IDX_PIERRE)
    # Volée 2 : le long du mur ouest, du palier tournant (z=1,62) à la
    # VIGIE (z=3,05 — arbitrage « La vigie retrouvée »). Marches en
    # encorbellement scellées dans le parement, contremarches 0,28 m
    # (step_height du contrôleur : 0,30–0,38) et girons 0,33 m — la montée
    # est jouable aux vrais contrôles, pas seulement dessinée.
    z0 = marches_1 * rise
    marches_2 = 5
    for m in range(marches_2):
        y = 1.20 - m * 0.33
        moellon(bm, (-HALF + EP * 0.5 + 0.40, y, z0 + (m + 1) * 0.28 - 0.07),
                (0.85, 0.55, 0.17), 71.0 + m * 1.9, IDX_PIERRE)
    # Le palier d'angle entre les deux volées.
    moellon(bm, (-HALF + 0.75, HALF - 0.55, z0 - 0.08),
            (0.95, 0.75, 0.18), 83.0, IDX_PIERRE)
    # LA VIGIE — la moitié SUD-OUEST du premier plancher a TENU : une dalle
    # de pierre appuyée sur les murs ouest et sud, bord d'arrachement
    # dentelé vers le nord-est (le reste est tombé — c'est le talus).
    # Épaisseur 0,22 m, dessus à 3,05 m : la ligne des corbeaux. Le joueur
    # y monte, et le paysage entre par la brèche au-dessus de la travée
    # est (arase 3,05 → 1,35) : la récompense-paysage AVANT les flèches.
    vigie_bas = 3.05 - 0.22
    profil_bord = profil_dechire(1.42, 1.15, 0.62, 77.0, plateau=0.10,
                                 dent_pos=0.45)
    contour_vigie = [(0.0, 0.0)] + [(s, max(0.30, z)) for s, z in profil_bord] \
        + [(1.42, 0.0)]
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
    moellon(bm, (-HALF + EP * 0.5 + 1.30, -HALF + 0.55, vigie_bas - 0.10),
            (0.30, 0.26, 0.24), 111.0, IDX_PIERRE)
    moellon(bm, (-HALF + EP * 0.5 + 0.75, -HALF + 1.15, vigie_bas - 0.10),
            (0.26, 0.30, 0.24), 113.0, IDX_PIERRE)

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
    for x in (0.1, 1.0):
        moellon(bm, (x, -HALF + EP * 0.5 + 0.14, 3.05),
                (0.26, 0.30, 0.22), 95.0 + x, IDX_PIERRE)
    poutre(bm, (-HALF + EP * 0.5, 0.35, 3.22),
           (-HALF + EP * 0.5 + 0.55, 0.38, 3.18), 0.13, 0.15, IDX_BOIS)
    poutre(bm, (-HALF + EP * 0.5, 0.72, 3.22),
           (-HALF + EP * 0.5 + 0.34, 0.74, 3.20), 0.12, 0.14, IDX_BOIS)
    for y in (-0.6, 0.7):
        moellon(bm, (-HALF + EP * 0.5 + 0.14, y, 5.95),
                (0.30, 0.26, 0.22), 103.0 + y, IDX_PIERRE)
    poutre(bm, (-HALF + EP * 0.5, 0.05, 6.10),
           (-HALF + EP * 0.5 + 0.42, 0.08, 6.06), 0.12, 0.14, IDX_BOIS)


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
    # a. une surface à 3,05 m d'au moins ~1 m² dans le quart sud-ouest ;
    # b. AUCUNE géométrie dans le volume où se tient la capsule du joueur
    #    au-dessus de la dalle (1,05–2,0 m au-dessus du sol de la vigie).
    dalle = sum(1 for v in shell.data.vertices
                if abs(v.co.z - 3.05) < 0.02 and v.co.x < -0.30
                and v.co.y < -0.55)
    if dalle < 8:
        print("[watchtower_ruin] ERREUR: vigie absente (%d sommet(s) à "
              "z=3,05 dans le quart SO)" % dalle)
        return 2
    obstacles = sum(1 for v in shell.data.vertices
                    if -1.70 <= v.co.x <= -0.55 and -1.70 <= v.co.y <= -0.75
                    and 3.30 <= v.co.z <= 4.90)
    if obstacles:
        print("[watchtower_ruin] ERREUR: %d sommet(s) dans le volume de la "
              "capsule au-dessus de la vigie" % obstacles)
        return 2
    print("[watchtower_ruin] vigie : dalle présente (%d sommets), volume "
          "capsule libre" % dalle)

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_Watchtower_Ruin.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[watchtower_ruin] source enregistrée -> %s" % sortie)
    print("FIN NOMINALE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
