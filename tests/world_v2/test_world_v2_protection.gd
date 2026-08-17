## V2.1 — PROTECTIONS : ce que cette phase n'a PAS le droit de changer.
##
## Deux verrous en LITTÉRAUX, jamais lus depuis le code qu'ils surveillent :
##   - le schéma de sauvegarde reste en version 4 — aucune migration réelle
##     avant la phase dédiée (contrat V2.0 §sauvegarde) ;
##   - les ancres §3.3 de la carte directrice restent aux coordonnées du
##     MASTER_SPEC — un layout qui dérive serait suivi par tous les
##     bâtisseurs au lieu d'être dénoncé.
extends GateTestCase


func test_le_schema_de_sauvegarde_reste_en_version_4() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	var system: Node = loop.root.get_node("SaveSystem")
	check_equal(int(system.get("SCHEMA_VERSION")), 4,
		"SCHEMA_VERSION == 4 — la V2.1 ne touche pas à la sauvegarde")


func test_les_ancres_du_layout_restent_celles_du_master_spec() -> void:
	var layout: Dictionary = WorldV2Layout.load_layout()
	var anchors: Dictionary = layout.get("spec_anchors", {}) as Dictionary
	# Littéraux MASTER_SPEC §3.3 — indépendants du JSON et du code.
	var expected: Dictionary = {
		"spawn": [0, 24, 170],
		"camp": [45, 6, 65],
		"pylon": [115, 18, -25],
		"dungeon_gate": [0, 34, -210],
	}
	for key: String in expected:
		var wanted: Array = expected[key] as Array
		var actual: Array = anchors.get(key, []) as Array
		check_equal(actual.size(), 3, "l'ancre %s existe" % key)
		if actual.size() != 3:
			continue
		for axis: int in range(3):
			check_approx(float(actual[axis]), float(wanted[axis]), 0.001,
				"ancre %s, axe %d" % [key, axis])
	check_equal(String(anchors.get("spawn_look", "")), "-Z",
		"le regard du spawn reste vers -Z")
