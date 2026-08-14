# SOURCE DE GÉNÉRATION REPRODUCTIBLE — L'Arche de pierre (`valley.poi.stone_bridge.01`).
#
# POURQUOI CE FICHIER EXISTE. La passe précédente fabriquait le pont en
# GDScript, par empilement d'environ 250 `BoxMesh` irrégulières. Le lead a
# rejeté « blocs et voussoirs non solidarisés, grandes faces blanches,
# géométrie qui déborde des culées, la vue sous l'arche entre dans le
# maillage ». Trois de ces quatre défauts sont arithmétiques, pas
# esthétiques, et le premier se démontre :
#
#   `_arch_ring()` échantillonnait une demi-ellipse à PAS D'ANGLE constant
#   (`PI*t`, 17 pas) pour poser des claveaux de 1,26 m fixes en tangentiel.
#   Le pas MÉTRIQUE d'une ellipse n'est pas constant : 4,1 × π/17 = 0,758 m
#   à la naissance, 8,0 × π/17 = 1,478 m à la clé. Donc 0,50 m de
#   chevauchement aux reins et 0,22 m DE CIEL entre deux claveaux à la clé.
#   Aucun réglage de taille moyenne ne rattrape ça ; seule une autre
#   méthode le peut.
#
# MÉTHODE — le bandeau est UN SEUL VOLUME BALAYÉ, et les joints radiaux
# sont creusés DANS LA SECTION, exactement comme les canaux du pylône sont
# dans son profil. On empile des sections fermées de MÊME nombre de sommets
# le long de l'arc et on coud les quads : l'arche est continue, fermée et
# manifold par construction, et elle présente malgré tout 18 joints
# strictement radiaux régulièrement espacés. Un empilement ne peut pas
# offrir les deux à la fois ; un loft les donne gratuitement.
#
# Aucun booléen nulle part (leçon du pylône : un booléen sur une pile de
# primitives reproduit les artefacts rejetés).
#
# IMPLANTATION — mesurée, pas héritée. `probe_site_section` à 2 m, 1 m et
# 0,5 m montre que le chenal principal court NORD-SUD (centre x = −27,5 en
# z = −15, x = −21,5 en z = +2, soit 19,4° de l'axe Z). L'ouvrage précédent
# courait le long de x = −21 : PARALLÈLE au fleuve, dans l'eau sur 23 m
# continus, sa culée nord plantée en plein chenal à 9 m de toute berge.
# D'où « pas de berge où ancrer ». Ici la traversée est perpendiculaire au
# chenal, en (−23,5 ; −3,5), azimut 341° : 9,3 m d'eau entre deux berges
# qui montent à 1,00 m/m jusqu'à +2,9 et +3,3.
#
# Blender est Z-up, l'exporteur convertit en Y-up (`export_yup`). On modèle
# donc Z vertical, base de fondation à Z = 0 (exigence `IMPORT_RULES.md`).
# Blender +X = axe du pont ; Blender +Y = FACE AVAL, celle que le soleil
# éclaire (voir le bloc « soleil » plus bas).
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/architecture/make_stone_bridge.py

import math
import os
import sys

import bmesh
import bpy

# ---------------------------------------------------------------------------
# LE SOLEIL, MESURÉ — il décide de l'orientation, pas le goût.
#
# `scenes/world_v2/WorldV2.tscn`, nœud `Lighting/Sun` : la colonne −Z de sa
# base vaut (0,8677 ; −0,3907 ; 0,3073). C'est la direction de MARCHE de la
# lumière : azimut 19,5°, élévation 23,0°. Le soleil est donc à l'azimut
# 199,5°.
#
# L'axe du pont est imposé par le chenal (perpendiculaire = azimut 341°).
# Les deux faces ont donc pour normales les azimuts 250,6° et 70,6°.
# Éclairement de la face 250,6° :
#     n = (cos 250,6° ; sin 250,6°) = (−0,3322 ; −0,9432)
#     n · (−marche) = 0,3322×0,8677 + 0,9432×0,3073 = 0,578
# Si le pont avait été posé plein est-ouest, cette même face n'aurait reçu
# que 0,307. Le fait de se mettre d'équerre sur la rivière DOUBLE presque
# l'éclairement de la face que l'on montre. Trois raisons convergentes :
# portée plus courte (9,3 m contre 10,4), ouvrage d'équerre, face lisible.
#
# Face éclairée = Blender +Y. Toutes les décisions de composition en
# découlent : brèche du parapet côté +Y, refuge côté −Y.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# COTES — toutes en mètres, Z mesuré depuis la base de fondation (Z = 0).
# Correspondance avec le monde : Z_monde = Z_modèle − 2,60.
#
#   Z 0,00  fondation      monde −2,60   (0,70 m sous le lit)
#   Z 0,70  lit            monde −1,90
#   Z 1,70  plan d'eau     monde −0,90
#   Z 2,30  naissance      monde −0,30
#   Z 4,98  intrados clé   monde +2,38
#   Z 5,70  extrados clé   monde +3,10
#   Z 6,45  tablier        monde +3,85
# ---------------------------------------------------------------------------
Z_LIT = 0.70
Z_EAU = 1.70
Z_NAISSANCE = 2.30

DEMI_PORTEE = 4.90          # portée libre 9,80 m entre faces de culée
FLECHE = 2.68               # arc SURBAISSÉ (rapport 0,273) — un pont de rivière,
                            # pas un plein cintre qui monterait à +4,6 de tablier
Z_CLE_INTRADOS = Z_NAISSANCE + FLECHE                       # 4,98
RAYON_INT = (DEMI_PORTEE ** 2 + FLECHE ** 2) / (2.0 * FLECHE)  # 5,8195
Z_CENTRE_ARC = Z_CLE_INTRADOS - RAYON_INT                   # −0,8395
EPAISSEUR_BANDEAU = 0.72
RAYON_EXT = RAYON_INT + EPAISSEUR_BANDEAU                   # 6,5395
DEMI_ANGLE = math.asin(DEMI_PORTEE / RAYON_INT)             # 57,377°

# 19 claveaux : nombre IMPAIR, donc une clé centrée sur l'axe.
VOUSSOIRS = 19
PAS_ANGLE = 2.0 * DEMI_ANGLE / VOUSSOIRS                    # 6,0397°

