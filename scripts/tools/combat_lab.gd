## CombatLab (MASTER_SPEC §10.8) — embryon, complété au fil de la Phase C.
##
## Déjà présent : mannequins, panneau d'état (phase, index de combo, temps dans
## l'action, santé des cibles), journal des événements de coup. À venir avec les
## systèmes qu'ils instrumentent : timeline startup/actif/recovery dessinée,
## historique d'inputs avec raisons de rejet, scénarios rejoués, export CSV.
extends Node3D

@onready var _player: PlayerController = $Player
@onready var _readout: Label = $DebugUI/Readout

var _events: Array[String] = []
var _phase_names: Dictionary = {
	AttackControllerComponent.Phase.IDLE: "idle",
	AttackControllerComponent.Phase.STARTUP: "STARTUP",
	AttackControllerComponent.Phase.ACTIVE: "ACTIF",
	AttackControllerComponent.Phase.RECOVERY: "RECOVERY",
}


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var attack: AttackControllerComponent = _player.attack_controller()
	attack.attack_started.connect(func(d: AttackDefinition, i: int) -> void:
		_log("coup %d : %s" % [i + 1, d.id]))
	attack.attack_finished.connect(func() -> void: _log("combo terminé"))
	var hitbox: HitboxComponent = _player.get_node("VisualRoot/WeaponHitbox")
	hitbox.hit_confirmed.connect(func(e: DamageEvent, _t: HurtboxComponent) -> void:
		_log("touche : %.1f dégâts (id %d)" % [e.amount, e.attack_id]))
	for dummy: CombatDummy in get_tree().get_nodes_in_group("enemies"):
		dummy.dummy_died.connect(func() -> void: _log("mannequin à terre"))
	print("[combat_lab] clic gauche : attaque. Échap : souris. §10.8 — instrumentation partielle, complétée au fil de la Phase C.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE \
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED


func _log(message: String) -> void:
	_events.append(message)
	if _events.size() > 8:
		_events.pop_front()


func _process(_delta: float) -> void:
	var attack: AttackControllerComponent = _player.attack_controller()
	var lines: Array[String] = []
	lines.append("phase %s · coup %d/3 · t=%.2fs" % [
		_phase_names.get(attack.phase(), "?"), attack.combo_index() + 1, attack.elapsed()])
	for dummy: CombatDummy in get_tree().get_nodes_in_group("enemies"):
		lines.append("%s : %.0f / %.0f PV" % [dummy.name,
			dummy.health().current(), dummy.health().maximum()])
	lines.append("— derniers événements —")
	lines.append_array(_events)
	_readout.text = "\n".join(lines)
