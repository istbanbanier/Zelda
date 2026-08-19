# Addendum — recalibrage de la mesure « eau garantie » APRÈS l'archive rouge

Le rouge archivé (`r2b_basin_rouge.log`) jugeait l'intrusion des maillages
dans l'eau par `Transform3D * AABB` — la boîte ENGLOBANTE de la boîte
tournée. Vérifié à la main pendant l'implémentation : pour une dalle de
couronnement en biais (~51° de lacet), cette boîte gagne des coins
fantômes ~0,2 m plus proches du centre que la dalle physique ; les deux
écarts `Margelle_19/20` du rouge relevaient au moins en partie de cette
inflation, pas d'une trempe réelle.

La mesure est donc passée à l'échantillonnage du treillis 3×3×3 de la
boîte RÉELLE transformée point par point (voir l'en-tête de
`_mesh_enters_swim_water` dans le test). Les seuils n'ont PAS bougé :
même ellipse d'eau garantie (houle minimale 0,65), même bande de hauteur.
C'est la grandeur mesurée qui a été corrigée — même famille que la règle
de `tests/CLAUDE.md` : quand un contrôle rougit, demander d'abord ce
qu'il mesure vraiment, jamais quel seuil le ferait passer.
