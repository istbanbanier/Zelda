#!/usr/bin/env python3
"""Boîtitude d'un .glb : quelle part des triangles appartient à des pavés ?

Portail de forme de R2B.3 (ISS-060). Trois prédicats emboîtés, publiés
ENSEMBLE parce qu'ils répondent à trois questions différentes :

  hexa          composante de 12 triangles ET 8 sommets géométriques distincts
                après soudage par position — « un solide à huit coins »
  equidistance  hexa + les 8 coins à EQUI_TOL près de la distance moyenne au
                centroïde — « un pavé, quelle que soit son orientation »
  droite        equidistance + exactement 6 directions de normale de face
                — « un pavé aligné sur ses propres axes »

Le LIANT du portail est `hexa`, le plus lâche : il est le seul qui ne puisse
pas être contourné en bougeant légèrement les coins d'un cube.

PIÈGE MESURÉ (2026-08-19, R2B.2, VERIFICATIONS_LEAD §28) : une première
version fusionnait le soudage par position et la connexité dans une SEULE
union-find. Chaque composante s'effondrait alors sur un sommet racine unique,
« 8 sommets » ne pouvait jamais être vrai, et l'instrument rendait 0,0 % sur
un maillage à 79,6 %. Il a été attrapé parce que le chiffre était invraisemblable,
pas parce que le code a protesté. D'où l'ordre imposé ici, et le cas témoin
analytique `--autotest` qui fabrique un cube et EXIGE 100 %.

Sort aussi la morphométrie qui rend les contournements visibles : triangles,
emprise, aire totale, aire médiane de composante et arête minimale. Un lot qui
ferait tomber la boîtitude en pulvérisant la géométrie en bruit sous-pixel
verrait son arête minimale s'effondrer et son compte de composantes exploser.

Usage :
    python3 tools/mesure_boititude.py <fichier.glb> [--json] [--plafond 25]
    python3 tools/mesure_boititude.py --autotest
"""

import argparse
import json
import math
import struct
import sys

GLB_MAGIC = 0x46546C67
CHUNK_JSON = 0x4E4F534A
CHUNK_BIN = 0x004E4942

SOUDAGE_M = 1e-5        # deux sommets à moins de 10 µm sont le même coin
EQUI_TOL = 0.02         # 2 % de la distance moyenne au centroïde
NORMALE_DOT = 0.999     # ~2,56° : deux faces coplanaires

_TAILLE = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
_FORMAT = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I", 5126: "f"}
_COMPOSANTES = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def lire_glb(chemin):
    with open(chemin, "rb") as h:
        blob = h.read()
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
        debut = base + i * stride
        sortie.append(struct.unpack_from("<" + fmt * n_comp, binaire, debut))
    return sortie


def _racine(parent, a):
    while parent[a] != a:
        parent[a] = parent[parent[a]]
        a = parent[a]
    return a


def _unir(parent, a, b):
    ra, rb = _racine(parent, a), _racine(parent, b)
    if ra != rb:
        parent[rb] = ra


def analyser_primitive(positions, indices):
    """Rend la liste des composantes, chacune : (n_triangles, n_sommets, verdicts)."""
    # ÉTAPE 1 — soudage par POSITION. Jamais fusionné avec l'étape 2.
    grille = {}
    geo_de = []
    for p in positions:
        cle = (round(p[0] / SOUDAGE_M), round(p[1] / SOUDAGE_M), round(p[2] / SOUDAGE_M))
        if cle not in grille:
            grille[cle] = len(grille)
        geo_de.append(grille[cle])
    n_geo = len(grille)
    coord_geo = [None] * n_geo
    for i, p in enumerate(positions):
        coord_geo[geo_de[i]] = (p[0], p[1], p[2])

    # ÉTAPE 2 — connexité sur les IDENTIFIANTS GÉOMÉTRIQUES, pas sur les sommets bruts.
    parent = list(range(n_geo))
    triangles = []
    for t in range(0, len(indices) - 2, 3):
        a, b, c = geo_de[indices[t]], geo_de[indices[t + 1]], geo_de[indices[t + 2]]
        triangles.append((a, b, c))
        _unir(parent, a, b)
        _unir(parent, b, c)

    comps = {}
    for tri in triangles:
        r = _racine(parent, tri[0])
        comps.setdefault(r, {"tris": [], "sommets": set()})
        comps[r]["tris"].append(tri)
        comps[r]["sommets"].update(tri)

    sortie = []
    for donnees in comps.values():
        n_tri = len(donnees["tris"])
        sommets = sorted(donnees["sommets"])
        n_som = len(sommets)
        v_hexa = (n_tri == 12 and n_som == 8)
        v_equi = False
        v_droite = False
        if v_hexa:
            pts = [coord_geo[s] for s in sommets]
            cx = sum(p[0] for p in pts) / 8.0
            cy = sum(p[1] for p in pts) / 8.0
            cz = sum(p[2] for p in pts) / 8.0
            d = [math.dist(p, (cx, cy, cz)) for p in pts]
            moy = sum(d) / 8.0
            v_equi = moy > 0.0 and all(abs(x - moy) <= EQUI_TOL * moy for x in d)
        if v_equi:
            grappes = []
            for a, b, c in donnees["tris"]:
                pa, pb, pc = coord_geo[a], coord_geo[b], coord_geo[c]
                u = (pb[0] - pa[0], pb[1] - pa[1], pb[2] - pa[2])
                v = (pc[0] - pa[0], pc[1] - pa[1], pc[2] - pa[2])
                nx = u[1] * v[2] - u[2] * v[1]
                ny = u[2] * v[0] - u[0] * v[2]
                nz = u[0] * v[1] - u[1] * v[0]
                norme = math.sqrt(nx * nx + ny * ny + nz * nz)
                if norme <= 0.0:
                    continue
                n = (nx / norme, ny / norme, nz / norme)
                # Normale SIGNÉE : +X et -X sont deux faces, pas une. Avec abs(),
                # un pavé rendrait 3 grappes et `droite` serait toujours faux —
                # piège attrapé par le cas témoin du cube unité.
                if not any(n[0] * g[0] + n[1] * g[1] + n[2] * g[2] >= NORMALE_DOT
                           for g in grappes):
                    grappes.append(n)
            v_droite = (len(grappes) == 6)
        sortie.append({"tris": n_tri, "sommets": n_som,
                       "hexa": v_hexa, "equidistance": v_equi, "droite": v_droite,
                       "aire": _aire(donnees["tris"], coord_geo),
                       "arete_min": _arete_min(donnees["tris"], coord_geo)})
    return sortie


