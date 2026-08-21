## LA SOURCE AUX REFLETS (`valley.poi.turquoise_spring.01`, r04) — une eau
## vive qui sort du pied de la falaise, à vingt-quatre mètres du guet et
## quatorze mètres sous lui.
##
## LES DEUX LIEUX SONT LES DEUX FACES DU MÊME MUR, et c'est le terrain gelé
## qui le dit, pas une intention. Profils mesurés (port Python de
## `world_v2_heightmap.gd`, `docs/V2_3_B_LOT1_VOIE_B_PLAN.md` §0) : à
## l'ouest de la source le sol monte de +0,98 m à 11 m, +8,73 m à 16 m,
## +13,72 m à 20 m, puis se stabilise à +14,0 m — soit exactement
## l'altitude du guet (26 − 12 = 14). La pente vaut 54°, et le shader de
## sol rend de la roche stratifiée au-delà de 55° : la paroi EST là, et
## elle est déjà minérale. Ce lieu n'a donc aucune falaise à construire.
##
## LE CADRE COMMUN, calculé avant de poser une pierre : depuis la vasque,
## un œil à 1,70 m qui vise le sommet de la tour (24 m à l'ouest, +23,1 m)
## passe à 20,4 m d'altitude relative au droit de la lèvre, laquelle n'est
## qu'à 14,0 m — le haut de la tour se détache donc sur le ciel. Le même
## calcul vers le PIED de la tour (+14,0 m) passe à 12,5 m au droit de la
## lèvre : le pied, lui, reste caché. On voit la ruine, jamais son assise.
## C'est ce qui fait d'elle un but plutôt qu'un décor.
##
## L'AFFLUENT NAÎT ICI. Premier point de `west_tributary_xz` : (−130 ; 34),
## soit 8,49 m au nord-est du site — et `_trib_bed_curve(0)` vaut 11,0,
## donc une surface d'eau à 11,6 m, quarante centimètres SOUS le pad de la
## source (12,0). Le déversoir n'a rien à inventer : il pointe vers un lit
## qui existe déjà et qui descend. Aucune pièce de ce lieu ne porte de
## collider à moins de 5 m de cette tête de lit — la bande creusée de
## l'affluent (6,3 m de demi-largeur au contrat du lot) reste libre.
##
## CE LIEU N'AJOUTE PAS D'EAU AU MONDE. `NappeSource` est un maillage
## visuel, sans collision, sans `WaterMatterComponent`, sans nœud de
## graphe : l'hydrologie V2.2 est gelée et reste seule maîtresse. Et le
## turquoise employé est celui de la bible §1.4 (`#4FAFB2` peu profond,
## `#2A7182` au fond) — jamais le cyan de Résonance, qui est réservé aux
## sites systémiques et au pylône.
class_name TurquoiseSpringPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## Roche du couchant : ocre froid, un ton sous la falaise pour que les
## pièces posées se détachent du terrain au lieu de s'y dissoudre.
const TONE_ROCK: Color = Color(0.82, 0.74, 0.63)
const TONE_RIM: Color = Color(0.95, 0.90, 0.80)
## Eau : clair au centre (peu profond, fond visible), sombre au bord.
const EAU_CLAIRE: Color = Color(0.310, 0.686, 0.698)
const EAU_PROFONDE: Color = Color(0.165, 0.443, 0.510)
## Centre de la vasque, dans le repère du lieu — au pied de la paroi.
const BASSIN_X: float = -5.4
const BASSIN_Z: float = 0.2
const BASSIN_R: float = 3.0


func default_place_id() -> StringName:
	return &"valley.poi.turquoise_spring.01"


