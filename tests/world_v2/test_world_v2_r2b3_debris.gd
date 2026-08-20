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

## -- Le SECOND LIANT : la RECTANGULARITÉ, invariante à la soudure -------------
## ORIGINE — ISS-062. Le liant ci-dessus juge PAR COMPOSANTE CONNEXE. Ce
## prédicat est donc cassable en changeant CE QUI COMPTE COMME UNE COMPOSANTE,
## sans toucher un pixel : dix-huit pavés droits parfaits soudés par un coin ne
## forment qu'UNE composante, ne sont donc ni `hexa` ni `pave6`, rendent 0,00 %
## de liant, et franchissent les neuf planchers ci-dessus. L'image, elle, montre
## évidemment des boîtes.
##
## `tools/mesure_rectangularite.py` ne raisonne JAMAIS par composante. Il juge
## des PLAQUES PLANES — ensembles maximaux de triangles coplanaires connexes
## PAR ARÊTE. Deux faces qui ne se touchent que par un COIN restent deux
## plaques : la mesure ne bouge pas d'un centième quand on soude. Deux faces
## coplanaires qui partagent une ARÊTE entière fusionnent : la mesure ne bouge
## pas non plus quand on subdivise.
##
##   part_rectangulaire  part de l'AIRE portée par des plaques dont le bord est
##                       un quadrilatère à quatre angles droits (±5°)
##   part_orthogonale    part de la LONGUEUR de jonction entre plaques voisines
##                       dont l'angle dièdre vaut 90° (ou 270°) à ±5°
##   indice_boite        min(part_rectangulaire, part_orthogonale)
##
## Le `min` et non la moyenne : un cylindre à 24 côtés rend rect = 66,86 % et
## ortho = 20,70 %. Sa moyenne ressemble à celle d'un caillou ; son min dit la
## vérité. Le verdict d'une mesure composite est le plus faible de ses critères
## — c'est déjà la règle du dépôt pour les gates.
##
## PLAFOND = 51, ET IL A ÉTÉ ÉCRIT AVANT D'AVOIR MESURÉ LE SUJET.
## `evidence/world_v2/v2_3_r2b3/iss062/regle_seuil.md`, horodaté 11:08:02, pose
## `plafond = plancher((M + 100) / 2)` avec `M` = le pire indice de la famille
## NATURE/DÉBRIS, marge minimale `M + 10`, et BLOQUÉ si `M > 60`. Les mesures du
## sujet datent de 11:10:20. `M = 2,66` (`SM_ThunderstruckTree`) -> 51. Les
## témoins : RubbleLarge 0,00, RubbleSmall 0,00, arbre 2,66 ; et même
## l'architecture acceptée — pont 6,46, mur 4,53, pylône 15,68 — reste sous 16,
## parce que sa pierre est chanfreinée et non cubique. Un assemblage de boîtes
## rend 100,00. Le plafond est à 35 points au-dessus du pire témoin et à
## 49 points sous la référence boîte. NE PAS LE DÉPLACER : un seuil déplacé pour
## faire passer une correction est un portail qui s'affaiblit sans que personne
## ne mente.
##
## L'ARCHITECTURE EST LÉGITIMEMENT RECTANGULAIRE, et c'est pour cela que le
## plafond ne s'applique qu'à des meshes NOMMÉS ici — deux tas de gravats. Un
## instrument qui interdirait à un mur d'être droit interdirait l'architecture.
const RECT_PLAFOND_PCT: float = 51.0
## SECOND PLAFOND, INDÉPENDANT, POSÉ SUR L'ORTHOGONALITÉ SEULE.
##
## Trouvé par l'audit adverse le 2026-08-20 : `indice_boite = min(RECT, ortho)`
## se contourne avec un bruit COHÉRENT de 2 mm appliqué par POSITION — les coins
## soudés le restent, donc la boîtitude reste aveugle, mais les faces cessent
## d'être planes à mieux que `RECT_COPLAN_DIST`, `RECT` s'effondre à 38,80 % et
## le `min` le retient. Les DIX contrôles rendaient vert sur une géométrie qui
## n'est QUE des boîtes ; la marge de l'instrument contre le bruit valait UN
## millimètre.
##
## Or `ortho` reste à **100,00 %** sur ce contre-exemple, et dit la vérité : les
## dièdres sont droits, l'objet est fait de boîtes. Un `min` protège contre le
## cas où une seule grandeur suffirait à ABSOUDRE ; il ne protège pas contre le
## cas où une seule grandeur suffit à ACCUSER.
##
## Seuil dérivé par la MÊME règle pré-enregistrée que `RECT_PLAFOND_PCT`
## (`evidence/.../iss062/regle_seuil.md`), appliquée à `part_orthogonale` sur la
## famille NATURE/DÉBRIS : M = 4,80 (arbre foudroyé ; les deux tas de gravats du
## kit sont à 0,00) → plafond = floor((4,80 + 100) / 2) = 52, marge M+10 tenue.
## Témoins : sujet livré 14,97 · pylône 15,68 · pont 6,46 · mur 4,53 — tous PASS.
## Contre-exemples : bruit 2 mm 100,00 · 20 mm 92,72 · 50 mm 63,50 — tous FAIL.
const RECT_ORTHO_PLAFOND_PCT: float = 52.0
## Tolérances reprises À L'IDENTIQUE de `tools/mesure_rectangularite.py`.
const RECT_COPLAN_DOT: float = 0.999
const RECT_COPLAN_DIST: float = 1.0e-3
const RECT_ANGLE_TOL_DEG: float = 5.0
const RECT_COLIN_TOL_DEG: float = 5.0


