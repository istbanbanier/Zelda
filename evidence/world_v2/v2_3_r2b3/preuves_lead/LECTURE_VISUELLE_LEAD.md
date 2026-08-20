# Ce que j'ai vu moi-même, à taille réelle, sur les onze montages A/B

Rendu logiciel llvmpipe. Régression visuelle seulement, jamais une mesure.

## En gros plan — le défaut nommé a disparu

`ab_debris_a_proche`. **Avant** : un éventail de plaques de tuile plates et de
madriers gris droits, posés à angles. La lecture « carton découpé » que le
verdict R2B.2 décrivait est indiscutable une fois qu'on regarde de près.
**Après** : un amas compact de fragments facettés, avec du volume, une silhouette
cassée, un reste de tuile et une poutre dessous.

À cette distance, la corrective fait ce qu'on lui demandait.

## À distance d'orbite — la différence est à peine perceptible

`ab_ferme_orb090`, `ab_ferme_orb000`, `ab_ferme_orb180`, `ab_ferme_orb270`. Les
deux panneaux se ressemblent. Les deux tas ne sont qu'une petite part de
l'anneau bas de maçonnerie qui ceinture la ruine, et c'est **l'anneau** qui
domine le cadre.

Or cet anneau — `SM_Farm_Rubble_Wall`, `SM_Farm_WallStub_East`, et le socle
loftté — **n'est pas dans le périmètre de la corrective**. Si la « bordure
construite » du verdict venait en partie de lui, elle est toujours là.

C'est une question que je porte à la revue, pas une conclusion : seul l'œil
qui a rendu le verdict initial peut dire ce qu'il regardait.

## Deux changements que personne n'a demandés

1. **La matière.** `MAT_Farm_Stone` passe de 0 à 94 triangles (47 %), les tuiles
   de 58 à 36 %, le bois de 39 à 12 %. Le tas lisait « bois et tuile », il lit
   maintenant « moellons ». Plus crédible comme effondrement de maçonnerie —
   mais cela le rapproche visuellement de l'anneau voisin, au risque de l'y fondre.
2. **L'emprise** de `Debris_A` gagne ~5 % en X comme en Z. Dans la tolérance,
   pas nulle.

## Ce que je ne peux pas dire

Si le résultat est BEAU. Le liant est passé de 96,8 % à 0,00 %, la valeur des
tas de gravats acceptés du kit — mais un chiffre de forme ne juge pas une image,
et l'agent qui a fait le travail n'a jamais vu son propre résultat, faute de GPU.
**ISS-060 ne se ferme que par l'œil de Codex/Istvan.**
