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
## coffres ouverts, et depuis le schéma 3 la position/rotation du joueur
## (§19.1, défaut S2 du playtest externe no1 : « Continuer » replaçait sur la
## crête). Repli DOCUMENTÉ si la position est absente ou invalide : le spawn.
const SAVE_SLOT: String = "slot0"
const SAVE_SCHEMA: int = 4

## §19.4 : « si position invalide, utiliser checkpoint ». Le fichier de
## sauvegarde est éditable à la main — bornes du monde jouable, PAS des
## suppositions : terrain 512 × 512 m centré (±256, petite marge), plafond
## au-dessus de tout sol praticable (donjon y = 34, citadelle y = 80),
## plancher STRICTEMENT au-dessus du filet de secours — une position qui
## déclencherait le sauvetage à la première frame n'est pas une reprise.
const SAVED_POSITION_LIMIT_XZ: float = 260.0
const SAVED_POSITION_LIMIT_Y: float = 120.0

## §7.7 : soleil à l'ouest (rayons vers +X), plongée 22°.
const SUN_ROTATION_DEG: Vector3 = Vector3(-22.0, -90.0, 0.0)

## Repose des ramassables sur le sol (voir `_drop_pickups_to_ground`).
## La sonde part TRÈS haut : un objet enterré de 8 m — le cas réellement
## rencontré sur la crête — ne serait pas rattrapé par un rayon court.
const GROUND_SNAP_UP: float = 40.0
const GROUND_SNAP_DOWN: float = 60.0
## Un ingrédient posé pile sur la surface s'y encastre à l'œil : on le pose
## légèrement dessus, comme un objet réellement déposé.
const GROUND_SNAP_CLEARANCE: float = 0.12

## §3.2, ajusté SUR CAPTURE (les valeurs de la spec sont des points de départ) :
## à 4,2 m, une capsule de 1,8 m occupait 57 % du cadre — mesuré sur la première
## capture. Reculée à ~7,2 m et montée à 2,6 m au-dessus des pieds : héros à
## ~32 % de la hauteur, dans la bande 32–40 % de §3.2, légèrement à gauche
## (décalage caméra +0,8). FOV horizontal ≈ 68° (vertical 42° en 16:9).
## Spawn avancé à z = 150, à 6 m du bord de crête : depuis z = 170, 26 m de
## plateau plat masquaient TOUTE la vallée (2e capture) — ici elle se révèle.
# H-3 : le héros se tient AU BORD de la rupture de pente (§1.1 — la
# référence regarde la vallée en contrebas) ; caméra avancée d'autant et
# regard plus plongeant (−10°) pour que la SpawnSlope occupe le bas du
# cadre au lieu d'être cachée par les brins de la prairie.
const VISTA_POSITION: Vector3 = Vector3(0.8, 34.9, 153.4)
# −8° : à −10, le nuage d'orage et la spire sortaient du cadre (ciel
# réduit à ~10 % — la référence en veut 38-48 %). Mesuré sur capture.
const VISTA_ROTATION_DEG: Vector3 = Vector3(-8.0, 0.0, 0.0)
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
## PT-D1-10 : le retour du vestibule place le joueur devant la porte de la
## citadelle. Ce placement GAGNE sur la position sauvegardée — l'instantané
## de transition a été pris SUR le déclencheur de la porte, y replacer le
## joueur le renverrait dans le vestibule en boucle.
var _pending_spawn_applied: bool = false
## Vrai sur une partie NEUVE (instantané du menu, sans inventaire) : la seule
## fois où l'invite d'interprétation de la fumée a un sens. S3 des playtests :
## quatre testeurs n'ont jamais trouvé le camp — la fumée montre OÙ, cette
## ligne dit QUOI. Une fois, jamais de marqueur (§2.2 P2 : curiosité, pas
## checklist).
var _fresh_run: bool = false
## Aides au déplacement, posées dans la vallée même (playtest : elles
## n'existaient que dans la scène d'entraînement, donc pas dans le jeu).
var _mount: Mount = null
var _dev_fly: DevFlyMode = null
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
			_pending_spawn_applied = true
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
	if _fresh_run:
		var hint_timer: SceneTreeTimer = get_tree().create_timer(4.0)
		hint_timer.timeout.connect(func() -> void:
			if not is_inside_tree():
				return
			var bus: Node = get_node_or_null("/root/EventBus")
			if bus != null:
				bus.call("notify", "De la fumée s'élève au loin — un campement ?"))
	# La vallée a un fond sonore. Sans lui, le jeu est littéralement muet
	# entre deux actions — le défaut le plus cité du playtest en aveugle.
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play_ambience"):
		audio.call("play_ambience", &"amb_valley")
	# E.2b : le feu de cuisine — un interactable posé SUR le foyer réel du
	# camp (§13.3). L'atelier vit dans la coquille ; le feu n'est que la
	# porte, comme la collision reste celle du foyer existant.
	var campfire: Campfire = Campfire.new()
	campfire.name = "CampCookingFire"
	campfire.position = Vector3(44.6, 6.1, 63.2)
	add_child(campfire)
	# Monture et vol libre DANS LA VALLÉE, pas seulement au terrain
	# d'entraînement. Défaut de livraison signalé au playtest : les deux
	# n'existaient que dans `TrainingGrounds.tscn`, une scène qu'il faut
	# lancer à la main — donc absents du jeu tel qu'on y joue, alors que la
	# demande était précisément d'explorer CETTE carte plus vite.
	_spawn_travel_aids()
	# E.1 : les ingrédients de la vallée (§13.1) — posés en code comme le
	# relief, AVANT l'application de la sauvegarde qui retire les récoltés.
	_spawn_ingredients()
	_apply_ingredient_save()
	for shard: Node in find_children("*", "FragmentPickup", true, false):
		var typed_shard: FragmentPickup = shard as FragmentPickup
		if typed_shard != null:
			typed_shard.picked_up.connect(
				_on_fragment_shard_taken.bind(typed_shard))
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
	_paint_the_world()


