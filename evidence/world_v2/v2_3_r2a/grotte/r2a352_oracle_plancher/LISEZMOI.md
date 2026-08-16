# Le plancher des stations terminales, mesuré par un instrument qui ne sait pas où est la galerie

**Ce dossier ne valide aucune livraison.** Il répond à une seule question, posée
par la directive R2a-3.5.2 : les stations 6 à 8 ont-elles un plancher ?

La réponse mesurée est **oui**, et le « défaut de plancher » que j'avais moi-même
inscrit au cahier des charges de cette passe **n'existe pas dans la roche**.

## Pourquoi un cinquième instrument

Quatre contrôles disaient déjà que le plancher est sain. Trois d'entre eux —
`controle_plancher()` du générateur, le contrôle 1 de la sonde sur
`points_interieurs`, la carte de l'agent plancher — placent leurs points de la
**même** façon : depuis une station `u`, le long de la normale locale,
multipliés par `facteur_lateral`. Ils partagent le calcul central dont la
variante fautive venait d'être démasquée dans `carte_du_plancher()`.

Trois instruments d'accord entre eux ne prouvent rien s'ils peuvent se tromper
ensemble. La directive l'écrit : « une fonction de placement commune ne doit pas
pouvoir aveugler les deux ».

`tools/audit_cave_floor_columns.py` ne connaît ni `CAVITE_ASYM`, ni
`facteur_lateral`, ni `normale_de_cavite`, ni `u`. **Il ne sait pas où est la
galerie.** Il balaie des colonnes verticales sur toute l'emprise du modèle et lit
l'alternance roche/vide par parité d'impacts. Un vide où l'on tient debout,
coiffé de roche, doit reposer sur de la roche.

## Les cinq passages

Journal brut complet : `journal_oracle.txt`. Résumé, tous au pas de 0,25 m :

| | géométrie | vides habitables | ouverts | roche sous le sol, minimum | verdict |
|---|---|---:|---:|---:|---|
| **A** | R2a-3.5.2, global | 358 | **0** | **2,521 m** | PASS |
| **B** | R2a-3.5.2, fenêtre des stations terminales | 33 dans la fenêtre | **0** | **2,887 m** | PASS |
| **C** | idem, sous-sol retiré sous z = 0,00 | 358 | 0 | 2,887 m | PASS |
| **D** | idem, **plancher lui-même retiré** sous z = 0,60 | 338 | **21** | — | **FAIL** |
| **E** | tronc R2a-3.4 **livré** | 922 | 15 | **0,139 m** | FAIL |

**B est la réponse à la question posée.** Sous les 33 colonnes habitables des
stations terminales, il y a au minimum **2,89 m** de roche continue. Ce n'est pas
un plancher limite, c'est un plancher massif.

## L'oracle peut rougir, et on l'a fait rougir

Un contrôle qui n'a jamais échoué n'est pas un contrôle. **D** retire 319
triangles — le plancher des stations terminales — du **même maillage** que A et
B, et l'oracle passe immédiatement au rouge : 21 colonnes ouvertes, toutes dans
la fenêtre du sabotage, et le compte de vides bornés tombe de 358 à 338.

**C** est le contre-contrôle, et il compte autant : on retire seulement le
sous-sol *sous* le plancher, en laissant la peau du plancher en place. L'oracle
**reste vert**, parce que le joueur ne tombe pas. Un instrument qui rougirait
aussi là serait un instrument nerveux, pas un instrument juste.

## Ce que E dit, et surtout ce qu'il ne dit pas

Les 15 ouvertures du tronc livré se répartissent : **7 à l'aplomb de la bouche**
— où l'absence de plancher dans le modèle est le comportement voulu, le terrain
le fournit — et **8 au bord aminci du massif**, entre x −8,5 et −6,8, à huit
mètres de la galerie. **E n'est donc pas un constat de trou dans le plancher de
la grotte livrée**, et il ne doit pas être cité comme tel.

Le différentiel réel entre les deux géométries est ailleurs, et il est net :

| | tronc R2a-3.4 | R2a-3.5.2 |
|---|---:|---:|
| roche sous le sol, minimum | **0,139 m** | **2,521 m** |
| vides dont la roche sous le sol est < 0,30 m | 1 sur 924 | **0 sur 358** |

## Ce que cet oracle ne mesure pas

