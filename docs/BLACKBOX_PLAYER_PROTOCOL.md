# Joueur visuel en boîte noire — protocole

Ce document dit **comment on joue** et **ce qui compte comme preuve**.
L'architecture est décrite à part (`BLACKBOX_PLAYER_ARCHITECTURE.md`).

## Lancer une session

```bash
tools/blackbox_player/play.sh <profil> <parcours> [tours_max]
tools/blackbox_player/play.sh decouverte A 45
```

Une session à la fois. `play.sh` tue tout Godot et tout Xvfb avant de démarrer :
en rendu logiciel, deux instances se disputent le processeur et faussent les
durées, ce qui rendrait tout jugement de rythme faux.

Contrôle de plomberie, à relancer après toute modification du serveur :

```bash
python3 tools/blackbox_player/smoke_test.py
```

Il vérifie trois choses et rien de plus : la poignée de main MCP, une image de
plus de 5 ko qui commence par les octets `PNG`, et une touche réelle qui change
l'image. **Il ne prouve rien sur le jeu.**

## La boucle, imposée par le protocole

À chaque pas, le joueur doit produire, dans cet ordre :

1. **Observation** — ce qu'il voit vraiment, pas ce qu'il suppose derrière.
2. **Objectif supposé** et **confiance de 0 à 5**.
3. **Décision écrite AVANT l'appel d'outil**, avec le résultat attendu.
4. **Une seule action**.
5. **Comparaison** : ce qui était attendu s'est-il produit ?

Chaque outil renvoie la nouvelle image. Le joueur ne peut donc pas enchaîner
deux actions sans regarder : l'observation lui est imposée par la forme du
protocole, pas par une consigne qu'il pourrait ignorer.

**Signal d'alarme :** si plusieurs dizaines d'actions existent avant la
première capture, la session est scénarisée et ne compte pas.

## Durées humaines

| Situation | Durée |
|---|---|
| S'orienter | 100–400 ms |
| Tourner la caméra | 100–500 ms |
| Combat réactif | 150–350 ms |
| Se déplacer vers un objet proche | 300–1200 ms |
| Avancer sur un chemin dégagé | 1000–2500 ms |
| Attendre un chargement ou une animation | jusqu'à 8000 ms |

Les cinq premières lignes sont des **actions** et sont plafonnées à 2500 ms :
un joueur qui agit regarde souvent. La dernière est une **non-action** ; la
plafonner à 2500 ms forcerait des décisions artificielles pendant un écran de
chargement, ce qui a été constaté dès la première session (`decouverte_A`, huit
attentes consécutives sur un fondu). Attendre n'est pas décider.

Jamais trente secondes sans regarder, dans tous les cas.

## Ce que le joueur n'a pas le droit de faire

Ces interdits ne sont pas des consignes de bonne conduite : les outils
correspondants ne lui ont pas été donnés, et `--disallowedTools` les refuse.

- lire le code, une scène, une sauvegarde, un test, une trace ;
- lire les rapports des autres joueurs ;
- connaître une coordonnée, un identifiant de lieu, un navmesh ;
- se téléporter, appeler une méthode de gameplay, modifier une santé ou un objet ;
- envoyer une entrée impossible au clavier (touche hors liste blanche : refusée) ;
- valider un lieu « par ses coordonnées » — seule l'image compte.

## Six profils

| Profil | Ce qu'il apporte |
|---|---|
| `decouverte` | n'a presque jamais joué en 3D ; révèle ce qui n'est pas enseigné |
| `experimente` | quinze ans de jeux d'action ; exigeant sur réactivité et lisibilité |
| `occasionnel` | veut comprendre en une minute ; révèle les frictions d'entrée |
| `explorateur` | fouille les coins et les hauteurs ; trouve les vides et l'inachevé |
| `prudent` | observe avant d'agir, revient en arrière ; révèle les impasses |
| `presse` | fonce et râle ; révèle ce qui casse quand on ne suit pas le chemin |

Chaque profil a **sa propre conversation, sa propre sauvegarde, sa propre
trajectoire et son propre verdict**. Aucun ne lit le verdict d'un autre : c'est
la condition pour qu'un accord entre eux veuille dire quelque chose.

## Cinq parcours

| Parcours | Objectif donné, et rien de plus |
|---|---|
| A | découvrir, approcher le campement, **gagner un combat** |
| B | inventaire, armes, objets ramassés — comprendre ce qu'on porte |
| C | trouver l'entrée du grand bâtiment et progresser dans ses salles |
| D | aller au bout, affronter ce qui l'occupe, **terminer le jeu** |
| E | explorer, décrire chaque lieu atteint, dire s'il semble fini ou vide |

Seul un objectif **général** est donné. Jamais un chemin, jamais une solution,
jamais un nom de lieu que le jeu n'affiche pas.

## Preuves produites

`evidence/blackbox_player/<profil>_<parcours>_<horodatage>/` :

| Fichier | Contenu |
|---|---|
| `captures/pas_NNNN_<outil>.png` | tout ce que le joueur a vu, dans l'ordre |
| `trajectory.jsonl` | un objet par appel : outil, touches, souris, durée, capture |
| `player_memory.json` | ce que le joueur a noté lui-même |
| `godot_stdout.log` | sortie du jeu — pour l'intégrateur, jamais pour le joueur |
| `verdict.md` | le compte rendu, tel qu'il l'a écrit |
| `replay_report.md` | rejeu de la trajectoire **sans suspension** |

La trajectoire est écrite pour l'**intégrateur**. Le joueur n'a aucun moyen de
la lire — il n'a pas l'outil `Read`.

## Le rejeu sans suspension

Le verrouillage par pas fausse la durée perçue. Un enchaînement jugé
confortable sous suspension doit être rejoué **sans** SIGSTOP avant qu'on
affirme qu'il est jouable. Ce rejeu est un **contrôle de faisabilité**, pas un
nouveau playtest : il ne produit aucune note et aucun jugement.

## Quand le joueur est bloqué

Il n'a pas droit à un indice. Il écrit son modèle mental — « je crois que je
dois X, je n'y arrive pas parce que Y » — et la tentative se clôt **comme un
échec de joueur réel**. Ce n'est pas une erreur de manipulation à effacer :
c'est le résultat.

Ensuite seulement, l'intégrateur lit le code et la trace, corrige, et **un
autre agent, neuf**, rejoue. Jamais le même : un joueur qui a déjà buté connaît
la réponse.

## Contrôles négatifs

Un protocole qu'on ne peut pas faire échouer ne prouve rien. Trois contrôles,
dans `tools/blackbox_player/negative_controls.py` :

| Contrôle | Attendu |
|---|---|
| remplacer l'image renvoyée par une capture périmée | le joueur doit s'en apercevoir ou décrire des faits incohérents |
| retirer l'outil d'observation | le joueur doit être bloqué, pas continuer de raconter le jeu |
| démarrer sur une scène inconnue de lui | le joueur doit repartir d'une analyse, pas d'un savoir antérieur |

Si le joueur « joue » toujours aussi bien sans image, c'est qu'il improvise et
que tous les verdicts sont sans valeur.

## Ce que ce protocole ne mesure pas

Ni la fluidité, ni le frame pacing, ni le son, ni le ressenti d'une main
humaine sur un clavier. Rendu logiciel, sans GPU, sans audio. Les verdicts
portent le nom exact de ce qu'ils sont : **PLAYTEST VISUEL EN BOÎTE NOIRE PAR
AGENT IA**, distinct de `VALIDATION SUR GPU RÉEL` et de `VALIDATION PAR HUMAIN
RÉEL`, qui restent à confirmer.
