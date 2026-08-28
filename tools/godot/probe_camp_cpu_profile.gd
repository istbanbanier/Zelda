## ISS-074 §6.6 — LE COÛT CPU DU CAMP À GARNISON PLEINE.
##
## Usage :
##   tools/lancer_godot.sh --path . --script tools/godot/probe_camp_cpu_profile.gd
##
## CE QUE CETTE MESURE EST, ET CE QU'ELLE N'EST PAS. Elle est prise dans un
## conteneur Linux **headless, sans GPU**, en rendu logiciel. Elle ne dit donc
## RIEN d'un budget de frame : `CLAUDE.md` l'interdit explicitement, et une
## mesure llvmpipe présentée comme un budget serait un mensonge. Ce qu'elle
## mesure honnêtement, c'est le coût CPU AJOUTÉ par la garnison — perception,
## machines à états, navigation — en comparant le MÊME monde avec et sans ses
## quatre gardes. Un delta est comparable à lui-même d'une passe à l'autre ;
## un absolu ne l'est pas.
##
## Le contrôle est ce qui donne son sens au chiffre : sans lui, on publierait
## le coût du monde entier en croyant publier celui de la garnison.
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"
## Le héros est posé au cœur du camp : c'est le pire cas honnête — les quatre
## gardes le perçoivent, poursuivent et demandent des chemins.
const AU_CAMP: Vector3 = Vector3(37.0, 6.5, 70.0)
const ECHAUFFEMENT: int = 60
const ECHANTILLONS: int = 240


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var avec: Dictionary = await _mesurer(true)
	var sans: Dictionary = await _mesurer(false)
	if avec.is_empty() or sans.is_empty():
		push_error("[profil] mesure impossible")
		quit(3)
		return

	print("[profil] ---------------------------------------------------------")
	print("[profil] CONTENEUR HEADLESS SANS GPU, RENDU LOGICIEL.")
	print("[profil] Ceci n'est PAS un budget de frame. C'est un DELTA CPU,")
	print("[profil] comparable à lui-même d'une passe à l'autre.")
	print("[profil] ---------------------------------------------------------")
	for cle: String in ["physique_ms_moyen", "physique_ms_p95",
			"process_ms_moyen", "noeuds"]:
		print("[profil] %-22s  avec garnison %8.3f   sans %8.3f   delta %+8.3f"
			% [cle, float(avec[cle]), float(sans[cle]),
				float(avec[cle]) - float(sans[cle])])
	print("[profil] gardes actifs mesurés : %d" % int(avec["ennemis"]))
	print("[profil] plafond du coordinateur (MAX_ACTIVE_AI) : %d"
		% CombatCoordinator.MAX_ACTIVE_AI)
	var marge: float = float(CombatCoordinator.MAX_ACTIVE_AI) \
		- float(avec["ennemis"])
	print("[profil] marge avant plafond : %.0f agent(s)" % marge)
	print("[profil] FIN NOMINALE")
	quit(0)


func _mesurer(avec_garnison: bool) -> Dictionary:
	var world: Node3D = (load(WORLD) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	await process_frame
	await physics_frame
	await physics_frame
	await process_frame
	await physics_frame

	var ennemis: Array[Node] = world.find_children("*", "EnemyBase", true, false)
	if not avec_garnison:
		# LE CONTRÔLE : on retire les gardes du monde déjà bâti, et RIEN
		# d'autre. Mesurer un monde construit autrement comparerait deux
		# choses différentes.
		for e: Node in ennemis:
			e.get_parent().remove_child(e)
			e.queue_free()
		await process_frame
		await physics_frame

	var joueurs: Array[Node] = world.find_children("*", "PlayerController",
		true, false)
	if not joueurs.is_empty():
		var joueur: Node3D = joueurs[0] as Node3D
		joueur.global_position = AU_CAMP
		if joueur.has_method("reset_physics_interpolation"):
			joueur.reset_physics_interpolation()

	for _i: int in range(ECHAUFFEMENT):
		await physics_frame

	var physiques: Array[float] = []
	var process_ms: float = 0.0
	for _i: int in range(ECHANTILLONS):
		await physics_frame
		physiques.append(Performance.get_monitor(
			Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		process_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0

	var noeuds: float = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var vivants: int = world.find_children("*", "EnemyBase", true, false).size()
	physiques.sort()
	var somme: float = 0.0
	for v: float in physiques:
		somme += v
	var resultat: Dictionary = {
		"physique_ms_moyen": somme / float(physiques.size()),
		"physique_ms_p95": physiques[int(float(physiques.size()) * 0.95)],
		"process_ms_moyen": process_ms / float(ECHANTILLONS),
		"noeuds": noeuds,
		"ennemis": vivants,
	}
	root.remove_child(world)
	world.queue_free()
	await process_frame
	return resultat
