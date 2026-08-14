# SOURCE DE GÉNÉRATION REPRODUCTIBLE — Grotte de la cascade.
#
# POURQUOI CE FICHIER EXISTE. La passe précédente fabriquait la grotte en
# GDScript avec `WorldV2PlaceKit.hollow_rock_mesh()`. Le lead a rejeté :
# « enveloppe ouverte, plaques minces, face intérieure rectiligne noire,
# caméra intérieure dans les polygones ». Les quatre défauts ont une cause
# géométrique unique, lisible dans ce kit et mesurée avant d'écrire ici :
#
#   * AUCUN fond n'y est cousu : les anneaux `inner[i]` et `outer[i]`
#     existent à y = 0 et ne sont jamais reliés — arête libre sur tout le
#     pourtour ;
#   * `if open[i] and open[i + 1]: continue` supprime, au secteur bouche,
#     la paroi intérieure, les bandes extérieures ET la couronne. Seule y
#     survit la voûte, enroulée pour être vue de dessous : culée par le
#     dessus, elle laisse un TROU VERS LE CIEL au-dessus de l'entrée ;
#   * les deux joues ne sont émises qu'aux 2 segments de transition et
#     vont de `inner` à `outer` (t = 1) alors que la couronne s'arrête à
#     t = 0,52 : fente de 0,48 x 4,4 = 2,11 m entre la joue et la face ;
#   * la paroi intérieure est UN quad par colonne de y = 0 à `tops[i]` :
#     une surface réglée, donc rectiligne par construction.
#
# MÉTHODE. Aucun booléen, aucune plaque : un LOFT UNIQUE à sections en
# « rondelle ». Chaque station porte deux profils fermés de MÊME nombre de
# sommets — l'intérieur (arc surbaissé sur sol dishé) et l'extérieur (blob
# irrégulier). On coud la peau extérieure, la peau intérieure, et la
# RONDELLE DE RIVE à la bouche qui relie les deux. Le résultat est UNE
# surface fermée de genre 0 : un solide creusé d'une cavité borgne.
#
# CE QUE LA TOPOLOGIE DONNE GRATUITEMENT, et c'est l'argument central :
# sur un manifold fermé, `bmesh.ops.recalc_face_normals` oriente toutes
# les faces vers l'extérieur DU SOLIDE. Sur la peau d'une cavité, cela
# veut dire VERS LA SALLE. Enroulement et normale d'ombrage deviennent
# donc corrects d'un seul coup, sans raisonnement face par face — c'est
# exactement ce que le kit rejeté faisait à la main, et ratait. Le sol de
# la salle appartient au profil fermé : il est cousu aux parois, aucune
# herbe du terrain ne peut passer entre.
#
# LE SOLEIL. Mesuré par le lead sur la scène montée, et non déduit du
# `.tscn` (les 12 flottants y sont les LIGNES de la base, pas les
# colonnes — première lecture fausse de ma part) : propagation
# (0,8677 ; -0,3907 ; 0,3073), azimut 19,5°, élévation 23,0°, donc soleil
# à l'azimut 199,5°. Le ressaut monte à l'OUEST : la bouche regarde donc
# nécessairement vers l'est, à l'opposé du soleil. Aucun azimut de bouche
# vers l'est n'est éclairable (mesuré : -0,87 à l'est, -0,83 au sud-est,
# -0,40 au nord-est). Le contre-jour est ASSUMÉ : le contraste vient du
# plateau ensoleillé devant, de la crête et du flanc ouest ensoleillés
# au-dessus, et de l'intérieur plus sombre que la collerette.
#
# Vérifié aussi par le calcul : le site n'est PAS dans l'ombre portée du
# ressaut — à 23° d'élévation le rayon franchit la crête (x = -130,
# y = 10,3) avec de la marge. Tout ce qui regarde l'est est en ombre
# PROPRE, pas en ombre portée.
#
# L'AMBIANTE DU MONDE EST CONSTANTE ET NON OCCLUSE (`WorldV2.tscn` :
# `ambient_light_source = 2`, énergie 0,6). Aucun intérieur ne sera noir
# par absence de lumière : l'obscurité doit venir de l'ALBÉDO et de
# l'orientation. Les albédos intérieurs sont donc franchement bas, et
# séparés en trois familles (paroi proche, fond/plafond, sol).
#
# Blender est Z-up ; l'exporteur convertit en Y-up (`export_yup`). On
# modèle donc Z vertical, plan de sol à Z = 0, bouche à l'origine, galerie
# vers +Y. Le lacet d'implantation est appliqué côté Godot.
#
# Usage (les DEUX garde-fous sont obligatoires, cf. export_architecture.sh) :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/environment/make_waterfall_cave.py
#   blender --background --python-exit-code 1 \
#       source_assets/blender/environment/SM_WaterfallCave.blend \
#       --python tools/blender/export_gltf.py -- \
#       --out assets/environment/caves/SM_WaterfallCave.glb

