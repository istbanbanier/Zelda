## Racine du monde World V2 — VALLÉE WHITEBOX (phase V2.1).
##
## V2.0 avait prouvé l'architecture avec un sol temporaire ; V2.1 le remplace
## par la vallée réelle en whitebox : 64 chunks de relief continu issus de LA
## fonction de hauteur (`WorldV2Heightmap`), hydrologie creusée, marqueurs des
## lieux, limites fermées, navigation versionnée, six fenêtres de composition.
## Tout est construit UNE fois au chargement, depuis la carte directrice
## validée — une carte invalide arrête le monde bruyamment.
##
## Ce que cette scène N'EST toujours PAS : un monde habillé. Matériaux de
## diagnostic, aucun asset artistique, aucun ennemi, aucune récompense —
## la structure spatiale est vraie, et c'est tout ce qu'elle affirme.
##
## Isolation : aucun contenu spatial V1 référencé — contrat tenu par
## `tests/world_v2/`. Depuis T1, cette scène ÉCRIT sa sauvegarde : position,
## orientation et lieu de reprise, signés `world_version`, par fusion sur le
## payload existant, au départ de chaque transition, à la fermeture de la
## fenêtre et toutes les `AUTOSAVE_PERIODE_S` secondes — voir `autosave()`
## et `docs/contrats/t1_persistance_world_v2.md`.
class_name WorldV2Root
extends Node3D

const WORLD_ID: StringName = WorldIds.V2_WORLD_ID

const REQUIRED_CONTAINERS: Array[String] = [
	"TerrainChunks", "Water", "Biomes", "Routes", "Landmarks", "POIs",
	"Places", "Encounters", "Navigation", "Vegetation", "Lighting",
	"CaptureCameras", "WorldBindings",
]

const GROUND_PROBE_UP_M: float = 2.0
const GROUND_PROBE_DOWN_M: float = 12.0
const WORLD_STATIC_LAYER_MASK: int = 1
const NAV_RESOURCE_PATTERN: String = "res://resources/world_v2/nav/world_v2_navmesh_q%d.tres"
const NAV_QUADRANTS: int = 4

## T1 — PERSISTANCE. Le slot unique du jeu, celui que le menu écrit et relit.
const SAVE_SLOT: String = "slot0"
## Le lieu narratif que World V2 inscrit dans `checkpoint`. Le donjon écrit
## déjà le sien (`antechamber.gd` pose `dungeon.antechamber`) : la reprise
## route sur ce champ, et n'en invente pas un second.
const CHECKPOINT_TAG: String = "world_v2.valley"
## Le tag que « Réessayer » pose (`gameplay_shell.gd::_on_retry`). Il signifie
## « reprends au dernier état sauvegardé », pas « point d'apparition » — et
## aucune scène ne le comprenait : World V2 le traitait en tag INCONNU et
## déposait le joueur au spawn, à 380 m du lieu de sa mort. Constat de la
## contre-revue ISS-073.
const RETRY_TAG: StringName = &"retry_checkpoint"
## Bornes d'une position RELUE. Une position de sauvegarde est une entrée NON
## FIABLE — le fichier s'édite à la main — et la doctrine du projet est celle
## de `valley_world.gd` : toute forme douteuse retombe sur le point
## d'apparition, jamais sur un crash. Les bornes horizontales viennent du
## LAYOUT (`bounds.x/z`), pas d'un nombre recopié qui vieillirait en silence.
const SAVED_POSITION_MIN_Y: float = -6.0
const SAVED_POSITION_MAX_Y: float = 200.0
## C9 — la FENÊTRE DE PERTE d'un arrêt brutal. Un jeu de 30-50 h ne peut pas
## perdre un temps illimité entre deux transitions : cette minuterie borne la
## perte au pire à ce nombre de secondes de temps moteur. Épinglée par
## `test_c9…` — la changer est un choix de contrat, pas un accident.
const AUTOSAVE_PERIODE_S: float = 60.0

## D'où le héros a été placé à ce montage : `spawn`, `retour_donjon` ou
## `sauvegarde` (T1). Un test doit pouvoir le lire sans deviner d'après une
## distance.
var _spawn_source: StringName = &"spawn"

@onready var _spawn: Node3D = $SpawnPoint
@onready var _player: Node3D = $Player
@onready var _shell: CanvasLayer = $GameplayShell
@onready var _diag_camera: Camera3D = $CaptureCameras/DiagnosticCamera

