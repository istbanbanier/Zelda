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

## R2B : l'habillage passe des `stone_block` procéduraux aux MODULES du kit
## (rejet du lead : « des primitives »). Les teintes ci-dessous sont des
## MULTIPLICATEURS sur des textures qui portent déjà leur valeur — la bande
## de valeur se MESURE sur capture (`tools/check_value_bands.py`, cible
## p50 ∈ [35, 65] %, p90 ≤ 70 %), elle ne se prédit pas depuis l'albédo
## (gain non linéaire, scripts/CLAUDE.md).
##
## MESURÉ sur `bassin_proche` (commit 70780a0) : avec un multiplicateur
## prudent (0,86/0,80/0,71) — choisi par crainte du piège inverse, le
## double assombrissement des roches sombres du donjon — la texture
## RockPath, CLAIRE, sortait à p50 = 72,9 % / p90 = 87,1 % sur crop pierre
## seule (herbe témoin : p90 = 58 %). Correction par le ratio mesuré
## (~0,77) : la valeur de palette CUT_STONE convient à CE kit-là. Les deux
## pièges sont réels et opposés — d'où : mesurer, jamais présumer.
const KIT_CUT_STONE: Color = Color(0.66, 0.60, 0.52)
const KIT_RAIL_COPPER: Color = Color(0.357, 0.4675, 0.425)  # PATINA × 0,85
## Pente : un module de 2 m dont l'empreinte enjambe plus de ça se scinde
## en modules de 1 m (arbitrage R2B, décision transverse).
const SLAB_GROUND_SPAN_MAX: float = 0.07

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
## des MODULES du kit, plus un seul bloc procédural (R2B). Une assise de
## bordures (`Prop_ExteriorBorder_Straight1`) suit le contour de la nappe,
## un couronnement de dalles (`RockPath_Square_Small_1`) la coiffe
## (~0,28 m), et deux à trois degrés au sud-est montent au couronnement.
## Les deux rives de port (est/ouest, ±22°) restent DÉGAGÉES, et rien
## n'entre dans l'eau garantie de la nappe (le filet r2b_basin le juge).
func _containing_kerb() -> void:
	for i: int in range(12):
		var angle: float = TAU * float(i) / 12.0
		# Les deux rives de port restent DÉGAGÉES : ±22° autour de l'axe X.
		if absf(sin(angle)) < 0.375:
			continue
		var swell: float = _kerb_swell(angle)
		var r_x: float = WATER_HALF_X * swell + 0.18
		var r_z: float = WATER_HALF_Z * swell + 0.18
		var s_pos: Vector2 = Vector2(cos(angle) * r_x, sin(angle) * r_z)
		# Assise : bordure tangentielle, pivot au bord INTÉRIEUR (z-min du
		# module) — la profondeur (0,70 m) s'étend vers l'extérieur. Sur
		# pente (Δsol > 0,07 m sous l'empreinte), la bordure de 2 m se
		# scinde en deux de 1 m, chacune assise sur SON sol (arbitrage R2B).
		var seat_yaw: float = 90.0 - rad_to_deg(angle)
		# L'empreinte réelle s'étend du pivot vers l'EXTÉRIEUR (pivot z-min) :
		# le Δsol se mesure au centre de l'empreinte, pas au pivot.
		var footprint: Vector2 = s_pos + Vector2(cos(angle), sin(angle)) * 0.35
		if _ground_span(footprint.x, footprint.y, 1.0, 0.35, seat_yaw) \
				<= SLAB_GROUND_SPAN_MAX:
			var seat: Node3D = K.module(self, &"Prop_ExteriorBorder_Straight1",
				_seated(s_pos.x, s_pos.y), seat_yaw, 1.0, KIT_CUT_STONE)
			if seat != null:
				seat.name = "MargelleAssise_%d" % i
		else:
			var tangent: Vector2 = Vector2(-sin(angle), cos(angle)) * 0.5
			for half: int in range(2):
				var h_pos: Vector2 = s_pos + tangent * (1.0 - 2.0 * float(half))
				var seat_half: Node3D = K.module(self,
					&"Prop_ExteriorBorder_Straight1",
					_seated(h_pos.x, h_pos.y), seat_yaw, 0.5, KIT_CUT_STONE)
				if seat_half != null:
					seat_half.name = "MargelleAssise_%d_%d" % [i, half]
		# Couronnement : deux dalles carrées par segment, joints tournés —
		# et la MÊME règle de baie que l'assise (±22° dégagés).
		for step: int in range(2):
			var offset: float = deg_to_rad(-9.0 + 18.0 * float(step))
			var a: float = angle + offset
			if absf(sin(a)) < 0.375:
				continue
			var c_x: float = cos(a) * (WATER_HALF_X * _kerb_swell(a) + 0.53)
			var c_z: float = sin(a) * (WATER_HALF_Z * _kerb_swell(a) + 0.53)
			var cap: Node3D = K.module(self, &"RockPath_Square_Small_1",
				_seated(c_x, c_z) + Vector3(0.0, 0.13, 0.0),
				90.0 - rad_to_deg(a) + float((i * 7 + step * 11) % 13) - 6.0,
				1.0, KIT_CUT_STONE)
			if cap != null:
				cap.name = "MargelleDalle_%d_%d" % [i, step]
		if i % 3 == 0:
			declare_support(_seated(cos(angle) * r_x, sin(angle) * r_z))
	# LES DEGRÉS du sud-est : trois dalles qui montent au couronnement, à
	# −42° — hors des baies (±22°) et hors de l'emprise des colliders
	# nord/sud (leur z s'arrête à −2,2 ; les colliders commencent à −2,7).
	var stair_angle: float = deg_to_rad(-42.0)
	var stair_swell: float = _kerb_swell(stair_angle)
	for step: int in range(3):
		var reach: float = 1.35 - 0.525 * float(step)
		var s_x: float = cos(stair_angle) \
			* (WATER_HALF_X * stair_swell + 0.18 + reach)
		var s_z: float = sin(stair_angle) \
			* (WATER_HALF_Z * stair_swell + 0.18 + reach)
		var stair: Node3D = K.module(self, &"RockPath_Square_Small_1",
			_seated(s_x, s_z) + Vector3(0.0, 0.08 * float(step), 0.0),
			132.0 + float(step * 9), 1.0, KIT_CUT_STONE)
		if stair != null:
			stair.name = "MargelleDegre_%d" % step
	# Deux BORNES de site (NE/SO) : fûts de pilier réduits, hors des deux
	# axes de lecture (source→eau, eau→récepteur) et loin du poste de lien.
	for corner: Array in [[4.4, 4.4, 15.0], [-4.4, -4.6, 205.0]]:
		var bollard: Node3D = K.module(self, &"SM_Dungeon_PillarStub",
			_seated(float(corner[0]), float(corner[1])),
			float(corner[2]), 0.5, KIT_CUT_STONE)
		if bollard != null:
			bollard.name = "BorneSite_%d" % int(corner[0] * 10.0)
	K.collider_box(self, "Margelle_nord", _seated(0.0, 3.15)
		+ Vector3(0.0, 0.32, 0.0), Vector3(5.4, 0.64, 0.9))
	K.collider_box(self, "Margelle_sud", _seated(0.0, -3.15)
		+ Vector3(0.0, 0.32, 0.0), Vector3(5.4, 0.64, 0.9))


