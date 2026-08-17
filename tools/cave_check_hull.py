#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""COQUE STRUCTURELLE — le contrat de `docs/CONTRAT_COQUE_STRUCTURELLE.md`,
rendu EXECUTABLE, par un chemin qui n'emprunte rien a l'oracle principal.

POURQUOI CE CHEMIN-LA, ET PAS CELUI DE L'ORACLE
===============================================
Deux instruments qui partagent leur coeur se trompent ENSEMBLE. C'est
exactement ce qui est arrive quand `points_interieurs()` alimentait a elle
seule trois « corroborations independantes » qui se confirmaient
mutuellement en placant leurs points au mauvais endroit.

Cet outil n'emploie donc AUCUNE grille, AUCUN voxel, AUCUNE parite de rayon,
AUCUN EDT, AUCUN chanfrein, AUCUN Dijkstra, AUCUNE station de `CAVITE`,
AUCUN `ay` seuil, AUCUNE distance a un axe. Ses quatre primitives sont :

  * la soudure par position ;
  * le GRAPHE DUAL des faces ;
  * l'ANGLE SOLIDE signe (nombre d'enroulement generalise) ;
  * la distance EXACTE point-triangle.

LES SIX ETAPES DU CONTRAT, ET COMMENT CHACUNE EST TENUE
=======================================================

§2.1 SCELLER LA BOUCHE PAR UNE SURFACE D'EPAISSEUR NULLE.
     La barriere est une COUPURE D'ARETES DANS LE GRAPHE DUAL. Elle n'ote
     aucune cellule, aucun triangle, aucun volume : elle coupe l'adjacence.
     L'epaisseur nulle n'est donc pas un reglage soigneux, elle est
     STRUCTURELLE — le defaut `C4`, ou une tranche epaisse ampute la cavite
     au lieu de la fermer, est impossible par construction.

     Sa position est DERIVEE : on balaie des plans, on decoupe l'intersection
     plan-surface en contours fermes, et on retient le contour separant de
     PERIMETRE MINIMAL — l'etranglement. Le profil complet est publie.

§2.2 IDENTIFIER LA COMPOSANTE D'AIR INTERIEURE.
     Apres la coupure, le graphe dual se scinde. La peau interieure est la
     composante qui porte les faces les plus proches des deux graines.

     CE QUE CELA APPORTE, ET QU'UNE INONDATION NE PEUT PAS APPORTER : ce
     test n'a AUCUNE RESOLUTION. Si la cavite communique ailleurs avec le
     dehors — par une percee de n'importe quelle largeur — la coupure de la
     seule bouche NE SEPARE PAS, et cela se voit sans grille. Une inondation
     a 6 cm est aveugle a une fissure de 5 mm ; ceci ne l'est pas.

§2.3 LES DEUX GRAINES DOIVENT ETRE DANS L'AIR.
     Par angle solide, pas par parite. Si l'une tombe dans la roche : RC=3
     BLOQUE. Une graine dans la roche rendrait « etanche » sans rien prouver.

§2.4 LA COQUE = CE QUI SEPARE CET AIR DU DEHORS.
     C'est la peau interieure. Definition topologique : aucun point n'est
     ecarte au motif qu'il depasse la derniere station de `CAVITE`. C'est la
     clause qui distingue ce contrat du precedent, et c'est elle que cet
     outil rend vraie.

§2.5 EXCLUSION UNIQUE : la bouche masquee.
     Au rebord meme de la bouche, l'epaisseur tend vers zero — c'est une
     arete, pas un defaut. Le masque ecarte donc un voisinage GEODESIQUE du
     contour, mesure SUR la surface. Comme toute emprise de masque est un
     choix, on ne choisit pas : on publie le MINIMUM EN FONCTION DE
     L'EMPRISE, et le lecteur voit ce que chaque metre exclut.

§2.6 EPAISSEUR = DISTANCE EUCLIDIENNE A LA SURFACE EXTERIEURE.
     Distance exacte point-triangle, acceleree par hachage spatial. Aucune
     discretisation de la distance elle-meme.

     LA BORNE. On echantillonne la peau interieure en subdivisant chaque
     triangle jusqu'a ce que son circonradius soit <= `h`. Tout point de la
     coque est alors a <= `h` d'un echantillon. La distance a un ferme etant
     1-LIPSCHITZIENNE, on a exactement :

         min_vrai  >=  min_echantillonne - h

     `borne = lecture - h`, et le gate se prononce sur la BORNE.

LE TROISIEME CAS, celui qu'un portail honnete doit distinguer
=============================================================
     lecture - h >= 0,80                    -> PASS, garanti
     lecture     <  0,80                    -> FAIL, mesure
     lecture >= 0,80 ET lecture - h < 0,80  -> BLOQUE (RC=3)

Le troisieme n'est pas un defaut de la geometrie : c'est un defaut de
l'instrument, et l'accuser elle serait malhonnete. On rend BLOQUE, on liste
les points concernes, et on publie le `h` qu'il faudrait pour trancher.

UNE BORNE SANS SON `h` N'EST PAS UNE BORNE. `h` est imprime partout.

