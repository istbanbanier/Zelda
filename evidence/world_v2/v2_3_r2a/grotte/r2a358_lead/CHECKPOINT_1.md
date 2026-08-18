# R2a-3.5.8 — checkpoint 1 : pré-vol, caméra verte, plans arbitrés

Date : 2026-08-18. HEAD au moment du checkpoint : `52ce1b5`.

## 1. Divergence du pré-vol — expliquée, résolue, rien de publié touché

Le distant portait les deux commits Codex (`9274c7d`, `0b0ef54`) ; le local
portait **un** commit non poussé (preset Web + étape CI + guide PLAYTEST,
trois fichiers, aucun chevauchement). Résolution : sauvegarde additive
(`sauvegarde/checkpoint-5f01ce7`), puis rejeu de ce seul commit non publié sur
la tête distante. Vérifié après coup : **les deux commits Codex sont ancêtres
préservés**, `HEAD = origin`, arbre propre. L'interdit rebase/reset protège
l'historique publié ; rien de publié n'a été réécrit.

La validation `validate_fast` en cours a été **tuée par PID relevés via
`/proc`** (jamais par motif), mort vérifiée avant annotation, annotation relue :
elle tournait sur les tests d'AVANT les commits Codex, qui modifient
précisément ces tests. Son verdict n'aurait rien valu.

## 2. Premier gate vert : le correctif caméra au HEAD (§6 de la directive)

Exécuté par l'agent C, sous `flock`, import d'abord, jetons `RC=0` :

> `ok test_boot_smoke.gd::test_boot_smoke_from_boot_to_playable_world_v2`
> **(23 assertions)** · 1 réussi, 0 échoué · 0 erreur de script

- parcours réel `Boot → Menu → « Nouvelle partie » → WorldV2`, scène active
  `WorldV2` ;
- joueur présent, posé, **vivant et réactif** — soulevé de 3 m il retombe, une
  intention le déplace de plus d'un mètre ;
- **caméra active = `player.camera_rig().get_camera()` par égalité
  d'identité**, ce qui exclut `DiagnosticCamera` par construction ; le
  mécanisme du correctif `0b0ef54` (`activate_gameplay_camera()`, `push_error`
  en échec) vérifié dans `world_v2_root.gd`, zéro erreur au journal ;
- HUD monté, 64 chunks, 9 lieux, spawn `(0.0, 24.4, 170.0)` ;
- bonus : le monde se monte **deux fois** au journal — mort → « Réessayer » →
  rechargement — prouvant que la reprise repasse par la reconquête caméra.

## 3. Un écart de provenance trouvé par C, résolu par les relevés du lead

Le fichier `r2a357_agentA_intersections.patch` hache `86b01ece…` alors que le
LISEZMOI de 3.5.7 annonce `027b80e4…`. Résolution par l'historique de session :
l'agent A de 3.5.7 a livré **deux versions successives du même chemin de
fichier**, toutes deux autonomes sur l'état `MASSIF`-seul — `027b80e4` (136 l,
retrait d'alcôve, 16→4) puis `86b01ece` (148 l, retrait à l'échelle
`CAVITE_ASYM`, toujours 4 à 0,2434 m). **`86b01ece` supersède `027b80e4`.** La
v1 est perdue comme fichier, décrite dans les preuves. État candidat complet :

> `531cdd8` + correctif T-jonction (non commité, `a_epaisseur`)
> + `massif_lissage.patch` (`5b9d4734`) + `86b01ece`. Rien d'autre.

## 4. Arbitrages rendus sur les plans

- **C** : plan approuvé ; outil `sha256_geom` par nœud autorisé (~40 lignes,
  instrument du gate « visuel inchangé », hors budget du contrôle spécialisé) ;
  vue « collider seul » autorisée en **tracé d'instrument** étiqueté, jamais
  présenté comme capture moteur.
- **B** : plan approuvé ; l'unique contrôle nouveau est
  `cave_paroi_invisible.py` (aucun existant ne compare `COL_` et `SM_` sur le
  même rayon) ; la fixture de sabotage ne compte pas dans le budget — elle est
  mandatée par la directive §5. **Mise en garde transmise : le `COL_` de
  `40714c46` est pré-`MASSIF`** — rodage et contrôles négatifs dessus, tableaux
  finaux uniquement sur le GLB de l'agent A. Règle reprise au gate : *un rouge
  délocalisé compte comme échec du contrôle, pas comme succès*.
- **A** : plan attendu.

## Budget

0 des 3 itérations de géométrie consommées. 1 contrôle spécialisé alloué (B).
