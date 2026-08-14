## SONDE D'ASSISE DES MODULES DE KIT — mesurer un module AVANT d'assembler.
##
## Pourquoi elle existe. Le lead a rejeté trois passes d'assemblages
## procéduraux et exige désormais « des modules CC0 existants correctement
## assemblés ». Correctement assembler suppose de connaître trois choses
## qu'aucun document ne donne : le facteur appliqué par `KitScale`,
## l'offset appliqué par `KitPlacement.seat()`, et surtout **où se trouve
## l'origine du modèle dans son emprise**. Un mur dont le pivot est au
## coin ne se pose pas comme un mur dont le pivot est au centre — et
## l'erreur ne se voit pas sur un plan, elle se voit en jointure.
##
## C'est la mesure qui manquait quand le propriétaire a écrit « les murs
## sont pas fermés » et qu'on a trouvé 117 défauts d'assemblage.
##
## La sonde instancie chaque module EXACTEMENT comme `WorldV2PlaceKit.module()`
## le fait — même facteur, même assise — puis rend son emprise réelle.
##
## Usage :
##   godot --headless --path . --script tools/godot/probe_kit_seating.gd -- \
##       --modules=Wall_Plaster_Straight,Roof_RoundTiles_4x4
##   godot --headless --path . --script tools/godot/probe_kit_seating.gd -- \
##       --famille=murs
##
## Sans `--modules` ni `--famille`, la sonde balaie les familles utiles aux
## quatre golden masters de V2.3-A.R2a.
extends SceneTree

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## Les familles qui servent aux quatre références. Chaque nom a été relevé
## dans `assets/environment/**` — un nom introuvable fait sortir en 3, il
## n'est jamais avalé en silence.
const FAMILLES: Dictionary = {
	"murs": [
		&"Wall_Plaster_Straight", &"Wall_Plaster_Straight_L",
		&"Wall_Plaster_Straight_R", &"Wall_UnevenBrick_Straight",
		&"Wall_Plaster_Door_Round", &"Wall_UnevenBrick_Door_Round",
		&"Wall_Plaster_Window_Wide_Round",
		&"Wall_UnevenBrick_Window_Wide_Round", &"Wall_Arch",
		&"Wall_BottomCover",
	],
	"coins": [
		&"Corner_Exterior_Brick", &"Corner_ExteriorWide_Brick",
		&"Corner_Exterior_Wood",
	],
	"toits": [
		&"Roof_RoundTiles_4x4", &"Roof_RoundTiles_6x6",
		&"Roof_RoundTiles_8x8", &"Roof_RoundTiles_6x10",
		&"Roof_Front_Brick4", &"Roof_Front_Brick6",
		&"Overhang_Roof_Plaster", &"Overhang_Plaster_Short",
	],
	"sols": [
		&"Floor_Brick", &"Floor_UnevenBrick", &"Floor_WoodLight",
		&"Floor_WoodDark",
	],
	"ouvertures": [
		&"Door_2_Round", &"Door_4_Round", &"DoorFrame_Round_WoodDark",
		&"Window_Wide_Round1", &"WindowShutters_Wide_Round_Open",
	],
	"escaliers": [
		&"Stairs_Exterior_Straight", &"Stairs_Exterior_Straight_L",
		&"Stairs_Exterior_Platform",
	],
	"grotte": [
		&"SM_Dungeon_CaveWall", &"SM_Dungeon_CaveWallHalf",
		&"SM_Dungeon_CaveWallTop", &"SM_Dungeon_CaveArch",
		&"SM_Dungeon_CaveRock",
	],
	"pont": [
		&"SM_Dungeon_ArchBlock", &"SM_Dungeon_PillarStub",
		&"SM_Dungeon_RubbleLarge", &"SM_Dungeon_RubbleSmall",
		&"RockPath_Square_Wide",
	],
	"appuis": [
		&"Prop_Support", &"Roof_Support2", &"Prop_Chimney",
		&"Balcony_Simple_Straight", &"Prop_WoodenFence_Single",
	],
}


