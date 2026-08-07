# Comment travailler avec le propriétaire de ce projet

Le propriétaire est **débutant total** : ni game dev, ni Godot, ni git, ni
terminal. Il ne peut pas relire un diff, ni juger un shader, ni réparer un
dépôt cassé. Mais il est le SEUL à pouvoir jouer au jeu sur un vrai écran,
et ses remarques ont été, jusqu'ici, la meilleure source de défauts du
projet — meilleure que les tests, meilleure que les audits.

Ce fichier existe parce que chaque session repart de zéro et refait les
mêmes erreurs. Les règles ci-dessous ne sont pas des préférences : chacune
est née d'un dégât réel, daté, qu'on peut retrouver dans l'historique.

## 1. UNE SEULE SESSION À LA FOIS SUR CE DÉPÔT

C'est la règle la plus coûteuse à enfreindre, et elle l'a été le 2026-08-07.

Trois sessions ont travaillé en parallèle. Résultat mesuré :

- deux branches ont divergé et le jeu s'est retrouvé coupé en deux moitiés ;
  les archives livrées au propriétaire ne contenaient qu'une moitié, pendant
  qu'il croyait avoir le tout ;
- une session a affirmé au propriétaire que le vol libre et la monture
  « n'existent pas » après avoir cherché dans **une seule branche** — ils
  existaient, sur une autre ;
- des tests ont échoué pour des raisons qui n'appartenaient à personne, et
  il a fallu recréer l'état d'avant dans un dépôt détaché pour trancher ;
- une fusion à six conflits a coûté une session entière.

Si une autre session tourne, **dis-le au propriétaire et propose d'attendre**.
Aucune fonctionnalité ne vaut un dépôt qui bouge sous les pieds.

## 2. VÉRIFIER DANS TOUT LE DÉPÔT, PAS DANS SON ARBRE DE TRAVAIL

Corollaire direct du point 1, et erreur commise deux fois le même jour.

Avant d'affirmer qu'une chose n'existe pas :

```bash
git fetch origin '+refs/heads/*:refs/remotes/origin/*'
for b in $(git branch -r | grep -v HEAD); do git ls-tree -r --name-only "$b" | grep -i MOTIF; done
```

Et avant d'affirmer qu'une chose est **dans l'archive livrée** — ce qui est
la seule question qui intéresse le propriétaire :

```bash
git merge-base --is-ancestor <commit> <tag_de_l_archive> && echo DEDANS || echo DEHORS
```

Chercher dans `HEAD` ne prouve rien sur ce que le joueur a téléchargé.

## 3. NE PUBLIER QU'APRÈS LE VERDICT DES TESTS

Deux archives ont été livrées avant que `tools/validate_fast.sh` ait parlé.
La première contenait des adversaires posés en travers de la route du
donjon : le propriétaire pouvait rester bloqué. « Les scripts parsent » n'est
pas « les tests passent », et la suite met une vingtaine de minutes — ce
n'est pas une raison de s'en passer, c'est une raison de le dire et
d'attendre.

## 4. LA PRUDENCE VA DU CÔTÉ DE L'AUTOMATIQUE

Le 2026-08-07, un workflow de ménage a supprimé l'archive jouable qui venait
d'être livrée. La cause n'était pas un accident : l'essai à blanc protégeait
le bouton **manuel**, et le déclenchement **automatique** partait en
suppression directe. La prudence était du mauvais côté.

Règle : tout ce qui se déclenche sans qu'un humain l'ait demandé doit avoir
le comportement le plus inoffensif par défaut. Une suppression se demande,
elle ne s'hérite pas.

## 5. LE PROPRIÉTAIRE NE NOTE RIEN, MAIS IL VOIT TOUT

Ne jamais lui demander d'arbitrer un shader, une licence, un compromis de
performance, une grille de notation. En revanche, ses observations brutes
valent de l'or, et l'historique le prouve :

| Ce qu'il a dit | Ce que ça a révélé |
|---|---|
| « les murs sont pas fermés » | 117 défauts d'assemblage dans TOUT le monde bâti |
| « je trouve le jeu pas très jouable » | caméra à 102° au lieu de 71°, herbe géante, aucun son |
| « pourquoi c'est toujours 400 Mo ? » | la taille ne prouve rien — d'où le numéro de commit dans chaque livraison |
| « ils ont déjà été créés » | deux branches divergentes, jamais fusionnées |

Le mode développement (`F3` pour enregistrer, `F4` pour signaler) existe pour
ça : voir `docs/MODE_DEV.md`. Un dossier de session vaut mieux que dix pages
d'analyse — il donne l'endroit, l'heure, l'état et l'image.

## 6. UN OBJECTIF PAR SESSION

Une session qui dérive — passe d'art, puis jouabilité, puis mode dev, puis
ménage GitHub, puis fusion — livre moins qu'une session qui finit une chose.
Quand le propriétaire ouvre un nouveau front, c'est légitime : note l'ancien
dans `docs/PROGRESS.md` avec sa prochaine action exacte, et dis clairement ce
qui est mis de côté.

## 7. DIRE CE QUI N'A PAS ÉTÉ VÉRIFIÉ

Le propriétaire ne peut pas contrôler ce qu'on lui dit. C'est précisément
pour ça que l'honnêteté doit être plus stricte, pas moins. Trois formules
interdites, et leur remplacement :

| Interdit | À dire à la place |
|---|---|
| « le jeu tourne à 60 FPS » | « la fluidité reste à confirmer sur un vrai PC » |
| « tout est vert » avant la suite | « les scripts parsent ; j'attends les tests » |
| « ça n'existe pas » après un seul `grep` | « je n'ai pas trouvé dans X ; je vérifie ailleurs » |
