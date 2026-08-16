## LA GROTTE DU COUCHANT A-T-ELLE UN SOL, ET UN FOND ?
##
## POURQUOI CE FILET EXISTE — l'incident qu'il empêche de revenir.
##
## R2a-3.3 a été livrée avec neuf contrôles verts dans
## `source_assets/blender/environment/make_waterfall_cave.py`, et la revue a
## rendu FAIL VISUEL : « surfaces vertes à travers la poche », « sol
## visuellement disloqué ». Les neuf contrôles ne pouvaient pas voir le
## défaut, et la raison est une CIRCULARITÉ, lisible en deux lignes :
##
##   * `controle_epaisseur()` exclut les rayons descendants —
##     `if math.sin(theta) < -0.30: continue` — en écrivant que « le
##     plancher est garanti autrement : par `controle_aucun_jour` » ;
##   * `controle_aucun_jour()` ne tire que `Vector((0.0, 0.0, 1.0))`,
##     c'est-à-dire VERS LE HAUT.
##
## Rien n'a donc jamais regardé le sol. Et les deux contrôles sautent les
## stations 0, 1, 7 et 8 (`if i >= len(CAVITE) - 2` d'un côté,
## `range(2, len(CAVITE) - 2)` de l'autre), c'est-à-dire le porche, le
## seuil, et tout le fond.
##
## Mesuré par `tools/probe_cave_openings.py` sur le GLB livré :
##   * le plancher est ABSENT de y = -0,29 à y = +6,25 en repère modèle ;
##     ce que la caméra montre comme sol y est le sommet de l'assise
##     enterrée, environ un demi-mètre trop bas ;
##   * le FOND de la galerie est PERCÉ sur environ 1,5 x 1,25 m : un rayon
##     parti de la salle vers le fond ressort du rocher sans rien toucher.
##
## CE QUE CE FILET ÉPINGLE, ET CE QU'IL N'ÉPINGLE PAS.
##
## Il épingle des PROPRIÉTÉS géométriques — « il y a un sol ici », « le fond
## est plein » — et jamais un nombre de triangles, une taille de fichier ni
## une empreinte. C'est délibéré : la composition extérieure de ce lieu est
## en cours de reprise, le GLB sera régénéré, et un filet épinglé sur des
## compteurs rougirait alors pour une raison qui n'est pas la sienne.
##
## Il ne juge rien d'artistique. La forme du rocher ne le regarde pas.
class_name TestGrotteSansJour
extends GateTestCase

const OUVRAGE: String = "res://assets/environment/caves/SM_WaterfallCave.glb"
const NOEUD_RENDU: String = "SM_WaterfallCave"

## Cotes recopiées de `make_waterfall_cave.py`, en repère MODÈLE BLENDER
## (galerie vers +Y, bouche vers -Y, plan de sol à z = 0).
const SAG: float = 0.08
## `PALIER` du générateur : la hauteur du sol monte par marches vers le fond.
const PALIER: Array[float] = [0.00, 0.00, 0.04, 0.10, 0.16, 0.26, 0.50, 0.78, 0.92]

## Tolérance sur la hauteur du premier impact vers le bas. La section n'a que
## 9 facettes : entre deux sommets, la corde s'écarte du profil théorique, et
## la décimation déplace encore des sommets. 0,30 m couvre les deux — et ne
## peut pas couvrir le défaut mesuré, qui vaut 0,31 à 0,76 m et dont le fond
## se situe au niveau de l'assise enterrée, un demi-mètre plus bas.
const TOLERANCE_SOL: float = 0.30

## Points de sonde du PLANCHER : (x, y) en repère modèle, index de station.
## Choisis sur l'axe et à mi-largeur, dans la portion de galerie que la
## caméra d'approche montre réellement — c'est ce que le lead a vu.
const SONDES_SOL: Array[Dictionary] = [
	{"x": 0.06, "y": 1.60, "i": 2},
	{"x": 0.90, "y": 1.60, "i": 2},
	{"x": 0.24, "y": 3.20, "i": 3},
	{"x": 1.20, "y": 3.20, "i": 3},
	{"x": 0.58, "y": 4.75, "i": 4},
	{"x": 1.05, "y": 6.25, "i": 5},
]

## Points de sonde du FOND : on part de la salle et on regarde vers le fond
## de la galerie. `x` couvre l'emprise du trou mesuré (x de +0,97 à +2,47).
const SONDES_FOND: Array[float] = [1.05, 1.45, 1.85]


func test_le_sol_de_la_galerie_existe_sous_le_joueur() -> void:
	var faces: PackedVector3Array = _faces_du_rendu()
	if faces.is_empty():
		check(false, "maillage rendu %s introuvable ou vide dans %s"
			% [NOEUD_RENDU, OUVRAGE])
		return
	for sonde: Dictionary in SONDES_SOL:
		var sol_attendu: float = PALIER[int(sonde["i"])] - SAG
		var depart_modele: Vector3 = Vector3(
			float(sonde["x"]), float(sonde["y"]), sol_attendu + 0.90)
		var impacts: Array[float] = _distances(
			faces, _vers_godot(depart_modele), Vector3(0.0, -1.0, 0.0))
		# Deux façons d'échouer, distinguées : rien du tout sous les pieds,
		# ou bien un sol qui existe mais un demi-mètre trop bas — c'est
		# alors l'assise enterrée que l'on voit, pas le profil de cavité.
		if impacts.is_empty():
			check(false, "plancher ABSENT en (%.2f ; %.2f) : aucun impact "
				% [sonde["x"], sonde["y"]] + "sous un point de la galerie")
			continue
		check(impacts[0] <= 0.90 + TOLERANCE_SOL,
			"plancher trop bas en (%.2f ; %.2f) : premier impact a %.2f m "
			% [sonde["x"], sonde["y"], impacts[0]]
			+ "sous le point de depart, attendu au plus %.2f m — la "
			% (0.90 + TOLERANCE_SOL)
			+ "difference est le vide entre le profil de cavite et l'assise")


