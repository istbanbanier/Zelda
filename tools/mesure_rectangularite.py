#!/usr/bin/env python3
"""Rectangularité d'un .glb : la géométrie est-elle faite d'angles droits ?

CONTRÔLE INDÉPENDANT DE `tools/mesure_boititude.py` (ticket ISS-062).

POURQUOI IL EXISTE — le défaut exact qu'il rattrape
---------------------------------------------------
`mesure_boititude.py` juge PAR COMPOSANTE CONNEXE : une composante est un pavé
si elle a 12 triangles et 8 sommets soudés (`hexa`), ou 6 plans et 8 coins
(`pave6`). Ce prédicat est donc cassable en changeant CE QUI COMPTE COMME UNE
COMPOSANTE, sans toucher un seul pixel de l'image. Contre-exemple mesuré par
l'audit indépendant du 2026-08-20 : DIX-HUIT pavés droits parfaits, posés
tangents et soudés par un coin latéral, forment UNE composante de 216 triangles
et 145 sommets — donc ni `hexa` ni `pave6`, donc 0,00 % de liant, donc les neuf
planchers franchis — alors que l'image montre évidemment des boîtes.

Le présent instrument ne raisonne JAMAIS par composante. Il juge des PLAQUES
PLANES, qui existent avant toute soudure et que la soudure ne déplace pas :

  plaque      ensemble maximal de triangles COPLANAIRES et connexes PAR ARÊTE.
              Deux faces coplanaires qui ne se touchent que par un coin restent
              deux plaques ; c'est ce qui rend la mesure invariante à la soudure
              par coin. Deux faces coplanaires qui partagent une arête entière
              fusionnent, ce qui rend la mesure invariante à la subdivision.

  part_rectangulaire  part de l'AIRE totale portée par des plaques dont le bord
              est un QUADRILATÈRE à angles droits (4 coins après suppression des
              sommets alignés, chaque angle intérieur à ±5° de 90°).

  part_rectiligne     variante lâche : tous les angles intérieurs à ±5° de 90°
              OU de 270°. Un L de trois cubes fusionnés donne une plaque en L,
              qui n'est pas un quadrilatère mais reste entièrement à angles
              droits. Publiée à côté parce qu'elle dit autre chose.

  part_orthogonale    part de la LONGUEUR d'arête partagée entre plaques
              adjacentes distinctes dont l'angle dièdre vaut 90° à ±5° près
              (test |cos(n1,n2)| <= sin 5°, qui accepte aussi bien un angle
              saillant de 90° qu'un rentrant de 270°).

POURQUOI DEUX GRANDEURS ET PAS UNE
----------------------------------
Aucune des deux ne suffit seule, et c'est mesurable :
 - un CYLINDRE a des faces latérales qui sont des rectangles parfaits. Sa
   part_rectangulaire est haute et son image n'a rien d'une boîte. Sa
   part_orthogonale, elle, s'effondre : ses arêtes verticales joignent deux
   quads à ~(180 - 360/n) degrés, pas à 90.
 - une SPHÈRE facettée a des jonctions presque plates : part_orthogonale nulle,
   mais aussi part_rectangulaire nulle (plaques triangulaires).
D'où l'indice publié : `indice_boite = min(part_rectangulaire, part_orthogonale)`.

CE QUE L'INSTRUMENT NE MESURE PAS
---------------------------------
Il ne dit RIEN de la beauté d'un asset ni de sa conformité à la bible visuelle.
Une architecture — un mur, un pylône — est légitimement faite d'angles droits et
sortira haut. Le plafond ne se pose donc que sur les meshes qui sont CENSÉS être
des débris ou de la matière naturelle. Le calibrage du rapport le montre.

PIÈGES D'ÉCRITURE, MESURÉS
--------------------------
 - Grouper les plaques par (normale, distance à l'origine) GLOBALEMENT fusionne
   les faces supérieures de deux cubes voisins qui ne se touchent que par un
   coin : la mesure redevient sensible à la soudure, exactement le défaut qu'on
   corrige. D'où la connexité PAR ARÊTE, locale.
 - Sans suppression des sommets alignés sur le bord, une simple jonction en T
   (sommet de subdivision au milieu d'une arête) fait passer un carré de 4 à 5
   coins et le disqualifie sans qu'un pixel bouge.
 - Un nom de mesh inconnu doit BLOQUER (RC 2), jamais rendre 0 % et RC 0 : un
   portail vert sur un ensemble vide est pire qu'un portail absent.

Usage :
    python3 tools/mesure_rectangularite.py <fichier.glb> [--mesh NOM]... [--json]
                                           [--plafond 55]
    python3 tools/mesure_rectangularite.py --autotest
"""

import argparse
import json
import math
import struct
import sys

# ---------------------------------------------------------------- constantes

SOUDAGE_M = 1e-4        # 0,1 mm : même valeur que mesure_boititude.py, portée
                        # là-bas sur constat d'audit (un coin décalé de 12 µm
                        # se dédoublait et cassait le compte de sommets).
