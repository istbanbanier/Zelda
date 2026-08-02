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

## Scène rechargée par « Réessayer » — le checkpoint de D.1R (le monde jouable
## principal), posé par la scène qui instancie la coquille.
@export var world_scene_path: String = "res://scenes/world/valley/ValleyWorld.tscn"

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
@onready var _death_panel: Control = %DeathPanel
@onready var _retry_button: Button = %RetryButton
@onready var _death_quit_button: Button = %DeathQuitButton
@onready var _fade_rect: ColorRect = %RescueFade

var _mouse_captured_wanted: bool = true
var _player: PlayerController = null
var _hud_refresh_accumulator: float = 0.0
var _selected_slot: int = 0

## Habillage V4.4 (réf. 03) — construits en code par `_apply_v4_style()`.
const RUBY_SHARDS: int = 5
const DURABILITY_SEGMENTS: int = 4
var _ruby_shards: Array[ProgressBar] = []
var _durability_segments: Array[ProgressBar] = []
var _lock_plaque: PanelContainer = null
var _lock_target_bar: ProgressBar = null
var _lock_health: HealthComponent = null
var _prompt_panel: PanelContainer = null
## Inventaire V4.5 (réf. 04) — grille de cartes + détail aux données réelles.
var _inventory_grid: GridContainer = null
var _detail_name: Label = null
var _detail_stats: Label = null
var _detail_conductivity: ProgressBar = null
var _detail_icon: TextureRect = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_panel.visible = false
	_inventory_panel.visible = false
	_prompt_label.text = ""
	_lock_label.visible = false
	_reticle.visible = false
	_death_panel.visible = false
	_fade_rect.modulate.a = 0.0
	_resume_button.pressed.connect(_on_resume)
	_quit_button.pressed.connect(_on_quit_to_menu)
	_retry_button.pressed.connect(_on_retry)
	_death_quit_button.pressed.connect(_on_quit_to_menu)
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
	_apply_v4_style()
	_set_mouse_captured(true)
	# Le joueur peut entrer dans l'arbre après la coquille : liaison différée.
	_bind_player.call_deferred()


## ---------------------------------------------------------------------------
## Habillage V4.4 (réf. 03/05) — ardoise, or pâle, rubis, turquoise.
## La LOGIQUE D.1R n'est pas reconstruite : les mêmes signaux alimentent des
## contrôles restylés ; chaque valeur affichée vient d'un composant réel.
## ---------------------------------------------------------------------------

