## Contrôleur du joueur — locomotion caméra-relative (MASTER_SPEC §8.1, §8.2).
##
## D-013 : ce script ne consulte **jamais** l'InputMap ni un périphérique. Il
## consomme une `InputIntent` produite par `PlayerInputReader`, ou injectée par un
## test. C'est ce qui rend la locomotion vérifiable en headless sans simuler la
## moindre touche — et ce qui garde la dette `CONTROLLER-001` payable.
##
## §20.9 : toute la logique de mouvement vit dans `_physics_process()`. Aucun
## transform de gameplay n'est écrit depuis `_process()`.
##
## ÉTAT C.3 : traversal complet, combo de trois + **attaque lourde** (§10.2, 20
## d'endurance, refusée à jauge vide), esquive à i-frames, verrouillage avec
## **changement de cible**, **réaction de dégât + anti-stunlock** (§10.5), et
## **l'arc** (§10.4) — visée en modificateur de locomotion, flèches balistiques
## par balayage, poolées. Le `Mode` à six états reste la machine plate de §8.1
## (D-018 amendée).
class_name PlayerController
extends CharacterBody3D

## Émis au contact du sol, avec la vitesse verticale d'impact (négative).
## Les dégâts de chute (§8.2) s'y brancheront sans modifier ce script.
signal landed(impact_speed: float)
signal left_ground()
## Émis au franchissement d'une marche (§8.2), avec l'altitude atteinte.
signal stepped_up(new_height: float)
## Accroche et lâcher de paroi (§9.2). `reason` dit pourquoi le mur a été lâché :
## `released`, `exhausted` ou `lost_contact`.
signal grabbed_wall(normal: Vector3)
signal released_wall(reason: StringName)
## Franchissement (§9.3). `refused` porte la raison nommée par le détecteur.
signal mantle_started(target: Vector3)
signal mantle_finished()
signal mantle_refused(reason: StringName)
## Garde et déviation (P2 §7.4) — la présentation (VFX/audio) s'y branche.
signal guard_blocked(event: DamageEvent)
signal parried(event: DamageEvent)
signal guard_broken()
## Verdict d'une opération du Bracelet (P2 §3.8 : « raison courte en cas de
## refus »). `action` vaut `resonance_pulse`, `resonance_ground` ou
## `resonance_confirm` ; `verdict` est le mot rendu par `ResonanceController` ;
## `executed` distingue l'opération partie du refus. La sonde de latence reste
## l'instrument de MESURE ; ce signal est le canal de PRÉSENTATION, seul moyen
## pour le HUD d'expliquer un échec sans que le contrôleur connaisse l'UI.
signal resonance_verdict(action: StringName, verdict: StringName, executed: bool)

## Modes de locomotion effectivement implémentés.
##
## §8.1 énumère vingt états, dont la moitié appartient au combat. Construire la
## machine complète maintenant reviendrait à écrire dix-huit états vides : ce
## `Mode` couvre exactement ce qui existe, et la `StateMachine` de §8.1 arrivera
## avec la Phase C, quand les états de combat auront un contenu (D-018).
enum Mode { LOCOMOTION, CLIMBING, MANTLING, ATTACKING, DODGING, HURT, DEAD }

## Rappel vers la distance de paroi : gain en (m/s) par mètre d'écart, et vitesse
## maximale de correction. Bornés à dessein — voir `_apply_climb_motion()`.
const WALL_HOLD_GAIN: float = 8.0
const WALL_HOLD_MAX_SPEED: float = 1.5

## §12.7 (D-EN.0) : cadence de l'annonce sonore du sprint.
const SPRINT_NOISE_INTERVAL: float = 0.5
var _sprint_noise_timer: float = 0.0

## Hauteur dont le sommet du trajet de mantle dépasse la surface d'arrivée.
## Voir `_try_mantle()`.
const LEDGE_RISE_CLEARANCE: float = 0.06

## Marge de descente lors de la recherche du dessus d'une marche. Voir
## `_try_step_up()`.
const STEP_LANDING_MARGIN: float = 0.05

## Composante minimale de la poussée dirigée VERS l'obstacle pour tenter un
## franchissement de marche. En deçà, le joueur longe l'obstacle et un
## franchissement serait une surprise, pas un service. Voir `_maybe_step_up()`.
const WALL_PUSH_MIN_DOT: float = 0.3

## Poussée des objets physiques (§14.1). `move_and_slide()` ne pousse rien
## de lui-même : un `CharacterBody3D` traverse la scène sans jamais déplacer
## un `RigidBody3D`. La poussée se fait donc par IMPULSION, sur les corps
## rapportés par les collisions de glissement — jamais en écrivant leur
## transform (§14.1 : « pas de modification directe répétée de transform
## d'un rigid body actif »).
## Réponse : fraction de l'écart de vitesse rattrapé par tick — 0,35 donne
## un démarrage franc en ~3 ticks, sans le à-coup d'une impulsion pleine.
const PUSH_RESPONSE: float = 0.35
## §14.1 : « vitesses maximum ». Un bloc ne dépasse jamais la marche.
const PUSH_MAX_SPEED: float = 2.2
## Sous cette vitesse d'approche, le joueur frôle l'objet, il ne pousse pas.
const PUSH_MIN_SPEED: float = 0.15

@export var tuning: LocomotionTuning

@onready var _visual_root: Node3D = $VisualRoot
@onready var _camera_rig: CameraRig = $CameraRig
@onready var _input_reader: PlayerInputReader = $Components/PlayerInputReader
@onready var _resonance: ResonanceController = \
	get_node_or_null("Components/ResonanceController") as ResonanceController
@onready var _stamina: StaminaComponent = $Components/StaminaComponent
@onready var _climbing: ClimbingComponent = $Components/ClimbingComponent
@onready var _ledge: LedgeDetectorComponent = $Components/LedgeDetectorComponent
@onready var _alignment: ActionAlignmentComponent = $Components/ActionAlignmentComponent
@onready var _attack: AttackControllerComponent = $Components/AttackController
@onready var _health: HealthComponent = $Components/HealthComponent
@onready var _lock_on: LockOnComponent = $Components/LockOnComponent
@onready var _bow: BowComponent = $Components/BowComponent
@onready var _inventory: InventoryComponent = $Components/InventoryComponent
@onready var _status: StatusEffectComponent = $Components/StatusEffectComponent
@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _weapon_hitbox: HitboxComponent = $VisualRoot/WeaponHitbox
@onready var _collision: CollisionShape3D = $CollisionShape3D

## Esquive (§10.2) : fenêtres et vitesse en ressource, coût dans StaminaTuning.
@export var dodge: DodgeDefinition
## Réaction de dégât et anti-stunlock (§8.1 Hurt, §10.5).
@export var hurt: HurtTuning
## Garde et déviation parfaite (P2 §7.4).
@export var guard: GuardTuning

## Intention courante. Remplacée par un test via `set_intent_source()`.
var _intent: InputIntent = null
var _use_reader: bool = true
## Vrai quand un porteur (monture) ou un outil (vol libre) conduit le héros.
var _frozen: bool = false

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
## Arc Step (P2 §3.5) : cible du dash en cours, et budget de temps de secours
## — le contrôle revient TOUJOURS, même si l'arrivée devient inatteignable.
var _arc_step_active: bool = false
var _arc_step_target: Vector3 = Vector3.ZERO
var _arc_step_time_left: float = 0.0
## Ground (P2 §3.6) : immobilité assumée pendant le startup de mise à la terre.
var _ground_lock_timer: float = 0.0
## Garde (P2 §7.4) : âge du maintien (-1 = pas en garde). L'âge distingue la
## déviation parfaite (appui récent) du blocage ordinaire (maintien ancien).
var _guard_held_time: float = -1.0
## Clarity : fenêtre de lecture ouverte par une déviation parfaite.
var _clarity_timer: float = 0.0
## Vrai le temps d'un événement : le coup courant a été bloqué par la garde —
## `_on_hit_received` le consomme pour refuser la réaction HURT.
var _hit_was_blocked: bool = false
var _was_on_floor: bool = true
## Vitesse horizontale VOULUE au dernier tick (avant collision) — sert à
## la poussée des objets physiques.
var _desired_horizontal: Vector3 = Vector3.ZERO

var _mode: Mode = Mode.LOCOMOTION
## Normale de paroi lissée (§9.2 : « lissage normale 0,08–0,16 s »). Sans ce
## lissage, la moindre aspérité ferait pivoter le personnage d'un coup.
var _wall_normal: Vector3 = Vector3.ZERO
## Empêche de se raccrocher à la paroi dans le tick qui suit un lâcher volontaire
## ou un saut d'escalade : le joueur est encore contre le mur, il se rattraperait
## immédiatement et ne partirait jamais.
var _grab_cooldown: float = 0.0
## Durée d'appui continu vers une paroi saisissable, pieds au sol. Remise à zéro
## dès que l'une des conditions d'accroche cesse d'être vraie : le seuil mesure
## une INTENTION tenue, pas un cumul de frôlements successifs (D-017).
var _wall_push_time: float = 0.0
## `INF` tant qu'aucun sol n'a été foulé — voir `last_grounded_position()`.
var _last_grounded_position: Vector3 = Vector3.INF
## Arme dont l'avertissement d'usure est branché — voir
## `_bind_durability_warning()`. Une seule à la fois : deux armes ne doivent
## pas prévenir en même temps.
var _warned_weapon: WeaponInstance = null
## Gel d'impact (§10.2, §10.6 « hit-stop attaquant/cible ») : le héros se fige
## au contact, qu'il donne le coup ou le reçoive — même durée des deux côtés,
## lue dans `event.hit_stop`, jamais inventée ici.
var _hitstop_timer: float = 0.0

var _dodge_elapsed: float = 0.0
var _dodge_direction: Vector3 = Vector3.ZERO
## Appui d'esquive mémorisé (§10.2 : 0,12 s) — posé pendant une attaque, il part
## dès la première fenêtre légale (recovery annulable ou retour à la locomotion).
var _dodge_buffer: float = 0.0

var _hurt_elapsed: float = 0.0
## Fenêtre anti-stunlock (§10.5) : tant qu'elle court, un coup blesse mais ne
## reprend pas le contrôle. Décrémentée dans `_physics_process`, pas dans les
## timers de locomotion — elle doit courir dans TOUS les modes.
var _stunlock_grace: float = 0.0

## Portée des mains nues, en mètres — §11.1 n'en donne pas : plus courte que la
## plus courte arme (gourdin, 1,6 m). Décision D-023.
const BARE_REACH: float = 1.2

## Feedback graybox (PT-D1-03) : arme visible, pose d'attaque, flash d'impact.
## Ce n'est PAS de l'animation (Phase H) — c'est le minimum pour qu'un humain
## COMPRENNE le système pendant un test (§7.14 : rien ici n'est « final »).
var _weapon_pivot: Node3D = null
## Vrai quand le pivot d'arme vit dans la MAIN du modèle riggé (ART-Q1) —
## le balayage procédural et la pose de garde graybox sont alors coupés.
var _weapon_in_hand: bool = false
var _weapon_mesh: MeshInstance3D = null
var _weapon_material: StandardMaterial3D = null
## ART-P0 : modèle de production en main (null = boîte graybox de repli).
var _weapon_model: Node3D = null
var _weapon_model_for: WeaponInstance = null
var _body_material: StandardMaterial3D = null
## Matériaux réellement AFFICHÉS sur lesquels peindre le flash de dégât.
##
## `_body_material` ne couvrait que la capsule graybox — que le pilote visuel
## rend invisible dès que le modèle riggé est monté (`player_visual_driver.gd`).
## Le clignotement d'invulnérabilité était donc peint sur un maillage que
## personne ne voit : le joueur perdait sa vie sans aucun signal à l'écran.
var _flash_materials: Array[StandardMaterial3D] = []
var _flash_timer: float = 0.0

