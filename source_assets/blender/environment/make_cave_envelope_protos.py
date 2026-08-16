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
# boucle fermée très étroite (0,30 m) qui suit une polyligne 3D montante,
# cassée et inclinée. Le sommet n'est donc pas une face horizontale mais
# une ARÊTE, et sa pente est un paramètre, pas un accident. C'est la
# différence structurelle avec la version rejetée, et elle ne peut pas se
# perdre au réglage : il n'existe aucune valeur des paramètres qui rende
# un sommet plat.
#
# Le profil de flanc suit horiz(t) = t^p avec p < 1. La pente vaut alors
# dz/dh ∝ 1/(p·t^(p-1)) : nulle en t = 0 (pied évasé, masse POSÉE au sol)
# et maximale en t = 1 (crête vive). Un p > 1 donnerait l'inverse — pied
# vertical et sommet évasé, soit exactement le champignon qu'on ne veut
# pas. Le sens de cette inégalité est le cœur du fichier.
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
LARGEUR_RUBAN = 0.30    # largeur de la boucle de crête : une arête, pas un plateau

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


def _densifier(polyline: list, count: int) -> list:
    """Porte la polyligne à `count` points SANS PERDRE AUCUN SOMMET D'ORIGINE.

    LE PIÈGE QUE CETTE FONCTION ÉVITE, et il a coûté une passe de mesure :
    un rééchantillonnage par abscisse curviligne place ses points à pas
    constant, donc il RATE les sommets de la polyligne. Sur la première
    exécution, la crête culminait à 8,60 m et le maillage exporté à
    7,87 m : l'apex avait été raboté de 73 cm par l'échantillonneur, en
    silence. Une silhouette dont le point haut est décidé par l'outil de
    discrétisation et non par la crête ne prouve rien.

    On garde donc tous les sommets et on n'insère des points QUE dans les
    segments, en servant d'abord les plus longs.
    """
    if count < len(polyline):
        raise ValueError("count (%d) < sommets de crête (%d) : augmenter n"
                         % (count, len(polyline)))
    segments = len(polyline) - 1
    insertions = [0] * segments
    longueurs = [(polyline[i + 1] - polyline[i]).length for i in range(segments)]
    reste = count - len(polyline)
    for _ in range(reste):
        # Le segment dont le pas courant est le plus grand reçoit le point.
        cible = max(range(segments), key=lambda i: longueurs[i] / (insertions[i] + 1))
        insertions[cible] += 1
    sortie = []
    for i in range(segments):
        sortie.append(polyline[i])
        for j in range(insertions[i]):
            u = (j + 1) / (insertions[i] + 1)
            sortie.append(polyline[i].lerp(polyline[i + 1], u))
    sortie.append(polyline[-1])
    return sortie


def _ruban_crete(crete: list, n: int, largeur: float) -> list:
    """Boucle fermée de `n` sommets serrée autour d'une polyligne de crête.

    C'EST LA PIÈCE QUI INTERDIT LE SOMMET PLAT. Le loft se termine sur
    cette boucle au lieu d'un polygone horizontal : la face de fermeture
    est un ruban de `largeur` mètres, donc l'œil lit une arête et sa
    pente, jamais une table.

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
        t = Vector((b.x - a.x, b.y - a.y))
        if t.length < 1e-6:
            t = Vector((1.0, 0.0))
        tangentes.append(t.normalized())
    perp = [Vector((-t.y, t.x)) for t in tangentes]
    demi_l = largeur * 0.5
    cote_a = [Vector((p.x + q.x * demi_l, p.y + q.y * demi_l, p.z))
              for p, q in zip(echant, perp)]
    cote_b = [Vector((p.x - q.x * demi_l, p.y - q.y * demi_l, p.z))
              for p, q in zip(echant, perp)]
    # côté A parcouru de « plus » vers « moins », puis côté B en retour.
    return list(reversed(cote_a)) + cote_b


def _loft(bm: bmesh.types.BMesh, anneaux: list) -> None:
    """Coud une pile d'anneaux de même cardinal, avec les deux fonds."""
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
    for boucle in (list(reversed(verts[0])), verts[-1]):
        try:
            bm.faces.new(boucle)
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
    crete = [Vector(p) for p in crete]
    axe = Vector((crete[-1].x - crete[0].x, crete[-1].y - crete[0].y))
    psi = math.atan2(axe.y, axe.x) if axe.length > 1e-6 else 0.0
    biais_az = math.radians(biais_az_deg)

    ruban = _ruban_crete(crete, n, LARGEUR_RUBAN)
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

    anneaux = []
    for i in range(niveaux):
        t = i / (niveaux - 1)
        anneau = []
        for k in range(n):
            p = max(0.30, p_flanc * p_bruit[k])
            f = t ** p
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
    _loft(bm, anneaux)


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
# PROTOTYPE A — « CUESTA »
#
# Un seul corps porte l'épaule gauche ET la masse dominante : la crête est
# une polyligne continue de douze sommets qui monte en rampe, marque un
# col, culmine à 8,55 décentré, se casse et plonge. La formation ne peut
# pas se lire comme des blocs posés côte à côte, puisqu'il n'y a pas de
# blocs — les « trois masses » sont trois bosses d'un même relief.
# Le contrefort est un corps séparé, reculé, qui émerge de derrière
# l'escarpement.
# ---------------------------------------------------------------------------