func _apply_v4_style() -> void:
	var hud: Control = _health_bar.get_node("../..") as Control
	# 1. Vie en fragments de rubis (réf. 03) : la barre d'origine devient le
	# MODÈLE caché — mêmes signaux, seuls les éclats s'affichent. `hud_health()`
	# lit la SOMME des éclats : le seam mesure ce qui est réellement montré.
	_health_bar.visible = false
	var vitals: VBoxContainer = _health_bar.get_parent() as VBoxContainer
	var ruby_row: HBoxContainer = HBoxContainer.new()
	ruby_row.name = "RubyRow"
	ruby_row.add_theme_constant_override(&"separation", 4)
	var emblem: Label = Label.new()
	emblem.text = "❖"
	emblem.add_theme_color_override(&"font_color", HudStyle.GOLD)
	ruby_row.add_child(emblem)
	for i: int in range(RUBY_SHARDS):
		var shard: ProgressBar = ProgressBar.new()
		shard.custom_minimum_size = Vector2(30, 20)
		shard.show_percentage = false
		shard.max_value = 100.0 / float(RUBY_SHARDS)
		shard.value = shard.max_value
		shard.add_theme_stylebox_override(&"background",
			HudStyle.gauge_background(HudStyle.RUBY_DARK))
		shard.add_theme_stylebox_override(&"fill", HudStyle.gauge_fill(HudStyle.RUBY))
		ruby_row.add_child(shard)
		_ruby_shards.append(shard)
	vitals.add_child(ruby_row)
	vitals.move_child(ruby_row, 0)
	# 2. Endurance turquoise DISCRÈTE près du personnage, visible pendant
	# l'usage seulement (réf. 03) — sortie de la colonne haut-gauche.
	vitals.remove_child(_stamina_bar)
	hud.add_child(_stamina_bar)
	_stamina_bar.custom_minimum_size = Vector2(130, 7)
	_stamina_bar.show_percentage = false
	_stamina_bar.set_anchors_preset(Control.PRESET_CENTER)
	_stamina_bar.offset_left = 90.0
	_stamina_bar.offset_right = 220.0
	_stamina_bar.offset_top = 30.0
	_stamina_bar.offset_bottom = 37.0
	_stamina_bar.add_theme_stylebox_override(&"background",
		HudStyle.gauge_background(HudStyle.TURQUOISE_DARK))
	_stamina_bar.add_theme_stylebox_override(&"fill",
		HudStyle.gauge_fill(HudStyle.TURQUOISE))
	_stamina_bar.visible = false
	# 3. Plaque de cible verrouillée : nom sobre + vie RÉELLE de l'ennemi.
	_lock_plaque = PanelContainer.new()
	_lock_plaque.name = "LockPlaque"
	_lock_plaque.add_theme_stylebox_override(&"panel", HudStyle.plaque())
	var lock_column: VBoxContainer = VBoxContainer.new()
	_lock_label.get_parent().remove_child(_lock_label)
	_lock_label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	lock_column.add_child(_lock_label)
	_lock_target_bar = ProgressBar.new()
	_lock_target_bar.custom_minimum_size = Vector2(180, 9)
	_lock_target_bar.show_percentage = false
	_lock_target_bar.add_theme_stylebox_override(&"background",
		HudStyle.gauge_background(HudStyle.RUBY_DARK))
	_lock_target_bar.add_theme_stylebox_override(&"fill",
		HudStyle.gauge_fill(HudStyle.RUBY))
	lock_column.add_child(_lock_target_bar)
	_lock_plaque.add_child(lock_column)
	hud.add_child(_lock_plaque)
	_lock_plaque.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_lock_plaque.offset_left = -110.0
	_lock_plaque.offset_right = 110.0
	_lock_plaque.offset_top = 18.0
	_lock_plaque.visible = false
	# 4. Carte d'arme (réf. 03) : plaque bas-droite — nom, durabilité
	# SEGMENTÉE, flèches. Les labels existants y déménagent tels quels.
	var gear: VBoxContainer = _weapon_label.get_parent() as VBoxContainer
	var card: PanelContainer = PanelContainer.new()
	card.name = "WeaponCard"
	card.add_theme_stylebox_override(&"panel", HudStyle.plaque())
	hud.add_child(card)
	card.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	card.offset_left = -250.0
	card.offset_top = -110.0
	card.offset_right = -16.0
	card.offset_bottom = -16.0
	gear.get_parent().remove_child(gear)
	card.add_child(gear)
	_weapon_label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	_arrows_label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	var durability_row: HBoxContainer = HBoxContainer.new()
	durability_row.name = "DurabilityRow"
	durability_row.add_theme_constant_override(&"separation", 3)
	for i: int in range(DURABILITY_SEGMENTS):
		var segment: ProgressBar = ProgressBar.new()
		segment.custom_minimum_size = Vector2(28, 8)
		segment.show_percentage = false
		segment.max_value = 1.0
		segment.add_theme_stylebox_override(&"background",
			HudStyle.gauge_background(Color(0.16, 0.14, 0.10, 0.9)))
		segment.add_theme_stylebox_override(&"fill", HudStyle.gauge_fill(HudStyle.GOLD))
		durability_row.add_child(segment)
		_durability_segments.append(segment)
	gear.add_child(durability_row)
	gear.move_child(durability_row, 1)
	# 5. Invite en cartouche (réf. 03 : chip de touche + verbe).
	_prompt_panel = PanelContainer.new()
	_prompt_panel.name = "PromptPanel"
	_prompt_panel.add_theme_stylebox_override(&"panel", HudStyle.chip())
	var prompt_anchor_top: float = _prompt_label.offset_top
	_prompt_label.get_parent().remove_child(_prompt_label)
	_prompt_label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	_prompt_panel.add_child(_prompt_label)
	hud.add_child(_prompt_panel)
	_prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_panel.offset_left = -110.0
	_prompt_panel.offset_right = 110.0
	_prompt_panel.offset_top = prompt_anchor_top
	_prompt_panel.visible = false
	# 6. Panneaux (pause, mort) : colonne posée sur une plaque d'ardoise, dim
	# adouci — le monde reste VISIBLE derrière (réf. 05 : jamais un écran noir).
	for panel_name: String in ["PausePanel", "DeathPanel", "InventoryPanel"]:
		var panel: Control = get_node("%" + panel_name) as Control
		var dim: ColorRect = panel.get_node("Dim") as ColorRect
		dim.color = Color(0.02, 0.03, 0.05, 0.45)
		var column: VBoxContainer = panel.get_node("Column") as VBoxContainer
		var plate: PanelContainer = PanelContainer.new()
		plate.name = "Plate"
		plate.add_theme_stylebox_override(&"panel", HudStyle.plaque(0.8))
		panel.remove_child(column)
		plate.add_child(column)
		# Centrage ROBUSTE (ART-P0 : la capture d'inventaire montrait la plaque
		# hors cadre avec des ancres calculées) : un CenterContainer plein
		# écran centre son contenu quelle que soit sa taille — mesurable, sans
		# arithmétique d'offsets.
		var centerer: CenterContainer = CenterContainer.new()
		centerer.name = "Centerer"
		panel.add_child(centerer)
		# ANCRES **ET OFFSETS** (ART-P0R.2) : `set_anchors_preset` seul
		# recalcule les offsets pour PRÉSERVER le rect courant — le conteneur
		# restait 0 × 0 en haut-gauche (mesuré sur la capture ART-P0). La
		# variante _and_offsets remplit réellement l'écran ; le centrage suit
		# ensuite chaque redimensionnement, sans position calculée au 1er frame.
		centerer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		centerer.add_child(plate)
		var title: Label = column.get_node_or_null("Title") as Label
		if title != null:
			title.add_theme_color_override(&"font_color", HudStyle.GOLD)
	# 7. Inventaire (réf. 04) : grille 2 × 4 de cartes + panneau de détail aux
	# données RÉELLES (définition + instance). Pas d'onglet OBJETS : il
	# n'existe pas encore — on n'affiche pas un système absent (§0.2).
	(_inventory_panel.get_node("Centerer/Plate/Column/Title") as Label).text = "INVENTAIRE"
	var body: HBoxContainer = HBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override(&"separation", 18)
	_inventory_grid = GridContainer.new()
	_inventory_grid.name = "Cards"
	_inventory_grid.columns = 4
	_inventory_grid.add_theme_constant_override(&"h_separation", 6)
	_inventory_grid.add_theme_constant_override(&"v_separation", 6)
	body.add_child(_inventory_grid)
	var detail_plate: PanelContainer = PanelContainer.new()
	detail_plate.name = "Detail"
	detail_plate.add_theme_stylebox_override(&"panel", HudStyle.plaque(0.5))
	detail_plate.custom_minimum_size = Vector2(230, 0)
	var detail_column: VBoxContainer = VBoxContainer.new()
	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = Vector2(0, 110)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_column.add_child(_detail_icon)
	_detail_name = Label.new()
	_detail_name.add_theme_color_override(&"font_color", HudStyle.GOLD)
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_column.add_child(_detail_name)
	_detail_stats = Label.new()
	_detail_stats.add_theme_color_override(&"font_color", HudStyle.IVORY)
	detail_column.add_child(_detail_stats)
	var conductivity_title: Label = Label.new()
	conductivity_title.text = "Conductivité"
	conductivity_title.add_theme_color_override(&"font_color", HudStyle.IVORY)
	detail_column.add_child(conductivity_title)
	_detail_conductivity = ProgressBar.new()
	_detail_conductivity.custom_minimum_size = Vector2(0, 10)
	_detail_conductivity.max_value = 1.0
	_detail_conductivity.show_percentage = false
	_detail_conductivity.add_theme_stylebox_override(&"background",
		HudStyle.gauge_background(Color(0.05, 0.15, 0.17, 0.9)))
	_detail_conductivity.add_theme_stylebox_override(&"fill",
		HudStyle.gauge_fill(Color(0.133, 0.851, 0.925)))
	detail_column.add_child(_detail_conductivity)
	detail_plate.add_child(detail_column)
	body.add_child(detail_plate)
	_slot_list.add_child(body)
	var hint: Label = Label.new()
	hint.name = "Hints"
	hint.text = "Tab / Échap — Fermer"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override(&"font_color",
		Color(HudStyle.IVORY.r, HudStyle.IVORY.g, HudStyle.IVORY.b, 0.6))
	_slot_list.add_child(hint)
	for button_node: Button in [_resume_button, _quit_button, _retry_button,
			_death_quit_button, _equip_button, _move_up_button, _move_down_button,
			_close_inventory_button]:
		HudStyle.style_button(button_node)


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
	if health != null:
		health.died.connect(_on_player_died)
	var lock: LockOnComponent = _player.lock_component()
	if lock != null:
		lock.target_acquired.connect(_on_lock_acquired)
		lock.target_released.connect(_on_lock_released)
	_refresh_weapon_text()


