# Guidage vers le camp — la fumée coupe enfin l'horizon

## Le défaut (S3, recoupé quatre fois)

Quatre playtests indépendants (trois en boîte noire, un externe) ont cherché le
camp sans jamais le trouver : « aucune mission, direction, marqueur » ; « aucun
feu de camp, aucune fumée ». La colonne de fumée EXISTAIT pourtant depuis D.1.

## La cause, géométrique

Sommet de la colonne : 20,5 m. Œil du joueur sur la crête de départ : ~27 m.
La fumée ne coupait jamais la ligne d'horizon — elle se projetait sur les
falaises gris pâle, du gris translucide immobile sur du gris. Invisible par
construction, pas par malchance.

## La correction

- colonne portée à 28 m (sommet ~34,5 m) : elle se découpe sur le CIEL ;
- assombrie et opacifiée (0.42,0.44,0.5 à 92 %) : contraste sur ciel pastel ;
- ANIMÉE (`camp_smoke.gd`) : balancement en cisaillement, pied ancré au feu —
  §2.2 (P2) : « la lumière, le son et le mouvement attirent » ;
- flamme émissive orange + OmniLight chaude au foyer (§10.1 bible : « flamme
  orange » et « reflet chaud » rendent le camp lisible à 70-110 m) ;
- une notification unique en partie neuve, après 4 s : « De la fumée s'élève
  au loin — un campement ? » — la fumée montre OÙ, la ligne dit QUOI. Aucun
  marqueur, conformément à la doctrine curiosité de P2 §2.2.

## Preuve

`vista_apres_correction.png` — capture déterministe `VistaCamera_Hero01`
(renderer réel, llvmpipe) : la colonne bleu-gris coupe l'horizon à droite du
cadre, distincte du pylône cyan plus à droite.

Régression : assertions ajoutées au test des landmarks — sommet > 30 m, script
d'animation présent, flamme et lumière présentes. `valley_world` 9/9.

## Limite

Une capture fixe ne montre pas le balancement ; l'animation est garantie par
le test (script attaché), son rendu en mouvement reste à voir en jeu.
