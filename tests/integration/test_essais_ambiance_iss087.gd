## ISS-087 / D-066 — LE CÂBLAGE DES ESSAIS D'AMBIANCE, MESURÉ.
##
## Quatre contrats :
##   D  — la variante committée est le TÉMOIN MUET : `_ready()` lit bien la
##        config (seam `variante_essai_appliquee`) et rien ne joue ;
##   P1 — le chemin P1 démarre `amb_p1_lit`, IDENTITÉ vérifiée par
##        `AudioManager.ambience_id()` — l'identité CONTRACTUELLE (ISS-087),
##        le chemin du flux restant un diagnostic (`_etat()`) — et la sortie
##        de scène REND, identité comprise (P1.4) ;
##   P3 — le lit `amb_p3_lit` joue et la minuterie d'événements planifie un
##        one-shot dans [20 ; 45] s ;
##   P2 — le lecteur de zone démarre le lit « ouvert », bascule par région
##        (boîte {x,z} ET anneau {ring_radius_m}), GARDE le lit courant hors
##        région, et rend tout à la sortie.
##
## Les chemins P1/P2/P3 sont exercés par le seam PUBLIC
## `demarrer_ambiance_essai()` — le fichier committé `essai_config.gd` porte
## `&"D"` et n'est PAS modifié par le test (consigne du lot : le sélecteur ne
## varie qu'entre les builds du lead).
##
## Les régions de P2 sont FABRIQUÉES par le test (ids réels, groupe réel,
## métadonnée réelle) : la présence des onze régions réelles à l'exécution est
## déjà épinglée par `test_world_v2_anchors.gd` — ce fichier-ci juge le
## LECTEUR, pas le constructeur de marqueurs.
##
## Toutes les attentes sont bornées et s'arrêtent au succès (ISS-038).
extends GateTestCase

const SHELL: String = "res://scenes/ui/GameplayShell.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"
const CONFIG: GDScript = preload("res://scripts/audio/essai_config.gd")
const AMB_P1: StringName = &"amb_p1_lit"
const AMB_P3: StringName = &"amb_p3_lit"
const AMB_OUVERT: StringName = &"amb_p2_ouvert"
const AMB_FERME: StringName = &"amb_p2_ferme"
const BUDGET_S: float = 3.0
## Une bascule de région coûte l'hystérésis (2 s) plus l'échantillonnage.
const BUDGET_REGION_S: float = 8.0
## Fenêtre pendant laquelle « rien ne doit changer » hors région : plus longue
## que l'hystérésis, pour que l'absence de bascule soit une preuve.
const TENUE_HORS_REGION_S: float = 3.0
const RECYCLAGE_AUDIO_MS: int = 400

var _world: Node3D = null
var _shell: GameplayShell = null
var _player: PlayerController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _audio() -> Node:
	return _tree().root.get_node_or_null("/root/AudioManager")


func _lecteur() -> AudioStreamPlayer:
	var audio: Node = _audio()
	if audio == null:
		return null
	return audio.get_node_or_null("Ambience") as AudioStreamPlayer


## Identité CONTRACTUELLE de l'ambiance en LECTURE (`ambience_id()`, ISS-087),
## `&""` si rien ne joue. Les gardes playing/stream disent SI, l'identité dit
## QUOI ; le chemin du flux reste dans `_etat()` en diagnostic.
func _ambiance_jouee() -> StringName:
	var audio: Node = _audio()
	var joueur: AudioStreamPlayer = _lecteur()
	if audio == null or not audio.has_method("ambience_id") \
			or joueur == null or not joueur.playing or joueur.stream == null:
		return &""
	return StringName(audio.call("ambience_id"))


func _etat() -> String:
	var audio: Node = _audio()
	var identite: String = "?"
	if audio != null and audio.has_method("ambience_id"):
		identite = String(StringName(audio.call("ambience_id")))
	var joueur: AudioStreamPlayer = _lecteur()
	if joueur == null:
		return "id=%s, aucun lecteur d'ambiance" % identite
	var flux: String = "null"
	if joueur.stream != null:
		flux = joueur.stream.resource_path
	return "id=%s, playing=%s, stream=%s" % [identite, joueur.playing, flux]


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _attendre_identite(id: StringName, budget_s: float = BUDGET_S) -> void:
	var ecoule: float = 0.0
	while ecoule <= budget_s:
		if _ambiance_jouee() == id:
			return
		await _tree().process_frame
		ecoule += _tree().root.get_process_delta_time()


func _attendre_game_time(duree_s: float) -> void:
	var ecoule: float = 0.0
	while ecoule < duree_s:
		await _tree().process_frame
		ecoule += _tree().root.get_process_delta_time()


func _attendre_liberation() -> void:
	var ecoule: float = 0.0
	while ecoule <= BUDGET_S:
		var joueur: AudioStreamPlayer = _lecteur()
		if joueur == null or (not joueur.playing and joueur.stream == null):
			return
		await _tree().process_frame
		ecoule += _tree().root.get_process_delta_time()


