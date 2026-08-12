### Ce que j'ai fait
J'ai lancé une nouvelle partie d'« Éclats d'Orage », attendu un chargement anormalement long (bloqué à 46% pendant ~20s), puis exploré la vallée à pied depuis le point de spawn. J'ai récolté un ingrédient (« Fruit de soin »), repéré un pylône cyan, un village, une citadelle au loin et un campement avec feu de camp et auvent orange. J'ai passé le reste du temps à tenter de l'atteindre en traversant une zone marécageuse, sans parvenir à engager de combat.

### Ce que j'ai compris, et grâce à quoi
- **Contrôles de base** : Z/Q/S/D déplacent le personnage relativement à la caméra (compris en observant les changements de posture — dos, face, profil selon la touche). Espace fait sauter, E interagit/récolte, clic gauche attaque.
- **Système de récolte** : confirmé par le message explicite « Récolté : Fruit de soin » et le prompt contextuel « E — Récolter » / « Rien à portée — approchez-vous et faites face » — un vrai bon exemple de feedback clair.
- **Indices narratifs** : le message « De la fumée s'élève au loin — un campement ? » m'a orienté efficacement vers l'objectif.
- **Présence d'ennemis proches** : déduite d'une icône d'épée et de barres colorées apparues sporadiquement dans le HUD, jamais reliées à une cible identifiable à l'écran.

### Ce que j'ai tenté sans résultat
- Faire tourner la caméra à la souris : fonctionne parfois nettement, puis semble totalement figée pendant plusieurs actions consécutives sur le même arrière-plan montagneux, malgré des `mouse_delta` importants.
- Verrouiller une cible avec C : aucun réticule, aucun effet visible.
- Atteindre physiquement le feu de camp repéré à plusieurs reprises : à chaque approche finale, je retombais dans une zone d'eau/marécage (filtre gris-bleu à l'écran) qui semblait ralentir ou bloquer ma progression.
- Une attaque à l'épée dans le vide : animation jouée, aucun ennemi touché.

### Où je me suis perdu
Systématiquement dans les 50 derniers mètres avant le camp : la transition prairie → berge/eau m'a fait boucler plusieurs fois autour du même point sans jamais franchir clairement la rive pour rejoindre le foyer et les silhouettes ennemies aperçues au loin. Je n'ai jamais pu confirmer visuellement un ennemi assez proche pour l'attaquer.

### Ce qui m'a donné envie de continuer, ou d'arrêter
Envie de continuer : la vallée est agréable à parcourir, les messages contextuels (récolte, fumée au loin) donnent une vraie sensation de guidage naturel, et la citadelle électrique au loin est un bel objectif visuel. Envie d'arrêter : la caméra capricieuse et la difficulté à traverser cette dernière zone marécageuse ont cassé le rythme — j'ai passé plus de la moitié de la session à tourner autour du même camp sans jamais l'atteindre vraiment.

### Ce qui m'a semblé cassé, vide ou inachevé
- Le chargement initial bloqué à 46% pendant ~20 secondes avant de sauter directement à 100% — probablement de la compilation de shaders, mais sans indication à l'écran, ça ressemble à un freeze.
- La rotation de caméra à la souris très inconsistante (fonctionne, puis ne répond plus pendant plusieurs actions).
- Aucun ennemi jamais clairement rendu à l'écran malgré des indices HUD répétés (icône épée, barres colorées) — soit ils étaient hors-champ/masqués par le brouillard de la zone humide, soit le rendu de cette zone est défaillant (le filtre gris-bleu permanent réduisait fortement la lisibilité).
- Échelle de l'herbe très exagérée par rapport au personnage au tout début, notée mais pas gênante pour le jeu.

### Notes sur 10
- Plaisir immédiat : 5/10
- Compréhension : 6/10
- Beauté : 6/10
- Réactivité : 4/10 (caméra capricieuse, chargement long)
- Envie de continuer : 4/10 (je me suis arrêté frustré de ne pas avoir pu combattre)
