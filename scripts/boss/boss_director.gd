## Directeur de patterns du boss (P2 §10.5) — remplace le `randf()` pur de
## `_choose_attack` : « ne pas utiliser de random pur sans historique ».
##
## La bibliothèque est TAGUÉE (portée, phases, cooldown, poids) ; le directeur
## ne choisit que parmi les patterns LÉGAUX, refuse la répétition immédiate
## quand une alternative légale existe, consigne chaque choix, et rejoue
## exactement la même séquence à seed égal — la reproduction d'un bug de
## combat devient une commande, pas une chance.
class_name BossDirector
extends RefCounted

## Bibliothèque : { id: StringName, min_range: float, max_range: float,
## phases: Array[StringName], cooldown: float, weight: float }.
var _library: Array[Dictionary] = []
## id -> temps de recharge restant.
var _cooldowns: Dictionary = {}
var _last: StringName = &""
var _history: Array[StringName] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _seed: int = 0


func _init(seed_value: int = 0) -> void:
	# Seed 0 = tirée puis CONSIGNÉE — la reproduction reste possible même
	# quand personne ne l'a demandée d'avance (P2 §10.5).
	if seed_value == 0:
		_rng.randomize()
		_seed = int(_rng.seed)
	else:
		_seed = seed_value
		_rng.seed = seed_value


func set_library(patterns: Array[Dictionary]) -> void:
	_library = patterns
	_cooldowns.clear()
	for pattern: Dictionary in _library:
		_cooldowns[pattern["id"]] = 0.0


func seed_used() -> int:
	return _seed


func history() -> Array[StringName]:
	return _history


## Décompte des recharges — appelé par le propriétaire au rythme qu'il veut
## (le sien : le tick physique ; les tests : des sauts francs).
func tick(delta: float) -> void:
	for id: Variant in _cooldowns:
		_cooldowns[id] = maxf(0.0, float(_cooldowns[id]) - delta)


## Choisit un pattern légal pour cette distance et cette phase. `&""` = rien
## de légal — le boss ATTEND, fallback déterministe, jamais un coup illégal.
func pick(distance: float, phase: StringName) -> StringName:
	var legal: Array[Dictionary] = []
	for pattern: Dictionary in _library:
		if distance < float(pattern["min_range"]) \
				or distance > float(pattern["max_range"]):
			continue
		if not phase in (pattern["phases"] as Array):
			continue
		if float(_cooldowns.get(pattern["id"], 0.0)) > 0.0:
			continue
		legal.append(pattern)
	if legal.is_empty():
		return &""
	# Anti-répétition : le dernier choix s'écarte SI une alternative existe.
	if legal.size() > 1:
		for i: int in range(legal.size() - 1, -1, -1):
			if StringName(legal[i]["id"]) == _last:
				legal.remove_at(i)
	# Tirage pondéré, sur le générateur SEMÉ.
	var total: float = 0.0
	for pattern: Dictionary in legal:
		total += float(pattern["weight"])
	var roll: float = _rng.randf() * total
	var chosen: Dictionary = legal[legal.size() - 1]
	for pattern: Dictionary in legal:
		roll -= float(pattern["weight"])
		if roll <= 0.0:
			chosen = pattern
			break
	var id: StringName = chosen["id"] as StringName
	_cooldowns[id] = float(chosen["cooldown"])
	_last = id
	_history.append(id)
	return id
