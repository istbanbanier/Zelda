## GARDIEN DE L'ORAGE — boss final (MASTER_SPEC §16).
##
## Créature mécanique-animale ORIGINALE : quadrupède trapu de pierre et de
## bronze, dos hérissé de câbles, noyau cyan sous une armure de plaques.
## Aucune silhouette empruntée ; le graybox porte déjà les proportions
## (4,2 m au garrot, 6,4 m de long) que la Phase H habillera.
##
## §16.2 — machine à états, au complet :
## `Intro`, `Phase1`, `GroundedStun`, `Transition12`, `Phase2`,
## `Overload`, `Transition23`, `Phase3`, `Stagger`, `Dead`.
## Toutes les transitions sont IDEMPOTENTES : un seuil de PV ne peut pas
## se déclencher deux fois (`_thresholds_crossed`), et la mort coupe tout
## une seule fois.
##
## Le cœur du combat, phase par phase :
## - §16.3 (100 → 65 %) : l'armure divise les dégâts par cinq. Pour la
##   percer, on DRESSE DEUX PYLÔNES : la prochaine décharge du Gardien
##   part alors dans la terre, il s'écroule 6 s, et son noyau est nu.
##   Les pylônes sont de vrais nœuds du graphe électrique du donjon.
## - §16.4 (65 → 30 %) : deux cristaux conducteurs poussent sur son dos.
##   Tant qu'ils vivent, il entre en SURCHARGE par intermittence ; frapper
##   pendant la surcharge avec une arme CONDUCTRICE renvoie une décharge
##   (le bois, lui, ne renvoie rien — §14.4). Les cristaux tombent à
##   l'arc ou au corps à corps.
## - §16.5 (< 30 %) : vitesse +15 %, charge suivie d'une frappe au sol,
##   et des marques d'impact au sol 0,85 s avant l'éclair. Les fenêtres
##   raccourcissent sans disparaître.
class_name StormGuardian
extends CharacterBody3D

signal phase_changed(phase: StringName)
signal grounded()
signal crystal_destroyed(remaining: int)
signal died()

enum State {
	INTRO, PHASE1, GROUNDED_STUN, TRANSITION12, PHASE2, OVERLOAD,
	TRANSITION23, PHASE3, STAGGER, DEAD,
}

const GRAVITY: float = 24.0
## §16.1 : « animation d'entrée 5-8 s passable ».
const INTRO_TIME: float = 5.0
## §16.3 : « la mise à la terre étourdit 5-8 s ».
const GROUNDED_TIME: float = 6.0
const TRANSITION_TIME: float = 2.0
## §16.4 : la surcharge dure, puis retombe — ce n'est pas un état permanent.
const OVERLOAD_TIME: float = 4.0
const OVERLOAD_INTERVAL: float = 9.0
## §16.5 : « éclairs marqués au sol 0,7-1,0 s avant impact ».
const STRIKE_TELEGRAPH: float = 0.85
## §16.3 : l'armure réduit fortement, sans invulnérabilité obscure.
const ARMOURED_MULTIPLIER: float = 0.2
## §16.5 : « vitesse +10 à +18 %, pas doublement brutal ».
const PHASE3_SPEED_GAIN: float = 1.15

## Les PV du Gardien sont DÉRIVÉS, pas inventés. §16.7 exige un test qui
## échoue si le boss est mathématiquement impossible avec le loot garanti,
## et « une marge de 30-50 % au-dessus du minimum théorique ». Le loot
## garanti (lame conductrice 26×16, épée usée 12×24, gourdin 8×18) donne
## environ 755 dégâts utiles sous des hypothèses délibérément pessimistes
## — deux coups sur trois portent, la moitié seulement tombe dans une
## fenêtre de noyau. 560 PV placent la marge à 35 %. La première valeur
## essayée, 900, plaçait le combat à -16 % : impossible. Le calcul vit
## dans `test_the_guardian_is_beatable_with_the_guaranteed_loot` et
## refusera toute dérive, à la hausse comme à la baisse.
@export var max_health: float = 560.0
@export var move_speed: float = 4.6
@export var turn_speed: float = 2.6
## Phase H : la portée suit le CORPS. Le hero asset mesure 9,58 m de long ;
## sa griffe balaie de -2,8 à -6,4 m devant le pivot. 4,6 m — valeur du
## graybox, qui faisait 6,4 m — laissait le Gardien frapper à l'intérieur
## de lui-même.
@export var melee_reach: float = 6.0
@export var arc_reach: float = 14.0
## Seuils de phase, en fraction de vie (§16.3-§16.5).
@export var phase2_threshold: float = 0.65
@export var phase3_threshold: float = 0.30
## Pylônes de l'arène — il en faut DEUX dressés pour la mise à la terre.
@export var pylon_paths: Array[NodePath] = []
## §16.6 : « nav/steering garde le boss dans l'arène ». Le mur circulaire
## le tient déjà physiquement ; ce rappel évite qu'il s'y ÉCRASE en
## poursuivant un joueur collé au bord — un colosse qui laboure le mur
## pousse le joueur, et c'est exactement ce que §16.6 interdit.
@export var arena_center: Vector3 = Vector3.ZERO
## 0 = pas de limite (bancs de test, `CombatLab`).
@export var arena_radius: float = 0.0

