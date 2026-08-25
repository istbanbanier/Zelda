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
## LE PIÈGE QUI A RENDU CETTE SONDE INFAILLIBLE (LOT 1.R.1) : la version R2
## portait CHEMIN en coordonnées locales au lieu, figées AVANT la rotation de
## la nef (θ = 45°, T = (2,50 ; 0,25), similitude du script du lieu). Après la
## recomposition, la sonde marchait donc l'ANCIEN axe — de l'herbe nue — et
## imprimait « plus grande marche 0,000 » : un test qui ne pouvait pas échouer
## (PROMPT4 §2). Correctif : CHEMIN vit dans le PLAN DE NEF, et la sonde le
## projette par la MÊME similitude, lue dans les constantes du script du lieu
## (`NEF_ROT_DEG`, `NEF_T`, `NEF_L`, `NEF_W`) — si le lieu tourne encore, la
## sonde tourne avec lui au lieu de mentir.
##
## DEUXIÈME AMENDEMENT, même intégration : une fois l'axe corrigé, la sonde a
## rougi sur DEUX écarts qui n'étaient pas des défauts de la nef — elle
## marchait SUR le collider élargi de sa propre destination (marche 0,60 m),
## et sa station de couloir −1,20 tirait dans le coin tourné de ce même
## collider (0,31 m d'un côté, 3 m de l'autre). Le chemin s'arrête donc devant
## le front du collider (voir CHEMIN), une garde d'atteinte remplace le
## tronçon retiré, et le couloir se juge à la FENÊTRE libre totale. Les seuils
## (MARCHE_MAX, CAPSULE_R, plafond) n'ont pas bougé.
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

## La source de vérité de la similitude nef → local : le script du lieu.
const PLACE: GDScript = preload(
	"res://scripts/world_v2/poi/forest_shrine_place.gd")

## La nef, en coordonnées du PLAN DE NEF (x est, z sud, table à l'origine) :
## on entre par le seuil au nord (marche vers z −3,0), on enjambe la pierre
## couchée (−0,10 ; −2,10), on s'arrête DEVANT la table — marcher SUR sa
## dalle compterait sa hauteur comme une contremarche.
##
## POURQUOI −1,75 ET PLUS −0,85 (intégration LOT 1.R.1) : la fusion R3 a
## élargi le collider déclaré du cœur (`Sanctuaire_coeur_dalle`, 2,95 × 1,75,
## lacet 12° — `_collisions()` du script du lieu). Dans le couloir de la
## capsule (|x| ≤ 0,40 m), son front atteint 0,98 m du centre ; plus le rayon
## de capsule, le dernier appui légitime est à ≥ 1,38 m, soit z de nef
## −1,73 (échelle 0,80). L'ancien −0,85 faisait marcher la sonde SUR le
## collider de sa propre destination : marche de 0,60 m mesurée, qui n'était
## pas un défaut de la nef. Si le collider regrossit un jour, cette borne en
## dur fait ROUGIR la sonde (le chemin le percute) — jamais passer à tort.
## La garde d'atteinte ci-dessous empêche l'inverse : un chemin raccourci en
## douce cesserait d'arriver à portée d'interaction de l'ancre.
const CHEMIN: Array[Vector2] = [
	Vector2(-0.05, -4.60),
	Vector2(-0.05, -3.00),
	Vector2(-0.10, -2.10),
	Vector2(0.00, -1.75),
]
## Portée d'interaction ORDINAIRE minimale du spec (MASTER_SPEC §14.2 :
## 1,8–2,4 m). Le bout du chemin doit laisser l'ancre de récompense à portée.
const PORTEE_INTERACTION: float = 1.8


## Un point du plan de nef -> le plan LOCAL du lieu. Réplique volontairement
## `_nef()` du script du lieu, avec SES constantes : la sonde ne peut pas
## dériver du lieu sans que le lieu ait changé lui-même.
func _nef_locale(x: float, z: float) -> Vector2:
	var t: float = deg_to_rad(PLACE.NEF_ROT_DEG as float)
	var c: float = cos(t)
	var s: float = sin(t)
	var xx: float = x * (PLACE.NEF_W as float)
	var zz: float = z * (PLACE.NEF_L as float)
	var trans: Vector2 = PLACE.NEF_T as Vector2
	return Vector2(xx * c - zz * s + trans.x, xx * s + zz * c + trans.y)


