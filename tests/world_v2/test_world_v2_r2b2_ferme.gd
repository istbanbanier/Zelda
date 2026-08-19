## V2.3-A.R2B.2 — FILET de l'agent A : la ferme abandonnée doit être faite de
## la MATIÈRE de la maçonnerie qui l'entoure, et son mur nord doit MANQUER.
##
## ORIGINE. Verdict PARTIAL du lead (R2B.2) sur trois vues — `ferme_seuil`,
## `ferme_facade`, `ferme_arriere` : « planches et panneaux pâles lisant comme
## des plaques opaques sans matière », « des ajouts qui BOUCHENT la lecture »,
## « pignon arrière lisant comme une plaque beige POSÉE sur le bâtiment »,
## « mur nord toujours parfaitement rectangulaire ».
##
## LES QUATRE DÉFAUTS SONT MESURÉS, jamais supposés (sondes du 2026-08-19,
## `evidence/world_v2/v2_3_r2b2/ferme/rouge_avant/`) :
##
##   1. UV0 — sonde Godot : 23 surfaces sur 23 des 12 pièces `SM_Farm_*` sans
##      `ARRAY_FORMAT_TEX_UV` et sans `albedo_texture`, quand le module de kit
##      voisin `Wall_UnevenBrick_Straight` a UV0 sur ses 3 surfaces et porte
##      `T_UnevenBrick_BaseColor.png`. C'est cette discontinuité de MATIÈRE,
##      mur contre mur, qui produit le « carton ».
##      LE COMPTE EST DOUZE, PAS ONZE : la directive disait onze pièces, la
##      sonde en trouve douze. Que personne ne cherche la douzième plus tard.
##
##   2. PROFONDEUR DE POSE — les tableaux ne manquent pas d'épaisseur (0,52 m,
##      soit PLUS que le mur qu'ils bordent) : leur signe est INVERSÉ. Blender
##      les extrude de y = -0,42 à +0,10 pour entrer de 42 cm DANS le mur ;
##      l'export Y-up donne `Godot z = -y`, et le GLB rend Z ∈ [-0,10 ; +0,42].
##      Posés sur un parement dont le plan de brique est à z = 3,000 (le module
##      de kit est DEUX PLANS STRICTS, brique Z=0,000 et plâtre Z=-0,200, sans
##      aucune face de chant), ils SAILLENT de 42 cm devant la façade. Ce sont
##      eux, `SM_Farm_Jamb_Door` et `SM_Farm_Jamb_Breach`, qui « bouchent la
##      lecture » : 7,32 + 5,32 + 2,92 + 1,31 % du cadre de `ferme_seuil`.
##
##   3. PIGNON POSÉ — 0,68 m d'épaisseur sur un mur dont la géométrie réelle
##      n'a que 0,20 m, donc 34 cm de surplomb devant le parement, et une base
##      qui n'entre que de 0,06 m dans l'arase (posé 3,06, arase 3,12).
##
##   4. MUR NORD — trois `Wall_UnevenBrick_Straight` pleine hauteur : la ligne
##      d'arase du seul mur nord est PLATE à 3,12 m, écart-type 0,000 m. Le
##      filet R2B.1 ne l'attrape pas : il mesure la dispersion sur TOUTE la
##      maçonnerie, que le pignon et le moignon suffisent à faire passer.
##
## Écrit ROUGE d'abord : les quatre contrôles échouent sur `c44f430b`, chacun
## en nommant le nombre qu'il constate.
extends GateTestCase

const FARM_SCENE: String = "res://scenes/world_v2/poi/AbandonedFarmPlace.tscn"
const FARM_GLB: String = "res://assets/architecture/farm/SM_Farm_Ruins.glb"

## Arase mesurée du module de mur (`probe_kit_seating`, 2026-08-19).
const ARASE_M: float = 3.12
## Demi-portée du bâtiment : le plan de brique du mur nord est à z = -3,00.
const DEMI_M: float = 3.00

## -- Contrôle A : matière ----------------------------------------------------
## Plancher : sous ce compte de surfaces, le contrôle ne regarderait rien.
const SURFACES_MIN: int = 20

## -- Contrôle B : profondeur de pose ------------------------------------------
## Un tableau de baie AFFLEURE son parement et s'enfonce dans la tranche.
## `+0,02` : deux centimètres de tolérance pour un arrondi, pas un pilastre.
const TABLEAU_SAILLIE_MAX_M: float = 0.02
const TABLEAU_ENFONCEMENT_MIN_M: float = 0.30
## Le pignon prolonge un mur de 0,40 m ; au-delà il déborde et se lit posé.
const PIGNON_EPAISSEUR_MAX_M: float = 0.42
const PIGNON_SAILLIE_MAX_M: float = 0.12

