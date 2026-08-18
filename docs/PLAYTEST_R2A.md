# Éclats d'Orage — checkpoint jouable R2a

**Ce document s'adresse à Istvan.** Il n'y a rien à installer, rien à compiler,
et aucune connaissance technique n'est nécessaire.

| | |
|---|---|
| Version | checkpoint R2a |
| `PLAYABLE_SHA` | `413360d727c9957d615b8d06964d19c83323c837` |
| Court | `413360d` |
| Dépôt propre à la construction | `repo_dirty: false` |
| Moteur | Godot 4.7.1-stable — **embarqué dans le build, rien à installer** |
| Grotte livrée | `SM_WaterfallCave.glb`, empreinte `8bf1a1b309aee79f` (R2a-3.4) |

**Aucun candidat R2a-3.5.x n'est dans cette version.** Les corrections de la
grotte des trois dernières passes existent, sont mesurées, et sont **exclues** :
elles n'ont pas passé leur portail de collision. Ce build est la géométrie
R2a-3.4, celle qui a été validée.

---

## 1. Lancer le jeu

### Version navigateur — la plus simple

1. Télécharger et **décompresser** l'archive `EclatsDOrage_Web_*.zip`.
2. Ouvrir un terminal **dans le dossier décompressé**.
3. Lancer :

   ```bash
   python3 -m http.server 8000
   ```

4. Ouvrir **http://localhost:8000** dans Chrome ou Firefox.

> **Un double-clic sur `index.html` ne marchera pas.** Les navigateurs refusent
> de charger un jeu depuis un fichier local ; c'est une règle de sécurité, pas un
> défaut. Le petit serveur ci-dessus existe pour ça et s'arrête avec `Ctrl+C`.

### Version macOS

1. Décompresser `EclatsDOrage_macOS_*.zip`.
2. **Clic droit** sur `EclatsDOrage.app`, puis **« Ouvrir »**, et confirmer.

> Un double-clic ordinaire sera **refusé la première fois**. L'application n'est
> pas signée par Apple — cela demande un compte développeur payant que le projet
> n'a pas. Le clic droit ne sert qu'une seule fois ; ensuite l'app s'ouvre
> normalement. Ce n'est pas un défaut du jeu.

Les versions Windows et Linux sont publiées aussi, au cas où.

---

## 2. Les touches — clavier AZERTY

Relevées **une par une dans le fichier de configuration**, pas recopiées.

| Action | Touche |
|---|---|
| Avancer | **Z** |
| Aller à gauche | **Q** |
| Reculer | **S** |
| Aller à droite | **D** |
| Sauter | **Espace** |
| Courir | **Maj gauche** (maintenir) |
| Interagir, ramasser, ouvrir | **E** |
| Frapper | **clic gauche** |
| Frapper lourd | **R** |
| Viser à l'arc | **clic droit** |
| Esquiver | **Ctrl gauche** |
| Verrouiller une cible | **C** |
| Cible suivante / précédente | **V** / **X** |
| Inventaire | **Tab** |
| Plat rapide | **F** |
| Pause | **Échap** |

### Le Bracelet de Résonance

| Action | Touche |
|---|---|
| Impulsion — révèle ce qui réagit | **A** |
| Focus — viser une cible du bracelet | **G** |
| Mise à la terre | **T** |

### Manette

Une manette est reconnue : stick gauche pour se déplacer, **A/Croix** pour
sauter, **X/Carré** pour interagir, **RB/R1** pour frapper, **B/Rond** pour
esquiver, stick droit pressé pour verrouiller. Elle **n'a jamais été essayée** —
voir §5.

### Un outil de dépannage, au cas où vous seriez coincé

**F4** active un mode de vol libre ; **Espace** monte, **Ctrl** descend. Ce n'est
pas une fonctionnalité du jeu, c'est un outil de développement laissé en place
volontairement : si vous tombez à travers le sol ou restez bloqué, il vous
permet de vous dégager et de continuer, plutôt que de tout recommencer.

---

## 3. À quoi sert cette version

**Ce n'est pas une démo, c'est une question.** Le jeu a été construit dans un
conteneur **sans écran, sans clavier, sans manette et sans carte graphique**. La
machine a vérifié tout ce qu'une machine peut vérifier. Elle n'a jamais pu
vérifier ce qui compte : est-ce que c'est **agréable**.

Votre partie est la première.

---

## 4. Ce qu'il y a à voir

- **la vallée de Néris** : la partie la plus travaillée. Terrain, rivière,
  végétation, lumière d'orage ;
- **la grotte de la cascade**, le pont de pierre, le pylône et le hameau : les
  quatre lieux qui ont reçu le plus de soin ;
- **le camp** et ses adversaires ;
- **le donjon** : l'entrée et la salle 1 sont atteignables normalement.

---

## 5. Ce qui n'est PAS fini, et il faut le savoir avant de jouer

Cette liste est écrite pour éviter de vous faire chercher des choses qui
n'existent pas.

- **Au-delà de la salle 1 du donjon, rien n'a été atteint depuis une partie
  normale.** Les salles 2 à 4, la salle centrale, l'antichambre, le boss et la
  victoire existent et fonctionnent séparément, mais **personne n'a vérifié
  qu'on y arrive en jouant**.
- **La manette n'a jamais été essayée.** Ni ici, ni ailleurs.
- **Le son n'a jamais été entendu.** Le conteneur n'a pas de périphérique audio.
- **La version navigateur est plus pauvre visuellement** que la version macOS,
  et c'est normal : les navigateurs ne savent pas faire le rendu que le jeu
  utilise. Elle démarre et se joue, mais le brouillard, les reflets et une
  partie de l'éclairage y sont absents. Si vous voulez juger l'image, prenez la
  version macOS.
- **La grotte de la cascade a un défaut connu et mesuré** : quatre petits
  recouvrements de sa forme de collision. Ils ne devraient rien changer pour
  vous — c'est la raison pour laquelle la correction n'a pas été livrée, elle
  aurait ajouté un mur invisible dans la niche à récompense.

---

## 6. Comment me dire ce qui ne va pas

**Des phrases simples valent mieux qu'un diagnostic.**

> « je tombe à travers le sol ici » · « j'appuie sur E et il ne se passe rien » ·
> « je ne comprends pas où aller » · « ça rame quand je cours » ·
> « je ne vois rien dans la grotte »

**Si vous pouvez, dites l'endroit** : « près de la rivière », « en sortant du
camp », « dans la grotte, à droite ». C'est ce qui coûte le moins à écrire et ce
qui sert le plus.

### Faire une capture

- **macOS** : `Maj + Cmd + 4` puis Espace, cliquer sur la fenêtre du jeu.
  L'image va sur le Bureau.
- **Navigateur** : `Maj + Cmd + 4` de la même façon.

Une capture floue prise au téléphone suffit largement. Ce qui compte est de voir
**où** vous étiez.

### Le mode développement, si vous voulez aider davantage

**F3** enregistre une session : position, heure, état. Ce n'est pas nécessaire —
une phrase et une capture suffisent. Détail dans `docs/MODE_DEV.md`.
