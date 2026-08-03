"""Phase H — GARDIEN DE L'ORAGE, hero asset original du boss final.

Création ORIGINALE du projet, procédurale et reproductible (seed fixe).
Aucune silhouette empruntée : la bête-machine de VISUAL_ASSET_BIBLE §15.1
est construite ici depuis des primitives, os par os.

Ce que la bible impose et que ce script tient :
  - six appuis : quatre pattes locomotrices BASSES + deux membres
    antérieurs plus massifs, capables de frapper ;
  - masse centrale de pierre au dos VOÛTÉ, sans espèce réelle citable ;
  - tête courte protégée par TROIS plaques de céramique ;
  - épaules de bronze ;
  - queue-conducteur SEGMENTÉE terminée par une fourche de mise à la terre ;
  - anneau vertical INCOMPLET au-dessus du dos, en trois segments ;
  - noyau circulaire FENDU au sternum ;
  - 8 à 10 m de long, 5,2 à 6 m de haut anneau fermé, 5 à 7 m de large.

Découpage en objets nommés, parce que le gameplay en dépend (§16.4, §16.5) :
`Core`, `CrystalA`, `CrystalB`, les plaques d'armure détachables, les trois
segments d'anneau et les segments de queue sont des meshes SÉPARÉS — la
phase 2 les révèle, la phase 3 les fait pendre, et rien de tout cela ne
peut se faire depuis une masse unique.

Rig : squelette minimal orienté gameplay (racine, colonne, tête, six
membres, queue). Il porte le poids et les appuis ; les clips d'animation
viennent au lot suivant.

Usage :
    blender --background --python tools/blender/make_storm_guardian.py
Sorties :
    source_assets/blender/creatures/SK_StormGuardian.blend
    source_assets/blender/creatures/textures/T_Guardian_{BaseColor,MR}.png
"""

import math
import os

import bmesh
import bpy
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC_DIR = os.path.join(ROOT, "source_assets", "blender", "creatures")
TEX_DIR = os.path.join(SRC_DIR, "textures")

SEED = 20260803
TEX_SIZE = 1024

# --- Cotes, en mètres. Bible §15.1 : long 8-10, haut 5,2-6, large 5-7.
BODY_LEN = 5.0          # masse centrale seule ; tête et queue portent le reste
BODY_W = 4.75          # élargi : la fermeture des articulations avait ramené la bête à 4,89 m, sous la bande 5-7 de §15.1
BODY_H = 2.2
BODY_Z = 2.35           # hauteur du centre de la masse au-dessus du sol
HEAD_LEN = 1.5
TAIL_SEGMENTS = 5
RING_RADIUS = 1.85
RING_Z = 3.40           # centre de l'anneau : abaissé pour qu'il TRAVERSE le dos
LEG_FRONT_Z = 2.05      # attache des membres antérieurs
LEG_REAR_Z = 1.75

# Palette de la bible §1.4 — aucune valeur inventée ici.
COL_STONE = (0.235, 0.166, 0.108, 1.0)     # roche ocre sombre
COL_STONE_LIT = (0.404, 0.279, 0.176, 1.0)
COL_BRONZE = (0.302, 0.192, 0.098, 1.0)
COL_COPPER = (0.478, 0.263, 0.129, 1.0)
COL_IVORY = (0.729, 0.639, 0.435, 1.0)
COL_CABLE = (0.086, 0.180, 0.220, 1.0)     # bleu pétrole, NON émissif au repos
COL_CYAN = (0.055, 0.694, 0.831, 1.0)
COL_CORE = (0.902, 1.0, 1.0, 1.0)

# Régions de l'atlas UV (u0, v0, u1, v1). Les textures sont peintes sur ces
# MÊMES rectangles : la correspondance est structurelle, pas espérée.
UV_STONE = (0.010, 0.010, 0.490, 0.640)
UV_BRONZE = (0.510, 0.010, 0.740, 0.400)
UV_IVORY = (0.760, 0.010, 0.990, 0.400)
UV_CABLE = (0.510, 0.420, 0.740, 0.640)
UV_CYAN = (0.760, 0.420, 0.990, 0.640)
UV_COPPER = (0.010, 0.660, 0.490, 0.990)


def log(message: str) -> None:
    print("[make_storm_guardian] %s" % message)


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0


def rng() -> np.random.Generator:
    return np.random.default_rng(SEED)


# ---------------------------------------------------------------------------
# Fabrique de volumes
# ---------------------------------------------------------------------------

