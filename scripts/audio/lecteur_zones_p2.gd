## Lecteur de zone du prototype P2 — ISS-087, D-066.
##
## Commute deux lits d'ambiance (« ouvert » / « fermé ») selon la région où se
## trouve le joueur. Les régions sont DÉCOUVERTES par le groupe
## `&"world_v2_regions"` et leur métadonnée `bounds`, posées par
## `world_v2_markers_builder.gd` — rien n'est ajouté au layout gelé.
##
## Les deux cas qui ne sont PAS des cas limites (INVENTAIRE_SONORE §5) :
## - **aucune région** (19,3 % du disque jouable) : GARDER le lit courant,
##   jamais le silence — un trou de découpage muet paraîtrait cassé ;
## - **recouvrements** (onze recouvrements pour dix paires) : premier match
##   dans `ORDRE_REGIONS`, ordre déclaré ici, stable, reproductible.
##
## `bounds` est un TABLEAU de dictionnaires, sous DEUX formes : `{x, z}` pour
## les treize boîtes, `{ring_radius_m}` pour l'anneau frontalier r11. Ignorer
## la seconde laisserait la bordure muette.
##
## Bascule = coupe franche par `play_ambience(l'autre lit, self)` — ASSUMÉE et
## documentée : pas de fondu, donc AUCUNE modification d'`AudioManager` (le
## fondu exigerait un second lecteur, voir PROTOTYPES_AMBIANCE §4). Le lecteur
## unique garantit que deux lits ne se superposent jamais.
##
## Propriété ISS-086 STRICTE : ce nœud démarre ses lits avec `self` comme
## propriétaire et les rend dans son propre `_exit_tree()`. Qui démarre rend.
##
## Sondé par `Timer` (0,5 s), jamais `_process` ; hystérésis de 2 s avant
## toute bascule pour qu'une marche le long d'une frontière ne fasse pas
## battre le son. SANS `class_name` (contrat de résidu) : chargé par
## `preload(...).new()` depuis `gameplay_shell.gd`.
extends Node

const LIT_OUVERT: StringName = &"amb_p2_ouvert"
const LIT_FERME: StringName = &"amb_p2_ferme"
const GROUPE_REGIONS: StringName = &"world_v2_regions"
const PERIODE_SONDE_S: float = 0.5
const HYSTERESIS_S: float = 2.0

## Ordre STABLE de résolution des recouvrements : premier match gagne. C'est
## l'ordre du document (r01..r11), déclaré ici et non dérivé de l'ordre des
## nœuds dans l'arbre, qui n'est pas contractuel.
const ORDRE_REGIONS: Array[StringName] = [
	&"r01_crete_de_l_aube",
	&"r02_prairie_mille_fleurs",
	&"r03_val_de_neris",
	&"r04_falaises_du_couchant",
	&"r05_terrasse_du_camp",
	&"r06_bois_du_levant",
	&"r07_hauteurs_de_l_orient",
	&"r08_steppe_du_nord",
	&"r09_ruines_du_coeur",
	&"r10_marche_de_l_orage",
	&"r11_anneau_frontalier",
]

## Table région -> lit, DÉRIVÉE de l'inventaire réel des onze régions de
## `world_v2_layout.json` (fonctions et altitudes citées). « ouvert » = plein
## air ; « fermé » = couvert ou encaissé :
## - r01 crête d'ouverture, r02 prairie, r05 clairière du camp, r07 hauteurs
##   panoramiques, r08 steppe, r10 marche du lac : PLEIN AIR -> ouvert ;
## - r03 lit de rivière encaissé (altitude -1,5..3 m entre berges), r04 pied
##   et paroi des falaises, r06 bois (couvert végétal), r09 ruines (murs,
##   aqueduc), r11 cols encaissés de la bordure : COUVERT/ENCAISSÉ -> fermé.
const LIT_PAR_REGION: Dictionary[StringName, StringName] = {
	&"r01_crete_de_l_aube": LIT_OUVERT,
	&"r02_prairie_mille_fleurs": LIT_OUVERT,
	&"r03_val_de_neris": LIT_FERME,
	&"r04_falaises_du_couchant": LIT_FERME,
	&"r05_terrasse_du_camp": LIT_OUVERT,
	&"r06_bois_du_levant": LIT_FERME,
	&"r07_hauteurs_de_l_orient": LIT_OUVERT,
	&"r08_steppe_du_nord": LIT_OUVERT,
	&"r09_ruines_du_coeur": LIT_FERME,
	&"r10_marche_de_l_orage": LIT_OUVERT,
	&"r11_anneau_frontalier": LIT_FERME,
}

## La coquille qui a créé ce lecteur — elle sait quel joueur SA scène sert
## (`bound_player()`), règle F.6 : jamais le premier venu du groupe `player`.
## Typée `Node` et interrogée par `call()`, à dessein : `gameplay_shell.gd`
## précharge CE script — le typer `GameplayShell` ici fermerait un cycle de
## dépendance entre les deux fichiers (interdit, `.claude/rules/gdscript.md`).
var _coquille: Node = null
var _minuterie: Timer = null
## Nœuds de région découverts, par id. Rebâti si vide ou si un nœud est mort :
## les marqueurs peuvent naître APRÈS ce lecteur, et mourir à la transition.
var _regions: Dictionary[StringName, Node3D] = {}
var _lit_courant: StringName = &""
var _candidat: StringName = &""
var _depuis_candidat_s: float = 0.0
var _arrete: bool = false


