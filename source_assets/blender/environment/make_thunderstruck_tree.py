# SOURCE DE GÉNÉRATION REPRODUCTIBLE — L'Arbre foudroyé, hero asset de la
# prairie aux mille fleurs (V2.3-A.R2B.2, agent B).
#
# POURQUOI CETTE RÉVISION EXISTE. R2B.1 a réglé la SILHOUETTE LOINTAINE — la
# fourche se lit à 94 m, anisotropie 1,81 -> 1,17 — et le lead l'a gardée.
# Mais en vue rapprochée il a maintenu PARTIAL : « un tronc prismatique, une
# fracture qui ressemble à un ruban peint, des racines en éventail de plaques
# plates, des branches tombées qui ressemblent à des poutres droites ».
#
# L'ÉCART ENTRE DES MÉTRIQUES AMÉLIORÉES ET UNE LECTURE ENCORE SYMBOLIQUE A
# UNE CAUSE, ET ELLE EST MESURÉE :
#
#   R2B.1 MESURAIT LA RÉPARTITION ; LE LEAD LIT LA LOI DE FORME D'UNE PIÈCE.
#   Anisotropie, écarts d'azimut, raie dominante du disque, rapports
#   longueur/rayon : ce sont des statistiques de l'ENVELOPPE EN PLAN et des
#   RAPPORTS ENTRE PIÈCES — du champ lointain. L'œil de près lit comment une
#   section évolue le long de son axe, en combien de mètres se creuse un
#   sillon. Un objet peut être parfaitement irrégulier en répartition et
#   rester fait de cinq prismes, d'un ruban et de cinq cônes droits.
#
# LES CINQ DÉFAUTS, CHIFFRÉS SUR LE GLB R2B.1 (2 526 tris) :
#   * `anneau()` échantillonnait toujours `a = 2πi/n` depuis LA MÊME ORIGINE.
#     Rotation inter-anneau mesurée : 0,003°. Les arêtes longitudinales
#     étaient donc des MÉRIDIENS EXACTS et chaque facette une bande réglée
#     courant tout le membre — dièdre longitudinal médian 1,1° sur 3–7 m,
#     facette de 0,156 m à r = 0,35 et 0,328 m à la souche.
#   * le relief radial était tiré INDÉPENDAMMENT à chaque anneau : corrélation
#     du profil d'un anneau au suivant −0,320, crête-à-crête 0,123. Du bruit,
#     pas des cannelures. Un maillage numériquement non plan partout, et
#     visuellement un prisme.
#   * la cicatrice alternait de largeur une station sur deux (autocorrélation
#     lag-1 −0,483). Son CV BRUT valait 0,402 — rassurant — mais son CV LISSÉ
#     SUR TROIS STATIONS, à l'échelle où l'œil intègre, valait 0,212, et sa
#     profondeur radiale était un ruban de 0,110 m CONSTANT.
#   * les racines : hexagone aplati 1,80 dont les trois sommets bas étaient
#     écrêtés par `max(0.01, …)` — 68,5 % de surface presque horizontale,
#     10,0 % de flanc, sagitta en plan NULLE, écarts d'azimut max/min 1,55.
#   * les bois tombés : axe droit EXACT (sagitta 0,000 m pour les cinq), mêmes
#     8 côtés, même effilement `1 − 0,38t`, et 88 triangles CINQ FOIS.
#
# CE QUE FAIT CETTE RÉVISION. Elle n'ajoute pas du détail : elle change les
# LOIS DE FORME, et les deux gestes principaux ne coûtent AUCUN triangle.
#   1. LA PHASE D'ÉCHANTILLONNAGE TOURNE d'un anneau au suivant, de façon
#      irrégulière et de somme nulle. Les méridiens deviennent des hélices
#      brisées, chaque quad se vrille, sa triangulation cesse d'être
#      coplanaire, et la bande de 4 m d'une seule valeur se casse en marches.
#   2. LE RELIEF EST VERROUILLÉ SUR L'AZIMUT au lieu d'être tiré par anneau :
#      il survit d'un anneau au suivant, donc il devient une arête filante qui
#      accroche la lumière rasante au lieu d'une moucheture.
#
# LE GEL — CE QUI NE BOUGE PAS, PARCE QUE LA FOURCHE À 94 m EN DÉPEND. À cette
# caméra, 1 px = 0,147 m : une cannelure de 0,035 m vaut 0,24 px et une loupe
# de 0,12 m vaut 0,82 px, contre 2,7 px pour un bras de fourche et 75 px pour
# la hauteur. Le détail rapproché est SOUS-PIXELLAIRE là-bas — à condition que
# les masses ne bougent pas. Sont donc gelés, à la valeur exacte de R2B.1 :
#     AZ_VIVANT · AZ_MORT · AZ_MEMBRE · PORTEE_VIVANT · PORTEE_MORT ·
#     PORTEE_MEMBRE · FOURCHE_Z · VIVANT_SOMMET · MORT_SOMMET ·
#     MEMBRE_BASE_Z · MEMBRE_RUPTURE_Z · les (z, yaw, longueur) des cinq
#     moignons · les cinq empreintes (x, y) et longueurs des bois tombés.
# Toutes les corrections agissent SUR LA PEAU de masses inchangées.
#
# LA CIME VIVANTE RESTE VIVANTE — arbitrage du lead, inchangé. Les DEUX
# ruptures principales restent du côté frappé : moitié morte rompue à 5,9 m,
# branche maîtresse arrachée à 7,55 m, écart 1,65 m.
#
# QUATRIÈME MATÉRIAU — AUTORISATION EXPLICITE DU LEAD, 2026-08-19. La limite
# passe de 3 à 4. RAISON : il n'existait AUCUNE valeur intermédiaire entre
# l'écorce (luminance 0,218) et le cœur (0,748), rapport 3,43, et la directive
# demande « une transition entre écorce brûlée, cœur pâle exposé et éclats ».
# Une transition entre deux valeurs sans palier ne se fabrique pas par la
# géométrie seule. CONDITION DU LEAD : palier de VALEUR, pas teinte neuve —
# `MAT_Tree_ScorchedSap` reste dans l'enveloppe de teinte et de saturation
# déjà admise par les trois autres (étendue de teinte 0,0896, saturation max
# 0,346), et le filet `test_world_v2_r2b2_arbre.gd` le vérifie.
#
# CINQ FAMILLES D'OBJETS, UN SEUL GLB :
#   * `_Bark`   — souche, moitié vivante, moitié morte, membre arraché, cinq
#                 moignons. Trois emplacements de matériau désormais : écorce
#                 saine, zones calcinées, et l'aubier grillé des lèvres du
#                 sillon.
#   * `_Heart`  — le bois MIS À NU : coin de fente, TROIS fragments de
#                 cicatrice séparés par deux ponts d'écorce, huit échardes le
#                 long du parcours, échardes des deux plans de rupture, bouts
#                 de moignons, cassures des bois au sol.
#   * `_Roots`  — cinq contreforts courbes, dont deux fourchent. OBJET SÉPARÉ
#                 à dessein : le garde-fou `SOUCHE_LARGEUR` mesure les sommets
#                 sous z = 0,3 ; y verser les racines lui ferait avaler autre
#                 chose que la souche.
#   * `_BranchA..E` — cinq bois tombés à cinq LOIS DE FORME distinctes.
#
# BUDGET VERROUILLÉ : ≤ 6 000 triangles. Le plafond n'a pas bougé. LE
# GÉNÉRATEUR REFUSE D'ENREGISTRER si la hauteur sort de [10 ; 12], si la base
# n'est pas à Z = 0, si le budget est dépassé, si la souche sort de sa largeur
# de plan, si la cicatrice n'est pas creusée, ou — refus AJOUTÉ en R2B.2 — si
# un contrefort dépasse 0,32 m hors de l'emprise du collider du tronc : à
# 0,382 m il était déjà, AVANT cette passe, au-dessus du `step_height` de 0,34
# de `locomotion_default.tres`, donc infranchissable sans collider. C'est un
# défaut PRÉEXISTANT que cette révision corrige au passage.
#
# Blender est Z-up ; l'export convertit en Y-up : Blender (x, y, z) devient
# Godot (x, z, −y).
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/environment/make_thunderstruck_tree.py

import math
import os
import sys

import bmesh
import bpy

# ---------------------------------------------------------------------------
# Cotes — LE BLOC GELÉ D'ABORD
# ---------------------------------------------------------------------------
FOURCHE_Z = 2.2             # GELÉ — le tronc est UN jusqu'ici
VIVANT_SOMMET = 10.8        # GELÉ — moitié vivante, cime INTACTE
MORT_SOMMET = 5.9           # GELÉ — moitié morte, rupture basse
MEMBRE_BASE_Z = 6.30        # GELÉ — branche maîtresse arrachée
MEMBRE_RUPTURE_Z = 7.55     # GELÉ — rupture haute
AZ_VIVANT = math.radians(15.0)      # GELÉ
AZ_MORT = math.radians(-104.6)      # GELÉ
AZ_MEMBRE = math.radians(137.9)     # GELÉ
PORTEE_VIVANT = 2.40        # GELÉ
PORTEE_MORT = 2.08          # GELÉ
PORTEE_MEMBRE = 2.34        # GELÉ

