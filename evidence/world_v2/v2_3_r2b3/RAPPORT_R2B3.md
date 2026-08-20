# R2B.3 — rapport de clôture du lead

**Type : VIVANT** jusqu'au verdict visuel Codex/Istvan, **HISTORIQUE** ensuite.

Base `1491ee4` → reprise à `291a621` après **deux recréations de conteneur**.
Rendu **logiciel** (llvmpipe) : régression visuelle seulement, jamais une mesure
de performance.

---

## 1. Verdict

> **La forme est gagnée, mesurée deux fois et éprouvée trois fois. La fuite ne
> l'est pas.**

**`PARTIAL`, sur une cause mesurée et nommée : le `+100` de `DummyMaterial`
d'ISS-059 reste NON EXPLIQUÉ.** Le domaine est fortement réduit, la fuite qui a
été trouvée est réelle et corrigée — mais ce n'est pas celle du ticket, et le
ticket ne se ferme pas sans causalité.

Le verdict d'un gate est le plus faible de ses critères, jamais leur moyenne.

---

## 2. Les débris — ce qui est acquis

| grandeur | avant | après |
|---|---:|---:|
| liant de boîtitude (plafond 25 %) | 96,8 % | **0,00 %** |
| indice de rectangularité (plafond 51) | 71,42 % | **0,32 %** |
| part orthogonale (plafond 52) | — | **14,97 %** |
| triangles par tas (plafond 600) | 124 | 198 |
| ferme entière (plafond 4 500) | 2 076 | 2 224 |
| UV0 | 27/27 | **27/27** |
| `gltf_inspect` | VALIDE | **VALIDE, 0 avertissement** |

`0,00 %` est **la valeur des tas de gravats acceptés du kit**, pas 24,9.

Le geste est **structurel, pas un réglage** : `eclat()` construit `k + k + 1`
sommets avec `k` borné à [3 ; 7], donc **toujours impair, jamais huit**. Relevé
sur le maillage livré : sommets `[4,9,9,9,9,11,11,11,11,13,13,13]`, plans
`[4,11,13,13,14,16,17,17,17,21,22,22]` — zéro composante à 8 sommets, zéro à
6 plans. `hexa` et `pave6` sont l'un comme l'autre **impossibles**.

Non-contamination : les 12 autres meshes ont triangles, emprise **et** min
POSITION identiques, vérifié au sha256 du flux de positions trié.

---

## 3. Ce que les débris dessinent RÉELLEMENT — et pourquoi ça compte

Plancher A/A — même scène, même processus, même état, deux rendus :
**0 pixel changé sur les onze vues, aux seuils 1, 8 et 32.** Bit-à-bit
identiques. Le plancher n'est pas petit : il est **nul**, et c'est lui qui rend
le reste interprétable.

| vue | part dessinée par les deux tas |
|---|---:|
| `debris_a_proche` | 3,71 % |
| `debris_b_proche` | 2,59 % |
| `debris_plongee` | 1,82 % |
| `ferme_orb090` | **0,41 %** |
| `ferme_laterale` | 0,37 % |
| `ferme_facade` | 0,18 % |
| `ferme_orb000` · `ferme_orb180` | **0,02 %** |
| `ferme_seuil` · `ferme_arriere` · `ferme_orb270` | **0,00 %** |

**Ce chiffre est le résultat le plus important de la passe pour la revue.**
À distance d'orbite, les deux tas dessinent entre 0,02 % et 0,41 % de l'image ;
sur trois vues imposées, **exactement rien**. Corriger `Debris_A/B` ne change
donc presque pas l'image à distance normale.

Ma lecture des montages le disait déjà : ce qui domine le cadre, c'est l'anneau
bas de maçonnerie — `Rubble_Wall`, `WallStub_East`, le socle — **qui n'est pas
dans le périmètre de la corrective**. Si la « bordure construite » du verdict
R2B.2 venait en partie de lui, elle est toujours là. **Question portée à la
revue, pas conclusion** : seul l'œil qui a rendu le verdict sait ce qu'il
regardait.

Trois campagnes précédentes ont produit des chiffres crédibles et **faux**
(0,57–5,45 %, 0,90–6,44 %, 0,84–4,94 %) : elles mesuraient le **vent**. Détail
en §6.

---

## 4. ISS-062 — deux trous trouvés, deux trous fermés, le ticket reste ouvert

**Trou 1, la soudure.** `hexa` et `pave6` raisonnent par composante connexe :
18 pavés soudés par un coin rendent **0,00 %** et franchissent les neuf
planchers. Fermé par un **second instrument d'une autre famille** —
`mesure_rectangularite.py`, qui juge plaques planes et angles dièdres et est
donc **invariant à la soudure**. Deux instruments de familles différentes valent
mieux qu'un instrument durci : le second n'hérite pas de la faille du premier.

