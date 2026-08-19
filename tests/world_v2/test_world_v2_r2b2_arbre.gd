## V2.3-A.R2B.2 — FILET DE FERMETURE VISUELLE DE L'ARBRE FOUDROYÉ (agent B).
##
## POURQUOI CE FICHIER EXISTE, ALORS QUE `test_world_v2_r2b1_arbre.gd` EXISTE
## DÉJÀ ET RESTE VERT. Parce que R2B.1 mesurait la RÉPARTITION et que le lead
## lisait la LOI DE FORME D'UNE PIÈCE.
##
##   Anisotropie, écarts d'azimut, raie dominante du disque, rapports
##   longueur/rayon des bois : ce sont des statistiques de l'ENVELOPPE EN PLAN
##   et des RAPPORTS ENTRE PIÈCES. Elles règlent « est-ce un obélisque ? » et
##   « ces deux planches sont-elles jumelles ? » — deux questions de champ
##   LOINTAIN. L'œil de près lit autre chose : comment une section évolue le
##   long de son axe, en combien de mètres se creuse un sillon. Un objet peut
##   être parfaitement irrégulier en répartition et rester fait de cinq
##   prismes, d'un ruban et de cinq cônes droits — c'était exactement le cas.
##
## LES CINQ DÉFAUTS, MESURÉS SUR LE GLB R2B.1 AVANT CORRECTION :
##  * `anneau()` échantillonnait toujours `a = 2πi/n` depuis la même origine :
##    ROTATION INTER-ANNEAU 0,000°, donc arêtes longitudinales = méridiens
##    exacts, donc facettes réglées courant tout le membre. Dièdre
##    longitudinal médian 1,1° sur 3–7 m.
##  * relief radial tiré INDÉPENDAMMENT à chaque anneau : corrélation du
##    profil d'un anneau au suivant −0,52 (anti-corrélé), crête-à-crête 0,089
##    du rayon. Du bruit, pas des cannelures.
##  * cicatrice : autocorrélation lag-1 de la largeur −0,483, donc alternance
##    une station sur deux. CV BRUT 0,402 — rassurant — mais CV LISSÉ SUR
##    TROIS STATIONS, c'est-à-dire à l'échelle où l'œil intègre, 0,155.
##    Profondeur relative du sillon constante (retrait 0,80 partout).
##  * racines : hexagone aplati 1,80 aux trois sommets bas écrêtés par
##    `max(0.01, …)` — 10,0 % de flanc seulement, sagitta en plan nulle.
##  * bois tombés : axe droit EXACT (sagitta 0,000 m pour les cinq), mêmes
##    8 côtés, même effilement, mêmes 88 triangles cinq fois.
##
## UN CONTRÔLE QUE DU BRUIT SATISFAIT MESURE DU BRUIT. Un estimateur de
## « plages coplanaires connexes » a été construit puis JETÉ : il rendait
## 0,3 % sur la géométrie que le lead juge prismatique, parce que le bruit
## per-anneau rend le maillage numériquement non plan partout sans rien
## donner à l'œil. Les contrôles C1c/C1d le remplacent par un COUPLE que ni
## le bruit ni la pauvreté ne satisfont : cohérence verticale ≥ 0,55 ET
## amplitude ≥ 0,16. Un cône parfait échoue à l'amplitude ; un fût bruité
## échoue à la cohérence.
##
## MÉTHODE. Tout est mesuré sur le GLB EXPORTÉ, jamais sur les constantes du
## générateur — un test qui relit les constantes qui ont produit la géométrie
## compare une constante à elle-même et ne peut pas rougir. Les anneaux d'un
## loft sont PLANS en Y : on les retrouve en groupant les sommets soudés au
## millimètre par altitude, ce qui restitue la topologie de Blender que
## l'export glTF a éclatée par normale.
class_name TestWorldV2R2B2Arbre
extends GateTestCase

const TREE_GLB: String = "res://assets/architecture/flora/SM_ThunderstruckTree.glb"

## Seuils. Chacun porte la valeur MESURÉE sur le GLB R2B.1, pour qu'on voie
## d'un coup d'œil que l'assertion rougit avant correction.
const PHASE_MEAN_MIN_DEG: float = 4.0    # R2B.1 : 0,000
const PHASE_SD_MIN_DEG: float = 2.0      # R2B.1 : 0,000
const PHASE_NET_MAX_DEG: float = 60.0    # borne haute : interdit l'effet barbier
const FLUTE_CORR_MIN: float = 0.55       # R2B.1 : −0,52
const FLUTE_PP_MIN: float = 0.16         # R2B.1 : 0,089
## SEUIL CORRIGÉ APRÈS CALCUL, ET IL FAUT DIRE POURQUOI. Le plan proposait
## « flanc ≥ 28 % ». Pour une section elliptique de demi-axes (a horizontal,
## b vertical), la part de surface dont la normale est à plus de 70° de la
## verticale vaut ≈ 2·2·atan(0,364·b/a)/2π : 12,7 % pour l'aplatissement 1,80
## d'aujourd'hui (mesuré 10,0 %), 20 % pour une section légèrement plus haute
## que large, 22 % pour un cercle parfait. 28 % EXIGERAIT UNE SECTION PLUS
## HAUTE QUE LARGE — une nageoire, pas un contrefort. Le seuil était donc
## inatteignable sans fabriquer un autre défaut. On garde le flanc, plus bas,
## et on lui ADJOINT la mesure qui décrit vraiment « une plaque » : la part de
## surface presque horizontale.
const ROOT_FLANK_MIN_PCT: float = 15.0   # R2B.1 : 10,0 ; cercle parfait : 22
const ROOT_PLATE_MAX_PCT: float = 60.0   # R2B.1 : 68,5 ; cercle parfait : 50
const ROOT_SAG_MIN_PCT: float = 7.0      # R2B.1 : 0,0
const ROOT_GAP_RATIO_MIN: float = 2.20   # R2B.1 : 1,55
const ROOT_STEP_MAX_M: float = 0.32      # R2B.1 : 0,382 (défaut PRÉEXISTANT)
## LA MESURE QUI MANQUAIT — ajoutée après un rejet du lead, et il faut dire
## pourquoi les dix-huit autres ne l'ont pas vue. C2a mesure l'ORIENTATION DES
## NORMALES d'une section : une aile mince peut avoir des flancs parfaitement
## arrondis en section — 33,0 % de flanc, vert — et former malgré tout une
## galette vue de trois quarts. L'orientation d'une normale ne dit rien de
## l'ÉTALEMENT d'une masse. Mesuré sur le GLB rejeté : emprise 4,52 m de large
## pour 0,86 m de haut, soit 5,26 : 1, et 68 % des sommets hors de l'emprise du
## collider, plafonnés à 0,28 m. Le volume était là où on ne le voit pas ; la
## platitude là où on la voit.
##
## DEUX BORNES, ET LA SECONDE EST LA PRINCIPALE. Le rapport d'aspect se
## trafiquerait en RELEVANT la jupe — ce que le plafond de traversabilité
## interdit et que je ne ferai pas. La largeur en mètres, elle, ne se trafique
## par rien.
const ROOT_ASPECT_MAX: float = 4.20      # GLB rejeté : 5,26
const ROOT_SPAN_MAX_M: float = 3.60      # GLB rejeté : 4,52
const FALLEN_SAG_MIN_PCT: float = 5.0    # R2B.1 : 0,0
const FALLEN_TAPER_RATIO_MIN: float = 1.60  # R2B.1 : 1,00
const FALLEN_DISTINCT_TRIS_MIN: int = 4  # R2B.1 : 1 (cinq fois 88)
const SCAR_SMOOTH_CV_MIN: float = 0.32   # R2B.1 : 0,155
const SCAR_SMOOTH_RATIO_MIN: float = 3.0 # R2B.1 : 1,82
const SCAR_SEGMENTS_MIN: int = 3         # R2B.1 : 1 (bande ininterrompue)
const SCAR_DEPTH_RATIO_MIN: float = 3.50 # R2B.1 : 2,22 — plancher de bruit du
## ruban de 0,11 m constant, dont la section hexagonale tourne avec la spirale.
## Le seuil est posé BIEN AU-DESSUS de ce plancher, pas juste au-dessus.
const SCAR_SPLINTERS_MIN: int = 6        # R2B.1 : 0 (toutes aux plans de rupture)
const VALUE_STEPS_MIN: int = 3           # R2B.1 : 2
const VALUE_GAP_MIN: float = 0.12
const BUDGET_TRIS: int = 6000            # plafond INCHANGÉ

