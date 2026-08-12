# Tranche verticale d'ouverture — preuves du 2026-08-11

**HISTORIQUE.** Ce dossier est daté ; il décrit un état, pas une intention. La
source de vérité vivante reste `docs/STATUS.md`.

Branche de session : `claude/new-session-840w2o`
Commit de départ (après remise à niveau sur la branche auditée) : `6a996a5`
Moteur : Godot **4.7.1-stable** officiel (`a13da4feb`), Blender 4.0.2
Rendu des captures : `xvfb` + **llvmpipe logiciel**, 1920×1080, 40 frames

> Ce conteneur n'a ni GPU, ni écran, ni clavier, ni manette, ni audio. Les
> captures servent la **régression visuelle** ; aucune n'est une mesure de
> performance, et aucun contrôle manuel de §21.4 n'a pu être exécuté.

---

## 1. Écart avec le prompt de reprise, à lire en premier

Le prompt annonce la branche `claude/vertical-slice-opening-polish` au commit
`c8fc1ab048a48fe8eeb214195a09ec1e012d4ac9`.

- Ce SHA **n'existe dans aucune référence du dépôt distant**. Ses quatre
  commits locaux ont visiblement été réécrits avant d'être poussés : la branche
  distante porte le même travail sous d'autres SHA, jusqu'à `b0fe61c`.
- La branche de cette session, `claude/new-session-840w2o`, était **13 commits
  en arrière** de cette branche. Y travailler aurait reproduit le dégât du
  2026-08-07 décrit dans `docs/COMMENT_TRAVAILLER_ENSEMBLE.md` §1 — des
  branches divergentes dont aucune ne contient tout le travail.

`origin/claude/vertical-slice-opening-polish` a donc été fusionnée
**localement** dans la branche de session (commit `6a996a5`) avant tout
travail. Aucun push, aucune fusion distante, aucun force-push. Le diff de cette
fusion est purement additif : aucun fichier supprimé.

---

## 2. Le tableau demandé : problème → preuve → cause → correction → test