## Plaque de cible (V4.4, réf. 03) : la vie de l'ennemi verrouillé, depuis SON
## HealthComponent — connectée à l'acquisition, déconnectée au relâchement
## (règle CLAUDE.md : déconnecter les signaux dynamiques).
func _on_lock_acquired(target: Node3D) -> void:
	_lock_label.visible = true
	_lock_plaque.visible = true
	_disconnect_lock_health()
	if target.has_method("health"):
		_lock_health = target.call("health") as HealthComponent
	if _lock_health != null:
		_lock_health.health_changed.connect(_on_lock_target_health)
		_on_lock_target_health(_lock_health.current(), _lock_health.maximum())
		_lock_target_bar.visible = true
	else:
		_lock_target_bar.visible = false


func _on_lock_released(_reason: StringName) -> void:
	_lock_label.visible = false
	_lock_plaque.visible = false
	_disconnect_lock_health()


func _disconnect_lock_health() -> void:
	if _lock_health != null and is_instance_valid(_lock_health) \
			and _lock_health.health_changed.is_connected(_on_lock_target_health):
		_lock_health.health_changed.disconnect(_on_lock_target_health)
	_lock_health = null


func _on_lock_target_health(current: float, maximum: float) -> void:
	_lock_target_bar.max_value = maximum
	_lock_target_bar.value = current


