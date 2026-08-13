# Revue contradictoire V2.2 — contexte frais (agent `adversarial-qa`)

Date : 2026-08-13. État examiné : `38c87b1..298099f` (arbre GELÉ pendant
toute la revue — la leçon A1 de V2.1 appliquée : aucun commit concurrent).

## Verdict global : PASS (réserves non bloquantes)

L'agent a cherché à démontrer l'échec du gate et n'y est pas parvenu sur le
fond. Ce qu'il a RÉELLEMENT exécuté (pas seulement lu) :

- diff complet du périmètre + `git diff --quiet` sur tous les chemins
  interdits (layout JSON, heightmap, caméras, V1, Player, SaveSystem,
  project.godot, tests V1, preuves antérieures) → tout gelé ;
- la suite world_v2 REJOUÉE à HEAD → verte, RC=0 ;
- `validate_fast.sh` relancé : stades 0-1b verts ; stade 2 tué par
  l'environnement à 880 verts / 0 échec (les restants = suites qu'il avait
  déjà rejouées vertes en filtre) ; stades 3-4 appuyés EXPLICITEMENT sur le
  journal archivé `validate_fast_final.log` ;
- le re-bake de navigation REJOUÉ : quatre `.tres` bit-à-bit identiques aux
  committés (sha256) — la réserve « reproductibilité NON VÉRIFIÉE » de V2.1
  est levée pour V2.2 ;
- le contrôle négatif D rejoué sur HEAD → rougit avec le message exact ;
- une INJECTION ADVERSE originale : transforms moteur décalés de +2 m avec
  méta de plan intacte → le contrat paysager reste VERT (démonstration de
  l'angle mort, voir réserve 1) ;
- cam01 re-capturée à HEAD → Δluma 0,0001 vs l'archivée (les commits
  postérieurs aux six A/B n'ont pas changé l'image) ;
- les 21 manifestes de capture lus : tous `repo_dirty: false`, commits
  ancêtres de HEAD.

## Réserves « à corriger » et leur traitement

1. **Le plan en méta peut mentir sur ce que le MOTEUR reçoit** (démontré
   par injection). Ce n'est pas un contournement du contrat — la limite
   était documentée au point d'usage AVANT la revue (bâtisseur, test,
   README) — mais le trou méritait d'exister comme ARTEFACT, pas comme
   phrase. → Traité : `controles/controle_E_meta_moteur_ANGLE_MORT.log` —
   l'injection rejouée, la suite reste verte, et le journal dit pourquoi
   c'est un angle mort assumé (le headless ne voit pas le moteur ; les
   captures llvmpipe et les sondes physiques — visée, gués, azimuts — ne
   passent jamais par la méta). Filet supplémentaire proposé pour une phase
   ultérieure : comparaison d'un échantillon plan/capture.
2. **`docs/STATUS.md` sans entrée World V2** (la DoD l'exige à la clôture).
   → Corrigé après revue : entrées V2.0/V2.1/V2.2 ajoutées, ancrées sur des
   chemins stables et les preuves datées, jamais sur des compteurs.

## Détails relevés (tous consignés)

- `suite_complete_c3_verte.log` date du MILIEU de phase (avant eau/ciel/
  bordures) ; couvert par la relance de l'agent à HEAD et par
  `validate_fast_final.log`. → Le README d'evidence le précise désormais.
- Instances traversables échantillonnées (≤ 60/cellule) dans le test des
  couloirs : un brin isolé peut échapper ; les colliders sont vérifiés à
  100 %. Marges du bâtisseur strictement supérieures aux seuils du test,
  qui lit le layout gelé indépendamment — pas d'auto-absolution.
- Une canopée SANS collision dans l'axe d'une fenêtre ne serait vue que sur
  capture (la sonde de visée est physique) — les six captures ont été
  inspectées, aucune fenêtre bouchée.
- Le visuel des crêtes de bordure déborde la boîte de collision (talus,
  cols) — murs invisibles/bases traversables possibles UNIQUEMENT hors de
  la zone jouable (r = 246 > limite 233).
- Aucune auto-louange artistique trouvée dans les commits, docs et
  evidence de la phase ; « calibrage final » = dernière passe, pas un
  verdict de qualité.
