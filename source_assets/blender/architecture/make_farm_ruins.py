# SOURCE DE GÉNÉRATION REPRODUCTIBLE — Ruine de toiture de la ferme
# abandonnée (V2.3-A.R2B, agent B).
#
# POURQUOI CE FICHIER EXISTE. Le lead a rejeté la charpente procédurale de
# la fermette : « de longues planches plantées dans le bâtiment et dans
# l'arbre ». Le défaut était structurel — des `stone_block` posés un par un
# ne partagent aucune logique porteuse : les chevrons ne touchaient ni la
# faîtière ni les murs, et chaque bloc pouvait flotter seul. Ici la
# charpente est UN objet : la faîtière cassée en deux, ses chevrons
# SOLIDAIRES (générés du même trait, du faîte à l'arase), les sablières qui
# reposent sur les murs. Rien ne peut se désolidariser par construction.
#
# R2B.1 — SECONDE REVUE DU LEAD : « techniquement propre mais se lit comme une
# boîte beige inachevée ou un greybox ; murs rectangulaires lisses, charpente
# trop vide, peu de masse effondrée et presque aucune histoire structurelle
# visible ». Le défaut a été MESURÉ avant d'être corrigé (sonde du 2026-08-19) :
#
#   ARASES : n=15 min=3.059 max=3.173 moy=3.142 ecart_type=0.050 m
#
# Les onze modules de mur du kit sont TOUS à 3,173 m — cinq centimètres de
# dispersion sur 6,4 m de bâtiment. La maçonnerie ne casse nulle part, d'où le
# contour « rectangle + chapeau ». Et l'inspection glTF du module de kit
# explique les grands aplats : `MI_UnevenBrick` est un plan STRICT à Z = 0,000
# (4 tris), `MI_Plaster` un plan STRICT à Z = -0,200 (2 tris), sans AUCUNE face
# de chant entre les deux — soit 6,00 m² de façade décrits par deux triangles.
#
# Cinq objets sont donc AJOUTÉS ici : ils apportent la masse qui manque, là où
# le kit ne peut pas en fournir (pignon arraché, moignon de mur, talus de
# moellons, tableaux d'épaisseur, ossature intérieure). Les cinq objets de R2B
# gardent leur nom : le filet `test_world_v2_r2b_farm_tree.gd` les désigne.
#
# QUATRE MATÉRIAUX DEPUIS LE 2026-08-19, ET POURQUOI. Ce fichier était
# verrouillé à TROIS matériaux. Le lead a porté la limite à QUATRE ce jour-là,
# sur demande argumentée : les moellons d'un mur écroulé sont de la PIERRE, et
# les peindre avec `MAT_Farm_Tiles` les ferait lire comme de la terre cuite —
# mentir sur la matière pour tenir un compte n'est pas tenir un budget. Le
# plafond de 4 500 TRIANGLES, lui, n'a pas bougé d'un triangle : c'est lui qui
# protège le budget, et il refuse toujours l'enregistrement au-delà.
#
# QUATRE FAMILLES D'OBJETS, UN SEUL GLB (même pratique que
# make_village_wall.py, deux objets dans SM_Village_Wall.glb) :
#   * `SM_Farm_Truss`          — charpente : faîtière rompue, chevrons,
#                                sablières ; base Z=0 à l'ARASE des murs
#                                (3,12 m mesurés, probe_kit_seating) ;
#   * `SM_Farm_RoofPan_Intact` — pan de couverture À PLAT (~3,6 × 6,8 m),
#                                posé par le lieu à 22° sur le versant
#                                ouest ; rangées de tuiles à recouvrement ;
#   * `SM_Farm_RoofPan_Fallen` — pan PLIÉ en deux segments, un bout au
#                                sol : la géométrie porte la chute, le lieu
#                                ne fait que le poser ;
#   * `SM_Farm_Debris_A/B`     — gravats fusionnés : éclats de tuiles et
#                                bouts de chevrons, base Z=0.
#
# AJOUTS R2B.1 :
#   * `SM_Farm_GableBreak`     — pignon nord ROMPU : monte au faîte puis
#                                s'arrache en gradins d'assise vers l'est ;
#                                un VOLUME de 0,40 m d'épaisseur, jamais un
#                                plan. C'est la rupture majeure de silhouette ;
#   * `SM_Farm_WallStub_East`  — moignon du mur est écroulé, arase brisée en
#                                diagonale : transforme un trou net en
#                                arrachement ;
#   * `SM_Farm_Rubble_Wall`    — talus de moellons : la matière du mur écroulé,
#                                au pied de la brèche. Sans lui, un mur
#                                disparaît sans laisser de trace ;
#   * `SM_Farm_Jambs`          — tableaux de baie et seuils : ils donnent au
#                                mur la TRANCHE que le module de kit n'a pas ;
#   * `SM_Farm_InteriorFrame`  — ossature intérieure : poteaux, décharges et
#                                solives rompues du plancher disparu. Elle
#                                découpe le quad de 6 m² et empêche l'intérieur
#                                de se lire comme une coque vide.
#
# BUDGET VERROUILLÉ AVANT MODÉLISATION (arbitrage R2B) : ferme ≤ 4 500
# triangles au total, 3 matériaux, sRGB converti en linéaire explicitement.
# Le générateur REFUSE d'enregistrer au-delà — le budget se vérifie à
# l'export, pas dans un rapport.
#
# Blender est Z-up ; l'export convertit en Y-up : Blender (x, y, z) devient
# Godot (x, z, -y). La faîtière court selon Blender Y, donc Godot Z ; le
# versant intact est en Blender/Godot -X (ouest) ; l'effondrement regarde
# Godot +Z (sud), soit Blender -Y.
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/architecture/make_farm_ruins.py

import math
import os
import sys

import bmesh
import bpy

# ---------------------------------------------------------------------------
# Cotes — mesurées sur le bâti réel, jamais devinées.
# probe_kit_seating (2026-08-19) : Wall_UnevenBrick_* fait 2,00 × 3,12 ×
# 0,41, pivot min-Y — l'arase est donc à 3,12 m au-dessus du plancher des
# murs, et la charpente pose son Z=0 sur ce plan.
# ---------------------------------------------------------------------------
DEMI_PORTEE = 3.05      # du faîte à l'aplomb du mur (murs à ±3,0)
PENTE_DEG = 22.0
FAITE_Z = DEMI_PORTEE * math.tan(math.radians(PENTE_DEG))   # ≈ 1,232

CHEVRON_SECTION = (0.09, 0.14)
SABLIERE_SECTION = (0.16, 0.14)
FAITIERE_SECTION = (0.14, 0.20)

PAN_PENTE_M = 3.55      # longueur de versant du pan intact
PAN_LONG_M = 6.80       # le long du faîte
PAN_RANGS = 6           # rangées de tuiles à recouvrement

