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

# PORTÉE À 0,1 mm SUR CONSTAT DE L'AUDIT (2026-08-20). À 10 µm, déplacer un
# coin de 12 µm le dédoublait : la composante passait à 9 sommets et cessait
# d'être une boîte pour l'instrument, sans que l'image bouge d'un pixel. 0,1 mm
# reste 5× sous la plus fine arête d'un asset accepté (pont de pierre, 0,57 mm).
SOUDAGE_M = 1e-4
EQUI_TOL = 0.02         # 2 % de la distance moyenne au centroïde
NORMALE_DOT = 0.999     # ~2,56° : deux faces coplanaires
PLAN_EPS = 1e-3         # deux triangles dans le même plan à 1 mm près
AIRE_NULLE = 1e-10      # en dessous, le triangle est dégénéré et ne compte pas
FINESSE_M = 2e-3        # un triangle dont la plus longue arête est sous 2 mm
                        # est de la poussière, pas de la matière

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


def _normale(pa, pb, pc):
    u = (pb[0] - pa[0], pb[1] - pa[1], pb[2] - pa[2])
    v = (pc[0] - pa[0], pc[1] - pa[1], pc[2] - pa[2])
    n = (u[1] * v[2] - u[2] * v[1],
         u[2] * v[0] - u[0] * v[2],
         u[0] * v[1] - u[1] * v[0])
    norme = math.sqrt(n[0] * n[0] + n[1] * n[1] + n[2] * n[2])
    if norme <= 0.0:
        return None, 0.0
    return (n[0] / norme, n[1] / norme, n[2] / norme), 0.5 * norme


def analyser_mesh(primitives):
    """Analyse un MESH ENTIER, primitives fondues.

    FONDRE LES PRIMITIVES EST OBLIGATOIRE, sur constat de l'audit (2026-08-20) :
    un pavé réparti sur deux primitives — parce que ses faces portent deux
    matériaux — apparaissait comme deux composantes de 6 triangles, donc comme
    « pas une boîte », alors que l'image montre un pavé. `Debris_A` porte déjà
    trois primitives.

    `primitives` : liste de (positions, indices).
    """
    # ÉTAPE 1 — soudage par POSITION, sur tout le mesh. Jamais fusionné avec 2.
    grille = {}
    geo_de = []          # index brut (cumulé) -> identifiant géométrique
    triangles = []
    for positions, indices in primitives:
        base = len(geo_de)
        for p in positions:
            cle = (round(p[0] / SOUDAGE_M), round(p[1] / SOUDAGE_M),
                   round(p[2] / SOUDAGE_M))
            if cle not in grille:
                grille[cle] = len(grille)
            geo_de.append(grille[cle])
        for t in range(0, len(indices) - 2, 3):
            triangles.append((geo_de[base + indices[t]],
                              geo_de[base + indices[t + 1]],
                              geo_de[base + indices[t + 2]]))
    n_geo = len(grille)
    coord = [None] * n_geo
    pos_cumul = []
    for positions, _ in primitives:
        pos_cumul.extend(positions)
    for i, p in enumerate(pos_cumul):
        coord[geo_de[i]] = (p[0], p[1], p[2])

    # LES TRIANGLES DÉGÉNÉRÉS SONT ÉCARTÉS AVANT TOUT COMPTAGE.
    # Sans cela, un seul triangle d'aire nulle ajouté à un pavé le faisait
    # passer de 12 à 13 triangles, donc « pas une boîte », sans qu'aucun pixel
    # ne change (constat de l'audit, 2026-08-20).
    vivants = []
    for tri in triangles:
        n, aire = _normale(coord[tri[0]], coord[tri[1]], coord[tri[2]])
        if n is None or aire <= AIRE_NULLE:
            continue
        vivants.append((tri, n, aire))

    # ÉTAPE 2 — connexité sur les IDENTIFIANTS GÉOMÉTRIQUES.
    parent = list(range(n_geo))
    for tri, _n, _a in vivants:
        _unir(parent, tri[0], tri[1])
        _unir(parent, tri[1], tri[2])

    comps = {}
    for tri, n, aire in vivants:
        r = _racine(parent, tri[0])
        comps.setdefault(r, [])
        comps[r].append((tri, n, aire))

    sortie = []
    for faces in comps.values():
        sommets = sorted({s for tri, _n, _a in faces for s in tri})
        n_tri = len(faces)
        n_som = len(sommets)

        # --- plans : normale signée + distance à l'origine ---
        plans = []                       # [(normale, d, {sommets})]
        for tri, n, _a in faces:
            d = (n[0] * coord[tri[0]][0] + n[1] * coord[tri[0]][1]
                 + n[2] * coord[tri[0]][2])
            trouve = None
            for pl in plans:
                if (n[0] * pl[0][0] + n[1] * pl[0][1] + n[2] * pl[0][2]
                        >= NORMALE_DOT and abs(d - pl[1]) <= PLAN_EPS):
                    trouve = pl
                    break
            if trouve is None:
                plans.append((n, d, set(tri)))
            else:
                trouve[2].update(tri)

        # Un COIN appartient à au moins trois plans. Un sommet de subdivision
        # coplanaire n'en touche qu'un : il ne compte pas.
        incidences = {}
        for _n, _d, sommets_du_plan in plans:
            for s in sommets_du_plan:
                incidences[s] = incidences.get(s, 0) + 1
        coins = [s for s, k in incidences.items() if k >= 3]

        v_hexa = (n_tri == 12 and n_som == 8)
        v_pave6 = (len(plans) == 6 and len(coins) == 8)
        v_liant = v_hexa or v_pave6

        v_equi = False
        v_droite = False
        if v_liant and len(coins) == 8:
            pts = [coord[s] for s in coins]
            c = (sum(p[0] for p in pts) / 8.0, sum(p[1] for p in pts) / 8.0,
                 sum(p[2] for p in pts) / 8.0)
            d = [math.dist(p, c) for p in pts]
            moy = sum(d) / 8.0
            v_equi = moy > 0.0 and all(abs(x - moy) <= EQUI_TOL * moy for x in d)
        if v_equi:
            v_droite = (len(plans) == 6)

        aire = sum(a for _t, _n, a in faces)
        aire_fine = 0.0
        for tri, _n, a in faces:
            aretes = [math.dist(coord[tri[i]], coord[tri[(i + 1) % 3]])
                      for i in range(3)]
            if max(aretes) < FINESSE_M:
                aire_fine += a
        sortie.append({"tris": n_tri, "sommets": n_som, "plans": len(plans),
                       "coins": len(coins),
                       "hexa": v_hexa, "pave6": v_pave6, "liant": v_liant,
                       "equidistance": v_equi, "droite": v_droite,
                       "aire": aire, "aire_fine": aire_fine,
                       "arete_min": _arete_min([t for t, _n, _a in faces], coord)})
    return sortie