COPLAN_DOT = 0.999      # ~2,56° entre normales
COPLAN_DIST = 1e-3      # 1 mm d'écart au plan du voisin
ANGLE_TOL_DEG = 5.0     # tolérance sur 90° (et sur 270°)
COLIN_TOL_DEG = 5.0     # au-delà de 175°, un sommet de bord est « aligné »
AIRE_NULLE = 1e-10      # sous ce seuil le triangle est dégénéré : écarté

_COS_ORTHO = math.sin(math.radians(ANGLE_TOL_DEG))    # |cos| toléré autour de 90°
_SIN_COLIN = math.sin(math.radians(COLIN_TOL_DEG))

GLB_MAGIC = 0x46546C67
CHUNK_JSON = 0x4E4F534A
CHUNK_BIN = 0x004E4942
_TAILLE = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
_FORMAT = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I", 5126: "f"}
_COMPOSANTES = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


# ------------------------------------------------------------- lecture .glb
# Lecteur AUTONOME, volontairement non partagé avec mesure_boititude.py : deux
# instruments qui doivent se contredire ne doivent pas dépendre du même parseur.

def lire_glb(chemin):
    with open(chemin, "rb") as h:
        blob = h.read()
    if len(blob) < 12:
        raise ValueError("fichier trop court : %s" % chemin)
    magic, _version, _total = struct.unpack_from("<III", blob, 0)
    if magic != GLB_MAGIC:
        raise ValueError("en-tête GLB invalide sur %s" % chemin)
    gltf, binaire, pos = None, b"", 12
    while pos + 8 <= len(blob):
        longueur, genre = struct.unpack_from("<II", blob, pos)
        corps = blob[pos + 8:pos + 8 + longueur]
        if genre == CHUNK_JSON:
            gltf = json.loads(corps.decode("utf-8"))
        elif genre == CHUNK_BIN:
            binaire = corps
        pos += 8 + longueur + ((4 - longueur % 4) % 4 if longueur % 4 else 0)
    if gltf is None:
        raise ValueError("aucun chunk JSON dans %s" % chemin)
    return gltf, binaire


def lire_accessor(gltf, binaire, index):
    acc = gltf["accessors"][index]
    n_comp = _COMPOSANTES[acc["type"]]
    ctype = acc["componentType"]
    taille = _TAILLE[ctype]
    fmt = _FORMAT[ctype]
    count = acc["count"]
    if "bufferView" not in acc:
        return [tuple([0] * n_comp) for _ in range(count)]
    vue = gltf["bufferViews"][acc["bufferView"]]
    base = vue.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = vue.get("byteStride") or (taille * n_comp)
    sortie = []
    for i in range(count):
        sortie.append(struct.unpack_from("<" + fmt * n_comp, binaire,
                                         base + i * stride))
    return sortie


# ------------------------------------------------------------ petite algèbre

