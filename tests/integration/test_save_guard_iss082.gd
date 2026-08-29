## ISS-082 — un slot PRÉSENT mais illisible n'est à personne, et surtout pas
## au premier écrivain qui passe.
##
## POURQUOI CE FICHIER EXISTE. `SaveSystem.load_slot()` rend `{}` dans quatre
## cas que l'appelant ne peut pas distinguer : slot absent, JSON tronqué,
## enveloppe incomplète, et `schema_version` PLUS RÉCENT — ce dernier refusé
## *précisément pour protéger* la sauvegarde d'un build futur (§19.4). Un
## écrivain qui repart de `{}` puis écrit ne corrompt pas le fichier : il le
## REMPLACE par un état neuf et rétrogradé, et la copie de secours suit au
## deuxième passage.
##
## La garde existe depuis C10 dans `world_v2_root.gd::autosave()`, depuis
## ISS-080 dans `antechamber.gd::_write_checkpoint()`, et dans
## `world_v2_encounters_builder.gd::_persister_mort()`. Trois écrivains ne
## l'avaient pas :
##
##   - `dungeon_room.gd::save_room_state()`     — chaque salle résolue
##   - `boss_arena.gd::_on_boss_died()`         — la victoire
##   - `valley_world.gd::_autosave()`           — coffres, flèches, buffs…
##
## Le troisième n'était même pas nommé dans ISS-082 ; la cartographie de cette
## passe l'a trouvé. Deux salles de donjon suffisaient à effacer le fichier ET
## sa copie de secours.
##
## CE QUE CE FICHIER MESURE, ET COMMENT IL PEUT ROUGIR. Chaque cas empoisonne
## le slot, appelle l'écrivain POUR DE VRAI, puis compare les OCTETS du
## fichier et de son `.bak` avant et après. Un refus qui n'écrit rien laisse
## les deux identiques. Le dernier cas est la garde de non-vacuité : sur un
## slot normal, les trois écrivains doivent écrire — sans quoi on aurait
## « corrigé » le défaut en cassant la sauvegarde.
extends GateTestCase

const SLOT: String = "slot0"
const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"

## Un JSON coupé en plein milieu : `load_slot` ne peut pas l'analyser.
const TRONQUE: String = '{"schema_version": 4, "slot": "slot0", "data": {"che'

## Une enveloppe PARFAITEMENT formée, mais d'un schéma que ce build ne sait
## pas lire. C'est le cas qui fait le plus mal : le fichier est intact, sain,
## et appartient à une version future du jeu.
const FUTUR: String = '{"schema_version": 99, "slot": "slot0", ' \
	+ '"saved_at_utc": "2027-01-01T00:00:00", "data": {"schema": 99, ' \
	+ '"checkpoint": "world_v2.valley", "enemies_slain": ["garrison.x.01"]}}'


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for _i: int in range(ticks):
		await _tree().physics_frame


func _save_system() -> Node:
	return _tree().root.get_node_or_null("/root/SaveSystem")


func _chemin() -> String:
	var systeme: Node = _save_system()
	if systeme == null:
		return ""
	return ProjectSettings.globalize_path(String(systeme.call("slot_path", SLOT)))


## Écrit le contenu BRUT du slot, sans passer par SaveSystem — c'est la seule
## façon de fabriquer un fichier que `load_slot` refusera.
func _empoisonner(contenu: String) -> void:
	var chemin: String = _chemin()
	DirAccess.make_dir_recursive_absolute(chemin.get_base_dir())
	var f: FileAccess = FileAccess.open(chemin, FileAccess.WRITE)
	f.store_string(contenu)
	f.close()


## Pose aussi un `.bak` reconnaissable : sans lui, on ne prouverait rien sur
## la copie de secours, et c'est elle que le SECOND passage détruit.
func _empoisonner_avec_bak(contenu: String) -> void:
	_empoisonner(contenu)
	var f: FileAccess = FileAccess.open(_chemin() + ".bak", FileAccess.WRITE)
	f.store_string(contenu)
	f.close()