const WEAPON_COLORS: Dictionary = {
	&"club": Color(0.45, 0.3, 0.18), &"sword": Color(0.75, 0.78, 0.82),
	&"spear": Color(0.6, 0.5, 0.35), &"axe": Color(0.5, 0.45, 0.45),
	&"blade": Color(0.5, 0.75, 0.8), &"bow": Color(0.55, 0.4, 0.25),
}
## Demi-profondeur du volume de frappe, lue une fois sur la forme réelle : la
## FACE AVANT du volume est placée à `reach_m` de l'axe du personnage.
var _hitbox_half_depth: float = 0.55


func _ready() -> void:
	if tuning == null:
		tuning = LocomotionTuning.new()
		push_warning("[player] aucun LocomotionTuning assigné — valeurs par défaut utilisées.")
	# Le rig partage le même réglage : une seule source pour la caméra et le corps.
	if _camera_rig != null and _camera_rig.tuning == null:
		_camera_rig.tuning = tuning
	floor_max_angle = deg_to_rad(tuning.max_floor_angle_deg)
	floor_snap_length = tuning.floor_snap_length
	# Le corps ne tourne jamais : seule la représentation visuelle s'oriente. Sans
	# cela le `CameraRig`, enfant du corps, hériterait de sa rotation et tournerait
	# avec le personnage — la caméra deviendrait incontrôlable.
	floor_stop_on_slope = true
	# §8.1 Hurt : la hurtbox blesse la santé elle-même ; le contrôleur, lui,
	# écoute pour RÉAGIR — recul et perte de contrôle brève (§10.5).
	if _hurtbox != null:
		_hurtbox.hit_received.connect(_on_hit_received)
		_hurtbox.damage_gate = _gate_damage
	# §11.2 : l'usure ne vient QUE d'un coup qui touche — `hit_confirmed`, jamais
	# l'activation. Puis application de l'état déjà émis : l'inventaire (enfant)
	# a équipé l'arme par défaut AVANT ce `_ready` — le signal est passé, on
	# raccorde donc l'état courant à la main, de façon idempotente (§6.4).
	if _weapon_hitbox != null:
		_weapon_hitbox.hit_confirmed.connect(_on_own_hit_confirmed)
		var shape_holder: CollisionShape3D = \
			_weapon_hitbox.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var box: BoxShape3D = shape_holder.shape as BoxShape3D if shape_holder != null else null
		if box != null:
			_hitbox_half_depth = box.size.z * 0.5
	# §16.2 généralisé au joueur : la mort interrompt tout et libère la caméra.
	if _health != null:
		_health.died.connect(_on_died)
	# E.2a : les multiplicateurs de buff (§13.5) se RETENDENT au changement —
	# jamais de polling (règle du composant).
	if _status != null:
		_status.buff_applied.connect(_on_buff_changed_apply)
		_status.buff_expired.connect(_on_buff_changed_expire)
	_build_weapon_visual()
	# Matériau du corps dédoublé : le flash d'impact d'un joueur ne doit jamais
	# éclairer un autre exemplaire du même matériau partagé (§5.4).
	var body_mesh: MeshInstance3D = _visual_root.get_node_or_null("BodyMesh") as MeshInstance3D
	if body_mesh != null:
		var base: StandardMaterial3D = \
			body_mesh.get_surface_override_material(0) as StandardMaterial3D
		if base != null:
			_body_material = base.duplicate() as StandardMaterial3D
			body_mesh.set_surface_override_material(0, _body_material)
	_collect_flash_materials.call_deferred()
	if _inventory != null:
		_inventory.weapon_equipped.connect(_on_weapon_equipped)
		_on_weapon_equipped(_inventory.equipped())


## Permet à un test de piloter le contrôleur sans aucun périphérique.
func set_intent_source(intent: InputIntent) -> void:
	_intent = intent
	_use_reader = false
	if _input_reader != null:
		_input_reader.set_capture_enabled(false)


func current_intent() -> InputIntent:
	if _use_reader and _input_reader != null:
		return _input_reader.get_intent()
	return _intent if _intent != null else InputIntent.new()


## Latence P2-1 : la consommation est marquée AU changement d'état, pas à la
## lecture de l'intent — c'est l'écart réception→effet que mesure la sonde.
func _mark_consumed(action: StringName) -> void:
	if _use_reader and _input_reader != null:
		_input_reader.probe.mark_consumed(action)


func _mark_refused(action: StringName, reason: StringName) -> void:
	if _use_reader and _input_reader != null:
		_input_reader.probe.mark_refused(action, reason)


func _physics_process(delta: float) -> void:
	# Hit-stop (§10.2) : tout se fige, caméra comprise — geler l'acteur en
	# laissant courir sa caméra désynchroniserait les deux (§10.7). Les fronts
	# d'entrée saisis pendant le gel restent dans l'intent : rien n'est perdu.
	if _hitstop_timer > 0.0:
		_hitstop_timer = maxf(0.0, _hitstop_timer - delta)
		return
	# Gel : le héros a cédé la conduite à un porteur (monture) ou à un outil de
	# développement (vol libre). Il ne consomme plus rien et ne se déplace plus
	# de lui-même ; celui qui l'a gelé est responsable de sa position et de son
	# dégel. La caméra continue de suivre, puisqu'elle reste son enfant.
	#
	# Le gel passe AVANT le relevé du dernier sol : porté ou en vol, on n'est
	# pas « au sol » au sens où l'entend la sauvegarde, et écrire ces positions
	# ferait reparaître exactement le blocage que ce relevé existe pour éviter.
	if _frozen:
		velocity = Vector3.ZERO
		_camera_rig.apply_look(current_intent().look_analog,
			current_intent().look_mouse, delta)
		_camera_rig.update_shake(delta)
		return
	# Dernier sol foulé — voir `last_grounded_position()`. Mesuré AVANT la
	# machine à états : c'est la position d'où le joueur est parti ce tick.
	if is_on_floor() and _mode == Mode.LOCOMOTION:
		_last_grounded_position = global_position
	var intent: InputIntent = current_intent()

	# La caméra est mise à jour avant tout le reste : le repère utilisé pour
	# « avant » est celui que le joueur voit à cet instant.
	_camera_rig.apply_look(intent.look_analog, intent.look_mouse, delta)
	_camera_rig.update_shake(delta)

	# Bracelet de Résonance (P2 §3) : le composant s'auto-pilote (cooldowns,
	# engagement Polarité) ; ici, seulement la DÉCISION — le Pulse ne part que
	# depuis un état où le héros a la main (§3.5 : jamais pendant HURT/DEAD,
	# ni au milieu d'un mantle/attaque/esquive).
	# Un dash Arc Step ou un verrou de terre ne survivent jamais à un
	# changement de mode (coup reçu, chute, mort) : l'état sûr, c'est le mode.
	if _mode != Mode.LOCOMOTION:
		_arc_step_active = false
		_ground_lock_timer = 0.0

	# Garde (P2 §7.4) : clic D tenu avec une arme de MÊLÉE (l'arc, lui, vise).
	# L'âge du maintien distingue parade (récent) et blocage (ancien).
	_clarity_timer = maxf(0.0, _clarity_timer - delta)
	var wants_guard: bool = intent.aim_held and not intent.focus_held \
		and _mode == Mode.LOCOMOTION and is_on_floor() and not _is_bow_equipped()
	if wants_guard:
		_guard_held_time = 0.0 if _guard_held_time < 0.0 else _guard_held_time + delta
	else:
		_guard_held_time = -1.0

	if _resonance != null and intent.pulse_pressed \
			and (_mode == Mode.LOCOMOTION or _mode == Mode.CLIMBING):
		var pulse_verdict: StringName = _resonance.try_pulse(self)
		match pulse_verdict:
			&"fired":
				_mark_consumed(&"resonance_pulse")
			&"cooldown":
				_mark_refused(&"resonance_pulse", &"cooldown")
		resonance_verdict.emit(&"resonance_pulse", pulse_verdict,
			pulse_verdict == &"fired")

	# Ground direct (P2 §3.6, touche dédiée) : cible auto = l'objet chargé le
	# plus proche — la lecture préalable au Pulse a montré quoi viser.
	if _resonance != null and intent.ground_pressed and _mode == Mode.LOCOMOTION:
		var ground_target: Node = _resonance.pick_ground_target(self)
		if ground_target == null:
			_mark_refused(&"resonance_ground", &"aucune_cible")
			resonance_verdict.emit(&"resonance_ground", &"aucune_cible", false)
		else:
			var ground_verdict: StringName = _resonance.try_ground(self, ground_target)
			if ground_verdict != &"grounding":
				_mark_refused(&"resonance_ground", ground_verdict)
			resonance_verdict.emit(&"resonance_ground", ground_verdict,
				ground_verdict == &"grounding")

	# Focus de Résonance (P2 §3.8) : tenu, il capture la molette (cycle) et le
	# clic (confirmation contextuelle) — l'épée et le lock-on sont suspendus le
	# temps du maintien, et tout l'éphémère s'oublie au relâchement.
	if _resonance != null:
		if intent.focus_held and _mode == Mode.LOCOMOTION:
			var camera: Camera3D = _camera_rig.get_camera()
			if camera != null:
				_resonance.focus_update(self, camera.global_position,
					-camera.global_transform.basis.z)
			if intent.target_next_pressed:
				_resonance.focus_cycle(1)
			elif intent.target_prev_pressed:
				_resonance.focus_cycle(-1)
			if intent.attack_pressed:
				var verdict: StringName = _resonance.focus_confirm(self, intent.sprint_held)
				var executed: bool = verdict in [&"step", &"linked", &"engaged",
					&"port_a", &"grounding"]
				if executed:
					_mark_consumed(&"resonance_confirm")
				else:
					_mark_refused(&"resonance_confirm", verdict)
				resonance_verdict.emit(&"resonance_confirm", verdict, executed)
		elif _resonance.focus_active():
			_resonance.focus_end()

	_stunlock_grace = maxf(0.0, _stunlock_grace - delta)
	_update_flash(delta)
	_update_weapon_pose()

	# Verrouillage : bascule et suivi, quel que soit le mode — la caméra doit
	# suivre la cible pendant une esquive autant qu'en course (§8.4).
	_handle_lock_on(delta, intent)

	# Molette / X-V HORS verrouillage : changement d'arme (PT-D1-03). Le même
	# geste change de CIBLE quand une cible est tenue — aucun conflit : le
	# verrouillage a consommé les fronts avant d'arriver ici.
	if _mode == Mode.LOCOMOTION and _inventory != null \
			and not intent.focus_held \
			and (_lock_on == null or not _lock_on.has_target()):
		if intent.target_next_pressed:
			_inventory.equip_next()
		elif intent.target_prev_pressed:
			_inventory.equip_previous()

	# Invite d'interaction (§14.2) : sélection par cadence, pas par frame.
	_interact_refusal_cooldown = maxf(0.0, _interact_refusal_cooldown - delta)
	_interact_focus_tick += 1
	if _interact_focus_tick % INTERACT_FOCUS_INTERVAL == 0:
		_refresh_interact_focus()

	match _mode:
		Mode.MANTLING:
			_process_mantle(delta)
		Mode.CLIMBING:
			_process_climb(delta, intent)
		Mode.ATTACKING:
			_process_attack(delta, intent)
		Mode.DODGING:
			_process_dodge(delta)
		Mode.HURT:
			_process_hurt(delta)
		Mode.DEAD:
			_process_dead(delta)
		_:
			_process_locomotion(delta, intent)

	_orient_visual(delta)

	# Après les demandes d'effort, jamais avant : c'est `update()` qui décide si le
	# tick a consommé ou s'il faut régénérer.
	if _stamina != null:
		_stamina.update(delta)

	if _use_reader and _input_reader != null:
		_input_reader.clear_edges()
	elif _intent != null:
		_intent.consume_edges()


## Arc Step (P2 §3.5) : appelé par `ResonanceController.try_arc_step` APRÈS
## validation complète du trajet. Paie l'endurance ici — à l'exécution, jamais
## au refus. Retourne faux si l'état ou la jauge l'interdit.
func begin_arc_step(arrival: Vector3, cost: float) -> bool:
	if _mode != Mode.LOCOMOTION:
		return false
	if _stamina != null and not _stamina.try_spend(cost):
		return false
	_arc_step_active = true
	_arc_step_target = arrival
	_arc_step_time_left = 0.8
	_mark_consumed(&"resonance_confirm")
	return true


