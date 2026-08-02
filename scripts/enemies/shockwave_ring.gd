## Onde de choc au sol (MASTER_SPEC §12.4) — anneau qui S'ÉTEND depuis le
## point d'impact du colosse. Frappe UNE fois le joueur AU SOL dans la
## bande de l'anneau : sauter (décollé) ou esquiver (i-frames, refusées
## par la santé) l'évite — c'est la leçon que §12.4 enseigne.
## Autonome et borné : l'anneau se libère seul à sa portée maximale.
class_name ShockwaveRing
extends Node3D

const EXPAND_SPEED: float = 9.0
const MAX_RADIUS: float = 8.0
const BAND_HALF_WIDTH: float = 0.7
const DAMAGE: float = 14.0
const KNOCKBACK: float = 5.0

var instigator: Node = null

var _radius: float = 0.6
var _has_hit: bool = false
var _mesh: MeshInstance3D = null


func _ready() -> void:
	# Graybox lisible : un disque plat qui grandit — le VFX §7.13 viendra
	# en Phase H, la MÉCANIQUE est là.
	_mesh = MeshInstance3D.new()
	var disk: CylinderMesh = CylinderMesh.new()
	disk.height = 0.1
	disk.top_radius = 1.0
	disk.bottom_radius = 1.0
	_mesh.mesh = disk
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.6, 0.15, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh.material_override = material
	add_child(_mesh)


func _physics_process(delta: float) -> void:
	_radius += EXPAND_SPEED * delta
	if _mesh != null:
		_mesh.scale = Vector3(_radius, 1.0, _radius)
	if _radius >= MAX_RADIUS:
		queue_free()
		return
	if _has_hit:
		return
	for node: Node in get_tree().get_nodes_in_group("player"):
		var player: PlayerController = node as PlayerController
		if player == null:
			continue
		# Décollé = épargné (§12.4 : « évitable par saut »).
		if not player.is_on_floor():
			continue
		var flat: Vector2 = Vector2(
			player.global_position.x - global_position.x,
			player.global_position.z - global_position.z)
		if absf(flat.length() - _radius) > BAND_HALF_WIDTH:
			continue
		var hurtbox: HurtboxComponent = player.get_node_or_null("Hurtbox") \
			as HurtboxComponent
		if hurtbox == null:
			continue
		var event: DamageEvent = DamageEvent.new()
		event.amount = DAMAGE
		event.knockback = KNOCKBACK
		event.instigator = instigator
		var direction: Vector3 = Vector3(flat.x, 0.0, flat.y)
		if direction.length_squared() > 0.0001:
			event.direction = direction.normalized()
		var before: float = hurtbox.health().current() \
			if hurtbox.health() != null else -1.0
		hurtbox.receive_hit(event)
		# L'esquive (i-frames) refuse les dégâts CÔTÉ SANTÉ : l'anneau ne
		# marque « touché » que si la vie a réellement baissé — sinon il
		# continue sa course (une esquive n'éteint pas l'onde).
		if hurtbox.health() != null and hurtbox.health().current() < before:
			_has_hit = true
