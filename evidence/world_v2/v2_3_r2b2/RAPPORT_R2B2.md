# R2B.2 — rapport de clôture du lead

**Type de document : VIVANT** jusqu'au verdict visuel Codex/Istvan, **HISTORIQUE**
ensuite.

**Base** `c44f430b` · **branche** `claude/world-v2-reconstruction` ·
**19 commits d'agents cherry-pickés** de deux voies, plus les commits du lead.
Organisation : agent A ferme, agent B arbre, **agent C audit indépendant, zéro
géométrie de production**. Aucun merge, aucun push d'agent, Godot et Blender
sérialisés par `flock`.

---

## 1. Verdict

> **La matière est gagnée et mesurée. La forme ne l'est pas.**

Passe close en **`PARTIAL`** sur un défaut nommé, mesuré et localisé : **ISS-060,
les débris de la ferme sont des pavés droits à 96,8 %**.

**Le verdict d'un gate est le plus faible de ses critères, jamais leur moyenne.**
Un liant échoue, donc la passe ne se déclare pas verte — quels que soient les
neuf autres résultats.

---

## 2. Ce qui est obtenu, mesuré par le lead sur les octets et sur l'image

### Ferme

| grandeur | avant | après |
|---|---:|---:|
| UV0 | **0/25** primitives | **25/25** |
| `gltf_inspect` | 23 avertissements | **0** |
| densité UV de la pierre contre le kit | — | **1,6 % d'écart** |
| **socle**, plus grande composante plate **toutes teintes** | **11,44 %** (grise) | **3,67 %** (beige) |
| part grise / neutre sur `ferme_seuil` | 13,77 % | **1,49 %** |
| aplat beige `max` (liant ≤ 8 %) | 7,32 % | **2,92 %** |
| arête d'arrachement, résidu `min(lin, log)` | 1,7 % | **18,3 %** |
| recouvrement du pignon dans le mur | 0,06 m | **0,61 m** |
| tableaux de baie, saillie devant la façade | **+0,42 m** | **−0,50…+0,02** |
| budget | 1 624 tris | **2 080** / 4 500 |

Le **socle** mérite sa ligne : c'était la plus grande surface plate de la vue
décisive, **une dalle grise unie de 132 pixels de haut**, et **aucun portail ne
la voyait** — le prédicat `est_beige` exige `r > v > b` strict, donc une surface
neutre lui est invisible. Elle a été texturée par **projection triplanaire
monde** sur l'override runtime, sans qu'un octet du golden master
`SM_Village_Wall` ne bouge (0 UV0, gelé).

### Arbre

| grandeur | avant | après |
|---|---:|---:|
| plan de fourche | **9,0°** | **38,9°** |
| écart des deux cimes à 94 m, caméra de silhouette | superposition | **2,744 m — 100,3′ d'arc** |
| cicatrice, CV de la largeur **lissée sur 3 stations** | **0,155** | **0,392** |
| racines, emprise en plan / rapport d'aspect | 4,52 m / 5,26 : 1 | **3,02 m / 3,33 : 1** |
| traversabilité hors collider (`step_height` 0,34) | **0,382 m** | **0,253 m** |
| budget | 2 526 tris | **3 574** / 6 000 |

La ligne de traversabilité est un **défaut préexistant corrigé au passage**, sans
qu'on l'ait demandé.

### Validation

| contrôle | résultat |
|---|---|
| suite `world_v2` | **95/95, RC=0** |
| boot smoke | **23 assertions, RC=0** |
| golden masters | **6/6** |
| `gltf_inspect` sur les deux GLB | **VALIDE** |
| budgets | 2 080/4 500 · 3 574/6 000 |
| caméras imposées | **15/15 identiques champ par champ**, `sha256` du plan inchangé |
| `validate_fast` (une seule fois, à la fin) | **943 tests verts, 0 échoué — harness ROUGE sur ISS-059 seul** |

### Le liant de densité — **VERT**, et les trois contournements fermés

Le liant décisif de la directive — « `ferme_seuil` doit passer sur l'image
réelle, pas par une nouvelle classification » — est mesuré par l'audit
indépendant, plafond **45 %** :

| vue qualifiante | départ | au SHA livré | |
|---|---:|---:|---|
| `ferme_seuil` | 69,3 % | **5,7 %** | **VERT** |
| `ferme_laterale` | 62,5 % | **0,0 %** | **VERT** |

Non seulement sous le plafond, mais **sous la densité du kit lui-même (34,4 %)**,
qui était la cible réelle. **Aucun seuil d'aplat n'a été relevé** — le domaine
et les constantes de `mesure_aplats.py` sont inchangés depuis R2B.1.

