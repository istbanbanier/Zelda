## Bassin conducteur (P2-4, bible §3.4) — l'enseignement eau×électricité de
## la route de la rivière, AVANT la salle 4 du donjon. Diorama autonome :
## un bassin peu profond, une source active trop loin de l'eau pour que les
## ports se touchent, un récepteur collé à l'autre rive de l'eau.
##
## UN Arc Link (source→eau) complète le circuit : source → lien → EAU →
## récepteur — le courant TRAVERSE l'eau, c'est le point de la leçon, et
## dissoudre le lien rend tout (transport, jamais création). Ici la leçon
## est SÛRE (P2 §9.6 : le danger arrive au donjon, pas à l'école).
class_name ConductiveBasin
extends Node3D

const CYAN: Color = Color(0.133, 0.851, 0.925)
const AMBER: Color = Color(1.0, 0.75, 0.3)
const WATER_TINT: Color = Color(0.31, 0.686, 0.698)

var _source: ElectricNode = null
var _water: ElectricNode = null
var _receiver: ElectricNode = null


func _ready() -> void:
	var graph: ElectricGraph = ElectricGraph.new()
	add_child(graph)
	_build_basin()
	# La SOURCE : à 6 m du port ouest de l'eau — hors de portée des ports
	# (0,6 m), à portée d'un Arc Link (≤ 14 m). Le maillon manquant.
	_source = _electric(ElectricNode.Kind.SOURCE, &"valley.basin.source.01",
		Vector3(-9.0, 0.6, 0.0))
	_source.name = "SourceNode"
	_port_marker(_source)
	_lamp(_source, AMBER, 1.8)
	# L'EAU : un nœud zone, ports aux deux rives.
	_water = _electric(ElectricNode.Kind.WATER_ZONE, &"valley.basin.water.01",
		Vector3(0.0, 0.15, 0.0))
	_water.name = "WaterNode"
	_water.port_offsets = [Vector3(-2.5, 0.0, 0.0), Vector3(2.5, 0.0, 0.0)]
	_port_marker(_water)
	# Le RÉCEPTEUR : collé au port est de l'eau (0,5 m ≤ portée 0,6) — déjà
	# connecté, il attend le courant.
	_receiver = _electric(ElectricNode.Kind.RECEIVER, &"valley.basin.receiver.01",
		Vector3(3.0, 0.15, 0.0))
	_receiver.name = "ReceiverNode"
	_lamp(_receiver, CYAN, 0.0)
	# ISS-030 : l'eau de la VALLÉE parle les MÊMES lois que celle du
	# donjon — matière `eau`, mouillage, relais borné — via le composant
	# partagé. L'école reste SÛRE (P2 §9.6) : aucun dégât ici, les lois
	# de matière seulement.
	var bathing: Area3D = Area3D.new()
	bathing.name = "BathingZone"
	bathing.collision_layer = 0
	bathing.collision_mask = 2 | 128
	bathing.monitoring = true
	var bathing_shape: CollisionShape3D = CollisionShape3D.new()
	var bathing_box: BoxShape3D = BoxShape3D.new()
	bathing_box.size = Vector3(5.6, 1.4, 4.6)
	bathing_shape.shape = bathing_box
	bathing.add_child(bathing_shape)
	add_child(bathing)
	bathing.position = Vector3(0.0, 0.4, 0.0)
	var water_matter: WaterMatterComponent = WaterMatterComponent.new()
	water_matter.name = "WaterMatter"
	water_matter.node_path = NodePath("../WaterNode")
	water_matter.area_path = NodePath("../BathingZone")
	add_child(water_matter)


func source() -> ElectricNode:
	return _source


func water() -> ElectricNode:
	return _water


func receiver() -> ElectricNode:
	return _receiver


## Où se poster pour lier : entre la source et l'eau, en retrait.
func stand_point() -> Vector3:
	return to_global(Vector3(-4.5, 0.1, 4.0))


