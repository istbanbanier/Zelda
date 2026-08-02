## Coordinateur de combat par groupe (D-EN.3, MASTER_SPEC §12.8).
##
## Tokens d'attaque : DEUX mêlée ordinaires, UN lourd. Un ennemi sans
## token encercle/menace au lieu de frapper (le socle orbite). La
## LIBÉRATION est GARANTIE structurellement : un token n'est tenu que
## par un porteur VIVANT et EN ÉTAT D'ATTAQUE — la purge par cadence
## élimine morts, invalides et sortis de combat, aucune référence morte
## ne bloque la file. Plafond §12.9 : 10-14 IA pleinement actives — les
## plus lointaines du joueur dorment (physique coupée) jusqu'à leur tour.
##
## SANS coordinateur dans la scène, le socle accorde implicitement : les
## duels solitaires (tests, labo) ne changent pas.
class_name CombatCoordinator
extends Node

const MELEE_TOKENS: int = 2
const HEAVY_TOKENS: int = 1
## §12.9 : « limiter à 10-14 IA pleinement actives » — borne haute.
const MAX_ACTIVE_AI: int = 14
## Cadence de purge et d'application du plafond (jamais par frame).
const GOVERN_INTERVAL: int = 12

var _melee_holders: Array[EnemyBase] = []
var _heavy_holders: Array[EnemyBase] = []
var _govern_tick: int = 0


func _ready() -> void:
	add_to_group("combat_coordinator")


func _physics_process(_delta: float) -> void:
	_govern_tick += 1
	if _govern_tick % GOVERN_INTERVAL != 0:
		return
	_purge(_melee_holders)
	_purge(_heavy_holders)
	_enforce_activity_cap()


## Un porteur légitime est VIVANT et encore EN ATTAQUE — tout le reste
## sort de la file (mort, stagger, fuite, invalide) : garantie §12.8.
func _purge(holders: Array[EnemyBase]) -> void:
	for i: int in range(holders.size() - 1, -1, -1):
		var holder: EnemyBase = holders[i]
		if holder == null or not is_instance_valid(holder) \
				or holder.health().is_dead() \
				or holder.state() != EnemyBase.State.ATTACK:
			holders.remove_at(i)


func request_token(enemy: EnemyBase, kind: StringName) -> bool:
	var holders: Array[EnemyBase] = _heavy_holders if kind == &"heavy" \
		else _melee_holders
	var limit: int = HEAVY_TOKENS if kind == &"heavy" else MELEE_TOKENS
	_purge(holders)
	if holders.has(enemy):
		return true
	if holders.size() >= limit:
		return false
	holders.append(enemy)
	return true


func release_token(enemy: EnemyBase) -> void:
	_melee_holders.erase(enemy)
	_heavy_holders.erase(enemy)


func melee_holder_count() -> int:
	_purge(_melee_holders)
	return _melee_holders.size()


## Plafond d'IA actives (§12.9) : au-delà de MAX_ACTIVE_AI vivantes, les
## plus LOINTAINES du joueur dorment — physique coupée, réveillées quand
## leur rang revient. Les mortes ne comptent ni ne dorment.
func _enforce_activity_cap() -> void:
	var player: Node3D = null
	for node: Node in get_tree().get_nodes_in_group("player"):
		player = node as Node3D
		break
	if player == null:
		return
	var living: Array[EnemyBase] = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: EnemyBase = node as EnemyBase
		if enemy != null and is_instance_valid(enemy) \
				and not enemy.health().is_dead():
			living.append(enemy)
	if living.size() <= MAX_ACTIVE_AI:
		for enemy: EnemyBase in living:
			if not enemy.is_physics_processing():
				enemy.set_physics_process(true)
		return
	living.sort_custom(func(a: EnemyBase, b: EnemyBase) -> bool:
		return a.global_position.distance_squared_to(player.global_position) \
			< b.global_position.distance_squared_to(player.global_position))
	for i: int in range(living.size()):
		var should_run: bool = i < MAX_ACTIVE_AI
		if living[i].is_physics_processing() != should_run:
			living[i].set_physics_process(should_run)


func active_enemy_count() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: EnemyBase = node as EnemyBase
		if enemy != null and is_instance_valid(enemy) \
				and enemy.is_physics_processing() \
				and not enemy.health().is_dead():
			count += 1
	return count
