# PROTOTYPES DE MACRO-SILHOUETTE — enveloppe extérieure de la Grotte du
# Couchant. R2a-3.5, agent A.
#
# CE QUE CE FICHIER N'EST PAS. Ce n'est pas une nouvelle grotte. Il n'y a
# ici ni cavité, ni bouche, ni galerie, ni alcôve, ni matériau, ni module
# de détail, ni collision. Trois enveloppes, exportées nues, dont le seul
# but est de répondre à UNE question : la masse tient-elle en silhouette
# noire AVANT les strates et les matériaux ?
#
# POURQUOI IL EXISTE. Verdict du lead sur R2a-3.4, mot pour mot : « les
# trois masses sont mesurables, mais elles lisent encore comme trois tours
# verticales, des sommets plats, une forteresse crénelée, des blocs posés
# côte à côte. La mesure 5,58 / 3,60 / 2,18 m ne remplace pas ce constat. »
# Trois passes avaient optimisé le compteur de proéminences pendant que
# l'image restait un château. Le diagnostic n'est donc plus un coefficient
# à régler : c'est l'architecture du maillage. Les copies de
# `template-detail` ne doivent plus PORTER la silhouette ; elles peuvent
# casser des surfaces, jamais fabriquer des tours ni décider des sommets.
#
# LA CAUSE GÉOMÉTRIQUE DU « CHÂTEAU », lue sur les deux silhouettes
# livrées (`silhouette_grotte_r2a34_055.png`, `_100.png`) :
#
#   1. chaque masse est capée par une face HORIZONTALE — trois sommets
#      plats alignés en hauteur, c'est la définition d'un créneau ;
#   2. les flancs sont des surfaces réglées quasi verticales sur 4 à 6 m
#      de haut : une verticale continue de cette longueur EST une tour,
#      quel que soit le bruit qu'on y applique ;
#   3. les trois masses sont le MÊME objet à trois échelles, posées côte
#      à côte sur un socle dont l'arête basse est horizontale sur toute la
#      largeur — le socle se lit comme une plinthe de rempart.
#
# LA MÉTHODE ICI. Aucune masse n'est capée à plat. Chaque volume est un
# LOFT entre un polygone de sol irrégulier et un RUBAN DE CRÊTE : une
# boucle fermée qui suit une polyligne 3D montante, cassée et inclinée, et
# dont la LARGEUR EST DONNÉE POINT PAR POINT. Le sommet n'est donc jamais
# une face horizontale ; c'est une table inclinée là où le ruban est large
# (2,0 à 2,4 m) et une arête vive là où il est mince (0,25 m).
#
# DEUX ÉCHECS OPPOSÉS SE RÈGLENT LÀ, et il a fallu les rencontrer tous
# les deux pour trouver la borne :
#   * cape horizontale        -> créneau, « forteresse » (R2a-3.4) ;
#   * ruban partout très fin  -> cône, sommet en pointe, « montagne de
#     dessin animé » (première exécution de ce fichier, capturée et
#     jetée).
# La largeur variable est la seule forme qui échappe aux deux.
#
# LE FLANC N'EST PAS UNE DROITE NON PLUS. La première exécution employait
# horiz(t) = t^0,62, une courbe presque droite : trois triangles nets. Un
# flanc de rocher alterne replats et murs, ce qu'imposent les sept points
# de contrôle `RESSAUTS`, décalés en basse fréquence d'azimut pour que les
# vires serpentent au lieu de faire des anneaux — sinon, pièce montée.
#
# TROIS CONSTRUCTIONS INDÉPENDANTES, pas trois réglages :
#
#   A « CUESTA »   — UN seul corps porte l'épaule ET la dominante ; la
#                    crête est une polyligne continue qui monte, se casse
#                    et redescend. Il n'y a donc pas de blocs à poser côte
#                    à côte, puisqu'il n'y a pas de blocs.
#   B « STRATES »  — aucune masse n'est modelée : bancs tabulaires épais,
#                    tous inclinés du même pendage, emboîtés et décalés.
#                    Que des plans inclinés, par construction.
#   C « ÉPERONS »  — trois proues déversées, chacune penchant dans une
#                    direction différente, liées par un talus continu.
#
# L'IMPLANTATION NE BOUGE PAS. Repère identique au générateur réel
# (`make_waterfall_cave.py`) : Blender Z-up, sol à z = 0, bouche à
# l'origine, galerie vers +y, donc la face d'approche du joueur est -y.
# L'export convertit en Y-up. `SEUIL_LOCAL`, `LACET_DEG`, `EXHAUSSEMENT`
# et `APPUIS_MODELE` de `waterfall_cave_place.gd` restent valides tels
# quels — aucun de ces prototypes n'est intégré, et aucun ne demande à
# l'être.
#
# LE LACET DE 45° N'EST PAS CUIT dans le maillage. Conséquence directe
# sur la lecture des captures, à ne pas confondre :
#
#     azimut_glb = azimut_monde + 45°
#     monde  55° (approche joueur)  ->  glb 100°
#     monde 100° (second azimut)    ->  glb 145°
#     monde 225° (arrière, de dos)  ->  glb 270°
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/environment/make_cave_envelope_protos.py

from __future__ import annotations

import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Vector

TAU = math.pi * 2.0

