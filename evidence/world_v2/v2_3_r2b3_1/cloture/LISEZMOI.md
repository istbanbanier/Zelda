# Clôture R2B.3.1 — les deux portails, et ce qui les prouve

Passe de clôture du 2026-08-21, base `a27e559`. Le lead a rendu son verdict sur
R2B.3 (**PASS visuel et technique**) et tranché sur ISS-059 : le résidu de
ressources du PROJET est corrigé ; le résidu de scripts du MOTEUR est un domaine
séparé, suivi et non bloquant.

Ce répertoire contient la matière de cette décision. Les preuves de la mesure
elle-même vivent à côté, dans `../iss059/`.

## Ce qui a été construit

| Fichier | Rôle |
|---|---|
| `tools/gate_fuite_ressources.py` | classe le rapport de fuite ; deux modes, deux verdicts |
| `tools/gate_fuite_controle_negatif.sh` | 9 fixtures : le portail doit rougir pour chaque défaut |
| `tools/gate_fuite_composition.sh` | énumération complète, le mode cher |
| `tools/gel_verifier.sh` + `docs/contrats/gel_v2_3_b.sha256` | le gel §4, rendu exécutable |
| `docs/contrats/residu_cache_moteur.json` | l'enveloppe connue du résidu moteur |

## Le principe : une LISTE BLANCHE

Le portail n'énumère pas ce qui est interdit — il énumère ce qui est **admis**
(`GDScript`, `GDScriptNativeClass`, et un `Shader` seulement s'il est démontré
constante `preload()` d'un script lui-même retenu). Tout le reste est du projet,
donc rouge. Un type de fuite encore jamais vu est rouge **par défaut**, jamais
silencieux par oubli — c'est la seule direction d'erreur acceptable pour un
garde-fou.

## Ce que chaque mode voit, et ce qu'il ne voit pas

| | à chaque `validate_fast` | sur commande |
|---|---|---|
| mode | agrégat | composition |
| coût | un `grep` | la suite en `--verbose` |
| voit | les 3 comptes, au chiffre près, et les classes de RID | chaque objet, chaque chemin |
| ne voit pas | une substitution à somme nulle | — |

La répartition est une décision mesurée, pas un confort : `--verbose` a été
chronométré sur cette machine et il triple la durée de la suite. Un contrôle de
ce prix à chaque tour finit contourné (PROMPT4_METHOD §0) — et un portail que
personne ne lance ne protège rien.
