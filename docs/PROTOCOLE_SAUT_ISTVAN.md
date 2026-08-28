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

L'archive du jeu, celle de la Release **`world-v2-candidate-iss073-…`** — la
plus récente, marquée « pré-publication ».

**Ce n'est plus `world-v2-playtest-lot1r2-05d0760`.** Cette page pointait
dessus jusqu'au 2026-08-28 ; entre-temps la boucle de campagne a été réparée
(ISS-073) et une nouvelle candidate a été publiée. Les gestes ci-dessous sont
identiques, mais la mesure doit venir de la build que je vais promouvoir, pas
de celle d'avant — sinon je validerais une gravité sur un jeu qui n'est plus
celui qu'on livre.

Le protocole complet de cette candidate, essai de la boucle compris, est dans
`docs/PLAYTEST_ISS073.md`, joint à la Release.

---

## Les gestes — compte, ne chronomètre pas

Le jeu enregistre tout seul une position par seconde. **Ça ne suffit pas** :
un saut ne dure que sept dixièmes de seconde, donc l'enregistrement
automatique le rate presque toujours. C'est toi qui poses les repères, avec
`F4`, aux instants qui comptent.

Rien n'est chronométré. Tu regardes l'écran et tu appuies.

---

**1. Lance le jeu, clique sur « Nouvelle partie »**, attends que le paysage
apparaisse. Le chargement peut prendre une minute.

**2. `F3`** — un petit panneau s'affiche : l'enregistrement a démarré.

**3. Trois fois `F4`, sans bouger**, en comptant « et un, et deux » entre
chaque. **Ne touche à rien d'autre** : ni ZQSD, ni la souris. Ces trois
repères disent à quelle hauteur est le sol sous les pieds du héros. C'est la
mesure la plus importante des trois : tout le reste s'y compare.

**4. Puis, trois fois de suite, ces trois gestes dans cet ordre :**

&nbsp;&nbsp;&nbsp;&nbsp;**a.** `Espace` — le héros saute.
&nbsp;&nbsp;&nbsp;&nbsp;**b.** `F4` **tout de suite**, pendant qu'il est en
l'air, sans attendre. Vise le moment où il est haut ; si tu appuies un peu
tard, ce n'est pas grave.
&nbsp;&nbsp;&nbsp;&nbsp;**c.** Attends de **voir** qu'il a bien reposé les
pieds au sol, compte « et un, et deux », puis `F4` de nouveau.

Recommence depuis **a**. Trois sauts en tout.

**5. `F3`** — le panneau disparaît, le fichier est écrit.

**6. Quitte le jeu.**

---

### Le compte, pour vérifier

**Neuf appuis sur `F4` en tout** : trois au repos, puis deux par saut.

Si tu en as fait plus ou moins, ce n'est pas grave — **refais simplement les
gestes 2 à 6**. J'analyse le dernier enregistrement, et l'outil me dira
lui-même si la séquence est incomplète plutôt que de deviner.

### Pourquoi deux repères par saut, et pas un

Le premier dit **jusqu'où il monte**. Le second dit **s'il redescend
vraiment au sol**. Les deux questions sont différentes, et c'est la seconde
qui m'intéresse le plus : un héros qui monte mais ne retombe pas exactement
là où il était trahirait un défaut que je ne peux pas voir d'ici.

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
| Les neuf repères sont bien là | sinon il refuse de conclure |
| Le sol, pris comme la **médiane** de tes trois premiers repères | jamais le point le plus bas — voir plus bas |
| Le sol ne bouge pas pendant les trois repos | dérive ≤ **0,10 m** |
| Chaque montée dépasse le sol | d'au moins **0,50 m** |
| Chaque retour revient au sol | à **0,20 m** près |
| Le héros est debout, ni mort ni blessé | état `locomotion` |
| L'horloge de ta machine est saine | contrôle **à part**, qui n'annule pas les repères |

**Pourquoi la médiane et pas le point le plus bas.** Si le héros trébuche une
fois dans un creux, ce creux deviendrait le « sol » et tout se mesurerait
depuis un plancher qui n'existe pas. J'ai construit le cas : un héros qui
**ne saute jamais** mais oscille de 0,6 m serait déclaré faire trois beaux
sauts. La médiane de trois relevés ne bouge pas pour un accident — il en
faudrait deux. La démonstration est dans
`evidence/.../appareil/preuve_mediane_contre_minimum.md`.

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
