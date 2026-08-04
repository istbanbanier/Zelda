# Blocages restants

Classés par la priorité de correction de l'ordre de validation qualitative :
crash et softlock d'abord, finition en dernier. Chaque entrée dit **où c'est
visible**, pour qu'on puisse la contredire.

## 1. Crash, corruption, softlock

Aucun constaté à ce jour. Deux sessions de playtest en boîte noire (99 s de jeu
cumulées) et 585 tests automatiques n'en ont produit aucun. Ce n'est pas une
preuve d'absence : ni le donjon, ni le boss, ni la conclusion n'ont été joués
en boîte noire.

## 2. Impossibilité de terminer

**BL-01 — Le jeu complet n'a jamais été terminé en boîte noire.** Le parcours
prouvé jusqu'ici s'arrête à la traversée de la vallée. Le donjon, le boss et
l'écran de conclusion n'ont été franchis que par des tests automatiques, qui
prouvent une liaison, pas une compréhension. Tant que ce parcours n'existe pas,
aucun verdict « le jeu est finissable par un joueur » n'est recevable.

## 3. Perte de contrôle, incompréhension

**BL-02 — Le jeu ne répond visiblement pas aux actions.** Le joueur découverte,
après 40 s : « Espace ne montre rien, E ne montre rien, pas même un refus ». Le
diff pixel montre que les images changent (41 041 pixels après le saut), donc
le jeu *fait* quelque chose — mais un observateur attentif ne le voit pas.
§7.13 exige que chaque action importante combine au moins deux retours.
Preuve : `evidence/playtest/decouverte_01/shot_011` à `shot_012`.

**BL-03 — Aucun objectif n'est jamais affiché.** Aucun titre de zone, aucun
objectif, aucune boussole en 40 s. Le joueur a déduit son but de la couleur du
décor. Cela peut être un choix (guidage par la curiosité, §6.3) — mais alors
il faut que le monde réponde, ce qui renvoie à BL-02.

**BL-04 — Le compteur de vie change sans cause visible.** Six carrés et un
losange doré sur une capture, cinq carrés sans losange sur la suivante, sans
qu'aucun danger n'apparaisse. Vu par un seul agent, non reproduit, non
expliqué. `evidence/playtest/decouverte_01/shot_009` puis `shot_011`.

## 4. Collision, caméra, combat, inventaire, sauvegarde

**BL-05 — Cassure de terrain visible.** Un plan vert vif à arête franche
occupe la moitié droite du cadre, avec un arbre poussant dessus. Signalé
indépendamment par les deux agents. `evidence/playtest/decouverte_01/shot_014`.

## 5. Ennui, répétition, mauvaise récompense

**BL-06 — Le sol est vide sur la moitié basse de presque chaque image.** La
prairie s'arrête net à la crête ; au-delà, un aplat vert sans variation, sans
caillou, sans trace. Les deux agents le citent comme cause d'ennui.

**BL-07 — Le même coffre au même angle dans quatre lieux sur dix.** Un lieu
devrait se reconnaître à sa récompense. `evidence/rewards/`.

**BL-08 — Six lieux portent une récompense sans condition d'ouverture.** Les
cinq territoires et la cavité de cristal : le coffre est réel et persistant, le
verrou « territoire nettoyé » n'existe pas. `DiscoveryRewards.deferred_gates()`.

## 6. Placeholders dominants et ambiance

**BL-09 — Trois récompenses sur dix sont des primitives brutes** : une sphère
rouge, une sphère beige, un cylindre. Ce sont les ingrédients, qui n'ont pas de
modèle.

**BL-10 — Le fond est un empilement de boîtes qui concurrence la citadelle.**
Mesure : sur la bande d'horizon, toute l'image tient entre 55 % et 80 % de
valeur. Après le lot « ombres froides », 57 % à 81 % — le gain est réel et
modeste, le problème demeure.

**BL-11 — Le nuage d'orage est un disque plat.** Deux ellipses noires opaques,
sans volume ni éclairement interne.

**BL-12 — Cinq armes sur six n'ont pas de texture** (ISS-020, partiellement
corrigé : elles ont un modèle, pas de cartes peintes).

**BL-13 — Le menu principal affiche un bouton « Debug — Audit d'entrée » et un
« Options » grisé.** Le bouton est conditionné à `OS.is_debug_build()`, ce qui
est vrai pour l'archive livrée — le joueur le voit donc. Et l'absence
d'options prive le joueur de sensibilité souris, de volume et du rappel des
touches avant de jouer, ce que §12.3 exige.

## 7. Finition

**BL-14 — Herbe qui blanchit à distance**, tiges grises sans teinte.
**BL-15 — Chemin de terre parfaitement rectiligne à bords nets.**
**BL-16 — Rochers posés sans contact** : ni creux, ni mousse, ni ombre.
**BL-17 — Le héros n'a pas sa couleur signature turquoise** (§13.1 la demande).

## Ce qui n'est PAS un blocage et qu'il ne faut pas casser

Relevé par le directeur artistique, et je le confirme :

- l'herbe du premier plan — le meilleur asset du jeu ;
- la silhouette du héros de dos, lisible en aplat noir ;
- les arbres feuillus et le hameau — le langage painterly visé ;
- la rareté du cyan, discipline tenue ;
- l'eau et la brume de la Chute du Voile, seule vraie atmosphère du lot ;
- l'interface d'inventaire, sobre et lisible.
