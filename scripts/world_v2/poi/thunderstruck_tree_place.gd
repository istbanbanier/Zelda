## ARBRE FOUDROYÉ (`valley.poi.thunderstruck_tree.01`, r02) — la
## merveille de la prairie, landmark ouest de la région : un doyen fendu
## par la foudre, mort d'un côté, têtu de l'autre.
##
## REJET DU LEAD (V2.3-A) : « L'arbre noir entouré de fleurs jaunes ne
## raconte pas encore la foudre. » Diagnostic : deux modules `DeadTree`
## teintés en noir et une lamelle pâle de 22 cm ne montrent NI la fente,
## NI le bois mis à nu, NI l'impact. Et la silhouette reposait sur la
## COULEUR (du noir dans un pré vert) — en niveaux de gris il ne restait
## qu'une tache.
##
## MESURE sur la question des fleurs, et sa LIMITE — les deux comptent.
## `tools/godot/probe_vegetation_near.gd --center=-92,132 --radius=8` →
## **0 instance** de végétation gelée dans les 8 m. Ce qui touchait le
## tronc venait donc bien du LIEU (`Flower_4_Group`, `Flower_3_Group`
## posés à 3 m du pied, et un `Bush_Common_Flowers` à 5,6 m qui occupait
## le quart du plan rapproché) : tout cela se retire sans toucher au gel,
## et c'est fait.
## Mais la capture de composition montre AUSSI un tapis jaune AU-DELÀ de
## 8 m : celui-là est la prairie gelée de r02, et il reste. La réponse
## n'est donc pas de le retirer — c'est interdit — mais de lui opposer un
## premier plan qui lui prend la vedette : le disque brûlé.
##
## Reconstruction : une souche commune, DEUX moitiés qui divergent, le
## cœur pâle visible dans la fente, une cicatrice qui DESCEND en spirale
## jusqu'au sol, des branches réellement arrachées, un disque de sol brûlé
## qui épouse le terrain et des fragments orientés par l'impact. La
## silhouette (V fendu, cime cassée, moignons) se lit sans la couleur.
class_name ThunderstruckTreePlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## Écorce carbonisée : sombre, jamais du noir pur — §1.6 interdit les
## valeurs bouchées, et un noir plat redevient une tache.
const BARK: Color = Color(0.26, 0.21, 0.17)
## Cœur mis à nu : c'est LUI qui porte la lecture en niveaux de gris.
const HEARTWOOD: Color = Color(0.84, 0.74, 0.55)
## Terre vitrifiée sous l'impact. Mesuré : à 0,31 la galette ressortait
## PLUS CLAIRE que la prairie — le gain de lumière de ce monde est ≈ 1,8
## (`scripts/CLAUDE.md`), donc une « terre brûlée » d'albédo 0,31 rend
## 0,56. Abaissée pour que la brûlure lise comme une brûlure.
const SCORCH: Color = Color(0.17, 0.15, 0.13)
## 4,6 m : le disque doit ATTEINDRE la lisière du tapis de fleurs gelé
## (mesuré à ≈ 8 m du pied) sans la franchir — c'est lui qui tient le
## premier plan de la vue de composition.
const SCORCH_RADIUS_M: float = 4.6


func default_place_id() -> StringName:
	return &"valley.poi.thunderstruck_tree.01"