Il ne mesure ni la **pente** du plancher, ni sa **continuité** le long d'un
parcours, ni le **gabarit**. Un plancher présent mais en marches d'escalier
passerait ici. Il répond à « y a-t-il de la roche sous le vide », pas à « ce sol
est-il praticable ». Publier l'un pour l'autre referait exactement la faute que
cette passe traque : un seul nombre, qui répond à une autre question que celle
posée.

## Trois inversions, toutes de ma main, en une heure

L'oracle a rendu **trois verdicts faux avant d'en rendre un juste**, et les trois
fautes sont la même :

1. **« parité impaire = vide ouvert »** — c'est l'exact contraire. Un rayon
   descendant qui compte un nombre impair d'impacts a fini sa course *dans* la
   roche. L'oracle a accusé de « plancher absent » trois colonnes dont le rayon
   s'enfonçait de trois mètres dans la matière.
2. **`sous = None` traité comme « pas de plancher »** — même inversion, dans
   l'autre branche du même fichier, vingt minutes plus tard. Quatre colonnes du
   tronc, au sol infiniment épais, déclarées trouées.
3. **Le minimum d'épaisseur ignorait la fenêtre du verdict** — après avoir
   saboté les stations terminales, l'oracle imprimait encore « minimum 2,521 m »,
   chiffre exact mais mesuré à la bouche. Un chiffre juste au mauvais endroit est
   un chiffre faux.

La leçon n'est pas « la parité est subtile ». Elle est : **quand un rayon cesse
de rencontrer des faces, cela veut dire PLEIN**, et cette lecture s'écrit *une*
fois — pas une fois par branche, où on la redérive et où on se trompe. Elle est
consignée dans `tools/CLAUDE.md`.

## Fichiers

| fichier | contenu |
|---|---|
| `journal_oracle.txt` | les cinq passages, sortie intégrale, code retour de chacun |

Les empreintes des deux maillages mesurés figurent en tête du journal. Aucun
seuil n'a été modifié. Aucune géométrie n'est versée au chemin livrable par ce
dossier.

---

## Addendum — mon instrument de coupe a crié au loup, et j'ai vérifié plutôt que choisir

En mesurant la géométrie de l'agent collerette, `tools/plot_cave_section.py` a
signalé **24 rayons sous le minimum contractuel de paroi de 0,80 m**, dont un à
**0,12 m** vers la station 4,75. Le générateur, lui, publie 0,87 m et passe.

Deux chiffres pour la même grandeur : la situation exacte que cette passe traque.
La tentation est de choisir celui qui arrange. J'ai regardé ce que le rayon
traverse réellement :

```
u 4.75 az 190  ->  ROCHE 0.20   vide 1.10   ROCHE 3.84
u 5.00 az 190  ->  ROCHE 0.76   vide 0.36   ROCHE 3.94
u 4.75 az 180  ->  ROCHE 0.45   vide 1.74   ROCHE 3.21
u 5.25 az 180  ->  ROCHE 0.58   vide 0.18   ROCHE 0.35  vide 0.91  ROCHE 3.30
```

Le premier bloc mince n'est **pas la paroi** : c'est une **nervure intérieure**
entre la galerie et la poche de la salle/alcôve, suivie d'un vide court, puis de
3,2 à 3,9 m de roche vers l'extérieur. `controle_epaisseur` a raison, et sa
docstring avait anticipé le cas mot pour mot — « un rayon effleurait d'abord le
bord d'un rocher secondaire avant d'atteindre la paroi. Ce n'est pas la paroi. »

**Mon instrument avait tort sur le contrat de paroi**, et sa limite est
maintenant nommée : `premiere` ne vaut « la paroi » que s'il n'y a aucune
structure entre l'axe et le dehors. Sur une cavité à poche latérale, il n'y en a
pas la garantie.

Ce que le signal dit quand même, et qui reste vrai : **il existe des vides de
0,18 à 1,74 m à l'intérieur du massif**, entre la galerie et la paroi, vers les
stations 4,75 à 5,25 du côté large. Invisibles au joueur, sans effet sur le
contrat, mais le massif n'est pas plein à cet endroit. Consigné, non bloquant.

Et le fait qui compte pour la passe en cours : ces 24 cases sont **identiques
avant et après** l'ajout de la visière — 24 des deux côtés, à `u ≥ 1`. Elles
préexistent à la base R2a-3.5.2 et ne sont pas l'œuvre de la collerette.