## Le lead a porté la limite de matériaux de 3 à 4 le 2026-08-19 pour que la
## transition écorce → aubier grillé → cœur existe. Condition 2 de son
## arbitrage : PALIER DE VALEUR, pas teinte neuve — la teinte du nouveau
## matériau doit rester dans l'intervalle de la famille existante.
## L'étendue de teinte des TROIS matériaux R2B.1 vaut déjà 0,0896 et leur
## saturation max 0,346. « Pas de teinte neuve » ne peut donc pas vouloir dire
## « étendue nulle » — cela voudrait dire repeindre l'existant, ce qui est
## interdit. Le contrôle est un GARDE-FOU, pas un fail-first : il n'a aucune
## raison de rougir aujourd'hui puisque le 4e matériau n'existe pas encore, et
## il rougit dès que ce matériau sort de l'enveloppe déjà admise.
const HUE_SPAN_MAX: float = 0.0950     # R2B.1 : 0,0896
const SAT_MAX: float = 0.400           # R2B.1 : 0,346


func _capped(faults: Array[String], keep: int = 6) -> String:
	if faults.is_empty():
		return "aucun écart"
	if faults.size() <= keep:
		return ", ".join(faults)
	return ", ".join(faults.slice(0, keep)) + " (+%d autre(s))" % (faults.size() - keep)


## ---------------------------------------------------------------------------
## Lecture du GLB
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
		var mats: Array[Color] = []
		for s: int in range(mi.mesh.get_surface_count()):
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var base: int = verts.size()
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			for v: Vector3 in vs:
				verts.append(mi.transform * v)
			var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			for i: int in ix:
				idx.append(i + base)
			var m: StandardMaterial3D = mi.mesh.surface_get_material(s) as StandardMaterial3D
			if m != null:
				mats.append(m.albedo_color)
		out[String(mi.name)] = {"v": verts, "i": idx, "m": mats}
	root.free()
	return out


## Soudure au millimètre + union-find. Rend un Array de PackedVector3Array.
## SANS lambda : une `Callable` capture par VALEUR, et la première version de
## ce piège (documentée dans le filet R2B.1) rendait un sommet par composante.
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
	# Un PackedVector3Array est un type VALEUR : `buckets[r].append(v)` écrit
	# sur une copie et l'écriture est jetée sans erreur. On accumule donc dans
	# des `Array` (type RÉFÉRENCE) et on convertit à la fin.
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
		var pg: PackedVector3Array = PackedVector3Array()
		var seen: Dictionary = {}
		for v2: Vector3 in gr:
			var kk: String = "%d|%d|%d" % [roundi(v2.x * 1000.0),
				roundi(v2.y * 1000.0), roundi(v2.z * 1000.0)]
			if seen.has(kk):
				continue
			seen[kk] = true
			pg.append(v2)
		comps.append(pg)
	comps.sort_custom(func(a: PackedVector3Array, b: PackedVector3Array) -> bool:
		return a.size() > b.size())
	return comps


## Les anneaux d'un loft sont PLANS en Y. On regroupe les sommets soudés par
## altitude au millimètre. Garde-fou : un niveau doit être à peu près
## circulaire (rmax/rmin ≤ 2,6), sinon c'est que deux lofts distincts se
## trouvent à la même altitude et la mesure porterait sur un nuage, pas un
## anneau.
func _anneaux(verts: PackedVector3Array, y_min: float, y_max: float,
		n_min: int, n_max: int) -> Array:
	var par_niveau: Dictionary = {}
	var vus: Dictionary = {}
	for v: Vector3 in verts:
		if v.y < y_min or v.y > y_max:
			continue
		var kk: String = "%d|%d|%d" % [roundi(v.x * 1000.0), roundi(v.y * 1000.0),
			roundi(v.z * 1000.0)]
		if vus.has(kk):
			continue
		vus[kk] = true
		var lvl: int = roundi(v.y * 1000.0)
		if not par_niveau.has(lvl):
			par_niveau[lvl] = PackedVector3Array()
		var arr: PackedVector3Array = par_niveau[lvl]
		arr.append(v)
		par_niveau[lvl] = arr
	var out: Array = []
	var niveaux: Array = par_niveau.keys()
	niveaux.sort()
	for lvl2: int in niveaux:
		var pts: PackedVector3Array = par_niveau[lvl2]
		if pts.size() < n_min or pts.size() > n_max:
			continue
		var c: Vector3 = Vector3.ZERO
		for p: Vector3 in pts:
			c += p
		c /= float(pts.size())
		var azs: Array[float] = []
		var rs: Array[float] = []
		var rmin: float = 1.0e9
		var rmax: float = 0.0
		for p2: Vector3 in pts:
			var d: Vector2 = Vector2(p2.x - c.x, p2.z - c.z)
			azs.append(atan2(d.y, d.x))
			rs.append(d.length())
			rmin = minf(rmin, d.length())
			rmax = maxf(rmax, d.length())
		if rmin < 0.01 or rmax / rmin > 2.6:
			continue
		out.append({"y": float(lvl2) / 1000.0, "c": c, "az": azs, "r": rs})
	return out


