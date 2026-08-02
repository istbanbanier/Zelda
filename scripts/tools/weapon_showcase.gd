## ART-P0 — scène de présentation de l'Épée usée (gate visuel).
##
## Quatre états dans un même cadre, tous depuis les VRAIES ressources :
## modèle neuf sur présentoir, variante usée (< 25 %, via WeaponModel),
## arme AU SOL (WeaponPickup réel), arme EN MAIN (Player réel, l'épée est
## sa dotation par défaut). `SHOWCASE_INVENTORY=1` ouvre l'inventaire réel
## pour la capture d'icône/détail.
class_name WeaponShowcase
extends Node3D

const SWORD_SCENE: String = "res://scenes/weapons/WornSword.tscn"

var _camera: Camera3D = null
var _attack_intent: InputIntent = null


func _ready() -> void:
	_build_stage()
	# Présentoir : modèle neuf, lame vers le ciel.
	var fresh: Node3D = _sword(Vector3(-1.05, 0.06, 0.15), true)
	fresh.name = "FreshSword"
	# Variante USÉE (§11.2) : la même scène, l'état d'usure activé.
	var worn: Node3D = _sword(Vector3(-0.45, 0.06, 0.15), true)
	worn.name = "WornVariant"
	worn.call("set_worn", true)
	# Au sol : le VRAI pickup (même chemin que la vallée).
	var pickup: WeaponPickup = (load("res://scenes/interactables/WeaponPickup.tscn")
		as PackedScene).instantiate() as WeaponPickup
	pickup.definition = load("res://resources/weapons/worn_sword.tres") \
		as WeaponDefinition
	pickup.pickup_id = &"showcase.pickup.worn_sword.01"
	pickup.position = Vector3(0.25, 0.02, 0.75)
	add_child(pickup)
	# En main : le VRAI joueur — l'Épée usée est sa dotation par défaut.
	var player: PlayerController = (load("res://scenes/player/Player.tscn")
		as PackedScene).instantiate() as PlayerController
	player.position = Vector3(1.7, 0.02, -1.1)
	player.rotation_degrees = Vector3(0, -140, 0)
	add_child(player)

	if OS.get_environment("SHOWCASE_INVENTORY") == "1":
		var shell: GameplayShell = (load("res://scenes/ui/GameplayShell.tscn")
			as PackedScene).instantiate() as GameplayShell
		add_child(shell)
		_open_inventory.call_deferred(shell)
	# Modes de capture ART-P0R : cadrages dédiés — main au repos, ATTAQUE
	# réelle (intention injectée, le vrai pipeline §10.1 s'exécute), paire
	# neuf/usé en gros plan.
	if OS.get_environment("SHOWCASE_HAND") == "1" \
			or OS.get_environment("SHOWCASE_ATTACK") == "1":
		_camera.position = player.position + Vector3(-1.15, 1.35, 1.55)
		_camera.look_at(player.position + Vector3(0.1, 1.05, 0.0))
		if OS.get_environment("SHOWCASE_ATTACK") == "1":
			_attack_intent = InputIntent.new()
			player.set_intent_source(_attack_intent)
	elif OS.get_environment("SHOWCASE_PAIR") == "1":
		_camera.position = Vector3(-0.75, 0.95, 1.5)
		_camera.look_at(Vector3(-0.75, 0.55, 0.15))


func _process(_delta: float) -> void:
	# Attaque continue : chaque frame demande un coup — la capture attrape le
	# vrai balayage, quelle que soit la cadence des frames llvmpipe.
	if _attack_intent != null:
		_attack_intent.attack_pressed = true


func _open_inventory(shell: GameplayShell) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	shell.toggle_inventory()


func _sword(at: Vector3, upright: bool) -> Node3D:
	var sword: Node3D = (load(SWORD_SCENE) as PackedScene).instantiate() as Node3D
	if upright:
		sword.rotation_degrees = Vector3(-90, 0, 12)   # lame vers le ciel
		at.y += 0.19   # la prise au-dessus du socle, pointe en l'air
	sword.position = at
	add_child(sword)
	var base: MeshInstance3D = MeshInstance3D.new()
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = 0.09
	cylinder.bottom_radius = 0.12
	cylinder.height = 0.12
	base.mesh = cylinder
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.32, 0.31, 0.36)
	base.material_override = material
	base.position = Vector3(at.x, 0.06, at.z)
	add_child(base)
	return sword


func _build_stage() -> void:
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(10, 1, 10)
	shape.shape = box
	floor_body.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var mesh_box: BoxMesh = BoxMesh.new()
	mesh_box.size = Vector3(10, 1, 10)
	mesh.mesh = mesh_box
	var ground_material: StandardMaterial3D = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.36, 0.42, 0.31)
	ground_material.roughness = 0.95
	mesh.material_override = ground_material
	floor_body.add_child(mesh)
	floor_body.position = Vector3(0, -0.5, 0)
	add_child(floor_body)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.839, 0.541)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-38, -35, 0)
	add_child(sun)

	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.53, 0.62, 0.68)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.6, 0.68)
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	_camera = Camera3D.new()
	_camera.name = "ShowcaseCamera"
	_camera.position = Vector3(0.15, 1.15, 2.7)
	_camera.rotation_degrees = Vector3(-14, 0, 0)
	_camera.fov = 45
	add_child(_camera)
	_camera.make_current()
