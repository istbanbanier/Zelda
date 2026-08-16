# Grotte du Couchant — forensic du seuil

Aucun verdict artistique dans ce document. Il établit **pourquoi** la caméra
montre du vert à travers la poche et un sol disloqué, par la mesure et non par
l'impression, et il nomme la cause en des termes qu'une correction ne peut pas
contourner.

Périmètre : `valley.poi.waterfall_cave.01`. Aucune géométrie de production n'a
été touchée. Les livrables sont une sonde, un filet et ce rapport.

| | |
|---|---|
| arbre mesuré | worktree `seuil`, détaché à `59e0adb` |
| asset mesuré | `assets/environment/caves/SM_WaterfallCave.glb`, committé |
| captures relues | `evidence/world_v2/v2_3_r2a/grotte/tranche3/` |
| outil | `tools/probe_cave_openings.py` — Python pur, ni Blender, ni Godot, ni GPU |
| filet | `tests/unit/test_grotte_sans_jour.gd` |
| sortie brute | `probe_cave_openings.json`, à côté de ce fichier |

---

## 1. Verdict

### Suite filtrée — exécutée, et rouge au bon endroit

```bash
flock /home/user/Zelda/.git/heavy_tools.lock -c '
  godot --headless --path . --import > /tmp/import_seuil.log 2>&1
  godot --headless --path . --script tools/godot/test_runner.gd -- \
      --filter=world_v2,grotte,cave > /tmp/rouge.log 2>&1'
```

`IMPORT_RC=0` · `RUNNER_RC=1` · `=== RÉSULTAT: 63 réussi(s), 6 échoué(s) ===`
· 417 assertions · **un seul** en-tête `Godot Engine v4` et **une seule** ligne
de résultat, donc aucune suite concurrente (`tools/CLAUDE.md`).

Les six échecs sont **tous** dans `test_grotte_sans_jour.gd` — trois sur le
plancher, trois sur le fond. Aucun ailleurs ; les huit tests préexistants de
`test_valley_caves.gd` restent verts. Journal complet : `runner_grotte.log`.

Un détail qui vaut le rapport : `test_world_v2_places_behavior.gd::`
`test_la_grotte_a_un_seuil_et_un_interieur_praticables` est **vert**. Ce filet
marche du seuil à l'intérieur et exige 1,75 m de hauteur libre tous les
0,40 m — il ne regarde jamais **sous** ses pieds. L'angle mort du générateur
existe donc aussi dans la suite, et il y est resté vert sur une galerie sans
plancher.

### Verdict par contrôle de la sonde

| contrôle | verdict | ce qui est mesuré |
|---|---|---|
| plancher de la galerie | **FAIL** | 87 fautes sur 455 points ; le sol manque sur 6,5 m |
| jour (sphère entière) | **FAIL** | 761 percées sur 38 049 rayons ; le fond est ouvert sur 1,50 × 1,25 m |
| ligne de vue (règle du moteur) | **PARTIAL** | 1 pixel perçant dans `t3_03`, dans une zone verte mesurée ; transformation monde→modèle `NON VÉRIFIÉ` (voir §6) |
| cohérence coque / collision | `PASS` | `COL_WaterfallCave` reste un maillage distinct, jamais rendu |

---

## 2. Deux défauts, pas un — et la phrase de correction

### 2.1 Le plancher est absent sur 6,5 m

> **Le plancher de la galerie est absent de `y = −0,29` à `y = +6,25` en repère
> modèle Blender, soit les stations 1 à 5. Sur ces 6,5 mètres, ce que la caméra
> montre comme sol est le sommet de l'assise enterrée, à `z ≈ −0,43`, c'est-à-dire
> 0,38 à 0,53 m sous le profil de cavité.**

Profil relevé sur l'axe, à comparer au profil que `anneau_interieur()` construit :

