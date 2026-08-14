## ARCHE DE PIERRE (`valley.poi.stone_bridge.01`, r03) — l'ouvrage qui
## franchit le chenal principal, en aval du gué central.
##
## CE SCRIPT N'EST PLUS UN MODELEUR. R2a : la surface artistique vient d'un
## maillage Blender versionné
## (`source_assets/blender/architecture/make_stone_bridge.py` ->
## `assets/architecture/stone_bridge/SM_StoneBridge_Arch.glb`). Ici on
## instancie, on implante, on pose les collisions et on VÉRIFIE que le
## terrain gelé est bien celui qui a servi à générer. La version précédente
## empilait environ 250 `BoxMesh` irrégulières ; c'est ce que la règle de
## production interdit désormais.
##
## POURQUOI L'OUVRAGE A CHANGÉ DE PLACE. La version rejetée courait le long
## de `x = -21`, de `z = 14` à `z = -2`. Trois coupes `probe_site_section`
## (pas 2 m, 1 m, 0,5 m) montrent que le chenal principal court NORD-SUD —
## centre `x = -27,5` en `z = -15`, `x = -21,5` en `z = +2`, soit 19,4° de
## l'axe Z. Cet axe-là était donc PARALLÈLE au fleuve : le sol y vaut −1,8
## en eau sur 23 m continus, et la culée nord se dressait en plein chenal à
## 9 m de la berge la plus proche. Ce n'était pas un défaut de modelage —
## il n'y avait PAS DE BERGE OÙ ANCRER.
##
## L'ouvrage traverse maintenant en `(-23,5 ; -3,5)`, perpendiculairement au
## chenal (azimut 341°) : 9,3 m d'eau entre deux berges qui montent à
## 1,00 m/m jusqu'à +2,9 et +3,3. Il est à 28,8 m du `v2_site`, contre
## 19,4 m auparavant — un ajustement de 9,4 m d'un ouvrage déjà décalé, et
## il n'existe aucune traversée berge-à-berge à moins de 25 m du site. La
## racine du lieu, elle, NE BOUGE PAS : elle reste sur son `v2_site`.
##
## Se mettre d'équerre sur la rivière paie une troisième fois, en lumière :
## le soleil est à l'azimut 199,5° / élévation 23,0° (mesuré dans
## `WorldV2.tscn`, `Lighting/Sun` : sa colonne −Z vaut (0,8677 ; −0,3907 ;
## 0,3073)). La face aval de l'ouvrage, de normale 250,6°, reçoit 0,578
## d'éclairement ; posée plein est-ouest elle n'aurait reçu que 0,307.
##
## Gué central (ISS-032) : le point de maçonnerie le plus proche d'un
## échantillon de rayon de gué est à 10,8 m, contre 2,2 m auparavant.
class_name StoneBridgePlace
extends WorldV2Place

const BRIDGE_MESH: PackedScene = preload(
	"res://assets/architecture/stone_bridge/SM_StoneBridge_Arch.glb")

## Centre de la traversée, en coordonnées LOCALES du lieu (racine = v2_site
## (-10 ; 22)). Monde : (-23,5 ; -3,5).
const CROSSING_LOCAL: Vector2 = Vector2(-13.5, -25.5)
## Lacet de l'axe : +X local du maillage -> monde (0,9429 ; -0,3331).
const AXIS_YAW_DEG: float = 19.45
## Le maillage a sa base de fondation à Y = 0 ; elle se pose 0,70 m sous le
## lit, qui est le sol au centre de la traversée.
const FOUNDATION_BELOW_BED_M: float = 0.70

## Cotes du maillage, en repère MODÈLE (Y = hauteur au-dessus de la
## fondation). Elles doivent rester d'accord avec `make_stone_bridge.py` ;
## la scène ne les recalcule pas, elle s'en sert pour poser les collisions.
const Y_DECK_CROWN: float = 6.45
const Y_DECK_SHOULDER: float = 6.35
const Y_RAMP_W: float = 5.60
const Y_RAMP_E: float = 5.90
const X_ABUTMENT: float = 8.60
const X_RAMP_W: float = -12.60
const X_RAMP_E: float = 11.50
const X_PARAPET_W: float = -9.40
const X_PARAPET_E: float = 9.40
const PARAPET_H: float = 0.98
const BREACH_X: Vector2 = Vector2(1.30, 4.55)

