# LOT 9 — Journal de l'agent UI (2026-08-12)

Branche : `claude/full-world-visual-finish`. Aucun lancement de Godot, aucun
commit, aucun fichier hors périmètre : ce journal est la seule trace — 
l'intégrateur centralise `ATTRIBUTIONS.md` et `ASSET_MANIFEST.csv` depuis le
tableau §b, puis parse et capture.

Statut honnête : tout ce qui suit est **Implémenté** (écrit et raccordé),
**NON VÉRIFIÉ** en exécution — l'agent UI n'a pas le droit de lancer Godot.
Les points de vérification pour l'intégrateur sont en §d.

## a. Fichiers modifiés

| Fichier | Résumé (une ligne) |
|---|---|
| `scripts/ui/hud_style.gd` | +4 constantes (IVORY_MUTED, GOLD_DARK, BACKDROP, —), `style_button` complété (normal/survol/appui/désactivé en plaques — plus aucun bouton gris Godot), `style_heading`, et la couche sons UI partagée (`UI_SOUND_PATHS`, `attach_ui_audio`, `play_ui`, `wire_button_feedback`) |
| `scripts/ui/options_panel.gd` | **correction du débordement 720p** (voir §c) : ScrollContainer + compaction ; cartouches de touche au langage « chip » du HUD ; titres or/filets ; seams `content_height()`/`fits_height()` ; sons ouverture/retour/clic |
| `scripts/ui/main_menu.gd` | livrée complète des 6 boutons, hiérarchie typographique (titre or, sous-titre estompé), survol souris = focus clavier, sons Kenney (tic/clic), erreurs dites ET entendues (`_show_error` — libellés épinglés par les tests inchangés) |
| `scripts/ui/victory_screen.gd` | titre or pâle, sons boutons, erreurs audibles ; aucune logique changée |
| `scripts/ui/gameplay_shell.gd` | lecteur `UiSounds` ; sons ouvrir/fermer sur pause, inventaire, cuisine (fermeture factorisée `_close_cooking(son)` : « confirm » si plat cuisiné, « back » si annulé) ; erreur audible sur refus de Résonance et réserve pleine ; `ControlsButton` enfin stylé ; cartes d'inventaire et lignes de stock câblées ; 3 couleurs dupliquées remplacées par les constantes HudStyle |
| `scripts/ui/resonance_overlay.gd` | **inchangé** — déjà conforme (états par forme, seams épinglés par test_resonance_hud) |
| `scenes/ui/MainMenu.tscn` | fond dégradé crépusculaire (GradientTexture2D en ressource de scène) + emblème « ❖ » en filigrane or 6 % ; titre 64 px + filet d'or + sous-titre 22 px ; « Quitter » déplacé en fin de liste (ordre visuel = ordre du cycle de focus) |
| `scenes/ui/VictoryScreen.tscn` | composition apaisée : dégradé sombre→or d'horizon, noyau « ❖ » turquoise calme (jamais le cyan de Résonance), colonne centrée, textes centrés, boutons 380 px ; **`Layout/Column/TimeLabel` épinglé par test_boss_victory : chemin conservé** |
| `scenes/ui/GameplayShell.tscn` | **inchangé** — tout l'habillage V4 passe par le script ; `%InventoryPanel/Centerer/Plate` (épinglé) intact |

## b. Assets promus (quarantaine → build)

