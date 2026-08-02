"""Rendus de contrôle ART-P0R : SM_WornSword sous quatre angles (Cycles CPU).

Preuves du gate visuel — gros plan trois-quarts, FACE (plat de lame), PROFIL
(tranche), et vue entière trois-quarts, sur fond contrasté. Chaque image vient
du fichier source réel.

Usage :
    blender --background source_assets/weapons/SM_WornSword.blend \
        --python tools/blender/render_worn_sword.py
"""

import math
import os

import bpy
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "evidence", "artP0R")


def setup_stage(scene):
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 96
    scene.cycles.use_denoising = False   # Blender Ubuntu sans OIDN (mesuré)
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 1200

    world = bpy.data.worlds.new("RenderWorld")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (
        0.13, 0.15, 0.19, 1.0)   # fond CONTRASTÉ, ni noir ni clair
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.7
    scene.world = world

    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 4.0
    sun.data.color = (1.0, 0.87, 0.64)
    sun.rotation_euler = (math.radians(50.0), math.radians(-18.0), 0.0)
    scene.collection.objects.link(sun)
    fill = bpy.data.objects.new("Fill", bpy.data.lights.new("Fill", "AREA"))
    fill.data.energy = 55.0
    fill.data.size = 1.8
    fill.data.color = (0.60, 0.70, 0.86)
    fill.location = (-0.7, -0.9, 0.5)
    fill.rotation_euler = (math.radians(60.0), 0.0, math.radians(-140.0))
    scene.collection.objects.link(fill)


def look_at(camera, target):
    direction = target - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def render_view(scene, sword, name, sword_rotation, camera_offset, lens):
    sword.rotation_euler = sword_rotation
    bpy.context.view_layer.update()
    mid = sword.matrix_world @ Vector((0.0, 0.28, 0.0))
    camera = scene.camera
    camera.location = mid + Vector(camera_offset)
    camera.data.lens = lens
    look_at(camera, mid)
    scene.render.filepath = os.path.join(OUT_DIR, "blender_%s.png" % name)
    bpy.ops.render.render(write_still=True)
    print("[render] écrit : %s" % scene.render.filepath)


def main():
    scene = bpy.context.scene
    setup_stage(scene)
    sword = bpy.data.objects["SM_WornSword_LOD0"]
    camera = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(camera)
    scene.camera = camera
    os.makedirs(OUT_DIR, exist_ok=True)

    # Gros plan trois-quarts sur garde/poignée/bas de lame.
    sword.rotation_euler = (0.0, math.radians(18.0), math.radians(-32.0))
    bpy.context.view_layer.update()
    grip = sword.matrix_world @ Vector((0.0, 0.05, 0.0))
    camera.location = grip + Vector((0.24, -0.50, 0.30))
    camera.data.lens = 68.0
    look_at(camera, grip)
    scene.render.filepath = os.path.join(OUT_DIR, "blender_closeup.png")
    bpy.ops.render.render(write_still=True)
    print("[render] écrit : %s" % scene.render.filepath)

    # FACE : le plat de lame vers la caméra (gouttière et entailles lisibles).
    render_view(scene, sword, "face", (0.0, 0.0, math.radians(-90.0)),
        (0.0, 0.0, 1.25), 40.0)
    # PROFIL : la tranche — l'épaisseur réelle se lit.
    render_view(scene, sword, "profil", (math.radians(90.0), 0.0,
        math.radians(-90.0)), (0.0, 0.0, 1.25), 40.0)
    # TROIS-QUARTS entière.
    render_view(scene, sword, "threequarter", (0.0, math.radians(18.0),
        math.radians(-32.0)), (0.42, -1.18, 0.66), 46.0)


if __name__ == "__main__":
    main()