## PROFIL DE TERRAIN CUIT DANS LE GÉNÉRATEUR — littéraux épinglés
## (PROMPT4 §4). Blender ne peut pas interroger Godot ; le terrain, lui, est
## GELÉ. Le générateur travaille donc sur cette table mesurée à la sonde, et
## c'est ICI qu'on la confronte au réel. Sans cette confrontation la table
## se dégrade en silence et l'ouvrage se met à flotter ou à s'enterrer sans
## que rien ne le dise — c'est exactement le mode de panne qui a produit une
## culée en plein chenal.
## (abscisse le long de l'axe, hauteur MONDE du sol)
const BAKED_GROUND: Array[Vector2] = [
	Vector2(-12.6, 3.00), Vector2(-9.0, 3.00), Vector2(-6.0, 0.41),
	Vector2(-4.9, -0.79), Vector2(0.0, -1.90), Vector2(4.9, -0.89),
	Vector2(7.0, 1.39), Vector2(9.0, 3.10), Vector2(11.5, 3.30),
]
const GROUND_DRIFT_TOLERANCE_M: float = 0.35

var _axis: Vector2 = Vector2.ZERO
var _lit_side: Vector2 = Vector2.ZERO


func default_place_id() -> StringName:
	return &"valley.poi.stone_bridge.01"


func _build() -> void:
	# Axe et normale de la face éclairée, dans le plan XZ du monde. Le lacet
	# envoie le +X local sur (cos ; -sin) ; la face éclairée est le -Z local,
	# soit (-sin ; -cos) = (axe.y ; -axe.x).
	_axis = Vector2(cos(deg_to_rad(AXIS_YAW_DEG)), -sin(deg_to_rad(AXIS_YAW_DEG)))
	_lit_side = Vector2(_axis.y, -_axis.x)

	var bed: float = ground_local_y(CROSSING_LOCAL.x, CROSSING_LOCAL.y)
	var bridge: Node3D = Node3D.new()
	bridge.name = "Ouvrage"
	bridge.position = Vector3(CROSSING_LOCAL.x, bed - FOUNDATION_BELOW_BED_M,
		CROSSING_LOCAL.y)
	bridge.rotation.y = deg_to_rad(AXIS_YAW_DEG)
	add_child(bridge)

	var mesh_root: Node3D = BRIDGE_MESH.instantiate() as Node3D
	mesh_root.name = "Maconnerie"
	bridge.add_child(mesh_root)

	_colliders(bridge)
	_declare_supports()
	_verify_baked_ground()

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Arche de pierre"
	poi.region = "r03_val_de_neris"
	poi.position = Vector3(CROSSING_LOCAL.x, bed + 2.0, CROSSING_LOCAL.y)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 14.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)

	# Le fragment d'histoire se pose sur la berge est, À CÔTÉ de la rampe et
	# hors de toute maçonnerie : le rayon vertical d'une ancre doit toucher
	# le terrain NU (contrat §3.3). t = 11,8 le met au-delà du mur en aile,
	# s = 5,4 bien en dehors du demi-tablier (2,34) et de l'aile (4,22).
	var reward_at: Vector2 = _axis_local(11.8, 5.4)
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.STORY,
		Vector3(reward_at.x, ground_local_y(reward_at.x, reward_at.y) + 0.15,
			reward_at.y),
		Vector3(-_axis.x, 0.0, -_axis.y))


## Point du plan, en coordonnées LOCALES du lieu, à l'abscisse `along` le
## long de l'axe et au décalage `lateral` vers la face ÉCLAIRÉE (aval).
func _axis_local(along: float, lateral: float) -> Vector2:
	return CROSSING_LOCAL + _axis * along + _lit_side * lateral


## Arase du tablier (repère modèle) à l'abscisse `x`.
func _deck_top(x: float) -> float:
	var a: float = absf(x)
	if a <= 4.90:
		return Y_DECK_CROWN - 0.10 * pow(a / 4.90, 2.0)
	if a <= X_ABUTMENT:
		return Y_DECK_SHOULDER
	if x < 0.0:
		var s: float = (-X_ABUTMENT - x) / (-X_ABUTMENT - X_RAMP_W)
		return Y_DECK_SHOULDER + (Y_RAMP_W - Y_DECK_SHOULDER) * s
	var t: float = (x - X_ABUTMENT) / (X_RAMP_E - X_ABUTMENT)
	return Y_DECK_SHOULDER + (Y_RAMP_E - Y_DECK_SHOULDER) * t


