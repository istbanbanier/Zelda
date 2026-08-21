## SONDE D'IMPLANTATION DU LOT 1 (V2.3-B, voie A) — diagnostic seul.
##
## Elle ne construit rien et ne modifie rien. Elle monte le monde V2 GELÉ et
## répond, pour chacun des six sujets du lot 1, à la seule question qui
## gouverne la fondation : **ce site porte-t-il un lieu, et à quel prix ?**
##
## Usage :
##   tools/lancer_godot.sh --headless --path . \
##       --script tools/godot/sonde_implantation_lot1.gd > sortie.log
##   # le document JSON se lit entre === IMPLANTATION_BEGIN/END ===
##
## CONTRÔLE NÉGATIF — une sonde qui n'a jamais rien condamné ne prouve rien :
##
##   tools/lancer_godot.sh --headless --path . \
##       --script tools/godot/sonde_implantation_lot1.gd -- --controle-negatif
##
## Elle mesure alors TROIS points fabriqués dont le verdict est connu
## d'avance : au milieu du cours principal, au centre du lac, et sur un
## waypoint de route. Si l'un d'eux ressort `POSABLE`, la sonde est aveugle et
## le tableau qu'elle produit ne vaut rien. Ces points ne sont PAS des sujets :
## ils vivent dans une section séparée du document.
##
## CE QU'ELLE MESURE, et pourquoi chacune de ces grandeurs est ici :
##
##  1. hauteur du terrain gelé au site et ÉCART avec le `y` du layout — le
##     bâtisseur pose la racine à `height_at`, pas à `y` : l'écart dit de
##     combien le pad a réellement tiré le terrain.
##  2. pente locale sur un disque de 6 m (max, moyenne) et dénivelé — un lieu
##     sur 40 % de pente ne se pose pas comme sur un replat.
##  3. distance aux quatre routes contractuelles, aux trois gués, au cours
##     principal, à l'affluent et au lac.
##  4. eau sous le site — le piège du hameau V2.1 : un site 1,5 m SOUS la
##     surface d'un affluent. On ne demande pas « y a-t-il de l'eau », on
##     mesure de combien la surface passe au-dessus du sol.
##  5. distance aux six caméras GELÉES et à leur segment de visée, plus la
##     GARDE du rayon au-dessus du terrain au point d'approche la plus
##     proche — c'est ce nombre, et non la distance latérale, qui dit si une
##     tour de 12 m coupera la fenêtre.
##  6. végétation gelée dans 8 m, par couche, et colliders végétaux — pour
##     que la voie B compose AUTOUR au lieu de la traverser.
##
## DEUX PIÈGES, mesurés dans ce dépôt, dont cette sonde se protège :
##
##  * `WorldV2Heightmap.distance_to_water_course()` est BUCKETISÉE : elle ne
##    regarde que les segments de la cellule de 32 m du point, et rend `INF`
##    dès que le cours d'eau est dans une autre cellule. Utilisée telle
##    quelle pour un site à 100 m de la rivière, elle rendrait « infini » —
##    vrai au sens du code, faux au sens qui compte. On balaie donc les
##    polylignes ENTIÈRES, et on publie les deux nombres côte à côte.
##  * `instance_origins` contient des positions MONDE. `probe_vegetation_near.gd`
##    les remultiplie par `global_transform`, ce qui ajoute la position de la
##    cellule (jusqu'à ±240 m) : ses comptes « dans 8 m » portent sur un
##    autre endroit. Ici on vérifie le repère AVANT de compter, par un
##    résidu d'ancrage, et on BLOQUE si la vérification ne tranche pas.
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"

## Les six sujets. Seuls les IDENTIFIANTS sont ici ; les positions viennent
## du layout, qui est la seule source (contrat du lot §2.2).
const SUJETS: Array[StringName] = [
	&"valley.poi.watchtower_ruin.01",
	&"valley.poi.overlook_summit.01",
	&"valley.poi.turquoise_spring.01",
	&"valley.poi.forest_shrine.01",
	&"valley.poi.barrow_cemetery.01",
	&"valley.poi.flower_field.01",
]

const ROUTES: Array[String] = ["main_path", "river_route", "heights_route",
	"ruins_route"]

## Rayon d'inspection de la végétation gelée (brief voie A).
const RAYON_VEGETATION_M: float = 8.0
## Disque de mesure de pente (brief voie A).
const RAYON_PENTE_M: float = 6.0
const ANNEAUX_PENTE: Array[float] = [1.5, 3.0, 4.5, 6.0]
const SECTEURS_PENTE: int = 24
## Anneaux d'inspection de l'eau sous le site.
const ANNEAUX_EAU: Array[float] = [0.0, 2.0, 4.0, 6.0, 8.0]