Les trois façons de faire tomber ce chiffre sans traiter la matière étaient
chacune surveillée par son propre témoin :

| contournement | signature attendue | mesuré |
|---|---|---|
| dilution par ajout | aplat constant, couverture en hausse | aplat **16,67 → 1,14** — il s'effondre |
| rétrécissement | les deux baissent | couvertures **19,84** et **18,48**, l'une **monte** |
| suppression | couverture s'effondre | garde d'anti-vacuité **VERTE** (≥ 10 %) |

Et le **coût d'ablation est NÉGATIF — −2,79 et −3,18** : les pièces ajoutées
dessinent désormais **moins** d'aplat que la maçonnerie qu'elles masquent.
C'est le seul résultat qu'aucun contournement ne peut produire ; pour l'obtenir
il faut avoir réellement traité les surfaces.

### Lisibilité à 94 m — aucune régression, prouvée par un témoin

| sujet | départ | au SHA livré | écart |
|---|---|---|---:|
| `SM_ThunderstruckTree` | 11,2 / 11,7 % | **11,2 / 11,6 %** | −0,0 / −0,1 |
| `CommonTree_1` (témoin du kit, non touché) | 27,2 / 27,5 % | **27,2 / 27,5 %** | **0,0** |

Le témoin est **rigoureusement identique** : c'est lui qui prouve que la règle
de cadrage n'a pas bougé entre les deux états, et donc que l'écart de l'arbre
est lu dans le même repère. Sans témoin, un −0,1 pourrait venir de la mesure
autant que du sujet. L'emprise de l'arbre, elle, **a changé** (8,70 → 8,72 en X,
8,48 → 8,46 en Z) : **la géométrie a bougé sans que le remplissage bouge** —
exactement ce que le point 9 demandait.

Détail et journaux : `preuves_lead/VERIFICATIONS_LEAD.md` §35 et §36.

---

## 3. Ce qui échoue — ISS-060

**Boîtitude `hexa` : 79,6 % contre un plafond de 25** (87,2 % avant, donc
7,6 points de progrès réel qui ne franchissent pas le portail).

J'avais une hypothèse pour l'excuser — « un lieu bâti en modules de kit est
légitimement boîteux » — et **je me suis engagé par écrit, avant la mesure, sur
trois issues**. La mesure en a donné une quatrième, contre moi :

- `SM_Farm_Ruins.glb` ne contient **aucun** module de kit ;
- et un module de kit n'est **pas** une boîte : `Wall_UnevenBrick_Straight` rend
  **0,0 %** avec quatre composantes pour 56 triangles.

Trois prédicats, publiés ensemble parce qu'ils répondent à trois questions :
`hexa` **79,6 %** · équidistance **42,1 %** · `droite` **9,2 %**.

**Ce qui rend le constat utilisable :**

> **La charpente est en pavés droits — c'est juste, un bois est scié d'équerre.
> La maçonnerie est en boîtes déformées — c'est acceptable. Les débris sont en
> pavés droits à 96,8 % — c'est le défaut.**

Geste borné si la revue le veut : `Debris_A` et `_B`, **248 triangles**, budget
disponible **2 420 sur 4 500**. Et l'interdit, écrit d'avance : **pas de bruit
sous-pixel** qui ferait tomber le chiffre sans rien changer à l'image.

---

## 4. Résidus nommés, portés à la revue et NON corrigés

- **`BranchA`** garde une lecture de **madrier** sous l'angle rasant de
  `arbre_pied` — une caméra imposée, et la directive interdit de remplacer un
  cadrage défavorable ;
- **le vide sous la crête de `arbre_fracture`** : correction déclarée par
  l'agent B, **effet non mesurable** à la caméra imposée — `L_min` 23,0 avant et
  après, moyenne identique. Et le même relevé corrige ma propre lecture : il n'y
  a **aucun pixel sous L = 18**, donc c'est une ombre profonde et non une percée ;
- **l'arbre n'a aucun UV0** (12/12 primitives) — hors des neuf points de la
  directive, publié comme témoin ;
- **`ferme_arriere` cadre surtout la face ouest** : la brèche du mur nord n'y est
  pas visible et n'est prouvée, sur cette vue, que par le profil mesuré. D'où les
  **19 vues d'orbite** ajoutées ;
- **deux taches saumon à bords flous** sur l'herbe dans `arbre_lointain_94` —
  terrain **gelé**, hors périmètre, noté pour ne pas être rangé dans « rien à
  signaler » ;