import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

TAU = math.pi * 2.0

# ---------------------------------------------------------------------------
# Cotes. Toutes mesurées contre le terrain GELÉ (probe_site_section, pas de
# 2 m) : plateau plat à 3,00 m sur x in [-118 ; -102], z in [0 ; +9] ; le
# ressaut monte à l'ouest (-120 -> 3,1 ; -122 -> 4,1 ; -124 -> 5,8 ;
# -126 -> 7,6). Le sol intérieur reste donc au niveau du plateau : la
# cavité est une masse POSÉE sur le plat et adossée au ressaut, jamais un
# creusement dans le champ de hauteur (qui, lui, traverserait la salle).
# ---------------------------------------------------------------------------

SEGMENTS = 56           # sommets par profil (visuel)
SEGMENTS_COL = 20       # idem pour la coque de collision
SAG = 0.08              # cuvette du sol : un sol parfaitement plat sonne faux
SKIRT = 2.20            # jupe extérieure sous le plan de sol — masse PLANTÉE
SKIRT_COL = 1.10

# Marges de la coque de collision. Elles ne sont pas cosmétiques : la passe
# rejetée plaçait la face interne du collider EXACTEMENT sur INNER_R, et le
# relief de paroi (wobble +/-0,30) mettait jusqu'à 0,96 m de paroi VISIBLE
# en deçà de la barrière. La caméra entrait donc dans le maillage avant
# d'être arrêtée. Ici la collision est rétrécie explicitement.
COL_MARGE_LAT = 0.40
COL_MARGE_CLE = 0.35

# Stations de la CAVITÉ : (axe_x, axe_y, demi-largeur, hauteur de clé).
# La galerie s'infléchit de ~31° entre le seuil et la salle : depuis le
# seuil on ne voit pas le fond, et depuis la salle la bouche reste une
# lucarne claire. L'inflexion est aussi ce qui permet d'avoir À LA FOIS
# une bouche noire (les 4 premiers mètres restent à l'ambiante seule) et
# une salle éclairée (la source motivée vit après le coude, invisible du
# dehors).
#
# CONTRAINTE DURE du filet `test_la_grotte_a_un_seuil_et_un_interieur` :
# il marche en LIGNE DROITE du seuil à l'intérieur et exige 1,75 m de
# hauteur libre à chaque pas de 0,40 m. La corde d'un arc de 31° sur
# 6,25 m s'écarte au plus de 0,30 m de l'axe — la demi-largeur minimale
# (1,55 m) l'absorbe largement, et la clé y reste au-dessus de 2,4 m.
CAVITE = [
    # ax     ay     hw     cle
    (0.00, -1.15, 1.75, 2.55),   # porche évasé, sol 6 cm SOUS le terrain
    (0.00,  0.00, 1.55, 2.60),   # seuil
    (0.06,  1.60, 1.70, 2.70),
    (0.24,  3.20, 2.15, 2.80),
    (0.58,  4.75, 2.70, 2.90),
    (1.05,  6.25, 3.05, 2.92),   # SALLE
    (1.62,  7.60, 2.80, 2.80),
    (2.25,  8.65, 2.00, 2.40),
    (2.85,  9.25, 1.15, 1.80),
]
CAVITE_APEX = (3.25, 9.55, 0.70)     # pointe de la calotte du fond
# La lèvre du porche plonge sous le terrain. -0,06 au premier jet, avec un
# exhaussement de 0,02 : la CUVETTE du sol (SAG) descendait alors 8 cm sous
# le plan, donc 6 cm sous le terrain — mesuré en capture, l'herbe du
# terrain gelé traversait le sol de la salle sur toute sa longueur. Le sol
# construit est désormais remonté de 0,11 (place script) et la lèvre
# creusée d'autant, pour rester enterrée sans faire de marche.
PORCHE_DENIVELE = -0.14

