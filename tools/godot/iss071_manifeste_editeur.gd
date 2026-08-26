## ISS-071 — manifeste de résolution, côté EXÉCUTION ÉDITEUR.
##
## POURQUOI CE SCRIPT EXISTE. La parité exigée par la directive §8 se compare
## entre deux environnements. Le côté export est lu par le jeu lui-même (une
## build release n'accepte pas `--script`) ; ce script produit l'AUTRE moitié,
## dans les mêmes conditions : monde réellement monté, index construit par les
## vrais appels de placement, compteurs relevés APRÈS la construction.
##
## Il ne mesure rien lui-même : il monte le monde et laisse
## `WorldV2Root._vider_manifeste_iss071_si_demande()` écrire, exactement comme
## dans la build. Deux chemins de mesure différents rendraient la comparaison
## sans valeur.
##
## Usage :
##   tools/lancer_godot.sh --headless --path . \
##     --script tools/godot/iss071_manifeste_editeur.gd \
##     -- --iss071-dump=<chemin absolu ou res:// ou user://>
##
## Codes : 0 = manifeste écrit · 2 = drapeau absent · 3 = monde non monté
extends SceneTree

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const FRAMES_MONTAGE: int = 90


func _initialize() -> void:
	var cible: String = ""
	var args: PackedStringArray = OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg: String in args:
		if arg.begins_with("--iss071-dump="):
			cible = arg.substr("--iss071-dump=".length())
	if cible.is_empty():
		print("BLOQUÉ : --iss071-dump=<chemin> manquant — rien à écrire.")
		quit(2)
		return

	var monde: Node3D = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(monde)
	for i: int in range(FRAMES_MONTAGE):
		await process_frame

	# Le jalon d'écriture est le fichier lui-même : ne jamais conclure d'un
	# nombre de frames écoulées que le monde a fini de se monter.
	if not FileAccess.file_exists(cible):
		print("BLOQUÉ : aucun manifeste après %d frames — le monde n'a pas "
			% FRAMES_MONTAGE + "atteint « fondation V2 vérifiée ».")
		quit(3)
		return
	print("[iss071] manifeste éditeur présent : %s (%d octets)"
		% [cible, FileAccess.get_file_as_bytes(cible).size()])
	quit(0)
