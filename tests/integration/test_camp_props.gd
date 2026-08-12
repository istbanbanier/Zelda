## ART-Q3 — props de production au camp : le coffre réel s'ouvre avec SON
## clip (IDs, loot et atomicité INTACTS), l'état sauvegardé s'applique sans
## geste ni loot, et le camp de la vallée porte caisses/tonneaux/galets
## réels avec leurs collisions. Mesuré sur les vraies scènes.
extends GateTestCase

const CHEST: String = "res://scenes/interactables/Chest.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"
const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const CLUB: String = "res://resources/weapons/wood_club.tres"

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
	box.size = Vector3(40, 1, 40)
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


func test_the_chest_opens_with_its_own_clip_and_keeps_loot_atomicity() -> void:
	## Le coffre monte le modèle rigged, masque son graybox, garde sa
	## collision, et l'ouverture joue Chest_Open — le loot et le refus
	## d'inventaire plein sont STRICTEMENT ceux d'avant.
	await _setup()
	var chest: Chest = (load(CHEST) as PackedScene).instantiate() as Chest
	chest.chest_id = &"test.chest.model.01"
	chest.weapon_loot = load(CLUB) as WeaponDefinition
	chest.position = Vector3(0, 0, 1.6)
	_world.add_child(chest)
	await _settle(2)
	var model_anim: Array[Node] = chest.find_children("*", "AnimationPlayer",
		true, false)
	check(not model_anim.is_empty(), "le modèle rigged du coffre est monté")
	var anim: AnimationPlayer = model_anim[0] as AnimationPlayer
	check(not (chest.get_node("BodyMesh") as MeshInstance3D).visible,
		"graybox du coffre masqué")
	check(chest.get_node("CollisionShape3D") != null, "collision intacte")

	var before: int = _player.inventory().weapons().size()
	check(chest.interact(_player), "ouverture acceptée")
	check_equal(_player.inventory().weapons().size(), before + 1,
		"le loot est versé UNE fois")
	check_equal(anim.current_animation, "Chest_Open",
		"l'ouverture joue le clip du modèle")
	check(not chest.interact(_player), "déjà ouvert : refusé (jamais de 2e loot)")
	await _teardown()


func test_a_saved_state_applies_the_opened_pose_without_looting() -> void:
	## §19.4 : l'application d'état joue la POSE ouverte (pas le geste) et ne
	## verse rien — idempotente, quel que soit l'ordre avec _ready.
	await _setup()
	var chest: Chest = (load(CHEST) as PackedScene).instantiate() as Chest
	chest.chest_id = &"test.chest.model.02"
	chest.weapon_loot = load(CLUB) as WeaponDefinition
	chest.position = Vector3(0, 0, 1.6)
	_world.add_child(chest)
	await _settle(2)
	var before: int = _player.inventory().weapons().size()
	chest.mark_opened_silently()
	await _settle(1)
	var anim: AnimationPlayer = chest.find_children("*", "AnimationPlayer",
		true, false)[0] as AnimationPlayer
	check_equal(anim.current_animation, "Chest_Opened",
		"pose ouverte directe — aucun geste d'ouverture rejoué")
	check_equal(_player.inventory().weapons().size(), before,
		"aucun loot versé par l'application d'état")
	check_equal(chest.prompt_verb(), "", "un coffre ouvert n'invite plus")
	await _teardown()


func test_the_valley_camp_carries_real_props_with_collisions() -> void:
	## Le camp de la vallée porte les caisses/tonneaux de production (vrais
	## maillages + collision d'obstacle) et l'anneau de galets du foyer.
	var valley: Node3D = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(valley)
	await _settle(5)
	var camp: Node3D = valley.find_children("CampDressing", "Node3D", true,
		false)[0] as Node3D
	var props: Array[Node] = []
	for child: Node in camp.get_children():
		if String(child.name).begins_with("CampProp_"):
			props.append(child)
	check(props.size() >= 4, "au moins 4 props de camp (%d)" % props.size())
	for prop: Node in props:
		var meshes: Array[Node] = prop.find_children("*", "MeshInstance3D",
			true, false)
		var real: bool = false
		for mesh: Node in meshes:
			if (mesh as MeshInstance3D).mesh != null:
				real = true
		check(real, "%s : maillage réel monté" % prop.name)
		check(not prop.find_children("*", "CollisionShape3D", true, false)
			.is_empty(), "%s : obstacle physique" % prop.name)
	var pebbles: int = 0
	for child: Node in camp.get_children():
		if String(child.name).begins_with("Pebble"):
			pebbles += 1
	check_equal(pebbles, 8, "l'anneau de foyer compte huit galets")
	# V4 lot 5 : le camp VIT — cuisine, réserve, travail, râtelier,
	# charrette, clôture, abri. Chaque placement a un maillage réel.
	# Passe 3 : 30 → 31 — la SECONDE bannière du seuil sud (§10.1 : « deux
	# bannières étroites »), exigée par le test du triangle du camp.
	var life: Node3D = camp.get_node("CampLife") as Node3D
	check_equal(life.get_child_count(), 31, "les 31 éléments de vie montés")
	var real_props: int = 0
	for prop: Node in life.get_children():
		for mesh: Node in prop.find_children("*", "MeshInstance3D", true, false):
			if (mesh as MeshInstance3D).mesh != null:
				real_props += 1
				break
	check_equal(real_props, 31, "…tous avec un maillage réel")
	check(not life.get_node("Cauldron_0").find_children("*", "MeshInstance3D",
		true, false).is_empty(), "le chaudron est SUR le foyer (§11.D)")
	valley.get_parent().remove_child(valley)
	valley.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)
