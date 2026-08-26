## SONDE DE LA SOURCE AUX REFLETS — quatre contrôles ciblés, sur la scène
## MONTÉE, avec les vrais maillages et les vrais colliders.
##
## ELLE PEUT ROUGIR, et c'est la seule raison de l'écrire. Chaque contrôle est
## formulé de façon qu'un défaut réel le fasse échouer :
##
##   A. SURFACE FLOTTANTE — pour chaque masse de roche, on parcourt les
##      SOMMETS RÉELS du maillage importé, on les range par cellule de 0,5 m,
##      et on compare le sommet le PLUS BAS de chaque cellule au sol gelé
##      sous elle. Un lobe posé sur un terrain plus bas que son plan de pose
##      montre le dessous de sa jupe : ce contrôle le voit. On ne mesure PAS
##      la boîte englobante — c'est l'erreur d'ISS-018, où des tests verts
##      décrivaient la pose de liaison et non ce que le moteur dessine.
##
##      PLAFOND DE SURPLOMB, ET IL VIENT D'UN FAUX POSITIF MESURÉ. Le premier
##      jet signalait « 5,308 m de jour » sous le contrefort. Cinq mètres de
##      jour sous un rocher de cinq mètres n'existent pas : la cellule en
##      question était sous un SURPLOMB — la masse y déborde en hauteur sans
##      que sa base l'atteigne, ce que le générateur EXIGE (`SURPLOMBS_MIN`).
##      Une cellule dont le sommet le plus bas est très au-dessus du sol n'est
##      donc pas un jour, c'est un porte-à-faux ; seules comptent les cellules
##      où la masse est PRÉSENTE bas (moins de 0,60 m) et ne touche pourtant
##      pas. Un contrôle qui rougit à tort finit désactivé dans l'heure.
##   B. EAU JAMAIS SOUS LE TERRAIN, BERGE JAMAIS EN L'AIR — mêmes sommets
##      réels, bandes différentes selon le maillage.
##   C. MARCHE RÉELLE — une capsule de joueur est testée contre les vrais
##      colliders sur une grille de 0,5 m, puis on remplit depuis l'est (le
##      côté par lequel on arrive). Sont exigés joignables : l'ancre de
##      récompense, et au moins un point de chaque rive. Si une masse enferme
##      la récompense, ce contrôle échoue.
##   D. BANDES CREUSÉES ET TÊTE D'AFFLUENT — distance de chaque collider à la
##      polyligne de l'affluent et au cours principal, plus la portée réelle
##      de la langue d'eau.
##
## Usage :
##   tools/lancer_godot.sh --path . --script <ce fichier> -- --out=res://…json
extends SceneTree

const PLACE_ID: StringName = &"valley.poi.turquoise_spring.01"
## Capsule du joueur, reprise de la scène du héros : rayon 0,40, hauteur 1,70.
const RAYON: float = 0.40
const HAUTEUR: float = 1.70
const PAS: float = 0.5
## Cellule du contrôle A. 0,5 m était PLUS FIN que le maillage lui-même : à
## 22 azimuts pour 2,25 m de rayon, deux sommets voisins de l'anneau de base
## sont distants de 0,64 m, et une cellule de 0,5 m pouvait donc ne contenir
## aucun sommet bas alors que la masse touche le sol de part et d'autre. Le
## contrôle mesurait l'échantillonnage du maillage, pas son assise — troisième
## faux positif de cette sonde, et le plus instructif : un instrument plus fin
## que son sujet ne mesure que lui-même.
const PAS_ASSISE: float = 1.2
## Tolérance de contact pierre/sol. 2 cm : au-delà, un œil voit le jour sous
## une masse à trois mètres.
const TOLERANCE_ASSISE: float = 0.02
## Au-dessus de cette hauteur, une cellule sans contact est un SURPLOMB et non
## un jour — voir la note de l'en-tête, et le faux positif qui l'a produite.
const PLAFOND_SURPLOMB: float = 0.60

var _out: String = "res://sonde_source.json"
var _place: WorldV2Place = null
var _monde: Node = null
var _ecarts: Array[String] = []


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_run()


