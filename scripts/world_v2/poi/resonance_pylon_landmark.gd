## PYLÔNE DE RÉSONANCE (ancre §3.3 `pylon`, r07) — le repère vertical
## entre le camp et la marche de l'orage.
##
## CE SCRIPT NE MODÈLE PLUS RIEN. C'est le changement de pipeline exigé
## par le lead en V2.3-A.R2a : « les scripts ne doivent plus fabriquer
## seuls la surface artistique finale sous forme d'assemblages de BoxMesh,
## plaques ou fragments visibles ». Il reste responsable de quatre choses,
## et de rien d'autre : instancier, implanter, exposer les interfaces
## fonctionnelles, poser les collisions simples.
##
## La surface vient de `assets/architecture/pylon/SM_Pylon_Resonance.glb`,
## produit par une source de génération reproductible et versionnée :
## `source_assets/blender/architecture/make_pylon_resonance.py`. Dix-sept
## volumes LOFTÉS — aucun booléen, aucune primitive visible — dont les
## trois canaux sont creusés DANS le profil du fût et non ajoutés après.
## Mesuré à l'export : 34,56 m, base à z = 0, 5 252 triangles,
## cinq matériaux nommés, zéro texture.
##
## Ce qui reste PRIMITIF est invisible et le restera : les deux corps de
## collision. C'est la place que le lead assigne aux primitives — « les
## réserver aux collisions, sondes et supports invisibles ».
##
## Implantation MESURÉE, inchangée depuis V2.3-A.R : l'ancre §3.3
## `(115, 18, −25)` est un jalon des routes principale ET des hauteurs, et
## son rayon vertical doit continuer de toucher le terrain NU (filet
## `test_world_v2_anchors`). La structure est donc décalée en local
## `(9,0 ; 4,5)` — monde `(124 ; · ; −20,5)` — ce qui laisse 5,80 m à
## `main_path` et 4,05 m à `heights_route` après le collider de base.
class_name ResonancePylonLandmark
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## L'ouvrage, produit par Blender. Un seul chemin : si le GLB manque, le
## lieu doit le DIRE, pas se rabattre en silence sur des primitives.
const OUVRAGE: String = "res://assets/architecture/pylon/SM_Pylon_Resonance.glb"

## Centre local de la structure (l'ancre §3.3 reste libre — voir en-tête).
const CENTER: Vector3 = Vector3(9.0, 0.0, 4.5)

## Cotes reprises de la source Blender, pour poser les collisions sans
## avoir à interroger le maillage : elles sont le CONTRAT de l'asset.
const SOCLE_RAYON: float = 4.2
const SOCLE_HAUTEUR: float = 3.6
const FUT_RAYON: float = 2.3
const FUT_Z0: float = 7.1
const FUT_Z1: float = 25.2


func default_place_id() -> StringName:
	return &"pylon"


func _build() -> void:
	var base_y: float = ground_local_y(CENTER.x, CENTER.z)
	var assise: Vector3 = Vector3(CENTER.x, base_y, CENTER.z)

	var ouvrage: Node3D = _instancier_ouvrage()
	if ouvrage == null:
		return
	ouvrage.name = "Ouvrage"
	ouvrage.position = assise
	add_child(ouvrage)
	declare_support(assise)

	_collisions(assise)
	_terrasse()

	# Les trois pieds du tripode portent le terrain gelé, chacun pour son
	# compte : le filet des fondations vérifie chaque appui déclaré.
	for pied: int in range(3):
		var angle: float = TAU * float(pied) / 3.0 + 0.42
		var local: Vector3 = CENTER + Vector3(cos(angle), 0.0, sin(angle)) * 4.05
		declare_support(Vector3(local.x, ground_local_y(local.x, local.z), local.z))


## Charge et instancie l'ouvrage. Aucun repli silencieux : un asset absent
## est une erreur visible, pas un lieu qui se construit à moitié.
func _instancier_ouvrage() -> Node3D:
	var packed: PackedScene = load(OUVRAGE) as PackedScene
	if packed == null:
		push_error("[world_v2] pylône : ouvrage introuvable — %s" % OUVRAGE)
		return null
	var noeud: Node3D = packed.instantiate() as Node3D
	if noeud == null:
		push_error("[world_v2] pylône : ouvrage non instanciable — %s" % OUVRAGE)
		return null
	return noeud


## Deux corps, et deux seulement : la base et le fût. La culée du lead —
## « réserver les primitives aux collisions » — est ici prise au mot.
##
## Le rayon de 4,2 m n'est pas un réglage : au-delà, l'AABB du cylindre
## (un carré de 2r de côté dans le test point-dans-boîte) mord les deux
## couloirs de route qui passent par l'ancre.
func _collisions(assise: Vector3) -> void:
	_cylindre("Base_col", assise + Vector3(0.0, SOCLE_HAUTEUR * 0.5, 0.0),
		SOCLE_RAYON, SOCLE_HAUTEUR)
	_cylindre("Fut_col", assise + Vector3(0.0, (FUT_Z0 + FUT_Z1) * 0.5, 0.0),
		FUT_RAYON, FUT_Z1 - FUT_Z0)


func _cylindre(nom: String, centre: Vector3, rayon: float, hauteur: float) -> void:
	var corps: StaticBody3D = StaticBody3D.new()
	corps.name = nom
	corps.collision_layer = 1
	corps.collision_mask = 0
	var forme: CollisionShape3D = CollisionShape3D.new()
	forme.name = nom + "_forme"
	var cylindre: CylinderShape3D = CylinderShape3D.new()
	cylindre.radius = rayon
	cylindre.height = hauteur
	forme.shape = cylindre
	corps.add_child(forme)
	corps.position = centre
	add_child(corps)


## Le parvis d'arrivée : l'ancre de route reste un sol praticable.
func _terrasse() -> void:
	for dalle: Array in [[0.0, 0.0], [2.2, 1.0], [4.4, 1.9], [1.2, -1.6]]:
		K.module(self, &"RockPath_Square_Wide",
			_seated(float(dalle[0]), float(dalle[1])),
			float(dalle[0]) * 31.0, 1.1, K.TONE_STONE)
	# Le pot était en (3,0 ; 6,8), c'est-à-dire seul au pied de la plinthe
	# dans l'axe de la vue de base : un petit objet clair isolé au centre du
	# cadre tire l'œil autant que le sujet. Il rejoint la corde — deux
	# objets groupés se lisent comme une halte, un objet seul comme une
	# erreur de placement.
	K.module(self, &"Pot_1", _seated(5.4, 6.2), 0.0, 1.0, K.TONE_STONE)
	K.module(self, &"Rope_1", _seated(4.2, 6.2), 70.0, 1.0, K.TONE_WOOD)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
