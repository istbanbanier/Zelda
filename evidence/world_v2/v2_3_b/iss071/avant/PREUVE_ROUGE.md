# ISS-071 — PREUVE ROUGE sur `cb8c5d7`, build autonome LANCÉE

**HISTORIQUE.** Ce dossier fige un état mesuré à une date ; il ne décrit pas
l'intention du projet. Le document qui fait autorité sur ce que la parité doit
être est `docs/contrats/iss071_parite_resolveurs.md`.

Produit par l'agent A de la directive corrective S1 ISS-071, le 2026-08-26.

---

## 1. Ce qui est prouvé, et par quoi

Le défaut d'ISS-071 est **reproduit de bout en bout par un portail
automatisé**, sur une build Linux exportée, lancée sous Xvfb avec un `user://`
vierge, et pilotée au clavier comme un joueur. Le verdict vient du binaire
autonome, jamais de l'éditeur.

| | |
|---|---|
| SHA git testé | `cb8c5d71a5188a18df49d0e48f37ed453a4b0c89` |
| fichiers sales à l'exécution | 3, **tous sous `tools/` et `tests/`** (les outils de ce portail) ; `scripts/` `scenes/` `assets/` `resources/` intacts |
| binaire exporté | `EclatsDOrage.x86_64`, 393 757 344 octets |
| sha256 du binaire | `13de524f6ade6137f02e26a667a8014f06f5c957e3466a9222a675a45c41881d` |
| moteur éditeur | 4.7.1-stable (custom_build) |
| moteur de la build | 4.7.1-stable (official) — templates release compilés localement |
| verdict du portail | **ROUGE, code 1** |
| contrôles exécutés | 32 · **19 ROUGE** · 0 BLOQUÉ · 2 NON VÉRIFIÉ |

## 2. La signature rouge exigée par la directive

| exigence | mesuré |
|---|---:|
| appels de placement manqués > 0 | **1 789** aux manifestes · **1 094** lignes au journal |
| modèles distincts manquants > 0 | **110** |
| index export ≠ index éditeur | kit **215 → 0** · registre **160 → 0** |
| au moins une famille kit | `kit : modèle inconnu` = **457** lignes, 96 modèles distincts |
| au moins une famille végétation | `modèle végétal introuvable` = **631** lignes, 21 distincts |
| modèles du champ des mille fleurs manquants | `[flower_field] modèle inconnu` = **4** (3 distincts) · `modèle de dalle inconnu` = **2** (2 distincts) |

Compteurs qui doivent être **positifs et égaux** des deux côtés, et qui ne le
sont pas :

| compteur | éditeur | export |
|---|---:|---:|
| `modules_instancies` | 459 | **0** |
| `cellules_emises` | 631 | **0** |
| `cellules_manquees` | 0 | **631** |
| `lieux_poses` | 16 | 16 (le seul qui tienne) |

Une cellule de MultiMesh manquée est sautée **entière** : le nombre d'objets
réellement absents de l'écran est très supérieur à 1 094.

## 3. Le mécanisme causal, remesuré sur CE binaire

Le journal d'export dit lui-même ce que le PCK contient, et il n'y a pas à le
déduire :

| dans le PCK | compte |
|---|---:|
| fichiers `Storing File` au total | 1 548 |
| **sources `.gltf` / `.glb`** | **0** |
| métadonnées `<nom>.gltf.import` / `<nom>.glb.import` | 252 |
| scènes importées `res://.godot/imported/*.scn` | 252 |

Le dépôt porte exactement 252 `.gltf`/`.glb` sous `assets/`. Un balayage qui
teste le suffixe `.glb`/`.gltf` sur `DirAccess.get_files()` ne trouve donc
**rien** dans une build, tandis que `load()` sur un chemin explicite réussit :
la redirection est transparente pour un chemin, pas pour un listage.

## 4. Reproductibilité

Le manifeste éditeur produit par ce portail est **identique au bit près** à
celui versé par le commit d'appareillage `cb8c5d7`
(`674c584288bec953116acea35e4261f53e444c5aab5c04e0ec0ea3886bde156a`). Les deux
viennent de deux exécutions indépendantes du même chemin d'écriture.

