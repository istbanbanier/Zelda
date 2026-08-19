# SOURCE DE GÉNÉRATION REPRODUCTIBLE — L'Arbre foudroyé, hero asset de la
# prairie aux mille fleurs (V2.3-A.R2B.1, agent B).
#
# POURQUOI CETTE RÉVISION EXISTE. Le r02 était un LOFT correct — une seule
# surface, une vraie fente, une cicatrice creusée — et il a quand même été
# rejeté : « un pilier noir polygonal posé sur une étoile de planches ».
# La mesure a donné la cause, et ce n'était pas le détail :
#
#   * LE PLAN DE FOURCHE ÉTAIT UNIQUE. Les deux moitiés divergeaient de
#     3,59 m en X pour 0,57 m en Y — un plan à 9°. Une caméra qui regarde
#     DANS ce plan voit les deux moitiés se superposer exactement, et
#     l'arbre redevient un trait. Les caméras de preuve du lead sont à
#     −31°, soit 22° du plan. D'où l'emprise latérale au-dessus de la
#     fourche : 2,32 m au pire azimut contre 4,18 m au meilleur —
#     anisotropie 1,81, élancement 4,8. C'est l'obélisque, chiffré.
#   * LE FÛT ÉTAIT AFFINE. `0,50 − t·0,34` : un cône exact. Résidu
#     d'ajustement linéaire 3,7 %, zéro renflement de collet.
#   * LA SOUCHE ÉTAIT RECTILIGNE ET BOMBÉE : concavité −0,025 m.
#   * LES SAILLIES ÉTAIENT EN GRAPPE : deux moignons à 1,4° l'un de
#     l'autre, pentes toutes identiques (+22,8°).
#   * LES BOIS AU SOL ÉTAIENT DEUX PLANCHES JUMELLES : rayon 0,155
#     identique, dénivelé bout-à-bout 0,054 m pour les deux.
#   * LA CICATRICE ÉTAIT UNE BANDE DE LARGEUR CONSTANTE (0,15 sur 7 m).
#
# CE QUE FAIT CETTE RÉVISION. Elle ne « détaille » pas l'objet : elle casse
# les trois régularités qui le faisaient lire comme un solide de
# révolution. La fourche sort de son plan (trois extrémités réparties en
# azimut au lieu de deux opposées), le rayon suit une loi de puissance
# ponctuée de collets, et les terminaisons deviennent inégales.
#
# LA CIME VIVANTE RESTE VIVANTE — arbitrage explicite du lead. Le récit du
# lieu est « un arbre foudroyé qui a survécu d'un côté » ; la casser
# réécrirait la fiction. Les DEUX ruptures principales sont donc toutes
# deux du côté frappé : la moitié morte rompue net à 5,9 m, et une grosse
# branche maîtresse arrachée à 7,55 m. Écart 1,65 m.
#
# CINQ OBJETS, UN SEUL GLB :
#   * `_Bark`    — souche, moitié vivante, moitié morte, membre arraché,
#                  cinq moignons. DEUX emplacements de matériau : écorce
#                  saine et zones calcinées (côté frappé).
#   * `_Heart`   — le bois MIS À NU : coin de fente, ruban de cicatrice à
#                  largeur VARIABLE, échardes des deux plans de rupture,
#                  bouts de moignons, cassures des bois au sol.
#   * `_Roots`   — cinq contreforts-racines. OBJET SÉPARÉ à dessein : le
#                  garde-fou `SOUCHE_LARGEUR` mesure les sommets sous
#                  z = 0,3 ; y verser les racines lui ferait avaler autre
#                  chose que la souche et le ferait rougir à tort. On ne
#                  desserre pas un seuil pour lui faire passer une
#                  géométrie — on range la géométrie ailleurs.
#   * `_BranchA..E` — cinq bois tombés hiérarchisés, dont deux appuyés.
#
# BUDGET VERROUILLÉ AVANT MODÉLISATION (arbitrage R2B) : ≤ 6 000 triangles.
# LE GÉNÉRATEUR REFUSE D'ENREGISTRER si la hauteur totale sort de [10 ; 12],
# si la base n'est pas à Z = 0, si le budget est dépassé, si la souche sort
# de sa largeur de plan ou si la cicatrice n'est pas creusée. Ces refus ne
# bougent pas d'un iota dans cette révision.
#
# Blender est Z-up ; l'export convertit en Y-up : Blender (x, y, z) devient
# Godot (x, z, −y). Un azimut Godot φ correspond donc à un azimut Blender
# −φ. La moitié vivante garde son orientation vers +X (est) — les caméras
# existantes restent justes ; ce sont la moitié morte et le membre qui
# quittent le plan.
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
# Cotes
# ---------------------------------------------------------------------------
SOUCHE_LARGEUR = 2.1        # au sol, lobes de contrefort compris
SOUCHE_RAYON_BAS = 0.84
SOUCHE_RAYON_HAUT = 0.62
SOUCHE_PUISSANCE = 2.8      # > 1 => profil CONCAVE (le pied se creuse)
FOURCHE_Z = 2.2             # le tronc est UN jusqu'ici
VIVANT_SOMMET = 10.8        # moitié vivante — cime INTACTE
MORT_SOMMET = 5.9           # moitié morte, rompue net (rupture basse)
MEMBRE_BASE_Z = 6.30        # branche maîtresse arrachée (rupture haute)
MEMBRE_RUPTURE_Z = 7.55
HAUTEUR_MIN, HAUTEUR_MAX = 10.0, 12.0
BUDGET_TRIS = 6000
BASE_TOL = 0.005

