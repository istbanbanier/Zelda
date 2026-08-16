# La collerette mesurée par cinq instruments — et pourquoi le gate reste rouge

**Ce dossier ne valide rien.** Il croise les instruments et publie l'écart au lieu
de le moyenner.

## Les cinq lectures de la même grandeur

| instrument | mécanisme | AVANT (`8bc8b9f9`) | APRÈS visière (`4dd1642f`) |
|---|---|---:|---:|
| générateur, `controle_epaisseur` | cumul des blocs sur rayon, `i <= 1` | 0,48 m *(min. de 7 rayons)* | **1,05 m** *(de 33)* |
| ma coupe, `plot_cave_section.py` | premier bloc, direction transverse | 0,10 m | 0,83 m |
| agent collerette, méthode A | rayons selon la normale, rim topologique | — | 0,83 m |
| agent collerette, méthode B | sphère inscrite | 0,25 m | 0,68 m |
| **instruments, `cave_collar.py` A** | rayons normale + garde anti-rasant | **0,060 m** | **0,653 m** |
| **instruments, `cave_collar.py` B** | transformée de distance 2D, **aucun rayon** | **0,050 m** | **0,566 m** |

Journal brut : `journal_cave_collar.txt`.

## Ce qui est acquis, et qui n'est pas discutable

**La visière ferme le porche.** Toutes les lectures montent d'un facteur 3 à 11,
et deux faits ne viennent d'aucune convention de mesure :

1. **43 colonnes coiffées apparaissent**, toutes entre `y −2,25` et `−1,25`,
   c'est-à-dire exactement devant le porche, et **aucune colonne n'est perdue
   ailleurs** (`audit_cave_floor_columns.py`, qui ignore tout de la collerette).
2. **Le plan de bouche `y = −1,15` devient utilisable.** Avant, `cave_collar.py`
   devait reculer à `y = −0,95` parce que « le plan de bouche lui-même est ouvert
   latéralement ». Après, il travaille sur `y = −1,15`. Personne n'a conçu cet
   outil pour rapporter cela ; c'est tombé de la mesure.

Et le « avant » de référence n'est pas 0,48 m mais **25 rayons sur 33 qui sortent
par un jour**, azimuts 39–193° sans interruption : sur plus des trois quarts du
pourtour, il n'y avait **pas de roche du tout**. Le 0,48 était le minimum des
sept rayons survivants — un chiffre juste sur un échantillon qui excluait le
défaut.

## Ce qui reste rouge, et pourquoi je ne le déclare pas vert

**`cave_collar.py` méthode B rend 0,566 m pour un seuil de 0,60.** Verdict `FAIL`,
manque **0,034 m**.

C'est la mesure la plus conservatrice, produite par le seul mécanisme qui
n'emploie **ni rayon, ni normale, ni station** : une transformée de distance
8-connexe sur une coupe transversale rastérisée, l'ouverture étant reconnue par
inondation 2D.

Quatre chiffres pour une seule grandeur — 1,05 · 0,83 · 0,68 · 0,57 — et le plus
bas est sous le seuil. **Tant que l'écart n'est pas expliqué, l'item est
`NON VÉRIFIÉ`, pas `PASS`.** Le choisir serait exactement la faute que cette
passe traque depuis le début : un seul nombre, choisi parce qu'il arrange.

L'agent instruments marque d'ailleurs ses deux mesures **`NON CALIBRÉES`** de
lui-même, et nomme le suspect : deux mesures qui s'accordent peuvent partager une
erreur d'emprise. Sur la géométrie d'avant, il lit 0,050–0,060 m là où le
générateur lit 0,48 — l'écart de calibration est donc établi, il n'est pas
hypothétique.

## Ce qu'il faut avant de trancher

1. **Calibrer** `cave_collar.py` sur une forme dont l'épaisseur est connue
   analytiquement — un tube dans un cylindre. Un instrument qui n'a jamais été
   confronté à une réponse connue ne peut ni condamner ni acquitter.
2. **Faire converger les emprises** : les cinq instruments ne s'accordent pas sur
   ce qu'est « la limite de l'ouverture ». Tant que cette définition diffère, ils
   ne mesurent pas la même chose et leur désaccord n'est pas informatif.
3. Seulement ensuite, décider si 0,566 m condamne la visière ou l'instrument.

**Aucun seuil ne sera abaissé pour résoudre ceci.**