func _run() -> void:
	var packed: PackedScene = load("res://scenes/world_v2/WorldV2.tscn") \
		as PackedScene
	if packed == null:
		printerr("[sonde] BLOQUÉ : WorldV2.tscn introuvable")
		quit(3)
		return
	_monde = packed.instantiate()
	root.add_child(_monde)
	if not _monde.is_node_ready():
		await _monde.ready
	for i: int in range(45):
		await process_frame
	_place = _trouver(_monde)
	if _place == null:
		printerr("[sonde] ÉCHEC : lieu non monté")
		quit(2)
		return

	var doc: Dictionary = {}
	doc["A_assise_masses"] = _controle_assise()
	doc["B_bandes_eau"] = _controle_eau()
	doc["C_marche"] = await _controle_marche()
	doc["D_bandes_creusees"] = _controle_bandes()
	doc["ecarts"] = _ecarts
	doc["verdict"] = "PASS" if _ecarts.is_empty() else "FAIL"

	var f: FileAccess = FileAccess.open(_out, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(doc, "  "))
		f.close()
	print("[sonde] === %s === %d écart(s)" % [doc["verdict"], _ecarts.size()])
	for e: String in _ecarts:
		print("[sonde] ÉCART %s" % e)
	print("[sonde] -> %s" % _out)
	quit(0 if _ecarts.is_empty() else 1)


## A — chaque masse de roche touche le sol PARTOUT sous son emprise.
func _controle_assise() -> Array:
	var lignes: Array = []
	for nom: String in ["Contrefort_sud", "Levre_arrivee", "Table_nord",
			"Seuil_deversoir"]:
		var noeud: Node = _place.find_child(nom, true, false)
		if noeud == null:
			_ecarts.append("A : masse %s absente de la scène montée" % nom)
			continue
		var bas: Dictionary = _plus_bas_par_cellule(noeud as Node3D)
		var pire: float = -999.0
		var pire_cle: String = ""
		var cellules: int = 0
		var surplombs: int = 0
		for cle: Vector2i in bas.keys():
			cellules += 1
			var p: Vector3 = bas[cle] as Vector3
			var sol: float = _place.ground_local_y(p.x, p.z)
			var jour: float = p.y - sol
			if jour > PLAFOND_SURPLOMB:
				surplombs += 1
				continue
			if jour > pire:
				pire = jour
				pire_cle = "(%.2f ; %.2f)" % [p.x, p.z]
		lignes.append({"masse": nom, "cellules": cellules,
			"cellules_en_surplomb": surplombs,
			"jour_max_m": snappedf(pire, 0.001), "ou": pire_cle})
		if pire > TOLERANCE_ASSISE:
			_ecarts.append(("A : %s montre %.3f m de jour sous elle en %s "
				+ "(tolérance %.2f) — jupe trop courte ou lobe posé sur un "
				+ "terrain plus bas que son plan de pose")
				% [nom, pire, pire_cle, TOLERANCE_ASSISE])
	return lignes


## B — l'eau ne passe jamais SOUS le terrain ; la berge ne flotte jamais.
func _controle_eau() -> Array:
	var lignes: Array = []
	var bandes: Dictionary = {
		"FondVasque": Vector2(-0.10, 0.75),
		"NappeSource": Vector2(-0.06, 3.85),
	}
	for nom: String in bandes.keys():
		var noeud: MeshInstance3D = _place.find_child(nom, true, false) \
			as MeshInstance3D
		if noeud == null:
			_ecarts.append("B : maillage %s absent" % nom)
			continue
		var bande: Vector2 = bandes[nom] as Vector2
		var mini: float = 999.0
		var maxi: float = -999.0
		var n: int = 0
		for sommet: Vector3 in _sommets(noeud):
			var ecart: float = sommet.y - _place.ground_local_y(sommet.x,
				sommet.z)
			mini = minf(mini, ecart)
			maxi = maxf(maxi, ecart)
			n += 1
		lignes.append({"maillage": nom, "sommets": n,
			"au_dessus_du_sol_min_m": snappedf(mini, 0.001),
			"au_dessus_du_sol_max_m": snappedf(maxi, 0.001),
			"bande": [bande.x, bande.y]})
		if mini < bande.x:
			_ecarts.append("B : %s descend à %.3f m sous le sol (plancher %.2f)"
				% [nom, mini, bande.x])
		if maxi > bande.y:
			_ecarts.append("B : %s monte à %.3f m au-dessus du sol (plafond %.2f)"
				% [nom, maxi, bande.y])
	return lignes