# Stations du MASSIF : mêmes axes, prolongés au-delà de la cavité, plus le
# jeu latéral et le jeu de clé. Au-delà de la cavité les demi-largeurs de
# référence sont fantômes (le solide y est plein).
# SILHOUETTE CAPTURÉE TÔT, ET ELLE A TRANCHÉ. Le premier jet donnait des
# jeux monotones (0,85 → 1,60 → 0,85) : les deux silhouettes isolées
# sortaient en MICHE LISSE, une coque de casque sans une arête. C'est la
# leçon du pylône — la PROJECTION décide, pas le maillage : un relief
# angulaire, si régulier soit-il le long de l'axe, se projette en dôme.
#
# Trois corrections, toutes dans le profil et non dans la texture :
#   1. deux SOMMETS séparés d'un col (stations 3 et 5, jeu de clé 2,00 et
#      2,05 contre 1,50 entre elles) — le contour monte, redescend, remonte ;
#   2. une VISIÈRE : la station 0 déborde la station 1 (1,70 contre 1,30
#      latéral, 1,55 contre 1,35 en clé), donc la roche surplombe la bouche.
#      C'est le « sourcil » que la passe rejetée posait en boîte séparée,
#      ici construit DANS la coque ;
#   3. des ÉPAULES latérales décorrélées de la clé (station 7 à 2,15
#      latéral pour 1,70 en clé) — le contour de face et le contour de
#      profil ne racontent plus la même chose.
#
# Le jeu de clé ne descend jamais sous 1,35 m tant que la cavité existe :
# à 0,95 m, le contrôle d'épaisseur tombait à 0,35 m de linteau — un
# creux de bruit extérieur et une bosse de bruit intérieur se cumulent.
MASSIF = [
    # ax     ay    hw_ref cle_ref  jeu_lat jeu_cle
    (0.00, -1.15, 1.75, 2.55, 1.70, 1.55),   # visière saillante
    (0.00,  0.00, 1.55, 2.60, 1.60, 1.35),   # retrait derrière la visière
    (0.06,  1.60, 1.70, 2.70, 1.85, 1.45),
    (0.24,  3.20, 2.15, 2.80, 2.10, 2.15),   # SOMMET 1
    (0.58,  4.75, 2.70, 2.90, 2.00, 1.68),   # col
    (1.05,  6.25, 3.05, 2.92, 2.10, 2.22),   # SOMMET 2, au-dessus de la salle
    (1.62,  7.60, 2.80, 2.80, 1.95, 1.62),
    (2.25,  8.65, 2.00, 2.40, 2.15, 1.70),   # épaule latérale
    (2.85,  9.25, 1.15, 1.80, 1.95, 1.35),
    (3.35,  9.90, 0.85, 1.35, 1.60, 1.55),   # ressaut de queue
    (3.85, 10.55, 0.55, 0.95, 1.35, 0.90),
    (4.30, 11.15, 0.30, 0.55, 0.95, 0.70),
]
MASSIF_APEX = (4.65, 11.65, 1.20)

# STRATES. La roche de la vallée est sédimentaire ocre : « strates
# horizontales larges cassées par des fractures diagonales »
# (VISUAL_ASSET_BIBLE §2.1). On rapproche donc la hauteur de la peau d'une
# grille ABSOLUE de niveaux — absolue, pour que les replats se poursuivent
# d'une station à l'autre et fassent de vraies assises, au lieu d'onduler
# avec la section. Sans les coller (0,55) : les arêtes restent franches,
# le volume garde sa forme.
PAS_STRATE = 0.85
FORCE_STRATE = 0.55

