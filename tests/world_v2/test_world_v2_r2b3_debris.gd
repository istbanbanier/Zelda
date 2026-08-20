## V2.3-A.R2B.3 — FILET de l'agent A : les gravats de la ferme doivent être des
## FRAGMENTS, pas des pavés droits alignés.
##
## ORIGINE — ISS-060. Verdict visuel du lead sur R2B.2 : la ferme passe, SAUF
## `SM_Farm_Debris_A` et `SM_Farm_Debris_B`, qui « lisent encore comme des pavés
## droits alignés, donc comme une bordure construite plutôt que comme des débris
## d'effondrement ». C'est le dernier défaut bloquant du lot.
##
## LE DÉFAUT EST MESURÉ, jamais supposé. Sur le GLB de départ — sha256
## `9c7b94e1848dc1a1d33967343ee1c2a7868b38ab239d003de6cf4dcbc3216b3c`, journal
## `evidence/world_v2/v2_3_r2b3/debris/02_instrument_rouge_avant.log` :
##
##   mesh               comp  tris   liant   aire tot.  aire méd.  aire fine
##   SM_Farm_Debris_A     11   124   96,8 %    3,9764    0,32639     0,000 %
##   SM_Farm_Debris_B     11   124   96,8 %    4,1805    0,46180     0,000 %
##
## Cause exacte : `gravats()` construit chaque éclat avec `poutre()`, et une
## poutre EST un pavé — douze triangles, huit sommets soudés. Dix poutres sur
## onze composantes, d'où 120/124.
##
## CALIBRAGE DU PLAFOND — ET LE PREMIER TÉMOIN ÉTAIT MAUVAIS. Le lead avait
## calibré sur `SM_ThunderstruckTree.glb` (10,4 %). L'audit indépendant a
## proposé la MÊME FAMILLE D'OBJET que celle jugée ici :
## `SM_Dungeon_RubbleLarge`, tas de gravats accepté, **0,00 %** pour
## 150 triangles et 10 composantes — soit 15 triangles par fragment. C'est cette
## valeur qu'on vise, pas 24,9. Le plafond de 25 est un plafond, pas une cible.
##
## LE LIANT A CHANGÉ DE DÉFINITION LE 2026-08-20, DANS LE SENS STRICT. Il vaut
## désormais `hexa` **OU** `pave6` : 12 triangles et 8 sommets, ou exactement
## 6 plans et 8 coins (un coin étant un sommet touchant au moins trois plans).
## Raison mesurée par l'audit : `hexa` seul tombait à 0 % sous quatre
## perturbations qui ne changent RIEN à l'image — un triangle d'aire nulle, une
## subdivision coplanaire, un coin décalé de 12 µm, un pavé réparti sur deux
## primitives — et `Debris_A` en portait déjà trois. Le risque n'était pas la
## fraude : c'était un VERT ACCIDENTEL après remaillage, qui aurait fait croire
## à une réussite. Ce fichier recalcule donc le prédicat CORRIGÉ, à l'identique.
##
## POURQUOI SEPT CRITÈRES ET NON UN SEUL. Il existe quatre façons de faire
## tomber un pourcentage sans traiter le sujet : **supprimer** les débris, les
## **rétrécir**, les **pulvériser** en bruit sous-pixel, les **subdiviser**. Un
## plafond de boîtitude seul récompenserait les quatre. Les planchers qui
## l'accompagnent sont donc aussi liants que lui, et aucun ne doit être relevé :
## un seuil déplacé pour faire passer une correction est un portail qui
## s'affaiblit sans que personne ne mente (`tests/CLAUDE.md`, « ne jamais
## assouplir un seuil »). Deux ont bougé pendant cette passe — le plancher
## d'arête, RETIRÉ, et le budget par tas, AJOUTÉ — les deux décidés par le lead
## sur constat de l'audit indépendant, et les deux avant de voir ce résultat.
##
## POURQUOI CE FILET RECALCULE LE LIANT EN GDSCRIPT au lieu d'appeler
## `tools/mesure_boititude.py`. Un test Godot ne lance pas de processus, et un
## second calcul indépendant vaut mieux qu'un appel : si les deux implémentations
## — Python sur les octets du GLB, GDScript sur le maillage importé — rendent le
## même 96,8 % en rouge puis le même chiffre en vert, c'est le prédicat qui est
## vérifié, pas une seule ligne de code. Le journal rouge publie les deux.
##
## PIÈGE DE SOUDAGE, mesuré et non supposé. Ici les positions passent par
## l'importeur Godot, dont `meshes/force_disable_compression=false` (voir
## `SM_Farm_Ruins.glb.import`) quantifie les positions sur l'AABB. Une tolérance
## de 10 µm — celle de la première version de l'instrument — serait cassée par
## cette quantification, donc les comptes de sommets, donc le prédicat. 0,1 mm
## absorbe la quantification tout en restant plusieurs centaines de fois sous la
## plus courte arête du tas (0,059 m), donc incapable de fusionner deux coins
## distincts. L'instrument Python a convergé vers la même valeur pour une raison
## voisine : l'audit y a montré qu'à 10 µm un coin déplacé de 12 µm se dédoublait.
##
## LA PREUVE QUE CE CHOIX EST JUSTE EST LE ROUGE LUI-MÊME : le filet a rendu
## EXACTEMENT les 11 composantes / 124 triangles / 96,8 % que l'instrument Python
## rend sur les mêmes meshes, à 4 µm près sur l'arête minimale — écart qui EST la
## quantification, et qui est publié plutôt que caché.
extends GateTestCase

