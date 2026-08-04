# Vérification du correctif clavier À TRAVERS le harnais MCP

Le correctif de `KEYMAP` avait déjà été prouvé sur une instance Godot lancée à
la main (`evidence/blackbox_player/fix_clavier_20260804_034919/`). Cette
session-ci vérifie la même chose par le chemin que le joueur emprunte
réellement : les outils MCP `game_click`, `game_wait`, `game_act`.

Déroulé : menu → `game_click` sur « Nouvelle partie » → vallée affichée après
**~32 s** de noir → un seul `game_act` avec `keys_down = ["z", "shift"]`
pendant 2000 ms.

Résultat visible dans `captures/` : le décor défile nettement — la citadelle se
décale, les bosquets rouges grossissent — et une **jauge d'endurance turquoise**
apparaît sous le héros pendant le sprint.

Deux points méritent d'être notés :

- c'est la première fois qu'un playtest de ce projet parvient à faire avancer
  le personnage ; les deux sessions précédentes s'étaient arrêtées sur un héros
  parfaitement immobile ;
- la jauge d'endurance n'avait donc jamais été observée en jeu jusqu'ici.

Cette session ne prouve **que** la locomotion. Aucun ennemi n'a été approché,
aucun combat engagé.