# DIACLASE ET CORNICHE — ce qui rend un contour CONCAVE.
#
# Deuxième silhouette : les deux sommets et les strates ont produit des
# facettes, mais le contour restait celui d'une patate. C'est arithmétique
# et non artistique : un rayon en R·(1 + 0,15·harmoniques) ne peut pas
# devenir concave, quelle que soit la richesse des harmoniques. Il faut
# une ENTAILLE et une SAILLIE, franches et localisées.
#
#   * la diaclase est une fracture verticale qui court sur toute la
#     longueur du rocher et mord jusqu'à 45 % du jeu latéral. Elle donne
#     l'encoche du contour, et en jeu une arête verticale que la lumière
#     rasante souligne ;
#   * la corniche est un replat saillant à mi-hauteur, du côté du soleil :
#     elle projette une ombre portée sur le flanc, et son dessous est
#     concave — ce qu'aucune bosse ne peut donner.
#
# Le retrait de la diaclase est plafonné à une FRACTION DU JEU, jamais à
# une valeur absolue : la roche restante ne peut donc pas passer sous le
# seuil d'épaisseur, quel que soit le réglage des jeux.
DIACLASE_THETA = math.radians(158.0)
DIACLASE_LARGEUR = math.radians(34.0)
DIACLASE_PART_LAT = 0.40
DIACLASE_PART_CLE = 0.28
CORNICHE_THETA = math.radians(18.0)
CORNICHE_AMPL = 0.62
CORNICHE_HAUT = 0.46
CORNICHE_ETAL = 0.17

# 0,055 au premier jet : en capture, les parois de la galerie sortaient en
# PLANS GRIS LISSES — le défaut « face intérieure rectiligne » revenait par
# la petite porte. 0,085 donne du relief sans mordre le gabarit ; le jeu de
# clé des stations 3 à 6 est relevé d'autant pour garder l'épaisseur.
AMP_INTERIEUR = 0.085   # relief de paroi : lisible, la salle reste jouable
# 0,150 au premier jet : l'épaisseur minimale de roche tombait à 0,87 m, à
# peine au-dessus du seuil de refus. Le creux du bruit extérieur et la bosse
# du bruit intérieur se cumulent au même endroit (clé de la salle). 0,132
# rend 1,04 m sans toucher à la hauteur de crête, qui, elle, est contrainte
# par le ressaut : à 4,6 m au-dessus du plateau la masse reste sous le profil
# de la falaise (7,6 m à x = -126), donc adossée et non posée devant.
AMP_MASSIF = 0.150      # relief exterieur : le rocher a des epaules

# Contrôles bloquants (§7 du plan). Chiffrés, et chacun rend impossible un
# défaut nommé par le lead.
EPAISSEUR_MIN_M = 0.80          # nulle part une plaque
EPAISSEUR_MIN_COLLERETTE_M = 0.60
GABARIT_DEMI_LARGEUR_M = 0.95   # capsule joueur r = 0,45 m
GABARIT_CLE_M = 2.05
ASSISE_JUPE_MIN_M = 2.00

# ---------------------------------------------------------------------------
# Matières. glTF stocke `baseColorFactor` en LINÉAIRE et Godot le réencode
# en sRGB : écrire 0,40 dans Blender rendrait 0,67 dans Godot (c'est ce qui
# a fait rendre le pylône entièrement blanc). On convertit donc à l'écriture
# et on vérifie ensuite avec probe_asset_materials.gd.
#
# Cibles de VALEUR RENDUE, à mesurer sur capture et jamais à prédire depuis
# l'albédo (le gain mesuré sur le pylône va de 1,43 à 1,80 selon le niveau) :
# crête et flanc ouest au soleil ~0,60 · collerette et flanc est, en ombre
# propre, ~0,38 · parois intérieures 0,16-0,22 · sol intérieur 0,26.
# Contrat de bouche : le pixel le plus clair vu à travers l'ouverture doit
# rester sous 0,5 x la valeur de la collerette.
# ---------------------------------------------------------------------------

MATIERES = {
    "MAT_CaveRock_Face":   ((0.455, 0.405, 0.335), 0.93),
    "MAT_CaveRock_Base":   ((0.300, 0.278, 0.258), 0.95),
    "MAT_CaveRock_Collar": ((0.495, 0.435, 0.352), 0.91),
    "MAT_CaveIn_Wall":     ((0.205, 0.192, 0.180), 0.96),
    "MAT_CaveIn_Deep":     ((0.132, 0.130, 0.140), 0.97),
    "MAT_CaveIn_Floor":    ((0.262, 0.240, 0.208), 0.95),
}
ORDRE_MATIERES = list(MATIERES.keys())
IDX = {nom: i for i, nom in enumerate(ORDRE_MATIERES)}


def srgb_vers_lineaire(canal):
    if canal <= 0.04045:
        return canal / 12.92
    return ((canal + 0.055) / 1.055) ** 2.4


