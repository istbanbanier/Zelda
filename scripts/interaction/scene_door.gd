## Porte de transition entre scènes jouables (D.1R.4, PT-D1-10).
##
## Une structure présentée comme destination doit être accessible ou
## honnêtement scellée — cette porte est la version accessible : l'interaction
## pose un tag d'apparition dans `GameState` puis demande la transition à
## `SceneFlow`. La scène cible consomme le tag pour placer le joueur au bon
## endroit (ressortir replace DEVANT la porte, jamais au spawn).
class_name SceneDoor
extends StaticBody3D

## Verbe de l'invite (§14.2) : « Entrer », « Sortir »…
@export var verb: String = "Entrer"
@export var target_scene: String = ""
## Tag consommé par la scène cible pour choisir le point d'apparition.
@export var spawn_tag: StringName = &""


func _ready() -> void:
	add_to_group("interactable")


func prompt_verb() -> String:
	return verb


func interact(_player: PlayerController) -> bool:
	if target_scene == "":
		return false
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow == null or not bool(flow.call("can_go_to", target_scene)):
		return false
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null and spawn_tag != &"":
		game_state.call("set_pending_spawn", spawn_tag)
	flow.call("go_to", target_scene)
	return true
