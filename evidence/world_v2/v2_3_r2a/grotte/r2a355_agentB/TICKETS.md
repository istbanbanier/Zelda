# Trois tickets ouverts par R2a-3.5.5 — Agent B

Chiffrés, non corrigés, avec ce qui est su de la cause — et ce qui ne l'est
pas est marqué `NON VÉRIFIÉ`.

**Aucun des trois n'a été fabriqué par cette passe.** B1 et B2 préexistent au
socle `f39b232` ; B2 est une régression réelle mais **héritée de R2a-3.5.2**,
identique avant et après la calotte nord, donc hors du périmètre de l'agent
A. B3 est un angle mort de l'instrument que cette passe vient de réparer :
il est apparu parce qu'on s'est mis à regarder.

---

## TICKET-B1 — La décimation fabrique des auto-intersections dans le visuel

**Sévérité proposée : S3.** Défaut visible potentiel, sous le seuil de
profondeur, sans effet mesuré sur la fermeture ni sur le CSG.

### Mesure

| géométrie | pénétrations | enfoncement max | couture max | seuil |
|---|---:|---:|---:|---:|
| `c184c8dc` (candidat) | **6** | **0,000612 m** | **0,570 m** | 0,020 m |
| `R2a34_8bf1a1b3` (**livrée et validée**) | **10** | **0,000000 m** | **0,125 m** | 0,020 m |

**Toutes les pénétrations du visuel sont sous le seuil de profondeur**, des
deux côtés — 0,61 mm au pire, soit 33 fois moins que `REPLI_LIVRABLE_MAX_M`.
Le contrôle réparé reste donc **vert**, mais il le dit honnêtement au lieu de
publier 0.

### ATTENTION — « le candidat est meilleur » est à nuancer

C'est vrai sur le **compte**, faux sur les deux autres grandeurs :

| grandeur | meilleur | écart |
|---|---|---|
| nombre de paires | **candidat** | 6 contre 10 |
| enfoncement maximal | **R2a-3.4** | 0 µm contre 612 µm |
| étendue de couture | **R2a-3.4** | 0,125 m contre 0,570 m |

Les 10 pénétrations de R2a-3.4 ont un enfoncement **inférieur au demi-micron**
— elles sont à la limite du contact tangent. Celles du candidat sont mille
fois plus profondes et leurs coutures 4,5 fois plus longues. Un arbitrage qui
ne retiendrait que « 6 contre 10 » se tromperait de sens.

L'enfoncement maximal exact, 0,000612 m, coïncide **au chiffre près** avec
celui que publiait l'ancien compteur. L'ancien trouvait donc la bonne
profondeur pour la paire la plus profonde, et **ratait les quatre autres**.

### Cause, mesurée

Attribution rejouée sur le socle `f39b232`
(`B2_attribution/01_chaine_instrumentee.log`) :

| étape | tris | pénétrations |
|---|---:|---:|
| `joindre` | 30 396 | 187 dans l'amas B |
| `remailler_voxel` | 135 624 | **0** |
| `retirer_bulles` #1 | 135 624 | 0 |
| `stratifier` | 135 624 | 0 |
| **`decimer`** | 19 000 | **4** |
| `soustraire` | 20 072 | +2 (second amas) |

Le remaillage voxel efface les 187 pénétrations de l'union brute. La
décimation en recrée 4, toutes dans le même amas. Le facteur commun est la
face `12973` du GLB : un triangle de **plus de 2 m d'arête**, quasi-plan,
qui traverse le relief fin voisin — signature d'un `DECIMATE COLLAPSE`
trop agressif sur une zone de détail.

### Pourquoi ce n'est pas corrigé dans cette passe

Toucher la décimation rebat **tout** le maillage : nouvelle empreinte de
bout en bout, ratios et composition à revalider intégralement, et collision
directe avec l'agent A, qui modifie la calotte dans la même union. Le
candidat étant déjà meilleur que la référence livrée (6 contre 10), la
réparation mérite sa propre passe et sa propre revue.

### Piste, non testée

Décimer en deux temps, ou plafonner la longueur d'arête produite par le
collapse dans les zones de forte courbure. **`NON VÉRIFIÉ`** : aucune de ces
deux options n'a été essayée.

---

## TICKET-B2 — `COL_WaterfallCave` porte 62 auto-intersections profondes, et rien ne la regarde

**Sévérité proposée : S2.** Enfoncement 23 fois le seuil du livrable, sur la
géométrie qui décide des collisions du joueur.

### Mesure

| géométrie | pénétrations | enfoncement max | couture max |
|---|---:|---:|---:|
| `c184c8dc` (candidat) | **62** | **0,457261 m** | 0,944 m |
| `R2a34_8bf1a1b3` (livrée) | **7** | **0,020325 m** | 0,915 m |

Le candidat est donc **nettement pire** que la référence livrée sur ce
maillage-ci : 62 contre 7, et 0,457 m d'enfoncement contre 0,020 m. C'est
une **régression réelle**, à l'inverse du ticket précédent.

Topologie par ailleurs saine dans les deux cas : 0 bord libre, 0
non-manifold, 1 composante, **genre 0**.

### Attribution — la régression est HÉRITÉE, la calotte nord est hors de cause