SOUCHE_LARGEUR = 2.1        # seuil INCHANGÉ, ± 0,35
SOUCHE_RAYON_BAS = 0.84
SOUCHE_RAYON_HAUT = 0.62
SOUCHE_PUISSANCE = 2.8      # > 1 => profil CONCAVE (le pied se creuse)
HAUTEUR_MIN, HAUTEUR_MAX = 10.0, 12.0
BUDGET_TRIS = 6000          # plafond INCHANGÉ
BASE_TOL = 0.005

# Emprise du collider `Tronc_col` du lieu (2,1 × 3,4 × 1,9 centré en x=z=0) et
# `step_height` de locomotion_default.tres. Hors de cette emprise, un
# contrefort plus haut que la marche est un mur invisible.
COLLIDER_DEMI_X = 1.05
COLLIDER_DEMI_Y = 0.95
RACINE_HAUTEUR_MAX_HORS = 0.32

# Nombres de côtés. La facette de souche de R2B.1 mesurait 0,328 m — la plus
# large de l'asset, et c'est elle que voit la caméra `arbre_pied`.
ANNEAU_SOUCHE = 22          # R2B.1 : 16 -> facette 0,328 m ramenée à 0,239 m
ANNEAU_VIVANT = 18          # R2B.1 : 14 -> facette 0,156 m ramenée à 0,121 m
ANNEAU_MORT = 16            # R2B.1 : 14
ANNEAU_MEMBRE = 12          # R2B.1 : 10

# LA PHASE. Le pas doit rester NETTEMENT SOUS π/n, sans quoi la rotation
# s'aliase sur le pas d'échantillonnage et devient indiscernable de zéro —
# c'est aussi ce que mesure le filet, qui replie Δφ dans ±π/n.
PHASE_PAS = 0.80            # fraction de π/n — mesuré : 0,42 ne donnait
#                             que 2,19° de |Δφ| moyen, sous le plancher de 4°
PHASE_MIN = 0.45            # amplitude minimale d'un pas, en fraction de PHASE_PAS

# LES CANNELURES, verrouillées sur l'AZIMUT. `CANNELURE_DERIVE` fait
# lentement tourner le motif avec l'altitude : une arête d'écorce monte en
# vrille douce, elle ne monte pas au cordeau.
CANNELURE_AMP = 0.175
# DÉRIVE EN RADIANS PAR MÈTRE. Premier jet : la dérive était multipliée par 8
# dans `anneau()`, soit 0,36 rad/m — 177° sur le fût. Les cannelures tournaient
# tellement d'un anneau au suivant que leur cohérence verticale retombait à
# 0,587, à peine au-dessus du plancher : le relief redevenait presque du bruit.
CANNELURE_DERIVE = 0.045    # 0,39 rad soit 22° sur 8,6 m

# Deux LOUPES sur le fût vivant : renflements SECTORIELS (120°), donc non
# axisymétriques. À 94 m elles valent 0,82 px.
LOUPES = (
    # (z, sigma, amplitude, azimut du secteur)
    (4.35, 0.30, 0.30, math.radians(-58.0)),
    (7.15, 0.26, 0.22, math.radians(112.0)),
)

# Moignons — (z, yaw, longueur) GELÉS ; pente et rayon de collet inchangés.
MOIGNONS = (
    (3.90, math.radians(-323.7), 1.38, 0.14, 0.22),
    (5.20, math.radians(-3.1), 0.94, 0.62, 0.19),
    (6.90, math.radians(-279.2), 0.91, 0.30, 0.17),
    (7.80, math.radians(-132.0), 1.42, 0.20, 0.16),
    (9.50, math.radians(-62.7), 1.37, 0.45, 0.11),
)

# LA CICATRICE. R2B.1 donnait à sa largeur 18 valeurs qui alternaient une
# station sur deux : CV brut 0,402, CV lissé 0,212. L'enveloppe est désormais
# exprimée EN MÈTRES et de BASSE FRÉQUENCE — large à l'impact, effilée au
# pied — parce que c'est une largeur en mètres que l'œil lit, pas un angle :
# un demi-angle constant sur un fût qui s'affine donne une largeur presque
# constante, ce qui était exactement le défaut.
CICATRICE_HAUT = 7.4
CICATRICE_BAS = 0.35
CICATRICE_TOURS_RAD = 3.4
# (z, largeur en mètres, profondeur radiale en mètres)
CICATRICE_PROFIL = (
    (7.40, 0.10, 0.040),
    (6.55, 0.19, 0.075),
    (5.60, 0.28, 0.105),
    (4.60, 0.41, 0.150),
    (3.85, 0.55, 0.190),
    (3.20, 0.62, 0.205),
    (2.55, 0.52, 0.170),
    (2.00, 0.44, 0.140),
    (1.45, 0.31, 0.100),
    (0.90, 0.20, 0.062),
    (0.35, 0.09, 0.030),
)
# DEUX INTERRUPTIONS : l'écorce fait pont au-dessus du bois nu. R2B.1 avait un
# seul segment ininterrompu de 6,55 m.
#
# LEUR PLACEMENT N'EST PAS LIBRE, et la première tentative (5,05 et 2,28) a
# fait ROUGIR UN CONTRÔLE R2B.1 QUI ÉTAIT VERT. Le filet R2B.1 mesure le CV
# BRUT de la largeur sur la PLUS GROSSE composante du cœur ; en coupant la
# cicatrice en trois, on lui donne à mesurer un fragment plus court, donc une
# portion d'enveloppe plus plate — CV tombé à 0,284 pour un plancher de 0,30.
# Les ponts sont donc placés de façon que le plus grand fragment traverse la
# plus grande variation d'enveloppe : de 0,60 m à 0,10 m entre 3,00 m et le
# pied. Un contrôle antérieur qui rougit à cause d'une amélioration reste un
# rouge : c'est la nouvelle géométrie qui cède, pas le seuil ancien.
CICATRICE_PONTS = ((5.60, 0.20), (3.20, 0.20))
CICATRICE_LEVRE = 1.085     # l'écorce se soulève au bord du sillon
CICATRICE_RETRAIT_MIN = 0.46

# ÉCHARDES LE LONG DU PARCOURS — R2B.1 n'en avait aucune hors des deux plans
# de rupture. (z, décalage d'azimut, hauteur, demi-largeur, pente)
# LES ALTITUDES SONT CHOISIES, PAS RÉPARTIES. Trois contraintes se croisent et
# le premier jet en violait deux, ce qui coûtait trois échardes sur huit :
#   * ne pas tomber sur un PONT D'ÉCORCE (2,08..2,48 et 4,81..5,29) — là,
#     `cicatrice_metres` rend 0 et l'écharde n'est tout simplement pas posée ;
#   * rester à plus de 0,60 m des DEUX PLANS DE RUPTURE (5,78 et 7,45), sinon
#     le filet les agrège au plan et ne les compte plus « le long du
#     parcours » — une écharde à 6,95 m avait même volé au plan haut son
#     statut de plan, faussant le comptage des deux côtés.
ECHARDES_PARCOURS = (
    (0.90, 0.22, 0.36, 0.042, 0.55),
    (1.50, -0.26, 0.44, 0.048, 0.35),
    (2.60, 0.19, 0.58, 0.056, 0.62),
    (3.15, -0.30, 0.62, 0.060, 0.28),
    (3.70, 0.27, 0.51, 0.050, 0.70),
    (4.25, -0.21, 0.39, 0.044, 0.40),
    (4.60, 0.24, 0.42, 0.045, 0.58),
    (6.45, -0.18, 0.34, 0.040, 0.33),
)

