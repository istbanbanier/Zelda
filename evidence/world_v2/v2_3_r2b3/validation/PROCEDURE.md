# ISS-063 — rejeu isolé des suites contaminées : procédure exacte

Agent « suites rejouées ». Dépôt `/home/user/Zelda`, branche
`claude/world-v2-reconstruction`. Godot 4.7.1-stable, rendu logiciel llvmpipe —
**aucune mesure de performance n'est produite ici.**

## HEAD réellement testé — il n'est PAS celui du brief

| | |
|---|---|
| HEAD annoncé dans le brief | `291a62198eaddd5cead7929e828839f141ba996f` |
| HEAD au démarrage de l'agent (11:22Z) | `4857c0889a1243baa8f611d2421d9ecae6e18eb3` |
| HEAD au moment du rejeu (11:23Z et après) | `47e182bd21c95a71838d408796bebb021c815383` |

`291a621` est bien un **ancêtre** de HEAD (`git merge-base --is-ancestor` → 0),
mais trois commits l'ont dépassé, dont deux **pendant cette session** : le dépôt
a bougé sous les pieds de l'agent entre sa première et sa deuxième commande.
Les verdicts ci-dessous portent donc sur `47e182b`, pas sur `291a621`.

## Enveloppe d'isolation appliquée à CHAQUE lancement

```bash
XDG_DATA_HOME=/tmp/ud_suites \
  flock -w 3000 "$(git rev-parse --git-common-dir)/heavy_tools.lock" \
    timeout 3000 /usr/local/bin/godot --headless --path /home/user/Zelda \
      --script tools/godot/test_runner.gd -- "--filter=<lot>"
```

Trois précautions, toutes vérifiées et non supposées :

1. **`user://` propre.** `XDG_DATA_HOME=/tmp/ud_suites` → `user://` vaut
   `/tmp/ud_suites/godot/app_userdata/…`, jamais `/root/.local/share/…` partagé
   par tous les arbres de travail. C'est le mécanisme d'ISS-063.
2. **Verrou du dépôt**, pris **une seule fois pour les trois lots** (script
   `/tmp/batch_suites.sh`), pour ne pas avoir à le regagner entre deux lots.
3. **Comptage de processus avant/après chaque lot**, via
   `ls -l /proc/*/exe | grep -c godot` — jamais `pgrep -f`, jamais `pkill`.
   Le lot est **refusé** si un Godot étranger tourne.

Le RC de `flock` est testé à chaque fois : `flock -w N` qui expire rend **1 sans
exécuter la commande**. Un `RC=1` accompagné d'un journal **vide** est signalé
explicitement comme « le verrou a expiré, rien n'a tourné ».

Le drapeau est `--filter=`, **pas** `--filtre=` : `test_runner.gd:159`
(`_read_filter`) ne lit que `--filter=`, et un drapeau inconnu est ignoré, ce
qui lancerait la suite **entière** (193 fichiers) en silence. Contrôle de
plausibilité posé avant les lancements, par simple comptage de chemins :

| filtre | fichiers attendus |
|---|---:|
| `world_v2` | 31 |
| `boss_arena` | 1 |
| `boot_smoke` | 1 |
| (suite entière) | 193 |

## Cache d'import : il était PÉRIMÉ, et il a fallu le rafraîchir d'abord

Constat avant tout lancement, par comparaison du md5 du fichier avec le
`source_md5` mémorisé par Godot :

| `.glb` | md5 du fichier | `source_md5` du cache | verdict |
|---|---|---|---|
| `assets/architecture/farm/SM_Farm_Ruins.glb` | `15187278…` | `b69e6470…` | **périmé** |
| `assets/architecture/flora/SM_ThunderstruckTree.glb` | `cbcce425…` | `c85419051…` | **périmé** |

Les deux fichiers sont pourtant **identiques à HEAD** (`git status` muet) : ce
sont les commits `a6d503f` et `3d80fe4` (correctifs R2B.3 des gravats) qui les
ont changés après le dernier import du 19/08 13:25. Une suite lancée sur ce
cache aurait décrit la géométrie **précédente** — exactement le piège annoncé.

`godot --headless --path . --import` a donc été lancé **en premier**, sous la
même enveloppe. Après coup, les deux `source_md5` égalent les md5 des fichiers.

## Journaux produits

| fichier | contenu |
|---|---|
| `00_golden_masters.log` | `sha256sum -c` des 6 golden masters |
| `01_import.log` | import des ressources |
| `02_world_v2.log` | lot `--filter=world_v2` |
| `03_boss_arena.log` | lot `--filter=boss_arena` |
| `04_boot_smoke.log` | lot `--filter=boot_smoke` |
| `RESUME_RC.txt` | RC, durée, processus concurrents et ligne RÉSULTAT de chaque lot |
