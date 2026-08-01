# Audit d'asset readiness — après la Passe V4 (2026-08-01)

**Contexte** : verdict propriétaire — la Passe V4 est acceptée comme
infrastructure technique et fonctionnelle ; le gate ARTISTIQUE est refusé.
Les captures montrent un graybox décoré de primitives, loin des références V4.
Cet audit répond à une seule question : **que faut-il pour passer des
primitives à la production ?** Aucun travail artistique n'accompagne ce
document — décision propriétaire attendue à sa suite.

**État de référence** : commit `e0094a7`, 270 tests verts, branche poussée.

---

## 1. Inventaire — chaque asset actuellement utilisé

| Élément en jeu | Représentation actuelle | Construite où | Nature |
|---|---|---|---|
| Héros | CapsuleMesh + boîte d'arme colorée par type + pose d'attaque par rotation | `Player.tscn` + `player_controller.gd` | **primitive** |
| Pillard rouge | CapsuleMesh + ClubMesh boîte + télégraphe rouge (teinte matériau) | `RaiderRed.tscn` + `raider_red.gd` | **primitive** |
| Armes (6 définitions) | Données `.tres` complètes (dégâts, portée, durabilité, conductivité) ; visuel = boîte colorée | `resources/weapons/*.tres` | **données PRODUCTION / visuel primitive** |
| Flèche (arc) | primitive projetée | scripts combat | **primitive** |
| Coffre | boîtes (corps + couvercle) | `Chest.tscn` | **primitive** |
| Arme au sol | boîte | `WeaponPickup.tscn` | **primitive** |
| Terrain (crête, vallée, plateaux, rampes) | dalles BoxMesh + prismes convexes, albedo uni | `valley_terrain.gd` (code) | **graybox** |
| Montagnes frontière | murs collision + pics PrismMesh 2 rangées + contreforts | `valley_terrain.gd` | **graybox** |
| Rivière | ruban de BoxMesh turquoise translucide | `valley_terrain.gd` | **primitive** |
| Chemins | bandes BoxMesh ocre | `valley_terrain.gd` | **primitive** |
| Prairie (1400 touffes + 130 fleurs) | ArrayMesh 3 quads croisés, MultiMesh, shader vent | `valley_terrain.gd` + `foliage_wind.gdshader` | **proto réutilisable** (maillage à remplacer, shader = base) |
| Arbres (12) | cylindre + sphère, 3 tons | `valley_terrain.gd` | **primitive** |
| Camp (3 tentes, foyer, fumée) | PrismMesh + cylindres + GPUParticles | `valley_terrain.gd` + `ValleyWorld.tscn` | **primitive** |
| Pylône | cylindres empilés + sphère, émissifs standards | `valley_terrain.gd` | **primitive** |
| Citadelle + façade | boîtes (donjon, tours, gradins, piliers, conduits, braseros, marches) | `valley_terrain.gd` | **graybox** |
| Vestibule | boîtes (salle, colonnes, braseros, seuil scellé) + omni | `citadel_vestibule.gd` | **graybox** |
| Orage + éclair | sphères aplaties + segments BoxMesh émissifs + omni | `storm_cell.gd` | **proto VFX** |
| Poussière/pollen | GPUParticles + quad billboard uni | `valley_world.gd` | **proto VFX** |
| HUD / inventaire / pause / mort | Controls Godot + StyleBoxFlat (`HudStyle`), **police par défaut du moteur**, zéro texture | `gameplay_shell.gd` | **fonctionnel, sans art** |
| Audio | **NÉANT** — les quatre dossiers `assets/audio/*` sont vides | — | **absent** |
| `SM_TestCube`, `SK_TestRigAnim` | seuls vrais `.glb` du dépôt | `assets/` | **tests du pipeline — marqués « ne pas utiliser en jeu », et ils ne le sont pas** |

## 2. Primitives / assets de test vs base de production

- **Primitives ou graybox (à remplacer)** : tout le visible ci-dessus —
  personnages, armes, environnement, architecture, eau, végétation, VFX.
