## P2-2 — lois matière : matrice minimale du Gate ReactionSystem (P2 §4.6).
##
## Fail-first : écrit AVANT l'implémentation. Couvre eau×électricité,
## métal×charge×terre, bois×chaleur×eau, céramique×impact, double source
## (plafond d'énergie), chaîne cyclique et budget par tick. Les profils sont
## construits en code : les .tres canoniques suivent quand les lois tiennent.
extends GateTestCase

var _root: Node3D = null
var _system: ReactionSystem = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _setup() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	_system = ReactionSystem.new()
	_root.add_child(_system)


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	_system = null


func _profile(id: StringName, conductivity: float, capacity: float,
		flammability: float, fragility: float, absorbs: bool) -> MaterialProfile:
	var profile: MaterialProfile = MaterialProfile.new()
	profile.id = id
	profile.conductivity = conductivity
	profile.charge_capacity = capacity
	profile.flammability = flammability
	profile.fragility = fragility
	profile.absorbs_water = absorbs
	return profile


func _target(profile: MaterialProfile) -> MaterialStateComponent:
	var body: Node3D = Node3D.new()
	_root.add_child(body)
	var state: MaterialStateComponent = MaterialStateComponent.new()
	state.profile = profile
	body.add_child(state)
	return state


func test_wood_ignites_dry_refuses_wet_and_water_extinguishes() -> void:
	_setup()
	var wood: MaterialStateComponent = _target(_profile(&"bois", 0.05, 0.0, 0.8, 0.4, true))
	# Sec + chaleur suffisante → s'enflamme.
	var burn: PackedStringArray = _system.resolve_now(wood.get_parent(),
		_heat_packet(3.0, &"feu_1"))
	check("enflamme" in burn, "le bois sec s'enflamme (résultat : %s)" % str(burn))
	check(wood.is_burning(), "l'état burning est actif")
	# L'eau éteint.
	var douse: PackedStringArray = _system.resolve_now(wood.get_parent(),
		_wet_packet(1.0, &"eau_1"))
	check("mouille" in douse, "l'eau mouille")
	check(not wood.is_burning(), "l'eau a éteint le feu (P2 §4.2)")
	# Mouillé + chaleur → refus.
	var refuse: PackedStringArray = _system.resolve_now(wood.get_parent(),
		_heat_packet(3.0, &"feu_2"))
	check("humide_refuse" in refuse, "le bois mouillé refuse l'ignition")
	_teardown()


func test_metal_stores_charge_wet_couples_better_and_ground_drains() -> void:
	_setup()
	var metal_profile: MaterialProfile = _profile(&"metal", 0.9, 10.0, 0.0, 0.0, false)
	var dry: MaterialStateComponent = _target(metal_profile)
	var wet: MaterialStateComponent = _target(metal_profile)
	wet.soak()
	_system.resolve_now(dry.get_parent(), ElementPacket.electric_burst(2.0, &"arc_a"))
	_system.resolve_now(wet.get_parent(), ElementPacket.electric_burst(2.0, &"arc_b"))
	check(dry.charge() > 0.0, "le métal sec stocke la charge")
	check(wet.charge() > dry.charge(),
		"le couplage mouillé reçoit plus (%.2f > %.2f)" % [wet.charge(), dry.charge()])
	dry.ground()
	check(dry.charge() == 0.0, "la mise à la terre draine tout")
	check(dry.is_grounded(), "l'état grounded est actif")
	var during_ground: PackedStringArray = _system.resolve_now(dry.get_parent(),
		ElementPacket.electric_burst(2.0, &"arc_c"))
	check("dissipe" in during_ground, "un apport pendant grounded se dissipe")
	check(dry.charge() == 0.0, "rien ne s'accumule pendant grounded")
	_teardown()


func test_two_sources_never_exceed_capacity_no_energy_created() -> void:
	_setup()
	var metal: MaterialStateComponent = _target(_profile(&"metal", 0.9, 5.0, 0.0, 0.0, false))
	_system.resolve_now(metal.get_parent(), ElementPacket.electric_burst(4.0, &"src_a"))
	_system.resolve_now(metal.get_parent(), ElementPacket.electric_burst(4.0, &"src_b"))
	check(metal.charge() <= 5.0,
		"le stock est plafonné par la capacité (%.2f ≤ 5)" % metal.charge())
	_teardown()


