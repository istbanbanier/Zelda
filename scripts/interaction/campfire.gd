## E.2b (§13.3) — feu de cuisine interactif. L'objet ne cuisine pas :
## il OUVRE l'atelier de cuisine du shell (sélection 1-5, aperçu,
## confirmation atomique). Le shell détient l'UI ; le feu n'est que la
## porte. Groupe `interactable` : sélection par cône/distance du
## contrôleur, comme les coffres.
class_name Campfire
extends Node3D

## Identifiant stable (§19.3) — le feu du camp est aussi un repère.
@export var campfire_id: StringName = &"valley.campfire.camp.01"


## ISS-084 — UN FOYER PEUT APPARTENIR À QUELQU'UN D'AUTRE.
##
## Tant que ce drapeau est levé, le feu ne propose rien et refuse de s'ouvrir.
## Il reste NÉANMOINS un `Campfire` dans le groupe `interactable` : c'est un
## contrat de checkpoint (`test_world_v2_places_behavior.gd`), pas de décor,
## et le lieu qui le pose est GELÉ. On change un ÉTAT, jamais une inscription.
##
## FAUX PAR DÉFAUT, et c'est la moitié du travail. Trois `Campfire` existent :
## celui du camp braise, celui de la vallée V1, celui de l'antichambre du
## boss. Les deux derniers n'ont aucune garnison et ne doivent RIEN perdre.
## Personne ne lève ce drapeau sauf `CampCuisineGuard`, pour le seul foyer que
## la donnée du camp désigne.
var _revendique: bool = false


func _ready() -> void:
	add_to_group("interactable")


## Appelé par `CampCuisineGuard` quand la garnison du camp se lève ou tombe.
func set_revendique(revendique: bool) -> void:
	_revendique = revendique


func est_revendique() -> bool:
	return _revendique


## VIDE quand le foyer est revendiqué — et c'est le SEUL levier qui efface
## l'invite sans quitter le groupe. Mesuré : `_select_interactable()` du
## contrôleur ne teste ni la visibilité ni ce verbe ; c'est
## `_refresh_interact_focus()` (l.1476-1478) et le HUD
## (`gameplay_shell.gd:790-797`) qui l'honorent. Masquer le feu ne l'aurait
## donc PAS désactivé : il serait resté sélectionnable, et `E` aurait ouvert
## la cuisine dans un camp ennemi.
func prompt_verb() -> String:
	return "" if _revendique else "Cuisiner"


## Contrat des interactables : `interact(player) -> bool`. Vrai si
## l'atelier s'ouvre — le geste du joueur (lot 14) part sur ce vrai.
func interact(_player: Node) -> bool:
	# Le verbe vide ne suffit PAS : `_try_interact()` appelle `interact()` sur
	# la meilleure cible sans consulter le verbe. Sans ce refus, `E` ouvrirait
	# encore l'atelier devant un foyer muet.
	if _revendique:
		return false
	var shell: Node = get_tree().get_first_node_in_group("gameplay_shell")
	if shell == null or not shell.has_method("open_cooking"):
		return false
	return bool(shell.call("open_cooking", _player))
