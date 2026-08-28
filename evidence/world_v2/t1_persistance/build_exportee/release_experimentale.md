# Artefact expérimental T1 — coordonnées vérifiées depuis GitHub

Date de vérification : 2026-08-28. Toutes les valeurs ci-dessous sont lues
depuis les **données de GitHub** (API release + digests calculés par GitHub sur
les octets reçus), jamais depuis la sortie du dispatch.

## Coordonnées

| | |
|---|---|
| Run CI | `33188161790` (`publish-playtest.yml`, run n°27), conclusion **success** |
| Tag | `world-v2-t1-exp-53a6493` |
| Release id | `378607024` — **prerelease**, non draft |
| Commit lié | `53a64932cbad09d494eca88a30c294bc2fef1f94` (`target_commitish`, vérifié) |
| Branche | `claude/world-v2-t1-persistance` |
| Bandeau | présent : « n'est PAS la candidate de lundi », nomme `world-v2-candidate-iss073-98cbaf0` |

## Archives et empreintes (digests GitHub = table du corps = SHA256SUMS.txt)

| Fichier | Octets | SHA-256 |
|---|---:|---|
| `EclatsDOrage_MondeOuvert_53a6493.zip` | 427 776 863 | `01c534ecac64249e2c4a7cf9cf0cc587eca55b2325e14628d7e73e3893212c8f` |
| `EclatsDOrage_Windows_x86_64_53a6493.zip` | 350 159 030 | `508f63f3540459792fb6854c12fbc6689efbe4d37de9777d26e55305cfdc04ed` |
| `EclatsDOrage_macOS_53a6493.zip` | 372 510 114 | `270e2314de8af42f03884642c520b723ec3530e44a4ebd7d6bbbd37a4eaa4a34` |
| `EclatsDOrage_Linux_x86_64_53a6493.zip` | 340 501 493 | `28f1d22445c4d531189aa21d0071afd2badd76545e424e1494276a3be235e34b` |

Concordance vérifiée à trois sources indépendantes : les digests d'assets
calculés par GitHub, la table SHA-256 du corps de la release, et
`SHA256SUMS.txt` — identiques au caractère près pour les quatre archives.

## Assets texte re-téléchargés et hachés localement

| Fichier | SHA-256 local | Digest GitHub | Verdict |
|---|---|---|---|
| `PLAYTEST_T1_EXPERIMENTAL.md` | `0a900ad7dbdf…49b23475` | idem | **conforme**, `grep -c "@@"` → **0** placeholder restant, commit exact présent en ligne 3 |
| `SHA256SUMS.txt` | `52e40cefb554…f964fead` | idem | **conforme** |

## L'écart honnête entre la preuve locale et l'artefact CI

Le binaire prouvé par `gate_export_t1.sh` (21 PASS) est l'export **local**
construit sur l'arbre `a168dfd5`. L'artefact publié est un export **CI** de
`53a64932`. Mesuré : `git diff --name-only a168dfd5..53a64932` ne contient
**aucun** fichier `.gd`, `.tscn`, `.tres`, `.glb` ni `project.godot` — le diff
est intégralement outils (`gate_export_t1.sh`, `x11_fermer_fenetre.py`),
workflow, docs et evidence. Le contenu de jeu empaqueté par la CI provient donc
de la même source, à l'octet près, que celui prouvé localement. L'artefact CI
lui-même n'a pas été relancé ici : c'est une build expérimentale, jamais jouée
par un humain, et la release le dit en bandeau.
