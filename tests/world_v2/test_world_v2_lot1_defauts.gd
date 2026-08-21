## V2.3-B LOT 1 — LE FILET DES HUIT DÉFAUTS NOMMÉS D'AVANCE.
##
## Le §4 de `docs/V2_3_B_LOT1_CONTRAT.md` nomme huit familles de défaut AVANT
## qu'un seul lieu n'existe, « pour que le contrôle négatif ait quelque chose à
## viser ». Ce fichier est ce contrôle. Un test par famille, D1 à D8.
##
## ÉCRIT ROUGE D'ABORD (2026-08-21). Au moment de son écriture, AUCUN des six
## sujets du lot 1 n'est construit : le registre de `WorldV2PlacesBuilder` en
## compte neuf, tous du lot pilote. Chaque test nomme donc l'absence au lieu de
## verdir sur zéro sujet — c'est la facture de `test_world_v2_places_contract.gd`
## et ce n'est pas un détail : un filet qui itère sur une liste vide est vert,
## silencieux, et parfaitement inutile.
##
## ISS-018 EST LA RAISON D'ÊTRE DE CE FICHIER. Les créatures s'affichaient en
## pièces détachées avec TOUS les tests verts, parce qu'ils mesuraient la boîte
## englobante d'un maillage skinné — la pose de liaison, pas ce que le moteur
## dessine. D'où trois règles suivies ici sans exception :
##
##   1. on lit la SCÈNE MONTÉE, jamais le code qui prétend la produire ;
##   2. on ne mesure jamais une propriété qui n'est pas celle qu'on garantit —
##      les `CollisionShape3D` et non les `StaticBody3D` pour le budget de
##      collision, les `VisualInstance3D` et non les `MeshInstance3D` pour
##      l'emprise (un `MultiMeshInstance3D` échappe au second, et le champ de
##      fleurs EST ce cas) ;
##   3. chaque seuil est un LITTÉRAL recopié du contrat, jamais lu depuis
##      l'objet qu'il surveille (`tests/CLAUDE.md`, « l'auto-comparaison »).
##
## LE PIÈGE DE NOMMAGE, vérifié dans le code et non dans la prose. Deux
## constantes s'appellent `ROUTE_CLEAR_M` : **1,2 m** dans
## `test_world_v2_places_contract.gd`, qui est le seuil d'un LIEU, et **2,3 m**
## dans `world_v2_vegetation_builder.gd`, qui est l'exclusion VÉGÉTALE du
## domaine gelé V2.2. Le §4 de `WORLD_V2_POI_CONTRACTS.md` annonce en prose
## « routes 2,3 m, gués 12 m, checkpoints 4,5 m, caméras 6 m » : ce sont les
## valeurs de la végétation. Ce fichier emploie celles des LIEUX.
##
## Le plan complet — ce que chaque contrôle mesure, et le sabotage qui prouve
## qu'il sait rougir — est dans `docs/V2_3_B_LOT1_CONTROLES.md`, committé AVANT
## la première mesure. Le sabotage s'exécute par `tools/gate_negatif_lot1.sh`.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"

## Les SIX sujets du lot 1 (contrat §1). Jamais moins : un lieu absent est un
## écart nommé, pas un test sauté.
const LOT1: Array[StringName] = [
	&"valley.poi.watchtower_ruin.01",
	&"valley.poi.overlook_summit.01",
	&"valley.poi.turquoise_spring.01",
	&"valley.poi.forest_shrine.01",
	&"valley.poi.barrow_cemetery.01",
	&"valley.poi.flower_field.01",
]

## Le corpus ACCEPTÉ au moment de l'écriture — les neuf lieux du lot pilote
## validés par le lead. Il sert de référence de comparaison (D3) et de
## calibration (D1a). Il n'est jamais jugé par ce fichier.
const CORPUS_ACCEPTE: Array[StringName] = [
	&"camp",
	&"valley.poi.riverside_village.01",
	&"valley.poi.abandoned_farm.01",
	&"valley.poi.stone_bridge.01",
	&"valley.poi.waterfall_cave.01",
	&"valley.poi.thunderstruck_tree.01",
	&"valley.poi.ember_raider_camps.01",
	&"valley.poi.conductive_basin.01",
	&"pylon",
]

## Famille de budget par sujet (contrat §2.7 + `WORLD_V2_POI_CONTRACTS` §4).
## Littéral : la famille d'un lieu est une décision de contrat, pas une
## propriété qu'on lit sur l'objet construit.
const FAMILLE: Dictionary = {
	&"valley.poi.watchtower_ruin.01": "ruine",
	&"valley.poi.forest_shrine.01": "vestige",
	&"valley.poi.barrow_cemetery.01": "vestige",
	&"valley.poi.overlook_summit.01": "micro",
	&"valley.poi.turquoise_spring.01": "micro",
	&"valley.poi.flower_field.01": "micro",
}
## [modules, nœuds visuels, collisions] — plafonds, jamais des objectifs.
const BUDGET: Dictionary = {
	"micro": [12, 30, 6],
	"ruine": [40, 80, 20],
	"vestige": [40, 80, 20],
}

## -- Seuils des LIEUX, recopiés de test_world_v2_places_contract.gd ----------
const SUPPORT_TOLERANCE_M: float = 0.65
const ROOT_GROUND_TOLERANCE_M: float = 1.0
const SITE_XZ_TOLERANCE_M: float = 0.5
const ROUTE_CLEAR_M: float = 1.2
## Fraction du trajet caméra → cible qui doit rester libre (masque 1).
const CLEAR_SIGHT_FRACTION: float = 0.6

## -- D4 : les bandes creusées de l'eau ---------------------------------------
## Demi-largeur TOTALE de la bande que l'hydrologie creuse dans le terrain,
## somme du lit et de la berge (`world_v2_heightmap.gd`) :
##   principal : RIVER_BED_HALF_W 3,0 + RIVER_BANK_W 6,5 = 9,5
##   affluent  : TRIB_BED_HALF_W 1,8 + TRIB_BANK_W  4,5 = 6,3
## Recopiées en littéral : un test qui lirait `WorldV2Heightmap.RIVER_BANK_W`
## suivrait un élargissement de berge au lieu de le dénoncer.
const EAU_PRINCIPAL_M: float = 9.5
const EAU_AFFLUENT_M: float = 6.3
const EAU_LAC_MARGE_M: float = 2.0
## Le LIT seul — un collider dans le lit est dans l'eau ; un collider sur la
## berge peut être une margelle légitime (la Source aux reflets est un
## belvédère « au bord de son bassin », contrat §1). La distinction est faite
## exprès pour que ce filet n'interdise pas ce que le contrat demande.
const LIT_PRINCIPAL_M: float = 3.0
const LIT_AFFLUENT_M: float = 1.8

## -- D1 : l'assemblage de primitives -----------------------------------------
## Soudage par position, 0,1 mm. Valeur de `tools/mesure_boititude.py` depuis sa
## correction du 2026-08-20 : à 10 µm, un coin déplacé de 12 µm se dédoublait et
## faisait tomber la boîtitude sans qu'un pixel bouge — un VERT ACCIDENTEL, qui
## est le mode de panne le plus dangereux d'un plafond.
const SOUDAGE_M: float = 1.0e-4
## Plafond de boîtitude `hexa` : 12 triangles ET 8 sommets soudés. ACQUIS en
## R2B.3 (ISS-060) sur le même défaut, recopié tel quel. Un plafond est un
## plafond, pas une cible : le témoin accepté `SM_Dungeon_RubbleLarge` vaut
## 0,00 %.
const HEXA_PLAFOND_PCT: float = 25.0
## Sous ce compte de triangles RUNTIME cumulés sur un lieu, un pourcentage ne
## veut rien dire : deux pavés au plus, donc pas encore un empilement. Au-delà,
## la boîtitude agrégée est jugée.
const TRIS_MIN_POUR_JUGER: int = 24

