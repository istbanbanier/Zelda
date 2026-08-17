#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""LES DEFAUTS SIGNALES SONT-ILS REELS ? — verdict exact, sans tolerance.

POURQUOI CE FICHIER EXISTE
==========================
Le generateur publie « auto-intersection du livrable : 2 paire(s), repli
maximal 0,0006 m ». Ce chiffre vient de `controle_repli()`, qui s'appuie sur
`BVHTree.overlap` puis sur un test de straddle avec `TOLERANCE_TANGENCE_M =
1e-4`. Deux tolerances, donc, et un verdict binaire tire d'elles.

Or la directive dit « 0 auto-intersection ». Avant de corriger une
geometrie, il faut savoir si ces paires SONT des intersections. Un
instrument qui utiliserait la meme tolerance que celui qu'il verifie ne
prouverait rien : il rendrait le meme verdict pour la meme raison.

CE QUE FAIT CELUI-CI, ET EN QUOI IL EST INDEPENDANT
===================================================
  * il ne lit pas Blender : il ouvre le GLB LIVRE, celui que Godot charge ;
  * il n'utilise aucun BVH, aucune normale normalisee, aucun epsilon ;
  * tous ses predicats sont EXACTS. Les coordonnees d'un GLB sont des
    float32, donc des rationnels dyadiques : `Fraction` les represente sans
    perte, et un determinant 3x3 de Fractions est exact. Un signe rendu ici
    est le vrai signe, pas un signe a 1e-4 pres.

LA DEFINITION QU'IL APPLIQUE, ET ELLE EST LA SEULE QUI COMPTE
=============================================================
Deux triangles se PENETRENT si l'intersection de leurs INTERIEURS RELATIFS
est non vide. C'est une definition topologique, sans seuil :

  * deux faces partageant une arete se coupent exactement le long de cette
    arete, qui est dans la frontiere des deux -> AUCUNE penetration ;
  * deux faces tangentes se touchent sur leur frontiere -> AUCUNE
    penetration, quel que soit le bruit de virgule flottante ;
  * deux faces dont l'une entre dans l'autre partagent des points
    interieurs -> PENETRATION, meme de 0,0006 m.

Le calcul n'echantillonne pas le segment d'intersection : il resout les
trois inegalites barycentriques STRICTES comme un intervalle ouvert en t,
et demande que l'intersection des deux intervalles ouverts soit non vide.
Un echantillonnage a 1/4, 1/2, 3/4 pourrait manquer un intervalle court ;
un intervalle exact ne le peut pas.

L'AIRE NULLE, MEME EXIGENCE
===========================
« Aire < 1e-9 » est une petite face. « Aire nulle » est une face degeneree.
Ce ne sont pas les memes objets et le solveur booleen exact de Blender ne
les traite pas pareil : mesure en R2a-3.4, quatre faces PRESQUE nulles
survivent au CSG, une face EXACTEMENT nulle le fait echouer. Ici l'aire est
le produit vectoriel exact : nul ou pas nul, sans seuil.

