# Ces lames minces sont-elles au-dessus de la galerie, ou au-dessus de bulles ?

**C'est la mesure qui rend l'arbitrage tractable**, et elle n'était pas possible
avant cette passe : elle exige un maillage **fermé**, ce que
`../r2a353_topologie/` vient d'établir contre une affirmation que j'avais moi-même
versionnée.

## Pourquoi la question

R2a-3.5.3 mesure des lames de roche sous `EPAISSEUR_MIN_M = 0,80 m` : **167** sur
le candidat, **232** sur `BASE352`, **326** sur la géométrie **livrée**. Toutes
ces lames ne disent pas la même chose :

- une lame au-dessus d'un vide **relié à la galerie** est à une décimation d'être
  un trou dans l'espace où le joueur se tient ;
- une lame au-dessus d'une **bulle isolée** du massif est un défaut de contrat
  qui ne peut produire aucun symptôme visible.

Sans cette distinction, « 167 » et « 326 » sont des nombres qui ne répondent à
aucune question.

## Deux définitions d'épaisseur, publiées ensemble

- **première dalle** — la membrane immédiate au-dessus du vide. Répond à *« y
  a-t-il une lame fine ici »*.
- **cumul** — toute la roche au-dessus, dalles empilées. Répond à *« ce vide
  voit-il le ciel »*. C'est la définition que `controle_epaisseur` se donne à
  lui-même.

Elles divergent dès qu'un second vide existe plus haut, et c'est **exactement**
le cas qui sépare une membrane interne d'un trou. L'agent A a trouvé la même
distinction de son côté, sur la colonne R2a-3.4 en `(−0,20 ; −2,60)` :

```
roche 0,957 | vide 0,471 | roche 0,020 | vide 2,768 | roche 2,602
```

Le vide de 0,471 ne qualifie pas ; `première` tombe sur la lame de 2 cm, `cumul`
additionne 0,957 + 0,020 = 0,977 et passe le seuil. **Les deux ont raison sur des
questions différentes.** Publier un seul nombre choisirait la réponse avant de
mesurer.

## LE RÉSULTAT

Vide qualifiant ≥ 1,00 m ; graine = `MODELE_SALLE` ; pas 0,10 m ; **maillage
visuel seul**.

| géométrie | roche mince **sur la galerie** *(cumul < 0,80)* | membrane interne *(cumul ≥ 0,80)* | bulle isolée |
|---|---:|---:|---:|
| candidat `cc3596c5` | **205** | 0 | 11 |
| `BASE352` `8bc8b9f9` | **276** | 0 | 6 |
| **R2a-3.4 LIVRÉE** `8bf1a1b3` | **202** | 64 | 307 |

Trois lectures, et aucune ne va dans le sens attendu :

1. **Sur le critère qui compte — la roche mince au-dessus de l'espace jouable —
   le candidat et la géométrie livrée sont équivalents : 205 contre 202.** Ce
   n'est ni une régression ni une amélioration. Le « facteur dix » annoncé à la
   passe précédente était le minimum dans une **fenêtre** de 5 × 3 m, pas sur le
   domaine.
2. **Le lot collerette améliore réellement les choses** : `BASE352` 276 → candidat
   **205**, soit **−26 %**. C'est son apport, et il était invisible jusqu'ici.
3. **La géométrie livrée porte 307 bulles internes** contre 11 pour le candidat.
   C'est ISS-050 mesuré à l'échelle : sur ce critère le candidat est très
   nettement meilleur.

**Aucune des trois géométries ne tient le contrat, et aucune n'en approche.**
Corriger la seule lame de `(0,50 ; 5,80)` changerait **1 colonne sur 205**.

Sur le candidat, **0 des 205 lames reliées** possède un banc de roche au-dessus :
elles sont minces de bout en bout. Sur R2a-3.4, **64 sur 266** sont des membranes
internes protégées par un banc — ce qui explique une partie de son meilleur
score.

## La niche et la salle sont dans la même composante de vide

Sur les trois géométries. La récompense n'est pas isolée du trajet — condition
nécessaire, pas suffisante : ce contrôle ne dit rien du gabarit ni de la pente.

## L'outil a refusé de deviner, et c'était le bon comportement

Semé avec les repères **courants**, il ne trouve **aucun vide** à l'altitude de
`MODELE_SALLE` sur R2a-3.4 et s'arrête : *« graine introuvable — on ne devine pas
la galerie »*. C'est la symétrie exacte du §27.3 du handoff — les repères ont été
re-dérivés pour la cavité neuve, donc les **nouveaux** tombent dans la roche de
l'**ancienne** géométrie. D'où `--anciens-reperes`, employé pour R2a-3.4 et
imprimé dans le journal.

Un outil qui aurait « trouvé le vide le plus proche » aurait rendu un nombre
plausible et faux.

## Deux pièges payés par quelqu'un, évités ici

1. **Le `.glb` contient deux maillages.** `COL_WaterfallCave`, la coque de
   collision, **rebouche la galerie**. Les mesurer ensemble rend « 3,06 m de
   roche continue » là où il y en a 0,038, et fait conclure que le défaut
   n'existe pas — c'est l'erreur que l'agent A a commise, tracée et publiée. On
   filtre `SM_WaterfallCave`, et l'outil **lève** si le nœud est absent.
2. **La lecture de parité s'écrit une fois**, dans une fonction nommée. Trois
   verdicts faux avant un juste ont été payés pour l'apprendre.

## Ce que cette mesure NE dit pas

- **rien du gabarit ni de la praticabilité** : « relié en tant que vide » n'est
  pas « parcourable » ;
- **rien de l'étanchéité** : elle ne cherche pas si l'intérieur rejoint le dehors,
  c'est le mandat de l'oracle global ;
- **rien sur la direction de la mesure** : les colonnes sont **verticales**. Une
  paroi latérale mince ne s'y voit pas, par construction. Le contrat de paroi se
  mesure selon la normale, ailleurs.

## Reproduction

```sh
python3 tools/cave_void_connectivity.py <fichier.glb>                      # reperes courants
python3 tools/cave_void_connectivity.py <fichier.glb> --anciens-reperes    # geometrie R2a-3.4
```

Journal : `connexite.log`, empreintes lues **avant** mesure.