## Passe de PEINTURE de toute la carte (mandat « de toute la map »).
##
## Elle vient EN DERNIER, quand tout est construit : relief, lieux,
## bestiaire, ingrédients, feu de cuisine. Une passe posée plus tôt
## aurait laissé nus tous les objets créés après elle — c'est
## précisément le genre d'oubli qu'une recette recopiée à six endroits
## produit, et la raison pour laquelle elle vit désormais en un seul
## (`PainterlyRecipe`).
##
## Ce qu'elle ne touche pas, par CONTRAT :
##   - tout matériau qui émet vraiment — câbles, récepteurs, dangers,
##     noyaux, runes : ce sont des télégraphes de jeu, pas du décor ;
##   - l'orage, qui porte son propre langage d'éclair déjà réglé.
func _paint_the_world() -> void:
	# Le nuage de la vallée s'appelle `CitadelStorm` : la première passe
	# l'a blanchi parce que la liste ne connaissait que « Storm ».
	# DÉFAUT CORRIGÉ (audit du 2026-08-06). L'exclusion portait sur le nœud
	# `Terrain` tout entier, et `_is_skipped()` remonte les ANCÊTRES : tout
	# son sous-arbre était donc ignoré. Or l'habillage du monde y est monté —
	# camp, forêt, zones, phrases végétales, structures secondaires, citadelle,
	# pylône, eau, chemins. Le commentaire précédent affirmait que « les props,
	# roches, bâtiments et végétaux gagnent la peinture dès maintenant » : c'était
	# faux, ils étaient tous exclus avec le sol.
	#
	# On nomme donc les PORTEURS DE SOL un par un. Eux seuls gardent leurs
	# teintes macro (la recette, réglée sur un laboratoire sans terrain, les
	# délavait : lointain de 65 % à 74 %, sol gris). Tout le reste du monde
	# reçoit enfin le style.
	#
	# … ET C'EST PRÉCISÉMENT CE « UN PAR UN » QUI A DÉRIVÉ. La liste citait
	# douze dalles et pas UNE rampe. `DungeonRamp` — la rampe processionnelle
	# de la citadelle, 55 % du cadre depuis la route du nord — était donc
	# repeinte : de la pierre rendue en VERT VIF (140, 218, 82), un tapis
	# agrafé sur une falaise brune. Idem pour la pente de la crête, les trois
	# rampes de la descente, la sortie du camp, la rampe du pylône et les
	# quatre berges de la rivière.
	#
	# L'exemption vit désormais dans `PainterlyRecipe.GROUND_CARRIER_GROUP`,
	# posé par `_slab()` et `_ramp()` eux-mêmes : un porteur de sol créé
	# demain sera exempté sans que personne y pense. Ne restent ici que les
	# nœuds qui ne sont NI dalle NI rampe.
	var skip: Array[String] = ["CitadelStorm", "Storm", "StormCell",
		"GroundVariation", "Paths",
		# L'ANNEAU LOINTAIN reste hors peinture : la recette est réglée pour
		# le premier plan, et elle éclaircissait l'horizon de 65 % à 74 % —
		# les montagnes viraient au blanc et l'étagement des trois plans
		# (§1.3) disparaissait. Noms relevés dans `valley_terrain.gd`.
		"WallSkirts", "BorderCrests", "FarSkyline", "MountainDressing",
		"PlateauSkirts", "BorderNorth", "BorderSouth", "BorderEast",
		"BorderWest"]
	var painted: int = PainterlyRecipe.paint_world(self, skip)
	if painted > 0:
		print("[art] vallée peinte : %d surfaces" % painted)


