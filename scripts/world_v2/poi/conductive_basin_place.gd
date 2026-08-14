## BASSIN CONDUCTEUR (`valley.poi.conductive_basin.01`, r03) — le site
## systémique de l'école Arc Link, HABILLÉ sans toucher à sa logique.
##
## Le comportement canonique est la classe `ConductiveBasin` elle-même,
## instanciée TELLE QUELLE : son `ElectricGraph` reste ENFANT du site
## (jamais plus haut — il capterait tous les nœuds du monde), ses IDs de
## nœuds, ses ports, ses portées, sa zone de baignade et son
## `WaterMatterComponent` ne changent pas. Le filet de comportement
## vérifie la classe, le graphe et le circuit qui ATTEND.
##
## REJET DU LEAD (V2.3-A) : « Le bassin ressemble à une petite surface
## turquoise rectangulaire entourée de rochers » et « la fonction
## systémique est illisible ». Deux causes distinctes :
##   1. la nappe d'eau de `ConductiveBasin` est un `PlaneMesh` 5,6 × 4,6 —
##      un RECTANGLE parfait, que huit rochers ronds ne rachètent pas ;
##   2. rien ne DISAIT où le courant entre, par où il circulerait, ni ce
##      qui attend. Trois lampes sur un pré, ce n'est pas une leçon.
##
## Correction, et sa frontière exacte :
##   - la nappe reçoit une forme INTÉGRÉE non rectangulaire — on remplace
##     le `Mesh` de l'instance visuelle, RIEN d'autre. Aucun nœud, aucun
##     port, aucune portée, aucune collision, aucune ligne de
##     `scripts/world/conductive_basin.gd` n'est touchée ; le filet de
##     comportement reste le juge ;
##   - une GRAMMAIRE apparaît : pierre taillée qui contient, céramique
##     ivoire qui ISOLE, cuivre patiné qui CONDUIT, caniveau qui montre le
##     trajet — et le caniveau ouest est ROMPU sur 2,3 m : le maillon
##     manquant devient une architecture, pas un vide inexpliqué ;
##   - le cyan reste aux seuls points fonctionnels, c'est-à-dire ceux que
##     `ConductiveBasin` allume lui-même. Ce lieu n'en ajoute AUCUN.
class_name ConductiveBasinPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## La grammaire des matières, §2.3 de la bible visuelle.
const CUT_STONE: Color = Color(0.66, 0.60, 0.52)
const IVORY_CERAMIC: Color = Color(0.90, 0.86, 0.76)
const PATINA_COPPER: Color = Color(0.42, 0.55, 0.50)
const BRIGHT_COPPER: Color = Color(0.66, 0.46, 0.28)

## Emprise de la nappe : celle du plan d'origine, au centimètre — la
## cuvette de collision (6,0 × 5,0) et la zone de baignade (5,6 × 4,6) de
## `ConductiveBasin` ne bougent pas, la forme doit rester DEDANS.
const WATER_HALF_X: float = 2.80
const WATER_HALF_Z: float = 2.30


func default_place_id() -> StringName:
	return &"valley.poi.conductive_basin.01"


func _build() -> void:
	# — Le comportement canonique, intact.
	var basin: ConductiveBasin = ConductiveBasin.new()
	basin.name = "BassinConducteur"
	basin.position = Vector3(0.0, ground_local_y(0.0, 0.0) + 0.05, 0.0)
	add_child(basin)
	declare_support(Vector3(0.0, ground_local_y(0.0, 0.0), 0.0))
	_reshape_water(basin)

	_containing_kerb()
	_source_side()
	_receiver_side()
	_reeds()

	# — Découverte + récompense canonique (récompense d'énigme — coffre).
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Bassin conducteur"
	poi.region = "r03_val_de_neris"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 13.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.PUZZLE,
		_seated(7.2, 1.6) + Vector3(0.0, 0.1, 0.0), Vector3(-1.4, 0.0, -0.8))


