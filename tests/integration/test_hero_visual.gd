## ART-Q1 — héros riggé vertical : bibliothèque cuite (12 états, bouclage
## explicite, audit de root motion), scène HeroVisual (squelette + clips +
## sockets main/dos/arc), montage RÉEL dans le joueur (graybox masqué,
## capsule intouchée, arme dans la main) et pilotage des clips par l'état
## gameplay. Tout est mesuré sur les vraies ressources importées.
extends GateTestCase

const LIBRARY: String = "res://assets/animations/AL_HeroStates.res"
const AUDIT: String = "res://evidence/artQ1/hero_anim_audit.json"
const ANIM_SET: String = "res://resources/characters/hero_anim_set.tres"
const PLAYER: String = "res://scenes/player/Player.tscn"

const LOOPING: Array[StringName] = [&"Idle", &"Walk", &"Jog_Fwd", &"Sprint",
	&"Jump"]
const ONE_SHOT: Array[StringName] = [&"Jump_Start", &"Jump_Land", &"Roll",
	&"Sword_Regular_A", &"Sword_Heavy_Combo", &"Hit_Chest", &"Death01",
	# V4 lot 14 — états optionnels, tous one-shot :
	&"ClimbUp_1m", &"Interact", &"Consume"]

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _setup_player() -> void:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = Vector3(0, 0.1, 0)
	_world.add_child(_player)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	await _settle(3)


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	await _settle(1)


func _hero_visual() -> CharacterVisual:
	return _player.get_node("VisualRoot/CharacterVisual") as CharacterVisual


func test_the_baked_library_has_the_twelve_states_with_explicit_loops() -> void:
	## La bibliothèque cuite contient les 12 clips, et le bouclage est
	## EXPLICITE : les boucles de locomotion bouclent, les one-shots jamais
	## (une mort qui boucle est un bug visible).
	var library: AnimationLibrary = load(LIBRARY) as AnimationLibrary
	check(library != null, "AL_HeroStates.res charge")
	check_equal(library.get_animation_list().size(), 15,
		"quinze clips exactement (douze obligatoires + trois optionnels lot 14)")
	for clip: StringName in LOOPING:
		check(library.has_animation(clip), "clip présent : %s" % String(clip))
		check_equal(int(library.get_animation(clip).loop_mode),
			int(Animation.LOOP_LINEAR), "%s BOUCLE" % String(clip))
	for clip: StringName in ONE_SHOT:
		check(library.has_animation(clip), "clip présent : %s" % String(clip))
		check_equal(int(library.get_animation(clip).loop_mode),
			int(Animation.LOOP_NONE), "%s ne boucle PAS" % String(clip))


func test_the_root_motion_audit_proves_in_place_loops() -> void:
	## L'audit chiffré existe (preuve « neutralisé et documenté par
	## animation ») et les BOUCLES se referment : dérive pelvis ≈ 0. Aucun
	## clip ne porte de piste de position sur un nœud (root motion interdit).
	check(FileAccess.file_exists(AUDIT), "l'audit JSON est dans evidence/artQ1/")
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(AUDIT))
	var clips: Dictionary = (parsed as Dictionary).get("clips", {})
	check_equal(clips.size(), 15, "quinze clips audités (12 + 3 optionnels)")
	for clip: Variant in clips:
		var measures: Dictionary = clips[clip]
		check(not bool(measures.get("node_motion", true)),
			"%s : aucune piste de position de NŒUD" % String(clip))
		if bool(measures.get("loop", false)):
			check(float(measures.get("drift_m", 1.0)) <= 0.05,
				"%s : boucle refermée (dérive %.4f m)"
				% [String(clip), float(measures.get("drift_m", 1.0))])


