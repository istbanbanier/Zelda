# R2a-3.5.8 — rapport final du lead

Date : 2026-08-18. Statut du couloir technique : **PASS**. Statut artistique :
**AUCUN VERDICT AUTO-DÉCLARÉ** — revue Codex/Istvan requise (§8).

## Ce qui a été fait, en une phrase

Les 4 auto-intersections du collider (repli 0,2434 m, 12× le seuil livrable)
sont à **zéro sur le binaire exporté**, en une itération de géométrie sur un
budget de trois, sans toucher un octet du maillage visuel validé, et le
candidat complet est committé sous `candidates/` sans remplacer la production
R2a-3.4.

## Chaîne de preuve (chaque maillon reproduit par le lead)

| Maillon | Preuve | Où |
|---|---|---|
| Provenance source | 102cc33d (reconstruit indépendamment par C, byte-identique) + delta 750151d5 = 28535fb3, vérifié aller ET retour | `integration/patch_*.log` |
| Adaptations d'intégration | déclassement télémétrie (#91, cca1778/28fa140) + nom de .blend — deux pièces, montrées au diff | commit `4a51e3b` |
| Reproductibilité binaire | export rejoué deux fois (worktree propre puis arbre committé) : GLB byte-identique `5ff4ec6e…` les deux fois | `integration/export_*.log` |
| Collision | juge du tronc : COL zéro pénétration réelle ; SM 6 coutures préexistantes 0,000612 m (33× sous seuil, jugées 3.5.7) | `integration/ctrl_exact.log` |
| Paroi invisible / poche | contrôle spécialisé (a9f1a6fb) : champ sous 0,061 ; capsule jamais bloquée dans du vide ; poche 0,5828 ≥ 0,524 | `integration/ctrl_paroi.log` |
| Fil du couteau | reproduction lead à instrument indépendant : direction publiée retrouvée (écarts ≤ 3 cm), secteur alcôve culminant exactement à la direction de la jauge | `repro_poche/journal.log` |
| Traversabilité | agent B : T1 canonique courbe 0 faute, T2 capsule au chiffre près du relevé 3.5.7, T3 champ + fonctionnel + niche, 4 contrôles négatifs rouges au bon endroit | arbre B, `final/05_TABLEAU_VERDICTS.md` |
| Identité visuelle | SM bit-identique à la baseline sous TROIS instruments (session 3.5.7, outil lead, outil C) | checkpoint 4 |
| Moteur | boot→WorldV2, caméra du rig par égalité d'identité, avec ET sans bascule | `scratchpad` + commit `a2c000e` |
| Captures | 15 vues llvmpipe d'arbre committé (`repo_dirty:false`), inspectées une à une ; 4 montages A/B contre R2a-3.4 ; « collision » = tracé d'instrument, jamais capture | `r2a358_candidat/` |

## Les deux écarts consignés de la passe

1. **Poche rétrécie par conception** : la profondeur de poche en collision
   passe de 1,065 (pré-correctif) à 0,583 — prix arbitré du zéro
   pénétration ; le plancher de conception (0,524) est tenu, l'atteinte de la
   niche inchangée. Chiffre au dossier, pas un blocage.
2. **Caméras intérieures périmées** (5ᵉ récidive du piège des caméras) : les
   vues 04/05 dérivaient des ancres R2a-3.4 ; re-dérivées sur les ancres
   candidates (`47f3a2e`) après inspection pleine taille. La leçon reste :
   une caméra héritée se vérifie contre les ancres de la révision qu'elle
   prétend montrer.

## Ce que ce rapport ne dit PAS

Il ne dit pas que la grotte est belle, ni qu'elle vaut mieux que R2a-3.4 : la
question visuelle est relayée au propriétaire et à Codex, sans réponse du
lead. Il ne dit pas que le candidat est actif : `assets/environment/caves/
SM_WaterfallCave.glb` reste `8bf1a1b3` (R2a-3.4) sur tout chemin de jeu.

## Validation finale §9

Suite world_v2 : 56/56. Boot smoke : 23 assertions, avec et sans bascule.
`git diff --check` propre. `validate_fast.sh` : **904/904 tests verts, verdict
ROUGE (RC=1)** sur le filtre des diagnostics de sortie — fuites de fin de
processus **préexistantes, mesurées identiques à la base `0b0ef54`** (suite
complète rejouée là-bas : mêmes comptes, zéro commit de la passe présent).
Consigné ISS-059 ; un rouge préexistant ne se rebaptise pas vert, et il
n'appartient pas aux gates de la grotte. Journaux :
`r2a358_lead/validation/`.

## NON VÉRIFIÉ

Rendu GPU réel (llvmpipe seulement ici) · niveaux 6-7 (perf, soak, export) ·
tests manuels §21.4 · verdict artistique.
