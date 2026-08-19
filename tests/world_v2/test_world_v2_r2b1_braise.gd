## V2.3-A.R2B.1 — LE BUDGET DE COMPLEXITÉ DU CAMP BRAISE.
##
## Ce contrôle rend EXÉCUTABLE le plafond de `docs/WORLD_V2_POI_CONTRACTS.md`
## §4, qui n'existait jusqu'ici qu'en prose : un camp (checkpoint ou
## territoire) tient en ≤ 45 modules de kit, ≤ 90 nœuds visuels et
## ≤ 24 collisions. Personne ne le vérifiait ; le camp braise a dérivé à
## 54 modules sans que rien ne rougisse.
##
## Écrit ROUGE D'ABORD (2026-08-19, R2B.1) : au moment de l'écriture, la
## sonde `tools/godot/probe_ember_modules.gd` mesure 54 modules montés,
## dont 53 posés par le bâtisseur — soit 9 de trop.
##
## CANDIDAT À GÉNÉRALISATION : le même plafond borne le camp-checkpoint
## (34 modules mesurés, DANS le plafond) et bornera les autres camps. Ce
## fichier est écrit pour qu'on y ajoute un lieu par constante, pas pour
## rester une curiosité de passe.
##
## POURQUOI UN FICHIER À PART. `test_world_v2_r2b_camps.gd` porte les cinq
## contrôles du camp-checkpoint, GELÉ. On ne touche pas un filet gelé pour
## y loger un contrôle neuf.
##
## DEUX RÈGLES DURABLES, nées d'une erreur payée le 2026-08-19 :
##
##  1. LE PLAFOND EST INCLUSIF : 45 PASSE, 46 ROUGIT. Établi par sabotage à
##     deux pas, pas par raisonnement — remettre un module coupé (45/45)
##     laisse le contrôle VERT, en remettre un second (46/45) le fait
##     ROUGIR. Les deux journaux vivent dans
##     `evidence/world_v2/v2_3_r2b1/braise/sabotage/`.
##  2. LE COMPTE DE RÉFÉRENCE EST CELUI DU BÂTISSEUR, coffre de récompense
##     exempté PAR SON NOM. Un sabotage à un seul pas avait d'abord été
##     prévu « 46 → doit rougir » : il comptait le coffre qu'on venait
##     d'exempter, le contrôle serait resté vert, et ce vert aurait été
##     pris pour une preuve. Un plafond ne se vérifie qu'en le franchissant
##     avec le compte qui fait foi.
##
## ┌──────────────────────────────────────────────────────────────────────┐
## │ LE CAMP BRAISE EST À 45/45. MARGE NULLE. AUCUNE PLACE.                │
## │                                                                      │
## │ Ajouter UN SEUL module au camp braise fera rougir ce contrôle. Ce    │
## │ n'est pas un accident : neuf modules ont été coupés le 2026-08-19,   │
## │ puis le poteau de palissade 280° a été REMIS sur arbitrage du lead — │
## │ l'A/B l'avait montré visible (3 535 px, 0,384 % du cadre au plan     │
## │ `braise_guet`). Le lead a refusé d'échanger cette place contre une   │
## │ dixième coupe, qui aurait été plus voyante que ce qu'elle rachetait. │
## │                                                                      │
## │ Pour ajouter quelque chose ici : il faut d'abord en retirer autre    │
## │ chose, et le justifier par une emprise écran MESURÉE                 │
## │ (tools/godot/probe_ember_modules.gd), pas au jugé.                   │
## └──────────────────────────────────────────────────────────────────────┘
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const EMBER_ID: StringName = &"valley.poi.ember_raider_camps.01"

## Plafonds du contrat §4 pour un camp. Ce ne sont PAS des objectifs :
## descendre en dessous est libre, les dépasser est un échec.
const CAMP_MODULE_CEILING: int = 45
const CAMP_VISUAL_CEILING: int = 90
const CAMP_COLLIDER_CEILING: int = 24

var _world: Node3D = null


