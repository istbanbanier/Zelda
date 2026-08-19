## ARBRE FOUDROYÉ (`valley.poi.thunderstruck_tree.01`, r02) — la
## merveille de la prairie, landmark ouest de la région : un doyen fendu
## par la foudre, mort d'un côté, têtu de l'autre.
##
## DEUX REJETS DU LEAD, et ce qu'il en reste :
##  * V2.3-A : « L'arbre noir entouré de fleurs jaunes ne raconte pas
##    encore la foudre » — deux modules `DeadTree` teintés ne montraient
##    ni fente, ni bois nu, ni impact. Les fleurs du LIEU ont été retirées
##    (mesure `probe_vegetation_near` : 0 instance gelée dans les 8 m) ;
##    le tapis jaune au-delà de 8 m est la prairie gelée et RESTE — c'est
##    le disque brûlé qui lui prend la vedette au premier plan.
##  * V2.3-A.R2 : la reconstruction en `K.stone_block` restait « un
##    empilement de blocs » — des boîtes, à toute distance.
##
## R2B : l'arbre est un HERO ASSET GLB (`SM_ThunderstruckTree.glb`,
## générateur `make_thunderstruck_tree.py`, loft de profils fermés) :
## souche commune large de 2,1 m, tronc UN jusqu'à 2,2 m puis V divergent,
## moitié vivante à 10,8 m, moitié morte rompue à 5,4 m avec sa couronne
## d'échardes DANS le maillage, fente à joues réelles et fond de cœur
## pâle, cicatrice en RETRAIT spiralant jusqu'au sol, deux branches
## arrachées au sol dans le même GLB (cassure pâle vers l'arbre). Le
## couple écorce sombre / cœur pâle porte la lecture en niveaux de gris.
##
## SEULE géométrie construite en runtime : le disque de sol brûlé
## (`SolBrule`), qui épouse le terrain gelé sommet par sommet — exemption
## NOMMÉE de l'arbitrage R2B, épinglée par le filet
## `test_world_v2_r2b_farm_tree.gd`.
class_name ThunderstruckTreePlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")
const ARBRE_SCENE: PackedScene = preload(
	"res://assets/architecture/flora/SM_ThunderstruckTree.glb")

## Terre vitrifiée sous l'impact. Mesuré : à 0,31 la galette ressortait
## PLUS CLAIRE que la prairie — le gain de lumière de ce monde est ≈ 1,8
## (`scripts/CLAUDE.md`), donc une « terre brûlée » d'albédo 0,31 rend
## 0,56. Abaissée pour que la brûlure lise comme une brûlure.
const SCORCH: Color = Color(0.17, 0.15, 0.13)
## 4,6 m : le disque doit ATTEINDRE la lisière du tapis de fleurs gelé
## (mesuré à ≈ 8 m du pied) sans la franchir — c'est lui qui tient le
## premier plan de la vue de composition.
const SCORCH_RADIUS_M: float = 4.6
## Plafond painterly commun aux GLB du monde (même règle que le hameau).
const ALBEDO_MAX: float = 0.80

static var _cache_materiaux: Dictionary = {}


func default_place_id() -> StringName:
	return &"valley.poi.thunderstruck_tree.01"


func _build() -> void:
	var foot: Vector3 = _seated(0.0, 0.0)
	declare_support(foot)
	# L'ordre compte : le sol brûlé D'ABORD, tout le reste se pose dessus.
	_scorched_ground(foot)

	# — LE DOYEN : une seule instance du hero asset, posée au pied. Les
	# branches arrachées font partie du GLB (leur chute appartient à
	# l'arbre) ; chacune est réassise sur le sol réel à SON emplacement —
	# aujourd'hui le site est un pad plat, mais un terrain qui bougerait ne
	# doit pas les faire flotter.
	var arbre: Node3D = ARBRE_SCENE.instantiate() as Node3D
	arbre.name = "SM_ThunderstruckTree"
	add_child(arbre)
	arbre.position = foot
	for enfant: Node in arbre.get_children():
		var piece: Node3D = enfant as Node3D
		if piece == null or not String(piece.name).contains("Branch"):
			continue
		var instance: MeshInstance3D = piece as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var centre: Vector3 = instance.mesh.get_aabb().get_center()
		piece.position.y = ground_local_y(centre.x, centre.z) - foot.y
	_peindre_glb(arbre)

	# Le tronc reste un obstacle plein — une seule masse, pas un collider
	# par bloc (le filet de couloir compte les corps, pas les copeaux).
	# Emprise IDENTIQUE à la version précédente.
	K.collider_box(self, "Tronc_col", foot + Vector3(0.0, 1.7, 0.0),
		Vector3(2.1, 3.4, 1.9))

	# — La REPOUSSE, refoulée HORS du disque brûlé : la foudre nourrit, mais
	# elle nourrit à la LISIÈRE. Un seul buisson fleuri, côté soleil — à
	# 5,6 m et pleine échelle il occupait le quart du plan rapproché (rejet
	# du lead), d'où 7,5 m et 0,65 d'échelle.
	K.module(self, &"Bush_Common_Flowers", _seated(6.9, 3.0), 30.0, 0.65,
		K.TONE_PLANT)
	K.module(self, &"Bush_Common", _seated(-6.4, 4.1), 100.0, 0.8,
		K.TONE_PLANT)
	K.module(self, &"Plant_1", _seated(5.2, -5.0), 0.0, 0.8, K.TONE_PLANT)

	# — Découverte + récompense canonique (savoir — épice rare), posée au
	# bord du disque brûlé et NON sous le tronc : l'ancre doit rester
	# atteignable, la souche fait 2,1 m de large.
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


## Le GLB porte déjà ses valeurs (sRGB converti en linéaire dans le
## générateur). On borne rugosité, spéculaire et albédo pour rester dans le
## langage painterly du monde — matériaux DUPLIQUÉS et mis en cache, jamais
## de mutation d'une ressource partagée.
func _peindre_glb(racine: Node3D) -> void:
	for node: Node in racine.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var base: StandardMaterial3D = instance.get_active_material(
				surface) as StandardMaterial3D
			if base == null:
				continue
			var cle: String = "glb|%d" % base.get_instance_id()
			var mat: StandardMaterial3D = \
				_cache_materiaux.get(cle) as StandardMaterial3D
			if mat == null:
				mat = base.duplicate() as StandardMaterial3D
				mat.roughness = maxf(mat.roughness, 0.95)
				mat.metallic_specular = 0.1
				var a: Color = mat.albedo_color
				mat.albedo_color = Color(minf(a.r, ALBEDO_MAX),
					minf(a.g, ALBEDO_MAX), minf(a.b, ALBEDO_MAX), a.a)
				_cache_materiaux[cle] = mat
			instance.set_surface_override_material(surface, mat)


## LE SOL BRÛLÉ : un disque IRRÉGULIER qui épouse le terrain gelé —
## chaque sommet du bord est reposé sur la hauteur réelle du sol, sinon
## une galette plate flotterait d'un côté et s'enterrerait de l'autre
## (le défaut mesuré sur les dalles de la grotte, groupe 1).
##
## EXEMPTION NOMMÉE de l'arbitrage R2B : ce mesh reste construit en
## runtime — même pratique que `rock_floor_mesh` — parce qu'il doit lire
## le terrain du site au montage. Le filet R2B le désigne par son nom.
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
