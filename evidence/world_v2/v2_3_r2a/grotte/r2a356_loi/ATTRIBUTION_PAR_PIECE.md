# Les 68 auto-intersections viennent de l'ENVELOPPE, pas de la cavité

**Résultat de l'agent B, R2a-3.5.6.** Il réfute trois hypothèses successives,
dont deux qui étaient les miennes et une qui était la voie proposée par la
directive.

## Ce qui est réfuté, et par quelle mesure

| hypothèse | test | verdict |
|---|---|---|
| le coude de 42° | distribution par station | **réfutée** — 2 paires sur 62 |
| le **cisaillement** entre sections (la mienne) | corrélation vrillage ↔ pénétrations | **réfutée, et anti-corrélée** |
| **rallonger le segment sortant** (la directive) | ablation V4 | **réfutée, et contre-productive : 68 → 82** |
| porche évasé, porche abaissé | ablations V1–V3 | **réfutées** — 70, 68, 70 |

Le cisaillement trie **à l'envers** : la station au vrillage maximal
(`hw/R = 0,931`) porte **zéro** pénétration ; celles à 0,058 en portent 21. Ce
n'est pas « non corrélé », c'est l'inverse de la prédiction.

## La cause : le découpage par station confondait TROIS pièces

`construire()` bâtit trois pièces dans une seule coque — **peau de cavité**,
**peau d'enveloppe** (loft `MASSIF`), **rondelle de rive**. Attribuer par station
les mélangeait, et c'est pourquoi la station 0 restait rivée à 26 dans toutes les
ablations du tube : on y comptait de l'enveloppe.

| variante | total | `cav×cav` | `cav×env` | `env×env` |
|---|---:|---:|---:|---:|
| **V0 candidat** | **68** | **0** | **28** | **40** |
| V4 segment rallongé | 82 | 14 | 28 | 40 |
| V7 asymétrie de R2a-3.4 | 40 | 0 | **0** | 40 |
| V10 les trois tables R2a-3.4 | 29 | 22 | 0 | **7** |

Deux invariants portent tout :

1. **`env×env` vaut 40** dans toute variante gardant le `MASSIF` du candidat, et
   tombe à **7** dès qu'on restaure celui de R2a-3.4 — exactement le compte du
   GLB livré.
2. **`cav×cav` vaut 0** chez le candidat. **La peau de cavité — celle que le
   tracé, le porche et le parcours joueur décident — est saine.**

Décomposition des 68 : **40** de la table `MASSIF`, **28** de `CAVITE_ASYM` dont
le ratio est passé de 1,7 à **6,8** sur les stations 4-8, **0** de la cavité.

## Attribution d'étape, prouvée et non déduite

Empreinte **`3a15d9b49eb5d60d` inchangée** après `joindre`, `remailler_voxel`,
`retirer_bulles` ×2, `stratifier`, `decimer`, `soustraire` — **sept étapes, une
seule empreinte**. Les défauts naissent **intégralement à `construire()`**.

## Ce que ça implique

La consigne que j'avais donnée — repère à rotation minimale restreint au loft —
**ne s'applique plus** : elle corrigerait la peau de cavité, déjà à zéro. Elle ne
toucherait aucune des 68.

Et le constat se range avec les deux autres de cette série : **l'enveloppe
R2a-3.5.2 est, dans ses propres tables, géométriquement moins saine que celle
qu'elle remplace.** Troisième mesure indépendante allant dans ce sens, après la
lèvre mince et les pénétrations de collision.

## `NON VÉRIFIÉ`, et celui-là inquiète

> **V10 laisse 22 `cav×cav` : la table de R2a-3.4 replaquée sur le code courant
> produit des replis qu'elle ne produisait pas à l'époque. Autre chose que les
> tables a changé entre-temps, non identifié.**

Sans effet sur la conclusion, mais réel — et il dit qu'une régression de chaîne
existe quelque part entre R2a-3.4 et aujourd'hui, en dehors des tables.

Autre limite déclarée : le verdict porte sur la **triangulation interne** — 68
ici contre 62 sur le GLB. Faible sur la collision (quads convexes), non nul.

## Ce qui n'est PAS fait

**Rien n'est réparé.** `MASSIF` et `CAVITE_ASYM` décident l'enveloppe extérieure
et la forme de la bouche, donc la silhouette gelée. Une **courbe de coût** est en
cours : pour chaque table, le changement minimal qui annule sa contribution, avec
le coût en composition et le verdict de `controle_amas` à chaque pas. L'arbitrage
revient au lead.
