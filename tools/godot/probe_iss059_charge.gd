## Sonde ISS-059 — la signature de fuite dépend-elle du seul CHARGEMENT
## des ressources, sans aucun montage ni test ?
##
## Pourquoi elle existe : quatre lots isolés (`boss_arena`, `world_v2`,
## `boot_smoke`, `unit`) sortent propres, et neuf montages de `ValleyWorld`
## dans un seul processus sortent propres aussi (mesuré le 2026-08-20,
## `evidence/world_v2/v2_3_r2b3/iss059/bissection/E_dress9.log`). La fuite de
## la suite complète est donc CUMULATIVE, pas dosée par montage. Cette sonde
## teste l'hypothèse la moins chère qui reste : le multiplicateur n'est pas le
## montage, c'est le NOMBRE DE RESSOURCES DISTINCTES chargées dans le
## processus.
##
## Usage :
##   godot --headless --path . --script tools/godot/probe_iss059_charge.gd -- --mode=aucun
##   godot --headless --path . --script tools/godot/probe_iss059_charge.gd -- --mode=scenes
##   godot --headless --path . --script tools/godot/probe_iss059_charge.gd -- --mode=scenes --limite=40
##
## `--mode=aucun` est le TÉMOIN : même processus, mêmes autoloads, zéro
## chargement. Un compte n'a de sens que par son écart avec lui.
extends SceneTree

const RACINES: Array[String] = ["res://scenes", "res://assets"]


func _initialize() -> void:
	var mode: String = _arg("--mode=", "aucun")
	var limite: int = int(_arg("--limite=", "0"))
	var garder: bool = _arg("--garder=", "non") == "oui"
	print("=== SONDE ISS-059 — mode=%s limite=%d garder=%s ===" % [mode, limite, garder])
	_install_autoloads()
	await process_frame

	var chemins: Array[String] = []
	if mode != "aucun":
		for racine: String in RACINES:
			_collecte(racine, chemins, mode)
		chemins.sort()
	if limite > 0 and chemins.size() > limite:
		chemins.resize(limite)

	var instancier: bool = _arg("--instancie=", "non") == "oui"
	var gardees: Array[Resource] = []
	var charges: int = 0
	var echecs: int = 0
	var montes: int = 0
	for chemin: String in chemins:
		var res: Resource = ResourceLoader.load(chemin)
		if res == null:
			echecs += 1
			continue
		charges += 1
		if garder:
			gardees.append(res)
		if instancier:
			var paquet: PackedScene = res as PackedScene
			if paquet != null and paquet.can_instantiate():
				var noeud: Node = paquet.instantiate()
				if noeud != null:
					root.add_child(noeud)
					montes += 1
					await process_frame
					root.remove_child(noeud)
					noeud.queue_free()
					await process_frame
	print("chemins=%d chargés=%d échecs=%d gardés=%d montés=%d"
		% [chemins.size(), charges, echecs, gardees.size(), montes])
	gardees.clear()
	print("objets vivants avant sortie : %d"
		% int(Performance.get_monitor(Performance.OBJECT_COUNT)))
	print("=== SONDE TERMINÉE ===")
	quit(0)


func _arg(prefixe: String, defaut: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefixe):
			return arg.trim_prefix(prefixe)
	return defaut


func _collecte(chemin_dossier: String, sortie: Array[String], mode: String) -> void:
	var dir: DirAccess = DirAccess.open(chemin_dossier)
	if dir == null:
		return
	dir.list_dir_begin()
	var entree: String = dir.get_next()
	while entree != "":
		var complet: String = chemin_dossier.path_join(entree)
		if dir.current_is_dir():
			if not entree.begins_with("."):
				_collecte(complet, sortie, mode)
		else:
			if mode == "scenes" and entree.ends_with(".tscn"):
				sortie.append(complet)
			elif mode == "glb" and entree.ends_with(".glb"):
				sortie.append(complet)
			elif mode == "tout" and (entree.ends_with(".tscn") or entree.ends_with(".glb")):
				sortie.append(complet)
		entree = dir.get_next()
	dir.list_dir_end()


## Copie fidèle de `tools/godot/test_runner.gd` : un `--script` remplace la
## `SceneTree` par défaut et Godot n'y installe PAS les autoloads. Sans eux le
## témoin ne serait pas comparable au runner.
func _install_autoloads() -> void:
	var installed: Array[String] = []
	for setting: Dictionary in ProjectSettings.get_property_list():
		var key: String = String(setting.get("name", ""))
		if not key.begins_with("autoload/"):
			continue
		var autoload_name: String = key.trim_prefix("autoload/")
		var value: String = String(ProjectSettings.get_setting(key, ""))
		if value == "":
			continue
		if not value.begins_with("*"):
			continue
		var path: String = value.substr(1)
		if root.has_node(NodePath(autoload_name)):
			continue
		var script: Script = load(path) as Script
		if script == null or not script.can_instantiate():
			continue
		var node: Node = script.new() as Node
		if node == null:
			continue
		node.name = autoload_name
		root.add_child(node)
		installed.append(autoload_name)
	if not installed.is_empty():
		print("autoloads installés: %s" % ", ".join(installed))
