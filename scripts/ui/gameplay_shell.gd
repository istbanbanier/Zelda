## Coquille de gameplay — capture souris, pause, réglages, HUD, inventaire
## (jalon correctif D.1R, constats PT-D1-01/-03/-11).
##
## Instanciée dans chaque scène JOUABLE. `process_mode = ALWAYS` : elle reste
## vivante quand l'arbre est en pause — c'est elle qui suspend et reprend le
## monde ; le gameplay (PAUSABLE par défaut) gèle réellement.
##
## HUD (§17.2) : santé, endurance, flèches, arme et durabilité, verrouillage,
## réticule en visée, invite d'interaction unique, notifications courtes. Tout
## reflète les COMPOSANTS réels — aucune valeur recopiée à la main.
##
## LIMITE MESURÉE : en headless le serveur d'affichage refuse
## `MOUSE_MODE_CAPTURED` (relu : VISIBLE). L'état VOULU est exposé et testé ;
## la capture effective se vérifie sur un poste avec écran.
class_name GameplayShell
extends CanvasLayer

signal pause_toggled(paused: bool)

## Rythme de rafraîchissement des textes du HUD (§5.4 : pas d'allocation de
## chaînes à chaque frame pour des valeurs qui bougent rarement).
const HUD_TEXT_REFRESH: float = 0.1
const NOTIFICATION_LIFETIME: float = 3.0
const MAX_NOTIFICATIONS: int = 4

@onready var _pause_panel: Control = %PausePanel
@onready var _resume_button: Button = %ResumeButton
@onready var _sensitivity_slider: HSlider = %SensitivitySlider
@onready var _sensitivity_value: Label = %SensitivityValue
@onready var _quit_button: Button = %QuitButton
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _stamina_bar: ProgressBar = %StaminaBar
@onready var _arrows_label: Label = %ArrowsLabel
@onready var _weapon_label: Label = %WeaponLabel
@onready var _lock_label: Label = %LockLabel
@onready var _reticle: Control = %Reticle
@onready var _prompt_label: Label = %PromptLabel
@onready var _notifications: VBoxContainer = %Notifications
@onready var _inventory_panel: Control = %InventoryPanel
@onready var _slot_list: VBoxContainer = %SlotList
@onready var _equip_button: Button = %EquipButton
@onready var _move_up_button: Button = %MoveUpButton
@onready var _move_down_button: Button = %MoveDownButton
@onready var _close_inventory_button: Button = %CloseInventoryButton

var _mouse_captured_wanted: bool = true
var _player: PlayerController = null
var _hud_refresh_accumulator: float = 0.0
var _selected_slot: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_panel.visible = false
	_inventory_panel.visible = false
	_prompt_label.text = ""
	_lock_label.visible = false
	_reticle.visible = false
	_resume_button.pressed.connect(_on_resume)
	_quit_button.pressed.connect(_on_quit_to_menu)
	_equip_button.pressed.connect(_on_equip_selected)
	_move_up_button.pressed.connect(func() -> void: _move_selected(-1))
	_move_down_button.pressed.connect(func() -> void: _move_selected(1))
	_close_inventory_button.pressed.connect(toggle_inventory)
	_sensitivity_slider.min_value = UserSettings.MIN_MOUSE_SENSITIVITY
	_sensitivity_slider.max_value = UserSettings.MAX_MOUSE_SENSITIVITY
	_sensitivity_slider.step = 0.0001
	_sensitivity_slider.value = UserSettings.load_mouse_sensitivity()
	_sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	_refresh_sensitivity_label(_sensitivity_slider.value)
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.connect("gameplay_notification", _on_notification)
	_set_mouse_captured(true)
	# Le joueur peut entrer dans l'arbre après la coquille : liaison différée.
	_bind_player.call_deferred()


func _bind_player() -> void:
	for node: Node in get_tree().get_nodes_in_group("player"):
		var player: PlayerController = node as PlayerController
		if player != null:
			_player = player
			break
	if _player == null:
		return
	var health: HealthComponent = _player.health()
	if health != null:
		health.health_changed.connect(_on_health_changed)
		_on_health_changed(health.current(), health.maximum())
	var stamina: StaminaComponent = _player.stamina()
	if stamina != null:
		stamina.changed.connect(_on_stamina_changed)
		_on_stamina_changed(stamina.current(), stamina.maximum())
	var inventory: InventoryComponent = _player.inventory()
	if inventory != null:
		inventory.arrows_changed.connect(_on_arrows_changed)
		_on_arrows_changed(inventory.arrows())
		inventory.weapon_equipped.connect(_on_weapon_changed)
	_player.interact_focus_changed.connect(_on_interact_focus_changed)
	var lock: LockOnComponent = _player.lock_component()
	if lock != null:
		lock.target_acquired.connect(func(_target: Node3D) -> void:
			_lock_label.visible = true)
		lock.target_released.connect(func(_reason: StringName) -> void:
			_lock_label.visible = false)
	_refresh_weapon_text()


