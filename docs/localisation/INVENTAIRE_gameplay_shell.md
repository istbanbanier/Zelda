# Inventaire des littéraux — `scripts/ui/gameplay_shell.gd`

**HISTORIQUE — GÉNÉRÉ.** État **AVANT migration**, au commit `8c6955c6`. C'est
l'inventaire de ce qu'il y avait À MIGRER ; le rejouer sur l'arbre d'aujourd'hui
rendra d'autres chiffres, puisque 65 littéraux sont devenus des clés. Pour le
reproduire à l'identique :

```bash
git show 8c6955c6:scripts/ui/gameplay_shell.gd > /tmp/avant.gd
python3 tools/classer_textes_joueur.py /tmp/avant.gd _refresh_resonance_hud sortie.md
```

Régénération générique :
```bash
python3 tools/classer_textes_joueur.py scripts/ui/gameplay_shell.gd _refresh_resonance_hud \
  docs/localisation/INVENTAIRE_gameplay_shell.md
```

## Pourquoi cet inventaire remplace le compteur précédent

`tools/inventaire_textes_joueur.py` annonce **39** littéraux joueur pour ce
fichier. Il y en a **78**. Son critère est la FORME : un caractère de sa
constante `ACC` doit être présent. Les manqués ne sont pas des cas tordus,
ce sont les plus ordinaires — « INVENTAIRE », « Commandes », « Mains nues »,
« Surcharge », « Silence » : du français sans accent.

**Allonger `ACC` ne peut pas marcher**, et c'est démontrable :
« Cuisiner », « Surcharge », « Silence » sont typographiquement IDENTIQUES
à « Plate », « Title », « Detail » — mêmes lettres ASCII, même casse. Les
premiers vont à l'écran, les seconds nomment des nœuds. L'information qui
les sépare n'est pas dans la chaîne : elle est dans ce que le code EN FAIT.

Ce document classe donc par **rôle syntaxique**, et chaque ligne porte le
**nom de la règle** qui l'a classée : un désaccord porte sur une règle
nommée, pas sur une intuition.

## Portée, et ce que cet outil ne sait PAS encore faire

Les règles ont été calibrées sur `gameplay_shell.gd`. Passé sur d'autres
fichiers, l'outil range beaucoup dans `A_ARBITRER` — mesuré le 2026-08-31 :
104 pour `training_grounds.gd`, 47 pour `options_panel.gd`. Ces deux-là
déclarent leurs libellés dans des **dictionnaires en ligne**, un idiome
qu'aucune règle ne couvre encore.

**C'est le comportement voulu, pas un défaut.** L'outil qu'il remplace
rangeait silencieusement tout ce qu'il ne reconnaissait pas du côté « pas
du texte joueur » ; celui-ci le déclare. Le compte de `A_ARBITRER` est donc
la mesure honnête de ce qui reste à couvrir, fichier par fichier.

## Les quatre classes

| Classe | Compte | Sens |
|---|---:|---|
| `J_JOUEUR` | 69 | le joueur le lit ; passe par une clé |
| `C_HORS_TRANCHE` | 9 | texte joueur sur un chemin **par frame** ; hors passe À DESSEIN |
| `A_ARBITRER` | 3 | aucune règle ne tranche — **non classé, pas absous** |
| `N_NON_JOUEUR` | 219 | identifiant, chemin, clé, message développeur |
| **total** | **300** | tous les littéraux du fichier |

## Les règles, et ce que chacune constate

