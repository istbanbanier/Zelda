# Preuve croisée `watchtower_gp_lointain` — cadrage calculé AVANT la capture

**Pourquoi ce document est daté d'avant l'image.** Une caméra choisie après
avoir vu ce qu'elle montre n'est pas une preuve, c'est un cadrage. Le calcul
ci-dessous est fait sur les nombres de `shots_lot1r_final.json`, committés
avant la passe de captures.

## La question

Les deux lieux corrigés par la voie A et la voie B — la tour de guet et la
source turquoise, séparés d'environ 24 m de dénivelé — **lisent-ils ensemble
dans un même cadre** ? Aucun arbre de voie ne pouvait y répondre : dans l'arbre
de la voie A, la tour était encore rejetée, et réciproquement.

## Le plan

`watchtower_gp_lointain` — caméra `(-90, 38, 90)`, visée `(-160, 30, 40)`,
FOV **vertical** 45°, image 1280 × 720 (donc demi-FOV horizontal 36,4°,
`KEEP_HEIGHT` — le piège de `Camera3D.fov` documenté par
`VISUAL_ASSET_BIBLE` §3.1).

## Le calcul

Projection de chaque sujet dans le repère de la caméra ; position d'écran
normalisée où `(0, 0)` est le centre et `±1` le bord.

| Sujet | Distance | Angle h | Angle v | Écran | Verdict |
|---|---:|---:|---:|---|---|
| Tour (cible de visée) | 86,4 m | +0,0° | −0,0° | (+0,00 ; −0,00) | dans le cadre |
| Source — vasque | 72,7 m | +11,5° | −16,0° | (+0,28 ; −0,69) | dans le cadre |
| Source — bouche | 79,0 m | +6,1° | −12,9° | (+0,14 ; −0,55) | dans le cadre |
| Source — dalles | 70,6 m | +17,0° | −17,1° | (+0,41 ; −0,74) | dans le cadre |

La tour occupe le centre ; la source se lit dans le **quart inférieur droit**,
entre 55 % et 74 % de la demi-hauteur — assez bas pour que le dénivelé se voie,
assez haut pour ne pas être coupée.

## Ce que ce calcul NE prouve PAS

Il ne prouve que l'appartenance au **tronc de vision**. Il ignore
l'**occlusion** : un ressaut de terrain entre la caméra et la vasque
masquerait la source sans rien changer aux angles. Seule l'image tranche, et
c'est elle qui fait foi. Ce document sert uniquement à établir que le plan
n'a pas été choisi après coup.
