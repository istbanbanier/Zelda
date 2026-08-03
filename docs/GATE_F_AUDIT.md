# Audit du Gate F — donjon électrique

Base : MASTER_SPEC §15 (graphe, quatre salles, salle centrale, antichambre,
anti-softlock), §22 Phase F, §23.1. Critère de sortie du gate : **« quatre
salles solvables depuis sauvegarde vierge ET intermédiaire »**.

Preuves rejouées au commit de HEAD, jamais reprises d'un résumé.

## Matrice de preuve — items de la Phase F

| # | Item §22 | Preuve rejouée | Verdict |
|---|---|---|---|
| 24 | Graphe dans une sandbox automatisée, AVANT toute salle | `--filter=electric_graph` 11/11 : contact réel port-à-port, isolants, interrupteurs, CYCLE de quatre câbles qui termine, dix marquages = un recalcul, vingt ticks inactifs = zéro, idempotence des signaux, batterie, sauvegarde, validateur d'IDs | **PASS** |
| 25 | Chaque salle grayboxée et testée SÉPARÉMENT | `--filter=room1` 12/12, `--filter=room2` 12/12, `--filter=room3` 8/8, `--filter=room4` 12/12 — chacune dans sa propre scène jouable | **PASS** |
| 26 | Salle centrale et antichambre | `--filter=dungeon_hub` 10/10 : trois récepteurs indépendants, porte à trois conditions, carte murale, checkpoint, coffre garanti, cuisine, baies, fresque bois/métal, aperçu de l'arène | **PASS** |
| 27 | Tests softlock / reset / save | `--filter=antisoftlock` 8/8 : sauvegarde vierge sur les six scènes, rechargement à mi-résolution, objets essentiels irrécupérables, reset qui ne retire rien, sortie/retour, cent recalculs sans blocage, indice visuel, outil de debug | **PASS** |
| 28 | Donjon complet | `--filter=topology` 5/5 (assemblage) et `--filter=dungeon_run` 2/2 (run réel) | **PASS** |

## Matrice de preuve — exigences §15 salle par salle

| Salle | Exigences | Preuve | Verdict |
|---|---|---|---|
| §15.5 — Initiation | source/récepteur séparés par un vide court, bloc métallique mobile, deux plaques, contacts réels, propagation lumineuse, ouverture différée 0,6-1,2 s, compréhension sans texte, reset, solution imperdable | `--filter=room1` : le joueur POUSSE le bloc sur 7 m et la porte s'ouvre ; délai mesuré tick par tick ; butée testée à 40 m/s ; aucun `Label3D` dans la salle | **PASS** |
| §15.6 — Circuit vertical | ascenseur non alimenté, puits escaladable, électrodes intermittentes au rythme observable, interrupteur supérieur qui REDIRIGE, corniches, endurance juste, chute sur palier proche, aucun écrasement, sauvegarde | `--filter=room2` : montée réelle du joueur, rythme mesuré (1,10 s / 1,70 s), fenêtre calme > temps de traversée, ascenseur qui s'arrête devant un corps et qui PORTE le joueur, chute sur le palier sans dégâts | **PASS** |
| §15.7 — Relais rotatifs | quatre colonnes, ports visibles, rotations discrètes, propagation progressive, feedback du chemin partiel, aucune punition létale, solveur automatique, reset | `--filter=room3` : bras de cuivre confondus avec les ports du graphe (mesuré à 0,45 m près), solveur qui énumère les 256 configurations et n'en trouve qu'UNE, départ qui n'est pas solution, quatre erreurs sans un point de dégât | **PASS** |
| §15.8 — Batterie transportable | batterie chargeable, transport physique, sockets explicites, deux mécanismes successifs, eau conductrice, DEUX solutions, respawn hors limites, retour toujours possible, jamais verrouillée du mauvais côté | `--filter=room4` 12/12 : charge seulement dans son berceau, prise/portée/posée par le vrai chemin, planche isolante qui protège au-dessus de l'eau vive, coupure du courant, respawn côté charge, aucune porte entre la batterie et son chargeur | **PASS** |
| §15.9 — Salle centrale | trois récepteurs INDÉPENDANTS, trois anneaux, lignes continues, progression mécanique, carte murale, vraie ouverture | `--filter=dungeon_hub` : une salle résolue n'allume QUE son anneau (le test qui aurait échoué avec des branches reliées), porte à trois conditions, tableau salle→récepteur vérifié salle par salle | **PASS** |
| §15.10 — Antichambre | checkpoint, coffre garanti, cuisine, ingrédients, baies électriques, fresque, aperçu de l'arène, retour, aucune cinématique longue | idem : checkpoint écrit à l'entrée, lame conductrice + 12 flèches, `Campfire`, quatre `storm_berry`, fresque à deux voies dont seule celle du métal arrive au bout, quatre pylônes derrière la baie | **PASS** |
| §15.11 — Anti-softlock | reset, respawn, chemin retour, état sauvegardé, indice visuel, aucune ressource obligatoire destructible, test vierge, test à mi-résolution, outil debug | `--filter=antisoftlock` 8/8 + `--filter=topology` : chaque traversée dépose DEVANT le seuil de retour, toutes les salles atteignables depuis le vestibule, outil de debug qui liste IDs, types, ports, voisins et états | **PASS** |

