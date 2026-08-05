## P2-3 — Identités d'armes (P2 §7.5) : « ne pas produire six recolorations
## d'un même combo ». Fail-first : écrit avant les lourdes par famille.
##
## Chaque famille de mêlée répond à une question tactique par SA lourde,
## en pure data : le gourdin PROJETTE (recul maximal), la hache BRISE
## (posture_damage qui vide la garde d'un Briseur en un coup), la lame
## conductrice DÉCHARGE (élément électrique), l'épée LIT (bonus de fenêtre
## de déviation), la lance TIENT LA DISTANCE (portée maximale — donnée
## déjà en place). Et l'équipement échange RÉELLEMENT la lourde du
## contrôleur — plus jamais la lourde d'épée pour tout le monde.
extends GateTestCase

const WEAPONS: Dictionary = {
	&"club": "res://resources/weapons/wood_club.tres",
	&"sword": "res://resources/weapons/worn_sword.tres",
	&"spear": "res://resources/weapons/spear.tres",
	&"axe": "res://resources/weapons/heavy_axe.tres",
	&"blade": "res://resources/weapons/conductive_blade.tres",
}

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null


func _load_all() -> Dictionary:
	var loaded: Dictionary = {}
	for family: StringName in WEAPONS:
		loaded[family] = load(WEAPONS[family] as String) as WeaponDefinition
	return loaded


func test_each_melee_family_answers_its_own_tactical_question() -> void:
	var weapons: Dictionary = _load_all()
	for family: StringName in weapons:
		var definition: WeaponDefinition = weapons[family] as WeaponDefinition
		check(definition != null, "définition chargée : %s" % family)
		if definition == null:
			return
		check(definition.heavy_attack != null,
			"%s : une lourde PROPRE à la famille" % family)
	var club: WeaponDefinition = weapons[&"club"] as WeaponDefinition
	var sword: WeaponDefinition = weapons[&"sword"] as WeaponDefinition
	var spear: WeaponDefinition = weapons[&"spear"] as WeaponDefinition
	var axe: WeaponDefinition = weapons[&"axe"] as WeaponDefinition
	var blade: WeaponDefinition = weapons[&"blade"] as WeaponDefinition
	if club.heavy_attack == null or sword.heavy_attack == null \
			or spear.heavy_attack == null or axe.heavy_attack == null \
			or blade.heavy_attack == null:
		return
	# Cinq lourdes distinctes — pas une ressource partagée recolorée.
	var ids: Array[StringName] = []
	for family: StringName in weapons:
		var heavy: AttackDefinition = \
			(weapons[family] as WeaponDefinition).heavy_attack
		check(not heavy.id in ids, "lourde unique : %s (%s)" % [heavy.id, family])
		ids.append(heavy.id)
	# La hache BRISE : sa lourde vide la garde d'un Briseur (12) en UN coup,
	# et domine strictement les autres sur cet axe.
	check(axe.heavy_attack.posture_damage >= 12.0,
		"hache : posture_damage ≥ 12 (brise la garde du Briseur en un coup)")
	for family: StringName in [&"club", &"sword", &"spear", &"blade"]:
		check((weapons[family] as WeaponDefinition).heavy_attack.posture_damage \
			< axe.heavy_attack.posture_damage,
			"la hache domine %s en rupture de garde" % family)
	# Le gourdin PROJETTE : recul strictement maximal.
	for family: StringName in [&"sword", &"spear", &"axe", &"blade"]:
		check((weapons[family] as WeaponDefinition).heavy_attack.knockback \
			< club.heavy_attack.knockback,
			"le gourdin projette plus loin que %s" % family)
	# La lame DÉCHARGE : élément électrique sur la lourde, unique à elle.
	check(blade.heavy_attack.element == &"electric",
		"lame conductrice : lourde électrique")
	for family: StringName in [&"club", &"sword", &"spear", &"axe"]:
		check((weapons[family] as WeaponDefinition).heavy_attack.element != &"electric",
			"%s : pas d'élément électrique" % family)
	# L'épée LIT : seule à bonifier la fenêtre de déviation parfaite.
	check(sword.parry_window_bonus > 0.0, "épée : bonus de fenêtre de déviation")
	for family: StringName in [&"club", &"spear", &"axe", &"blade"]:
		check((weapons[family] as WeaponDefinition).parry_window_bonus == 0.0,
			"%s : pas de bonus de déviation" % family)
	# La lance TIENT LA DISTANCE : portée strictement maximale (donnée §11.1).
	for family: StringName in [&"club", &"sword", &"axe", &"blade"]:
		check((weapons[family] as WeaponDefinition).reach_m < spear.reach_m,
			"la lance dépasse %s en portée" % family)
	# La hache s'ANNONCE : startup le plus long (P2 §7.5 : startup/recovery
	# élevés sont sa faiblesse réelle).
	for family: StringName in [&"club", &"sword", &"spear", &"blade"]:
		check((weapons[family] as WeaponDefinition).heavy_attack.startup \
			< axe.heavy_attack.startup,
			"la hache s'annonce plus longtemps que %s" % family)


func test_equipping_really_swaps_the_heavy_of_the_controller() -> void:
	var tree: SceneTree = _tree()
	_root = Node3D.new()
	tree.root.add_child(_root)
	var player_scene: PackedScene = load("res://scenes/player/Player.tscn") as PackedScene
	var player: PlayerController = player_scene.instantiate() as PlayerController
	_root.add_child(player)
	await tree.physics_frame
	var attack: AttackControllerComponent = \
		player.get_node("Components/AttackController") as AttackControllerComponent
	if attack == null:
		check(false, "contrôleur d'attaque introuvable")
		_teardown()
		return
	var inventory: InventoryComponent = \
		player.get_node("Components/InventoryComponent") as InventoryComponent
	var axe_def: WeaponDefinition = load(WEAPONS[&"axe"] as String) as WeaponDefinition
	var axe: WeaponInstance = WeaponInstance.create(axe_def)
	check(inventory.add_weapon(axe), "hache ajoutée")
	var index: int = 0
	for i: int in range(8):
		if inventory.equip_index(i) and inventory.equipped() == axe:
			index = i
			break
	check(inventory.equipped() == axe, "hache équipée (slot %d)" % index)
	check(attack.heavy_attack == axe_def.heavy_attack,
		"la lourde du contrôleur EST celle de la hache — plus celle de l'épée")
	_teardown()
