## Infrastructure d'intégration d'assets (ordre de nuit ART-Q0/Q1) — registre
## central, correspondance d'animations, adaptateur à REPLI, calibration.
##
## Tout est mesuré : le registre résout ou rend null proprement sur TOUT le
## catalogue, le validateur d'animations trouve les clips réellement absents
## (dans les deux sens), l'adaptateur replie sans casser quand le modèle
## manque, la scène de calibration étiquette chaque asset manquant et ses
## références font EXACTEMENT leurs cotes.
extends GateTestCase

const CALIBRATION: String = "res://scenes/tests/AssetCalibration.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func test_the_registry_resolves_delivered_assets_and_declines_missing_ones() -> void:
	## Chaque id du catalogue : soit une vraie PackedScene, soit null propre —
	## jamais une exception, jamais une ressource rose. L'Épée usée (livrée)
	## DOIT résoudre ; les ids réservés aux packs absents DOIVENT replier.
	for id: StringName in AssetRegistry.known_ids():
		var packed: PackedScene = AssetRegistry.resolve(id)
		check(packed == null or packed is PackedScene,
			"%s : résolution propre" % String(id))
		check_equal(AssetRegistry.available(id), packed != null,
			"%s : available() dit la même chose que resolve()" % String(id))
	check(AssetRegistry.resolve(&"weapon.worn_sword") != null,
		"l'asset LIVRÉ (Épée usée) résout")
	check(AssetRegistry.resolve(&"char.hero") != null,
		"le héros LIVRÉ (ART-Q1) résout")
	check(AssetRegistry.resolve(&"char.raider_red") != null,
		"le pillard LIVRÉ (ART-Q2) résout")
	check(AssetRegistry.resolve(&"prop.tent") == null,
		"l'asset EN ATTENTE (tente, absente des packs) replie sur null")
	check(AssetRegistry.resolve(&"id.inconnu.xyz") == null,
		"un id inconnu rend null sans crash")


## Les onze ids env/prop/arch livrés par ART-Q0. Chaque lot suivant ALLONGE
## cette liste — la retirer ou la raccourcir est une régression.
const DELIVERED_Q0: Array[StringName] = [
	&"env.tree.large", &"env.tree.medium", &"env.rock.large",
	&"env.rock.medium", &"env.plant.bush", &"prop.chest", &"prop.crate",
	&"prop.barrel", &"arch.gate.module", &"arch.wall.module",
	&"arch.column.module",
	# ART-Q1 :
	&"char.hero",
	# ART-Q2 :
	&"char.raider_red", &"char.raider_blue", &"char.raider_black",
	# ART-Q3 :
	&"env.rock.pebble_a", &"env.rock.pebble_b", &"env.rock.pebble_c",
]


func test_the_q0_delivered_assets_resolve_with_real_meshes() -> void:
	## ART-Q0/Q1 : chaque id livré monte une scène qui contient AU MOINS un
	## maillage réel — pas un wrapper vide qui « résout » sans rien montrer.
	for id: StringName in DELIVERED_Q0:
		var packed: PackedScene = AssetRegistry.resolve(id)
		check(packed != null, "%s : LIVRÉ, doit résoudre" % String(id))
		if packed == null:
			continue
		var instance: Node = packed.instantiate()
		var has_mesh: bool = false
		for node: Node in instance.find_children("*", "MeshInstance3D", true, false):
			if (node as MeshInstance3D).mesh != null:
				has_mesh = true
		check(has_mesh, "%s : au moins un maillage réel monté" % String(id))
		instance.free()


func test_the_hero_candidate_keeps_its_rig_through_the_godot_import() -> void:
	## ART-Q0 : le modèle héros importé (préview, câblage en Q1) transporte
	## son armature — 65 os, mesh skinné. Sans cela, Q1 partirait d'un
	## modèle mort.
	var path: String = "res://assets/characters/hero/Male_Ranger.gltf"
	check(ResourceLoader.exists(path, "PackedScene"),
		"le modèle héros candidat est importé")
	var instance: Node = (load(path) as PackedScene).instantiate()
	var skeletons: Array[Node] = instance.find_children("*", "Skeleton3D", true, false)
	check_equal(skeletons.size(), 1, "une armature exactement")
	if skeletons.size() == 1:
		var skeleton: Skeleton3D = skeletons[0] as Skeleton3D
		check_equal(skeleton.get_bone_count(), 65,
			"les 65 os du squelette UAL (compatibilité animations vérifiée)")
	var skinned: int = 0
	for node: Node in instance.find_children("*", "MeshInstance3D", true, false):
		if (node as MeshInstance3D).skin != null:
			skinned += 1
	check(skinned > 0, "au moins un maillage réellement skinné")
	instance.free()


