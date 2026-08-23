## CIMETIÈRE DU TERTRE (`valley.poi.barrow_cemetery.01`, r08) — trois
## masses tombées dans la steppe, et beaucoup de vide entre elles.
##
## LE VIDE EST LE CONTRAT, pas une économie. r08 dit « densité basse
## voulue — le vide est une identité » et « plans très larges ». Le terrain
## le confirme : ±1 m sur quarante mètres dans toutes les directions sauf
## le nord-est. Rien ici ne se cache derrière rien ; la lecture se fait de
## loin, et elle doit tenir en trois masses inégales séparées par de
## l'herbe rase. Le lieu le plus proche est à 46,6 m.
##
## POURQUOI DES DÔMES DE TERRE, ET POURQUOI ILS SONT CONSTRUITS EN RUNTIME.
## Un tertre est un GONFLEMENT DU SOL. Aucun module du kit ne sait se
## raccorder tangentiellement au terrain gelé à sa lisière : posé dessus,
## un rocher fait un objet ; un dôme cousu au sol fait une tombe. C'est
## exactement la famille d'exemption déjà NOMMÉE pour `SolBrule` (arbre
## foudroyé) et `rock_floor_mesh` (grotte) — de la géométrie qui doit lire
## le terrain du site AU MONTAGE. L'exemption est donc revendiquée ici pour
## trois nœuds, `Tertre_Grand`, `Tertre_Moyen` et `Tertre_Petit`, et pour
## eux seuls : tout le reste du lieu est du kit importé.
##
## ET ELLE EST PAYÉE. Un dôme nu resterait une primitive. Chaque tertre est
## donc CEINTURÉ de pierres de kit demi-enterrées, et le plus grand est
## MORDU par une chambre de dolmen en modules — l'œil lit de la pierre
## posée sur de la terre remuée, jamais une capsule lisse. Le bord des
## dômes est haché par secteur puis lissé sur trois voisins, la recette
## anti-« étoile » que l'arbre foudroyé a payée d'une revue : deux sinus
## purs donnent cinq lobes réguliers, un hachage lissé n'a plus de période.
##
## L'ANCRE DE RÉGION `anchor.r08` EST À 5,66 m (local +4 ; +4). Le tertre
## moyen a donc été déplacé à (+9,0 ; +6,5) : son bord passe à 5,6 m de
## l'ancre au lieu de la recouvrir.
class_name BarrowCemeteryPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## Terre remuée sous l'herbe rase. Valeur choisie dans la même bande que
## `earth_color` du shader de sol (0,315 / 0,25 / 0,20) et `wet_bed_color`
## (0,24 / 0,26 / 0,23) — deux albédos DÉJÀ mesurés sûrs sur ce monde.
## `scripts/CLAUDE.md` : une couleur de palette n'est pas un albédo, le
## gain de lumière vaut 1,4 à 1,8, et un vert de bible donné tel quel
## ferait des tertres plus clairs que la prairie qui les entoure.
const TERRE: Color = Color(0.280, 0.300, 0.195)
## Pierre des tumulus : grise, lichénée, sans ocre — plus vieille que les
## ruines de la vallée, et d'une autre main.
const TONE_STELE: Color = Color(0.72, 0.72, 0.68)
const TONE_CHAMBRE: Color = Color(0.64, 0.64, 0.61)

## Chaque tertre : centre local, rayon, hauteur, graine.
const TERTRES: Array[Array] = [
	["Tertre_Grand", -3.5, -1.5, 6.20, 2.10, 4131],
	["Tertre_Moyen", 9.0, 6.5, 4.40, 1.35, 9077],
	["Tertre_Petit", 2.0, -8.5, 3.00, 0.80, 2609],
]


func default_place_id() -> StringName:
	return &"valley.poi.barrow_cemetery.01"


