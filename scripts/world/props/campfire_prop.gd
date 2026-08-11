## FOYER DE CAMP — asset livré, plus un repli graybox.
##
## POURQUOI IL EXISTE. Même défaut P0 que l'auvent : `prop.campfire` était
## réservé dans `AssetRegistry` et pointait vers une scène absente. La terrasse
## posait à la place deux cylindres — un anneau de pierre et un disque de
## braise — ce qui donne, depuis la caméra du camp, un rond gris et un rond
## orange. §10.3 demande « pierres, bois, braises, flamme/fumée/lumière » et
## des états `unlit` / `embers` / `lit`.
##
## CE QUE C'EST. Sept pierres de tailles et d'orientations différentes posées
## en anneau IRRÉGULIER (une manque, comme un foyer qu'on a ouvert pour glisser
## une marmite), trois bûches croisées, un lit de braise émissif et une flamme
## en trois langues de hauteurs inégales.
##
## CE QU'IL NE FAIT PAS. Il ne porte NI la lumière, NI la collision, NI l'état
## de jeu : `CampFireLight` et `FireCoals` restent créés par la terrasse, qui
## les nomme et les teste depuis V4.3. Un décor ne décide jamais d'un état
## (`scripts/CLAUDE.md`) — celui-ci ne fait que rendre le foyer crédible.
##
## AUCUN ASSET EXTERNE : géométrie construite ici, palette §3.4.
class_name CampfireProp
extends Node3D

const RING_RADIUS: float = 1.05
const COL_STONE_WARM: Color = Color(0.315, 0.282, 0.246)
const COL_STONE_COLD: Color = Color(0.232, 0.216, 0.205)
const COL_LOG: Color = Color(0.268, 0.176, 0.118)
const COL_LOG_CHARRED: Color = Color(0.115, 0.098, 0.092)
const COL_FLAME_CORE: Color = Color(1.0, 0.86, 0.46)
const COL_FLAME_EDGE: Color = Color(0.98, 0.44, 0.16)


func _ready() -> void:
	_build_stones()
	_build_logs()
	_build_flames()


func _build_stones() -> void:
	# Sept pierres, huit places : le vide est intentionnel. Un anneau complet
	# et régulier lit « décor posé » ; un anneau ouvert lit « on s'en sert ».
	for i: int in range(8):
		if i == 5:
			continue
		var angle: float = TAU * float(i) / 8.0 + 0.19
		var stone: MeshInstance3D = MeshInstance3D.new()
		stone.name = "HearthStone%d" % i
		var box: BoxMesh = BoxMesh.new()
		var scale_factor: float = 0.78 + 0.34 * absf(sin(float(i) * 2.7))
		box.size = Vector3(0.42, 0.30, 0.34) * scale_factor
		stone.mesh = box
		stone.material_override = _flat(COL_STONE_WARM if i % 3 != 1
			else COL_STONE_COLD)
		var radius: float = RING_RADIUS + 0.08 * sin(float(i) * 3.1)
		stone.position = Vector3(cos(angle) * radius,
			0.13 * scale_factor, sin(angle) * radius)
		# Trois rotations différentes par pierre : rien d'aligné sur le monde.
		stone.rotation = Vector3(0.10 * sin(float(i) * 1.9),
			angle + 0.35 * sin(float(i) * 2.3), 0.13 * cos(float(i) * 1.3))
		add_child(stone)


func _build_logs() -> void:
	# Trois bûches croisées, dont deux dont l'extrémité est carbonisée. Les
	# angles sont premiers entre eux : pas de trépied symétrique.
	var logs: Array[Array] = [
		["LogA", 0.35, 0.62, 1.30, COL_LOG],
		["LogB", 2.30, 0.48, 1.15, COL_LOG_CHARRED],
		["LogC", 4.05, 0.55, 1.22, COL_LOG],
	]
	for entry: Array in logs:
		var yaw: float = entry[1]
		var log_mesh: MeshInstance3D = MeshInstance3D.new()
		log_mesh.name = String(entry[0])
		var cylinder: CylinderMesh = CylinderMesh.new()
		cylinder.top_radius = 0.075
		cylinder.bottom_radius = 0.095
		cylinder.height = float(entry[3])
		cylinder.radial_segments = 6
		log_mesh.mesh = cylinder
		log_mesh.material_override = _flat(entry[4] as Color)
		log_mesh.position = Vector3(0.10 * cos(yaw), float(entry[2]) * 0.42,
			0.10 * sin(yaw))
		# Couchée puis inclinée : une bûche posée à plat sur un feu, ce n'est
		# pas un cylindre debout.
		log_mesh.rotation = Vector3(deg_to_rad(72.0), yaw, 0.0)
		add_child(log_mesh)


func _build_flames() -> void:
	# Trois langues de hauteurs et de largeurs inégales. Cônes émissifs sans
	# transparence : le rendu Compatibility du profil Web n'a ni particules
	# GPU ni dépendance à l'écran, et une flamme doit rester lisible partout.
	var flames: Array[Array] = [
		["FlameTall", Vector3(0.0, 0.0, 0.0), 0.30, 1.05, COL_FLAME_CORE, 2.6],
		["FlameWest", Vector3(-0.22, 0.0, 0.11), 0.24, 0.70, COL_FLAME_EDGE, 2.0],
		["FlameEast", Vector3(0.19, 0.0, -0.14), 0.20, 0.54, COL_FLAME_EDGE, 1.7],
	]
	for entry: Array in flames:
		var height: float = float(entry[3])
		var flame: MeshInstance3D = MeshInstance3D.new()
		flame.name = String(entry[0])
		var cone: CylinderMesh = CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = float(entry[2])
		cone.height = height
		cone.radial_segments = 7
		flame.mesh = cone
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = entry[4] as Color
		material.emission_enabled = true
		material.emission = entry[4] as Color
		material.emission_energy_multiplier = float(entry[5])
		material.roughness = 1.0
		flame.material_override = material
		# Une flamme n'a pas d'ombre portée : elle est la source.
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flame.position = (entry[1] as Vector3) + Vector3(0.0, 0.24 + height * 0.5, 0.0)
		flame.rotation.z = 0.09 * sin(height * 7.0)
		add_child(flame)


func _flat(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.94
	return material
