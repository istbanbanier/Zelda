## Matrice région → identité visuelle + manifeste de végétation (V2.2R §2).
##
## Imprime du Markdown depuis les CONSTANTES RÉELLES du code — peinture,
## cendre, profils de semis — et le layout gelé. Rien n'est recopié à la
## main : si une valeur change dans un bâtisseur, la matrice régénérée
## change avec elle (règle d'ancrage : le chiffre vit dans la preuve datée).
##
## Usage :
##   godot --headless --path . --script \
##       tools/godot/print_region_identity_matrix.gd > sortie.md
## Sections délimitées par === MATRICE === et === VEGETATION ===.
extends SceneTree


func _initialize() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/world_v2/world_v2_layout.json")) as Dictionary
	var names: Dictionary = {}
	var functions: Dictionary = {}
	for entry: Variant in layout.get("regions", []) as Array:
		var region: Dictionary = entry as Dictionary
		names[StringName(String(region.get("id", "")))] = region.get("name", "?")
		functions[StringName(String(region.get("id", "")))] = \
			region.get("function", "")

	print("=== MATRICE ===")
	print("| Région | Nom | Peinture sol | Cendre | Herbe/m² | Arbres/m² | Rochers/m² | Traits de semis |")
	print("|---|---|---|---:|---:|---:|---:|---|")
	var region_ids: Array = WorldV2TerrainBuilder.REGION_PAINT.keys()
	region_ids.sort()
	for id: StringName in region_ids:
		var paint: Color = WorldV2TerrainBuilder.REGION_PAINT[id] as Color
		var ash: float = float(WorldV2TerrainBuilder.REGION_ASH.get(id, 0.0))
		var profile: Dictionary = \
			WorldV2VegetationBuilder.PROFILES.get(id, {}) as Dictionary
		var traits: Array[String] = []
		for flag: String in ["phrases", "tall", "reeds", "clusters", "dead"]:
			if bool(profile.get(flag, false)):
				traits.append(flag)
		print("| %s | %s | #%s | %.2f | %.3f | %.4f | %.4f | %s |" % [
			String(id).substr(0, 3), names.get(id, "?"),
			paint.to_html(false), ash,
			float(profile.get("grass", 0.0)),
			float(profile.get("trees", 0.0)),
			float(profile.get("boulders", 0.0)),
			", ".join(traits) if not traits.is_empty() else "—",
		])
	print("")
	print("Fonctions contractuelles (layout gelé) :")
	for id: StringName in region_ids:
		if functions.get(id, "") != "":
			print("- **%s** : %s" % [String(id).substr(0, 3),
				String(functions.get(id, ""))])

	print("=== VEGETATION ===")
	print("| Constante | Valeur | Rôle |")
	print("|---|---:|---|")
	print("| `CELL_M` | %d m | côté d'une cellule MultiMesh |"
		% WorldV2VegetationBuilder.CELL_M)
	print("| `GLOBAL_SEED` | %d | graine déterministe globale |"
		% WorldV2VegetationBuilder.GLOBAL_SEED)
	print("| `ROUTE_CLEAR_M` | %.1f m | couloir des routes |"
		% WorldV2VegetationBuilder.ROUTE_CLEAR_M)
	print("| `FORD_CLEAR_M` | %.1f m | couloir des gués (traversables) |"
		% WorldV2VegetationBuilder.FORD_CLEAR_M)
	print("| `FORD_BLOCKER_CLEAR_M` | %.1f m | écart des BLOQUANTS aux gués |"
		% WorldV2VegetationBuilder.FORD_BLOCKER_CLEAR_M)
	print("| `CHECKPOINT_CLEAR_M` | %.1f m | couloir des checkpoints |"
		% WorldV2VegetationBuilder.CHECKPOINT_CLEAR_M)
	print("| `CAMERA_BLOCKER_CLEAR_M` | %.1f m | écart des bloquants aux yeux gelés |"
		% WorldV2VegetationBuilder.CAMERA_BLOCKER_CLEAR_M)
	print("| `TRUNK_RADIUS_M` | %.2f m | rayon de collision d'un tronc |"
		% WorldV2VegetationBuilder.TRUNK_RADIUS_M)
	print("| `BOULDER_COLLIDER_MIN_RADIUS_M` | %.2f m | seuil de collision d'un rocher |"
		% WorldV2VegetationBuilder.BOULDER_COLLIDER_MIN_RADIUS_M)
	print("")
	print("Espèces (Quaternius, CC0 — ATTRIBUTIONS ART-Q0/Q8/Q9) :")
	print("- prairie : %s" % ", ".join(WorldV2VegetationBuilder.TREES_MEADOW))
	print("- rivière : %s" % ", ".join(WorldV2VegetationBuilder.TREES_RIVERSIDE))
	print("- bois : %s" % ", ".join(WorldV2VegetationBuilder.TREES_WOOD))
	print("- sec : %s" % ", ".join(WorldV2VegetationBuilder.TREES_DRY))
	print("- mort : %s" % ", ".join(WorldV2VegetationBuilder.TREES_DEAD))
	print("- fleurs : %s (la rose, Flower_3_Group, est l'accent rare)"
		% ", ".join(WorldV2VegetationBuilder.FLOWER_MODELS))
	print("- rochers : %s" % ", ".join(WorldV2VegetationBuilder.BOULDER_MODELS))
	print("- cailloux : %s" % ", ".join(WorldV2VegetationBuilder.PEBBLE_MODELS))
	print("=== FIN ===")
	quit(0)