BUDGET_TRIS = 4500
# La base est « au sol » si RIEN ne perce le sol (‑5 mm) et si le point
# bas reste à moins de 5 cm du plan : un assemblage de plaques inclinées
# n'a pas de face inférieure exactement plane, exiger 0,000 pousserait à
# tricher sur la géométrie plutôt qu'à poser juste.
BASE_TOL_DESSOUS = 0.005
BASE_TOL_DESSUS = 0.05

# ---------------------------------------------------------------------------
# Cotes R2B.1 — la ruine gagne sa masse
# ---------------------------------------------------------------------------
EPAISSEUR_MUR = 0.40    # l'épaisseur RÉELLE du mur : toute pièce est un volume
ASSISE_H = 0.22         # hauteur d'assise ; c'est le PAS des gradins
                        # d'arrachement — une maçonnerie se rompt par lits,
                        # jamais en diagonale lisse.

# Fraction du rampant EST emportée par l'arrachement du pignon. C'est la
# constante que le contrôle de silhouette surveille : à 0,0 le pignon
# redevient un triangle intact, donc un mur de plus au lieu d'une rupture.
PIGNON_ARRACHE = 0.45

# R2B.2 — LE PIED DU PIGNON. Il ne coiffe plus l'arase, il DESCEND dedans :
# le lieu le pose 0,55 m plus bas et le contour gagne d'autant, si bien que le
# faîte ne bouge pas d'un centimètre. Mesuré avant le geste : le pignon
# n'entrait que de 0,06 m dans l'arase et débordait de 0,34 m devant le
# parement — un bandeau en surplomb sur un mur qui n'est qu'un plan, donc une
# plaque posée. Cinq assises de recouvrement et le même parement suppriment
# les deux causes d'un coup.
PIGNON_PIED_Z = 0.55
# Épaisseur du pignon : Blender y ∈ [-0,34 ; 0,00] ⇒ Godot z ∈ [0,00 ; 0,34],
# et le relief de parement ressort de 4 cm vers Godot -z, côté extérieur.
PIGNON_Y_DEDANS = -0.34
PIGNON_RELIEF_Y = 0.005

MOIGNON_H_HAUTE = 1.15  # ce qui reste debout du mur est, côté nord
MOIGNON_H_BASSE = 0.48  # ... et côté sud, là où l'arrachement a mordu

# ---------------------------------------------------------------------------
# Matériaux — sRGB converti en linéaire (glTF stocke du linéaire, Godot
# réencode en sRGB : écrire 0,40 tel quel rendrait 0,67).
#
# Hiérarchie de valeur visée sous l'éclairage du monde : murs de brique
# teintés ≈ 0,45 rendu ; les TUILES restent SOUS les murs (0,36), le BOIS
# de charpente encore dessous (0,28), et le bois ROMPU (cœur frais) porte
# le seul accent clair — c'est lui qui raconte la cassure récente.
# Recalage obligatoire sur la capture : un albédo n'est pas une valeur
# rendue (scripts/CLAUDE.md).
# ---------------------------------------------------------------------------
MATERIAUX = {
    "MAT_Farm_Wood": (0.330, 0.260, 0.185, 0.95),
    "MAT_Farm_Tiles": (0.450, 0.330, 0.250, 0.92),
    "MAT_Farm_BrokenWood": (0.720, 0.620, 0.460, 0.90),
    # PIERRE À NU (R2B.1) : un mur écroulé montre son moellon, pas son crépi.
    #
    # RECALÉ SUR CAPTURE le 2026-08-19, et c'est la raison d'être de la règle
    # « un albédo n'est pas une valeur rendue ». La première valeur
    # (0,400 / 0,358 / 0,312) visait « plus sombre et plus froid que le mur ».
    # À l'écran elle est sortie GRIS ARDOISE : le pignon se lisait comme un
    # carton posé sur la maison et les jambages comme des poteaux métalliques,
    # tous deux en rupture franche avec la pierre ocre du kit. Le défaut
    # n'était pas la luminance mais la SATURATION — désaturée à ce point, la
    # pierre quitte la famille chromatique du lieu. Re-saturée vers l'ocre et
    # descendue d'un cran, elle reste sous les murs debout sans les renier.
    "MAT_Farm_Stone": (0.430, 0.337, 0.243, 0.94),
}
IDX_BOIS = 0
IDX_TUILES = 1
IDX_CASSURE = 2
IDX_PIERRE = 3
ORDRE_MATERIAUX = ("MAT_Farm_Wood", "MAT_Farm_Tiles", "MAT_Farm_BrokenWood",
                   "MAT_Farm_Stone")


# ---------------------------------------------------------------------------
# DÉPLIAGE UV0 (R2B.2) — ET POURQUOI IL EXISTE
#
# Sonde Godot du 2026-08-19 : les 12 pièces de ce fichier sortaient avec
# 23 surfaces sur 23 SANS `ARRAY_FORMAT_TEX_UV` et sans texture, quand le
# module de kit qui les touche, `Wall_UnevenBrick_Straight`, a UV0 sur ses
# 3 surfaces et porte `T_UnevenBrick_BaseColor.png`. C'est cette discontinuité
# de MATIÈRE, mur contre mur, qui produit le « carton découpé » du lead — pas
# un manque d'épaisseur : la mesure dit qu'une seule pièce sur douze est une
# plaque, et que les tableaux sont plus épais que le mur qu'ils bordent.
#
# LES ÉCHELLES SONT MESURÉES, PAS CHOISIES. Sur `Wall_UnevenBrick_Straight`,
# 1 tuile UV couvre 2,00 m en U et 2,11 m en V, soit ~0,48 UV/m : les pierres
# des pièces ajoutées auront donc la taille apparente de celles du kit.
# `T_RoundTiles` (module `Roof_Dormer_RoundTile`) : 2,054 UV sur 1,92 m en U,
# 0,806 UV sur ~2,4 m de pente en V. `T_WoodTrim` (`Roof_FrontSupports`) :
# 3,597 UV sur 5,49 m, bande V de 0,788.
#
# PIÈGE : `T_WoodTrim` et `T_RoundTiles` sont des TRIM SHEETS directionnels —
# une projection boîte libre y traverse les bandes et raye la matière. Leur V
# est donc REPLIÉ dans une bande mesurée. La pierre, elle, se répète sans
# couture (le kit lui-même monte à v = 1,423) : aucun repli.
#
# Projection boîte déterministe par face selon l'axe dominant de la normale :
# aucun `bpy.ops`, aucun contexte éditeur, aucun `smart_project` dont le
# résultat dépendrait de la version de Blender.
#
#   (echelle_u, echelle_v, bande_min, bande_etendue)   bande None = pas de repli
PROJECTION_UV = {
    0: (0.65, 0.65, 0.02, 0.28),    # IDX_BOIS      — T_WoodTrim
    1: (1.05, 0.34, 0.00, 0.80),    # IDX_TUILES    — T_RoundTiles
    2: (0.65, 0.65, 0.02, 0.28),    # IDX_CASSURE   — T_WoodTrim (cœur clair)
    3: (0.48, 0.48, None, None),    # IDX_PIERRE    — T_UnevenBrick / T_RockTrim
}


