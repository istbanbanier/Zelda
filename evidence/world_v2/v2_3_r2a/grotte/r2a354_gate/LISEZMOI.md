# Gate R2a-3.5.4 — la percée est fermée, la coque est trop mince

**Verdict : `PARTIAL`.** Un item du gate échoue, mesuré et reproduit.

## Le tableau

| item | verdict | mesure | reproduit par |
|---|---|---|---|
| **gate topologique** | **PASS** | genre 1 → **0** · oracle `ROUGE → VERT` à 0,06 · barrière duale valide dès `ay = −1,615` | intégrateur, **3 chemins disjoints** |
| **batterie d'oracle** | **PASS** | **8/8 CONFORME**, 1 tentative, placebo compris | intégrateur, `RC=0` |
| suite adverse · mutations · topologie | **PASS** | `RC=0` depuis le tronc | intégrateur |
| **gate d'épaisseur de coque** | **FAIL** | **lecture 0,6613 m** · borne garantie **0,5613 m** · seuil **0,80 m** | intégrateur, `RC=1` |

**Argmin : `(1,036 ; 5,173 ; 2,316)` en repère modèle — `ay = 5,17`, soit deux
mètres au-delà de la dernière station de `CAVITE`.**

C'est un `FAIL` **mesuré sur la lecture**, pas un `BLOQUÉ` de résolution : le
troisième verdict du contrat ne s'applique pas ici.

## Le contrat a fonctionné, et c'est le résultat de méthode de la passe

`docs/CONTRAT_COQUE_STRUCTURELLE.md` a été **committé avant** toute correction
géométrique, à `a4e91dc`, précisément pour que le domaine ne soit pas choisi
après avoir vu le résultat. L'antériorité se vérifie dans Git.

Il attrape un défaut à `ay = 5,17`. **L'ancien `controle_epaisseur`, borné à la
dernière station `ay = 3,17`, ne pouvait pas le voir** — et c'est mot pour mot le
domaine que le §2.4 a été écrit pour couvrir :

> *Aucun point de la coque ne peut être écarté au motif qu'il se trouve au-delà
> de la dernière station de `CAVITE`.*

## Ce qui est acquis, et qui ne l'était pas il y a une passe

**La percée est fermée à la source.** Trois chemins indépendants concordent :

- **genre** — 1 → 0, par mon lecteur GLB ;
- **inondation** — `ROUGE C3 → VERT`, oracle au pas 0,06 ;
- **graphe dual** — aucune barrière valide sur `cc3596c5` à aucun `ay` ; valide
  dès `ay = −1,615` sur la corrigée.

Une grotte à une seule bouche est topologiquement une **bosselure** : genre 0. La
corrigée l'atteint, quand la géométrie **livrée** porte genre 2.

**La cause du défaut est nommée** : le vide n'existait à aucune étape source, il
était **creusé par le booléen**. `OUTIL_Cavite` déborde à `y = +7,245` quand la
dernière station est à `3,17` : la salle déportée et l'alcôve projettent leur
joue quatre mètres au nord, et la roche qui aurait dû les couvrir manquait. **Un
domaine borné aux stations, sur une géométrie qui les dépasse** — la même cause
de fond que le toit mince, la collerette sous-mesurée et les quatorze occurrences
d'échantillonnage.

**Le portail d'oracle est devenu générique** : 8/8 sur trois genres différents,
0, 1 et 2, une seule tentative par contrôle, restauration byte-identique.

## Deux questions qui remontent au lead

### 1. L'emprise du masque de bouche n'est pas définie par le contrat

Le §2.5 dit *« seule la bouche canonique, explicitement masquée, est exclue »*,
sans fixer son **emprise**. Or elle change la cause publiée du tout au tout :

| emprise | lecture | argmin |
|---:|---:|---|
| 0,00–1,50 m | 0,0216 → 0,0565 m | `ay ≈ −1,11` — **collé au rebord du porche** |
| 2,00 / 3,00 m | **0,6613 m** | `(1,036 ; 5,173 ; 2,316)` |

**`FAIL` dans les deux lectures** — le verdict ne dépend pas du choix. Mais la
*cause* si. Le contrat étant **gelé**, l'agent a refusé de trancher et publié la
courbe entière. C'est la conduite exigée par le gel.

### 2. « 0 auto-intersection » contre une tolérance de 0,020 m

Le livrable porte **2 paires, repli 0,000612 m** — **pré-existantes**, le
candidat les portait déjà. Le contrôle du générateur passe ; le libellé du gate
dit « 0 ».

Attribution mesurée par l'agent A : le repli **naît à la décimation**, et une
seconde fragilité — un triangle d'**aire rigoureusement nulle** en
`(−1,504 ; −3,099 ; −0,639)` — **naît à la soustraction**. R2a-3.4 survit au
CSG parce qu'elle porte quatre triangles *presque* dégénérés mais **aucun
exactement nul** : le critère n'est pas « petite face », c'est « aire nulle ».
**Deux défauts distincts, tous deux dans la chaîne, aucun dans la source** —
donc un ticket, pas une passe.

## Ce qui n'est pas fait, et pourquoi

**Aucune capture.** Le gate est rouge ; la directive l'interdit.
**Aucun export livrable.** La géométrie corrigée reste en patch.

## Reproduction

```sh
cd <worktree portant les reperes de la geometrie>
python3 tools/cave_check_hull.py <glb> --h=0.10 --masque=2.00     # RC=1, FAIL
python3 tools/cave_oracle_batterie.py --entree <glb> --pas 0.06   # RC=0, 8/8
python3 tools/cave_oracle_global.py <glb> --pas 0.06              # RC=0, VERT
python3 tools/cave_topology_check.py                              # genre 0
```

Le `cd` n'est pas décoratif : lancé depuis le tronc, dont le script de lieu porte
encore les **anciens** repères, l'oracle rend `ROUGE C4` sur une géométrie saine.
Je l'ai reproduit par accident, et c'est consigné dans `../r2a354_percee_fermee/`.
