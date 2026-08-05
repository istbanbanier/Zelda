## Overlay de laboratoire P2-1 (P2 §5.7) — état, vitesses, endurance, timers de
## fenêtre et latences instrumentées de la sonde (`LatencyProbe`).
##
## À poser comme enfant direct d'une scène de lab (TraversalSandbox, CombatLab).
## Il retrouve le joueur par le groupe `player` ; sans joueur, il s'éteint. Debug
## de développement uniquement : jamais dans un build final (§15.11 — l'outil
## n'est référencé par aucune scène du chemin critique du jeu).
class_name LabOverlay
extends CanvasLayer

## Coin haut-gauche du bloc de texte — décalable quand la scène a déjà un
## readout au même endroit (CombatLab).
@export var top_left: Vector2 = Vector2(8.0, 8.0)

var _label: Label = null
var _player: PlayerController = null
var _reader: PlayerInputReader = null


func _ready() -> void:
	layer = 90
	_label = Label.new()
	_label.position = top_left
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.92, 0.96, 0.9))
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)
	# Le joueur peut apparaître après cet overlay : re-tenter au premier tick.
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_locate_player()
		if _player == null:
			_label.text = "LabOverlay : aucun joueur dans le groupe `player`"
			return
	var lines: PackedStringArray = PackedStringArray()
	var mode_names: PackedStringArray = PackedStringArray([
		"LOCOMOTION", "CLIMBING", "MANTLING", "ATTACKING", "DODGING", "HURT", "DEAD",
	])
	var mode_index: int = int(_player.mode())
	var mode_name: String = mode_names[mode_index] if mode_index < mode_names.size() else str(mode_index)
	lines.append("mode: %s   sol: %s" % [mode_name, "oui" if _player.is_on_floor() else "non"])
	var v: Vector3 = _player.velocity
	lines.append("v: (%.2f, %.2f, %.2f)  |xz|: %.2f m/s" % [v.x, v.y, v.z, Vector2(v.x, v.z).length()])
	var stamina: StaminaComponent = _player.get_node_or_null("Components/StaminaComponent") as StaminaComponent
	if stamina != null:
		lines.append("endurance: %.0f (%.0f %%)" % [stamina.current(), stamina.ratio() * 100.0])
	lines.append("fps: %d   tick: %d" % [int(Engine.get_frames_per_second()), int(Engine.get_physics_frames())])
	if _reader != null:
		var probe_text: String = _reader.probe.summary()
		if probe_text != "":
			lines.append("— latences (réception→effet) —")
			lines.append(probe_text)
		var refusal: Dictionary = _reader.probe.last_refusal()
		if not refusal.is_empty():
			lines.append("dernier refus: %s (%s)" % [refusal["action"], refusal["reason"]])
	_label.text = "\n".join(lines)


func _locate_player() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	_player = tree.get_first_node_in_group("player") as PlayerController
	if _player != null:
		_reader = _player.get_node_or_null("Components/PlayerInputReader") as PlayerInputReader