func _build() -> void:
	var foot: Vector3 = _seated(0.0, 0.0)
	declare_support(foot)
	# L'ordre compte : le sol brûlé D'ABORD, tout le reste se pose dessus.
	_scorched_ground(foot)
	_stump(foot)
	_split_core(foot)
	_living_half(foot)
	_dead_half(foot)
	_descending_scar(foot)
	_torn_branches(foot)
	_impact_debris()

	# Le tronc reste un obstacle plein — une seule masse, pas un collider
	# par bloc (le filet de couloir compte les corps, pas les copeaux).
	K.collider_box(self, "Tronc_col", foot + Vector3(0.0, 1.7, 0.0),
		Vector3(2.1, 3.4, 1.9))

	# — La REPOUSSE, refoulée HORS du disque brûlé : la foudre nourrit, mais
	# elle nourrit à la LISIÈRE. Un seul buisson fleuri, côté soleil, à
	# 6,4 m — plus aucune fleur au pied (rejet du lead).
	# Repoussé à 7,5 m et réduit à 0,65 : à 5,6 m et pleine échelle, ce
	# buisson fleuri occupait le quart gauche du plan rapproché — les
	# « fleurs jaunes autour de l'arbre » du rejet, c'était lui.
	K.module(self, &"Bush_Common_Flowers", _seated(6.9, 3.0), 30.0, 0.65,
		K.TONE_PLANT)
	K.module(self, &"Bush_Common", _seated(-6.4, 4.1), 100.0, 0.8,
		K.TONE_PLANT)
	K.module(self, &"Plant_1", _seated(5.2, -5.0), 0.0, 0.8, K.TONE_PLANT)

	# — Découverte + récompense canonique (savoir — épice rare), posée au
	# bord du disque brûlé et NON sous le tronc : l'ancre doit rester
	# atteignable, la souche fait maintenant 2,1 m de large.
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Arbre foudroyé"
	poi.region = "r02_prairie_mille_fleurs"
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 11.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.RECIPE,
		_seated(-1.9, 1.7) + Vector3(0.0, 0.1, 0.0), Vector3(1.3, 0.0, -1.2))


## LA SOUCHE : le pied commun d'où partent les deux moitiés. Large, bas,
## intact — c'est ce qui prouve que l'arbre était UN avant la fente.
func _stump(foot: Vector3) -> void:
	for i: int in range(3):
		var t: float = float(i) / 2.0
		K.stone_block(self, "Souche_%d" % i,
			foot + Vector3(0.0, 0.32 + t * 1.02, 0.0),
			Vector3(2.05 - t * 0.35, 0.72, 1.85 - t * 0.30),
			float(i) * 23.0, BARK, 9100 + i, 0.09)


## LE CŒUR DE LA FENTE : un coin de bois PÂLE, planté entre les deux
## moitiés, qui s'affine en montant.
##
## Première version rejetée par la mesure (capture rapprochée du
## 2026-08-14) : le cœur était une dalle plaquée SUR chaque moitié, avec
## un lacet propre à chaque bloc. Résultat à 6 m — des planches blanches
## posées en travers de blocs sombres eux-mêmes désalignés. Un tronc ne
## se lit que si ses blocs partagent une orientation ; c'est l'écart de
## POSITION, pas de rotation, qui raconte la fente.
func _split_core(foot: Vector3) -> void:
	for i: int in range(5):
		var t: float = float(i) / 4.0
		K.stone_block(self, "CoeurDeFente_%d" % i,
			foot + Vector3(0.06, 1.52 + t * 4.55, 0.02),
			Vector3(0.92 - t * 0.52, 1.12, 0.80 - t * 0.42),
			4.0, HEARTWOOD, 9150 + i, 0.10)


## LA MOITIÉ VIVANTE (est) : six fûts au MÊME lacet, qui s'écartent du
## cœur et montent à ~9 m.
func _living_half(foot: Vector3) -> void:
	# Sept fûts jusqu'à ≈ 10,5 m : à six (8,0 m), le doyen ne dominait pas
	# la crête derrière lui et sa silhouette se perdait dans le relief.
	for i: int in range(7):
		var t: float = float(i) / 6.0
		K.stone_block(self, "FutVivant_%d" % i,
			foot + Vector3(0.78 + t * 1.45, 2.10 + t * 7.55,
				0.06 + t * 0.30),
			Vector3(1.14 - t * 0.50, 1.42, 1.06 - t * 0.44),
			10.0, BARK, 9200 + i, 0.10)