func configurer(coquille: Node) -> void:
	_coquille = coquille


func _ready() -> void:
	# La coquille est PROCESS_MODE_ALWAYS ; l'ambiance, elle, est un système de
	# gameplay : la sonde gèle pendant la pause (§13.3 — aucune minuterie de
	# gameplay ne court), comme l'AudioManager qu'elle pilote.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_minuterie = Timer.new()
	_minuterie.name = "SondeRegions"
	_minuterie.wait_time = PERIODE_SONDE_S
	_minuterie.one_shot = false
	_minuterie.timeout.connect(_sonder)
	add_child(_minuterie)
	_minuterie.start()
	# Lit de DÉPART, avant toute sonde : « ouvert » — le spawn (crête de
	# l'Aube) est en plein air, et « jamais le silence » vaut aussi pour la
	# première seconde.
	_jouer(LIT_OUVERT)


func _exit_tree() -> void:
	arreter()


## Idempotent : appelé par la coquille à sa sortie ET par le propre
## `_exit_tree()` de ce nœud — le premier arrivé rend, le second ne fait rien.
func arreter() -> void:
	if _arrete:
		return
	_arrete = true
	if _minuterie != null and is_instance_valid(_minuterie):
		_minuterie.stop()
	var audio: Node = _audio()
	if audio != null:
		audio.call("stop_ambience_owned_by", self)


func lit_courant() -> StringName:
	return _lit_courant


func _audio() -> Node:
	var arbre: SceneTree = get_tree()
	if arbre == null:
		return null
	return arbre.root.get_node_or_null("AudioManager")


func _jouer(lit: StringName) -> void:
	var audio: Node = _audio()
	if audio == null:
		return
	audio.call("play_ambience", lit, self)
	_lit_courant = lit


func _sonder() -> void:
	if _arrete or _coquille == null or not is_instance_valid(_coquille) \
			or not _coquille.has_method("bound_player"):
		return
	var joueur: Node3D = _coquille.call("bound_player") as Node3D
	if joueur == null or not is_instance_valid(joueur):
		return
	var position: Vector3 = joueur.global_position
	var region: StringName = _region_a(position.x, position.z)
	var lit: StringName = &""
	if region != &"" and LIT_PAR_REGION.has(region):
		lit = LIT_PAR_REGION[region]
	# Hors-région, ou même lit : rien à faire, l'hystérésis repart de zéro.
	if lit == &"" or lit == _lit_courant:
		_candidat = &""
		_depuis_candidat_s = 0.0
		return
	if lit != _candidat:
		_candidat = lit
		_depuis_candidat_s = 0.0
		return
	_depuis_candidat_s += PERIODE_SONDE_S
	if _depuis_candidat_s >= HYSTERESIS_S:
		_jouer(lit)
		_candidat = &""
		_depuis_candidat_s = 0.0


## Première région de `ORDRE_REGIONS` dont une boîte (ou l'anneau) contient
## (x, z). `&""` si aucune — 19,3 % du disque jouable, cas ORDINAIRE.
func _region_a(x: float, z: float) -> StringName:
	_decouvrir_si_necessaire()
	for id: StringName in ORDRE_REGIONS:
		if not _regions.has(id):
			continue
		var node: Node3D = _regions[id]
		if not is_instance_valid(node):
			continue
		var bornes: Array = node.get_meta(&"bounds", []) as Array
		for entree: Variant in bornes:
			if entree is Dictionary and _dans_la_boite(entree as Dictionary, x, z):
				return id
	return &""


func _dans_la_boite(boite: Dictionary, x: float, z: float) -> bool:
	if boite.has("x") and boite.has("z"):
		var bx: Array = boite["x"] as Array
		var bz: Array = boite["z"] as Array
		return x >= float(bx[0]) and x <= float(bx[1]) \
			and z >= float(bz[0]) and z <= float(bz[1])
	if boite.has("ring_radius_m"):
		var anneau: Array = boite["ring_radius_m"] as Array
		var rayon: float = sqrt(x * x + z * z)
		return rayon >= float(anneau[0]) and rayon <= float(anneau[1])
	return false


func _decouvrir_si_necessaire() -> void:
	var vivantes: bool = not _regions.is_empty()
	for id: StringName in _regions:
		var node: Node3D = _regions[id]
		if node == null or not is_instance_valid(node):
			vivantes = false
			break
	if vivantes:
		return
	_regions.clear()
	var arbre: SceneTree = get_tree()
	if arbre == null:
		return
	for node: Node in arbre.get_nodes_in_group(GROUPE_REGIONS):
		var region: Node3D = node as Node3D
		if region != null and region.has_meta(&"bounds"):
			_regions[StringName(region.name)] = region
