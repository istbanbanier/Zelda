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
## 0,56. Abaissée pour que la brûlure lise comme une brûlure ; remontée de
## 0,17 à 0,20 en R2B.1 parce que le lead voyait « un socle noir opaque
## qui masque la lecture du tronc » — c'est la teinte de BORD, dégradée
## vers la prairie, qui règle vraiment ce défaut (voir `_scorched_ground`).
const SCORCH: Color = Color(0.20, 0.175, 0.150)
## 2,7 m au lieu de 4,6. Le disque r02 couvrait 34,5 m², soit 3,9 fois
## l'emprise de la souche : ce n'était plus une brûlure, c'était un socle.
## À 2,7 il couvre 19 m² et s'arrête au bord de la plaque de racines, ce
## qui est la lecture juste — la foudre a vitrifié le pied, pas la prairie.
const SCORCH_RADIUS_M: float = 2.7
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
	var segments: int = 44
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# LE BORD N'EST PLUS HARMONIQUE. Le r02 modulait son rayon par
	# `sin(a·2)·0,16 + sin(a·5+1,1)·0,11` : deux raies pures, cinq lobes
	# réguliers, rmax/rmin = 2,13 — mesuré, et c'est exactement l'« étoile »
	# que le lead a vue. Ici le rayon vient d'un hachage par secteur, lissé
	# sur trois voisins : la modulation n'a plus de période, et son énergie
	# se répartit au lieu de tenir dans une raie.
	var brut: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(segments):
		brut.append(_alea(float(i) * 1.7 + 4.3))
	var rayons: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(segments):
		var lisse: float = (brut[(i - 1 + segments) % segments] + brut[i]
			+ brut[(i + 1) % segments]) / 3.0
		rayons.append(SCORCH_RADIUS_M * (0.92 + 0.16 * lisse))
	# DEUX ANNEAUX. Un disque à un seul anneau part d'un sommet central
	# unique : trente secteurs identiques en éventail, que la teinte
	# périodique `0,82 + (i%4)·0,06` soulignait encore. L'anneau
	# intermédiaire casse l'éventail, et la teinte de bord remonte vers la
	# prairie pour que la brûlure s'éteigne au lieu de se découper.
	var interieur: PackedVector3Array = PackedVector3Array()
	var exterieur: PackedVector3Array = PackedVector3Array()
	var teinte_int: PackedFloat32Array = PackedFloat32Array()
	var teinte_ext: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		var r_ext: float = rayons[i]
		var r_int: float = r_ext * (0.40 + 0.09 * _alea(float(i) * 3.1 + 19.0))
		var xi: float = cos(angle) * r_int
		var zi: float = sin(angle) * r_int
		var xe: float = cos(angle) * r_ext
		var ze: float = sin(angle) * r_ext
		interieur.append(Vector3(xi, ground_local_y(xi, zi) - foot.y + 0.050, zi))
		exterieur.append(Vector3(xe, ground_local_y(xe, ze) - foot.y + 0.045, ze))
		teinte_int.append(0.74 + 0.10 * _alea(float(i) * 5.9 + 2.0))
		teinte_ext.append(1.16 + 0.20 * _alea(float(i) * 7.3 + 31.0))
	var centre: Vector3 = Vector3(0.0, 0.062, 0.0)
	for i: int in range(segments):
		var j: int = (i + 1) % segments
		_triangle_degrade(st, centre, interieur[i], interieur[j],
			0.62, teinte_int[i], teinte_int[j])
		_triangle_degrade(st, interieur[i], exterieur[i], exterieur[j],
			teinte_int[i], teinte_ext[i], teinte_ext[j])
		_triangle_degrade(st, interieur[i], exterieur[j], interieur[j],
			teinte_int[i], teinte_ext[j], teinte_int[j])
	disc.mesh = st.commit()
	var material: StandardMaterial3D = K.flat_material(SCORCH)
	material.vertex_color_use_as_albedo = true
	disc.mesh.surface_set_material(0, material)
	disc.position = foot
	add_child(disc)


## Hachage déterministe dans [−1 ; 1]. Pas de `randf()` : le disque doit
## être identique d'un montage à l'autre, sinon la régression visuelle
## compare deux formes différentes et ne prouve rien.
func _alea(graine: float) -> float:
	var v: float = sin(graine * 127.1 + 311.7) * 43758.5453
	return (v - floor(v)) * 2.0 - 1.0


## Un triangle dont CHAQUE SOMMET porte sa valeur. `K._triangle` existe et
## fait presque la même chose, mais avec UNE valeur pour tout le triangle :
## c'est justement ce qu'il ne faut pas ici, puisque le dégradé du cœur
## vitrifié vers le bord cendreux est ce qui empêche le disque de se lire
## comme une plaque découpée. Deux fonctions voisines, une raison nommée.
func _triangle_degrade(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		ta: float, tb: float, tc: float) -> void:
	for paire: Array in [[a, ta], [b, tb], [c, tc]]:
		var t: float = paire[1]
		st.set_color(Color(t, t, t, 1.0))
		st.set_normal(Vector3.UP)
		st.add_vertex(paire[0])


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)

## ISS-059 — fin de vie du cache statique. Inscrite au démarrage du
## script par `_static_init()`, appelée UNE fois à l'extinction du moteur
## par `SceneFlow._exit_tree()`. Sans elle, ces entrées vivent jusqu'à la
## mort du processus et sortent au rapport de fuite : mesure et ablation à
## variable unique, `evidence/…/v2_3_r2b3_1/iss059/CHAINE_CAUSALE.md`.
##
## Le sens de la dépendance est imposé : le porteur connaît le noyau, le
## noyau ne connaît aucun porteur (test_aucune_reference_croisee_interdite).
static func _static_init() -> void:
	StaticResourceCaches.enregistrer("ThunderstruckTreePlace", liberer_caches)


static func liberer_caches() -> int:
	var n: int = _cache_materiaux.size()
	_cache_materiaux.clear()
	return n