## LA NAPPE, RENDUE NON RECTANGULAIRE — et uniquement la nappe.
##
## `ConductiveBasin._build_basin()` crée son `MeshInstance3D` SANS nom :
## Godot le rebaptise `@MeshInstance3D@…`, donc on ne peut pas le désigner
## par un nom (piège déjà consigné dans `scripts/CLAUDE.md`). On le
## retrouve par sa nature — c'est le seul enfant direct du bassin dont le
## maillage est un `PlaneMesh` — et on lui substitue une nappe à contour
## organique, à la MÊME hauteur, dans la MÊME emprise, avec le MÊME
## matériau. Le nœud d'eau, ses deux ports à ±2,5 m et la zone de baignade
## ne sont pas approchés : ce sont eux qui portent la leçon.
func _reshape_water(basin: ConductiveBasin) -> void:
	var sheet: MeshInstance3D = null
	for child: Node in basin.get_children():
		var candidate: MeshInstance3D = child as MeshInstance3D
		if candidate != null and candidate.mesh is PlaneMesh:
			sheet = candidate
			break
	if sheet == null:
		push_warning("bassin : nappe d'eau introuvable — forme rectangulaire conservée")
		return
	sheet.name = "NappeDEau"
	var segments: int = 34
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim: PackedVector3Array = PackedVector3Array()
	for i: int in range(segments + 1):
		var angle: float = TAU * float(i % segments) / float(segments)
		# Contour organique : une ellipse cabossée, plus large côté ports
		# (est/ouest) — la nappe « coule » vers les deux rives.
		var swell: float = 0.86 + sin(angle * 2.0) * 0.11 \
			+ sin(angle * 3.0 + 0.7) * 0.07 + sin(angle * 7.0 + 2.1) * 0.03
		rim.append(Vector3(cos(angle) * WATER_HALF_X * swell, 0.0,
			sin(angle) * WATER_HALF_Z * swell))
	for i: int in range(segments):
		for point: Vector3 in [Vector3.ZERO, rim[i], rim[i + 1]]:
			st.set_normal(Vector3.UP)
			st.add_vertex(point)
	var reshaped: ArrayMesh = st.commit()
	# Le matériau d'origine, repris tel quel : la teinte, la transparence
	# et l'alpha de `ConductiveBasin` restent la vérité de l'eau.
	if sheet.material_override != null:
		reshaped.surface_set_material(0, sheet.material_override)
		sheet.material_override = null
	sheet.mesh = reshaped


## LA MARGELLE : de la pierre TAILLÉE, en appareil, qui CONTIENT l'eau —
## et non huit galets posés autour. Les blocs suivent le contour de la
## nappe et s'ouvrent aux deux rives des ports, est et ouest.
func _containing_kerb() -> void:
	for i: int in range(22):
		var angle: float = TAU * float(i) / 22.0
		# Les deux rives de port restent DÉGAGÉES : ±22° autour de l'axe X.
		var to_axis: float = abs(sin(angle))
		if to_axis < 0.36:
			continue
		var swell: float = 0.86 + sin(angle * 2.0) * 0.11 \
			+ sin(angle * 3.0 + 0.7) * 0.07
		var r_x: float = WATER_HALF_X * swell + 0.52
		var r_z: float = WATER_HALF_Z * swell + 0.52
		var x: float = cos(angle) * r_x
		var z: float = sin(angle) * r_z
		var height: float = 0.40 + fposmod(float(i) * 0.71, 1.0) * 0.26
		K.stone_block(self, "Margelle_%d" % i,
			_seated(x, z) + Vector3(0.0, height * 0.5, 0.0),
			Vector3(0.86, height, 0.62), rad_to_deg(angle) + 90.0,
			CUT_STONE, 10300 + i, 0.11)
		if i % 6 == 0:
			declare_support(_seated(x, z))
	K.collider_box(self, "Margelle_nord", _seated(0.0, 3.15)
		+ Vector3(0.0, 0.32, 0.0), Vector3(5.4, 0.64, 0.9))
	K.collider_box(self, "Margelle_sud", _seated(0.0, -3.15)
		+ Vector3(0.0, 0.32, 0.0), Vector3(5.4, 0.64, 0.9))