## Fraction de visée exigée libre — MÊME valeur que `test_world_v2_cameras.gd`.
## Recopiée ici parce qu'un script ne peut pas lire la constante d'un test
## sans le charger ; l'écart avec la source rougirait au premier changement,
## et c'est la raison pour laquelle elle est imprimée dans le document.
const CLEAR_SIGHT_FRACTION: float = 0.6

## ---------------------------------------------------------------------------
## SEUILS DE LECTURE — ils ne sont PAS des portails.
##
## Les seuils qui rougissent sont ceux du filet
## (`test_world_v2_places_contract.gd`) et des caméras. Ceux-ci servent
## uniquement à colorer la colonne « verdict » du tableau publié : ils disent
## « attention, ce site coûtera quelque chose à la voie B », pas « échec ».
## Les nommer ainsi évite qu'un chiffre de confort devienne plus tard un
## plancher de qualité (tools/CLAUDE.md, calibrage sur le sujet).
## ---------------------------------------------------------------------------
const LECTURE_ROUTE_CONFORT_M: float = 4.0
const LECTURE_CAMERA_CONFORT_M: float = 8.0
const LECTURE_VISEE_CONFORT_M: float = 6.0
const LECTURE_PENTE_CONFORT_DEG: float = 20.0
const LECTURE_DENIVELE_CONFORT_M: float = 1.5
const LECTURE_BANDE_CONFORT_M: float = 5.0
## Le filet : écart maximal admis entre la racine et le sol.
const ROOT_GROUND_TOLERANCE_M: float = 1.0

## Points fabriqués du contrôle négatif : [étiquette, x, z, défaut attendu].
## Les coordonnées viennent du layout gelé — milieu d'un segment du cours
## principal, centre du lac, waypoint de `heights_route`.
const CONTROLE_NEGATIF: Array[Array] = [
	["negatif_dans_le_cours", 36.0, 6.0, "IMPOSSIBLE"],
	["negatif_dans_le_lac", -15.0, -140.0, "IMPOSSIBLE"],
	["negatif_sur_une_route", 168.0, 52.0, "CONTRAINT"],
]

var _bloques: Array[String] = []


func _init() -> void:
	call_deferred("_executer")


func _executer() -> void:
	var monde: Node3D = (load(WORLD) as PackedScene).instantiate() as Node3D
	root.add_child(monde)
	await process_frame
	await physics_frame
	await process_frame

	var heightmap: WorldV2Heightmap = monde.call("heightmap") as WorldV2Heightmap
	var layout: Dictionary = monde.call("layout") as Dictionary
	if heightmap == null or layout.is_empty():
		_bloquer("le monde n'expose ni heightmap ni layout — rien n'est mesurable")
		_sortir({})
		return

	# Les CENTRES d'intérêt sont connus avant la collecte : les six sites, plus
	# les points du contrôle négatif. La végétation est filtrée à la lecture —
	# garder les ~100 000 instances du monde entier pour en compter quelques
	# dizaines serait une allocation massive sans usage.
	var centres: PackedVector2Array = PackedVector2Array()
	for sujet: StringName in SUJETS:
		var site_centre: Vector3 = _site_du_layout(layout, sujet)
		if site_centre != Vector3.INF:
			centres.append(Vector2(site_centre.x, site_centre.z))
	for point: Array in CONTROLE_NEGATIF:
		centres.append(Vector2(float(point[1]), float(point[2])))

	var plantes: Array[Dictionary] = []
	var repere: Dictionary = _collecter_vegetation(monde, heightmap, centres,
		plantes)
	var colliders: Array[Dictionary] = _collecter_colliders_vegetaux(monde,
		centres)
	var cameras: Array[Dictionary] = _collecter_cameras(monde)
	if cameras.size() != 6:
		_bloquer("%d caméra(s) gelée(s) trouvée(s), 6 attendues" % cameras.size())

	var doc: Dictionary = {
		"sonde": "tools/godot/sonde_implantation_lot1.gd",
		"commit": _commit(),
		"repo_dirty": _depot_sale(),
		"clear_sight_fraction": CLEAR_SIGHT_FRACTION,
		"rayon_vegetation_m": RAYON_VEGETATION_M,
		"rayon_pente_m": RAYON_PENTE_M,
		"repere_vegetation": repere,
		"vegetation_instances_retenues": plantes.size(),
		"colliders_vegetaux_retenus": colliders.size(),
		"seuils_de_lecture": {
			"route_confort_m": LECTURE_ROUTE_CONFORT_M,
			"camera_confort_m": LECTURE_CAMERA_CONFORT_M,
			"visee_confort_m": LECTURE_VISEE_CONFORT_M,
			"pente_confort_deg": LECTURE_PENTE_CONFORT_DEG,
			"denivele_confort_m": LECTURE_DENIVELE_CONFORT_M,
			"bande_confort_m": LECTURE_BANDE_CONFORT_M,
			"note": "seuils de LECTURE, jamais des portails — voir l'en-tête",
		},
	}
	var sujets: Dictionary = {}

	var segments_routes: Dictionary = _segments_routes(layout)
	var gues: Array[Dictionary] = _gues(layout)

	for sujet: StringName in SUJETS:
		var site: Vector3 = _site_du_layout(layout, sujet)
		if site == Vector3.INF:
			_bloquer("%s : aucun v2_site dans le layout" % sujet)
			continue
		sujets[String(sujet)] = _mesurer(site, heightmap,
			segments_routes, gues, cameras, plantes, colliders)
	doc["sujets"] = sujets

	if OS.get_cmdline_user_args().has("--controle-negatif"):
		doc["controle_negatif"] = _controle_negatif(heightmap, segments_routes,
			gues, cameras, plantes, colliders)

	_imprimer_tableau(doc, sujets)
	_sortir(doc)


