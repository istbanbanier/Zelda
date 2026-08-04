# Preuve — l'écran de chargement remplace le noir muet

## Le défaut

Entre le clic « Nouvelle partie » et l'affichage de la vallée : **25 à 65 s**
d'écran totalement noir, sans barre, sans texte, sans logo.

Deux playtests en boîte noire, indépendants, ont réagi de la même façon : croire
à un plantage. Le premier a écrit « chargement très long (35-40 s d'écran noir) »,
le second a enchaîné huit décisions inutiles pendant le fondu.

## La cause

`SceneFlow.go_to()` appelait `get_tree().change_scene_to_file()`, qui est
**synchrone** : elle bloque le thread principal pendant tout le chargement, donc
aucune image ne peut être dessinée. Le commentaire du fichier assumait le report
de l'écran de chargement « à la Phase I ».

## La correction

Chargement en arrière-plan par `ResourceLoader.load_threaded_request()`
(MASTER_SPEC §20.10), qui rend la main à chaque frame :

- interrogation de `load_threaded_get_status()` avec récupération de la
  progression réelle ;
- `load_threaded_get()` appelée **seulement** une fois la ressource prête —
  l'appeler plus tôt bloquerait et annulerait tout le bénéfice ;
- bascule par `change_scene_to_packed()` ;
- repli sur le chemin synchrone si la requête échoue, et chemin synchrone
  conservé en headless où il n'y a rien à dessiner ;
- l'écran de chargement est en `PROCESS_MODE_ALWAYS` : `go_to()` met l'arbre en
  pause avant de charger, et un `Control` laissé en `INHERIT` serait gelé au
  moment précis où il doit informer.

Habillage conforme à la bible visuelle : texte or pâle `#D8B36A` (§23.1), barre
cyan de Résonance `#22D9EC` sur piste sombre.

## Preuve

Instance Godot isolée (`DISPLAY=:92`), partie lancée depuis le menu.

- `captures/02_chargement_46pc.png` — « Chargement…  46 % », barre cyan à
  mi-course. **Le joueur sait que le jeu travaille.**
- `captures/04_vallee_jouable.png` — écran de chargement disparu, vallée
  jouable, HUD en place.

Test de régression :
`test_scene_flow_shows_a_loading_screen_that_survives_the_pause`, 8 assertions —
présence de l'écran, `PROCESS_MODE_ALWAYS`, invisibilité hors transition,
libellé et barre. Il échouait avant la correction (aucun nœud `LoadingUI`).

Tests ciblés relancés, tous verts : `autoload` 10/10, `menu` 10/10,
`valley_world` 9/9.

## Limite honnête

La correction supprime le **silence**, pas la lenteur. Le chargement reste de
l'ordre de 25 à 60 s en rendu logiciel llvmpipe, sans GPU. Réduire cette durée
est un travail de performance distinct, à mesurer sur du matériel représentatif.
