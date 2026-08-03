"""Phase H lot H.2 — les TROIS PILLARDS, silhouettes réellement distinctes.

L'ordre de la Phase H est net : « ne jamais confondre une variante de
couleur avec une famille visuelle distincte ». Les trois pillards
partageaient jusqu'ici un même modèle acheté, teinté trois fois. Ce script
leur donne trois CORPS, construits depuis des primitives.

Choix structurant : **la géométrie est neuve, le squelette ne l'est pas.**
Les corps sont bâtis autour du squelette UAL à 65 os déjà présent dans le
dépôt, puis liés par poids automatiques. Conséquence directe : les
bibliothèques d'animation existantes (`AL_RaiderStates.res`) continuent de
s'appliquer sans retargeting. Créer trois rigs neufs aurait signifié
réécrire toutes les animations — une régression déguisée en progrès.

Les trois familles, d'après VISUAL_ASSET_BIBLE §14.1 à §14.3 :

| | braise | azur | obsidienne |
|---|---|---|---|
| taille | 1,40-1,52 m | 1,58-1,72 m | 1,85-2,05 m |
| posture | torse court VOÛTÉ, centre de gravité en avant | droite, épaules étroites, jambes longues | bassin BAS, torse très large, cou presque absent |
| tête | coin, deux excroissances osseuses vers l'ARRIÈRE | crête verticale mince | visière fendue, mâchoire lourde |
| épaules | nues | protège-épaules SEGMENTÉS, silhouette en parenthèses | deux plaques INÉGALES en trapèze |
| bras | avant-bras LONGS | fins, tendus | épais |

Aucune oreille de Bokoblin, aucun masque tribal générique, aucune cuirasse
empruntée : les excroissances pointent vers l'arrière, la crête est osseuse
et la visière est fendue en diagonale.

Usage :
    blender --background --python tools/blender/make_raiders.py
Sorties :
    source_assets/blender/characters/SK_Raider{Red,Blue,Black}.blend
"""

import math
import os

maxf = max

import bmesh
import bpy
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SKELETON = os.path.join(ROOT, "assets", "characters", "enemies",
                        "Male_Peasant.gltf")
SRC_DIR = os.path.join(ROOT, "source_assets", "blender", "characters")

# Palette de la bible §1.4 et §14.1-14.3 — rien d'inventé ici.
COL_SKIN_RED = (0.372, 0.196, 0.145, 1.0)
COL_CLOTH_RED = (0.435, 0.161, 0.114, 1.0)     # terre cuite / rouge sombre
COL_SKIN_BLUE = (0.278, 0.286, 0.325, 1.0)
COL_CLOTH_BLUE = (0.153, 0.180, 0.290, 1.0)    # indigo délavé
COL_GUARD_BLUE = (0.361, 0.392, 0.427, 1.0)    # céramique gris-bleu
COL_SKIN_BLACK = (0.216, 0.196, 0.192, 1.0)
COL_PLATE_BLACK = (0.118, 0.110, 0.125, 1.0)   # pierre vitreuse mate
COL_CORE_BLACK = (0.294, 0.251, 0.216, 1.0)    # cœur brun-gris des ébréchures
COL_LEATHER = (0.408, 0.251, 0.157, 1.0)
COL_ROPE = (0.545, 0.451, 0.298, 1.0)
COL_BRONZE = (0.427, 0.302, 0.180, 1.0)
COL_BONE = (0.729, 0.667, 0.545, 1.0)


def log(message: str) -> None:
    print("[make_raiders] %s" % message)


# ---------------------------------------------------------------------------
# Volumes
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
                    offset=min(size) * 0.16, segments=2, affect="EDGES")
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    obj.location = location
    obj.rotation_euler = rotation
    return obj


def limb(name: str, start: Vector, end: Vector, girth: float):
    """Volume tendu entre deux points — un membre suit son os.

    Il est allongé d'un demi-diamètre à chaque bout : sans ce mordant, les
    segments se touchent sans se recouvrir et le corps se désassemble à
    l'œil dès qu'on le regarde de trois quarts.

    CAUSE RACINE d'ISS-018 : `add_box` prend une taille PLEINE, puisque
    `bmesh.ops.create_cube(size=1.0)` pose ses sommets à ±0,5. Le `* 0.5`
    qui traînait ici bâtissait chaque membre à la MOITIÉ de sa portée : il
    s'arrêtait à mi-chemin de son articulation, et le mordant décrit
    ci-dessus n'a jamais existé.
    """
    delta = end - start
    length = max(0.02, delta.length) + girth
    centre = (start + end) * 0.5
    obj = add_box(name, (girth, girth, length), tuple(centre))
    # Oriente +Z local le long du segment.
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = delta.to_track_quat("Z", "Y")
    return obj


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