## Lumière et atmosphère V4.1 (réf. 01 du pack V4) : soleil doré de fin
## d'après-midi venant de la gauche, ciel chaud vers l'horizon, brume qui
## sépare les trois plans, brume basse dans les creux, orage LOCAL sur la
## citadelle. Construit en code : une seule source de vérité chiffrée.
func _setup_environment() -> void:
	# Soleil #FFD68A (§3.4) — chaud, ombres longues lisibles (§7.7). La rotation
	# vient de SUN_ROTATION_DEG (ouest/gauche, plongée 22°).
	_sun.light_color = Color(1.0, 0.839, 0.541)
	# Revue Gate H (correction n°1) : l'image lisait « zénithal plat » —
	# l'ambiance à 0,85 remplissait les ombres à ras bord, le modelé
	# disparaissait. Direct RENFORCÉ (1,45), ambiance à voir plus bas.
	_sun.light_energy = 1.30
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
	environment.ambient_light_energy = 0.55
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
	# H-7b : le niveau de gris §7.16 a tranché — tiers haut ET milieu à
	# 185/179 de luma : l'aerial à 0,62 noyait le plan moyen dans un champ
	# pâle unique, défaisant le relief des passes H. Redescendu à 0,48 et
	# brume refroidie/assombrie ; cible mesurée : ≥ 15 points d'écart entre
	# tiers haut et milieu (script make_review_pack).
	environment.fog_light_color = Color(0.72, 0.77, 0.83)
	environment.fog_density = 0.00075
	environment.fog_aerial_perspective = 0.42
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
	# Passe H-2 : cellule à y 122 — la colonne d'éclair passe de 14 à ~18 m
	# (ventre à 118, impact au sommet de la spire à 100), les 14 m de H-1 se
	# perdaient dans la jupe du nuage. Haut de frame ≈ y 123 à 360 m : seuls
	# les grumeaux hauts sont rognés — c'est la place du nuage dans la
	# référence (Y 0-17 % de l'image).
	storm.position = Vector3(0, 122, -215)
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
	# Le monde porte 33 lieux nommés — village, ferme, arbre foudroyé,
	# belvédère… — et le journal émettait fidèlement `discovered` à chaque
	# première arrivée. Ce signal n'avait AUCUN abonné : le joueur traversait
	# la vallée et découvrait tout dans un silence total, sans jamais savoir
	# qu'il venait d'arriver quelque part. §6.3 veut une exploration guidée par
	# la curiosité : encore faut-il que le monde accuse réception.
	if not discoveries.discovered.is_connected(_on_place_discovered):
		discoveries.discovered.connect(_on_place_discovered)
	# §3 : un lieu sans récompense n'est pas une découverte. Les familles
	# posent des ancrages vides ; c'est ici qu'ils reçoivent un vrai coffre,
	# dont l'identifiant dérive de celui du lieu — donc unique et stable.
	rewards = DiscoveryRewards.new()
	rewards.name = "DiscoveryRewards"
	add_child(rewards)
	rewards.furnish(self)
	# LE SOL DES LIEUX HABITÉS, en dernier : il a besoin que tout soit bâti
	# pour mesurer l'emprise réelle. Un village n'est pas une collection de
	# maisons, c'est une terre battue, une place et des chemins qui s'y
	# rendent — sans quoi le regard lit « modèles alignés sur un pré ».
	# Différé d'une frame : les emprises se mesurent en coordonnées MONDE,
	# et les sous-arbres viennent tout juste d'entrer dans l'arbre.
	_lay_settlement_ground.call_deferred()


