## Plan de contrôle du village de la rivière — scène de DEV.
extends Node3D


func _ready() -> void:
	var ground: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(160, 160)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.52, 0.30)
	plane.material = mat
	ground.mesh = plane
	ground.position = RiversideVillage.SITE
	add_child(ground)
	add_child(RiversideVillage.new())
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34, 128, 0)
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.93, 0.82)
	add_child(sun)
	var env: WorldEnvironment = WorldEnvironment.new()
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.68, 0.76, 0.82)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.70)
	environment.ambient_light_energy = 0.7
	env.environment = environment
	add_child(env)
	var cam: Camera3D = Camera3D.new()
	cam.fov = 50.0
	cam.current = true
	# `look_at` a besoin d'une transformation GLOBALE : appelé avant l'entrée
	# dans l'arbre, il visait dans le vide et le bourg sortait du cadre.
	add_child(cam)
	cam.global_position = RiversideVillage.SITE + Vector3(26, 15, 30)
	cam.look_at(RiversideVillage.SITE + Vector3(-2, 2, -2))