| station | y | profil attendu | mesuré | |
|---:|---:|---:|---:|---|
| 0 | −1,15 | −0,660 | **−0,655** | conforme |
| 1 | 0,00 | −0,080 | **−0,452** | trop bas de 0,37 m |
| 2 | +1,60 | −0,040 | **−0,416** | trop bas de 0,38 m |
| 3 | +3,20 | +0,020 | **−0,416** | trop bas de 0,44 m |
| 4 | +4,75 | +0,080 | **−0,451** | trop bas de 0,53 m |
| 5 | +6,25 | +0,180 | **+0,185** | conforme |
| 6 | +7,60 | +0,420 | **+0,425** | conforme |
| 7 | +8,65 | +0,700 | **+0,704** | conforme |
| 8 | +9,25 | +0,840 | **+0,842** | conforme |

La valeur mesurée est **constante** aux stations 1 à 4, à ±0,04 m près. Un sol
qui devrait monter par paliers et qui reste plat à une cote unique n'est pas un
sol déformé : c'est **un autre objet**. Cette cote est celle du sommet de
l'assise enterrée (`ASSISE["z1"] = −0,55`, remontée par le remaillage et la
stratification).

Conséquence directe sur l'image : le terrain gelé est à `z = −0,50` en repère
modèle. L'assise culmine 0,06 m au-dessus. Les touffes d'herbe gelées, hautes
d'environ 0,30 m, montent donc à `z ≈ −0,20` — **0,24 m au-dessus de la surface
que le joueur prend pour le sol**. C'est exactement ce que montrent
`t3_04_seuil_cadre.png` en `x[597..643] y[413..434]` et
`t3_03_gros_plan_seuil.png` en `x[553..700] y[563..622]` : des brins qui
sortent d'une fente à arêtes droites, et plus clairs que l'herbe du dehors
parce que l'omni `JourDuSeuil` les prend à 2,6 m.

### 2.2 Le fond de la galerie est percé

> **Le fond de la galerie est ouvert sur environ 1,50 × 1,25 m, d'emprise
> `x ∈ [+0,97 ; +2,47]` et `z ∈ [+1,02 ; +2,27]`, derrière la dernière station.
> Un rayon parti de la salle vers le fond, à hauteur de tête, ressort de la
> formation sans rencontrer un seul triangle.**

Mesure directe, rayon horizontal depuis la salle (station 5) vers le fond :

| x de départ | impacts |
|---:|---|
| +0,25 | 2, aux `y = 9,69` et `9,78` |
| +0,65 | 2, aux `y = 9,87` et `10,04` |
| **+1,05** | **0** |
| **+1,45** | **0** |
| **+1,85** | **0** |

Et derrière la calotte (station 8 → apex), rayon vers `+Y` :

| x | roche traversée |
|---:|---|
| +1,85 | **aucune** |
| +2,35 | **aucune** |
| +2,85 | 0,48 m |
| +3,35 | **aucune** |
| +3,85 | **aucune** |

C'est la seconde signature verte : les masses foliaires à mi-hauteur, profondes
dans la galerie, mesurées en `t3_04` `x[550..675] y[287..320]` et en `t3_03`
`x[542..640] y[333..381]`, `x[643..691] y[375..410]`, `x[721..821] y[365..403]`.
Leur ton, `(57, 86, 72)`, est celui de l'herbe extérieure non éclairée —
`(53, 86, 67)` mesuré au premier plan de la même image. Ce n'est pas un effet
de lumière : c'est le dehors.

---

## 3. Pourquoi neuf contrôles verts n'ont rien vu

La cause n'est pas un oubli isolé, c'est une **circularité** entre deux
fonctions de `source_assets/blender/environment/make_waterfall_cave.py` :

* `controle_epaisseur()` exclut les rayons descendants —
  `if math.sin(theta) < -0.30: continue` — et le justifie ainsi :
  *« le plancher est garanti autrement : par `controle_aucun_jour` »* ;
* `controle_aucun_jour()` ne tire que `Vector((0.0, 0.0, 1.0))`, **vers le
  haut**.

Aucune fonction du fichier ne regarde le sol. Ce n'est pas une interprétation :
c'est le texte des deux fonctions.

Deux angles morts du même ordre expliquent le second défaut :