## Houle du contour de la margelle — les DEUX premières harmoniques de la
## nappe (`_reshape_water`), sans la septième : la margelle suit la masse
## de l'eau, pas ses cabosses fines.
func _kerb_swell(angle: float) -> float:
	return 0.86 + sin(angle * 2.0) * 0.11 + sin(angle * 3.0 + 0.7) * 0.07


## CÔTÉ SOURCE (ouest) — « ICI le courant ENTRE, et le chemin est ROMPU ».
##
## Un socle de céramique ivoire (isolant) porte le pied de la source ; un
## caniveau de pierre part vers l'eau, son rail de cuivre au fond ; et à
## 2,3 m du bord, le caniveau s'interrompt — dalles descellées, rail
## arraché, cuivre nu. Le maillon manquant que l'Arc Link vient rétablir
## devient VISIBLE, sans qu'aucune portée logique ne change.
func _source_side() -> void:
	# Le socle isolant : trois assises de céramique — dalles du kit,
	# empilées en retrait progressif. Le fanal de la source (dont le fût
	# reçoit un maillage de kit, option B) émerge de la pile.
	_ground_slab("SocleIsolant_0", -9.0, 0.0, 0.0, 0.95, IVORY_CERAMIC)
	var course_top: float = 0.171
	for i: int in range(1, 3):
		var course_scale: float = 0.95 - 0.17 * float(i)
		var course: Node3D = K.module(self, &"RockPath_Square_Wide",
			_seated(-9.0, 0.0) + Vector3(0.0, course_top, 0.0),
			float(i) * 17.0, course_scale, IVORY_CERAMIC)
		if course != null:
			course.name = "SocleIsolant_%d" % i
		course_top += 0.18 * course_scale
	declare_support(_seated(-9.0, 0.0))
	var canonical_source: ConductiveBasin = _canonical()
	if canonical_source != null:
		_dress_lamp(canonical_source.source())
	# Un PORTIQUE, pas deux blocs (mesuré sur `bassin_chaine` : sans
	# linteau, deux montants lisaient comme deux dalles plantées). R2B :
	# deux fûts de pilier, un linteau de bordure, une clé d'arche —
	# céramique ivoire, ~2,3 m à la clé. L'isolant encadre l'entrée du
	# courant, le motif reste porté par la pierre, jamais par une émission.
	for side: float in [-1.0, 1.0]:
		var post: Node3D = K.module(self, &"SM_Dungeon_PillarStub",
			_seated(-9.0, side * 1.35), 8.0 * side, 1.0, IVORY_CERAMIC)
		if post != null:
			post.name = "MontantSource_%d" % int(side)
	# Linteau : bordure tournée le long de Z (pivot z-min → sa profondeur
	# s'étend vers +X après rotation ; recentrée d'une demi-profondeur).
	var lintel: Node3D = K.module(self, &"Prop_ExteriorBorder_Straight1",
		Vector3(-9.49, _portal_ground() + 1.31, 0.0), 90.0, 1.4,
		IVORY_CERAMIC)
	if lintel != null:
		lintel.name = "LinteauSource"
	var keystone: Node3D = K.module(self, &"SM_Dungeon_ArchBlock",
		Vector3(-9.0, _portal_ground() + 1.49, 0.0), 8.0, 0.8, IVORY_CERAMIC)
	if keystone != null:
		keystone.name = "CleDuLinteau"
	# LE CANIVEAU : joues de bordure + rail de cuivre patiné au fond, de la
	# source vers l'eau. Il court de x = −7,9 à x ≈ −5,7… puis s'arrête.
	_channel_run(-7.25, -6.35, "Caniveau")
	# LA RUPTURE (x −5,9 → −3,3) : gravats, deux briques, dalles
	# descellées, et le câble arraché en cuivre vif — le maillon manquant
	# devient une architecture, pas un vide inexpliqué.
	var rubble_small: Node3D = K.module(self, &"SM_Dungeon_RubbleSmall",
		_seated(-5.3, 0.35), 25.0, 0.75, KIT_CUT_STONE)
	if rubble_small != null:
		rubble_small.name = "RuptureGravatsA"
	var rubble_large: Node3D = K.module(self, &"SM_Dungeon_RubbleLarge",
		_seated(-4.4, -0.55), 130.0, 0.55, KIT_CUT_STONE)
	if rubble_large != null:
		rubble_large.name = "RuptureGravatsB"
	# Deux briques éparses. Pivot Y CENTRÉ mesuré à la sonde d'assise
	# (`probe_kit_seating`) : posées telles quelles, elles s'enterrent à
	# moitié — on les remonte d'une demi-hauteur (0,105 m).
	for brick: Array in [[-4.9, 0.7, 40.0], [-3.75, -0.4, 155.0]]:
		var laid: Node3D = K.module(self, &"Prop_Brick1",
			_seated(float(brick[0]), float(brick[1]))
				+ Vector3(0.0, 0.105, 0.0),
			float(brick[2]), 1.0, KIT_CUT_STONE)
		if laid != null:
			laid.name = "RuptureBrique_%d" % int(brick[2])
	# Dalles descellées, culbutées hors du caniveau.
	for shard: Array in [[-5.05, 0.95, 34.0, 12.0], [-4.2, -1.0, -21.0, -9.0]]:
		var slab: Node3D = K.module(self, &"RockPath_Square_Small_1",
			_seated(float(shard[0]), float(shard[1]))
				+ Vector3(0.0, 0.07, 0.0),
			float(shard[2]), 0.85, KIT_CUT_STONE)
		if slab != null:
			slab.name = "DalleDescellee_%d" % int(shard[0] * -10.0)
			slab.rotation.z = deg_to_rad(float(shard[3]))
	# Le câble arraché : cuivre VIF — le seul accent chaud de la rupture.
	var torn: Node3D = K.module(self, &"Chain_Coil",
		_seated(-5.55, 0.2) + Vector3(0.0, 0.02, 0.0), 70.0, 0.8,
		BRIGHT_COPPER)
	if torn != null:
		torn.name = "CableArrache"


