# Preuve de correction — la caméra du joueur tourne enfin

Le joueur `blackbox-player` lancé sur la version à clavier corrigé a rapporté :
« la caméra ne tourne **pas** avec `mouse_delta` seul (testé à plusieurs
reprises, deltas de 100 à 400 px, sans aucun effet visible) ». Il a exploré la
vallée sans jamais trouver le camp, et n'a donc gagné aucun combat.

## Cause

`GameplayShell` documente que le serveur d'affichage refuse
`MOUSE_MODE_CAPTURED` et laisse le mode à `VISIBLE`. Sans capture, Godot ne
recentre pas le curseur.

Or `_mouse()` visait une position **absolue**, `centre + delta`, et
`game_act` découpe le mouvement en fragments de ~60 ms. Le curseur atteignait
donc `centre + delta` au premier fragment, puis **n'y bougeait plus** :
`InputEventMouseMotion.relative` valait zéro pour tous les suivants.

Le joueur ne recevait qu'un fragment sur dix, soit **un dixième** de la
rotation demandée. Pour un `mouse_delta` de 60 à 150 px, cela représente moins
d'un degré : rigoureusement invisible à l'écran. D'où sa conclusion, logique
mais fausse, que la caméra ne répondait pas.

## Correction

`tools/blackbox_player/server.py` : `_mouse()` utilise désormais
`xdotool mousemove_relative`, correct dans les deux modes. Si la capture est
active, Godot recentre et chaque fragment vaut son delta ; sinon le pointeur
avance réellement et les fragments s'additionnent.

## Vérification

Instance Godot isolée (`DISPLAY=:91`), partie lancée depuis le menu. Rotation
demandée : 20 fragments de 22 px, soit 440 px vers la droite.

Le pointeur a bien parcouru 512 → 952 px, et l'image montre un lacet d'environ
25-30° vers la droite :

| repère | avant | après |
|---|---:|---:|
| citadelle (centre) | x ≈ 512 | x ≈ 250 |
| pylône cyan | x ≈ 870 | x ≈ 600 |
| chemin sableux | hors champ | apparaît à droite |

Captures : `captures/01_avant_rotation.png`, `captures/02_apres_rotation.png`.

## Limite assumée

En mode VISIBLE le pointeur finit par buter sur un bord de l'écran : une action
isolée est bornée à environ 45° depuis le centre, à la sensibilité par défaut
de 0,0015 rad/px. Le joueur enchaîne plusieurs actions pour tourner davantage.
Recentrer d'office injecterait une rotation parasite en sens inverse, ce qui
serait pire que la limite.