| Règle | Constat syntaxique |
|---|---|
| `N-STRINGNAME` | littéral préfixé `&` : un `StringName` nomme un thème, un signal, un groupe ou une clé — jamais une phrase |
| `N-CHEMIN` | commence par `res://` ou `user://` |
| `N-DIAG` | la ligne porte `push_error`, `push_warning`, `print`, `assert` — message développeur |
| `N-THEME` | premier argument d'un `add_theme_*_override(` — nom d'item de thème |
| `N-NOM-NOEUD` | membre droit d'un `.name =` — nom de nœud |
| `N-CLE-DICT` | premier argument d'un `.get(` / `.has(` / `.erase(` — clé de dictionnaire |
| `N-API-IDENT` | premier argument d'une porte d'API qui prend un identifiant (`get_node`, `connect`, `is_action_pressed`, `load`, …) |
| `N-CLASSE` | deuxième argument d'un `find_children(` — nom de classe |
| `N-IDENT-BOUCLE` | élément d'une liste de boucle dont la variable sert ensuite à retrouver un nœud |
| `N-CASSE` | étiquette de branche d'un `match`, hors bloc `const` |
| `N-VIDE` | chaîne vide |
| `N-GABARIT` | aucune lettre : gabarit de format, glyphe ou ponctuation — rien à traduire |
| `J-TEXT` | membre droit d'un `.text =` |
| `J-NOTIFY` | argument d'un `_on_notification(` ou d'un `call("notify", …)` |
| `J-ANNONCE` | argument d'un `_announce_resonance(` |
| `J-TABLE` | valeur d'une table `const` indexée depuis une fonction qui écrit un Label |
| `J-RETOUR` | `return` d'une fonction dont le résultat atteint un Label |
| `J-ACCUM` | affecté ou concaténé à une variable locale qui finit dans un `.text` ou dans le `return` d'une fonction d'affichage |
| `A-SANS-ROLE` | aucune porte d'affichage et aucune porte d'identifiant ne s'applique |
| `A-COURT` | moins de trois caractères : ne peut porter une phrase, mais porte peut-être un fragment |

## Le chemin PAR FRAME, dérivé et non déclaré

`_refresh_resonance_hud` court à chaque frame. La clôture transitive de ses
appels est **calculée** par l'outil, pas écrite à la main — une liste écrite
à la main se périme en silence dès qu'un appel bouge :

```
_refresh_resonance_hud
_resonance_action_line
_resonance_camera
_resonance_state_line
_set_label
anchor
apply_state
approche
camera_rig
focus_active
focus_selected
get_camera
has
is_instance_valid
is_position_behind
link_pending
maxf
unproject_position
```

Tables indexées depuis ce chemin : `RESONANCE_ACTIONS`.
Tout littéral joueur atteint par cette clôture est `C_HORS_TRANCHE` : le
traduire appellerait `Textes.t()` soixante fois par seconde.

## Texte joueur — dans la tranche (69)