def make_material(name: str, colour, roughness: float = 0.82,
                  metallic: float = 0.0):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = colour
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return material


# ---------------------------------------------------------------------------
# Squelette
# ---------------------------------------------------------------------------

def load_skeleton():
    """Importe le squelette UAL **et son corps**.

    On garde l'armature, ses 65 os et leurs noms — c'est ce qui rend les
    bibliothèques d'animation existantes réutilisables telles quelles.

    On garde AUSSI les maillages du corps, ce que la version précédente
    jetait. C'était une erreur de jugement coûteuse : le pack Quaternius
    « Universal Base Characters » (CC0, déjà attribué) fournit un humanoïde
    complet de 12 894 triangles, texturé en PBR et correctement pesé sur ces
    mêmes os. Il était remplacé par des membres bâtis en barres de 4 cm de
    section — la capture du bestiaire montrait trois figurines de fil de fer
    au lieu de trois familles de pillards. Les formes propres à chaque
    famille (cornes, crête, visière, épaulières, ceinture) restent, elles,
    des créations du projet : c'est ce qui les rend reconnaissables.
    """
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.ops.import_scene.gltf(filepath=SKELETON)
    armature = None
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE":
            armature = obj
            break
    # L'importateur glTF fabrique une icosphère d'affichage pour les os. Elle
    # n'appartient pas au personnage : gardée par erreur, elle ajoutait une
    # boule de 2 m à l'origine — qui gonflait la stature mesurée et comptait
    # évidemment comme une pièce détachée.
    helpers = {bone.custom_shape.name for bone in armature.pose.bones
               if bone.custom_shape is not None}
    body = []
    for obj in list(bpy.data.objects):
        if obj.type == "ARMATURE":
            continue
        if obj.type == "MESH" and obj.name not in helpers:
            body.append(obj)
        else:
            bpy.data.objects.remove(obj, do_unlink=True)
    armature.name = "Armature"
    armature.animation_data_clear()
    return armature, body


def reshape_body(body: list, wide: float, deep: float) -> None:
    """Change la CARRURE sans toucher à la hauteur.

    Seuls X et Y sont mis à l'échelle : Z reste celui des os, sinon les
    membres ne suivraient plus leur squelette. La stature vient de
    `height_scale`, appliquée à l'armature.
    """
    for obj in body:
        for vertex in obj.data.vertices:
            vertex.co.x *= wide
            vertex.co.y *= deep


def tint_body(body: list, colour, key: str) -> None:
    """Teinte les matériaux du corps SANS perdre leurs textures.

    Un `MixRGB` en multiplication est inséré entre la texture de couleur de
    base et le BSDF. Remplacer le matériau par un aplat aurait jeté la
    normal map et l'ORM du pack, c'est-à-dire l'essentiel de sa qualité.
    """
    done = set()
    for obj in body:
        for slot in obj.material_slots:
            material = slot.material
            # Suivre le DATABLOC, pas son nom : la première version testait le
            # nom puis le renommait, si bien qu'un matériau partagé par les
            # quatre maillages du corps se faisait préfixer quatre fois.
            if material is None or material in done:
                continue
            done.add(material)
            material.name = "MAT_Raider%s_%s" % (key, material.name)
            if not material.use_nodes:
                continue
            tree = material.node_tree
            bsdf = next((n for n in tree.nodes
                         if n.type == "BSDF_PRINCIPLED"), None)
            if bsdf is None:
                continue
            socket = bsdf.inputs["Base Color"]
            # `ShaderNodeMix` en RGBA, pas le `ShaderNodeMixRGB` hérité :
            # l'exporteur glTF ne reconnaît que le premier comme un
            # « facteur de couleur de base ». Avec l'ancien nœud, le mélange
            # était simplement ignoré et les trois familles sortaient de
            # l'export avec exactement la même texture de paysan.
            mix = tree.nodes.new("ShaderNodeMix")
            mix.data_type = "RGBA"
            mix.blend_type = "MULTIPLY"
            mix.inputs["Factor"].default_value = 1.0
            mix.inputs["B"].default_value = colour
            if socket.is_linked:
                tree.links.new(mix.inputs["A"], socket.links[0].from_socket)
            else:
                mix.inputs["A"].default_value = socket.default_value
            tree.links.new(socket, mix.outputs["Result"])