func _build_basin() -> void:
	# Cuvette peu profonde : fond dur (couche 1) et margelle basse.
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(6.0, 0.3, 5.0)
	shape.shape = box
	floor_body.add_child(shape)
	add_child(floor_body)
	floor_body.position = Vector3(0.0, -0.15, 0.0)
	# La nappe d'eau : un plan visuel teinté — la LOGIQUE est le nœud.
	var sheet: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(5.6, 4.6)
	sheet.mesh = plane
	var water_material: StandardMaterial3D = StandardMaterial3D.new()
	water_material.albedo_color = WATER_TINT
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.albedo_color.a = 0.7
	sheet.material_override = water_material
	add_child(sheet)
	sheet.position = Vector3(0.0, 0.12, 0.0)


func _electric(kind: ElectricNode.Kind, id: StringName, at: Vector3) -> ElectricNode:
	var node: ElectricNode = ElectricNode.new()
	node.kind = kind
	node.node_id = id
	add_child(node)
	node.position = at
	return node


func _port_marker(node: ElectricNode) -> void:
	var marker: ResonanceTargetComponent = ResonanceTargetComponent.new()
	marker.kind = &"port"
	node.add_child(marker)


## Le fanal d'un nœud : un POTEAU DE RÉSONANCE, socle posé au sol.
##
## DÉFAUT MESURÉ (revue « une caisse claire flotte près de la rivière »).
## C'était une `BoxMesh` NUE de 0,55 × 1,10 × 0,55 m, centrée sur le nœud, en
## émission ambre 1,8 sur toute sa surface. Boîtes monde relevées dans la
## vallée montée (`tools/godot/probe_world_boxes.gd`) :
##   - source   : x 6,72..7,28 · y 2,05..3,15 · z 27,73..28,27 ;
##   - récepteur : y 1,60..2,70, soit 0,40 m ENTERRÉ sous une plaine à 2,00.
## Depuis la rive, la source se lisait exactement comme le dit le propriétaire :
## une caisse claire posée en l'air. Trois causes, toutes vérifiables — aucun
## socle, donc aucun contact au sol ; une valeur unique sur les six faces, donc
## aucun volume ; et une hauteur calée sur le NŒUD (perché à 0,60 m pour la
## source, enfoncé pour le récepteur) au lieu du SOL.
##
## Correction : socle large, fût, noyau (langage électrique — « socle large +
## noyau profond »), l'émission réservée au seul noyau, et l'empilement calé
## sur le sol du site (y local 0) quelle que soit la cote du nœud. La position
## du NŒUD n'est pas touchée : elle porte les portées de port (0,60 m) et le
## lien (14 m) — la déplacer casserait la leçon.
const LAMP_BASE_H: float = 0.22
const LAMP_SHAFT_H: float = 0.78
const LAMP_CORE_H: float = 0.44
const COL_LAMP_STONE: Color = Color(0.34, 0.32, 0.29)


func _lamp(node: ElectricNode, tint: Color, idle_energy: float) -> void:
	# Le sol du site est à y = 0 en local ; le nœud, lui, peut être perché.
	var ground: float = -node.position.y
	var stone: StandardMaterial3D = StandardMaterial3D.new()
	stone.albedo_color = COL_LAMP_STONE
	stone.roughness = 0.92
	_lamp_block(node, "Socle", ground + LAMP_BASE_H * 0.5,
		Vector3(0.86, LAMP_BASE_H, 0.86), stone)
	_lamp_block(node, "Fut", ground + LAMP_BASE_H + LAMP_SHAFT_H * 0.5,
		Vector3(0.46, LAMP_SHAFT_H, 0.46), stone)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.20, 0.22)
	material.roughness = 0.45
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = idle_energy
	# Le noyau chevauche le haut du fût et le dépasse : c'est lui, et lui seul,
	# qui brille — une lueur de 0,28 m au lieu d'un pavé de 0,55.
	_lamp_block(node, "Noyau",
		ground + LAMP_BASE_H + LAMP_SHAFT_H + LAMP_CORE_H * 0.5 - 0.08,
		Vector3(0.28, LAMP_CORE_H, 0.28), material)
	node.power_changed.connect(func(powered: bool, _power: float) -> void:
		material.emission_energy_multiplier = 1.8 if powered else idle_energy)


func _lamp_block(node: ElectricNode, block_name: String, centre_y: float,
		size: Vector3, material: StandardMaterial3D) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = block_name
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	node.add_child(mesh)
	mesh.position = Vector3(0.0, centre_y, 0.0)
