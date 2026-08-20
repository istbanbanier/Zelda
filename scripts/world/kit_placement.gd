## Assise au sol des modèles du kit — « rien ne flotte » (bible §4, contrat d'asset).
##
## LE DÉFAUT QU'IL CORRIGE. Les bâtisseurs du monde posent un modèle en écrivant
## sa position, et supposent tous la même chose : que l'origine du modèle est à
## sa BASE. C'est faux pour une partie du kit CC0. Mesuré par
## `tools/gltf_inspect.py` :
##
##     Prop_Support.gltf   bbox_min.y = +1,2114
##
## Sa géométrie commence 1,21 m AU-DESSUS de son propre point d'ancrage. Posé au
## sol, il flotte à 1,21 m. Le joueur voit des objets suspendus sans raison, et
## aucun réglage de position ne peut le corriger — la faute est dans le modèle,
## pas dans le placement.
##
## LA RÈGLE APPLIQUÉE. Un modèle ne peut pas commencer au-dessus de son ancrage.
## Si le point le plus bas de sa géométrie est au-dessus de son origine, on
## descend l'objet d'autant. Rien d'autre n'est touché :
##
##  - un modèle correctement centré sur sa base (min.y ≈ 0) n'est PAS déplacé ;
##  - un modèle dont la géométrie descend sous son origine (min.y < 0, cas des
##    props centrés) n'est PAS remonté — ce serait supposer une intention ;
##  - la hauteur demandée par l'appelant est CONSERVÉE : on ne retire que le
##    défaut interne du modèle, jamais l'intention du level design. Une bannière
##    voulue à 4 m reste à 4 m.
##
## La mesure tient compte de l'échelle et de la rotation déjà appliquées, et
## le résultat est mis en cache par scène : une forêt de 400 arbres ne mesure
## le même modèle qu'une fois.
class_name KitPlacement
extends RefCounted

## En deçà, l'écart relève du bruit de modélisation et non d'un défaut d'origine.
const FLOAT_TOLERANCE: float = 0.05

## Chemin de scène → point le plus bas de la géométrie, en unités locales.
static var _base_cache: Dictionary = {}
## Compteur de diagnostic : combien de modèles ont réellement dû être rassis.
static var seated_count: int = 0
static var inspected_count: int = 0


## Boîte englobante fusionnée de toute la géométrie, dans l'espace local de
## `root`. Fonctionne sur une instance HORS de l'arbre : `get_aabb()` interroge
## le maillage, pas le rendu.
static func local_aabb(root: Node3D) -> AABB:
	var merged: AABB = AABB()
	var first: bool = true
	for node: Node in root.find_children("*", "VisualInstance3D", true, false):
		var visual: VisualInstance3D = node as VisualInstance3D
		if visual == null:
			continue
		if visual is MeshInstance3D and (visual as MeshInstance3D).mesh == null:
			continue
		var relative: Transform3D = root.global_transform.affine_inverse() \
			* visual.global_transform if root.is_inside_tree() \
			else _relative_transform(root, visual)
		var box: AABB = relative * visual.get_aabb()
		if first:
			merged = box
			first = false
		else:
			merged = merged.merge(box)
	if root is VisualInstance3D:
		var own: AABB = (root as VisualInstance3D).get_aabb()
		merged = own if first else merged.merge(own)
	return merged


## Transform d'un descendant relativement à sa racine, sans passer par l'arbre.
static func _relative_transform(root: Node3D, node: Node3D) -> Transform3D:
	var chain: Transform3D = Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != root:
		if current is Node3D:
			chain = (current as Node3D).transform * chain
		current = current.get_parent()
	return chain


## Point le plus bas du modèle dans son espace local, mis en cache par scène.
static func _base_offset(node: Node3D, cache_key: String) -> float:
	if cache_key != "" and _base_cache.has(cache_key):
		return _base_cache[cache_key] as float
	var box: AABB = local_aabb(node)
	var value: float = 0.0 if box.size == Vector3.ZERO else box.position.y
	if cache_key != "":
		_base_cache[cache_key] = value
	return value


## Assoit `node` : si sa géométrie commence au-dessus de son ancrage, on l'y
## ramène. Renvoie la correction appliquée en mètres (0 si rien à faire).
##
## `cache_key` est le chemin de la scène source — le passer évite de remesurer
## le même modèle des centaines de fois.
static func seat(node: Node3D, cache_key: String = "") -> float:
	if node == null:
		return 0.0
	inspected_count += 1
	var base: float = _base_offset(node, cache_key)
	if base <= FLOAT_TOLERANCE:
		return 0.0
	# L'échelle et la rotation sont déjà posées : la correction doit être
	# mesurée dans l'espace du PARENT, pas dans celui du modèle.
	var lowest: float = (node.transform.basis * Vector3(0.0, base, 0.0)).y
	if lowest <= FLOAT_TOLERANCE:
		return 0.0
	node.position.y -= lowest
	seated_count += 1
	return lowest


## Remet les compteurs à zéro (tests et rapports de session).
static func reset_stats() -> void:
	seated_count = 0
	inspected_count = 0

## ISS-059 — fin de vie du cache statique. Inscrite au démarrage du
## script par `_static_init()`, appelée UNE fois à l'extinction du moteur
## par `SceneFlow._exit_tree()`. Sans elle, ces entrées vivent jusqu'à la
## mort du processus et sortent au rapport de fuite : mesure et ablation à
## variable unique, `evidence/…/v2_3_r2b3_1/iss059/CHAINE_CAUSALE.md`.
##
## Le sens de la dépendance est imposé : le porteur connaît le noyau, le
## noyau ne connaît aucun porteur (test_aucune_reference_croisee_interdite).
static func _static_init() -> void:
	StaticResourceCaches.enregistrer("KitPlacement", liberer_caches)


static func liberer_caches() -> int:
	var n: int = _base_cache.size()
	_base_cache.clear()
	return n