# ---------------------------------------------------------------------------
# EMPRISE CIBLE. Mesurée sur le GLB livré en R2a-3.4 (`gltf_inspect`) :
# 17,2052 x 13,1937 x 16,2433 m, min Y = -3,5503. Le lieu ne grossit pas ;
# on vise le même ordre, jamais davantage. En repère Blender cela donne
# x ∈ [-8,3 ; +8,9], y ∈ [-4,0 ; +12,3], z ∈ [-3,6 ; +9,6].
#
# La hauteur de crête retenue ici est 8,55 m et non 9,64 : à 17 m de large
# pour 9,6 m de haut, le flanc moyen de la masse dominante vaut 62°, et
# c'est précisément ce que l'œil appelle une tour. Baisser d'un mètre et
# élargir le pied change la lecture sans changer l'ordre de grandeur. La
# semelle plantée descend à -1,35 et non -3,55 : elle ne se voit jamais en
# jeu, et une jupe profonde fausse le cadrage des silhouettes.
# ---------------------------------------------------------------------------

Z_PIED = -1.35          # semelle plantée sous le sol — masse POSÉE, pas posée dessus

# Ancrages de plan des trois masses, en mètres, repère Blender.
#
# CES TROIS POINTS SONT LE RÉSULTAT D'UN CALCUL, PAS D'UN GOÛT. La
# contrainte du lead « contrefort droit réellement reculé dans la
# profondeur » entre en conflit direct avec « trois masses séparées aux
# deux azimuts » — c'est ce conflit que R2a-3.4 a déclaré non satisfait,
# en écrivant que la séparation « impose de le poser vers l'avant ».
# Il se résout, et voici comment.
#
# Écran-x à l'azimut monde 55° :  s55  = ( 0,9848 ; -0,1736)
# Écran-x à l'azimut monde 100° : s100 = ( 0,5736 ; -0,8192)
# Profondeur (vers la caméra) à 55° : t55 = (-0,1736 ; -0,9848)
#
# En notant (dx, dy) l'écart contrefort - dominante, il faut simultanément
#   séparation à 100° :  0,5736·dx - 0,8192·dy >= 3
#   recul réel à 55°  :  0,1736·dx + 0,9848·dy >  0
# La première impose dy <= 0,700·dx - 3,663, la seconde dy > -0,176·dx.
# L'intervalle n'est non vide que si dx > 4,18 m. Autrement dit : le
# contrefort PEUT être reculé, à condition d'être aussi NETTEMENT plus à
# droite. La passe précédente le posait à dx ≈ 4 m — juste sous le seuil,
# d'où l'impossibilité constatée alors, qui était réelle mais locale.
#
# Retenu : dx = 6,6 m, dy = +0,7 m.
#   séparation 55° : 6,38 m   séparation 100° : 3,21 m   recul : 1,84 m
ANCRE_EPAULE = Vector((-5.00, 5.30))
ANCRE_DOMINANTE = Vector((-0.80, 4.20))
ANCRE_CONTREFORT = Vector((5.80, 4.90))


# ---------------------------------------------------------------------------
# Outils de maillage
# ---------------------------------------------------------------------------


def _bruit(seed: int, count: int, amp: float) -> list:
    """Perturbations déterministes par pan, autour de 1.

    Déterministe et non « aléatoire » : deux exécutions du script doivent
    rendre le même GLB au bit près, sans quoi aucune comparaison
    avant/après n'est possible.
    """
    rng = random.Random(seed)
    return [1.0 + rng.uniform(-amp, amp) for _ in range(count)]


def _rayon_ellipse(delta: float, demi_grand: float, demi_petit: float) -> float:
    c = math.cos(delta)
    s = math.sin(delta)
    return (demi_grand * demi_petit) / math.sqrt(
        (demi_petit * c) ** 2 + (demi_grand * s) ** 2)


def _densifier(points: list, count: int) -> list:
    """Porte la polyligne à `count` points SANS PERDRE AUCUN SOMMET D'ORIGINE.

    LE PIÈGE QUE CETTE FONCTION ÉVITE, et il a coûté une exécution : un
    rééchantillonnage par abscisse curviligne place ses points à pas
    constant, donc il RATE les sommets de la polyligne. Sur la première
    version, la crête culminait à 8,60 m et le maillage exporté à 7,87 m :
    l'apex avait été raboté de 73 cm par l'échantillonneur, en silence.
    Une silhouette dont le point haut est décidé par l'outil de
    discrétisation, et non par la crête, ne prouve rien.

    On garde donc tous les sommets et on n'insère des points QUE dans les
    segments, en servant d'abord les plus longs. Les points sont des
    n-uplets (x, y, z, largeur_de_ruban) : la largeur s'interpole comme le
    reste.
    """
    if count < len(points):
        raise ValueError("count (%d) < sommets de crête (%d) : augmenter n"
                         % (count, len(points)))
    segments = len(points) - 1
    insertions = [0] * segments
    longueurs = []
    for i in range(segments):
        a, b = points[i], points[i + 1]
        longueurs.append(math.dist(a[:3], b[:3]))
    for _ in range(count - len(points)):
        cible = max(range(segments), key=lambda i: longueurs[i] / (insertions[i] + 1))
        insertions[cible] += 1
    sortie = []
    for i in range(segments):
        sortie.append(tuple(points[i]))
        a, b = points[i], points[i + 1]
        for j in range(insertions[i]):
            u = (j + 1) / (insertions[i] + 1)
            sortie.append(tuple(a[d] + (b[d] - a[d]) * u for d in range(len(a))))
    sortie.append(tuple(points[-1]))
    return sortie


