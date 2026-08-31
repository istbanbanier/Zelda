# Manifeste de preuve — passe post-ISS-086 (2026-08-31)

SHA testé et exporté : 0597f1213d38a68fc934052f53f0224380178ed7
(claude/world-v2-post-iss086-team ; arbre propre, repo_dirty vérifié par
les portails eux-mêmes).

| Preuve | Fichier | Verdict |
|---|---|---|
| Suite complète (niveaux 1-3) | validate_fast_0597f121.log | VERT RC=0 — 1074 tests / 0 échec |
| LE journal jugé par le prédicat de l'étape 2 (ISS-095) | 02_unit_0597f121.log | 4 lignes ERROR, TOUTES de fin de processus, exemptées explicitement (« le résidu de sortie est jugé en 2b ») : 76 resources still in use = LE chiffre épinglé du contrat gelé ; 2 PagedAllocator ; 3 RID du renderer factice. Zéro [textes], zéro erreur de test. |
| Export + parité éditeur/export | parite.log | RC=0 — SHA testé concordant, build sha256 a7794c0e9cef9515… |
| Portail garnison G1-G7 | garnison.log | VERT (0 échec) — balayages PCK PASS, motifs resserrés [textes]/[audio] ACTIFS (737418b4) et silencieux |

Provenance des templates d'export (le portail ne teste que la présence —
déclaré ici) : templates OFFICIELS 4.7.1.stable, SHA512 vérifiée contre
SHA512-SUMS.txt de godotengine/godot-builds, installés sous
~/.local/share/godot/export_templates/4.7.1.stable et atteints par le
symlink .godot_user/godot/export_templates/4.7.1.stable. L'en-tête
d'export_presets.cfg mentionne d'anciens templates compilés depuis
/opt/src/godot : cette provenance-là n'est PAS celle de ce build.

Moteur : 4.7.1.stable.official.a13da4feb (binaire officiel, SHA512
vérifiée). Rendu logiciel llvmpipe — aucune mesure de performance ici,
conformément aux règles du dépôt.