func _build() -> void:
	# L'exemption revendiquée dans l'en-tête, RÉELLEMENT posée — mesuré le
	# 2026-08-23 : revendiquée en prose mais jamais câblée, elle n'exemptait
	# rien, et D1a rendait 55,7 % d'aire runtime sur ce lieu. Le titre de
	# l'exemption est vérifié dans `_tertre()` : chaque sommet appelle
	# `ground_local_y(x, z)` — un gonflement du terrain gelé ne peut pas être
	# un GLB, même famille que `SolBrule`.
	set_meta(&"exemption_runtime", PackedStringArray(
		["Tertre_Grand", "Tertre_Moyen", "Tertre_Petit"]))
	for spec: Array in TERTRES:
		_tertre(String(spec[0]), float(spec[1]), float(spec[2]),
			float(spec[3]), float(spec[4]), int(spec[5]))
	_ceintures()
	_chambre_ouverte()
	_steles_couchees()
	_steppe()
	_collisions()

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Cimetière du tertre"
	poi.region = &"r08_steppe_du_nord"
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Decouverte_forme"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 18.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	# Le layout dit « coffre — hache lourde », et c'est le `kind` de
	# l'ancrage qui décide de la forme : `CHEST` donne bien un coffre dont
	# `DiscoveryRewards` remplit le `weapon_loot` depuis sa table. Il est
	# posé à la GUEULE du dolmen, dehors : un coffre au fond d'une chambre
	# fermée serait un piège, et l'audit d'ancrage exige qu'on reparte.
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.CHEST,
		_seated(-1.5, 4.3) + Vector3(0.0, 0.1, 0.0), Vector3(0.4, 0.0, 7.4))


## UN TERTRE — dôme cousu au terrain gelé, sommet par sommet.
##
## Le profil `cos(t·π/2)^1.4` a une tangente HORIZONTALE aux deux bouts :
## le dôme ne fait ni pointe au sommet ni arête à la lisière, et c'est
## l'arête de lisière qui trahirait une capsule posée sur l'herbe.
##
## Chaque anneau lit `ground_local_y()` à sa propre position : sur le pad
## plat de ce site cela ne change rien aujourd'hui, mais un terrain qui
## bougerait ne ferait pas flotter un bord et enterrer l'autre — le défaut
## mesuré sur les dalles de la grotte.
func _tertre(nom: String, cx: float, cz: float, rayon: float, hauteur: float,
		graine: int) -> void:
	var secteurs: int = 32
	# Le premier anneau n'est PAS zéro : un anneau de rayon nul est un
	# cercle dégénéré de 32 sommets confondus, et il coûte 32 triangles
	# d'aire nulle. Le sommet est un point unique, cousu en éventail.
	var anneaux: Array[float] = [0.30, 0.58, 0.80, 0.93, 1.0]
	# Rayon par secteur : hachage, puis lissage sur trois voisins.
	var brut: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(secteurs):
		brut.append(_alea(float(i) * 1.9 + float(graine) * 0.013))
	var rayons: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(secteurs):
		var lisse: float = (brut[(i - 1 + secteurs) % secteurs] + brut[i]
			+ brut[(i + 1) % secteurs]) / 3.0
		rayons.append(rayon * (0.90 + 0.17 * lisse))
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grilles: Array[PackedVector3Array] = []
	var valeurs: Array[PackedFloat32Array] = []
	for anneau: float in anneaux:
		var points: PackedVector3Array = PackedVector3Array()
		var tons: PackedFloat32Array = PackedFloat32Array()
		for i: int in range(secteurs):
			var angle: float = TAU * float(i) / float(secteurs)
			var r: float = rayons[i] * anneau
			var x: float = cx + cos(angle) * r
			var z: float = cz + sin(angle) * r
			# Profil `cos(t·π/2)^1,4` : tangente HORIZONTALE aux deux
			# bouts — ni pointe au sommet, ni arête à la lisière. Le
			# `maxf` protège du cosinus qui frôle zéro par en dessous :
			# `pow` d'un négatif à exposant fractionnaire rend NaN, et un
			# NaN dans un maillage ne se voit qu'à la capture.
			var y: float = ground_local_y(x, z) + hauteur \
				* pow(maxf(cos(anneau * PI * 0.5), 0.0), 1.4)
			points.append(Vector3(x, y, z))
			# La couronne est plus TERREUSE (0,86), la lisière rejoint
			# l'herbe (1,08) : c'est le dégradé qui fait fondre le bord.
			tons.append(lerpf(0.86, 1.08, anneau)
				+ 0.05 * _alea(float(i) * 3.7 + anneau * 11.0))
		points.append(points[0])
		tons.append(tons[0])
		grilles.append(points)
		valeurs.append(tons)
	# Le sommet, cousu en éventail sur le premier anneau. L'ENROULEMENT est
	# celui de `SolBrule` et de `rock_floor_mesh` — (centre, bord[i],
	# bord[i+1]) à angle croissant — parce que c'est l'enroulement d'une
	# surface tournée VERS LE HAUT qui a déjà été validée sur ce moteur.
	var sommet: Vector3 = Vector3(cx, ground_local_y(cx, cz) + hauteur, cz)
	for i: int in range(secteurs):
		_triangle(st, sommet, grilles[0][i], grilles[0][i + 1], 0.86)
	for anneau_index: int in range(anneaux.size() - 1):
		var bas: PackedVector3Array = grilles[anneau_index + 1]
		var haut: PackedVector3Array = grilles[anneau_index]
		var t_bas: PackedFloat32Array = valeurs[anneau_index + 1]
		var t_haut: PackedFloat32Array = valeurs[anneau_index]
		for i: int in range(secteurs):
			_triangle_degrade(st, haut[i], bas[i], bas[i + 1],
				t_haut[i], t_bas[i], t_bas[i + 1])
			_triangle_degrade(st, haut[i], bas[i + 1], haut[i + 1],
				t_haut[i], t_bas[i + 1], t_haut[i + 1])
	var dome: MeshInstance3D = MeshInstance3D.new()
	dome.name = nom
	dome.mesh = st.commit()
	var terre: StandardMaterial3D = K.flat_material(TERRE)
	terre.vertex_color_use_as_albedo = true
	dome.mesh.surface_set_material(0, terre)
	add_child(dome)
	declare_support(_seated(cx, cz))


