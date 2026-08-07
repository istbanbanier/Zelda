## MONTURE — se déplacer plus vite qu'à pied, sans casser les règles.
##
## GRAYBOX ASSUMÉ : la silhouette est faite de primitives. Aucun quadrupède
## n'existe dans les kits (`assets/characters/creatures/` ne contient que le
## chasseur centauroïde et le colosse, qui sont des ennemis). Cette monture
## n'est donc PAS finale et ne doit pas être présentée comme telle — elle vaut
## pour la jouabilité et l'exploration, pas pour l'image.
##
## Contrats tenus :
##
##   - D-013 : aucune lecture de périphérique. La monture consomme la même
##     `InputIntent` que le héros, via son lecteur.
##   - §20.9 : tout le mouvement vit dans `_physics_process`. Le cavalier est
##     reposé sur la selle APRÈS le déplacement de la monture, dans le même
##     tick — jamais depuis `_process`, jamais deux écritures concurrentes.
##   - Anti-softlock : on ne descend que sur une place LIBRE, sondée à la
##     capsule du héros. Si aucune n'est libre, la descente est refusée et
##     annoncée — jamais de cavalier déposé dans la roche.
##   - Le héros gelé rend toujours la main : mourir dégèle (`set_frozen`), et
##     la monture lâche son cavalier si celui-ci disparaît.
##
## Interaction : convention existante du projet — groupe `interactable` et
## méthode `interact(player)`. Monter et descendre se font donc avec la même
## touche que tout le reste, sans action nouvelle à apprendre.
class_name Mount
extends CharacterBody3D

signal mounted(rider: PlayerController)
signal dismounted(rider: PlayerController, refused: bool)

## Allures. Le pas et le trot restent lisibles ; le galop dépasse nettement le
## sprint du héros (9 m/s) — c'est la raison d'être de la monture.
const WALK_SPEED: float = 5.0
const GALLOP_SPEED: float = 14.0
const ACCEL: float = 14.0
const BRAKE: float = 18.0
## Rotation : une monture ne pivote pas sur place comme un personnage.
const TURN_RATE: float = 2.6
const GRAVITY: float = 24.0
## Hauteur de la selle au-dessus de la base.
const SADDLE_HEIGHT: float = 1.72
## Côtés testés pour descendre, dans l'ordre : gauche, droite, arrière.
const DISMOUNT_OFFSETS: Array[Vector3] = [
	Vector3(-1.6, 0.2, 0.0), Vector3(1.6, 0.2, 0.0), Vector3(0.0, 0.2, 2.0),
]

const HIDE_TONE: Color = Color(0.42, 0.31, 0.24)
const MANE_TONE: Color = Color(0.24, 0.19, 0.16)

var _rider: PlayerController = null
var _saddle: Marker3D = null


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 1
	_build_body()
	set_physics_process(true)


func rider() -> PlayerController:
	return _rider


func is_ridden() -> bool:
	return _rider != null and is_instance_valid(_rider)


func saddle_position() -> Vector3:
	return _saddle.global_position if _saddle != null else global_position


## Convention `interactable` : monter si libre, descendre si c'est le cavalier.
func interact(who: Node) -> bool:
	var player: PlayerController = who as PlayerController
	if player == null:
		return false
	if is_ridden():
		if player != _rider:
			return false
		return dismount()
	return mount(player)


func mount(player: PlayerController) -> bool:
	if is_ridden() or player == null or not is_instance_valid(player):
		return false
	_rider = player
	# Le héros cède la conduite : il ne consomme plus d'entrée et ne bouge plus
	# de lui-même. Sa caméra reste son enfant, donc le joueur garde le regard.
	_rider.set_frozen(true)
	_seat_rider()
	mounted.emit(_rider)
	return true


## Descend sur la première place libre. Refuse si aucune ne l'est — et le dit,
## plutôt que de déposer le cavalier dans un mur.
func dismount() -> bool:
	if not is_ridden():
		return false
	var spot: Vector3 = _free_spot()
	var refused: bool = spot.is_equal_approx(Vector3.INF)
	var leaving: PlayerController = _rider
	if refused:
		dismounted.emit(leaving, true)
		return false
	_rider = null
	leaving.global_position = spot
	leaving.velocity = Vector3.ZERO
	leaving.set_frozen(false)
	# Repositionnement instantané : l'interpolation doit repartir de zéro,
	# sinon le héros glisse depuis la selle pendant une image (§20.9).
	leaving.reset_physics_interpolation()
	dismounted.emit(leaving, false)
	return true