## Sol de référence du portique (le pied du montant nord) : linteau et clé
## se posent par rapport à LUI, pas chacun sur son propre sol — sinon une
## pente déchirerait l'assemblage.
func _portal_ground() -> float:
	return ground_local_y(-9.0, 0.0)


## Un tronçon de caniveau : joues de bordure des deux côtés + rail de
## cuivre patiné au fond, courant le long de X entre les centres donnés.
func _channel_run(x_start: float, x_end: float, label: String) -> void:
	var x: float = x_start
	var index: int = 0
	while x <= x_end + 0.01:
		for side: float in [-1.0, 1.0]:
			var cheek: Node3D = K.module(self, &"Prop_ExteriorBorder_Straight1",
				_seated(x, side * 0.30), 0.0 if side > 0.0 else 180.0,
				0.65, KIT_CUT_STONE)
			if cheek != null:
				cheek.name = "Joue%s_%d_%d" % [label, index, int(side)]
		# Le rail court SOUS chaque paire de joues (±0,47 m autour de son
		# centre) : côté source, il s'arrête ainsi exactement à la rupture.
		var rail: Node3D = K.module(self, &"RockPath_Round_Thin",
			_seated(x, 0.0) + Vector3(0.0, 0.02, 0.0),
			90.0, 0.45, KIT_RAIL_COPPER)
		if rail != null:
			rail.name = "Rail%s_%d" % [label, index]
		x += 0.9
		index += 1