CE QU'IL NE FAIT PAS
====================
Il ne modifie rien, ne reexporte rien, n'appelle ni Blender ni Godot. Il
lit un fichier et publie des nombres.
"""

import argparse
import json
import struct
import sys
from collections import defaultdict
from fractions import Fraction


# ---------------------------------------------------------------------------
# LECTURE DU GLB — sans dependance, parce que la dependance serait un tiers
# de confiance de plus dans une chaine dont on met justement la confiance en
# doute.
# ---------------------------------------------------------------------------

TAILLE_COMPOSANT = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
FORMAT_COMPOSANT = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I",
                    5126: "f"}
NOMBRE_CANAUX = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def lire_glb(chemin):
    """Rend (json, blob binaire). Le GLB est deux morceaux, pas davantage."""
    with open(chemin, "rb") as flux:
        entete = flux.read(12)
        magique, _version, _longueur = struct.unpack("<4sII", entete)
        if magique != b"glTF":
            raise SystemExit("ce fichier n'est pas un GLB : %s" % chemin)
        gltf = None
        blob = b""
        while True:
            entete_morceau = flux.read(8)
            if len(entete_morceau) < 8:
                break
            longueur, genre = struct.unpack("<II", entete_morceau)
            donnees = flux.read(longueur)
            if genre == 0x4E4F534A:
                gltf = json.loads(donnees.decode("utf-8"))
            elif genre == 0x004E4942:
                blob = donnees
    if gltf is None:
        raise SystemExit("aucun morceau JSON dans %s" % chemin)
    return gltf, blob


def lire_accesseur(gltf, blob, indice):
    """Extrait un accesseur en respectant son `byteStride`.

    Un exportateur a le droit d'entrelacer les attributs ; ignorer le pas
    rendrait des positions fausses SANS erreur visible, ce qui est
    exactement la famille de panne que ce projet documente.
    """
    acc = gltf["accessors"][indice]
    canaux = NOMBRE_CANAUX[acc["type"]]
    fmt = FORMAT_COMPOSANT[acc["componentType"]]
    taille = TAILLE_COMPOSANT[acc["componentType"]] * canaux
    vue = gltf["bufferViews"][acc["bufferView"]]
    base = vue.get("byteOffset", 0) + acc.get("byteOffset", 0)
    pas = vue.get("byteStride") or taille
    sortie = []
    for k in range(acc["count"]):
        debut = base + k * pas
        valeurs = struct.unpack_from("<" + fmt * canaux, blob, debut)
        sortie.append(valeurs if canaux > 1 else valeurs[0])
    return sortie


def maillage_par_nom(gltf, blob):
    """Rend {nom: (sommets, triangles)} en fusionnant les primitives.

    Un GLB stocke UNE primitive PAR MATERIAU : la grotte en a six. Compter
    des aretes ou des paires sans les avoir fusionnees mesurerait six
    surfaces separees, avec des bords libres partout ou il n'y en a aucun.
    C'est un piege documente de ce depot ; on le desamorce ici en soudant
    par POSITION, pas par indice de primitive.
    """
    sortie = {}
    for maillage in gltf.get("meshes", []):
        nom = maillage.get("name", "sans_nom")
        positions = []
        triangles = []
        for prim in maillage.get("primitives", []):
            if prim.get("mode", 4) != 4:
                continue
            decalage = len(positions)
            positions.extend(lire_accesseur(gltf, blob,
                                            prim["attributes"]["POSITION"]))
            if "indices" in prim:
                indices = lire_accesseur(gltf, blob, prim["indices"])
            else:
                indices = list(range(len(positions) - decalage))
            for k in range(0, len(indices) - 2, 3):
                triangles.append((indices[k] + decalage,
                                  indices[k + 1] + decalage,
                                  indices[k + 2] + decalage))
        sortie[nom] = (positions, triangles)
    return sortie


def souder(positions, triangles):
    """Fusionne les sommets de position BINAIREMENT identique.

    Pas de tolerance : deux float32 egaux bit a bit sont le meme point, et
    deux float32 differents sont deux points differents. Introduire un
    epsilon ici recreerait le probleme qu'on essaie de mesurer.
    """
    table = {}
    uniques = []
    remap = []
    for pos in positions:
        cle = pos
        if cle not in table:
            table[cle] = len(uniques)
            uniques.append(pos)
        remap.append(table[cle])
    tris = []
    for a, b, c in triangles:
        tris.append((remap[a], remap[b], remap[c]))
    return uniques, tris


# ---------------------------------------------------------------------------
# PREDICATS EXACTS — tout ce qui suit est en Fraction, donc sans arrondi.
# ---------------------------------------------------------------------------

def en_fractions(sommets):
    return [tuple(Fraction(c) for c in p) for p in sommets]


def soustraire3(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def produit_vectoriel(u, v):
    return (u[1] * v[2] - u[2] * v[1],
            u[2] * v[0] - u[0] * v[2],
            u[0] * v[1] - u[1] * v[0])


def produit_scalaire(u, v):
    return u[0] * v[0] + u[1] * v[1] + u[2] * v[2]


def orient3d(a, b, c, d):
    """Signe du volume oriente du tetraedre (a,b,c,d). Exact."""
    return produit_scalaire(produit_vectoriel(soustraire3(b, a),
                                              soustraire3(c, a)),
                            soustraire3(d, a))


def normale_exacte(t):
    return produit_vectoriel(soustraire3(t[1], t[0]), soustraire3(t[2], t[0]))


def nul3(v):
    return v[0] == 0 and v[1] == 0 and v[2] == 0


def aire_double_carree(t):
    """Carre de la norme du produit vectoriel — exact, et nul ssi l'aire
    l'est. On evite la racine, qui serait irrationnelle et donc arrondie."""
    n = normale_exacte(t)
    return n[0] * n[0] + n[1] * n[1] + n[2] * n[2]


# ---------------------------------------------------------------------------
# INTERSECTION EXACTE DE DEUX TRIANGLES
# ---------------------------------------------------------------------------