func _build() -> void:
	# — LA GUEULE. Une arche de roche au pied de la paroi, réduite à 0,62 :
	# `SM_Dungeon_CaveArch` mesure 4,00 × 4,05 × 2,45 m, donc 2,48 × 2,51 ×
	# 1,52 ici, pour une ouverture d'environ 1,2 m. C'est une FENTE dont
	# l'eau sort, pas une grotte où l'on entre — la Grotte du couchant
	# existe déjà à 43 m d'ici et c'est elle qui a le droit d'être une
	# poche. Posée à 10,6 m à l'ouest, là où le sol commence tout juste à
	# se relever (+0,62 m mesuré à r = 10,5).
	var gueule: Vector3 = _seated(-10.6, 0.3)
	K.module(self, &"SM_Dungeon_CaveArch", gueule, 92.0, 0.62, TONE_ROCK)
	declare_support(gueule)

	# — LES DEUX ÉPAULES, plus haut sur la pente, de tailles et d'azimuts
	# différents : elles rattachent la fente à la paroi. Sans elles, une
	# arche isolée sur un talus d'herbe se lit « posée ».
	var epaule_n: Vector3 = _seated(-12.4, -2.6)
	var nord: Node3D = K.module(self, &"SM_Dungeon_CaveWallHalf", epaule_n,
		74.0, 1.0, TONE_ROCK)
	if nord != null:
		nord.rotation.z = deg_to_rad(6.0)
	declare_support(epaule_n)
	var epaule_s: Vector3 = _seated(-12.0, 3.4)
	var sud: Node3D = K.module(self, &"SM_Dungeon_CaveWallHalf", epaule_s,
		104.0, 0.85, TONE_ROCK)
	if sud != null:
		sud.rotation.z = deg_to_rad(-9.0)
	declare_support(epaule_s)

	# — LA VASQUE. La nappe D'ABORD, les margelles ensuite : les pierres se
	# posent au bord de l'eau, pas l'inverse.
	_nappe()
	# ANNEAU ROMPU, jamais un cercle : trois margelles inégales au nord, à
	# l'est et au sud, et RIEN à l'ouest — c'est de ce côté que l'eau
	# arrive, et une margelle y boucherait la fente.
	# Les échelles sont des MULTIPLICATEURS de la correction `KitScale` :
	# `rock_largeA` y vaut ×4,23 et `rock_largeC` ×4,83. Les valeurs
	# ci-dessous donnent des margelles de 2,20 / 1,55 / 2,00 m d'emprise —
	# vérifiées au calcul avant la pose, pas devinées à la capture.
	var margelles: Array[Array] = [
		[-6.9, -2.5, 118.0, 0.51], [-3.4, -3.2, -34.0, 0.30],
		[-6.2, 2.9, 61.0, 0.39],
	]
	for spec: Array in margelles:
		var at: Vector3 = _seated(float(spec[0]), float(spec[1]))
		var modele: StringName = &"rock_largeA" \
			if float(spec[3]) > 0.45 else &"rock_largeC"
		K.module(self, modele, at + Vector3(0.0, -0.10, 0.0),
			float(spec[2]), float(spec[3]), TONE_RIM)
		declare_support(at)
	# Un bloc TOMBÉ DE LA PAROI, demi-enterré au sud de la vasque : c'est
	# lui qui donne l'échelle de la falaise au premier plan.
	var bloc: Vector3 = _seated(-8.6, 4.6)
	K.module(self, &"Rock_Medium_2", bloc + Vector3(0.0, -0.95, 0.0), 150.0,
		1.0, TONE_ROCK)
	declare_support(bloc)

	# — LE FIL QUI S'EN VA. Trois dalles mouillées, à demi enfoncées, qui
	# descendent au nord-est vers la tête de l'affluent (local +6 ; −6). La
	# dernière s'arrête à 5,0 m d'elle : le lit gelé reste libre.
	for spec: Array in [[-1.2, -3.4, 24.0, &"RockPath_Round_Small_1"],
			[0.6, -4.4, -51.0, &"RockPath_Square_Small_1"],
			[1.6, -5.0, 12.0, &"RockPath_Round_Small_1"]]:
		K.module(self, spec[3] as StringName,
			_seated(float(spec[0]), float(spec[1]))
				+ Vector3(0.0, -0.05, 0.0), float(spec[2]), 1.0, TONE_RIM)
	# La frange humide : elle marque le fil de l'eau sans le border.
	K.module(self, &"Fern_1", _seated(-5.6, -4.4), 28.0, 1.0, K.TONE_PLANT)
	K.module(self, &"Plant_7", _seated(-4.4, 4.2), -63.0, 1.0, K.TONE_PLANT)

	_collisions()

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "La Source aux reflets"
	poi.region = &"r04_falaises_du_couchant"
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Decouverte_forme"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 12.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	# Le fruit de soin pousse au bord de l'eau, côté est — le côté par
	# lequel on arrive, et le seul qui ne soit pas contre la paroi.
	RewardAnchor.attach(self, default_place_id(),
		RewardAnchor.Kind.INGREDIENT,
		_seated(-2.6, 2.4) + Vector3(0.0, 0.12, 0.0), Vector3(2.0, 0.0, 2.0))


