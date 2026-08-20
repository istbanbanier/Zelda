# ISS-063 — le correctif ne dépend plus d'un lanceur contournable

Passe R2B.3.1, 2026-08-20. Base `06b865b`.

La directive du propriétaire : *« Le correctif ne doit pas dépendre uniquement
d'un lanceur que certains scripts peuvent contourner. »*

---

## 1. La dette, comptée AVANT de poser quoi que ce soit

`PROMPT4_METHOD` §1 l'exige : compter les violations existantes d'abord, sinon
on ne sait pas si le garde-fou protège du propre ou rattrape une dette.

Balayage des exécutables versionnés (`.sh`, `.py`, `.yml`), hors `evidence/`,
sur les lignes non commentées qui référencent le binaire :

**13 fichiers, 35 sites.** Deux fichiers conformes : `tools/lancer_godot.sh`
(le mécanisme) et `tools/lancer_godot_autotest.sh` (son contrôle négatif).
**Onze fichiers ne prenaient ni verrou canonique ni cloison `user://`.**

Inventaire détaillé, ligne à ligne : `INVENTAIRE_POINTS_ENTREE.md`, plus la
contre-épreuve qui l'a complété (neuf sites de plus, un quatrième fichier de
verrou, un lancement Blender, un vecteur documentaire sous-compté d'un facteur 7).

Ce n'est donc **pas** un garde-fou anti-régression posé sur du propre. C'est le
contrôle qui rend durable la conversion de ces onze fichiers.

---

## 2. Le mécanisme unique — `tools/lib/godot_env.sh`

Deux gestes DIFFÉRENTS, dont aucun ne remplace l'autre :

| | rôle | ce que l'autre ne fait pas |
|---|---|---|
| **VERROU** `<git-common-dir>/heavy_tools.lock` | sérialise dans le TEMPS | ne protège pas d'un survivant lancé hors verrou |
| **CLOISON** `XDG_DATA_HOME` | sépare dans l'ESPACE | ne protège pas de la contention processeur |

Deux durées de vie de cloison, et c'est voulu :

- `godot_cloison_ephemere` — un `user://` neuf par invocation, effacé à la
  sortie. Pour une MESURE : un résidu de l'exécution précédente la fausserait.
- `godot_cloison_arbre` — un `user://` stable par arbre de travail
  (`<arbre>/.godot_user`, ignoré par git). Pour une SUITE en plusieurs étapes
  dont l'une relit ce qu'une autre a écrit.

Le verrou suit le DÉPÔT (`--git-common-dir`, le `.git` PARTAGÉ) et non le
répertoire : deux arbres de travail se disputent le même `.godot/imported` et le
même processeur. Dans un arbre de travail, `.git` est un FICHIER — `flock` sur
`.git/x.lock` y répond « Not a directory » puis « Bad file descriptor ».

---

## 3. Ce qui a été converti

| fichier | verrou | cloison | remarque |
|---|---|---|---|
| `tools/validate_fast.sh` | **8** = heavy_tools (`-w`), en plus de son `validate_fast.lock` (fd 9, `-n`) | d'arbre | le plus gros consommateur ; il ne se sérialisait avec RIEN |
| `tools/validate_release.sh` | 8 | d'arbre | captures : la cloison doit survivre entre étapes |
| `tools/capture_ab.sh` | 8 | d'arbre | lance par TABLEAU d'arguments — invisible à un motif naïf |
| `tools/capture_vslice_gate.sh` | 8 | d'arbre | |
| `tools/gate_negative_control.sh` | 8 | d'arbre | |
| `tools/gate_select.sh` | 8 | d'arbre | |
| `tools/godot/run_iss059_scenarios.sh` | 8 | d'arbre | prenait `/tmp/godot.lock`, le TROISIÈME verrou, que personne d'autre ne prend |
| `tools/env_report.sh` | 8, attente **10 s** | d'arbre | verrou occupé → le dit et n'annonce PAS une capacité non vérifiée |
| `tools/setup_godot.sh` | 8, attente **7200 s** | — | compile 90 min puis REMPLACE le binaire sous les pieds des moteurs en cours |
| `.githooks/pre-push` | 8, attente **5 s** | d'arbre | verrou occupé → parse SAUTÉ, dit explicitement ; bloquer un push 50 min serait pire |
| `tools/blackbox_player/server.py` | verrou canonique en Python (`_prendre_verrou_lourd`), attente 120 s | déjà isolée | `.mcp.json` le démarre sans qu'aucune ligne de shell existe |

