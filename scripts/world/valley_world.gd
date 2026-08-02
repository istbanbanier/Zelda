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
## E.1 : même mémoire pour les ingrédients récoltés — politique v0.1
## EXPLICITE (§13.1) : pas de respawn, un ingrédient récolté reste récolté.
var _taken_ingredients: Array[String] = []


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
	# E.1 : les ingrédients de la vallée (§13.1) — posés en code comme le
	# relief, AVANT l'application de la sauvegarde qui retire les récoltés.
	_spawn_ingredients()
	_apply_ingredient_save()
	for pickup: Node in find_children("*", "IngredientPickup", true, false):
		var typed_ingredient: IngredientPickup = pickup as IngredientPickup
		typed_ingredient.collected.connect(
			func(_definition: IngredientDefinition) -> void:
				_on_ingredient_taken(typed_ingredient))
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


## Lumière et atmosphère V4.1 (réf. 01 du pack V4) : soleil doré de fin
## d'après-midi venant de la gauche, ciel chaud vers l'horizon, brume qui
## sépare les trois plans, brume basse dans les creux, orage LOCAL sur la
## citadelle. Construit en code : une seule source de vérité chiffrée.
func _setup_environment() -> void:
	# Soleil #FFD68A (§3.4) — chaud, ombres longues lisibles (§7.7). La rotation
	# vient de SUN_ROTATION_DEG (ouest/gauche, plongée 22°).
	_sun.light_color = Color(1.0, 0.839, 0.541)
	_sun.light_energy = 1.25
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 180.0

	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.663, 0.831, 0.918)      # #A9D4EA
	# Horizon réchauffé (V4 : ciel doré côté soleil) — entre pastel et sable.
	sky_material.sky_horizon_color = Color(0.82, 0.78, 0.68)
	sky_material.ground_bottom_color = Color(0.365, 0.561, 0.239)
	sky_material.ground_horizon_color = Color(0.78, 0.74, 0.66)
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.6
	# Filmic : hautes lumières chaudes sans écrêtage plastique (§7.1).
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# Glow FAIBLE, seuil haut (§7.7 : « bloom faible, seuil élevé ») : seuls
	# les émissifs — éclair, noyaux cyan — rayonnent, jamais le ciel.
	environment.glow_enabled = true
	environment.glow_intensity = 0.5
	environment.glow_bloom = 0.0
	environment.glow_hdr_threshold = 1.2
	# Brume de distance (§7.7 fog classique) : l'étagement atmosphérique de
	# §3.2, sans fog volumétrique (hors budget graybox et hors Compatibility).
	# L'aerial perspective fond les lointains vers le ciel — la profondeur
	# COLORIMÉTRIQUE demandée par V4.1 ; sky_affect bas garde le ciel propre.
	# 1re capture V4.1 : 0,0016 + aerial 0,55 NOYAIENT le plan moyen (ruines
	# dissoutes à 150 m) — l'inverse de « vallée lisible à 300 m ». Divisé.
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.72, 0.77, 0.80)
	environment.fog_density = 0.0009
	environment.fog_aerial_perspective = 0.35
	environment.fog_sky_affect = 0.08
	# Brume basse dans les creux (lit de rivière y≈0-6) : densité douce sous
	# y = 6 — la crête (y 24) et le plateau (y 34) restent clairs.
	environment.fog_height = 6.0
	environment.fog_height_density = 0.035
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "ValleyEnvironment"
	world_environment.environment = environment
	add_child(world_environment)

	# Orage LOCAL au-dessus de la citadelle (donjon culminant à y = 80). À
	# y 102, l'écart nuage-sommet (18 m) rendait l'éclair invisible depuis la
	# crête (2e capture) : à y 130, la colonne fait ~46 m et se LIT. Localité
	# testée.
	var storm: StormCell = StormCell.new()
	storm.name = "CitadelStorm"
	storm.position = Vector3(0, 115, -215)
	add_child(storm)
	if OS.get_environment("VALLEY_VISTA") == "1":
		storm.hold_flash()   # éclair majeur tenu pour la capture (§3.2, §21.8)
	_setup_dust()


