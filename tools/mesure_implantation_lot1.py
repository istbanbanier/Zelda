#!/usr/bin/env python3
"""Géométrie 2D d'implantation des six sujets du lot 1 (V2.3-B) — HORS MOTEUR.

Ce que cet outil mesure, et pourquoi il n'a pas besoin de Godot : toutes les
grandeurs ci-dessous vivent dans le plan XZ et sortent de données déjà
committées — les polylignes du layout et les littéraux des six caméras gelées.
Aucune n'exige la fonction de hauteur.

  * distance du site à chacune des quatre routes contractuelles ;
  * distance aux trois gués ;
  * distance au cours principal, à l'affluent, au bord du lac ;
  * respect des BANDES CREUSÉES interdites à tout site ;
  * distance à chacune des six caméras gelées, et à son SEGMENT DE VISÉE
    (les 60 % du trajet caméra → cible que `test_world_v2_cameras.gd` exige
    libres).

Ce qu'il ne mesure PAS, et qui exige le moteur : hauteur du terrain, pente,
eau sous le site, végétation gelée. Ces quatre-là sont le travail de
`tools/godot/sonde_implantation_lot1.gd`.

RÈGLE D'ANCRAGE : aucun nombre n'est recopié ici. Les demi-largeurs de
creusement viennent de `world_v2_heightmap.gd`, les caméras de
`world_v2_cameras_builder.gd`, la fraction de visée de
`test_world_v2_cameras.gd`, les seuils de lieu de
`test_world_v2_places_contract.gd`, les sites du layout. Chaque extraction
échoue BRUYAMMENT si son motif est absent — un `re.search` qui rend None ne
doit jamais devenir un défaut silencieux (tools/CLAUDE.md).

Usage :
  python3 tools/mesure_implantation_lot1.py            # tableau lisible
  python3 tools/mesure_implantation_lot1.py --json     # document JSON
"""

from __future__ import annotations

import json
import math
import re
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parents[1]

LAYOUT = RACINE / "resources/world_v2/world_v2_layout.json"
HEIGHTMAP = RACINE / "scripts/world_v2/world_v2_heightmap.gd"
CAMERAS = RACINE / "scripts/world_v2/world_v2_cameras_builder.gd"
TEST_CAMERAS = RACINE / "tests/world_v2/test_world_v2_cameras.gd"
TEST_PLACES = RACINE / "tests/world_v2/test_world_v2_places_contract.gd"

SUJETS = [
    "valley.poi.watchtower_ruin.01",
    "valley.poi.overlook_summit.01",
    "valley.poi.turquoise_spring.01",
    "valley.poi.forest_shrine.01",
    "valley.poi.barrow_cemetery.01",
    "valley.poi.flower_field.01",
]

ROUTES = ["main_path", "river_route", "heights_route", "ruins_route"]


class Absent(Exception):
    """Un motif attendu n'est pas dans la source : on s'arrête, on ne devine pas."""


def const_float(source: Path, nom: str) -> float:
    texte = source.read_text(encoding="utf-8")
    m = re.search(r"^const %s: float = ([-0-9.]+)" % re.escape(nom), texte, re.M)
    if m is None:
        raise Absent("%s : constante %s introuvable" % (source.name, nom))
    return float(m.group(1))


def const_float_dans_bloc(source: Path, nom: str) -> float:
    """Comme `const_float`, mais tolère une indentation (constante de classe)."""
    texte = source.read_text(encoding="utf-8")
    m = re.search(r"^\s*const %s: float = ([-0-9.]+)" % re.escape(nom), texte, re.M)
    if m is None:
        raise Absent("%s : constante %s introuvable" % (source.name, nom))
    return float(m.group(1))


def fenetres_camera() -> list[dict]:
    """Les six caméras gelées, LUES dans le bâtisseur — jamais retapées."""
    texte = CAMERAS.read_text(encoding="utf-8")
    bloc = re.search(r"^const WINDOWS: Array\[Array\] = \[\n(.*?)^\]", texte, re.M | re.S)
    if bloc is None:
        raise Absent("world_v2_cameras_builder.gd : bloc WINDOWS introuvable")
    motif = re.compile(
        r'\["(?P<nom>[a-z0-9_]+)",\s*(?P<x>[-0-9.]+),\s*(?P<z>[-0-9.]+),\s*'
        r"Vector3\((?P<tx>[-0-9.]+),\s*(?P<ty>[-0-9.]+),\s*(?P<tz>[-0-9.]+)\)"
    )
    fenetres = [
        {
            "nom": m.group("nom"),
            "xz": (float(m.group("x")), float(m.group("z"))),
            "cible": (float(m.group("tx")), float(m.group("ty")), float(m.group("tz"))),
        }
        for m in motif.finditer(bloc.group(1))
    ]
    if len(fenetres) != 6:
        raise Absent("WINDOWS : %d fenêtre(s) extraite(s), 6 attendues" % len(fenetres))
    return fenetres


