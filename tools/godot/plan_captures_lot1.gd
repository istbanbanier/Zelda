## PLAN DE CAPTURES du lot 1 — les caméras sont DÉRIVÉES, jamais tapées.
##
## POURQUOI UN GÉNÉRATEUR ET PAS UN `shots.json` ÉCRIT À LA MAIN. Une caméra
## posée à la main est irreproductible : personne ne saura, dans trois
## semaines, si le cadrage a changé parce que le lieu a bougé ou parce que la
## main a tremblé. Ici chaque plan découle de deux choses que le dépôt possède
## déjà — le `v2_site` du layout et l'emprise réelle du lieu monté — par une
## règle écrite. Relancer le générateur sur le même commit redonne les mêmes
## nombres ; sur un lieu modifié, il redonne un cadrage juste.
##
## TROIS VUES PAR SUJET, et la raison de chacune :
##
##   `_lecture`  la vue de RELATION : le lieu dans son terrain, cadré depuis
##               la direction d'où le joueur arrive — c'est-à-dire depuis le
##               point le plus proche d'une route contractuelle. Distance et
##               hauteur dérivées de l'emprise, pas d'un goût.
##   `_joueur`   la vue JOUEUR, exigée par le contrat §2.9. Ce n'est pas une
##               belle vue : c'est LA vue, aux valeurs réelles du jeu —
##               `camera_distance = 4,3`, `camera_target_height = 1,45`,
##               `camera_fov = 44,0` (`resources/tuning/locomotion_default.tres`).
##               Un lieu qui ne tient pas dans ce cadre-là ne tient pas.
##   `_assise`   la vue RASANTE, presque à hauteur de sol. C'est celle qui
##               démasque un plan peint tenu pour un volume, et une fondation
##               qui ne touche pas le terrain. `PROMPT4_METHOD` §3 étape 5 :
##               « une seule belle image ne prouve rien ».
##
## Écrit aussi la liste des silhouettes à capturer (`silhouettes.json`), qui
## alimente `tools/lot1_repetition.py` : sans elle, le détecteur D3 n'a rien à
## lire et son verdict manque, donc la suite rougit — c'est voulu.
##
## Usage :
##   tools/lancer_godot.sh --headless --path . \
##     --script tools/godot/plan_captures_lot1.gd -- \
##     --out-dir=evidence/world_v2/v2_3_b/lot1/plans
extends SceneTree

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"

## Les valeurs RÉELLES du jeu, recopiées de resources/tuning/locomotion_default.tres.
## Recopiées et non lues : si le réglage du jeu change, la vue joueur du lot 1
## doit être RECAPTURÉE et le constat doit se voir, pas se dissoudre.
const JOUEUR_DISTANCE_M: float = 4.3
const JOUEUR_HAUTEUR_M: float = 1.45
const JOUEUR_FOV_DEG: float = 44.0
## Vue de lecture : un cadrage plus large, mais toujours crédible.
const LECTURE_FOV_DEG: float = 50.0
## Distance de lecture = ce facteur × la plus grande dimension du lieu, borné
## bas pour qu'un tout petit lieu ne soit pas cadré au ras du nez.
const LECTURE_FACTEUR: float = 2.2
const LECTURE_DISTANCE_MIN_M: float = 12.0
## Vue rasante : l'œil presque au sol, à courte distance.
const ASSISE_HAUTEUR_M: float = 0.9
const ASSISE_FOV_DEG: float = 46.0
const ASSISE_FACTEUR: float = 1.3
const ASSISE_DISTANCE_MIN_M: float = 8.0

const LOT1: Array[StringName] = [
	&"valley.poi.watchtower_ruin.01",
	&"valley.poi.overlook_summit.01",
	&"valley.poi.turquoise_spring.01",
	&"valley.poi.forest_shrine.01",
	&"valley.poi.barrow_cemetery.01",
	&"valley.poi.flower_field.01",
]

