## P2-4c — Placement du pont magnétique dans la vallée (route des ruines).
## Fail-first : écrit avant l'implantation.
##
## Le site (−34, 3, 44, lacet 90°) sort de la SONDE `probe_bridge_site.gd`
## (plaine plate à y = 2,00, écart 0,00 sur l'emprise 20 × 6 m — rives posées
## sur le sol, jamais enterrées ni flottantes). Le lieu est déclaré comme un
## vrai POI (§19.3) avec son ancrage de récompense (PUZZLE) — l'ordre
## d'extension §3 interdit un lieu sans récompense.
extends GateTestCase

const SITE: Vector3 = Vector3(-34.0, 3.0, 44.0)

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null


func test_the_bridge_stands_on_the_ruins_route_as_a_declared_place() -> void:
	var tree: SceneTree = _tree()
	_root = Node3D.new()
	tree.root.add_child(_root)
	var relics: Node3D = ValleyRelics.new()
	_root.add_child(relics)
	await tree.physics_frame
	var site: Node3D = relics.get_node_or_null("PontMagnetique") as Node3D
	check(site != null, "le site du pont existe")
	if site == null:
		_teardown()
		return
	check(site.position.distance_to(SITE) < 0.1,
		"posé au site sondé (−34, 3, 44)")
	check(absf(fmod(site.rotation_degrees.y, 180.0)) - 90.0 < 0.1
		and absf(fmod(site.rotation_degrees.y, 180.0)) - 90.0 > -0.1,
		"lacet 90° (la travée croise la route)")
	var bridge: MagneticBridge = null
	for child: Node in site.get_children():
		if child is MagneticBridge:
			bridge = child as MagneticBridge
	check(bridge != null, "le diorama MagneticBridge est monté")
	if bridge == null:
		_teardown()
		return
	check(not bridge.is_locked(), "à découvrir : pas encore verrouillé")
	var state: MaterialStateComponent = null
	for child: Node in bridge.deck().get_children():
		if child is MaterialStateComponent:
			state = child as MaterialStateComponent
	check(state != null and state.is_charged() and not state.charge_decay_enabled,
		"le tablier attend le joueur, chargé sans fuite")
	# POI déclaré (§19.3) avec ancrage de récompense.
	var poi_found: bool = false
	for poi: PointOfInterest in relics.pois:
		if poi.poi_id == &"valley.poi.magnetic_bridge.01":
			poi_found = true
	check(poi_found, "POI valley.poi.magnetic_bridge.01 déclaré")
	check(site.find_children("*", "RewardAnchor", true, false).size() >= 1,
		"un ancrage de récompense est posé (lieu sans récompense interdit)")
	_teardown()