Trois attentes différentes, chacune justifiée sur place : un rapport
d'environnement ne doit pas se bloquer une heure, un `git push` non plus, mais
une compilation du moteur doit attendre.

---

## 4. Ce qui n'a pas été fait dépendre de la discipline

`tests/unit/test_invariants.gd::test_tout_lancement_godot_prend_verrou_et_cloison`
balaie `tools/`, `.github/` et `scripts/` et échoue sur tout exécutable qui
référence le binaire sans citer le mécanisme canonique.

**Prédicat volontairement LARGE.** Sa première version exigeait un ` --` après le
binaire. La contre-épreuve a reproduit sa panne sur un site réel :
`tools/capture_ab.sh` construit ses arguments dans un tableau puis lance
`RUN "$GODOT_BIN" "${args[@]}"` — aucun `--` sur la ligne, site invisible, et il
tourne deux fois par invocation. Un prédicat qui rate un vrai lancement est pire
qu'absent : il donne l'illusion de la couverture. Sur-inclure est le bon sens de
l'erreur — un faux positif se règle par une exemption **nommée** qui laisse une
trace, un faux négatif ne laisse rien.

**Cycle rouge d'abord, mesuré :**

| étape | verdict |
|---|---|
| état livré | `9 réussi(s), 0 échoué(s)` |
| sabotage : verrou retiré de `gate_select.sh` | **ÉCHEC**, nommant `tools/gate_select.sh` |
| sabotage : inscription retirée d'un cache statique | **ÉCHEC**, nommant le fichier |
| restauration (sha256 identiques) | `9 réussi(s), 0 échoué(s)` |

**Quatre exemptions, chacune nommée et justifiée** dans `LANCEURS_EXEMPTES` :
le lanceur lui-même, son contrôle négatif (qui partage `user://` exprès), la
bibliothèque, le kit de validation manuelle (destiné à la machine du
propriétaire), le workflow GitHub (runner éphémère), `dev_report.py` (lit
`user://`, ne lance rien).

Et `CLAUDE.md` — chargé à chaque session — enseignait les quatre commandes NUES
sous « Commandes réelles », sans mentionner le lanceur. La dérive était
enseignée, pas subie. Corrigé.

---

## 5. Ce qui reste ouvert, dit sans atténuation

- **Blender n'est pas couvert.** `heavy_tools.lock` est défini comme sérialisant
  « tout usage lourd de Godot **ou Blender** ». Mesuré : **30 fichiers** de
  `tools/` lancent Blender, **4 seulement** prennent un verrou. Ce n'était pas
  le périmètre de cette directive (§2 parle des points d'entrée Godot) et je ne
  l'ai pas élargi de moi-même. Dette nommée, à ouvrir.
- **La commande tapée à la volée** n'écrit aucun fichier : aucun test ne la voit.
  Un hook `PreToolUse` la couvrirait — au prix de faux positifs sur tout fichier
  qui PARLE du binaire, dont ce document. Décision du propriétaire.
- **Le `kill` par `pgrep -x godot`** de `tools/blackbox_player/play.sh` reste
  hors de portée : rien n'empêche un processus d'en tuer un autre, verrou ou
  non. Le remède serait de restreindre le kill à ses propres enfants.
- **`tools/cave_oracle_batterie.py`** expose `--verrou` en argument, avec un
  chemin ABSOLU par défaut : un appelant s'exempte par un drapeau officiel, et
  depuis un autre clone il verrouillerait le mauvais fichier en silence.
- **Le vecteur documentaire** : 46 lignes de commandes nues dans 19 fichiers de
  `docs/`, plus `README.md`. Seul le `CLAUDE.md` racine est corrigé ici.
- **Je n'ai pas démontré une collision** entre deux sites. Le dégât mesuré reste
  celui de 2026-08-11 (huit échecs de sauvegarde fabriqués), pas un que j'aurais
  reproduit dans cette passe.
