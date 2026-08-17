# Coupe technique et carte d'épaisseur — état R2a-3.4, AVANT la refonte

Produites par `tools/plot_cave_section.py` (commit `15abf21`) sur
`assets/environment/caves/SM_WaterfallCave.glb` à la géométrie **`504ecbe`** —
celle que la revue a jugée `FAIL TECHNIQUE — FAIL VISUEL`.

Ce dossier est une **référence**, pas une preuve de réussite. Il existe pour
que la coupe de R2a-3.5 se lise contre quelque chose.

## Ce que la mesure dit de cette géométrie

| grandeur | valeur |
|---|---:|
| triangles du maillage livré | 19 954 |
| épaisseur minimale de première paroi | **0,18 m** (station 7,75 · azimut 190°) |
| rayons sous le minimum contractuel de 0,60 m | **18** sur 1 152 |
| écart horizontal crête ↔ axe de galerie, au seuil | 0,00 m |
| écart horizontal crête ↔ axe, **moyen** | **2,84 m** |
| écart horizontal crête ↔ axe, **maximum** | **7,95 m** |
| stations non mesurables | 8,00 (point d'axe théorique hors maillage) |

## Le chiffre qui compte pour cette passe

Le panneau **B** de `coupe_technique.png` trace l'écart horizontal entre la
crête la plus haute de chaque tranche et l'axe de la galerie. Il vaut 0,4 m au
seuil, puis **monte jusqu'à 7,95 m** vers `y = 7`.

La revue avait formulé le constat à l'œil : la galerie passe sous les cols, pas
sous la masse dominante. Ceci en est la mesure. Sur une galerie réellement
rangée sous la dominante, cette courbe doit s'effondrer — c'est le contrôle que
je passerai sur la géométrie R2a-3.5, et il est publié **avant** de la voir,
pour qu'il ne puisse pas être choisi après coup.

## Ce que ces images ne prouvent pas

Rien sur l'aspect. Aucune de ces deux planches n'est un jugement visuel ; elles
sont produites par un outil qui n'a pas de verdict et pas de code retour
d'échec sur la forme. Le verdict artistique appartient au lead.

Elles ne prouvent rien non plus sur l'étanchéité : c'est le travail de
`tools/probe_cave_openings.py`, dont la définition d'une percée confirmée — un
carré de 0,10 m intégralement percé — est plus stricte que « un rayon a
traversé ».

## Reproduction

```bash
python3 tools/plot_cave_section.py \
    --out-dir evidence/world_v2/v2_3_r2a/grotte/r2a35_coupe_baseline
```

Les nombres complets sont dans `coupe.json` : profil de crête station par
station, épaisseurs par azimut avec les **deux** lectures (`premiere` et
`totale`), et les trois sections transverses.
