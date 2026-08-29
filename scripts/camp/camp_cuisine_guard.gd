## ISS-084 — LE FOYER D'UN CAMP APPARTIENT À SA GARNISON TANT QU'ELLE TIENT.
##
## Ce nœud ne fait qu'une chose : lever ou baisser le drapeau `_revendique`
## du `Campfire` que la donnée du camp désigne. Il n'ouvre rien, ne dessine
## rien, ne sauvegarde rien.
##
## POURQUOI UN NŒUD DE PLUS PLUTÔT QUE DU CODE DANS L'EXISTANT.
## Le script GELÉ qui libère le camp ferait l'affaire — il connaît déjà le camp,
## la garnison et les morts. Il est GELÉ. `camp_checkpoint_place.gd`, qui pose
## les deux foyers, est GELÉ lui aussi. La scène `WorldV2.tscn`, elle, ne
## l'est pas : c'est par elle qu'`CampLiberation` est arrivé (D-058), et c'est
## par elle que celui-ci arrive. Conteneur FRÈRE, observateur, sans autorité
## sur le monde.
##
## POURQUOI PAS `FeuVisuel.visible` COMME SOURCE DE VÉRITÉ, alors que c'est le
## lien le plus court. Parce que ce serait laisser le VISUEL décider de
## l'ÉTAT du jeu, ce que `scripts/CLAUDE.md` interdit en toutes lettres : le
## visuel traduit une décision, il ne la prend pas. Un jour où le foyer serait
## masqué pour une autre raison — une transition, un preset graphique, un bug
## d'affichage — la cuisine se fermerait sans que personne comprenne pourquoi.
##
## LA RÈGLE RETENUE, et elle est plus simple que celle du script gelé : **le
## foyer est revendiqué tant qu'un garde de sa garnison est debout.** Pas de
## lecture de sauvegarde, pas de `camps_liberes`, pas de duplication de la loi
## « libéré = tous morts OU déjà noté ». On compte des vivants, une fois, puis
## on écoute leur mort. Un garde persisté mort n'est jamais instancié : au
## rechargement d'un camp pris, la liste est vide et le foyer est libre — sans
## qu'on ait eu à relire quoi que ce soit.
class_name CampCuisineGuard
extends Node

## LE CHEMIN DES DONNÉES EST INJECTÉ PAR LA SCÈNE, jamais écrit ici.
##
## Ce n'est pas de l'élégance, c'est un contrôle du dépôt :
## `test_aucune_reference_croisee_interdite` est TEXTUEL — il refuse le mot
## d'un sous-système dans un fichier hors de son arborescence, pas seulement
## la dépendance. Ce fichier vit dans `scripts/camp/`, donc il n'a pas le
## droit de nommer le chemin. Deux issues existaient : s'ajouter à la liste
## d'exemptions du test (que le test prévoit, en exigeant une justification),
## ou SUPPRIMER la dépendance. La seconde est meilleure et coûte trois lignes :
## la scène qui possède le camp lui passe sa donnée.
##
## Effet de bord utile : ce garde devient réutilisable pour un autre camp
## piloté par une autre donnée, sans le toucher.
@export_file("*.json") var donnees: String = ""

## Un foyer suivi : son nœud, et le nombre de gardes encore debout.
var _suivis: Array[Dictionary] = []


func _ready() -> void:
	# Différé comme les autres observateurs : la garnison est bâtie dans une
	# file différée, et un foyer sans garde compté serait libre à tort.
	call_deferred("_installer")


func _installer() -> void:
	var racine: Node = get_parent()
	if racine == null:
		return
	for camp: Dictionary in _camps():
		var chemin: String = String(camp.get("foyer_cuisine", ""))
		var garnison: String = String(camp.get("garrison", ""))
		if chemin == "" or garnison == "":
			continue
		var foyer: Node = racine.get_node_or_null(chemin)
		if foyer == null or not foyer.has_method("set_revendique"):
			push_warning("[cuisine] foyer introuvable ou muet : %s" % chemin)
			continue

		var gardes: Array[Node] = _gardes_vivants(racine, garnison)
		if gardes.is_empty():
			# Camp déjà pris — rien à revendiquer, rien à écouter.
			foyer.call("set_revendique", false)
			continue

		foyer.call("set_revendique", true)
		var suivi: Dictionary = {"foyer": foyer, "restants": gardes.size()}
		_suivis.append(suivi)
		for garde: Node in gardes:
			garde.connect("died", _sur_mort.bind(suivi))


func _camps() -> Array[Dictionary]:
	var sortie: Array[Dictionary] = []
	var brut: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(donnees))
	if not (brut is Dictionary):
		push_warning("[cuisine] données de camp illisibles : %s" % donnees)
		return sortie
	for entree: Variant in ((brut as Dictionary).get("camps", []) as Array):
		sortie.append(entree as Dictionary)
	return sortie


## Les mêmes trois pièges que pour la libération, et pour les mêmes raisons :
## `owned = false` car les ennemis naissent au runtime ; `health().is_dead()`
## car `_on_died()` laisse le cadavre dans l'arbre ; et le préfixe se termine
## par un point, pour qu'une future « garrison.ember_camp_nord » ne soit pas
## avalée par « garrison.ember_camp ».
func _gardes_vivants(racine: Node, garnison: String) -> Array[Node]:
	var sortie: Array[Node] = []
	var prefixe: String = garnison + "."
	for e: Node in racine.find_children("*", "EnemyBase", true, false):
		var meta: String = String(e.get_meta(&"encounter_id", ""))
		if meta != garnison and not meta.begins_with(prefixe):
			continue
		var sante: Node = e.call("health") as Node
		if sante != null and not bool(sante.call("is_dead")):
			sortie.append(e)
	return sortie


func _sur_mort(suivi: Dictionary) -> void:
	suivi["restants"] = int(suivi["restants"]) - 1
	if int(suivi["restants"]) > 0:
		return
	var foyer: Variant = suivi.get("foyer")
	if foyer is Node and is_instance_valid(foyer as Node) \
			and (foyer as Node).has_method("set_revendique"):
		(foyer as Node).call("set_revendique", false)