def proto_a() -> list:
    objets = []

    # Corps principal. Rampe gauche à 39° (0,55 -> 4,30 sur 4,6 m), col A
    # à 2,80, montée à 8,55, cassure à 7,15, plongée vers le col B.
    crete = [
        (-7.80, 6.10, 0.55),
        (-6.55, 5.75, 1.90),
        (-5.35, 5.30, 3.15),
        (-4.25, 4.85, 4.30),   # épaule — sommet local
        (-3.45, 4.50, 3.55),
        (-2.85, 4.20, 2.80),   # col A : 1,50 m sous l'épaule
        (-2.00, 3.95, 5.05),
        (-1.00, 3.90, 7.10),
        (-0.10, 4.15, 8.55),   # sommet dominant, décentré
        (0.75, 4.55, 7.15),    # cassure
        (1.55, 4.95, 5.05),
        (2.40, 5.30, 2.35),    # descente vers le col B
    ]
    bm = bmesh.new()
    masse_crete(bm, crete,
                ancre_sol=Vector((-2.70, 4.60)),
                demi_grand=5.70, demi_petit=4.30,
                n=26, niveaux=13, seed=11,
                p_flanc=0.62, bombement=0.22,
                biais_amp=0.20, biais_az_deg=260.0)
    objets.append(_objet("SM_ProtoA_Corps", bm))

    # Contrefort droit — reculé de 1,84 m, plus petit, crête descendante.
    crete_c = [
        (3.95, 6.00, 1.85),
        (4.85, 5.55, 3.60),
        (5.75, 5.05, 4.55),
        (6.70, 4.70, 3.35),
        (7.55, 4.45, 1.45),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_c,
                ancre_sol=Vector((5.75, 5.15)),
                demi_grand=2.60, demi_petit=2.35,
                n=16, niveaux=10, seed=23,
                p_flanc=0.70, bombement=0.16,
                biais_amp=0.18, biais_az_deg=300.0)
    objets.append(_objet("SM_ProtoA_Contrefort", bm))

    # Talus continu. Il ne doit surtout PAS être une plinthe : sa crête
    # ondule de 0,95 à 3,55 m et son plan est franchement dissymétrique,
    # large à l'avant-gauche, mince à droite.
    crete_t = [
        (-8.20, 3.20, 0.95),
        (-5.80, 1.95, 2.55),
        (-3.10, 1.05, 3.55),
        (-0.40, 0.85, 2.30),
        (2.20, 1.75, 3.20),
        (4.90, 2.95, 2.05),
        (7.40, 3.95, 0.85),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_t,
                ancre_sol=Vector((-0.35, 3.60)),
                demi_grand=7.60, demi_petit=4.90,
                n=18, niveaux=7, seed=37,
                p_flanc=0.56, bombement=0.28,
                biais_amp=0.16, biais_az_deg=250.0)
    objets.append(_objet("SM_ProtoA_Talus", bm))

    # Queue enterrée au nord : la masse se perd dans le ressaut au lieu de
    # s'arrêter net. C'est ce qui manque le plus à la vue arrière.
    crete_q = [
        (-3.90, 8.20, 3.60),
        (-1.30, 9.45, 4.45),
        (1.40, 10.20, 3.30),
        (3.80, 9.90, 1.85),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_q,
                ancre_sol=Vector((-0.40, 8.40)),
                demi_grand=5.60, demi_petit=3.40,
                n=16, niveaux=8, seed=53,
                p_flanc=0.60, bombement=0.22,
                biais_amp=0.20, biais_az_deg=90.0)
    objets.append(_objet("SM_ProtoA_Queue", bm))
    return objets


