# La collerette mesurée par cinq instruments — et deux d'entre eux étaient biaisés

**Ce dossier ne valide aucune livraison.** Il croise les instruments, calibre
ceux qu'on peut calibrer, et publie l'écart au lieu de le moyenner.

## L'histoire courte

Quatre chiffres existaient pour une même grandeur : **1,05 · 0,83 · 0,68 · 0,57**.
Le plus bas échouait au seuil de 0,60, et j'ai refusé de choisir. La calibration
sur une forme à réponse connue a montré que **le chiffre bas était faux d'une
maille de raster**, et que **le mien est faux dans l'autre sens**.

Aucun seuil n'a été touché.

## La calibration, et pourquoi elle tranche

Un tube de rayon `r` dans un cylindre de rayon `R` : la collerette vaut
exactement `R − r`, partout, dans toutes les directions. Aucune place pour un
désaccord d'emprise. Polygone à 96 côtés, écart de surface 0,053 % — deux ordres
sous le biais cherché.

### `cave_collar.py` méthode B sous-estimait d'exactement une maille

| pas | 0,1000 | 0,0500 | 0,0250 | 0,0125 |
|---|---:|---:|---:|---:|
| biais | −0,1000 | −0,0500 | −0,0250 | −0,0125 |
| biais / pas | −1,00 | −1,00 | −1,00 | −1,00 |

À pas constant, le biais ne bouge pas quand l'épaisseur passe de 0,30 à 1,20 m :
**il suit le pas et ignore la grandeur mesurée.** C'est de la discrétisation. La
première case de roche est à une demi-maille de l'air, la dernière à une
demi-maille de l'ouverture, et le compte perd une maille entre les deux.
Correction `+ pas` ; après, biais **0,0000 m sur les huit formes**.

**La vérification indépendante que je peux faire sans rejouer quoi que ce soit** :
j'avais mesuré 0,5657 m avec l'outil non corrigé, au pas de 0,05. `0,5657 + 0,0500
= 0,6157` — exactement la valeur que l'outil corrigé publie. Le chiffre que
j'avais noté avant que la correction existe confirme la correction.

### Ma propre coupe sur-évalue, et je ne m'exempte pas

`plot_cave_section.py`, même forme analytique (`calibration_de_ma_coupe.txt`) :

| r | R | attendu | `premiere` | biais |
|---:|---:|---:|---:|---:|
| 0,8 | 1,5 | 0,7000 | 0,7897 | **+0,0897** |
| 1,0 | 2,2 | 1,2000 | 1,2465 | +0,0465 |
| 1,0 | 1,3 | 0,3000 | 0,3204 | +0,0204 |
| 1,5 | 1,8 | 0,3000 | 0,3013 | +0,0013 |
| 2,0 | 3,2 | 1,2000 | 1,2000 | **+0,0000** |

**Elle sur-évalue, d'autant plus que le rayon de la galerie est petit.** Signature
d'une origine de rayon qui n'est pas sur l'axe du cercle : le rayon parcourt une
corde, pas un rayon. Au porche, où `hw` vaut 1,70–1,90, le biais attendu est de
l'ordre de +0,00 à +0,03 m.

Ce qui reste valide dans mes lectures : **les comptes** (13 rayons sans aucune
roche → 0) et **la structure des blocs** (`ROCHE 0,20 · vide 1,10 · ROCHE 3,84`)
ne dépendent pas de cette échelle. Ce qui est à corriger vers le bas : mes
chiffres absolus d'épaisseur.

Et la « convergence à quatre décimales » entre ma coupe (0,10 m) et le B corrigé
(0,1000 m) sur la géométrie d'avant est donc **plus fragile qu'elle n'en avait
l'air** : deux instruments biaisés en sens contraires peuvent se croiser. Je la
retire comme argument.

## Les lectures, après calibration

| instrument | mécanisme | AVANT `8bc8b9f9` | APRÈS visière |
|---|---|---:|---:|
| générateur, `controle_epaisseur` | cumul des blocs, `i <= 1` | 0,48 m *(min. de 7 rayons)* | 1,05 m *(de 33)* |
| ma coupe *(sur-évalue jusqu'à +0,09)* | premier bloc, transverse | 0,10 m | 0,83 m |
| agent collerette, sphère inscrite | rayon 3D | 0,25 m | 0,68 m |
| **`cave_collar.py` A** *(biais 0,0006)* | rayons normale + garde anti-rasant | 0,0601 m | **0,7699 m** |
| **`cave_collar.py` B** *(calibré, biais 0,0000)* | transformée de distance 2D, **aucun rayon** | **0,1000 m** | **0,7500 m** |

Dernière ligne mesurée par moi sur `a4cce09c`, l'état du lot collerette à
l'instant du run — **l'agent itérait encore, et ce n'est donc pas un livrable**.
Sur l'état précédent `4dd1642f` : A 0,6533, B 0,6157.

**Verdict de `cave_collar.py` : `PASS`, les deux mécanismes au-dessus de 0,60**,
et au-dessus de la cible de conception de 0,70.

## Ce qui est acquis sans dépendre d'aucune convention de mesure

1. **43 colonnes coiffées apparaissent**, toutes entre `y −2,25` et `−1,25`,
   exactement devant le porche, **zéro perdue ailleurs**
   (`audit_cave_floor_columns.py`, qui ignore tout de la collerette).
2. **Le plan de bouche `y = −1,15` devient utilisable.** Avant, `cave_collar.py`
   devait reculer à `y = −0,95` : « le plan de bouche lui-même est ouvert
   latéralement ». Personne n'a conçu cet outil pour rapporter cela.
3. Le « avant » de référence n'est pas 0,48 m mais **25 rayons sur 33 sortant par
   un jour**, azimuts 39–193° sans interruption : sur plus des trois quarts du
   pourtour, **pas de roche du tout**. Le 0,48 était le minimum des sept rayons
   survivants — juste sur un échantillon qui excluait le défaut.

## Ce qui reste ouvert

- **Le générateur et la sphère inscrite ne sont pas calibrés.** Le cylindre existe
  (`tools/cave_collar_calibration.py`), il prend une minute, et il a déjà attrapé
  deux défauts en une passe. Tant qu'ils ne le sont pas, leurs chiffres sont des
  indications, pas des preuves.
- **Le biais de ma coupe n'est pas corrigé**, seulement mesuré et publié.
- **Aucune capture.** Rien n'établit que la visière se *lise* comme de la roche
  plutôt que comme une arche. C'est une question d'œil, elle n'appartient pas aux
  instruments.

## Fichiers

| fichier | contenu |
|---|---|
| `journal_cave_collar.txt` | l'outil **non corrigé** sur les deux géométries, tel que mesuré avant la calibration |
| `calibration_de_ma_coupe.txt` | mon propre instrument confronté à la réponse analytique |