## C — un joueur atteint-il réellement l'eau, la récompense et les deux rives ?
func _controle_marche() -> Dictionary:
	var espace: PhysicsDirectSpaceState3D = \
		(_monde as Node3D).get_world_3d().direct_space_state
	var forme: CapsuleShape3D = CapsuleShape3D.new()
	forme.radius = RAYON
	forme.height = HAUTEUR
	var requete: PhysicsShapeQueryParameters3D = \
		PhysicsShapeQueryParameters3D.new()
	requete.shape = forme
	requete.collide_with_areas = false
	requete.collide_with_bodies = true

	var libre: Dictionary = {}
	var x: float = -13.0
	while x <= 8.001:
		var z: float = -10.0
		while z <= 10.001:
			var y: float = _place.ground_local_y(x, z) + HAUTEUR * 0.5 + RAYON
			requete.transform = Transform3D(Basis.IDENTITY,
				_place.to_global(Vector3(x, y, z)))
			var touche: Array[Dictionary] = espace.intersect_shape(requete, 1)
			libre[_cle(x, z)] = touche.is_empty()
			z += PAS
		x += PAS

	# Remplissage depuis l'EST — le côté par lequel on arrive.
	var depart: Vector2i = _cle(7.5, 0.0)
	var vus: Dictionary = {}
	var pile: Array[Vector2i] = []
	if libre.get(depart, false):
		pile.append(depart)
		vus[depart] = true
	while not pile.is_empty():
		var c: Vector2i = pile.pop_back()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1),
				Vector2i(0, -1)]:
			var v: Vector2i = c + d
			if vus.has(v) or not bool(libre.get(v, false)):
				continue
			vus[v] = true
			pile.append(v)

	# CIBLES CHOISIES HORS DES BOÎTES DE COLLISION — le premier jet les avait
	# posées DANS la roche et le contrôle rougissait sur son propre choix, pas
	# sur le lieu. Les emprises des cinq boîtes sont recopiées dans le journal.
	var cibles: Dictionary = {
		"ancre_de_recompense": Vector2(-2.4, 2.6),
		"rive_est_de_la_vasque": Vector2(-1.0, -1.0),
		"rive_sud_sous_le_contrefort": Vector2(-7.5, 7.5),
		"nord_au_dela_de_la_table": Vector2(-6.0, -9.0),
		"ouest_pres_du_voile": Vector2(-7.8, -0.6),
	}
	# TÉMOIN NÉGATIF : ce point est au CŒUR du contrefort. S'il devient
	# joignable, les colliders ne collent plus rien et tout le contrôle C ne
	# vaut plus rien — un filet qui ne peut pas rougir ne prouve rien.
	var temoin: Vector2 = Vector2(-9.9, 4.0)
	var atteintes: Dictionary = {}
	for nom: String in cibles.keys():
		var p: Vector2 = cibles[nom] as Vector2
		var c: Vector2i = _cle(p.x, p.y)
		var ok: bool = vus.has(c)
		atteintes[nom] = ok
		if not ok:
			var raison: String = "occupée par %s" % _qui_bloque(espace, forme,
				p) if not bool(libre.get(c, false)) else "libre mais ENFERMÉE"
			_ecarts.append("C : %s (%.1f ; %.1f) n'est pas joignable depuis "
				% [nom, p.x, p.y] + "l'est — case %s" % raison)
	var temoin_joignable: bool = vus.has(_cle(temoin.x, temoin.y))
	if temoin_joignable:
		_ecarts.append(("C : TÉMOIN NÉGATIF ATTEINT — le cœur du contrefort "
			+ "(%.1f ; %.1f) est joignable à pied. Les colliders ne bloquent "
			+ "rien, et le reste du contrôle C ne prouve donc rien.")
			% [temoin.x, temoin.y])
	var total: int = libre.size()
	var libres: int = 0
	for v: bool in libre.values():
		if v:
			libres += 1
	return {"cases": total, "cases_libres": libres,
		"cases_joignables_depuis_l_est": vus.size(), "cibles": atteintes,
		"temoin_negatif_coeur_du_contrefort_joignable": temoin_joignable}