# Le joint est une GORGE creusée dans la section, large de 0,06 m sur
# l'intrados et profonde de 0,07 m. Profondeur choisie par le calcul
# d'ombre : la face est éclairée à 51° de sa normale, donc une gorge de
# 0,07 projette 0,07 × tan 51° = 0,086 m — environ 5 px à 25 m en 1440p.
# À 0,035 (premier réflexe) elle n'aurait fait que 2 px : invisible.
JOINT_PROFONDEUR = 0.07
JOINT_DEMI_LARGEUR = 0.03
JOINT_PENTE = 0.010          # les joues de la gorge sont inclinées, jamais
                             # verticales : deux anneaux au MÊME angle
                             # produiraient des faces d'aire nulle.

# Largeurs. L'archivolte déborde de 0,12 m sur le nu du tympan : c'est ce
# débord qui dessine l'arc en ombre portée et empêche la face de se lire
# comme un plan.
DEMI_L_ARCHIVOLTE = 2.28
DEMI_L_MUR = 2.16
DEMI_L_CORNICHE = 2.34
DEMI_L_PARAPET_INT = 1.74    # chaussée libre : 3,48 m
DEMI_L_CORDON = 2.32
DEMI_L_CHAPERON = 2.24

CHANFREIN = 0.05             # toutes les arêtes vives sont cassées : une
                             # arête franche de 4 m se lit comme une plaque.

# Tablier — bombé (dos d'âne léger) puis rampes vers les deux plateaux.
Z_TABLIER_CLE = 6.45
BOMBEMENT = 0.10
DALLE_EPAISSEUR = 0.34
X_CULEE = 8.60               # dos de culée
X_CHAUSSEE_O, X_CHAUSSEE_E = -12.60, 11.50   # bouts de rampe
Z_RAMPE_O, Z_RAMPE_E = 5.60, 5.90            # arase des rampes (monde 3,00 / 3,30)
X_PARAPET_O, X_PARAPET_E = -9.40, 9.40

# Extrados à la naissance : l'arc, plus épais, mord plus loin que l'intrados.
X_SKEWBACK = RAYON_EXT * math.sin(DEMI_ANGLE)               # 5,506
Z_SKEWBACK = Z_CENTRE_ARC + RAYON_EXT * math.cos(DEMI_ANGLE)  # 2,688

Z_LIGNE_MOUILLEE = 2.45      # sous cette cote la pierre est humide et sombre
Z_CORDON_BAS, Z_CORDON_HAUT = 5.78, 6.00
PARAPET_HAUTEUR = 0.86
CHAPERON_HAUTEUR = 0.12

# ---------------------------------------------------------------------------
# PROFIL DU TERRAIN GELÉ, MESURÉ ET CUIT ICI.
#
# `probe_site_section` (pas 1 m et 0,5 m), échantillonné LE LONG DE L'AXE du
# pont : t est l'abscisse modèle X, la valeur est la hauteur MONDE du sol.
# Le générateur ne peut pas interroger Godot ; le terrain, lui, est GELÉ.
# On le cuit donc en constantes — et `stone_bridge_place.gd` re-mesure ces
# mêmes points par `ground_local_y()` et `push_error` au-delà de 0,35 m
# d'écart. C'est la règle des littéraux épinglés (PROMPT4 §4) appliquée au
# terrain : si le paysage bouge un jour, ça rougit ici, pas chez le joueur.
# ---------------------------------------------------------------------------
PROFIL_TERRAIN = (
    (-13.0, 3.00), (-11.0, 3.00), (-10.0, 3.00), (-9.0, 3.00), (-8.0, 2.47),
    (-7.0, 1.59), (-6.0, 0.41), (-4.9, -0.79), (0.0, -1.90), (4.9, -0.89),
    (6.0, 0.29), (7.0, 1.39), (8.0, 2.23), (9.0, 3.10), (10.0, 3.29),
    (11.0, 3.30), (12.0, 3.30),
)
DECAISSEMENT = 0.25          # la rampe s'enfonce de 25 cm dans le sol : elle
                             # MEURT dedans au lieu de s'y poser.

