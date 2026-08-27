# Vérifier le saut — cinq minutes, lundi

Istvan, cette page ne demande **aucune connaissance technique**. Tu lances le
jeu, tu sautes trois fois, tu m'envoies un fichier. C'est tout.

## Pourquoi j'ai besoin de toi pour ça

La machine sur laquelle je travaille n'a ni écran, ni carte graphique, ni
horloge fiable : j'ai mesuré qu'elle fait vivre au jeu **une seconde pendant
que dix-sept secondes passent en vrai**. Sur une machine pareille, je ne peux
pas dire si le héros retombe correctement — ni que oui, ni que non. Je préfère
te le dire plutôt que d'affirmer quelque chose que je n'ai pas vu.

Ton PC, lui, a une horloge normale. Trois sauts chez toi valent mieux que
trois heures de mesures chez moi.

---

## Ce qu'il te faut

L'archive du jeu, celle de la Release **`world-v2-playtest-lot1r2-05d0760`**.
Si tu l'as déjà téléchargée, c'est la bonne — je n'ai rien republié depuis.

---

## Les six gestes

**1. Lance le jeu.**

**2. Clique sur « Nouvelle partie »** et attends que le paysage apparaisse.
   Le chargement peut prendre une minute : c'est normal.

**3. Appuie une fois sur `F3`.**
   Un petit panneau s'affiche en haut : l'enregistrement a démarré.

**4. Appuie sur `Espace` pour sauter. Attends que le héros soit bien
   retombé, compte « et un, et deux » dans ta tête, puis recommence.
   **Trois sauts en tout.** Ne touche à rien d'autre — ni ZQSD, ni la souris.
   Reste sur place.

**5. Appuie une fois sur `F3`.**
   Le panneau disparaît : l'enregistrement est fini et le fichier est écrit.

**6. Quitte le jeu.**

Si tu te trompes, ce n'est pas grave : refais les gestes 3 à 6. J'analyserai
le dernier enregistrement.

---

## Le fichier à m'envoyer

Colle ce chemin dans la barre d'adresse de ton explorateur de fichiers.

### Windows

```
%APPDATA%\Godot\app_userdata\Eclats d'Orage\dev_sessions
```

### macOS

Dans le Finder : menu **Aller** → **Aller au dossier…** (ou `Cmd + Maj + G`),
puis colle :

```
~/Library/Application Support/Godot/app_userdata/Eclats d'Orage/dev_sessions
```

### Linux

```
~/.local/share/godot/app_userdata/Eclats d'Orage/dev_sessions
```

**Le dossier s'appelle `Eclats d'Orage`** — sans accent sur le E, avec une
apostrophe droite. C'est le nom que le jeu utilise en interne, vérifié dans
`project.godot`. Si tu ne le trouves pas, cherche `dev_sessions` depuis ton
dossier personnel : il n'existe qu'à un seul endroit.

Tu y trouveras un dossier par enregistrement, nommé par la date et l'heure —
par exemple `20260831_140312`. **Prends le plus récent**, et envoie-moi le
fichier `journal.jsonl` qu'il contient. Il est tout petit, quelques dizaines
de kilo-octets.

Si tu préfères, zippe le dossier entier et envoie le zip : il contient aussi
les captures d'écran, qui ne me gênent pas.

---

## Ce que le fichier contient, et ce qu'il ne contient pas

Il contient : l'altitude du héros, son état, sa vie, son endurance, la scène
en cours, et les moments où le jeu a ralenti. Rien d'autre.

Il ne contient **aucune donnée personnelle** : pas de nom, pas de chemin
privé, pas d'adresse, rien qui sorte de ton ordinateur si tu ne l'envoies pas
toi-même. Le mode développement ne triche pas non plus : il n'ajoute aucune
vie, ne téléporte pas, ne modifie aucune valeur du jeu. Une session
enregistrée reste une session honnête, sinon elle ne prouverait rien.

---

## Ce que j'en ferai, en une commande

```bash
python3 tools/analyse_journal_devmode.py <journal.jsonl>
```

L'outil compare l'altitude du héros aux seuils **écrits à l'avance**, avant
toute mesure, dans `docs/contrats/s1_1_gravite.md` :

| Ce qu'il vérifie | Seuil |
|---|---|
| L'horloge de ta machine est-elle saine ? | temps moteur ≈ temps réel |
| Le héros monte-t-il vraiment ? | au moins **0,50 m** |
| Chaque montée est-elle suivie d'un retour au sol ? | oui, toutes |
| Combien d'allers-retours complets ? | **3** demandés |
| Le héros est-il debout, ni mort ni blessé ? | état `locomotion` |
| Le sol reste-t-il stable quand il ne saute pas ? | dérive ≤ **0,10 m** |

Pour information, la valeur attendue : le héros doit monter à environ
**1,40 m**, hauteur calculée à partir des réglages du jeu — vitesse de saut
8,2 m/s, gravité 24 m/s².

Trois réponses possibles, et je te donnerai celle qui sort, telle quelle :

- **vert** — la gravité est vérifiée, on referme le sujet et j'ouvre la suite ;
- **rouge** — il y a un vrai défaut, je le corrige avant toute chose ;
- **bloqué** — même chez toi la mesure ne conclut pas ; je te dirai pourquoi.

---

## Si quelque chose cloche pendant que tu joues

Le mode développement sert justement à ça. À n'importe quel moment où le jeu
te paraît anormal — un mur traversé, une chute bizarre, une image figée —
appuie sur **`F4`**. Ça pose un repère horodaté **et** une capture d'écran
dans le même dossier. Tu n'as rien à écrire ; l'horodatage fait le reste, et
je saurai exactement où regarder.

Détail complet du mode développement : `docs/MODE_DEV.md`.
