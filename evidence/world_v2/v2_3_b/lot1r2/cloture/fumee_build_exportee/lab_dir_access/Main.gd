extends Node

## LABORATOIRE — que rend DirAccess.get_files() dans une build EXPORTÉE ?
## Question posée le 2026-08-26 pour ISS-071 : le balayage de répertoire
## échoue en export, mais la CAUSE n'était pas prouvée. Ce lab la tranche.
func _ready() -> void:
	print("LAB: debut")
	var d: DirAccess = DirAccess.open("res://assets")
	if d == null:
		print("LAB: DirAccess.open() rend NULL — la cause serait l'ouverture, pas le nom")
	else:
		var fichiers: PackedStringArray = d.get_files()
		print("LAB: get_files() rend %d entree(s)" % fichiers.size())
		for f: String in fichiers:
			print("LAB:   [%s]" % f)
	print("LAB: ResourceLoader.exists(gltf) = %s"
		% ResourceLoader.exists("res://assets/Floor_WoodLight.gltf", "PackedScene"))
	print("LAB: load(gltf) = %s" % (load("res://assets/Floor_WoodLight.gltf") != null))
	print("LAB: fin")
	get_tree().quit()
