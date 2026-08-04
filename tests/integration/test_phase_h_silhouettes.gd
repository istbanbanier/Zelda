## Phase H, passe H-1 « Horizon, orage, arbres, citadelle » — régressions de
## SILHOUETTE. La capture `vista_horizon_etage` a tranché : crêtes et skyline
## en `BoxMesh` lisaient « gratte-ciels », le nuage (lobes de 8-13 m de haut
## pour ~26 m de rayon) lisait « soucoupe », la citadelle (masse de 24 m sans
## spire) disparaissait devant les montagnes, et les feuilles des arbres
## torsadés (texture moyenne RGB 95/13/13) couvraient la vallée de rouge sang
## — le ratio §3.4 exige 60 % de verts/ocres.
##
## Ces tests encodent les invariants de forme, pas le goût : une capture reste
## la preuve visuelle (§21.8), mais aucune régression ne doit pouvoir remettre
## une boîte dans le ciel sans faire rougir la suite.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const FOLIAGE_DIR: String = "res://assets/environment/foliage/"
const TWISTED_GLTFS: Array[String] = [
	"TwistedTree_1.gltf", "TwistedTree_2.gltf", "TwistedTree_3.gltf",
	"Bush_Common.gltf",
]
const OLIVE_TEXTURE: String = "Leaves_TwistedTree_C_olive.png"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


## Compte les meshes BoxMesh / PrismMesh sous un nœud (enfants directs).
func _count_shapes(parent: Node) -> Dictionary:
	var boxes: int = 0
	var prisms: int = 0
	for child: Node in parent.get_children():
		var mesh_instance: MeshInstance3D = child as MeshInstance3D
		if mesh_instance == null:
			continue
		if mesh_instance.mesh is BoxMesh:
			boxes += 1
		elif mesh_instance.mesh is PrismMesh:
			prisms += 1
	return {"boxes": boxes, "prisms": prisms}


func test_silhouettes_montagnes_nuage_et_citadelle() -> void:
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(8)

	# --- Montagnes : silhouettes triangulaires, plus jamais de boîtes. ---
	var terrain: Node = valley.get_node("Terrain")
	var crests: Node = terrain.get_node("BorderCrests")
	var crest_shapes: Dictionary = _count_shapes(crests)
	check_equal(int(crest_shapes["boxes"]), 0,
		"aucune crête n'est une boîte (le « mur de gratte-ciels » de la capture)")
	check(int(crest_shapes["prisms"]) >= 40,
		"les crêtes sont des prismes (%d)" % int(crest_shapes["prisms"]))
	var skyline: Node = terrain.get_node("FarSkyline")
	var far_shapes: Dictionary = _count_shapes(skyline)
	check_equal(int(far_shapes["boxes"]), 0,
		"aucun massif lointain n'est une boîte")
	check(int(far_shapes["prisms"]) >= 56,
		"les massifs lointains sont des prismes (%d)" % int(far_shapes["prisms"]))

	# --- Nuage : cumuliforme, pas une galette. ---
	var storm: StormCell = valley.get_node("CitadelStorm") as StormCell
	check_not_null(storm, "la cellule d'orage existe au-dessus de la citadelle")
	if storm != null:
		var lumps: int = 0
		var ratio_sum: float = 0.0
		for child: Node in storm.get_children():
			if not child.name.begins_with("CloudLayer"):
				continue
			var lump: MeshInstance3D = child as MeshInstance3D
			var sphere: SphereMesh = lump.mesh as SphereMesh
			if sphere == null:
				continue
			lumps += 1
			ratio_sum += sphere.height / sphere.radius
		check(lumps >= 12, "au moins 12 grumeaux (%d) — 8 lisaient « galette »" % lumps)
		if lumps > 0:
			var mean_ratio: float = ratio_sum / float(lumps)
			check(mean_ratio >= 0.8,
				"grumeaux dodus : hauteur/rayon moyen %.2f ≥ 0,8 (avant : ~0,55)"
					% mean_ratio)

	# --- Citadelle : masse élargie et spire qui domine ses tours (§2.4). ---
	var citadel: Node3D = valley.get_node("Terrain/CitadelProxy") as Node3D
	check_not_null(citadel, "le proxy de citadelle existe")
	var spire_top: float = -INF
	if citadel != null:
		var keep: MeshInstance3D = citadel.get_node_or_null("Keep/KeepMesh") \
			as MeshInstance3D
		if keep == null:
			keep = citadel.get_node_or_null("Keep") as MeshInstance3D
		check_not_null(keep, "la masse centrale (Keep) existe")
		if keep != null:
			var keep_box: BoxMesh = keep.mesh as BoxMesh
			check(keep_box != null and keep_box.size.x >= 30.0,
				"masse centrale élargie : %.0f m ≥ 30 (avant : 24 — une cabane)"
					% (keep_box.size.x if keep_box != null else 0.0))
		for child: Node in citadel.get_children():
			if not child.name.begins_with("Spire"):
				continue
			var segment: MeshInstance3D = child as MeshInstance3D
			if segment == null or not (segment is MeshInstance3D):
				continue
			var aabb: AABB = segment.get_aabb()
			var top: float = (segment.global_transform * aabb).get_support(Vector3.UP).y
			spire_top = maxf(spire_top, top)
		check(spire_top >= 34.0 + 60.0,
			"une spire domine la citadelle : sommet y %.1f ≥ 94" % spire_top)

	# --- L'éclair frappe la spire, pas un toit invisible. ---
	if storm != null and spire_top > -INF:
		var strike_world: Vector3 = storm.global_position + storm.strike_offset
		check(absf(strike_world.y - spire_top) <= 6.0,
			"l'éclair frappe le sommet de la spire (impact y %.1f, spire y %.1f)"
				% [strike_world.y, spire_top])

	_tree().root.remove_child(valley)
	valley.queue_free()
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)


