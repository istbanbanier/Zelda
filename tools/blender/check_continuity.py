"""Contrôle de CONTINUITÉ d'un modèle (ISS-019).

Le défaut d'ISS-018 — une créature qui se lit en pièces détachées — est
invisible aux tests de géométrie : la boîte englobante d'un maillage skinné
reste juste pendant que les morceaux flottent. Ce script mesure la seule
chose qui compte : **chaque morceau touche-t-il au moins un autre morceau ?**

Méthode :
  1. importer le `.glb` LIVRÉ (pas la source), donc ce que le moteur reçoit ;
  2. ÉVALUER le graphe de dépendances — la géométrie est lue APRÈS
     déformation par l'armature, pas en pose de liaison ;
  3. RESSOUDER les sommets coïncidents. Sans cette étape le test ne mesure
     rien : l'export glTF sépare les sommets par normale et par UV, si bien
     qu'une simple boîte arrive découpée en six faces indépendantes. La
     première version de ce script comptait 1520 « îlots » sur le Gardien et
     ne voyait évidemment aucun défaut, puisque les faces d'une même boîte se
     touchent entre elles ;
  4. découper en morceaux connexes réels ;
  5. pour chaque morceau, chercher un voisin qui l'interpénètre ou dont la
     surface passe à moins de `--gap` mètres ;
  6. échouer en listant les morceaux orphelins, leur taille, leur position et
     la distance qui les sépare du reste du corps.

Un morceau orphelin est une pièce qui flotte. Le script sort en code 1 s'il
en reste, ce qui le rend utilisable en porte de validation.

Usage :
    blender --background --python tools/blender/check_continuity.py -- \\
        --glb assets/characters/creatures/SK_RavineTroll.glb [--gap 0.02]
"""

import os
import sys

import bmesh
import bpy
import numpy
from mathutils import Vector


def parse_args(argv: list) -> dict:
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    args = {"glb": "", "gap": 0.02, "label": "", "weld": 0.0005, "report": 0}
    i = 0
    while i < len(argv):
        if argv[i] == "--glb":
            args["glb"] = argv[i + 1]
            i += 2
        elif argv[i] == "--gap":
            args["gap"] = float(argv[i + 1])
            i += 2
        elif argv[i] == "--weld":
            args["weld"] = float(argv[i + 1])
            i += 2
        elif argv[i] == "--label":
            args["label"] = argv[i + 1]
            i += 2
        elif argv[i] == "--report":
            args["report"] = int(argv[i + 1])
            i += 2
        else:
            i += 1
    return args


def log(message: str) -> None:
    print("[continuité] %s" % message)


def islands_of(obj, depsgraph, weld: float) -> list:
    """Morceaux connexes du maillage ÉVALUÉ, en coordonnées monde.

    `evaluated_get` applique le modificateur d'armature : on lit donc la pose
    réellement rendue. `remove_doubles` annule la séparation de sommets
    introduite par l'export glTF, sans quoi chaque face serait un morceau.
    """
    evaluated = obj.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=weld)
    bm.verts.ensure_lookup_table()
    matrix = evaluated.matrix_world

    seen = set()
    found = []
    for start in bm.verts:
        if start.index in seen:
            continue
        stack = [start]
        seen.add(start.index)
        points = []
        while stack:
            vert = stack.pop()
            points.append(matrix @ vert.co)
            for edge in vert.link_edges:
                other = edge.other_vert(vert)
                if other.index not in seen:
                    seen.add(other.index)
                    stack.append(other)
        cloud = numpy.array([[p.x, p.y, p.z] for p in points], dtype=float)
        found.append({
            "object": obj.name,
            "points": cloud,
            "min": cloud.min(axis=0),
            "max": cloud.max(axis=0),
        })
    bm.free()
    evaluated.to_mesh_clear()
    return found


def penetration(a: dict, b: dict) -> float:
    """Profondeur d'interpénétration des boîtes englobantes.

    Positive quand les deux volumes se chevauchent réellement sur les trois
    axes — c'est le cas d'un membre planté dans un torse.
    """
    low = numpy.maximum(a["min"], b["min"])
    high = numpy.minimum(a["max"], b["max"])
    return float((high - low).min())


def points_to_box(points, low, high) -> float:
    """Distance minimale d'un nuage de points à une boîte."""
    delta = numpy.maximum(low - points, points - high)
    delta = numpy.maximum(delta, 0.0)
    return float(numpy.sqrt((delta * delta).sum(axis=1)).min())


def surface_gap(a: dict, b: dict) -> float:
    """Écart entre les SURFACES de deux morceaux.

    Mesuré des sommets de l'un vers la boîte de l'autre, dans les deux sens.
    La distance sommet à sommet, essayée d'abord, mentait : deux boîtes qui
    se recouvrent franchement mais tournées de 19° l'une par rapport à
    l'autre n'ont aucun sommet commun, et l'anneau du Gardien ressortait
    « détaché » alors que ses maillons s'enfilaient correctement.
    """
    return min(points_to_box(a["points"], b["min"], b["max"]),
               points_to_box(b["points"], a["min"], a["max"]))


