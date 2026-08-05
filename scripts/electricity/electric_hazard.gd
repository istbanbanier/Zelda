## Électrode intermittente (MASTER_SPEC §15.1 `HazardNode`, §15.4, §15.6).
##
## §15.6 exige un « rythme observable » : la décharge n'est pas aléatoire,
## elle bat. Le joueur regarde depuis le bas, compte, puis grimpe — c'est
## l'énigme. Une électrode qui frapperait au hasard ne serait pas une
## difficulté mais un impôt.
##
## Trois effets pendant la décharge, tous nécessaires :
##   1. dégâts électriques au corps présent, avec un temps de recharge —
##      jamais une saignée par image ;
##   2. la paroi gardée entre dans le groupe `electrified`, que
##      `ClimbingComponent` REFUSE (§9.2) : on ne s'accroche pas à un
##      barreau sous tension ;
##   3. la barre passe de sombre à cœur blanc/halo cyan (§15.4).
##
## §13.5 : la résistance électrique divise les dégâts. C'est ici qu'elle
## sert pour la première fois.
class_name ElectricHazard
extends Node3D

## La décharge vient de commencer / de finir.
signal discharge_changed(active: bool)

const COL_DARK: Color = Color(0.26, 0.24, 0.28)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)
const COL_CORE: Color = Color(0.925, 1.0, 1.0)

## P2-5 (P2 §4.2) : une nappe `WATER_ZONE` parle les LOIS COMMUNES — elle
## porte la matière `eau`, mouille ce qui y entre et, sous tension, RELAIE
## l'électricité à la matière qu'elle baigne. L'eau traverse, elle ne
## stocke pas : même loi que le bassin de la vallée.
const PROFILE_EAU: MaterialProfile = \
	preload("res://resources/materials/MAT_PROFILE_eau.tres")
## Énergie relayée par impulsion (cadence : `damage_interval`). Le métal
## (capacité 10) se remplit en quelques impulsions — plus vite mouillé,
## par le couplage humide des lois.
const RELAY_ELECTRIC: float = 2.0

@export var hazard_id: StringName = &""
## Type de nœud : `HAZARD` pour une électrode, `WATER_ZONE` pour une nappe
## d'eau conductrice (§15.1). Le comportement de décharge est le même ; ce
## qui change, c'est ce que le graphe et la carte murale en disent.
@export var node_kind: ElectricNode.Kind = ElectricNode.Kind.HAZARD
## Durée de décharge, puis durée de repos. §15.6 : le rythme doit être
## OBSERVABLE — la fenêtre calme doit suffire à franchir la zone. Un
## `off_time` nul donne une décharge CONTINUE : c'est le cas d'une nappe
## d'eau alimentée (§15.8), qui n'est pas un piège rythmé mais un état.
@export var on_time: float = 1.1
@export var off_time: float = 1.7
## Décalage de phase : deux électrodes voisines ne battent pas ensemble.
@export var phase_offset: float = 0.0
@export var damage: float = 12.0
## Temps de recharge entre deux coups sur la même victime.
@export var damage_interval: float = 0.9
@export var area_size: Vector3 = Vector3(2.6, 2.2, 3.0)
## Décalage de la zone par rapport à l'électrode : la décharge part de la
## barre et couvre la ligne d'escalade, pas le mur derrière.
@export var area_offset: Vector3 = Vector3(0, 0, 0.6)
## Corps statique rendu inaccrochable pendant la décharge (§9.2).
@export var guarded_body_path: NodePath
## Ports du nœud, en local (§15.3).
@export var node_port_offsets: Array[Vector3] = []
@export var node_port_reach: float = 0.55

var _node: ElectricNode = null
var _area: Area3D = null
var _bar: MeshInstance3D = null
var _material: StandardMaterial3D = null
var _glow: OmniLight3D = null
var _guarded: Node = null
var _timer: float = 0.0
var _active: bool = false
var _cooldowns: Dictionary[Node, float] = {}
var _matter: MaterialStateComponent = null
var _reactions: ReactionSystem = null
var _pulse_serial: int = 0


func _ready() -> void:
	_build()
	_guarded = get_node_or_null(guarded_body_path)
	_timer = phase_offset
	_node.power_changed.connect(_on_power_changed)
	if node_kind == ElectricNode.Kind.WATER_ZONE:
		_setup_water_matter()
	set_physics_process(true)
	_apply_visual()


## La nappe devient de la MATIÈRE (P2 §4.1) : profil `eau`, arbitre des
## réactions garanti (un nœud de SCÈNE, D-047 — créé localement si la
## salle n'en fournit pas), et les props (couche 128) deviennent visibles
## de la zone — le chemin de dégâts, lui, ne lit que les hurtbox.
func _setup_water_matter() -> void:
	_matter = MaterialStateComponent.new()
	_matter.name = "MaterialState"
	_matter.profile = PROFILE_EAU
	add_child(_matter)
	_area.collision_mask = 2 | 128
	_area.body_entered.connect(_on_body_entered_water)
	_reactions = ReactionSystem.locate(get_tree())
	if _reactions == null:
		_reactions = ReactionSystem.new()
		_reactions.name = "ReactionSystem"
		add_child(_reactions)


## L'eau MOUILLE ce qui y entre, tension ou pas — c'est de l'eau. Une
## cible sans matière est ignorée par l'arbitre (sans_matiere).
func _on_body_entered_water(body: Node3D) -> void:
	if _reactions == null or not is_instance_valid(_reactions):
		return
	_pulse_serial += 1
	var packet: ElementPacket = ElementPacket.new()
	packet.wetness = 1.0
	packet.action_id = StringName("%s.soak.%d" % [hazard_id, _pulse_serial])
	packet.position = body.global_position
	_reactions.submit(body, packet)


