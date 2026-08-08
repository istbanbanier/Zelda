## LES TÊTES EXISTENT DANS LA VALLÉE OÙ L'ON JOUE, pas seulement en laboratoire.
##
## `test_characters_have_heads.gd` monte les scènes de personnage DIRECTEMENT.
## Il prouve que la tête se pose sur l'os — jamais qu'un joueur qui démarre le
## jeu normalement (Boot → menu → vallée) la verra.
##
## La distinction n'est pas théorique : c'est exactement le défaut que la
## session parallèle a consigné le même jour sous PT-LIVRAISON-01 — la monture
## et le vol libre avaient ONZE tests verts et n'existaient dans aucune scène
## jouable, parce que les tests les instanciaient eux-mêmes. « Un test vert
## peut coexister avec une fonctionnalité inaccessible. »
##
## Ici le risque est réel et nommé : `CharacterVisual` résout son modèle via
## `AssetRegistry` et, s'il échoue, se rabat SILENCIEUSEMENT sur la capsule
## graybox (`character_visual.gd:30`) — qui n'a pas de tête. Un repli actif
## dans la vallée rendrait la correction invisible sans faire échouer un seul
## des tests précédents.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"

var _valley: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _load() -> void:
	# Un monde jouable AUTOSAUVEGARDE : on garde l'état d'avant pour le
	# rendre intact au cas suivant (voir `remember_saves`).
	remember_saves()
	_valley = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_valley)
	await _settle(10)


func _unload() -> void:
	_tree().paused = false
	_valley.get_parent().remove_child(_valley)
	_valley.queue_free()
	_valley = null
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)
	restore_saves()


## Le héros de la vallée porte un crâne, et son modèle riggé n'est pas en repli.
func test_the_hero_in_the_valley_has_a_head() -> void:
	await _load()
	var player: PlayerController = _valley.call("player") as PlayerController
	check(player != null, "la vallée porte un joueur")
	var models: Array[Node] = player.find_children(
		"*", "CharacterModelSockets", true, false)
	check(not models.is_empty(),
		"le modèle riggé du héros est monté dans la vallée (pas le repli graybox)")
	if models.is_empty():
		await _unload()
		return
	var model: CharacterModelSockets = models[0] as CharacterModelSockets
	var mount: BoneAttachment3D = model.socket("SOCKET_HEAD")
	check(mount != null, "…et il a un socket de tête")
	check(mount != null and mount.get_node_or_null("Head") != null,
		"…et une tête est réellement dessus")
	# Le crâne se tient AU-DESSUS des épaules du héros, dans le monde.
	#
	# ISS-038 — ce bloc mesurait après `_settle(10)`, un nombre FIXE de frames,
	# et lisait parfois 1,16 m au lieu de 1,20 : la pose du squelette et le
	# `BoneAttachment3D` n'étaient pas encore stabilisés. Quatre centimètres, et
	# la suite entière basculait au rouge.
	#
	# On n'attend plus un COMPTE, on attend la CONDITION : la hauteur du crâne
	# cesse de bouger. Bornée, pour qu'un vrai blocage échoue au lieu de pendre.
	var top: float = model.head_top().y
	var previous: float = -INF
	var stable: int = 0
	for i: int in range(240):
		top = model.head_top().y
		stable = stable + 1 if absf(top - previous) < 0.001 else 0
		previous = top
		if stable >= 5:
			break
		await _tree().physics_frame
	check(stable >= 5,
		"la pose du héros s'est stabilisée avant la mesure (%d frames stables)"
			% stable)
	check(top > player.global_position.y + 1.2,
		"le crâne est à hauteur de tête (%.2f m au-dessus des pieds)"
			% (top - player.global_position.y))
	await _unload()


## Et chaque pillard réellement posé dans la vallée en porte un aussi.
func test_every_raider_in_the_valley_has_a_head() -> void:
	await _load()
	var without: Array[String] = []
	var counted: int = 0
	for node: Node in _valley.find_children("*", "CharacterModelSockets",
			true, false):
		var model: CharacterModelSockets = node as CharacterModelSockets
		# Le héros est couvert par le cas précédent ; ici les ennemis.
		if model.get_parent() != null \
				and model.get_parent().name == "VisualRoot" \
				and model.owner is PlayerController:
			continue
		var skeletons: Array[Node] = model.find_children(
			"*", "Skeleton3D", true, false)
		if skeletons.is_empty():
			continue
		if (skeletons[0] as Skeleton3D).find_bone("Head") < 0:
			continue   # créature sans os `Head` : hors du périmètre de ce cas
		counted += 1
		var mount: BoneAttachment3D = model.socket("SOCKET_HEAD")
		if mount == null or mount.get_node_or_null("Head") == null:
			without.append(model.name)
	check(counted > 0,
		"des personnages à squelette humanoïde peuplent la vallée (%d)" % counted)
	check(without.is_empty(),
		"tous portent un crâne ; sans tête : %s"
			% ("aucun" if without.is_empty() else ", ".join(without)))
	await _unload()