* `controle_epaisseur` saute `if i >= len(CAVITE) - 2` et `controle_aucun_jour`
  boucle sur `range(2, len(CAVITE) - 2)` : les stations **0, 1, 7 et 8** ne sont
  mesurées par aucun des deux — le porche, le seuil, et tout le fond ;
* `controle_epaisseur` tire `Vector((cos θ, 0, sin θ))`, donc dans le plan
  perpendiculaire à l'axe. **Aucun rayon ne pointe le long de la galerie**, ni
  vers la calotte du fond.

Le trou du fond est situé exactement dans les deux stations que personne ne
mesure. Trois mécanismes concourent, et chacun se lit dans les données :

1. `ASSISE["y1"] = 9.10` s'arrête **avant** la dernière station (`y = 9,25`) et
   l'apex (`y = 9,55`) : pas de pavé sous le fond ;
2. `rochers_gaine()` saute `if i == 0 or i >= len(CAVITE) - 1` : **la station 8
   ne reçoit aucune roche de gaine** ;
3. l'alcôve creuse et rien ne remblaie. `anneau_interieur()` élargit la cavité
   de `ALCOVE["ampl"] = 1.20` à l'azimut 180° sur les stations 5 à 7, tandis que
   son lobe compensateur `dos_alcove` vit dans `LOBES`, consommé par
   `anneau_exterieur()` — appelé uniquement par `construire()`, qui depuis le
   pivot R2a-3.3 ne fabrique plus que `COL_WaterfallCave`, jamais rendu.
   **Le creusement a survécu au pivot, le remblai non.** Et `rochers_gaine()`
   dimensionne depuis `hw + GAINE_MARGE_M` seul : il ne lit jamais `ALCOVE`.

---

## 4. Le chiffre que le générateur avait déjà imprimé

`TRANCHE3.md` publie `sol : -0,416 seuil`. Le site d'appel est
`("axe_seuil", 0.05, 1.60)`, c'est-à-dire l'axe de la galerie 1,60 m après la
bouche — la station 2.

La sonde y remesure **−0,416 m**, à trois décimales, par une implémentation
entièrement indépendante (Python pur contre BVH Blender). Le profil de cavité y
attend `PALIER[2] − SAG = −0,040`. **L'écart est de 0,376 m, et c'est le trou.**

Le générateur a donc imprimé la mesure du défaut le jour de la livraison. Elle
était illisible pour une seule raison : **la ligne imprime la valeur mesurée
sans la valeur attendue à côté**. Un `%.3f m (profil attendu %.3f m)` aurait
suffi à la faire crier.

**Correction de ma propre analyse.** J'avais signalé au lead « 0,38 m d'écart
non expliqué » entre ce journal et le commentaire du code
(`−0,035 → 0,145 → 0,942 → 1,148`). C'était une comparaison fautive : les deux
relevés portent sur des points différents, et il n'y avait pas de contradiction
entre eux. Le fait réel est plus simple et plus grave — le nombre publié est
lui-même la mesure du défaut.

---

## 5. Ce que la sonde fait, et comment elle peut me contredire

`tools/probe_cave_openings.py` mesure le GLB livré en Python pur. Trois
contrôles, **séparés à dessein** : un correctif qui épaissirait la gaine ferait
verdir les parois sans toucher au plancher, et un verdict global le masquerait.

Trois garde-fous ont été ajoutés *contre la sonde elle-même*, chacun après un
faux positif constaté :

* **les rayons qui sortent par la bouche sont écartés.** Un premier jet
  signalait 61 « percées » à la station 0 : c'était la porte d'entrée. 1 851
  rayons sont désormais écartés à ce titre ;
* **le porche est écarté du contrôle des jours.** Il est ouvert par
  construction ; le juger fabriquerait des défauts. Il reste jugé pour le
  plancher, et il y **passe** ;
* **un point d'échantillonnage doit être enclos** à plus de 50 % de la sphère
  pour compter comme « dans la cavité ». Un point tombé hors du rocher passerait
  le test du vide et produirait cent percées d'un coup. Sur cette exécution :
  **0 point écarté** — l'échantillonnage est sain, et le résultat ne doit rien à
  ce filtre.

