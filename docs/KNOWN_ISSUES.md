# KNOWN ISSUES

Sévérités (§21.10) : `S0` corruption/perte de données · `S1` crash, softlock,
progression impossible · `S2` système majeur incorrect, caméra injouable, chute
majeure de performance · `S3` défaut visible ou contournable · `S4` polish.

Aucun `S0`/`S1` ouvert n'est admis pour un build candidat.

---

## ISS-001 — Binaires officiels Godot et Blender injoignables · `S2` · OUVERT (contourné)

- **Build** : Phase 0, environnement d'exécution conteneurisé.
- **Étapes** : `curl -I https://godotengine.org` · `curl -I https://downloads.godotengine.org`
  · `curl -I https://download.blender.org`
- **Attendu** : HTTP 200. **Observé** : `CONNECT tunnel failed, response 403` — refus
  de la politique d'egress, pas une panne réseau. `archive.ubuntu.com`, `pypi.org`,
  `registry.npmjs.org` et `github.com` (git) répondent normalement.
- **Fréquence** : systématique.
- **Contournement en place** : moteur compilé depuis le tag git (D-001), Blender
  installé depuis le dépôt Ubuntu (D-002).
- **Propriétaire** : administrateur de l'environnement — seul lui peut lever le blocage.
- **Test de régression** : `tools/env_report.sh` affiche les versions réellement
  installées à chaque session.

## ISS-002 — Aucune capacité de rendu : GPU et affichage absents · `S2` · OUVERT

- **Étapes** : `ls /dev/dri` → absent · `echo $DISPLAY` → vide.
- **Impact** : bloque les niveaux 5-7 de la pyramide de validation — capture North
  Star, régression visuelle, profilage, soak. Donc bloque **Gate C.5, H, I et J**.
- **N'affecte pas** : import, parse, tests unitaires et d'intégration headless,
  logique de jeu, données, sauvegarde, graphe électrique — soit tout le chemin
  jusqu'au Gate G (graybox jouable).
- **Contournement mesuré (R-004)** : `xvfb-run` + Mesa **llvmpipe** rend réellement
  en Forward+ et produit des PNG exploitables — vérifié sur
  `scenes/tests/PipelineLab.tscn`. La **régression visuelle** (niveau 5) est donc
  possible ici ; seuls les niveaux **6 (performance)** et **7 (soak/export)**
  restent hors de portée.
- **Reste bloqué** : notation WOW fine (les couleurs et le filtrage logiciel ne sont
  pas ceux d'un GPU), profilage, frame pacing, session 60 min, export de build.
- **Interdiction associée** : ne jamais publier une mesure de performance obtenue
  en llvmpipe comme budget de frame (§20.1).
- **Propriétaire** : administrateur de l'environnement.

## ISS-004 — Aucun périphérique audio dans le conteneur · `S4` · OUVERT

- **Observé** : `ERROR: Condition "status < 0" is true. Returning: ERR_CANT_OPEN`
  depuis `drivers/alsa/audio_driver_alsa.cpp:97`, puis
  `WARNING: All audio drivers failed, falling back to the dummy driver.`
- **Cause** : pas de carte son ni de serveur audio dans le conteneur.
- **Impact** : nul sur l'import, les tests et la capture. Bloque en revanche toute
  vérification réelle du mixage et des bus audio (§18).
- **Contournement** : `--audio-driver Dummy` passé explicitement par
  `tools/validate_release.sh`, ce qui supprime une erreur trompeuse dans les logs.
- **Propriétaire** : administrateur de l'environnement. À rouvrir en Phase H/I.

## ISS-003 — Image de référence North Star absente du dépôt · `S3` · OUVERT

- **Contexte** : l'image de référence a été fournie dans la conversation, pas comme
  fichier sur disque. Son analyse a été faite et consignée dans `docs/ART_BIBLE.md`
  (relations de composition mesurées contre §3.2), mais le binaire lui-même n'a pas
  pu être versionné.
- **Impact** : les comparaisons avant/après de §7.16 exigent une référence stable et
  partagée. Sans le fichier, chaque session repart de la description écrite.
- **Action requise (utilisateur)** : déposer l'image à
  `source_assets/concepts/NORTHSTAR_reference.png` et l'inscrire dans
  `ATTRIBUTIONS.md`.
- **Rappel** : cette image reste une **référence de cadrage uniquement**. Elle ne
  doit jamais devenir skybox, matte painting, billboard ou texture (§0.2).

---

## Résolus

## ISS-R01 — Export glTF produisait un preset vide · `S2` · RÉSOLU 2026-07-31

- **Observé** : `tools/blender/export_gltf.py` rejetait ses 17 options et n'écrivait
  aucun `.glb` ; `gltf_inspect.py` échouait sur fichier introuvable.
- **Cause** : introspection via `inspect.signature(bpy.ops.export_scene.gltf.idname_py)`,
  qui décrit la méthode Python et non les propriétés de l'opérateur.
- **Correctif** : filtrage sur `get_rna_type().properties.keys()` (75 propriétés).
- **Régression couverte par** : `tools/blender/run_export.sh`, qui échoue si le
  `.glb` n'est pas produit **et** si la validation glTF le refuse.

## ISS-R02 — Blender Ubuntu sans numpy, exporter glTF inutilisable · `S2` · RÉSOLU 2026-07-31

- **Observé** : `ModuleNotFoundError: No module named 'numpy'` levé depuis
  `io_scene_gltf2/blender/exp/gltf2_blender_gather_tree.py`.
- **Cause** : le paquet Ubuntu de Blender utilise le Python système (3.12.3) et
  n'embarque pas numpy, dont l'exporter dépend.
- **Correctif** : `python3-numpy` (1.26.4), consigné comme dépendance obligatoire
  dans `docs/BUILD_ENVIRONMENT.md`.