func _notification(what: int) -> void:
	# Reprise de focus : ré-appliquer l'état voulu — perdre puis reprendre le
	# focus ne doit jamais laisser une caméra morte (PT-D1-02).
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_apply_mouse_mode()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause", false, true):
		if _inventory_panel.visible:
			toggle_inventory()
		else:
			toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("inventory", false, true):
		if not _pause_panel.visible:
			toggle_inventory()
			get_viewport().set_input_as_handled()
		return
	# Clic dans la fenêtre pendant le jeu : recapture (curseur échappé).
	if not is_paused() and _mouse_captured_wanted \
			and event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_apply_mouse_mode()


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_reticle.visible = _player.is_aiming()
	_hud_refresh_accumulator += delta
	if _hud_refresh_accumulator >= HUD_TEXT_REFRESH:
		_hud_refresh_accumulator = 0.0
		_refresh_weapon_text()


## ---------------------------------------------------------------------------
## Pause et inventaire — les deux suspendent le monde
## ---------------------------------------------------------------------------

func toggle_pause() -> void:
	if is_paused() and _pause_panel.visible:
		_on_resume()
	elif not is_paused():
		get_tree().paused = true
		_pause_panel.visible = true
		_set_mouse_captured(false)
		_resume_button.grab_focus()
		var game_state: Node = get_node_or_null("/root/GameState")
		if game_state != null:
			game_state.call("set_paused", true)
		pause_toggled.emit(true)


func is_paused() -> bool:
	return get_tree().paused


func _on_resume() -> void:
	get_tree().paused = false
	_pause_panel.visible = false
	_set_mouse_captured(true)
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_paused", false)
	pause_toggled.emit(false)


## Inventaire (§11.3, §13.4 : le monde est réellement en pause pendant qu'on y
## navigue — aucune minuterie de gameplay ne court).
func toggle_inventory() -> void:
	if _inventory_panel.visible:
		_inventory_panel.visible = false
		get_tree().paused = false
		_set_mouse_captured(true)
	elif not is_paused():
		_selected_slot = 0
		_rebuild_inventory_panel()
		_inventory_panel.visible = true
		get_tree().paused = true
		_set_mouse_captured(false)


func is_inventory_open() -> bool:
	return _inventory_panel.visible


func _on_quit_to_menu() -> void:
	# Dépauser AVANT la transition : SceneFlow gère sa propre pause de fondu.
	get_tree().paused = false
	_set_mouse_captured(false)
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow != null and bool(flow.call("can_go_to", "res://scenes/ui/MainMenu.tscn")):
		flow.call("go_to", "res://scenes/ui/MainMenu.tscn")


## ---------------------------------------------------------------------------
## Panneau d'inventaire (PT-D1-03 : équiper, sélectionner, réordonner)
## ---------------------------------------------------------------------------

func _rebuild_inventory_panel() -> void:
	for child: Node in _slot_list.get_children():
		child.queue_free()
	if _player == null or _player.inventory() == null:
		return
	var inventory: InventoryComponent = _player.inventory()
	var weapons: Array[WeaponInstance] = inventory.weapons()
	_selected_slot = clampi(_selected_slot, 0, maxi(0, weapons.size() - 1))
	for i: int in range(InventoryComponent.MAX_WEAPONS):
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(460, 34)
		button.toggle_mode = true
		if i < weapons.size():
			var weapon: WeaponInstance = weapons[i]
			var definition: WeaponDefinition = weapon.definition
			var marker: String = "▶ " if weapon == inventory.equipped() else "   "
			button.text = "%s%d. %s — %.0f dég · %.1f m · %d/%d" % [
				marker, i + 1, definition.display_name, definition.base_damage,
				definition.reach_m, weapon.current_durability, definition.max_durability]
			var slot: int = i
			button.pressed.connect(func() -> void:
				_selected_slot = slot
				_refresh_slot_selection())
		else:
			button.text = "   %d. —" % (i + 1)
			button.disabled = true
		_slot_list.add_child(button)
	_refresh_slot_selection()


