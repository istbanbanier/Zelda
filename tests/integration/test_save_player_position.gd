## Régression S2 (playtest externe no1) : « Continuer » rechargeait la partie
## mais replaçait le joueur sur la crête de départ — `_apply_save()` restaurait
## découvertes, armes, flèches, coffres et pickups, JAMAIS la position du
## joueur, et l'instantané ne l'écrivait pas non plus. §19.1 exige
## « position/rotation sûre du joueur » dans la sauvegarde ; §19.4 exige
## « placer joueur au transform sûr » et « si position invalide, utiliser
## checkpoint ». Le fichier de sauvegarde est une ENTRÉE NON FIABLE : il peut
## avoir été édité à la main.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const SLOT: String = "slot0"
## Palier de la descente (l'herbe d'endurance y pousse en (35, 16, 109)) :
## sol réel, plat, loin du camp et de ses pillards — un point de reprise
## crédible et sans interférence de combat pendant les frames de repos.
const AWAY_POSITION: Vector3 = Vector3(35.0, 16.6, 109.0)
const SAVED_YAW: float = 2.0


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _save_system() -> Node:
	return _tree().root.get_node_or_null("/root/SaveSystem")


func _clear_save() -> void:
	var system: Node = _save_system()
	if system == null:
		return
	var path: String = String(system.call("slot_path", SLOT))
	for candidate: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _load_valley() -> ValleyWorld:
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)
	return valley


func _cleanup(world: Node) -> void:
	_tree().root.remove_child(world)
	world.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


## Le point d'apparition documenté de la vallée — lu sur la scène elle-même,
## pas recopié en dur : si le level design déplace la crête, le test suit.
func _spawn_of(valley: ValleyWorld) -> Vector3:
	return (valley.get_node("SpawnPoint") as Node3D).global_position


func test_reload_restores_player_position_and_yaw() -> void:
	## Le défaut S2 exactement : jouer, s'éloigner de la crête, sauvegarder,
	## recharger — le joueur doit reprendre OÙ IL ÉTAIT, pas au spawn.
	_clear_save()
	var valley: ValleyWorld = await _load_valley()
	var player: PlayerController = valley.player()
	var spawn: Vector3 = _spawn_of(valley)
	player.global_position = AWAY_POSITION
	player.reset_physics_interpolation()
	var visual: Node3D = player.get_node("VisualRoot") as Node3D
	visual.rotation.y = SAVED_YAW
	await _settle(8)   # le corps se pose sur le sol du palier
	var rested: Vector3 = player.global_position
	check(rested.distance_to(spawn) > 20.0,
		"précondition : le joueur a réellement quitté le spawn (%.1f m)"
		% rested.distance_to(spawn))
	# L'instantané — le même que celui d'une transition sortante ou d'un
	# retour menu (`_on_transition_started` ne fait qu'appeler `_autosave`).
	valley._autosave()
	await _cleanup(valley)

	var reloaded: ValleyWorld = await _load_valley()
	var back: PlayerController = reloaded.player()
	check(back.global_position.distance_to(rested) < 1.5,
		"« Continuer » replace le joueur où il était (écart %.2f m, attendu < 1,5)"
		% back.global_position.distance_to(rested))
	check(back.global_position.distance_to(spawn) > 20.0,
		"…et PAS sur la crête de départ — le défaut S2 (%.1f m du spawn)"
		% back.global_position.distance_to(spawn))
	var back_visual: Node3D = back.get_node("VisualRoot") as Node3D
	check_approx(back_visual.rotation.y, SAVED_YAW, 0.15,
		"le lacet (rotation) du joueur est restauré")
	await _cleanup(reloaded)
	_clear_save()


func test_invalid_saved_positions_fall_back_to_spawn() -> void:
	## §19.4 : « si position invalide, utiliser checkpoint ». Le fichier peut
	## être édité à la main — hors monde, sous le terrain ou de type absurde,
	## la reprise retombe proprement sur le point d'apparition, sans crash.
	var invalid_positions: Array[Variant] = [
		{"x": 5000.0, "y": 6.0, "z": 0.0},     # hors des bornes du monde
		{"x": 0.0, "y": -40.0, "z": 0.0},      # sous le plancher de secours
		"corrompu",                            # type absurde (fichier édité)
	]
	for raw_position: Variant in invalid_positions:
		_clear_save()
		var system: Node = _save_system()
		system.call("save_slot", SLOT, {
			"schema": 3,
			"checkpoint": "valley.camp.start",
			"player_position": raw_position,
			"player_yaw": "nord",              # le lacet aussi est non fiable
			"boss_defeated": false,
		})
		var valley: ValleyWorld = await _load_valley()
		var player: PlayerController = valley.player()
		check(player.global_position.distance_to(_spawn_of(valley)) < 2.0,
			"position invalide %s → reprise au point d'apparition (%.1f m)"
			% [str(raw_position), player.global_position.distance_to(_spawn_of(valley))])
		await _cleanup(valley)
	_clear_save()


func test_legacy_save_without_position_still_loads_at_spawn() -> void:
	## §19.4 : une sauvegarde ANCIENNE (schéma 2, d'avant ce champ) se charge
	## sans erreur — l'inventaire s'applique, et l'absence de position signifie
	## « position inconnue » : reprise au point d'apparition documenté.
	_clear_save()
	var system: Node = _save_system()
	var path: String = String(system.call("slot_path", SLOT))
	# Enveloppe écrite À LA MAIN en version 2 : le chemin de migration réel
	# est traversé, pas simulé — `save_slot` écrirait la version courante.
	var envelope: Dictionary = {
		"schema_version": 2,
		"slot": SLOT,
		"saved_at_utc": "2026-01-01T00:00:00",
		"data": {
			"schema": 2,
			"checkpoint": "valley.camp.start",
			"weapons": [{"id": "worn_sword", "durability": 19}],
			"equipped_index": 0,
			"arrows": 5,
			"boss_defeated": false,
		},
	}
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	check_not_null(file, "le fichier de sauvegarde artisanal s'écrit")
	file.store_string(JSON.stringify(envelope, "  "))
	file.close()

	var valley: ValleyWorld = await _load_valley()
	var player: PlayerController = valley.player()
	check_equal(player.inventory().equipped().current_durability, 19,
		"la sauvegarde de schéma 2 s'applique toujours (durabilité)")
	check_equal(player.inventory().arrows(), 5,
		"…et les flèches aussi")
	check(player.global_position.distance_to(_spawn_of(valley)) < 2.0,
		"sans champ position : reprise au point d'apparition (%.1f m)"
		% player.global_position.distance_to(_spawn_of(valley)))
	await _cleanup(valley)
	_clear_save()
