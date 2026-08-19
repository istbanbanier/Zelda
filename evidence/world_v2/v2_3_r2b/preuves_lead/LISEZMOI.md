# Preuves du lead — intégration V2.3-A.R2B

Dossier produit par le lead APRÈS le cherry-pick des trois voies (A: camps,
B: ferme + arbre, C: bassin) sur `claude/world-v2-reconstruction`.

Contenu :

- `ab_<lieu>.png` × 5 — montages AVANT/APRÈS à caméra STRICTEMENT identique
  (vérification programmatique : mêmes `from`/`look`/`fov` par nom de shot
  entre `evidence/world_v2/v2_3/captures_v23ar/manifest.json` (commit 4100f66)
  et les manifestes des voies ; 17 paires comparées, toutes IDENTIQUE).
  Gauche = V2.3-A.R (assemblages primitifs), droite = R2B.
- `carte_cinq_lieux_r2b.png` — les cinq lieux pilotes situés sur le layout
  (turquoise), les quatre golden masters gelés (or), rivière et routes.
- `planche_couleur_r2b.png` / `planche_niveaux_de_gris_r2b.png` — vues
  proches des cinq lieux, couleur et valeurs.
- `METRIQUES_PAR_LIEU.md` — modules/meshes/colliders/tris par lieu, écarts
  consignés (dépassement accepté du camp braise).
- `INVENTAIRE_ACTIFS_LICENCES.md` — provenance et licence de chaque peau
  visible ; dette héritée du manifeste consignée.
- `JOURNAL_CONTROLES_NEGATIFS.md` — les 12 contrôles des trois voies,
  rouges d'abord (journaux bruts liés), verts après, seuils inchangés.
- `gm_byte_identity_HEAD_final.log` — sha256sum -c des 6 GLB gelés au HEAD
  final : 6/6 OK.
- `../integration/suite_w2_integree.log` — la suite world_v2 complète
  rejouée sur la branche intégrée.

Rappels : rendu LOGICIEL (llvmpipe) — régression visuelle seulement, jamais
une mesure de performance. AUCUN VERDICT ARTISTIQUE AUTO-DÉCLARÉ : ces
planches sont préparées pour la revue visuelle Codex/Istvan.
