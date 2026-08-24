## Sonde du SANCTUAIRE FORESTIER (compo B « La nef avalée »).
##
## Elle répond aux trois conditions de l'arbitrage du lead qui ne se prouvent
## ni à l'œil ni au calcul de tête :
##
##   1. PLAFOND D'IDENTITÉ — le point le plus haut du BÂTI, mesuré sur les
##      nœuds POSÉS (donc terrain compris), sous 2,40 m ; la marge est
##      IMPRIMÉE, jamais déduite. Les troncs sont exclus : le contrat dit
##      « rien au-dessus de 2,4 m HORS TRONCS ».
##   2. LA PIERRE COUCHÉE EST FRANCHISSABLE — sonde physique sur les vrais
##      colliders, du seuil à la table, au pas de 0,15 m : aucune contremarche
##      au-dessus de la hauteur de marche du héros, volume de capsule libre,
##      couloir assez large.
##   3. LES TROIS TRONCS DÉPLACÉS APPARTIENNENT AU LIEU — recensement de ce
##      qui est GELÉ autour du site (`WorldV2/Vegetation`, semis V2.2) contre
##      ce que le lieu plante lui-même. Le constat doit être une mesure : si
##      un tronc gelé bloque l'approche nord, il reste où il est.
##
## Ce que la sonde ne remplace PAS : la capture. L'invisibilité depuis la
## route se juge sur l'image prise depuis P1, pas ici.
##
## Usage :
##   tools/lancer_godot.sh --path . --script tools/godot/probe_sanctuaire.gd
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"
const PLACE_ID: StringName = &"valley.poi.forest_shrine.01"
const PAS: float = 0.15
const MARCHE_MAX: float = 0.38
const CAPSULE_H: float = 1.9
const CAPSULE_R: float = 0.40
const PLAFOND_IDENTITE: float = 2.40
## Rayon de recensement de la végétation gelée autour du site.
const RAYON_RECENSEMENT: float = 14.0

## La nef, en coordonnées LOCALES au lieu (x est, z sud) : on entre par le
## seuil au nord, on enjambe la pierre couchée, on arrive à la table.
const CHEMIN: Array[Vector2] = [
	Vector2(-0.05, -4.60),
	Vector2(-0.05, -3.00),
	Vector2(-0.10, -2.10),
	Vector2(0.00, -1.20),
	Vector2(0.00, -0.85),
]
## Les pièces qui sont du BÂTI (le reste est végétal et peut dépasser).
const PREFIXES_BATI: Array[String] = ["SM_Shrine_", "Socle_", "Floor_",
	"Pebble_", "RockPath_"]