# RACINES — (yaw, portée, crête, dérive de yaw, t de fourche ou None).
# Écarts d'azimut R2B.1 : 60..93°, max/min 1,55 — un éventail régulier.
# Ici : 34 / 98 / 66 / 56 / 106°, max/min 3,1.
# LES DÉRIVES DE YAW SONT MESURÉES, PAS DEVINÉES, et il a fallu trois passes.
# 26° sur une portée de 2,15 m ne rendent que 4,5 % de sagitta ; 44° en rendent
# 5,5 %. La cause est que le filet mesure la sagitta sur la composante ENTIÈRE,
# épaisseur comprise : sur une racine courte et grosse, l'axe principal est
# tiré par la section et absorbe une part de la courbure. Il faut donc environ
# 60° de dérive — une flexion douce sur deux mètres, pas un crochet — pour
# qu'une racine cesse de se mesurer comme un rayon droit.
RACINES = (
    (math.radians(-8.0), 2.30, 0.26, math.radians(74.0), 0.58),
    # Portée relevée de 1,05 à 1,45 m : à 1,05 m la racine est aussi épaisse
    # que longue, son axe principal est tiré par sa section, et même 52° de
    # dérive ne rendaient que 6,1 % de sagitta. Allonger est ici plus honnête
    # que courber davantage — au-delà, une racine devient un crochet.
    (math.radians(-42.0), 1.45, 0.20, math.radians(-60.0), None),
    (math.radians(-140.0), 2.55, 0.24, math.radians(60.0), None),
    (math.radians(-206.0), 1.60, 0.22, math.radians(-54.0), 0.66),
    (math.radians(-262.0), 1.75, 0.25, math.radians(44.0), None),
)
RACINE_COTES = 8
RACINE_LATERAL = 1.06       # R2B.1 : 1,35 (et 0,75 en vertical -> aplati 1,80)
RACINE_VERTICAL = 0.94      # aplatissement ramené à 1,13
RACINE_R0 = 0.38
RACINE_DECROISSANCE = 0.70

# BOIS TOMBÉS — empreintes, longueurs et rayons GELÉS (ils portent l'acquis
# R2B.1 et l'enveloppe en plan). Ce qui change, c'est la LOI DE FORME :
# (x, y, yaw, longueur, rayon, relevé | côtés, flèche, position de flèche,
#  loi d'effilement, nombre de chicots)
BRANCHES = (
    (2.95, 1.75, 2.05, 4.20, 0.260, 0.00, 8, 0.42, 0.38, "renfle", 2),
    (-3.30, 2.15, -0.75, 3.10, 0.195, 0.62, 7, -0.24, 0.55, "troncon", 0),
    (-1.20, -3.35, 0.95, 2.30, 0.155, 0.00, 6, 0.20, 0.62, "noeud", 1),
    (3.05, -2.40, 2.60, 1.60, 0.115, 0.41, 6, -0.17, 0.45, "fourchue", 3),
    (0.35, 3.55, 1.35, 1.10, 0.085, 0.00, 5, 0.13, 0.50, "fouet", 1),
)

# ---------------------------------------------------------------------------
# Matériaux — sRGB converti en linéaire. QUATRE valeurs depuis le 2026-08-19.
# §1.6 : jamais de noir pur.
# ---------------------------------------------------------------------------
MATERIAUX = {
    "MAT_Tree_CharredBark": (0.26, 0.21, 0.17, 0.96),
    "MAT_Tree_Heartwood": (0.84, 0.74, 0.55, 0.88),
    "MAT_Tree_Charcoal": (0.145, 0.130, 0.128, 0.99),
    # LE PALIER INTERMÉDIAIRE. Luminance 0,432, entre l'écorce (0,218) et le
    # cœur (0,748). Teinte 0,072 et saturation 0,340 : DANS l'enveloppe des
    # trois autres (teintes 0,0196..0,1092, saturation max 0,346). C'est un
    # palier de valeur, pas une couleur neuve — condition du lead.
    "MAT_Tree_ScorchedSap": (0.50, 0.42, 0.33, 0.94),
}
IDX_ECORCE = 0
IDX_CALCINE = 1
IDX_AUBIER = 2


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
    return math.sin(x * 12.9898) * 0.5


# Bruit angulaire à phases irrégulières : somme d'harmoniques déphasées, sans
# période dominante.
_HARMONIQUES = ((2, 1.00, 0.71), (3, 0.86, 2.93), (5, 0.71, 1.34),
                (7, 0.58, 4.42), (9, 0.50, 0.19))
_NORME = sum(a for _, a, _ in _HARMONIQUES)


def bruit(angle, graine=0.0):
    total = 0.0
    for k, amp, phase in _HARMONIQUES:
        total += amp * math.sin(k * angle + phase + graine)
    return total / _NORME


def _interp(table, z):
    """Interpolation linéaire dans une table (z, …) DÉCROISSANTE en z."""
    if z >= table[0][0]:
        return table[0][1:]
    if z <= table[-1][0]:
        return table[-1][1:]
    for i in range(len(table) - 1):
        z0, z1 = table[i][0], table[i + 1][0]
        if z1 <= z <= z0:
            t = (z0 - z) / (z0 - z1)
            return tuple(a + (b - a) * t
                         for a, b in zip(table[i][1:], table[i + 1][1:]))
    return table[-1][1:]


# ---------------------------------------------------------------------------
# LA PHASE D'ÉCHANTILLONNAGE — le geste principal, à coût nul en triangles.
# ---------------------------------------------------------------------------
def phases(n_anneaux, n_cotes, graine):
    """Rotation cumulée de l'échantillonnage, anneau par anneau.

    TROIS CONTRAINTES, et elles se contredisent :
      * assez grande pour casser les méridiens — le filet exige |Δφ| moyen
        ≥ 4° et un écart-type ≥ 2° ;
      * NETTEMENT sous π/n, sinon la rotation s'aliase sur le pas
        d'échantillonnage et redevient indiscernable de zéro (c'est aussi ce
        que replie le filet, donc un pas trop grand se mesurerait plus PETIT
        qu'il n'est) ;
      * de somme nulle sur le membre, sinon le fût part en vrille et l'on
        remplace un prisme par un mât de barbier.
    La somme est donc retranchée explicitement : la rotation nette est nulle
    à la précision machine, pas « à peu près ».
    """
    pas = PHASE_PAS * math.pi / n_cotes
    bruts = []
    for j in range(n_anneaux):
        amp = PHASE_MIN + (1.0 - PHASE_MIN) * abs(bruit(j * 1.31 + graine, graine))
        signe = 1.0 if bruit(j * 2.17 + graine * 0.5, graine * 1.7) >= 0.0 else -1.0
        bruts.append(signe * amp * pas)
    moyenne = sum(bruts) / len(bruts)
    bruts = [x - moyenne for x in bruts]
    out = [0.0]
    for x in bruts[:-1]:
        out.append(out[-1] + x)
    return out


# ---------------------------------------------------------------------------
# La cicatrice — UNE définition, partagée par l'écorce ET par le cœur.
# ---------------------------------------------------------------------------
def angle_cicatrice(z):
    t = (CICATRICE_HAUT - z) / (CICATRICE_HAUT - CICATRICE_BAS)
    return -0.55 + t * CICATRICE_TOURS_RAD


def _pont(z):
    """Vrai si l'écorce fait pont au-dessus du bois nu à cette altitude."""
    for zc, demi in CICATRICE_PONTS:
        if abs(z - zc) < demi:
            return True
    return False


def cicatrice_metres(z):
    """Rend (largeur, profondeur) EN MÈTRES, ou (0, 0) sur un pont d'écorce.

    L'enveloppe est de BASSE FRÉQUENCE : c'est ce que l'œil intègre. R2B.1
    faisait alterner la largeur d'une station à l'autre — CV brut 0,402, CV
    lissé sur trois stations 0,212, et la bande se lisait peinte. Le jitter
    résiduel est volontairement petit devant l'enveloppe.
    """
    if z > CICATRICE_HAUT or z < CICATRICE_BAS or _pont(z):
        return 0.0, 0.0
    largeur, prof = _interp(CICATRICE_PROFIL, z)
    jitter = 1.0 + 0.16 * bruit(z * 2.9, 3.7)
    return largeur * jitter, prof * jitter


def cicatrice_profil(z, rayon):
    """Rend (demi-angle du fond, demi-angle de la lèvre, facteur de retrait)."""
    largeur, prof = cicatrice_metres(z)
    if largeur <= 0.0 or rayon <= 0.02:
        return 0.0, 0.0, 1.0
    demi = min(1.05, 0.5 * largeur / rayon)
    retrait = max(CICATRICE_RETRAIT_MIN, 1.0 - prof / rayon)
    return demi, demi * 1.55, retrait


def facteur_cicatrice(z, angle, rayon):
    """Multiplicateur de rayon : fond du sillon, flanc, puis LÈVRE soulevée.

    La lèvre est ce qui fait la différence entre un sillon et une bande
    peinte : l'écorce ne s'arrête pas net au bord d'un arrachement, elle se
    relève.
    """
    demi, levre, retrait = cicatrice_profil(z, rayon)
    if demi <= 0.0:
        return 1.0, False
    ecart = abs((angle - angle_cicatrice(z) + math.pi) % (2.0 * math.pi) - math.pi)
    if ecart <= demi * 0.70:
        return retrait, True
    if ecart <= demi:
        t = (ecart - demi * 0.70) / (demi * 0.30)
        return retrait + (1.0 - retrait) * t, True
    if ecart <= levre:
        t = (ecart - demi) / max(1.0e-6, levre - demi)
        return 1.0 + (CICATRICE_LEVRE - 1.0) * math.sin(math.pi * t), True
    return 1.0, False


