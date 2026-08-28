# Éclats d'Orage — essai réel, candidate « boucle de campagne »

**Ce document s'adresse à Istvan.** Rien à installer, rien à compiler, aucune
connaissance technique.

| | |
|---|---|
| Version | **CANDIDATE** — pas encore une livraison officielle |
| `PLAYABLE_SHA` | `@@SHA_LONG@@` <!-- rempli par la CI depuis le commit réellement construit --> |
| Court | `@@SHA_COURT@@` <!-- même valeur que dans le tag --> |
| Moteur | Godot 4.7.1-stable — **embarqué dans le build, rien à installer** |

Il y a **deux choses** à faire, et elles sont indépendantes. La première prend
environ dix minutes, la seconde cinq. Si tu n'as le temps que pour une, fais
la première : c'est celle qui décide si la version est bonne.

---

## Ce qui vient d'être réparé, et pourquoi j'ai besoin de toi

Le menu ouvre le **nouveau monde** (World V2) depuis quelques versions. Mais
ce monde ne portait **aucune porte** vers le donjon : le donjon existait,
était complet, et restait **inatteignable en jouant**. Et si on y entrait
autrement, en ressortir replaçait le héros à 380 mètres de la citadelle, au
point de départ.

C'est réparé, et prouvé par des tests qui **marchent réellement** jusqu'à la
porte et appuient sur la touche. Mais ces tests tournent sur une machine sans
écran : ils prouvent que la mécanique répond, **pas** que c'est jouable,
lisible ou agréable. C'est ce qu'aucune machine ne peut me dire.

---

## 1. Lancer le jeu

### Windows

Décompresser `EclatsDOrage_Windows_*.zip`, double-cliquer sur
`EclatsDOrage.exe`. Windows peut afficher « éditeur inconnu » : c'est normal
pour un jeu non signé — *Informations complémentaires* puis *Exécuter quand
même*.

### macOS

Décompresser `EclatsDOrage_macOS_*.zip`. **Clic droit** sur l'application puis
*Ouvrir* (un double-clic simple sera refusé : le jeu n'est pas signé).

### Linux

Décompresser, puis `chmod +x EclatsDOrage.x86_64` et lancer.

**Touches (AZERTY)** — Avancer `Z` · Gauche `Q` · Reculer `S` · Droite `D` ·
Courir `Maj gauche` · Sauter `Espace` · **Interagir `E`** · Frapper clic
gauche · Esquiver `Ctrl gauche` · Pause `Échap`.

---

## 2. L'essai qui compte : peux-tu ATTEINDRE le donjon ?

**Nouvelle partie.** Attends le paysage (le chargement peut prendre une
minute).

> **Tu commenceras peut-être dos à la vallée.** C'est un défaut connu et
> consigné (ISS-076), pas un piège : tourne simplement la caméra avec la
> souris pour trouver la grande masse au fond. Je ne l'ai pas corrigé dans
> cette version parce qu'elle ne devait toucher qu'à la mécanique de la
> boucle.

Puis, simplement : **descends vers la citadelle**, la grande masse au fond.
Ne cherche pas de chemin particulier — prends celui qui te paraît naturel.

Ce que j'ai besoin de savoir, dans l'ordre d'importance :

1. **Est-ce que tu comprends où aller ?** Sans que je te le dise. Si tu as
   hésité, dis-moi où.
2. **Est-ce que tu arrives à la citadelle à pied ?** Combien de temps environ.
   Si quelque chose t'a bloqué — un mur invisible, une pente infranchissable,
   une chute — dis-moi **l'endroit** : « près de la rivière », « après le
   camp ».
3. **Vois-tu la porte ?** Elle est au pied de la citadelle. Est-ce qu'elle
   ressemble à une porte, ou à un bloc posé là ?
4. **Approche-toi et appuie sur `E`.** Est-ce que ça t'emmène à l'intérieur ?
5. **Une fois dedans, ressors** (il y a une porte de sortie derrière toi).
   **Où le héros réapparaît-il ?** C'est LA question. Il doit revenir
   **devant la citadelle**, là où tu étais. S'il se retrouve au point de
   départ, tout au fond de la vallée, la correction a échoué et je veux le
   savoir avant de publier quoi que ce soit.

Si tu as le courage, continue dans le donjon et dis-moi jusqu'où tu vas.
Sois prévenu : **l'intérieur du donjon n'a jamais été parcouru par personne**.
Les salles existent et les portes se relient, mais je ne peux pas promettre
qu'on traverse. Si tu restes coincé quelque part, c'est une information utile,
pas un échec de ta part.

### Ce que tu peux me dire

Des phrases simples valent mieux qu'un diagnostic. « J'appuie sur E et rien ne
se passe », « je ne comprends pas où aller », « je suis revenu au début », « il
y a un trou dans le sol ici ». Et si tu peux, **l'endroit**.

---

## 3. Le second essai, cinq minutes : le saut

Cet essai est **indépendant** du premier et sert à une autre question : est-ce
que le héros retombe correctement ? Ma machine fait vivre au jeu une seconde
pendant que dix-sept passent en vrai — je ne peux ni l'affirmer ni le nier
d'ici.

Le protocole complet, avec le chemin du fichier à m'envoyer pour chaque
système, est dans **`docs/PROTOCOLE_SAUT_ISTVAN.md`**, joint au dépôt. En
résumé :

1. Nouvelle partie, attends le paysage.
2. `F3` — l'enregistrement démarre.
3. **Trois fois `F4` sans bouger** (ni ZQSD, ni souris), en comptant « et un,
   et deux » entre chaque. Ces trois repères donnent la hauteur du sol.
4. Puis **trois fois** : `Espace`, puis `F4` **tout de suite** pendant qu'il
   est en l'air, puis attends de **voir** les pieds au sol et `F4` encore.
5. `F3` — le fichier est écrit. Quitte le jeu.

**Neuf appuis sur `F4` en tout.** Si tu t'es trompé, refais simplement les
étapes 2 à 5 : l'outil me dira lui-même si la séquence est incomplète plutôt
que de deviner.

Envoie-moi le `journal.jsonl` du dossier le plus récent sous `dev_sessions`
(chemins exacts par système dans `PROTOCOLE_SAUT_ISTVAN.md`).

---

## Ce que cette version ne prouve PAS

Je préfère le dire avant que tu le découvres :

- **la fluidité** n'a jamais été mesurée sur une vraie carte graphique. Ce
  conteneur rend en logiciel ; un chiffre de FPS pris ici ne voudrait rien
  dire ;
- **le son, la manette, la lisibilité de l'interface** n'ont jamais été
  essayés par un être humain ;
- **l'intérieur du donjon** n'est vérifié qu'en câblage : les portes existent
  et se relient, mais personne n'a marché d'une salle à l'autre en jouant ;
- **rien de l'art** ne change dans cette version : c'est une correction de
  mécanique, et une seule.

La suite automatique est verte, ce qui veut dire qu'aucun défaut que la
machine sait mesurer n'est présent. Le compte exact de tests vit dans
`docs/TEST_REPORT.md`, daté — un nombre recopié ici se périmerait.
