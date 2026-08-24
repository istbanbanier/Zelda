# LOT 1.R — rapport de corrective visuelle

**Base de la directive** : `89a3009`. **Verdict Codex sur le lot 1** : PASS
technique, **REJET visuel**. **`GO_V2_3_B_LOT2` reste `FALSE`.**

Ce rapport ne prononce **aucun verdict artistique**. Le lead n'a pas autorité
pour cela : la revue appartient à Codex et à Istvan. Ce qu'il dit, c'est ce
qui a été fait, ce qui a été mesuré, et ce qui reste `NON VÉRIFIÉ`.

## 1. Méthode

Trois arbres de travail détachés du même commit, un propriétaire par fichier,
**aucun push d'agent, aucun commit de fusion**. Le lead reproduit, inspecte en
taille réelle, puis cueille par cherry-pick dans l'ordre A → B → C.

Six lieux, six émotions imposées, **deux compositions réellement différentes
proposées par lieu**, arbitrées par le lead sans attendre Istvan. Permission
explicite de remplacer un asset faible ; interdiction explicite d'en garder un
au motif qu'il est déjà dans le dépôt.

## 2. Ce que les voies ne pouvaient pas prouver

Une preuve qui montre PLUSIEURS lieux ne peut pas naître dans l'arbre d'une
voie : les cinq autres lieux y sont encore dans leur état rejeté. Cela vaut
pour le verdict D3 du lot, la preuve croisée `gp_lointain`, la planche anonyme
des six vues joueur, et les vidéos dont l'arrière-plan peut contenir un voisin
non corrigé.

**Exception vérifiée** : la vidéo du champ, dont le cadre ne contient aucun
autre sujet du lot (village gelé seulement).

## 3. Validation technique sur l'arbre intégré

| Étape | Résultat | Commit |
|---|---|---|
| Import Godot | `RC=0` | intégré |
| Filet des huit défauts D1–D8 | **11 réussis, 0 échoué** | `5920b87` |
| Contrat des lieux | **5 réussis, 0 échoué** | `5920b87` |
| Contrôle négatif, 8 sabotages | **8 déclarés, 8 joués, 8 validés** | `213e1a2` |
| Détecteur R-D3 du lot | *(rejoué — §5)* | |
| `validate_fast.sh` | *(§4)* | |

## 4. La passe de clôture a d'abord été ROUGE

Premier verdict sur l'arbre intégré `29f06bc` : **960 tests, 1 échoué**,
`rc=1`. Cause unique et nommée —
`test_invariants.gd::test_tout_cache_statique_de_ressources_est_liberable` :
les trois lieux de la voie B avaient gagné un cache statique sans chemin de
libération (ISS-059).

**Aucune ligne du diff ne montrait le manque** : ce qui manquait était une
fonction absente. Le hook regarde les lignes ajoutées, le test regarde l'état
du projet ; ici seul le second pouvait voir (`PROMPT4_METHOD` §2).

Correctif `3fd004c` : `_static_init()` + `liberer_caches()`, motif déjà en
place dans `abandoned_farm_place.gd`. Le journal ROUGE est committé sous
`validation/` — un dossier qui ne garde que ses verdicts verts ne prouve rien.

## 5. Deux preuves périmées attrapées avant usage

**Le verdict D3 `PASS` citait un commit introuvable.**
`verdict_PASS_0f94194.json` déclare un commit que `git cat-file -t` ne trouve
pas : calculé dans un état local jamais poussé, perdu avec la recréation du
conteneur. Le verdict `FAIL` du même dossier, lui, pointe sur `213e1a2`, qui
est un ancêtre de HEAD. Le PASS est donc repassé **`NON VÉRIFIÉ`** et rejoué
sur un commit atteignable.

*Piège de méthode* : `git rev-parse --short <40 hex>` abrège **sans vérifier
l'existence**. Seuls `git cat-file -t` et `git merge-base --is-ancestor`
répondent vraiment.

**Un sha256 du manifeste d'assets était faux.** `SM_Watchtower_Ruin` portait
`8d1b56bf`, qui ne correspond à aucune version du GLB dans l'histoire ; le
seul blob existant vaut `d7c710e9`. `SM_Barrow_Stones` annonçait un sha256
recalculé sans jamais l'écrire. Aucun test ne lit ce fichier — même famille de
panne silencieuse qu'ISS-066. D'où `tools/verifier_manifeste_lot1r.py`,
exécutable et éprouvé par sabotage.

## 6. Preuves visuelles

*(à compléter après la passe de captures sur l'arbre intégré)*

## 7. Barre « wahou », lieu par lieu

*(à compléter — `BARRE_WAHOU.md`, écrite AVANT toute capture finale)*

## 8. Ce qui reste NON VÉRIFIÉ

- **le verdict visuel du lot** : il appartient à Codex et à Istvan ;
- tout ce que ce conteneur ne peut pas juger — écran, clavier, manette, GPU
  (`docs/MANUAL_VALIDATION.md`).
