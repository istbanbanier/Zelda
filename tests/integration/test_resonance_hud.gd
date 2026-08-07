## PT-BRACELET-01 — Présentation du Bracelet de Résonance (P2 §3.8).
##
## Défaut mesuré en playtest : le Bracelet n'avait AUCUN retour en jeu. Hors
## de `ResonanceLab`, rien n'écoutait `revealed`, la cible retenue par le focus
## était invisible, l'étape « premier port retenu » d'un Arc Link en deux temps
## ne se voyait pas, et un refus partait muet dans la sonde de latence — un
## instrument de mesure que seul un overlay de laboratoire affiche. Le
## playtester ne pouvait pas distinguer « rien n'est parti » de « c'est parti
## et je n'ai pas vu la conséquence ».
##
## Contrats vérifiés ici : la plaque paraît pendant le focus et nomme l'action
## que le clic déclenchera ; la cible retenue est marquée à sa position écran ;
## le port en attente se voit ; un refus est écrit en français lisible ; et
## AUCUNE information ne repose sur la seule couleur (P3 §1.6) — l'anneau se
## ferme, le losange se double, le viseur se barre.
extends GateTestCase

const SHELL: String = "res://scenes/ui/GameplayShell.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"

var _root: Node3D = null
var _player: PlayerController = null
var _shell: GameplayShell = null
var _intent: InputIntent = null
var _resonance: ResonanceController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _idle(frames: int) -> void:
	for i: int in range(frames):
		await _tree().process_frame


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	_player = null
	_shell = null
	_intent = null
	_resonance = null


func _setup() -> bool:
	var tree: SceneTree = _tree()
	if tree == null:
		return false
	_root = Node3D.new()
	tree.root.add_child(_root)
	_root.add_child(_static_floor())
	var player_scene: PackedScene = load(PLAYER) as PackedScene
	var shell_scene: PackedScene = load(SHELL) as PackedScene
	if player_scene == null or shell_scene == null:
		return false
	_player = player_scene.instantiate() as PlayerController
	_root.add_child(_player)
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	_resonance = _player.resonance()
	_shell = shell_scene.instantiate() as GameplayShell
	_root.add_child(_shell)
	return true


func _static_floor() -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(80.0, 1.0, 80.0)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(0.0, -0.5, 0.0)
	return body


## Pose une cible EXACTEMENT dans l'axe de la caméra réelle : le test ne
## présume donc aucune orientation par défaut du rig.
##
## Un port doit être porté par un `ElectricNode` — `focus_confirm` transtype son
## ancre et répondrait `invalide` sur un `Node3D` nu.
func _target_in_front(kind: StringName) -> ResonanceTargetComponent:
	var camera: Camera3D = _player.camera_rig().get_camera()
	var forward: Vector3 = -camera.global_transform.basis.z
	var at: Vector3 = camera.global_position + forward * 6.0
	# Garde-fou : jamais sous le sol. Si ce relèvement sortait la cible du
	# cône, l'assertion de sélection le dirait — pas un vert silencieux.
	at.y = maxf(at.y, 0.8)
	var holder: Node3D = null
	if kind == &"port":
		var node: ElectricNode = ElectricNode.new()
		node.kind = ElectricNode.Kind.SOURCE
		node.node_id = &"test.hud.port.01"
		holder = node
	else:
		holder = Node3D.new()
	_root.add_child(holder)
	holder.global_position = at
	var component: ResonanceTargetComponent = ResonanceTargetComponent.new()
	component.kind = kind
	holder.add_child(component)
	return component


func test_the_shell_binds_the_bracelet_of_its_own_player() -> void:
	if not _setup():
		check(false, "mise en scène impossible")
		return
	await _settle(4)
	check(_shell.bound_player() == _player, "le shell suit le joueur de sa scène")
	check(_resonance != null, "le joueur expose son ResonanceController")
	check(not _shell.is_resonance_plaque_visible(),
		"au repos, la plaque reste masquée (§17.2 : masquer l'inutile)")
	_teardown()


func test_a_refusal_is_written_in_plain_language() -> void:
	## Le cœur du défaut : un refus n'existait que dans la sonde de latence.
	if not _setup():
		check(false, "mise en scène impossible")
		return
	await _settle(4)
	_player.resonance_verdict.emit(&"resonance_confirm", &"trop_loin", false)
	await _idle(3)
	check(_shell.is_resonance_plaque_visible(), "un refus fait paraître la plaque")
	check(_shell.resonance_state_text().contains("écartés"),
		"…et il est écrit en français, pas en code (« %s »)"
			% _shell.resonance_state_text())
	_teardown()