def dist_point_segment(p, a, b) -> float:
    ax, az = a
    bx, bz = b
    px, pz = p
    dx, dz = bx - ax, bz - az
    long2 = dx * dx + dz * dz
    t = 0.0 if long2 == 0.0 else max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / long2))
    cx, cz = ax + dx * t, az + dz * t
    return math.hypot(px - cx, pz - cz)


def _court(poi_id: str) -> str:
    return poi_id.replace("valley.poi.", "").replace(".01", "")


def entites_du_layout(layout: dict) -> list[tuple[str, tuple[float, float]]]:
    """Tout ce que le layout POSE au sol et qu'un lieu ne doit pas recouvrir."""
    out: list[tuple[str, tuple[float, float]]] = []
    for poi in layout.get("pois", []):
        site = poi.get("v2_site")
        if site:
            out.append((str(poi["id"]), (float(site[0]), float(site[2]))))
    for site_entry in layout.get("systemic_sites", []):
        site = site_entry.get("v2_site")
        if site:
            out.append((str(site_entry["id"]), (float(site[0]), float(site[2]))))
    for cp in layout.get("checkpoints", []):
        pos = cp.get("pos")
        if pos:
            out.append(("checkpoint." + str(cp.get("id", "?")),
                        (float(pos[0]), float(pos[2]))))
    for cle in ("spawn", "camp", "pylon", "dungeon_gate"):
        pos = layout.get("spec_anchors", {}).get(cle)
        if pos:
            out.append(("anchor." + cle, (float(pos[0]), float(pos[2]))))
    if not out:
        raise Absent("layout : aucune entité posée au sol")
    return out


## Les neuf lieux du LOT PILOTE, déjà bâtis et gelés : leurs colliders existent
## dans le monde monté. La liste est LUE dans le registre du bâtisseur, jamais
## recopiée — le jour où le lot 1 s'y ajoute, elle grandit toute seule.
def lieux_batis() -> list[str]:
    texte = (RACINE / "scripts/world_v2/poi/world_v2_places_builder.gd").read_text(
        encoding="utf-8")
    bloc = re.search(r"^const REGISTRY: Dictionary = \{\n(.*?)^\}", texte, re.M | re.S)
    if bloc is None:
        raise Absent("world_v2_places_builder.gd : bloc REGISTRY introuvable")
    ids = re.findall(r'&"([^"]+)":', bloc.group(1))
    if not ids:
        raise Absent("REGISTRY : aucun identifiant extrait")
    return ids


def dist_polyligne(p, points) -> tuple[float, int]:
    """Distance minimale et indice du segment le plus proche."""
    if len(points) < 2:
        raise Absent("polyligne de moins de deux points")
    meilleure, indice = float("inf"), -1
    for i in range(len(points) - 1):
        d = dist_point_segment(p, points[i], points[i + 1])
        if d < meilleure:
            meilleure, indice = d, i
    return meilleure, indice