def box_gap(a: dict, b: dict) -> float:
    """Écart entre boîtes englobantes — minorant bon marché du vrai écart."""
    delta = numpy.maximum(a["min"] - b["max"], b["min"] - a["max"])
    delta = numpy.maximum(delta, 0.0)
    return float(numpy.sqrt((delta * delta).sum()))


def neighbours_of(index: int, islands: list, gap: float) -> tuple:
    """(distance au plus proche, indices de TOUS les voisins soudés).

    Une interpénétration compte comme une distance nulle : la pièce est
    plantée dans la masse.
    """
    me = islands[index]
    best = 1e9
    joined = []
    order = sorted(
        ((box_gap(me, islands[j]), j)
         for j in range(len(islands)) if j != index),
        key=lambda entry: entry[0],
    )
    for cheap, j in order:
        # `box_gap` minore l'écart réel : au-delà de `best` ET de `gap`, plus
        # aucun candidat ne peut ni raccourcir la distance ni être voisin.
        if cheap >= best and cheap > gap:
            break
        if penetration(me, islands[j]) > 0.0:
            best = 0.0
            joined.append(j)
            continue
        distance = surface_gap(me, islands[j])
        best = min(best, distance)
        if distance <= gap:
            joined.append(j)
    return best, joined


def components(islands: list, links: list) -> list:
    """Groupes de morceaux réellement solidaires.

    Le critère « chaque pièce a un voisin » ne suffit pas : deux grappes
    séparées le satisfont alors que la créature se lit en deux blocs. On
    exige donc UN SEUL groupe.
    """
    seen = [False] * len(islands)
    groups = []
    for start in range(len(islands)):
        if seen[start]:
            continue
        stack = [start]
        seen[start] = True
        group = []
        while stack:
            node = stack.pop()
            group.append(node)
            for other in links[node]:
                if not seen[other]:
                    seen[other] = True
                    stack.append(other)
        groups.append(group)
    return groups


def main() -> None:
    args = parse_args(sys.argv)
    if not args["glb"]:
        log("ÉCHEC : --glb manquant")
        sys.exit(2)
    path = os.path.abspath(args["glb"])
    if not os.path.exists(path):
        log("ÉCHEC : fichier absent — %s" % path)
        sys.exit(2)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    depsgraph = bpy.context.evaluated_depsgraph_get()

    # L'importateur glTF ajoute une icosphère d'affichage pour les os. Elle
    # n'est PAS exportée — on l'écarte par son rôle, pas par son nom.
    helpers = set()
    for obj in bpy.data.objects:
        if obj.type != "ARMATURE":
            continue
        for bone in obj.pose.bones:
            if bone.custom_shape is not None:
                helpers.add(bone.custom_shape.name)

    islands = []
    for obj in bpy.data.objects:
        if obj.type != "MESH" or obj.name in helpers:
            continue
        islands.extend(islands_of(obj, depsgraph, args["weld"]))

    label = args["label"] or os.path.basename(path)
    log("%s : %d morceau(x) après ressoudure" % (label, len(islands)))

    measured = []
    links = []
    for i in range(len(islands)):
        distance, joined = neighbours_of(i, islands, args["gap"])
        measured.append((distance, i))
        links.append(joined)

    orphans = [entry for entry in measured if entry[0] > args["gap"]]
    groups = components(islands, links)
    measured.sort(key=lambda entry: -entry[0])

    if args["report"]:
        log("%s : les %d écarts les plus grands" % (label, args["report"]))
        for distance, i in measured[:args["report"]]:
            centre = (islands[i]["max"] + islands[i]["min"]) * 0.5
            log("   %-20s écart=%.3f m  centre=(%+.2f, %+.2f, %+.2f)"
                % (islands[i]["object"], distance,
                   centre[0], centre[1], centre[2]))

    if not orphans and len(groups) == 1:
        log("%s : UN SEUL corps solidaire, %d morceaux, aucun détaché"
            " (écart toléré %.3f m)" % (label, len(islands), args["gap"]))
        sys.exit(0)

    if orphans:
        log("%s : %d PIÈCE(S) DÉTACHÉE(S)" % (label, len(orphans)))
        orphans.sort(key=lambda entry: -entry[0])
        for distance, i in orphans[:40]:
            island = islands[i]
            size = island["max"] - island["min"]
            centre = (island["max"] + island["min"]) * 0.5
            log("   %-20s écart=%.3f m  taille=(%.2f, %.2f, %.2f)"
                "  centre=(%+.2f, %+.2f, %+.2f)"
                % (island["object"], distance, size[0], size[1], size[2],
                   centre[0], centre[1], centre[2]))

    if len(groups) > 1:
        groups.sort(key=len, reverse=True)
        log("%s : %d GRAPPES SÉPARÉES — la créature ne fait pas un seul corps"
            % (label, len(groups)))
        for group in groups[1:11]:
            names = sorted({islands[i]["object"] for i in group})
            low = numpy.minimum.reduce([islands[i]["min"] for i in group])
            high = numpy.maximum.reduce([islands[i]["max"] for i in group])
            centre = (low + high) * 0.5
            log("   grappe de %2d morceau(x) : %-28s centre=(%+.2f, %+.2f, %+.2f)"
                % (len(group), ",".join(names)[:28],
                   centre[0], centre[1], centre[2]))
    sys.exit(1)


if __name__ == "__main__":
    main()