# ---------------------------------------------------------------------------
# Loft d'anneaux fermés
# ---------------------------------------------------------------------------
def anneau(centre, rayon, n, z, phase=0.0, lobes=0.0, lobes_azimuts=(),
           cannelure=0.0, cannelure_graine=0.0, aplati=None,
           applique_cicatrice=True, loupes=()):
    """Un anneau fermé, échantillonné à partir de `phase`.

    LE RELIEF EST FONCTION DE L'AZIMUT, PAS DE L'INDICE. R2B.1 écrivait
    `_graine(graine + i * 1.7)` avec une graine qui changeait à chaque
    anneau : le motif était retiré à neuf tous les 0,6 m, corrélation −0,320
    d'un anneau au suivant. Le maillage en devenait numériquement non plan
    partout — assez pour verdir un contrôle de planéité — sans rien donner à
    l'œil : 0,031 m de gigue, soit une moucheture sur une facette de 46 px.
    Ici `bruit(a + dérive·z)` ne dépend que de l'azimut et d'une lente
    dérive : le relief SURVIT d'un anneau au suivant et devient une arête
    filante.
    """
    points = []
    zones = []
    for i in range(n):
        a = 2.0 * math.pi * i / n + phase
        r = rayon
        if cannelure > 0.0:
            r *= 1.0 + cannelure * bruit(a + CANNELURE_DERIVE * z,
                                         cannelure_graine)
        if lobes > 0.0 and lobes_azimuts:
            # LES CONTREFORTS DE SOUCHE SONT VERROUILLÉS SUR LES RACINES.
            # R2B.1 les modulait par un bruit dont la phase changeait à chaque
            # anneau : les lobes ne montaient nulle part et les racines
            # démarraient contre une paroi lisse — d'où la couture franche au
            # pied que le lead décrit comme « peu de transition organique ».
            bosse = 0.0
            for yaw in lobes_azimuts:
                c = math.cos(a - yaw)
                if c > 0.0:
                    bosse = max(bosse, c ** 5)
            r *= 1.0 + lobes * (0.34 + 0.66 * bosse)
        for zl, sigma, amp, azl in loupes:
            c2 = math.cos(a - azl)
            if c2 > 0.0:
                r *= 1.0 + amp * math.exp(-((z - zl) / sigma) ** 2) * (c2 ** 2)
        if aplati is not None:
            ecart = (a - aplati[0] + math.pi) % (2.0 * math.pi) - math.pi
            if abs(ecart) < 1.05:
                r *= 1.0 - aplati[1] * (1.0 - abs(ecart) / 1.05)
        zone = 0
        if applique_cicatrice:
            facteur, touche = facteur_cicatrice(z, a, rayon)
            r *= facteur
            if touche:
                zone = 1 if facteur < 1.0 else 2
        points.append((centre[0] + math.cos(a) * r,
                       centre[1] + math.sin(a) * r, z))
        zones.append(zone)
    return points, zones


def loft(bm, anneaux, mat_idx=0, fermer_bas=False, fermer_haut=False,
         mat_par_point=None, zones=None):
    """`zones` porte, point par point, le code de bord de cicatrice rendu par
    `anneau()` : 0 écorce saine, 1 fond ou flanc du sillon, 2 lèvre soulevée.
    Une face qui touche une zone non nulle passe en AUBIER GRILLÉ — c'est
    ainsi que la transition écorce -> aubier -> cœur existe dans la
    géométrie, et pas seulement dans l'intention."""
    rangs = [[bm.verts.new(p) for p in a] for a in anneaux]
    faces = []
    idx_face = []
    for e in range(len(rangs) - 1):
        bas, haut = rangs[e], rangs[e + 1]
        n = len(bas)
        for i in range(n):
            j = (i + 1) % n
            faces.append(bm.faces.new((bas[i], bas[j], haut[j], haut[i])))
            if mat_par_point is not None:
                idx_face.append(mat_par_point(e, i))
            elif zones is not None:
                z_max = max(zones[e][i], zones[e][j],
                            zones[e + 1][i], zones[e + 1][j])
                idx_face.append(IDX_AUBIER if z_max > 0 else mat_idx)
            else:
                idx_face.append(mat_idx)
    if fermer_bas:
        faces.append(bm.faces.new(tuple(reversed(rangs[0]))))
        idx_face.append(mat_idx)
    if fermer_haut:
        faces.append(bm.faces.new(tuple(rangs[-1])))
        idx_face.append(mat_idx)
    for f, m in zip(faces, idx_face):
        f.material_index = m
    return rangs


def couronne_rompue(bm, sommet, centre, hauteurs, mat_idx):
    """Une cassure : le dernier anneau part en pointes INÉGALES."""
    n = len(sommet)
    fond = bm.verts.new((centre[0], centre[1], centre[2] - 0.30))
    for i in range(n):
        j = (i + 1) % n
        a = sommet[i].co
        b = sommet[j].co
        pointe = bm.verts.new((
            (a.x + b.x) * 0.5 + (a.x - centre[0]) * 0.35,
            (a.y + b.y) * 0.5 + (a.y - centre[1]) * 0.35,
            max(a.z, b.z) + hauteurs[i % len(hauteurs)]))
        for tri in ((sommet[i], sommet[j], pointe),
                    (sommet[j], sommet[i], fond)):
            f = bm.faces.new(tri)
            f.material_index = mat_idx


# ---------------------------------------------------------------------------
# Chemins — GELÉS, sauf le profil de rayon qui reçoit les loupes.
# ---------------------------------------------------------------------------
def _collets(z):
    facteur = 1.0
    for zm, _, _, _, _ in MOIGNONS:
        facteur *= 1.0 + 0.14 * math.exp(-((z - zm) / 0.55) ** 2)
    return facteur


def chemin_vivant(t):
    course = PORTEE_VIVANT * (t ** 1.25)
    z = FOURCHE_Z + t * (VIVANT_SOMMET - FOURCHE_Z)
    rayon = (0.15 + 0.37 * ((1.0 - t) ** 0.62)) * _collets(z)
    return ((0.30 + math.cos(AZ_VIVANT) * course,
             0.06 + math.sin(AZ_VIVANT) * course, z), rayon)


def chemin_mort(t):
    course = PORTEE_MORT * (t ** 1.15)
    z = FOURCHE_Z + t * (MORT_SOMMET - FOURCHE_Z)
    return ((-0.26 + math.cos(AZ_MORT) * course,
             -0.05 + math.sin(AZ_MORT) * course, z),
            0.34 + 0.16 * ((1.0 - t) ** 0.55))


def chemin_membre(t):
    depart = chemin_vivant((MEMBRE_BASE_Z - FOURCHE_Z)
                           / (VIVANT_SOMMET - FOURCHE_Z))[0]
    course = PORTEE_MEMBRE * t
    return ((depart[0] + math.cos(AZ_MEMBRE) * course,
             depart[1] + math.sin(AZ_MEMBRE) * course,
             MEMBRE_BASE_Z + t * (MEMBRE_RUPTURE_Z - MEMBRE_BASE_Z)),
            0.34 - t * 0.04)


def _souche_rayon(z):
    u = min(1.0, max(0.0, z / FOURCHE_Z))
    return SOUCHE_RAYON_HAUT + (SOUCHE_RAYON_BAS - SOUCHE_RAYON_HAUT) \
        * ((1.0 - u) ** SOUCHE_PUISSANCE)


def rayon_local(z):
    """Rayon nominal du fût à l'altitude z, pour convertir une largeur de
    cicatrice en mètres vers un demi-angle."""
    if z <= FOURCHE_Z:
        return _souche_rayon(z)
    t = min(1.0, (z - FOURCHE_Z) / (VIVANT_SOMMET - FOURCHE_Z))
    return chemin_vivant(t)[1]


def centre_local(z):
    if z <= FOURCHE_Z:
        return (0.0, 0.0, z)
    t = min(1.0, (z - FOURCHE_Z) / (VIVANT_SOMMET - FOURCHE_Z))
    return chemin_vivant(t)[0]