var _state: State = State.INTRO
var _timer: float = 0.0
var _target: PlayerController = null
var _pylons: Array[GroundingPylon] = []
var _crystals: Array[HurtboxComponent] = []
var _crystal_health: Array[float] = []
var _thresholds_crossed: Dictionary[StringName, bool] = {}
var _overload_cooldown: float = OVERLOAD_INTERVAL
var _attack_cooldown: float = 1.4
var _strike_marks: Array[Node3D] = []
var _armour_intact: bool = true

## Phase H : le hero asset. `null` en repli — un banc de test peut monter le
## Gardien sans son modèle, et la logique ne doit pas s'en apercevoir.
@onready var _visual: GuardianVisual = get_node_or_null("Pivot/GuardianVisual") \
	as GuardianVisual
@onready var _health: HealthComponent = $HealthComponent
@onready var _attack: AttackControllerComponent = $AttackController
@onready var _body_hurtbox: HurtboxComponent = $Pivot/BodyHurtbox
@onready var _core_hurtbox: HurtboxComponent = $Pivot/CoreHurtbox
@onready var _pivot: Node3D = $Pivot


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("damageable")
	add_to_group("lock_on_targets")
	add_to_group("boss")
	_health.max_health = max_health
	_health.revive(max_health)
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)
	for path: NodePath in pylon_paths:
		var pylon: GroundingPylon = get_node_or_null(path) as GroundingPylon
		if pylon != null:
			_pylons.append(pylon)
	_collect_crystals()
	# L'armure est posée dès le départ : le noyau ne prend rien tant qu'il
	# n'est pas exposé, et le corps encaisse au cinquième.
	_apply_armour(true)
	# `_enter()` est IDEMPOTENT (§16.2) : entrer dans l'état déjà courant
	# ne fait rien — c'est voulu, et c'est ce qui protège les seuils de PV.
	# L'INTRO doit donc être ARMÉE à la main : sans cette ligne, `_timer`
	# valait 0 et le Gardien basculait en phase 1 au premier tick physique.
	# Les « 5 à 8 s » d'éveil de §16.1 n'existaient tout simplement pas ;
	# `test_the_camera_widens_progressively_near_the_boss` l'a démontré.
	_state = State.INTRO
	_timer = INTRO_TIME
	phase_changed.emit(state_name())


func _collect_crystals() -> void:
	for node: Node in _pivot.find_children("Crystal*", "HurtboxComponent",
			true, false):
		var crystal: HurtboxComponent = node as HurtboxComponent
		_crystals.append(crystal)
		_crystal_health.append(60.0)
		crystal.hit_received.connect(_on_crystal_hit.bind(crystal))
		crystal.monitorable = false   # ils n'apparaissent qu'en phase 2


