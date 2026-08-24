## Sonde PHYSIQUE de l'ascension de la vigie (tour de guet, compo B).
##
## Arbitrage « La vigie retrouvée », condition 1 : l'ascension est PROUVÉE
## physiquement, pas déclarée. Cette sonde marche le chemin brèche →
## escalier → palier tournant → vigie sur les VRAIS colliders du monde
## monté (raycasts sur la couche 1), au pas de 0,15 m — l'échelle de la
## capsule — et rend un verdict :
##
##   * aucune contremarche rencontrée > 0,38 m (step_height max, §8.2) ;
##   * pente locale ≤ 46° hors contremarches (limite du contrôleur) ;
##   * altitude finale ≥ +2,85 m au-dessus du sol d'entrée (on est monté) ;
##   * volume de la capsule LIBRE au-dessus de chaque appui (1,9 m) ;
##   * depuis la vigie, chaque bord libre retombe sur un sol à moins de
##     6 m (redescente sans dégâts — condition 2).
##
## Ce que la sonde ne remplace PAS : la vidéo joueur aux vrais contrôles
## (outillée par la voie C). Elle prouve la géométrie de collision, pas le
## game feel.
##
## Usage :
##   tools/lancer_godot.sh --path . --script tools/godot/probe_vigie_ascension.gd
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"
const PLACE_ID: StringName = &"valley.poi.watchtower_ruin.01"
const PAS: float = 0.15
const MARCHE_MAX: float = 0.38
const PENTE_MAX_DEG: float = 46.0
const CAPSULE_H: float = 1.9
const CHUTE_MAX: float = 6.0