func test_an_unknown_verdict_is_shown_raw_rather_than_swallowed() -> void:
	## Mieux vaut un mot brut qu'un silence : c'est le silence qui a coûté
	## le playtest. Une table incomplète ne doit jamais redevenir muette.
	if not _setup():
		check(false, "mise en scène impossible")
		return
	await _settle(4)
	_player.resonance_verdict.emit(&"resonance_confirm", &"verdict_inedit", false)
	await _idle(3)
	check(_shell.resonance_state_text().contains("verdict_inedit"),
		"un verdict hors table s'affiche tel quel (« %s »)"
			% _shell.resonance_state_text())
	_teardown()


func test_the_focus_names_the_action_and_closes_the_ring() -> void:
	if not _setup():
		check(false, "mise en scène impossible")
		return
	await _settle(4)
	_intent.focus_held = true
	await _settle(4)
	check(_resonance.focus_active(), "le focus tenu est bien engagé")
	await _idle(2)
	check(_shell.is_resonance_plaque_visible(),
		"la plaque paraît dès le focus, même sans cible")
	check(_shell.resonance_state_text().contains("Aucune cible"),
		"sans cible, le HUD dit POURQUOI rien ne partira (« %s »)"
			% _shell.resonance_state_text())
	check(not _shell.resonance_overlay().is_ring_closed(),
		"l'anneau reste ouvert tant qu'aucune cible n'est retenue")
	# Une cible entre dans l'axe : l'anneau se ferme et l'action se nomme.
	_target_in_front(&"port")
	await _settle(4)
	await _idle(2)
	check(_resonance.focus_selected() != null,
		"la cible posée dans l'axe de la caméra est retenue")
	check(_shell.resonance_action_text().contains("Arc Link"),
		"le HUD nomme l'action du clic (« %s »)" % _shell.resonance_action_text())
	check(_shell.resonance_overlay().is_ring_closed(),
		"l'anneau se REFERME — lisible sans la couleur")
	_teardown()


func test_the_pending_port_of_a_two_step_link_is_visible() -> void:
	## L'étape qui perdait les joueurs : après le premier clic, plus rien à
	## l'écran ne disait qu'un port attendait son second — ni qu'il fallait
	## garder G.
	if not _setup():
		check(false, "mise en scène impossible")
		return
	await _settle(4)
	_intent.focus_held = true
	await _settle(4)
	_target_in_front(&"port")
	await _settle(4)
	if _resonance.focus_selected() == null:
		check(false, "la cible n'est pas retenue : mise en scène invalide")
		_teardown()
		return
	var verdict: StringName = _resonance.focus_confirm(_player, false)
	check(verdict == &"port_a", "premier clic : port A retenu (obtenu %s)" % verdict)
	await _settle(2)
	await _idle(2)
	check(_shell.resonance_state_text().contains("Port retenu"),
		"le port en attente est ANNONCÉ (« %s »)" % _shell.resonance_state_text())
	check(_shell.resonance_state_text().contains("G"),
		"…avec la consigne qui manquait : ne pas lâcher G")
	check(_shell.resonance_overlay().is_mark_doubled(),
		"le losange se DOUBLE sur le port retenu — lisible sans la couleur")
	_teardown()


func test_a_pulse_says_how_many_targets_it_revealed() -> void:
	## Le Pulse ne montrait rien du tout hors du laboratoire.
	if not _setup():
		check(false, "mise en scène impossible")
		return
	await _settle(4)
	_resonance.pulse_fired.emit(3)
	await _idle(3)
	check(_shell.resonance_state_text().contains("3"),
		"le Pulse annonce son résultat (« %s »)" % _shell.resonance_state_text())
	_resonance.pulse_fired.emit(0)
	await _idle(3)
	check(_shell.resonance_state_text().contains("aucune"),
		"…y compris quand il ne révèle rien (« %s »)"
			% _shell.resonance_state_text())
	_teardown()


func test_the_overlay_redraws_only_on_change() -> void:
	## Règle CLAUDE.md : aucun travail inutile par frame. Le viseur suit la
	## visée à chaque image, mais son TRACÉ ne se refait qu'au changement.
	var overlay: ResonanceOverlay = ResonanceOverlay.new()
	check(overlay.apply_state(true, true, true, Vector2(100.0, 80.0), false, false),
		"un premier état demande un tracé")
	check(not overlay.apply_state(true, true, true, Vector2(100.0, 80.0), false,
		false), "le même état ne redemande RIEN")
	check(overlay.apply_state(true, true, true, Vector2(140.0, 80.0), false, false),
		"une cible qui bouge à l'écran redemande un tracé")
	check(overlay.apply_state(true, true, true, Vector2(140.0, 80.0), true, false),
		"le port retenu redemande un tracé")
	check(overlay.is_mark_doubled(), "…et double la marque")
	overlay.free()