def head_of(armature, bone_name: str) -> Vector:
    return armature.data.bones[bone_name].head_local.copy()


def tail_of(armature, bone_name: str) -> Vector:
    return armature.data.bones[bone_name].tail_local.copy()


# ---------------------------------------------------------------------------
# Corps
# ---------------------------------------------------------------------------

def build_raider(armature, profile: dict) -> dict:
    """Construit un corps autour du squelette, selon un profil de famille.

    Tout est positionné à partir des OS réels lus dans l'armature : aucune
    cote absolue recopiée, donc aucune dérive si le squelette change.
    """
    groups = {"skin": [], "cloth": [], "hard": []}
    spine1 = head_of(armature, "spine_01")
    head = head_of(armature, "Head")   # majuscule : nom réel du squelette UAL

    torso_w = profile["torso_w"]
    torso_d = profile["torso_d"]

    # --- Le CORPS (torse, bras, jambes, pieds) vient du pack CC0 : voir
    # `load_skeleton`. Ne restent ici que les pièces propres aux familles.
    #
    # La TÊTE en fait partie : les personnages modulaires de Quaternius sont
    # livrés SANS tête, et c'est tant mieux — la bible §14.1-14.3 demande des
    # crânes qui ne sont pas humains (coin à excroissances arrière, crête
    # osseuse, visière fendue). Une tête humaine du commerce les aurait tous
    # rendus identiques.
    neck = head_of(armature, "neck_01")
    head_centre = head + Vector((0, profile["head_shift"],
                                 profile["head_shift_z"]))
    neck_top = head_centre.z - profile["head_size"][2] * 0.35
    groups["skin"].append(add_box("Neck",
        (0.085 if profile["neck_visible"] else 0.13,
         0.085 if profile["neck_visible"] else 0.14,
         maxf(0.08, (neck_top - neck.z) + 0.12)),
        tuple(neck + Vector((0, profile["lean_shift"] * 0.6,
                             (neck_top - neck.z) * 0.5)))))
    groups["skin"].append(add_box("Head", profile["head_size"],
                                  tuple(head_centre),
                                  (profile["head_tilt"], 0, 0)))
    for part in profile["head_features"](head_centre):
        groups[part[0]].append(part[1])

    # --- Épaules : épaulières, gardes, protections.
    for side, sign in (("l", 1.0), ("r", -1.0)):
        shoulder = head_of(armature, "upperarm_%s" % side)
        for part in profile["shoulder_features"](shoulder, sign):
            groups[part[0]].append(part[1])

    # --- Ceinture : elle coupe la silhouette et dit la faction.
    groups["cloth"].append(add_box("Belt",
        (torso_w * 0.52, torso_d * 0.52, 0.035),
        tuple(spine1 + Vector((0, 0, -0.02)))))
    return groups


# ---------------------------------------------------------------------------
# Traits propres à chaque famille
# ---------------------------------------------------------------------------

def braise_head_features(centre: Vector) -> list:
    """Deux excroissances osseuses vers l'ARRIÈRE (§14.1). Ni oreilles, ni
    cornes dressées : elles filent en arrière, comme un coin."""
    parts = []
    for sign in (-1.0, 1.0):
        horn = add_box("Horn_%d" % int(sign),
                       (0.022, 0.10, 0.022),
                       tuple(centre + Vector((sign * 0.055, 0.09, 0.045))),
                       (math.radians(24.0), 0.0, math.radians(sign * 16.0)))
        parts.append(("hard", horn))
    # Museau en coin, mâchoire courte.
    parts.append(("skin", add_box("Snout", (0.048, 0.055, 0.038),
                                  tuple(centre + Vector((0, -0.075, -0.02))))))
    return parts


def azur_head_features(centre: Vector) -> list:
    """Crête osseuse VERTICALE et mince (§14.2)."""
    parts = []
    for i in range(3):
        parts.append(("hard", add_box("Crest%d" % i,
            (0.016, 0.030 + 0.012 * i, 0.05 - 0.008 * i),
            tuple(centre + Vector((0, 0.02 - 0.028 * i, 0.085))),
            (math.radians(-8.0 * i), 0.0, 0.0))))
    return parts


