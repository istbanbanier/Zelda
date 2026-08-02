## Bloc métallique poussable (MASTER_SPEC §14.1, §14.3, §15.5).
##
## C'est un VRAI corps simulé — pas un `AnimatableBody3D` déguisé : le
## joueur le déplace en poussant dessus, avec des impulsions bornées
## (§14.1 : « saisir/déplacer avec forces ou mode contrôlé stable »,
## « vitesses maximum », « pas de modification directe répétée de
## transform d'un rigid body actif »).
##
## §14.3 impose à tout objet d'énigme essentiel : zone hors limites,
## transform de secours, bouton reset et `persistent_id`. Les trois
## premiers vivent ici ; le bouton appelle `reset_to_rescue()`.
##
## Les rotations sont VERROUILLÉES : un bloc conducteur qui bascule
## emmènerait ses ports avec lui (§15.3) et l'énigme d'initiation
## deviendrait un casse-tête d'orientation — or §15.5 exige une
## « solution impossible à perdre ».
class_name PushableBlock
extends RigidBody3D

## Le bloc vient de réapparaître après une sortie de monde (§14.3).
signal rescued()

## §19.3 : `zone.category.name.index`.
@export var persistent_id: StringName = &""
## Délai de réapparition après sortie de monde — §14.3 : « 1 à 2 s ».
@export var rescue_delay: float = 1.2
## Sous cette altitude, ou hors de `bounds`, le bloc est perdu.
@export var kill_y: float = -6.0
## Demi-étendue autorisée autour de l'origine de la salle, en mètres.
@export var bounds: Vector3 = Vector3(30, 40, 30)

var _rescue_transform: Transform3D = Transform3D.IDENTITY
var _rescue_timer: float = 0.0
var _falling_out: bool = false


func _ready() -> void:
	add_to_group("pushable")
	add_to_group("conductive")
	# §14.1 : damping, sommeil, vitesse plafonnée — un bloc de 400 kg qui
	# glisse sans frottement traverserait la salle sur une seule poussée.
	mass = 40.0
	linear_damp = 3.2
	angular_damp = 8.0
	max_contacts_reported = 0
	can_sleep = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	# Métal poli sur dalle de pierre : le frottement doit rester assez bas
	# pour qu'un humain déplace 40 kg à la main — mesuré, à frottement 1,0
	# le seuil de glissement dépasse ce qu'une poussée plafonnée peut
	# fournir, et le bloc ne bouge tout simplement jamais.
	var surface: PhysicsMaterial = PhysicsMaterial.new()
	surface.friction = 0.4
	surface.bounce = 0.0
	physics_material_override = surface
	_rescue_transform = transform


## Le transform de secours (§14.3) : là où le bloc revient. Posé par la
## salle APRÈS placement, pour que le bloc revienne à son départ réel.
func set_rescue_transform(value: Transform3D) -> void:
	_rescue_transform = value


func rescue_transform() -> Transform3D:
	return _rescue_transform


## Repose le bloc, immobile, à un transform sûr. Passe par
## `PhysicsServer3D` : écrire `transform` sur un corps ÉVEILLÉ laisserait
## le solveur avec un état incohérent (§14.1).
func place_at(target: Transform3D) -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	PhysicsServer3D.body_set_state(get_rid(),
		PhysicsServer3D.BODY_STATE_TRANSFORM, target)
	PhysicsServer3D.body_set_state(get_rid(),
		PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)
	PhysicsServer3D.body_set_state(get_rid(),
		PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, Vector3.ZERO)
	global_transform = target
	_falling_out = false
	_rescue_timer = 0.0


func reset_to_rescue() -> void:
	place_at(_rescue_transform)


## §14.3 : « s'il tombe, réapparaître après 1-2 s ». Surveillé au tick
## physique — un seul corps, aucune boucle sur le monde.
func _physics_process(delta: float) -> void:
	if _falling_out:
		_rescue_timer -= delta
		if _rescue_timer <= 0.0:
			reset_to_rescue()
			rescued.emit()
		return
	if _is_out_of_world():
		_falling_out = true
		_rescue_timer = rescue_delay


func _is_out_of_world() -> bool:
	if global_position.y < kill_y:
		return true
	var local: Vector3 = global_position
	var origin: Node3D = get_parent() as Node3D
	if origin != null:
		local = origin.to_local(global_position)
	return absf(local.x) > bounds.x or absf(local.z) > bounds.z \
		or local.y > bounds.y


## Le bloc est-il en train d'attendre son sauvetage ? (test, et carte murale)
func is_lost() -> bool:
	return _falling_out


## §19.1 : « transforms des objets essentiels SEULEMENT si sûres ». Un
## bloc en train de tomber ne sauvegarde jamais sa chute : c'est son
## transform de secours qui part dans le fichier.
func safe_transform() -> Transform3D:
	if _falling_out or _is_out_of_world():
		return _rescue_transform
	return global_transform