## Pose la terre battue, la place et les chemins de chaque lieu habité.
##
## Les implantations sont retrouvées par le NOM de leur nœud, tel que leur
## bâtisseur l'a écrit. Un lieu absent est simplement sauté : cette passe ne
## doit jamais empêcher le monde de se charger.
func _lay_settlement_ground() -> void:
	if not is_inside_tree():
		return
	# nom du groupe -> [chemin du bâtisseur, noms des bâtiments, altitude du sol]
	var plans: Array = [
		["Hamlets", ["CabaneDesBucherons", "Scierie", "PileDeTroncs",
			"Charretterie"], 2.0, 20260806],
		["Hamlets", ["CorpsDeGarde", "GalerieDeMine", "Sechoir",
			"CourDeMinerai"], 2.0, 20260807],
	]
	var total_paths: int = 0
	var total_props: int = 0
	for plan: Array in plans:
		var host: Node3D = get_node_or_null(NodePath(plan[0] as String)) as Node3D
		if host == null:
			continue
		var buildings: Array[Node3D] = []
		for building_name: String in (plan[1] as Array):
			var found: Array[Node] = host.find_children(building_name, "Node3D",
				true, false)
			if not found.is_empty():
				buildings.append(found[0] as Node3D)
		if buildings.size() < 2:
			continue
		var group: String = "Sol_%s" % (plan[1] as Array)[0]
		var report: Dictionary = SettlementGround.lay(host, group, buildings,
			plan[2] as float)
		total_paths += report["paths"] as int
		var centre: Vector3 = SettlementGround.footprint(
			host.get_node(NodePath(group)) as Node3D).get_center()
		centre.y = plan[2] as float
		total_props += SettlementGround.populate(host, "Vie_%s"
			% (plan[1] as Array)[0], centre, 9.0, 7, plan[3] as int)
	if total_paths > 0:
		print("[monde] lieux habités : %d chemins, %d objets de vie"
			% [total_paths, total_props])


## Journal des découvertes de la partie — public, pour que la sauvegarde de
## la vallée le collecte et que l'interface puisse s'y abonner.
var discoveries: DiscoveryLog = DiscoveryLog.new()


## Une découverte se dit une fois, brièvement, et sans marqueur permanent :
## c'est une récompense d'attention, pas une case à cocher.
func _on_place_discovered(_poi_id: StringName, display_name: String) -> void:
	if display_name.is_empty():
		return
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.call("notify", "Découvert : %s" % display_name)

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
	# CAMÉRA ENTERRÉE, corrigée le 2026-08-11. Elle était posée à
	# (14 ; 27 ; 152) : `SpawnRidge` est une dalle qui couvre x −50..50 et
	# z 144..208 avec son sommet à **y = 32**. La caméra se trouvait donc
	# CINQ MÈTRES SOUS le sol de la crête, à l'intérieur du volume. Sa capture
	# de gate est un aplat vert du bord au bord, et l'était déjà au commit
	# audité — personne ne l'avait regardée.
	#
	# Reposée 3 m au-dessus du rebord et orientée vers le camp (45 ; 6 ; 65) :
	# lacet −21,5° et plongée −17° sont l'angle exact de ce vecteur, pas un
	# réglage à l'œil.
	descent_camera.position = Vector3(10.0, 35.0, 154.0)
	descent_camera.rotation_degrees = Vector3(-17.0, -21.5, 0.0)
	descent_camera.fov = 60.0
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
	_setup_gate_cameras()


## ---------------------------------------------------------------------------
## LES SIX CAMÉRAS DE GATE DE LA TRANCHE D'OUVERTURE
##
## Le prompt de reprise du 2026-08-11 exige « six paires avant/après » et « la
## même caméra » de part et d'autre. Le dépôt avait bien des caméras de
## contrôle, mais dispersées derrière cinq variables d'environnement
## différentes, sans jeu nommé ni ordre : impossible de dire « les six caméras
## de gate » sans les énumérer à la main à chaque fois, donc impossible de
## garantir qu'une comparaison porte sur les mêmes.
##
## `VALLEY_GATE=1..6` les rassemble sous un seul nom, dans l'ordre du parcours
## joué : crête → descente → camp → gué → route du nord → approche de la
## citadelle. Les trois premières RÉUTILISENT les nœuds existants — dupliquer
## leurs cotes les aurait fait diverger le jour où l'une bouge.
##
## Ce ne sont PAS des caméras de jeu. Aucune ne s'active sans sa variable, et
## une capture aérienne de debug ne remplace pas une vue joueur : les six sont
## posées à hauteur d'œil (1,6-1,8 m au-dessus du sol) sauf la crête, qui est
## la North Star de §3.2 et garde son recul d'épaule.
## ---------------------------------------------------------------------------

## Nom du nœud caméra pour chaque numéro de gate. Étendre cette liste est un
## geste délibéré : le nombre « six » est cité dans les preuves.
const GATE_CAMERA_NAMES: Array[String] = [
	"VistaCamera_Hero01",     # 1 — la crête, cadrage North Star §3.2
	"DescentCamera_01",       # 2 — la descente en S vers le camp
	"CampCamera_01",          # 3 — le camp comme lieu habité
	"GateCamera_Ford",        # 4 — le gué ouest, la rivière et le plan moyen
	"GateCamera_NorthRoad",   # 5 — la plaine nord sur la route du donjon
	"GateCamera_Citadel",     # 6 — l'approche du plateau et de la citadelle
]


