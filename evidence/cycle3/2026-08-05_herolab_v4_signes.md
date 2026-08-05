# HeroShotLab v4 — les cinq signes du héros (§13.1)

**Date** : 2026-08-05 · **Arbre** : `c342228` (propre) · **Renderer** :
Forward+ / llvmpipe (RENDU LOGICIEL — régression visuelle, jamais un
score) · **Captures** : `herolab_v4_signes.png` + vignette + gris +
`herolab_v4_silhouette.png`.

## Fait

`HeroSigns` (classe RÉUTILISABLE — le lab aujourd'hui, `Player` à la
Phase H) : cinq signes graybox attachés aux os sondés du rig
(BoneAttachment3D) —

1. **Mantelet turquoise** (spine_03) couvrant les épaules, DEUX pointes
   inégales (0,38/0,24 m) ; turquoise héros #168F9B désaturé, écart RGB
   vérifié CONTRE le cyan électrique #22D9EC (§1.4) ;
2. **Épaulière unique** ivoire/bronze (clavicle_r — côté OPPOSÉ au
   Bracelet, §13.1) ;
3. **Bracelet de Résonance** (lowerarm_l) : manchon cuir, plaque
   ivoire, canal cyan à émission 0,8 (§13.5 : respiration presque
   imperceptible au repos) ;
4-5. **Arc + carquois en X incomplet** (spine_02, diagonales opposées
   28°/−20°) ; empennage ivoire.

Contrats fail-first : 0/8 rouge (dont un rappel utile —
`Color.distance_to` n'existe pas en 4.7.1, écart RGB manuel), puis 4/4
vert. Placement itéré PAR CAPTURE : la plaque trop basse et décollée
lisait « sac à dos » → remontée aux épaules, collée au dos. Suites
héros complètes 17/17.

## Ce que l'image montre

Le X du dos se lit immédiatement (l'arc déborde de la silhouette
corporelle — la promesse §13.1 tenue) ; capuche, mantelet, épaulière,
carquois distincts ; le turquoise héros ne se confond ni avec le cyan
du pylône ni avec l'éclair.

## Honnêteté sur `herolab_v4_silhouette.png`

C'est une CARTE DES MASSES SOMBRES (seuil de valeur < 90/255), pas la
silhouette aplatie de §30.3 : le mantelet turquoise (valeur moyenne) y
devient un trou. La VRAIE passe de silhouette (matériaux noircis,
3/10/25 m) existe déjà comme outil (`SilhouetteLineup`,
`SILHOUETTE_FLAT=1`) — y intégrer le héros signé est une tranche
suivante nommée. Le X et le carquois se lisent déjà dans la carte des
masses — bon présage, pas une preuve §30.3.

## Reste ouvert

Creusement du lit de rivière (l'amorce lit « bassin »), doigts du héros
(bind pose), fumée du camp, SilhouetteLineup avec le héros signé.
Score /100 : machine utilisateur.
