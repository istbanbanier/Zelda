## ISS-035 — les pierres de la rivière touchent-elles vraiment le lit ?
##
## Origine : sonde `tools/godot/probe_world_boxes.gd` sur la vallée montée.
##
##     DressZoneRiver/RockPath_Round_Wide_4    y 0,54..0,70  sol -1,50  → +2,04 m
##     DressZoneRiver/RockPath_Round_Thin_5    y 0,49..0,62  sol -1,50  → +1,99 m
##
## Ces « pierres émergentes du lit » étaient des DALLES de 0,11 à 0,18 m
## d'épaisseur, posées à une cote intermédiaire qui n'était ni le lit (-1,50),
## ni la surface de l'eau (-0,55). Elles flottaient à mi-hauteur.
##
## LE PIÈGE QUE CE TEST EXISTE POUR EMPÊCHER. La correction évidente — « poser
## les dalles sur le lit » — produit PIRE : une dalle de 0,16 m posée à -1,50 a
## son sommet à -1,34, soit 0,79 m SOUS l'eau. Elle disparaît. Un test qui ne
## vérifierait que « la base touche le lit » validerait donc une rivière vide.
##
## D'où deux exigences conjointes, et c'est le cœur du test :
##
##   1. la base atteint le lit — la pierre repose sur le fond ;
##   2. le sommet émerge de l'eau — la pierre se voit.
##
## Aucune dalle du kit ne peut satisfaire les deux : il faut 0,95 m pour aller
## du lit à la surface, et la plus épaisse fait 0,18 m. Le second bras du test
## le vérifie à la source, pour qu'un futur placement de dalle en rivière
## rougisse AVANT d'être monté.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const ROCKS_DIR: String = "res://assets/environment/rocks"

## Cotes du monde, lues dans `valley_terrain.gd` et non recopiées de mémoire :
## `_slab("Riverbed", ..., -1.5, ...)` pour le lit ; le ruban d'eau est un
## `BoxMesh` de 0,30 m d'épaisseur centré à -0,70, donc surface à -0,55.
const BED: float = -1.5
const WATER_TOP: float = -0.55

## Hauteur minimale utile d'une pierre de lit : la distance lit → surface.
const SPAN: float = WATER_TOP - BED   # 0,95 m

## La pierre est enfoncée de 5 cm dans le lit par conception (un bloc en
## rivière y est PRIS, il n'y est pas posé en équilibre). On tolère donc un
## dépassement vers le bas, et très peu vers le haut.
const SINK_MAX: float = 0.60
const LIFT_MAX: float = 0.10

var _valley: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _load_valley() -> void:
	_valley = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_valley)
	await _settle(5)


func _unload_valley() -> void:
	if _valley == null:
		return
	_valley.get_parent().remove_child(_valley)
	_valley.queue_free()
	_valley = null
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


## Boîte englobante en espace MONDE : la transformation des parents (donc
## l'échelle du site) est comprise. Mesurer en repère local était l'un des deux
## défauts trouvés en écrivant `test_roofs_are_supported.gd` ; on ne le refait
## pas.
func _world_box(root_node: Node3D) -> AABB:
	var box: AABB = AABB()
	var first: bool = true
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var world: AABB = instance.global_transform * instance.mesh.get_aabb()
		box = world if first else box.merge(world)
		first = false
	return box if not first else AABB(Vector3.ZERO, Vector3.ZERO)


