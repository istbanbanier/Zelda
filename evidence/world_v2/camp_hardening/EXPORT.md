# Les deux portails d'export — et pourquoi ce fichier remplace les précédents

**Constat bloquant de la contre-revue, et il était juste.** Les journaux
d'abord committés portaient `SHA testé : 398a0f30`, alors que le commit
suivant — `f056f017` — modifiait **cinq fichiers exportés**, dont
`WorldV2.tscn` (l'injection de `donnees` dans `CampCuisineGuard` : sans elle,
le garde est inerte). Un verdict dont la preuve précède le dernier changement
du fichier concerné est **périmé, pas hérité**. Et le message de commit qui les
apportait disait « sur l'arbre committé 334b2032 » : les journaux le
contredisaient.

Les deux portails ont donc été **rejoués** sur l'arbre final.

```
SHA testé : 783217bfcbe7c8b2f562dc59c5a07987d54aaf29
VERDICT ISS-071 : VERT (code 0)
GATE_EXPORT_GARNISON : VERT (0 échec)
```

Journal complet : `export_deux_portails_783217bf.log`.

## Ce que ces portails prouvent, et ce qu'ils ne prouvent pas

Un binaire autonome de 411,5 Mo, exporté puis **réellement lancé** sous Xvfb :
« Nouvelle partie » pilotée par le focus X, jalon de montage du monde atteint,
écran de chargement effacé (luminance mesurée contre un seuil), manifeste écrit
par le jeu lui-même, zéro ressource manquante dans le PCK sur **tous** les
journaux du run, zéro duplication à la relance, morts et inventaire persistés à
travers un vrai redémarrage de processus.

Ils ne prouvent **pas** l'échange de coups : un clavier synthétique en rendu
logiciel n'en ferait pas une mesure déterministe. Le combat est prouvé en
moteur par `test_world_v2_garrison_combat.gd`.

## Ce qui manquait au conteneur, et ce que les portails en disaient

Trois outils absents, et chaque fois le portail accusait le JEU :

| Manquant | Message rendu | Cause réelle |
|---|---|---|
| templates d'export | `BLOQUÉ: templates absents` | exact — recompilés depuis `/opt/src/godot`, 12 min 51 s |
| `xdotool` | « fenêtre « Eclats d'Orage » introuvable après 120 s » | l'outil n'existait pas |
| ImageMagick | « l'écran de chargement n'a jamais disparu (luminance -1) » | `-1` est un sentinelle « pas mesuré », pas un écran noir |

Les deux derniers messages désignent le jeu pour un défaut d'outillage. C'est
une faiblesse de diagnostic à corriger si ces portails doivent tourner sur une
machine neuve.
