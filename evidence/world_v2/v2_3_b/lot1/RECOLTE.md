# Récolte des trois voies — ordre d'intégration (à exécuter APRÈS le commit de clôture)

État constaté le 2026-08-21 ~17:50 UTC. Les trois agents sont morts dans la
suspension de 12 h ; leurs commits sont les livrables. Sauvetages effectués dans
LEURS arbres : `1bed85b` (voie B, trois lieux en cours) et `9a955c6` (voie C).

## Ce que chaque voie a livré

| Voie | Commits | Contenu | À inspecter avant cueillette |
|---|---|---|---|
| A | 10 | sonde d'implantation (729 l), mesures XZ hors moteur, filet LOT1_PLACES écrit ROUGE, publication SITES | RAS — n'a PAS touché le REGISTRY (conforme phase 2) |
| B | 4 + sauvetage | plan des six silhouettes ARRÊTÉ AVANT construction, puis 6 scripts + 6 scènes | les 3 lieux du commit de sauvetage sont NON RELUS, NON TESTÉS |
| C | 10 + sauvetage | filet des 8 défauts, détecteur D3, compteur de budget, plan de captures, provenance | idem sur gate_negatif_lot1.sh |

Zéro recouvrement de fichier entre les trois arbres — vérifié par diff.

## Constats remontés par les voies, à traiter par le lead

1. **C : `SM_WaterfallCave_r2a358.glb` est GELÉ mais absent d'ASSET_MANIFEST.csv**
   (trouvé par lot1_provenance.py, reproductible). Violation de la règle
   « manifeste AVANT build » sur un fichier déjà livré — dette à corriger, pas
   un défaut du lot 1.
2. **C : sa première version de D5 accusait 3 des 9 lieux ACCEPTÉS** — corrigée
   et mesurée avant livraison. À revérifier en cueillant.
3. **A + B ont convergé indépendamment sur le secteur libre du belvédère** :
   masse à l'est (derrière cam05), ouverture OSO. Convergence de deux mesures
   séparées = bon signe ; le filet caméras tranchera.
4. **A : marges critiques** — overlook_summit route −1,20 m (la route passe SUR
   le site : composer AUTOUR, jamais dessus) ; turquoise_spring affluent +2,19 m.

## Ordre de cueillette (cherry-pick, aucun merge commit) — RÉVISÉ

Première version exigeait « chaque état intermédiaire vert » avec A cueillie
SANS son filet. Impossible proprement : les retouches du filet sont réparties
sur DEUX commits de A (0389e34, d6262f9), entrelacés dans la série avec
l'outillage. Découper ces commits serait réécrire l'histoire de l'agent.

Ordre révisé — le ROUGE du filet entre A et le câblage est ASSUMÉ, borné à
l'intérieur d'une même vague locale, et rien n'est poussé avant le vert :

1. Voie B d'abord : les 6 lieux, non câblés → tout reste vert.
   INSPECTION passe 2 (moteur) sur les 3 lieux du sauvetage AVANT cueillette.
2. Voie A entière, dans l'ordre de ses commits → le filet devient ROUGE
   (six sujets « RESTÉ SIMPLE MARQUEUR ») — c'est le rouge d'abord VOULU,
   dont l'agent a archivé la preuve.
3. LEAD, immédiatement après : câblage REGISTRY (6 entrées) → le filet juge
   les lieux réels et doit verdir.
4. Voie C : filet des 8 défauts + outillage + sabotages archivés.
5. UNE validation complète. AUCUN push entre 1 et 5 : le distant ne voit
   jamais l'état rouge intermédiaire.
6. Captures depuis arbre committé, carte, planche, checkpoint.

## Reproduction par le lead (rien n'est accepté sans elle)

- rejouer la sonde A (phase 2, moteur) et comparer à geometrie_xz.json ;
- instancier chaque scène B isolément, compter les budgets avec l'outil C ;
- rejouer les sabotages C et vérifier que chaque rouge nomme SON défaut.

## Inspection du lead — passe 1 (hors moteur, 2026-08-21 ~17:55 UTC)

Portée : les 3 lieux du SAUVETAGE d'abord (les plus risqués), puis les 6 scènes.

| contrôle | résultat |
|---|---|
| classe + `default_place_id()` constant | 6/6 conformes |
| position de site codée en dur | AUCUNE — les littéraux signalés (86.0, 74.0) sont des angles locaux, vérifiés en contexte |
| appuis déclarés / assise | 13 à 25 usages par lieu |
| primitives nues | ZÉRO — tout passe par le kit |
| ancres de récompense vs PLAN canonique | 6/6 cohérentes ; `barrow`=CHEST(hache dans un coffre) et `overlook`=WEAPON(arc posé) sont deux choix délibérés, confirmés par la lecture de `furnish()`/`_grant()` |
| scènes `.tscn` | 6/6 sur le patron accepté (enveloppe mince, 11 lignes) |

**Ce que cette passe NE prouve PAS** : parse, instanciation, budgets réels,
fondations sur le vrai terrain, filets D1–D8. Tout cela exige le moteur —
passe 2, après le commit de clôture. Les trois lieux sauvés restent marqués
NON TESTÉS jusqu'à là.

## Inspection du lead — passe 2 (SOUS MOTEUR, 2026-08-23)

La passe 1 s'arrêtait à « tout cela exige le moteur ». Fait. Chronologie
réelle, avec les verdicts au moment où ils sont tombés :

