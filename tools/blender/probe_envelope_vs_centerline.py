# SONDE DE COMPATIBILITÉ — enveloppe extérieure contre centerline de galerie.
#
# POURQUOI ELLE EXISTE. La fusion R2a-3.5 remplace deux choses à la fois :
# la silhouette (prototype A) et le tracé de la galerie (centerline de
# l'agent galerie). Chacune a été validée SÉPARÉMENT. Rien ne garantit
# qu'elles tiennent ensemble, et trois passes de cette grotte ont déjà été
# perdues parce qu'un défaut d'assemblage n'a été vu qu'après le rendu.
#
# La question posée est étroite et se répond sans rien construire : en
# chaque station de la centerline, l'enveloppe passe-t-elle assez haut, et
# assez loin latéralement, pour que la cavité tienne dedans ?
#
# CE QU'ELLE MESURE, par station :
#   * `z_som`    — altitude du SOMMET de l'enveloppe dans la colonne de la
#                  station, obtenue par rayon DESCENDANT depuis z = +50.
#   * `toit`     — z_som moins la clé : hauteur de roche au-dessus de la
#                  galerie. C'est la mesure qui décide, et non la distance
#                  au sol : une galerie sous une enveloppe basse fait de la
#                  gaine la crête (constat de l'agent galerie).
#
#                  LE RAYON DESCEND, ET C'EST UNE CORRECTION. Première
#                  version : rayon MONTANT depuis la clé. Sur un solide
#                  plein il rend la bonne valeur, mais sur la grotte
#                  ACTUELLE — qui est creuse — la clé est dans la poche
#                  d'air, le rayon traverse d'abord le plafond, et « toit »
#                  mesurait alors l'épaisseur de la voûte, pas la roche
#                  au-dessus. Le témoin l'a montré : 0,26 à 2,40 m là où
#                  l'agent galerie annonce 2,06 à 3,77. Deux mesures qui ne
#                  coïncident pas aux bornes : l'écart ÉTAIT le sujet.
#                  Un rayon descendant depuis le ciel ne peut pas se
#                  tromper de surface, creux ou plein.
#   * `lat_g` / `lat_d` — roche restante de part et d'autre, à mi-hauteur,
#                  après retrait de la demi-largeur.
#   * `dedans`   — la station est-elle seulement à l'intérieur du solide ?
#                  Une station HORS de l'enveloppe ne donne pas une paroi
#                  mince : elle donne un trou.
#
# MÉTHODE. Lancer de rayons sur un BVH construit depuis le maillage réel
# exporté, pas depuis les paramètres du générateur : c'est le fichier livré
# qu'on mesure. Le test « dedans » compte les intersections d'un rayon
# vertical montant — parité impaire = intérieur.
#
# REPÈRE. Blender Z-up, sol à z = 0, bouche à l'origine, galerie vers +y.
# L'importateur glTF reconvertit le GLB Y-up vers Z-up : la sonde retrouve
# donc le repère du générateur. Le contrôle d'emprise en tête de sortie le
# vérifie au lieu de le supposer.
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python tools/blender/probe_envelope_vs_centerline.py -- \
#       --glb assets/environment/caves/prototypes/SM_CaveEnvelope_ProtoA.glb

from __future__ import annotations

import math
import os
import sys

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

# Centerline établie par l'agent galerie : (ax, ay, demi-largeur, clé, palier).
# Recopiée telle quelle ; toute divergence avec le générateur se verra ici.
CENTERLINE = [
    (0.00, -1.15, 1.90, 2.80, 0.00),   # porche
    (0.00, 0.00, 1.70, 2.85, 0.00),    # seuil
    (0.22, 1.05, 1.75, 2.90, 0.02),    # fin du vestibule
    (1.00, 1.62, 2.10, 2.90, 0.06),    # LE COUDE
    (1.82, 2.12, 2.60, 2.92, 0.10),
    (2.62, 2.58, 3.00, 2.92, 0.16),    # SALLE
    (3.10, 2.88, 2.50, 2.80, 0.34),
    (3.40, 3.06, 1.85, 2.45, 0.56),    # alcôve
    (3.58, 3.17, 1.30, 2.00, 0.70),    # calotte du fond
]
APEX = (3.72, 3.25, 0.70)