var _layout: Dictionary = {}
var _heightmap: WorldV2Heightmap = null
var _terrain_builder: WorldV2TerrainBuilder = null


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

	var build_start: int = Time.get_ticks_msec()
	_heightmap = WorldV2Heightmap.new(_layout)
	_terrain_builder = WorldV2TerrainBuilder.new(_heightmap, _layout)
	_terrain_builder.build($TerrainChunks as Node3D)
	var hydrology: WorldV2HydrologyBuilder = WorldV2HydrologyBuilder.new(_heightmap, _layout)
	hydrology.build($Water as Node3D, $Landmarks as Node3D)
	var markers: WorldV2MarkersBuilder = WorldV2MarkersBuilder.new(_heightmap, _layout)
	markers.build($POIs as Node3D, $Landmarks as Node3D, $Biomes as Node3D,
		$Routes as Node3D)
	var places: WorldV2PlacesBuilder = WorldV2PlacesBuilder.new(_heightmap, _layout)
	var places_count: int = places.build($Places as Node3D)
	# ISS-073 — la porte du donjon. Posée APRÈS les lieux et AVANT les
	# frontières : le seuil est à l'intérieur du monde jouable, et l'anneau de
	# gardes ne doit pas s'y superposer.
	var door_builder: WorldV2DungeonDoor = WorldV2DungeonDoor.new(
		_heightmap, _layout)
	var door_ok: bool = door_builder.build($Landmarks as Node3D)
	var borders: WorldV2BordersBuilder = WorldV2BordersBuilder.new(_heightmap)
	borders.build($TerrainChunks as Node3D)
	var vegetation: WorldV2VegetationBuilder = WorldV2VegetationBuilder.new(
		_heightmap, _terrain_builder, _layout)
	vegetation.build($Vegetation as Node3D)
	var atmosphere: WorldV2AtmosphereBuilder = WorldV2AtmosphereBuilder.new(_heightmap)
	atmosphere.build($Lighting as Node3D)
	var cameras: WorldV2CamerasBuilder = WorldV2CamerasBuilder.new(_heightmap)
	cameras.build($CaptureCameras as Node3D)
	var nav_regions: int = _load_navigation()

	# ISS-073 — LE FLUX, ET D'OÙ L'ON ARRIVE.
	#
	# Trois provenances possibles, et leur PRIORITÉ compte :
	#   1. un RETOUR de transition (le vestibule) — l'emporte sur tout ;
	#   2. une position sauvegardée — hors périmètre de cette corrective ;
	#   3. le point d'apparition — le cas d'une partie neuve.
	#
	# Avant ce correctif, World V2 ne consommait AUCUN `pending_spawn` : un
	# retour du vestibule replaçait le héros au spawn, à 380 m du seuil qu'il
	# venait de franchir. Pire, le tag restait posé et aurait resservi à la
	# transition suivante.
	var game_state: Node = get_node_or_null("/root/GameState")
	var arrival: StringName = &""
	if game_state != null:
		game_state.call("set_flow", 2)  # GameState.Flow.VALLEY
		arrival = game_state.call("consume_pending_spawn")

	var return_anchor: Node3D = $Landmarks.get_node_or_null(
		WorldV2DungeonDoor.RETURN_ANCHOR_NAME) as Node3D
	# T1 — la deuxième provenance existe maintenant. Elle est lue AVANT le
	# branchement pour que la priorité soit visible d'un seul regard, et elle
	# vaut `Vector3.INF` chaque fois qu'elle n'a pas le droit de s'appliquer.
	var reprise: Vector3 = _position_de_reprise()
	if arrival == WorldV2DungeonDoor.RETURN_TAG and return_anchor != null:
		# Ressortir replace DEVANT la porte, jamais au spawn (PT-D1-10). Un
		# retour de transition l'emporte sur une position sauvegardée : la
		# sauvegarde décrit où l'on ÉTAIT, la transition où l'on ARRIVE.
		_player.global_position = return_anchor.global_position
		_spawn_source = &"retour_donjon"
	elif reprise != Vector3.INF:
		_player.global_position = reprise
		_spawn_source = &"sauvegarde"
	else:
		_player.global_position = _spawn.global_position
		_spawn_source = &"spawn"
		if arrival != &"" and arrival != WorldV2DungeonDoor.RETURN_TAG \
				and arrival != RETRY_TAG:
			push_warning("[world_v2] tag d'apparition inconnu « %s » — "
				% arrival + "reprise au point d'apparition")
	if _spawn_source != &"retour_donjon":
		_restaurer_orientation()
	# §20.9 : reset d'interpolation après tout repositionnement instantané.
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	# `DiagnosticCamera` précède le joueur dans WorldV2.tscn : Godot la rend
	# automatiquement courante lorsqu'elle entre seule dans le Viewport. Les
	# caméras de preuve ne doivent jamais décider de la vue d'une partie normale.
	# On reprend donc explicitement la main une fois le monde monté ; les outils
	# de capture pourront toujours activer ensuite leur caméra nommée.
	if not activate_gameplay_camera():
		push_error("[world_v2] caméra du joueur introuvable — vue jouable impossible")

	_diag_camera.look_at_from_position(
		_diag_camera.global_position, _spawn.global_position, Vector3.UP)
	_apply_capture_environment()

	print("[world_v2] monde        : %s (vallée whitebox V2.1)" % WORLD_ID)
	print("[world_v2] carte        : %d lieux + %d sites systémiques, valide"
		% [(_layout.get("pois", []) as Array).size(),
			(_layout.get("systemic_sites", []) as Array).size()])
	print("[world_v2] terrain      : %d chunks, montage %d ms"
		% [get_tree().get_nodes_in_group(&"world_v2_terrain").size(),
			Time.get_ticks_msec() - build_start])
	print("[world_v2] navigation   : %d région(s) chargée(s)" % nav_regions)
	print("[world_v2] lieux        : %d scène(s) posée(s) par le layout" % places_count)
	print("[world_v2] spawn        : %s" % _spawn.global_position)
	print("[world_v2] porte donjon : %s" % ("posée au seuil §3.3"
		if door_ok else "ABSENTE — le donjon est inatteignable"))
	print("[world_v2] arrivée      : %s" % _spawn_source)
	# Jalon lisible par le portail d'export T1 : la position et le lacet
	# RÉELLEMENT posés — la seule façon de mesurer une reprise depuis
	# l'extérieur d'une build autonome (même famille que les jalons ISS-071).
	var visual_pose: Node3D = _player.get_node_or_null("VisualRoot") as Node3D
	print("[world_v2] héros posé   : (%.1f, %.1f, %.1f) lacet=%.2f" % [
		_player.global_position.x, _player.global_position.y,
		_player.global_position.z,
		visual_pose.rotation.y if visual_pose != null else 0.0])
	_brancher_autosave()

	await get_tree().physics_frame
	if not is_instance_valid(self) or not is_inside_tree():
		return
	var hit: Dictionary = probe_ground_below_spawn()
	if hit.is_empty():
		push_error("[world_v2] AUCUN SOL sous le spawn — le monde ne porte pas le joueur")
		return
	print("[world_v2] sol          : %s à y=%.2f" % [
		(hit["collider"] as Node).name, (hit["position"] as Vector3).y])
	print("[world_v2] fondation V2 vérifiée — vallée whitebox prête.")
	_vider_manifeste_iss071_si_demande()
	await _capturer_vues_iss071_si_demande()


