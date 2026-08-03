"""Phase H lots H.3 et H.4 — COLOSSE DES RAVINS et CHASSEUR QUADRUPÈDE.

Deux créatures qui n'existaient qu'en boîtes de graybox. L'ordre de la
Phase H est explicite sur les deux : « un humain agrandi ne constitue pas
un colosse », et le chasseur doit avoir « un corps inférieur quadrupède
ORIGINAL, non équin ». Elles sont donc construites ici depuis des
primitives, comme le Gardien, avec leur propre squelette — contrairement
aux pillards, aucune bibliothèque d'animation existante ne les vise, il n'y
avait donc rien à préserver.

**Colosse des ravins** (VISUAL_ASSET_BIBLE §14.4) :
torse INCLINÉ, bassin massif, bras ASYMÉTRIQUES dont l'un porte une
croissance rocheuse, petites jambes puissantes, tête enfoncée mais visage
lisible. Point faible : un nodule minéral PÂLE entre omoplate et nuque,
visible seulement de dos et par le haut. Ceinture de troncs tressés,
protection de bois sur une jambe. Aucune massue géante : ses mains servent
à arracher et à lancer.

**Chasseur quadrupède** (§14.5) :
corps inférieur bas et allongé — félin cuirassé et grand lézard, ni sabots,
ni crinière, ni croupe de cheval — sur quatre pattes à TROIS doigts larges,
épaules avant plus hautes, longue cage thoracique, courte queue de lames.
Le torse supérieur naît EN AVANT du bassin inférieur et reste incliné ;
tête étroite à plaque frontale et deux mandibules latérales décoratives.
Silhouette en flèches vers l'arrière.

Usage :
    blender --background --python tools/blender/make_creatures.py
Sorties :
    source_assets/blender/creatures/SK_RavineTroll.blend
    source_assets/blender/creatures/SK_CentaurHunter.blend
"""

import math
import os

import bmesh
import bpy
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC_DIR = os.path.join(ROOT, "source_assets", "blender", "creatures")

# Palette de la bible §1.4 / §14.4-14.5.
COL_HIDE = (0.352, 0.302, 0.216, 1.0)      # peau gris-ocre épaisse
COL_ROCK = (0.278, 0.243, 0.200, 1.0)      # plaques naturelles
COL_NODULE = (0.780, 0.745, 0.639, 1.0)    # nodule minéral PÂLE (point faible)
COL_WOOD = (0.408, 0.251, 0.157, 1.0)
COL_ROOT = (0.310, 0.243, 0.169, 1.0)
COL_CARAPACE = (0.729, 0.686, 0.596, 1.0)  # lames de céramique ivoire
COL_CARAPACE_COLD = (0.478, 0.510, 0.545, 1.0)
COL_FLESH = (0.325, 0.278, 0.259, 1.0)
COL_BRONZE = (0.427, 0.302, 0.180, 1.0)
COL_NIGHT = (0.129, 0.145, 0.216, 1.0)     # textile bleu nuit, très réduit


def log(message: str) -> None:
    print("[make_creatures] %s" % message)


# ---------------------------------------------------------------------------
# Volumes (mêmes briques que le Gardien)
# ---------------------------------------------------------------------------

def add_box(name: str, size, location, rotation=(0.0, 0.0, 0.0)):
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for vert in bm.verts:
        vert.co.x *= size[0]
        vert.co.y *= size[1]
        vert.co.z *= size[2]
    bmesh.ops.bevel(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
                    offset=min(size) * 0.14, segments=2, affect="EDGES")
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    obj.location = location
    obj.rotation_euler = rotation
    return obj


def limb(name: str, start: Vector, end: Vector, girth: float):
    delta = end - start
    obj = add_box(name, (girth, girth, max(0.02, delta.length) * 0.5),
                  tuple((start + end) * 0.5))
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = delta.to_track_quat("Z", "Y")
    return obj


def join_all(name: str, objects: list):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    merged = bpy.context.view_layer.objects.active
    merged.name = name
    merged.data.name = name
    return merged


def make_material(name: str, colour, roughness: float = 0.84,
                  metallic: float = 0.0, emissive=None):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = colour
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emissive is not None:
        bsdf.inputs["Emission Color"].default_value = emissive
        bsdf.inputs["Emission Strength"].default_value = 1.2
    return material