## CÔTÉ SOURCE (ouest) — « ICI le courant ENTRE, et le chemin est ROMPU ».
##
## Un socle de céramique ivoire (isolant) porte le pied de la source ; un
## caniveau de pierre part vers l'eau, son rail de cuivre au fond ; et à
## 2,3 m du bord, le caniveau s'interrompt — dalles descellées, rail
## arraché, cuivre nu. Le maillon manquant que l'Arc Link vient rétablir
## devient VISIBLE, sans qu'aucune portée logique ne change.
func _source_side() -> void:
	# Le socle isolant : trois assises de céramique, dressées.
	for i: int in range(3):
		var t: float = float(i) / 2.0
		K.stone_block(self, "SocleIsolant_%d" % i,
			_seated(-9.0, 0.0) + Vector3(0.0, 0.14 + t * 0.26, 0.0),
			Vector3(2.5 - t * 0.55, 0.28, 2.3 - t * 0.50),
			float(i) * 17.0, IVORY_CERAMIC, 10340 + i, 0.05)
	declare_support(_seated(-9.0, 0.0))
	# Un PORTIQUE, pas deux blocs : deux montants plus fins reliés par un
	# linteau de céramique. Mesuré sur `bassin_chaine` — à 0,52 × 1,9 m et
	# sans linteau, les deux montants lisaient comme deux dalles grises
	# plantées au premier plan, et masquaient la chaîne au lieu de
	# l'annoncer. Un portique dit « on entre ici » d'un seul coup d'œil.
	for side: float in [-1.0, 1.0]:
		K.stone_block(self, "MontantSource_%.0f" % side,
			_seated(-9.0, side * 1.35) + Vector3(0.0, 0.78, 0.0),
			Vector3(0.40, 1.56, 0.44), 8.0, CUT_STONE,
			10360 + int(side), 0.09)
	K.stone_block(self, "LinteauSource", _seated(-9.0, 0.0)
		+ Vector3(0.0, 1.70, 0.0), Vector3(0.46, 0.30, 3.35), 8.0,
		IVORY_CERAMIC, 10372, 0.05)
	# La clé du linteau porte le motif du courant fendu (§2.3) : un losange
	# creux entre deux montants — jamais d'émission, la pierre suffit.
	K.stone_block(self, "CleDuLinteau", _seated(-9.0, 0.0)
		+ Vector3(0.0, 1.98, 0.0), Vector3(0.34, 0.42, 0.60), 8.0,
		CUT_STONE, 10373, 0.10)
	# LE CANIVEAU : joues de pierre + rail de cuivre au fond, de la source
	# vers l'eau. Il court de x = −7,9 à x = −3,3… puis s'arrête.
	var broken_from: float = -5.9
	var x: float = -7.9
	while x < -3.2:
		var intact: bool = x < broken_from
		for cheek: float in [-0.46, 0.46]:
			K.stone_block(self, "JoueCaniveau_%.1f_%.0f" % [x, cheek * 10.0],
				_seated(x, cheek) + Vector3(0.0, 0.17, 0.0),
				Vector3(0.62, 0.34, 0.30),
				0.0 if intact else fposmod(x * 31.0, 24.0) - 12.0,
				CUT_STONE, 10400 + int(x * 10.0) + int(cheek * 10.0),
				0.08 if intact else 0.20)
		if intact:
			K.stone_block(self, "RailCuivre_%.1f" % x,
				_seated(x, 0.0) + Vector3(0.0, 0.09, 0.0),
				Vector3(0.62, 0.10, 0.34), 0.0, PATINA_COPPER,
				10440 + int(x * 10.0), 0.04)
		x += 0.68
	# LA RUPTURE : trois dalles descellées, culbutées hors du caniveau, et
	# le bout de rail arraché qui montre son cuivre vif.
	for shard: Array in [[-5.5, 1.05, 34.0], [-4.6, -1.15, -21.0],
			[-3.9, 0.95, 62.0]]:
		var slab: MeshInstance3D = K.stone_block(self,
			"DalleDescellee_%.0f" % (float(shard[0]) * 10.0),
			_seated(float(shard[0]), float(shard[1]))
				+ Vector3(0.0, 0.18, 0.0),
			Vector3(0.66, 0.20, 0.44), float(shard[2]), CUT_STONE,
			10470 + int(shard[0] * 10.0), 0.14)
		slab.rotation.z = deg_to_rad(float(shard[2]) * 0.35)
	K.stone_block(self, "RailArrache", _seated(-5.75, 0.18)
		+ Vector3(0.0, 0.16, 0.0), Vector3(0.44, 0.12, 0.26), 27.0,
		BRIGHT_COPPER, 10490, 0.16)


