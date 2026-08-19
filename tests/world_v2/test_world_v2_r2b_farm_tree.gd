## V2.3-A.R2B — FILET de l'agent B : ferme abandonnée + arbre foudroyé.
##
## ORIGINE. Revue du lead (V2.3-A.R2) : la ferme montre « de longues
## planches plantées dans le bâtiment » (une charpente qui ne porte sur
## rien) et l'arbre foudroyé reste « un empilement de blocs » — les deux
## lieux sont bâtis en `K.stone_block()`, des boîtes à sommets déplacés qui
## se lisent comme des primitives à toute distance. L'arbitrage R2B
## (`evidence/world_v2/v2_3_r2b/ARBITRAGE_PLANS.md`, agent B) accorde la
## voie Blender : hero assets `SM_Farm_*` et `SM_ThunderstruckTree` en GLB,
## avec les garde-fous de pipeline R2a.
##
## Écrit ROUGE d'abord (2026-08-19) : au moment de son écriture, aucun GLB
## n'existe, les deux lieux sont procéduraux, la chaîne d'export ne connaît
## pas les sujets. Chaque contrôle nomme l'écart.
##
## LE CRITÈRE « BLOC PROCÉDURAL » EST MESURÉ, pas supposé : un maillage
## construit en runtime (`SurfaceTool.commit()`, la brique de
## `K.stone_block`) porte `resource_path == ""` ; un maillage importé porte
## `res://…gltf::ArrayMesh_…` ou `res://…glb::ArrayMesh_…` (sonde du
## 2026-08-19, `evidence/world_v2/v2_3_r2b/ferme_arbre/`).
##
## L'EXEMPTION EST NOMMÉE, jamais silencieuse (arbitrage R2B) : le disque
## de sol brûlé `SolBrule` de l'arbre reste un mesh runtime — il ÉPOUSE le
## terrain gelé sommet par sommet, même pratique que `rock_floor_mesh`.
## Toute autre géométrie runtime dans ces deux lieux est un défaut.
extends GateTestCase

const FARM_SCENE: String = "res://scenes/world_v2/poi/AbandonedFarmPlace.tscn"
const TREE_SCENE: String = "res://scenes/world_v2/poi/ThunderstruckTreePlace.tscn"
const TREE_GLB: String = "res://assets/architecture/flora/SM_ThunderstruckTree.glb"
const FARM_GLB: String = "res://assets/architecture/farm/SM_Farm_Ruins.glb"
const EXPORT_CHAIN: String = "res://tools/blender/export_architecture.sh"
## Les journaux ARCHIVÉS du pipeline — pas `evidence/pipeline/`, qui est
## gitignoré : un clone frais doit pouvoir vérifier la preuve committée.
## Si quelqu'un régénère un GLB sans réarchiver ses journaux, la taille
## inspectée divergera de celle du dépôt et ce filet rougira — c'est le
## contrat « une preuve datée reliée au commit » (.claude/rules/evidence.md).
const PIPELINE_DIR: String = "res://evidence/world_v2/v2_3_r2b/ferme_arbre/pipeline"

## L'exemption de l'arbitrage R2B : le nom EXACT du nœud, rien d'autre.
const RUNTIME_MESH_EXEMPT: Array[String] = ["SolBrule"]

## Contrat du générateur d'arbre (plan approuvé) : hauteur totale dans
## [10 ; 12] m, base au sol. Littéraux recopiés du plan, jamais lus depuis
## le générateur — un test qui lit la valeur qu'il surveille suit l'erreur.
const TREE_HEIGHT_MIN_M: float = 10.0
const TREE_HEIGHT_MAX_M: float = 12.0
const TREE_BASE_TOLERANCE_M: float = 0.05

## Une charpente PORTÉE : l'écart vertical entre le bas de la ferme
## (chevrons) et l'arase du mur porteur qu'elle chevauche en plan.
## 0,15 m au-dessus = elle flotte ; 0,60 m en dessous = elle traverse.
const TRUSS_GAP_MAX_M: float = 0.15
const TRUSS_SINK_MAX_M: float = 0.60
## Le pan tombé a « un bout au sol » : son point bas reste sous cette
## hauteur au-dessus du sol plat du montage autonome.
const FALLEN_PAN_GROUND_MAX_M: float = 0.40