func test_river_stones_rest_on_the_bed_and_emerge() -> void:
	## DANS LE MONDE. Chaque rocher du lit doit satisfaire les DEUX exigences.
	await _load_valley()
	var river: Node3D = _valley.find_child("DressZoneRiver", true, false) as Node3D
	check_not_null(river, "DressZoneRiver introuvable dans la vallée montée")
	if river == null:
		await _unload_valley()
		return

	var inspected: int = 0
	var floating: Array[String] = []
	var drowned: Array[String] = []
	var buried: Array[String] = []

	for child: Node in river.get_children():
		var name_text: String = String(child.name)
		# « Rock » SANS underscore : couvre `Rock_Medium_*` (les blocs actuels)
		# ET `RockPath_*` (les dalles d'avant). Le premier jet filtrait sur
		# `Rock_`, qui ne reconnaissait pas `RockPath` — le test rougissait
		# alors sur « 0 rocher trouvé » au lieu de « flotte », et surtout une
		# dalle suspendue REMISE À CÔTÉ de quatre bons blocs serait passée
		# inaperçue. Défaut trouvé en vérifiant que le test rougit bien sans le
		# correctif ; un test vert ne prouve rien tant qu'on n'a pas vu sa
		# couleur rouge, ni POUR QUELLE RAISON il rougit.
		#
		# Les autres pièces de la zone (roseaux, herbes, saule, bivouac) sont
		# sur la BERGE à y ≈ 2,02, pas dans l'eau : aucune ne porte « Rock ».
		if not name_text.contains("Rock"):
			continue
		var node: Node3D = child as Node3D
		if node == null:
			continue
		var box: AABB = _world_box(node)
		if box.size == Vector3.ZERO:
			continue
		inspected += 1
		var bottom: float = box.position.y
		var top: float = box.position.y + box.size.y
		if bottom > BED + LIFT_MAX:
			floating.append("%s : base %+.3f, lit %+.2f → flotte de %.2f m"
				% [name_text, bottom, BED, bottom - BED])
		if bottom < BED - SINK_MAX:
			buried.append("%s : base %+.3f, soit %.2f m sous le lit"
				% [name_text, bottom, BED - bottom])
		if top <= WATER_TOP:
			drowned.append("%s : sommet %+.3f, surface %+.2f → noyé de %.2f m"
				% [name_text, top, WATER_TOP, WATER_TOP - top])

	check(inspected >= 4,
		"le lit doit porter au moins 4 rochers inspectables ; trouvé %d" % inspected)
	check(floating.is_empty(), "pierre(s) suspendue(s) au-dessus du lit : %s" % str(floating))
	check(drowned.is_empty(), "pierre(s) invisible(s) sous l'eau : %s" % str(drowned))
	check(buried.is_empty(), "pierre(s) enterrée(s) dans le lit : %s" % str(buried))
	await _unload_valley()


func test_no_flat_slab_can_ever_satisfy_the_rule() -> void:
	## À LA SOURCE, et sans monter la vallée. Une pierre de lit doit couvrir la
	## distance lit → surface. On mesure les dalles `RockPath_*` du kit et on
	## exige qu'AUCUNE n'y parvienne, même à la variation d'échelle maximale
	## admise dans les placements existants (1,5).
	##
	## Ce bras ne teste pas le correctif : il verrouille le RAISONNEMENT. S'il
	## rougissait un jour — parce qu'une dalle épaisse serait ajoutée au kit —
	## la règle « les dalles ne conviennent pas » devrait être rediscutée plutôt
	## que recopiée.
	const VARIATION_MAX: float = 1.5
	var dir: DirAccess = DirAccess.open(ROCKS_DIR)
	check_not_null(dir, "répertoire des rochers introuvable : %s" % ROCKS_DIR)
	if dir == null:
		return

	var slabs: int = 0
	var tall_enough: Array[String] = []
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry.begins_with("RockPath_") and entry.ends_with(".gltf"):
			var packed: PackedScene = load("%s/%s" % [ROCKS_DIR, entry]) as PackedScene
			if packed != null:
				var node: Node3D = packed.instantiate() as Node3D
				if node != null:
					_tree().root.add_child(node)
					var height: float = _world_box(node).size.y
					node.get_parent().remove_child(node)
					node.queue_free()
					slabs += 1
					if height * VARIATION_MAX >= SPAN:
						tall_enough.append("%s : %.3f m × %.1f ≥ %.2f m"
							% [entry, height, VARIATION_MAX, SPAN])
		entry = dir.get_next()
	dir.list_dir_end()

	check(slabs >= 4, "au moins 4 dalles RockPath_* attendues ; trouvé %d" % slabs)
	check(tall_enough.is_empty(),
		"une dalle atteint désormais la surface : la règle est à rediscuter, pas à recopier — %s"
		% str(tall_enough))