ANNEAU_SOUCHE = 16
ANNEAU_MOITIE = 14
ANNEAU_MEMBRE = 10

# Azimuts BLENDER des trois extrémités. En Godot : −15° (vivant), +120°
# (mort), +235° (membre). Écarts en plan 135° / 115° / 110° — inégaux à
# dessein : trois directions équidistantes redonneraient une étoile.
AZ_VIVANT = math.radians(15.0)
AZ_MORT = math.radians(-104.6)
AZ_MEMBRE = math.radians(137.9)
PORTEE_VIVANT = 2.40
PORTEE_MORT = 2.08
PORTEE_MEMBRE = 2.34

# La cicatrice : bande qui DESCEND en spirale du départ de la fourche
# jusqu'au pied, sur la face frappée.
CICATRICE_HAUT = 7.4
CICATRICE_BAS = 0.35
CICATRICE_DEMI_ANGLE = 0.42
CICATRICE_RETRAIT = 0.80    # rayon × 0,80 au droit de la bande
CICATRICE_TOURS_RAD = 3.4
# Largeurs du ruban de cœur, station par station. Le r02 avait 0,15
# CONSTANT sur sept mètres : c'est exactement ce que le lead a vu comme
# « une bande blanche droite peinte ». Une cassure de bois n'a pas de
# largeur constante.
CICATRICE_LARGEURS = (0.30, 0.13, 0.22, 0.09, 0.26, 0.11, 0.19, 0.31, 0.12,
                      0.24, 0.10, 0.20, 0.28, 0.14, 0.09, 0.17, 0.25, 0.11)

# Moignons : (z, yaw Blender, longueur, pente, rayon au collet). Les
# azimuts sont VISÉS APRÈS MESURE : un moignon naît de la paroi d'un
# fût penché, donc son azimut vu depuis l'axe n'est pas son yaw — le
# décalage mesuré va de −18° à +35° selon la hauteur et la longueur.
# Cible : six saillies (cinq moignons + le membre) à écarts inégaux
# mais bornés, sans secteur vide de plus de 90°.
MOIGNONS = (
    (3.90, math.radians(-323.7), 1.38, 0.14, 0.22),
    (5.20, math.radians(-3.1), 0.94, 0.62, 0.19),
    (6.90, math.radians(-279.2), 0.91, 0.30, 0.17),
    (7.80, math.radians(-132.0), 1.42, 0.20, 0.16),
    (9.50, math.radians(-62.7), 1.37, 0.45, 0.11),
)