func test_h2_jupes_de_mur_sol_macro_et_colonne_d_eclair() -> void:
	## Passe H-2, trois offenseurs MESURÉS sur `vista_h1_silhouettes` :
	##  - le mur de bordure (dalle plate de 70 m) lisait « barrage » (#A9B5B8
	##    uniforme sur 500 m) → jupes de prismes contre les faces internes,
	##    écrêtées derrière la citadelle pour qu'elle domine ;
	##  - le sol nu était un aplat sans variation macro (§5.1) → bruit
	##    triplanar MONDE (continu d'une dalle à l'autre) ;
	##  - la colonne d'éclair (14 m) se perdait dans la jupe du nuage →
	##    ≥ 15 m entre l'origine du tracé et l'impact.
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(8)

	var terrain: Node = valley.get_node("Terrain")
	var skirts: Node = terrain.get_node_or_null("WallSkirts")
	check_not_null(skirts, "les jupes de mur existent")
	if skirts != null:
		var shapes: Dictionary = _count_shapes(skirts)
		check_equal(int(shapes["boxes"]), 0, "aucune jupe n'est une boîte")
		check(int(shapes["prisms"]) >= 40,
			"les jupes sont des prismes (%d)" % int(shapes["prisms"]))
		var worst_behind: float = -INF
		for child: Node in skirts.get_children():
			var skirt: MeshInstance3D = child as MeshInstance3D
			if skirt == null:
				continue
			var prism: PrismMesh = skirt.mesh as PrismMesh
			if prism == null:
				continue
			if skirt.position.z < -240.0 and absf(skirt.position.x) < 110.0:
				worst_behind = maxf(worst_behind,
					skirt.position.y + prism.size.y * 0.5)
		check(worst_behind > -INF and worst_behind <= 44.0,
			"derrière la citadelle, les jupes restent SOUS ses gradins (top %.1f ≤ 44)"
				% worst_behind)

	# H-2c : la bande plate au CENTRE du cadre était la face sud du plateau
	# du donjon (130 × 42 m à 315 m), pas le mur de bordure — l'habiller.
	var plateau_skirts: Node = terrain.get_node_or_null("PlateauSkirts")
	check_not_null(plateau_skirts, "les jupes du plateau du donjon existent")
	if plateau_skirts != null:
		var plateau_shapes: Dictionary = _count_shapes(plateau_skirts)
		check_equal(int(plateau_shapes["boxes"]), 0,
			"aucune jupe de plateau n'est une boîte")
		check(int(plateau_shapes["prisms"]) >= 12,
			"la falaise du plateau est habillée (%d prismes)"
				% int(plateau_shapes["prisms"]))
		var rim_break: bool = false
		for child: Node in plateau_skirts.get_children():
			var skirt: MeshInstance3D = child as MeshInstance3D
			if skirt == null:
				continue
			var prism: PrismMesh = skirt.mesh as PrismMesh
			if prism != null \
					and skirt.position.y + prism.size.y * 0.5 > 34.2:
				rim_break = true
		check(not rim_break,
			"aucune jupe ne dépasse le rebord du plateau (la voie vers la porte reste dégagée)")

	var plain: MeshInstance3D = terrain.get_node_or_null("PlainSouth/PlainSouthMesh") \
		as MeshInstance3D
	check_not_null(plain, "la dalle de plaine sud existe")
	if plain != null:
		var ground: StandardMaterial3D = plain.material_override as StandardMaterial3D
		check(ground != null and ground.albedo_texture is NoiseTexture2D,
			"le sol porte une variation macro (NoiseTexture2D)")
		check(ground != null and ground.uv1_triplanar and ground.uv1_world_triplanar,
			"…projetée en triplanar MONDE : continue d'une dalle à l'autre")
		# L'invariant se mesure sur la TEXTURE GÉNÉRÉE, pas sur les réglages :
		# la première version avait tous les drapeaux corrects et un
		# quasi-aplat (écart-type 0,039 — la distribution FBM concentre tout
		# autour de 0,5). Seuil 0,06 : en dessous, la « variation » ne se
		# voit pas.
		if ground != null and ground.albedo_texture is NoiseTexture2D:
			var noise_texture: NoiseTexture2D = ground.albedo_texture as NoiseTexture2D
			var image: Image = noise_texture.get_image()
			if image == null:
				await noise_texture.changed
				image = noise_texture.get_image()
			check_not_null(image, "la texture de bruit est générée")
			if image != null:
				var total: float = 0.0
				var squares: float = 0.0
				var samples: int = 0
				for py: int in range(0, image.get_height(), 8):
					for px: int in range(0, image.get_width(), 8):
						var luma: float = image.get_pixel(px, py).get_luminance()
						total += luma
						squares += luma * luma
						samples += 1
				var mean: float = total / float(samples)
				var deviation: float = sqrt(maxf(0.0, squares / float(samples) - mean * mean))
				check(deviation >= 0.06,
					"la variation macro se VOIT : écart-type luma %.3f ≥ 0,06 (aplat : 0,039)"
						% deviation)

	var storm: StormCell = valley.get_node("CitadelStorm") as StormCell
	check_not_null(storm, "la cellule d'orage existe")
	if storm != null:
		var origin: Variant = storm.get_script().get_script_constant_map() \
			.get("BOLT_ORIGIN")
		check(origin is Vector3, "l'origine du tracé d'éclair est une constante nommée")
		if origin is Vector3:
			var column: float = (origin as Vector3).distance_to(storm.strike_offset)
			check(column >= 15.0,
				"la colonne d'éclair fait %.1f m ≥ 15 (avant : 14,0)" % column)

	_tree().root.remove_child(valley)
	valley.queue_free()
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)