def main() -> int:
    layout = json.loads(LAYOUT.read_text(encoding="utf-8"))

    # --- seuils, lus à la source ---------------------------------------------
    seuils = {
        "RIVER_BED_HALF_W": const_float(HEIGHTMAP, "RIVER_BED_HALF_W"),
        "RIVER_BANK_W": const_float(HEIGHTMAP, "RIVER_BANK_W"),
        "TRIB_BED_HALF_W": const_float(HEIGHTMAP, "TRIB_BED_HALF_W"),
        "TRIB_BANK_W": const_float(HEIGHTMAP, "TRIB_BANK_W"),
        "LAKE_SHORE_W": const_float(HEIGHTMAP, "LAKE_SHORE_W"),
        "FORD_INFLUENCE_M": const_float(HEIGHTMAP, "FORD_INFLUENCE_M"),
        "ROUTE_CLEAR_M": const_float_dans_bloc(TEST_PLACES, "ROUTE_CLEAR_M"),
        "SITE_XZ_TOLERANCE_M": const_float_dans_bloc(TEST_PLACES, "SITE_XZ_TOLERANCE_M"),
        "ROOT_GROUND_TOLERANCE_M": const_float_dans_bloc(
            TEST_PLACES, "ROOT_GROUND_TOLERANCE_M"),
        "SUPPORT_TOLERANCE_M": const_float_dans_bloc(TEST_PLACES, "SUPPORT_TOLERANCE_M"),
        "CLEAR_SIGHT_FRACTION": const_float_dans_bloc(TEST_CAMERAS, "CLEAR_SIGHT_FRACTION"),
        "EYE_HEIGHT": const_float(CAMERAS, "EYE_HEIGHT"),
    }
    bande_principale = seuils["RIVER_BED_HALF_W"] + seuils["RIVER_BANK_W"]
    bande_affluent = seuils["TRIB_BED_HALF_W"] + seuils["TRIB_BANK_W"]
    # Le lac : rayon du layout + 2 m de dégagement exigés par le contrat du lot.
    lac = layout["river"]["mouth"]
    lac_centre = (float(lac["center_xz"][0]), float(lac["center_xz"][1]))
    lac_rayon = float(lac["radius_m"])
    degagement_lac = 2.0

    principal = [(float(a), float(b)) for a, b in layout["river"]["main_course_xz"]]
    affluent = [(float(a), float(b)) for a, b in layout["river"]["west_tributary_xz"]]
    gues = [
        (str(g["id"]), (float(g["pos_xz"][0]), float(g["pos_xz"][1])))
        for g in layout["river"]["fords"]
    ]
    routes = {}
    for nom in ROUTES:
        pts = layout["routes"][nom]["waypoints_xz"]
        routes[nom] = [(float(a), float(b)) for a, b in pts]

    fenetres = fenetres_camera()
    fraction = seuils["CLEAR_SIGHT_FRACTION"]

    entites = entites_du_layout(layout)
    registre = lieux_batis()

    sites = {}
    for poi in layout["pois"]:
        if poi["id"] in SUJETS:
            sites[poi["id"]] = [float(v) for v in poi["v2_site"]]
    manquants = [s for s in SUJETS if s not in sites]
    if manquants:
        raise Absent("sites absents du layout : %s" % ", ".join(manquants))

    doc = {
        "source": "tools/mesure_implantation_lot1.py",
        "portee": "géométrie XZ seule — hauteurs, pentes, eau et végétation exigent le moteur",
        "seuils": seuils,
        "bandes_creusees_interdites_m": {
            "cours_principal": bande_principale,
            "affluent": bande_affluent,
            "lac": lac_rayon + degagement_lac,
        },
        "sujets": {},
    }

    for pid in SUJETS:
        x, y, z = sites[pid]
        p = (x, z)
        par_route = {}
        for nom, pts in routes.items():
            d, i = dist_polyligne(p, pts)
            par_route[nom] = {"distance_m": round(d, 2), "segment": i}
        route_proche = min(par_route.items(), key=lambda kv: kv[1]["distance_m"])

        d_principal, seg_principal = dist_polyligne(p, principal)
        d_affluent, seg_affluent = dist_polyligne(p, affluent)
        d_lac_centre = math.hypot(x - lac_centre[0], z - lac_centre[1])

        par_gue = {gid: round(math.hypot(x - gx, z - gz), 2) for gid, (gx, gz) in gues}
        gue_proche = min(par_gue.items(), key=lambda kv: kv[1])

        par_camera = {}
        for f in fenetres:
            cx, cz = f["xz"]
            tx, _ty, tz = f["cible"]
            fin = (cx + (tx - cx) * fraction, cz + (tz - cz) * fraction)
            par_camera[f["nom"]] = {
                "distance_camera_m": round(math.hypot(x - cx, z - cz), 2),
                "distance_segment_vise_m": round(dist_point_segment(p, (cx, cz), fin), 2),
                "fin_segment_xz": [round(fin[0], 1), round(fin[1], 1)],
            }
        camera_proche = min(
            par_camera.items(), key=lambda kv: kv[1]["distance_segment_vise_m"]
        )

        voisins = [(nom, math.hypot(x - vx, z - vz))
                   for nom, (vx, vz) in entites if nom != pid]
        voisin = min(voisins, key=lambda kv: kv[1])
        batis = [(nom, d) for nom, d in voisins
                 if nom in registre or "anchor." + nom in registre
                 or nom in ("checkpoint.camp",) or nom == "anchor.pylon"]
        bati = min(batis, key=lambda kv: kv[1]) if batis else ("(aucun)", float("inf"))

        doc["sujets"][pid] = {
            "v2_site": [x, y, z],
            "routes": par_route,
            "route_la_plus_proche": [route_proche[0], route_proche[1]["distance_m"]],
            "marge_route_m": round(route_proche[1]["distance_m"] - seuils["ROUTE_CLEAR_M"], 2),
            "gues": par_gue,
            "gue_le_plus_proche": [gue_proche[0], gue_proche[1]],
            "sous_influence_de_gue": gue_proche[1] < seuils["FORD_INFLUENCE_M"],
            "cours_principal": {
                "distance_m": round(d_principal, 2),
                "segment": seg_principal,
                "bande_interdite_m": bande_principale,
                "marge_m": round(d_principal - bande_principale, 2),
            },
            "affluent": {
                "distance_m": round(d_affluent, 2),
                "segment": seg_affluent,
                "bande_interdite_m": bande_affluent,
                "marge_m": round(d_affluent - bande_affluent, 2),
            },
            "lac": {
                "distance_au_centre_m": round(d_lac_centre, 2),
                "bande_interdite_m": lac_rayon + degagement_lac,
                "marge_m": round(d_lac_centre - (lac_rayon + degagement_lac), 2),
            },
            "cameras": par_camera,
            "voisin_le_plus_proche": [voisin[0], round(voisin[1], 2)],
            "lieu_bati_le_plus_proche": [bati[0], round(bati[1], 2)],
            "camera_la_plus_proche_en_visee": [
                camera_proche[0],
                camera_proche[1]["distance_segment_vise_m"],
            ],
        }

    if "--json" in sys.argv:
        print(json.dumps(doc, ensure_ascii=False, indent=2))
        return 0

    print("=== IMPLANTATION LOT 1 — GÉOMÉTRIE XZ (hors moteur) ===")
    print("bandes creusées interdites : cours %.1f m · affluent %.1f m · lac %.1f m"
          % (bande_principale, bande_affluent, lac_rayon + degagement_lac))
    print("seuil de route pour un LIEU : %.1f m (test_world_v2_places_contract.gd)"
          % seuils["ROUTE_CLEAR_M"])
    print("visée libre exigée : %.0f %% du trajet caméra → cible" % (fraction * 100.0))
    print()
    entete = "%-34s %7s %-16s %8s %8s %8s %8s %-22s %7s"
    print(entete % ("sujet", "route", "(laquelle)", "gué", "cours", "affl.",
                    "lac-c", "caméra la + proche", "d.visée"))
    for pid in SUJETS:
        s = doc["sujets"][pid]
        print(entete % (
            pid.replace("valley.poi.", "").replace(".01", ""),
            "%.1f" % s["route_la_plus_proche"][1],
            s["route_la_plus_proche"][0],
            "%.1f" % s["gue_le_plus_proche"][1],
            "%.1f" % s["cours_principal"]["distance_m"],
            "%.1f" % s["affluent"]["distance_m"],
            "%.1f" % s["lac"]["distance_au_centre_m"],
            s["camera_la_plus_proche_en_visee"][0],
            "%.1f" % s["camera_la_plus_proche_en_visee"][1],
        ))
    print()
    print("--- marges (positif = dégagé) ---")
    for pid in SUJETS:
        s = doc["sujets"][pid]
        print("  %-34s route %+7.2f  cours %+8.2f  affluent %+8.2f  lac %+8.2f"
              % (pid.replace("valley.poi.", "").replace(".01", ""),
                 s["marge_route_m"], s["cours_principal"]["marge_m"],
                 s["affluent"]["marge_m"], s["lac"]["marge_m"]))
    print()
    print("--- distance de CHAQUE site à CHAQUE segment de visée gelé (m) ---")
    noms = [f["nom"] for f in fenetres]
    print("%-20s %s" % ("sujet", " ".join("%14s" % n[:14] for n in noms)))
    for pid in SUJETS:
        s = doc["sujets"][pid]
        print("%-20s %s" % (
            _court(pid),
            " ".join("%14.1f" % s["cameras"][n]["distance_segment_vise_m"] for n in noms),
        ))
    print()
    print("--- voisinage : entité du layout la plus proche (hors le sujet lui-même) ---")
    for pid in SUJETS:
        s = doc["sujets"][pid]
        v = s["voisin_le_plus_proche"]
        b = s["lieu_bati_le_plus_proche"]
        print("  %-20s layout %-34s %7.1f m   |  lieu bâti %-34s %7.1f m"
              % (_court(pid), v[0], v[1], b[0], b[1]))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Absent as erreur:
        print("BLOQUÉ : %s" % erreur, file=sys.stderr)
        sys.exit(3)