## RESSAUTS DE FLANC. Points de contrôle (t, f) du profil horizontal.
##
## POURQUOI ILS EXISTENT. La première exécution donnait un profil
## horiz(t) = t^0,62, donc une ligne presque droite du pied à la crête :
## en silhouette, trois triangles. La formation avait cessé d'être un
## château pour devenir une montagne de dessin animé — défaut différent,
## échec identique. Un flanc de rocher n'est pas une droite : il alterne
## des replats (f avance vite pour peu de z) et des murs (f avance peu).
## Ces sept points imposent cette alternance ; le bruit par pan les
## décale, de sorte que les replats serpentent au lieu de former des
## anneaux — sans quoi on obtiendrait une pièce montée.
RESSAUTS = [
    (0.00, 0.00),
    (0.13, 0.25),   # évasement du pied — replat
    (0.36, 0.35),   # mur
    (0.46, 0.56),   # vire
    (0.70, 0.66),   # mur
    (0.82, 0.84),   # épaulement
    (1.00, 1.00),
]


def _profil_ressauts(t: float, decal_t: float, decal_f: float) -> float:
    """Profil horizontal par morceaux, monotone, décalé par pan."""
    n = len(RESSAUTS)
    for i in range(n - 1):
        t0, f0 = RESSAUTS[i]
        t1, f1 = RESSAUTS[i + 1]
        if i > 0:
            t0 += decal_t
            f0 += decal_f
        if i + 1 < n - 1:
            t1 += decal_t
            f1 += decal_f
        if t <= t1 or i == n - 2:
            if t1 - t0 <= 1e-9:
                return f1
            u = min(1.0, max(0.0, (t - t0) / (t1 - t0)))
            return f0 + (f1 - f0) * u
    return 1.0


def _ruban_crete(crete: list, n: int) -> list:
    """Boucle fermée de `n` sommets serrée autour d'une polyligne de crête.

    C'EST LA PIÈCE QUI INTERDIT LE SOMMET PLAT ET LE SOMMET POINTU. Le
    loft se termine sur cette boucle au lieu d'un polygone horizontal : la
    face de fermeture est un ruban dont la largeur est donnée POINT PAR
    POINT par la quatrième coordonnée de la crête.

    Les deux échecs successifs se règlent ici, et ils sont opposés :
      * largeur nulle partout -> cône, sommet en pointe, « montagne de
        dessin animé » ;
      * face horizontale       -> créneau, « forteresse ».
    Une largeur de 0,25 m aux extrémités et de 2,0 à 2,6 m au sommet
    donne ce que le lead demande : une TABLE INCLINÉE, cassée à ses deux
    bouts. Ni pointe, ni plateau horizontal.

    `crete` va de l'extrémité « moins » à l'extrémité « plus » le long de
    l'axe de crête. L'indice 0 de la boucle retombe sur l'extrémité
    « plus », et la boucle tourne dans le sens trigonométrique : c'est la
    même convention que les anneaux inférieurs, sans quoi le loft
    vrillerait d'un demi-tour.
    """
    if n % 2 != 0:
        raise ValueError("n pair requis pour un ruban à deux flancs")
    demi = n // 2
    echant = _densifier(crete, demi)
    tangentes = []
    for i in range(demi):
        a = echant[max(0, i - 1)]
        b = echant[min(demi - 1, i + 1)]
        t = Vector((b[0] - a[0], b[1] - a[1]))
        if t.length < 1e-6:
            t = Vector((1.0, 0.0))
        tangentes.append(t.normalized())
    perp = [Vector((-t.y, t.x)) for t in tangentes]
    cote_a, cote_b = [], []
    for p, q in zip(echant, perp):
        demi_l = max(0.10, p[3]) * 0.5
        cote_a.append(Vector((p[0] + q.x * demi_l, p[1] + q.y * demi_l, p[2])))
        cote_b.append(Vector((p[0] - q.x * demi_l, p[1] - q.y * demi_l, p[2])))
    # côté A parcouru de « plus » vers « moins », puis côté B en retour.
    return list(reversed(cote_a)) + cote_b


def _loft(bm: bmesh.types.BMesh, anneaux: list, cape_en_bande: bool = False) -> None:
    """Coud une pile d'anneaux de même cardinal, avec les deux fonds.

    `cape_en_bande` ferme le dernier anneau par une BANDE DE QUADS entre
    ses deux flancs, au lieu d'un n-gone.

    POURQUOI CETTE OPTION EXISTE, ET CE QU'ELLE A COÛTÉ DE NE PAS L'AVOIR.
    Le ruban de crête est une boucle en épingle : elle descend un flanc et
    remonte l'autre. Fermée par un n-gone de 48 sommets, Blender la
    triangule en reliant des points très éloignés de l'épingle — le toit
    obtenu n'est pas la crête mais un assemblage arbitraire. Mesuré sur la
    capture à l'azimut monde 100° : deux cornes à 8,45 et 8,39 m séparées
    par une encoche À FOND PLAT de 0,70 m. Autrement dit un CRÉNEAU, le
    défaut exact que toute cette passe cherche à supprimer, réintroduit
    non par la forme voulue mais par la triangulation du capot.

    Un n-gone convexe (le fond) ne pose pas ce problème ; une épingle, si.
    D'où la bande : chaque quad relie deux échantillons consécutifs de la
    crête sur les deux flancs, et le toit ne peut alors qu'épouser la
    polyligne.
    """
    n = len(anneaux[0])
    verts = [[bm.verts.new(tuple(p)) for p in anneau] for anneau in anneaux]
    for i in range(len(anneaux) - 1):
        bas, haut = verts[i], verts[i + 1]
        for k in range(n):
            k2 = (k + 1) % n
            try:
                bm.faces.new([bas[k], bas[k2], haut[k2], haut[k]])
            except ValueError:
                pass
    try:
        bm.faces.new(list(reversed(verts[0])))
    except ValueError:
        pass
    haut = verts[-1]
    if not cape_en_bande:
        try:
            bm.faces.new(haut)
        except ValueError:
            pass
        return
    demi = n // 2
    for s in range(demi - 1):
        quad = [haut[demi - 1 - s], haut[demi - 2 - s],
                haut[demi + s + 1], haut[demi + s]]
        try:
            bm.faces.new(quad)
        except ValueError:
            pass