## -- Contrôle D1 : le pignon est SOLIDAIRE ------------------------------------
## Il ne coiffe pas une arête : il EST les assises hautes du mur. 0,45 m, c'est
## deux assises de 0,22 m — en deçà, la jonction redevient une ligne.
const PIGNON_RECOUVREMENT_MIN_M: float = 0.45
## Débord hors du plan de parement du mur nord.
const PIGNON_DEBORD_MAX_M: float = 0.06

## -- Contrôle D2 : le mur NORD manque -----------------------------------------
## La ligne d'arase du SEUL mur nord, échantillonnée en colonnes.
const NORD_BANDE_Z_MAX: float = -2.40
const NORD_COLONNE_M: float = 0.25
const NORD_COLONNES_MIN: int = 12
const NORD_ECART_TYPE_MIN_M: float = 0.35
const NORD_POINT_BAS_MAX_M: float = 2.10


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _mount_alone(path: String) -> Node3D:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	var place: Node3D = packed.instantiate() as Node3D
	if place == null:
		return null
	_tree().root.add_child(place)
	return place


func _dismount(place: Node3D) -> void:
	if place != null:
		place.get_parent().remove_child(place)
		place.queue_free()


func _capped(faults: Array[String], keep: int = 6) -> String:
	if faults.size() <= keep:
		return " ; ".join(faults)
	return " ; ".join(faults.slice(0, keep)) \
		+ " ; (+%d autres)" % (faults.size() - keep)


## La maison : le repère dans lequel « nord » et « arase » ont un sens.
func _house(place: Node3D) -> Node3D:
	for child: Node in place.find_children("*", "Node3D", true, false):
		if String(child.name) == "Fermette":
			return child as Node3D
	return null


## AABB d'un sous-arbre EXPRIMÉE dans le repère de `frame`.
## PIÈGE R2B.1 recopié ici : composer les transforms AVANT de toucher la boîte,
## sinon la rotation de 25° du bâtiment regonfle l'AABB deux fois.
func _bounds_in(node: Node3D, frame: Node3D) -> AABB:
	var inverse: Transform3D = frame.global_transform.affine_inverse()
	var merged: AABB = AABB()
	var first: bool = true
	var targets: Array[Node] = node.find_children("*", "MeshInstance3D",
		true, false)
	if node is MeshInstance3D:
		targets.append(node)
	for child: Node in targets:
		var instance: MeshInstance3D = child as MeshInstance3D
		if instance.mesh == null:
			continue
		var box: AABB = (inverse * instance.global_transform) \
			* instance.get_aabb()
		if first:
			merged = box
			first = false
		else:
			merged = merged.merge(box)
	return merged


func _named_child(root: Node3D, prefix: String) -> Node3D:
	for child: Node in root.find_children("*", "Node3D", true, false):
		if String(child.name).begins_with(prefix):
			return child as Node3D
	return null


## -- A. Chaque pièce de la ruine porte UV0 ET une texture --------------------
##
## Rouge avant le geste : 23 surfaces sur 23 sans l'un ni l'autre.

