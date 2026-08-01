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
##
## Navigation (D-022, soldée en D.1) : chemin du navmesh baké par requêtes
## DIRECTES au serveur (`map_get_path`), suivi manuel avec avancement de
## waypoint en 2D. ADAPTATION MESURÉE, pas un choix de confort : le suiveur
## intégré de `NavigationAgent3D` compare position et waypoint en 3D, or les
## points du chemin vivent à la hauteur VOXELISÉE du navmesh (~0,45 m au-dessus
## des pieds) — `path_desired_distance` 0,4 ne validait jamais un waypoint
## (pillard gelé sur place), 0,8 les validait trop tôt (gelé contre un coin de
## mur). Trois sondes archivées dans PROGRESS. L'agent reviendra si l'évitement
## de §12.9 l'exige. Sans navmesh (arènes de test, CombatLab) : pilotage direct.
## L'audition de §12.6 attend les événements sonores de §12.7.
class_name RaiderRed
extends CharacterBody3D

signal died()
signal state_changed(state: StringName)

enum State { IDLE, CHASE, ATTACK, RETREAT, STAGGERED, DEAD }

## Cadence de perception (§12.9 : jamais de perception complète par frame).
const PERCEPTION_INTERVAL: int = 6
## Cadence de re-calcul du chemin (§12.9 : « cadence 0,15–0,35 s », 0,25 s ici —
## jamais de pathfinding par frame).
const REPATH_INTERVAL: int = 15
const GRAVITY: float = 24.0
## Séparation locale entre corps ennemis (PT-D1-02) : rayon d'influence et
## poids de la poussée mélangée à la direction de poursuite.
const SEPARATION_RADIUS: float = 1.7
const SEPARATION_WEIGHT: float = 0.9

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
var _repath_tick: int = 0
var _state_timer: float = 0.0
var _attack_cooldown: float = 0.0
## Chemin courant sur le navmesh et son index de waypoint (voir l'en-tête).
var _path: PackedVector3Array = PackedVector3Array()
var _path_index: int = 0
## Position de la cible au moment du dernier calcul — §12.9 : on ne recalcule
## que si elle a bougé significativement.
var _path_goal: Vector3 = Vector3.INF

