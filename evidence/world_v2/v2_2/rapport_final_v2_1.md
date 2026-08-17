# RAPPORT A — V2.1 (archivé à la frontière d'audit V2.2)

Archivé ici parce que `evidence/world_v2/v2_1/` est GELÉ en V2.2 (périmètre §8).
Les preuves citées vivent dans `evidence/world_v2/v2_1/`, inchangées.

- **Checkpoint de sécurité** : `5bbe679849b50792edcf1539c7064ef592742dc4`
  (« V2.1 CHECKPOINT — PHASE EN COURS, NON VALIDÉE », poussé pendant la panne
  serveur de la revue, sur dérogation du lead).
- **V2_1_FINAL_SHA** : `38c87b1d1b2600844a941ba4823b2242ef8aa2ad` — vérifié
  distant au moment du gate.
- **Commits de phase** (0da6c8d..38c87b1, 11 commits) : bb80761 (contrat
  hydro/routes rouge d'abord), 6733c54 (vallée whitebox), bfb80e3 (7 suites),
  6b3f9b4 (relief praticable), 80a4096 (navigation), 94f5430 (suites
  nav+parcours), 5bbe679 (contrôles négatifs), 415a3c4 (corrections revue
  D2/D4 + sonde métriques), 487f9d6 (enroulement du terrain), 38c87b1
  (preuves finales).
- **Tests** : 33/33 V2.1 au commit final ; `validate_fast.sh` **878 réussis /
  0 échoué, RC=0** (journal unique, en-tête daté + SHA).
- **Parcours** : les quatre routes marchées par le vrai `PlayerController`
  via `InputIntent`, zéro téléportation après le spawn, garanties par tick
  (jamais sous le monde, aucun saut > 3 m, arrivée vivant).
- **Navigation** : 4 quadrants versionnés (2758/2416/2953/3192 polygones),
  ancres reliées (arrivées ≤ 0,75 m), bol du lac = île par obstruction d'eau
  profonde déclarée ; **re-cuisson bit-à-bit identique** (reproductibilité
  prouvée, pas déduite).
- **Contrôles négatifs** : A couture (nomme « frontière est de c3r3 »),
  B tablier (nomme « river_route (-22,-58) »), C brèche (nomme « azimut
  70° ») — chacun ROUGE archivé puis restauré VERT, jamais commité cassé.
- **Captures** : six fenêtres 1280×720 d'arbre committé, manifestes
  `repo_dirty:false`, inspectées une à une — l'inspection a attrapé
  l'enroulement inversé du maillage de terrain (pièce avant/après conservée).
- **Revue indépendante** : **PASS** à contexte frais (aboutie à la 5ᵉ
  tentative après quatre erreurs 529 ; la revue de repli n'a pas été
  nécessaire) ; réserves A1-A4/D1-D4 non bloquantes toutes traitées ;
  reproductibilité du bake, seul NON VÉRIFIÉ de la revue, convertie ensuite
  en preuve par re-cuisson. Codex peut rejouer librement sur `38c87b1`.
- **V1** : intacte byte-pour-byte (`git diff 0da6c8d..38c87b1 --
  scripts/world/ scenes/world/ scripts/save/` vide) ; flux normal V1.
- **Schéma de sauvegarde** : 4, inchangé.
- **Verdict** : `V2.1 GATE STRUCTUREL ET PHYSIQUE : PASS` — `GO_V2_2 = TRUE`.

Post-gate, avant la présente directive : un commit de protection
(`1ee83e9`, tests/world_v2/test_world_v2_dungeon_pins.gd) épingle les
contraintes immuables du donjon — écrit sous l'ancienne interprétation de
V2.2 (enveloppe du donjon), conservé comme fil de détente valable pour toute
phase future ; il n'appartient PAS au périmètre paysager V2.2 et est déclaré
ici pour l'audit `V2_1_FINAL_SHA..V2_2_HEAD`.
