## UNE RÉCOMPENSE QU'ON NE PEUT PAS ATTEINDRE N'EST PAS UNE RÉCOMPENSE.
##
## POURQUOI CE FICHIER EXISTE. `test_world_v2_camp_libere.gd` prouve que le
## coffre est POSÉ, qu'il porte la bonne arme et qu'il ne se duplique pas. Il
## ne dit rien de l'endroit. Or la position (44, 6, 68) est un littéral écrit
## à la main dans `world_v2_camp_liberation.json` : rien, jusqu'ici, ne
## vérifiait qu'elle tombe sur du sol, ni qu'un joueur puisse s'en approcher.
##
## Le défaut qu'il attrape est silencieux et complet : un coffre enterré dans
## le terrain, flottant à 80 cm, ou posé derrière la palissade, passe TOUS les
## autres tests du camp. Le contrat C2 « récompense fixe et utile » serait vert
## pendant qu'aucun joueur ne peut la prendre.
##
## CE QUE « ATTEIGNABLE » VEUT DIRE ICI, ET RIEN DE PLUS. Le mot est repris de
## la seule définition qui fasse foi : celle du joueur, dans
## `player_controller.gd`, `_select_interactable()` —
##
##   INTERACT_RANGE   2.2 m, distance HORIZONTALE (y écrasé) ;
##   INTERACT_MIN_DOT 0.25, il faut regarder vers l'objet ;
##   `_has_interact_los()`, rayon torse (+1,2) → objet (+0,5), couche 1,
##                    l'objet lui-même exclu.
##
## Donc « atteignable » = il existe une station où le joueur TIENT DEBOUT, à
## moins de 2,2 m à l'horizontale, d'où la ligne de vue passe. Ce n'est PAS
## une preuve de cheminement depuis le point de départ : un test d'éditeur ne
## peut pas prouver qu'on sait y arriver, et prétendre le contraire serait la
## même faute que mesurer une pose de liaison au lieu de ce que le moteur
## dessine (ISS-018). La marche réelle jusqu'au camp est prouvée ailleurs, par
## le portail d'export de la garnison (G3).
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const DONNEES: String = "res://resources/world_v2/world_v2_camp_liberation.json"
const SLOT: String = "slot0"
const CAMP_ID: String = "camp.ember_terrace"
const GARNISON: String = "garrison.ember_camp"

## Repris de `player_controller.gd`. Ces trois nombres sont RECOPIÉS à dessein,
## et non lus depuis la classe : un test qui suit automatiquement la constante
## suivrait aussi son affaiblissement. Si le joueur change de portée, ce
## fichier doit être relu, pas se mettre d'accord tout seul.
const PORTEE_INTERACTION: float = 2.2
const HAUTEUR_TORSE: float = 1.2
const HAUTEUR_CIBLE: float = 0.5
const COUCHE_DECOR: int = 1

## Capsule du joueur, lue dans `scenes/player/Player.tscn` : rayon 0,35,
## hauteur 1,8.
const RAYON_JOUEUR: float = 0.35
const HAUTEUR_JOUEUR: float = 1.8

## L'anneau de stations essayées autour du coffre. 1,4 m : confortablement en
## deçà des 2,2 m, et assez loin pour qu'un corps de 0,35 m de rayon ne soit
## pas dans la caisse (demi-diagonale du coffre ≈ 0,61 m).
const RAYON_ANNEAU: float = 1.4
const STATIONS: int = 16

var _world: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _donnees() -> Dictionary:
	var brut: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(DONNEES))
	if not (brut is Dictionary):
		return {}
	for entree: Variant in ((brut as Dictionary).get("camps", []) as Array):
		var camp: Dictionary = entree as Dictionary
		if String(camp.get("id", "")) == CAMP_ID:
			return camp
	return {}


func _semer_libere() -> void:
	var ids: Array = []
	for suffixe: String in ["red.01", "red.02", "red.03", "blue.01"]:
		ids.append("%s.%s" % [GARNISON, suffixe])
	_tree().root.get_node_or_null("/root/SaveSystem").call("save_slot", SLOT, {
		"schema": 4, "world_version": "neris_v2",
		"checkpoint": "world_v2.valley",
		"enemies_slain": ids, "camps_liberes": [CAMP_ID],
	})


func _monter() -> void:
	var gs: Node = _tree().root.get_node_or_null("GameState")
	if gs != null:
		gs.call("consume_pending_spawn")
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_world)
	await _tree().process_frame
	# Deux vidages de file : le bâtisseur de garnisons, puis la libération.
	for _i: int in range(3):
		await _tree().physics_frame
		await _tree().process_frame


