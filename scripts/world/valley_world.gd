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
## §12.9 (D-EN.6) : carte de navigation des grandes carrures. Créée à la
## main, donc LIBÉRÉE à la main — sans quoi elle fuit à la sortie de
## scène (fuite de RID mesurée au test).
var _large_navigation_map: RID = RID()


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
	# Monde ouvert : les 31 lieux, leur journal de découvertes et leurs
	# récompenses. AVANT `_apply_save()`, et ce n'est pas un détail d'ordre :
	#
	#  - `discoveries.apply_state()` ignore tout lieu non encore déclaré. Bâtir
	#    après aurait rechargé une partie où AUCUN lieu n'est découvert, en
	#    silence — l'avertissement « lieu inconnu » l'avait masqué ;
	#  - les coffres et armes des lieux doivent exister quand la sauvegarde
	#    retire ce qui a déjà été pris, sinon une arme ramassée réapparaît au
	#    rechargement et se ramasse une seconde fois (§11.4).
	_build_open_world()
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
	# D-EN.6 : les QUATRE familles au-delà du braise (§12.2-§12.5), posées
	# selon leur rôle de level design ; le coordinateur de combat (§12.8)
	# les gouverne toutes.
	_spawn_bestiary()
	# E.2b : le feu de cuisine — un interactable posé SUR le foyer réel du
	# camp (§13.3). L'atelier vit dans la coquille ; le feu n'est que la
	# porte, comme la collision reste celle du foyer existant.
	var campfire: Campfire = Campfire.new()
	campfire.name = "CampCookingFire"
	campfire.position = Vector3(44.6, 6.1, 63.2)
	add_child(campfire)
	# E.1 : les ingrédients de la vallée (§13.1) — posés en code comme le
	# relief, AVANT l'application de la sauvegarde qui retire les récoltés.
	_spawn_ingredients()
	_apply_ingredient_save()
	for pickup: Node in find_children("*", "IngredientPickup", true, false):
		var typed_ingredient: IngredientPickup = pickup as IngredientPickup
		typed_ingredient.collected.connect(
			func(_definition: IngredientDefinition) -> void:
				_on_ingredient_taken(typed_ingredient))
	# E.2a : cuisiner ou manger change la réserve de plats — instantané
	# immédiat, comme les coffres (le buff part dans le même instantané).
	if _player.inventory() != null:
		_player.inventory().meals_changed.connect(
			func(_count: int) -> void: _autosave())
	# Le signal des plats part AU PRÉLÈVEMENT, avant l'application du buff :
	# l'instantané du buff se prend sur SON propre signal, juste après.
	if _player.status() != null:
		_player.status().buff_applied.connect(
			func(_e: StringName, _p: float, _d: float) -> void: _autosave())
		# Correctif V4 lot 1 : l'EXPIRATION aussi — sans cet instantané, le
		# buff sauvegardé à l'application ressuscitait au rechargement avec
		# tout son temps (test « never_resurrects », rouge avant ce commit).
		_player.status().buff_expired.connect(
			func(_e: StringName) -> void: _autosave())
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
	# OMBRES FROIDES (§3.4 « ombre froide #4C5B75 », §7.7 « ombres bleues/violettes »).
	#
	# Le ciel seul remplissait les ombres à 0,6 : mesurée sur la capture de
	# référence, la vallée entière tenait entre 55 % et 80 % de valeur, sans
	# une seule masse sombre. Un monde sans ombre n'a pas d'heure — c'est le
	# reproche exact d'une revue à contexte frais, et la mesure lui donne
	# raison même si sa cause supposée (« soleil blanc ») était fausse : le
	# soleil EST miel, ce sont les ombres qui étaient remplies à ras bord.
	#
	# Contribution du ciel abaissée, et une couleur d'ambiance FROIDE explicite
	# prend le relais : les creux virent au bleu-violet au lieu du gris.
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.34
	environment.ambient_light_color = Color(0.298, 0.357, 0.459)   # #4C5B75
	environment.ambient_light_energy = 0.85
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
	environment.fog_density = 0.0011
	# Perspective aérienne RENFORCÉE plutôt que densité : elle fond les lointains
	# vers la couleur du CIEL en fonction de la profondeur, sans épaissir l'air
	# du plan moyen. Monter la densité avait dissous les ruines à 150 m.
	environment.fog_aerial_perspective = 0.62
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


