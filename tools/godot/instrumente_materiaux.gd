## ISS-059 — INSTRUMENTATION DES MATÉRIAUX ET DES CACHES STATIQUES.
##
## Pourquoi cet outil existe. `validate_fast.sh` sort ROUGE sur la seule
## signature de fin de processus (`ObjectDB instances were leaked`,
## `resources still in use`, RID `DummyMaterial`). Entre R2B.1 et R2B.2 le
## compte a bougé de +100 sur `DummyMaterial` ET sur ObjectDB — le même objet
## compté deux fois — pendant que `DummyShader`, `DummyMesh`, `DummyTexture` et
## `resources still in use` restaient IDENTIQUES au chiffre près.
##
## L'explication avancée alors — « la ferme duplique un matériau par surface,
## +100 c'est du contenu » — a été REFUSÉE par l'audit indépendant faute
## d'instrumentation. ISS-059 porte donc : le +100 est NON EXPLIQUÉ.
##
## Cet outil ne cherche pas à rendre l'explication plausible. Il cherche à la
## rendre DÉCIDABLE, en distinguant quatre choses que « ça fuit » confond :
##
##   1. allocation attendue et bornée — on sait combien, et pourquoi ;
##   2. cache stable — il ne croît pas au second cycle ;
##   3. ressource survivante — elle existe encore après démontage ;
##   4. croissance cumulative à chaque cycle — ÇA, et seulement ça, est une fuite.
##
## Le discriminateur est le CYCLE : monter puis démonter le même lieu N fois
## dans le MÊME processus. Un cache borné donne un résidu constant quel que
## soit N ; une fuite donne un résidu proportionnel à N. Le rapport de fin de
## processus de Godot lui-même (la ligne que `validate_fast.sh` filtre) est
## relevé en parallèle des compteurs internes : deux instruments indépendants
## qui doivent raconter la même histoire, sans quoi c'est l'instrument qu'il
## faut corriger avant la conclusion.
##
## Usage :
##   godot --headless --path . --script tools/godot/instrumente_materiaux.gd -- \
##       --scenario=ferme --cycles=3 --sortie=res://<...>.json
##
## Scénarios : temoin, ferme, arbre, ferme_arbre, monde, controle_positif.
##
## PIÈGE mesuré (tools/CLAUDE.md) : ne jamais enchaîner cet outil dans un `head`.
## Il écrit son JSON à la toute fin ; un SIGPIPE tue le processus avant, la
## console montre un résultat crédible et AUCUN fichier n'est écrit.
extends SceneTree

## Chemins des scènes montées. `monde` reproduit ce que montent réellement les
## tests R2B (`test_world_v2_r2b_basin.gd`, `_camps.gd`, `r2b1_braise.gd`) :
## la scène entière, pas un lieu isolé.
const SCENE_FERME: String = "res://scenes/world_v2/poi/AbandonedFarmPlace.tscn"
const SCENE_ARBRE: String = "res://scenes/world_v2/poi/ThunderstruckTreePlace.tscn"
const SCENE_MONDE: String = "res://scenes/world_v2/WorldV2.tscn"
const GLB_FERME: String = "res://assets/architecture/farm/SM_Farm_Ruins.glb"
const GLB_MUR: String = "res://assets/architecture/village/SM_Village_Wall.glb"
## Une pièce de kit CC0 posée par `WorldV2PlaceKit.module()`, prise comme
## témoin du chemin `apply_tone()`. Le nom vient de `_wall()` de la ferme.
const KIT_TEMOIN: StringName = &"Prop_Wagon"

## Nombre de trames laissées au moteur pour consommer les `queue_free()`.
## Trois trames de process plus une de physique : au-delà, mesuré, le compte
## ne bouge plus — en deçà, on mesurerait une file d'attente et non un résidu.
const TRAMES_APRES_DEMONTAGE: int = 3
## Taille de la fuite volontaire du contrôle positif. Assez grande pour être
## lue sans ambiguïté, assez petite pour rester lisible dans le journal.
const CONTROLE_POSITIF_N: int = 100

var _scenario: String = "temoin"
var _cycles: int = 2
var _sortie: String = ""
var _journal: Array[String] = []


