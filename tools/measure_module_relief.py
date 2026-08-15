#!/usr/bin/env python3
"""Mesure le RELIEF d'un module glTF, pas seulement sa taille.

Pourquoi cet outil. « Rester proche de l'échelle native » suppose de connaître
l'échelle native ; « conserver leur relief réel » suppose de savoir lequel des
modules en a. `gltf_inspect.py` répond à la première question et pas à la
seconde : un mur plat de 4 x 4 m et un rocher sculpté de 4 x 4 m y sont
indiscernables.

Trois mesures, toutes calculées sur les triangles réellement présents :

  facettes_distinctes  nombre de directions de normale séparées de plus de
                       12 deg. Un cube en donne 6. Un bloc sculpte en donne
                       des dizaines. C'est le proxy le plus direct de
                       « surface travaillee ».
  plus_grande_face_pc  part de l'aire totale occupee par la plus grande
                       FAMILLE de normales.
  plage_plane_m2       aire, en metres carres, de la plus grande PLAGE PLANE
                       CONNEXE — triangles voisins par une arete dont les
                       normales tiennent dans 12 deg. C'est la mesure qui
                       compte : c'est litteralement le plus grand pan plat
                       que l'oeil voit. Les deux colonnes precedentes ne le
                       voient PAS. Mesure du 2026-08-15 : le loft polygonal
                       de la grotte affiche 7,5 % et 162 familles — donc
                       « pas de plan dominant » — alors qu'il porte des pans
                       de plusieurs metres carres, et c'est ce que le lead a
                       reproche a l'image. Un pourcentage reparti sur
                       soixante-douze quadrilateres geants reste soixante-
                       douze quadrilateres geants.
  amplitude_relief_m   ecart-type des distances des sommets a la boite
                       englobante, en metres. Dit de combien la surface
                       s'ecarte d'un pave.

ATTENTION, CE QUE CET OUTIL MESURE ET CE QU'IL NE MESURE PAS. Il lit tous
les triangles du fichier : coque de collision, socle enterre, faces
interieures d'une cavite compris. Sur `SM_WaterfallCave.glb` il rend
157,56 m2 de plage plane, et c'est le DESSOUS DU SOCLE ENTERRE, une dalle
de 13 x 12 m que personne ne verra jamais. Le controle equivalent cote
Blender (`controle_plage_plane`) ecarte ce qui est sous le terrain et ce qui
appartient a la cavite, et rend 2,73 m2. Les deux chiffres sont justes ; un
seul repond a la question « voit-on un grand aplat ».

Usage : python3 tools/measure_module_relief.py [--maillage=NOM] <fichier.glb>…
"""

from __future__ import annotations

import json
import math
import struct
import sys
from pathlib import Path

_COMPOSANTES = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2), 5123: ("H", 2),
                5125: ("I", 4), 5126: ("f", 4)}
_ELEMENTS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def _lire_glb(chemin: Path) -> tuple[dict, bytes]:
    donnees = chemin.read_bytes()
    if donnees[:4] == b"glTF":
        _, _, _ = struct.unpack_from("<III", donnees, 0)
        curseur, gltf, binaire = 12, None, b""
        while curseur < len(donnees):
            taille, sorte = struct.unpack_from("<II", donnees, curseur)
            bloc = donnees[curseur + 8:curseur + 8 + taille]
            if sorte == 0x4E4F534A:
                gltf = json.loads(bloc.decode("utf-8"))
            elif sorte == 0x004E4942:
                binaire = bloc
            curseur += 8 + taille + ((4 - taille % 4) % 4)
        if gltf is None:
            raise ValueError("GLB sans bloc JSON")
        return gltf, binaire
    gltf = json.loads(donnees.decode("utf-8"))
    binaire = b""
    for tampon in gltf.get("buffers", []):
        uri = tampon.get("uri", "")
        if uri.startswith("data:"):
            import base64
            binaire += base64.b64decode(uri.split(",", 1)[1])
        elif uri:
            binaire += (chemin.parent / uri).read_bytes()
    return gltf, binaire


def _accesseur(gltf: dict, binaire: bytes, index: int) -> list:
    acc = gltf["accessors"][index]
    fmt, octets = _COMPOSANTES[acc["componentType"]]
    n = _ELEMENTS[acc["type"]]
    vue = gltf["bufferViews"][acc["bufferView"]]
    base = vue.get("byteOffset", 0) + acc.get("byteOffset", 0)
    foulee = vue.get("byteStride", 0) or n * octets
    sortie = []
    for i in range(acc["count"]):
        debut = base + i * foulee
        sortie.append(struct.unpack_from("<" + fmt * n, binaire, debut))
    return sortie


def _triangles(chemin: Path, filtre: str | None = None) -> list:
    gltf, binaire = _lire_glb(chemin)
    faces = []
    for maillage in gltf.get("meshes", []):
        if filtre is not None and filtre not in maillage.get("name", ""):
            continue
        for prim in maillage.get("primitives", []):
            if prim.get("mode", 4) != 4 or "POSITION" not in prim.get("attributes", {}):
                continue
            positions = _accesseur(gltf, binaire, prim["attributes"]["POSITION"])
            if "indices" in prim:
                indices = [v[0] for v in _accesseur(gltf, binaire, prim["indices"])]
            else:
                indices = list(range(len(positions)))
            for i in range(0, len(indices) - 2, 3):
                faces.append((positions[indices[i]], positions[indices[i + 1]],
                              positions[indices[i + 2]]))
    return faces


