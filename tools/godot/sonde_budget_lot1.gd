## SONDE DE BUDGET du lot 1 (V2.3-B) — lue sur la SCÈNE MONTÉE, jamais sur le
## code qui prétend la produire.
##
## POURQUOI CETTE SONDE ET PAS `probe_place_metrics.gd`. La sonde existante
## compte les `StaticBody3D` et les appelle « colls ». Ce n'est pas la même
## chose qu'une collision : un corps unique peut porter trente
## `CollisionShape3D`, et un micro-POI au budget « 6 » passerait sans que rien
## ne bronche. Elle compte aussi les `MeshInstance3D` et les appelle
## « mesh » : un `MultiMeshInstance3D` — la forme attendue d'un champ de
## fleurs — lui est invisible, et elle annoncerait « 0 » sur le lieu le plus
## dense du lot. Les deux erreurs sont de la même famille qu'ISS-018 : mesurer
## une propriété qui n'est PAS celle qu'on veut garantir.
##
## Les trois compteurs sont définis dans `docs/V2_3_B_LOT1_CONTROLES.md` §2, et
## `tests/world_v2/test_world_v2_lot1_defauts.gd` (D7) les recompte à
## l'identique. Cette sonde SERT LE RAPPORT ; le filet sert le verdict.
##
## MODE `--calibrer` : rend la part d'aire RUNTIME de chaque lieu du CORPUS
## ACCEPTÉ, et son maximum — la valeur que la règle D1a du plan de contrôles
## désigne comme plafond du lot 1. C'est une calibration sur des sujets déjà
## validés par le lead, faite avant que le premier lieu du lot n'existe : elle
## ne peut donc pas être ajustée par ce qu'elle doit juger.
##
## Usage :
##   tools/lancer_godot.sh --headless --path . \
##     --script tools/godot/sonde_budget_lot1.gd -- [--calibrer]
extends SceneTree

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"

const LOT1: Array[StringName] = [
	&"valley.poi.watchtower_ruin.01",
	&"valley.poi.overlook_summit.01",
	&"valley.poi.turquoise_spring.01",
	&"valley.poi.forest_shrine.01",
	&"valley.poi.barrow_cemetery.01",
	&"valley.poi.flower_field.01",
]
const CORPUS_ACCEPTE: Array[StringName] = [
	&"camp",
	&"valley.poi.riverside_village.01",
	&"valley.poi.abandoned_farm.01",
	&"valley.poi.stone_bridge.01",
	&"valley.poi.waterfall_cave.01",
	&"valley.poi.thunderstruck_tree.01",
	&"valley.poi.ember_raider_camps.01",
	&"valley.poi.conductive_basin.01",
	&"pylon",
]
const FAMILLE: Dictionary = {
	&"valley.poi.watchtower_ruin.01": "ruine",
	&"valley.poi.forest_shrine.01": "vestige",
	&"valley.poi.barrow_cemetery.01": "vestige",
	&"valley.poi.overlook_summit.01": "micro",
	&"valley.poi.turquoise_spring.01": "micro",
	&"valley.poi.flower_field.01": "micro",
}
const BUDGET: Dictionary = {
	"micro": [12, 30, 6],
	"ruine": [40, 80, 20],
	"vestige": [40, 80, 20],
}

var _calibrer: bool = false


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--calibrer":
			_calibrer = true
	var monde: Node3D = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(monde)
	for i: int in range(45):
		await process_frame

	var lieux: Dictionary = {}
	for noeud: Node in root.get_tree().get_nodes_in_group(&"world_v2_places"):
		lieux[noeud.get_meta(&"place_id", &"?") as StringName] = noeud as Node3D

	if _calibrer:
		_calibration(lieux)
		quit(0)
		return

	print("BUDGET DES LIEUX — scène montée. Définitions : "
		+ "docs/V2_3_B_LOT1_CONTROLES.md §2")
	print("  module    = nœud à scene_file_path + maillage runtime (mesh sans resource_path)")
	print("  visuel    = VisualInstance3D (MultiMesh COMPRIS)")
	print("  collision = CollisionShape3D (la FORME, pas le corps)")
	print("")
	print("%-38s %-8s %9s %9s %11s %9s" % ["lieu", "famille", "modules",
		"visuels", "collisions", "runtime%"])
	var manquants: Array[String] = []
	for id: StringName in LOT1:
		if not lieux.has(id):
			manquants.append(String(id))
			continue
		_ligne(id, lieux[id] as Node3D, String(FAMILLE[id]))
	print("")
	for id: StringName in CORPUS_ACCEPTE:
		if lieux.has(id):
			_ligne(id, lieux[id] as Node3D, "(accepté)")
	if not manquants.is_empty():
		print("")
		print("ABSENTS DU MONDE MONTÉ (%d) : %s"
			% [manquants.size(), ", ".join(manquants)])
		print("Un budget qu'on ne peut pas compter n'est pas un budget tenu :")
		print("ces lieux restent NON VÉRIFIÉS, jamais « dans le budget ».")
	quit(0)