## Planchers d'architecture : sous ces comptes, le contrôle ne regarde
## rien et passerait à vide. Ce ne sont pas des cibles de qualité.
const FARM_MIN_MESHES: int = 15
const TREE_MIN_MESHES: int = 5
const TREE_GLB_MIN_MESHES: int = 4


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Monte une scène de lieu SEULE (autonomie contractuelle §5-§6) : hors
## monde, `ground_local_y()` rend 0 et le lieu se bâtit à plat — exactement
## le mode du filet d'autonomie des places.
func _mount_alone(path: String) -> Node3D:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	var place: Node3D = packed.instantiate() as Node3D
	if place == null:
		return null
	_tree().root.add_child(place)
	return place


func _dismount(place: Node3D) -> void:
	if place != null:
		place.get_parent().remove_child(place)
		place.queue_free()


func _capped(faults: Array[String], keep: int = 6) -> String:
	if faults.size() <= keep:
		return " ; ".join(faults)
	return " ; ".join(faults.slice(0, keep)) \
		+ " ; (+%d autres)" % (faults.size() - keep)


## Vrai si le nœud vit sous un ancrage de récompense ou un POI : ces
## sous-arbres appartiennent aux systèmes canoniques, pas à la géométrie
## du lieu que ce filet juge.
func _under_canonical_system(node: Node, place: Node3D) -> bool:
	var cursor: Node = node
	while cursor != null and cursor != place:
		if cursor is RewardAnchor or cursor is PointOfInterest:
			return true
		cursor = cursor.get_parent()
	return false


## AABB globale d'un sous-arbre (maillages seuls).
func _bounds(node: Node3D) -> AABB:
	var merged: AABB = AABB()
	var first: bool = true
	var targets: Array[Node] = node.find_children("*", "MeshInstance3D",
		true, false)
	if node is MeshInstance3D:
		targets.append(node)
	for child: Node in targets:
		var instance: MeshInstance3D = child as MeshInstance3D
		if instance.mesh == null:
			continue
		var box: AABB = instance.global_transform * instance.mesh.get_aabb()
		merged = box if first else merged.merge(box)
		first = false
	return merged


func _named_child(place: Node3D, prefix: String) -> Node3D:
	for child: Node in place.find_children("*", "Node3D", true, false):
		if String(child.name).begins_with(prefix):
			return child as Node3D
	return null


## -- 1. Zéro bloc procédural visible, hors exemption NOMMÉE ------------------