func test_h3_la_crete_descend_en_pente_pas_en_falaise() -> void:
	## Passe H-3, composition (§1.1, §3.3) : la North Star regarde une vallée
	## EN CONTREBAS — une pente fleurie occupe le bas du cadre. Chez nous, le
	## bord nord de la crête (z 144) tombait de 22 m d'un coup : la vista
	## lisait « pré plat posé devant un décor ». Le profil du sol le long de
	## l'axe de descente doit être une PENTE : aucune marche de plus de 4 m
	## entre deux sondes espacées de 4 m (46° max — au-delà, ni marchable ni
	## crédible comme prairie), et la plaine est atteinte sans rupture.
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)

	var space: PhysicsDirectSpaceState3D = valley.get_world_3d().direct_space_state
	var previous_height: float = INF
	var worst_drop: float = 0.0
	var reached_plain: bool = false
	for step: int in range(21):
		var z: float = 144.0 - 4.0 * float(step)   # z 144 → 64
		# x 7,5 : l'axe de la pente — recentrée après que l'audit des
		# ancrages a refusé le tracé x −4 (ferme abandonnée encastrée).
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D \
			.create(Vector3(7.5, 45.0, z), Vector3(7.5, -10.0, z))
		# Sol seulement (couche 1), pas le joueur ni un prop.
		query.collision_mask = 1
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			continue
		var height: float = (hit["position"] as Vector3).y
		if previous_height < INF:
			worst_drop = maxf(worst_drop, previous_height - height)
		previous_height = height
		if height <= 4.0:
			reached_plain = true
	check(worst_drop <= 4.0,
		"aucune falaise sur l'axe de descente : pire marche %.1f m ≤ 4 (avant : 22)"
			% worst_drop)
	check(reached_plain, "la pente atteint réellement la plaine (y ≤ 4)")

	_tree().root.remove_child(valley)
	valley.queue_free()
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)


