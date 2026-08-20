# Vérification adverse R2B.3 — ce qui tient, ce qui ne tient pas

Vérificateur adverse, 2026-08-20. Dépôt `/home/user/Zelda`, branche
`claude/world-v2-reconstruction`, HEAD `ebcd782` (le brief annonçait `291a6219` ;
le dépôt a avancé de quatre commits depuis). Godot 4.7.1, llvmpipe.
Lecture seule : aucun fichier de production, aucun `.glb`, aucun test, aucun
générateur modifié. Scripts jetables sous `/tmp`.

---

## BLOQUANT — le contrôle de rectangularité se contourne à 2 mm

`tools/mesure_rectangularite.py` ferme le contournement par SOUDURE. Il ne ferme
pas le contournement par BRUIT COHÉRENT, et les deux se combinent.

**Le contre-exemple.** Je pars du GLB déjà saboté (dix-huit pavés droits axés par
tas, soudés par les coins) et je déplace chaque **position unique** de ≤ 2 mm.
Le bruit est appliqué par position et non par sommet : les coins soudés le
restent, donc le nombre de composantes ne bouge pas et l'ancien portail reste
aveugle. Mais les faces cessent d'être planes à mieux que `RECT_COPLAN_DIST`
(1 mm), donc chaque face se scinde en triangles, donc `part_rectangulaire`
s'effondre.

```
$ python3 /tmp/contre_exemple.py .../02_SM_Farm_Ruins_SABOTE.glb /tmp/CE_0.002.glb 0.002
$ python3 tools/mesure_rectangularite.py /tmp/CE_0.002.glb \
      --mesh SM_Farm_Debris_A --mesh SM_Farm_Debris_B --plafond 51
  indice_boite = min(RECT, ortho) = 38.80%
  OK : indice_boite 38.80% <= plafond 51.00%        RC=0
$ python3 tools/mesure_boititude.py /tmp/CE_0.002.glb \
      --mesh SM_Farm_Debris_A --mesh SM_Farm_Debris_B --plafond 25
  OK : liant 0.0% <= plafond 25.0%                  RC=0
```

Les dix contrôles sont verts sur une géométrie qui n'est QUE des boîtes :

| # | plancher | exigé | contre-exemple 2 mm |
|---:|---|---|---|
| 1 | liant (boîtitude) | ≤ 25 % | **0,0 %** |
| 2 | composantes | ≥ 9 | **9** / **9** |
| 3 | triangles | ≤ 600 | **216** / **216** |
| 4 | aire totale | ≥ 3,20 / 3,35 m² | **8,2184** / **8,3186** |
| 5 | aire médiane | ≥ 0,08 m² | **0,899** / **0,911** |
| 6 | aire fine < 2 mm | ≤ 1,00 % | **0,000 %** |
| 7-9 | emprise X/Y/Z | ± 20 / 30 % | **+0,15 / +0,42 / +0,20 %** |
| 10 | `indice_boite` | ≤ 51 % | **38,80 %** |

Le bruit vaut 2 mm sur des arêtes de 189 mm (`arete_min` = 0,189 m), soit 1,06 %.
Il ne se voit pas. La falaise est nette : à 1 mm le contrôle mord encore
(56,55 %, RC 1), à 2 mm il ne mord plus. **La marge de l'instrument contre le
bruit est d'un millimètre.**

Cause exacte : `min(RECT, ortho)`. Sur le contre-exemple `ortho` reste à
**100,00 %** — les dièdres sont toujours droits, l'objet est toujours fait de
boîtes — et c'est `RECT`, seule grandeur sensible à la planéité, que le `min`
retient. Le `min` était justifié par le cylindre (rect 66,86 / ortho 20,70) ;
c'est exactement lui que le contournement exploite.

**L'agent avait la mesure et ne l'a pas dite.**
`iss062/limite_bruitage.txt`, dernière ligne du second tableau :

```
coins soudes exacts, jitter 20 mm      2.77%    92.72%     2.77% |      0.00%  (composantes=1)
```

indice 2,77 % et boîtitude 0,00 % : les deux portails aveugles, sur la même page.
Ce fichier n'a ni en-tête, ni commande, ni script producteur, et n'est cité que
par une ligne de `README.md` (« ce que le bruitage fait aux deux mesures »). Rien
dans `RAPPORT_SABOTAGE.md`, rien dans la section « CE QUE L'INSTRUMENT NE MESURE
PAS » de l'outil, rien dans le commentaire du seuil `RECT_PLAFOND_PCT`.

**Ce qui changerait.** Un second plafond, **indépendant**, sur `part_orthogonale`.
En appliquant la règle pré-écrite de l'agent à cette grandeur :
`M_ortho`(nature/débris) = 4,80 → `floor((4,80 + 100)/2)` = **52**. Vérifié sur
tout le corpus que j'ai rejoué : attrape le contre-exemple (100,00), le sabotage
(100,00) et le sujet AVANT (71,73) ; laisse passer les six témoins (max 15,68) et
le sujet APRÈS (14,97). Coût : une constante et une assertion.