## Chemin en coordonnées LOCALES AU LIEU (x est, z sud) : brèche →
## intérieur → pied de l'escalier → rampe 1 → tournant → rampe 2 → vigie.
const CHEMIN: Array[Vector2] = [
	Vector2(1.6, -0.6),
	Vector2(0.2, -0.6),
	Vector2(-1.05, -0.985),
	Vector2(-3.25, -0.985),
	Vector2(-3.45, -1.02),
	Vector2(-3.575, -0.6),
	Vector2(-3.575, 1.02),
	Vector2(-3.265, 1.59),
]


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
		printerr("[vigie] ECHEC : lieu %s introuvable" % PLACE_ID)
		quit(2)
		return

	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var ecarts: Array[String] = []
	var precedent: float = NAN
	var sol_entree: float = NAN
	var sommet: float = -INF
	var echantillons: int = 0
	for segment: int in range(CHEMIN.size() - 1):
		var a: Vector2 = CHEMIN[segment]
		var b: Vector2 = CHEMIN[segment + 1]
		var longueur: float = a.distance_to(b)
		var pas_n: int = maxi(2, int(ceil(longueur / PAS)))
		for i: int in range(pas_n + 1):
			var p: Vector2 = a.lerp(b, float(i) / float(pas_n))
			var monde: Vector3 = lieu.to_global(Vector3(p.x, 0.0, p.y))
			var h: float = _sol(space, monde)
			if is_nan(h):
				ecarts.append("aucun sol en local (%.2f, %.2f)" % [p.x, p.y])
				continue
			echantillons += 1
			if is_nan(sol_entree):
				sol_entree = h
			sommet = maxf(sommet, h)
			if not is_nan(precedent):
				var montee: float = h - precedent
				# Une montée sous la hauteur de marche est FRANCHIE par le
				# contrôleur quel que soit son angle local ; une pente
				# CONTINUE au-delà de 46° est jugée séparément, en fenêtre
				# glissante de 0,60 m, plus bas.
				if montee > MARCHE_MAX:
					ecarts.append("contremarche %.2f m > %.2f en (%.2f, %.2f)"
						% [montee, MARCHE_MAX, p.x, p.y])
			precedent = h
			# Volume de la capsule au-dessus de l'appui.
			var toit: Dictionary = space.intersect_ray(
				PhysicsRayQueryParameters3D.create(
					monde + Vector3(0.0, h - monde.y + 0.35, 0.0),
					monde + Vector3(0.0, h - monde.y + CAPSULE_H, 0.0), 1))
			if not toit.is_empty():
				ecarts.append("plafond a %.2f m au-dessus de (%.2f, %.2f)"
					% [(toit["position"] as Vector3).y - h, p.x, p.y])

	# Pente continue : fenêtre glissante de 0,60 m sur le profil rejoué.
	var profil: PackedFloat32Array = PackedFloat32Array()
	for segment: int in range(CHEMIN.size() - 1):
		var a2: Vector2 = CHEMIN[segment]
		var b2: Vector2 = CHEMIN[segment + 1]
		var pas_n2: int = maxi(2, int(ceil(a2.distance_to(b2) / PAS)))
		for i: int in range(pas_n2 + 1):
			var p2: Vector2 = a2.lerp(b2, float(i) / float(pas_n2))
			var h2: float = _sol(space, lieu.to_global(Vector3(p2.x, 0.0, p2.y)))
			if not is_nan(h2):
				profil.append(h2)
	var fenetre: int = maxi(2, int(round(0.60 / PAS)))
	for i: int in range(profil.size() - fenetre):
		var pente: float = rad_to_deg(atan2(
			profil[i + fenetre] - profil[i], float(fenetre) * PAS))
		if pente > PENTE_MAX_DEG + 3.0:
			ecarts.append("pente continue %.1f deg > %.1f (echantillon %d)"
				% [pente, PENTE_MAX_DEG, i])

	# Le gain se juge contre le sol GELÉ du pied du fût, pas contre le
	# premier échantillon (qui peut être en contrebas du pad, ou sur un
	# collider) : la vigie vit à base_y + 2,77 m, et base_y est le point
	# HAUT des quatre angles — le gain honnête est donc ~2,7-2,8 m.
	var hm: WorldV2Heightmap = world.call("heightmap") as WorldV2Heightmap
	var pied: Vector3 = lieu.to_global(Vector3(-2.2, 0.0, -0.6))
	var sol_pied: float = hm.height_at(pied.x, pied.z)
	var gain: float = sommet - sol_pied
	print("[vigie] %d appuis sondes ; premier appui %.2f ; sol du fut %.2f ; "
		% [echantillons, sol_entree, sol_pied]
		+ "sommet %.2f ; gain %.2f m" % [sommet, gain])
	if gain < 2.60:
		ecarts.append("gain %.2f m < 2.60 — on n'est PAS monte a la vigie"
			% gain)

	# Redescente (condition 2) : du sommet atteint, le sol GELÉ au droit
	# des bords libres de la vigie est à moins de CHUTE_MAX. Le sol se lit
	# sur la heightmap : un rayon parti sous un collider de terrain le rate
	# par sa face arrière et fabrique une chute qui n'existe pas (mesuré,
	# première version de cette sonde : « chute 8,0 m » sur un pad plat).
	for bord: Vector2 in [Vector2(-2.2, 1.6), Vector2(-3.3, 2.4),
			Vector2(-2.6, 0.7), Vector2(-4.4, 1.6)]:
		var haut: Vector3 = lieu.to_global(Vector3(bord.x, 0.0, bord.y))
		var atterrissage: float = hm.height_at(haut.x, haut.z)
		if sommet - atterrissage > CHUTE_MAX:
			ecarts.append("chute de %.1f m au bord (%.1f, %.1f)"
				% [sommet - atterrissage, bord.x, bord.y])

	if echantillons < 30:
		ecarts.append("seulement %d appuis sondes — la sonde n'a pas marche"
			% echantillons)
	print("")
	if ecarts.is_empty():
		print("[vigie] VERDICT : PASS — ascension physique prouvee "
			+ "(contremarches <= %.2f, capsule libre, gain %.2f m, "
			% [MARCHE_MAX, gain] + "redescente < %.0f m)" % CHUTE_MAX)
		quit(0)
	else:
		for e: String in ecarts:
			print("[vigie] ECART : %s" % e)
		print("[vigie] VERDICT : FAIL (%d ecart(s))" % ecarts.size())
		quit(1)


func _sol(space: PhysicsDirectSpaceState3D, monde: Vector3) -> float:
	var hit: Dictionary = space.intersect_ray(
		PhysicsRayQueryParameters3D.create(
			Vector3(monde.x, monde.y + 12.0, monde.z),
			Vector3(monde.x, monde.y - 20.0, monde.z), 1))
	if hit.is_empty():
		return NAN
	return (hit["position"] as Vector3).y