# Racines : (yaw Blender, portée, crête). La crête reste sous 0,30 m,
# c'est-à-dire sous le `step_height` de 0,34 de locomotion_default.tres :
# ces contreforts n'ont pas de collider et le joueur doit pouvoir les
# enjamber sans les ressentir comme un mur.
RACINES = (
    (math.radians(-8.0), 2.15, 0.28),
    (math.radians(-75.0), 1.55, 0.19),
    (math.radians(-140.0), 1.95, 0.26),
    (math.radians(-200.0), 1.65, 0.22),
    (math.radians(-275.0), 2.05, 0.30),
)

# Bois tombés : (x, y Blender, yaw, longueur, rayon, hauteur du bout
# relevé). Les deux derniers champs portent la hiérarchie que le r02
# n'avait pas : cinq épaisseurs distinctes, et deux pièces APPUYÉES —
# une sur la souche, une en travers de la première.
BRANCHES = (
    (2.95, 1.75, 2.05, 4.20, 0.260, 0.00),
    (-3.30, 2.15, -0.75, 3.10, 0.195, 0.62),
    (-1.20, -3.35, 0.95, 2.30, 0.155, 0.00),
    (3.05, -2.40, 2.60, 1.60, 0.115, 0.41),
    (0.35, 3.55, 1.35, 1.10, 0.085, 0.00),
)

# ---------------------------------------------------------------------------
# Matériaux — sRGB converti en linéaire. TROIS valeurs, pas deux : le lead
# demande de distinguer écorce brûlée, cœur exposé et zones calcinées.
# §1.6 : jamais de noir pur — le calciné reste une valeur sombre lisible.
# ---------------------------------------------------------------------------
MATERIAUX = {
    "MAT_Tree_CharredBark": (0.26, 0.21, 0.17, 0.96),
    "MAT_Tree_Heartwood": (0.84, 0.74, 0.55, 0.88),
    "MAT_Tree_Charcoal": (0.145, 0.130, 0.128, 0.99),
}
IDX_ECORCE = 0
IDX_CALCINE = 1


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


# Bruit angulaire à phases irrégulières. Le r02 modulait ses contreforts
# par `max(0, sin(3a + 0,7))²` — trois lobes IDENTIQUES à 120°, c'est-à-dire
# une étoile à trois branches. Ici la somme d'harmoniques déphasées ne
# laisse aucune période dominante.
_HARMONIQUES = ((2, 1.00, 0.71), (3, 0.86, 2.93), (5, 0.71, 1.34),
                (7, 0.58, 4.42), (9, 0.50, 0.19))
_NORME = sum(a for _, a, _ in _HARMONIQUES)


def bruit(angle, graine=0.0):
    total = 0.0
    for k, amp, phase in _HARMONIQUES:
        total += amp * math.sin(k * angle + phase + graine)
    return total / _NORME


# ---------------------------------------------------------------------------
# La spirale de cicatrice — UNE définition, partagée par le retrait de
# l'écorce ET par le ruban de cœur : deux codes qui redérivent la même
# spirale finissent par diverger (tools/CLAUDE.md).
# ---------------------------------------------------------------------------
def angle_cicatrice(z):
    t = (CICATRICE_HAUT - z) / (CICATRICE_HAUT - CICATRICE_BAS)
    return -0.55 + t * CICATRICE_TOURS_RAD


def dans_cicatrice(z, angle):
    if z > CICATRICE_HAUT or z < CICATRICE_BAS:
        return False
    ecart = (angle - angle_cicatrice(z) + math.pi) % (2.0 * math.pi) - math.pi
    return abs(ecart) < CICATRICE_DEMI_ANGLE


