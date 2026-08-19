## V2.3-A.R2B.1 — FILET de l'agent A : la FERME ABANDONNÉE doit se lire comme
## une ruine, pas comme une boîte.
##
## ORIGINE. Revue du lead (R2B.1) : « techniquement propre mais se lit comme
## une boîte beige inachevée ou un greybox ; murs rectangulaires lisses,
## charpente trop vide, peu de masse effondrée et presque aucune histoire
## structurelle visible ».
##
## LE DÉFAUT EST MESURÉ, jamais supposé. Sonde Godot du 2026-08-19 sur la
## scène montée seule :
##
##     ARASES : n=15 min=3.059 max=3.173 moy=3.142 ecart_type=0.050 m
##
## Les 11 modules de mur sont TOUS à 3,173 m, les 4 piliers de coin à 3,059 m :
## 5 cm d'écart-type sur 6,4 m de bâtiment. La maçonnerie ne casse nulle part,
## d'où le contour « rectangle + chapeau ». Et l'inspection glTF du module de
## kit `Wall_UnevenBrick_Straight` montre pourquoi les faces sont des cartons :
## `MI_UnevenBrick` est un plan STRICT à Z = 0,000 (4 tris), `MI_Plaster` un
## plan STRICT à Z = -0,200 (2 tris), sans aucune face de chant entre les deux.
##
## POURQUOI CE FICHIER EST SÉPARÉ de `test_world_v2_r2b_farm_tree.gd` :
## ce dernier couvre AUSSI l'arbre foudroyé, sujet d'un agent qui travaille en
## parallèle. Arbitrage du lead du 2026-08-19 : filet R2B laissé octet pour
## octet identique, filet R2B.1 dans son propre fichier. CONSÉQUENCE GRAVÉE —
## les cinq pièces `SM_Farm_*` de R2B ne peuvent pas être renommées, le filet
## R2B les désigne par leur nom ; le contrôle 8 ci-dessous le garde.
##
## Écrit ROUGE d'abord (2026-08-19) : au moment de son écriture, aucune des
## pièces attendues n'existe et l'écart-type des arases vaut 0,050 m. Chaque
## contrôle nomme l'écart qu'il constate.
extends GateTestCase

const FARM_SCENE: String = "res://scenes/world_v2/poi/AbandonedFarmPlace.tscn"
const FARM_GLB: String = "res://assets/architecture/farm/SM_Farm_Ruins.glb"