# ---------------------------------------------------------------------------
# PROTOTYPE B — « STRATES BASCULÉES »
#
# Aucune masse n'est modelée : la formation est une pile de bancs
# tabulaires, tous inclinés, emboîtés et décalés vers +x. Le profil
# supérieur est donc, par construction, une succession de segments
# inclinés séparés par des ressauts — jamais une horizontale, jamais une
# verticale continue. L'escalier est long à gauche (rampe) et court à
# droite (escarpement) : la même cuesta que A, par un tout autre chemin.
#
# RISQUE ASSUMÉ, ET NOMMÉ : c'est la construction la plus exposée au
# reproche que le lead a porté sur la vue arrière — « plaques et piliers,
# volumes qui paraissent assemblés ». D'où des bancs ÉPAIS (1,2 à 3,6 m),
# jamais des plaques, et un recouvrement franc de chaque banc par le
# suivant.
# ---------------------------------------------------------------------------


def proto_b() -> list:
    objets = []

    # Assise : deux bancs larges, faible pendage, qui portent tout et
    # plantent la formation. Leur face inférieure reste sous z = 0 sur
    # toute leur emprise — sinon la formation flotte.
    bm = bmesh.new()
    banc(bm, Vector((-3.00, 4.90)), 8.0, 5.60, 4.40,
         plan=(2.10, 0.160, 0.045), epaisseur=3.10, n=15, seed=101, fruit=0.91)
    banc(bm, Vector((3.40, 5.20)), -7.0, 4.70, 4.10,
         plan=(2.55, 0.100, 0.030), epaisseur=3.60, n=14, seed=113, fruit=0.90)
    objets.append(_objet("SM_ProtoB_Assise", bm))

    # Rampe gauche : deux bancs à fort pendage (0,42 = 22,8°), de plus en
    # plus courts vers le haut et décalés vers +x.
    bm = bmesh.new()
    banc(bm, Vector((-4.60, 5.20)), 12.0, 4.40, 3.40,
         plan=(5.40, 0.420, 0.060), epaisseur=1.90, n=14, seed=127, fruit=0.87)
    banc(bm, Vector((-3.30, 4.90)), 18.0, 3.50, 2.80,
         plan=(6.35, 0.420, 0.050), epaisseur=1.70, n=13, seed=139, fruit=0.85)
    objets.append(_objet("SM_ProtoB_Rampe", bm))

    # Dominante : quatre bancs courts empilés, décalés vers +x, le dernier
    # à pendage inversé pour que la crête KINKE au lieu de continuer.
    bm = bmesh.new()
    banc(bm, Vector((-1.60, 4.40)), 22.0, 3.00, 2.50,
         plan=(7.05, 0.420, 0.040), epaisseur=1.60, n=13, seed=151, fruit=0.84)
    banc(bm, Vector((-0.40, 4.20)), 30.0, 2.30, 1.90,
         plan=(7.85, 0.380, 0.030), epaisseur=1.40, n=12, seed=163, fruit=0.82)
    banc(bm, Vector((0.50, 4.60)), 40.0, 1.60, 1.25,
         plan=(8.45, 0.200, -0.180), epaisseur=1.20, n=11, seed=173, fruit=0.76)
    objets.append(_objet("SM_ProtoB_Dominante", bm))

    # Contrefort droit, reculé : deux bancs à pendage INVERSÉ, donc une
    # crête qui descend vers la droite au lieu de prolonger la rampe.
    bm = bmesh.new()
    banc(bm, Vector((5.80, 5.40)), -18.0, 3.00, 2.40,
         plan=(4.90, -0.180, 0.070), epaisseur=2.40, n=13, seed=191, fruit=0.88)
    banc(bm, Vector((5.55, 5.05)), -32.0, 2.20, 1.75,
         plan=(6.05, -0.260, 0.060), epaisseur=1.55, n=12, seed=199, fruit=0.80)
    objets.append(_objet("SM_ProtoB_Contrefort", bm))

    # Queue enterrée, banc épais prolongé vers le nord.
    bm = bmesh.new()
    banc(bm, Vector((-0.50, 9.20)), 4.0, 5.40, 3.30,
         plan=(3.20, 0.120, -0.060), epaisseur=4.20, n=14, seed=211, fruit=0.90)
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
        (-7.60, 3.30, 1.55),
        (-6.40, 4.05, 3.15),
        (-5.20, 4.85, 4.40),
        (-4.10, 5.75, 3.75),
        (-3.20, 6.65, 2.40),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_g,
                ancre_sol=Vector((-4.70, 5.90)),
                demi_grand=4.10, demi_petit=3.40,
                n=18, niveaux=11, seed=301,
                p_flanc=0.60, bombement=0.26,
                biais_amp=0.26, biais_az_deg=225.0)
    objets.append(_objet("SM_ProtoC_Epaule", bm))

    # Dominante : proue déversée vers l'arrière (+y). Le pied est en
    # avant, la crête en arrière : le front est en dévers, jamais une
    # paroi — et c'est ce dévers qui abritera la bouche.
    crete_d = [
        (-2.75, 6.20, 4.35),
        (-1.70, 5.80, 6.70),
        (-0.60, 5.45, 8.55),
        (0.55, 5.35, 7.20),
        (1.60, 5.60, 4.80),
        (2.50, 6.05, 2.60),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_d,
                ancre_sol=Vector((-0.60, 3.30)),
                demi_grand=4.40, demi_petit=3.70,
                n=20, niveaux=12, seed=317,
                p_flanc=0.64, bombement=0.24,
                biais_amp=0.22, biais_az_deg=250.0)
    objets.append(_objet("SM_ProtoC_Dominante", bm))

    # Contrefort droit : reculé, penché vers +x, crête courte et oblique.
    crete_c = [
        (4.10, 6.35, 2.10),
        (5.05, 5.70, 4.15),
        (6.05, 5.10, 4.95),
        (7.10, 4.70, 3.05),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_c,
                ancre_sol=Vector((5.35, 5.85)),
                demi_grand=2.70, demi_petit=2.40,
                n=16, niveaux=10, seed=331,
                p_flanc=0.68, bombement=0.18,
                biais_amp=0.24, biais_az_deg=330.0)
    objets.append(_objet("SM_ProtoC_Contrefort", bm))

    # Talus liant — ici structurel. Deux corps qui se recouvrent, jamais
    # une nappe unique : une nappe unique redonnerait la plinthe.
    crete_t1 = [
        (-7.90, 3.90, 1.05),
        (-5.30, 2.25, 2.85),
        (-2.30, 1.15, 3.70),
        (0.40, 1.55, 2.45),
        (2.80, 2.75, 1.25),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_t1,
                ancre_sol=Vector((-2.70, 3.70)),
                demi_grand=6.30, demi_petit=4.20,
                n=16, niveaux=7, seed=347,
                p_flanc=0.56, bombement=0.30,
                biais_amp=0.18, biais_az_deg=250.0)
    objets.append(_objet("SM_ProtoC_TalusOuest", bm))

    crete_t2 = [
        (1.20, 2.95, 2.15),
        (3.60, 3.65, 3.15),
        (5.80, 4.65, 2.40),
        (7.50, 5.60, 1.00),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_t2,
                ancre_sol=Vector((4.50, 5.20)),
                demi_grand=4.60, demi_petit=3.50,
                n=16, niveaux=7, seed=359,
                p_flanc=0.58, bombement=0.26,
                biais_amp=0.18, biais_az_deg=280.0)
    objets.append(_objet("SM_ProtoC_TalusEst", bm))

    # Queue enterrée.
    crete_q = [
        (-3.40, 8.70, 3.40),
        (-0.70, 9.75, 4.35),
        (2.10, 10.15, 3.15),
        (4.40, 9.60, 1.70),
    ]
    bm = bmesh.new()
    masse_crete(bm, crete_q,
                ancre_sol=Vector((0.10, 8.80)),
                demi_grand=5.30, demi_petit=3.20,
                n=16, niveaux=8, seed=367,
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