func _notification(what: int) -> void:
	# Reprise de focus : ré-appliquer l'état voulu — perdre puis reprendre le
	# focus ne doit jamais laisser une caméra morte (PT-D1-02).
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_apply_mouse_mode()


func _input(event: InputEvent) -> void:
	# L'écran de mort est MODAL (QA-D1R-03) : ni pause ni inventaire par-dessus,
	# et jamais de recapture souris sous une UI à cliquer. Ses propres boutons
	# (Réessayer / Menu, focus posé) restent la seule issue — clavier compris.
	if _death_panel.visible:
		return
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
	if _fade_rect.modulate.a > 0.0:
		_fade_rect.modulate.a = maxf(0.0, _fade_rect.modulate.a - delta * 1.6)
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
	if _death_panel.visible:
		return  # modal (QA-D1R-03) — la garde tient aussi hors du chemin _input
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
	if _death_panel.visible:
		return  # modal (QA-D1R-03)
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

## Grille 2 × 4 (réf. 04) : huit cartes, cases vides VISIBLES avec emblème
## estompé — jamais une liste tronquée qui cacherait la capacité réelle.
func _rebuild_inventory_panel() -> void:
	for child: Node in _inventory_grid.get_children():
		child.queue_free()
	if _player == null or _player.inventory() == null:
		return
	var inventory: InventoryComponent = _player.inventory()
	var weapons: Array[WeaponInstance] = inventory.weapons()
	_selected_slot = clampi(_selected_slot, 0, maxi(0, weapons.size() - 1))
	for i: int in range(InventoryComponent.MAX_WEAPONS):
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(168, 64)
		button.toggle_mode = true
		button.add_theme_stylebox_override(&"normal", HudStyle.plaque(0.3))
		var selected_style: StyleBoxFlat = HudStyle.plaque(1.0)
		selected_style.border_color = HudStyle.GOLD
		selected_style.set_border_width_all(2)
		button.add_theme_stylebox_override(&"pressed", selected_style)
		HudStyle.style_button(button)
		if i < weapons.size():
			var weapon: WeaponInstance = weapons[i]
			var definition: WeaponDefinition = weapon.definition
			var marker: String = "▶ " if weapon == inventory.equipped() else ""
			button.text = "%s%s\n%d/%d" % [marker, definition.display_name,
				weapon.current_durability, definition.max_durability]
			if definition.icon != null:
				# ART-P0 : icône RENDUE depuis le vrai modèle (jamais dessinée).
				button.icon = definition.icon
				button.expand_icon = true
				button.add_theme_constant_override(&"icon_max_width", 44)
			var slot: int = i
			button.pressed.connect(func() -> void:
				_selected_slot = slot
				_refresh_slot_selection())
		else:
			button.text = "◇"
			button.disabled = true
		_inventory_grid.add_child(button)
	_refresh_slot_selection()


