## Exécution d'attaque (MASTER_SPEC §10.1, §10.2, §10.6).
##
## Machine à trois phases — STARTUP → ACTIVE → RECOVERY — pilotée par les nombres
## d'une `AttackDefinition`, jamais par une animation (§10.6 : « l'animation et
## les effets se calent sur le contrat ; ils ne redéfinissent pas silencieusement
## la logique »). La hitbox est allumée exactement pendant la fenêtre active.
##
## Enchaînement (§10.2) : un appui pendant l'attaque est mémorisé `input_buffer`
## secondes ; si la fenêtre d'enchaînement — les derniers `combo_window_fraction`
## de la recovery — s'ouvre pendant que la mémoire est fraîche, le coup suivant
## part immédiatement, annulant le reste de la récupération. Sinon l'attaque se
## termine et le combo repart de zéro. Un appui APRÈS l'ouverture de la fenêtre
## part au tick suivant (§10.6 : « en un à deux ticks après la première fenêtre
## légale »).
##
## Le propriétaire appelle `update(delta)` à son rythme physique, comme pour
## `StaminaComponent` — le composant ne se traite jamais tout seul.
class_name AttackControllerComponent
extends Node

signal attack_started(definition: AttackDefinition, combo_index: int)
signal attack_phase_changed(phase: StringName)
signal attack_finished()

enum Phase { IDLE, STARTUP, ACTIVE, RECOVERY }

## Chaîne du combo léger, dans l'ordre (§10.2 : trois pour l'épée).
@export var attacks: Array[AttackDefinition] = []
## Attaque lourde (§10.2), hors chaîne : elle part de l'idle, ne s'enchaîne pas.
## Son coût d'endurance (§9.1 : 20) est vérifié par le PROPRIÉTAIRE avant
## `try_heavy()` — ce composant ne connaît pas l'endurance, comme la hitbox ne
## connaît pas les armes.
@export var heavy_attack: AttackDefinition
@export var hitbox_path: NodePath
## Dégâts SANS arme : les mains nues du joueur, ou l'arme « de corps » d'un
## ennemi qui n'a pas d'inventaire (le gourdin du pillard est son bras). Une
## `WeaponInstance` équipée via `set_weapon()` remplace cette valeur par le
## `base_damage` de sa définition (§11.1). Le terme « buff » de §10.3 arrivera
## avec la cuisine (Phase E).
@export var base_damage: float = 12.0

@onready var _hitbox: HitboxComponent = get_node_or_null(hitbox_path) as HitboxComponent

## Arme en main (§11.1) — `null` = mains nues, la valeur exportée s'applique.
var _weapon: WeaponInstance = null
## Chaîne exportée d'origine, restaurée quand l'arme (et son `attack_set`) part.
var _default_heavy: AttackDefinition = null
var _default_attacks: Array[AttackDefinition] = []

func _ready() -> void:
	_default_attacks = attacks
	_default_heavy = heavy_attack


## Équipe une arme (§11.1) : ses dégâts remplacent la valeur exportée, son
## `attack_set` remplace la chaîne si elle en déclare un. `null` rend les mains
## nues. Un changement en plein coup interrompt le coup — le contrat de §10.6
## appartient à l'action en cours, pas à la suivante.
func set_weapon(weapon: WeaponInstance) -> void:
	if _phase != Phase.IDLE:
		cancel()
	_weapon = weapon
	if weapon != null and not weapon.definition.attack_set.is_empty():
		attacks = weapon.definition.attack_set
	else:
		attacks = _default_attacks
	# P2 §7.5 : la LOURDE aussi suit la famille — plus jamais la lourde
	# d'épée pour tout le monde. Repli : l'export historique de la scène.
	if weapon != null and weapon.definition.heavy_attack != null:
		heavy_attack = weapon.definition.heavy_attack
	else:
		heavy_attack = _default_heavy


func weapon() -> WeaponInstance:
	return _weapon


## Base côté attaquant de la formule §10.3 : l'arme si elle existe, sinon la
## valeur exportée (mains nues).
func attack_damage_base() -> float:
	if _weapon != null and _weapon.definition != null:
		return _weapon.definition.base_damage
	return base_damage


var _phase: Phase = Phase.IDLE
var _index: int = 0
## Définition en cours d'exécution : un maillon de `attacks`, ou `heavy_attack`
## (auquel cas `_index` vaut -1 et rien ne s'enchaîne).
var _current: AttackDefinition = null
var _elapsed: float = 0.0
## Temps restant de validité de l'appui mémorisé (§10.2 : 0,15 s).
var _buffer_timer: float = 0.0


