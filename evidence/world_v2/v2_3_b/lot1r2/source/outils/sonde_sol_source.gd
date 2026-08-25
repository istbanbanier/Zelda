## SONDE DE SOL — la hauteur du terrain GELÉ autour de la Source aux reflets.
##
## Pourquoi hors du script du lieu : concevoir une composition (quelle masse
## est haute, laquelle est basse, où passe l'eau) demande de savoir où le sol
## monte. Le port Python du heightmap n'existe pas ; le moteur, lui, est
## l'autorité. On échantillonne donc une grille locale et on l'écrit en JSON.
##
## Usage :
##   tools/lancer_godot.sh --path . --script <ce fichier> -- --out=<fichier>
extends SceneTree

const SITE: Vector3 = Vector3(-136.0, 12.0, 40.0)


func _initialize() -> void:
	var sortie: String = "res://sonde_sol_source.json"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			sortie = arg.trim_prefix("--out=")
	_run(sortie)


func _run(sortie: String) -> void:
	var packed: PackedScene = load("res://scenes/world_v2/WorldV2.tscn") \
		as PackedScene
	if packed == null:
		printerr("[sol] BLOQUÉ : WorldV2.tscn introuvable")
		quit(3)
		return
	var monde: Node = packed.instantiate()
	root.add_child(monde)
	if not monde.is_node_ready():
		await monde.ready
	for i: int in range(30):
		await process_frame
	# Le lieu monté : on lui demande SA fonction de sol, pas une copie.
	var lieu: Node3D = _trouver(monde)
	if lieu == null:
		printerr("[sol] ÉCHEC : lieu introuvable dans le monde monté")
		quit(2)
		return
	var lignes: Array = []
	var x: float = -18.0
	while x <= 12.001:
		var ligne: Array = []
		var z: float = -12.0
		while z <= 12.001:
			ligne.append(snappedf(
				(lieu as WorldV2Place).ground_local_y(x, z), 0.001))
			z += 1.0
		lignes.append({"x": snappedf(x, 0.01), "y": ligne})
		x += 1.0
	var doc: Dictionary = {
		"site": [SITE.x, SITE.y, SITE.z],
		"origine_monde": [lieu.global_position.x, lieu.global_position.y,
			lieu.global_position.z],
		"x_de": -18.0, "x_a": 12.0, "z_de": -12.0, "z_a": 12.0, "pas": 1.0,
		"grille": lignes,
	}
	var f: FileAccess = FileAccess.open(sortie, FileAccess.WRITE)
	if f == null:
		printerr("[sol] ÉCHEC : écriture impossible : %s" % sortie)
		quit(2)
		return
	f.store_string(JSON.stringify(doc, "  "))
	f.close()
	print("[sol] OK -> %s" % sortie)
	quit(0)


func _trouver(noeud: Node) -> Node3D:
	if noeud is WorldV2Place:
		var place: WorldV2Place = noeud as WorldV2Place
		if place.place_id() == &"valley.poi.turquoise_spring.01":
			return place
	for enfant: Node in noeud.get_children():
		var trouve: Node3D = _trouver(enfant)
		if trouve != null:
			return trouve
	return null