func _octets(chemin: String) -> PackedByteArray:
	if not FileAccess.file_exists(chemin):
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(chemin)


func _nettoyer() -> void:
	var chemin: String = _chemin()
	for c: String in [chemin, chemin + ".bak", chemin + ".tmp"]:
		if FileAccess.file_exists(c):
			DirAccess.remove_absolute(c)


## Une salle de donjon nue : `DungeonRoom extends Node3D`, `room_state()`
## supporte l'absence de graphe et de blocs. Rien d'autre n'est nécessaire
## pour atteindre son écriture.
func _salle() -> Node:
	var salle: Node = ClassDB.instantiate("Node3D")
	salle.set_script(load("res://scripts/dungeon/dungeon_room.gd"))
	salle.set("room_id", &"test.iss082.salle")
	salle.name = "SalleISS082"
	_tree().root.add_child(salle)
	return salle


func _arene() -> Node:
	var arene: Node = ClassDB.instantiate("Node3D")
	arene.set_script(load("res://scripts/boss/boss_arena.gd"))
	arene.set("room_id", &"test.iss082.arene")
	arene.name = "AreneISS082"
	_tree().root.add_child(arene)
	return arene


## `is_instance_valid` AVANT tout : une `BossArena` montée nue peut se libérer
## elle-même pendant l'apaisement, et démonter un objet déjà libéré lève une
## SCRIPT ERROR que le garde-fou ISS-027 du runner compte — un test vert
## deviendrait rouge pour une faute de ménage, pas pour la chose mesurée.
## Le paramètre est `Variant`, pas `Node`, ET C'EST LE POINT : GDScript vérifie
## le type de l'argument AVANT d'entrer dans la fonction, donc une garde
## `is_instance_valid` à l'intérieur d'une signature typée `Node` n'est jamais
## atteinte — l'erreur est levée au site d'appel. Mesuré ici même.
func _demonter(brut: Variant) -> void:
	if brut == null or not is_instance_valid(brut):
		return
	var noeud: Node = brut as Node
	if noeud == null:
		return
	if noeud.get_parent() != null:
		noeud.get_parent().remove_child(noeud)
	noeud.queue_free()
	await _settle(2)


# --------------------------------------------------------------------------
# 1-2 — la salle de donjon
# --------------------------------------------------------------------------
func test_une_salle_de_donjon_refuse_un_slot_tronque() -> void:
	remember_saves()
	_nettoyer()
	_empoisonner_avec_bak(TRONQUE)
	var avant: PackedByteArray = _octets(_chemin())
	var avant_bak: PackedByteArray = _octets(_chemin() + ".bak")

	var salle: Node = _salle()
	var ecrit: bool = bool(salle.call("save_room_state"))
	await _demonter(salle)

	check(not ecrit,
		"save_room_state() doit RENDRE FALSE sur un slot illisible — un vrai "
		+ "refus se voit dans le code retour, pas seulement dans le fichier")
	check_equal(_octets(_chemin()), avant,
		"le fichier tronqué est resté OCTET POUR OCTET le même")
	check_equal(_octets(_chemin() + ".bak"), avant_bak,
		"la copie de secours est restée OCTET POUR OCTET la même")
	_nettoyer()
	restore_saves()


func test_une_salle_de_donjon_refuse_un_schema_futur() -> void:
	remember_saves()
	_nettoyer()
	_empoisonner_avec_bak(FUTUR)
	var avant: PackedByteArray = _octets(_chemin())
	var avant_bak: PackedByteArray = _octets(_chemin() + ".bak")

	var salle: Node = _salle()
	var ecrit: bool = bool(salle.call("save_room_state"))
	await _demonter(salle)

	check(not ecrit,
		"save_room_state() doit refuser un schéma 99 : ce fichier appartient "
		+ "à un build plus récent, pas à celui-ci (§19.4)")
	check_equal(_octets(_chemin()), avant,
		"la sauvegarde du futur est intacte après la salle de donjon")
	check_equal(_octets(_chemin() + ".bak"), avant_bak,
		"sa copie de secours aussi")
	_nettoyer()
	restore_saves()