def _sous(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _cross(u, v):
    return (u[1] * v[2] - u[2] * v[1],
            u[2] * v[0] - u[0] * v[2],
            u[0] * v[1] - u[1] * v[0])


def _dot(u, v):
    return u[0] * v[0] + u[1] * v[1] + u[2] * v[2]


def _norme(u):
    return math.sqrt(_dot(u, u))


def _normale_aire(pa, pb, pc):
    n = _cross(_sous(pb, pa), _sous(pc, pa))
    m = _norme(n)
    if m <= 0.0:
        return None, 0.0
    return (n[0] / m, n[1] / m, n[2] / m), 0.5 * m


def _racine(parent, a):
    while parent[a] != a:
        parent[a] = parent[parent[a]]
        a = parent[a]
    return a


def _unir(parent, a, b):
    ra, rb = _racine(parent, a), _racine(parent, b)
    if ra != rb:
        parent[rb] = ra


# --------------------------------------------------------------- géométrie 2D

def _simplifier_boucle(boucle, coord):
    """Supprime les sommets ALIGNÉS d'une boucle fermée.

    Sans ceci, une jonction en T — un sommet de subdivision posé au milieu
    d'une arête de bord — fait passer un carré de 4 à 5 coins et le disqualifie
    alors que l'image est identique.
    """
    pts = [coord[s] for s in boucle]
    change = True
    while change and len(pts) > 3:
        change = False
        n = len(pts)
        for i in range(n):
            a, b, c = pts[(i - 1) % n], pts[i], pts[(i + 1) % n]
            u, v = _sous(b, a), _sous(c, b)
            lu, lv = _norme(u), _norme(v)
            if lu <= 0.0 or lv <= 0.0:
                pts.pop(i)
                change = True
                break
            sin_t = _norme(_cross(u, v)) / (lu * lv)
            if sin_t < _SIN_COLIN and _dot(u, v) > 0.0:
                pts.pop(i)
                change = True
                break
    return pts


def _angles_interieurs(pts, normale):
    """Angles intérieurs en degrés d'un polygone plan, orienté par `normale`."""
    n = len(pts)
    if n < 3:
        return None
    # orientation : aire signée projetée sur la normale
    aire2 = (0.0, 0.0, 0.0)
    for i in range(n):
        c = _cross(pts[i], pts[(i + 1) % n])
        aire2 = (aire2[0] + c[0], aire2[1] + c[1], aire2[2] + c[2])
    if _dot(aire2, normale) < 0.0:
        pts = list(reversed(pts))
    angles = []
    for i in range(n):
        p, b, s = pts[(i - 1) % n], pts[i], pts[(i + 1) % n]
        u, v = _sous(s, b), _sous(p, b)   # sortant, entrant
        lu, lv = _norme(u), _norme(v)
        if lu <= 0.0 or lv <= 0.0:
            return None
        cos = max(-1.0, min(1.0, _dot(u, v) / (lu * lv)))
        a = math.degrees(math.acos(cos))
        if _dot(_cross(u, v), normale) <= 0.0:    # rentrant
            a = 360.0 - a
        angles.append(a)
    return angles


# ------------------------------------------------------------------- analyse

def analyser_mesh(primitives):
    """Analyse un MESH ENTIER, primitives fondues.

    Fondre les primitives est obligatoire : une face portant un autre matériau
    sort dans une primitive séparée, et une plaque coupée en deux par une
    frontière de matériau n'est plus un quadrilatère.

    `primitives` : liste de (positions, indices).
    Rend un dictionnaire de mesures, ou None si le mesh n'a aucun triangle vivant.
    """
    # --- 1. soudage par POSITION (identifiants géométriques) -----------------
    grille = {}
    geo_de = []
    coord = []
    triangles = []
    for positions, indices in primitives:
        base = len(geo_de)
        for p in positions:
            cle = (round(p[0] / SOUDAGE_M), round(p[1] / SOUDAGE_M),
                   round(p[2] / SOUDAGE_M))
            if cle not in grille:
                grille[cle] = len(coord)
                coord.append((float(p[0]), float(p[1]), float(p[2])))
            geo_de.append(grille[cle])
        for t in range(0, len(indices) - 2, 3):
            triangles.append((geo_de[base + indices[t]],
                              geo_de[base + indices[t + 1]],
                              geo_de[base + indices[t + 2]]))

    # --- 2. triangles vivants ------------------------------------------------
    tris, normales, aires = [], [], []
    for a, b, c in triangles:
        if a == b or b == c or a == c:
            continue
        n, s = _normale_aire(coord[a], coord[b], coord[c])
        if n is None or s <= AIRE_NULLE:
            continue
        tris.append((a, b, c))
        normales.append(n)
        aires.append(s)
    if not tris:
        return None

    # --- 3. arêtes -> triangles incidents ------------------------------------
    aretes = {}
    for i, (a, b, c) in enumerate(tris):
        for x, y in ((a, b), (b, c), (c, a)):
            cle = (x, y) if x < y else (y, x)
            aretes.setdefault(cle, []).append(i)

    # --- 4. plaques = composantes de l'adjacence COPLANAIRE PAR ARÊTE --------
    parent = list(range(len(tris)))
    for cle, inc in aretes.items():
        if len(inc) < 2:
            continue
        for ii in range(len(inc)):
            for jj in range(ii + 1, len(inc)):
                t1, t2 = inc[ii], inc[jj]
                n1, n2 = normales[t1], normales[t2]
                if _dot(n1, n2) < COPLAN_DOT:
                    continue
                p1 = coord[tris[t1][0]]
                if all(abs(_dot(n1, _sous(coord[s], p1))) <= COPLAN_DIST
                       for s in tris[t2]):
                    _unir(parent, t1, t2)

    plaques = {}
    for i in range(len(tris)):
        plaques.setdefault(_racine(parent, i), []).append(i)

    plaque_de = {}
    for pid, membres in plaques.items():
        for t in membres:
            plaque_de[t] = pid

    # --- 5. forme du bord de chaque plaque -----------------------------------
    aire_totale = 0.0
    aire_rect = 0.0
    aire_rectiligne = 0.0
    aires_plaques = []
    normale_plaque = {}
    detail_refus = {"bord_ambigu": 0, "trous": 0, "pas_4_coins": 0, "angles": 0}

    for pid, membres in plaques.items():
        aire_p = sum(aires[t] for t in membres)
        aire_totale += aire_p
        aires_plaques.append(aire_p)
        # normale pondérée par l'aire
        nx = sum(normales[t][0] * aires[t] for t in membres)
        ny = sum(normales[t][1] * aires[t] for t in membres)
        nz = sum(normales[t][2] * aires[t] for t in membres)
        m = math.sqrt(nx * nx + ny * ny + nz * nz)
        npl = (nx / m, ny / m, nz / m) if m > 0 else normales[membres[0]]
        normale_plaque[pid] = npl

        # bord = arêtes n'apparaissant qu'UNE fois dans la plaque
        compte = {}
        for t in membres:
            a, b, c = tris[t]
            for x, y in ((a, b), (b, c), (c, a)):
                cle = (x, y) if x < y else (y, x)
                compte[cle] = compte.get(cle, 0) + 1
        bord = [cle for cle, k in compte.items() if k == 1]
        if not bord:
            detail_refus["trous"] += 1
            continue

        voisins = {}
        for x, y in bord:
            voisins.setdefault(x, []).append(y)
            voisins.setdefault(y, []).append(x)
        if any(len(v) != 2 for v in voisins.values()):
            detail_refus["bord_ambigu"] += 1
            continue

        # chaînage : une seule boucle attendue (sinon la plaque est trouée)
        depart = bord[0][0]
        boucle = [depart]
        prec, cour = None, depart
        while True:
            a, b = voisins[cour]
            suiv = a if a != prec else b
            if suiv == depart:
                break
            boucle.append(suiv)
            prec, cour = cour, suiv
            if len(boucle) > len(bord):
                break
        if len(boucle) != len(voisins):
            detail_refus["trous"] += 1
            continue

        pts = _simplifier_boucle(boucle, coord)
        angles = _angles_interieurs(pts, npl)
        if angles is None:
            detail_refus["bord_ambigu"] += 1
            continue
        droit = [abs(a - 90.0) <= ANGLE_TOL_DEG for a in angles]
        rentrant = [abs(a - 270.0) <= ANGLE_TOL_DEG for a in angles]
        if all(d or r for d, r in zip(droit, rentrant)):
            aire_rectiligne += aire_p
            if len(pts) == 4 and all(droit):
                aire_rect += aire_p
            elif len(pts) != 4:
                detail_refus["pas_4_coins"] += 1
            else:
                detail_refus["angles"] += 1
        else:
            if len(pts) != 4:
                detail_refus["pas_4_coins"] += 1
            else:
                detail_refus["angles"] += 1

    # --- 6. orthogonalité des jonctions entre plaques ------------------------
    #
    # JONCTION DÉGÉNÉRÉE, ÉCARTÉE DES DEUX CÔTÉS DE LA FRACTION. Deux plaques
    # qui partagent une arête et dont les normales sont (anti)parallèles sont
    # forcément DANS LE MÊME PLAN — l'arête partagée appartient aux deux plans.
    # C'est le cas de deux boîtes simplement accolées : la face +X de l'une et
    # la face -X de l'autre sont dos à dos, invisibles, et leur « angle » de
    # 180° ne dit rien de la forme. Mesuré sur le L de trois cubes du cas 10 :
    # 8,0 des 45,0 unités de jonction, soit 17,8 points d'orthogonalité perdus
    # sur une géométrie pourtant entièrement à angles droits.
    # L'exclusion est neutre : elle retire la longueur du numérateur ET du
    # dénominateur. Elle est publiée séparément (`longueur_degeneree`) pour que
    # personne ne puisse la cacher.
    long_totale = 0.0
    long_ortho = 0.0
    long_degen = 0.0
    for cle, inc in aretes.items():
        pids = sorted({plaque_de[t] for t in inc})
        if len(pids) < 2:
            continue
        L = math.dist(coord[cle[0]], coord[cle[1]])
        for ii in range(len(pids)):
            for jj in range(ii + 1, len(pids)):
                n1, n2 = normale_plaque[pids[ii]], normale_plaque[pids[jj]]
                d = abs(_dot(n1, n2))
                if d >= COPLAN_DOT:
                    long_degen += L
                    continue
                long_totale += L
                if d <= _COS_ORTHO:
                    long_ortho += L

    aires_plaques.sort()
    mediane = aires_plaques[len(aires_plaques) // 2] if aires_plaques else 0.0
    p_rect = (100.0 * aire_rect / aire_totale) if aire_totale else 0.0
    p_rectiligne = (100.0 * aire_rectiligne / aire_totale) if aire_totale else 0.0
    p_ortho = (100.0 * long_ortho / long_totale) if long_totale > 0 else None

    return {
        "triangles": len(tris),
        "plaques": len(plaques),
        "aire_totale": aire_totale,
        "aire_mediane_plaque": mediane,
        "part_rectangulaire": p_rect,
        "part_rectiligne": p_rectiligne,
        "part_orthogonale": p_ortho,
        "indice_boite": (min(p_rect, p_ortho) if p_ortho is not None else p_rect),
        "longueur_jonctions": long_totale,
        "longueur_degeneree": long_degen,
        "refus": detail_refus,
    }


def mesurer(chemin):
    gltf, binaire = lire_glb(chemin)
    resultats = []
    for mesh in gltf.get("meshes", []):
        nom = mesh.get("name", "?")
        primitives = []
        for prim in mesh.get("primitives", []):
            attrs = prim.get("attributes", {})
            if "POSITION" not in attrs:
                continue
            if prim.get("mode", 4) != 4:      # TRIANGLES uniquement
                continue
            positions = lire_accessor(gltf, binaire, attrs["POSITION"])
            if "indices" in prim:
                indices = [i[0] for i in lire_accessor(gltf, binaire,
                                                       prim["indices"])]
            else:
                indices = list(range(len(positions)))
            primitives.append((positions, indices))
        if not primitives:
            continue
        r = analyser_mesh(primitives)
        if r is None:
            continue
        r["mesh"] = nom
        r["primitives"] = len(primitives)
        resultats.append(r)
    return resultats


# ------------------------------------------------------------------ autotest

def _cube(ox=0.0, oy=0.0, oz=0.0, c=1.0):
    s = [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0),
         (0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]
    pts = [(ox + x * c, oy + y * c, oz + z * c) for (x, y, z) in s]
    faces = [(0, 2, 1), (0, 3, 2), (4, 5, 6), (4, 6, 7), (0, 1, 5), (0, 5, 4),
             (1, 2, 6), (1, 6, 5), (2, 3, 7), (2, 7, 6), (3, 0, 4), (3, 4, 7)]
    return pts, [i for f in faces for i in f]


def _icosphere(subdiv=2):
    t = (1.0 + math.sqrt(5.0)) / 2.0
    v = [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0),
         (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t),
         (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]
    f = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11),
         (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
         (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9),
         (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    v = [list(p) for p in v]
    for _ in range(subdiv):
        milieu, nf = {}, []
        def mid(a, b):
            k = (min(a, b), max(a, b))
            if k not in milieu:
                p = [(v[a][i] + v[b][i]) / 2.0 for i in range(3)]
                milieu[k] = len(v)
                v.append(p)
            return milieu[k]
        for a, b, c in f:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
            nf += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        f = nf
    pts = []
    for p in v:
        m = math.sqrt(sum(x * x for x in p))
        pts.append(tuple(x / m for x in p))
    return pts, [i for tri in f for i in tri]


def autotest():
    """Cas témoins analytiques. Un instrument qui ne les passe pas ne mesure rien.

    Le cas 2 est LE contre-exemple d'ISS-062 : celui sur lequel
    `mesure_boititude.py` rend 0,00 % de liant.
    """
    resultats = []

    def cas(nom, r, cible_rect, cible_ortho, sens="~"):
        """`cible_*` : (mini, maxi) en pourcentage, ou None pour ne pas juger."""
        pr = r["part_rectangulaire"] if r else -1.0
        po = r["part_orthogonale"] if r and r["part_orthogonale"] is not None else -1.0
        ok = True
        if cible_rect is not None:
            ok = ok and (cible_rect[0] <= pr <= cible_rect[1])
        if cible_ortho is not None:
            ok = ok and (cible_ortho[0] <= po <= cible_ortho[1])
        resultats.append(ok)
        print("%-38s rect=%6.2f%% ortho=%6.2f%% plaques=%4s -> %s"
              % (nom, pr, po, r["plaques"] if r else "-",
                 "OK" if ok else "ECHEC"))
        return ok

    # 1 — cube seul
    p, i = _cube()
    cas("cube seul", analyser_mesh([(p, i)]), (99.0, 100.01), (99.0, 100.01))

    # 2 — DIX-HUIT cubes soudés par un coin (contre-exemple ISS-062).
    #     Chaque cube est décalé de (1,1,1) : le coin (k,k,k) est PARTAGÉ,
    #     donc tout tient en UNE composante connexe, et pourtant chaque face
    #     reste une plaque carrée isolée.
    pts, idx = [], []
    for k in range(18):
        p, i = _cube(float(k), float(k), float(k))
        idx += [j + len(pts) for j in i]
        pts += p
    r18 = analyser_mesh([(pts, idx)])
    cas("18 cubes soudés par un coin", r18, (99.0, 100.01), (99.0, 100.01))
    # invariance à la soudure : identique au cube seul, à la virgule près
    p, i = _cube()
    r1 = analyser_mesh([(p, i)])
    inv = (abs(r18["part_rectangulaire"] - r1["part_rectangulaire"]) < 0.01
           and abs(r18["part_orthogonale"] - r1["part_orthogonale"]) < 0.01)
    resultats.append(inv)
    print("%-38s ecart<0.01 pt -> %s"
          % ("  invariance soudure (18 vs 1)", "OK" if inv else "ECHEC"))

    # 3 — dix-huit cubes DISJOINTS : la mesure doit être la même que soudés.
    pts, idx = [], []
    for k in range(18):
        p, i = _cube(float(k) * 3.0, 0.0, 0.0)
        idx += [j + len(pts) for j in i]
        pts += p
    rd = analyser_mesh([(pts, idx)])
    inv2 = (abs(rd["part_rectangulaire"] - r18["part_rectangulaire"]) < 0.01
            and abs(rd["part_orthogonale"] - r18["part_orthogonale"]) < 0.01)
    resultats.append(inv2)
    print("%-38s ecart<0.01 pt -> %s"
          % ("18 cubes disjoints == 18 soudés", "OK" if inv2 else "ECHEC"))

    # 3b — 18 cubes en RANGÉE, faces entièrement fusionnées : un mur de boîtes.
    #      Les faces supérieures, coplanaires ET adjacentes par arête, fondent
    #      en UNE plaque de 1x18. Un rectangle de 1x18 reste un rectangle.
    pts, idx = [], []
    for k in range(18):
        p, i = _cube(float(k), 0.0, 0.0)
        idx += [j + len(pts) for j in i]
        pts += p
    cas("18 cubes en rangée fusionnée", analyser_mesh([(pts, idx)]),
        (99.0, 100.01), (99.0, 100.01))

    # 3c — LE CAS LE PLUS PROCHE DU DÉFAUT RÉEL : 18 pavés de tailles
    #      DIFFÉRENTES, TOURNÉS chacun de son propre angle, et soudés en chaîne
    #      par un coin. Aucune arête commune, aucun axe commun, une seule
    #      composante connexe. `mesure_boititude.py` y rend 0,00 % de liant
    #      (vérifié le 2026-08-20) ; l'image montre dix-huit boîtes.
    def _tourner(p, a, b, c):
        x, y, z = p
        x, y = x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a)
        y, z = y * math.cos(b) - z * math.sin(b), y * math.sin(b) + z * math.cos(b)
        z, x = z * math.cos(c) - x * math.sin(c), z * math.sin(c) + x * math.cos(c)
        return (x, y, z)

    pts, idx = [], []
    ancre = (0.0, 0.0, 0.0)
    for k in range(18):
        base, i = _cube(0.0, 0.0, 0.0, 0.6 + 0.05 * k)
        tourne = [_tourner(p, 0.31 * k, 0.17 * k, 0.23 * k) for p in base]
        d = tuple(ancre[j] - tourne[0][j] for j in range(3))
        place = [tuple(p[j] + d[j] for j in range(3)) for p in tourne]
        ancre = place[6]
        idx += [j + len(pts) for j in i]
        pts += place
    cas("18 pavés TOURNÉS soudés par un coin", analyser_mesh([(pts, idx)]),
        (99.0, 100.01), (99.0, 100.01))

    # 4 — tétraèdre RÉGULIER : dièdre 70,53°, faces triangulaires.
    #     ATTENTION AU PIÈGE, ÉPROUVÉ ICI : le tétraèdre « facile »
    #     (0,0,0),(1,0,0),(0,1,0),(0,0,1) N'EST PAS un fragment irrégulier —
    #     trois de ses faces SONT les plans de coordonnées, donc mutuellement
    #     orthogonales. Il rend 41,42 % d'orthogonalité, valeur analytiquement
    #     exacte : 3 arêtes axiales de longueur 1 contre 3 arêtes de la face
    #     oblique de longueur racine de 2, soit 3/(3+3*sqrt(2)). C'est un coin
    #     de boîte, pas un caillou. Les deux cas sont gardés.
    tet = [(1.0, 1.0, 1.0), (1.0, -1.0, -1.0), (-1.0, 1.0, -1.0), (-1.0, -1.0, 1.0)]
    cas("tétraèdre régulier",
        analyser_mesh([(tet, [0, 2, 1, 0, 1, 3, 0, 3, 2, 1, 2, 3])]),
        (0.0, 1.0), (0.0, 1.0))

    coin = [(0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)]
    cas("tétraèdre-coin de boîte (attendu 41,42%)",
        analyser_mesh([(coin, [0, 2, 1, 0, 1, 3, 0, 3, 2, 1, 2, 3])]),
        (0.0, 1.0), (41.0, 41.9))

    # 5 — icosphère subdivisée deux fois
    p, i = _icosphere(2)
    cas("icosphère (320 faces)", analyser_mesh([(p, i)]), (0.0, 1.0), (0.0, 1.0))

    # 6 — cube dont une face est subdivisée au barycentre (invariance)
    p, i = _cube()
    p = list(p) + [(0.5, 0.5, 0.0)]
    faces = [(4, 5, 6), (4, 6, 7), (0, 1, 5), (0, 5, 4), (1, 2, 6), (1, 6, 5),
             (2, 3, 7), (2, 7, 6), (3, 0, 4), (3, 4, 7),
             (0, 2, 8), (2, 1, 8), (1, 0, 8)]
    # la face z=0 (0,1,2,3) redécoupée en 4 autour du barycentre 8
    faces = [(4, 5, 6), (4, 6, 7), (0, 1, 5), (0, 5, 4), (1, 2, 6), (1, 6, 5),
             (2, 3, 7), (2, 7, 6), (3, 0, 4), (3, 4, 7),
             (0, 8, 1), (1, 8, 2), (2, 8, 3), (3, 8, 0)]
    cas("cube, face subdivisée au barycentre",
        analyser_mesh([(p, [j for f in faces for j in f])]),
        (99.0, 100.01), (99.0, 100.01))

    # 7 — cube avec une jonction en T sur une arête de bord
    p, i = _cube()
    p = list(p) + [(0.5, 0.0, 0.0)]      # milieu de l'arête 0-1
    faces = [(0, 2, 1), (0, 3, 2), (4, 5, 6), (4, 6, 7),
             (0, 8, 5), (8, 1, 5), (0, 5, 4),
             (1, 2, 6), (1, 6, 5), (2, 3, 7), (2, 7, 6), (3, 0, 4), (3, 4, 7)]
    cas("cube, jonction en T sur une arête",
        analyser_mesh([(p, [j for f in faces for j in f])]),
        (99.0, 100.01), (99.0, 100.01))

    # 8 — cylindre à 24 côtés : faces latérales RECTANGULAIRES mais dièdres à 165°
    n = 24
    pts = []
    for k in range(n):
        a = 2.0 * math.pi * k / n
        pts.append((math.cos(a), math.sin(a), 0.0))
    for k in range(n):
        a = 2.0 * math.pi * k / n
        pts.append((math.cos(a), math.sin(a), 2.0))
    pts += [(0.0, 0.0, 0.0), (0.0, 0.0, 2.0)]
    idx = []
    for k in range(n):
        k2 = (k + 1) % n
        idx += [k, k2, n + k2, k, n + k2, n + k]         # côté
        idx += [2 * n, k2, k]                            # fond
        idx += [2 * n + 1, n + k, n + k2]                # dessus
    rc = analyser_mesh([(pts, idx)])
    ok8 = rc["part_rectangulaire"] > 50.0 and rc["part_orthogonale"] < 40.0
    resultats.append(ok8)
    print("%-38s rect=%6.2f%% ortho=%6.2f%% -> %s   (rect HAUT, ortho BAS : "
          "c'est pourquoi une seule grandeur ne suffit pas)"
          % ("cylindre 24 côtés", rc["part_rectangulaire"],
             rc["part_orthogonale"], "OK" if ok8 else "ECHEC"))

    # 9 — pavé réparti sur DEUX primitives (deux matériaux)
    p, i = _cube()
    fa = [(0, 2, 1), (0, 3, 2), (4, 5, 6), (4, 6, 7), (0, 1, 5), (0, 5, 4)]
    fb = [(1, 2, 6), (1, 6, 5), (2, 3, 7), (2, 7, 6), (3, 0, 4), (3, 4, 7)]
    pa = [p[j] for f in fa for j in f]
    pb = [p[j] for f in fb for j in f]
    cas("pavé sur deux primitives",
        analyser_mesh([(pa, list(range(len(pa)))), (pb, list(range(len(pb))))]),
        (99.0, 100.01), (99.0, 100.01))

    # 10 — L de trois cubes fusionnés : plaque en L, donc PAS un quadrilatère,
    #      mais entièrement à angles droits. Le couple rect/rectiligne le dit.
    pts, idx = [], []
    for (ox, oy) in ((0, 0), (1, 0), (0, 1)):
        p, i = _cube(float(ox), float(oy), 0.0)
        idx += [j + len(pts) for j in i]
        pts += p
    rl = analyser_mesh([(pts, idx)])
    ok10 = rl["part_rectiligne"] > 99.0 and rl["part_orthogonale"] > 99.0
    resultats.append(ok10)
    print("%-38s rect=%6.2f%% rectiligne=%6.2f%% ortho=%6.2f%% -> %s"
          % ("L de trois cubes fusionnés", rl["part_rectangulaire"],
             rl["part_rectiligne"], rl["part_orthogonale"],
             "OK" if ok10 else "ECHEC"))

    # 11 — SABOTAGE : un cube dont un coin est tiré de 25 cm ne doit PLUS être
    #      rectangulaire. Sans ce cas, un instrument qui rendrait 100 % partout
    #      passerait les dix précédents.
    p, i = _cube()
    p = list(p)
    p[6] = (1.25, 1.30, 1.22)
    rs = analyser_mesh([(p, i)])
    ok11 = rs["part_rectangulaire"] < 60.0
    resultats.append(ok11)
    print("%-38s rect=%6.2f%% (doit tomber sous 60) -> %s"
          % ("cube à un coin tiré de 25 cm", rs["part_rectangulaire"],
             "OK" if ok11 else "ECHEC"))

    print("\n%d cas, %d OK, %d ECHEC"
          % (len(resultats), sum(1 for x in resultats if x),
             sum(1 for x in resultats if not x)))
    return 0 if all(resultats) else 1


# ---------------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("fichier", nargs="?")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--mesh", action="append", default=None,
                    help="restreindre le verdict à ces meshes (répétable)")
    ap.add_argument("--plafond-ortho", type=float, default=None,
                    dest="plafond_ortho",
                    help="plafond INDÉPENDANT sur part_orthogonale ; sort 1 si dépassé. "
                         "Nécessaire parce que `min(RECT, ortho)` se contourne : un "
                         "bruit cohérent de 2 mm effondre RECT sans toucher ortho.")
    ap.add_argument("--plafond", type=float, default=None,
                    help="indice_boite maximum toléré ; sort 1 si dépassé")
    ap.add_argument("--autotest", action="store_true")
    a = ap.parse_args()
    if a.autotest:
        return autotest()
    if not a.fichier:
        ap.error("fichier requis (ou --autotest)")

    # UN FICHIER ILLISIBLE BLOQUE (RC 2), IL N'ÉCHOUE PAS (RC 1).
    # Sans ceci, `--plafond 51 fichier_corrompu` rendait RC 1 par traceback, et
    # RC 1 est déjà le code de « plafond dépassé » : on lisait « trop
    # rectangulaire » là où l'instrument n'avait rien mesuré du tout.
    try:
        res = mesurer(a.fichier)
    except (OSError, ValueError, KeyError, struct.error) as exc:
        sys.stderr.write("BLOQUÉ : %s illisible comme .glb : %s\n"
                         % (a.fichier, exc))
        return 2
    if not res:
        sys.stderr.write("BLOQUÉ : aucun mesh triangulé exploitable dans %s\n"
                         % a.fichier)
        return 2
    connus = {r["mesh"] for r in res}

    # UN NOM DE MESH INCONNU EST UNE ERREUR, JAMAIS UN VERDICT.
    if a.mesh:
        inconnus = [m for m in a.mesh if m not in connus]
        if inconnus:
            sys.stderr.write("BLOQUÉ : mesh(es) introuvable(s) dans %s : %s\n"
                             % (a.fichier, ", ".join(inconnus)))
            sys.stderr.write("         présents : %s\n" % ", ".join(sorted(connus)))
            return 2

    retenus = [r for r in res if (a.mesh is None or r["mesh"] in a.mesh)]
    aire = sum(r["aire_totale"] for r in retenus)
    a_rect = sum(r["aire_totale"] * r["part_rectangulaire"] / 100.0 for r in retenus)
    a_rectil = sum(r["aire_totale"] * r["part_rectiligne"] / 100.0 for r in retenus)
    lj = sum(r["longueur_jonctions"] for r in retenus)
    ldeg = sum(r["longueur_degeneree"] for r in retenus)
    l_ortho = sum(r["longueur_jonctions"] * (r["part_orthogonale"] or 0.0) / 100.0
                  for r in retenus)
    g_rect = (100.0 * a_rect / aire) if aire else 0.0
    g_rectil = (100.0 * a_rectil / aire) if aire else 0.0
    g_ortho = (100.0 * l_ortho / lj) if lj else None
    indice = min(g_rect, g_ortho) if g_ortho is not None else g_rect

    if a.json:
        print(json.dumps({
            "fichier": a.fichier,
            "meshes": [{k: (round(v, 6) if isinstance(v, float) else v)
                        for k, v in r.items()} for r in res],
            "retenus": [r["mesh"] for r in retenus],
            "part_rectangulaire": round(g_rect, 2),
            "part_rectiligne": round(g_rectil, 2),
            "part_orthogonale": (round(g_ortho, 2) if g_ortho is not None else None),
            "indice_boite": round(indice, 2),
            "plaques": sum(r["plaques"] for r in retenus),
            "longueur_jonctions": round(lj, 5),
            "longueur_degeneree": round(ldeg, 5),
            "aire_totale": round(aire, 5),
        }, ensure_ascii=False, indent=2))
    else:
        print("%-26s %5s %7s %8s %10s %9s %11s %10s" %
              ("mesh", "prim", "tris", "plaques", "RECT%", "ortho%",
               "rectiligne%", "aire_med"))
        for r in res:
            marque = "*" if (a.mesh is not None and r["mesh"] in a.mesh) else " "
            po = r["part_orthogonale"]
            print("%s%-25s %5d %7d %8d %9.2f%% %8.2f%% %10.2f%% %10.6f" % (
                marque, r["mesh"], r["primitives"], r["triangles"], r["plaques"],
                r["part_rectangulaire"], (po if po is not None else -1.0),
                r["part_rectiligne"], r["aire_mediane_plaque"]))
        etendue = "MESHES RETENUS" if a.mesh else "TOTAL"
        print("%-26s %5s %7s %8d %9.2f%% %8.2f%% %10.2f%% %10s" % (
            etendue, "", "", sum(r["plaques"] for r in retenus), g_rect,
            (g_ortho if g_ortho is not None else -1.0), g_rectil, ""))
        print("indice_boite = min(RECT, ortho) = %.2f%%" % indice)

    # DEUX PLAFONDS INDÉPENDANTS, ET C'EST LE POINT.
    #
    # Trouvé par l'audit adverse le 2026-08-20 : `indice_boite = min(RECT, ortho)`
    # se contourne avec un bruit COHÉRENT de 2 mm appliqué par POSITION (donc les
    # coins soudés le restent). Les faces cessent d'être planes à mieux que
    # RECT_COPLAN_DIST, RECT s'effondre à 38,80 %, et le `min` le retient — alors
    # qu'`ortho` reste à 100,00 % et dit la vérité : l'objet est TOUJOURS fait de
    # boîtes. Les dix contrôles rendaient vert sur une géométrie qui n'est que des
    # boîtes. La marge de l'instrument contre le bruit était d'UN millimètre.
    #
    # Un `min` protège contre le cas où une seule grandeur suffirait à absoudre ;
    # il ne protège pas contre le cas où une seule grandeur suffit à ACCUSER.
    # D'où un second plafond, posé sur `ortho` SEULE, jamais à travers le `min`.
    if a.plafond_ortho is not None:
        if g_ortho is not None and g_ortho > a.plafond_ortho:
            sys.stderr.write("ECHEC : part_orthogonale %.2f%% > plafond %.2f%% — "
                             "des angles droits partout, quelle que soit la "
                             "planéité des faces (ISS-062)\n"
                             % (g_ortho, a.plafond_ortho))
            return 1
        sys.stderr.write("OK : part_orthogonale %s <= plafond %.2f%%\n"
                         % ("%.2f%%" % g_ortho if g_ortho is not None
                            else "(indéfinie)", a.plafond_ortho))
    if a.plafond is not None:
        if indice > a.plafond:
            sys.stderr.write("ECHEC : indice_boite %.2f%% > plafond %.2f%%\n"
                             % (indice, a.plafond))
            return 1
        sys.stderr.write("OK : indice_boite %.2f%% <= plafond %.2f%%\n"
                         % (indice, a.plafond))
    return 0


if __name__ == "__main__":
    sys.exit(main())
