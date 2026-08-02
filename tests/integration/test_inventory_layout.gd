## ART-P0R.2 — cadrage de l'inventaire : centré et contenu, TROIS résolutions.
##
## La capture ART-P0 prouvait un panneau accroché en haut-gauche. Ici on
## MESURE le rect réel de la plaque contre le viewport à 1280×720, 1920×1080
## et 2560×1440 : centre à ±6 px du centre écran, panneau entièrement contenu,
## et jamais superposé à la carte d'arme du HUD (bas-droite).
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const SHELL: String = "res://scenes/ui/GameplayShell.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func test_the_inventory_plate_centers_at_three_resolutions() -> void:
	var window: Window = _tree().root
	var original_size: Vector2i = window.size
	var world: Node3D = Node3D.new()
	_tree().root.add_child(world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, 0)
	world.add_child(floor_body)
	var player: PlayerController = (load(PLAYER) as PackedScene).instantiate() \
		as PlayerController
	player.position = Vector3(0, 0.1, 0)
	world.add_child(player)
	var shell: GameplayShell = (load(SHELL) as PackedScene).instantiate() \
		as GameplayShell
	world.add_child(shell)
	await _settle(5)

	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080),
			Vector2i(2560, 1440)]:
		window.size = size
		await _settle(3)
		shell.toggle_inventory()
		await _settle(3)
		var plate: Control = shell.get_node("%InventoryPanel/Centerer/Plate") \
			as Control
		var rect: Rect2 = plate.get_global_rect()
		var viewport: Vector2 = Vector2(window.size)
		var offset: Vector2 = rect.get_center() - viewport * 0.5
		check(absf(offset.x) <= 6.0 and absf(offset.y) <= 6.0,
			"%s : plaque CENTRÉE (écart %.0f, %.0f — rect %s)"
			% [str(size), offset.x, offset.y, str(rect)])
		check(rect.position.x >= 0.0 and rect.position.y >= 0.0
			and rect.end.x <= viewport.x and rect.end.y <= viewport.y,
			"%s : plaque entièrement CONTENUE (rect %s)" % [str(size), str(rect)])
		check(rect.size.x > 500.0 and rect.size.y > 200.0,
			"%s : la plaque a une vraie taille (%s)" % [str(size), str(rect.size)])
		shell.toggle_inventory()
		await _settle(2)

	window.size = original_size
	await _settle(2)
	if _tree().paused:
		_tree().paused = false
	world.get_parent().remove_child(world)
	world.queue_free()
	await _settle(2)
