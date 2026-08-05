# PROMPT2_AUDIT — Audit d'entrée du Prompt 2 (P2-0)

Date : 2026-08-05 · Arbre : `7a4ba85` · Godot 4.7.1-stable custom_build vérifié.
Baseline visuelle : `evidence/phaseH/vista_h8_verdict.png` (+ pack de revue).
Baseline performance : IMPOSSIBLE ici (llvmpipe — R-004) ; sera faite machine
utilisateur. Chemin critique rejoué : golden path 4/4 VERT le 2026-08-05
(boss vaincu avec loot garanti, donjon vierge + reprise, traversal sans
softlock).

## Matrice d'état (format P2 §1)

| Domaine | État actuel | Preuve | Risque | Action | Gate |
|---|---|---|---|---|---|
| Boot/import | VERT — boot→menu→vallée, 0 parse error (233 scripts) | `validate_fast` sérialisé 2026-08-05 (611/623, 12 rouges = test recalé depuis) | dérive d'arbre pendant suites (R-017) | sérialiser, ISS-024 | P2-0 ✔ |
| Boucle complète | VERT automatisé — spawn→camp→donjon→boss→victoire | suites playthrough 4/4 | jamais rejouée par un HUMAIN depuis H-3/H-5 (terrain remanié) | playtest utilisateur sur release `playtest-65709df` | P2-0 ✔ |
| Mouvement/caméra | Fonctionnel, tuning data-driven, mercy/hit-stop/knockback récents | 600+ tests ; TESTS.md | latences jamais instrumentées (P2-1) ; pas d'InputLab/TraversalLab dédiés | P2-1 | P2-1 |
| Combat | Base C complète + fenêtre mercy + hit-stop ; PAS de garde/déviation/posture | tests C + fail-first récents | expressivité limitée à l'esquive ; 6 armes peu différenciées | P2-3 | P2-3 |
| IA | 5 familles, FSM, perception LOS, coordinateur simple | 107 assertions transverses | pas d'utility scoring, pas de tokens formels, pas de bruit/diversion | P2-3 | P2-3 |
| Récolte/cuisine | Gate E accepté (chaîne complète testée) | GATE_E_AUDIT | préparation tactique (P2 §6.4) non faite | P2-4 | P2-4 |
| Électricité/énigmes | Gate F accepté, graphe + 4 salles + solveur | GATE_F_AUDIT | pas de lois matériaux communes (ReactionSystem) — chaque salle a sa logique | P2-2/P2-5 | P2-2 |
| Boss | Gate G accepté (3 phases, solvabilité) | GATE_G_AUDIT | patterns sans director tagué ; scripts par phase | P2-5 | P2-5 |
| Sauvegarde | Schéma v4, merge, vitals, migrations testées | tests save/merge | liaisons Bracelet futures à persister | P2-2+ | ✔ |
| Visuel/anim/audio | Phase H : Gate FAIL formel (31-41/100), 9 sons placeholder | TEST_REPORT 2026-08-05 | cf. cadence Cycle 3 | V3-V9 | H |
| Performance | NON MESURABLE ici | R-004 | promesses interdites | machine utilisateur | I |
| Accessibilité | Remap partiel, rien de §12.3 P2 | audit V0 | chantier entier | P2-7 | P2-7 |
| Licences | Quaternius CC0 + généré + coursier en cours | ATTRIBUTIONS, SOURCING_MATRIX | packs coursier à vérifier À L'ARRIVÉE avant promotion | continu | ✔ |

## LE constat central

**Le Bracelet de Résonance n'existe pas** (zéro ligne de code — vérifié), ni
`MaterialProfile`/`ReactionSystem`, ni InputMap `resonance_*`. C'est la
mécanique signature (P2 §3), déclarée incoupable par l'échelle de réduction
P2 §18. Tout le reste du Prompt 2 s'y accroche.

## Backlog P2 ordonné (impact × risque × dépendance)

1. **P2-1** — instrumentation des latences + InputLab/TraversalLab (fondation
   de mesure, faible risque, débloque les gates chiffrés de P2).
2. **P2-2** — Bracelet : `MaterialProfile` + `ElementPacket` + `ReactionSystem`
   d'abord (les LOIS), puis Pulse → Arc Link → Polarité → Arc Step → Ground,
   chacun fail-first dans un `ReactionLab`. LE chantier (~4-6 sessions).
3. **P2-3** — défense expressive (garde/déviation/posture) + identités
   d'armes + IA utility/tokens ; camp trois approches.
4. **P2-4** — routes nommées, POI Bracelet-dépendants, infiltration/bruit.
5. **P2-5** — migration donjon/boss vers les lois communes ; boss director.
6. **P2-6/7** — benchmark visuel (rejoint le Cycle 3 art) ; perf/accessibilité/
   DemoRoute.

## Non-objectifs immédiats

Pas de refactor du save (v4 sain), pas de nouveau monde, pas d'art avant les
lois (cadence committée). Aucun travail utilisateur perdu : rien à écraser.