func set_target(player: PlayerController) -> void:
	_target = player


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	_timer = maxf(0.0, _timer - delta)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if _attack.is_attacking():
		_attack.update(delta)
	_tick_strike_marks(delta)

	match _state:
		State.INTRO:
			if _timer <= 0.0:
				_enter(State.PHASE1)
		State.PHASE1:
			_process_combat(delta, 1.0)
		State.GROUNDED_STUN:
			velocity.x = 0.0
			velocity.z = 0.0
			if _timer <= 0.0:
				_apply_armour(true)
				_enter(State.PHASE1 if _health.ratio() > phase2_threshold \
					else State.PHASE2)
		State.TRANSITION12:
			velocity.x = 0.0
			velocity.z = 0.0
			if _timer <= 0.0:
				_enter(State.PHASE2)
		State.PHASE2:
			_process_combat(delta, 1.0)
			_tick_overload(delta)
		State.OVERLOAD:
			_process_combat(delta, 0.85)
			if _timer <= 0.0:
				_enter(State.PHASE2)
		State.TRANSITION23:
			velocity.x = 0.0
			velocity.z = 0.0
			if _timer <= 0.0:
				_enter(State.PHASE3)
		State.PHASE3:
			_process_combat(delta, PHASE3_SPEED_GAIN)
		State.STAGGER:
			velocity.x = 0.0
			velocity.z = 0.0
			if _timer <= 0.0:
				_enter(_phase_state())
		State.DEAD:
			velocity.x = 0.0
			velocity.z = 0.0
	_steer_inside_arena()
	move_and_slide()


## Rappel doux vers l'arène (§16.6). Il n'agit QU'AU-DELÀ du rayon : à
## l'intérieur, la poursuite est libre. Aucun téléport, aucune butée dure —
## la vitesse sortante est simplement retirée.
func _steer_inside_arena() -> void:
	if arena_radius <= 0.0:
		return
	var offset: Vector3 = global_position - arena_center
	offset.y = 0.0
	var distance: float = offset.length()
	if distance <= arena_radius or distance < 0.001:
		return
	var outward: Vector3 = offset / distance
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var escaping: float = horizontal.dot(outward)
	if escaping > 0.0:
		horizontal -= outward * escaping
	# Et on revient franchement vers le centre : sinon il longerait le mur.
	horizontal -= outward * minf(move_speed, (distance - arena_radius) * 4.0)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Poursuite et attaques, communes aux trois phases ; le rythme et le
## répertoire changent, pas le squelette.
func _process_combat(delta: float, speed_scale: float) -> void:
	if _target == null or not is_instance_valid(_target) \
			or _target.health().is_dead():
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	if distance > 0.01:
		var desired: float = atan2(-to_target.x, -to_target.z)
		_pivot.rotation.y = lerp_angle(_pivot.rotation.y, desired,
			minf(1.0, turn_speed * delta))
	if _attack.is_attacking():
		velocity.x = 0.0
		velocity.z = 0.0
		return
	if distance > melee_reach * 0.85:
		var direction: Vector3 = to_target.normalized()
		velocity.x = direction.x * move_speed * speed_scale
		velocity.z = direction.z * move_speed * speed_scale
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	if _attack_cooldown > 0.0:
		return
	_choose_attack(distance)


func _choose_attack(distance: float) -> void:
	# §16.3 : combo court au contact, arc frontal à distance, frappe de
	# zone annoncée. En phase 3, la charge précède la frappe au sol.
	if distance <= melee_reach:
		if _state == State.PHASE3 and randf() < 0.45:
			_start_ground_strike()
		else:
			_attack.try_attack()
		_attack_cooldown = 2.2 if _state != State.PHASE3 else 1.7
		return
	if distance <= arc_reach:
		_cast_arc()
		_attack_cooldown = 3.4 if _state != State.PHASE3 else 2.6


## L'ARC : c'est lui que les pylônes capturent (§16.3).
func _cast_arc() -> void:
	if _raised_pylons() >= 2:
		_ground_out()
		return
	_attack.try_heavy()


func _raised_pylons() -> int:
	var count: int = 0
	for pylon: GroundingPylon in _pylons:
		if pylon.is_raised():
			count += 1
	return count


## Mise à la terre : l'arc part dans les pylônes, le Gardien s'écroule et
## son noyau devient vulnérable (§16.3).
func _ground_out() -> void:
	_attack.cancel()
	_apply_armour(false)
	# Les pylônes se déchargent : il faudra les redresser.
	for pylon: GroundingPylon in _pylons:
		pylon.lower()
	_enter(State.GROUNDED_STUN)
	grounded.emit()


## §16.3 : l'armure réduit fortement les dégâts SANS invulnérabilité
## obscure ; le noyau, lui, n'est frappable que découvert.
func _apply_armour(intact: bool) -> void:
	_armour_intact = intact
	_body_hurtbox.damage_taken_multiplier = ARMOURED_MULTIPLIER if intact else 0.6
	_core_hurtbox.monitorable = not intact
	# Le noyau s'ALLUME quand il est frappable : c'est le seul retour qui
	# dit au joueur que la fenêtre est ouverte (§16.3, §15.4 de la bible).
	if _visual != null:
		_visual.set_core_exposed(not intact)