## Le dash est un MOUVEMENT : vitesse + move_and_slide, gravité et collisions
## souveraines. Un contact franc ou le budget de temps rendent la main — c'est
## l'« annulation vers le dernier état sûr » de P2 §3.5.
func _drive_arc_step(delta: float) -> void:
	_arc_step_time_left -= delta
	var planar: Vector3 = _arc_step_target - global_position
	planar.y = 0.0
	if planar.length() < 0.35 or _arc_step_time_left <= 0.0:
		_arc_step_active = false
		# Élan (P2-4e) : le Fragment conserve une portion BORNÉE de l'élan
		# de sortie — plafonnée à la vitesse de course, jamais l'élan du dash.
		if _resonance != null and _resonance.has_fragment(&"elan"):
			var kept: Vector3 = Vector3(velocity.x, 0.0, velocity.z) \
				* ResonanceController.ELAN_KEEP
			velocity = kept.limit_length(tuning.run_speed)
			velocity.y = 0.0
		else:
			velocity = Vector3.ZERO
		return
	velocity = planar.normalized() * ResonanceController.ARC_STEP_SPEED
	velocity.y = 0.0
	move_and_slide()
	if is_on_wall():
		_arc_step_active = false
		velocity = Vector3.ZERO


## Ground (P2 §3.6) : verrouille le héros sur place pendant le startup —
## l'immobilité est le COÛT de l'opération, elle ne peut pas être esquivée.
func begin_ground_lock(duration: float) -> bool:
	if _mode != Mode.LOCOMOTION or not is_on_floor():
		return false
	_ground_lock_timer = duration
	_mark_consumed(&"resonance_ground")
	return true


## Cadence des pas, mesurée en DISTANCE parcourue et non en temps : marcher,
## courir et sprinter produisent alors naturellement des rythmes différents,
## et s'arrêter arrête les pas — ce qu'un minuteur ne saurait pas faire.
##
## Il n'existait aucun crochet de pas dans le projet : ni cadence, ni notion
## de surface. C'est le manque n°1 du playtest — sans pas, le personnage
## flotte, le sol n'a pas de matière et la vitesse n'a pas de rythme.
const STEP_STRIDE_M: float = 2.1
var _step_distance: float = 0.0
var _step_variant: int = 0


func _tick_footsteps(delta: float) -> void:
	if not is_on_floor():
		return
	var speed: float = Vector2(velocity.x, velocity.z).length()
	if speed < 0.6:
		return
	_step_distance += speed * delta
	if _step_distance < STEP_STRIDE_M:
		return
	_step_distance = 0.0
	# Trois échantillons en rotation : deux pas par seconde sur un seul son
	# produisent l'effet mitraillette que §18.2 interdit.
	_step_variant = (_step_variant + 1) % 3
	_sfx(StringName("step_grass_%s" % "abc"[_step_variant]))


func _process_locomotion(delta: float, intent: InputIntent) -> void:
	_tick_footsteps(delta)
	# Arc Step en cours : le dash a l'autorité, l'entrée est suspendue le
	# temps du trajet (< 0,8 s garanti par le budget de secours).
	if _arc_step_active:
		_drive_arc_step(delta)
		return
	# Mise à la terre en cours : immobile, gravité conservée.
	if _ground_lock_timer > 0.0:
		_ground_lock_timer -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y -= tuning.gravity * delta
		move_and_slide()
		return
	# Une seule décision de sprint par tick, prise ici et transmise ensuite. La
	# caméra, la vitesse et l'endurance doivent s'accorder sur la même réponse :
	# recalculer la condition à trois endroits les ferait diverger au moment précis
	# où la jauge se vide.
	var sprinting: bool = _resolve_sprint(delta, intent)
	# §12.7 (D-EN.0) : le sprint fait du BRUIT — annonce périodique aux
	# oreilles ennemies, jamais par frame.
	if sprinting:
		_sprint_noise_timer -= delta
		if _sprint_noise_timer <= 0.0:
			_sprint_noise_timer = SPRINT_NOISE_INTERVAL
			NoiseEvents.emit(get_tree(), global_position,
				NoiseEvents.SPRINT_RADIUS, &"sprint")
	else:
		_sprint_noise_timer = 0.0
	_camera_rig.update_fov(sprinting, delta)

	_update_timers(delta, intent)
	_apply_gravity(delta)
	_apply_horizontal_motion(delta, intent, sprinting)
	_try_jump()

	var was_on_floor: bool = is_on_floor()
	var vertical_before: float = velocity.y
	move_and_slide()
	# La vitesse VOULUE, jamais la vitesse constatée : contre un obstacle,
	# `move_and_slide()` remet la composante entrante à ~0 et l'accélération
	# repart de zéro au tick suivant — mesuré : impulsion plafonnée à
	# 5,6 N·s, sous le seuil de frottement du bloc, donc bloc immobile en
	# 600 ticks de marche.
	_push_physics_props(_desired_horizontal)
	_detect_ground_transitions(was_on_floor, vertical_before)

	# Franchissement de marche avant l'accroche : une marche de 30 cm doit se
	# monter en marchant, pas déclencher une escalade.
	_maybe_step_up(intent)

	# L'accroche est tentée **après** le déplacement : la paroi est sondée depuis
	# la position réellement atteinte, pas depuis celle du tick précédent.
	_try_grab(delta, intent)

	# Visée et tir (§10.4) : tant que la visée est tenue, le bouton d'attaque
	# sert au tir — les portails d'épée sont suspendus.
	if intent.aim_held:
		if intent.shoot_pressed:
			_try_shoot()
	else:
		# L'attaque s'engage depuis le sol uniquement (§8.1 : LightAttack est un
		# état terrestre ; l'attaque aérienne n'existe pas dans la spec de la 0.1).
		if _mode == Mode.LOCOMOTION and intent.attack_pressed and is_on_floor() \
				and not intent.focus_held \
				and _attack != null and _attack.try_attack():
			_mode = Mode.ATTACKING
			_mark_consumed(&"attack_light")
			return
		# Attaque lourde (§10.2) : 20 d'endurance (§9.1), REFUSÉE à jauge
		# insuffisante — l'appui est alors perdu, pas mémorisé.
		if _mode == Mode.LOCOMOTION and intent.heavy_pressed and is_on_floor() \
				and not intent.focus_held \
				and _attack != null:
			var cost: float = _stamina.tuning.heavy_attack_cost if _stamina != null else 0.0
			if (_stamina == null or _stamina.can_spend(cost)) and _attack.try_heavy():
				if _stamina != null:
					_stamina.try_spend(cost)
				_mode = Mode.ATTACKING
				_mark_consumed(&"attack_heavy")
				return
			# 6.10 du plan de test : « jamais de silence sur une action
			# impossible ». Le refus (endurance ou phase) s'entend.
			_sfx(&"refuse")
			_mark_refused(&"attack_heavy", &"endurance_ou_phase")

	# Esquive (§10.2) : depuis le sol, contre 15 d'endurance. L'appui mémorisé
	# pendant une autre action est honoré ici, à la première fenêtre légale.
	if _mode == Mode.LOCOMOTION and (intent.dodge_pressed or _dodge_buffer > 0.0) \
			and is_on_floor():
		_try_dodge(intent)
		return

	# Interaction contextuelle (§14.2) : cône court devant le personnage, l'objet
	# le plus proche l'emporte.
	if _mode == Mode.LOCOMOTION and intent.interact_pressed and is_on_floor():
		_try_interact()
	# E.2a (§8.5 « Plat rapide ») : consommer le plus ancien plat cuisiné —
	# soin immédiat TOUJOURS appliqué, buff majeur remplacé (§13.4).
	if _mode == Mode.LOCOMOTION and intent.meal_pressed:
		_eat_quick_meal()


## Le sprint n'est accordé que s'il est demandé, que le joueur se déplace
## réellement, et que l'endurance le soutient (§9.1). Sprinter sur place ne
## consomme rien : c'est un état de locomotion, pas une posture.
##
## À zéro, `try_sustain()` refuse et le joueur retombe en course — la bascule de
## §9.1 est donc portée par le composant, pas par une condition dispersée ici.
func _resolve_sprint(delta: float, intent: InputIntent) -> bool:
	if not intent.sprint_held or not intent.has_move():
		return false
	if _stamina == null:
		return true
	return _stamina.try_sustain(_stamina.tuning.sprint_drain, delta)


func _update_timers(delta: float, intent: InputIntent) -> void:
	_grab_cooldown = maxf(0.0, _grab_cooldown - delta)
	_dodge_buffer = maxf(0.0, _dodge_buffer - delta)
	if is_on_floor():
		_coyote_timer = tuning.coyote_time
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	# Le saut demandé trop tôt n'est pas perdu : il attend l'atterrissage (§8.2).
	if intent.jump_pressed:
		_jump_buffer_timer = tuning.jump_buffer
	else:
		_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta


## Déplacement **relatif à la caméra** (§8.2) : « avant » signifie l'écran, pas
## l'axe -Z du monde. C'est le pivot de lacet qui définit ce repère.
func _apply_horizontal_motion(delta: float, intent: InputIntent, sprinting: bool) -> void:
	var basis_yaw: Basis = _camera_rig.get_yaw_basis()
	var forward: Vector3 = -basis_yaw.z
	var right: Vector3 = basis_yaw.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var wish: Vector3 = right * intent.move.x + forward * intent.move.y
	var magnitude: float = minf(wish.length(), 1.0)
	if magnitude > 0.0:
		wish = wish.normalized()

	# `target_speed()` reste le seul endroit qui décide d'une vitesse. L'épuisement
	# n'y ajoute pas de branche : il se contente de faire arriver `sprinting` à
	# faux (§9.1, « sprint → course »).
	var speed: float = tuning.target_speed(magnitude, sprinting)
	# En visée (§10.4), on marche : le tir demande de la stabilité, pas un sprint.
	# La visée est un MODIFICATEUR de la locomotion, pas un mode — mêmes règles de
	# mouvement, vitesse plafonnée (l'état Aim de §8.1 est documenté ainsi).
	if intent.aim_held and is_on_floor():
		speed = minf(speed, tuning.walk_speed)
	var desired: Vector3 = wish * speed
	# Mémorisée pour la poussée des objets physiques : contre un obstacle,
	# la vitesse RÉELLE est rabotée à chaque tick par le glissement, alors
	# que l'intention, elle, reste pleine (§14.1).
	_desired_horizontal = desired

	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = 0.0
	if is_on_floor():
		rate = tuning.ground_acceleration if magnitude > 0.0 else tuning.ground_deceleration
	else:
		# §8.2 : contrôle aérien réduit à 35 %. On ne peut pas changer de direction
		# en l'air aussi librement qu'au sol.
		#
		# Le facteur EST DÉJÀ dans `air_acceleration` : 8,4 = 0,35 × 24, c'est
		# la valeur que §8.2 donne pour l'air. Le multiplier une seconde fois
		# par `air_control` donnait 2,94 m/s², soit 12 % du sol — et un saut ne
		# dure que 0,68 s, donc on ne pouvait corriger sa trajectoire que de
		# 2 m/s alors qu'on court à 6. La direction était verrouillée au
		# décollage, et rater une plateforme devenait irrattrapable.
		# `air_control` reste le RAPPORT de référence ; un test vérifie que les
		# deux réglages ne se désaccordent pas (`test_locomotion.gd`).
		rate = tuning.air_acceleration

	horizontal = horizontal.move_toward(desired, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _try_jump() -> void:
	if _jump_buffer_timer <= 0.0 or _coyote_timer <= 0.0:
		return
	velocity.y = tuning.jump_velocity
	_sfx(&"jump")
	_jump_buffer_timer = 0.0
	# Consommer le coyote empêche un second saut pendant la fenêtre restante.
	_coyote_timer = 0.0
	_mark_consumed(&"jump")


func _detect_ground_transitions(was_on_floor: bool, vertical_before: float) -> void:
	var now_on_floor: bool = is_on_floor()
	if now_on_floor and not was_on_floor:
		# `landed` était émis et n'avait AUCUN écouteur : tomber de trente
		# mètres ne produisait pas un bruit. Deux masses, deux sons — c'est
		# aussi la seule information qui dit au joueur qu'une chute comptait.
		_sfx(&"land_hard" if vertical_before < -12.0 else &"land_soft")
		_step_distance = 0.0
		landed.emit(vertical_before)
	elif not now_on_floor and was_on_floor:
		left_ground.emit()
	_was_on_floor = now_on_floor


## Oriente la représentation visuelle vers le déplacement. Le corps, lui, garde
## une rotation nulle : voir `_ready()`.
func _orient_visual(delta: float) -> void:
	# §8.4 : verrouillé, le personnage fait face à la menace — le déplacement
	# devient un strafe. La vitesse d'interpolation reste la même.
	var lock: Node3D = lock_target()
	if lock != null and _mode != Mode.CLIMBING:
		var to_target: Vector3 = lock.global_position - global_position
		if Vector2(to_target.x, to_target.z).length_squared() > 0.01:
			var lock_yaw: float = atan2(to_target.x, to_target.z)
			var lock_weight: float = 1.0 - exp(-tuning.visual_turn_speed * delta)
			_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, lock_yaw, lock_weight)
		return
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length_squared() < 0.04:
		return
	var target_yaw: float = atan2(horizontal.x, horizontal.z)
	# Interpolation indépendante du framerate (§8.3) : à 30 comme à 120 FPS, la
	# rotation met le même temps réel à converger.
	var weight: float = 1.0 - exp(-tuning.visual_turn_speed * delta)
	_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, target_yaw, weight)