## LE BUDGET DU CAMP BRAISE — trois plafonds, deux comptes publiés.
##
## Le compte qui fait foi est celui du BÂTISSEUR : le plafond §4 borne ce
## qu'un bâtisseur COMPOSE. Le total monté est publié à côté, jamais
## soustrait en silence — un nombre exempté qu'on ne voit plus est un
## nombre que personne ne vérifie plus.
func test_le_camp_braise_tient_son_budget_de_modules() -> void:
	await _mount()
	var faults: Array[String] = []
	var ember: Node3D = _place(EMBER_ID)
	if ember == null:
		faults.append("camp braise : lieu ABSENT")
	else:
		var built: Dictionary = _tally(ember, true)
		var mounted: Dictionary = _tally(ember, false)
		# Les deux comptes, toujours, même quand tout passe.
		print("[braise] bâtisseur %d modules / %d nœuds visuels / %d collisions"
			% [built["modules"], built["visuals"], built["bodies"]])
		print("[braise] total monté %d / %d / %d (écart = récompense sous RewardAnchor)"
			% [mounted["modules"], mounted["visuals"], mounted["bodies"]])
		# La valeur courante est affichée À CÔTÉ du plafond : la session
		# suivante doit lire « 44/45 » et savoir qu'elle n'a pas de place,
		# au lieu de le découvrir en rougissant.
		if int(built["modules"]) > CAMP_MODULE_CEILING:
			faults.append("%d/%d modules kit" % [built["modules"], CAMP_MODULE_CEILING])
		if int(built["visuals"]) > CAMP_VISUAL_CEILING:
			faults.append("%d/%d nœuds visuels" % [built["visuals"], CAMP_VISUAL_CEILING])
		if int(built["bodies"]) > CAMP_COLLIDER_CEILING:
			faults.append("%d/%d collisions" % [built["bodies"], CAMP_COLLIDER_CEILING])
		if faults.is_empty():
			print("[braise] budget §4 tenu : %d/%d modules, %d/%d visuels, %d/%d collisions"
				% [built["modules"], CAMP_MODULE_CEILING, built["visuals"],
					CAMP_VISUAL_CEILING, built["bodies"], CAMP_COLLIDER_CEILING])
	check(faults.is_empty(),
		"le camp braise tient le budget §4 (camp ≤ %d modules, ≤ %d visuels, ≤ %d collisions) — %s"
		% [CAMP_MODULE_CEILING, CAMP_VISUAL_CEILING, CAMP_COLLIDER_CEILING,
			" ; ".join(faults)])
	await _unmount()


## -- outillage ----------------------------------------------------------------

## Compte modules / nœuds visuels / collisions d'un lieu.
##
## `only_built` applique l'EXEMPTION NOMMÉE : tout ce qui pend sous une
## `RewardAnchor` est instancié à l'exécution par `chest.gd`
## (`AssetRegistry.resolve(&"prop.chest")` → `ChestModel.tscn` →
## `Chest_Wood.gltf`), donc HORS du contrôle du bâtisseur. Le compter
## ferait hériter aux 31 lieux un module qu'aucun d'eux ne peut retirer.
## Même forme que l'exemption `CampfireProp` du filet camps.
func _tally(place: Node3D, only_built: bool) -> Dictionary:
	var modules: int = 0
	var visuals: int = 0
	var bodies: int = 0
	for node: Node in place.find_children("*", "", true, false):
		if only_built and _under_reward_anchor(node, place):
			continue
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			visuals += 1
		if node is StaticBody3D:
			bodies += 1
		if node is Node3D and _is_module_root(node as Node3D, place):
			modules += 1
	return {"modules": modules, "visuals": visuals, "bodies": bodies}


## Racine de module : instance d'une scène de `res://assets/` qui n'est pas
## déjà contenue dans une autre (une pièce de kit n'en compte pas deux).
## Même règle que `_module_root_of` du filet camps.
func _is_module_root(node: Node3D, place: Node3D) -> bool:
	if not node.scene_file_path.begins_with("res://assets/"):
		return false
	var walker: Node = node.get_parent()
	while walker != null and walker != place:
		if walker.scene_file_path.begins_with("res://assets/"):
			return false
		walker = walker.get_parent()
	return true


func _under_reward_anchor(node: Node, place: Node3D) -> bool:
	var walker: Node = node
	while walker != null and walker != place:
		if walker is RewardAnchor:
			return true
		walker = walker.get_parent()
	return false


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
	check(clean, "démontage propre (budget braise r2b1) — %s" % restore_root_reason())
	restore_saves()


func _place(place_id: StringName) -> Node3D:
	for node: Node in _world.get_tree().get_nodes_in_group(&"world_v2_places"):
		if node.get_meta(&"place_id", &"") as StringName == place_id:
			return node as Node3D
	return null