## Seuils du plan approuvé — littéraux recopiés, jamais lus depuis le code
## qu'ils surveillent (un test qui lit la valeur qu'il garde suit l'erreur).
##
## L'arase CASSE : sur une maçonnerie de ruine, la hauteur du couronnement
## varie. 0,45 m est neuf fois la dispersion mesurée avant le geste (0,050 m)
## et reste très en deçà de la portée d'un pignon (1,23 m au-dessus de l'arase).
const ARASE_ECART_TYPE_MIN_M: float = 0.45
## Au moins deux pans de maçonnerie ARRÊTÉS À MI-HAUTEUR : c'est ce qui
## distingue un mur écroulé d'un trou net entre deux murs pleins.
const ARASE_BASSE_MIN_M: float = 0.80
const ARASE_BASSE_MAX_M: float = 2.40
const ARASE_BASSE_COMPTE_MIN: int = 2
## Le pignon monte AU-DESSUS de l'arase (3,17 m mesurés) et son arrachement
## lui retire plus de 30 % de la portée : un pignon plein serait un mur de
## plus, pas une rupture.
const PIGNON_SOMMET_MIN_M: float = 3.40
## Asymétrie du faîte dans l'emprise, et nombre d'assises arrachées. Le
## générateur refuse d'enregistrer sous 0,12 et 3 ; le filet le revérifie sur
## le GLB IMPORTÉ, car un garde côté Blender ne dit rien de ce que Godot lit.
const PIGNON_ASYMETRIE_MIN: float = 0.12
const PIGNON_GRADINS_MIN: int = 3
const PIGNON_GRADIN_MIN_M: float = 0.132
const PORTEE_M: float = 6.00
## « Éviter les plans visiblement sans épaisseur » : toute pièce de maçonnerie
## ajoutée est un VOLUME, ses trois dimensions dépassent 0,30 m.
const EPAISSEUR_MIN_M: float = 0.30
## La masse effondrée obéit à la gravité : elle touche le sol, et elle gît au
## pied de la brèche, pas à l'autre bout du lieu.
const GRAVATS_SOL_MAX_M: float = 0.15
const GRAVATS_DISTANCE_BRECHE_MAX_M: float = 2.50
## L'intérieur n'est pas une coque : ossature verticale au-dessus de 1,20 m.
const INTERIEUR_HAUT_MIN_M: float = 1.20
const INTERIEUR_COMPTE_MIN: int = 4
## Demi-emprise intérieure de la fermette : les murs sont posés à ±3,00 m et
## portent 0,40 m d'épaisseur, le parement intérieur est donc à ±2,80 m. La
## marge à 2,95 laisse passer une pièce plaquée contre ce parement sans
## laisser entrer ce qui est dehors (charrette, arbres, buissons : tous
## au-delà de 3,15 m, sonde du 2026-08-19).
const INTERIEUR_DEMI_M: float = 2.95
## Un verger est un ALIGNEMENT, pas un arbre isolé.
const VERGER_ARBRES_MIN: int = 4
const VERGER_ALIGNES_MIN: int = 3
const VERGER_ECART_DROITE_MAX_M: float = 0.80
const VERGER_PAS_MIN_M: float = 3.00
const VERGER_PAS_MAX_M: float = 5.00
## Budget : le PLAFOND est celui déjà verrouillé dans le générateur et il ne
## bouge pas. Le PLANCHER dit qu'un geste a bien eu lieu — 676 tris avant.
const BUDGET_TRIS_MAX: int = 4500
const BUDGET_TRIS_MIN: int = 900
## Les cinq pièces R2B dont le filet de l'agent B dépend.
const PIECES_R2B: Array[String] = [
	"SM_Farm_Truss", "SM_Farm_RoofPan_Intact", "SM_Farm_RoofPan_Fallen",
	"SM_Farm_Debris_A", "SM_Farm_Debris_B",
]
## La face BRIQUE d'un module de kit est en +Z local. Elle doit regarder
## DEHORS. Mesuré le 2026-08-19 : avec `yaw` 90° et 270°, les murs ouest et
## est présentaient leur face PLÂTRE à l'extérieur — un quad de 6 m² en deux
## triangles, plein cadre sur `ferme_laterale`.
const BRIQUE_DEHORS_MARGE: float = 0.25


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _mount_alone(path: String) -> Node3D:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	var place: Node3D = packed.instantiate() as Node3D
	if place == null:
		return null
	_tree().root.add_child(place)
	return place


func _dismount(place: Node3D) -> void:
	if place != null:
		place.get_parent().remove_child(place)
		place.queue_free()


func _capped(faults: Array[String], keep: int = 6) -> String:
	if faults.size() <= keep:
		return " ; ".join(faults)
	return " ; ".join(faults.slice(0, keep)) \
		+ " ; (+%d autres)" % (faults.size() - keep)


## AABB d'un sous-arbre EXPRIMÉE dans le repère de `frame`.
##
## PIÈGE MESURÉ le 2026-08-19. `Transform3D * AABB` rend l'AABB alignée sur
## les axes qui ENGLOBE la boîte transformée. Prendre l'AABB monde d'une pièce
## puis lui appliquer l'inverse du repère de la maison la regonfle donc DEUX
## fois par la rotation de 25° du bâtiment : une ossature de 0,47 m d'épaisseur
## se mesurait à 4,55 m, et le contrôle d'intérieur ne trouvait plus rien.
## Il faut composer les transforms AVANT de toucher à la boîte.
func _bounds_in(node: Node3D, frame: Node3D) -> AABB:
	var inverse: Transform3D = frame.global_transform.affine_inverse()
	var merged: AABB = AABB()
	var first: bool = true
	var targets: Array[Node] = node.find_children("*", "MeshInstance3D",
		true, false)
	if node is MeshInstance3D:
		targets.append(node)
	for child: Node in targets:
		var instance: MeshInstance3D = child as MeshInstance3D
		if instance.mesh == null:
			continue
		var box: AABB = (inverse * instance.global_transform) \
			* instance.get_aabb()
		if first:
			merged = box
			first = false
		else:
			merged = merged.merge(box)
	return merged