def masse_crete(bm, crete, ancre_sol, demi_grand, demi_petit, *, n=16,
                niveaux=11, seed=1, p_flanc=0.66, bombement=0.16,
                biais_amp=0.0, biais_az_deg=270.0, bruit_rayon=0.13,
                z_pied=Z_PIED):
    """Un volume : polygone de sol irrégulier -> ruban de crête incliné.

    `biais_amp` / `biais_az_deg` allongent le pied dans UNE direction du
    plan (azimut absolu, repère Blender). C'est ce décalage, et non un
    paramètre de pente, qui produit un flanc long d'un côté et un
    escarpement court de l'autre. Un pied centré sous sa crête est
    symétrique par construction, et aucune quantité de bruit ne le
    dissymétrise.
    """
    crete = [tuple(p) for p in crete]
    axe = Vector((crete[-1][0] - crete[0][0], crete[-1][1] - crete[0][1]))
    psi = math.atan2(axe.y, axe.x) if axe.length > 1e-6 else 0.0
    biais_az = math.radians(biais_az_deg)

    ruban = _ruban_crete(crete, n)
    rayon_bruit = _bruit(seed, n, bruit_rayon)
    bombe_bruit = _bruit(seed + 97, n, 1.0)
    p_bruit = _bruit(seed + 41, n, 0.10)

    base = []
    dehors = []
    for k in range(n):
        a = psi + TAU * k / n
        r = _rayon_ellipse(a - psi, demi_grand, demi_petit) * rayon_bruit[k]
        r *= 1.0 + biais_amp * math.cos(a - biais_az)
        d = Vector((math.cos(a), math.sin(a)))
        dehors.append(d)
        base.append(Vector((ancre_sol.x + d.x * r, ancre_sol.y + d.y * r, z_pied)))

    # Décalages des ressauts, en BASSE FRÉQUENCE d'azimut et non en bruit
    # blanc : deux pans voisins doivent partager leur vire, sinon les
    # replats se hachent en dents de scie au lieu de serpenter.
    decal_t = [0.040 * math.sin(TAU * k / n + seed * 0.7)
               + 0.022 * math.sin(2.0 * TAU * k / n + seed * 1.3) for k in range(n)]
    decal_f = [0.038 * math.sin(TAU * k / n + seed * 1.9 + 1.1)
               for k in range(n)]

    anneaux = []
    for i in range(niveaux):
        t = i / (niveaux - 1)
        anneau = []
        for k in range(n):
            # `p_flanc` module encore le profil à ressauts : < 1 conserve
            # le pied évasé, > 1 le redresse.
            f = _profil_ressauts(t, decal_t[k], decal_f[k])
            f = f ** max(0.55, p_flanc * p_bruit[k] * 1.45)
            x = base[k].x + (ruban[k].x - base[k].x) * f
            y = base[k].y + (ruban[k].y - base[k].y) * f
            # Renflement de mi-hauteur : sans lui le flanc est une surface
            # réglée, et une surface réglée se lit comme une plaque.
            g = bombement * bombe_bruit[k] * math.sin(math.pi * t)
            x += dehors[k].x * g
            y += dehors[k].y * g
            z = z_pied + (ruban[k].z - z_pied) * t
            anneau.append(Vector((x, y, z)))
        anneaux.append(anneau)
    _loft(bm, anneaux, cape_en_bande=True)


def banc(bm, centre, psi_deg, demi_grand, demi_petit, *, plan, epaisseur,
         n=13, seed=1, fruit=0.86, bruit_amp=0.14):
    """Un banc tabulaire épais, compris entre deux plans PARALLÈLES inclinés.

    `plan` = (z0, kx, ky) : la face supérieure vaut z0 + kx·x + ky·y. Le
    banc n'a donc ni face horizontale ni face verticale — ses joues sont
    frustées par `fruit` (rapport haut/bas des rayons).
    """
    psi = math.radians(psi_deg)
    z0, kx, ky = plan
    rayons = _bruit(seed, n, bruit_amp)
    bas, haut = [], []
    for k in range(n):
        a = psi + TAU * k / n
        r = _rayon_ellipse(a - psi, demi_grand, demi_petit) * rayons[k]
        d = Vector((math.cos(a), math.sin(a)))
        xb = centre.x + d.x * r
        yb = centre.y + d.y * r
        xh = centre.x + d.x * r * fruit
        yh = centre.y + d.y * r * fruit
        bas.append(Vector((xb, yb, z0 + kx * xb + ky * yb - epaisseur)))
        haut.append(Vector((xh, yh, z0 + kx * xh + ky * yh)))
    _loft(bm, [bas, haut])


def _objet(nom: str, bm: bmesh.types.BMesh) -> bpy.types.Object:
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(nom)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nom, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


