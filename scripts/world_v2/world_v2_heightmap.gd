## LA fonction de hauteur du monde V2 — unique, pure et déterministe (V2.1).
##
## Tout le relief sort d'ici : chunks visuels, collisions, sondes de tests,
## outils de bake. Deux chunks voisins échantillonnent la MÊME fonction aux
## MÊMES coordonnées entières : leur frontière est identique par construction
## — c'est la réponse contractuelle à l'interdit « chaque chunk avec un bruit
## indépendant » (prompt V2.1 §4).
##
## La fonction est la SOMME de champs analytiques lisses (crête sud, mur
## ouest en deux ressauts, hauteurs de l'est, contreforts, terrasses des
## ruines, rampe processionnelle, plateau du donjon, anneau frontalier),
## CREUSÉE par l'hydrologie (cours principal, affluent, lac), puis ANCRÉE par
## des « pads » de site : chaque lieu du layout tire doucement le terrain vers
## son altitude planifiée dans un petit rayon. Aucun aléatoire : uniquement
## des sinus déterministes — deux exécutions donnent le même monde au bit près.
##
## Ondulation volontaire partout (ISS-045 : la V1 était plate à 96,8 %) ;
## aucune dalle, aucune marche verticale artificielle aux ancres.
class_name WorldV2Heightmap
extends RefCounted

## Grille contractuelle (V2.0 §11 / V2.1 §4).
const CHUNK_SIZE_M: int = 64
const GRID_COLS: int = 8
const GRID_ROWS: int = 8
const ORIGIN_XZ: float = -256.0
const EXTENT_M: float = 512.0
const PLAYABLE_RADIUS_M: float = 235.0

## Hydrologie : demi-largeurs et profil des berges. Berges ordinaires RAIDES
## (≈ 56°, escaladables donc jamais un piège — D-019) ; gués en tablier LARGE
## et doux (leçon ISS-032 : la largeur utile dépasse la largeur visuelle).
const RIVER_BED_HALF_W: float = 3.0
const RIVER_BANK_W: float = 6.5
const FORD_BED_HALF_W: float = 4.0
## 20 m : à 16, la sortie diagonale du gué est cumulée à l'éperon du pylône
## gardait une bande à 1,0 m/m (46°) — la coupe de berge doit s'étaler.
const FORD_BANK_W: float = 20.0
const FORD_INFLUENCE_M: float = 24.0
const TRIB_BED_HALF_W: float = 1.8
const TRIB_BANK_W: float = 4.5
## Lac de l'Orage : bol profond. Le fond est une île de navigation VOULUE —
## exclue par l'obstruction d'eau profonde du bâtisseur d'hydrologie (le lit
## du bras nord, à 28°, descend naturellement dans le bol : la pente seule ne
## suffisait pas, c'était mesuré).
const LAKE_DEPTH: float = 6.0
const LAKE_SHORE_W: float = 10.0

## Rampe processionnelle (masterplan §2) : (0,2,-110) → (0,34,-165).
const RAMP_Z_START: float = -110.0
const RAMP_Z_END: float = -165.0
const RAMP_Y_START: float = 2.0
const RAMP_Y_END: float = 34.0
const RAMP_HALF_W: float = 7.0
const RAMP_BLEND_W: float = 10.0

## Anneau frontalier : montée 235 → 262, cols sinusoïdaux (§9 : des cols,
## pas un anneau parfaitement plat).
const RING_RISE: float = 45.0
const RING_START: float = 235.0
const RING_FULL: float = 262.0
const RING_COL_AMPLITUDE: float = 11.0

var _sites: Array[Dictionary] = []
var _river_main: PackedVector2Array = PackedVector2Array()
var _river_trib: PackedVector2Array = PackedVector2Array()
var _fords: Array[Vector2] = []
var _lake_center: Vector2 = Vector2.ZERO
var _lake_radius: float = 0.0

## SEAUX SPATIAUX — 270 000 échantillons appellent height_at() à chaque
## construction du monde : sans pré-indexation, chaque appel parcourait
## ~50 pads et ~25 segments de cours d'eau (des dizaines de millions
## d'opérations mesurées au premier jet). Grille de cellules de 32 m ;
## chaque pad/segment est inscrit dans TOUTES les cellules que touche son
## emprise d'influence — la recherche lit UNE cellule.
const BUCKET_CELL_M: float = 32.0
const BUCKET_COLS: int = 17
var _cell_sites: Dictionary = {}
var _cell_main_segments: Dictionary = {}
var _cell_trib_segments: Dictionary = {}
var _main_seg_t0: PackedFloat32Array = PackedFloat32Array()
var _main_seg_t1: PackedFloat32Array = PackedFloat32Array()
var _trib_seg_t0: PackedFloat32Array = PackedFloat32Array()
var _trib_seg_t1: PackedFloat32Array = PackedFloat32Array()


