# Lot instruments — deuxième passe (agent C), 2026-08-16

Chemin normalisé (`evidence/world_v2/v2_3_r2a/grotte/…`), contrairement au
premier lot `evidence/r2a352_c_instruments/` qui reste à normaliser.

Maillage mesuré partout : `cc3596c5d68cbfd8060987604aad6d5356772df18086f3f76f5aa8dbf8a73f49`
(`b_collerette/assets/environment/caves/SM_WaterfallCave.glb`), **jamais réécrit** —
chaque sabotage vit en mémoire et l'empreinte est relue après coup.

## Verdicts, sans lissage

| domaine | verdict | où |
|---|---|---|
| suite adverse | **9 / 10** — épreuve 5 `FAIL` | `adv_final.log` |
| banc de calibration élargi | exécuté, **deux prédictions réfutées** | `banc_verdict.log` |
| portage EDT | **équivalence prouvée** | `edt_original_blend.log`, `edt_port_glb.log` |
| oracle d'étanchéité | **`NON VALIDÉ`** — 5 contrôles négatifs sur 6 ne mordent pas | `oracle_cc3596c5.log` |
| classement du débord | **AUTORISÉ**, contrôle négatif refusé comme il doit | `debord.log` |

## Fichiers

* `adv_final.log`, `adversarial_bilan.json`, `epreuve5_collerette.json`,
  `epreuve10_courbure.json` — suite adverse. L'épreuve 5 porte trois
  sabotages instrumentés et deux faits nommés ; l'épreuve 10 porte le
  balayage de robustesse à neuf combinaisons.
* `banc_fixtures.log` (mesures A et B), `banc_edt.log` (EDT sur les mêmes
  GLB), `banc_verdict.log` (jonction et verdict), `plan.json`,
  `resultats_edt.json`, `verdict.json`.
* `edt_original_blend.log` — l'instrument **original** de `b_collerette`
  sur son `.blend`. `edt_port_glb.log` — **mon portage** sur le GLB.
  Les deux rendent `1,0400 m au (x −2,06 ; z 2,70)`.
* `diag_parite.log` — comptage des colonnes de parité impaire.
* `diag_fuite.log` — trace du chemin de fuite, cellule par cellule.
* `oracle_cc3596c5.log`, `oracle_cc3596c5.json` — l'oracle et ses contrôles.
* `debord.log`, `debord.json` — classement du débord d'overhang.

## Trois faits sur la géométrie, indépendants des instruments

1. **26 colonnes sur 33 950** ont une parité impaire selon +Z (15/24 850
   selon +X, 18/27 548 selon +Y). Sur un maillage clos, c'est impossible.
2. Le **toit du vide tombe à 0,054 m** vers `(x 0,58 ; y 5,80)`, et à
   0,023 m à `(0,58 ; 5,82)`. `EPAISSEUR_MIN_M` vaut 0,80.
3. Du **vide connecté à la galerie court jusqu'à `y ≈ 7,0`** au moins,
   alors que `CAVITE` s'arrête à `ay = 3,17`. Aucun instrument ancré sur
   les stations ne regarde là — ce n'est pas une couverture insuffisante,
   c'est hors domaine.

Ces trois faits sont mesurés, pas interprétés. Décider s'ils tombent dans
le périmètre du portail appartient au lead, pas à cet agent.
