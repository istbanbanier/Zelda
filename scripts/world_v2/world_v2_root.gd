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
## Isolation : aucun contenu spatial V1 référencé, aucune écriture de
## sauvegarde — contrats tenus par `tests/world_v2/`.
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

	# Le joueur apparaît TOUJOURS au point d'apparition — aucune position de
	# sauvegarde n'est lue ici (contrat de migration).
	_player.global_position = _spawn.global_position
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
func _vider_manifeste_iss071_si_demande() -> void:
	var cible: String = ""
	var args: PackedStringArray = OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg: String in args:
		if arg.begins_with("--iss071-dump="):
			cible = arg.substr("--iss071-dump=".length())
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
		"lieux_poses": ($Places as Node3D).get_child_count(),
	}
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


func spawn_position() -> Vector3:
	return _spawn.global_position


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