func _coffre() -> Node3D:
	if _world == null:
		return null
	var vise: String = String((_donnees().get("recompense", {}) as Dictionary)
		.get("coffre_id", ""))
	for n: Node in _world.find_children("*", "Chest", true, false):
		if String(n.get("chest_id")) == vise:
			return n as Node3D
	return null


func _espace() -> PhysicsDirectSpaceState3D:
	return _world.get_world_3d().direct_space_state


## Hauteur du décor sous un point, ou NAN si le rayon ne rencontre rien.
## `exclure` sort le coffre lui-même du calcul : sa propre caisse est sur la
## couche 1 et masquerait le sol qui la porte.
func _sol_sous(x: float, y_depart: float, z: float,
		exclure: Array[RID]) -> float:
	var requete: PhysicsRayQueryParameters3D = \
		PhysicsRayQueryParameters3D.create(
			Vector3(x, y_depart, z), Vector3(x, y_depart - 30.0, z),
			COUCHE_DECOR, exclure)
	var touche: Dictionary = _espace().intersect_ray(requete)
	if touche.is_empty():
		return NAN
	return (touche["position"] as Vector3).y


# --------------------------------------------------------------------------
# 1 — le coffre est POSÉ, ni enterré ni flottant
# --------------------------------------------------------------------------
## La caisse du coffre (`BoxShape3D` 1,0 × 0,7 × 0,7, translatée de +0,35 en Y)
## a son plancher EXACTEMENT à l'origine du nœud. « Posé » se dit donc sans
## approximation : l'origine doit coïncider avec le sol.
func test_le_coffre_repose_sur_le_sol_du_camp() -> void:
	remember_saves()
	remember_root()
	_semer_libere()
	await _monter()

	var coffre: Node3D = _coffre()
	check_not_null(coffre, "préalable : le camp libéré a bien posé sa récompense")
	if coffre != null:
		var corps: CollisionObject3D = coffre as CollisionObject3D
		var exclure: Array[RID] = []
		if corps != null:
			exclure.append(corps.get_rid())
		var p: Vector3 = coffre.global_position
		var sol: float = _sol_sous(p.x, p.y + 6.0, p.z, exclure)
		check(not is_nan(sol),
			"il y a du décor sous le coffre — un rayon de 6 m au-dessus de "
			+ "(%.1f, %.1f) doit rencontrer un sol" % [p.x, p.z])
		if not is_nan(sol):
			# 0,25 m : une marche du kit de camp, pas une falaise. Au-delà,
			# le coffre flotte ou s'enterre visiblement.
			check(absf(p.y - sol) <= 0.25,
				"C2 — le coffre REPOSE sur le sol : origine y = %.3f, sol "
				% p.y + "mesuré à %.3f, écart %.3f m (toléré 0,25)"
				% [sol, absf(p.y - sol)])

	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# 2 — il existe une station d'où le joueur peut l'ouvrir
