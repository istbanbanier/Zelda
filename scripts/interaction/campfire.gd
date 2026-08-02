## E.2b (§13.3) — feu de cuisine interactif. L'objet ne cuisine pas :
## il OUVRE l'atelier de cuisine du shell (sélection 1-5, aperçu,
## confirmation atomique). Le shell détient l'UI ; le feu n'est que la
## porte. Groupe `interactable` : sélection par cône/distance du
## contrôleur, comme les coffres.
class_name Campfire
extends Node3D

## Identifiant stable (§19.3) — le feu du camp est aussi un repère.
@export var campfire_id: StringName = &"valley.campfire.camp.01"


func _ready() -> void:
	add_to_group("interactable")


func prompt_verb() -> String:
	return "Cuisiner"


## Contrat des interactables : `interact(player) -> bool`. Vrai si
## l'atelier s'ouvre — le geste du joueur (lot 14) part sur ce vrai.
func interact(_player: Node) -> bool:
	var shell: Node = get_tree().get_first_node_in_group("gameplay_shell")
	if shell == null or not shell.has_method("open_cooking"):
		return false
	return bool(shell.call("open_cooking", _player))