## D — colliders contre les bandes creusées, et portée réelle de la langue.
func _controle_bandes() -> Dictionary:
	var heightmap: Object = _chercher_heightmap(_monde)
	var trib: PackedVector2Array = PackedVector2Array()
	var principal: PackedVector2Array = PackedVector2Array()
	if heightmap != null:
		trib = heightmap.call("river_trib_polyline") as PackedVector2Array
		principal = heightmap.call("river_main_polyline") as PackedVector2Array
	# UN HEIGHTMAP INTROUVABLE DOIT ÉCHOUER. Le premier jet rendait des
	# distances de 995 à 997 m — `_distance_polyligne` sur une polyligne VIDE
	# rend 999, et le contrôle passait donc au vert en n'ayant rien mesuré.
	# C'est exactement le test qui ne peut pas rougir : il ne rougissait pas
	# même quand il n'avait pas ses données.
	if trib.size() < 2 or principal.size() < 2:
		_ecarts.append(("D : polylignes d'eau INTROUVABLES (affluent %d pts, "
			+ "cours principal %d pts) — le contrôle n'a rien mesuré et ne "
			+ "vaut pas un vert") % [trib.size(), principal.size()])
	var bande_trib: float = WorldV2Heightmap.TRIB_BED_HALF_W \
		+ WorldV2Heightmap.TRIB_BANK_W
	var bande_main: float = WorldV2Heightmap.RIVER_BED_HALF_W \
		+ WorldV2Heightmap.RIVER_BANK_W
	var colliders: Array = []
	for corps: Node in _place.find_children("*", "StaticBody3D", true, false):
		for f: Node in (corps as StaticBody3D).find_children("*",
				"CollisionShape3D", false, false):
			var forme: CollisionShape3D = f as CollisionShape3D
			var boite: BoxShape3D = forme.shape as BoxShape3D
			if boite == null:
				continue
			var centre: Vector3 = forme.global_transform.origin
			var rayon: float = boite.size.length() * 0.5
			var d_trib: float = _distance_polyligne(
				Vector2(centre.x, centre.z), trib) - rayon
			var d_main: float = _distance_polyligne(
				Vector2(centre.x, centre.z), principal) - rayon
			colliders.append({"corps": corps.name,
				"distance_affluent_m": snappedf(d_trib, 0.01),
				"distance_cours_principal_m": snappedf(d_main, 0.01)})
			if d_trib < bande_trib:
				_ecarts.append("D : %s à %.2f m de l'affluent (bande %.1f m)"
					% [corps.name, d_trib, bande_trib])
			if d_main < bande_main:
				_ecarts.append("D : %s à %.2f m du cours principal (bande %.1f)"
					% [corps.name, d_main, bande_main])
	# Portée de la langue : le sommet d'eau le plus proche de la tête gelée.
	var tete: Vector2 = trib[0] if trib.size() > 0 else Vector2(-130.0, 34.0)
	var nappe: MeshInstance3D = _place.find_child("NappeSource", true, false) \
		as MeshInstance3D
	var plus_proche: float = 999.0
	if nappe != null:
		for sommet: Vector3 in _sommets(nappe):
			var monde: Vector3 = _place.to_global(sommet)
			plus_proche = minf(plus_proche,
				Vector2(monde.x, monde.z).distance_to(tete))
	return {"bande_affluent_m": bande_trib, "bande_cours_principal_m":
		bande_main, "colliders": colliders,
		"tete_affluent": [tete.x, tete.y],
		"eau_la_plus_proche_de_la_tete_m": snappedf(plus_proche, 0.01)}


## ── OUTILS ───────────────────────────────────────────────────────────────