Pack : **Interface Sounds 1.0**, Kenney (kenney.nl) — licence **CC0 1.0
Universal** vérifiée dans `asset_library/inbox/kenney_interface_sounds_1_0/License.txt`
et `PROVENANCE.md` (SHA-256 d'archive `f2193d07…c81232`). Crédit non
obligatoire ; à créditer quand même dans ATTRIBUTIONS (geste de courtoisie déjà
pratiqué par le projet). 6 fichiers sur les 4–8 autorisés.

| Source (inbox …/Audio/) | Cible (`assets/audio/ui/`) | Licence | Usage |
|---|---|---|---|
| `click_002.ogg` | `ui_click.ogg` | CC0 1.0 | appui de bouton (tous écrans, via `HudStyle.wire_button_feedback`) |
| `confirmation_001.ogg` | `ui_confirm.ogg` | CC0 1.0 | validation réussie (plat cuisiné) |
| `back_001.ogg` | `ui_back.ogg` | CC0 1.0 | retour/fermeture (pause, inventaire, cuisine annulée, options) |
| `tick_002.ogg` | `ui_hover.ogg` | CC0 1.0 | survol/focus d'un bouton (clavier ET souris — même son) |
| `error_004.ogg` | `ui_error.ogg` | CC0 1.0 | refus/échec : Résonance refusée, réserve de plats pleine, sauvegarde illisible, scène indisponible |
| `open_001.ogg` | `ui_open.ogg` | CC0 1.0 | ouverture de panneau (pause, inventaire, cuisine, options) |

SHA-256 des copies :

```
07db973f79f6ae0f2edc34561e7592e24d0577455919fb602cb8ecc0da991dcf  ui_back.ogg
adcd1f4adc35f1b41bc1b5bbefeff7aa44f2f3f0d96d3199b544140c7c1e761c  ui_click.ogg
063564703b6094d70718a3e787a55cc9141611e4ecd6b6637f8828f79b4a8c3a  ui_confirm.ogg
0b574cea597d96507e782ae9764f88482ce49f46e931e57054bf7150047f2d69  ui_error.ogg
869442f54214be902ec7437f79e400dc91c1bfd90d18a6dd2d5b7e41ffbf457b  ui_hover.ogg
a27c6bb0df7da1e6af5dd5937593c98bc58b6e513f42fe6a3254cd6a6949c648  ui_open.ogg
```

Branchement : un `AudioStreamPlayer` nommé `UiSounds` par écran
(`HudStyle.attach_ui_audio`), bus `UI` (repli `Master` si absent), volume
−9 dB, `PROCESS_MODE_ALWAYS` (la pause s'entend). Flux chargés à la demande et
mis en cache ; fichier manquant = action muette, jamais cassée (même contrat
qu'`AudioManager.play_sfx`). Les anciens placeholders `ui_move`/`ui_accept`
(WAV générés) ne sont plus appelés par le menu ; ils restent utilisés ailleurs
(`player_controller.gd`) — pas touché, hors périmètre.

## c. Défauts corrigés

1. **Options déborde à 1280×720 (défaut connu, prioritaire).**
   - Avant : contenu ≈ **775 px** de haut pour 720 de fenêtre (mesure du
     défaut consigné au brief LOT 9) — la fin de la table des commandes et la
     note manette étaient hors écran, sans aucun moyen de les atteindre.
   - Causes mesurables dans l'ancien `_build()` : marges verticales 48 px ×2,
     19 lignes de commandes séparées de 6 px, une ligne VIDE de respiration,
     aucun conteneur défilant.
   - Correction (3 leviers + 1 filet) : marges verticales 48→24 ; séparation
     de la table 6→3 ; ligne vide supprimée (la note passe en ivoire estompé) ;
     touches en cartouches 16 px à marges réduites ; et un **ScrollContainer**
     (`Margin/Scroll/Columns`) en garantie dure — quoi que pèse un futur ajout,
     rien n'est jamais inatteignable, à 720p comme en dessous.
   - Après (estimation arithmétique, police par défaut : titre 28 ≈ 40 px,
     19 cartouches ≈ 27 px, filets, note, séparations, marges 48) :
     ≈ **690 px**, soit ~30 px de marge sous 720. **Estimation, pas mesure** :
     le seam `OptionsPanel.content_height()` (marges comprises) existe pour
     que l'intégrateur relève la valeur réelle en capture 1280×720 —
     `fits_height(720.0)` doit rendre vrai.
2. **Boutons au thème gris Godot par défaut** (menu principal en entier,
   `ControlsButton` de la pause) : `HudStyle.style_button` fournit désormais
   les 4 états en plaques d'ardoise/or — normal, survol, appui, désactivé —
   plus le focus existant. États visibles au clavier ET à la souris ; le
   survol souris donne le focus (un seul état « courant »).
3. **Fond du menu principal = aplat gris** : dégradé crépusculaire + emblème
   en filigrane + filet d'or sous le titre (64 px). Aucune image externe,
   aucune capture mensongère : ressources de scène lisibles en diff.
4. **« Quitter » au milieu de la liste du menu** : l'ordre visuel des boutons
   contredisait le cycle de focus câblé (Options → Entraînement → … → Quitter).
   Scène réordonnée ; aucun test ne dépend de l'ordre des enfants.
5. **Écran de victoire étiré** : la colonne remplissait toute la largeur
   (boutons de ~1792 px à 1080p). Colonne et textes centrés, boutons 380 px,
   composition apaisée (noyau turquoise calme, horizon d'or).
6. **Écrans muets** : aucune action d'interface n'avait de retour sonore hors
   menu principal (placeholders). Voir §b — ouverture/retour/clic/tic/erreur
   sur menu, pause, inventaire, cuisine, options, victoire, refus du Bracelet.
7. **Trois couleurs dupliquées en littéral** dans `gameplay_shell.gd`
   (fond durabilité, fond/remplissage conductivité) remplacées par
   `HudStyle.GOLD_DARK` / `TURQUOISE_DARK` / `CYAN` — une seule source.
8. **Incohérence typographique des options** : case à cocher restée à la
   police 24 par défaut au milieu d'étiquettes 18 ; alignée.

## d. À vérifier en capture par l'intégrateur

1. **Options à 1280×720** (le point du lot) : ouvrir depuis le menu principal
   ET depuis la pause en jeu ; vérifier bouton « Retour » et note manette
   visibles sans défilement ; relever `content_height()` (attendu ≤ 720) et
   `fits_height(720.0) == true`. Rejouer à 1920×1080 (doit être aéré, scroll
   invisible).
2. **Menu principal** à 720p et 1080p : hiérarchie titre/sous-titre/boutons,
   états survol (souris) et focus (Tab/flèches) distincts du repos, bouton
   « Continuer » grisé lisible sans sauvegarde, emblème discret (pas de
   rivalité avec le texte).
3. **Inventaire** : les tests `test_inventory_layout` (centrage 3 résolutions)
   et `test_hud_style` doivent rester verts — l'habillage des cartes a changé
   d'ordre d'application (générique puis spécifique) mais pas de rendu attendu.
4. **Victoire** : `test_boss_victory` vert (chemin `Layout/Column/TimeLabel`
   conservé) ; capture : colonne centrée, boutons à largeur bornée.
5. **Sons** : après `--import`, vérifier qu'un survol/clic au menu joue les
   .ogg (bus UI) ; le curseur « Effets » ne doit PAS affecter l'UI (bus
   séparé) ; la pause doit s'entendre s'ouvrir (« open ») et se fermer
   (« back ») ; cuisiner un plat joue « confirm », annuler joue « back ».
6. **Refus de Résonance** : viser un mur trop loin, cliquer — barre du viseur
   + message + son d'erreur (trois canaux, jamais la couleur seule).
7. **Suite complète** : aucun test UI épinglé ne cite OptionsPanel en interne ;
   les libellés d'erreur épinglés (« Vallée indisponible — voir le journal. »)
   sont inchangés au caractère près.

## e. Blocages et limites honnêtes

- **Rien n'a été exécuté** : ni parse, ni import, ni capture — interdits à cet
  agent (une seule instance Godot, propriété de l'intégrateur). Tout statut
  ci-dessus est « Implémenté », pas « Fonctionnel ».
- Les `.ogg` copiés n'ont pas encore de `.import` : premier `--import` requis
  avant que `load()` les trouve. Le code est silencieux (pas cassé) tant que
  l'import n'a pas eu lieu.
- La hauteur « après » des options est une **estimation arithmétique** (police
  par défaut, métriques approchées). Si la mesure réelle dépasse 720, le
  ScrollContainer garantit déjà l'atteignabilité ; la compaction resterait à
  resserrer (prochaine vis : police des cartouches 16→15, marges 24→20).
- Le choix des 6 sons s'est fait sur nom et usage (pas d'écoute possible dans
  ce conteneur — aucun périphérique audio). Si `ui_hover` (tick_002) s'avère
  trop présent à l'oreille, remplacer par `tick_004` du même pack, même
  licence.
- Un seul lecteur UI par écran : deux sons dans la même frame se coupent
  (choix assumé — le son « d'issue » gagne : back/confirm/open priment sur le
  clic). Si un playtest réclame la superposition, passer à un petit pool.
