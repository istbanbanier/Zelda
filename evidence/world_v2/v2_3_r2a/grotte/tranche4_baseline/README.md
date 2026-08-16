# Baseline « AVANT » des A/B de R2a-3.4

Ces quatre plans figent l'état **avec fleurs corrigées et géométrie R2a-3.3
inchangée**. Ils forment le côté gauche des montages A/B de la passe R2a-3.4.

## Pourquoi cette recapture était obligatoire

La directive R2a-3.4 §5 l'impose, et l'image en donne la raison : utiliser
comme « avant » une capture à fleurs géantes aurait **confondu deux
corrections** — celle de l'environnement (échelle florale V2.2) et celle de la
composition extérieure. Le lecteur aurait attribué à la seconde un dégagement
dû à la première.

Le manifeste le prouve plutôt que de l'affirmer :

| rôle | commit |
|---|---|
| géométrie (`SM_WaterfallCave.glb`) | `8368550` — R2a-3.3, **inchangée** |
| correctif floral (`world_v2_vegetation_builder.gd`) | `4ed364b` |
| arbre de capture | `4ed364b`, `repo_dirty: false` |

Les SHA ne sont pas saisis à la main : `capture_poi_batch --provenance=` les
lit dans git, par chemin.

## Ce que ces images établissent

1. **La correction florale fonctionne à l'écran.** Les grappes de 2,84 m qui
   masquaient la bouche sont devenues des touffes à l'échelle de l'herbe.
   L'agent A ne pouvait pas le prouver de son côté et l'avait honnêtement
   laissé `NON VÉRIFIÉ` ; c'est vérifié ici.

2. **Elles démasquent les deux défauts du seuil**, aux emprises que la sonde
   `tools/probe_cave_openings.py` avait calculées **sans caméra ni moteur** :

   - feuillage vert visible *à travers* la paroi du fond, dans
     `seuil_cadre.png` ;
   - sol en plaques disjointes, avec des brins d'herbe du terrain gelé qui
     percent entre elles — le sol visible est le sommet de l'assise enterrée.

   Les fleurs les cachaient. C'est la seconde raison, non prévue, pour
   laquelle cette recapture devait précéder toute autre correction.

## Caméras

Identiques à celles de la passe finale R2a-3.4, prises du **même fichier**
`shots_r2a34.json` — l'identité des cadrages est structurelle, pas déclarative.
