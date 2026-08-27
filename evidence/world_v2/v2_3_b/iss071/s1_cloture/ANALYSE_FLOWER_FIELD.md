# Pourquoi flower_field a d'abord rougi l'A/B — et pourquoi ce n'était pas l'empaquetage

Premier passage : RMSE 0,114 contre la référence éditeur, seuil fixe 0,05 →
FAIL. Diagnostic AVANT tout geste, deux mesures indépendantes :

**1. Le bruit run-à-run du MÊME environnement.** Le dépôt archive DEUX
exécutions éditeur indépendantes des six vues (`apres/vues_editeur/` et
`mesure/`). RMSE entre elles :

    barrow_cemetery    0.0143
    flower_field       0.1093   <- deux runs ÉDITEUR divergent déjà d'autant
    forest_shrine      0.0190
    overlook_summit    0.0379
    turquoise_spring   0.0156
    watchtower_ruin    0.0158

L'export (0,114) est à 5 % au-dessus du bruit propre de la scène — pas
au-dessus d'une divergence éditeur/export.

**2. Où vit l'écart.** Par quadrants, export contre référence éditeur :

    haut-gauche  0.0081   haut-droit  0.0121   <- ciel, terrain lointain
    bas-gauche   0.1758   bas-droit   0.1453   <- le tapis de fleurs animées

Un modèle manquant aurait aussi altéré les zones statiques. Ici tout l'écart
est dans la végétation que le vent anime : deux captures prises à des phases
différentes de l'animation ne peuvent pas coïncider au pixel.

**Conclusion.** Le seuil fixe mesurait le VENT et l'imputait à l'empaquetage —
la classe de défaut exacte que la passe S1 corrige partout ailleurs (un rouge
dont la cause n'est pas ce qu'il prétend mesurer). L'oracle est calibré :
seuil par vue = max(0,05 ; 1,5 × bruit run-à-run de la scène), bruit recalculé
à chaque exécution depuis les deux runs éditeur committés — jamais un nombre
mort. Chaque verdict publie l'écart, le bruit et le seuil. Résultat final :
13 points, 0 FAIL, 0 BLOQUÉ ; flower_field à 0,125 pour un plafond de 0,164,
les cinq scènes stables entre 0,012 et 0,036 pour un plafond de 0,05.
