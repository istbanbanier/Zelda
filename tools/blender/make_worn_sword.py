"""ART-P0R — fabrique l'Épée usée RÉVISÉE (SM_WornSword), asset de production.

Création originale du projet, procédurale et REPRODUCTIBLE (seed fixe).
Révision après verdict propriétaire ART-P0 : silhouette d'arme d'aventure
lisible (plus une aiguille), lame LARGE à vraie épaisseur, gouttière centrale
sur les deux faces, biseaux d'affûtage, trois entailles asymétriques DANS la
silhouette, garde forte asymétrique à volumes chanfreinés (~20 cm), poignée à
enroulement de cuir en spirale, pommeau sculpté à facettes (pas une sphère),
détails ivoire discrets. Acier patiné CLAIR légèrement chaud — la lame ne doit
jamais lire « ligne noire ». Zéro cyan.

Proportions (ordre ART-P0R) : total ≈ 0,98 m ; lame 0,78 m ; largeur de base
5,2 cm ; garde 20 cm ; poignée 13 cm ; pommeau volumineux (Ø 5,4 cm).
Origine au MILIEU DE LA POIGNÉE (pivot de prise) — le décalage vers la main
est porté par la scène Godot WornSword.tscn.

Textures 1024 : BaseColor + MetallicRoughness + NORMAL (générée depuis une
carte de hauteur : gouttière, biseaux, spires de cuir, patine).

Usage :
    blender --background --python tools/blender/make_worn_sword.py
Sorties :
    source_assets/weapons/SM_WornSword.blend
    source_assets/weapons/textures/T_WornSword_{BaseColor,MR,Normal}.png
"""

import math
import os

import bmesh
import bpy
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC_DIR = os.path.join(ROOT, "source_assets", "weapons")
TEX_DIR = os.path.join(SRC_DIR, "textures")

SEED = 20260802
TEX_SIZE = 1024

# Régions UV de l'atlas (u0, v0, u1, v1) — textures peintes sur ces MÊMES
# rectangles : correspondance structurelle.
UV_BLADE = (0.010, 0.020, 0.490, 0.980)
UV_GRIP = (0.510, 0.020, 0.730, 0.480)
UV_GUARD = (0.510, 0.520, 0.730, 0.980)
UV_POMMEL = (0.750, 0.520, 0.980, 0.980)
UV_IVORY = (0.750, 0.020, 0.980, 0.200)

BLADE_LEN = 0.78
BLADE_W = 0.026          # demi-largeur à la base (5,2 cm de large)
BLADE_T = 0.0052         # demi-épaisseur (1,04 cm — épaisseur PERCEPTIBLE)
GRIP_TOP = -0.012
GRIP_BOT = -0.142
POMMEL_TOP = -0.142
POMMEL_BOT = -0.196


def ring_fullered(bm, y, half_w, half_t, x_shift=0.0):
    """Section de lame à 22 sommets : fil, biseau d'affûtage, plat, épaule et
    GOUTTIÈRE centrale sur les DEUX faces — la lumière a des arêtes à prendre.
    Contour fermé : fil +x → face sup → fil -x → face inf → retour."""
    half = [
        (1.00, 0.00), (0.70, 1.00), (0.44, 1.00), (0.30, 0.85),
        (0.15, 0.58), (0.05, 0.54),
    ]
    contour = [(f * half_w, t * half_t) for f, t in half]
    contour += [(-f * half_w, t * half_t) for f, t in reversed(half[1:])]
    contour += [(-half[0][0] * half_w, 0.0)]
    contour += [(-f * half_w, -t * half_t) for f, t in half[1:]]
    contour += [(f * half_w, -t * half_t) for f, t in reversed(half[1:])]
    return [bm.verts.new((x + x_shift, y, z)) for x, z in contour]


def bridge(bm, ring_a, ring_b):
    n = len(ring_a)
    for i in range(n):
        bm.faces.new((ring_a[i], ring_a[(i + 1) % n],
            ring_b[(i + 1) % n], ring_b[i]))