# --------------------------------------------------------------------------
# 3 — deux salles d'affilée : c'est le SECOND passage qui détruisait le .bak
# --------------------------------------------------------------------------
func test_deux_salles_d_affilee_ne_detruisent_pas_la_copie_de_secours() -> void:
	remember_saves()
	_nettoyer()
	_empoisonner_avec_bak(FUTUR)
	var avant_bak: PackedByteArray = _octets(_chemin() + ".bak")

	for i: int in range(2):
		var salle: Node = _salle()
		salle.set("room_id", StringName("test.iss082.salle%d" % i))
		salle.call("save_room_state")
		await _demonter(salle)

	check_equal(_octets(_chemin() + ".bak"), avant_bak,
		"APRÈS DEUX salles résolues, la copie de secours est intacte — sans "
		+ "la garde, la première la remplaçait et la seconde l'effaçait")
	_nettoyer()
	restore_saves()


# --------------------------------------------------------------------------
# 4 — la victoire du boss
# --------------------------------------------------------------------------
func test_la_victoire_du_boss_refuse_un_schema_futur() -> void:
	remember_saves()
	_nettoyer()
	_empoisonner_avec_bak(FUTUR)
	var avant: PackedByteArray = _octets(_chemin())

	var arene: Node = _arene()
	arene.call("_on_boss_died")
	await _settle(2)
	await _demonter(arene)

	check_equal(_octets(_chemin()), avant,
		"la sauvegarde du futur est intacte après la mort du boss — écrire "
		+ "`boss_defeated` dans un état neuf effacerait la partie du joueur")
	_nettoyer()
	restore_saves()


# --------------------------------------------------------------------------
# 5 — l'autosave de la vallée V1, le troisième écrivain, absent d'ISS-082
# --------------------------------------------------------------------------
func test_l_autosave_de_la_vallee_refuse_un_schema_futur() -> void:
	remember_saves()
	remember_root()
	_nettoyer()
	_empoisonner_avec_bak(FUTUR)
	var avant: PackedByteArray = _octets(_chemin())

	var vallee: Node = (load(VALLEY) as PackedScene).instantiate()
	_tree().root.add_child(vallee)
	await _settle(10)
	vallee.call("_autosave")
	await _settle(2)
	await _demonter(vallee)

	check_equal(_octets(_chemin()), avant,
		"la sauvegarde du futur survit à un autosave de la vallée — c'est le "
		+ "chemin le plus fréquent du jeu : coffres, flèches, buffs")
	_nettoyer()
	restore_saves()
	# `await`, ET C'EST TOUT LE SUJET. `restore_root()` est une coroutine :
	# appelée sans attendre, elle SURVIT à la fin du cas et recharge la racine
	# pendant que le cas SUIVANT monte son monde. Le journal vert de cette
	# passe le portait déjà, après le décompte donc non compté :
	# « Resumed function '_sweep()' after await, but class instance is gone ».
	# C'est le piège que `test_enemy_territory_iss083.gd` documente comme
	# mesuré, et la famille d'intermittents ISS-038. Le 6/0 filtré était vrai ;
	# sa tenue en suite complète ne l'était pas.
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())