**La sonde peut me contredire, et c'est démontré sur le maillage livré
lui-même.** Sur les 33 positions longitudinales sondées, **15 sont vertes** —
le porche, et toute la galerie de `y = +6,59` au fond — avec un écart maximal
de 0,19 m ; **18 sont rouges**, avec un écart allant jusqu'à 0,76 m. Un
contrôle vert sur une moitié d'un objet et rouge sur l'autre n'est pas câblé
sur l'échec : il mesure. Second essai indépendant : en rebouchant
artificiellement le fond dans une copie en mémoire, la carte du fond passe de
**24 cases ouvertes à 0**.

La sonde vérifie aussi, à chaque exécution, que ses cotes recopiées
(`CAVITE`, `PALIER`, `SAG`, `PORCHE_DENIVELE`) correspondent encore au
générateur, par lecture textuelle. Une divergence sort en **3 (BLOQUÉ)**, jamais
en 0.

---

## 6. Limites — ce que ce travail ne prouve pas

* **Le contrôle 3 ne peut pas voir le vert.** Il mesure le GLB seul ; le terrain
  et sa végétation n'y sont pas. Il ne détecte donc que les rayons qui quittent
  la formation, et il en trouve **un** pixel dans `t3_03`, en
  `x[600..603] y[344..347]` — à l'intérieur exact de la zone verte que j'avais
  mesurée en `x[542..640] y[333..381]`. C'est une confirmation croisée, pas un
  dénombrement. Le vert du plancher, lui, ne peut apparaître que dans le
  contrôle 1, où le rayon touche bien de la roche — mais la mauvaise, un
  demi-mètre trop bas.
* **La transformation monde → modèle du contrôle 3 est déduite, et sa
  vérification a ÉCHOUÉ.** Origine `(−106,0 ; 3,50 ; 3,5)`, lacet 45°, dérivée
  de `world_v2_layout.json` (`v2_site`), de `SEUIL_LOCAL`, de `EXHAUSSEMENT` et
  de l'absence de rotation dans `world_v2_places_builder.gd`. J'ai tenté de la
  valider en superposant la silhouette calculée à la capture, avec la luminance
  comme discriminant : **le test n'est pas concluant**, parce que le fond de ces
  captures est aussi sombre que la formation. Sur `t3_07_trois_masses` la
  concordance n'est que de 52,4 %, et décaler l'origine de +3 m l'améliore — ce
  qui disqualifie la mesure, pas seulement l'origine. Le contrôle 3 est donc
  `PARTIAL` : son unique pixel perçant tombe dans la bonne zone verte, ce qui
  corrobore, mais ne prouve pas. Statut de la transformation : `NON VÉRIFIÉ`.

  **Cela n'affaiblit en rien les contrôles 1 et 2**, qui sont l'essentiel de ce
  rapport : ils travaillent entièrement en repère modèle, sur le GLB seul, et
  n'utilisent aucune transformation de monde. La preuve du plancher absent et
  du fond percé ne dépend d'aucune caméra.
* **La cote du terrain gelé sous le site (3,00 m) est documentaire**, reprise des
  commentaires de `waterfall_cave_place.gd`. Elle n'a pas été relue par sonde
  dans cette passe.
* **Rien ici n'est une mesure de performance.** Aucun rendu n'a été fait.
* **Aucun verdict artistique.** La forme du rocher n'est pas jugée.
* **Je ne dis pas quelle correction appliquer.** Deux mécanismes sont
  compatibles avec le plancher absent — pas de roche source sous le profil, ou
  décimation (202 928 → 19 000, ratio 0,094) appliquée avant la soustraction. La
  sonde ne les départage pas et n'en a pas besoin : les deux se corrigent en
  garantissant de la matière sous le profil de cavité, et le contrôle 1 dira si
  c'est fait.

---

## 7. Un piège rencontré en chemin — l'erreur accuse le mauvais coupable

Un `git worktree add --detach` neuf n'a **aucun `.godot/`**. Le runner de tests
y échoue alors ainsi :

```
SCRIPT ERROR: Parse Error: Could not find type "GateTestCase" in the current scope.
          at: GDScript::reload (res://tools/godot/test_runner.gd:215)
```

