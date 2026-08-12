# ATTRIBUTIONS

Règle absolue (§2, §7.14) : **aucune ressource n'entre dans le build avant d'être
inscrite ici** avec source, auteur, licence et modifications. Une ressource sans
licence claire n'entre pas dans le build. Aucun asset ne doit exiger le compte
personnel du joueur ni un service payant.

## État à ce jour

Le projet contient des ressources externes de **quatre** provenances, toutes
sous **CC0 1.0** (domaine public — usage commercial autorisé, crédit non
obligatoire mais donné ici) : Quaternius Standard (ART-Q0/Q8, 2026-08-02),
puis, déposées par le propriétaire du projet le **2026-08-06** :
**ambientCG** (textures de surface), **Kenney** (Nature Kit) et
**KayKit / Kay Lousberg** (Dungeon Pack). Tout le reste a été généré par les
scripts du dépôt.

## Textures de surface — ambientCG, CC0 1.0 (ART-T1, 2026-08-06)

Six matériaux photoscannés, entrés dans le build pour combler le manque
dominant nommé par trois évaluations successives (« zéro texture, albedos
plats »).

| | |
|---|---|
| Auteur / source | **ambientCG** (Lennart Demes) — <https://ambientcg.com> |
| Licence | **CC0 1.0 Universal** — <https://creativecommons.org/publicdomain/zero/1.0/> |
| Packs | `Rock030`, `Rock064`, `Ground037`, `Grass001`, `Bark006`, `Fabric030` (variantes 2K-JPG) |
| Cible | `assets/textures/surfaces/` |
| Noms projet | `T_Rock_Strata`, `T_Rock_Mossy`, `T_Ground_Earth`, `T_Grass_Field`, `T_Bark_Tree`, `T_Fabric_Canvas` — suffixes `_Albedo`, `_Normal`, `_Rough` |
| Modifications | **oui** : seules 3 cartes retenues par pack (Color, NormalGL, Roughness), redimensionnées 2048 → **1024 px** (Lanczos), rugosité convertie en niveaux de gris, JPEG qualité 88. Occlusion, displacement, sources `.blend`/`.usdc`/`.mtlx` écartées |
| Poids | **7,3 Mo** pour 18 cartes (contre 111 Mo pour les archives complètes) |
| Reproductible | fichiers importés présents dans `assets/` ; recette et empreintes dans `docs/assets/IMPORT_RULES.md` (la boîte de transport `assets-1` a été retirée du dépôt après import) |

## Nature Kit — Kenney, CC0 1.0 (ART-K1, 2026-08-06)

| | |
|---|---|
| Auteur / source | **Kenney** — <https://kenney.nl/assets/nature-kit> |
| Licence | **CC0 1.0 Universal** (fichier `License.txt` du pack, version 2.1) |
| Formats retenus | glTF binaire (`Models/GLTF format/*.glb`) |
| Cible | `assets/environment/cliffs/` |
| Sélection importée | 8 modèles : `cliff_large_rock`, `cliff_blockSlope_rock`, `cliff_half_rock`, `cliff_corner_rock`, `cliff_cornerLarge_rock`, `rock_largeA`, `rock_largeC`, `rock_smallB` |
| Modifications | **aucune** sur les fichiers : copie à l'octet près. L'échelle « tuile » du kit (1 m natif) est corrigée **à l'usage** par `KitScale`, jamais en réécrivant l'asset |
| État | **importé** (2026-08-06) — le reste du pack est retéléchargeable chez l'auteur, à l'URL de source ci-dessus |

## Dungeon Pack 1.1 FREE — KayKit / Kay Lousberg, CC0 1.0 (ART-KK1, 2026-08-06)

| | |
|---|---|
| Auteur / source | **Kay Lousberg** — <https://www.kaylousberg.com> |
| Licence | **CC0 1.0 Universal** (fichier `License.txt` du pack) — crédit non obligatoire, donné volontairement |
| Formats retenus | glTF (`Assets/gltf/`) |
| État | **déposé, non encore importé** — destiné à la Citadelle de l'Œil-Tempête (phase donjon) |

## Ultimate Nature (FBX/OBJ) — Quaternius, CC0 1.0 (ART-Q9, 2026-08-06)

