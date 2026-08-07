# À coller dans une nouvelle session Claude Code

Tu reprends « Éclats d'Orage » après un playtest humain de 74 minutes qui a
tout changé. **Ne refais aucun audit** : tout est déjà écrit et mesuré.

Lis d'abord, dans cet ordre :
`evidence/blackbox_player/session_20260807_141313/` (le rapport du joueur),
puis `docs/GUIDE_CONTENU.md`, `docs/GUIDE_SOLUTION.md`,
`docs/GUIDE_CARTE_ET_CONTROLES.md`, puis
`docs/COMMENT_TRAVAILLER_ENSEMBLE.md` (sept règles, sept dégâts réels).

Le propriétaire est débutant total : tu décides de tout, tu rapportes en
français simple, tu ne lui demandes jamais d'arbitrer une question technique.

## Répare dans CET ordre, un par un, chacun avec son test

### 1. L'interaction — rien d'autre ne compte tant que ce n'est pas fait

Le joueur a appuyé sur `E` devant sept objets différents. Sept échecs, et
**jamais une seule invite à l'écran**. Conséquence : zéro coffre, zéro
cuisine, zéro porte, donjon jamais atteint. Tout le contenu du jeu lui est
inaccessible.

La chaîne EXISTE et se tient — c'est vérifié :
- `player_controller.gd:420` balaie le groupe `interactable` à cadence ;
- `_select_interactable()` filtre par angle **et ligne de vue** ;
- `interact_focus_changed` est émis (`:1450`) ;
- `gameplay_shell.gd:380` s'y abonne et affiche « E — verbe » (`:773`).

Donc ce n'est pas « non branché », c'est **un échec à l'exécution**. Deux
suspects, à départager EN LANÇANT LE JEU, pas en lisant :

1. **La liaison différée échoue.** `_bind_player.call_deferred()` : si
   `_find_player_in_own_scene()` rate une seule fois, plus aucune invite de
   toute la partie. Colle parfaitement avec « jamais une seule invite ».
2. **Les objets ne rejoignent pas le groupe**, ou la ligne de vue les
   rejette. Le feu de camp aurait dû répondre — il a échoué trois fois.

**L'expérience d'une minute** : lance la vallée, approche le feu de camp du
camp, et regarde si `interact_focus_changed` part. Ça tranche entre les deux.

### 2. L'arc ne tire jamais — une ligne à déplacer

`attack_light` et `shoot` sont tous deux sur le clic gauche, et la cascade
teste `attack_light` en premier : `player_input_reader.gd:98` contre `:106`.
Le clic est toujours avalé. Prouvé deux fois — par le code, et par le joueur
qui a visé, cliqué, et n'a jamais vu partir une flèche (compteur bloqué sur 8
toute la partie).

Correctif : tester `shoot` avant `attack_light` **quand la visée est tenue**.
Conséquence en chaîne : sans l'arc, les cristaux du boss (à `y = 3,90 m`,
hors de portée du corps à corps) sont indestructibles — **le boss est
actuellement invincible**.

### 3. Les têtes

Les ennemis portent un cône ou un bloc posé sur le cou, **creux à
l'intérieur**. Le capuchon du héros est **vide** et ça se voit de profil,
donc en permanence. Citation du testeur, à garder : « je ne regardais plus un
jeu, je regardais un chantier ».

### 4. Caméra et sensibilité

La caméra entre dans le corps du héros quand on recule contre un obstacle, et
passe sous le terrain près de la rivière. La sensibilité souris est au
**maximum par défaut**, et son curseur ne répond pas au premier clic puis se
réinitialise.

## Ce qu'il NE faut PAS réparer maintenant

Le Bracelet dans le donjon, le vol libre, la monture, les cristaux du boss,
la planche de la salle 4. Ce sont de vrais défauts, tous mesurés — mais
**personne ne peut les atteindre**. On répare dans l'ordre où le joueur les
rencontre, sinon on travaille pour personne.

## Règles de livraison

- `tools/validate_fast.sh` VERT avant toute publication — deux archives ont
  été livrées sans, dont une où des ennemis bouchaient la route du donjon.
- Pousse après chaque lot : le conteneur est éphémère.
- Une seule session à la fois sur ce dépôt (trois en parallèle ont coûté une
  journée et coupé le jeu en deux moitiés).
- Jamais « le jeu tourne à 60 FPS » : pas de GPU ici.
- Un fichier qui existe ne prouve pas qu'un joueur puisse s'en servir. Le vol,
  la monture et le Bracelet étaient « livrés » — dans une scène de test que
  personne n'ouvre.
