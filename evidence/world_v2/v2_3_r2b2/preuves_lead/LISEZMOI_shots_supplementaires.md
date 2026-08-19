# Vues supplémentaires du lead — R2B.2 §7

Vues SUPPLEMENTAIRES du lead pour R2B.2 §7.
Elles s'AJOUTENT aux quinze cameras imposees de shots_r2b1.json et n'en remplacent aucune.
Deux orbites de huit azimuts repondent a une question ouverte : la breche du mur nord et la fourche sont-elles visibles, et sous quels angles ? Les hauteurs sont posees au-dessus du sol (ferme ~5 m, arbre ~8 m) : une camera sous le terrain rend le dessous du monde avec RC=0 et une image plausible — piege paye cinq fois en R2B.1.

## Pourquoi ce fichier est un TABLEAU NU et non un objet

`tools/godot/capture_poi_batch.gd` refuse tout ce qui n'est pas un `Array` :

```gdscript
if parsed == null or not (parsed is Array):
	printerr("[poi] BLOQUÉ : JSON invalide")
```

J'ai d'abord écrit `{"doc": …, "shots": […]}`, ce qui est plus lisible et
**inutilisable** : le lot entier est sorti en `RC=3` sans écrire une image.
L'outil a bien dit `BLOQUÉ` plutôt que de rendre un dossier vide en silence —
c'est le bon comportement, et c'est ce qui m'a évité d'analyser du vide.

La documentation vit donc ici, à côté, et le JSON reste ce que le parseur
attend.
