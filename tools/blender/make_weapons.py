"""Fabrique les CINQ armes de production qui manquaient (ISS-020).

Seule l'Épée usée avait un modèle. Les cinq autres retombaient sur la boîte
graybox de `WeaponPickup` — repli honnête tant qu'aucune arme n'était posée au
sol, devenu visible le jour où quatre des 31 récompenses sont des armes au sol.

Créations ORIGINALES du projet, procédurales et reproductibles (seed fixe),
d'après VISUAL_ASSET_BIBLE §16 :

  * `SM_WoodClub`        branche dense torsadée, masse noueuse en bout, bandes
                         de cuir, AUCUNE lame métallique (§16.1) ;
  * `SM_Spear`           hampe de bois sombre, ligatures turquoise sourd, tête
                         foliacée étroite bronze/fer + insert céramique (§16.3) ;
  * `SM_HeavyAxe`        tête en coin DISSYMÉTRIQUE, contrepoids minéral,
                         manche brun renforcé de métal (§16.4) ;
  * `SM_SimpleBow`       composite ASYMÉTRIQUE en deux bois, renforts de
                         tendon, corde, poignée et encoche visibles (§16.5) ;
  * `SM_ConductiveBlade` deux rails cuivre/fer séparés par une âme de céramique
                         ivoire, pointe fourchue courte, canal fendu (§16.6).

Convention reprise de l'Épée usée, éprouvée : l'arme est bâtie le long de
Blender **+Y**, pivot au MILIEU DE LA PRISE. L'export `--export_yup` envoie
+Y de Blender sur −Z de glTF ; la scène Godot enveloppante fait le demi-tour
qui remet la pointe vers +Z. Ne pas changer cette chaîne sans refaire les
quatre scènes.

Aucune texture : ces cinq modèles portent des matériaux PBR à facteurs plats
(base color, metallic, roughness). C'est un cran au-dessus de la boîte grise et
un cran EN DESSOUS de l'Épée usée, qui a ses cartes peintes. Dit tel quel dans
`docs/KNOWN_ISSUES.md` plutôt que présenté comme fini.

Usage :
    blender --background --python tools/blender/make_weapons.py
Sorties :
    source_assets/weapons/SM_{WoodClub,Spear,HeavyAxe,SimpleBow,ConductiveBlade}.blend
"""

import math
import os

import bmesh
import bpy
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC_DIR = os.path.join(ROOT, "source_assets", "weapons")

SEED = 20260803

# --- Palette (VISUAL_ASSET_BIBLE §1.4) --------------------------------------
# base color linéaire, metallic, roughness
MATERIALS = {
    "wood_dark":   ((0.128, 0.075, 0.043, 1.0), 0.0, 0.82),
    "wood_warm":   ((0.238, 0.140, 0.072, 1.0), 0.0, 0.76),
    "wood_pale":   ((0.330, 0.230, 0.130, 1.0), 0.0, 0.70),
    "leather":     ((0.150, 0.085, 0.050, 1.0), 0.0, 0.62),
    "cord":        ((0.360, 0.310, 0.210, 1.0), 0.0, 0.88),
    "iron":        ((0.300, 0.305, 0.320, 1.0), 1.0, 0.52),
    "iron_worn":   ((0.235, 0.240, 0.255, 1.0), 1.0, 0.62),
    "bronze":      ((0.360, 0.230, 0.120, 1.0), 1.0, 0.44),
    "copper":      ((0.420, 0.225, 0.115, 1.0), 1.0, 0.38),
    "patina":      ((0.185, 0.240, 0.215, 1.0), 0.6, 0.66),
    "ivory":       ((0.700, 0.640, 0.480, 1.0), 0.0, 0.48),
    "stone":       ((0.245, 0.215, 0.180, 1.0), 0.0, 0.86),
    "turquoise":   ((0.055, 0.330, 0.360, 1.0), 0.0, 0.78),
    "sinew":       ((0.520, 0.470, 0.360, 1.0), 0.0, 0.80),
}


# --- Socle Blender ----------------------------------------------------------

def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0