- **Assets de test (à ne jamais embarquer)** : `SM_TestCube`,
  `SK_TestRigAnim`, scènes `scenes/tests/*` (CombatDummy…), exclus du chemin
  critique — conforme.
- **Base de production déjà valide (à CONSERVER)** : les données `.tres`
  (armes, tuning ennemi), le graphe de scènes et les seams testés, le
  pipeline Blender→glTF→inspection→import (validé de bout en bout Phase 0),
  `foliage_wind.gdshader` (v0 de SH_FoliageWind), `HudStyle` (langage UI),
  les palettes/règles ART_BIBLE §1bis, la capture reproductible, le navmesh.

## 3. Manquants de production (MASTER_SPEC §7)

**Modèles 3D** — rien n'existe :
- Héros §7.11 : 40-70k tris, silhouette originale (cape turquoise, arc,
  sacoches), rig complet, ~30 animations §7.12 (locomotion, saut, escalade
  4 directions, mantle, combos par arme, arc, esquive, impacts, mort…).
- Cinq familles ennemies §12 (silhouettes réellement distinctes) ; boss
  Phase G (100-160k, hero asset).
- Kit environnement §7.3 : 12 rochers, 6 falaises, 4 talus, 5 arbres,
  6 buissons, 8 herbes, 5 fleurs, 8 modules de ruine, 12 modules de donjon,
  6 câbles/rails, 4 connecteurs, 3 portes, 4 pylônes, 10 props de camp.
- Armes : 6 modèles + sockets ; coffre ; ingrédients (Phase E).
- Citadelle/façade : modules architecturaux (trimsheet §7.15 recommandé).

**Matériaux/textures** — zéro texture image dans le projet :
- Ramps painterly, trimsheets architecture, atlas végétation, splat
  terrain (herbe/terre/roche/humide), patine métal, céramique.
- Budgets §7.10 : atlas 2K env., 2K héros (4K justifié), 512-1K props.

**Shaders §7.9** — 1 sur 12 :
- Existant : `SH_FoliageWind` v0. Manquants : `SH_CharacterPainterly`,
  `SH_RockTriplanar`, `SH_GroundBlend`, `SH_TreeCanopy`, `SH_WaterStylized`,
  `SH_MetalPatina`, `SH_EnergyCyan`, `SH_ElectrifiedSurface`,
  `SH_CloudLayer`, `SH_DistanceImpostor`, `SH_CameraFadeDither`.

**VFX §7.13** — protos seulement (éclair, fumée, motes) :
- Impacts par matière, étincelles, feu/braises texturés, coffre, buffs,
  projectiles, rupture d'arme, propagation électrique, boss.

**Animations** — aucune (le jeu est 100 % capsules statiques) : la liste
§7.12 entière, plus retargeting documenté si base externe.

