# Audit V0 — Phase H (Prompt 3 §29, Prompt 4 §1)

Date : 2026-08-05 · Arbre : `d8b92c8` · Baseline : `evidence/phaseH/vista_h6_citadelle.png`
(≈ 56/100 §30.2, auto-évalué) et les six captures d'itération H-1→H-6.

Statuts : `KEEP` (conforme, conservé) · `REWORK` (base conservée, à retravailler) ·
`REPLACE` (à remplacer par swap testé) · `MISSING` (n'existe pas) · `BLOCKED`
(voie de production ou licence non tranchée).

## Matrice

| Élément | État | Statut | Notes |
|---|---|---|---|
| **Héros** (Quaternius Universal Base + tenue, capuche recolorée #168F9B) | jouable, lisible de dos | **REWORK** | manque 3 des 5 signes §13.1 : épaulière ivoire/bronze, Bracelet visible, diagonale arc/carquois |
| **Animations** (UAL 1+2, retarget bakés) | locomotion/combat OK | **KEEP**/REWORK | bibliothèque §13.6 incomplète (Résonance absente — dépend du Prompt 2) |
| **raider_red/blue/black** (corps Quaternius, stature/carrure/teintes différenciées) | 3 familles testées | **REWORK** | silhouettes distinctes prouvées (turntables evidence/phaseH) ; équipements §14 à produire |
| **ravine_troll, centaur_hunter** | corps solidaires testés | **REWORK** | en DERNIER (arbitrage verrouillé n°4) |
| **Gardien de l'Orage** (SK_StormGuardian.glb) | modèle + 3 phases jouables | **REWORK** | dégâts visuels progressifs et sous-meshes destructibles §15.2 absents |
| **Terrain macro** (dalles + rampes + prismes) | composé, testé, navmesh | **KEEP** (graybox assumé) | remplacement par chunks sculptés = passe V4, après validation sourcing |
| **Montagnes/crêtes/jupes** (prismes H-1/H-2) | silhouettes OK | **REWORK** | modelé sculpté à terme ; plafonds nord testés |
| **Citadelle proxy** (masse, spire, couronne, conduits, contreforts) | focale lisible, foudre sur couronne | **REWORK** | < 20 grandes formes ✓ ; langage §2.4 partiel (arches/vides absents) |
| **Pylône proxy** | lisible à droite du cadre | **REWORK** | états §11.2 (Dormant→Active) absents |
| **Orage + éclair** (StormCell) | cumuliforme, colonne 18 m, flash testé | **KEEP** | raffinements V4 possibles (bords chauds côté soleil) |
| **Végétation** (arbres Quaternius olive, brins/fleurs procéduraux) | dense, vent, pente fleurie | **KEEP**/REWORK | phrases §7.17 partielles ; fleurs-ellipsoïdes (H-7) |
| **Sol/roche/montagne — matériaux macro** (NoiseTexture2D triplanar) | sol prouvé (R-016) | **REWORK** | H-7 étend à roche/montagne ; les 12 shaders maîtres §21 restent à écrire |
| **Eau** | néant (lit sec + gués) | **MISSING** | `SH_WaterStylized` + ruban turquoise §8 — chantier entier |
| **Camp ennemi** (props Quaternius, feu, fumée testée) | lisible, guidage S3 verrouillé | **KEEP**/REWORK | kit §10.2 partiel (bannières, râtelier à sockets) |
| **Village/hameaux/ruines/POI** (Quaternius + compositions) | 31 lieux, ancrages audités | **KEEP** | dressing focales à densifier en V4 |
| **Donjon intérieur** (vestibule + 4 salles + hub graybox) | jouable, solvable, testé | **REWORK** | kit modulaire §12 et éclairage motivé = passe V7 |
| **Shaders maîtres** (1/12 : foliage_wind) | — | **MISSING** | SH_CharacterPainterly = premier chantier (arbitrage n°2) |
| **VFX** (électricité graybox, flash, poussière) | minimaux | **MISSING** | inventaire §20 à produire (passe V9) |
| **UI/HUD** (santé, endurance, arme, flèches, notifications) | fonctionnelle, originale | **REWORK** | thème §23 (pierre/or pâle), icônes 70+, glyphs — passe V5 |
| **Typographie** | police par défaut Godot | **BLOCKED** | aucune police embarquée choisie — voie tranchée dans SOURCING_MATRIX |
| **Sons** (9 WAV générés CC0) | branchés, testés | KEEP/**REWORK** | placeholder assumé ; bibliothèque §18 = phase audio |
| **Cinématiques** | néant (flash d'ouverture seul) | **MISSING** | 7 séquences §25 — après V4/V8 |

## Synthèse

- **Aucun asset sans licence** : tout est Quaternius CC0, généré par script (CC0
  par construction) ou procédural — voir `ATTRIBUTIONS.md` et la matrice de
  sourcing. Rien ne passe `BLOCKED` pour raison de licence, SAUF la typographie
  (aucune police choisie).
- **Les gros MISSING** : eau, 11 shaders maîtres, VFX, cinématiques, icônes.
- **Chemin critique du Gate H** (zéro placeholder §23.2) : héros (5 signes),
  famille pilote finalisée, citadelle/pylône états, eau, SH_CharacterPainterly.
