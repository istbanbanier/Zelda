## Vallée de Néris — monde graybox (MASTER_SPEC §22 Phase D, D.1 par D-024).
##
## D.1 : relief macro complet (voir `ValleyTerrain`), proxys du pylône et de la
## citadelle, soleil de fin d'après-midi (§7.7 : ouest/gauche, plongée 18–28°),
## ciel et brume aux couleurs ancres (§3.4), et la caméra de la vue d'ouverture
## `VistaCamera_Hero01` (§3.2) — constantes FIXES : une capture de référence doit
## être reproductible au millimètre (§21.8).
##
## `VALLEY_VISTA=1` dans l'environnement rend la VistaCamera active au chargement
## — c'est le chemin de `tools/godot/capture_reference.gd`, jamais celui du jeu.
class_name ValleyWorld
extends Node3D

## Filet de sécurité TECHNIQUE (D.1R.4) : les montagnes périmétrales sont la
## vraie limite — ce filet ne rattrape que l'inattendu, TÔT (sous le plancher
## le plus bas, -1,5) et vite (cadence 0,25 s), vers le DERNIER POINT SÛR.
const FALL_LIMIT_Y: float = -6.0
const RESCUE_CHECK_INTERVAL: float = 0.25
## Cadence d'enregistrement du dernier point sûr (au sol uniquement).
const SAFE_POINT_INTERVAL: float = 2.0

## Sauvegarde minimale honnête (D.1R.5, PT-D1-05) : ce que « Continuer »
## restaure VRAIMENT — inventaire (armes + durabilités), arme équipée, flèches,
## coffres ouverts. Point de reprise DOCUMENTÉ : le spawn de la crête (le
## checkpoint d'entrée du donjon arrive avec la Phase E/F).
const SAVE_SLOT: String = "slot0"
const SAVE_SCHEMA: int = 2

## §7.7 : soleil à l'ouest (rayons vers +X), plongée 22°.
const SUN_ROTATION_DEG: Vector3 = Vector3(-22.0, -90.0, 0.0)

## §3.2, ajusté SUR CAPTURE (les valeurs de la spec sont des points de départ) :
## à 4,2 m, une capsule de 1,8 m occupait 57 % du cadre — mesuré sur la première
## capture. Reculée à ~7,2 m et montée à 2,6 m au-dessus des pieds : héros à
## ~32 % de la hauteur, dans la bande 32–40 % de §3.2, légèrement à gauche
## (décalage caméra +0,8). FOV horizontal ≈ 68° (vertical 42° en 16:9).
## Spawn avancé à z = 150, à 6 m du bord de crête : depuis z = 170, 26 m de
## plateau plat masquaient TOUTE la vallée (2e capture) — ici elle se révèle.
const VISTA_POSITION: Vector3 = Vector3(0.8, 26.9, 157.4)
const VISTA_ROTATION_DEG: Vector3 = Vector3(-6.0, 0.0, 0.0)
const VISTA_FOV: float = 42.0

@onready var _player: PlayerController = $Player
@onready var _spawn: Node3D = $SpawnPoint
@onready var _sun: DirectionalLight3D = $Sun
@onready var _shell: GameplayShell = $GameplayShell

var _last_safe: Vector3 = Vector3.ZERO
## IDs des pickups déjà ramassés — mémoire de monde, car l'objet lui-même a
## quitté l'arbre au moment de l'instantané (QA-D1R-01).
var _taken_pickups: Array[String] = []


func _ready() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 2)  # GameState.Flow.VALLEY
		# Retour du vestibule : DEVANT la porte de la citadelle, pas au spawn
		# (PT-D1-10 : « ressortir replace correctement le joueur devant la porte »).
		var tag: StringName = game_state.call("consume_pending_spawn")
		if tag == &"citadel_door":
			_player.position = Vector3(0, 34.3, -193.0)
	_last_safe = _player.position
	# Application de la sauvegarde — TOUJOURS si elle existe : une partie neuve
	# vient d'écrire un instantané minimal (sans inventaire) qui n'applique
	# rien ; une reprise applique tout. Aucun drapeau à transporter.
	_apply_save()
	# Instantanés : chaque coffre ouvert, chaque arme ramassée, et toute
	# transition sortante (porte de la citadelle, retour menu) — le loot acquis
	# survit à « Continuer » sans JAMAIS réapparaître au sol (QA-D1R-01).
	for chest: Node in find_children("*", "Chest", true, false):
		(chest as Chest).opened.connect(func(_id: StringName) -> void: _autosave())
	for pickup: Node in find_children("*", "WeaponPickup", true, false):
		var typed: WeaponPickup = pickup as WeaponPickup
		typed.picked_up.connect(func(_weapon: WeaponInstance) -> void:
			_on_pickup_taken(typed))
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow != null:
		flow.connect("transition_started", _on_transition_started)

	_sun.rotation_degrees = SUN_ROTATION_DEG
	_setup_environment()
	_setup_vista_camera()

	# Timers plutôt que polling par frame (§5.4).
	var rescue_timer: Timer = Timer.new()
	rescue_timer.wait_time = RESCUE_CHECK_INTERVAL
	rescue_timer.autostart = true
	rescue_timer.timeout.connect(_check_fall_rescue)
	add_child(rescue_timer)
	var safe_timer: Timer = Timer.new()
	safe_timer.wait_time = SAFE_POINT_INTERVAL
	safe_timer.autostart = true
	safe_timer.timeout.connect(_record_safe_point)
	add_child(safe_timer)