# ---------------------------------------------------------------------------
# Loft d'anneaux fermés
# ---------------------------------------------------------------------------
def anneau(centre, rayon, n, z, lobes=0.0, graine=0.0, aplati=None,
           applique_cicatrice=True):
    """Un anneau fermé. `lobes` module le rayon par un BRUIT à phases
    irrégulières (contreforts de souche), `aplati` = (angle, force) écrase
    la face qui regarde la fente, et la bande de cicatrice CREUSE le
    profil — le retrait est dans l'écorce, pas plaqué dessus."""
    points = []
    for i in range(n):
        a = 2.0 * math.pi * i / n
        r = rayon * (1.0 + _graine(graine + i * 1.7) * 0.10)
        if lobes > 0.0:
            # 0,5 + 0,5·bruit plutôt que max(0, bruit) : tout le tour reçoit
            # un contrefort, d'intensité irrégulière. Avec `max` seule la
            # moitié du tour s'élargissait et la souche tombait à 1,71 m,
            # sous le plancher de 1,75 du garde-fou de largeur.
            r *= 1.0 + lobes * (0.5 + 0.5 * bruit(a, graine * 0.37))
        if aplati is not None:
            ecart = (a - aplati[0] + math.pi) % (2.0 * math.pi) - math.pi
            if abs(ecart) < 1.05:
                r *= 1.0 - aplati[1] * (1.0 - abs(ecart) / 1.05)
        if applique_cicatrice and dans_cicatrice(z, a):
            r *= CICATRICE_RETRAIT
        points.append((centre[0] + math.cos(a) * r,
                       centre[1] + math.sin(a) * r, z))
    return points


def loft(bm, anneaux, mat_idx=0, fermer_bas=False, fermer_haut=False):
    rangs = [[bm.verts.new(p) for p in a] for a in anneaux]
    faces = []
    for e in range(len(rangs) - 1):
        bas, haut = rangs[e], rangs[e + 1]
        n = len(bas)
        for i in range(n):
            j = (i + 1) % n
            faces.append(bm.faces.new((bas[i], bas[j], haut[j], haut[i])))
    if fermer_bas:
        faces.append(bm.faces.new(tuple(reversed(rangs[0]))))
    if fermer_haut:
        faces.append(bm.faces.new(tuple(rangs[-1])))
    for f in faces:
        f.material_index = mat_idx
    return rangs


def couronne_rompue(bm, sommet, centre, hauteurs, mat_idx):
    """Une cassure : le dernier anneau part en pointes INÉGALES au lieu de
    se refermer à plat. C'est ce qui distingue une rupture d'une coupe."""
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
# Chemins — loi de PUISSANCE, pas une droite.
# ---------------------------------------------------------------------------
def _collets(z):
    """Renflement local à chaque départ de moignon. Un tronc ne s'affine
    pas régulièrement : il épaissit là où part une branche. Sans ces
    bosses le profil reste monotone et l'œil lit un cône."""
    facteur = 1.0
    for zm, _, _, _, _ in MOIGNONS:
        facteur *= 1.0 + 0.14 * math.exp(-((z - zm) / 0.55) ** 2)
    return facteur


def chemin_vivant(t):
    """Centre et rayon de la moitié vivante à t ∈ [0;1]. La course en plan
    s'incurve (t**1.25) au lieu de filer droit."""
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
    """La branche maîtresse arrachée : elle NAÎT du fût vivant à 6,30 m et
    se rompt à 7,55 m. Elle reste ÉPAISSE à la cassure (0,30 de rayon,
    0,60 de diamètre) — la foudre casse gros, elle n'effile pas en
    brindille, et c'est cette masse qui donne à l'arbre sa lecture
    latérale à 90 m."""
    depart = chemin_vivant((MEMBRE_BASE_Z - FOURCHE_Z)
                           / (VIVANT_SOMMET - FOURCHE_Z))[0]
    course = PORTEE_MEMBRE * t
    return ((depart[0] + math.cos(AZ_MEMBRE) * course,
             depart[1] + math.sin(AZ_MEMBRE) * course,
             MEMBRE_BASE_Z + t * (MEMBRE_RUPTURE_Z - MEMBRE_BASE_Z)),
            0.34 - t * 0.04)


def _souche_rayon(z):
    """Profil CONCAVE : le pied se creuse au lieu de descendre en ligne
    droite. Le r02 avait une concavité de −0,025 m — il bombait."""
    u = min(1.0, max(0.0, z / FOURCHE_Z))
    return SOUCHE_RAYON_HAUT + (SOUCHE_RAYON_BAS - SOUCHE_RAYON_HAUT) \
        * ((1.0 - u) ** SOUCHE_PUISSANCE)