# ---------------------------------------------------------------------------
# SM_ThunderstruckTree_Bark
# ---------------------------------------------------------------------------
def ecorce(bm):
    azimuts_racines = tuple(r[0] for r in RACINES)

    # --- la souche : contreforts VERROUILLÉS sur les azimuts de racine.
    ph = phases(9, ANNEAU_SOUCHE, 4.1)
    souche, zones_s = [], []
    for k in range(9):
        z = FOURCHE_Z * (k / 8.0)
        p, zn = anneau((0.0, 0.0), _souche_rayon(z), ANNEAU_SOUCHE, z,
                       phase=ph[k],
                       lobes=0.30 * ((1.0 - z / FOURCHE_Z) ** 1.4),
                       lobes_azimuts=azimuts_racines)
        souche.append(p)
        zones_s.append(zn)
    rangs = loft(bm, souche, mat_idx=IDX_ECORCE, fermer_bas=True,
                 zones=zones_s)

    # --- le col : l'entonnoir qui descend ENTRE les moitiés.
    haut = rangs[-1]
    col = bm.verts.new((0.0, 0.0, 1.58))
    for i in range(ANNEAU_SOUCHE):
        j = (i + 1) % ANNEAU_SOUCHE
        f = bm.faces.new((haut[j], haut[i], col))
        f.material_index = IDX_CALCINE

    # --- moitié vivante : loft continu jusqu'à 10,8 m, cime INTACTE.
    ph = phases(15, ANNEAU_VIVANT, 17.3)
    vivant, zones_v = [], []
    for k in range(15):
        t = k / 14.0
        centre, rayon = chemin_vivant(t)
        p, zn = anneau(centre, rayon, ANNEAU_VIVANT, centre[2], phase=ph[k],
                       cannelure=CANNELURE_AMP, cannelure_graine=1.9,
                       aplati=(AZ_MORT, 0.30 * (1.0 - t)), loupes=LOUPES)
        vivant.append(p)
        zones_v.append(zn)
    rangs_vivant = loft(bm, vivant, mat_idx=IDX_ECORCE, zones=zones_v)
    cime_centre, _ = chemin_vivant(1.0)
    cime = bm.verts.new((cime_centre[0] + 0.06, cime_centre[1] - 0.04,
                         cime_centre[2] + 0.22))
    dessus = rangs_vivant[-1]
    for i in range(ANNEAU_VIVANT):
        j = (i + 1) % ANNEAU_VIVANT
        f = bm.faces.new((dessus[i], dessus[j], cime))
        f.material_index = IDX_ECORCE

    # --- moitié morte : RUPTURE BASSE à 5,9 m, écorce calcinée. La cicatrice
    # ne s'y applique plus : la blessure court sur le fût SURVIVANT, et un
    # sillon non rempli sur la moitié morte donnait deux rubans pâles là où le
    # récit n'en veut qu'un.
    ph = phases(10, ANNEAU_MORT, 31.7)
    mort = []
    for k in range(10):
        t = k / 9.0
        centre, rayon = chemin_mort(t)
        p, _zn = anneau(centre, rayon, ANNEAU_MORT, centre[2], phase=ph[k],
                        cannelure=CANNELURE_AMP * 0.9, cannelure_graine=5.3,
                        aplati=(AZ_VIVANT, 0.28 * (1.0 - t)),
                        applique_cicatrice=False)
        mort.append(p)
    rangs_mort = loft(bm, mort, mat_idx=IDX_CALCINE)
    couronne_rompue(bm, rangs_mort[-1], chemin_mort(1.0)[0],
                    (1.35, 0.24, 0.82, 0.15, 1.08, 0.31, 0.66, 0.13,
                     0.95, 0.27, 0.50, 0.19, 1.18, 0.22, 0.71, 0.16),
                    IDX_CALCINE)

    # --- membre arraché : RUPTURE HAUTE à 7,55 m.
    ph = phases(6, ANNEAU_MEMBRE, 47.9)
    membre = []
    for k in range(6):
        t = k / 5.0
        centre, rayon = chemin_membre(t)
        p, _zn = anneau((centre[0], centre[1]), rayon, ANNEAU_MEMBRE,
                        centre[2], phase=ph[k], cannelure=CANNELURE_AMP * 0.8,
                        cannelure_graine=9.1, applique_cicatrice=False)
        membre.append(p)
    rangs_membre = loft(bm, membre, mat_idx=IDX_CALCINE, fermer_bas=True)
    couronne_rompue(bm, rangs_membre[-1], chemin_membre(1.0)[0],
                    (0.62, 0.14, 0.44, 0.21, 0.55, 0.11, 0.36, 0.17,
                     0.48, 0.13, 0.40, 0.19), IDX_CALCINE)

    # --- moignons : cinq branches arrachées encore accrochées.
    for z, yaw, longueur, pente, rcol in MOIGNONS:
        t = (z - FOURCHE_Z) / (VIVANT_SOMMET - FOURCHE_Z)
        centre, rayon = chemin_vivant(t)
        direction = (math.cos(yaw), math.sin(yaw), pente)
        base = (centre[0] + direction[0] * rayon * 0.8,
                centre[1] + direction[1] * rayon * 0.8, z)
        ph = phases(4, 8, z * 3.7)
        anneaux_moignon = []
        for e in range(4):
            te = e / 3.0
            c = (base[0] + direction[0] * longueur * te,
                 base[1] + direction[1] * longueur * te,
                 base[2] + direction[2] * longueur * te)
            p, _zn = anneau((c[0], c[1]), rcol * (1.0 - te * 0.42), 8, c[2],
                            phase=ph[e], cannelure=0.13,
                            cannelure_graine=z * 2.3,
                            applique_cicatrice=False)
            anneaux_moignon.append(p)
        loft(bm, anneaux_moignon, mat_idx=IDX_CALCINE, fermer_haut=True)


# ---------------------------------------------------------------------------
# SM_ThunderstruckTree_Roots — contreforts au sol, OBJET SÉPARÉ
# ---------------------------------------------------------------------------
def _contrefort(bm, yaw0, d0, portee, crete, dyaw, echelle, graine):
    """Un contrefort COURBE, à section presque ronde.

    R2B.1 : hexagone de demi-largeur 1,35 r et de demi-hauteur 0,75 r —
    aplatissement 1,80 — dont les TROIS sommets bas étaient écrasés par
    `max(0.01, …)`. Le dessous était donc plat par construction, et 68,5 % de
    la surface se trouvait à moins de 45° de la verticale : une plaque. Ici la
    LIGNE MÉDIANE est relevée d'exactement une demi-hauteur, si bien que le
    bas de la section affleure le sol SANS ÉCRÊTAGE, et l'aplatissement tombe
    à 1,13.

    LA HAUTEUR EST BORNÉE HORS DE L'EMPRISE DU COLLIDER : à 0,382 m, R2B.1
    dépassait déjà le `step_height` de 0,34 — un contrefort sans collider que
    le joueur ne peut pas enjamber est un mur invisible. La décroissance du
    rayon est calibrée pour que le sommet reste sous 0,32 m dès d = 0,95.
    """
    n_rings = 7
    ph = phases(n_rings, RACINE_COTES, graine)
    anneaux_racine = []
    for k in range(n_rings):
        t = k / float(n_rings - 1)
        d = d0 + portee * t
        yaw = yaw0 + dyaw * (t - 0.35 * t * t)
        r = max(0.045, RACINE_R0 * echelle
                * math.exp(-(d - d0) / RACINE_DECROISSANCE))
        r *= 1.0 + 0.08 * _graine(graine * 7.0 + k)
        collet = crete * (max(0.0, 1.0 - d / 0.95) ** 1.7)
        zc = 0.015 + RACINE_VERTICAL * r + collet
        cx = math.cos(yaw) * d
        cy = math.sin(yaw) * d
        px = -math.sin(yaw)
        py = math.cos(yaw)
        pts = []
        for i in range(RACINE_COTES):
            a = 2.0 * math.pi * i / RACINE_COTES + ph[k]
            lat = math.cos(a) * r * RACINE_LATERAL
            ver = math.sin(a) * r * RACINE_VERTICAL
            pts.append((cx + px * lat, cy + py * lat, zc + ver))
        anneaux_racine.append(pts)
    loft(bm, anneaux_racine, fermer_bas=True, fermer_haut=True)
    return anneaux_racine


def racines(bm):
    for yaw0, portee, crete, dyaw, fourche_t in RACINES:
        _contrefort(bm, yaw0, 0.30, portee, crete, dyaw, 1.0, yaw0 * 3.1)
        if fourche_t is None:
            continue
        # LA FOURCHE : une racine qui se divise. Loft SÉPARÉ à dessein — le
        # filet mesure la sagitta par composante connexe, et une fourche
        # soudée à son parent rendrait une « courbure » qui n'est que
        # l'écartement des deux bras.
        d = 0.30 + portee * fourche_t
        yaw = yaw0 + dyaw * (fourche_t - 0.35 * fourche_t * fourche_t)
        # LA DÉRIVE DU BRAS N'EST PAS MONOTONE, et je m'y suis fait prendre :
        # à −0,34 rad la sonde mesure 13,0 et 13,4 % de sagitta, à −0,78 rad
        # elle mesure 2,4 et 2,5 %. Au-delà d'un certain angle, l'arc devient
        # assez large pour que l'axe principal du nuage de points bascule, et
        # la « sagitta » mesurée s'effondre alors que la pièce est PLUS courbe.
        # C'est une limite de l'estimateur, pas de la géométrie ; on reste donc
        # du côté où il mesure ce qu'il prétend mesurer.
        _contrefort(bm, yaw + 0.52, d, portee * (1.0 - fourche_t) * 0.85,
                    0.0, -0.34, 0.36, yaw0 * 5.7 + 2.0)