func _initialize() -> void:
	var demandes: Array[StringName] = []
	var titre: String = "familles utiles aux quatre golden masters"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--modules="):
			titre = "modules demandés"
			for nom: String in argument.substr(10).split(",", false):
				demandes.append(StringName(nom.strip_edges()))
		elif argument.begins_with("--famille="):
			var famille: String = argument.substr(10).strip_edges()
			if not FAMILLES.has(famille):
				printerr("[assise] BLOQUÉ : famille inconnue « %s » — connues : %s"
					% [famille, ", ".join(FAMILLES.keys())])
				quit(3)
				return
			titre = "famille " + famille
			for nom: Variant in FAMILLES[famille] as Array:
				demandes.append(nom as StringName)
	if demandes.is_empty():
		for famille: Variant in FAMILLES.keys():
			for nom: Variant in FAMILLES[famille] as Array:
				demandes.append(nom as StringName)

	var hote: Node3D = Node3D.new()
	root.add_child(hote)
	await process_frame

	print("[assise] %s — %d module(s)" % [titre, demandes.size()])
	print("[assise] emprise et pivot MESURÉS après KitScale.factor() puis")
	print("[assise] KitPlacement.seat(), exactement comme WorldV2PlaceKit.module()")
	print("")
	print("%-38s %6s %7s  %-22s  %-24s  %s"
		% ["module", "facteur", "assise", "emprise L×H×P (m)",
			"pivot dans l'emprise", "surfaces"])
	var manquants: Array[String] = []
	for nom: StringName in demandes:
		var ligne: Dictionary = _mesurer(hote, nom)
		if ligne.is_empty():
			manquants.append(String(nom))
			print("%-38s %6s %7s  %s" % [nom, "—", "—", "INTROUVABLE"])
			continue
		print("%-38s %6.3f %7.3f  %6.2f × %5.2f × %5.2f  %-24s  %d"
			% [nom, float(ligne["facteur"]), float(ligne["assise"]),
				(ligne["taille"] as Vector3).x, (ligne["taille"] as Vector3).y,
				(ligne["taille"] as Vector3).z, ligne["pivot"], int(ligne["surfaces"])])
	print("")
	if manquants.is_empty():
		print("[assise] tous les modules demandés existent.")
		quit(0)
		return
	# Un nom introuvable n'est PAS un détail : c'est un assemblage qui se
	# construira avec un trou, sans que rien ne rougisse en jeu.
	printerr("[assise] BLOQUÉ : %d module(s) INTROUVABLE(S) — %s"
		% [manquants.size(), ", ".join(manquants)])
	quit(3)


## Instancie le module comme le fait le kit, puis rend son emprise réelle.
func _mesurer(hote: Node3D, nom: StringName) -> Dictionary:
	var packed: PackedScene = K.scene_for(nom)
	if packed == null:
		return {}
	var noeud: Node3D = packed.instantiate() as Node3D
	if noeud == null:
		return {}
	noeud.name = String(nom)
	var facteur: float = KitScale.factor(String(nom))
	noeud.scale = Vector3.ONE * facteur
	noeud.position = Vector3.ZERO
	hote.add_child(noeud)
	var assise: float = KitPlacement.seat(noeud, String(nom))

	var boite: AABB = _emprise(noeud)
	var surfaces: int = 0
	for enfant: Node in noeud.find_children("*", "MeshInstance3D", true, false):
		var maillage: Mesh = (enfant as MeshInstance3D).mesh
		if maillage != null:
			surfaces += maillage.get_surface_count()

	# Le pivot : où tombe l'origine du nœud DANS son emprise. C'est la
	# donnée qui décide si deux pièces jointent ou laissent un trou.
	var pivot: String = "%s / %s / %s" % [
		_position_relative(boite.position.x, boite.size.x),
		_position_relative(boite.position.y, boite.size.y),
		_position_relative(boite.position.z, boite.size.z)]

	noeud.queue_free()
	return {
		"facteur": facteur, "assise": assise, "taille": boite.size,
		"pivot": pivot, "surfaces": surfaces,
	}


## Emprise du sous-arbre dans l'espace du nœud lui-même.
func _emprise(racine: Node3D) -> AABB:
	var boite: AABB = AABB()
	var premier: bool = true
	for noeud: Node in racine.find_children("*", "VisualInstance3D", true, false):
		var visuel: VisualInstance3D = noeud as VisualInstance3D
		if visuel == null:
			continue
		var locale: AABB = visuel.get_aabb()
		var relative: Transform3D = racine.global_transform.affine_inverse() \
			* visuel.global_transform
		var monde: AABB = relative * locale
		if premier:
			boite = monde
			premier = false
		else:
			boite = boite.merge(monde)
	return boite


## « bas », « centre », « haut » — lu depuis la position du minimum.
func _position_relative(minimum: float, taille: float) -> String:
	if taille <= 0.001:
		return "plat"
	var part: float = -minimum / taille
	if part < 0.15:
		return "min"
	if part > 0.85:
		return "max"
	if absf(part - 0.5) < 0.12:
		return "centre"
	return "%.2f" % part
