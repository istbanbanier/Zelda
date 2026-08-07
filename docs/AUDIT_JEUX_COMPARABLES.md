# AUDIT COMPARATIF — jeux développés avec Claude, et ce qu'ils nous apprennent

**Date** : 2026-08-06 · **Demande** : « auditer d'autres jeux similaires
développés avec Claude sur Godot, pour voir comment améliorer le
gameplay » · **Statut des constats sur NOTRE code** : `Vérifié` (grep
sur le dépôt) · **Statut des constats sur les autres projets** :
`Lu dans leur documentation publique`, pas joué.

## Méthode et son honnêteté

Recherche GitHub sur les dépôts portant un `CLAUDE.md` et du code Godot
3D (1 046 dépôts avec Godot + CLAUDE.md ; 60 avec `CharacterBody3D` +
Claude Code ; 26 se réclamant d'un « zelda-like »). Trois projets
retenus pour leur pertinence décroissante, plus une recherche web sur
les retours d'expérience publiés.

**Limite déclarée** : je n'ai joué à AUCUN de ces jeux. J'ai lu leur
documentation et leur code. Les leçons ci-dessous valent comme
hypothèses argumentées, pas comme verdicts. Ce qui est `Vérifié`, c'est
uniquement l'état de NOTRE dépôt.

## Les trois projets retenus

### 1. `levy-street/world-of-claudecraft` — le plus ambitieux (mais pas Godot)

MMO navigateur en Three.js/TypeScript, jouable en ligne. Trois choses à
retenir, dont une qui nous concerne directement :

- **Le cœur de simulation est SÉPARÉ du rendu** (`src/sim/` sans aucune
  dépendance au navigateur ni à Three.js). Conséquence : le même code de
  jeu tourne en solo, sur serveur, ET dans un environnement
  d'entraînement d'agents. Un « portail » d'intégrité vérifie qu'aucun
  import interdit ne franchit la frontière.
- **Tick fixe 20 Hz, aléatoire à graine, zéro horloge murale.**
- **Largeur de contenu assumée** : 9 classes, 90+ quêtes, 5 donjons,
  PvP, artisanat, marché. Ils ont choisi la MULTIPLICATION de systèmes
  qui s'entrecroisent.

### 2. `lucasbrandao4770/claude-code-gamedev` — le plus proche du genre

Atelier avec un prototype zelda-like Godot (« forge-of-worlds »). Sa
valeur est dans les **pièges nommés explicitement** :

| Piège documenté | Notre état |
|---|---|
| « Ne pas se fier au seul signal `area_entered` — balayer les recouvrements, sinon une attaque rapide passe à travers » | **Déjà évité** — `hitbox_component.gd` fait un balayage physique (`get_overlapping_areas()`), et son en-tête explique pourquoi |
| Séparer la durée d'ÉTOURDISSEMENT de la durée d'INVULNÉRABILITÉ (le joueur reprend la main avant la fin des i-frames) | **Déjà fait** — `mercy_invulnerability` séparée de l'état `Hurt` |
| Séparer hitbox et hurtbox plutôt que des collisions de corps | **Déjà fait** |
| Discipline MVP : la boucle avant l'habillage | Respectée (Gates A→G avant la passe art) |

**Conclusion inconfortable pour eux, flatteuse pour nous** : sur la
technique de combat, nous sommes DEVANT ces projets. Notre problème
n'est pas là.

### 3. `dburks-svg/scars-of-ash` — le plus instructif pour NOUS

Créature-collector « Pokémon rencontre Dark Souls ». Deux idées de
conception valent le détour :

**(a) Le constat de playtest qui nous vise directement.** Cité
textuellement dans leur doc : *« Les premiers playtests ont révélé que
les joueurs pouvaient éviter tous les combats non-boss, donc la boucle
[de progression] ne s'enclenchait jamais. »* Leur correction : des
gardiens obligatoires sur les passages étroits et des élites en
patrouille — pas plus de combats, mais des combats **inévitables**.

**(b) L'échec produit quelque chose.** Une créature qui tombe gagne une
**cicatrice permanente** dépendant de la façon dont elle est morte
(empoisonnée, brûlée, distancée) : un handicap ET un avantage. « L'échec
est intéressant », et une équipe abîmée raconte une histoire.

## Ce que ça dit de NOTRE gameplay — trois trous, vérifiés dans le code

### TROU 1 — Rien n'oblige à jouer nos systèmes (le plus grave)

`grep` sur le dépôt : **aucun `must_defeat`, aucun `enemies_cleared`,
aucune porte conditionnée à un combat**. La porte de la citadelle
(`citadel_door`) ne vérifie rien. Nos ennemis ont bien un territoire et
une poursuite bornée (`valley_territories.gd`, `enemy_base.gd`) — ce qui
est correct pour la liberté, mais signifie qu'**un joueur peut courir du
spawn au donjon sans frapper une seule fois**.

Or nous avons construit : six identités d'armes, garde/déviation/posture,
IA à utility explicable, coordinateur de combat à jetons, cuisine et
buffs, cinq familles ennemies. **Si rien n'y oblige, tout cela est
optionnel — et l'optionnel ne se découvre pas.** C'est exactement le
diagnostic de Scars of Ash, sur un jeu dix fois plus systémique.

### TROU 2 — L'échec ne laisse aucune trace

Mourir renvoie au checkpoint. Rien ne change : pas de marque, pas de
coût, pas d'histoire. Notre durabilité d'armes est le seul système qui
crée une conséquence durable, et elle ne parle pas de l'échec.

### TROU 3 — Le Bracelet n'est peut-être pas nécessaire

Nos cinq opérations (Pulse, Arc Link, Polarité, Arc Step, Ground) sont
chacune enseignées et testées. Mais rien ne prouve qu'on ne peut pas
finir le jeu en n'en utilisant qu'une. Une capacité facultative est une
capacité que le joueur oublie.

## Trois propositions, par rapport gain/risque

| # | Proposition | Pourquoi | Risque |
|---|---|---|---|
| **A** | **Un gardien inévitable par route** — pas un mur, un adversaire posé sur le seul passage étroit de chacune des trois routes. Contournable en infiltration (nous avons le bruit et la perception), mais impossible à ignorer. | Fait enfin tourner le combat, la préparation et la cuisine ; reprend la correction exacte de Scars of Ash | Faible : les trois approches du camp existent déjà, c'est le même patron |
| **B** | **La mort marque l'arme** — l'arme équipée à la mort perd un cran de durabilité et gagne une ébréchure VISIBLE. L'échec devient lisible sur l'objet. | « L'échec est intéressant » sans punir la progression ; branché sur un système qui existe déjà | Faible : la durabilité et ses quatre états visuels existent |
| **C** | **La porte du boss exige une PREUVE de maîtrise**, pas trois circuits : au moins une mise à la terre réussie ET une déviation parfaite dans la partie. | Rend le Bracelet et la défense nécessaires plutôt que décoratifs | Moyen : touche au verrouillage de progression — à faire derrière un test anti-blocage strict |

## Ce que je ne recommande PAS, et pourquoi

- **Copier la largeur de World of ClaudeCraft** (classes, artisanat,
  PvP) : notre cahier des charges vise une verticale de 25-40 min. Plus
  de systèmes sur une base qu'on n'oblige personne à jouer aggraverait
  le trou n°1.
- **Séparer le cœur de simulation du rendu** comme eux : élégant, mais
  ce serait une réécriture d'architecture pour un bénéfice (agents
  d'entraînement, multijoueur) hors de notre périmètre.

## Prochaine action honnête

Ces trois trous sont des **hypothèses tirées du code**, pas des
observations de jeu. Le projet possède un agent `blackbox-player` qui
joue à l'image seule, sans accès au code. **La façon rigoureuse de
trancher est de le lancer** : s'il atteint le donjon sans combattre, le
trou n°1 est prouvé et la proposition A devient prioritaire.

## Sources

- <https://github.com/levy-street/world-of-claudecraft>
- <https://github.com/lucasbrandao4770/claude-code-gamedev>
- <https://github.com/dburks-svg/scars-of-ash>
- <https://www.mrphilgames.com/blog/claude-md-for-game-devs>
- <https://www.summerengine.com/blog/claude-for-godot>
