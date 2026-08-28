# T1 — la reprise de partie, prouvée dans la BUILD EXPORTÉE

Date : 2026-08-28 · branche `claude/world-v2-t1-persistance` · arbre de jeu
committé `a168dfd5` (le binaire local y est lié par `contexte.json`).

## La chaîne, dans l'ordre exécuté

| Étape | Verdict | Journal |
|---|---|---|
| `validate_fast.sh` sur l'arbre committé | **VERT, RC=0, 987 tests, 0 échec**, gel intact | `validate_fast_final.log` |
| `gate_export_parite.sh` (export Linux NEUF + 32 contrôles ISS-071) | **RC=0**, 0 rouge, 0 bloqué, 0 non vérifié | `gate_parite_t1.log` |
| `gate_export_t1.sh` (6 phases, profils `user://` vierges/fabriqués) | **RC=0, 21 PASS, 0 FAIL** | `gate_t1.log` |

## Ce que le portail T1 a MESURÉ dans le binaire autonome

- **P1** — partie neuve : spawn correct, marche RÉELLE tenue au clavier
  (103,29 m écrits), puis la CROIX de la fenêtre : le processus meurt seul et
  la sauvegarde écrite est signée `neris_v2`, checkpoint `world_v2.valley`.
- **P2** — relance, « Continuer » : provenance `sauvegarde`, position
  restaurée à **0,00 m** d'écart, orientation restaurée (-3,14 écrit, -3,14
  posé). Captures : `t1_p2_reprise.png`.
- **P3** — slot fabriqué « arrêté dans l'antichambre » : le menu route vers
  `Antechamber.tscn` (ligne `[flow]` lue), montage à froid sans erreur.
- **P4** — slot riche : une écriture a RÉELLEMENT eu lieu (horodatage
  d'enveloppe ≠ valeur fabriquée), et `boss_defeated` + l'inventaire témoin
  ont survécu à l'autosave réel de la croix.
- **P5** — slot V1 (sans signature) avec position plausible : IGNORÉ,
  provenance `spawn`.
- **P6** — slot corrompu : refus lisible, processus vivant, fichier INTACT
  au sha256.

Déclaré **NON VÉRIFIÉ** par le portail lui-même : la marche jusqu'au donjon
et le retour (ISS-072), la mort puis « Réessayer » (ISS-074 : aucun
adversaire) — tous prouvés en éditeur par C1..C10.

## Les DEUX défauts de harnais que les runs 1 et 2 ont coûtés

Conservés parce qu'ils attendent quiconque pilote une build sous Xvfb :

1. **`xdotool windowclose` ne ferme pas une fenêtre, il la DÉTRUIT**
   (XDestroyWindow) : le jeu ne reçoit jamais la demande, le processus
   survit, rien n'est écrit (`gate_t1_run1_harnais_defaillant.log`). Ce même
   run a aussi montré un **faux déplacement de 170 m** fabriqué par
   `p.get("x", 0)` sur un slot SANS position — le portail rend désormais
   `nan` et échoue bruyamment.
2. **Godot interne `WM_DELETE_WINDOW` avec `only_if_exists=true`** : sur un
   serveur X vierge (aucun WM, aucun client passé), l'atome n'existe pas,
   Godot reçoit 0 et publie `WM_PROTOCOLS=[0]` — la croix est physiquement
   inopérante. Et sans `-noreset`, Xvfb se RÉINITIALISE quand son dernier
   client part, effaçant l'atome à peine interné
   (`gate_t1_run2_atome_absent.log`). Le portail interne l'atome avant le
   jeu, sur un Xvfb `-noreset`, et envoie le vrai ClientMessage
   WM_PROTOCOLS/WM_DELETE_WINDOW (`tools/x11_fermer_fenetre.py`). Sur un
   poste réel, le gestionnaire de fenêtres a toujours déjà interné l'atome —
   ce piège n'existe que dans un harnais nu.

## Observation d'horloge, à ne pas surclamer

Sur CE conteneur, la build a parcouru ~103 m en 90 s de mur (~1,15 m/s de
mur) — bien plus vite que le facteur 17-76 d'ISS-072 mesuré sur l'ancien
hôte. Une exécution, un hôte : c'est une observation, pas une révision
d'ISS-072.