## Plafond de part d'aire RUNTIME, à CALIBRER sur le corpus accepté selon la
## règle du §4 (D1) de `docs/V2_3_B_LOT1_CONTROLES.md` : le maximum observé sur
## les neuf lieux déjà validés.
##
## `-1.0` = NON CALIBRÉ, et le test ROUGIT en le disant. C'est délibéré : un
## plafond non calibré ne doit pas passer pour un plafond franchi, et un chiffre
## inventé ici serait exactement le mensonge que ce fichier existe pour empêcher.
## Renseigner APRÈS la calibration, avec le journal daté en commentaire.
const AIRE_RUNTIME_PLAFOND_PCT: float = -1.0

## -- D6 : le contenu canonique, recopié du contrat §1 -------------------------
## Recopié de la table du contrat, JAMAIS lu depuis `DiscoveryRewards.PLAN` :
## si la table et le contrat divergent, c'est le contrat qui gagne, et ce test
## est le seul endroit où cette divergence se voit.
const RECOMPENSE_ATTENDUE: Dictionary = {
	&"valley.poi.watchtower_ruin.01": {"kind": "arrows", "id": "15"},
	&"valley.poi.overlook_summit.01": {"kind": "weapon", "id": "simple_bow"},
	&"valley.poi.turquoise_spring.01": {"kind": "ingredient", "id": "heal_fruit"},
	&"valley.poi.forest_shrine.01": {"kind": "ingredient", "id": "rare_spice"},
	&"valley.poi.barrow_cemetery.01": {"kind": "weapon", "id": "heavy_axe"},
	&"valley.poi.flower_field.01": {"kind": "ingredient", "id": "stamina_herb"},
}

## -- D3 : le verdict du détecteur d'image ------------------------------------
## Le détecteur vit hors moteur (`tools/lot1_repetition.py`) parce qu'il lit des
## PNG. Son verdict est rendu LIANT ici : fichier absent ou verdict autre que
## PASS ⇒ rouge. Sans ce raccord, un détecteur qui n'aurait jamais tourné
## laisserait la suite verte.
const VERDICT_D3: String = \
	"res://evidence/world_v2/v2_3_b/lot1/controles/verdict_repetition.json"

## -- D8 : le manifeste du gel ------------------------------------------------
const MANIFESTE_GEL: String = "res://docs/contrats/gel_v2_3_b.sha256"

var _world: Node3D = null
var _heightmap: WorldV2Heightmap = null


## ---------------------------------------------------------------------------
## D0 — RECENSEMENT : sans lui, les huit contrôles passeraient à vide.
## ---------------------------------------------------------------------------
func test_d0_les_six_sujets_du_lot_1_existent_vraiment() -> void:
	await _monter()
	var absents: Array[String] = []
	for id: StringName in LOT1:
		if not WorldV2PlacesBuilder.REGISTRY.has(id):
			absents.append("%s : ABSENT DU REGISTRE (resté simple marqueur)" % id)
		elif _lieu(id) == null:
			absents.append("%s : enregistré mais ABSENT du monde monté" % id)
	check(absents.is_empty(),
		"D0 recensement — les six sujets du lot 1 sont montés (%d absent(s)) : %s"
		% [absents.size(), _plafonner(absents)])
	# Le corpus de référence doit lui aussi être là, sinon D1a et D3 se
	# calibreraient sur rien (garde-fou R-D3c du plan de contrôles).
	var corpus: int = 0
	for id: StringName in CORPUS_ACCEPTE:
		if _lieu(id) != null:
			corpus += 1
	check(corpus >= 6,
		"D0 recensement — le corpus accepté compte %d sujets montés (≥ 6 exigé "
		% corpus + "pour que max() soit une statistique et non un accident)")
	await _demonter()


## ---------------------------------------------------------------------------
## D1 — ASSEMBLAGE DE PRIMITIVES
## ---------------------------------------------------------------------------
func test_d1_aucun_lieu_ne_lit_comme_un_assemblage_de_primitives() -> void:
	await _monter()
	var faults: Array[String] = []
	var examines: int = 0
	for id: StringName in LOT1:
		var lieu: Node3D = _lieu(id)
		if lieu == null:
			faults.append("%s : ABSENT — rien à mesurer" % id)
			continue
		examines += 1
		var exemptions: Array[String] = _exemptions_runtime(lieu)
		var aire_totale: float = 0.0
		var aire_runtime: float = 0.0
		var tris_runtime: int = 0
		var tris_hexa: int = 0
		for noeud: Node in lieu.find_children("*", "MeshInstance3D", true, false):
			var instance: MeshInstance3D = noeud as MeshInstance3D
			if instance.mesh == null:
				continue
			var aire: float = _aire_monde(instance)
			aire_totale += aire
			var runtime: bool = instance.mesh.resource_path.is_empty()
			if not runtime:
				continue
			if exemptions.has(String(instance.name)):
				continue
			aire_runtime += aire
			# D1b — LE LIANT SANS CALIBRATION : la boîtitude de ce que le lieu
			# construit en runtime. `K.stone_block` déplace les coins d'une
			# boîte ; la TOPOLOGIE reste 12 triangles / 8 sommets, donc `hexa`
			# le voit là où « ça ressemble à une boîte » ne le verrait pas.
			#
			# AGRÉGÉ SUR LE LIEU, et non jugé maillage par maillage. Un pavé
			# isolé de 12 triangles resterait sous n'importe quel plancher de
			# significativité ; c'est L'EMPILEMENT qui est le défaut — la ferme
			# et l'arbre rejetés en R2B étaient « un empilement de blocs ».
			# Douze pavés jugés séparément passent ; agrégés, ils rendent
			# 100 %.
			var forme: Dictionary = _boititude(instance.mesh)
			tris_runtime += int(forme["tris"])
			tris_hexa += int(forme["hexa_tris"])
		if tris_runtime >= TRIS_MIN_POUR_JUGER:
			var pct_hexa: float = 100.0 * float(tris_hexa) / float(tris_runtime)
			if pct_hexa > HEXA_PLAFOND_PCT:
				faults.append(("D1 %s : boîtitude hexa %.1f %% du runtime "
					+ "> %.1f %% (%d/%d triangles) — un empilement de blocs")
					% [id, pct_hexa, HEXA_PLAFOND_PCT, tris_hexa, tris_runtime])
		# D1a — la part d'aire portée par du runtime. Les `MultiMeshInstance3D`
		# sont HORS PÉRIMÈTRE, et c'est dit plutôt que tu : un semis instancié
		# pose une question de densité (D7), pas d'assemblage de primitives, et
		# sa géométrie source reste jugée par D1b comme n'importe quelle autre.
		if aire_totale <= 0.0:
			faults.append("D1 %s : aucune aire de maillage — lieu vide ?" % id)
			continue
		var part: float = 100.0 * aire_runtime / aire_totale
		if AIRE_RUNTIME_PLAFOND_PCT < 0.0:
			faults.append(("D1 %s : aire runtime %.1f %% — PLAFOND NON CALIBRÉ. "
				+ "Lancer tools/godot/sonde_budget_lot1.gd --calibrer sur le "
				+ "corpus accepté, puis inscrire AIRE_RUNTIME_PLAFOND_PCT avec "
				+ "son journal daté.") % [id, part])
		elif part > AIRE_RUNTIME_PLAFOND_PCT:
			faults.append("D1 %s : aire runtime %.1f %% > %.1f %% (plafond calibré)"
				% [id, part, AIRE_RUNTIME_PLAFOND_PCT])
	check(examines == LOT1.size(),
		"D1 — %d sujet(s) réellement inspecté(s) sur %d (un contrôle qui "
		% [examines, LOT1.size()] + "n'inspecte rien est vert pour rien)")
	check(faults.is_empty(),
		"D1 assemblage de primitives (%d écart(s)) : %s"
		% [faults.size(), _plafonner(faults)])
	await _demonter()


