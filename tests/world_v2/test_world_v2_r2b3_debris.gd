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
##   mesh               comp  tris    hexa   aire tot.  aire méd.  arête min
##   SM_Farm_Debris_A     11   124   96,8 %    3,9764    0,32639     0,060
##   SM_Farm_Debris_B     11   124   96,8 %    4,1805    0,46180     0,060
##
## Cause exacte : `gravats()` construit chaque éclat avec `poutre()`, et une
## poutre EST un pavé — douze triangles, huit sommets soudés. Dix poutres sur
## onze composantes, d'où 120/124.
##
## POURQUOI SIX CRITÈRES ET NON UN SEUL. Il existe trois façons de faire tomber
## un pourcentage sans traiter le sujet : **supprimer** les débris, les
## **rétrécir**, les **pulvériser** en bruit sous-pixel. Un plafond de boîtitude
## seul récompenserait les trois. Les cinq planchers qui l'accompagnent sont donc
## aussi liants que lui, et aucun ne doit être relevé : un seuil déplacé pour
## faire passer une correction est un portail qui s'affaiblit sans que personne
## ne mente (`tests/CLAUDE.md`, « ne jamais assouplir un seuil »).
##
## POURQUOI CE FILET RECALCULE `hexa` EN GDSCRIPT au lieu d'appeler
## `tools/mesure_boititude.py`. Un test Godot ne lance pas de processus, et un
## second calcul indépendant vaut mieux qu'un appel : si les deux implémentations
## — Python sur les octets du GLB, GDScript sur le maillage importé — rendent le
## même 96,8 % en rouge puis le même chiffre en vert, c'est le prédicat qui est
## vérifié, pas une seule ligne de code. Le journal rouge publie les deux.
##
## PIÈGE DE SOUDAGE, mesuré et non supposé. L'instrument Python soude à 10 µm sur
## les flottants bruts du GLB. Ici les positions passent par l'importeur Godot,
## dont `meshes/force_disable_compression=false` (voir `SM_Farm_Ruins.glb.import`)
## quantifie les positions sur l'AABB — l'erreur peut dépasser 10 µm et casserait
## le soudage, donc les comptes de sommets, donc le prédicat. La tolérance est
## portée à 0,1 mm : 300 fois plus fine que l'arête minimale exigée (0,03 m), donc
## incapable de fusionner deux coins distincts, et assez large pour absorber la
## quantification. La preuve que ce choix est juste est le rouge lui-même : il
## doit rendre EXACTEMENT les 11 composantes / 124 triangles / 96,8 % que
## l'instrument Python rend sur les mêmes meshes.
extends GateTestCase

const FARM_GLB: String = "res://assets/architecture/farm/SM_Farm_Ruins.glb"

const DEBRIS_A: String = "SM_Farm_Debris_A"
const DEBRIS_B: String = "SM_Farm_Debris_B"

## Soudage par position. Voir le piège documenté en tête de fichier.
const SOUDAGE_M: float = 1.0e-4

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
const ARETE_MIN_M: float = 0.03

## -- Plancher 5 : l'implantation ne bouge pas ---------------------------------
## Emprise POSITION du GLB de départ, repère local du mesh (X, Y = hauteur, Z),
## `evidence/world_v2/v2_3_r2b3/debris/03_empreinte_avant.log`.
const EMPRISE_BASE_A: Vector3 = Vector3(1.4279, 0.6841, 1.1525)
const EMPRISE_BASE_B: Vector3 = Vector3(1.1721, 0.6852, 1.0310)
## Le tas peut respirer en hauteur — un centre plus haut est demandé — mais son
## emprise au sol tient la place que le lieu lui a donnée.
const EMPRISE_TOL_XZ: float = 0.20
const EMPRISE_TOL_Y: float = 0.30