var _out_dir: String = "evidence/world_v2/v2_3_b/lot1/plans"


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out-dir="):
			_out_dir = argument.trim_prefix("--out-dir=")
	var monde: Node3D = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(monde)
	for i: int in range(45):
		await process_frame
	var heightmap: WorldV2Heightmap = monde.call("heightmap") as WorldV2Heightmap

	var lieux: Dictionary = {}
	for noeud: Node in root.get_tree().get_nodes_in_group(&"world_v2_places"):
		lieux[noeud.get_meta(&"place_id", &"?") as StringName] = noeud as Node3D

	var plans: Array = []
	var silhouettes: Array = []
	var absents: Array[String] = []
	for id: StringName in LOT1:
		if not lieux.has(id):
			absents.append(String(id))
			continue
		var lieu: Node3D = lieux[id] as Node3D
		var emprise: AABB = _emprise(lieu)
		if emprise.size == Vector3.ZERO:
			absents.append(String(id) + " (sans géométrie)")
			continue
		var centre: Vector3 = emprise.get_center()
		var taille: float = maxf(maxf(emprise.size.x, emprise.size.z),
			emprise.size.y)
		# LA DIRECTION D'APPROCHE, dérivée : le point le plus proche d'une
		# route contractuelle. C'est par là que le joueur vient ; c'est donc
		# de là qu'un lieu doit se lire. À défaut de route proche, on se
		# rabat sur le centre du monde, et le plan le DIT.
		var approche: Dictionary = _approche(monde, lieu.global_position)
		var vers: Vector3 = approche["depuis"] as Vector3
		var direction: Vector3 = (vers - lieu.global_position)
		direction.y = 0.0
		if direction.length() < 0.01:
			direction = Vector3(0.0, 0.0, 1.0)
		direction = direction.normalized()
		var nom: String = String(id).replace("valley.poi.", "").replace(".01", "")

		# 1. VUE DE LECTURE
		var d_lecture: float = maxf(LECTURE_DISTANCE_MIN_M,
			taille * LECTURE_FACTEUR)
		var p_lecture: Vector3 = lieu.global_position + direction * d_lecture
		p_lecture.y = heightmap.height_at(p_lecture.x, p_lecture.z) \
			+ maxf(2.5, emprise.size.y * 0.55)
		plans.append(_plan("%s_lecture" % nom, p_lecture, centre,
			LECTURE_FOV_DEG, id,
			"relation du lieu à son terrain, depuis la direction d'approche (%s)"
			% String(approche["source"])))

		# 2. VUE JOUEUR — aux valeurs réelles du jeu.
		var pieds: Vector3 = vers
		pieds.y = heightmap.height_at(pieds.x, pieds.z)
		var oeil: Vector3 = pieds + direction * JOUEUR_DISTANCE_M
		oeil.y = heightmap.height_at(oeil.x, oeil.z) + JOUEUR_HAUTEUR_M
		var regard: Vector3 = Vector3(lieu.global_position.x,
			heightmap.height_at(lieu.global_position.x, lieu.global_position.z)
			+ minf(emprise.size.y * 0.5, 6.0), lieu.global_position.z)
		plans.append(_plan("%s_joueur" % nom, oeil, regard, JOUEUR_FOV_DEG, id,
			"VUE JOUEUR — distance 4,3 m, œil 1,45 m, FOV 44° (valeurs du jeu)"))

		# 3. VUE RASANTE — celle qui démasque un plan peint et une fondation
		# qui ne touche pas le sol.
		var d_assise: float = maxf(ASSISE_DISTANCE_MIN_M, taille * ASSISE_FACTEUR)
		var lateral: Vector3 = Vector3(-direction.z, 0.0, direction.x)
		var p_assise: Vector3 = lieu.global_position + lateral * d_assise
		p_assise.y = heightmap.height_at(p_assise.x, p_assise.z) + ASSISE_HAUTEUR_M
		var cible_assise: Vector3 = Vector3(lieu.global_position.x,
			heightmap.height_at(lieu.global_position.x, lieu.global_position.z)
			+ 1.0, lieu.global_position.z)
		plans.append(_plan("%s_rasante" % nom, p_assise, cible_assise,
			ASSISE_FOV_DEG, id,
			"vue rasante — assise sur le terrain, volume contre plan peint"))

		# 4. SILHOUETTE — trois angles, alimente le détecteur D3.
		silhouettes.append({
			"place_id": String(id), "nom": nom, "angles": "0,90,180",
			"taille": "900x1200",
		})

	_ecrire("%s/lot1_shots.json" % _out_dir, plans)
	_ecrire("%s/lot1_silhouettes.json" % _out_dir, silhouettes)
	print("[plan] %d plan(s) et %d silhouette(s) écrits sous %s"
		% [plans.size(), silhouettes.size(), _out_dir])
	if not absents.is_empty():
		# ÉCHEC, pas « ignoré » : un plan de captures amputé produirait une
		# planche crédible où il manque un sujet, et personne ne le verrait.
		printerr("[plan] ÉCHEC : %d sujet(s) du lot 1 sans plan — %s"
			% [absents.size(), ", ".join(absents)])
		quit(1)
		return
	quit(0)


func _plan(nom: String, depuis: Vector3, vers: Vector3, fov: float,
		place_id: StringName, prouve: String) -> Dictionary:
	return {
		"name": nom,
		"from": [snappedf(depuis.x, 0.01), snappedf(depuis.y, 0.01),
			snappedf(depuis.z, 0.01)],
		"look": [snappedf(vers.x, 0.01), snappedf(vers.y, 0.01),
			snappedf(vers.z, 0.01)],
		"fov": fov,
		"place_id": String(place_id),
		"proves": prouve,
	}


## Point d'approche : l'échantillon de route contractuelle le plus proche du
## lieu. Rend aussi la SOURCE, pour que le plan dise s'il s'est rabattu.
func _approche(monde: Node3D, site: Vector3) -> Dictionary:
	var meilleur: Vector3 = Vector3(0.0, 0.0, 0.0)
	var distance: float = 1.0e9
	for route: Node in monde.get_tree().get_nodes_in_group(&"world_v2_routes"):
		var jalons: Array = route.get_meta(&"waypoints_xz", []) as Array
		for jalon: Variant in jalons:
			var p: Vector3 = Vector3(float((jalon as Array)[0]), site.y,
				float((jalon as Array)[1]))
			var d: float = p.distance_to(site)
			if d < distance:
				distance = d
				meilleur = p
	if distance > 120.0:
		return {"depuis": Vector3(0.0, site.y, 0.0),
			"source": "aucune route à moins de 120 m — repli sur le centre du monde"}
	return {"depuis": meilleur,
		"source": "route la plus proche, à %.0f m" % distance}


func _emprise(lieu: Node3D) -> AABB:
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


func _ecrire(chemin: String, contenu: Array) -> void:
	var dossier: String = chemin.get_base_dir()
	if not DirAccess.dir_exists_absolute(dossier):
		DirAccess.make_dir_recursive_absolute(dossier)
	var fichier: FileAccess = FileAccess.open(chemin, FileAccess.WRITE)
	if fichier == null:
		printerr("[plan] écriture impossible : %s" % chemin)
		return
	fichier.store_string(JSON.stringify(contenu, "  "))
	fichier.close()