def _intervalle_interieur(triangle, normale, origine, direction):
    """Intervalle OUVERT des t pour lesquels origine + t*direction est
    strictement a l'interieur de `triangle`.

    Pour chaque arete (qi, qj), le point P est du bon cote ssi
    ((qj - qi) x (P - qi)) . N > 0. Cette quantite est AFFINE en t : on la
    resout exactement, sans echantillonner. Rend (bas, haut) ou None.
    """
    bas = None
    haut = None
    for k in range(3):
        qi = triangle[k]
        qj = triangle[(k + 1) % 3]
        arete = soustraire3(qj, qi)
        # f(t) = ((qj-qi) x (O + tD - qi)) . N = c0 + t*c1
        c0 = produit_scalaire(produit_vectoriel(arete,
                                                soustraire3(origine, qi)),
                              normale)
        c1 = produit_scalaire(produit_vectoriel(arete, direction), normale)
        if c1 == 0:
            if c0 <= 0:
                return None
            continue
        limite = Fraction(-c0, 1) / c1
        if c1 > 0:
            if bas is None or limite > bas:
                bas = limite
        else:
            if haut is None or limite < haut:
                haut = limite
    return (bas, haut)


def _borne_max(a, b):
    if a is None:
        return b
    if b is None:
        return a
    return max(a, b)


def _borne_min(a, b):
    if a is None:
        return b
    if b is None:
        return a
    return min(a, b)


def classer_paire(t1, t2):
    """Verdict exact sur deux triangles donnes par leurs sommets Fraction.

    Rend l'une des chaines :
      DEGENERE            l'un des deux est d'aire nulle, le test n'a pas
                          de sens et on le dit au lieu de rendre 0
      PARALLELE_DISJOINT  plans paralleles distincts
      COPLANAIRE          memes plans — traite a part, voir plus bas
      DISJOINT            aucun point commun
      CONTACT             points communs, tous sur la frontiere des deux
      PENETRATION         interieurs relatifs qui se rencontrent
    """
    n1 = normale_exacte(t1)
    n2 = normale_exacte(t2)
    if nul3(n1) or nul3(n2):
        return "DEGENERE", None

    d1 = [produit_scalaire(n2, soustraire3(p, t2[0])) for p in t1]
    d2 = [produit_scalaire(n1, soustraire3(q, t1[0])) for q in t2]

    if all(x > 0 for x in d1) or all(x < 0 for x in d1):
        return "DISJOINT", None
    if all(x > 0 for x in d2) or all(x < 0 for x in d2):
        return "DISJOINT", None

    direction = produit_vectoriel(n1, n2)
    if nul3(direction):
        # Plans paralleles. Confondus ou non ?
        if d1[0] != 0:
            return "PARALLELE_DISJOINT", None
        return "COPLANAIRE", None

    # Droite d'intersection des deux plans : un point d'origine exact, puis
    # la direction ci-dessus. On resout le systeme des deux plans en fixant
    # la coordonnee dont la direction est la plus « franche » — ici, la
    # composante non nulle de `direction`.
    axe = 0 if direction[0] != 0 else (1 if direction[1] != 0 else 2)
    u, v = [k for k in range(3) if k != axe]
    c1 = produit_scalaire(n1, t1[0])
    c2 = produit_scalaire(n2, t2[0])
    det = n1[u] * n2[v] - n1[v] * n2[u]
    if det == 0:
        return "DISJOINT", None
    origine = [Fraction(0), Fraction(0), Fraction(0)]
    origine[u] = Fraction(c1 * n2[v] - c2 * n1[v], 1) / det
    origine[v] = Fraction(n1[u] * c2 - n2[u] * c1, 1) / det
    origine = tuple(origine)

    i1 = _intervalle_interieur(t1, n1, origine, direction)
    i2 = _intervalle_interieur(t2, n2, origine, direction)
    if i1 is None or i2 is None:
        return "CONTACT", None
    bas = _borne_max(i1[0], i2[0])
    haut = _borne_min(i1[1], i2[1])
    if bas is None or haut is None or bas >= haut:
        return "CONTACT", None
    milieu = (bas + haut) / 2
    point = tuple(origine[k] + milieu * direction[k] for k in range(3))
    return "PENETRATION", (point, bas, haut, direction, t1, t2)