## La direction LATÉRALE de la nef (son +x), dans le plan local du lieu.
func _nef_travers() -> Vector3:
	var t: float = deg_to_rad(PLACE.NEF_ROT_DEG as float)
	return Vector3(cos(t), 0.0, sin(t))
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
			var loc: Vector2 = _nef_locale(p.x, p.y)
			var monde: Vector3 = lieu.to_global(Vector3(loc.x, 0.0, loc.y))
			var h: float = _sol(space, monde)
			if is_nan(h):
				ecarts.append("aucun sol en nef (%.2f, %.2f)" % [p.x, p.y])
				continue
			echantillons += 1
			if not is_nan(precedent):
				var montee: float = absf(h - precedent)
				marche_max_vue = maxf(marche_max_vue, montee)
				if montee > MARCHE_MAX:
					ecarts.append("marche %.2f m > %.2f en nef (%.2f, %.2f)"
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

	# ---- 2a. L'ANCRE RESTE À PORTÉE DU BOUT DU CHEMIN ----------------------
	# La garde du raccourcissement (LOT 1.R.1) : le chemin s'arrête désormais
	# DEVANT le collider de la table. Un chemin qu'on raccourcit en douce
	# cesserait d'« arriver à la table » sans qu'aucune marche ne rougisse —
	# cette garde le crie. La cote de l'ancre est reconstruite des constantes
	# DÉCLARÉES (`TABLE_DESSUS` − 0,05, la cote du script du lieu) : c'est une
	# borne d'atteinte, pas un test de position d'ancre — celui-là vit dans
	# les suites du lieu.
	var fin_nef: Vector2 = CHEMIN[CHEMIN.size() - 1]
	var fin_loc: Vector2 = _nef_locale(fin_nef.x, fin_nef.y)
	var fin_monde: Vector3 = lieu.to_global(Vector3(fin_loc.x, 0.0, fin_loc.y))
	var sol_fin: float = _sol(space, fin_monde)
	var ancre_loc: Vector2 = _nef_locale(0.0, 0.0)
	var ancre_xz: Vector3 = lieu.to_global(
		Vector3(ancre_loc.x, 0.0, ancre_loc.y))
	var ancre: Vector3 = Vector3(ancre_xz.x,
		hm.height_at(ancre_xz.x, ancre_xz.z)
		+ (PLACE.TABLE_DESSUS as float) - 0.05, ancre_xz.z)
	if is_nan(sol_fin):
		ecarts.append("aucun sol au bout du chemin — atteinte non mesurable")
	else:
		var atteinte: float = Vector3(fin_monde.x, sol_fin, fin_monde.z) \
			.distance_to(ancre)
		print("[sanctuaire] atteinte : le bout du chemin laisse l'ancre à "
			+ "%.2f m (portée d'interaction %.2f m)"
			% [atteinte, PORTEE_INTERACTION])
		if atteinte > PORTEE_INTERACTION:
			ecarts.append("ancre à %.2f m > portée %.2f — le chemin n'arrive "
				% [atteinte, PORTEE_INTERACTION] + "plus à la table")

	# ---- 2b. LARGEUR DU COULOIR --------------------------------------------
	# Un couloir se mesure LATÉRALEMENT, pas au centre : un rayon vertical au
	# milieu de la nef ne rencontre aucun socle et déclarerait « libre » une
	# nef bouchée. On tire donc à hauteur de hanche, de part et d'autre.
	# HISTOIRE DE LA GRANDEUR, en trois états, parce que chacun a mordu :
	#   v1 additionnait les deux tirs SANS les publier — « 3,72 m » voulait
	#   dire « 0,72 d'un côté et rien de l'autre », un nombre juste qui
	#   répondait à une autre question (tools/CLAUDE.md, la platitude mesurée
	#   à la place de la largeur) ;
	#   v2 (correction) exigeait CAPSULE_R du côté le plus étroit DEPUIS
	#   L'AXE — mais une capsule n'est pas clouée à l'axe : le coin tourné du
	#   collider de la table (lacet 12°) pinçait un côté à 0,31 m alors que
	#   l'autre offrait 3 m, et la sonde déclarait infranchissable un couloir
	#   qu'on passe en s'écartant d'un pas (intégration LOT 1.R.1) ;
	#   v3 (ici) : l'intervalle libre est contigu — du premier impact à gauche
	#   au premier impact à droite — donc la capsule passe ssi la FENÊTRE
	#   totale gauche+droite ≥ son diamètre + marge. Les DEUX nombres sont
	#   publiés, et un tir sans impact est plafonné à 3,0 m et dit tel quel :
	#   c'est la leçon de v1 — publier ce qui a été réellement mesuré.
	var etroit: float = INF
	var ou_etroit: float = 0.0
	var fenetre_min: float = INF
	var ou_fenetre: float = 0.0
	# Les stations sont des z du PLAN DE NEF ; le travers est le +x de la nef
	# tourné par θ — tirer LEFT/RIGHT du lieu sur une nef à 45° mesurerait la
	# diagonale des socles, pas la largeur du couloir. La dernière station
	# suit la fin du chemin : −1,20 sondait un point que le chemin ne visite
	# plus (il est DANS le collider de la table).
	for z: float in [-3.20, -2.80, -2.40, -2.00, -1.80]:
		var axe: Vector2 = _nef_locale(0.0, z)
		var centre: Vector3 = lieu.to_global(Vector3(axe.x, 0.0, axe.y))
		var sol_c: float = hm.height_at(centre.x, centre.z)
		# 0,55 m et non 0,95 : à hauteur de hanche le rayon frôlait le sommet
		# des socles de 0,97 m et pouvait les rater. On tire à mi-socle.
		var origine: Vector3 = Vector3(centre.x, sol_c + 0.55, centre.z)
		var travers: Vector3 = _nef_travers()
		var fenetre: float = 0.0
		for direction: Vector3 in [travers, -travers]:
			var monde_dir: Vector3 = lieu.global_transform.basis * direction
			var tir: Dictionary = space.intersect_ray(
				PhysicsRayQueryParameters3D.create(
					origine, origine + monde_dir * 3.0, 1))
			var degagement: float = 3.0
			if not tir.is_empty():
				degagement = origine.distance_to(tir["position"] as Vector3)
			fenetre += degagement
			if degagement < etroit:
				etroit = degagement
				ou_etroit = z
		if fenetre < fenetre_min:
			fenetre_min = fenetre
			ou_fenetre = z
	print("[sanctuaire] couloir : fenêtre libre minimale %.2f m à z de nef "
		% fenetre_min + "%.2f ; dégagement minimal d'un côté %.2f m à %.2f "
		% [ou_fenetre, etroit, ou_etroit]
		+ "(tirs plafonnés à 3,0 m, diamètre de capsule %.2f m)"
		% (CAPSULE_R * 2.0))
	if fenetre_min < 2.0 * (CAPSULE_R + 0.05):
		ecarts.append("fenêtre libre de %.2f m à z de nef %.2f — la capsule "
			% [fenetre_min, ou_fenetre] + "ne passe pas")

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