## LE CONTRÔLE NÉGATIF. Il ne mesure pas le lot : il mesure la SONDE.
##
## Trois points dont le défaut est connu avant la mesure. Leur `y` est posé à
## la hauteur du terrain pour que l'écart layout/sol soit nul — sinon ce seul
## écart suffirait à les condamner, et le contrôle prouverait la mauvaise
## chose : le sabotage doit retirer LA chose testée, pas ce qui est en dessous
## (tools/CLAUDE.md).
##
## Si l'un des trois ressort `POSABLE`, la sonde est aveugle : on BLOQUE, et
## le tableau des six sujets ne doit pas être publié.
func _controle_negatif(heightmap: WorldV2Heightmap, segments_routes: Dictionary,
		gues: Array[Dictionary], cameras: Array[Dictionary],
		plantes: Array[Dictionary],
		colliders: Array[Dictionary]) -> Dictionary:
	var sortie: Dictionary = {}
	for point: Array in CONTROLE_NEGATIF:
		var etiquette: String = String(point[0])
		var x: float = float(point[1])
		var z: float = float(point[2])
		var attendu: String = String(point[3])
		var site: Vector3 = Vector3(x, heightmap.height_at(x, z), z)
		var mesure: Dictionary = _mesurer(site, heightmap, segments_routes,
			gues, cameras, plantes, colliders)
		var verdict: String = String(mesure["verdict"])
		var famille: String = verdict.split(" (")[0]
		mesure["defaut_attendu"] = attendu
		mesure["controle"] = "VU" if famille == attendu else "AVEUGLE"
		if famille != attendu:
			_bloquer(("contrôle négatif %s : attendu %s, obtenu %s — la sonde "
				+ "ne voit pas le défaut qu'elle est censée voir")
				% [etiquette, attendu, famille])
		sortie[etiquette] = mesure
	return sortie


## -- mesure d'un site ---------------------------------------------------------