## LES CEINTURES — pierres demi-enterrées au PIED de chaque tertre. Ce sont
## elles qui empêchent le dôme de se lire comme une primitive : un tumulus
## est ceint de blocs, et l'œil accroche la pierre avant la terre.
##
## Pas d'espacement régulier : trois pierres sur le grand, deux sur le
## moyen, une sur le petit, à des azimuts qui ne se répondent pas.
func _ceintures() -> void:
	# Dernière colonne : MULTIPLICATEUR de la correction `KitScale`, qui
	# vaut déjà ×4,83 pour `rock_largeC` et ×4,23 pour `rock_largeA`. Les
	# valeurs donnent des blocs de 1,60 / 1,80 / 1,30 / 1,50 / 1,15 / 1,00 m
	# d'emprise, décroissants avec la taille du tertre qu'ils ceinturent.
	var pierres: Array[Array] = [
		[-3.5, -1.5, 6.10, 202.0, &"rock_largeC", 0.31],
		[-3.5, -1.5, 6.30, 318.0, &"rock_largeA", 0.42],
		[-3.5, -1.5, 5.95, 96.0, &"rock_largeC", 0.25],
		[9.0, 6.5, 4.30, 41.0, &"rock_largeA", 0.35],
		[9.0, 6.5, 4.45, 236.0, &"rock_largeC", 0.22],
		[2.0, -8.5, 2.95, 154.0, &"rock_largeC", 0.19],
	]
	for spec: Array in pierres:
		var azimut: float = deg_to_rad(float(spec[3]))
		var x: float = float(spec[0]) + cos(azimut) * float(spec[2])
		var z: float = float(spec[1]) + sin(azimut) * float(spec[2])
		var at: Vector3 = _seated(x, z)
		K.module(self, spec[4] as StringName, at + Vector3(0.0, -0.09, 0.0),
			float(spec[3]) * 0.7, float(spec[5]), TONE_STELE)
		declare_support(at)


