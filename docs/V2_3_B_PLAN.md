# V2.3-B — inventaire exact, découpage en lots, et lot 1

**VIVANT.** Ce document décrit le travail en cours et fait autorité sur le
périmètre de V2.3-B. Quand il diverge du code, c'est le code qui a raison :
revérifier et consigner l'écart.

Ouvert le 2026-08-21 après le commit de clôture R2B.3.1. `GO_V2_3_B=TRUE`.

## 1. Le compte exact — 27 sujets, pas 31

Le layout porte 31 POI. Six sont **déjà bâtis et raccordés** ; il ne reste donc
pas 31 lieux à construire, et le supposer aurait gonflé le plan d'un quart.

La liste qui fait foi n'est pas le layout mais `REGISTRY`, dans
`scripts/world_v2/poi/world_v2_places_builder.gd` : un POI absent de ce
dictionnaire garde son simple marqueur V2.2, quel que soit le fichier qui porte
son nom ailleurs.

| | compte |
|---|---:|
| POI au layout | 31 |
| POI déjà au registre | **6** — riverside_village, abandoned_farm, stone_bridge, waterfall_cave, thunderstruck_tree, ember_raider_camps |
| POI restants | **25** |
| sites systémiques restants | **2** — magnetic_bridge, earth_altar (conductive_basin est bâti) |
| **total à construire** | **27** |

`camp` et `pylon` sont au registre mais ne sont pas des POI : l'un est un
checkpoint, l'autre une ancre de `spec_anchors`.

## 2. Les huit familles, et ce qui reste dans chacune

Grammaire visuelle : `docs/WORLD_V2_POI_CONTRACTS.md` §2.

| Famille | bâti | reste |
|---|---|---|
| village | riverside_village | logging_hamlet, mining_post |
| ruine | abandoned_farm | watchtower_ruin, ancient_aqueduct, storm_caravan |
| vestige | — | ruined_observatory, barrow_cemetery, old_rampart, forest_shrine |
| grotte | waterfall_cave | abandoned_mine, hollow_crypt |
| souterrain | — | hidden_passage, crystal_hollow |
| repère naturel | stone_bridge | ancient_tree, turquoise_spring, flower_field, overlook_summit |
| merveille | thunderstruck_tree | veil_falls, watchers_circle, wind_gorge, storm_grove |
| territoire | ember_raider_camps | azure_patrol_run, obsidian_bastion, colossus_lair, hunter_range |

Répartition des restants par région : r08 en porte **sept**, r04/r06/r07 quatre
chacune, r10 trois, r09 deux, r02 une. Un découpage naïf par région
concentrerait un lot entier dans la steppe du nord — ce que la directive
interdit explicitement.

## 3. Découpage en cinq lots

Priorités appliquées, dans l'ordre de la directive : réemployer les pipelines
validés · couvrir plusieurs régions sans répétition visible · privilégier
exploration, orientation et rythme · ne pas concentrer une seule région ·
isoler les sujets à forte dépendance ou forte identité.

**La règle qui a le plus pesé est la quatrième, à l'échelle de la FAMILLE.**
Quatre vestiges dans un même lot se ressembleraient forcément, quelles que
soient les intentions : chaque lot mêle donc des familles dont les silhouettes
n'ont rien en commun.

| Lot | Thème | Sujets | Régions |
|---|---|---|---:|
| **1** | les repères qui orientent | watchtower_ruin · overlook_summit · turquoise_spring · forest_shrine · barrow_cemetery · flower_field | r02 r04 r06 r07 r08 |
| 2 | les hameaux et l'eau | logging_hamlet · mining_post · veil_falls · ancient_aqueduct · magnetic_bridge · earth_altar | r04 r06 r07 r09 |
| 3 | le sous-sol | abandoned_mine · hollow_crypt · hidden_passage · crystal_hollow · ancient_tree · watchers_circle | r04 r07 r08 r09 |
| 4 | l'orage | storm_grove · storm_caravan · wind_gorge · ruined_observatory · old_rampart | r06 r07 r08 r10 |
| 5 | les territoires | azure_patrol_run · obsidian_bastion · colossus_lair · hunter_range | r06 r08 r10 |

Le lot 5 est **dédié** : les quatre territoires sont de l'architecture tactique
(couverts, accès, sorties) et partagent une dépendance forte au comportement
des rencontres. Les mêler à des repères naturels aurait produit un lot dont la
moitié dépend d'un système que l'autre moitié ignore.

