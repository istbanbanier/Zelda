## Coque commune des salles du donjon (MASTER_SPEC §15, §19).
##
## Ce qui est ici est ce que §15.11 exige de CHAQUE salle, sans exception :
## reset, respawn des objets essentiels, état sauvegardé, chemin retour.
## Le reste — la mécanique propre à la salle — appartient à la salle.
##
## Le décor est construit en code, comme `ValleyTerrain` et
## `CitadelVestibule` : déclaratif, déterministe, cotes lisibles en diff.
##
## Persistance : la salle FUSIONNE sa part dans le slot commun plutôt que
## d'écrire un fichier à elle (§19.1 : « portes/interrupteurs/circuits »
## font partie de la même sauvegarde que l'inventaire). Elle relit le
## fichier, remplace sa propre clé, et réécrit — jamais d'écrasement des
## clés des autres.
class_name DungeonRoom
extends Node3D

const SAVE_SLOT: String = "slot0"
const COL_STONE: Color = Color(0.30, 0.28, 0.33)
const COL_FLOOR: Color = Color(0.24, 0.23, 0.27)
const COL_BRONZE: Color = Color(0.42, 0.30, 0.18)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)
const COL_IVORY: Color = Color(0.90, 0.87, 0.78)
const COL_COPPER: Color = Color(0.55, 0.36, 0.22)

## §19.3 : `zone.category.name.index` — racine des IDs de la salle.
@export var room_id: StringName = &""

var _blocks: Array[PushableBlock] = []
var _graph: ElectricGraph = null
var _hints_tracker: PuzzleHintTracker = null


## Enregistre un objet d'énigme essentiel (§14.3) : le reset et la
## sauvegarde le connaissent désormais.
## Point d'insertion UNIQUE de l'habillage (bible §12.2). Chaque salle définit
## son propre `_ready()`, qui masque celui de la classe de base ; `_notification`
## n'est pas masqué, lui, et l'appel différé garantit que la coque de la salle
## est entièrement bâtie avant qu'on pose la moindre brique dessus.
func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		_dress_shell.call_deferred()


func _dress_shell() -> void:
	if not is_inside_tree():
		return
	var report: Dictionary = RoomDressing.dress(self)
	dressing_report = report


## Compte-rendu chiffré de l'habillage : les tests s'appuient dessus.
var dressing_report: Dictionary = {}


func register_block(block: PushableBlock) -> void:
	if not _blocks.has(block):
		_blocks.append(block)


func blocks() -> Array[PushableBlock]:
	return _blocks


func graph() -> ElectricGraph:
	return _graph


func set_graph(value: ElectricGraph) -> void:
	_graph = value


## §15.11 : « chaque salle : reset ». Remet les objets déplaçables à leur
## transform de secours et recalcule le circuit. Ce que le reset ne défait
## JAMAIS : une porte déjà ouverte (anti-softlock, §15.11).
func reset_room() -> void:
	for block: PushableBlock in _blocks:
		block.reset_to_rescue()
	if _graph != null:
		_graph.mark_dirty()


## État sauvegardable de la salle (§19.1). Redéfini par chaque salle pour
## y ajouter ses propres faits ; l'implémentation de base couvre ce que
## toutes les salles ont : circuits et objets essentiels.
func room_state() -> Dictionary:
	var state: Dictionary = {}
	if _graph != null:
		state["nodes"] = _graph.save_state()
	var block_states: Array[Dictionary] = []
	for block: PushableBlock in _blocks:
		# §19.1 : transform d'un objet essentiel SEULEMENT s'il est sûr.
		var safe: Transform3D = block.safe_transform()
		block_states.append({
			"id": String(block.persistent_id),
			"position": [safe.origin.x, safe.origin.y, safe.origin.z],
		})
	state["blocks"] = block_states
	return state


func apply_room_state(state: Dictionary) -> void:
	if _graph != null and state.has("nodes"):
		_graph.apply_state(state["nodes"] as Array)
	if not state.has("blocks"):
		return
	for entry: Variant in (state["blocks"] as Array):
		var block_state: Dictionary = entry as Dictionary
		var id: StringName = StringName(String(block_state.get("id", "")))
		var block: PushableBlock = _find_block(id)
		if block == null:
			push_warning("[donjon] bloc inconnu ignoré : %s" % String(id))
			continue
		var coords: Array = block_state.get("position", []) as Array
		if coords.size() != 3:
			continue
		var target: Transform3D = block.rescue_transform()
		target.origin = Vector3(float(coords[0]), float(coords[1]),
			float(coords[2]))
		block.place_at(target)