## ISS-071 — vidage des manifestes de résolution, INERTE sans le drapeau.
##
## Pourquoi ici et pas dans un script d'outil : une build exportée en mode
## release n'accepte pas `--script`. Le seul endroit d'où l'on peut lire l'index
## RÉEL d'une build installée, c'est le jeu lui-même, une fois le monde monté.
## Sans ce vidage, la parité éditeur/export exigée par la directive §8 resterait
## une affirmation.
##
## Le drapeau est cherché dans les DEUX listes : `get_cmdline_args()` couvre
## l'exécution éditeur, `get_cmdline_user_args()` couvre ce qui suit `--` dans
## une build exportée.
func _argument_iss071(prefixe: String) -> String:
	var args: PackedStringArray = OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	var valeur: String = ""
	for arg: String in args:
		if arg.begins_with(prefixe):
			valeur = arg.substr(prefixe.length())
	return valeur


## Nombre de SCÈNES DE LIEU réellement posées par le layout — et rien d'autre.
##
## POURQUOI PAS `get_child_count()` (correction demandée par le propriétaire,
## passe S1) : `$Places` porte aussi le nœud utilitaire `Recompenses`, ajouté
## par `_furnish_rewards()` APRÈS la pose des lieux. Le compte brut rendait
## donc 16 quand le layout pose 15 scènes — et le journal du jeu, lui, disait
## bien 15. Deux compteurs qui prétendent mesurer la même chose et divergent
## d'un nœud utilitaire, c'est exactement l'écart qu'ISS-071 traque.
##
## L'oracle est la marque `place_id`, posée par `WorldV2PlacesBuilder.build()`
## sur chaque scène de lieu au moment de la pose. ATTENTION : parmi les
## ENFANTS DIRECTS de `$Places`, seuls les lieux la portent — mais elle
## existe AILLEURS dans le monde (les marqueurs de
## `world_v2_markers_builder.gd` la portent aussi, sous `$POIs` et
## `$Landmarks`). La restriction aux enfants directs n'est donc pas une
## commodité : c'est ce qui rend l'oracle juste. Ne jamais le remplacer par
## une recherche globale du meta.
func _compter_lieux_poses() -> int:
	var lieux: int = 0
	for enfant: Node in ($Places as Node3D).get_children():
		if enfant.has_meta(&"place_id"):
			lieux += 1
	return lieux


