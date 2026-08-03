## RÉCOMPENSES des découvertes (ordre d'extension §3).
##
## Première version : 31 coffres identiques, dont 23 posés au centre du volume
## du lieu faute d'ancrage. Deux fautes en une — la même récompense partout, et
## un placement plausible mais jamais vérifié.
##
## Celle-ci corrige les deux :
##
##  - le placement vient d'un `RewardAnchor` explicite, posé par le bâtisseur
##    du lieu, éprouvé par `RewardAnchorAudit` (sol, dégagement, accès, retour).
##    Plus de repli : un lieu sans ancrage est SIGNALÉ, pas servi au hasard ;
##  - la nature de la récompense vient de l'ancrage (`kind`) et son contenu de
##    la table `PLAN` ci-dessous. Trente et un lieux, sept natures : coffre,
##    arme au sol, ingrédient rare, savoir, fragment d'histoire, récompense
##    d'énigme, récompense de territoire.
##
## Ce que cette classe ne fait PAS, et qu'il faut dire : les natures `PUZZLE`
## et `COMBAT` décrivent l'INTENTION du lieu, pas encore une condition
## d'ouverture. Le coffre du territoire est réel et persistant, mais il n'est
## pas verrouillé jusqu'à la mort des ennemis. `deferred_gates()` les nomme
## pour que ce manque reste visible au lieu de se dissoudre dans un total.
class_name DiscoveryRewards
extends Node3D

const CHEST_SCENE: String = "res://scenes/interactables/Chest.tscn"
const WEAPON_SCENE: String = "res://scenes/interactables/WeaponPickup.tscn"
const WEAPON_DIR: String = "res://resources/weapons/%s.tres"
const INGREDIENT_DIR: String = "res://resources/ingredients/%s.tres"

## Contenu par lieu. Data-driven au sens strict : ajouter un lieu, c'est
## ajouter une ligne ici et un ancrage là-bas, jamais toucher au code de pose.
##
## Clés reconnues : `weapon` (identifiant de `resources/weapons`), `arrows`,
## `ingredient` (identifiant de `resources/ingredients`), `title` + `text`
## pour un fragment d'histoire.
const PLAN: Dictionary = {
	# --- Village et hameaux ---------------------------------------------
	&"valley.poi.riverside_village.01": {"weapon": "worn_sword"},
	&"valley.poi.logging_hamlet.01": {"weapon": "wood_club"},
	&"valley.poi.mining_post.01": {"arrows": 12},
	# --- Ruines -----------------------------------------------------------
	&"valley.poi.watchtower_ruin.01": {"arrows": 15},
	&"valley.poi.ancient_aqueduct.01": {
		"title": "Le canal mort",
		"text": "L'eau montait ici sans pompe ni bête. Les dalles ivoire "
			+ "séparaient le courant de la pierre — on savait déjà s'en "
			+ "protéger.",
	},
	&"valley.poi.abandoned_farm.01": {"ingredient": "heal_fruit"},
	&"valley.poi.storm_caravan.01": {"weapon": "spear"},
	# --- Vestiges ---------------------------------------------------------
	&"valley.poi.ruined_observatory.01": {
		"title": "Relevés de l'orage",
		"text": "Trois cents nuits de mesures, une seule conclusion : la "
			+ "tempête ne passe pas au-dessus de la citadelle. Elle y reste.",
	},
	&"valley.poi.barrow_cemetery.01": {"weapon": "heavy_axe"},
	&"valley.poi.old_rampart.01": {"arrows": 15},
	&"valley.poi.forest_shrine.01": {"ingredient": "rare_spice"},
	# --- Grottes ----------------------------------------------------------
	&"valley.poi.waterfall_cave.01": {"ingredient": "heal_mushroom"},
	&"valley.poi.abandoned_mine.01": {"weapon": "heavy_axe"},
	&"valley.poi.hollow_crypt.01": {"weapon": "conductive_blade"},
	# --- Souterrains ------------------------------------------------------
	&"valley.poi.hidden_passage.01": {"arrows": 20},
	&"valley.poi.crystal_hollow.01": {"arrows": 20},
	# --- Repères naturels -------------------------------------------------
	&"valley.poi.ancient_tree.01": {"ingredient": "rare_spice"},
	&"valley.poi.turquoise_spring.01": {"ingredient": "heal_fruit"},
	&"valley.poi.flower_field.01": {"ingredient": "stamina_herb"},
	&"valley.poi.stone_bridge.01": {
		"title": "La marque du passeur",
		"text": "Une entaille par traversée. Le pont en compte des centaines, "
			+ "puis plus rien : la dernière est fraîche d'un hiver.",
	},
	&"valley.poi.overlook_summit.01": {"weapon": "simple_bow"},
	# --- Merveilles -------------------------------------------------------
	&"valley.poi.veil_falls.01": {"arrows": 12},
	&"valley.poi.watchers_circle.01": {
		"title": "Le cercle qui écoute",
		"text": "Sept pierres debout, aucune foudroyée. Elles ne captent pas "
			+ "l'orage : elles le détournent vers la vallée voisine.",
	},
	&"valley.poi.wind_gorge.01": {"ingredient": "stamina_herb"},
	&"valley.poi.storm_grove.01": {"ingredient": "storm_berry"},
	&"valley.poi.thunderstruck_tree.01": {"ingredient": "rare_spice"},
	# --- Territoires ennemis ----------------------------------------------
	&"valley.poi.ember_raider_camps.01": {"weapon": "wood_club"},
	&"valley.poi.azure_patrol_run.01": {"arrows": 20},
	&"valley.poi.obsidian_bastion.01": {"weapon": "heavy_axe"},
	&"valley.poi.colossus_lair.01": {"weapon": "conductive_blade"},
	&"valley.poi.hunter_range.01": {"weapon": "simple_bow"},
}

