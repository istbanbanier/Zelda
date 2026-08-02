## Effets d'état du joueur (MASTER_SPEC §5.8, §13.4, §13.5).
##
## §13.4 : UN SEUL buff majeur actif — un nouveau REMPLACE l'ancien. La
## minuterie court en `_process` PAUSABLE : la pause réelle (arbre suspendu)
## suspend le buff, comme l'exige §13.4. Les multiplicateurs de §13.5 sont
## exposés en lecture ; les consommateurs (hitbox, hurtbox, endurance) les
## tirent au changement — jamais de polling.
class_name StatusEffectComponent
extends Node

signal buff_applied(effect: StringName, potency: float, duration: float)
signal buff_expired(effect: StringName)

## §13.5 — valeurs de départ de la table des buffs.
const ATTACK_MULTIPLIER: float = 1.25
const DAMAGE_TAKEN_MULTIPLIER: float = 0.75
const STAMINA_REGEN_MULTIPLIER: float = 1.6
const ELEC_DAMAGE_MULTIPLIER: float = 0.4

var _effect: StringName = &""
var _potency: float = 0.0
var _remaining: float = 0.0


func _ready() -> void:
	set_process(false)   # §5.4 : pas de _process sur un composant dormant


func apply_buff(effect: StringName, potency: float, duration: float) -> void:
	if effect == &"" or duration <= 0.0:
		return
	if _effect != &"":
		buff_expired.emit(_effect)   # remplacement (§13.4)
	_effect = effect
	_potency = potency
	_remaining = duration
	set_process(true)
	buff_applied.emit(effect, potency, duration)


func _process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		var expired: StringName = _effect
		_effect = &""
		_potency = 0.0
		_remaining = 0.0
		set_process(false)
		buff_expired.emit(expired)


func active_effect() -> StringName:
	return _effect


func remaining() -> float:
	return maxf(0.0, _remaining)


func attack_multiplier() -> float:
	return ATTACK_MULTIPLIER if _effect == &"attack" else 1.0


func damage_taken_multiplier() -> float:
	return DAMAGE_TAKEN_MULTIPLIER if _effect == &"defense" else 1.0


func stamina_regen_multiplier() -> float:
	return STAMINA_REGEN_MULTIPLIER if _effect == &"stamina" else 1.0


func elec_damage_multiplier() -> float:
	return ELEC_DAMAGE_MULTIPLIER if _effect == &"elec_resist" else 1.0


## Sauvegarde (§19.1 : « buff restant ») — primitives seulement.
func snapshot() -> Dictionary:
	if _effect == &"":
		return {}
	return {"effect": String(_effect), "potency": _potency,
		"remaining": _remaining}


## Restauration (§19.4) : ré-applique par le chemin normal — les
## consommateurs reçoivent leur signal et retendent leurs multiplicateurs.
func restore(data: Dictionary) -> void:
	if data.is_empty():
		return
	apply_buff(StringName(String(data.get("effect", ""))),
		float(data.get("potency", 0.0)), float(data.get("remaining", 0.0)))