def deplier_boite(bm):
    """Pose UV0 sur toutes les faces, par projection boîte.

    L'axe de projection est celui où la normale de la face est la plus forte :
    une face verticale reçoit sa hauteur réelle en V, une face horizontale
    reçoit son plan. Les mètres deviennent des tuiles à l'échelle du kit.
    """
    couche = bm.loops.layers.uv.verify()
    for face in bm.faces:
        eu, ev, bande_min, bande_etendue = PROJECTION_UV.get(
            face.material_index, (0.48, 0.48, None, None))
        n = face.normal
        ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
        for boucle in face.loops:
            co = boucle.vert.co
            if az >= ax and az >= ay:
                u, v = co.x, co.y          # face horizontale
            elif ax >= ay:
                u, v = co.y, co.z          # face regardant X
            else:
                u, v = co.x, co.z          # face regardant Y
            u *= eu
            v *= ev
            if bande_min is not None:
                # Repli dans la bande du trim sheet : `math.fmod` garde le
                # signe, on passe donc par la partie fractionnaire positive.
                v = bande_min + (v % bande_etendue)
            boucle[couche].uv = (u, v)


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


# ---------------------------------------------------------------------------
# Briques de construction bmesh
# ---------------------------------------------------------------------------
def _graine(x):
    """Petit bruit déterministe sans dépendance : sin d'entiers."""
    return math.sin(x * 12.9898) * 0.5


def poutre(bm, depart, arrivee, largeur, hauteur, materiau_idx,
           jitter=0.006, roulis=0.0):
    """Une poutre du point `depart` au point `arrivee` (axes Blender),
    section largeur × hauteur perpendiculaire à son axe. Huit sommets,
    six faces — rien de plus. Le léger `jitter` casse le parallélisme
    parfait qui se lit comme une primitive.
    """
    dx = [arrivee[i] - depart[i] for i in range(3)]
    longueur = math.sqrt(sum(c * c for c in dx))
    axe = [c / longueur for c in dx]
    # Repère orthogonal : `cote` horizontal, `haut` le plus vertical possible.
    if abs(axe[2]) < 0.99:
        cote = [-axe[1], axe[0], 0.0]
        norme = math.sqrt(sum(c * c for c in cote)) or 1.0
        cote = [c / norme for c in cote]
    else:
        cote = [1.0, 0.0, 0.0]
    haut = [axe[1] * cote[2] - axe[2] * cote[1],
            axe[2] * cote[0] - axe[0] * cote[2],
            axe[0] * cote[1] - axe[1] * cote[0]]
    if roulis:
        c, s = math.cos(roulis), math.sin(roulis)
        cote, haut = ([c * cote[i] + s * haut[i] for i in range(3)],
                      [-s * cote[i] + c * haut[i] for i in range(3)])
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
    a = sommets[:4]
    b = sommets[4:]
    faces = [bm.faces.new((a[0], a[1], a[2], a[3])),
             bm.faces.new((b[3], b[2], b[1], b[0]))]
    for i in range(4):
        j = (i + 1) % 4
        faces.append(bm.faces.new((a[i], b[i], b[j], a[j])))
    for f in faces:
        f.material_index = materiau_idx
    return faces


def echarde(bm, base, direction, longueur, largeur, materiau_idx):
    """Un coin déchiré : quatre sommets de base, une pointe — le bout d'une
    pièce ROMPUE, en bois clair, jamais une coupe de scie."""
    perp = [-direction[1], direction[0], 0.0]
    n = math.sqrt(sum(c * c for c in perp)) or 1.0
    perp = [c / n for c in perp]
    b0 = bm.verts.new((base[0] + perp[0] * largeur * 0.5,
                       base[1] + perp[1] * largeur * 0.5, base[2]))
    b1 = bm.verts.new((base[0] - perp[0] * largeur * 0.5,
                       base[1] - perp[1] * largeur * 0.5, base[2]))
    b2 = bm.verts.new((base[0], base[1], base[2] + largeur * 0.6))
    pointe = bm.verts.new((base[0] + direction[0] * longueur,
                           base[1] + direction[1] * longueur,
                           base[2] + direction[2] * longueur))
    for tri in ((b0, b1, pointe), (b1, b2, pointe), (b2, b0, pointe),
                (b0, b2, b1)):
        f = bm.faces.new(tri)
        f.material_index = materiau_idx
    return 4


# ---------------------------------------------------------------------------
# SM_Farm_Truss — la charpente rompue, d'un seul trait
# ---------------------------------------------------------------------------
def charpente(bm):
    z_faite = FAITE_Z + CHEVRON_SECTION[1] * 0.5

    # Sablières : elles POSENT la charpente sur l'arase des murs. Ouest
    # (-X) entière ; est (+X) rompue — il n'en reste que le tronçon nord,
    # comme le mur en dessous (le segment sud du mur est n'existe plus).
    poutre(bm, (-3.0, -3.15, SABLIERE_SECTION[1] * 0.5),
           (-3.0, 3.15, SABLIERE_SECTION[1] * 0.5),
           SABLIERE_SECTION[0], SABLIERE_SECTION[1], IDX_BOIS)
    poutre(bm, (3.0, 0.4, SABLIERE_SECTION[1] * 0.5),
           (3.0, 3.15, SABLIERE_SECTION[1] * 0.5),
           SABLIERE_SECTION[0], SABLIERE_SECTION[1], IDX_BOIS)
    echarde(bm, (3.0, 0.4, SABLIERE_SECTION[1] * 0.5), (0.0, -1.0, 0.05),
            0.34, SABLIERE_SECTION[0], IDX_CASSURE)

    # Faîtière en DEUX tronçons : le nord tient, le sud a plié — son bout
    # libre plonge de 0,55 m vers le vide laissé par le mur est.
    poutre(bm, (0.0, 0.55, z_faite), (0.0, 3.35, z_faite),
           FAITIERE_SECTION[0], FAITIERE_SECTION[1], IDX_BOIS)
    poutre(bm, (0.0, 0.30, z_faite - 0.04), (0.12, -3.05, z_faite - 0.58),
           FAITIERE_SECTION[0] * 0.95, FAITIERE_SECTION[1], IDX_BOIS,
           roulis=math.radians(9.0))
    # Les deux bouts de la rupture, cœur clair déchiré.
    echarde(bm, (0.0, 0.55, z_faite + 0.03), (0.05, -1.0, -0.12), 0.42,
            0.16, IDX_CASSURE)
    echarde(bm, (0.0, 0.30, z_faite - 0.02), (-0.03, 1.0, 0.10), 0.36,
            0.15, IDX_CASSURE)

    # Chevrons SOLIDAIRES : chaque paire part du faîte et descend à
    # l'arase. Côté nord (faîtière intacte) : trois paires complètes.
    for i, y in enumerate((0.9, 1.9, 2.9)):
        for cote in (-1, 1):
            devers = _graine(i * 3.1 + cote) * 0.05
            poutre(bm, (cote * 0.06, y + devers, z_faite - 0.02),
                   (cote * DEMI_PORTEE, y + devers, CHEVRON_SECTION[1] * 0.5),
                   CHEVRON_SECTION[0], CHEVRON_SECTION[1], IDX_BOIS)
    # Côté sud : la faîtière a plié — les chevrons ouest suivent sa chute
    # (toujours ACCROCHÉS à elle : même point de départ), les chevrons est
    # sont rompus court, bout déchiré.
    for i, y in enumerate((-0.6, -1.7, -2.7)):
        t = (0.30 - y) / 3.35          # position le long du tronçon plié
        z_depart = (z_faite - 0.04) - 0.54 * t
        x_depart = 0.12 * t
        poutre(bm, (x_depart - 0.06, y, z_depart),
               (-DEMI_PORTEE, y, CHEVRON_SECTION[1] * 0.5),
               CHEVRON_SECTION[0], CHEVRON_SECTION[1], IDX_BOIS)
        if i != 1:
            longueur_rompue = 1.15 + _graine(y) * 0.3
            pente = (z_depart - CHEVRON_SECTION[1] * 0.5) / DEMI_PORTEE
            poutre(bm, (x_depart + 0.06, y, z_depart),
                   (x_depart + longueur_rompue, y,
                    z_depart - pente * longueur_rompue - 0.10),
                   CHEVRON_SECTION[0], CHEVRON_SECTION[1], IDX_BOIS)
            echarde(bm, (x_depart + longueur_rompue, y,
                         z_depart - pente * longueur_rompue - 0.10),
                    (1.0, 0.0, -0.25), 0.30, CHEVRON_SECTION[0], IDX_CASSURE)

    # Un entrait au nord : la triangulation qui dit « charpente », pas
    # « planches posées ».
    poutre(bm, (-2.1, 1.9, 0.44), (2.1, 1.9, 0.44), 0.10, 0.13, IDX_BOIS)


