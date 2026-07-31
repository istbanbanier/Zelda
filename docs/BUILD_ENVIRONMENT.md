# BUILD ENVIRONMENT

Exigence §5.1 : consigner la version exacte du moteur et des outils. Ce fichier est
régénérable par `tools/env_report.sh` ; la version brute est archivée dans
`evidence/gate0/env_report.txt`.

## Moteur

| Champ | Valeur |
|---|---|
| Godot | **4.7.1-stable** |
| Commit du tag | `a13da4feb8d8aefc283c3763d33a2f170a18d541` |
| Édition | standard, sans .NET |
| Provenance | **compilé depuis la source** (voir DECISIONS D-001) |
| Cible de build | `platform=linuxbsd target=editor arch=x86_64 debug_symbols=no` |
| Renderer projet | Forward+ (`rendering/renderer/rendering_method="forward_plus"`) |
| Physique 3D | Jolt Physics (`physics/3d/physics_engine="Jolt Physics"`) |
| Tick physique | 60 Hz |
| `config_version` | 5 |

`Engine.get_version_info()` est relu à l'exécution par `tests/unit/test_smoke.gd`,
qui échoue si le moteur n'est pas exactement 4.7.1-stable. La version n'est donc pas
seulement documentée, elle est testée.

## Outils de production

| Outil | Version | Provenance |
|---|---|---|
| Blender | 4.0.2 | paquet Ubuntu noble (`blender`) |
| Exporter glTF `io_scene_gltf2` | 4.0.44 | fourni avec Blender |
| numpy | 1.26.4 | `python3-numpy` — **dépendance obligatoire** de l'exporter glTF, requise par le Python **embarqué de Blender** (3.12), pas par le python3 d'outillage |
| Python | 3.11.15 (outillage) / 3.12.3 (embarqué Blender) | système |
| SCons | 4.5.2 | paquet Ubuntu |
| GCC | 13.3.0 | paquet Ubuntu |
| Git LFS | **absent** | non installé, non requis à ce stade (R-005) |

> ⚠️ Le paquet Ubuntu de Blender n'embarque pas numpy alors que l'exporter glTF en
> dépend. Sans `python3-numpy`, tout export échoue par `ModuleNotFoundError`
> (KNOWN_ISSUES ISS-R02).

## Machine de développement actuelle

| Champ | Valeur |
|---|---|
| OS | Ubuntu 24.04.4 LTS |
| Noyau | Linux 6.18.5 x86_64 |
| CPU | 4 cœurs |
| RAM | 15 Gio |
| GPU | **aucun** (`/dev/dri` absent) |
| Affichage | **aucun** (`DISPLAY` vide) |
| Rendu logiciel | Mesa llvmpipe présent, `xvfb-run` présent |

### Conséquences directes

- ✅ Possible : import, parse, tests unitaires et d'intégration headless, logique de
  jeu, données, sauvegarde, graphe électrique, pipeline d'assets.
- ⚠️ Possible mais dégradé : la **capture** et donc la régression visuelle, via
  Xvfb + Mesa llvmpipe (rendu **logiciel**). Couleurs et filtrage diffèrent d'un
  GPU réel : tolérances larges obligatoires, notation artistique fine exclue.
- ❌ Impossible : profilage, frame pacing, session 60 min, export de build, test
  audio. Donc **Gates H, I et J restent bloqués ici**, et la notation WOW du
  Gate C.5 devra se faire sur une machine avec GPU (ISS-002, ISS-004).
- Cette machine **n'est pas** un matériel de référence de performance. Aucun budget
  de frame ne peut en être tiré (§20.1).

## Restrictions réseau constatées

| Hôte | Résultat |
|---|---|
| `godotengine.org`, `downloads.godotengine.org` | **CONNECT → 403** (politique d'egress) |
| `download.blender.org` | **CONNECT → 403** |
| `github.com` (git) | accessible en lecture |
| `archive.ubuntu.com`, `pypi.org`, `registry.npmjs.org` | accessibles |

La documentation Godot en ligne étant inaccessible, la **source primaire de
référence** pour toute question d'API est le code du tag cloné sous `/opt/src/godot`.

## Reconstruire cet environnement

```bash
tools/setup_godot.sh          # Godot 4.7.1 depuis la source, ~60-120 min sur 4 cœurs
apt-get install -y blender python3-numpy
tools/env_report.sh           # vérifier les versions obtenues
```

Le conteneur étant éphémère, la compilation est à relancer à chaque session neuve.
La lancer **en arrière-plan dès le début** et travailler sur la documentation, les
données et les scripts pendant ce temps (RISKS RSK-09).