| | |
|---|---|
| Auteur / source | **Quaternius** — <https://quaternius.com> (même auteur que ART-Q0/Q8) |
| Licence | **CC0 1.0 Universal** |
| Contenu | 150 modèles OBJ + FBX : saules, rochers moussus, troncs, blé, variantes enneigées et automnales |
| Cible | `assets/environment/riverside/` |
| Sélection importée | 8 modèles OBJ + leurs `.mtl` : `Willow_1/3/5`, `Rock_Moss_2/5`, `TreeStump_Moss`, `WoodLog_Moss`, `BushBerries_1` (348 Ko) |
| Modifications | **aucune** sur les fichiers. L'OBJ s'importe en ressource **Mesh** (et non en scène) — contrat vérifié dans le `.import` généré puis rendu exécutable par test. Échelle corrigée **à l'usage** par `KitScale` |
| État | **importé** (2026-08-06) — le reste du pack est retéléchargeable chez l'auteur, à l'URL de source ci-dessus |

## Promotion « monde ouvert » — CC0 Quaternius (ART-Q8)

63 modèles supplémentaires promus depuis les mêmes archives Quaternius
Standard déjà attribuées ci-dessous (ART-Q0), pour l'ordre d'extension
« monde entièrement explorable » : toitures, débords, sols d'intérieur,
portes, fenêtres de toit, escaliers intérieurs et extérieurs, balcons,
clôtures, cheminée, plus des essences d'arbres, herbes hautes, plantes,
rochers et dalles de chemin.

