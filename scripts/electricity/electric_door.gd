## Porte alimentée (MASTER_SPEC §15.1 `DoorNode`, §15.4, §15.5).
##
## La porte est un NŒUD DU GRAPHE (`kind = DOOR`) posé au contact de son
## récepteur : elle ne devine rien, elle attend `power_changed`. §15.5
## impose une ouverture DIFFÉRÉE de 0,6 à 1,2 s après l'alimentation —
## le délai est ce qui rend la cause lisible : la lumière parcourt le
## circuit, l'anneau se ferme, PUIS le mécanisme part.
##
## La porte est LATCHÉE (§15.11, anti-softlock) : une fois ouverte, elle
## le reste. Un panneau qui se refermerait dès qu'on bouge le bloc
## pourrait enfermer le joueur du mauvais côté — exactement le risque que
## §15.8 interdit pour la batterie.
##
## Le panneau est un `AnimatableBody3D` (§14.1 : « pour portes/plateformes
## pilotées »), déplacé au tick physique, jamais depuis `_process`.
##
## Audio : le « son » de §15.4 appartient au contenu de Phase H — ce
## conteneur n'a aucun périphérique audio (KNOWN_ISSUES ISS-004). Le
## mouvement mécanique et la lumière, eux, sont là.
class_name ElectricDoor
extends Node3D

## La porte a fini de s'ouvrir.
signal opened()

const COL_METAL: Color = Color(0.22, 0.21, 0.25)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)
## §15.5 : « porte s'ouvre avec délai 0,6-1,2 s ». Bornes DURES : une
## valeur hors plage est ramenée dedans plutôt que silencieusement subie.
const DELAY_MIN: float = 0.6
const DELAY_MAX: float = 1.2

@export var door_id: StringName = &""
## Récepteur qui commande la porte. Vide : la porte obéit à sa propre
## alimentation dans le graphe.
@export var receiver_path: NodePath
@export var open_delay: float = 0.9
## Durée du mouvement mécanique, une fois le délai écoulé.
@export var open_time: float = 1.4
@export var panel_size: Vector3 = Vector3(4.0, 5.0, 0.5)
## Course verticale du panneau : il monte dans le linteau.
@export var travel: float = 5.2
## Ports du nœud de porte, en LOCAL (§15.3) : la porte est branchée sur
## le circuit comme n'importe quel autre nœud, pas commandée en douce.
@export var node_port_offsets: Array[Vector3] = []
@export var node_port_reach: float = 0.55

var _node: ElectricNode = null
var _receiver: ElectricNode = null
var _panel: AnimatableBody3D = null
var _seam: MeshInstance3D = null
var _closed_y: float = 0.0
var _countdown: float = -1.0
var _open_ratio: float = 0.0
var _latched: bool = false


func _ready() -> void:
	open_delay = clampf(open_delay, DELAY_MIN, DELAY_MAX)
	_build()
	_receiver = get_node_or_null(receiver_path) as ElectricNode
	if _receiver == null:
		_receiver = _node
	_receiver.power_changed.connect(_on_power_changed)


func _build() -> void:
	_node = ElectricNode.new()
	_node.name = "DoorNode"
	_node.node_id = door_id
	_node.kind = ElectricNode.Kind.DOOR
	_node.conductivity = 1.0
	_node.port_offsets = node_port_offsets
	_node.port_reach = node_port_reach
	add_child(_node)

	_panel = AnimatableBody3D.new()
	_panel.name = "Panel"
	_panel.collision_layer = 1  # World Static : la porte fermée EST un mur
	_panel.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = panel_size
	shape.shape = box
	_panel.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var mesh_box: BoxMesh = BoxMesh.new()
	mesh_box.size = panel_size
	mesh.mesh = mesh_box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = COL_METAL
	material.roughness = 0.7
	mesh.material_override = material
	_panel.add_child(mesh)
	_panel.position = Vector3(0, panel_size.y * 0.5, 0)
	add_child(_panel)
	_closed_y = _panel.position.y

	# La couture cyan : §15.4, « chaque activation associe mouvement
	# mécanique, son et lumière ». Elle s'allume avec le récepteur.
	_seam = MeshInstance3D.new()
	_seam.name = "Seam"
	var seam_box: BoxMesh = BoxMesh.new()
	seam_box.size = Vector3(0.16, panel_size.y * 0.9, 0.1)
	_seam.mesh = seam_box
	var seam_material: StandardMaterial3D = StandardMaterial3D.new()
	seam_material.albedo_color = COL_METAL
	_seam.material_override = seam_material
	_seam.position = Vector3(0, panel_size.y * 0.5, panel_size.z * 0.5 + 0.06)
	add_child(_seam)


func _on_power_changed(powered: bool, _power: float) -> void:
	if not powered or _latched:
		return
	_latched = true
	_countdown = open_delay
	var seam_material: StandardMaterial3D = _seam.material_override \
		as StandardMaterial3D
	seam_material.albedo_color = COL_CYAN
	seam_material.emission_enabled = true
	seam_material.emission = COL_CYAN
	seam_material.emission_energy_multiplier = 2.6


func _physics_process(delta: float) -> void:
	if _countdown > 0.0:
		_countdown -= delta
		return
	if not _latched or _open_ratio >= 1.0:
		return
	_open_ratio = minf(1.0, _open_ratio + delta / maxf(0.05, open_time))
	_panel.position.y = _closed_y + travel * _open_ratio
	if _open_ratio >= 1.0:
		opened.emit()


## Ouvre la porte SANS animation ni délai — restauration d'une salle déjà
## résolue au chargement (§19.4 : appliquer l'état, pas le rejouer).
func force_open() -> void:
	_latched = true
	_countdown = -1.0
	_open_ratio = 1.0
	if _panel != null:
		_panel.position.y = _closed_y + travel
	if _seam != null:
		var seam_material: StandardMaterial3D = _seam.material_override \
			as StandardMaterial3D
		seam_material.albedo_color = COL_CYAN
		seam_material.emission_enabled = true
		seam_material.emission = COL_CYAN
		seam_material.emission_energy_multiplier = 2.6


func is_open() -> bool:
	return _open_ratio >= 1.0


## Avancement du mécanisme, 0 fermé → 1 ouvert (seam de test).
func open_ratio() -> float:
	return _open_ratio


## La porte a-t-elle reçu l'ordre d'ouverture (latch) ?
func is_latched() -> bool:
	return _latched


func node() -> ElectricNode:
	return _node
