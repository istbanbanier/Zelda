"""Rendu de contrôle ART-P0 : gros plan Blender de SM_WornSword (Cycles CPU).

Preuve du gate visuel — le rendu vient du fichier source réel, jamais d'une
image fabriquée ailleurs.

Usage :
    blender --background source_assets/weapons/SM_WornSword.blend \
        --python tools/blender/render_worn_sword.py
"""

import math
import os

import bpy

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "evidence", "artP0", "blender_closeup.png")


def main():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 96
    # Ce Blender Ubuntu est compilé sans OpenImageDenoiser (mesuré) :
    # débrancher le débruiteur, compenser par les échantillons.
    scene.cycles.use_denoising = False
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 1200
    scene.render.filepath = OUT

    world = bpy.data.worlds.new("RenderWorld")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (
        0.09, 0.10, 0.12, 1.0)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.6
    scene.world = world

    sword = bpy.data.objects["SM_WornSword_LOD0"]
    # À plat, lame en diagonale du cadre — l'épée ENTIÈRE se lit, la face de
    # lame regarde la caméra (patine et entailles visibles).
    sword.rotation_euler = (0.0, math.radians(18.0), math.radians(-32.0))

    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 4.0
    sun.data.color = (1.0, 0.86, 0.62)          # fin d'après-midi (§3.4)
    sun.rotation_euler = (math.radians(50.0), math.radians(-18.0), 0.0)
    scene.collection.objects.link(sun)
    fill = bpy.data.objects.new("Fill", bpy.data.lights.new("Fill", "AREA"))
    fill.data.energy = 45.0
    fill.data.size = 1.6
    fill.data.color = (0.62, 0.72, 0.85)        # ombre froide (§3.4)
    fill.location = (-0.7, -0.9, 0.4)
    fill.rotation_euler = (math.radians(65.0), 0.0, math.radians(-140.0))
    scene.collection.objects.link(fill)

    # Milieu réel de l'épée APRÈS rotation — calculé, pas deviné (le cadrage
    # précédent visait un point estimé et coupait la poignée).
    bpy.context.view_layer.update()
    from mathutils import Vector
    mid = sword.matrix_world @ Vector((0.0, 0.22, 0.0))
    target = bpy.data.objects.new("Target", None)
    target.location = mid
    scene.collection.objects.link(target)
    camera = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    camera.location = (mid.x + 0.36, mid.y - 1.08, mid.z + 0.66)
    camera.data.lens = 52.0
    track = camera.constraints.new("TRACK_TO")
    track.target = target
    scene.collection.objects.link(camera)
    scene.camera = camera

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    bpy.ops.render.render(write_still=True)
    print("[render] écrit : %s" % OUT)


if __name__ == "__main__":
    main()