# --------------------------------------------------------------------------
func test_un_joueur_peut_se_tenir_devant_le_coffre_et_le_voir() -> void:
	remember_saves()
	remember_root()
	_semer_libere()
	await _monter()

	var coffre: Node3D = _coffre()
	check_not_null(coffre, "préalable : la récompense est posée")
	if coffre == null:
		await _demonter()
		restore_saves()
		return

	var corps: CollisionObject3D = coffre as CollisionObject3D
	var exclure: Array[RID] = []
	if corps != null:
		exclure.append(corps.get_rid())
	var centre: Vector3 = coffre.global_position

	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = RAYON_JOUEUR
	capsule.height = HAUTEUR_JOUEUR

	var avec_sol: int = 0
	var libres: int = 0
	var ouvrables: int = 0
	var distances: Array[float] = []

	for i: int in range(STATIONS):
		var angle: float = TAU * float(i) / float(STATIONS)
		var x: float = centre.x + RAYON_ANNEAU * cos(angle)
		var z: float = centre.z + RAYON_ANNEAU * sin(angle)
		var sol: float = _sol_sous(x, centre.y + 6.0, z, exclure)
		if is_nan(sol):
			continue
		avec_sol += 1
		# Une station à 2 m plus haut ou plus bas que le coffre n'est pas une
		# station : c'est un toit ou un fossé.
		if absf(sol - centre.y) > 2.0:
			continue

		# Le corps du joueur tient-il debout ici ? Centre de la capsule à
		# mi-hauteur, plus une marge d'un centimètre pour ne pas compter le
		# contact rasant avec le sol comme une pénétration.
		var forme: PhysicsShapeQueryParameters3D = \
			PhysicsShapeQueryParameters3D.new()
		forme.shape = capsule
		forme.transform = Transform3D(Basis(),
			Vector3(x, sol + HAUTEUR_JOUEUR * 0.5 + 0.01, z))
		forme.collision_mask = COUCHE_DECOR
		forme.exclude = exclure
		if not _espace().intersect_shape(forme, 1).is_empty():
			continue
		libres += 1

		# La ligne de vue du joueur, celle-là même que `_has_interact_los()`
		# tire : torse → coffre + 0,5.
		var vue: PhysicsRayQueryParameters3D = \
			PhysicsRayQueryParameters3D.create(
				Vector3(x, sol + HAUTEUR_TORSE, z),
				centre + Vector3.UP * HAUTEUR_CIBLE, COUCHE_DECOR, exclure)
		if not _espace().intersect_ray(vue).is_empty():
			continue
		ouvrables += 1
		distances.append(Vector2(x - centre.x, z - centre.z).length())

	# NON VACUITÉ. Si l'anneau ne trouvait aucun sol, les trois compteurs
	# seraient à zéro et l'assertion finale rougirait pour la mauvaise raison :
	# on mesurerait un trou dans le monde, pas l'accès au coffre.
	check(avec_sol >= STATIONS / 2,
		"préalable : l'anneau de %d stations trouve du sol sous au moins la "
		% STATIONS + "moitié d'entre elles — mesuré %d" % avec_sol)

	check(ouvrables > 0,
		"C2 — au moins une station permet d'ouvrir le coffre : %d stations "
		% STATIONS + "essayées, %d avec sol, %d où le corps du joueur tient "
		% [avec_sol, libres] + "debout, %d avec ligne de vue" % ouvrables)

	for d: float in distances:
		check(d <= PORTEE_INTERACTION,
			"la station retenue est à %.2f m, dans la portée de %.1f m du "
			% [d, PORTEE_INTERACTION] + "joueur")

	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# 3 — le coffre est DANS la région du camp, pas à côté
# --------------------------------------------------------------------------
## Le layout est GELÉ et donne les bornes de `r05_terrasse_du_camp`. Le
## littéral de position vit ailleurs, dans un fichier NON gelé : rien
## n'empêchait les deux de diverger. Ce cas les rapproche.
func test_la_position_de_la_recompense_est_dans_la_region_du_camp() -> void:
	var brut: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/world_v2/world_v2_layout.json"))
	check(brut is Dictionary, "le layout gelé se lit")
	if not (brut is Dictionary):
		return

	# `bounds` est une LISTE de boîtes, pas une boîte : une région peut en
	# porter plusieurs. Vérifié dans le layout avant d'écrire ce cas — le lire
	# comme un Dictionary aurait rendu ce test rouge pour la mauvaise raison,
	# ce qui est exactement la façon dont un contrat perd sa crédibilité.
	var boites: Array = []
	for entree: Variant in ((brut as Dictionary).get("regions", []) as Array):
		var r: Dictionary = entree as Dictionary
		if String(r.get("id", "")).begins_with("r05"):
			boites = r.get("bounds", []) as Array
			break
	check(not boites.is_empty(),
		"préalable NON VACUITÉ : la région r05 existe dans le layout et porte "
		+ "au moins une boîte — sans elle, la comparaison serait vide "
		+ "contre vide")
	if boites.is_empty():
		return

	var pos: Array = ((_donnees().get("recompense", {}) as Dictionary)
		.get("position", []) as Array)
	check_equal(pos.size(), 3, "la position de la récompense est un triplet")
	if pos.size() != 3:
		return

	var x: float = float(pos[0])
	var z: float = float(pos[2])
	var dedans: bool = false
	var vues: Array[String] = []
	for entree: Variant in boites:
		var b: Dictionary = entree as Dictionary
		var xs: Array = b.get("x", []) as Array
		var zs: Array = b.get("z", []) as Array
		if xs.size() != 2 or zs.size() != 2:
			continue
		vues.append("x[%.0f,%.0f] z[%.0f,%.0f]"
			% [float(xs[0]), float(xs[1]), float(zs[0]), float(zs[1])])
		if x >= float(xs[0]) and x <= float(xs[1]) \
				and z >= float(zs[0]) and z <= float(zs[1]):
			dedans = true

	check(not vues.is_empty(),
		"préalable : au moins une boîte de r05 est lisible")
	check(dedans,
		"la récompense (x = %.1f, z = %.1f) tombe dans le camp — boîtes "
		% [x, z] + "de r05 examinées : %s" % [vues])


func _demonter() -> void:
	_world = null
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())
