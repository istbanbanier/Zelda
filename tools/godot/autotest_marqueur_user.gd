## Sonde d'ISOLATION de `user://` — sert UNIQUEMENT à `tools/lancer_godot_autotest.sh`.
##
## Elle ne mesure rien du jeu. Elle répond à une seule question :
## **deux invocations de Godot voient-elles le même `user://` ?**
##
## Pourquoi elle existe (ISS-063) : `user://` dérive de `application/config/name`,
## identique dans tous les arbres de travail. Sans redirection, il vaut
## `/root/.local/share/godot/app_userdata/Eclats d'Orage` pour TOUT le monde.
## Deux runners concurrents ont ainsi FABRIQUÉ des échecs de sauvegarde
## (tools/CLAUDE.md, 2026-08-11) : ils écrivaient la même sauvegarde.
##
## Usage :
##   godot --headless --path . --script tools/godot/autotest_marqueur_user.gd -- \
##       --marqueur=NOM        # écrit user://NOM.marqueur, PUIS liste user://
##   ... sans --marqueur       # liste seulement, n'écrit rien (lecture seule)
##
## Sortie, une clé par ligne, préfixée `MARQ ` pour être grepable sans ambiguïté :
##   MARQ USER_DIR=<chemin absolu resolu par le moteur>
##   MARQ ECRIT=<nom|AUCUN>
##   MARQ VU=<nom>            (une ligne par marqueur trouvé dans user://)
##   MARQ NB_VUS=<entier>
##   MARQ RC=0                jeton de FIN NOMINALE : son absence = échec, quel
##                            que soit le code retour (tools/CLAUDE.md, blender
##                            rend 0 en ayant levé — même famille de piège).
extends SceneTree

const PREFIXE: String = "MARQ "
const SUFFIXE: String = ".marqueur"


func _init() -> void:
	var nom: String = _lire_argument("--marqueur=")
	var dossier: String = OS.get_user_data_dir()
	print(PREFIXE + "USER_DIR=" + dossier)

	if nom != "":
		var chemin: String = "user://" + nom + SUFFIXE
		var f: FileAccess = FileAccess.open(chemin, FileAccess.WRITE)
		if f == null:
			print(PREFIXE + "ERREUR=ecriture_impossible:" + chemin)
			quit(2)
			return
		# Le contenu importe peu ; c'est la PRÉSENCE du fichier qui est la mesure.
		f.store_string(nom + "\n" + str(Time.get_unix_time_from_system()) + "\n")
		f.close()
		# Une écriture non relue n'est pas une écriture (tools/CLAUDE.md :
		# « un garde-fou vaut par son observation, pas par son intention »).
		if not FileAccess.file_exists(chemin):
			print(PREFIXE + "ERREUR=relecture_impossible:" + chemin)
			quit(2)
			return
	print(PREFIXE + "ECRIT=" + (nom if nom != "" else "AUCUN"))

	var vus: PackedStringArray = _lister_marqueurs()
	for v: String in vus:
		print(PREFIXE + "VU=" + v)
	print(PREFIXE + "NB_VUS=" + str(vus.size()))
	# `--headless` DÉSACTIVE le rendu : le nom du serveur d'affichage est le seul
	# témoin honnête de ce qu'on a réellement lancé. « headless » ici veut dire
	# qu'aucune capture ne serait rendue, quelle que soit la crédibilité du reste.
	print(PREFIXE + "AFFICHAGE=" + DisplayServer.get_name())
	print(PREFIXE + "RC=0")
	quit(0)


## Lit un argument passé APRÈS le `--` du moteur.
func _lire_argument(cle: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with(cle):
			return a.substr(cle.length())
	return ""


## Énumère les marqueurs présents dans `user://`, triés pour une sortie stable.
func _lister_marqueurs() -> PackedStringArray:
	var noms: PackedStringArray = PackedStringArray()
	var d: DirAccess = DirAccess.open("user://")
	if d == null:
		return noms
	d.list_dir_begin()
	var e: String = d.get_next()
	while e != "":
		if not d.current_is_dir() and e.ends_with(SUFFIXE):
			noms.append(e.substr(0, e.length() - SUFFIXE.length()))
		e = d.get_next()
	d.list_dir_end()
	noms.sort()
	return noms
