## Arme ramassable (MASTER_SPEC §11.4, §14.2) — le flux « il trouve une arme »
## de §1, version graybox : un volume au sol, l'interaction la verse dans
## l'inventaire (C.4) et l'objet disparaît. Un inventaire PLEIN refuse : l'arme
## reste au sol, rien n'est perdu (§11.3 : huit armes, pas une de plus).
##
## L'exemplaire est créé AU RAMASSAGE, jamais à l'avance : une arme au sol n'a
## pas de durabilité entamée à la 0.1 — le butin d'occasion viendra avec les
## tables de loot (§11.4).
class_name WeaponPickup
extends Node3D

signal picked_up(weapon: WeaponInstance)

@export var definition: WeaponDefinition
## Identifiant persistant (§19.3, format `zone.category.name.index`). Un pickup
## ramassé est consigné dans la sauvegarde : sans cet ID, il réapparaîtrait à
## chaque « Continuer » et dupliquerait son arme à l'infini (QA-D1R-01).
@export var pickup_id: StringName = &""


func _ready() -> void:
	add_to_group("interactable")
	if definition == null:
		push_warning("[pickup] arme au sol sans définition — inerte.")


func prompt_verb() -> String:
	return "Ramasser"


## Contrat des interactables : `false` = refusé, l'objet reste.
func interact(player: PlayerController) -> bool:
	if definition == null or player == null or player.inventory() == null:
		return false
	var bus: Node = get_node_or_null("/root/EventBus")
	var weapon: WeaponInstance = WeaponInstance.create(definition)
	if not player.inventory().add_weapon(weapon):
		if bus != null:
			bus.call("notify", "Inventaire plein (8 armes) — l'arme reste au sol")
		return false  # inventaire plein : l'arme reste au sol
	if bus != null:
		bus.call("notify", "Ramassé : " + definition.display_name)
	picked_up.emit(weapon)
	queue_free()
	return true


## Application d'état (§19.4) : un pickup déjà ramassé disparaît sans signal ni
## notification — appliquer une sauvegarde n'est pas du gameplay. Rendu inerte
## immédiatement : `queue_free` ne prend effet qu'à la fin de la frame.
func mark_taken_silently() -> void:
	remove_from_group("interactable")
	definition = null
	visible = false
	queue_free()
