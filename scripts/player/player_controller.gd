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

@export var tuning: LocomotionTuning

@onready var _visual_root: Node3D = $VisualRoot
@onready var _camera_rig: CameraRig = $CameraRig
@onready var _input_reader: PlayerInputReader = $Components/PlayerInputReader
@onready var _stamina: StaminaComponent = $Components/StaminaComponent
@onready var _climbing: ClimbingComponent = $Components/ClimbingComponent
@onready var _ledge: LedgeDetectorComponent = $Components/LedgeDetectorComponent
@onready var _alignment: ActionAlignmentComponent = $Components/ActionAlignmentComponent
@onready var _attack: AttackControllerComponent = $Components/AttackController
@onready var _health: HealthComponent = $Components/HealthComponent
@onready var _lock_on: LockOnComponent = $Components/LockOnComponent
@onready var _bow: BowComponent = $Components/BowComponent
@onready var _inventory: InventoryComponent = $Components/InventoryComponent
@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _weapon_hitbox: HitboxComponent = $VisualRoot/WeaponHitbox
@onready var _collision: CollisionShape3D = $CollisionShape3D

## Esquive (§10.2) : fenêtres et vitesse en ressource, coût dans StaminaTuning.
@export var dodge: DodgeDefinition
## Réaction de dégât et anti-stunlock (§8.1 Hurt, §10.5).
@export var hurt: HurtTuning

## Intention courante. Remplacée par un test via `set_intent_source()`.
var _intent: InputIntent = null
var _use_reader: bool = true

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _was_on_floor: bool = true

var _mode: Mode = Mode.LOCOMOTION
## Normale de paroi lissée (§9.2 : « lissage normale 0,08–0,16 s »). Sans ce
## lissage, la moindre aspérité ferait pivoter le personnage d'un coup.
var _wall_normal: Vector3 = Vector3.ZERO
## Empêche de se raccrocher à la paroi dans le tick qui suit un lâcher volontaire
## ou un saut d'escalade : le joueur est encore contre le mur, il se rattraperait
## immédiatement et ne partirait jamais.
var _grab_cooldown: float = 0.0

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
var _weapon_mesh: MeshInstance3D = null
var _weapon_material: StandardMaterial3D = null
## ART-P0 : modèle de production en main (null = boîte graybox de repli).
var _weapon_model: Node3D = null
var _weapon_model_for: WeaponInstance = null
var _body_material: StandardMaterial3D = null
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


func _physics_process(delta: float) -> void:
	var intent: InputIntent = current_intent()

	# La caméra est mise à jour avant tout le reste : le repère utilisé pour
	# « avant » est celui que le joueur voit à cet instant.
	_camera_rig.apply_look(intent.look_analog, intent.look_mouse, delta)

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
			and (_lock_on == null or not _lock_on.has_target()):
		if intent.target_next_pressed:
			_inventory.equip_next()
		elif intent.target_prev_pressed:
			_inventory.equip_previous()

	# Invite d'interaction (§14.2) : sélection par cadence, pas par frame.
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