def add_box(name: str, size, location, rotation=(0.0, 0.0, 0.0),
            taper: float = 1.0) -> bpy.types.Object:
    """Boîte chanfreinée, éventuellement effilée vers +Z (taper < 1)."""
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for vert in bm.verts:
        scale = 1.0 if vert.co.z < 0 else taper
        vert.co.x *= size[0] * scale
        vert.co.y *= size[1] * scale
        vert.co.z *= size[2]
    bmesh.ops.bevel(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
                    offset=min(size) * 0.10, segments=2, affect="EDGES")
    bm.to_mesh(mesh)
    bm.free()
    obj.location = location
    obj.rotation_euler = rotation
    return obj


def add_cylinder(name: str, radius: float, depth: float, location,
                 rotation=(0.0, 0.0, 0.0), verts: int = 12) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=verts,
                          radius1=radius, radius2=radius, depth=depth)
    bm.to_mesh(mesh)
    bm.free()
    obj.location = location
    obj.rotation_euler = rotation
    return obj


def triangulate(obj: bpy.types.Object) -> None:
    """Le chanfrein produit des n-gons ; l'exporter glTF refuse alors de
    calculer les tangentes (« Tangent space can only be computed for
    tris/quads »). Une normal map sans tangentes est une normal map fausse :
    on triangule à la source plutôt que de perdre l'information à l'export.
    """
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.to_mesh(obj.data)
    bm.free()


def apply_transforms(objects: list) -> None:
    """APPLIQUE la transformation de chaque maillage dans ses sommets.

    Sans cela le modèle EXPLOSE à l'affichage, et aucun test de géométrie ne
    le voit : un maillage SKINNÉ ignore la transformation de son nœud —
    glTF le place par ses joints et ses matrices de liaison inverse. Chaque
    pièce posée par `obj.location` se rabattait donc sur la position de son
    os, et la créature arrivait dans Godot en tas de boîtes éparpillées.
    Constaté sur une CAPTURE du vrai moteur, pas sur une assertion : les
    boîtes englobantes, elles, restaient dans les bonnes bandes.

    C'est aussi ce qu'exigeait déjà `.claude/rules/assets.md` — « rotation et
    échelle appliquées avant export ».
    """
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.context.view_layer.update()


def join(name: str, objects: list) -> bpy.types.Object:
    """Fusionne une liste d'objets en un seul mesh nommé."""
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    merged = bpy.context.view_layer.objects.active
    merged.name = name
    merged.data.name = name
    return merged


# ---------------------------------------------------------------------------
# Anatomie
# ---------------------------------------------------------------------------

def build_body(generator) -> bpy.types.Object:
    """Masse centrale : dos VOÛTÉ, poitrail plus bas, flancs cuirassés.

    Le dos est bâti en cinq travées d'épaisseur décroissante vers l'arrière —
    c'est ce qui donne la voûte sans recourir à un modificateur de courbe,
    et ce qui rend le résultat identique à chaque exécution.
    """
    parts = []
    for i in range(5):
        t = i / 4.0
        arch = math.sin(math.pi * (0.25 + 0.5 * t)) * 0.55
        width = BODY_W * (1.0 - 0.08 * t)
        length = BODY_LEN / 5.0
        y = BODY_LEN * (0.5 - t) - length * 0.5
        jitter = float(generator.uniform(-0.03, 0.03))
        # Cotes PLEINES : `add_box` ne prend pas une demi-taille. Les travées
        # bâties à 0,52 m de profondeur pour un pas de 1,00 m laissaient un
        # trou de 48 cm entre chacune — le dos du Gardien arrivait en
        # rondelles, et sa masse à mi-largeur laissait plaques, câbles et
        # membres flotter autour du vide (ISS-018).
        parts.append(add_box(
            "BodySpan%d" % i,
            (width, length * 1.15, BODY_H * (0.82 + arch * 0.4)),
            (0.0, y, BODY_Z + arch * 0.32 + jitter)))
    # Poitrail : plus bas et plus étroit, il porte le noyau.
    parts.append(add_box("Chest", (BODY_W * 0.36, 0.55, BODY_H * 0.42),
                         (0.0, BODY_LEN * 0.5 + 0.35, BODY_Z - 0.55)))
    # Flancs : deux jupes de pierre qui ferment la silhouette vue de face.
    for side in (-1, 1):
        parts.append(add_box("Flank%d" % (side + 1),
                             (0.30, BODY_LEN * 0.40, 0.75),
                             (side * BODY_W * 0.48, -0.2, BODY_Z - 0.35),
                             (0.0, side * math.radians(9.0), 0.0)))
    return join("GuardianBody", parts)


