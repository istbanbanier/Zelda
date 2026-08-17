# R2a-3.5.5 — agent A, étapes A2 et A3 : le correctif, son effet, sa non-régression

**Type de document : HISTORIQUE.** Journal daté. Il ne fait autorité sur rien ;
les instruments qu'il cite, si.

| | avant | après |
|---|---|---|
| GLB | `c184c8dc0c0e754a` | **`bf68bfda37976758`** |
| octets | 1 490 320 | 1 488 728 |
| `CALOTTE_AZIMUTS` | 5 | **7** |
| roches de calotte | 23 | 33 |
| volume | 796,445 m³ | 798,0 m³ |
| triangles | 20 072 | 20 070 |

Le GLB « après » est produit par `tools/blender/export_cave_echafaudage.sh`
avec `--diagnostic` : **il n'est pas livrable**, `controle_epaisseur_domaine`
restant rouge comme il l'a toujours été sur toute géométrie.

---

## 1. Le résultat qui compte, et ce n'est pas le correctif

**L'argmin s'est déplacé, et il a changé de nature.**

| | avant | après |
|---|---:|---:|
| lecture (masque 2,00 · `h` 0,10) | 0,6613 m | **0,6813 m** |
| borne garantie | 0,5613 m | 0,5813 m |
| argmin | `(1,036 ; 5,173 ; 2,316)` | **`(3,039 ; 1,920 ; 1,704)`** |
| **direction de la roche manquante** | **97,1 % verticale** | **98,2 % horizontale** |
| côté | joue gauche / nord | **joue DROITE (+n)** |
| distance à la courbe | 3,037 m | 0,782 m |
| `u` / `s` | 4,9124 / +3,841 m | 5,0107 / +3,928 m |
| échantillons sous 0,80 m | **2 216** | **1 122** (−49,4 %) |
| échantillons indécidables | 5 430 | 4 712 |
| verdict | `FAIL` | **`FAIL`** |