func _refresh_slot_selection() -> void:
	var buttons: Array[Node] = _inventory_grid.get_children()
	for i: int in range(buttons.size()):
		var button: Button = buttons[i] as Button
		if button != null and not button.is_queued_for_deletion():
			button.button_pressed = i == _selected_slot
	_refresh_detail()


## Panneau de détail (réf. 04) : chaque valeur vient de la DÉFINITION et de
## l'INSTANCE sélectionnées — rien n'est recopié en dur dans l'interface.
func _refresh_detail() -> void:
	if _player == null or _player.inventory() == null:
		return
	var weapons: Array[WeaponInstance] = _player.inventory().weapons()
	if _selected_slot < 0 or _selected_slot >= weapons.size():
		_detail_name.text = "—"
		_detail_stats.text = ""
		_detail_conductivity.value = 0.0
		_detail_icon.texture = null
		return
	var weapon: WeaponInstance = weapons[_selected_slot]
	var definition: WeaponDefinition = weapon.definition
	_detail_icon.texture = definition.icon
	_detail_icon.visible = definition.icon != null
	_detail_name.text = definition.display_name.to_upper()
	_detail_stats.text = "Dégâts  %.0f\nPortée  %.1f m\nDurabilité  %d / %d" % [
		definition.base_damage, definition.reach_m,
		weapon.current_durability, definition.max_durability]
	_detail_conductivity.value = definition.conductivity


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
	# Fragments de rubis (V4.4) : chaque éclat porte une part égale du maximum,
	# le dernier entamé se vide partiellement (réf. 03).
	var per_shard: float = maximum / float(RUBY_SHARDS)
	for i: int in range(_ruby_shards.size()):
		_ruby_shards[i].max_value = per_shard
		_ruby_shards[i].value = clampf(current - per_shard * float(i), 0.0, per_shard)


