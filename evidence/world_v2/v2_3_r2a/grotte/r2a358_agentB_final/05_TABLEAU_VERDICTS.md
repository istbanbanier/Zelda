# R2a-3.5.8 agent B — VERDICTS FINAUX sur le GLB de l'agent A

Sujet : `final/SM_WaterfallCave_agentA.glb`, sha256 fichier `5ff4ec6ee7a5bb6f…`
(1 488 700 octets), relevé AVANT toute mesure. Géométrie : `SM_` `dd3ea5c6…`
**bit-identique à la baseline** ; `COL_` `e322e4b5…` (modifié, comme voulu).
Gardes : tables `CAVITE` provenance A (`28535fb3…`) == instruments == référence
figée `86b01ece` (`5e09940e…`) ; formule d'alcôve vérifiée mot pour mot dans la
source d'A ; atlas `it1` **442/442** positions retrouvées dans le GLB (le
périmé `correctif_v1` échoue 18/442 — la garde du plan l'écartait seule).
Journaux : `final/00…04`, tous `RC=`.

## Tableau des critères

| # | critère | mesure | taille de l'examiné | verdict |
|---|---|---|---|---|
| T1a | chemin canonique COURBE (polyligne, longueur d'arc), contrat 1,75 m, r=0,45 | **0 échantillon sous contrat**, hauteurs 2,10–2,53 m, aller ET retour | 2×14 échantillons, 5,52 m, 880 tris | **PASS** |
| T1b | idem r=0,35 | 0 sous contrat | idem | **PASS** |
| T1c | témoin corde (doit différer) | 11 sous contrat, pire 0,667 m, aucun occupable | 2×13 échantillons, 4,93 m | **PASS** (discriminant : 11 ≠ 0) |
| T2a | capsule 3D exacte, stations 1/3/5/7, COL et SM, 2 rayons, atlas it1 | st1 −0,0002 · st3 −0,0003 (tangence, ≤ tolérance 0,0075) ; st5 **−0,0216 = artefact de pente** (identique sur les 2 maillages, α≈18°, 4e occurrence du piège du plancher, documenté) ; st7 étroit sur les DEUX | 4 st × 2 r × 2 maillages ; erreur ≤ 0,0025 m | **PASS** (verdict porté par T2b) |
| T2b | capsule en BANDE aux quatre lieux + ancre de niche, 2 rayons, 2 maillages | **st1 0,7013/+0,2513 · st3 1,2001/+0,7501 · st5 0,5713/+0,1213 — au chiffre près le relevé 3.5.7** ; niche-axe et ancre : étroit contre les DEUX maillages (fond/tablette, pas une paroi invisible) | 5 lieux × 2 × 2 ; erreur ~1e-9 m | **PASS** (r=0,45 et 0,35 partout où SM passe) |
| T3a | champ paroi invisible, marge figée 86b01ece, seuil 0,061 (plancher 0,010 + étalonnage 0,051) | pire excès **+0,0503** (= le max d'étalonnage, même adresse côté D non touchée par le correctif) → sous le seuil | 43 200 rayons, 37 501 doubles touches, 80 échantillons, détectabilité 0,153 m | **PASS** |
| T3b | fonctionnel : capsule bloquée par COL_ dans du vide SM_ | nulle part | marche canonique + salle→niche, pas 0,10 m | **PASS** |
| T3c | atteinte de la niche | capsule tient jusqu'à **0,569 m** de l'ancre (contrat interaction 1,8–2,4 m) — identique au rodage | 17 échantillons | **PASS** |
| T3d | jauge de poche, plancher lead 0,524 | ventre : diff SM−COL 1,2932 → **ampl_col estimé 0,5828 ≥ 0,524** ; vers l'ancre : 1,1814 (bord de fenêtre, F≈0, attendu) | 2 directions, plan y=sol+0,50 | **PASS — mais lire la note 1** |
| — | Δsol (sol invisible) | ≤ 0,005 m partout | 80 échantillons | **PASS** (télémétrie) |
| — | écarts négatifs (COL derrière SM) / impacts uniques | 517 (rodage : 565) / 1 401 (1 360) | rayons du champ | publié **non jugé** — couloir collision / préexistant |

**Verdict du couloir traversabilité : PASS** (le plus faible des critères, pas
leur moyenne).

## Note 1 — le PASS de poche est au fil du couteau, et il faut le dire

Marge au plancher : **+0,0588 m, de l'ordre de l'erreur annoncée (~0,06)**.
La leçon 3.5.7 (« un verdict qui se joue à moins que l'erreur ne s'arrondit
pas ») impose deux appuis supplémentaires, et ils existent :

1. **La valeur de conception de la révision mesurée EST le plancher** :
   `ampl_alcove = 1,20 − 0,40×1,69 = 0,524`, formule vérifiée mot pour mot
   dans la source d'A par la garde (RC=3 sinon). Le critère est tenu par
   construction ; ma mesure (0,583) est compatible avec la conception à
   +0,059.
2. **L'hypothèse concurrente est exclue loin de l'erreur** : l'état refusé
   (retrait 0,50 → poche 0,355) lirait ≈0,41 ; l'écart mesuré 0,583−0,355 =
   0,228 ≈ **4× l'erreur**. La jauge distingue donc bien l'état livré de
   l'état refusé.

## Note 2 — découverte : « jauge ≥ rodage » n'est PAS vérifié, et c'est explicable

Attendu du lead : jauge de poche ≥ rodage. Mesuré : **0,583 contre 1,065**
(ventre), d_COL 4,0315 → **3,5490** (le mur de collision s'est AVANCÉ de
0,48 m dans le vide de la poche par rapport à mon rodage). Explication : mon
rodage était **PRÉ-correctif** (poussée d'alcôve pleine, 1,20, des deux
côtés) ; le correctif 86b01ece réduit l'amplitude de collision à 0,524 **par
conception** — c'est le prix arbitré du zéro pénétration. La direction « le
collider recule hors du vide » vaut pour les 9 positions de queue d'A
(vers l'ancre : d_COL 2,1739 → 2,1704, quasi inchangé ; écarts négatifs
565 → 517, cohérents avec l'enfouissement de l'enveloppe), pas pour la poche,
que le correctif RÉTRÉCIT délibérément. Le joueur perd 0,48 m de profondeur
de poche en collision par rapport à l'état pré-correctif — chiffre publié
pour l'intégration, pas un blocage : le champ reste sous la marge figée et
l'atteinte de la niche est inchangée.

## Corroborations croisées

* T2b reproduit **au chiffre près** le relevé 3.5.7 (log 23) sur st1/st3/st5 —
  deux chaînes de calcul distinctes, même résultat : la peau de cavité est
  bien celle de la pile 86b01ece.
* Positions soudées `COL_` : 269/442 diffèrent de mon rodage pré-MASSIF
  (pile entière), dont 23 en bande de queue — le « 9/442 » d'A se rapporte à
  SA base (86b01ece), pas à la mienne ; les deux comptes ne se contredisent
  pas (`final/04`).
* Les instruments ont prouvé leur capacité à rougir : contrôles négatifs
  (a)(b)(c)(d), tous rouges AU BON ENDROIT puis verts après restauration
  bit-prouvée (`negatif/`, T4 du LISEZMOI).

## NON VÉRIFIÉ

Comportement en moteur (aucun Godot ici — le filet `world_v2_places` réel n'a
pas été rejoué dans Godot) · terrain gelé (autre corps ; 1 401 impacts
uniques au porche en témoignent) · les 6 pénétrations propres du `SM_` à
0,000612 m : préexistantes, jugées non réelles par le critère du projet en
3.5.7 — hors de mon couloir, non re-jugées ici.
