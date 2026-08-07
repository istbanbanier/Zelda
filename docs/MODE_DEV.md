# Le mode développement — comment me dire ce qui ne va pas, sans rien écrire

Ce mode existe pour une seule raison : **vous n'avez pas à décrire un
problème**. Vous appuyez sur une touche au moment où quelque chose cloche, et
le jeu note tout seul l'heure, l'endroit, ce que faisait le héros, sa vie, son
endurance et une image de l'écran.

Vous m'envoyez ensuite un dossier. C'est tout.

---

## Les trois touches à retenir

| Touche | Ce qu'elle fait |
|---|---|
| **F3** | Démarre l'enregistrement (et affiche un petit panneau en haut à gauche). Rappuyer l'arrête. |
| **F4** | « Là, il y a un problème. » Note le moment et prend une image. |
| **F5** | Prend juste une image, sans rien signaler. |

Il n'y a rien d'autre à apprendre.

## Comment s'en servir, concrètement

1. Lancez le jeu normalement.
2. Appuyez sur **F3**. Un panneau apparaît en haut à gauche : c'est le signe
   que ça enregistre.
3. Jouez. Vraiment jouez, comme d'habitude.
4. **Chaque fois** que quelque chose vous surprend, vous bloque, vous semble
   moche, lent, injuste ou incompréhensible : appuyez sur **F4**. Même si
   vous n'êtes pas sûr. Même dix fois dans la partie. Un signalement de trop
   ne coûte rien ; un signalement manquant, si.
5. Quand vous arrêtez de jouer, appuyez sur **F3**. Un message vous donne le
   nom du dossier.

## Où sont les fichiers

Le jeu écrit dans un dossier caché de votre ordinateur. Le message affiché à
l'arrêt vous donne le chemin exact. Selon votre machine, la racine est :

- **Windows** : `%APPDATA%\Godot\app_userdata\Eclats d'Orage\dev_sessions`
- **macOS** : `~/Library/Application Support/Godot/app_userdata/Eclats d'Orage/dev_sessions`
- **Linux** : `~/.local/share/godot/app_userdata/Eclats d'Orage/dev_sessions`

Dans ce dossier, un sous-dossier par session, nommé avec la date et l'heure.

## Ce qu'il y a dedans

| Fichier | À quoi ça sert |
|---|---|
| `resume.md` | Un résumé lisible, en français. C'est celui à ouvrir en premier. |
| `journal.jsonl` | La liste complète des événements, seconde par seconde. C'est celui qui me sert le plus. |
| `environnement.json` | Votre machine, votre carte graphique, la taille de la fenêtre. |
| `marqueur_01.png`, … | Les images prises à chaque fois que vous avez appuyé sur F4. |

**Envoyez-moi le dossier entier.** Pas besoin de trier.

## Transformer une session en rapport

Si vous voulez un texte propre à lire ou à archiver, une commande suffit :

```bash
python3 tools/dev_report.py --dernier > rapport.md
```

Elle prend la dernière session enregistrée et en fait un rapport en français :
ce que vous avez signalé, à quel moment, les blocages d'image, le parcours, et
— honnêtement — ce que l'enregistrement ne prouve pas.

Pour une session précise, donnez son dossier à la place de `--dernier`.

## Ce que le mode dev NE fait pas

C'est important, parce que c'est ce qui rend ses traces utilisables :

- **Il ne triche pas.** Pas d'invincibilité, pas de téléportation, pas de
  valeur modifiée. Ce que vous enregistrez est une vraie partie.
- **Il n'envoie rien sur Internet.** Tout reste sur votre machine, dans le
  dossier ci-dessus. Aucune donnée personnelle n'est collectée.
- **Il ne juge pas.** Il note ce qui s'est passé ; c'est vous qui dites ce qui
  n'allait pas, avec F4.
- **Il est éteint par défaut.** Si vous n'appuyez jamais sur F3, il ne fait
  strictement rien.

## Ce que les images par seconde affichées valent

Le panneau montre un nombre d'images par seconde. **Ce nombre vaut pour votre
machine et pour cette fenêtre, rien d'autre.** Il ne prouve pas que le jeu
« tourne à 60 images par seconde » : ça, seule une mesure sur du vrai matériel,
dans une fenêtre donnée, avec un réglage donné, peut le dire. Le panneau sert à
repérer les moments où **ça saccade**, pas à décerner une note.

## Si vous ne savez pas quoi signaler

Appuyez sur F4 dès que vous vous dites une de ces phrases :

- « Je ne sais pas où aller. »
- « Je ne comprends pas ce qui vient de se passer. »
- « Ça ne répond pas comme je veux. »
- « C'est moche ici. »
- « Je suis coincé. »
- « C'est injuste. »
- « Je m'ennuie. »

Ces sept phrases sont exactement les défauts que je cherche.