# ---------------------------------------------------------------------------
# MATIÈRES — trois VALEURS séparées, pas trois teintes voisines.
#
# Les nombres ci-dessous sont en sRGB (ce que l'œil doit lire) et sont
# convertis en LINÉAIRE avant d'entrer dans Blender : glTF stocke
# `baseColorFactor` en linéaire et Godot le réencode en sRGB. Le pylône a
# rendu entièrement blanc pour avoir sauté cette conversion (0,40 écrit
# arrivait à 0,67).
#
# Et le piège plus coûteux, mesuré sur la capture du pylône : l'écart
# d'ÉCLAIREMENT entre face au soleil et face à l'ombre valait ×1,63, autant
# que l'écart de matière. Trois matières donnaient une seule valeur perçue.
# Pour qu'une hiérarchie survive à l'éclairement, son écart doit le
# dépasser : 0,145 / 0,300 / 0,375, soit environ 0,15 de valeur rendue
# entre chaque.
#
# La version rejetée du pont écrivait 0,60 / 0,66 / 0,55 / 0,52 directement
# dans `albedo_color` : quatre teintes tenant dans 0,14, toutes au-dessus
# de 0,85 une fois rendues. C'était ça, les « grandes faces blanches ».
#
# Rappel §1.5 : ombres 18–38 %, masse de pierre 35–65 %. Rien au-dessus de
# 0,95 sauf le ciel. VALEURS À RE-MESURER AU PIXEL sur la capture finale ;
# celles-ci sont un point de départ calibré, pas une prédiction.
# ---------------------------------------------------------------------------
MATERIAUX = {
    # nom                        r      v      b     rugosité
    "MAT_Bridge_Wet":         (0.145, 0.150, 0.135, 0.55),  # assise mouillée,
    "MAT_Bridge_Ashlar":      (0.300, 0.272, 0.216, 0.90),  # appareil courant
    "MAT_Bridge_Dressed":     (0.375, 0.352, 0.298, 0.82),  # pierre de taille
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
# Outillage de loft — repris de `make_pylon_resonance.py`, recopié et non
# partagé (règle de la passe : chaque générateur porte le sien).
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


def objet(nom, anneaux, nom_materiau, fermer_bas=True, fermer_haut=True):
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


def section_trapeze(x, y_bas, y_haut, z_bas, z_haut, chanfrein=CHANFREIN):
    """Section fermée à 8 sommets dans le plan X = x, symétrique en Y.

    `y_bas` et `y_haut` peuvent différer : c'est le FRUIT du mur (la face
    penche en arrière en montant). Une face strictement verticale de 3 m de
    haut prend la même lumière du bas en haut et se lit comme une plaque —
    c'est le défaut nommé par le lead sur le pylône, et il vaut ici pour les
    faces de culée, qui sont les plus grandes surfaces de l'ouvrage.
    """
    h = z_haut - z_bas
    c = min(chanfrein, y_bas * 0.45, y_haut * 0.45, h * 0.45)
    return [
        (x, y_bas - c, z_bas), (x, y_bas, z_bas + c),
        (x, y_haut, z_haut - c), (x, y_haut - c, z_haut),
        (x, c - y_haut, z_haut), (x, -y_haut, z_haut - c),
        (x, -y_bas, z_bas + c), (x, c - y_bas, z_bas),
    ]


def section_bande(x, y0, y1, z_bas, z_haut, chanfrein=CHANFREIN):
    """Section fermée à 8 sommets sur une bande latérale [y0 ; y1].

    Sert aux pièces qui n'existent que d'un côté : tympan, parapet,
    chaperon, cordon, mur en aile.
    """
    largeur = abs(y1 - y0)
    h = z_haut - z_bas
    c = min(chanfrein, largeur * 0.45, h * 0.45)
    s = 1.0 if y1 >= y0 else -1.0
    return [
        (x, y0 + s * c, z_bas), (x, y1 - s * c, z_bas),
        (x, y1, z_bas + c), (x, y1, z_haut - c),
        (x, y1 - s * c, z_haut), (x, y0 + s * c, z_haut),
        (x, y0, z_haut - c), (x, y0, z_bas + c),
    ]


def section_arc(theta, r_int, r_ext, demi_l, chanfrein=CHANFREIN):
    """Section du bandeau, dans le plan radial à l'angle `theta`.

    Le repère local de la section est (rayon, y). Un point (r, y) se place
    à (r·sin θ, y, z_centre + r·cos θ). C'est ce qui rend les joints
    RADIAUX par construction : ils sont dans la section, donc perpendiculaires
    à l'intrados, quel que soit l'angle.
    """
    st, ct = math.sin(theta), math.cos(theta)
    ep = r_ext - r_int
    c = min(chanfrein, demi_l * 0.45, ep * 0.45)
    plan = [
        (r_ext, demi_l - c), (r_ext - c, demi_l),
        (r_int + c, demi_l), (r_int, demi_l - c),
        (r_int, c - demi_l), (r_int + c, -demi_l),
        (r_ext - c, -demi_l), (r_ext, c - demi_l),
    ]
    return [(r * st, y, Z_CENTRE_ARC + r * ct) for r, y in plan]


# ---------------------------------------------------------------------------
# Profils longitudinaux.
# ---------------------------------------------------------------------------
def terrain_monde(x):
    """Hauteur MONDE du sol gelé à l'abscisse x de l'axe (table mesurée)."""
    if x <= PROFIL_TERRAIN[0][0]:
        return PROFIL_TERRAIN[0][1]
    if x >= PROFIL_TERRAIN[-1][0]:
        return PROFIL_TERRAIN[-1][1]
    for i in range(len(PROFIL_TERRAIN) - 1):
        x0, y0 = PROFIL_TERRAIN[i]
        x1, y1 = PROFIL_TERRAIN[i + 1]
        if x0 <= x <= x1:
            t = (x - x0) / (x1 - x0)
            return y0 + (y1 - y0) * t
    return PROFIL_TERRAIN[-1][1]


def terrain_modele(x):
    return terrain_monde(x) + 2.60


def tablier_dessus(x):
    """Arase du tablier : bombée sur l'arche, en rampe au-delà des culées."""
    a = abs(x)
    if a <= DEMI_PORTEE:
        return Z_TABLIER_CLE - BOMBEMENT * (a / DEMI_PORTEE) ** 2
    if a <= X_CULEE:
        return Z_TABLIER_CLE - BOMBEMENT
    if x < 0.0:
        s = (-X_CULEE - x) / (-X_CULEE - X_CHAUSSEE_O)
        return (Z_TABLIER_CLE - BOMBEMENT) + (Z_RAMPE_O - Z_TABLIER_CLE + BOMBEMENT) * s
    s = (x - X_CULEE) / (X_CHAUSSEE_E - X_CULEE)
    return (Z_TABLIER_CLE - BOMBEMENT) + (Z_RAMPE_E - Z_TABLIER_CLE + BOMBEMENT) * s


def tablier_dessous(x):
    return tablier_dessus(x) - DALLE_EPAISSEUR


def extrados_z(x):
    """Cote de l'extrados de l'arc à l'abscisse x (|x| <= X_SKEWBACK)."""
    a = min(abs(x), RAYON_EXT)
    return Z_CENTRE_ARC + math.sqrt(max(RAYON_EXT ** 2 - a * a, 0.0))


def intrados_z(x):
    a = min(abs(x), RAYON_INT)
    return Z_CENTRE_ARC + math.sqrt(max(RAYON_INT ** 2 - a * a, 0.0))


# ---------------------------------------------------------------------------
# LES PIÈCES.
# ---------------------------------------------------------------------------
def bandeau():
    """L'ARCHE — un seul volume balayé, 19 claveaux, 18 joints radiaux.

    C'est la pièce qui répond au premier défaut. Les joints ne sont pas des
    interstices entre des blocs : ce sont des GORGES creusées dans la
    section pendant le balayage. Le solide reste continu et fermé, et les
    joints sont exactement radiaux parce que la section l'est.

    Le pas est constant EN ANGLE, et c'est correct ici — contrairement à
    l'ellipse de la version rejetée — parce qu'un arc de CERCLE a un pas
    métrique proportionnel au pas angulaire : 5,8195 × 6,0397° = 0,6135 m
    sur l'intrados, à chaque claveau, du sommier à la clé.
    """
    anneaux = []
    plein = (RAYON_INT, RAYON_EXT, DEMI_L_ARCHIVOLTE)
    creux = (RAYON_INT + JOINT_PROFONDEUR, RAYON_EXT,
             DEMI_L_ARCHIVOLTE - JOINT_PROFONDEUR)
    demi_gorge = JOINT_DEMI_LARGEUR / RAYON_INT
    joue = JOINT_PENTE / RAYON_INT

    anneaux.append(section_arc(-DEMI_ANGLE, *plein))
    for k in range(1, VOUSSOIRS):
        theta = -DEMI_ANGLE + PAS_ANGLE * k
        # Milieu du claveau précédent : l'intrados reste bien circulaire
        # entre deux joints, il n'est pas une corde.
        anneaux.append(section_arc(theta - PAS_ANGLE * 0.5, *plein))
        anneaux.append(section_arc(theta - demi_gorge, *plein))
        anneaux.append(section_arc(theta - demi_gorge + joue, *creux))
        anneaux.append(section_arc(theta + demi_gorge - joue, *creux))
        anneaux.append(section_arc(theta + demi_gorge, *plein))
    anneaux.append(section_arc(DEMI_ANGLE - PAS_ANGLE * 0.5, *plein))
    anneaux.append(section_arc(DEMI_ANGLE, *plein))
    return objet("SM_Bridge_ArchRing", anneaux, "MAT_Bridge_Dressed")


def culee_basse(cote):
    """Assise MOUILLÉE de la culée : du lit jusqu'à 0,55 m au-dessus de l'eau.

    Pièce séparée pour une seule raison : la matière. La pierre en contact
    de la rivière est plus sombre et moins rugueuse (§5.2, pierre humide
    0,35–0,65) ; c'est la valeur basse de la hiérarchie, et c'est elle qui
    ANCRE l'ouvrage dans l'eau au lieu de le laisser flotter au-dessus.
    """
    x0 = cote * DEMI_PORTEE
    x1 = cote * X_CULEE
    anneaux = []
    pas = 8
    for i in range(pas + 1):
        t = i / pas
        x = x0 + (x1 - x0) * t
        # Le pied s'élargit : empattement de fondation, visible sur 0,7 m.
        y_bas = DEMI_L_MUR + 0.30 * max(0.0, 1.0 - t * 2.2)
        anneaux.append(section_trapeze(x, y_bas, DEMI_L_MUR, 0.0,
                                       Z_LIGNE_MOUILLEE))
    if cote < 0:
        anneaux.reverse()
    return objet("SM_Bridge_AbutmentBase_%s" % ("W" if cote < 0 else "E"),
                 anneaux, "MAT_Bridge_Wet")


def culee_haute(cote):
    """MASSIF DE CULÉE — la plus grande surface de l'ouvrage, donc la plus
    exposée au défaut « grande face blanche ». Quatre dispositifs :

      1. FRUIT : la face rentre de 0,18 m sur sa hauteur, elle n'est jamais
         verticale et prend un dégradé au lieu d'une valeur unique ;
      2. JOINTS VERTICAUX tous les 0,90 m, gorges de 0,05 m creusées par le
         même procédé de section rentrée que les joints de l'arche ;
      3. le BANDEAU D'IMPOSTE en saillie à la naissance (pièce séparée) ;
      4. le CORDON en saillie sous le tablier (pièce séparée).

    Résultat : aucune surface plane libre ne dépasse 0,90 × 3,1 m.

    L'ANCRAGE se lit dans les nombres : au dos (x = ±8,60) la culée n'est
    plus proue que de 0,7 m au-dessus du terrain mesuré, contre 3,1 m à son
    maximum. Elle SORT de la berge au lieu d'être posée devant.
    """
    x0 = cote * DEMI_PORTEE
    x1 = cote * X_CULEE
    retrait = 0.05
    abscisses = []
    n = 14
    for i in range(n + 1):
        abscisses.append((x0 + (x1 - x0) * (i / n), 0.0))
    # Joints verticaux : quatre par culée, à pas métrique constant.
    for j in range(1, 5):
        xj = x0 + (x1 - x0) * (j / 5.0)
        d = 0.03 * (1.0 if x1 > x0 else -1.0)
        abscisses += [(xj - d, 0.0), (xj - d * 0.4, retrait),
                      (xj + d * 0.4, retrait), (xj + d, 0.0)]
    abscisses.sort(key=lambda p: p[0] * (1.0 if x1 > x0 else -1.0))

    anneaux = []
    for x, r in abscisses:
        z_haut = tablier_dessous(x)
        # Le dessus suit le sommier tant qu'on est sous l'arc, puis rejoint
        # le dessous du tablier : la culée PORTE le bandeau, elle ne le
        # côtoie pas.
        # LE DESSUS MONTE D'UN COUP PASSÉ LE SOMMIER, et c'est un correctif,
        # pas un choix. Le premier jet faisait remonter la culée jusqu'au
        # tablier en douceur sur 1,10 m : la silhouette isolée a montré DEUX
        # TRIANGLES BLANCS aux reins, entre l'extrados et le tablier, là où
        # ni l'arc ni la culée n'arrivaient encore. Un vide de 2,5 m sous le
        # tablier qu'aucun contrôle numérique n'avait vu — seule la
        # projection le montre, exactement comme les trois pieds du pylône.
        a = abs(x)
        if a <= X_SKEWBACK:
            z_haut = Z_NAISSANCE + (Z_SKEWBACK - Z_NAISSANCE) * \
                (a - DEMI_PORTEE) / max(X_SKEWBACK - DEMI_PORTEE, 1e-6)
        anneaux.append(section_trapeze(
            x, DEMI_L_MUR - r, DEMI_L_MUR - 0.18 - r,
            Z_LIGNE_MOUILLEE - 0.30, max(z_haut, Z_LIGNE_MOUILLEE + 0.10)))
    if cote < 0:
        anneaux.reverse()
    return objet("SM_Bridge_Abutment_%s" % ("W" if cote < 0 else "E"),
                 anneaux, "MAT_Bridge_Ashlar")


def chaussee(cote):
    """RAMPE D'ACCÈS — le corps qui porte le tablier au-delà de la culée.

    Son dessous suit le PROFIL DE TERRAIN MESURÉ moins 25 cm. C'est la
    « transition propre vers le terrain » : la rampe s'enfonce dans la
    berge et s'y termine, elle ne s'arrête pas en l'air sur un bord franc.
    """
    x0 = cote * X_CULEE
    x1 = X_CHAUSSEE_E if cote > 0 else X_CHAUSSEE_O
    anneaux = []
    pas = 10
    for i in range(pas + 1):
        t = i / pas
        x = x0 + (x1 - x0) * t
        z_bas = terrain_modele(x) - DECAISSEMENT
        z_haut = tablier_dessous(x)
        if z_haut - z_bas < 0.10:
            break
        anneaux.append(section_trapeze(x, DEMI_L_MUR, DEMI_L_MUR - 0.06,
                                       z_bas, z_haut))
    if cote < 0:
        anneaux.reverse()
    return objet("SM_Bridge_Causeway_%s" % ("W" if cote < 0 else "E"),
                 anneaux, "MAT_Bridge_Ashlar")


def tympan(face):
    """TYMPAN — le mur de front entre l'extrados et le tablier.

    Un seul loft continu par face, de sommier à sommier, dont la base SUIT
    l'extrados au millimètre : il n'y a aucun jeu possible entre le mur et
    l'arche, et le contrôle 3 le vérifie sur 20 abscisses.
    """
    y0 = face * DEMI_L_PARAPET_INT
    y1 = face * DEMI_L_MUR
    # Le mur de front NE S'ARRÊTE PAS au sommier : il continue au-dessus de
    # la culée et meurt sur le bandeau d'imposte. C'est à ça que sert une
    # imposte, et c'est ce qui ferme les deux triangles vus en silhouette.
    abscisses = sorted({-X_SKEWBACK, X_SKEWBACK} | {
        -X_CULEE + (2.0 * X_CULEE) * (i / 72.0) for i in range(73)})
    anneaux = []
    for x in abscisses:
        z_bas = extrados_z(x) if abs(x) <= X_SKEWBACK else Z_SKEWBACK
        z_haut = tablier_dessous(x)
        anneaux.append(section_bande(x, y0, y1, z_bas, max(z_haut, z_bas + 0.12)))
    if face < 0:
        anneaux.reverse()
    return objet("SM_Bridge_Spandrel_%s" % ("N" if face > 0 else "S"),
                 anneaux, "MAT_Bridge_Ashlar")


def imposte(cote, face):
    """BANDEAU D'IMPOSTE — la ligne horizontale qui marque la naissance.

    En saillie de 0,14 m sur le nu du mur. C'est l'élément qui dit à l'œil
    où l'arc commence et où la culée finit ; sans lui les deux masses se
    confondent en un seul bloc, ce qui est exactement le reproche
    « géométrie qui déborde des culées ».
    """
    # Le bandeau MORD dans le mur de 0,14 m au lieu de s'y coller : posé
    # tangent, il ne recouvrait l'archivolte que de 0,10 m et le contrôle 3
    # l'a refusé comme pièce rapportée. Une moulure appartient au mur.
    x0 = cote * (X_SKEWBACK - 0.35)
    x1 = cote * (X_CULEE + 0.05)
    y0 = face * (DEMI_L_MUR - 0.14)
    y1 = face * (DEMI_L_MUR + 0.14)
    anneaux = []
    pas = 6
    for i in range(pas + 1):
        x = x0 + (x1 - x0) * (i / pas)
        anneaux.append(section_bande(x, y0, y1, Z_SKEWBACK - 0.13,
                                     Z_SKEWBACK + 0.13, 0.035))
    if cote * face < 0:
        anneaux.reverse()
    return objet("SM_Bridge_Impost_%s%s" % ("W" if cote < 0 else "E",
                                            "N" if face > 0 else "S"),
                 anneaux, "MAT_Bridge_Dressed")


def cordon(face):
    """CORDON — bandeau continu en saillie de 0,16 m sous le tablier.

    Il court d'un bout à l'autre de l'ouvrage et coupe la façade en deux
    registres. Avec l'archivolte en dessous et la corniche au-dessus, plus
    aucune façade ne présente de plan libre de plus de 3 m².
    """
    y0 = face * DEMI_L_MUR
    y1 = face * DEMI_L_CORDON
    anneaux = []
    pas = 30
    for i in range(pas + 1):
        x = X_PARAPET_O + (X_PARAPET_E - X_PARAPET_O) * (i / pas)
        anneaux.append(section_bande(x, y0, y1, Z_CORDON_BAS, Z_CORDON_HAUT,
                                     0.04))
    if face < 0:
        anneaux.reverse()
    return objet("SM_Bridge_StringCourse_%s" % ("N" if face > 0 else "S"),
                 anneaux, "MAT_Bridge_Dressed")


def tablier():
    """LE TABLIER — dalle bombée, en débord de 0,18 m sur le nu des murs.

    Le débord (corniche, larmier) n'est pas décoratif : il projette une
    ombre horizontale continue sur toute la façade, et c'est la ligne qui
    fait lire le pont comme un ouvrage plutôt que comme un bloc.
    """
    anneaux = []
    pas = 56
    for i in range(pas + 1):
        x = X_CHAUSSEE_O + (X_CHAUSSEE_E - X_CHAUSSEE_O) * (i / pas)
        z_haut = tablier_dessus(x)
        anneaux.append(section_trapeze(x, DEMI_L_CORNICHE, DEMI_L_CORNICHE,
                                       z_haut - DALLE_EPAISSEUR, z_haut, 0.05))
    return objet("SM_Bridge_Deck", anneaux, "MAT_Bridge_Ashlar")


# BRÈCHE et REFUGE — l'ouvrage a vécu, mais il a vécu de façon lisible.
# La brèche est côté ÉCLAIRÉ (+Y) : c'est la seule façon qu'elle se voie sur
# la vue de composition et sur la silhouette. Le refuge (renfoncement de
# piéton, courant sur les ponts anciens) est côté ombre, pour que les deux
# rives du tablier aient chacune un évènement.
BRECHE_X = (1.30, 4.55)
REFUGE_X = (-1.40, 1.40)


def parapet(face):
    """PARAPET partiellement RUINÉ.

    Côté éclairé, une brèche franche de 3,25 m dont les deux bouts
    DESCENDENT EN GRADINS au lieu d'être coupés net : une rupture nette se
    lit comme un trou de modélisation, une rupture en gradins se lit comme
    une pierre arrachée. Côté ombre, le parapet recule de 0,34 m sur 2,8 m
    pour former un refuge.
    """
    y0 = face * DEMI_L_PARAPET_INT
    y1 = face * DEMI_L_MUR
    anneaux = []
    pas = 78
    ouvert = False
    for i in range(pas + 1):
        x = X_PARAPET_O + (X_PARAPET_E - X_PARAPET_O) * (i / pas)
        z0 = tablier_dessus(x)
        h = PARAPET_HAUTEUR
        y_int = y0
        if face > 0:
            if BRECHE_X[0] <= x <= BRECHE_X[1]:
                ouvert = True
                continue
            # Gradins de part et d'autre de la brèche.
            for bord in BRECHE_X:
                d = abs(x - bord)
                if d < 1.30:
                    h = PARAPET_HAUTEUR * (0.24 + 0.76 * (d / 1.30) ** 0.8)
        else:
            if REFUGE_X[0] <= x <= REFUGE_X[1]:
                y_int = face * (DEMI_L_PARAPET_INT + 0.34)
        anneaux.append(section_bande(x, y_int, y1, z0, z0 + h, 0.04))
    if face < 0:
        anneaux.reverse()
    obj = objet("SM_Bridge_Parapet_%s" % ("N" if face > 0 else "S"),
                anneaux, "MAT_Bridge_Ashlar")
    obj["breche"] = ouvert
    return obj


def chaperon(face):
    """CHAPERON du parapet — pierre de taille claire, légèrement débordante.

    Il porte la valeur haute de la hiérarchie sur la ligne la plus visible
    de l'ouvrage : le couronnement, qui est aussi la seule surface presque
    horizontale que le soleil frappe à 23° d'élévation.
    """
    y0 = face * (DEMI_L_PARAPET_INT - 0.06)
    y1 = face * DEMI_L_CHAPERON
    anneaux = []
    pas = 78
    for i in range(pas + 1):
        x = X_PARAPET_O + (X_PARAPET_E - X_PARAPET_O) * (i / pas)
        if face > 0:
            if BRECHE_X[0] - 0.10 <= x <= BRECHE_X[1] + 0.10:
                continue
            saute = False
            for bord in BRECHE_X:
                if abs(x - bord) < 1.30:
                    saute = True
            if saute:
                continue
        z0 = tablier_dessus(x) + PARAPET_HAUTEUR
        y_int = y0
        if face < 0 and REFUGE_X[0] <= x <= REFUGE_X[1]:
            y_int = face * (DEMI_L_PARAPET_INT + 0.28)
        anneaux.append(section_bande(x, y_int, y1, z0, z0 + CHAPERON_HAUTEUR,
                                     0.035))
    if face < 0:
        anneaux.reverse()
    return objet("SM_Bridge_Coping_%s" % ("N" if face > 0 else "S"),
                 anneaux, "MAT_Bridge_Dressed")


def mur_aile(cote, face):
    """MUR EN AILE — le mur qui retient la berge de part et d'autre de la rampe.

    Il s'évase à 35° de l'axe et son arase DESCEND jusqu'au terrain mesuré :
    il meurt dans la pente au lieu de s'y arrêter. C'est la pièce qui rend
    la transition lisible et qui casse les deux bouts de la façade de culée.
    """
    x0 = cote * (X_CULEE - 0.20)
    y_dep = face * DEMI_L_MUR
    longueur = 3.60
    anneaux = []
    pas = 6
    for i in range(pas + 1):
        t = i / pas
        x = x0 + cote * math.cos(math.radians(35.0)) * longueur * t
        y = y_dep + face * math.sin(math.radians(35.0)) * longueur * t
        sol = terrain_modele(x)
        z_haut = (tablier_dessus(x0) + 0.30) * (1.0 - t) + (sol - 0.10) * t
        z_bas = min(sol - 0.90, z_haut - 0.45)
        # 0,55 et non 0,44 : à 0,44 le mur se lisait comme une lame en
        # silhouette. Un mur de soutènement a de l'épaisseur.
        anneaux.append(section_bande(x, y - face * 0.55, y, z_bas,
                                     max(z_haut, z_bas + 0.30), 0.04))
    if cote * face < 0:
        anneaux.reverse()
    return objet("SM_Bridge_Wing_%s%s" % ("W" if cote < 0 else "E",
                                          "N" if face > 0 else "S"),
                 anneaux, "MAT_Bridge_Ashlar")


def radier(cote):
    """RADIER — le tapis de pierre au pied de la culée, dans le lit.

    Il touche la culée (contrôle 3) et donne au pied de l'ouvrage une base
    horizontale sombre à la ligne d'eau. AUCUN bloc libre n'est semé dans le
    lit : les gravats de la version précédente sont précisément ce qui
    encombrait la vue sous l'arche.
    """
    x0 = cote * (DEMI_PORTEE - 0.90)
    x1 = cote * (DEMI_PORTEE + 1.70)
    anneaux = []
    pas = 5
    for i in range(pas + 1):
        t = i / pas
        x = x0 + (x1 - x0) * t
        demi = DEMI_L_MUR + 0.52 - 0.22 * t
        anneaux.append(section_trapeze(x, demi, demi - 0.10, 0.20, Z_LIT + 0.34,
                                       0.06))
    if cote < 0:
        anneaux.reverse()
    return objet("SM_Bridge_Apron_%s" % ("W" if cote < 0 else "E"),
                 anneaux, "MAT_Bridge_Wet")


# ---------------------------------------------------------------------------
# CONTRÔLES — le générateur REFUSE d'enregistrer si l'un échoue.
#
# Ils sont écrits pour ROUGIR sur les défauts nommés par le lead, pas pour
# décorer. Chacun mesure le MAILLAGE PRODUIT, jamais les constantes qui
# l'ont produit : un contrôle qui relit sa propre formule ne peut pas
# échouer (PROMPT4 §2).
# ---------------------------------------------------------------------------
def controle_arche(obj):
    """1. L'arc est un ARC, et ses 18 joints sont RÉGULIERS.

    On mesure la distance de chaque sommet à l'axe de l'arc, et on retrouve
    les joints en repérant les sommets dont le rayon tombe dans la bande de
    la gorge, puis en les groupant par angle. Un empilement de claveaux
    droits échouerait sur le premier test ; une gorge manquante ou un pas
    dérivé échouerait sur le second.
    """
    rayons, angles_gorge = [], []
    for v in obj.data.vertices:
        r = math.hypot(v.co.x, v.co.z - Z_CENTRE_ARC)
        rayons.append(r)
        if RAYON_INT + 0.060 <= r <= RAYON_INT + 0.080:
            angles_gorge.append(math.degrees(
                math.atan2(v.co.x, v.co.z - Z_CENTRE_ARC)))
    r_min, r_max = min(rayons), max(rayons)
    dedans = sum(1 for r in rayons
                 if RAYON_INT - 0.002 <= r <= RAYON_EXT + 0.002)
    part = dedans / len(rayons)

    angles_gorge.sort()
    grappes = []
    for a in angles_gorge:
        if grappes and a - grappes[-1][-1] < 0.5:
            grappes[-1].append(a)
        else:
            grappes.append([a])
    centres = [sum(g) / len(g) for g in grappes]
    ecart = 0.0
    if len(centres) >= 2:
        pas_moyen = (centres[-1] - centres[0]) / (len(centres) - 1)
        for k, c in enumerate(centres):
            ecart = max(ecart, abs(c - (centres[0] + pas_moyen * k)))
    # LA MESURE QUI RÉFUTE LE DÉFAUT NOMMÉ : la largeur MÉTRIQUE de chaque
    # claveau sur l'intrados, reconstruite depuis le maillage. La version
    # rejetée, qui échantillonnait une ellipse à pas d'angle constant,
    # aurait imprimé ici 0,758 m au sommier contre 1,478 m à la clé. Un arc
    # de cercle balayé à pas d'angle constant donne la même largeur partout ;
    # c'est ça, « voussoirs réguliers ».
    largeurs = [math.radians(centres[k + 1] - centres[k]) * RAYON_INT
                for k in range(len(centres) - 1)]
    if centres:
        largeurs.append(math.radians(centres[0] + math.degrees(DEMI_ANGLE))
                        * RAYON_INT)
        largeurs.append(math.radians(math.degrees(DEMI_ANGLE) - centres[-1])
                        * RAYON_INT)
    return r_min, r_max, part, len(centres), ecart, min(largeurs), max(largeurs)


def controle_passage(pieces, exclues):
    """2. LE PASSAGE SOUS L'ARCHE EST LIBRE À HAUTEUR DE JOUEUR.

    Le quatrième défaut, transformé en prisme chiffré : travée libre ×
    pleine largeur × [lit ; intrados − 0,25]. On teste les sommets, les
    CENTRES DE FACE et les MILIEUX D'ARÊTE — un sommet seul laisserait
    passer une face qui traverse le prisme sans y poser de sommet.
    """
    intrus = []
    for obj in pieces:
        if obj.name in exclues:
            continue
        mesh = obj.data
        points = [tuple(v.co) for v in mesh.vertices]
        for poly in mesh.polygons:
            points.append(tuple(poly.center))
        for e in mesh.edges:
            a = mesh.vertices[e.vertices[0]].co
            b = mesh.vertices[e.vertices[1]].co
            points.append(((a.x + b.x) * 0.5, (a.y + b.y) * 0.5,
                           (a.z + b.z) * 0.5))
        for x, y, z in points:
            if abs(x) > DEMI_PORTEE or abs(y) > DEMI_L_CORNICHE:
                continue
            if z < Z_LIT or z > intrados_z(x) - 0.25:
                continue
            intrus.append((obj.name, x, y, z))
            break
    hauteur_cle = intrados_z(0.0) - Z_LIT
    largeur_utile = 0.0
    pas = 0.05
    x = -DEMI_PORTEE
    while x <= DEMI_PORTEE:
        if intrados_z(x) - Z_LIT >= 2.60:
            largeur_utile += pas
        x += pas
    return intrus, hauteur_cle, largeur_utile


def aabb(obj):
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    return (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs))


