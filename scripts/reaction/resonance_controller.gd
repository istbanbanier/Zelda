## Contrôleur du Bracelet de Résonance (P2 §3) — porte les cinq opérations.
## Tranche 1 : **Pulse** (P2 §3.2). Les suivantes (Arc Link, Polarité,
## Arc Step, Ground) s'ajouteront ici, chacune fail-first.
##
## Le contrôleur ne lit JAMAIS l'InputMap (D-013) : `PlayerController` lui
## transmet la décision et marque lui-même consommation/refus dans la sonde
## de latence. Interdits durs (GAMEPLAY_BIBLE §3.5) : aucune révélation à
## travers un mur — LOS calquée sur celle des ennemis (couche 1, monde
## statique) ; le Pulse est AUDIBLE (coût de bruit, §12.7).
class_name ResonanceController
extends Node

signal pulse_fired(revealed_count: int)
signal link_created(a: ElectricNode, b: ElectricNode)
signal link_dissolved()
signal ground_completed(target: Node)
signal ground_cancelled(reason: StringName)

## Valeurs de départ P2 §3.2 — à migrer en Resource de tuning quand les
## cinq opérations existeront (une `ResonanceActionDefinition` par opération).
const PULSE_RADIUS: float = 10.0
const PULSE_COOLDOWN: float = 1.5
const REVEAL_DURATION: float = 3.0
## Rayon du bruit émis — entre flèche (8) et sprint (12) : discret mais réel.
const PULSE_NOISE_RADIUS: float = 9.0
## Hauteur de l'« œil » du Bracelet pour la ligne de vue.
const EYE_HEIGHT: float = 1.4

## Arc Link (P2 §3.3) — valeurs de départ, à migrer en Resource de tuning.
## Portée de SÉLECTION joueur→port ; ÉCART maximal entre les deux ports.
const LINK_SELECT_RANGE: float = 16.0
const LINK_MAX_SPAN: float = 14.0

## Polarité (P2 §3.4) — impulsions bornées, jamais de téléport, jamais un
## acteur vivant (RigidBody3D structurellement). Valeurs de départ.
const POLARITY_RANGE: float = 12.0
const POLARITY_MASS_MAX: float = 90.0
const POLARITY_SPEED: float = 4.5
const POLARITY_ACCEL: float = 12.0
const POLARITY_DURATION: float = 2.5

## Arc Step (P2 §3.5) — dash physique court vers un ancrage. Valeurs de départ.
const ARC_STEP_RANGE: float = 10.0
const ARC_STEP_SPEED: float = 18.0
const ARC_STEP_COST: float = 20.0
const ARC_STEP_COOLDOWN: float = 0.35

## Ground (P2 §3.6) — mise à la terre volontaire. Valeurs de départ.
const GROUND_RANGE: float = 3.0
const GROUND_STARTUP: float = 0.35

## Focus (P2 §3.1/§3.8) — sélection le long de l'axe de visée.
const FOCUS_RANGE: float = 18.0
## Demi-cône de candidature : dot minimal entre visée et direction cible.
const FOCUS_CONE_DOT: float = 0.25

var _pulse_cooldown: float = 0.0
var _arc_step_cooldown: float = 0.0
var _link: ResonanceLinkNode = null
var _ground_target: MaterialStateComponent = null
var _ground_player: PlayerController = null
var _ground_timer: float = 0.0
var _focus_engaged: bool = false
var _focus_candidates: Array[ResonanceTargetComponent] = []
var _focus_selected: ResonanceTargetComponent = null
## Vrai quand la sélection vient d'un cycle volontaire : l'update suivant la
## respecte (hystérésis, P2 §5.5 — pas de target switch surprise).
var _focus_manual: bool = false
## Extrémité A d'un Arc Link en deux temps. Oubliée à la sortie du focus.
var _link_first: ElectricNode = null
var _polarity_target: RigidBody3D = null
var _polarity_anchor: CharacterBody3D = null
var _polarity_sign: float = 1.0
var _polarity_timer: float = 0.0


func _ready() -> void:
	# Auto-piloté : cooldowns et engagement Polarité vivent au tick physique
	# du composant lui-même — le propriétaire ne fait que DÉCIDER (try_*).
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_pulse_cooldown = maxf(0.0, _pulse_cooldown - delta)
	_arc_step_cooldown = maxf(0.0, _arc_step_cooldown - delta)
	_drive_polarity(delta)
	_drive_ground(delta)