const FARM_GLB: String = "res://assets/architecture/farm/SM_Farm_Ruins.glb"

const DEBRIS_A: String = "SM_Farm_Debris_A"
const DEBRIS_B: String = "SM_Farm_Debris_B"

## Soudage par position. Voir le piège documenté en tête de fichier. La valeur
## est celle de l'instrument depuis sa correction du 2026-08-20 : à 10 µm,
## déplacer un coin de 12 µm dédoublait le sommet et suffisait à faire tomber le
## liant sans qu'un pixel bouge.
const SOUDAGE_M: float = 1.0e-4
## Tolérances de plan, reprises À L'IDENTIQUE de `tools/mesure_boititude.py`.
const NORMALE_DOT: float = 0.999
const PLAN_EPS: float = 1.0e-3
const AIRE_NULLE: float = 1.0e-10
## Un triangle dont la plus longue arête est sous 2 mm est de la poussière.
const FINESSE_M: float = 2.0e-3

## -- Le liant : le plafond de boîtitude --------------------------------------
## `hexa` = composante de 12 triangles ET 8 sommets géométriques après soudage.
## C'est le plus LÂCHE des trois prédicats de `tools/mesure_boititude.py`, à
## dessein : on ne le fait pas tomber en secouant les coins d'un cube — il faut
## changer la TOPOLOGIE. Plafond posé par le lead, non négociable.
const HEXA_PLAFOND_PCT: float = 25.0

## -- Plancher 1 : les débris ne disparaissent pas -----------------------------
const COMPOSANTES_MIN: int = 9

## -- Plancher 2 : pas de rétrécissement ---------------------------------------
## 80 % de l'aire mesurée avant (3,9764 et 4,1805 m²).
const AIRE_TOTALE_MIN_A_M2: float = 3.20
const AIRE_TOTALE_MIN_B_M2: float = 3.35

## -- Plancher 3 : un fragment reste MACROSCOPIQUE -----------------------------
## Médiane d'aire de composante. Un tas pulvérisé en gravier s'effondrerait ici
## bien avant que la boîtitude ne bouge.
const AIRE_MEDIANE_MIN_M2: float = 0.08

## -- Plancher 4 : pas de bruit sous-pixel -------------------------------------
## La directive l'interdit explicitement : « aucun détail sous-pixel destiné
## seulement à faire tomber le chiffre ».
##
## DEUX FOIS CORRIGÉ PAR LE LEAD, ET LA SECONDE FOIS LE CRITÈRE A ÉTÉ RETIRÉ.
## Il exigeait d'abord `arete_min ≥ 0,03 m`, puis `≥ 0,005 m`. L'audit
## indépendant a montré que même 0,005 rejetait la grotte (0,000365 m), le pont
## (0,000573 m) et le cœur de l'arbre foudroyé (0,003941 m) — trois assets
## GELÉS et VALIDÉS de ce projet. Le défaut n'était pas le nombre : `arete_min`
## est une statistique d'ordre extrême, fixée par UN triangle sur 3 574, donc
## un plancher qui juge un maillage entier sur son pire point isolé.
##
## REMPLACÉ PAR UNE PART D'AIRE, qui ne peut monter qu'en pulvérisant vraiment
## la géométrie : `aire_fine` = part de l'aire portée par des triangles dont la
## plus longue arête est sous 2 mm. Mesurée à 0,0000 % sur les huit assets
## acceptés, et à 0,0000 % ici. `arete_min` reste PUBLIÉE dans la trace du test,
## sans être liante — un nombre qu'on regarde n'est pas un nombre qui bloque.
const AIRE_FINE_MAX_PCT: float = 1.0

