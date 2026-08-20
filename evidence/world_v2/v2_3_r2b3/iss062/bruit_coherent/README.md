# ISS-062 — le SECOND trou, trouvé par l'audit adverse et fermé par le lead

Le contrôle de rectangularité fermait la SOUDURE. Il ne fermait pas le
BRUIT COHÉRENT, et les deux se combinent.

## Le contournement

Partir du GLB saboté (18 pavés droits par tas, soudés par les coins) et
déplacer chaque POSITION UNIQUE de 2 mm. Le bruit est appliqué par position
et non par sommet : les coins soudés le restent, donc le nombre de
composantes ne bouge pas et l'ancien portail reste aveugle. Mais les faces
cessent d'être planes à mieux que 1 mm, donc `part_rectangulaire` s'effondre
à 38,80 % — et `min(RECT, ortho)` la retient.

2 mm sur des arêtes de 189 mm : **1,06 %**. Cela ne se voit pas.
À 1 mm le contrôle mordait encore ; à 2 mm il ne mordait plus.
**La marge de l'instrument contre le bruit valait UN millimètre.**

## Ce que l'agent avait et n'a pas dit

`limite_bruitage.txt`, dernier tableau : à 20 mm de bruit, indice 2,77 % et
boîtitude 0,00 % — **les deux portails aveugles, sur la même page**. Ce
fichier n'a ni en-tête, ni commande, ni script producteur, et n'est cité
nulle part dans le rapport ni dans la section « ce que l'instrument ne
mesure pas ». La mesure existait ; elle n'a pas été portée.

## La correction, dérivée par la règle DÉJÀ écrite

Un `min` protège contre le cas où une seule grandeur suffirait à ABSOUDRE.
Il ne protège pas contre le cas où une seule grandeur suffit à ACCUSER.
D'où un **second plafond, indépendant, sur `part_orthogonale` seule**.

Même règle pré-enregistrée, appliquée à `ortho` sur la famille
NATURE/DÉBRIS : M = 4,80 (arbre foudroyé ; les deux tas de gravats du kit
sont à 0,00) → plafond = floor((4,80+100)/2) = **52**, marge M+10 tenue.

| | part_orthogonale | verdict |
|---|---:|---|
| sujet livré | 14,97 % | PASS |
| pylône accepté | 15,68 % | PASS |
| pont accepté | 6,46 % | PASS |
| mur accepté | 4,53 % | PASS |
| **sabotage soudé** | **100,00 %** | **FAIL** |
| **bruit cohérent 2 mm** | **100,00 %** | **FAIL** |
| bruit 20 mm | 92,72 % | FAIL |
| bruit 50 mm | 63,50 % | FAIL |

## Cycle rouge/vert, joué par le lead

```
sujet livré              filet RC=0   RECT=0.32%  ortho=15.00%
contre-exemple 2 mm      filet RC=1   RECT=38.80% ortho=100.00%  — 1 seul écart
restauration             filet RC=0   RECT=0.32%  ortho=15.00%
sha256 après restauration ead79105e3deaf70…  IDENTIQUE à l'octet près
git status --porcelain assets/  ->  0 ligne
```

L'`indice_boite` reste à 38,80 % sous le plafond de 51 sur le contre-exemple :
c'est bien le **second** plafond qui mord, et lui seul — un écart, variable unique.

## Ce que cela ne prouve toujours pas

Qu'un tas soit beau. Deux instruments de familles différentes rendent la
régression difficile ; ils ne remplacent pas un œil. ISS-062 reste OUVERT :
rien ne dit qu'il n'existe pas un troisième contournement.