## Ciel pastel, brume bleutée, lumière ambiante du ciel — les ancres de §3.4 en
## version graybox. Construit en code : une seule source de vérité chiffrée.
func _setup_environment() -> void:
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.663, 0.831, 0.918)      # #A9D4EA
	sky_material.sky_horizon_color = Color(0.686, 0.784, 0.827)  # #AFC8D3
	sky_material.ground_bottom_color = Color(0.365, 0.561, 0.239)
	sky_material.ground_horizon_color = Color(0.686, 0.784, 0.827)
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.6
	# Brume de distance (§7.7 fog classique) : l'étagement atmosphérique de §3.2,
	# sans fog volumétrique (hors budget graybox et hors Compatibility).
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.686, 0.784, 0.827)
	environment.fog_density = 0.0018
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "ValleyEnvironment"
	world_environment.environment = environment
	add_child(world_environment)


func _setup_vista_camera() -> void:
	var vista: Camera3D = Camera3D.new()
	vista.name = "VistaCamera_Hero01"
	vista.position = VISTA_POSITION
	vista.rotation_degrees = VISTA_ROTATION_DEG
	vista.fov = VISTA_FOV
	vista.current = false
	add_child(vista)
	if OS.get_environment("VALLEY_VISTA") == "1":
		# Après que la caméra du joueur s'est déclarée : le différé gagne.
		vista.make_current.call_deferred()


func _record_safe_point() -> void:
	if _player != null and is_instance_valid(_player) and _player.is_on_floor() \
			and not _player.health().is_dead():
		_last_safe = _player.global_position


func _check_fall_rescue() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.global_position.y < FALL_LIMIT_Y:
		_player.velocity = Vector3.ZERO
		_player.global_position = _last_safe
		_player.reset_physics_interpolation()
		if _shell != null:
			_shell.play_rescue_fade()


func last_safe_point() -> Vector3:
	return _last_safe


## ---------------------------------------------------------------------------
## Sauvegarde minimale (D.1R.5) — §19.4 : lire → valider → appliquer, idempotent
## ---------------------------------------------------------------------------

func _exit_tree() -> void:
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow != null and flow.is_connected("transition_started", _on_transition_started):
		flow.disconnect("transition_started", _on_transition_started)


func _on_transition_started(_target: String) -> void:
	if is_inside_tree():
		_autosave()


## Le pickup se libère lui-même (`queue_free` au ramassage) : son ID doit donc
## être mémorisé ICI, sinon l'instantané suivant ne saurait plus qu'il a
## disparu — et « Continuer » le ferait réapparaître (QA-D1R-01).
func _on_pickup_taken(pickup: WeaponPickup) -> void:
	var id: String = String(pickup.pickup_id)
	if id.is_empty():
		push_warning("[save] pickup sans pickup_id — il réapparaîtra au rechargement.")
	elif not id in _taken_pickups:
		_taken_pickups.append(id)
	_autosave()


func _autosave() -> void:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null or _player == null or _player.inventory() == null:
		return
	var inventory: InventoryComponent = _player.inventory()
	var weapons: Array[Dictionary] = []
	for weapon: WeaponInstance in inventory.weapons():
		weapons.append({
			"id": String(weapon.definition_id()),
			"durability": weapon.current_durability,
		})
	var opened: Array[String] = []
	for chest: Node in find_children("*", "Chest", true, false):
		if (chest as Chest).is_opened():
			opened.append(String((chest as Chest).chest_id))
	save_system.call("save_slot", SAVE_SLOT, {
		"schema": SAVE_SCHEMA,
		"checkpoint": "valley.camp.start",
		"weapons": weapons,
		"equipped_index": inventory.equipped_index(),
		"arrows": inventory.arrows(),
		"opened_chests": opened,
		"taken_pickups": _taken_pickups.duplicate(),
		"boss_defeated": false,
	})


func _apply_save() -> void:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null or not bool(save_system.call("has_save", SAVE_SLOT)):
		return
	var data: Dictionary = save_system.call("load_slot", SAVE_SLOT)
	if data.is_empty():
		return
	# §19.4 : un item inconnu se journalise et n'arrête rien.
	if data.has("weapons") and _player != null and _player.inventory() != null:
		var inventory: InventoryComponent = _player.inventory()
		inventory.clear_weapons()
		for entry: Variant in (data["weapons"] as Array):
			var weapon_data: Dictionary = entry as Dictionary
			var id: String = String(weapon_data.get("id", ""))
			var path: String = "res://resources/weapons/%s.tres" % id
			if not ResourceLoader.exists(path):
				push_warning("[save] arme inconnue ignorée : %s" % id)
				continue
			var instance: WeaponInstance = WeaponInstance.create(
				load(path) as WeaponDefinition)
			instance.current_durability = int(weapon_data.get("durability",
				instance.current_durability))
			inventory.add_weapon(instance)
		var equipped: int = int(data.get("equipped_index", 0))
		inventory.equip_index(equipped)
		if data.has("arrows"):
			inventory.set_arrows(int(data["arrows"]))
	if data.has("opened_chests"):
		var opened: Array = data["opened_chests"] as Array
		for chest: Node in find_children("*", "Chest", true, false):
			if String((chest as Chest).chest_id) in opened:
				(chest as Chest).mark_opened_silently()
	if data.has("taken_pickups"):
		# Reconstruit la mémoire des pickups pris (élément par élément : un
		# fichier édité peut contenir autre chose que des chaînes), puis retire
		# du monde ceux déjà ramassés — jamais de second exemplaire (§11.4).
		for entry: Variant in (data["taken_pickups"] as Array):
			var id: String = String(entry)
			if not id.is_empty() and not id in _taken_pickups:
				_taken_pickups.append(id)
		for pickup: Node in find_children("*", "WeaponPickup", true, false):
			if String((pickup as WeaponPickup).pickup_id) in _taken_pickups:
				(pickup as WeaponPickup).mark_taken_silently()


func player() -> PlayerController:
	return _player