## Pousse les corps simulés que le personnage vient de heurter (§14.1).
##
## Trois garde-fous, tous nécessaires :
##   - seuls les corps du groupe `pushable` bougent — un cadavre, une flèche
##     ou un débris ne se transforment pas en bélier ;
##   - la vitesse visée est celle du JOUEUR dans l'axe de la poussée, plafonnée
##     à `PUSH_MAX_SPEED` : impossible de lancer un bloc de 40 kg à travers la
##     salle en sprintant ;
##   - l'impulsion est proportionnelle à l'ÉCART restant, donc nulle une fois
##     le corps à la bonne vitesse : le bloc suit le joueur au lieu de fuir.
func _push_physics_props(desired_velocity: Vector3) -> void:
	for i: int in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(i)
		var body: RigidBody3D = collision.get_collider() as RigidBody3D
		if body == null or not body.is_in_group("pushable"):
			continue
		# La normale pointe VERS le joueur : la poussée va à l'opposé, à plat.
		var normal: Vector3 = collision.get_normal()
		var push: Vector3 = Vector3(-normal.x, 0.0, -normal.z)
		if push.length_squared() < 0.0001:
			continue
		push = push.normalized()
		var approach: float = desired_velocity.dot(push)
		if approach < PUSH_MIN_SPEED:
			continue
		var target: float = minf(approach, PUSH_MAX_SPEED)
		var current: float = Vector3(body.linear_velocity.x, 0.0,
			body.linear_velocity.z).dot(push)
		if current >= target:
			continue
		body.apply_central_impulse(
			push * body.mass * (target - current) * PUSH_RESPONSE)


## Décide s'il y a lieu de tenter un franchissement de marche.
##
## Le déclencheur est la **collision de glissement** que `move_and_slide()` vient
## de rapporter : une normale plus raide que le sol praticable, dans laquelle le
## joueur pousse. C'est le troisième déclencheur de ce mécanisme, et le premier
## fondé sur une mesure complète :
##   - `is_on_wall()` avait été écarté sur une mesure MAL INTERPRÉTÉE — « faux
##     contre le mur de 6 m » : le joueur avait en réalité SAISI ce mur (mode
##     escalade, tenu à 0,42 m, aucun contact). L'artefact est corrigé dans
##     D-020 (amendée) ;
##   - la comparaison distance parcourue / distance demandée, qui l'a remplacé,
##     restait muette en poussée diagonale : le glissement le long de la face
##     conserve ~71 % de la distance totale — contre-exemple démontré par la
##     revue contradictoire du Gate B ;
##   - la collision de glissement, elle, est rapportée dans les deux cas —
##     mesuré : normale (0 ; 0,12 ; −0,99) en poussée à 45° contre la marche —
##     et jamais sur sol libre, donc aucun faux déclenchement pendant une
##     accélération.
func _maybe_step_up(intent: InputIntent) -> void:
	if not is_on_floor():
		return
	var wish: Vector3 = _wish_direction(intent)
	if wish.length_squared() < 0.04:
		return
	var wish_dir: Vector3 = wish.normalized()
	for i: int in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(i)
		var normal: Vector3 = collision.get_normal()
		var angle: float = rad_to_deg(acos(clampf(normal.dot(Vector3.UP), -1.0, 1.0)))
		if angle <= tuning.max_floor_angle_deg:
			continue  # c'est le sol, pas un obstacle
		# Un plafond a une normale quasi verticale : sa composante horizontale ne
		# se normalise pas — et on ne « marche » pas par-dessus un plafond.
		var horizontal: Vector3 = Vector3(normal.x, 0.0, normal.z)
		if horizontal.length_squared() < 0.0001:
			continue
		if wish_dir.dot(-horizontal.normalized()) < WALL_PUSH_MIN_DOT:
			continue  # le joueur longe l'obstacle, il ne pousse pas dedans
		if _try_step_up(wish_dir):
			return


## Franchit une marche basse (§8.2 : 0,30–0,38 m).
##
## `move_and_slide()` n'en monte aucune : mesuré sur le moteur installé, une marche
## de 0,32 m arrête le personnage net — `is_on_wall()` vrai, position figée, aucune
## erreur. Sans ce shape cast, le moindre rebord de décor devient un mur.
##
## Trois questions, dans cet ordre, chacune pouvant refuser :
##   1. y a-t-il la place de se hisser d'une hauteur de marche ?
##   2. une fois surélevé, la place d'avancer ?
##   3. y a-t-il, sous ce point, un sol **praticable** à moins d'une marche ?
## Un « non » à l'une des trois signifie que ce n'était pas une marche mais un mur,
## un plafond ou un vide — et le personnage reste où il est.
func _try_step_up(direction: Vector3) -> bool:
	if _collision == null or _collision.shape == null:
		return false
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return false

	var step: float = tuning.step_height
	var up: Vector3 = Vector3.UP * step
	var ahead: Vector3 = flat.normalized() * tuning.step_forward_probe

	# 1. Dégagement au-dessus. Un plafond bas interdit de se hisser.
	if test_move(global_transform, up):
		return false
	var raised: Transform3D = global_transform.translated(up)

	# 2. Dégagement devant, une fois surélevé. S'il n'y en a pas, l'obstacle est
	# plus haut qu'une marche : c'est un mur, et l'escalade s'en chargera.
	if test_move(raised, ahead):
		return false
	var advanced: Transform3D = raised.translated(ahead)

	# 3. Sol praticable dessous, à moins d'une hauteur de marche. La marge évite de
	# rater un contact au millimètre près ; sans sol, on serait au bord d'un vide et
	# se hisser reviendrait à léviter.
	var landing: KinematicCollision3D = KinematicCollision3D.new()
	if not test_move(advanced, Vector3.DOWN * (step + STEP_LANDING_MARGIN), landing):
		return false
	var normal: Vector3 = landing.get_normal()
	var angle: float = rad_to_deg(acos(clampf(normal.dot(Vector3.UP), -1.0, 1.0)))
	if angle > tuning.max_floor_angle_deg:
		return false

	global_position = advanced.origin + landing.get_travel()
	stepped_up.emit(global_position.y)
	return true


## ---------------------------------------------------------------------------
## Attaque (§10.1, §10.2)
## ---------------------------------------------------------------------------