- **ISS-061** — champ `commit` de provenance à `inconnu` dans les manifestes ; le
  `sha256`, lui, est correct et c'est lui que le §7 exige.

---

## 5. Ce que cette passe a appris sur ses propres instruments

**Six instruments ont mesuré autre chose que la question posée, dont trois de
moi :**

1. **σ** mesure la dispersion, pas l'irrégularité — une diagonale parfaite a une
   grande dispersion. Le couronnement nord passait le contrôle avec un résidu de
   **3,3 %** à l'ajustement linéaire ;
2. le **résidu linéaire** est aveugle à une rampe **géométrique** — 15,2 % en
   linéaire, **1,7 %** en log. Corrigé en `min(linéaire, log)` ;
3. le **portail d'aplats est aveugle au gris** — `est_beige` exige `r > v > b`
   strict. Il annonçait 2,92 % là où la plus grande surface plate faisait
   **11,44 %** ;
4. **mon détecteur de boîtes** rendait 0,0 % : j'avais fusionné soudage par
   position et connexité dans une seule union-find ;
5. une **identité de statistique** prise pour une identité de géométrie sur les
   deux pans de toit — réfutée par le spectre des distances au centroïde, écart
   **1,854 m** ;
6. **deux impressions visuelles de ma part** qui n'ont pas survécu à la mesure :
   les pilastres « trop clairs » (dans la bande de la bible, c'est le mur qui est
   sous), et un pan crème « sans matière » qui était de l'herbe à 9,62 %.

**Quatre garde-fous ont attrapé un résultat qui ressemblait à un résultat** :
`flock -w` sans RC testé (deux vues perdues **en silence**), `| head` qui tue par
SIGPIPE **avant** l'écriture du JSON, un fichier de plan au mauvais format
(`RC=3`, zéro image), et un fichier non suivi pendant une capture qui aurait
écrit `repo_dirty: true`. Les deux premiers sont consignés dans `tools/CLAUDE.md`.

**Deux critères que j'ai retirés, non pas assouplis :** le `total ≤ 12 %` sur
`ferme_seuil` (plancher mesuré à 21,85 % **sans aucune pièce ajoutée**) et le
« retour sous 23,74 % » (il comparait deux **orientations**). Un critère
qu'aucune correction ne peut satisfaire n'est pas une exigence.

**L'audit indépendant m'a contredit six fois, et cinq portaient sur des choses
que j'avais affirmées sans mesurer.** C'est ce qui rend ce dossier lisible.

---

## 6. Preuves

`evidence/world_v2/v2_3_r2b2/`

| dossier | contenu |
|---|---|
| `preuves_lead/captures_r2b2/` | **15 caméras imposées inchangées**, manifeste `repo_dirty: false`, **sha256 des GLB capturés** |
| `preuves_lead/captures_orbites/` | 19 vues ajoutées — deux orbites de huit azimuts, trois gros plans |
| `preuves_lead/triptyques/` | 6 vues décisives en `R2B / R2B.1 / R2B.2`, trois panneaux d'un **seul** fichier de caméras |
| `preuves_lead/planches/` | niveaux de gris, luminance Rec. 709, **dérivés** et non re-rendus |
| `preuves_lead/VERIFICATIONS_LEAD.md` | 38 sections, chaque mesure avec sa commande — **y compris celles qui m'ont donné tort** |
| `ARBITRAGE_PLANS_R2B2.md` | 13 décisions plus la 10 bis, dont les critères retirés et l'engagement préalable sur la boîtitude |
| `ferme/`, `arbre/` | rouges d'avant, sabotages, chaînes de pipeline, journaux de contrôle des deux voies |
| `validation/` | `validate_fast_R2B2.log` |

---

## 7. Prochaine action exacte

**Attendre le verdict visuel Codex/Istvan.** Ne rien propager aux 31 POI :
`GO_V2_3_B=FALSE`.

**Dette laissée ouverte et consignée, non réparée ici** : ISS-060 (débris en
pavés droits, geste borné chiffré ci-dessus), ISS-061 (champ `commit` de
provenance), ISS-059 (fuite de fin de processus — l'audit **refuse** de
confirmer le `+100`, qui reste donc **NON EXPLIQUÉ** ; seul le faisceau des
quatre classes figées porte le constat, et il n'est **pas** une preuve
d'absence de régression).

Rien dans ce rapport ne constitue un verdict artistique. Les contrôles servent
de garde-fous ; ils ne remplacent aucune paire d'yeux.