## 5. Ce que ce dossier NE prouve pas

- **I4/I5 ne sont pas couverts** : le manifeste ne porte pas la chargeabilité
  des chemins indexés jamais demandés. Côté export l'index est vide, donc le
  contrôle rougit pour absence de couverture — ce n'est pas la même chose que
  d'avoir éprouvé chaque chemin.
- **I8 est épinglé sur des littéraux de source**, pas sur un comportement de
  cache observé en exécution. Le comportement lui-même reste verrouillé par
  `tests/world_v2/test_world_v2_iss059_cache_kit.gd`, qui n'est pas rejoué ici.
- **Aucune conclusion visuelle** n'est tirée au-delà de « le monde est affiché »
  (luminance 0,292 contre 0,0027 pour l'écran de chargement).
- Une anomalie mineure est **relevée mais non expliquée** : `Wall_Arch` est
  demandé par la build et jamais par l'exécution éditeur (1 seule différence de
  modèles demandés côté kit). Elle est `NON VÉRIFIÉ`.

## 6. Fichiers

| fichier | contenu |
|---|---|
| `gate_export_parite.log` | journal complet du portail, du verrou au verdict |
| `jeu_exporte_stdout.log` | stdout+stderr du jeu exporté, 2 239 lignes |
| `manifeste_editeur.json` | index et compteurs, exécution éditeur |
| `manifeste_export.json` | index et compteurs, build exportée |
| `rapport_parite.json` | les 32 contrôles, un par un, avec la taille examinée |
| `inventaire_modeles_absents.txt` | **inventaire nominatif** des 110 modèles |
| `contexte.json` | SHA git, sha256 du binaire, luminance, compteurs |
| `export_linux.log` | journal d'export : la liste de ce qui entre dans le PCK |
| `controle_negatif.log` | les dix sabotages du portail (voir `CONTROLES_NEGATIFS.md`) |
| `02_monde.png` | capture réelle du monde affiché par la build |
| `01_menu.png` | capture du menu, avant « Nouvelle partie » |

## 7. Rejouer

```bash
cd /home/user/wt-a
nohup tools/gate_export_parite.sh --sortie /home/user/wt-a-out > gate.log 2>&1 &
until grep -q '^RC=' gate.log; do sleep 20; done   # jamais `| tail` : le tube masque le RC
```

---

## 8. Exécution de CONFIRMATION, sur la version committée du portail

La preuve des §1-§4 vient d'une exécution antérieure à deux correctifs du
comparateur (`I2/I3` et `I4/I5` rendaient VERT en n'examinant rien — voir
`CONTROLES_NEGATIFS.md` §3). Publier un portail dont la version versionnée n'a
jamais tourné serait exactement la dérive que ce dépôt punit. Il a donc été
rejoué **en entier**, sans réutilisation d'artefact, sur l'arbre committé.

| | exécution 1 | confirmation |
|---|---|---|
| SHA git | `cb8c5d7` (3 fichiers sales : les outils eux-mêmes) | `2defdf4`, **0 fichier sale** |
| verdict | ROUGE, code 1 | ROUGE, code 1 |
| contrôles | 32 · 17 ROUGE · 2 verts fabriqués | 32 · **19 ROUGE** · 0 BLOQUÉ · 2 NON VÉRIFIÉ |
| `kit : modèle inconnu` | 457 | **457** |
| `modèle végétal introuvable` | 631 | **631** |
| `flower_field` (2 familles) | 4 + 2 | **4 + 2** |
| sha256 du binaire | `13de524f…5c41881d` | `13de524f…5c41881d` |
| luminance du monde | 0,292 | 0,301 |
| durée | ~4 min | ~2,5 min |

Le binaire exporté est **identique au sha256 près** entre les deux exécutions,
bien que trois commits soient intervenus : le preset exclut `tools/`, `tests/`
et `docs/`, et sa graine est nulle. L'export est donc reproductible bit à bit,
ce qui rend le sha256 utilisable comme identité de build.

Journal : `gate_export_parite_confirmation.log` · contexte :
`contexte_confirmation.json`.
