# V2.3-B lot 1 — CONSTATS de la voie C

**VIVANT** tant que le lot 1 n'est pas clos. Fichier propre à la voie C : le
lead y puise ce qu'il intègre dans `STATUS`, `PROGRESS` et `KNOWN_ISSUES`, que
cette voie ne touche pas.

## 1. Ce qui a été livré

| livrable | fichier | état |
|---|---|---|
| les huit contrôles, pré-enregistrés | `docs/V2_3_B_LOT1_CONTROLES.md` | committé AVANT toute mesure |
| le filet D1..D8 + deux témoins analytiques | `tests/world_v2/test_world_v2_lot1_defauts.gd` | écrit ROUGE d'abord |
| le détecteur de répétition D3 | `tools/lot1_repetition.py` | `--autotest` vert |
| le compteur de budget | `tools/godot/sonde_budget_lot1.gd` | écrit |
| le plan de captures | `docs/V2_3_B_LOT1_PLAN_CAPTURES.md`, `tools/godot/plan_captures_lot1.gd`, `tools/capture_lot1.sh` | écrit |
| le contrôle négatif | `tools/gate_negatif_lot1.sh` | écrit, deux modes |
| la provenance | `tools/lot1_provenance.py` | exécuté, voir §3 |

## 2. Deux mesures que les filets existants prennent sur la mauvaise propriété

Ce ne sont pas des reproches : ce sont des trous que le lot 1 aurait franchis
sans bruit. Les deux sont de la famille d'ISS-018 — mesurer une propriété qui
n'est pas celle qu'on veut garantir.

1. **`probe_place_metrics.gd` compte les `StaticBody3D` et les nomme
   « colls ».** Un corps unique peut porter trente `CollisionShape3D`. Un
   micro-POI au budget « 6 collisions » avec 1 corps et 30 formes passerait, et
   le chiffre imprimé dirait « 1 ». `sonde_budget_lot1.gd` compte les formes.
2. **`test_world_v2_places_contract.gd` calcule l'emprise d'un lieu sur les
   `MeshInstance3D`.** Un `MultiMeshInstance3D` lui est invisible : sur un champ
   de fleurs bâti en semis — la forme attendue de `flower_field.01` — il
   conclurait « aucun maillage visuel », c'est-à-dire un ÉCART, sur un lieu
   parfaitement correct. Le filet du lot lit les `VisualInstance3D`.

Le second est le plus gênant des deux : il ne laisse pas passer un défaut, il en
**invente un**. À signaler à la voie qui construit `flower_field.01`.

## 3. Un asset GELÉ sans ligne au manifeste — trouvé par `lot1_provenance.py`

Reproductible :

```bash
python3 - <<'PY'
import importlib.util
spec = importlib.util.spec_from_file_location("prov", "tools/lot1_provenance.py")
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
m.LOT1 = ["valley.poi.waterfall_cave.01"]
raise SystemExit(m.main())
PY
```

Résultat : `assets/environment/caves/SM_WaterfallCave_r2a358.glb` est
**référencé par `WaterfallCavePlace`**, **gelé** (ligne 5 de
`docs/contrats/gel_v2_3_b.sha256`), et **absent de
`docs/assets/ASSET_MANIFEST.csv`** — seul `SM_WaterfallCave` y figure
(ligne 180).

Ce n'est pas un défaut du lot 1 et la voie C n'y touche pas. C'est un constat à
arbitrer par le lead : soit le `.glb` `_r2a358` est une variante à inscrire,
soit c'est un résidu que le gel a figé par inadvertance. Dans les deux cas, la
règle `.claude/rules/assets.md` — « tout asset entre au manifeste AVANT le
build » — n'est pas tenue sur ce fichier.

## 3bis. Un critère à moi était FAUX, mesuré avant livraison

La première version du contrôle D5 cherchait les deux coordonnées du site
n'importe où dans le fichier du lieu. Rejouée sur les **neuf lieux acceptés**,
elle en accusait **trois** — `camp` (45, 65), `stone_bridge` (-10, 22),
`ember_raider_camps` (96, 120). Des entiers ronds trop banals pour qu'une
double présence signifie quoi que ce soit.