func _mesurer(site: Vector3, heightmap: WorldV2Heightmap,
		segments_routes: Dictionary, gues: Array[Dictionary],
		cameras: Array[Dictionary], plantes: Array[Dictionary],
		colliders: Array[Dictionary]) -> Dictionary:
	var x: float = site.x
	var z: float = site.z
	var h_centre: float = heightmap.height_at(x, z)

	# 1. Relief : pente et dénivelé sur le disque.
	var pente_max: float = heightmap.slope_deg_at(x, z)
	var pente_somme: float = pente_max
	var pente_n: int = 1
	var h_min: float = h_centre
	var h_max: float = h_centre
	var pente_pire_xz: Array = [x, z]
	for rayon: float in ANNEAUX_PENTE:
		for k: int in range(SECTEURS_PENTE):
			var a: float = TAU * float(k) / float(SECTEURS_PENTE)
			var px: float = x + cos(a) * rayon
			var pz: float = z + sin(a) * rayon
			var s: float = heightmap.slope_deg_at(px, pz)
			pente_somme += s
			pente_n += 1
			if s > pente_max:
				pente_max = s
				pente_pire_xz = [snappedf(px, 0.1), snappedf(pz, 0.1)]
			var h: float = heightmap.height_at(px, pz)
			h_min = minf(h_min, h)
			h_max = maxf(h_max, h)

	# 2. Routes.
	var par_route: Dictionary = {}
	var route_proche: String = ""
	var route_d: float = INF
	for nom: String in ROUTES:
		var d: float = _distance_polyligne(Vector2(x, z),
			segments_routes[nom] as PackedVector2Array)
		par_route[nom] = snappedf(d, 0.01)
		if d < route_d:
			route_d = d
			route_proche = nom

	# 3. Gués.
	var par_gue: Dictionary = {}
	var gue_proche: String = ""
	var gue_d: float = INF
	for gue: Dictionary in gues:
		var pos: Vector2 = gue["pos"] as Vector2
		var d: float = Vector2(x, z).distance_to(pos)
		par_gue[String(gue["id"])] = snappedf(d, 0.01)
		if d < gue_d:
			gue_d = d
			gue_proche = String(gue["id"])

	# 4. Cours d'eau — balayage COMPLET des polylignes, et le nombre bucketisé
	# à côté pour que l'écart soit visible plutôt que caché.
	var d_principal: float = _distance_polyligne(Vector2(x, z),
		heightmap.river_main_polyline())
	var d_affluent: float = _distance_polyligne(Vector2(x, z),
		heightmap.river_trib_polyline())
	var d_bucket: float = heightmap.distance_to_water_course(x, z)
	var d_lac: float = Vector2(x, z).distance_to(heightmap.lake_center())

	var bande_principale: float = WorldV2Heightmap.RIVER_BED_HALF_W \
		+ WorldV2Heightmap.RIVER_BANK_W
	var bande_affluent: float = WorldV2Heightmap.TRIB_BED_HALF_W \
		+ WorldV2Heightmap.TRIB_BANK_W
	var bande_lac: float = heightmap.lake_radius() + 2.0

	# 5. Eau sous le site : de combien la surface passe-t-elle au-dessus du sol.
	var mouille: int = 0
	var submersion_max: float = -INF
	var submersion_xz: Array = []
	var echantillons_eau: int = 0
	for rayon: float in ANNEAUX_EAU:
		var secteurs: int = 1 if rayon == 0.0 else 8
		for k: int in range(secteurs):
			var a: float = TAU * float(k) / float(secteurs)
			var px: float = x + cos(a) * rayon
			var pz: float = z + sin(a) * rayon
			echantillons_eau += 1
			var surface: float = heightmap.water_surface_at(px, pz)
			if surface <= -1e29:
				continue
			var sol: float = heightmap.height_at(px, pz)
			var delta: float = surface - sol
			if delta > submersion_max:
				submersion_max = delta
				submersion_xz = [snappedf(px, 0.1), snappedf(pz, 0.1)]
			if heightmap.is_in_water(px, pz):
				mouille += 1

	# 6. Caméras gelées.
	var par_camera: Dictionary = {}
	var visee_min: float = INF
	var visee_camera: String = ""
	for camera: Dictionary in cameras:
		var pos: Vector3 = camera["pos"] as Vector3
		var cible: Vector3 = camera["cible"] as Vector3
		var fin: Vector3 = pos.lerp(cible, CLEAR_SIGHT_FRACTION)
		var a2: Vector2 = Vector2(pos.x, pos.z)
		var b2: Vector2 = Vector2(fin.x, fin.z)
		var t: float = _parametre_segment(Vector2(x, z), a2, b2)
		var proche2: Vector2 = a2.lerp(b2, t)
		var d_xz: float = Vector2(x, z).distance_to(proche2)
		var point_rayon: Vector3 = pos.lerp(fin, t)
		var sol_sous_rayon: float = heightmap.height_at(proche2.x, proche2.y)
		var d_3d: float = Vector3(x, h_centre, z).distance_to(point_rayon)
		par_camera[String(camera["nom"])] = {
			"distance_camera_m": snappedf(Vector2(x, z).distance_to(a2), 0.01),
			"distance_segment_vise_xz_m": snappedf(d_xz, 0.01),
			"distance_segment_vise_3d_m": snappedf(d_3d, 0.01),
			"t_approche": snappedf(t, 0.001),
			"derriere_la_camera": t <= 0.0,
			"garde_rayon_sur_sol_m": snappedf(point_rayon.y - sol_sous_rayon, 0.01),
			"altitude_rayon_m": snappedf(point_rayon.y, 0.01),
			"camera_xyz": [snappedf(pos.x, 0.01), snappedf(pos.y, 0.01),
				snappedf(pos.z, 0.01)],
		}
		if d_xz < visee_min:
			visee_min = d_xz
			visee_camera = String(camera["nom"])

	# 7. Végétation gelée dans le rayon.
	var par_couche: Dictionary = {}
	var veg_total: int = 0
	var veg_plus_proche: float = INF
	for plante: Dictionary in plantes:
		var p: Vector3 = plante["p"] as Vector3
		var d: float = Vector2(p.x, p.z).distance_to(Vector2(x, z))
		if d > RAYON_VEGETATION_M:
			continue
		veg_total += 1
		veg_plus_proche = minf(veg_plus_proche, d)
		var couche: String = String(plante["couche"])
		par_couche[couche] = int(par_couche.get(couche, 0)) + 1
	var blocs: Array = []
	for corps: Dictionary in colliders:
		var p: Vector3 = corps["p"] as Vector3
		var d: float = Vector2(p.x, p.z).distance_to(Vector2(x, z))
		if d > RAYON_VEGETATION_M:
			continue
		blocs.append({
			"nom": String(corps["nom"]),
			"distance_m": snappedf(d, 0.01),
			"xz": [snappedf(p.x, 0.1), snappedf(p.z, 0.1)],
		})

	# 8. Verdict de lecture.
	var contraintes: Array[String] = []
	var impossibles: Array[String] = []
	if d_principal < bande_principale:
		impossibles.append("dans la bande creusée du cours principal (%.1f < %.1f m)"
			% [d_principal, bande_principale])
	if d_affluent < bande_affluent:
		impossibles.append("dans la bande creusée de l'affluent (%.1f < %.1f m)"
			% [d_affluent, bande_affluent])
	if d_lac < bande_lac:
		impossibles.append("dans le dégagement du lac (%.1f < %.1f m)"
			% [d_lac, bande_lac])
	if mouille > 0:
		impossibles.append("%d échantillon(s) sous la surface d'eau (max %.2f m)"
			% [mouille, submersion_max])
	if absf(h_centre - site.y) > ROOT_GROUND_TOLERANCE_M:
		contraintes.append("écart layout/sol %.2f m (> %.1f m du filet)"
			% [h_centre - site.y, ROOT_GROUND_TOLERANCE_M])
	if route_d < LECTURE_ROUTE_CONFORT_M:
		contraintes.append("route %s à %.2f m — aucun collider dans son couloir"
			% [route_proche, route_d])
	if visee_min < LECTURE_VISEE_CONFORT_M:
		contraintes.append("segment de visée %s à %.2f m" % [visee_camera, visee_min])
	for nom: String in par_camera.keys():
		var c: Dictionary = par_camera[nom]
		if float(c["distance_camera_m"]) < LECTURE_CAMERA_CONFORT_M:
			contraintes.append("caméra gelée %s à %.2f m de l'objectif"
				% [nom, c["distance_camera_m"]])
	if pente_max > LECTURE_PENTE_CONFORT_DEG:
		contraintes.append("pente max %.1f° sur le disque de %.0f m"
			% [pente_max, RAYON_PENTE_M])
	if h_max - h_min > LECTURE_DENIVELE_CONFORT_M:
		contraintes.append("dénivelé %.2f m sur le disque" % (h_max - h_min))
	if d_principal - bande_principale < LECTURE_BANDE_CONFORT_M:
		contraintes.append("marge au cours principal %.2f m"
			% (d_principal - bande_principale))
	if d_affluent - bande_affluent < LECTURE_BANDE_CONFORT_M:
		contraintes.append("marge à l'affluent %.2f m" % (d_affluent - bande_affluent))
	if not blocs.is_empty():
		contraintes.append("%d collider(s) végétal(aux) gelé(s) dans %.0f m"
			% [blocs.size(), RAYON_VEGETATION_M])

	var verdict: String = "POSABLE"
	if not impossibles.is_empty():
		verdict = "IMPOSSIBLE (%s)" % " ; ".join(impossibles)
	elif not contraintes.is_empty():
		verdict = "CONTRAINT (%s)" % " ; ".join(contraintes)

	return {
		"v2_site": [site.x, site.y, site.z],
		"hauteur_terrain_m": snappedf(h_centre, 0.01),
		"ecart_layout_m": snappedf(h_centre - site.y, 0.01),
		"pente_centre_deg": snappedf(heightmap.slope_deg_at(x, z), 0.01),
		"pente_max_deg": snappedf(pente_max, 0.01),
		"pente_max_xz": pente_pire_xz,
		"pente_moyenne_deg": snappedf(pente_somme / float(pente_n), 0.01),
		"hauteur_min_disque_m": snappedf(h_min, 0.01),
		"hauteur_max_disque_m": snappedf(h_max, 0.01),
		"denivele_disque_m": snappedf(h_max - h_min, 0.01),
		"routes": par_route,
		"route_la_plus_proche": [route_proche, snappedf(route_d, 0.01)],
		"gues": par_gue,
		"gue_le_plus_proche": [gue_proche, snappedf(gue_d, 0.01)],
		"cours_principal_m": snappedf(d_principal, 0.01),
		"cours_principal_bande_m": bande_principale,
		"affluent_m": snappedf(d_affluent, 0.01),
		"affluent_bande_m": bande_affluent,
		"lac_centre_m": snappedf(d_lac, 0.01),
		"lac_bande_m": snappedf(bande_lac, 0.01),
		"distance_to_water_course_bucketisee_m":
			"INF" if is_inf(d_bucket) else snappedf(d_bucket, 0.01),
		"eau_echantillons": echantillons_eau,
		"eau_echantillons_mouilles": mouille,
		"eau_submersion_max_m":
			"aucune surface d'eau dans le rayon" if is_inf(submersion_max)
			else snappedf(submersion_max, 0.01),
		"eau_submersion_xz": submersion_xz,
		"cameras": par_camera,
		"visee_la_plus_proche": [visee_camera, snappedf(visee_min, 0.01)],
		"vegetation_dans_rayon": veg_total,
		"vegetation_par_couche": par_couche,
		"vegetation_plus_proche_m":
			"aucune" if is_inf(veg_plus_proche) else snappedf(veg_plus_proche, 0.01),
		"colliders_vegetaux_dans_rayon": blocs,
		"verdict": verdict,
	}