| Ligne | Règle | Site | Texte |
|---:|---|---|---|
| 279 | `J-TEXT` | `_apply_v4_style` | `INVENTAIRE` |
| 307 | `J-TEXT` | `_apply_v4_style` | `Conductivité` |
| 326 | `J-TEXT` | `_apply_v4_style` | `Tab / Échap — Fermer` |
| 530 | `J-TEXT` | `_build_controls_button` | `Commandes` |
| 646 | `J-TEXT` | `_rebuild_inventory_panel` | `%s%s\n%d/%d` |
| 698 | `J-TEXT` | `_refresh_detail` | `Dégâts  %.0f\nPortée  %.1f m\nDurabilité  %d / %d` |
| 751 | `J-TEXT` | `_on_arrows_changed` | `Flèches : %d` |
| 762 | `J-TEXT` | `_on_meals_changed` | `Plats : %d  (F)` |
| 777 | `J-TEXT` | `_refresh_weapon_text` | `Mains nues` |
| 781 | `J-TEXT` | `_refresh_weapon_text` | `%s  %d/%d` |
| 796 | `J-TEXT` | `_on_interact_focus_changed` | `E — %s` |
| 1004 | `J-TEXT` | `_refresh_sensitivity_label` | `%.4f rad/px` |
| 1023 | `J-TABLE` | `BUFF_LABELS` | `Attaque` |
| 1024 | `J-TABLE` | `BUFF_LABELS` | `Défense` |
| 1025 | `J-TABLE` | `BUFF_LABELS` | `Endurance` |
| 1026 | `J-TABLE` | `BUFF_LABELS` | `Résist. élec.` |
| 1049 | `J-TEXT` | `_build_cooking_panel` | `CUISINE` |
| 1067 | `J-TEXT` | `_build_cooking_panel` | `Cuisiner` |
| 1073 | `J-TEXT` | `_build_cooking_panel` | `Retirer le dernier` |
| 1080 | `J-TEXT` | `_build_cooking_panel` | `Reprendre` |
| 1153 | `J-NOTIFY` | `cooking_confirm` | `Réserve de plats pleine` |
| 1169 | `J-NOTIFY` | `cooking_confirm` | `Cuisiné : %s` |
| 1197 | `J-RETOUR` | `_effect_display_name` | `Attaque renforcée` |
| 1199 | `J-RETOUR` | `_effect_display_name` | `Défense renforcée` |
| 1201 | `J-RETOUR` | `_effect_display_name` | `Endurance renforcée` |
| 1203 | `J-RETOUR` | `_effect_display_name` | `Résistance à la foudre` |
| 1219 | `J-TEXT` | `_rebuild_cooking_panel` | `%s  ×%d` |
| 1226 | `J-TEXT` | `_rebuild_cooking_panel` | `Choisis 1 à 5 ingrédients` |
| 1235 | `J-TEXT` | `_rebuild_cooking_panel` | `Choisis (%d/5) : %s` |
| 1244 | `J-ACCUM` | `_rebuild_cooking_panel` | `%s — soigne %d PV` |
| 1249 | `J-ACCUM` | `_rebuild_cooking_panel` | `\n%s pendant %d s` |
| 1252 | `J-ACCUM` | `_rebuild_cooking_panel` | `\n(mélange instable : le soin est fortement réduit)` |
| 1282 | `J-TEXT` | `_refresh_buff_label` | `%s — %d s` |
| 1301 | `J-TABLE` | `BOSS_PHASE_LABELS` | `Le Gardien s'éveille` |
| 1302 | `J-TABLE` | `BOSS_PHASE_LABELS` | `Armure chargée` |
| 1303 | `J-TABLE` | `BOSS_PHASE_LABELS` | `Mis à la terre — le noyau est nu` |
| 1304 | `J-TABLE` | `BOSS_PHASE_LABELS` | `L'armure se fend` |
| 1305 | `J-TABLE` | `BOSS_PHASE_LABELS` | `Surcharge` |
| 1306 | `J-TABLE` | `BOSS_PHASE_LABELS` | `SURCHARGE — le métal renvoie` |
| 1307 | `J-TABLE` | `BOSS_PHASE_LABELS` | `La tempête monte` |
| 1308 | `J-TABLE` | `BOSS_PHASE_LABELS` | `Tempête` |
| 1309 | `J-TABLE` | `BOSS_PHASE_LABELS` | `Chancelant` |
| 1310 | `J-TABLE` | `BOSS_PHASE_LABELS` | `Silence` |
| 1326 | `J-TEXT` | `_build_boss_bar` | `GARDIEN DE L'ORAGE` |
| 1432 | `J-TABLE` | `RESONANCE_REFUSALS` | `Bracelet en recharge` |
| 1433 | `J-TABLE` | `RESONANCE_REFUSALS` | `Aucune cible` |
| 1434 | `J-TABLE` | `RESONANCE_REFUSALS` | `Cible invalide` |
| 1435 | `J-TABLE` | `RESONANCE_REFUSALS` | `Trop loin` |
| 1436 | `J-TABLE` | `RESONANCE_REFUSALS` | `Les deux ports sont trop écartés` |
| 1437 | `J-TABLE` | `RESONANCE_REFUSALS` | `Un obstacle coupe le trajet` |
| 1438 | `J-TABLE` | `RESONANCE_REFUSALS` | `Ce n'est pas du métal` |
| 1439 | `J-TABLE` | `RESONANCE_REFUSALS` | `Cet objet n'est pas chargé` |
| 1440 | `J-TABLE` | `RESONANCE_REFUSALS` | `Trop lourd pour la Polarité` |
| 1441 | `J-TABLE` | `RESONANCE_REFUSALS` | `Rien à mettre à la terre` |
| 1442 | `J-TABLE` | `RESONANCE_REFUSALS` | `Il faut les pieds au sol` |
| 1443 | `J-TABLE` | `RESONANCE_REFUSALS` | `Mise à la terre déjà en cours` |
| 1444 | `J-TABLE` | `RESONANCE_REFUSALS` | `Le trajet est barré` |
| 1445 | `J-TABLE` | `RESONANCE_REFUSALS` | `Pas de sol à l'arrivée` |
| 1446 | `J-TABLE` | `RESONANCE_REFUSALS` | `Endurance insuffisante` |
| 1447 | `J-TABLE` | `RESONANCE_REFUSALS` | `Cible perdue` |
| 1448 | `J-TABLE` | `RESONANCE_REFUSALS` | `Interrompu` |
| 1535 | `J-ANNONCE` | `_on_resonance_verdict` | `Lien établi` |
| 1537 | `J-ANNONCE` | `_on_resonance_verdict` | `Polarité engagée` |
| 1539 | `J-ANNONCE` | `_on_resonance_verdict` | `Arc Step` |
| 1546 | `J-ANNONCE` | `_on_resonance_pulse` | `Impulsion — aucune cible à portée` |
| 1548 | `J-ANNONCE` | `_on_resonance_pulse` | `Impulsion — %d cible%s révélée%s` |
| 1554 | `J-ANNONCE` | `_on_resonance_link_dissolved` | `Lien rompu` |
| 1558 | `J-ANNONCE` | `_on_resonance_grounded` | `Mise à la terre effectuée` |
| 1565 | `J-ANNONCE` | `_on_resonance_ground_cancelled` | `Mise à la terre annulée — %s` |

