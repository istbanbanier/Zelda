# Bassin conducteur — preuve V2.3-A.R2B (agent C)

Contenu :

- `rouge_avant/` : le rouge archivé AVANT l'habillage (72 primitives hors
  kit, 2 blocs de l'ancienne margelle dans l'eau, option B non appliquée)
  + `ADDENDUM_MESURE.md` (recalibrages de la mesure d'eau garantie).
- `shots_bassin.json` : les 4 caméras EXACTES du manifeste V2.3-A —
  mêmes positions, cibles et FOV que la baseline `captures_v23ar`, pour
  un avant/après comparable.
- `*.png` + `manifest.json` : captures FINALES depuis l'arbre COMMITTÉ
  `d8a71e4` (`repo_dirty: false` au manifeste).
- `bandes_valeur.log` : mesure `tools/check_value_bands.py` (mode crop)
  du crop margelle de `bassin_proche` — historique complet des mesures
  (baseline p90 = 89 % → final p50 = 49,4 % / p90 = 66,3 %, cible
  p50 ∈ [35, 65], p90 ≤ 70), jeton `FIN NOMINALE`.
- `verts/` : journaux à jeton `RC=` —
  - `r2b_basin_3sur3.log` : les 3 contrôles neufs, verts, sur l'arbre
    devenu `d8a71e4` ;
  - `places_8sur8.log` et `world_v2_59sur59.log` : suites communes,
    vertes, sur l'arbre devenu `70780a0` (les deux commits suivants ne
    changent que des teintes, rejouées via le filtre r2b_basin) ;
  - `world_v2_59sur59_final.log` : la passe complète rejouée sur
    `d8a71e4`, si présente ;
  - `probe_kit_seating_12_modules.log` : l'assise des 12 modules mesurée
    AVANT tout assemblage.

Rappels evidence.md : rendu LOGICIEL (llvmpipe) — utilisable pour la
composition et la régression visuelle, jamais pour une mesure de
performance. Aucun verdict artistique auto-déclaré : constats factuels,
le verdict appartient au lead/Codex/Istvan.
