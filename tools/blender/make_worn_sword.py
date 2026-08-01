"""ART-P0 — fabrique l'Épée usée (SM_WornSword), premier asset de PRODUCTION.

Création originale du projet, entièrement procédurale et REPRODUCTIBLE :
géométrie bmesh (aucune primitive extrudée brute), UV posés par régions
d'atlas, textures stylisées générées en numpy (couleur + metallic-roughness),
matériau Principled unique exportable en glTF 2.0.

Direction (ordre ART-P0) : lame de fer patinée à usure visible, arêtes
biseautées (section en diamant facettée), garde de bronze asymétrique,
poignée de cuir sombre à gorges, pommeau de bronze vieilli, très légers
détails ivoire, AUCUN cyan, aucun symbole d'une licence existante.

Origine au CENTRE DE LA PRISE (§7.15 : pivot intentionnel), lame vers +Y.
Échelle métrique : lame 0,78 m, longueur totale ≈ 0,97 m.

Usage :
    blender --background --python tools/blender/make_worn_sword.py
Sorties :
    source_assets/weapons/SM_WornSword.blend
    source_assets/weapons/textures/T_WornSword_BaseColor.png
    source_assets/weapons/textures/T_WornSword_MR.png
"""

import math
import os
import random

import bmesh
import bpy
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC_DIR = os.path.join(ROOT, "source_assets", "weapons")
TEX_DIR = os.path.join(SRC_DIR, "textures")

SEED = 20260801
TEX_SIZE = 512

# Régions UV de l'atlas (u0, v0, u1, v1) — les textures sont peintes sur les
# MÊMES rectangles : la correspondance est structurelle, pas devinée.
UV_BLADE = (0.010, 0.020, 0.490, 0.980)
UV_GRIP = (0.510, 0.020, 0.730, 0.480)
UV_GUARD = (0.510, 0.520, 0.730, 0.980)
UV_POMMEL = (0.750, 0.520, 0.980, 0.980)
UV_IVORY = (0.750, 0.020, 0.980, 0.200)

BLADE_LEN = 0.78
BLADE_W = 0.030          # demi-largeur à la base
GRIP_TOP = -0.012
GRIP_BOT = -0.150
POMMEL_Y = -0.168


def ring_diamond(bm, y, half_w, half_t, x_shift=0.0):
    """Section de lame : diamant facetté à 6 sommets (arêtes biseautées)."""
    pts = [
        (half_w + x_shift, y, 0.0),
        (0.45 * half_w + x_shift, y, half_t),
        (-0.45 * half_w + x_shift, y, half_t),
        (-half_w + x_shift, y, 0.0),
        (-0.45 * half_w + x_shift, y, -half_t),
        (0.45 * half_w + x_shift, y, -half_t),
    ]
    return [bm.verts.new(p) for p in pts]


def bridge(bm, ring_a, ring_b):
    faces = []
    n = len(ring_a)
    for i in range(n):
        faces.append(bm.faces.new((
            ring_a[i], ring_a[(i + 1) % n], ring_b[(i + 1) % n], ring_b[i])))
    return faces


def uv_rect(region, u, v):
    u0, v0, u1, v1 = region
    return (u0 + (u1 - u0) * min(max(u, 0.0), 1.0),
            v0 + (v1 - v0) * min(max(v, 0.0), 1.0))


def build_blade():
    """Lame effilée, arête centrale, deux ENTAILLES d'usure asymétriques."""
    bm = bmesh.new()
    sections = [
        (0.000, 1.00, 1.00), (0.140, 0.95, 0.97), (0.320, 0.87, 0.89),
        (0.500, 0.77, 0.79), (0.640, 0.63, 0.68), (0.720, 0.43, 0.52),
    ]
    rings = []
    for y, wf, tf in sections:
        rings.append(ring_diamond(bm, y, BLADE_W * wf, 0.0060 * tf,
            x_shift=0.0008 * math.sin(y * 9.0)))
    # Entailles : deux sommets d'arête repoussés vers l'axe — l'usure se lit
    # dans la SILHOUETTE, pas seulement dans la texture.
    rings[2][0].co.x *= 0.84
    rings[4][3].co.x *= 0.82
    for a, b in zip(rings, rings[1:]):
        bridge(bm, a, b)
    tip = bm.verts.new((0.0015, BLADE_LEN, 0.0))
    last = rings[-1]
    for i in range(6):
        bm.faces.new((last[i], last[(i + 1) % 6], tip))
    bm.faces.new(tuple(reversed(rings[0])))
    # UV planaires symétriques : u depuis x (les arêtes tombent aux bords de
    # la région — la bande « fil affûté » de la texture y correspond).
    uv = bm.loops.layers.uv.new("UVMap")
    for face in bm.faces:
        for loop in face.loops:
            co = loop.vert.co
            loop[uv].uv = uv_rect(UV_BLADE, co.x / (2.0 * BLADE_W) + 0.5,
                co.y / BLADE_LEN)
    return bm


