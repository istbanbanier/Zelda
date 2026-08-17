# Revue contradictoire V2.1 — contexte frais (agent `adversarial-qa`)

Date : 2026-08-13. État examiné : commits `bb80761…5bbe679` (le correctif D2/D4
`415a3c4` répond à ses constats ; le correctif d'enroulement `487f9d6` lui est
postérieur — trouvé ensuite par l'inspection des captures).

## Verdict global : PASS (réserves « à corriger », aucune bloquante)

L'agent a cherché à démontrer l'échec du gate et n'y est pas parvenu sur le
fond spatial : les 33 tests passent sous SA PROPRE exécution au commit livré,
les seuils sensibles sont ancrés à des contrats indépendants préexistants, les
contrôles négatifs prouvent que les tests savent rougir, la V1 est
byte-pour-byte intacte.

## Ce que l'agent a réellement exécuté

- `git diff 0da6c8d..HEAD -- scripts/world/ scenes/world/ scripts/save/` → vide (V1 intacte)
- `git diff --name-only 0da6c8d..HEAD` filtré hors périmètre → vide (périmètre respecté)
- Runner complet `--filter=world_v2` → **33 réussis, 0 échoué, 0 erreur de script, RC=0**
- Lecture intégrale : heightmap, six bâtisseurs, root, outil de bake, les 12
  fichiers de tests, layout JSON, les 10 journaux d'évidence, l'historique git
  de `FORD_MAX_STEP_PER_M`
- Vérifications ponctuelles : `SCHEMA_VERSION == 4` ; `max_floor_angle_deg = 46.0`
  (`resources/tuning/locomotion_default.tres`, non touché par la phase) ;
  défaut latent confirmé dans `bake_valley_navmesh.gd` (symbole `_make_mesh`)

## Jugements sur les cinq points sensibles déclarés

1. **`FORD_MAX_STEP_PER_M` 1.0 → 1.0355 : calibrage honnête.** 1,0355 = tan(46°),
   constante contractuelle PRÉEXISTANTE et INDÉPENDANTE (tuning de locomotion,
   hors périmètre de la phase). Preuve décisive : l'échec initial mesurait
   1,05 > 1,0355 — relever le seuil seul n'aurait PAS absous ; le terrain a dû
   être réellement corrigé (`FORD_BANK_W` 16→20). Garde-fou : le vrai joueur
   traverse le gué est dans la suite de traversal.
2. **Navigation synchrone + marge 2 m** : le risque de fausse connexion le plus
   dangereux (bol du lac) est testé et tient.
3. **Île du lac par obstruction** : cohérent de bout en bout (commentaire
   corrigé, obstruction déclarée, lue au bake, île prouvée par test).
4. **`agent_max_slope` en degrés** : correct, justifié par la source 4.7.1.
5. **Migration de l'assertion de sol du squelette** : contrat conservé et
   renforcé (altitude y=24 toujours exigée).

## Réserves

- **A1** — le dépôt a bougé pendant la revue (commit d'evidence `5bbe679` créé
  entre deux lectures) : violation de « une seule session à la fois » pendant
  une revue à arbre immobile. Contenu evidence-only, régularisé.
- **A2** — `docs/PROGRESS.md` sans entrée de handoff V2.1. → Corrigé après revue.
- **A3** — défaut latent V1 (`bake_valley_navmesh.gd`) non consigné dans
  `KNOWN_ISSUES.md`. → Hors périmètre d'écriture ; porté dans README + PROGRESS,
  action proposée pour la prochaine session V1.
- **A4** — preuves sans manifeste daté/SHA ; le journal 33/33 final absent du
  dépôt (revendication vraie — l'agent l'a reproduite — mais non prouvée par le
  dépôt). → Corrigé après revue : tous les artefacts portent date + commit.
- **D1** — seuil de gué = pile la frontière de marchabilité (à documenter, fait).
- **D2** — branche morte `maxf(24,12)` dans la légalité de traversée du pont. → Corrigé (`415a3c4`).
- **D3** — liste canonique POI en constante de production ; compensé par
  `test_world_v2_layout.gd` (ancrage contre les bâtisseurs V1, source indépendante).
- **D4** — grottes comptées, pas épinglées individuellement. → Corrigé (`415a3c4`).

## NON VÉRIFIÉ (explicite, jamais converti en PASS)

- **Reproductibilité du bake de navigation** : la revue (lecture seule) n'a pas
  re-cuit ; vérifiée par l'ordre des commits seulement.

## Note de méthode

La revue indépendante a subi quatre interruptions serveur (erreurs 529) avant
d'aboutir à la cinquième tentative — elle est allée au bout et le verdict
ci-dessus est le sien. La revue principale de repli prévue par la directive du
lead n'a PAS été nécessaire.