func _tick_overload(delta: float) -> void:
	if _crystals_alive() == 0:
		return
	_overload_cooldown -= delta
	if _overload_cooldown <= 0.0:
		_overload_cooldown = OVERLOAD_INTERVAL
		_enter(State.OVERLOAD)


func _crystals_alive() -> int:
	var alive: int = 0
	for i: int in range(_crystals.size()):
		if _crystal_health[i] > 0.0:
			alive += 1
	return alive


## §16.4 : « métal frappant pendant la surcharge risque un stun court ;
## bois/isolant évite ce risque ». La conductivité vient de l'ARME
## (§11.1), pas d'un cas particulier de boss.
func _on_damaged(event: DamageEvent) -> void:
	if _state != State.OVERLOAD or event == null:
		return
	var attacker: PlayerController = event.instigator as PlayerController
	if attacker == null:
		attacker = _target
	if attacker == null or not is_instance_valid(attacker):
		return
	var conductivity: float = _weapon_conductivity(attacker)
	if conductivity < 0.5:
		return   # bois, céramique : rien ne remonte
	var backlash: DamageEvent = DamageEvent.new()
	backlash.instigator = self
	backlash.team = &"enemies"
	backlash.damage_type = &"electric"
	backlash.element = &"electric"
	backlash.amount = 14.0 * conductivity * _player_resistance(attacker)
	backlash.direction = (attacker.global_position - global_position).normalized()
	backlash.position = attacker.global_position
	var hurtbox: HurtboxComponent = attacker.get_node_or_null("Hurtbox") \
		as HurtboxComponent
	if hurtbox != null:
		hurtbox.receive_hit(backlash)


func _weapon_conductivity(player: PlayerController) -> float:
	if player.inventory() == null:
		return 0.0
	var weapon: WeaponInstance = player.inventory().equipped()
	if weapon == null or weapon.definition == null:
		return 0.0
	return weapon.definition.conductivity


## §13.5 : la résistance électrique réduit les dégâts ET la durée du stun.
func _player_resistance(player: PlayerController) -> float:
	if player.status() == null:
		return 1.0
	return player.status().elec_damage_multiplier()


func _on_crystal_hit(event: DamageEvent, crystal: HurtboxComponent) -> void:
	var index: int = _crystals.find(crystal)
	if index < 0 or _crystal_health[index] <= 0.0:
		return
	_crystal_health[index] = maxf(0.0, _crystal_health[index] - event.amount)
	if _crystal_health[index] > 0.0:
		return
	crystal.monitorable = false
	if _visual != null:
		_visual.set_crystal_visible(crystal.name, false)
	crystal_destroyed.emit(_crystals_alive())
	# §16.5 : « noyau exposé après destruction des cristaux ».
	if _crystals_alive() == 0:
		_apply_armour(false)


## §16.5 : marques au sol AVANT l'éclair. La fenêtre est réelle et
## mesurable — c'est ce que teste `test_boss`.
func _start_ground_strike() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var mark: Node3D = preload("res://scripts/boss/lightning_strike.gd").new() \
		as Node3D
	mark.set("telegraph", STRIKE_TELEGRAPH)
	mark.set("target_position", _target.global_position)
	get_parent().add_child(mark)
	mark.global_position = _target.global_position
	_strike_marks.append(mark)


func _tick_strike_marks(_delta: float) -> void:
	for i: int in range(_strike_marks.size() - 1, -1, -1):
		if not is_instance_valid(_strike_marks[i]):
			_strike_marks.remove_at(i)


func _enter(state: State) -> void:
	if _state == state:
		return
	_state = state
	match state:
		State.INTRO:
			_timer = INTRO_TIME
		State.GROUNDED_STUN:
			_timer = GROUNDED_TIME
		State.TRANSITION12, State.TRANSITION23:
			_timer = TRANSITION_TIME
		State.OVERLOAD:
			_timer = OVERLOAD_TIME
		State.STAGGER:
			_timer = 1.0
		State.PHASE2:
			_reveal_crystals()
			# §16.4/§16.5 : en phase 2 le noyau se REFERME derrière les
			# cristaux ; il ne se rouvre qu'à leur destruction. Sans cette
			# ligne, une mise à la terre obtenue en phase 1 laissait le
			# noyau nu pour tout le reste du combat.
			_apply_armour(_crystals_alive() > 0)
		State.PHASE3:
			_apply_armour(_crystals_alive() > 0)
			# §16.5 de la bible : « certaines plaques pendent », l'anneau
			# divisé tourne de travers. La silhouette raconte la phase.
			if _visual != null:
				_visual.hang_armour(0.5)
	phase_changed.emit(state_name())