## Construit la fonction depuis la carte directrice. Les pads de site
## proviennent des POI, sites systémiques, checkpoints et ancres de région :
## la donnée du layout TRAVERSE le relief, elle n'est pas recopiée à la main.
func _init(layout: Dictionary) -> void:
	# Fondu de 12 m : à 8, un site perché (overlook_summit, +5 m sur son
	# anneau) faisait un mur de 48° à 15 m du sommet — le vrai joueur y
	# restait cloué, vitesse nulle, sol=true (mesuré au parcours réel).
	for entry: Variant in layout.get("pois", []) as Array:
		_add_site(entry as Dictionary, "v2_site", 9.0, 12.0)
	for entry: Variant in layout.get("systemic_sites", []) as Array:
		_add_site(entry as Dictionary, "v2_site", 8.0, 12.0)
	for entry: Variant in layout.get("checkpoints", []) as Array:
		var checkpoint: Dictionary = entry as Dictionary
		if checkpoint.get("pos") != null:
			_add_pad(checkpoint["pos"] as Array, 10.0, 9.0)
	for entry: Variant in layout.get("regions", []) as Array:
		var region: Dictionary = entry as Dictionary
		var anchor: Variant = region.get("save_anchor")
		if anchor != null and (anchor as Dictionary).get("pos") != null:
			_add_pad((anchor as Dictionary)["pos"] as Array, 7.0, 7.0)
	# Ancres §3.3 immuables — pads dédiés (spawn, camp, pylône, porte).
	# Fondu LARGE (16 m) : avec 10 m, le raccord du pad du pylône concentrait
	# la montée vers y=18 en une bande de 1,8 m/m sur le trajet principal.
	var anchors: Dictionary = layout.get("spec_anchors", {}) as Dictionary
	for key: String in ["spawn", "camp", "pylon", "dungeon_gate"]:
		if anchors.has(key):
			_add_pad(anchors[key] as Array, 11.0, 16.0)

	var river: Dictionary = layout.get("river", {}) as Dictionary
	for point: Variant in river.get("main_course_xz", []) as Array:
		_river_main.append(Vector2(float((point as Array)[0]), float((point as Array)[1])))
	for point: Variant in river.get("west_tributary_xz", []) as Array:
		_river_trib.append(Vector2(float((point as Array)[0]), float((point as Array)[1])))
	for entry: Variant in river.get("fords", []) as Array:
		var pos: Array = (entry as Dictionary).get("pos_xz", []) as Array
		if pos.size() == 2:
			_fords.append(Vector2(float(pos[0]), float(pos[1])))
	var mouth: Dictionary = river.get("mouth", {}) as Dictionary
	var mouth_center: Array = mouth.get("center_xz", [0, 0]) as Array
	_lake_center = Vector2(float(mouth_center[0]), float(mouth_center[1]))
	_lake_radius = float(mouth.get("radius_m", 14.0))

	_bake_buckets()


func _add_site(entry: Dictionary, key: String, radius: float, blend: float) -> void:
	var site: Variant = entry.get(key)
	if site == null:
		return
	_add_pad(site as Array, radius, blend)


func _add_pad(pos: Array, radius: float, blend: float) -> void:
	if pos.size() != 3:
		return
	_sites.append({
		"x": float(pos[0]), "y": float(pos[1]), "z": float(pos[2]),
		"r": radius, "b": blend,
	})


func _cell_key(x: float, z: float) -> int:
	var cx: int = clampi(int(floorf((x - ORIGIN_XZ) / BUCKET_CELL_M)), 0, BUCKET_COLS - 1)
	var cz: int = clampi(int(floorf((z - ORIGIN_XZ) / BUCKET_CELL_M)), 0, BUCKET_COLS - 1)
	return cz * BUCKET_COLS + cx