**UI** : police(s) sous licence (l'actuelle est celle du moteur), icônes
d'armes/objets, glyphes de touches, textures de plaques/cadres, réticule.

**Audio §18.2** : la liste obligatoire complète (pas par surface, impacts,
arc, rupture, coffre, récolte, détection, éclairs/tonnerre, ambiances,
musique exploration/combat/donjon/boss) — rien n'existe.

## 4. Créer (Blender) / acquérir / remplacer

**À créer dans Blender** (pipeline `tools/blender/export_gltf.py` validé,
conventions §7.15 : `SM_/SK_/AN_`, LODs, collisions, min Y = 0) :
- le héros (priorité 1 de §7.2), rig et bibliothèque d'animations ;
- le kit environnement modulaire et les trimsheets d'architecture ;
- les 6 armes, le coffre, les props de camp, le pylône ;
- les modules citadelle/vestibule/donjon.

**À acquérir sous licence compatible** (chaque entrée passe par
`ATTRIBUTIONS.md` AVANT le build — règle absolue) :
- polices : SIL OFL (ex. familles libres à chiffres tabulaires) ;
- SFX/ambiances : CC0 de préférence (l'attribution CC-BY est acceptable et
  documentée) ; musique : originale ou CC0/CC-BY ;
- éventuellement bases low-poly stylisées CC0 pour accélérer le kit
  (à re-sculpter aux silhouettes du projet — rien de reconnaissable) ;
- animations : création propre ou bibliothèques dont la licence permet
  l'EMBARQUEMENT dans un jeu ET la présence des fichiers dans un dépôt —
  vérifier ce second point avant toute dépendance (beaucoup de services
  d'animation l'interdisent) ; aucun compte personnel requis (§2).

**À remplacer, dans l'ordre de §7.2** : héros → herbe proche/vue
d'ouverture → citadelle/pylône/orage → camp/feu → entrée/vestibule → boss →
routes secondaires → fonds. Chaque primitive listée en §1 a son successeur
défini par les références V4.

## 5. Licences et formats requis

- **Format d'échange** : glTF 2.0 `.glb` exclusivement (D-003), sources
  `.blend` versionnées dans `source_assets/`, manifeste
  `ASSET_MANIFEST.csv` tenu à chaque entrée.
- **Textures** : PNG source, power-of-two, mipmaps/compression à l'import ;
  budgets §7.10.
- **Audio** : WAV/OGG ; OGG pour musique/ambiances, WAV courts pour SFX.
- **Licences acceptées** : création projet, CC0, CC-BY (attribution
  consignée), OFL (polices). **Refusées** : tout contenu évoquant une
  licence existante (Nintendo…), packs sans licence claire, ressources
  exigeant un compte/service payant, assets non redistribuables en dépôt.
- **Git LFS** : le dépôt n'en dépend pas aujourd'hui ; sa disponibilité
  réelle sur l'origine doit être vérifiée AVANT d'y engager textures maîtres
  et `.blend` lourds (règle §7.15) — sinon, discipline de taille stricte.

## 6. Risques d'intégration et de performance

1. **Aucune validation visuelle possible dans ce conteneur** : llvmpipe
   prouve la composition, jamais la qualité perçue ni la performance. Toute
   passe d'assets exigera des allers-retours sur poste GPU (playtests).
2. **Le monde est construit EN CODE** (`valley_terrain.gd`) : brancher des
   `.glb` signifie soit instancier les scènes importées depuis ces
   générateurs (recommandé : les cotes et les tests de relief survivent),
   soit basculer vers des scènes assemblées à la main (les 270 tests de
   cotes/navigation devront suivre). Refactor moyen, à planifier.
3. **Navmesh** : chaque remplacement de géométrie de collision impose un
   rebake + re-preuve de navigation (outil et tests existants).
4. **Premier vrai rig** : retargeting, échelles, root motion — risques
   §7.18 jamais exercés ici au-delà du `SK_TestRigAnim` ; l'import headless
   valide la mécanique, pas la déformation visuelle.
5. **Végétation texturée** : l'overdraw alpha (§7.17) remplacera le coût
   trivial des quads unis — à mesurer sur GPU, budgets §20.2.
6. **Poids du dépôt sans LFS confirmé** : textures 2K et `.blend` peuvent
   enfler vite ; vérifier LFS ou imposer des plafonds par fichier.
7. **Charge de production** : héros + 5 familles + boss est le plus gros
   poste (risque RSK-01) ; le pipeline n'a été exercé que sur un cube et un
   rig de test — prévoir un PREMIER asset de bout en bout (un rocher ou une
   arme) pour éprouver la chaîne avant d'industrialiser.

---

## Pack V4 — état du dépôt des PNG (bloquant documentaire)

Ordre : « dépose réellement les cinq PNG ». **Impossible depuis ce
conteneur** : recherche exhaustive du disque (hors dépôt) — aucun
`*V4*.png`, aucun `*ATMOSPHERE*` ; les images n'ont été transmises que dans
la conversation, dont le contenu n'est pas extractible en fichiers. Les
recréer serait une falsification de provenance (§0.2) — refusé. Deux voies
réelles : (a) commit direct des cinq PNG depuis votre machine dans
`source_assets/concepts/final_v4/` ; (b) tout canal de dépôt qui écrit
réellement sur le disque du conteneur — je les versionnerai alors avec
sommes SHA-256 dans le manifeste.

**Fin de l'audit. Arrêt — décision propriétaire attendue.**