## Texte joueur — HORS tranche (par frame) (9)

| Ligne | Règle | Site | Texte |
|---:|---|---|---|
| 1422 | `J-TABLE/PAR-FRAME` | `RESONANCE_ACTIONS` | `Arc Link` |
| 1423 | `J-TABLE/PAR-FRAME` | `RESONANCE_ACTIONS` | `Polarité (Maj : repousser)` |
| 1424 | `J-TABLE/PAR-FRAME` | `RESONANCE_ACTIONS` | `Mise à la terre` |
| 1425 | `J-TABLE/PAR-FRAME` | `RESONANCE_ACTIONS` | `Arc Step` |
| 1617 | `J-RETOUR/PAR-FRAME` | `_resonance_action_line` | `Bracelet de Résonance` |
| 1622 | `J-ACCUM/PAR-FRAME` | `_resonance_action_line` | `Arc Link — relier` |
| 1623 | `J-RETOUR/PAR-FRAME` | `_resonance_action_line` | `Clic gauche : %s` |
| 1632 | `J-RETOUR/PAR-FRAME` | `_resonance_state_line` | `Port retenu — vise le second port SANS lâcher G` |
| 1636 | `J-RETOUR/PAR-FRAME` | `_resonance_state_line` | `Aucune cible dans l'axe — approche (18 m) et dégage la vue` |

## À arbitrer — aucune règle ne tranche (3)

| Ligne | Règle | Site | Texte |
|---:|---|---|---|
| 1169 | `A-SANS-ROLE` | `cooking_confirm` | `Plat` |
| 1549 | `A-COURT` | `_on_resonance_pulse` | `s` |
| 1549 | `A-COURT` | `_on_resonance_pulse` | `s` |

## Non joueur (219)