func _initialize() -> void:
	var world: Node3D = (load(WORLD) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i: int in range(20):
		await process_frame
	await physics_frame

	var lieu: Node3D = null
	for noeud: Node in root.get_tree().get_nodes_in_group(&"world_v2_places"):
		if (noeud.get_meta(&"place_id", &"") as StringName) == PLACE_ID:
			lieu = noeud as Node3D
			break
	if lieu == null:
		printerr("[sanctuaire] ECHEC : lieu %s introuvable" % PLACE_ID)
		quit(2)
		return

	var hm: WorldV2Heightmap = world.call("heightmap") as WorldV2Heightmap
	var space: PhysicsDirectSpaceState3D = \
		world.get_world_3d().direct_space_state
	var ecarts: Array[String] = []

	# ---- 1. PLAFOND D'IDENTITÉ ---------------------------------------------
	var plus_haut: float = -INF
	var coupable: String = ""
	var comptes: int = 0
	for noeud: Node in lieu.find_children("*", "VisualInstance3D", true, false):
		var vi: VisualInstance3D = noeud as VisualInstance3D
		var chemin: String = String(vi.get_path())
		var bati: bool = false
		for prefixe: String in PREFIXES_BATI:
			if chemin.contains(prefixe):
				bati = true
				break
		if not bati:
			continue
		var mi: MeshInstance3D = vi as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		comptes += 1
		var boite: AABB = mi.global_transform * mi.mesh.get_aabb()
		var sol: float = hm.height_at(boite.get_center().x, boite.get_center().z)
		var au_dessus: float = boite.position.y + boite.size.y - sol
		if au_dessus > plus_haut:
			plus_haut = au_dessus
			coupable = String(vi.name)
	print("[sanctuaire] plafond : %d maillages de bâti ; le plus haut est "
		% comptes + "« %s » à %.3f m au-dessus du sol gelé — MARGE %.3f m "
		% [coupable, plus_haut, PLAFOND_IDENTITE - plus_haut]
		+ "sous le plafond d'identité de %.2f m" % PLAFOND_IDENTITE)
	if comptes == 0:
		ecarts.append("aucun maillage de bâti reconnu — la sonde n'a rien mesuré")
	elif plus_haut > PLAFOND_IDENTITE:
		ecarts.append("bâti à %.2f m > plafond d'identité %.2f m (%s)"
			% [plus_haut, PLAFOND_IDENTITE, coupable])

	# ---- 2. LA NEF EST MARCHABLE -------------------------------------------
	var precedent: float = NAN
	var echantillons: int = 0
	var marche_max_vue: float = 0.0
	for segment: int in range(CHEMIN.size() - 1):
		var a: Vector2 = CHEMIN[segment]
		var b: Vector2 = CHEMIN[segment + 1]
		var pas_n: int = maxi(2, int(ceil(a.distance_to(b) / PAS)))
		for i: int in range(pas_n + 1):
			var p: Vector2 = a.lerp(b, float(i) / float(pas_n))
			var monde: Vector3 = lieu.to_global(Vector3(p.x, 0.0, p.y))
			var h: float = _sol(space, monde)
			if is_nan(h):
				ecarts.append("aucun sol en local (%.2f, %.2f)" % [p.x, p.y])
				continue
			echantillons += 1
			if not is_nan(precedent):
				var montee: float = absf(h - precedent)
				marche_max_vue = maxf(marche_max_vue, montee)
				if montee > MARCHE_MAX:
					ecarts.append("marche %.2f m > %.2f en local (%.2f, %.2f)"
						% [montee, MARCHE_MAX, p.x, p.y])
			precedent = h
			var toit: Dictionary = space.intersect_ray(
				PhysicsRayQueryParameters3D.create(
					Vector3(monde.x, h + 0.45, monde.z),
					Vector3(monde.x, h + CAPSULE_H, monde.z), 1))
			if not toit.is_empty():
				ecarts.append("plafond a %.2f m au-dessus de (%.2f, %.2f)"
					% [(toit["position"] as Vector3).y - h, p.x, p.y])
	print("[sanctuaire] nef : %d appuis sondés, plus grande marche %.3f m "
		% [echantillons, marche_max_vue]
		+ "(hauteur de marche du héros %.2f m)" % MARCHE_MAX)
	if echantillons < 20:
		ecarts.append("seulement %d appuis sondés — la sonde n'a pas marché"
			% echantillons)

	# ---- 2b. LARGEUR DU COULOIR --------------------------------------------
	# Un couloir se mesure LATÉRALEMENT, pas au centre : un rayon vertical au
	# milieu de la nef ne rencontre aucun socle et déclarerait « libre » une
	# nef bouchée. On tire donc à hauteur de hanche, de part et d'autre.
	# La grandeur honnête est le DÉGAGEMENT MINIMAL D'UN CÔTÉ, pas la somme
	# des deux : première version de cette sonde, elle additionnait les deux
	# tirs et comptait 3,0 m pour un tir qui ne rencontrait RIEN — « 3,72 m »
	# voulait donc dire « 0,72 d'un côté et rien de l'autre », un nombre juste
	# qui répondait à une autre question (tools/CLAUDE.md, la platitude
	# mesurée à la place de la largeur).
	var etroit: float = INF
	var ou_etroit: float = 0.0
	for z: float in [-3.20, -2.80, -2.40, -2.00, -1.60, -1.20]:
		var centre: Vector3 = lieu.to_global(Vector3(0.0, 0.0, z))
		var sol_c: float = hm.height_at(centre.x, centre.z)
		# 0,55 m et non 0,95 : à hauteur de hanche le rayon frôlait le sommet
		# des socles de 0,97 m et pouvait les rater. On tire à mi-socle.
		var origine: Vector3 = Vector3(centre.x, sol_c + 0.55, centre.z)
		for direction: Vector3 in [Vector3.RIGHT, Vector3.LEFT]:
			var monde_dir: Vector3 = lieu.global_transform.basis * direction
			var tir: Dictionary = space.intersect_ray(
				PhysicsRayQueryParameters3D.create(
					origine, origine + monde_dir * 3.0, 1))
			var degagement: float = 3.0
			if not tir.is_empty():
				degagement = origine.distance_to(tir["position"] as Vector3)
			if degagement < etroit:
				etroit = degagement
				ou_etroit = z
	print("[sanctuaire] couloir : dégagement latéral minimal %.2f m à "
		% etroit + "z = %.2f (rayon de capsule %.2f m)" % [ou_etroit, CAPSULE_R])
	if etroit < CAPSULE_R + 0.05:
		ecarts.append("dégagement de %.2f m à z = %.2f — la capsule ne passe pas"
			% [etroit, ou_etroit])

	# ---- 3. QUI EST GELÉ AUTOUR DU SITE ------------------------------------
	var origine_lieu: Vector3 = lieu.global_position
	var geles: int = 0
	var instances_plates: int = 0
	# Regroupé par cellule ET par position arrondie au demi-mètre : la
	# première version imprimait 159 lignes rigoureusement identiques, ce qui
	# noyait le seul fait utile — QUELLES espèces, et À QUELLE distance.
	var groupes: Dictionary = {}
	var vegetation: Node = world.find_child("Vegetation", true, false)
	if vegetation != null:
		for noeud: Node in vegetation.find_children("*",
				"MultiMeshInstance3D", true, false):
			var mm: MultiMeshInstance3D = noeud as MultiMeshInstance3D
			if mm.multimesh == null:
				continue
			for i: int in range(mm.multimesh.instance_count):
				var locale: Transform3D = \
					mm.multimesh.get_instance_transform(i)
				# HONNÊTETÉ DE MESURE : si le tampon d'instances rend
				# l'identité, la position lue n'est pas celle de l'arbre mais
				# celle de la CELLULE, et publier des coordonnées plausibles
				# et fausses serait pire que ne rien publier (ISS-018). On le
				# dit au lieu de le taire.
				if locale.origin.length_squared() < 1.0e-6:
					instances_plates += 1
				var t: Transform3D = mm.global_transform * locale
				var lx: float = t.origin.x - origine_lieu.x
				var lz: float = t.origin.z - origine_lieu.z
				var d: float = Vector2(lx, lz).length()
				if d > RAYON_RECENSEMENT:
					continue
				geles += 1
				var cle: String = "%s|%.0f|%.0f" % [mm.name, lx, lz]
				if groupes.has(cle):
					groupes[cle] = int(groupes[cle]) + 1
				else:
					groupes[cle] = 1
	print("[sanctuaire] gel : %d instance(s) de végétation V2.2 dans %.0f m "
		% [geles, RAYON_RECENSEMENT] + "du site, en %d groupe(s) — INTOUCHÉES "
		% groupes.size() + "par ce lieu")
	if instances_plates > 0:
		print("[sanctuaire]   AVERTISSEMENT : %d transform(s) d'instance "
			% instances_plates + "rendent l'identité — les positions "
			+ "ci-dessous sont celles de la CELLULE, pas de l'arbre. Le "
			+ "COMPTE et l'ESPÈCE restent lisibles ; la position, non.")
	var cles: Array = groupes.keys()
	cles.sort()
	for cle: String in cles:
		var parts: PackedStringArray = cle.split("|")
		print("[sanctuaire]   gelé : %-28s × %-3d  local (%s, %s)"
			% [parts[0], int(groupes[cle]), parts[1], parts[2]])
	var plantes: int = 0
	for noeud: Node in lieu.find_children("*", "Node3D", false, false):
		var nom: String = String(noeud.name)
		if nom.begins_with("Pine_") or nom.begins_with("CommonTree_"):
			plantes += 1
			print("[sanctuaire]   du lieu : %s en local (%.2f, %.2f)"
				% [nom, (noeud as Node3D).position.x,
					(noeud as Node3D).position.z])
	print("[sanctuaire] le lieu plante %d tronc(s) — ce sont ceux-là, et eux "
		% plantes + "seuls, que la corrective déplace")
	if plantes != 3:
		ecarts.append("le lieu plante %d tronc(s) au lieu de 3" % plantes)

	print("")
	if ecarts.is_empty():
		print("[sanctuaire] VERDICT : PASS — plafond d'identité %.3f m de "
			% (PLAFOND_IDENTITE - plus_haut)
			+ "marge, nef marchable, couloir %.2f m, %d tronc(s) du lieu"
			% [etroit, plantes])
		quit(0)
	else:
		for e: String in ecarts:
			print("[sanctuaire] ECART : %s" % e)
		print("[sanctuaire] VERDICT : FAIL (%d ecart(s))" % ecarts.size())
		quit(1)


func _sol(space: PhysicsDirectSpaceState3D, monde: Vector3) -> float:
	var hit: Dictionary = space.intersect_ray(
		PhysicsRayQueryParameters3D.create(
			Vector3(monde.x, monde.y + 12.0, monde.z),
			Vector3(monde.x, monde.y - 20.0, monde.z), 1))
	if hit.is_empty():
		return NAN
	return (hit["position"] as Vector3).y