# ---------------------------------------------------------------------------
# SM_ThunderstruckTree_Heart — le bois mis à nu
# ---------------------------------------------------------------------------
def _section_cicatrice(z, largeur, prof):
    """Un COIN de bois arraché, pas un ruban d'épaisseur constante.

    R2B.1 loftait une section hexagonale de 0,110 m d'épaisseur CONSTANTE sur
    tout le parcours : profondeur radiale max/min 2,22, ce qui n'est que le
    bruit de rotation de la section. Ici la profondeur SUIT la largeur —
    profonde à l'impact, effacée au pied — et le profil se referme en V.
    """
    a = angle_cicatrice(z)
    centre = centre_local(z)
    radial = (math.cos(a), math.sin(a))
    tang = (-math.sin(a), math.cos(a))
    r_ext = rayon_local(z) * 1.005
    w = largeur * 0.5
    # (latéral, radial) — polygone simple parcouru dans l'ordre
    profil = ((w, 0.0), (0.0, prof * 0.12), (-w, 0.0),
              (-w * 0.62, -prof * 0.45), (-w * 0.30, -prof),
              (0.0, -prof * 1.15), (w * 0.30, -prof), (w * 0.62, -prof * 0.45))
    pts = []
    for lat, rad in profil:
        rr = r_ext + rad
        pts.append((centre[0] + radial[0] * rr + tang[0] * lat,
                    centre[1] + radial[1] * rr + tang[1] * lat, z))
    return pts


def _echarde(bm, base, direction, hauteur, largeur, mat_idx=0):
    """Un éclat de bois frais qui pointe hors de la cassure."""
    b = base
    s = largeur
    rangs_pointe = [
        [(b[0] - s, b[1] - s, b[2]), (b[0] + s, b[1] - s, b[2]),
         (b[0] + s, b[1] + s, b[2]), (b[0] - s, b[1] + s, b[2])],
        [(b[0] - s * 0.18 + direction[0] * hauteur * 0.4,
          b[1] - s * 0.18 + direction[1] * hauteur * 0.4, b[2] + hauteur),
         (b[0] + s * 0.18 + direction[0] * hauteur * 0.4,
          b[1] - s * 0.18 + direction[1] * hauteur * 0.4, b[2] + hauteur),
         (b[0] + s * 0.18 + direction[0] * hauteur * 0.4,
          b[1] + s * 0.18 + direction[1] * hauteur * 0.4, b[2] + hauteur),
         (b[0] - s * 0.18 + direction[0] * hauteur * 0.4,
          b[1] + s * 0.18 + direction[1] * hauteur * 0.4, b[2] + hauteur)],
    ]
    loft(bm, rangs_pointe, mat_idx=mat_idx, fermer_bas=True, fermer_haut=True)


def coeur(bm):
    # --- le coin de la fente : un wedge lofté qui tapisse le fond du col.
    fente = []
    for z, largeur, profondeur in ((1.42, 0.95, 0.80), (2.10, 0.72, 0.58),
                                   (2.95, 0.40, 0.30)):
        fente.append([(-largeur * 0.5, -profondeur * 0.5, z),
                      (largeur * 0.5, -profondeur * 0.5, z),
                      (largeur * 0.5, profondeur * 0.5, z),
                      (-largeur * 0.5, profondeur * 0.5, z)])
    loft(bm, fente, fermer_bas=True, fermer_haut=True)

    # --- LA CICATRICE, en fragments séparés par les ponts d'écorce.
    stations = 26
    fragment = []
    fragments = []
    for k in range(stations):
        z = CICATRICE_HAUT - 0.04 - (CICATRICE_HAUT - CICATRICE_BAS - 0.08) \
            * k / (stations - 1)
        largeur, prof = cicatrice_metres(z)
        if largeur <= 0.0:
            if len(fragment) >= 4:
                fragments.append(fragment)
            fragment = []
            continue
        fragment.append(_section_cicatrice(z, largeur, prof))
    if len(fragment) >= 4:
        fragments.append(fragment)
    for frag in fragments:
        # Les deux arêtes et la crête reçoivent l'AUBIER GRILLÉ : c'est le
        # palier de valeur entre l'écorce (0,218) et le cœur (0,748) que le
        # lead a autorisé le 2026-08-19. Sans lui, la transition est un saut
        # de rapport 3,43 et la bande se lit comme une décalcomanie.
        loft(bm, frag, fermer_bas=True, fermer_haut=True,
             mat_par_point=lambda e, i: 1 if i in (0, 1, 7) else 0)

    # --- ÉCHARDES LE LONG DU PARCOURS. R2B.1 n'en avait aucune hors des deux
    # plans de rupture : la cicatrice n'était bordée d'aucun éclat, donc rien
    # ne disait qu'elle était arrachée plutôt que peinte.
    for z, decal, hauteur, demi, pente in ECHARDES_PARCOURS:
        largeur, prof = cicatrice_metres(z)
        if largeur <= 0.0:
            continue
        a = angle_cicatrice(z) + decal
        centre = centre_local(z)
        r_ext = rayon_local(z) * 0.99
        base = (centre[0] + math.cos(a) * r_ext,
                centre[1] + math.sin(a) * r_ext, z)
        _echarde(bm, base, (math.cos(a) * pente, math.sin(a) * pente),
                 hauteur, demi, mat_idx=0 if hauteur > 0.45 else 1)

    # --- PLAN DE RUPTURE BAS : quatre échardes de longueurs distinctes.
    cm = chemin_mort(1.0)[0]
    for dx, dy, h, w in ((0.11, -0.07, 1.55, 0.115), (-0.15, 0.10, 1.15, 0.100),
                         (0.03, 0.17, 0.85, 0.085), (-0.05, -0.16, 0.60, 0.075)):
        _echarde(bm, (cm[0] + dx, cm[1] + dy, cm[2] - 0.12),
                 (dx * 2.0, dy * 2.0), h, w)

    # --- PLAN DE RUPTURE HAUT : trois échardes au bout du membre arraché.
    cb = chemin_membre(1.0)[0]
    for dx, dy, h, w in ((0.09, 0.06, 0.85, 0.090), (-0.10, -0.05, 0.60, 0.078),
                         (0.02, -0.11, 0.42, 0.068)):
        _echarde(bm, (cb[0] + dx, cb[1] + dy, cb[2] - 0.10),
                 (dx * 2.0, dy * 2.0), h, w)

    # --- bouts pâles des moignons.
    for z, yaw, longueur, pente, rcol in MOIGNONS:
        t = (z - FOURCHE_Z) / (VIVANT_SOMMET - FOURCHE_Z)
        centre, rayon = chemin_vivant(t)
        direction = (math.cos(yaw), math.sin(yaw), pente)
        bout = (centre[0] + direction[0] * (rayon * 0.8 + longueur),
                centre[1] + direction[1] * (rayon * 0.8 + longueur),
                z + pente * longueur)
        taille = rcol * 0.48
        rangs_bout = [
            [(bout[0] - taille, bout[1] - taille, bout[2] - taille),
             (bout[0] + taille, bout[1] - taille, bout[2] - taille),
             (bout[0] + taille, bout[1] + taille, bout[2] - taille),
             (bout[0] - taille, bout[1] + taille, bout[2] - taille)],
            [(bout[0] - taille * 0.5, bout[1] - taille * 0.5, bout[2] + taille),
             (bout[0] + taille * 0.5, bout[1] - taille * 0.5, bout[2] + taille),
             (bout[0] + taille * 0.5, bout[1] + taille * 0.5, bout[2] + taille),
             (bout[0] - taille * 0.5, bout[1] + taille * 0.5, bout[2] + taille)],
        ]
        loft(bm, rangs_bout, fermer_bas=True, fermer_haut=True)

    # --- cassures des bois au sol : la face pâle REGARDE l'arbre.
    for spec in BRANCHES:
        bx, by, yaw, longueur, rayon = spec[0], spec[1], spec[2], spec[3], spec[4]
        vers_arbre = math.atan2(-by, -bx)
        bout = (bx + math.cos(vers_arbre) * longueur * 0.52,
                by + math.sin(vers_arbre) * longueur * 0.52, 0.16)
        h = rayon * 1.1
        rangs_cassure = [
            [(bout[0] - rayon, bout[1] - rayon, 0.04),
             (bout[0] + rayon, bout[1] - rayon, 0.04),
             (bout[0] + rayon, bout[1] + rayon, 0.04),
             (bout[0] - rayon, bout[1] + rayon, 0.04)],
            [(bout[0] - rayon * 0.4 + math.cos(vers_arbre) * 0.16,
              bout[1] - rayon * 0.4 + math.sin(vers_arbre) * 0.16, h + 0.14),
             (bout[0] + rayon * 0.4 + math.cos(vers_arbre) * 0.16,
              bout[1] - rayon * 0.4 + math.sin(vers_arbre) * 0.16, h + 0.14),
             (bout[0] + rayon * 0.4 + math.cos(vers_arbre) * 0.16,
              bout[1] + rayon * 0.4 + math.sin(vers_arbre) * 0.16, h + 0.14),
             (bout[0] - rayon * 0.4 + math.cos(vers_arbre) * 0.16,
              bout[1] + rayon * 0.4 + math.sin(vers_arbre) * 0.16, h + 0.14)],
        ]
        loft(bm, rangs_cassure, fermer_bas=True, fermer_haut=True)


