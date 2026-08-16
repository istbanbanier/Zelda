# Socle R2a-3.5.5 — la pile est fidèle, et un instrument était cassé

## La pile de quatre patches reconstitue EXACTEMENT le générateur du candidat

Le tronc porte encore le générateur **de R2a-3.4** (`4c748d1`), inchangé depuis
31 commits. Toute la géométrie R2a-3.5.2 → 3.5.4 vit hors tronc, en patches.
Rejouée sur `0cdfd91`, elle rend un générateur dont l'écart avec celui de
l'agent A est **exactement** les 105 lignes du hunk de politique — que j'ai
retiré, la reclassification ne pouvant venir qu'après qualification du nouveau
gate.

**Preuve d'exécution** : le socle rend `c184c8dc0c0e754a`, **1 490 320 octets**,
byte-identique au GLB de l'agent. Cinquième confirmation de reproductibilité de
la série, et elle établit trois choses d'un coup — la pile est fidèle,
`--diagnostic` ne touche pas la géométrie, la chaîne est déterministe.

Deux outils sont gardés **au tronc** plutôt qu'au patch : `probe_cave_openings.py`
et `probe_cave_edt_plan_bouche.py` portent des correctifs POSTÉRIEURS à
`c79341e` (« SIXIÈME ENDROIT », « DOUZIEME DEFAUT », mode métrique). Appliquer le
patch les aurait fait régresser.

## Gate topologique reproduit, sur les trois géométries

| géométrie | bords libres | non-manifold | χ | genre |
|---|---:|---:|---:|---:|
| R2a-3.4 **livrée** `8bf1a1b3` | 0 | 0 | −2 | **2** |
| candidat percé `cc3596c5` | 0 | 0 | 0 | **1** |
| candidat corrigé `c184c8dc` | 0 | 0 | 2 | **0** |

La coque de collision `COL_WaterfallCave` est de genre 0 dans les trois cas.
Une grotte à une seule bouche est topologiquement une bosselure : genre 0. Seule
la corrigée l'atteint.

## Un instrument du tronc était cassé, et son banc passait au vert

`tools/cave_topology_check.py` portait **trois chemins absolus** vers
`/home/user/zelda-r2a353/`, worktree d'une passe close, **et ignorait son
argument de ligne de commande**. Le worktree supprimé, l'outil rendait
`FileNotFoundError` sur un chemin que l'appelant n'avait jamais nommé.

Ce qui rend le défaut coûteux : **le banc `--banc` passait**. Un outil dont
l'auto-test réussit pendant que son chemin de production est mort est exactement
la panne décrite par `PROMPT4_METHOD` §2 — un test qui ne peut pas échouer sur ce
qui compte. Le banc n'éprouvait que l'analyse ; personne n'éprouvait la lecture.

`MASTER_SPEC` §7.15 l'interdisait déjà — « aucun fichier dépendant d'un chemin
privé ». La règle existait, elle ne mordait nulle part.

Corrigé : les chemins se passent en argument, **aucun défaut**, et l'absence
d'argument rend 2 avec un mode d'emploi. Trois autres outils portaient des
chemins morts en docstring d'exemple (`cave_fix_etapes`, `cave_fix_outil`,
`cave_fix_csg_diagnostic`), neutralisés au passage.

## Reproduction

```sh
python3 tools/cave_topology_check.py <glb> [<glb> ...]     # RC=0
python3 tools/cave_topology_check.py --banc                 # 3 verts
flock /home/user/Zelda/.git/heavy_tools.lock -c \
  'cd <socle> && tools/blender/export_cave_echafaudage.sh'  # rend c184c8dc
```

## Batterie d'oracle reproduite — 8/8, une tentative par contrôle

Depuis le socle, sur `c184c8dc`, pas 0,06 m :

| contrôle | attendu | obtenu | tentatives | rayon libre |
|---|---|---|---:|---:|
| témoin | VERT | VERT | 1 | — |
| placebo | VERT | VERT | 1 | — |
| toit | ROUGE | ROUGE | 1 | 0,280 m |
| paroi est | ROUGE | ROUGE | 1 | 0,280 m |
| paroi ouest | ROUGE | ROUGE | 1 | 0,280 m |
| plancher | ROUGE | ROUGE | 1 | 0,280 m |
| poche | ROUGE | ROUGE | 1 | — |
| roche flottante | ROUGE | ROUGE | 1 | — |

`RC=0`, **BATTERIE : CONFORME**. Le placebo est celui qui compte : un portail
qui rougit sur un sabotage inerte ne prouve rien.

## Ce que ce dossier NE dit PAS — et c'est un manque réel

**L'épaisseur de R2a-3.4 n'a jamais été mesurée.** Le journal de la passe
précédente s'arrêtait **sans `RC=`** sur `16 854 916 échantillons`, et a été
renommé `coque_R2a34_INTERROMPU_SANS_RC.log` par son auteur.

Cause structurelle, mesurée : la subdivision est 4-aire et **uniforme**, un
triangle descend de `ceil(log2(R₀/h))` niveaux et chaque niveau quadruple.
Quelques triangles à grand rayon imposent leur profondeur à toute la face.

| géométrie | peau intérieure | échantillons à `h = 0,15` |
|---|---:|---:|
| `c184c8dc` | 95 m² | 114 376 — termine |
| **R2a-3.4** | **628 m²** | **16 854 916 — ne termine pas** |

Pas effectif ≈ 6 mm là où `h` valait 0,150 : vingt-cinq fois plus fin que
nécessaire. **La couverture reste prouvée ; c'est le coût qui ne l'est pas.**

Statut : `NON MESURÉE`, jamais « probablement bonne ». Un instrument qui ne
termine pas doit le **dire** — même règle que « une étape sautée sort en 3, pas
en 0 », appliquée au temps de calcul.

## L'appariement GLB ↔ générateur de R2a-3.4 est PROUVÉ, plus supposé

L'agent C posait à juste titre en **hypothèse** que le GLB `8bf1a1b3` sorte du
générateur de `504ecbe` : le `.blend` est une sortie non reproductible, et le
manifeste étiquette d'ailleurs ce GLB « R2a-3.6 ».

Reconstruit depuis un worktree neuf détaché sur `504ecbe` :

```
reconstruit : 8bf1a1b309aee79f92c77371   1 506 684 octets
livré HEAD  : 8bf1a1b309aee79f92c77371   1 506 684 octets
cmp         : IDENTIQUE au bit près
git status --porcelain assets/  : vide
```

**L'hypothèse devient un fait.** Et le résultat est plus large que la question
posée : la chaîne est **déterministe de bout en bout sur la géométrie
canonique**, 60 commits et un worktree neuf plus tard.

`RC_MAKE=0` : la chaîne de R2a-3.4 est **verte**, contrairement à celle du
socle. La raison est simple et il faut la dire précisément —
`controle_epaisseur_domaine` a **0 occurrence** dans le générateur de `504ecbe`.
Il a été ajouté à R2a-3.5.3.

> **Précision qui compte.** « 326 plaques sur R2a-3.4 » n'est pas un verdict que
> la chaîne de R2a-3.4 aurait rendu sur elle-même : c'est le contrôle de
> R2a-3.5.3 **appliqué après coup** à la géométrie de R2a-3.4. La géométrie
> livrée n'a jamais été soumise à ce contrôle par sa propre chaîne. C'est
> exactement pourquoi un critère qui condamne plus fort la référence que le sujet
> ne peut pas décider seul.