func test_h4_le_fond_nord_laisse_le_ciel_et_la_pente_fleurit() -> void:
	## Passe H-4. Deux offenseurs mesurés sur `vista_h3c_final` :
	##  - le fond NORD culmine à 134 m (mur 70 + crêtes + pics) : depuis la
	##    caméra (y 27, 400 m), il monte à ~15° d'élévation et réduit le ciel
	##    à ~15-20 % du cadre — la référence en veut 38-48 %, avec un horizon
	##    montagneux à Y 24-43 % de l'image (élévation ~4-10°). Plafonds côté
	##    nord : crêtes ≤ 96 m, pics proches ≤ 96, rangée éloignée ≤ 112.
	##  - la SpawnSlope est NUE : le « premier plan végétal » de §1.1 (Y
	##    72-100 % du cadre) est la pente — brins et fleurs doivent
	##    l'habiller, à SA hauteur (ils épousent l'inclinaison, pas un plan).
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(8)

	var terrain: Node = valley.get_node("Terrain")
	# --- Plafonds du fond nord. ---
	var worst_crest: float = -INF
	for child: Node in terrain.get_node("BorderCrests").get_children():
		var crest: MeshInstance3D = child as MeshInstance3D
		if crest == null or not (crest.mesh is PrismMesh):
			continue
		if crest.position.z < -240.0:
			worst_crest = maxf(worst_crest,
				crest.position.y + (crest.mesh as PrismMesh).size.y * 0.5)
	check(worst_crest > -INF and worst_crest <= 96.0,
		"crêtes nord sous le plafond : sommet %.0f ≤ 96 (avant : 111)" % worst_crest)
	var worst_peak: float = -INF
	var worst_far_peak: float = -INF
	var dressing: Node = terrain.get_node("MountainDressing")
	for child: Node in dressing.get_children():
		var peak: MeshInstance3D = child as MeshInstance3D
		if peak == null or not (peak.mesh is PrismMesh):
			continue
		if peak.position.z > -240.0:
			continue
		var top: float = peak.position.y + (peak.mesh as PrismMesh).size.y * 0.5
		if child.name.begins_with("FarPeak"):
			worst_far_peak = maxf(worst_far_peak, top)
		elif child.name.begins_with("Peak"):
			worst_peak = maxf(worst_peak, top)
	check(worst_peak > -INF and worst_peak <= 96.0,
		"pics proches nord sous le plafond : %.0f ≤ 96 (avant : 134)" % worst_peak)
	check(worst_far_peak > -INF and worst_far_peak <= 112.0,
		"rangée éloignée nord sous le plafond : %.0f ≤ 112 (avant : 142)"
			% worst_far_peak)

	# --- Flore de la pente : les brins épousent l'inclinaison. ---
	var flora: Node = terrain.get_node_or_null("SlopeFlora")
	check_not_null(flora, "la pente porte sa flore")
	if flora != null:
		var blades: MultiMeshInstance3D = flora.get_node_or_null("SlopeBlades") \
			as MultiMeshInstance3D
		check_not_null(blades, "…des brins d'herbe")
		if blades != null:
			check(blades.multimesh.instance_count >= 3000,
				"…en nombre (%d ≥ 3000)" % blades.multimesh.instance_count)
			var origins: PackedVector3Array = blades.get_meta(&"origins",
				PackedVector3Array()) as PackedVector3Array
			check(origins.size() >= 3000, "…origines consignées pour la preuve")
			var off_slope: int = 0
			for i: int in range(0, origins.size(), 97):
				var origin: Vector3 = origins[i]
				var slope_height: float = 2.0 + 30.0 * (origin.z - 60.0) / 84.0
				if absf(origin.y - slope_height) > 0.6:
					off_slope += 1
			check_equal(off_slope, 0,
				"chaque brin échantillonné est À la hauteur de la pente (±0,6 m)")
		check_not_null(flora.get_node_or_null("SlopeFlowers"),
			"…et des fleurs, concentrées vers la rupture")

	_tree().root.remove_child(valley)
	valley.queue_free()
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)


