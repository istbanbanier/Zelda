# Preuves S1 — gate BOOT-TO-FUN, après l'audit indépendant du 2026-08-09

| | |
|---|---|
| Code éprouvé | `edbd67d3ca35be91b15fa0d32a235bee2cb57f58` |
| Branche | `claude/world-of-claudecraft-advice-snt1qa`, **poussée** |
| Base de l'audit | `327f566d96d20186260be4e053ce85886846ab67` |
| Arbre pendant les exécutions | propre — `git status --porcelain` vide, `git diff --check` sans défaut |
| Godot | `4.7.1.stable.custom_build.a13da4feb` · `forward_plus` · headless · Jolt 60 Hz |
| Date | 2026-08-09 |

Les journaux de ce dossier sortent du code ci-dessus. Le commit qui les verse
vient juste après, comme l'exige `.claude/rules/evidence.md` : commiter le code,
capturer, commiter la preuve.

## Verdict global : **NON VÉRIFIÉ**

Et il le reste. Deux parcours verts ne font pas un jeu jouable :

- salles 2 à 4, salle centrale, antichambre, boss et victoire ne sont **jamais
  atteints depuis le flux normal** — `test_dungeon_run` et `test_boss_run` les
  chargent directement, ce qui prouve la solvabilité, jamais l'arrivée ;
- caméra, compréhension de l'objectif, lisibilité du HUD, son, manette et FPS
  restent hors de portée de ce conteneur ;
- `P9c` **échoue** sur un défaut réel du jeu, décrit plus bas.

## Ce que chaque journal prouve

| Fichier | Commande | Résultat |
|---|---|---|
| `validate_fast.log` | `tools/validate_fast.sh` | **809 réussis / 1 échoué — ROUGE, code 1** |
| `boot_smoke.log` | `--filter=boot_smoke` | 1/0, 20 assertions, code 0 |
| `flow_wiring.log` | `--filter=flow_wiring` | 1/0, 20 assertions, code 0 |
| `physical_run.log` | `--filter=physical_run` | **0/1** — seul `P9c` rougit |
| `restore_root.log` | `--filter=restore_root` | 3/0, trois cas adverses |
| `anti_poison_sequentiel.log` | 5 parcours chargeant un monde, à la suite | 5/1 — aucune contamination croisée |
| `controle_negatif.log` | `tools/gate_negative_control.sh` | 2 déclarés, 2 exécutés, **0 ignorés**, 2 validés, code 0 |
| `controle_negatif_AUTOTEST.log` | même script, signature fausse + fichier absent | **code 1** — les nouveaux garde-fous mordent |

809 = 806 avant + 3 cas adverses de `restore_root`. Le seul échec est le défaut
ci-dessous ; aucune régression.

## Le défaut trouvé : la porte du donjon est MUETTE au centre

```
P9c — l'invite répond DEVANT la porte, au centre du battant
      mode=0, sol=true
      [d=0.75 m (max 2,20) · cos=1.00 (min 0,25)
       · groupe=true · vue=SealedSeam · choisi=aucun]
```

Debout à 75 cm de la porte du donjon, parfaitement en face, au sol, en
locomotion, la porte bien dans le groupe `interactable` :
`PlayerController._select_interactable()` ne rend **rien**.

Cause mesurée : le rayon de `_has_interact_los()` est coupé par `SealedSeam`,
une veine cyan décorative construite en `StaticBody3D` sur la **couche 1** à
`z = −12,50` (`citadel_vestibule.gd`, helper `_box`), devant le battant à
`z = −12,75`. Le décor coupe l'interaction à l'endroit exact où un joueur se
place.

Un pas de côté suffit à ouvrir : `P9b` passe. La porte est **muette, pas
condamnée**. C'est la signature du défaut nº 1 du playtest humain du
2026-08-07 — le joueur appuie sur `E`, n'obtient rien, conclut que la touche ne
marche pas et cesse d'essayer.

**Non corrigé ici.** C'est un défaut de jeu, donc S2. S1 s'arrête à le prouver.

Aucun test d'appel direct ne pouvait le voir : `flow_wiring_path` franchit la
même porte en vert, parce qu'il appelle `SceneDoor.interact()` sans passer par
la sélection du joueur.

## Ce que le parcours physique a réellement joué

Tout par `InputIntent` et le `PlayerController` — jamais une écriture de
`global_position`, jamais la méthode finale d'une cible, aucun ennemi retiré :

- **11/11** jalons de la descente de crête, **> 100 m** parcourus, jamais sous
  le monde ;
- un coffre rejoint à pied et ouvert par `interact_pressed` ;
- un ennemi **poursuivi** puis frappé par `attack_pressed`, l'instigateur du
  dégât étant le joueur ;
- `pulse_pressed` avec **`revealed_count > 0`**, pas seulement le verdict
  « fired » ;
- **5/5** jalons de la route du donjon, héros vivant ;
- le seuil de la citadelle atteint à pied, le vestibule ouvert à la touche ;
- la salle 1 atteinte à pied, après un pas de côté.

C'est le premier parcours du dépôt à enchaîner les deux moitiés de la route sans
la téléportation qui les séparait (`test_bestiary_gate` plaçait le joueur en
`(0, 2.5, −20)`).

## Cinq défauts trouvés en chemin — quatre au pilote, un au jeu

Un test qui joue mal accuse le jeu à tort. Consignés pour qu'ils ne reviennent
pas :

1. `ResonanceTargetComponent extends Node`, pas `Node3D` : le cast rendait null
   pour toutes les cibles, et le test concluait « aucune cible de Résonance dans
   le monde ».
2. `Mode.ATTACKING` vaut **3**, pas 2 : le compteur d'attaques engagées lisait
   `MANTLING`.
3. Une lambda GDScript capture les locales **par valeur** : `opened = true`
   depuis le rappel modifiait la copie, et le test accusait le coffre de ne pas
   s'ouvrir pendant que l'état du coffre disait « déjà ouvert=true ».
4. Viser la position figée d'un ennemi vivant : quatre attaques engagées, zéro
   touche, l'ennemi à 5,5 m. Il faut le poursuivre.
5. **Au jeu** : `SealedSeam`, ci-dessus.

## Fuites de fin de processus

Mesurées avec `--verbose` : `2 ObjectDB instances were leaked`
(`AudioStreamPlaybackWAV`, `AudioStreamWAV`) et
`Resource still in use: amb_valley.wav`.

Cause : `ValleyWorld._ready()` demande `AudioManager.play_ambience()`, et
`AudioManager` est un **autoload** — son lecteur survit à la vallée. Ce n'est
pas une fuite de gameplay ; c'est un test qui ne rendait pas le processus tel
qu'il l'avait trouvé. Les trois parcours S1 arrêtent maintenant l'ambiance dans
leur nettoyage, et plus aucune ligne de fuite n'apparaît.

Comparaison avec `d52e5fb` : les tests qui chargent la vallée **directement**
(`test_valley_world`, 9 cas) n'ont jamais produit ces lignes, et la suite
complète non plus. La fuite n'apparaissait que sur un parcours isolé passant par
`Boot` et `SceneFlow` — c'est-à-dire sur du code S1.

Le gate les ignorait : `validate_fast.sh` couvrait `^ERROR:` sur tout le
journal, verdict interne compris, mais « ObjectDB instances were leaked » est un
**WARNING**. Les deux motifs sont entrés dans le filtre.
