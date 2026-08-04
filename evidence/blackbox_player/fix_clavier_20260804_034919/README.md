# Preuve de correction — le clavier du joueur atteint enfin le jeu

Test de régression pour le blocage S1 relevé dans
`evidence/blackbox_player/session_20260804_031040/verdict.md` : « aucune entrée
clavier n'atteint le jeu, le personnage ne bouge jamais ».

## Cause

`project.godot` mappe les actions en **`physical_keycode`** (avec `keycode: 0`) :

| action | physical_keycode | touche US | étiquette AZERTY |
|---|---:|---|---|
| `move_forward` | 87 | W | Z |
| `move_left` | 65 | A | Q |
| `move_back` | 83 | S | S |
| `move_right` | 68 | D | D |

C'est correct : un code physique désigne une **position**, étiquetée selon le
clavier US. C'est ainsi qu'on obtient « AZERTY : Z avance, Q va à gauche » sans
casser le QWERTY.

Le harnais, lui, envoyait `xdotool keydown z` sur un serveur X en disposition
**US**, ce qui produit la position du Z américain — jamais celle du W. Aucune
action de déplacement ne pouvait donc se déclencher.

Cela explique exactement l'asymétrie observée par le joueur : `Échap` et les
clics souris sont identiques dans les deux dispositions et fonctionnaient,
tandis que `z`, `q`, `s`, `d` ne produisaient rien.

## Correction

`tools/blackbox_player/server.py`, table `KEYMAP` : l'étiquette AZERTY demandée
par le joueur est traduite vers la position physique attendue.

```
"z" -> "w"   (Z azerty occupe la position du W us)
"q" -> "a"   (Q azerty occupe la position du A us)
```

`shift`/`ctrl` passent aussi aux keysyms canoniques `Shift_L` / `Control_L`.

## Vérification 1 — livraison des touches (Xvfb jetable, `xev`)

Chaque touche du harnais produit bien la position physique attendue :

```
w -> keycode 25      a -> keycode 38      s -> keycode 39      d -> keycode 40
space -> 65   Shift_L -> 50   Control_L -> 37   e -> 26   r -> 27   Escape -> 9
```

## Vérification 2 — bout en bout, dans le jeu réel

Instance Godot isolée (`DISPLAY=:90`, `XDG_DATA_HOME` dédié), partie lancée
depuis le menu, vallée affichée après **52 s**. Mesure : différence de
luminance moyenne de la bande de **fond** (y = 100..300) avant/après l'appui.
Le fond ne peut changer que si la caméra — donc le personnage — se déplace.

| touche envoyée | résultat |
|---|---:|
| `z` — **ancien** mapping | **0.013** (bruit) |
| `w` — **nouveau** mapping | **1.782** |

Puis, avec le mapping corrigé :

| action | fond |
|---|---:|
| sprint avant (`w`+`Shift_L`) | 13.266 |
| gauche (`a`) | 50.802 |
| arrière (`s`) | 20.253 |
| droite (`d`) | 28.584 |
| saut (`space`) | 17.194 |
| cumul avant → après | **61.446** |

Le test échouait avant la correction et réussit après.

## Captures

- `captures/01_menu.png` — menu principal.
- `captures/02_vallee_au_chargement.png` — vallée juste après chargement.
- `captures/03_avant_deplacements.png` — position de départ, dans les hautes herbes.
- `captures/04_apres_deplacements.png` — après les déplacements : le héros a
  quitté la prairie, se trouve dans une clairière, et **des huttes à toit de
  chaume sont visibles** — le campement est atteignable.

## Limite honnête

Ce test prouve la **locomotion**. Il ne prouve pas le combat : aucun ennemi
n'a été engagé ici. Le second blocage S1 du verdict — enfermement dans le menu
Pause, qui ne se referme qu'au centre exact du bouton — **n'est pas corrigé**
et reste ouvert.

Le serveur MCP doit être redémarré pour charger la table corrigée : une session
joueur déjà en cours conserve l'ancien mapping.