## ---------------------------------------------------------------------------
## LE CONTRÔLE PRINCIPAL — un tas de débris n'est pas un empilement de pavés
## ---------------------------------------------------------------------------

func test_les_gravats_ne_sont_pas_des_paves() -> void:
	var faults: Array[String] = []
	var packed: PackedScene = load(FARM_GLB) as PackedScene
	var inspectes: int = 0
	# Accumulateurs du SECOND LIANT (ISS-062). Agrégés sur les DEUX tas, à
	# l'identique de `mesure_rectangularite.py --mesh A --mesh B` : l'aire pour
	# la part rectangulaire, la longueur de jonction pour l'orthogonalité.
	var r_aire: float = 0.0
	var r_aire_rect: float = 0.0
	var r_long: float = 0.0
	var r_long_ortho: float = 0.0
	var r_plaques: int = 0
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
			# LE SECOND LIANT — mesure par tas, verdict agrégé après la boucle.
			var r: Dictionary = _rectangularite(mi.mesh)
			r_aire += float(r["aire_totale"])
			r_aire_rect += float(r["aire_rect"])
			r_long += float(r["long_totale"])
			r_long_ortho += float(r["long_ortho"])
			r_plaques += int(r["plaques"])
			var pr_m: float = 0.0
			if float(r["aire_totale"]) > 0.0:
				pr_m = 100.0 * float(r["aire_rect"]) / float(r["aire_totale"])
			var po_m: float = -1.0
			if float(r["long_totale"]) > 0.0:
				po_m = 100.0 * float(r["long_ortho"]) / float(r["long_totale"])
			print("[r2b3_debris] %-20s plaques=%d RECT=%.2f%% ortho=%.2f%% "
				% [nom, int(r["plaques"]), pr_m, po_m]
				+ "rectiligne=%.2f%% jonction=%.4f m degeneree=%.4f m"
				% [(100.0 * float(r["aire_rectiligne"]) / float(r["aire_totale"])
					if float(r["aire_totale"]) > 0.0 else 0.0),
				   float(r["long_totale"]), float(r["long_degen"])])
		# LE SECOND LIANT — verdict, sur l'agrégat des deux tas.
		if inspectes == 2:
			var g_rect: float = 100.0 * r_aire_rect / r_aire if r_aire > 0.0 else 0.0
			var g_ortho: float = 100.0 * r_long_ortho / r_long if r_long > 0.0 \
				else g_rect
			var indice: float = minf(g_rect, g_ortho)
			print("[r2b3_debris] AGRÉGAT A+B : plaques=%d RECT=%.2f%% "
				% [r_plaques, g_rect]
				+ "ortho=%.2f%% indice_boite=%.2f%% (plafond %.2f%%)"
				% [g_ortho, indice, RECT_PLAFOND_PCT])
			if g_ortho > RECT_ORTHO_PLAFOND_PCT:
				faults.append(("%s + %s : part_orthogonale = %.2f %%, plafond "
					+ "%.2f %% — des angles droits PARTOUT, quelle que soit la "
					+ "planéité des faces. Un bruit cohérent de 2 mm effondre "
					+ "la part rectangulaire sans rien changer aux dièdres ni à "
					+ "l'image : ce contrôle-ci ne s'y laisse pas prendre "
					+ "(ISS-062)")
					% [DEBRIS_A, DEBRIS_B, g_ortho, RECT_ORTHO_PLAFOND_PCT])
			if indice > RECT_PLAFOND_PCT:
				faults.append(("%s + %s : indice_boite (rectangularité) = "
					+ "%.2f %%, plafond %.2f %% — RECT=%.2f %% ortho=%.2f %% sur "
					+ "%d plaques ; des BOÎTES DROITES restent des boîtes même "
					+ "SOUDÉES PAR LES COINS, et la soudure ne déplace pas cette "
					+ "mesure (ISS-062) — le tas se lit comme une bordure "
					+ "construite")
					% [DEBRIS_A, DEBRIS_B, indice, RECT_PLAFOND_PCT, g_rect,
					   g_ortho, r_plaques])
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