## §16.4 : les deux cristaux conducteurs apparaissent en phase 2.
func _reveal_crystals() -> void:
	for i: int in range(_crystals.size()):
		if _crystal_health[i] <= 0.0:
			continue
		_crystals[i].monitorable = true
		if _visual != null:
			_visual.set_crystal_visible(_crystals[i].name, true)


func _phase_state() -> State:
	var ratio: float = _health.ratio()
	if ratio <= phase3_threshold:
		return State.PHASE3
	if ratio <= phase2_threshold:
		return State.PHASE2
	return State.PHASE1


## §16.2 : « un seuil de PV ne peut déclencher deux fois ». Le passage est
## marqué une fois pour toutes.
func _check_thresholds() -> void:
	var ratio: float = _health.ratio()
	if ratio <= phase2_threshold and not _thresholds_crossed.has(&"p2"):
		_thresholds_crossed[&"p2"] = true
		_enter(State.TRANSITION12)
		return
	if ratio <= phase3_threshold and not _thresholds_crossed.has(&"p3"):
		_thresholds_crossed[&"p3"] = true
		_enter(State.TRANSITION23)


func _on_died(_event: DamageEvent) -> void:
	if _state == State.DEAD:
		return
	# §16.2 : la mort interrompt toute attaque, coupe hitboxes et timers.
	_attack.cancel()
	_state = State.DEAD
	velocity = Vector3.ZERO
	for hitbox: Node in find_children("*", "HitboxComponent", true, false):
		(hitbox as HitboxComponent).deactivate()
	for hurtbox: Node in find_children("*", "HurtboxComponent", true, false):
		(hurtbox as HurtboxComponent).monitorable = false
	for mark: Node3D in _strike_marks:
		if is_instance_valid(mark):
			mark.queue_free()
	_strike_marks.clear()
	for pylon: GroundingPylon in _pylons:
		pylon.lower()
	set_physics_process(false)
	phase_changed.emit(state_name())
	died.emit()


func _process(_delta: float) -> void:
	# Les seuils sont relus hors du tick physique : la vie peut tomber
	# pendant une attaque, la transition attend la fin du geste.
	#
	# `GROUNDED_STUN` a d'abord figuré dans cette liste, et c'était un
	# défaut de conception : le run complet a montré un Gardien tué
	# ENTIÈREMENT pendant sa première fenêtre de noyau, sans jamais voir
	# les phases 2 et 3 de §16.4 et §16.5. Un seuil de vie franchi doit
	# gagner contre un étourdissement — l'armure qui se fend interrompt la
	# mise à la terre, elle ne l'attend pas.
	if _state in [State.DEAD, State.INTRO, State.TRANSITION12,
			State.TRANSITION23]:
		return
	_check_thresholds()


func state_name() -> StringName:
	match _state:
		State.INTRO: return &"intro"
		State.PHASE1: return &"phase1"
		State.GROUNDED_STUN: return &"grounded_stun"
		State.TRANSITION12: return &"transition12"
		State.PHASE2: return &"phase2"
		State.OVERLOAD: return &"overload"
		State.TRANSITION23: return &"transition23"
		State.PHASE3: return &"phase3"
		State.STAGGER: return &"stagger"
		State.DEAD: return &"dead"
	return &"?"


func state() -> State:
	return _state


func health() -> HealthComponent:
	return _health


func is_armoured() -> bool:
	return _armour_intact


func crystals_alive() -> int:
	return _crystals_alive()


func pylons() -> Array[GroundingPylon]:
	return _pylons


func strike_marks() -> Array[Node3D]:
	return _strike_marks


## Force un état — utilisé par les tests et la capture pour observer une
## phase sans jouer les précédentes. Aucune règle de jeu ne l'appelle.
func debug_force_state(state: State) -> void:
	_enter(state)