---

## À CORRIGER

### 1. La suite `world_v2` n'a jamais tourné sur l'arbre livré

```
02_world_v2.log                          mtime 11:50:41   (99 réussis, 0 échoué)
tests/world_v2/test_world_v2_r2b3_debris.gd  mtime 12:11:42
```

Le 99/0 décrit un arbre **sans** la dixième assertion. Seul un run ciblé
`--filter=r2b3_debris` (2 tests, `00b`/`08`) a exercé le nouveau contrôle. Les
~310 lignes de GDScript ajoutées n'ont jamais été vues par la suite complète.

### 2. « Seuil écrit avant mesure » : la chaîne de preuve se contredit — mais le chiffre tient

L'ordre n'est appuyé que par des `mtime`, et ils ne concordent pas avec le texte :

- `regle_seuil.md` (11:08:02) dit être écrit « après l'autotest (15/15) ». Le seul
  artefact d'autotest, `autotest_rectangularite.txt`, est horodaté **11:11:26**,
  trois minutes plus tard.
- `tools/mesure_rectangularite.py` a été **modifié à 11:11:26**, donc après les
  témoins (11:08:29) et après le sujet (11:10:20) qu'il a produits.

J'ai donc tout rejoué avec l'outil livré :

```
$ python3 tools/mesure_rectangularite.py <chaque témoin>
  RubbleLarge 0,00 | RubbleSmall 0,00 | Tree 2,66 | Bridge 6,46 | Wall 4,53 | Pylon 15,68
$ ... SM_Farm_Ruins_c44f430b.glb --plafond 51   ->  71.42 %  RC=1
$ ... assets/.../SM_Farm_Ruins.glb  --plafond 51   ->   0.32 %  RC=0
$ ... --mesh SM_Inexistant                        ->  BLOQUÉ   RC=2
$ python3 tools/mesure_rectangularite.py --autotest -> 15 cas, 15 OK, RC=0
```

Tout reproduit au centième. Et surtout le verdict est **insensible à l'ordre** :
avec n'importe quel `M` réellement observé (0 → 15,68), la formule rend un
plafond dans [50, 57] ; AVANT (71,42) échoue et APRÈS (0,32) passe sous chacun.
La revendication de procédure est `PARTIAL` ; le chiffre est `PASS`.

### 3. `tools/lancer_godot.sh` n'est utilisé par rien

```
$ grep -rn 'lancer_godot' evidence/ tools/ docs/ | grep -v 'tools/lancer_godot'
(aucune sortie)
```

L'enveloppe est correcte et son autotest est bon — il porte un vrai contrôle
négatif (`user://` partagé → la seconde sonde voit 2 marqueurs, RC 0). Mais les
trois autres agents ont chacun réimplémenté l'isolation à la main
(`XDG_DATA_HOME` + `flock` + `timeout`), en trois variantes. **Aucune mesure
livrée ne passe par l'enveloppe.** Elle est donc `NON VÉRIFIÉE` en usage réel.

### 4. Le plancher A/A est nul, mais cinq vues sur onze ne portent aucun signal

`LISEZMOI_ablation.md` écrit : « il n'y a aucune vue où le signal soit du même
ordre que lui ». C'est faux sur trois vues, où le signal **est** le plancher :

| vue | signal gravats |
|---|---:|
| `ferme_arriere`, `ferme_orb270`, `ferme_seuil` | **0 px — 0,00 %** |
| `ferme_orb000`, `ferme_orb180` | 205 / 204 px — **0,02 %** |

