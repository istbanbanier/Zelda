# R2a-3.5.8 — checkpoint 2 : l'état candidat n'existait pas ; il existe par arbitrage

Date : 2026-08-18.

## 1. Le constat de l'agent C — et il bloquait tout

« `531cdd8` + T-jonction + `massif_lissage` + `86b01ece` » **n'existait pas comme
état de fichier**. Matrice de dry-runs sur les cinq ordres d'application :
aucune permutation brute ne passe. Cause : la couche T-jonction et
`massif_lissage` réécrivent **la même ligne** de `soustraire()` et portent deux
traitements sémantiquement voisins des n-gones colinéaires —
`_a_bord_colineaire` + `_resorber_faces_plates` contre
`_desamorcer_ngones_colineaires`.

Deux états sains épinglés par C : `S1` = 531cdd8 + T-jonction (générateur
`24fb636c…`, **celui qui a produit la baseline `40714c46`**) et `M2` = 531cdd8 +
massif + intersections (`0d5f564a…`).

## 2. L'arbitrage du lead, et le fait mesuré qui le fonde

> **Dans `soustraire()`, la version T-jonction gagne, verbatim. Le hunk
> `soustraire()` de `massif_lissage` est exclu — ni l'appel
> `_desamorcer_ngones_colineaires`, ni sa définition.**

1. Le traitement T-jonction est **le seul vérifié sur un GLB réellement
   exporté** (`40714c46` : 0 aire nulle, 0 lamelle < 1e-9, V/E/F/aire/volume
   identiques, prédictions tenues, reproduit par le lead). L'autre ne l'a
   jamais été sur l'état complet.
2. **`soustraire()` ne touche pas le collider** — mesuré par C : le hash de
   géométrie de `COL_` est identique de part et d'autre de la T-jonction. La
   décision ne change donc rien aux déterminants des 4 intersections, et
   l'exigence de reproduction `4 / 0,2434` de l'it.0 tient telle quelle.
3. **Un mécanisme, pas deux** — même règle que le retrait d'`_orient_exact` :
   un no-op appelé est encore un second mécanisme que chaque passe future doit
   comprendre avant de toucher la fonction.

État fusionné prescrit : `soustraire()` de S1 + tout le reste de M2 (table
`MASSIF`, `construire()`/`anneau_exterieur`, `controle_penetration_exacte` avec
sa note « minorant −12 % ») + `86b01ece`. Le hash `cce3da51` (qui incluait
l'insertion manuelle) est caduc ; l'agent A ré-épingle et publie.

## 3. Provenance close (agent C)

- `027b80e4` : **supersédé, perdu comme fichier** — recherche bornée dans les
  cinq arbres + tronc, aucun ne correspond ; corroboré par les relevés du lead.
- T-jonction s'applique proprement sur `531cdd8` (générateur byte-identique
  entre `531cdd8` et le HEAD d'`a_epaisseur` : `09fcc4a5…`) et reproduit
  exactement l'arbre ; `massif_lissage` 6/6 sur `531cdd8` nu ; `86b01ece` 4/4
  sur l'état MASSIF-seul.

## 4. Baseline re-mesurée, mesuré-contre-mesuré (agent C)

`40714c46` : V=10 037 / E=30 105 / F=20 070, 0 bord libre, 0 non-manifold,
genre 0, aire `842,188236 m²`, volume `+798,812 m³` normales sortantes, AABB
figé. Instrument neuf : `tools/cave_sha256_geom.py` (positions f32 + indices
canonisés, par nœud, en-tête documenté). Paires baseline : **C** SM `e6a4bdb0…`
· COL `eb26d38e…` ; **lead** SM `dd3ea5c6…` · COL `f17852ba…`. Les valeurs ne
se comparent jamais ENTRE outils — chaque instrument compare ses propres
paires ; la structure concorde entre trois outils indépendants.

Mesure clef au passage : **COL identique de part et d'autre de la T-jonction**
(3a80ae71 vs 40714c46) — c'est le fait qui rend l'arbitrage §2 sans risque
pour la reproduction it.0. Et le `COL_` de `40714c46` = pré-MASSIF, prouvé
(identique à celui de `5bd1b4f5`).

## 5. Anti-circularité (rappel des deux garde-fous actifs)

- clamp extérieur d'enveloppe : `min(position actuelle, surface visible −
  marge)` — les 71 sommets déjà saillants (préexistant, jusqu'à 2,72 m) ne
  reculent pas mais n'avancent jamais ; compte et max publiés avant/après ;
- retrait de cavité : poche d'alcôve en collision **≥ 0,524 m** ; la marge
  prévue de l'instrument de B est **figée sur l'état `86b01ece`**, jamais lue
  dans le code modifié par A — correction d'une consigne circulaire que le
  lead avait lui-même donnée.

## 6. Divers

Manifeste de shots `shots_r2a358.json` prêt : 15 vues, 0 murée, caméras A/B
identiques à celles de R2a-3.4 (`tranche4_final`, commit `55c4803c`,
dirty=false). Captures différées à l'arbre committé. Vue « collider seul » en
tracé d'instrument étiqueté.

Budget : **0 des 3 itérations consommées.** It.0 (hors budget) en cours chez A.
