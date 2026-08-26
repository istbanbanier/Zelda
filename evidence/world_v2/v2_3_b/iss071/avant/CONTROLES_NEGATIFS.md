# ISS-071 — les dix contrôles négatifs du portail d'export

**HISTORIQUE.** État mesuré le 2026-08-26 sur `cb8c5d7`, avant tout correctif.

Un portail qui ne rougit jamais est indistinguable d'un portail qui marche.
`tools/gate_export_parite.sh` a rendu ROUGE — c'est nécessaire, ce n'est pas
suffisant. Il fallait savoir **ce qu'il voit**, et **ce qu'il laisserait
passer**.

Banc : `tools/gate_export_parite_controle_negatif.sh` · journal :
`controle_negatif.log` · **12 contrôles joués, 0 échec, 4 `NON VÉRIFIÉ`**.

## 0. Le préalable qui donne un sens à tous les autres

Avant tout sabotage, le comparateur doit pouvoir rendre **VERT**. Sinon un
rouge ne prouverait rien : il serait acquis d'avance.

Base saine : le manifeste éditeur **réel** (215 + 160 entrées d'index),
redéclaré `export`, plus le journal réel privé de ses 1 094 lignes d'erreur.
C'est exactement la forme qu'un correctif doit produire.

> `30 contrôles exécutés · 0 ROUGE · 0 BLOQUÉ · 2 NON VÉRIFIÉ` → **code 0**.

Les deux `NON VÉRIFIÉ` sont I4/I5, honnêtement déclarés : le manifeste ne porte
pas la chargeabilité des chemins jamais demandés.

## 1. Tableau des dix

| # | sabotage | verdict attendu | obtenu | cause reconnue |
|---|---|---|---|---|
| 1 | normalisation `.import` désactivée dans `WorldV2PlaceKit` | ROUGE famille kit | **NON VÉRIFIÉ** — la normalisation n'existe pas encore sur `cb8c5d7`. Jumeau à l'échelle de la règle joué : `sans-import` → 5 écarts, code 1 | oui (jumeau) |
| 2 | idem dans `AssetRegistry` | ROUGE famille végétation | **NON VÉRIFIÉ** — même raison. La famille est bien observable : 631 lignes au journal réel | — |
| 3 | faux chemin source reconstruit (extension → `.scn`) | ROUGE au chargement | ROUGE, 10 écarts sur 14 cas + 7 entrées de listage | oui |
| 4 | entrée `.bin.import` interprétée comme scène | ignorée | ROUGE, 4 écarts, « Foo.bin » nommé | oui |
| 5 | suffixe `.tres.import` accepté | ignoré | ROUGE, 1 écart, « Foo.tres.import » nommé | oui |
| 5b | `split-point` · `casse` · `chemin-import` | ROUGE | ROUGE (2, 1 et 6 écarts) | oui |
| 6 | collision de nom vers deux chemins différents, publiée d'un seul côté | signalée | ROUGE, I6, collision **nommée** `Prop_Crate` avec ses deux chemins | oui |
| 7 | modèle retiré du seul index export | le verdict le NOMME | ROUGE, « 215 clés éditeur contre 214 export », `Prop_Crate` nommé | oui |
| 8 | `SCENE_CACHE_MAX` 256 → 0 (dans une COPIE) | ROUGE I8 | ROUGE, « LITTÉRAL ABSENT » | oui |
| 9 | image de l'écran de chargement soumise à la décision du portail | le portail se REFUSE | REFUS (code 3) à 0,00275 ; ACCEPTE à 0,292 | oui |
| 10 | journal dont toutes les lignes d'erreur sont filtrées | ROUGE quand même | ROUGE : I1, I3, modèles demandés/chargés, compteurs — **jamais l'absence de messages** | oui |

## 2. Le contrôle 10, en détail, parce que c'est celui qui protège du faux vert

Journal filtré : **0 ligne** des quatre familles sur 1 145 lignes. Manifeste
export réel remis. Verdict : **ROUGE**, et pour les bonnes raisons —

```
[ROUGE] I1 index AssetRegistry     :: 160 différences, 160 seulement en éditeur
[ROUGE] I3 index AssetRegistry     :: AUCUNE clé commune
[ROUGE] §4 modèles DEMANDÉS        :: 90 différences
[ROUGE] §4 modèles CHARGÉS         :: 21 différences
[ROUGE] §4 DEMANDÉ mais NON CHARGÉ :: 1 321 appels manqués en export
[ROUGE] I1 index WorldV2PlaceKit   :: 215 différences
```

Le portail ne conclut pas sur l'absence de messages ; il conclut sur la parité
des index et sur des compteurs **positifs**. Faire taire le journal ne suffit
donc pas à obtenir un vert — et c'était le seul risque sérieux de ce dispositif.

## 3. Deux défauts trouvés DANS le portail par ses propres contrôles

Corrigés le jour même, avant l'archivage :

1. **`I2/I3` rendait VERT sur 0 couple examiné.** Index export vide → aucune
   clé commune → « 0 divergence » → vert. C'est la forme exacte du piège `diff`
   sur deux fichiers absents (`tools/CLAUDE.md`). Désormais **`NON VÉRIFIÉ`**.
2. **`I4/I5` rendait VERT sur un index vide.** « 0 chemin non couvert » n'est pas
   une couverture parfaite, c'est une absence de couverture. Désormais **ROUGE**.

Le verdict global est passé de 17 à 19 ROUGE sans qu'aucun sabotage ne soit
ajouté : deux verts obtenus en n'examinant rien ont simplement cessé d'être
comptés comme des verts.

## 4. Intégrité — aucun fichier de production touché

Les sabotages 1, 2, 3 et 7 portent sur des fichiers dont l'agent A n'est pas
propriétaire. Ils sont joués soit sur une **copie jetable** hors de l'arbre,
soit sur une implémentation de référence de la règle
(`tools/iss071_regle_noms.py`) pilotée par `tests/fixtures/iss071_noms.json`.

```
world_v2_place_kit.gd  f6192541…4d6cab95  ->  f6192541…4d6cab95  (inchangé)
asset_registry.gd      ef0165c7…bd9d2d02  ->  ef0165c7…bd9d2d02  (inchangé)
manifeste éditeur      674c5842…bde156a   ->  674c5842…bde156a   (inchangé)
manifeste export       bd50b899…9e55f875  ->  bd50b899…9e55f875  (inchangé)
journal du jeu         5fc0791c…ba7e7356  ->  5fc0791c…ba7e7356  (inchangé)
git status --porcelain scripts/  :  0 ligne
```

## 5. Ce qui reste `NON VÉRIFIÉ`, et qui doit être rejoué après le correctif

1. **Contrôle 1** — désactiver la normalisation dans le vrai
   `WorldV2PlaceKit.scene_for()`, relancer le portail, exiger un ROUGE de la
   famille `kit : modèle inconnu`.
2. **Contrôle 2** — même geste dans `AssetRegistry.model()`, exiger un ROUGE de
   la famille `modèle végétal introuvable` (elle passe par le registre, pas par
   le kit : corriger un seul des deux résolveurs laisserait l'autre en recours
   muet, et c'est précisément ce qui a masqué le défaut jusqu'ici).
3. **Contrôle 8** — rejouer `test_world_v2_iss059_cache_kit.gd` avec le cache
   vidé entre deux placements ; il exige le moteur et le verrou.
4. **Contrôle 9** — voir `CONTROLE_9_BOUT_EN_BOUT.md`.