## Phase de l'anneau : argument de l'harmonique d'ordre `n` dominant, ramené
## dans [0 ; 2π/n[. C'est la seule grandeur qui décrit « depuis quel azimut
## l'anneau a été échantillonné » sans dépendre de l'ordre des sommets, que
## l'export glTF a perdu.
func _phase_anneau(azs: Array[float], n: int) -> float:
	var sx: float = 0.0
	var sy: float = 0.0
	for a: float in azs:
		sx += cos(float(n) * a)
		sy += sin(float(n) * a)
	return atan2(sy, sx) / float(n)


func _fold_dominant(azs: Array[float]) -> int:
	var best: int = 0
	var best_amp: float = -1.0
	for n: int in range(8, 33):
		var sx: float = 0.0
		var sy: float = 0.0
		for a: float in azs:
			sx += cos(float(n) * a)
			sy += sin(float(n) * a)
		var amp: float = Vector2(sx, sy).length()
		if amp > best_amp:
			best_amp = amp
			best = n
	return best


## Profil radial rééchantillonné à 36 azimuts uniformes, normalisé par sa
## moyenne. Sert aux deux moitiés du couple C1c/C1d.
func _profil(anneau: Dictionary) -> Array[float]:
	var azs: Array[float] = anneau["az"]
	var rs: Array[float] = anneau["r"]
	var out: Array[float] = []
	var moy: float = 0.0
	for k: int in range(36):
		var a: float = -PI + TAU * float(k) / 36.0
		var best: float = 0.0
		var best_d: float = 1.0e9
		for i: int in range(azs.size()):
			var d: float = absf(wrapf(azs[i] - a, -PI, PI))
			if d < best_d:
				best_d = d
				best = rs[i]
		out.append(best)
		moy += best
	moy /= 36.0
	if moy <= 0.0:
		return out
	for k2: int in range(36):
		out[k2] = out[k2] / moy
	return out


func _correlation(a: Array[float], b: Array[float]) -> float:
	var n: int = mini(a.size(), b.size())
	if n < 8:
		return 0.0
	var ma: float = 0.0
	var mb: float = 0.0
	for i: int in range(n):
		ma += a[i]
		mb += b[i]
	ma /= float(n)
	mb /= float(n)
	var num: float = 0.0
	var da: float = 0.0
	var db: float = 0.0
	for i2: int in range(n):
		num += (a[i2] - ma) * (b[i2] - mb)
		da += pow(a[i2] - ma, 2.0)
		db += pow(b[i2] - mb, 2.0)
	if da <= 0.0 or db <= 0.0:
		return 0.0
	return num / sqrt(da * db)


## Sagitta EN PLAN d'une pièce allongée, en fraction de sa longueur. Mesurée
## sur la composante donnée UNIQUEMENT : mesurer sur tous les sommets du nœud
## fait entrer le chicot latéral, qui déporte le centroïde de tranche et
## fabrique une fausse courbure — vérifié, il rendait 7 % sur un axe
## rigoureusement droit.
func _sagitta_plan(pts: PackedVector3Array) -> Array:
	if pts.size() < 8:
		return [0.0, 0.0]
	var c: Vector3 = Vector3.ZERO
	for v: Vector3 in pts:
		c += v
	c /= float(pts.size())
	var sxx: float = 0.0
	var szz: float = 0.0
	var sxz: float = 0.0
	for v2: Vector3 in pts:
		sxx += pow(v2.x - c.x, 2.0)
		szz += pow(v2.z - c.z, 2.0)
		sxz += (v2.x - c.x) * (v2.z - c.z)
	var th: float = 0.5 * atan2(2.0 * sxz, sxx - szz)
	var u: Vector2 = Vector2(cos(th), sin(th))
	var p: Vector2 = Vector2(-u.y, u.x)
	var lo: float = 1.0e9
	var hi: float = -1.0e9
	for v3: Vector3 in pts:
		var t: float = (v3.x - c.x) * u.x + (v3.z - c.z) * u.y
		lo = minf(lo, t)
		hi = maxf(hi, t)
	var span: float = hi - lo
	if span < 0.2:
		return [0.0, 0.0]
	var somme: Array[float] = []
	var compte: Array[float] = []
	for k: int in range(9):
		somme.append(0.0)
		compte.append(0.0)
	for v4: Vector3 in pts:
		var t2: float = (v4.x - c.x) * u.x + (v4.z - c.z) * u.y
		var w: float = (v4.x - c.x) * p.x + (v4.z - c.z) * p.y
		var b: int = clampi(int((t2 - lo) / span * 8.999), 0, 8)
		somme[b] += w
		compte[b] += 1.0
	var lat: Array[float] = []
	for k2: int in range(9):
		if compte[k2] > 0.0:
			lat.append(somme[k2] / compte[k2])
	if lat.size() < 3:
		return [0.0, span]
	var sag: float = 0.0
	for i3: int in range(lat.size()):
		var chord: float = lat[0] + (lat[lat.size() - 1] - lat[0]) \
			* float(i3) / float(lat.size() - 1)
		sag = maxf(sag, absf(lat[i3] - chord))
	return [sag, span]


