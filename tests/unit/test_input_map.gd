## Verrouille l'InputMap et les couches de collision (MASTER_SPEC §8.5, §5.7).
##
## L'invariant « AZERTY prioritaire, Q = gauche » est le plus facile à casser sans
## s'en apercevoir : il ne se voit qu'en jouant sur un clavier AZERTY. Il est donc
## testé ici, pas seulement documenté.
extends GateTestCase

# Relevées dans /opt/src/godot/core/os/keyboard.h (tag 4.7.1-stable).
const KEY_SPECIAL: int = 1 << 22
const KEY_A: int = 0x41  # position QWERTY « A » = touche « Q » sur AZERTY
const KEY_Q: int = 0x51  # étiquette logique « Q »
const KEY_W: int = 0x57  # position QWERTY « W » = touche « Z » sur AZERTY
const KEY_S: int = 0x53
const KEY_D: int = 0x44
const KEY_C: int = 0x43
const KEY_SPACE: int = 0x20
const KEY_ESCAPE: int = KEY_SPECIAL | 0x01

const EXPECTED_ACTIONS: Array[String] = [
	"move_forward", "move_left", "move_back", "move_right",
	"jump", "sprint", "interact",
	"attack_light", "attack_heavy", "aim", "shoot", "dodge",
	"lock_on", "target_prev", "target_next",
	"inventory", "quick_meal", "pause",
]

const EXPECTED_LAYERS: Array[String] = [
	"World Static", "Player", "Enemy", "Player Hitbox", "Enemy Hitbox",
	"Hurtbox", "Projectile", "Physics Prop", "Interactable", "Climb Probe",
	"Conductive", "Water Danger", "Navigation Obstacle", "Camera Collision",
]


func _physical_keycodes(action: String) -> Array[int]:
	var codes: Array[int] = []
	if not InputMap.has_action(action):
		return codes
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			codes.append((event as InputEventKey).physical_keycode)
	return codes


func _has_joypad_event(action: String) -> bool:
	if not InputMap.has_action(action):
		return false
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false


func test_all_expected_actions_exist() -> void:
	for action: String in EXPECTED_ACTIONS:
		check(InputMap.has_action(action), "action manquante dans l'InputMap : %s" % action)


func test_no_action_is_empty() -> void:
	for action: String in EXPECTED_ACTIONS:
		if not InputMap.has_action(action):
			continue
		check(InputMap.action_get_events(action).size() > 0,
			"action sans aucun événement : %s" % action)


func test_azerty_q_moves_left() -> void:
	## INVARIANT NON NÉGOCIABLE. `physical_keycode = KEY_A` désigne la position
	## physique qui porte l'étiquette « Q » sur un clavier AZERTY et « A » sur un
	## QWERTY : une seule liaison sert les deux dispositions, conformément à §8.5.
	var left: Array[int] = _physical_keycodes("move_left")
	check(left.has(KEY_A),
		"« gauche » doit être lié à la position physique QWERTY-A (= Q en AZERTY) ; obtenu %s"
		% str(left))


func test_lock_on_never_uses_the_azerty_q_position() -> void:
	## §8.5 : « Q signifie impérativement gauche. Ne jamais l'utiliser pour le lock-on. »
	var lock: Array[int] = _physical_keycodes("lock_on")
	check(not lock.has(KEY_A),
		"le lock-on occupe la position AZERTY « Q » — interdit par §8.5 ; obtenu %s" % str(lock))
	check(not lock.has(KEY_Q),
		"le lock-on utilise l'étiquette logique « Q » — interdit par §8.5 ; obtenu %s" % str(lock))
	check(lock.has(KEY_C), "le lock-on doit être sur « C » ; obtenu %s" % str(lock))


func test_movement_uses_zqsd_positions() -> void:
	check(_physical_keycodes("move_forward").has(KEY_W),
		"« avancer » doit être sur la position QWERTY-W (= Z en AZERTY)")
	check(_physical_keycodes("move_back").has(KEY_S), "« reculer » doit être sur S")
	check(_physical_keycodes("move_right").has(KEY_D), "« droite » doit être sur D")


func test_no_physical_key_is_bound_to_two_actions() -> void:
	## Une même position physique sur deux actions produit des conflits invisibles.
	var owner_of: Dictionary = {}
	for action: String in EXPECTED_ACTIONS:
		for code: int in _physical_keycodes(action):
			if owner_of.has(code):
				check(false, "position physique %d partagée par « %s » et « %s »"
					% [code, owner_of[code], action])
			else:
				owner_of[code] = action
	check(owner_of.size() > 0, "aucune touche physique liée — InputMap vide ?")


func test_core_actions_have_gamepad_bindings() -> void:
	## §23.1 : clavier AZERTY **et** manette fonctionnels.
	for action: String in EXPECTED_ACTIONS:
		check(_has_joypad_event(action), "action sans liaison manette : %s" % action)


func test_essential_keys_are_bound() -> void:
	check(_physical_keycodes("jump").has(KEY_SPACE), "saut doit être sur Espace")
	check(_physical_keycodes("pause").has(KEY_ESCAPE), "pause doit être sur Échap")


func test_collision_layers_are_named() -> void:
	## §5.7 : couches nommées. Une couche sans nom devient un numéro magique.
	for i: int in range(EXPECTED_LAYERS.size()):
		var key: String = "layer_names/3d_physics/layer_%d" % (i + 1)
		check_equal(String(ProjectSettings.get_setting(key, "")), EXPECTED_LAYERS[i],
			"couche de collision %d" % (i + 1))
