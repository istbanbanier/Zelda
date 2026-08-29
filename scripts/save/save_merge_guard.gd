## ISS-082 — la distinction que `load_slot()` ne fait pas, et qui a coûté une
## sauvegarde de joueur.
##
## `SaveSystem.load_slot()` rend `{}` dans quatre cas que l'appelant ne peut
## pas distinguer :
##
##   1. le slot n'existe pas               → repartir de zéro est LÉGITIME
##   2. le JSON est tronqué                → le fichier n'est pas le nôtre
##   3. l'enveloppe est incomplète         → le fichier n'est pas le nôtre
##   4. `schema_version` est PLUS RÉCENT   → le fichier appartient à un build
##                                            futur, et il a été refusé
##                                            PRÉCISÉMENT pour le protéger
##
## Le cas 1 autorise l'écriture. Les cas 2 à 4 l'interdisent : fusionner dans
## `{}` puis écrire ne corrompt pas le fichier, il le REMPLACE par un état
## neuf et rétrogradé — et la copie de secours suit au deuxième passage
## (§19.4 : ne jamais écraser silencieusement une sauvegarde plus récente).
##
## POURQUOI UN MODULE, ET PAS UN QUATRIÈME COPIER-COLLER. La garde vivait déjà,
## à l'identique, dans trois fichiers — dont deux GELÉS, donc non refactorables
## ici. Trois NOUVEAUX sites en avaient besoin le même jour :
## `dungeon_room.save_room_state()`, `boss_arena._on_boss_died()` et
## `valley_world._autosave()`. C'est la règle de trois de PROMPT4_METHOD §8 :
## on extrait au troisième exemplaire, pas avant.
##
## `null` et `{}` sont ici deux réponses DIFFÉRENTES, et c'est tout l'objet de
## ce fichier : rendre impossible, au niveau du type, la confusion qui a créé
## ISS-082.
class_name SaveMergeGuard
extends RefCounted


## Rend le payload sur lequel fusionner, ou `null` si l'écriture doit être
## REFUSÉE.
##
##   var base: Variant = SaveMergeGuard.base_de_fusion(sys, SAVE_SLOT, "salle")
##   if base == null:
##       return false
##   var data: Dictionary = base as Dictionary
##
## `contexte` n'apparaît que dans l'avertissement : il dit QUI a refusé, ce qui
## est la seule information manquante quand on lit un journal après coup.
static func base_de_fusion(save_system: Node, slot: String,
		contexte: String) -> Variant:
	if save_system == null:
		return null
	if not bool(save_system.call("has_save", slot)):
		# Cas 1 — aucune sauvegarde. Partir d'un dictionnaire vide est le
		# comportement correct, et c'est le SEUL cas où il l'est.
		return {}
	var payload: Dictionary = save_system.call("load_slot", slot) as Dictionary
	if payload.is_empty():
		# Cas 2, 3 ou 4. On ne sait pas lequel — et on n'a pas besoin de le
		# savoir : dans les trois, ce fichier n'est pas le nôtre à réécrire.
		# « Nouvelle partie » l'écrase, lui, avec une confirmation explicite.
		push_warning("[%s] slot présent mais ILLISIBLE — écriture refusée "
			% contexte + "pour ne pas l'écraser (§19.4, ISS-082)")
		return null
	return payload
