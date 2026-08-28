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
##
## UN PROCESSUS PAR MESURE, ET C'EST UNE CORRECTION PAYÉE. La première version
## montait les deux mondes dans LE MÊME processus, l'un après l'autre. Résultat
## mesuré : le monde SANS garnison sortait à 12,6 ms de physique contre 3,9 ms
## AVEC — retirer quatre ennemis rendait la physique trois fois plus lente. Le
## chiffre était précis et absurde : le second monde payait la destruction du
## premier. Un delta négatif de -8,8 ms publié tel quel aurait été une preuve
## fausse, de la famille d'ISS-018. Chaque mesure vit donc désormais dans son
## propre processus, et `tools/profil_camp.sh` les compare.
##
## Usage réel :
##   tools/lancer_godot.sh --path . --script <ce fichier> -- --avec
##   tools/lancer_godot.sh --path . --script <ce fichier> -- --sans
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
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var avec_garnison: bool = not arguments.has("--sans")
	var mesure: Dictionary = await _mesurer(avec_garnison)
	if mesure.is_empty():
		push_error("[profil] mesure impossible")
		quit(3)
		return
	print("[profil] CONTENEUR HEADLESS SANS GPU, RENDU LOGICIEL — pas un budget.")
	print("[profil] mode                  : %s"
		% ("AVEC garnison" if avec_garnison else "SANS garnison (contrôle)"))
	print("[profil] gardes vivants        : %d" % int(mesure["ennemis"]))
	print("[profil] physique_ms_moyen     : %.3f" % float(mesure["physique_ms_moyen"]))
	print("[profil] physique_ms_p95       : %.3f" % float(mesure["physique_ms_p95"]))
	print("[profil] process_ms_moyen      : %.3f" % float(mesure["process_ms_moyen"]))
	print("[profil] noeuds                : %.0f" % float(mesure["noeuds"]))
	print("[profil] plafond MAX_ACTIVE_AI : %d" % CombatCoordinator.MAX_ACTIVE_AI)
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
