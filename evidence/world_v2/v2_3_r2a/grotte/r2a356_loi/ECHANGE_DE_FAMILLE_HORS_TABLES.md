# Une famille de roches a été échangée entre le livré et le candidat

Statut : **VÉRIFIÉ** par moi, par AST sur les deux sources, le 2026-08-17.
Portée : instruit TICKET-B4 sans le clore.

## Le constat

`main()` ne pose pas les mêmes familles de roches dans les deux arbres.

| arbre | familles posées par `main()` |
|---|---|
| tronc — **la géométrie livrée**, `8bf1a1b3` | `assise_enterree`, `rochers_dos_alcove`, **`rochers_gaine`**, `rochers_semelle` |
| candidat R2a-3.5.x, `a_epaisseur` | `assise_enterree`, `rochers_dos_alcove`, `rochers_semelle`, **`rochers_calotte_nord`** |

Méthode : `ast.parse`, puis collecte des `ast.Call` dans le corps de `main()`.
Pas de `grep` — un `grep` sur `rochers_gaine` rend **six** occurrences dans le
candidat, toutes des mentions en commentaire, dont une qui affirme le contraire
de ce que le code fait. C'est le piège de `tools/CLAUDE.md` : *« vérifier en
relisant l'endroit exact, pas en cherchant une valeur »*.

## Ce que la fonction retirée faisait

Le commentaire du candidat, aux lignes 5534-5552, le dit chiffres en main :

> Ses **84 roches**, faîte 5,98 m, comblent le col A depuis le porche.
> `enveloppe seule` → 3 masses, cols 1,36 / 0,74 ;
> `enveloppe + gaine + semelle` → **2 masses**.

Le retrait est donc **délibéré et motivé par la composition**, pas un oubli. Il
protège l'invariant 3/3/3. La raison est bonne ; ce qui manquait, c'est que
personne n'avait relié ce retrait aux comparaisons faites ensuite.

## Pourquoi cela instruit TICKET-B4

TICKET-B4 porte sur un constat de l'agent B qu'il a lui-même classé
`NON VÉRIFIÉ` :

> V10 laisse 22 `cav×cav` : la table de R2a-3.4 replaquée sur le code courant
> produit des replis qu'elle ne produisait pas à l'époque. **Autre chose que les
> tables a changé entre-temps, non identifié.**

Une famille de 84 roches retirée et une autre ajoutée est **exactement** un
changement de cette forme : il ne touche ni `CAVITE`, ni `CAVITE_ASYM`, ni
`MASSIF`, donc **aucune comparaison de tables ne peut le voir**. L'agent B avait
d'ailleurs vérifié que `anneau_interieur()`, `tangentes()` et `phases()` étaient
identiques — il cherchait au bon endroit, dans le mauvais registre.

Cela ne clôt pas le ticket : que le changement soit *de la bonne forme* ne prouve
pas qu'il soit *la cause*. La mesure qui trancherait est de rejouer V10 en
réintroduisant `rochers_gaine()`, et de voir si les 22 disparaissent.

## Une correction que je me dois à moi-même

L'agent C a écrit « `rochers_gaine()` est du code mort ; `main()` n'y figure
pas ». C'est vrai **de son arbre**, faux du tronc — où l'appel est à la ligne
4002 et où la fonction est bien vivante. Ma première lecture, par `grep` sur le
tronc, semblait le contredire ; c'est en fait nous deux qui mesurions deux
arbres différents sans le dire.

La règle de `COMMENT_TRAVAILLER_ENSEMBLE` §2 s'applique mot pour mot :
**vérifier dans tout le dépôt, pas dans son arbre de travail.** Ici la variante
est plus insidieuse — l'affirmation était juste, seul son périmètre manquait.
Toute phrase de la forme « la fonction X n'est pas appelée » doit nommer
l'arbre.

## Conséquence directe sur la passe

La différence entre le livré et le candidat n'est **pas** réductible à un
déplacement de tables. Elle comprend au moins un échange de famille de roches
motivé par la composition. Tout raisonnement de la forme « comme en R2a-3.4 »
reste donc suspect, et la formulation de l'agent B est la bonne :

> aucune comparaison « comme en R2a-3.4 » n'est fiable tant que TICKET-B4 tient.