Rien n'est dit vue par vue. Or cela **répond** à la question laissée ouverte par
`LECTURE_VISUELLE_LEAD.md` (« la bordure construite venait-elle de l'anneau ? ») :
sur les vues d'orbite les deux tas pèsent 0 à 0,02 % du cadre, donc le verdict
« bordure construite » pris à cette distance ne peut pas porter sur eux. Les deux
documents sont dans le même dossier et personne ne les a reliés.

### 5. Bissection : une ligne du tableau « Éliminé » n'est pas éliminée

La ligne « les matériaux fuités sont des sous-ressources de scène » s'appuie sur
le rapport matériaux/maillages **115,5** (suite complète à `ea93460`) contre
**1,31** (sonde à HEAD). Deux SHA différents et deux périmètres différents. Or le
§0 du même rapport pose que `d195c58` — précisément le correctif ISS-059 qui
retient les `PackedScene` — sépare les deux, et que c'est « la limite
d'attribution de tout ce qui suit ». La conclusion ferme du §4 contredit la
réserve du §0. Cette réduction de domaine oriente la prochaine passe vers
129 sites de création à l'exécution : elle doit être rangée en **plausible**, pas
en **éliminé**. Le reste de la bissection est solide — chaque bloc a son témoin
(T1, T2, C1–C3 emboîtés), les trois hypothèses sont falsifiées par une mesure, et
les deux points non tranchés sont marqués `NON VÉRIFIÉ` / `BLOQUÉ`.

---

## DÉTAIL

- Aucun **plafond** d'aire n'existe sur les tas, seulement un plancher. Le
  contre-exemple double l'aire (8,22 contre 4,07 m²) sans qu'un contrôle bronche.
  Degré de liberté ouvert, non exploité ici pour tricher.
- `limite_bruitage.txt` est le seul fichier de la passe ISS-062 sans en-tête ni
  commande de reproduction.

---

## CE QUE J'AI VÉRIFIÉ ET QUI TIENT — `PASS`

- **Gel non régressé.** `SM_ThunderstruckTree.glb` = `c44f9c1e…` ✓ ;
  `SM_Farm_Ruins.glb` = `ead79105…` ✓ (sha256 recalculés par moi).
- **Restauration byte-identique** après sabotage : hash attendu, et
  `diff 00b_filet_VERT_avant_sabotage.log 08_filet_VERT_restaure.log` vide.
- **Le sabotage mord pour la bonne raison.** Seul `test_les_gravats_ne_sont_pas_des_paves`
  tombe, avec un message nommant la rectangularité ; `test_le_budget_tient…` reste
  vert. Variable unique. Les neuf autres planchers verts, prédits **puis** mesurés.
- **L'ancien portail est réellement aveugle** : `mesure_boititude.py` sur le
  saboté rend `liant 0.0 %`, **RC 0** — rejoué par moi.
- **Le plancher A/A est un vrai A/A** : les onze paires sont identiques au md5, et
  les `mtime` des deux fichiers d'une paire diffèrent de 458 ms — deux rendus, pas
  une copie. 0 px aux seuils 1, 8 et 32.
- **Un mesh inconnu BLOQUE** (RC 2) au lieu de rendre un vert sur ensemble vide.
- **Suites rejouées** : la distinction contamination / vrai défaut est réellement
  faite, avec un mécanisme nommé pour chacune (`slot0` relu ; coffre de
  l'antichambre à `1 arme + 8 flèches` avant ouverture). Le troisième échec est
  classé `NON VÉRIFIÉ` et non « contamination ». Le résidu `boss_arena` est
  publié comme **rouge**, pas absorbé.
- **Manifestes de capture** : `5de2750d` et `da454207` existent et sont ancêtres
  de HEAD ; `repo_dirty: false`.

---

## CE QUE JE N'AI PAS PU VÉRIFIER

1. **Le contre-exemple n'est pas passé au filet Godot.** Le dixième contrôle vit
   en GDScript et lit un chemin de production figé ; l'exercer imposerait de
   remplacer le `.glb` ou de modifier le test, tous deux interdits par ma
   consigne. Le verdict Python est certain (RC 0) ; l'équivalence Python↔GDScript
   est établie par l'agent à 0,00 pt sur la grandeur qui décide, donc le vert est
   prévisible — **mais non mesuré**. `NON VÉRIFIÉ`.
2. **Je n'ai rejoué aucune suite Godot** (791 s pour `world_v2`) ni aucune
   capture. Je me suis appuyé sur les journaux et sur leurs contrôles anti-piège
   (`filtre:` présent, une seule ligne `=== RÉSULTAT`, journal non vide sur RC non
   nul), que j'ai lus un par un. Les verdicts de suite restent ceux des agents.
3. **« Vent gelé sur 3 matériaux »** n'est pas audité en tant que compte. Le
   plancher A/A à 0 px rend la question sans objet pour cette mesure-ci, mais rien
   ne prouve que trois soit le compte complet des feuillages de WorldV2.
4. **ISS-059** : je n'ai pris aucune mesure : j'ai audité le raisonnement et ses
   témoins. Le `+100` reste non expliqué, comme le dit le rapport.

---

## Reproduire le contre-exemple

Le script jetable est `/tmp/contre_exemple.py` (non versé au dépôt). Il lit un
GLB, regroupe les positions **uniques** des deux tas, applique à chacune un
déplacement borné déterministe (sha256 de la position), réécrit les accesseurs et
leurs `min`/`max`. Trois amplitudes mesurées :

| amplitude | `indice_boite` | RC rect | liant | RC boîtitude |
|---:|---:|---:|---:|---:|
| 1 mm | 56,55 % | **1** | 0,0 % | 0 |
| **2 mm** | **38,80 %** | **0** | **0,0 %** | **0** |
| 3 mm | 28,94 % | **0** | 0,0 % | 0 |