## -- Plancher 5 : l'implantation ne bouge pas ---------------------------------
## Emprise POSITION du GLB de départ, repère local du mesh (X, Y = hauteur, Z),
## `evidence/world_v2/v2_3_r2b3/debris/03_empreinte_avant.log`.
const EMPRISE_BASE_A: Vector3 = Vector3(1.4279, 0.6841, 1.1525)
const EMPRISE_BASE_B: Vector3 = Vector3(1.1721, 0.6852, 1.0310)
## Le tas peut respirer en hauteur — un centre plus haut est demandé — mais son
## emprise au sol tient la place que le lieu lui a donnée.
const EMPRISE_TOL_XZ: float = 0.20
const EMPRISE_TOL_Y: float = 0.30

## -- Plancher 6 : le budget PAR TAS -------------------------------------------
## Ajouté par le lead sur constat de l'audit : le plafond global de 4 500
## laissait un facteur ×13,4 sur la densité des débris — assez pour faire tomber
## le liant en subdivisant les faces plutôt qu'en changeant de forme. Le témoin
## de la bonne économie est `SM_Dungeon_RubbleLarge`, tas accepté : 150 triangles
## pour 10 composantes, soit 15 par fragment.
const TRIS_MAX_PAR_TAS: int = 600

## -- Plancher 7 : le budget de la ferme ---------------------------------------
## Le plafond du générateur, inchangé depuis R2B.
const BUDGET_TRIS_MAX: int = 4500
## Plancher de masse : la ruine porte 2 080 triangles avant cette passe ; un
## effondrement du total signalerait une pièce perdue, pas une correction.
const BUDGET_TRIS_MIN: int = 1900


## ---------------------------------------------------------------------------
## LE CONTRÔLE PRINCIPAL — un tas de débris n'est pas un empilement de pavés
## ---------------------------------------------------------------------------

