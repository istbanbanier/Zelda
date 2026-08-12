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
	var guard_material: StandardMaterial3D = StandardMaterial3D.new()
	guard_material.albedo_color = Color(0.30, 0.28, 0.30)
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
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(GUARD_THICKNESS, crest, GUARD_LENGTH)
		mesh.material = guard_material
		var visual: MeshInstance3D = MeshInstance3D.new()
		visual.name = "GuardMesh"
		visual.mesh = mesh
		guard.add_child(visual)
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = mesh.size
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
	var far_material: StandardMaterial3D = StandardMaterial3D.new()
	far_material.albedo_color = Color(0.38, 0.37, 0.42)
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
