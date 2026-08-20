# ISS-062 — fermeture du contournement par SOUDURE : ajout au filet, sabotage, restauration

Agent « sabotage ISS-062 ». Dépôt `/home/user/Zelda`, branche
`claude/world-v2-reconstruction`, HEAD `291a62198eaddd5cead7929e828839f141ba996f`
plus le travail non commité des agents « rectangularité » et « isolation ».
Godot 4.7.1 (`/usr/local/bin/godot`), rendu logiciel llvmpipe — **aucune mesure
de performance ici, et aucune capture d'image**.

Rien n'est commité ni poussé : les fichiers restent dans l'arbre pour le lead.

---

## Ce que ce rapport prouve, et ce qu'il ne prouve pas

**Prouvé** : le nouveau contrôle voit un contre-exemple que l'ancien portail
laisse passer, et il le voit depuis le filet Godot, pas seulement depuis Python.

**Non prouvé, et ce n'est pas son objet** : que les gravats livrés soient beaux,
conformes à la bible visuelle, ou que le lot R2B.3 soit `PASS`.
`mesure_rectangularite.py` ne mesure QUE la part d'angles droits.

---

## Temps 1 — le contrôle entre dans le filet

Fichier touché : `tests/world_v2/test_world_v2_r2b3_debris.gd`, **et lui seul**.

- Aucun des neuf planchers existants n'a été modifié : ni son seuil, ni son
  code, ni son message. Vérifiable par `git diff`.
- Ajouté : les constantes `RECT_*`, une assertion agrégée sur
  `SM_Farm_Debris_A + SM_Farm_Debris_B`, et une seconde implémentation
  GDScript de `tools/mesure_rectangularite.py` (`_rectangularite`,
  `_simplifier_boucle`, `_angles_interieurs`).
- Seuil : **51**, celui que l'agent rectangularité a justifié dans
  `regle_seuil.md` (horodaté 11:08:02) **avant** de mesurer le sujet (11:10:20).
  Il n'a pas été touché.

### Pourquoi une seconde implémentation plutôt qu'un appel