func _vider_manifeste_iss071_si_demande() -> void:
	var cible: String = _argument_iss071("--iss071-dump=")
	if cible.is_empty():
		return
	var manifeste: Dictionary = {
		"environnement": ("export" if OS.has_feature("template")
			else "editeur"),
		"godot": String(Engine.get_version_info().get("string", "?")),
		"monde": WORLD_ID,
		"resolveurs": {
			"WorldV2PlaceKit": WorldV2PlaceKit.manifeste_iss071(),
			"AssetRegistry": AssetRegistry.manifeste_iss071(),
		},
		"vegetation": WorldV2VegetationBuilder.manifeste_iss071(),
		"lieux_poses": _compter_lieux_poses(),
	}
	if not _argument_iss071("--iss071-chargeabilite").is_empty():
		for nom: Variant in (manifeste["resolveurs"] as Dictionary).keys():
			var res: Dictionary = (manifeste["resolveurs"] as Dictionary)[nom]
			res["chargeabilite"] = _eprouver_chargeabilite(
				res.get("index", {}) as Dictionary)
	var repertoire: String = cible.get_base_dir()
	if not repertoire.is_empty():
		DirAccess.make_dir_recursive_absolute(repertoire)
	var fichier: FileAccess = FileAccess.open(cible, FileAccess.WRITE)
	if fichier == null:
		push_error("[iss071] écriture impossible : %s (erreur %d)"
			% [cible, FileAccess.get_open_error()])
		return
	fichier.store_string(JSON.stringify(manifeste, "\t", false))
	fichier.close()
	print("[iss071] manifeste écrit : %s" % cible)


## Navigation versionnée : quatre quadrants cuits hors-ligne
## (`tools/godot/bake_world_v2_navmesh.gd`). Zéro région n'est pas une
## erreur au montage (le bake peut ne pas encore exister) — les tests, eux,
## l'exigent.
##
## Itérations SYNCHRONES obligatoires : la construction asynchrone (défaut du
## moteur) poste une tâche de WorkerThreadPool qui ne se termine JAMAIS dans
## l'environnement headless `--script` — mesuré : `map_get_iteration_id`
## bloqué à 1, toutes les requêtes rendent (0,0,0). La carte V1 souffre du
## même mal (ses ennemis retombent en pilotage direct sans le dire). Pour une
## carte statique cuite, la construction synchrone au chargement est de toute
## façon le comportement voulu — et elle rend la navigation PROUVABLE.
func _load_navigation() -> int:
	NavigationServer3D.map_set_use_async_iterations(
		get_world_3d().navigation_map, false)
	# Marge de connexion d'arêtes 2 m : les contours de deux quadrants cuits
	# INDÉPENDAMMENT divergent à leur couture jusqu'à ~1,3 m par côté
	# (edge_max_error de Recast) — à 0,25/0,5/1,0 les quatre jambes
	# d'ancres restaient coupées à la couture, à 2,0 elles se raccordent
	# (balayage mesuré). Aucune fausse connexion possible : les bandes
	# élaguées (berges 56°, rive du lac) font toutes plus de 2 m de large.
	NavigationServer3D.map_set_edge_connection_margin(
		get_world_3d().navigation_map, 2.0)
	var loaded: int = 0
	for quadrant: int in range(NAV_QUADRANTS):
		var path: String = NAV_RESOURCE_PATTERN % quadrant
		if not ResourceLoader.exists(path):
			continue
		var mesh: NavigationMesh = load(path) as NavigationMesh
		if mesh == null:
			continue
		var region: NavigationRegion3D = NavigationRegion3D.new()
		region.name = "NavQuadrant%d" % quadrant
		NavigationServer3D.region_set_use_async_iterations(region.get_rid(), false)
		region.navigation_mesh = mesh
		($Navigation as Node3D).add_child(region)
		loaded += 1
	return loaded


func containers_missing() -> Array[String]:
	var missing: Array[String] = []
	for wanted: String in REQUIRED_CONTAINERS:
		if get_node_or_null(wanted) == null:
			missing.append(wanted)
	return missing


## Provenance du placement : `spawn`, `retour_donjon` ou `sauvegarde`
## (ISS-073, puis T1).
func spawn_source() -> StringName:
	return _spawn_source


func dungeon_door() -> SceneDoor:
	return $Landmarks.get_node_or_null(
		WorldV2DungeonDoor.DOOR_NAME) as SceneDoor


func spawn_position() -> Vector3:
	return _spawn.global_position


# ---------------------------------------------------------------------------
# T1 — PERSISTANCE : écrire son état de reprise, et le relire
# ---------------------------------------------------------------------------
#
# Ce que World V2 possède, et lui seul : la position du héros, son orientation,
# et le lieu narratif où rouvrir la partie. Tout est écrit par FUSION sur le
# payload existant — jamais en écrasement : un champ posé par une AUTRE scène
# (l'arène pose `boss_defeated`) disparaîtrait à la première sauvegarde, et le
# joueur perdrait sa victoire en explorant. C'est un défaut déjà payé côté V1.
#
# Et rien n'est relu sans signature. `world_version` dit de quel monde vient
# une position ; son ABSENCE signifie le monde V1, dont les coordonnées n'ont
# aucun sens ici — une position V1 peut être parfaitement dans les bornes V2 et
# pourtant au fond d'un lac V2 (contrat de migration §4).