## -- collectes ----------------------------------------------------------------

## Le PLAN DE PLANTATION gelé, et la VÉRIFICATION de son repère.
##
## Le renderer factice du headless jette les transformées de MultiMesh : le
## bâtisseur écrit donc ses origines en méta, dans la même boucle. Ces
## origines sont en coordonnées MONDE (`_emit_cells` retranche la position de
## la cellule de la transformée moteur, PAS de la méta) — c'est ainsi que les
## lit `test_world_v2_landscape_contract.gd`, qui compare `origin.y` à
## `height_at(origin.x, origin.z)`.
##
## On ne le croit pas sur parole : on mesure le résidu d'ancrage des deux
## lectures possibles. La bonne colle au sol, l'autre s'en écarte de plusieurs
## dizaines de mètres. Si les deux se valent, on BLOQUE — un compte pris dans
## le mauvais repère serait précis, plausible et faux (famille ISS-018).
func _collecter_vegetation(monde: Node, heightmap: WorldV2Heightmap,
		centres: PackedVector2Array, sortie: Array[Dictionary]) -> Dictionary:
	var cellules: Array[Node] = monde.get_tree().get_nodes_in_group(
		&"world_v2_vegetation")
	var sans_plan: int = 0
	var residu_brut: float = 0.0
	var residu_transforme: float = 0.0
	var echantillons: int = 0
	for noeud: Node in cellules:
		var multi: MultiMeshInstance3D = noeud as MultiMeshInstance3D
		if multi == null:
			continue
		if not multi.has_meta(&"instance_origins"):
			sans_plan += 1
			continue
		var origines: PackedVector3Array = multi.get_meta(
			&"instance_origins") as PackedVector3Array
		# « veg_c<x>r<z>_<couche> » — la couche est ce qui suit les deux
		# premiers segments.
		var morceaux: PackedStringArray = String(multi.name).split("_")
		var couche: String = "_".join(morceaux.slice(2))
		var vers_monde: Transform3D = multi.global_transform
		var pas: int = maxi(1, int(origines.size() / 8))
		for i: int in range(origines.size()):
			var brut: Vector3 = origines[i]
			if _proche_d_un_centre(Vector2(brut.x, brut.z), centres):
				sortie.append({"p": brut, "couche": couche,
					"cellule": multi.name})
			# Le RÉSIDU d'ancrage, lui, s'échantillonne sur TOUT le monde :
			# vérifier le repère sur les seules instances déjà filtrées par ce
			# repère serait circulaire.
			if i % pas == 0:
				var transforme: Vector3 = vers_monde * brut
				residu_brut += absf(brut.y - heightmap.height_at(brut.x, brut.z))
				residu_transforme += absf(transforme.y
					- heightmap.height_at(transforme.x, transforme.z))
				echantillons += 1
	if sans_plan > 0:
		_bloquer("%d cellule(s) de végétation sans méta instance_origins — un compte serait faux"
			% sans_plan)
	if echantillons == 0:
		_bloquer("aucune instance de végétation échantillonnable")
		return {"verifie": false}
	var moyen_brut: float = residu_brut / float(echantillons)
	var moyen_transforme: float = residu_transforme / float(echantillons)
	# Marge x3 : deux lectures qui se valent ne tranchent rien.
	var tranche: bool = moyen_brut * 3.0 < moyen_transforme
	if not tranche:
		_bloquer(("repère de la végétation INDÉCIDABLE : résidu brut %.2f m, "
			+ "résidu transformé %.2f m — refus de compter") % [moyen_brut,
			moyen_transforme])
	return {
		"verifie": tranche,
		"lecture_retenue": "origines brutes = coordonnées MONDE",
		"residu_ancrage_brut_m": snappedf(moyen_brut, 0.001),
		"residu_ancrage_transforme_m": snappedf(moyen_transforme, 0.001),
		"echantillons": echantillons,
		"cellules": cellules.size(),
	}