## LA NAPPE — le SEUL maillage construit en runtime de ce lieu, et le seul
## du lot de la voie B avec les tertres du cimetière. L'exemption est
## NOMMÉE, comme `SolBrule` de l'arbre foudroyé et `rock_floor_mesh` de la
## grotte, et pour la même raison : une surface d'eau doit être DE NIVEAU
## dans une cuvette dont le fond est le terrain gelé. Aucun module de kit
## ne peut faire ça, et un plan importé serait faux dès que le pad bougerait.
##
## Le bord n'est PAS harmonique. L'arbre foudroyé a payé une revue pour
## avoir modulé son disque par deux sinus purs : cinq lobes réguliers, une
## « étoile ». Ici le rayon vient d'un hachage par secteur lissé sur trois
## voisins — la modulation n'a plus de période.
##
## Deux anneaux, et une valeur de sommet par anneau : sans dégradé, une
## nappe turquoise unie se lit comme une décalcomanie posée sur l'herbe.
func _nappe() -> void:
	var nappe: MeshInstance3D = MeshInstance3D.new()
	nappe.name = "NappeSource"
	var segments: int = 40
	var brut: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(segments):
		brut.append(_alea(float(i) * 2.3 + 7.1))
	var rayons: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(segments):
		var lisse: float = (brut[(i - 1 + segments) % segments] + brut[i]
			+ brut[(i + 1) % segments]) / 3.0
		rayons.append(BASSIN_R * (0.88 + 0.20 * lisse))
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var interieur: PackedVector3Array = PackedVector3Array()
	var exterieur: PackedVector3Array = PackedVector3Array()
	for i: int in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		var r_ext: float = rayons[i]
		var r_int: float = r_ext * (0.44 + 0.10 * _alea(float(i) * 4.7 + 13.0))
		interieur.append(Vector3(cos(angle) * r_int, 0.0, sin(angle) * r_int))
		exterieur.append(Vector3(cos(angle) * r_ext, 0.0, sin(angle) * r_ext))
	for i: int in range(segments):
		var j: int = (i + 1) % segments
		_triangle(st, Vector3.ZERO, interieur[i], interieur[j], 1.00)
		_triangle(st, interieur[i], exterieur[i], exterieur[j], 0.62)
		_triangle(st, interieur[i], exterieur[j], interieur[j], 0.62)
	nappe.mesh = st.commit()
	# `vertex_color_use_as_albedo` : la valeur de sommet PORTE le dégradé
	# clair-au-centre / sombre-au-bord, sans seconde surface ni shader.
	# La teinte du matériau est la MOYENNE des deux eaux de la bible ; la
	# valeur de sommet (1,00 au centre, 0,62 au bord) la module ensuite.
	# Le produit des deux donne le dégradé sans second matériau ni shader.
	var eau: StandardMaterial3D = K.flat_material(
		EAU_PROFONDE.lerp(EAU_CLAIRE, 0.5))
	eau.vertex_color_use_as_albedo = true
	# La nappe est LISSE : c'est la seule surface non rugueuse du lieu, et
	# c'est ce qui la fait lire comme de l'eau à côté d'une roche mate.
	eau.roughness = 0.18
	eau.metallic_specular = 0.55
	nappe.mesh.surface_set_material(0, eau)
	# Le fond de vasque étant le pad plat, la nappe se pose 10 cm au-dessus
	# du sol réel de son centre : assez pour noyer la base des margelles,
	# trop peu pour flotter.
	var centre: Vector3 = _seated(BASSIN_X, BASSIN_Z)
	nappe.position = centre + Vector3(0.0, 0.10, 0.0)
	add_child(nappe)
	declare_support(centre)


## Trois volumes seulement — et AUCUN sur le fil de l'eau : les dalles du
## déversoir sont à plat et se franchissent, un corps solide dessus ferait
## une marche au milieu d'un ruisseau.
func _collisions() -> void:
	K.collider_box(self, "Source_gueule",
		_seated(-10.6, 0.3) + Vector3(0.0, 1.25, 0.0), Vector3(1.6, 2.5, 2.4),
		92.0)
	K.collider_box(self, "Source_epaule_nord",
		_seated(-12.4, -2.6) + Vector3(0.0, 2.0, 0.0), Vector3(2.1, 4.0, 1.9),
		74.0)
	K.collider_box(self, "Source_bloc",
		_seated(-8.6, 4.6) + Vector3(0.0, 0.45, 0.0), Vector3(2.9, 0.9, 2.4),
		150.0)


## Hachage déterministe dans [−1 ; 1]. Pas de `randf()` : la nappe doit
## être identique d'un montage à l'autre, sinon la régression visuelle
## compare deux formes différentes et ne prouve rien.
func _alea(graine: float) -> float:
	var v: float = sin(graine * 127.1 + 311.7) * 43758.5453
	return (v - floor(v)) * 2.0 - 1.0


func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		valeur: float) -> void:
	for point: Vector3 in [a, b, c]:
		st.set_color(Color(valeur, valeur, valeur, 1.0))
		st.set_normal(Vector3.UP)
		st.add_vertex(point)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