| # | Problème | Preuve | Cause réelle | Correction | Test | Résultat |
|---|---|---|---|---|---|---|
| 1 | Le sol de la vallée rend **plus clair que son ciel** ; les trois plans de §1.3 tiennent dans 1,9 point de valeur | `tools/check_value_bands.py` sort en **code 1** sur 5 des 6 caméras de gate ; `avant/*_gris.png` | Couleurs PEINTES de §3.4 posées telles quelles en ALBÉDO, sans tenir compte d'un gain lumineux de 1,4 à 1,8 (rechute d'ISS-037) | Lot A : moyennes descendues, écarts internes ÉLARGIS, récession peinte dans la couleur | `check_value_bands.py` + `make_review_pack.py` sur les six caméras | **4 caméras sur 6 conformes** (voir §3) |
| 2 | La rampe processionnelle de la citadelle est un **tapis vert** sur une falaise brune, sur **55,5 %** du cadre | `probe_frame_masses.gd` ; repeinture magenta puis recapture | La passe de peinture exemptait les sols par une LISTE DE NOMS citant douze dalles et **aucune rampe** | Lot B.0 : exemption par GROUPE, posé par `_slab()` et `_ramp()` eux-mêmes | `test_ground_carriers_keep_their_material.gd` — contrôle négatif : **16 assertions rougissent** sans le correctif | pierre rendue `221,176,126` au lieu de `140,218,82` |
| 3 | Trois boîtes occupent **71 %** du cadre de la route du nord | `probe_frame_masses.gd` : bordure 36,8 %, plateau 22,7 %, rampe 12,0 % | Face sud du plateau = dalle nue ; ses 14 contreforts passaient `(largeur, profondeur)` **inversés** et ne couvraient que la moitié de la face | Lot B : falaise à trois rangs recouvrants ; jupes de bordure 17 au lieu de 13, plus hautes ; crêtes 20 au lieu de 14, recouvrantes | 110 tests vallée/terrain/bordure/silhouettes + parcours physique | plus de mur plein sur les caméras 5 et 6 |
| 4 | `prop.tent` et `prop.campfire` pointent vers des **scènes absentes** ; les tentes sont des cônes | `AssetRegistry.CATALOG` ; `scenes/environment/` | Assets réservés depuis ART-Q0, jamais livrés, et **jamais consommés** : la terrasse posait des `PrismMesh` | Lot D : `AwningTent` et `CampfireProp`, originaux, construits par script ; le camp les monte | `test_asset_pipeline.gd` corrigé (il pinglait l'ABSENCE), `test_valley_dressing.gd` inchangé | aucun repli boîte au camp |
| 5 | La colonne de fumée est un **pilier opaque de 40 m** | `apres/03_camp.png` d'une passe intermédiaire | La peinture repeignait un matériau à alpha 0,22 en CUTOUT opaque ; elle refusait les émissifs, pas les translucides | `PainterlyRecipe.is_translucent()` | contraste mesuré depuis la crête | voile traversé par les montagnes |
| 6 | …mais le voile devient **invisible** depuis la crête | contraste colonne/voisinage : **+22,6 → +1,6** | Un gris 0,58 à 22 % sur des falaises grises ne se découpe pas | Lot D bis : teinte 0,87, alpha 0,34 | même mesure | **+39,7** — meilleur qu'avant, et translucide |

---

## 3. Les six caméras, avant et après

`VALLEY_GATE=1..6`, déclarées côté jeu dans `ValleyWorld.GATE_CAMERA_NAMES`.
Rejouables par `tools/capture_vslice_gate.sh --out-dir=…`.

| caméra | écart haut/milieu | sol p95 vs ciel p50 | §1.5 |
|---|---|---|---|
| `01_crete_vista` | 2,1 → **5,3** | 74/70 → **57/69** | VIOLATION → **conforme** |
| `02_descente` | 0,6 → **0,3** | 90/46 → **68/24** | VIOLATION → **VIOLATION** |
| `03_camp` | 0,0 → **18,7** | 94/82 → **68/76** | VIOLATION → **conforme** |
| `04_gue` | 14,0 → **26,7** | 96/92 → **78/92** | VIOLATION → **conforme** |
| `05_route_nord` | 12,3 → **13,0** | 54/60 → **47/57** | conforme → **conforme** |
| `06_approche_citadelle` | 45,2 → **52,9** | 99/94 → **100/95** | VIOLATION → **VIOLATION** |

**Limite de cette mesure, à ne pas maquiller.** `check_value_bands.py` est
calibré sur le cadrage North Star : ciel dans les 30 % du haut, sol dans les
22 % du bas. Les caméras 2 et 6 ne montrent **pas de ciel** dans leur bandeau
haut — la descente regarde vers le bas, l'approche regarde une falaise. Leur
verdict `VIOLATION` ne dit donc rien d'utile, ni avant ni après ; il est
reporté tel quel plutôt que retiré, parce que retirer une mesure qui dérange
est précisément ce que ce dossier doit rendre impossible.

Chaque capture est accompagnée de son manifeste `.json` (commit, moteur,
renderer, taille, frames, `repo_dirty`), de sa vignette `320×180`, de son
niveau de gris et de son relevé `_revue.json`.

---

## 3 bis. Deuxième passe (étapes 1 à 8 du prompt de continuation)

Après le gel du §3, la session a continué : suite ramenée au VERT (823/0 —
les 8 échecs étaient l'entrelacement de DEUX runners concurrents, verrou
ajouté), caméra de descente désenterrée (elle vivait 5 m SOUS la crête,
test-sonde sur les six caméras), citadelle (étape 4 : terrasses en troncs de
pyramide, arcade percée, brèche, courtines déviées), chemins (étape 5 :
tronçons chevauchants plaqués au sol, épaulements, pierres), camp réévalué
(étape 6), talus des deux dernières mesas SANS toucher la paroi d'escalade
(étape 7). Chaque geste : test rouge d'abord quand vérifiable machine.

**Jeu final : `final/`** (v2, après corrections 6-7 du propriétaire) — les
six caméras, mêmes réglages, arbre committé. Mesures : §1.5 conforme sur
**5 caméras sur 6** (la 6 n'a pas de ciel dans son bandeau mesuré — verdict
non pertinent, reporté tel quel) ; écarts haut/milieu : 5,4 / **36,4** /
20,6 / 26,9 / 13,0 / 52,8. Corrections appliquées : verrou `flock` atomique
(contrôles négatif ET positif exécutés), vides placés là où les caméras
regardent (porche profond, baies du Keep, mur percé détaché, arche rompue),
chemin en ensemble (terre 78 % → 62 % de valeur, langues d'herbe, grappes
de pierres), matrice scindée visible/backlog.

Traçabilité : `AUDIT_TRACEABILITY.csv` (87 constats : 3 PROUVÉ, 2 CORRIGÉ,
20 À TRAITER, 3 BLOQUÉ, 59 REPORTÉ AU BACKLOG) et `AUDIT_FILES_USED.md`.
Révision demandée par le propriétaire : un constat dont la MANIFESTATION est
visible depuis le parcours des dix minutes ne peut pas être reporté d'office —
V-004 (relief du parcours → lots C/E), V-007 (coques dans les cadres → E),
V-012 (vie du camp → D) et les douze lieux du parcours sont SCINDÉS : part
visible « À TRAITER » dans son lot, refonte du lieu entier au backlog.

Nom canonique du projet : **Zelda / Éclats d'Orage** — « Zelada » est une
faute historique de l'audit source, non propagée ici.

## 4. Ce qui reste ROUGE, et que je ne prétends pas avoir traité

Le gate de sortie de la tranche verticale **ÉCHOUE**. Points du prompt §9 qui
sont encore vrais sur le chemin de démonstration :

1. **La citadelle** a désormais terrasses talutées, arcade, brèche et
   courtines (étape 4) — mais le Keep et les tours restent des boîtes à
   collision axées monde, et le verdict d'image appartient à Codex.
2. **Le terrain reste plat** : 96,8 % des 1 024 sondages de l'audit sont sous
   5° de pente et 79,6 % tombent sur deux dalles. Rien dans cette session n'a
   touché le relief — c'était le risque le plus élevé et le moins réversible.
3. **Les chemins** sont désormais des chaînes de tronçons plaqués au sol
   (étape 5) — il reste leur clarté en plein soleil et la transition
   terre/herbe encore géométrique.
4. **Les mesas orange du plan moyen** et la monture en primitives restent des
   volumes cubiques visibles depuis la crête.
5. **Le camp n'est pas composé** en triangle repos/cuisine/garde ; il a des
   assets finaux, pas encore une organisation.
6. **Options/Commandes déborde toujours à 720p** (775 px demandés) et la
   mention « Manette prise en charge » reste plus forte que la preuve. Lot F
   non fait.
7. **Score North Star : NON VÉRIFIÉ.** Aucun évaluateur indépendant n'a noté
   ces captures ; je ne m'attribue aucune note.
8. **Les trois joueurs boîte noire : NON VÉRIFIÉ.** `tools/blackbox_player/`
   n'a pas été lancé dans cette session.
9. **Caméra, son, manette, fluidité, 60 minutes de stabilité : NON VÉRIFIÉ**,
   et non vérifiables ici (§ limites connues de `CLAUDE.md`).

---

## 5. Comment rejouer

```bash
export GODOT_BIN=/usr/local/bin/godot            # binaire officiel 4.7.1-stable
tools/capture_vslice_gate.sh --out-dir=/tmp/verif # les six caméras + mesures
godot --headless --path . --script tools/godot/probe_frame_masses.gd -- \
    --camera=GateCamera_Citadel --limit=15        # ce qui domine un cadre
tools/validate_fast.sh                            # suite complète (~25 min)
```
