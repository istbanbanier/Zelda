# Portail visuel R2B.1 — ferme abandonnée, avant / après

Méthode : `tools/mesure_aplats.py`, seuil de gradient calibré sur mesure
(voir l'en-tête de l'outil). Mêmes six caméras, valeurs recopiées telles
quelles de `evidence/world_v2/v2_3_r2b1/shots_r2b1.json` — les sept plans
utilisés y sont **identiques** à la version du lead au commit `4a2b43a`.

AVANT : baseline du lead, `evidence/world_v2/v2_3_r2b1/avant/`, commit `4a2b43a`.
APRÈS : `evidence/world_v2/v2_3_r2b1/ferme/apres/`, commit `9aa8978`, `repo_dirty:false`.

Portail fixé par le lead : **max ≤ 8 %**, **total ≤ 12 %**.

| vue | max % av. | max % ap. | total % av. | total % ap. | plat/beige av. | ap. |
|---|---:|---:|---:|---:|---:|---:|
| ferme_approche | 2,39 | **0,80** | 3,92 | **1,43** | 46,6 | **33,7** |
| ferme_composition | 2,13 | **0,84** | 3,03 | **1,52** | 40,8 | **35,0** |
| ferme_facade | 1,95 | **1,29** | 4,83 | 6,49 | 39,7 | 43,7 |
| ferme_laterale | 6,66 | **3,15** | 11,91 | 12,00 | 57,4 | **56,1** |
| ferme_arriere | 1,66 | 2,06 | 6,89 | **4,03** | 48,0 | **34,4** |
| ferme_seuil | 2,92 | 7,32 | 23,74 | 35,46 | 55,0 | 65,7 |

## Verdict : PARTIAL

* **max ≤ 8 % : PASS sur les six vues** (pire cas 7,32 sur `ferme_seuil`).
* **total ≤ 12 % : PASS sur cinq vues, FAIL sur `ferme_seuil`** (35,46 contre
  un portail à 12, et contre 23,74 avant — c'est une régression, pas un
  simple dépassement).
* `ferme_laterale` passe de 11,91 à 12,00 : au portail à 0,09 point près.

## Pourquoi `ferme_seuil` empire, sans détour

Les onze pièces de maçonnerie ajoutées n'ont **pas d'UV0** — le générateur
produit de la géométrie nue, et `gltf_inspect` le signale à chaque export.
Elles rendent donc en couleur unie. Sur une vue prise à deux mètres du
seuil, où 68 % de l'image est déjà du bâti, remplacer un grand quad de
plâtre par des tableaux, des poteaux et des solives **augmente** la surface
sans gradient même si la lecture de l'espace, elle, s'améliore : la boîte
vide devient une pièce charpentée.

L'outil mesure la platitude du RENDU, pas la richesse du volume. Sur les
cinq autres vues les deux vont dans le même sens ; sur celle-ci elles
divergent, et il faut le dire plutôt que de choisir la mesure qui arrange.

**Dette nommée** : déplier les UV des pièces `SM_Farm_*` et leur donner la
texture de pierre du kit. C'est le seul geste qui ferait tomber
`ferme_seuil`, et il n'était pas dans le périmètre arbitré.
