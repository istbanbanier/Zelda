# Revue contradictoire consolidée D.1R — 2026-08-01

Contexte frais (agent `adversarial-qa`), périmètre : commits `30213c3..ade002b`
(série D.1R complète). Méthode : commandes REJOUÉES par le réviseur —
`tools/validate_fast.sh` (exit 0, 251/251), les trois lancements Xvfb (vallée,
vestibule, boot→menu : exit 0, zéro erreur de script), lecture des 5 suites de
régression, et sondes GDScript hostiles écrites hors dépôt (settings corrompu,
sauvegarde corrompue, duplication de pickup, pause sur écran de mort).

## Verdict

**23 critères confrontés : 21 PASS, 1 PARTIEL, 2 FAIL démontrés.**
Verdict global = le plus faible : **FAIL** au moment de la revue —
**aucun S0/S1/S2**, trois S3 reproductibles, tous corrigés le jour même
(commit qui accompagne ce fichier) avec une régression chacun :

| ID | Sévérité | Défaut démontré | Résolution |
|---|---|---|---|
| QA-D1R-01 | S3 | `WeaponPickup` non persisté → gourdin dupliqué à chaque « Continuer » (repro : ramasser → autosave → recharger → reprendre = 2 gourdins) | `pickup_id` persistant, IDs mémorisés par le monde, retrait silencieux à l'application de la sauvegarde ; régression `test_a_taken_pickup_never_respawns_after_reload` |
| QA-D1R-02 | S3 | `settings.cfg` hostile : tableau → erreur de constructeur puis 0,0 (sous le MIN, souris morte) ; `nan` traversait `clampf` jusqu'au lecteur | `load_mouse_sensitivity` n'accepte qu'un nombre FINI, `clamp_sensitivity` rejette nan/inf, le lecteur passe par son setter borné ; régression `test_a_corrupt_settings_file_falls_back_within_bounds` (6 valeurs hostiles) |
| QA-D1R-03 | S3 | Mort → Échap → Reprendre recapturait la souris SOUS l'écran de mort ; Tab ouvrait l'inventaire par-dessus | Écran de mort MODAL : gardes dans `_input`, `toggle_pause`, `toggle_inventory` et `_set_mouse_captured` ; régression `test_the_death_panel_is_modal_no_pause_inventory_or_mouse_grab` |
| QA-D1R-04 | S4 | TEST_REPORT surdéclarait la couverture (réticule, plafond notifications) et attribuait le détour en U à la mauvaise suite | Formulations corrigées dans TEST_REPORT — les deux points non assertés sont explicitement renvoyés au playtest n° 2 |

Note S4 consignée : les manifestes de capture portent `repo_dirty: true` parce
que les fichiers de preuve eux-mêmes sont non suivis au moment de la capture
(œuf-et-poule) — le hash de commit du manifeste reste exact pour le code rendu.

## Plafond maintenu

Tout ce qui exige un appui de touche réel, une capture souris effective ou un
jugement visuel (critères périphériques de D.1R.1/D.1R.3, l'essentiel du
feedback graybox) reste **EN ATTENTE** du playtest humain n° 2 — les tests
prouvent des liaisons et des mesures, jamais un appui de touche (CLAUDE.md).
D.1R n'est pas « Validé » : il est **Fonctionnel, corrigé post-revue, en
attente de validation humaine**.