func _collecter_colliders_vegetaux(monde: Node,
		centres: PackedVector2Array) -> Array[Dictionary]:
	var sortie: Array[Dictionary] = []
	for noeud: Node in monde.get_tree().get_nodes_in_group(
			&"world_v2_vegetation_colliders"):
		var corps: Node3D = noeud as Node3D
		if corps == null:
			continue
		var p: Vector3 = corps.global_position
		if not _proche_d_un_centre(Vector2(p.x, p.z), centres):
			continue
		sortie.append({"nom": corps.name, "p": p})
	return sortie


## Vrai si le point est dans le rayon d'inspection d'AU MOINS un centre.
func _proche_d_un_centre(p: Vector2, centres: PackedVector2Array) -> bool:
	for centre: Vector2 in centres:
		if p.distance_squared_to(centre) <= RAYON_VEGETATION_M * RAYON_VEGETATION_M:
			return true
	return false


func _collecter_cameras(monde: Node) -> Array[Dictionary]:
	var sortie: Array[Dictionary] = []
	for noeud: Node in monde.get_tree().get_nodes_in_group(
			&"world_v2_capture_cameras"):
		var camera: Camera3D = noeud as Camera3D
		if camera == null:
			continue
		sortie.append({
			"nom": String(camera.name),
			"pos": camera.global_position,
			"cible": camera.get_meta(&"target", Vector3.ZERO) as Vector3,
		})
	sortie.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["nom"]) < String(b["nom"]))
	return sortie


