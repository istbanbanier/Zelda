## L'EAU comme MATIÈRE des lois (P2 §4.1/§4.2) — composant PARTAGÉ entre
## la nappe du donjon (`ElectricHazard` WATER_ZONE) et le bassin de la
## vallée (`ConductiveBasin`) : ISS-030, l'asymétrie vallée/donjon levée.
##
## Trois faits, les mêmes partout :
## 1. l'eau EST de la matière (profil `eau`, état sur le NŒUD porteur —
##    Pulse la lit, Ground la visite) ;
## 2. l'eau MOUILLE ce qui y entre, tension ou pas (paquet `wetness`) ;
## 3. sous tension, l'eau RELAIE l'électricité à la matière baignée
##    (une impulsion par cadence et par cible, action_id par impulsion,
##    chaîne anti-boucle §4.3) — l'eau traverse, elle ne stocke pas
##    (capacité 0). Une eau mise à la terre DISSIPE : relais suspendu.
##
## Le composant ne porte AUCUN dégât : le chemin de dégâts du danger
## (§13.5, résistance électrique) reste à `ElectricHazard`. Le bassin,
## lui, reste une école SÛRE (P2 §9.6) — mêmes lois, zéro punition.
class_name WaterMatterComponent
extends Node

const PROFILE_EAU: MaterialProfile = \
	preload("res://resources/materials/MAT_PROFILE_eau.tres")
## Énergie relayée par impulsion (métal : capacité 10, couplage humide
## ×1,5 à la réception — plafonnée par le profil, jamais créée).
const RELAY_ELECTRIC: float = 2.0

## Nœud électrique porteur (la vérité de tension) — le composant lui
## attache l'état de matière, sous le nom `MaterialState`.
@export var node_path: NodePath
## Zone de baignade (couches : joueur 2 + props 128).
@export var area_path: NodePath
## Cadence du relais, par cible.
@export var relay_interval: float = 0.9

var _node: ElectricNode = null
var _area: Area3D = null
var _state: MaterialStateComponent = null
var _reactions: ReactionSystem = null
var _pulse_serial: int = 0
var _cooldowns: Dictionary[Node, float] = {}


func _ready() -> void:
	_node = get_node_or_null(node_path) as ElectricNode
	_area = get_node_or_null(area_path) as Area3D
	if _node == null or _area == null:
		push_warning("[eau] WaterMatterComponent sans nœud ou sans zone")
		set_physics_process(false)
		return
	_state = MaterialStateComponent.new()
	_state.name = "MaterialState"
	_state.profile = PROFILE_EAU
	_node.add_child(_state)
	_area.body_entered.connect(_on_body_entered)
	# Arbitre garanti (D-047 : nœud de SCÈNE, jamais un autoload) —
	# localisé, sinon créé localement.
	_reactions = ReactionSystem.locate(get_tree())
	if _reactions == null:
		_reactions = ReactionSystem.new()
		_reactions.name = "ReactionSystem"
		add_child(_reactions)
	set_physics_process(true)


func state() -> MaterialStateComponent:
	return _state


## L'eau MOUILLE ce qui y entre — c'est de l'eau, tension ou pas. Une
## cible sans matière est ignorée par l'arbitre (sans_matiere).
func _on_body_entered(body: Node3D) -> void:
	if _reactions == null or not is_instance_valid(_reactions):
		return
	_pulse_serial += 1
	var packet: ElementPacket = ElementPacket.new()
	packet.wetness = 1.0
	packet.action_id = StringName("%s.soak.%d"
		% [_node.node_id, _pulse_serial])
	packet.position = body.global_position
	_reactions.submit(body, packet)


func _physics_process(delta: float) -> void:
	if not _node.is_powered():
		return
	# Terre = dissipation : le relais se suspend, la loi de matière prime.
	if _state != null and _state.is_grounded():
		return
	for body: Node3D in _area.get_overlapping_bodies():
		var remaining: float = float(_cooldowns.get(body, 0.0)) - delta
		if remaining > 0.0:
			_cooldowns[body] = remaining
			continue
		if _relay_to(body):
			_cooldowns[body] = relay_interval


func _relay_to(body: Node3D) -> bool:
	var has_matter: bool = false
	for child: Node in body.get_children():
		if child is MaterialStateComponent:
			has_matter = true
			break
	if not has_matter:
		return false
	_pulse_serial += 1
	var packet: ElementPacket = ElementPacket.electric_burst(RELAY_ELECTRIC,
		StringName("%s.pulse.%d" % [_node.node_id, _pulse_serial]))
	packet.position = body.global_position
	_reactions.submit(body, packet)
	return true