**Trou 2, le bruit cohérent — trouvé par l'audit adverse.** Déplacer chaque
position de **2 mm** garde les coins soudés, casse la planéité, effondre `RECT`
à 38,80 %, et `min(RECT, ortho)` la retient. **Les dix contrôles rendaient vert
sur une géométrie qui n'est que des boîtes.** 2 mm sur des arêtes de 189 mm :
1,06 %, invisible. La marge valait **un millimètre**.

Fermé par un **second plafond, indépendant, sur `part_orthogonale` seule** :
un `min` protège contre le cas où une seule grandeur suffirait à ABSOUDRE, pas
contre le cas où une seule suffit à ACCUSER. Seuil dérivé par la **même règle
pré-enregistrée** — M = 4,80 → plafond 52.

Cycle rejoué par moi : sujet `RC=0` · contre-exemple `RC=1` **avec un seul
écart** · restauration `RC=0`, sha256 à l'octet près, `git status assets/` vide.

**Le ticket reste OUVERT** : rien ne dit qu'il n'existe pas un troisième
contournement, et aucun des deux instruments ne juge si un tas est beau.

---

## 5. ISS-063 — démontré, corrigé, et les suites rejouées

`user://` ne dérive **pas** du répertoire de travail : tous les arbres en
partageaient un seul. Deux runners y ont **fabriqué un échec impossible**.
Correctif : `XDG_DATA_HOME` par invocation, dans `tools/lancer_godot.sh`, qui
prend aussi le verrou du dépôt par `--git-common-dir` et **refuse `--filtre=`**.

Un verrou sérialise dans le temps ; une cloison sépare dans l'espace. Il fallait
les deux.

| lot, rejoué SEUL et ISOLÉ | verdict contaminé | rejeu | conclusion |
|---|---|---|---|
| `world_v2` | 96/1, RC=1 | **99/0, RC=0** | **contamination prouvée** |
| `boss_arena` | échec annoncé sans journal | **11/0, RC=0** | ne se reproduit pas |
| `boot_smoke` | — | **1 test, 23 assertions, RC=0** | — |
| golden masters | — | **6/6 avant et après** | — |

Contrôles anti-piège sur chaque journal : ligne `filtre:` présente, 31 fichiers
et non 193, **une seule** ligne `=== RÉSULTAT`, aucun journal vide sur RC non nul.

---

## 6. ISS-059 — domaine fortement réduit, cause NON atteinte

**Éliminé, avec la mesure qui l'élimine :**

| éliminé | mesure |
|---|---|
| le montage de la vallée comme multiplicateur | **130 montages, 177 tests, 1 483 s → 0 ligne** |
| la dose par montage, le cache saturant, tout seuil sous 130 montages | A1/A2/A3 |
| les 70 premières scènes du projet | C3 : 0 / 0 / 0 |
| les 8 lieux POI comme contributeurs propres | C6 ≈ C5 |
| les 47 GLB comme source du résidu | B1 = témoin, B3 = B2 |
| **« les matériaux fuités sont des sous-ressources de scène »** | rapport matériaux/maillages **115,5 contre 1,31** |

**Établi :** le résidu constant `≈ 240 ObjectDB / 239 resources` est fait de
`GDScript` + `GDScriptNativeClass` épinglés par le chargement des `.tscn` —
**des scripts, pas des matériaux**. Et une signature à matériaux se reproduit en
97 s, localisée à trois scènes ; mais son **profil diffère** de celui de la
suite, donc ce n'est pas la même fuite.

**Réduction la plus utile** : les 4 849 matériaux de la suite ne sont pas des
sous-ressources de scènes épinglées — ce sont des matériaux **créés à
l'exécution**, dont le porteur ne crée pas de maillage.

**Une vraie fuite cumulative a été trouvée et corrigée** au passage :
`WorldV2PlaceKit.scene_for()` chargeait sans retenir. Monde
**334 / 536 / 738 par cycle → 334 / 334 / 334**. Vingt cycles, +27 sur chacun
des dix-neuf intervalles. **Mais 561 matériaux retenus produisent zéro ligne de
fuite** : ce n'est pas la signature du ticket.

**ISS-059 reste OUVERT. C'est la cause mesurée du `PARTIAL`.**

---

## 7. Ce que je ne peux pas dire

**Si c'est beau.** Aucun agent n'a vu le tas — pas de GPU. Ma propre lecture des
onze montages est dans `preuves_lead/LECTURE_VISUELLE_LEAD.md`, avec ce qui me
gêne : le tas passe à **47 % de pierre** (il lisait « bois et tuile »), ce qui le
rapproche justement de l'anneau voisin ; et l'emprise gagne ~5 %.

Le liant est **nécessaire, pas suffisant**. Deux instruments rendent la
régression difficile ; ils ne remplacent pas un œil. **ISS-060 ne se ferme que
par le vôtre.**