## Facteurs de mise à l'échelle finale, mesurés puis figés : la géométrie
## est composée à des proportions lisibles, et la TAILLE de la famille est
## posée en une fois à la fin. Le colosse sortait à 3,42 m pour une bande
## de 3,7-4,3 ; le chasseur à 5,04 m de long pour 4,0-4,8.
TROLL_SCALE = 1.16
HUNTER_SCALE = 0.93


def scale_creature(objects: list, factor: float) -> None:
    """Met la créature à sa taille de famille, puis APPLIQUE la
    transformation : une échelle laissée sur l'objet partirait deux fois
    vers glTF (cuite dans les sommets ET portée par le nœud) — mesuré sur
    les pillards, D-035."""
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.location = obj.location * factor
        obj.scale = (factor, factor, factor)
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=True)
    bpy.context.view_layer.update()


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"


def rest_on_ground(objects: list) -> float:
    """« Bas de l'objet au sol » (§7.15). Mesure puis repose."""
    bpy.context.view_layer.update()
    lowest = min((obj.matrix_world @ vertex.co).z
                 for obj in objects for vertex in obj.data.vertices)
    if abs(lowest) > 1e-4:
        for obj in objects:
            obj.location = (obj.location.x, obj.location.y,
                            obj.location.z - lowest)
    bpy.context.view_layer.update()
    return -lowest


def measure(objects: list) -> tuple:
    bpy.context.view_layer.update()
    xs, ys, zs = [], [], []
    for obj in objects:
        for vertex in obj.data.vertices:
            world = obj.matrix_world @ vertex.co
            xs.append(world.x)
            ys.append(world.y)
            zs.append(world.z)
    return (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs), min(zs))


def bind(armature, binding: dict, meshes: dict) -> None:
    """Poids 1 par pièce, comme pour le Gardien. Le parentage « BONE » de
    Blender accroche à la QUEUE de l'os et décale tout : on ne l'utilise
    pas (voir D-034)."""
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


def new_armature(name: str, bones: list):
    """`bones` : liste de (nom, head, tail, parent|None)."""
    data = bpy.data.armatures.new(name)
    armature = bpy.data.objects.new("Armature", data)
    bpy.context.collection.objects.link(armature)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode="EDIT")
    for bone_name, head, tail, parent in bones:
        edit_bone = data.edit_bones.new(bone_name)
        edit_bone.head = head
        edit_bone.tail = tail
        if parent is not None:
            edit_bone.parent = data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    return armature


# ---------------------------------------------------------------------------
# COLOSSE DES RAVINS (§12.4, bible §14.4)
# ---------------------------------------------------------------------------