# --------------------------------------------------------------------------
# 6 — LA GARDE DE NON-VACUITÉ. Sans elle, on « corrigerait » ISS-082 en
#     empêchant toute sauvegarde, et les cinq cas ci-dessus resteraient verts.
# --------------------------------------------------------------------------
func test_un_slot_normal_reste_inscriptible_par_les_trois_ecrivains() -> void:
	remember_saves()
	_nettoyer()
	var systeme: Node = _save_system()
	check_not_null(systeme, "SaveSystem est monté")
	if systeme == null:
		restore_saves()
		return
	check(bool(systeme.call("save_slot", SLOT,
			{"schema": 4, "checkpoint": "world_v2.valley"})),
		"le slot de départ est bien écrit")

	var salle: Node = _salle()
	var ecrit: bool = bool(salle.call("save_room_state"))
	await _demonter(salle)
	check(ecrit, "sur un slot LISIBLE, la salle de donjon écrit toujours")

	var apres_salle: Dictionary = systeme.call("load_slot", SLOT) as Dictionary
	check(apres_salle.has("dungeon"),
		"et son état de salle est réellement dans le fichier")
	check_equal(String(apres_salle.get("checkpoint", "")), "world_v2.valley",
		"sans avoir écrasé le champ d'une autre scène — c'est une FUSION")

	var arene: Node = _arene()
	arene.call("_on_boss_died")
	await _settle(2)
	await _demonter(arene)
	var apres_boss: Dictionary = systeme.call("load_slot", SLOT) as Dictionary
	check(bool(apres_boss.get("boss_defeated", false)),
		"sur un slot LISIBLE, la victoire du boss est bien écrite")
	check(apres_boss.has("dungeon"),
		"et elle n'a pas effacé l'état de salle posé juste avant")

	_nettoyer()
	restore_saves()


# --------------------------------------------------------------------------
# LE CHAMP PARTAGÉ : la fusion protège les CLÉS, pas le CONTENU d'une clé
# --------------------------------------------------------------------------
## TROUVÉ PAR LA CONTRE-REVUE, ET C'EST UN TROU RÉEL DANS C4.
##
## `valley_world.gd::_autosave()` fusionne bien son payload — c'est ce que les
## cinq cas ci-dessus prouvent. Mais `opened_chests` y était RECONSTRUIT depuis
## les coffres de la scène V1 puis écrit tel quel : la fusion préservait les
## autres clés, et écrasait le contenu de celle-là.
##
## Sans conséquence tant que V1 était seule à écrire ce champ. Depuis que World
## V2 a repris le NOM pour le coffre du camp braise — délibérément, pour parler
## le vocabulaire du dépôt plutôt que d'en inventer un — un autosave de la
## vallée sur le même slot chasse `camp.chest.ember_terrace.01` de la liste. Au
## remontage, `_poser_la_recompense()` ne le trouve plus parmi les pillés et
## repose le coffre PLEIN : une épée usée et dix flèches, une deuxième fois.
##
## C4 « la récompense n'est jamais duplicable » tomberait sans qu'un seul test
## du camp ne bouge — ils regardent tous le camp, aucun ne regarde qui d'autre
## écrit dans le même champ.
##
## Latent aujourd'hui : menu, victoire et vestibule routent vers World V2. Mais
## `gameplay_shell.gd` garde ValleyWorld en défaut exporté ; le chemin existe.
func test_l_autosave_de_la_vallee_preserve_les_coffres_d_une_autre_scene() -> void:
	remember_saves()
	remember_root()
	_nettoyer()

	# Un slot LISIBLE portant un coffre qui n'appartient pas à la vallée V1.
	const ETRANGER: String = "camp.chest.ember_terrace.01"
	_tree().root.get_node_or_null("/root/SaveSystem").call("save_slot", SLOT, {
		"schema": 4,
		"checkpoint": "valley.camp.start",
		"opened_chests": [ETRANGER],
	})

	var vallee: Node = (load(VALLEY) as PackedScene).instantiate()
	_tree().root.add_child(vallee)
	await _settle(10)
	vallee.call("_autosave")
	await _settle(2)
	await _demonter(vallee)

	var apres: Dictionary = _tree().root.get_node_or_null("/root/SaveSystem") \
		.call("load_slot", SLOT) as Dictionary
	var coffres: Array = apres.get("opened_chests", []) as Array

	# NON VACUITÉ : si le slot était devenu illisible, `coffres` serait vide et
	# l'assertion rougirait pour une raison qui n'a rien à voir avec le sujet.
	check(not apres.is_empty(),
		"préalable : le slot reste lisible après l'autosave — sinon on "
		+ "mesurerait un refus d'écriture, pas la préservation d'un champ")
	check(coffres.has(ETRANGER),
		"le coffre du camp survit à un autosave de la vallée V1 : sans quoi "
		+ "la récompense du camp serait REPOSÉE PLEINE au remontage suivant "
		+ "(C4). Contenu du champ après autosave : %s" % [coffres])

	_nettoyer()
	restore_saves()
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())