var _placed: int = 0
var _skipped: Array[StringName] = []
var _by_kind: Dictionary = {}
var _deferred: Array[StringName] = []


func placed_count() -> int:
	return _placed


## Lieux déclarés au journal mais SANS ancrage : ils ne reçoivent rien. Nommés
## plutôt que comptés — un manque tu est un manque qui reste.
func skipped_places() -> Array[StringName]:
	return _skipped.duplicate()


## Combien de récompenses par nature. Le test s'en sert pour refuser un monde
## qui aurait glissé vers « 31 coffres » sans que personne ne le voie.
func counts_by_kind() -> Dictionary:
	return _by_kind.duplicate()


## Lieux dont la nature promet une condition d'ouverture pas encore
## implémentée (énigme résolue, territoire nettoyé). Le coffre existe ; le
## verrou, non.
func deferred_gates() -> Array[StringName]:
	return _deferred.duplicate()


## Pose une récompense sur chaque ancrage du monde `world`.
func furnish(world: Node) -> int:
	var anchors: Dictionary = {}
	for node: Node in world.find_children("*", "RewardAnchor", true, false):
		var anchor: RewardAnchor = node as RewardAnchor
		if String(anchor.place_id).is_empty():
			push_warning("[récompenses] ancrage sans lieu : %s"
				% anchor.get_path())
			continue
		if anchors.has(anchor.place_id):
			push_warning("[récompenses] deux ancrages pour %s — le second est "
				% anchor.place_id + "ignoré")
			continue
		anchors[anchor.place_id] = anchor

	# Les lieux mènent la revue, pas les ancrages : c'est le lieu SANS ancrage
	# qu'il faut voir, et un ancrage ne peut pas signaler sa propre absence.
	for node: Node in world.find_children("*", "PointOfInterest", true, false):
		var poi: PointOfInterest = node as PointOfInterest
		if String(poi.poi_id).is_empty():
			continue
		if not anchors.has(poi.poi_id):
			_skipped.append(poi.poi_id)
			continue
		_grant(anchors[poi.poi_id] as RewardAnchor)
	return _placed


## Identifiant persistant dérivé de celui du lieu : `valley.poi.x.01` devient
## `valley.chest.x.01`. Unique par construction, aucune table à tenir (§19.3).
static func persistent_id(place: StringName, category: String) -> StringName:
	return StringName(String(place).replace(".poi.", ".%s." % category))