## Tente un Pulse depuis `body`. Retourne `&"fired"` ou `&"cooldown"` — le
## propriétaire traduit ce verdict vers la sonde de latence.
func try_pulse(body: CharacterBody3D) -> StringName:
	if _pulse_cooldown > 0.0:
		return &"cooldown"
	_pulse_cooldown = PULSE_COOLDOWN
	var revealed_count: int = 0
	var space: PhysicsDirectSpaceState3D = body.get_world_3d().direct_space_state
	var eye: Vector3 = body.global_position + Vector3.UP * EYE_HEIGHT
	for node: Node in get_tree().get_nodes_in_group(&"resonance_targets"):
		var target: ResonanceTargetComponent = node as ResonanceTargetComponent
		if target == null:
			continue
		var anchor: Node3D = target.anchor()
		if anchor == null:
			continue
		if anchor.global_position.distance_to(body.global_position) > PULSE_RADIUS:
			continue
		if not _has_los(space, eye, anchor.global_position, body):
			continue
		target.reveal(REVEAL_DURATION)
		revealed_count += 1
	# Le Pulse s'entend (P2 §3.2) — même canal que sprint/impact/flèche.
	NoiseEvents.emit(get_tree(), body.global_position, PULSE_NOISE_RADIUS, &"pulse")
	pulse_fired.emit(revealed_count)
	return &"fired"


## --- Polarité (P2 §3.4) ---

func polarity_engaged() -> bool:
	return _polarity_target != null and is_instance_valid(_polarity_target)


## Engage la Polarité sur `target`. Verdicts : `engaged`, `invalide`,
## `pas_metal`, `pas_charge`, `trop_lourd`, `hors_portee`.
func try_polarity(body: CharacterBody3D, target: RigidBody3D,
		mode: StringName) -> StringName:
	if body == null or target == null or not target.is_inside_tree():
		return &"invalide"
	var state: MaterialStateComponent = _material_state_of(target)
	if state == null or state.profile == null \
			or not state.profile.has_tag(&"metal"):
		return &"pas_metal"
	if not state.is_charged():
		return &"pas_charge"
	if target.mass > POLARITY_MASS_MAX:
		return &"trop_lourd"
	if body.global_position.distance_to(target.global_position) > POLARITY_RANGE:
		return &"hors_portee"
	_polarity_target = target
	_polarity_anchor = body
	_polarity_sign = -1.0 if mode == &"repousser" else 1.0
	_polarity_timer = POLARITY_DURATION
	return &"engaged"


func polarity_stop() -> void:
	_polarity_target = null
	_polarity_anchor = null
	_polarity_timer = 0.0


## Pilotage par impulsions bornées (Jolt) : on corrige la vitesse PLANE vers
## la vitesse cible, sous plafond d'accélération — jamais d'écriture de
## transform, la gravité et les collisions restent souveraines.
func _drive_polarity(delta: float) -> void:
	if _polarity_target == null:
		return
	if not is_instance_valid(_polarity_target) \
			or not _polarity_target.is_inside_tree() \
			or _polarity_anchor == null or not is_instance_valid(_polarity_anchor):
		polarity_stop()
		return
	_polarity_timer -= delta
	var state: MaterialStateComponent = _material_state_of(_polarity_target)
	var out_of_range: bool = _polarity_anchor.global_position.distance_to(
		_polarity_target.global_position) > POLARITY_RANGE + 2.0
	if _polarity_timer <= 0.0 or out_of_range \
			or state == null or not state.is_charged():
		polarity_stop()
		return
	var toward: Vector3 = _polarity_anchor.global_position \
		- _polarity_target.global_position
	toward.y = 0.0
	if toward.length_squared() < 0.25:
		# Assez proche : l'attraction s'arrête au lieu d'aspirer dans le corps.
		if _polarity_sign > 0.0:
			polarity_stop()
			return
	var direction: Vector3 = toward.normalized() * _polarity_sign
	var desired: Vector3 = direction * POLARITY_SPEED
	var current: Vector3 = _polarity_target.linear_velocity
	var planar: Vector3 = Vector3(current.x, 0.0, current.z)
	var correction: Vector3 = (desired - planar).limit_length(POLARITY_ACCEL * delta)
	_polarity_target.sleeping = false
	_polarity_target.apply_central_impulse(correction * _polarity_target.mass)


func _material_state_of(target: Node) -> MaterialStateComponent:
	for child: Node in target.get_children():
		if child is MaterialStateComponent:
			return child as MaterialStateComponent
	return null


