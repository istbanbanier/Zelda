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

## Le verdict, en trois lignes qui ne se remplacent pas

Les confondre serait la sur-promesse suivante. Elles répondent à trois questions
différentes, et se lisent ensemble.

| Question | Verdict | Pourquoi |
|---|---|---|
| **Gate automatique actuel** — ce que la machine exécute aujourd'hui rend-il vert ? | **`PASS`** | suite complète verte depuis la correction de `P9c` (S2.0) |
| **Couverture BOOT-TO-FUN complète** — l'ensemble du parcours est-il éprouvé ? | **`NON VÉRIFIÉ`** | salles 2-4, salle centrale, antichambre, boss et victoire ne sont jamais atteints depuis le flux normal |
| **Critères humains** — écran, mains, oreilles | **`BLOQUÉ`** | ni écran, ni clavier, ni manette, ni son, ni GPU dans ce conteneur |

**Verdict global : `NON VÉRIFIÉ`**, par la règle du plus faible critère. Un gate
vert ne dit pas que le jeu est jouable : il dit que rien de ce qu'on sait
mesurer n'est cassé. Il ne deviendra `PASS` qu'après la couverture complète
**et** le protocole humain.

## Commandes

```bash
tools/gate_negative_control.sh            # le gate sait-il rougir ?
godot --headless --path . --script tools/godot/test_runner.gd -- --filter=boot_smoke
godot --headless --path . --script tools/godot/test_runner.gd -- --filter=flow_wiring
godot --headless --path . --script tools/godot/test_runner.gd -- --filter=physical_run
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
| B8 | Une interaction ET un ennemi **présents dans un rayon euclidien** du spawn | assertion B8 — la ROUTE n'est pas éprouvée ici ; `P3`/`P4` s'en chargent |
| B9 | **Câblage** `HealthComponent` → mort → panneau → « Réessayer » → héros vivant | B9, B9a, B9b, B9c — **aucun combat** ; le combat réel est `P5` |
| B10 | Arrêt sans nœud résiduel | assertion B10 |

**B7b existe à cause du contrôle négatif** : sans lui, tout le parcours restait
vert avec un héros figé. « Vivant, posé, HUD présent » ne prouve rien du
contrôle.

## B — Parcours de CÂBLAGE (`flow_wiring_path`)

Fichier : `tests/playthrough/test_flow_wiring_path.gd`
Ce fichier s'appelait `test_golden_path.gd`. L'audit du 2026-08-09 a refusé ce
nom : appeler « golden path » une suite d'appels directs à `interact()`
annonçait une couverture inexistante.

**Ce parcours prouve des FILS, pas un trajet.** Chaque cible est saisie dans le
groupe `interactable` et sa méthode est appelée là où elle est, fût-elle à
344 m. Rien ne marche, rien ne vise, rien n'appuie sur une touche.

| # | Critère | Ce qui est prouvé | Ce qui ne l'est PAS |
|---|---|---|---|
| W1–W4 | Boot → menu → `SceneFlow` → vallée avec joueur | la chaîne de scènes | — |
| W5 | `Chest.interact()` → inventaire (+1 arme) | le fil coffre→inventaire | portée, cône, ligne de vue, accès |
| W6 | `HealthComponent.take_damage()` → PV décomptés | la comptabilité des PV | **aucune hitbox, aucun combat** |
| W7 | `try_pulse()` rend `fired` | le contrôleur est monté | **aucun effet observable** |
| W8 | `SceneDoor.interact()` → vestibule | le fil porte→`SceneFlow` | **aucune distance n'est vérifiée** |
| W9 | idem → salle 1 | idem | idem |
| W10 | la racine est rendue intacte | `restore_root()` conclut sans réserve | — |

## B2 — Parcours PHYSIQUE (`physical_run`)

Fichier : `tests/playthrough/test_physical_run.gd`

Tout passe par `InputIntent` et le `PlayerController` — la même porte d'entrée
qu'un clavier ou une manette (D-013). Interdits : écrire `global_position`,
appeler la méthode finale d'une cible, retirer un ennemi de la route.

| # | Critère | Preuve |
|---|---|---|
| P1–P2 | Menu → vallée → héros posé, piloté par `InputIntent` | P1, P1b, P2 |
| P3 | La descente de crête se **marche** en entier | 11/11 jalons, > 100 m |
| P11 | Sur **chaque tick physique** du parcours : jamais sous le monde, aucune discontinuité de position | min y et plus grand saut mesurés, pas affirmés |
| P4 | Un **coffre** est rejoint à pied, ouvert par `interact_pressed`, et l'inventaire en porte la trace | P4 |
| P5 | Un ennemi est **poursuivi** et frappé par `attack_pressed` | touches réelles, instigateur = joueur |
| P6 | `pulse_pressed` révèle **au moins une cible** (`revealed_count > 0`) | P6 |
| P7 | La route du donjon se **marche** en entier, héros vivant | 5/5 jalons |
| P8 | La porte de la citadelle est atteinte à pied et ouverte à la touche | P8, P8b |
| P9b | La salle 1 est atteinte **à pied** depuis le menu | PASS |
| P9c | L'invite répond **au centre du battant** du donjon | PASS depuis S2.0 — voir ci-dessous |
| P9d | **Aucun** repositionnement latéral n'est nécessaire | PASS — le filet ne sert jamais |

### Ce que ce parcours a trouvé — et qui est corrigé depuis

`P9c` a échoué pendant deux passes d'audit, sur une cause mesurée : debout à
0,75 m de la porte du donjon, parfaitement en face (`cos = 1,00`), au sol, en
locomotion, porte bien dans le groupe `interactable` — `_select_interactable()`
ne rendait **rien**. Le rayon de `_has_interact_los()` était coupé par
`SealedSeam`, une veine cyan **décorative** construite en `StaticBody3D` sur la
**couche 1** à `z = −12,50` (`citadel_vestibule.gd`), devant le battant à
`z = −12,75`.

Le décor coupait l'interaction **à l'endroit exact où un joueur se place**, et
nulle part ailleurs : un pas de côté rendait la porte sélectionnable. C'est la
signature du défaut nº 1 du playtest humain du 2026-08-07 — le joueur appuie sur
`E`, n'obtient rien, conclut que la touche ne marche pas et cesse d'essayer.

**Corrigé en S2.0** par `_decor_box()` : un ornement produit un `MeshInstance3D`
seul, sans corps ni forme de collision. La veine garde géométrie, position et
émission ; elle perd son statut d'obstacle. Aucune constante d'interaction n'a
bougé, aucune exception n'a été ajoutée au contrôleur.

La régression est épinglée par
`tests/integration/test_dungeon_door_is_reachable_at_centre.gd` — treize
assertions, dont `current_interact_target() == DungeonDoor` **par identité** —
et par `P9d`, qui exige **zéro repositionnement latéral** : sans lui, un retour
du défaut serait absorbé par le filet du pas de côté et `P9b` resterait vert.

Aucun test d'appel direct ne pouvait voir ce défaut : `test_flow_wiring_path`
franchit la même porte en vert, parce qu'il appelle `SceneDoor.interact()` sans
passer par la sélection du joueur. C'est exactement ce que le parcours physique
a été construit pour attraper.

| Portée restante | État |
|---|---|
| Salles 2-4, salle centrale, antichambre, boss, victoire | **NON VÉRIFIÉ** — hors des deux parcours |

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
- `restore_root()` et le runner vérifient la racine **dans les deux sens** :
  rien en trop, **rien en moins**. Un test qui libère un nœud photographié ou le
  remplace par un homonyme laissait une racine « propre » et un verdict vrai ;
  `current_scene` est traitée à part, parce qu'un `current_scene` perdu ne se
  voit dans aucune liste d'enfants ;
- `tools/gate_negative_control.sh` refuse de conclure si un sabotage ne casse
  rien, ou si le filtre ne sélectionne aucun test ;
- une erreur de script pendant un test est attrapée par le garde-fou ISS-027 du
  journal, même si aucune assertion ne rougit.

### Six faux témoins déjà rencontrés, gardés ici pour qu'ils ne reviennent pas

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

5. **Un pilote plus mauvais qu'un joueur.** Le parcours physique poussait tout
   droit et s'arrêtait contre le décor : 4 jalons sur 11, et l'accusation aurait
   porté sur le terrain. Un joueur oblique, saute, s'écarte puis revient. Une
   fois le pilote doté de ces trois gestes, 11/11 puis 5/5. Un test qui joue mal
   accuse le jeu à tort — même famille que le cast raté qui déclarait « aucune
   cible de Résonance dans le monde ».

6. **Une affirmation « jamais » échantillonnée onze fois.** Le parcours physique
   relevait la hauteur une fois par jalon — onze photos pour plus de cent
   mètres — et écrivait « jamais sous le monde ». Un héros qui traverse le sol
   et qu'un filet remonte entre deux jalons passait inaperçu. La mesure est
   maintenant prise à chaque tick physique, et le plus grand saut de position
   d'un tick à l'autre est surveillé : un secours ou un respawn déplace de
   plusieurs mètres là où le sprint fait 0,15 m.

Chacun de ces six aurait produit un verdict inversé.