func _process_locomotion(delta: float, intent: InputIntent) -> void:
	# Une seule décision de sprint par tick, prise ici et transmise ensuite. La
	# caméra, la vitesse et l'endurance doivent s'accorder sur la même réponse :
	# recalculer la condition à trois endroits les ferait diverger au moment précis
	# où la jauge se vide.
	var sprinting: bool = _resolve_sprint(delta, intent)
	_camera_rig.update_fov(sprinting, delta)

	_update_timers(delta, intent)
	_apply_gravity(delta)
	_apply_horizontal_motion(delta, intent, sprinting)
	_try_jump()

	var was_on_floor: bool = is_on_floor()
	var vertical_before: float = velocity.y
	move_and_slide()
	_detect_ground_transitions(was_on_floor, vertical_before)

	# Franchissement de marche avant l'accroche : une marche de 30 cm doit se
	# monter en marchant, pas déclencher une escalade.
	_maybe_step_up(intent)

	# L'accroche est tentée **après** le déplacement : la paroi est sondée depuis
	# la position réellement atteinte, pas depuis celle du tick précédent.
	_try_grab(intent)

	# Visée et tir (§10.4) : tant que la visée est tenue, le bouton d'attaque
	# sert au tir — les portails d'épée sont suspendus.
	if intent.aim_held:
		if intent.shoot_pressed:
			_try_shoot()
	else:
		# L'attaque s'engage depuis le sol uniquement (§8.1 : LightAttack est un
		# état terrestre ; l'attaque aérienne n'existe pas dans la spec de la 0.1).
		if _mode == Mode.LOCOMOTION and intent.attack_pressed and is_on_floor() \
				and _attack != null and _attack.try_attack():
			_mode = Mode.ATTACKING
			return
		# Attaque lourde (§10.2) : 20 d'endurance (§9.1), REFUSÉE à jauge
		# insuffisante — l'appui est alors perdu, pas mémorisé.
		if _mode == Mode.LOCOMOTION and intent.heavy_pressed and is_on_floor() \
				and _attack != null:
			var cost: float = _stamina.tuning.heavy_attack_cost if _stamina != null else 0.0
			if (_stamina == null or _stamina.can_spend(cost)) and _attack.try_heavy():
				if _stamina != null:
					_stamina.try_spend(cost)
				_mode = Mode.ATTACKING
				return

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

	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = 0.0
	if is_on_floor():
		rate = tuning.ground_acceleration if magnitude > 0.0 else tuning.ground_deceleration
	else:
		# §8.2 : contrôle aérien réduit à 35 %. On ne peut pas changer de direction
		# en l'air aussi librement qu'au sol.
		rate = tuning.air_acceleration * tuning.air_control

	horizontal = horizontal.move_toward(desired, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _try_jump() -> void:
	if _jump_buffer_timer <= 0.0 or _coyote_timer <= 0.0:
		return
	velocity.y = tuning.jump_velocity
	_jump_buffer_timer = 0.0
	# Consommer le coyote empêche un second saut pendant la fenêtre restante.
	_coyote_timer = 0.0


func _detect_ground_transitions(was_on_floor: bool, vertical_before: float) -> void:
	var now_on_floor: bool = is_on_floor()
	if now_on_floor and not was_on_floor:
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
		return
	if _mode == Mode.CLIMBING or _mode == Mode.MANTLING or _mode == Mode.DODGING:
		return
	if _mode == Mode.ATTACKING and _attack != null:
		_attack.cancel()
	_flash_timer = 0.12
	_stunlock_grace = hurt.stunlock_grace
	_hurt_elapsed = 0.0
	velocity.x = event.direction.x * event.knockback
	velocity.z = event.direction.z * event.knockback
	_mode = Mode.HURT


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
	if _visual_root != null:
		_visual_root.rotation.x = -1.3   # le corps tombe — la mort se VOIT (PT-D1-03)
	_mode = Mode.DEAD


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
	_refresh_weapon_visual(weapon)


## ---------------------------------------------------------------------------
## Feedback graybox (PT-D1-03)
## ---------------------------------------------------------------------------

func _build_weapon_visual() -> void:
	_weapon_pivot = Node3D.new()
	_weapon_pivot.name = "WeaponPivot"
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
func _update_weapon_pose() -> void:
	if _weapon_pivot == null or _attack == null:
		return
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
func _update_flash(delta: float) -> void:
	if _body_material == null:
		return
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)
		if not _body_material.emission_enabled:
			_body_material.emission_enabled = true
			_body_material.emission = Color(1, 1, 1)
			_body_material.emission_energy_multiplier = 1.6
	elif _body_material.emission_enabled:
		_body_material.emission_enabled = false


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

signal interact_focus_changed(target: Node3D)


func _try_interact() -> void:
	var best: Node3D = _select_interactable()
	if best != null:
		best.call("interact", self)
		_refresh_interact_focus()   # l'objet a pu disparaître ou changer d'état


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
func _on_own_hit_confirmed(_event: DamageEvent, _target: HurtboxComponent) -> void:
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
		if intent.target_next_pressed or intent.target_prev_pressed:
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
func _try_grab(intent: InputIntent) -> void:
	if _grab_cooldown > 0.0 or _climbing == null or not intent.has_move():
		return
	if _stamina != null and not _stamina.can_sustain():
		return  # épuisé : §9.1 fait lâcher le mur, s'y raccrocher serait absurde

	var wish: Vector3 = _wish_direction(intent)
	if wish.length_squared() < 0.04:
		return

	var probe: ClimbingComponent.WallProbe = _climbing.probe_wall(
		_space(), global_position, wish.normalized(), [get_rid()])
	if not probe.grabbable:
		return

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
