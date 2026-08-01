## Exemplaire d'arme (MASTER_SPEC §5.9, §11.2) — l'état mutable, séparé.
##
## La `WeaponDefinition` est partagée par tous les exemplaires ; CE qui distingue
## un exemplaire — sa durabilité restante — vit ici. L'invariant de CLAUDE.md
## (« deux exemplaires ne partagent jamais leur durabilité ») tient à cette
## séparation, et `tests/unit/test_weapon_data.gd` la défend dans les deux sens :
## l'exemplaire jumeau ET la définition doivent rester intacts quand celui-ci
## s'use.
##
## §11.2 : l'usure n'est appliquée QUE par un coup qui touche — c'est l'appelant
## (le contrôleur du porteur, sur `hit_confirmed`) qui décide quand appeler
## `apply_hit_wear()` ; l'exemplaire ne connaît ni hitbox ni swing.
class_name WeaponInstance
extends RefCounted

## §11.2 : « à 25 % : avertissement bref [...] sans spam » — émis UNE fois.
signal durability_warned()
## §11.2 : « à zéro : rupture » — émis UNE fois ; l'exemplaire est fini.
signal broke()

const WARNING_FRACTION: float = 0.25

## Compteur global : deux exemplaires ne partagent jamais un identifiant, même
## créés depuis la même définition (le pattern de `HitboxComponent`).
static var _next_instance_id: int = 1

var instance_id: int = 0
var definition: WeaponDefinition = null
var current_durability: int = 0

var _warned: bool = false
var _broke_emitted: bool = false


static func create(from_definition: WeaponDefinition) -> WeaponInstance:
	var instance: WeaponInstance = WeaponInstance.new()
	instance.instance_id = _next_instance_id
	_next_instance_id += 1
	instance.definition = from_definition
	instance.current_durability = from_definition.max_durability
	return instance


## Identité durable pour la sauvegarde (§19.2 : des IDs, jamais des références).
func definition_id() -> StringName:
	return definition.id if definition != null else &""


## Un coup qui a TOUCHÉ (§11.2 : « jamais dans le vide ») coûte un point.
func apply_hit_wear() -> void:
	if current_durability <= 0:
		return
	current_durability -= 1
	if current_durability <= 0:
		if not _broke_emitted:
			_broke_emitted = true
			broke.emit()
		return
	if not _warned and durability_fraction() <= WARNING_FRACTION:
		_warned = true
		durability_warned.emit()


func is_broken() -> bool:
	return current_durability <= 0


func durability_fraction() -> float:
	if definition == null or definition.max_durability <= 0:
		return 0.0
	return float(current_durability) / float(definition.max_durability)