Le message désigne `GateTestCase` et `tools/godot/test_runner.gd`. La cause
n'est ni l'un ni l'autre : c'est l'absence de
`.godot/global_script_class_cache.cfg`, qui n'existe qu'après
`godot --headless --path . --import`. Sans ce cache, **aucun `class_name` du
projet n'est résoluble**, et le premier fichier qui en cite un porte le blâme.
Le même symptôme frappe `--check-only --script` sur n'importe quel test.

`docs/COMMENT_TRAVAILLER_ENSEMBLE.md` prescrit un worktree séparé par tâche, et
`CLAUDE.md` liste bien la commande d'import — mais rien ne relie les deux. Une
session qui suit la consigne de worktree et lance directement le runner reçoit
une erreur qui l'envoie chercher un défaut dans les fichiers de test.
`tools/validate_fast.sh` fait l'import lui-même, ce qui masque le piège tant
qu'on passe par lui — et le masque précisément quand on l'a remplacé par le
runner filtré.

Ordre correct dans un worktree neuf, en un seul passage sous verrou :

```bash
flock /home/user/Zelda/.git/heavy_tools.lock -c '
  godot --headless --path . --import > /tmp/import.log 2>&1
  godot --headless --path . --script tools/godot/test_runner.gd -- --filter=... > /tmp/run.log 2>&1'
```

L'import produit environ 142 Mo de cache et prend plusieurs minutes ; il n'est
à faire qu'une fois par worktree.

---

## 8. Lignes de continuité

Aucun document de continuité n'a été modifié — arbitrage du coordinateur. Les
lignes à reporter, telles quelles :

**`docs/STATUS.md`**

```
| Grotte du Couchant — continuité intérieure | FAIL | plancher absent stations 1–5
  (6,5 m) et fond percé 1,50 × 1,25 m ; mesuré par tools/probe_cave_openings.py
  sur SM_WaterfallCave.glb à 59e0adb ; preuve evidence/world_v2/v2_3_r2a/grotte/
  seuil_forensic/ | filet tests/unit/test_grotte_sans_jour.gd |
```

**`docs/PROGRESS.md`**

```
Forensic du seuil de la Grotte du Couchant. Cause établie, correction NON faite
(délibérément : make_waterfall_cave.py est en cours de reprise par ailleurs).
Deux défauts distincts, mesurés : (1) plancher absent de y = -0,29 à y = +6,25,
le sol visible étant le sommet de l'assise enterrée à z ≈ -0,43 ; (2) fond de
galerie ouvert sur 1,50 × 1,25 m en x[+0,97..+2,47] z[+1,02..+2,27].
Cause racine : controle_epaisseur exclut les rayons descendants en invoquant
controle_aucun_jour, qui ne tire que vers le haut — rien n'a jamais regardé le
sol ; et les stations 0, 1, 7, 8 ne sont mesurées par aucun des deux.
PROCHAINE ACTION : garantir de la matière sous le profil de cavité aux stations
1 à 5, et fermer le fond au-delà de la station 8 (l'assise s'arrête à y = 9,10,
la gaine saute la dernière station). Rejouer
`python3 tools/probe_cave_openings.py` : il doit passer de RC=1 à RC=0.
```

**`docs/KNOWN_ISSUES.md`**

```
ISS-0xx — S2 — Grotte du Couchant : plancher absent et fond percé.
Reproduction : python3 tools/probe_cave_openings.py  -> RC=1, contrôles 1 et 2
en FAIL, cartes imprimées. Visible en jeu depuis la caméra t3_04_seuil_cadre.
Cause : voir evidence/world_v2/v2_3_r2a/grotte/seuil_forensic/SEUIL_FORENSIC.md §3.
Contournement : aucun. Propriétaire : correction de production non assignée à
cette session.

ISS-0yy — S3 — make_waterfall_cave.py imprime `sol sous <nom> : %.3f m` sans la
valeur attendue. La ligne a publié -0,416 m là où le profil attend -0,040 m, et
personne ne pouvait le voir. Correction : imprimer l'attendu à côté du mesuré.
```