## Feedback graybox (PT-D1-03) : télégraphe TEINTÉ pendant l'annonce, flash
## d'impact, étourdissement penché, mort couchée. Pas de l'art (§7.14) — de la
## lisibilité pour un testeur humain.
var _body_material: StandardMaterial3D = null
var _base_color: Color = Color.WHITE
var _flash_timer: float = 0.0
const TELEGRAPH_COLOR: Color = Color(0.95, 0.2, 0.12)


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
	# Matériau dédoublé : trois pillards partagent la ressource de scène — le
	# télégraphe de l'un ne doit jamais rougir les autres (§5.4).
	var body_mesh: MeshInstance3D = get_node_or_null("Pivot/BodyMesh") as MeshInstance3D
	if body_mesh != null:
		var base: StandardMaterial3D = \
			body_mesh.get_surface_override_material(0) as StandardMaterial3D
		if base == null and body_mesh.mesh != null:
			base = body_mesh.mesh.surface_get_material(0) as StandardMaterial3D
		if base != null:
			_body_material = base.duplicate() as StandardMaterial3D
			_base_color = _body_material.albedo_color
			body_mesh.set_surface_override_material(0, _body_material)
	# Gourdin visible (PT-D1-03 : « aucune arme visible »).
	var club: MeshInstance3D = MeshInstance3D.new()
	club.name = "ClubMesh"
	var club_box: BoxMesh = BoxMesh.new()
	club_box.size = Vector3(0.11, 0.11, 0.7)
	club.mesh = club_box
	var club_material: StandardMaterial3D = StandardMaterial3D.new()
	club_material.albedo_color = Color(0.4, 0.26, 0.14)
	club.material_override = club_material
	club.position = Vector3(0.35, 1.0, 0.35)
	_pivot.add_child(club)


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	_state_timer += delta
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_poise.update(delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	_update_feedback(delta)

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

	var direction: Vector3 = _pursuit_direction(to_target, distance)
	# Séparation locale (PT-D1-02, §12.9 « avoidance seulement pour agents
	# proches ») : la collision empêche le chevauchement mais laisse trois
	# poursuivants en file indienne — la poussée latérale les déploie.
	var steered: Vector3 = direction + _separation_push() * SEPARATION_WEIGHT
	if steered.length_squared() > 0.0001:
		steered = steered.normalized()
	velocity.x = steered.x * tuning.pursuit_speed
	velocity.z = steered.z * tuning.pursuit_speed


## Direction de poursuite : le chemin du navmesh quand la carte en offre un, la
## ligne directe sinon. Recalcul seulement si la cible a bougé de plus de 1,5 m,
## vérifié par cadence (§12.9 : jamais de pathfinding par frame).
func _pursuit_direction(to_target: Vector3, distance: float) -> Vector3:
	if distance <= 0.001:
		return Vector3.ZERO
	var map: RID = get_world_3d().navigation_map
	_repath_tick += 1
	if _path.is_empty() or (_repath_tick % REPATH_INTERVAL == 1
			and _path_goal.distance_to(_target.global_position) > 1.5):
		_path = NavigationServer3D.map_get_path(
			map, global_position, _target.global_position, true)
		_path_index = 0
		_path_goal = _target.global_position
	# Carte sans navmesh (arène de test), pas encore synchronisée (§20.10), ou
	# cible dans le même polygone : la ligne directe est le bon mouvement.
	if _path.size() < 2:
		return to_target.normalized()
	# Avancement en 2D : la hauteur des waypoints est celle du navmesh voxelisé,
	# pas celle des pieds — la comparer ferait geler le suivi (voir l'en-tête).
	while _path_index < _path.size() - 1:
		var reached: Vector3 = _path[_path_index]
		if Vector2(reached.x - global_position.x, reached.z - global_position.z) \
				.length() < 0.6:
			_path_index += 1
		else:
			break
	var waypoint: Vector3 = _path[_path_index]
	var direction: Vector3 = Vector3(
		waypoint.x - global_position.x, 0.0, waypoint.z - global_position.z)
	if direction.length_squared() < 0.0001:
		return to_target.normalized()
	return direction.normalized()


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


## Poussée d'éloignement des autres corps ennemis proches. Le groupe `enemies`
## reste petit (≤ 14 IA actives, §12.9) — la boucle est bornée par conception.
func _separation_push() -> Vector3:
	var push: Vector3 = Vector3.ZERO
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node == self:
			continue
		var other: Node3D = node as Node3D
		if other == null:
			continue
		if other.has_method("health"):
			var other_health: HealthComponent = other.call("health") as HealthComponent
			if other_health != null and other_health.is_dead():
				continue  # un cadavre ne repousse personne
		var away: Vector3 = global_position - other.global_position
		away.y = 0.0
		var gap: float = away.length()
		if gap >= SEPARATION_RADIUS or gap < 0.001:
			continue
		push += away / gap * (1.0 - gap / SEPARATION_RADIUS)
	return push


## Perception par cadence (§12.9) : distance, cône, puis raycast de LOS —
## « aucune vision à travers mur » (§12.7).
func _tick_perception() -> void:
	_perception_tick += 1
	if _perception_tick % PERCEPTION_INTERVAL != 0:
		return
	var player: PlayerController = _find_player()
	if player == null:
		return
	# Un cadavre ne se « perçoit » pas comme une menace : sans cette garde, la
	# perception ré-acquérait le joueur mort à chaque cadence (D1, revue Gate C).
	var player_health: HealthComponent = player.health()
	if player_health != null and player_health.is_dead():
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


## Une cible morte cesse d'en être une (constat D1 de la revue du Gate C : sans
## ce contrôle, le pillard frappait le cadavre indéfiniment). Même convention
## `health()` que le lock-on.
func _target_valid() -> bool:
	if _target == null or not is_instance_valid(_target):
		return false
	if _target.has_method("health"):
		var target_health: HealthComponent = _target.call("health") as HealthComponent
		if target_health != null and target_health.is_dead():
			return false
	return true


func _face(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target_yaw: float = atan2(direction.x, direction.z)
	var weight: float = 1.0 - exp(-tuning.turn_speed * delta)
	_pivot.rotation.y = lerp_angle(_pivot.rotation.y, target_yaw, weight)


func _on_hit_received(event: DamageEvent) -> void:
	if _state == State.DEAD:
		return
	_flash_timer = 0.12
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
	# La mort se VOIT (PT-D1-03) : le corps bascule au sol.
	_pivot.rotation.x = -1.45
	if _body_material != null:
		_body_material.albedo_color = _base_color.darkened(0.5)
		_body_material.emission_enabled = false
	set_physics_process(false)
	died.emit()


## Télégraphe, flash et étourdissement — pilotés par l'ÉTAT, jamais l'inverse
## (§10.6 : la présentation suit le contrat).
func _update_feedback(delta: float) -> void:
	if _body_material == null:
		return
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)
		if not _body_material.emission_enabled:
			_body_material.emission_enabled = true
			_body_material.emission = Color(1, 1, 1)
			_body_material.emission_energy_multiplier = 1.6
	elif _body_material.emission_enabled:
		_body_material.emission_enabled = false
	# Annonce (§12.1 : télégraphe 0,65-0,95 s) : rouge franc pendant le startup.
	if _state == State.ATTACK \
			and _attack.phase() == AttackControllerComponent.Phase.STARTUP:
		_body_material.albedo_color = TELEGRAPH_COLOR
	elif _state != State.DEAD:
		_body_material.albedo_color = _base_color
	# Étourdissement penché, redressé partout ailleurs (sauf mort, couchée).
	if _state == State.STAGGERED:
		_pivot.rotation.x = 0.4
	elif _state != State.DEAD:
		_pivot.rotation.x = 0.0


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
