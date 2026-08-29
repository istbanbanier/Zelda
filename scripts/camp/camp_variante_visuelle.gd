## VARIANTE VISUELLE DU CAMP LIBÉRÉ — proposition, pas décision.
##
## Deux reproches du playtest, et rien d'autre : le feu rallumé ne se voit
## pas, et le coffre écrase le cadre. Cette variante répond aux deux SANS
## toucher une seule ligne de géométrie gelée.
##
## ELLE N'EST PAS DESTINÉE À ÊTRE FUSIONNÉE EN L'ÉTAT. Elle vit sur sa propre
## branche, elle produit des captures, et c'est Istvan qui tranche. Le code
## est écrit propre parce qu'une proposition qu'on ne peut pas juger sur des
## images réelles ne vaut rien — pas parce que la décision serait prise.
##
## ─── CE QUI REND CETTE FORME LÉGALE ───────────────────────────────────────
##
## 1. LE FEU EST POSÉ EN ENFANTS DU `CampfireProp`, jamais en frères.
##    Deux conséquences, toutes deux nécessaires :
##      · le contrôle de peau du camp (filet des camps R2B,
##        `_under_exempt_prop`) remonte les ANCÊTRES à la recherche d'un
##        `CampfireProp` — l'exemption NOMMÉE de l'arbitrage R2B. Un frère
##        serait un maillage hors-module, donc ROUGE ;
##      · la visibilité est héritée. Le script GELÉ de libération bascule
##        `FeuVisuel.visible` ; braises, lueur et étincelles s'allument et
##        s'éteignent avec lui, SANS que rien ici ne lise un état de jeu.
##        C'est la règle de `scripts/CLAUDE.md` : un visuel ne décide de rien,
##        et ici il ne CONSTATE même pas — il suit son parent.
##
## 2. `CampfireProp` LUI-MÊME N'EST PAS TOUCHÉ. Il est partagé avec la vallée
##    V1, et son propre en-tête dit qu'il ne porte « NI la lumière, NI la
##    collision, NI l'état de jeu » — celles-ci sont créées par le lieu. La
##    vallée V1 le fait déjà (`valley_terrain.gd`, `FireCoals` +
##    `CampFireLight`) ; le camp World V2 ne le faisait pas. C'est le manque,
##    et il se comble ici, avec les VALEURS MESURÉES de V1 plutôt que des
##    valeurs inventées.
##
## 3. LE COFFRE EST HABILLÉ PAR SURFACE SUR DES MATÉRIAUX DUPLIQUÉS, sur cette
##    instance seulement. Technique et garde-fous repris mot pour mot de
##    `barrow_cemetery_place.gd` (autorisée par le lead au lot 1.R), y compris
##    le piège qui y a été payé : `material_override` PRIME sur les surcharges
##    de surface, donc écrire une surcharge sur un nœud qui en porte un ne
##    ferait RIEN, en silence.
##
## 4. AUCUN FICHIER GELÉ N'EST MODIFIÉ. Ce script vit dans `scripts/camp/`,
##    hors du glob gelé des scripts du monde V2, et se branche par un FRÈRE
##    dans `WorldV2.tscn` — le même motif que `CampLiberation` et
##    `CampCuisineGuard`.
class_name CampVarianteVisuelle
extends Node

## Chemin injecté par la scène, jamais écrit ici — même raison que pour le
## garde de cuisine : le contrôle de références croisées est TEXTUEL.
@export_file("*.json") var donnees: String = ""

## Interrupteur d'A/B, et il n'existe QUE pour la preuve. `off` rend le camp
## exactement tel qu'il est sur la branche de durcissement : même arbre, même
## sauvegarde, même caméra, une seule variable. Sans lui, comparer deux
## captures reviendrait à comparer deux mondes.
@export var actif: bool = true