## ---------------------------------------------------------------------------
## D2 — BÂTI FLOTTANT OU ENTERRÉ
## ---------------------------------------------------------------------------
func test_d2_rien_ne_flotte_et_rien_n_est_enterre() -> void:
	await _monter()
	var faults: Array[String] = []
	var examines: int = 0
	for id: StringName in LOT1:
		var lieu: Node3D = _lieu(id)
		if lieu == null:
			faults.append("%s : ABSENT — rien à sonder" % id)
			continue
		examines += 1
		# a. La racine est ancrée au sol gelé.
		var sol_racine: float = _heightmap.height_at(
			lieu.global_position.x, lieu.global_position.z)
		if absf(lieu.global_position.y - sol_racine) > ROOT_GROUND_TOLERANCE_M:
			faults.append("D2 %s : racine à y=%.2f, sol gelé à %.2f"
				% [id, lieu.global_position.y, sol_racine])
		# b. Chaque appui DÉCLARÉ touche le sol gelé.
		var appuis: PackedVector3Array = _appuis(lieu)
		if appuis.is_empty():
			faults.append("D2 %s : AUCUN appui déclaré (declare_support)" % id)
			continue
		for local: Vector3 in appuis:
			var monde: Vector3 = lieu.to_global(local)
			var sol: float = _heightmap.height_at(monde.x, monde.z)
			if absf(monde.y - sol) > SUPPORT_TOLERANCE_M:
				faults.append("D2 %s : appui (%.1f, %.1f) à %.2f m du sol (tol %.2f)"
					% [id, monde.x, monde.z, monde.y - sol, SUPPORT_TOLERANCE_M])
		# c. COUVERTURE des appuis — le trou du filet existant. Un lieu qui
		# déclare un seul appui au centre passe le point (b) et laisse tout le
		# reste flotter. Pour tout axe dont l'emprise dépasse 6 m, on exige un
		# appui dans le tiers bas ET un dans le tiers haut. Aucun seuil à
		# débattre : c'est une partition en trois.
		#
		# L'emprise se lit sur les `VisualInstance3D` et non sur les
		# `MeshInstance3D` : un `MultiMeshInstance3D` — la forme attendue d'un
		# champ de fleurs — échappe entièrement aux seconds, et le filet
		# existant conclurait « aucun maillage visuel » sur le lieu le plus
		# peuplé du lot.
		var emprise: AABB = _emprise_visuelle(lieu)
		if emprise.size == Vector3.ZERO:
			faults.append("D2 %s : aucune instance visuelle (VisualInstance3D)" % id)
			continue
		faults.append_array(_couverture_appuis(id, lieu, appuis, emprise))
	check(examines == LOT1.size(),
		"D2 — %d sujet(s) réellement sondé(s) sur %d" % [examines, LOT1.size()])
	check(faults.is_empty(),
		"D2 bâti flottant ou enterré (%d écart(s)) : %s"
		% [faults.size(), _plafonner(faults)])
	await _demonter()


## ---------------------------------------------------------------------------
## D3 — RÉPÉTITION (étage structurel ; l'étage image est le détecteur Python)
## ---------------------------------------------------------------------------
func test_d3_aucun_lieu_du_lot_n_en_repete_un_autre() -> void:
	await _monter()
	var faults: Array[String] = []
	var signatures: Dictionary = {}
	var examines: int = 0
	# Le corpus accepté ENTRE EN PREMIER : il donne les signatures de
	# référence, et un lieu du lot qui copie un pilote se signale alors comme
	# copiant CE pilote, pas l'inverse.
	var a_comparer: Array[StringName] = []
	for id: StringName in CORPUS_ACCEPTE:
		a_comparer.append(id)
	for id: StringName in LOT1:
		a_comparer.append(id)
	for id: StringName in a_comparer:
		var du_lot: bool = LOT1.has(id)
		var lieu: Node3D = _lieu(id)
		if lieu == null:
			if du_lot:
				faults.append("%s : ABSENT — pas de signature à comparer" % id)
			continue
		if du_lot:
			examines += 1
		var signature: String = _signature_composition(lieu)
		if signature.is_empty():
			if du_lot:
				faults.append("D3 %s : signature vide (aucun maillage)" % id)
			continue
		if signatures.has(signature):
			var autre: StringName = signatures[signature] as StringName
			# Deux lieux ne peuvent pas porter la MÊME signature. Pas de seuil :
			# identique est identique. C'est la forme la plus grossière de D3 —
			# le copier-coller d'un lieu sur l'autre — et la seule que le
			# moteur puisse trancher sans image.
			if du_lot or LOT1.has(autre):
				faults.append("D3 %s : signature de composition IDENTIQUE à %s"
					% [id, autre])
		else:
			signatures[signature] = id
	check(examines == LOT1.size(),
		"D3 — %d sujet(s) du lot réellement comparé(s) sur %d"
		% [examines, LOT1.size()])
	check(faults.is_empty(),
		"D3 répétition, étage structurel (%d écart(s)) : %s"
		% [faults.size(), _plafonner(faults)])
	# L'étage IMAGE : le verdict du détecteur de silhouettes est LIANT.
	var verdict: Dictionary = _verdict_json(VERDICT_D3)
	check(not verdict.is_empty(),
		"D3 répétition, étage image — verdict ABSENT (%s). Lancer "
		% VERDICT_D3 + "tools/lot1_repetition.py : un détecteur qui n'a jamais "
		+ "tourné laisse la suite verte sans rien prouver.")
	if not verdict.is_empty():
		check(String(verdict.get("regle", "")) == "R-D3",
			"D3 étage image — le verdict cite la règle pré-enregistrée R-D3 "
			+ "(obtenu : « %s »)" % String(verdict.get("regle", "")))
		check(String(verdict.get("verdict", "")) == "PASS",
			"D3 étage image — verdict « %s » : %s"
			% [String(verdict.get("verdict", "?")),
				String(verdict.get("resume", "sans résumé"))])
	await _demonter()


