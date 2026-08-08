## Trajectoire réelle du pilote de `test_the_route_from_ridge_to_north_plain_is_walkable`
## (ISS-032) — outil de diagnostic, sans verdict.
##
## La sonde de terrain a montré que le sol est à y = 2,00 sur toute l'approche
## du gué, diagonale comprise. Le pilote tombe pourtant sous −0,5. Donc il ne
## suit PAS la trajectoire qu'on croit : cette sonde imprime où il va vraiment.
##
## Reprend exactement la boucle du test — mêmes jalons, même conversion
## d'intention — et journalise la position toutes les N frames, plus les
## dix dernières avant la chute.
extends SceneTree

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const LOG_EVERY: int = 40


func _initialize() -> void:
	var valley: Node3D = (load(VALLEY) as PackedScene).instantiate() as Node3D
	root.add_child(valley)
	for i: int in range(5):
		await physics_frame
	for raider: Node in valley.find_children("*", "RaiderRed", true, false):
		raider.queue_free()
	for i: int in range(5):
		await physics_frame

	var player: Node3D = valley.call("player") as Node3D
	var intent: Object = ClassDB.instantiate("RefCounted")
	# `InputIntent` est une classe du projet ; on la charge par son nom.
	intent = load("res://scripts/components/input_intent.gd").new()
	player.call("set_intent_source", intent)
	for i: int in range(120):
		if player.call("is_on_floor"):
			break
		await physics_frame

	var waypoints: Array[Vector2] = [
		Vector2(14, 152), Vector2(26, 134), Vector2(36, 112), Vector2(27, 94),
		Vector2(18, 79), Vector2(28, 70), Vector2(40, 60), Vector2(40, 38),
		Vector2(36, 22), Vector2(20, 10), Vector2(12, -8),
	]
	var reached: int = 0
	var ticks: int = 0
	var recent: Array[String] = []
	print("[trajet] depart : %s" % _fmt(player.global_position))
	while reached < waypoints.size() and ticks < 3600:
		var target: Vector2 = waypoints[reached]
		var here: Vector2 = Vector2(player.global_position.x,
			player.global_position.z)
		var to_target: Vector2 = target - here
		if to_target.length() < 2.5:
			print("[trajet] jalon %d atteint (%s) a %d ticks, pos %s"
				% [reached, target, ticks, _fmt(player.global_position)])
			reached += 1
			continue
		intent.set("move", Vector2(to_target.x, -to_target.y).normalized())
		await physics_frame
		ticks += 1
		var line: String = "  t=%4d  pos %s  cible jalon %d %s  reste %.1f m" % [
			ticks, _fmt(player.global_position), reached, target,
			to_target.length()]
		recent.append(line)
		if recent.size() > 10:
			recent.remove_at(0)
		if ticks % LOG_EVERY == 0 and reached >= 8:
			print(line)
		if player.global_position.y < -0.5:
			print("[trajet] CHUTE sous -0.5 a t=%d, pos %s"
				% [ticks, _fmt(player.global_position)])
			print("[trajet] les dix dernieres frames :")
			for l: String in recent:
				print(l)
			break
	print("[trajet] fin : %d/%d jalons, %d ticks"
		% [reached, waypoints.size(), ticks])
	quit(0)


func _fmt(v: Vector3) -> String:
	return "(%.1f, %.2f, %.1f)" % [v.x, v.y, v.z]