def build_colossus() -> None:
    reset_scene()
    meshes = {}
    hide, rock, nodule, wood = [], [], [], []

    # Bassin MASSIF, bas. C'est lui qui porte la lecture « colosse » : la
    # masse est en bas, pas en haut comme sur un humain agrandi.
    hide.append(add_box("Pelvis", (0.86, 0.62, 0.52), (0.0, 0.0, 1.62)))
    # Torse INCLINÉ vers l'avant, épaules très larges.
    hide.append(add_box("TorsoLow", (0.92, 0.60, 0.46),
                        (0.0, -0.12, 2.28), (math.radians(-16.0), 0, 0)))
    hide.append(add_box("TorsoHigh", (1.10, 0.62, 0.48),
                        (0.0, -0.34, 2.94), (math.radians(-22.0), 0, 0)))
    # Tête ENFONCÉE entre les épaules, mais le visage reste lisible.
    hide.append(add_box("Head", (0.40, 0.46, 0.36),
                        (0.0, -0.62, 3.24), (math.radians(-10.0), 0, 0)))
    hide.append(add_box("Brow", (0.44, 0.16, 0.10),
                        (0.0, -0.84, 3.36), (math.radians(-14.0), 0, 0)))
    hide.append(add_box("Jaw", (0.32, 0.30, 0.16), (0.0, -0.80, 3.02)))

    # POINT FAIBLE (§12.4) : nodule minéral pâle entre omoplate et nuque.
    # Il n'est visible que de dos et par le haut — pas une cible peinte.
    nodule.append(add_box("WeakNodule", (0.26, 0.22, 0.20),
                          (0.0, 0.30, 3.16), (math.radians(18.0), 0, 0)))

    # Plaques naturelles suivant l'omoplate.
    for side in (-1, 1):
        rock.append(add_box("Scapula%d" % (side + 1), (0.34, 0.40, 0.14),
                            (side * 0.62, 0.16, 3.02),
                            (math.radians(12.0), math.radians(side * 18.0), 0)))

    # BRAS ASYMÉTRIQUES : le droit porte une croissance rocheuse, le gauche
    # est nu. L'asymétrie est le signe de reconnaissance de la famille.
    for side, rocky in ((-1, False), (1, True)):
        shoulder = Vector((side * 1.02, -0.28, 2.98))
        elbow = Vector((side * 1.44, -0.16, 2.02))
        wrist = Vector((side * 1.52, -0.34, 1.12))
        girth = 0.30 if not rocky else 0.36
        hide.append(limb("UpperArm%d" % (side + 1), shoulder, elbow, girth))
        hide.append(limb("LowerArm%d" % (side + 1), elbow, wrist, girth * 0.92))
        hide.append(add_box("Hand%d" % (side + 1), (0.30, 0.26, 0.30),
                            tuple(wrist + Vector((0, -0.04, -0.28)))))
        for finger in range(3):
            hide.append(add_box("Finger%d_%d" % (side + 1, finger),
                (0.075, 0.075, 0.16),
                tuple(wrist + Vector((side * 0.0 + (finger - 1) * 0.16,
                                      -0.12, -0.58)))))
        if rocky:
            for i in range(4):
                t = i / 3.0
                rock.append(add_box("Growth%d" % i,
                    (0.20 - 0.03 * i, 0.20 - 0.03 * i, 0.16),
                    tuple(shoulder.lerp(wrist, t)
                          + Vector((side * 0.18, 0.10, 0.0))),
                    (0, math.radians(side * (14.0 + 6.0 * i)), 0)))

    # Petites jambes PUISSANTES : courtes, épaisses, très écartées.
    for side in (-1, 1):
        hip = Vector((side * 0.52, 0.0, 1.44))
        knee = Vector((side * 0.60, 0.06, 0.80))
        ankle = Vector((side * 0.62, -0.02, 0.22))
        hide.append(limb("Thigh%d" % (side + 1), hip, knee, 0.34))
        hide.append(limb("Calf%d" % (side + 1), knee, ankle, 0.30))
        hide.append(add_box("Foot%d" % (side + 1), (0.34, 0.46, 0.14),
                            (side * 0.62, -0.18, 0.10)))
        for toe in range(3):
            hide.append(add_box("Toe%d_%d" % (side + 1, toe),
                (0.09, 0.16, 0.09),
                (side * 0.62 + (toe - 1) * 0.19, -0.46, 0.08)))

    # Ceinture de troncs TRESSÉS et protection de bois sur UNE jambe.
    for i in range(5):
        angle = math.pi * (-0.4 + 0.2 * i)
        wood.append(add_box("BeltLog%d" % i, (0.14, 0.14, 0.34),
            (math.sin(angle) * 0.84, math.cos(angle) * 0.58, 1.52),
            (math.radians(88.0), 0.0, angle)))
    wood.append(add_box("ShinGuard", (0.34, 0.20, 0.42),
                        (-0.62, -0.22, 0.72), (math.radians(-8.0), 0, 0)))

    groups = {"Hide": (hide, COL_HIDE, 0.90, 0.0, None),
              "Rock": (rock, COL_ROCK, 0.94, 0.0, None),
              "Nodule": (nodule, COL_NODULE, 0.42, 0.0, None),
              "Wood": (wood, COL_WOOD, 0.88, 0.0, None)}
    for key, (parts, colour, rough, metal, emissive) in groups.items():
        merged = join_all("Troll%s" % key, parts)
        merged.data.materials.append(
            make_material("MAT_Troll_%s" % key, colour, rough, metal, emissive))
        meshes[merged.name] = merged

    scale_creature(list(meshes.values()), TROLL_SCALE)
    rest_on_ground(list(meshes.values()))
    k = TROLL_SCALE
    armature = new_armature("TrollArmature", [
        ("Root", (0, 0, 0), (0, 0.5 * k, 0), None),
        ("Pelvis", (0, 0, 1.44 * k), (0, 0, 2.10 * k), "Root"),
        ("Spine", (0, 0, 2.10 * k), (0, -0.3 * k, 2.94 * k), "Pelvis"),
        ("Head", (0, -0.34 * k, 2.94 * k), (0, -0.9 * k, 3.24 * k), "Spine"),
        ("ArmL", (-1.02 * k, -0.28 * k, 2.98 * k),
         (-1.52 * k, -0.34 * k, 1.12 * k), "Spine"),
        ("ArmR", (1.02 * k, -0.28 * k, 2.98 * k),
         (1.52 * k, -0.34 * k, 1.12 * k), "Spine"),
        ("LegL", (-0.52 * k, 0, 1.44 * k), (-0.62 * k, -0.02, 0.22 * k), "Pelvis"),
        ("LegR", (0.52 * k, 0, 1.44 * k), (0.62 * k, -0.02, 0.22 * k), "Pelvis"),
    ])
    bind(armature, {"TrollHide": "Spine", "TrollRock": "Spine",
                    "TrollNodule": "Spine", "TrollWood": "Pelvis"}, meshes)

    width, length, height, floor = measure(list(meshes.values()))
    log("colosse : haut %.2f m (bible §14.4 : 3,7-4,3) · large %.2f m · min Z %.3f"
        % (height, width, floor))
    os.makedirs(SRC_DIR, exist_ok=True)
    out = os.path.join(SRC_DIR, "SK_RavineTroll.blend")
    bpy.ops.wm.save_as_mainfile(filepath=out)
    log("source écrite : %s" % os.path.basename(out))


