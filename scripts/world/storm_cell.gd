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

const CLOUD_SLATE: Color = Color(0.24, 0.26, 0.31)
const CLOUD_DARK: Color = Color(0.16, 0.17, 0.21)
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


## Masse cumuliforme : sept grumeaux aplatis, irréguliers, qui se chevauchent —
## ventre sombre, sommets ardoise (1re capture V4.1 : trois galettes propres
## lisaient « pièce montée », pas « orage »). `disable_fog` garde le nuage
## SOMBRE à 360 m : c'est son contraste avec le ciel doré qui porte la menace,
## la brume le fondait dans l'horizon.
func _build_clouds() -> void:
	cloud_radius = minf(cloud_radius, MAX_CLOUD_RADIUS)
	# Grumeaux DODUS en deux étages, sur une jupe basse sombre. La capture
	# `vista_horizon_etage` a tranché : des lobes de 8-13 m de haut pour ~26 m
	# de rayon lisaient « soucoupe » à 360 m — la hauteur d'un grumeau doit
	# suivre son rayon, et la masse doit s'EMPILER, pas s'étaler.
	#
	# Jupe : le ventre plat et sombre d'un cumulonimbus, d'où sort l'éclair.
	var skirt: MeshInstance3D = MeshInstance3D.new()
	skirt.name = "CloudBase"
	var skirt_sphere: SphereMesh = SphereMesh.new()
	skirt_sphere.radius = cloud_radius * 0.62
	skirt_sphere.height = 9.0
	skirt_sphere.radial_segments = 24
	skirt_sphere.rings = 8
	skirt.mesh = skirt_sphere
	skirt.material_override = _cloud_material(CLOUD_DARK)
	skirt.position = Vector3(0, -2.0, 0)
	add_child(skirt)
	for i: int in range(14):
		# Étage bas (i < 8) : gros grumeaux du ventre. Étage haut : plus
		# petits, plus clairs, plus serrés vers l'axe — la tour du nuage.
		var lower: bool = i < 8
		var radius: float = (_rng.randf_range(0.30, 0.46) if lower
			else _rng.randf_range(0.18, 0.32)) * cloud_radius
		var reach: float = (cloud_radius - radius) * (1.0 if lower else 0.55)
		var angle: float = _rng.randf_range(0.0, TAU)
		var span: float = _rng.randf_range(0.25, 1.0) * reach
		var height: float = _rng.randf_range(1.0, 7.0) if lower \
			else _rng.randf_range(8.0, 19.0)
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = "CloudLayer%d" % i
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = radius
		# Hauteur PROPORTIONNELLE au rayon (ratio 0,9-1,5) : un grumeau est
		# une masse, pas une assiette. L'invariant est testé (ratio moyen ≥ 0,8).
		sphere.height = radius * _rng.randf_range(0.9, 1.5)
		sphere.radial_segments = 24
		sphere.rings = 8
		mesh.mesh = sphere
		# Ventre sombre, sommets ardoise — la menace vient du dessous.
		mesh.material_override = _cloud_material(
			CLOUD_DARK if height < 5.0 else CLOUD_SLATE)
		mesh.position = Vector3(cos(angle) * span, height, sin(angle) * span)
		add_child(mesh)


func _cloud_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_fog = true
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
