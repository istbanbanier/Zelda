## PLANCHE D'INSPECTION d'un ancrage de récompense.
##
## L'audit physique (`RewardAnchorAudit`) répond à « un corps y arrive-t-il et
## en repart-il ». Il ne répond pas à « à quoi cela ressemble ». Un coffre
## posé sur un sol réel, atteignable et quittable, peut encore être à moitié
## dans un tronc, dos à un mur, ou invisible depuis le chemin.
##
## Cette scène place la caméra au POINT DE STATION de l'ancrage — là où le
## joueur se tiendra pour interagir — à hauteur d'yeux, et regarde la
## récompense. Ce qu'on voit est donc ce que le joueur verra.
##
##     --script tools/godot/capture_reference.gd -- \
##         --scene=res://scenes/tests/RewardAnchorShot.tscn \
##         --out=evidence/rewards/<lieu>.png --place=valley.poi.veil_falls.01
##
## Sans `--place`, la scène prend le premier ancrage trouvé et le dit.
class_name RewardAnchorShot
extends Node3D

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
## Hauteur des yeux au-dessus du sol de station.
const EYE: float = 1.55
## Recul supplémentaire derrière le point de station : on veut voir la
## récompense DANS son lieu, pas coller le nez dessus.
const PULL_BACK: float = 1.6

var place_id: StringName = &""
var framed: bool = false


func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--place="):
			place_id = StringName(argument.substr(8))

	var packed: PackedScene = load(VALLEY) as PackedScene
	if packed == null:
		push_error("[ancrage] vallée introuvable")
		return
	var world: Node3D = packed.instantiate() as Node3D
	add_child(world)

	var anchor: RewardAnchor = _find(world)
	if anchor == null:
		push_error("[ancrage] aucun ancrage pour %s" % place_id)
		return

	# Le point de vue est celui du joueur : au point de station, reculé, à
	# hauteur d'yeux. Un cadrage choisi ailleurs flatterait la pose.
	var stand: Vector3 = anchor.standing_point()
	var back: Vector3 = (stand - anchor.global_position)
	back.y = 0.0
	if back.length() < 0.05:
		back = Vector3.FORWARD
	var eye: Vector3 = stand + back.normalized() * PULL_BACK + Vector3(0, EYE, 0)

	var camera: Camera3D = Camera3D.new()
	camera.name = "VueAncrage"
	camera.fov = 55.0
	camera.current = true
	add_child(camera)
	# `look_at` exige d'être DANS l'arbre : appelé avant, il vise le vide.
	camera.global_position = eye
	camera.look_at(anchor.global_position + Vector3(0, 0.45, 0), Vector3.UP)
	framed = true
	print("[ancrage] %s — caméra en %v, cible %v"
		% [anchor.place_id, eye, anchor.global_position])


func _find(world: Node3D) -> RewardAnchor:
	var first: RewardAnchor = null
	for node: Node in world.find_children("*", "RewardAnchor", true, false):
		var anchor: RewardAnchor = node as RewardAnchor
		if first == null:
			first = anchor
		if anchor.place_id == place_id:
			return anchor
	if String(place_id).is_empty() and first != null:
		print("[ancrage] aucun --place= : premier ancrage (%s)" % first.place_id)
		return first
	return null