# ---------------------------------------------------------------------------
# CHASSEUR QUADRUPÈDE (§12.5, bible §14.5)
# ---------------------------------------------------------------------------

def build_hunter() -> None:
    reset_scene()
    meshes = {}
    flesh, carapace, bronze, textile = [], [], [], []

    # Corps inférieur : cage thoracique LONGUE et basse, épaules avant plus
    # hautes que la croupe. Aucune croupe de cheval, aucune crinière.
    spans = [(1.10, 0.62, 0.52), (1.16, 0.60, 0.58), (1.08, 0.58, 0.56),
             (0.94, 0.54, 0.50), (0.78, 0.50, 0.42)]
    for i, (w, d, h) in enumerate(spans):
        y = 1.45 - i * 0.72
        z = 1.38 - i * 0.055        # l'avant est PLUS HAUT que l'arrière
        flesh.append(add_box("Rib%d" % i, (w * 0.5, d * 0.5, h * 0.5),
                             (0.0, y, z)))
    # Plaques dorsales en flèches vers l'arrière : la vitesse se lit à l'arrêt.
    for i in range(5):
        carapace.append(add_box("Fin%d" % i, (0.30 - 0.03 * i, 0.34, 0.09),
            (0.0, 1.20 - i * 0.70, 1.66 - i * 0.05),
            (math.radians(-24.0 - 4.0 * i), 0, 0)))

    # Quatre pattes à TROIS doigts larges. Pas de sabot.
    for side in (-1, 1):
        for pair, (y, hip_z, upper, lower) in enumerate(
                ((1.24, 1.12, 0.62, 0.56), (-1.62, 1.02, 0.58, 0.52))):
            hip = Vector((side * 0.52, y, hip_z))
            knee = Vector((side * 0.58, y - 0.14, hip_z - upper))
            ankle = Vector((side * 0.56, y + 0.06, hip_z - upper - lower))
            flesh.append(limb("Upper%d_%d" % (side + 1, pair), hip, knee, 0.17))
            flesh.append(limb("Lower%d_%d" % (side + 1, pair), knee, ankle, 0.14))
            for toe in range(3):
                flesh.append(add_box("Toe%d_%d_%d" % (side + 1, pair, toe),
                    (0.055, 0.115, 0.045),
                    tuple(ankle + Vector(((toe - 1) * 0.10, -0.14, -0.05)))))
            carapace.append(add_box("Greave%d_%d" % (side + 1, pair),
                (0.13, 0.17, 0.22), tuple(hip + Vector((side * 0.10, 0, -0.20))),
                (0, math.radians(side * 12.0), 0)))

    # Queue COURTE, en lames de céramique — stabilisatrice, pas décorative.
    for i in range(3):
        carapace.append(add_box("TailBlade%d" % i,
            (0.10 - 0.02 * i, 0.28, 0.07),
            (0.0, -2.24 - i * 0.42, 1.06 - i * 0.10),
            (math.radians(-18.0 - 8.0 * i), 0, 0)))

    # Torse supérieur : il naît EN AVANT du bassin inférieur et reste
    # INCLINÉ. C'est ce qui distingue la créature d'un centaure classique.
    flesh.append(add_box("TorsoLow", (0.44, 0.34, 0.42),
                         (0.0, 1.62, 1.86), (math.radians(-18.0), 0, 0)))
    flesh.append(add_box("TorsoHigh", (0.50, 0.32, 0.44),
                         (0.0, 1.48, 2.62), (math.radians(-14.0), 0, 0)))
    carapace.append(add_box("Chestplate", (0.46, 0.14, 0.40),
                            (0.0, 1.24, 2.52), (math.radians(-12.0), 0, 0)))
    # Tête ÉTROITE à plaque frontale et deux mandibules latérales.
    flesh.append(add_box("Head", (0.20, 0.34, 0.24), (0.0, 1.32, 3.06)))
    carapace.append(add_box("Frontplate", (0.24, 0.12, 0.28),
                            (0.0, 1.16, 3.14), (math.radians(-16.0), 0, 0)))
    for side in (-1, 1):
        carapace.append(add_box("Mandible%d" % (side + 1), (0.05, 0.24, 0.06),
            (side * 0.17, 1.20, 2.96),
            (math.radians(-10.0), 0.0, math.radians(side * 13.0))))

    # Deux bras LONGS.
    for side in (-1, 1):
        shoulder = Vector((side * 0.44, 1.44, 2.72))
        elbow = Vector((side * 0.66, 1.30, 2.18))
        wrist = Vector((side * 0.72, 1.42, 1.66))
        flesh.append(limb("Arm%d" % (side + 1), shoulder, elbow, 0.115))
        flesh.append(limb("Forearm%d" % (side + 1), elbow, wrist, 0.10))
        flesh.append(add_box("Hand%d" % (side + 1), (0.10, 0.09, 0.12),
                             tuple(wrist + Vector((0, 0.04, -0.10)))))
        carapace.append(add_box("Pauldron%d" % (side + 1), (0.19, 0.21, 0.13),
            tuple(shoulder + Vector((side * 0.08, 0, 0.06))),
            (0, math.radians(side * 20.0), 0)))

    # Carquois latéral FIXÉ AU CORPS INFÉRIEUR (§14.5), pas dans le dos.
    bronze.append(add_box("Quiver", (0.11, 0.15, 0.44),
                          (0.62, 0.30, 1.52),
                          (math.radians(16.0), math.radians(-14.0), 0)))
    textile.append(add_box("Sash", (0.42, 0.10, 0.26),
                           (0.0, 1.38, 2.30), (math.radians(-14.0), 0, 0)))

    groups = {"Flesh": (flesh, COL_FLESH, 0.86, 0.0),
              "Carapace": (carapace, COL_CARAPACE, 0.52, 0.0),
              "Bronze": (bronze, COL_BRONZE, 0.44, 0.75),
              "Textile": (textile, COL_NIGHT, 0.90, 0.0)}
    for key, (parts, colour, rough, metal) in groups.items():
        merged = join_all("Hunter%s" % key, parts)
        merged.data.materials.append(
            make_material("MAT_Hunter_%s" % key, colour, rough, metal))
        meshes[merged.name] = merged

    scale_creature(list(meshes.values()), HUNTER_SCALE)
    rest_on_ground(list(meshes.values()))
    k = HUNTER_SCALE
    armature = new_armature("HunterArmature", [
        ("Root", (0, 0, 0), (0, 0.5 * k, 0), None),
        ("Spine", (0, -1.6 * k, 1.15 * k), (0, 1.45 * k, 1.38 * k), "Root"),
        ("Chest", (0, 1.45 * k, 1.38 * k), (0, 1.55 * k, 1.90 * k), "Spine"),
        ("TorsoUp", (0, 1.55 * k, 1.90 * k), (0, 1.45 * k, 2.70 * k), "Chest"),
        ("Head", (0, 1.45 * k, 2.70 * k), (0, 1.30 * k, 3.20 * k), "TorsoUp"),
        ("Tail", (0, -2.10 * k, 1.10 * k), (0, -3.00 * k, 0.85 * k), "Spine"),
    ])
    bind(armature, {"HunterFlesh": "Spine", "HunterCarapace": "Spine",
                    "HunterBronze": "Spine", "HunterTextile": "Chest"}, meshes)

    width, length, height, floor = measure(list(meshes.values()))
    log("chasseur : haut %.2f m (bible §14.5 : 3,0-3,5) · long %.2f m (4,0-4,8) "
        % (height, length) + "· large %.2f m · min Z %.3f" % (width, floor))
    out = os.path.join(SRC_DIR, "SK_CentaurHunter.blend")
    bpy.ops.wm.save_as_mainfile(filepath=out)
    log("source écrite : %s" % os.path.basename(out))


def main() -> None:
    log("Blender %s" % bpy.app.version_string)
    build_colossus()
    build_hunter()


if __name__ == "__main__":
    main()
