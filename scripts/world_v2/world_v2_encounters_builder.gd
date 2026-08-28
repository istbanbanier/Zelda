## ISS-074 — LE PEUPLEMENT DE WORLD V2, PILOTÉ PAR DONNÉES.
##
## Ce nœud est le script du conteneur `Encounters` de `WorldV2.tscn`. Ce
## conteneur existait depuis V2.0, était exigé par `REQUIRED_CONTAINERS`, et
## restait VIDE : le monde n'avait aucun adversaire. C'est ISS-074.
##
## POURQUOI ICI, ET PAS DANS `world_v2_root.gd`. La racine du monde est GELÉE
## (`docs/contrats/gel_v2_3_b.sha256`). Peupler depuis un script porté par un
## conteneur non gelé évite une levée de gel dont la passe n'a pas besoin —
## et laisse la construction du monde exactement où elle était.
##
## CE QU'IL NE CONTIENT PAS : aucune coordonnée, aucun compte, aucun réglage.
## Tout vient de `resources/world_v2/world_v2_garrisons.json`. Ajouter une
## garnison n'est donc pas une modification de code.
##
## QUATRE PIÈGES MESURÉS, refermés ici, chacun silencieux :
##
##  1. `EnemyBase` capture son `_territory_origin` depuis `global_position`
##     DANS son `_ready()`, et n'offre aucun setter. Poser la position APRÈS
##     `add_child()` ancre donc tout le territoire à l'origine du monde, et
##     l'ennemi rentre « chez lui » à (0, 0, 0). La position est écrite AVANT.
##     Même piège pour `RaiderBlue._flank_side`, calculé depuis `position.x`.
##
##  2. Le `tuning` d'une scène d'ennemi est une RESSOURCE PARTAGÉE (`.tres`).
##     L'écrire réglerait tous les pillards du jeu, V1 comprise. On en prend
##     donc une COPIE par ennemi — « définitions immuables, état mutable
##     séparé » (`CLAUDE.md`).
##
##  3. Godot renomme les homonymes en `@Node3D@366`. Un identifiant porté par
##     le seul nom de nœud serait donc instable ; l'identité vit dans une méta
##     `encounter_id`, et le nom la recopie pour la lisibilité du débogage.
##
##  4. Un slot présent mais ILLISIBLE rend `{}` exactement comme un slot
##     absent (C10). Y écrire les morts écraserait la sauvegarde d'un build
##     plus récent. On refuse d'écrire, bruyamment.
class_name WorldV2EncountersBuilder
extends Node3D

const DONNEES: String = "res://resources/world_v2/world_v2_garrisons.json"
const SAVE_SLOT: String = "slot0"
## Champ ADDITIF du schéma de sauvegarde : les identifiants de garnison
## tombés. `WorldV2Root.autosave()` fusionne ses quatre champs (`merge`) sans
## toucher au reste — celui-ci lui survit donc, et T1 reste intact.
const CHAMP_MORTS: String = "enemies_slain"

var _built: bool = false
var _coordinator: CombatCoordinator = null
var _vivants: Dictionary = {}


func _ready() -> void:
	# En différé : le monde entier — terrain, navigation, lieux, joueur —
	# doit exister avant qu'un adversaire n'y soit posé.
	call_deferred("_build")


func _build() -> void:
	if _built:
		return
	_built = true
	var donnees: Dictionary = _lire_donnees()
	if donnees.is_empty():
		return
	var morts: Dictionary = _morts_persistees()

	_coordinator = CombatCoordinator.new()
	_coordinator.name = "CombatCoordinator"
	add_child(_coordinator)

	var poses: int = 0
	var sautes: int = 0
	for entree: Variant in (donnees.get("garrisons", []) as Array):
		var garnison: Dictionary = entree as Dictionary
		var hote: Node3D = Node3D.new()
		hote.name = String(garnison.get("id", "garrison"))
		add_child(hote)
		for brut: Variant in (garnison.get("enemies", []) as Array):
			var fiche: Dictionary = brut as Dictionary
			var id: String = String(fiche.get("id", ""))
			if id.is_empty():
				push_warning("[peuplement] fiche sans identifiant — ignorée")
				continue
			if morts.has(id):
				sautes += 1
				continue
			if _poser(hote, fiche, id):
				poses += 1
	print("[peuplement] garnison : %d posé(s), %d déjà tombé(s)"
		% [poses, sautes])