## Pendant une attaque, le corps est engagé : la locomotion ne pilote plus, la
## vitesse horizontale s'éteint à la décélération du sol et la gravité continue
## de s'appliquer. Les nombres de l'attaque vivent dans `AttackDefinition` ; ce
## contrôleur ne fait qu'exécuter les phases et rendre la main.
func _process_attack(delta: float, intent: InputIntent) -> void:
	_camera_rig.update_fov(false, delta)
	_update_timers(delta, intent)

	# Un nouvel appui pendant l'attaque nourrit le buffer ou enchaîne (§10.2) —
	# la décision appartient au composant, qui connaît fenêtres et index.
	if intent.attack_pressed:
		_attack.try_attack()

	# Dodge cancel (§10.6) : la recovery est annulable par l'esquive — startup et
	# fenêtre active ne le sont pas, l'engagement fait partie du contrat. Un appui
	# hors fenêtre est mémorisé 0,12 s et part au retour à la locomotion.
	if intent.dodge_pressed:
		if _attack.phase() == AttackControllerComponent.Phase.RECOVERY:
			_attack.cancel()
			_try_dodge(intent)
			return
		_dodge_buffer = dodge.input_buffer if dodge != null else 0.12

	if not _attack.update(delta):
		_mode = Mode.LOCOMOTION
		return

	_apply_gravity(delta)
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(Vector3.ZERO, tuning.ground_deceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()


## ---------------------------------------------------------------------------
## Garde et déviation parfaite (P2 §7.4)
## ---------------------------------------------------------------------------

func is_guarding() -> bool:
	return _guard_held_time >= 0.0


func is_clarity_active() -> bool:
	return _clarity_timer > 0.0


func _is_bow_equipped() -> bool:
	if _inventory == null:
		return false
	var weapon: WeaponInstance = _inventory.equipped()
	return weapon != null and weapon.definition != null \
		and weapon.definition.weapon_type == &"bow"


## Porte installée sur la hurtbox — appelée AVANT dégâts et réaction.
## Verdicts : `annule` (déviation parfaite), `bloquee` (événement atténué
## par mutation), `subie` (la garde ne s'applique pas).
func _gate_damage(event: DamageEvent) -> StringName:
	if guard == null or _guard_held_time < 0.0 or event == null:
		return &"subie"
	# La garde est FRONTALE : le modèle fait face à +Z local du VisualRoot,
	# et `direction` pointe de l'attaquant vers le joueur.
	var facing: Vector3 = _visual_root.global_transform.basis.z
	facing.y = 0.0
	var toward_attacker: Vector3 = -event.direction
	toward_attacker.y = 0.0
	if facing.length_squared() < 0.001 or toward_attacker.length_squared() < 0.001:
		return &"subie"
	var cos_half: float = cos(deg_to_rad(guard.front_angle_deg * 0.5))
	if facing.normalized().dot(toward_attacker.normalized()) < cos_half:
		return &"subie"
	# Déviation parfaite : la garde vient d'être levée (P2 §7.4 — fenêtre
	# initiale 0,12 s, + bonus d'arme : l'épée « lit et dévie », §7.5).
	# Aucun dégât, aucune endurance, Clarity, et l'attaquant paie en
	# posture/poise — par le système, pas par un script spécial.
	var window: float = guard.parry_window
	var equipped: WeaponInstance = _inventory.equipped() if _inventory != null else null
	if equipped != null and equipped.definition != null:
		window += equipped.definition.parry_window_bonus
	if _guard_held_time <= window:
		_clarity_timer = guard.clarity_duration
		_jolt_attacker_poise(event)
		_sfx(&"parry")
		parried.emit(event)
		return &"annule"
	# Blocage ordinaire : l'endurance paie ; jauge insuffisante = GuardBreak.
	var cost: float = maxf(guard.block_cost_min, event.amount * guard.block_cost_factor)
	if _stamina == null or not _stamina.try_spend(cost):
		_guard_held_time = -1.0
		guard_broken.emit()
		return &"subie"
	event.amount *= guard.block_damage_factor
	event.knockback *= guard.block_knockback_factor
	_hit_was_blocked = true
	_sfx(&"guard")
	guard_blocked.emit(event)
	return &"bloquee"


## Une déviation parfaite fait payer l'attaquant — règle de dispatch de la
## bible §7.2 : la POSTURE si la cible en porte une (les gardiens plient
## avant de rompre), la POISE sinon (les légers sont étourdis net).
func _jolt_attacker_poise(event: DamageEvent) -> void:
	if event.instigator == null or not is_instance_valid(event.instigator):
		return
	var posture: PostureComponent = event.instigator.get_node_or_null(
		"PostureComponent") as PostureComponent
	if posture != null:
		posture.take_posture_damage(guard.parry_posture_damage)
		return
	var poise: PoiseComponent = \
		event.instigator.get_node_or_null("PoiseComponent") as PoiseComponent
	if poise == null:
		return
	var jolt: DamageEvent = DamageEvent.new()
	jolt.poise_damage = guard.parry_poise_damage
	jolt.attack_id = HitboxComponent.next_attack_id()
	poise.take_poise_damage(jolt)


## Réaction de dégât (§8.1 Hurt, §10.5) et arc (§10.4)
## ---------------------------------------------------------------------------

## Un coup encaissé reprend brièvement le contrôle — SAUF dans la fenêtre
## anti-stunlock (§10.5), où il blesse sans réaction, et pendant les modes où une
## réaction créerait pire que le mal (escalade : lâcher serait une chute ;
## franchissement : téléporter ; esquive : la santé a déjà refusé le dégât).
func _on_hit_received(event: DamageEvent) -> void:
	if _health == null or _health.is_invulnerable() or _health.is_dead():
		return
	if _stunlock_grace > 0.0:
		# La grâce anti-stunlock protège de la RÉACTION, pas des dégâts : le
		# coup passait donc à pleine puissance, sans son, sans flash, sans
		# recul — 0,25 s d'agression totalement muette entre la fin de la
		# mercy et la fin de la grâce. Le joueur voyait sa vie tomber sans
		# comprendre d'où. On garde l'immunité au stagger, on rend le signal.
		_feel_hit(event, 0.010)
		return
	if _mode == Mode.CLIMBING or _mode == Mode.MANTLING or _mode == Mode.DODGING:
		return
	# Coup BLOQUÉ (P2 §7.4) : la garde a tenu — recul court, pas de réaction
	# HURT, pas de mercy (la garde EST la défense ; la mercy suit une vraie
	# blessure subie).
	if _hit_was_blocked:
		_hit_was_blocked = false
		velocity.x = event.direction.x * event.knockback
		velocity.z = event.direction.z * event.knockback
		# Une garde qui tient est un SUCCÈS : elle secoue moins qu'une
		# blessure, sinon parer et encaisser se ressentiraient pareil (§10.7 :
		# trois intensités cohérentes, jamais l'inverse).
		_feel_hit(event, 0.014)
		return
	if _mode == Mode.ATTACKING and _attack != null:
		_attack.cancel()
	# Mercy (2.6) : invulnérable aux DÉGÂTS pendant la fenêtre, et le flash
	# couvre toute sa durée — le clignotement EST l'affichage de la fenêtre.
	# En DIFFÉRÉ, impérativement : la hurtbox émet `hit_received` AVANT
	# d'appliquer les dégâts du même événement — un octroi immédiat rendait le
	# coup déclencheur lui-même gratuit (« attendu 10, obtenu 0.0000 » au
	# premier passage du test). La mercy suit une blessure RÉELLE.
	_health.grant_invulnerability.call_deferred(hurt.mercy_invulnerability)
	_flash_timer = maxf(0.12, hurt.mercy_invulnerability)
	_hitstop_timer = maxf(_hitstop_timer, event.hit_stop)
	_feel_hit(event, 0.030)
	_stunlock_grace = hurt.stunlock_grace
	_hurt_elapsed = 0.0
	velocity.x = event.direction.x * event.knockback
	velocity.z = event.direction.z * event.knockback
	_mode = Mode.HURT


## Le retour SENSIBLE d'un coup reçu, en un seul endroit : son et secousse.
## Les trois chemins d'entrée (garde tenue, grâce anti-stunlock, blessure) y
## passent — c'est ce qui garantit qu'aucun ne redevienne muet.
func _feel_hit(_event: DamageEvent, shake: float) -> void:
	_sfx(&"hit_taken")
	if _camera_rig != null:
		_camera_rig.add_shake(shake)


func _process_hurt(delta: float) -> void:
	_camera_rig.update_fov(false, delta)
	_hurt_elapsed += delta
	_apply_gravity(delta)
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(Vector3.ZERO, hurt.knockback_decay * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()
	if _hurt_elapsed >= hurt.reaction_duration:
		_mode = Mode.LOCOMOTION


## Mort (§8.1 Dead, §16.2 généralisé) — constat D1 de la revue du Gate C : sans
## cet état, le cadavre courait, attaquait et esquivait. Ici : plus aucune
## intention n'est consommée, le corps s'immobilise, la caméra reste libre.
## Le retour au checkpoint (§10.2 « mort/checkpoint ») exige la sauvegarde —
## Phase E, consigné dans STATUS.
func _process_dead(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()


func _on_died(_event: DamageEvent) -> void:
	if _mode == Mode.DEAD:
		return
	if _attack != null:
		_attack.cancel()
	if _lock_on != null and _lock_on.has_target():
		_lock_on.release(&"owner_dead")
		_camera_rig.clear_lock_target()
	# Le coup fatal vient de poser sa réaction HURT et son recul (`hit_received`
	# part AVANT `take_damage`) : la mort les écrase — un mort ne recule pas en
	# courant à 6 m/s.
	velocity.x = 0.0
	velocity.z = 0.0
	# Le corps tombe — la mort se VOIT (PT-D1-03). Avec le modèle riggé,
	# c'est le clip Death01 qui couche le corps : basculer AUSSI la racine
	# ferait tomber le cadavre deux fois (ART-Q1).
	var visual: CharacterVisual = _visual_root.get_node_or_null(
		"CharacterVisual") as CharacterVisual if _visual_root != null else null
	if _visual_root != null and (visual == null or visual.is_fallback_active()):
		_visual_root.rotation.x = -1.3
	_sfx(&"death")
	_mode = Mode.DEAD
	# Mourir rend TOUJOURS la conduite : un héros mort et gelé par une monture
	# ou par le vol libre ne se relèverait jamais au checkpoint (anti-softlock).
	_frozen = false


## ---------------------------------------------------------------------------
## Arme équipée, usure et rupture (§11.1, §11.2)
## ---------------------------------------------------------------------------

## L'inventaire a décidé (équipement, ou « suivante » après rupture) ; ici on
## raccorde : dégâts au contrôleur d'attaque, PORTÉE au volume de frappe — la
## face avant du volume est posée à `reach_m` (§11.1 : la lance à 2,7 m touche
## ce que l'épée à 1,7 m ne touche pas) — et représentation visible (PT-D1-03).
func _on_weapon_equipped(weapon: WeaponInstance) -> void:
	if _attack != null:
		_attack.set_weapon(weapon)
	var reach: float = BARE_REACH
	if weapon != null and weapon.definition != null and weapon.definition.reach_m > 0.0:
		reach = weapon.definition.reach_m
	if _weapon_hitbox != null:
		_weapon_hitbox.position.z = reach - _hitbox_half_depth
	_bind_durability_warning(weapon)
	_refresh_weapon_visual(weapon)


## §11.2 exige un avertissement à 25 % d'usure. L'exemplaire l'émettait
## fidèlement — et PERSONNE ne l'écoutait : `durability_warned` n'avait, dans
## tout le dépôt, qu'une seule connexion, dans un test unitaire. Le joueur
## voyait donc son arme casser en plein combat sans avoir jamais été prévenu.
## On branche l'avertissement sur l'arme RÉELLEMENT équipée, et on débranche la
## précédente : deux armes ne doivent pas parler en même temps.
func _bind_durability_warning(weapon: WeaponInstance) -> void:
	if _warned_weapon != null \
			and _warned_weapon.durability_warned.is_connected(_on_durability_warned):
		_warned_weapon.durability_warned.disconnect(_on_durability_warned)
	_warned_weapon = weapon
	if weapon != null and not weapon.durability_warned.is_connected(_on_durability_warned):
		weapon.durability_warned.connect(_on_durability_warned)


func _on_durability_warned() -> void:
	var name_text: String = "L'arme"
	if _warned_weapon != null and _warned_weapon.definition != null:
		name_text = _warned_weapon.definition.display_name
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.call("notify", "%s est sur le point de casser" % name_text)
	_sfx(&"refuse")


## ---------------------------------------------------------------------------
## Feedback graybox (PT-D1-03)
## ---------------------------------------------------------------------------

func _build_weapon_visual() -> void:
	_weapon_pivot = Node3D.new()
	_weapon_pivot.name = "WeaponPivot"
	# ART-Q1 : si le modèle riggé est monté, l'arme s'attache à la MAIN
	# (BoneAttachment3D `hand_r`) et suit les clips — le balayage procédural
	# du graybox se coupe (_update_weapon_pose). Le repli graybox garde le
	# pivot à l'épaule et son balayage. Dans les deux cas la hitbox de
	# combat reste le volume du contrôleur — jamais le modèle.
	var visual: CharacterVisual = _visual_root.get_node_or_null(
		"CharacterVisual") as CharacterVisual
	var socket: BoneAttachment3D = visual.weapon_socket() \
		if visual != null else null
	if socket != null:
		socket.add_child(_weapon_pivot)
		_weapon_in_hand = true
		# Alignement prise/paume, VÉRIFIÉ PAR CAPTURE (evidence/artQ1) : la
		# lame (+Z du pivot) traverse le poing fermé, la prise posée dans la
		# paume. `WEAPON_GRIP_EULER`/`WEAPON_GRIP_OFFSET` sont des coutures
		# de réglage dev (même famille que SHOWCASE_*) — jamais du gameplay.
		# (90,0,0) retenu par balayage de six orientations canoniques
		# (captures scratchpad puis evidence/artQ1/hero_sword_*).
		_weapon_pivot.rotation_degrees = _grip_tuning_vector(
			"WEAPON_GRIP_EULER", Vector3(90.0, 0.0, 0.0))
		_weapon_pivot.position = _grip_tuning_vector(
			"WEAPON_GRIP_OFFSET", Vector3(0.0, 0.05, 0.0))
	else:
		_weapon_pivot.position = Vector3(0.42, 1.1, 0.1)
		_visual_root.add_child(_weapon_pivot)
	_weapon_mesh = MeshInstance3D.new()
	_weapon_mesh.name = "WeaponMesh"
	var blade: BoxMesh = BoxMesh.new()
	blade.size = Vector3(0.09, 0.09, 1.0)
	_weapon_mesh.mesh = blade
	_weapon_mesh.position = Vector3(0, 0, 0.5)
	_weapon_material = StandardMaterial3D.new()
	_weapon_material.roughness = 0.6
	_weapon_mesh.material_override = _weapon_material
	_weapon_pivot.add_child(_weapon_mesh)
	if not _weapon_in_hand:
		_weapon_pivot.rotation.x = 0.35   # pose de garde, pointe basse


func _refresh_weapon_visual(weapon: WeaponInstance) -> void:
	if _weapon_mesh == null:
		return
	# Même arme déjà en main avec son modèle : seule l'USURE se rafraîchit —
	# pas de ré-instanciation à chaque coup porté (§5.4).
	if _weapon_model != null and is_instance_valid(_weapon_model) \
			and weapon != null and weapon == _weapon_model_for:
		if _weapon_model.has_method("set_worn"):
			_weapon_model.call("set_worn", weapon.durability_fraction()
				<= WeaponInstance.WARNING_FRACTION)
		return
	# ART-P0 : le modèle de PRODUCTION précédent quitte la main quoi qu'il
	# arrive — un changement d'arme ne doit jamais empiler deux visuels.
	if _weapon_model != null and is_instance_valid(_weapon_model):
		_weapon_model.queue_free()
	_weapon_model = null
	_weapon_model_for = null
	if weapon == null or weapon.definition == null:
		_weapon_mesh.visible = false
		return
	if weapon.definition.mesh_scene != null:
		# Modèle de production (mesh_scene de la définition). La géométrie de
		# GAMEPLAY n'y est jamais liée : hitbox et portée restent les volumes
		# du contrôleur (_weapon_hitbox), le modèle est un visuel.
		var instantiated: Node = weapon.definition.mesh_scene.instantiate()
		_weapon_model = instantiated as Node3D
		if _weapon_model == null:
			instantiated.queue_free()
			push_error("[weapon] mesh_scene de %s n'est pas un Node3D — repli boîte."
				% String(weapon.definition.id))
		else:
			_weapon_mesh.visible = false
			# Roulis de 90° autour de l'axe de lame (ART-P0R §6) : EN MAIN, le
			# plat de lame regarde le côté caméra — fil vers le bas, comme une
			# épée tenue. Sans lui, la caméra 3e personne ne voit que la
			# tranche : une « aiguille » (mesuré sur capture).
			_weapon_model.rotation.z = PI * 0.5
			_weapon_pivot.add_child(_weapon_model)
			_weapon_model_for = weapon
			if _weapon_model.has_method("set_worn"):
				_weapon_model.call("set_worn", weapon.durability_fraction()
					<= WeaponInstance.WARNING_FRACTION)
			return
	# Repli CONTRÔLÉ (arme sans modèle de production — normal tant que la
	# bibliothèque ART n'est pas complète) : la boîte graybox de D.1R.3.
	_weapon_mesh.visible = true
	var color: Color = WEAPON_COLORS.get(weapon.definition.weapon_type,
		Color(0.7, 0.7, 0.7)) as Color
	# Durabilité basse (§11.2 : « usure visuelle ») : la lame s'assombrit.
	if weapon.durability_fraction() <= WeaponInstance.WARNING_FRACTION:
		color = color.darkened(0.45)
	_weapon_material.albedo_color = color
	var length: float = 1.0
	if weapon.definition.reach_m > 0.0:
		length = clampf(weapon.definition.reach_m - 0.6, 0.7, 2.0)
	(_weapon_mesh.mesh as BoxMesh).size = Vector3(0.09, 0.09, length)
	_weapon_mesh.position = Vector3(0, 0, length * 0.5)


## Pose d'attaque par phase (§10.6 : l'animation SUIT le contrat, jamais
## l'inverse) : lever pendant l'anticipation, balayer pendant la fenêtre
## active, revenir pendant la récupération.
## Couture de réglage visuel : "x,y,z" depuis l'environnement, sinon la
## valeur figée. Ne touche que l'ALIGNEMENT du modèle d'arme dans la main.
func _grip_tuning_vector(variable: String, fallback: Vector3) -> Vector3:
	var raw: String = OS.get_environment(variable)
	if raw.is_empty():
		return fallback
	var parts: PackedStringArray = raw.split(",")
	if parts.size() != 3:
		return fallback
	return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())


func _update_weapon_pose() -> void:
	if _weapon_pivot == null or _attack == null:
		return
	if _weapon_in_hand:
		return   # la main animée porte le geste — pas de balayage procédural
	var definition: AttackDefinition = _attack.current_attack()
	if definition == null:
		_weapon_pivot.rotation.x = 0.35
		return
	var elapsed: float = _attack.elapsed()
	match _attack.phase():
		AttackControllerComponent.Phase.STARTUP:
			var t: float = clampf(elapsed / maxf(definition.startup, 0.01), 0.0, 1.0)
			_weapon_pivot.rotation.x = lerpf(0.35, -1.1, t)
		AttackControllerComponent.Phase.ACTIVE:
			var t: float = clampf((elapsed - definition.startup)
				/ maxf(definition.active, 0.01), 0.0, 1.0)
			_weapon_pivot.rotation.x = lerpf(-1.1, 0.9, t)
		AttackControllerComponent.Phase.RECOVERY:
			var t: float = clampf((elapsed - definition.startup - definition.active)
				/ maxf(definition.recovery, 0.01), 0.0, 1.0)
			_weapon_pivot.rotation.x = lerpf(0.9, 0.35, t)
		_:
			_weapon_pivot.rotation.x = 0.35


## Flash d'impact (§10.7 « contact ») : émission blanche brève sur le corps.
## Recense les surfaces visibles du héros. Différé : le modèle riggé est monté
## par `CharacterVisual` pendant le même `_ready()`, et l'on veut l'état final.
func _collect_flash_materials() -> void:
	if not is_instance_valid(self):
		return
	_flash_materials.clear()
	for node: Node in _visual_root.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh == null or not mesh.visible or mesh.mesh == null:
			continue
		for surface: int in range(mesh.mesh.get_surface_count()):
			var material: StandardMaterial3D = \
				mesh.get_surface_override_material(surface) as StandardMaterial3D
			if material == null:
				var active: StandardMaterial3D = \
					mesh.get_active_material(surface) as StandardMaterial3D
				if active == null:
					continue
				material = active.duplicate() as StandardMaterial3D
				mesh.set_surface_override_material(surface, material)
			if not _flash_materials.has(material):
				_flash_materials.append(material)


func _update_flash(delta: float) -> void:
	if _flash_materials.is_empty() and _body_material != null:
		_flash_materials.append(_body_material)
	if _flash_materials.is_empty():
		return
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)
		# CLIGNOTEMENT (~9 Hz) plutôt que lueur continue : c'est le langage
		# universel de l'invulnérabilité post-coup (plan de test 2.6), et il
		# se voit même sur un modèle sombre.
		var lit: bool = fmod(_flash_timer, 0.11) > 0.055
		for material: StandardMaterial3D in _flash_materials:
			if material.emission_enabled != lit:
				material.emission_enabled = lit
				material.emission = Color(1, 1, 1)
				material.emission_energy_multiplier = 1.6
	else:
		for material: StandardMaterial3D in _flash_materials:
			if material.emission_enabled:
				material.emission_enabled = false


## Interaction contextuelle (§14.2) : portée ordinaire 2,2 m (bande 1,8–2,4),
## cône avant du VISUEL (le corps ne tourne jamais), LIGNE DE VUE exigée — une
## paroi empêche l'invite ET l'interaction (constat du playtest n° 1) —, le
## plus proche l'emporte. Contrat : un « interactable » est dans le groupe
## éponyme et expose `interact(player) -> bool` et `prompt_verb() -> String`.
const INTERACT_RANGE: float = 2.2
const INTERACT_MIN_DOT: float = 0.25
## Cadence de la sélection continue qui alimente l'invite du HUD (§12.9 :
## timers plutôt que polling par frame).
const INTERACT_FOCUS_INTERVAL: int = 6

## Meilleur interactable courant — consommé par le HUD via le signal.
var _interact_focus: Node3D = null
var _interact_focus_tick: int = 0
## Délai entre deux refus annoncés (voir `_refuse_interaction`), en secondes.
const INTERACT_REFUSAL_COOLDOWN: float = 1.2
var _interact_refusal_cooldown: float = 0.0

signal interact_focus_changed(target: Node3D)
## V4 lot 14 : interaction ACCEPTÉE par la cible — le pilote visuel y
## accroche le geste (l'animation visualise, ne décide pas, §7.18).
signal interacted(target: Node3D)


func _try_interact() -> void:
	var best: Node3D = _select_interactable()
	if best == null:
		_refuse_interaction()
		return
	var accepted: Variant = best.call("interact", self)
	if accepted is bool and bool(accepted):
		interacted.emit(best)
	elif best.has_method("refus_cle"):
		# ISS-084 : une cible peut REFUSER. Sans cette branche, `E` devant le
		# foyer d'un camp encore tenu rendait `false` EN SILENCE — le défaut
		# nº1 du playtest, revenu par une autre porte. Contrat OPTIONNEL :
		# `refus_cle() -> String`, vide quand la cible n'a rien à dire.
		var cle: String = String(best.call("refus_cle"))
		if cle != "":
			_refuse_interaction(cle, &"cible_refuse")
	_refresh_interact_focus()   # l'objet a pu disparaître ou changer d'état


## `E` DANS LE VIDE NE DOIT PAS ÊTRE SILENCIEUX.
##
## Le défaut nº1 du playtest du 2026-08-07 n'était pas une chaîne cassée : la
## chaîne fonctionne, mesurée sur 53 des 55 interactables de la vallée. C'était
## le SILENCE. Le joueur a appuyé sur `E` devant une enclume, un cadavre, un
## objet orange et un foyer décoratif — tous du décor — et n'a rien obtenu :
## ni son, ni message, ni refus. Il en a conclu que la touche ne marchait pas,
## a cessé d'essayer, et n'a ouvert aucun coffre de toute la partie.
##
## Le projet applique déjà cette règle à l'attaque lourde refusée (« jamais de
## silence sur une action impossible », point 6.10 du plan de test) ; elle
## manquait ici, précisément là où un débutant apprend ce que fait une touche.
##
## Cadencé : marteler la touche ne doit pas remplir l'écran de notifications.
##
## ISS-075 : le message est une CLÉ, résolue par le HUD. Le refus « rien à
## portée » n'est plus le seul : une cible qui existe mais se refuse dit
## pourquoi, sans dupliquer la cadence anti-spam qui vit ici.
func _refuse_interaction(cle: String = "interaction.rien_a_portee",
		raison: StringName = &"rien_a_portee") -> void:
	_mark_refused(&"interact", raison)
	if _interact_refusal_cooldown > 0.0:
		return
	_interact_refusal_cooldown = INTERACT_REFUSAL_COOLDOWN
	_sfx(&"refuse")
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.call("notify", cle)


func _select_interactable() -> Node3D:
	var forward: Vector3 = _visual_root.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return null
	forward = forward.normalized()
	var best: Node3D = null
	var best_distance: float = INF
	for node: Node in get_tree().get_nodes_in_group("interactable"):
		var candidate: Node3D = node as Node3D
		if candidate == null or not candidate.has_method("interact"):
			continue
		var to_candidate: Vector3 = candidate.global_position - global_position
		to_candidate.y = 0.0
		var distance: float = to_candidate.length()
		if distance > INTERACT_RANGE or distance < 0.001:
			continue
		if to_candidate.normalized().dot(forward) < INTERACT_MIN_DOT:
			continue
		if not _has_interact_los(candidate):
			continue
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


## §14.2 : « interaction refusée si obstacle ». Rayon poitrine → objet, décor
## seul (couche 1), l'objet lui-même exclu s'il est un corps.
func _has_interact_los(candidate: Node3D) -> bool:
	var exclude: Array[RID] = [get_rid()]
	var body: CollisionObject3D = candidate as CollisionObject3D
	if body != null:
		exclude.append(body.get_rid())
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 1.2,
		candidate.global_position + Vector3.UP * 0.5,
		1, exclude)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _refresh_interact_focus() -> void:
	var current: Node3D = _select_interactable() if _mode == Mode.LOCOMOTION else null
	if current != null and current.has_method("prompt_verb") \
			and String(current.call("prompt_verb")) == "":
		current = null   # un coffre déjà ouvert n'invite plus
	if current != _interact_focus:
		_interact_focus = current
		interact_focus_changed.emit(current)