| | |
|---|---|
| Licence | **CC0 1.0 Universal** — identique à ART-Q0, même archives |
| Dossier neuf | `assets/environment/village/` (53 pièces d'architecture modulaire) |
| Autres cibles | `assets/environment/{foliage,rocks,props}/` |
| Sélection | `docs/assets/PROMOTIONS.csv`, section « Monde ouvert » — un clone rejoue `python3 tools/promote_quaternius.py <extraction> --apply` et reconstruit les mêmes fichiers |
| Modifications | aucune : copie à l'octet près, textures dédupliquées par dossier cible |
| Poids | 56,8 Mo (139 fichiers ; les textures partagées ne sont copiées qu'une fois par dossier) |

## Packs Quaternius Standard — CC0 1.0 Universal (ART-Q0)

| Élément | Valeur |
|---|---|
| Auteur | **Quaternius** (https://quaternius.com) |
| Licence | **CC0 1.0 Universal (Public Domain Dedication)** — confirmée sur le fichier `License*.txt` PRÉSENT DANS CHACUNE des sept archives, https://creativecommons.org/publicdomain/zero/1.0/ |
| Canal d'acquisition | boîte de transport déposée par le propriétaire sur une Release du dépôt, retirée après import ; empreintes SHA-256 relevées à l'import et conservées dans `docs/assets/QUATERNIUS_INBOX.md` — c'est ce fichier qui fait foi désormais |
| Archives sources | Stylized Nature MegaKit, Fantasy Props MegaKit, Medieval Village MegaKit, Universal Base Characters, Modular Character Outfits – Fantasy, Universal Animation Library 1 et 2 (éditions Standard, gratuites) |
| Modifications | copies à l'octet près depuis les archives, SAUF les trois dérivations listées ci-dessous ; la sélection (~130 modèles promus sur 2162 entrées) est documentée dans `docs/assets/PROMOTIONS.csv` et `docs/assets/ASSET_MANIFEST.csv` |
| Fichiers dans le build | `assets/environment/{foliage,rocks,props,dungeon}/` et `assets/characters/{hero,enemies,parts}/` — voir manifeste |

### Dérivations d'assets Quaternius (V4 lot 13) — licites en CC0, consignées

| Fichier | Nature de la modification |
|---|---|
| `assets/characters/hero/T_Ranger_Hero_BaseColor.png` | dérivée de `T_Ranger_BaseColor.png` : recoloration turquoise (#168F9B) de la seule région UV de la capuche, script reproductible `tools/godot/recolor_hero_hood.gd`, manifeste JSON à côté du fichier |
| `assets/characters/parts/T_Hair_1_Normal_png.png` | copie octet à octet de `T_Hair_1_Normal.png` sous le nom que le gltf `Superhero_Male_FullBody` référence — correction d'un défaut de nommage AMONT du pack, aucune retouche d'image |
| `assets/characters/parts/T_Eye_Normal_png.png` | idem, copie de `T_Eye_Normal.png` |
| `assets/characters/parts/SM_UniversalHead.glb` | **TÊTE** découpée dans `Superhero_Male_FullBody.gltf` (même pack CC0) par `tools/extract_head.py`, script reproductible : sélection des 2 516 triangles réellement pilotés par l'os `Head`, puis transport dans le repère local de cet os. Aucune retouche de forme, aucun sommet ajouté. Motif : ni `Male_Ranger.gltf` (héros — il ne livre que la capuche) ni `Male_Peasant.gltf` (les trois pillards) ne contiennent de crâne ; le playtest du 2026-08-07 voyait l'intérieur du capuchon, vide. L'outil refuse d'écrire si les squelettes source et cible ne partagent pas exactement l'os `Head` |
| `assets/environment/foliage/Leaves_TwistedTree_C_olive.png` | dérivée de `Leaves_TwistedTree_C.png` (passe H-1) : rotation de teinte rouge→vert-olive (HSV : teinte recentrée sur 0,24, saturation ×0,9, valeur conservée) — les feuilles d'automne du pack couvraient la vallée de rouge sang, contre le ratio 60 % verts/ocres de la palette §3.4. Les quatre `.gltf` (`TwistedTree_1/2/3`, `Bush_Common`) référencent la variante ; l'originale reste sur disque, non référencée |

CC0 : aucune attribution exigée légalement ; elle est donnée ici par honnêteté
de provenance. Aucun compte, aucun paiement, aucune restriction de
redistribution. Les archives elles-mêmes ne sont **pas** versionnées.

## Ressources produites par le projet

| Ressource | Origine | Auteur | Licence | Modifications |
|---|---|---|---|---|
| `source_assets/blender/props/SM_TestCube.blend` | généré par `tools/blender/make_test_assets.py` | projet | licence du projet | — |
| `source_assets/blender/props/SK_TestRigAnim.blend` | généré par `tools/blender/make_test_assets.py` | projet | licence du projet | — |
| `assets/environment/props/SM_TestCube.glb` | export de la source ci-dessus | projet | licence du projet | export glTF 2.0 |
| `assets/characters/hero/SK_TestRigAnim.glb` | export de la source ci-dessus | projet | licence du projet | export glTF 2.0 |

| `scenes/environment/Tent.tscn` + `scripts/world/props/awning_tent.gd` | construit par script dans le moteur | projet | licence du projet | — (création 2026-08-11, lot D) |
| `scenes/environment/Campfire.tscn` + `scripts/world/props/campfire_prop.gd` | construit par script dans le moteur | projet | licence du projet | — (création 2026-08-11, lot D) |

L'auvent et le foyer de camp sont des créations **originales du projet**, sans
aucune ressource externe : géométrie primitive assemblée par code, matériaux
tirés de la palette §3.4. Rien à télécharger, rien à attribuer à un tiers. Ils
livrent `prop.tent` et `prop.campfire`, deux identifiants qu'`AssetRegistry`
réservait depuis ART-Q0 vers des fichiers absents.

Ces quatre fichiers sont des **assets de test du pipeline**, pas du contenu de jeu.
Ils prouvent que la chaîne Blender → glTF transporte échelle, pivot, matériaux,
armature et animation. Ils ne doivent apparaître dans aucune scène jouable.

## Assets de production (ART-P0)

| Asset | Origine | Licence |
|---|---|---|
| `SM_WornSword` (.blend, .glb, textures) | **création originale du projet** — géométrie, UV et textures générées par `tools/blender/make_worn_sword.py` (reproductible, seed fixe) | licence du projet |
| `T_WornSword_Icon.png` | rendu Godot du modèle ci-dessus (`tools/godot/render_weapon_icon.gd`) | licence du projet |
| `SK_Raider{Red,Blue,Black}` (.blend, .glb) — Phase H lot H.2 | **œuvre dérivée**. Le CORPS (torse, bras, jambes, pieds) et le SQUELETTE à 65 os viennent du pack Quaternius « Universal Base Characters » CC0 déjà attribué ci-dessus, via `Male_Peasant.gltf`. MODIFICATIONS apportées par `tools/blender/make_raiders.py` : carrure mise à l'échelle par famille (X et Y seulement), texture de couleur de base multipliée par une teinte de faction, stature mise à l'échelle. Sont des CRÉATIONS ORIGINALES du projet, ajoutées par-dessus : la tête et le cou de chaque famille (les personnages modulaires Quaternius sont livrés sans tête), les excroissances osseuses, la crête, la visière fendue, la mâchoire, les épaulières, les gardes et la ceinture. Le squelette d'origine est conservé tel quel, ce qui permet de garder les bibliothèques d'animation existantes | CC0 (corps, squelette, textures — cf. Quaternius) · licence du projet (têtes, armures, accessoires) |
| `SK_RavineTroll`, `SK_CentaurHunter` (.blend, .glb) — Phase H lots H.3-H.4 | **création originale du projet** — géométrie et rigs générés par `tools/blender/make_creatures.py`. Aucune anatomie réelle citable : le chasseur n'a ni sabots, ni crinière, ni croupe équine | licence du projet |
| `SK_StormGuardian` (.blend, .glb, textures) — Phase H lot H.1 | **création originale du projet** — géométrie, rig 22 os, UV et atlas générés par `tools/blender/make_storm_guardian.py` (reproductible, seed 20260803). Bête-machine à six appuis : aucune anatomie réelle citable, aucune silhouette empruntée, aucun symbole d'une autre licence | licence du projet |

Aucun contenu externe, aucun symbole d'une licence existante.

## Outils (non redistribués avec le jeu)

| Outil | Version installée | Licence | Rôle |
|---|---|---|---|
| Godot Engine | 4.7.1-stable (commit `a13da4fe`) | MIT | moteur — compilé depuis la source, voir DECISIONS D-001 |
| Blender | 4.0.2 (paquet Ubuntu) | GPL-3.0-or-later | DCC — production des sources 3D |
| `io_scene_gltf2` | 4.0.44 | Apache-2.0 | exporter glTF, fourni avec Blender |
| numpy | 1.26.4 | BSD-3-Clause | dépendance de l'exporter glTF |

Le moteur Godot est sous licence MIT : sa redistribution avec le jeu est autorisée,
à condition de conserver l'avis de copyright. Blender est un outil de production et
n'est pas redistribué ; sa licence GPL **ne contamine pas** les assets produits avec.

## Image de référence North Star (Phase 0 — remplacée)

Fournie par l'auteur du projet comme **référence de cadrage uniquement**. Jamais
versionnée (KNOWN_ISSUES ISS-003). Depuis la Passe visuelle V4.1, elle est
**remplacée comme autorité** par le pack V4 ci-dessous et ne garde qu'une valeur
historique.

## Pack visuel V4 (`source_assets/concepts/final_v4/`)

| Élément | Valeur |
|---|---|
| Source | `ECLATS_ORAGE_FINAL_ATMOSPHERE_PACK_V4.zip`, fourni par le propriétaire du projet (2026-08-01) |
| Auteur / droits | concepts commandés par le propriétaire pour ce projet ; usage interne de référence |
| Nature | illustrations générées/peintes **hors moteur** — références de composition, ambiance, palette et hiérarchie |
| Statut dans le build | **AUCUN** : jamais asset, jamais skybox, jamais billboard, jamais texture d'UI, jamais preuve (§0.2) |
| Binaires | **versionnés** (2026-08-02) dans `source_assets/concepts/final_v4/` — SHA-256 dans le README du dossier ; ~12,7 Mo en git simple, LFS indisponible (décision consignée) |

Tout ce que ces images montrent est **reconstruit** en 3D réelle et en interface
Godot alimentée par les données réelles. Rien n'en est extrait ni copié-collé.

## Contrôle avant chaque gate artistique

- [ ] Chaque asset du build a une ligne ici.
- [ ] Aucune ressource extraite d'une œuvre commerciale.
- [ ] Aucun nom, symbole, silhouette ou son appartenant à une licence existante.
- [ ] Aucune dépendance à un compte personnel ou à un service payant.

## Sons de remplacement générés (`assets/audio/sfx/*.wav`)

- **Source** : synthétisés par `tools/audio/make_placeholder_sfx.py` (sinus,
  bruit filtré, enveloppes) — aucun échantillon externe, aucune bibliothèque.
- **Auteur** : ce dépôt. **Licence** : domaine public de fait (générés par un
  script versionné, reproductibles à l'octet près hors jitter de compilation).
- **Statut** : PLACEHOLDERS. Leur rôle est qu'aucune action ne soit muette
  (§18.2) ; ils ne prétendent pas à la qualité finale — pas de variation par
  matière, pas de mixage écouté (conteneur sans périphérique audio, ISS-004).

## Packs Kenney livrés par le coursier (`source_assets/external/`, 2026-08-05)

Téléchargés par le workflow `asset-courier.yml` (run n°2) depuis les dépôts
GitHub officiels de KenneyNL — le conteneur de dev n'a pas d'accès réseau aux
sites d'assets. **Hors build** : la promotion vers `assets/` reste manuelle,
pack par pack, avec ligne dédiée ici au moment de la promotion.

| Pack | Contenu retenu (après élagage) | Licence livrée |
|---|---|---|
| `kenneynl_starter_kit_basic_scene` | **Mini Arena** : colonnes, murs, portail, escaliers, statue, bannière, râtelier, épée, lance, sol (GLB + colormap) | **CC0 1.0** (License.txt du pack, crédit Kenney/Tony Schär facultatif) |
| `kenneynl_starter_kit_3d_platformer` | herbe, plateformes, drapeaux, nuage, sons saut/atterrissage/pas, sprites particule/ombre | MIT (LICENSE.md, © Kenney) |
| `kenneynl_starter_kit_fps` | murs, plateformes, sons pas/saut/atterrissage/impacts, sprites burst/hit/ombre | MIT (LICENSE.md) |
| `kenneynl_starter_kit_city_builder` | bâtiments, routes, fontaine, arbres, **ambience.ogg**, sons de placement | MIT (LICENSE.md) |
| `kenneynl_starter_kit_racing` | tentes/forêt de déco, sons moteur/**impact**/dérapage, sprite smoke | MIT (LICENSE) |
| `kenneynl_starter_kit_match_3` | sprites sparkle/curseurs/tuiles | README : code MIT, **sprites CC0** |

Notes : les polices `.ttf` (Lilita, SIL OFL) ont été élaguées par le workflow —
seuls leurs fichiers de licence subsistent ; aucune police externe n'est donc
embarquée à ce jour. MIT exige de conserver la notice de copyright : les
`LICENSE.md` sont versionnés à côté des fichiers et devront accompagner toute
promotion vers `assets/`.

## Bibliothèque mondiale complémentaire — Kenney CC0 (quarantaine, 2026-08-12)

La branche dédiée `codex/world-asset-library-20260812` contient, sous
`asset_library/inbox/`, une sélection **hors build** destinée à la future passe de
toute la carte. `.gdignore` empêche son import automatique. Aucun de ces fichiers
n'est un asset de production tant qu'une promotion ciblée n'a pas reçu sa propre
ligne dans ce document et dans `docs/assets/ASSET_MANIFEST.csv`.

| Famille | Packs | Autorité de licence |
|---|---|---|
| 3D | Castle Kit, Modular Cave Kit, Fantasy Town Kit, Graveyard Kit, Survival Kit, Watercraft Kit | pages officielles Kenney, **CC0 1.0** |
| audio | RPG Audio, Interface Sounds | pages officielles Kenney, **CC0 1.0** |
| VFX | Particle Pack, Light Masks, Smoke Particle Assets | pages officielles Kenney, **CC0 1.0** |

Le transport automatisé passe par les archives publiées par Kenney sur
OpenGameArt ; l'auteur, la source officielle, l'URL de transport et la licence sont
verrouillés dans `asset_library/SOURCES.lock.csv`. Chaque dossier contient
`PROVENANCE.md`; les empreintes des archives et fichiers vivent dans
`SOURCE_ARCHIVE_SHA256.csv` et `SHA256SUMS.txt`. Les archives, formats redondants et
sources Unity ne sont pas versionnés.
