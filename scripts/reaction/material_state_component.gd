## État matière d'UNE instance (P2 §4.2) — le pendant mutable de
## `MaterialProfile` (immuable). Deux caisses de bois partagent le profil,
## jamais leur humidité.
##
## Les transitions sont décidées par `ReactionSystem` (l'arbitre) qui appelle
## les méthodes typées ci-dessous ; ce composant ne résout RIEN lui-même, il
## porte l'état, les minuteries de décroissance et les signaux. Idempotent :
## un signal ne part qu'au changement (patron `ElectricNode.set_powered`).
##
## Décroissances au tick physique, mais UNIQUEMENT quand un état est actif :
## `set_physics_process(false)` au repos (règle CLAUDE.md : pas de `_process`
## sur des nœuds dormants).
class_name MaterialStateComponent
extends Node

signal state_changed(state: StringName, active: bool)
signal charge_changed(amount: float)
signal overloaded()

const STATE_WET: StringName = &"wet"
const STATE_CHARGED: StringName = &"charged"
const STATE_GROUNDED: StringName = &"grounded"
const STATE_OVERLOADED: StringName = &"overloaded"
const STATE_BURNING: StringName = &"burning"
const STATE_FRACTURED: StringName = &"fractured"

## Durées de décroissance (secondes). Data de départ P2 §4.2, tunables.
const WET_DURATION_ABSORBENT: float = 20.0
const WET_DURATION_SURFACE: float = 6.0
const BURN_DURATION: float = 8.0
const GROUNDED_DURATION: float = 1.2
const CHARGE_DECAY_PER_SECOND: float = 0.35
## La surcharge télégraphie PUIS décharge (P2 §4.2 : jamais punition
## instantanée) — fenêtre de télégraphe :
const OVERLOAD_TELEGRAPH: float = 0.9

@export var profile: MaterialProfile = null

var _wet_timer: float = 0.0
var _burn_timer: float = 0.0
var _grounded_timer: float = 0.0
var _overload_timer: float = 0.0
var _charge: float = 0.0
var _fractured: bool = false


func _ready() -> void:
	set_physics_process(false)


func is_wet() -> bool: return _wet_timer > 0.0
func is_burning() -> bool: return _burn_timer > 0.0
func is_grounded() -> bool: return _grounded_timer > 0.0
func is_overloaded() -> bool: return _overload_timer > 0.0
func is_fractured() -> bool: return _fractured
func charge() -> float: return _charge
func is_charged() -> bool: return _charge > 0.0


## --- Mutations, appelées par ReactionSystem uniquement ---

func soak(duration_scale: float = 1.0) -> void:
	var was: bool = is_wet()
	var base: float = WET_DURATION_ABSORBENT if profile != null and profile.absorbs_water \
		else WET_DURATION_SURFACE
	_wet_timer = maxf(_wet_timer, base * duration_scale)
	# L'eau éteint (P2 §4.2 : « eau éteint »).
	if is_burning():
		_extinguish()
	if not was:
		state_changed.emit(STATE_WET, true)
	_wake()


func ignite() -> void:
	if is_burning() or _fractured:
		return
	_burn_timer = BURN_DURATION
	state_changed.emit(STATE_BURNING, true)
	_wake()


func add_charge(amount: float) -> void:
	if profile == null or profile.charge_capacity <= 0.0:
		return
	var before: float = _charge
	_charge = minf(_charge + amount, profile.charge_capacity)
	if before <= 0.0 and _charge > 0.0:
		state_changed.emit(STATE_CHARGED, true)
	if not is_equal_approx(before, _charge):
		charge_changed.emit(_charge)
	# Saturation ET apport encore entrant = surcharge télégraphiée.
	if _charge >= profile.charge_capacity and amount > 0.0 and before >= profile.charge_capacity \
			and _overload_timer <= 0.0:
		_overload_timer = OVERLOAD_TELEGRAPH
		state_changed.emit(STATE_OVERLOADED, true)
		_wake()
	_wake()


func ground() -> void:
	var had_charge: bool = _charge > 0.0
	if had_charge:
		_charge = 0.0
		charge_changed.emit(0.0)
		state_changed.emit(STATE_CHARGED, false)
	if _overload_timer > 0.0:
		_overload_timer = 0.0
		state_changed.emit(STATE_OVERLOADED, false)
	_grounded_timer = GROUNDED_DURATION
	state_changed.emit(STATE_GROUNDED, true)
	_wake()


func fracture() -> void:
	if _fractured:
		return
	_fractured = true
	state_changed.emit(STATE_FRACTURED, true)


## --- Décroissances ---

func _physics_process(delta: float) -> void:
	var busy: bool = false
	if _wet_timer > 0.0:
		_wet_timer -= delta
		if _wet_timer <= 0.0:
			state_changed.emit(STATE_WET, false)
		else:
			busy = true
	if _burn_timer > 0.0:
		_burn_timer -= delta
		if _burn_timer <= 0.0:
			state_changed.emit(STATE_BURNING, false)
		else:
			busy = true
	if _grounded_timer > 0.0:
		_grounded_timer -= delta
		if _grounded_timer <= 0.0:
			state_changed.emit(STATE_GROUNDED, false)
		else:
			busy = true
	if _overload_timer > 0.0:
		_overload_timer -= delta
		if _overload_timer <= 0.0:
			# Fin du télégraphe : décharge — le système écoute `overloaded`
			# pour émettre le paquet de zone ; l'état local se vide.
			_charge = 0.0
			charge_changed.emit(0.0)
			state_changed.emit(STATE_CHARGED, false)
			state_changed.emit(STATE_OVERLOADED, false)
			overloaded.emit()
		else:
			busy = true
	if _charge > 0.0 and _overload_timer <= 0.0:
		var before: float = _charge
		_charge = maxf(0.0, _charge - CHARGE_DECAY_PER_SECOND * delta)
		if _charge <= 0.0 and before > 0.0:
			charge_changed.emit(0.0)
			state_changed.emit(STATE_CHARGED, false)
		else:
			busy = true
	if not busy and _charge <= 0.0:
		set_physics_process(false)


func _extinguish() -> void:
	if _burn_timer > 0.0:
		_burn_timer = 0.0
		state_changed.emit(STATE_BURNING, false)


func _wake() -> void:
	set_physics_process(true)
