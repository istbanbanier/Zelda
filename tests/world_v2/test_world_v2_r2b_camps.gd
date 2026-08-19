## V2.3-A.R2B — CONTRÔLES NÉGATIFS des deux camps (agent A).
##
## Écrits ROUGES D'ABORD (2026-08-19, arbitrage R2B §Décisions transverses
## n°1) : au moment de l'écriture, le camp-checkpoint est fait de blocs
## procéduraux (halle en `stone_block`, mât à fanions, fumée en boîtes
## translucides) et le camp braise partage la MÊME toile (`AwningTent`),
## brûle un vrai feu (`CampfireProp` émissif) et pend des bannières au bleu
## du kit. Chaque test nomme l'écart mesuré. Vert seulement quand les deux
## lieux sont reconstruits selon le plan approuvé.
##
## Ce que ce filet attrape :
##  1. peau du camp-checkpoint NON modulaire (retour des primitives) —
##     seule exemption NOMMÉE : `CampfireProp`, le feu canonique conservé
##     tel quel (arbitrage R2B, décision c — hors périmètre) ;
##  2. toile commune entre les deux camps (le braise réutilisait
##     `AwningTent`, la grammaire du camp joueur) ;
##  3. camp braise qui n'est pas ÉTEINT : flamme, matériau émissif, ou
##     bleu de bannière du kit non reteinté ;
##  4. guet braise sans signal vertical (plateforme < 4,5 m) ;
##  5. camp-checkpoint sans masse couverte réelle (halle absente ou toit
##     trop bas pour marcher dessous).
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const CAMP_ID: StringName = &"camp"
const EMBER_ID: StringName = &"valley.poi.ember_raider_camps.01"

## 5. La halle : masse couverte minimale et hauteur sous couverture.
## « masse couverte ≥ 8 m² à ≥ 2,2 m » (plan approuvé R2B, agent A).
const HALL_COVER_MIN_M2: float = 8.0
const HALL_UNDERSIDE_MIN_M: float = 2.2
## Faîte annoncé ≈ 3,2 m — borné large pour dénoncer un toit posé au sol
## ou une tour, jamais pour noter l'esthétique.
const HALL_RIDGE_MIN_M: float = 2.8
const HALL_RIDGE_MAX_M: float = 4.2

## 4. Le guet : plancher de guet à ≥ 4,5 m, quatre poteaux, garde-corps.
const WATCH_FLOOR_MIN_M: float = 4.5
const WATCH_POSTS_MIN: int = 4
const WATCH_RAIL_MIN_M: float = 0.5

## 3. Bleu dominant : b − r au-delà de cette marge dénonce une teinte
## froide dans un camp qui n'a droit qu'aux braises et au charbon.
const BLUE_MARGIN: float = 0.02

var _world: Node3D = null


## 1. PEAU DU CAMP-CHECKPOINT = MODULES DU KIT, exemption NOMMÉE :
## `CampfireProp` (feu canonique conservé tel quel, arbitrage R2B c).
## Tout maillage visible doit descendre d'une scène importée de
## `res://assets/` — le retour d'une primitive procédurale rougit ici.
func test_la_peau_du_camp_checkpoint_est_faite_de_modules() -> void:
	await _mount()
	var faults: Array[String] = []
	var camp: Node3D = _place(CAMP_ID)
	if camp == null:
		faults.append("camp : lieu ABSENT")
	else:
		var offenders: Array[String] = []
		for node: Node in camp.find_children("*", "MeshInstance3D", true, false):
			var instance: MeshInstance3D = node as MeshInstance3D
			if instance.mesh == null:
				continue
			if _under_exempt_prop(instance, camp):
				continue
			if _module_root_of(instance, camp) != null:
				continue
			offenders.append(String(instance.name))
		if not offenders.is_empty():
			faults.append("%d maillage(s) procéduraux hors exemption : %s"
				% [offenders.size(), ", ".join(offenders.slice(0, 8))])
	check(faults.is_empty(),
		"la peau du camp-checkpoint est faite de modules (exemption nommée : CampfireProp) — %s"
		% " ; ".join(faults))
	await _unmount()