func _find_block(id: StringName) -> PushableBlock:
	for block: PushableBlock in _blocks:
		if block.persistent_id == id:
			return block
	return null


## Fusionne l'état de la salle dans le slot commun, sans toucher aux
## autres clés (§19.2 : écriture atomique côté `SaveSystem`).
func save_room_state() -> bool:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null or room_id == &"":
		return false
	var data: Dictionary = {}
	if bool(save_system.call("has_save", SAVE_SLOT)):
		data = save_system.call("load_slot", SAVE_SLOT) as Dictionary
	if data.is_empty():
		data = {"schema": 2}
	var rooms: Dictionary = data.get("dungeon", {}) as Dictionary
	rooms[String(room_id)] = room_state()
	data["dungeon"] = rooms
	return bool(save_system.call("save_slot", SAVE_SLOT, data))


## Relit la part de cette salle. Vide si le joueur n'y est jamais venu :
## la salle démarre alors dans son état construit, pas dans une erreur.
func load_room_state() -> Dictionary:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null or room_id == &"" \
			or not bool(save_system.call("has_save", SAVE_SLOT)):
		return {}
	var data: Dictionary = save_system.call("load_slot", SAVE_SLOT) as Dictionary
	var rooms: Dictionary = data.get("dungeon", {}) as Dictionary
	return rooms.get(String(room_id), {}) as Dictionary


## P2 §9.8 : installe les hints gradués et BRANCHE les échecs réels que
## la salle possède déjà — bouton reset pressé, objet essentiel hors
## limites, décharge subie par le joueur. À appeler à la FIN du `_ready`
## de la salle, quand boutons, blocs et joueur existent. La résolution
## (`solved`/`rerouted`) FERME les hints : une énigme comprise n'a plus
## besoin d'aide.
func install_hints(law: String, cause: String, relation: String) -> void:
	_hints_tracker = PuzzleHintTracker.new()
	_hints_tracker.name = "PuzzleHints"
	_hints_tracker.set_hints(law, cause, relation)
	add_child(_hints_tracker)
	for node: Node in find_children("*", "ResetButton", true, false):
		(node as ResetButton).pressed.connect(
			func() -> void: _hints_tracker.record_failure(&"reset"))
	for block: PushableBlock in _blocks:
		block.rescued.connect(
			func() -> void: _hints_tracker.record_failure(&"hors_limites"))
	var player: PlayerController = get_node_or_null("Player") \
		as PlayerController
	if player != null and player.health() != null:
		player.health().damaged.connect(_on_hint_player_damaged)
	if has_signal("solved"):
		connect("solved", _hints_tracker.close)
	if has_signal("rerouted"):
		connect("rerouted", _hints_tracker.close)


## Seules les décharges d'un DANGER comptent : un échec observé, pas un
## combat perdu.
func _on_hint_player_damaged(event: DamageEvent) -> void:
	if event != null and event.team == &"hazard" and _hints_tracker != null:
		_hints_tracker.record_failure(&"choc")


func hints() -> PuzzleHintTracker:
	return _hints_tracker


## Consomme le tag d'apparition posé par la porte qu'on vient de franchir
## (§6.1 : « ressortir replace le joueur DEVANT la porte, jamais au
## spawn »). Vide quand la salle est lancée directement.
func consume_spawn_tag() -> StringName:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return &""
	return StringName(String(game_state.call("consume_pending_spawn")))


## Place le joueur au seuil correspondant au tag. Un tag inconnu laisse la
## position de la scène : jamais de téléportation au hasard.
func place_player_at_spawn(player: Node3D, tag: StringName,
		spawns: Dictionary) -> void:
	if player == null or tag == &"" or not spawns.has(tag):
		return
	player.global_position = spawns[tag] as Vector3