func current_interact_target() -> Node3D:
	return _interact_focus if _interact_focus != null \
		and is_instance_valid(_interact_focus) else null


## §11.2, à la lettre : l'usure vient d'un coup qui TOUCHE — jamais du vide.
## À zéro : couper la hitbox (le `cancel()` de §16.2), retirer l'exemplaire ;
## l'inventaire équipe la suivante ou les mains nues, et `_on_weapon_equipped`
## raccorde le tout.
func _on_own_hit_confirmed(event: DamageEvent, _target: HurtboxComponent) -> void:
	# §10.6 : le hit-stop vaut pour l'ATTAQUANT aussi — c'est le contact qui
	# pèse, pas seulement l'encaissement.
	_hitstop_timer = maxf(_hitstop_timer, event.hit_stop)
	_sfx(&"hit_land")
	if _inventory == null:
		return
	var weapon: WeaponInstance = _inventory.equipped()
	if weapon == null:
		return  # mains nues : rien ne s'use
	weapon.apply_hit_wear()
	if weapon.is_broken():
		var bus: Node = get_node_or_null("/root/EventBus")
		if bus != null and weapon.definition != null:
			bus.call("notify", "%s cassée !" % weapon.definition.display_name)
		_attack.cancel()
		_inventory.remove_weapon(weapon)
	else:
		_refresh_weapon_visual(weapon)


