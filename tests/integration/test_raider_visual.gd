## ART-Q2 — pillard animé sur la VRAIE IA : bibliothèque cuite dédiée,
## trois variantes de faction réellement teintées, montage dans la scène
## RaiderRed réelle (graybox masqué, gourdin dans la main animée, capsule
## intouchée) et clips pilotés par la machine d'états de l'IA — mesuré sur
## les vraies ressources, jamais déclaré.
extends GateTestCase

const LIBRARY: String = "res://assets/animations/AL_RaiderStates.res"
const AUDIT: String = "res://evidence/artQ2/raider_anim_audit.json"
const RAIDER: String = "res://scenes/enemies/RaiderRed.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"

var _world: Node3D = null
var _player: PlayerController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _setup() -> void:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = Vector3(0, 0.1, 0)
	_world.add_child(_player)
	_player.set_intent_source(InputIntent.new())
	await _settle(3)


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	await _settle(1)


func _poke(raider: RaiderRed, amount: float) -> void:
	var event: DamageEvent = DamageEvent.new()
	event.instigator = _player
	event.team = &"player"
	event.amount = amount
	event.attack_id = HitboxComponent.next_attack_id()
	(raider.get_node("Hurtbox") as HurtboxComponent).receive_hit(event)


func test_the_raider_library_is_baked_with_its_own_attack_grammar() -> void:
	## La bibliothèque du pillard existe, ses boucles bouclent, son attaque
	## est le crochet de mêlée (pas l'épée du héros), et l'audit de root
	## motion prouve les boucles fermées.
	var library: AnimationLibrary = load(LIBRARY) as AnimationLibrary
	check(library != null, "AL_RaiderStates.res charge")
	check(library.has_animation(&"Melee_Hook"),
		"l'attaque du gourdin est le crochet de mêlée")
	check(not library.has_animation(&"Sword_Regular_A"),
		"…pas le coup d'épée du héros — grammaires distinctes (§12)")
	check_equal(int(library.get_animation(&"Jog_Fwd").loop_mode),
		int(Animation.LOOP_LINEAR), "la poursuite boucle")
	check_equal(int(library.get_animation(&"Melee_Hook").loop_mode),
		int(Animation.LOOP_NONE), "le crochet ne boucle pas")
	check(FileAccess.file_exists(AUDIT), "audit JSON dans evidence/artQ2/")
	var clips: Dictionary = (JSON.parse_string(
		FileAccess.get_file_as_string(AUDIT)) as Dictionary).get("clips", {})
	for clip: Variant in clips:
		var measures: Dictionary = clips[clip]
		if bool(measures.get("loop", false)):
			check(float(measures.get("drift_m", 1.0)) <= 0.05,
				"%s : boucle refermée" % String(clip))


func test_the_three_faction_variants_mount_with_distinct_tints() -> void:
	## §12 : braise, azur, obsidienne — trois scènes du registre, même
	## squelette, teintes RÉELLEMENT différentes sur les matériaux montés.
	var albedos: Dictionary = {}
	for id: StringName in [&"char.raider_red", &"char.raider_blue",
			&"char.raider_black"]:
		var packed: PackedScene = AssetRegistry.resolve(id)
		check(packed != null, "%s : la variante résout" % String(id))
		var instance: CharacterModelSockets = packed.instantiate() \
			as CharacterModelSockets
		_tree().root.add_child(instance)
		await _settle(1)
		check_equal(instance.find_children("*", "Skeleton3D", true, false).size(),
			1, "%s : squelette monté" % String(id))
		var sample: Color = Color.WHITE
		for node: Node in instance.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			var material: BaseMaterial3D = \
				mesh.get_surface_override_material(0) as BaseMaterial3D
			if material != null:
				sample = material.albedo_color
				break
		albedos[id] = sample
		# Libération DIFFÉRÉE : le renderer (même factice) référence encore
		# les matériaux par instance pendant la frame — un free() immédiat
		# le fait crier « material is null » à la frame suivante.
		instance.queue_free()
		await _settle(2)
	var red: Color = albedos[&"char.raider_red"]
	var blue: Color = albedos[&"char.raider_blue"]
	var black: Color = albedos[&"char.raider_black"]
	check(red.r > red.b + 0.1, "la braise tire au rouge (%s)" % red)
	check(blue.b > blue.r + 0.1, "l'azur tire au bleu (%s)" % blue)
	check(black.r < 0.4 and black.b < 0.4, "l'obsidienne est sombre (%s)" % black)