## LA MOITIÉ MORTE (ouest) : quatre fûts seulement, cassés net à ~5,4 m,
## et trois échardes de cœur pâle qui montrent la RUPTURE.
func _dead_half(foot: Vector3) -> void:
	for i: int in range(4):
		var t: float = float(i) / 3.0
		K.stone_block(self, "FutMort_%d" % i,
			foot + Vector3(-0.72 - t * 1.18, 2.00 + t * 2.85,
				-0.08 - t * 0.22),
			Vector3(1.00 - t * 0.28, 1.24, 0.94 - t * 0.24),
			-14.0, BARK, 9300 + i, 0.11)
	# La cassure : trois échardes divergentes, cœur nu vers le ciel.
	for splinter: Array in [[-1.85, 5.55, -0.38, -26.0, 1.35],
			[-1.52, 5.86, 0.02, -9.0, 1.72], [-2.06, 5.40, 0.34, 16.0, 1.05]]:
		var shard: MeshInstance3D = K.stone_block(self,
			"Echarde_%d" % get_child_count(),
			foot + Vector3(float(splinter[0]), float(splinter[1]),
				float(splinter[2])),
			Vector3(0.20, float(splinter[4]), 0.24), 0.0, HEARTWOOD,
			9330 + get_child_count(), 0.14)
		shard.rotation.z = deg_to_rad(float(splinter[3]))
		shard.rotation.x = deg_to_rad(float(splinter[0]) * 5.0)


## LA CICATRICE DESCENDANTE : ce que la foudre laisse VRAIMENT — une
## bande de bois mis à nu qui s'enroule autour du fût vivant, de la
## fourche jusqu'au sol. Neuf éclats, en spirale, de plus en plus larges
## vers le bas (l'arc a chassé l'écorce en s'élargissant).
func _descending_scar(foot: Vector3) -> void:
	for i: int in range(7):
		var t: float = float(i) / 6.0
		var angle: float = deg_to_rad(-34.0 + t * 190.0)
		# La cicatrice COLLE au fût vivant : son rayon suit l'affinement du
		# tronc, sinon les marques flottent à côté (défaut mesuré).
		var radius: float = 0.56 - t * 0.06
		var y: float = 7.40 - t * 6.20
		var lean: float = 0.78 + (1.0 - t) * 1.32
		var centre: Vector3 = foot + Vector3(
			lean + cos(angle) * radius, y, 0.10 + sin(angle) * radius * 0.92)
		var mark: MeshInstance3D = K.stone_block(self, "Cicatrice_%d" % i,
			centre, Vector3(0.34 + t * 0.26, 0.92 - t * 0.12, 0.22),
			rad_to_deg(-angle), HEARTWOOD, 9400 + i, 0.13)
		mark.rotation.z = deg_to_rad(-12.0 + t * 8.0)


## BRANCHES ARRACHÉES : trois moignons encore accrochés (bout déchiré vers
## l'extérieur) et quatre branches au sol, dont la cassure REGARDE l'arbre
## — elles sont tombées d'ici, pas apportées par le vent.
func _torn_branches(foot: Vector3) -> void:
	for stub: Array in [[4.60, 44.0, 1.35], [7.00, -32.0, 1.10],
			[9.10, 108.0, 0.88]]:
		var y: float = float(stub[0])
		var yaw: float = float(stub[1])
		var length: float = float(stub[2])
		var t: float = clampf((y - 2.10) / 7.55, 0.0, 1.0)
		var base: Vector3 = foot + Vector3(0.78 + t * 1.45, y, 0.06 + t * 0.30)
		var direction: Vector3 = Vector3(cos(deg_to_rad(yaw)), 0.30,
			sin(deg_to_rad(yaw))).normalized()
		var branch: MeshInstance3D = K.stone_block(self,
			"Moignon_%.0f" % y, base + direction * (length * 0.5),
			Vector3(length, 0.26, 0.24), yaw, BARK, 9500 + int(y * 10.0), 0.10)
		branch.rotation.z = deg_to_rad(17.0)
		K.stone_block(self, "MoignonCoeur_%.0f" % y,
			base + direction * (length + 0.06),
			Vector3(0.16, 0.24, 0.22), yaw, HEARTWOOD,
			9520 + int(y * 10.0), 0.18)
	for fallen: Array in [[2.9, -1.7, 118.0, 3.1], [-3.4, -2.2, 44.0, 2.4],
			[1.6, 3.5, 206.0, 2.7], [-2.4, 2.9, 320.0, 2.0]]:
		var at: Vector3 = _seated(float(fallen[0]), float(fallen[1]))
		var yaw: float = float(fallen[2])
		var length: float = float(fallen[3])
		var log_piece: MeshInstance3D = K.stone_block(self,
			"BrancheAuSol_%.0f" % yaw, at + Vector3(0.0, 0.20, 0.0),
			Vector3(length, 0.32, 0.30), yaw, BARK, 9600 + int(yaw), 0.12)
		log_piece.rotation.z = deg_to_rad(float(fallen[1]) * 1.4)
		# La cassure pâle, tournée vers le pied.
		var toward: Vector3 = (Vector3.ZERO - Vector3(at.x, 0.0, at.z)).normalized()
		K.stone_block(self, "Cassure_%.0f" % yaw,
			at + Vector3(0.0, 0.22, 0.0) + toward * (length * 0.46),
			Vector3(0.18, 0.30, 0.28), yaw, HEARTWOOD, 9620 + int(yaw), 0.16)


