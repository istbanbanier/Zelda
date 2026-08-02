## Objet TRANSPORTABLE (MASTER_SPEC §14.2 « ramasser / transporter /
## poser », §15.8 « batterie chargeable et transportable »).
##
## Hérite de `PushableBlock` : un objet qu'on porte reste un corps simulé
## qu'on peut aussi pousser, et il conserve le filet de §14.3 — zone hors
## limites, transform de secours, retour après 1 à 2 s.
##
## Pendant le transport, le corps est GELÉ en mode cinématique et suivi
## sur le point de port du joueur : §14.1 interdit d'écrire le transform
## d'un rigid body ACTIF, pas d'un corps gelé prévu pour cela. Au lâcher,
## il repart dans la simulation avec une vitesse bornée.
class_name CarryableObject
extends PushableBlock

signal picked_up()
signal dropped()

## Étiquette libre : un socket n'accepte que ce qu'il attend.
@export var carry_tag: StringName = &"object"
@export var verb_take: String = "Prendre"
@export var verb_drop: String = "Poser"
## Point de port, relatif au joueur : devant lui, à hauteur de poitrine.
@export var carry_offset: Vector3 = Vector3(0, 1.15, -0.9)
## Distance de dépose devant le joueur.
@export var drop_distance: float = 1.1

var _carrier: PlayerController = null
var _seated: bool = false


func _ready() -> void:
	super()
	add_to_group("interactable")
	add_to_group("carryable")
	mass = 12.0


func prompt_verb() -> String:
	return verb_drop if _carrier != null else verb_take


func interact(player: PlayerController) -> bool:
	if _carrier != null:
		return drop()
	return pick_up(player)


func pick_up(player: PlayerController) -> bool:
	if player == null or _carrier != null:
		return false
	_carrier = player
	_seated = false
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	picked_up.emit()
	return true


func drop() -> bool:
	if _carrier == null:
		return false
	var forward: Vector3 = -_carrier.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
	var target: Vector3 = _carrier.global_position \
		+ forward.normalized() * drop_distance + Vector3(0, 0.6, 0)
	_carrier = null
	freeze = false
	place_at(Transform3D(Basis.IDENTITY, target))
	dropped.emit()
	return true


## Posé de force dans un socket : le corps reste gelé, immobile et propre.
func seat_at(target: Transform3D) -> void:
	_carrier = null
	_seated = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	global_transform = target


func release_from_seat() -> void:
	_seated = false
	freeze = false


func is_carried() -> bool:
	return _carrier != null


func is_seated() -> bool:
	return _seated


func carrier() -> PlayerController:
	return _carrier


func _physics_process(delta: float) -> void:
	if _carrier != null and is_instance_valid(_carrier):
		# Suivi au tick PHYSIQUE (§20.9 : aucun transform de gameplay
		# écrit depuis `_process`).
		global_transform = Transform3D(_carrier.global_transform.basis,
			_carrier.global_position
			+ _carrier.global_transform.basis * carry_offset)
		return
	if _seated:
		return
	super(delta)