## CÔTÉ RÉCEPTEUR (est) — « ICI ça ATTEND ». Le rail sort de l'eau, monte
## sur un socle de pierre et s'arrête sous l'anneau : le trajet est
## COMPLET de ce côté-ci ; il ne manque que le courant.
func _receiver_side() -> void:
	var x: float = 3.35
	while x < 5.6:
		for cheek: float in [-0.46, 0.46]:
			K.stone_block(self, "JoueArrivee_%.1f_%.0f" % [x, cheek * 10.0],
				_seated(x, cheek) + Vector3(0.0, 0.17, 0.0),
				Vector3(0.62, 0.34, 0.30), 0.0, CUT_STONE,
				10500 + int(x * 10.0) + int(cheek * 10.0), 0.08)
		K.stone_block(self, "RailArrivee_%.1f" % x,
			_seated(x, 0.0) + Vector3(0.0, 0.09, 0.0),
			Vector3(0.62, 0.10, 0.34), 0.0, PATINA_COPPER,
			10530 + int(x * 10.0), 0.04)
		x += 0.68
	# Le socle du récepteur : deux assises de pierre, chape de céramique.
	K.stone_block(self, "SocleRecepteur_0", _seated(5.9, 0.0)
		+ Vector3(0.0, 0.20, 0.0), Vector3(1.9, 0.40, 1.7), 6.0,
		CUT_STONE, 10560, 0.08)
	K.stone_block(self, "SocleRecepteur_1", _seated(5.9, 0.0)
		+ Vector3(0.0, 0.52, 0.0), Vector3(1.5, 0.26, 1.35), -9.0,
		IVORY_CERAMIC, 10561, 0.06)
	declare_support(_seated(5.9, 0.0))
	# L'ANNEAU D'ATTENTE : un cercle INCOMPLET de claveaux de cuivre, dressé
	# sur la chape et TOURNÉ VERS L'EAU (plan vertical, normale sur −X) —
	# la forme dit « il manque quelque chose » sans une seule lumière, et
	# elle le dit aussi en niveaux de gris.
	var ring_centre: Vector3 = _seated(5.9, 0.0) + Vector3(0.0, 1.70, 0.0)
	for i: int in range(14):
		# Trois claveaux manquants en bas de l'anneau : la boucle est
		# OUVERTE côté rail, exactement là où le courant devrait arriver.
		if i >= 6 and i <= 8:
			continue
		var angle: float = TAU * float(i) / 14.0
		var claveau: MeshInstance3D = K.stone_block(self, "Claveau_%d" % i,
			ring_centre + Vector3(0.0, cos(angle) * 1.02, sin(angle) * 1.02),
			Vector3(0.26, 0.36, 0.30), 0.0, PATINA_COPPER, 10570 + i, 0.07)
		claveau.rotation.x = -angle
	# Le seuil pavé où l'on se poste pour observer le récepteur.
	for slab: Array in [[7.0, 1.0], [7.5, -0.4], [6.6, -1.4]]:
		K.stone_block(self, "PaveArrivee_%d" % get_child_count(),
			_seated(float(slab[0]), float(slab[1]))
				+ Vector3(0.0, 0.06, 0.0), Vector3(1.15, 0.12, 1.0),
			float(slab[0]) * 23.0, CUT_STONE, 10590 + get_child_count(), 0.07)


## Roseaux et verdure D'ANGLE seulement : les deux axes de lecture
## (source → eau, eau → récepteur) restent dégagés, et le poste de lien
## de `ConductiveBasin.stand_point()` — local (−4,5 ; 4,0) — reste libre.
func _reeds() -> void:
	K.module(self, &"Plant_1", _seated(-2.2, 4.6), 0.0, 1.0, K.TONE_PLANT)
	K.module(self, &"Grass_Common_Tall", _seated(2.4, 4.4), 40.0, 1.0,
		K.TONE_PLANT)
	K.module(self, &"Plant_1", _seated(2.9, -4.5), 160.0, 0.9, K.TONE_PLANT)
	K.module(self, &"Fern_1", _seated(-2.4, -4.7), 220.0, 0.9, K.TONE_PLANT)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
