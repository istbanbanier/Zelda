## Atmosphère V4.1 — lumière chaude, brume étagée, orage LOCAL, éclair réel.
##
## Les règles V4 mesurées ici : l'orage n'assombrit QUE la zone citadelle (la
## crête de départ reste sous ciel ouvert), l'éclair FRAPPE réellement (état et
## lumière mesurés dans le temps, pas la présence d'un nœud), le soleil reste
## chaud avec ombres, la brume sépare les plans sans noyer le monde.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _cleanup(world: Node) -> void:
	_tree().root.remove_child(world)
	world.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


func test_the_storm_is_local_to_the_citadel_and_spares_the_crest() -> void:
	## Règle V4 n° 1 : nuages bornés, centrés sur la citadelle (z ≈ -215), et la
	## crête de départ (z = 150) est à PLUSIEURS rayons du bord du nuage.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var storm: StormCell = valley.get_node("CitadelStorm") as StormCell
	check_not_null(storm, "la cellule d'orage existe")
	check(storm.position.z < -180.0, "…au-dessus du plateau de la citadelle")
	var widest: float = 0.0
	var clouds: Array[Node] = storm.find_children("CloudLayer*", "MeshInstance3D",
		true, false)
	check(clouds.size() >= 3, "au moins trois couches de nuage")
	for cloud: Node in clouds:
		var sphere: SphereMesh = (cloud as MeshInstance3D).mesh as SphereMesh
		widest = maxf(widest, sphere.radius)
	check(widest <= StormCell.MAX_CLOUD_RADIUS,
		"rayon des couches borné (%.0f ≤ %.0f)" % [widest, StormCell.MAX_CLOUD_RADIUS])
	var spawn_xz: Vector2 = Vector2(0, 150)
	var storm_xz: Vector2 = Vector2(storm.position.x, storm.position.z)
	var clearance: float = spawn_xz.distance_to(storm_xz) - widest
	check(clearance > 150.0,
		"la crête reste sous ciel ouvert : %.0f m entre elle et le bord du nuage"
		% clearance)
	await _cleanup(valley)


func test_the_lightning_actually_strikes_then_rests() -> void:
	## L'éclair est un ÉVÉNEMENT mesuré : invisible au départ, il frappe dans la
	## première seconde (fenêtre déterministe couvrant la capture §21.8), allume
	## sa lumière, puis s'éteint — pas un mesh émissif laissé allumé.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	var storm: StormCell = valley.get_node("CitadelStorm") as StormCell
	check(not storm.is_flashing(), "au chargement : pas d'éclair")
	check_equal(storm.flash_light_energy(), 0.0, "…et lumière éteinte")

	var struck: bool = false
	for i: int in range(120):   # ≤ 2 s : la première frappe part à 0,6 s
		await _tree().physics_frame
		if storm.is_flashing():
			struck = true
			break
	check(struck, "l'éclair frappe dans les deux premières secondes")
	check(storm.flash_light_energy() > 1.0,
		"…avec une vraie lumière locale (%.1f)" % storm.flash_light_energy())
	var bolt: Node3D = storm.get_node("Bolt") as Node3D
	check(bolt.visible, "…et le tracé visible")
	check(bolt.get_child_count() >= 10,
		"tracé irrégulier en segments (cœur + halo), pas un trait unique")

	var rested: bool = false
	for i: int in range(90):   # la frappe dure 0,5 s
		await _tree().physics_frame
		if not storm.is_flashing():
			rested = true
			break
	check(rested, "l'éclair s'éteint après sa fenêtre")
	check_equal(storm.flash_light_energy(), 0.0, "…lumière rendue à zéro")
	check(not bolt.visible, "…tracé caché entre deux frappes")
	await _cleanup(valley)


func test_light_and_fog_serve_depth_without_drowning_the_valley() -> void:
	## Soleil chaud avec ombres, brume qui étage les plans (aerial perspective),
	## brume basse SOUS la crête — des valeurs mesurées, bornées, pas des drapeaux.
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var sun: DirectionalLight3D = valley.get_node("Sun") as DirectionalLight3D
	check(sun.light_color.r > sun.light_color.b + 0.2,
		"soleil CHAUD (r %.2f > b %.2f)" % [sun.light_color.r, sun.light_color.b])
	check(sun.shadow_enabled, "ombres directionnelles actives")
	check(sun.light_energy >= 1.0, "énergie pleine — le monde n'est jamais sombre")

	var environment: Environment = \
		(valley.get_node("ValleyEnvironment") as WorldEnvironment).environment
	check(environment.fog_enabled, "brume active")
	check(environment.fog_aerial_perspective > 0.3,
		"aerial perspective : les lointains fondent vers le ciel (profondeur)")
	check(environment.fog_density < 0.005,
		"densité bornée (%.4f) : la vallée reste lisible à 300 m" \
		% environment.fog_density)
	check(environment.fog_height < 20.0,
		"la brume basse vit dans les creux (y %.0f), sous la crête (y 24)"
		% environment.fog_height)
	check_equal(environment.tonemap_mode, Environment.TONE_MAPPER_FILMIC,
		"tonemapping filmic (§7.1 : hautes lumières sans plastique)")
	await _cleanup(valley)
