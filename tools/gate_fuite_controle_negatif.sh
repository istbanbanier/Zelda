#!/usr/bin/env bash
# Le portail se prouve AVANT de servir. PROMPT4_METHOD §2 : « un test vert n'est
# pas une preuve ; un test qui échouerait sans le correctif en est une. »
#
# Sept fixtures, sept verdicts attendus. Le témoin doit passer VERT ; chacun des
# cinq sabotages doit rougir POUR SA RAISON PROPRE ; le journal non `--verbose`
# doit sortir BLOQUÉ et non vert — ne pas pouvoir conclure n'est pas réussir.
#
# Ce contrôle dure quelques millisecondes et tourne à chaque validate_fast :
# il empêche le portail de se dégrader en silence, ce qui est exactement le mode
# de panne que ce portail existe pour éviter.
#
# COUPLAGE VOLONTAIRE, à connaître avant de s'en étonner : la fixture 01 ne passe
# que parce que `scripts/lookdev/hero_shot_lab.gd` contient RÉELLEMENT
# `preload("res://shaders/characters/SH_CharacterPainterly.gdshader")`. La
# justification d'un shader survivant n'est pas déclarée dans une table, elle est
# LUE dans le dépôt. Si ce `preload` disparaît, la fixture 01 rougit — et c'est
# le comportement voulu : le mécanisme de justification ne tient plus, il faut
# donc le revoir, pas le contourner. Une fixture entièrement synthétique aurait
# prouvé que le code s'exécute, jamais qu'il dit vrai.
set -uo pipefail
cd "$(dirname "$0")/.."
FIX="tests/fixtures/gate_fuite"
OUTIL="python3 tools/gate_fuite_ressources.py"
ECHECS=0

# fichier | code attendu | fragment attendu dans la sortie
CAS=(
  "01_temoin_moteur.log|0|PROJECT_RESOURCE_LEAK_GATE : VERT"
  "02_materiau_projet.log|1|ressource(s) du PROJET survivent"
  "03_rid_nouveau.log|1|classe(s) de RID appartenant au projet"
  "04_mesure_vs_explique.log|1|ensemble mesuré ≠ ensemble expliqué"
  "05_shader_orphelin.log|1|qu'aucun script retenu ne charge par preload"
  "06_non_verbose.log|3|BLOQUÉ"
  "07_flux_audio.log|1|ressource(s) du PROJET survivent"
)

# Le MODE AGRÉGAT a ses propres fixtures : c'est lui qui tourne à chaque
# validate_fast, donc c'est lui qu'il serait le plus grave de laisser pourrir.
# Le contrat de fixture est FIGÉ et distinct du contrat vivant du dépôt : sinon
# ces cas changeraient de verdict à chaque re-baseline, et un contrôle qui
# change de verdict tout seul n'en est plus un.
CONTRAT_FIXE="$FIX/contrat_essai.json"
#
# LE TROU QUE CES TROIS DERNIERS CAS FERMENT. La revue contradictoire a muté le
# code : elle a SUPPRIMÉ la comparaison des deux comptes — le cœur même du mode
# qui tourne à chaque passe — et les neuf cas sont restés VERTS. Raison : le cas
# 09 rougissait par sa classe de RID, jamais par ses comptes. On pouvait donc
# effacer le contrôle sans qu'aucun contrôle ne s'en aperçoive. C'est exactement
# le « test qui ne peut pas échouer » de PROMPT4_METHOD §2.
CAS_AGREGAT=(
  "08_agregat_temoin.log|0|PROJECT_RESOURCE_LEAK_GATE : VERT"
  "09_agregat_materiau.log|1|classe de RID appartenant au projet : DummyMaterial"
  "10_agregat_objets.log|2|objets fuités = 139, contrat = 138"
  "11_agregat_ressources.log|2|ressources retenues = 75, contrat = 74"
  "12_agregat_rid_disparu.log|2|classe de RID du contrat ABSENTE de la mesure : DummyShader"
)

for cas in "${CAS[@]}"; do
  IFS='|' read -r fichier attendu fragment <<< "$cas"
  sortie="$($OUTIL "$FIX/$fichier" --racine . 2>&1)"
  rc=$?
  if [ "$rc" -ne "$attendu" ]; then
    echo "  [ÉCHEC] $fichier : code $rc, attendu $attendu"
    echo "$sortie" | sed 's/^/          /'
    ECHECS=$((ECHECS + 1))
  elif ! printf '%s' "$sortie" | grep -qF "$fragment"; then
    echo "  [ÉCHEC] $fichier : code correct mais motif absent — « $fragment »"
    echo "$sortie" | sed 's/^/          /'
    ECHECS=$((ECHECS + 1))
  else
    echo "  [OK]   $fichier -> code $rc, motif attendu présent"
  fi
done

for cas in "${CAS_AGREGAT[@]}"; do
  IFS='|' read -r fichier attendu fragment <<< "$cas"
  sortie="$($OUTIL "$FIX/$fichier" --mode=agregat --racine . --reference "$CONTRAT_FIXE" 2>&1)"
  rc=$?
  if [ "$rc" -ne "$attendu" ]; then
    echo "  [ÉCHEC] $fichier (agrégat) : code $rc, attendu $attendu"
    echo "$sortie" | sed 's/^/          /'
    ECHECS=$((ECHECS + 1))
  elif ! printf '%s' "$sortie" | grep -qF "$fragment"; then
    echo "  [ÉCHEC] $fichier (agrégat) : code correct mais motif absent — « $fragment »"
    echo "$sortie" | sed 's/^/          /'
    ECHECS=$((ECHECS + 1))
  else
    echo "  [OK]   $fichier (agrégat) -> code $rc, motif attendu présent"
  fi
done

if [ $ECHECS -eq 0 ]; then
  echo "  $(( ${#CAS[@]} + ${#CAS_AGREGAT[@]} )) cas : le portail rougit pour chaque défaut et passe sur les témoins."
  exit 0
fi
echo "  $ECHECS cas en échec — le portail ne peut pas être cru."
exit 1