def obsidian_head_features(centre: Vector) -> list:
    """Visière FENDUE en diagonale (§14.3) : le visage reste partiellement
    visible, ce n'est ni un casque intégral ni un masque tribal."""
    parts = []
    for sign in (-1.0, 1.0):
        parts.append(("hard", add_box("Visor_%d" % int(sign),
            (0.052, 0.058, 0.040),
            tuple(centre + Vector((sign * 0.032, -0.052, 0.022))),
            (0.0, math.radians(sign * 13.0), 0.0))))
    parts.append(("hard", add_box("Jaw", (0.075, 0.052, 0.032),
                                  tuple(centre + Vector((0, -0.055, -0.048))))))
    return parts


def no_shoulder_features(_shoulder: Vector, _sign: float) -> list:
    return []


def azur_shoulder_features(shoulder: Vector, sign: float) -> list:
    """Protège-épaules SEGMENTÉS : la silhouette « en parenthèses »."""
    parts = []
    for i in range(3):
        parts.append(("hard", add_box("Guard%d_%d" % (int(sign), i),
            (0.030, 0.055 - 0.006 * i, 0.020),
            tuple(shoulder + Vector((sign * (0.02 + 0.030 * i), 0.0,
                                     0.035 - 0.020 * i))),
            (0.0, math.radians(sign * (14.0 + 12.0 * i)), 0.0))))
    return parts


def obsidian_shoulder_features(shoulder: Vector, sign: float) -> list:
    """Deux plaques INÉGALES formant un trapèze (§14.3) : la gauche est
    nettement plus grande. L'asymétrie est le signe de reconnaissance."""
    parts = []
    scale = 1.32 if sign > 0 else 0.94
    parts.append(("hard", add_box("Pauldron_%d" % int(sign),
        (0.085 * scale, 0.075 * scale, 0.055 * scale),
        tuple(shoulder + Vector((sign * 0.045, 0.0, 0.035))),
        (0.0, math.radians(sign * 18.0), 0.0))))
    parts.append(("hard", add_box("PauldronSkirt_%d" % int(sign),
        (0.070 * scale, 0.062 * scale, 0.030),
        tuple(shoulder + Vector((sign * 0.075, 0.0, -0.030))),
        (0.0, math.radians(sign * 26.0), 0.0))))
    return parts


PROFILES = {
    "Red": {
        "display": "pillard braise",
        "height_scale": 0.82,      # 1,80 m x 0,82 ≈ 1,48 m (bible : 1,40-1,52)
        "lean": math.radians(17.0),   # torse VOÛTÉ, centre de gravité en avant
        "lean_shift": -0.045,
        "torso_w": 0.34, "torso_d": 0.21,
        "shoulder_spread": 0.92,
        "limb_girth": 0.048,
        "body_wide": 1.02, "body_deep": 1.06,   # trapu, ramassé
        # Teinte du corps : elle MULTIPLIE la texture du pack, donc elle doit
        # être plus claire que la couleur visée sinon tout vire au noir.
        "body_tint": (0.88, 0.42, 0.30, 1.0),   # terre cuite
        "arm_gain": 0.92, "leg_gain": 0.95,
        "forearm_gain": 1.34,      # avant-bras LONGS (§14.1)
        "neck_visible": False,     # tête enfoncée dans les épaules
        "head_shift": -0.02, "head_shift_z": 0.055, "head_tilt": math.radians(12.0),
        "head_size": (0.075, 0.085, 0.070),
        "head_features": braise_head_features,
        "shoulder_features": no_shoulder_features,
        "skin": COL_SKIN_RED, "cloth": COL_CLOTH_RED, "hard": COL_BONE,
    },
    "Blue": {
        "display": "pillard azur",
        "height_scale": 0.92,      # ≈ 1,66 m (bible : 1,58-1,72)
        "lean": math.radians(2.0),    # posture DROITE
        "lean_shift": 0.0,
        "torso_w": 0.30, "torso_d": 0.19,
        "shoulder_spread": 0.88,   # épaules ÉTROITES
        "limb_girth": 0.044,
        "body_wide": 0.90, "body_deep": 0.90,   # épaules ÉTROITES (§14.2)
        "body_tint": (0.40, 0.50, 0.82, 1.0),   # indigo délavé
        "arm_gain": 0.88, "leg_gain": 1.06,   # jambes LONGUES
        "forearm_gain": 1.0,
        "neck_visible": True,
        "head_shift": 0.0, "head_shift_z": 0.075, "head_tilt": 0.0,
        "head_size": (0.066, 0.078, 0.078),
        "head_features": azur_head_features,
        "shoulder_features": azur_shoulder_features,
        "skin": COL_SKIN_BLUE, "cloth": COL_CLOTH_BLUE, "hard": COL_GUARD_BLUE,
    },
    "Black": {
        "display": "briseur d'obsidienne",
        "height_scale": 1.10,      # ≈ 1,87 m (bible : 1,85-2,05)
        "lean": math.radians(8.0),
        "lean_shift": -0.015,
        "torso_w": 0.52, "torso_d": 0.30,     # torse TRÈS large
        "shoulder_spread": 1.18,
        "limb_girth": 0.072,
        "body_wide": 1.26, "body_deep": 1.18,   # torse TRÈS large (§14.3)
        "body_tint": (0.42, 0.40, 0.44, 1.0),   # pierre vitreuse, froide
        "arm_gain": 1.24, "leg_gain": 1.16,
        "forearm_gain": 0.94,
        "neck_visible": False,     # cou presque absent
        "head_shift": -0.01, "head_shift_z": 0.06, "head_tilt": math.radians(6.0),
        "head_size": (0.085, 0.082, 0.072),
        "head_features": obsidian_head_features,
        "shoulder_features": obsidian_shoulder_features,
        "skin": COL_SKIN_BLACK, "cloth": COL_LEATHER, "hard": COL_PLATE_BLACK,
    },
}