def build_head() -> list:
    """Tête COURTE, protégée par trois plaques de céramique distinctes."""
    y0 = BODY_LEN * 0.5 + 0.9
    skull = add_box("HeadSkull", (0.86, HEAD_LEN * 0.72, 0.78),
                    (0.0, y0 - 0.30, BODY_Z + 0.10), (math.radians(-8.0), 0.0, 0.0))
    jaw = add_box("HeadJaw", (0.62, 0.80, 0.44),
                  (0.0, y0 + 0.25, BODY_Z - 0.34))
    plates = []
    for i in range(3):
        offset = (i - 1) * 0.46
        plates.append(add_box(
            "HeadPlate%d" % i, (0.30, 0.52, 0.12),
            (offset, y0 - 0.05, BODY_Z + 0.66),
            (math.radians(-14.0), 0.0, math.radians(offset * 8.0))))
    head = join("GuardianHead", [skull, jaw])
    ceramic = join("GuardianHeadPlates", plates)
    return [head, ceramic]


def build_limb(name: str, side: int, y: float, attach_z: float,
               thigh: float, shin: float, heavy: bool) -> bpy.types.Object:
    """Un membre à trois segments et un pied à trois doigts larges.

    Les antérieurs (heavy) sont plus épais et plus longs : ce sont eux qui
    frappent, et la silhouette doit le dire avant l'attaque (§16.1).
    """
    girth = 0.38 if heavy else 0.26
    x = side * (BODY_W * 0.40 + girth * 0.2)
    parts = []
    # Chaque segment couvre TOUTE sa portée, plus un diamètre de mordant :
    # bâtis à 62 % ils s'arrêtaient à 19 % de la hanche et à 19 % du genou,
    # et la bête se lisait en morceaux (ISS-018).
    parts.append(add_box("%sThigh" % name,
                         (girth, girth * 0.9, thigh + girth),
                         (x, y, attach_z - thigh * 0.5),
                         (0.0, side * math.radians(7.0), 0.0)))
    knee_z = attach_z - thigh
    parts.append(add_cylinder("%sKnee" % name, girth * 0.86, girth * 1.5,
                              (x, y, knee_z),
                              (0.0, math.radians(90.0), 0.0)))
    parts.append(add_box("%sShin" % name,
                         (girth * 0.80, girth * 0.80, shin + girth * 0.8),
                         (x + side * 0.10, y - 0.08, knee_z - shin * 0.5),
                         (math.radians(6.0), 0.0, 0.0)))
    foot_z = knee_z - shin
    parts.append(add_box("%sPad" % name, (girth * 1.9, girth * 1.0, 0.22),
                         (x + side * 0.14, y - 0.14, foot_z + 0.10)))
    for toe in range(3):
        spread = (toe - 1) * girth * 0.72
        parts.append(add_box(
            "%sToe%d" % (name, toe), (girth * 0.26, 0.34, 0.13),
            (x + side * 0.14 + spread, y - 0.30, foot_z + 0.08),
            (0.0, 0.0, math.radians(spread * 14.0))))
    return join(name, parts)


def build_ring() -> list:
    """Anneau vertical INCOMPLET : trois segments, une brèche au sommet.

    La brèche est le motif de « surcharge » de la bible §2.3 (anneau
    incomplet) ; c'est aussi ce qui rend la phase 3 lisible quand l'anneau
    se divise et tourne de travers.
    """
    segments = []
    # Chaque arc PLONGE dans la masse par au moins une de ses extrémités :
    # l'arc 70°-165° d'origine restait entièrement au-dessus du dos et
    # flottait donc en l'air, un tiers d'anneau sans attache (ISS-018).
    # Les trois brèches (10°, 12°, 10°) gardent l'anneau « incomplet ».
    spans = [(math.radians(190.0), math.radians(285.0)),
             (math.radians(295.0), math.radians(35.0)),
             (math.radians(45.0), math.radians(178.0))]
    for index, (start, end) in enumerate(spans):
        if end < start:
            end += math.tau
        steps = 9
        # Le maillon doit couvrir le PAS de l'arc, sinon l'anneau devient un
        # collier de perles flottantes : 7 blocs de 0,20 m sur un arc de
        # 3,07 m laissaient 31 cm entre chacun (ISS-018).
        #
        # La longueur à allonger est celle de l'axe TANGENT. Avec une
        # rotation de `angle` autour de X, c'est le +Z local qui suit la
        # tangente et le +Y local qui pointe vers le centre : allonger Y,
        # comme je l'avais fait d'abord, épaississait les rayons sans jamais
        # combler l'écart entre eux.
        step_arc = abs(end - start) * RING_RADIUS / float(steps - 1)
        parts = []
        for step in range(steps):
            angle = start + (end - start) * (step / float(steps - 1))
            parts.append(add_box(
                "RingChunk%d_%d" % (index, step),
                (0.13, 0.20, step_arc * 1.30),
                (0.0,
                 math.cos(angle) * RING_RADIUS - 0.2,
                 RING_Z + math.sin(angle) * RING_RADIUS),
                (angle, 0.0, 0.0)))
        segments.append(join("GuardianRing%d" % index, parts))
    return segments


