# ADDENDUM VISUEL FINAL V4 — NON BLOQUANT

Ce message complète les instructions D.1R déjà en cours. Il ne les remplace pas, ne modifie pas leur priorité et ne t’autorise pas à abandonner le sous-jalon actif.

## 1. Sécurité du travail en cours

Si tu es au milieu d’une modification D.1R :

- continue exactement le sous-jalon actuel ;
- termine la modification atomique, ses tests et son commit avant de traiter cet addendum ;
- ne fais aucun reset, revert, rebase, checkout destructif ou réécriture d’un travail valide ;
- ne mélange pas dans un même commit les corrections fonctionnelles D.1R et l’enregistrement des références visuelles ;
- ne lance pas maintenant une refonte artistique du monde si cela retarde les corrections caméra, collisions, UI fonctionnelle, limites du monde, structures ou sauvegarde ;
- ne me demande pas un nouvel arbitrage si le travail actuel peut continuer sans risque.

Cet addendum remplace uniquement les anciens concepts visuels. Il ne remplace aucune spécification fonctionnelle, aucun test, aucune décision enregistrée ni aucun travail déjà validé.

## 2. Pack visuel V4 faisant autorité

Les cinq images jointes constituent désormais l’unique référence visuelle V4 :

1. `01_WORLD_NORTHSTAR_FINAL_V4.png`
2. `02_DUNGEON_ENTRANCE_FINAL_V4.png`
3. `03_GAMEPLAY_HUD_FINAL_V4.png`
4. `04_INVENTORY_FINAL_V4.png`
5. `05_PAUSE_MENU_FINAL_V4.png`

Au prochain point de sauvegarde sûr, idéalement après la livraison D.1R, copie-les dans :

`source_assets/concepts/final_v4/`

Enregistre leur provenance dans `ATTRIBUTIONS.md` et actualise seulement les sections nécessaires de la bible visuelle. Fais-le dans un commit documentaire séparé.

Si les images ne sont pas réellement accessibles dans ton espace de travail, signale-le en une phrase puis continue D.1R. Ne bloque jamais le développement en les attendant.

## 3. Statut des images

Ce sont des références de composition, ambiance, profondeur, palette, architecture et hiérarchie d’interface.

Elles ne doivent jamais être utilisées directement comme :

- arrière-plan de gameplay ;
- skybox représentant un faux monde explorable ;
- billboard, matte painting ou façade plate ;
- texture d’interface contenant de fausses valeurs ;
- capture présentée comme l’état réel du jeu.

Le résultat doit être reconstruit avec de vrais environnements 3D, de vraies collisions, de vraies structures visitables et une interface Godot alimentée par l’état réel du jeu.

Ne déclare jamais que la build correspond aux concepts sans capture provenant réellement de Godot et sans validation fonctionnelle.

## 4. Direction d’ambiance commune

Le jeu doit conserver le meilleur des versions lumineuse et sombre :

- vallée chaude, dorée, riche et attirante ;
- menace froide concentrée autour de la citadelle, jamais un monde entièrement sombre ;
- soleil de fin d’après-midi venant de la gauche ;
- orage ardoise localisé au-dessus de la citadelle ;
- transition visuelle progressive entre sécurité dorée et danger froid ;
- forte profondeur atmosphérique : premier plan, plan intermédiaire et arrière-plan ;
- végétation animée par le vent, poussière, brume, ombres de nuages et rais de lumière ;
- cyan rare, réservé à l’électricité, aux repères et aux interactions importantes ;
- matériaux tactiles : grès ocre, basalte charbon, bronze vieilli, céramique ivoire ;
- aucune copie de personnage, symbole, interface, architecture ou objet appartenant à Zelda, Nintendo ou une autre licence.

L’implémentation doit rester originale et compatible avec les capacités réelles du projet Godot.

## 5. Monde — référence 01

La vue du monde fixe les relations spatiales à préserver :

- crête de départ au premier plan ;
- personnage original lisible mais assez petit pour montrer l’échelle ;
- camp ennemi visible dans le bas de la vallée ;
- routes et sentiers guidant naturellement la descente ;
- rivière turquoise formant une courbe en S ;
- ruines, ponts et bâtiments répartis sur plusieurs plans ;
- pylône électrique à droite comme repère secondaire ;
- citadelle centrale lointaine comme objectif principal ;
- montagnes et mesas formant des frontières naturelles crédibles ;
- chaque destination visible doit sembler physiquement atteignable.

Ne remplis pas le monde avec du décor aléatoire. Chaque élément doit aider l’orientation, la traversée, le combat, l’exploration ou la narration environnementale.

## 6. Donjon — référence 02

Les proportions monumentales sont non négociables :

- le personnage est clairement dominé par la masse du bâtiment ;
- la façade dépasse le cadre et possède une structure porteuse crédible ;
- la porte centrale est gigantesque, ouverte et réellement franchissable ;
- des escaliers et un chemin conduisent clairement à l’intérieur ;
- le vestibule jouable reste visible sur environ 20 à 30 mètres ;
- le joueur doit distinguer sol, colonnes, plafond, braseros, mécanisme électrique, routes latérales et second seuil ;
- l’ouverture ne doit jamais être un rectangle noir, une façade plate ou un téléporteur dissimulé sans retour visuel honnête.

