# RAPPORT — CORRECTION D3, arbre intégré du lot 1.R

Arbre `/home/user/wt-lot1r-d3`, détaché de `67a51c0`. **Aucun push.** Aucun
fichier gelé, aucun test, aucun seuil, aucun lieu autre que le cimetière n'a
été touché — la preuve est au §7.

Statuts : `PASS` · `PARTIAL` · `FAIL` · `BLOQUÉ` · `NON VÉRIFIÉ`.
Aucun verdict artistique n'est prononcé ici.

**Résultat en une ligne : `PASS`.** Le détecteur de répétition rend `PASS` sur
les quinze manifestes, zéro paire signalée, témoin dégénéré signalé à 1,0000
aux trois distances. Les deux filets sont verts.

---

## 1. Commits, dans l'ordre

| Commit | Sujet |
|---|---|
| `27acef8` | **la correction** — cimetière, `barrow_cemetery_place.gd` seul |
| `0f94194` | silhouettes recapturées à `27acef8`, arbre propre ; brief versé |
| `5920b87` | verdict D3 `PASS`, journal, silhouettes AVANT, planche avant/après |
| *(celui-ci)* | ce rapport |

---

## 2. Ce que j'ai regardé avant de toucher au code

### 2.1 Les deux aplats noirs

`silhouette_overlook_summit_000.png` : deux masses pleines, la grande à
gauche, un satellite détaché à droite, rien entre les deux.
`silhouette_barrow_cemetery_000.png` : un ruban bas de trois dos, un mince
éclat de pierre au-dessus du dos de gauche, un satellite à droite.

Le diagnostic du lead se vérifie à l'œil, mais **il fallait mesurer POURQUOI
l'instrument les confond**, parce qu'à pleine résolution les deux images ne
se ressemblent pas tant que ça. La réponse est dans le cadrage, et elle est
mécanique.

### 2.2 Le mécanisme, en cotes

`capture_silhouette.gd` cadre par l'AABB :

```
camera.size = max(Y, max(X,Z) × hauteur_image/largeur_image) × 1,20
```

Sur le cimetière — 23,55 × 2,76 × 19,35 m en cadre paysage — c'est
`23,55 × 0,75 × 1,20 = 21,20 m` : **c'est la LARGEUR qui pilote le cadre, pas
la hauteur**. Le sujet occupe donc 2,76 / 21,20 = 13 % de la hauteur du cadre.
Même règle sur le belvédère : 6,96 / 35,86 = 19 %.

Puis le détecteur écrase les deux sur une toile commune de 96 × 96. Résultat
mesuré sur les masques réels, à 30 m :

| | bande occupée | aire (px sur 9 216) |
|---|---|---|
| belvédère 0° | lignes 39 → 56 | 547 |
| cimetière 90° | lignes 42 → 54 | 356 |

**85,1 % du masque du cimetière tombe à l'intérieur de celui du belvédère.**
La ressemblance mesurée n'est donc pas une ressemblance de dessin : c'est une
ressemblance de BANDE. À cette résolution de lecture, tout lieu large et bas
devient le même ruban horizontal centré, et le plus petit se niche dans le
plus grand. Le paramètre qui commande la bande est le rapport
hauteur / largeur au sol.

C'est ce rapport que la correction change — et c'est pour cela que la piste du
lead (« faire percer les verticales ») était la bonne : elle ne déplace pas de
la matière, elle change la seule variable que l'instrument regarde.

### 2.3 Contrôle : la chaîne de capture est déterministe

Avant d'écrire une ligne, j'ai rejoué la capture d'origine sur l'arbre
**non modifié** : les deux PNG reviennent **au bit près**
(`sha256 66710480…` et `534a6c8a…`, identiques aux fichiers committés).
La commande et l'outil sont donc les bons, et tout écart mesuré ensuite vient
de la géométrie, jamais du rendu.

### 2.4 Une prédiction, faite avant de modéliser