## QUI bloque cette case ? Sans le nom, un écart de marche ne dit pas s'il
## vient de ce lieu ou d'un rocher du semis V2.2 gelé — et on ne corrige pas
## la même chose dans les deux cas.
func _qui_bloque(espace: PhysicsDirectSpaceState3D, forme: CapsuleShape3D,
		p: Vector2) -> String:
	var requete: PhysicsShapeQueryParameters3D = \
		PhysicsShapeQueryParameters3D.new()
	requete.shape = forme
	requete.collide_with_areas = false
	var y: float = _place.ground_local_y(p.x, p.y) + HAUTEUR * 0.5 + RAYON
	requete.transform = Transform3D(Basis.IDENTITY,
		_place.to_global(Vector3(p.x, y, p.y)))
	var noms: Array[String] = []
	for touche: Dictionary in espace.intersect_shape(requete, 4):
		var corps: Object = touche.get("collider")
		if corps is Node:
			var n: Node = corps as Node
			var proprio: String = "monde gelé"
			var parent: Node = n
			while parent != null:
				if parent == _place:
					proprio = "CE LIEU"
					break
				parent = parent.get_parent()
			noms.append("%s [%s]" % [n.name, proprio])
	return ", ".join(noms) if not noms.is_empty() else "rien d'identifié"


func _cle(x: float, z: float) -> Vector2i:
	return Vector2i(int(roundf(x / PAS)), int(roundf(z / PAS)))


func _cle_assise(x: float, z: float) -> Vector2i:
	return Vector2i(int(floorf(x / PAS_ASSISE)), int(floorf(z / PAS_ASSISE)))


## Sommets d'un maillage, en coordonnées LOCALES du lieu.
func _sommets(instance: MeshInstance3D) -> Array[Vector3]:
	var sortie: Array[Vector3] = []
	if instance.mesh == null:
		return sortie
	var vers_lieu: Transform3D = _place.global_transform.affine_inverse() \
		* instance.global_transform
	for surface: int in range(instance.mesh.get_surface_count()):
		var tableaux: Array = instance.mesh.surface_get_arrays(surface)
		var points: PackedVector3Array = \
			tableaux[Mesh.ARRAY_VERTEX] as PackedVector3Array
		for p: Vector3 in points:
			sortie.append(vers_lieu * p)
	return sortie


## Sommet le plus BAS de chaque cellule de 0,5 m, sous un sous-arbre.
func _plus_bas_par_cellule(racine: Node3D) -> Dictionary:
	var bas: Dictionary = {}
	for noeud: Node in racine.find_children("*", "MeshInstance3D", true, false):
		for p: Vector3 in _sommets(noeud as MeshInstance3D):
			var cle: Vector2i = _cle_assise(p.x, p.z)
			if not bas.has(cle) or (bas[cle] as Vector3).y > p.y:
				bas[cle] = p
	if racine is MeshInstance3D:
		for p: Vector3 in _sommets(racine as MeshInstance3D):
			var cle: Vector2i = _cle_assise(p.x, p.z)
			if not bas.has(cle) or (bas[cle] as Vector3).y > p.y:
				bas[cle] = p
	return bas


func _distance_polyligne(p: Vector2, ligne: PackedVector2Array) -> float:
	if ligne.size() < 2:
		return 999.0
	var mini: float = 999.0
	for i: int in range(ligne.size() - 1):
		mini = minf(mini, _distance_segment(p, ligne[i], ligne[i + 1]))
	return mini


func _distance_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var l2: float = ab.length_squared()
	if l2 < 1e-6:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Le heightmap n'est PAS un nœud : c'est un `RefCounted` que la scène du
## monde porte dans sa propriété `_heightmap` (même accès que
## `test_world_v2_places_contract.gd::_mount`). Le chercher parmi les nœuds
## ne pouvait donc jamais aboutir — et c'est ce qui a produit le faux vert.
func _chercher_heightmap(noeud: Node) -> Object:
	var direct: Variant = noeud.get("_heightmap")
	if direct != null and (direct as Object).has_method("river_trib_polyline"):
		return direct as Object
	if noeud.has_method("river_trib_polyline"):
		return noeud
	for enfant: Node in noeud.get_children():
		var trouve: Object = _chercher_heightmap(enfant)
		if trouve != null:
			return trouve
	return null


func _trouver(noeud: Node) -> WorldV2Place:
	if noeud is WorldV2Place:
		var place: WorldV2Place = noeud as WorldV2Place
		if place.place_id() == PLACE_ID:
			return place
	for enfant: Node in noeud.get_children():
		var trouve: WorldV2Place = _trouver(enfant)
		if trouve != null:
			return trouve
	return null