func test_les_gravats_ne_sont_pas_des_paves() -> void:
	var faults: Array[String] = []
	var packed: PackedScene = load(FARM_GLB) as PackedScene
	var inspectes: int = 0
	if packed == null:
		faults.append("GLB illisible : %s" % FARM_GLB)
	else:
		var root: Node3D = packed.instantiate() as Node3D
		var attendus: Dictionary = {
			DEBRIS_A: {"aire": AIRE_TOTALE_MIN_A_M2, "emprise": EMPRISE_BASE_A},
			DEBRIS_B: {"aire": AIRE_TOTALE_MIN_B_M2, "emprise": EMPRISE_BASE_B},
		}
		for nom: String in [DEBRIS_A, DEBRIS_B]:
			var mi: MeshInstance3D = _mesh_nomme(root, nom)
			if mi == null or mi.mesh == null:
				faults.append("%s : mesh absent du GLB — un tas supprimé n'est "
					% nom + "pas un tas corrigé")
				continue
			inspectes += 1
			var m: Dictionary = _morphometrie(mi.mesh)
			var tris: int = int(m["triangles"])
			var pct: float = 0.0
			if tris > 0:
				pct = 100.0 * float(m["tris_hexa"]) / float(tris)
			# LE LIANT.
			if pct > HEXA_PLAFOND_PCT:
				faults.append(("%s : %.1f %% de triangles en PAVÉS (liant = "
					+ "12 triangles et 8 sommets, OU 6 plans et 8 coins), "
					+ "plafond %.1f %% — %d composante(s) sur %d en sont ; le "
					+ "tas se lit comme une bordure construite")
					% [nom, pct, HEXA_PLAFOND_PCT, int(m["comp_hexa"]),
					   int(m["composantes"])])
			# PLANCHER 1 — les débris ne disparaissent pas.
			if int(m["composantes"]) < COMPOSANTES_MIN:
				faults.append("%s : %d composante(s), plancher %d — supprimer "
					% [nom, int(m["composantes"]), COMPOSANTES_MIN]
					+ "des fragments ferait tomber la boîtitude sans corriger "
					+ "l'image")
			# PLANCHER 6 — pas de subdivision.
			if tris > TRIS_MAX_PAR_TAS:
				faults.append("%s : %d triangles, plafond %d par tas — "
					% [nom, tris, TRIS_MAX_PAR_TAS] + "subdiviser les faces "
					+ "fait tomber le liant sans changer la forme")
			# PLANCHER 2 — pas de rétrécissement.
			var aire_min: float = float((attendus[nom] as Dictionary)["aire"])
			if float(m["aire_totale"]) < aire_min:
				faults.append("%s : aire totale %.4f m², plancher %.2f m² — un "
					% [nom, float(m["aire_totale"]), aire_min]
					+ "tas rétréci n'est pas un tas cassé")
			# PLANCHER 3 — un fragment reste macroscopique.
			if float(m["aire_mediane"]) < AIRE_MEDIANE_MIN_M2:
				faults.append("%s : aire médiane de composante %.5f m², "
					% [nom, float(m["aire_mediane"])]
					+ "plancher %.2f m² — le tas est pulvérisé, pas fracturé"
					% AIRE_MEDIANE_MIN_M2)
			# PLANCHER 4 — pas de bruit sous-pixel.
			if float(m["aire_fine_pct"]) > AIRE_FINE_MAX_PCT:
				faults.append("%s : %.4f %% de l'aire portée par des triangles "
					% [nom, float(m["aire_fine_pct"])]
					+ "de moins de 2 mm, plafond %.2f %% — un détail invisible "
					% AIRE_FINE_MAX_PCT
					+ "à l'écran ne corrige aucune lecture")
			# PLANCHER 5 — l'implantation ne bouge pas.
			var base: Vector3 = (attendus[nom] as Dictionary)["emprise"]
			var vue: Vector3 = m["emprise"]
			var noms_axes: Array[String] = ["X", "Y (hauteur)", "Z"]
			var tols: Array[float] = [EMPRISE_TOL_XZ, EMPRISE_TOL_Y,
				EMPRISE_TOL_XZ]
			for k: int in range(3):
				var att: float = base[k]
				var tol: float = tols[k] * att
				if absf(vue[k] - att) > tol:
					faults.append("%s : emprise %s = %.4f m, attendue %.4f "
						% [nom, noms_axes[k], vue[k], att]
						+ "± %.4f m — l'implantation du lieu a bougé" % tol)
			print("[r2b3_debris] %-20s comp=%d tris=%d liant=%.1f%% "
				% [nom, int(m["composantes"]), tris, pct]
				+ "aire_tot=%.4f aire_med=%.5f fine=%.4f%% arete_min=%.6f "
				% [float(m["aire_totale"]), float(m["aire_mediane"]),
				   float(m["aire_fine_pct"]), float(m["arete_min"])]
				+ "emprise=%.4f x %.4f x %.4f" % [vue.x, vue.y, vue.z])
		root.free()
	if inspectes < 2:
		faults.append("%d tas inspecté(s) sur 2 — le contrôle ne regarde rien"
			% inspectes)
	check(faults.is_empty(),
		"les gravats de la ferme sont des fragments et non des pavés "
		+ "(%d écart(s)) — %s" % [faults.size(), _capped(faults)])


## ---------------------------------------------------------------------------
## LE BUDGET ET LA MATIÈRE — une correction de forme ne paie pas en triangles
## ni en UV perdues
## ---------------------------------------------------------------------------
##
## L'UV0 est ici parce que R2B.2 l'a conquise : les douze pièces `SM_Farm_*`
## n'avaient AUCUN `ARRAY_FORMAT_TEX_UV`, ce qui produisait le « carton » que le
## lead a rejeté. Une nouvelle primitive de fragment qui oublierait le dépliage
## ramènerait le défaut par la porte de service, et le plafond de boîtitude,
## lui, serait parfaitement content.