# ---------------------------------------------------------------------------
# PROTOTYPE A — « CUESTA À RESSAUTS »
#
# Un seul corps porte l'épaule gauche ET la masse dominante : la crête est
# une polyligne continue de vingt-deux sommets qui monte par paliers,
# marque un col, culmine sur une TABLE INCLINÉE décentrée, se casse et
# plonge. La formation ne peut pas se lire comme des blocs posés côte à
# côte, puisqu'il n'y a pas de blocs — les « trois masses » sont trois
# bosses d'un même relief. Le contrefort est un corps séparé, reculé, qui
# émerge de derrière l'escarpement.
#
# Chaque quadruplet est (x, y, z, largeur_de_ruban). Les largeurs sont le
# vrai levier de lecture : 0,25 m aux extrémités donne une arête, 0,8 à
# 1,3 m donne un replat, 2,1 à 2,4 m donne la table sommitale.
# ---------------------------------------------------------------------------


def proto_a() -> list:
    objets = []

    # Corps principal. Rampe gauche à ressauts, épaule 4,30, col A 2,80
    # (1,50 m plus bas), montée par deux vires, table sommitale de 8,45 à
    # 8,10 sur 0,65 m — soit 9° d'inclinaison —, cassure, puis plongée.
    crete = [
        (-7.80, 7.05, 0.55, 0.25),
        (-7.05, 6.80, 1.55, 0.45),
        (-6.55, 6.60, 1.70, 0.75),   # vire
        (-5.80, 6.30, 2.85, 0.50),
        (-5.35, 6.05, 3.05, 0.85),   # vire
        (-4.70, 5.70, 4.45, 0.55),
        (-4.25, 5.45, 4.85, 1.20),   # épaule : petite table inclinée
        (-3.75, 5.20, 4.35, 0.70),
        (-3.45, 5.05, 3.45, 0.45),
        (-2.85, 4.75, 2.55, 0.55),   # col A
        (-2.35, 4.55, 3.95, 0.40),
        (-2.00, 4.40, 4.25, 0.75),   # vire
        (-1.45, 4.20, 5.85, 0.45),
        (-1.10, 4.10, 6.15, 0.70),   # vire
        (-0.55, 3.95, 7.65, 0.95),
        (-0.10, 3.85, 8.35, 1.35),   # table sommitale, début
        (0.60, 3.70, 8.10, 1.45),    # table sommitale, fin — 20° d'inclinaison
        (1.05, 3.60, 7.35, 1.05),    # cassure
        (1.45, 3.55, 6.60, 1.15),    # vire
        (1.85, 3.50, 4.55, 0.55),
        (2.15, 3.45, 4.05, 0.85),    # vire
        (2.45, 3.40, 2.05, 0.30),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete,
                ancre_sol=Vector((-2.60, 4.40)),
                demi_grand=5.30, demi_petit=4.80,
                n=48, niveaux=15, seed=11,
                p_flanc=0.62, bombement=0.22,
                biais_amp=0.17, biais_az_deg=248.0)
    objets.append(_objet("SM_ProtoA_Corps", bm))

    # Contrefort droit — reculé de 1,84 m, plus petit, crête descendante.
    crete_c = [
        (3.95, 6.00, 1.85, 0.25),
        (4.45, 5.75, 3.00, 0.45),
        (4.85, 5.55, 3.25, 0.95),    # vire
        (5.35, 5.25, 4.20, 0.55),
        (5.75, 5.05, 4.55, 1.25),    # table
        (6.15, 4.90, 4.30, 0.90),
        (6.70, 4.70, 3.35, 0.50),
        (7.10, 4.60, 3.10, 0.80),    # vire
        (7.55, 4.45, 1.45, 0.25),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_c,
                ancre_sol=Vector((5.75, 5.15)),
                demi_grand=2.60, demi_petit=2.35,
                n=22, niveaux=12, seed=23,
                p_flanc=0.70, bombement=0.16,
                biais_amp=0.18, biais_az_deg=300.0)
    objets.append(_objet("SM_ProtoA_Contrefort", bm))

    # Talus continu. Il ne doit surtout PAS être une plinthe : sa crête
    # ondule de 0,85 à 3,55 m et son plan est franchement dissymétrique,
    # large à l'avant-gauche, mince à droite.
    crete_t = [
        (-8.20, 3.20, 0.95, 0.35),
        (-6.90, 2.55, 2.10, 0.90),
        (-5.80, 1.95, 2.55, 1.60),
        (-4.40, 1.45, 2.30, 1.10),
        (-3.10, 1.05, 2.15, 1.80),
        (-1.70, 0.90, 2.45, 1.30),
        (-0.40, 0.85, 2.30, 1.70),
        (0.90, 1.25, 3.05, 1.20),
        (2.20, 1.75, 3.05, 1.60),
        (3.60, 2.35, 2.55, 1.20),
        (4.90, 2.95, 2.05, 1.50),
        (6.20, 3.45, 1.55, 1.00),
        (7.40, 3.95, 0.85, 0.35),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_t,
                ancre_sol=Vector((-0.35, 3.60)),
                demi_grand=7.60, demi_petit=4.90,
                n=28, niveaux=9, seed=37,
                p_flanc=0.56, bombement=0.28,
                biais_amp=0.16, biais_az_deg=250.0)
    objets.append(_objet("SM_ProtoA_Talus", bm))

    # Queue enterrée au nord : la masse se perd dans le ressaut au lieu de
    # s'arrêter net. C'est ce qui manque le plus à la vue arrière.
    #
    # SON ALTITUDE EST DÉSORMAIS CONTRAINTE PAR UNE MESURE, pas choisie.
    # À l'azimut monde 55° un rayon de projection est presque parallèle à
    # l'axe de la galerie (0,176 m en x pour 1 m en y) : il balaie donc
    # TOUTE la profondeur du massif à x constant. La queue, à y ≈ 8,9 et
    # z = 4,15, retombait ainsi exactement dans le col A et en relevait le
    # fond de 3,90 à 5,51 m — l'épaule n'avait plus que 0,67 m de
    # proéminence, à peine au-dessus de l'entaille de 0,60. Une masse
    # située à neuf mètres derrière décidait de la lisibilité de l'épaule,
    # et rien dans l'image ne le disait.
    #
    # D'où le creux à (-2,60 ; 8,85) : c'est le seul sommet de queue dont
    # le rayon traverse le col. Les autres sont conservés, sinon la queue
    # cesse d'enterrer le massif — ce que la vue arrière paierait.
    crete_q = [
        (-3.90, 8.20, 3.10, 0.60),
        (-2.60, 8.85, 2.75, 1.40),   # creux : voir ci-dessus
        (-1.30, 9.45, 3.55, 2.00),
        (0.10, 9.90, 3.50, 1.60),
        (1.40, 10.20, 3.05, 1.80),
        (2.60, 10.10, 2.50, 1.20),
        (3.80, 9.90, 1.80, 0.40),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_q,
                ancre_sol=Vector((-0.40, 8.40)),
                demi_grand=5.60, demi_petit=3.40,
                n=18, niveaux=9, seed=53,
                p_flanc=0.60, bombement=0.22,
                biais_amp=0.20, biais_az_deg=90.0)
    objets.append(_objet("SM_ProtoA_Queue", bm))
    return objets