func test_zero_bloc_procedural_hors_exemption_nommee() -> void:
	remember_root()
	var faults: Array[String] = []
	var subjects: Dictionary = {"ferme": FARM_SCENE, "arbre": TREE_SCENE}
	var floors: Dictionary = {"ferme": FARM_MIN_MESHES, "arbre": TREE_MIN_MESHES}
	for label: String in subjects.keys():
		var place: Node3D = _mount_alone(String(subjects[label]))
		if place == null:
			faults.append("%s : la scène ne se monte pas seule" % label)
			continue
		await _tree().process_frame
		var meshes: int = 0
		for child: Node in place.find_children("*", "MeshInstance3D", true, false):
			var instance: MeshInstance3D = child as MeshInstance3D
			if instance.mesh == null:
				continue
			meshes += 1
			if _under_canonical_system(child, place):
				continue
			if instance.mesh.resource_path != "":
				continue  # maillage importé (kit CC0 ou GLB) : légitime
			if label == "arbre" and RUNTIME_MESH_EXEMPT.has(String(child.name)):
				continue  # SolBrule — l'exemption de l'arbitrage R2B, nommée
			faults.append("%s : bloc procédural « %s » (mesh runtime hors "
				% [label, child.name] + "exemption SolBrule)")
		if meshes < int(floors[label]):
			faults.append("%s : %d maillage(s) seulement (plancher %d) — le "
				% [label, meshes, int(floors[label])]
				+ "contrôle ne regarde rien")
		_dismount(place)
	check(faults.is_empty(),
		"aucun bloc procédural visible hors l'exemption nommée SolBrule "
		+ "(%d écart(s)) — %s" % [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (blocs procéduraux) — %s"
		% restore_root_reason())


## -- 2. La charpente est PORTÉE par ses murs ---------------------------------

func test_la_charpente_est_portee_par_ses_murs() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	if place == null:
		faults.append("ferme : la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var truss: Node3D = _named_child(place, "SM_Farm_Truss")
		var intact: Node3D = _named_child(place, "SM_Farm_RoofPan_Intact")
		var fallen: Node3D = _named_child(place, "SM_Farm_RoofPan_Fallen")
		var debris: Node3D = _named_child(place, "SM_Farm_Debris")
		if intact == null:
			faults.append("ferme : aucun pan de toit intact SM_Farm_RoofPan_Intact")
		if debris == null:
			faults.append("ferme : aucun gravat SM_Farm_Debris_*")
		if fallen == null:
			faults.append("ferme : aucun pan tombé SM_Farm_RoofPan_Fallen")
		else:
			var fallen_box: AABB = _bounds(fallen)
			if fallen_box.position.y > FALLEN_PAN_GROUND_MAX_M:
				faults.append("ferme : le pan tombé ne touche pas le sol "
					+ "(point bas à %.2f m)" % fallen_box.position.y)
		if truss == null:
			faults.append("ferme : aucune charpente SM_Farm_Truss — le toit "
				+ "n'a rien qui le porte")
		else:
			var truss_box: AABB = _bounds(truss)
			var best_top: float = -1e9
			var overlapping: int = 0
			for child: Node in place.find_children("*", "Node3D", true, false):
				if not String(child.name).begins_with("Wall_UnevenBrick"):
					continue
				var wall_box: AABB = _bounds(child as Node3D)
				if wall_box.size == Vector3.ZERO:
					continue
				var overlap_x: bool = wall_box.end.x > truss_box.position.x \
					and wall_box.position.x < truss_box.end.x
				var overlap_z: bool = wall_box.end.z > truss_box.position.z \
					and wall_box.position.z < truss_box.end.z
				if overlap_x and overlap_z:
					overlapping += 1
					best_top = maxf(best_top, wall_box.end.y)
			if overlapping == 0:
				faults.append("ferme : la charpente ne chevauche AUCUN mur "
					+ "porteur en plan")
			else:
				var gap: float = truss_box.position.y - best_top
				if gap > TRUSS_GAP_MAX_M:
					faults.append("ferme : la charpente FLOTTE à %.2f m "
						% gap + "au-dessus de l'arase des murs (max %.2f)"
						% TRUSS_GAP_MAX_M)
				elif gap < -TRUSS_SINK_MAX_M:
					faults.append("ferme : la charpente TRAVERSE les murs de "
						+ "%.2f m (max %.2f)" % [-gap, TRUSS_SINK_MAX_M])
		_dismount(place)
	check(faults.is_empty(),
		"la charpente est portée par les murs, pan tombé au sol, gravats "
		+ "présents (%d écart(s)) — %s" % [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (charpente) — %s" % restore_root_reason())


## -- 3. L'arbre est un asset GLB présent et VALIDE ---------------------------

func test_l_arbre_est_un_asset_glb_valide() -> void:
	remember_root()
	var faults: Array[String] = []
	if not ResourceLoader.exists(TREE_GLB):
		faults.append("GLB absent : %s" % TREE_GLB)
	else:
		var packed: PackedScene = load(TREE_GLB) as PackedScene
		var asset: Node3D = null if packed == null \
			else packed.instantiate() as Node3D
		if asset == null:
			faults.append("le GLB de l'arbre ne s'instancie pas")
		else:
			_tree().root.add_child(asset)
			await _tree().process_frame
			var meshes: int = 0
			for child: Node in asset.find_children("*", "MeshInstance3D",
					true, false):
				if (child as MeshInstance3D).mesh != null:
					meshes += 1
			if meshes < TREE_GLB_MIN_MESHES:
				faults.append("le GLB porte %d maillage(s), plancher %d "
					% [meshes, TREE_GLB_MIN_MESHES]
					+ "(écorce, cœur, deux branches)")
			var box: AABB = _bounds(asset)
			if box.size.y < TREE_HEIGHT_MIN_M or box.size.y > TREE_HEIGHT_MAX_M:
				faults.append("hauteur %.2f m hors du contrat [%.0f ; %.0f]"
					% [box.size.y, TREE_HEIGHT_MIN_M, TREE_HEIGHT_MAX_M])
			if absf(box.position.y) > TREE_BASE_TOLERANCE_M:
				faults.append("base à y = %.3f — le bas de l'objet n'est pas "
					% box.position.y + "au sol (§7.15)")
			_dismount(asset)
	# Le LIEU monte bien CET asset — pas une copie procédurale du même nom.
	var place: Node3D = _mount_alone(TREE_SCENE)
	if place == null:
		faults.append("arbre : la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var instance: Node3D = _named_child(place, "SM_ThunderstruckTree")
		if instance == null:
			faults.append("arbre : le lieu ne monte aucun nœud "
				+ "SM_ThunderstruckTree*")
		else:
			var imported: bool = false
			for child: Node in instance.find_children("*", "MeshInstance3D",
					true, false):
				var mesh_instance: MeshInstance3D = child as MeshInstance3D
				if mesh_instance.mesh != null and mesh_instance.mesh \
						.resource_path.contains("SM_ThunderstruckTree"):
					imported = true
			if not imported:
				faults.append("arbre : le nœud SM_ThunderstruckTree* ne porte "
					+ "aucun maillage venant du GLB")
		_dismount(place)
	check(faults.is_empty(),
		"l'arbre est un asset GLB présent, valide et monté (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (arbre GLB) — %s" % restore_root_reason())


## -- 4. Le pipeline Blender est frais et vérifié -----------------------------
##
## « Un .glb intact n'est pas un .glb produit » (export_architecture.sh).
## Ici, la fraîcheur est liée par le CONTENU : le journal d'inspection
## imprime la taille en octets du fichier inspecté ; si le GLB du dépôt n'a
## pas cette taille, l'inspection VALIDE appartient à un autre fichier.
## Et `blender --background` rend 0 même quand le script lève
## (tools/CLAUDE.md) : le jeton « FIN NOMINALE » écrit par le générateur
## lui-même est donc exigé dans chaque journal de génération.

func test_le_pipeline_blender_est_frais_et_verifie() -> void:
	var faults: Array[String] = []
	var chain: String = FileAccess.get_file_as_string(EXPORT_CHAIN)
	if chain.is_empty():
		faults.append("chaîne d'export illisible : %s" % EXPORT_CHAIN)
	var subjects: Dictionary = {
		"farm_ruins": {
			"source": "res://source_assets/blender/architecture/make_farm_ruins.py",
			"glb": FARM_GLB,
		},
		"thunderstruck_tree": {
			"source": "res://source_assets/blender/environment/make_thunderstruck_tree.py",
			"glb": TREE_GLB,
		},
	}
	var size_pattern: RegEx = RegEx.new()
	size_pattern.compile("GLB v2, (\\d+) octets")
	for subject: String in subjects.keys():
		var spec: Dictionary = subjects[subject] as Dictionary
		var source: String = String(spec["source"])
		var glb: String = String(spec["glb"])
		if not chain.contains("%s|" % subject):
			faults.append("%s : sujet absent de export_architecture.sh — la "
				% subject + "chaîne ne peut pas le rejouer")
		if not FileAccess.file_exists(source):
			faults.append("%s : générateur absent (%s)" % [subject, source])
		if not FileAccess.file_exists(glb):
			faults.append("%s : GLB absent (%s)" % [subject, glb])
		var make_log: String = FileAccess.get_file_as_string(
			"%s/architecture_%s_make.log" % [PIPELINE_DIR, subject])
		if not make_log.contains("FIN NOMINALE"):
			faults.append("%s : journal de génération sans jeton FIN NOMINALE "
				% subject + "— Blender rend 0 même quand le script lève")
		var inspect_log: String = FileAccess.get_file_as_string(
			"%s/architecture_%s_inspect.log" % [PIPELINE_DIR, subject])
		if not inspect_log.contains("=== VALIDE ==="):
			faults.append("%s : aucune inspection glTF VALIDE au journal"
				% subject)
		else:
			var found: RegExMatch = size_pattern.search(inspect_log)
			var actual: int = FileAccess.get_file_as_bytes(glb).size()
			if found == null:
				faults.append("%s : le journal d'inspection ne porte pas la "
					% subject + "taille inspectée")
			elif actual == 0:
				faults.append("%s : GLB illisible pour la comparaison de "
					% subject + "taille")
			elif int(found.get_string(1)) != actual:
				faults.append("%s : l'inspection VALIDE porte sur %s octets, "
					% [subject, found.get_string(1)]
					+ "le GLB du dépôt en fait %d — journal d'un AUTRE fichier"
					% actual)
	check(faults.is_empty(),
		"le pipeline Blender est frais et vérifié pour les deux sujets "
		+ "(%d écart(s)) — %s" % [faults.size(), _capped(faults)])