## Lieux du monde ouvert. Chaque lieu se DÉCLARE au journal en naissant :
## c'est ce qui rend « aucune seconde récompense après rechargement » vrai
## sans que le lieu ait à s'en souvenir lui-même.
func _build_open_world() -> void:
	# Les huit familles de lieux. Chacune est bâtie par sa propre classe, puis
	# TOUS les points d'intérêt du monde sont reliés au journal en une passe :
	# un lieu qui n'est pas posé ici n'existe que dans ses tests, et le joueur
	# ne le verra jamais. C'est l'écueil déjà corrigé pour le village.
	var village: RiversideVillage = RiversideVillage.new()
	village.name = "RiversideVillage"
	add_child(village)
	var hamlets: Hamlets = Hamlets.new()
	hamlets.name = "Hamlets"
	add_child(hamlets)
	var ruins: ValleyRuins = ValleyRuins.new()
	ruins.name = "ValleyRuins"
	add_child(ruins)
	var relics: ValleyRelics = ValleyRelics.new()
	relics.name = "ValleyRelics"
	add_child(relics)
	var caves: ValleyCaves = ValleyCaves.new()
	caves.name = "ValleyCaves"
	add_child(caves)
	var undergrounds: ValleyUndergrounds = ValleyUndergrounds.new()
	undergrounds.name = "ValleyUndergrounds"
	add_child(undergrounds)
	var landmarks: ValleyLandmarks = ValleyLandmarks.new()
	landmarks.name = "ValleyLandmarks"
	add_child(landmarks)
	var wonders: ValleyWonders = ValleyWonders.new()
	wonders.name = "ValleyWonders"
	add_child(wonders)
	var territories: ValleyTerritories = ValleyTerritories.new()
	territories.name = "ValleyTerritories"
	add_child(territories)
	for poi: Node in find_children("*", "PointOfInterest", true, false):
		(poi as PointOfInterest).bind(discoveries)
	# §3 : un lieu sans récompense n'est pas une découverte. Les familles
	# posent des ancrages vides ; c'est ici qu'ils reçoivent un vrai coffre,
	# dont l'identifiant dérive de celui du lieu — donc unique et stable.
	rewards = DiscoveryRewards.new()
	rewards.name = "DiscoveryRewards"
	add_child(rewards)
	rewards.furnish(self)


## Journal des découvertes de la partie — public, pour que la sauvegarde de
## la vallée le collecte et que l'interface puisse s'y abonner.
var discoveries: DiscoveryLog = DiscoveryLog.new()

## Coffres posés sur les ancrages des lieux — public pour les tests.
var rewards: DiscoveryRewards = null


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
	# V4 lot 4 — caméra de contrôle de la DESCENTE (§15 : « descente »),
	# regard le long des rampes vers le camp.
	var descent_camera: Camera3D = Camera3D.new()
	descent_camera.name = "DescentCamera_01"
	descent_camera.position = Vector3(14.0, 27.0, 152.0)
	descent_camera.rotation_degrees = Vector3(-16.0, 12.0, 0.0)
	descent_camera.fov = 58.0
	descent_camera.current = false
	add_child(descent_camera)
	if OS.get_environment("VALLEY_DESCENT") == "1":
		descent_camera.make_current.call_deferred()
	# V4 lot 12 — caméras de contrôle des STRUCTURES : VALLEY_STRUCTURES=1,
	# le poste de garde depuis la route (la rampe derrière) ; =2, l'intérieur
	# de l'avant-poste depuis le seuil de sa porte.
	var structures_camera: Camera3D = Camera3D.new()
	structures_camera.name = "StructuresCamera_01"
	structures_camera.position = Vector3(4.0, 4.2, -95.0)
	structures_camera.rotation_degrees = Vector3(-10.9, -52.1, 0.0)
	structures_camera.fov = 62.0
	structures_camera.current = false
	add_child(structures_camera)
	if OS.get_environment("VALLEY_STRUCTURES") == "1":
		structures_camera.make_current.call_deferred()
	var interior_camera: Camera3D = Camera3D.new()
	interior_camera.name = "StructuresCamera_02"
	interior_camera.position = Vector3(19.8, 3.3, -52.0)
	interior_camera.rotation_degrees = Vector3(-9.8, -81.5, 0.0)
	interior_camera.fov = 66.0
	interior_camera.current = false
	add_child(interior_camera)
	if OS.get_environment("VALLEY_STRUCTURES") == "2":
		interior_camera.make_current.call_deferred()


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
	# La carte de navigation des grandes carrures est créée en code : elle
	# appartient à cette scène et meurt avec elle (fuite de RID mesurée).
	if _large_navigation_map.is_valid():
		NavigationServer3D.free_rid(_large_navigation_map)
		_large_navigation_map = RID()


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