# TÉMOIN. Centerline et paliers ACTUELS du générateur, recopiés depuis
# `make_waterfall_cave.py` (`CAVITE` + `PALIER`). Ils servent de contrôle
# positif : mesurés contre le GLB actuel, ils doivent rendre les 2,06 à
# 3,77 m de toit annoncés. Une sonde qui échoue sur des données connues ne
# prouve rien sur des données nouvelles — c'est le seul moyen de savoir si
# un « INCOMPATIBLE » vient de la géométrie ou de l'instrument.
TEMOIN = [
    (0.00, -1.15, 1.90, 2.80, 0.00),
    (0.00, 0.00, 1.70, 2.85, 0.00),
    (0.06, 1.60, 1.85, 2.95, 0.04),
    (0.24, 3.20, 2.15, 2.80, 0.10),
    (0.58, 4.75, 2.70, 2.90, 0.16),
    (1.05, 6.25, 3.05, 2.92, 0.26),
    (1.62, 7.60, 2.80, 2.92, 0.50),
    (2.25, 8.65, 2.20, 2.55, 0.78),
    (2.85, 9.25, 1.40, 2.00, 0.92),
]
TEMOIN_APEX = (3.25, 9.55, 0.70)

LOIN = 200.0


def _args() -> dict:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = {"glb": "assets/environment/caves/prototypes/SM_CaveEnvelope_ProtoA.glb",
           "temoin": False}
    for a in argv:
        if a.startswith("--glb="):
            out["glb"] = a[len("--glb="):]
        elif a == "--temoin":
            out["temoin"] = True
    return out


def _charger(chemin: str) -> tuple:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=chemin)
    sommets, faces = [], []
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for ob in list(bpy.context.scene.objects):
        if ob.type != "MESH":
            continue
        me = ob.data
        me.calc_loop_triangles()
        base = len(sommets)
        for v in me.vertices:
            p = ob.matrix_world @ v.co
            sommets.append(p)
            for i in range(3):
                lo[i] = min(lo[i], p[i])
                hi[i] = max(hi[i], p[i])
        for t in me.loop_triangles:
            faces.append(tuple(base + i for i in t.vertices))
    if not faces:
        raise RuntimeError("aucune face importée depuis %s" % chemin)
    return BVHTree.FromPolygons(sommets, faces, all_triangles=True), lo, hi, len(faces)


def _distance(bvh: BVHTree, origine: Vector, direction: Vector) -> float:
    """Distance au premier impact, ou -1 si le rayon sort sans toucher."""
    hit = bvh.ray_cast(origine, direction.normalized(), LOIN)
    return -1.0 if hit[0] is None else (hit[0] - origine).length


def _dedans(bvh: BVHTree, point: Vector) -> bool:
    """Parité des impacts d'un rayon montant : impair = intérieur du solide."""
    n = 0
    o = point.copy()
    for _ in range(64):
        hit = bvh.ray_cast(o, Vector((0.0, 0.0, 1.0)), LOIN)
        if hit[0] is None:
            break
        n += 1
        o = hit[0] + Vector((0.0, 0.0, 1e-4))
    return n % 2 == 1