Le cadrage étant entièrement connu, j'ai simulé hors moteur l'effet d'une
verticale ajoutée (décalage du contenu vers le bas de Δ/2 puisque la caméra
se recentre sur l'AABB, plus une barre au sommet), puis passé le résultat dans
le ré-échantillonnage du détecteur.

Témoin de la simulation : à Δ = 0, elle rend **0,5050 / 0,4856 / 0,5329**,
c'est-à-dire exactement les valeurs mesurées. Elle prédisait, pour
Δ ≈ +1,75 m, un IoU de 0,337 / 0,339 / 0,325 contre le belvédère.

**Mesuré ensuite dans le moteur, à Δ = +1,86 m : 0,3145 / 0,3242 / 0,3217.**
La prédiction a servi à choisir la cote sans brûler cinq passes de capture ;
elle ne fait pas preuve, et c'est la capture qui a tranché.

---

## 3. Ce que j'ai changé, et pourquoi

Un seul fichier : `scripts/world_v2/poi/barrow_cemetery_place.gd`.

### 3.1 Les six marques dressées prennent leur taille de pierres levées

Deux colonnes s'ajoutent aux spécifications de `CHEMIN` et
`MARQUES_ISOLEES` : échelle **en travers** et échelle **en hauteur**,
dissociées — une pierre levée est plus élancée, pas plus grosse.

| Marque | hauteur avant | hauteur après | rôle |
|---|---:|---:|---|
| stèle basse du chemin (`Stele_B`) | 0,92 m | 1,58 m | premier signe rencontré |
| stèle haute du chemin (`Stele_A`) | 1,57 m | 2,48 m | second signe, plus près |
| stèle de l'est (`Stele_B`) | 0,92 m | 1,49 m | marque lointaine opposée |
| **pierre du seuil** (`Stele_A`) | — | **4,33 m** | tête du dos dominant |

Les trois lames couchées **ne bougent pas** : « à demi avalées par l'herbe »
reste la cote (0,13 à 0,20 m d'émergence, sous la hauteur de marche du héros).

Le crescendo suit le chemin d'arrivée sud-ouest → gueule : la séquence
« signes secondaires d'abord, puis le dominant » cesse d'être un simple ordre
de rencontre et devient une montée.

### 3.2 La pierre du seuil

Une seule pièce ajoutée, à `(x = +1,886 ; z = +1,364)` en repère local — au
bout HAUT du grand axe de `Tertre_Grand`, **1,1 m au-delà du pied du dos** et
à l'opposé de la gueule. Trois raisons vérifiables :

* elle est hors de la jupe du tertre. Le rayon maximal du dos vaut
  `demi_long × (0,88 + 0,22) = 5,50 m` ; la pierre est à 6,10 m du centre sur
  le même axe. Elle est donc assise sur le terrain gelé et `_seated()` suffit ;
* elle n'entre ni dans le quadrant d'accès des déblais ni dans le corridor
  d'arrivée : 4,5 m de l'ancre de récompense, 3,8 m de la gueule. On marche
  jusqu'au coffre sans la contourner ;
* vue depuis l'arrivée sud-ouest, elle se dresse **derrière** le dos dominant.
  Elle couronne l'élément héroïque au lieu de le précéder — l'intention impose
  les signes secondaires d'abord.

### 3.3 Les colliders suivent

Les trois boîtes de stèle sont étirées comme leur pierre (une stèle qui double
de hauteur sans son corps se traverserait par le haut), et la pierre du seuil
reçoit un corps sur toute sa hauteur : c'est la seule masse du lieu qu'on ne
franchit pas. Collisions du lieu : 12 → **13** sur un plafond de 20.

L'approximation « boîte d'aplomb sous une pierre penchée » est **conservée
telle quelle et re-nommée dans le code** : le sommet penché sort de son corps,
jusqu'à 0,73 m sur la stèle haute. C'est le même arbitrage que celui déjà pris
pour les lames — mieux vaut une masse traversable en haut qu'un mur invisible
qu'on sent sans le voir. Le pied, qu'on heurte en marchant, est couvert.

### 3.4 Ce que je n'ai PAS fait

* **le vide n'est pas rempli** : une seule pièce ajoutée, contre une masse
  existante ; les cinq autres gestes sont des changements d'échelle sur des
  marques déjà là. Le vide entre le groupe de gauche et le satellite de droite
  est intact sur les deux vues ;
* **`_tertre()` n'est pas touché** : la méthode terrain-hugging, les trois noms
  de nœuds de l'exemption D1a, le profil sans arête faîtière et les trois
  réécritures de la voie B sont tels quels. `D1` reste vert et l'aire runtime
  du lieu reste à 0,0 % ;
* **le GLB n'est pas touché** : aucune chaîne Blender n'a été nécessaire, donc
  aucune ligne de manifeste à recalculer ;
* **l'emprise XZ n'a pas bougé d'un centimètre** (23,5519 × 19,3495 m avant et
  après), donc le cadre de capture est identique et la comparaison avant/après
  porte sur la forme seule ;
* **le belvédère n'a pas été ouvert**, ni aucun seuil, ni aucun test.

---

## 4. Les mesures

### 4.1 Le couple signalé — IoU aux trois distances

Seuils identiques avant et après, calibrés comme toujours sur
`ferme abandonnée × pont de pierre`, deux lieux du corpus accepté.

| Distance | Seuil S | AVANT | marge | APRÈS | marge |
|---|---:|---:|---:|---:|---:|
| 30 m | 0,4931 | **0,5050** | **+0,0119** `FAIL` | **0,3145** | **−0,1786** |
| 80 m | 0,4912 | 0,4856 | −0,0056 | **0,3242** | **−0,1670** |
| 160 m | 0,5458 | 0,5329 | −0,0129 | **0,3217** | **−0,2241** |

`dprofil`, publié et non liant : 0,0879 → 0,0863 · 0,0836 → 0,0980 ·
0,0839 → 0,0860.

Le fait que 80 m et 160 m étaient déjà à moins de 0,013 du seuil est la raison
pour laquelle je n'ai pas visé le minimum suffisant : une correction qui
n'aurait sauvé que les 30 m aurait laissé deux marges de la largeur du bruit.

### 4.2 Le pire voisin du cimetière, tous sujets confondus

| Distance | AVANT | APRÈS |
|---|---|---|
| 30 m | belvédère 0,5050 (**+0,0119**) | camps de braise 0,3263 (−0,1668) |
| 80 m | belvédère 0,4856 (−0,0056) | belvédère 0,3242 (−0,1670) |
| 160 m | belvédère 0,5329 (−0,0129) | hameau de la rive 0,3324 (−0,2134) |

Le cimetière n'est plus le voisin le plus proche de personne, et le belvédère
n'est plus le sien à deux distances sur trois.

### 4.3 Le belvédère, non touché, garde ses marges fines

C'était la condition explicite du brief. Vérifié chiffre par chiffre :

| Distance | son pire voisin APRÈS | marge |
|---|---|---:|
| 30 m | hameau de la rive 0,4773 | −0,0158 |
| 80 m | hameau de la rive 0,4822 | **−0,0090** |
| 160 m | ferme abandonnée 0,5174 | −0,0284 |

Le **−0,0090 contre le hameau à 80 m** est exactement la marge que le brief
nommait. Elle est **inchangée** : elle existait avant ma correction et je n'y
ai pas touché. Elle était simplement masquée dans le classement par la paire
qui rougissait.

> **À signaler au lead, et c'est le seul point d'attention qui reste.** Une
> fois le cimetière écarté, la paire la plus serrée de tout le lot devient
> `overlook_summit × riverside_village` à 80 m, **−0,0090**. Le lot passe, mais
> c'est désormais elle la contrainte liante. Ce n'est pas une régression de
> cette correction — le chiffre est identique avant et après — c'est une
> information sur ce qui deviendra rouge en premier si un lieu bouge encore.

### 4.4 Le témoin dégénéré

`camp` comparé à lui-même : **IoU 1,0000, SIGNALÉ**, aux trois distances.
L'instrument voit toujours ; le `PASS` n'est pas un `PASS` d'aveugle.

### 4.5 La capture

| | AVANT | APRÈS |
|---|---|---|
| emprise | 23,5519 × **2,7621** × 19,3495 m | 23,5519 × **4,6242** × 19,3495 m |
| cadre | 1200 × 900 | 1200 × 900 (inchangé) |
| sujet 0° / 90° | 3,507 % / 3,879 % | **3,981 % / 4,327 %** |
| hors bandes | 0,000 % | 0,000 % |
| commit / arbre sale | `7b31316` / non | `27acef8` / **non** |

Le plancher de 2,0 % de l'outil s'éloigne au lieu de se rapprocher : la
tension notée au §9.4 du rapport de la voie B se détend.

---

## 5. Les deux filets, rejoués

Exécutés à `5920b87`, l'état livré, via `tools/lancer_godot.sh`.

| Filet | Commande | Résultat |
|---|---|---|
| Les huit défauts nommés (D0–D8 + 2 témoins) | `tools/lancer_godot.sh --path . --script tools/godot/test_runner.gd -- --filter=lot1_defauts` | **11 réussi(s), 0 échoué(s)**, 38 assertions, 0 erreur de script, `RC_GODOT=0` |
| Contrat des lieux | `… -- --filter=places_contract` | **5 réussi(s), 0 échoué(s)**, 14 assertions, 0 erreur de script, `RC_GODOT=0` |

Les onze essais du premier filet sont verts individuellement, dont les quatre
que cette correction pouvait casser :

* `D1` — assemblage de primitives : vert, aire runtime du lieu **0,0 %** ;
* `D2` — rien ne flotte, rien n'est enterré : vert (la pierre du seuil déclare
  son assise et repose sur le terrain gelé) ;