## Écrit l'état de reprise de World V2. Publique : c'est le point d'entrée que
## les contrats T1 appellent, et le seul endroit d'où V2 touche la sauvegarde.
func autosave() -> void:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null or _player == null or not is_instance_valid(_player):
		return
	# ON NE SAUVEGARDE PAS LA POSITION D'UN MORT. « Réessayer » part par une
	# transition, donc par ce point d'entrée : sans cette garde, mourir
	# inscrirait le lieu de sa mort comme point de reprise, et le joueur
	# ressusciterait là où il vient d'être tué. Le défaut est né avec le
	# crochet lui-même — il n'existait pas avant T1.
	if _player.has_method("health"):
		var sante: Node = _player.call("health") as Node
		if sante != null and bool(sante.call("is_dead")):
			return
	var payload: Dictionary = {}
	if bool(save_system.call("has_save", SAVE_SLOT)):
		payload = save_system.call("load_slot", SAVE_SLOT) as Dictionary
		# C10 — le point le plus dangereux de tout T1. `load_slot` rend `{}`
		# sur un fichier corrompu ET sur un schéma PLUS RÉCENT, refusé
		# « fichier intact » précisément pour le protéger. Fusionner dans `{}`
		# puis écrire détruirait la sauvegarde d'un futur build à la première
		# transition d'un build ancien (§19.4 : ne jamais écraser
		# silencieusement). Un slot présent mais illisible n'est pas le nôtre
		# à réécrire ; « Nouvelle partie » l'écrase, lui, avec confirmation.
		if payload.is_empty():
			push_warning("[world_v2] slot présent mais illisible — autosave "
				+ "refusé pour ne pas l'écraser (§19.4)")
			return
	# Le DERNIER SOL FOULÉ, jamais la position courante : sauvegarder au milieu
	# d'une chute ou d'un coin de décor produit une reprise dans le décor, dont
	# on ne sort plus.
	var pose: Vector3 = _player.global_position
	if _player.has_method("last_grounded_position"):
		pose = _player.call("last_grounded_position") as Vector3
	payload.merge({
		"world_version": String(WORLD_ID),
		"checkpoint": CHECKPOINT_TAG,
		"player_position": {"x": pose.x, "y": pose.y, "z": pose.z},
		"player_yaw": _lacet_du_heros(),
	}, true)
	save_system.call("save_slot", SAVE_SLOT, payload)


## Le lacet vit sur `VisualRoot` : le corps du héros ne tourne JAMAIS
## (`PlayerController._ready`). Lire la rotation du corps rendrait 0 quoi qu'il
## arrive — une grandeur voisine de celle qui compte, et le mode de panne
## maison. Absent, 0 est un lacet honnête, pas une erreur.
func _lacet_du_heros() -> float:
	var visual: Node3D = _player.get_node_or_null("VisualRoot") as Node3D
	return visual.rotation.y if visual != null else 0.0


func _restaurer_orientation() -> void:
	var data: Dictionary = _sauvegarde_de_ce_monde()
	if data.is_empty():
		return
	var brut: Variant = data.get("player_yaw")
	if not (brut is float) or not is_finite(brut as float):
		return
	var visual: Node3D = _player.get_node_or_null("VisualRoot") as Node3D
	if visual != null:
		visual.rotation.y = wrapf(brut as float, -PI, PI)


## Position de reprise, ou `Vector3.INF` s'il n'y en a pas de valable. Un seul
## chemin de rejet : toute forme douteuse — pas un dictionnaire, composante
## absente ou non numérique, hors bornes, sous le filet — rend `INF`.
func _position_de_reprise() -> Vector3:
	var data: Dictionary = _sauvegarde_de_ce_monde()
	if data.is_empty() or not data.has("player_position"):
		return Vector3.INF
	var brut: Variant = data["player_position"]
	if not (brut is Dictionary):
		return Vector3.INF
	var dict: Dictionary = brut as Dictionary
	var composantes: Array[float] = []
	for cle: String in ["x", "y", "z"]:
		var valeur: Variant = dict.get(cle)
		if not (valeur is float):
			return Vector3.INF
		composantes.append(valeur as float)
	var pose := Vector3(composantes[0], composantes[1], composantes[2])
	if not _position_sauvegardee_sure(pose):
		push_warning("[world_v2] position sauvegardée hors domaine (%s) — "
			% pose + "reprise au point d'apparition")
		return Vector3.INF
	return pose


func _position_sauvegardee_sure(pose: Vector3) -> bool:
	if not (is_finite(pose.x) and is_finite(pose.y) and is_finite(pose.z)):
		return false
	var limite: float = _limite_horizontale()
	if absf(pose.x) > limite or absf(pose.z) > limite:
		return false
	return pose.y > SAVED_POSITION_MIN_Y and pose.y <= SAVED_POSITION_MAX_Y


## Bornes horizontales lues dans le LAYOUT. Recopier 256 ici marcherait
## aujourd'hui et mentirait le jour où la carte change de taille.
func _limite_horizontale() -> float:
	var bounds: Dictionary = _layout.get("bounds", {}) as Dictionary
	var x: Variant = bounds.get("x")
	if x is Array and (x as Array).size() == 2:
		return absf(float((x as Array)[1]))
	return 256.0


