# ISS-059 — ce qui reste après correctif, énuméré sur la SUITE COMPLÈTE

Passe R2B.3.1, 2026-08-20. `tools/godot/test_runner.gd` en `--verbose`, suite
entière, une exécution. **949 tests réussis, 0 échoué**, RC 0.

Le vidage `--verbose` pèse **138 Mo** ; il est ignoré par git
(`.gitignore`). Ce fichier est sa décomposition, et c'est ce qui vaut d'être
conservé. Reproduire :

```bash
tools/lancer_godot.sh --attente=7200 --headless --path . --verbose \
  --script tools/godot/test_runner.gd > /tmp/verbose.log 2>&1
grep -oP '(?<=Leaked instance: )[A-Za-z0-9_]+' /tmp/verbose.log | sort | uniq -c
grep -oP '(?<=Resource still in use: )\S+' /tmp/verbose.log | sed 's/.*\.//' | sort | uniq -c
```

---

## 1. La décomposition tombe juste, au dernier objet

| ligne du rapport de sortie | compte | décomposition mesurée |
|---|---:|---|
| `ObjectDB instances were leaked` | **138** | 74 `GDScript` + 61 `GDScriptNativeClass` + 3 `Shader` = **138** |
| `resources still in use` | **74** | 71 `.gd` + 3 `.gdshader` = **74** |
| `RID allocations 'DummyShader'` | **3** | les 3 `Shader` ci-dessus = **3** |

**Aucun reste.** Pas un matériau, pas un maillage, pas une texture, pas un flux
audio. Les trois classes de RID qui portaient ISS-059 — `DummyMaterial` (281),
`DummyMesh` (214), `DummyTexture` (67) — ne sont plus imprimées du tout.

Le flux audio `land_soft.wav` observé sur la sonde isolée (ISS-064) **n'apparaît
pas** ici : il appartient au chemin de la sonde, pas au harnais.

---

## 2. La cause, et pourquoi elle n'est pas la nôtre

**Charger une `.tscn` épingle les `GDScript` qu'elle attache, plus leurs
`GDScriptNativeClass`.** C'est le cache de scripts du moteur
(`GDScriptCache`), et il n'existe **aucune API GDScript pour le purger**. Le
constat n'est pas nouveau : la bissection de R2B.3 l'avait déjà identifié et
énuméré sur la sonde ; il est ici confirmé sur la suite entière.

Provenance des 74 `.gd` retenus, par dossier :

```
14 scripts/components   7 scripts/reaction    5 scripts/world_v2
 5 scripts/dungeon      5 scripts/combat      4 scripts/world
 4 scripts/core         4 resources/tuning    4 resources/combat
 3 scripts/player       3 scripts/enemies     3 scripts/electricity
 2 shaders/characters   2 scripts/characters  1 shaders/foliage
 1 scripts/ui           1 scripts/lookdev     1 scripts/inventory
 1 scripts/interaction  1 scripts/art         1 resources/weapons
 1 resources/ingredients 1 resources/enemies
```

C'est la surface de code que la suite monte, pas un conteneur du projet.

### Les 3 shaders sont une CONSÉQUENCE des 135 scripts, pas une cause distincte

Les trois `Shader` vivants sont :

```
res://shaders/characters/SH_CharacterPainterly.gdshader
res://shaders/characters/SH_CharacterPainterlyCutout.gdshader
res://shaders/foliage/SH_FoliageWindPainterly.gdshader
```

Les trois sont des constantes `preload()` de **`scripts/lookdev/hero_shot_lab.gd`**
(lignes 87, 92, 97) — et ce script est lui-même dans l'ensemble retenu
(vérifié : `res://scripts/lookdev/hero_shot_lab.gd` apparaît dans
`Resource still in use`). Une constante `preload` vit dans la table de
constantes du script ; tant que le script est épinglé, elle l'est aussi, et
`liberer_caches()` n'y peut rien — elle vide des variables, pas des constantes.

**Il reste donc UNE cause pour les 138, pas deux.**

---

## 3. Ce qui pourrait encore être fait, et pourquoi ce n'est PAS fait ici

Remplacer les trois `preload()` de `hero_shot_lab.gd` par des `load()` paresseux
retirerait 3 objets, 3 ressources et **la ligne `DummyShader` entière** du
rapport — soit une des cinq lignes rouges.

Ce n'est pas fait, et le raisonnement est écrit plutôt que caché :

- cela ne rendrait **pas** le harnais vert — les 135 objets de script restent, et
  aucune API GDScript ne les libère ;
- `hero_shot_lab.gd` est un laboratoire de look-dev, hors du périmètre de cette
  directive et hors du chemin critique ;
- changer un `preload` légitime pour retrancher trois lignes d'un rapport qui
  reste rouge est **cosmétique**. La méthode du projet interdit d'ajuster ce qui
  est mesuré pour flatter le verdict ; retoucher le code dans le même but
  relève du même travers.

Décision au propriétaire.

---

## 4. Verdict

| | |
|---|---|
| Fuite d'ISS-059 (matériaux, maillages, textures) | **CORRIGÉE** — lignes absentes du rapport |
| Croissance cumulative | **ABSENTE** — cycle 1 = cycle 2 à l'unité |
| Objets concernés réellement libérés | **OUI** — 281 → 0, 214 → 0, 67 → 0 |
| Résidu restant | **ÉNUMÉRÉ ET ATTRIBUÉ** — cache de scripts du moteur |
| Harnais global | **ROUGE** — cinq lignes de fin de processus subsistent |

Le seuil du filtre N1 n'a pas été touché, et ne le sera pas pour faire passer un
rouge.