## Demande d'attaque — front d'intention. Retourne `true` si un coup part
## immédiatement ; sinon l'appui est mémorisé et `update()` décidera.
func try_attack() -> bool:
	if attacks.is_empty() or _hitbox == null:
		return false
	if _phase == Phase.IDLE:
		_begin(0)
		return true
	if _phase == Phase.RECOVERY and _index >= 0 \
			and _elapsed >= _current.combo_open_time() and _index + 1 < attacks.size():
		# Fenêtre déjà ouverte : le coup suivant part sans attendre le tick d'après.
		_begin(_index + 1)
		return true
	_buffer_timer = _current.input_buffer
	return false


## Attaque lourde (§10.2) : depuis l'idle uniquement. Pas de buffer — un appui
## lourd pendant une autre action est perdu, limite assumée de C.3.
func try_heavy() -> bool:
	if heavy_attack == null or _hitbox == null:
		return false
	if _phase != Phase.IDLE:
		return false
	_current = heavy_attack
	_index = -1
	_elapsed = 0.0
	_buffer_timer = 0.0
	_phase = Phase.STARTUP
	attack_started.emit(heavy_attack, -1)
	attack_phase_changed.emit(&"startup")
	return true


## À appeler une fois par tick physique. Retourne `true` tant qu'une attaque est
## en cours — le propriétaire s'en sert pour savoir quand rendre la locomotion.
func update(delta: float) -> bool:
	if _phase == Phase.IDLE:
		return false
	_elapsed += delta
	_buffer_timer = maxf(0.0, _buffer_timer - delta)

	match _phase:
		Phase.STARTUP:
			if _elapsed >= _current.startup:
				_phase = Phase.ACTIVE
				_hitbox.activate(attack_damage_base() * _current.damage_multiplier,
					_current.poise_damage, _current.knockback, &"melee",
					_current.element, _current.hit_stop,
					_current.posture_damage)
				# §18.2 : le sifflement du swing, joueur comme ennemi — le
				# contrôleur est partagé, le son l'est aussi.
				var audio: Node = get_node_or_null("/root/AudioManager")
				if audio != null:
					audio.call("play_sfx", &"swing")
				attack_phase_changed.emit(&"active")
		Phase.ACTIVE:
			if _elapsed >= _current.startup + _current.active:
				_phase = Phase.RECOVERY
				_hitbox.deactivate()
				attack_phase_changed.emit(&"recovery")
		Phase.RECOVERY:
			# §10.2 : l'appui mémorisé enchaîne dès l'ouverture de la fenêtre.
			# Jamais depuis la lourde (_index -1) : elle ne fait pas partie de la
			# chaîne.
			if _buffer_timer > 0.0 and _index >= 0 \
					and _elapsed >= _current.combo_open_time() \
					and _index + 1 < attacks.size():
				_begin(_index + 1)
				return true
			if _elapsed >= _current.total_duration():
				# §10.6 : « l'action bufferisée part à la première fenêtre légale ».
				# Au bout du DERNIER coup, la première fenêtre légale est la fin du
				# combo : un appui encore frais relance un combo neuf. Sans ce
				# report, un appui posé 0,1 s avant la fin serait perdu — exactement
				# l'entrée avalée que §10.6 interdit.
				if _buffer_timer > 0.0:
					_begin(0)
					return true
				_finish()
				return false
	return true


## Interruption externe (stagger, mort — C.2). Coupe la hitbox proprement :
## §16.2 exige que la mort interrompe « toute attaque, hitboxes et timers ».
func cancel() -> void:
	if _phase == Phase.IDLE:
		return
	_hitbox.deactivate()
	_phase = Phase.IDLE
	_index = 0
	_buffer_timer = 0.0
	attack_finished.emit()


func _begin(index: int) -> void:
	# Un enchaînement pendant la fenêtre active de l'ancien coup n'existe pas
	# (la fenêtre d'enchaînement est dans la recovery), mais un `_begin` doit
	# rester sûr : hitbox éteinte avant d'ouvrir le coup suivant.
	if _hitbox.is_active():
		_hitbox.deactivate()
	_index = index
	_current = attacks[index]
	_elapsed = 0.0
	_buffer_timer = 0.0
	_phase = Phase.STARTUP
	attack_started.emit(_current, _index)
	attack_phase_changed.emit(&"startup")


func _finish() -> void:
	_phase = Phase.IDLE
	_index = 0
	attack_finished.emit()


func is_attacking() -> bool:
	return _phase != Phase.IDLE


func phase() -> Phase:
	return _phase


func combo_index() -> int:
	return _index


## Définition en cours d'exécution — consommée par la pose d'arme graybox
## (PT-D1-03) et l'instrumentation du CombatLab (§10.8).
func current_attack() -> AttackDefinition:
	return _current if _phase != Phase.IDLE else null


## Exposé pour l'instrumentation du `CombatLab` (§10.8) : temps écoulé dans
## l'action courante.
func elapsed() -> float:
	return _elapsed