# ---------------------------------------------------------------------------
# Pans de couverture — rangées de tuiles à recouvrement
# ---------------------------------------------------------------------------
def pan(bm, profil, longueur, rangs, materiau_idx):
    """Un pan de toiture le long d'un `profil` [(s, z), …] : `s` est
    l'abscisse curviligne selon Blender X, `z` la hauteur. Chaque rang est
    une planche de tuiles qui RECOUVRE la précédente de 8 cm — c'est le
    recouvrement qui fait lire « couverture », pas une plaque.
    """
    total = profil[-1][0]
    pas = total / rangs
    for r in range(rangs):
        s0 = r * pas
        s1 = s0 + pas + (0.08 if r < rangs - 1 else 0.0)
        # hauteur du profil aux deux abscisses (interpolation linéaire)
        def z_de(s):
            for i in range(len(profil) - 1):
                a, b = profil[i], profil[i + 1]
                if s <= b[0] or i == len(profil) - 2:
                    if b[0] == a[0]:
                        return a[1]
                    t = max(0.0, min(1.0, (s - a[0]) / (b[0] - a[0])))
                    return a[1] + (b[1] - a[1]) * t
            return profil[-1][1]
        releve = 0.030 + r * 0.012      # chaque rang chevauche le précédent
        y0 = -longueur * 0.5 + abs(_graine(r * 1.7)) * 0.12
        y1 = longueur * 0.5 - abs(_graine(r * 2.9)) * 0.12
        epaisseur = 0.055
        coins_bas = [(s0, y0, z_de(s0) + releve), (s1, y0, z_de(s1) + releve),
                     (s1, y1, z_de(s1) + releve), (s0, y1, z_de(s0) + releve)]
        bas = [bm.verts.new(p) for p in coins_bas]
        haut = [bm.verts.new((p[0], p[1], p[2] + epaisseur))
                for p in coins_bas]
        faces = [bm.faces.new(tuple(reversed(bas))), bm.faces.new(tuple(haut))]
        for i in range(4):
            j = (i + 1) % 4
            faces.append(bm.faces.new((bas[i], bas[j], haut[j], haut[i])))
        for f in faces:
            f.material_index = materiau_idx
        # Trois liteaux sous le rang 0 seulement (le dessous se voit du sol
        # par le trou du toit).
        if r == 0:
            for y in (y0 + 0.5, 0.0, y1 - 0.5):
                poutre(bm, (0.02, y, z_de(0.02) + 0.032),
                       (total - 0.02, y, z_de(total - 0.02) + 0.032),
                       0.07, 0.06, IDX_BOIS)


def pan_intact(bm):
    # À PLAT : c'est le LIEU qui le pose à 22° sur les chevrons. Un pan
    # exporté déjà penché aurait une AABB diagonale et une assise fausse.
    pan(bm, [(0.0, 0.0), (PAN_PENTE_M, 0.0)], PAN_LONG_M, PAN_RANGS,
        IDX_TUILES)


def pan_tombe(bm):
    # PLIÉ : un segment couché (glissé au sol), un segment relevé contre le
    # mur. La géométrie PORTE la chute — le lieu n'a plus qu'à le poser.
    pan(bm, [(0.0, 0.0), (1.5, 0.22), (3.15, 2.05)], 2.6, 4, IDX_TUILES)
    # Deux tuiles échappées au pied du pli.
    for i, (x, y) in enumerate(((0.7, -1.55), (2.0, 1.5))):
        poutre(bm, (x - 0.22, y, 0.07), (x + 0.22, y + 0.1, 0.09),
               0.34, 0.05, IDX_TUILES, roulis=_graine(i) * 0.35)


def gravats(bm, graine, etendue):
    """Un tas fusionné : éclats de tuiles et bouts de chevrons, jamais un
    semis de cubes réguliers."""
    n = 9
    for i in range(n):
        angle = i * 2.399 + graine          # angle d'or : pas d'alignement
        rayon = etendue * (0.25 + 0.75 * abs(_graine(i * 1.3 + graine)))
        x = math.cos(angle) * rayon
        y = math.sin(angle) * rayon * 0.8
        taille = 0.22 + abs(_graine(i * 2.1 + graine)) * 0.30
        z = taille * 0.18
        if i % 3 == 0:
            poutre(bm, (x - taille, y, z), (x + taille, y + 0.15, z + 0.05),
                   0.11, 0.10, IDX_BOIS, roulis=_graine(i) * 0.9)
        else:
            poutre(bm, (x - taille * 0.7, y - 0.05, z),
                   (x + taille * 0.7, y + 0.08, z + 0.03),
                   taille * 1.1, 0.06, IDX_TUILES, roulis=_graine(i + 9) * 0.7)
    # Un chevron cassé émerge du tas — la cause au milieu des conséquences.
    poutre(bm, (-etendue * 0.5, 0.1, 0.05), (etendue * 0.7, -0.2, 0.55),
           CHEVRON_SECTION[0], CHEVRON_SECTION[1], IDX_BOIS)
    echarde(bm, (etendue * 0.7, -0.2, 0.55), (0.8, -0.3, 0.4), 0.26,
            CHEVRON_SECTION[0], IDX_CASSURE)