## ---------------------------------------------------------------------------
## Rectangularité — seconde implémentation de `tools/mesure_rectangularite.py`
## ---------------------------------------------------------------------------
##
## MÊME RAISON QUE POUR LE LIANT PLUS HAUT : un test Godot ne lance pas de
## processus, et un second calcul indépendant vaut mieux qu'un appel. Si le
## Python (sur les octets du GLB, en flottants 64 bits) et le GDScript (sur le
## maillage IMPORTÉ, en `Vector3` 32 bits quantifiés sur l'AABB) rendent le même
## chiffre, c'est le prédicat qui est vérifié, pas une ligne de code.
##
## LE PIÈGE QUI ANNULERAIT TOUT LE TICKET : grouper les faces par (normale,
## distance à l'origine) GLOBALEMENT. Les faces supérieures de deux cubes
## voisins qui ne se touchent que par un coin fusionneraient alors en une seule
## plaque, et la mesure redeviendrait sensible à la soudure — exactement le
## défaut qu'on corrige. D'où la connexité PAR ARÊTE, locale, ci-dessous.
##
## JONCTION DÉGÉNÉRÉE, ÉCARTÉE DES DEUX CÔTÉS DE LA FRACTION : deux plaques qui
## partagent une arête et dont les normales sont (anti)parallèles sont dans le
## MÊME plan. C'est le cas de deux boîtes simplement accolées, dos à dos. Leur
## « angle » de 180° ne dit rien de la forme ; la longueur est retirée du
## numérateur ET du dénominateur, et publiée à part pour que nul ne la cache.

