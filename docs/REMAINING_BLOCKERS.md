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

**BL-18 — Le kit végétal était posé à son échelle native.** Trouvé par le
premier playtest en boucle fermée (`decouverte_A_20260804_021956`, capture
`pas_0036_act.png`) : une fleur jaune occupe un quart de l'écran et dépasse la
poitrine d'un héros d'1,78 m. Mesure : `Flower_4_Group` = **2,49 m**, quand la
bible §3 borne les fleurs à 0,18–0,55 m ; `Fern_1` = **9,05 m de large**.
Violation de l'invariant « 1 unité = 1 m ». **CORRIGÉ** par `KitScale`, point
unique consulté par les sept modules de placement, avec deux tests de
régression (source et vallée montée).

**BL-19 — La jauge d'endurance flotte à côté du héros, pas au-dessus.**
Capture `pas_0069_act.png` : la barre bleue est à environ 150 px à droite du
personnage, détachée, à hauteur de poitrine. §17.2 demande une « endurance
contextuelle près du héros ». Non expliqué, non reproduit à ce jour.

**BL-21 — Hors prairie, le sol est un aplat vert absolument nu.** Capture
`pas_0086_act.png` : le joueur a quitté la crête, la moitié basse de l'image
est un vert uniforme sans un caillou, sans une trace, sans une variation de
teinte, et l'arrière-plan est un mur de boîtes beiges sans perspective
atmosphérique. C'est la forme la plus sévère de `BL-06`, vue cette fois en
cours de traversée et non depuis le point d'ouverture.

**BL-22 — « Bloqué près des arbres », à reproduire.** Le joueur écrit au pas 73
qu'il est « régulièrement bloqué près des arbres, possible collision qui
empêche l'avancée ». Vérification faite : les collisions de tronc sont des
`BoxShape3D` de `size` 1 × 5 × 1 m, et `size` est bien la dimension PLEINE en
Godot 4 — rien d'anormal à la lecture. Le symptôme est donc réel mais la cause
supposée par le joueur n'est pas démontrée : **observation, pas diagnostic**.
À reproduire avec la trace avant toute correction.

**BL-20 — Le visage du héros est un aplat sous la capuche.** Capture
`pas_0073_act.png`, vue de face à quelques mètres : aucun trait lisible. §13.2
demande un visage original et crédible, « même si la caméra montre surtout le
dos », avec des expressions minimales.

## 6. Placeholders dominants et ambiance

**BL-09 — Trois récompenses sur dix sont des primitives brutes** : une sphère
rouge, une sphère beige, un cylindre. Ce sont les ingrédients, qui n'ont pas de
modèle.

**BL-10 — Le fond est un empilement de boîtes qui concurrence la citadelle.**
Mesure : sur la bande d'horizon, toute l'image tient entre 55 % et 80 % de
valeur. Après le lot « ombres froides », 57 % à 81 %. **L'écart passe de 25 à
24 points : négligeable, et dans le mauvais sens.** Les deux lots visuels
(horizon étagé, ombres froides) sont donc classés **NON CONCLUANTS** — ils ne
sont pas démontrés. Un diff de pixels n'est pas une amélioration esthétique, et
une mesure qui ne va pas dans le sens annoncé n'autorise aucune revendication.

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
