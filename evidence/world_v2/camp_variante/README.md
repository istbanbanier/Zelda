# Variante visuelle du camp libéré — A/B depuis la vraie caméra du joueur

**Ce dossier ne rend aucun verdict.** Il pose deux paires d'images et quatre
nombres devant Istvan. La décision lui appartient ; la branche
`claude/world-v2-camp-variante-visuelle` n'a pas vocation à être fusionnée en
l'état.

Commit `cb33bef6`, arbre propre (`repo_dirty: false`), rendu **logiciel**.

## Ce que la caméra est, cette fois

`capture_camp_libere.gd` masque l'interface et crée sa propre caméra, à un
FOV et depuis un point qu'aucun joueur n'occupe. C'est le bon outil pour lire
la composition d'un lieu, et le mauvais pour juger « est-ce que ça écrase le
cadre ? » — le cadre en question n'étant pas celui du jeu.

`capture_camp_vue_joueur.gd` laisse le héros arriver avec **sa** caméra et
garde le **HUD**. Le manifeste publie le FOV **lu** sur la caméra :

> **44,0° vertical** — soit ≈ 71° horizontal en 16:9.

Ni les `70` écrits dans `Player.tscn` (que `_ready()` écrase), ni les `58` de
l'ancienne preuve. Les deux images d'un même plan ne diffèrent QUE par
`--variante` : même arbre, même sauvegarde, même position, même visée.

## Les quatre nombres

`coffre_sur_cadre` = luminance médiane d'une fenêtre de 52 px autour du coffre,
divisée par la luminance médiane de l'image. Au-dessus de 1, le coffre est plus
clair que son cadre. C'est un **rapport** : une luminance absolue ne dirait
rien, deux expositions suffiraient à la faire bouger.

| Plan | avant | après | écart | fond avant → après |
|---|---:|---:|---:|---|
| `joueur_01_au_foyer` | **0,846** | **0,623** | −26 % | 0,416 → 0,419 |
| `joueur_02_entree_nord` | **0,811** | **0,604** | −26 % | 0,467 → 0,467 |

**La colonne de droite est le contrôle, et c'est elle qui rend la mesure
lisible** : la médiane de l'image ne bouge pas. La baisse vient donc du coffre,
pas d'un assombrissement général qu'on aurait pu obtenir en baissant
l'exposition et en appelant ça un progrès.

### Ce que ce nombre NE dit PAS — correction après contre-revue

L'AVANT vaut déjà **0,846**, donc **inférieur à 1** : le coffre n'était pas
plus clair que la médiane de l'image. Ce rapport ne mesure donc pas
« dominant » au sens du reproche du playtest, qui était vraisemblablement
CHROMATIQUE — un objet gris-bleu froid et métallique dans un cadre chaud. Or
le mécanisme correctif (`COFFRE_VERS_GRIS = 0,42`) désature d'abord, et la
désaturation **n'est mesurée nulle part ici**.

Ce que les deux paires établissent honnêtement : le coffre s'assombrit
(0,352 → 0,261 en absolu) pendant que son cadre ne bouge pas, donc le
changement lui est attribuable. Ce qu'elles n'établissent pas : que ce soit la
bonne réponse au reproche. **C'est l'œil d'Istvan qui tranche ça**, et c'est la
raison d'être de cette branche.

Et « toujours visible » n'a pour toute preuve que `coffre_dans_le_cadre` — une
projection à l'écran, pas un plancher de lisibilité. Un habillage beaucoup plus
poussé passerait ce contrôle en faisant disparaître le coffre.

`foyer_lumiere` passe de **false** à **true** : le foyer World V2 n'avait
aucune lumière locale, alors que la vallée V1 en pose une depuis V4.3.

## Ce qu'on voit, et ce qu'on ne peut pas juger ici

Visible dans la paire : le coffre cesse d'être l'objet le plus clair et le plus
froid du cadre, sans cesser d'être un coffre ; le sol autour du foyer prend une
lueur chaude ; des braises montent.

**Non jugeable depuis ce conteneur** : la lumière finale, la performance, et le
rendu réel des particules. Les braises apparaissent ici comme de petits carrés
émissifs — c'est ce que donne un billboard non éclairé en rendu logiciel, et ce
n'est pas une preuve de ce qu'une vraie carte affichera. Si un seul point de
cette variante doit être tranché sur un écran, c'est celui-là.

## Deux défauts d'outil payés pour produire ces images

1. **Budget en frames, pas en temps.** 300 frames n'ont pas suffi au premier
   montage ; les porter à 2400 a été pire — en rendu logiciel la boucle n'a pas
   fini en 28 minutes. Le budget compte désormais des **secondes**.
2. **Le vrai coupable : `_initialize()` court avant les autoloads.** `_semer()`
   cherchait `/root/SaveSystem`, ne le trouvait pas, et sortait **en silence** :
   le premier plan montait un monde sans sauvegarde semée — garnison debout,
   camp jamais libéré. Le journal l'a dit d'un mot, `gardes=4`, et l'attente est
   tombée de sept minutes à **2 secondes**.

   **La même faiblesse dort dans `capture_camp_libere.gd`**, masquée par
   l'ordre de ses plans : ses deux premiers n'ont pas besoin d'une garnison
   morte, et le troisième arrive quand la racine est peuplée. Réordonner ses
   plans la réveillerait. Consigné ici, **non corrigé** : cet outil appartient
   à la branche de durcissement.

## Ce qui n'a pas été touché

Aucun fichier gelé. Le feu est posé en **enfants** du `CampfireProp` — ce qui
lui vaut l'exemption nommée du contrôle de peau (l'arbitrage R2B remonte les
ancêtres) et lui fait hériter la visibilité du foyer, donc l'extinction quand
le camp est repris. `CampfireProp` lui-même, partagé avec la vallée V1, est
intact. Le coffre est habillé **par surface sur des matériaux dupliqués**, sur
cette instance seulement.

Filet rejoué sur cette branche : **39 réussis, 0 échoué** (peau des camps,
braise, contrats de lieux, camp libéré, cuisine, récompense, localisation).

> **Et ce filet-là ne suffisait pas.** La contre-revue à contexte frais a
> montré que deux fichiers de cette branche violaient
> `test_aucune_reference_croisee_interdite` — un contrôle TEXTUEL qui refuse le
> nom d'un sous-système dans un fichier hors de son arborescence, commentaires
> compris. Le filet cité ne l'incluait pas : **la preuve contournait le
> contrôle qui échouait.** Corrigé (chemins injectés par la scène, citations
> abrégées) et le contrôle est désormais dans le filet.