## CÔTÉ RÉCEPTEUR (est) — « ICI ça ATTEND ». Le rail sort de l'eau, monte
## sur un socle de pierre et s'arrête sous l'anneau : le trajet est
## COMPLET de ce côté-ci ; il ne manque que le courant.
func _receiver_side() -> void:
	# Le caniveau d'arrivée : COMPLET — joues + rail, du bord du port au
	# socle. Il ne manque que le courant.
	_channel_run(4.1, 5.0, "Arrivee")
	# Le socle du récepteur : assise de pierre, chape de céramique.
	_ground_slab("SocleRecepteur_0", 5.9, 0.0, 6.0, 1.0, KIT_CUT_STONE)
	var cap_course: Node3D = K.module(self, &"RockPath_Square_Wide",
		_seated(5.9, 0.0) + Vector3(0.0, 0.18, 0.0), -9.0, 0.78,
		IVORY_CERAMIC)
	if cap_course != null:
		cap_course.name = "SocleRecepteur_1"
	declare_support(_seated(5.9, 0.0))
	var canonical_receiver: ConductiveBasin = _canonical()
	if canonical_receiver != null:
		_dress_lamp(canonical_receiver.receiver())
	# L'ANNEAU D'ATTENTE (R2B) : un cadre rond de brique SEMI-ENTERRÉ dans
	# le socle, plan vertical TOURNÉ VERS L'EAU (normale sur −X). L'arche à
	# demi engloutie dit « il manque quelque chose » sans une seule
	# lumière, et le dit aussi en niveaux de gris. Arbitrage R2B : si le
	# sol sous l'empreinte varie de plus de 0,07 m, module réduit à ~1 m.
	var ring_span: float = _ground_span(5.9, 0.0, 0.24, 0.80)
	var ring_scale: float = 1.0 if ring_span <= SLAB_GROUND_SPAN_MAX else 0.62
	var ring_name: StringName = &"DoorFrame_Round_Brick" \
		if K.scene_for(&"DoorFrame_Round_Brick") != null else &"Wall_Arch"
	var ring: Node3D = K.module(self, ring_name,
		_seated(5.9, 0.0) + Vector3(0.0, -0.85 * ring_scale, 0.0),
		90.0, ring_scale, KIT_CUT_STONE)
	if ring != null:
		ring.name = "AnneauAttente"
	# Le seuil pavé où l'on se poste pour observer le récepteur.
	for slab: Array in [[7.0, 1.0], [7.5, -0.4], [6.6, -1.4]]:
		var paving: Node3D = K.module(self, &"RockPath_Square_Wide",
			_seated(float(slab[0]), float(slab[1])),
			float(slab[0]) * 23.0, 0.58, KIT_CUT_STONE)
		if paving != null:
			paving.name = "PaveArrivee_%d" % get_child_count()


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


## Le comportement canonique, tel que `_build` l'a nommé.
func _canonical() -> ConductiveBasin:
	return get_node_or_null("BassinConducteur") as ConductiveBasin