func _rectangularite(mesh: Mesh) -> Dictionary:
	# ÉTAPE 1 — soudage par POSITION, toutes primitives fondues. Une plaque
	# coupée en deux par une frontière de matériau ne serait plus un
	# quadrilatère : les surfaces doivent être fondues AVANT l'analyse.
	var grille: Dictionary = {}
	var coord: Array[Vector3] = []
	var bruts: Array[Vector3i] = []
	for s: int in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(s)
		var sommets: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var geo_de: Array[int] = []
		for v: Vector3 in sommets:
			var cle: Vector3i = Vector3i(
				roundi(v.x / SOUDAGE_M), roundi(v.y / SOUDAGE_M),
				roundi(v.z / SOUDAGE_M))
			if not grille.has(cle):
				grille[cle] = coord.size()
				coord.append(v)
			geo_de.append(int(grille[cle]))
		var t: int = 0
		while t + 2 < indices.size():
			bruts.append(Vector3i(geo_de[indices[t]], geo_de[indices[t + 1]],
				geo_de[indices[t + 2]]))
			t += 3

	# ÉTAPE 2 — triangles vivants. Un triangle d'aire nulle n'a pas de normale.
	var tris: Array[Vector3i] = []
	var normales: Array[Vector3] = []
	var aires: Array[float] = []
	for tri: Vector3i in bruts:
		if tri.x == tri.y or tri.y == tri.z or tri.x == tri.z:
			continue
		var brut: Vector3 = (coord[tri.y] - coord[tri.x]).cross(
			coord[tri.z] - coord[tri.x])
		var aire_t: float = 0.5 * brut.length()
		if aire_t <= AIRE_NULLE:
			continue
		tris.append(tri)
		normales.append(brut.normalized())
		aires.append(aire_t)
	if tris.is_empty():
		return {"aire_totale": 0.0, "aire_rect": 0.0, "aire_rectiligne": 0.0,
			"long_totale": 0.0, "long_ortho": 0.0, "long_degen": 0.0,
			"plaques": 0, "triangles": 0}

	# ÉTAPE 3 — arêtes -> triangles incidents.
	var aretes: Dictionary = {}
	for i: int in range(tris.size()):
		var tri: Vector3i = tris[i]
		for paire: Vector2i in [Vector2i(tri.x, tri.y), Vector2i(tri.y, tri.z),
				Vector2i(tri.z, tri.x)]:
			var cle: Vector2i = paire
			if paire.x > paire.y:
				cle = Vector2i(paire.y, paire.x)
			if not aretes.has(cle):
				aretes[cle] = []
			(aretes[cle] as Array).append(i)

	# ÉTAPE 4 — plaques = composantes de l'adjacence COPLANAIRE PAR ARÊTE.
	var parent: Array[int] = []
	parent.resize(tris.size())
	for i: int in range(tris.size()):
		parent[i] = i
	for cle: Vector2i in aretes.keys():
		var inc: Array = aretes[cle]
		if inc.size() < 2:
			continue
		for ii: int in range(inc.size()):
			for jj: int in range(ii + 1, inc.size()):
				var t1: int = int(inc[ii])
				var t2: int = int(inc[jj])
				if normales[t1].dot(normales[t2]) < RECT_COPLAN_DOT:
					continue
				var n1: Vector3 = normales[t1]
				var p1: Vector3 = coord[tris[t1].x]
				var coplan: bool = true
				for sid: int in [tris[t2].x, tris[t2].y, tris[t2].z]:
					if absf(n1.dot(coord[sid] - p1)) > RECT_COPLAN_DIST:
						coplan = false
						break
				if coplan:
					_unir(parent, t1, t2)

	var groupes: Dictionary = {}
	var plaque_de: Array[int] = []
	plaque_de.resize(tris.size())
	for i: int in range(tris.size()):
		var r: int = _racine(parent, i)
		plaque_de[i] = r
		if not groupes.has(r):
			groupes[r] = []
		(groupes[r] as Array).append(i)

	# ÉTAPE 5 — forme du bord de chaque plaque.
	var aire_totale: float = 0.0
	var aire_rect: float = 0.0
	var aire_rectiligne: float = 0.0
	var normale_plaque: Dictionary = {}
	for pid: int in groupes.keys():
		var membres: Array = groupes[pid]
		var aire_p: float = 0.0
		var nx: float = 0.0
		var ny: float = 0.0
		var nz: float = 0.0
		var compte: Dictionary = {}
		for t_v: Variant in membres:
			var t: int = int(t_v)
			aire_p += aires[t]
			nx += normales[t].x * aires[t]
			ny += normales[t].y * aires[t]
			nz += normales[t].z * aires[t]
			var tri: Vector3i = tris[t]
			for paire: Vector2i in [Vector2i(tri.x, tri.y),
					Vector2i(tri.y, tri.z), Vector2i(tri.z, tri.x)]:
				var cle: Vector2i = paire
				if paire.x > paire.y:
					cle = Vector2i(paire.y, paire.x)
				compte[cle] = int(compte.get(cle, 0)) + 1
		aire_totale += aire_p
		var npl: Vector3 = Vector3(nx, ny, nz)
		if npl.length() > 0.0:
			npl = npl.normalized()
		else:
			npl = normales[int(membres[0])]
		normale_plaque[pid] = npl

		# Bord : les arêtes qui n'apparaissent qu'UNE fois dans la plaque.
		var bord: Array[Vector2i] = []
		for cle: Vector2i in compte.keys():
			if int(compte[cle]) == 1:
				bord.append(cle)
		if bord.is_empty():
			continue
		var voisins: Dictionary = {}
		for cle: Vector2i in bord:
			if not voisins.has(cle.x):
				voisins[cle.x] = []
			if not voisins.has(cle.y):
				voisins[cle.y] = []
			(voisins[cle.x] as Array).append(cle.y)
			(voisins[cle.y] as Array).append(cle.x)
		var ambigu: bool = false
		for k: int in voisins.keys():
			if (voisins[k] as Array).size() != 2:
				ambigu = true
				break
		if ambigu:
			continue
		# Chaînage : UNE seule boucle attendue, sinon la plaque est trouée.
		var depart: int = bord[0].x
		var boucle: Array[int] = [depart]
		var prec: int = -1
		var cour: int = depart
		while true:
			var vs: Array = voisins[cour]
			var suiv: int = int(vs[0]) if int(vs[0]) != prec else int(vs[1])
			if suiv == depart:
				break
			boucle.append(suiv)
			prec = cour
			cour = suiv
			if boucle.size() > bord.size():
				break
		if boucle.size() != voisins.size():
			continue
		var pts: Array[Vector3] = []
		for sid: int in boucle:
			pts.append(coord[sid])
		pts = _simplifier_boucle(pts)
		var angles: Array[float] = _angles_interieurs(pts, npl)
		if angles.is_empty():
			continue
		var tous_droits: bool = true
		var tous_rectilignes: bool = true
		for ang: float in angles:
			var d: bool = absf(ang - 90.0) <= RECT_ANGLE_TOL_DEG
			var r270: bool = absf(ang - 270.0) <= RECT_ANGLE_TOL_DEG
			if not d:
				tous_droits = false
			if not (d or r270):
				tous_rectilignes = false
		if tous_rectilignes:
			aire_rectiligne += aire_p
			if pts.size() == 4 and tous_droits:
				aire_rect += aire_p

	# ÉTAPE 6 — orthogonalité des jonctions ENTRE plaques distinctes.
	var long_totale: float = 0.0
	var long_ortho: float = 0.0
	var long_degen: float = 0.0
	var cos_ortho: float = sin(deg_to_rad(RECT_ANGLE_TOL_DEG))
	for cle: Vector2i in aretes.keys():
		var inc: Array = aretes[cle]
		var pids: Array[int] = []
		for t_v: Variant in inc:
			var pid: int = plaque_de[int(t_v)]
			if not pids.has(pid):
				pids.append(pid)
		if pids.size() < 2:
			continue
		var lg: float = coord[cle.x].distance_to(coord[cle.y])
		for ii: int in range(pids.size()):
			for jj: int in range(ii + 1, pids.size()):
				var d: float = absf((normale_plaque[pids[ii]] as Vector3).dot(
					normale_plaque[pids[jj]] as Vector3))
				if d >= RECT_COPLAN_DOT:
					long_degen += lg
					continue
				long_totale += lg
				if d <= cos_ortho:
					long_ortho += lg

	return {
		"aire_totale": aire_totale,
		"aire_rect": aire_rect,
		"aire_rectiligne": aire_rectiligne,
		"long_totale": long_totale,
		"long_ortho": long_ortho,
		"long_degen": long_degen,
		"plaques": groupes.size(),
		"triangles": tris.size(),
	}