# ---------------------------------------------------------------------------
# PROTOTYPE B — « STRATES BASCULÉES »
#
# Aucune masse n'est modelée : la formation est une pile de onze bancs
# tabulaires inclinés, emboîtés et décalés. Le profil supérieur est donc,
# par construction, une succession de segments inclinés séparés par des
# ressauts — jamais une horizontale, jamais une verticale continue.
# L'escalier est long à gauche (rampe) et court à droite (escarpement) :
# la même cuesta que A, par un tout autre chemin.
#
# CHAQUE BANC EST DÉFINI PAR SES DEUX BOUTS, pas par un plan abstrait :
# (x0, z0) -> (x1, z1). Le pendage s'en déduit. Écrire le plan et espérer
# l'altitude, c'est ce que faisait la première version — et deux bancs
# flottaient à 0,4 m au-dessus de leur porteur sans que rien ne le crie.
# Le recouvrement de chaque banc par le suivant est ici VÉRIFIÉ à la main,
# banc par banc, et l'épaisseur choisie en conséquence.
#
# RISQUE ASSUMÉ, ET NOMMÉ : c'est la construction la plus exposée au
# reproche que le lead a porté sur la vue arrière — « plaques et piliers,
# volumes qui paraissent assemblés ». D'où des bancs ÉPAIS (1,5 à 4,0 m),
# jamais des plaques.
# ---------------------------------------------------------------------------


def banc_x(bm, x0, x1, z0, z1, *, y, dp, epaisseur, psi_deg=0.0, ky=0.0,
           n=13, seed=1, fruit=0.87):
    """Un banc défini par ses deux extrémités en x et leurs altitudes."""
    kx = (z1 - z0) / (x1 - x0)
    plan = (z0 - kx * x0 - ky * y, kx, ky)
    centre = Vector(((x0 + x1) * 0.5, y))
    demi_grand = (x1 - x0) * 0.5 / max(0.6, math.cos(math.radians(psi_deg)))
    banc(bm, centre, psi_deg, demi_grand, dp, plan=plan, epaisseur=epaisseur,
         n=n, seed=seed, fruit=fruit)