func test_h5_le_contrebas_se_creuse() -> void:
	## Passe H-5 — le constat géométrique de H-4 : le ciel et la profondeur
	## sont BORNÉS par le dénivelé héros→vallée (22 m ; la référence en a
	## ~60). Crête relevée à 32 m : le contrebas passe à 30 m, la pente garde
	## SON emprise (aucun nouveau conflit d'ancrage) en se raidissant à
	## 19,6° — toujours marchable (§8.2 : 46° max).
	##
	## Invariant de GUIDAGE embarqué : la fumée du camp (S3 — quatre
	## testeurs perdus sans elle) doit continuer de dépasser l'œil de crête.
	## Relever la crête sans relever la fumée aurait silencieusement défait
	## le correctif — c'est exactement le genre de régression croisée que ce
	## test verrouille.
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(10)

	var space: PhysicsDirectSpaceState3D = valley.get_world_3d().direct_space_state
	var crest_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D \
		.create(Vector3(0.0, 70.0, 150.0), Vector3(0.0, -10.0, 150.0))
	crest_query.collision_mask = 1
	var crest_hit: Dictionary = space.intersect_ray(crest_query)
	var plain_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D \
		.create(Vector3(7.5, 70.0, 52.0), Vector3(7.5, -10.0, 52.0))
	plain_query.collision_mask = 1
	var plain_hit: Dictionary = space.intersect_ray(plain_query)
	check(not crest_hit.is_empty() and not plain_hit.is_empty(),
		"les deux sondes touchent le sol")
	if not crest_hit.is_empty() and not plain_hit.is_empty():
		var drop: float = (crest_hit["position"] as Vector3).y \
			- (plain_hit["position"] as Vector3).y
		check(drop >= 28.0,
			"le contrebas héros→vallée fait %.1f m ≥ 28 (avant : 22)" % drop)

	var smoke: MeshInstance3D = valley.get_node_or_null("Camp/SmokeColumn") \
		as MeshInstance3D
	check_not_null(smoke, "la colonne de fumée du camp existe toujours")
	if smoke != null:
		var top_y: float = smoke.global_position.y \
			+ (smoke.mesh as CylinderMesh).height * 0.5
		check(top_y > 40.0,
			"la fumée dépasse le NOUVEL œil de crête (%.1f m > 40 — l'œil vista est à 34,9)"
				% top_y)

	_tree().root.remove_child(valley)
	valley.queue_free()
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)