## La sauvegarde SI ELLE PARLE DE CE MONDE. Sans signature, rien n'est rendu :
## c'est ici, en un seul endroit, que le contrat de migration §4 est tenu.
func _sauvegarde_de_ce_monde() -> Dictionary:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null or not bool(save_system.call("has_save", SAVE_SLOT)):
		return {}
	var data: Dictionary = save_system.call("load_slot", SAVE_SLOT) as Dictionary
	if String(data.get("world_version", "")) != String(WORLD_ID):
		return {}
	return data


## Les TROIS déclencheurs d'autosave, branchés en un seul endroit :
##   - le DÉPART d'une transition (`SceneFlow.transition_started`, émis avant
##     tout `await` : le héros est encore en place) ;
##   - la FERMETURE de la fenêtre (NOTIFICATION_WM_CLOSE_REQUEST, reçue via
##     `_notification` — l'écriture est synchrone, elle précède le quit) ;
##   - une MINUTERIE de `AUTOSAVE_PERIODE_S` : la borne de perte d'un arrêt
##     brutal (C9). Elle meurt avec la scène — aucun débranchement à gérer —
##     et s'arrête sous pause d'arbre, où le héros ne bouge de toute façon pas.
## Tous convergent vers `autosave()`, qui porte seul les gardes (mort, slot
## illisible, dernier sol foulé).
func _brancher_autosave() -> void:
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow != null and not flow.is_connected(
			"transition_started", _sur_depart_de_transition):
		flow.connect("transition_started", _sur_depart_de_transition)
	if get_node_or_null("AutosaveTimer") == null:
		var minuterie: Timer = Timer.new()
		minuterie.name = "AutosaveTimer"
		minuterie.wait_time = AUTOSAVE_PERIODE_S
		minuterie.one_shot = false
		minuterie.autostart = true
		minuterie.timeout.connect(_sur_tic_d_autosave)
		add_child(minuterie)


func _sur_tic_d_autosave() -> void:
	autosave()


func _notification(what: int) -> void:
	# C9 — fermer la fenêtre pendant l'exploration ne perd plus la partie.
	# Le moteur propage cette notification depuis la racine avant de quitter
	# (`auto_accept_quit`) ; l'écriture atomique de SaveSystem est synchrone
	# et se termine avant la fin du processus.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		autosave()


func _sur_depart_de_transition(_cible: String) -> void:
	autosave()


## Un autoload survit à la scène : un signal branché sur lui doit être défait,
## sinon le prochain monde reçoit l'autosave de l'ancien sur un joueur libéré.
func _exit_tree() -> void:
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow != null and flow.is_connected(
			"transition_started", _sur_depart_de_transition):
		flow.disconnect("transition_started", _sur_depart_de_transition)


## Point d'accès commun aux scènes jouables. Le menu et la coquille chargent
## désormais World V2 comme monde principal ; les filets de parcours doivent
## pouvoir interroger le vrai joueur sans connaître l'arbre interne de la scène.
func player() -> PlayerController:
	return _player as PlayerController


func layout() -> Dictionary:
	return _layout


func heightmap() -> WorldV2Heightmap:
	return _heightmap


func terrain_builder() -> WorldV2TerrainBuilder:
	return _terrain_builder


func probe_ground_below_spawn() -> Dictionary:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from: Vector3 = _spawn.global_position + Vector3.UP * GROUND_PROBE_UP_M
	var to: Vector3 = _spawn.global_position + Vector3.DOWN * GROUND_PROBE_DOWN_M
	var query: PhysicsRayQueryParameters3D = \
		PhysicsRayQueryParameters3D.create(from, to, WORLD_STATIC_LAYER_MASK)
	return space.intersect_ray(query)


## -- caméras de capture -------------------------------------------------------
## L'outil de capture appelle une méthode SANS argument (`--call=`) : une
## méthode par fenêtre, mêmes noms que les tests.

func activate_gameplay_camera() -> bool:
	var typed_player: PlayerController = player()
	if typed_player == null:
		return false
	var rig: CameraRig = typed_player.camera_rig()
	if rig == null:
		return false
	var camera: Camera3D = rig.get_camera()
	if camera == null:
		return false
	camera.current = true
	return true

func activate_diagnostic_camera() -> void:
	_diag_camera.current = true


func activate_capture_camera(camera_name: String) -> bool:
	var camera: Camera3D = ($CaptureCameras as Node3D).get_node_or_null(
		camera_name) as Camera3D
	if camera == null:
		push_warning("[world_v2] caméra de capture inconnue : %s" % camera_name)
		return false
	camera.current = true
	return true


func activate_cam01() -> void:
	activate_capture_camera("cam01_spawn_vista")


func activate_cam02() -> void:
	activate_capture_camera("cam02_camp_pylone")


func activate_cam03() -> void:
	activate_capture_camera("cam03_pylone_marche")


func activate_cam04() -> void:
	activate_capture_camera("cam04_falaise_cuvette")


func activate_cam05() -> void:
	activate_capture_camera("cam05_belvedere_crete")