func _grant(anchor: RewardAnchor) -> void:
	var payload: Dictionary = PLAN.get(anchor.place_id, {}) as Dictionary
	var reward: Node3D = null
	match anchor.kind:
		RewardAnchor.Kind.WEAPON:
			reward = _weapon_pickup(anchor, payload)
		RewardAnchor.Kind.INGREDIENT, RewardAnchor.Kind.RECIPE:
			reward = _ingredient_pickup(anchor, payload)
		RewardAnchor.Kind.STORY:
			reward = _story_fragment(anchor, payload)
		RewardAnchor.Kind.PUZZLE, RewardAnchor.Kind.COMBAT:
			_deferred.append(anchor.place_id)
			reward = _chest(anchor, payload)
		_:
			reward = _chest(anchor, payload)
	if reward == null:
		_skipped.append(anchor.place_id)
		return
	# Enfant de l'ancrage : la récompense SUIT le point éprouvé. La poser à
	# une position globale recopiée la laisserait dériver au premier
	# déplacement du lieu.
	anchor.add_child(reward)
	reward.position = Vector3.ZERO
	_placed += 1
	var key: int = anchor.kind
	_by_kind[key] = int(_by_kind.get(key, 0)) + 1


func _chest(anchor: RewardAnchor, payload: Dictionary) -> Node3D:
	var packed: PackedScene = load(CHEST_SCENE) as PackedScene
	if packed == null:
		push_warning("[récompenses] scène de coffre introuvable")
		return null
	var chest: Chest = packed.instantiate() as Chest
	chest.chest_id = persistent_id(anchor.place_id, "chest")
	var weapon: WeaponDefinition = _weapon_of(payload)
	if weapon != null:
		chest.weapon_loot = weapon
	chest.arrows_loot = int(payload.get("arrows", 0))
	if weapon == null and chest.arrows_loot <= 0:
		# Un coffre vide serait une récompense en trompe-l'œil.
		chest.arrows_loot = 10
	return chest


func _weapon_pickup(anchor: RewardAnchor, payload: Dictionary) -> Node3D:
	var weapon: WeaponDefinition = _weapon_of(payload)
	if weapon == null:
		push_warning("[récompenses] %s : arme au sol sans définition — repli coffre"
			% anchor.place_id)
		return _chest(anchor, payload)
	var packed: PackedScene = load(WEAPON_SCENE) as PackedScene
	if packed == null:
		push_warning("[récompenses] scène d'arme au sol introuvable")
		return null
	var pickup: WeaponPickup = packed.instantiate() as WeaponPickup
	pickup.definition = weapon
	pickup.pickup_id = persistent_id(anchor.place_id, "pickup")
	return pickup


func _ingredient_pickup(anchor: RewardAnchor, payload: Dictionary) -> Node3D:
	var id: String = String(payload.get("ingredient", ""))
	if id.is_empty():
		return _chest(anchor, payload)
	var path: String = INGREDIENT_DIR % id
	if not ResourceLoader.exists(path):
		push_warning("[récompenses] ingrédient inconnu : %s" % id)
		return _chest(anchor, payload)
	var pickup: IngredientPickup = IngredientPickup.new()
	pickup.name = "RecompenseIngredient"
	pickup.definition = load(path) as IngredientDefinition
	pickup.pickup_id = persistent_id(anchor.place_id, "ingredient")
	return pickup


func _story_fragment(anchor: RewardAnchor, payload: Dictionary) -> Node3D:
	var text: String = String(payload.get("text", ""))
	if text.strip_edges().is_empty():
		push_warning("[récompenses] %s : fragment sans texte — repli coffre"
			% anchor.place_id)
		return _chest(anchor, payload)
	var fragment: StoryFragment = StoryFragment.new()
	fragment.name = "FragmentHistoire"
	fragment.fragment_id = persistent_id(anchor.place_id, "story")
	fragment.title = String(payload.get("title", ""))
	fragment.text = text
	return fragment


func _weapon_of(payload: Dictionary) -> WeaponDefinition:
	var id: String = String(payload.get("weapon", ""))
	if id.is_empty():
		return null
	var path: String = WEAPON_DIR % id
	if not ResourceLoader.exists(path):
		push_warning("[récompenses] arme inconnue : %s" % id)
		return null
	return load(path) as WeaponDefinition