func test_ceramic_fractures_at_threshold_stone_endures() -> void:
	_setup()
	var ceramic_profile: MaterialProfile = _profile(&"ceramique", 0.0, 0.0, 0.0, 0.9, false)
	ceramic_profile.fracture_threshold = 8.0
	var ceramic: MaterialStateComponent = _target(ceramic_profile)
	var weak_hit: PackedStringArray = _system.resolve_now(ceramic.get_parent(),
		ElementPacket.impact(4.0, &"coup_faible"))
	check("encaisse" in weak_hit, "sous le seuil : encaisse")
	check(not ceramic.is_fractured(), "pas de fracture sous le seuil")
	var strong_hit: PackedStringArray = _system.resolve_now(ceramic.get_parent(),
		ElementPacket.impact(9.0, &"coup_fort"))
	check("fracture" in strong_hit, "au-dessus du seuil : fracture")
	check(ceramic.is_fractured(), "l'état fractured est actif")
	var stone: MaterialStateComponent = _target(_profile(&"pierre", 0.0, 0.0, 0.0, 0.0, false))
	var stone_hit: PackedStringArray = _system.resolve_now(stone.get_parent(),
		ElementPacket.impact(50.0, &"coup_pierre"))
	check("encaisse" in stone_hit and not stone.is_fractured(),
		"la pierre (fragilité 0) est incassable par impact")
	_teardown()


func test_a_cyclic_chain_touches_each_target_once() -> void:
	_setup()
	var metal_profile: MaterialProfile = _profile(&"metal", 0.9, 10.0, 0.0, 0.0, false)
	var a: MaterialStateComponent = _target(metal_profile)
	var b: MaterialStateComponent = _target(metal_profile)
	var packet: ElementPacket = ElementPacket.electric_burst(2.0, &"boucle")
	var first: PackedStringArray = _system.resolve_now(a.get_parent(), packet)
	var second: PackedStringArray = _system.resolve_now(b.get_parent(), packet.attenuated(0.8))
	# Le cycle revient sur A avec la MÊME action : refus.
	var back: PackedStringArray = _system.resolve_now(a.get_parent(), packet.attenuated(0.6))
	check("charge" in first and "charge" in second, "la chaîne A→B a chargé les deux")
	check("deja_touche" in back, "le retour du cycle sur A est refusé (anti-boucle §4.3)")
	var charge_after: float = a.charge()
	# Une NOUVELLE action retouche A normalement.
	var fresh: PackedStringArray = _system.resolve_now(a.get_parent(),
		ElementPacket.electric_burst(1.0, &"boucle_2"))
	check("charge" in fresh and a.charge() > charge_after, "une nouvelle action repasse")
	_teardown()


func test_the_per_tick_budget_defers_overflow_without_losing_packets() -> void:
	_setup()
	var tree: SceneTree = _tree()
	var metal_profile: MaterialProfile = _profile(&"metal", 0.9, 500.0, 0.0, 0.0, false)
	var targets: Array[MaterialStateComponent] = []
	for i: int in range(120):
		targets.append(_target(metal_profile))
	var resolved: Array[int] = [0]
	_system.reaction_resolved.connect(
		func(_t: Node, _r: PackedStringArray, _p: ElementPacket) -> void: resolved[0] += 1)
	for i: int in range(120):
		_system.submit(targets[i].get_parent(),
			ElementPacket.electric_burst(0.5, StringName("salve_%d" % i)))
	await tree.physics_frame
	await tree.physics_frame
	var after_first_ticks: int = resolved[0]
	check(after_first_ticks <= ReactionSystem.PACKETS_PER_TICK * 2,
		"le budget par tick est respecté (%d résolus en ≤ 2 ticks utiles)" % after_first_ticks)
	check(_system.pending_count() > 0, "le surplus attend en file, il n'est pas perdu")
	for i: int in range(6):
		await tree.physics_frame
	check(resolved[0] == 120, "tout finit par être résolu (%d/120)" % resolved[0])
	_teardown()


func _heat_packet(amount: float, action: StringName) -> ElementPacket:
	var packet: ElementPacket = ElementPacket.new()
	packet.heat = amount
	packet.action_id = action
	return packet


func _wet_packet(amount: float, action: StringName) -> ElementPacket:
	var packet: ElementPacket = ElementPacket.new()
	packet.wetness = amount
	packet.action_id = action
	return packet
