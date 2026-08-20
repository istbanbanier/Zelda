## ISS-059 — UN CACHE NE DOIT PAS GROSSIR QUAND ON REMONTE LE MÊME LIEU.
##
## CE QUE CE TEST EMPÊCHE DE REVENIR, mesuré le 2026-08-20 par
## `tools/godot/instrumente_materiaux.gd` (journaux et JSON dans
## `evidence/world_v2/v2_3_r2b3/iss059/`) :
##
##   | scénario, 3 cycles | entrées de cache par cycle | croissance |
##   |---|---|---|
##   | témoin (rien monté) | 0 / 0 / 0 | 0 |
##   | ferme seule | 48 / 75 / 102 | **+27 à CHAQUE cycle** |
##   | arbre seul | 11 / 15 / 19 | **+4** |
##   | monde entier | 334 / 536 / 738 | **+202** |
##
## Sur vingt cycles la ferme monte à 561 entrées, sans le moindre palier : la
## croissance est LINÉAIRE, ce n'est donc ni une allocation bornée ni un cache
## qui se remplit une fois.
##
## LA CAUSE, mesurée et non supposée. `WorldV2PlaceKit._material_cache` et
## `RiversideVillagePlace._cache_teintes` indexent leurs matériaux sur
## `base.get_instance_id()`. Or `WorldV2PlaceKit.scene_for()` fait `load(path)`
## et NE RETIENT RIEN : au démontage du lieu, plus personne ne référence la
## `PackedScene`, elle sort du cache de ressources avec ses sous-ressources, et
## le montage suivant recrée des matériaux NEUFS. Vérifié aux deux bouts —
## en gardant la `PackedScene` vivante les identifiants sont identiques ; en ne
## la gardant pas, `ResourceLoader.has_cached()` répond `false` et les
## identifiants n'ont AUCUNE intersection d'un cycle à l'autre.
##
## Une clé bâtie sur une identité qui meurt avant le cache ne peut jamais
## retomber juste. Le cache est `static` : il n'est jamais vidé, et chaque
## génération de matériaux y reste jusqu'à la fin du processus.
##
## Les huit lieux échappent au défaut parce qu'ils font `const … = preload(…)`,
## ce qui épingle leur `PackedScene` : leurs caches propres sont mesurés
## STABLES (ferme 6/6/6, arbre 4/4/4). `KitPlacement._base_cache`, qui a la
## même forme mais une clé de chaîne STABLE (le nom du modèle ici, le chemin
## de scène chez les appelants V1), est stable lui aussi (15/15/15). Ce n'est
## donc pas la mise en cache qui est fautive, ni même `get_instance_id()` en
## soi : c'est la durée de vie de ce sur quoi la clé est bâtie.
##
## CE TEST NE MESURE PAS UNE TAILLE ABSOLUE, et c'est délibéré : la suite
## complète monte ces lieux dans beaucoup de tests, le cache est donc déjà
## chaud quand celui-ci démarre. Il mesure l'ÉCART entre deux de ses propres
## cycles — la seule quantité qui reste vraie quel que soit l'ordre des tests.
extends GateTestCase

const SCENE_FERME: String = "res://scenes/world_v2/poi/AbandonedFarmPlace.tscn"
const SCENE_HAMEAU: String = "res://scenes/world_v2/poi/RiversideVillagePlace.tscn"


func test_cache_du_kit_idempotent_au_second_montage() -> void:
	remember_root()
	var peintes: int = await _un_cycle(SCENE_FERME)
	# GARDE-FOU : sans elle, un lieu qui ne poserait plus aucun module de kit
	# rendrait ce test vert en ne regardant rien (piège « assertion sautée »).
	check(peintes > 0,
		"la ferme doit poser des surfaces teintées par le kit — %d trouvée(s)"
			% peintes)
	var apres_1: int = WorldV2PlaceKit._material_cache.size()
	await _un_cycle(SCENE_FERME)
	var apres_2: int = WorldV2PlaceKit._material_cache.size()
	check(apres_2 == apres_1,
		("WorldV2PlaceKit._material_cache grossit au remontage : %d puis %d "
			+ "(+%d). Un second montage du MÊME lieu ne doit ajouter aucune "
			+ "entrée ; s'il en ajoute, la clé du cache repose sur une "
			+ "identité plus courte que le cache (ISS-059).")
			% [apres_1, apres_2, apres_2 - apres_1])
	var propre: bool = await restore_root()
	check(propre, "démontage propre (ferme) — %s" % restore_root_reason())


func test_cache_du_hameau_idempotent_au_second_montage() -> void:
	remember_root()
	var peintes: int = await _un_cycle(SCENE_HAMEAU)
	check(peintes > 0,
		"le hameau doit poser des surfaces teintées — %d trouvée(s)" % peintes)
	var apres_1: int = RiversideVillagePlace._cache_teintes.size()
	await _un_cycle(SCENE_HAMEAU)
	var apres_2: int = RiversideVillagePlace._cache_teintes.size()
	check(apres_2 == apres_1,
		("RiversideVillagePlace._cache_teintes grossit au remontage : %d puis "
			+ "%d (+%d). Même cause que le kit : `_teinter()` s'applique aux "
			+ "modules posés par `K.module()`, dont la PackedScene n'est pas "
			+ "retenue (ISS-059).")
			% [apres_1, apres_2, apres_2 - apres_1])
	var propre: bool = await restore_root()
	check(propre, "démontage propre (hameau) — %s" % restore_root_reason())


## Monte le lieu, compte les surfaces réellement repeintes, puis le démonte.
## Le compte sert de garde-fou : il prouve que le cycle a bien exercé le
## chemin de peinture, sans quoi l'égalité qui suit ne vaudrait rien.
func _un_cycle(chemin: String) -> int:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	var packed: PackedScene = load(chemin) as PackedScene
	if packed == null:
		return 0
	var lieu: Node3D = packed.instantiate() as Node3D
	if lieu == null:
		return 0
	loop.root.add_child(lieu)
	await loop.process_frame
	await loop.physics_frame
	var peintes: int = _surfaces_surchargees(lieu)
	lieu.get_parent().remove_child(lieu)
	lieu.queue_free()
	await loop.process_frame
	await loop.process_frame
	await loop.physics_frame
	return peintes


func _surfaces_surchargees(racine: Node3D) -> int:
	var total: int = 0
	for node: Node in racine.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			if instance.get_surface_override_material(surface) != null:
				total += 1
	return total