func test_le_budget_tient_et_toute_primitive_porte_ses_uv() -> void:
	var faults: Array[String] = []
	var packed: PackedScene = load(FARM_GLB) as PackedScene
	var total: int = 0
	var surfaces: int = 0
	if packed == null:
		faults.append("GLB illisible : %s" % FARM_GLB)
	else:
		var root: Node3D = packed.instantiate() as Node3D
		for child: Node in root.find_children("*", "MeshInstance3D", true,
				false):
			var mi: MeshInstance3D = child as MeshInstance3D
			if mi.mesh == null:
				continue
			for s: int in range(mi.mesh.get_surface_count()):
				surfaces += 1
				var arrays: Array = mi.mesh.surface_get_arrays(s)
				var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				total += idx.size() / 3
				var uv: Variant = arrays[Mesh.ARRAY_TEX_UV]
				if uv == null or (uv as PackedVector2Array).is_empty():
					faults.append("%s surface %d : aucune UV0 — la matière du "
						% [String(child.name), s] + "kit ne peut pas s'y "
						+ "plaquer, la pièce redevient du carton")
		root.free()
	if surfaces < 20:
		faults.append("%d surface(s) inspectée(s) (plancher 20) — le contrôle "
			% surfaces + "ne regarde rien")
	if total > BUDGET_TRIS_MAX:
		faults.append("budget DÉPASSÉ : %d triangles (plafond %d)"
			% [total, BUDGET_TRIS_MAX])
	if total < BUDGET_TRIS_MIN:
		faults.append("%d triangles seulement (plancher %d) — une pièce a "
			% [total, BUDGET_TRIS_MIN] + "disparu")
	print("[r2b3_debris] ferme entière : %d triangles, %d surfaces"
		% [total, surfaces])
	check(faults.is_empty(),
		"la ferme tient son budget et chaque primitive porte ses UV "
		+ "(%d écart(s)) — %s" % [faults.size(), _capped(faults)])


## ---------------------------------------------------------------------------
## Morphométrie — seconde implémentation du prédicat de `mesure_boititude.py`
## ---------------------------------------------------------------------------
##
## ORDRE IMPOSÉ, et il n'est pas cosmétique : le soudage par POSITION vient
## d'abord, la connexité ensuite, sur les identifiants géométriques. La première
## version de l'instrument Python fusionnait les deux en une seule union-find ;
## chaque composante s'effondrait alors sur un sommet racine unique, « 8 sommets »
## ne pouvait jamais être vrai, et l'outil rendait 0,0 % sur un maillage à
## 79,6 %. Le même piège attend ici.

