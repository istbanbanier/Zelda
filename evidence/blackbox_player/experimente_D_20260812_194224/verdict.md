J'ai atteint la limite d'actions prévue pour cette session de test. Je conclus mon rapport.

### Ce que j'ai fait

J'ai lancé une nouvelle partie d'« Éclats d'Orage », traversé la vallée depuis le point de départ (colline herbeuse) jusqu'au camp/village situé au pied de la citadelle, en franchissant une rivière à gué, en contournant des murs, rochers et arbres, et en testant la caméra libre à la souris. Une fois dans le camp, un PNJ m'a attaqué ; j'ai engagé un combat à l'épée (clics gauches répétés) qui a duré la fin de la session, sans jamais atteindre l'entrée de la citadelle elle-même — l'objectif « aller jusqu'au bout du bâtiment et affronter ce qui l'occupe » n'a donc été que partiellement rempli : j'ai affronté un occupant du camp, pas le gardien du bâtiment.

### Ce que j'ai compris, et grâce à quoi

- Les contrôles ZQSD + Shift (sprint) + souris (caméra) fonctionnent, mais la caméra ne réagit qu'à des mouvements de souris assez amples (des `mouse_delta` de 150 px n'ont produit aucun effet visible, alors que 400-600 px faisaient tourner la vue de façon quasi complète) — je l'ai déduit en comparant plusieurs captures consécutives à delta croissant.
- L'endurance (jauge bleue au-dessus du personnage) se régénère vite dès qu'on arrête de sprinter — observé en alternant `z` seul et `z+shift`.
- Le combat existe et a un effet réel : ma vie est passée de 5 à 4 cœurs (visible sur le HUD) après le premier contact avec le PNJ hostile, et une barre de vie ennemie (bleue) a fini par apparaître après plusieurs coups portés — donc un système de ciblage/santé existe, avec un affichage retardé.
- Le monde est cohérent avec la bible visuelle : héros de dos avec capuche turquoise, palette dorée/verte, citadelle massive au loin sous un nuage d'orage avec éclair, camp aux tentes marron — je l'ai vu directement à l'écran dès la première capture après chargement.

### Ce que j'ai tenté sans résultat

- Interagir avec un socle de pierre surmonté d'un cube jaune lumineux rencontré en chemin : aucune invite d'interaction (`E`) n'est apparue, je suis passé à côté sans retour.
- Faire baisser visiblement la barre de vie de l'ennemi du camp malgré 5-6 attaques au clic gauche consécutives : elle est restée pleine (bleu foncé) sur toute la durée observée, sans effet d'impact clair (pas d'étincelle, de flash ou de recul net).
- Atteindre la citadelle elle-même : je m'en suis approché à plusieurs reprises mais j'ai été dérouté par le camp et son occupant avant d'en franchir l'entrée.

### Où je me suis perdu

Je me suis perdu dans la navigation à la caméra libre : plusieurs de mes rotations de souris m'ont fait perdre la citadelle du cadre et m'ont redirigé malgré moi vers le camp latéral plutôt que vers l'entrée principale du bâtiment. Le manque de repère directionnel permanent (pas de boussole, pas de marqueur d'objectif) combiné à une caméra qui tourne par à-coups m'a fait tourner en rond autour du camp sans jamais localiser clairement l'entrée de la citadelle.

### Ce qui m'a donné envie de continuer, ou d'arrêter

Envie de continuer : la vue d'ouverture est immédiatement lisible et engageante (citadelle, orage, camp, tous visibles dès le lancement), et le déplacement/sprint est réactif dès la première pression de touche — bon accroche initiale. Envie d'arrêter : le combat contre le PNJ du camp, qui a occupé la fin de ma session sans jamais donner de signal clair de progression (barre de vie ennemie figée, pas de mort visible, pas de loot), a cassé mon élan vers l'objectif principal et créé une frustration proche du sentiment d'être bloqué sans le comprendre.

### Ce qui m'a semblé cassé, vide ou inachevé

- Le chargement initial figé à 45% pendant ~18-26 secondes sans aucune indication (pas de texte « compilation en cours », juste une barre immobile) : ressemble fortement à un softlock au premier lancement, même si le jeu a fini par démarrer.
- Une masse de terrain plate vert clair, totalement sans texture ni relief, visible près de l'étang devant le camp — clairement un élément non fini ou un proxy géométrique oublié.
- Le feedback de combat est insuffisant : pas de barre de vie ennemie visible avant plusieurs coups, aucun effet visuel clair d'impact, l'arme du héros disparaît puis réapparaît de façon incohérente entre deux captures consécutives lors des attaques.
- Aucun point de sauvegarde, boussole ou marqueur de quête rencontré en une quinzaine de minutes de jeu, ce qui rend l'orientation vers l'objectif principal (la citadelle) difficile à maintenir face aux distractions latérales (camp).

### Notes sur 10

| Critère | Note | Justification courte |
|---|---|---|
| Plaisir immédiat | 6/10 | Belle vue d'ouverture et déplacement réactif, mais le combat frustrant a cassé l'élan |
| Compréhension | 4/10 | Aucun repère d'objectif clair, caméra imprévisible, feedback de combat absent |
| Beauté | 7/10 | Palette et composition cohérentes avec la bible visuelle, malgré un défaut de terrain visible |
| Réactivité | 6/10 | Déplacement et sprint très réactifs ; caméra à la souris peu prévisible (seuils étranges) |
| Envie de continuer | 5/10 | L'accroche initiale est forte, mais le blocage de combat en fin de session a entamé ma motivation |
