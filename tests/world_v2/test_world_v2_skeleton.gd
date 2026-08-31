## World V2 — le SQUELETTE prouve l'architecture du monde désormais jouable.
##
## Ce que ce fichier tient, et pourquoi chaque garde existe :
##   - Boot → MainMenu → Nouvelle partie/Continuer mène désormais à V2 ;
##   - cette unique référence d'entrée est autorisée dans le menu, sans faire
##     dépendre les bâtisseurs V1 et V2 les uns des autres ;
##   - le VRAI joueur apparaît dans V2, sur un sol qui PORTE (collision réelle,
##     pas une promesse) ;
##   - la coquille de jeu (HUD) se raccorde et son « Réessayer » reste en V2 ;
##   - le squelette se ferme proprement (delta de racine balayé, rien ne fuit) ;
##   - la sauvegarde V1 (`slot0`) n'est JAMAIS modifiée par un passage en V2 —
##     comparaison d'octets, pas d'intention.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const BOOTSTRAP_SCENE: String = "res://scenes/world_v2/WorldV2Bootstrap.tscn"
## Cible de « Réessayer » attendue sur la coquille embarquée dans V2.
const EXPECTED_SHELL_TARGET: String = "res://scenes/world_v2/WorldV2.tscn"
## Altitude du sol au spawn : l'ancre §3.3 (0, 24, 170) — le pad de spawn de
## la fonction de hauteur V2.1 garantit exactement 24, comme le faisait le
## dessus de la dalle temporaire V2.0. Le contrat (le sol PORTE le joueur à
## cette altitude) est inchangé ; seul le porteur a changé — c'est le
## remplacement annoncé par l'étiquette du sol temporaire.
const TEMP_GROUND_TOP_Y: float = 24.0
## Assez de frames physiques pour qu'une chute de ~0,4 m se pose et se stabilise.
const SETTLE_PHYSICS_FRAMES: int = 40


func test_la_v2_est_le_flux_normal() -> void:
	var main_scene: String = String(ProjectSettings.get_setting(
		"application/run/main_scene", ""))
	check_equal(main_scene, "res://scenes/boot/Boot.tscn",
		"le jeu démarre toujours sur Boot")

	var boot_script: Script = load("res://scripts/core/boot.gd") as Script
	check_not_null(boot_script, "script de Boot lisible")
	var boot_constants: Dictionary = boot_script.get_script_constant_map()
	check_equal(String(boot_constants.get("MAIN_MENU", "")),
		"res://scenes/ui/MainMenu.tscn", "Boot enchaîne toujours sur le menu")

	var menu_script: Script = load("res://scripts/ui/main_menu.gd") as Script
	check_not_null(menu_script, "script du menu lisible")
	var menu_constants: Dictionary = menu_script.get_script_constant_map()
	var menu_target: String = String(menu_constants.get("WORLD_SCENE", ""))
	check_equal(menu_target, WORLD_V2_SCENE,
		"« Continuer »/« Nouvelle partie » mènent au monde V2")
	check(menu_target.contains("world_v2"),
		"le flux normal référence explicitement V2")