## Cible du raccourci direct de mise à la terre : l'état matière CHARGÉ le
## plus proche dans la portée — la lecture (Pulse) a déjà montré quoi viser.
func pick_ground_target(body: CharacterBody3D) -> Node:
	var best: Node = null
	var best_gap: float = GROUND_RANGE
	for node: Node in get_tree().get_nodes_in_group(&"material_states"):
		var state: MaterialStateComponent = node as MaterialStateComponent
		if state == null or not state.is_inside_tree():
			continue
		if not state.is_charged() and not state.is_overloaded():
			continue
		var anchor: Node3D = state.get_parent() as Node3D
		if anchor == null:
			continue
		var gap: float = anchor.global_position.distance_to(body.global_position)
		if gap <= best_gap:
			best_gap = gap
			best = state
	return best


## --- Focus et sélection (P2 §3.1/§3.8) ---

func focus_active() -> bool:
	return _focus_engaged


## À appeler chaque tick tenu : reconstruit les candidats (portée, cône,
## LOS) et maintient la sélection. `from`/`direction` viennent de la caméra
## en jeu, des tests en headless — le cœur ne connaît pas la caméra.
func focus_update(body: CharacterBody3D, from: Vector3, direction: Vector3) -> void:
	_focus_engaged = true
	var space: PhysicsDirectSpaceState3D = body.get_world_3d().direct_space_state
	var scored: Array[Dictionary] = []
	for node: Node in get_tree().get_nodes_in_group(&"resonance_targets"):
		var target: ResonanceTargetComponent = node as ResonanceTargetComponent
		if target == null or not target.is_inside_tree():
			continue
		var anchor: Node3D = target.anchor()
		if anchor == null:
			continue
		var to_target: Vector3 = anchor.global_position - from
		var gap: float = to_target.length()
		if gap > FOCUS_RANGE or gap < 0.05:
			continue
		var dot: float = direction.dot(to_target / gap)
		if dot < FOCUS_CONE_DOT:
			continue
		if not _has_los(space, from, anchor.global_position, body):
			continue
		scored.append({ "target": target, "angle": direction.angle_to(to_target) })
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["angle"]) < float(b["angle"]))
	_focus_candidates.clear()
	for entry: Dictionary in scored:
		_focus_candidates.append(entry["target"] as ResonanceTargetComponent)
	var still_there: bool = _focus_selected != null \
		and is_instance_valid(_focus_selected) \
		and _focus_selected in _focus_candidates
	if _focus_candidates.is_empty():
		_focus_selected = null
		_focus_manual = false
	elif not still_there or not _focus_manual:
		_focus_selected = _focus_candidates[0]
		if not still_there:
			_focus_manual = false


func focus_cycle(step: int) -> void:
	if _focus_candidates.is_empty():
		return
	var index: int = _focus_candidates.find(_focus_selected)
	index = wrapi(index + step, 0, _focus_candidates.size())
	_focus_selected = _focus_candidates[index]
	_focus_manual = true


func focus_selected() -> ResonanceTargetComponent:
	if _focus_selected != null and not is_instance_valid(_focus_selected):
		_focus_selected = null
	return _focus_selected


## Confirme la cible visée — le DISPATCH par nature (P2 §2.3 : une entrée,
## plusieurs contextes). `alt` inverse la Polarité (repousser).
func focus_confirm(player: PlayerController, alt: bool) -> StringName:
	var target: ResonanceTargetComponent = focus_selected()
	if target == null or player == null:
		return &"aucune_cible"
	match target.kind:
		&"arc_anchor":
			return try_arc_step(player, target)
		&"port":
			var node: ElectricNode = target.anchor() as ElectricNode
			if node == null:
				return &"invalide"
			if _link_first == null or not is_instance_valid(_link_first) \
					or node == _link_first:
				_link_first = node
				return &"port_a"
			var verdict: StringName = try_link(player, _link_first, node)
			if verdict == &"linked":
				_link_first = null
			return verdict
		&"polarity":
			var rigid: RigidBody3D = target.anchor() as RigidBody3D
			if rigid == null:
				return &"invalide"
			return try_polarity(player, rigid,
				&"repousser" if alt else &"attirer")
		&"material":
			return try_ground(player, target.anchor())
		_:
			return &"invalide"


