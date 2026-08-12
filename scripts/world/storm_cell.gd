## Cellule d'orage LOCALE au-dessus de la citadelle (Passe V4.1, réf. 01 du
## pack V4 : « orage ardoise localisé », « le monde n'est jamais uniformément
## sombre »).
##
## §7.6 : Godot n'a pas les nuages volumétriques d'Unreal — l'orage graybox est
## fait de couches de meshes aplatis, sombres et superposés. La LOCALITÉ est un
## invariant testé : le rayon des couches est borné, la crête de départ reste
## sous le ciel doré.
##
## L'éclair est DÉTERMINISTE (seed fixe) : tracé irrégulier reproductible et
## première frappe qui couvre la fenêtre de la capture de référence (§21.8,
## §7.6 : « un éclair majeur simultané dans la vue d'ouverture »). Cadence
## irrégulière ensuite. Cœur blanc, halo cyan (§7.6) ; le tonnerre attend la
## Phase audio.
class_name StormCell
extends Node3D

## Valeurs REMONTÉES avec le passage du nuage en rendu éclairé (voir
## `_cloud_material`). En aplat non éclairé, l'albédo était la couleur finale et
## `CLOUD_DARK` tombait à 17 % de luminance — sous le plancher de 18 % que la
## bible §1.5 fixe aux ombres (« jamais bouchées »). Éclairées, ces mêmes
## couleurs perdraient encore de la valeur sur les faces à l'ombre : on les
## remonte pour que le ventre du nuage reste lisible au lieu de devenir un trou
## noir. Le juge final est la capture, pas ce commentaire.
const CLOUD_SLATE: Color = Color(0.34, 0.36, 0.42)
const CLOUD_DARK: Color = Color(0.25, 0.26, 0.31)
const BOLT_CORE: Color = Color(0.925, 1.0, 1.0)      # #ECFFFF
const BOLT_HALO: Color = Color(0.133, 0.851, 0.925)  # #22D9EC

## Localité de l'orage — invariant V4 vérifié par test.
const MAX_CLOUD_RADIUS: float = 90.0
## Seed fixe : même tracé d'éclair et même cadence à chaque lancement (§21.8).
const STORM_SEED: int = 20260801

@export var cloud_radius: float = 68.0
## Origine du tracé d'éclair, dans le ventre du nuage. Constante NOMMÉE :
## le test de la colonne (≥ 15 m) mesure |BOLT_ORIGIN − strike_offset|.
const BOLT_ORIGIN: Vector3 = Vector3(0, -4.0, 0)

## Point d'impact, en coordonnées LOCALES de la cellule. L'éclair frappe le
## SOMMET DE LA SPIRE (y = 100, z = −212 — passe H-1), pas un toit : la
## cellule plane à y 122, z −215 → local (0, −22, 3). Colonne de ~18 m depuis
## le ventre (−4) — les 14 m de H-1 se perdaient dans la jupe du nuage
## (mesure H-2). Toujours dans le cadre §3.2 (haut de frame à 360 m ≈ y 123 ;
## un nuage à 130 en sortait entièrement, 3e capture — à 122, seuls les
## grumeaux hauts sont rognés, c'est la place du nuage dans la référence).
## Invariants testés : |impact − sommet de spire| ≤ 6 m ; colonne ≥ 15 m.
@export var strike_offset: Vector3 = Vector3(0, -22.0, 3.0)
## Première frappe : allumée à 0,6 s, éteinte à 1,1 s — la capture (60 frames,
## ~1 s) tombe DANS la fenêtre.
@export var first_flash_at: float = 0.6
@export var flash_duration: float = 0.5

var _bolt_root: Node3D = null
var _flash_light: OmniLight3D = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _flash_timer: Timer = null
var _flashing: bool = false


func _ready() -> void:
	_rng.seed = STORM_SEED
	_build_clouds()
	_build_rain_veil()
	_build_bolt()
	_flash_light = OmniLight3D.new()
	_flash_light.name = "FlashLight"
	_flash_light.light_color = BOLT_HALO
	_flash_light.light_energy = 0.0
	_flash_light.omni_range = 55.0
	_flash_light.position = strike_offset + Vector3(0, 8, 0)
	add_child(_flash_light)

	_flash_timer = Timer.new()
	_flash_timer.one_shot = true
	_flash_timer.wait_time = first_flash_at
	_flash_timer.timeout.connect(_on_flash_timer)
	add_child(_flash_timer)
	_flash_timer.start()


