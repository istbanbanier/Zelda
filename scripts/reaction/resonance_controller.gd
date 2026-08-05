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

var _pulse_cooldown: float = 0.0
var _link: ResonanceLinkNode = null


## À appeler chaque tick physique par le propriétaire, quel que soit le mode.
func tick(delta: float) -> void:
	_pulse_cooldown = maxf(0.0, _pulse_cooldown - delta)


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
