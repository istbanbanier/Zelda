## ISS-073 — LA PORTE DU DONJON, et le point où l'on ressort.
##
## POURQUOI CE FICHIER EXISTE. Le menu ouvre World V2 ; World V2 ne portait
## aucune `SceneDoor`. Le seuil §3.3 n'était qu'un `Node3D` nu avec un pilier
## de diagnostic — on ne peut pas interagir avec un marqueur. Donjon, boss,
## antichambre, coffre final et écran de victoire étaient donc inatteignables
## par le chemin d'un joueur, sous 111 tests verts qui vérifiaient le monde
## pour lui-même sans jamais franchir sa sortie.
##
## CE QU'IL POSE, et rien de plus :
##   - une `SceneDoor` réelle, dans le groupe `interactable`, au seuil ;
##   - une ANCRE DE RETOUR stable, devant elle, pour la ressortie.
##
## L'ancre est un nœud nommé, pas une constante recopiée dans trois fichiers :
## le jour où le seuil bouge, la ressortie suit. C'est la règle d'ancrage de
## PROMPT4 — citer un symbole, jamais un nombre.
class_name WorldV2DungeonDoor
extends RefCounted

const VESTIBULE_SCENE: String = "res://scenes/world/citadel/CitadelVestibule.tscn"
## Tag posé par la porte, consommé par la scène d'arrivée. Il porte le même
## nom qu'en V1 : c'est le vestibule qui le lit, et il ne sait pas de quel
## monde on vient.
## Tag posé par la porte AU MOMENT D'ENTRER — consommé par le vestibule.
## C'est la convention déjà établie par le monde V1 (`valley_terrain.gd`,
## `CitadelDoor.spawn_tag = &"from_valley"`), et elle n'est PAS la même que le
## tag de retour : les confondre ferait consommer l'arrivée par la mauvaise
## scène. Ma première version posait `citadel_door` à l'aller ; le vestibule
## l'avalait, et World V2 ne voyait plus rien revenir.
const ENTRY_TAG: StringName = &"from_valley"
## Tag posé par la porte de SORTIE du vestibule, consommé par `WorldV2Root`
## pour replacer le héros devant la citadelle plutôt qu'au spawn initial.
const RETURN_TAG: StringName = &"citadel_door"
const DOOR_NAME: String = "DungeonSceneDoor"
const RETURN_ANCHOR_NAME: String = "DungeonReturnAnchor"

## Recul de l'ancre de retour, mesuré depuis la porte vers le sud (+Z, côté
## vallée). Assez pour que le héros ne ressorte pas DANS le volume de la
## porte — sans quoi le cône d'interaction la reprendrait aussitôt et il
## repartirait d'où il vient, en boucle.
const RETURN_BACKOFF_M: float = 4.0
## Hauteur de la porte : le héros doit la voir et la viser, pas marcher
## dessus.
const DOOR_HEIGHT_M: float = 3.2
const DOOR_WIDTH_M: float = 2.6
const DOOR_DEPTH_M: float = 0.8

var _heightmap: WorldV2Heightmap = null
var _layout: Dictionary = {}


func _init(heightmap: WorldV2Heightmap, layout: Dictionary) -> void:
	_heightmap = heightmap
	_layout = layout


## Pose la porte et son ancre sous `parent`. Rend `true` si le seuil est
## déclaré par la carte directrice — sinon rien n'est posé et le monde le dit,
## plutôt que d'inventer une position.
func build(parent: Node3D) -> bool:
	var anchors: Dictionary = _layout.get("spec_anchors", {}) as Dictionary
	if not anchors.has("dungeon_gate"):
		push_error("[world_v2] `dungeon_gate` absent des ancres §3.3 — "
			+ "aucune porte de donjon posée")
		return false
	var gate: Array = anchors["dungeon_gate"] as Array
	var gx: float = float(gate[0])
	var gz: float = float(gate[2])

	var door: SceneDoor = SceneDoor.new()
	door.name = DOOR_NAME
	door.verb = "Entrer"
	door.target_scene = VESTIBULE_SCENE
	door.spawn_tag = ENTRY_TAG
	# Couche 1 (World Static) : la porte est un obstacle plein, comme en V1.
	door.collision_layer = 1
	door.collision_mask = 0
	door.position = Vector3(gx, _heightmap.height_at(gx, gz), gz)

	var body: MeshInstance3D = MeshInstance3D.new()
	body.name = "Frame"
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(DOOR_WIDTH_M, DOOR_HEIGHT_M, DOOR_DEPTH_M)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	# Bronze patiné du langage de Résonance — pas un accent cyan : la porte
	# n'est pas alimentée, et le cyan reste rare (VISUAL_ASSET_BIBLE §1.4).
	material.albedo_color = Color(0.44, 0.40, 0.30)
	material.roughness = 0.72
	mesh.material = material
	body.mesh = mesh
	body.position = Vector3(0.0, DOOR_HEIGHT_M * 0.5, 0.0)
	door.add_child(body)

	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Collision"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(DOOR_WIDTH_M, DOOR_HEIGHT_M, DOOR_DEPTH_M)
	shape.shape = box
	shape.position = Vector3(0.0, DOOR_HEIGHT_M * 0.5, 0.0)
	door.add_child(shape)
	parent.add_child(door)

	# L'ancre de retour : DEVANT la porte, côté vallée, posée au sol.
	var az: float = gz + RETURN_BACKOFF_M
	var anchor: Node3D = Node3D.new()
	anchor.name = RETURN_ANCHOR_NAME
	anchor.add_to_group(&"world_v2_return_anchors")
	anchor.position = Vector3(gx, _heightmap.height_at(gx, az), az)
	parent.add_child(anchor)
	return true