USAGE
=====
    python3 tools/cave_check_hull.py <fichier.glb> [options]
      --h=0.05            rayon de couverture de l'echantillonnage
      --anciens-reperes   graines d'avant la re-derivation R2a-3.5.2
      --pas-balayage=0.05 pas du balayage de plans pour deriver la bouche
      --masque=0.60       emprise geodesique du masque de bouche (m)

Codes retour : 0 PASS · 1 FAIL · 3 BLOQUE.
"""

import hashlib
import math
import os
import sys
from collections import defaultdict, deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cave_check_mesh as M  # noqa: E402

EPAISSEUR_MIN_M = 0.80          # inchange, non negociable

# Reperes de gameplay, repere MODELE (ax = gx ; ay = -gz ; az = gy).
# Godot : MODELE_SALLE (2.62, 0.09, -2.58) · MODELE_NICHE (2.78, 0.50, -4.09)
SALLE = (2.62, 2.58, 0.09)
NICHE = (2.78, 4.09, 0.50)
# Avant la re-derivation R2a-3.5.2, pour la geometrie R2a-3.4.
SALLE_ANCIEN = (1.05, 6.25, 0.22)
NICHE_ANCIEN = (-1.20, 8.20, 0.43)


def empreinte(chemin):
    h = hashlib.sha256()
    with open(chemin, "rb") as f:
        for bloc in iter(lambda: f.read(1 << 20), b""):
            h.update(bloc)
    return h.hexdigest()


# ==========================================================================
# §2.3 — dedans / dehors par ANGLE SOLIDE, jamais par parite
# ==========================================================================

def enroulement(positions, faces, p):
    """Nombre d'enroulement generalise de la surface vu du point `p`.

    Somme des angles solides signes (van Oosterom & Strackee), divisee par
    4*pi. Vaut ~1 (au signe d'orientation pres) si `p` est DANS le solide,
    ~0 s'il est dehors.

    Pourquoi pas la parite d'un rayon : la parite exige un maillage clos et
    ne survit pas a une singularite ; l'angle solide degrade continument et
    ne partage aucune ligne de code avec les trois oracles existants. C'est
    la condition pour que cette verification vaille quelque chose.
    """
    px, py, pz = p
    total = 0.0
    for (ia, ib, ic) in faces:
        ax, ay, az = positions[ia]
        bx, by, bz = positions[ib]
        cx, cy, cz = positions[ic]
        ax -= px; ay -= py; az -= pz
        bx -= px; by -= py; bz -= pz
        cx -= px; cy -= py; cz -= pz
        la = math.sqrt(ax * ax + ay * ay + az * az)
        lb = math.sqrt(bx * bx + by * by + bz * bz)
        lc = math.sqrt(cx * cx + cy * cy + cz * cz)
        if la == 0.0 or lb == 0.0 or lc == 0.0:
            continue
        num = (ax * (by * cz - bz * cy)
               - ay * (bx * cz - bz * cx)
               + az * (bx * cy - by * cx))
        den = (la * lb * lc
               + (ax * bx + ay * by + az * bz) * lc
               + (ax * cx + ay * cy + az * cz) * lb
               + (bx * cx + by * cy + bz * cz) * la)
        total += 2.0 * math.atan2(num, den)
    return total / (4.0 * math.pi)


def volume_signe(positions, faces):
    """Volume signe : son signe dit le sens des normales."""
    v = 0.0
    for (ia, ib, ic) in faces:
        a, b, c = positions[ia], positions[ib], positions[ic]
        v += (a[0] * (b[1] * c[2] - b[2] * c[1])
              - a[1] * (b[0] * c[2] - b[2] * c[0])
              + a[2] * (b[0] * c[1] - b[1] * c[0]))
    return v / 6.0


# ==========================================================================
# §2.1 — derivation de la bouche : balayage de plans, contours fermes
# ==========================================================================

def contours_du_plan(positions, faces, tab, axe, s):
    """Decoupe l'intersection du plan (`axe` = s) avec la surface.

    Rend une liste de contours ; chaque contour est (aretes_coupees,
    perimetre, faces_traversees). Deux aretes coupees appartiennent au meme
    contour si une meme face les porte toutes deux — c'est la relation de
    succession le long de la courbe d'intersection.
    """
    coupees = set()
    par_face = {}
    for fi, (a, b, c) in enumerate(faces):
        va, vb, vc = positions[a][axe], positions[b][axe], positions[c][axe]
        cote = ((va > s), (vb > s), (vc > s))
        if cote[0] == cote[1] == cote[2]:
            continue
        loc = []
        for (u, v) in ((a, b), (b, c), (c, a)):
            if (positions[u][axe] > s) != (positions[v][axe] > s):
                loc.append((u, v) if u < v else (v, u))
        if len(loc) != 2:
            continue          # face tangente au plan : ignoree
        par_face[fi] = loc
        coupees.update(loc)

    # Union-find sur les aretes coupees, via les faces qui les enchainent.
    parent = {a: a for a in coupees}

    def trouver(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for fi, (e1, e2) in par_face.items():
        r1, r2 = trouver(e1), trouver(e2)
        if r1 != r2:
            parent[r1] = r2

    groupes = defaultdict(lambda: {"aretes": set(), "faces": []})
    for a in coupees:
        groupes[trouver(a)]["aretes"].add(a)
    for fi, (e1, _e2) in par_face.items():
        groupes[trouver(e1)]["faces"].append(fi)

    def point_sur(e):
        u, v = e
        pu, pv = positions[u], positions[v]
        t = (s - pu[axe]) / (pv[axe] - pu[axe])
        return tuple(pu[k] + t * (pv[k] - pu[k]) for k in range(3))

    sortie = []
    for g in groupes.values():
        perim = 0.0
        for fi in g["faces"]:
            e1, e2 = par_face[fi]
            p1, p2 = point_sur(e1), point_sur(e2)
            perim += math.dist(p1, p2)
        pts = [point_sur(e) for e in g["aretes"]]
        sortie.append({
            "aretes": g["aretes"], "perimetre": perim,
            "faces": g["faces"], "n_aretes": len(g["aretes"]),
            "centre": tuple(sum(p[k] for p in pts) / len(pts) for k in range(3)),
            "boite": (tuple(min(p[k] for p in pts) for k in range(3)),
                      tuple(max(p[k] for p in pts) for k in range(3))),
        })
    return sortie


def faces_du_dehors(positions, faces):
    """Les faces EXTREMES du maillage dans 26 directions.

    Temoins de l'ENVELOPPE EXTERIEURE : la face dont le centroide va le plus
    loin dans une direction donnee est necessairement sur le dehors. Une
    barriere dont le cote graine en contiendrait une n'enfermerait pas une
    cavite — elle aurait avale un morceau de flanc.

    POURQUOI 26 ET PAS 1. Avec le seul temoin du zenith, la barriere retenue
    sur R2a-3.4 a ete un PLAN QUI COUPE LE MASSIF EN DEUX a `ay = 2,228` :
    628,39 m2 d'un cote, 638,74 m2 de l'autre, contour de 13 m sur 12 m. Le
    zenith tombait du bon cote, donc « valide ». Vingt-six directions ne
    laissent pas ce trou-la.

    POURQUOI L'EXTREMUM ET PAS « LA FACE LA PLUS PROCHE D'UN POINT LOINTAIN ».
    La seconde formulation est la premiere ecrite, et elle etait
    INUTILISABLE : la recherche par anneaux croissants partait a 68 m du
    modele et devait traverser 136 anneaux vides avant de rencontrer quoi
    que ce soit. Le programme n'a pas echoue, il a simplement mis quatre
    minutes sans rien imprimer — la pire facon de se tromper. L'extremum
    repond a la meme question en O(F).
    """
    temoins = set()
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                if dx == dy == dz == 0:
                    continue
                best, bf = None, -1
                for fi, (a, b, c) in enumerate(faces):
                    g = M.centroide(positions[a], positions[b], positions[c])
                    v = g[0] * dx + g[1] * dy + g[2] * dz
                    if best is None or v > best:
                        best, bf = v, fi
                if bf >= 0:
                    temoins.add(bf)
    return temoins


def separe_graine_ciel(adj, aretes_coupees, tab, f_graine, temoins):
    """La coupure isole-t-elle la face de la GRAINE de TOUS les temoins ?

    C'est LA barriere du §2.1 : on retire des ARCS D'ADJACENCE, jamais des
    faces. Epaisseur nulle par construction — le defaut `C4`, ou une tranche
    epaisse ampute la cavite, est impossible ici.

    Rend (separe, cote_graine). Sortie anticipee des que le ciel est
    atteint : c'est le cas frequent et il devient gratuit.

    LE CRITERE, ET POURQUOI CELUI-LA. Un premier jet retenait « le contour
    separant de plus petit perimetre » : il a elu un BOUTON DE 6 FACES,
    0,03 m2, un accident de surface qu'un plan detache. Le perimetre seul ne
    dit pas ce qu'on separe. Exiger que la graine et le ciel finissent de
    part et d'autre est ce qui fait de la coupure une bouche plutot qu'une
    verrue.
    """
    interdits = set()
    for a in aretes_coupees:
        inc = tab[a]
        if len(inc) == 2:
            interdits.add((inc[0], inc[1]))
            interdits.add((inc[1], inc[0]))
    if f_graine in temoins:
        return False, None
    vus = {f_graine}
    pile = [f_graine]
    while pile:
        f = pile.pop()
        for g in adj[f]:
            if g in vus or (f, g) in interdits:
                continue
            if g in temoins:
                return False, None
            vus.add(g)
            pile.append(g)
    return True, vus


# ==========================================================================
# §2.6 — distance exacte point-triangle + hachage spatial
# ==========================================================================

def distance_point_triangle2(p, a, b, c):
    """Carre de la distance exacte du point `p` au triangle `abc`."""
    ab = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    ac = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    ap = (p[0] - a[0], p[1] - a[1], p[2] - a[2])
    d1 = ab[0] * ap[0] + ab[1] * ap[1] + ab[2] * ap[2]
    d2 = ac[0] * ap[0] + ac[1] * ap[1] + ac[2] * ap[2]
    if d1 <= 0.0 and d2 <= 0.0:
        return ap[0] ** 2 + ap[1] ** 2 + ap[2] ** 2
    bp = (p[0] - b[0], p[1] - b[1], p[2] - b[2])
    d3 = ab[0] * bp[0] + ab[1] * bp[1] + ab[2] * bp[2]
    d4 = ac[0] * bp[0] + ac[1] * bp[1] + ac[2] * bp[2]
    if d3 >= 0.0 and d4 <= d3:
        return bp[0] ** 2 + bp[1] ** 2 + bp[2] ** 2
    vc = d1 * d4 - d3 * d2
    if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
        den = d1 - d3
        v = d1 / den if den != 0.0 else 0.0
        q = (a[0] + v * ab[0], a[1] + v * ab[1], a[2] + v * ab[2])
        return (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2
    cp = (p[0] - c[0], p[1] - c[1], p[2] - c[2])
    d5 = ab[0] * cp[0] + ab[1] * cp[1] + ab[2] * cp[2]
    d6 = ac[0] * cp[0] + ac[1] * cp[1] + ac[2] * cp[2]
    if d6 >= 0.0 and d5 <= d6:
        return cp[0] ** 2 + cp[1] ** 2 + cp[2] ** 2
    vb = d5 * d2 - d1 * d6
    if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
        den = d2 - d6
        w = d2 / den if den != 0.0 else 0.0
        q = (a[0] + w * ac[0], a[1] + w * ac[1], a[2] + w * ac[2])
        return (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2
    va = d3 * d6 - d5 * d4
    if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
        den = (d4 - d3) + (d5 - d6)
        w = (d4 - d3) / den if den != 0.0 else 0.0
        q = (b[0] + w * (c[0] - b[0]), b[1] + w * (c[1] - b[1]),
             b[2] + w * (c[2] - b[2]))
        return (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2
    den = va + vb + vc
    v = vb / den
    w = vc / den
    q = (a[0] + ab[0] * v + ac[0] * w,
         a[1] + ab[1] * v + ac[1] * w,
         a[2] + ab[2] * v + ac[2] * w)
    return (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2


class Hachage:
    """Grille de hachage sur les triangles d'un ensemble de faces.

    Requete par anneaux croissants, avec arret garanti : quand la meilleure
    distance trouvee est inferieure a la distance minimale aux cellules non
    encore explorees, aucune cellule plus lointaine ne peut faire mieux.
    """

    def __init__(self, positions, faces, indices, cellule):
        self.pos = positions
        self.faces = faces
        self.c = cellule
        self.cases = defaultdict(list)
        for fi in indices:
            a, b, cc = faces[fi]
            pa, pb, pc = positions[a], positions[b], positions[cc]
            lo = [min(pa[k], pb[k], pc[k]) for k in range(3)]
            hi = [max(pa[k], pb[k], pc[k]) for k in range(3)]
            for i in range(int(math.floor(lo[0] / cellule)),
                           int(math.floor(hi[0] / cellule)) + 1):
                for j in range(int(math.floor(lo[1] / cellule)),
                               int(math.floor(hi[1] / cellule)) + 1):
                    for k in range(int(math.floor(lo[2] / cellule)),
                                   int(math.floor(hi[2] / cellule)) + 1):
                        self.cases[(i, j, k)].append(fi)

    def plus_proche(self, p, plafond=None):
        """Rend (distance, face). `plafond` coupe la recherche au-dela."""
        c = self.c
        ci = (int(math.floor(p[0] / c)), int(math.floor(p[1] / c)),
              int(math.floor(p[2] / c)))
        meilleure2 = float("inf")
        meilleure_f = -1
        vus = set()
        r = 0
        while True:
            garantie = (r - 1) * c if r > 0 else 0.0
            if meilleure2 < garantie * garantie:
                break
            if plafond is not None and garantie > plafond:
                break
            trouve_case = False
            for di in range(-r, r + 1):
                for dj in range(-r, r + 1):
                    for dk in range(-r, r + 1):
                        if max(abs(di), abs(dj), abs(dk)) != r:
                            continue
                        cle = (ci[0] + di, ci[1] + dj, ci[2] + dk)
                        lst = self.cases.get(cle)
                        if not lst:
                            continue
                        trouve_case = True
                        for fi in lst:
                            if fi in vus:
                                continue
                            vus.add(fi)
                            a, b, cc = self.faces[fi]
                            d2 = distance_point_triangle2(
                                p, self.pos[a], self.pos[b], self.pos[cc])
                            if d2 < meilleure2:
                                meilleure2 = d2
                                meilleure_f = fi
            r += 1
            if r > 400 and not trouve_case and meilleure_f == -1:
                break
        return math.sqrt(meilleure2) if meilleure_f >= 0 else float("inf"), \
            meilleure_f


# ==========================================================================
# Echantillonnage de la peau : subdivision jusqu'au circonradius <= h
# ==========================================================================

def rayon_de_couverture(a, b, c):
    """Rayon de couverture EXACT du triangle par son centroide.

    Le centroide `G` est TOUJOURS dans le triangle — contrairement au
    circoncentre, qui en sort des que le triangle est obtus.

    PREUVE. Tout point `p` du triangle est une combinaison convexe des trois
    sommets. La fonction `p -> |p - G|` est convexe. Le maximum d'une
    fonction convexe sur une enveloppe convexe est atteint en un point
    extreme, donc en un SOMMET. D'ou, exactement :

        max_{p dans T} |p - G|  =  max_i |V_i - G|

    Ce n'est pas une majoration prudente : c'est une egalite, calculable en
    trois distances.

    POURQUOI PAS LE CIRCONRADIUS — et c'est une erreur que j'ai ecrite
    ================================================================
    Mon premier jet subdivisait jusqu'a « circonradius <= h » en affirmant
    que tout point etait alors a <= h d'un echantillon. C'EST FAUX, et le
    contre-exemple n'est meme pas exotique : le triangle rectangle isocele
    de cotes 1.

        sommets (0,0) (1,0) (0,1)   ->   R = hypotenuse/2 = 0,70711
        centroide (1/3, 1/3)        ->   max_i |V_i - G|  = 0,74536

    Pour `h = 0,72` la construction naive ACCEPTE le triangle sans le
    subdiviser, alors que le sommet (1,0) est a 0,745 du seul echantillon :
    la couverture est violee de 3,4 %, et la borne `lecture - h` qui en
    decoule est fausse dans le sens dangereux — elle promet plus qu'elle ne
    tient. Un maillage decime produit precisement ce genre de triangles.

    Contre-epreuve executable : `tools/cave_check_coverage.py`.
    """
    g = ((a[0] + b[0] + c[0]) / 3.0,
         (a[1] + b[1] + c[1]) / 3.0,
         (a[2] + b[2] + c[2]) / 3.0)
    return max(math.dist(g, a), math.dist(g, b), math.dist(g, c)), g


def echantillonner(positions, faces, indices, h):
    """Points de la surface tels que TOUT point de la coque soit a <= `h`.

    Construction, en trois phrases exactes :

      1. on part de chaque triangle de la coque ;
      2. tant que son rayon de couverture `max_i |V_i - G|` depasse `h`, on
         le coupe en quatre par les MILIEUX D'ARETES ;
      3. l'echantillon d'un triangle terminal est son CENTROIDE.

    Tout echantillon appartient donc reellement a la face — le centroide
    d'un sous-triangle d'une face est dans cette face — et jamais au
    circoncentre, qui sort du triangle des qu'il est obtus.

    COUVERTURE. Les sous-triangles terminaux recouvrent la face ; chaque
    point appartient a l'un d'eux ; il est donc a au plus `max_i |V_i - G|`
    <= `h` de son centroide. La couverture est PROUVEE, pas esperee, et
    c'est ce qui autorise `borne = lecture - h`.

    TERMINAISON, ET ELLE NE DEPEND PAS DE LA FORME. La subdivision par
    milieux produit quatre sous-triangles SEMBLABLES au parent, de rapport
    1/2 : toutes les aretes sont divisees par deux a chaque niveau. Comme

        |G - V_1| = |(V_2 - V_1) + (V_3 - V_1)| / 3 <= (2/3) x arete_max

    le rayon de couverture est divise par deux a chaque niveau, quel que
    soit l'aplatissement du triangle. Un triangle obtus converge donc
    exactement aussi vite qu'un triangle equilateral — il ne devient pas
    moins obtus, et cela n'a aucune importance ici.
    """
    pts = []
    for fi in indices:
        a, b, c = faces[fi]
        pile = [(positions[a], positions[b], positions[c])]
        while pile:
            p, q, r = pile.pop()
            rc, g = rayon_de_couverture(p, q, r)
            if rc <= h:
                pts.append((g, fi))
                continue
            pq = tuple((p[k] + q[k]) / 2 for k in range(3))
            qr = tuple((q[k] + r[k]) / 2 for k in range(3))
            rp = tuple((r[k] + p[k]) / 2 for k in range(3))
            pile.append((p, pq, rp))
            pile.append((pq, q, qr))
            pile.append((rp, qr, r))
            pile.append((pq, qr, rp))
    return pts


# ==========================================================================
# Pilote
# ==========================================================================

def opt(argv, nom, defaut):
    for a in argv:
        if a.startswith("--%s=" % nom):
            return float(a.split("=", 1)[1])
    return defaut


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    if not args:
        print(__doc__)
        return 3
    chemin = args[0]
    h = opt(argv, "h", 0.05)
    pas_bal = opt(argv, "pas-balayage", 0.05)
    masque_m = opt(argv, "masque", 0.60)
    anciens = "--anciens-reperes" in argv
    salle, niche = (SALLE_ANCIEN, NICHE_ANCIEN) if anciens else (SALLE, NICHE)

    print("=" * 76)
    print("COQUE STRUCTURELLE — contrat docs/CONTRAT_COQUE_STRUCTURELLE.md")
    print("=" * 76)
    print("fichier : %s" % chemin)
    print("sha256  : %s        <- lu AVANT la mesure" % empreinte(chemin))
    print("noeud   : SM_WaterfallCave")
    print("h (rayon de couverture) = %.4f m   |   seuil = %.2f m"
          % (h, EPAISSEUR_MIN_M))
    print("reperes : %s" % ("ANCIENS (pre R2a-3.5.2)" if anciens else "COURANTS"))
    print()

    sommets, triangles = M.charger(chemin, "SM_WaterfallCave", repere="modele")
    positions, faces, stats = M.souder(sommets, triangles)
    tab = M.aretes(faces)
    adj = M.graphe_dual(faces, tab)

    # ---- fermeture, prealable non negociable (§2.2) ----
    bl = sum(1 for inc in tab.values() if len(inc) == 1)
    nm = sum(1 for inc in tab.values() if len(inc) > 2)
    print("--- fermeture prealable ---")
    print("bords libres %d | non-manifold %d | %d faces | %d sommets soudes"
          % (bl, nm, len(faces), len(positions)))
    if bl:
        print("BLOQUE : maillage OUVERT. Aucune notion de dedans n'y est definie.")
        return 3
    vs = volume_signe(positions, faces)
    print("volume signe = %+.3f m3  -> normales %s"
          % (vs, "sortantes" if vs > 0 else "rentrantes"))
    print()

    # ---- §2.3 les graines sont-elles dans l'air ? ----
    print("--- §2.3 les deux graines sont-elles dans l'AIR ? (angle solide) ---")
    bloque = False
    for nom, p in (("MODELE_SALLE", salle), ("MODELE_NICHE", niche)):
        w = enroulement(positions, faces, p)
        dedans = abs(w) > 0.5
        print("  %-13s modele (%.3f ; %.3f ; %.3f)  enroulement %+.4f  -> %s"
              % (nom, p[0], p[1], p[2], w, "ROCHE" if dedans else "AIR"))
        if dedans:
            bloque = True
    if bloque:
        print()
        print("BLOQUE (RC=3) : une graine tombe dans la ROCHE. Une graine dans")
        print("la roche rendrait « etanche » sans rien prouver — §2.3 impose")
        print("le refus, jamais le vert. Si la geometrie est anterieure a la")
        print("re-derivation R2a-3.5.2, la semer avec SES reperes :")
        print("    --anciens-reperes")
        return 3
    print()

    # ---- reference « ciel » : la face que voit un point tres au-dessus ----
    (x0, y0, z0), (x1, y1, z1) = M.boite(positions)
    hach_tout = Hachage(positions, faces, range(len(faces)), 0.5)
    temoins = faces_du_dehors(positions, faces)
    _ds, f_salle = hach_tout.plus_proche(salle)
    _dn, f_niche = hach_tout.plus_proche(niche)
    print("--- references de faces ---")
    print("  temoins de l'ENVELOPPE EXTERIEURE : %d faces distinctes,"
          % len(temoins))
    print("     vues de 26 directions a grande distance")
    print("  face de SALLE  : %d   face de NICHE : %d" % (f_salle, f_niche))
    print()

    # ---- §2.1 derivation de la bouche par balayage ----
    print("--- §2.1 derivation de la bouche : balayage du profil ---")
    axe = 1                      # ay : l'axe de la galerie ; bouche en ay bas
    debut, fin = y0 + 0.02, min(y0 + 9.0, y1 - 0.02)
    print("  axe de balayage : ay   de %.3f a %.3f, pas %.3f m"
          % (debut, fin, pas_bal))
    print("  TROIS conditions de validite, et chacune a ete apprise a ses")
    print("  depens sur cette geometrie :")
    print("    1. le contour isole SALLE de 26 TEMOINS de l'enveloppe ;")
    print("       — le perimetre seul elisait une VERRUE de 6 faces, et un")
    print("         temoin unique au zenith laissait passer une BISSECTION")
    print("         du massif entier (628 m2 contre 639 m2) ;")
    print("    2. la face de NICHE reste du cote graine ;")
    print("       — sinon la barriere ampute l'arriere de la cavite ;")
    print("    3. aire(cote graine) < aire(cote ciel).")
    print("       — sinon on retient le complement : un bouton isolant le")
    print("         CIEL satisfait 1 et 2 en laissant 20 078 faces dedans.")
    print("  Parmi les valides on prend la PLUS EXTERIEURE — celle qui")
    print("  enferme le PLUS de cavite. Prendre l'etranglement le plus")
    print("  etroit amputerait le fond, ce que §2.4 interdit.")
    print()
    print("  %-9s %-8s %-10s %-8s %-11s %s"
          % ("ay", "contours", "perim.min", "valide", "aire int.", "perimetre"))

    aire_totale = sum(M.aire_triangle(positions[a], positions[b], positions[c])
                      for (a, b, c) in
                      [(faces[i][0], faces[i][1], faces[i][2])
                       for i in range(len(faces))])
    aire_face = [M.aire_triangle(positions[faces[i][0]], positions[faces[i][1]],
                                 positions[faces[i][2]])
                 for i in range(len(faces))]

    candidats = []
    s = debut
    while s <= fin:
        cs = contours_du_plan(positions, faces, tab, axe, s)
        valides = []
        for ct in cs:
            ok, cote = separe_graine_ciel(adj, ct["aretes"], tab,
                                          f_salle, temoins)
            if not ok:
                continue
            if f_niche not in cote:
                continue
            a_int = sum(aire_face[i] for i in cote)
            if a_int >= aire_totale - a_int:
                continue
            valides.append((ct, cote, a_int))
        if cs:
            pmin = min(c["perimetre"] for c in cs)
            note = ""
            if valides:
                best = max(valides, key=lambda t: t[2])
                note = "%-11.2f %.3f m" % (best[2], best[0]["perimetre"])
                candidats.append((best[2], s, best))
            print("  %-9.3f %-8d %-10.3f %-8s %s"
                  % (s, len(cs), pmin, "OUI" if valides else "non", note))
        s += pas_bal
    print()

    if not candidats:
        print("=" * 76)
        print("GATE TOPOLOGIQUE : **ROUGE**")
        print("=" * 76)
        print("AUCUNE barriere de bouche valide n'isole l'interieur.")
        print()
        print("Lecture : sceller la bouche ne suffit pas a isoler l'interieur.")
        print("La cavite communique donc avec le dehors AILLEURS que par la")
        print("bouche. Ce test n'a AUCUNE RESOLUTION — il verrait une fissure")
        print("de n'importe quelle largeur, la ou une inondation a 6 cm est")
        print("aveugle en dessous de son pas.")
        print()
        print("L'epaisseur n'est pas mesuree : mesurer l'epaisseur d'une coque")
        print("trouee n'a pas de sens, il n'y a pas de separation a mesurer.")
        print("(§5 : le gate topologique passe EN PREMIER.)")
        print()
        print("CE TEST NE LOCALISE PAS. Il dit qu'une communication existe,")
        print("pas ou elle est — c'est l'appariement du §6 :")
        print("    python3 tools/cave_check_sky_map.py <glb> --pas=0.005 \\")
        print("            --autour-du-defaut")
        return 1

    a_int, s_bouche, (ct, cote, _a) = max(candidats, key=lambda t: t[0])
    print("bouche retenue : ay = %.3f, perimetre %.3f m," % (s_bouche,
                                                            ct["perimetre"]))
    print("                 la plus EXTERIEURE des barrieres valides —")
    print("                 elle enferme %.2f m2 de peau interieure." % a_int)
    print("                 %d aretes coupees" % len(ct["aretes"]))
    (b0, b1) = ct["boite"]
    print("  emprise du contour : x[%.3f %.3f] ay[%.3f %.3f] az[%.3f %.3f]"
          % (b0[0], b1[0], b0[1], b1[1], b0[2], b1[2]))
    print()

    # ---- §2.2 / §2.4 la peau interieure ----
    interieur = sorted(cote)
    dedans = set(interieur)
    exterieur = [i for i in range(len(faces)) if i not in dedans]
    aire_int = sum(M.aire_triangle(positions[faces[i][0]], positions[faces[i][1]],
                                   positions[faces[i][2]]) for i in interieur)
    aire_ext = sum(M.aire_triangle(positions[faces[i][0]], positions[faces[i][1]],
                                   positions[faces[i][2]]) for i in exterieur)
    print("--- §2.2/§2.4 peau interieure ---")
    print("  peau INTERIEURE : %d faces, aire %.2f m2"
          % (len(interieur), aire_int))
    print("  peau EXTERIEURE : %d faces, aire %.2f m2"
          % (len(exterieur), aire_ext))
    print("  niche bordee par la peau interieure : %s"
          % ("OUI" if f_niche in dedans else "NON — a signaler"))
    print()

    # ---- §2.5 masque de bouche : distance geodesique SUR la surface ----
    bord = set()
    for a in ct["aretes"]:
        for f in tab[a]:
            if f in dedans:
                bord.add(f)
    dist_g = {f: 0.0 for f in bord}
    file = deque(bord)
    centres = {i: M.centroide(positions[faces[i][0]], positions[faces[i][1]],
                              positions[faces[i][2]]) for i in interieur}
    while file:
        f = file.popleft()
        for g in adj[f]:
            if g not in dedans:
                continue
            d = dist_g[f] + math.dist(centres[f], centres[g])
            if d < dist_g.get(g, float("inf")):
                dist_g[g] = d
                file.append(g)

    print("--- §2.5 masque de bouche (seule exclusion) ---")
    print("  Au REBORD MEME de la bouche l'epaisseur tend vers zero : c'est")
    print("  une arete, pas un defaut. Le masque ecarte donc un voisinage")
    print("  GEODESIQUE du contour, mesure SUR la surface.")
    print("  Toute emprise de masque est un CHOIX. On ne choisit donc pas :")
    print("  on publie le minimum EN FONCTION de l'emprise, et le lecteur")
    print("  voit exactement ce que chaque metre exclut. Un minimum qui")
    print("  remonte brutalement avec l'emprise est un REBORD ; un minimum")
    print("  qui reste bas est un vrai amincissement de coque.")
    print()

    # Echantillonnage fait UNE fois sur toute la peau interieure ; chaque
    # echantillon porte la distance geodesique de SA face au contour, ce qui
    # permet de rejouer tous les masques sans re-echantillonner.
    ech_tous = echantillonner(positions, faces, interieur, h)
    print("  %d echantillons sur la peau interieure "
          "(couverture PROUVEE <= h = %.4f m)" % (len(ech_tous), h))
    hach_ext = Hachage(positions, faces, exterieur, 0.5)
    mesures = []
    for (p, fi) in ech_tous:
        d, _f = hach_ext.plus_proche(p)
        mesures.append((d, p, fi, dist_g.get(fi, float("inf"))))
    print()
    print("  %-9s %-8s %-11s %-11s %s"
          % ("masque", "echant.", "lecture", "borne", "argmin (x ; ay ; az)"))
    retenu = None
    for m in (0.0, 0.25, 0.50, 0.75, 1.00, 1.50, 2.00, 3.00):
        sous = [t for t in mesures if t[3] > m]
        if not sous:
            print("  %-9.2f %-8d  (plus rien apres masquage)" % (m, 0))
            continue
        best = min(sous, key=lambda t: t[0])
        print("  %-9.2f %-8d %-11.4f %-11.4f (%.3f ; %.3f ; %.3f)"
              % (m, len(sous), best[0], best[0] - h,
                 best[1][0], best[1][1], best[1][2]))
        if abs(m - masque_m) < 1e-9:
            retenu = (best, sous, m)
    if retenu is None:
        sous = [t for t in mesures if t[3] > masque_m]
        retenu = (min(sous, key=lambda t: t[0]), sous, masque_m) if sous \
            else None
    if retenu is None:
        print("  BLOQUE : le masque demande ne laisse aucun echantillon.")
        return 3
    best, sous, m_ret = retenu
    coque = sorted({t[2] for t in sous})
    aire_coque = sum(M.aire_triangle(positions[faces[i][0]],
                                     positions[faces[i][1]],
                                     positions[faces[i][2]]) for i in coque)
    print()
    print("  emprise retenue : %.2f m" % m_ret)
    print("  coque structurelle : %d faces, %.2f m2" % (len(coque), aire_coque))
    ays = [centres[f][1] for f in coque if f in centres]
    if ays:
        print("  domaine couvert en ay : [%.3f ; %.3f]   <- AUCUNE borne de"
              % (min(ays), max(ays)))
        print("     station : la derniere station de CAVITE est a ay = 3,17 et")
        print("     la coque est mesuree bien au-dela. C'est la clause §2.4.")
    print()

    print("--- §2.6 epaisseur : distance euclidienne exacte ---")
    lecture = best[0]
    borne = lecture - h
    print("  LECTURE brute      : %.4f m" % lecture)
    print("  BORNE GARANTIE     : %.4f m   = lecture - h  (h = %.4f)"
          % (borne, h))
    print("  ARGMIN localise    : modele (%.3f ; %.3f ; %.3f), face %d"
          % (best[1][0], best[1][1], best[1][2], best[2]))
    print("     (l'argmin, pas seulement le minimum : un minimum qui se")
    print("      deplace est une migration qu'aucun total ne montre)")
    sous_seuil = [t for t in sous if t[0] < EPAISSEUR_MIN_M]
    indecis = [t for t in sous
               if t[0] >= EPAISSEUR_MIN_M and t[0] - h < EPAISSEUR_MIN_M]
    print("  echantillons sous le seuil en LECTURE : %d" % len(sous_seuil))
    print("  echantillons INDECIDABLES (lecture>=0,80 mais borne<0,80) : %d"
          % len(indecis))
    print()

    print("=" * 76)
    if lecture < EPAISSEUR_MIN_M:
        print("GATE EPAISSEUR : **FAIL** — lecture %.4f m < %.2f m, mesuree."
              % (lecture, EPAISSEUR_MIN_M))
        print("=" * 76)
        return 1
    if borne < EPAISSEUR_MIN_M:
        h_requis = lecture - EPAISSEUR_MIN_M
        print("GATE EPAISSEUR : **BLOQUE** (RC=3)")
        print("=" * 76)
        print("lecture %.4f m >= %.2f, mais borne %.4f m < %.2f."
              % (lecture, EPAISSEUR_MIN_M, borne, EPAISSEUR_MIN_M))
        print()
        print("La coque est peut-etre conforme et `h` est trop grand pour le")
        print("dire. Rendre FAIL accuserait la geometrie d'un defaut")
        print("d'INSTRUMENT ; rendre PASS violerait le contrat, qui se")
        print("prononce sur la borne. On refuse de choisir.")
        print()
        print("  h actuel  : %.4f m" % h)
        print("  h requis  : < %.4f m pour trancher a cet argmin" % h_requis)
        print("  points concernes : %d" % len(indecis))
        print("  -> raffiner h localement sur eux seuls, pas partout.")
        return 3
    print("GATE EPAISSEUR : **PASS** — borne garantie %.4f m >= %.2f m"
          % (borne, EPAISSEUR_MIN_M))
    print("=" * 76)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