func _refresh_slot_selection() -> void:
	var buttons: Array[Node] = _slot_list.get_children()
	for i: int in range(buttons.size()):
		var button: Button = buttons[i] as Button
		if button != null and not button.is_queued_for_deletion():
			button.button_pressed = i == _selected_slot


func _on_equip_selected() -> void:
	if _player == null or _player.inventory() == null:
		return
	_player.inventory().equip_index(_selected_slot)
	_rebuild_inventory_panel()
	_refresh_weapon_text()


func _move_selected(offset: int) -> void:
	if _player == null or _player.inventory() == null:
		return
	var target: int = _selected_slot + offset
	if _player.inventory().move_weapon(_selected_slot, target):
		_selected_slot = target
		_rebuild_inventory_panel()


## Seam de test : équipe une case comme si le bouton avait été pressé.
func equip_slot(index: int) -> void:
	_selected_slot = index
	_on_equip_selected()


## ---------------------------------------------------------------------------
## HUD — les composants parlent, la coquille affiche
## ---------------------------------------------------------------------------

func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current


func _on_stamina_changed(current: float, maximum: float) -> void:
	_stamina_bar.max_value = maximum
	_stamina_bar.value = current


func _on_arrows_changed(count: int) -> void:
	_arrows_label.text = "Flèches : %d" % count


func _on_weapon_changed(_weapon: WeaponInstance) -> void:
	_refresh_weapon_text()
	if _inventory_panel.visible:
		_rebuild_inventory_panel()


func _refresh_weapon_text() -> void:
	if _player == null or _player.inventory() == null:
		return
	var weapon: WeaponInstance = _player.inventory().equipped()
	if weapon == null or weapon.definition == null:
		_weapon_label.text = "Mains nues"
		return
	_weapon_label.text = "%s  %d/%d" % [weapon.definition.display_name,
		weapon.current_durability, weapon.definition.max_durability]


func _on_interact_focus_changed(target: Node3D) -> void:
	if target == null or not target.has_method("prompt_verb"):
		_prompt_label.text = ""
		return
	var verb: String = String(target.call("prompt_verb"))
	_prompt_label.text = "" if verb == "" else "E — %s" % verb


func _on_notification(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notifications.add_child(label)
	while _notifications.get_child_count() > MAX_NOTIFICATIONS:
		_notifications.get_child(0).free()
	var timer: Timer = Timer.new()
	timer.wait_time = NOTIFICATION_LIFETIME
	timer.one_shot = true
	timer.autostart = true
	label.add_child(timer)
	timer.timeout.connect(label.queue_free)


func notification_texts() -> Array[String]:
	var texts: Array[String] = []
	for child: Node in _notifications.get_children():
		var label: Label = child as Label
		if label != null and not label.is_queued_for_deletion():
			texts.append(label.text)
	return texts


func prompt_text() -> String:
	return _prompt_label.text


func hud_health() -> float:
	return _health_bar.value


func hud_stamina() -> float:
	return _stamina_bar.value


## ---------------------------------------------------------------------------
## Souris et sensibilité
## ---------------------------------------------------------------------------

func wants_mouse_captured() -> bool:
	return _mouse_captured_wanted


func _set_mouse_captured(captured: bool) -> void:
	_mouse_captured_wanted = captured
	_apply_mouse_mode()


func _apply_mouse_mode() -> void:
	if _mouse_captured_wanted and not get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_sensitivity_changed(value: float) -> void:
	UserSettings.save_mouse_sensitivity(value)
	_refresh_sensitivity_label(value)
	for node: Node in get_tree().get_nodes_in_group("player"):
		var player: PlayerController = node as PlayerController
		if player != null:
			var reader: PlayerInputReader = \
				player.get_node_or_null("Components/PlayerInputReader") as PlayerInputReader
			if reader != null:
				reader.set_mouse_sensitivity(value)


func _refresh_sensitivity_label(value: float) -> void:
	_sensitivity_value.text = "%.4f rad/px" % value


## Seam de test : applique une valeur comme si le curseur avait bougé.
func set_sensitivity(value: float) -> void:
	_sensitivity_slider.value = UserSettings.clamp_sensitivity(value)
