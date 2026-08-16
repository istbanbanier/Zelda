# Régression florale V2.2 — corrigée, et prouvée inerte ailleurs

Worktree `/home/user/zelda-r2a34/flore` · Godot 4.7.1-stable
(`custom_build.a13da4feb`) · headless, renderer muet.

- Rouge archivé à `59e0adb700ae4790cd93fc2444702a829bf05857` : `JOURNAL_ROUGE.md`
- Contrôle + témoin épinglés : commit `a3179c4`
- Correction : commit *(reporté ci-dessous après validation)*

Journaux bruts : `journal_rouge_59e0adb.log`, `journal_vert_passage1.log`,
`journal_vert_passage2.log`, `controle_negatif_temoin.log`.

## Verdict

| passage | commande | résultat |
|---|---|---|
| rouge, avant correction | `--filter=flora_scale` | **1 réussi, 1 échoué** — la régression |
| vert 1 | `--filter=world_v2,flora,kit_scale` | **58 réussis, 0 échoué** |
| vert 2 | `--filter=world_v2,flora,kit_scale` | **58 réussis, 0 échoué** |
| contrôle négatif | `--filter=flora_scale`, un littéral perturbé de 0,001 | **rouge attendu, obtenu** |

Deux passages, comme l'exige ISS-038 : un passage vert ne prouve pas qu'un
test est sain. Un seul résumé `=== RÉSULTAT` par journal, zéro erreur de
script — les deux garde-fous de `tools/CLAUDE.md` contre les suites
concurrentes.

Commande exacte, verrou compris :

```bash
flock /home/user/Zelda/.git/heavy_tools.lock -c \
  'cd /home/user/zelda-r2a34/flore && /usr/local/bin/godot --headless --path . \
   --script tools/godot/test_runner.gd -- --filter=world_v2,flora,kit_scale \
   > /tmp/vert1.log 2>&1'; echo "RC=$?"
```

---

## Le changement, en trois lignes de code

`scripts/world_v2/world_v2_vegetation_builder.gd`, `_build_cell` §3 :

```diff
-					_ground_transform(p, rng, 0.8, 1.15, -0.03))
+					_ground_transform(p, rng, FLOWER_VARIATION_MIN * kit,
+						FLOWER_VARIATION_MAX * kit, -0.03))
```

avec `var kit: float = KitScale.factor(String(flower_model))` et deux
constantes `FLOWER_VARIATION_MIN = 0.69`, `FLOWER_VARIATION_MAX = 0.99`.

Tout le reste du diff est du commentaire. Aucun autre fichier de code n'est
touché.

## Avant / après, mesuré

| variante | natif | avant | après | bible §3 |
|---|---:|---:|---:|---:|
| `Flower_4_Group` | 2,4868 m | 1,989 – **2,860 m** | 0,380 – **0,545 m** | 0,18 – 0,55 |
| `Flower_3_Group` | 2,0548 m | 1,644 – **2,363 m** | 0,359 – **0,515 m** | 0,18 – 0,55 |

La plus haute fleur réellement plantée passait de **2,841 m** (cellule
`c2r8`) à une valeur bornée par 0,545 m. Le test mesure chacune des 1 194
fleurs, pas un échantillon.

## Pourquoi la bande passe de (0,80 ; 1,15) à (0,69 ; 0,99)

Trois raisons, toutes arithmétiques.

1. **`KitScale` seul ne suffisait pas.** Il ramène la cible à 0,55 m, mais
   0,55 × 1,15 = **0,632 m** — encore au-dessus du plafond. La seule autre
   issue aurait été de déclarer un plafond de 0,632 m, c'est-à-dire
   d'inventer un contrat pour l'ajuster au code.
2. **Le rapport min/max est conservé.** L'original vaut 0,80/1,15 = 0,6957 ;
   le retenu vaut 0,69/0,99 = 0,6970 — **0,19 % d'écart**. On corrige donc
   l'échelle sans toucher à l'amplitude relative des tailles : la variation
   voulue entre deux touffes reste celle d'avant.
