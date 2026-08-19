# R2a-3.5.8 — agent C : provenance, baseline visuelle, correctif caméra

Statut : relevé de session du 2026-08-18, arbre `/home/user/zelda-r2a358/c_provenance`
au HEAD `52ce1b5`, **rien commité, rien poussé**. Tout chiffre de ce document est
mesuré dans cette session (journaux `mesures/`, jeton `RC=` en fin de chaque log),
sauf mention explicite « corroboration ».

---

## 1. Correctif caméra au HEAD — `PASS`

Parcours réel Boot → Menu → « Nouvelle partie » → WorldV2, rejoué par
`test_boot_smoke.gd` via le runner, import d'abord (worktree neuf sans `.godot/`),
sous `flock` (logs `00a`/`00b`, `RC=0` aux deux étapes).

- `1 réussi(s), 0 échoué(s)` — **23 assertions vertes**, 0 erreur de script.
- Scène active `WorldV2` ; joueur présent, posé, vivant, **réactif** (soulevé de
  3 m il retombe ; une intention le déplace de > 1 m).
- **Caméra active = celle du rig joueur, par égalité d'identité**
  (`get_viewport().get_camera_3d() == rig.get_camera()`) — ce qui exclut
  `DiagnosticCamera` par construction. Mécanisme du correctif `0b0ef54` vérifié
  dans `world_v2_root.gd` : `activate_gameplay_camera()` reprend la main après
  montage (la caméra de preuve reste dans la scène pour l'outillage, plus jamais
  la vue) ; `push_error` en échec — journal à zéro erreur.
- HUD `GameplayShell` monté ; **64 chunks** ; **9 lieux** ; spawn `(0.0, 24.4, 170.0)`.
- Le monde se monte **deux fois** dans le log : c'est B9 (mort → panneau →
  « Réessayer » → rechargement) — la reprise repasse aussi par la reconquête caméra.
- Hors couloir, non bloquant, non instruit : avertissements navigation
  préexistants (2 puis 38 « edge errors ») à chaque montage.

---

## 2. Provenance du candidat — table des couches