func _initialize() -> void:
	_lire_arguments()
	_dire("=== ISS-059 instrumentation — scenario=%s cycles=%d ==="
		% [_scenario, _cycles])
	_dire("moteur %s" % Engine.get_version_info()["string"])
	await process_frame

	var rapport: Dictionary = {
		"scenario": _scenario,
		"cycles": _cycles,
		"moteur": Engine.get_version_info()["string"],
		"stabilite_ids_base": {},
		"avant_tout": {},
		"cycles_mesures": [],
	}

	# LA MESURE QUI TRANCHE LA CLÉ DU CACHE. Toutes les peintures du monde
	# indexent leur cache sur `base.get_instance_id()`. Si cet identifiant
	# change d'une instanciation à l'autre, le cache n'est pas un cache : il
	# grossit sans borne et chaque montage y dépose des matériaux définitifs.
	# ORDRE IMPORTANT, et il a déjà menti une fois : `_kit_sans_retention()`
	# doit tourner AVANT `_diagnostic_kit()`, dont les variables locales
	# `packed_a`/`packed_b` gardent la `PackedScene` vivante et faisaient
	# répondre « ids identiques » à une expérience censée mesurer l'inverse.
	rapport["kit_sans_retention"] = _kit_sans_retention()
	rapport["stabilite_ids_base"] = _stabilite_ids_base()
	rapport["diagnostic_kit"] = _diagnostic_kit()

	rapport["avant_tout"] = _etat("avant_tout")
	_dire("état initial : %s" % JSON.stringify(rapport["avant_tout"]["compteurs"]))

	for cycle: int in range(_cycles):
		var mesure: Dictionary = await _un_cycle(cycle)
		(rapport["cycles_mesures"] as Array).append(mesure)

	rapport["verdicts"] = _verdicts(rapport)
	_ecrire(rapport)
	_dire("=== FIN — le rapport de fuite de fin de processus suit ci-dessous ===")
	quit(0)


func _lire_arguments() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			_scenario = arg.substr(len("--scenario="))
		elif arg.begins_with("--cycles="):
			_cycles = maxi(1, int(arg.substr(len("--cycles="))))
		elif arg.begins_with("--sortie="):
			_sortie = arg.substr(len("--sortie="))


## Un cycle complet : mesure avant, montage, mesure montée, démontage,
## mesure après. C'est la différence entre les « après » successifs qui
## sépare un cache borné d'une fuite.
func _un_cycle(index: int) -> Dictionary:
	var avant: Dictionary = _etat("avant_montage")
	var racines: Array[Node3D] = await _monter()
	var recensement: Dictionary = _recenser(racines)
	var monte: Dictionary = _etat("monte")
	await _demonter(racines)
	var apres: Dictionary = _etat("apres_demontage")
	var mesure: Dictionary = {
		"cycle": index,
		"avant_montage": avant,
		"monte": monte,
		"apres_demontage": apres,
		"recensement": recensement,
	}
	_dire("cycle %d : objets avant=%d monté=%d après=%d | caches total=%d"
		% [index,
			int(avant["compteurs"]["object_count"]),
			int(monte["compteurs"]["object_count"]),
			int(apres["compteurs"]["object_count"]),
			int(apres["caches_total"])])
	return mesure


func _monter() -> Array[Node3D]:
	var racines: Array[Node3D] = []
	match _scenario:
		"temoin":
			pass
		"controle_positif":
			# CONTRÔLE POSITIF DE L'INSTRUMENT, et il est indispensable.
			# Ce tableau de bord conclut « aucune ligne de fuite en fin de
			# processus » ; encore faut-il prouver que le rapporteur de Godot
			# PEUT parler dans cette invocation. Sans ce contrôle, « zéro
			# ligne » se confond avec « rapporteur muet », et toute la
			# conclusion négative tombe.
			#
			# On fabrique donc une fuite VRAIE et de taille connue : des
			# `MeshInstance3D` jamais libérés (un Node n'est pas compté par
			# référence : perdre son pointeur le fait fuir), chacun portant un
			# `StandardMaterial3D` unique. Attendu en sortie : environ
			# CONTROLE_POSITIF_N objets ObjectDB et autant de `DummyMaterial`.
			for i: int in range(CONTROLE_POSITIF_N):
				var perdu: MeshInstance3D = MeshInstance3D.new()
				perdu.name = "FuiteVolontaire_%d" % i
				var m: StandardMaterial3D = StandardMaterial3D.new()
				m.albedo_color = Color(float(i) / 100.0, 0.5, 0.5)
				perdu.material_override = m
				# Ni parent, ni libération, ni référence conservée.
		"ferme":
			racines.append(_instancier(SCENE_FERME))
		"arbre":
			racines.append(_instancier(SCENE_ARBRE))
		"ferme_arbre":
			racines.append(_instancier(SCENE_FERME))
			racines.append(_instancier(SCENE_ARBRE))
		"monde":
			racines.append(_instancier(SCENE_MONDE))
		_:
			_dire("SCENARIO INCONNU: %s — rien monté" % _scenario)
	for racine: Node3D in racines:
		if racine != null:
			root.add_child(racine)
	await process_frame
	await physics_frame
	return racines