## Cherche une place libre à côté de la monture, à la capsule RÉELLE du héros.
## Renvoie `Vector3.INF` si aucune ne convient.
func _free_spot() -> Vector3:
	var shape_node: CollisionShape3D = \
		_rider.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null or shape_node.shape == null:
		return Vector3.INF
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for offset: Vector3 in DISMOUNT_OFFSETS:
		var candidate: Vector3 = global_position + global_transform.basis * offset
		# Un sol sous les pieds, d'abord.
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			candidate + Vector3.UP * 2.0, candidate + Vector3.DOWN * 4.0, 1,
			[get_rid(), _rider.get_rid()])
		var hit: Dictionary = space.intersect_ray(ray)
		if hit.is_empty():
			continue
		var landing: Vector3 = (hit["position"] as Vector3) + Vector3.UP * 0.1
		# …puis la place pour la capsule.
		var params: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		params.shape = shape_node.shape
		params.transform = Transform3D(Basis.IDENTITY, landing + Vector3.UP)
		params.collision_mask = 1
		params.exclude = [get_rid(), _rider.get_rid()]
		if space.intersect_shape(params, 1).is_empty():
			return landing
	return Vector3.INF


func _physics_process(delta: float) -> void:
	# Le cavalier a pu être libéré (mort, changement de scène) : la monture ne
	# doit pas continuer à conduire un fantôme.
	if _rider != null and not is_instance_valid(_rider):
		_rider = null
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	if is_ridden():
		_drive(delta)
	else:
		# Sans cavalier, elle s'arrête — elle ne divague pas dans le monde.
		var flat: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
		flat = flat.move_toward(Vector3.ZERO, BRAKE * delta)
		velocity.x = flat.x
		velocity.z = flat.z
	move_and_slide()
	if is_ridden():
		# APRÈS le déplacement, dans le MÊME tick : le cavalier ne peut donc
		# jamais accuser une image de retard sur sa selle.
		_seat_rider()


## Conduite : la monture avance dans SON axe et tourne — elle ne fait pas de
## pas latéral comme un personnage. C'est ce qui la distingue de la marche.
func _drive(delta: float) -> void:
	# L'intention EFFECTIVE du héros, pas le lecteur brut : un test qui injecte
	# son intention désactive la capture du lecteur, et lire celui-ci
	# directement rendrait la monture sourde (défaut mesuré : 0,5 m en 40 ticks).
	var intent: InputIntent = _rider.current_intent()
	# Descendre : même touche que monter, la convention du projet. Le héros
	# gelé ne vide plus les fronts — c'est au geleur de les consommer, sinon
	# ils s'accumulent et partent tous d'un coup à la descente.
	var wants_off: bool = intent.interact_pressed
	intent.consume_edges()
	if wants_off:
		dismount()
		return
	rotation.y -= intent.move.x * TURN_RATE * delta
	var forward: Vector3 = -global_transform.basis.z
	var throttle: float = intent.move.y
	var speed: float = GALLOP_SPEED if intent.sprint_held else WALK_SPEED
	var target: Vector3 = forward * throttle * speed
	var flat: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = ACCEL if absf(throttle) > 0.05 else BRAKE
	flat = flat.move_toward(target, rate * delta)
	velocity.x = flat.x
	velocity.z = flat.z


## Pose le cavalier sur la selle et l'oriente comme la monture. Écriture unique
## et explicite : personne d'autre ne touche à ce transform pendant le trajet.
func _seat_rider() -> void:
	if not is_ridden():
		return
	_rider.global_position = saddle_position()
	_rider.rotation.y = rotation.y


## --- Silhouette graybox -----------------------------------------------------

## Volumes simples : corps, encolure, tête, quatre membres, une selle. Assez
## pour lire « monture » à 30 m ; ce n'est pas un modèle final.
func _build_body() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var hull: BoxShape3D = BoxShape3D.new()
	hull.size = Vector3(0.9, 1.5, 2.4)
	shape.shape = hull
	shape.position = Vector3(0.0, 0.75, 0.0)
	add_child(shape)
	_box("Corps", Vector3(0.0, 1.15, 0.0), Vector3(0.86, 0.86, 2.1), HIDE_TONE)
	_box("Encolure", Vector3(0.0, 1.55, -1.05), Vector3(0.5, 0.5, 0.9), HIDE_TONE)
	_box("Tete", Vector3(0.0, 1.72, -1.62), Vector3(0.42, 0.46, 0.72), HIDE_TONE)
	_box("Criniere", Vector3(0.0, 1.86, -1.05), Vector3(0.2, 0.3, 1.0), MANE_TONE)
	_box("Queue", Vector3(0.0, 1.42, 1.12), Vector3(0.18, 0.5, 0.28), MANE_TONE)
	for side: float in [-1.0, 1.0]:
		for front: float in [-1.0, 1.0]:
			_box("Membre", Vector3(side * 0.32, 0.36, front * 0.78),
				Vector3(0.22, 0.72, 0.24), MANE_TONE)
	_box("Selle", Vector3(0.0, 1.62, 0.1), Vector3(0.7, 0.16, 0.8),
		Color(0.36, 0.24, 0.18))
	_saddle = Marker3D.new()
	_saddle.name = "Selle"
	_saddle.position = Vector3(0.0, SADDLE_HEIGHT, 0.1)
	add_child(_saddle)


func _box(box_name: String, at: Vector3, size: Vector3, tone: Color) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "%s%02d" % [box_name, get_child_count()]
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = tone
	material.roughness = 0.9
	mesh.material_override = material
	mesh.position = at
	add_child(mesh)
