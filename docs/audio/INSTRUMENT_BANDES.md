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

## La validation, et ses six cas

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

## Le second défaut, trouvé par contre-revue le 2026-08-31

Cette version-ci a été corrigée une seconde fois. Le défaut était **de la même
famille** que celui qu'elle réparait : une pondération systématique oubliée.
La première version oubliait la largeur de bande dans le domaine
**fréquentiel** ; la deuxième oubliait la couverture dans le domaine
**temporel**.

### Ce qui n'allait pas

`profil` posait `hop = L // 2` sous fenêtre de Hann, sans bourrage aux bords.
La somme des `hann²` n'est alors pas constante : elle monte de zéro jusqu'à son
palier sur les `L/2` premières trames. Ces trames-là n'étaient vues que par la
jupe montante d'une seule fenêtre.

Sur un lit stationnaire de 42 segments, l'effet se noie. Sur un **one-shot
percussif** — 20 des 21 WAV du dépôt — l'attaque porte 27 à 42 % de l'énergie
et se trouve exactement là. Elle était vue à 0,7-1,6 % de son poids.

S'y ajoutait un abandon de queue silencieux : jusqu'à `L-1` trames finales
n'étaient lues par aucun segment, sans mention. `n = 300` rendait une sortie
identique à `n = 256`.

### L'entrée à réponse exacte qui l'a établi

Deux moitiés successives, chacune divisée par la racine de son énergie, donc
rigoureusement égales : attaque à 8 kHz, queue à 200 Hz. La théorie n'a pas de
tolérance — **50,00 % dans l'octave 8k**.

| clip (attaque + queue, trames) | avant | après |
|---|---:|---:|
| 441 + 2 205 | 8,90 % | **49,82 %** |
| 882 + 5 292 | 5,51 % | **49,91 %** |
| 441 + 4 410 | 0,70 % | **49,88 %** |
| 441 + 8 820 | 0,05 % | **49,83 %** |
| 441 + 44 100 | **0,03 %** | **49,84 %** |

Facteur d'erreur jusqu'à **1 700**. L'instrument qu'on avait remplacé pour un
facteur 77 en faisait 1 700 sur cette classe d'entrée. Le résidu de 0,1-0,2
point est la fuite de la fenêtre de Hann par-dessus la frontière d'octave, pas
un biais systématique.

**Aucun des cinq cas de validation ne pouvait le voir** : tous les cinq sont
stationnaires sur quatre secondes. C'est le trou exact que le cas 6 comble.

### La correction

`hop = L // 4`, plus `L - hop` zéros aux deux bords. `hann²` satisfait la
condition COLA à `hop = L/4` — son spectre ne porte que les raies 0, 1 et 2, et
le repliement de la somme se produit aux raies multiples de 4, donc nulles.
Chaque trame réelle est alors couverte par exactement quatre fenêtres, la
pondération est plate d'un bout à l'autre, et le bourrage corrige au passage
l'abandon de queue.

### Le cas 5 était une tautologie, et il ne l'est plus