func _instancier(chemin: String) -> Node3D:
	var packed: PackedScene = load(chemin) as PackedScene
	if packed == null:
		_dire("ÉCHEC de chargement : %s" % chemin)
		return null
	return packed.instantiate() as Node3D


func _demonter(racines: Array[Node3D]) -> void:
	for racine: Node3D in racines:
		if racine == null:
			continue
		if racine.get_parent() != null:
			racine.get_parent().remove_child(racine)
		racine.queue_free()
	for i: int in range(TRAMES_APRES_DEMONTAGE):
		await process_frame
	await physics_frame


## Est-ce que `base.get_instance_id()` est STABLE d'une instanciation à
## l'autre ? Trois instanciations successives du même GLB, hors arbre, et on
## compare les identifiants des matériaux actifs. Réponse `true` : le cache
## est indexé sur une clé stable, donc borné. Réponse `false` : chaque montage
## crée des entrées neuves, et le cache statique n'est jamais vidé.
func _stabilite_ids_base() -> Dictionary:
	var resultat: Dictionary = {}
	for chemin: String in [GLB_FERME, GLB_MUR]:
		var passes: Array[Array] = []
		for essai: int in range(3):
			var packed: PackedScene = load(chemin) as PackedScene
			if packed == null:
				continue
			var noeud: Node = packed.instantiate()
			var ids: Array[int] = []
			for n: Node in _mailles(noeud):
				var mi: MeshInstance3D = n as MeshInstance3D
				if mi.mesh == null:
					continue
				for s: int in range(mi.mesh.get_surface_count()):
					var m: Material = mi.get_active_material(s)
					if m != null:
						ids.append(int(m.get_instance_id()))
			ids.sort()
			passes.append(ids)
			noeud.free()
		var stable: bool = passes.size() == 3 \
			and passes[0] == passes[1] and passes[1] == passes[2]
		resultat[chemin] = {
			"surfaces_avec_materiau": (passes[0] as Array).size() if passes.size() > 0 else 0,
			"ids_distincts": _distincts(passes[0] if passes.size() > 0 else []),
			"stable_sur_3_instanciations": stable,
			"ids_passe_1": passes[0] if passes.size() > 0 else [],
			"ids_passe_3": passes[2] if passes.size() > 2 else [],
		}
		_dire("stabilité des id de base — %s : %s (%d surfaces, %d id distincts)"
			% [chemin.get_file(), str(stable),
				int(resultat[chemin]["surfaces_avec_materiau"]),
				int(resultat[chemin]["ids_distincts"])])
	return resultat