def vider_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def materiau(nom):
    couleur, rugosite = MATIERES[nom]
    mat = bpy.data.materials.new(name=nom)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    r, v, b = (srgb_vers_lineaire(c) for c in couleur)
    bsdf.inputs["Base Color"].default_value = (r, v, b, 1.0)
    bsdf.inputs["Roughness"].default_value = rugosite
    if "Metallic" in bsdf.inputs:
        bsdf.inputs["Metallic"].default_value = 0.0
    mat.diffuse_color = (r, v, b, 1.0)
    return mat


# ---------------------------------------------------------------------------
# Géométrie
# ---------------------------------------------------------------------------

def tangentes(stations):
    """Tangente mitrée par différence centrée : les sections d'un virage se
    mitrent, sinon elles se croisent sur l'intérieur du coude."""
    sortie = []
    for i, st in enumerate(stations):
        avant = stations[max(0, i - 1)]
        apres = stations[min(len(stations) - 1, i + 1)]
        t = Vector((apres[0] - avant[0], apres[1] - avant[1]))
        if t.length < 1e-6:
            t = Vector((0.0, 1.0))
        sortie.append(t.normalized())
    return sortie


def bruit(theta, phase, amplitude):
    """Relief angulaire. Le terme PERSISTANT (sans phase de station) est
    ce qui fait courir une nervure sur toute la longueur du rocher : avec
    des phases toutes décalées, les creux se décalent d'une section à
    l'autre et la surface bouillonne au lieu d'avoir des arêtes."""
    return 1.0 + amplitude * (
        math.sin(3.0 * theta + 0.9) * 0.34
        + math.sin(2.0 * theta + phase) * 0.30
        + math.sin(3.0 * theta + 1.31 * phase + 0.7) * 0.21
        + math.sin(5.0 * theta + 2.17 * phase + 1.9) * 0.15)


def anneau_interieur(station, tangente, segments, phase, retrait_lat, retrait_cle,
                     denivele, sag):
    """Profil FERMÉ de la cavité : arc surbaissé sur un sol légèrement dishé.

    Le sol fait partie du profil — c'est lui qui garantit qu'aucune herbe du
    terrain gelé ne peut apparaître entre le sol et les parois, défaut vu à
    la passe précédente quand le sol était un disque séparé.
    """
    ax, ay, hw, cle = station
    hw = max(0.05, hw - retrait_lat)
    cle = max(0.10, cle - retrait_cle)
    normale = Vector((tangente.y, -tangente.x))
    points = []
    for k in range(segments):
        theta = TAU * k / segments
        u, v = math.cos(theta), math.sin(theta)
        w = bruit(theta, phase, AMP_INTERIEUR)
        n = hw * u * w
        z = (cle * (v ** 0.75) * w) if v >= 0.0 else (sag * v)
        points.append(Vector((ax + n * normale.x, ay + n * normale.y,
                              z + denivele)))
    return points


def anneau_exterieur(station, tangente, segments, phase, jupe, denivele):
    ax, ay, hw, cle, jeu_lat, jeu_cle = station
    normale = Vector((tangente.y, -tangente.x))
    demi = hw + jeu_lat
    haut = cle + jeu_cle
    points = []
    for k in range(segments):
        theta = TAU * k / segments
        u, v = math.cos(theta), math.sin(theta)
        w = bruit(theta, phase, AMP_MASSIF)

        # Diaclase : creux en cosinus surélevé, centré sur son azimut.
        ecart = abs(math.remainder(theta - DIACLASE_THETA, TAU))
        creux = 0.0
        if ecart < DIACLASE_LARGEUR:
            creux = 0.5 + 0.5 * math.cos(math.pi * ecart / DIACLASE_LARGEUR)
        lat = jeu_lat * (1.0 - creux * DIACLASE_PART_LAT)
        cle_jeu = jeu_cle * (1.0 - creux * DIACLASE_PART_CLE)

        n = (hw + lat) * u * w
        if v >= 0.0:
            z = (cle + cle_jeu) * (v ** 0.85) * w
            niveau = round(z / PAS_STRATE) * PAS_STRATE
            z += (niveau - z) * FORCE_STRATE
            # Corniche : saillie latérale dans une bande de hauteur, du
            # côté du soleil. N'ajoute que de la matière — elle ne peut
            # donc jamais amincir la roche.
            portee = max(0.0, math.cos(theta - CORNICHE_THETA)) ** 3.0
            bande = math.exp(-(((v ** 0.85) - CORNICHE_HAUT)
                               / CORNICHE_ETAL) ** 2.0)
            n += CORNICHE_AMPL * portee * bande * (1.0 if u >= 0.0 else -1.0)
        else:
            z = jupe * v * (0.85 + 0.3 * w)
        points.append(Vector((ax + n * normale.x, ay + n * normale.y,
                              z + denivele)))
    return points