def build_tail() -> list:
    """Queue-conducteur segmentée, terminée par une FOURCHE de terre."""
    parts = []
    y = -BODY_LEN * 0.5 + 0.42
    z = BODY_Z - 0.05
    for i in range(TAIL_SEGMENTS):
        t = i / float(TAIL_SEGMENTS - 1)
        radius = 0.38 * (1.0 - 0.50 * t)
        length = 0.58
        y -= length * 0.92
        z -= 0.20 + 0.04 * i
        # Le segment couvre son pas plus un mordant : à `length * 0.5` la
        # queue se désenfilait vertèbre par vertèbre (ISS-018).
        parts.append(add_box("TailSeg%d" % i, (radius, length * 1.15, radius),
                             (0.0, y, z), (math.radians(-16.0 - 4.0 * i), 0, 0)))
    fork = []
    for prong in (-1, 1):
        fork.append(add_box("TailProng%d" % (prong + 1), (0.09, 0.52, 0.09),
                            (prong * 0.13, y - 0.34, z - 0.20),
                            (math.radians(-34.0), 0.0,
                             math.radians(prong * 12.0))))
    return [join("GuardianTail", parts), join("GuardianTailFork", fork)]


def build_core() -> bpy.types.Object:
    """Noyau circulaire FENDU au sternum — deux demi-disques et un vide."""
    parts = []
    for half in (-1, 1):
        parts.append(add_cylinder("CoreHalf%d" % (half + 1), 0.52, 0.30,
                                  (half * 0.10, BODY_LEN * 0.5 + 0.62,
                                   BODY_Z - 0.5),
                                  (math.radians(90.0), 0.0,
                                   math.radians(half * 6.0)), verts=16))
    core = join("Core", parts)
    return core


def build_crystals() -> list:
    """Deux cristaux en DIAPASON BRISÉ (bible §15.3) — pas des gemmes."""
    crystals = []
    for index, side in enumerate((-1, 1)):
        parts = []
        base = add_box("CrystalBase", (0.20, 0.20, 0.34),
                       (side * 0.92, -0.55, BODY_Z + 1.15))
        parts.append(base)
        for prong in (-1, 1):
            # Les branches repartent DE la base : à +1,78 elles flottaient
            # 20 cm au-dessus d'elle (ISS-018).
            parts.append(add_box(
                "CrystalProng%d" % (prong + 1), (0.09, 0.09, 0.52),
                (side * 0.92 + prong * 0.17, -0.55, BODY_Z + 1.45),
                (0.0, math.radians(prong * 11.0), 0.0)))
        crystals.append(join("Crystal%s" % "AB"[index], parts))
    return crystals


def build_armour_plates(generator) -> list:
    """Plaques d'armure DÉTACHABLES : chacune est un objet à part, sinon la
    phase 2 ne pourrait pas les ouvrir ni la phase 3 les faire pendre."""
    plates = []
    for i in range(8):
        side = -1 if i % 2 == 0 else 1
        row = i // 2
        y = BODY_LEN * 0.34 - row * (BODY_LEN * 0.24)
        tilt = float(generator.uniform(-6.0, 6.0))
        plates.append(add_box(
            "ArmourPlate%d" % i, (0.34, BODY_LEN * 0.11, 0.62),
            (side * (BODY_W * 0.50), y, BODY_Z + 0.42),
            (math.radians(tilt), side * math.radians(16.0), 0.0)))
    return plates


