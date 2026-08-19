## V2.3-A.R2B (agent C) — contrôles NÉGATIFS de l'habillage du bassin
## conducteur. Fichier neuf, propriété de l'agent C (arbitrage R2B §1) :
## personne d'autre n'y écrit, le lead relit et intègre.
##
## Écrit ROUGE d'abord (2026-08-19) : au moment de l'écriture, l'habillage
## est fait d'environ cinquante `stone_block` procéduraux — des `ArrayMesh`
## sans UV ni provenance. Le lead a rejeté « des primitives » ; ces
## contrôles rendent le rejet EXÉCUTABLE, puis empêchent son retour.
##
## Trois filets :
##   1. anti-primitive : tout maillage visible HORS du sous-arbre canonique
##      (`ConductiveBasin`) vient d'un module du kit — provenance prouvée
##      par le résolveur canonique `WorldV2PlaceKit.scene_for()`, UV exigés.
##      La nappe d'eau reste la seule exemption, NOMMÉE (`NappeDEau`) ;
##   2. comportement + contrat rejoués dans le monde monté : la classe
##      canonique intacte, le graphe enfant direct, le récepteur qui
##      ATTEND, la récompense, la découverte, les appuis, les colliders,
##      le volume de baignade libre et le poste de lien dégagé ;
##   3. lampes (option B de l'arbitrage) : le MESH de Socle/Fût est
##      remplacé, le Noyau, son matériau émissif et son raccord
##      `power_changed` restent INTACTS — et l'habillage n'ajoute AUCUNE
##      émission (« cyan ajouté : zéro » est une exigence, pas un vœu).
extends GateTestCase

const PLACE_ID: StringName = &"valley.poi.conductive_basin.01"
const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## Plancher d'examen : un verdict doit publier la taille de ce qu'il a
## examiné (tools/CLAUDE.md). Un lieu qui ne construirait plus son
## habillage rendrait un balayage VIDE — vert par absence — sans ce seuil.
const MIN_DRESSING_MESHES: int = 12

## Emprise de la nappe, épinglée en LITTÉRAL (jamais relue depuis la
## constante testée — l'auto-comparaison suit l'erreur au lieu de la
## dénoncer, tests/CLAUDE.md).
const EXPECTED_WATER_HALF_X: float = 2.80
const EXPECTED_WATER_HALF_Z: float = 2.30

## Zone de baignade canonique de `ConductiveBasin` (locale au bassin) :
## boîte 5,6 × 1,4 × 4,6 centrée à (0 ; 0,4 ; 0). Littéraux, même règle.
const BATHING_LOCAL: AABB = AABB(Vector3(-2.8, -0.3, -2.3),
	Vector3(5.6, 1.4, 4.6))

## Intérieur de nage : l'ellipse d'EAU GARANTIE, pas la boîte. MESURÉ
## avant le premier rouge, en deux temps : (a) la boîte canonique déborde
## la nappe — l'ellipse cabossée culmine à z ≈ 1,9 au nord pour une boîte
## à 2,3, donc une margelle qui « contient l'eau » chevauche forcément la
## boîte sans gêner personne ; (b) même rétrécie de 0,45 m, une boîte
## garde des COINS secs au-delà du bord d'eau, et 11 blocs légitimes y
## tombaient encore. La grandeur qu'on croit mesurer est l'OBSTRUCTION de
## l'eau : on la mesure donc contre l'ellipse de houle MINIMALE du contour
## canonique (swell 0,65 = 0,86 − 0,11 − 0,07 − 0,03), qui est de l'eau en
## toute direction. Les COLLIDERS restent jugés sur la boîte canonique
## entière : aucun corps physique dans le volume, sans exception.
const SWIM_ELLIPSE_HALF_X: float = 1.82  # 2,80 × 0,65
const SWIM_ELLIPSE_HALF_Z: float = 1.50  # 2,30 × 0,65 (arrondi bas)

## Rayon libre exigé autour du poste de lien (`stand_point()`).
const STAND_CLEAR_RADIUS_M: float = 1.0

var _world: Node3D = null


