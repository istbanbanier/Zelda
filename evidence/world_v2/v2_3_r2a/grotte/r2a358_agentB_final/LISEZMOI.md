# R2a-3.5.8 — agent B — traversabilité en instruments indépendants

Couloir : la traversabilité, rien d'autre. Aucune géométrie de production
modifiée. Base : tronc `52ce1b5`. **Rodage + contrôles négatifs exécutés sur
`40714c46` (pré-MASSIF)** — par consigne du lead, ce GLB sert au rodage
d'instruments et aux contrôles négatifs ; les tableaux T1–T3 FINAUX ne valent
que sur le GLB de l'agent A, non livré à la clôture de ce journal.

## Le candidat mesuré (rodage)

`SM_WaterfallCave_candidat.glb` — sha256 fichier `40714c46544e27d2…`,
géométrie par maillage : `COL_` `f17852ba628a8dc6…`, `SM_` `dd3ea5c6bf9cee3b…`
(`rodage/00_empreintes_et_garde_tables.log`). Copie en lecture seule ; les
sabotages ont opéré sur des copies détruites après usage, hash aux journaux.

## Instruments

| instrument | provenance | sha256 | rôle |
|---|---|---|---|
| `tools/cave_gabarit_marche.py` | b_chaine 3.5.7, repris TEL QUEL | `4f9a6ff537d8dc42…` | T1 : chemin canonique COURBE (longueur d'arc) + témoin corde |
| `tools/cave_largeur_seuil.py` | b_chaine 3.5.7, repris TEL QUEL | `574b95a997756550…` | T2 : capsule exacte aux stations d'axe |
| `tools/cave_epaisseur_col.py` | b_chaine 3.5.7 (dépendance) | `3d32873c0b9ba268…` | `dist_point_triangle` |
| `tools/cave_exact_intersect.py` | tronc | (suivi git) | prédicats exacts, contrôle (a) |
| `tools/cave_paroi_invisible.py` | **NOUVEAU** (l'unique contrôle du budget) | `a9f1a6fb9fbe407d…` (v4d figée) | champ SM/COL même rayon, capsule bande, marche salle→niche, jauge de poche |
| `fixture/saboter_glb.py` | fixture (mécanisme de `cave_fix_sabotage.py` tronc, généralisé) | `823e4758c30e0a88…` | sabotages des contrôles négatifs — pas un instrument |

**Garde de tables** : `CAVITE` de la provenance du GLB mesuré == copies en dur
des instruments == référence figée, vérifiée avant toute mesure, RC=3 sinon
(`rodage/00`). Le piège est réel : la table du tronc `52ce1b5` DIFFÈRE.

## La référence de marge FIGÉE (arbitrage lead, consigne corrigée)

`reference/make_waterfall_cave_86b01ece.py`, sha256 `5e09940e23f1632c…`,
RECONSTRUITE depuis f39b232 + `massif_lissage.patch` (5b9d4734…) + patch
intersections (86b01ece…) et prouvée identique au bit près à l'arbre b_chaine.
Modèle exact lu dans son code :

    recul COL derrière SM = ML·asym·w + min(AMPL, ML·asym)·F   (fenêtre alcôve)
    marge_prévue (borne)  = ML·asym·(1+AMP) [+ min(AMPL, ML·asym) dans la fenêtre]

ML=0,40 · AMP=0,085 (somme des coefficients de `bruit()` = 1,00 exactement) ·
AMPL=1,20 · fenêtre stations 5–7, ±52°. L'outil exige `--sha-reference` et
rend BLOQUÉ si la référence bouge, si la formule d'alcôve n'y est pas mot pour
mot, ou si les tables divergent.

## Ce que le rodage a coûté — et payé UNE fois

1. **Quatrième occurrence du piège du plancher.** `ajustement_capsule` (3D)
   rend `r·(cos α − 1)` sur un sol en pente : −0,0216 m IDENTIQUE sur COL et
   SM (sols identiques par conception), α ≈ 18°. Le critère juste est la
   LARGEUR DE BANDE du journal 23 de 3.5.7 — un sol de pente s n'entre dans la
   bande qu'à r/s > r tant que s < 1. Écrit au-dessus de la fonction.
2. **Ni le rayon, ni la normale ne mesurent une profondeur.** v1 : rayon
   quasi axial → compare virage et fond. v2 : rayon normal → court parallèle
   au mur SM dans les coins (+4,9 m pour une marge de 0,13). v3 : la
   profondeur est la DISTANCE 2D impact→surface SM la plus proche.
3. **La marge est locale à l'IMPACT, pas à l'échantillon** : un rayon parti de
   u=2 touche à u=6 où la marge vaut 0,676, pas 0,25 (faux excès +0,43).
4. **Étalonnage** : sur l'état de référence, excès résiduel max +0,0503 m =
   flèche de rééchantillonnage (anneaux 20 vs 56 sommets) + plans de coupe.
   Borne publiée : `--borne-etalonnage 0.051` (`rodage/06`). Le cas à voir
   (poche 0,355 au lieu de 0,524 : excès ~+0,17) reste ~3× au-dessus.
5. **Jauge de poche** : v1 muette (fenêtre < bande de référence), v3 polluée
   par la forme de la salle. v4 : différentiel SM−COL dans la direction de la
   poche — l'algèbre même du plafond du lead (`ampl_col = 1,20 − retrait·asym`
   → 0,524 à retrait 0,40 ; 0,355 à 0,50). Rodage : 1,065 (ventre) / 1,185
   (vers l'ancre) pour 1,20 attendu (poussée pleine pré-correctif) — dans
   l'erreur annoncée (~0,06 ; F<1 au plan de coupe).
6. **v4c/v4d payées aux contrôles négatifs** : verdict de poche sur le MIN
   des directions (un mur vers l'ancre passait vert) ; marqueur fonctionnel
   borné au contrat (il flambait sur le porche, hors contrat).

**Limite assumée, écrite dans l'outil** : dans la fenêtre d'alcôve, le CHAMP
est aveugle PAR CONSTRUCTION (la marge figée y admet ~1,41 m — le recul
légitime de 86b01ece). C'est la JAUGE DE POCHE qui police la niche.

## Rodage (RODAGE-PRE-MASSIF — aucun verdict de gate)

* **T1** (`rodage/07`) : chemin canonique COL_, r=0,45 et 0,35 — **zéro
  échantillon sous le contrat 1,75 m** (2,10–2,53 m de hauteur libre).
  Témoin corde : **11** sous contrat, pire 0,667 m — l'instrument
  DISCRIMINE ; le « 7/8 = défaut de sonde » tient aussi sur ce GLB.
* **T2** (`rodage/01`) : capsule exacte st1/st3 : jeu −0,0002/−0,0003
  (tangence, PASSE). st5 : −0,0216 = artefact de pente (piège n°1), corrigé
  par la bande : jeuB st5 (t=5,00) = **+0,165**, salle occupable. st7 axe :
  étroit contre les DEUX maillages (fond), pas une paroi invisible.
* **Champ final** (`rodage/08`, v4b) : **RC=0** — aucun excès au-delà de
  0,061 ; capsule jamais bloquée par COL_ dans du vide SM_ ; poche 1,07 ;
  atteinte de la niche 0,569 m (contrat interaction 1,8–2,4) ; Δsol ≤ 0,005.
  43 200 rayons, 37 542 doubles touches, 565 écarts négatifs (couloir
  collision, publiés non jugés), 1 360 impacts uniques (bouche/saillie
  extérieure : préexistant, publié non jugé).

## T4 — les quatre contrôles négatifs

| # | sabotage (mesuré, pas affirmé) | rouge attendu | rouge obtenu | localisation |
|---|---|---|---|---|
| (a) | 220 sommets `COL_` du coude poussés −1,5 m hors de l'axe (`SM_` INCHANGÉ au bit près) | pénétrations cav×env nouvelles | 62 → **101** | **+39, toutes** dans la boîte du sabotage (19→58 ; r 3,6 m) |
| (b) | 119 sommets du flanc de niche tirés +1,0 m vers l'axe (d_COL vers l'ancre : 2,174 → **0,020**) | jauge de poche < 0,524 | `ampl_col estimé = −0,969` → **RC=1** | direction « vers l'ancre » — celle du sabotage ; baseline intacte re-testée VERTE |
| (c) | 80 sommets du seuil tirés +0,4 m vers l'axe (largeur st1 : 0,450→0,277) | capsule NE PASSE PAS à st1 ; fonctionnel au seuil | `jeu st1 −0,1728` (r=0,45), **RC=1** ; champ 18 pts, fonctionnel 4 pts t=1,20–1,50 | st1 seulement — st3 intacte (−0,0003) ; poche intacte verte |
| (d) | restauration | VERT + hash | fichier `40714c46…` ; géo COL/SM == étape 00 ; capsule PASSE ; champ RC=0 ; **positions des 62 pénétrations identiques à la baseline (diff vide)** | — |

Détails : `negatif/`. Chaque sabotage publie sommets vus/bougés, |d|max,
sha256 par maillage avant/après ; `SM_` est resté identique au bit près dans
(a)(b)(c). Première tentative de (a) ÉCHOUÉE et consignée (84 sommets bougés,
zéro pénétration nouvelle — la sélection avait pris la voûte, pas les
flancs) : le contrôle a refusé son propre rouge, c'est sa raison d'être.
Fixture déterministe : sha du sabotage (c) reproduit à l'identique
(`negatif/c6`).

## Ce qui attend le GLB de l'agent A (tableaux finaux)

1. Garde de tables sur SA provenance (`--provenance-glb`, RC=3 si divergence).
2. T1 : `cave_gabarit_marche --chemin canonique` + témoin corde, r=0,45/0,35.
3. T2 : capsule bande aux quatre lieux × 2 rayons × 2 maillages.
4. T3 : champ complet `--borne-etalonnage 0.051 --plancher-poche 0.524`
   (le plancher de poche est l'arbitrage du lead ; ma jauge est son
   contre-pouvoir : je publie ma mesure même si son relevé dit l'inverse).
5. Saillie extérieure préexistante : publiée « préexistant », jamais jugée.

## NON VÉRIFIÉ

Tout verdict de traversabilité sur le GLB de l'agent A (pas livré) · le
comportement en moteur (aucun Godot ici) · le terrain gelé (autre corps,
invisible à ces instruments — les impacts uniques du porche en témoignent) ·
la valeur d'étalonnage 0,051 sur une géométrie dont le rééchantillonnage
changerait (SEGMENTS_COL ≠ 20 → ré-étalonner, le journal `rodage/06` dit
comment).

---

## MISE À JOUR — verdicts finaux rendus

Le GLB de l'agent A (`5ff4ec6e…`) est mesuré : voir **`final/05_TABLEAU_VERDICTS.md`**
(un verdict par critère, tailles d'examiné, notes sur le fil du couteau de la
jauge de poche et sur la découverte « poche < rodage, par conception »).
Journaux `final/00` à `04`. **Verdict du couloir : PASS**, plus faible des
critères. La section « Ce qui attend le GLB de l'agent A » ci-dessus est
soldée.
