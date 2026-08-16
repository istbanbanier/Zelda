# La percée est fermée — reproduit par l'intégrateur

**GLB `c184c8dc0c0e754a…`**, produit par l'agent A dans son worktree. Ce dossier
ne contient que **mes** reproductions ; celles de l'agent sont dans
`r2a354_percee/`.

## Ce qui est reproduit, et par quel chemin

| mesure | avant `cc3596c5` | après `c184c8dc` | mon outil |
|---|---:|---:|---|
| **genre** | **1** *(une anse)* | **0** | `cave_topology_check.py` |
| bords libres · non-manifold | 0 · 0 | **0 · 0** | idem |
| **oracle d'inondation, pas 0,06** | **ROUGE `RC=1`**, `C3` | **VERT `RC=0`** | `cave_oracle_global.py` |
| composantes d'espace sans barrière | **3** | **2** | idem |
| composition, entaille contractuelle 0,90 | 3/3/3 · 2,16/2,33/2,25 | **identique** | journal de chaîne |
| auto-intersection | 2 paires · 0,0006 m | **2 paires · 0,0006 m** | journal de chaîne |

Une grotte à une seule bouche est topologiquement une **bosselure** : genre 0.
La géométrie corrigée l'atteint. **Elle est topologiquement plus propre que la
géométrie livrée**, qui porte genre 2.

## La cause du défaut, trouvée par l'agent et vérifiable au journal

Ni « deux lentilles qui ne se recouvrent pas », ni « artefact de décimation » —
**les deux hypothèses ont été réfutées par la mesure**, y compris celle que
j'avais trouvée plausible.

Le vide **n'existe à aucune étape source**. Il est **creusé par le booléen** :
`OUTIL_Cavite` a une emprise `y ∈ [−4,200 ; +7,245]` alors que la dernière
station est à `3,17` et l'apex à `3,25`. `hw · gauche` atteint `2,50 × 1,69 =
4,23 m`, et la normale y est à ~85 % alignée avec −Y : la salle déportée et
l'alcôve projettent leur joue **quatre mètres au nord** des stations.

C'est **le gabarit intérieur**, intouchable. Ce qui manquait, c'était la roche
qui aurait dû le couvrir — et c'est encore la même cause de fond que le toit
mince, la collerette sous-mesurée et les quatorze occurrences d'échantillonnage :
**un domaine borné aux stations, sur une géométrie qui les dépasse.**

## `C4` reproduit par accident — quatrième cause, et la plus banale

Mon premier lancement s'est fait **depuis le tronc** au lieu du worktree de
l'agent. Même GLB aux octets près, deux verdicts :

```
depuis le TRONC     graine (1.05 ; 6.25 ; 1.12)   ANCIENS reperes   ROUGE  C4
depuis le WORKTREE  graine (2.62 ; 2.58 ; 0.99)   NOUVEAUX reperes  VERT   RC=0
```

`cave_oracle_global.py` lit les repères dans
`scripts/world_v2/poi/waterfall_cave_place.gd` **relativement à l'arbre courant**.
Le tronc porte encore les anciens, la base R2a-3.5.2 n'y ayant jamais été
intégrée ; la géométrie, elle, est R2a-3.5.2.

**`C4` a donc raison** : il refuse de certifier une cavité dont un témoin déclaré
n'est pas dedans. Ce n'est ni la barrière, ni la niche, ni la percée — c'est un
**désaccord entre le maillage et le script de lieu qui le décrit**.

Le détail qui rend le cas insidieux : **`composantes d'espace (sans barrière) :
2` dans les deux runs.** L'étanchéité était établie des deux côtés ; seul le
témoin divergeait. Un `C4` peut donc coexister avec une géométrie parfaitement
saine — et un portail devrait rendre **`BLOQUÉ`**, pas `ROUGE`, quand la
provenance des repères ne s'accorde pas à la géométrie.

C'est la troisième fois que cette symétrie mord dans la série (§27.3, oracle sur
R2a-3.4, ici). Elle mérite d'être dite par l'outil, pas par un handoff.

## L'auto-intersection : pré-existante, pas introduite

Le journal du candidat — `r2a352_reproductibilite/run1_generateur.log` — porte
déjà **2 paires, repli 0,0006 m**. La correction n'en introduit aucune.

Le contrôle du générateur passe, son seuil étant `0,020 m`. **Le gate de la
directive dit « 0 auto-intersection ».** Deux paires à 0,6 mm ne sont pas zéro.
L'écart entre le libellé du gate et la tolérance de l'outil est **signalé au
lead, non tranché ici** — le contrat est gelé et cette question n'y figure pas.

## Ce que ce dossier NE dit pas

- **rien de l'épaisseur de coque** : c'est le mandat de l'agent C, et le gate
  d'épaisseur sera prononcé par son outil, pas par celui-ci ;
- **rien du visuel** : aucune capture, aucun verdict artistique ;
- **rien sous 6 cm** : une communication plus fine que le pas de l'inondation y
  resterait invisible. Le **genre**, lui, la verrait — et il rend 0.

## Reproduction

```sh
python3 evidence/.../r2a354_percee_fermee/genre_trois_geometries.py
cd <worktree portant les repères de la géométrie> && \
  python3 tools/cave_oracle_global.py <glb> --pas 0.06
```

Le `cd` n'est pas décoratif : c'est exactement ce qui distingue mes deux runs.