func _bucket_aabb(store: Dictionary, value: int, min_x: float, min_z: float,
		max_x: float, max_z: float) -> void:
	var cx0: int = clampi(int(floorf((min_x - ORIGIN_XZ) / BUCKET_CELL_M)), 0, BUCKET_COLS - 1)
	var cx1: int = clampi(int(floorf((max_x - ORIGIN_XZ) / BUCKET_CELL_M)), 0, BUCKET_COLS - 1)
	var cz0: int = clampi(int(floorf((min_z - ORIGIN_XZ) / BUCKET_CELL_M)), 0, BUCKET_COLS - 1)
	var cz1: int = clampi(int(floorf((max_z - ORIGIN_XZ) / BUCKET_CELL_M)), 0, BUCKET_COLS - 1)
	for cz: int in range(cz0, cz1 + 1):
		for cx: int in range(cx0, cx1 + 1):
			var key: int = cz * BUCKET_COLS + cx
			if not store.has(key):
				store[key] = PackedInt32Array()
			var bucket: PackedInt32Array = store[key]
			bucket.append(value)
			store[key] = bucket


func _bake_buckets() -> void:
	for i: int in range(_sites.size()):
		var site: Dictionary = _sites[i]
		var reach: float = float(site["r"]) + float(site["b"])
		_bucket_aabb(_cell_sites, i,
			float(site["x"]) - reach, float(site["z"]) - reach,
			float(site["x"]) + reach, float(site["z"]) + reach)
	var main_margin: float = FORD_BED_HALF_W + FORD_BANK_W + 4.0
	_bake_segment_buckets(_river_main, _cell_main_segments, _main_seg_t0,
		_main_seg_t1, main_margin)
	_bake_segment_buckets(_river_trib, _cell_trib_segments, _trib_seg_t0,
		_trib_seg_t1, main_margin)


func _bake_segment_buckets(line: PackedVector2Array, store: Dictionary,
		t0_out: PackedFloat32Array, t1_out: PackedFloat32Array,
		margin: float) -> void:
	if line.size() < 2:
		return
	var total: float = 0.0
	for i: int in range(line.size() - 1):
		total += line[i].distance_to(line[i + 1])
	t0_out.resize(line.size() - 1)
	t1_out.resize(line.size() - 1)
	var walked: float = 0.0
	for i: int in range(line.size() - 1):
		var seg_len: float = line[i].distance_to(line[i + 1])
		t0_out[i] = walked / maxf(total, 0.001)
		t1_out[i] = (walked + seg_len) / maxf(total, 0.001)
		walked += seg_len
		_bucket_aabb(store, i,
			minf(line[i].x, line[i + 1].x) - margin,
			minf(line[i].y, line[i + 1].y) - margin,
			maxf(line[i].x, line[i + 1].x) + margin,
			maxf(line[i].y, line[i + 1].y) + margin)


## Plus proche point parmi les SEGMENTS CANDIDATS de la cellule.
## Rendu [distance, t] — vide si aucun candidat.
func _closest_bucketed(p: Vector2, line: PackedVector2Array, store: Dictionary,
		t0_arr: PackedFloat32Array, t1_arr: PackedFloat32Array) -> Array:
	var key: int = _cell_key(p.x, p.y)
	if not store.has(key):
		return []
	var best_d: float = INF
	var best_t: float = 0.0
	for idx: int in store[key] as PackedInt32Array:
		var a: Vector2 = line[idx]
		var b: Vector2 = line[idx + 1]
		var seg: Vector2 = b - a
		var seg_len2: float = seg.length_squared()
		var t: float = 0.0
		if seg_len2 > 0.0:
			t = clampf((p - a).dot(seg) / seg_len2, 0.0, 1.0)
		var d: float = p.distance_to(a + seg * t)
		if d < best_d:
			best_d = d
			best_t = lerpf(t0_arr[idx], t1_arr[idx], t)
	if best_d == INF:
		return []
	return [best_d, best_t]


## Profils d'altitude du lit, MONOTONES descendants de la source à l'exutoire —
## une rivière qui remonte serait un mensonge spatial. Courbes ANALYTIQUES en
## t d'ARC (le t rendu par _closest_bucketed) : l'ancienne version cuisait un
## tableau indexé PAR POINT puis l'interrogeait en t d'arc — sur l'affluent,
## dont les segments vont de 13 à 40 m, la distorsion flottait la surface
## jusqu'à 1,4 m au-dessus du sol creusé (fosse de 1,73 m mesurée au gué ouest).
func _main_bed_curve(t: float) -> float:
	# Source ~11 (sous la Chute du Voile), descente rapide, bande centrale
	# -1,5, bras nord -1,5 → -2,5 vers le lac.
	var clamped: float = clampf(t, 0.0, 1.0)
	if clamped < 0.22:
		return lerpf(11.0, 0.5, clamped / 0.22)
	if clamped < 0.42:
		return lerpf(0.5, -1.5, (clamped - 0.22) / 0.2)
	return lerpf(-1.5, -2.5, (clamped - 0.42) / 0.58)