## Masse cumuliforme granulaire — ventre sombre, sommets ardoise, bord chaud
## côté soleil. `disable_fog` garde le nuage SOMBRE à 360 m : c'est son
## contraste avec le ciel doré qui porte la menace, la brume le fondait dans
## l'horizon.
##
## PASSE 3 (2026-08-12, proxys des caméras 5-6) : les huit grumeaux du ventre
## faisaient jusqu'à 41 m de rayon pour 62 m de haut — depuis l'approche
## (caméra 6), le haut du cadre était le dessous LISSE d'une seule sphère, et
## leur ventre descendait à y ≈ 92 : la couronne de la spire (y ≈ 98)
## transperçait le nuage. §9.2 : « base sombre APLATIE au-dessus de la
## spire », bords « plus clairs et chauds côté soleil ». La masse devient
## GRANULAIRE (22 grumeaux ≤ 22 m de rayon, chevauchés), son plancher reste
## au-dessus de la spire, et quatre grumeaux chauds prennent le soleil à
## l'ouest. Les grumeaux restent DODUS (ratio testé ≥ 0,8) : c'est la
## soucoupe qu'on interdit à 360 m, pas la masse.
## Invariants passe 3 : `test_storm_cloud_hangs_above_the_spire.gd`.
func _build_clouds() -> void:
	cloud_radius = minf(cloud_radius, MAX_CLOUD_RADIUS)
	# Jupe-enclume : le ventre plat et sombre d'un cumulonimbus, d'où sort
	# l'éclair. PAS une seule sphère : une enclume de 63 m de rayon relisait
	# « soucoupe lisse » depuis la crête — recapture du 2026-08-12, la forme
	# exacte que l'invariant anti-galette combattait. La base est un ANNEAU
	# de galettes chevauchées plus une galette centrale : le bord scalopé
	# remplace l'ellipse propre, et chaque pièce reste sous le plafond de
	# rayon que le test impose désormais à TOUTES les sphères du nuage.
	var skirt_center: MeshInstance3D = MeshInstance3D.new()
	skirt_center.name = "CloudBase"
	var center_sphere: SphereMesh = SphereMesh.new()
	center_sphere.radius = 22.0
	center_sphere.height = 7.5
	center_sphere.radial_segments = 24
	center_sphere.rings = 8
	skirt_center.mesh = center_sphere
	skirt_center.material_override = _cloud_material(CLOUD_DARK)
	skirt_center.position = Vector3(0, -8.0, 0)
	add_child(skirt_center)
	for i: int in range(9):
		var pancake: MeshInstance3D = MeshInstance3D.new()
		pancake.name = "CloudSkirt%d" % i
		var disc: SphereMesh = SphereMesh.new()
		disc.radius = _rng.randf_range(15.0, 23.0)
		disc.height = _rng.randf_range(5.5, 8.0)
		disc.radial_segments = 24
		disc.rings = 8
		pancake.mesh = disc
		pancake.material_override = _cloud_material(CLOUD_DARK)
		var ring_angle: float = TAU * float(i) / 9.0 + _rng.randf_range(-0.2, 0.2)
		var ring_span: float = cloud_radius * _rng.randf_range(0.42, 0.70)
		pancake.position = Vector3(cos(ring_angle) * ring_span,
			-8.5 + _rng.randf_range(-0.8, 0.8), sin(ring_angle) * ring_span)
		add_child(pancake)
	# Plancher LOCAL du ventre : cellule à y 122 monde, spire à 100 — un
	# grumeau ne descend jamais sous −14 local (108 monde, 8 m d'air).
	const BELLY_FLOOR: float = -14.0
	var lump_index: int = 0
	# Ventre : douze grumeaux serrés — le dessous se lit comme un chou-fleur
	# renversé, pas comme trois arches.
	for i: int in range(12):
		var radius: float = _rng.randf_range(0.13, 0.24) * cloud_radius
		var reach: float = cloud_radius * 0.82 - radius
		var angle: float = _rng.randf_range(0.0, TAU)
		var span: float = _rng.randf_range(0.30, 1.0) * reach
		var height: float = radius * _rng.randf_range(0.9, 1.3)
		var lift: float = maxf(_rng.randf_range(-6.0, -1.0),
			BELLY_FLOOR + height * 0.5)
		_add_cloud_lump(lump_index, radius, height,
			Vector3(cos(angle) * span, lift, sin(angle) * span), CLOUD_DARK)
		lump_index += 1
	# Tour : six grumeaux plus hauts, plus clairs, serrés vers l'axe.
	for i: int in range(6):
		var radius: float = _rng.randf_range(0.14, 0.22) * cloud_radius
		var reach: float = (cloud_radius - radius) * 0.5
		var angle: float = _rng.randf_range(0.0, TAU)
		var span: float = _rng.randf_range(0.2, 1.0) * reach
		var height: float = radius * _rng.randf_range(1.0, 1.4)
		_add_cloud_lump(lump_index, radius, height,
			Vector3(cos(angle) * span, _rng.randf_range(6.0, 16.0),
				sin(angle) * span), CLOUD_SLATE)
		lump_index += 1
	# Bord chaud côté soleil (§9.2) : quatre grumeaux à l'OUEST (x < 0),
	# albédo penché vers le miel — le soleil vient de l'ouest/haut-gauche.
	var warm: Color = Color(0.545, 0.50, 0.455)
	for i: int in range(4):
		var radius: float = _rng.randf_range(0.10, 0.16) * cloud_radius
		var angle: float = PI + _rng.randf_range(-0.85, 0.85)
		var span: float = (cloud_radius - radius) * _rng.randf_range(0.80, 0.98)
		var height: float = radius * _rng.randf_range(0.9, 1.3)
		_add_cloud_lump(lump_index, radius, height,
			Vector3(minf(cos(angle) * span, -radius * 0.5),
				_rng.randf_range(0.0, 9.0), sin(angle) * span), warm)
		lump_index += 1