Une transition vers une scène intérieure séparée est acceptable si elle est stable, rapide, réversible et visuellement cohérente.

## 7. HUD — référence 03

Le HUD final doit être minimal et alimenté uniquement par des données réelles :

- fragments rubis en haut à gauche pour la vie ;
- jauge de stamina turquoise discrète près du personnage pendant son utilisation ;
- réticule de verrouillage et vie de la cible lorsque le ciblage est actif ;
- invite contextuelle `E — Interagir` seulement lorsqu’une interaction valide est possible ;
- arme équipée, durabilité segmentée et nombre réel de flèches en bas à droite ;
- aucune mini-carte permanente, aucun faux objectif et aucun compteur décoratif.

Les formes doivent rester originales : pas de cœurs, de roue de stamina ou d’icônes copiées d’une licence existante.

## 8. Inventaire — référence 04

L’écran doit refléter exactement les règles déjà établies :

- huit emplacements d’armes maximum, ni plus ni moins ;
- aucun doublon d’instance ;
- flèches stockées séparément ;
- emplacements vides clairement visibles ;
- sélection clavier/souris lisible ;
- équiper une arme ;
- passer à l’arme suivante ;
- déplacer ou réordonner une arme si cette fonction est livrée ;
- statistiques, dégâts, portée, durabilité et conductivité lus depuis `WeaponDefinition` et l’instance équipée ;
- aucune valeur recopiée en dur dans l’interface ;
- toute arme ramassée dans un coffre ou au sol actualise immédiatement l’inventaire et le HUD ;
- un inventaire plein refuse proprement le ramassage sans détruire l’objet.

Ne rends pas actifs des onglets ou systèmes qui n’existent pas encore. Un élément futur doit être absent ou explicitement désactivé, jamais simulé.

## 9. Pause et sensibilité — référence 05

Le menu pause doit être réellement fonctionnel :

- `Échap` ouvre et ferme le menu ;
- le monde, les ennemis et le combat sont effectivement suspendus ;
- la souris est libérée dans le menu et recapturée à la reprise ;
- aucun clic ou mouvement du menu ne déclenche une attaque ou une action dans le monde ;
- `Reprendre`, `Inventaire`, `Options`, `Commandes` et `Retour au menu` fonctionnent ou sont honnêtement désactivés ;
- le réglage `Sensibilité souris` agit immédiatement sur la caméra ;
- sa valeur est bornée, affichée et conservée après fermeture, changement de scène et relance ;
- `Inverser axe Y` doit fonctionner s’il est affiché ; sinon, ne l’affiche pas encore ;
- clavier AZERTY et navigation souris doivent être testés.

## 10. Construction Godot

Construis l’interface avec de vrais nœuds Godot : `CanvasLayer`, `Control`, `Container`, `GridContainer`, `PanelContainer`, `Label`, `TextureRect`, `ProgressBar`, `HSlider`, boutons et ressources `Theme` adaptées.

Exigences :

- ancres et conteneurs responsifs ;
- zones sûres respectées en 1280×720 et 1920×1080 ;
- aucune coordonnée magique fragile si un conteneur peut l’éviter ;
- navigation au clavier et focus visibles ;
- séparation entre données de jeu et présentation ;
- mises à jour par signaux, sans polling inutile ;
- aucune texture plein écran servant à simuler l’interface ;
- les concepts peuvent guider les couleurs et proportions, mais les composants doivent rester modulaires et testables.

## 11. Ordre et critères de validation

Priorité immédiate : terminer D.1R. N’applique la passe visuelle complète qu’après stabilisation fonctionnelle et nouveau playtest humain.

Avant de déclarer les écrans terminés, prouve au minimum :

1. la vie et la stamina du HUD suivent l’état réel du joueur ;
2. l’arme, la durabilité et les flèches se synchronisent avec l’inventaire ;
3. ramassage, coffre, équipement, changement d’arme et casse se reflètent à l’écran ;
4. l’inventaire respecte la limite de huit et le refus sans perte ;
5. la pause stoppe réellement la simulation et empêche les entrées de traverser ;
6. la sensibilité modifie immédiatement la rotation et persiste ;
7. l’interface reste lisible aux deux résolutions cibles ;
8. aucune erreur, référence invalide ou donnée fictive n’apparaît ;
9. `validate_fast` reste vert et les tests ciblés sont ajoutés ;
10. les captures de livraison proviennent de la vraie build Godot.

## 12. Réponse attendue maintenant

Réponds brièvement avec :

1. confirmation que le pack V4 remplace les anciennes références visuelles ;
2. nom du sous-jalon D.1R actuellement poursuivi ;
3. point de commit sûr auquel le pack sera versionné.

Puis reprends immédiatement le sous-jalon en cours. Pas de longue analyse, pas de nouvelle roadmap et pas de changement de priorité.
