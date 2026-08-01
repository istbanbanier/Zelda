## Zone de frappe (MASTER_SPEC §5.8, §10.1).
##
## Pipeline de §10.1, à la lettre : activation **par méthode** → set des cibles
## déjà touchées → dégâts/poise/recul/élément appliqués **une fois** par cible et
## par swing → désactivation. « Jamais de dégâts à chaque frame d'overlap » : le
## set `_already_hit` est la pièce qui tient cette exigence, et le critère
## central du Gate C — « une touche par swing ».
##
## Détection par **balayage physique** plutôt que par signal `area_entered` : une
## hurtbox déjà en chevauchement au moment de l'activation (cas normal d'un coup
## d'épée) doit être touchée au tick suivant, pas au hasard d'un événement
## d'entrée. Un seul chemin de code, déterministe. Le balayage ne tourne que
## pendant la fenêtre active (§5.4 : pas de `_physics_process` sur nœud dormant).
##
## Couches attendues (§5.7) : `Player Hitbox` (4) ou `Enemy Hitbox` (5) en
## couche, `Hurtbox` (6) en masque.
class_name HitboxComponent
extends Area3D

signal hit_confirmed(event: DamageEvent, target: HurtboxComponent)

## Équipe de l'attaquant. Une hurtbox de la même équipe n'est jamais touchée.
@export var team: StringName = &""
## Propriétaire logique du coup, rapporté dans l'événement (§10.3).
@export var instigator_path: NodePath

## Compteur global d'identifiants de swing (§10.1, §10.8) : deux activations ne
## partagent jamais un ID, même sur deux hitbox différentes. Les projectiles
## (§10.4) puisent au même compteur via `next_attack_id()` : un ID unique par
## flèche, comme par swing.
static var _next_attack_id: int = 1


static func next_attack_id() -> int:
	var id: int = _next_attack_id
	_next_attack_id += 1
	return id

@onready var _instigator: Node = get_node_or_null(instigator_path)

var _active: bool = false
var _attack_id: int = 0
## Dégâts côté attaquant : base × weapon × attack × buff (§10.3), calculés par
## l'appelant AVANT l'activation. Le côté défenseur est appliqué au contact.
var _attacker_damage: float = 0.0
var _poise_damage: float = 0.0
var _knockback: float = 0.0
var _damage_type: StringName = &""
var _element: StringName = &""
## Cibles déjà touchées pendant CE swing, par identifiant d'instance.
var _already_hit: Array[int] = []


func _ready() -> void:
	# `monitoring` reste allumé EN PERMANENCE, et c'est mesuré, pas un oubli :
	# le couper à `deactivate()` puis le rallumer à l'`activate()` suivant dans la
	# même frame laisse la liste de chevauchements **définitivement vide** — sonde
	# sur le moteur installé : hurtbox en plein chevauchement, `overlaps=0` six
	# frames après la réactivation (R-014). La fenêtre active est donc portée par
	# `_active` et par le balayage, seuls arbitres ; le coût d'un suivi de paires
	# permanent est négligeable devant un swing perdu un tick sur deux.
	monitoring = true
	monitorable = false
	set_physics_process(false)


## Ouvre la fenêtre active d'un swing. `attacker_damage` est le produit
## base × weapon × attack × buff de §10.3 — l'appelant (le contrôleur d'attaque,
## en C.1) le calcule ; la hitbox ne connaît pas les armes.
func activate(attacker_damage: float, poise_damage: float = 0.0,
		knockback: float = 0.0, damage_type: StringName = &"melee",
		element: StringName = &"") -> int:
	_attacker_damage = attacker_damage
	_poise_damage = poise_damage
	_knockback = knockback
	_damage_type = damage_type
	_element = element
	_already_hit.clear()
	_attack_id = next_attack_id()
	_active = true
	set_physics_process(true)
	return _attack_id


## Ferme la fenêtre. Le set des cibles touchées meurt avec le swing : le
## prochain `activate()` repart de zéro et peut retoucher les mêmes cibles.
func deactivate() -> void:
	_active = false
	set_physics_process(false)


func is_active() -> bool:
	return _active


func current_attack_id() -> int:
	return _attack_id


func _physics_process(_delta: float) -> void:
	if not _active:
		return
	for area: Area3D in get_overlapping_areas():
		_process_target(area)


func _process_target(area: Area3D) -> void:
	var hurtbox: HurtboxComponent = area as HurtboxComponent
	if hurtbox == null:
		return
	if hurtbox.team == team:
		return  # jamais de tir ami par accident de couche
	var target_id: int = hurtbox.get_instance_id()
	if _already_hit.has(target_id):
		return  # §10.1 : une touche par cible et par swing
	_already_hit.append(target_id)

	var event: DamageEvent = DamageEvent.new()
	event.instigator = _instigator
	event.team = team
	event.damage_type = _damage_type
	# Côté défenseur de la formule (§10.3) : point faible déclaré par la hurtbox.
	# Résistance et armure arriveront avec les buffs et les définitions d'ennemis
	# (C.2) — neutres d'ici là, et déjà à leur place dans la formule.
	event.amount = DamageFormula.compute(_attacker_damage, hurtbox.weak_point_multiplier)
	event.poise_damage = _poise_damage
	event.knockback = _knockback
	event.element = _element
	event.attack_id = _attack_id
	event.position = hurtbox.global_position
	var flat: Vector3 = hurtbox.global_position - global_position
	flat.y = 0.0
	event.direction = flat.normalized() if flat.length_squared() > 0.0001 else Vector3.ZERO

	hurtbox.receive_hit(event)
	hit_confirmed.emit(event, hurtbox)