func _on_stamina_changed(current: float, maximum: float) -> void:
	_stamina_bar.max_value = maximum
	_stamina_bar.value = current
	# Réf. 03 : « près du personnage PENDANT son utilisation » — la jauge
	# n'occupe l'écran que quand l'endurance travaille.
	_stamina_bar.visible = current < maximum - 0.5


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
		for segment: ProgressBar in _durability_segments:
			segment.value = 0.0
		return
	_weapon_label.text = "%s  %d/%d" % [weapon.definition.display_name,
		weapon.current_durability, weapon.definition.max_durability]
	# Durabilité SEGMENTÉE (réf. 03) : fraction réelle répartie sur 4 crans.
	var fraction: float = float(weapon.current_durability) \
		/ float(weapon.definition.max_durability) * float(DURABILITY_SEGMENTS)
	for i: int in range(_durability_segments.size()):
		_durability_segments[i].value = clampf(fraction - float(i), 0.0, 1.0)


func _on_interact_focus_changed(target: Node3D) -> void:
	if target == null or not target.has_method("prompt_verb"):
		_prompt_label.text = ""
		_prompt_panel.visible = false
		return
	var verb: String = String(target.call("prompt_verb"))
	_prompt_label.text = "" if verb == "" else "E — %s" % verb
	_prompt_panel.visible = _prompt_label.text != ""


func _on_notification(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	label.add_theme_stylebox_override(&"normal", HudStyle.plaque(0.35))
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


## Somme des éclats de rubis : le seam mesure ce qui est réellement AFFICHÉ
## (V4.4), pas le modèle caché.
func hud_health() -> float:
	var total: float = 0.0
	for shard: ProgressBar in _ruby_shards:
		total += shard.value
	return total


func ruby_shard_values() -> Array[float]:
	var values: Array[float] = []
	for shard: ProgressBar in _ruby_shards:
		values.append(shard.value)
	return values


func is_stamina_gauge_visible() -> bool:
	return _stamina_bar.visible


func is_lock_plaque_visible() -> bool:
	return _lock_plaque.visible


func lock_target_health_shown() -> float:
	return _lock_target_bar.value


func durability_segment_values() -> Array[float]:
	var values: Array[float] = []
	for segment: ProgressBar in _durability_segments:
		values.append(segment.value)
	return values


func inventory_card_count() -> int:
	var count: int = 0
	for child: Node in _inventory_grid.get_children():
		if not child.is_queued_for_deletion():
			count += 1
	return count


func detail_name_text() -> String:
	return _detail_name.text


func detail_stats_text() -> String:
	return _detail_stats.text


func detail_conductivity_shown() -> float:
	return _detail_conductivity.value


func hud_stamina() -> float:
	return _stamina_bar.value


## ---------------------------------------------------------------------------
## Mort et secours (D.1R.4, PT-D1-04)
## ---------------------------------------------------------------------------

## La mort affiche un vrai choix — plus jamais « fermer et relancer ».
func _on_player_died(_event: DamageEvent) -> void:
	# Petit délai : laisser la chute du corps se voir avant l'écran.
	var timer: Timer = Timer.new()
	timer.wait_time = 1.2
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(func() -> void:
		_death_panel.visible = true
		_set_mouse_captured(false)
		_retry_button.grab_focus()
		timer.queue_free())


func is_death_panel_open() -> bool:
	return _death_panel.visible


## Cible du bouton « Réessayer » — exposée pour les tests : la transition
## réelle s'exécute sur poste, le choix de la cible se prouve ici.
func retry_target() -> String:
	return world_scene_path


func _on_retry() -> void:
	get_tree().paused = false
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_pending_spawn", &"retry_checkpoint")
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow != null and bool(flow.call("can_go_to", world_scene_path)):
		flow.call("go_to", world_scene_path)


## Fondu bref après un repêchage de chute (§14.3 : lisible, jamais punitif).
func play_rescue_fade() -> void:
	_fade_rect.modulate.a = 1.0


## ---------------------------------------------------------------------------
## Souris et sensibilité
## ---------------------------------------------------------------------------

func wants_mouse_captured() -> bool:
	return _mouse_captured_wanted


func _set_mouse_captured(captured: bool) -> void:
	# Ceinture et bretelles (QA-D1R-03) : tant que l'écran de mort est affiché,
	# AUCUN chemin ne peut avaler le curseur.
	_mouse_captured_wanted = captured and not _death_panel.visible
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
