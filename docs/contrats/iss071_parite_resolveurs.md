# Contrat ISS-071 — parité de résolution des modèles entre éditeur et export

**VIVANT.** Écrit AVANT toute modification des deux résolveurs, comme l'exige la
directive corrective S1 §2. Ce document dit ce qui doit être vrai ; son
exécutant est `tools/iss071_parite.py`, et son portail est
`tools/gate_export_parite.sh`. Un invariant qui ne vit que dans cette page se
dégrade en silence — c'est la leçon de PROMPT4_METHOD §0.

## 0. Le défaut que ce contrat empêche de revenir

Dans une build exportée, `DirAccess.get_files()` ne rend pas les fichiers
sources : le PCK ne contient que leurs métadonnées `<nom>.gltf.import`. Les deux
résolveurs indexent en testant le suffixe `.glb` / `.gltf` ; leur index sort
donc VIDE, et 1 094 appels de placement échouent sans que le jeu plante.
Mesuré, prouvé au laboratoire, consigné en ISS-071.

## 1. Les deux résolveurs sous contrat

| résolveur | fichier | répertoires |
|---|---|---|
| `WorldV2PlaceKit.scene_for()` | `scripts/world_v2/poi/world_v2_place_kit.gd` | `MODULE_DIRS` (6) |
| `AssetRegistry.model()` | `scripts/core/asset_registry.gd` | `MODEL_DIRS` (6) |

Les deux publient séparément leur manifeste par `manifeste_iss071()`.

## 2. Invariants — chacun est une assertion, pas une intention

| # | invariant | comment il rougit |
|---|---|---|
| I1 | l'ensemble des noms canoniques indexés est **identique** en éditeur et en export | différence symétrique des clés d'index ≠ ∅ |
| I2 | chaque nom sélectionne le **même chemin source** dans les deux environnements | un couple `nom → chemin` diffère |
| I3 | la comparaison porte sur les **couples**, jamais sur un compte | deux index de même taille et de contenus différents doivent ROUGIR |
| I4 | pour tout chemin indexé, `ResourceLoader.exists(chemin, "PackedScene")` est vrai | un chemin indexé non chargeable |
| I5 | pour tout chemin indexé, `load(chemin) as PackedScene` réussit | un `load` qui rend `null` |
| I6 | aucune collision de nom n'est résolue **silencieusement** | une collision non publiée au manifeste |
| I7 | les priorités historiques entre répertoires ne changent pas | l'ordre de `MODULE_DIRS`/`MODEL_DIRS` ou la règle premier-gagne / dernier-gagne change |
| I8 | aucun cache ne change de durée de vie | `SCENE_CACHE_MAX`, `MODEL_CACHE_MAX`, `liberer_caches()`, `StaticResourceCaches` modifiés |
| I9 | aucun modèle manquant n'est remplacé silencieusement par du graybox | un placement manqué qui ne laisse ni erreur ni compteur |

## 3. Compteurs de parité — le vert doit être POSITIF

Une simple disparition des messages d'erreur ne prouve rien. Le gate compare
aussi des compteurs qui doivent être **non nuls et égaux** des deux côtés :

| compteur | source |
|---|---|
| `modules_instancies` | `WorldV2PlaceKit.module()` |
| `demandes` / `resolus` / `manques` par nom | les deux résolveurs |
| `cellules_emises` / `cellules_manquees` | `WorldV2VegetationBuilder` |
| `lieux_poses` | `WorldV2Root` |

## 4. Gate final (directive §8)

| grandeur | valeur exigée |
|---|---:|
| différence d'index (I1, I2) | 0 |
| différence des modèles demandés | 0 |
| différence des modèles chargés | 0 |
| modèle demandé mais non chargé | 0 |
| appels de placement manqués | 0 |
| lignes `kit : modèle inconnu` | 0 |
| lignes `modèle végétal introuvable` | 0 |
| lignes `flower_field … inconnu` | 0 |
| `modules_instancies` | > 0 et identique des deux côtés |
| `cellules_emises` | > 0 et identique des deux côtés |

## 5. Ce que le contrat n'autorise pas

- balayer `res://.godot/imported/` : ses noms sont hachés, c'est un détail interne ;
- forcer l'inclusion des sources brutes dans le PCK pour sauver l'ancien balayage ;
- une liste manuelle des 110 modèles ;
- abaisser un seuil ou filtrer une famille d'erreurs pour obtenir un vert ;
- changer la priorité entre deux chemins de même nom canonique sans le prouver.

## 6. Appareil de mesure

L'instrumentation (`manifeste_iss071()`, compteurs `_diag_*`) est posée AVANT le
correctif, dans un commit séparé, et ne change aucun comportement de résolution.
Elle vit hors de `liberer_caches()` : y toucher changerait la valeur épinglée
par les tests d'ISS-059, pour aucun gain.