## 4. Lot 1 — pourquoi ces six-là

| Sujet | Famille | Région | Site v2 | Pipeline réemployé | Ce qu'il apporte au joueur | Récompense canonique |
|---|---|---|---|---|---|---|
| `watchtower_ruin` | ruine | r04 | (-160, 26, 40) | ferme ruinée | verticale d'orientation à l'ouest, visible de loin | 15 flèches |
| `overlook_summit` | repère naturel | r07 | (168, 22, 52) | composition rocheuse | panorama est ; **l'arc récompense l'ascension** | arc simple |
| `turquoise_spring` | repère naturel | r04 | (-136, 12, 40) | bassin conducteur | eau vive ; à 24 m du guet, ils se lisent ensemble | fruit de soin |
| `forest_shrine` | vestige | r06 | (86, 7, 74) | kit ruine + arbre | intime, sous couvert, récompense la curiosité | épice rare |
| `barrow_cemetery` | vestige | r08 | (56, 4, -64) | kit pierre | masses tombées, lecture funéraire | hache lourde |
| `flower_field` | repère naturel | r02 | (-56, 5, 124) | végétation | respiration près du spawn, premier POI atteignable | herbe d'endurance |

Six récompenses **de six natures différentes** : flèches, arme de distance,
soin, épice, arme lourde, endurance. Aucun lieu ne répète l'effet du précédent
sur la préparation du joueur.

`watchtower_ruin` et `turquoise_spring` sont à **24 m** l'un de l'autre, même Z.
Ils seront vus dans le même cadre. Les construire dans le MÊME lot est
délibéré : deux passes séparées produiraient deux compositions qui se
contredisent.

## 5. Trois voies parallèles

Arbres de travail détachés issus du SHA de clôture (`tools/worktree_lot.sh`),
aucun push d'agent, aucun merge commit, le lead cueille par cherry-pick.

| Voie | Périmètre | Interdits |
|---|---|---|
| **A — implantation** | positions issues du layout seul, sondes de terrain, routes/gués/eau/caméras/navigation, fondations et collisions | aucun travail artistique sur les assets gelés |

**Précision que la revue contradictoire a rendue nécessaire.** Le périmètre de
la voie A — terrain, hydrologie, caméras, marqueurs — est *intégralement gelé*
(`docs/contrats/gel_v2_3_b.sha256`). Ce n'est pas une contradiction : la voie A
**lit** ces bâtisseurs pour savoir où poser un lieu, elle ne les **modifie**
jamais. Si un site du layout s'avère impossible — fondation sous l'eau, collider
en travers d'un gué — la réponse n'est pas de retoucher le terrain gelé : c'est
une régression précise et reproductible à porter au propriétaire, comme la
directive §4 l'exige.

Corollaire opérationnel : le gel n'interdit pas d'**ajouter**. Créer
`WatchtowerRuinPlace.tscn` et son script ne rougit pas — le périmètre gelé est
énuméré, pas globé sur des répertoires qui vont grossir. Vérifié.

Deuxième corollaire, à connaître avant de s'en étonner : chaque lot qui ajoute
des scripts et des scènes **déplace la signature du résidu de fin de processus**
(chaque `.tscn` chargée épingle ses `GDScript`). `validate_fast` le signalera en
`ENGINE_SCRIPT_CACHE_TELEMETRY : DÉRIVE`, code 2, **bloquant**. C'est attendu et
ce n'est pas une fuite : entériner la nouvelle enveloppe avec
`tools/gate_fuite_composition.sh --entériner` en fin de lot, et justifier dans
`docs/DECISIONS.md`.
| **B — scènes et assets** | construction des six lieux, réemploi des kits CC0 attribués, Blender si nécessaire, identité propre à chacun | aucun assemblage final composé uniquement de primitives génériques |
| **C — contrats et preuves** | tests rouges d'abord, budgets, provenance et licences, contrôles négatifs, plans de captures, détection de répétition | ne construit aucun lieu |

Le lead lit les contrats lui-même, arbitre les trois plans, **reproduit
personnellement** chaque résultat, tient les verrous, intègre, inspecte chaque
capture à taille réelle, et ne prononce que le verdict **technique**.
