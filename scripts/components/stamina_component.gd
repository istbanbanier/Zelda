## Endurance partagée par plusieurs actions (MASTER_SPEC §9.1, §5.8).
##
## Composant, pas classe de base : §5.4 impose la composition. Le sprint le
## consomme dès B.2 ; l'escalade (§9.2), l'esquive et l'attaque lourde (§10.2) s'y
## brancheront sans le modifier — c'est tout l'intérêt de le sortir du contrôleur.
##
## Protocole d'appel, à respecter par le propriétaire :
##   1. demander l'effort du tick — `try_sustain()` (continu) ou `try_spend()`
##      (instantané) ;
##   2. appeler `update(delta)` **une seule fois**, après les demandes.
## `update()` sait si le tick a consommé quelque chose ; c'est ce qui distingue
## « je viens de sprinter » de « je suis à l'arrêt depuis une seconde » sans que le
## propriétaire ait à le lui dire.
class_name StaminaComponent
extends Node

## Émis à chaque variation utile de la jauge — pour la jauge contextuelle de
## §17.2, qui n'existe pas encore.
signal changed(current: float, maximum: float)
## Émis au passage à zéro (§9.1 : sprint qui retombe en course, lâcher du mur,
## attaque lourde refusée).
signal exhausted()
## Émis quand l'épuisement se lève : verrou écoulé **et** jauge non nulle.
signal recovered()

@export var tuning: StaminaTuning

var _current: float = 0.0
var _time_since_spend: float = 0.0
var _regen_ramp_timer: float = 0.0
var _exhausted: bool = false
var _lockout_timer: float = 0.0
## Remis à faux par `update()` : le propriétaire n'a pas à gérer ce drapeau.
var _spent_this_tick: bool = false


func _ready() -> void:
	if tuning == null:
		tuning = StaminaTuning.new()
		push_warning("[stamina] aucun StaminaTuning assigné — valeurs par défaut utilisées.")
	_current = tuning.max_stamina


## Effort continu (sprint, escalade). Retourne `true` si l'effort a pu être
## soutenu ce tick. Un refus n'est pas une erreur : c'est la bascule sprint →
## course de §9.1.
func try_sustain(rate_per_second: float, delta: float) -> bool:
	if not can_sustain():
		return false
	_consume(rate_per_second * delta)
	return true


## Coût instantané (saut d'escalade, esquive, attaque lourde). Ne consomme **rien**
## si le coût n'est pas payable : pas de jauge vidée à moitié pour une action qui
## n'a pas eu lieu.
func try_spend(cost: float) -> bool:
	if not can_spend(cost):
		return false
	_consume(cost)
	return true


## L'effort continu est-il possible ce tick ?
##
## L'épuisement bloque ici, mais **pas** dans `can_spend()` : une action ponctuelle
## payable doit rester possible dès que le verrou est écoulé. Ce sont les efforts
## soutenus qui bégaieraient s'ils reprenaient à la première unité régénérée
## (D-016).
func can_sustain() -> bool:
	return not _exhausted and _current > 0.0 and _lockout_timer <= 0.0


## Le coût est-il payable maintenant ? Deux raisons de refuser, distinctes :
## la réserve est insuffisante, ou le verrou d'épuisement court encore.
func can_spend(cost: float) -> bool:
	return _current >= cost and _lockout_timer <= 0.0


## À appeler une fois par tick physique, après les demandes d'effort.
func update(delta: float) -> void:
	if _lockout_timer > 0.0:
		_lockout_timer = maxf(0.0, _lockout_timer - delta)

	if _spent_this_tick:
		_spent_this_tick = false
	else:
		_time_since_spend += delta
		if _time_since_spend >= tuning.regen_delay:
			_regenerate(delta)

	# L'épuisement ne se lève ni au seul écoulement du verrou, ni à la première
	# unité régénérée : il faut une réserve réellement utilisable (D-016). Le seuil
	# est borné au maximum, sinon un réglage trop ambitieux rendrait la
	# récupération impossible.
	var threshold: float = minf(tuning.exhaustion_recovery_threshold, tuning.max_stamina)
	if _exhausted and _lockout_timer <= 0.0 and _current >= threshold:
		_exhausted = false
		recovered.emit()


func _regenerate(delta: float) -> void:
	if is_equal_approx(_current, tuning.max_stamina):
		return
	# « Reprise progressive » (§9.1) : le régime monte sur `regen_ramp` au lieu de
	# s'appliquer d'un bloc.
	_regen_ramp_timer += delta
	var ramp: float = 1.0
	if tuning.regen_ramp > 0.0:
		ramp = clampf(_regen_ramp_timer / tuning.regen_ramp, 0.0, 1.0)
	var before: float = _current
	_current = minf(tuning.max_stamina, _current + tuning.regen_rate * ramp * delta)
	if not is_equal_approx(before, _current):
		changed.emit(_current, tuning.max_stamina)


func _consume(amount: float) -> void:
	if amount <= 0.0:
		return
	_spent_this_tick = true
	_time_since_spend = 0.0
	_regen_ramp_timer = 0.0
	_current = maxf(0.0, _current - amount)
	changed.emit(_current, tuning.max_stamina)
	if _current <= 0.0 and not _exhausted:
		_exhausted = true
		_lockout_timer = tuning.exhaustion_lockout
		exhausted.emit()


func current() -> float:
	return _current


func maximum() -> float:
	return tuning.max_stamina


## Fraction 0–1, pour la jauge de §17.2.
func ratio() -> float:
	if tuning.max_stamina <= 0.0:
		return 0.0
	return _current / tuning.max_stamina


func is_exhausted() -> bool:
	return _exhausted


## Réservé aux tests et à la restauration de sauvegarde (§19.1). Le gameplay passe
## par `try_sustain()` / `try_spend()`.
func set_current(value: float) -> void:
	_current = clampf(value, 0.0, tuning.max_stamina)
	changed.emit(_current, tuning.max_stamina)
