## Mannequin d'entraînement (MASTER_SPEC §10.8) — cible de test, pas un ennemi.
##
## Il encaisse, il compte, il meurt proprement (§12.10 : à la mort, plus aucune
## collision ni hurtbox active — un cadavre ne bloque rien). L'IA, la perception
## et les vraies familles d'ennemis arrivent en C.2+ ; ce mannequin sert le
## `CombatLab` et les tests d'échange.
class_name CombatDummy
extends StaticBody3D

signal dummy_died()

@onready var _health: HealthComponent = $HealthComponent
@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	_health.died.connect(_on_died)


func _on_died(_event: DamageEvent) -> void:
	# §12.10 : couper hitboxes et collision à la mort, une seule fois.
	_hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	if _mesh != null:
		_mesh.transparency = 0.8
	dummy_died.emit()


func health() -> HealthComponent:
	return _health