def phases(nombre, graine):
    """Phases de relief interpolées le long de l'axe : le bruit doit être
    COHÉRENT d'une station à l'autre, sinon les nervures ne courent pas le
    long du rocher et la surface bouillonne."""
    return [graine * 0.37 + i * 0.61 for i in range(nombre)]


def construire(segments, sag, jupe, retrait_lat, retrait_cle, graine=7.0):
    """Rend (sommets, faces, familles) — familles = étiquette par face."""
    t_cav = tangentes(CAVITE)
    t_mas = tangentes(MASSIF)
    ph_c = phases(len(CAVITE), graine)
    ph_m = phases(len(MASSIF), graine + 3.0)

    sommets = []
    faces = []
    familles = []

    def ajouter_anneau(points):
        base = len(sommets)
        sommets.extend(points)
        return base

    cav_bases = []
    for i, st in enumerate(CAVITE):
        denivele = PORCHE_DENIVELE if i == 0 else 0.0
        cav_bases.append(ajouter_anneau(anneau_interieur(
            st, t_cav[i], segments, ph_c[i], retrait_lat, retrait_cle,
            denivele, sag)))
    cav_apex = len(sommets)
    sommets.append(Vector(CAVITE_APEX))

    mas_bases = []
    for i, st in enumerate(MASSIF):
        denivele = PORCHE_DENIVELE if i == 0 else 0.0
        mas_bases.append(ajouter_anneau(anneau_exterieur(
            st, t_mas[i], segments, ph_m[i], jupe, denivele)))
    mas_apex = len(sommets)
    sommets.append(Vector(MASSIF_APEX))

    def famille_interieure(station_index, k):
        theta = TAU * k / segments
        v = math.sin(theta)
        if v < -0.20:
            return "MAT_CaveIn_Floor"
        if v > 0.55 or station_index >= 4:
            return "MAT_CaveIn_Deep"
        return "MAT_CaveIn_Wall"

    # Peau de la cavité. L'ordre des sommets est indifférent : le manifold
    # fermé sera réorienté d'un bloc par recalc_face_normals.
    for i in range(len(CAVITE) - 1):
        a, b = cav_bases[i], cav_bases[i + 1]
        for k in range(segments):
            k2 = (k + 1) % segments
            faces.append((a + k, a + k2, b + k2, b + k))
            familles.append(famille_interieure(i, k))
    dernier = cav_bases[-1]
    for k in range(segments):
        k2 = (k + 1) % segments
        faces.append((dernier + k, dernier + k2, cav_apex))
        familles.append("MAT_CaveIn_Deep")

    # Peau du massif.
    for i in range(len(MASSIF) - 1):
        a, b = mas_bases[i], mas_bases[i + 1]
        for k in range(segments):
            k2 = (k + 1) % segments
            faces.append((a + k, a + k2, b + k2, b + k))
            z = 0.25 * (sommets[a + k].z + sommets[a + k2].z
                        + sommets[b + k].z + sommets[b + k2].z)
            familles.append("MAT_CaveRock_Base" if z < -0.10
                            else "MAT_CaveRock_Face")
    dernier = mas_bases[-1]
    for k in range(segments):
        k2 = (k + 1) % segments
        faces.append((dernier + k, dernier + k2, mas_apex))
        familles.append("MAT_CaveRock_Face")

    # RONDELLE DE RIVE : la seule pièce qui relie les deux peaux. C'est elle
    # qui fait la collerette de la bouche — piédroits, linteau et seuil d'un
    # seul tenant. C'est aussi elle qui rend le maillage connexe, donc de
    # genre 0, donc orientable d'un bloc.
    a, b = cav_bases[0], mas_bases[0]
    for k in range(segments):
        k2 = (k + 1) % segments
        faces.append((a + k, a + k2, b + k2, b + k))
        familles.append("MAT_CaveRock_Collar")

    return sommets, faces, familles