## Balayage d'isolation, dans LES DEUX directions. Un seul fichier fautif rend
## le nom exact — pas un compte muet.
func test_aucune_reference_croisee_interdite() -> void:
	# Direction 1 : hors des points d'entrée NOMMÉS, rien de V1 (scripts/ et
	# scenes/ hors world_v2) ne parle de V2.
	#
	# LA LISTE S'EST ALLONGÉE, ET C'EST UN CHANGEMENT DE CONTRAT ASSUMÉ.
	# Quand ce balayage a été écrit, V2 était un squelette isolé construit à
	# côté de V1 : seul le menu avait le droit de le connaître. Depuis, V2 EST
	# le monde de la campagne — le menu n'ouvre plus V1 du tout. Les chemins de
	# RETOUR de la campagne doivent donc viser V2, sans quoi le joueur est
	# déposé dans un monde qu'il n'a jamais traversé et dont rien ne le ramène.
	# C'est exactement ISS-073, et le laisser interdit aurait figé le défaut.
	#
	# La liste reste une ÉNUMÉRATION, jamais un motif : un quatrième fichier
	# qui se mettrait à parler de V2 rougit toujours, et devra se justifier
	# comme ces trois-là.
	var v1_entry_points: Array[String] = [
		"res://scripts/ui/main_menu.gd",         # « Nouvelle partie »/« Continuer »
		"res://scripts/ui/victory_screen.gd",    # « Continuer l'exploration »
		"res://scripts/world/citadel_vestibule.gd",  # la porte de SORTIE
		# Les deux suivants sont le CÂBLAGE D'AMBIANCE des essais ISS-087
		# (branche expérimentale) : la coquille est le porteur désigné par
		# docs/audio/PROTOTYPES_AMBIANCE.md §2 — elle démarre et REND
		# l'ambiance (contrat ISS-086) et, en variante P2, instancie le
		# lecteur de zone dont tout l'objet est de lire les régions du monde
		# V2 (groupe world_v2_regions). Le couplage est le BUT, pas un
		# accident ; il est testé par test_essais_ambiance_iss087.gd, et un
		# SIXIÈME fichier qui parlerait de V2 rougit toujours.
		"res://scripts/ui/gameplay_shell.gd",    # porteur d'ambiance (essais)
		"res://scripts/audio/lecteur_zones_p2.gd",  # lecteur de régions P2
	]
	var v1_offenders: Array[String] = []
	var v1_files: Array[String] = []
	_walk_files("res://scripts", ["gd", "tscn", "tres"], v1_files)
	_walk_files("res://scenes", ["gd", "tscn", "tres"], v1_files)
	for path: String in v1_files:
		if path.contains("world_v2"):
			continue
		if v1_entry_points.has(path):
			continue
		if _file_contains(path, ["world_v2"]) != "":
			v1_offenders.append(path)
	check(v1_offenders.is_empty(),
		"hors des points d'entrée nommés, aucun fichier V1 ne référence "
		+ "world_v2 — fautifs : %s" % ", ".join(v1_offenders))
	# Et l'inverse, sinon la liste pourrait grandir sans que rien ne le voie :
	# chacun des trois DOIT réellement viser V2. Un point d'entrée exempté qui
	# ne pointe plus vers V2 est une exemption devenue mensongère.
	for entry: String in v1_entry_points:
		check(_file_contains(entry, ["world_v2"]) != "",
			"le point d'entrée %s vise bien World V2 — sinon son exemption "
			% entry.get_file() + "ne protège plus rien")

	# Direction 2 : rien de V2 ne consomme le CONTENU SPATIAL V1 (sa scène de
	# vallée, ses bâtisseurs). Les interfaces protégées (Player, coquille,
	# autoloads) restent permises — c'est tout le contrat DUAL_WORLD.
	# Aiguilles assemblées pour que ce test ne se dénonce pas lui-même.
	var forbidden: Array[String] = [
		"scenes/world/" + "valley",
		"scripts/world/" + "valley",
		"Valley" + "World",
		"valley_" + "terrain",
	]
	var v2_offenders: Array[String] = []
	var v2_files: Array[String] = []
	_walk_files("res://scripts/world_v2", ["gd"], v2_files)
	_walk_files("res://scenes/world_v2", ["tscn"], v2_files)
	check(v2_files.size() >= 4,
		"le balayage V2 voit bien les fichiers du squelette (%d)" % v2_files.size())
	for path: String in v2_files:
		var needle: String = _file_contains(path, forbidden)
		if needle != "":
			v2_offenders.append("%s (« %s »)" % [path, needle])
	check(v2_offenders.is_empty(),
		"aucun fichier V2 ne référence le contenu spatial V1 — fautifs : %s"
			% ", ".join(v2_offenders))