## Tir à l'arc (§10.4). Direction : le point que la caméra vise à 100 m, corrigé
## vers l'origine — LA POITRINE. L'origine ne s'avance jamais dans la direction
## du tir : le balayage de la flèche part de l'intérieur du corps (RID exclus) et
## rencontre donc tout mur qu'on étreint, au lieu d'apparaître derrière.
## Flèches comptées (§11.3) : pas de munition, pas de tir ; la flèche n'est
## consommée QUE si le tir part vraiment — un refus de cadence ne coûte rien.
func _try_shoot() -> void:
	if _bow == null:
		return
	if _inventory != null and not _inventory.has_arrows():
		return
	var camera: Camera3D = _camera_rig.get_camera()
	var aim_point: Vector3 = camera.global_position \
		- camera.global_transform.basis.z * 100.0
	var origin: Vector3 = global_position + Vector3.UP * 1.3
	var direction: Vector3 = (aim_point - origin).normalized()
	var exclude: Array[RID] = [get_rid()]
	if _hurtbox != null:
		exclude.append(_hurtbox.get_rid())
	if _bow.try_fire(origin, direction, &"player", self, exclude) \
			and _inventory != null:
		_inventory.consume_arrow()


## ---------------------------------------------------------------------------
## Esquive (§10.2) et verrouillage (§8.4)
## ---------------------------------------------------------------------------

## Tente l'esquive. Refus possibles : endurance insuffisante (le coût de 15,
## déclaré dans `StaminaTuning` depuis B.2, est enfin consommé) — l'appui est
## alors simplement perdu, pas mémorisé : marteler l'esquive à jauge vide ne doit
## pas construire une dette d'esquives.
func _try_dodge(intent: InputIntent) -> void:
	if dodge == null:
		return
	if _stamina != null and not _stamina.try_spend(_stamina.tuning.dodge_cost):
		_dodge_buffer = 0.0
		_mark_refused(&"dodge", &"endurance")
		return
	# §10.2 « esquive quatre directions » : celle du stick, en repère caméra ;
	# sans direction, une reculade — le dos du personnage, pas celui de la caméra.
	var wish: Vector3 = _wish_direction(intent)
	if wish.length_squared() > 0.04:
		_dodge_direction = wish.normalized()
	else:
		_dodge_direction = -(_visual_root.global_transform.basis.z).normalized()
		_dodge_direction.y = 0.0
	_dodge_elapsed = 0.0
	_dodge_buffer = 0.0
	_mode = Mode.DODGING
	_mark_consumed(&"dodge")


func _process_dodge(delta: float) -> void:
	_camera_rig.update_fov(false, delta)
	var was_invulnerable: bool = _health != null and _health.is_invulnerable()
	_dodge_elapsed += delta

	# Fenêtre d'invulnérabilité (§10.2) : portée par la santé, comme le stagger et
	# les futurs buffs — l'esquive ne fait qu'ouvrir et fermer la porte.
	if _health != null:
		var inside: bool = _dodge_elapsed >= dodge.iframes_start \
			and _dodge_elapsed < dodge.iframes_end
		if inside != was_invulnerable:
			_health.set_invulnerable(inside)

	velocity.x = _dodge_direction.x * dodge.speed
	velocity.z = _dodge_direction.z * dodge.speed
	_apply_gravity(delta)
	move_and_slide()

	if _dodge_elapsed >= dodge.duration:
		if _health != null:
			_health.set_invulnerable(false)
		_mode = Mode.LOCOMOTION


## Bascule et suivi du verrouillage (§8.4). L'appui décroche si une cible est
## tenue, accroche sinon ; la caméra reçoit la cible et la rend au décrochage.
func _handle_lock_on(delta: float, intent: InputIntent) -> void:
	if _lock_on == null or _mode == Mode.DEAD:
		return
	if intent.lock_pressed:
		if _lock_on.has_target():
			_lock_on.release(&"toggled")
			_camera_rig.clear_lock_target()
		else:
			var camera: Camera3D = _camera_rig.get_camera()
			var forward: Vector3 = -camera.global_transform.basis.z
			var found: Node3D = _lock_on.acquire(self, camera.global_position, forward)
			if found != null:
				_camera_rig.set_lock_target(found)
	elif _lock_on.has_target():
		# §8.4 : changement de cible directionnel, sans boucler.
		if (intent.target_next_pressed or intent.target_prev_pressed) \
				and not intent.focus_held:
			var camera: Camera3D = _camera_rig.get_camera()
			var step: int = 1 if intent.target_next_pressed else -1
			var switched: Node3D = _lock_on.switch_target(self,
				camera.global_position, -camera.global_transform.basis.z, step)
			if switched != null:
				_camera_rig.set_lock_target(switched)
		_lock_on.update(self, _camera_rig.get_camera().global_position, delta)
		if not _lock_on.has_target():
			_camera_rig.clear_lock_target()


func lock_target() -> Node3D:
	return _lock_on.target() if _lock_on != null else null


## ---------------------------------------------------------------------------
## Escalade (§9.2) et mantle (§9.3)
## ---------------------------------------------------------------------------

## Direction horizontale demandée, exprimée dans le monde (repère caméra).
func _wish_direction(intent: InputIntent) -> Vector3:
	var basis_yaw: Basis = _camera_rig.get_yaw_basis()
	var forward: Vector3 = -basis_yaw.z
	var right: Vector3 = basis_yaw.x
	forward.y = 0.0
	right.y = 0.0
	var wish: Vector3 = right.normalized() * intent.move.x + forward.normalized() * intent.move.y
	wish.y = 0.0
	return wish


func _space() -> PhysicsDirectSpaceState3D:
	var world: World3D = get_world_3d()
	if world == null:
		return null
	return world.direct_space_state


## Tente l'accroche. §9.2 ne fixe aucune touche : pousser vers une paroi
## saisissable suffit, au sol comme en l'air (D-017). Une action dédiée obligerait
## à l'ajouter partout — clavier, manette, remapping — pour un geste que le joueur
## fait déjà naturellement.
## Position du dernier sol praticable sur lequel le héros s'est réellement
## tenu. La sauvegarde écrit CELLE-CI et jamais la position courante.
##
## Un playtest en aveugle a produit le pire défaut possible : le héros s'est
## accroché seul à une pente d'herbe, la caméra est entrée dans le terrain,
## l'endurance est tombée à zéro — et la sauvegarde automatique a écrit cette
## position. « Continuer » rechargeait donc DANS le trou, indéfiniment ; la
## seule issue était de perdre la partie. La garde existante
## (`_is_saved_position_safe`) ne teste que les bornes du monde et les nombres
## valides : un trou à l'intérieur de la carte les passe sans problème.
##
## Retenir le dernier sol coupe la classe entière de ce défaut : on ne peut
## pas recharger dans un endroit où l'on n'a jamais pu se tenir debout.
func last_grounded_position() -> Vector3:
	# Debout maintenant : la position courante EST un sol valide, et c'est la
	# plus juste — inutile de renvoyer un point plus ancien.
	if is_on_floor():
		return global_position
	if _last_grounded_position == Vector3.INF:
		return global_position
	return _last_grounded_position


func _try_grab(delta: float, intent: InputIntent) -> void:
	if _grab_cooldown > 0.0 or _climbing == null or not intent.has_move():
		_wall_push_time = 0.0
		return
	# On ne s'accroche pas EN COURANT. Courir contre un arbre, une maison ou
	# une pente est le comportement normal de quelqu'un qui se déplace, pas
	# une demande d'escalade — et l'accroche accidentelle est ce qui a fini
	# par bloquer définitivement un joueur (voir `last_grounded_position`).
	# Au-dessus de la vitesse de marche, on refuse ; en l'air, la garde ne
	# s'applique pas, car sauter vers un rebord est toujours volontaire.
	if is_on_floor():
		var planar_speed: float = Vector2(velocity.x, velocity.z).length()
		if planar_speed > tuning.walk_speed:
			_wall_push_time = 0.0
			return
	if _stamina != null and not _stamina.can_sustain():
		_wall_push_time = 0.0
		return  # épuisé : §9.1 fait lâcher le mur, s'y raccrocher serait absurde

	var wish: Vector3 = _wish_direction(intent)
	if wish.length_squared() < 0.04:
		_wall_push_time = 0.0
		return

	var probe: ClimbingComponent.WallProbe = _climbing.probe_wall(
		_space(), global_position, wish.normalized(), [get_rid()])
	if not probe.grabbable:
		_wall_push_time = 0.0
		return

	# SEUIL D'INTENTION (D-017). Pousser un instant vers une paroi ne suffit
	# plus : il faut insister. D-017 avait nommé ce risque en s'adoptant —
	# « une paroi longeant un chemin s'accroche sans qu'on l'ait demandé » — et
	# fixé d'avance le remède. Un playtest externe l'a confirmé : courir contre
	# un arbre ou une maison déclenchait l'escalade, et la caméra traversait
	# alors le tronc ou le toit.
	#
	# Le délai ne vaut QU'AU SOL. En l'air, l'accroche reste immédiate : on ne
	# saute pas vers un mur par accident, et attendre ferait manquer le rebord
	# visé — ce serait échanger une gêne contre une chute.
	if is_on_floor():
		var required: float = _climb_tuning().grab_intent_delay_s
		_wall_push_time += delta
		if _wall_push_time < required:
			return
	_wall_push_time = 0.0

	_enter_climb(probe.normal)


func _enter_climb(normal: Vector3) -> void:
	_mode = Mode.CLIMBING
	_wall_normal = normal
	velocity = Vector3.ZERO
	# L'accroche au sol doit être coupée pendant l'escalade : `floor_snap_length`
	# rabattrait le personnage vers le sol dès qu'il décolle du bas de la paroi,
	# et la montée s'arrêterait au premier mètre sans qu'aucune erreur ne le dise.
	floor_snap_length = 0.0
	grabbed_wall.emit(normal)


## Rétablit les réglages de locomotion coupés pendant l'escalade.
func _restore_ground_settings() -> void:
	floor_snap_length = tuning.floor_snap_length


## Lâche la paroi. Nommer la raison n'est pas cosmétique : `exhausted` et
## `released` produisent la même chute mais pas le même retour au joueur (§9.1
## demande une respiration), et un test doit pouvoir les distinguer.
func _release_wall(reason: StringName) -> void:
	if _mode != Mode.CLIMBING:
		return
	_mode = Mode.LOCOMOTION
	_wall_normal = Vector3.ZERO
	_grab_cooldown = 0.25
	_restore_ground_settings()
	released_wall.emit(reason)


func _process_climb(delta: float, intent: InputIntent) -> void:
	_camera_rig.update_fov(false, delta)
	_grab_cooldown = maxf(0.0, _grab_cooldown - delta)

	# §9.1 : à endurance nulle, le personnage lâche la paroi. La condition vit dans
	# le composant ; ici on ne fait qu'en tirer la conséquence.
	if _stamina != null and not _stamina.can_sustain():
		_release_wall(&"exhausted")
		return

	# §9.2 : « valider contact à chaque mouvement ». Une paroi qui s'interrompt
	# doit faire lâcher, pas laisser le personnage grimper dans le vide.
	var into_wall: Vector3 = -_wall_normal
	into_wall.y = 0.0
	if into_wall.length_squared() < 0.0001:
		_release_wall(&"lost_contact")
		return
	into_wall = into_wall.normalized()

	var probe: ClimbingComponent.WallProbe = _climbing.probe_wall(
		_space(), global_position, into_wall, [get_rid()])
	if not probe.grabbable:
		# Torse encore en contact mais pieds dans le vide : c'est le haut de la
		# paroi. On tente le franchissement avant de conclure à une perte de contact.
		if probe.chest_hit and _try_mantle(into_wall):
			return
		_release_wall(&"lost_contact")
		return

	# Lissage de la normale (§9.2) : framerate-independent, comme le reste.
	var weight: float = 1.0
	if _climb_tuning().normal_smoothing > 0.0:
		weight = 1.0 - exp(-delta / _climb_tuning().normal_smoothing)
	_wall_normal = _wall_normal.lerp(probe.normal, weight).normalized()

	# Le haut atteint : si un rebord franchissable existe et que le joueur pousse
	# vers le haut, on franchit (§9.3).
	if probe.ledge_likely and intent.move.y > 0.1 and _try_mantle(into_wall):
		return

	if intent.jump_pressed:
		_climb_jump(into_wall)
		return

	_apply_climb_motion(delta, intent, probe)


