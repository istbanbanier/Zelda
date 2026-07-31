"""Génère les assets de test du pipeline Phase 0.5 (MASTER_SPEC §7.15).

Produit deux fichiers .blend sources, sans dépendre d'aucun asset externe :
  1. SM_TestCube      — mesh statique, 1 m d'arête, matériau nommé, UV, LOD0
  2. SK_TestRigAnim   — mesh skinné + armature 2 os + clip animé bouclé

Ces objets n'entrent pas dans le jeu : ils existent pour prouver que la chaîne
Blender -> glTF -> Godot transporte correctement échelle, orientation, pivot,
matériaux, armature et animation.

Usage :
    blender --background --python tools/blender/make_test_assets.py
"""

import math
import os
import sys

import bpy
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC_DIR = os.path.join(ROOT, "source_assets", "blender", "props")


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    # Convention projet : unités métriques, 1 unité Godot = 1 m.
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0


def make_static_cube() -> str:
    """Cube 1 m, origine au centre de la base, matériau + UV."""
    reset_scene()
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.5))
    cube = bpy.context.active_object
    cube.name = "SM_TestCube_LOD0"
    cube.data.name = "SM_TestCube_LOD0_mesh"

    # Pivot intentionnel : bas de l'objet au sol (Z=0), exigence §7.15.
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    cube.location = (0.0, 0.0, 0.0)

    # Rotation/échelle appliquées avant export.
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    mat = bpy.data.materials.new(name="MAT_TestCube")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    # Ocre roche de la palette ancre (#9B6842) — sRGB -> linéaire approximé.
    bsdf.inputs["Base Color"].default_value = (0.333, 0.144, 0.060, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.72
    bsdf.inputs["Metallic"].default_value = 0.0
    cube.data.materials.append(mat)

    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")

    path = os.path.join(SRC_DIR, "SM_TestCube.blend")
    bpy.ops.wm.save_as_mainfile(filepath=path)
    return path


def make_rigged_animation() -> str:
    """Cylindre skinné sur 2 os avec un clip bouclé de 24 frames."""
    reset_scene()
    scene = bpy.context.scene

    bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=2.0, location=(0.0, 0.0, 1.0))
    body = bpy.context.active_object
    body.name = "SK_TestRig"
    body.data.name = "SK_TestRig_mesh"
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    body.location = (0.0, 0.0, 0.0)

    mat = bpy.data.materials.new(name="MAT_TestRig")
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (
        0.008, 0.283, 0.331, 1.0,  # turquoise #168F9B
    )
    body.data.materials.append(mat)

    bpy.ops.object.armature_add(location=(0.0, 0.0, 0.0))
    arm = bpy.context.active_object
    arm.name = "ARM_TestRig"
    arm.data.name = "ARM_TestRig_data"

    bpy.ops.object.mode_set(mode="EDIT")
    edit_bones = arm.data.edit_bones
    root_bone = edit_bones[0]
    root_bone.name = "bone_root"
    root_bone.head = Vector((0.0, 0.0, 0.0))
    root_bone.tail = Vector((0.0, 0.0, 1.0))
    upper = edit_bones.new("bone_upper")
    upper.head = Vector((0.0, 0.0, 1.0))
    upper.tail = Vector((0.0, 0.0, 2.0))
    upper.parent = root_bone
    upper.use_connect = True
    bpy.ops.object.mode_set(mode="OBJECT")

    # Skinning par poids automatiques.
    body.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")

    # Clip bouclé : la pose de la frame 1 est identique à celle de la frame 25,
    # sinon la boucle « saute » à l'import (exigence de validation §7.15).
    scene.frame_start = 1
    scene.frame_end = 24
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    pose_bone = arm.pose.bones["bone_upper"]
    pose_bone.rotation_mode = "QUATERNION"

    keys = [(1, 0.0), (7, 0.35), (13, 0.0), (19, -0.35), (25, 0.0)]
    for frame, angle in keys:
        scene.frame_set(frame)
        pose_bone.rotation_quaternion = (
            math.cos(angle / 2.0), math.sin(angle / 2.0), 0.0, 0.0,
        )
        pose_bone.keyframe_insert(data_path="rotation_quaternion", frame=frame)
    bpy.ops.object.mode_set(mode="OBJECT")

    if arm.animation_data and arm.animation_data.action:
        arm.animation_data.action.name = "AN_TestRig_Idle"

    path = os.path.join(SRC_DIR, "SK_TestRigAnim.blend")
    bpy.ops.wm.save_as_mainfile(filepath=path)
    return path


def main() -> None:
    os.makedirs(SRC_DIR, exist_ok=True)
    print("[make_test_assets] Blender %s" % bpy.app.version_string)
    print("[make_test_assets] statique -> %s" % make_static_cube())
    print("[make_test_assets] rig+anim -> %s" % make_rigged_animation())
    print("[make_test_assets] OK")


if __name__ == "__main__":
    main()
    sys.exit(0)