| géométrie | paires | enfoncement max | couture max |
|---|---:|---:|---:|
| `cc3596c5` (R2a-3.5.2 nue, **avant** calotte) | **62** | **0,457261 m** | 0,944 m |
| `c184c8dc` (candidat, **avec** calotte) | **62** | **0,457261 m** | 0,944 m |
| `R2a34_8bf1a1b3` (livrée) | 7 | 0,020325 m | 0,915 m |

Les distributions par station de `cc3596c5` et `c184c8dc` sont **identiques
ligne pour ligne**. La régression est **entièrement héritée de R2a-3.5.2** :
ni cette passe ni la calotte nord de l'agent A ne l'ont fabriquée. Le ticket
porte sur l'enveloppe, pas sur le périmètre de A.

**Le constat qui compte plus que le chiffre :** ces 62 pénétrations étaient
déjà là quand R2a-3.5.4 a déclaré la percée fermée et le portail conforme.
Personne ne les a vues parce que **personne ne regardait cette coque**.

### Cause — l'hypothèse du coude est RÉFUTÉE par la mesure

Hypothèse testée : le coude de 42° à la station 3 (`ay = 1,62`) replierait
les sections du loft à l'intérieur du virage. **Faux.**

| station | `ay` | paires | enfoncement max |
|---|---:|---:|---:|
| 0 — porche évasé | −1,15 | **24** | **0,457 m** |
| 1 — seuil | 0,00 | **8** | 0,319 m |
| 2 — vestibule | +1,05 | 0 | — |
| **3 — LE COUDE, 42°** | **+1,62** | **2** | 0,063 m |
| 4 | +2,12 | 0 | — |
| 5 — salle | +2,58 | 0 | — |
| 6 | +2,88 | **21** | 0,366 m |
| 7 — alcôve / niche | +3,06 | **7** | 0,371 m |
| 8 — calotte du fond | +3,17 | 0 | — |

**Le coude ne porte que 2 paires sur 62, soit 3 %.** Les pénétrations sont
aux **deux extrémités** du tube : 32 au porche (stations 0–1), 28 à l'alcôve
(stations 6–7). Les 7 de R2a-3.4 sont, elles, **toutes** à la station 8.

### Cause probable, non prouvée — `NON VÉRIFIÉ`

La signature est celle d'un loft qui **change de section trop vite**, pas
d'un loft qui vire. Entre les stations 6 et 8, `hw` passe de 2,50 à 1,30
(−48 %) et `cle` de 2,80 à 2,00 sur 0,48 m de progression en `ax`, suivi de
l'`APEX`. Le porche est symétriquement le lieu où la lèvre s'évase et plonge
sous le terrain.

Je n'ai remonté ni `construire()` ni les tables `CAVITE` de R2a-3.4 contre
R2a-3.5.2 : hors périmètre. `COL_MARGE_LAT` et `COL_MARGE_CLE` n'ont pas été
lues et ne doivent pas bouger.

### Ce qui est certain

`controle_repli()` — comme le `controle_penetration_exacte()` qui le
remplace — n'est appelé que sur `grotte`, le maillage **visuel**. La coque de
collision n'a **jamais** été soumise à un contrôle d'auto-intersection, par
personne. C'est pourquoi 62 pénétrations dont une de presque un demi-mètre
ont pu traverser toutes les passes sans être vues.

### Recommandation

Brancher `controle_penetration_exacte()` sur la coque de collision aussi. Le
faire **maintenant** rendrait le portail rouge immédiatement : c'est une
décision de gate, pas une décision de session.

---

## TICKET-B3 — Le contrôle exact mesure une triangulation qui n'est pas celle livrée

**Sévérité proposée : S3.** Le contrôle ne ment plus sur la nature du défaut,
mais il en sous-compte encore le nombre.

### Mesure

`controle_penetration_exacte()` publie **4** paires dans le journal de la
chaîne, là où le juge indépendant `tools/cave_exact_intersect.py` en trouve
**6** sur le GLB — la même géométrie, empreinte `5bd1b4f5115bfd35`.

Cause mesurée, `B7_controle_repare/02_triangulation_interne_vs_export.log` :

| | |
|---|---:|
| polygones du maillage Blender | 17 468, dont **2 481 à plus de 3 côtés** |
| triangulation interne `bmesh BEAUTY` | 20 072 triangles |
| triangulation de l'exportateur glTF | 20 072 triangles |
| triangles **identiques** des deux côtés | 17 893 |
| **présents seulement en interne** | **2 178** |
| **présents seulement à l'export** | **2 179** |

**10,9 % des triangles diffèrent.** Le contrôle mesure une soupe de triangles
qui n'est pas celle qui part dans le livrable.

### La phrase à ne pas omettre

> **Le « 4 » publié par le générateur est un MINORANT du « 6 » réel.**

Un lecteur qui verrait 4 sans cette phrase croirait le contrôle exhaustif. Il
ne l'est pas : il est exact sur ce qu'il regarde, et il ne regarde pas
exactement le livrable.

### Deux issues, aucune essayée — `NON VÉRIFIÉ`

1. **Trianguler la chaîne avant export**, pour que la triangulation mesurée
   soit celle livrée. Change le GLB, et `controle_plage_plane()` travaille sur
   les polygones — risque de régression sur la composition.
2. **Faire du juge indépendant une porte post-export**, dans
   `export_architecture.sh`. Ne touche pas la géométrie, mais s'applique aux
   cinq sujets dont trois golden masters gelés, qu'il ferait peut-être rougir.

Les deux touchent le livrable ou le script d'export : arbitrage, pas session.
