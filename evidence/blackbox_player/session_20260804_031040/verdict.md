# Verdict — joueur action-aventure expérimenté (session_20260804_031040)

- **Mode** : MCP Claude Code (serveur stdio `tools/blackbox_player/server.py`), step-locked SIGSTOP/SIGCONT.
- **Résolution** : 1024x768, Xvfb `:77`, rendu logiciel Mesa llvmpipe.
- **Actions joueur** : ~52 (28 captures conservées dans `captures/`).
- **Résultat** : **ÉCHEC**. Le campement n'a jamais été atteint, aucun combat n'a été engagé.

## Parcours réellement accompli

| Étape | État |
|---|---|
| Boot → menu → Nouvelle partie | PASS |
| Comprendre la vue d'ouverture | PASS |
| Trouver le camp | FAIL (aperçu de loin, jamais atteint) |
| Gagner un vrai combat | FAIL (jamais engagé) |
| Reste du parcours (arme, inventaire, esquive, citadelle, donjon, boss) | UNVERIFIED |

## Défauts observés, par gravité

### S1 — Aucune entrée clavier n'atteint le jeu

Le personnage n'a jamais bougé. Ce n'est pas une collision : la différence de
luminance moyenne du **fond** (bande y=100..300) entre captures successives vaut
`0.000` — identique au pixel près — pendant que le premier plan varie (~24)
sous l'effet du shader de vent.

Vérifié sur `z`, `q`, `d`, `z+q`, `z+Maj` (sprint), flèches, `Échap`, `Entrée`,
`Espace`. Vérifié également **hors du serveur MCP**, par injection directe
`xdotool keydown z` pendant 2 s avec le processus explicitement repris
(SIGCONT) : fond inchangé (`0.000`). Testé par deux voies X distinctes, XTEST
et XSendEvent (`xdotool key --window`), après `windowfocus` + `windowraise`
explicites : aucun effet.

État X au moment des tests : fenêtre `0x200003` « Eclats d'Orage (DEBUG) »,
`Map State: IsViewable`, `xdotool getwindowfocus` = cette fenêtre, pointeur
centré, aucune touche restée enfoncée (purge effectuée). Aucun gestionnaire de
fenêtres présent (`_NET_SUPPORTING_WM_CHECK` absent).

**Asymétrie décisive** : les **clics souris fonctionnent** dans le même état —
le clic sur « Nouvelle partie » a lancé la partie, et un clic a levé la pause.
Seul le clavier est ignoré. Piste à instruire côté intégrateur : Godot X11
filtrant les événements clavier tant qu'il ne s'estime pas focalisé, en
l'absence de WM pour émettre un `FocusIn`.

### S1 — Enfermement dans le menu Pause

Un panneau « Pause » (Reprendre / Sensibilité souris / Menu principal) s'est
affiché sans action volontaire de ma part, avec « Reprendre » encadré en doré.
Il n'a été refermé ni par `Échap`, ni par `Entrée`, ni par `Espace`, ni par un
clic sur le curseur de sensibilité, ni par un clic à (511,320) sur le bouton.
**Seul un clic à (512,319)** — centre exact — l'a levé.

Pendant la pause, le jeu continue à dessiner (herbe animée, éclair cyan) : rien
ne signale au joueur qu'il est en pause et non bloqué par le décor.

### S2 — Chargement muet et très variable

`Nouvelle partie` → **~64 s d'écran noir total** (mesuré : 8 waits de 8000 ms de
temps de jeu repris), sans barre de progression, sans texte, sans logo. Une
instance antérieure du même build avait chargé en ~23 s. Rien ne distingue un
chargement d'un plantage. Mémoire du processus observée en montée continue
(1,82 → 1,99 Go pendant le chargement), CPU actif, état `D` (I/O).

### S2 — Caméra souris inutilisable (corrigé pendant la session)

Tout `game_act` contenant `mouse_delta` expirait après 60 s. Cause :
`xdotool mousemove --sync` attend la stabilisation du pointeur à la position
visée, que Godot ne laisse jamais atteindre en `MOUSE_MODE_CAPTURED`.
Les 60 s venaient du cumul de trois timeouts de 20 s (souris, relâche des
touches, capture).

**Corrigé** dans le commit `19e7bed` : suppression de `--sync`, bornes à 5 s,
relâche des touches isolée. Le correctif n'a pas pu être exercé dans cette
session (il exige un redémarrage du serveur MCP).

## Ce qui fonctionne

- Menu principal lisible, clic fiable, transition vers la partie.
- Composition de la vue d'ouverture : trois plans nets, héros lisible de dos,
  citadelle centrale, pylône cyan à droite, bosquets rouges, brume d'étagement.
- Éclair cyan récurrent sur la spire, nuage d'orage circonscrit.
- HUD lisible : 6 cœurs, « Épée usée 24/24 », « Flèches : 8 ».

## Limite honnête de ce verdict

Tout ce qui suit la locomotion — combat, endurance, durabilité, arc, esquive,
inventaire, cuisine, donjon, boss — reste **UNVERIFIED**. Aucune note de game
feel n'est produite : on ne juge pas un combat qu'on n'a pas pu déclencher.

## Hypothèse sur la session précédente

`decouverte_A_20260804_021956` rapporte une « limite invisible » infranchissable
avant le camp. Au vu du présent constat, l'explication la plus probable n'est
pas une frontière de monde mais la même absence de locomotion.