func test_the_anim_set_validator_measures_real_gaps_in_both_directions() -> void:
	## Le validateur compte les DOUZE états obligatoires, voit un clip présent
	## dans un vrai AnimationPlayer, et signale ceux qui manquent.
	var anim_set: CharacterAnimSet = CharacterAnimSet.new()
	check_equal(anim_set.undeclared_states().size(), 12,
		"correspondance vide : les 12 états sont des trous déclarés")

	anim_set.idle = &"Idle_Loop"
	anim_set.walk = &"Walk_Loop"
	var player: AnimationPlayer = AnimationPlayer.new()
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation(&"Idle_Loop", Animation.new())
	player.add_animation_library(&"", library)
	_tree().root.add_child(player)

	var missing: Array[StringName] = anim_set.missing_clips(player)
	check(not missing.has(&"idle"),
		"idle déclaré ET présent dans le lecteur : pas manquant")
	check(missing.has(&"walk"),
		"walk déclaré mais ABSENT du lecteur : signalé")
	check(missing.has(&"death"), "death jamais déclaré : signalé")
	check_equal(missing.size(), 11, "un seul état réellement couvert sur douze")
	player.queue_free()
	await _settle(1)


func test_the_character_visual_falls_back_cleanly_when_the_model_is_missing() -> void:
	## ART-Q1 : le contrat de repli — modèle absent (packs pas livrés) : rien
	## ne casse, rien ne s'affiche, le socket est nul (le pivot procédural du
	## contrôleur reste l'attache), et validate() DIT l'absence.
	var visual: CharacterVisual = CharacterVisual.new()
	visual.model_id = &"prop.tent"   # id connu, fichier absent (aucune tente)
	visual.anim_set = CharacterAnimSet.new()
	_tree().root.add_child(visual)
	await _settle(1)
	check(visual.is_fallback_active(), "repli actif : aucun modèle monté")
	visual.play_state(&"run")
	check_equal(visual.current_state(), &"run",
		"l'état est accepté même en repli (aucun blocage)")
	check(visual.weapon_socket() == null,
		"pas de socket squelette : le pivot procédural garde l'attache")
	var problems: Array[String] = visual.validate()
	check(problems.size() == 1 and problems[0].contains("repli"),
		"validate() consigne l'absence honnêtement")
	visual.queue_free()
	await _settle(1)


func test_the_calibration_scene_labels_every_missing_asset_and_keeps_scale() -> void:
	## ART-Q0 : un socle par id du catalogue ; les manquants portent un jalon
	## orange étiqueté, les livrés montent leur vraie scène ; le cube de
	## référence fait EXACTEMENT 1 m.
	var calibration: AssetCalibration = (load(CALIBRATION) as PackedScene) \
		.instantiate() as AssetCalibration
	_tree().root.add_child(calibration)
	await _settle(2)
	var ids: Array[StringName] = AssetRegistry.known_ids()
	var slots: Array[Node] = calibration.find_children("Slot_*", "Node3D", false, false)
	check_equal(slots.size(), ids.size(), "un socle par id du catalogue")
	var placeholders: int = 0
	for slot: Node in slots:
		if slot.get_node_or_null("MissingPlaceholder") != null:
			placeholders += 1
	var missing_expected: int = 0
	for id: StringName in ids:
		if not AssetRegistry.available(id):
			missing_expected += 1
	check_equal(placeholders, missing_expected,
		"chaque asset manquant a son jalon — ni plus ni moins")
	var sword_slot: Node = calibration.get_node("Slot_weapon_worn_sword")
	check(sword_slot.get_node_or_null("MissingPlaceholder") == null,
		"l'asset livré monte sa vraie scène, pas un jalon")
	check(sword_slot.find_children("*", "MeshInstance3D", true, false).size() > 0,
		"…et elle contient bien un maillage")
	var cube: MeshInstance3D = calibration.get_node("ReferenceCube1m") as MeshInstance3D
	check_equal(cube.mesh.get_aabb().size, Vector3.ONE,
		"le cube de référence fait exactement 1 m")
	calibration.get_parent().remove_child(calibration)
	calibration.queue_free()
	await _settle(1)


func test_the_model_index_serves_the_promoted_library() -> void:
	## V4 lot 3 : l'index paresseux dessert les ~130 modèles promus par NOM
	## canonique — de vrais maillages, null propre pour l'inconnu.
	check(AssetRegistry.known_models().size() >= 110,
		"au moins 110 modèles promus (%d)" % AssetRegistry.known_models().size())
	for name: StringName in [&"Pine_1", &"Cauldron", &"Wall_Arch",
			&"Grass_Common_Tall", &"Stairs_Exterior_Straight"]:
		var packed: PackedScene = AssetRegistry.model(name)
		check(packed != null, "%s : promu et résolu" % String(name))
		if packed != null:
			var instance: Node = packed.instantiate()
			var has_mesh: bool = false
			for mesh: Node in instance.find_children("*", "MeshInstance3D",
					true, false):
				if (mesh as MeshInstance3D).mesh != null:
					has_mesh = true
			check(has_mesh, "%s : maillage réel" % String(name))
			instance.free()
	check(AssetRegistry.model(&"Modele_Inconnu_XYZ") == null,
		"inconnu : null propre, jamais une ressource rose")