## Valeurs de la vallée V1 (`valley_terrain.gd`), reprises telles quelles.
## Un camp de ce monde doit brûler comme l'autre ; inventer un second réglage
## créerait deux feux qui ne se ressemblent pas, pour aucune raison.
const BRAISE_EMISSION: Color = Color(0.98, 0.45, 0.12)
const BRAISE_ENERGIE: float = 2.4
const LUEUR_COULEUR: Color = Color(1.0, 0.62, 0.28)
const LUEUR_ENERGIE: float = 1.8
const LUEUR_PORTEE: float = 14.0
## Hauteur de la lueur au-dessus du foyer — V1 la pose 1,4 m plus haut.
const LUEUR_HAUTEUR: float = 1.4

## Habillage du coffre : on DÉSATURE et on ASSOMBRIT, on ne repeint pas. Le
## contraste bois/ferrure survit parce que c'est un RAPPORT ; seul l'écart au
## reste du cadre diminue. Valeurs plus douces que celles du tertre : ici le
## coffre doit rester la promesse visible d'une récompense, pas disparaître.
const COFFRE_VERS_GRIS: float = 0.42
const COFFRE_FACTEUR: Vector3 = Vector3(0.74, 0.75, 0.79)


func _ready() -> void:
	call_deferred("_installer")


func _installer() -> void:
	if not actif:
		return
	var camp: Dictionary = _premier_camp()
	if camp.is_empty():
		push_warning("[variante] données du camp illisibles — rien à habiller")
		return
	_allumer_le_foyer(camp)
	_suivre_la_recompense(camp)


## ------------------------------------------------------------------------
## Le feu
## ------------------------------------------------------------------------
func _allumer_le_foyer(camp: Dictionary) -> void:
	var chemin: String = String(camp.get("foyer_visuel", ""))
	if chemin == "":
		return
	var foyer: Node = get_parent().get_node_or_null(NodePath(chemin))
	if foyer == null:
		push_warning("[variante] foyer visuel introuvable : %s" % chemin)
		return
	if not (foyer is CampfireProp):
		# Refus EXPLICITE plutôt que pose silencieuse : hors d'un
		# `CampfireProp`, l'exemption de peau ne s'applique pas et le contrôle
		# du camp deviendrait rouge sans que personne comprenne pourquoi.
		push_warning("[variante] « %s » n'est pas un CampfireProp — rien posé"
			% chemin)
		return
	if foyer.has_node("LitDeBraises"):
		return

	var braises: MeshInstance3D = MeshInstance3D.new()
	braises.name = "LitDeBraises"
	var disque: CylinderMesh = CylinderMesh.new()
	disque.top_radius = 0.62
	disque.bottom_radius = 0.66
	disque.height = 0.10
	braises.mesh = disque
	braises.position = Vector3(0.0, 0.18, 0.0)
	braises.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var matiere: StandardMaterial3D = StandardMaterial3D.new()
	matiere.albedo_color = Color(0.42, 0.16, 0.07)
	matiere.roughness = 0.92
	matiere.emission_enabled = true
	matiere.emission = BRAISE_EMISSION
	matiere.emission_energy_multiplier = BRAISE_ENERGIE
	braises.material_override = matiere
	foyer.add_child(braises)

	var lueur: OmniLight3D = OmniLight3D.new()
	lueur.name = "LueurFoyer"
	lueur.light_color = LUEUR_COULEUR
	lueur.light_energy = LUEUR_ENERGIE
	lueur.omni_range = LUEUR_PORTEE
	lueur.position = Vector3(0.0, LUEUR_HAUTEUR, 0.0)
	# Une seule lumière locale, sans ombre : §20.4 demande de couper les ombres
	# des petites sources. Le soleil porte déjà celles du camp.
	lueur.shadow_enabled = false
	foyer.add_child(lueur)

	# `CPUParticles3D` et NON `GPUParticles3D` : ce conteneur rend en logiciel
	# (llvmpipe), et une preuve qu'on ne peut pas capturer n'est pas une
	# preuve. Le coût est négligeable — 18 particules, une seule source.
	var etincelles: CPUParticles3D = CPUParticles3D.new()
	etincelles.name = "EtincellesFoyer"
	etincelles.amount = 18
	etincelles.lifetime = 2.1
	etincelles.position = Vector3(0.0, 0.32, 0.0)
	etincelles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	etincelles.emission_sphere_radius = 0.34
	etincelles.direction = Vector3.UP
	etincelles.spread = 14.0
	etincelles.initial_velocity_min = 0.55
	etincelles.initial_velocity_max = 1.30
	etincelles.gravity = Vector3(0.15, 0.35, -0.10)   # l'air chaud monte
	etincelles.scale_amount_min = 0.030
	etincelles.scale_amount_max = 0.075
	etincelles.color = Color(1.0, 0.72, 0.34)
	var braise_mat: StandardMaterial3D = StandardMaterial3D.new()
	braise_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	braise_mat.vertex_color_use_as_albedo = true
	braise_mat.emission_enabled = true
	braise_mat.emission = Color(1.0, 0.66, 0.26)
	braise_mat.emission_energy_multiplier = 1.6
	braise_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	braise_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	etincelles.material_override = braise_mat
	var grain: QuadMesh = QuadMesh.new()
	grain.size = Vector2(0.06, 0.06)
	etincelles.mesh = grain
	foyer.add_child(etincelles)