## ---------------------------------------------------------------------------
## D4 — OBSTRUCTION : routes, eau creusée, caméras gelées
## ---------------------------------------------------------------------------
func test_d4_ni_route_ni_eau_ni_camera_ne_sont_obstruees() -> void:
	await _monter()
	var faults: Array[String] = []
	var examines: int = 0
	var layout: Dictionary = WorldV2Layout.load_layout()

	# a. Le SITE lui-même est hors des bandes creusées de l'eau. Le contrat est
	# explicite : « les bandes creusées de l'eau sont interdites à tout site ».
	for id: StringName in LOT1:
		var lieu: Node3D = _lieu(id)
		if lieu == null:
			faults.append("%s : ABSENT — rien à dégager" % id)
			continue
		examines += 1
		var site: Vector2 = Vector2(lieu.global_position.x, lieu.global_position.z)
		var d_main: float = _distance_polyligne(site, _heightmap.river_main_polyline())
		var d_trib: float = _distance_polyligne(site, _heightmap.river_trib_polyline())
		var d_lac: float = site.distance_to(_heightmap.lake_center()) \
			- _heightmap.lake_radius()
		if d_main < EAU_PRINCIPAL_M:
			faults.append("D4 %s : site à %.1f m du cours principal (bande creusée %.1f m)"
				% [id, d_main, EAU_PRINCIPAL_M])
		if d_trib < EAU_AFFLUENT_M:
			faults.append("D4 %s : site à %.1f m de l'affluent (bande creusée %.1f m)"
				% [id, d_trib, EAU_AFFLUENT_M])
		if d_lac < EAU_LAC_MARGE_M:
			faults.append("D4 %s : site à %.1f m du lac (dégagement %.1f m)"
				% [id, d_lac, EAU_LAC_MARGE_M])
		# Le site correspond au layout : un lieu qui a dérivé de son site a
		# aussi dérivé de toutes les exclusions calculées pour ce site.
		var attendu: Vector3 = _site_layout(layout, id)
		if attendu != Vector3.INF:
			if absf(site.x - attendu.x) > SITE_XZ_TOLERANCE_M \
					or absf(site.y - attendu.z) > SITE_XZ_TOLERANCE_M:
				faults.append("D4 %s : posé en (%.1f, %.1f), layout (%.1f, %.1f)"
					% [id, site.x, site.y, attendu.x, attendu.z])

	# b. Aucun collider de lieu du lot dans une route contractuelle, ni dans le
	# LIT d'un cours d'eau. Le lit et non la berge : le contrat demande un
	# belvédère « au bord de son bassin », et un filet qui interdirait la berge
	# rejetterait ce que le contrat exige.
	var empreintes: Array[AABB] = []
	var porteurs: Array[StringName] = []
	for id: StringName in LOT1:
		var lieu: Node3D = _lieu(id)
		if lieu == null:
			continue
		for noeud: Node in lieu.find_children("*", "CollisionShape3D", true, false):
			var boite: AABB = _emprise_forme(noeud as CollisionShape3D)
			if boite.size == Vector3.ZERO:
				continue
			empreintes.append(boite)
			porteurs.append(id)
	var bloquages: int = 0
	for route: Node in _world.get_tree().get_nodes_in_group(&"world_v2_routes"):
		var jalons: Array = route.get_meta(&"waypoints_xz", []) as Array
		for i: int in range(jalons.size() - 1):
			var a: Vector2 = Vector2(float((jalons[i] as Array)[0]),
				float((jalons[i] as Array)[1]))
			var b: Vector2 = Vector2(float((jalons[i + 1] as Array)[0]),
				float((jalons[i + 1] as Array)[1]))
			var pas: int = maxi(1, int(a.distance_to(b)))
			for s: int in range(pas + 1):
				var p: Vector2 = a.lerp(b, float(s) / float(pas))
				for f: int in range(empreintes.size()):
					if not _dans_marge(p, empreintes[f], ROUTE_CLEAR_M):
						continue
					bloquages += 1
					if bloquages <= 3:
						faults.append("D4 %s bloque %s vers (%.0f, %.0f) — dégagement %.1f m"
							% [porteurs[f], route.name, p.x, p.y, ROUTE_CLEAR_M])
	if bloquages > 3:
		faults.append("D4 … %d empiétement(s) de route au total" % bloquages)
	for f: int in range(empreintes.size()):
		var centre: Vector2 = Vector2(empreintes[f].get_center().x,
			empreintes[f].get_center().z)
		var rayon: float = maxf(empreintes[f].size.x, empreintes[f].size.z) * 0.5
		if _distance_polyligne(centre, _heightmap.river_main_polyline()) - rayon \
				< LIT_PRINCIPAL_M:
			faults.append("D4 %s : collider DANS LE LIT du cours principal" % porteurs[f])
		if _distance_polyligne(centre, _heightmap.river_trib_polyline()) - rayon \
				< LIT_AFFLUENT_M:
			faults.append("D4 %s : collider DANS LE LIT de l'affluent" % porteurs[f])

	# c. Les six caméras GELÉES voient encore leur cible. La faute nomme le
	# `place_id` fautif et pas seulement le nœud : la cause doit être dans le
	# message, sinon on la cherche une heure.
	var espace: PhysicsDirectSpaceState3D = _world.get_world_3d().direct_space_state
	var cameras: Array[Node] = _world.get_tree().get_nodes_in_group(
		&"world_v2_capture_cameras")
	check(cameras.size() == 6,
		"D4 — six caméras gelées présentes (obtenu %d)" % cameras.size())
	for noeud: Node in cameras:
		var camera: Camera3D = noeud as Camera3D
		var cible: Vector3 = camera.get_meta(&"target", Vector3.ZERO) as Vector3
		if cible == Vector3.ZERO:
			continue
		var fin: Vector3 = camera.global_position.lerp(cible, CLEAR_SIGHT_FRACTION)
		var requete: PhysicsRayQueryParameters3D = \
			PhysicsRayQueryParameters3D.create(camera.global_position, fin, 1)
		var touche: Dictionary = espace.intersect_ray(requete)
		if touche.is_empty():
			continue
		var fautif: StringName = _lieu_proprietaire(touche["collider"] as Node)
		if not LOT1.has(fautif):
			continue
		var au: Vector3 = touche["position"] as Vector3
		faults.append("D4 %s bouche la caméra %s à %.0f m (en %.0f, %.0f)"
			% [fautif, camera.name, camera.global_position.distance_to(au),
				au.x, au.z])
	check(examines == LOT1.size(),
		"D4 — %d sujet(s) réellement dégagé(s) sur %d" % [examines, LOT1.size()])
	check(faults.is_empty(),
		"D4 obstruction (%d écart(s)) : %s" % [faults.size(), _plafonner(faults)])
	await _demonter()


## ---------------------------------------------------------------------------
## D5 — PLACEMENT CODÉ EN DUR (pas de monde : on lit le TEXTE)
## ---------------------------------------------------------------------------
func test_d5_aucune_position_de_site_n_est_codee_en_dur() -> void:
	var layout: Dictionary = WorldV2Layout.load_layout()
	var faults: Array[String] = []
	var examines: int = 0
	for id: StringName in LOT1:
		if not WorldV2PlacesBuilder.REGISTRY.has(id):
			faults.append("%s : ABSENT DU REGISTRE — aucun fichier à fouiller" % id)
			continue
		examines += 1
		var site: Vector3 = _site_layout(layout, id)
		if site == Vector3.INF:
			faults.append("D5 %s : aucun site dans le layout" % id)
			continue
		var scene_path: String = String(WorldV2PlacesBuilder.REGISTRY[id])
		var chemins: Array[String] = [scene_path]
		var script_path: String = _script_de_scene(scene_path)
		if not script_path.is_empty():
			chemins.append(script_path)
		for chemin: String in chemins:
			var texte: String = FileAccess.get_file_as_string(chemin)
			if texte.is_empty():
				faults.append("D5 %s : fichier illisible — %s" % [id, chemin])
				continue
			# On EXIGE LES DEUX coordonnées dans le même fichier avant de
			# crier. Un lieu peut légitimement porter `40.0` comme rayon ;
			# porter `-160` ET `40` par hasard, non. La probabilité d'un faux
			# positif tombe au produit de deux coïncidences.
			var a_x: bool = _porte_litteral(texte, site.x)
			var a_z: bool = _porte_litteral(texte, site.z)
			if a_x and a_z:
				faults.append(("D5 %s : littéral de site (%.0f, %.0f) TROUVÉ dans "
					+ "%s — la position vient du layout, pas du fichier de lieu")
					% [id, site.x, site.z, chemin.get_file()])
		# `default_place_id()` doit rendre une constante, jamais une position :
		# c'est l'identité, et la base la documente ainsi.
		if not script_path.is_empty():
			var source: String = FileAccess.get_file_as_string(script_path)
			if source.contains("func default_place_id") \
					and not source.contains("return &\"%s\"" % id):
				faults.append("D5 %s : default_place_id() ne rend pas la constante &\"%s\""
					% [id, id])
	check(examines == LOT1.size(),
		"D5 — %d sujet(s) réellement fouillé(s) sur %d" % [examines, LOT1.size()])
	check(faults.is_empty(),
		"D5 placement codé en dur (%d écart(s)) : %s"
		% [faults.size(), _plafonner(faults)])