## LA CHAMBRE OUVERTE — le grand tertre a été MORDU au sud-est. Deux
## montants, une dalle de couverture posée en travers, et la matière qu'on
## en a sortie répandue devant. C'est la seule chose du lieu qui dise
## « quelqu'un est venu et a ouvert » — sans un mot, comme le demande le
## contrat.
##
## La dalle est INCLINÉE de 7° et débordante : une couverture d'aplomb se
## lit maçonnée, une couverture qui a glissé se lit descellée.
func _chambre_ouverte() -> void:
	var montants: Array[Array] = [[-0.6, 2.2, 14.0], [-2.6, 3.4, -21.0]]
	for spec: Array in montants:
		var at: Vector3 = _seated(float(spec[0]), float(spec[1]))
		K.module(self, &"SM_Dungeon_ArchBlock", at, float(spec[2]), 1.45,
			TONE_CHAMBRE)
		declare_support(at)
	var couverture: Node3D = K.module(self, &"RockPath_Square_Wide",
		_seated(-1.6, 2.8) + Vector3(0.0, 1.48, 0.0), 32.0, 1.25,
		TONE_CHAMBRE)
	if couverture != null:
		couverture.rotation.z = deg_to_rad(7.0)
	# La matière sortie de la chambre, devant la gueule et non derrière.
	for spec: Array in [[-0.9, 4.6, 57.0, 1.05, &"SM_Dungeon_RubbleLarge"],
			[-3.2, 5.2, -14.0, 0.90, &"SM_Dungeon_RubbleSmall"],
			[0.6, 5.9, 128.0, 0.80, &"SM_Dungeon_RubbleSmall"]]:
		K.module(self, spec[4] as StringName,
			_seated(float(spec[0]), float(spec[1])), float(spec[2]),
			float(spec[3]), TONE_CHAMBRE)


## LES STÈLES COUCHÉES — huit marques éparpillées jusqu'à seize mètres, la
## plupart à plat et à demi avalées par l'herbe, deux encore debout et
## penchées. Elles sont ce qui étend le lieu au-delà des trois dômes sans
## le remplir : entre elles, il n'y a rien, et c'est voulu.
func _steles_couchees() -> void:
	# Les deux qui tiennent encore, penchées de 18° et 31°.
	for spec: Array in [[6.4, -3.2, 1.50, 71.0, 18.0],
			[-7.8, 3.9, 1.10, -34.0, 31.0]]:
		var at: Vector3 = _seated(float(spec[0]), float(spec[1]))
		var stele: Node3D = K.module(self, &"SM_Dungeon_PillarStub", at,
			float(spec[3]), float(spec[2]), TONE_STELE)
		if stele != null:
			stele.rotation.z = deg_to_rad(float(spec[4]))
		declare_support(at)
	# Trois lames couchées, `cliff_half_rock` (1,00 × 0,50 × 0,42 m natif,
	# corrigé ×9 par `KitScale` puis réduit ici) basculées à plat.
	# Dernière colonne : ENFONCEMENT en mètres. Il est calculé, pas choisi :
	# basculées, ces lames font 1,06 / 0,90 / 0,77 m d'épaisseur apparente,
	# et une masse de 0,84 m qu'on traverse à pied est un défaut visible.
	# Enfoncées de 0,62 / 0,52 / 0,44 m elles n'émergent plus que de 0,44 /
	# 0,38 / 0,33 m — sous la hauteur de marche du héros (0,30-0,38 m, §8.2),
	# donc franchissables sans collider et sans traversée visible. « À demi
	# avalées par l'herbe » cesse d'être une image : c'est la cote.
	for spec: Array in [[-10.4, -5.6, 0.26, 23.0, 0.62],
			[12.6, -1.8, 0.22, -48.0, 0.52], [4.2, 12.4, 0.19, 106.0, 0.44]]:
		var lame: Node3D = K.module(self, &"cliff_half_rock",
			_seated(float(spec[0]), float(spec[1])), float(spec[3]),
			float(spec[2]), TONE_STELE)
		_coucher(lame, 86.0, float(spec[4]))
	# Trois dalles à demi enfoncées, que l'herbe a presque reprises.
	for spec: Array in [[-6.2, -8.8, 39.0, &"RockPath_Square_Small_1"],
			[8.8, -9.6, -62.0, &"RockPath_Round_Small_1"],
			[-13.2, 1.4, 17.0, &"RockPath_Square_Small_1"]]:
		K.module(self, spec[3] as StringName,
			_seated(float(spec[0]), float(spec[1]))
				+ Vector3(0.0, -0.07, 0.0), float(spec[2]), 1.0, TONE_STELE)