1. **Filet lot1_defauts, premier passage sur les lieux réels** : 5 échecs —
   D1 (plafond non calibré), D2 ×2, D3 (verdict image absent), D4 ×2, D7 ×3.
2. **Trois pièges d'instrument mesurés et corrigés** (test + sonde, commit
   `426d1ff`) : `surface_get_primitive_type` n'existe que sur `ArrayMesh` ;
   `get_meta(nom, null)` déclenche quand même l'erreur d'absence ; l'AABB
   d'un MultiMesh sous renderer factice est TOUJOURS (0,0,0) — emprise
   recalculée côté CPU. Une calibration D1a exécutée avec la sonde boguée
   avait rendu 20,63 % : chiffre REJETÉ, jamais inscrit.
3. **Calibration D1a saine** : RC=0, zéro SCRIPT ERROR, maximum 20,37 %
   (ember_raider_camps) sur les 9 lieux acceptés → plafond 20,4 inscrit
   avec journal daté (`controles/calibration_d1a_2026-08-23.log`).
4. **Défauts réels des lieux corrigés** (commit `4a67589`) :
   - D2 : les pièces portées des extrémités déclarent leur assise (guet :
     plaques couchées + roc d'angle ; source : dalles du déversoir) ;
   - D4 : le filet ramassait les sphères de DÉCOUVERTE (`PointOfInterest`,
     un Area3D) — 75 faux empiétements au sanctuaire, un faux « dans le
     lit » à la source. Aligné sur le filet de référence : formes portées
     par un `StaticBody3D` seulement. Amendement daté au contrat §D4 ;
   - D7 : les trois micro-POI portent chacun EXACTEMENT 12 pièces de
     composition ; c'est la machinerie de récompense (3 nœuds/arme,
     2/ingrédient, structure de `_grant()`) qui débordait. Amendement §2
     daté : le sous-arbre d'un `RewardAnchor` ne compte pas. Le plafond 12
     ne bouge pas ; la nappe de la source RESTE comptée (anti-empilement)
     et la source a cédé son `Plant_7` — le budget a mordu une vraie pièce ;
   - D1 : l'exemption d'aire revendiquée en prose (tertres du cimetière,
     nappe de la source) n'était câblée nulle part — 55,7 % au cimetière.
     Titre vérifié dans le code avant la pose des métas (chaque sommet de
     tertre appelle `ground_local_y`).
5. **Filet rejoué : 10/11 verts.** Seul D3 (étage image) reste, par
   construction : ses captures n'existaient pas encore.
6. **Incident de discipline, avoué** : la première campagne de silhouettes
   a été lancée puis une ligne d'ASSET_MANIFEST ajoutée PENDANT les prises —
   manifestes `repo_dirty=true`. Captures supprimées, ligne commitée
   (`bc55474`), campagne relancée d'un arbre propre.
7. **Dette voie C soldée** : `SM_WaterfallCave_r2a358.glb` (grotte promue,
   gelée) a désormais sa ligne de manifeste — mesures par `gltf_inspect.py`.

## D3 — l'étage image a mordu, et la correction est de composition

Chronologie (commits `aa4f689` puis `cbb0611`) :

1. Campagne : 15 sujets × 2 angles, arbre committé, `repo_dirty=false`
   partout. Trois sujets PLATS (champ de fleurs, camp, +1) repris en
   paysage 1200×900 — c'est le cadrage portrait qui noyait un sujet bas
   dans du vide, le seuil de bimodalité de l'outil n'a pas bougé.
2. Détecteur R-D3 : **FAIL** — `overlook_summit ≈ waterfall_cave` à
   IoU 0,568/0,560/0,570 contre S 0,493/0,491/0,546 (calibration
   ferme×pont, 36 paires, témoin dégénéré signalé aux trois distances).
   Le belvédère groupé se projetait en un seul amas triangulaire — la
   même lecture que la grotte. Preuves archivées :
   `controles/d3_avant_rework/`.
3. Correction DE COMPOSITION, aucun seuil touché : l'aile nord devient un
   avant-poste détaché (9,5;1,5 → 13;−1), la crête se lit bimodale sur
   les deux axes. Marges refaites au calcul : 8,5 m de la diagonale de
   route, toujours derrière cam05.
4. Recapture depuis l'arbre committé, détecteur rejoué : **PASS** —
   overlook×cave 0,481 < 0,493, aucune autre paire au-dessus, témoin
   toujours signalé. Avant/après : `controles/d3_avant_apres.png`.
5. Filet complet rejoué : **11/11 VERTS** (D1 à D8).

## Captures POI et planche

13 plans (`poi/`, manifeste commit+repo_dirty), planche 13 vignettes,
carte du lot. Deux reprises de cadrage documentées dans
`shots_lot1.json` ; l'approche nord du sanctuaire bute sur un tronc GELÉ
de la végétation V2.2 (le site n'est pas exclu du scatter — constat déjà
porté par l'en-tête du lieu, confirmé en image).

Observations versées à la passe art, NON bloquantes au niveau graybox du
lot : roches de kit terracotta au belvédère et à la source là où r04/r07
demandent un minéral plus froid ; nappe de la source quasi blanche au
rendu (piège albédo ≠ valeur rendue, gain ≈ 1,8, scripts/CLAUDE.md).
