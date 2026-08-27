# Mesures indépendantes — socle chiffré de l'audit

Produit par `tools/mesures_socle.py`. Prises **avant** de lire les
rapports des sous-agents, pour que ces rapports puissent être
confrontés à une base qu'ils n'ont pas écrite. Aucun chiffre de cette
page ne vient d'un agent.

Commit : `ece42a6` · arbre **1 fichier(s) modifié(s)** hors cette sortie

## Le monde

| Grandeur | Valeur |
|---|---:|
| Étendue du terrain | 512 × 512 m |
| Rayon jouable max | 235 m |
| Régions déclarées | 11 |
| Lignes de vue | 6 |
| Checkpoints | 5 |
| Espaces de donjon | 8 |
| Étapes de progression | 8 |

## Lieux : construits contre déclarés

| | Nombre |
|---|---:|
| POI déclarés au layout | 31 |
| Sites systémiques déclarés | 3 |
| **Total déclaré** | **34** |
| Montés dans le REGISTRY | 15 |
| dont hors liste (camp, pylône) | 2 |
| **Déclarés et NON construits** | **21** |

Achèvement de la région 1 : **38 %** des sujets déclarés.

Non construits :

- `earth_altar`
- `valley.poi.abandoned_mine.01`
- `valley.poi.ancient_aqueduct.01`
- `valley.poi.ancient_tree.01`
- `valley.poi.azure_patrol_run.01`
- `valley.poi.colossus_lair.01`
- `valley.poi.crystal_hollow.01`
- `valley.poi.hidden_passage.01`
- `valley.poi.hollow_crypt.01`
- `valley.poi.hunter_range.01`
- `valley.poi.logging_hamlet.01`
- `valley.poi.magnetic_bridge.01`
- `valley.poi.mining_post.01`
- `valley.poi.obsidian_bastion.01`
- `valley.poi.old_rampart.01`
- `valley.poi.ruined_observatory.01`
- `valley.poi.storm_caravan.01`
- `valley.poi.storm_grove.01`
- `valley.poi.veil_falls.01`
- `valley.poi.watchers_circle.01`
- `valley.poi.wind_gorge.01`

## Coût de production mesuré

Chantier World V2 : **2026-08-12 → 2026-08-27**, **727 commits** au total.

Commits touchant les fichiers de chaque lieu construit :

| Lieu | Commits |
|---|---:|
| riverside_village | 21 |
| abandoned_farm | 24 |
| stone_bridge | 16 |
| waterfall_cave | 33 |
| thunderstruck_tree | 23 |
| ember_raider | 17 |
| conductive_basin | 15 |
| watchtower_ruin | 29 |
| overlook_summit | 33 |
| turquoise_spring | 45 |
| forest_shrine | 36 |
| barrow_cemetery | 39 |
| flower_field | 24 |

Médiane **24 commits par lieu** ; minimum 15, maximum 45.

**Projection — c'est une ESTIMATION, pas une mesure.** Au rythme
observé, les **21 lieux restants de la SEULE région 1**
représentent de l'ordre de **504 commits**. Le chiffre
vaut pour l'ordre de grandeur, pas pour la décimale : il suppose que
les lieux restants coûtent comme les précédents, ce qui est faux dans
les deux sens — le pipeline s'est amélioré, mais les sujets faciles
ont été faits en premier.

## Code et tests

| Domaine | Fichiers `.gd` |
|---|---:|
| scripts/ai | 1 |
| scripts/art | 1 |
| scripts/boss | 6 |
| scripts/characters | 3 |
| scripts/combat | 6 |
| scripts/components | 14 |
| scripts/cooking | 1 |
| scripts/core | 9 |
| scripts/dungeon | 15 |
| scripts/electricity | 9 |
| scripts/enemies | 9 |
| scripts/interaction | 7 |
| scripts/inventory | 1 |
| scripts/lookdev | 2 |
| scripts/player | 4 |
| scripts/reaction | 8 |
| scripts/save | 1 |
| scripts/tools | 18 |
| scripts/ui | 6 |
| scripts/world | 28 |
| scripts/world_v2 | 31 |

| Suite | Fichiers `.gd` |
|---|---:|
| tests/fixtures | 0 |
| tests/integration | 135 |
| tests/playthrough | 6 |
| tests/support | 1 |
| tests/unit | 22 |
| tests/world_v2 | 32 |

Scènes `.tscn` : **88** · ressources `.tres` : **60**

## Sondes ciblees — presence d'un systeme, pas d'un mot

164 `class_name` declares dans `scripts/`, 6 autoloads.

| Systeme | `class_name` | Autoload | Verdict |
|---|---|---|---|
| Quetes | — | — | **ABSENT** |
| Dialogues | — | — | **ABSENT** |
| PNJ | — | — | **ABSENT** |
| New Game + | — | — | **ABSENT** |
| Streaming de region | — | — | **ABSENT** |
| Artisanat hors cuisine | — | — | **ABSENT** |
| Marchand / economie | — | — | **ABSENT** |
| Meteo / cycle jour | — | — | **ABSENT** |
| Cuisine | `PainterlyRecipe RecipeRules` | — | present |
| Sauvegarde | — | `SaveSystem` | present |
| Resonance / Bracelet | `ResonanceController ResonanceLab ResonanceLinkNode ResonanceOverlay ResonancePylonLandmark ResonanceTargetComponent` | — | present |
| Reaction materiaux | `MaterialProfile ReactionSystem` | — | present |
| Graphe electrique | `ElectricDebugOverlay ElectricDoor ElectricGraph ElectricHazard ElectricNode ElectricRelay ElectricSwitch ElectricVisual` | — | present |
| Boss | `BossArena BossDirector` | — | present |
| IA utilitaire | `UtilityBrain` | — | present |
| Inventaire | `InventoryComponent` | — | present |
| Etat de jeu | — | `GameState` | present |

Une absence de classe ET d'autoload est un signal fort dans ce depot,
ou `CLAUDE.md` impose `class_name` pour tout type reutilisable. Elle ne
vaut pas preuve formelle : un sujet peut vivre sans type nomme.
