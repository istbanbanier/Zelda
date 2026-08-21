# Contrôles négatifs du lot 1 — V2.3-B

Ce dossier ne contient pas des preuves que le lot va bien. Il contient des
preuves que **les instruments savent rougir**. La distinction est tout : un
filet vert peut l'être parce que le lot est bon, ou parce qu'il ne regarde
rien. ISS-018 est le rappel — les créatures s'affichaient en pièces détachées
avec TOUS les tests verts.

## Ce qui est ici

| fichier | ce qu'il prouve |
|---|---|
| `D3_controle_negatif_synthetique_*.log` | le détecteur de répétition D3 signale une COPIE EXACTE, sur des images, à trois distances |
| `verdict_repetition_SYNTHETIQUE.json` | le verdict correspondant, **synthétique** |
| `negatif_temoin_*.log` | les sabotages joués sur les instruments eux-mêmes |
| `negatif_lot1_*.log` | les sabotages joués sur les six sujets (après livraison A/B) |

## Le nom `_SYNTHETIQUE` n'est pas décoratif

Le filet `tests/world_v2/test_world_v2_lot1_defauts.gd` lit
**`verdict_repetition.json`**, sans suffixe. Le verdict synthétique porte donc
un nom que le filet ne peut pas lire : il ne peut pas verdir la suite par
accident. Un contrôle négatif qui pourrait passer pour la preuve qu'il
contrôle serait un faux témoin de plus.

## Le contrôle négatif D3, en détail

Six sujets « acceptés » de formes franchement différentes (muret, pont, dôme,
tertre, arbre, aiguille) calibrent le seuil. Deux sujets « du lot » sont
ajoutés, dont **un est la copie pixel pour pixel** d'un accepté.

Résultat, aux trois distances :

- **la copie est signalée** : `IoU = 1,0000`, `dprofil = 0,0000`, contre un
  seuil calibré de 0,718 / 0,690 / 0,682 ;
- **le témoin dégénéré est signalé** aux trois distances (`signale: true`) —
  un sujet comparé à lui-même ; sans lui, on ne saurait pas si la chaîne de
  chargement, de ré-échantillonnage et de comparaison a seulement tourné ;
- une seconde paire est signalée à 160 m (0,690 contre 0,682) : deux verticales
  étroites de l'échantillon synthétique. C'est un vrai positif de la mesure sur
  un dessin grossier, pas un défaut de l'outil — et il est publié plutôt que
  filtré ;
- le verdict final est **`BLOQUÉ`**, parce que quatre sujets du lot n'ont pas
  de silhouette. C'est le comportement voulu : un sujet qu'on ne voit pas ne
  peut pas être déclaré distinct.

Reproduction exacte : le script de génération est dans le rapport de la voie C ;
l'outil se rejoue par

```bash
python3 tools/lot1_repetition.py --manifestes <dossier de silhouettes> --out <json>
python3 tools/lot1_repetition.py --autotest   # le cas témoin analytique
```

## Ce que ce dossier NE prouve PAS

Rien sur les six lieux du lot, qui n'existent pas au moment où ces contrôles
ont tourné. Rien sur la performance (rendu logiciel). Rien sur la jouabilité
(ni écran ni manette). Ces trois-là restent `NON VÉRIFIÉ`.