## Porte de transition entre scènes (§6.1). Toutes les salles en posent :
## le helper vit donc ici, pas recopié six fois.
func scene_door(door_name: String, verb: String, target: String,
		tag: StringName, at: Vector3, size: Vector3) -> SceneDoor:
	var door: SceneDoor = SceneDoor.new()
	door.name = door_name
	door.verb = verb
	door.target_scene = target
	door.spawn_tag = tag
	door.collision_layer = 1
	door.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	door.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var mesh_box: BoxMesh = BoxMesh.new()
	mesh_box.size = size
	mesh.mesh = mesh_box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.14, 0.16, 0.2)
	mesh.material_override = material
	door.add_child(mesh)
	door.position = at   # AVANT add_child (règle D.0)
	add_child(door)
	return door

## Fabrique un nœud du graphe et le pose. `ports` en coordonnées LOCALES
## (§15.3 : la rotation du nœud emmène ses ports avec elle).
func make_node(id: StringName, kind: ElectricNode.Kind, at: Vector3,
		ports: Array[Vector3], reach: float,
		parent: Node = null) -> ElectricNode:
	var node: ElectricNode = ElectricNode.new()
	node.node_id = id
	node.kind = kind
	node.port_offsets = ports
	node.port_reach = reach
	node.position = at
	var host: Node = parent if parent != null else self
	host.add_child(node)
	return node


## Ligne de câbles : `count` barres d'un mètre dont les ports d'extrémité
## coïncident deux à deux (§15.3, contact RÉEL entre ports). `axis` donne
## la direction de la ligne — horizontale ou verticale.
func cable_run(prefix: String, from_pos: Vector3, to_pos: Vector3,
		axis: Vector3, count: int) -> void:
	var step: Vector3 = (to_pos - from_pos) / float(maxi(1, count - 1))
	var size: Vector3 = Vector3(0.22, 0.12, 0.22)
	if absf(axis.x) > 0.5:
		size.x = 1.0
	elif absf(axis.y) > 0.5:
		size.y = 1.0
	else:
		size.z = 1.0
	for i: int in range(count):
		var at: Vector3 = from_pos + step * float(i)
		var cable: ElectricNode = make_node(
			StringName("dungeon.node.%s.%02d" % [prefix.to_snake_case(), i + 1]),
			ElectricNode.Kind.CABLE, at,
			[axis * -0.5, axis * 0.5], 0.55)
		cable.name = "%s%02d" % [prefix, i + 1]
		attach_visual(cable, size, Vector3.ZERO, false)


## Attache une présentation à un nœud : un maillage + `ElectricVisual`.
func attach_visual(node: ElectricNode, size: Vector3, offset: Vector3,
		pulse: bool) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "Mesh"
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.position = offset
	node.add_child(mesh)
	var visual: ElectricVisual = ElectricVisual.new()
	visual.name = "Visual"
	visual.node_path = NodePath("..")
	visual.mesh_path = NodePath("../Mesh")
	visual.pulse = pulse
	node.add_child(visual)


## Boîte statique de graybox : collision + maillage, une seule ligne par
## volume. `emissive` pour les veines et les noyaux.
func box(box_name: String, center: Vector3, size: Vector3, color: Color,
		emissive: bool = false) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = box_name
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var mesh_box: BoxMesh = BoxMesh.new()
	mesh_box.size = size
	mesh.mesh = mesh_box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.0
	mesh.material_override = material
	body.add_child(mesh)
	body.position = center   # AVANT add_child (règle D.0)
	add_child(body)
	return body


## Décor pur, sans collision — rails de guidage bas, socles, habillage.
func decor(decor_name: String, center: Vector3, size: Vector3, color: Color,
		emissive: bool = false) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = decor_name
	var mesh_box: BoxMesh = BoxMesh.new()
	mesh_box.size = size
	mesh.mesh = mesh_box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.2
	mesh.material_override = material
	mesh.position = center
	add_child(mesh)
	return mesh


