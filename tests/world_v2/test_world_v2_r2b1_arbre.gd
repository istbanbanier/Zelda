## V2.3-A.R2B.1 — FILET PROPRE DE L'ARBRE FOUDROYÉ (agent B).
##
## POURQUOI CE FICHIER EXISTE, ET POURQUOI IL EST SÉPARÉ.
## `test_world_v2_r2b_farm_tree.gd` couvre la ferme ET l'arbre, et la ferme
## appartient à une autre session qui travaille en parallèle. Toucher ce
## filet partagé, c'est fabriquer un conflit d'intégration pour rien. Il
## reste donc octet pour octet identique ; tout ce qui suit vit ici.
##
## CE QUE LE LEAD A REJETÉ, ET LA MESURE QUI L'EXPLIQUE (GLB r02, 977 tris) :
##  * « un pilier noir polygonal » — l'emprise latérale au-dessus de la
##    fourche vaut 2,32 m au pire azimut contre 4,20 m au meilleur. Cause :
##    `chemin_vivant`/`chemin_mort` divergeaient de 3,59 m en X pour 0,57 m
##    en Y, soit un plan de fourche à 9°. Les caméras de preuve du lead sont
##    à −31° : à 22° du plan, les deux moitiés se superposent presque.
##  * « manque de tapering » — rayons affines exacts : résidu d'ajustement
##    linéaire 3,2 %, ZÉRO renflement de collet.
##  * « pied très massif » — profil de souche rectiligne : concavité
##    −0,027 m (le pied bombe au lieu de se creuser).
##  * « étoile de planches » — bord du disque brûlé = deux harmoniques
##    pures, rmax/rmin = 2,13, 30 secteurs depuis un seul sommet.
##  * « branches au sol plates et identiques » — rayon 0,162 IDENTIQUE,
##    dénivelé bout-à-bout 0,054 m pour les deux.
##  * « bande blanche droite peinte » — largeur du ruban de cicatrice de
##    coefficient de variation 0,12.
##
## LA CIME VIVANTE RESTE VIVANTE (arbitrage du lead) : le détecteur de
## rupture exige du CŒUR PÂLE au bout de la composante ET un diamètre de
## fût ≥ 0,55 m. Une pointe intacte n'a ni l'un ni l'autre — elle n'est
## donc jamais comptée, et rien ici ne pousse à casser le sommet vivant.
##
## MÉTHODE. Tout est mesuré sur le GLB EXPORTÉ et sur le lieu MONTÉ, jamais
## sur les constantes du générateur : un test qui relit les constantes qui
## ont produit la géométrie compare une constante à elle-même et ne peut
## pas rougir. L'identité des pièces vient d'une SOUDURE des sommets au
## millimètre suivie d'une union-find sur les triangles — l'exporteur glTF
## dédouble les sommets par normale (1 249 sommets pour 340 sommets
## Blender), donc une union-find sur les indices bruts éclaterait en une
## composante par face. La soudure restitue la topologie de Blender.
class_name TestWorldV2R2B1Arbre
extends GateTestCase

const TREE_GLB: String = "res://assets/architecture/flora/SM_ThunderstruckTree.glb"
const TREE_SCENE: String = "res://scenes/world_v2/poi/ThunderstruckTreePlace.tscn"

## Seuils. Chacun est accompagné de la valeur MESURÉE sur le r02 rejeté,
## pour qu'on voie d'un coup d'œil que l'assertion rougit aujourd'hui.
const OPEN_MIN_M: float = 3.60          # r02 : 2,316
const OPEN_ANISO_MAX: float = 1.35      # r02 : 1,812
const BREAK_MIN: int = 2                # r02 : 1
const BREAK_GAP_MIN_M: float = 1.50     # r02 : 0,00 (une seule rupture)
const BREAK_DIA_MIN_M: float = 0.55
const TAPER_RESIDUAL_MIN: float = 0.07  # r02 : 0,032
const TAPER_SWELL_MIN: int = 2          # r02 : 0
const STUMP_CONCAVE_MIN_M: float = 0.06 # r02 : −0,027
const SPUR_GAP_MIN_DEG: float = 20.0    # r02 : 2,1
const SPUR_GAP_RATIO_MAX: float = 2.60  # r02 : 129,1
const SPUR_GAP_RATIO_MIN: float = 1.25  # borne basse : interdit l'étoile RÉGULIÈRE
const FALLEN_MIN: int = 4               # r02 : 2
const FALLEN_LEN_RATIO_MIN: float = 1.80  # r02 : 1,25
const FALLEN_RAD_RATIO_MIN: float = 1.60  # r02 : 1,00
const FALLEN_TILT_MIN_M: float = 0.35     # r02 : 0,054
const SCAR_CV_MIN: float = 0.30         # r02 : 0,122
const SPLINTER_PLANES_MIN: int = 2      # r02 : 1
const SCORCH_LOBE_RATIO_MAX: float = 1.55   # r02 : 2,13
const SCORCH_HARMONIC_MAX: float = 0.45     # r02 : ≈ 1,00
const SCORCH_AREA_MAX_M2: float = 24.0      # r02 : 34,5
## 8e portail — LA MASSE SOMBRE AU SOL, tous éléments confondus. Ajouté
## après coup : j'avais SIGNALÉ au lead que les contreforts-racines se
## lisaient comme des plaques et refaisaient, avec les bois tombés, une
## masse radiale au pied — et aucun des sept portails ne la mesurait. La
## mesure m'a DÉMENTI (39,3 -> 30,5 m², raie dominante 58 % -> 20 %),
## mais un défaut vu que rien ne mesure revient à la passe suivante.
const GROUND_AREA_MAX_M2: float = 34.0      # r02 : 39,3 ; R2B.1 : 30,5
const GROUND_STUMP_RATIO_MAX: float = 20.0  # r02 : 24,8 ; R2B.1 : 15,6
const GROUND_HARMONIC_MAX: float = 0.45     # r02 : 0,58 ; R2B.1 : 0,20


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _capped(faults: Array[String], keep: int = 6) -> String:
	if faults.is_empty():
		return "aucun écart"
	if faults.size() <= keep:
		return ", ".join(faults)
	return ", ".join(faults.slice(0, keep)) + " (+%d autre(s))" % (faults.size() - keep)