# ---------------------------------------------------------------------------
# SM_ThunderstruckTree_Bark
# ---------------------------------------------------------------------------
def ecorce(bm):
    # --- la souche : UN anneau, contreforts irréguliers qui s'estompent.
    souche = []
    for k in range(9):
        z = FOURCHE_Z * (k / 8.0)
        souche.append(anneau((0.0, 0.0), _souche_rayon(z), ANNEAU_SOUCHE, z,
                             lobes=0.30 * ((1.0 - z / FOURCHE_Z) ** 1.4),
                             graine=k * 3.3))
    rangs = loft(bm, souche, mat_idx=IDX_ECORCE, fermer_bas=True)

    # --- le col : l'entonnoir qui descend ENTRE les moitiés — les joues de
    # la fente. Le sommet de souche se referme vers un centre ABAISSÉ.
    haut = rangs[-1]
    col = bm.verts.new((0.0, 0.0, 1.58))
    for i in range(ANNEAU_SOUCHE):
        j = (i + 1) % ANNEAU_SOUCHE
        f = bm.faces.new((haut[j], haut[i], col))
        f.material_index = IDX_CALCINE

    # --- moitié vivante : loft continu jusqu'à 10,8 m, cime INTACTE.
    vivant = []
    for k in range(15):
        t = k / 14.0
        centre, rayon = chemin_vivant(t)
        vivant.append(anneau(centre, rayon, ANNEAU_MOITIE, centre[2],
                             graine=40.0 + k * 2.1,
                             aplati=(AZ_MORT, 0.30 * (1.0 - t))))
    rangs_vivant = loft(bm, vivant, mat_idx=IDX_ECORCE)
    cime_centre, _ = chemin_vivant(1.0)
    cime = bm.verts.new((cime_centre[0] + 0.06, cime_centre[1] - 0.04,
                         cime_centre[2] + 0.22))
    dessus = rangs_vivant[-1]
    for i in range(ANNEAU_MOITIE):
        j = (i + 1) % ANNEAU_MOITIE
        f = bm.faces.new((dessus[i], dessus[j], cime))
        f.material_index = IDX_ECORCE

    # --- moitié morte : RUPTURE BASSE à 5,9 m, écorce calcinée.
    mort = []
    for k in range(10):
        t = k / 9.0
        centre, rayon = chemin_mort(t)
        mort.append(anneau(centre, rayon, ANNEAU_MOITIE, centre[2],
                           graine=80.0 + k * 1.9,
                           aplati=(AZ_VIVANT, 0.28 * (1.0 - t))))
    rangs_mort = loft(bm, mort, mat_idx=IDX_CALCINE)
    couronne_rompue(bm, rangs_mort[-1], chemin_mort(1.0)[0],
                    (1.35, 0.24, 0.82, 0.15, 1.08, 0.31, 0.66, 0.13,
                     0.95, 0.27, 0.50, 0.19, 1.18, 0.22), IDX_CALCINE)

    # --- membre arraché : RUPTURE HAUTE à 7,55 m.
    membre = []
    for k in range(6):
        t = k / 5.0
        centre, rayon = chemin_membre(t)
        membre.append(anneau((centre[0], centre[1]), rayon, ANNEAU_MEMBRE,
                             centre[2], graine=130.0 + k * 2.7,
                             applique_cicatrice=False))
    rangs_membre = loft(bm, membre, mat_idx=IDX_CALCINE, fermer_bas=True)
    couronne_rompue(bm, rangs_membre[-1], chemin_membre(1.0)[0],
                    (0.62, 0.14, 0.44, 0.21, 0.55, 0.11, 0.36, 0.17,
                     0.48, 0.13), IDX_CALCINE)

    # --- moignons : cinq branches arrachées encore accrochées, générées du
    # MÊME chemin de tronc. Pentes et épaisseurs toutes différentes : le
    # r02 avait cinq fois la même pente et deux moignons à 1,4° l'un de
    # l'autre.
    for z, yaw, longueur, pente, rcol in MOIGNONS:
        t = (z - FOURCHE_Z) / (VIVANT_SOMMET - FOURCHE_Z)
        centre, rayon = chemin_vivant(t)
        direction = (math.cos(yaw), math.sin(yaw), pente)
        base = (centre[0] + direction[0] * rayon * 0.8,
                centre[1] + direction[1] * rayon * 0.8, z)
        anneaux_moignon = []
        for e in range(4):
            te = e / 3.0
            c = (base[0] + direction[0] * longueur * te,
                 base[1] + direction[1] * longueur * te,
                 base[2] + direction[2] * longueur * te)
            anneaux_moignon.append(anneau(
                (c[0], c[1]), rcol * (1.0 - te * 0.42), 8, c[2],
                graine=z * 4.1 + e, applique_cicatrice=False))
        loft(bm, anneaux_moignon, mat_idx=IDX_CALCINE, fermer_haut=True)


