## La colonne de fumée du camp cesse de mentir sur deux points.
##
## L'INCIDENT. La capture `04_camp_interieur` du 2026-08-10, prise au camp sur
## `02d5212`, montre une masse claire au milieu du campement ET une ombre pleine
## barrant le sol. L'objet au-dessus existe : c'est la colonne, haute de 40 m et
## donc hors cadre dès qu'on s'en approche.
##
## DEUX CAUSES DISTINCTES, mesurées avant d'être corrigées.
##
## 1. `SmokeColumn` ne déclare aucun `cast_shadow` et garde donc la valeur par
##    défaut « activé ». Un volume de fumée à alpha 0,22 projetait une ombre
##    d'objet plein.
##
## 2. La compensation de pivot du cisaillement est juste en X et fausse en Y.
##    Pour ancrer le pied il faut `_base_height - h(1 - cos(lean))` ; le code
##    écrivait `+`. À `SWAY_DEG = 6` et `h = 20`, le pied monte de 0,219 m.
##
## Ce test ne juge pas l'aspect de la fumée — seulement qu'elle n'invente pas
## une ombre et que son pied ne décolle pas du foyer.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const SMOKE_PATH: String = "Camp/SmokeColumn"

## Deux cycles complets de balancement : `SWAY_SPEED = 0.5` Hz, donc 2 s par
## cycle. On échantillonne assez pour attraper les deux extrêmes du sinus.
const SAMPLE_FRAMES: int = 130
## Le pied peut frémir d'un cheveu sans que personne ne le voie. 5 cm est très
## en dessous des 21,9 cm mesurés, et très au-dessus du bruit numérique.
const FOOT_TOLERANCE_M: float = 0.05

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	# `ValleyWorld` démarre la boucle d'ambiance sur l'autoload. Sans cet arrêt,
	# le test rend son arbre mais garde le flux audio référencé jusqu'au verdict.
	var audio: Node = _tree().root.get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("stop_ambience"):
		audio.call("stop_ambience")
	for i: int in range(3):
		await _tree().physics_frame


func _open_valley() -> Node3D:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var valley: Node3D = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_root.add_child(valley)
	for i: int in range(10):
		await _tree().physics_frame
	return valley


func test_the_smoke_column_casts_no_shadow() -> void:
	var valley: Node3D = await _open_valley()
	var smoke: MeshInstance3D = \
		valley.get_node_or_null(NodePath(SMOKE_PATH)) as MeshInstance3D
	check_not_null(smoke, "la colonne de fumée existe à %s" % SMOKE_PATH)
	if smoke == null:
		await _teardown()
		return
	check(smoke.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		"une fumée semi-transparente ne projette pas d'ombre pleine "
		+ "(cast_shadow lu : %d)" % smoke.cast_shadow)
	await _teardown()


func test_the_foot_of_the_column_stays_on_the_fire() -> void:
	var valley: Node3D = await _open_valley()
	var smoke: MeshInstance3D = \
		valley.get_node_or_null(NodePath(SMOKE_PATH)) as MeshInstance3D
	check_not_null(smoke, "la colonne de fumée existe à %s" % SMOKE_PATH)
	if smoke == null:
		await _teardown()
		return
	# Le pied est le bas de la boîte englobante MONDE : le cisaillement penche
	# la tête, donc le point le plus bas reste la base du cylindre.
	var lowest: float = INF
	var highest: float = -INF
	for i: int in range(SAMPLE_FRAMES):
		await _tree().process_frame
		var box: AABB = smoke.global_transform * smoke.get_aabb()
		lowest = minf(lowest, box.position.y)
		highest = maxf(highest, box.position.y)
	var drift: float = highest - lowest
	check(drift <= FOOT_TOLERANCE_M,
		"le pied de la colonne reste ancré au foyer sur deux cycles "
		+ "(dérive mesurée %.3f m, tolérance %.3f m)" % [drift, FOOT_TOLERANCE_M])
	await _teardown()