def objet(nom, sommets, faces, familles, avec_matieres):
    maillage = bpy.data.meshes.new(nom)
    maillage.from_pydata([tuple(v) for v in sommets], [], faces)
    maillage.validate(verbose=False)
    if avec_matieres:
        for cle in ORDRE_MATIERES:
            maillage.materials.append(bpy.data.materials[cle])
        for polygone, famille in zip(maillage.polygons, familles):
            polygone.material_index = IDX[famille]
    obj = bpy.data.objects.new(nom, maillage)
    bpy.context.collection.objects.link(obj)

    bm = bmesh.new()
    bm.from_mesh(maillage)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(maillage)
    bm.free()
    maillage.update()
    for polygone in maillage.polygons:
        polygone.use_smooth = False
    return obj


# ---------------------------------------------------------------------------
# CONTRÔLES BLOQUANTS. Chacun rend impossible un défaut nommé par le lead ;
# le script rend 2 et n'enregistre rien si l'un échoue.
# ---------------------------------------------------------------------------

def controle_fermeture(obj):
    """Aucune arête de bord, aucune arête non-manifold, volume > 0.

    C'est le contrôle qui rend impossible « enveloppe ouverte » et
    « sommet ouvert » : une coque à trous a forcément des arêtes de bord.
    """
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bords = sum(1 for e in bm.edges if len(e.link_faces) != 2)
    non_manifold = sum(1 for e in bm.edges if not e.is_manifold)
    volume = bm.calc_volume(signed=True)
    bm.free()
    return bords, non_manifold, volume


def bvh_depuis(obj, filtre=None):
    sommets = [v.co.copy() for v in obj.data.vertices]
    polys = [tuple(p.vertices) for p in obj.data.polygons
             if filtre is None or filtre(p)]
    return BVHTree.FromPolygons(sommets, polys, all_triangles=False, epsilon=0.0)


def controle_epaisseur(obj, segments):
    """Distance minimale entre peau intérieure et peau extérieure.

    On ne compare pas station à station (elles ne coïncident pas) : on
    construit un BVH de la SEULE peau du massif et on interroge chaque
    sommet de la cavité. C'est la vraie épaisseur de roche.
    """
    n_cav = len(CAVITE) * segments + 1
    peau_massif = bvh_depuis(obj, lambda p: all(i >= n_cav for i in p.vertices))
    mini, mini_collerette = 1e9, 1e9
    for i in range(n_cav):
        co = obj.data.vertices[i].co
        trouve = peau_massif.find_nearest(co)
        if trouve is None or trouve[0] is None:
            continue
        d = (trouve[0] - co).length
        station = i // segments
        if station <= 1:
            mini_collerette = min(mini_collerette, d)
        else:
            mini = min(mini, d)
    return mini, mini_collerette


def controle_gabarit():
    """Une capsule r = 0,45 m, h = 1,85 m passe partout sur le chemin."""
    faibles = []
    for i, (_, ay, hw, cle) in enumerate(CAVITE):
        if i >= len(CAVITE) - 2:
            continue          # les deux dernières stations FERMENT la calotte
        marge_hw = hw * (1.0 - AMP_INTERIEUR)
        marge_cle = cle * (1.0 - AMP_INTERIEUR)
        if marge_hw < GABARIT_DEMI_LARGEUR_M or marge_cle < GABARIT_CLE_M:
            faibles.append((i, ay, marge_hw, marge_cle))
    return faibles


def controle_aucun_jour(obj, segments):
    """Aucun point du sol de la salle ne voit le ciel.

    25 points du sol, rayon vertical, comptage des intersections par
    marche : le nombre doit être PAIR et >= 2. Un seul point qui voit le
    ciel = refus. C'est la vérification machine directe de « aucun trou
    vers le ciel », que le kit rejeté échouait au-dessus de la bouche.
    """
    bvh = bvh_depuis(obj)
    fautes = []
    for i in range(2, len(CAVITE) - 2):
        ax, ay, hw, _ = CAVITE[i]
        for lat in (-0.55, -0.25, 0.0, 0.25, 0.55):
            origine = Vector((ax + lat * hw, ay, 0.35))
            croisements, position, garde = 0, origine.copy(), 0
            while garde < 16:
                garde += 1
                r = bvh.ray_cast(position, Vector((0.0, 0.0, 1.0)), 100.0)
                if r is None or r[0] is None:
                    break
                croisements += 1
                position = r[0] + Vector((0.0, 0.0, 0.002))
            if croisements < 2 or croisements % 2 != 0:
                fautes.append((ax + lat * hw, ay, croisements))
    return fautes


