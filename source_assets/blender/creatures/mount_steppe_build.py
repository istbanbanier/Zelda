"""SM_Mount_Steppe — « coureur des steppes », monture ORIGINALE de la Vallée de Néris.

Quadrupède trapu NON équin-générique : silhouette entre l'élan sans bois massifs
et le bouquetin — encolure épaisse, garrot marqué (~1,55 m), croupe plus basse,
queue courte touffue, tête allongée à museau carré, DEUX petites cornes
recourbées vers l'arrière. Selle de cuir + sangle + couverture turquoise
désaturé (signature du héros) + licol simple. Aucun contenu Nintendo : formes
construites ici depuis des primitives, aucune référence à une licence.

Construction DÉTERMINISTE par code (aucun aléatoire ; les asymétries sont des
décalages fixes). Un seul mesh statique fusionné, pose debout neutre.
Pas de rig, pas d'animation.

Conventions du dépôt (.claude/rules/assets.md, MASTER_SPEC §7.15) :
- 1 unité = 1 m ; Blender Z-up ; l'animal regarde -Y en Blender ;
  l'export glTF (+Y up) convertit vers -Z avant / +Y up côté Godot.
- Origine au sol entre les quatre sabots ; min Y (glTF) ~ 0 ; X/Z centrés.
- 3 000 à 8 000 triangles ; pas de texture — 5 matériaux baseColor désaturés.
- Aucune caméra ni lumière exportée : les caméras de contrôle sont créées
  APRÈS l'export .glb, uniquement pour les rendus de prévisualisation.

Usage :
    blender --background --python source_assets/blender/creatures/mount_steppe_build.py
Sorties :
    assets/characters/mount/SM_Mount_Steppe.glb
    $MOUNT_PREVIEW_DIR/mount_preview_side.png et mount_preview_34.png
    (MOUNT_PREVIEW_DIR facultatif ; défaut : répertoire temporaire système)
"""

import math
import os
import tempfile

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
EXPORT_PATH = os.path.join(ROOT, "assets", "characters", "mount", "SM_Mount_Steppe.glb")
PREVIEW_DIR = os.environ.get("MOUNT_PREVIEW_DIR", tempfile.gettempdir())

TRI_MIN, TRI_MAX, TRI_TARGET = 3000, 8000, 7000

# Palette du monde (§1.4 de la bible) — désaturée, baseColor uniquement.
COL_COAT = (0.42, 0.34, 0.27, 1.0)      # robe brun-gris
COL_BELLY = (0.72, 0.65, 0.52, 1.0)     # ventre / museau crème
COL_HORN = (0.25, 0.22, 0.20, 1.0)      # sabots / cornes sombres
COL_SADDLE = (0.40, 0.25, 0.16, 1.0)    # cuir brun
COL_BLANKET = (0.09, 0.45, 0.47, 1.0)   # turquoise désaturé — signature héros


def log(message: str) -> None:
    print("[mount_steppe] %s" % message)


def make_material(name: str, rgba: tuple) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = rgba
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Metallic"].default_value = 0.0
    mat.diffuse_color = rgba
    return mat


def loft(name: str, rings: list, axis: str, sides: int, mat: bpy.types.Material,
         cap_start: bool = True, cap_end: bool = True, twist: float = 0.0,
         subsurf: int = 0) -> bpy.types.Object:
    """Tube lofté déterministe.

    Chaque ring = ((cx, cy, cz), (r1, r2)). axis='Y' : sections dans le plan
    X-Z (tube couché le long de Y). axis='Z' : sections dans le plan X-Y
    (tube vertical). Les centres peuvent dériver librement -> formes courbées.
    """
    bm = bmesh.new()
    prev = None
    for (cx, cy, cz), (r1, r2) in rings:
        verts = []
        for i in range(sides):
            a = 2.0 * math.pi * i / sides + twist
            if axis == "Y":
                pos = (cx + r1 * math.cos(a), cy, cz + r2 * math.sin(a))
            else:
                pos = (cx + r1 * math.cos(a), cy + r2 * math.sin(a), cz)
            verts.append(bm.verts.new(pos))
        if prev is None:
            if cap_start:
                bm.faces.new(verts)
        else:
            for i in range(sides):
                bm.faces.new((prev[i], prev[(i + 1) % sides],
                              verts[(i + 1) % sides], verts[i]))
        prev = verts
    if cap_end:
        bm.faces.new(prev)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    mesh.materials.append(mat)
    for poly in mesh.polygons:
        poly.use_smooth = True
    if subsurf > 0:
        mod = obj.modifiers.new("Subdiv", "SUBSURF")
        mod.levels = subsurf
        mod.render_levels = subsurf
    return obj