## LA STEPPE — trois touffes sèches, deux éclats, rien d'autre. Aucun
## arbre : la steppe du nord n'en porte pas, et le vide est l'identité.
func _steppe() -> void:
	for spec: Array in [[5.0, 8.2, 27.0], [-9.6, -2.4, -51.0],
			[13.4, 4.6, 84.0]]:
		K.module(self, &"Grass_Common_Tall",
			_seated(float(spec[0]), float(spec[1])), float(spec[2]), 1.0,
			K.TONE_PLANT)
	K.module(self, &"rock_smallB", _seated(1.4, 3.4), 62.0, 0.67, TONE_STELE)
	K.module(self, &"rock_smallB", _seated(-5.4, 7.6), -19.0, 0.49, TONE_STELE)


## COLLISIONS — une SPHÈRE par tertre, jamais une boîte : un dôme se
## franchit en marchant, une boîte s'y cogne à hauteur d'arête.
##
## Le rayon vient du dôme : une sphère qui vaut zéro au bord et `hauteur`
## au centre a pour rayon `R = (r² + h²) / 2h`. Le rayon d'ajustement est
## réduit à 0,94·r — APPROXIMATION ASSUMÉE ET MESURÉE : la sphère déborde
## alors la lisière visible de 0,66 m si le sol voisin descend d'un mètre,
## ce qui est le pire cas de cette steppe (±1 m sur quarante). Un ajustement
## sur `r` plein donnerait 1,1 m de débord ; l'inverse creuserait une marche
## visible au sommet.
func _collisions() -> void:
	for spec: Array in TERTRES:
		var cx: float = float(spec[1])
		var cz: float = float(spec[2])
		var rayon: float = float(spec[3]) * 0.94
		var hauteur: float = float(spec[4])
		var r_sphere: float = (rayon * rayon + hauteur * hauteur) \
			/ (2.0 * hauteur)
		var corps: StaticBody3D = StaticBody3D.new()
		corps.name = String(spec[0]) + "_col"
		corps.collision_layer = 1
		corps.collision_mask = 0
		var forme: CollisionShape3D = CollisionShape3D.new()
		forme.name = corps.name + "_forme"
		var boule: SphereShape3D = SphereShape3D.new()
		boule.radius = r_sphere
		forme.shape = boule
		corps.add_child(forme)
		add_child(corps)
		corps.position = _seated(cx, cz) \
			+ Vector3(0.0, hauteur - r_sphere, 0.0)
	# La chambre : UN volume pour les deux montants et leur couverture.
	K.collider_box(self, "Chambre_dolmen",
		_seated(-1.6, 2.8) + Vector3(0.0, 0.85, 0.0), Vector3(3.1, 1.7, 2.0),
		32.0)
	# Les deux stèles encore debout — les couchées se franchissent.
	K.collider_box(self, "Stele_est",
		_seated(6.4, -3.2) + Vector3(0.0, 0.98, 0.0),
		Vector3(0.95, 1.96, 0.95), 71.0)
	K.collider_box(self, "Stele_ouest",
		_seated(-7.8, 3.9) + Vector3(0.0, 0.72, 0.0),
		Vector3(0.85, 1.44, 0.85), -34.0)