# --------------------------------------------------------------------------
# LA LOI PLUTÔT QUE SES SIX APPLICATIONS
# --------------------------------------------------------------------------
## POURQUOI CE CAS EXISTE. Les cinq précédents éprouvent les trois écrivains
## qu'ISS-082 a corrigés. Ils ne disent rien du DIXIÈME, celui qu'on écrira le
## mois prochain. Or l'inventaire de ce jour donne NEUF appelants de
## `save_slot` dans `scripts/`, répartis en trois familles :
##
##   - quatre passent par `SaveMergeGuard.base_de_fusion()` — dungeon_room,
##     boss_arena, valley_world, world_v2_camp_liberation ;
##   - trois portent une COPIE À LA MAIN de la même garde, dont deux dans des
##     fichiers GELÉS qu'on ne peut pas migrer — world_v2_root,
##     world_v2_encounters_builder, antechamber ;
##   - deux ÉCRASENT VOLONTAIREMENT, et c'est correct : commencer une partie
##     neuve n'est pas une fusion, c'est une remise à zéro, et les deux
##     demandent confirmation au joueur (§17.3).
##
## Une loi appliquée en six exemplaires manuscrits se dégrade en silence, et
## le jour où elle se dégrade, la panne est une sauvegarde détruite. Ce cas
## l'exécute.
##
## CE QU'IL NE VOIT PAS, dit ici plutôt que découvert plus tard : le contrôle
## porte sur la FONCTION qui contient l'appel, et cherche une trace de garde
## dans son corps. Une fonction qui appellerait `save_slot` deux fois, une
## fois gardée et une fois non, passerait. L'angle mort est réel ; il est plus
## étroit qu'un contrôle par fichier, et beaucoup plus étroit que rien.
const ECRIVAINS_EXEMPTES: Dictionary = {
	"scripts/ui/main_menu.gd":
		"« Nouvelle partie » ÉCRIT une partie neuve plutôt que de supprimer "
		+ "le fichier — c'est une remise à zéro voulue, pas une fusion. La "
		+ "confirmation d'écrasement de §17.3 est le garde-fou, et elle est "
		+ "à sa place : devant le joueur.",
	"scripts/ui/victory_screen.gd":
		"« Recommencer » après la victoire, même geste et même raison ; "
		+ "l'écran demande explicitement confirmation avant d'effacer.",
}

## Les deux formes reconnues de la garde. La première est le mécanisme
## partagé ; la seconde est la phrase exacte des copies manuscrites, dont
## deux vivent dans des fichiers gelés et ne peuvent pas être migrées.
const MARQUES_DE_GARDE: Array[String] = [
	"SaveMergeGuard.base_de_fusion",
	"slot présent mais illisible",
]