## Δsol sous une empreinte rectangulaire (quatre coins tournés + centre) :
## la mesure qui décide de la règle « module 2 m → deux modules 1 m ».
func _ground_span(center_x: float, center_z: float, half_x: float,
		half_z: float, yaw_deg: float = 0.0) -> float:
	var yaw: float = deg_to_rad(yaw_deg)
	var axis_x: Vector2 = Vector2(cos(yaw), -sin(yaw))
	var axis_z: Vector2 = Vector2(sin(yaw), cos(yaw))
	var lowest: float = INF
	var highest: float = -INF
	for corner: Vector2 in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0),
			Vector2(-1.0, 1.0), Vector2(1.0, 1.0), Vector2.ZERO]:
		var sample: Vector2 = Vector2(center_x, center_z) \
			+ axis_x * (corner.x * half_x) + axis_z * (corner.y * half_z)
		var ground: float = ground_local_y(sample.x, sample.y)
		lowest = minf(lowest, ground)
		highest = maxf(highest, ground)
	return highest - lowest


## Une dalle de ~2 m posée AU SOL : entière quand le sol sous l'empreinte
## est plat (Δ ≤ 0,07 m), sinon scindée en deux dalles de ~1 m assises
## chacune sur SON sol (arbitrage R2B, décision transverse « pente »).
func _ground_slab(slab_name: String, local_x: float, local_z: float,
		yaw_deg: float, slab_scale: float, tone: Color) -> void:
	var half: float = 1.02 * slab_scale
	if _ground_span(local_x, local_z, half, half * 0.97, yaw_deg) \
			<= SLAB_GROUND_SPAN_MAX:
		var slab: Node3D = K.module(self, &"RockPath_Square_Wide",
			_seated(local_x, local_z), yaw_deg, slab_scale, tone)
		if slab != null:
			slab.name = slab_name
		return
	var yaw: float = deg_to_rad(yaw_deg)
	var along: Vector2 = Vector2(cos(yaw), -sin(yaw)) * (0.51 * slab_scale)
	for half_index: int in range(2):
		var at: Vector2 = Vector2(local_x, local_z) \
			+ along * (1.0 - 2.0 * float(half_index))
		var piece: Node3D = K.module(self, &"RockPath_Square_Small_1",
			_seated(at.x, at.y), yaw_deg, slab_scale, tone)
		if piece != null:
			piece.name = "%s_%d" % [slab_name, half_index]


## OPTION B (arbitrage R2B) : le fanal canonique garde son Noyau, son
## matériau émissif et son raccord `power_changed` — seuls les MAILLAGES
## du Socle et du Fût sont remplacés par des maillages du kit,
## redimensionnés à l'emprise EXACTE des boîtes d'origine (le matériau
## pierre en override reste, la silhouette seule change).
func _dress_lamp(node: ElectricNode) -> void:
	if node == null:
		return
	_swap_lamp_mesh(node.get_node_or_null("Socle"),
		&"RockPath_Square_Small_1", Vector3(0.86, 0.22, 0.86))
	_swap_lamp_mesh(node.get_node_or_null("Fut"),
		&"SM_Dungeon_PillarStub", Vector3(0.46, 0.78, 0.46))


func _swap_lamp_mesh(instance_node: Node, model: StringName,
		target: Vector3) -> void:
	var instance: MeshInstance3D = instance_node as MeshInstance3D
	if instance == null:
		return
	var mesh: Mesh = _kit_mesh(model)
	if mesh == null:
		return
	var box: AABB = mesh.get_aabb()
	if box.size.x <= 0.001 or box.size.y <= 0.001 or box.size.z <= 0.001:
		return
	# Le BAS de l'ancienne boîte (centrée) reste le bas du nouveau maillage.
	var old_bottom: float = instance.position.y - target.y * 0.5
	var fit: Vector3 = Vector3(target.x / box.size.x, target.y / box.size.y,
		target.z / box.size.z)
	instance.mesh = mesh
	instance.scale = fit
	instance.position.y = old_bottom - box.position.y * fit.y


var _kit_mesh_cache: Dictionary = {}


## Premier maillage d'un module du kit — la RESSOURCE, partagée en lecture.
func _kit_mesh(model: StringName) -> Mesh:
	if _kit_mesh_cache.has(model):
		return _kit_mesh_cache[model] as Mesh
	var packed: PackedScene = K.scene_for(model)
	if packed == null:
		return null
	var ghost: Node3D = packed.instantiate() as Node3D
	var mesh: Mesh = null
	if ghost != null:
		for child: Node in ghost.find_children("*", "MeshInstance3D",
				true, false):
			var candidate: MeshInstance3D = child as MeshInstance3D
			if candidate.mesh != null:
				mesh = candidate.mesh
				break
		ghost.free()
	_kit_mesh_cache[model] = mesh
	return mesh
