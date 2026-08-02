## Nœud du graphe électrique (MASTER_SPEC §15.1) — la BRIQUE commune de
## tous les types de §15.1. Un nœud est un `Node3D` : sa position dans le
## monde EST sa donnée de connexion (§15.3 : les connexions dépendent de
## contacts réels, pas d'un point invisible).
##
## Contrat de §15.1, au complet :
## - ID stable (`node_id`, sauvegardable §19.3) ;
## - PORTS d'entrée/sortie, orientés dans l'espace local ;
## - état alimenté, puissance normalisée, conductivité ;
## - signaux `connection_changed` et `power_changed` ;
## - `set_powered(value)` IDEMPOTENT — appelé deux fois de suite avec la
##   même valeur, il n'émet rien la seconde fois ;
## - la représentation visuelle/audio vit AILLEURS : ce script ne
##   contient aucune ligne de rendu.
##
## Le graphe (`ElectricGraph`) fait la propagation ; un nœud ne connaît
## que ses ports et son état.
class_name ElectricNode
extends Node3D

## Un changement de connexion (le graphe a relié ou coupé un voisin).
signal connection_changed()
## L'alimentation a CHANGÉ — jamais réémis à valeur égale (§15.2 pt. 9).
signal power_changed(powered: bool, power: float)

## Rôle du nœud dans le graphe (§15.1). Le comportement de propagation
## en dépend ; le type n'est pas décoratif.
enum Kind {
	SOURCE, CABLE, CONNECTOR, SWITCH, MOVABLE_CONDUCTOR, RELAY,
	RECEIVER, DOOR, HAZARD, BATTERY, WATER_ZONE,
}

## Sens d'un port : ce qu'il accepte.
enum PortFlow { INPUT, OUTPUT, BOTH }

## §19.3 : `zone.category.name.index`. Un ID vide est refusé par le
## validateur du graphe.
@export var node_id: StringName = &""
@export var kind: Kind = Kind.CABLE
## Conductivité 0-1 (§14.4). Sous ce seuil, le courant ne passe pas —
## un isolant (céramique ivoire) est un nœud à conductivité nulle.
@export_range(0.0, 1.0) var conductivity: float = 1.0
## Distance maximale à laquelle DEUX PORTS se touchent (§15.3 : contact
## réel avec tolérance, jamais une proximité vague).
@export var port_reach: float = 0.6
## Interrupteur fermé / source active / batterie chargée : ce que le
## joueur contrôle. Sans effet sur les autres types.
@export var enabled: bool = true
## SOURCE seulement : puissance injectée (1.0 = pleine).
@export var source_power: float = 1.0
## Ports, en coordonnées LOCALES : la rotation du nœud les emmène avec
## elle (§15.3 : « pour une colonne rotative, dépendre de l'orientation
## des ports »). Vide = un port omnidirectionnel au centre.
@export var port_offsets: Array[Vector3] = []
@export var port_flows: Array[int] = []

var _powered: bool = false
var _power: float = 0.0
## Voisins RÉELLEMENT connectés au dernier calcul (§15.1).
var _neighbours: Array[ElectricNode] = []
## Nombre de sauts depuis la source la plus proche au dernier calcul.
## -1 = non atteint. C'est ce qui permet à la présentation d'étaler la
## montée du cyan le long du câble (§15.4 : « ligne cyan qui se PROPAGE
## de 0 à 1 »), sans que la logique connaisse le rendu.
var _hop: int = -1


func _ready() -> void:
	add_to_group("electric_nodes")
	if node_id == &"":
		push_warning("[électricité] nœud sans ID stable : %s" % name)


## Ports en coordonnées MONDE, avec leur sens. Un nœud sans port déclaré
## expose un port unique omnidirectionnel à son origine.
func world_ports() -> Array[Dictionary]:
	var ports: Array[Dictionary] = []
	if port_offsets.is_empty():
		ports.append({
			"position": global_position,
			"flow": PortFlow.BOTH,
		})
		return ports
	for i: int in range(port_offsets.size()):
		var flow: int = int(port_flows[i]) if i < port_flows.size() \
			else PortFlow.BOTH
		ports.append({
			"position": global_transform * port_offsets[i],
			"flow": flow,
		})
	return ports


## Le courant peut-il TRAVERSER ce nœud ? Un interrupteur ouvert coupe ;
## un isolant coupe ; une source coupée ne se laisse pas traverser.
func conducts() -> bool:
	if conductivity <= 0.0:
		return false
	match kind:
		Kind.SWITCH:
			return enabled
		Kind.SOURCE:
			return enabled
		Kind.BATTERY:
			return enabled
	return true


## Ce nœud INJECTE-t-il du courant ? Les sources actives, et les
## batteries chargées posées dans leur socket.
func is_emitting() -> bool:
	return kind in [Kind.SOURCE, Kind.BATTERY] and enabled and conductivity > 0.0


## §15.1 : IDEMPOTENT. Deux appels de suite à la même valeur n'émettent
## qu'une fois — c'est ce qui permet au graphe de tout recalculer sans
## faire clignoter la présentation (§15.2 pt. 9).
func set_powered(value: bool, power: float = 1.0) -> void:
	var new_power: float = power if value else 0.0
	if value == _powered and is_equal_approx(new_power, _power):
		return
	_powered = value
	_power = new_power
	power_changed.emit(_powered, _power)


func is_powered() -> bool:
	return _powered


func power() -> float:
	return _power


## Posé par le graphe AVANT `set_powered` : la présentation lit une
## profondeur déjà à jour quand le signal arrive.
func set_hop_depth(value: int) -> void:
	_hop = value


func hop_depth() -> int:
	return _hop


## Remplacé par le graphe à chaque reconstruction. Émet
## `connection_changed` UNIQUEMENT si l'ensemble a réellement changé.
func set_neighbours(neighbours: Array[ElectricNode]) -> void:
	if neighbours.size() == _neighbours.size():
		var identical: bool = true
		for node: ElectricNode in neighbours:
			if not _neighbours.has(node):
				identical = false
				break
		if identical:
			return
	_neighbours = neighbours
	connection_changed.emit()


func neighbours() -> Array[ElectricNode]:
	return _neighbours


## L'état sauvegardable du nœud (§19.1) : ce que le joueur a changé, pas
## ce que le graphe a calculé — l'alimentation se RECALCULE au chargement.
func save_state() -> Dictionary:
	return {"id": String(node_id), "enabled": enabled}


func apply_state(state: Dictionary) -> void:
	enabled = bool(state.get("enabled", enabled))
