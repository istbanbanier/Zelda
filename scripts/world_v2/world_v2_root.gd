## Racine du monde World V2 — SQUELETTE de la phase V2.0.
##
## Ce que cette scène EST : la preuve d'architecture. Les conteneurs de la
## reconstruction existent, le vrai joueur (`scenes/player/Player.tscn`) et la
## vraie coquille de jeu (`scenes/ui/GameplayShell.tscn`) s'y raccordent par
## leurs interfaces existantes, le sol temporaire porte une collision réelle,
## et la carte directrice (`WorldV2Layout`) est chargée et validée.
##
## Ce que cette scène N'EST PAS : un monde. Aucun habillage, aucun POI posé,
## aucun éclairage final — le sol est marqué « TEMPORAIRE V2.0 » en toutes
## lettres. La vallée whitebox arrive en V2.1, sur le masterplan approuvé.
##
## Isolation : ce script ne référence RIEN du monde V1 (ni sa scène, ni ses
## bâtisseurs) et n'écrit JAMAIS dans la sauvegarde — deux contrats tenus par
## `tests/world_v2/`. Les seules dépendances sont les interfaces protégées :
## Player, GameplayShell, autoloads.
class_name WorldV2Root
extends Node3D

## Identité de monde — publiée pour la future migration de sauvegarde
## (`docs/WORLD_V2_SAVE_MIGRATION.md`). Jamais réutilisée pour autre chose.
const WORLD_ID: StringName = WorldIds.V2_WORLD_ID

## Les conteneurs de l'architecture V2 (prompt V2.0 §6). Leur ABSENCE est une
## erreur de fondation : la construction V2.1+ posera terrain, eau, biomes,
## routes, repères, POI, rencontres, navigation, lumière et caméras de capture
## dans ces nœuds-là, jamais ailleurs.
const REQUIRED_CONTAINERS: Array[String] = [
	"TerrainChunks", "Water", "Biomes", "Routes", "Landmarks", "POIs",
	"Encounters", "Navigation", "Lighting", "CaptureCameras", "WorldBindings",
]

## Sonde de sol : départ au-dessus du spawn, portée vers le bas, couche 1
## (« World Static ») uniquement — la même règle que le joueur.
const GROUND_PROBE_UP_M: float = 2.0
const GROUND_PROBE_DOWN_M: float = 12.0
const WORLD_STATIC_LAYER_MASK: int = 1

@onready var _spawn: Node3D = $SpawnPoint
@onready var _player: Node3D = $Player
@onready var _shell: CanvasLayer = $GameplayShell
@onready var _diag_camera: Camera3D = $CaptureCameras/DiagnosticCamera

var _layout: Dictionary = {}


func _ready() -> void:
	var missing: Array[String] = containers_missing()
	if not missing.is_empty():
		push_error("[world_v2] conteneur(s) absent(s) : %s — l'architecture V2 est incomplète"
			% ", ".join(missing))
		return

	_layout = WorldV2Layout.load_layout()
	var problems: Array[String] = WorldV2Layout.validate(_layout)
	if not problems.is_empty():
		push_error("[world_v2] carte directrice invalide (%d problème(s)) — premier : %s"
			% [problems.size(), problems[0]])
		return

	# Le joueur apparaît TOUJOURS au point d'apparition du squelette — aucune
	# position de sauvegarde n'est lue ici (contrat de migration : une position
	# V1 ne se réapplique jamais aveuglément dans V2).
	_player.global_position = _spawn.global_position

	# La caméra de diagnostic cadre le spawn ; elle n'est PAS active par défaut
	# — le jeu reste sur la caméra du joueur, l'outil de capture l'active par
	# `--call=activate_diagnostic_camera`.
	_diag_camera.look_at_from_position(
		_diag_camera.global_position, _spawn.global_position, Vector3.UP)

	print("[world_v2] monde        : %s (squelette V2.0)" % WORLD_ID)
	print("[world_v2] carte        : %d lieux + %d sites systémiques, valide"
		% [(_layout.get("pois", []) as Array).size(),
			(_layout.get("systemic_sites", []) as Array).size()])
	print("[world_v2] spawn        : %s" % _spawn.global_position)

	# La sonde de sol exige un état physique à jour : première frame physique.
	await get_tree().physics_frame
	if not is_instance_valid(self) or not is_inside_tree():
		return
	var hit: Dictionary = probe_ground_below_spawn()
	if hit.is_empty():
		push_error("[world_v2] AUCUN SOL sous le spawn — le squelette ne porte pas le joueur")
		return
	print("[world_v2] sol          : %s à y=%.2f" % [
		(hit["collider"] as Node).name, (hit["position"] as Vector3).y])
	print("[world_v2] fondation V2 vérifiée — squelette prêt.")


## Conteneurs manquants — vide si l'architecture est complète. Public : les
## tests le lisent au lieu de dupliquer la liste.
func containers_missing() -> Array[String]:
	var missing: Array[String] = []
	for wanted: String in REQUIRED_CONTAINERS:
		if get_node_or_null(wanted) == null:
			missing.append(wanted)
	return missing


func spawn_position() -> Vector3:
	return _spawn.global_position


func layout() -> Dictionary:
	return _layout


## Sonde le sol sous le spawn, sur la couche « World Static » seulement — si
## elle ne touche rien, le joueur traverserait. Appeler après une frame
## physique.
func probe_ground_below_spawn() -> Dictionary:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from: Vector3 = _spawn.global_position + Vector3.UP * GROUND_PROBE_UP_M
	var to: Vector3 = _spawn.global_position + Vector3.DOWN * GROUND_PROBE_DOWN_M
	var query: PhysicsRayQueryParameters3D = \
		PhysicsRayQueryParameters3D.create(from, to, WORLD_STATIC_LAYER_MASK)
	return space.intersect_ray(query)


## Active la caméra de diagnostic — chemin de l'outil de capture
## (`--call=activate_diagnostic_camera`), jamais celui du jeu.
func activate_diagnostic_camera() -> void:
	_diag_camera.current = true


## Retour au flux normal : la seule sortie du squelette est le menu principal,
## par la même porte que tout le monde (SceneFlow). Aucune écriture de
## sauvegarde au passage — le squelette n'a rien à sauver.
func request_exit_to_menu() -> bool:
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow == null:
		push_warning("[world_v2] SceneFlow absent — sortie impossible")
		return false
	return bool(flow.call("go_to", "res://scenes/ui/MainMenu.tscn"))