## ---------------------------------------------------------------------------
## D6 — RÉCOMPENSE NON RACCORDÉE
## ---------------------------------------------------------------------------
func test_d6_chaque_recompense_canonique_est_raccordee() -> void:
	await _monter()
	var faults: Array[String] = []
	var examines: int = 0
	var places_root: Node = _world.get_node_or_null("Places")
	var journal: DiscoveryLog = null
	if places_root != null:
		var meta: Variant = places_root.get_meta(&"discovery_log", null)
		if meta is DiscoveryLog:
			journal = meta as DiscoveryLog
	check(journal != null,
		"D6 — le journal de découverte existe sous Places (meta discovery_log)")
	for id: StringName in LOT1:
		var lieu: Node3D = _lieu(id)
		if lieu == null:
			faults.append("%s : ABSENT — aucune récompense à raccorder" % id)
			continue
		examines += 1
		# a. L'ID canonique est DANS le journal — le révélateur nommé par le
		# contrat §4. Un POI posé mais non enregistré est un lieu qu'aucune
		# découverte ne verra jamais.
		var pois: Array[Node] = lieu.find_children("*", "PointOfInterest", true, false)
		if pois.is_empty():
			faults.append("D6 %s : aucun PointOfInterest" % id)
		else:
			var poi: PointOfInterest = pois[0] as PointOfInterest
			if poi.poi_id != id:
				faults.append("D6 %s : PointOfInterest.poi_id = « %s »"
					% [id, poi.poi_id])
			if not poi.is_bound():
				faults.append("D6 %s : PointOfInterest non lié au journal" % id)
			if journal != null and not journal.is_registered(id):
				faults.append("D6 %s : ID canonique ABSENT du journal de découverte" % id)
		# b. L'ancre existe, et porte un interactable.
		var ancres: Array[Node] = lieu.find_children("AncrageRecompense",
			"RewardAnchor", true, false)
		if ancres.is_empty():
			faults.append("D6 %s : aucune AncrageRecompense" % id)
			continue
		var attendu: Dictionary = RECOMPENSE_ATTENDUE[id] as Dictionary
		var trouve: String = ""
		var interactable: bool = false
		for ancre: Node in ancres:
			for enfant: Node in ancre.get_children():
				if enfant.is_in_group(&"interactable"):
					interactable = true
				var vu: String = _contenu_recompense(enfant)
				if not vu.is_empty():
					trouve = vu
		var veut: String = "%s:%s" % [attendu["kind"], attendu["id"]]
		if trouve != veut:
			faults.append(("D6 %s : récompense « %s », le contrat §1 dit « %s »")
				% [id, trouve if trouve != "" else "aucune", veut])
		if not interactable:
			faults.append("D6 %s : la récompense n'est pas dans le groupe interactable"
				% id)
	check(examines == LOT1.size(),
		"D6 — %d sujet(s) réellement vérifié(s) sur %d" % [examines, LOT1.size()])
	check(faults.is_empty(),
		"D6 récompense non raccordée (%d écart(s)) : %s"
		% [faults.size(), _plafonner(faults)])
	await _demonter()


## ---------------------------------------------------------------------------
## D7 — BUDGET DÉPASSÉ EN SILENCE
## ---------------------------------------------------------------------------
func test_d7_aucun_budget_de_lieu_n_est_depasse() -> void:
	await _monter()
	var faults: Array[String] = []
	var examines: int = 0
	for id: StringName in LOT1:
		var lieu: Node3D = _lieu(id)
		if lieu == null:
			faults.append("%s : ABSENT — aucun budget à compter" % id)
			continue
		examines += 1
		var famille: String = String(FAMILLE[id])
		var plafonds: Array = BUDGET[famille] as Array
		var compte: Dictionary = _compter_budget(lieu)
		if int(compte["modules"]) > int(plafonds[0]):
			faults.append("D7 %s (%s) : budget modules %d > %d"
				% [id, famille, int(compte["modules"]), int(plafonds[0])])
		if int(compte["visuels"]) > int(plafonds[1]):
			faults.append("D7 %s (%s) : budget nœuds visuels %d > %d"
				% [id, famille, int(compte["visuels"]), int(plafonds[1])])
		if int(compte["collisions"]) > int(plafonds[2]):
			faults.append("D7 %s (%s) : budget collisions %d > %d"
				% [id, famille, int(compte["collisions"]), int(plafonds[2])])
	check(examines == LOT1.size(),
		"D7 — %d sujet(s) réellement compté(s) sur %d" % [examines, LOT1.size()])
	check(faults.is_empty(),
		"D7 budget dépassé (%d écart(s)) : %s" % [faults.size(), _plafonner(faults)])
	await _demonter()


## ---------------------------------------------------------------------------
## D8 — RÉGRESSION SUR LE GEL (seconde implémentation, indépendante du shell)
## ---------------------------------------------------------------------------
func test_d8_aucun_element_gele_n_a_bouge() -> void:
	var texte: String = FileAccess.get_file_as_string(MANIFESTE_GEL)
	check(not texte.is_empty(),
		"D8 gel — le manifeste %s est lisible" % MANIFESTE_GEL)
	var lignes: PackedStringArray = texte.split("\n", false)
	var faults: Array[String] = []
	var verifies: int = 0
	for ligne: String in lignes:
		var nette: String = ligne.strip_edges()
		if nette.is_empty() or nette.begins_with("#"):
			continue
		# Format `sha256sum` : « <hash>  <chemin> », deux espaces.
		var coupe: int = nette.find("  ")
		if coupe < 0:
			faults.append("D8 gel : ligne de manifeste illisible — « %s »" % nette)
			continue
		var attendu: String = nette.substr(0, coupe).strip_edges()
		var chemin: String = nette.substr(coupe + 2).strip_edges()
		var res: String = "res://" + chemin
		if not FileAccess.file_exists(res):
			faults.append("D8 gel : fichier gelé DISPARU — %s" % chemin)
			continue
		verifies += 1
		var obtenu: String = FileAccess.get_sha256(res)
		if obtenu != attendu:
			faults.append("D8 gel : %s a BOUGÉ (sha256 %s… au lieu de %s…)"
				% [chemin, obtenu.substr(0, 12), attendu.substr(0, 12)])
	# Un manifeste vide serait vert et muet. La directive de clôture R2B.3.1 §4
	# gèle V2.2, quatre golden masters, les lieux du lot pilote et les
	# géométries R2B.3 : trente entrées est un plancher très en dessous.
	check(verifies >= 30,
		"D8 gel — %d fichier(s) gelé(s) réellement recalculé(s) (≥ 30 attendu : "
		% verifies + "un manifeste vidé rendrait ce contrôle vert et muet)")
	check(faults.is_empty(),
		"D8 régression sur le gel (%d écart(s)) : %s"
		% [faults.size(), _plafonner(faults)])


