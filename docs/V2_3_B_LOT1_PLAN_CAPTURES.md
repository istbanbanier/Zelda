# V2.3-B lot 1 — PLAN DE CAPTURES

**VIVANT.** Ce que le lot doit montrer, avec quelles caméras, et pourquoi
celles-là. Écrit avant les captures : un plan rédigé après coup décrit ce qu'on
a réussi à photographier.

## 1. La règle

> **Les caméras sont DÉRIVÉES, jamais tapées.**

Une caméra posée à la main est irreproductible : dans trois semaines, personne
ne saura si le cadrage a changé parce que le lieu a bougé ou parce que la main a
tremblé. `tools/godot/plan_captures_lot1.gd` calcule chaque plan à partir de
deux choses que le dépôt possède déjà — le `v2_site` du layout et l'emprise
réelle du lieu monté — par une règle écrite dans son en-tête. Relancer le
générateur sur le même commit redonne les mêmes nombres.

La **direction d'approche** est elle aussi dérivée : c'est la direction du point
le plus proche d'une route contractuelle. C'est par là que le joueur vient, donc
c'est de là qu'un lieu doit se lire. Quand aucune route n'est à moins de 120 m,
le générateur se rabat sur le centre du monde **et le plan le dit** dans son
champ `proves` — un repli silencieux serait un cadrage inventé.

## 2. Trois vues par sujet, et ce que chacune prouve

| vue | réglage | ce qu'elle prouve | ce qu'elle ne prouve pas |
|---|---|---|---|
| `_lecture` | FOV 50°, distance `2,2 × plus grande dimension` (min 12 m), hauteur `0,55 × hauteur` (min 2,5 m) | le lieu dans son terrain, sa relation aux voisins, sa silhouette à distance de lecture | rien sur le ressenti en jeu |
| `_joueur` | FOV **44°**, distance **4,3 m**, œil **1,45 m** | ce que le joueur voit RÉELLEMENT. Valeurs recopiées de `resources/tuning/locomotion_default.tres` | rien sur la jouabilité : ce conteneur n'a ni écran ni manette |
| `_rasante` | FOV 46°, œil 0,9 m, latéral | l'ASSISE : un volume contre un plan peint, une fondation qui touche ou ne touche pas | rien sur la lecture à distance |

La vue rasante n'est pas décorative. `PROMPT4_METHOD` §3 étape 5 : *« une seule
belle image ne prouve rien »* — et la vue rasante est précisément celle qui
démasque un décor tenu de face et creux de côté.

Le contrat §2.9 exige « deux vues propres au minimum, dont une vue joueur ». On
en produit trois : la troisième coûte une seconde de rendu et répond à une
question que les deux autres ne posent pas.

## 3. Silhouettes

Trois angles (0°, 90°, 180°) par sujet du lot **et** par sujet du corpus
accepté. Les secondes ne sont pas du décor : elles **calibrent** le seuil de la
règle R-D3 (`docs/V2_3_B_LOT1_CONTROLES.md` §3.4). Sans elles, le détecteur rend
`BLOQUÉ` par son garde-fou R-D3c, ce qui est le comportement voulu — un seuil
sans corpus n'est pas un seuil.

`tools/godot/capture_silhouette.gd` refuse d'écrire une image non bimodale :
une capture assombrie n'est pas une silhouette, et l'outil sort en échec plutôt
que de livrer une preuve qui n'en est pas une.

## 4. Carte du lot et planche de miniatures

- **carte** : `tools/godot/render_world_v2_maps.gd --label=v2_3_b_lot1`, pour
  situer les six sujets les uns par rapport aux autres et par rapport aux
  routes ;
- **planche** : `tools/godot/compose_contact_sheet.gd`, trois colonnes.
  `test_world_v2_proof_boards.gd` existe parce que deux planches entièrement
  VIDES ont été livrées au lead en V2.3-A — `blit_rect` échouait sans erreur sur
  une différence de format. Une planche se vérifie tuile par tuile, pas à l'œil.

## 5. La chaîne, en une commande

```bash
tools/capture_lot1.sh --out-dir=evidence/world_v2/v2_3_b/lot1
```

Elle enchaîne, dans cet ordre : plan dérivé → vues → silhouettes du lot →
silhouettes du corpus → **verdict D3** → carte → planche. Le verdict D3 est
produit au milieu de la chaîne parce que le filet
`test_world_v2_lot1_defauts.gd` l'exige : verdict absent ⇒ suite rouge.

**Arbre sale : refusé.** Le manifeste doit porter `repo_dirty: false` et le hash
du commit livré (`.claude/rules/evidence.md`). `--allow-dirty` existe pour
itérer ; ses images ne sont pas des preuves. **Le lead lance la chaîne finale
depuis un arbre committé** — c'est la règle du brief, et c'est aussi la seule
façon qu'une image se rattache à un commit.

## 6. Ce que ces captures ne prouveront pas

- **Aucune performance.** Xvfb + Mesa llvmpipe, rendu logiciel : utilisable pour
  la régression visuelle, jamais pour une mesure de frame (`CLAUDE.md`,
  « limites connues »).
- **Aucune jouabilité.** Ni écran, ni clavier, ni manette :
  `docs/MANUAL_VALIDATION.md`.
- **Aucun verdict artistique.** Le verdict technique appartient au lead, le
  verdict artistique au propriétaire, sur inspection à taille réelle.
