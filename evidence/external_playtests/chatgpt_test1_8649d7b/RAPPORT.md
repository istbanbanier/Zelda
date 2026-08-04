# Test indépendant du jeu — build `8649d7b`

Date : 4 août 2026  
Branche : `claude/phase-0-gate-0-setup-t72ibt`  
Commit testé : `8649d7b5804e8ae2fb2040c8392bf7038ea95016`  
Moteur : Godot `4.7.1-stable` officiel  

## Verdict

Le projet démarre et plusieurs systèmes sont réellement jouables, mais cette
version n'est pas encore prête pour être remise comme build de playtest à un
joueur extérieur. Deux blocages dominent : l'escalade automatique/caméra et le
début du combat de boss.

## Conditions du test

- lancement du vrai projet, sans modifier le dépôt ;
- entrées clavier et souris envoyées au jeu comme celles d'un joueur ;
- scènes testées : menu, vallée, laboratoire de combat, salle 1 du donjon et
  arène du boss ;
- rendu logiciel `llvmpipe` et audio factice : aucune conclusion de performance,
  de qualité GPU ou de son ne peut être tirée ;
- aucun `SCRIPT ERROR` observé. Les seuls messages moteur concernent Vulkan,
  V-Sync et ALSA indisponibles dans l'environnement de test.

## Fonctionne réellement

- menu principal et chargement de la vallée ;
- caméra à la souris et réglage de sensibilité ;
- déplacement, saut et sprint ;
- pause, inventaire 2 x 4 et données de l'arme ;
- attaques légères, combo de trois coups et attaque lourde ;
- dégâts corrects dans le laboratoire : `12`, `12,6`, `15,6` pour le combo et
  `21,6` pour l'attaque lourde ;
- salle 1 du donjon : le bloc se pousse, le circuit s'allume, le récepteur
  s'active et la porte s'ouvre.

## Défauts critiques ou majeurs observés

### 1. Escalade automatique et caméra — majeur, reproduit plusieurs fois

Courir normalement contre un arbre, une maison ou un mur du donjon déclenche
l'escalade sans intention explicite. Le personnage peut rester suspendu ; la
caméra traverse alors tronc, toit ou mur et peut masquer presque tout l'écran.
Le dégagement latéral finit parfois par libérer le joueur, mais l'exploration
et le franchissement d'une porte deviennent imprévisibles.

Reproduit dans la vallée et après résolution de la salle 1 du donjon.

### 2. Début du boss — critique pour la progression

En lancement autonome de `BossArena` (donc sans jouer toute la chaîne depuis
l'antichambre), à environ cinq secondes du lancement de l'arène, le Gardien traverse la distance
jusqu'au joueur et retire toute sa vie en quelques secondes. Sans action, le
joueur plein de vie est mort vers la sixième seconde. Une esquive au réveil
évite le premier contact, mais la caméra entre immédiatement dans les modèles
et le joueur meurt environ deux secondes plus tard.

Le bouton `Réessayer (dernier checkpoint)` fonctionne, mais rejoue le même
enchaînement. La sévérité doit être confirmée en entrant par le parcours normal,
avec l'équipement réellement sauvegardé dans l'antichambre.

### 3. Pillard du laboratoire — majeur à confirmer dans la vallée

Le pillard reçoit les dégâts, mais peut rester superposé au joueur sans porter
de coup. Les deux corps se chevauchent visiblement. Comme cette observation a
été faite dans `CombatLab`, elle doit être reproduite dans le camp réel avant
d'affirmer que toute l'IA de la vallée est cassée.

### 4. Continuer et orientation — défauts de parcours

- `Continuer` recharge le jeu, mais replace le joueur sur la crête au lieu de
  restaurer la position atteinte ;
- aucune mission, direction, marqueur ou indication de but n'était visible ;
- le camp et ses ennemis n'ont pas été trouvés naturellement pendant cette
  passe malgré une traversée prolongée : cela constitue déjà un problème de
  guidage pour un nouveau joueur.

### 5. Monde et lisibilité visuelle — finition importante

La vallée mélange des bâtiments et de la végétation plus détaillés avec de
grands murs/volumes verts ou gris. Plusieurs éléments du village semblent
intersectés, suspendus ou très proches des parois. Les intérieurs sont ouverts,
mais vides et difficiles à parcourir à cause de la caméra.

## Priorité de correction recommandée

1. Rendre l'escalade volontaire ou fortement filtrée ; ajouter une annulation
   immédiate et une vraie collision de caméra.
2. Rejouer les dix premières secondes du boss, corriger sa fermeture de
   distance, ses dégâts cumulés et le cadrage au contact.
3. Reproduire en vallée la superposition joueur/ennemi et l'absence d'attaque,
   puis corriger collisions et IA si confirmé.
4. Sauvegarder/restaurer la position et l'état de progression utiles.
5. Ajouter un objectif de départ et un guidage visuel vers le premier camp.
6. Refaire ensuite une passe humaine complète vallée -> donjon -> boss avant
   l'archive publique.

## Non validé dans cette passe

- chaîne complète des quatre salles du donjon ;
- coffre et ramassage dans le camp réel ;
- combat complet et victoire contre le boss ;
- audio ;
- performance sur GPU réel ;
- manette.