def proto_b() -> list:
    objets = []

    # Assise : deux bancs larges, faible pendage, qui portent tout et
    # plantent la formation. Leur face inférieure reste sous z = 0 sur
    # toute leur emprise — sinon la formation flotte.
    bm = bmesh.new()
    banc_x(bm, -8.60, 3.00, 0.35, 2.30, y=4.60, dp=4.30, epaisseur=2.60,
           psi_deg=6.0, ky=0.03, n=15, seed=101, fruit=0.91)
    banc_x(bm, -2.40, 8.60, 2.20, 0.90, y=5.30, dp=4.00, epaisseur=3.00,
           psi_deg=-6.0, ky=0.02, n=14, seed=113, fruit=0.90)
    objets.append(_objet("SM_ProtoB_Assise", bm))

    # Rampe gauche : deux bancs, pendage croissant, qui montent à l'épaule.
    bm = bmesh.new()
    banc_x(bm, -7.60, -2.40, 1.35, 3.55, y=5.00, dp=3.40, epaisseur=2.30,
           psi_deg=14.0, ky=0.05, n=14, seed=127, fruit=0.87)
    banc_x(bm, -6.00, -3.40, 2.85, 5.05, y=4.95, dp=2.90, epaisseur=2.10,
           psi_deg=22.0, ky=0.04, n=13, seed=139, fruit=0.85)
    objets.append(_objet("SM_ProtoB_Rampe", bm))

    # Dominante : quatre bancs de moins en moins longs, décalés vers +x.
    # Le dernier a un pendage INVERSÉ : la crête kinke au lieu de
    # continuer, et le sommet devient une table inclinée à 12,5°.
    bm = bmesh.new()
    banc_x(bm, -3.20, 3.40, 3.15, 4.60, y=4.45, dp=3.20, epaisseur=3.20,
           psi_deg=10.0, ky=0.04, n=14, seed=151, fruit=0.86)
    banc_x(bm, -1.70, 3.00, 4.90, 6.10, y=4.35, dp=2.70, epaisseur=1.60,
           psi_deg=18.0, ky=0.03, n=13, seed=163, fruit=0.84)
    banc_x(bm, -0.70, 2.60, 6.60, 7.60, y=4.40, dp=2.20, epaisseur=1.70,
           psi_deg=26.0, ky=0.03, n=12, seed=173, fruit=0.82)
    banc_x(bm, 0.50, 2.30, 8.35, 7.95, y=4.70, dp=1.70, epaisseur=1.50,
           psi_deg=38.0, ky=-0.05, n=12, seed=181, fruit=0.78)
    objets.append(_objet("SM_ProtoB_Dominante", bm))

    # Contrefort droit, reculé : deux bancs à pendage INVERSÉ, donc une
    # crête qui descend vers la droite au lieu de prolonger la rampe.
    bm = bmesh.new()
    banc_x(bm, 3.40, 7.80, 1.90, 1.30, y=5.55, dp=2.60, epaisseur=2.20,
           psi_deg=-20.0, ky=0.05, n=13, seed=191, fruit=0.89)
    banc_x(bm, 3.90, 6.50, 4.45, 3.85, y=5.30, dp=2.05, epaisseur=2.80,
           psi_deg=-34.0, ky=0.04, n=12, seed=199, fruit=0.82)
    objets.append(_objet("SM_ProtoB_Contrefort", bm))

    # Queue enterrée, banc épais prolongé vers le nord.
    bm = bmesh.new()
    banc_x(bm, -5.00, 4.00, 2.60, 3.40, y=9.30, dp=3.30, epaisseur=4.00,
           psi_deg=4.0, ky=-0.06, n=14, seed=211, fruit=0.90)
    objets.append(_objet("SM_ProtoB_Queue", bm))
    return objets


# ---------------------------------------------------------------------------
# PROTOTYPE C — « ÉPERONS OBLIQUES »
#
# Trois proues déversées, penchant chacune dans une direction différente
# — l'épaule vers l'avant-gauche, la dominante vers l'arrière (elle
# surplombe donc la future bouche), le contrefort vers la droite. Le
# déversement vient du décalage entre le polygone de sol et le ruban de
# crête : aucun flanc ne peut alors être vertical, et les trois masses ne
# partagent aucune direction — donc aucune symétrie possible.
#
# RISQUE ASSUMÉ : c'est le prototype qui s'éloigne le plus de la lecture
# « un seul rocher ». Le talus continu est ici structurel, pas décoratif :
# c'est lui qui empêche la lecture « trois rochers séparés ».
# ---------------------------------------------------------------------------