## Le cœur de la phase : V2 se charge SÉPARÉMENT, porte le vrai joueur sur un
## sol réel, raccorde la coquille, se ferme proprement — et laisse `slot0`
## intact à l'OCTET près.
func test_le_squelette_porte_le_vrai_joueur_sans_toucher_la_sauvegarde() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	check_not_null(loop, "SceneTree disponible")
	remember_saves()
	remember_root()

	# Une sauvegarde SENTINELLE écrite par le chemin pavé : si un code V2
	# écrivait dans slot0, la comparaison d'octets le dénoncerait.
	var save_system: Node = loop.root.get_node_or_null("/root/SaveSystem")
	check_not_null(save_system, "SaveSystem présent")
	var sentinel: Dictionary = {
		"schema": 4, "checkpoint": "valley.camp.start",
		"sentinelle_v2_0": "ne_pas_toucher",
	}
	check(bool(save_system.call("save_slot", "slot0", sentinel)),
		"sauvegarde sentinelle écrite")
	var slot_path: String = String(save_system.call("slot_path", "slot0"))
	var bytes_before: PackedByteArray = FileAccess.get_file_as_bytes(slot_path)
	check(bytes_before.size() > 0, "la sentinelle existe sur disque")

	var packed: PackedScene = load(WORLD_V2_SCENE) as PackedScene
	check_not_null(packed, "la scène du squelette V2 se charge")
	var world: Node3D = packed.instantiate() as Node3D
	check_not_null(world, "le squelette s'instancie")
	loop.root.add_child(world)
	await loop.process_frame

	# --- Architecture : identité de monde et conteneurs.
	check_equal(world.get("WORLD_ID"), WorldIds.V2_WORLD_ID,
		"la racine V2 se réclame du monde V2")
	var missing: Array[String] = world.call("containers_missing") as Array[String]
	check(missing.is_empty(),
		"les conteneurs de l'architecture sont tous là — absents : %s"
			% ", ".join(missing))

	# --- Le VRAI joueur, pas un substitut.
	var players: Array[Node] = loop.get_nodes_in_group(&"player")
	check_equal(players.size(), 1, "exactement un joueur dans l'arbre")
	var player: CharacterBody3D = players[0] as CharacterBody3D
	check_not_null(player, "le joueur est un CharacterBody3D")
	check(player is PlayerController,
		"c'est le PlayerController réel du jeu, pas une doublure")
	check(player.get_node_or_null("Components/StaminaComponent") != null,
		"les composants protégés sont embarqués (endurance)")
	check(player.get_node_or_null("CameraRig") != null,
		"la caméra du jeu est embarquée dans le joueur")

	# --- Sol : la sonde touche le sol temporaire NOMMÉ, sous le spawn.
	await loop.physics_frame
	var hit: Dictionary = world.call("probe_ground_below_spawn") as Dictionary
	check(not hit.is_empty(), "un sol existe sous le spawn (couche World Static)")
	if not hit.is_empty():
		var ground: Node = hit["collider"] as Node
		# V2.0 exigeait ici le sol TEMPORAIRE nommé ; V2.1 l'a remplacé par la
		# vallée whitebox — l'assertion suit le contrat, renforcée : le sol
		# est un CHUNK de terrain V2 (groupe + nom de grille), plus une dalle.
		check(ground.is_in_group(&"world_v2_terrain"),
			"le sol touché est un chunk du terrain V2 (obtenu : %s)" % ground.name)
		check(String(ground.name).begins_with("c"),
			"le chunk porte son nom de grille (obtenu : %s)" % ground.name)

	# --- Le joueur SE POSE : la collision porte, la position se stabilise.
	var frames: int = 0
	while frames < SETTLE_PHYSICS_FRAMES:
		await loop.physics_frame
		frames += 1
	var rested_y: float = player.global_position.y
	check(absf(rested_y - TEMP_GROUND_TOP_Y) <= 0.6,
		"le joueur repose sur le dessus de la dalle (y=%.2f, attendu ~%.1f)"
			% [rested_y, TEMP_GROUND_TOP_Y])
	await loop.physics_frame
	await loop.physics_frame
	check(absf(player.global_position.y - rested_y) <= 0.05,
		"la position verticale est STABLE — le sol porte, il n'absorbe pas")
	var spawn: Vector3 = world.call("spawn_position") as Vector3
	check(Vector2(player.global_position.x - spawn.x,
		player.global_position.z - spawn.z).length() <= 0.5,
		"le joueur est resté au point d'apparition du squelette")

	# --- La coquille de jeu se raccorde, et son « Réessayer » RESTE en V2.
	var shell: CanvasLayer = world.get_node_or_null("GameplayShell") as CanvasLayer
	check_not_null(shell, "la GameplayShell réelle est raccordée")
	if shell != null:
		check_equal(String(shell.get("world_scene_path")), EXPECTED_SHELL_TARGET,
			"le « Réessayer » de la coquille cible V2 — jamais le monde V1")

	# --- Fermeture propre : le delta de racine est balayé, rien ne survit.
	var clean: bool = await restore_root()
	check(clean, "fermeture propre du squelette — %s" % restore_root_reason())
	check(loop.get_nodes_in_group(&"player").is_empty(),
		"aucun joueur ne survit à la fermeture")

	# --- La sauvegarde V1 n'a pas bougé d'un octet.
	var bytes_after: PackedByteArray = FileAccess.get_file_as_bytes(slot_path)
	check(bytes_after == bytes_before,
		"slot0 est identique à l'octet près après le passage en V2")
	restore_saves()


## L'entrée développeur charge V2 par la même porte que tout le monde
## (SceneFlow), et REFUSE de démarrer sur une carte directrice invalide — le
## refus est le comportement, pas un accident.
func test_l_entree_developpeur_charge_v2_separement() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	check_not_null(loop, "SceneTree disponible")
	remember_saves()
	remember_root()

	var packed: PackedScene = load(BOOTSTRAP_SCENE) as PackedScene
	check_not_null(packed, "la scène d'amorce V2 se charge")
	var bootstrap: Node = packed.instantiate()
	loop.root.add_child(bootstrap)

	var appeared: bool = await await_scene("WorldV2Root")
	check(appeared, "l'amorce mène au monde V2 via SceneFlow")
	var idle: bool = await await_flow_idle()
	check(idle, "SceneFlow revient au repos après la transition")

	var clean: bool = await restore_root()
	check(clean, "fermeture propre après l'amorce — %s" % restore_root_reason())
	restore_saves()


## -- outillage de balayage ---------------------------------------------------

func _walk_files(root: String, extensions: Array[String],
		out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(root)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full: String = root.path_join(entry)
		if dir.current_is_dir():
			_walk_files(full, extensions, out)
		else:
			for wanted: String in extensions:
				if entry.ends_with(".%s" % wanted):
					out.append(full)
					break
		entry = dir.get_next()
	dir.list_dir_end()


## Rend la première aiguille trouvée dans le fichier, ou "" si aucune.
func _file_contains(path: String, needles: Array[String]) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	for needle: String in needles:
		if text.contains(needle):
			return needle
	return ""