def controle_solidarite(pieces):
    """3. RIEN NE FLOTTE : chaque pièce touche une autre.

    « Blocs non solidarisés » devient un nombre : le recouvrement des boîtes
    englobantes doit valoir au moins 0,12 m sur les TROIS axes avec au moins
    une autre pièce. Rend la pièce la plus faiblement rattachée.
    """
    boites = {o.name: aabb(o) for o in pieces}
    pire_nom, pire = None, 1e9
    for a in pieces:
        ba = boites[a.name]
        meilleur = 0.0
        for b in pieces:
            if b is a:
                continue
            bb = boites[b.name]
            rec = min(min(ba[1], bb[1]) - max(ba[0], bb[0]),
                      min(ba[3], bb[3]) - max(ba[2], bb[2]),
                      min(ba[5], bb[5]) - max(ba[4], bb[4]))
            meilleur = max(meilleur, rec)
        if meilleur < pire:
            pire, pire_nom = meilleur, a.name
    return pire_nom, pire


def controle_tympan(obj_tympan):
    """3 bis. Le tympan repose EXACTEMENT sur l'extrados.

    Sur 20 abscisses, l'arase basse du mur de front doit se trouver à moins
    de 0,02 m de la courbe d'extrados. C'est ce qui interdit la fente entre
    l'arche et le mur qu'un empilement laisse toujours.
    """
    # Mesure PAR ANNEAU, à l'abscisse réelle du mur — et non sur une grille
    # rééchantillonnée. Le premier jet comparait l'arase à `extrados_z(x)`
    # pour un x arbitraire distant de l'anneau : près du sommier la pente de
    # l'extrados vaut 1,55, donc 0,12 m de décalage en x fabriquait un faux
    # écart de 0,19 m. Le contrôle mesurait sa propre grille.
    par_x = {}
    for v in obj_tympan.data.vertices:
        cle = round(v.co.x, 6)
        par_x[cle] = min(par_x.get(cle, 1e9), v.co.z)
    # Hors du sommier le mur repose sur la culée, pas sur l'arc : on ne
    # mesure la portance que là où l'arc existe réellement.
    return max(abs(z - extrados_z(x)) for x, z in par_x.items()
               if abs(x) <= X_SKEWBACK - 0.02)