def proto_c() -> list:
    objets = []

    # Épaule gauche : basse, large, déversée vers l'avant-gauche ; sa
    # crête est une croupe qui descend vers l'extérieur, pas une table.
    crete_g = [
        (-7.35, 6.40, 1.55, 0.30),
        (-6.75, 5.95, 2.60, 0.55),
        (-6.25, 5.60, 2.85, 0.95),
        (-5.65, 5.15, 3.95, 0.60),
        (-5.15, 4.80, 4.55, 1.35),
        (-4.60, 4.40, 4.15, 0.90),
        (-4.10, 4.05, 3.60, 0.55),
        (-3.65, 3.70, 3.35, 0.85),
        (-3.20, 3.35, 2.40, 0.30),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_g,
                ancre_sol=Vector((-5.10, 6.10)),
                demi_grand=4.10, demi_petit=3.40,
                n=22, niveaux=13, seed=301,
                p_flanc=0.60, bombement=0.26,
                biais_amp=0.20, biais_az_deg=215.0)
    objets.append(_objet("SM_ProtoC_Epaule", bm))

    # Dominante : proue déversée vers l'arrière (+y). Le pied est en
    # avant, la crête en arrière : le front est en dévers, jamais une
    # paroi — et c'est ce dévers qui abritera la bouche.
    crete_d = [
        (-2.75, 6.85, 4.35, 0.35),
        (-2.30, 6.55, 5.55, 0.65),
        (-2.00, 6.35, 5.80, 1.05),
        (-1.55, 6.05, 7.05, 0.60),
        (-1.15, 5.75, 7.35, 1.05),
        (-0.60, 5.35, 8.45, 1.30),
        (0.15, 4.85, 8.10, 1.45),
        (0.55, 4.60, 7.20, 0.95),
        (1.00, 4.35, 6.75, 1.10),
        (1.60, 4.05, 4.80, 0.55),
        (2.05, 3.85, 4.50, 0.85),
        (2.50, 3.65, 2.60, 0.30),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_d,
                ancre_sol=Vector((-0.60, 3.60)),
                demi_grand=4.60, demi_petit=4.10,
                n=26, niveaux=14, seed=317,
                p_flanc=0.64, bombement=0.24,
                biais_amp=0.22, biais_az_deg=250.0)
    objets.append(_objet("SM_ProtoC_Dominante", bm))

    # Contrefort droit : reculé, penché vers +x, crête courte et oblique.
    crete_c = [
        (4.10, 6.35, 2.10, 0.30),
        (4.60, 6.00, 3.35, 0.55),
        (5.05, 5.70, 3.65, 1.05),
        (5.55, 5.40, 4.60, 0.60),
        (6.05, 5.10, 4.95, 1.30),
        (6.50, 4.90, 4.55, 0.95),
        (7.10, 4.70, 3.05, 0.30),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_c,
                ancre_sol=Vector((5.35, 5.85)),
                demi_grand=2.70, demi_petit=2.40,
                n=18, niveaux=12, seed=331,
                p_flanc=0.68, bombement=0.18,
                biais_amp=0.24, biais_az_deg=330.0)
    objets.append(_objet("SM_ProtoC_Contrefort", bm))

    # Talus liant — ici structurel. Deux corps qui se recouvrent, jamais
    # une nappe unique : une nappe unique redonnerait la plinthe.
    crete_t1 = [
        (-7.90, 3.90, 1.05, 0.35),
        (-6.60, 3.05, 2.35, 1.10),
        (-5.30, 2.25, 2.85, 1.70),
        (-3.80, 1.65, 2.55, 1.20),
        (-2.30, 1.15, 3.70, 1.80),
        (-0.95, 1.35, 2.85, 1.30),
        (0.40, 1.55, 2.45, 1.60),
        (1.60, 2.15, 1.95, 1.10),
        (2.80, 2.75, 1.25, 0.35),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_t1,
                ancre_sol=Vector((-2.50, 3.70)),
                demi_grand=5.80, demi_petit=4.20,
                n=22, niveaux=9, seed=347,
                p_flanc=0.56, bombement=0.30,
                biais_amp=0.18, biais_az_deg=250.0)
    objets.append(_objet("SM_ProtoC_TalusOuest", bm))

    crete_t2 = [
        (1.20, 2.95, 2.15, 0.40),
        (2.40, 3.30, 2.85, 1.20),
        (3.60, 3.65, 3.15, 1.70),
        (4.70, 4.15, 2.85, 1.30),
        (5.80, 4.65, 2.40, 1.50),
        (6.65, 5.10, 1.75, 1.00),
        (7.50, 5.60, 1.00, 0.35),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_t2,
                ancre_sol=Vector((4.50, 5.20)),
                demi_grand=4.60, demi_petit=3.50,
                n=18, niveaux=9, seed=359,
                p_flanc=0.58, bombement=0.26,
                biais_amp=0.18, biais_az_deg=280.0)
    objets.append(_objet("SM_ProtoC_TalusEst", bm))

    # Queue enterrée.
    crete_q = [
        (-3.40, 8.70, 3.40, 0.50),
        (-2.10, 9.30, 4.05, 1.30),
        (-0.70, 9.75, 4.35, 1.90),
        (0.70, 10.05, 4.00, 1.50),
        (2.10, 10.15, 3.15, 1.70),
        (3.30, 9.95, 2.45, 1.10),
        (4.40, 9.60, 1.70, 0.35),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_q,
                ancre_sol=Vector((0.10, 8.80)),
                demi_grand=5.30, demi_petit=3.20,
                n=18, niveaux=9, seed=367,
                p_flanc=0.60, bombement=0.22,
                biais_amp=0.20, biais_az_deg=90.0)
    objets.append(_objet("SM_ProtoC_Queue", bm))
    return objets


# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

RACINE = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
SORTIE = os.path.join(RACINE, "assets", "environment", "caves", "prototypes")

OPTIONS = {
    "export_format": "GLB",
    "export_yup": True,
    "export_apply": True,
    "export_texcoords": False,
    "export_normals": True,
    "export_tangents": False,
    "export_materials": "NONE",
    "export_cameras": False,
    "export_lights": False,
    "export_extras": False,
    "export_skins": False,
    "export_animations": False,
}


def _vider() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _emprise(objets: list) -> tuple:
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for ob in objets:
        for v in ob.data.vertices:
            p = ob.matrix_world @ v.co
            for i in range(3):
                lo[i] = min(lo[i], p[i])
                hi[i] = max(hi[i], p[i])
    return lo, hi


def _exporter(nom: str, objets: list) -> None:
    for ob in objets:
        ob.data.calc_loop_triangles()
    lo, hi = _emprise(objets)
    tris = sum(len(ob.data.loop_triangles) for ob in objets)
    print("[protos] %-8s corps=%d tris=%d" % (nom, len(objets), tris))
    print("[protos]   Blender  x %.2f..%.2f   y %.2f..%.2f   z %.2f..%.2f"
          % (lo.x, hi.x, lo.y, hi.y, lo.z, hi.z))
    print("[protos]   emprise  %.2f x %.2f x %.2f m — crête hors sol %.2f m"
          % (hi.x - lo.x, hi.y - lo.y, hi.z - lo.z, hi.z))
    os.makedirs(SORTIE, exist_ok=True)
    chemin = os.path.join(SORTIE, "SM_CaveEnvelope_%s.glb" % nom)
    dispo = set(bpy.ops.export_scene.gltf.get_rna_type().properties.keys())
    opts = {k: v for k, v in OPTIONS.items() if k in dispo}
    bpy.ops.export_scene.gltf(filepath=chemin, **opts)
    if not os.path.exists(chemin):
        raise RuntimeError("export manqué : %s" % chemin)
    print("[protos]   -> %s (%d octets)" % (chemin, os.path.getsize(chemin)))


def main() -> int:
    print("[protos] Blender %s" % bpy.app.version_string)
    for nom, fabrique in (("ProtoA", proto_a), ("ProtoB", proto_b),
                          ("ProtoC", proto_c)):
        _vider()
        _exporter(nom, fabrique())
    print("[protos] OK — 3 prototypes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