## 1. ANTI-PRIMITIVE — l'habillage vient du kit, avec UV et provenance.
func test_l_habillage_du_bassin_vient_du_kit_avec_uv() -> void:
	var place: Node3D = await _mount_place_alone()
	var faults: Array[String] = []
	if place == null:
		faults.append("bassin : scène du registre introuvable ou non instanciable")
	else:
		var basin: Node3D = _canonical_basin(place)
		if basin == null:
			faults.append("bassin : aucun ConductiveBasin — le balayage n'a pas de sous-arbre canonique à exclure")
		else:
			# L'exemption est NOMMÉE : la nappe reformée s'appelle NappeDEau.
			# Si `_reshape_water` régresse (nappe introuvable), ce nom
			# disparaît et le contrôle le dit — pas une exemption muette.
			if basin.find_children("NappeDEau", "MeshInstance3D",
					false, false).is_empty():
				faults.append("bassin : NappeDEau absente — la nappe n'a pas été reformée (retour au rectangle)")
			var examined: int = 0
			for node: Node in place.find_children("*", "MeshInstance3D",
					true, false):
				var instance: MeshInstance3D = node as MeshInstance3D
				if _inside(basin, instance) or not instance.is_visible_in_tree():
					continue
				examined += 1
				faults.append_array(_kit_mesh_faults(instance))
			check(examined >= MIN_DRESSING_MESHES,
				"le balayage anti-primitive a examiné assez de maillages (%d, plancher %d)"
				% [examined, MIN_DRESSING_MESHES])
	var shown: Array[String] = faults.slice(0, 6)
	if faults.size() > 6:
		shown.append("… et %d autres" % (faults.size() - 6))
	check(faults.is_empty(),
		"l'habillage du bassin vient du kit avec UV (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(shown)])
	await _unmount_place_alone(place)


## 2. COMPORTEMENT + CONTRAT, rejoués dans le monde monté.
func test_le_bassin_garde_comportement_et_contrat_dans_le_monde() -> void:
	await _mount_world()
	var faults: Array[String] = []
	var place: Node3D = _place_in_world(PLACE_ID)
	if place == null:
		faults.append("conductive_basin : lieu ABSENT du monde monté")
	else:
		faults.append_array(_behavior_faults(place))
		faults.append_array(_contract_faults(place))
	var shown: Array[String] = faults.slice(0, 6)
	if faults.size() > 6:
		shown.append("… et %d autres" % (faults.size() - 6))
	check(faults.is_empty(),
		"le bassin garde son comportement et son contrat (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(shown)])
	await _unmount_world()


## 3. LAMPES OPTION B — socle/fût habillés, noyau et raccord intacts,
## et AUCUNE émission ajoutée par l'habillage.
func test_les_lampes_gardent_leur_noyau_et_l_habillage_n_emet_pas() -> void:
	var place: Node3D = await _mount_place_alone()
	var faults: Array[String] = []
	if place == null:
		faults.append("bassin : scène du registre introuvable ou non instanciable")
	else:
		var basin: Node3D = _canonical_basin(place)
		if basin == null:
			faults.append("bassin : aucun ConductiveBasin")
		else:
			var canonical: ConductiveBasin = basin as ConductiveBasin
			faults.append_array(_lamp_faults(canonical.source(), "source", 1.8))
			faults.append_array(_lamp_faults(canonical.receiver(), "récepteur", 0.0))
			# « Cyan ajouté : zéro » : aucun matériau émissif, aucune
			# lumière, hors du sous-arbre canonique.
			for node: Node in place.find_children("*", "MeshInstance3D",
					true, false):
				var instance: MeshInstance3D = node as MeshInstance3D
				if _inside(basin, instance) or not instance.is_visible_in_tree():
					continue
				if instance.mesh == null:
					continue
				for surface: int in range(instance.mesh.get_surface_count()):
					var material: StandardMaterial3D = \
						instance.get_active_material(surface) as StandardMaterial3D
					if material != null and material.emission_enabled:
						faults.append("%s : matériau ÉMISSIF dans l'habillage — seuls les noyaux canoniques émettent"
							% instance.name)
			for node: Node in place.find_children("*", "Light3D", true, false):
				if not _inside(basin, node as Node3D):
					faults.append("%s : lumière ajoutée par l'habillage" % node.name)
	var shown: Array[String] = faults.slice(0, 6)
	if faults.size() > 6:
		shown.append("… et %d autres" % (faults.size() - 6))
	check(faults.is_empty(),
		"les lampes gardent leur noyau et l'habillage n'émet pas (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(shown)])
	await _unmount_place_alone(place)


## -- filets détaillés ---------------------------------------------------------

## Un maillage d'habillage légitime : provenance kit (le RÉSOLVEUR canonique
## sert exactement ce fichier) et UV sur chaque surface.
func _kit_mesh_faults(instance: MeshInstance3D) -> Array[String]:
	var faults: Array[String] = []
	if instance.mesh == null:
		return faults
	var path: String = instance.mesh.resource_path
	if path.is_empty() or not path.begins_with("res://assets/environment/"):
		faults.append("%s : maillage PROCÉDURAL (%s) — primitive hors kit"
			% [instance.name, "sans chemin" if path.is_empty() else path])
		return faults
	var source: String = path.get_slice("::", 0)
	var model: StringName = StringName(source.get_file().get_basename())
	var packed: PackedScene = K.scene_for(model)
	if packed == null or packed.resource_path != source:
		faults.append("%s : %s n'est pas servi par WorldV2PlaceKit.scene_for(%s)"
			% [instance.name, source, model])
	for surface: int in range(instance.mesh.get_surface_count()):
		var arrays: Array = instance.mesh.surface_get_arrays(surface)
		if arrays[Mesh.ARRAY_TEX_UV] == null:
			faults.append("%s : surface %d SANS UV" % [instance.name, surface])
	return faults


## Le filet de comportement de V2.3 §6, rejoué à l'identique.
func _behavior_faults(place: Node3D) -> Array[String]:
	var faults: Array[String] = []
	var basins: Array[Node] = place.find_children("*", "ConductiveBasin",
		true, false)
	if basins.is_empty():
		faults.append("aucun ConductiveBasin (le comportement canonique) dans le lieu")
		return faults
	var basin: ConductiveBasin = basins[0] as ConductiveBasin
	if basin.source() == null or basin.water() == null \
			or basin.receiver() == null:
		faults.append("source/eau/récepteur incomplets")
	var graphs: Array[Node] = basin.find_children("*", "ElectricGraph",
		false, false)
	if graphs.is_empty():
		faults.append("le graphe électrique n'est pas ENFANT DIRECT du bassin")
	elif basin.receiver() != null:
		(graphs[0] as ElectricGraph).recompute()
		if basin.receiver().is_powered():
			faults.append("le récepteur est alimenté SANS lien — le circuit n'attend plus")
	return faults


## Le contrat du lieu : récompense, découverte, appuis, emprise de la
## nappe, colliders, volume de baignade libre, poste de lien dégagé.
func _contract_faults(place: Node3D) -> Array[String]:
	var faults: Array[String] = []
	# Récompense canonique : AncrageRecompense portant un Chest.
	var anchors: Array[Node] = place.find_children("AncrageRecompense",
		"RewardAnchor", true, false)
	if anchors.is_empty():
		faults.append("aucune AncrageRecompense")
	else:
		var chest_found: bool = false
		for anchor: Node in anchors:
			if not (anchor as Node3D).find_children("*", "Chest",
					true, false).is_empty():
				chest_found = true
			for child: Node in anchor.get_children():
				if child is Chest:
					chest_found = true
		if not chest_found:
			faults.append("l'ancrage ne porte aucun Chest")
	if place.find_children("*", "PointOfInterest", true, false).is_empty():
		faults.append("aucun PointOfInterest (découverte)")
	# Appuis déclarés.
	var supports: Variant = place.get_meta(&"support_points", null)
	if not (supports is PackedVector3Array) \
			or (supports as PackedVector3Array).is_empty():
		faults.append("aucun point de support déclaré")
	# Emprise de la nappe : les constantes du lieu, contre des LITTÉRAUX.
	if not is_equal_approx(ConductiveBasinPlace.WATER_HALF_X,
			EXPECTED_WATER_HALF_X) \
			or not is_equal_approx(ConductiveBasinPlace.WATER_HALF_Z,
			EXPECTED_WATER_HALF_Z):
		faults.append("WATER_HALF modifiées : (%.2f ; %.2f), contrat (2,80 ; 2,30)"
			% [ConductiveBasinPlace.WATER_HALF_X, ConductiveBasinPlace.WATER_HALF_Z])
	var basin: Node3D = _canonical_basin(place)
	if basin == null:
		return faults
	# Colliders : couche 1, masque 0 — le monde les porte, ils ne sondent
	# rien. Vaut pour TOUT StaticBody3D du lieu, habillage compris.
	var to_basin: Transform3D = basin.global_transform.affine_inverse()
	for node: Node in place.find_children("*", "StaticBody3D", true, false):
		var body: StaticBody3D = node as StaticBody3D
		if body.collision_layer != 1 or body.collision_mask != 0:
			faults.append("%s : collider couche %d / masque %d, contrat 1/0"
				% [body.name, body.collision_layer, body.collision_mask])
		# Rien dans le volume de baignade — colliders d'habillage inclus.
		if not _inside(basin, body):
			for shape_node: Node in body.find_children("*", "CollisionShape3D",
					false, false):
				var shape: CollisionShape3D = shape_node as CollisionShape3D
				if shape.shape is BoxShape3D:
					var local: AABB = _to_local_aabb(to_basin,
						shape.global_transform,
						AABB(-(shape.shape as BoxShape3D).size * 0.5,
							(shape.shape as BoxShape3D).size))
					if BATHING_LOCAL.intersects(local):
						faults.append("%s : collider DANS le volume de baignade"
							% body.name)
	# Volume de baignade et poste de lien : l'habillage visible n'y entre pas.
	var stand: Vector3 = (basin as ConductiveBasin).stand_point()
	for node: Node in place.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		if _inside(basin, instance) or not instance.is_visible_in_tree() \
				or instance.mesh == null:
			continue
		var local: AABB = _to_local_aabb(to_basin, instance.global_transform,
			instance.mesh.get_aabb())
		if local.position.y <= 1.1 and local.end.y >= -0.3 \
				and _box_enters_swim_ellipse(local):
			faults.append("%s : habillage DANS l'eau garantie de la nappe"
				% instance.name)
		var world_box: AABB = instance.global_transform * instance.mesh.get_aabb()
		if world_box.position.y <= stand.y + 1.9 \
				and world_box.end.y >= stand.y - 0.5 \
				and _xz_distance(stand, world_box) < STAND_CLEAR_RADIUS_M:
			faults.append("%s : habillage à moins de %.1f m du poste de lien"
				% [instance.name, STAND_CLEAR_RADIUS_M])
	return faults


## Option B : Socle et Fût ne sont plus des boîtes (mesh remplacé), le
## Noyau reste la boîte émissive canonique et son raccord `power_changed`
## répond toujours.
func _lamp_faults(node: ElectricNode, label: String,
		idle_energy: float) -> Array[String]:
	var faults: Array[String] = []
	if node == null:
		return ["lampe %s : nœud absent" % label]
	var socle: MeshInstance3D = node.get_node_or_null("Socle") as MeshInstance3D
	var fut: MeshInstance3D = node.get_node_or_null("Fut") as MeshInstance3D
	var core: MeshInstance3D = node.get_node_or_null("Noyau") as MeshInstance3D
	if socle == null or fut == null or core == null:
		faults.append("lampe %s : Socle/Fut/Noyau incomplets" % label)
		return faults
	if socle.mesh is BoxMesh or fut.mesh is BoxMesh:
		faults.append("lampe %s : Socle/Fût encore en BoxMesh — option B non appliquée"
			% label)
	if not (core.mesh is BoxMesh):
		faults.append("lampe %s : le Noyau canonique n'est plus une BoxMesh — option B débordée"
			% label)
	var material: StandardMaterial3D = \
		core.material_override as StandardMaterial3D
	if material == null or not material.emission_enabled:
		faults.append("lampe %s : matériau émissif du Noyau perdu" % label)
		return faults
	if not is_equal_approx(material.emission_energy_multiplier, idle_energy):
		faults.append("lampe %s : émission au repos %.2f, canonique %.2f"
			% [label, material.emission_energy_multiplier, idle_energy])
	# Le raccord `power_changed` répond toujours (option B : lambda intact).
	node.power_changed.emit(true, 1.0)
	var powered_energy: float = material.emission_energy_multiplier
	node.power_changed.emit(false, 0.0)
	if not is_equal_approx(powered_energy, 1.8):
		faults.append("lampe %s : power_changed ne pilote plus le Noyau (%.2f au lieu de 1,80)"
			% [label, powered_energy])
	if not is_equal_approx(material.emission_energy_multiplier, idle_energy):
		faults.append("lampe %s : le Noyau ne revient pas au repos après power_changed"
			% label)
	return faults


## -- outillage ----------------------------------------------------------------

func _canonical_basin(place: Node3D) -> Node3D:
	var basins: Array[Node] = place.find_children("*", "ConductiveBasin",
		true, false)
	return null if basins.is_empty() else basins[0] as Node3D


func _inside(ancestor: Node3D, node: Node) -> bool:
	return ancestor != null and (node == ancestor
		or ancestor.is_ancestor_of(node))


## AABB locale `box` d'un nœud, exprimée dans le repère du bassin.
func _to_local_aabb(to_basin: Transform3D, from_global: Transform3D,
		box: AABB) -> AABB:
	return (to_basin * from_global) * box


## Le point de la boîte (locale au bassin) le plus proche du centre de la
## nappe entre-t-il dans l'ellipse d'eau garantie ?
func _box_enters_swim_ellipse(local: AABB) -> bool:
	var nearest_x: float = clampf(0.0, local.position.x, local.end.x)
	var nearest_z: float = clampf(0.0, local.position.z, local.end.z)
	var nx: float = nearest_x / SWIM_ELLIPSE_HALF_X
	var nz: float = nearest_z / SWIM_ELLIPSE_HALF_Z
	return nx * nx + nz * nz < 1.0


## Distance horizontale (XZ) d'un point à une AABB monde.
func _xz_distance(point: Vector3, box: AABB) -> float:
	var dx: float = maxf(maxf(box.position.x - point.x,
		point.x - box.end.x), 0.0)
	var dz: float = maxf(maxf(box.position.z - point.z,
		point.z - box.end.z), 0.0)
	return Vector2(dx, dz).length()


## Instancie la scène ENREGISTRÉE du bassin, seule (autonomie du contrat
## §5 : elle se construit à plat sans terrain lié).
func _mount_place_alone() -> Node3D:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_root()
	if not WorldV2PlacesBuilder.REGISTRY.has(PLACE_ID):
		return null
	var path: String = String(WorldV2PlacesBuilder.REGISTRY[PLACE_ID])
	if not ResourceLoader.exists(path):
		return null
	var place: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	if place == null:
		return null
	loop.root.add_child(place)
	await loop.process_frame
	return place


func _unmount_place_alone(place: Node3D) -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	if place != null:
		place.queue_free()
		await loop.process_frame
	var clean: bool = await restore_root()
	check(clean, "démontage propre (bassin seul) — %s" % restore_root_reason())


func _mount_world() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame


func _unmount_world() -> void:
	var clean: bool = await restore_root()
	check(clean, "démontage propre (monde monté) — %s" % restore_root_reason())
	restore_saves()
	_world = null


func _place_in_world(place_id: StringName) -> Node3D:
	for node: Node in _world.get_tree().get_nodes_in_group(&"world_v2_places"):
		if node.get_meta(&"place_id", &"") as StringName == place_id:
			return node as Node3D
	return null