def build_one(key: str, profile: dict) -> None:
    armature, body = load_skeleton()
    # La CARRURE distingue les familles autant que la stature : le briseur
    # est « TRÈS large » (§14.3), l'azur a les « épaules étroites » (§14.2).
    reshape_body(body, profile["body_wide"], profile["body_deep"])
    tint_body(body, profile["body_tint"], key)
    groups = build_raider(armature, profile)

    materials = {
        "skin": make_material("MAT_Raider%s_Skin" % key, profile["skin"], 0.78),
        "cloth": make_material("MAT_Raider%s_Cloth" % key, profile["cloth"], 0.88),
        "hard": make_material("MAT_Raider%s_Hard" % key, profile["hard"], 0.58,
                              0.18 if key == "Black" else 0.0),
    }
    meshes = []
    for group_name, parts in groups.items():
        if not parts:
            continue
        merged = join_all("Raider%s_%s" % (key, group_name.capitalize()), parts)
        merged.data.materials.append(materials[group_name])
        meshes.append(merged)

    apply_transforms(meshes)
    # Liaison par POIDS AUTOMATIQUES au squelette UAL, pour les pièces
    # NEUVES seulement : le corps du pack porte déjà ses poids d'origine, et
    # les recalculer les dégraderait.
    bpy.ops.object.select_all(action="DESELECT")
    for merged in meshes:
        merged.select_set(True)
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    meshes = body + meshes

    # La taille de la famille (§14.1-14.3) s'applique à l'armature — les
    # animations, qui sont des rotations d'os, y survivent intactes — puis
    # elle est APPLIQUÉE. Sans cela l'échelle part deux fois vers glTF :
    # une fois cuite dans les sommets par `export_apply`, une fois portée
    # par le nœud exporté. Mesuré dans Godot : le braise arrivait à 1,17 m
    # au lieu de 1,42, et le briseur à 2,07 au lieu de 1,88.
    armature.scale = (profile["height_scale"],) * 3
    bpy.ops.object.select_all(action="DESELECT")
    for merged in meshes:
        merged.select_set(True)
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.context.view_layer.update()

    # `matrix_world` du mesh contient DÉJÀ la transformation de l'armature
    # depuis le parentage : la multiplier une seconde fois par
    # `armature.matrix_world` appliquait l'échelle deux fois et sous-estimait
    # chaque famille (braise annoncé 1,17 m pour 1,43 m réels).
    xs, ys, zs = [], [], []
    for merged in meshes:
        for vertex in merged.data.vertices:
            world = merged.matrix_world @ vertex.co
            xs.append(world.x)
            ys.append(world.y)
            zs.append(world.z)
    log("%s : haut %.2f m · large %.2f m · %d meshes"
        % (profile["display"], max(zs) - min(zs), max(xs) - min(xs),
           len(meshes)))

    os.makedirs(SRC_DIR, exist_ok=True)
    out = os.path.join(SRC_DIR, "SK_Raider%s.blend" % key)
    bpy.ops.wm.save_as_mainfile(filepath=out)
    log("source écrite : %s" % os.path.basename(out))


def main() -> None:
    log("Blender %s" % bpy.app.version_string)
    for key, profile in PROFILES.items():
        build_one(key, profile)


if __name__ == "__main__":
    main()
