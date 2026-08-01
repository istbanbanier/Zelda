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


func _ready() -> void:
	add_to_group("interactable")
	if definition == null:
		push_warning("[pickup] arme au sol sans définition — inerte.")


## Contrat des interactables : `false` = refusé, l'objet reste.
func interact(player: PlayerController) -> bool:
	if definition == null or player == null or player.inventory() == null:
		return false
	var weapon: WeaponInstance = WeaponInstance.create(definition)
	if not player.inventory().add_weapon(weapon):
		return false  # inventaire plein : l'arme reste au sol
	picked_up.emit(weapon)
	queue_free()
	return true
