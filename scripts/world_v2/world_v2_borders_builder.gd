## Bâtisseur des LIMITES du monde V2.1 — fermeture physique sans mur nu.
##
## L'anneau de relief (fonction de hauteur) ferme déjà visuellement le monde,
## mais D-019 rend toute pente raide ESCALADABLE : sans garde-fous, le joueur
## grimperait l'anneau et sortirait du monde. La ceinture de crêtes whitebox
## (masses simples autorisées par le prompt §9) porte donc le groupe
## `unclimbable` : visible, épaisse, EMBARQUÉE dans la montée de l'anneau —
## jamais une paroi invisible exposée. Les segments se recouvrent : aucune
## brèche. Au-delà, des silhouettes visuelles sans collision (hors d'atteinte).
class_name WorldV2BordersBuilder
extends RefCounted

const GUARD_SEGMENTS: int = 36
const GUARD_RADIUS: float = 246.0
const GUARD_HEIGHT: float = 34.0
const GUARD_THICKNESS: float = 6.0
## Longueur avec RECOUVREMENT : périmètre/36 ≈ 42,9 m — 50 m ferme les joints.
const GUARD_LENGTH: float = 50.0
const FAR_SILHOUETTES: int = 12
const FAR_RADIUS: float = 276.0

var _heightmap: WorldV2Heightmap = null


func _init(heightmap: WorldV2Heightmap) -> void:
	_heightmap = heightmap


func build(parent: Node3D) -> void:
	var ring: Node3D = Node3D.new()
	ring.name = "BorderGuards"
	parent.add_child(ring)
	for i: int in range(GUARD_SEGMENTS):
		var azimuth: float = TAU * float(i) / float(GUARD_SEGMENTS)
		var x: float = cos(azimuth) * GUARD_RADIUS
		var z: float = sin(azimuth) * GUARD_RADIUS
		var ground: float = _heightmap.height_at(x, z)
		var guard: StaticBody3D = StaticBody3D.new()
		guard.name = "BorderGuard%02d" % i
		guard.collision_layer = 1
		guard.collision_mask = 0
		guard.add_to_group(&"unclimbable")
		guard.add_to_group(&"world_v2_border_guards")
		# Crête variable par segment : des cols, pas un anneau plat (§9).
		var crest: float = GUARD_HEIGHT + 8.0 * sin(azimuth * 8.0 + 1.3)
		guard.position = Vector3(x, ground + crest * 0.5 - 6.0, z)
		guard.rotation = Vector3(0.0, -azimuth, 0.0)
		# V2.2-C : le VISUEL devient une crête déchiquetée — la COLLISION
		# reste la boîte V2.1 exacte (le test des 72 azimuts lit la
		# collision, jamais le maillage).
		var visual: MeshInstance3D = MeshInstance3D.new()
		visual.name = "GuardMesh"
		visual.mesh = _ridge_mesh(crest, i)
		guard.add_child(visual)
		var shape: BoxShape3D = BoxShape3D.new()
		# La boîte V2.1 EXACTE — la fermeture physique ne bouge pas d'un mètre.
		shape.size = Vector3(GUARD_THICKNESS, crest, GUARD_LENGTH)
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.name = "GuardCollision"
		collision.shape = shape
		guard.add_child(collision)
		ring.add_child(guard)

	# Silhouettes lointaines : VISUEL SEULEMENT, hors de portée (au-delà des
	# gardes) — elles habillent l'horizon whitebox, elles ne bloquent rien.
	var far: Node3D = Node3D.new()
	far.name = "FarSilhouettes"
	parent.add_child(far)
	# Bleu-gris clair : les pics lointains s'enfoncent dans la brume (§9.4 :
	# montagnes éclaircies, refroidies, simplifiées).
	var far_material: StandardMaterial3D = StandardMaterial3D.new()
	far_material.albedo_color = Color(0.46, 0.51, 0.58)
	far_material.roughness = 1.0
	for i: int in range(FAR_SILHOUETTES):
		var azimuth: float = TAU * (float(i) + 0.5) / float(FAR_SILHOUETTES)
		var x: float = cos(azimuth) * FAR_RADIUS
		var z: float = sin(azimuth) * FAR_RADIUS
		var peak: MeshInstance3D = MeshInstance3D.new()
		peak.name = "FarPeak%02d" % i
		var cone: CylinderMesh = CylinderMesh.new()
		cone.top_radius = 2.0
		cone.bottom_radius = 34.0 + 10.0 * sin(azimuth * 5.0 + 0.7)
		cone.height = 62.0 + 16.0 * sin(azimuth * 3.0 + 2.1)
		cone.material = far_material
		peak.mesh = cone
		peak.position = Vector3(x, cone.height * 0.5 + 18.0, z)
		far.add_child(peak)


## Crête de montagne : une boîte subdivisée PINCÉE vers le sommet et
## déchiquetée au bruit à graine fixe — l'enroulement vient de BoxMesh, il
## n'est jamais réécrit à la main (leçon V2.1 : l'enroulement se prouve à
## la capture). Base élargie en talus, sommet mince et irrégulier.
func _ridge_mesh(crest: float, ridge_seed: int) -> ArrayMesh:
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(GUARD_THICKNESS, crest, GUARD_LENGTH)
	box.subdivide_width = 2
	box.subdivide_height = 4
	box.subdivide_depth = 12
	var arrays: Array = box.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.055
	noise.seed = 20260813 + ridge_seed
	var half_h: float = crest * 0.5
	for i: int in range(vertices.size()):
		var v: Vector3 = vertices[i]
		var t: float = clampf((v.y + half_h) / crest, 0.0, 1.0)
		# Talus large à la base, arête mince au sommet.
		v.x *= lerpf(2.6, 0.18, t)
		# Crête déchiquetée : pics et cols le long du segment.
		v.y += noise.get_noise_2d(v.z, 13.7) * crest * 0.30 * t
		v.x += noise.get_noise_2d(v.z * 0.7, 41.2) * 3.0 * t
		vertices[i] = v
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	# Roche d'anneau : ocre éteint tirant froid — l'identité r11, pas un
	# gris neutre (§1.6 : les matériaux gris génériques sont interdits).
	material.albedo_color = Color(0.40, 0.345, 0.315)
	material.roughness = 1.0
	mesh.surface_set_material(0, material)
	return mesh