## Source de la terrasse (≈ 11) → chute au ressaut → confluence (≈ -0,5).
## Le bief calme démarre à 0,3 : son bassin (creux de sinus des plaines,
## ~1,1 m au sud du gué ouest) doit dominer la SURFACE — un lit à 2,2 y
## faisait flotter l'eau au-dessus de la prairie (contenance mesurée rouge).
func _trib_bed_curve(t: float) -> float:
	var clamped: float = clampf(t, 0.0, 1.0)
	if clamped < 0.34:
		return lerpf(11.0, 0.3, clamped / 0.34)
	return lerpf(0.3, -0.5, (clamped - 0.34) / 0.66)


## ---------------------------------------------------------------------------
## LA fonction. Pure : même (x, z) → même hauteur, toujours.
## ---------------------------------------------------------------------------
func height_at(x: float, z: float) -> float:
	var h: float = _fields(x, z)
	# Pads AVANT creusement : un site de berge tire le terrain vers son
	# altitude, puis la rivière creuse À TRAVERS — le lit reste ouvert
	# (l'ordre inverse endiguait le cours sous l'Arche de pierre).
	h = _apply_pads(x, z, h)
	h = _carve_rivers(x, z, h)
	# Rampe APRÈS creusement : c'est une STRUCTURE (chaussée processionnelle),
	# elle enjambe la rive est du lac au lieu d'être creusée par elle — le bol
	# du lac tirait la ligne centrale vers -6 avec ~2 m/m de gradient radial
	# (marche mesurée en (0,-153), test des dalles).
	h = _apply_ramp(x, z, h)
	return h


## Champs de relief additifs, tous lisses.
func _fields(x: float, z: float) -> float:
	# Plaines vallonnées : 3 ± ~2,2 m, deux fréquences déterministes.
	var h: float = 3.0 \
		+ 1.3 * sin(x * 0.031 + 1.7) * sin(z * 0.027 + 0.9) \
		+ 0.9 * sin(x * 0.011 - 0.5) * sin(z * 0.013 + 2.1)

	# Crête sud (balcon du spawn) : pente continue ≈ 30° max côté vallée.
	h += 21.0 * smoothstep(112.0, 168.0, z)

	# Mur ouest en DEUX ressauts escaladables (§3.3 : falaise d'apprentissage)
	# avec la terrasse de la Source entre les deux.
	h += 9.0 * smoothstep(110.0, 117.0, -x)
	h += 12.0 * smoothstep(138.0, 146.0, -x)
	h += 3.0 * smoothstep(150.0, 190.0, -x)

	# Hauteurs de l'Orient : bande z [-100, 56]. Montée ÉTALÉE sur 64 m, et
	# son PIED décollé du tablier du gué est — à 88 la montée démarrait sur la
	# coupe de berge (2,57 m/m mesurés d'abord, puis encore 1,19 m/m sur la
	# sortie diagonale du gué avec le pied à 88). Le fondu NORD est large
	# (44→96) : resserré (52→84), il tombait à 48° en travers de l'approche
	# du belvédère — le parcours réel y restait cloué en (165, 69).
	var east_z: float = smoothstep(-108.0, -80.0, z) * (1.0 - smoothstep(44.0, 96.0, z))
	h += 15.0 * smoothstep(94.0, 158.0, x) * east_z
	# Éperon du pylône : butte LARGE qui porte presque toute l'altitude de
	# l'ancre (18 m) — un pad qui devait combler 8 m en 10 m de fondu créait
	# une bande à 1,8 m/m sur l'approche (109,-10). Rayon 52 : à 44, le
	# flanc ouest cumulé au pad restait ≥ 46° et le parcours réel s'y est
	# cloué en (94, -17) — un promeneur dévié doit toujours pouvoir REVENIR.
	h += 9.0 * _bump(x, z, 115.0, -25.0, 48.0)
	# Butte du belvédère (à gravir) — LARGE : à r=22 son anneau tombait de
	# 5 m en quelques mètres et s'empilait sur le pad du sommet (48°).
	h += 5.0 * _bump(x, z, 168.0, 52.0, 30.0)
	# Col de la Gorge du vent (96,12,-88) : la crête qui le porte — sans elle,
	# le pad du POI devait hisser 8 m au-dessus des plaines en 8 m de fondu
	# (1,4 m/m mesurés en 84,-93 sur le trajet principal).
	h += 8.0 * _bump(x, z, 96.0, -88.0, 34.0)

	# Contreforts du nord-ouest.
	h += 9.0 * smoothstep(80.0, 140.0, -z) * smoothstep(20.0, 90.0, -x)

	# Terrasses des Ruines du Cœur (le centre n'est plus vide).
	h += 3.5 * _bump(x, z, 0.0, -64.0, 48.0)

	# Plateau du donjon (la rampe, structure bâtie, est plaquée dans height_at
	# APRÈS le creusement — voir _apply_ramp).
	h += 31.0 * smoothstep(150.0, 172.0, -z)

	# Anneau frontalier : montée + cols (jamais un anneau plat).
	var radius: float = Vector2(x, z).length()
	var ring: float = smoothstep(RING_START, RING_FULL, radius)
	if ring > 0.0:
		var azimuth: float = atan2(z, x)
		h += ring * (RING_RISE + RING_COL_AMPLITUDE * (0.5 + 0.5 * sin(azimuth * 8.0 + 1.3)))
	return h