Corrigée : on cherche la FORME du défaut — `Vector3(x, *, z)`, une affectation
`position.x =`, ou l'origine d'un `Transform3D` de scène. Nouvelle mesure :
**0 faux positif sur 9**, scripts et scènes confondus, et les quatre formes du
défaut sont vues.

Journal :
`evidence/world_v2/v2_3_b/lot1/controles/D5_calibration_faux_positifs_20260821.md`.

Ce paragraphe est ici plutôt que caché parce que c'est le mode de panne que ce
lot doit apprendre à voir : le critère avait l'air raisonnable, il ne l'était
pas, et seule la mesure sur un corpus dont on connaît la réponse l'a montré.

## 3ter. Le détecteur D3 sait rougir sur des images

Contrôle négatif de bout en bout sur silhouettes synthétiques : six sujets
« acceptés » de formes franchement différentes calibrent le seuil, un sujet
« du lot » est la **copie pixel pour pixel** d'un accepté.

Résultat : la copie est signalée aux trois distances (`IoU = 1,0000`,
`dprofil = 0,0000`) contre des seuils calibrés de 0,718 / 0,690 / 0,682 ; le
témoin dégénéré est signalé aux trois distances ; le verdict final est `BLOQUÉ`
parce que quatre sujets du lot n'ont pas de silhouette — le comportement voulu.

Journal et détail :
`evidence/world_v2/v2_3_b/lot1/controles/README.md`.

## 4. Le seuil de répétition : la règle, avant les nombres

Écrite dans `docs/V2_3_B_LOT1_CONTROLES.md` §3.4 et committée le 2026-08-21,
avant qu'aucune silhouette n'ait été capturée :

> **R-D3.** Le seuil `S(d)` est le maximum d'IoU observé entre deux sujets
> DISTINCTS du **corpus accepté** (les neuf lieux déjà validés), à cette
> distance, tous angles confondus. Une paire du lot 1 est signalée si son IoU
> dépasse `S(d)`.

Deux garde-fous, écrits en même temps : **R-D3b**, calibration invalide et
verdict `BLOQUÉ` si `S(d) ≥ 0,90` ; **R-D3c**, `BLOQUÉ` sous 6 sujets acceptés.
Plus un **témoin dégénéré** — un sujet comparé à lui-même doit être signalé,
sinon le verdict est jeté.

`S(d)` n'a pas encore de valeur : il se calcule à la capture. **Aucune valeur
n'est annoncée ici, et aucune ne doit l'être avant que la chaîne ait tourné.**

## 5. Ce qui reste `NON VÉRIFIÉ`, et pourquoi

| élément | état | raison |
|---|---|---|
| D1..D7 sur les six sujets | `NON VÉRIFIÉ` | les six lieux n'existent pas ; le filet les nomme absents |
| `AIRE_RUNTIME_PLAFOND_PCT` (D1a) | `NON CALIBRÉ` | vaut `-1.0` ; le filet ROUGIT en le disant plutôt que de laisser croire à un plafond |
| `S(d)` du détecteur D3 | `NON MESURÉ` | exige les silhouettes du corpus accepté |
| sabotages D1..D8 mode `--lot1` | `BLOQUÉ` | cibles non construites ; le script sort en 3 et le dit |
| toute performance | hors périmètre | Xvfb + llvmpipe : régression visuelle seulement |
| toute jouabilité | hors périmètre | ni écran, ni manette : `docs/MANUAL_VALIDATION.md` |

## 6. Ce que le lead doit relancer après la livraison des voies A et B

```bash
# 1. calibrer le plafond D1a sur le corpus DÉJÀ accepté, puis l'inscrire
tools/lancer_godot.sh --headless --path . \
  --script tools/godot/sonde_budget_lot1.gd -- --calibrer

# 2. le filet des huit défauts
tools/lancer_godot.sh --headless --path . \
  --script tools/godot/test_runner.gd -- --filter=lot1_defauts

# 3. le contrôle négatif, mode réel — un sabotage par famille
tools/gate_negatif_lot1.sh --lot1

# 4. la chaîne de preuve, depuis un arbre COMMITTÉ
tools/capture_lot1.sh --out-dir=evidence/world_v2/v2_3_b/lot1

# 5. la provenance
python3 tools/lot1_provenance.py
```
