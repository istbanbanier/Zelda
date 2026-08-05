## Arbitre central des réactions matière (P2 §4.3/§4.4) — nœud de SCÈNE,
## jamais un autoload (D-047 : hermétisme des tests, état jamais partagé entre
## scènes). Chaque monde et chaque lab instancie le sien ; découverte par le
## groupe `reaction_system` via `locate()`.
##
## Contrat :
## - `submit()` met en file ; la résolution se fait au tick physique, sous
##   budget borné (P2 §4.4 : plafond de travail par tick, le surplus attend le
##   tick suivant — jamais perdu, jamais de cascade non bornée) ;
## - une cible n'est touchée qu'UNE fois par action (`packet.chain`) ;
## - aucune énergie créée : la charge stockée est plafonnée par le profil,
##   l'atténuation de propagation est ≤ 1.
class_name ReactionSystem
extends Node

signal reaction_resolved(target: Node, results: PackedStringArray, packet: ElementPacket)

## Budget de résolutions par tick physique (P2 §4.4). Le surplus reste en file.
const PACKETS_PER_TICK: int = 48
## Chaleur minimale pour enflammer une matière inflammable.
const FLASH_HEAT: float = 2.0
## Couplage électrique amélioré sur cible mouillée (P2 §4.2). Ce multiplicateur
## s'applique à la RÉCEPTION ; le stock reste plafonné par `charge_capacity` —
## il ne crée pas d'énergie, il modélise un meilleur contact.
const WET_ELECTRIC_COUPLING: float = 1.5

## File FIFO : { "target_id": int, "packet": ElementPacket }.
var _queue: Array[Dictionary] = []
## Compteur de résolutions du tick courant (remis à zéro chaque tick).
var _resolved_this_tick: int = 0


static func locate(tree: SceneTree) -> ReactionSystem:
	if tree == null:
		return null
	return tree.get_first_node_in_group(&"reaction_system") as ReactionSystem


func _ready() -> void:
	add_to_group(&"reaction_system")


func _physics_process(_delta: float) -> void:
	_resolved_this_tick = 0
	while not _queue.is_empty() and _resolved_this_tick < PACKETS_PER_TICK:
		var entry: Dictionary = _queue.pop_front() as Dictionary
		_resolve_entry(entry)


## Met en file une interaction. Résolution au tick physique courant ou suivant.
func submit(target: Node, packet: ElementPacket) -> void:
	if target == null or packet == null or packet.is_empty():
		return
	_queue.append({ "target_id": target.get_instance_id(), "packet": packet })


## Résolution SYNCHRONE — pour les tests unitaires et les cas où l'appelant
## est déjà dans le tick physique (hitbox). Respecte le même budget.
func resolve_now(target: Node, packet: ElementPacket) -> PackedStringArray:
	var state: MaterialStateComponent = _state_of(target)
	if state == null:
		return PackedStringArray(["sans_matiere"])
	return _resolve(state, packet)


func pending_count() -> int:
	return _queue.size()


func _resolve_entry(entry: Dictionary) -> void:
	var target: Node = instance_from_id(int(entry["target_id"])) as Node
	if target == null or not is_instance_valid(target):
		return
	var state: MaterialStateComponent = _state_of(target)
	if state == null:
		return
	var packet: ElementPacket = entry["packet"] as ElementPacket
	var results: PackedStringArray = _resolve(state, packet)
	_resolved_this_tick += 1
	reaction_resolved.emit(target, results, packet)


func _resolve(state: MaterialStateComponent, packet: ElementPacket) -> PackedStringArray:
	var results: PackedStringArray = PackedStringArray()
	var owner_id: int = state.get_instance_id()
	# Anti-boucle §4.3 : une cible, une fois par action. Le set `chain` est
	# PARTAGÉ par tous les paquets d'une même action (référence commune).
	if owner_id in packet.chain:
		results.append("deja_touche")
		return results
	packet.chain.append(owner_id)
	var profile: MaterialProfile = state.profile

	# Ordre fixe : eau → chaleur → électricité → cinétique. L'eau d'abord,
	# pour qu'un paquet mixte (vapeur brûlante) mouille AVANT le test du feu.
	if packet.wetness > 0.0:
		state.soak()
		results.append("mouille")
	if packet.heat > 0.0:
		if state.is_wet():
			results.append("humide_refuse")
		elif profile != null and profile.flammability > 0.0 and packet.heat >= FLASH_HEAT:
			state.ignite()
			results.append("enflamme")
		else:
			results.append("incombustible")
	if packet.electric > 0.0:
		if state.is_grounded():
			results.append("dissipe")
		elif profile != null and profile.charge_capacity > 0.0:
			var coupling: float = WET_ELECTRIC_COUPLING if state.is_wet() else 1.0
			state.add_charge(packet.electric * coupling)
			results.append("charge")
		elif profile != null and profile.conductivity > 0.0:
			results.append("traverse")
		else:
			results.append("isole")
	if packet.kinetic > 0.0:
		if profile != null and profile.fragility > 0.0 \
				and packet.kinetic >= profile.fracture_threshold:
			state.fracture()
			results.append("fracture")
		else:
			results.append("encaisse")
	return results


func _state_of(target: Node) -> MaterialStateComponent:
	if target is MaterialStateComponent:
		return target as MaterialStateComponent
	for child: Node in target.get_children():
		if child is MaterialStateComponent:
			return child as MaterialStateComponent
	return null
