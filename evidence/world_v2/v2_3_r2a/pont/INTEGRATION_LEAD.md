# Pont R2a — vérification d'intégration par le lead

Candidat reçu de l'agent `pont`, branche `claude/r2a-pont`, partie de
`d327e5e`. Fusionné en `--no-ff`. Ce document porte ce que **j'ai vérifié
moi-même après la fusion**, pas ce que l'agent a rapporté.

## Propriété des fichiers — RESPECTÉE

Diff `d327e5e..claude/r2a-pont` : 14 fichiers, tous dans son périmètre —
son générateur, son `.blend`, son `.glb`, `stone_bridge_place.gd`, et son
dossier de preuves. **Aucun fichier réservé au lead n'a été touché** : ni
`PROGRESS`, ni `STATUS`, ni le README global, ni le manifeste d'assets, ni
un kit, ni un builder, ni le layout, ni un test.

## Chaîne de preuve — VALIDE

| contrôle | résultat |
|---|---|
| `manifest.json` | `commit 62335da`, `repo_dirty: false` |
| `manifest_silhouettes_pont.json` | même SHA, `repo_dirty: false`, **0,000 %** hors bandes aux deux angles |
| ordre commit → capture → preuve | `git merge-base --is-ancestor 62335da 1d7fa65` = vrai |
| scène capturée | `res://scenes/world_v2/WorldV2.tscn` — le bon monde |

## Après fusion, dans MON arbre

| contrôle | résultat |
|---|---|
| `godot --headless --import` | RC 0, **0 erreur** |
| `gltf_inspect` | **VALIDE** — 34 maillages, 15 784 tris, 3 matériaux, 0 texture, 24,10 × 7,43 × 8,45 m, base Y = 0 |
| filets `world_v2_places` | **8 / 8** |
| filets `world_v2_hydrology` | **4 / 4** — le pont a bougé près d'un gué, l'agent les avait laissés `NON VÉRIFIÉ` |
| filets `world_v2_anchors` | **2 / 2** |
| recapture des 5 plans depuis l'arbre intégré | 5 / 5, rendu conforme |

## Reproductibilité de la chaîne — PROUVÉE

`stone_bridge` ajouté à `tools/blender/export_architecture.sh`, puis la
chaîne rejouée **dans le worktree jetable de l'agent** pour ne pas salir
l'asset prouvé : `EXPORT ARCHITECTURE : VERT`, `.glb` réécrit (jeton de
fraîcheur franchi), **675 988 octets et 15 784 triangles** — mêmes valeurs
que l'asset livré. La source régénère bien le résultat.

## Ce que j'ai mesuré à taille réelle

Sept images inspectées. Les quatre défauts nommés par le lead sont
démontrés corrigés :

- **arche continue et voussoirs solidarisés** — la silhouette d'élévation à
  90° montre un **vide continu**, pas un escalier ; c'est la preuve la plus
  directe du contrôle d'arc de l'agent ;
- **culées ancrées** — elles émergent des deux berges dans la composition
  et dans la vue 3 ;
- **caméra sous l'arche** — la vue 5 est prise sous la voûte à hauteur
  d'œil, l'intrados au-dessus avec ses lignes de joint qui convergent, et
  l'ouverture cadre l'autre rive. La caméra ne traverse rien ;
- **pas de grande face blanche** — mesuré. La frange claire au pourtour de
  l'arc, que l'agent déclare comme faiblesse, culmine à **0,775** contre un
  ciel à **0,813** et un intrados à **0,289**. Ce sont des arêtes de joint
  qui accrochent la lumière rasante, pas des faces blanches saturées.

## Ce qui reste faible — repris de l'agent, vérifié par moi

Ses neuf points sont exacts. Les trois qui se voient le plus :

1. l'intrados est une grande surface plate sombre, sans autre relief que
   les 19 lignes de joint ;
2. le dessus du tablier monte à ~0,70, au-dessus de la bande 35–65 % de
   §1.5 — surface horizontale captant soleil et ciel ;
3. tablier et parapets fusionnent en une seule bande épaisse dans la
   silhouette d'élévation, et la brèche ne peut pas y apparaître : le
   parapet opposé la comble. Elle se voit en vues 2 et 3.

## Le point qui appartient au lead, pas à moi

L'ouvrage est à **28,8 m du `v2_site`**, contre 19,4 m avant cette passe.
Raison mesurée et vérifiée par moi : à `x = −22`, le sol est **en eau de
`z = −12` à `z = +12`** — le pont d'avant était parallèle au chenal et posé
dans l'eau sur toute sa longueur. Il n'existe aucune traversée
berge-à-berge à moins de 25 m du site.

La note du layout dit toujours « berge sud du gué central ». **Ni l'agent
ni moi n'y avons touché** : c'est au lead d'arbitrer si la note doit
suivre l'ouvrage.

`NON VÉRIFIÉ` sur le plan artistique — aucun verdict auto-déclaré.