func _add_cloud_lump(index: int, radius: float, height: float, at: Vector3,
		color: Color) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "CloudLayer%d" % index
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = radius
	# Hauteur PROPORTIONNELLE au rayon (ratio 0,9-1,4) : un grumeau est une
	# masse, pas une assiette. L'invariant est testé (ratio moyen ≥ 0,8).
	sphere.height = height
	sphere.radial_segments = 24
	sphere.rings = 8
	mesh.mesh = sphere
	mesh.material_override = _cloud_material(color)
	mesh.position = at
	add_child(mesh)


func _cloud_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	# Correction V5 — le nuage était ÉCLAIRÉ DE NULLE PART.
	#
	# `UNSHADED` + `disable_fog` signifie : la couleur affichée est exactement
	# l'albédo, sur toutes les faces, quelle que soit la distance. Deux teintes
	# seulement, donc deux aplats — une tache noire découpée dans un ciel clair,
	# à 380 m, sans ventre sombre, sans bord chaud, sans profondeur. Aucun
	# réglage de shader ne pouvait produire le « bord plus clair et chaud côté
	# soleil » que demande la bible §9.2 tant que la lumière était coupée.
	#
	# En rendant les couches au soleil, les 14 sphères se dégradent d'elles-
	# mêmes : le dessous reste sombre, le dessus prend le miel du couchant, et
	# la brume atmosphérique recolle enfin le nuage au reste du lointain.
	material.disable_fog = false
	return material


## Rideau de pluie DERRIÈRE la citadelle (réf. 01 : la colonne d'éclair claque
## contre un fond ardoise, pas contre une muraille gris clair — 3e capture).
## Un voile translucide du ventre du nuage au sol, côté nord : il assombrit la
## zone citadelle SEULEMENT, vu depuis la crête.
func _build_rain_veil() -> void:
	var veil: MeshInstance3D = MeshInstance3D.new()
	veil.name = "RainVeil"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(88.0, 96.0, 2.0)
	veil.mesh = box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(CLOUD_DARK.r, CLOUD_DARK.g, CLOUD_DARK.b, 0.42)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_fog = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	veil.material_override = material
	# Ventre du nuage (~y −4) jusque sous le plateau (34) : centre −52, 15 m
	# derrière l'axe de la citadelle.
	veil.position = Vector3(0, -52.0, -15.0)
	add_child(veil)