def uv_rect(region, u, v):
    u0, v0, u1, v1 = region
    return (u0 + (u1 - u0) * min(max(u, 0.0), 1.0),
        v0 + (v1 - v0) * min(max(v, 0.0), 1.0))


def build_blade(rng):
    """Lame large et effilée : 30 anneaux, gouttière, TROIS entailles
    asymétriques et micro-irrégularités de fil (l'arme a une histoire)."""
    bm = bmesh.new()
    rings = []
    count = 30
    for i in range(count):
        s = i / (count - 1.0)
        y = s * 0.755
        wf = 1.0 - 0.44 * s - 0.30 * max(0.0, s - 0.82) / 0.18
        tf = 1.0 - 0.35 * s
        jitter = 1.0 + rng.uniform(-0.012, 0.012)      # fil irrégulier
        shift = 0.0009 * math.sin(y * 11.0)
        rings.append(ring_fullered(bm, y, BLADE_W * wf * jitter,
            BLADE_T * tf, x_shift=shift))
    # Entailles asymétriques : le sommet de FIL (index 0 = +x, index 11 = -x)
    # rentre vers l'axe — la silhouette est réellement mordue.
    for ring_index, edge_index, depth in ((6, 0, 0.80), (13, 11, 0.74),
            (21, 0, 0.85)):
        rings[ring_index][edge_index].co.x *= depth
        # L'anneau voisin s'affaisse à moitié : entaille en V, pas un cran net.
        rings[ring_index + 1][edge_index].co.x *= (1.0 + depth) * 0.5
    for a, b in zip(rings, rings[1:]):
        bridge(bm, a, b)
    # Pointe crédible : un anneau resserré puis l'apex — pas une aiguille.
    tip_ring = ring_fullered(bm, 0.772, BLADE_W * 0.14, BLADE_T * 0.5,
        x_shift=0.0012)
    bridge(bm, rings[-1], tip_ring)
    apex = bm.verts.new((0.0016, BLADE_LEN, 0.0))
    n = len(tip_ring)
    for i in range(n):
        bm.faces.new((tip_ring[i], tip_ring[(i + 1) % n], apex))
    bm.faces.new(tuple(reversed(rings[0])))
    uv = bm.loops.layers.uv.new("UVMap")
    for face in bm.faces:
        for loop in face.loops:
            co = loop.vert.co
            loop[uv].uv = uv_rect(UV_BLADE, co.x / (2.0 * BLADE_W) + 0.5,
                co.y / BLADE_LEN)
    return bm


def octagon(hy, hz):
    return [(hy, hz * 0.5), (hy * 0.5, hz), (-hy * 0.5, hz), (-hy, hz * 0.5),
        (-hy, -hz * 0.5), (-hy * 0.5, -hz), (hy * 0.5, -hz), (hy, -hz * 0.5)]


def build_guard():
    """Garde FORTE (~20 cm) : écusson central massif, bras court relevé, bras
    long tombant fini par un bloc évasé — silhouette asymétrique, sections
    octogonales = volumes chanfreinés d'origine."""
    bm = bmesh.new()
    stations = [
        (-0.085, 0.0055, 0.0045, 0.0045),
        (-0.072, 0.0095, 0.0075, 0.0025),
        (-0.030, 0.0170, 0.0110, 0.0),
        (0.030, 0.0170, 0.0110, 0.0),
        (0.072, 0.0105, 0.0080, -0.0040),
        (0.098, 0.0085, 0.0065, -0.0085),
        (0.104, 0.0130, 0.0095, -0.0095),
        (0.115, 0.0125, 0.0090, -0.0100),
    ]
    rings = []
    for x, hy, hz, dy in stations:
        rings.append([bm.verts.new((x, dy + py, pz))
            for py, pz in octagon(hy, hz)])
    for a, b in zip(rings, rings[1:]):
        bridge(bm, a, b)
    bm.faces.new(tuple(reversed(rings[0])))
    bm.faces.new(tuple(rings[-1]))
    uv = bm.loops.layers.uv.new("UVMap")
    for face in bm.faces:
        for loop in face.loops:
            co = loop.vert.co
            loop[uv].uv = uv_rect(UV_GUARD, (co.x + 0.09) / 0.21,
                (co.z + 0.012) / 0.024)
    return bm