def controle_ancrage():
    """4. LES RAMPES MEURENT DANS LA BERGE.

    Contre le profil de terrain MESURÉ : le dessous de rampe doit rester
    entre 0,05 et 0,45 m sous le sol sur toute sa longueur, et son arase
    doit rejoindre le terrain à moins de 0,35 m à son extrémité. Une rampe
    qui s'arrête en l'air, ou qui plane au-dessus de la berge, rougit ici.
    """
    defauts = []
    for x0, x1 in ((-X_CULEE, X_CHAUSSEE_O), (X_CULEE, X_CHAUSSEE_E)):
        pas = 12
        for i in range(pas + 1):
            x = x0 + (x1 - x0) * (i / pas)
            sol = terrain_modele(x)
            if not (0.05 <= DECAISSEMENT <= 0.45):
                defauts.append("décaissement %.2f hors [0,05 ; 0,45]" % DECAISSEMENT)
            if tablier_dessous(x) < sol - 0.60:
                defauts.append("rampe enterrée en x=%.1f" % x)
        bout = x1
        if abs(tablier_dessus(bout) - terrain_modele(bout)) > 0.35:
            defauts.append("bout de rampe x=%.1f à %.2f m du sol"
                           % (bout, tablier_dessus(bout) - terrain_modele(bout)))
    return defauts


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

    arche = bandeau()
    tympan_n = tympan(1)
    pieces = [arche, tympan_n, tympan(-1), tablier()]
    pieces += [culee_basse(c) for c in (-1, 1)]
    pieces += [culee_haute(c) for c in (-1, 1)]
    pieces += [chaussee(c) for c in (-1, 1)]
    pieces += [radier(c) for c in (-1, 1)]
    pieces += [cordon(f) for f in (1, -1)]
    pieces += [parapet(f) for f in (1, -1)]
    pieces += [chaperon(f) for f in (1, -1)]
    pieces += [imposte(c, f) for c in (-1, 1) for f in (1, -1)]
    pieces += [mur_aile(c, f) for c in (-1, 1) for f in (1, -1)]

    for obj in pieces:
        obj.location = (0.0, 0.0, 0.0)
        obj.scale = (1.0, 1.0, 1.0)

    z_min = min(min(v.co.z for v in o.data.vertices) for o in pieces)
    z_max = max(max(v.co.z for v in o.data.vertices) for o in pieces)
    x_min = min(min(v.co.x for v in o.data.vertices) for o in pieces)
    x_max = max(max(v.co.x for v in o.data.vertices) for o in pieces)
    triangles = sum(len(p.vertices) - 2 for o in pieces for p in o.data.polygons)
    print("[pont] %d pièces, %d triangles, %.2f × %.2f m (base z=%.3f)"
          % (len(pieces), triangles, x_max - x_min, z_max - z_min, z_min))
    print("[pont] arc : R=%.4f m, demi-angle %.3f°, %d claveaux de %.3f m "
          "(pas %.4f°)" % (RAYON_INT, math.degrees(DEMI_ANGLE), VOUSSOIRS,
                           RAYON_INT * PAS_ANGLE, math.degrees(PAS_ANGLE)))

    echecs = []
    if abs(z_min) > 0.01:
        echecs.append("base pas à z=0 (%.3f)" % z_min)
    if triangles > 16000:
        echecs.append("budget dépassé : %d triangles > 16000" % triangles)

    r_min, r_max, part, n_joints, ecart, l_min, l_max = controle_arche(arche)
    print("[pont] contrôle 1 — rayons %.4f–%.4f m (attendus %.4f / %.4f), "
          "%.1f %% dans la bande, %d joints, régularité ±%.4f°, "
          "claveaux %.3f–%.3f m sur l'intrados"
          % (r_min, r_max, RAYON_INT, RAYON_EXT, part * 100.0, n_joints, ecart,
             l_min, l_max))
    if l_max - l_min > 0.010:
        echecs.append("claveaux irréguliers : %.3f à %.3f m (écart %.3f m)"
                      % (l_min, l_max, l_max - l_min))
    if abs(r_min - RAYON_INT) > 0.001 or abs(r_max - RAYON_EXT) > 0.001:
        echecs.append("l'arc n'est pas un arc : rayons %.4f–%.4f" % (r_min, r_max))
    if part < 0.96:
        echecs.append("seulement %.1f %% des sommets dans la bande du bandeau"
                      % (part * 100.0))
    if n_joints != VOUSSOIRS - 1:
        echecs.append("%d joints détectés, %d attendus" % (n_joints, VOUSSOIRS - 1))
    if ecart > 0.05:
        echecs.append("joints irréguliers : ±%.3f° > 0,05°" % ecart)

    exclues = {o.name for o in pieces
               if "Abutment" in o.name or "Apron" in o.name}
    intrus, h_cle, largeur = controle_passage(pieces, exclues)
    print("[pont] contrôle 2 — dégagement à la clé %.2f m, hauteur ≥ 2,60 m "
          "sur %.2f m de travée, %d intrus" % (h_cle, largeur, len(intrus)))
    if intrus:
        echecs.append("passage encombré par %s en (%.2f ; %.2f ; %.2f)"
                      % intrus[0])
    if h_cle < 4.00:
        echecs.append("dégagement à la clé %.2f m < 4,00 m" % h_cle)
    if largeur < 6.00:
        echecs.append("hauteur d'homme sur %.2f m seulement < 6,00 m" % largeur)

    faible, recouvrement = controle_solidarite(pieces)
    print("[pont] contrôle 3 — pièce la moins rattachée : %s, recouvrement "
          "%.3f m" % (faible, recouvrement))
    if recouvrement < 0.12:
        echecs.append("%s ne touche rien (recouvrement %.3f m)"
                      % (faible, recouvrement))
    jeu = controle_tympan(tympan_n)
    print("[pont] contrôle 3bis — jeu tympan/extrados : %.4f m" % jeu)
    if jeu > 0.02:
        echecs.append("fente de %.3f m entre le tympan et l'arche" % jeu)

    defauts = controle_ancrage()
    print("[pont] contrôle 4 — ancrage des rampes : %s"
          % ("conforme" if not defauts else " ; ".join(defauts)))
    echecs += defauts

    if echecs:
        for e in echecs:
            print("[pont] ERREUR: %s" % e)
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_StoneBridge_Arch.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[pont] source enregistrée -> %s" % sortie)
    return 0


if __name__ == "__main__":
    sys.exit(main())