## ---------------------------------------------------------------------------
## TÉMOINS ANALYTIQUES — les instruments de ce fichier savent-ils voir ?
##
## Les six sujets du lot n'existent pas encore : les contrôles D1 à D7 ne
## peuvent donc PAS être éprouvés sur eux aujourd'hui. Ce qui peut l'être tout
## de suite, c'est l'INSTRUMENT — et c'est ce qui compte le plus, parce qu'un
## instrument aveugle produirait des verts crédibles le jour où les lieux
## arriveront. Même discipline que `tools/mesure_boititude.py --autotest`, qui
## fabrique un cube et EXIGE 100 %.
##
## Ces deux tests sont aussi les gardiens ANTI-ISS-018 de mes propres mesures :
## si quelqu'un « simplifie » un jour le compteur de collisions vers
## `StaticBody3D`, ou l'emprise vers `MeshInstance3D`, ils rougissent.
## ---------------------------------------------------------------------------
func test_temoin_l_instrument_de_boititude_voit_un_pave() -> void:
	var pave: BoxMesh = BoxMesh.new()
	pave.size = Vector3(2.0, 1.0, 3.0)
	var mesure_pave: Dictionary = _boititude(pave)
	# Un `BoxMesh` porte 24 sommets (normales séparées) et 12 triangles. Après
	# soudage PAR POSITION il reste 8 coins : c'est exactement `hexa`. Si ce
	# chiffre n'est pas 100, le soudage ou la connexité est cassé, et TOUT
	# pourcentage rendu par D1 est faux — dans le sens permissif, celui qui
	# laisse passer le défaut.
	check_approx(float(mesure_pave["hexa_pct"]), 100.0, 0.001,
		"témoin — un pavé rend 100 %% de boîtitude (12 tris obtenus : %d)"
		% int(mesure_pave["tris"]))
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radial_segments = 16
	sphere.rings = 8
	var mesure_sphere: Dictionary = _boititude(sphere)
	check(float(mesure_sphere["hexa_pct"]) < 0.001,
		"témoin — une sphère rend 0 %% de boîtitude (obtenu %.3f %% sur %d tris)"
		% [float(mesure_sphere["hexa_pct"]), int(mesure_sphere["tris"])])
	check(int(mesure_sphere["tris"]) > 100,
		"témoin — la sphère porte assez de triangles pour que le 0 %% ait un sens (%d)"
		% int(mesure_sphere["tris"]))


func test_temoin_les_compteurs_voient_ce_qu_ils_pretendent_compter() -> void:
	var boucle: SceneTree = Engine.get_main_loop() as SceneTree
	remember_root()
	var faux_lieu: Node3D = Node3D.new()
	faux_lieu.name = "TemoinLieu"
	# Un semis instancié — la forme attendue d'un champ de fleurs. Un compteur
	# qui regarde `MeshInstance3D` ne le voit PAS et annonce « 0 visuel ».
	var semis: MultiMeshInstance3D = MultiMeshInstance3D.new()
	var multi: MultiMesh = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = BoxMesh.new()
	multi.instance_count = 4
	semis.multimesh = multi
	faux_lieu.add_child(semis)
	# UN corps, TROIS formes. Un compteur qui regarde `StaticBody3D` annonce
	# « 1 collision » là où il y en a trois — et un micro-POI au budget 6
	# passerait avec dix-huit formes.
	var corps: StaticBody3D = StaticBody3D.new()
	faux_lieu.add_child(corps)
	for i: int in range(3):
		var forme: CollisionShape3D = CollisionShape3D.new()
		forme.shape = BoxShape3D.new()
		corps.add_child(forme)
	boucle.root.add_child(faux_lieu)
	await boucle.process_frame

	var compte: Dictionary = _compter_budget(faux_lieu)
	check_equal(int(compte["collisions"]), 3,
		"témoin — le compteur voit les FORMES de collision et non le corps")
	check_equal(int(compte["visuels"]), 1,
		"témoin — le compteur voit le MultiMeshInstance3D comme nœud visuel")
	var emprise: AABB = _emprise_visuelle(faux_lieu)
	check(emprise.size != Vector3.ZERO,
		"témoin — l'emprise visuelle voit un MultiMesh (obtenu %s) ; un calcul "
		% str(emprise.size) + "fondé sur MeshInstance3D rendrait Vector3.ZERO "
		+ "et conclurait « aucun maillage visuel » sur le champ de fleurs")

	faux_lieu.queue_free()
	await boucle.process_frame
	var propre: bool = await restore_root()
	check(propre, "démontage propre (témoin des compteurs) — %s"
		% restore_root_reason())


## ===========================================================================
## OUTILLAGE
## ===========================================================================

func _monter() -> void:
	var boucle: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	boucle.root.add_child(_world)
	await boucle.process_frame
	await boucle.physics_frame
	_heightmap = _world.call("heightmap") as WorldV2Heightmap


func _demonter() -> void:
	var propre: bool = await restore_root()
	check(propre, "démontage propre (lot 1) — %s" % restore_root_reason())
	restore_saves()


func _lieu(place_id: StringName) -> Node3D:
	if _world == null:
		return null
	for noeud: Node in _world.get_tree().get_nodes_in_group(&"world_v2_places"):
		if (noeud.get_meta(&"place_id", &"") as StringName) == place_id:
			return noeud as Node3D
	return null


## Remonte du collider au lieu qui le porte.
func _lieu_proprietaire(noeud: Node) -> StringName:
	var courant: Node = noeud
	while courant != null:
		if courant.has_meta(&"place_id"):
			return courant.get_meta(&"place_id", &"?") as StringName
		courant = courant.get_parent()
	return &"?"


func _appuis(lieu: Node3D) -> PackedVector3Array:
	var meta: Variant = lieu.get_meta(&"support_points", null)
	if meta is PackedVector3Array:
		return meta as PackedVector3Array
	return PackedVector3Array()


## Exemptions RUNTIME nommées par le lieu lui-même. Précédent : `SolBrule`,
## le disque brûlé de l'arbre foudroyé, qui épouse le terrain sommet par
## sommet et ne peut donc pas être un GLB. Une exemption existe si elle est
## NOMMÉE ; il n'y a pas d'exemption tacite.
func _exemptions_runtime(lieu: Node3D) -> Array[String]:
	var noms: Array[String] = []
	var meta: Variant = lieu.get_meta(&"exemption_runtime", null)
	if meta is PackedStringArray:
		for nom: String in meta as PackedStringArray:
			noms.append(nom)
	elif meta is Array:
		for valeur: Variant in meta as Array:
			noms.append(String(valeur))
	return noms


## Emprise MONDE sur les `VisualInstance3D` — MultiMesh compris.
func _emprise_visuelle(lieu: Node3D) -> AABB:
	var totale: AABB = AABB()
	var premier: bool = true
	for noeud: Node in lieu.find_children("*", "VisualInstance3D", true, false):
		var instance: VisualInstance3D = noeud as VisualInstance3D
		var boite: AABB = instance.global_transform * instance.get_aabb()
		if boite.size == Vector3.ZERO:
			continue
		if premier:
			totale = boite
			premier = false
		else:
			totale = totale.merge(boite)
	return totale


## Couverture des appuis : pour tout axe dont l'emprise dépasse 6 m, un appui
## dans le tiers bas et un dans le tiers haut.
func _couverture_appuis(id: StringName, lieu: Node3D,
		appuis: PackedVector3Array, emprise: AABB) -> Array[String]:
	var faults: Array[String] = []
	var axes: Array[String] = ["X", "Z"]
	for a: int in range(2):
		var taille: float = emprise.size.x if a == 0 else emprise.size.z
		if taille <= 6.0:
			continue
		var bas: float = (emprise.position.x if a == 0 else emprise.position.z) \
			+ taille / 3.0
		var haut: float = (emprise.end.x if a == 0 else emprise.end.z) \
			- taille / 3.0
		var tiers_bas: bool = false
		var tiers_haut: bool = false
		for local: Vector3 in appuis:
			var monde: Vector3 = lieu.to_global(local)
			var v: float = monde.x if a == 0 else monde.z
			if v <= bas:
				tiers_bas = true
			if v >= haut:
				tiers_haut = true
		if not (tiers_bas and tiers_haut):
			var manque: String = "aucun appui dans le tiers bas" if not tiers_bas \
				else "aucun appui dans le tiers haut"
			faults.append(("D2 couverture des appuis %s : emprise %.1f m en %s, "
				+ "mais %s — un appui central ne prouve rien du reste")
				% [id, taille, axes[a], manque])
	return faults