## POURQUOI la clé du cache de `WorldV2PlaceKit` ne retombe jamais sur elle-même.
##
## Mesuré : le cache du kit gagne 27 entrées à CHAQUE montage, la moitié
## `teinte` de la clé étant identique et la moitié `instance_id` n'ayant
## AUCUNE intersection. Donc `base` est un objet neuf à chaque instanciation.
## Reste à savoir d'où vient ce neuf — c'est ce que ce diagnostic mesure, et
## il regarde les trois seuls endroits possibles : la `PackedScene` (est-elle
## rechargée ?), le maillage, et le matériau lui-même (`local_to_scene` fait
## dupliquer une sous-ressource à chaque `instantiate()`).
func _diagnostic_kit() -> Dictionary:
	var packed_a: PackedScene = WorldV2PlaceKit.scene_for(KIT_TEMOIN)
	var packed_b: PackedScene = WorldV2PlaceKit.scene_for(KIT_TEMOIN)
	if packed_a == null:
		return {"erreur": "module %s introuvable" % KIT_TEMOIN}
	var passes: Array[Dictionary] = []
	for essai: int in range(2):
		var noeud: Node = packed_a.instantiate()
		var surfaces: Array[Dictionary] = []
		for n: Node in _mailles(noeud):
			var mi: MeshInstance3D = n as MeshInstance3D
			if mi.mesh == null:
				continue
			for s: int in range(mi.mesh.get_surface_count()):
				var actif: Material = mi.get_active_material(s)
				var du_maillage: Material = mi.mesh.surface_get_material(s)
				var surcharge: Material = mi.get_surface_override_material(s)
				surfaces.append({
					"noeud": String(mi.name),
					"surface": s,
					"maillage_id": int(mi.mesh.get_instance_id()),
					"maillage_local_to_scene": mi.mesh.resource_local_to_scene,
					"maillage_chemin": mi.mesh.resource_path,
					"actif_id": int(actif.get_instance_id()) if actif != null else 0,
					"actif_local_to_scene":
						actif.resource_local_to_scene if actif != null else false,
					"actif_chemin": actif.resource_path if actif != null else "",
					"actif_nom": actif.resource_name if actif != null else "",
					"vient_du_maillage": actif != null and du_maillage == actif,
					"vient_dune_surcharge": surcharge != null,
				})
		passes.append({"surfaces": surfaces})
		noeud.free()
	var a: Array = passes[0]["surfaces"] as Array
	var b: Array = passes[1]["surfaces"] as Array
	var ids_a: Array[int] = []
	var ids_b: Array[int] = []
	var mailles_a: Array[int] = []
	var mailles_b: Array[int] = []
	for d: Variant in a:
		ids_a.append(int((d as Dictionary)["actif_id"]))
		mailles_a.append(int((d as Dictionary)["maillage_id"]))
	for d: Variant in b:
		ids_b.append(int((d as Dictionary)["actif_id"]))
		mailles_b.append(int((d as Dictionary)["maillage_id"]))
	var res: Dictionary = {
		"module": String(KIT_TEMOIN),
		"packedscene_partagee_entre_deux_load":
			packed_a.get_instance_id() == packed_b.get_instance_id(),
		"materiaux_identiques_entre_deux_instanciations": ids_a == ids_b,
		"maillages_identiques_entre_deux_instanciations": mailles_a == mailles_b,
		"detail_passe_1": a,
		"detail_passe_2": b,
	}
	_dire("diagnostic kit %s : PackedScene partagée=%s | matériaux identiques=%s | maillages identiques=%s"
		% [KIT_TEMOIN, str(res["packedscene_partagee_entre_deux_load"]),
			str(res["materiaux_identiques_entre_deux_instanciations"]),
			str(res["maillages_identiques_entre_deux_instanciations"])])
	if a.size() > 0:
		var d0: Dictionary = a[0] as Dictionary
		_dire("  surface 0 : nom=%s local_to_scene(mat)=%s local_to_scene(mesh)=%s vient_du_maillage=%s chemin=%s"
			% [String(d0["actif_nom"]), str(d0["actif_local_to_scene"]),
				str(d0["maillage_local_to_scene"]), str(d0["vient_du_maillage"]),
				String(d0["actif_chemin"])])
	return res