## ------------------------------------------------------------------------
## Le coffre
## ------------------------------------------------------------------------
## Le coffre n'existe pas au montage : le script GELÉ de libération le pose
## à la victoire. On s'abonne donc à son arrivée, comme le tertre le fait.
func _suivre_la_recompense(camp: Dictionary) -> void:
	var liberation: Node = get_parent().get_node_or_null("CampLiberation")
	if liberation == null:
		return
	var attendu: String = String((camp.get("recompense", {}) as Dictionary)
		.get("coffre_id", ""))
	if attendu == "":
		return
	# Déjà là (reprise d'une partie où le camp est libéré) ou à venir.
	for n: Node in liberation.find_children("*", "Chest", true, false):
		_peut_etre_habiller(n, attendu)
	liberation.child_entered_tree.connect(
		func(noeud: Node) -> void: _peut_etre_habiller(noeud, attendu))


func _peut_etre_habiller(noeud: Node, attendu: String) -> void:
	if not (noeud is Chest) or String((noeud as Chest).chest_id) != attendu:
		return
	if noeud.is_node_ready():
		_habiller(noeud)
	else:
		noeud.ready.connect(_habiller.bind(noeud), CONNECT_ONE_SHOT)


func _habiller(racine: Node) -> void:
	if racine == null or not is_instance_valid(racine):
		return
	if racine.has_meta(&"variante_habillee"):
		return
	racine.set_meta(&"variante_habillee", true)
	var cibles: Array[Node] = racine.find_children("*", "MeshInstance3D",
		true, false)
	for noeud: Node in cibles:
		var instance: MeshInstance3D = noeud as MeshInstance3D
		if instance.mesh == null or not instance.visible:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var base: StandardMaterial3D = instance.get_active_material(
				surface) as StandardMaterial3D
			if base == null:
				continue
			var mat: StandardMaterial3D = base.duplicate() as StandardMaterial3D
			var c: Color = mat.albedo_color
			var gris: float = c.get_luminance()
			mat.albedo_color = Color(
				lerpf(c.r, gris, COFFRE_VERS_GRIS) * COFFRE_FACTEUR.x,
				lerpf(c.g, gris, COFFRE_VERS_GRIS) * COFFRE_FACTEUR.y,
				lerpf(c.b, gris, COFFRE_VERS_GRIS) * COFFRE_FACTEUR.z, c.a)
			mat.roughness = maxf(mat.roughness, 0.88)
			mat.metallic_specular = 0.12
			# `material_override` PRIME sur les surcharges de surface : écrire
			# au mauvais endroit ne ferait RIEN, en silence. Piège payé au
			# lot 1.R sur le tertre.
			if instance.material_override != null:
				instance.material_override = mat
			else:
				instance.set_surface_override_material(surface, mat)


func _premier_camp() -> Dictionary:
	var f: FileAccess = FileAccess.open(donnees, FileAccess.READ)
	if f == null:
		return {}
	var v: Variant = JSON.parse_string(f.get_as_text())
	if not (v is Dictionary):
		return {}
	var camps: Array = (v as Dictionary).get("camps", []) as Array
	return camps[0] as Dictionary if camps.size() > 0 else {}