## Critère de sortie du Gate F

| Critère | Preuve | Verdict |
|---|---|---|
| Quatre salles solvables depuis une sauvegarde VIERGE | `test_the_four_rooms_are_solvable_from_a_virgin_save` (29 assertions) : les quatre énigmes résolues d'affilée par leurs gestes réels, puis les trois circuits de la salle centrale et l'ouverture de la porte du boss | **PASS** |
| Quatre salles solvables depuis une sauvegarde INTERMÉDIAIRE | `test_the_dungeon_resumes_from_an_intermediate_save` (32 assertions) : run coupé en deux, fichier relu depuis le disque, un seul circuit debout à mi-parcours, les deux dernières salles résolues APRÈS reprise | **PASS** |
| Donjon assemblé et connecté | `--filter=topology` : 11 traversées vérifiées, aucune porte vers une scène inexistante, toutes les salles atteignables, chemin retour partout | **PASS** |

## Ce qui n'est PAS couvert

- **Accord sonore par circuit** (§15.9) : aucun périphérique audio dans ce
  conteneur (KNOWN_ISSUES ISS-004). Le mouvement mécanique et la lumière sont
  là ; le son appartient à la Phase H et au Prompt 3.
- **Essai humain** : la lisibilité des énigmes « sans texte », le confort de
  la poussée, la lecture du rythme des électrodes et l'ergonomie du transport
  n'ont jamais été jugés par un œil humain. Protocole prêt :
  `docs/MANUAL_VALIDATION.md`.
- **Art** : tout le donjon est en graybox. Les matériaux, les kits
  architecturaux et les VFX de §15.4 relèvent du Prompt 3 (V7).
- **Performance** : aucune mesure GPU possible ici (llvmpipe). Les scènes
  chargent et tournent, mais aucun budget de frame n'est prononcé.

## Comportement systémique conservé (et non corrigé)

Une batterie chargée LAISSÉE dans son berceau continue d'alimenter le circuit
de la salle 4 : couper le levier ne suffit alors pas à éteindre l'eau, il faut
d'abord REPRENDRE la batterie. Trouvé par le run complet, gardé volontairement
— c'est cohérent avec §15.1 (une batterie débite) et §15.3 (charge, socket et
décharge sont distincts), cela n'enferme personne, et c'est désormais couvert
par un test dédié qui documente la règle.

## Verdict global

Tous les critères automatisables sont `PASS`, sur des preuves rejouées.
Aucun essai humain n'a eu lieu.

> **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE**

Aucune case `PASS humain` n'est cochée.