func test_the_hero_scene_mounts_skeleton_clips_and_the_three_sockets() -> void:
	## HeroVisual.tscn : squelette 65 os, AnimationPlayer couvrant les 12
	## états du CharacterAnimSet, et les TROIS sockets de l'ordre (main
	## d'arme, dos, arc) attachés aux bons os.
	var hero: CharacterModelSockets = (load("res://scenes/characters/HeroVisual.tscn")
		as PackedScene).instantiate() as CharacterModelSockets
	_tree().root.add_child(hero)
	await _settle(1)
	var skeleton: Skeleton3D = hero.find_children("*", "Skeleton3D", true,
		false)[0] as Skeleton3D
	check_equal(skeleton.get_bone_count(), 65, "squelette UAL complet")
	var player: AnimationPlayer = hero.get_node("AnimationPlayer") as AnimationPlayer
	var anim_set: CharacterAnimSet = load(ANIM_SET) as CharacterAnimSet
	check_equal(anim_set.undeclared_states().size(), 0,
		"les 12 états sont déclarés dans la correspondance")
	check_equal(anim_set.missing_clips(player).size(), 0,
		"chaque clip déclaré EXISTE dans le lecteur de la scène")
	for expected: Array in [["SOCKET_HAND_R", "hand_r"],
			["SOCKET_BACK", "spine_03"], ["SOCKET_BOW", "hand_l"]]:
		var socket: BoneAttachment3D = hero.socket(String(expected[0]))
		check(socket != null, "socket présent : %s" % String(expected[0]))
		if socket != null:
			check_equal(socket.bone_name, String(expected[1]),
				"%s sur l'os %s" % [String(expected[0]), String(expected[1])])
	hero.get_parent().remove_child(hero)
	hero.free()


func test_the_player_mounts_the_hero_hides_graybox_and_keeps_the_capsule() -> void:
	## Dans le VRAI Player.tscn : le modèle monte (plus de repli), le graybox
	## se masque, la capsule de collision reste STRICTEMENT identique, et
	## l'arme de départ vit dans la MAIN (BoneAttachment3D hand_r).
	await _setup_player()
	var visual: CharacterVisual = _hero_visual()
	check(not visual.is_fallback_active(), "le modèle héros est monté")
	check_equal(visual.validate().size(), 0,
		"validate() : aucun problème de branchement")
	check(not (_player.get_node("VisualRoot/BodyMesh") as MeshInstance3D).visible,
		"graybox corps masqué")
	check(not (_player.get_node("VisualRoot/NoseMesh") as MeshInstance3D).visible,
		"graybox nez masqué")
	var capsule: CapsuleShape3D = (_player.get_node("CollisionShape3D")
		as CollisionShape3D).shape as CapsuleShape3D
	check(capsule != null and absf(capsule.height - 1.8) < 0.001,
		"la capsule de collision reste l'autorité (1,8 m, intouchée)")
	var socket: BoneAttachment3D = visual.weapon_socket()
	check(socket != null and socket.bone_name == "hand_r",
		"le socket d'arme est la main droite du squelette")
	check_equal(socket.name, "SOCKET_HAND_R",
		"…et c'est LE socket du modèle, pas un doublon empilé")
	var pivot: Node3D = _player.find_children("WeaponPivot", "Node3D", true,
		false)[0] as Node3D
	check_equal(pivot.get_parent(), socket,
		"le pivot d'arme vit dans la main — l'épée suit les clips")
	await _teardown()


func test_the_driver_follows_gameplay_states_without_touching_them() -> void:
	## Le pilote traduit l'état RÉEL : repos → Idle ; course → Jog_Fwd ;
	## sprint → Sprint. Sens unique : piloter l'animation n'a modifié ni le
	## mode ni la vitesse du contrôleur.
	await _setup_player()
	var visual: CharacterVisual = _hero_visual()
	var player_anim: AnimationPlayer = visual.find_children("*",
		"AnimationPlayer", true, false)[0] as AnimationPlayer
	# Le spawn tombe de 10 cm : réception (land) tenue 0,3 s — laisser
	# passer la retenue avant de juger le repos.
	await _settle(30)
	check_equal(String(visual.current_state()), "idle", "au repos : état idle")
	check_equal(player_anim.current_animation, "Idle", "…clip Idle en lecture")

	_intent.move = Vector2(1.0, 0.0)
	await _settle(30)
	check_equal(String(visual.current_state()), "run", "course : état run")
	check_equal(player_anim.current_animation, "Jog_Fwd", "…clip Jog_Fwd")

	_intent.sprint_held = true
	await _settle(30)
	check_equal(String(visual.current_state()), "sprint", "sprint : état sprint")
	check_equal(player_anim.current_animation, "Sprint", "…clip Sprint")
	check_equal(int(_player.mode()), int(PlayerController.Mode.LOCOMOTION),
		"le pilote n'a PAS touché le mode gameplay")
	_intent.move = Vector2.ZERO
	_intent.sprint_held = false
	await _teardown()