func test_the_real_raider_mounts_the_model_and_keeps_its_gameplay_volumes() -> void:
	## Dans RaiderRed.tscn RÉEL : modèle monté, graybox masqué, gourdin dans
	## la MAIN animée (socket hand_r), capsule et volume de frappe inchangés.
	await _setup()
	var raider: RaiderRed = (load(RAIDER) as PackedScene).instantiate() as RaiderRed
	raider.position = Vector3(0, 0.1, 6.0)
	_world.add_child(raider)
	await _settle(3)
	var visual: CharacterVisual = raider.get_node("Pivot/CharacterVisual") \
		as CharacterVisual
	check(not visual.is_fallback_active(), "le modèle pillard est monté")
	check(not (raider.get_node("Pivot/BodyMesh") as MeshInstance3D).visible,
		"graybox masqué")
	var club: MeshInstance3D = raider.find_children("ClubMesh",
		"MeshInstance3D", true, false)[0] as MeshInstance3D
	var socket: BoneAttachment3D = visual.weapon_socket()
	check(socket != null and socket.bone_name == "hand_r",
		"socket d'arme sur la main droite")
	check(socket.is_ancestor_of(club),
		"le gourdin vit dans la main — il suit le crochet de mêlée")
	var capsule: CapsuleShape3D = (raider.get_node("CollisionShape3D")
		as CollisionShape3D).shape as CapsuleShape3D
	check(capsule != null and absf(capsule.height - 1.6) < 0.001,
		"la capsule IA reste l'autorité (1,6 m, intouchée)")
	check(not raider.telegraph_materials().is_empty(),
		"le télégraphe a des matériaux ACTIFS malgré le graybox masqué")
	await _teardown()


func test_the_ai_states_drive_the_clips_and_death_lies_down_once() -> void:
	## La machine d'états RÉELLE pilote les clips : repos → Idle ; agression
	## → poursuite (Jog_Fwd) puis crochet (Melee_Hook) ; mort → Death01 UNE
	## fois, sans bascule procédurale du pivot en plus.
	await _setup()
	var raider: RaiderRed = (load(RAIDER) as PackedScene).instantiate() as RaiderRed
	raider.position = Vector3(0, 0.1, 8.0)
	_world.add_child(raider)
	await _settle(6)
	var visual: CharacterVisual = raider.get_node("Pivot/CharacterVisual") \
		as CharacterVisual
	check_equal(String(visual.current_state()), "idle", "au repos : idle")

	_poke(raider, 1.0)
	var saw_chase: bool = false
	var saw_attack: bool = false
	for i: int in range(300):
		await _tree().physics_frame
		if raider.state() == RaiderRed.State.CHASE \
				and String(visual.current_state()) == "run":
			saw_chase = true
		if raider.state() == RaiderRed.State.ATTACK \
				and String(visual.current_state()) == "attack_light":
			saw_attack = true
		if saw_chase and saw_attack:
			break
	check(saw_chase, "poursuite : l'état CHASE joue la course")
	check(saw_attack, "attaque : l'état ATTACK joue le crochet")

	_poke(raider, 999.0)
	await _settle(4)
	check_equal(int(raider.state()), int(RaiderRed.State.DEAD),
		"préalable : mort")
	check_equal(String(visual.current_state()), "death", "clip de mort")
	check(absf((raider.get_node("Pivot") as Node3D).rotation.x) < 0.01,
		"le pivot ne bascule pas — Death01 couche le corps, pas un tilt en plus")
	await _teardown()
