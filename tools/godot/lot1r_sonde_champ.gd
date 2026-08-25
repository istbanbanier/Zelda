## SONDE DU CHAMP DES MILLE FLEURS (lot 1.R, voie C) — le compte d'instances.
##
## POURQUOI ELLE EXISTE. Le budget D7 compte des NŒUDS visuels, et un
## `MultiMeshInstance3D` en vaut un, qu'il porte trois fleurs ou trois mille.
## Le nœud est donc un budget de scène, pas un budget de densité : densifier
## une nappe est GRATUIT au regard de D7. Publier le nombre d'instances est
## la seule façon de rendre cette densité visible à une revue — sans quoi le
## champ pourrait grossir indéfiniment sans qu'aucun chiffre ne bouge.
##
## L'EMPRISE SE CALCULE CÔTÉ CPU. `MultiMesh.get_aabb()` rend (0,0,0) sous le
## renderer factice : l'AABB d'un MultiMesh est entretenue par le serveur de
## rendu, pas par la ressource. Une sonde qui la lirait annoncerait « lieu
## vide » sans une erreur. On somme donc les `instance_origins` posées en méta
## par le lieu — les mêmes que le plan de plantation.
##
## Usage :
##   tools/lancer_godot.sh --headless --path . \
##     --script tools/godot/lot1r_sonde_champ.gd
extends SceneTree

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const SUJET: StringName = &"valley.poi.flower_field.01"
## Plafonds « micro » du contrat (docs/V2_3_B_LOT1_CONTROLES.md §2).
const BUDGET_MODULES: int = 12
const BUDGET_VISUELS: int = 30
const BUDGET_COLLISIONS: int = 6


func _initialize() -> void:
	var monde: Node3D = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(monde)
	for i: int in range(45):
		await process_frame

	var lieu: Node3D = null
	for noeud: Node in root.get_tree().get_nodes_in_group(&"world_v2_places"):
		if (noeud.get_meta(&"place_id", &"?") as StringName) == SUJET:
			lieu = noeud as Node3D
			break
	if lieu == null:
		print("BLOQUÉ : %s absent du monde monté — rien à compter." % SUJET)
		quit(3)
		return

	print("CHAMP DES MILLE FLEURS — instances par nœud visuel")
	print("%-26s %10s %10s %8s" % ["nœud", "instances", "aire_xz", "h_moy"])
	var total: int = 0
	var min_x: float = INF
	var max_x: float = -INF
	var min_z: float = INF
	var max_z: float = -INF
	for noeud: Node in lieu.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi: MultiMeshInstance3D = noeud as MultiMeshInstance3D
		if mmi.multimesh == null:
			continue
		var n: int = mmi.multimesh.instance_count
		total += n
		var origines: PackedVector3Array = mmi.get_meta(&"instance_origins",
			PackedVector3Array()) as PackedVector3Array
		var echelles: PackedFloat32Array = mmi.get_meta(&"instance_scales",
			PackedFloat32Array()) as PackedFloat32Array
		var lx: float = INF
		var hx: float = -INF
		var lz: float = INF
		var hz: float = -INF
		for p: Vector3 in origines:
			lx = minf(lx, p.x)
			hx = maxf(hx, p.x)
			lz = minf(lz, p.z)
			hz = maxf(hz, p.z)
		min_x = minf(min_x, lx)
		max_x = maxf(max_x, hx)
		min_z = minf(min_z, lz)
		max_z = maxf(max_z, hz)
		var moyenne: float = 0.0
		for e: float in echelles:
			moyenne += e
		if echelles.size() > 0:
			moyenne /= float(echelles.size())
		var hauteur_m: float = 0.0
		if mmi.multimesh.mesh != null:
			hauteur_m = mmi.multimesh.mesh.get_aabb().size.y * moyenne
		print("%-26s %10d %10.1f %8.2f" % [mmi.name, n,
			maxf(hx - lx, 0.0) * maxf(hz - lz, 0.0), hauteur_m])
	print("")
	print("TOTAL INSTANCES MULTIMESH : %d" % total)
	print("EMPRISE DES INSTANCES     : %.1f x %.1f m (local)"
		% [max_x - min_x, max_z - min_z])

	var modules: int = 0
	for noeud: Node in lieu.find_children("*", "Node", true, false):
		if _sous_ancrage(noeud, lieu):
			continue
		if not noeud.scene_file_path.is_empty():
			modules += 1
	for noeud: Node in lieu.find_children("*", "MeshInstance3D", true, false):
		if _sous_ancrage(noeud, lieu):
			continue
		var mi: MeshInstance3D = noeud as MeshInstance3D
		if mi.mesh != null and mi.mesh.resource_path.is_empty():
			modules += 1
	var visuels: int = lieu.find_children("*", "VisualInstance3D",
		true, false).size()
	var collisions: int = lieu.find_children("*", "CollisionShape3D",
		true, false).size()
	print("")
	print("BUDGET micro (D7) : modules %d/%d %s · visuels %d/%d %s · collisions %d/%d %s"
		% [modules, BUDGET_MODULES, "!" if modules > BUDGET_MODULES else "ok",
			visuels, BUDGET_VISUELS, "!" if visuels > BUDGET_VISUELS else "ok",
			collisions, BUDGET_COLLISIONS,
			"!" if collisions > BUDGET_COLLISIONS else "ok"])
	quit(0)


## Vrai si le nœud vit sous un `RewardAnchor` — même amendement que la sonde
## de budget : la machinerie de contrat n'est pas une pièce de composition.
func _sous_ancrage(noeud: Node, lieu: Node3D) -> bool:
	var courant: Node = noeud
	while courant != null and courant != lieu:
		if courant is RewardAnchor:
			return true
		courant = courant.get_parent()
	return false