func test_chaque_piece_porte_uv0_et_une_texture() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	var surfaces: int = 0
	var sans_uv: int = 0
	var sans_texture: int = 0
	if place == null:
		faults.append("ferme : la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		for child: Node in place.find_children("*", "MeshInstance3D", true,
				false):
			var instance: MeshInstance3D = child as MeshInstance3D
			if instance.mesh == null:
				continue
			if not String(instance.name).begins_with("SM_Farm_"):
				continue
			for s: int in range(instance.mesh.get_surface_count()):
				surfaces += 1
				var format: int = instance.mesh.surface_get_format(s)
				if (format & Mesh.ARRAY_FORMAT_TEX_UV) == 0:
					sans_uv += 1
					faults.append("%s s%d : pas d'UV0" % [instance.name, s])
					continue
				var mat: StandardMaterial3D = instance.get_active_material(s) \
					as StandardMaterial3D
				if mat == null or mat.albedo_texture == null:
					sans_texture += 1
					faults.append("%s s%d : aucune albedo_texture — couleur "
						% [instance.name, s] + "plate, la matière du kit "
						+ "voisin n'est pas reprise")
		if surfaces < SURFACES_MIN:
			faults.append("seulement %d surface(s) SM_Farm_* inspectée(s) "
				% surfaces + "(plancher %d) — le contrôle ne regarde rien"
				% SURFACES_MIN)
		_dismount(place)
	check(faults.is_empty(),
		"les %d surfaces des pièces SM_Farm_* portent UV0 et une texture "
		% surfaces + "(%d sans UV0, %d sans texture) — %s"
		% [sans_uv, sans_texture, _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (matière) — %s" % restore_root_reason())


## -- B. Les pièces frontales ENTRENT dans le mur -----------------------------
##
## Rouge avant le geste : tableaux Z ∈ [-0,10 ; +0,42] (42 cm de saillie),
## pignon 0,68 m d'épaisseur pour 0,34 m de surplomb.

func test_les_pieces_frontales_entrent_dans_le_mur() -> void:
	var faults: Array[String] = []
	var packed: PackedScene = load(FARM_GLB) as PackedScene
	if packed == null:
		faults.append("le GLB de ruine ne se charge pas")
	else:
		var racine: Node3D = packed.instantiate() as Node3D
		var vus: int = 0
		for child: Node in racine.find_children("*", "MeshInstance3D", true,
				false):
			var instance: MeshInstance3D = child as MeshInstance3D
			if instance.mesh == null:
				continue
			var nom: String = String(instance.name)
			var box: AABB = instance.mesh.get_aabb()
			if nom.begins_with("SM_Farm_Jamb_"):
				vus += 1
				if box.end.z > TABLEAU_SAILLIE_MAX_M:
					faults.append("%s SAILLE de %.2f m devant le parement "
						% [nom, box.end.z] + "(max %.2f) — pilastre plaqué, "
						% TABLEAU_SAILLIE_MAX_M + "pas un tableau de baie")
				if box.position.z > -TABLEAU_ENFONCEMENT_MIN_M:
					faults.append("%s n'entre que de %.2f m dans la tranche "
						% [nom, -box.position.z] + "(min %.2f)"
						% TABLEAU_ENFONCEMENT_MIN_M)
			elif nom.begins_with("SM_Farm_GableBreak"):
				vus += 1
				if box.size.z > PIGNON_EPAISSEUR_MAX_M:
					faults.append("pignon épais de %.2f m (max %.2f) sur un "
						% [box.size.z, PIGNON_EPAISSEUR_MAX_M]
						+ "mur de 0,40 — il déborde des deux côtés")
				# LE DEHORS N'EST PAS DU MÊME CÔTÉ POUR LES DEUX PIÈCES, et
				# l'oublier fait mesurer la bonne valeur au mauvais endroit.
				# Les tableaux vivent sur le mur SUD, dont l'extérieur est
				# +Z : leur saillie est `end.z`. Le pignon coiffe le mur NORD,
				# dont l'extérieur est -Z : sa saillie est `-position.z`.
				# Vérifié sur les deux états : géométrie R2B.1 (z ∈ [-0,34 ;
				# +0,34]) → 0,34 m, ROUGE ; géométrie R2B.2 → 0,03 m.
				var saillie: float = -box.position.z
				if saillie > PIGNON_SAILLIE_MAX_M:
					faults.append("pignon en surplomb de %.2f m devant le "
						% saillie + "parement nord (max %.2f)"
						% PIGNON_SAILLIE_MAX_M)
		racine.free()
		if vus < 3:
			faults.append("%d pièce(s) frontale(s) trouvée(s) au lieu de 3 "
				% vus + "(deux tableaux, un pignon) — le contrôle ne regarde "
				+ "rien")
	check(faults.is_empty(),
		"tableaux et pignon entrent dans le mur au lieu d'être plaqués "
		+ "(%d écart(s)) — %s" % [faults.size(), _capped(faults)])


## -- D1. Le pignon est SOLIDAIRE du mur --------------------------------------
##
## Rouge avant le geste : recouvrement 0,06 m, débord 0,34 m.

func test_le_pignon_est_solidaire_du_mur_nord() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	if place == null:
		faults.append("ferme : la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var house: Node3D = _house(place)
		var pignon: Node3D = _named_child(place, "SM_Farm_GableBreak")
		if house == null:
			faults.append("aucun nœud « Fermette » — repère introuvable")
		elif pignon == null:
			faults.append("aucun pignon SM_Farm_GableBreak")
		else:
			var box: AABB = _bounds_in(pignon, house)
			var recouvrement: float = ARASE_M - box.position.y
			if recouvrement < PIGNON_RECOUVREMENT_MIN_M:
				faults.append("le pignon ne recouvre l'arase que de %.2f m "
					% recouvrement + "(min %.2f) — il COIFFE une arête au "
					% PIGNON_RECOUVREMENT_MIN_M
					+ "lieu d'être les assises hautes du mur")
			var debord: float = -DEMI_M - box.position.z
			if debord > PIGNON_DEBORD_MAX_M:
				faults.append("le pignon déborde de %.2f m hors du parement "
					% debord + "nord (max %.2f) — bandeau en surplomb, donc "
					% PIGNON_DEBORD_MAX_M + "plaque posée")
		_dismount(place)
	check(faults.is_empty(),
		"le pignon partage le plan et les assises hautes du mur nord "
		+ "(%d écart(s)) — %s" % [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (pignon) — %s" % restore_root_reason())


## -- D2. Le sommet du mur NORD manque ----------------------------------------
##
## Le filet R2B.1 mesure la dispersion sur TOUTE la maçonnerie : le pignon et
## le moignon est suffisent à la faire passer pendant que le mur nord reste un
## rectangle intact. Ici la ligne d'arase du SEUL mur nord est échantillonnée
## en colonnes de 0,25 m — c'est le profil, pas l'AABB d'une pièce, car une
## pièce qui part du faîte et descend garde une AABB haute.
##
## Rouge avant le geste : écart-type 0,000 m, point bas 3,12 m.

func test_le_sommet_du_mur_nord_manque() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	var colonnes: Dictionary = {}
	if place == null:
		faults.append("ferme : la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var house: Node3D = _house(place)
		if house == null:
			faults.append("aucun nœud « Fermette » — repère introuvable")
		else:
			var inverse: Transform3D = house.global_transform.affine_inverse()
			for child: Node in house.find_children("*", "MeshInstance3D",
					true, false):
				var instance: MeshInstance3D = child as MeshInstance3D
				if instance.mesh == null:
					continue
				var nom: String = String(instance.get_parent().name)
				var propre: String = String(instance.name)
				# LE PIGNON EST EXCLU, ET C'EST LE CŒUR DU CONTRÔLE. Mesuré
				# le 2026-08-19 : en l'incluant, ses sommets à 4,31 m suffisent
				# à eux seuls à faire passer l'écart-type, et un mur nord
				# rectangulaire intact passe sous une plaque posée dessus —
				# très exactement le défaut que ce contrôle doit attraper.
				# Ici on mesure le COURONNEMENT DU MUR, pas sa superstructure.
				var maconnerie: bool = nom.begins_with("Wall_UnevenBrick") \
					or propre.begins_with("Wall_UnevenBrick") \
					or propre.begins_with("SM_Farm_WallBreak") \
					or nom.begins_with("Corner_Exterior") \
					or propre.begins_with("Corner_Exterior")
				if not maconnerie:
					continue
				var vers_maison: Transform3D = inverse \
					* instance.global_transform
				var arrays: Array = instance.mesh.surface_get_arrays(0)
				var sommets: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				for v: Vector3 in sommets:
					var p: Vector3 = vers_maison * v
					if p.z > NORD_BANDE_Z_MAX:
						continue
					var cle: int = int(floor(p.x / NORD_COLONNE_M))
					if not colonnes.has(cle) or float(colonnes[cle]) < p.y:
						colonnes[cle] = p.y
			var hauteurs: Array[float] = []
			for cle: int in colonnes.keys():
				hauteurs.append(float(colonnes[cle]))
			if hauteurs.size() < NORD_COLONNES_MIN:
				faults.append("%d colonne(s) d'arase nord échantillonnée(s) "
					% hauteurs.size() + "(plancher %d) — le contrôle ne "
					% NORD_COLONNES_MIN + "regarde rien")
			else:
				var somme: float = 0.0
				var bas: float = 1e9
				for h: float in hauteurs:
					somme += h
					bas = minf(bas, h)
				var moyenne: float = somme / float(hauteurs.size())
				var variance: float = 0.0
				for h: float in hauteurs:
					variance += (h - moyenne) * (h - moyenne)
				var ecart: float = sqrt(variance / float(hauteurs.size()))
				if ecart < NORD_ECART_TYPE_MIN_M:
					faults.append("arase nord d'écart-type %.3f m sur %d "
						% [ecart, hauteurs.size()] + "colonnes (min %.2f) — "
						% NORD_ECART_TYPE_MIN_M + "le mur est un rectangle")
				if bas > NORD_POINT_BAS_MAX_M:
					faults.append("point bas de l'arase nord à %.2f m "
						% bas + "(max %.2f) — rien ne MANQUE au mur"
						% NORD_POINT_BAS_MAX_M)
		_dismount(place)
	check(faults.is_empty(),
		"le sommet du mur nord montre un manque structurel (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (mur nord) — %s" % restore_root_reason())
