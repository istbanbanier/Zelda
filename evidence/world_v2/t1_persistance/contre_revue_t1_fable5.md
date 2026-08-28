# Contre-revue T1 — §1 de la décision lead du 2026-08-28, contexte frais, modèle Fable 5

Périmètre : `git diff a8d2f77..84fe2c0` (les quatre commits T1), lu
exclusivement par `git show` — l'arbre de travail était vivant pendant la
revue. Moteur jamais lancé (verrou tenu par la session principale) ; les
journaux committés de `evidence/world_v2/t1_persistance/` ont été recomptés
(115 assertions revérifiées ligne à ligne).

Ce fichier consigne le verdict et le SORT de chaque constat. Les corrections
elles-mêmes sont dans les commits qui suivent la revue sur cette branche.

## Les neuf points

| # | Point | Verdict | Sort |
|---|---|---|---|
| 1 | Branchement/débranchement du signal | PASS (sur lecture) | l'exécution réelle est désormais prouvée par C8, y compris le débranchement (slot intact après émission sur monde libéré) |
| 2 | Priorité retour-donjon / sauvegarde / spawn | PASS | — |
| 3 | Fusion du payload | **FAIL** | **fermé par C10** : un slot présent mais illisible (JSON tronqué OU schéma plus récent) n'est JAMAIS réécrit — rouge d'abord (2 échecs mesurés), garde posée, vert ensuite |
| 4 | Signature `world_version` | PASS (2 réserves) | réserve A fermée par C10 ; réserve B consignée **ISS-079** (latente, scène V1 inatteignable) |
| 5 | Routage par checkpoint | PASS (1 constat) | constat consigné **ISS-080** (antichambre réécrit l'inventaire par le kit par défaut — préexistant) |
| 6 | Mort et `retry_checkpoint` | PASS | — |
| 7 | Sauvegardes anciennes/corrompues | PASS | — |
| 8 | Chemin réel jamais testé + prose périmée | **FAIL** | **fermé par C8** (vraie transition `SceneFlow`, fusion éprouvée par témoins `boss_defeated`/`weapons`, reprise par le vrai bouton du menu, position ET orientation mesurées dans le monde remonté) ; prose corrigée aux trois endroits (en-tête, `_spawn_source`, `spawn_source()`) |
| 9 | Fermetures du jeu | **FAIL** | **fermé par C9** : handler `NOTIFICATION_WM_CLOSE_REQUEST` + minuterie d'autosave épinglée à 60 s + « jamais en l'air » (dernier sol foulé) — rouge d'abord (2 échecs mesurés) |

L'effet composé du point 9 (« fermer la fenêtre dans la vallée après un
retour de donjon fait router "Continuer" vers l'antichambre, car le
`checkpoint` du slot est resté `dungeon.antechamber` ») est fermé par la même
correction : la fermeture ET la minuterie réécrivent `checkpoint =
world_v2.valley` dans la minute qui suit le retour.

## Constat « à corriger » n° 3, précisé par la mesure

La revue notait : « remplacer `payload.merge(...)` par une affectation sèche
resterait vert ». C8 sème désormais `boss_defeated: true` et un témoin
`weapons` AVANT la vraie transition et asserte leur survie dans le slot
écrit : une affectation sèche rougit ces deux assertions.

## Détails non corrigés, tous consignés

- ISS-079 — autosave V1 sous signature V2 (latent, scène inatteignable) ;
- ISS-080 — inventaire par défaut au « Continuer » antichambre (préexistant) ;
- ISS-081 — tag d'apparition fantôme sur `go_to` échoué (préexistant) ;
- le lacet d'une sauvegarde V2 dont la POSITION est rejetée est tout de même
  restauré au spawn — comportement conservé, jugé « détail » par la revue.

## Verdict global du relecteur

« PARTIAL — prête pour une build expérimentale, avec deux conditions avant
livraison » : la garde du slot illisible (C10) et la fermeture de fenêtre
(C9). Les deux sont fermées sur cette branche, rouge d'abord, avant tout
export.