func _setup_gate_cameras() -> void:
	# Gué ouest (x 20, z 10) : le joueur arrive de la plaine sud et découvre
	# la rivière, le plan moyen et le monument au-dessus. Hauteur d'œil sur la
	# berge sud, à 30 m du passage.
	_add_gate_camera("GateCamera_Ford", Vector3(20.0, 3.7, 42.0),
		Vector3(-3.0, 4.0, 0.0), 60.0)
	# Plaine nord, à mi-chemin du plateau : c'est le plan qui montrait 815
	# impacts de sonde sur deux dalles plates, et la face sud du plateau en
	# grand mur. Regard droit vers le nord.
	#
	# CAMÉRA CONTRE UN MUR, corrigée le 2026-08-12 (passe 3). Posée à
	# (−2 ; 3,7 ; −60), l'œil vivait à 2,6 m à l'EST de `RuinWall03`
	# (x = −4, z −56..−68, sommet y 4,6 : 0,9 m AU-DESSUS de l'œil) — la
	# moitié gauche du cadre était un coin gris sans matière, et l'était
	# depuis la création de la caméra. Même famille que la caméra de descente
	# enterrée : le picking par rayon a tranché (la sonde d'emprise ne voyait
	# pas l'AABB fine du mur). Décalée à x = +4 : la route reste au tiers
	# gauche, les ruines se lisent à distance de lecture, le mur le plus
	# proche est à plus de 7 m. Invariant testé :
	# `test_no_gate_camera_has_a_static_wall_against_its_lens`.
	_add_gate_camera("GateCamera_NorthRoad", Vector3(4.0, 3.7, -60.0),
		Vector3(1.5, 0.0, 0.0), 58.0)
	# Approche : sur la route, AVANT la rampe processionnelle. Cadrage réglé
	# sur capture — posée à z −118, la caméra se trouvait à 47 m d'une face de
	# plateau haute de 42 m : le cadre entier était le mur, la citadelle
	# n'apparaissait pas, et une comparaison avant/après n'aurait rien montré
	# d'autre qu'un aplat brun. À z −92, la face monte à 22° et la spire (y 100)
	# à 39° : le monument, sa falaise porteuse et le sol tiennent ensemble.
	_add_gate_camera("GateCamera_Citadel", Vector3(1.0, 3.7, -92.0),
		Vector3(14.0, 0.0, 0.0), 58.0)
	var selected: String = OS.get_environment("VALLEY_GATE")
	if selected.is_empty():
		return
	var index: int = selected.to_int() - 1
	if index < 0 or index >= GATE_CAMERA_NAMES.size():
		push_warning("VALLEY_GATE=%s hors des six caméras de gate" % selected)
		return
	var camera: Camera3D = get_node_or_null(
		NodePath(GATE_CAMERA_NAMES[index])) as Camera3D
	if camera != null:
		camera.make_current.call_deferred()


func _add_gate_camera(camera_name: String, at: Vector3, rotation_deg: Vector3,
		fov: float) -> void:
	var camera: Camera3D = Camera3D.new()
	camera.name = camera_name
	camera.position = at
	camera.rotation_degrees = rotation_deg
	camera.fov = fov
	camera.current = false
	add_child(camera)


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