# ---------------------------------------------------------------------------
# R2B.1 — maçonnerie : prisme, gradins, moellons
# ---------------------------------------------------------------------------
def prisme(bm, contour, y0, y1, materiau_idx):
    """Extrude un contour du plan XZ le long de Y, de `y0` à `y1`.

    Le contour est une liste [(x, z), ...] parcourue dans l'ordre. Chaque
    pièce de maçonnerie passe par ici : c'est ce qui garantit qu'aucune n'est
    un plan. Deux faces n-gon (avant/arrière) plus un quad par arête.
    """
    avant = [bm.verts.new((x, y0, z)) for x, z in contour]
    arriere = [bm.verts.new((x, y1, z)) for x, z in contour]
    faces = [bm.faces.new(tuple(avant)), bm.faces.new(tuple(reversed(arriere)))]
    n = len(contour)
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((avant[i], avant[j], arriere[j], arriere[i])))
    for f in faces:
        f.material_index = materiau_idx
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


def _gradins(x_depart, x_fin, z_depart, z_fin):
    """Le profil d'un ARRACHEMENT de maçonnerie : des marches d'une assise.

    Une pierre se rompt par lits de pose. Une diagonale lisse se lit comme une
    coupe, une suite de marches se lit comme un mur qui s'est écroulé. Rend la
    liste des points (x, z) du départ à l'arrivée, marche après marche.
    """
    marches = max(1, int(round(abs(z_depart - z_fin) / ASSISE_H)))
    points = []
    for i in range(marches):
        t0 = float(i) / marches
        t1 = float(i + 1) / marches
        x0 = x_depart + (x_fin - x_depart) * t0
        x1 = x_depart + (x_fin - x_depart) * t1
        z_haut = z_depart + (z_fin - z_depart) * t0
        z_bas = z_depart + (z_fin - z_depart) * t1
        # irrégularité : une marche n'a jamais exactement la longueur voisine
        x1 += _graine(i * 5.1) * 0.16
        points.append((x0, z_haut))
        points.append((x1, z_haut))   # la marche, horizontale
        points.append((x1, z_bas))    # la chute d'une assise
    return points


def pignon_rompu(bm):
    """Le pignon NORD : il monte au faîte, puis s'arrache vers l'est.

    C'est la RUPTURE MAJEURE demandée. Sans lui, les murs s'arrêtent tous à
    l'arase et le contour se lit « rectangle + chapeau ».

    Le rampant ouest est intact — c'est le côté que la charpente porte encore
    et que le pan de couverture recouvre. Le rampant est est emporté sur
    `PIGNON_ARRACHE` de sa longueur, en gradins d'une assise.
    """
    demi = DEMI_PORTEE
    faite = FAITE_Z
    pied = PIGNON_PIED_Z
    # Le pignon commence 0,55 m SOUS l'arase : ces assises-là sont le mur.
    contour = [(-demi - 0.05, 0.0), (-demi - 0.05, pied + 0.26)]
    # rampant ouest, en trois ressauts de taille (jamais une droite parfaite)
    for i, t in enumerate((0.34, 0.68, 1.0)):
        x = -demi - 0.05 + (demi + 0.05) * t
        z = pied + 0.26 + (faite - 0.26) * t + _graine(i * 2.7) * 0.05
        contour.append((x, z))
    # arrachement vers l'est
    x_fin = demi * (1.0 - PIGNON_ARRACHE)
    if PIGNON_ARRACHE > 0.001:
        contour.extend([(x, z + pied)
                        for x, z in _gradins(0.0, x_fin, faite, 0.0)])
        contour.append((x_fin + _graine(9.1) * 0.10, pied))
    else:
        # SABOTAGE / pignon intact : le rampant est redescend d'un trait et la
        # silhouette redevient un triangle symétrique.
        contour.append((demi + 0.05, pied + 0.26))
        contour.append((demi + 0.05, pied))
    # BORD BAS EN DENTS D'ASSISE : une plaque posée a une arête basse droite,
    # un mur arraché n'en a pas. C'est ce qui empêche la jonction avec le
    # module de kit d'être une ligne horizontale continue.
    x_est = x_fin + _graine(9.1) * 0.10
    x_ouest = -demi - 0.05
    dents = 7
    z_dent = 0.20
    contour.append((x_est, z_dent))
    for k in range(dents):
        t = float(k + 1) / dents
        x = x_est + (x_ouest - x_est) * t + _graine(k * 3.7) * 0.06
        if k == dents - 1:
            x = x_ouest
        suivant = 0.04 if z_dent > 0.12 else 0.20
        contour.append((x, z_dent))      # la marche, horizontale
        contour.append((x, suivant))     # la chute d'une assise
        z_dent = suivant
    prisme(bm, contour, PIGNON_Y_DEDANS, 0.0, IDX_PIERRE)
    # Corniche d'égout côté ouest : la pierre plate qui reçoit la couverture.
    # Corniche d'égout ramenée DANS l'épaisseur (elle débordait de 26 cm) :
    # deux cours de pierre plate dans le plan du parement, pas deux bandeaux
    # en console.
    poutre(bm, (-demi - 0.14, PIGNON_Y_DEDANS + 0.08, pied + 0.13),
           (-demi * 0.42, PIGNON_Y_DEDANS + 0.08, pied + 0.62),
           0.16, 0.14, IDX_PIERRE)
    poutre(bm, (-demi - 0.14, -0.08, pied + 0.13),
           (-demi * 0.42, -0.08, pied + 0.62),
           0.16, 0.14, IDX_PIERRE)
    # RELIEF DE PAREMENT, ajouté après capture : vu du nord, le pignon était
    # un triangle d'un seul tenant, sans une arête pour accrocher la lumière —
    # un aplat de plus, exactement le défaut qu'il devait corriger. Ces
    # moellons saillants lui donnent les ombres portées qui manquaient, et
    # rappellent l'appareillage du mur qu'il coiffe.
    for i, (x, z, t) in enumerate(((-2.62, 0.18, 0.20), (-2.05, 0.44, 0.17),
                                   (-1.44, 0.66, 0.19), (-0.82, 0.90, 0.16),
                                   (-2.30, 0.72, 0.15), (-1.10, 0.28, 0.18),
                                   (-0.34, 1.06, 0.14))):
        moellon(bm, (x + _graine(i * 1.7) * 0.10, PIGNON_RELIEF_Y, z + pied),
                (t * 1.7, 0.05, t), 30.0 + i * 2, IDX_PIERRE)

    # Quatre pierres descellées, encore accrochées au bord de la cassure : la
    # rupture est RÉCENTE, elle n'est pas nettoyée.
    for i, (x, z, t) in enumerate(((0.30, 0.92, 0.20), (0.86, 0.66, 0.17),
                                   (1.44, 0.40, 0.19), (1.92, 0.14, 0.16))):
        moellon(bm, (x + _graine(i) * 0.12, -0.17, z + pied),
                (t * 1.5, 0.26, t), 4.0 + i, IDX_PIERRE)