def _normale_et_aire(t) -> tuple[tuple[float, float, float], float]:
    a, b, c = t
    u = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    v = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    n = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2],
         u[0] * v[1] - u[1] * v[0])
    longueur = math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2)
    if longueur < 1e-12:
        return (0.0, 0.0, 0.0), 0.0
    return (n[0] / longueur, n[1] / longueur, n[2] / longueur), longueur * 0.5


def _plage_plane_max(faces: list, normales: list, aires: list) -> float:
    """Plus grande plage plane connexe, en m^2.

    Deux triangles appartiennent à la même plage s'ils partagent une arête ET
    si leurs normales tiennent dans 12 deg. On regroupe par union-find sur les
    arêtes, ce qui évite de fusionner deux pans parallèles mais séparés.
    """
    arete_vers_faces: dict = {}
    for i, t in enumerate(faces):
        if aires[i] <= 0.0:
            continue
        sommets = [tuple(round(c, 5) for c in s) for s in t]
        for k in range(3):
            a, b = sommets[k], sommets[(k + 1) % 3]
            cle = (a, b) if a <= b else (b, a)
            arete_vers_faces.setdefault(cle, []).append(i)

    parent = list(range(len(faces)))

    def racine(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    cos_seuil = math.cos(math.radians(12.0))
    for voisins in arete_vers_faces.values():
        for i in range(len(voisins)):
            for j in range(i + 1, len(voisins)):
                a, b = voisins[i], voisins[j]
                na, nb = normales[a], normales[b]
                if na[0] * nb[0] + na[1] * nb[1] + na[2] * nb[2] < cos_seuil:
                    continue
                ra, rb = racine(a), racine(b)
                if ra != rb:
                    parent[ra] = rb

    cumul: dict = {}
    for i in range(len(faces)):
        if aires[i] <= 0.0:
            continue
        r = racine(i)
        cumul[r] = cumul.get(r, 0.0) + aires[i]
    return max(cumul.values(), default=0.0)


def mesurer(chemin: Path, filtre: str | None = None) -> dict:
    faces = _triangles(chemin, filtre)
    if not faces:
        return {"fichier": chemin.name, "erreur": "aucun triangle"}

    familles: list[list] = []          # [normale, aire cumulée]
    aire_totale = 0.0
    cos_seuil = math.cos(math.radians(12.0))
    normales: list = []
    aires: list = []
    for t in faces:
        n, aire = _normale_et_aire(t)
        normales.append(n)
        aires.append(aire)
        if aire <= 0.0:
            continue
        aire_totale += aire
        for f in familles:
            m = f[0]
            if n[0] * m[0] + n[1] * m[1] + n[2] * m[2] >= cos_seuil:
                f[1] += aire
                break
        else:
            familles.append([n, aire])

    sommets = {s for t in faces for s in t}
    xs = [s[0] for s in sommets]
    ys = [s[1] for s in sommets]
    zs = [s[2] for s in sommets]
    taille = (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
    centre = ((max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2,
              (max(zs) + min(zs)) / 2)
    demi = (taille[0] / 2 or 1e-6, taille[1] / 2 or 1e-6, taille[2] / 2 or 1e-6)
    # Distance normalisée à la boîte : 1.0 = sur la boîte, < 1 = en retrait.
    ecarts = []
    for s in sommets:
        r = max(abs(s[0] - centre[0]) / demi[0], abs(s[1] - centre[1]) / demi[1],
                abs(s[2] - centre[2]) / demi[2])
        ecarts.append(r)
    moyenne = sum(ecarts) / len(ecarts)
    variance = sum((e - moyenne) ** 2 for e in ecarts) / len(ecarts)
    portee = min(demi)

    plus_grande = max((f[1] for f in familles), default=0.0)
    return {
        "fichier": chemin.name + ("" if filtre is None else "#" + filtre),
        "triangles": len(faces),
        "dimensions_m": [round(v, 3) for v in taille],
        "facettes_distinctes": len(familles),
        "plus_grande_face_pc": round(100.0 * plus_grande / aire_totale, 1)
        if aire_totale else 0.0,
        "plage_plane_m2": round(_plage_plane_max(faces, normales, aires), 2),
        "amplitude_relief_m": round(math.sqrt(variance) * portee, 3),
    }


def main() -> int:
    # `--maillage=NOM` restreint la mesure aux maillages dont le nom contient
    # NOM. Sans lui, un fichier qui embarque sa COQUE DE COLLISION rend le
    # chiffre de la collision : mesuré sur SM_WaterfallCave.glb, 157,56 m2
    # de plage plane pour le collider (un loft, jamais rendu) contre 2,73
    # pour le maillage visible. Le nombre était juste et la conclusion
    # fausse.
    filtre = None
    args = []
    for a in sys.argv[1:]:
        if a.startswith("--maillage="):
            filtre = a.split("=", 1)[1]
        else:
            args.append(a)
    chemins = [Path(a) for a in args]
    if not chemins:
        print(__doc__)
        return 2
    print("%-34s %6s %-22s %6s %8s %10s %9s" % (
        "fichier", "tri", "dimensions_m", "facet", "plusgd%", "plage_m2",
        "relief_m"))
    for c in chemins:
        m = mesurer(c, filtre)
        if "erreur" in m:
            print("%-34s  %s" % (m["fichier"], m["erreur"]))
            continue
        print("%-34s %6d %-22s %6d %8.1f %10.2f %9.3f" % (
            m["fichier"], m["triangles"], str(m["dimensions_m"]),
            m["facettes_distinctes"], m["plus_grande_face_pc"],
            m["plage_plane_m2"], m["amplitude_relief_m"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
