## Zone vulnérable (MASTER_SPEC §5.8, §10.1).
##
## La hurtbox **reçoit** : elle ne détecte rien (`monitoring` coupé — c'est la
## hitbox qui balaie), elle route l'événement vers la santé et le republie pour
## les couches de présentation. Couche de collision attendue : `Hurtbox` (6,
## §5.7), masque nul.
##
## `weak_point_multiplier` est le facteur « point faible » de §10.3 : le dos du
## colosse ou la tête d'un pillard sont des hurtbox distinctes portant un
## multiplicateur > 1 — pas des cas particuliers dans le code de l'attaquant.
class_name HurtboxComponent
extends Area3D

signal hit_received(event: DamageEvent)

## Équipe du propriétaire (`player`, `enemies` — §5.7). La hitbox refuse le tir
## ami en comparant les équipes.
@export var team: StringName = &""
## Facteur de point faible (§10.3), appliqué par la FORMULE côté hitbox — la
## hurtbox le déclare, elle ne calcule rien.
@export var weak_point_multiplier: float = 1.0
## Santé du propriétaire. NodePath exporté plutôt que `get_node()` en dur (§5.4).
@export var health_path: NodePath

@onready var _health: HealthComponent = get_node_or_null(health_path) as HealthComponent


func _ready() -> void:
	# Récepteur pur : détectable, jamais détecteur.
	monitoring = false
	monitorable = true


## Point d'entrée unique des dégâts. L'événement arrive complet (§10.3) : il est
## transmis, jamais recalculé.
## E.2a (§13.5) : multiplicateur du buff de DÉFENSE (×0.75 actif) — appliqué
## AVANT l'émission : le recul, la réaction et la santé voient le même chiffre.
var damage_taken_multiplier: float = 1.0


func receive_hit(event: DamageEvent) -> void:
	if event == null:
		return
	event.amount *= damage_taken_multiplier
	hit_received.emit(event)
	if _health != null and is_instance_valid(_health):
		_health.take_damage(event)


func health() -> HealthComponent:
	return _health