def moignon_est(bm):
    """Ce qui reste debout du mur EST : une arase brisée en gradins.

    AVANT : le mur est n'avait que deux modules pleine hauteur et un vide de
    2,00 m — un trou net entre deux murs pleins, pas un arrachement. Ce
    moignon donne à la brèche sa forme d'écroulement, et casse la ligne
    d'arase par le BAS pendant que le pignon la casse par le HAUT.

    La pièce court selon Blender Y (donc Godot Z, la profondeur du bâtiment)
    et son épaisseur est selon X.
    """
    contour = [(-1.0, 0.0), (-1.0, MOIGNON_H_HAUTE)]
    contour.extend(_gradins(-1.0, 0.72, MOIGNON_H_HAUTE, MOIGNON_H_BASSE))
    contour.append((0.98, MOIGNON_H_BASSE - 0.10))
    contour.append((0.98, 0.0))
    # Extrudé selon Y : le contour vit dans le plan (Y, Z) une fois posé, on
    # le construit dans (X, Z) puis on l'étire en Y sur l'épaisseur du mur.
    prisme(bm, contour, -EPAISSEUR_MUR * 0.5, EPAISSEUR_MUR * 0.5, IDX_PIERRE)
    # Trois pierres d'angle saillantes : le chaînage arraché du mur voisin.
    for i, (x, z) in enumerate(((-1.02, 0.28), (-1.02, 0.72), (0.86, 0.20))):
        moellon(bm, (x, _graine(i * 2.1) * 0.10, z),
                (0.30, EPAISSEUR_MUR * 0.95, 0.22), 11.0 + i, IDX_PIERRE)


def talus_moellons(bm, angle_zero=1.7, etendue=1.55, n=14, decalage=0.0,
                   bois=True):
    """La matière du mur écroulé, au pied de la brèche.

    Sans elle, un mur disparaît sans laisser de trace — le défaut le plus
    coûteux d'une ruine : on lit « inachevé » et non « effondré ». Le talus
    est plus haut contre le mur et s'étale en s'éloignant, comme un éboulis.
    """
    for i in range(n):
        angle = i * 2.399 + angle_zero    # angle d'or : aucun alignement
        rayon = etendue * (0.18 + 0.82 * abs(_graine(i * 1.7 + 0.3 + decalage)))
        x = math.cos(angle) * rayon
        y = math.sin(angle) * rayon * 0.62
        # profil d'éboulis : haut près de l'origine (le pied du mur), bas loin
        # Profil d'éboulis, et une exigence de composition : le talus doit
        # COUVRIR le soubassement mis à nu par la brèche, sinon on lit une
        # « fondation découverte » au lieu d'un mur écroulé.
        proche = max(0.0, 1.0 - rayon / etendue)
        taille = 0.24 + abs(_graine(i * 2.3 + decalage)) * 0.26
        z = 0.08 + proche * 0.66 + abs(_graine(i * 3.1 + decalage)) * 0.12
        moellon(bm, (x, y, z), (taille * 1.35, taille * 1.1, taille),
                20.0 + i + decalage, IDX_PIERRE)
    if not bois:
        return
    # Deux bouts de sablière tombés avec le mur : la charpente a suivi.
    poutre(bm, (-1.25, -0.42, 0.12), (0.55, -0.10, 0.30),
           0.15, 0.13, IDX_BOIS, roulis=0.4)
    echarde(bm, (0.55, -0.10, 0.30), (1.0, 0.15, 0.10), 0.30, 0.15,
            IDX_CASSURE)


# R2B.2 — LE MUR NORD DOIT MANQUER.
#
# Mesuré le 2026-08-19 : la ligne d'arase du SEUL mur nord était plate, écart-
# type 0,029 m sur 15 colonnes, point bas 3,00 m. Le filet R2B.1 ne l'attrapait
# pas — il mesure la dispersion sur TOUTE la maçonnerie, et le pignon suffisait
# à la faire passer pendant que le mur restait un rectangle intact.
#
# La réponse n'est PAS une décoration posée sur le mur : le lieu RETIRE le
# module de kit le plus à l'est et l'angle nord-est, et met cette pièce à leur
# place. Un module en moins, pas un ornement en plus. L'arrachement continue
# celui du mur est autour du même angle : une seule histoire d'effondrement.
BRECHE_NORD_DEMI_L = 1.25
BRECHE_NORD_H_HAUTE = 3.12   # l'arase intacte, mesurée sur le module de kit
BRECHE_NORD_H_BASSE = 1.15


def breche_nord(bm):
    """Le pan de mur nord ROMPU : arase pleine à l'ouest, arrachée à l'est."""
    demi = BRECHE_NORD_DEMI_L
    epais = 0.205
    contour = [(-demi, 0.0), (-demi, BRECHE_NORD_H_HAUTE)]
    contour.extend(_gradins(-demi, 0.95, BRECHE_NORD_H_HAUTE,
                            BRECHE_NORD_H_BASSE))
    contour.append((demi, BRECHE_NORD_H_BASSE - 0.13))
    contour.append((demi, 0.0))
    prisme(bm, contour, -epais, epais, IDX_PIERRE)
    # Chaînage d'angle arraché : les pierres du coin nord-est descellées,
    # encore accrochées, décroissant vers le bas comme un arrachement récent.
    for i, (x, z, t) in enumerate(((demi - 0.06, 0.30, 0.24),
                                   (demi - 0.02, 0.72, 0.21),
                                   (demi - 0.10, 1.06, 0.18))):
        moellon(bm, (x, _graine(i * 2.7) * 0.06, z),
                (t, epais * 1.9, t * 0.9), 51.0 + i, IDX_PIERRE)
    # RELIEF DE PAREMENT côté DEHORS (Blender +y ⇒ Godot -z) : sans lui, le pan
    # neuf est une face lisse à côté d'un module de kit appareillé.
    for i, (x, z, t) in enumerate(((-0.92, 0.42, 0.20), (-0.30, 1.05, 0.17),
                                   (0.34, 1.72, 0.19), (-0.66, 2.28, 0.16),
                                   (0.08, 2.74, 0.15), (-1.02, 1.62, 0.18))):
        moellon(bm, (x + _graine(i * 1.9) * 0.08, epais - 0.02, z),
                (t * 1.6, 0.06, t), 60.0 + i, IDX_PIERRE)
    # Le lit de rupture : deux pierres basculées au sommet de l'arrachement.
    poutre(bm, (0.42, -epais * 0.5, BRECHE_NORD_H_BASSE - 0.02),
           (0.96, epais * 0.4, BRECHE_NORD_H_BASSE + 0.16),
           0.34, 0.20, IDX_PIERRE, roulis=0.28)


