# L'instrument de mesure spectrale — `tools/audio/band_profile.py`

**Document VIVANT.** Il décrit un outil présent dans l'arbre et exécutable.
Réserve **D-066** (ISS-087).

## Pourquoi ce document existe

Une première version de cet outil a servi de portail à des conclusions
sonores. Elle était fausse. Rien ne l'a signalé pendant qu'elle servait, parce
qu'**aucune de ses sorties n'avait jamais été confrontée à une réponse connue
d'avance**. Ce document est la confrontation manquante.

## Le défaut de la version précédente, et sa mesure

| | |
|---|---|
| Sortie fautive | 33 % d'énergie en 125-500 Hz pour du **bruit blanc** |
| Réponse théorique | **2,81 %** (la bande fait 618,7 Hz sur 22 050 de Nyquist) |
| Facteur d'erreur | ~12 |

Deux causes, indépendantes, toutes deux dans le code :

1. **Somme de raies de sonde au lieu d'une intégrale.** Huit raies échantillonnées
   par octave, quelle que soit la largeur de l'octave. Or l'octave 16 kHz couvre
   10 736 Hz et l'octave 31,5 Hz en couvre 22,3 — **481 fois moins**. Prendre
   huit points dans chacune mesure une *densité* spectrale moyenne, pas une
   *énergie*. Le biais gonfle les basses exactement du rapport des largeurs.

2. **Décimation sans filtre anti-repliement.** `step = max(1, n // 20000)`
   gardait une trame sur neuf sans passe-bas préalable. Sur un clip de
   176 400 trames le Nyquist effectif tombait à **2 756 Hz** : les colonnes
   4 k, 8 k et 16 k ne mesuraient plus que des alias.

Conséquences constatées par la contre-revue : `amb_drone_neris` annoncé à 0,5 %
en 125 Hz alors qu'il y met 38,4 % (**facteur 77**), et `amb_bed_riviere`
désigné « point faible » à 40,7 % alors qu'il est le plus propre de sa série
(1,4 %). **Une décision de conception a été prise à l'envers.**

## Ce que fait la version actuelle

Périodogramme de **Welch** : segments en puissance de deux, fenêtre de Hann
périodique, recouvrement 50 %, moyenne des périodogrammes. Spectre unilatéral
(raies intérieures comptées double, continu et Nyquist une fois). **Aucune
décimation, à aucun endroit.**

Puis l'intégration, qui est le point réparé : chaque raie couvre l'intervalle
`[(k-½)·df, (k+½)·df]` et verse son énergie aux bandes **au prorata du
recouvrement réel**. C'est ce prorata qui rend l'intégration juste là où les
raies sont rares — dans les octaves basses, précisément là où l'ancienne
version se trompait le plus.

Les fractions somment à 100 % par construction. Un total qui s'en écarterait
serait lui-même le signe d'un défaut : c'est le cas 5 de la validation.

## La validation, et ses cinq cas

`python3 tools/audio/band_profile.py --valider` — 3 s, code retour 0.
Journal figé : `evidence/world_v2/iss087/validation_instrument.log`.

| Cas | Entrée | Réponse théorique | Mesuré | Verdict |
|---|---|---|---|---|
| 1 | bruit blanc gaussien, graine figée | fraction = largeur / Nyquist, pour les 11 bandes | écart maximal **0,515 point** | PASS |
| 1b | idem, sous-total 125-500 Hz | 2,81 % | **2,83 %** | PASS |
| 2 | sinus pur 250 Hz | ~100 % dans l'octave 250 | **100,000 %** | PASS |
| 3 | sinus pur 16 kHz | ~100 % dans l'octave 16k, **rien** en bas | **100,000 %**, repliement sous 2 kHz : **0,0000 %** | PASS |
| 4 | bruit rose exact (densité 1/f) | énergie **égale** par octave pleine | dispersion **1,7 %** de la moyenne | PASS |
| 5 | conservation | somme = 100 % | **100,000000 %** | PASS |

Le **cas 3 vise le second défaut** : une décimation sans filtre replierait ce
ton de 16 kHz vers ~1,3 kHz et le ferait apparaître en bas. Le **cas 4 vise le
premier** : « huit sondes par octave » rend toutes les octaves égales pour du
bruit *blanc*, donc inégales pour du rose. Chaque cas tue un défaut nommé — ce
n'est pas une batterie décorative.

Le bruit rose est synthétisé **dans le domaine spectral** (module en 1/√f,
phase aléatoire, transformée inverse) : sa théorie est exacte par construction,
et non approchée par un générateur temporel dont il faudrait à son tour prouver
la couleur.

## Sensibilité de l'estimateur — pourquoi mes chiffres ne sont pas ceux de la contre-revue

Sur `amb_valley.wav`, sous-total 125-500 Hz, en faisant varier la longueur de
segment sur un rapport de **128×** :

| segment | 1024 | 2048 | 4096 | 8192 | 16384 | 32768 | 65536 | 131072 |
|---|---|---|---|---|---|---|---|---|
| Hz/raie | 43,07 | 21,53 | 10,77 | 5,38 | 2,69 | 1,35 | 0,67 | 0,34 |
| 125-500 % | 52,07 | 51,95 | 51,65 | **51,03** | 51,44 | 51,40 | 51,62 | 51,64 |

L'estimateur est stable à **±0,6 point**. La contre-revue rendait **54,8 %** sur
le même fichier. L'écart de ~3,8 points est donc **définitionnel, pas du bruit
de méthode** — deux implémentations toutes deux validées contre la théorie du
bruit blanc peuvent découper « 125-500 Hz » différemment (bornes d'octave,
affectation par centre de raie plutôt qu'au prorata, inclusion ou non de
l'octave 63).

**Je ne peux pas réconcilier : le code de référence a été détruit avec le reste.**
Cet écart reste `NON VÉRIFIÉ`. Il ne change aucune conclusion : 51 % comme 55 %
disent la même chose — **la moitié de l'énergie d'`amb_valley` tombe exactement
là où vivent les sons courts.**

Mes mesures encadrent les leurs sur les deux autres points de contrôle
conservés, ce qui est cohérent avec un désaccord de découpage et non de méthode :

| Son | contre-revue | sa référence | **cet outil** |
|---|---|---|---|
| `amb_valley`, 125-500 Hz | 54,7 % | 54,8 % | 51,03 % |
| `hit_taken`, octave 125 | 94,1 % | 90,0 % | **91,67 %** |
| `step_stone_a`, octave 250 | 85,1 % | 80,6 % | **82,48 %** |

## Limites assumées

- **Ne décode pas l'Ogg Vorbis.** Les six sons d'interface (`assets/audio/ui/`)
  sont hors de portée. Les 21 sons de `assets/audio/sfx/` sont tous en WAV.
- Pas de `numpy` ni de `scipy` : le paquet numpy est présent mais ses extensions
  C sont cassées (`No module named numpy.core._multiarray_umath`). FFT en Python
  pur, radix 2, table de racines mémorisée. Coût mesuré : 3 s pour la
  validation, ~2 s pour les 21 sons.
- Mesure un **fichier**, pas un mixage. Aucun verdict d'écoute ne peut en sortir :
  ce conteneur n'a pas de périphérique audio (ISS-004).

## Codes retour

`0` mesure faite · `3` BLOQUÉ, rien de mesurable · `1` la validation échoue.
Convention de `tools/CLAUDE.md` : une étape sautée ne rend jamais 0.