func _fichiers_gd(racine: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(racine)
	if dir == null:
		return
	dir.list_dir_begin()
	var entree: String = dir.get_next()
	while entree != "":
		var complet: String = "%s/%s" % [racine, entree]
		if dir.current_is_dir():
			if not entree.begins_with("."):
				_fichiers_gd(complet, out)
		elif entree.ends_with(".gd"):
			out.append(complet)
		entree = dir.get_next()
	dir.list_dir_end()


## Corps de la fonction de premier niveau qui contient la ligne `index`.
## Les fonctions commencent en colonne 0 par `func ` : on remonte jusqu'à la
## précédente, on descend jusqu'à la suivante.
func _fonction_contenant(lignes: PackedStringArray, index: int) -> String:
	var debut: int = 0
	for i: int in range(index, -1, -1):
		if lignes[i].begins_with("func "):
			debut = i
			break
	var fin: int = lignes.size()
	for i: int in range(index + 1, lignes.size()):
		if lignes[i].begins_with("func "):
			fin = i
			break
	# LES COMMENTAIRES SONT RETIRÉS, et c'est le point qui rend ce contrôle
	# capable de rougir. Mesuré : `_autosave()` de `valley_world.gd` porte la
	# phrase « slot présent mais illisible » DANS UN COMMENTAIRE, ligne 964,
	# en plus de son vrai appel ligne 966. En gardant les commentaires, effacer
	# l'appel aurait laissé le test vert — la marque aurait survécu à la garde
	# qu'elle décrit. C'est exactement la famille de test qui ne peut pas
	# échouer que `test-coverage-auditor` traque.
	var corps: String = ""
	for i: int in range(debut, fin):
		var ligne: String = lignes[i]
		var diese: int = ligne.find("#")
		if diese >= 0:
			ligne = ligne.substr(0, diese)
		corps += ligne + "\n"
	return corps


func test_tout_ecrivain_de_sauvegarde_fusionne_ou_est_exempte_nommement() -> void:
	var fichiers: Array[String] = []
	_fichiers_gd("res://scripts", fichiers)

	# NON VACUITÉ, et elle compte : si le balayage ne trouvait aucun fichier —
	# répertoire renommé, DirAccess muet en export — la boucle ne tournerait
	# pas et ce cas serait vert en n'ayant rien lu. C'est exactement la forme
	# de test qui ne peut pas rougir.
	check(fichiers.size() > 100,
		"préalable : le balayage de res://scripts trouve les scripts du "
		+ "projet — %d fichier(s) .gd" % fichiers.size())

	var ecrivains: int = 0
	var gardes: int = 0
	var exemptes: int = 0
	for chemin: String in fichiers:
		var source: String = FileAccess.get_file_as_string(chemin)
		if not source.contains("\"save_slot\""):
			continue
		var relatif: String = chemin.replace("res://", "")
		var lignes: PackedStringArray = source.split("\n")
		for i: int in range(lignes.size()):
			# La DÉFINITION de `save_slot` dans SaveSystem n'est pas un appel.
			if not lignes[i].contains("call(\"save_slot\""):
				continue
			ecrivains += 1
			if ECRIVAINS_EXEMPTES.has(relatif):
				exemptes += 1
				continue
			var corps: String = _fonction_contenant(lignes, i)
			var garde: bool = false
			for marque: String in MARQUES_DE_GARDE:
				if corps.contains(marque):
					garde = true
					break
			if garde:
				gardes += 1
			check(garde,
				"%s ligne %d écrit la sauvegarde sans lire d'abord ce "
				% [relatif, i + 1] + "qu'elle contient. Un slot PRÉSENT mais "
				+ "illisible — corrompu, ou d'un schéma plus récent — rend "
				+ "`{}` comme un slot absent : repartir de là détruit le "
				+ "fichier ET sa copie de secours (ISS-082). Passer par "
				+ "`SaveMergeGuard.base_de_fusion()`, ou inscrire ce fichier "
				+ "dans ECRIVAINS_EXEMPTES avec sa raison.")

	# Le verdict publie la TAILLE de ce qu'il a examiné : « aucune violation »
	# sans dénominateur ne prouve rien.
	check(ecrivains >= 8,
		"préalable : l'inventaire trouve les écrivains connus — %d appel(s) "
		% ecrivains + "à save_slot, dont %d gardé(s) et %d exempté(s) "
		% [gardes, exemptes] + "nommément")