## COLLISIONS — simples, peu nombreuses, et posées SOUS le nœud de
## l'ouvrage pour hériter du lacet. Le maillage n'en porte aucune : un
## `.glb` d'architecture ne doit jamais fournir de collision concave.
func _colliders(bridge: Node3D) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Collisions"
	body.collision_layer = 1
	body.collision_mask = 0
	bridge.add_child(body)

	# Chaussée : trois dalles, dont deux INCLINÉES qui suivent les rampes.
	# Une marche d'escalier à chaque changement de pente se sentirait au
	# pied ; une dalle inclinée non.
	_slab(body, "Tablier", -X_ABUTMENT, X_ABUTMENT,
		_deck_top(-X_ABUTMENT), _deck_top(X_ABUTMENT), 4.32, 0.60)
	_slab(body, "RampeOuest", X_RAMP_W, -X_ABUTMENT,
		_deck_top(X_RAMP_W), _deck_top(-X_ABUTMENT), 4.32, 0.60)
	_slab(body, "RampeEst", X_ABUTMENT, X_RAMP_E,
		_deck_top(X_ABUTMENT), _deck_top(X_RAMP_E), 4.32, 0.60)

	# Massifs de culée : l'ouvrage est un obstacle plein sous le tablier,
	# pas un décor traversable.
	for side: float in [-1.0, 1.0]:
		_box(body, "Culee%s" % ("O" if side < 0.0 else "E"),
			Vector3(side * 6.75, 3.05, 0.0), Vector3(3.70, 6.10, 4.32))

	# Parapets : celui de la face éclairée est COUPÉ par la brèche — un
	# parapet ruiné qui arrête encore le joueur serait un mensonge.
	_parapet_colliders(body, -1.0, true)
	_parapet_colliders(body, 1.0, false)


func _parapet_colliders(body: StaticBody3D, z_sign: float,
		breached: bool) -> void:
	var spans: Array[Vector2] = [Vector2(X_PARAPET_W, X_PARAPET_E)]
	if breached:
		spans = [Vector2(X_PARAPET_W, BREACH_X.x),
			Vector2(BREACH_X.y, X_PARAPET_E)]
	var index: int = 0
	for span: Vector2 in spans:
		index += 1
		var mid: float = (span.x + span.y) * 0.5
		_box(body, "Parapet%s_%d" % ["N" if z_sign < 0.0 else "S", index],
			Vector3(mid, _deck_top(mid) + PARAPET_H * 0.5, z_sign * 1.95),
			Vector3(span.y - span.x, PARAPET_H, 0.42))


func _box(parent: Node3D, box_name: String, at: Vector3,
		size: Vector3) -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = box_name
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	parent.add_child(shape)


## Dalle INCLINÉE entre deux abscisses et deux arases.
func _slab(parent: Node3D, slab_name: String, x0: float, x1: float,
		y0: float, y1: float, width: float, thickness: float) -> void:
	var length: float = Vector2(x1 - x0, y1 - y0).length()
	var pitch: float = atan2(y1 - y0, x1 - x0)
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = slab_name
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(length, thickness, width)
	shape.shape = box
	shape.position = Vector3((x0 + x1) * 0.5,
		(y0 + y1) * 0.5 - thickness * 0.5 * cos(pitch), 0.0)
	shape.rotation.z = pitch
	parent.add_child(shape)


## Appuis structurels DÉCLARÉS — le filet des fondations vérifie que chacun
## touche le sol gelé à 0,65 m près. Ils sont calculés PAR le sol, donc
## exacts par construction ; leur rôle est de dire au filet OÙ l'ouvrage
## prend appui : les deux bouts de rampe, les deux culées et le lit.
func _declare_supports() -> void:
	for along: float in [-12.4, -8.6, -4.9, 0.0, 4.9, 8.6, 11.3]:
		var p: Vector2 = _axis_local(along, 0.0)
		declare_support(Vector3(p.x, ground_local_y(p.x, p.y), p.y))


## CONTRÔLE 4, VERSANT GODOT — le terrain cuit dans le générateur est-il
## toujours le vrai ? Voir `BAKED_GROUND`.
func _verify_baked_ground() -> void:
	var worst: float = 0.0
	var worst_at: float = 0.0
	var measured: bool = false
	for sample: Vector2 in BAKED_GROUND:
		var p: Vector2 = _axis_local(sample.x, 0.0)
		var local_y: float = ground_local_y(p.x, p.y)
		if not is_zero_approx(local_y):
			measured = true
		var drift: float = absf(local_y + global_position.y - sample.y)
		if drift > worst:
			worst = drift
			worst_at = sample.x
	if not measured:
		return  # scène autonome, hors monde : rien à confronter
	if worst > GROUND_DRIFT_TOLERANCE_M:
		push_error(("[stone_bridge] le terrain a DÉRIVÉ de %.2f m à " +
			"l'abscisse %.1f (tolérance %.2f) — le profil cuit dans " +
			"make_stone_bridge.py ne décrit plus la vallée ; régénérer " +
			"l'asset avant de croire cette implantation.")
			% [worst, worst_at, GROUND_DRIFT_TOLERANCE_M])
