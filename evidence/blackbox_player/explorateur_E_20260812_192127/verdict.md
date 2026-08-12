### Ce que j'ai fait

J'ai lancé une nouvelle partie et exploré librement la Vallée de Néris pendant une cinquantaine d'actions, sans suivre d'objectif : vue d'ouverture, un plateau rocheux perché avec une monture, le pylône cyan, un camp avec feu et PNJ, un village séparé au style architectural différent (maisons à toits pointus, tourelle, grand portail à colonnes de pierre), et un recoin caché sous un pont avec une mare et une créature. J'ai testé les déplacements, le sprint, le saut, la caméra à 360°, l'interaction (E) et une attaque à l'épée.

### Ce que j'ai compris, et grâce à quoi

- **Contrôles** : Z/Q/S/D déplacent, la souris tourne la caméra librement (y compris à la verticale, jusqu'à voir sous le menton du héros), Shift sprinte et fait apparaître une jauge d'endurance turquoise contextuelle, Espace saute. Compris en testant chaque touche et en observant le résultat immédiat.
- **La touche E fait monter/descendre de cheval** (toggle) — compris après plusieurs tentatives infructueuses pour "descendre" en marchant, sautant ou esquivant, jusqu'à ce que E fonctionne.
- **Le monde contient au moins deux zones habitées visuellement très différentes** : un camp assez rustique (tentes, feu, palissades) et un village plus architecturé (maisons à toits pointus, tourelle, portail à colonnes) — découvert en tournant simplement la caméra à 180° depuis un point que je pensais déjà "vu".
- **Un texte contextuel narratif existe** ("De la fumée s'élève au loin — un campement ?"), déclenché par la proximité ou le déplacement — bon indice de guidage.

### Ce que j'ai tenté sans résultat

- Interagir avec le cheval via E dès la première approche : rien ne s'est passé avant que j'appuie une seconde fois plus tard (ou que la mécanique se déclenche après un délai/une collision).
- Cliquer (attaque) sur la créature blob à yeux orange dans la mare cachée : aucune réaction visible, la "barre" au-dessus n'a pas bougé — possible qu'elle soit hors de portée, ou que ce soit un élément décoratif fixe plutôt qu'un ennemi actif.
- Sortir du dos du cheval par le mouvement normal (marcher, reculer, sauter) : seule la touche E a fonctionné.

### Où je me suis perdu

Pas vraiment perdu au sens géographique — la citadelle reste un repère visuel constant à l'horizon — mais je suis resté bloqué un moment sur le dos du cheval sans comprendre comment en descendre, ce qui m'a semblé être un vrai piège de contrôle (softlock partiel) avant de trouver la bonne touche par tâtonnement.

### Ce qui m'a donné envie de continuer, ou d'arrêter

Envie de continuer : la découverte du village au portail de pierre a été le moment le plus fort — un vrai changement de registre visuel qui m'a donné envie de voir ce qu'il y avait encore ailleurs. Le petit recoin caché (mare + créature + coffre) sous le pont était aussi une bonne surprise, le genre de détail qui récompense la curiosité.
Envie d'arrêter : le temps de chargement initial bloqué 13 secondes à 45% m'a fait craindre un plantage, et le bug de monture m'a un instant fait penser être coincé pour de bon.

### Ce qui m'a semblé cassé, vide ou inachevé

- **Bug de monture** : le héros reste debout, en pose d'idle normale, sur le dos du cheval — aucune animation de monte, aucun contrôle spécifique en selle observé, aucun galop.
- **Faces de terrain non texturées** : à plusieurs reprises, en changeant l'angle de caméra (surtout en hauteur ou en pente), de grands plans unis (vert foncé ou gris), sans texture ni relief, apparaissent en bordure d'écran — ressemble à des faces internes de collision/mesh de terrain visibles depuis l'"intérieur", pas un rendu fini.
- **Clipping** : le feuillage d'un arbre proche s'est superposé à la tête/dos du héros en marchant à côté.
- **Silhouette du héros** : tunique verte, capuche, arc dans le dos — visuellement très proche d'un personnage connu d'une autre licence, ce qui contredit l'intention d'originalité affichée par le projet.
- **Ciel terne** au lieu du doré attendu à l'ouverture, et une petite silhouette humanoïde flottante bleu clair au-dessus de la citadelle qui ressemblait à un éclair mal formé ou un placeholder.
- **Créature dans la mare cachée** : aucune réaction à l'attaque, statut ambigu (décor ou ennemi non fonctionnel).

### Notes sur 10

- **Plaisir immédiat** : 6/10 — le mouvement est fluide et la découverte du village surprend agréablement, mais le bug de monture et le chargement bloqué cassent l'élan au début.
- **Compréhension** : 7/10 — les contrôles de base se devinent vite ; la mécanique de monture est le seul vrai point d'incompréhension.
- **Beauté** : 6/10 — de belles idées (mare cachée, portail en pierre, palette stylisée) mais des défauts de rendu visibles (faces non texturées, ciel terne, silhouette du héros peu originale) qui cassent l'illusion.
- **Réactivité** : 7/10 — déplacements et caméra répondent bien ; l'attaque et l'interaction avec la créature manquent de feedback clair.
- **Envie de continuer** : 7/10 — l'existence de plusieurs zones distinctes et de recoins cachés donne vraiment envie de voir le reste de la carte, notamment la citadelle et le donjon.
