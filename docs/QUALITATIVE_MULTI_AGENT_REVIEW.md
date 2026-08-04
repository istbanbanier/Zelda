# VALIDATION QUALITATIVE MULTI-AGENTS — HUMAINS RÉELS ENCORE À CONFIRMER

Ce document n'est **pas** un playtest humain. Il porte ce titre en entier, à
chaque mention, parce que la nuance est la seule chose qui l'empêche de mentir.

## Ce qui a réellement eu lieu

| Nature | Fait ? | Comment |
|---|---|---|
| Test automatique | oui | `tools/validate_fast.sh`, 585 tests, VERT |
| Playtest en boîte noire par agent IA | oui | harnais `tools/godot/playtest_session.gd`, deux sessions, 62 captures |
| Revue qualitative multi-agents | oui | deux juges indépendants à contexte frais |
| Validation sur GPU réel | **non** | aucun GPU dans ce conteneur (ISS-002) |
| Validation par humain réel | **non** | à confirmer |

## Comment le playtest reste honnête

`PlayerInputReader` est le seul endroit du gameplay qui consulte l'InputMap
(D-013), et il lit des **actions**, jamais des touches. Le harnais injecte donc
des actions : elles traversent exactement le chemin d'un clavier — lecteur,
`InputIntent`, contrôleur, physique. Aucune téléportation, aucun appel de
méthode de victoire, aucune lecture d'état interne pour trouver une solution.

Trois sorties, séparées à dessein :

* les **captures** — tout ce que l'agent joueur reçoit ;
* le **journal** — actions et notifications lues à l'écran ;
* la **trace** — positions et états, réservée à l'intégrateur, **interdite** aux
  agents joueurs. Sans cette séparation, un agent « découvrirait » un lieu en
  lisant ses coordonnées.

Les juges rendent leur verdict **sans voir celui des autres**. C'est la
condition pour qu'un consensus veuille dire quelque chose.

## Un défaut du harnais, trouvé par le harnais

Première session : le joueur devait marcher trois secondes, il s'est retrouvé à
plus de cent mètres, dans la rivière. La cause n'était pas le jeu — le harnais
convertissait les secondes en frames en supposant 60 par seconde, alors qu'en
rendu logiciel une frame dure dix fois plus et fait avancer plusieurs ticks
physiques. Un playtest dont les durées mentent ne mesure ni le rythme, ni la
distance, ni la réponse. Corrigé : les attentes accumulent le delta réel.

## Les agents se trompent, et il faut le vérifier

Deux exemples de cette session, tous deux instructifs :

**Le joueur découverte** a écrit que trois captures étaient « strictement
identiques » et en a tiré que le saut et la touche E ne font rien. Diff pixel :
41 041 pixels diffèrent entre la capture avant et après le saut, 12 390 entre
les deux dernières. Les images ne sont **pas** identiques. Mais le fait qu'un
observateur attentif les déclare identiques **est** le constat : le saut ne
produit aucun retour perceptible sur une image fixe. Le symptôme est réel, la
cause invoquée était fausse.

**Le directeur artistique** a diagnostiqué « une directionnelle blanche
neutre, haute ». Vérification dans le code : le soleil est déjà
`#FFD68A` à 22° de plongée, venant de la gauche. Là encore, la cause était
fausse — et le symptôme réel. La mesure a tranché : sur la bande d'horizon,
toute l'image tenait entre 55 % et 80 % de valeur, monument compris. Les
ombres n'étaient pas grises par manque de soleil chaud ; elles étaient
**remplies à ras bord** par un ciel contribuant à 0,6.

D'où une règle de travail, valable pour la suite : *un rapport d'agent est une
observation, pas un diagnostic*. L'intégrateur mesure avant de corriger.

## Notes rendues

Les notes ci-dessous sont celles des agents, non retouchées. Elles portent sur
**40 et 59 secondes de jeu** — l'ouverture, pas le jeu complet. Combat, donjon
et boss n'ont pas encore été joués en boîte noire : aucun axe les concernant
n'est noté ici, et aucun ne doit être déduit.

### Joueur découverte (ouverture, 40 s)

| Axe | Note |
|---|---:|
| Plaisir immédiat | 4 |
| Envie de continuer | 5 |
| Beauté | 4 |
| Ambiance | 4 |
| Lisibilité de l'image | 6 |
| Compréhension | 3 |
| Caméra | 6 |
| Impression de finition | 3 |

Verbatim : « un prototype prometteur qu'il faut d'abord rendre **réactif**
avant de le rendre beau ».

### Directeur artistique (image de référence + 16 captures)

| Axe | Note |
|---|---:|
| Profondeur | 4 |
| Hiérarchie visuelle | 3 |
| Composition | 3 |
| Lumière | 2 |
| Palette | 3 |
| Lisibilité | 5 |
| Cohérence artistique | 2 |
| Matériaux | 3 |
| Silhouettes | 4 |
| Densité maîtrisée | 3 |
| Absence de répétition | 2 |
| Absence de placeholder dominant | 2 |
| Ambiance | 2 |

Verbatim : « le problème n'est pas que la vallée soit un graybox — c'est que
l'image n'a ni heure, ni sujet ».

## Consensus et désaccord

**Accord fort des deux juges**, sur des exemples différents :

1. le fond est un empilement de boîtes qui concurrence la citadelle ;
2. le sol est un aplat vide sur la moitié basse de presque chaque image ;
3. deux familles d'assets incompatibles cohabitent (maisons détaillées contre
   proxies non texturés) ;
4. la première impression est celle d'un prototype, pas d'un jeu.

**Désaccord** : le joueur note la lisibilité 6 et la caméra 6 — il trouve le
système sain ; le directeur artistique note la lisibilité 5 et déplore que
l'horizon soit au milieu et le héros au centre. Écart inférieur à 3 points,
donc pas d'arbitrage nécessaire ; les deux disent la même chose sous deux
angles — la caméra fonctionne, son cadrage ne compose pas.

**Vu par un seul, potentiellement grave** : le joueur découverte signale que le
compteur de vie passe de six carrés à cinq entre deux captures, sans qu'aucun
danger n'apparaisse. Non reproduit à ce jour, non expliqué. Inscrit aux
blocages restants.

## Ce que cette validation ne dit PAS

- rien sur le plaisir du combat : il n'a pas encore été joué en boîte noire ;
- rien sur le donjon, les énigmes, le boss, la conclusion ;
- rien sur la performance, la fluidité, le frame pacing — pas de GPU ;
- rien sur le son — aucun périphérique audio ;
- rien qu'un humain réel ait ressenti.

Le seuil « prêt qualitativement » n'est pas franchi : plusieurs axes sont sous
6 de médiane, et le jeu complet n'a pas été terminé en boîte noire.