def build_shoulders() -> bpy.types.Object:
    """Épaules de BRONZE : la masse qui annonce les coups des antérieurs."""
    parts = []
    for side in (-1, 1):
        # Épaules ÉLARGIES : ramener les attaches de membres dans la masse
        # (pour fermer les articulations) avait fait tomber la largeur à
        # 4,89 m, sous la bande 5-7 de §15.1. Le test l'a vu ; c'est la
        # carrure qui reprend la place, pas les jambes qui ressortent.
        parts.append(add_box("Shoulder%d" % (side + 1), (0.78, 0.80, 0.66),
                             (side * (BODY_W * 0.44), BODY_LEN * 0.30,
                              LEG_FRONT_Z + 0.52),
                             (0.0, side * math.radians(14.0), 0.0)))
    return join("GuardianShoulders", parts)


def build_cables() -> bpy.types.Object:
    """Câbles-tendons : ils relient le dos aux épaules et à la queue. Bleu
    pétrole, NON émissifs au repos (bible §15.2)."""
    parts = []
    for side in (-1, 1):
        for i in range(3):
            offset = (i - 1) * 0.24
            parts.append(add_box(
                "Cable%d_%d" % (side + 1, i), (0.055, BODY_LEN * 0.30, 0.055),
                (side * (BODY_W * 0.30 + offset * 0.5), 0.15 + offset,
                 BODY_Z + 0.92),
                (math.radians(6.0 * i), 0.0, 0.0)))
    return join("GuardianCables", parts)


# ---------------------------------------------------------------------------
# Matériaux et UV
# ---------------------------------------------------------------------------

def make_material(name: str, colour, metallic: float, roughness: float,
                  images=None, emission=None) -> bpy.types.Material:
    """Matériau branché sur l'ATLAS quand il est fourni.

    Sans ce branchement, les PNG peints étaient écrits sur disque et le .glb
    n'embarquait aucune image : les UV portaient une correspondance que rien
    ne lisait. Les couleurs restent en repli si l'atlas manque.
    """
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    tree = material.node_tree
    bsdf = tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = colour
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = emission
        bsdf.inputs["Emission Strength"].default_value = 2.0
    if images is None:
        return material

    base_node = tree.nodes.new("ShaderNodeTexImage")
    base_node.image = images["base"]
    base_node.location = (-620, 260)
    tree.links.new(base_node.outputs["Color"], bsdf.inputs["Base Color"])

    mr_node = tree.nodes.new("ShaderNodeTexImage")
    mr_node.image = images["mr"]
    mr_node.image.colorspace_settings.name = "Non-Color"
    mr_node.location = (-620, -80)
    separate = tree.nodes.new("ShaderNodeSeparateColor")
    separate.location = (-380, -80)
    tree.links.new(mr_node.outputs["Color"], separate.inputs["Color"])
    # Convention ORM : G = roughness, B = metallic (docs/assets/IMPORT_RULES).
    tree.links.new(separate.outputs["Green"], bsdf.inputs["Roughness"])
    tree.links.new(separate.outputs["Blue"], bsdf.inputs["Metallic"])
    return material


def project_uv(obj: bpy.types.Object, region) -> None:
    """Projection planaire par objet dans SA région de l'atlas.

    Volontairement simple : les volumes sont des boîtes chanfreinées et la
    texture porte des masses de couleur, pas un motif à raccorder. Une
    dépliage complexe coûterait sans rien ajouter de visible.
    """
    mesh = obj.data
    if not mesh.uv_layers:
        mesh.uv_layers.new(name="UVMap")
    uv_layer = mesh.uv_layers.active.data
    xs = [v.co.x for v in mesh.vertices]
    ys = [v.co.y for v in mesh.vertices]
    zs = [v.co.z for v in mesh.vertices]
    span_x = max(1e-4, max(xs) - min(xs))
    span_y = max(1e-4, max(ys) - min(ys))
    span_z = max(1e-4, max(zs) - min(zs))
    u0, v0, u1, v1 = region
    for poly in mesh.polygons:
        for loop_index in poly.loop_indices:
            vertex = mesh.vertices[mesh.loops[loop_index].vertex_index]
            # L'axe le plus plat de la face décide de la projection.
            normal = poly.normal
            if abs(normal.x) >= abs(normal.y) and abs(normal.x) >= abs(normal.z):
                a = (vertex.co.y - min(ys)) / span_y
                b = (vertex.co.z - min(zs)) / span_z
            elif abs(normal.y) >= abs(normal.z):
                a = (vertex.co.x - min(xs)) / span_x
                b = (vertex.co.z - min(zs)) / span_z
            else:
                a = (vertex.co.x - min(xs)) / span_x
                b = (vertex.co.y - min(ys)) / span_y
            uv_layer[loop_index].uv = (u0 + (u1 - u0) * a, v0 + (v1 - v0) * b)


