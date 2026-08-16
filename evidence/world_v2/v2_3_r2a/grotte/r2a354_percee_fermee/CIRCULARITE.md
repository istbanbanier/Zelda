# Circularité topologique — reproduit par l'intégrateur, les deux moitiés

L'addendum du lead pose la seule question qui pouvait invalider la correction :

> *Le volume ciblé doit soit être réellement rempli de roche, soit rester relié à
> l'intérieur canonique par un chemin indépendant de l'ancienne percée. Un simple
> bouchon transformant le défaut en bulle interne ne constitue pas une
> correction.*

Le piège est réel : une fois la bouche scellée, l'air intérieur et l'air
extérieur communiquent **par la percée elle-même**. On ne peut donc pas déclarer
le vide « intérieur » au motif qu'il est connecté — l'argument tournerait en
rond.

## La réponse, mesurée sous un plafond qui exclut la percée

`cave_fix_connexite_interne.py` inonde **sous `z ≤ 1,20`**, c'est-à-dire sous
l'altitude de la percée. Tout chemin qu'il trouve est donc, par construction,
**indépendant de l'ancienne percée**.

| | candidat percé `cc3596c5` | corrigée `c184c8dc` |
|---|---:|---:|
| composantes d'air sous plafond | **5** | **5** |
| `MODELE_SALLE` | composante 3 | composante 3 |
| `MODELE_NICHE` | composante 3 | composante 3 |
| **vide ciblé `(0,55 ; 5,95 ; 0,80)`** | **composante 3** | **composante 3** |
| témoin dehors | composante 2 | composante 2 |
| salle séparée du dehors | oui | oui |

## Ce que ça tranche

**Le vide ciblé appartenait déjà à l'intérieur canonique avant correction**, par
un chemin bas qui n'emprunte pas la percée. Il n'avait donc pas à être rempli de
roche : ce n'est pas un défaut de vide, c'est un défaut de **couverture**. La
correction ajoute la roche qui manquait **au-dessus**, ce qui est exactement le
sens de correction préféré par la directive.

**Aucune bulle isolée n'apparaît.** 5 composantes avant, 5 après. Les deux
minuscules — 64 segments / 0,03 m³ et 1 segment / 0,00 m³ — sont présentes des
deux côtés : pré-existantes, pas créées.

## Reproduction

```sh
cd /home/user/zelda-r2a354/a_percee    # le cd porte les reperes R2a-3.5.2
python3 tools/cave_fix_connexite_interne.py assets/environment/caves/SM_WaterfallCave.glb --pas 0.06
python3 tools/cave_fix_connexite_interne.py /tmp/ref354/SM_WaterfallCave_cc3596c5.glb  --pas 0.06
```

Mes deux runs concordent **ligne pour ligne** avec les 18 lignes de mesure du
journal de l'agent (`../r2a354_percee/09_connexite_interne_avant_apres.log`) ;
seuls diffèrent l'en-tête de fichier et le `RC` global de son enveloppe.