## Sortir du focus oublie tout l'éphémère — y compris l'extrémité A d'un
## lien en cours de pose (P2 §3.8 : annulation lisible), jamais les liens
## déjà posés.
func focus_end() -> void:
	_focus_engaged = false
	_focus_candidates.clear()
	_focus_selected = null
	_focus_manual = false
	_link_first = null


## --- Ground (P2 §3.6) ---

## Engage la mise à la terre d'une cible chargée. Verdicts : `grounding`,
## `invalide`, `pas_de_charge`, `hors_portee`, `pas_au_sol`, `occupe`.
## RIEN n'est appliqué avant la fin du startup — jamais d'effet à moitié.
func try_ground(player: PlayerController, target: Node) -> StringName:
	if player == null or target == null or not is_instance_valid(target):
		return &"invalide"
	var state: MaterialStateComponent = target as MaterialStateComponent
	if state == null:
		state = _material_state_of(target)
	if state == null or not state.is_inside_tree():
		return &"invalide"
	if _ground_target != null:
		return &"occupe"
	var anchor: Node3D = state.get_parent() as Node3D
	if anchor == null:
		return &"invalide"
	if not state.is_charged() and not state.is_overloaded():
		return &"pas_de_charge"
	if anchor.global_position.distance_to(player.global_position) > GROUND_RANGE:
		return &"hors_portee"
	# Support valide (P2 §3.6) : le héros touche une terre réelle.
	if not player.is_on_floor():
		return &"pas_au_sol"
	if not player.begin_ground_lock(GROUND_STARTUP):
		return &"invalide"
	_ground_target = state
	_ground_player = player
	_ground_timer = GROUND_STARTUP
	return &"grounding"


func _drive_ground(delta: float) -> void:
	if _ground_target == null:
		return
	if not is_instance_valid(_ground_target) or not _ground_target.is_inside_tree() \
			or _ground_player == null or not is_instance_valid(_ground_player):
		_cancel_ground(&"cible_perdue")
		return
	var anchor: Node3D = _ground_target.get_parent() as Node3D
	if anchor == null or anchor.global_position.distance_to(
			_ground_player.global_position) > GROUND_RANGE + 1.0:
		_cancel_ground(&"hors_portee")
		return
	if _ground_player.mode() != PlayerController.Mode.LOCOMOTION:
		# Le héros a perdu la main (coup, chute) : la terre n'arrive jamais.
		_cancel_ground(&"interrompu")
		return
	_ground_timer -= delta
	if _ground_timer > 0.0:
		return
	# Fin du startup : le drainage s'applique EN ENTIER, maintenant.
	var target: MaterialStateComponent = _ground_target
	_ground_target = null
	_ground_player = null
	target.ground()
	ground_completed.emit(target)


func _cancel_ground(reason: StringName) -> void:
	_ground_target = null
	_ground_player = null
	_ground_timer = 0.0
	ground_cancelled.emit(reason)


## --- Arc Step (P2 §3.5) ---

## Valide TOUT le trajet puis délègue l'exécution au joueur. Verdicts :
## `step`, `invalide`, `cooldown`, `hors_portee`, `obstacle`, `pas_de_sol`,
## `endurance`. Un refus ne coûte jamais rien — le coût part à l'exécution.
func try_arc_step(player: PlayerController,
		anchor: ResonanceTargetComponent) -> StringName:
	if player == null or anchor == null or not is_instance_valid(anchor) \
			or not anchor.is_inside_tree() or anchor.kind != &"arc_anchor":
		return &"invalide"
	if _arc_step_cooldown > 0.0:
		return &"cooldown"
	var target: Node3D = anchor.anchor()
	if target == null:
		return &"invalide"
	var to: Vector3 = target.global_position
	if player.global_position.distance_to(to) > ARC_STEP_RANGE:
		return &"hors_portee"
	var planar: Vector3 = to - player.global_position
	planar.y = 0.0
	if planar.length() < 0.8:
		return &"invalide"
	# Arrivée : juste DEVANT l'ancrage, à hauteur du joueur — on rejoint un
	# point d'appui, on ne fusionne pas avec le mécanisme.
	var direction: Vector3 = planar.normalized()
	var arrival: Vector3 = Vector3(to.x, player.global_position.y, to.z) \
		- direction * 0.6
	# Sweep de la VRAIE capsule sur TOUT le trajet (P2 §3.5) — un obstacle
	# n'importe où refuse le dash, jamais de traversée.
	var shape_node: CollisionShape3D = \
		player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null or shape_node.shape == null:
		return &"invalide"
	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var params: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	params.shape = shape_node.shape
	params.transform = shape_node.global_transform
	params.motion = arrival - player.global_position
	params.collision_mask = 1
	params.exclude = [player.get_rid()]
	var motion: PackedFloat32Array = space.cast_motion(params)
	if motion.size() >= 1 and motion[0] < 0.98:
		return &"obstacle"
	# Validation d'arrivée : un sol réel sous le point d'atterrissage.
	var ground_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		arrival + Vector3.UP * 0.5, arrival + Vector3.DOWN * 3.5, 1,
		[player.get_rid()])
	if space.intersect_ray(ground_query).is_empty():
		return &"pas_de_sol"
	if not player.begin_arc_step(arrival, ARC_STEP_COST):
		return &"endurance"
	# Cooldown = durée estimée du dash + délai court (P2 §3.5 : 0,25-0,45 s).
	_arc_step_cooldown = params.motion.length() / ARC_STEP_SPEED + ARC_STEP_COOLDOWN
	return &"step"