Le défaut que je viens de corriger était **zénithal, sur la joue nord**, du
ressort de `rochers_calotte_nord()`. Celui qui le remplace est **latéral, sur
le flanc droit de la salle** — un côté que la calotte ne couvre pas par
construction (ses azimuts vont de 100° à 176°, c'est-à-dire côté `−n`). Le
même levier ne s'y applique pas.

C'est l'inquiétude que j'avais mise en tête de mes `NON VÉRIFIÉ` à l'étape
A1, et elle se vérifie.

---

## 2. La carte, avant et après — le correctif porte plus loin que prévu

J'annonçais que la calotte ne portait que l'amas de l'argmin, soit 11,6 %.
**C'était trop pessimiste**, et la mesure me corrige.

**Avant — 2 216 points, 5 amas** (agglomération à 0,50 m) :

| amas | pts | % | centre | min |
|---:|---:|---:|---|---:|
| 0 | 996 | 44,9 | `(2,86 ; 4,38 ; 1,21)` | 0,7484 |
| 1 | 761 | 34,3 | `(3,23 ; 2,36 ; 1,75)` | 0,6813 |
| 2 | 258 | 11,6 | `(1,57 ; 5,02 ; 2,18)` | **0,6613** ← argmin |
| 3 | 111 | 5,0 | `(2,01 ; 0,13 ; 1,93)` | 0,7451 |
| 4 | 90 | 4,1 | `(0,02 ; 6,11 ; 0,88)` | 0,7564 |

**Après — 1 122 points, 3 amas** :

| amas | pts | % | centre | min |
|---:|---:|---:|---|---:|
| 0 | 761 | 67,8 | `(3,23 ; 2,36 ; 1,75)` | **0,6813** ← argmin |
| 1 | 250 | 22,3 | `(2,24 ; 4,93 ; 1,92)` | 0,7198 |
| 2 | 111 | 9,9 | `(2,01 ; 0,13 ; 1,93)` | 0,7451 |

Lecture ligne à ligne :

- **amas 0 (996 pts) : disparu.** Il était à `ay = 4,38`, dans l'emprise de
  la calotte.
- **amas 4 (90 pts) : disparu.**
- **amas 2 (258 pts, celui de l'argmin) : réduit à 250, et son minimum remonte
  de 0,6613 à 0,7198** — +0,059 m.
- **amas 1 (761) et amas 3 (111) : rigoureusement inchangés**, y compris leurs
  minima. Ils sont hors de portée de la calotte.

Répartition des lectures, dans les deux cas : **aucun point sous 0,60 m**, et
97 % entre 0,70 et 0,80. Rien n'est catastrophique ; tout est *juste sous* le
seuil.

### Groupés ou dispersés — la réponse

**Groupés.** Trois amas compacts, dont un porte 67,8 %. Ce n'est pas une
dispersion sur toute la coque, et une correction locale peut donc encore
progresser. Mais chaque amas relève d'une cause différente : le suivant est
latéral quand celui-ci était zénithal, et il faudra le diagnostiquer à part.

### Les 4 712 indécidables

Mis en avant à la demande du coordinateur, et il a raison de le demander :
**lecture ≥ 0,80 mais borne < 0,80**, donc `h = 0,10` est trop grossier pour
trancher sur une région entière. Ce n'est pas du bruit de résolution : c'est
quatre fois l'effectif des points franchement sous le seuil. Le contrat prévoit
exactement ce cas — `BLOQUÉ`, RC 3 — mais il est ici masqué par un `FAIL`
franc qui le précède.

---

## 3. Le contour de bouche — la divergence signalée n'en est pas une

Le coordinateur a relevé un périmètre de bouche invraisemblable : 53,755 m
pour une ouverture de ~3,8 × 2,9 m. **Constat exact, cause trouvée, et elle
n'oppose pas deux agents.**

Les trois chiffres cités viennent du **même outil**, `cave_check_hull.py`, et
ne diffèrent que par `--pas-balayage` :

| source | géométrie | pas | plan | périmètre | arêtes |
|---|---|---:|---:|---:|---:|
| `r2a354_agentC/coque_c184c8dc.log` | `c184c8dc` | 0,250 | −1,615 | **11,978 m** | 175 |
| `r2a354_gate/coque_c184c8dc_FAIL.log` | `c184c8dc` | 0,050 | −1,765 | **53,756 m** | 532 |
| moi, `localiser_*` | idem | 0,050 | −1,765 | 53,756 m | 532 |

(Le troisième chiffre du coordinateur, 13,879 m à `ay = −1,972`, concerne
**R2a-3.4**, une autre géométrie — 156,86 m² de peau intérieure contre 95,19.)

### Pourquoi le pas change le plan

Les deux barrières enferment **exactement 95,19 m²**. Le critère de sélection
— « la plus extérieure des valides, celle qui enferme le plus de cavité » —
est donc **dégénéré** : à aire égale, un pas fin découvre un plan plus
extérieur, qui coupe le massif entier (13,30 × 7,29 m) au lieu de la bouche.

### Pourquoi cela ne change PAS la mesure

`contour_bouche.log`, aux deux pas :

| | pas 0,050 | pas 0,250 |
|---|---:|---:|
| arêtes du contour | 533 | 175 |
| **bordant la peau INTÉRIEURE** | **99** | **99** |
| → **faces de départ du front géodésique** | **56** | **56** |
| bordant la peau extérieure seule (ignorées) | 434 | 76 |
| **emprise des faces de départ** | **3,96 × 3,01 m** | **3,96 × 3,01 m** |

Le front géodésique ne part que des faces `dedans`. Les 434 arêtes
supplémentaires bordent la peau **extérieure** et n'y entrent jamais. La
bouche effective est identique aux deux pas, et c'est bien une bouche de
3,96 × 3,01 m — l'ordre de grandeur attendu.

**Confirmation indépendante** : les deux exécutions de l'agent C publient des
tables d'emprise de masque **identiques au point près** — 114 376 / 111 432 /
105 800 / 91 064 / 86 020 / 69 408 échantillons, et `0,6613 m` au même argmin.

> **Ma lecture n'est donc pas optimiste.** Le masque écarte la même peau quel
> que soit le contour retenu.

### Le ticket qui reste

Le champ « périmètre » de `cave_check_hull.py` publie la longueur du **contour
complet**, section du massif comprise, et l'appelle « bouche ». C'est
trompeur — cela a coûté cet aller-retour — mais sans effet sur aucun verdict.
**Ticket, pas préalable.** La correction serait de publier le périmètre des
seules arêtes bordant la peau intérieure.

---

## 4. Non-régression (A3)

| contrôle | avant | après | verdict |
|---|---|---|---|
| genre topologique `SM_` | 0 (χ = 2) | **0 (χ = 2)** | conservé |
| genre topologique `COL_` | 0 | **0** | conservé |
| bords libres | 0 | **0** | conservé |
| arêtes non-manifold | 0 | **0** | conservé |
| composantes de surface | 1 | **1** | conservé |
| composition, entaille 0,90 | 3 / 3 / 3 masses | **3 / 3 / 3** | conservé |
| ratios d'emprises | 2,16 / 2,33 / 2,25 | **2,16 / 2,37 / 2,25** | conservé (seuil ≥ 2,00) |
| télémétrie de domaine | 29 plaques | **28 plaques** | −1 |
| gabarit | passe aux 7 stations | **passe aux 7 stations** | conservé |
| plancher | 0 faute / 54 sondes | **0 faute / 54 sondes** | conservé |
| épaisseur historique (stations) | — | **0,87 m paroi · 1,15 m linteau** | passe |
| auto-intersection | — | 2 paires, repli 0,0006 m (seuil 0,020) | passe |

### Connexité interne — aucune bulle nouvelle

Même commande, même paramètres, sur les deux géométries :

| composante | avant | après |
|---:|---|---|
| 2 (extérieur) | 52 201 seg · 353,11 m³ | 52 078 seg · 352,94 m³ |
| 0 | 22 801 seg · 168,36 m³ | 22 800 seg · 168,36 m³ |
| **3 (salle + niche + vide ciblé)** | **7 069 seg · 28,88 m³** | **7 069 seg · 28,88 m³** |
| 4 | 64 seg · 0,03 m³ | 64 seg · 0,03 m³ |
| 1 | 1 seg · 0,00 m³ | 1 seg · 0,00 m³ |

**5 composantes avant, 5 après, les mêmes.** La composante intérieure est
identique au segment près ; salle, niche et vide ciblé y restent ensemble, et
l'extérieur en reste séparé sous le plafond de grille. Les 0,17 m³ perdus par
l'extérieur sont exactement la roche ajoutée.

### Le ratio qui bouge, et pourquoi ce n'est pas une dégradation

Seul l'azimut 100° change : emprises `5,09 / 6,79 / 2,92` → `4,96 / 6,92 / 2,92`,
donc ratio `2,33 → 2,37`. Le portail exige un **minimum** de 2,00 : le ratio
monte, les masses sont légèrement plus inégales, et `controle_amas` franchit.

---

## 5. La butée de plafond parle maintenant

Exigence du coordinateur, tenue sans changer le comportement :

```
[grotte] calotte nord : 10/33 poses ECRETEES par CALOTTE_PLAFOND_M = 4.00 m ;
         retrait max 0.499 m en (2.06 ; 3.27) ; couverture la plus mince
         obtenue 1.101 m pour 1.60 visee
```

Elle mordait **7 poses sur 23** avant, **10 sur 33** après. Son commentaire la
présentait comme « une butée si un réglage futur devenait déraisonnable » —
elle agissait déjà sur un tiers des poses.

---

## 6. Le certificat local — la cible est atteinte, et le rayon compte

`h = 0,05 m`, masque 2,00, autour de l'ancien argmin `(1,036 ; 5,173 ; 2,316)` :

| rayon | échant. | lecture | borne | argmin local | sous 0,80 |
|---:|---:|---:|---:|---|---:|
| **0,30 m** | 316 | **1,1777 m** | **1,1277 m** | `(1,254 ; 5,366 ; 2,285)` | **0** |
| 1,00 m | 3 842 | 0,7561 m | 0,7061 m | `(1,985 ; 5,146 ; 2,017)` | 72 |

**À l'endroit visé, la cible de robustesse est tenue et largement** :
1,1777 m de lecture contre 0,90 demandés, borne 1,1277 m contre 0,85 — soit
**+0,516 m** sur la lecture de départ (0,6613 m), et aucun échantillon sous
0,80 m dans le voisinage.

Le rayon de 1,00 m rend un chiffre plus bas parce qu'il capture un point
**à 0,95 m de là**, `(1,985 ; 5,146 ; 2,017)` — au bord du voisinage, et
appartenant à un autre défaut. Ce n'est pas une contradiction : c'est la
raison pour laquelle un certificat local doit publier son rayon. Les deux
sont donnés, et le lecteur voit exactement ce que chacun mesure.

Le `h` de 0,05 **resserre** la borne : à lecture égale il est plus exigeant
que `h = 0,10`, jamais l'inverse. Aucun seuil n'a été touché.

---

## 7. Ce qui reste `NON VÉRIFIÉ`

- **L'attribution d'étape sur la géométrie corrigée n'a pas été faite.**
  `tools/cave_fix_etapes.py` a reçu ses options `--point` / `--sortie` pour
  cela, mais le passage Blender n'a pas été lancé. L'attribution de A1 reste
  **déduite**, pas mesurée après chacune des cinq étapes.
- **Aucune capture, aucun verdict visuel.** Hors mandat.
- **La gaine est « au ras »** — écart max 1,387 m pour une limite de 1,380 m.
  Signalée, non corrigée, et je ne sais pas si elle explique le nouvel argmin
  (flanc droit) : la corrélation est plausible, la mesure n'est pas faite.
- **Le gate d'épaisseur reste `FAIL`**, et rien dans cette passe ne dit qu'il
  est atteignable. Le coordinateur mesure 71 sommets sous 0,80 m et 26 sous
  0,60 m sur la lèvre du porche de la géométrie **livrée et visuellement
  validée** ; cette question appartient au lead.