func _build() -> void:
	_node = ElectricNode.new()
	_node.name = "HazardNode"
	_node.node_id = hazard_id
	_node.kind = node_kind
	_node.conductivity = 1.0
	_node.port_offsets = node_port_offsets
	_node.port_reach = node_port_reach
	add_child(_node)

	_bar = MeshInstance3D.new()
	_bar.name = "Bar"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1.4, 0.22, 0.22)
	_bar.mesh = box
	_material = StandardMaterial3D.new()
	_material.albedo_color = COL_DARK
	_bar.material_override = _material
	add_child(_bar)

	_area = Area3D.new()
	_area.name = "Zone"
	_area.collision_layer = 0
	_area.collision_mask = 2   # Player
	_area.monitoring = true
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = area_size
	shape.shape = box_shape
	shape.position = area_offset
	_area.add_child(shape)
	add_child(_area)

	_glow = OmniLight3D.new()
	_glow.name = "Glow"
	_glow.light_color = COL_CYAN
	_glow.light_energy = 0.0
	_glow.omni_range = 7.0
	add_child(_glow)


func _on_power_changed(powered: bool, _power: float) -> void:
	if powered:
		return
	# Coupé : la décharge s'arrête NET et la paroi redevient accrochable.
	_active = false
	_timer = 0.0
	_set_guard(false)
	_apply_visual()
	discharge_changed.emit(false)


func _physics_process(delta: float) -> void:
	if not _node.is_powered():
		return
	_timer += delta
	var period: float = maxf(0.1, on_time + off_time)
	var phase: float = fmod(_timer, period)
	var should_be_active: bool = phase < on_time
	if should_be_active != _active:
		_active = should_be_active
		_set_guard(_active)
		_apply_visual()
		discharge_changed.emit(_active)
	if _active:
		_shock_bodies(delta)


func _shock_bodies(delta: float) -> void:
	for body: Node3D in _area.get_overlapping_bodies():
		var remaining: float = float(_cooldowns.get(body, 0.0)) - delta
		if remaining > 0.0:
			_cooldowns[body] = remaining
			continue
		var acted: bool = _apply_shock(body)
		if _relay_to_matter(body):
			acted = true
		if acted:
			_cooldowns[body] = damage_interval


## P2-5 : l'eau sous tension relaie l'électricité à la MATIÈRE qu'elle
## baigne, à la cadence des dégâts, une impulsion = une action (chaîne
## anti-boucle §4.3). Une eau mise à la terre DISSIPE : le relais se
## suspend — le chemin de dégâts du graphe, lui, continue : la terre est
## une loi de matière, pas un coupe-circuit.
func _relay_to_matter(body: Node3D) -> bool:
	if node_kind != ElectricNode.Kind.WATER_ZONE or _reactions == null:
		return false
	if _matter != null and _matter.is_grounded():
		return false
	var has_matter: bool = false
	for child: Node in body.get_children():
		if child is MaterialStateComponent:
			has_matter = true
			break
	if not has_matter:
		return false
	_pulse_serial += 1
	var packet: ElementPacket = ElementPacket.electric_burst(RELAY_ELECTRIC,
		StringName("%s.pulse.%d" % [hazard_id, _pulse_serial]))
	packet.position = body.global_position
	_reactions.submit(body, packet)
	return true


func _apply_shock(body: Node3D) -> bool:
	var hurtboxes: Array[Node] = body.find_children("*", "HurtboxComponent",
		true, false)
	if hurtboxes.is_empty():
		return false
	var event: DamageEvent = DamageEvent.new()
	event.instigator = self
	event.team = &"hazard"
	event.damage_type = &"electric"
	event.element = &"electric"
	event.amount = damage * _resistance_multiplier(body)
	event.direction = (body.global_position - global_position).normalized()
	event.position = global_position
	event.knockback = 3.0
	(hurtboxes[0] as HurtboxComponent).receive_hit(event)
	return true


## §13.5 : « Résistance électrique : -60 % de dégâts électriques ». C'est
## ici que le plat de baies sert enfin à quelque chose.
func _resistance_multiplier(body: Node3D) -> float:
	var status: Array[Node] = body.find_children("*", "StatusEffectComponent",
		true, false)
	if status.is_empty():
		return 1.0
	return float((status[0] as StatusEffectComponent).elec_damage_multiplier())


## §9.2 : `electrified` fait partie des groupes que l'escalade REFUSE.
func _set_guard(active: bool) -> void:
	if _guarded == null:
		return
	if active and not _guarded.is_in_group("electrified"):
		_guarded.add_to_group("electrified")
	elif not active and _guarded.is_in_group("electrified"):
		_guarded.remove_from_group("electrified")


func _apply_visual() -> void:
	if _material == null:
		return
	var live: bool = _active and _node.is_powered()
	_material.albedo_color = COL_CORE if live else COL_DARK
	_material.emission_enabled = live
	_material.emission = COL_CYAN
	_material.emission_energy_multiplier = 4.0 if live else 0.0
	_glow.light_energy = 2.6 if live else 0.0


func is_discharging() -> bool:
	return _active and _node.is_powered()


func node() -> ElectricNode:
	return _node


## Fenêtre calme, en secondes — un test vérifie qu'elle suffit à franchir
## la zone à la vitesse d'escalade.
func quiet_window() -> float:
	return off_time