## AABB globale des maillages d'un sous-arbre.
func _bounds(node: Node3D) -> AABB:
	var merged: AABB = AABB()
	var first: bool = true
	var targets: Array[Node] = node.find_children("*", "MeshInstance3D",
		true, false)
	if node is MeshInstance3D:
		targets.append(node)
	for child: Node in targets:
		var instance: MeshInstance3D = child as MeshInstance3D
		if instance.mesh == null:
			continue
		var box: AABB = instance.global_transform * instance.get_aabb()
		if first:
			merged = box
			first = false
		else:
			merged = merged.merge(box)
	return merged


## Premier descendant dont le nom COMMENCE par `prefix`, ou null.
func _named_child(root: Node3D, prefix: String) -> Node3D:
	for child: Node in root.find_children("*", "Node3D", true, false):
		if String(child.name).begins_with(prefix):
			return child as Node3D
	return null


## Toutes les pièces de MAÇONNERIE du lieu : modules de mur du kit et pièces
## de pierre du GLB de ruine. Ce sont elles qui portent la ligne d'arase.
func _masonry(place: Node3D) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for child: Node in place.find_children("*", "Node3D", true, false):
		var name: String = String(child.name)
		if name.begins_with("Wall_UnevenBrick") \
				or name.begins_with("SM_Farm_GableBreak") \
				or name.begins_with("SM_Farm_WallStub"):
			out.append(child as Node3D)
	return out


## -- 1. L'arase de maçonnerie CASSE ------------------------------------------
##
## Avant le geste : écart-type 0,050 m sur 15 pièces. Une ligne droite.

