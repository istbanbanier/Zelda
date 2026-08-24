# Le premier verdict D3 de la passe intégrée était FAUX — et c'est moi qui l'ai fabriqué

**Verdict rendu à 15:55** : `FAIL` —
`valley.poi.overlook_summit.01` ≈ `valley.poi.waterfall_cave.01`,
IoU 0,5073 à 30 m (seuil 0,4931) et 0,5171 à 80 m (seuil 0,4912).

Lu tel quel, ce verdict dit que la corrective de la voie A a **re-cassé** une
contrainte que le lot 1 avait fermée (le même couple y était passé de 0,568 à
0,481 par correction de composition). C'était faux. J'ai failli renvoyer un
lieu en corrective sur une mesure de ma propre fabrication.

## Ce qui l'a trahi

L'emprise du belvédère est **identique au centième** avant et après la
corrective : `L = 22,41 · H = 6,96 · P = 20,41`. Une composition retravaillée
qui ne bouge pas d'un centimètre son enveloppe, mais dont l'IoU saute de 0,481
à 0,517, n'a pas changé de forme : c'est la MESURE qui a changé.

## La cause, en une ligne de code

`tools/godot/capture_silhouette.gd` dérive son cadrage de l'emprise **et du
rapport de l'image** :

```gdscript
var largeur_apparente: float = maxf(boite.size.x, boite.size.z)
var hauteur_requise: float = maxf(
    boite.size.y, largeur_apparente * float(_height) / float(_width))
camera.size = hauteur_requise * (1.0 + MARGE * 2.0)
```

Le facteur `_height / _width` vaut **1,333** en portrait 900 × 1200 et **0,750**
en paysage 1200 × 900 — un rapport de 1,78 entre les deux. Sur un sujet large
et bas comme le belvédère, c'est le terme `largeur_apparente × ratio` qui
gouverne, donc le cadrage entier.

Ma passe a forcé `--size=1200x900` sur les six lieux. La baseline du lot 1 —
et le corpus gelé auquel D3 les compare — emploie **900 × 1200 pour onze
sujets sur quinze**, et 1200 × 900 seulement pour les quatre sujets larges et
plats (`barrow_cemetery`, `camp`, `conductive_basin`, `flower_field`).

## L'effet, chiffré

Part de la hauteur d'image occupée par le sujet :

| Sujet | Portrait 900 × 1200 | Paysage 1200 × 900 |
|---|---:|---:|
| Belvédère | **19,4 %** | 34,5 % |
| Grotte | **32,5 %** | 57,7 % |

- **Cadrage du corpus** (les deux en portrait) : 19,4 % contre 32,5 % —
  **13,0 points d'écart**. Deux bandes de hauteurs franchement différentes,
  donc une IoU basse : le 0,481 du lot 1.
- **Ma passe** (belvédère en paysage, grotte restée en portrait du corpus) :
  34,5 % contre 32,5 % — **2,1 points d'écart**. Les deux masques deviennent
  la même bande, et l'IoU monte mécaniquement à 0,507 / 0,517.

Le détecteur n'a pas menti : on lui a donné deux images qui ne se comparent
pas, et il a fait son travail sur ce qu'on lui a donné.

## Ce que ça confirme, et ce que ça ouvre

C'est la **loi de cadrage par la largeur au sol** déjà mesurée pendant le lot
1.R — 85,1 % du masque du cimetière tombait dans celui du belvédère par le seul
effet du rapport hauteur/largeur. Elle vient de mordre une seconde fois, sur
moi cette fois.

Elle ouvre aussi une faiblesse **du dispositif D3 lui-même**, qui n'est pas de
mon ressort ici : le corpus gelé **mélange les deux rapports d'image**. Onze
sujets en portrait, quatre en paysage, et rien n'oblige nulle part à respecter
ce choix par sujet — il vit dans la mémoire de celui qui a lancé la capture.
Les seuils ont été calibrés sur ce mélange, donc on ne peut pas y toucher sans
tout recalibrer. Ticket à ouvrir, pas correctif de corrective.

## Correction appliquée

Les quatre sujets concernés — tour de guet, belvédère, source, sanctuaire —
sont recapturés en **900 × 1200**, taille **recopiée du manifeste de leur
propre baseline**, et D3 est rejoué. Le cimetière et le champ étaient déjà en
1200 × 900, conformes à la leur.

Le verdict FAIL et son journal restent committés à côté du nouveau. On ne
supprime pas une mesure fausse : on l'explique.