func test_the_character_variants_have_distinct_silhouettes() -> void:
	## V4 lot 13 (§12 : « pas de simples recolorations ») : l'azur porte
	## épaulière + bottes GREFFÉES au squelette, l'obsidienne capuche +
	## épaulière et carrure ×1,12, le héros une texture DÉRIVÉE (capuche
	## turquoise) — mesuré sur les scènes réelles, maillages skinnés liés.
	var counts: Dictionary[StringName, int] = {}
	for id: StringName in [&"char.raider_red", &"char.raider_blue",
			&"char.raider_black"]:
		var visual: Node3D = (AssetRegistry.resolve(id) as PackedScene) \
			.instantiate() as Node3D
		_tree().root.add_child(visual)
		await _settle(2)
		var skinned: int = 0
		for node: Node in visual.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			if mesh.skin != null:
				skinned += 1
				check(mesh.get_node_or_null(mesh.skeleton) is Skeleton3D,
					"%s/%s : maillage skinné LIÉ au squelette"
					% [String(id), mesh.name])
		counts[id] = skinned
		if id == &"char.raider_blue":
			check(not visual.find_children("*Pauldron*", "MeshInstance3D",
				true, false).is_empty(), "azur : épaulière greffée")
			check(not visual.find_children("*Boots*", "MeshInstance3D",
				true, false).is_empty(), "azur : bottes greffées")
		if id == &"char.raider_black":
			check(not visual.find_children("*Head_Hood*", "MeshInstance3D",
				true, false).is_empty(), "obsidienne : capuche greffée")
			# §12.3 « silhouette LARGE, centre de gravité BAS » : des
			# proportions NON uniformes. Le facteur uniforme d'origine
			# donnait un pillard simplement PLUS GRAND — corrigé après
			# la revue contradictoire du Gate D.
			var model_scale: Vector3 = (visual.get_node("Model") as Node3D).scale
			check(model_scale.x > 1.1 and model_scale.z > 1.1,
				"obsidienne : plus LARGE (%.2f)" % model_scale.x)
			check(model_scale.y < 1.0,
				"…et plus BASSE (%.2f) — jamais un simple agrandissement"
				% model_scale.y)
		visual.queue_free()
		await _settle(1)
	check(counts[&"char.raider_blue"] == counts[&"char.raider_red"] + 2,
		"azur = braise + 2 pièces (%d vs %d)"
		% [counts[&"char.raider_blue"], counts[&"char.raider_red"]])
	check(counts[&"char.raider_black"] == counts[&"char.raider_red"] + 2,
		"obsidienne = braise + 2 pièces (%d vs %d)"
		% [counts[&"char.raider_black"], counts[&"char.raider_red"]])
	# Héros : la capuche est re-teinte DANS la texture dérivée committée.
	var hero: Node3D = (AssetRegistry.resolve(&"char.hero") as PackedScene) \
		.instantiate() as Node3D
	_tree().root.add_child(hero)
	await _settle(2)
	var substituted: bool = false
	for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		for surface: int in range(mesh.mesh.get_surface_count()
				if mesh.mesh != null else 0):
			var override: BaseMaterial3D = mesh \
				.get_surface_override_material(surface) as BaseMaterial3D
			if override != null and override.albedo_texture != null \
					and override.albedo_texture.resource_path \
					.ends_with("T_Ranger_Hero_BaseColor.png"):
				substituted = true
	check(substituted, "héros : texture dérivée (capuche turquoise) montée")
	hero.queue_free()
	await _settle(1)


func test_the_silhouette_lineup_mounts_the_four_characters() -> void:
	## §7.18 : la bibliothèque de silhouettes monte les QUATRE personnages
	## — c'est la scène du jugement en aplats, elle ne peut pas être vide.
	var lineup: SilhouetteLineup = (load("res://scenes/tests/SilhouetteLineup.tscn")
		as PackedScene).instantiate() as SilhouetteLineup
	_tree().root.add_child(lineup)
	await _settle(2)
	check_equal(lineup.mounted_characters, 4, "les quatre personnages montés")
	lineup.queue_free()
	await _settle(1)


func test_the_gallery_mounts_a_full_page_without_losses() -> void:
	## V4 lot 3 (§8) : une page de galerie monte ses 12 modèles — une erreur
	## d'asset serait un jalon orange consigné, jamais une perte silencieuse.
	OS.set_environment("GALLERY_CATEGORY", "Props")
	OS.set_environment("GALLERY_PAGE", "0")
	var gallery: AssetGallery = (load("res://scenes/tests/AssetGallery.tscn")
		as PackedScene).instantiate() as AssetGallery
	_tree().root.add_child(gallery)
	await _settle(2)
	check_equal(gallery.page_entries, 12, "page pleine : 12 entrées")
	check_equal(gallery.mounted_models, 12, "12 modèles réellement montés")
	check_equal(gallery.failed_models, 0, "aucun échec de chargement")
	OS.set_environment("GALLERY_CATEGORY", "")
	OS.set_environment("GALLERY_PAGE", "")
	gallery.get_parent().remove_child(gallery)
	gallery.queue_free()
	await _settle(2)