## FRAGMENTS ORIENTÉS PAR L'IMPACT : neuf éclats carbonisés dont le grand
## axe pointe vers l'EXTÉRIEUR — la direction raconte la détonation.
func _impact_debris() -> void:
	# Six éclats, pas neuf, et ÉPAIS : à 0,18 m d'épaisseur ils rendaient
	# des plaques noires plates posées sur la brûlure.
	for i: int in range(6):
		var angle: float = TAU * float(i) / 6.0 + 0.31
		var radius: float = 2.05 + fposmod(float(i) * 1.37, 1.0) * 1.5
		var at: Vector3 = _seated(cos(angle) * radius, sin(angle) * radius)
		var chip: MeshInstance3D = K.stone_block(self, "Eclat_%d" % i,
			at + Vector3(0.0, 0.20, 0.0),
			Vector3(0.72 + fposmod(float(i) * 0.7, 1.0) * 0.5, 0.38, 0.34),
			rad_to_deg(angle), BARK, 9700 + i, 0.16)
		chip.rotation.z = deg_to_rad(fposmod(float(i) * 11.0, 14.0) - 7.0)


## LE SOL BRÛLÉ : un disque IRRÉGULIER qui épouse le terrain gelé —
## chaque sommet du bord est reposé sur la hauteur réelle du sol, sinon
## une galette plate flotterait d'un côté et s'enterrerait de l'autre
## (le défaut mesuré sur les dalles de la grotte, groupe 1).
func _scorched_ground(foot: Vector3) -> void:
	var disc: MeshInstance3D = MeshInstance3D.new()
	disc.name = "SolBrule"
	var segments: int = 30
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim: PackedVector3Array = PackedVector3Array()
	for i: int in range(segments + 1):
		var angle: float = TAU * float(i % segments) / float(segments)
		var r: float = SCORCH_RADIUS_M * (0.72 + sin(angle * 2.0) * 0.16
			+ sin(angle * 5.0 + 1.1) * 0.11)
		var x: float = cos(angle) * r
		var z: float = sin(angle) * r
		rim.append(Vector3(x, ground_local_y(x, z) - foot.y + 0.045, z))
	var centre: Vector3 = Vector3(0.0, 0.06, 0.0)
	for i: int in range(segments):
		var shade: float = 0.82 + float(i % 4) * 0.06
		var normal: Vector3 = Vector3.UP
		for point: Vector3 in [centre, rim[i], rim[i + 1]]:
			st.set_color(Color(shade, shade, shade, 1.0))
			st.set_normal(normal)
			st.add_vertex(point)
	disc.mesh = st.commit()
	var material: StandardMaterial3D = K.flat_material(SCORCH)
	material.vertex_color_use_as_albedo = true
	disc.mesh.surface_set_material(0, material)
	disc.position = foot
	add_child(disc)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
