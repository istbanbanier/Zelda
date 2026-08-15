# Grotte — R2a-3.2 tranche 2 : extérieur fusionné

**Commit prouvé : `44e92008db6715e6e30cf32779dc43675949356c`** · `repo_dirty: false`
(manifestes `manifest.json` et `manifest_silhouettes_grotte_t2.json`).
Scène `res://scenes/world_v2/WorldV2.tscn`, Forward+, llvmpipe.
Le correctif de fougères qui suit est au commit `1fb57d3` ; les quatre
diagnostics ont été recapturés depuis cet arbre propre.

Ce document ne contient **aucun verdict artistique**. Il livre les quatre
diagnostics extérieurs demandés, les deux A/B, et les journaux de contrôle.

---

## Les deux corrections demandées

**`controle_composition` s'exécute enfin.** Il était annoncé comme
télémétrie imprimée sans être appelé nulle part — du code mort qui mentait
sur ce qu'il faisait. Il tourne maintenant une fois sur la coque et les onze
masses, avant l'union, sans aucune condition bloquante.

**`PENETRATION_MIN_M` est devenu `RECOUVREMENT_AABB_MIN_M`.** Il ne mesurait
aucune profondeur de matière : deux volumes peuvent partager 0,50 m de boîte
en se touchant par un coin, et c'est précisément ce qui a fait rendre deux
îlots à l'union. Il est présenté comme préfiltre, et la preuve de solidarité
est écrite dans le code comme la conjonction des cinq mesures exigées.

---

## Le repli, corrigé à la source

Aucun anneau de cavité ne se repliait dans son plan — les neuf stations ont
été vérifiées une à une. Le croisement était **entre stations**, colonnes 1
et 54 de la bande 7→8, causé par le vrillage de la grille de facettes, qui
s'accumule le long de l'axe (0,23 rad × 8 = 1,84 rad, soit deux facettes et
demie). Balayage complet :

| vrillage (rad/station) | croisements |
|---:|---:|
| 0,23 | 2 |
| 0,18 | 0 |
| 0,14 | **1** |
| 0,10 | 0 |
| 0,06 | 0 |
| 0,03 | 0 |
| 0,00 | 0 |

Le phénomène est **non monotone** : 0,18 ne passe que par chance. Valeur
retenue **0,10**, au milieu d'un palier de zéros.

Le défaut n'a pas migré : le contrôle d'auto-intersection tourne désormais
sur **toutes les sources avant l'union**, et il est vert.

`EpauleOuest` effleurait encore la jupe enterrée : deux faces se croisaient
dans la sortie du booléen alors que toutes les sources étaient valides. Elle
est enfoncée de 0,50 m pour que l'intersection soit transversale.

---

## Journal des contrôles, chaîne verte, RC = 0

```
onze masses degagees de la cavite : 0,47 a 1,25 m (minimum exige 0,35)
epaisseur 0,92 m en paroi, 0,74 m en collerette (minimums 0,80 / 0,60)
  mesuree AVANT union : l'ordre des sommets qui separe les deux peaux
  n'existe plus apres un booleen, et la mesure sur l'enveloppe seule est
  un minorant valide puisque l'union ne peut qu'eloigner la surface
solidarite : 15 paires en INTERSECTION REELLE de faces
sources    : aucune auto-intersection avant union
union      : une seule composante connexe
auto-intersection de l'union : aucune paire de faces croisees
fermeture  : 0 arete de bord, 0 non-manifold, volume 717,6 m3
gabarit    : capsule r=0,45 h=1,85 aux 7 stations du chemin
aucun jour : 25 rayons verticaux, croisements pairs et >= 2
sol        : -0,039 seuil · 0,185 salle · 0,386 niche · 0,510 voisin
```

Filets de lieux : **8 réussis, 0 échoué**.
`gltf_inspect` : **VALIDE** — 2 nœuds, 4 904 triangles, 15,0 × 11,0 × 15,8 m.

Télémétrie de composition des **volumes sources** (ne bloque rien ; l'union
les fond ensuite en un seul maillage) : enveloppe 79,9 %, puis Contrefort
3,0 %, EpauleOuest 2,2 %, DosAlcove 2,2 %, Couronne 1,8 %, Surplomb 1,8 %,
EpauleNordEst 1,8 %, BlocPiedOuest 1,8 %, Eperon 1,5 %, MolaireEst 1,5 %,
BlocPiedSud 1,2 %, EbouliEst 1,2 %.

---

## Les quatre diagnostics

| fichier | vue |
|---|---|
| `t2_02_approche_joueur.png` | approche joueur, caméra réelle |
| `t2_03_gros_plan_seuil.png` | gros plan du seuil |
| `t2_07_trois_masses.png` | lecture des masses depuis l'approche réelle |
| `silhouette_grotte_t2_000.png` | silhouette isolée, azimut 0° |

A/B direct R2a-3.1 → tranche 2 : `AB_approche.png`, `AB_seuil.png`.

---

## Ce que je n'ai pas résolu, et que je ne masque pas

**Les masses jaunes devant la bouche ne sont toujours pas identifiées, et
elles ne sont PAS ce que j'ai annoncé au tour précédent.** Trois mesures
concordantes :

1. la sonde de semis gelé compte 810 cellules, 0 sans plan de plantation, et
   ne trouve **aucun objet floral à moins de 24 m** de la bouche ;
2. j'ai déplacé les deux `Fern_1` du lieu, puis **masqué les trois Fern** de
   la scène : les masses jaunes restent, au pixel près ;
3. une énumération de tous les `GeometryInstance3D` visibles, triée par
   distance à l'œil de la caméra d'approche, ne les contient pas — les plus
   proches sont deux `Fern_1` à 8,4 et 10,1 m, puis des `RockPath` à 11 m.

J'avais conclu au tour précédent que c'étaient les fougères du lieu. **La
mesure me contredit, et je le dis avant qu'on me le demande.** L'exigence
« les fleurs ne masquent plus le tiers inférieur de l'entrée » n'est donc
**pas satisfaite**, et la cause reste à trouver.

Un test intermédiaire a été écarté comme invalide : masquer le lieu puis
capturer avec une caméra créée à la volée. La caméra du joueur reprend la
main pendant la construction du monde, et l'image obtenue montrait un autre
endroit. Seul `capture_poi_batch` garantit le point de vue.

Aucun de ces chiffres n'est une mesure de performance : llvmpipe rend en
logiciel.