## Hachage déterministe dans [−1 ; 1]. Pas de `randf()` : trois tertres
## doivent être identiques d'un montage à l'autre, sinon une régression
## visuelle compare deux mondes et ne prouve rien.
func _alea(graine: float) -> float:
	var v: float = sin(graine * 127.1 + 311.7) * 43758.5453
	return (v - floor(v)) * 2.0 - 1.0


func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		valeur: float) -> void:
	_triangle_degrade(st, a, b, c, valeur, valeur, valeur)


## Un triangle dont CHAQUE SOMMET porte sa valeur : c'est le dégradé
## couronne-terreuse → lisière-herbeuse qui fait fondre le bord du tertre
## dans le terrain. Une valeur unique par triangle redonnerait des facettes.
func _triangle_degrade(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		ta: float, tb: float, tc: float) -> void:
	# LA NORMALE EST REDRESSÉE VERS LE HAUT, et c'est délibéré. La normale
	# d'un dôme pointe toujours vers l'extérieur, donc jamais vers le bas ;
	# l'imposer ici rend l'éclairage indépendant de la convention
	# d'enroulement, laquelle est réglée séparément en recopiant celle de
	# `SolBrule`. Sans ce redressement, une erreur de signe donnerait un
	# tertre NOIR — un défaut qui ne se voit qu'à la capture, jamais au
	# parse ni au compte de maillages.
	var normale: Vector3 = (b - a).cross(c - a).normalized()
	if normale.y < 0.0:
		normale = -normale
	for paire: Array in [[a, ta], [b, tb], [c, tc]]:
		var t: float = float(paire[1])
		st.set_color(Color(t, t, t, 1.0))
		st.set_normal(normale)
		st.add_vertex(paire[0] as Vector3)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)

## COUCHER UNE PIÈCE, ET LA RÉASSEOIR SUR SA VRAIE EMPRISE.
##
## `KitPlacement.seat()` mesure AVANT que l'appelant n'ajoute un roulis ou un
## basculement — il ne peut donc rien pour une pièce qu'on couche ensuite. Et
## le décalage à rattraper n'est pas devinable : mesuré au glTF,
## `cliff_half_rock` a son épaisseur en +Z (bbox z ∈ [0,0815 ; 0,500]) et son
## origine sur une ARÊTE, si bien qu'un basculement de +86° l'envoie
## ENTIÈREMENT sous le sol — 11 cm visibles sur 1,06 m. `SM_Dungeon_PillarStub`
## est centré en X/Z et se comporte autrement, `Wall_UnevenBrick_Straight`
## autrement encore (z ∈ [−0,314 ; +0,092]).
##
## On ne devine donc pas : on bascule, on remesure l'emprise dans le repère du
## parent, et on enfonce de la fraction VOULUE. `enfoncement` est la profondeur
## en mètres sous le sol — zéro pose la pièce exactement dessus.
##
## (Troisième emploi dans ce lot : sa place serait `world_v2_place_kit.gd`
## selon la règle de trois. Il reste ici parce que ce fichier-là est partagé
## par les trois voies du lot et qu'une édition concurrente y coûte une fusion ;
## remonté au lead pour intégration.)
func _coucher(piece: Node3D, deg_x: float, enfoncement: float) -> void:
	if piece == null:
		return
	piece.rotation.x = deg_to_rad(deg_x)
	var boite: AABB = Transform3D(piece.transform.basis, Vector3.ZERO) \
		* KitPlacement.local_aabb(piece)
	piece.position.y -= boite.position.y + enfoncement