func _poser(hote: Node3D, fiche: Dictionary, id: String) -> bool:
	var chemin: String = String(fiche.get("scene", ""))
	if not ResourceLoader.exists(chemin):
		push_warning("[peuplement] scène introuvable : %s" % chemin)
		return false
	var ennemi: EnemyBase = (load(chemin) as PackedScene).instantiate() as EnemyBase
	if ennemi == null:
		push_warning("[peuplement] %s n'est pas un EnemyBase" % chemin)
		return false

	# Piège 2 : une COPIE du tuning, jamais la ressource partagée.
	var base: EnemyTuning = ennemi.tuning
	var reglage: EnemyTuning = base.duplicate() as EnemyTuning \
		if base != null else EnemyTuning.new()
	if fiche.has("vision_range"):
		reglage.vision_range = float(fiche["vision_range"])
	if fiche.has("max_pursuit_distance"):
		reglage.max_pursuit_distance = float(fiche["max_pursuit_distance"])
	ennemi.tuning = reglage

	# Piège 1 : la position AVANT `add_child()`.
	var p: Array = fiche.get("position", [0, 0, 0]) as Array
	ennemi.position = Vector3(float(p[0]), float(p[1]), float(p[2]))

	var rondes: Array[Vector3] = []
	for decalage: Variant in (fiche.get("patrol_offsets", []) as Array):
		var d: Array = decalage as Array
		rondes.append(Vector3(float(d[0]), float(d[1]), float(d[2])))
	ennemi.patrol_offsets = rondes

	# Piège 3 : l'identité vit dans la méta ; le nom la recopie.
	ennemi.name = id.replace(".", "_")
	ennemi.set_meta(&"encounter_id", id)

	hote.add_child(ennemi)
	_vivants[id] = ennemi

	# Le REGARD se pose sur le pivot, jamais sur le corps : c'est le pivot que
	# `_tick_perception()` lit comme direction avant.
	var pivot: Node3D = ennemi.get_node_or_null("Pivot") as Node3D
	if pivot != null:
		pivot.rotation.y = deg_to_rad(float(fiche.get("yaw_deg", 0.0)))

	# `EnemyBase.died` est SANS argument — celui de `HealthComponent` en porte
	# un. Se brancher sur le mauvais des deux donne une erreur d'arité.
	ennemi.died.connect(_sur_mort.bind(id))
	return true


func _sur_mort(id: String) -> void:
	_vivants.erase(id)
	_persister_mort(id)


## La mort est écrite dans la sauvegarde EXISTANTE. Elle n'en fabrique jamais
## une : une partie sans sauvegarde n'a pas de progression à protéger, et
## inventer un slot ici allumerait « Continuer » sur un état que le joueur n'a
## pas demandé de garder.
func _persister_mort(id: String) -> void:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null:
		return
	if not bool(save_system.call("has_save", SAVE_SLOT)):
		print("[peuplement] « %s » est tombé — aucune sauvegarde à mettre à "
			% id + "jour pour l'instant")
		return
	var payload: Dictionary = save_system.call("load_slot", SAVE_SLOT) as Dictionary
	# Piège 4 — la garde de C10, à l'identique.
	if payload.is_empty():
		push_warning("[peuplement] slot présent mais illisible — mort NON "
			+ "écrite pour ne pas l'écraser (§19.4)")
		return
	var morts: Array = payload.get(CHAMP_MORTS, []) as Array
	if morts.has(id):
		return
	morts.append(id)
	payload[CHAMP_MORTS] = morts
	save_system.call("save_slot", SAVE_SLOT, payload)


func _morts_persistees() -> Dictionary:
	var morts: Dictionary = {}
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null or not bool(save_system.call("has_save", SAVE_SLOT)):
		return morts
	var payload: Dictionary = save_system.call("load_slot", SAVE_SLOT) as Dictionary
	if payload.is_empty():
		return morts
	for entree: Variant in (payload.get(CHAMP_MORTS, []) as Array):
		morts[String(entree)] = true
	return morts


func _lire_donnees() -> Dictionary:
	if not FileAccess.file_exists(DONNEES):
		push_warning("[peuplement] données absentes : %s" % DONNEES)
		return {}
	var brut: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(DONNEES))
	if brut is not Dictionary:
		push_warning("[peuplement] données illisibles : %s" % DONNEES)
		return {}
	return brut as Dictionary


## Le coordinateur du monde, pour un portail qui veut le désigner sans
## dépendre du groupe global.
func coordinator() -> CombatCoordinator:
	return _coordinator