func test_the_optional_gestures_play_and_yield_to_movement() -> void:
	## V4 lot 14 : les états OPTIONNELS existent (mantle/interact/consume
	## déclarés ET cuits — ClimbUp_1m, Interact, Consume, in-place audités),
	## le geste de consommation se joue à l'arrêt, et BOUGER l'annule — le
	## contrôle prime toujours sur la pose (§7.18).
	await _setup_player()
	var visual: CharacterVisual = _hero_visual()
	var player_anim: AnimationPlayer = visual.find_children("*",
		"AnimationPlayer", true, false)[0] as AnimationPlayer
	for clip: StringName in [&"ClimbUp_1m", &"Interact", &"Consume"]:
		check(player_anim.has_animation(clip),
			"clip optionnel cuit dans la bibliothèque : %s" % String(clip))
	await _settle(30)
	# Plat en réserve, puis consommation par le vrai chemin (plat rapide).
	_player.inventory().add_meal({"valid": true, "name": "Test", "heal": 2.0})
	_intent.meal_pressed = true
	await _settle(2)
	_intent.meal_pressed = false
	check_equal(String(visual.current_state()), "consume",
		"le geste de consommation se joue")
	check_equal(player_anim.current_animation, "Consume", "…clip Consume")
	# Bouger annule le geste : la locomotion reprend l'autorité.
	_intent.move = Vector2(1.0, 0.0)
	await _settle(25)
	check(String(visual.current_state()) in ["walk", "run"],
		"bouger annule le geste (%s)" % String(visual.current_state()))
	_intent.move = Vector2.ZERO
	await _teardown()


func test_dead_players_play_death_once_and_stay_down() -> void:
	## La mort joue Death01 UNE fois (pas de boucle macabre) et la racine
	## visuelle ne bascule PAS en plus du clip — le clip couche le corps.
	await _setup_player()
	var visual: CharacterVisual = _hero_visual()
	_player.health().take_damage(_damage_event(999.0))
	await _settle(4)
	check_equal(int(_player.mode()), int(PlayerController.Mode.DEAD),
		"préalable : le joueur est mort")
	check_equal(String(visual.current_state()), "death", "état visuel : death")
	var root: Node3D = _player.get_node("VisualRoot") as Node3D
	check(absf(root.rotation.x) < 0.01,
		"la racine ne bascule pas — Death01 couche le corps, pas un tilt en plus")
	await _teardown()


func _damage_event(amount: float) -> DamageEvent:
	var event: DamageEvent = DamageEvent.new()
	event.amount = amount
	return event


func test_the_turquoise_tint_touches_the_outfit_and_never_the_skin() -> void:
	## §7.11 : « le turquoise relie le héros à la citadelle ». V4 lot 13 : la
	## teinte GLOBALE d'ART-Q6 est remplacée par une texture DÉRIVÉE où seule
	## la capuche est turquoise — les surfaces MI_Ranger portent la
	## substitution (albedo_color BLANC : plus aucune multiplication), les
	## surfaces MI_Regular_Male (peau) restent VIERGES.
	var hero: CharacterModelSockets = (load("res://scenes/characters/HeroVisual.tscn")
		as PackedScene).instantiate() as CharacterModelSockets
	_tree().root.add_child(hero)
	await _settle(1)
	var substituted: int = 0
	var skin_untouched: bool = true
	for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		var surfaces: int = mesh.mesh.get_surface_count() if mesh.mesh != null else 0
		for surface: int in range(surfaces):
			var override: BaseMaterial3D = mesh.get_surface_override_material(
				surface) as BaseMaterial3D
			var base: BaseMaterial3D = (mesh.mesh.surface_get_material(surface)
				if mesh.mesh != null else null) as BaseMaterial3D
			if base != null and base.resource_name == "MI_Regular_Male" \
					and override != null:
				skin_untouched = false
			if override != null and override.albedo_texture != null \
					and override.albedo_texture.resource_path \
					.ends_with("T_Ranger_Hero_BaseColor.png"):
				substituted += 1
				check(override.albedo_color.is_equal_approx(Color.WHITE),
					"substitution sans teinte résiduelle : couleur blanche")
	check(substituted >= 1,
		"la tenue porte la texture dérivée à capuche turquoise (%d)" % substituted)
	check(skin_untouched, "la peau (MI_Regular_Male) n'est JAMAIS teintée")
	hero.get_parent().remove_child(hero)
	hero.queue_free()
	await _settle(2)