## --- Arc Link (P2 §3.3) ---

func active_link() -> ResonanceLinkNode:
	if _link != null and not is_instance_valid(_link):
		_link = null
	return _link


## Tente de lier deux nœuds électriques. Verdicts explicables (P2 §3.8) :
## `linked`, `invalide`, `hors_portee` (joueur→ports), `trop_loin`
## (écart des ports), `pas_de_vue` (mur entre les ports).
func try_link(body: CharacterBody3D, a: ElectricNode, b: ElectricNode) -> StringName:
	if body == null or a == null or b == null or a == b \
			or not a.is_inside_tree() or not b.is_inside_tree():
		return &"invalide"
	if body.global_position.distance_to(a.global_position) > LINK_SELECT_RANGE \
			or body.global_position.distance_to(b.global_position) > LINK_SELECT_RANGE:
		return &"hors_portee"
	var a_port: Vector3 = _nearest_port(a, b.global_position)
	var b_port: Vector3 = _nearest_port(b, a_port)
	if a_port.distance_to(b_port) > LINK_MAX_SPAN:
		return &"trop_loin"
	# Ligne de vue ENTRE LES PORTS (P2 §3.3) — l'arc suit un trajet réel,
	# jamais à travers un mur. Légèrement surélevée : les ports posés au sol
	# ne doivent pas être « occlus » par le sol lui-même.
	var space: PhysicsDirectSpaceState3D = body.get_world_3d().direct_space_state
	var lift: Vector3 = Vector3.UP * 0.3
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		a_port + lift, b_port + lift, 1, [body.get_rid()])
	if not space.intersect_ray(query).is_empty():
		return &"pas_de_vue"
	# Un seul lien actif (P2 §3.3) : le nouveau remplace l'ancien.
	cancel_link()
	var link: ResonanceLinkNode = ResonanceLinkNode.new()
	# Même racine que les nœuds liés : le graphe le collectera avec eux.
	a.get_parent().add_child(link)
	link.bind(a, b, a_port, b_port)
	link.dissolved.connect(_on_link_dissolved)
	_link = link
	_mark_graphs_dirty()
	link_created.emit(a, b)
	return &"linked"


func cancel_link() -> void:
	if _link != null and is_instance_valid(_link):
		_link.dissolve()
	_link = null


func _on_link_dissolved() -> void:
	_link = null
	link_dissolved.emit()


func _nearest_port(node: ElectricNode, toward: Vector3) -> Vector3:
	var best: Vector3 = node.global_position
	var best_gap: float = INF
	for port: Dictionary in node.world_ports():
		var at: Vector3 = port["position"] as Vector3
		var gap: float = at.distance_to(toward)
		if gap < best_gap:
			best_gap = gap
			best = at
	return best


func _mark_graphs_dirty() -> void:
	for graph: Node in get_tree().get_nodes_in_group(&"electric_graphs"):
		if graph.has_method("mark_dirty"):
			graph.call("mark_dirty")


## LOS calquée sur `EnemyBase._has_los` : monde statique (couche 1), deux
## hauteurs de visée — voir l'une des deux suffit.
func _has_los(space: PhysicsDirectSpaceState3D, from: Vector3,
		target: Vector3, body: CharacterBody3D) -> bool:
	for height: float in [0.2, 0.8]:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			from, target + Vector3.UP * height, 1, [body.get_rid()])
		if space.intersect_ray(query).is_empty():
			return true
	return false
