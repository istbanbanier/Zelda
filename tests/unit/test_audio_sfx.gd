## Régression du bug 1 de TESTS.md : « le jeu entier est muet » — zéro asset
## audio, aucun appel de lecture. Ces tests vérifient la CHAÎNE : les fichiers
## existent, l'autoload les charge, et la lecture ne casse rien même sur le
## pilote audio muet du conteneur (ISS-004 — on ne peut pas ÉCOUTER ici, on
## prouve le raccordement, pas le mixage).
extends GateTestCase

## Un son par action de §18.2 couverte par cette passe. La liste est le
## CONTRAT : retirer un fichier doit faire rougir ce test.
const EXPECTED: Array[StringName] = [
	&"hit_land", &"hit_taken", &"swing", &"refuse", &"chest_open",
	&"pickup", &"death", &"ui_move", &"ui_accept",
	# V5 — le corps du héros et la défense. Le jeu ne jouait aucun pas, aucun
	# atterrissage, aucun saut, et la déviation parfaite — le geste le plus
	# difficile — ne produisait rien. Trois variantes de pas plutôt qu'une :
	# deux pas par seconde sur un seul échantillon donnent l'effet mitraillette
	# que §18.2 interdit.
	&"step_grass_a", &"step_grass_b", &"step_grass_c",
	&"step_stone_a", &"step_stone_b",
	&"jump", &"land_soft", &"land_hard",
	&"parry", &"guard", &"weapon_break",
	# Boucle d'ambiance de la vallée : le silence entre deux actions est ce qui
	# fait « projet non fini » plus sûrement qu'un placeholder visuel.
	&"amb_valley",
]


func _audio() -> Node:
	return (Engine.get_main_loop() as SceneTree).root \
		.get_node_or_null("/root/AudioManager")


func test_every_declared_sound_exists_and_loads() -> void:
	var audio: Node = _audio()
	check_not_null(audio, "AudioManager")
	if audio == null:
		return
	for sound: StringName in EXPECTED:
		check(bool(audio.call("has_sfx", sound)),
			"le son « %s » doit exister et se charger" % String(sound))


func test_playing_a_sound_is_safe_even_headless() -> void:
	## Le conteneur n'a pas de périphérique audio : `play_sfx` doit rester
	## inoffensif — c'est la garantie qu'aucune action de gameplay ne peut
	## casser à cause d'un son.
	var audio: Node = _audio()
	if audio == null:
		return
	for sound: StringName in EXPECTED:
		audio.call("play_sfx", sound)
	audio.call("play_sfx", &"inexistant_volontaire")
	check(true, "aucune de ces lectures ne doit lever d'erreur")
	# RENDRE LE POOL COMME ON L'A TROUVÉ.
	#
	# `play_sfx()` assigne le flux à un lecteur du pool, et `AudioManager` est un
	# autoload : chaque lecteur garde SON `AudioStreamWAV` jusqu'à la fin du
	# processus. Ce cas jouant TOUS les sons déclarés, il laissait autant de
	# ressources vivantes — dont `amb_valley.wav`, ce qui faisait sortir Godot
	# sur « N ObjectDB instances were leaked » et « resources still in use ».
	#
	# Le gate voit ces deux lignes depuis la passe S1 ; il refusait donc la suite
	# entière pour un test qui ne rangeait pas derrière lui. Ce n'est ni un
	# défaut de gameplay ni une fuite du jeu : en jeu, le pool est censé rester
	# chargé. Le nettoyage n'appartient qu'au test.
	for child: Node in audio.get_children():
		var speaker: AudioStreamPlayer = child as AudioStreamPlayer
		if speaker != null:
			speaker.stop()
			speaker.stream = null


func test_the_wired_actions_reference_known_sounds() -> void:
	## Anti-dérive : les points d'appel du gameplay ne référencent que des
	## sons du contrat. Un `&"hit_lnad"` mal orthographié serait silencieux
	## en jeu — ici il rougit.
	var sources: Array[String] = [
		"res://scripts/player/player_controller.gd",
		"res://scripts/combat/attack_controller.gd",
		"res://scripts/interaction/chest.gd",
		"res://scripts/interaction/weapon_pickup.gd",
		"res://scripts/interaction/ingredient_pickup.gd",
		"res://scripts/ui/main_menu.gd",
	]
	var regex: RegEx = RegEx.new()
	regex.compile("play_sfx\",?\\s*&\"([a-z_]+)\"|_sfx\\(&\"([a-z_]+)\"")
	var found: int = 0
	for path: String in sources:
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		check_not_null(file, path)
		if file == null:
			continue
		for result: RegExMatch in regex.search_all(file.get_as_text()):
			var name: String = result.get_string(1)
			if name.is_empty():
				name = result.get_string(2)
			found += 1
			check(StringName(name) in EXPECTED,
				"« %s » (%s) doit être un son du contrat" % [name, path])
	check(found >= 8,
		"au moins huit points d'appel doivent être câblés (trouvés : %d)" % found)