L'ancien cas 5 vérifiait que `sum(fractions)` vaut 100. Or `profil` divise par
ce total : la somme vaut 100 **par construction**. La contre-revue l'a prouvé
en sabotant l'outil de deux façons — un trou de 2,8 kHz dans `bornes_bandes`
(l'octave 4k retirée), et le défaut de prorata historique réinjecté. Dans les
deux cas, la somme est restée à **100,000000 %**.

Le cas 5 contrôle désormais la **couverture** : le rapport entre l'énergie
versée aux bandes et l'énergie présente dans les raies. Ablation refaite :

| ablation | ancien cas 5 | **nouveau cas 5** |
|---|---|---|
| octave 4k retirée de la couverture | 100,000000 % — **vert** | **87,061099 % — ROUGE** |
| prorata par largeur de bande (défaut historique) | 100,000000 % — **vert** | ROUGE via les cas 1, 1b, 4 |
| `hop = L // 2` restauré | vert | cas 6 ROUGE : écart 49,97 pt |

Ce nouveau cas 5 a **échoué dès sa première exécution**, à 100,003304 %, et il
avait raison : `bornes_bandes` posait indépendamment `63·√2 = 89,095` et
`125/√2 = 88,388`, parce que le rapport 125/63 vaut 1,984 et non 2. Les deux
bandes se **recouvraient** sur 0,707 Hz, et toute raie de cette lame était
versée deux fois. Les raccords sont désormais des moyennes géométriques
`sqrt(c_i · c_{i+1})` — identiques à `c·√2` partout où le rapport est 2, donc
un seul raccord de tout le tableau se déplace.

### Le mode `--csv` se cassait sur son propre livrable

L'en-tête était figé sur `bornes_bandes(22050.0)` — 11 bandes — tandis qu'une
ligne suivait le Nyquist du fichier mesuré. Un WAV à 22 050 Hz n'en produit que
10 : la ligne sortait à **14 champs contre 15 d'en-tête**, `masquage_125_500`
glissait dans la colonne `b_16k`, et `reproduire_mesures.py` levait un
`TypeError` sur `float(None)`. C'est-à-dire précisément le format que le lot
recommande de produire pour une ambiance à 22,05 kHz. Les colonnes sont
maintenant fixes (`COLONNES_CSV`), et une bande au-dessus du Nyquist du fichier
sort en **champ vide** — jamais `0,000` : « absent » et « mesuré à zéro » ne
sont pas la même affirmation.

### Ce que la correction a changé aux conclusions publiées

Trois fichiers sur 21 étaient faux — exactement les trois où le découpage
laissait 1 à 3 segments. Les 18 autres tenaient à moins de 2,5 points.

| fichier | 125-500 Hz avant | après | > 2 828 Hz avant | après |
|---|---:|---:|---:|---:|
| `land_hard` | 11,66 % | **36,47 %** | 3,98 % | 4,31 % |
| `pickup` | 15,82 % | **64,66 %** | 0,00 % | 0,00 % |
| `weapon_break` | 79,15 % | **58,31 %** | 13,14 % | **31,48 %** |

**Aucune conclusion stratégique n'est renversée.** La règle « creuser
125-500 Hz » survit (dix sons sur vingt au lieu de onze), la bande creuse
707-2 828 Hz survit, et les trois pas sur l'herbe montent de 68,7/63,6/73,0 %
à 71,8/67,0/75,7 % au-dessus de 2 828 Hz. Ce qui ne survit pas, c'est le
tableau d'occupation, faux sur quatre de ses onze lignes — rectifié dans
`docs/audio/INVENTAIRE_SONORE.md` §3.

### Convergence indépendante

La contre-revue avait écrit son propre analyseur — FFT vérifiée contre une DFT
naïve, Parseval exact à chaque appel, plus un troisième estimateur STFT à
recouvrement 75 %. L'instrument corrigé retombe sur ses valeurs : `weapon_break`
58,31 % et 31,48 % à l'identique, les trois pas d'herbe à 0,00 point près,
`land_hard` à 0,22 point, `pickup` à 1,6 point. Deux chemins de calcul écrits
séparément qui convergent valent mieux qu'un seul qui s'auto-vérifie.

## Limites assumées

- **Ne décode pas l'Ogg Vorbis.** Les six sons d'interface (`assets/audio/ui/`)
  sont hors de portée. Les 21 sons de `assets/audio/sfx/` sont tous en WAV.
- Pas de `numpy` ni de `scipy` : le paquet numpy est présent mais ses extensions
  C sont cassées (`No module named numpy.core._multiarray_umath`). FFT en Python
  pur, radix 2, table de racines mémorisée. Coût mesuré : 3 s pour la
  validation, ~2 s pour les 21 sons.
- Mesure un **fichier**, pas un mixage. Aucun verdict d'écoute ne peut en sortir :
  ce conteneur n'a pas de périphérique audio (ISS-004).
- **Fuite de fenêtre près d'un raccord d'octave.** Le lobe principal de Hann
  s'étale sur ±2 raies. À `L = 8192` cela fait ±10,8 Hz ; à `L = 1024` — la
  longueur retenue pour un clip très court comme `ui_move` — cela fait ±86 Hz.
  Un ton à 1 % sous un raccord se voit donc réparti sur les deux bandes. Borné
  et localisé, mais réel : ne pas lire une répartition 85/15 près d'un raccord
  comme une vraie bimodalité.
- **Les six cas de validation sont tous mono.** La lecture 8/24/32 bits et le
  downmix stéréo sont implémentés et ont été éprouvés à la main, mais **aucun
  cas ne les garde**. Un stéréo en opposition de phase rend un profil de zéros
  avec un code retour 0, sans avertissement. Sans portée aujourd'hui : les 21
  assets sont mono.

## Codes retour

`0` mesure faite · `3` BLOQUÉ, rien de mesurable · `1` la validation échoue.
Convention de `tools/CLAUDE.md` : une étape sautée ne rend jamais 0.