## -- Plancher 6 : le budget de la ferme ---------------------------------------
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
				faults.append(("%s : %.1f %% de triangles en PAVÉS (hexa = 12 "
					+ "triangles et 8 sommets), plafond %.1f %% — %d composante(s) "
					+ "sur %d en sont ; le tas se lit comme une bordure "
					+ "construite") % [nom, pct, HEXA_PLAFOND_PCT,
					int(m["comp_hexa"]), int(m["composantes"])])
			# PLANCHER 1 — les débris ne disparaissent pas.
			if int(m["composantes"]) < COMPOSANTES_MIN:
				faults.append("%s : %d composante(s), plancher %d — supprimer "
					% [nom, int(m["composantes"]), COMPOSANTES_MIN]
					+ "des fragments ferait tomber la boîtitude sans corriger "
					+ "l'image")
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
			if float(m["arete_min"]) < ARETE_MIN_M:
				faults.append("%s : arête minimale %.6f m, plancher %.3f m — "
					% [nom, float(m["arete_min"]), ARETE_MIN_M]
					+ "un détail invisible à l'écran ne corrige aucune lecture")
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
			print("[r2b3_debris] %-20s comp=%d tris=%d hexa=%.1f%% "
				% [nom, int(m["composantes"]), tris, pct]
				+ "aire_tot=%.4f aire_med=%.5f arete_min=%.6f "
				% [float(m["aire_totale"]), float(m["aire_mediane"]),
				   float(m["arete_min"])]
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
	var composantes: int = 0
	var comp_hexa: int = 0
	var triangles: int = 0
	var tris_hexa: int = 0
	var aire_totale: float = 0.0
	var arete_min: float = INF
	var aires: Array[float] = []
	var lo: Vector3 = Vector3(INF, INF, INF)
	var hi: Vector3 = Vector3(-INF, -INF, -INF)

	for s: int in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(s)
		var sommets: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for v: Vector3 in sommets:
			lo = Vector3(minf(lo.x, v.x), minf(lo.y, v.y), minf(lo.z, v.z))
			hi = Vector3(maxf(hi.x, v.x), maxf(hi.y, v.y), maxf(hi.z, v.z))

		# ÉTAPE 1 — soudage par POSITION, jamais fusionné avec l'étape 2.
		var grille: Dictionary = {}
		var geo_de: Array[int] = []
		var coord: Array[Vector3] = []
		for v: Vector3 in sommets:
			var cle: Vector3i = Vector3i(
				roundi(v.x / SOUDAGE_M), roundi(v.y / SOUDAGE_M),
				roundi(v.z / SOUDAGE_M))
			if not grille.has(cle):
				grille[cle] = coord.size()
				coord.append(v)
			geo_de.append(int(grille[cle]))

		# ÉTAPE 2 — connexité sur les identifiants GÉOMÉTRIQUES.
		var parent: Array[int] = []
		parent.resize(coord.size())
		for i: int in range(coord.size()):
			parent[i] = i
		var tris: Array[Vector3i] = []
		var t: int = 0
		while t + 2 < indices.size():
			var a: int = geo_de[indices[t]]
			var b: int = geo_de[indices[t + 1]]
			var c: int = geo_de[indices[t + 2]]
			tris.append(Vector3i(a, b, c))
			_unir(parent, a, b)
			_unir(parent, b, c)
			t += 3
		triangles += tris.size()

		var groupes: Dictionary = {}
		for tri: Vector3i in tris:
			var r: int = _racine(parent, tri.x)
			if not groupes.has(r):
				groupes[r] = []
			(groupes[r] as Array).append(tri)

		for cle_g: int in groupes.keys():
			var membres: Array = groupes[cle_g]
			var vus: Dictionary = {}
			var aire: float = 0.0
			for tri: Vector3i in membres:
				vus[tri.x] = true
				vus[tri.y] = true
				vus[tri.z] = true
				var pa: Vector3 = coord[tri.x]
				var pb: Vector3 = coord[tri.y]
				var pc: Vector3 = coord[tri.z]
				aire += 0.5 * (pb - pa).cross(pc - pa).length()
				for paire: Vector2i in [Vector2i(tri.x, tri.y),
						Vector2i(tri.y, tri.z), Vector2i(tri.z, tri.x)]:
					if paire.x == paire.y:
						continue
					var d: float = coord[paire.x].distance_to(coord[paire.y])
					if d > 0.0 and d < arete_min:
						arete_min = d
			composantes += 1
			aires.append(aire)
			aire_totale += aire
			if membres.size() == 12 and vus.size() == 8:
				comp_hexa += 1
				tris_hexa += 12

	aires.sort()
	var mediane: float = 0.0
	if not aires.is_empty():
		mediane = aires[aires.size() >> 1]
	return {
		"composantes": composantes,
		"comp_hexa": comp_hexa,
		"triangles": triangles,
		"tris_hexa": tris_hexa,
		"aire_totale": aire_totale,
		"aire_mediane": mediane,
		"arete_min": 0.0 if arete_min == INF else arete_min,
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