def triangle_count(mesh: bpy.types.Mesh) -> int:
    return sum(max(0, len(p.vertices) - 2) for p in mesh.polygons)


def build() -> bpy.types.Object:
    mat_coat = make_material("MAT_Mount_Coat", COL_COAT)
    mat_belly = make_material("MAT_Mount_Belly", COL_BELLY)
    mat_horn = make_material("MAT_Mount_Horn", COL_HORN)
    mat_saddle = make_material("MAT_Mount_Saddle", COL_SADDLE)
    mat_blanket = make_material("MAT_Mount_Blanket", COL_BLANKET)

    parts = []

    # --- TORSO : garrot marqué (haut ~1,56), croupe plus basse (~1,38). ---
    parts.append(loft("torso", [
        ((0.0, -0.62, 1.14), (0.12, 0.17)),
        ((0.0, -0.55, 1.16), (0.25, 0.31)),
        ((0.0, -0.40, 1.17), (0.33, 0.39)),   # garrot -> z max 1.56, poitrail 0.78
        ((0.0, -0.10, 1.11), (0.35, 0.36)),
        ((0.0, 0.25, 1.09), (0.36, 0.34)),
        ((0.0, 0.60, 1.10), (0.33, 0.32)),
        ((0.0, 0.85, 1.10), (0.29, 0.28)),    # croupe -> z max 1.38
        ((0.0, 1.05, 1.07), (0.19, 0.21)),
        ((0.0, 1.14, 1.05), (0.08, 0.10)),
    ], axis="Y", sides=14, mat=mat_coat, subsurf=1))

    # --- VENTRE crème, légèrement débordant sous le torse. ---
    parts.append(loft("belly", [
        ((0.0, -0.42, 0.95), (0.22, 0.17)),
        ((0.0, -0.05, 0.90), (0.28, 0.17)),
        ((0.0, 0.35, 0.91), (0.27, 0.16)),
        ((0.0, 0.70, 0.96), (0.20, 0.13)),
    ], axis="Y", sides=12, mat=mat_belly, subsurf=1))

    # --- ENCOLURE épaisse, montante vers l'avant (-Y). ---
    parts.append(loft("neck", [
        ((0.0, -0.36, 1.28), (0.24, 0.30)),
        ((0.0, -0.50, 1.41), (0.20, 0.26)),
        ((0.0, -0.64, 1.54), (0.17, 0.21)),
        ((0.0, -0.76, 1.65), (0.14, 0.17)),
    ], axis="Y", sides=12, mat=mat_coat, subsurf=1))

    # --- TÊTE allongée (crâne robe + museau carré crème). Légère asymétrie. ---
    parts.append(loft("skull", [
        ((0.005, -0.70, 1.72), (0.12, 0.13)),
        ((0.005, -0.83, 1.74), (0.14, 0.14)),
        ((0.005, -0.93, 1.70), (0.125, 0.115)),
        ((0.005, -1.00, 1.66), (0.11, 0.09)),
    ], axis="Y", sides=10, mat=mat_coat))
    parts.append(loft("muzzle", [
        ((0.005, -0.97, 1.64), (0.100, 0.088)),
        ((0.005, -1.06, 1.61), (0.090, 0.082)),
        ((0.005, -1.14, 1.59), (0.082, 0.075)),
    ], axis="Y", sides=8, mat=mat_belly, twist=math.pi / 8.0))

    # --- DEUX CORNES courtes recourbées vers l'ARRIÈRE (+Y), asymétriques. ---
    parts.append(loft("horn_l", [
        ((-0.075, -0.72, 1.80), (0.035, 0.035)),
        ((-0.088, -0.68, 1.87), (0.028, 0.028)),
        ((-0.100, -0.62, 1.91), (0.019, 0.019)),
        ((-0.112, -0.56, 1.93), (0.009, 0.009)),
    ], axis="Z", sides=8, mat=mat_horn))
    parts.append(loft("horn_r", [
        ((0.075, -0.72, 1.80), (0.035, 0.035)),
        ((0.086, -0.69, 1.865), (0.028, 0.028)),
        ((0.097, -0.63, 1.905), (0.019, 0.019)),
        ((0.108, -0.575, 1.92), (0.009, 0.009)),
    ], axis="Z", sides=8, mat=mat_horn))

    # --- QUATRE JAMBES + SABOTS, décalages fixes (pas de symétrie parfaite). ---
    legs = [  # (x, y, épaisseur relative) — membres FORTS : bête trapue
        (-0.215, -0.40, 1.28),   # avant gauche
        (0.21, -0.365, 1.28),    # avant droit
        (-0.21, 0.83, 1.48),     # arrière gauche (plus fort)
        (0.22, 0.775, 1.48),     # arrière droit
    ]
    for idx, (lx, ly, thick) in enumerate(legs):
        parts.append(loft("leg_%d" % idx, [
            ((lx, ly, 0.10), (0.055 * thick, 0.055 * thick)),
            ((lx, ly + 0.01, 0.35), (0.060 * thick, 0.065 * thick)),
            ((lx, ly - 0.02, 0.62), (0.075 * thick, 0.082 * thick)),
            ((lx, ly, 1.05), (0.10 * thick, 0.12 * thick)),
        ], axis="Z", sides=10, mat=mat_coat))
        parts.append(loft("hoof_%d" % idx, [
            ((lx, ly, 0.0), (0.078, 0.083)),
            ((lx, ly, 0.06), (0.076, 0.080)),
            ((lx, ly, 0.12), (0.064, 0.066)),
        ], axis="Z", sides=10, mat=mat_horn))

    # --- QUEUE courte et touffue, tombante, dérive latérale fixe. ---
    parts.append(loft("tail", [
        ((0.010, 1.10, 1.10), (0.050, 0.055)),
        ((0.020, 1.17, 1.03), (0.095, 0.105)),
        ((0.025, 1.22, 0.94), (0.065, 0.075)),
        ((0.030, 1.25, 0.87), (0.025, 0.030)),
    ], axis="Y", sides=8, mat=mat_coat, subsurf=1))

    # --- COUVERTURE turquoise drapée sur le dos. ---
    parts.append(loft("blanket", [
        ((0.0, -0.30, 1.40), (0.34, 0.100)),
        ((0.0, -0.05, 1.38), (0.40, 0.115)),
        ((0.0, 0.30, 1.38), (0.39, 0.110)),
        ((0.0, 0.50, 1.39), (0.35, 0.095)),
    ], axis="Y", sides=12, mat=mat_blanket, subsurf=1))

    # --- SELLE cuir (assise ~1,58 m) + pommeau + troussequin. ---
    parts.append(loft("saddle", [
        ((0.0, -0.20, 1.50), (0.16, 0.070)),
        ((0.0, 0.00, 1.50), (0.20, 0.085)),
        ((0.0, 0.22, 1.51), (0.17, 0.075)),
    ], axis="Y", sides=12, mat=mat_saddle, subsurf=1))
    parts.append(loft("pommel", [
        ((0.0, -0.24, 1.50), (0.060, 0.060)),
        ((0.0, -0.26, 1.60), (0.035, 0.035)),
    ], axis="Z", sides=8, mat=mat_saddle))
    parts.append(loft("cantle", [
        ((0.0, 0.27, 1.50), (0.070, 0.070)),
        ((0.0, 0.29, 1.585), (0.040, 0.040)),
    ], axis="Z", sides=8, mat=mat_saddle))

    # --- SANGLE : anneau de cuir autour du ventre. ---
    parts.append(loft("girth", [
        ((0.0, -0.03, 1.10), (0.375, 0.385)),
        ((0.0, 0.05, 1.10), (0.375, 0.385)),
    ], axis="Y", sides=14, mat=mat_saddle))

    # --- LICOL : muserolle + têtière + deux montants latéraux. ---
    parts.append(loft("halter_nose", [
        ((0.005, -1.06, 1.63), (0.095, 0.085)),
        ((0.005, -1.02, 1.63), (0.095, 0.085)),
    ], axis="Y", sides=10, mat=mat_saddle))
    parts.append(loft("halter_crown", [
        ((0.005, -0.72, 1.74), (0.125, 0.140)),
        ((0.005, -0.68, 1.74), (0.125, 0.140)),
    ], axis="Y", sides=10, mat=mat_saddle))
    for side, sx in (("l", -1.0), ("r", 1.0)):
        parts.append(loft("halter_strap_%s" % side, [
            ((sx * 0.098, -1.04, 1.64), (0.012, 0.012)),
            ((sx * 0.118, -0.72, 1.73), (0.012, 0.012)),
        ], axis="Y", sides=6, mat=mat_saddle))

    # --- Appliquer les subdivisions PUIS fusionner en un seul mesh. ---
    for obj in parts:
        if obj.modifiers:
            bpy.context.view_layer.objects.active = obj
            for mod in list(obj.modifiers):
                bpy.ops.object.modifier_apply(modifier=mod.name)

    for obj in bpy.context.scene.objects:
        obj.select_set(obj in parts)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    mount = bpy.context.view_layer.objects.active
    mount.name = "SM_Mount_Steppe"
    mount.data.name = "SM_Mount_Steppe"

    # --- Orientation finale : -Z avant côté Godot. ---
    # L'exporteur glTF (+Y up) mappe Blender (x, y, z) -> glTF (x, z, -y) :
    # c'est Blender +Y qui devient le -Z avant de Godot (convention suivie
    # par les créatures existantes du dépôt, cf. tools/blender/make_creatures.py
    # — poitrail à +Y, queue à -Y). Le modèle est bâti tête vers -Y, donc une
    # rotation rigide de 180 degrés autour de Z le met dans la convention.
    mount.data.transform(Matrix.Rotation(math.pi, 4, "Z"))

    # --- Budget : décimer si au-dessus du plafond. ---
    tris = triangle_count(mount.data)
    log("triangles avant contrôle de budget : %d" % tris)
    if tris > TRI_MAX:
        mod = mount.modifiers.new("Decimate", "DECIMATE")
        mod.ratio = float(TRI_TARGET) / float(tris)
        bpy.ops.object.modifier_apply(modifier=mod.name)
        tris = triangle_count(mount.data)
        log("triangles après décimation : %d" % tris)
    if tris < TRI_MIN:
        log("AVERTISSEMENT : %d triangles < plancher %d" % (tris, TRI_MIN))

    # --- Origine au sol entre les quatre sabots ; X centré ; min Z = 0. ---
    xs = [v.co.x for v in mount.data.vertices]
    zs = [v.co.z for v in mount.data.vertices]
    hoof_mid_y = -sum(l[1] for l in legs) / len(legs)  # négatif : rotation 180°
    offset = Vector((-(max(xs) + min(xs)) / 2.0, -hoof_mid_y, -min(zs)))
    mount.data.transform(Matrix.Translation(offset))
    log("recalage origine : %s" % [round(v, 4) for v in offset])

    # --- Ombrage : smooth + auto-smooth 40 degrés (painterly low-poly). ---
    mount.data.use_auto_smooth = True
    mount.data.auto_smooth_angle = math.radians(40.0)

    # --- UV0 (évite l'avertissement de gltf_inspect ; pas de texture). ---
    try:
        bpy.context.view_layer.objects.active = mount
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.02)
        bpy.ops.object.mode_set(mode="OBJECT")
        log("UV0 générés (smart project)")
    except RuntimeError as exc:
        if bpy.context.object and bpy.context.object.mode != "OBJECT":
            bpy.ops.object.mode_set(mode="OBJECT")
        log("UV0 non générés (%s) — avertissement gltf_inspect attendu" % exc)

    return mount