3. **Le haut de bande s'arrête à 0,99.** Une hauteur corrigée est un produit
   de flottants (natif × cible/natif × variation) : à 1,00 exact elle
   retombe sur 0,5499999 ou 0,5500001 selon l'arrondi, et une assertion
   `≤ 0,55` deviendrait intermittente. Le test porte en plus 1 mm de
   tolérance de bord — ceinture et bretelles sur une borne flottante.

## Le témoin d'invariance : ce qui n'a PAS bougé

`test_les_elements_non_floraux_sont_inchanges` compare le monde corrigé aux
littéraux mesurés avant correction. **Vert** : les cinq catégories non
florales sont identiques au millième près, et les fleurs n'ont ni bougé, ni
été ajoutées, ni supprimées.

| catégorie | instances | somme X | somme Y | somme Z | somme échelles |
|---|---:|---:|---:|---:|---:|
| `grass` | 12 570 | 20 004,2914 | 128 604,1517 | 816 381,5592 | 13 513,6401 |
| `tall` | 1 985 | −87,4601 | 40 697,9946 | 334 611,8255 | 2 128,5345 |
| `reeds` | 7 | −588,1430 | 13,4484 | 135,7969 | 7,5395 |
| `tree` | 197 | 14 889,9664 | 1 900,7008 | 9 588,2803 | 218,0460 |
| `rock` | 698 | 1 788,8191 | 9 815,9115 | −6 175,0403 | 800,5724 |
| `flowers` | 1 194 | −22 648,5969 | 13 960,9344 | 130 360,7182 | *non épinglée* |

Sensibilité du témoin : une seule instance déplacée d'un millimètre décale
une somme de 0,001, soit **le double** du seuil de détection (0,0005), et
**vingt fois** le bruit d'arrondi des littéraux (0,00005). Il ne peut donc
ni clignoter, ni absoudre.

**Pourquoi c'était acquis d'avance, et pourquoi on le prouve quand même.**
Multiplier les *bornes* de `randf_range` plutôt que le résultat consomme
exactement un tirage, comme avant : la séquence de la graine de cellule est
intacte. C'est un raisonnement — le témoin en est la mesure.

La seule grandeur qui a bougé est celle qui devait bouger : la somme des
échelles florales passe de **1 162,5143 à 225,4038** pour les mêmes 1 194
fleurs.

## Le témoin peut-il seulement rougir ?

Un témoin qui ne rougit jamais ne prouve rien — c'est le mode de panne
d'ISS-018, où tous les tests étaient verts pendant que les créatures
s'affichaient en pièces détachées.

Contrôle négatif exécuté : la somme X des roseaux, épinglée à −588,1430, a
été perturbée à −588,1440 — soit **exactement 0,001**, l'équivalent d'un
seul roseau déplacé d'un millimètre parmi 15 457 instances végétales. Le
test échoue et nomme la faute :

```
ÉCHEC test_les_elements_non_floraux_sont_inchanges
  dérives : reeds / somme X : attendu -588.144, obtenu -588.143
```

La sensibilité annoncée est donc mesurée, pas supposée. Journal :
`controle_negatif_temoin.log`. La perturbation a été retirée ensuite ; le
fichier committé est celui des passages verts, au commentaire près.

## Ce qui n'a délibérément PAS été corrigé

Les arbres et les rochers du même bâtisseur continuent d'être posés sans
consulter `KitScale`. Ce serait inerte aujourd'hui : aucun de leurs modèles
(`CommonTree_*`, `Pine_*`, `TwistedTree_*`, `DeadTree_*`, `Rock_Medium_*`,
`Pebble_*`) ne figure dans `KitScale.MEASURED`, le facteur vaudrait
exactement 1,0. Mais ce serait un changement de comportement **latent** dans
un système gelé : le jour où quelqu'un ajouterait un arbre à la table, toute
la végétation V2.2 se redimensionnerait sans que personne l'ait demandé.
Périmètre limité à ce dont le dépassement est prouvé.

## Ce que ce document ne prouve pas

- **Que la bouche de la grotte est dégagée à l'écran.** Aucune capture ici.
  Statut : `NON VÉRIFIÉ` — cela relève de la vérification visuelle du lead.
- **Aucune mesure de performance.** Le rendu est muet.
- **Aucun jugement artistique.** Le test mesure une hauteur contre un
  littéral de la bible ; il ne dit rien de la beauté du résultat.
