## P2-4 — Bassin conducteur (bible §3.4, P3 §24.4) : l'enseignement
## eau×électricité AVANT la salle 4 du donjon. Fail-first : écrit avant
## `ConductiveBasin`.
##
## Contrats : le circuit est PRÉ-ARRANGÉ avec UN maillon manquant — la
## source est trop loin de l'eau pour que les ports se touchent ; un seul
## Arc Link (source→eau) complète : source → lien → EAU → récepteur. Le
## courant TRAVERSE l'eau (le point de la leçon), la conséquence s'allume,
## et dissoudre le lien rend tout — le lien transporte, il ne crée pas.
extends GateTestCase

var _root: Node3D = null
var _basin: ConductiveBasin = null
var _player: PlayerController = null
var _resonance: ResonanceController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	_basin = null
	_player = null
	_resonance = null


func _setup() -> bool:
	var tree: SceneTree = _tree()
	if tree == null:
		return false
	_root = Node3D.new()
	tree.root.add_child(_root)
	_basin = ConductiveBasin.new()
	_root.add_child(_basin)
	var player_scene: PackedScene = load("res://scenes/player/Player.tscn") as PackedScene
	_player = player_scene.instantiate() as PlayerController
	_root.add_child(_player)
	_player.global_position = _basin.stand_point()
	_resonance = _player.get_node("Components/ResonanceController") as ResonanceController
	return true


func test_the_circuit_waits_with_one_missing_link() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	for i: int in range(10):
		await tree.physics_frame
	check(_basin.source() != null and _basin.source().is_emitting(),
		"la source est là, active")
	check(not _basin.receiver().is_powered(),
		"le récepteur attend : le maillon source→eau manque")
	# Les deux bouts du maillon manquant sont ciblables au Bracelet.
	var markers: int = 0
	for node: ElectricNode in [_basin.source(), _basin.water()]:
		for child: Node in node.get_children():
			var target: ResonanceTargetComponent = child as ResonanceTargetComponent
			if target != null and target.kind == &"port":
				markers += 1
	check(markers == 2, "source et eau portent leur marqueur de port (%d/2)" % markers)
	_teardown()


func test_one_link_completes_the_circuit_through_the_water() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	for i: int in range(10):
		await tree.physics_frame
	var verdict: StringName = _resonance.try_link(_player, _basin.source(), _basin.water())
	check(verdict == &"linked", "UN Arc Link source→eau (obtenu %s)" % verdict)
	await tree.physics_frame
	await tree.physics_frame
	check(_basin.water().is_powered(), "l'eau est TRAVERSÉE par le courant — la leçon")
	check(_basin.receiver().is_powered(), "…et le récepteur s'allume au bout")
	# Dissoudre rend tout : transport, jamais création.
	_resonance.cancel_link()
	await tree.physics_frame
	await tree.physics_frame
	check(not _basin.receiver().is_powered(),
		"lien dissous : le récepteur s'éteint (aucune énergie créée)")
	_teardown()