func test_h6_la_citadelle_parle_le_langage_de_resonance() -> void:
	## Passe H-6 — §2.4, les éléments qui manquent au proxy pour lire
	## « citadelle de Résonance » et non « tour de bureaux » :
	##  - la COURONNE DE CAPTURE au sommet de la spire (anneau, ce que la
	##    foudre frappe — §2.4 « la spire capte l'orage ») ;
	##  - TROIS lignes d'énergie descendant de la couronne (§2.4), pas une ;
	##  - des CONTREFORTS à la base (§2.4 : socle, terrasses, contreforts) ;
	##  - une pierre OCRE/BRONZE SOMBRE (§12.1) — le gris neutre actuel
	##    (r − b = 0,012) lit « béton », pas « bronze ancien ».
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(8)

	var citadel: Node3D = valley.get_node("Terrain/CitadelProxy") as Node3D
	check_not_null(citadel, "le proxy de citadelle existe")
	if citadel == null:
		_tree().root.remove_child(valley)
		valley.queue_free()
		return

	var crown: MeshInstance3D = citadel.get_node_or_null("SpireCrown") \
		as MeshInstance3D
	check(crown != null and crown.mesh is TorusMesh,
		"la couronne de capture existe (anneau au sommet de la spire)")
	if crown != null:
		check(absf(crown.position.y - 100.0) <= 4.0,
			"…à hauteur du sommet (y %.1f, spire à 100)" % crown.position.y)

	var crown_conduits: int = 0
	var buttresses: int = 0
	for child: Node in citadel.get_children():
		if child.name.begins_with("CrownConduit"):
			crown_conduits += 1
		if child.name.begins_with("CitadelButtress"):
			var buttress: MeshInstance3D = child as MeshInstance3D
			if buttress != null and buttress.mesh is PrismMesh:
				buttresses += 1
	check(crown_conduits >= 2,
		"avec la ligne centrale, TROIS lignes d'énergie descendent (%d flancs)"
			% crown_conduits)
	check(buttresses >= 4, "des contreforts portent la base (%d ≥ 4)" % buttresses)

	var keep: MeshInstance3D = citadel.get_node_or_null("Keep/KeepMesh") \
		as MeshInstance3D
	check_not_null(keep, "la masse centrale existe")
	if keep != null:
		var stone: StandardMaterial3D = keep.material_override as StandardMaterial3D
		check(stone != null
			and stone.albedo_color.r - stone.albedo_color.b >= 0.04,
			"la pierre est chaude — ocre/bronze sombre §12.1 (r − b = %.3f ≥ 0,04)"
				% (stone.albedo_color.r - stone.albedo_color.b
					if stone != null else 0.0))

	_tree().root.remove_child(valley)
	valley.queue_free()
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)


func test_les_feuilles_torsadees_sont_olive() -> void:
	## La texture rouge sang (moyenne RGB 95/13/13) reste sur disque, mais plus
	## AUCUN arbre du monde ne la référence : les quatre `.gltf` pointent vers
	## la variante olive, dont le vert domine réellement le rouge.
	for gltf_name: String in TWISTED_GLTFS:
		var file: FileAccess = FileAccess.open(FOLIAGE_DIR + gltf_name,
			FileAccess.READ)
		check_not_null(file, "%s se lit" % gltf_name)
		if file == null:
			continue
		var text: String = file.get_as_text()
		file.close()
		check(text.contains(OLIVE_TEXTURE),
			"%s référence la variante olive" % gltf_name)
	var image: Image = Image.new()
	var error: int = image.load(
		ProjectSettings.globalize_path(FOLIAGE_DIR + OLIVE_TEXTURE))
	check_equal(error, OK, "la texture olive existe et se charge")
	if error == OK:
		image.resize(8, 8, Image.INTERPOLATE_BILINEAR)
		var red_sum: float = 0.0
		var green_sum: float = 0.0
		for y: int in range(8):
			for x: int in range(8):
				var pixel: Color = image.get_pixel(x, y)
				red_sum += pixel.r
				green_sum += pixel.g
		check(green_sum > red_sum * 1.2,
			"le vert domine le rouge (G %.2f vs R %.2f) — avant : 13 contre 95"
				% [green_sum, red_sum])