def build_guard():
    """Garde de bronze ASYMÉTRIQUE : bras long incliné +X, bras court -X."""
    bm = bmesh.new()
    profile = [
        (-0.055, 0.0075, 0.0062, 0.000),
        (-0.024, 0.0115, 0.0095, 0.000),
        (0.024, 0.0115, 0.0095, 0.000),
        (0.078, 0.0068, 0.0058, -0.007),
    ]
    rings = []
    for x, hy, hz, dy in profile:
        pts = [(x, dy + hy, hz), (x, dy + hy, -hz),
               (x, dy - hy, -hz), (x, dy - hy, hz)]
        rings.append([bm.verts.new(p) for p in pts])
    for a, b in zip(rings, rings[1:]):
        bridge(bm, a, b)
    bm.faces.new(tuple(reversed(rings[0])))
    bm.faces.new(tuple(rings[-1]))
    bmesh.ops.bevel(bm, geom=list(bm.edges), offset=0.0022, segments=1,
        affect="EDGES")
    uv = bm.loops.layers.uv.new("UVMap")
    for face in bm.faces:
        for loop in face.loops:
            co = loop.vert.co
            loop[uv].uv = uv_rect(UV_GUARD, (co.x + 0.06) / 0.14,
                (co.z + 0.012) / 0.024)
    return bm


def build_grip():
    """Poignée octogonale, trois gorges de laçage (cuir sombre)."""
    bm = bmesh.new()
    stations = [
        (GRIP_TOP, 0.0160), (-0.040, 0.0160), (-0.046, 0.0140),
        (-0.075, 0.0158), (-0.081, 0.0138), (-0.110, 0.0156),
        (-0.116, 0.0136), (GRIP_BOT, 0.0150),
    ]
    rings = []
    for y, r in stations:
        pts = []
        for i in range(8):
            a = math.tau * (i + 0.5) / 8.0
            pts.append((math.cos(a) * r, y, math.sin(a) * r * 0.92))
        rings.append([bm.verts.new(p) for p in pts])
    for a, b in zip(rings, rings[1:]):
        bridge(bm, a, b)
    bm.faces.new(tuple(reversed(rings[0])))
    bm.faces.new(tuple(rings[-1]))
    uv = bm.loops.layers.uv.new("UVMap")
    for face in bm.faces:
        for loop in face.loops:
            co = loop.vert.co
            angle = (math.atan2(co.z, co.x) / math.tau) + 0.5
            loop[uv].uv = uv_rect(UV_GRIP, angle,
                (co.y - GRIP_BOT) / (GRIP_TOP - GRIP_BOT))
    return bm