def material(name: str) -> bpy.types.Material:
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    base, metallic, roughness = MATERIALS[name]
    mat = bpy.data.materials.new("MAT_%s" % name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    # Facteurs PLATS : l'exporter glTF les transporte en `pbrMetallicRoughness`
    # sans texture. Vérifié sur les pillards — un `ShaderNodeMixRGB` serait
    # silencieusement ignoré, pas une entrée directe de Principled.
    bsdf.inputs["Base Color"].default_value = base
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


class Build:
    """Accumulateur de géométrie : un bmesh, un slot matériau par matière."""

    def __init__(self, name: str) -> None:
        self.name = name
        self.bm = bmesh.new()
        self.slots: list = []

    def _slot(self, matter: str) -> int:
        if matter not in self.slots:
            self.slots.append(matter)
        return self.slots.index(matter)

    def _tag(self, faces: list, matter: str) -> None:
        index = self._slot(matter)
        for face in faces:
            face.material_index = index

    def box(self, center, size, matter: str, rot=None) -> None:
        """Boîte de dimensions PLEINES.

        `create_cube(size=1)` place ses sommets à ±0,5 : la taille demandée est
        donc la dimension totale, pas la demi-dimension. Cette confusion a
        produit ISS-018 (créatures en pièces détachées) ; elle ne se répète pas.
        """
        before = set(self.bm.faces)
        bmesh.ops.create_cube(self.bm, size=1.0)
        made = [f for f in self.bm.faces if f not in before]
        verts = {v for f in made for v in f.verts}
        for vert in verts:
            vert.co = Vector((vert.co.x * size[0], vert.co.y * size[1],
                              vert.co.z * size[2]))
            if rot is not None:
                vert.co.rotate(rot)
            vert.co += Vector(center)
        self._tag(made, matter)

    def tube(self, points, radii, matter: str, segments: int = 8,
             twist: float = 0.0) -> None:
        """Tube balayé le long d'une polyligne, rayon variable par point.

        Couvre manche, hampe, branche et bras d'arc. Les anneaux sont fermés
        aux deux bouts : le volume est étanche, donc solidaire.
        """
        rings = []
        for i, (point, radius) in enumerate(zip(points, radii)):
            nxt = points[min(i + 1, len(points) - 1)]
            prv = points[max(i - 1, 0)]
            axis = (Vector(nxt) - Vector(prv))
            if axis.length < 1e-6:
                axis = Vector((0.0, 1.0, 0.0))
            axis.normalize()
            side = axis.cross(Vector((0.0, 0.0, 1.0)))
            if side.length < 1e-4:
                side = axis.cross(Vector((1.0, 0.0, 0.0)))
            side.normalize()
            up = axis.cross(side).normalized()
            ring = []
            for s in range(segments):
                angle = math.tau * s / segments + twist * i
                offset = side * (math.cos(angle) * radius) \
                    + up * (math.sin(angle) * radius)
                ring.append(self.bm.verts.new(Vector(point) + offset))
            rings.append(ring)
        made = []
        for a, b in zip(rings, rings[1:]):
            for s in range(segments):
                t = (s + 1) % segments
                made.append(self.bm.faces.new((a[s], a[t], b[t], b[s])))
        made.append(self.bm.faces.new(list(reversed(rings[0]))))
        made.append(self.bm.faces.new(rings[-1]))
        self._tag(made, matter)

    def finish(self) -> bpy.types.Object:
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        for matter in self.slots:
            mesh.materials.append(material(matter))
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.collection.objects.link(obj)
        mesh.shade_smooth() if False else None
        return obj


def save(obj_name: str) -> None:
    path = os.path.join(SRC_DIR, "%s.blend" % obj_name)
    os.makedirs(SRC_DIR, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=path)
    obj = bpy.data.objects[obj_name]
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for vert in obj.data.vertices:
        lo = Vector((min(lo[i], vert.co[i]) for i in range(3)))
        hi = Vector((max(hi[i], vert.co[i]) for i in range(3)))
    span = hi - lo
    print("[make_weapons] %-20s %5d tris  %.3f x %.3f x %.3f m  -> %s"
          % (obj_name, len(obj.data.polygons) * 2, span.x, span.y, span.z,
             os.path.relpath(path, ROOT)))


# --- 1. GOURDIN DE BOIS (§16.1) ---------------------------------------------
#
# 1,18 m. Branche torsadée qui ÉPAISSIT vers le bout, masse noueuse terminale,
# trois bandes de cuir sur la prise. Aucune pièce de métal : la faible
# conductivité doit se voir avant d'être lue dans une fiche.

def build_wood_club() -> None:
    reset_scene()
    build = Build("SM_WoodClub")
    grip_bottom, head_top = -0.30, 0.88
    points, radii = [], []
    for i in range(13):
        t = i / 12.0
        y = grip_bottom + (head_top - grip_bottom) * t
        # Le fût grossit doucement, puis la masse s'enfle sur le dernier tiers.
        radius = 0.019 + 0.012 * t
        if t > 0.62:
            swell = (t - 0.62) / 0.38
            radius += 0.030 * math.sin(swell * math.pi * 0.86)
        # Torsion : la branche n'est pas droite (§16.1 « torsadée »).
        bend = 0.014 * math.sin(t * math.pi * 1.7)
        points.append((bend, y, 0.008 * math.sin(t * math.pi * 2.3)))
        radii.append(radius)
    build.tube(points, radii, "wood_warm", segments=10, twist=0.10)

    # Nœuds de la masse : trois bosses asymétriques, pas une sphère lisse.
    for i, (t, side) in enumerate([(0.74, 1.0), (0.83, -0.7), (0.91, 0.35)]):
        y = grip_bottom + (head_top - grip_bottom) * t
        build.box((0.030 * side, y, 0.016 * (1 if i % 2 else -1)),
                  (0.042, 0.052, 0.038), "wood_pale")
    # Bandes de cuir de la prise.
    for y in (-0.24, -0.15, -0.06):
        build.tube([(0.0, y - 0.016, 0.0), (0.0, y + 0.016, 0.0)],
                   [0.023, 0.023], "leather", segments=10)
    # Lanière de poignet, nouée au talon.
    build.tube([(0.0, -0.30, 0.0), (0.014, -0.335, 0.006)],
               [0.021, 0.010], "leather", segments=8)
    build.finish()
    save("SM_WoodClub")


# --- 2. LANCE (§16.3) --------------------------------------------------------
#
# 2,05 m. Hampe de bois sombre, ligatures turquoise SOURD (jamais le cyan de la
# Résonance), tête foliacée étroite en bronze avec insert de céramique : la
# conductivité vient de la TÊTE, pas de toute la hampe — et cela se voit.

def build_spear() -> None:
    reset_scene()
    build = Build("SM_Spear")
    butt, head_base = -0.80, 0.86
    build.tube([(0.0, butt, 0.0), (0.0, head_base, 0.0)],
               [0.0155, 0.0138], "wood_dark", segments=10)
    # Talon ferré : la lance se plante, elle ne s'effiloche pas.
    build.tube([(0.0, butt - 0.055, 0.0), (0.0, butt + 0.02, 0.0)],
               [0.008, 0.017], "iron_worn", segments=8)

    # Douille puis lame foliacée : large au tiers, effilée vers la pointe.
    build.tube([(0.0, head_base - 0.02, 0.0), (0.0, head_base + 0.10, 0.0)],
               [0.019, 0.016], "bronze", segments=8)
    blade = [
        (head_base + 0.10, 0.017, 0.0055),
        (head_base + 0.17, 0.032, 0.0070),
        (head_base + 0.26, 0.028, 0.0060),
        (head_base + 0.36, 0.017, 0.0040),
        (head_base + 0.44, 0.004, 0.0018),
    ]
    for (y0, w0, t0), (y1, w1, t1) in zip(blade, blade[1:]):
        build.box((0.0, (y0 + y1) * 0.5, 0.0),
                  ((w0 + w1), (y1 - y0), (t0 + t1)), "bronze")
    # Insert de céramique dans la gouttière : l'isolant se lit à l'œil.
    build.box((0.0, head_base + 0.21, 0.0), (0.010, 0.13, 0.014), "ivory")
    # Ligatures turquoise sourd — deux à la douille, deux à la prise.
    for y in (head_base + 0.02, head_base + 0.07, 0.02, -0.10):
        build.tube([(0.0, y - 0.013, 0.0), (0.0, y + 0.013, 0.0)],
                   [0.0175, 0.0175], "turquoise", segments=10)
    build.finish()
    save("SM_Spear")


# --- 3. HACHE LOURDE (§16.4) -------------------------------------------------
#
# 1,34 m. Tête en coin DISSYMÉTRIQUE — un tranchant large d'un côté, un bec
# court de l'autre —, contrepoids minéral au talon, manche brun cerclé de
# métal. La silhouette doit annoncer le startup et la recovery élevés.

def build_heavy_axe() -> None:
    reset_scene()
    build = Build("SM_HeavyAxe")
    butt, top = -0.40, 0.88
    build.tube([(0.0, butt, 0.0), (0.0, 0.30, 0.0), (0.0, top, 0.0)],
               [0.020, 0.023, 0.026], "wood_warm", segments=10)
    for y in (-0.40, -0.22, 0.44, 0.70):
        build.tube([(0.0, y - 0.014, 0.0), (0.0, y + 0.014, 0.0)],
                   [0.026, 0.026], "iron_worn", segments=10)
    # Contrepoids minéral : la masse n'est pas toute à la tête.
    build.box((0.0, butt - 0.030, 0.0), (0.062, 0.075, 0.058), "stone")

    # Œil de la tête, enfilé sur le manche.
    build.box((0.0, top - 0.02, 0.0), (0.062, 0.145, 0.056), "iron")
    # Tranchant : quatre tranches qui s'élargissent et s'amincissent.
    for i, (dx, w, t) in enumerate([(0.055, 0.115, 0.048),
                                    (0.108, 0.150, 0.034),
                                    (0.152, 0.176, 0.021),
                                    (0.180, 0.192, 0.008)]):
        build.box((dx, top - 0.010, 0.0), (0.055, w, t), "iron")
    # Bec arrière, court et épais : la dissymétrie est la signature.
    build.box((-0.052, top + 0.020, 0.0), (0.070, 0.070, 0.040), "iron")
    build.box((-0.092, top + 0.042, 0.0), (0.048, 0.048, 0.026), "iron")
    # Prise de cuir sous la tête, là où la main descend pour les lourdes.
    for y in (0.10, 0.20):
        build.tube([(0.0, y - 0.030, 0.0), (0.0, y + 0.030, 0.0)],
                   [0.024, 0.024], "leather", segments=10)
    build.finish()
    save("SM_HeavyAxe")


# --- 4. ARC SIMPLE (§16.5) ---------------------------------------------------
#
# 1,52 m. Composite ASYMÉTRIQUE — branche haute plus longue que la basse —, en
# deux bois, renforts de tendon aux jonctions, corde, poignée et encoches
# visibles. Aucune reprise d'un arc existant : la courbure est un simple arc de
# cercle brisé au milieu, pas une recurve à double inflexion.

def build_simple_bow() -> None:
    reset_scene()
    build = Build("SM_SimpleBow")
    upper, lower = 0.88, -0.64          # asymétrie : 88 cm contre 64 cm

    def limb(end_y: float, matter: str) -> list:
        points, radii = [], []
        steps = 9
        for i in range(steps + 1):
            t = i / steps
            y = end_y * t
            # Le dos de l'arc s'écarte du plan de corde vers les pointes.
            x = 0.085 * math.sin(t * math.pi * 0.62)
            points.append((x, y, 0.0))
            radii.append(0.0155 * (1.0 - 0.62 * t) + 0.004)
        build.tube(points, radii, matter, segments=8)
        return points

    top = limb(upper, "wood_dark")
    bottom = limb(lower, "wood_pale")

    # Poignée : renflement central de cuir, plus une plaque de tendon.
    build.tube([(0.0, -0.075, 0.0), (0.0, 0.075, 0.0)],
               [0.021, 0.021], "leather", segments=10)
    build.box((0.017, 0.0, 0.0), (0.014, 0.10, 0.030), "sinew")
    # Renforts de tendon aux deux tiers de chaque branche.
    for points, t in ((top, 6), (bottom, 6)):
        px = points[t]
        build.tube([(px[0], px[1] - 0.030, 0.0), (px[0], px[1] + 0.030, 0.0)],
                   [0.016, 0.016], "sinew", segments=8)
    # Encoches : un anneau serré juste avant chaque pointe.
    for points in (top, bottom):
        px = points[-2]
        build.tube([(px[0], px[1] - 0.012, 0.0), (px[0], px[1] + 0.012, 0.0)],
                   [0.013, 0.013], "cord", segments=8)
    # Corde, tendue de pointe à pointe — elle passe DEVANT la poignée.
    build.tube([(top[-1][0], upper, 0.0), (0.0, 0.02, 0.0),
                (bottom[-1][0], lower, 0.0)],
               [0.0026, 0.0030, 0.0026], "cord", segments=6)
    build.finish()
    save("SM_SimpleBow")


# --- 5. LAME CONDUCTRICE (§16.6) ---------------------------------------------
#
# 0,90 m. Deux rails de cuivre séparés par une âme de céramique ivoire, pointe
# FOURCHUE très courte, canal de courant fendu. Au repos, presque aucune
# émission : le matériau raconte la conduction, pas une lumière allumée.

def build_conductive_blade() -> None:
    reset_scene()
    build = Build("SM_ConductiveBlade")
    grip_bottom, guard_y = -0.16, 0.0
    blade_top = 0.66

    # Poignée : bois sombre cerclé de cuivre, pommeau à facettes.
    build.tube([(0.0, grip_bottom, 0.0), (0.0, guard_y - 0.01, 0.0)],
               [0.017, 0.019], "wood_dark", segments=10)
    for y in (grip_bottom + 0.035, grip_bottom + 0.095):
        build.tube([(0.0, y - 0.011, 0.0), (0.0, y + 0.011, 0.0)],
                   [0.020, 0.020], "copper", segments=10)
    build.box((0.0, grip_bottom - 0.026, 0.0), (0.048, 0.044, 0.040), "copper")

    # Garde : barre plate, deux oreilles de céramique.
    build.box((0.0, guard_y + 0.012, 0.0), (0.150, 0.028, 0.034), "copper")
    for side in (-1.0, 1.0):
        build.box((0.062 * side, guard_y + 0.012, 0.0),
                  (0.030, 0.034, 0.038), "ivory")

    # DEUX rails de cuivre, séparés par l'âme de céramique : la signature.
    for side in (-1.0, 1.0):
        rail = []
        radii = []
        for i in range(7):
            t = i / 6.0
            rail.append((0.0155 * side * (1.0 - 0.35 * t),
                         guard_y + 0.03 + (blade_top - guard_y - 0.03) * t,
                         0.0))
            radii.append(0.0092 * (1.0 - 0.30 * t))
        build.tube(rail, radii, "copper", segments=6)
    # Âme centrale de céramique — plus fine, en retrait : le canal FENDU se
    # lit comme un vide entre les rails, pas comme une troisième barre.
    build.box((0.0, (guard_y + 0.03 + blade_top) * 0.5, 0.0),
              (0.014, blade_top - guard_y - 0.03, 0.010), "ivory")
    # Trois traverses : les rails tiennent ensemble (et le corps reste UN).
    for t in (0.18, 0.50, 0.82):
        y = guard_y + 0.03 + (blade_top - guard_y - 0.03) * t
        build.box((0.0, y, 0.0), (0.036, 0.014, 0.014), "copper")

    # Pointe FOURCHUE très courte : deux dents, un vide au milieu.
    for side in (-1.0, 1.0):
        build.tube([(0.010 * side, blade_top, 0.0),
                    (0.014 * side, blade_top + 0.055, 0.0)],
                   [0.0072, 0.0022], "iron", segments=6)
    build.box((0.0, blade_top - 0.008, 0.0), (0.030, 0.026, 0.014), "copper")
    build.finish()
    save("SM_ConductiveBlade")


def main() -> None:
    os.makedirs(SRC_DIR, exist_ok=True)
    print("[make_weapons] Blender %s" % bpy.app.version_string)
    build_wood_club()
    build_spear()
    build_heavy_axe()
    build_simple_bow()
    build_conductive_blade()
    print("[make_weapons] cinq armes bâties")


main()