# ---------------------------------------------------------------------------
# Bois tombés — CINQ LOIS DE FORME, pas cinq homothéties.
# ---------------------------------------------------------------------------
def _effilement(loi, t):
    """R2B.1 appliquait `1 − 0,38t` aux CINQ pièces : rapports d'effilement
    mesurés [0,632 ; 0,668 ; 0,622 ; 0,630 ; 0,655], max/min 1,073. La
    hiérarchie de R2B.1 portait sur l'ÉCHELLE — longueurs et rayons bien
    étagés — et pas du tout sur la FORME. C'est ce que le lead a lu comme
    « des poutres identiques »."""
    if loi == "renfle":
        return 0.42 + 0.88 * ((1.0 - t) ** 1.8)
    if loi == "troncon":
        return 1.00 - 0.12 * t
    if loi == "noeud":
        return 1.0 - 0.45 * t + 0.35 * math.exp(-((t - 0.44) / 0.10) ** 2)
    if loi == "fourchue":
        return 1.0 - 0.55 * t
    return 1.0 - 0.72 * t


_ANNEAUX_LOI = {"renfle": 7, "troncon": 5, "noeud": 6, "fourchue": 6,
                "fouet": 6}
_CHICOTS_LOI = {
    "renfle": ((0.22, 0.34, 0.9), (0.71, 0.26, -0.6)),
    "troncon": (),
    "noeud": ((0.44, 0.30, 0.7),),
    "fourchue": ((0.18, 0.24, 0.8), (0.40, 0.17, -0.9), (0.79, 0.13, 0.5)),
    "fouet": ((0.58, 0.19, -0.7),),
}


def _axe_branche(bx, by, yaw, longueur, fleche, pos_fleche, t):
    """L'axe est COURBE. R2B.1 : `c = (bx + cos(yaw)·L·(t−0,5), …)`, une droite
    EXACTE — sagitta en plan 0,000 m pour les cinq pièces."""
    g = math.log(0.5) / math.log(max(0.05, min(0.95, pos_fleche)))
    lat = fleche * math.sin(math.pi * (t ** g))
    ux, uy = math.cos(yaw), math.sin(yaw)
    px, py = -uy, ux
    return (bx + ux * longueur * (t - 0.5) + px * lat,
            by + uy * longueur * (t - 0.5) + py * lat)