func activate_cam06() -> void:
	activate_capture_camera("cam06_plateau_vallee")


## Rend l'éclair visible pour une capture déterministe (l'événement cadencé
## par timer ne tombe jamais au bon moment d'une capture headless).
func storm_flash_on() -> void:
	var bolt: MeshInstance3D = get_node_or_null("Lighting/StormBolt") as MeshInstance3D
	if bolt != null:
		bolt.visible = true


## -- instrumentation de capture (cachée par défaut, directive §11) ------------
## Les outils de capture ne passent qu'UN --call sans argument : les modes de
## preuve se déclenchent par variable d'environnement — jamais actifs en jeu
## ni dans les tests (l'environnement n'y est pas posé).
##   WORLD_V2_DIAGNOSTIC=1   : teintes de diagnostic V2.1 sur le terrain
##   WORLD_V2_STORM_FLASH=1  : éclair visible dès le montage
##   WORLD_V2_FRAME_REGION=r03_val_de_neris | seam : caméra de diagnostic
##     posée sur l'ancre de la région (ou sur un coin de 4 chunks).
func _apply_capture_environment() -> void:
	if OS.get_environment("WORLD_V2_DIAGNOSTIC") == "1":
		WorldV2GroundMaterial.create().set_shader_parameter(
			&"diagnostic_amount", 1.0)
	if OS.get_environment("WORLD_V2_STORM_FLASH") == "1":
		storm_flash_on()
	var frame: String = OS.get_environment("WORLD_V2_FRAME_REGION")
	if frame.is_empty():
		return
	if frame == "seam":
		# Vue rasante d'un coin de QUATRE chunks : toute couture de matière
		# ou de relief y serait nue.
		var h: float = _heightmap.height_at(0.0, 0.0)
		_diag_camera.look_at_from_position(Vector3(-8.0, h + 3.0, 20.0),
			Vector3(0.0, h, -6.0), Vector3.UP)
		return
	for node: Node in get_tree().get_nodes_in_group(&"world_v2_regions"):
		if String(node.name) != frame:
			continue
		var anchor: Vector3 = (node as Node3D).position
		var bounds: Array = node.get_meta(&"bounds", []) as Array
		# L'Anneau frontalier (r11) n'a ni ancre ni bornes x/z : c'est un
		# ANNEAU. On le cadre depuis la zone jouable vers une section de
		# crêtes — la onzième région contractuelle a droit à sa capture
		# dédiée (directive V2.2R §2).
		if not bounds.is_empty() \
				and (bounds[0] as Dictionary).has("ring_radius_m"):
			var ring: Array = (bounds[0] as Dictionary)["ring_radius_m"] as Array
			var mid_r: float = (float(ring[0]) + float(ring[1])) * 0.5
			var ring_eye: Vector3 = Vector3(150.0,
				_heightmap.height_at(150.0, 0.0) + 9.0, 0.0)
			_diag_camera.look_at_from_position(ring_eye,
				Vector3(mid_r, 42.0, 0.0), Vector3.UP)
			return
		var look: Vector3 = anchor + Vector3(0, -6, -30)
		if not bounds.is_empty():
			var b: Dictionary = bounds[0] as Dictionary
			var bx: Array = b.get("x", []) as Array
			var bz: Array = b.get("z", []) as Array
			if bx.size() == 2 and bz.size() == 2:
				var cx: float = (float(bx[0]) + float(bx[1])) * 0.5
				var cz: float = (float(bz[0]) + float(bz[1])) * 0.5
				look = Vector3(cx, _heightmap.height_at(cx, cz), cz)
		var eye: Vector3 = anchor + Vector3(0.0, 14.0, 0.0)
		eye += (eye - look).normalized() * 18.0
		_diag_camera.look_at_from_position(eye, look, Vector3.UP)
		return


func request_exit_to_menu() -> bool:
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow == null:
		push_warning("[world_v2] SceneFlow absent — sortie impossible")
		return false
	return bool(flow.call("go_to", "res://scenes/ui/MainMenu.tscn"))