def profondeur_et_etendue(details):
    """DEUX grandeurs, parce qu'une seule tromperait.

    * ETENDUE : longueur du segment le long duquel les deux triangles se
      coupent reellement. C'est la taille de la couture.
    * ENFONCEMENT : de combien un triangle plonge derriere le plan de
      l'autre. C'est la grandeur que `REPLI_LIVRABLE_MAX_M = 0.02` borne, et
      c'est donc elle qu'il faut comparer au seuil.

    Une longue couture tres peu profonde et une courte penetration profonde
    sont deux defauts differents ; les confondre sous le seul mot « repli »
    est ce qui a permis a six penetrations d'etre publiees comme deux.

    Les bornes sont exactes ; la racine carree finale ne l'est pas, et c'est
    sans consequence : on publie ici un metre, pas un predicat.
    """
    _point, bas, haut, direction, t1, t2 = details
    norme = float(produit_scalaire(direction, direction)) ** 0.5
    etendue = float(haut - bas) * norme

    def enfoncement(a, b):
        n = normale_exacte(b)
        norme_n = float(produit_scalaire(n, n)) ** 0.5
        if norme_n == 0.0:
            return 0.0
        d = [float(produit_scalaire(n, soustraire3(p, b[0]))) / norme_n
             for p in a]
        return min(max(d), -min(d))

    return min(enfoncement(t1, t2), enfoncement(t2, t1)), etendue


# ---------------------------------------------------------------------------
# RECHERCHE — grille de hachage en flottant, verdict en exact.
# ---------------------------------------------------------------------------

def boites(sommets, triangles):
    for tri in triangles:
        pts = [sommets[i] for i in tri]
        yield (min(p[0] for p in pts), min(p[1] for p in pts),
               min(p[2] for p in pts), max(p[0] for p in pts),
               max(p[1] for p in pts), max(p[2] for p in pts))


