# Auto-évaluation SÉVÈRE du HeroShotLab v5 — grille bible §30.2

**Date** : 2026-08-06 · **Base** : captures v5 committées
(`herolab_v5.png` + gris + vignette, arbre `03fb65c`) · **Statut
global : `UNVERIFIED`** — cette note est une boussole interne sur rendu
logiciel ; le score qui compte exige un humain et un vrai écran
(ISS-002, ligne établie du projet). Elle est volontairement dure :
l'auto-évaluation du Gate H s'était surestimée de 15-25 points.

| Domaine | /max | Note | Pourquoi (défaut visible → action) |
|---|---:|---:|---|
| Composition, trajectoire du regard | 20 | 14 | héros→chemin→camp→pylône→citadelle→orage : présents, ordonnés, TESTÉS (41 assertions) et lisibles en vignette 320×180. Mais la falaise gauche BOUCHE sans guider (deux blocs plats) et l'amorce de rivière reste timide |
| Profondeur, échelle | 15 | 10 | trois plans réels (90/105/316 m), brouillard au point mesuré, montagnes étagées ; mais l'échelle se lit par les valeurs seulement — tout est boîtes |
| Lumière, couleur | 15 | 8 | chaud/froid présent (miel/ombres froides/lointain bleui) ; PAS de ramps painterly (le shader n'existe pas), pas de rim, ombres portées peu lisibles |
| Héros, silhouette | 10 | 7 | 5 signes posés, X du dos, planche de 7 silhouettes toutes distinctes ; le mantelet reste un panneau rigide |
| Matériaux, cohérence | 10 | 5 | palette ancre respectée et niveau d'abstraction COHÉRENT partout — mais zéro texture, albedos plats : le plus gros manque |
| Végétation, terrain | 10 | 5 | phrases d'herbe + fleurs (bleues rares) + pente continue ; brins-cônes primitifs, terrain en plans |
| Camp, pylône, citadelle, orage | 10 | 7 | tous aux bonnes fenêtres, éclair majeur TENU, fumée, fanions ; citadelle sans terrasses fines |
| Mouvement, stabilité, performance | 10 | 2 | AUCUNE vidéo produite (manque connu), vent jamais jugé en mouvement, performance non mesurable ici |

**Total sévère : 58/100** — sous le seuil de 75 du gate intermédiaire
(bible §29 V2). **Verdict de bifurcation (handoff) : itérer le lab
AVANT toute propagation à la vallée.**

## Ce que le score dicte (ordre des lots confirmé)

Les trois domaines les plus faibles désignent exactement les chantiers :
1. **Lumière 8/15 + Matériaux 5/10** → `SH_CharacterPainterly` et ses
   déclinaisons sol/roche, D'ABORD dans le lab (décision verrouillée
   n°2 : « le rendu se gagne dans le shader + la lumière ») ;
2. **Mouvement 2/10** → la vidéo de stabilité 10-20 s (§30.1), jamais
   produite ;
3. puis re-évaluation sévère + revue contradictoire ; propagation V4
   seulement si ≥ 75 tenu avec preuves.

Aucun domaine à zéro ; aucune violation d'originalité ou de licence.