func test_le_fond_de_la_galerie_est_plein() -> void:
	var faces: PackedVector3Array = _faces_du_rendu()
	if faces.is_empty():
		check(false, "maillage rendu %s introuvable ou vide dans %s"
			% [NOEUD_RENDU, OUVRAGE])
		return
	# Depuis la salle (station 5), a hauteur de tete, on regarde vers le
	# fond. La galerie se termine par une calotte : un rayon doit donc
	# entrer dans la roche puis en sortir — deux impacts au moins, et un
	# nombre PAIR. Zero impact veut dire que le regard traverse la
	# formation de part en part.
	var hauteur: float = PALIER[5] - SAG + 1.00
	for x: float in SONDES_FOND:
		var depart: Vector3 = _vers_godot(Vector3(x, 6.25, hauteur))
		var impacts: Array[float] = _distances(
			faces, depart, _vers_godot_direction(Vector3(0.0, 1.0, 0.0)))
		check(impacts.size() >= 2 and impacts.size() % 2 == 0,
			"fond PERCE a x = %.2f : %d impact(s) vers le fond de la "
			% [x, impacts.size()]
			+ "galerie, il en faut un nombre pair et au moins 2 — "
			+ "sinon le joueur voit le monde a travers la roche")


func test_la_coque_de_collision_reste_distincte_du_rendu() -> void:
	# GARDE-FOU DE LA SONDE ELLE-MEME. `COL_WaterfallCave` est un loft
	# entierement different du maillage visible et n'est jamais rendu. Si un
	# jour les deux fusionnaient, les deux tests ci-dessus mesureraient la
	# continuite d'une surface que personne ne voit — et passeraient au vert
	# sans rien prouver. C'est exactement le mode d'echec qu'a deja connu
	# `tools/measure_module_relief.py` sur ce meme asset.
	var racine: Node3D = _instancier()
	check_not_null(racine, "instanciation de %s" % OUVRAGE)
	if racine == null:
		return
	var rendu: MeshInstance3D = _trouver(racine, NOEUD_RENDU)
	var collision: MeshInstance3D = _trouver(racine, "COL_WaterfallCave")
	check_not_null(rendu, "noeud rendu %s" % NOEUD_RENDU)
	check_not_null(collision, "proxy de collision COL_WaterfallCave")
	if rendu != null and collision != null:
		check(rendu.mesh != collision.mesh,
			"le rendu et la collision partagent le meme maillage : les "
			+ "sondes de sol et de fond mesureraient le collider")
	racine.free()


## ---------------------------------------------------------------------------
## Outillage
## ---------------------------------------------------------------------------

## Repère MODÈLE Blender -> repère local Godot. Le GLB est exporté Y-up :
## x_godot = x_blender, y_godot = z_blender, z_godot = -y_blender.
func _vers_godot(point: Vector3) -> Vector3:
	return Vector3(point.x, point.z, -point.y)


func _vers_godot_direction(direction: Vector3) -> Vector3:
	return Vector3(direction.x, direction.z, -direction.y).normalized()


func _instancier() -> Node3D:
	var paquet: PackedScene = load(OUVRAGE) as PackedScene
	if paquet == null:
		return null
	return paquet.instantiate() as Node3D


func _trouver(racine: Node3D, nom: String) -> MeshInstance3D:
	if racine.name == nom:
		return racine as MeshInstance3D
	for enfant: Node in racine.find_children(nom, "MeshInstance3D", true, false):
		return enfant as MeshInstance3D
	return null


## Triangles du maillage RENDU uniquement, en repère local Godot.
func _faces_du_rendu() -> PackedVector3Array:
	var racine: Node3D = _instancier()
	if racine == null:
		return PackedVector3Array()
	var noeud: MeshInstance3D = _trouver(racine, NOEUD_RENDU)
	var faces: PackedVector3Array = PackedVector3Array()
	if noeud != null and noeud.mesh != null:
		faces = noeud.mesh.get_faces()
	racine.free()
	return faces


## Distances de tous les impacts le long d'un rayon, triées.
##
## Les impacts distants de moins d'un demi-centimetre sont fusionnes : la
## decimation laisse des ecailles de quelques millimetres entre deux plis,
## que le generateur documente deja sous `EPAISSEUR_ECAILLE_M`. Les compter
## comme des parois ferait mentir la parite.
func _distances(faces: PackedVector3Array, depart: Vector3,
		direction: Vector3) -> Array[float]:
	var bruts: Array[float] = []
	var i: int = 0
	while i + 2 < faces.size():
		var touche: Variant = Geometry3D.ray_intersects_triangle(
			depart, direction, faces[i], faces[i + 1], faces[i + 2])
		if touche != null:
			bruts.append(depart.distance_to(touche as Vector3))
		i += 3
	bruts.sort()
	var sortie: Array[float] = []
	for d: float in bruts:
		if sortie.is_empty() or d - sortie[sortie.size() - 1] > 0.005:
			sortie.append(d)
	return sortie