# ---------------------------------------------------------------------------
# SM_ThunderstruckTree_Roots — contreforts au sol, OBJET SÉPARÉ
# ---------------------------------------------------------------------------
def racines(bm):
    for yaw, portee, crete in RACINES:
        anneaux_racine = []
        for k in range(5):
            t = k / 4.0
            d = 0.55 + portee * t
            z = crete * (1.0 - t) ** 1.6 + 0.045
            r = (0.30 - t * 0.24) * (1.0 + _graine(yaw * 7.0 + k) * 0.18)
            c = (math.cos(yaw) * d, math.sin(yaw) * d)
            pts = []
            for i in range(6):
                a = 2.0 * math.pi * i / 6
                # section aplatie : une racine est plus large que haute
                pts.append((c[0] - math.sin(yaw) * math.cos(a) * r * 1.35,
                            c[1] + math.cos(yaw) * math.cos(a) * r * 1.35,
                            max(0.01, z + math.sin(a) * r * 0.75)))
            anneaux_racine.append(pts)
        loft(bm, anneaux_racine, fermer_bas=True, fermer_haut=True)


# ---------------------------------------------------------------------------
# SM_ThunderstruckTree_Heart — le bois mis à nu
# ---------------------------------------------------------------------------
def ruban(bm, points, largeurs, epaisseur):
    """Ruban lofté le long d'une polyligne, à demi-largeur VARIABLE et
    section hexagonale. Une cassure de bois n'a pas de largeur constante ;
    une bande de largeur constante se lit comme de la peinture."""
    anneaux_ruban = []
    for (p, normale, tangente), demi in zip(points, largeurs):
        # LA LARGEUR PART SUR LA BINORMALE, pas sur la tangente. Premier
        # jet (et r02 avant lui) : le décalage latéral se faisait le long
        # de `tangente`, c'est-à-dire le long du CHEMIN — donc à la
        # verticale. Toute la variation de largeur partait dans la
        # longueur du ruban et n'élargissait rien : mesuré CV 0,204 au lieu
        # des 0,39 dessinés. Un chiffre juste appliqué au mauvais axe.
        bx = normale[1] * tangente[2] - normale[2] * tangente[1]
        by = normale[2] * tangente[0] - normale[0] * tangente[2]
        bz = normale[0] * tangente[1] - normale[1] * tangente[0]
        bn = math.sqrt(bx * bx + by * by + bz * bz) or 1.0
        binormale = (bx / bn, by / bn, bz / bn)
        section = []
        for i in range(6):
            a = 2.0 * math.pi * i / 6
            lat = math.cos(a) * demi
            prof = math.sin(a) * epaisseur
            section.append((p[0] + binormale[0] * lat - normale[0] * (prof + epaisseur),
                            p[1] + binormale[1] * lat - normale[1] * (prof + epaisseur),
                            p[2] + binormale[2] * lat - normale[2] * (prof + epaisseur)))
        anneaux_ruban.append(section)
    loft(bm, anneaux_ruban, fermer_bas=True, fermer_haut=True)