def main() -> int:
    args = _args()
    lignes = TEMOIN if args["temoin"] else CENTERLINE
    apex = TEMOIN_APEX if args["temoin"] else APEX
    chemin = os.path.abspath(args["glb"])
    bvh, lo, hi, nf = _charger(chemin)
    print("[sonde] %s — %d triangles | centerline : %s"
          % (os.path.basename(chemin), nf,
             "TÉMOIN (actuelle)" if args["temoin"] else "NOUVELLE"))
    print("[sonde] emprise Blender  x %.2f..%.2f  y %.2f..%.2f  z %.2f..%.2f"
          % (lo.x, hi.x, lo.y, hi.y, lo.z, hi.z))
    if hi.z < 4.0 or (hi.x - lo.x) < 8.0:
        print("[sonde] BLOQUÉ : emprise incohérente — repère probablement "
              "converti autrement que Z-up")
        return 3

    # Tangentes par différences centrées, pour la normale latérale.
    pts = [Vector((s[0], s[1], 0.0)) for s in lignes]
    tan = []
    for i in range(len(pts)):
        a = pts[max(0, i - 1)]
        b = pts[min(len(pts) - 1, i + 1)]
        t = Vector((b.x - a.x, b.y - a.y, 0.0))
        tan.append(t.normalized() if t.length > 1e-6 else Vector((0.0, 1.0, 0.0)))

    print("")
    print(" st |    ax    ay |  clé  palier |  z_som |   toit | lat_g  lat_d |"
          " cap")
    print("----+-------------+--------------+--------+--------+--------------+-----")
    verdicts = []
    for i, (ax, ay, hw, cle, palier) in enumerate(lignes):
        couronne = palier + cle
        normale = Vector((-tan[i].y, tan[i].x, 0.0))
        p_haut = Vector((ax, ay, couronne))
        p_mi = Vector((ax, ay, palier + cle * 0.5))

        haut = Vector((ax, ay, 50.0))
        d = _distance(bvh, haut, Vector((0.0, 0.0, -1.0)))
        z_som = None if d < 0 else 50.0 - d
        toit = None if z_som is None else z_som - couronne
        lg = _distance(bvh, p_mi, normale)
        ld = _distance(bvh, p_mi, -normale)
        cap = math.degrees(math.atan2(tan[i].x, tan[i].y))

        verdicts.append((i, z_som, toit, lg - hw, ld - hw))
        print(" %2d | %5.2f %5.2f | %4.2f  %4.2f  | %6s | %6s | %5s %5s | %4.0f°"
              % (i, ax, ay, cle, palier,
                 "AUCUN" if z_som is None else "%.2f" % z_som,
                 "AUCUN" if toit is None else "%+.2f" % toit,
                 "%.2f" % (lg - hw) if lg >= 0 else "AUCUN",
                 "%.2f" % (ld - hw) if ld >= 0 else "AUCUN", cap))

    ax, ay, az = apex
    d = _distance(bvh, Vector((ax, ay, 50.0)), Vector((0.0, 0.0, -1.0)))
    print(" ap | %5.2f %5.2f |  apex de calotte, z = %.2f | z_som %s | toit %s"
          % (ax, ay, az, "AUCUN" if d < 0 else "%.2f" % (50.0 - d),
             "AUCUN" if d < 0 else "%+.2f" % (50.0 - d - az)))

    toits = [v[2] for v in verdicts if v[2] is not None]
    fautes = [v for v in verdicts if v[2] is None or v[2] < 0.60]
    print("")
    print("[sonde] toit : min %+.2f  max %+.2f  m au-dessus de la clé"
          % (min(toits), max(toits)))
    if fautes:
        print("[sonde] INCOMPATIBLE : %d station(s) sous 0,60 m de toit" % len(fautes))
        for i, z_som, toit, mg, md in fautes:
            print("        station %d : z_sommet %s  toit %s  lat_g %+.2f  lat_d %+.2f"
                  % (i, "AUCUN" if z_som is None else "%.2f" % z_som,
                     "AUCUN" if toit is None else "%+.2f" % toit, mg, md))
        return 1
    print("[sonde] toutes les stations ont au moins 0,60 m de toit")
    return 0


if __name__ == "__main__":
    sys.exit(main())
