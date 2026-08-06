# Auto-évaluation SÉVÈRE du HeroShotLab v9 — grille bible §30.2

**Date** : 2026-08-06 · **Base** : captures v9 committées (arbre
`4f6f633`) + vidéo de stabilité (arbre `ae95f05`) · **Statut global :
`UNVERIFIED`** — boussole interne sur rendu logiciel ; le score qui
compte exige un humain et un vrai écran (ISS-002). Même dureté que
l'éval v5 (58/100), pour que le delta soit comparable.

| Domaine | /max | v5 | v9 | Pourquoi (défaut visible → action) |
|---|---:|---:|---:|---|
| Composition, trajectoire du regard | 20 | 14 | 15 | rivière-guide affirmée (entrée 13 m, S testé) et éclair qui ANCRE le regard sur la citadelle ; la falaise gauche bouche toujours sans guider (deux blocs plats), l'entrée du ruban reste en partie derrière le héros |
| Profondeur, échelle | 15 | 10 | 10 | inchangé : trois plans réels, brouillard mesuré — mais l'échelle se lit par valeurs, tout est boîtes |
| Lumière, couleur | 15 | 8 | 12 | LES RAMPS EXISTENT (half-Lambert + paliers fondus + Gooch soleil, lab ENTIER), plancher d'ombre §1.5 tenu, ombres froides/lumières miel réelles ; pas d'ombre de contact sous le héros, rim très discret non jugeable sur llvmpipe |
| Héros, silhouette | 10 | 7 | 7,5 | cuir/sangles modelés par le grade ; le mantelet reste un panneau rigide |
| Matériaux, cohérence | 10 | 5 | 7 | UN SEUL langage de matière (painterly partout + 3 émissifs justifiés testés) — mais zéro texture : albedos unis, le manque dominant demeure |
| Végétation, terrain | 10 | 5 | 6,5 | herbe premier plan = grand gagnant (pointes miel/creux profonds, phrases) + VENT prouvé (sondes 1,6-2,0) ; brins-cônes primitifs, terrain en plans |
| Camp, pylône, citadelle, orage | 10 | 7 | 8 | éclair majeur DIGNE (ramifié, cœur clair, halo, nuage→flanc) ; citadelle = boîtes grises à silhouette simple, sans terrasses fines §2.4 |
| Mouvement, stabilité, performance | 10 | 2 | 6 | la vidéo §30.1 EXISTE (18,1 s, pas fixe, manifeste), vent jugé, zéro shimmer/pop — mais le lab est un décor à UNE caméra (constat consigné) et la performance reste non mesurable ici |

**Total sévère : 72/100** (v5 : 58) — **sous le seuil de 75** du gate
intermédiaire (bible §29 V2). Aucun domaine à zéro ; aucune violation
d'originalité ou de licence.

## Verdict de bifurcation (AD-004)

72 < 75 : **pas de propagation V4 sur ce seul score.** Les trois points
manquants les moins chers, dans l'ordre de rendement :

1. **Ombre de contact du héros** (lumière 12→13 possible) : vérifier
   les ombres de la DirectionalLight sous llvmpipe dans le lab ;
2. **Citadelle en terrasses fines** (camp/pylône/citadelle 8→9) :
   silhouette < 20 grandes formes, épaulements §2.4 — chantier moyen ;
3. **Falaise gauche qui GUIDE** (composition 15→16) : remplacer les
   deux blocs plats par un escalier de strates orienté vers la vallée.

La revue contradictoire à contexte frais est lancée sur CE dossier —
si elle invalide des points, son verdict prime.