* `D3` — étage structurel **et** étage image : vert, le verdict lu par le filet
  est passé de `FAIL` à `PASS` ;
* `D4` — ni route, ni eau, ni caméra gelée obstruée : vert ;
* `D7` — budgets : vert.

Budget du lieu relu sur la scène montée
(`tools/godot/sonde_budget_lot1.gd`, `RC=0`) :

| | modules | nœuds visuels | collisions | aire runtime |
|---|---:|---:|---:|---:|
| avant | 30 / 40 | 34 / 80 | 12 / 20 | 0,0 % |
| **après** | **31 / 40** | **35 / 80** | **13 / 20** | **0,0 %** |

Les deux témoins du filet (l'instrument de boîtitude voit un pavé ; les
compteurs comptent ce qu'ils prétendent compter) sont verts eux aussi : un
filet vert dont l'instrument est aveugle ne prouverait rien.

---

## 6. Les preuves, et où les ouvrir

| Fichier | Ce qu'il montre |
|---|---|
| `evidence/…/lot1/controles/verdict_repetition.json` | le verdict **liant**, celui que D3 lit — `PASS`, commit `0f94194`, `repo_dirty: false` |
| `evidence/…/lot1r/d3_integre/verdict_PASS_0f94194.json` | copie horodatée du même verdict |
| `evidence/…/lot1r/d3_integre/repetition_0f94194.log` | la matrice complète des 90 paires × 3 distances |
| `evidence/…/lot1r/d3_integre/verdict_FAIL_213e1a2.json` | le verdict en échec d'origine (déjà présent) |
| `evidence/…/lot1r/d3_integre/avant/` | les deux silhouettes du cimetière AVANT, extraites de `67a51c0` |
| `evidence/…/lot1r/d3_integre/d3_avant_apres_cimetiere.png` | la planche : cimetière avant/après aux deux angles, avec le belvédère inchangé à côté |
| `evidence/…/lot1/silhouettes/silhouette_barrow_cemetery_0*.png` | les silhouettes livrées |

Commande exacte de la capture, rejouable :

```bash
tools/lancer_godot.sh --rendu --ecran=1000x1400x24 --path . \
  --script tools/godot/capture_silhouette.gd -- \
  --scene=res://scenes/world_v2/WorldV2.tscn \
  --place=valley.poi.barrow_cemetery.01 --name=barrow_cemetery \
  --out-dir=evidence/world_v2/v2_3_b/lot1/silhouettes \
  --angles=0,90 --size=1200x900 \
  --provenance=lieux:scripts/world_v2/poi
```

Commande exacte du détecteur :

```bash
python3 tools/lot1_repetition.py \
  --manifestes evidence/world_v2/v2_3_b/lot1/silhouettes \
  --out evidence/world_v2/v2_3_b/lot1/controles/verdict_repetition.json
```

> Piège rencontré, et il vaut d'être noté : rediriger la sortie du détecteur
> **dans le dépôt** (`> …/repetition.log`) crée le fichier AVANT que l'outil ne
> lise `git status`, et le verdict s'écrit alors avec `repo_dirty: true` sur un
> arbre par ailleurs propre. Le journal doit être écrit hors du dépôt puis
> recopié. C'est exactement le genre de faux « arbre sale » qui décrédibilise
> une preuve correcte.

---

## 7. Périmètre du changement — la preuve

`git diff --name-only 67a51c0..HEAD` :

```
BRIEF_D3.md                                       (le brief du lead, versé)
evidence/…/lot1/controles/verdict_repetition.json (FAIL -> PASS)
evidence/…/lot1/silhouettes/…barrow_cemetery…     (3 fichiers, le cimetière seul)
evidence/…/lot1r/d3_integre/…                     (6 fichiers, tous neufs)
scripts/world_v2/poi/barrow_cemetery_place.gd     (la correction)
```

* aucun fichier sous `tests/`, `tools/` ou `docs/` ;
* un seul fichier sous `scripts/world_v2/poi/`, et c'est le cimetière ;
* aucun seuil, aucun fichier gelé, aucune silhouette d'un autre sujet ;
* aucune déclaration GDScript non typée dans les lignes ajoutées ;
* `tools/lancer_godot.sh --path . --check-only --script …barrow_cemetery_place.gd`
  → `RC_GODOT=0` ;
* aucun `git push`, aucun `pgrep -f`, aucun `pkill`.

---

## 8. Ce qui reste, et ce que je n'ai pas jugé

**`PASS`** — le fait mesuré du brief est corrigé, par la composition du seul
cimetière, sans toucher au seuil ni au belvédère, et les deux filets sont
verts.

Trois réserves honnêtes :

1. **`NON VÉRIFIÉ` — le rendu jouable du lieu.** Je n'ai produit que des
   silhouettes en aplat noir, qui sont ce que D3 juge. La lecture en couleur du
   cimetière avec sa pierre de 4,33 m (valeurs, ombre portée sur le dos,
   lisibilité de la gueule derrière) n'a **pas** été recapturée. Si le lead veut
   ce contrôle, c'est une passe de `capture_lot1.sh` sur ce lieu.
2. **Aucun verdict artistique n'est prononcé.** J'ai mesuré une distance de
   forme, pas jugé une composition. Que la « pierre du seuil » serve ou desserve
   l'intention « le poids du passé » relève de la revue, pas de moi. Je note
   seulement que la vue 0° montre le rythme de verticales demandé plus nettement
   que la vue 90°, où les pierres du chemin se serrent contre le dos dominant.
3. **La marge liante du lot a changé de propriétaire** (§4.3) :
   `overlook_summit × riverside_village` à 80 m, −0,0090. Chiffre inchangé par
   cette correction, mais c'est lui qui rougira le premier au prochain
   mouvement.

Une alternative mesurée, si le lead trouve la pierre trop haute : la simulation
du §2.4 prédit, pour une pierre de **3,80 m** au lieu de 4,33 m, des marges
d'environ −0,09 / −0,11 / −0,16. Elle passerait aussi.

Si je ne l'ai pas retenue, c'est un choix de robustesse et il se discute : la
simulation est fidèle à ±0,02 sur le témoin, mais elle reste une prédiction, et
deux des trois distances étaient à moins de 0,013 du seuil AVANT correction.
Une marge de 0,17 supporte une dérive future ; une marge de 0,09 la supporte
moins bien. Le choix appartient au lead : deux littéraux à changer, l'échelle
verticale `PIERRE_DU_SEUIL[5]` (2,76 → 2,42) et la hauteur de sa boîte de
collision (4,33 → 3,80, centre 2,17 → 1,90). Toute autre cote demande de
recapturer et de rejouer le détecteur — la prédiction ne fait pas preuve.