## D-EN.6 (§12.2-§12.5, §12.8) — le bestiaire de la vallée. Les trois
## braises du camp restent dans la scène (première rencontre, §12.1) ;
## ces familles-ci occupent leurs rôles :
## - AZUR près de la rivière et en lisière de forêt : de vraies lignes de
##   tir et des angles de contournement (§12.2) ;
## - BRISEUR au sommet de la falaise ouest, gardien de la Lame conductrice
##   (§12.3 : « rare, gardien d'une forte récompense ») ;
## - COLOSSE dans les ruines centrales de la plaine nord, sur la route du
##   donjon — sa carrure interdit les passages étroits (§12.4) ;
## - CHASSEUR à l'est, DERRIÈRE le pylône : territoire optionnel signalé
##   par le relief, jamais sur le chemin principal (§12.5, §4.1).
func _spawn_bestiary() -> void:
	var holder: Node3D = Node3D.new()
	holder.name = "Bestiary"
	add_child(holder)
	_setup_large_navigation(holder)
	# Le coordinateur de groupe (§12.8) : tokens et plafond d'IA actives.
	var coordinator: CombatCoordinator = CombatCoordinator.new()
	coordinator.name = "CombatCoordinator"
	holder.add_child(coordinator)
	var placements: Array[Array] = [
		["res://scenes/enemies/RaiderBlue.tscn", Vector3(92, 2.1, 16), 3.0],
		["res://scenes/enemies/RaiderBlue.tscn", Vector3(58, 2.1, 30), 1.4],
		["res://scenes/enemies/RaiderBlack.tscn", Vector3(-104, 14.1, 62), 1.6],
		["res://scenes/enemies/RavineTroll.tscn", Vector3(-16, 2.1, -48), 0.4],
		["res://scenes/enemies/CentaurHunter.tscn", Vector3(150, 2.1, 52), 4.2],
	]
	for placement: Array in placements:
		var packed: PackedScene = load(String(placement[0])) as PackedScene
		if packed == null:
			push_warning("[bestiaire] scène absente : %s" % String(placement[0]))
			continue
		var enemy: Node3D = packed.instantiate() as Node3D
		enemy.position = placement[1] as Vector3
		holder.add_child(enemy)
		# Le regard initial fixe le TERRITOIRE, pas le joueur : chacun
		# garde son poste jusqu'à ce qu'il perçoive quelque chose.
		(enemy.get_node("Pivot") as Node3D).rotation.y = float(placement[2])


## §12.9 (D-EN.6) : une seconde carte de navigation, cuite pour un agent
## de 1,2 m de rayon — le colosse et le chasseur n'empruntent PAS les
## passages taillés pour un pillard. Carte SÉPARÉE (map_create) : les
## deux maillages ne se fusionnent jamais.
func _setup_large_navigation(holder: Node3D) -> void:
	var mesh: NavigationMesh = load(
		"res://scenes/world/valley/valley_navmesh_large.tres") as NavigationMesh
	if mesh == null:
		push_warning("[bestiaire] navmesh des grandes carrures absent — "
			+ "les grandes familles retombent sur la ligne directe.")
		return
	var region: NavigationRegion3D = NavigationRegion3D.new()
	region.name = "LargeNavigation"
	region.navigation_mesh = mesh
	region.add_to_group("large_navigation")
	holder.add_child(region)
	var map: RID = NavigationServer3D.map_create()
	NavigationServer3D.map_set_active(map, true)
	NavigationServer3D.map_set_up(map, Vector3.UP)
	NavigationServer3D.map_set_cell_size(map, mesh.cell_size)
	region.set_navigation_map(map)
	_large_navigation_map = map


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
		# V4 lot 12 : récompenses INTÉRIEURES des structures pénétrables —
		# entrer doit toujours payer (viande au guet, fruit chez le pêcheur,
		# baie d'orage au poste de garde : §13.5, la résistance AVANT le donjon).
		["meat", Vector3(21.5, 2.1, -52.5), "valley.ingredient.outpost_meat.01"],
		["heal_fruit", Vector3(-30.4, 2.1, 22.6), "valley.ingredient.shelter_fruit.01"],
		["storm_berry", Vector3(14.2, 2.1, -101.7), "valley.ingredient.guardpost_berry.01"],
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
	# E.2a (§19.1 : plats et « buff restant ») — restauration par le chemin
	# normal : les multiplicateurs se retendent via les signaux.
	if data.has("meals") and _player != null and _player.inventory() != null:
		_player.inventory().set_meals(data["meals"] as Array)
	if data.has("buff") and _player != null and _player.status() != null:
		_player.status().restore(data["buff"] as Dictionary)
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
		"meals": inventory.meals_snapshot(),
		"buff": _player.status().snapshot() if _player.status() != null else {},
		# Lieux découverts : seuls des identifiants partent en sauvegarde
		# (§19.2), et le journal refuse d'en re-récompenser un au retour.
		"discoveries": discoveries.collect_state(),
		"boss_defeated": false,
	})


func _apply_save() -> void:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null or not bool(save_system.call("has_save", SAVE_SLOT)):
		return
	var data: Dictionary = save_system.call("load_slot", SAVE_SLOT)
	if data.is_empty():
		return
	if data.has("discoveries"):
		discoveries.apply_state(data["discoveries"] as Dictionary)
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