## LA CAUSE, isolée en une expérience.
##
## Ci-dessus, deux instanciations d'affilée donnent les MÊMES identifiants de
## matériau — parce que la variable locale `packed_a` garde la `PackedScene`
## vivante. Ici on fait exactement ce que fait le code de production : on
## charge, on instancie, on libère TOUT, on ne retient rien. Si les
## identifiants changent alors, c'est que la `PackedScene` est sortie du cache
## de ressources avec ses sous-ressources, et qu'un `get_instance_id()` ne peut
## pas servir de clé à un cache qui, lui, survit au processus entier.
##
## Les huit lieux V2 font l'inverse (`const … = preload(…)`) : leur
## `PackedScene` est épinglée pour la durée du processus, donc leurs clés
## tiennent. Le kit est le seul à charger sans retenir.
func _kit_sans_retention() -> Dictionary:
	# LE CHEMIN EST RÉSOLU ICI, ET PAS PAR `WorldV2PlaceKit`, pour deux raisons
	# qui ont chacune failli fausser la mesure.
	#   1. `_index` est construit PARESSEUSEMENT dans `scene_for()`. Le lire
	#      avant tout appel rendait "" ; `ResourceLoader.has_cached("")` répond
	#      alors `false` par accident, et la ligne « plus en cache » ressemblait
	#      à une preuve alors qu'elle n'en était pas une. Piège attrapé le
	#      2026-08-20, après coup.
	#   2. Depuis la correction, `scene_for()` RETIENT la PackedScene : passer
	#      par lui épinglerait justement ce que cette expérience doit voir
	#      mourir. On mesure donc le comportement du MOTEUR, `load()` nu, qui
	#      est la condition d'avant correction.
	var chemin: String = _resoudre_module(KIT_TEMOIN)
	var ids: Array[Array] = []
	var caches: Array[bool] = []
	if chemin.is_empty():
		return {"erreur": "module %s introuvable dans MODULE_DIRS" % KIT_TEMOIN}
	for essai: int in range(2):
		var packed: PackedScene = load(chemin) as PackedScene
		if packed == null:
			continue
		var noeud: Node = packed.instantiate()
		var lot: Array[int] = []
		for n: Node in _mailles(noeud):
			var mi: MeshInstance3D = n as MeshInstance3D
			if mi.mesh == null:
				continue
			for si: int in range(mi.mesh.get_surface_count()):
				var m: Material = mi.get_active_material(si)
				if m != null:
					lot.append(int(m.get_instance_id()))
		lot.sort()
		ids.append(lot)
		noeud.free()
		packed = null
		# Rien ne retient plus la PackedScene dans CETTE portée ni au-dessus :
		# est-elle encore dans le cache de ressources ?
		caches.append(ResourceLoader.has_cached(chemin) if not chemin.is_empty()
			else false)
	var identiques: bool = ids.size() == 2 and ids[0] == ids[1]
	_dire("  sans retenir la PackedScene : ids identiques=%s | encore en cache après libération=%s"
		% [str(identiques), str(caches)])
	return {
		"chemin": chemin,
		"ids_identiques_entre_deux_chargements": identiques,
		"encore_en_cache_apres_liberation": caches,
		"ids_chargement_1": ids[0] if ids.size() > 0 else [],
		"ids_chargement_2": ids[1] if ids.size() > 1 else [],
	}


## Résout un module de kit par nom canonique, SANS passer par
## `WorldV2PlaceKit` — voir la raison dans `_kit_sans_retention()`.
func _resoudre_module(nom: StringName) -> String:
	for dossier: String in WorldV2PlaceKit.MODULE_DIRS:
		for extension: String in [".gltf", ".glb"]:
			var candidat: String = "%s/%s%s" % [dossier, nom, extension]
			if ResourceLoader.exists(candidat, "PackedScene"):
				return candidat
	return ""


## Recense les matériaux RÉELLEMENT posés sur les surfaces montées : c'est
## la décomposition demandée — combien de matériaux distincts, sur quelles
## familles, et combien portent une texture.
func _recenser(racines: Array[Node3D]) -> Dictionary:
	var ids: Dictionary = {}
	var par_famille: Dictionary = {}
	var surfaces: int = 0
	var textures: int = 0
	for racine: Node3D in racines:
		if racine == null:
			continue
		for n: Node in _mailles(racine):
			var mi: MeshInstance3D = n as MeshInstance3D
			if mi.mesh == null:
				continue
			for s: int in range(mi.mesh.get_surface_count()):
				surfaces += 1
				var m: Material = mi.get_active_material(s)
				if m == null:
					continue
				var id: int = int(m.get_instance_id())
				if ids.has(id):
					continue
				ids[id] = true
				var std: StandardMaterial3D = m as StandardMaterial3D
				var famille: String = m.resource_name
				if famille.is_empty():
					famille = "(sans nom) %s" % m.get_class()
				par_famille[famille] = int(par_famille.get(famille, 0)) + 1
				if std != null and std.albedo_texture != null:
					textures += 1
	return {
		"surfaces_parcourues": surfaces,
		"materiaux_distincts_actifs": ids.size(),
		"materiaux_avec_albedo_texture": textures,
		"par_famille": par_famille,
	}


func _mailles(racine: Node) -> Array[Node]:
	var trouves: Array[Node] = racine.find_children("*", "MeshInstance3D",
		true, false)
	if racine is MeshInstance3D:
		trouves.append(racine)
	return trouves


func _etat(etiquette: String) -> Dictionary:
	var caches: Dictionary = _caches()
	var total: int = 0
	for cle: String in caches:
		total += int((caches[cle] as Dictionary)["taille"])
	return {
		"etiquette": etiquette,
		"compteurs": {
			"object_count": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			"resource_count": int(Performance.get_monitor(
				Performance.OBJECT_RESOURCE_COUNT)),
			"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			"orphan_node_count": int(Performance.get_monitor(
				Performance.OBJECT_ORPHAN_NODE_COUNT)),
		},
		"caches": caches,
		"caches_total": total,
	}