func test_l_arase_de_maconnerie_casse() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	if place == null:
		faults.append("la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var tops: Array[float] = []
		for piece: Node3D in _masonry(place):
			var box: AABB = _bounds(piece)
			if box.size == Vector3.ZERO:
				continue
			tops.append(box.end.y)
		if tops.size() < 8:
			faults.append("%d pièce(s) de maçonnerie seulement — le contrôle "
				% tops.size() + "ne regarde rien")
		else:
			var sum: float = 0.0
			for top: float in tops:
				sum += top
			var mean: float = sum / float(tops.size())
			var variance: float = 0.0
			for top: float in tops:
				variance += (top - mean) * (top - mean)
			var deviation: float = sqrt(variance / float(tops.size()))
			if deviation < ARASE_ECART_TYPE_MIN_M:
				faults.append("l'arase est une LIGNE DROITE : écart-type "
					+ "%.3f m sur %d pièces (min %.2f)"
					% [deviation, tops.size(), ARASE_ECART_TYPE_MIN_M])
		_dismount(place)
	check(faults.is_empty(),
		"l'arase de maçonnerie casse (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (arase) — %s" % restore_root_reason())


## -- 2. Des pans de mur s'arrêtent à MI-HAUTEUR -------------------------------
##
## Avant le geste : ZÉRO. Tout est à 3,17 m ou 3,06 m ; le seul manque est un
## vide net de 2,00 m au mur est — un trou, pas un arrachement.

func test_des_pans_de_mur_s_arretent_a_mi_hauteur() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	if place == null:
		faults.append("la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var low: int = 0
		for piece: Node3D in _masonry(place):
			var box: AABB = _bounds(piece)
			if box.size == Vector3.ZERO:
				continue
			if box.end.y >= ARASE_BASSE_MIN_M and box.end.y <= ARASE_BASSE_MAX_M:
				low += 1
		if low < ARASE_BASSE_COMPTE_MIN:
			faults.append("%d pan(s) de maçonnerie arrêté(s) entre %.2f et "
				% [low, ARASE_BASSE_MIN_M]
				+ "%.2f m (min %d) — un mur écroulé ne se distingue pas d'un "
				% [ARASE_BASSE_MAX_M, ARASE_BASSE_COMPTE_MIN]
				+ "trou entre deux murs pleins")
		_dismount(place)
	check(faults.is_empty(),
		"des pans de mur s'arrêtent à mi-hauteur (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (pans bas) — %s" % restore_root_reason())


## -- 3. Le pignon est ROMPU, et c'est un volume ------------------------------

func test_le_pignon_est_rompu_et_massif() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	if place == null:
		faults.append("la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var gable: Node3D = _named_child(place, "SM_Farm_GableBreak")
		if gable == null:
			faults.append("aucun pignon SM_Farm_GableBreak — rien ne rompt la "
				+ "ligne du toit")
		else:
			var box: AABB = _bounds(gable)
			if box.end.y < PIGNON_SOMMET_MIN_M:
				faults.append("le pignon culmine à %.2f m, sous l'arase des "
					% box.end.y + "murs (min %.2f)" % PIGNON_SOMMET_MIN_M)
			var span: float = maxf(box.size.x, box.size.z)
			# ASYMÉTRIE et GRADINS, mesurés sur les SOMMETS.
			#
			# Une première version mesurait la largeur des sous-maillages :
			# elle ne pouvait PAS rougir, le pignon étant un maillage unique
			# dont l'AABB vaut toujours son emprise entière (5,11 m mesurés,
			# arraché comme intact). Un contrôle qui ne distingue pas les deux
			# cas ne contrôle rien — d'où cette mesure-ci, la même que celle
			# dont le générateur se sert pour refuser d'enregistrer :
			#   * sur un pignon intact, le faîte est au MILIEU de l'emprise ;
			#     un rampant emporté décale le milieu sans bouger le faîte ;
			#   * une maçonnerie se rompt par LITS DE POSE : compter les
			#     chutes verticales du profil supérieur, c'est compter les
			#     assises arrachées. Un triangle intact n'en a aucune.
			var profile: Dictionary = {}
			var peak_x: float = 0.0
			var peak_y: float = -1e9
			var min_x: float = 1e9
			var max_x: float = -1e9
			for child: Node in gable.find_children("*", "MeshInstance3D",
					true, false):
				var instance: MeshInstance3D = child as MeshInstance3D
				if instance.mesh == null:
					continue
				for surface: int in range(instance.mesh.get_surface_count()):
					var arrays: Array = instance.mesh.surface_get_arrays(surface)
					if arrays.size() <= Mesh.ARRAY_VERTEX \
							or arrays[Mesh.ARRAY_VERTEX] == null:
						continue
					for raw: Vector3 in arrays[Mesh.ARRAY_VERTEX] \
							as PackedVector3Array:
						var v: Vector3 = instance.global_transform * raw
						min_x = minf(min_x, v.x)
						max_x = maxf(max_x, v.x)
						if v.y > peak_y:
							peak_y = v.y
							peak_x = v.x
						var key: float = snappedf(v.x, 0.01)
						profile[key] = maxf(profile.get(key, -1e9), v.y)
			var half_span: float = (max_x - min_x) * 0.5
			var asymmetry: float = 0.0
			if half_span > 0.01:
				asymmetry = absf(peak_x - (min_x + max_x) * 0.5) / half_span
			var keys: Array = profile.keys()
			keys.sort()
			var steps: int = 0
			for i: int in range(1, keys.size()):
				if float(profile[keys[i - 1]]) - float(profile[keys[i]]) \
						>= PIGNON_GRADIN_MIN_M:
					steps += 1
			if asymmetry < PIGNON_ASYMETRIE_MIN:
				faults.append("le pignon est SYMÉTRIQUE (asymétrie %.3f, min "
					% asymmetry + "%.2f) — un pignon intact est un mur de "
					% PIGNON_ASYMETRIE_MIN + "plus, pas une rupture")
			if steps < PIGNON_GRADINS_MIN:
				faults.append("%d gradin(s) d'arrachement (min %d) — une "
					% [steps, PIGNON_GRADINS_MIN] + "maçonnerie se rompt par "
					+ "lits de pose, pas en diagonale lisse")
			# Épaisseur mesurée dans le repère de la PIÈCE : en monde, la
			# rotation du bâtiment gonflerait la boîte et un plan pourrait
			# passer pour un volume.
			var own: AABB = _bounds_in(gable, gable)
			var thinnest: float = minf(own.size.x, minf(own.size.y, own.size.z))
			if thinnest < EPAISSEUR_MIN_M:
				faults.append("le pignon est un PLAN : dimension la plus fine "
					+ "%.3f m (min %.2f)" % [thinnest, EPAISSEUR_MIN_M])
			if span < 1.0:
				faults.append("le pignon ne couvre que %.2f m de portée" % span)
		_dismount(place)
	check(faults.is_empty(),
		"le pignon est rompu et massif (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (pignon) — %s" % restore_root_reason())


## -- 4. La masse effondrée gît au pied de la brèche --------------------------

func test_la_masse_effondree_git_au_pied_de_la_breche() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	if place == null:
		faults.append("la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var rubble: Node3D = _named_child(place, "SM_Farm_Rubble_Wall")
		var stub: Node3D = _named_child(place, "SM_Farm_WallStub")
		if rubble == null:
			faults.append("aucun talus SM_Farm_Rubble_Wall — la matière du "
				+ "mur écroulé n'est nulle part")
		if stub == null:
			faults.append("aucun moignon SM_Farm_WallStub — la brèche est un "
				+ "trou net, pas un arrachement")
		if rubble != null:
			var box: AABB = _bounds(rubble)
			if box.position.y > GRAVATS_SOL_MAX_M:
				faults.append("le talus FLOTTE : point bas à %.2f m (max %.2f)"
					% [box.position.y, GRAVATS_SOL_MAX_M])
			var own_rubble: AABB = _bounds_in(rubble, rubble)
			var thinnest: float = minf(own_rubble.size.x,
				minf(own_rubble.size.y, own_rubble.size.z))
			if thinnest < EPAISSEUR_MIN_M:
				faults.append("le talus est un PLAN : dimension la plus fine "
					+ "%.3f m (min %.2f)" % [thinnest, EPAISSEUR_MIN_M])
			if stub != null:
				var stub_box: AABB = _bounds(stub)
				var a: Vector2 = Vector2(box.get_center().x, box.get_center().z)
				var b: Vector2 = Vector2(stub_box.get_center().x,
					stub_box.get_center().z)
				if a.distance_to(b) > GRAVATS_DISTANCE_BRECHE_MAX_M:
					faults.append("le talus gît à %.2f m de la brèche "
						% a.distance_to(b) + "(max %.2f) — la conséquence "
						% GRAVATS_DISTANCE_BRECHE_MAX_M + "n'est pas au pied "
						+ "de la cause")
		_dismount(place)
	check(faults.is_empty(),
		"la masse effondrée gît au pied de la brèche (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (masse effondrée) — %s"
		% restore_root_reason())


## -- 5. L'intérieur n'est pas une coque vide ---------------------------------
##
## Compte les maillages dont l'AABB tient ENTIÈREMENT dans le polygone des
## murs et qui montent au-dessus de 1,20 m — hors murs, toiture et charpente,
## qui ne sont pas de l'ossature intérieure. Avant le geste : ZÉRO.

func test_l_interieur_n_est_pas_une_coque_vide() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	if place == null:
		faults.append("la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var house: Node3D = _named_child(place, "Fermette")
		if house == null:
			faults.append("aucun nœud Fermette")
		else:
			var inside: int = 0
			for child: Node in place.find_children("*", "MeshInstance3D",
					true, false):
				var instance: MeshInstance3D = child as MeshInstance3D
				if instance.mesh == null:
					continue
				var owner_name: String = String(instance.get_parent().name)
				if owner_name.begins_with("Wall_") \
						or owner_name.begins_with("Corner_") \
						or owner_name.begins_with("SM_Farm_Roof") \
						or owner_name.begins_with("SM_Farm_Truss") \
						or owner_name.begins_with("SM_Farm_GableBreak") \
						or owner_name.begins_with("Socle") \
						or owner_name.begins_with("SocleAssise"):
					continue
				var box: AABB = instance.global_transform * instance.get_aabb()
				var local_box: AABB = _bounds_in(instance, house)
				if absf(local_box.position.x) > INTERIEUR_DEMI_M \
						or absf(local_box.end.x) > INTERIEUR_DEMI_M \
						or absf(local_box.position.z) > INTERIEUR_DEMI_M \
						or absf(local_box.end.z) > INTERIEUR_DEMI_M:
					continue
				if box.end.y <= INTERIEUR_HAUT_MIN_M:
					continue
				inside += 1
			if inside < INTERIEUR_COMPTE_MIN:
				faults.append("%d élément(s) d'ossature intérieure au-dessus "
					% inside + "de %.2f m (min %d) — l'intérieur est une coque"
					% [INTERIEUR_HAUT_MIN_M, INTERIEUR_COMPTE_MIN])
		_dismount(place)
	check(faults.is_empty(),
		"l'intérieur porte une ossature (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (intérieur) — %s" % restore_root_reason())


## -- 6. Le verger est un ALIGNEMENT ------------------------------------------

func test_le_verger_est_un_alignement() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	if place == null:
		faults.append("la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var trees: Array[Vector2] = []
		for child: Node in place.find_children("*", "Node3D", true, false):
			if not String(child.name).begins_with("CommonTree"):
				continue
			# Même piège que pour les murs : le GLB du kit porte un enfant
			# homonyme, et sans ce filtre CHAQUE arbre compte deux fois. Deux
			# points confondus donnent un pas de 0 m et cassent toute
			# détection de rang régulier — le contrôle ne pouvait pas passer.
			if String(child.get_parent().name).begins_with("CommonTree"):
				continue
			var box: AABB = _bounds(child as Node3D)
			if box.size == Vector3.ZERO:
				continue
			trees.append(Vector2(box.get_center().x, box.get_center().z))
		if trees.size() < VERGER_ARBRES_MIN:
			faults.append("%d arbre(s) (min %d) — un arbre isolé n'est pas un "
				% [trees.size(), VERGER_ARBRES_MIN] + "verger")
		else:
			var best: int = 0
			for i: int in range(trees.size()):
				for j: int in range(trees.size()):
					if i == j:
						continue
					var axis: Vector2 = trees[j] - trees[i]
					if axis.length() < 0.01:
						continue
					var dir: Vector2 = axis.normalized()
					var aligned: Array[float] = []
					for k: int in range(trees.size()):
						var delta: Vector2 = trees[k] - trees[i]
						var across: float = absf(delta.x * dir.y
							- delta.y * dir.x)
						if across <= VERGER_ECART_DROITE_MAX_M:
							aligned.append(delta.dot(dir))
					if aligned.size() < VERGER_ALIGNES_MIN:
						continue
					aligned.sort()
					var regular: bool = true
					for s: int in range(aligned.size() - 1):
						var step: float = aligned[s + 1] - aligned[s]
						if step < VERGER_PAS_MIN_M or step > VERGER_PAS_MAX_M:
							regular = false
							break
					if regular:
						best = maxi(best, aligned.size())
			if best < VERGER_ALIGNES_MIN:
				faults.append("aucun rang régulier : au mieux %d arbre(s) "
					% best + "alignés à %.2f m près avec un pas de %.1f à "
					% [VERGER_ECART_DROITE_MAX_M, VERGER_PAS_MIN_M]
					+ "%.1f m (min %d)" % [VERGER_PAS_MAX_M, VERGER_ALIGNES_MIN])
		_dismount(place)
	check(faults.is_empty(),
		"le verger est un alignement (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (verger) — %s" % restore_root_reason())


## -- 7. La face BRIQUE des murs regarde DEHORS -------------------------------
##
## La face brique du module de kit est en +Z local (inspection glTF :
## `MI_UnevenBrick` plan strict Z = 0,000, `MI_Plaster` plan strict
## Z = -0,200). Avant le geste, les murs posés à `yaw` 90° et 270° — ouest et
## est — présentaient donc leur PLÂTRE dehors : deux triangles pour 6 m² de
## façade, plein cadre sur `ferme_laterale`.

func test_la_face_brique_des_murs_regarde_dehors() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	if place == null:
		faults.append("la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var house: Node3D = _named_child(place, "Fermette")
		if house == null:
			faults.append("aucun nœud Fermette")
		else:
			var checked: int = 0
			for child: Node in place.find_children("*", "Node3D", true, false):
				if not String(child.name).begins_with("Wall_UnevenBrick"):
					continue
				# Le GLB du kit porte un enfant homonyme sous la racine du
				# module : sans ce filtre, chaque mur compte DEUX fois et le
				# décompte de défauts ment (10 signalés pour 5 murs).
				var parent_name: String = String(child.get_parent().name)
				if parent_name.begins_with("Wall_UnevenBrick"):
					continue
				var wall: Node3D = child as Node3D
				var here: Vector3 = house.to_local(wall.global_position)
				var outward: Vector3 = Vector3(here.x, 0.0, here.z)
				if outward.length() < 0.5:
					continue
				checked += 1
				var brick: Vector3 = house.to_local(
					wall.global_position + wall.global_transform.basis.z) - here
				brick.y = 0.0
				if brick.length() < 0.01:
					continue
				if brick.normalized().dot(outward.normalized()) \
						< BRIQUE_DEHORS_MARGE:
					faults.append("%s montre son PLÂTRE dehors" % wall.name)
			if checked < 8:
				faults.append("%d mur(s) examiné(s) — le contrôle ne regarde "
					% checked + "rien")
		_dismount(place)
	check(faults.is_empty(),
		"la face brique des murs regarde dehors (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (orientation des murs) — %s"
		% restore_root_reason())


## -- 8. Budget tenu et pièces R2B conservées ---------------------------------
##
## Le PLAFOND est celui du générateur et il ne bouge pas. Le PLANCHER dit
## qu'un geste a eu lieu : 676 triangles avant, pour un lieu qui en compte
## 30 591 au total — le GLB qui porte toute l'histoire de la ruine en pesait
## 2,2 %.

func test_le_budget_tient_et_les_pieces_r2b_survivent() -> void:
	var faults: Array[String] = []
	var packed: PackedScene = load(FARM_GLB) as PackedScene
	if packed == null:
		faults.append("GLB illisible : %s" % FARM_GLB)
	else:
		var root: Node3D = packed.instantiate() as Node3D
		var triangles: int = 0
		var present: Array[String] = []
		for child: Node in root.find_children("*", "MeshInstance3D",
				true, false):
			var instance: MeshInstance3D = child as MeshInstance3D
			if instance.mesh == null:
				continue
			present.append(String(child.name))
			for surface: int in range(instance.mesh.get_surface_count()):
				var arrays: Array = instance.mesh.surface_get_arrays(surface)
				if arrays.size() > Mesh.ARRAY_INDEX \
						and arrays[Mesh.ARRAY_INDEX] != null:
					triangles += (arrays[Mesh.ARRAY_INDEX] \
						as PackedInt32Array).size() / 3
		root.free()
		if triangles > BUDGET_TRIS_MAX:
			faults.append("budget DÉPASSÉ : %d triangles (plafond %d)"
				% [triangles, BUDGET_TRIS_MAX])
		if triangles < BUDGET_TRIS_MIN:
			faults.append("%d triangles seulement (plancher %d) — la ruine "
				% [triangles, BUDGET_TRIS_MIN] + "n'a pas gagné de masse")
		for piece: String in PIECES_R2B:
			if not present.has(piece):
				faults.append("pièce R2B « %s » disparue — le filet de "
					% piece + "test_world_v2_r2b_farm_tree.gd la désigne")
	check(faults.is_empty(),
		"le budget tient et les pièces R2B survivent (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