## Un test rend le processus tel qu'il l'a trouvé — même discipline et mêmes
## raisons que `test_ambience_ownership_iss086.gd` (fenêtre de recyclage du
## serveur audio en temps RÉEL, bornée).
func _rendre_le_silence() -> void:
	var audio: Node = _audio()
	if audio != null and audio.has_method("stop_ambience"):
		audio.call("stop_ambience")
	var joueur: AudioStreamPlayer = _lecteur()
	if joueur != null:
		joueur.stream = null
	await _settle(2)
	var depart: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - depart < RECYCLAGE_AUDIO_MS:
		await _tree().process_frame


func _monter(avec_joueur: bool) -> void:
	_world = Node3D.new()
	_world.name = "MondeEssaiAmbiance"
	_tree().root.add_child(_world)
	if avec_joueur:
		# Sol INFINI : le test P2 téléporte le joueur jusqu'au rayon de
		# l'anneau (250 m) — une dalle finie l'aurait laissé tomber.
		var sol: StaticBody3D = StaticBody3D.new()
		sol.name = "Sol"
		sol.collision_layer = 1
		var forme: CollisionShape3D = CollisionShape3D.new()
		forme.shape = WorldBoundaryShape3D.new()
		sol.add_child(forme)
		_world.add_child(sol)
		_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
		_player.position = Vector3(0, 0.2, 0)
		_world.add_child(_player)
	_shell = (load(SHELL) as PackedScene).instantiate() as GameplayShell
	_world.add_child(_shell)
	await _settle(4)


func _demonter() -> void:
	if _tree().paused:
		_tree().paused = false
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_shell = null
	_player = null
	await _settle(2)


## Région FABRIQUÉE : id réel, groupe réel, même forme de métadonnée que
## `world_v2_markers_builder.gd` (un TABLEAU de dictionnaires).
func _fabriquer_region(id: StringName, bornes: Array) -> void:
	var node: Node3D = Node3D.new()
	node.name = String(id)
	node.add_to_group(&"world_v2_regions")
	node.set_meta(&"bounds", bornes)
	_world.add_child(node)


## ---------------------------------------------------------------------------
## D — le témoin committé est muet, et le câblage de `_ready()` est RÉEL
## ---------------------------------------------------------------------------
func test_d_temoin_committe_muet() -> void:
	check_equal(CONFIG.VARIANTE, &"D",
		"D0 — la variante COMMITTÉE est le témoin &\"D\" (le lead seul la fait varier)")
	await _rendre_le_silence()
	await _monter(false)
	# Le seam prouve que `_ready()` a LU la config et dispatché — sans lui,
	# « rien ne joue » serait vrai même si le câblage n'existait pas.
	check_equal(_shell.variante_essai_appliquee(), &"D",
		"D1 — _ready() a appliqué la variante committée")
	check(not bool(_audio().call("is_ambience_playing")),
		"D2 — témoin : aucune ambiance ne joue après _ready (%s)" % _etat())
	await _demonter()
	await _rendre_le_silence()


## ---------------------------------------------------------------------------
## P1 — démarre, identité vérifiée, et la sortie de scène REND (ISS-086)
## ---------------------------------------------------------------------------
func test_p1_demarre_et_rend_a_la_sortie() -> void:
	await _rendre_le_silence()
	await _monter(false)
	_shell.demarrer_ambiance_essai(&"P1")
	await _attendre_identite(AMB_P1)
	check_equal(_ambiance_jouee(), AMB_P1,
		"P1.1 — le lit P1 joue et c'est BIEN lui (%s)" % _etat())
	# `_lecteur()` peut être nul si `play_ambience` n'a jamais couru : un échec
	# de P1.1 doit rester un ROUGE propre, pas un avortement de script.
	var joueur_p1: AudioStreamPlayer = _lecteur()
	var wav: AudioStreamWAV = null
	if joueur_p1 != null:
		wav = joueur_p1.stream as AudioStreamWAV
	check(wav != null and wav.loop_mode != AudioStreamWAV.LOOP_DISABLED,
		"P1.2 — le flux BOUCLE (la fin naturelle des 30 s ne passera pas pour "
		+ "une libération)")
	await _demonter()
	await _attendre_liberation()
	var joueur: AudioStreamPlayer = _lecteur()
	check(joueur != null and not joueur.playing and joueur.stream == null,
		"P1.3 — la coquille sortie, l'ambiance est RENDUE : _exit_tree a fait "
		+ "son travail (%s)" % _etat())
	# L'IDENTITÉ MEURT AVEC L'AMBIANCE : un `_ambience_id` survivant ferait
	# passer un silence pour la bonne ambiance. C'est l'assertion qui rougit
	# si le vidage de `_release_ambience` disparaît (sabotage mesuré).
	var audio_p1: Node = _audio()
	if audio_p1 != null and audio_p1.has_method("ambience_id"):
		check_equal(StringName(audio_p1.call("ambience_id")), &"",
			"P1.4 — l'identité est vidée avec l'ambiance rendue (%s)" % _etat())
	else:
		check(false, "P1.4 — ambience_id() absent de l'AudioManager")
	await _rendre_le_silence()


