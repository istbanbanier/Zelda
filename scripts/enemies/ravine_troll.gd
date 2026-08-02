## Colosse des ravins — `ravine_troll` (MASTER_SPEC §12.4).
##
## La montagne qui marche : ~420 PV, 3,8 m, poise 100, LENT (virage 3,5).
## TROIS attaques : balayage (renversement, knockback 6) enchaîné d'une
## frappe verticale (contrat chaîné), et COUP AU SOL à ONDE DE CHOC —
## anneau qui s'étend, ÉVITABLE par saut (décollé = épargné) ou esquive
## (i-frames). À mi-distance : LANCER DE ROCHER (projectile balistique
## réel, le même balayage CCD que la flèche). POINT FAIBLE dorsal :
## hurtbox arrière ×2 (§10.3, la formule l'applique côté hitbox).
## Token LOURD (§12.8). Sa taille est sa navigation : la capsule de
## 1,1 m de rayon ne franchit PAS une porte étroite — mesuré.
class_name RavineTroll
extends EnemyBase

## Coup au sol : cadence et anneau.
const SLAM_COOLDOWN: float = 8.0
const SLAM_TRIGGER_RANGE: float = 2.6
## Lancer de rocher : bande d'engagement et cadence.
const THROW_MIN: float = 6.0
const THROW_MAX: float = 16.0
const THROW_COOLDOWN: float = 6.0
const THROW_TELEGRAPH: float = 0.9
const THROW_RECOVERY: float = 0.8
const ROCK_SPEED: float = 18.0
const ROCK_GRAVITY: float = 12.0
const ROCK_DAMAGE: float = 20.0

var _slam_cooldown: float = 0.0
var _throw_cooldown: float = 0.0
var _throw_timer: float = 0.0
var _throw_recovering: float = 0.0
var _ring_spawned_for_slam: bool = false
var _rock: ArrowProjectile = null
var _rock_mesh: MeshInstance3D = null


func _family_ready() -> void:
	telegraph_color = Color(0.9, 0.55, 0.1)
	# Le rocher : un projectile balayé (CCD §5.3), réutilisé — jamais
	# instancié en rafale.
	_rock = ArrowProjectile.new()
	_rock.name = "RockProjectile"
	add_child(_rock)
	_rock_mesh = MeshInstance3D.new()
	_rock_mesh.name = "RockMesh"
	var stone: SphereMesh = SphereMesh.new()
	stone.radius = 0.45
	stone.height = 0.9
	_rock_mesh.mesh = stone
	var stone_material: StandardMaterial3D = StandardMaterial3D.new()
	stone_material.albedo_color = Color(0.5, 0.45, 0.4)
	_rock_mesh.material_override = stone_material
	_rock.add_child(_rock_mesh)
	# Le point faible dorsal participe au feedback commun (flash, réveil).
	var back: HurtboxComponent = get_node_or_null("BackHurtbox") \
		as HurtboxComponent
	if back != null:
		back.hit_received.connect(_on_hit_received)


## Le colosse consomme le token LOURD (§12.8) : un seul à la fois.
func _attack_token_kind() -> StringName:
	return &"heavy"


## Choix d'attaque au contact : coup au sol si proche et prêt (l'onde),
## sinon la chaîne balayage → verticale du contrat.
func _family_try_attack(distance: float) -> bool:
	if _slam_cooldown <= 0.0 and distance <= SLAM_TRIGGER_RANGE:
		if _attack.try_heavy():
			_slam_cooldown = SLAM_COOLDOWN
			_ring_spawned_for_slam = false
			return true
	return _attack.try_attack()


func _process_family_state(delta: float) -> bool:
	_slam_cooldown = maxf(0.0, _slam_cooldown - delta)
	_throw_cooldown = maxf(0.0, _throw_cooldown - delta)
	# L'onde part au moment d'IMPACT du coup au sol (phase ACTIVE).
	if _state == State.ATTACK and not _ring_spawned_for_slam \
			and _attack.current_attack() == _attack.heavy_attack \
			and _attack.phase() == AttackControllerComponent.Phase.ACTIVE:
		_ring_spawned_for_slam = true
		_spawn_shockwave()
	# Séquence de LANCER : annonce immobile orientée, jet, récupération.
	if _throw_timer > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		if _target_valid():
			var to_target: Vector3 = _target.global_position - global_position
			to_target.y = 0.0
			_face(to_target, delta)
		_throw_timer -= delta
		if _throw_timer <= 0.0:
			_launch_rock()
			_throw_recovering = THROW_RECOVERY
		move_and_slide()
		return true
	if _throw_recovering > 0.0:
		_throw_recovering -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return true
	# Déclenchement du lancer : bande 6-16 m, prêt, orienté.
	if _state == State.CHASE and _throw_cooldown <= 0.0 and _target_valid():
		var to_target: Vector3 = _target.global_position - global_position
		to_target.y = 0.0
		var distance: float = to_target.length()
		if distance >= THROW_MIN and distance <= THROW_MAX \
				and _facing_angle_deg(to_target) <= 25.0:
			_throw_timer = THROW_TELEGRAPH
			return true
	return false


## L'annonce du lancer rougeoie comme celle d'un coup (§10.5).
func _is_telegraphing() -> bool:
	return super() or _throw_timer > 0.0


func _launch_rock() -> void:
	_throw_cooldown = THROW_COOLDOWN
	if not _target_valid() or _rock == null:
		return
	# Le jet part DEVANT et AU-DESSUS : né dans sa propre carrure, le
	# balayage du projectile heurtait le colosse au premier tick (mesuré
	# D-EN.4 — rocher invisible, zéro mètre parcouru).
	var forward: Vector3 = _pivot.global_transform.basis.z
	forward.y = 0.0
	forward = direction_or_zero(forward)
	var origin: Vector3 = global_position + Vector3.UP * 3.0 + forward * 1.8
	var to_target: Vector3 = (_target.global_position + Vector3.UP * 1.0) \
		- origin
	var distance: float = to_target.length()
	# Compensation balistique simple : viser au-dessus selon la distance.
	var direction: Vector3 = (to_target
		+ Vector3.UP * (ROCK_GRAVITY * distance * distance)
			/ (2.0 * ROCK_SPEED * ROCK_SPEED)).normalized()
	_rock.launch(origin, direction, ROCK_SPEED, ROCK_GRAVITY, ROCK_DAMAGE,
		&"enemies", self, [get_rid()], 3.0)


func _spawn_shockwave() -> void:
	var ring: ShockwaveRing = ShockwaveRing.new()
	ring.instigator = self
	get_parent().add_child(ring)
	ring.global_position = Vector3(global_position.x,
		global_position.y + 0.05, global_position.z)


## Seams de test.
func is_winding_throw() -> bool:
	return _throw_timer > 0.0


func slam_cooldown_left() -> float:
	return _slam_cooldown