## ---------------------------------------------------------------------------
## Lecture du GLB : sommets monde par nœud, puis composantes connexes.
## ---------------------------------------------------------------------------
func _glb_nodes() -> Dictionary:
	var out: Dictionary = {}
	var packed: PackedScene = load(TREE_GLB) as PackedScene
	if packed == null:
		return out
	var root: Node3D = packed.instantiate() as Node3D
	if root == null:
		return out
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh == null:
			continue
		var verts: PackedVector3Array = PackedVector3Array()
		var idx: PackedInt32Array = PackedInt32Array()
		for s: int in range(mi.mesh.get_surface_count()):
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var base: int = verts.size()
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			for v: Vector3 in vs:
				verts.append(mi.transform * v)
			var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			for i: int in ix:
				idx.append(i + base)
		out[String(mi.name)] = {"v": verts, "i": idx}
	root.free()
	return out


## Soudure au millimètre + union-find. Rend un Array de PackedVector3Array,
## trié du plus haut sommet au plus bas.
func _components(verts: PackedVector3Array, idx: PackedInt32Array) -> Array:
	var key: Dictionary = {}
	var rep: PackedInt32Array = PackedInt32Array()
	for v: Vector3 in verts:
		var k: String = "%d|%d|%d" % [roundi(v.x * 1000.0), roundi(v.y * 1000.0),
			roundi(v.z * 1000.0)]
		if not key.has(k):
			key[k] = key.size()
		rep.append(int(key[k]))
	var par: PackedInt32Array = PackedInt32Array()
	par.resize(key.size())
	for i: int in range(key.size()):
		par[i] = i
	# Union-find SANS lambda : une `Callable` capture les variables locales PAR
	# VALEUR. Première version de ce fichier : `find` était un Callable qui
	# capturait `par` ; les fusions écrivaient dans le `par` extérieur pendant
	# que la recherche lisait une copie figée. Résultat : chaque sommet restait
	# sa propre composante, l'écorce se découpait en un millier de miettes, et
	# trois contrôles plantaient au lieu de mesurer. Le piège est silencieux —
	# aucune erreur, juste un résultat faux.
	for t: int in range(0, idx.size() - 2, 3):
		for pair: Vector2i in [Vector2i(idx[t], idx[t + 1]),
				Vector2i(idx[t + 1], idx[t + 2])]:
			var ra: int = rep[pair.x]
			while par[ra] != ra:
				par[ra] = par[par[ra]]
				ra = par[ra]
			var rb: int = rep[pair.y]
			while par[rb] != rb:
				par[rb] = par[par[rb]]
				rb = par[rb]
			if ra != rb:
				par[ra] = rb
	# DEUXIÈME PIÈGE SILENCIEUX, mesuré : un `PackedVector3Array` est un type
	# VALEUR. `buckets[r].append(v)` appende sur une COPIE rendue par l'index,
	# et l'écriture est jetée sans la moindre erreur. La sonde le montrait
	# net : 6 composantes trouvées pour l'écorce — le bon compte — mais
	# toutes de taille 0. Un `Array` est en revanche un type RÉFÉRENCE : on
	# accumule donc dans des `Array`, et on ne convertit qu'à la fin.
	var groups: Array = []
	var slot: Dictionary = {}
	for i2: int in range(verts.size()):
		var r2: int = rep[i2]
		while par[r2] != r2:
			r2 = par[r2]
		if not slot.has(r2):
			slot[r2] = groups.size()
			groups.append([])
		(groups[int(slot[r2])] as Array).append(verts[i2])
	var comps: Array = []
	for gr: Array in groups:
		var packed_group: PackedVector3Array = PackedVector3Array()
		for v2: Vector3 in gr:
			packed_group.append(v2)
		comps.append(packed_group)
	comps.sort_custom(func(a: PackedVector3Array, b: PackedVector3Array) -> bool:
		return _top(a) > _top(b))
	return comps


func _top(vs: PackedVector3Array) -> float:
	var m: float = -1.0e9
	for v: Vector3 in vs:
		m = maxf(m, v.y)
	return m


func _bottom(vs: PackedVector3Array) -> float:
	var m: float = 1.0e9
	for v: Vector3 in vs:
		m = minf(m, v.y)
	return m


func _centroid(vs: PackedVector3Array) -> Vector3:
	var c: Vector3 = Vector3.ZERO
	for v: Vector3 in vs:
		c += v
	return c / maxf(1.0, float(vs.size()))