## ---------------------------------------------------------------------------
## P3 — lit + minuterie d'événements planifiée dans [20 ; 45] s
## ---------------------------------------------------------------------------
func test_p3_lit_et_minuterie_dans_les_bornes() -> void:
	await _rendre_le_silence()
	await _monter(false)
	_shell.demarrer_ambiance_essai(&"P3")
	await _attendre_identite(AMB_P3)
	check_equal(_ambiance_jouee(), AMB_P3,
		"P3.1 — le lit P3 joue et c'est bien lui (%s)" % _etat())
	var minuterie: Timer = _shell.minuterie_evenements_ambiance()
	check_not_null(minuterie, "P3.2 — la minuterie d'événements existe")
	if minuterie != null:
		check(minuterie.one_shot, "P3.3 — one-shot re-armé, jamais de _process")
		check(not minuterie.is_stopped(), "P3.4 — elle court")
		check(minuterie.wait_time >= 20.0 and minuterie.wait_time <= 45.0,
			"P3.5 — l'intervalle est tiré dans [20 ; 45] s (%.2f)"
			% minuterie.wait_time)
	await _demonter()
	await _attendre_liberation()
	var joueur: AudioStreamPlayer = _lecteur()
	check(joueur != null and not joueur.playing and joueur.stream == null,
		"P3.6 — sortie de scène : le lit P3 est rendu (%s)" % _etat())
	await _rendre_le_silence()


## ---------------------------------------------------------------------------
## P2 — lit de départ, bascule par boîte, tenue hors région, bascule par anneau
## ---------------------------------------------------------------------------
func test_p2_bascules_par_region_et_tenue_hors_region() -> void:
	await _rendre_le_silence()
	await _monter(true)
	# Trois régions fabriquées : deux boîtes (une « fermé », une « ouvert »)
	# et l'ANNEAU r11 — la forme que l'inventaire §5 interdit d'oublier.
	# Le spawn (0, 0) n'appartient à aucune d'elles.
	_fabriquer_region(&"r06_bois_du_levant",
		[{"x": [64, 200], "z": [36, 200]}])
	_fabriquer_region(&"r07_hauteurs_de_l_orient",
		[{"x": [-200, -100], "z": [-200, -100]}])
	_fabriquer_region(&"r11_anneau_frontalier",
		[{"ring_radius_m": [235, 292]}])
	_shell.demarrer_ambiance_essai(&"P2")
	await _attendre_identite(AMB_OUVERT)
	check_equal(_ambiance_jouee(), AMB_OUVERT,
		"P2.1 — hors de toute région, le lit de DÉPART « ouvert » joue — "
		+ "jamais le silence (%s)" % _etat())
	check_not_null(_shell.get_node_or_null("LecteurZonesP2"),
		"P2.2 — le lecteur de zone est un enfant de la coquille")
	if _player == null:
		check(false, "P2.0 — montage : joueur absent, la suite serait vide")
		await _demonter()
		await _rendre_le_silence()
		return

	# Boîte {x,z} : entrer dans le bois (fermé) doit basculer après hystérésis.
	_player.global_position = Vector3(100.0, 0.2, 100.0)
	await _attendre_identite(AMB_FERME, BUDGET_REGION_S)
	check_equal(_ambiance_jouee(), AMB_FERME,
		"P2.3 — dans la boîte r06 (bois = fermé), bascule après l'hystérésis "
		+ "(%s)" % _etat())

	# Hors région (19,3 % du monde) : GARDER le lit courant, jamais couper.
	_player.global_position = Vector3(0.0, 0.2, -300.0)
	await _attendre_game_time(TENUE_HORS_REGION_S)
	check_equal(_ambiance_jouee(), AMB_FERME,
		"P2.4 — hors de toute région, le lit courant est GARDÉ (%s)" % _etat())

	# Seconde boîte, retour vers « ouvert » : la bascule marche dans les deux sens.
	_player.global_position = Vector3(-150.0, 0.2, -150.0)
	await _attendre_identite(AMB_OUVERT, BUDGET_REGION_S)
	check_equal(_ambiance_jouee(), AMB_OUVERT,
		"P2.5 — dans la boîte r07 (hauteurs = ouvert), bascule inverse (%s)"
		% _etat())

	# ANNEAU {ring_radius_m} : rayon 250 m, dans [235 ; 292] — la forme de r11.
	_player.global_position = Vector3(250.0, 0.2, 0.0)
	await _attendre_identite(AMB_FERME, BUDGET_REGION_S)
	check_equal(_ambiance_jouee(), AMB_FERME,
		"P2.6 — sur l'anneau frontalier (forme ring_radius_m), bascule vers "
		+ "« fermé » : la bordure n'est pas muette (%s)" % _etat())

	await _demonter()
	await _attendre_liberation()
	var joueur: AudioStreamPlayer = _lecteur()
	check(joueur != null and not joueur.playing and joueur.stream == null,
		"P2.7 — sortie de scène : le lecteur de zone a rendu son lit (%s)"
		% _etat())
	await _rendre_le_silence()