def build_pommel():
    """Pommeau de bronze vieilli, légèrement aplati et décentré."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=8, v_segments=5, radius=0.024)
    for v in bm.verts:
        v.co.x = v.co.x + 0.002
        v.co.z *= 0.90
        y = v.co.y
        v.co.y = POMMEL_Y + y * 0.85
    uv = bm.loops.layers.uv.new("UVMap")
    for face in bm.faces:
        for loop in face.loops:
            co = loop.vert.co
            loop[uv].uv = uv_rect(UV_POMMEL, (co.x + 0.026) / 0.052,
                (co.z + 0.024) / 0.048)
    return bm


def build_ivory():
    """Détails ivoire : pastille du pommeau + goupille du bras long."""
    bm = bmesh.new()
    # Pastille au cul du pommeau.
    disc = bmesh.ops.create_cone(bm, cap_ends=True, segments=8,
        radius1=0.0068, radius2=0.0060, depth=0.0050)
    for v in disc["verts"]:
        y = v.co.z
        v.co.z = v.co.y
        v.co.y = POMMEL_Y - 0.0195 + y
    # Goupille traversant le bras long de la garde.
    pin = bmesh.ops.create_cone(bm, cap_ends=True, segments=6,
        radius1=0.0034, radius2=0.0034, depth=0.0240)
    for v in pin["verts"]:
        v.co.x, v.co.z = 0.050 + v.co.x, v.co.z
    uv = bm.loops.layers.uv.new("UVMap")
    for face in bm.faces:
        for loop in face.loops:
            co = loop.vert.co
            loop[uv].uv = uv_rect(UV_IVORY, (co.x + 0.06) / 0.12,
                (co.z + 0.03) / 0.06)
    return bm


def value_noise(shape, cells, rng):
    """Bruit de valeur : grille aléatoire interpolée — patine reproductible."""
    grid = rng.random((cells + 1, cells + 1))
    y = np.linspace(0.0, cells, shape[0], endpoint=False)
    x = np.linspace(0.0, cells, shape[1], endpoint=False)
    yi, xi = np.floor(y).astype(int), np.floor(x).astype(int)
    yf, xf = (y - yi)[:, None], (x - xi)[None, :]
    yf = yf * yf * (3.0 - 2.0 * yf)
    xf = xf * xf * (3.0 - 2.0 * xf)
    a = grid[np.ix_(yi, xi)]
    b = grid[np.ix_(yi, xi + 1)]
    c = grid[np.ix_(yi + 1, xi)]
    d = grid[np.ix_(yi + 1, xi + 1)]
    return a * (1 - xf) * (1 - yf) + b * xf * (1 - yf) \
        + c * (1 - xf) * yf + d * xf * yf


def region_slice(region):
    u0, v0, u1, v1 = region
    n = TEX_SIZE
    return (slice(int(v0 * n), int(v1 * n)), slice(int(u0 * n), int(u1 * n)))


def paint_textures():
    """Couleur + metallic-roughness stylisées, peintes région par région."""
    rng = np.random.default_rng(SEED)
    n = TEX_SIZE
    color = np.zeros((n, n, 4), dtype=np.float64)
    color[..., 3] = 1.0
    mr = np.zeros((n, n, 4), dtype=np.float64)   # G=roughness, B=metallic
    mr[..., 3] = 1.0

    # --- Lame : fer patiné, arête centrale claire, FIL usé brillant aux
    # bords de région (= arêtes géométriques), entailles sombres.
    ys, xs = region_slice(UV_BLADE)
    h, w = ys.stop - ys.start, xs.stop - xs.start
    u = np.linspace(0.0, 1.0, w)[None, :]
    v = np.linspace(0.0, 1.0, h)[:, None]
    ridge = 1.0 - np.abs(u - 0.5) * 2.0                # arête centrale
    steel = 0.50 + 0.16 * ridge + 0.05 * value_noise((h, w), 6, rng)
    patina = value_noise((h, w), 14, rng)
    stain = np.clip(patina - 0.62, 0.0, 1.0) * 1.8      # taches de patine
    grime = np.clip(0.25 - v, 0.0, 1.0) * 0.5           # crasse près de la garde
    base = steel - 0.16 * stain - grime * 0.3
    r_ch = base * 0.96
    g_ch = base * 0.99
    b_ch = base * 1.06                                   # acier froid
    edge = np.clip(1.0 - np.minimum(u, 1.0 - u) / 0.055, 0.0, 1.0)
    for ch, gain in ((r_ch, 1.22), (g_ch, 1.22), (b_ch, 1.18)):
        ch += edge * (gain - 1.0) * 0.55                 # fil réaffûté clair
    nicks = ((v > 0.38) & (v < 0.42) & (u > 0.86)) | \
        ((v > 0.70) & (v < 0.735) & (u < 0.14))
    for ch in (r_ch, g_ch, b_ch):
        ch[nicks] *= 0.55                                # entailles sombres
    color[ys, xs, 0] = np.clip(r_ch, 0.0, 1.0)
    color[ys, xs, 1] = np.clip(g_ch, 0.0, 1.0)
    color[ys, xs, 2] = np.clip(b_ch, 0.0, 1.0)
    mr[ys, xs, 1] = np.clip(0.46 + 0.30 * stain - 0.30 * edge, 0.15, 0.9)
    mr[ys, xs, 2] = 1.0

    # --- Poignée : cuir sombre, laçage en diagonale.
    ys, xs = region_slice(UV_GRIP)
    h, w = ys.stop - ys.start, xs.stop - xs.start
    u = np.linspace(0.0, 1.0, w)[None, :]
    v = np.linspace(0.0, 1.0, h)[:, None]
    wrap = 0.5 + 0.5 * np.sin((v * 9.0 + u * 1.5) * math.tau)
    leather = 0.16 + 0.05 * wrap + 0.03 * value_noise((h, w), 8, rng)
    color[ys, xs, 0] = leather * 1.25
    color[ys, xs, 1] = leather * 0.82
    color[ys, xs, 2] = leather * 0.55
    mr[ys, xs, 1] = 0.88
    mr[ys, xs, 2] = 0.0

    # --- Garde et pommeau : bronze vieilli, patine discrète.
    for region, lift in ((UV_GUARD, 0.0), (UV_POMMEL, 0.06)):
        ys, xs = region_slice(region)
        h, w = ys.stop - ys.start, xs.stop - xs.start
        tone = 0.34 + lift + 0.07 * value_noise((h, w), 7, rng)
        spots = np.clip(value_noise((h, w), 10, rng) - 0.66, 0.0, 1.0)
        color[ys, xs, 0] = np.clip(tone * 1.30 - spots * 0.25, 0.0, 1.0)
        color[ys, xs, 1] = np.clip(tone * 1.02 - spots * 0.12, 0.0, 1.0)
        color[ys, xs, 2] = np.clip(tone * 0.62 + spots * 0.05, 0.0, 1.0)
        mr[ys, xs, 1] = np.clip(0.52 + spots * 0.3, 0.0, 1.0)
        mr[ys, xs, 2] = 1.0

    # --- Ivoire : chaud, mat, veinage à peine visible.
    ys, xs = region_slice(UV_IVORY)
    h, w = ys.stop - ys.start, xs.stop - xs.start
    vein = 0.90 + 0.04 * value_noise((h, w), 5, rng)
    color[ys, xs, 0] = vein
    color[ys, xs, 1] = vein * 0.975
    color[ys, xs, 2] = vein * 0.915
    mr[ys, xs, 1] = 0.55
    mr[ys, xs, 2] = 0.0

    os.makedirs(TEX_DIR, exist_ok=True)
    paths = {}
    for name, pixels, srgb in (
            ("T_WornSword_BaseColor", color, True),
            ("T_WornSword_MR", mr, False)):
        image = bpy.data.images.new(name, width=n, height=n, alpha=False)
        image.colorspace_settings.name = "sRGB" if srgb else "Non-Color"
        image.pixels = pixels.ravel().tolist()
        path = os.path.join(TEX_DIR, name + ".png")
        image.filepath_raw = path
        image.file_format = "PNG"
        image.save()
        paths[name] = (image, path)
    return paths


def build_material(images):
    material = bpy.data.materials.new("MAT_WornSword")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes["Principled BSDF"]
    tex_color = nodes.new("ShaderNodeTexImage")
    tex_color.image = images["T_WornSword_BaseColor"][0]
    links.new(tex_color.outputs["Color"], bsdf.inputs["Base Color"])
    tex_mr = nodes.new("ShaderNodeTexImage")
    tex_mr.image = images["T_WornSword_MR"][0]
    separate = nodes.new("ShaderNodeSeparateColor")
    links.new(tex_mr.outputs["Color"], separate.inputs["Color"])
    links.new(separate.outputs["Green"], bsdf.inputs["Roughness"])
    links.new(separate.outputs["Blue"], bsdf.inputs["Metallic"])
    return material


def main():
    random.seed(SEED)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0

    images = paint_textures()
    material = build_material(images)

    parts = []
    for name, builder in (("Blade", build_blade), ("Guard", build_guard),
            ("Grip", build_grip), ("Pommel", build_pommel),
            ("Ivory", build_ivory)):
        bm = builder()
        # Les capuchons à 6-8 sommets deviennent des triangles : l'exporter
        # glTF refuse les tangentes sur n-gons (mesuré au premier export).
        ngons = [f for f in bm.faces if len(f.verts) > 4]
        if ngons:
            bmesh.ops.triangulate(bm, faces=ngons)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        mesh = bpy.data.meshes.new("tmp_%s" % name)
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new("tmp_%s" % name, mesh)
        scene.collection.objects.link(obj)
        parts.append(obj)

    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    sword = bpy.context.active_object
    sword.name = "SM_WornSword_LOD0"
    sword.data.name = "SM_WornSword_LOD0_mesh"
    sword.data.materials.append(material)
    # Facettes lisibles : lissage sous 40°, arêtes franches au-delà (§7.1 —
    # arêtes sculptées, jamais un rendu plastique uniforme).
    sword.data.use_auto_smooth = True
    sword.data.auto_smooth_angle = math.radians(40.0)
    for poly in sword.data.polygons:
        poly.use_smooth = True

    tris = sum(len(p.vertices) - 2 for p in sword.data.polygons)
    print("[worn_sword] triangles : %d" % tris)
    print("[worn_sword] dimensions : %.3f x %.3f x %.3f"
        % tuple(sword.dimensions))

    os.makedirs(SRC_DIR, exist_ok=True)
    blend_path = os.path.join(SRC_DIR, "SM_WornSword.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print("[worn_sword] écrit : %s" % blend_path)


if __name__ == "__main__":
    main()
