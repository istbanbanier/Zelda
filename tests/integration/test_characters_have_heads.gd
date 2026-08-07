## LE HÉROS ET LES PILLARDS ONT UNE TÊTE, ET ELLE EST AU BON ENDROIT.
##
## Défaut mesuré au playtest du 2026-08-07, confirmé en gros plan de profil :
## « NI le héros NI les ennemis n'ont de tête. Le capuchon du héros est CREUX
## et VIDE — on voit à l'intérieur, il n'y a rien. Les ennemis ont un cône/bloc
## métallique posé sur le cou, à la place du crâne. » Verbatim du testeur :
## « je ne regardais plus un jeu, je regardais un chantier ».
##
## Vérifié dans les sources : `Male_Ranger.gltf` livre `Male_Ranger_Head_Hood`
## — la capuche SEULE — et `Male_Peasant.gltf` (les trois pillards) livre
## Arms/Body/Feet/Legs, rien au-dessus du cou.
##
## Ce cas ne se contente PAS de vérifier qu'un fichier existe : il monte le
## personnage, laisse le squelette se poser, et mesure où la tête se trouve
## dans le monde. Un crâne au bon endroit est la seule preuve qui compte —
## un maillage posé sur les genoux passerait n'importe quel test d'existence.
extends GateTestCase

## Modèle → hauteur d'os `Head` attendue, mesurée dans le glTF source.
## Le pillard braise culmine à 1,42 m, le briseur à 1,88 : une tête unique
## mise à l'échelle par le squelette doit atterrir à des hauteurs différentes.
const SUBJECTS: Dictionary = {
	"res://scenes/characters/HeroVisual.tscn": 1.5986,
	"res://scenes/characters/RaiderRedVisual.tscn": 1.3109,
	"res://scenes/characters/RaiderBlueVisual.tscn": 1.4707,
	"res://scenes/characters/RaiderBlackVisual.tscn": 1.7585,
}

## Tolérance sur la position de l'os : le squelette est au repos, pas animé.
const BONE_TOLERANCE: float = 0.06
## Une tête humaine fait 20 à 26 cm de haut. En deçà, c'est un bouchon.
const MIN_HEAD_HEIGHT: float = 0.12
const MAX_HEAD_HEIGHT: float = 0.30


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(frames: int) -> void:
	for i: int in range(frames):
		await _tree().process_frame


func test_every_character_carries_a_head_on_the_head_bone() -> void:
	for path: String in SUBJECTS:
		var scene: PackedScene = load(path) as PackedScene
		check(scene != null, "%s se charge" % path.get_file())
		if scene == null:
			continue
		var model: CharacterModelSockets = \
			scene.instantiate() as CharacterModelSockets
		_tree().root.add_child(model)
		await _settle(3)

		var mount: BoneAttachment3D = model.socket("SOCKET_HEAD")
		check(mount != null, "%s : socket de tête monté" % path.get_file())
		if mount == null:
			model.queue_free()
			continue
		var head: Node = mount.get_node_or_null("Head")
		check(head != null, "%s : une tête est réellement montée"
			% path.get_file())
		if head == null:
			model.queue_free()
			continue

		# 1. La tête porte de la GÉOMÉTRIE — pas un nœud vide bien nommé.
		var meshes: Array[Node] = head.find_children(
			"*", "MeshInstance3D", true, false)
		var triangles: int = 0
		for node: Node in meshes:
			var mesh: MeshInstance3D = node as MeshInstance3D
			if mesh.mesh != null:
				triangles += mesh.mesh.get_faces().size() / 3
		check(triangles > 200,
			"%s : la tête a une vraie géométrie (%d triangles)"
				% [path.get_file(), triangles])

		# 2. Le squelette porte bien l'os attendu, à la hauteur attendue.
		# C'est le REPOS qu'on compare ici : la pose animée, elle, bouge.
		var skeletons: Array[Node] = model.find_children(
			"*", "Skeleton3D", true, false)
		var skeleton: Skeleton3D = skeletons[0] as Skeleton3D
		var rest: float = skeleton.get_bone_global_rest(
			skeleton.find_bone("Head")).origin.y
		var expected: float = SUBJECTS[path]
		check(absf(rest - expected) < BONE_TOLERANCE,
			"%s : os `Head` au repos à %.3f m (attendu %.3f)"
				% [path.get_file(), rest, expected])

		# 3. Le crâne s'élève AU-DESSUS DE SON POINT D'ACCROCHE, d'une hauteur
		# de tête. On mesure depuis le socket et non depuis le repos : c'est
		# `BoneAttachment3D` qui porte la tête, et il suit la pose ANIMÉE —
		# l'idle du briseur baisse la nuque de 16 cm, ce qui faisait conclure à
		# tort à un crâne de 6 cm quand ce cas comparait au repos.
		var socket_y: float = mount.global_position.y
		var height: float = model.head_top().y - socket_y
		check(height > MIN_HEAD_HEIGHT and height < MAX_HEAD_HEIGHT,
			"%s : hauteur de crâne plausible (%.3f m)"
				% [path.get_file(), height])

		model.queue_free()
		await _settle(2)


## Le crâne du pillard braise doit être PLUS PETIT que celui du briseur :
## c'est la preuve que l'échelle vient du squelette et non d'une constante
## saisie à la main, qui dériverait au premier changement de modèle.
func test_the_head_is_scaled_to_each_stature() -> void:
	var heights: Dictionary = {}
	for path: String in ["res://scenes/characters/RaiderRedVisual.tscn",
			"res://scenes/characters/RaiderBlackVisual.tscn"]:
		var model: CharacterModelSockets = \
			(load(path) as PackedScene).instantiate() as CharacterModelSockets
		_tree().root.add_child(model)
		await _settle(3)
		var socket: BoneAttachment3D = model.socket("SOCKET_HEAD")
		var head: Node3D = socket.get_node_or_null("Head") as Node3D \
			if socket != null else null
		heights[path] = 0.0 if head == null else head.scale.x
		model.queue_free()
		await _settle(2)
	var small: float = heights["res://scenes/characters/RaiderRedVisual.tscn"]
	var large: float = heights["res://scenes/characters/RaiderBlackVisual.tscn"]
	check(small > 0.0 and large > 0.0, "les deux têtes sont montées")
	check(large > small,
		"le briseur (1,88 m) a un crâne plus grand que le braise (1,42 m) : "
			+ "%.3f > %.3f" % [large, small])
