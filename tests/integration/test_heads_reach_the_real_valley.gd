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
	# GARDE-FOU PRÉCÉDENT RETIRÉ, car il ne pouvait pas rougir. Il attendait que
	# la hauteur « cesse de bouger », puis l'affirmait. Deux mesures l'ont
	# démonté : la boucle sortait à la frame 5, en pleine fenêtre où la valeur
	# est FIGÉE parce que l'animation n'a pas encore démarré ; et une fois
	# l'animation lancée, son pas maximal (0,80 mm) reste SOUS la tolérance
	# (1 mm) — « stable » était donc vrai pendant que la tête bougeait.
	# Une pose de liaison, immobile, l'aurait satisfait parfaitement.
	#
	# Ce qu'il faut prouver n'est pas l'immobilité, c'est que le rig est VIVANT.
	var players: Array[Node] = model.find_children("*", "AnimationPlayer", true, false)
	var anim: AnimationPlayer = players[0] as AnimationPlayer if not players.is_empty() else null
	check(anim != null and anim.is_playing(),
		"le rig du héros est animé, pas en pose de liaison (%s)"
			% (anim.current_animation if anim != null else "aucun AnimationPlayer"))
	# « Animé » ne suffisait pas : mesuré, le héros jouait `Jump_Land`. Il
	# apparaît légèrement au-dessus du sol, tombe et ATTERRIT — et le test
	# mesurait pendant l'accroupissement de réception. 1,07 m accroupi contre
	# 1,74 m debout : les 65 cm d'écart venaient de là, pas d'une pollution.
	#
	# On attend donc la POSTURE DE REPOS, bornée en temps de jeu. Une borne en
	# secondes et non en frames : c'est la leçon d'ISS-038, et la réception dure
	# une durée, pas un nombre d'images.
	var settled: bool = await _reaches_rest(anim)
	check(settled, "le héros a fini d'atterrir avant la mesure (animation « %s »)"
		% (anim.current_animation if anim != null else "?"))
	var top: float = model.head_top().y
	# BANDE, et non seuil unilatéral. `> 1.2` absolvait tout : la valeur réelle
	# est 1,74 m, donc une tête enfoncée à 1,25 m comme une tête flottant à 3 m
	# passaient l'une et l'autre. La respiration de l'idle vaut ±1,1 cm ; 8 cm
	# de tolérance la couvre largement sans rien absoudre.
	check_approx(top - player.global_position.y, 1.74, 0.08,
		"le crâne est à hauteur de tête (%.3f m au-dessus des pieds, attendu 1,74 ± 0,08 ; animation « %s »)"
			% [top - player.global_position.y,
			anim.current_animation if anim != null else "?"])
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


## Attend que le héros ait fini d'atterrir, borné en TEMPS DE JEU.
##
## Le héros apparaît au-dessus du sol et joue `Jump_Land` en touchant terre.
## Toute mesure de POSE prise avant la fin de cette réception lit un
## accroupissement : 1,07 m au lieu de 1,74. Attendre un nombre de frames ne
## suffit pas — une réception dure une durée (leçon d'ISS-038).
##
## Rend `false` si la borne est épuisée : un héros qui n'atteindrait jamais sa
## posture de repos est un vrai défaut, et le test doit le dire.
func _reaches_rest(anim: AnimationPlayer, budget_s: float = 4.0) -> bool:
	if anim == null:
		return false
	var elapsed: float = 0.0
	while elapsed <= budget_s:
		if not anim.current_animation.begins_with("Jump"):
			return true
		await _tree().physics_frame
		elapsed += _tree().root.get_physics_process_delta_time()
	return false