## Supprime les sommets ALIGNÉS d'une boucle fermée. Sans ceci, une jonction en
## T — un sommet de subdivision posé au milieu d'une arête de bord — ferait
## passer un carré de 4 à 5 coins et le disqualifierait sans qu'un pixel bouge.
func _simplifier_boucle(entree: Array[Vector3]) -> Array[Vector3]:
	var pts: Array[Vector3] = entree.duplicate()
	var sin_colin: float = sin(deg_to_rad(RECT_COLIN_TOL_DEG))
	var change: bool = true
	while change and pts.size() > 3:
		change = false
		var n: int = pts.size()
		for i: int in range(n):
			var a: Vector3 = pts[(i - 1 + n) % n]
			var b: Vector3 = pts[i]
			var c: Vector3 = pts[(i + 1) % n]
			var u: Vector3 = b - a
			var v: Vector3 = c - b
			var lu: float = u.length()
			var lv: float = v.length()
			if lu <= 0.0 or lv <= 0.0:
				pts.remove_at(i)
				change = true
				break
			if u.cross(v).length() / (lu * lv) < sin_colin and u.dot(v) > 0.0:
				pts.remove_at(i)
				change = true
				break
	return pts


## Angles intérieurs en degrés d'un polygone plan, orienté par `normale`. Rend
## un tableau VIDE quand le bord est inexploitable — l'équivalent du `None`
## côté Python, jamais un verdict de 0 %.
func _angles_interieurs(entree: Array[Vector3], normale: Vector3) -> Array[float]:
	var n: int = entree.size()
	if n < 3:
		return []
	var pts: Array[Vector3] = entree
	var aire2: Vector3 = Vector3.ZERO
	for i: int in range(n):
		aire2 += pts[i].cross(pts[(i + 1) % n])
	if aire2.dot(normale) < 0.0:
		var inv: Array[Vector3] = []
		for i: int in range(n - 1, -1, -1):
			inv.append(pts[i])
		pts = inv
	var angles: Array[float] = []
	for i: int in range(n):
		var p: Vector3 = pts[(i - 1 + n) % n]
		var b: Vector3 = pts[i]
		var s: Vector3 = pts[(i + 1) % n]
		var u: Vector3 = s - b       # sortant
		var v: Vector3 = p - b       # entrant
		var lu: float = u.length()
		var lv: float = v.length()
		if lu <= 0.0 or lv <= 0.0:
			return []
		var ang: float = rad_to_deg(acos(clampf(u.dot(v) / (lu * lv), -1.0, 1.0)))
		if u.cross(v).dot(normale) <= 0.0:      # rentrant
			ang = 360.0 - ang
		angles.append(ang)
	return angles