func _bump(x: float, z: float, cx: float, cz: float, radius: float) -> float:
	var d: float = Vector2(x - cx, z - cz).length()
	return 1.0 - smoothstep(0.0, radius, d)


## Creuse le cours principal, l'affluent et le lac. Le lit est TOUJOURS plus
## bas que ses berges ; les gués élargissent et adoucissent le profil.
func _carve_rivers(x: float, z: float, h: float) -> float:
	var p: Vector2 = Vector2(x, z)

	var main_hit: Array = _closest_bucketed(p, _river_main, _cell_main_segments,
		_main_seg_t0, _main_seg_t1)
	if not main_hit.is_empty():
		var d: float = main_hit[0]
		var bed: float = _main_bed_curve(main_hit[1])
		var ford_factor: float = _ford_factor(p)
		var bed_half: float = lerpf(RIVER_BED_HALF_W, FORD_BED_HALF_W, ford_factor)
		var bank: float = lerpf(RIVER_BANK_W, FORD_BANK_W, ford_factor)
		# SEUIL de gué : le lit remonte au cœur du gué (traversée à ~0,35 m
		# d'eau, pas 0,9) — un gué praticable est un haut-fond, pas un trou.
		bed += 0.55 * ford_factor
		if d < bed_half + bank:
			var target: float = minf(h, bed)
			h = lerpf(target, h, smoothstep(bed_half, bed_half + bank, d))

	var trib_hit: Array = _closest_bucketed(p, _river_trib, _cell_trib_segments,
		_trib_seg_t0, _trib_seg_t1)
	if not trib_hit.is_empty():
		var d: float = trib_hit[0]
		var ford_factor: float = _ford_factor(p)
		var bed_half: float = lerpf(TRIB_BED_HALF_W, 3.5, ford_factor)
		var bank: float = lerpf(TRIB_BANK_W, 12.0, ford_factor)
		if d < bed_half + bank:
			var bed: float = _trib_bed_curve(trib_hit[1]) + 0.3 * ford_factor
			var target: float = minf(h, bed)
			h = lerpf(target, h, smoothstep(bed_half, bed_half + bank, d))

	var lake_d: float = p.distance_to(_lake_center)
	if lake_d < _lake_radius + LAKE_SHORE_W:
		var bowl: float = -LAKE_DEPTH
		h = lerpf(bowl, h, smoothstep(_lake_radius * 0.55, _lake_radius + LAKE_SHORE_W, lake_d))
	return h


## Rampe processionnelle (0,2,-110) → (0,34,-165) : chaussée PLAQUÉE sur le
## relief déjà creusé. `maxf` : la structure ne creuse jamais, elle porte.
## Fenêtre en z à FONDUS DOUX aux deux bouts — l'ancienne frontière dure
## (`z >= RAMP_Z_END - 8`) ne tenait que par la phase favorable des sinus.
func _apply_ramp(x: float, z: float, h: float) -> float:
	var corridor: float = 1.0 - smoothstep(RAMP_HALF_W, RAMP_HALF_W + RAMP_BLEND_W, absf(x))
	if corridor <= 0.0:
		return h
	var fade_south: float = 1.0 - smoothstep(RAMP_Z_START, RAMP_Z_START + 10.0, z)
	var fade_north: float = smoothstep(RAMP_Z_END - 18.0, RAMP_Z_END - 8.0, z)
	var z_fade: float = fade_south * fade_north
	if z_fade <= 0.0:
		return h
	var ramp_t: float = clampf((RAMP_Z_START - z) / (RAMP_Z_START - RAMP_Z_END), 0.0, 1.0)
	var ramp_h: float = RAMP_Y_START + (RAMP_Y_END - RAMP_Y_START) * ramp_t
	return lerpf(h, maxf(h, ramp_h), corridor * z_fade)