## 2. TOILE COMMUNE = ∅. Le camp braise ne réutilise plus `AwningTent`
## (la grammaire du camp joueur) : son abri est un appentis en modules
## `Roof_Wooden_2x1` charbon sur poteaux inégaux.
func test_aucune_toile_commune_entre_les_deux_camps() -> void:
	await _mount()
	var faults: Array[String] = []
	var ember: Node3D = _place(EMBER_ID)
	if ember == null:
		faults.append("camp braise : lieu ABSENT")
	else:
		var shared: Array[Node] = ember.find_children("*", "AwningTent",
			true, false)
		if not shared.is_empty():
			faults.append("%d AwningTent dans le camp braise — toile COMMUNE avec le camp joueur"
				% shared.size())
		var lean_to: int = 0
		for node: Node in ember.find_children("*", "", true, false):
			if String(node.name).begins_with("Roof_Wooden_2x1"):
				lean_to += 1
		if lean_to == 0:
			faults.append("aucun appentis Roof_Wooden_2x1 — le braise n'a pas sa propre grammaire d'abri")
	check(faults.is_empty(),
		"aucune toile commune entre les deux camps (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(faults)])
	await _unmount()


## 3. LE CAMP BRAISE EST ÉTEINT : ni flamme (`CampfireProp`, matériau
## émissif), ni bleu (bannière au bleu du kit non reteintée, albédo à
## dominante froide). « Personne n'est là… ou presque. »
func test_le_camp_braise_est_eteint_sans_bleu_ni_flamme() -> void:
	await _mount()
	var faults: Array[String] = []
	var ember: Node3D = _place(EMBER_ID)
	if ember == null:
		faults.append("camp braise : lieu ABSENT")
	else:
		var fires: Array[Node] = ember.find_children("*", "CampfireProp",
			true, false)
		if not fires.is_empty():
			faults.append("%d CampfireProp — le foyer braise doit être ÉTEINT, sans cône de flamme"
				% fires.size())
		var emissive: Array[String] = []
		var blue: Array[String] = []
		var kit_banner: Array[String] = []
		for node: Node in ember.find_children("*", "MeshInstance3D", true, false):
			var instance: MeshInstance3D = node as MeshInstance3D
			if instance.mesh == null:
				continue
			for surface: int in range(instance.mesh.get_surface_count()):
				var material: StandardMaterial3D = instance.get_active_material(
					surface) as StandardMaterial3D
				if material == null:
					continue
				if material.emission_enabled \
						and material.emission_energy_multiplier > 0.0:
					emissive.append(String(instance.name))
				if material.albedo_color.b > material.albedo_color.r + BLUE_MARGIN:
					blue.append(String(instance.name))
				if String(material.resource_name).contains("Banner") \
						and material.albedo_texture != null:
					kit_banner.append(String(instance.name))
		if not emissive.is_empty():
			faults.append("%d surface(s) émissive(s) (flamme/lueur) : %s"
				% [emissive.size(), ", ".join(emissive.slice(0, 4))])
		if not blue.is_empty():
			faults.append("%d surface(s) à dominante bleue : %s"
				% [blue.size(), ", ".join(blue.slice(0, 4))])
		if not kit_banner.is_empty():
			faults.append("%d toile(s) de bannière au bleu du kit (non reteintées EMBER_CLOTH) : %s"
				% [kit_banner.size(), ", ".join(kit_banner.slice(0, 4))])
	check(faults.is_empty(),
		"le camp braise est éteint, sans bleu ni flamme (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(faults)])
	await _unmount()


## 4. LE GUET BRAISE DONNE UN SIGNAL VERTICAL : plancher `Floor_WoodDark`
## à ≥ 4,5 m au-dessus du sol gelé, ≥ 4 poteaux `Corner_Exterior_Wood`,
## et un garde-corps au-dessus du plancher.
func test_le_guet_braise_donne_un_signal_vertical() -> void:
	await _mount()
	var faults: Array[String] = []
	var ember: Node3D = _place(EMBER_ID)
	var heightmap: WorldV2Heightmap = _world.call("heightmap") as WorldV2Heightmap
	if ember == null:
		faults.append("camp braise : lieu ABSENT")
	else:
		var platform: AABB = AABB()
		var found_floor: bool = false
		for node: Node in ember.find_children("*", "", true, false):
			if not String(node.name).begins_with("Floor_WoodDark"):
				continue
			var box: AABB = _meshes_bounds(node)
			if box.size == Vector3.ZERO:
				continue
			if not found_floor or box.end.y > platform.end.y:
				platform = box
				found_floor = true
		if not found_floor:
			faults.append("aucun plancher Floor_WoodDark — pas de plateforme de guet en modules")
		else:
			var center: Vector3 = platform.get_center()
			var ground: float = heightmap.height_at(center.x, center.z)
			var floor_height: float = platform.end.y - ground
			if floor_height < WATCH_FLOOR_MIN_M:
				faults.append("plancher de guet à %.2f m du sol — signal vertical exigé ≥ %.1f m"
					% [floor_height, WATCH_FLOOR_MIN_M])
			var rail_found: bool = false
			for node: Node in ember.find_children("*", "MeshInstance3D", true, false):
				var instance: MeshInstance3D = node as MeshInstance3D
				if instance.mesh == null:
					continue
				var box: AABB = instance.global_transform * instance.mesh.get_aabb()
				var flat: Vector2 = Vector2(box.get_center().x - center.x,
					box.get_center().z - center.z)
				if flat.length() > 2.5:
					continue
				if box.position.y >= platform.end.y - 0.3 \
						and box.end.y >= platform.end.y + WATCH_RAIL_MIN_M:
					rail_found = true
					break
			if not rail_found:
				faults.append("aucun garde-corps au-dessus du plancher de guet")
		var posts: int = 0
		for node: Node in ember.find_children("*", "", true, false):
			if String(node.name).begins_with("Corner_Exterior_Wood"):
				posts += 1
		if posts < WATCH_POSTS_MIN:
			faults.append("%d poteau(x) Corner_Exterior_Wood — %d exigés"
				% [posts, WATCH_POSTS_MIN])
	check(faults.is_empty(),
		"le guet braise donne un signal vertical (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(faults)])
	await _unmount()


## 5. LA HALLE COUVRE UNE MASSE RÉELLE : modules `Roof_*` dont l'emprise
## au sol fait ≥ 8 m², le dessous à ≥ 2,2 m (on marche dessous), le faîte
## dans la bande annoncée (~3,2 m).
func test_la_halle_du_camp_couvre_une_masse_reelle() -> void:
	await _mount()
	var faults: Array[String] = []
	var camp: Node3D = _place(CAMP_ID)
	var heightmap: WorldV2Heightmap = _world.call("heightmap") as WorldV2Heightmap
	if camp == null:
		faults.append("camp : lieu ABSENT")
	else:
		var roof: AABB = AABB()
		var found: bool = false
		for node: Node in camp.find_children("*", "", true, false):
			if not String(node.name).begins_with("Roof_"):
				continue
			var box: AABB = _meshes_bounds(node)
			if box.size == Vector3.ZERO:
				continue
			roof = box if not found else roof.merge(box)
			found = true
		if not found:
			faults.append("aucun module Roof_* — la halle n'existe pas en modules")
		else:
			var area: float = roof.size.x * roof.size.z
			if area < HALL_COVER_MIN_M2:
				faults.append("masse couverte %.1f m² — %.0f m² exigés"
					% [area, HALL_COVER_MIN_M2])
			var center: Vector3 = roof.get_center()
			var ground: float = heightmap.height_at(center.x, center.z)
			var underside: float = roof.position.y - ground
			if underside < HALL_UNDERSIDE_MIN_M:
				faults.append("dessous de toit à %.2f m — ≥ %.1f m exigés pour marcher dessous"
					% [underside, HALL_UNDERSIDE_MIN_M])
			var ridge: float = roof.end.y - ground
			if ridge < HALL_RIDGE_MIN_M or ridge > HALL_RIDGE_MAX_M:
				faults.append("faîte à %.2f m — bande annoncée [%.1f, %.1f]"
					% [ridge, HALL_RIDGE_MIN_M, HALL_RIDGE_MAX_M])
	check(faults.is_empty(),
		"la halle du camp couvre une masse réelle (%d écart(s)) — %s"
		% [faults.size(), " ; ".join(faults)])
	await _unmount()


## -- outillage ----------------------------------------------------------------

func _mount() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame


func _unmount() -> void:
	var clean: bool = await restore_root()
	check(clean, "démontage propre (camps r2b) — %s" % restore_root_reason())
	restore_saves()


func _place(place_id: StringName) -> Node3D:
	for node: Node in _world.get_tree().get_nodes_in_group(&"world_v2_places"):
		if node.get_meta(&"place_id", &"") as StringName == place_id:
			return node as Node3D
	return null


## Racine de module la plus proche : un ancêtre (borné au lieu) qui est
## l'instance d'une scène importée depuis `res://assets/`.
func _module_root_of(node: Node, place: Node3D) -> Node:
	var walker: Node = node
	while walker != null and walker != place:
		if not walker.scene_file_path.is_empty() \
				and walker.scene_file_path.begins_with("res://assets/"):
			return walker
		walker = walker.get_parent()
	return null


## Exemption NOMMÉE du contrôle de peau : `CampfireProp` uniquement
## (arbitrage R2B, décision c — le feu canonique est hors périmètre).
func _under_exempt_prop(node: Node, place: Node3D) -> bool:
	var walker: Node = node
	while walker != null and walker != place:
		if walker is CampfireProp:
			return true
		walker = walker.get_parent()
	return false


## AABB monde fusionnée des maillages d'un sous-arbre.
func _meshes_bounds(root: Node) -> AABB:
	var merged: AABB = AABB()
	var first: bool = true
	var targets: Array[Node] = root.find_children("*", "MeshInstance3D",
		true, false)
	if root is MeshInstance3D:
		targets.append(root)
	for node: Node in targets:
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance.mesh == null:
			continue
		var box: AABB = instance.global_transform * instance.mesh.get_aabb()
		if first:
			merged = box
			first = false
		else:
			merged = merged.merge(box)
	return merged