func _ligne(id: StringName, lieu: Node3D, famille: String) -> void:
	var compte: Dictionary = _compter(lieu)
	var marques: Array[String] = ["", "", ""]
	if BUDGET.has(famille):
		var plafonds: Array = BUDGET[famille] as Array
		marques[0] = "!" if int(compte["modules"]) > int(plafonds[0]) else ""
		marques[1] = "!" if int(compte["visuels"]) > int(plafonds[1]) else ""
		marques[2] = "!" if int(compte["collisions"]) > int(plafonds[2]) else ""
	print("%-38s %-8s %8d%s %8d%s %10d%s %8.1f%%"
		% [id, famille, int(compte["modules"]), marques[0],
			int(compte["visuels"]), marques[1],
			int(compte["collisions"]), marques[2],
			float(compte["runtime_pct"])])


func _calibration(lieux: Dictionary) -> void:
	print("CALIBRATION D1a — part d'aire RUNTIME du CORPUS ACCEPTÉ.")
	print("Règle : le plafond du lot 1 est le MAXIMUM observé ici. Mesuré sur")
	print("des lieux déjà validés par le lead, avant que le lot 1 n'existe.")
	print("")
	var maxi: float = -1.0
	var porteur: String = "—"
	var vus: int = 0
	for id: StringName in CORPUS_ACCEPTE:
		if not lieux.has(id):
			print("%-38s ABSENT" % id)
			continue
		vus += 1
		var compte: Dictionary = _compter(lieux[id] as Node3D)
		var pct: float = float(compte["runtime_pct"])
		print("%-38s aire runtime %6.2f %%  (aire totale %9.1f m²)"
			% [id, pct, float(compte["aire_totale"])])
		if pct > maxi:
			maxi = pct
			porteur = String(id)
	print("")
	if vus < 6:
		print("BLOQUÉ : %d sujet(s) accepté(s) mesuré(s), 6 exigés." % vus)
		print("Sous ce compte, max() n'est pas une statistique.")
		return
	print("MAXIMUM = %.2f %% (%s) sur %d sujets acceptés." % [maxi, porteur, vus])
	var propose: float = ceilf(maxi * 10.0) / 10.0
	print("Inscrire AIRE_RUNTIME_PLAFOND_PCT = %.1f dans" % propose)
	print("tests/world_v2/test_world_v2_lot1_defauts.gd, avec ce journal daté")
	print("en commentaire. Ne PAS arrondir vers le haut au-delà du dixième :")
	print("un plafond desserré « pour la marge » est un plafond qui ne tient rien.")


func _compter(lieu: Node3D) -> Dictionary:
	var modules: int = 0
	for noeud: Node in lieu.find_children("*", "Node", true, false):
		if not noeud.scene_file_path.is_empty():
			modules += 1
	var aire_totale: float = 0.0
	var aire_runtime: float = 0.0
	var exemptions: Array[String] = []
	# `has_meta` D'ABORD. Mesuré : `get_meta(nom, null)` déclenche quand même
	# l'erreur « does not have meta » — un défaut `null` est traité comme
	# l'absence de défaut par le binding. Le garde explicite est le seul sûr.
	var meta: Variant = null
	if lieu.has_meta(&"exemption_runtime"):
		meta = lieu.get_meta(&"exemption_runtime")
	if meta is PackedStringArray:
		for nom: String in meta as PackedStringArray:
			exemptions.append(nom)
	for noeud: Node in lieu.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = noeud as MeshInstance3D
		if instance.mesh == null:
			continue
		var aire: float = _aire(instance)
		aire_totale += aire
		if instance.mesh.resource_path.is_empty():
			modules += 1
			if not exemptions.has(String(instance.name)):
				aire_runtime += aire
	var visuels: int = lieu.find_children("*", "VisualInstance3D", true, false).size()
	var collisions: int = lieu.find_children("*", "CollisionShape3D", true, false).size()
	var pct: float = 0.0
	if aire_totale > 0.0:
		pct = 100.0 * aire_runtime / aire_totale
	return {"modules": modules, "visuels": visuels, "collisions": collisions,
		"aire_totale": aire_totale, "runtime_pct": pct}


## Type de primitive d'une surface, sûr pour TOUT `Mesh` — même piège que le
## filet D : `surface_get_primitive_type` n'existe que sur `ArrayMesh`, et un
## `PrimitiveMesh` produit toujours des triangles par définition.
func _primitive_de(mesh: Mesh, s: int) -> int:
	var tableau: ArrayMesh = mesh as ArrayMesh
	if tableau != null:
		return tableau.surface_get_primitive_type(s)
	return Mesh.PRIMITIVE_TRIANGLES


## Aire MONDE : l'aire est ce qu'on voit, donc elle se mesure après la
## transformation, pas dans le repère local du maillage.
func _aire(instance: MeshInstance3D) -> float:
	var base: Basis = instance.global_transform.basis
	var total: float = 0.0
	for s: int in range(instance.mesh.get_surface_count()):
		if _primitive_de(instance.mesh, s) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays: Array = instance.mesh.surface_get_arrays(s)
		var sommets: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var brut: Variant = arrays[Mesh.ARRAY_INDEX]
		var index: PackedInt32Array = PackedInt32Array()
		if brut != null:
			index = brut as PackedInt32Array
		var indirect: bool = index.size() > 0
		var n: int = index.size() if indirect else sommets.size()
		var i: int = 0
		while i + 2 < n:
			var ia: int = index[i] if indirect else i
			var ib: int = index[i + 1] if indirect else i + 1
			var ic: int = index[i + 2] if indirect else i + 2
			var a: Vector3 = base * sommets[ia]
			var b: Vector3 = base * sommets[ib]
			var c: Vector3 = base * sommets[ic]
			total += (b - a).cross(c - a).length() * 0.5
			i += 3
	return total