def paint_textures(generator) -> dict:
    """BaseColor et MetallicRoughness peintes sur les MÊMES rectangles que
    les UV. Variation macro lente, creux plus froids, arêtes plus chaudes —
    la grammaire painterly de la bible §5.1, sans microbruit."""
    size = TEX_SIZE
    base = np.zeros((size, size, 4), dtype=np.float32)
    base[..., 3] = 1.0
    mr = np.zeros((size, size, 4), dtype=np.float32)
    mr[..., 3] = 1.0

    def fill(region, colour, metallic, roughness, macro=0.0):
        u0, v0, u1, v1 = region
        x0, x1 = int(u0 * size), int(u1 * size)
        y0, y1 = int(v0 * size), int(v1 * size)
        h, w = y1 - y0, x1 - x0
        gy, gx = np.mgrid[0:h, 0:w]
        # Deux fréquences très basses : des masses, jamais du bruit fin.
        wave = (np.sin(gx / max(1.0, w) * 3.1 + 0.7)
                * np.cos(gy / max(1.0, h) * 2.3 - 0.4))
        wave = wave * macro
        for channel in range(3):
            base[y0:y1, x0:x1, channel] = np.clip(
                colour[channel] * (1.0 + wave), 0.0, 1.0)
        mr[y0:y1, x0:x1, 1] = np.clip(roughness + wave * 0.35, 0.04, 1.0)
        mr[y0:y1, x0:x1, 2] = metallic

    fill(UV_STONE, COL_STONE_LIT, 0.0, 0.86, macro=0.22)
    fill(UV_BRONZE, COL_BRONZE, 0.85, 0.46, macro=0.16)
    fill(UV_COPPER, COL_COPPER, 0.90, 0.38, macro=0.18)
    fill(UV_IVORY, COL_IVORY, 0.0, 0.48, macro=0.10)
    fill(UV_CABLE, COL_CABLE, 0.25, 0.62, macro=0.12)
    fill(UV_CYAN, COL_CYAN, 0.0, 0.20, macro=0.08)

    os.makedirs(TEX_DIR, exist_ok=True)
    written = {}
    for key, name, array in (("base", "T_Guardian_BaseColor", base),
                             ("mr", "T_Guardian_MR", mr)):
        image = bpy.data.images.new(name, width=size, height=size, alpha=True)
        image.pixels = array.reshape(-1).tolist()
        image.filepath_raw = os.path.join(TEX_DIR, "%s.png" % name)
        image.file_format = "PNG"
        image.save()
        written[key] = image
        log("texture écrite : %s.png" % name)
    return written


# ---------------------------------------------------------------------------
# Rig
# ---------------------------------------------------------------------------

