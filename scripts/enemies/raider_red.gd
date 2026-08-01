## Pillard braise — `raider_red` (MASTER_SPEC §12.1, §12.7).
##
## Le tutoriel vivant : perception lente, télégraphe long (0,65–0,95 s — le
## startup de son `AttackDefinition`), un coup, et il **recule après une esquive
## réussie** — c'est lui qui enseigne les i-frames. Ses nombres vivent dans
## `EnemyTuning` (§5.4) et son attaque dans le même `AttackControllerComponent`
## que le joueur : un seul pipeline de dégâts pour tout le monde (§10.1).
##
## Machine d'états : sous-ensemble de §12.7 réellement peuplé — `Patrol`,
## `Investigate`, `Flee` et les autres arriveront avec les familles suivantes.
## LIMITE ASSUMÉE (D-022) : pas de `NavigationAgent3D` — l'arène du CombatLab est
## plate et vide, le pilotage direct suffit ; la navigation arrive avec le monde
## (Phase D). L'audition de §12.6 attend les événements sonores de §12.7.
class_name RaiderRed
extends CharacterBody3D

signal died()
signal state_changed(state: StringName)

enum State { IDLE, CHASE, ATTACK, RETREAT, STAGGERED, DEAD }

## Cadence de perception (§12.9 : jamais de perception complète par frame).
const PERCEPTION_INTERVAL: int = 6
const GRAVITY: float = 24.0

@export var tuning: EnemyTuning

@onready var _health: HealthComponent = $HealthComponent
@onready var _poise: PoiseComponent = $PoiseComponent
@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _attack: AttackControllerComponent = $AttackController
@onready var _hitbox: HitboxComponent = $Pivot/ClubHitbox
@onready var _pivot: Node3D = $Pivot

var _state: State = State.IDLE
var _target: Node3D = null
var _perception_tick: int = 0
var _state_timer: float = 0.0
var _attack_cooldown: float = 0.0


func _ready() -> void:
	if tuning == null:
		tuning = EnemyTuning.new()
		push_warning("[raider_red] aucun EnemyTuning assigné — valeurs par défaut.")
	_health.max_health = tuning.max_health
	_health.revive()
	_poise.max_poise = tuning.poise
	_health.died.connect(_on_died)
	_poise.poise_broken.connect(_on_poise_broken)
	_hurtbox.hit_received.connect(_on_hit_received)
	# §12.1 : il recule après une esquive réussie. Sa propre hitbox le lui apprend :
	# un coup confirmé sur une cible invulnérable est un coup esquivé.
	_hitbox.hit_confirmed.connect(_on_own_hit_confirmed)


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	_state_timer += delta
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_poise.update(delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	match _state:
		State.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			_tick_perception()
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			velocity.x = 0.0
			velocity.z = 0.0
			if not _attack.update(delta):
				_attack_cooldown = tuning.attack_cooldown
				_enter(State.CHASE)
		State.RETREAT:
			_process_retreat(delta)
		State.STAGGERED:
			velocity.x = 0.0
			velocity.z = 0.0
			if _state_timer >= tuning.stagger_duration:
				_poise.recover()
				_enter(State.CHASE)

	move_and_slide()


func _process_chase(delta: float) -> void:
	if not _target_valid():
		_target = null
		_enter(State.IDLE)
		return
	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	_face(to_target, delta)

	if distance <= tuning.attack_reach and _attack_cooldown <= 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack.try_attack():
			_enter(State.ATTACK)
		return

	var direction: Vector3 = to_target.normalized() if distance > 0.001 else Vector3.ZERO
	velocity.x = direction.x * tuning.pursuit_speed
	velocity.z = direction.z * tuning.pursuit_speed


func _process_retreat(delta: float) -> void:
	if not _target_valid():
		_enter(State.IDLE)
		return
	var away: Vector3 = global_position - _target.global_position
	away.y = 0.0
	# Il recule EN FAISANT FACE (§12.1) : c'est une prise de distance, pas une fuite.
	_face(-away, delta)
	if away.length() > 0.001:
		away = away.normalized()
	velocity.x = away.x * tuning.retreat_speed
	velocity.z = away.z * tuning.retreat_speed
	if _state_timer >= tuning.retreat_duration:
		_enter(State.CHASE)


## Perception par cadence (§12.9) : distance, cône, puis raycast de LOS —
## « aucune vision à travers mur » (§12.7).
func _tick_perception() -> void:
	_perception_tick += 1
	if _perception_tick % PERCEPTION_INTERVAL != 0:
		return
	var player: PlayerController = _find_player()
	if player == null:
		return
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > tuning.vision_range:
		return
	var forward: Vector3 = _pivot.global_transform.basis.z
	forward.y = 0.0
	if to_player.length() > 0.001 and forward.length() > 0.001:
		var angle: float = rad_to_deg(forward.normalized().angle_to(to_player.normalized()))
		if angle > tuning.vision_half_angle_deg:
			return
	if not _has_los(player):
		return
	_target = player
	_enter(State.CHASE)


func _has_los(target: Node3D) -> bool:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 1.2,
		target.global_position + Vector3.UP * 1.0,
		1, [get_rid()])
	return space.intersect_ray(query).is_empty()


func _find_player() -> PlayerController:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	for node: Node in players:
		if node is PlayerController:
			return node as PlayerController
	return null


func _target_valid() -> bool:
	return _target != null and is_instance_valid(_target)


func _face(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target_yaw: float = atan2(direction.x, direction.z)
	var weight: float = 1.0 - exp(-tuning.turn_speed * delta)
	_pivot.rotation.y = lerp_angle(_pivot.rotation.y, target_yaw, weight)


func _on_hit_received(event: DamageEvent) -> void:
	if _state == State.DEAD:
		return
	_poise.take_poise_damage(event)
	# Être frappé révèle l'attaquant, même hors du cône (§12.7 : un impact est un
	# événement sonore à lui seul).
	if _target == null and event != null and is_instance_valid(event.instigator):
		_target = event.instigator as Node3D
		if _state == State.IDLE and _target != null:
			_enter(State.CHASE)


func _on_poise_broken() -> void:
	if _state == State.DEAD:
		return
	# §16.2 généralisé : l'interruption coupe l'attaque et sa hitbox.
	_attack.cancel()
	_enter(State.STAGGERED)


func _on_own_hit_confirmed(_event: DamageEvent, target: HurtboxComponent) -> void:
	# §12.1 : coup confirmé sur cible invulnérable = esquive réussie du joueur →
	# il recule. Sa hitbox le sait sans aucun câblage vers le joueur.
	if _state == State.DEAD:
		return
	var target_health: HealthComponent = target.health()
	if target_health != null and target_health.is_invulnerable():
		_attack.cancel()
		_enter(State.RETREAT)


func _on_died(_event: DamageEvent) -> void:
	# §12.10 : IA, hitboxes et collision coupées, une fois.
	_attack.cancel()
	_enter(State.DEAD)
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_physics_process(false)
	died.emit()


func _enter(state: State) -> void:
	if _state == state:
		return
	_state = state
	_state_timer = 0.0
	state_changed.emit(state_name())


func state() -> State:
	return _state


func state_name() -> StringName:
	match _state:
		State.IDLE: return &"idle"
		State.CHASE: return &"chase"
		State.ATTACK: return &"attack"
		State.RETREAT: return &"retreat"
		State.STAGGERED: return &"staggered"
		State.DEAD: return &"dead"
	return &"?"


## Convention des cibles verrouillables et des tests.
func health() -> HealthComponent:
	return _health