Socle 3.5.7 confirmé (une seule greffe `531cdd8` + `MASSIF` ; le générateur à
`531cdd8` hache `09fcc4a5…` et il est **byte-identique** à celui du HEAD
d'`a_epaisseur` — la couche T-jonction se lit donc directement sur `531cdd8`).

| # | Couche | Fichier | Lignes | sha256 (16) | Base d'application prouvée |
|---|---|---|---|---|---|
| 0 | fermeture+calotte+joue droite | commit `531cdd8` (générateur `09fcc4a5…`) | — | — | ancêtre du HEAD d'`a_epaisseur` |
| 1 | T-jonction (générateur) | `provenance/t_jonction_generateur.patch` (extrait du diff NON COMMITÉ d'`a_epaisseur`) | 209 (patch) ; +175/−1 sur le fichier | `35a70e53…` | `531cdd8` : RC=0, résultat == arbre `a_epaisseur` (`24fb636c…`) |
| 1b | T-jonction (addendum doc) | `provenance/t_jonction_addendum.patch` | 127 (patch) ; +116 sur le doc | `80132060…` | même diff |
| 1c | T-jonction (binaires) | GLB `3a80ae71…` (1 488 532 o) → `40714c46…` (1 488 700 o) ; `.blend` `5464f457…` → `14532726…` | — | — | figé par hash ; règle 3.5.7 : le `.blend` livré vient de l'export |
| 2 | massif + lissage | `r2a357_agentA/massif_lissage.patch` | 442 | `5b9d4734…` ✓ directive | `531cdd8` nu : **6/6 hunks RC=0** (contre-vérifié, identique au relevé 3.5.7) |
| 3 | intersections v2 (retrait d'alcôve à l'échelle `CAVITE_ASYM`) | `r2a357_agentA/r2a357_agentA_intersections.patch` | 148 | `86b01ece…` | état `MASSIF`-seul (couche 2 appliquée) : **4/4 hunks RC=0** |
| 4 | **fusion (arbitrage checkpoint 2, `80814a6`)** — **VÉRIFIÉE §2c** | générateur fusionné pré-correctif de l'agent A | — | `102cc33d3836d07fdb0b13951b3fa780187dc5388fafb43aa34bf8e05f0f4bb5` (`cce3da51` caduc) | reconstruit indépendamment ET byte-identique : S1 + massif{1,2,5,6} + `86b01ece` |
| 5 | delta de passe collider (it.1 agent A) | `r2a358_agentA/r2a358_agentA_collider.patch` | 259 | `750151d5…` | `102cc33d` + delta == `28535fb3f48d80c6546d76d7c42c8af4f3c7053b8ee444170c75b5ed0fddc3af` (arbre `a_collider`), vérifié aller ET retour |

### `027b80e4…` — verdict : SUPERSÉDÉ, perdu comme fichier

Le LISEZMOI d'agent A (3.5.7) annonce `027b80e4…` (136 lignes, 4 hunks) pour
`r2a357_agentA_intersections.patch`, mais le fichier sur disque hache `86b01ece…`
(148 lignes) — réécrit au même chemin à 12:03, APRÈS la table du LISEZMOI. Le
répertoire est **non suivi par git** (`??`) : pas d'historique. Recherche bornée
faite : les `.patch` de **cinq arbres + tronc** hachés (37 sur tronc/integration/
c_instruments + balayage a_epaisseur/b_chaine/essai_pile/reference) — **aucun ne
hache `027b80e4`**. Relevés de session du lead : v1 = retrait d'alcôve (16→4) ;
`86b01ece` = même correctif **à l'échelle de l'asymétrie** (4 pénétrations,
repli 0,2434 m), autonome sur la même base, qui le REMPLACE. Verdict de
provenance : *supersédé, décrit dans les preuves 3.5.7, corroboré par le lead* —
pas un blocage, et pas un `PASS` de conformité.

### CONSTAT (BLOQUANT à la découverte, TRANCHÉ au checkpoint 2) : les couches 1 et 2 sont en CONFLIT

L'ordre annoncé (`531cdd8` + T-jonction + massif + intersections) **ne s'applique
pas mécaniquement**, et aucune permutation brute ne passe (logs `provenance/
chaine_*.log`, rejet conservé) :

| Ordre essayé | Résultat |
|---|---|
| T-jonction → massif | massif hunk #3 **FAILED** (RC=1) |
| massif → intersections v2 → T-jonction | T-jonction hunk #3 **FAILED** (RC=1) |
| massif → T-jonction | T-jonction hunk #3 **FAILED** (RC=1) |
| massif → intersections v2 (sans T-jonction) | RC=0 / RC=0 — état `M2` sain, sha `0d5f564a…` |
| T-jonction seule | RC=0 — état `S1` == arbre `a_epaisseur`, sha `24fb636c…` |

Cause, lue dans les hunks : les deux couches réécrivent **la même ligne** de
`soustraire()` (le `print` « nettoyage de la soustraction ») et portent deux
traitements **sémantiquement voisins** des n-gones colinéaires — T-jonction :
`_a_bord_colineaire` + `_resorber_faces_plates` + triangulation ciblée ;
massif : `_desamorcer_ngones_colineaires` (117 lignes). La fusion des deux est
une **décision de contenu** (redondance ? complémentarité ? ordre d'exécution
dans la fonction ?) qui appartient au couloir d'intégration/lead, pas au mien.
Conséquence déjà mesurable : le GLB baseline `40714c46` a été produit par
l'état `S1` — **sans** massif ni intersections v2.

### §2b — Arbitrage rendu (checkpoint 2, commit `80814a6`) et procédure de vérification

Décision du lead : dans `soustraire()`, **la version T-jonction gagne verbatim** ;
le hunk concurrent de `massif_lissage` est exclu, appel ET définition de
`_desamorcer_ngones_colineaires`. Fondement cité : (1) seul traitement vérifié
sur un GLB réellement exporté, prédictions tenues ; (2) le fait mesuré ici —
`COL_` identique de part et d'autre de la T-jonction — prouve que la décision
ne change rien aux déterminants des 4 intersections ; (3) un mécanisme, pas
deux (même règle que le retrait d'`_orient_exact`).

**Références de ce que la fusion doit produire**, épinglées dans `provenance/` :

| État | Fichier | sha256 (16) |
|---|---|---|
| S1 = `531cdd8` + T-jonction | `etat_S1_531cdd8_plus_tjonction.py` | `24fb636c6033c6f8` |
| M2 = `531cdd8` + massif + intersections v2 | `etat_M2_massif_plus_intersections_v2.py` | `0d5f564a8ff35fdd` |

**À réception du hash ré-épinglé de l'it.0 de l'agent A** (son `cce3da51` est
caduc — il incluait l'insertion manuelle) :

1. extraire `soustraire()` du générateur fusionné et de S1 — exigence :
   **byte-identiques** ;
2. `diff` du reste du fichier contre M2 — exigence : identique hors la région
   arbitrée (aucun appel ni définition de `_desamorcer_ngones_colineaires`
   ne doit subsister) ;
3. re-consigner le sha256 complet du générateur fusionné dans cette table.

### §2c — Verdicts rendus le 2026-08-18 (logs `mesures/07` à `09`)

**Verdict 1 — conformité du générateur fusionné : `PASS`** (log `07`)

1. `102cc33d` reconstruit par application INVERSE du delta sur l'arbre
   `a_collider` (RC=0), hash complet conforme à l'annonce ; contrôle aller
   `PRE + delta == FINAL` : identiques.
2. §2b-1 : `soustraire()` de `102cc33d` **byte-identique** à celui de S1
   (66 lignes, sha `97ee5b3c…`).
3. §2b-2 : `_desamorcer_ngones_colineaires` — **0 occurrence** dans
   `102cc33d` ET dans `28535fb3`.
4. Plus fort que §2b-3 : reconstruction **indépendante** de l'état prescrit —
   S1 + `massif_lissage` hunks {1,2,5,6} + `86b01ece` — **byte-identique à
   `102cc33d`**. La fusion est exactement la stratification arbitrée, rien
   d'autre, prouvé sans rien reprendre de la construction de l'agent A.

**Verdict 2 — identité visuelle du GLB final : `PASS`** (log `08`)

GLB final `5ff4ec6e…` (1 488 700 o, arbre `a_collider`) mesuré avec MON outil :
`sha256_geom(SM) = e6a4bdb0471b6281…` — **byte-identique à la baseline
`40714c46`** ; `COL = 98034206db67e6c9…` ≠ baseline `eb26d38e…` (le collider a
changé, c'était le but). Boucle fermée à trois instruments : session 3.5.7,
outil du lead (`dd3ea5c6` des deux côtés), le mien (`e6a4bdb0` des deux côtés).

**Invariant croisé — multiset COL : `CONFORME`, reproduit** (log `09`)

Entre le COL de l'état 3.5.7 (`b_chaine`, GLB `d0d72a15…`) et le final :
**exactement 9 positions soudées disparues / 9 apparues sur 442**, toutes en
queue. Bande MESURÉE ici : `ay [5,275 ; 7,142]` — le « 5,3–7,0 » du lead en est
l'arrondi à une décimale (le max réel des apparues, 7,142, déborde son 7,0).

---

## 3. Baseline visuelle `40714c46` — re-mesurée, mesuré-contre-mesuré

Nouvel instrument : `tools/cave_sha256_geom.py` (non commité, en-tête documenté :
sha256 des POSITION float32 + indices canonisés u32, par nœud, primitives dans
l'ordre glTF ; ne hache ni normales, ni UV, ni matériaux, ni noms).

| Grandeur | Cité (directive/3.5.7) | Re-mesuré ici | Log |
|---|---|---|---|
| topologie SM (soudée) | V=10037 E=30105 F=20070 | **V=10037 E=30105 F=20070**, 1 composante, 0 bord libre, 0 non-manifold, genre 0 | `02` |
| aire totale SM | 842,188236 m² | **842,188236 m²** | `04` |
| volume SM | 798,8 m³ | **+798,812 m³**, normales sortantes | `05` (contrat coque complet : timeout à 480 s, RC=124 — seule la ligne volume est citée) |
| AABB (repère GLB) | — | min `[-8.7717, -3.5509, -11.8987]` max `[8.1739, 8.1923, 3.2305]`, dims `[16.9456, 11.7432, 15.1292]` | `03` |
| composition 3/3/3, ratios 2,23/2,37/2,25 | cités | **différé** — exigent les silhouettes capturées (`capture_silhouette.gd` puis `measure_silhouette_masses.py --entaille=0.90`) : phase captures, arbre committé | — |

### Hashes de géométrie par nœud — CIBLE DU GATE « visuel inchangé »

| État | outil session 3.5.7 | outil lead (2026-08-18) | **mon outil** (`cave_sha256_geom.py`) |
|---|---|---|---|
| SM pré-T-jonction (`3a80ae71`, et builds `b_chaine`) | `f51919de…` | (idem, cité) | `8ec0d74c7c9a3138…` |
| **SM baseline `40714c46`** | — | `dd3ea5c6bf9cee3b` | **`e6a4bdb0471b628138692cd8871d97f395ce123ade4bcf5bc49892d3508c91d0`** |
| COL baseline `40714c46` | — | `f17852ba628a8dc6` (= collider pré-`MASSIF` de `b_chaine`, mesuré par le lead) | `eb26d38edf163462…` |
| COL pré-T-jonction `3a80ae71` | — | — | `eb26d38edf163462…` — **identique** |
| **SM GLB FINAL `5ff4ec6e`** | — | `dd3ea5c6…` (== baseline) | **`e6a4bdb0…` == baseline — GATE VISUEL TENU** |
| COL GLB final `5ff4ec6e` | — | — | `98034206db67e6c9…` ≠ baseline (attendu) |

Trois outillages aux sérialisations différentes, **une seule structure** : la
T-jonction change SM (+7 sommets — 5 n-gones retriangulés) et ne touche PAS le
collider. Le verdict du gate sur le GLB final de l'agent A se rend avec **mon
outil des deux côtés** : attendu `sha256_geom(SM) == e6a4bdb0…` (fichier entier
différent, COL différent). Ne JAMAIS comparer une valeur de mon outil à une
valeur d'un autre : sérialisations distinctes, écart garanti des deux côtés.

---

## 4. Captures — manifeste re-dérivé, captures différées

`shots_r2a358.json` : **15 vues, 0 caméra murée** (contrôle par fonction d'appui
sur l'AABB monde de la baseline, marge 1 m ; vues intérieures hors contrôle,
marquées). Dérivation intégrale dans `deriver_cameras_r2a358.py` : chaîne de
repère origine monde `(-106, 3.5, 3.5)` + lacet 45° (contrôle d'axe sud-est
levant), ancres du dépôt (`waterfall_cave_place.gd`), zéro nombre à la main.
7 vues nommées (intentions R2a-3.1) + **4 vues A/B reprenant à l'identique les
caméras R2a-3.4** (`tranche4_final/manifest.json`, commit `55c4803c`,
dirty=false) + 4 tournette cardinales. Silhouettes 55°/100°/225° référencées
vers `manifest_silhouettes_grotte_r2a34.json`.

Non faisable ici, dit d'avance : les captures elles-mêmes (arbre committé exigé,
règle `evidence.md`) ; la vue « collider seul » n'existera que comme **tracé
d'instrument hors moteur** (autorisé par le lead, jamais présenté comme capture) ;
llvmpipe = régression géométrique/composition seulement, aucune mesure.

## 5. `NON VÉRIFIÉ`

L'export Blender du GLB final — non rejoué par moi (preuves d'export : evidence de l'agent A) ·
l'effet du delta 259 l sur les 4 pénétrations — couloir collision, pas le mien ·
composition/ratios/silhouettes de la baseline — différés avec les captures ·
`96_aire_final` exact-Fraction non rejoué (mon aire vient de
`cave_check_closure.py`, flottants, même valeur à 6 décimales) · le contrat
coque complet (`cave_check_hull.py`) au-delà de la ligne volume — timeout.