def analyser_primitive(positions, indices):
    """Compatibilité : une primitive isolée. Les cas témoins l'utilisent."""
    return analyser_mesh([(positions, indices)])


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
        primitives = []
        for prim in mesh.get("primitives", []):
            if "POSITION" not in prim.get("attributes", {}):
                continue
            positions = lire_accessor(gltf, binaire, prim["attributes"]["POSITION"])
            if "indices" in prim:
                indices = [i[0] for i in lire_accessor(gltf, binaire, prim["indices"])]
            else:
                indices = list(range(len(positions)))
            primitives.append((positions, indices))
        if not primitives:
            continue
        comps = analyser_mesh(primitives)
        if not comps:
            continue
        n_tri = sum(c["tris"] for c in comps)
        aires = sorted(c["aire"] for c in comps)
        med = aires[len(aires) // 2] if aires else 0.0
        aire_tot = sum(c["aire"] for c in comps)
        resultats.append({
            "mesh": nom,
            "primitives": len(primitives),
            "composantes": len(comps),
            "triangles": n_tri,
            "tris_liant": sum(c["tris"] for c in comps if c["liant"]),
            "tris_hexa": sum(c["tris"] for c in comps if c["hexa"]),
            "tris_pave6": sum(c["tris"] for c in comps if c["pave6"]),
            "tris_equidistance": sum(c["tris"] for c in comps if c["equidistance"]),
            "tris_droite": sum(c["tris"] for c in comps if c["droite"]),
            "aire_totale": round(aire_tot, 4),
            "aire_mediane_composante": round(med, 5),
            "aire_fine_pct": round(100.0 * sum(c["aire_fine"] for c in comps)
                                   / aire_tot, 4) if aire_tot else 0.0,
            "arete_min": round(min(c["arete_min"] for c in comps), 6),
        })
    return resultats


def autotest():
    """Cas témoins analytiques. Un instrument qui ne les passe pas ne mesure rien.

    Les cinq premiers datent de l'écriture. Les cinq suivants viennent de
    l'audit indépendant du 2026-08-20 : chacun est une perturbation qui ne
    change RIEN à l'image et faisait pourtant tomber le liant à 0 %.
    """
    cube = [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0),
            (0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]
    faces = [(0, 1, 2), (0, 2, 3), (4, 6, 5), (4, 7, 6), (0, 4, 5), (0, 5, 1),
             (1, 5, 6), (1, 6, 2), (2, 6, 7), (2, 7, 3), (3, 7, 4), (3, 4, 0)]
    idx = [i for f in faces for i in f]
    f = lambda pts: [tuple(map(float, p)) for p in pts]
    resultats = []

    def cas(nom, comps, attendu_liant, extra=""):
        obtenu = any(c["liant"] for c in comps) if comps else False
        ok = (obtenu == attendu_liant)
        resultats.append(ok)
        print("%-34s liant=%-5s attendu=%-5s %s -> %s"
              % (nom, obtenu, attendu_liant, extra, "OK" if ok else "ECHEC"))

    c = analyser_primitive(f(cube), idx)
    cas("cube unité", c, True,
        "hexa=%s pave6=%s equi=%s droite=%s" % (c[0]["hexa"], c[0]["pave6"],
                                                c[0]["equidistance"], c[0]["droite"]))

    plat, plat_idx = [], []
    for fa in faces:
        for i in fa:
            plat_idx.append(len(plat))
            plat.append(tuple(map(float, cube[i])))
    c2 = analyser_primitive(plat, plat_idx)
    cas("cube à sommets éclatés", c2, True, "sommets=%d" % c2[0]["sommets"])

    tordu = list(cube)
    tordu[6] = (1.6, 1.45, 1.5)
    c3 = analyser_primitive(f(tordu), idx)
    cas("boîte déformée", c3, True, "equi=%s (doit être False)" % c3[0]["equidistance"])

    d = [(p[0] + 5.0, p[1], p[2]) for p in cube]
    c4 = analyser_primitive(f(cube + d), idx + [i + 8 for i in idx])
    cas("deux cubes disjoints", c4, True, "composantes=%d (doit être 2)" % len(c4))

    tet = [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1)]
    c5 = analyser_primitive(f(tet), [0, 1, 2, 0, 1, 3, 0, 2, 3, 1, 2, 3])
    cas("tétraèdre", c5, False, "plans=%d" % c5[0]["plans"])

    # --- AUDIT 2026-08-20 : cinq perturbations invisibles ---

    # a) triangle d'aire nulle ajouté : 13 triangles, mais toujours un pavé.
    c6 = analyser_primitive(f(cube), idx + [0, 1, 1])
    cas("cube + triangle d'aire nulle", c6, True, "tris retenus=%d" % c6[0]["tris"])

    # b) subdivision coplanaire au barycentre d'une face : 9 sommets, 14 tris.
    sub = list(cube) + [(0.5, 0.5, 0.0)]
    sub_faces = [fa for fa in faces if fa not in ((0, 1, 2), (0, 2, 3))]
    sub_faces += [(0, 1, 8), (1, 2, 8), (2, 3, 8), (3, 0, 8)]
    c7 = analyser_primitive(f(sub), [i for fa in sub_faces for i in fa])
    cas("cube subdivisé au barycentre", c7, True,
        "sommets=%d plans=%d coins=%d" % (c7[0]["sommets"], c7[0]["plans"],
                                          c7[0]["coins"]))

    # c) un coin décalé de 12 µm : le soudage doit le rattraper.
    micro = list(cube)
    micro[6] = (1.000012, 1.0, 1.0)
    c8 = analyser_primitive(f(micro), idx)
    cas("coin décalé de 12 µm", c8, True, "sommets=%d" % c8[0]["sommets"])

    # d) pavé réparti sur DEUX primitives (deux matériaux).
    pa = [tuple(map(float, cube[i])) for fa in faces[:6] for i in fa]
    pb = [tuple(map(float, cube[i])) for fa in faces[6:] for i in fa]
    c9 = analyser_mesh([(pa, list(range(len(pa)))), (pb, list(range(len(pb))))])
    cas("pavé sur deux primitives", c9, True, "composantes=%d" % len(c9))

    # e) aire fine : un pavé de 1 mm est de la poussière, pas de la matière.
    petit = [(x * 0.001, y * 0.001, z * 0.001) for (x, y, z) in cube]
    c10 = analyser_primitive(f(petit), idx)
    part = 100.0 * c10[0]["aire_fine"] / c10[0]["aire"]
    ok10 = part > 99.0
    resultats.append(ok10)
    print("%-34s aire_fine=%.1f%% (doit être 100) -> %s"
          % ("cube de 1 mm", part, "OK" if ok10 else "ECHEC"))

    return 0 if all(resultats) else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("fichier", nargs="?")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--plafond", type=float, default=None,
                    help="pourcentage LIANT maximum toléré ; sort 1 si dépassé")
    ap.add_argument("--mesh", action="append", default=None,
                    help="restreindre le verdict à ces meshes (répétable)")
    ap.add_argument("--autotest", action="store_true")
    a = ap.parse_args()
    if a.autotest:
        return autotest()
    if not a.fichier:
        ap.error("fichier requis (ou --autotest)")
    res = mesurer(a.fichier)
    connus = {r["mesh"] for r in res}

    # UN NOM DE MESH INCONNU EST UNE ERREUR, JAMAIS UN VERDICT.
    #
    # Constat de l'audit, 2026-08-20 : `--mesh Debris_A` (au lieu de
    # `SM_Farm_Debris_A`) rendait « hexa 0.0% <= plafond » et RC=0. Un portail
    # qui rend VERT sur un ensemble vide est pire qu'un portail absent : il
    # produit une ligne de rapport qu'on recopie dans un gate. Deux documents
    # du dépôt employaient déjà le nom court.
    if a.mesh:
        inconnus = [m for m in a.mesh if m not in connus]
        if inconnus:
            sys.stderr.write("BLOQUÉ : mesh(es) introuvable(s) dans %s : %s\n"
                             % (a.fichier, ", ".join(inconnus)))
            sys.stderr.write("         présents : %s\n"
                             % ", ".join(sorted(connus)))
            return 2

    retenus = [r for r in res if (a.mesh is None or r["mesh"] in a.mesh)]
    tri = sum(r["triangles"] for r in retenus)
    liant = sum(r["tris_liant"] for r in retenus)
    hexa = sum(r["tris_hexa"] for r in retenus)
    equi = sum(r["tris_equidistance"] for r in retenus)
    droite = sum(r["tris_droite"] for r in retenus)
    aire_tot = sum(r["aire_totale"] for r in retenus)
    aire_fine = sum(r["aire_totale"] * r["aire_fine_pct"] / 100.0 for r in retenus)
    part = 100.0 * liant / tri if tri else 0.0
    pct = lambda n: (100.0 * n / tri) if tri else 0.0

    if a.json:
        print(json.dumps({"fichier": a.fichier, "meshes": res,
                          "retenus": [r["mesh"] for r in retenus],
                          "total_triangles": tri,
                          "liant_pct": round(part, 2),
                          "hexa_pct": round(pct(hexa), 2),
                          "equidistance_pct": round(pct(equi), 2),
                          "droite_pct": round(pct(droite), 2),
                          "aire_totale": round(aire_tot, 4),
                          "aire_fine_pct": round(
                              100.0 * aire_fine / aire_tot, 4) if aire_tot else 0.0,
                          "arete_min": min(
                              [r["arete_min"] for r in retenus], default=0.0)},
                         ensure_ascii=False, indent=2))
    else:
        print("%-24s %4s %5s %6s %8s %8s %8s %8s %9s %9s %8s" %
              ("mesh", "prim", "comp", "tris", "LIANT", "hexa", "equi",
               "droite", "aire_med", "arete_min", "fine%"))
        for r in res:
            marque = "*" if (a.mesh is not None and r["mesh"] in a.mesh) else " "
            print("%s%-23s %4d %5d %6d %7.1f%% %7.1f%% %7.1f%% %7.1f%% %9.5f %9.6f %7.3f%%" % (
                marque, r["mesh"], r["primitives"], r["composantes"], r["triangles"],
                100.0 * r["tris_liant"] / r["triangles"],
                100.0 * r["tris_hexa"] / r["triangles"],
                100.0 * r["tris_equidistance"] / r["triangles"],
                100.0 * r["tris_droite"] / r["triangles"],
                r["aire_mediane_composante"], r["arete_min"], r["aire_fine_pct"]))
        etendue = "MESHES RETENUS" if a.mesh else "TOTAL"
        # LA LIGNE TOTALE AGRÈGE TOUT CE SUR QUOI UN PLANCHER PORTE.
        # Constat de l'audit : `arete_min` et l'aire fine n'étaient pas totalisés,
        # donc un plancher posé dessus portait sur une grandeur que l'instrument
        # n'exposait jamais globalement.
        print("%-24s %4s %5s %6d %7.1f%% %7.1f%% %7.1f%% %7.1f%% %9s %9.6f %7.3f%%" % (
            etendue, "", "", tri, part, pct(hexa), pct(equi), pct(droite), "",
            min([r["arete_min"] for r in retenus], default=0.0),
            (100.0 * aire_fine / aire_tot) if aire_tot else 0.0))
    if a.plafond is not None:
        if part > a.plafond:
            sys.stderr.write("ECHEC : liant %.1f%% > plafond %.1f%%\n"
                             % (part, a.plafond))
            return 1
        sys.stderr.write("OK : liant %.1f%% <= plafond %.1f%%\n" % (part, a.plafond))
    return 0


if __name__ == "__main__":
    sys.exit(main())