Un test Godot ne lance pas de processus. Et surtout : si le Python (octets du
GLB, flottants 64 bits) et le GDScript (maillage IMPORTÉ, `Vector3` 32 bits
quantifiés sur l'AABB) rendent le même chiffre, c'est le **prédicat** qui est
vérifié, pas une seule ligne de code. C'est déjà la doctrine du fichier pour le
liant de boîtitude.

---

## Le sabotage : pourquoi CETTE forme et pas une autre

Par tas : **neuf composantes**, chacune faite de **deux pavés droits axés qui ne
se touchent que par un sommet**. Le coin partagé est calculé par la même
expression pour les deux pavés, donc identique bit à bit, donc soudé.

| Instrument | Ce qu'il regarde | Verdict sur le sabotage |
|---|---|---|
| `mesure_boititude.py` | la COMPOSANTE connexe : 12 tris/8 sommets (`hexa`), ou 6 plans/8 coins (`pave6`) | une paire = 24 tris, 15 sommets, 12 plans, 15 coins → **ni l'un ni l'autre → 0,00 %** |
| `mesure_rectangularite.py` | la PLAQUE plane, connexe PAR ARÊTE | les deux pavés ne partagent aucune ARÊTE : chaque face reste un carré isolé → **100 %** |

C'est exactement le contre-exemple décrit par ISS-062, transposé au sujet réel.

---

---

## Temps 1 (suite) — les deux implémentations rendent le MÊME chiffre

Sujet non saboté, `SM_Farm_Ruins.glb` sha256 `ead79105…`.

| grandeur | PYTHON (octets du GLB, float 64) | GDSCRIPT (maillage importé, `Vector3` 32 bits) | écart |
|---|---:|---:|---:|
| **`indice_boite` agrégé** | **0,32 %** | **0,32 %** | **0,00 pt** |
| `part_rectangulaire` agrégée | 0,32 % | 0,32 % | 0,00 pt |
| `part_orthogonale` agrégée | 14,97 % | 15,00 % | 0,03 pt |
| `Debris_A` RECT / ortho | 0,31 % / 15,50 % | 0,31 % / 15,50 % | 0,00 / 0,00 pt |
| `Debris_B` RECT / ortho | 0,32 % / 14,44 % | 0,32 % / 14,50 % | 0,00 / 0,06 pt |
| plaques (A + B) | 353 | 351 | 2 plaques |

**La grandeur qui décide est identique au centième.** L'écart vit sur
`part_orthogonale`, qui ici ne décide rien (le `min` retient la part
rectangulaire), et il vaut **deux plaques sur 353**.

Sa cause est nommée, pas tolérée : l'importeur Godot quantifie les positions sur
l'AABB (`meshes/force_disable_compression=false`), donc deux triangles
coplanaires que le Python sépare d'un cheveu deviennent adjacents après
quantification et fusionnent en une plaque. C'est le même bruit de
quantification que le fichier documente déjà sur `arete_min` — Python
`0,059032`, Godot `0,059027`, soit 5 µm. Il est publié plutôt que caché.

Sources : `01_python_sujet_propre.txt` et `00b_filet_VERT_avant_sabotage.log`.

---

## Temps 2 — le sabotage, les trois sorties côte à côte

`02_SM_Farm_Ruins_SABOTE.glb`, sha256 `7fe0070ee30159724410d193f2a5ce9db686a55e8adb1057f6c0d896cbd7b0ee`.

### a) l'ANCIEN portail ne voit rien — `mesure_boititude.py`, RC **0**

```
*SM_Farm_Debris_A           4     9    216     0.0%     0.0%     0.0%     0.0%   0.89855  0.191548   0.000%
*SM_Farm_Debris_B           4     9    216     0.0%     0.0%     0.0%     0.0%   0.90961  0.192724   0.000%
MESHES RETENUS                         432     0.0%     0.0%     0.0%     0.0%            0.191548   0.000%
OK : liant 0.0% <= plafond 25.0%
RC=0
```

C'est le point du ticket : **0,00 % de liant sur une géométrie qui n'est QUE
des boîtes.**

### b) le NOUVEAU contrôle le voit — `mesure_rectangularite.py`, RC **1**

```
*SM_Farm_Debris_A              4     216      108    100.00%   100.00%     100.00%   0.074879
*SM_Farm_Debris_B              4     216      108    100.00%   100.00%     100.00%   0.075801
MESHES RETENUS                                216    100.00%   100.00%     100.00%
indice_boite = min(RECT, ortho) = 100.00%
ECHEC : indice_boite 100.00% > plafond 51.00%
RC=1
```

### c) le FILET rougit, avec le motif nommé — `test_runner.gd`, RC **1**

```
[r2b3_debris] AGRÉGAT A+B : plaques=216 RECT=100.00% ortho=100.00% indice_boite=100.00% (plafond 51.00%)
  ÉCHEC test_world_v2_r2b3_debris.gd::test_les_gravats_ne_sont_pas_des_paves
  — les gravats de la ferme sont des fragments et non des pavés (1 écart(s))
  — SM_Farm_Debris_A + SM_Farm_Debris_B : indice_boite (rectangularité) = 100.00 %,
    plafond 51.00 % — RECT=100.00 % ortho=100.00 % sur 216 plaques ;
    des BOÎTES DROITES restent des boîtes même SOUDÉES PAR LES COINS, et la
    soudure ne déplace pas cette mesure (ISS-062) — le tas se lit comme une
    bordure construite

=== RÉSULTAT: 1 réussi(s), 1 échoué(s) ===
```

Le GDScript et le Python rendent **100,00 % tous les deux**, sur les deux tas.

---

## Contrôle à VARIABLE UNIQUE — les neuf autres planchers, sous sabotage

Le filet lui-même le dit avant moi : **« 1 écart(s) »**. Un seul critère est
tombé. Détail, relevé dans la trace du run rouge :

| # | plancher | seuil | `Debris_A` | `Debris_B` | verdict |
|---:|---|---|---:|---:|---|
| 1 | LIANT boîtitude | ≤ 25,0 % | 0,0 % | 0,0 % | **PASS** |
| 2 | composantes | ≥ 9 | 9 | 9 | **PASS** |
| 3 | triangles par tas | ≤ 600 | 216 | 216 | **PASS** |
| 4 | aire totale | ≥ 3,20 / 3,35 m² | 8,2211 | 8,3223 | **PASS** |
| 5 | aire médiane de composante | ≥ 0,08 m² | 0,89854 | 0,90960 | **PASS** |
| 6 | aire fine (< 2 mm) | ≤ 1,00 % | 0,0000 % | 0,0000 % | **PASS** |
| 7 | emprise X | ± 20 % | 1,5044 | 1,1803 | **PASS** |
| 8 | emprise Y | ± 30 % | 0,6841 | 0,6883 | **PASS** |
| 9 | emprise Z | ± 20 % | 1,2194 | 0,9543 | **PASS** |
| **10** | **`indice_boite` (rectangularité)** | **≤ 51 %** | **100,00** | **100,00** | **FAIL** |

Les emprises sont **identiques au dix-millième** à celles du run vert : le
sabotage occupe exactement la place du tas d'origine. Et le second test du
fichier — budget de la ferme et UV0 — reste **vert** : 2 264 triangles pour
27 surfaces, contre 2 228 avant.

Prédiction indépendante calculée sur les octets du GLB avant le run :
`07_prediction_planchers.txt`. Elle annonçait les neuf PASS ; le moteur les a
rendus.

---

## Temps 3 — restauration BYTE-IDENTIQUE

```
$ sha256sum assets/architecture/farm/SM_Farm_Ruins.glb
ead79105e3deaf70629c1bd928e68d355261217dbd2d5150384b4a7590cf9060
$ git status --porcelain assets/ | wc -l
0
$ cmp assets/.../SM_Farm_Ruins.glb <copie pristine>
IDENTIQUE (RC=0, 211 852 octets comparés des deux côtés)
```

Trois preuves plutôt qu'une, parce qu'un `git status` vide peut aussi vouloir
dire « rien n'a jamais bougé » : le journal `procedure.log` montre le sha du
saboté **installé** (`7fe0070e…`) entre les deux `ead79105…`, donc le fichier a
bien été remplacé puis remis.

Le réimport a été relancé **après** la restauration (`import RC=0`,
`06_import_apres_restauration.log`) : le cache décrit à nouveau la géométrie
livrée, et non celle du sabotage.

---

## Ce qui reste NON VÉRIFIÉ

1. **L'aspect des gravats.** Aucune image n'a été produite ici. Le rendu
   disponible est llvmpipe, et de toute façon `indice_boite` ne mesure que des
   angles droits. Le verdict visuel d'ISS-060 reste ouvert et appartient au
   lead.
2. **La suite complète.** Seul `--filter=r2b3_debris` a été rejoué. Une
   régression hors de ce filtre lui est invisible par construction
   (`tests/CLAUDE.md`). `tools/validate_fast.sh` n'a pas été lancé.
3. **Le plafond de 51 sur d'autres meshes.** Il n'est appliqué qu'aux deux tas
   nommés. Aucun autre asset du dépôt n'est jugé par ce contrôle, et rien ici ne
   dit ce qu'il rendrait sur eux — le calibrage de l'agent rectangularité couvre
   six témoins, pas le dépôt.
4. **Les autres formes de contournement.** Ce sabotage ferme UNE porte : la
   soudure par coin. Un fragment à neuf sommets qui *ressemble* à une boîte sans
   être rectangulaire passerait les deux instruments. Ni le liant ni la
   rectangularité ne sont suffisants ; ils sont nécessaires.
5. **ISS-062 n'est pas fermé par ce rapport.** Le lead décide. Ce qui est
   démontré est que le filet attrape désormais le contre-exemple exact du
   ticket.

---

## Annexe — le filet REJOUÉ après restauration, et il est vert

`08_filet_VERT_restaure.log`, RC **0** :

```
[r2b3_debris] AGRÉGAT A+B : plaques=351 RECT=0.32% ortho=15.00% indice_boite=0.32% (plafond 51.00%)
  ok   test_les_gravats_ne_sont_pas_des_paves (1 assertions)
  ok   test_le_budget_tient_et_toute_primitive_porte_ses_uv (1 assertions)
=== RÉSULTAT: 2 réussi(s), 0 échoué(s) ===
```

Ligne par ligne **identique** au run vert d'avant sabotage
(`00b_filet_VERT_avant_sabotage.log`) : mêmes 12 composantes, mêmes
198 triangles, mêmes 351 plaques, mêmes emprises. Le passage par le sabotage
n'a rien laissé derrière lui, ni dans le fichier ni dans le cache d'import.

Séquence complète des trois temps, dans l'ordre où elle a eu lieu :

| journal | fichier jugé | RC |
|---|---|---:|
| `00b_filet_VERT_avant_sabotage.log` | `ead79105…` | 0 |
| `04_import_sabote.log` | `7fe0070e…` installé et réimporté | 0 |
| `05_filet_ROUGE_sabote.log` | `7fe0070e…` | **1** |
| `06_import_apres_restauration.log` | `ead79105…` remis et réimporté | 0 |
| `08_filet_VERT_restaure.log` | `ead79105…` | 0 |