def export_glb(path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        export_yup=True,       # Blender Z-up -> glTF/Godot Y-up ; -Y -> -Z avant
        export_apply=True,
    )
    log("export : %s (%d octets)" % (path, os.path.getsize(path)))


def render_previews(target: bpy.types.Object) -> None:
    """Rendus de contrôle — caméra et lumière créées APRÈS l'export glTF."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 24
    scene.cycles.device = "CPU"
    scene.cycles.use_denoising = False  # ce Blender est bâti sans OpenImageDenoiser
    scene.view_settings.view_transform = "Standard"  # couleurs non délavées par AgX
    scene.render.resolution_x = 800
    scene.render.resolution_y = 600

    world = bpy.data.worlds.new("PreviewWorld")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs[0].default_value = (0.85, 0.88, 0.90, 1.0)
    bg.inputs[1].default_value = 1.0
    scene.world = world

    sun_data = bpy.data.lights.new("PreviewSun", type="SUN")
    sun_data.energy = 3.0
    sun = bpy.data.objects.new("PreviewSun", sun_data)
    scene.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(50.0), 0.0, math.radians(-30.0))

    cam_data = bpy.data.cameras.new("PreviewCam")
    cam = bpy.data.objects.new("PreviewCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam

    views = {  # la tête est à +Y après la rotation de mise en convention
        "mount_preview_side.png": (Vector((4.2, 0.1, 1.2)), Vector((0.0, 0.0, 1.0))),
        "mount_preview_34.png": (Vector((2.8, 3.0, 2.0)), Vector((0.0, -0.1, 0.95))),
    }
    os.makedirs(PREVIEW_DIR, exist_ok=True)
    for filename, (origin, look_at) in views.items():
        cam.location = origin
        direction = look_at - origin
        cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(PREVIEW_DIR, filename)
        bpy.ops.render.render(write_still=True)
        log("préviz : %s" % scene.render.filepath)

    # Nettoyage : la scène ne garde que la monture.
    for obj in (cam, sun):
        bpy.data.objects.remove(obj, do_unlink=True)


def main() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mount = build()

    dims = mount.dimensions
    log("dimensions Blender (X larg, Y long, Z haut) : %.3f x %.3f x %.3f"
        % (dims.x, dims.y, dims.z))
    log("triangles finaux : %d ; matériaux : %d"
        % (triangle_count(mount.data), len(mount.data.materials)))

    export_glb(EXPORT_PATH)
    render_previews(mount)
    log("TERMINÉ")


if __name__ == "__main__":
    main()