def build_grip(rng):
    """Poignée 13 cm : enroulement de cuir RÉEL — spires alternées dont chaque
    anneau creux tourne d'un demi-pas, la couture spirale se lit."""
    bm = bmesh.new()
    segments = 12
    stations = []
    steps = 12
    for i in range(steps):
        s = i / (steps - 1.0)
        y = GRIP_TOP + (GRIP_BOT - GRIP_TOP) * s
        ridge = i % 2 == 1
        r = 0.0146 if ridge else 0.0172
        stations.append((y, r, (i // 2) * (math.tau / segments) * 0.5))
    rings = []
    for y, r, twist in stations:
        pts = []
        for i in range(segments):
            a = math.tau * (i + 0.5) / segments + twist
            wobble = 1.0 + rng.uniform(-0.02, 0.02)
            pts.append((math.cos(a) * r * wobble, y,
                math.sin(a) * r * 0.94 * wobble))
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
    """Pommeau SCULPTÉ « scent-stopper » : cône octogonal facetté, col serré,
    panse large, cul plat — volumineux (Ø 5,4 cm), légèrement décentré."""
    bm = bmesh.new()
    stations = [
        (POMMEL_TOP, 0.0110), (-0.150, 0.0195), (-0.160, 0.0262),
        (-0.170, 0.0270), (-0.181, 0.0205), (-0.190, 0.0135),
        (POMMEL_BOT, 0.0095),
    ]
    rings = []
    for y, r in stations:
        pts = []
        for i in range(8):
            a = math.tau * (i + 0.5) / 8.0
            pts.append((math.cos(a) * r + 0.002, y, math.sin(a) * r * 0.94))
        rings.append([bm.verts.new(p) for p in pts])
    for a, b in zip(rings, rings[1:]):
        bridge(bm, a, b)
    bm.faces.new(tuple(reversed(rings[0])))
    bm.faces.new(tuple(rings[-1]))
    uv = bm.loops.layers.uv.new("UVMap")
    for face in bm.faces:
        for loop in face.loops:
            co = loop.vert.co
            loop[uv].uv = uv_rect(UV_POMMEL, (co.x + 0.030) / 0.060,
                (co.z + 0.028) / 0.056)
    return bm


def build_ivory():
    """Détails ivoire discrets : pastille du cul de pommeau + goupille du bras
    long de la garde."""
    bm = bmesh.new()
    disc = bmesh.ops.create_cone(bm, cap_ends=True, segments=8,
        radius1=0.0078, radius2=0.0068, depth=0.0055)
    for v in disc["verts"]:
        y = v.co.z
        v.co.z = v.co.y
        v.co.y = POMMEL_BOT - 0.0028 + y
        v.co.x += 0.002
    pin = bmesh.ops.create_cone(bm, cap_ends=True, segments=6,
        radius1=0.0036, radius2=0.0036, depth=0.0260)
    for v in pin["verts"]:
        v.co.x += 0.088
    uv = bm.loops.layers.uv.new("UVMap")
    for face in bm.faces:
        for loop in face.loops:
            co = loop.vert.co
            loop[uv].uv = uv_rect(UV_IVORY, (co.x + 0.06) / 0.12,
                (co.z + 0.03) / 0.06)
    return bm


def value_noise(shape, cells, rng):
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
    """BaseColor + MR + hauteur→NORMAL, 1024, stylisées V4. La lame est un
    acier patiné CLAIR légèrement chaud (verdict ART-P0 : plus jamais une
    ligne noire) ; l'oxydation vit UNIQUEMENT dans les creux et près de la
    garde."""
    rng = np.random.default_rng(SEED)
    n = TEX_SIZE
    color = np.zeros((n, n, 4), dtype=np.float64)
    color[..., 3] = 1.0
    mr = np.zeros((n, n, 4), dtype=np.float64)
    mr[..., 3] = 1.0
    height = np.zeros((n, n), dtype=np.float64)

    # --- Lame.
    ys, xs = region_slice(UV_BLADE)
    h, w = ys.stop - ys.start, xs.stop - xs.start
    u = np.linspace(0.0, 1.0, w)[None, :]
    v = np.linspace(0.0, 1.0, h)[:, None]
    center = np.abs(u - 0.5) * 2.0                      # 0 axe → 1 fil
    fuller = np.clip(1.0 - center / 0.24, 0.0, 1.0)     # gouttière centrale
    edge = np.clip(1.0 - (1.0 - center) / 0.16, 0.0, 1.0)   # bande du fil
    steel = 0.640 + 0.045 * value_noise((h, w), 7, rng) \
        - 0.060 * fuller + 0.030 * np.sin(v * 90.0) * 0.15
    patina = np.clip(value_noise((h, w), 16, rng) - 0.70, 0.0, 1.0) * 2.2
    steel -= 0.075 * patina                              # patine SUBTILE
    r_ch = steel * 1.010
    g_ch = steel * 0.995
    b_ch = steel * 0.975                                 # gris LÉGÈREMENT chaud
    sharp = np.clip(edge - 0.25, 0.0, 1.0)
    for ch in (r_ch, g_ch, b_ch):
        ch += sharp * 0.16                               # affûtage plus clair
    # Oxydation UNIQUEMENT près de la garde et au fond de la gouttière.
    rust = (np.clip(0.10 - v, 0.0, 1.0) * 6.0 + fuller * 0.55) \
        * np.clip(value_noise((h, w), 12, rng) - 0.45, 0.0, 1.0)
    rust = np.clip(rust, 0.0, 1.0) * 0.5
    r_ch = r_ch * (1.0 - rust) + 0.42 * rust
    g_ch = g_ch * (1.0 - rust) + 0.31 * rust
    b_ch = b_ch * (1.0 - rust) + 0.22 * rust
    nick_mask = (((v > 0.19) & (v < 0.215) & (u > 0.90)) |
        ((v > 0.43) & (v < 0.455) & (u < 0.10)) |
        ((v > 0.69) & (v < 0.71) & (u > 0.90)))
    for ch in (r_ch, g_ch, b_ch):
        ch[nick_mask] *= 0.72
    color[ys, xs, 0] = np.clip(r_ch, 0.0, 1.0)
    color[ys, xs, 1] = np.clip(g_ch, 0.0, 1.0)
    color[ys, xs, 2] = np.clip(b_ch, 0.0, 1.0)
    mr[ys, xs, 1] = np.clip(0.42 + 0.28 * patina + 0.30 * rust - 0.24 * sharp,
        0.12, 0.9)
    mr[ys, xs, 2] = 1.0
    height[ys, xs] = 0.5 - 0.30 * fuller + 0.10 * sharp - 0.25 * nick_mask \
        + 0.05 * patina

    # --- Poignée : cuir brun foncé, spires diagonales en relief.
    ys, xs = region_slice(UV_GRIP)
    h, w = ys.stop - ys.start, xs.stop - xs.start
    u = np.linspace(0.0, 1.0, w)[None, :]
    v = np.linspace(0.0, 1.0, h)[:, None]
    wrap = 0.5 + 0.5 * np.sin((v * 11.0 + u * 1.0) * math.tau)
    leather = 0.185 + 0.075 * wrap + 0.035 * value_noise((h, w), 9, rng)
    color[ys, xs, 0] = leather * 1.30
    color[ys, xs, 1] = leather * 0.86
    color[ys, xs, 2] = leather * 0.58
    mr[ys, xs, 1] = 0.86 - 0.08 * wrap
    mr[ys, xs, 2] = 0.0
    height[ys, xs] = 0.35 + 0.30 * wrap

    # --- Garde et pommeau : bronze vieilli, patine dans les creux.
    for region, lift in ((UV_GUARD, 0.0), (UV_POMMEL, 0.05)):
        ys, xs = region_slice(region)
        h, w = ys.stop - ys.start, xs.stop - xs.start
        tone = 0.385 + lift + 0.075 * value_noise((h, w), 8, rng)
        spots = np.clip(value_noise((h, w), 12, rng) - 0.68, 0.0, 1.0) * 1.8
        color[ys, xs, 0] = np.clip(tone * 1.34 - spots * 0.22, 0.0, 1.0)
        color[ys, xs, 1] = np.clip(tone * 1.04 - spots * 0.10, 0.0, 1.0)
        color[ys, xs, 2] = np.clip(tone * 0.60 + spots * 0.04, 0.0, 1.0)
        mr[ys, xs, 1] = np.clip(0.48 + spots * 0.30, 0.0, 1.0)
        mr[ys, xs, 2] = 1.0
        height[ys, xs] = 0.5 + 0.10 * value_noise((h, w), 6, rng) \
            - 0.12 * spots

    # --- Ivoire.
    ys, xs = region_slice(UV_IVORY)
    h, w = ys.stop - ys.start, xs.stop - xs.start
    vein = 0.905 + 0.040 * value_noise((h, w), 6, rng)
    color[ys, xs, 0] = vein
    color[ys, xs, 1] = vein * 0.975
    color[ys, xs, 2] = vein * 0.915
    mr[ys, xs, 1] = 0.52
    mr[ys, xs, 2] = 0.0
    height[ys, xs] = 0.5

    # Hauteur → normale (Sobel simple), force modérée : biseaux et spires
    # prennent la lumière sans granuler.
    strength = 2.2
    gy, gx = np.gradient(height)
    normal = np.zeros((n, n, 4), dtype=np.float64)
    nz = np.ones_like(height)
    length = np.sqrt((gx * strength) ** 2 + (gy * strength) ** 2 + nz ** 2)
    normal[..., 0] = 0.5 - 0.5 * gx * strength / length
    normal[..., 1] = 0.5 + 0.5 * gy * strength / length
    normal[..., 2] = 0.5 + 0.5 * nz / length
    normal[..., 3] = 1.0

    os.makedirs(TEX_DIR, exist_ok=True)
    out = {}
    for name, pixels, srgb in (
            ("T_WornSword_BaseColor", color, True),
            ("T_WornSword_MR", mr, False),
            ("T_WornSword_Normal", normal, False)):
        image = bpy.data.images.new(name, width=n, height=n, alpha=False)
        image.colorspace_settings.name = "sRGB" if srgb else "Non-Color"
        image.pixels = pixels.ravel().tolist()
        path = os.path.join(TEX_DIR, name + ".png")
        image.filepath_raw = path
        image.file_format = "PNG"
        image.save()
        out[name] = (image, path)
    return out


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
    tex_normal = nodes.new("ShaderNodeTexImage")
    tex_normal.image = images["T_WornSword_Normal"][0]
    normal_map = nodes.new("ShaderNodeNormalMap")
    normal_map.inputs["Strength"].default_value = 0.8
    links.new(tex_normal.outputs["Color"], normal_map.inputs["Color"])
    links.new(normal_map.outputs["Normal"], bsdf.inputs["Normal"])
    return material


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0

    rng = np.random.default_rng(SEED)
    images = paint_textures()
    material = build_material(images)

    parts = []
    builders = (("Blade", lambda: build_blade(rng)),
        ("Guard", build_guard), ("Grip", lambda: build_grip(rng)),
        ("Pommel", build_pommel), ("Ivory", build_ivory))
    for name, builder in builders:
        bm = builder()
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
    sword.data.use_auto_smooth = True
    sword.data.auto_smooth_angle = math.radians(38.0)
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