def tableaux(bm, hauteur, arrache):
    """Les TABLEAUX d'UNE baie : la tranche que le module de kit n'a pas.

    Mesuré le 2026-08-19 : `Wall_UnevenBrick_Straight` est fait de deux plans
    stricts (brique à Z = 0,000, plâtre à Z = -0,200) sans AUCUNE face de
    chant. Une baie y montre donc deux cartons parallèles, et c'est très
    exactement ce que le lead a nommé « plans visiblement sans épaisseur ».
    Ces jambages rendent au mur son épaisseur là où l'œil la cherche : au bord
    du percement.

    UN objet par baie, chacun centré sur X = 0. Un objet unique portant les
    deux baies figerait leur écart ET leur orientation — or la porte regarde
    le sud et la brèche regarde l'est.

    `arrache` : le jambage droit est rompu à mi-hauteur (brèche) ou entier
    (porte). Une brèche dont les deux bords sont nets se lit comme une
    ouverture voulue, pas comme un mur qui a cédé.
    """
    for cote in (-1.0, 1.0):
        haut = hauteur
        if arrache and cote > 0.0:
            haut = hauteur * 0.52
        contour = [(cote * 0.86 - 0.10, 0.0), (cote * 0.86 + 0.10, 0.0)]
        if arrache and cote > 0.0:
            contour.extend([(cote * 0.86 + 0.10, haut - 0.18),
                            (cote * 0.86 - 0.02, haut - 0.18),
                            (cote * 0.86 - 0.02, haut),
                            (cote * 0.86 - 0.10, haut)])
        else:
            contour.extend([(cote * 0.86 + 0.10, haut),
                            (cote * 0.86 - 0.10, haut)])
        # R2B.2 — LE SIGNE ÉTAIT INVERSÉ, ET C'EST TOUT LE DÉFAUT.
        # R2B.1 extrudait de -0,42 à +0,10 « pour entrer de 42 cm DANS le
        # mur ». Mais l'export Y-up donne `Godot z = -y` : le GLB rendait
        # Z ∈ [-0,10 ; +0,42] et les quatre tableaux SAILLAIENT de 42 cm
        # DEVANT la façade (mesuré sur le GLB le 2026-08-19). Ce sont eux, et
        # eux seuls, qui « bouchent la lecture » de `ferme_seuil` : 7,32 +
        # 5,32 + 2,92 + 1,31 % du cadre, et leur fusion fait tomber le nombre
        # de composantes de 45 à 40 pendant que le total double.
        # Bornes retournées : Blender y ∈ [-0,02 ; +0,42] ⇒ Godot
        # z ∈ [-0,42 ; +0,02]. Deux centimètres de saillie, pas quarante-deux.
        prisme(bm, contour, -0.02, EPAISSEUR_MUR + 0.02, IDX_PIERRE)
        # HARPES : une pierre sur deux déborde dans le mur. Sans elles, le
        # tableau est un bandeau lisse — mesuré sur capture, il se lisait
        # comme une colonne pleine, plus unie que tout ce qui l'entoure.
        for k, z in enumerate((0.28, 0.86, 1.44)):
            if z > haut - 0.15:
                continue
            # Harpes retournées avec le tableau : elles mordent la TRANCHE,
            # côté intérieur du parement, jamais sa face.
            moellon(bm, (cote * 0.86 + cote * 0.10, EPAISSEUR_MUR * 0.5,
                         z + _graine(k * 2.3) * 0.06),
                    (0.30, EPAISSEUR_MUR * 0.62, 0.19), 40.0 + k + cote,
                    IDX_PIERRE)
    # Seuil : la pierre usée du passage, débordante des deux côtés.
    # Le seuil s'enfonce vers l'intérieur (il porte le passage) et affleure
    # dehors : Blender y ∈ [-0,02 ; +0,50] ⇒ Godot z ∈ [-0,50 ; +0,02].
    prisme(bm, [(-0.94, 0.0), (0.94, 0.0), (0.94, 0.15), (-0.94, 0.15)],
           -0.02, EPAISSEUR_MUR + 0.10, IDX_PIERRE)


PLANCHER_Z = 2.35       # hauteur du plancher d'étage disparu


def ossature_interieure(bm):
    """Poteaux et décharges plaqués contre UN mur.

    C'est le remède direct au « presque aucune histoire structurelle visible »
    et à l'intérieur qui se lit comme une coque : le quad de plâtre de 6,00 m²
    est découpé par du bois qui raconte un étage qui n'existe plus.

    L'objet est plaqué en X = 0 et court selon Y ; le lieu l'applique contre
    le mur de son choix par une rotation.
    """
    # Trois poteaux de fruste équarrissage, jamais également espacés.
    for i, y in enumerate((-2.05, -0.15, 1.85)):
        poutre(bm, (0.10, y + _graine(i) * 0.10, 0.0),
               (0.16, y, 2.88), 0.17, 0.15, IDX_BOIS)
    # Deux décharges obliques : la triangulation qui dit « charpenté ».
    for i, y in enumerate((-2.0, 1.80)):
        poutre(bm, (0.14, y, 1.28),
               (0.66, y + (0.52 if i else -0.52), PLANCHER_Z),
               0.12, 0.12, IDX_BOIS)
    # Une lambourde horizontale qui relie les poteaux sous le plancher.
    poutre(bm, (0.16, -2.15, PLANCHER_Z - 0.14),
           (0.20, 1.95, PLANCHER_Z - 0.18), 0.13, 0.16, IDX_BOIS)


def solives_rompues(bm):
    """Les SOLIVES du plancher disparu, rompues net au ras du mur.

    Objet séparé de l'ossature à dessein : un plancher d'étage repose sur
    PLUSIEURS murs, et deux exemplaires du même bloc posés côte à côte se
    liraient comme une répétition. Ici chaque mur reçoit ce qui lui revient —
    des poteaux, ou les bouts de solives que le plancher y avait scellés.

    Leur cœur déchiré porte le seul accent clair de la pièce : c'est lui qui
    dit que la rupture est récente.
    """
    for i, y in enumerate((-1.95, -0.68, 0.58, 1.88)):
        longueur = 0.68 + abs(_graine(i * 4.1)) * 0.46
        chute = _graine(i * 2.9) * 0.09
        poutre(bm, (0.06, y, PLANCHER_Z),
               (0.06 + longueur, y + _graine(i) * 0.06, PLANCHER_Z + chute),
               0.13, 0.19, IDX_BOIS)
        echarde(bm, (0.06 + longueur, y, PLANCHER_Z + chute),
                (1.0, 0.05, -0.35), 0.34, 0.13, IDX_CASSURE)
    # Le corbeau de pierre qui portait la solive maîtresse, resté au mur.
    prisme(bm, [(0.0, PLANCHER_Z - 0.30), (0.34, PLANCHER_Z - 0.24),
                (0.34, PLANCHER_Z - 0.02), (0.0, PLANCHER_Z + 0.02)],
           -0.28, 0.28, IDX_PIERRE)