## L'éclat se libère au ramassage : mémoriser son ID ici (même règle que
## les armes au sol, QA-D1R-01) — et le Fragment lui-même part dans le
## champ `fragments` du payload à l'autosave qui suit.
func _on_fragment_shard_taken(_fragment_id: StringName,
		pickup: FragmentPickup) -> void:
	var id: String = String(pickup.pickup_id)
	if not id.is_empty() and not id in _taken_pickups:
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
	# Chaque ligne : scène, position, lacet initial, ronde (décalages locaux).
	#
	# RÉÉQUILIBRAGE V5 — un audit de la carte entière a mesuré que la route
	# naturelle du spawn jusqu'à la citadelle ne croisait AUCUN adversaire :
	# écart latéral minimal de 30 m pour 22 à 35 m de portée de vision, et deux
	# segments (0→183 m puis 192→349 m) où la détection était géométriquement
	# impossible. On pouvait donc atteindre le boss sans avoir porté un coup —
	# et tout ce que le jeu a construit (armes, garde, cuisine, Bracelet)
	# restait facultatif, donc invisible.
	#
	# On ne rend rien obligatoire : on POSE des présences sur le chemin, avec
	# leurs territoires bornés. Le joueur peut toujours contourner, il ne peut
	# plus ignorer.
	#
	# Et surtout, ils BOUGENT. `patrol_offsets` n'était renseigné nulle part :
	# l'état restait `IDLE`, `_face()` n'était jamais appelé, et les huit
	# ennemis étaient des cônes de vision gravés dans la carte. Une ronde même
	# courte fait balayer le regard et rend le monde habité de loin.
	var placements: Array[Array] = [
		["res://scenes/enemies/RaiderBlue.tscn", Vector3(92, 2.1, 16), 3.0,
			[Vector3(6, 0, 0), Vector3(-6, 0, 4)]],
		["res://scenes/enemies/RaiderBlue.tscn", Vector3(58, 2.1, 30), 1.4,
			[Vector3(0, 0, 7), Vector3(5, 0, -3)]],
		["res://scenes/enemies/RaiderBlack.tscn", Vector3(-104, 14.1, 62), 1.6,
			[Vector3(5, 0, 3), Vector3(-4, 0, -5)]],
		# Le colosse quitte son coin pour le SEUIL de la plaine nord, sur l'axe
		# de la rampe du donjon : on ne peut plus monter sans l'avoir vu.
		["res://scenes/enemies/RavineTroll.tscn", Vector3(22, 2.1, -64), 0.4,
			[Vector3(9, 0, 0), Vector3(-9, 0, 3)]],
		["res://scenes/enemies/CentaurHunter.tscn", Vector3(150, 2.1, 52), 4.2,
			[Vector3(12, 0, 8), Vector3(-10, 0, -6)]],
		# Les 150 m morts entre le colosse et la porte de la citadelle.
		["res://scenes/enemies/RaiderBlue.tscn", Vector3(26, 2.1, -118), 2.4,
			[Vector3(0, 0, 8), Vector3(-7, 0, 0)]],
		["res://scenes/enemies/RaiderRed.tscn", Vector3(-24, 2.1, -148), 0.2,
			[Vector3(6, 0, 4), Vector3(-5, 0, -4)]],
		# Le poste de garde et l'avant-poste étaient meublés et VIDES : râtelier
		# d'armes, bancs, ordres écrits, et personne depuis dix ans.
		["res://scenes/enemies/RaiderBlue.tscn", Vector3(15, 2.1, -99), -1.6,
			[Vector3(4, 0, 0), Vector3(-4, 0, 5)]],
		["res://scenes/enemies/RaiderRed.tscn", Vector3(20, 2.1, -49), -1.6,
			[Vector3(5, 0, 0), Vector3(0, 0, 5)]],
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
		if placement.size() > 3:
			var route: Array[Vector3] = []
			for offset: Variant in placement[3] as Array:
				route.append(offset as Vector3)
			(enemy as EnemyBase).patrol_offsets = route


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
	# LES INGRÉDIENTS SE POSENT SUR LE SOL RÉEL, pas sur une cote écrite à la
	# main. Les deux fruits de la crête étaient à y = 24 — la cote du spawn
	# dans MASTER_SPEC §3.3 — alors que le relief a depuis été bâti à y = 32 :
	# ils étaient donc ENTERRÉS de 8,00 m, mesurés à la sonde. Ce sont les deux
	# premiers ramassables de la partie, à l'endroit exact où le joueur prend
	# la main ; le playtest du 2026-08-07 finit avec « 0 ingrédient ramassé ».
	# C'est la même classe de défaut qu'ISS-035 (les pas japonais suspendus
	# au-dessus du lit) : une cote recopiée d'un document au lieu d'être
	# déduite du terrain. On la déduit.
	_drop_pickups_to_ground.call_deferred(holder)


## Repose chaque ramassable sur le décor sous lui. Appelé en différé : les
## corps statiques du relief doivent être enregistrés auprès du serveur
## physique avant qu'un rayon puisse les rencontrer.
func _drop_pickups_to_ground(holder: Node) -> void:
	if not is_instance_valid(holder):
		return
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if space == null:
		return
	for node: Node in holder.get_children():
		var pickup: Node3D = node as Node3D
		if pickup == null:
			continue
		var from: Vector3 = pickup.global_position + Vector3.UP * GROUND_SNAP_UP
		var to: Vector3 = pickup.global_position - Vector3.UP * GROUND_SNAP_DOWN
		# Couche 1 (World Static) seule : un ingrédient se pose sur le relief,
		# jamais sur un ennemi qui passait par là.
		var hit: Dictionary = space.intersect_ray(
			PhysicsRayQueryParameters3D.create(from, to, 1))
		if hit.is_empty():
			continue
		pickup.global_position = (hit["position"] as Vector3) \
			+ Vector3.UP * GROUND_SNAP_CLEARANCE


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
	# FUSION, jamais écrasement (TESTS.md, bugs 2 et 3). Ce payload écrivait un
	# dictionnaire figé : tout champ posé par une AUTRE scène disparaissait à
	# chaque autosave — dont `boss_defeated`, que l'arène pose en fusionnant,
	# et que le premier coffre ouvert après le retour en vallée remettait à
	# false EN DUR. La victoire du joueur était effacée par sa propre
	# exploration. On charge, on recouvre les champs que CETTE scène possède,
	# on réécrit — exactement le modèle de `boss_arena.gd`.
	var payload: Dictionary = {}
	if bool(save_system.call("has_save", SAVE_SLOT)):
		payload = save_system.call("load_slot", SAVE_SLOT) as Dictionary
	payload.merge({
		"schema": SAVE_SCHEMA,
		"checkpoint": "valley.camp.start",
		# §19.1 : position/rotation du joueur — en PRIMITIFS (§19.2 : jamais
		# un Variant Godot sérialisé). Le corps ne tourne jamais (voir
		# PlayerController._ready) : le lacet vit sur VisualRoot.
		# Le DERNIER SOL FOULÉ, jamais la position courante : sauvegarder au
		# milieu d'une paroi, d'une chute ou d'un coin de décor produisait une
		# reprise dans le décor, dont on ne sortait plus (voir
		# `PlayerController.last_grounded_position`).
		"player_position": {
			"x": _player.last_grounded_position().x,
			"y": _player.last_grounded_position().y,
			"z": _player.last_grounded_position().z,
		},
		"player_yaw": _player_visual_yaw(),
		# §19.1 : « santé/endurance ». Sans elles, recharger soignait
		# gratuitement — l'exploit qui vide le danger de son sens.
		"player_health": _player.health().current() \
			if _player.health() != null else 0.0,
		"player_stamina": _player.stamina().current() \
			if _player.stamina() != null else 0.0,
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
		"fragments": _fragments_snapshot(),
	}, true)
	# `boss_defeated` n'apparaît plus ici : ce champ appartient à l'ARÈNE. Une
	# partie neuve le reçoit du menu principal ; la fusion le préserve ensuite.
	save_system.call("save_slot", SAVE_SLOT, payload)


## Fragments détenus (P2-4e), en chaînes primitives (§19.2).
func _fragments_snapshot() -> Array[String]:
	var held: Array[String] = []
	if _player == null:
		return held
	var resonance: ResonanceController = _player.get_node_or_null(
		"Components/ResonanceController") as ResonanceController
	if resonance == null:
		return held
	for id: StringName in resonance.fragments():
		held.append(String(id))
	return held


func _apply_save() -> void:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null or not bool(save_system.call("has_save", SAVE_SLOT)):
		return
	var data: Dictionary = save_system.call("load_slot", SAVE_SLOT)
	if data.is_empty():
		return
	# Partie neuve : l'instantané du menu n'a pas encore d'inventaire. C'est le
	# seul moment où le joueur ignore ce qu'est la colonne au loin.
	_fresh_run = not data.has("weapons")
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
		for shard: Node in find_children("*", "FragmentPickup", true, false):
			if String((shard as FragmentPickup).pickup_id) in _taken_pickups:
				(shard as FragmentPickup).mark_taken_silently()
	# Fragments détenus (P2-4e) : re-accordés — grant refuse les doublons,
	# un identifiant inconnu se journalise par le refus, rien ne casse.
	if data.has("fragments") and _player != null:
		var resonance: ResonanceController = _player.get_node_or_null(
			"Components/ResonanceController") as ResonanceController
		if resonance != null:
			for entry: Variant in (data["fragments"] as Array):
				resonance.grant_fragment(StringName(String(entry)))
	_restore_player_transform(data)
	_restore_player_vitals(data)


## Santé/endurance (§19.1), traitées comme le transform : entrée NON FIABLE.
## Un champ absent (sauvegarde v3), non numérique ou hors bornes est ignoré et
## le joueur repart aux valeurs pleines — jamais de crash, jamais de mort au
## chargement : une santé sauvegardée à zéro est un fichier incohérent (on ne
## sauvegarde pas un mort), le plancher est donc 1.
func _restore_player_vitals(data: Dictionary) -> void:
	if _player == null:
		return
	var raw_health: Variant = data.get("player_health")
	if _player.health() != null and (raw_health is float or raw_health is int):
		var value: float = float(raw_health)
		if is_finite(value) and value > 0.0:
			_player.health().revive(maxf(1.0, value))
		elif value <= 0.0:
			push_warning("[save] santé sauvegardée invalide (%s) — pleine vie"
				% str(raw_health))
	var raw_stamina: Variant = data.get("player_stamina")
	if _player.stamina() != null and (raw_stamina is float or raw_stamina is int):
		var stamina: float = float(raw_stamina)
		if is_finite(stamina) and stamina >= 0.0:
			_player.stamina().set_current(stamina)


## §19.4 : « placer joueur au transform sûr » — APRÈS l'état du monde, AVANT
## la reprise du contrôle. Défaut S2 : sans cette étape, « Continuer »
## replaçait toujours sur la crête. Toute position absente, malformée ou hors
## monde retombe sur le point d'apparition (comportement documenté d'avant le
## schéma 3) — jamais un crash, jamais une téléportation dans le vide.
## `_last_safe` reste volontairement au spawn : si un fichier édité place le
## joueur en l'air à l'intérieur des bornes, la chute passe sous le filet
## (`FALL_LIMIT_Y`) et le sauvetage ramène à un point réellement sûr.
func _restore_player_transform(data: Dictionary) -> void:
	if _pending_spawn_applied or _player == null or not data.has("player_position"):
		return
	var restored: Vector3 = _read_saved_position(data["player_position"])
	if not _is_saved_position_safe(restored):
		push_warning("[save] position sauvegardée invalide (%s) — reprise au "
			% str(data["player_position"]) + "point d'apparition (§19.4).")
		return
	_player.velocity = Vector3.ZERO
	_player.global_position = restored
	# §20.9 : reset d'interpolation après tout repositionnement instantané.
	_player.reset_physics_interpolation()
	var yaw: Variant = data.get("player_yaw")
	if yaw is float and is_finite(yaw as float):
		var visual: Node3D = _player.get_node_or_null("VisualRoot") as Node3D
		if visual != null:
			visual.rotation.y = wrapf(yaw as float, -PI, PI)


## Lit `player_position` comme une ENTRÉE NON FIABLE (§19.2 : primitifs
## seulement ; le fichier peut être édité à la main). Tout écart de forme —
## pas un dictionnaire, composante absente ou non numérique — renvoie
## Vector3.INF, qui échoue ensuite la validation de bornes : un seul chemin
## de rejet, et JSON ne sait de toute façon pas transporter NaN/inf.
func _read_saved_position(raw: Variant) -> Vector3:
	if not (raw is Dictionary):
		return Vector3.INF
	var dict: Dictionary = raw as Dictionary
	var components: Array[float] = []
	for key: String in ["x", "y", "z"]:
		var value: Variant = dict.get(key)
		if not (value is float):
			return Vector3.INF
		components.append(value as float)
	return Vector3(components[0], components[1], components[2])


func _is_saved_position_safe(position: Vector3) -> bool:
	if not (is_finite(position.x) and is_finite(position.y) and is_finite(position.z)):
		return false
	if absf(position.x) > SAVED_POSITION_LIMIT_XZ \
			or absf(position.z) > SAVED_POSITION_LIMIT_XZ:
		return false
	return position.y > FALL_LIMIT_Y and position.y <= SAVED_POSITION_LIMIT_Y


## Le corps ne tourne jamais (PlayerController._ready) : l'orientation du
## héros vit sur VisualRoot. Enfant DIRECT du contrat de scène du joueur
## (§6.2) — s'il manque, 0 est un lacet honnête, pas une erreur.
func _player_visual_yaw() -> float:
	var visual: Node3D = _player.get_node_or_null("VisualRoot") as Node3D
	return visual.rotation.y if visual != null else 0.0


## Monture et vol libre de développement, posés dans la vallée elle-même.
##
## La monture attend au camp de départ, à portée de vue du spawn : sans cela
## il faudrait savoir qu'elle existe pour la trouver. Le vol libre, lui, n'a
## pas de position — c'est un outil, activé par sa touche.
func _spawn_travel_aids() -> void:
	_mount = Mount.new()
	_mount.name = "MontureDeVallee"
	add_child(_mount)
	# Sur la crête de départ, en contrebas du spawn (0, 32.3, 146) et dans
	# l'axe du regard : visible dès la prise de contrôle.
	_mount.global_position = Vector3(6.0, 32.3, 141.0)
	if _player == null:
		return
	_dev_fly = DevFlyMode.new()
	_dev_fly.name = "VolLibreDev"
	add_child(_dev_fly)
	_dev_fly.bind(_player)


func mount() -> Mount:
	return _mount


func dev_fly() -> DevFlyMode:
	return _dev_fly


func player() -> PlayerController:
	return _player


## Caméra de référence §21.5 (« vue camp ») — outil de capture uniquement.
func capture_camp_view() -> void:
	var camera: Camera3D = Camera3D.new()
	camera.name = "CampReferenceCamera"
	add_child(camera)
	# Revue Gate H : à (18, 14, 96) le cadre était à 45 % un talus nu et
	# des brins clippés — reculé, monté, décalé ouest.
	camera.global_position = Vector3(6.0, 22.0, 108.0)
	camera.look_at(Vector3(45.0, 6.0, 63.0), Vector3.UP)
	camera.fov = 55.0
	camera.current = true
