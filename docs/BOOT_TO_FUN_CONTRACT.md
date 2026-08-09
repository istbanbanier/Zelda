# Contrat BOOT-TO-FUN — document VIVANT

Ce que le joueur qui lance le build normal doit pouvoir faire, et **comment
chaque point est prouvé**. Ce contrat n'ajoute aucune exigence : il rend
vérifiable ce que `MASTER_SPEC` et `PROMPT2_SPEC` demandent déjà.

Il est **vivant** : quand le code et ce fichier divergent, c'est le code qui a
raison et ce fichier qui se corrige. Il cite des chemins stables et des tests
épinglés, jamais des compteurs qui pourrissent (règle d'ancrage, `CLAUDE.md`).

## Le principe qui gouverne tout le reste

> **Un test de présence ne prouve jamais l'atteignabilité.**

`test_valley_world.gd::test_the_menu_reaches_the_valley_scene` vérifie une
constante du menu et `can_go_to()`. Il resterait vert si le bouton n'était plus
connecté, si `_ready()` plantait, ou si la vallée s'ouvrait sans joueur.

Un critère n'est donc `PASS` que si sa preuve part du **flux réellement livré** :
`Boot.tscn` → menu → transitions par `interact()`. Charger une salle directement
prouve qu'elle est solvable, jamais qu'un joueur puisse y arriver.

## États autorisés

`PASS` · `FAIL` · `BLOQUÉ` · `NON VÉRIFIÉ`

- Un critère sans preuve exécutée est **`NON VÉRIFIÉ`**, jamais `PASS`.
- **Le verdict global est le plus FAIBLE des critères, jamais leur moyenne.**
  Neuf `PASS` et un `FAIL` font un `FAIL`.
- `BLOQUÉ` désigne un obstacle d'environnement nommé, pas une difficulté.

## Commandes

```bash
tools/gate_negative_control.sh            # le gate sait-il rougir ?
godot --headless --path . --script tools/godot/test_runner.gd -- --filter=boot_smoke
godot --headless --path . --script tools/godot/test_runner.gd -- --filter=golden_path
tools/validate_fast.sh                    # la suite entière, verdict de référence
```

Le contrôle négatif passe **avant** de croire un vert : un gate qui n'a jamais
échoué peut être vert parce que le jeu va bien, ou parce qu'il ne regarde rien.

## A — Boot Smoke, le parcours court

Fichier : `tests/playthrough/test_boot_smoke.gd`

| # | Critère | Preuve |
|---|---|---|
| B1 | `Boot.tscn` s'instancie et survit à `_ready()` | assertion B1 |
| B2 | Boot atteint le menu principal **seul** | assertion B2 |
| B3 | Le menu porte un bouton « Nouvelle partie » actionnable | assertion B3 |
| B4 | Le presser ouvre **réellement** la vallée | assertion B4, dans ses **deux** branches : avec et sans sauvegarde préalable |
| B5 | Un joueur vivant, posé sur un sol valide | assertion B5 |
| B6 | Caméra et HUD montés | assertion B6 |
| B7 | Le héros ne passe pas sous le monde | assertion B7 |
| B7b | Le héros **répond au monde** : soulevé, il retombe et se repose | assertion B7b |
| B8 | Une interaction ET un ennemi à portée de marche du spawn | assertion B8 |
| B9 | Mort par le chemin de dégâts réel, panneau, « Réessayer », héros vivant | B9, B9a, B9b, B9c |
| B10 | Arrêt sans nœud résiduel | assertion B10 |

**B7b existe à cause du contrôle négatif** : sans lui, tout le parcours restait
vert avec un héros figé. « Vivant, posé, HUD présent » ne prouve rien du
contrôle.

## B — Golden Path, le parcours long

Fichier : `tests/playthrough/test_golden_path.gd`

| # | Critère | Preuve |
|---|---|---|
| G1–G4 | Boot → menu → vallée → héros présent | assertions G1 à G4 |
| G5 | Un coffre s'ouvre **par l'interaction** et donne un objet réel | assertion G5 |
| G6 | Un ennemi encaisse par le chemin de dégâts réel | assertion G6 |
| G7 | Une capacité de Résonance s'exécute depuis le monde chargé | assertion G7 |
| G8 | La porte de la citadelle est franchissable, le vestibule s'ouvre | G8, G8b |
| G9 | La porte du donjon mène à la salle 1 | G9, G9b |
| G10+ | Salles 2-4, salle centrale, antichambre, boss, victoire | **NON VÉRIFIÉ** — non couvert par ce parcours |

Ce que le pilote s'interdit, et qui rendrait sa preuve fausse : téléporter au
delà d'un obstacle, appeler une fonction de récompense, instancier le boss hors
du flux, court-circuiter une condition. Il peut accélérer une attente ; jamais
sauter une étape.

### Ce que ce parcours ne prouve PAS, et qu'il serait malhonnête de laisser croire

**Le voyage.** Le pilote appelle `interact()` sur un coffre à 86 m et sur une
porte à 344 m, et `SceneDoor.interact()` ne vérifie aucune distance — la portée
est appliquée par l'`InteractionComponent` du joueur, pas par la porte. Le
parcours prouve donc que le **graphe de transitions** est câblé ; il ne prouve
jamais que le héros puisse parcourir les 344 mètres. Un ravin, un trou de
collision ou une falaise infranchissable au milieu du chemin le laisserait vert.

Aucun test du dépôt ne fait **marcher** le héros dans la vallée : tous le
posent. `test_interaction_reachable.gd` couvre bien « le joueur debout devant
l'objet voit l'invite » — en le plaçant, pas en l'y amenant. Le trajet entre
deux points de la vallée est le seul maillon du contrat que rien ne surveille,
et c'est exactement là que les défauts rapportés par le propriétaire se sont
logés (« je tombe à travers le sol ici »).

C'est la même faute que celle dénoncée en tête de ce document, d'un cran plus
haut : un test de câblage n'est pas une preuve d'atteignabilité.

## C — Ce qu'aucun test headless ne peut prouver

Ces critères restent **`BLOQUÉ`** tant qu'une personne ne les a pas essayés.
Aucun résultat automatique ne les fera passer.

| Critère | Pourquoi |
|---|---|
| « Je comprends quoi faire » | compréhension, pas exécution |
| Le ressenti de la caméra et de la souris | aucun écran, aucune souris |
| `Q` réellement à gauche sur un AZERTY physique | `physical_keycode` est testé ; l'appui ne l'est pas |
| La manette | dette `CONTROLLER-001`, aucune manette |
| La lisibilité du HUD | aucun écran |
| Le son | aucun périphérique audio |
| Les FPS | rendu logiciel llvmpipe, jamais un budget de frame |

Protocole prêt à exécuter : `docs/BOOT_TO_FUN_HUMAIN.md`.

## D — Comment ce contrat échoue

Le gate doit **échouer fermé**. Une étape non exécutée n'est jamais verte :

- une borne d'attente épuisée fait `FAIL`, elle ne fait pas pendre le test ;
- `tools/gate_negative_control.sh` refuse de conclure si un sabotage ne casse
  rien, ou si le filtre ne sélectionne aucun test ;
- une erreur de script pendant un test est attrapée par le garde-fou ISS-027 du
  journal, même si aucune assertion ne rougit.

### Quatre faux témoins déjà rencontrés, gardés ici pour qu'ils ne reviennent pas

1. **Un test absent du worktree** comptait comme « le gate a vu le sabotage ».
2. **`set -o pipefail` + un tube** : le code retour lu était celui de Godot, qui
   sort non nul sur une fuite de ressources. Même famille que `cmd | tail`.
3. **Saboter une valeur par défaut de script** alors que la `Resource` `.tres`
   l'écrase : le sabotage ne cassait rien, et le vert du gate était correct
   pendant que le contrôle criait « faille ». L'équilibrage de ce dépôt vit
   dans des `Resource` (§5.4).
4. **Deux verts en isolation valant pour un vert de suite.** Les deux parcours
   passaient seuls et faisaient sortir `validate_fast.sh` en ROUGE : le court
   laissait la vallée dans l'arbre, et `test_dungeon_run` démarrait dedans
   trente fichiers plus loin — dix-sept assertions tombaient pour une faute qui
   n'était pas la leur. Un parcours ne se juge que **dans la suite complète**
   (`tests/CLAUDE.md`).

Chacun de ces quatre aurait produit un verdict inversé.