## Prop d'habillage PUR — AUCUNE collision, aucun rôle de jeu. Instancie un
## modèle de la bibliothèque (`assets/environment/dungeon/`, promotions
## `SM_Dungeon_*` comprises) via `AssetRegistry.model()`. Même contrat que
## `RoomDressing` : si le modèle n'est pas encore importé, la salle reste
## EXACTEMENT ce qu'elle était — l'habillage est un bonus, jamais une
## dépendance. `tint` remplace les matériaux par un aplat (bannières du kit
## château : leurs couleurs vives d'origine sortiraient de la palette §12.1).
func dress_prop(model: StringName, prop_name: String, at: Vector3,
		yaw: float = 0.0, scale_xyz: Vector3 = Vector3.ONE,
		tint: Color = Color.TRANSPARENT) -> Node3D:
	var packed: PackedScene = AssetRegistry.model(model)
	if packed == null:
		return null
	var prop: Node3D = packed.instantiate() as Node3D
	if prop == null:
		return null
	# Nommage EXPLICITE : Godot rebaptise les homonymes `@Node3D@366` et
	# aucun test ne peut plus désigner la géométrie (scripts/CLAUDE.md).
	prop.name = prop_name
	prop.rotation.y = yaw
	prop.scale = scale_xyz
	if tint.a > 0.0:
		var flat: StandardMaterial3D = StandardMaterial3D.new()
		flat.albedo_color = tint
		flat.roughness = 0.9
		for node: Node in prop.find_children("*", "MeshInstance3D", true, false):
			(node as MeshInstance3D).material_override = flat
	prop.position = at   # AVANT add_child (règle D.0)
	add_child(prop)
	return prop


## Caméra de référence §21.5 (outil de capture uniquement, via `--call=`) :
## cadre la salle entière depuis un angle haut — l'AABB fusionnée des
## visuels donne le centre et l'empreinte, quel que soit le layout.
func capture_reference_view() -> void:
	var merged: AABB = AABB()
	var first: bool = true
	for visual: Node in find_children("*", "VisualInstance3D", true, false):
		var instance: VisualInstance3D = visual as VisualInstance3D
		var world_aabb: AABB = instance.global_transform * instance.get_aabb()
		merged = world_aabb if first else merged.merge(world_aabb)
		first = false
	if first:
		return
	var centre: Vector3 = merged.get_center()
	var camera: Camera3D = Camera3D.new()
	camera.name = "ReferenceCamera"
	add_child(camera)
	# À L'INTÉRIEUR de l'AABB (fractions de sa taille) : une salle est une
	# boîte fermée — la première version plaçait la caméra dehors et
	# capturait la coque sombre (gate_salle_electrique n°1, 31 Ko).
	camera.global_position = centre + Vector3(
		-merged.size.x * 0.30, merged.size.y * 0.24, merged.size.z * 0.34)
	camera.look_at(centre + Vector3(0, -merged.size.y * 0.15, 0), Vector3.UP)
	camera.fov = 68.0
	camera.current = true


## Passe de PEINTURE de la salle — ÉCRITE, MESURÉE, PAS ENCORE BRANCHÉE.
##
## Essayée sur les six salles, l'arène et le vestibule le 2026-08-06,
## puis RETIRÉE sur preuve : mesurée en capture, elle assombrissait des
## salles déjà trop sombres (luminance 17 % -> 9 %, ISS-025 « aucun
## couloir noir »), et l'arène perdait le contraste de ses marques de
## sol (45,5 -> 16,3). Le gain de matière était réel (contraste des
## murs 16,9 -> 26,5 en salle 3) mais il ne payait pas la perte de
## lisibilité.
##
## Cause identifiée : la recette est calibrée pour un SOLEIL
## directionnel. Un intérieur éclairé par de petites lampes rasantes
## demande son propre modèle (`PainterlyRecipe.interior_mode` existe et
## relève déjà le plancher d'ombre — il ne suffit pas). Le chantier est
## nommé, pas oublié : c'est l'ÉCLAIRAGE du donjon qu'il faut refaire
## d'abord, la peinture ensuite.
##
## À appeler en différé depuis le `_ready` d'une salle, le jour où
## l'éclairage intérieur aura été repris.
func paint_room() -> void:
	if not is_inside_tree():
		return
	PainterlyRecipe.interior_mode = true
	PainterlyRecipe.paint_world(self,
		["ElectricDebug", "Graph", "ZoneOuter", "ZoneRing", "ZoneCore"])
	PainterlyRecipe.interior_mode = false