def build_armature(meshes: dict) -> bpy.types.Object:
    """Squelette minimal ORIENTÉ GAMEPLAY : ce qui doit bouger pendant un
    combat, et rien de plus. Chaque mesh est parenté à l'os qui le porte —
    pas de skinning par poids ici : les volumes sont rigides, comme une
    machine de pierre doit l'être."""
    armature_data = bpy.data.armatures.new("GuardianArmature")
    armature = bpy.data.objects.new("Armature", armature_data)
    bpy.context.collection.objects.link(armature)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode="EDIT")

    def bone(name: str, head, tail, parent=None):
        edit_bone = armature_data.edit_bones.new(name)
        edit_bone.head = head
        edit_bone.tail = tail
        if parent is not None:
            edit_bone.parent = armature_data.edit_bones[parent]
        return edit_bone

    bone("Root", (0.0, 0.0, 0.0), (0.0, 0.6, 0.0))
    bone("Spine", (0.0, -BODY_LEN * 0.5, BODY_Z),
         (0.0, BODY_LEN * 0.5, BODY_Z + 0.3), "Root")
    bone("Neck", (0.0, BODY_LEN * 0.5, BODY_Z + 0.3),
         (0.0, BODY_LEN * 0.5 + 0.9, BODY_Z + 0.15), "Spine")
    bone("Head", (0.0, BODY_LEN * 0.5 + 0.9, BODY_Z + 0.15),
         (0.0, BODY_LEN * 0.5 + 1.7, BODY_Z + 0.1), "Neck")
    bone("Ring", (0.0, -0.2, BODY_Z + 1.25),
         (0.0, -0.2, BODY_Z + 1.25 + RING_RADIUS), "Spine")
    parent = "Spine"
    for i in range(TAIL_SEGMENTS):
        name = "Tail%d" % i
        y = -BODY_LEN * 0.5 - 0.48 * i
        bone(name, (0.0, y, BODY_Z - 0.1 - 0.20 * i),
             (0.0, y - 0.48, BODY_Z - 0.30 - 0.20 * i), parent)
        parent = name
    for side_name, side in (("L", -1), ("R", 1)):
        for kind, y, attach in (("Fore", BODY_LEN * 0.30, LEG_FRONT_Z),
                                ("Mid", -BODY_LEN * 0.05, LEG_REAR_Z),
                                ("Hind", -BODY_LEN * 0.34, LEG_REAR_Z)):
            x = side * (BODY_W * 0.46)
            bone("%s%sUpper" % (kind, side_name), (x, y, attach),
                 (x, y, attach - 0.9), "Spine")
            bone("%s%sLower" % (kind, side_name), (x, y, attach - 0.9),
                 (x, y - 0.2, 0.05), "%s%sUpper" % (kind, side_name))
    bpy.ops.object.mode_set(mode="OBJECT")

    binding = {
        "GuardianBody": "Spine", "GuardianHead": "Head",
        "GuardianHeadPlates": "Head", "GuardianShoulders": "Spine",
        "GuardianCables": "Spine", "Core": "Spine",
        "CrystalA": "Spine", "CrystalB": "Spine",
        "GuardianTail": "Tail0", "GuardianTailFork": "Tail%d" % (TAIL_SEGMENTS - 1),
        "GuardianRing0": "Ring", "GuardianRing1": "Ring", "GuardianRing2": "Ring",
    }
    for i in range(8):
        binding["ArmourPlate%d" % i] = "Spine"
    for side_name in ("L", "R"):
        for kind in ("Fore", "Mid", "Hind"):
            binding["Leg%s%s" % (kind, side_name)] = "%s%sUpper" % (kind, side_name)

    # Liaison par POIDS, pas par parentage d'os. Le parentage « BONE » de
    # Blender accroche l'objet à la QUEUE de l'os, pas à sa tête : la
    # première version décalait toute la bête (mesuré ensuite dans Godot :
    # 14,50 m de long au lieu de 9,58, et le ventre à -0,96 m sous le sol).
    # Un groupe de sommets à poids 1 par pièce donne un skin glTF correct,
    # et c'est de toute façon ce que veut une machine de pierre : chaque
    # volume RIGIDE suit exactement un os.
    for mesh_name, bone_name in binding.items():
        obj = meshes.get(mesh_name)
        if obj is None:
            continue
        group = obj.vertex_groups.new(name=bone_name)
        group.add(range(len(obj.data.vertices)), 1.0, "REPLACE")
        obj.parent = armature
        obj.parent_type = "OBJECT"
        modifier = obj.modifiers.new(name="Armature", type="ARMATURE")
        modifier.object = armature
    bpy.context.view_layer.update()
    return armature


# ---------------------------------------------------------------------------
# Assemblage
# ---------------------------------------------------------------------------

