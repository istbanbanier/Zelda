# R-D3 — auto-contrôle de répétition, fait ici et pas à l'intégration

Les quatorze manifestes des AUTRES sujets sont la copie conforme du jeu
committé sous `lot1r1/revue_intermediaire/silhouettes/` : ils ne sont pas
recalculés, ils sont recopiés. Seul `manifest_silhouettes_forest_shrine.json`
et ses deux PNG viennent d'être produits sur le lieu recomposé.

`verdict_d3_sanctuaire.json` sort de `tools/lot1_repetition.py` avec un `--out`
LOCAL — jamais le chemin par défaut, qui écraserait le verdict canonique du
lead.

- Seuils employés : ceux qui sont gelés, 0,4931 / 0,4912 / 0,5458 (30/80/160 m).
- Verdict : **PASS**, `signalees: 0`, `repo_dirty: false`, commit `4cb18d9`.
- Pire paire du sanctuaire : **IoU 0,389** contre `stone_bridge`. Le seuil le
  plus bas vaut 0,4912 ; l'exigence du lot est « seuil − 0,010 », soit 0,4812.
  Marge réelle : **0,092**.