func _morphometrie(mesh: Mesh) -> Dictionary:
	var lo: Vector3 = Vector3(INF, INF, INF)
	var hi: Vector3 = Vector3(-INF, -INF, -INF)

	# ÉTAPE 1 — soudage par POSITION, sur TOUTES les primitives à la fois.
	# Les surfaces sont fusionnées avant l'analyse : un pavé réparti sur deux
	# primitives par un découpage matériau resterait sinon invisible au liant,
	# et c'est un des quatre verts accidentels que l'audit a démontrés.
	var grille: Dictionary = {}
	var coord: Array[Vector3] = []
	var tris: Array[Vector3i] = []
	for s: int in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(s)
		var sommets: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var geo_de: Array[int] = []
		for v: Vector3 in sommets:
			lo = Vector3(minf(lo.x, v.x), minf(lo.y, v.y), minf(lo.z, v.z))
			hi = Vector3(maxf(hi.x, v.x), maxf(hi.y, v.y), maxf(hi.z, v.z))
			var cle: Vector3i = Vector3i(
				roundi(v.x / SOUDAGE_M), roundi(v.y / SOUDAGE_M),
				roundi(v.z / SOUDAGE_M))
			if not grille.has(cle):
				grille[cle] = coord.size()
				coord.append(v)
			geo_de.append(int(grille[cle]))
		var t: int = 0
		while t + 2 < indices.size():
			tris.append(Vector3i(geo_de[indices[t]], geo_de[indices[t + 1]],
				geo_de[indices[t + 2]]))
			t += 3

	# LES TRIANGLES DÉGÉNÉRÉS SONT ÉCARTÉS AVANT TOUT COMPTAGE : un seul
	# triangle d'aire nulle ajouté à un pavé le faisait passer de 12 à 13
	# triangles, donc « pas une boîte », sans qu'un pixel ne change.
	var vivants: Array[Vector3i] = []
	var normales: Array[Vector3] = []
	var surfaces: Array[float] = []
	for tri: Vector3i in tris:
		var brut: Vector3 = (coord[tri.y] - coord[tri.x]).cross(
			coord[tri.z] - coord[tri.x])
		var aire_tri: float = 0.5 * brut.length()
		if aire_tri <= AIRE_NULLE:
			continue
		vivants.append(tri)
		normales.append(brut.normalized())
		surfaces.append(aire_tri)

	# ÉTAPE 2 — connexité sur les identifiants GÉOMÉTRIQUES.
	var parent: Array[int] = []
	parent.resize(coord.size())
	for i: int in range(coord.size()):
		parent[i] = i
	for tri: Vector3i in vivants:
		_unir(parent, tri.x, tri.y)
		_unir(parent, tri.y, tri.z)

	var groupes: Dictionary = {}
	for i: int in range(vivants.size()):
		var r: int = _racine(parent, vivants[i].x)
		if not groupes.has(r):
			groupes[r] = []
		(groupes[r] as Array).append(i)

	var composantes: int = 0
	var comp_liant: int = 0
	var tris_liant: int = 0
	var aire_totale: float = 0.0
	var aire_fine: float = 0.0
	var arete_min: float = INF
	var aires: Array[float] = []

	for cle_g: int in groupes.keys():
		var membres: Array = groupes[cle_g]
		var vus: Dictionary = {}
		var aire: float = 0.0
		# Un PLAN : normale signée + distance à l'origine, avec les mêmes
		# tolérances que l'instrument (0,999 sur le produit scalaire, 1 mm sur
		# la distance). Un sommet né d'une subdivision coplanaire ne touche
		# qu'un plan ; il n'est donc pas un COIN.
		var plan_n: Array[Vector3] = []
		var plan_d: Array[float] = []
		var plan_s: Array[Dictionary] = []
		for idx: int in membres:
			var tri: Vector3i = vivants[idx]
			var n: Vector3 = normales[idx]
			vus[tri.x] = true
			vus[tri.y] = true
			vus[tri.z] = true
			aire += surfaces[idx]
			var d: float = n.dot(coord[tri.x])
			var trouve: int = -1
			for p: int in range(plan_n.size()):
				if n.dot(plan_n[p]) >= NORMALE_DOT \
						and absf(d - plan_d[p]) <= PLAN_EPS:
					trouve = p
					break
			if trouve < 0:
				plan_n.append(n)
				plan_d.append(d)
				plan_s.append({tri.x: true, tri.y: true, tri.z: true})
			else:
				plan_s[trouve][tri.x] = true
				plan_s[trouve][tri.y] = true
				plan_s[trouve][tri.z] = true
			var longue: float = 0.0
			for paire: Vector2i in [Vector2i(tri.x, tri.y),
					Vector2i(tri.y, tri.z), Vector2i(tri.z, tri.x)]:
				if paire.x == paire.y:
					continue
				var dist: float = coord[paire.x].distance_to(coord[paire.y])
				longue = maxf(longue, dist)
				if dist > 0.0 and dist < arete_min:
					arete_min = dist
			if longue < FINESSE_M:
				aire_fine += surfaces[idx]
		var incidences: Dictionary = {}
		for p: int in range(plan_s.size()):
			for s_id: int in plan_s[p].keys():
				incidences[s_id] = int(incidences.get(s_id, 0)) + 1
		var coins: int = 0
		for k: int in incidences.values():
			if k >= 3:
				coins += 1
		composantes += 1
		aires.append(aire)
		aire_totale += aire
		if (membres.size() == 12 and vus.size() == 8) \
				or (plan_n.size() == 6 and coins == 8):
			comp_liant += 1
			tris_liant += membres.size()

	aires.sort()
	var mediane: float = 0.0
	if not aires.is_empty():
		mediane = aires[aires.size() >> 1]
	var fine_pct: float = 0.0
	if aire_totale > 0.0:
		fine_pct = 100.0 * aire_fine / aire_totale
	var arete: float = 0.0
	if arete_min != INF:
		arete = arete_min
	return {
		"composantes": composantes,
		"comp_hexa": comp_liant,
		"triangles": vivants.size(),
		"tris_hexa": tris_liant,
		"aire_totale": aire_totale,
		"aire_mediane": mediane,
		"aire_fine_pct": fine_pct,
		"arete_min": arete,
		"emprise": hi - lo,
	}


func _racine(parent: Array[int], a: int) -> int:
	var x: int = a
	while parent[x] != x:
		parent[x] = parent[parent[x]]
		x = parent[x]
	return x


func _unir(parent: Array[int], a: int, b: int) -> void:
	var ra: int = _racine(parent, a)
	var rb: int = _racine(parent, b)
	if ra != rb:
		parent[rb] = ra


func _mesh_nomme(root: Node3D, nom: String) -> MeshInstance3D:
	for child: Node in root.find_children("*", "MeshInstance3D", true, false):
		if String(child.name) == nom:
			return child as MeshInstance3D
	return null


func _capped(faults: Array[String], keep: int = 6) -> String:
	if faults.size() <= keep:
		return " ; ".join(faults)
	return " ; ".join(faults.slice(0, keep)) \
		+ " ; (+%d autres)" % (faults.size() - keep)