def main() -> None:
    generator = rng()
    reset_scene()
    log("Blender %s" % bpy.app.version_string)

    meshes = {}
    body = build_body(generator)
    meshes[body.name] = body
    for obj in build_head():
        meshes[obj.name] = obj
    meshes["GuardianShoulders"] = build_shoulders()
    meshes["GuardianCables"] = build_cables()
    for obj in build_ring():
        meshes[obj.name] = obj
    for obj in build_tail():
        meshes[obj.name] = obj
    meshes["Core"] = build_core()
    for obj in build_crystals():
        meshes[obj.name] = obj
    for index, plate in enumerate(build_armour_plates(generator)):
        plate.name = "ArmourPlate%d" % index
        meshes[plate.name] = plate

    # Six membres : deux antérieurs LOURDS, quatre porteurs plus fins.
    for side_name, side in (("L", -1), ("R", 1)):
        meshes["LegFore%s" % side_name] = build_limb(
            "LegFore%s" % side_name, side, BODY_LEN * 0.30, LEG_FRONT_Z,
            1.05, 1.05, heavy=True)
        meshes["LegMid%s" % side_name] = build_limb(
            "LegMid%s" % side_name, side, -BODY_LEN * 0.05, LEG_REAR_Z,
            0.90, 0.90, heavy=False)
        meshes["LegHind%s" % side_name] = build_limb(
            "LegHind%s" % side_name, side, -BODY_LEN * 0.34, LEG_REAR_Z,
            0.95, 0.85, heavy=False)

    atlas = paint_textures(generator)
    materials = {
        "stone": (make_material("MAT_Guardian_Stone", COL_STONE_LIT, 0.0, 0.86,
                                atlas), UV_STONE),
        "bronze": (make_material("MAT_Guardian_Bronze", COL_BRONZE, 0.85, 0.46,
                                 atlas), UV_BRONZE),
        "copper": (make_material("MAT_Guardian_Copper", COL_COPPER, 0.90, 0.38,
                                 atlas), UV_COPPER),
        "ivory": (make_material("MAT_Guardian_Ceramic", COL_IVORY, 0.0, 0.48,
                                atlas), UV_IVORY),
        "cable": (make_material("MAT_Guardian_Cable", COL_CABLE, 0.25, 0.62,
                                atlas), UV_CABLE),
        "cyan": (make_material("MAT_Guardian_Core", COL_CORE, 0.0, 0.20,
                               atlas, emission=COL_CYAN), UV_CYAN),
    }
    assignment = {
        "GuardianBody": "stone", "GuardianHead": "stone",
        "GuardianHeadPlates": "ivory", "GuardianShoulders": "bronze",
        "GuardianCables": "cable", "Core": "cyan",
        "CrystalA": "cyan", "CrystalB": "cyan",
        "GuardianTail": "copper", "GuardianTailFork": "copper",
        "GuardianRing0": "bronze", "GuardianRing1": "bronze",
        "GuardianRing2": "bronze",
    }
    for i in range(8):
        assignment["ArmourPlate%d" % i] = "ivory" if i % 4 == 0 else "stone"
    for side_name in ("L", "R"):
        assignment["LegFore%s" % side_name] = "bronze"
        assignment["LegMid%s" % side_name] = "stone"
        assignment["LegHind%s" % side_name] = "stone"

    for mesh_name, key in assignment.items():
        obj = meshes.get(mesh_name)
        if obj is None:
            continue
        material, region = materials[key]
        obj.data.materials.append(material)
        triangulate(obj)
        project_uv(obj, region)

    # « Bas de l'objet au sol : min Y ≈ 0 » (règle assets, §7.15) — ici min Z
    # avant conversion Y-up. La bête est mesurée puis REPOSÉE : les cotes des
    # membres sont réglées pour la lisibilité de la silhouette, pas pour
    # tomber pile sur zéro, et un décalage global vaut mieux qu'un réglage
    # fragile qu'il faudrait refaire à chaque retouche de patte.
    bpy.context.view_layer.update()
    lowest = min((obj.matrix_world @ vertex.co).z
                 for obj in meshes.values() for vertex in obj.data.vertices)
    if abs(lowest) > 1e-4:
        for obj in meshes.values():
            obj.location = (obj.location.x, obj.location.y,
                            obj.location.z - lowest)
        log("modèle reposé au sol : décalage de %+.3f m" % -lowest)

    apply_transforms(list(meshes.values()))
    build_armature(meshes)

    # Contrôle de cotes : la bible §15.1 est une exigence, pas une intention.
    # `view_layer.update()` d'abord — sans lui, `matrix_world` est PÉRIMÉE
    # après un reparentage et le script mesure une bête qui n'existe plus.
    bpy.context.view_layer.update()
    xs, ys, zs = [], [], []
    for obj in meshes.values():
        for vertex in obj.data.vertices:
            world = obj.matrix_world @ vertex.co
            xs.append(world.x)
            ys.append(world.y)
            zs.append(world.z)
    width = max(xs) - min(xs)
    length = max(ys) - min(ys)
    height = max(zs) - min(zs)
    log("cotes mesurées : long %.2f m · large %.2f m · haut %.2f m"
        % (length, width, height))
    log("bible §15.1 attend : long 8-10 · large 5-7 · haut 5,2-6")
    log("min Z = %.3f m (doit être ≈ 0 : la bête pose au sol)" % min(zs))
    log("%d objets nommés (noyau, cristaux, plaques et anneaux séparés)"
        % len(meshes))

    os.makedirs(SRC_DIR, exist_ok=True)
    out = os.path.join(SRC_DIR, "SK_StormGuardian.blend")
    bpy.ops.wm.save_as_mainfile(filepath=out)
    log("source écrite : %s" % out)


if __name__ == "__main__":
    main()