## Signature de composition : multi-ensemble trié des sources de maillage et de
## leur échelle. Deux lieux qui la partagent sont le MÊME lieu bâti deux fois.
func _signature_composition(lieu: Node3D) -> String:
	var pieces: Array[String] = []
	for noeud: Node in lieu.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = noeud as MeshInstance3D
		if instance.mesh == null:
			continue
		var source: String = instance.mesh.resource_path
		if source.is_empty():
			# Un maillage runtime n'a pas de chemin : on l'empreinte par sa
			# forme, sinon deux géométries différentes se confondraient.
			var boite: AABB = instance.mesh.get_aabb()
			source = "runtime:%d:%.2fx%.2fx%.2f" % [
				_triangles(instance.mesh), boite.size.x, boite.size.y, boite.size.z]
		var e: Vector3 = instance.global_transform.basis.get_scale()
		pieces.append("%s@%.1f,%.1f,%.1f" % [source, e.x, e.y, e.z])
	pieces.sort()
	return "|".join(pieces)


## Les trois compteurs du budget, définis dans docs/V2_3_B_LOT1_CONTROLES.md §2.
func _compter_budget(lieu: Node3D) -> Dictionary:
	var modules: int = 0
	for noeud: Node in lieu.find_children("*", "Node", true, false):
		if not (noeud as Node).scene_file_path.is_empty():
			modules += 1
	for noeud: Node in lieu.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = noeud as MeshInstance3D
		if instance.mesh != null and instance.mesh.resource_path.is_empty():
			modules += 1
	# `VisualInstance3D` et non `MeshInstance3D` : un MultiMesh échapperait au
	# second et le compteur annoncerait « 0 » sur le lieu le plus dense du lot.
	var visuels: int = lieu.find_children("*", "VisualInstance3D", true, false).size()
	# `CollisionShape3D` et non `StaticBody3D` : c'est la FORME qui coûte et qui
	# obstrue. Un corps unique peut en porter trente, et le budget « 6 » d'un
	# micro-POI passerait sans que rien ne bronche.
	var collisions: int = lieu.find_children("*", "CollisionShape3D", true, false).size()
	return {"modules": modules, "visuels": visuels, "collisions": collisions}


func _triangles(mesh: Mesh) -> int:
	var total: int = 0
	for s: int in range(mesh.get_surface_count()):
		if mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays: Array = mesh.surface_get_arrays(s)
		var index: PackedInt32Array = _index_de(arrays)
		if index.size() > 0:
			total += index.size() / 3
		else:
			total += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return total


## `ARRAY_INDEX` vaut `null` sur une surface NON INDEXÉE, et `null as
## PackedInt32Array` ne rend pas un tableau vide : il casse. Un seul point
## d'entrée, pour que les trois mesures traitent le cas de la même façon.
func _index_de(arrays: Array) -> PackedInt32Array:
	var brut: Variant = arrays[Mesh.ARRAY_INDEX]
	if brut == null:
		return PackedInt32Array()
	return brut as PackedInt32Array


## Aire MONDE des triangles d'une instance : l'aire est ce qu'on voit, donc
## elle se mesure après la transformation, pas dans le repère local.
func _aire_monde(instance: MeshInstance3D) -> float:
	var base: Basis = instance.global_transform.basis
	var total: float = 0.0
	for s: int in range(instance.mesh.get_surface_count()):
		if instance.mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays: Array = instance.mesh.surface_get_arrays(s)
		var sommets: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var index: PackedInt32Array = _index_de(arrays)
		var indirect: bool = index.size() > 0
		var n: int = index.size() if indirect else sommets.size()
		var i: int = 0
		while i + 2 < n:
			var ia: int = index[i] if indirect else i
			var ib: int = index[i + 1] if indirect else i + 1
			var ic: int = index[i + 2] if indirect else i + 2
			var a: Vector3 = base * sommets[ia]
			var b: Vector3 = base * sommets[ib]
			var c: Vector3 = base * sommets[ic]
			total += (b - a).cross(c - a).length() * 0.5
			i += 3
	return total


## BOÎTITUDE `hexa` — recalculée ici, à l'identique de
## `tools/mesure_boititude.py`, sur le maillage tel que le moteur le porte.
##
## L'ORDRE EST IMPOSÉ ET NON NÉGOCIABLE : d'abord SOUDER par position, ENSUITE
## calculer la connexité sur les sommets soudés. Une première version de
## l'instrument Python fusionnait les deux dans une seule union-find : chaque
## composante s'effondrait sur un sommet racine, « 8 sommets » ne pouvait
## jamais être vrai, et l'outil rendait 0,0 % sur un maillage à 79,6 %. Il a été
## rattrapé parce que le chiffre était invraisemblable, pas parce que le code a
## protesté.
func _boititude(mesh: Mesh) -> Dictionary:
	var positions: PackedVector3Array = PackedVector3Array()
	var triangles: Array[Vector3i] = []
	for s: int in range(mesh.get_surface_count()):
		if mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays: Array = mesh.surface_get_arrays(s)
		var sommets: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var index: PackedInt32Array = _index_de(arrays)
		var indirect: bool = index.size() > 0
		var decalage: int = positions.size()
		positions.append_array(sommets)
		var n: int = index.size() if indirect else sommets.size()
		var i: int = 0
		while i + 2 < n:
			if indirect:
				triangles.append(Vector3i(decalage + index[i],
					decalage + index[i + 1], decalage + index[i + 2]))
			else:
				triangles.append(Vector3i(decalage + i, decalage + i + 1,
					decalage + i + 2))
			i += 3
	if triangles.is_empty():
		return {"tris": 0, "hexa_tris": 0, "hexa_pct": 0.0}

	# 1. SOUDAGE. Une grille de 0,1 mm, plus un balayage des 27 cellules
	# voisines : sans ce balayage, deux coins distants de 12 µm qui tombent de
	# part et d'autre d'une frontière de cellule restent deux sommets, la
	# boîtitude s'effondre, et le vert obtenu est un ACCIDENT — le mode de
	# panne le plus dangereux d'un plafond.
	var cellules: Dictionary = {}
	var soude: PackedInt32Array = PackedInt32Array()
	soude.resize(positions.size())
	var representants: PackedVector3Array = PackedVector3Array()
	for i: int in range(positions.size()):
		var p: Vector3 = positions[i]
		var cx: int = int(floor(p.x / SOUDAGE_M))
		var cy: int = int(floor(p.y / SOUDAGE_M))
		var cz: int = int(floor(p.z / SOUDAGE_M))
		var trouve: int = -1
		for dx: int in range(-1, 2):
			for dy: int in range(-1, 2):
				for dz: int in range(-1, 2):
					var cle: String = "%d,%d,%d" % [cx + dx, cy + dy, cz + dz]
					if not cellules.has(cle):
						continue
					for candidat: int in cellules[cle] as PackedInt32Array:
						if representants[candidat].distance_to(p) <= SOUDAGE_M:
							trouve = candidat
							break
					if trouve >= 0:
						break
				if trouve >= 0:
					break
			if trouve >= 0:
				break
		if trouve < 0:
			trouve = representants.size()
			representants.append(p)
			var cle_propre: String = "%d,%d,%d" % [cx, cy, cz]
			var liste: PackedInt32Array = cellules.get(cle_propre,
				PackedInt32Array()) as PackedInt32Array
			liste.append(trouve)
			cellules[cle_propre] = liste
		soude[i] = trouve

	# 2. CONNEXITÉ, sur les sommets SOUDÉS et pas avant.
	var parent: Array[int] = []
	parent.resize(representants.size())
	for i: int in range(representants.size()):
		parent[i] = i
	for t: Vector3i in triangles:
		_unir(parent, soude[t.x], soude[t.y])
		_unir(parent, soude[t.y], soude[t.z])

	# 3. Par composante : triangles et sommets géométriques distincts.
	var tris_par_comp: Dictionary = {}
	var sommets_par_comp: Dictionary = {}
	for t: Vector3i in triangles:
		var racine: int = _racine(parent, soude[t.x])
		tris_par_comp[racine] = int(tris_par_comp.get(racine, 0)) + 1
		var vus: Dictionary = sommets_par_comp.get(racine, {}) as Dictionary
		vus[soude[t.x]] = true
		vus[soude[t.y]] = true
		vus[soude[t.z]] = true
		sommets_par_comp[racine] = vus
	var hexa_tris: int = 0
	for racine: int in tris_par_comp.keys():
		var nb: int = int(tris_par_comp[racine])
		var nv: int = (sommets_par_comp[racine] as Dictionary).size()
		if nb == 12 and nv == 8:
			hexa_tris += nb
	var total: int = triangles.size()
	return {"tris": total, "hexa_tris": hexa_tris,
		"hexa_pct": 100.0 * float(hexa_tris) / float(total)}