def paires_candidates(sommets, triangles, pas):
    """Toutes les paires dont les boites se chevauchent, sans exclusion.

    On n'ecarte AUCUNE paire a ce stade, pas meme les faces adjacentes : le
    filtre « elles partagent un indice » du generateur est precisement ce
    dont on met la validite en doute. Le tri se fait au verdict exact.
    """
    cases = defaultdict(list)
    aabb = list(boites(sommets, triangles))
    for indice, (x0, y0, z0, x1, y1, z1) in enumerate(aabb):
        for cx in range(int(x0 // pas), int(x1 // pas) + 1):
            for cy in range(int(y0 // pas), int(y1 // pas) + 1):
                for cz in range(int(z0 // pas), int(z1 // pas) + 1):
                    cases[(cx, cy, cz)].append(indice)
    vues = set()
    for occupants in cases.values():
        for i in range(len(occupants)):
            for j in range(i + 1, len(occupants)):
                a, b = occupants[i], occupants[j]
                if a > b:
                    a, b = b, a
                if (a, b) in vues:
                    continue
                vues.add((a, b))
                ba, bb = aabb[a], aabb[b]
                if ba[3] < bb[0] or bb[3] < ba[0]:
                    continue
                if ba[4] < bb[1] or bb[4] < ba[1]:
                    continue
                if ba[5] < bb[2] or bb[5] < ba[2]:
                    continue
                yield a, b


def analyser(nom, sommets, triangles, pas, bavard):
    print("[exact] === %s : %d sommets soudes, %d triangles"
          % (nom, len(sommets), len(triangles)))
    frac = en_fractions(sommets)

    # --- 1. AIRES EXACTEMENT NULLES -------------------------------------
    nulles = []
    presque = []
    for indice, tri in enumerate(triangles):
        t = [frac[i] for i in tri]
        carre = aire_double_carree(t)
        if carre == 0:
            nulles.append(indice)
        elif carre < Fraction(4, 10 ** 18):     # aire < 1e-9 m2
            presque.append((indice, carre))
    print("[exact] aire EXACTEMENT nulle : %d face(s)" % len(nulles))
    for indice in nulles:
        tri = triangles[indice]
        pts = [sommets[i] for i in tri]
        centre = tuple(sum(p[k] for p in pts) / 3.0 for k in range(3))
        aretes = []
        for k in range(3):
            u = soustraire3(frac[tri[(k + 1) % 3]], frac[tri[k]])
            aretes.append(float(produit_scalaire(u, u)) ** 0.5)
        confondus = len({tri[0], tri[1], tri[2]}) < 3
        print("[exact]   face %d  centre (%.4f, %.4f, %.4f)"
              % (indice, centre[0], centre[1], centre[2]))
        print("[exact]     sommets %s" % (list(tri),))
        for k, p in enumerate(pts):
            print("[exact]       s%d = (%.9f, %.9f, %.9f)" % (k, p[0], p[1], p[2]))
        print("[exact]     aretes %.9f / %.9f / %.9f m"
              % (aretes[0], aretes[1], aretes[2]))
        print("[exact]     deux sommets confondus : %s ; plus courte arete "
              "%.9f m" % ("OUI" if confondus else "NON", min(aretes)))
    print("[exact] aire < 1e-9 m2 mais NON nulle : %d face(s)" % len(presque))
    for indice, carre in presque:
        pts = [sommets[i] for i in triangles[indice]]
        centre = tuple(sum(p[k] for p in pts) / 3.0 for k in range(3))
        print("[exact]   face %d  aire %.3e m2  centre (%.4f, %.4f, %.4f)"
              % (indice, float(carre) ** 0.5 / 2.0,
                 centre[0], centre[1], centre[2]))

    # --- 2. PENETRATIONS ------------------------------------------------
    comptes = defaultdict(int)
    penetrations = []
    total = 0
    for a, b in paires_candidates(sommets, triangles, pas):
        total += 1
        ta = [frac[i] for i in triangles[a]]
        tb = [frac[i] for i in triangles[b]]
        verdict, point = classer_paire(ta, tb)
        comptes[verdict] += 1
        if verdict == "PENETRATION":
            penetrations.append((a, b, point))
        elif verdict == "COPLANAIRE":
            comptes["COPLANAIRE"] = comptes["COPLANAIRE"]
    print("[exact] paires a boites chevauchantes : %d" % total)
    for cle in sorted(comptes):
        print("[exact]   %-20s %d" % (cle, comptes[cle]))
    print("[exact] PENETRATIONS REELLES : %d" % len(penetrations))
    pire_prof = 0.0
    pire_etendue = 0.0
    for a, b, details in penetrations:
        pa = [sommets[i] for i in triangles[a]]
        pb = [sommets[i] for i in triangles[b]]
        ca = tuple(sum(p[k] for p in pa) / 3.0 for k in range(3))
        cb = tuple(sum(p[k] for p in pb) / 3.0 for k in range(3))
        communs = len(set(triangles[a]) & set(triangles[b]))
        point = details[0]
        prof, etendue = profondeur_et_etendue(details)
        pire_prof = max(pire_prof, prof)
        pire_etendue = max(pire_etendue, etendue)
        print("[exact]   faces %d / %d  sommets communs %d" % (a, b, communs))
        print("[exact]     centres (%.4f, %.4f, %.4f) et (%.4f, %.4f, %.4f)"
              % (ca + cb))
        print("[exact]     enfoncement %.6f m   etendue de couture %.6f m"
              % (prof, etendue))
        print("[exact]     point interieur commun (%.9f, %.9f, %.9f)"
              % (float(point[0]), float(point[1]), float(point[2])))
    if penetrations:
        print("[exact]   ENFONCEMENT MAXIMAL %.6f m  (seuil livrable "
              "0.020 m)  ETENDUE MAXIMALE %.6f m" % (pire_prof, pire_etendue))
        if bavard:
            for etiquette, tri in (("A", triangles[a]), ("B", triangles[b])):
                for k, i in enumerate(tri):
                    p = sommets[i]
                    print("[exact]       %s.s%d idx %d = (%.9f, %.9f, %.9f)"
                          % (etiquette, k, i, p[0], p[1], p[2]))
    return len(nulles), len(penetrations)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("glb")
    ap.add_argument("--maillage", default=None,
                    help="nom exact ; par defaut, tous")
    ap.add_argument("--pas", type=float, default=0.25,
                    help="cote de la case de hachage, en metres")
    ap.add_argument("--bavard", action="store_true")
    args = ap.parse_args()

    gltf, blob = lire_glb(args.glb)
    print("[exact] fichier %s" % args.glb)
    for noeud in gltf.get("nodes", []):
        if "mesh" in noeud:
            print("[exact] noeud %-24s matrice=%s translation=%s "
                  "rotation=%s echelle=%s"
                  % (noeud.get("name", "?"),
                     "oui" if "matrix" in noeud else "non",
                     noeud.get("translation"), noeud.get("rotation"),
                     noeud.get("scale")))
    tout = maillage_par_nom(gltf, blob)
    total_nulles = 0
    total_pen = 0
    for nom, (positions, triangles) in sorted(tout.items()):
        if args.maillage and nom != args.maillage:
            continue
        sommets, tris = souder(positions, triangles)
        print("[exact] %s : %d positions brutes -> %d apres soudure"
              % (nom, len(positions), len(sommets)))
        nulles, pen = analyser(nom, sommets, tris, args.pas, args.bavard)
        total_nulles += nulles
        total_pen += pen
    print("[exact] TOTAL : %d face(s) d'aire exactement nulle, "
          "%d penetration(s) reelle(s)" % (total_nulles, total_pen))
    return 0


if __name__ == "__main__":
    sys.exit(main())