func _luminance(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


## ===========================================================================
## C1 — LE FÛT N'EST PLUS UN PRISME
## ===========================================================================
func test_c1_le_fut_n_est_plus_un_prisme() -> void:
	var faults: Array[String] = []
	var nodes: Dictionary = _glb_nodes()
	var bark: Dictionary = nodes.get("SM_ThunderstruckTree_Bark", {}) as Dictionary
	if bark.is_empty():
		check(false, "C1 : écorce absente du GLB")
		return
	var verts: PackedVector3Array = bark["v"]

	# --- C1a / C1b : rotation d'échantillonnage d'un anneau au suivant.
	# Fenêtre 2,6..10,4 m : au-dessus de la souche, sur les deux moitiés.
	var anneaux: Array = _anneaux(verts, 2.6, 10.4, 13, 40)
	var deltas: Array[float] = []
	var net: float = 0.0
	var prev_phase: float = 0.0
	var prev_y: float = -1.0
	var prev_n: int = 0
	for a: Dictionary in anneaux:
		var azs: Array[float] = a["az"]
		var n: int = _fold_dominant(azs)
		var ph: float = _phase_anneau(azs, n)
		if prev_y >= 0.0 and n == prev_n and a["y"] - prev_y < 1.2:
			var pas: float = TAU / float(n)
			var d: float = wrapf(ph - prev_phase, -0.5 * pas, 0.5 * pas)
			deltas.append(rad_to_deg(d))
			net += rad_to_deg(d)
		prev_phase = ph
		prev_y = a["y"]
		prev_n = n
	var moy_abs: float = 0.0
	var sd: float = 0.0
	if deltas.size() >= 4:
		for d2: float in deltas:
			moy_abs += absf(d2)
		moy_abs /= float(deltas.size())
		var m: float = 0.0
		for d3: float in deltas:
			m += d3
		m /= float(deltas.size())
		for d4: float in deltas:
			sd += pow(d4 - m, 2.0)
		sd = sqrt(sd / float(deltas.size()))
	else:
		faults.append("moins de 4 couples d'anneaux mesurables (%d)" % deltas.size())
	print("[r2b2-arbre] C1a rotation inter-anneau |Δφ| moyen %.3f° sur %d couples"
		% [moy_abs, deltas.size()])
	print("[r2b2-arbre] C1b écart-type de Δφ %.3f° ; rotation nette %.1f°" % [sd, net])
	if moy_abs < PHASE_MEAN_MIN_DEG:
		faults.append("C1a méridiens non brisés : |Δφ| moyen %.3f°, plancher %.1f°"
			% [moy_abs, PHASE_MEAN_MIN_DEG])
	if sd < PHASE_SD_MIN_DEG:
		faults.append("C1b rotation trop régulière : écart-type %.3f°, plancher %.1f°"
			% [sd, PHASE_SD_MIN_DEG])
	if absf(net) > PHASE_NET_MAX_DEG:
		faults.append("C1b effet barbier : rotation nette %.1f°, plafond %.1f°"
			% [net, PHASE_NET_MAX_DEG])

	# --- C1c / C1d : cannelures COHÉRENTES et d'amplitude suffisante.
	# Fenêtre 7,5..10,4 m : au-dessus du haut de la cicatrice, pour que le
	# sillon — qui est cohérent lui aussi — ne verdisse pas la corrélation à
	# la place des cannelures.
	var hauts: Array = _anneaux(verts, 7.5, 10.4, 13, 40)
	var corrs: Array[float] = []
	var pps: Array[float] = []
	var prof_prec: Array[float] = []
	for a2: Dictionary in hauts:
		var pr: Array[float] = _profil(a2)
		var lo: float = 1.0e9
		var hi: float = 0.0
		for x: float in pr:
			lo = minf(lo, x)
			hi = maxf(hi, x)
		pps.append(hi - lo)
		if not prof_prec.is_empty():
			corrs.append(_correlation(prof_prec, pr))
		prof_prec = pr
	var corr_moy: float = 0.0
	var pp_moy: float = 0.0
	if corrs.size() >= 3:
		for c2: float in corrs:
			corr_moy += c2
		corr_moy /= float(corrs.size())
		for p2: float in pps:
			pp_moy += p2
		pp_moy /= float(pps.size())
	else:
		faults.append("moins de 3 couples d'anneaux hauts (%d)" % corrs.size())
	print("[r2b2-arbre] C1c cohérence verticale du relief %+.3f sur %d couples"
		% [corr_moy, corrs.size()])
	print("[r2b2-arbre] C1d crête-à-crête du profil radial %.3f du rayon moyen" % pp_moy)
	if corr_moy < FLUTE_CORR_MIN:
		faults.append("C1c relief incohérent d'un anneau au suivant (du bruit) : %+.3f, plancher %.2f"
			% [corr_moy, FLUTE_CORR_MIN])
	if pp_moy < FLUTE_PP_MIN:
		faults.append("C1d relief trop faible (un cône lisse) : %.3f, plancher %.2f"
			% [pp_moy, FLUTE_PP_MIN])
	check(faults.is_empty(), "C1 le fût n'est plus un prisme (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])


## ===========================================================================
## C2 — LES RACINES ONT DU VOLUME, ET NE FONT PLUS D'ÉVENTAIL
## ===========================================================================
func test_c2_les_racines_ont_du_volume() -> void:
	var faults: Array[String] = []
	var nodes: Dictionary = _glb_nodes()
	var roots: Dictionary = nodes.get("SM_ThunderstruckTree_Roots", {}) as Dictionary
	if roots.is_empty():
		check(false, "C2 : racines absentes du GLB")
		return
	var verts: PackedVector3Array = roots["v"]
	var idx: PackedInt32Array = roots["i"]

	# --- C2a : part de FLANC. Une plaque n'a que du dessus et du dessous.
	var aire_tot: float = 0.0
	var aire_flanc: float = 0.0
	var aire_plaque: float = 0.0
	for t: int in range(0, idx.size() - 2, 3):
		var a: Vector3 = verts[idx[t]]
		var b: Vector3 = verts[idx[t + 1]]
		var c: Vector3 = verts[idx[t + 2]]
		var n: Vector3 = (b - a).cross(c - a)
		var aire: float = n.length() * 0.5
		if aire <= 1.0e-9:
			continue
		aire_tot += aire
		var ny: float = absf(n.normalized().y)
		if ny < cos(deg_to_rad(70.0)):
			aire_flanc += aire
		if ny > cos(deg_to_rad(45.0)):
			aire_plaque += aire
	var pct_flanc: float = 100.0 * aire_flanc / maxf(1.0e-6, aire_tot)
	var pct_plaque: float = 100.0 * aire_plaque / maxf(1.0e-6, aire_tot)
	print("[r2b2-arbre] C2a flanc %.1f %% / surface presque horizontale %.1f %% sur %.2f m²"
		% [pct_flanc, pct_plaque, aire_tot])
	if pct_flanc < ROOT_FLANK_MIN_PCT:
		faults.append("C2a racines sans flanc : %.1f %%, plancher %.1f %%"
			% [pct_flanc, ROOT_FLANK_MIN_PCT])
	if pct_plaque > ROOT_PLATE_MAX_PCT:
		faults.append("C2a racines en plaques : %.1f %% de surface presque horizontale, plafond %.1f %%"
			% [pct_plaque, ROOT_PLATE_MAX_PCT])

	# --- C2b : chaque racine est COURBE en plan.
	var comps: Array = _components(verts, idx)
	var principales: Array = []
	for comp: PackedVector3Array in comps:
		if comp.size() >= 20:
			principales.append(comp)
	var sag_min: float = 1.0e9
	var sags: Array[float] = []
	for comp2: PackedVector3Array in principales:
		var res: Array = _sagitta_plan(comp2)
		var pct: float = 0.0
		if float(res[1]) > 0.2:
			pct = 100.0 * float(res[0]) / float(res[1])
		sags.append(pct)
		sag_min = minf(sag_min, pct)
	print("[r2b2-arbre] C2b sagitta en plan des %d racines : %s (min %.2f %%)"
		% [principales.size(), str(sags), sag_min])
	if principales.size() < 5:
		faults.append("C2b %d racine(s) mesurable(s), plancher 5" % principales.size())
	elif sag_min < ROOT_SAG_MIN_PCT:
		faults.append("C2b racine rectiligne : sagitta min %.2f %%, plancher %.1f %%"
			% [sag_min, ROOT_SAG_MIN_PCT])

	# --- C2c : l'éventail régulier est cassé. Mesuré sur les CINQ PLUS
	# GROSSES composantes — sinon ajouter une petite racine collée à une
	# autre suffirait à créer un petit écart et à verdir le contrôle.
	principales.sort_custom(func(a2: PackedVector3Array, b2: PackedVector3Array) -> bool:
		return a2.size() > b2.size())
	var azs: Array[float] = []
	for k: int in range(mini(5, principales.size())):
		var comp3: PackedVector3Array = principales[k]
		var c3: Vector3 = Vector3.ZERO
		for v: Vector3 in comp3:
			c3 += v
		c3 /= float(comp3.size())
		azs.append(atan2(c3.z, c3.x))
	azs.sort()
	var ecarts: Array[float] = []
	for k2: int in range(azs.size()):
		var suiv: float = azs[(k2 + 1) % azs.size()]
		ecarts.append(rad_to_deg(fposmod(suiv - azs[k2], TAU)))
	var e_max: float = 0.0
	var e_min: float = 1.0e9
	for e: float in ecarts:
		e_max = maxf(e_max, e)
		e_min = minf(e_min, e)
	var ratio: float = e_max / maxf(1.0, e_min)
	print("[r2b2-arbre] C2c écarts d'azimut des racines %s → max/min %.2f"
		% [str(ecarts), ratio])
	if ratio < ROOT_GAP_RATIO_MIN:
		faults.append("C2c éventail régulier : écarts max/min %.2f, plancher %.2f"
			% [ratio, ROOT_GAP_RATIO_MIN])

	# --- C2d : TRAVERSABILITÉ. Défaut PRÉEXISTANT mesuré à 0,382 m sur le GLB
	# R2B.1, au-dessus du `step_height` de 0,34 de `locomotion_default.tres` :
	# hors de l'emprise du collider du tronc, un contrefort sans collider que
	# le joueur ne peut pas enjamber est un mur invisible.
	var haut_hors: float = 0.0
	var n_hors: int = 0
	for v2: Vector3 in verts:
		if absf(v2.x) <= 1.05 and absf(v2.z) <= 0.95:
			continue
		if v2.y > ROOT_STEP_MAX_M:
			n_hors += 1
		haut_hors = maxf(haut_hors, v2.y)
	print("[r2b2-arbre] C2d hauteur max des racines hors collider %.3f m (%d sommet(s) au-dessus de %.2f)"
		% [haut_hors, n_hors, ROOT_STEP_MAX_M])
	if haut_hors > ROOT_STEP_MAX_M:
		faults.append("C2d contrefort non enjambable : %.3f m hors collider, plafond %.2f m"
			% [haut_hors, ROOT_STEP_MAX_M])

	# --- C2e : AUCUNE GRANDE PLAQUE RADIALE (directive, point 6).
	var x0: float = 1.0e9
	var x1: float = -1.0e9
	var z0: float = 1.0e9
	var z1: float = -1.0e9
	var y0: float = 1.0e9
	var y1: float = -1.0e9
	for v3: Vector3 in verts:
		x0 = minf(x0, v3.x)
		x1 = maxf(x1, v3.x)
		z0 = minf(z0, v3.z)
		z1 = maxf(z1, v3.z)
		y0 = minf(y0, v3.y)
		y1 = maxf(y1, v3.y)
	var span: float = maxf(x1 - x0, z1 - z0)
	var aspect: float = span / maxf(0.05, y1 - y0)
	var aire_basse: float = 0.0
	for t2: int in range(0, idx.size() - 2, 3):
		var a2: Vector3 = verts[idx[t2]]
		var b2: Vector3 = verts[idx[t2 + 1]]
		var c2: Vector3 = verts[idx[t2 + 2]]
		if (a2.y + b2.y + c2.y) / 3.0 >= 0.30:
			continue
		aire_basse += (b2 - a2).cross(c2 - a2).length() * 0.5
	print("[r2b2-arbre] C2e emprise des racines %.2f x %.2f m -> aspect %.2f : 1 ; %.1f %% de surface sous 0,30 m"
		% [span, y1 - y0, aspect, 100.0 * aire_basse / maxf(1.0e-6, aire_tot)])
	if span > ROOT_SPAN_MAX_M:
		faults.append("C2e jupe trop étalée : %.2f m de large, plafond %.2f m"
			% [span, ROOT_SPAN_MAX_M])
	if aspect > ROOT_ASPECT_MAX:
		faults.append("C2e grande plaque radiale : %.2f : 1, plafond %.2f : 1"
			% [aspect, ROOT_ASPECT_MAX])
	check(faults.is_empty(), "C2 les racines ont du volume (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])


## ===========================================================================
## C3 — LES CINQ BOIS TOMBÉS NE SONT PLUS CINQ HOMOTHÉTIES
## ===========================================================================
func test_c3_les_bois_tombes_ne_sont_plus_homothetiques() -> void:
	var faults: Array[String] = []
	var nodes: Dictionary = _glb_nodes()
	var sags: Array[float] = []
	var tapers: Array[float] = []
	var tris: Array[int] = []
	for name: String in nodes.keys():
		if not name.contains("Branch"):
			continue
		var spec: Dictionary = nodes[name] as Dictionary
		var v: PackedVector3Array = spec["v"]
		var i: PackedInt32Array = spec["i"]
		tris.append(i.size() / 3)
		# la plus grosse composante = le bois lui-même, pas ses chicots
		var comps: Array = _components(v, i)
		if comps.is_empty():
			continue
		var log_piece: PackedVector3Array = comps[0]
		var res: Array = _sagitta_plan(log_piece)
		if float(res[1]) > 0.2:
			sags.append(100.0 * float(res[0]) / float(res[1]))
		var c: Vector3 = Vector3.ZERO
		for p: Vector3 in log_piece:
			c += p
		c /= float(log_piece.size())
		var sxx: float = 0.0
		var szz: float = 0.0
		var sxz: float = 0.0
		for p2: Vector3 in log_piece:
			sxx += pow(p2.x - c.x, 2.0)
			szz += pow(p2.z - c.z, 2.0)
			sxz += (p2.x - c.x) * (p2.z - c.z)
		var th: float = 0.5 * atan2(2.0 * sxz, sxx - szz)
		var u: Vector2 = Vector2(cos(th), sin(th))
		# EFFILEMENT — PREMIÈRE VERSION FAUSSE, corrigée après mesure. Elle
		# prenait une dalle de ±10 % de la portée autour de 20 % et 80 % de
		# l'axe PCA et lisait la distance max au centroïde de la dalle : la
		# dalle contenait un anneau ET une partie du suivant, et le `relevé`
		# inclinait la pièce, si bien que les rapports sortaient [1,29 ; 0,73 ;
		# 0,79 ; 1,29 ; 0,74] — non monotones — sur cinq bois dont l'effilement
		# est RIGOUREUSEMENT le même (1 − 0,38t). max/min valait 1,765 et le
		# contrôle passait au VERT sur la géométrie rejetée. Un contrôle vert
		# sur le défaut qu'il doit attraper ne vaut rien.
		# Version juste : les anneaux d'un loft de branche sont PLANS
		# perpendiculairement à l'axe ; on les retrouve en groupant par
		# coordonnée le long de l'axe, et le rayon est la distance max au
		# centroïde de l'anneau.
		# TROISIÈME MISE AU POINT, et la raison est instructive : grouper les
		# sommets par coordonnée le long de l'axe PCA marchait tant que l'axe
		# était DROIT. Dès que les bois ont reçu une flèche de 6 à 11 %, les
		# anneaux ont cessé d'être perpendiculaires à cet axe, leurs sommets se
		# sont éparpillés sur plusieurs cases, et seules DEUX pièces sur cinq
		# rendaient encore trois anneaux propres. On mesure donc les deux
		# BOUTS — les 10 % extrêmes de la course, où un seul anneau se trouve —
		# au lieu de reconstruire toute la série.
		var lo_u: float = 1.0e9
		var hi_u: float = -1.0e9
		for p4: Vector3 in log_piece:
			var t2: float = (p4.x - c.x) * u.x + (p4.z - c.z) * u.y
			lo_u = minf(lo_u, t2)
			hi_u = maxf(hi_u, t2)
		var course: float = hi_u - lo_u
		var rayons_anneaux: Array[float] = []
		for bout: int in range(2):
			var groupe: PackedVector3Array = PackedVector3Array()
			for p5: Vector3 in log_piece:
				var t3: float = (p5.x - c.x) * u.x + (p5.z - c.z) * u.y
				var d3: float = t3 - lo_u if bout == 0 else hi_u - t3
				if d3 < course * 0.10:
					groupe.append(p5)
			if groupe.size() < 4:
				continue
			var cc: Vector3 = Vector3.ZERO
			for p6: Vector3 in groupe:
				cc += p6
			cc /= float(groupe.size())
			var r: float = 0.0
			for p7: Vector3 in groupe:
				r = maxf(r, (p7 - cc).length())
			rayons_anneaux.append(r)
		# ORIENTATION — deuxième faux départ, corrigé après mesure. Le signe de
		# l'axe PCA est arbitraire : pour deux bois sur cinq, « premier anneau »
		# était le bout MINCE, et le rapport sortait 1,58 au lieu de 0,63. Les
		# cinq effilements réels sont identiques (1 − 0,38t) et max/min valait
		# pourtant 2,549 — encore VERT sur le défaut à attraper. On rend donc un
		# effilement INDÉPENDANT DE L'ORIENTATION : petit bout / gros bout.
		var rayons: Array[float] = [0.0, 0.0]
		if rayons_anneaux.size() >= 2:
			var ra: float = rayons_anneaux[0]
			var rb: float = rayons_anneaux[rayons_anneaux.size() - 1]
			rayons[0] = maxf(ra, rb)
			rayons[1] = minf(ra, rb)
		if rayons[0] > 0.02:
			tapers.append(rayons[1] / rayons[0])
	var sag_min: float = 1.0e9
	for s: float in sags:
		sag_min = minf(sag_min, s)
	print("[r2b2-arbre] C3a sagitta en plan des bois : %s" % str(sags))
	if sags.size() < 5:
		faults.append("C3a %d bois mesurable(s), plancher 5" % sags.size())
	elif sag_min < FALLEN_SAG_MIN_PCT:
		faults.append("C3a bois rectiligne : sagitta min %.2f %%, plancher %.1f %%"
			% [sag_min, FALLEN_SAG_MIN_PCT])
	var t_max: float = 0.0
	var t_min: float = 1.0e9
	for t3: float in tapers:
		t_max = maxf(t_max, t3)
		t_min = minf(t_min, t3)
	var t_ratio: float = t_max / maxf(0.01, t_min)
	print("[r2b2-arbre] C3b effilements %s → max/min %.3f" % [str(tapers), t_ratio])
	if tapers.size() < 5:
		faults.append("C3b %d effilement(s) mesurable(s), plancher 5" % tapers.size())
	elif t_ratio < FALLEN_TAPER_RATIO_MIN:
		faults.append("C3b une seule loi d'effilement : max/min %.3f, plancher %.2f"
			% [t_ratio, FALLEN_TAPER_RATIO_MIN])
	var distincts: Dictionary = {}
	for n2: int in tris:
		distincts[n2] = true
	print("[r2b2-arbre] C3c triangles par bois %s → %d compte(s) distinct(s)"
		% [str(tris), distincts.size()])
	if distincts.size() < FALLEN_DISTINCT_TRIS_MIN:
		faults.append("C3c topologies identiques : %d compte(s) distinct(s) sur %d bois, plancher %d"
			% [distincts.size(), tris.size(), FALLEN_DISTINCT_TRIS_MIN])
	check(faults.is_empty(), "C3 les bois tombés ne sont plus homothétiques (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])


## ===========================================================================
## C4 — LA CICATRICE EST UN VOLUME ARRACHÉ, PAS UN RUBAN PEINT
## ===========================================================================
func test_c4_la_cicatrice_est_un_volume_arrache() -> void:
	var faults: Array[String] = []
	var nodes: Dictionary = _glb_nodes()
	var heart: Dictionary = nodes.get("SM_ThunderstruckTree_Heart", {}) as Dictionary
	var bark: Dictionary = nodes.get("SM_ThunderstruckTree_Bark", {}) as Dictionary
	if heart.is_empty() or bark.is_empty():
		check(false, "C4 : cœur ou écorce absent du GLB")
		return
	var comps: Array = _components(heart["v"] as PackedVector3Array,
		heart["i"] as PackedInt32Array)

	# --- fragments de ruban : composantes assez grosses, dans la course de la
	# cicatrice. Les échardes (8 sommets), les bouts de moignon (8) et le coin
	# de fente (12) sont en dessous du seuil.
	var fragments: Array = []
	for comp: PackedVector3Array in comps:
		if comp.size() < 40:
			continue
		var lo: float = 1.0e9
		var hi: float = -1.0e9
		for v: Vector3 in comp:
			lo = minf(lo, v.y)
			hi = maxf(hi, v.y)
		if hi > 7.6 or lo < 0.1 or hi - lo < 0.5:
			continue
		fragments.append(comp)
	print("[r2b2-arbre] C4c fragments de ruban : %d" % fragments.size())
	if fragments.size() < SCAR_SEGMENTS_MIN:
		faults.append("C4c bande ininterrompue : %d fragment(s), plancher %d"
			% [fragments.size(), SCAR_SEGMENTS_MIN])

	# --- largeur LISSÉE : ce que l'œil intègre. Le CV BRUT du ruban R2B.1
	# valait 0,402 et la bande se lisait quand même comme peinte, parce que la
	# variation alternait d'une station à l'autre (autocorrélation −0,483).
	var tous: PackedVector3Array = PackedVector3Array()
	for f: PackedVector3Array in fragments:
		for v2: Vector3 in f:
			tous.append(v2)
	var largeurs: Array[float] = []
	if tous.size() >= 24:
		var y0: float = 1.0e9
		var y1: float = -1.0e9
		for v3: Vector3 in tous:
			y0 = minf(y0, v3.y)
			y1 = maxf(y1, v3.y)
		for k: int in range(18):
			var h: float = y0 + (y1 - y0) * (0.04 + 0.92 * float(k) / 17.0)
			var slice: PackedVector3Array = PackedVector3Array()
			for v4: Vector3 in tous:
				if absf(v4.y - h) < 0.25:
					slice.append(v4)
			# FENÊTRE ÉLARGIE DE 0,14 À 0,25 m APRÈS MESURE. À ±0,14 m, avec des
			# stations de ruban espacées de 0,39 m, une tranche sur deux tombait
			# ENTRE deux stations et sortait vide ; comptée comme largeur nulle,
			# elle donnait CV 0,821 et max/min 49,5 sur une bande dont la largeur
			# est en réalité quasi constante — VERT sur le défaut à attraper. Une
			# station sans sommet est désormais SAUTÉE ; les vraies interruptions
			# sont comptées par C4c, sur les composantes connexes.
			if slice.size() < 4:
				continue
			var c: Vector3 = Vector3.ZERO
			for v5: Vector3 in slice:
				c += v5
			c /= float(slice.size())
			var w: float = 0.0
			for v6: Vector3 in slice:
				w = maxf(w, Vector2(v6.x - c.x, v6.z - c.z).length())
			largeurs.append(2.0 * w)
	var lisse: Array[float] = []
	for k2: int in range(largeurs.size()):
		var a: float = largeurs[maxi(k2 - 1, 0)]
		var b: float = largeurs[k2]
		var c2: float = largeurs[mini(k2 + 1, largeurs.size() - 1)]
		lisse.append((a + b + c2) / 3.0)
	var cv: float = 0.0
	var ratio_l: float = 0.0
	if lisse.size() >= 10:
		var m: float = 0.0
		for x: float in lisse:
			m += x
		m /= float(lisse.size())
		var sd: float = 0.0
		var lo2: float = 1.0e9
		var hi2: float = 0.0
		for x2: float in lisse:
			sd += pow(x2 - m, 2.0)
			lo2 = minf(lo2, x2)
			hi2 = maxf(hi2, x2)
		sd = sqrt(sd / float(lisse.size()))
		cv = sd / maxf(1.0e-6, m)
		ratio_l = hi2 / maxf(0.01, lo2)
	else:
		faults.append("C4a ruban non mesurable (%d station(s))" % lisse.size())
	print("[r2b2-arbre] C4a CV de la largeur LISSÉE sur 3 stations %.3f" % cv)
	print("[r2b2-arbre] C4b largeur lissée max/min %.2f" % ratio_l)
	if cv < SCAR_SMOOTH_CV_MIN:
		faults.append("C4a largeur constante à l'échelle de l'œil : CV lissé %.3f, plancher %.2f"
			% [cv, SCAR_SMOOTH_CV_MIN])
	if ratio_l < SCAR_SMOOTH_RATIO_MIN:
		faults.append("C4b enveloppe plate : largeur lissée max/min %.2f, plancher %.2f"
			% [ratio_l, SCAR_SMOOTH_RATIO_MIN])

	# --- C4d : LA FRACTURE EST-ELLE UN VOLUME ? On mesure la PROFONDEUR
	# RADIALE du bois mis à nu — son étendue le long du rayon du fût — station
	# par station, puis son rapport max/min après le même lissage sur trois
	# stations que C4a. Un ruban lofté à épaisseur constante rend un rapport
	# de 1 ; un coin de bois arraché est profond à l'impact et s'efface au
	# pied.
	#
	# DEUX VERSIONS PRÉCÉDENTES ONT ÉTÉ JETÉES, et il faut le dire :
	#  * « profondeur du sillon en mètres » : sur un fût qui s'affine, un
	#    retrait CONSTANT donne déjà un rapport de 4 — vert sur le défaut.
	#  * « profondeur relative au rayon local » : quatre anneaux seulement
	#    étaient mesurables et ils rendaient [0,130 ; 0,074 ; 0,136 ; 0,163]
	#    sur un retrait rigoureusement constant, soit un rapport de 2,2 de pur
	#    bruit d'inscription polygonale. Un estimateur qui bruite autant que le
	#    signal qu'il cherche ne tranche rien.
	var anneaux_bark: Array = _anneaux(bark["v"] as PackedVector3Array,
		0.1, 7.7, 13, 40)
	var profs: Array[float] = []
	if tous.size() >= 24 and anneaux_bark.size() >= 4:
		var y0b: float = 1.0e9
		var y1b: float = -1.0e9
		for v7: Vector3 in tous:
			y0b = minf(y0b, v7.y)
			y1b = maxf(y1b, v7.y)
		for k3: int in range(18):
			var h2: float = y0b + (y1b - y0b) * (0.04 + 0.92 * float(k3) / 17.0)
			var sl: PackedVector3Array = PackedVector3Array()
			for v8: Vector3 in tous:
				if absf(v8.y - h2) < 0.25:
					sl.append(v8)
			if sl.size() < 4:
				continue
			var cs: Vector3 = Vector3.ZERO
			for v9: Vector3 in sl:
				cs += v9
			cs /= float(sl.size())
			var axe: Vector3 = Vector3.ZERO
			var dy: float = 1.0e9
			for an2: Dictionary in anneaux_bark:
				var d2: float = absf(float(an2["y"]) - h2)
				if d2 < dy:
					dy = d2
					axe = an2["c"]
			var dir: Vector2 = Vector2(cs.x - axe.x, cs.z - axe.z)
			if dir.length() < 0.02:
				continue
			dir = dir.normalized()
			var lo4: float = 1.0e9
			var hi4: float = -1.0e9
			for v10: Vector3 in sl:
				var pr: float = (v10.x - axe.x) * dir.x + (v10.z - axe.z) * dir.y
				lo4 = minf(lo4, pr)
				hi4 = maxf(hi4, pr)
			profs.append(hi4 - lo4)
	var profs_lisse: Array[float] = []
	for k4: int in range(profs.size()):
		profs_lisse.append((profs[maxi(k4 - 1, 0)] + profs[k4]
			+ profs[mini(k4 + 1, profs.size() - 1)]) / 3.0)
	var d_max: float = 0.0
	var d_min: float = 1.0e9
	for d: float in profs_lisse:
		d_max = maxf(d_max, d)
		d_min = minf(d_min, d)
	var d_ratio: float = d_max / maxf(0.005, d_min)
	print("[r2b2-arbre] C4d profondeur radiale du bois nu, lissée : %s" % str(profs_lisse))
	print("[r2b2-arbre] C4d profondeur radiale sur %d stations : min %.3f m max %.3f m → max/min %.2f"
		% [profs_lisse.size(), d_min, d_max, d_ratio])
	if profs_lisse.size() < 8:
		faults.append("C4d %d station(s) mesurable(s), plancher 8" % profs_lisse.size())
	elif d_ratio < SCAR_DEPTH_RATIO_MIN:
		faults.append("C4d ruban d'épaisseur constante, pas un volume arraché : max/min %.2f, plancher %.2f"
			% [d_ratio, SCAR_DEPTH_RATIO_MIN])

	# --- C4e : des échardes LE LONG du parcours, pas seulement aux deux plans
	# de rupture. Les plans sont trouvés dans les données (les deux altitudes
	# qui portent le plus de bases), pas codés en dur.
	var bases: Array[float] = []
	for comp2: PackedVector3Array in comps:
		if comp2.size() > 40 or comp2.size() < 5:
			continue
		var lo3: float = 1.0e9
		var hi3: float = -1.0e9
		var ex: float = 0.0
		var cx: Vector3 = Vector3.ZERO
		for v8: Vector3 in comp2:
			lo3 = minf(lo3, v8.y)
			hi3 = maxf(hi3, v8.y)
			cx += v8
		cx /= float(comp2.size())
		for v9: Vector3 in comp2:
			ex = maxf(ex, Vector2(v9.x - cx.x, v9.z - cx.z).length())
		if hi3 - lo3 < 0.30 or hi3 - lo3 < 1.4 * 2.0 * ex:
			continue
		bases.append(lo3)
	bases.sort()
	var plans: Array[float] = []
	for pass_i: int in range(2):
		var best_y: float = 0.0
		var best_n: int = 0
		for b2: float in bases:
			var n3: int = 0
			for b3: float in bases:
				if absf(b3 - b2) < 0.6:
					n3 += 1
			if n3 > best_n:
				best_n = n3
				best_y = b2
		if best_n < 2:
			break
		plans.append(best_y)
		var reste: Array[float] = []
		for b4: float in bases:
			if absf(b4 - best_y) >= 0.6:
				reste.append(b4)
		bases = reste
	var le_long: int = bases.size()
	print("[r2b2-arbre] C4e plans de rupture détectés %s ; échardes LE LONG du parcours %d"
		% [str(plans), le_long])
	if le_long < SCAR_SPLINTERS_MIN:
		faults.append("C4e aucun éclat hors des plans de rupture : %d, plancher %d"
			% [le_long, SCAR_SPLINTERS_MIN])
	check(faults.is_empty(), "C4 la cicatrice est un volume arraché (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])


## ===========================================================================
## C5 — TROIS PALIERS DE VALEUR, DANS LA FAMILLE, ET BUDGET
## ===========================================================================
## Le lead a porté la limite de matériaux de 3 à 4 le 2026-08-19 : il n'existe
## AUCUNE valeur intermédiaire entre écorce (luminance 0,218) et cœur (0,748),
## et une transition entre deux valeurs sans palier ne se fabrique pas par la
## géométrie seule. Condition 2 de son arbitrage : PALIER DE VALEUR, pas
## teinte neuve — d'où le contrôle de teinte et de saturation.
func test_c5_paliers_de_valeur_et_budget() -> void:
	var faults: Array[String] = []
	var nodes: Dictionary = _glb_nodes()
	var vus: Dictionary = {}
	var total: int = 0
	for name: String in nodes.keys():
		var spec: Dictionary = nodes[name] as Dictionary
		total += (spec["i"] as PackedInt32Array).size() / 3
		for c: Color in (spec["m"] as Array[Color]):
			vus["%.4f|%.4f|%.4f" % [c.r, c.g, c.b]] = c
	var lums: Array[float] = []
	var hues: Array[float] = []
	var sats: Array[float] = []
	for k: String in vus.keys():
		var c2: Color = vus[k]
		lums.append(_luminance(c2))
		hues.append(c2.h)
		sats.append(c2.s)
	lums.sort()
	var paliers: Array[float] = []
	for l: float in lums:
		if paliers.is_empty() or l - paliers[paliers.size() - 1] >= VALUE_GAP_MIN:
			paliers.append(l)
	print("[r2b2-arbre] C5 luminances %s → %d palier(s) séparé(s) d'au moins %.2f"
		% [str(lums), paliers.size(), VALUE_GAP_MIN])
	if paliers.size() < VALUE_STEPS_MIN:
		faults.append("C5 pas de valeur intermédiaire : %d palier(s), plancher %d"
			% [paliers.size(), VALUE_STEPS_MIN])
	# la famille : aucune teinte hors de l'intervalle des autres, ± tolérance
	var h_lo: float = 1.0
	var h_hi: float = 0.0
	var s_hi: float = 0.0
	for h: float in hues:
		h_lo = minf(h_lo, h)
		h_hi = maxf(h_hi, h)
	for s: float in sats:
		s_hi = maxf(s_hi, s)
	print("[r2b2-arbre] C5 teintes %.4f..%.4f (étendue %.4f), saturation max %.3f"
		% [h_lo, h_hi, h_hi - h_lo, s_hi])
	if h_hi - h_lo > HUE_SPAN_MAX:
		faults.append("C5 teinte neuve introduite : étendue de teinte %.4f, plafond %.4f"
			% [h_hi - h_lo, HUE_SPAN_MAX])
	if s_hi > SAT_MAX:
		faults.append("C5 saturation hors famille : %.3f, plafond %.3f" % [s_hi, SAT_MAX])
	print("[r2b2-arbre] C5 budget : %d triangles (plafond %d)" % [total, BUDGET_TRIS])
	if total > BUDGET_TRIS:
		faults.append("C5 budget dépassé : %d triangles, plafond %d" % [total, BUDGET_TRIS])
	check(faults.is_empty(), "C5 paliers de valeur et budget (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