## Les huit caches statiques du dépôt qui retiennent des ressources pour la
## durée du processus. Un `static var` de GDScript n'est jamais vidé : tout ce
## qui y entre est, par construction, vivant à la fermeture — donc compté par
## le rapport de fuite. Les recenser tous, et pas seulement le suspect nommé,
## est la seule façon d'attribuer un écart plutôt que de le supposer.
func _caches() -> Dictionary:
	return {
		"AbandonedFarmPlace._cache_materiaux":
			_decrire(AbandonedFarmPlace._cache_materiaux),
		"ThunderstruckTreePlace._cache_materiaux":
			_decrire(ThunderstruckTreePlace._cache_materiaux),
		"RiversideVillagePlace._cache_teintes":
			_decrire(RiversideVillagePlace._cache_teintes),
		"WorldV2PlaceKit._material_cache":
			_decrire(WorldV2PlaceKit._material_cache),
		"WorldV2VegetationBuilder._grass_materials":
			_decrire(WorldV2VegetationBuilder._grass_materials),
		"KitPlacement._base_cache": _decrire(KitPlacement._base_cache),
		"AssetRegistry._model_cache": _decrire(AssetRegistry._model_cache),
		"HudStyle._ui_streams": _decrire(HudStyle._ui_streams),
	}


func _decrire(cache: Dictionary) -> Dictionary:
	var cles: Array[String] = []
	for cle: Variant in cache:
		cles.append(str(cle))
	cles.sort()
	return {"taille": cache.size(), "cles": cles}


func _distincts(valeurs: Array) -> int:
	var vus: Dictionary = {}
	for v: Variant in valeurs:
		vus[v] = true
	return vus.size()


## Le verdict par CATÉGORIE, calculé et non raconté. Le résidu d'un cycle est
## l'écart entre l'état après démontage et l'état avant le tout premier
## montage. Deux résidus successifs identiques = borné. Un écart constant et
## non nul entre eux = cumulatif.
func _verdicts(rapport: Dictionary) -> Dictionary:
	var mesures: Array = rapport["cycles_mesures"] as Array
	var base: int = int(rapport["avant_tout"]["compteurs"]["object_count"])
	var base_caches: int = int(rapport["avant_tout"]["caches_total"])
	var residus: Array[int] = []
	var residus_caches: Array[int] = []
	for m: Variant in mesures:
		var d: Dictionary = m as Dictionary
		residus.append(int(d["apres_demontage"]["compteurs"]["object_count"]) - base)
		residus_caches.append(int(d["apres_demontage"]["caches_total"]) - base_caches)
	var croissances: Array[int] = []
	for i: int in range(1, residus.size()):
		croissances.append(residus[i] - residus[i - 1])
	var croissances_caches: Array[int] = []
	for i: int in range(1, residus_caches.size()):
		croissances_caches.append(residus_caches[i] - residus_caches[i - 1])
	var cumulatif: bool = false
	for c: int in croissances:
		if c != 0:
			cumulatif = true
	var cache_stable: bool = true
	for c: int in croissances_caches:
		if c != 0:
			cache_stable = false
	return {
		"residus_objectdb_par_cycle": residus,
		"croissance_entre_cycles": croissances,
		"residus_caches_par_cycle": residus_caches,
		"croissance_caches_entre_cycles": croissances_caches,
		"categorie_cache_stable": cache_stable,
		"categorie_croissance_cumulative": cumulatif,
	}


func _dire(ligne: String) -> void:
	print(ligne)
	_journal.append(ligne)


func _ecrire(rapport: Dictionary) -> void:
	rapport["journal"] = _journal
	if _sortie.is_empty():
		_dire("aucune sortie demandée (--sortie=) — rapport non écrit")
		return
	var dossier: String = _sortie.get_base_dir()
	if not DirAccess.dir_exists_absolute(dossier):
		DirAccess.make_dir_recursive_absolute(dossier)
	var f: FileAccess = FileAccess.open(_sortie, FileAccess.WRITE)
	if f == null:
		_dire("ÉCHEC d'écriture : %s (erreur %d)"
			% [_sortie, FileAccess.get_open_error()])
		return
	f.store_string(JSON.stringify(rapport, "  "))
	f.close()
	_dire("rapport écrit : %s" % _sortie)
