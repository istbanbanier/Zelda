# Le test que la machine ne peut pas faire — 10 minutes

Ce protocole vous est destiné. Il ne demande **aucune** console, aucun fichier à
ouvrir, aucune note sur 100. Vos observations brutes valent plus que toute
analyse : « je tombe ici », « rien ne se passe », « je ne comprends pas quoi
faire » ont trouvé plus de défauts que les tests.

Ce qui suit est **hors de portée de la machine** : il n'y a ici ni écran, ni
souris, ni clavier, ni son, ni carte graphique. Ces points restent donc marqués
`BLOQUÉ` tant que vous ne les avez pas essayés — quels que soient les tests.

## 1. Lancer

Ouvrir le projet dans Godot **4.7.1** et appuyer sur **F5**.

Si une fenêtre s'ouvre et qu'un menu apparaît, c'est gagné pour cette étape.
Si quelque chose s'affiche en rouge ou si rien ne s'ouvre : **arrêtez-vous là**
et dites-le. Le reste n'a pas d'intérêt tant que ça ne marche pas.

## 2. Les touches (AZERTY d'abord)

| Faire | Toucher |
|---|---|
| Avancer | **Z** |
| Gauche | **Q** |
| Reculer | **S** |
| Droite | **D** |
| Courir | **Maj gauche** |
| Sauter | **Espace** |
| Interagir | **E** |
| Frapper | **clic gauche** |
| Esquiver | **Ctrl gauche** |
| Pause | **Échap** |

**Le point le plus important de toute cette page** : appuyez sur **Q** et
regardez si le héros va bien **à gauche**. C'est un invariant du projet qu'aucun
test ne peut vérifier — la machine vérifie le câblage, pas l'appui.

## 3. Ce qu'il faut essayer, dans l'ordre

Prenez dix minutes, pas plus. Vous n'avez rien à finir.

1. Depuis le menu, lancez une **nouvelle partie**. *(Si une sauvegarde existe, le
   bouton demande une confirmation : appuyez une seconde fois.)*
2. **Regardez trois secondes sans rien toucher.** Sauriez-vous dire où aller ?
3. Avancez, tournez la caméra, courez, sautez.
4. Approchez-vous d'un objet et appuyez sur **E**.
5. Trouvez un ennemi et frappez-le.
6. Laissez-vous tuer, puis appuyez sur **Réessayer**.
7. Marchez vers la grande construction au fond et essayez d'y entrer.

## 4. Ce qu'il faut me rapporter

**Des phrases simples, pas un diagnostic.** Ce sont les meilleures :

- « je tombe à travers le sol ici » ;
- « la caméra entre dans le héros » ;
- « j'appuie sur E et rien ne se passe » ;
- « je ne comprends pas où aller » ;
- « l'ennemi me traverse » ;
- « c'est saccadé quand je cours » ;
- « le texte est trop petit » ;
- « je n'entends rien ».

Si vous pouvez, notez **l'endroit** : « près de la rivière », « en descendant de
la colline ». Ça suffit à retrouver le lieu exact.

## 4 bis. Un point précis, si vous atteignez le donjon

Devant la grande porte du fond de la citadelle, **placez-vous bien en face, au
milieu**, et appuyez sur **E**.

Un test a trouvé qu'à cet endroit exact l'invite ne répond pas : une veine
lumineuse décorative posée devant le battant coupe la ligne de vue. Un pas de
côté et la porte s'ouvre. Dites-moi simplement si vous constatez la même chose —
c'est le genre de détail qui fait croire qu'une touche ne marche pas.

## 5. Le mode développement, si vous voulez

Il existe et il est fait pour ça — voir `docs/MODE_DEV.md` :

- **F3** enregistre la session ;
- **F4** signale un défaut à l'endroit où vous êtes.

Un dossier de session vaut mieux que dix pages d'analyse : il donne le lieu,
l'heure, l'état et l'image. Mais **ce n'est pas obligatoire** — une phrase suffit.

## 6. Ce que je ne vous demanderai jamais

- de lire un diff ou du code ;
- d'arbitrer un shader, une licence ou un compromis de performance ;
- de noter quoi que ce soit sur 100 ;
- d'ouvrir une console ou un fichier de journal.

Si je vous demande l'une de ces choses, c'est une erreur de ma part.