## ISS-071 §10 — six vues des lieux gelés depuis la BUILD EXPORTÉE.
##
## POURQUOI CE CHEMIN. Une build release n'accepte pas `--script` : les outils
## de capture du dépôt ne peuvent pas l'atteindre. Or la question posée par la
## directive est précisément « l'habillage des six lieux est-il RÉELLEMENT
## présent dans ce que le joueur télécharge ». Compter des lignes d'erreur
## absentes n'y répond pas ; une image du monde empaqueté, si.
##
## Les transforms ne sont PAS écrits ici : ils sont lus depuis le fichier de
## plans des preuves déjà acceptées, à l'identique — même `from`, même `look`,
## même `fov`, même convention `look_at(..., Vector3.UP)` et même
## `make_current()` que `tools/godot/capture_poi_batch.gd`. Recadrer serait
## rouvrir un verdict artistique clos.
##
## Inerte sans les deux drapeaux :
##   --iss071-vues=<fichier json ABSOLU>  --iss071-vues-out=<répertoire ABSOLU>
func _capturer_vues_iss071_si_demande() -> void:
	var plans_chemin: String = _argument_iss071("--iss071-vues=")
	var sortie: String = _argument_iss071("--iss071-vues-out=")
	if plans_chemin.is_empty() or sortie.is_empty():
		return
	var brut: String = FileAccess.get_file_as_string(plans_chemin)
	if brut.is_empty():
		push_error("[iss071] plans de vues illisibles : %s" % plans_chemin)
		return
	var plans: Variant = JSON.parse_string(brut)
	if not (plans is Array):
		push_error("[iss071] plans de vues : tableau JSON attendu")
		return
	DirAccess.make_dir_recursive_absolute(sortie)

	# Contre-revue S1 : le jalon « fondation V2 vérifiée » tombe pendant que
	# SceneFlow tient encore son voile (le fondu final de `go_to()` court en
	# CONCURRENCE avec cette coroutine). Photographier trop tôt assombrirait
	# les vues — et la plus sombre des références éditeur (watchtower_ruin,
	# moyenne 0,293) passerait sous un plancher de luminance sans qu'on sache
	# pourquoi. `is_busy()` ne retombe qu'APRÈS `_fade_to(0.0)` : on attend
	# cet observable, borné à ~10 s, au lieu de supposer un nombre de frames.
	var flux_scene: Node = get_node_or_null(^"/root/SceneFlow")
	var garde_voile: int = 600
	while garde_voile > 0 and flux_scene != null \
			and bool(flux_scene.call(&"is_busy")):
		await get_tree().process_frame
		garde_voile -= 1
	if garde_voile == 0:
		push_error("[iss071] voile de transition jamais levé en 600 frames")

	var camera: Camera3D = Camera3D.new()
	camera.name = "Iss071VueCamera"
	camera.near = 0.2
	camera.far = 1600.0
	add_child(camera)
	var ecrites: int = 0
	for plan_brut: Variant in (plans as Array):
		var plan: Dictionary = plan_brut as Dictionary
		var nom: String = String(plan.get("name", "vue"))
		var de: Array = plan.get("from", [0, 10, 0]) as Array
		var vers: Array = plan.get("look", [0, 0, 0]) as Array
		camera.fov = float(plan.get("fov", 60.0))
		camera.position = Vector3(float(de[0]), float(de[1]), float(de[2]))
		camera.look_at(Vector3(float(vers[0]), float(vers[1]),
			float(vers[2])), Vector3.UP)
		camera.make_current()
		for i: int in range(12):
			await get_tree().process_frame
		var image: Image = get_viewport().get_texture().get_image()
		if image == null:
			push_error("[iss071] rendu nul sur %s" % nom)
			continue
		var chemin: String = "%s/%s.png" % [sortie, nom]
		if image.save_png(chemin) != OK:
			push_error("[iss071] écriture impossible : %s" % chemin)
			continue
		ecrites += 1
		print("[iss071] vue %s" % chemin)
	camera.queue_free()
	print("[iss071] %d/%d vue(s) écrite(s)" % [ecrites, (plans as Array).size()])


## ISS-071 I4/I5 — ÉPROUVER TOUT CHEMIN INDEXÉ, pas seulement ceux que le monde
## a demandés.
##
## POURQUOI CE COMPLÉMENT. Le portail ne pouvait juger la chargeabilité que des
## chemins réellement sollicités au montage : 99 sur 215 côté kit, 21 sur 160
## côté registre. Les autres restaient `NON VÉRIFIÉ` — un index peut contenir un
## chemin qui ne se charge pas, et personne ne s'en apercevrait tant qu'aucun
## lieu ne le demande.
##
## `ResourceLoader.exists()` NE SUFFIT PAS et c'est mesuré :
## `ResourceFormatImporter::exists()` rend vrai dès qu'un `<chemin>.import`
## existe, SANS regarder le type demandé — `exists("…/Bark_DeadTree.png",
## "PackedScene")` rend donc vrai alors que le `load()` qui suit rend `null`.
## Seul un vrai `load()` tranche, et c'est pour cela qu'on le fait ici.
##
## Coûteux (quelques centaines de chargements) : réservé au drapeau
## `--iss071-chargeabilite`, jamais au chemin de jeu.
func _eprouver_chargeabilite(index: Dictionary) -> Dictionary:
	var existe: int = 0
	var charge: int = 0
	var defaillants: Array[String] = []
	for cle: Variant in index.keys():
		var chemin: String = String(index[cle])
		if ResourceLoader.exists(chemin, "PackedScene"):
			existe += 1
		var scene: PackedScene = ResourceLoader.load(
			chemin, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		if scene != null:
			charge += 1
		else:
			defaillants.append("%s -> %s" % [String(cle), chemin])
	return {
		"chemins": index.size(),
		"exists_vrai": existe,
		"load_reussi": charge,
		"defaillants": defaillants,
	}
