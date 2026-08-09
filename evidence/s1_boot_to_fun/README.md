# Preuves S1 — gate BOOT-TO-FUN, après la DEUXIÈME passe d'audit

| | |
|---|---|
| Code éprouvé | `137034f5d89fae1c63e6fbdb8690cacc5ecec1f1` |
| Branche | `claude/world-of-claudecraft-advice-snt1qa`, **poussée** |
| Base de cette passe | `f2cdc0b80f8e401cb585d99f057fd6c7cda45cbc` |
| Arbre pendant les exécutions | propre — `git status --porcelain` vide, `git diff --check` muet |
| Godot | `4.7.1.stable.custom_build.a13da4feb` · `forward_plus` · headless · Jolt 60 Hz |
| Date | 2026-08-09 |

## Le verdict, en trois lignes qui ne se remplacent pas

| Question | Verdict | Pourquoi |
|---|---|---|
| **Gate automatique actuel** | **`FAIL`** | `P9c` échoue : l'invite est muette au centre de la porte du donjon |
| **Couverture BOOT-TO-FUN complète** | **`NON VÉRIFIÉ`** | salles 2-4, salle centrale, antichambre, boss, victoire jamais atteints depuis le flux normal |
| **Critères humains** | **`BLOQUÉ`** | ni écran, ni clavier, ni manette, ni son, ni GPU |

**Verdict global : `FAIL`** — un `FAIL` l'impose, quels que soient les autres.
Il ne deviendra `NON VÉRIFIÉ` qu'une fois `P9c` corrigé, et `PASS` seulement
après la couverture complète **et** le protocole humain.

## Résultats

| Fichier | Commande | Résultat |
|---|---|---|
| `validate_fast.log` | `tools/validate_fast.sh` | **812 réussis / 1 échoué — ROUGE, code 1** |
| `boot_smoke.log` | `--filter=boot_smoke` | 1/0, 21 assertions |
| `flow_wiring.log` | `--filter=flow_wiring` | 1/0, 20 assertions |
| `physical_run.log` | `--filter=physical_run` | **0/1** — `P9c` seul |
| `restore_root.log` | `--filter=restore_root` | 6/0, six cas adverses |
| `anti_poison_sequentiel.log` | 6 fichiers chargeant un monde, à la suite | 11/1 — aucune contamination |
| `controle_negatif.log` | `tools/gate_negative_control.sh` | 2 déclarés, 2 exécutés, **0 ignorés**, 2 validés, code 0 |
| `controle_negatif_AUTOTEST.log` | signature fausse + fichier absent | **code 1** — les garde-fous mordent |
| `physical_run_INSTRUMENTE.log` | recorder rallongé d'un `print` | **lecture, pas preuve** — arbre sale |

L'unique échec de toute la suite est `P9c`. Aucune fuite de ressources, aucun
`SCRIPT ERROR`.

## Ce que le parcours physique a mesuré

- **11/11** jalons de crête, **5/5** de la route du donjon ;
- coffre **`RiverChest`** ouvert par `interact_pressed` à 0,79 m, cos 0,98 —
  inventaire **1 → 2 armes** ;
- **4 touches** portées par `attack_pressed`, ennemi à 0,7 m, instigateur du
  dégât = le joueur ;
- `pulse_pressed` → **1 cible révélée**, pas seulement le verdict « fired » ;
- **`P11` : 5 621 ticks physiques échantillonnés**, min y = 0,00 (seuil −5,0),
  plus grand saut de position **0,52 m** en un tick (seuil 3,0). « Jamais sous
  le monde » est désormais une mesure, pas une affirmation ;
- salle 1 atteinte à pied après **un** repositionnement.

## Le défaut : la porte du donjon est MUETTE au centre

```
P9c   mode=0, sol=true
      [d=0.75 m (max 2,20) · cos=1.00 (min 0,25)
       · groupe=true · vue=SealedSeam · choisi=aucun]
```

À 75 cm, parfaitement en face, au sol, la porte dans le groupe `interactable` :
`_select_interactable()` ne rend rien. Le rayon de `_has_interact_los()` est
coupé par `SealedSeam`, une veine cyan décorative en `StaticBody3D` sur la
**couche 1** à `z = −12,50` (`citadel_vestibule.gd`, helper `_box`), devant le
battant à `z = −12,75`.

La contre-épreuve est dans le même journal : après un pas de côté de 1,5 m,
`vue=libre · choisi=DungeonDoor` et la salle 1 s'ouvre. Le décor coupe donc
l'interaction **à l'endroit exact où un joueur se place**, et nulle part
ailleurs.

C'est la signature du défaut nº 1 du playtest humain du 2026-08-07 : le joueur
appuie sur `E`, n'obtient rien, conclut que la touche ne marche pas.

**Non corrigé, sur consigne.** C'est du jeu, donc S2.

## Deux intermittents corrigés dans cette passe — aucun dans le jeu

**1. Une borne qui exigeait une machine RAPIDE.** `B4` a rougi dans la suite
complète après être passé seul. En headless, `SceneFlow._load_and_swap()` prend
le chemin synchrone : la frame de chargement dure plusieurs secondes et
`get_process_delta_time()` les compte. `GateTestCase.await_scene()` borne
désormais l'ORDRE (6 s) et l'APPARITION (15 s), jamais le chargement — dont le
garde de 600 s est un filet anti-blocage, pas un budget.

**2. Un appui avalé en silence.** `B4` a rougi une seconde fois, et le journal
ne montrait rien : ni avertissement, ni vallée. Cause lue dans le code —
`SceneFlow.can_go_to()` rend faux tant que `_busy`, et
`MainMenu._enter_valley()` se contente alors d'écrire « Vallée indisponible »
dans un libellé. Ni `push_warning`, ni `push_error`, ni transition. Or `_busy`
ne retombe qu'après le fondu de sortie : `MainMenu` existe pendant que le flux
est encore occupé. Le pilote pressait dans cette fenêtre.

Un joueur ne rencontre pas ce cas — le voile noir couvre l'écran pendant ce
laps. Le pilote l'imite : `await_flow_idle()` avant chaque appui de menu, et un
critère `B3b` le rend visible.

## Ce que la deuxième passe a durci

- **`restore_root()` vérifie les deux directions** : rien en trop, **rien en
  moins**. Nœud photographié disparu ou remplacé par un homonyme → verdict faux
  et disparu nommé. `current_scene` traitée à part — un `current_scene` perdu ne
  se voit dans aucune liste d'enfants. Motifs cumulés.
- **`test_runner.gd`** : photo par `instance_id`, détection des racines ajoutées
  **et** supprimées ou remplacées, message distinct pour chacun. Éprouvé en
  worktree jetable : retirer `AudioManager` produit « fait DISPARAÎTRE
  AudioManager (supprimé) de la racine ».
- **Sur-promesses retirées.** `P4` sélectionne un **vrai coffre** et exige
  l'effet d'inventaire. `B8` dit « présent dans un rayon euclidien » et que la
  route n'est pas éprouvée. `B9` dit « câblage `HealthComponent` → mort →
  panneau → reprise » ; le combat réel n'est prouvé que par `P5`.
