# Preuves du jalon F.2 — salle 1 d'initiation (§15.5)

Commit des preuves : `082a530`, arbre propre (`repo_dirty: false` dans les
deux manifestes). Captures produites par `tools/godot/capture_reference.gd`
depuis le renderer réel, en **rendu logiciel** (Xvfb + Mesa llvmpipe) :
utilisables pour la lecture et la régression visuelle, **jamais** pour une
mesure de performance (CLAUDE.md, limites de l'environnement).

| Fichier | Ce qu'il montre | Commande |
|---|---|---|
| `room1_entry.png` / `.json` | L'énigme telle que le joueur la découvre : source cyan à l'ouest, ligne de câbles allumée qui **s'arrête net** au vide entre les deux plaques, plaque est éteinte, bloc métallique dans le couloir de poussée, porte fermée, anneau du récepteur ouvert | `--scene=res://scenes/dungeon/rooms/Room1Initiation.tscn --frames=40 --label=f2_room1_entry` |
| `room1_solved.png` / `.json` | Le même cadrage une fois le bloc au contact : le courant traverse, tout le circuit est allumé jusqu'à la porte, l'anneau du récepteur est **fermé**, le panneau est monté et le couloir nord est ouvert | idem `--frames=220 --label=f2_room1_solved --call=capture_state_solved` |

`--call=capture_state_solved` ne triche pas : la méthode pose le bloc au
point de contact — exactement ce que la poussée du joueur produit — puis
laisse le chemin normal se dérouler (courant, anneau, délai de 0,9 s,
mécanisme). Le test `test_the_player_pushes_the_block_and_opens_the_door`,
lui, fait marcher le joueur sans aucun placement.

## Ce que ces images ne prouvent pas

- **Aucune mesure de performance** : llvmpipe, rendu logiciel.
- **Aucun verdict esthétique** : la salle est un graybox ; l'art est Phase H.
- **Aucune lisibilité humaine** : « compréhensible sans texte » (§15.5) exige
  un œil qui n'a pas construit la salle. Protocole :
  `docs/MANUAL_VALIDATION.md`. Tant qu'il n'a pas eu lieu, ce critère reste
  `NON VÉRIFIÉ`.