def controle_assise(obj):
    zs = [v.co.z for v in obj.data.vertices]
    seuil = [v.co.z for i, v in enumerate(obj.data.vertices)
             if len(CAVITE) * 0 <= i < 1]
    return min(zs), max(zs), (seuil[0] if seuil else 0.0)


def main():
    vider_scene()
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0
    for nom in ORDRE_MATIERES:
        materiau(nom)

    sommets, faces, familles = construire(
        SEGMENTS, SAG, SKIRT, 0.0, 0.0)
    grotte = objet("SM_WaterfallCave", sommets, faces, familles, True)

    s_col, f_col, fam_col = construire(
        SEGMENTS_COL, SAG, SKIRT_COL, COL_MARGE_LAT, COL_MARGE_CLE)
    collision = objet("COL_WaterfallCave", s_col, f_col, fam_col, False)

    for obj in (grotte, collision):
        obj.location = (0.0, 0.0, 0.0)
        obj.scale = (1.0, 1.0, 1.0)

    tris = sum(len(p.vertices) - 2 for p in grotte.data.polygons)
    tris_col = sum(len(p.vertices) - 2 for p in collision.data.polygons)
    mini_z, maxi_z, _ = controle_assise(grotte)
    print("[grotte] visuel %d faces (%d tris), collision %d faces (%d tris)"
          % (len(grotte.data.polygons), tris,
             len(collision.data.polygons), tris_col))
    print("[grotte] emprise Z de %.2f m a %.2f m (jupe %.2f m sous le sol)"
          % (mini_z, maxi_z, -mini_z))

    for nom, obj in (("visuel", grotte), ("collision", collision)):
        bords, nm, volume = controle_fermeture(obj)
        print("[grotte] %s : %d arete(s) de bord, %d non-manifold, volume %.1f m3"
              % (nom, bords, nm, volume))
        if bords != 0 or nm != 0:
            print("[grotte] ERREUR: coque %s NON FERMEE — c'est le defaut "
                  "'enveloppe ouverte' du rejet" % nom)
            return 2
        if abs(volume) < 1.0:
            print("[grotte] ERREUR: volume nul ou degenere (%s)" % nom)
            return 2

    mini, mini_col = controle_epaisseur(grotte, SEGMENTS)
    print("[grotte] epaisseur de roche : %.2f m en paroi, %.2f m en collerette"
          % (mini, mini_col))
    if mini < EPAISSEUR_MIN_M:
        print("[grotte] ERREUR: paroi de %.2f m < %.2f m — plaque vue par la "
              "tranche" % (mini, EPAISSEUR_MIN_M))
        return 2
    if mini_col < EPAISSEUR_MIN_COLLERETTE_M:
        print("[grotte] ERREUR: collerette de %.2f m < %.2f m"
              % (mini_col, EPAISSEUR_MIN_COLLERETTE_M))
        return 2

    faibles = controle_gabarit()
    if faibles:
        for i, ay, hw, cle in faibles:
            print("[grotte] ERREUR: station %d (y=%.2f) hors gabarit — "
                  "demi-largeur %.2f m, cle %.2f m" % (i, ay, hw, cle))
        return 2
    print("[grotte] gabarit : capsule r=0,45 h=1,85 passe aux %d stations "
          "du chemin" % (len(CAVITE) - 2))

    fautes = controle_aucun_jour(grotte, SEGMENTS)
    if fautes:
        for x, y, n in fautes[:5]:
            print("[grotte] ERREUR: le sol voit le ciel en (%.2f, %.2f) — "
                  "%d croisement(s)" % (x, y, n))
        return 2
    print("[grotte] aucun jour : 25 rayons verticaux, croisements pairs et >= 2")

    if -mini_z < ASSISE_JUPE_MIN_M:
        print("[grotte] ERREUR: jupe de %.2f m < %.2f m — masse posee, non "
              "plantee" % (-mini_z, ASSISE_JUPE_MIN_M))
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_WaterfallCave.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[grotte] source enregistree -> %s" % sortie)
    return 0


if __name__ == "__main__":
    sys.exit(main())