func _segments_routes(layout: Dictionary) -> Dictionary:
	var sortie: Dictionary = {}
	var routes: Dictionary = layout.get("routes", {}) as Dictionary
	for nom: String in ROUTES:
		var points: PackedVector2Array = PackedVector2Array()
		var waypoints: Array = (routes.get(nom, {}) as Dictionary).get(
			"waypoints_xz", []) as Array
		for entry: Variant in waypoints:
			var pair: Array = entry as Array
			points.append(Vector2(float(pair[0]), float(pair[1])))
		if points.size() < 2:
			_bloquer("route %s : moins de deux points" % nom)
		sortie[nom] = points
	return sortie


func _gues(layout: Dictionary) -> Array[Dictionary]:
	var sortie: Array[Dictionary] = []
	var river: Dictionary = layout.get("river", {}) as Dictionary
	for entry: Variant in river.get("fords", []) as Array:
		var gue: Dictionary = entry as Dictionary
		var pos: Array = gue.get("pos_xz", []) as Array
		if pos.size() != 2:
			continue
		sortie.append({"id": String(gue.get("id", "?")),
			"pos": Vector2(float(pos[0]), float(pos[1]))})
	if sortie.is_empty():
		_bloquer("aucun gué dans le layout")
	return sortie


func _site_du_layout(layout: Dictionary, poi_id: StringName) -> Vector3:
	for entry: Variant in layout.get("pois", []) as Array:
		var poi: Dictionary = entry as Dictionary
		if StringName(poi.get("id", "")) != poi_id:
			continue
		var site: Variant = poi.get("v2_site")
		if site is Array and (site as Array).size() == 3:
			var raw: Array = site as Array
			return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.INF