## Tracé irrégulier en segments (§7.6 : cœur blanc fin + halo cyan, 2 branches
## courtes), du ventre du nuage vers la flèche. Construit UNE fois, seed fixe ;
## seule la visibilité change.
func _build_bolt() -> void:
	_bolt_root = Node3D.new()
	_bolt_root.name = "Bolt"
	_bolt_root.visible = false
	add_child(_bolt_root)
	var from: Vector3 = BOLT_ORIGIN
	_build_bolt_branch(from, strike_offset, 6, 3.4, true)
	# Trois branches courtes qui meurent en l'air (§7.6 : 2-4 branches).
	var mid: Vector3 = from.lerp(strike_offset, 0.45)
	_build_bolt_branch(mid, mid + Vector3(7, -10, 3), 3, 1.8, false)
	var mid2: Vector3 = from.lerp(strike_offset, 0.65)
	_build_bolt_branch(mid2, mid2 + Vector3(-6, -8, -2), 3, 1.5, false)
	var mid3: Vector3 = from.lerp(strike_offset, 0.8)
	_build_bolt_branch(mid3, mid3 + Vector3(4, -7, -4), 3, 1.4, false)


func _build_bolt_branch(from: Vector3, to: Vector3, segments: int,
		jitter: float, main: bool) -> void:
	var previous: Vector3 = from
	for i: int in range(1, segments + 1):
		var t: float = float(i) / float(segments)
		var point: Vector3 = from.lerp(to, t)
		if i < segments:
			point += Vector3(_rng.randf_range(-jitter, jitter), 0.0,
				_rng.randf_range(-jitter, jitter))
		# Épais : le tracé doit se lire à 350 m depuis la crête (~5 px/m à
		# cette distance dans le cadre §3.2 — 1,6 m ≈ 8 px de halo).
		# Épaissi en H-2 : à 360 m, la colonne de H-1 (halo 1,6 m) restait un
		# fil — 2,2 m de halo ≈ 11 px dans le cadre §3.2, le trait se lit.
		_add_bolt_segment(previous, point, 2.2 if main else 0.9, BOLT_HALO, 2.6)
		_add_bolt_segment(previous, point, 0.85 if main else 0.34, BOLT_CORE, 5.0)
		previous = point


func _add_bolt_segment(from: Vector3, to: Vector3, thickness: float,
		color: Color, energy: float) -> void:
	var segment: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(thickness, from.distance_to(to), thickness)
	segment.mesh = box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_fog = true   # le cyan reste saturé à travers la brume
	# Revue contradictoire (passe art) : un halo OPAQUE cachait le cœur
	# blanc logé dedans — l'éclair se lisait comme un aplat cyan, contre
	# §9.3 (« cœur blanc fin + halo moins opaque ») et §1.6 (ruban opaque
	# interdit). Le halo devient translucide et additif ; le cœur, plus
	# fin, reste opaque et transparaît.
	if color == BOLT_HALO:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.42
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	segment.material_override = material
	segment.position = (from + to) * 0.5
	# Oriente l'axe Y du segment le long du tronçon.
	var direction: Vector3 = (to - from).normalized()
	if not direction.is_equal_approx(Vector3.UP) \
			and not direction.is_equal_approx(Vector3.DOWN):
		var axis: Vector3 = Vector3.UP.cross(direction).normalized()
		segment.basis = Basis(axis, Vector3.UP.angle_to(direction))
	_bolt_root.add_child(segment)


func _on_flash_timer() -> void:
	if _flashing:
		_bolt_root.visible = false
		_flash_light.light_energy = 0.0
		_flashing = false
		# Cadence irrégulière (§7.6), déterministe par le seed.
		_flash_timer.wait_time = _rng.randf_range(4.0, 9.0)
	else:
		_bolt_root.visible = true
		_flash_light.light_energy = 7.0
		_flashing = true
		_flash_timer.wait_time = flash_duration
	_flash_timer.start()


func is_flashing() -> bool:
	return _flashing


func flash_light_energy() -> float:
	return _flash_light.light_energy if _flash_light != null else 0.0


## Frappe majeure TENUE, pour la capture de référence (§3.2 : « un éclair
## majeur simultané dans la vue d'ouverture » ; §21.8 : déterminisme). Sous
## llvmpipe, une frame de rendu 1440p dure ~250 ms réels : la cadence
## temps-réel du Timer est passée bien avant la 60e frame — la capture tenait
## donc TOUJOURS l'écran entre deux frappes. À appeler UNIQUEMENT par le mode
## vista ; le jeu garde la cadence irrégulière.
func hold_flash() -> void:
	_flash_timer.stop()
	_bolt_root.visible = true
	_flash_light.light_energy = 7.0
	_flashing = true
