# `scripts/` — règles locales

Ne duplique pas le `CLAUDE.md` racine ni `.claude/rules/gdscript.md`. Ce fichier
porte les pièges mesurés **dans ce répertoire**.

## Le piège qui échoue en silence : une couleur de palette n'est PAS un albédo

`VISUAL_ASSET_BIBLE` §1.4 donne des couleurs **peintes cibles** — ce que l'œil
doit voir à l'écran. Les donner telles quelles comme albédo produit autre chose,
parce que la lumière a un gain.

Mesuré le 2026-08-08 dans `HeroShotLab` : un albédo **bleu pur** `(0,0,1)`
ressort à `B = 255`. Gain ≈ **1,8**. Donc `COL_EARTH` (#8A5A36, rouge 0,541)
rendait 0,97 — le chemin devenait l'objet le plus clair de l'image et tirait le
regard hors de la citadelle, contre §1.2 (ISS-037).

Le code portait déjà la leçon **dans l'autre sens** :

```gdscript
# « la texture du kit porte déjà sa valeur sombre — une teinte foncée la
#   doublait et les rochers devenaient des trous noirs » (v20)
rock_material.set_shader_parameter("albedo_color", Color(1.85, 1.52, 1.16))
```

Règle : viser la **valeur rendue** de §1.5 (sol 35–65 %, ciel 75–95 %, ombres
18–38 %), pas la valeur d'albédo. `tools/check_value_bands.py` le vérifie sur la
capture, et `validate_release.sh` étape 5b l'exécute.

## Le gain n'est pas linéaire

Deux points mesurés : albédo 0,541 → 0,973 (gain 1,80) ; albédo 0,308 → 0,440
(gain 1,43). Tonemapping et blend de texture s'en mêlent. **Un test qui
prédirait le rendu depuis l'albédo serait faux** — il faut rendre et mesurer.

## Une dalle de terrain a des bords, et les bords tuent

`FordWest` faisait 12 m et s'arrêtait net : sondé, le sol passait de 2,00 à
−0,63 en **50 cm** — une falaise de 2,6 m au ras du passage. Un joueur qui
visait le gué en diagonale tombait à côté (ISS-032).

Toute surface jouable posée au-dessus d'un creux doit avoir un **épaulement**,
et la largeur utile n'est pas la largeur du tablier. Vérifier par sondage
(`tools/godot/probe_ford_approach.gd`), jamais à l'œil sur une capture : ce
défaut était invisible sur toutes les images.

## Nommer les pièces instanciées

Godot rebaptise les homonymes `@Node3D@366`. Sur les cinq murs d'une forge, un
seul gardait un nom lisible — **aucun test ne pouvait désigner cette géométrie**
(2026-08-07). Passer un nom explicite à chaque instanciation.

## Rappels durs (détail dans `.claude/rules/gdscript.md`)

- Tout le mouvement dans `_physics_process()` ; jamais de transform de gameplay
  écrit depuis `_process()`.
- Jamais de `scale` sur une `CollisionShape3D` — modifier la ressource de forme.
- Aucune boucle sur le monde entier par frame, aucune allocation par frame.
- Le visuel ne décide jamais de l'état : `StateVisualController` **traduit**.