## Adoucissement de gué : 1 au cœur du gué, 0 au-delà de son influence.
func _ford_factor(p: Vector2) -> float:
	var factor: float = 0.0
	for ford: Vector2 in _fords:
		factor = maxf(factor, 1.0 - smoothstep(0.0, FORD_INFLUENCE_M, p.distance_to(ford)))
	return factor


## Ancre chaque site du layout à son altitude planifiée, en tirant doucement
## le terrain : pente de raccord bornée par (rayon de fondu), aucune marche.
func _apply_pads(x: float, z: float, h: float) -> float:
	var key: int = _cell_key(x, z)
	if not _cell_sites.has(key):
		return h
	for site_index: int in _cell_sites[key] as PackedInt32Array:
		var site: Dictionary = _sites[site_index]
		var dx: float = x - float(site["x"])
		var dz: float = z - float(site["z"])
		var r: float = float(site["r"])
		var b: float = float(site["b"])
		var d2: float = dx * dx + dz * dz
		var reach: float = r + b
		if d2 >= reach * reach:
			continue
		var d: float = sqrt(d2)
		var pull: float = 1.0 - smoothstep(r, reach, d)
		h = lerpf(h, float(site["y"]), pull)
	return h


## ---------------------------------------------------------------------------
## Services aux bâtisseurs et aux tests
## ---------------------------------------------------------------------------

## L'eau au point demandé : surface si le point est dans une emprise d'eau,
## sinon -INF. Sert aux tests « aucune eau au checkpoint/à l'ancre ».
func water_surface_at(x: float, z: float) -> float:
	var p: Vector2 = Vector2(x, z)
	var lake_d: float = p.distance_to(_lake_center)
	if lake_d < _lake_radius:
		return -0.5
	var main_hit: Array = _closest_bucketed(p, _river_main, _cell_main_segments,
		_main_seg_t0, _main_seg_t1)
	if not main_hit.is_empty() and float(main_hit[0]) < FORD_BED_HALF_W + 1.0:
		return _main_bed_curve(float(main_hit[1])) + 0.9
	var trib_hit: Array = _closest_bucketed(p, _river_trib, _cell_trib_segments,
		_trib_seg_t0, _trib_seg_t1)
	if not trib_hit.is_empty() and float(trib_hit[0]) < TRIB_BED_HALF_W + 1.2:
		return _trib_bed_curve(float(trib_hit[1])) + 0.6
	return -INF


func is_in_water(x: float, z: float) -> bool:
	var surface: float = water_surface_at(x, z)
	return surface > -INF and height_at(x, z) < surface


## Pente locale en degrés (différences centrales sur 1 m).
func slope_deg_at(x: float, z: float) -> float:
	var step: float = 0.5
	var dx: float = (height_at(x + step, z) - height_at(x - step, z)) / (2.0 * step)
	var dz: float = (height_at(x, z + step) - height_at(x, z - step)) / (2.0 * step)
	return rad_to_deg(atan(Vector2(dx, dz).length()))


func river_main_polyline() -> PackedVector2Array:
	return _river_main


func river_trib_polyline() -> PackedVector2Array:
	return _river_trib


func fords() -> Array[Vector2]:
	return _fords


func lake_center() -> Vector2:
	return _lake_center


func lake_radius() -> float:
	return _lake_radius


## Distance au cours d'eau le plus proche (main + affluent), INF si aucun.
func distance_to_water_course(x: float, z: float) -> float:
	var p: Vector2 = Vector2(x, z)
	var best: float = INF
	var main_hit: Array = _closest_bucketed(p, _river_main, _cell_main_segments,
		_main_seg_t0, _main_seg_t1)
	if not main_hit.is_empty():
		best = minf(best, float(main_hit[0]))
	var trib_hit: Array = _closest_bucketed(p, _river_trib, _cell_trib_segments,
		_trib_seg_t0, _trib_seg_t1)
	if not trib_hit.is_empty():
		best = minf(best, float(trib_hit[0]))
	return best