func _median(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	values.sort()
	return values[values.size() / 2]


## -- 1. La silhouette s'ouvre sous TOUT azimut ------------------------------
##
## LE CONTRÔLE PORTAIL. Le défaut « pilier noir » n'est pas un défaut de
## détail : c'est un plan de fourche unique. Deux moitiés qui divergent dans
## un seul plan se superposent exactement quand la caméra regarde DANS ce
## plan, et l'arbre redevient un trait. On mesure donc l'emprise latérale
## sous 24 azimuts et on exige un plancher ET une isotropie.
func test_l_arbre_ouvre_sa_silhouette_sous_tout_azimut() -> void:
	var faults: Array[String] = []
	var nodes: Dictionary = _glb_nodes()
	var high: PackedVector3Array = PackedVector3Array()
	for name: String in nodes.keys():
		if name.contains("Branch") or name.contains("Roots"):
			continue    # les bois au sol et les racines ne portent pas la cime
		for v: Vector3 in (nodes[name] as Dictionary)["v"] as PackedVector3Array:
			if v.y > 2.6:
				high.append(v)
	if high.size() < 50:
		faults.append("moins de 50 sommets au-dessus de la fourche — GLB illisible")
	else:
		var worst: float = 1.0e9
		var best: float = 0.0
		var worst_az: float = 0.0
		for k: int in range(24):
			var th: float = deg_to_rad(float(k) * 15.0)
			var ux: float = -sin(th)
			var uz: float = cos(th)
			var lo: float = 1.0e9
			var hi: float = -1.0e9
			for v: Vector3 in high:
				var u: float = v.x * ux + v.z * uz
				lo = minf(lo, u)
				hi = maxf(hi, u)
			var span: float = hi - lo
			if span < worst:
				worst = span
				worst_az = float(k) * 15.0
			best = maxf(best, span)
		var aniso: float = best / maxf(0.01, worst)
		if worst < OPEN_MIN_M:
			faults.append("emprise latérale %.2f m au pire azimut (%.0f°), plancher %.2f"
				% [worst, worst_az, OPEN_MIN_M])
		if aniso > OPEN_ANISO_MAX:
			faults.append("anisotropie %.2f (pire %.2f m / meilleur %.2f m), plafond %.2f"
				% [aniso, worst, best, OPEN_ANISO_MAX])
	check(faults.is_empty(),
		"la silhouette de l'arbre s'ouvre sous les 24 azimuts (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])


## -- 2. Deux ruptures principales, à des hauteurs franchement différentes ----
##
## Une rupture principale, c'est la FIN d'une grosse pièce d'écorce avec du
## cœur pâle au bout et une crête dentelée. Le diamètre minimal écarte les
## moignons ; l'exigence de cœur écarte une pointe intacte. La cime vivante
## reste donc libre d'être une pointe : ce test ne la réclame jamais.
func test_deux_ruptures_principales_a_des_hauteurs_differentes() -> void:
	var faults: Array[String] = []
	var nodes: Dictionary = _glb_nodes()
	var bark: Dictionary = nodes.get("SM_ThunderstruckTree_Bark", {}) as Dictionary
	var heart: Dictionary = nodes.get("SM_ThunderstruckTree_Heart", {}) as Dictionary
	if bark.is_empty() or heart.is_empty():
		faults.append("écorce ou cœur absent du GLB")
	else:
		var hv: PackedVector3Array = heart["v"] as PackedVector3Array
		var comps: Array = _components(bark["v"] as PackedVector3Array,
			bark["i"] as PackedInt32Array)
		var heights: Array[float] = []
		for comp: PackedVector3Array in comps:
			var top: float = _top(comp)
			var rim: PackedVector3Array = PackedVector3Array()
			var body: PackedVector3Array = PackedVector3Array()
			for v: Vector3 in comp:
				if v.y > top - 0.9:
					rim.append(v)
				if v.y < top - 0.6 and v.y > top - 1.6:
					body.append(v)
			if rim.size() < 6 or body.size() < 6:
				continue
			var rc: Vector3 = _centroid(rim)
			var bc: Vector3 = _centroid(body)
			var radii: Array[float] = []
			for v: Vector3 in body:
				radii.append(Vector2(v.x - bc.x, v.z - bc.z).length())
			var dia: float = 2.0 * _median(radii)
			# LE PLAN DE RUPTURE, PAS LE SOMMET DE LA PIÈCE. Premier jet :
			# on retenait `top`, c'est-à-dire la pointe la plus haute de la
			# couronne d'échardes. Deux cassures situées à 5,90 et 7,55 m —
			# 1,65 m d'écart — ressortaient alors espacées de 0,92 m, parce
			# que la longueur des échardes s'ajoutait à la hauteur de
			# cassure et que les deux variables se compensaient. Le bas du
			# bois mis à nu EST la face de cassure : c'est lui qu'on lit.
			var pale: int = 0
			var face: float = 1.0e9
			for w: Vector3 in hv:
				if absf(w.y - top) < 1.6 \
						and Vector2(w.x - rc.x, w.z - rc.z).length() < 0.9:
					pale += 1
					face = minf(face, w.y)
			# crête dentelée : dispersion des hauteurs max par secteur de 30°
			var sector: Dictionary = {}
			for v: Vector3 in rim:
				var s: int = int(fposmod(rad_to_deg(atan2(v.z - rc.z, v.x - rc.x)),
					360.0) / 30.0)
				sector[s] = maxf(sector.get(s, -9.0e9), v.y)
			if sector.size() < 3:
				continue
			var mean: float = 0.0
			for s2: int in sector.keys():
				mean += sector[s2]
			mean /= float(sector.size())
			var sd: float = 0.0
			for s3: int in sector.keys():
				sd += pow(sector[s3] - mean, 2.0)
			sd = sqrt(sd / float(sector.size()))
			if pale > 0 and dia >= BREAK_DIA_MIN_M and sd >= 0.15:
				heights.append(face)
		if heights.size() < BREAK_MIN:
			faults.append("%d rupture(s) principale(s), plancher %d"
				% [heights.size(), BREAK_MIN])
		else:
			heights.sort()
			var gap: float = heights[heights.size() - 1] - heights[0]
			if gap < BREAK_GAP_MIN_M:
				faults.append("ruptures espacées de %.2f m seulement, plancher %.2f"
					% [gap, BREAK_GAP_MIN_M])
	check(faults.is_empty(),
		"deux ruptures principales à des hauteurs différentes (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])


## -- 3. Le fût n'est pas un cône, le pied n'est pas un tronc de cône --------
func test_le_fut_n_est_pas_un_cone() -> void:
	var faults: Array[String] = []
	var nodes: Dictionary = _glb_nodes()
	var bark: Dictionary = nodes.get("SM_ThunderstruckTree_Bark", {}) as Dictionary
	if bark.is_empty():
		faults.append("écorce absente du GLB")
	else:
		var comps: Array = _components(bark["v"] as PackedVector3Array,
			bark["i"] as PackedInt32Array)
		var live: PackedVector3Array = comps[0] as PackedVector3Array
		var apex: Vector3 = Vector3.ZERO
		var foot: Vector3 = Vector3(0.0, 1.0e9, 0.0)
		for v: Vector3 in live:
			if v.y > apex.y:
				apex = v
			if v.y < foot.y:
				foot = v
		var zs: Array[float] = []
		var rs: Array[float] = []
		for k: int in range(12):
			var h: float = foot.y + 0.6 + 0.72 * float(k)
			if h > apex.y - 0.4:
				break
			var t: float = (h - foot.y) / maxf(0.01, apex.y - foot.y)
			var cx: float = foot.x + t * (apex.x - foot.x)
			var cz: float = foot.z + t * (apex.z - foot.z)
			var dd: Array[float] = []
			for v: Vector3 in live:
				if absf(v.y - h) < 0.22:
					dd.append(Vector2(v.x - cx, v.z - cz).length())
			if dd.size() < 6:
				continue
			zs.append(h)
			rs.append(_median(dd))
		if zs.size() < 5:
			faults.append("moins de 5 tranches exploitables sur le fût vivant")
		else:
			var n: float = float(zs.size())
			var sx: float = 0.0
			var sy: float = 0.0
			var sxx: float = 0.0
			var sxy: float = 0.0
			for i: int in range(zs.size()):
				sx += zs[i]
				sy += rs[i]
				sxx += zs[i] * zs[i]
				sxy += zs[i] * rs[i]
			var a: float = (n * sxy - sx * sy) / maxf(1.0e-6, n * sxx - sx * sx)
			var b: float = (sy - a * sx) / n
			var rms: float = 0.0
			for i: int in range(zs.size()):
				rms += pow(rs[i] - (a * zs[i] + b), 2.0)
			rms = sqrt(rms / n)
			var ratio: float = rms / maxf(1.0e-6, sy / n)
			var swells: int = 0
			for i: int in range(1, rs.size()):
				if rs[i] > rs[i - 1]:
					swells += 1
			if ratio < TAPER_RESIDUAL_MIN:
				faults.append("fût affine : résidu %.3f du rayon moyen, plancher %.2f"
					% [ratio, TAPER_RESIDUAL_MIN])
			if swells < TAPER_SWELL_MIN:
				faults.append("%d renflement(s) de collet, plancher %d"
					% [swells, TAPER_SWELL_MIN])
		# concavité de la souche : la composante la plus basse
		var stump: PackedVector3Array = comps[comps.size() - 1] as PackedVector3Array
		var base_y: float = _bottom(stump)
		var head_y: float = _top(stump)
		var prof: Array[float] = []
		for frac: float in [0.05, 0.5, 0.95]:
			var h2: float = base_y + (head_y - base_y) * frac
			var dd2: Array[float] = []
			for v: Vector3 in stump:
				if absf(v.y - h2) < 0.12:
					dd2.append(Vector2(v.x, v.z).length())
			prof.append(_median(dd2))
		var concave: float = (prof[0] + prof[2]) * 0.5 - prof[1]
		if concave < STUMP_CONCAVE_MIN_M:
			faults.append("souche rectiligne ou bombée : concavité %.3f m, plancher %.2f"
				% [concave, STUMP_CONCAVE_MIN_M])
	check(faults.is_empty(),
		"le fût s'affine et le pied se creuse (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])


## -- 4. Les saillies latérales ne forment ni grappe ni étoile ---------------
##
## Deux bornes, pas une. Le plafond interdit la GRAPPE (deux moignons à
## 2,1° l'un de l'autre sur le r02) ; le plancher interdit l'ÉTOILE
## RÉGULIÈRE, qui est le défaut nommé par le lead. Un contrôle qui n'aurait
## que le plafond pousserait vers l'écartement uniforme, c'est-à-dire vers
## le défaut qu'on cherche à supprimer.
func test_les_saillies_ne_forment_ni_grappe_ni_etoile() -> void:
	var faults: Array[String] = []
	var nodes: Dictionary = _glb_nodes()
	var bark: Dictionary = nodes.get("SM_ThunderstruckTree_Bark", {}) as Dictionary
	if bark.is_empty():
		faults.append("écorce absente du GLB")
	else:
		var comps: Array = _components(bark["v"] as PackedVector3Array,
			bark["i"] as PackedInt32Array)
		var live: PackedVector3Array = comps[0] as PackedVector3Array
		var apex: Vector3 = Vector3.ZERO
		var foot: Vector3 = Vector3(0.0, 1.0e9, 0.0)
		for v: Vector3 in live:
			if v.y > apex.y:
				apex = v
			if v.y < foot.y:
				foot = v
		var az: Array[float] = []
		for comp: PackedVector3Array in comps:
			# Classification par TAILLE, pas par nombre de sommets : le
			# nombre de sommets dépend du dédoublement de l'exporteur, la
			# taille non. Les grosses pièces (fût vivant, moitié morte,
			# souche) partent de la fourche ou du sol et sont écartées par
			# leur base ; ce qui reste est bien une saillie latérale.
			if _bottom(comp) < 3.0:
				continue
			var aabb: AABB = AABB(comp[0], Vector3.ZERO)
			for v: Vector3 in comp:
				aabb = aabb.expand(v)
			# 4,2 m : la branche maîtresse arrachée est une saillie latérale
			# à part entière, et sa couronne rompue lui donne une diagonale
			# de 3,6 m. Le plafond ne sert qu'à écarter le fût et la moitié
			# morte — que la borne de base (z ≥ 3,0) écarte déjà, sur le r02
			# comme ici : le ROUGE de référence est inchangé par ce réglage.
			if aabb.size.length() > 4.2:
				continue
			var c: Vector3 = _centroid(comp)
			var t: float = (c.y - foot.y) / maxf(0.01, apex.y - foot.y)
			var cx: float = foot.x + t * (apex.x - foot.x)
			var cz: float = foot.z + t * (apex.z - foot.z)
			az.append(fposmod(rad_to_deg(atan2(c.z - cz, c.x - cx)), 360.0))
		if az.size() < 3:
			faults.append("%d saillie(s) latérale(s) détectée(s) — attendu au moins 3"
				% az.size())
		else:
			az.sort()
			var gaps: Array[float] = []
			for i: int in range(az.size()):
				gaps.append(fposmod(az[(i + 1) % az.size()] - az[i], 360.0))
			var gmin: float = gaps[0]
			var gmax: float = gaps[0]
			for gg: float in gaps:
				gmin = minf(gmin, gg)
				gmax = maxf(gmax, gg)
			var ratio: float = gmax / maxf(0.1, gmin)
			if gmin < SPUR_GAP_MIN_DEG:
				faults.append("deux saillies à %.1f° l'une de l'autre, plancher %.0f°"
					% [gmin, SPUR_GAP_MIN_DEG])
			if ratio > SPUR_GAP_RATIO_MAX:
				faults.append("saillies en grappe : écarts max/min %.1f, plafond %.1f"
					% [ratio, SPUR_GAP_RATIO_MAX])
			if ratio < SPUR_GAP_RATIO_MIN:
				faults.append("saillies en étoile régulière : écarts max/min %.2f, "
					% ratio + "plancher %.2f" % SPUR_GAP_RATIO_MIN)
	check(faults.is_empty(),
		"les saillies ne forment ni grappe ni étoile (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])


## -- 5. Les bois tombés sont hiérarchisés ----------------------------------
func test_les_bois_tombes_sont_hierarchises() -> void:
	var faults: Array[String] = []
	var nodes: Dictionary = _glb_nodes()
	var lens: Array[float] = []
	var rads: Array[float] = []
	var tilt_max: float = 0.0
	var count: int = 0
	for name: String in nodes.keys():
		if not name.contains("Branch"):
			continue
		count += 1
		var spec: Dictionary = nodes[name] as Dictionary
		var comps: Array = _components(spec["v"] as PackedVector3Array,
			spec["i"] as PackedInt32Array)
		var log_piece: PackedVector3Array = comps[0] as PackedVector3Array
		for comp: PackedVector3Array in comps:
			if comp.size() > log_piece.size():
				log_piece = comp
		var aabb: AABB = AABB(log_piece[0], Vector3.ZERO)
		for v: Vector3 in log_piece:
			aabb = aabb.expand(v)
		lens.append(Vector2(aabb.size.x, aabb.size.z).length())
		rads.append(aabb.size.y * 0.5)
		# dénivelé bout à bout, le long du plus grand axe horizontal
		var axis: Vector2 = Vector2(aabb.size.x, aabb.size.z).normalized()
		var lo_u: float = 1.0e9
		var hi_u: float = -1.0e9
		for v: Vector3 in log_piece:
			var u: float = v.x * axis.x + v.z * axis.y
			lo_u = minf(lo_u, u)
			hi_u = maxf(hi_u, u)
		var band: float = (hi_u - lo_u) * 0.18
		var lo_sum: float = 0.0
		var lo_n: float = 0.0
		var hi_sum: float = 0.0
		var hi_n: float = 0.0
		for v: Vector3 in log_piece:
			var u2: float = v.x * axis.x + v.z * axis.y
			if u2 < lo_u + band:
				lo_sum += v.y
				lo_n += 1.0
			elif u2 > hi_u - band:
				hi_sum += v.y
				hi_n += 1.0
		if lo_n > 0.0 and hi_n > 0.0:
			tilt_max = maxf(tilt_max, absf(hi_sum / hi_n - lo_sum / lo_n))
	if count < FALLEN_MIN:
		faults.append("%d bois tombé(s), plancher %d" % [count, FALLEN_MIN])
	if lens.size() >= 2:
		lens.sort()
		rads.sort()
		var lr: float = lens[lens.size() - 1] / maxf(0.01, lens[0])
		var rr: float = rads[rads.size() - 1] / maxf(0.001, rads[0])
		if lr < FALLEN_LEN_RATIO_MIN:
			faults.append("longueurs trop proches : max/min %.2f, plancher %.2f"
				% [lr, FALLEN_LEN_RATIO_MIN])
		if rr < FALLEN_RAD_RATIO_MIN:
			faults.append("épaisseurs trop proches : max/min %.2f, plancher %.2f"
				% [rr, FALLEN_RAD_RATIO_MIN])
	if tilt_max < FALLEN_TILT_MIN_M:
		faults.append("aucun bois appuyé : dénivelé bout-à-bout max %.3f m, plancher %.2f"
			% [tilt_max, FALLEN_TILT_MIN_M])
	check(faults.is_empty(),
		"les bois tombés sont hiérarchisés et au moins un est appuyé (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])


## -- 6. La fracture est du bois arraché, pas une bande peinte --------------
func test_la_fracture_est_du_bois_arrache() -> void:
	var faults: Array[String] = []
	var nodes: Dictionary = _glb_nodes()
	var heart: Dictionary = nodes.get("SM_ThunderstruckTree_Heart", {}) as Dictionary
	if heart.is_empty():
		faults.append("cœur absent du GLB")
	else:
		var comps: Array = _components(heart["v"] as PackedVector3Array,
			heart["i"] as PackedInt32Array)
		var scar: PackedVector3Array = comps[0] as PackedVector3Array
		for comp: PackedVector3Array in comps:
			if comp.size() > scar.size():
				scar = comp
		var y0: float = _bottom(scar)
		var y1: float = _top(scar)
		var widths: Array[float] = []
		for k: int in range(12):
			var h: float = y0 + (y1 - y0) * (0.06 + 0.88 * float(k) / 11.0)
			var slice: PackedVector3Array = PackedVector3Array()
			for v: Vector3 in scar:
				if absf(v.y - h) < 0.16:
					slice.append(v)
			if slice.size() < 4:
				continue
			var c: Vector3 = _centroid(slice)
			var w: float = 0.0
			for v: Vector3 in slice:
				w = maxf(w, Vector2(v.x - c.x, v.z - c.z).length())
			widths.append(2.0 * w)
		if widths.size() < 6:
			faults.append("ruban de cicatrice non mesurable (%d stations)" % widths.size())
		else:
			var mean: float = 0.0
			for w2: float in widths:
				mean += w2
			mean /= float(widths.size())
			var sd: float = 0.0
			for w3: float in widths:
				sd += pow(w3 - mean, 2.0)
			sd = sqrt(sd / float(widths.size()))
			var cv: float = sd / maxf(1.0e-6, mean)
			if cv < SCAR_CV_MIN:
				faults.append("cicatrice de largeur constante : CV %.3f, plancher %.2f"
					% [cv, SCAR_CV_MIN])
		# échardes élancées, groupées par plan de rupture
		var bases: Array[float] = []
		for comp2: PackedVector3Array in comps:
			if comp2.size() > 160 or _bottom(comp2) < 2.5:
				continue
			var aabb: AABB = AABB(comp2[0], Vector3.ZERO)
			for v: Vector3 in comp2:
				aabb = aabb.expand(v)
			if aabb.size.y < 0.35 or aabb.size.y < 1.4 * maxf(aabb.size.x, aabb.size.z):
				continue
			bases.append(_bottom(comp2))
		var planes: Array[float] = []
		bases.sort()
		var i2: int = 0
		while i2 < bases.size():
			var j: int = i2
			while j + 1 < bases.size() and bases[j + 1] - bases[i2] < 1.0:
				j += 1
			if j - i2 + 1 >= 3:
				planes.append(bases[i2])
			i2 = j + 1
		if planes.size() < SPLINTER_PLANES_MIN:
			faults.append("%d plan(s) de rupture portant 3 échardes ou plus, plancher %d"
				% [planes.size(), SPLINTER_PLANES_MIN])
	check(faults.is_empty(),
		"la fracture est du bois arraché (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])


## -- 7. Le sol brûlé n'est ni une étoile ni une plaque ---------------------
##
## Mesuré sur le lieu MONTÉ, parce que ce mesh est construit en runtime :
## c'est l'exemption nommée de l'arbitrage R2B, et donc le seul endroit où
## la vérité est le nœud, pas un fichier.
func test_le_sol_brule_n_est_ni_etoile_ni_plaque() -> void:
	remember_root()
	var faults: Array[String] = []
	var packed: PackedScene = load(TREE_SCENE) as PackedScene
	var place: Node3D = null if packed == null else packed.instantiate() as Node3D
	if place == null:
		faults.append("la scène du lieu ne s'instancie pas")
	else:
		_tree().root.add_child(place)
		await _tree().process_frame
		var disc: MeshInstance3D = null
		for node: Node in place.find_children("SolBrule", "MeshInstance3D", true, false):
			disc = node as MeshInstance3D
		if disc == null or disc.mesh == null:
			faults.append("aucun maillage SolBrule au lieu monté")
		else:
			var arr: Array = disc.mesh.surface_get_arrays(0)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			# LE BORD, ET RIEN QUE LE BORD. Un simple « rayon > 0,5 m »
			# marchait tant que le disque n'avait qu'un anneau ; dès qu'il
			# en a deux, l'anneau intérieur entre dans l'échantillon et
			# rmax/rmin mesure l'écart entre les deux anneaux au lieu de la
			# forme du bord. On retient donc, PAR SECTEUR ANGULAIRE, le
			# sommet le plus éloigné : c'est la silhouette du disque, quel
			# que soit le nombre d'anneaux dessous.
			var far: Dictionary = {}
			for v: Vector3 in vs:
				var r: float = Vector2(v.x, v.z).length()
				if r < 0.3:
					continue
				var ang: float = fposmod(atan2(v.z, v.x), TAU)
				var sect: int = int(ang / TAU * 72.0)
				if not far.has(sect) or r > float((far[sect] as Array)[1]):
					far[sect] = [ang, r]
			var rim: Array = far.values()
			if rim.size() < 12:
				faults.append("bord du disque non mesurable (%d sommets)" % rim.size())
			else:
				rim.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
				var rmin: float = 1.0e9
				var rmax: float = 0.0
				var mean_r: float = 0.0
				for e: Array in rim:
					rmin = minf(rmin, e[1])
					rmax = maxf(rmax, e[1])
					mean_r += e[1]
				mean_r /= float(rim.size())
				var lobe: float = rmax / maxf(0.01, rmin)
				if lobe > SCORCH_LOBE_RATIO_MAX:
					faults.append("bord en étoile : rmax/rmin %.2f, plafond %.2f"
						% [lobe, SCORCH_LOBE_RATIO_MAX])
				# spectre de la modulation : aucune harmonique dominante
				var total: float = 0.0
				var top_share: float = 0.0
				var powers: Array[float] = []
				for k: int in range(1, 13):
					var re: float = 0.0
					var im: float = 0.0
					for e2: Array in rim:
						re += (e2[1] - mean_r) * cos(float(k) * e2[0])
						im += (e2[1] - mean_r) * sin(float(k) * e2[0])
					var pw: float = re * re + im * im
					powers.append(pw)
					total += pw
				for pw2: float in powers:
					top_share = maxf(top_share, pw2 / maxf(1.0e-9, total))
				if top_share > SCORCH_HARMONIC_MAX:
					faults.append("bord harmonique : %.0f%% de l'énergie dans une seule "
						% (top_share * 100.0) + "raie, plafond %.0f%%"
						% (SCORCH_HARMONIC_MAX * 100.0))
				var area: float = PI * mean_r * mean_r
				if area > SCORCH_AREA_MAX_M2:
					faults.append("disque de %.1f m², plafond %.0f" % [area,
						SCORCH_AREA_MAX_M2])
			# la teinte de sommet ne doit pas être périodique à courte période
			var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
			if cols.size() >= 24:
				var same: int = 0
				for i3: int in range(cols.size() - 12):
					if absf(cols[i3].r - cols[i3 + 12].r) < 0.002:
						same += 1
				if float(same) / float(cols.size() - 12) > 0.85:
					faults.append("teinte de sommet périodique : %d/%d sommets "
						% [same, cols.size() - 12] + "identiques à 12 rangs d'écart")
		place.queue_free()
	check(faults.is_empty(),
		"le sol brûlé n'est ni une étoile ni une plaque (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (sol brûlé) — %s" % restore_root_reason())


## Complète un profil angulaire : tout secteur sans sommet reçoit une
## valeur interpolée entre ses voisins occupés les plus proches, en
## circulaire. Sans ça, un maillage grossier rend une aire artificiellement
## petite — et le contrôle récompense la géométrie la plus pauvre.
func _profil_rempli(brut: Dictionary, n: int) -> PackedFloat32Array:
	var occupes: Array[int] = []
	for k: int in brut.keys():
		occupes.append(k)
	occupes.sort()
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	for i: int in range(n):
		if brut.has(i):
			out[i] = float(brut[i])
			continue
		var avant: int = occupes[occupes.size() - 1]
		var apres: int = occupes[0]
		for k2: int in occupes:
			if k2 < i:
				avant = k2
			if k2 > i:
				apres = k2
				break
		var d_av: float = float(posmod(i - avant, n))
		var d_ap: float = float(posmod(apres - i, n))
		var t: float = d_av / maxf(1.0, d_av + d_ap)
		out[i] = lerpf(float(brut[avant]), float(brut[apres]), t)
	return out


## -- 8. La masse sombre au sol n'écrase ni le pied ni la lecture ----------
##
## Le disque, les contreforts-racines et les bois tombés forment ENSEMBLE
## une tache sombre au pied. Chacun pris seul peut être sobre pendant que
## leur somme redevient le « socle » puis l'« étoile » que le lead a
## rejetés. On mesure donc la SILHOUETTE de cette union : rayon maximal par
## secteur de 5°, puis aire en éventail, rapport à l'emprise de souche, et
## répartition spectrale du profil — la même lecture que pour le bord du
## disque, appliquée à tout ce qui est au sol.
func test_la_masse_sombre_au_sol_reste_sobre() -> void:
	remember_root()
	var faults: Array[String] = []
	var packed: PackedScene = load(TREE_SCENE) as PackedScene
	var place: Node3D = null if packed == null else packed.instantiate() as Node3D
	if place == null:
		faults.append("la scène du lieu ne s'instancie pas")
	else:
		_tree().root.add_child(place)
		await _tree().process_frame
		var foot: Vector3 = Vector3.ZERO
		for node: Node in place.find_children("SolBrule", "MeshInstance3D",
				true, false):
			foot = (node as MeshInstance3D).global_transform.origin
		var sol: Dictionary = {}
		var souche: Dictionary = {}
		for node: Node in place.find_children("*", "MeshInstance3D", true, false):
			var mi: MeshInstance3D = node as MeshInstance3D
			if mi.mesh == null:
				continue
			var nom: String = String(mi.name)
			var au_sol: bool = nom.contains("SolBrule") or nom.contains("Roots") \
				or nom.contains("Branch")
			var est_souche: bool = nom.contains("Bark")
			if not au_sol and not est_souche:
				continue
			for s2: int in range(mi.mesh.get_surface_count()):
				var arr: Array = mi.mesh.surface_get_arrays(s2)
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				for v: Vector3 in vs:
					var p: Vector3 = mi.global_transform * v - foot
					var r: float = Vector2(p.x, p.z).length()
					if r < 0.4:
						continue
					var ang: float = fposmod(atan2(p.z, p.x), TAU)
					if au_sol and p.y <= 0.75:
						var s3: int = int(ang / TAU * 72.0)
						sol[s3] = maxf(sol.get(s3, 0.0), r)
					if est_souche and p.y <= 0.30:
						var s4: int = int(ang / TAU * 24.0)
						souche[s4] = maxf(souche.get(s4, 0.0), r)
		if sol.size() < 12 or souche.size() < 6:
			faults.append("masse au sol non mesurable (%d secteurs sol, %d souche)"
				% [sol.size(), souche.size()])
		else:
			# SECTEURS VIDES INTERPOLÉS, et c'est une correction, pas un
			# raffinement. Premier jet : on sommait les secteurs OCCUPÉS.
			# Le disque du r02 n'a que 30 sommets de bord pour 72 secteurs,
			# donc plus de la moitié des secteurs restaient vides et l'aire
			# était sous-estimée d'autant : le contrôle passait AU VERT sur
			# la géométrie qu'il était écrit pour recaler. Un test qui ne
			# peut pas rougir ne compte pas. Le profil est une courbe
			# fermée : un secteur sans sommet n'est pas un secteur sans
			# matière, il est entre deux sommets.
			var rayons_sol: PackedFloat32Array = _profil_rempli(sol, 72)
			var rayons_souche: PackedFloat32Array = _profil_rempli(souche, 24)
			var aire: float = 0.0
			var moyen: float = 0.0
			for k2: int in range(72):
				aire += 0.5 * pow(rayons_sol[k2], 2.0) * TAU / 72.0
				moyen += rayons_sol[k2]
			moyen /= 72.0
			var aire_souche: float = 0.0
			for k3: int in range(24):
				aire_souche += 0.5 * pow(rayons_souche[k3], 2.0) * TAU / 24.0
			var ratio: float = aire / maxf(0.01, aire_souche)
			var total: float = 0.0
			var raies: Array[float] = []
			for k: int in range(1, 13):
				var re: float = 0.0
				var im: float = 0.0
				for s7: int in range(72):
					var a2: float = (float(s7) + 0.5) / 72.0 * TAU
					re += (rayons_sol[s7] - moyen) * cos(float(k) * a2)
					im += (rayons_sol[s7] - moyen) * sin(float(k) * a2)
				var pw: float = re * re + im * im
				raies.append(pw)
				total += pw
			var dominante: float = 0.0
			for pw2: float in raies:
				dominante = maxf(dominante, pw2 / maxf(1.0e-9, total))
			if aire > GROUND_AREA_MAX_M2:
				faults.append("masse sombre de %.1f m² au pied, plafond %.0f"
					% [aire, GROUND_AREA_MAX_M2])
			if ratio > GROUND_STUMP_RATIO_MAX:
				faults.append("masse sombre = %.1f fois l'emprise de souche, "
					% ratio + "plafond %.0f" % GROUND_STUMP_RATIO_MAX)
			if dominante > GROUND_HARMONIC_MAX:
				faults.append("masse sombre en étoile : %.0f%% de l'énergie dans "
					% (dominante * 100.0) + "une seule raie, plafond %.0f%%"
					% (GROUND_HARMONIC_MAX * 100.0))
		place.queue_free()
	check(faults.is_empty(),
		"la masse sombre au sol reste sobre (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (masse au sol) — %s" % restore_root_reason())