| Ligne | Règle | Site | Texte |
|---:|---|---|---|
| 22 | `N-CHEMIN` | `—` | `res://scenes/world/valley/ValleyWorld.tscn` |
| 85 | `N-VIDE` | `_ready` | `` |
| 104 | `N-API-IDENT` | `_ready` | `/root/EventBus` |
| 106 | `N-API-IDENT` | `_ready` | `gameplay_notification` |
| 111 | `N-API-IDENT` | `_ready` | `gameplay_shell` |
| 129 | `N-API-IDENT` | `_apply_v4_style` | `../..` |
| 136 | `N-NOM-NOEUD` | `_apply_v4_style` | `RubyRow` |
| 137 | `N-STRINGNAME` | `_apply_v4_style` | `separation` |
| 139 | `N-GABARIT` | `_apply_v4_style` | `❖` |
| 140 | `N-STRINGNAME` | `_apply_v4_style` | `font_color` |
| 148 | `N-STRINGNAME` | `_apply_v4_style` | `background` |
| 150 | `N-STRINGNAME` | `_apply_v4_style` | `fill` |
| 166 | `N-STRINGNAME` | `_apply_v4_style` | `background` |
| 168 | `N-STRINGNAME` | `_apply_v4_style` | `fill` |
| 173 | `N-NOM-NOEUD` | `_apply_v4_style` | `LockPlaque` |
| 174 | `N-STRINGNAME` | `_apply_v4_style` | `panel` |
| 177 | `N-STRINGNAME` | `_apply_v4_style` | `font_color` |
| 182 | `N-STRINGNAME` | `_apply_v4_style` | `background` |
| 184 | `N-STRINGNAME` | `_apply_v4_style` | `fill` |
| 198 | `N-NOM-NOEUD` | `_apply_v4_style` | `WeaponCard` |
| 199 | `N-STRINGNAME` | `_apply_v4_style` | `panel` |
| 208 | `N-STRINGNAME` | `_apply_v4_style` | `font_color` |
| 209 | `N-STRINGNAME` | `_apply_v4_style` | `font_color` |
| 211 | `N-NOM-NOEUD` | `_apply_v4_style` | `DurabilityRow` |
| 212 | `N-STRINGNAME` | `_apply_v4_style` | `separation` |
| 218 | `N-STRINGNAME` | `_apply_v4_style` | `background` |
| 220 | `N-STRINGNAME` | `_apply_v4_style` | `fill` |
| 229 | `N-NOM-NOEUD` | `_apply_v4_style` | `MealsLabel` |
| 230 | `N-STRINGNAME` | `_apply_v4_style` | `font_color` |
| 235 | `N-NOM-NOEUD` | `_apply_v4_style` | `PromptPanel` |
| 236 | `N-STRINGNAME` | `_apply_v4_style` | `panel` |
| 239 | `N-STRINGNAME` | `_apply_v4_style` | `font_color` |
| 249 | `N-IDENT-BOUCLE` | `_apply_v4_style` | `PausePanel` |
| 249 | `N-IDENT-BOUCLE` | `_apply_v4_style` | `DeathPanel` |
| 249 | `N-IDENT-BOUCLE` | `_apply_v4_style` | `InventoryPanel` |
| 250 | `N-API-IDENT` | `_apply_v4_style` | `%` |
| 251 | `N-API-IDENT` | `_apply_v4_style` | `Dim` |
| 253 | `N-API-IDENT` | `_apply_v4_style` | `Column` |
| 255 | `N-NOM-NOEUD` | `_apply_v4_style` | `Plate` |
| 256 | `N-STRINGNAME` | `_apply_v4_style` | `panel` |
| 264 | `N-NOM-NOEUD` | `_apply_v4_style` | `Centerer` |
| 273 | `N-API-IDENT` | `_apply_v4_style` | `Title` |
| 275 | `N-STRINGNAME` | `_apply_v4_style` | `font_color` |
| 279 | `N-API-IDENT` | `_apply_v4_style` | `Centerer/Plate/Column/Title` |
| 281 | `N-NOM-NOEUD` | `_apply_v4_style` | `Body` |
| 282 | `N-STRINGNAME` | `_apply_v4_style` | `separation` |
| 284 | `N-NOM-NOEUD` | `_apply_v4_style` | `Cards` |
| 286 | `N-STRINGNAME` | `_apply_v4_style` | `h_separation` |
| 287 | `N-STRINGNAME` | `_apply_v4_style` | `v_separation` |
| 290 | `N-NOM-NOEUD` | `_apply_v4_style` | `Detail` |
| 291 | `N-STRINGNAME` | `_apply_v4_style` | `panel` |
| 300 | `N-STRINGNAME` | `_apply_v4_style` | `font_color` |
| 304 | `N-STRINGNAME` | `_apply_v4_style` | `font_color` |
| 308 | `N-STRINGNAME` | `_apply_v4_style` | `font_color` |
| 316 | `N-STRINGNAME` | `_apply_v4_style` | `background` |
| 318 | `N-STRINGNAME` | `_apply_v4_style` | `fill` |
| 325 | `N-NOM-NOEUD` | `_apply_v4_style` | `Hints` |
| 328 | `N-STRINGNAME` | `_apply_v4_style` | `font_color` |
| 345 | `N-API-IDENT` | `_find_player_in_own_scene` | `*` |
| 345 | `N-CLASSE` | `_find_player_in_own_scene` | `PlayerController` |
| 365 | `N-API-IDENT` | `_bind_player` | `player` |
| 405 | `N-API-IDENT` | `_on_lock_acquired` | `health` |
| 406 | `N-API-IDENT` | `_on_lock_acquired` | `health` |
| 446 | `N-API-IDENT` | `_input` | `pause` |
| 463 | `N-API-IDENT` | `_input` | `inventory` |
| 503 | `N-STRINGNAME` | `toggle_pause` | `open` |
| 506 | `N-API-IDENT` | `toggle_pause` | `/root/GameState` |
| 508 | `N-API-IDENT` | `toggle_pause` | `set_paused` |
| 529 | `N-NOM-NOEUD` | `_build_controls_button` | `ControlsButton` |
| 546 | `N-NOM-NOEUD` | `open_controls` | `ControlsPanel` |
| 575 | `N-STRINGNAME` | `_on_resume` | `back` |
| 577 | `N-API-IDENT` | `_on_resume` | `/root/GameState` |
| 579 | `N-API-IDENT` | `_on_resume` | `set_paused` |
| 590 | `N-STRINGNAME` | `toggle_inventory` | `back` |
| 597 | `N-STRINGNAME` | `toggle_inventory` | `open` |
| 610 | `N-API-IDENT` | `_on_quit_to_menu` | `/root/SceneFlow` |
| 611 | `N-API-IDENT` | `_on_quit_to_menu` | `can_go_to` |
| 611 | `N-CHEMIN` | `_on_quit_to_menu` | `res://scenes/ui/MainMenu.tscn` |
| 612 | `N-API-IDENT` | `_on_quit_to_menu` | `go_to` |
| 612 | `N-CHEMIN` | `_on_quit_to_menu` | `res://scenes/ui/MainMenu.tscn` |
| 637 | `N-STRINGNAME` | `_rebuild_inventory_panel` | `normal` |
| 641 | `N-STRINGNAME` | `_rebuild_inventory_panel` | `pressed` |
| 645 | `N-GABARIT` | `_rebuild_inventory_panel` | `▶ ` |
| 645 | `N-VIDE` | `_rebuild_inventory_panel` | `` |
| 652 | `N-STRINGNAME` | `_rebuild_inventory_panel` | `icon_max_width` |
| 658 | `N-GABARIT` | `_rebuild_inventory_panel` | `◇` |
| 688 | `N-GABARIT` | `_refresh_detail` | `—` |
| 689 | `N-VIDE` | `_refresh_detail` | `` |
| 791 | `N-API-IDENT` | `_on_interact_focus_changed` | `prompt_verb` |
| 792 | `N-VIDE` | `_on_interact_focus_changed` | `` |
| 795 | `N-API-IDENT` | `_on_interact_focus_changed` | `prompt_verb` |
| 796 | `N-VIDE` | `_on_interact_focus_changed` | `` |
| 796 | `N-VIDE` | `_on_interact_focus_changed` | `` |
| 797 | `N-VIDE` | `_on_interact_focus_changed` | `` |
| 821 | `N-STRINGNAME` | `_on_notification` | `font_color` |
| 822 | `N-STRINGNAME` | `_on_notification` | `normal` |
| 942 | `N-API-IDENT` | `_on_retry` | `/root/GameState` |
| 944 | `N-API-IDENT` | `_on_retry` | `set_pending_spawn` |
| 944 | `N-STRINGNAME` | `_on_retry` | `retry_checkpoint` |
| 945 | `N-API-IDENT` | `_on_retry` | `/root/SceneFlow` |
| 946 | `N-API-IDENT` | `_on_retry` | `can_go_to` |
| 947 | `N-API-IDENT` | `_on_retry` | `go_to` |
| 994 | `N-API-IDENT` | `_on_sensitivity_changed` | `player` |
| 998 | `N-API-IDENT` | `_on_sensitivity_changed` | `Components/PlayerInputReader` |
| 1023 | `N-STRINGNAME` | `BUFF_LABELS` | `attack` |
| 1024 | `N-STRINGNAME` | `BUFF_LABELS` | `defense` |
| 1025 | `N-STRINGNAME` | `BUFF_LABELS` | `stamina` |
| 1026 | `N-STRINGNAME` | `BUFF_LABELS` | `elec_resist` |
| 1040 | `N-NOM-NOEUD` | `_build_cooking_panel` | `CookingPanel` |
| 1043 | `N-STRINGNAME` | `_build_cooking_panel` | `panel` |
| 1046 | `N-STRINGNAME` | `_build_cooking_panel` | `separation` |
| 1051 | `N-STRINGNAME` | `_build_cooking_panel` | `font_color` |
| 1052 | `N-STRINGNAME` | `_build_cooking_panel` | `font_size` |
| 1055 | `N-NOM-NOEUD` | `_build_cooking_panel` | `Stock` |
| 1060 | `N-STRINGNAME` | `_build_cooking_panel` | `font_color` |
| 1063 | `N-STRINGNAME` | `_build_cooking_panel` | `separation` |
| 1066 | `N-NOM-NOEUD` | `_build_cooking_panel` | `CookingConfirm` |
| 1072 | `N-NOM-NOEUD` | `_build_cooking_panel` | `CookingRemoveLast` |
| 1079 | `N-NOM-NOEUD` | `_build_cooking_panel` | `CookingCancel` |
| 1097 | `N-STRINGNAME` | `open_cooking` | `open` |
| 1105 | `N-STRINGNAME` | `close_cooking` | `back` |
| 1141 | `N-VIDE` | `cooking_preview_text` | `` |
| 1154 | `N-STRINGNAME` | `cooking_confirm` | `error` |
| 1164 | `N-CLE-DICT` | `cooking_confirm` | `valid` |
| 1169 | `N-CLE-DICT` | `cooking_confirm` | `name` |
| 1170 | `N-STRINGNAME` | `cooking_confirm` | `confirm` |
| 1176 | `N-CHEMIN` | `_cooking_definitions` | `res://resources/ingredients/%s.tres` |
| 1185 | `N-CHEMIN` | `_ingredient_display_name` | `res://resources/ingredients/%s.tres` |
| 1196 | `N-CASSE` | `_effect_display_name` | `attack` |
| 1198 | `N-CASSE` | `_effect_display_name` | `defense` |
| 1200 | `N-CASSE` | `_effect_display_name` | `stamina` |
| 1202 | `N-CASSE` | `_effect_display_name` | `elec_resist` |
| 1214 | `N-CHEMIN` | `_rebuild_cooking_panel` | `res://resources/ingredients/%s.tres` |
| 1236 | `N-GABARIT` | `_rebuild_cooking_panel` | `, ` |
| 1238 | `N-CLE-DICT` | `_rebuild_cooking_panel` | `valid` |
| 1245 | `N-CLE-DICT` | `_rebuild_cooking_panel` | `name` |
| 1245 | `N-VIDE` | `_rebuild_cooking_panel` | `` |
| 1245 | `N-CLE-DICT` | `_rebuild_cooking_panel` | `heal` |
| 1246 | `N-CLE-DICT` | `_rebuild_cooking_panel` | `effect` |
| 1246 | `N-VIDE` | `_rebuild_cooking_panel` | `` |
| 1247 | `N-CLE-DICT` | `_rebuild_cooking_panel` | `duration` |
| 1251 | `N-CLE-DICT` | `_rebuild_cooking_panel` | `unstable` |
| 1255 | `N-GABARIT` | `_rebuild_cooking_panel` | `—` |
| 1265 | `N-NOM-NOEUD` | `_build_buff_label` | `BuffLabel` |
| 1266 | `N-VIDE` | `_build_buff_label` | `` |
| 1267 | `N-STRINGNAME` | `_build_buff_label` | `font_color` |
| 1268 | `N-STRINGNAME` | `_build_buff_label` | `font_size` |
| 1279 | `N-STRINGNAME` | `_refresh_buff_label` | `` |
| 1280 | `N-VIDE` | `_refresh_buff_label` | `` |
| 1288 | `N-VIDE` | `buff_label_text` | `` |
| 1301 | `N-STRINGNAME` | `BOSS_PHASE_LABELS` | `intro` |
| 1302 | `N-STRINGNAME` | `BOSS_PHASE_LABELS` | `phase1` |
| 1303 | `N-STRINGNAME` | `BOSS_PHASE_LABELS` | `grounded_stun` |
| 1304 | `N-STRINGNAME` | `BOSS_PHASE_LABELS` | `transition12` |
| 1305 | `N-STRINGNAME` | `BOSS_PHASE_LABELS` | `phase2` |
| 1306 | `N-STRINGNAME` | `BOSS_PHASE_LABELS` | `overload` |
| 1307 | `N-STRINGNAME` | `BOSS_PHASE_LABELS` | `transition23` |
| 1308 | `N-STRINGNAME` | `BOSS_PHASE_LABELS` | `phase3` |
| 1309 | `N-STRINGNAME` | `BOSS_PHASE_LABELS` | `stagger` |
| 1310 | `N-STRINGNAME` | `BOSS_PHASE_LABELS` | `dead` |
| 1321 | `N-NOM-NOEUD` | `_build_boss_bar` | `BossPlaque` |
| 1322 | `N-STRINGNAME` | `_build_boss_bar` | `panel` |
| 1325 | `N-NOM-NOEUD` | `_build_boss_bar` | `BossName` |
| 1328 | `N-STRINGNAME` | `_build_boss_bar` | `font_color` |
| 1329 | `N-STRINGNAME` | `_build_boss_bar` | `font_size` |
| 1332 | `N-NOM-NOEUD` | `_build_boss_bar` | `BossBar` |
| 1335 | `N-STRINGNAME` | `_build_boss_bar` | `background` |
| 1337 | `N-STRINGNAME` | `_build_boss_bar` | `fill` |
| 1341 | `N-NOM-NOEUD` | `_build_boss_bar` | `BossPhase` |
| 1343 | `N-STRINGNAME` | `_build_boss_bar` | `font_color` |
| 1344 | `N-STRINGNAME` | `_build_boss_bar` | `font_size` |
| 1365 | `N-API-IDENT` | `_find_boss` | `*` |
| 1365 | `N-CLASSE` | `_find_boss` | `StormGuardian` |
| 1378 | `N-API-IDENT` | `_refresh_boss_bar` | `health` |
| 1382 | `N-API-IDENT` | `_refresh_boss_bar` | `state_name` |
| 1383 | `N-STRINGNAME` | `_refresh_boss_bar` | `intro` |
| 1399 | `N-VIDE` | `boss_phase_text` | `` |
| 1422 | `N-STRINGNAME` | `RESONANCE_ACTIONS` | `port` |
| 1423 | `N-STRINGNAME` | `RESONANCE_ACTIONS` | `polarity` |
| 1424 | `N-STRINGNAME` | `RESONANCE_ACTIONS` | `material` |
| 1425 | `N-STRINGNAME` | `RESONANCE_ACTIONS` | `arc_anchor` |
| 1432 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `cooldown` |
| 1433 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `aucune_cible` |
| 1434 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `invalide` |
| 1435 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `hors_portee` |
| 1436 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `trop_loin` |
| 1437 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `pas_de_vue` |
| 1438 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `pas_metal` |
| 1439 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `pas_charge` |
| 1440 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `trop_lourd` |
| 1441 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `pas_de_charge` |
| 1442 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `pas_au_sol` |
| 1443 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `occupe` |
| 1444 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `obstacle` |
| 1445 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `pas_de_sol` |
| 1446 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `endurance` |
| 1447 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `cible_perdue` |
| 1448 | `N-STRINGNAME` | `RESONANCE_REFUSALS` | `interrompu` |
| 1460 | `N-VIDE` | `—` | `` |
| 1467 | `N-NOM-NOEUD` | `_build_resonance_hud` | `ResonanceOverlay` |
| 1471 | `N-NOM-NOEUD` | `_build_resonance_hud` | `ResonancePlaque` |
| 1472 | `N-STRINGNAME` | `_build_resonance_hud` | `panel` |
| 1476 | `N-NOM-NOEUD` | `_build_resonance_hud` | `ResonanceAction` |
| 1478 | `N-STRINGNAME` | `_build_resonance_hud` | `font_color` |
| 1479 | `N-STRINGNAME` | `_build_resonance_hud` | `font_size` |
| 1482 | `N-NOM-NOEUD` | `_build_resonance_hud` | `ResonanceState` |
| 1484 | `N-STRINGNAME` | `_build_resonance_hud` | `font_color` |
| 1485 | `N-STRINGNAME` | `_build_resonance_hud` | `font_size` |
| 1520 | `N-STRINGNAME` | `_announce_resonance` | `error` |
| 1534 | `N-STRINGNAME` | `_on_resonance_verdict` | `linked` |
| 1536 | `N-STRINGNAME` | `_on_resonance_verdict` | `engaged` |
| 1538 | `N-STRINGNAME` | `_on_resonance_verdict` | `step` |
| 1549 | `N-VIDE` | `_on_resonance_pulse` | `` |
| 1549 | `N-VIDE` | `_on_resonance_pulse` | `` |
| 1621 | `N-STRINGNAME` | `_resonance_action_line` | `port` |
| 1634 | `N-VIDE` | `_resonance_state_line` | `` |
| 1637 | `N-VIDE` | `_resonance_state_line` | `` |
| 1647 | `N-VIDE` | `resonance_action_text` | `` |
| 1651 | `N-VIDE` | `resonance_state_text` | `` |