## -- géométrie ----------------------------------------------------------------

func _distance_polyligne(p: Vector2, points: PackedVector2Array) -> float:
	if points.size() < 2:
		return INF
	var meilleure: float = INF
	for i: int in range(points.size() - 1):
		var proche: Vector2 = Geometry2D.get_closest_point_to_segment(
			p, points[i], points[i + 1])
		meilleure = minf(meilleure, p.distance_to(proche))
	return meilleure


## Paramètre [0..1] du point du segment le plus proche de `p`.
func _parametre_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var seg: Vector2 = b - a
	var long2: float = seg.length_squared()
	if long2 <= 0.0:
		return 0.0
	return clampf((p - a).dot(seg) / long2, 0.0, 1.0)


## -- sortie -------------------------------------------------------------------

func _imprimer_tableau(doc: Dictionary, sujets: Dictionary) -> void:
	print("")
	print("=== IMPLANTATION LOT 1 — MESURES SOUS MOTEUR ===")
	print("commit %s (dirty=%s)" % [doc["commit"], doc["repo_dirty"]])
	var repere: Dictionary = doc["repere_vegetation"] as Dictionary
	print("végétation : %d instance(s) retenue(s) autour des centres ; repère %s "
		% [doc["vegetation_instances_retenues"],
			"VÉRIFIÉ" if bool(repere.get("verifie", false)) else "INDÉCIDABLE"]
		+ "(résidu brut %s m, transformé %s m)"
		% [repere.get("residu_ancrage_brut_m", "?"),
			repere.get("residu_ancrage_transforme_m", "?")])
	print("")
	var entete: String = "%-18s %7s %7s %7s %7s %7s %7s %7s %6s %5s"
	print(entete % ["sujet", "h_sol", "écart", "p_max", "p_moy", "déniv",
		"route", "visée", "eau", "vég."])
	for sujet: StringName in SUJETS:
		var cle: String = String(sujet)
		if not sujets.has(cle):
			continue
		var s: Dictionary = sujets[cle]
		print(entete % [
			cle.replace("valley.poi.", "").replace(".01", ""),
			"%.2f" % s["hauteur_terrain_m"],
			"%+.2f" % s["ecart_layout_m"],
			"%.1f" % s["pente_max_deg"],
			"%.1f" % s["pente_moyenne_deg"],
			"%.2f" % s["denivele_disque_m"],
			"%.1f" % (s["route_la_plus_proche"] as Array)[1],
			"%.1f" % (s["visee_la_plus_proche"] as Array)[1],
			"%d" % s["eau_echantillons_mouilles"],
			"%d" % s["vegetation_dans_rayon"],
		])
	print("")
	for sujet: StringName in SUJETS:
		var cle: String = String(sujet)
		if not sujets.has(cle):
			continue
		var s: Dictionary = sujets[cle]
		print("  %-34s %s" % [cle, s["verdict"]])


func _bloquer(raison: String) -> void:
	_bloques.append(raison)
	printerr("[implantation] BLOQUÉ : %s" % raison)


func _sortir(doc: Dictionary) -> void:
	if not _bloques.is_empty():
		doc["bloques"] = _bloques
	print("=== IMPLANTATION_BEGIN ===")
	print(JSON.stringify(doc, "  "))
	print("=== IMPLANTATION_END ===")
	# Une sonde qui ne peut pas mesurer le DIT : 3, jamais 0 (tools/CLAUDE.md).
	quit(3 if not _bloques.is_empty() else 0)


func _commit() -> String:
	var sortie: Array = []
	var rc: int = OS.execute("git", ["-C",
		ProjectSettings.globalize_path("res://"), "rev-parse", "HEAD"],
		sortie, true)
	if rc != 0 or sortie.is_empty():
		return "inconnu"
	return String(sortie[0]).strip_edges()


func _depot_sale() -> bool:
	var sortie: Array = []
	var rc: int = OS.execute("git", ["-C",
		ProjectSettings.globalize_path("res://"), "status", "--porcelain"],
		sortie, true)
	if rc != 0:
		return true
	return not String("" if sortie.is_empty() else sortie[0]).strip_edges().is_empty()