func _racine(parent: Array[int], a: int) -> int:
	var r: int = a
	while parent[r] != r:
		r = parent[r]
	var c: int = a
	while parent[c] != c:
		var suivant: int = parent[c]
		parent[c] = r
		c = suivant
	return r


func _unir(parent: Array[int], a: int, b: int) -> void:
	var ra: int = _racine(parent, a)
	var rb: int = _racine(parent, b)
	if ra != rb:
		parent[rb] = ra


func _dans_marge(p: Vector2, boite: AABB, marge: float) -> bool:
	return p.x > boite.position.x - marge and p.x < boite.end.x + marge \
		and p.y > boite.position.z - marge and p.y < boite.end.z + marge


func _distance_polyligne(p: Vector2, ligne: PackedVector2Array) -> float:
	if ligne.size() < 2:
		return 1.0e9
	var mini: float = 1.0e9
	for i: int in range(ligne.size() - 1):
		var proche: Vector2 = Geometry2D.get_closest_point_to_segment(
			p, ligne[i], ligne[i + 1])
		mini = minf(mini, p.distance_to(proche))
	return mini


func _site_layout(layout: Dictionary, place_id: StringName) -> Vector3:
	for poi: Dictionary in layout.get("pois", []) as Array:
		if StringName(poi.get("id", "")) == place_id:
			var brut: Variant = poi.get("v2_site", null)
			if brut is Array and (brut as Array).size() == 3:
				var v: Array = brut as Array
				return Vector3(float(v[0]), float(v[1]), float(v[2]))
	return Vector3.INF


func _script_de_scene(scene_path: String) -> String:
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		return ""
	var etat: SceneState = packed.get_state()
	for i: int in range(etat.get_node_property_count(0)):
		if etat.get_node_property_name(0, i) == &"script":
			var script: Script = etat.get_node_property_value(0, i) as Script
			if script != null:
				return script.resource_path
	return ""


## Le littéral est cherché en TOKEN, pas en sous-chaîne : sans les gardes, le
## « 40 » de `-160` et celui de `0.40` compteraient tous les deux.
func _porte_litteral(texte: String, valeur: float) -> bool:
	var entier: String = "%d" % int(round(valeur))
	var motif: RegEx = RegEx.new()
	if motif.compile("(?<![0-9.])" + entier.replace("-", "\\-")
			+ "(\\.0+)?(?![0-9.])") != OK:
		return false
	return motif.search(texte) != null


## Contenu d'une récompense, sous la forme « kind:id ». Rendre "" quand le
## nœud n'est pas une récompense, pour que l'appelant distingue « rien trouvé »
## de « mauvaise récompense ».
func _contenu_recompense(noeud: Node) -> String:
	if noeud is Chest:
		var coffre: Chest = noeud as Chest
		if coffre.weapon_loot != null:
			return "weapon:%s" % String(coffre.weapon_loot.get("id"))
		return "arrows:%d" % coffre.arrows_loot
	if noeud is WeaponPickup:
		var arme: WeaponPickup = noeud as WeaponPickup
		if arme.definition != null:
			return "weapon:%s" % String(arme.definition.get("id"))
		return "weapon:?"
	if noeud is IngredientPickup:
		var ing: IngredientPickup = noeud as IngredientPickup
		if ing.definition != null:
			return "ingredient:%s" % String(ing.definition.get("id"))
		return "ingredient:?"
	if noeud is StoryFragment:
		return "story:%s" % String((noeud as StoryFragment).fragment_id)
	return ""


func _verdict_json(chemin: String) -> Dictionary:
	if not FileAccess.file_exists(chemin):
		return {}
	var brut: String = FileAccess.get_file_as_string(chemin)
	var lu: Variant = JSON.parse_string(brut)
	if lu is Dictionary:
		return lu as Dictionary
	return {}


## AABB monde approchée d'une forme de collision — même arithmétique que
## `test_world_v2_places_contract.gd`, pour que les deux filets s'accordent.
func _emprise_forme(noeud: CollisionShape3D) -> AABB:
	var forme: Shape3D = noeud.shape
	if forme == null:
		return AABB()
	var locale: AABB = AABB()
	if forme is BoxShape3D:
		var taille: Vector3 = (forme as BoxShape3D).size
		locale = AABB(-taille * 0.5, taille)
	elif forme is SphereShape3D:
		var r: float = (forme as SphereShape3D).radius
		locale = AABB(Vector3(-r, -r, -r), Vector3(r * 2.0, r * 2.0, r * 2.0))
	elif forme is CylinderShape3D:
		var cyl: CylinderShape3D = forme as CylinderShape3D
		locale = AABB(Vector3(-cyl.radius, -cyl.height * 0.5, -cyl.radius),
			Vector3(cyl.radius * 2.0, cyl.height, cyl.radius * 2.0))
	elif forme is CapsuleShape3D:
		var cap: CapsuleShape3D = forme as CapsuleShape3D
		locale = AABB(Vector3(-cap.radius, -cap.height * 0.5, -cap.radius),
			Vector3(cap.radius * 2.0, cap.height, cap.radius * 2.0))
	elif forme is ConvexPolygonShape3D:
		var points: PackedVector3Array = (forme as ConvexPolygonShape3D).points
		if points.is_empty():
			return AABB()
		locale = AABB(points[0], Vector3.ZERO)
		for p: Vector3 in points:
			locale = locale.expand(p)
	elif forme is ConcavePolygonShape3D:
		var faces: PackedVector3Array = (forme as ConcavePolygonShape3D).get_faces()
		if faces.is_empty():
			return AABB()
		locale = AABB(faces[0], Vector3.ZERO)
		for p: Vector3 in faces:
			locale = locale.expand(p)
	else:
		return AABB()
	return noeud.global_transform * locale


func _plafonner(faults: Array[String], garder: int = 6) -> String:
	var montre: Array[String] = faults.slice(0, garder)
	if faults.size() > garder:
		montre.append("… et %d autre(s)" % (faults.size() - garder))
	return " ; ".join(montre)