def branche(bm, bx, by, yaw, longueur, rayon, releve, cotes, fleche,
            pos_fleche, loi, chicots):
    n_rings = _ANNEAUX_LOI[loi]
    aplat = 0.88 if releve <= 0.001 else 1.0   # une pièce posée s'écrase un peu
    ph = phases(n_rings, cotes, rayon * 97.0)
    anneaux_branche = []
    for k in range(n_rings):
        t = k / float(n_rings - 1)
        cx, cy = _axe_branche(bx, by, yaw, longueur, fleche, pos_fleche, t)
        r = rayon * _effilement(loi, t)
        z = r + releve * (t ** 1.5) + 0.05 * math.sin(t * math.pi)
        if loi == "fouet" and t > 0.65:
            z -= 0.16 * ((t - 0.65) / 0.35) ** 2   # la pointe ploie
        perp = (-math.sin(yaw), math.cos(yaw))
        pts = []
        for i in range(cotes):
            a = 2.0 * math.pi * i / cotes + ph[k]
            rr = r * (1.0 + 0.10 * bruit(a, rayon * 31.0))
            pts.append((cx + perp[0] * math.cos(a) * rr,
                        cy + perp[1] * math.cos(a) * rr,
                        max(0.01, z + math.sin(a) * rr * aplat)))
        anneaux_branche.append(pts)
    # `noeud` est FENDUE EN LONG : sa moitié supérieure montre le cœur pâle
    # sur toute sa longueur. C'est la pièce qui porte, au sol, la même
    # transition écorce -> cœur que la cicatrice porte sur le fût.
    if loi == "noeud":
        loft(bm, anneaux_branche, fermer_bas=True, fermer_haut=True,
             mat_par_point=lambda e, i, n=cotes: 1 if i < n // 2 else 0)
    else:
        loft(bm, anneaux_branche, fermer_bas=True, fermer_haut=True)

    if loi == "fourchue":
        # LE SECOND BRAS, loft séparé : une pièce fourchue, pas un tube.
        t0 = 0.55
        cx0, cy0 = _axe_branche(bx, by, yaw, longueur, fleche, pos_fleche, t0)
        r0 = rayon * _effilement(loi, t0) * 0.72
        yaw2 = yaw + 0.62
        ph2 = phases(4, cotes, rayon * 53.0)
        bras = []
        for k in range(4):
            t = k / 3.0
            d = longueur * 0.42 * t
            cx = cx0 + math.cos(yaw2) * d
            cy = cy0 + math.sin(yaw2) * d
            r = r0 * (1.0 - 0.62 * t)
            z = r + releve * 0.4 * t + 0.04
            perp = (-math.sin(yaw2), math.cos(yaw2))
            pts = []
            for i in range(cotes):
                a = 2.0 * math.pi * i / cotes + ph2[k]
                pts.append((cx + perp[0] * math.cos(a) * r,
                            cy + perp[1] * math.cos(a) * r,
                            max(0.01, z + math.sin(a) * r)))
            bras.append(pts)
        loft(bm, bras, fermer_bas=True, fermer_haut=True)

    # CHICOTS : R2B.1 en donnait UN à chaque pièce, à la même position
    # relative et de la même hauteur. Ici zéro à trois, de tailles et
    # d'orientations différentes, certains plongeant dans l'herbe.
    for pos, taille, sens in _CHICOTS_LOI[loi]:
        cx, cy = _axe_branche(bx, by, yaw, longueur, fleche, pos_fleche, pos)
        r = rayon * _effilement(loi, pos)
        perp = (-math.sin(yaw), math.cos(yaw))
        s = rayon * 0.42
        base_z = r * 0.9
        haut = taille * sens
        rangs_chicot = [
            [(cx - s, cy - s, base_z), (cx + s, cy - s, base_z),
             (cx + s, cy + s, base_z), (cx - s, cy + s, base_z)],
            [(cx - s * 0.5 + perp[0] * taille * 1.3,
              cy - s * 0.5 + perp[1] * taille * 1.3, max(0.02, base_z + haut)),
             (cx + s * 0.5 + perp[0] * taille * 1.3,
              cy - s * 0.5 + perp[1] * taille * 1.3, max(0.02, base_z + haut)),
             (cx + s * 0.5 + perp[0] * taille * 1.3,
              cy + s * 0.5 + perp[1] * taille * 1.3, max(0.02, base_z + haut)),
             (cx - s * 0.5 + perp[0] * taille * 1.3,
              cy + s * 0.5 + perp[1] * taille * 1.3, max(0.02, base_z + haut))],
        ]
        loft(bm, rangs_chicot, fermer_bas=True, fermer_haut=True)


# ---------------------------------------------------------------------------
# Assemblage
# ---------------------------------------------------------------------------
def objet_depuis(nom, remplir, noms_materiaux, base_au_sol):
    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()
    remplir(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(maillage)
    bm.free()
    if base_au_sol:
        bas = min(v.co.z for v in maillage.vertices)
        for v in maillage.vertices:
            v.co.z -= bas
    obj = bpy.data.objects.new(nom, maillage)
    for nom_mat in noms_materiaux:
        obj.data.materials.append(materiau(nom_mat))
    bpy.context.collection.objects.link(obj)
    return obj


def tris_de(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def emprise(objets):
    xs, ys, zs = [], [], []
    for obj in objets:
        for v in obj.data.vertices:
            xs.append(v.co.x)
            ys.append(v.co.y)
            zs.append(v.co.z)
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def _diagnostics():
    """Ce que le générateur SAIT de lui-même, imprimé pour que le journal
    porte les chiffres et pas seulement le verdict."""
    d = phases(15, ANNEAU_VIVANT, 17.3)
    pas = [math.degrees(d[k + 1] - d[k]) for k in range(len(d) - 1)]
    moy = sum(abs(x) for x in pas) / len(pas)
    m = sum(pas) / len(pas)
    sd = (sum((x - m) ** 2 for x in pas) / len(pas)) ** 0.5
    net = math.degrees(d[-1] - d[0])
    alias = math.degrees(math.pi / ANNEAU_VIVANT)
    print("[thunderstruck_tree] phase : |dphi| moyen %.2f deg, ecart-type %.2f, "
          "net %.2f deg, repliement a +-%.2f deg (max |pas| %.2f)"
          % (moy, sd, net, alias, max(abs(x) for x in pas)))
    largeurs = []
    for k in range(26):
        z = CICATRICE_HAUT - 0.04 - (CICATRICE_HAUT - CICATRICE_BAS - 0.08) \
            * k / 25.0
        largeurs.append(cicatrice_metres(z)[0])
    non_nulles = [x for x in largeurs if x > 0.0]
    print("[thunderstruck_tree] cicatrice : largeur %.3f..%.3f m (rapport %.2f), "
          "%d station(s) sur %d interrompue(s) par un pont d'ecorce"
          % (min(non_nulles), max(non_nulles),
             max(non_nulles) / min(non_nulles),
             len(largeurs) - len(non_nulles), len(largeurs)))
    azs = sorted(math.degrees(r[0]) % 360.0 for r in RACINES)
    ecarts = [(azs[(i + 1) % len(azs)] - azs[i]) % 360.0 for i in range(len(azs))]
    print("[thunderstruck_tree] racines : ecarts d'azimut %s deg, max/min %.2f"
          % (", ".join("%.0f" % e for e in ecarts), max(ecarts) / min(ecarts)))


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _diagnostics()
    mats_ecorce = ["MAT_Tree_CharredBark", "MAT_Tree_Charcoal",
                   "MAT_Tree_ScorchedSap"]
    pieces = [
        objet_depuis("SM_ThunderstruckTree_Bark", ecorce, mats_ecorce, True),
        objet_depuis("SM_ThunderstruckTree_Heart", coeur,
                     ["MAT_Tree_Heartwood", "MAT_Tree_ScorchedSap"], False),
        objet_depuis("SM_ThunderstruckTree_Roots", racines,
                     ["MAT_Tree_CharredBark"], False),
    ]
    for suffixe, spec in zip("ABCDE", BRANCHES):
        mats = ["MAT_Tree_CharredBark"]
        if spec[9] == "noeud":
            mats.append("MAT_Tree_Heartwood")
        pieces.append(objet_depuis(
            "SM_ThunderstruckTree_Branch%s" % suffixe,
            lambda bm, s=spec: branche(bm, *s),
            mats, True))

    total = 0
    for obj in pieces:
        n = tris_de(obj)
        total += n
        print("[thunderstruck_tree] %-32s %4d tris" % (obj.name, n))
    (x0, x1), (y0, y1), (z0, z1) = emprise(pieces)
    print("[thunderstruck_tree] emprise X %.2f..%.2f  Y %.2f..%.2f  "
          "Z %.3f..%.2f — %d tris (budget %d)"
          % (x0, x1, y0, y1, z0, z1, total, BUDGET_TRIS))

    # LES REFUS DU PLAN APPROUVÉ — le générateur n'enregistre pas un arbre
    # hors contrat, il ne le « signale » pas : il échoue. Aucun de ces seuils
    # n'a bougé en R2B.2 ; le dernier est AJOUTÉ.
    if not (HAUTEUR_MIN <= z1 <= HAUTEUR_MAX):
        print("[thunderstruck_tree] ERREUR: hauteur %.2f hors de [%.0f ; %.0f]"
              " — REFUS d'enregistrer" % (z1, HAUTEUR_MIN, HAUTEUR_MAX))
        return 2
    if abs(z0) > BASE_TOL:
        print("[thunderstruck_tree] ERREUR: base à Z=%.3f (attendu 0) — "
              "REFUS d'enregistrer" % z0)
        return 2
    if total > BUDGET_TRIS:
        print("[thunderstruck_tree] ERREUR: budget dépassé — REFUS "
              "d'enregistrer")
        return 2
    ecorce_obj = pieces[0]
    bas_xs = [v.co.x for v in ecorce_obj.data.vertices if v.co.z < 0.3]
    bas_ys = [v.co.y for v in ecorce_obj.data.vertices if v.co.z < 0.3]
    largeur_souche = max(max(bas_xs) - min(bas_xs), max(bas_ys) - min(bas_ys))
    print("[thunderstruck_tree] souche large de %.2f m (attendu %.1f ± 0,35)"
          % (largeur_souche, SOUCHE_LARGEUR))
    if abs(largeur_souche - SOUCHE_LARGEUR) > 0.35:
        print("[thunderstruck_tree] ERREUR: souche large de %.2f m "
              "(attendu %.1f ± 0,35)" % (largeur_souche, SOUCHE_LARGEUR))
        return 2

    # REFUS AJOUTÉ EN R2B.2 — TRAVERSABILITÉ. Hors de l'emprise du collider du
    # tronc, un contrefort sans collider plus haut que le `step_height` de
    # 0,34 de locomotion_default.tres est un mur invisible. R2B.1 était à
    # 0,382 m sur 20 sommets : défaut PRÉEXISTANT, corrigé ici.
    racines_obj = pieces[2]
    haut_hors = 0.0
    for v in racines_obj.data.vertices:
        if abs(v.co.x) <= COLLIDER_DEMI_X and abs(v.co.y) <= COLLIDER_DEMI_Y:
            continue
        haut_hors = max(haut_hors, v.co.z)
    print("[thunderstruck_tree] racines : hauteur max hors collider %.3f m "
          "(plafond %.2f)" % (haut_hors, RACINE_HAUTEUR_MAX_HORS))
    if haut_hors > RACINE_HAUTEUR_MAX_HORS:
        print("[thunderstruck_tree] ERREUR: contrefort de %.3f m hors de "
              "l'emprise du collider — non enjambable" % haut_hors)
        return 2

    # La cicatrice est réellement CREUSÉE. Contrôle PAR SOMMET, normalisé :
    # chaque sommet du fût vivant est comparé au rayon nominal de SON anneau,
    # contre l'angle de la spirale à SON z. Le témoin exclut la face APLATIE
    # de la fente, qui n'est ni bande ni témoin.
    ratios_dans, ratios_hors = [], []
    joue = AZ_MORT
    for v in ecorce_obj.data.vertices:
        z = v.co.z
        if not (3.4 <= z <= 6.8):
            continue
        t = (z - FOURCHE_Z) / (VIVANT_SOMMET - FOURCHE_Z)
        centre, rayon_nominal = chemin_vivant(t)
        distance = math.hypot(v.co.x - centre[0], v.co.y - centre[1])
        if distance > rayon_nominal * 1.25 or distance < rayon_nominal * 0.4:
            continue
        angle = math.atan2(v.co.y - centre[1], v.co.x - centre[0])
        ecart_joue = (angle - joue + math.pi) % (2 * math.pi) - math.pi
        if abs(ecart_joue) < 1.1:
            continue
        demi, _levre, _retrait = cicatrice_profil(z, rayon_nominal)
        if demi <= 0.0:
            continue
        ecart = (angle - angle_cicatrice(z) + math.pi) % (2 * math.pi) - math.pi
        ratio = distance / rayon_nominal
        if abs(ecart) < demi * 0.70:
            ratios_dans.append(ratio)
        elif abs(ecart) > demi * 1.75:
            ratios_hors.append(ratio)
    if not ratios_dans or not ratios_hors:
        print("[thunderstruck_tree] ERREUR: contrôle de cicatrice sans "
              "échantillon (%d dans, %d hors)"
              % (len(ratios_dans), len(ratios_hors)))
        return 2
    moyen_dans = sum(ratios_dans) / len(ratios_dans)
    moyen_hors = sum(ratios_hors) / len(ratios_hors)
    creux = moyen_hors - moyen_dans
    print("[thunderstruck_tree] cicatrice : rayon relatif %.3f dans la bande "
          "(%d sommets), %.3f hors bande (%d) — creux %.3f"
          % (moyen_dans, len(ratios_dans), moyen_hors, len(ratios_hors),
             creux))
    if creux < 0.10:
        print("[thunderstruck_tree] ERREUR: la cicatrice n'est pas creusée")
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_ThunderstruckTree.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[thunderstruck_tree] source enregistrée -> %s" % sortie)
    print("FIN NOMINALE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