func _apply_climb_motion(delta: float, intent: InputIntent,
		probe: ClimbingComponent.WallProbe) -> void:
	var tune: ClimbTuning = _climb_tuning()
	# Repère de la paroi : « haut » reste le haut du monde, « droite » suit le mur.
	var wall_right: Vector3 = Vector3.UP.cross(_wall_normal).normalized()
	var vertical: float = intent.move.y * tune.climb_speed_up
	var lateral: float = intent.move.x * tune.climb_speed_lateral

	# §9.1 : l'escalade coûte 18/s, le latéral 16/s. On facture le mouvement
	# réellement demandé, dominante d'abord — cumuler les deux ferait payer deux
	# fois une diagonale.
	if _stamina != null:
		var rate: float = 0.0
		if absf(vertical) > 0.01 or absf(lateral) > 0.01:
			rate = _stamina.tuning.climb_drain if absf(intent.move.y) >= absf(intent.move.x) \
				else _stamina.tuning.climb_lateral_drain
		if rate > 0.0 and not _stamina.try_sustain(rate, delta):
			_release_wall(&"exhausted")
			return

	velocity = Vector3.UP * vertical + wall_right * lateral

	# Maintien à la bonne distance de la paroi (§9.2) : sans ce rappel, le
	# personnage dérive et finit par perdre le contact sur une paroi irrégulière.
	# Rappel **proportionnel et borné**, jamais une correction divisée par delta :
	# celle-ci ramènerait l'écart à zéro en une image, ce qui est un snap — et
	# ferait osciller le personnage contre la paroi, la capsule ne pouvant pas
	# s'approcher plus près que son rayon.
	var flat: Vector3 = Vector3(probe.point.x - global_position.x, 0.0,
		probe.point.z - global_position.z)
	var error: float = flat.length() - tune.wall_distance_m
	velocity += -_wall_normal * clampf(error * WALL_HOLD_GAIN, -WALL_HOLD_MAX_SPEED, WALL_HOLD_MAX_SPEED)

	move_and_slide()


## Saut d'escalade (§9.2 : 0,75–1,0 m ; §9.1 : 20 d'endurance).
func _climb_jump(into_wall: Vector3) -> void:
	var tune: ClimbTuning = _climb_tuning()
	if _stamina != null and not _stamina.try_spend(_stamina.tuning.climb_jump_cost):
		return
	_release_wall(&"released")
	# v = sqrt(2gh) : la hauteur demandée par §9.2 détermine la vitesse, pas
	# l'inverse. Coder la vitesse en dur rendrait la hauteur dépendante de la
	# gravité et donc fausse au premier réglage.
	velocity = Vector3.UP * sqrt(2.0 * tuning.gravity * tune.climb_jump_height)
	velocity += -into_wall * 1.5


## Tente le franchissement. Retourne `true` si le mantle démarre.
func _try_mantle(into_wall: Vector3) -> bool:
	if _ledge == null or _alignment == null or _collision == null:
		return false
	var result: LedgeDetectorComponent.LedgeResult = _ledge.find_ledge(
		_space(), global_position, into_wall, _collision.shape,
		_collision.position.y, tuning.max_floor_angle_deg, [get_rid()])
	if not result.valid:
		mantle_refused.emit(result.refusal)
		return false

	# Trajet en deux temps : monter au-dessus du rebord, puis avancer (§9.3,
	# « mantle bas/haut »). La droite du pied au dessus traverserait le rebord
	# lui-même, et le contrôle de capsule l'annulerait à mi-chemin — défaut
	# constaté, le franchissement nominal échouait sans qu'aucune géométrie ne soit
	# en cause. Le point haut dépasse la cible de `LEDGE_RISE_CLEARANCE` pour que
	# les pieds soient déjà au-dessus de la surface quand ils passent au-dessus.
	var tune: ClimbTuning = _climb_tuning()
	var apex: Vector3 = Vector3(global_position.x,
		result.target_feet.y + LEDGE_RISE_CLEARANCE, global_position.z)
	var path: PackedVector3Array = PackedVector3Array([global_position, apex, result.target_feet])
	if not _alignment.begin_path(path, tune.mantle_duration, tune.mantle_max_correction_m):
		mantle_refused.emit(&"correction_capped")
		return false

	_mode = Mode.MANTLING
	_wall_normal = Vector3.ZERO
	velocity = Vector3.ZERO
	floor_snap_length = 0.0
	mantle_started.emit(result.target_feet)
	return true


func _process_mantle(delta: float) -> void:
	_camera_rig.update_fov(false, delta)
	if not _alignment.is_active():
		_finish_mantle()
		return

	var next: Vector3 = _alignment.advance(delta)
	# §7.12 : annuler si la capsule se retrouve bloquée. Le décor peut bouger
	# pendant les 0,45 s du franchissement ; le valider une seule fois au départ ne
	# suffirait pas.
	if _capsule_blocked_at(next):
		_alignment.cancel(&"blocked")
		_mode = Mode.LOCOMOTION
		_grab_cooldown = 0.25
		_restore_ground_settings()
		mantle_refused.emit(&"blocked_midway")
		return

	global_position = next
	velocity = Vector3.ZERO
	if not _alignment.is_active():
		_finish_mantle()


func _finish_mantle() -> void:
	_mode = Mode.LOCOMOTION
	_grab_cooldown = 0.25
	velocity = Vector3.ZERO
	_restore_ground_settings()
	mantle_finished.emit()


func _capsule_blocked_at(feet: Vector3) -> bool:
	var space: PhysicsDirectSpaceState3D = _space()
	if space == null or _collision == null or _collision.shape == null:
		return false
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = _collision.shape
	query.transform = Transform3D(Basis.IDENTITY, feet + Vector3.UP * _collision.position.y)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	# Marge négative : frôler une surface pendant un franchissement est normal,
	# seule une pénétration franche doit annuler.
	query.margin = -0.05
	return not space.intersect_shape(query, 1).is_empty()


func _climb_tuning() -> ClimbTuning:
	if _climbing != null and _climbing.tuning != null:
		return _climbing.tuning
	return ClimbTuning.new()


## Mode courant, exposé pour les tests et le debug.
func mode() -> Mode:
	return _mode


func is_climbing() -> bool:
	return _mode == Mode.CLIMBING


func is_mantling() -> bool:
	return _mode == Mode.MANTLING


func is_attacking() -> bool:
	return _mode == Mode.ATTACKING


func is_dodging() -> bool:
	return _mode == Mode.DODGING


func attack_controller() -> AttackControllerComponent:
	return _attack


## Normale de paroi lissée, nulle hors escalade.
func wall_normal() -> Vector3:
	return _wall_normal


## Vitesse horizontale, exposée pour les tests et l'UI de debug.
func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## Exposé pour les tests, la jauge de §17.2 et la sauvegarde de §19.1.
func stamina() -> StaminaComponent:
	return _stamina


func status() -> StatusEffectComponent:
	return _status


## E.2a — consommation du plat rapide (§13.3/§13.4). Le plat quitte la
## réserve au prélèvement : jamais deux effets pour un plat.
## V4 lot 14 : plat réellement avalé — le pilote visuel joue le geste.
signal meal_eaten(meal_name: String)


## §18.2 : un son par action importante. Passe par l'autoload — silencieux
## si le son manque, jamais bloquant pour le gameplay.
func _sfx(sound: StringName) -> void:
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("play_sfx", sound)


func _eat_quick_meal() -> void:
	if _inventory == null or _status == null or _health == null:
		return
	var bus: Node = get_node_or_null("/root/EventBus")
	var meal: Dictionary = _inventory.take_first_meal()
	if meal.is_empty():
		_sfx(&"refuse")
		if bus != null:
			bus.call("notify", "Aucun plat — cuisinez au feu de camp")
		return
	_sfx(&"ui_accept")
	var heal: float = float(meal.get("heal", 0.0))
	if heal > 0.0:
		_health.heal(heal)
	var effect: StringName = StringName(String(meal.get("effect", "")))
	if effect != &"":
		_status.apply_buff(effect, float(meal.get("potency", 0.0)),
			float(meal.get("duration", 0.0)))
	meal_eaten.emit(String(meal.get("name", "Plat")))
	if bus != null:
		bus.call("notify", "Mangé : %s (+%d PV)"
			% [String(meal.get("name", "Plat")), int(heal)])


## E.2a — propagation des multiplicateurs de §13.5 : posés au signal, sur
## les composants qui les consomment. Le composant d'état reste la source ;
## hitbox/hurtbox/stamina n'apprennent JAMAIS l'existence des buffs.
func _on_buff_changed_apply(_effect: StringName, _potency: float,
		_duration: float) -> void:
	_refresh_buff_multipliers()


func _on_buff_changed_expire(_effect: StringName) -> void:
	_refresh_buff_multipliers()


func _refresh_buff_multipliers() -> void:
	if _status == null:
		return
	if _weapon_hitbox != null:
		_weapon_hitbox.damage_multiplier = _status.attack_multiplier()
	if _hurtbox != null:
		_hurtbox.damage_taken_multiplier = _status.damage_taken_multiplier()
	if _stamina != null:
		_stamina.regen_multiplier = _status.stamina_regen_multiplier()


## Exposé pour les tests, l'UI d'inventaire (§17.3) et la sauvegarde de §19.1.
func inventory() -> InventoryComponent:
	return _inventory


## Convention des cibles (§8.4, §12.7) : quiconque expose `health()` peut être
## jugé mort — le pillard s'en sert pour lâcher un cadavre.
func health() -> HealthComponent:
	return _health


## Consommé par le réticule du HUD (§17.2 : « réticule en visée »).
func is_aiming() -> bool:
	return _mode == Mode.LOCOMOTION and current_intent().aim_held


func lock_component() -> LockOnComponent:
	return _lock_on


## Consommé par le viseur de Résonance du HUD (P2 §3.8). Lecture seule : le
## HUD interroge la cible retenue et le port en attente, il ne décide rien.
func resonance() -> ResonanceController:
	return _resonance


## Cède ou reprend la conduite du héros.
##
## Gelé, il ne consomme plus aucune entrée et ne bouge plus de lui-même : c'est
## le porteur (monture) ou l'outil (vol libre) qui décide de sa position. Sa
## caméra continue de le suivre, donc le joueur garde le regard.
##
## Contrat de sûreté : celui qui gèle DOIT dégeler. Un héros gelé sans porteur
## serait un softlock — d'où `is_frozen()`, que les tests et les outils
## interrogent, et le dégel systématique à la mort.
func set_frozen(frozen: bool) -> void:
	if _frozen == frozen:
		return
	_frozen = frozen
	if frozen:
		velocity = Vector3.ZERO


func is_frozen() -> bool:
	return _frozen


## Lecteur d'entrée réel — consommé par le vol libre, qui a besoin des ordres
## bruts pendant que le héros, lui, est gelé.
func input_reader() -> PlayerInputReader:
	return _input_reader


## §16.6 : l'arène a besoin du rig pour élargir le cadrage face au boss.
## Exposé en lecture — personne n'écrit dans la caméra du joueur d'ailleurs.
func camera_rig() -> CameraRig:
	return _camera_rig