# ---------------------------------------------------------------------------
# Assemblage
# ---------------------------------------------------------------------------
def objet_depuis(nom, remplir):
    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()
    remplir(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    # UV0 APRÈS le recalcul des normales : la projection choisit son axe
    # d'après la normale de face, une normale retournée déplie à l'envers.
    deplier_boite(bm)
    bm.to_mesh(maillage)
    bm.free()
    # CHAQUE pièce se pose par son point bas : on cale min-Z à 0 ICI, une
    # fois, plutôt que de corriger à la main chaque éclat penché — la
    # troisième retouche du même millimètre est le signal qu'il faut caler
    # à la source. Le garde d'emprise reste : il attrape une pièce dont la
    # LOGIQUE de hauteur est fausse (faîte, portée), pas son arrondi.
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
        objet_depuis("SM_Farm_Truss", charpente),
        objet_depuis("SM_Farm_RoofPan_Intact", pan_intact),
        objet_depuis("SM_Farm_RoofPan_Fallen", pan_tombe),
        objet_depuis("SM_Farm_Debris_A", lambda bm: gravats(bm, 0.4, 0.85)),
        objet_depuis("SM_Farm_Debris_B", lambda bm: gravats(bm, 2.9, 0.65)),
        # R2B.1 — la masse qui manquait.
        objet_depuis("SM_Farm_GableBreak", pignon_rompu),
        objet_depuis("SM_Farm_WallStub_East", moignon_est),
        objet_depuis("SM_Farm_Rubble_Wall", talus_moellons),
        objet_depuis("SM_Farm_Jamb_Door",
                     lambda bm: tableaux(bm, 2.10, False)),
        objet_depuis("SM_Farm_Jamb_Breach",
                     lambda bm: tableaux(bm, 1.72, True)),
        objet_depuis("SM_Farm_InteriorFrame", ossature_interieure),
        objet_depuis("SM_Farm_JoistStubs", solives_rompues),
        # R2B.2 — le manque STRUCTUREL du mur nord, et sa matière au sol.
        objet_depuis("SM_Farm_WallBreak_North", breche_nord),
        objet_depuis("SM_Farm_Rubble_North",
                     lambda bm: talus_moellons(bm, angle_zero=0.9,
                                               etendue=1.35, n=12,
                                               decalage=5.0, bois=False)),
    ]

    total = 0
    for obj in pieces:
        n = tris_de(obj)
        total += n
        (x0, x1), (y0, y1), (z0, z1) = emprise(obj)
        print("[farm_ruins] %-24s %4d tris  X %.2f..%.2f  Y %.2f..%.2f  "
              "Z %.3f..%.2f" % (obj.name, n, x0, x1, y0, y1, z0, z1))
        # BASE À Z≈0 : chaque pièce se pose par son point bas. Une pièce
        # dont la base flotte se poserait faux partout.
        if z0 < -BASE_TOL_DESSOUS or z0 > BASE_TOL_DESSUS:
            print("[farm_ruins] ERREUR: base de %s à Z=%.3f (attendu "
                  "[-%.3f ; %.2f])" % (obj.name, z0, BASE_TOL_DESSOUS,
                                       BASE_TOL_DESSUS))
            return 2

    print("[farm_ruins] total %d triangles (budget %d)" % (total, BUDGET_TRIS))
    if total > BUDGET_TRIS:
        print("[farm_ruins] ERREUR: budget dépassé — le générateur REFUSE "
              "d'enregistrer")
        return 2

    # La charpente couvre la portée des murs (6,0 m à ±0,15) : plus courte,
    # elle flotterait entre les arases ; plus longue, elle les traverserait.
    (tx0, tx1), _, (_, tz1) = emprise(pieces[0])
    if abs((tx1 - tx0) - 2.0 * DEMI_PORTEE) > 0.30:
        print("[farm_ruins] ERREUR: portée de charpente %.2f, attendue %.2f"
              % (tx1 - tx0, 2.0 * DEMI_PORTEE))
        return 2
    if not (1.05 <= tz1 <= 1.55):
        print("[farm_ruins] ERREUR: faîte à %.2f m au-dessus de l'arase "
              "(attendu ~%.2f)" % (tz1, FAITE_Z))
        return 2

    # GARDE R2B.1 — LE PIGNON EST UNE RUPTURE, PAS UN MUR DE PLUS.
    #
    # Deux mesures, prises sur la géométrie et non sur l'intention :
    #   * ASYMÉTRIE — sur un pignon intact, le faîte est au milieu de
    #     l'emprise. Un rampant emporté décale le milieu sans bouger le faîte ;
    #   * GRADINS — une maçonnerie se rompt par lits de pose. Compter les
    #     chutes verticales du profil supérieur, c'est compter les assises
    #     arrachées. Un triangle intact n'en a aucune.
    #
    # Ces deux nombres sont ceux que le filet Godot vérifie à son tour sur le
    # GLB importé. Ici, le générateur REFUSE d'enregistrer un pignon droit.
    pignon = next(o for o in pieces if o.name == "SM_Farm_GableBreak")
    xs = [v.co.x for v in pignon.data.vertices]
    faite_x = max(pignon.data.vertices, key=lambda v: v.co.z).co.x
    milieu = (min(xs) + max(xs)) * 0.5
    demi_emprise = (max(xs) - min(xs)) * 0.5
    asymetrie = abs(faite_x - milieu) / demi_emprise if demi_emprise else 0.0
    profil = {}
    for v in pignon.data.vertices:
        cle = round(v.co.x, 3)
        profil[cle] = max(profil.get(cle, -1e9), v.co.z)
    hauteurs = [profil[k] for k in sorted(profil)]
    gradins = sum(1 for i in range(1, len(hauteurs))
                  if hauteurs[i - 1] - hauteurs[i] >= ASSISE_H * 0.6)
    print("[farm_ruins] pignon : asymetrie %.3f, %d gradin(s) d'arrachement"
          % (asymetrie, gradins))
    if asymetrie < 0.12 or gradins < 3:
        print("[farm_ruins] ERREUR: le pignon n'est pas ROMPU (asymetrie "
              "%.3f < 0.12 ou %d gradin(s) < 3) — un pignon intact est un mur "
              "de plus, pas une rupture de silhouette" % (asymetrie, gradins))
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_Farm_Ruins.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[farm_ruins] source enregistrée -> %s" % sortie)
    print("FIN NOMINALE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
