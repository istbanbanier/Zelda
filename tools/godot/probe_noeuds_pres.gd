## Liste les nœuds visuels proches d'un point monde — outil d'identification
## (audit lot 1.R : « quel est ce disque teal derrière la tour ? »).
## La méthode fiable pour désigner un nœud reste la repeinte de couleur
## impossible (tools/CLAUDE.md) ; celle-ci suffit quand le voisinage est peu
## peuplé et qu'on veut le NOM et l'ORIGINE (gelé ou lieu).
##
## Usage :
##   tools/lancer_godot.sh --path . --script tools/godot/probe_noeuds_pres.gd \
##     -- --at=-158,27,42.5 --rayon=5
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"


func _initialize() -> void:
	var centre: Vector3 = Vector3.ZERO
	var rayon: float = 5.0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--at="):
			var parts: PackedStringArray = arg.trim_prefix("--at=").split(",")
			if parts.size() == 3:
				centre = Vector3(parts[0].to_float(), parts[1].to_float(),
					parts[2].to_float())
		elif arg.begins_with("--rayon="):
			rayon = arg.trim_prefix("--rayon=").to_float()
	var world: Node3D = (load(WORLD) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i: int in range(20):
		await process_frame
	print("[pres] centre %s rayon %.1f" % [centre, rayon])
	var n: int = 0
	for noeud: Node in root.find_children("*", "VisualInstance3D", true, false):
		var vi: VisualInstance3D = noeud as VisualInstance3D
		var d: float = vi.global_position.distance_to(centre)
		if d <= rayon:
			n += 1
			print("[pres] %5.1f m  %-40s  %s  chemin=%s"
				% [d, vi.name, vi.global_position, vi.get_path()])
	print("[pres] %d noeud(s)" % n)
	quit(0)