def _echarde(bm, base, direction, hauteur, largeur):
    """Une écharde : un éclat de bois frais qui pointe hors de la cassure."""
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
    loft(bm, rangs_pointe, fermer_bas=True, fermer_haut=True)


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

    # --- le ruban de cicatrice, logé DANS le retrait de l'écorce : même
    # spirale (angle_cicatrice), largeur variable station par station.
    etapes = []
    n = len(CICATRICE_LARGEURS)
    for k in range(n):
        z = CICATRICE_HAUT - 0.25 - (CICATRICE_HAUT - CICATRICE_BAS - 0.5) \
            * k / (n - 1)
        if z > FOURCHE_Z:
            t = (z - FOURCHE_Z) / (VIVANT_SOMMET - FOURCHE_Z)
            centre, rayon = chemin_vivant(t)
        else:
            centre = (0.0, 0.0, z)
            rayon = _souche_rayon(z)
        a = angle_cicatrice(z)
        r = rayon * (CICATRICE_RETRAIT + 0.13)
        p = (centre[0] + math.cos(a) * r, centre[1] + math.sin(a) * r, z)
        etapes.append((p, (math.cos(a), math.sin(a), 0.0)))
    chemin = []
    for k in range(n):
        p, normale = etapes[k]
        p_suiv = etapes[min(k + 1, n - 1)][0]
        p_prec = etapes[max(k - 1, 0)][0]
        tangente = (p_suiv[0] - p_prec[0], p_suiv[1] - p_prec[1],
                    p_suiv[2] - p_prec[2])
        norme = math.sqrt(sum(c * c for c in tangente)) or 1.0
        tangente = tuple(c / norme for c in tangente)
        chemin.append((p, normale, tangente))
    ruban(bm, chemin, CICATRICE_LARGEURS, 0.055)

    # --- PLAN DE RUPTURE BAS : quatre échardes de longueurs distinctes au
    # cœur de la couronne morte.
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

    # --- bouts pâles des moignons (mêmes cotes que l'écorce).
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

    # --- cassures des bois au sol : la face pâle REGARDE l'arbre — ils sont
    # tombés d'ici, pas apportés par le vent.
    for bx, by, yaw, longueur, rayon, releve in BRANCHES:
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
# Bois tombés — dans le MÊME GLB : la chute appartient à l'arbre.
# ---------------------------------------------------------------------------
def branche(bm, bx, by, yaw, longueur, rayon, releve):
    perp = (-math.sin(yaw), math.cos(yaw))
    anneaux_branche = []
    for k in range(5):
        t = k / 4.0
        c = (bx + math.cos(yaw) * longueur * (t - 0.5),
             by + math.sin(yaw) * longueur * (t - 0.5))
        r = rayon * (1.0 - t * 0.38)
        # `releve` soulève UN bout : la pièce s'appuie au lieu de gésir à
        # plat. Le r02 avait deux planches parfaitement posées, dénivelé
        # bout-à-bout 0,054 m pour les deux — d'où « planches identiques ».
        z = r + releve * (t ** 1.5) + 0.05 * math.sin(t * math.pi)
        pts = []
        for i in range(8):
            a = 2.0 * math.pi * i / 8
            rr = r * (1.0 + _graine(k * 5.0 + i + rayon * 31.0) * 0.14)
            pts.append((c[0] + perp[0] * math.cos(a) * rr,
                        c[1] + perp[1] * math.cos(a) * rr,
                        z + math.sin(a) * rr))
        anneaux_branche.append(pts)
    loft(bm, anneaux_branche, fermer_bas=True, fermer_haut=True)
    # un chicot latéral, pour que la branche ne soit pas un tube
    c_mid = (bx + math.cos(yaw) * longueur * 0.1,
             by + math.sin(yaw) * longueur * 0.1)
    s = rayon * 0.42
    rangs_chicot = [
        [(c_mid[0] - s, c_mid[1] - s, rayon * 0.9),
         (c_mid[0] + s, c_mid[1] - s, rayon * 0.9),
         (c_mid[0] + s, c_mid[1] + s, rayon * 0.9),
         (c_mid[0] - s, c_mid[1] + s, rayon * 0.9)],
        [(c_mid[0] - s * 0.5 + perp[0] * 0.5, c_mid[1] - s * 0.5 + perp[1] * 0.5,
          rayon * 0.9 + 0.37),
         (c_mid[0] + s * 0.5 + perp[0] * 0.5, c_mid[1] - s * 0.5 + perp[1] * 0.5,
          rayon * 0.9 + 0.37),
         (c_mid[0] + s * 0.5 + perp[0] * 0.5, c_mid[1] + s * 0.5 + perp[1] * 0.5,
          rayon * 0.9 + 0.37),
         (c_mid[0] - s * 0.5 + perp[0] * 0.5, c_mid[1] + s * 0.5 + perp[1] * 0.5,
          rayon * 0.9 + 0.37)],
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


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    ecorce_mats = ["MAT_Tree_CharredBark", "MAT_Tree_Charcoal"]
    pieces = [
        objet_depuis("SM_ThunderstruckTree_Bark", ecorce, ecorce_mats, True),
        objet_depuis("SM_ThunderstruckTree_Heart", coeur,
                     ["MAT_Tree_Heartwood"], False),
        objet_depuis("SM_ThunderstruckTree_Roots", racines,
                     ["MAT_Tree_CharredBark"], False),
    ]
    for suffixe, spec in zip("ABCDE", BRANCHES):
        pieces.append(objet_depuis(
            "SM_ThunderstruckTree_Branch%s" % suffixe,
            lambda bm, s=spec: branche(bm, *s),
            ["MAT_Tree_CharredBark"], True))

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
    # hors contrat, il ne le « signale » pas : il échoue. Aucun de ces
    # seuils n'a bougé en R2B.1.
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
    # La souche doit avoir sa largeur de plan (2,1 m ± 0,35 lobes compris).
    # Le contrôle porte sur l'ÉCORCE SEULE : les contreforts-racines sont un
    # objet distinct précisément pour que cette mesure reste la mesure de la
    # souche.
    ecorce_obj = pieces[0]
    bas_xs = [v.co.x for v in ecorce_obj.data.vertices if v.co.z < 0.3]
    bas_ys = [v.co.y for v in ecorce_obj.data.vertices if v.co.z < 0.3]
    largeur_souche = max(max(bas_xs) - min(bas_xs), max(bas_ys) - min(bas_ys))
    if abs(largeur_souche - SOUCHE_LARGEUR) > 0.35:
        print("[thunderstruck_tree] ERREUR: souche large de %.2f m "
              "(attendu %.1f ± 0,35)" % (largeur_souche, SOUCHE_LARGEUR))
        return 2
    # La cicatrice est réellement CREUSÉE. Contrôle PAR SOMMET, normalisé :
    # chaque sommet du fût vivant est comparé au rayon nominal de SON anneau
    # (le fût s'affine), contre l'angle de la spirale à SON z (la bande
    # descend). Le premier jet comparait tout à un seul z ET prenait pour
    # témoin la face APLATIE de la fente — il mesurait la joue, pas la
    # cicatrice.
    ratios_dans, ratios_hors = [], []
    # La joue de la fente regarde désormais la moitié morte : le témoin
    # doit suivre, sinon le contrôle mesure la paroi ronde et croit que
    # la cicatrice n'est pas creusée.
    joue = AZ_MORT
    for v in ecorce_obj.data.vertices:
        z = v.co.z
        if not (3.4 <= z <= 6.8):
            continue    # fenêtre franche du fût vivant, loin fourche et cime
        t = (z - FOURCHE_Z) / (VIVANT_SOMMET - FOURCHE_Z)
        centre, rayon_nominal = chemin_vivant(t)
        distance = math.hypot(v.co.x - centre[0], v.co.y - centre[1])
        if distance > rayon_nominal * 1.10 or distance < rayon_nominal * 0.4:
            continue    # moignon ou bruit, pas la paroi du fût
        angle = math.atan2(v.co.y - centre[1], v.co.x - centre[0])
        ecart_joue = (angle - joue + math.pi) % (2 * math.pi) - math.pi
        if abs(ecart_joue) < 1.1:
            continue    # face aplatie de la fente : ni bande, ni témoin
        ecart = (angle - angle_cicatrice(z) + math.pi) % (2 * math.pi) - math.pi
        ratio = distance / rayon_nominal
        if abs(ecart) < CICATRICE_DEMI_ANGLE * 0.75:
            ratios_dans.append(ratio)
        elif abs(ecart) > CICATRICE_DEMI_ANGLE * 1.6:
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
