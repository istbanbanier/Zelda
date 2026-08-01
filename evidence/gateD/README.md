# evidence/gateD — Phase D (monde graybox)

## `vista_hero01.png` — capture de la caméra de départ (D.1, D-025)

Capture depuis le renderer réel (`capture_reference.gd`, llvmpipe via Xvfb —
utilisable en régression visuelle, JAMAIS comme mesure de qualité ou de
performance, CLAUDE.md). Manifeste : `vista_hero01.json`.

- **Commit du code capturé** : `316e4dd` (cadrage final : héros de dos ~32 %,
  spawn au bord de crête).
- **`repo_dirty: true`, expliqué** : au moment de la prise, les seuls fichiers
  modifiés étaient `vista_hero01.png`/`.json` eux-mêmes (l'itération de capture
  précédente, en cours de remplacement). Le code capturé correspond exactement
  au commit indiqué. L'outil marque tout écart — c'est son travail ; l'écart est
  ici l'artefact de sortie, pas le code.
- **Itérations archivées dans l'historique git** : 1re capture — héros de FACE
  (nez cyan), 57 % du cadre, vallée invisible ; 2e — dos et taille corrects,
  vallée toujours masquée par 26 m de plateau ; 3e (celle-ci) — spawn avancé au
  bord, la vallée se révèle : descente, ruines, rivière, fumée du camp, pylône
  cyan, citadelle au cœur cyan. Chaque défaut a été vu SUR CAPTURE et corrigé
  par un commit dédié — c'est la boucle de §7.16, en graybox.