## Poussière/pollen très contrôlés (V4.1) : quelques motes chaudes qui dérivent
## au-dessus de la crête de départ — visibles en contre-jour, jamais un rideau.
func _setup_dust() -> void:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "CrestDust"
	particles.amount = 24
	particles.lifetime = 7.0
	particles.preprocess = 7.0   # déjà en dérive à l'arrivée du joueur
	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(20.0, 4.0, 16.0)
	process.gravity = Vector3(0.12, -0.02, 0.0)   # dérive douce vers l'est
	process.initial_velocity_min = 0.05
	process.initial_velocity_max = 0.25
	process.scale_min = 0.5
	process.scale_max = 1.0
	particles.process_material = process
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.91, 0.75, 0.4)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = material
	particles.draw_pass_1 = quad
	particles.position = Vector3(0, 26.5, 152)
	add_child(particles)


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
	# ART-Q3 — caméra de contrôle du CAMP (§21.5 : « vue camp ») : fixe et
	# reproductible, activée par VALLEY_CAMP=1, même mécanique que la vista.
	var camp_camera: Camera3D = Camera3D.new()
	camp_camera.name = "CampCamera_01"
	camp_camera.position = Vector3(38.0, 9.2, 76.0)
	camp_camera.rotation_degrees = Vector3(-14.0, -28.0, 0.0)
	camp_camera.fov = 62.0
	camp_camera.current = false
	add_child(camp_camera)
	if OS.get_environment("VALLEY_CAMP") == "1":
		camp_camera.make_current.call_deferred()


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


func _on_ingredient_taken(pickup: IngredientPickup) -> void:
	var id: String = String(pickup.pickup_id)
	if not id.is_empty() and not id in _taken_ingredients:
		_taken_ingredients.append(id)
	_autosave()


## E.1 (§13.1) : les ingrédients de la vallée, posés en code comme le relief —
## deux fruits sur la crête, l'herbe au palier, la viande au camp, les
## champignons en forêt, la racine aux ruines, la BAIE près du pylône (§13.5 :
## enseigner la résistance près du danger), l'épice au sommet de la falaise
## (récompense d'ascension §9.3).
func _spawn_ingredients() -> void:
	var placements: Array[Array] = [
		["heal_fruit", Vector3(-9, 24.0, 153), "valley.ingredient.crest_fruit.01"],
		["heal_fruit", Vector3(7, 24.0, 147), "valley.ingredient.crest_fruit.02"],
		["stamina_herb", Vector3(35, 16.0, 109), "valley.ingredient.landing_herb.01"],
		["meat", Vector3(50, 6.0, 60), "valley.ingredient.camp_meat.01"],
		["heal_mushroom", Vector3(68, 2.0, 38), "valley.ingredient.forest_mushroom.01"],
		["heal_mushroom", Vector3(80, 2.0, 50), "valley.ingredient.forest_mushroom.02"],
		["defense_root", Vector3(4, 2.0, -44), "valley.ingredient.ruins_root.01"],
		["storm_berry", Vector3(96, 2.0, 4), "valley.ingredient.pylon_berry.01"],
		["rare_spice", Vector3(-108, 14.0, 62), "valley.ingredient.cliff_spice.01"],
	]
	var holder: Node3D = Node3D.new()
	holder.name = "Ingredients"
	add_child(holder)
	for placement: Array in placements:
		var pickup: IngredientPickup = IngredientPickup.new()
		pickup.name = String(placement[2]).replace(".", "_")
		pickup.definition = load("res://resources/ingredients/%s.tres"
			% String(placement[0])) as IngredientDefinition
		pickup.pickup_id = StringName(String(placement[2]))
		pickup.position = placement[1] as Vector3
		holder.add_child(pickup)


## Les pickups d'ingrédients naissent APRÈS `_apply_save()` : leur part de
## sauvegarde s'applique ici, sur le même instantané (§19.4, idempotent).
func _apply_ingredient_save() -> void:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null or not bool(save_system.call("has_save", SAVE_SLOT)):
		return
	var data: Dictionary = save_system.call("load_slot", SAVE_SLOT)
	if data.has("ingredients") and _player != null and _player.inventory() != null:
		_player.inventory().set_ingredients(data["ingredients"] as Dictionary)
	if data.has("taken_ingredients"):
		for entry: Variant in (data["taken_ingredients"] as Array):
			var id: String = String(entry)
			if not id.is_empty() and not id in _taken_ingredients:
				_taken_ingredients.append(id)
		for pickup: Node in find_children("*", "IngredientPickup", true, false):
			if String((pickup as IngredientPickup).pickup_id) in _taken_ingredients:
				(pickup as IngredientPickup).mark_taken_silently()


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
		"ingredients": inventory.ingredients_snapshot(),
		"taken_ingredients": _taken_ingredients.duplicate(),
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