def _aire(tris, coord):
    total = 0.0
    for a, b, c in tris:
        pa, pb, pc = coord[a], coord[b], coord[c]
        u = (pb[0] - pa[0], pb[1] - pa[1], pb[2] - pa[2])
        v = (pc[0] - pa[0], pc[1] - pa[1], pc[2] - pa[2])
        nx = u[1] * v[2] - u[2] * v[1]
        ny = u[2] * v[0] - u[0] * v[2]
        nz = u[0] * v[1] - u[1] * v[0]
        total += 0.5 * math.sqrt(nx * nx + ny * ny + nz * nz)
    return total


def _arete_min(tris, coord):
    mini = float("inf")
    for a, b, c in tris:
        for x, y in ((a, b), (b, c), (c, a)):
            if x == y:
                continue
            d = math.dist(coord[x], coord[y])
            if 0.0 < d < mini:
                mini = d
    return mini if mini != float("inf") else 0.0


def mesurer(chemin):
    gltf, binaire = lire_glb(chemin)
    resultats = []
    for mesh in gltf.get("meshes", []):
        nom = mesh.get("name", "?")
        comps = []
        for prim in mesh.get("primitives", []):
            if "POSITION" not in prim.get("attributes", {}):
                continue
            positions = lire_accessor(gltf, binaire, prim["attributes"]["POSITION"])
            if "indices" in prim:
                indices = [i[0] for i in lire_accessor(gltf, binaire, prim["indices"])]
            else:
                indices = list(range(len(positions)))
            comps.extend(analyser_primitive(positions, indices))
        if not comps:
            continue
        n_tri = sum(c["tris"] for c in comps)
        aires = sorted(c["aire"] for c in comps)
        med = aires[len(aires) // 2] if aires else 0.0
        resultats.append({
            "mesh": nom,
            "composantes": len(comps),
            "triangles": n_tri,
            "tris_hexa": sum(c["tris"] for c in comps if c["hexa"]),
            "tris_equidistance": sum(c["tris"] for c in comps if c["equidistance"]),
            "tris_droite": sum(c["tris"] for c in comps if c["droite"]),
            "aire_totale": round(sum(c["aire"] for c in comps), 4),
            "aire_mediane_composante": round(med, 5),
            "arete_min": round(min(c["arete_min"] for c in comps), 6),
        })
    return resultats


def autotest():
    """Cas témoins analytiques. Un instrument qui ne les passe pas ne mesure rien."""
    cube = [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0),
            (0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]
    faces = [(0, 1, 2), (0, 2, 3), (4, 6, 5), (4, 7, 6), (0, 4, 5), (0, 5, 1),
             (1, 5, 6), (1, 6, 2), (2, 6, 7), (2, 7, 3), (3, 7, 4), (3, 4, 0)]
    idx = [i for f in faces for i in f]
    c = analyser_primitive([tuple(map(float, p)) for p in cube], idx)
    ok = (len(c) == 1 and c[0]["tris"] == 12 and c[0]["sommets"] == 8
          and c[0]["hexa"] and c[0]["equidistance"] and c[0]["droite"])
    print("cube unité            : hexa=%s equi=%s droite=%s  -> %s"
          % (c[0]["hexa"], c[0]["equidistance"], c[0]["droite"], "OK" if ok else "ECHEC"))

    # Sommets dupliqués par face (24 sommets bruts) : le soudage DOIT les ramener à 8.
    plat, plat_idx = [], []
    for f in faces:
        for i in f:
            plat_idx.append(len(plat))
            plat.append(tuple(map(float, cube[i])))
    c2 = analyser_primitive(plat, plat_idx)
    ok2 = (len(c2) == 1 and c2[0]["sommets"] == 8 and c2[0]["hexa"])
    print("cube à sommets éclatés: sommets=%d hexa=%s -> %s"
          % (c2[0]["sommets"], c2[0]["hexa"], "OK" if ok2 else "ECHEC"))

    # Boîte déformée : un coin tiré. hexa VRAI, équidistance FAUSSE.
    tordu = list(cube)
    tordu[6] = (1.6, 1.45, 1.5)
    c3 = analyser_primitive([tuple(map(float, p)) for p in tordu], idx)
    ok3 = (c3[0]["hexa"] and not c3[0]["equidistance"])
    print("boîte déformée        : hexa=%s equi=%s -> %s"
          % (c3[0]["hexa"], c3[0]["equidistance"], "OK" if ok3 else "ECHEC"))

    # Deux cubes DISJOINTS : deux composantes, pas une seule à 16 sommets.
    d = [(p[0] + 5.0, p[1], p[2]) for p in cube]
    c4 = analyser_primitive([tuple(map(float, p)) for p in cube + d],
                            idx + [i + 8 for i in idx])
    ok4 = (len(c4) == 2 and all(x["hexa"] for x in c4))
    print("deux cubes disjoints  : composantes=%d -> %s"
          % (len(c4), "OK" if ok4 else "ECHEC"))

    # Tétraèdre : 4 triangles, 4 sommets. Aucun prédicat.
    tet = [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1)]
    c5 = analyser_primitive([tuple(map(float, p)) for p in tet],
                            [0, 1, 2, 0, 1, 3, 0, 2, 3, 1, 2, 3])
    ok5 = (not c5[0]["hexa"])
    print("tétraèdre             : hexa=%s -> %s" % (c5[0]["hexa"], "OK" if ok5 else "ECHEC"))
    return 0 if all([ok, ok2, ok3, ok4, ok5]) else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("fichier", nargs="?")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--plafond", type=float, default=None,
                    help="pourcentage hexa maximum toléré ; sort 1 si dépassé")
    ap.add_argument("--mesh", action="append", default=None,
                    help="restreindre le verdict à ces meshes (répétable)")
    ap.add_argument("--autotest", action="store_true")
    a = ap.parse_args()
    if a.autotest:
        return autotest()
    if not a.fichier:
        ap.error("fichier requis (ou --autotest)")
    res = mesurer(a.fichier)
    retenus = [r for r in res if (a.mesh is None or r["mesh"] in a.mesh)]
    tri = sum(r["triangles"] for r in retenus)
    hexa = sum(r["tris_hexa"] for r in retenus)
    equi = sum(r["tris_equidistance"] for r in retenus)
    droite = sum(r["tris_droite"] for r in retenus)
    part = 100.0 * hexa / tri if tri else 0.0
    if a.json:
        print(json.dumps({"fichier": a.fichier, "meshes": res,
                          "retenus": [r["mesh"] for r in retenus],
                          "total_triangles": tri, "hexa_pct": round(part, 2),
                          "equidistance_pct": round(100.0 * equi / tri, 2) if tri else 0.0,
                          "droite_pct": round(100.0 * droite / tri, 2) if tri else 0.0},
                         ensure_ascii=False, indent=2))
    else:
        print("%-22s %5s %6s %8s %8s %8s %9s %9s" %
              ("mesh", "comp", "tris", "hexa", "equi", "droite", "aire_med", "arete_min"))
        for r in res:
            marque = "*" if (a.mesh is not None and r["mesh"] in a.mesh) else " "
            print("%s%-21s %5d %6d %7.1f%% %7.1f%% %7.1f%% %9.5f %9.6f" % (
                marque, r["mesh"], r["composantes"], r["triangles"],
                100.0 * r["tris_hexa"] / r["triangles"],
                100.0 * r["tris_equidistance"] / r["triangles"],
                100.0 * r["tris_droite"] / r["triangles"],
                r["aire_mediane_composante"], r["arete_min"]))
        etendue = "les meshes retenus" if a.mesh else "TOTAL"
        print("%-22s %5s %6d %7.1f%% %7.1f%% %7.1f%%" % (
            etendue, "", tri, part,
            100.0 * equi / tri if tri else 0.0,
            100.0 * droite / tri if tri else 0.0))
    if a.plafond is not None:
        if part > a.plafond:
            sys.stderr.write("ECHEC : hexa %.1f%% > plafond %.1f%%\n" % (part, a.plafond))
            return 1
        sys.stderr.write("OK : hexa %.1f%% <= plafond %.1f%%\n" % (part, a.plafond))
    return 0


if __name__ == "__main__":
    sys.exit(main())
