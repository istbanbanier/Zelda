## Résumé du playtest

**Ce que j'ai compris, et grâce à quoi** : c'est un banc de test de liaisons clavier (« InputAudit — validation manuelle du Gate A »), pas un niveau de jeu. Il vérifie qu'AZERTY est bien actif pour qu'une touche « Q » physique déclenche `move_left` et jamais `lock_on`. Je l'ai compris dès le premier écran (avertissement rouge explicite), et confirmé en testant méthodiquement chaque touche.

**Ce que j'ai tenté qui n'a rien produit** : maintenir « q » 600 ms puis 1500 ms — aucun effet sur `move_left` ni sur les deux verdicts, restés « en attente ». Un simple clic gauche n'active pas `attack_light`. La touche « down » ne fait rien défiler, aucun bouton de changement de disposition n'est visible à l'écran.

**Où je me suis retrouvé bloqué** : impossible de faire progresser les deux verdicts centraux (`move_left` via Q, `lock_on` via Q), et `move_forward` (Z) ne s'active jamais. Il me manquerait soit un moyen de basculer la disposition système en AZERTY depuis cette scène, soit une touche « a » dans le jeu de touches disponibles (le harnais n'expose que z/q/s/d, pas les lettres QWERTY brutes) — sans ça, la position physique attendue pour « gauche » (étiquetée « A » selon l'écran) n'est jamais atteignable.

**Ce qui a bien fonctionné** : space→jump, e→interact, s→move_back, d→move_right — toutes ACTIVES instantanément, prouvant que le mécanisme d'audit lui-même fonctionne correctement.

**Constat le plus utile** : l'écran isole proprement le vrai problème — seules Z et Q (positions qui diffèrent entre QWERTY et AZERTY) sont mortes, alors que S/D/E, identiques dans les deux dispositions, marchent parfaitement. C'est une reproduction fidèle et vérifiable du blocage documenté ailleurs (validation clavier manuelle impossible sans vrai clavier physique) — pas une image cassée, mais un état honnêtement bloqué.
