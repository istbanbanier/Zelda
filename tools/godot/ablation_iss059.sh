#!/usr/bin/env bash
# Ablation à variable unique sur le reproducteur minimal d'ISS-059.
#
# La matrice de scénarios a montré que `WorldV2.tscn` SEULE porte toute la
# signature en 22 s. On garde donc ce reproducteur et on ne fait varier qu'une
# chose : quel conteneur statique est vidé JUSTE AVANT `quit()`.
#
# C'est un INSTRUMENT D'ATTRIBUTION, pas un correctif. Vider un cache en fin de
# processus ne répare rien ; si le rapport de sortie perd ses objets après avoir
# vidé X, alors X les tenait. Le correctif, lui, agit à la source.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2
SORTIE="${1:?usage: ablation_iss059.sh <dossier_sortie>}"
mkdir -p "$SORTIE"

mesurer() {
  local nom="$1" abl="$2"
  local log="$SORTIE/${nom}.log"
  tools/lancer_godot.sh --attente=3000 --headless --path . \
    --script tools/godot/sonde_iss059_proprietaire.gd -- \
    --scenes=worldv2 --cycles=1 "--ablation=${abl}" --detail=non \
    > "$log" 2>&1
  local rc=$?
  local mat mesh tex shad obj res
  mat=$(grep -oP "\d+(?= RID allocations of type 'N13RendererDummy15MaterialStorage13DummyMaterialE')" "$log" | tail -1)
  shad=$(grep -oP "\d+(?= RID allocations of type 'N13RendererDummy15MaterialStorage11DummyShaderE')" "$log" | tail -1)
  mesh=$(grep -oP "\d+(?= RID allocations of type 'N13RendererDummy9DummyMeshE')" "$log" | tail -1)
  tex=$(grep -oP "\d+(?= RID allocations of type 'PN13RendererDummy14TextureStorage12DummyTextureE')" "$log" | tail -1)
  obj=$(grep -oP '\d+(?= ObjectDB instances were leaked)' "$log" | tail -1)
  res=$(grep -oP '\d+(?= resources still in use)' "$log" | tail -1)
  local fini
  fini=$(grep -c '^=== SONDE TERMINEE ===' "$log")
  printf '%-26s rc=%s fini=%s | obj=%-5s res=%-5s mat=%-5s shad=%-4s mesh=%-5s tex=%-5s\n' \
    "$nom" "$rc" "$fini" "${obj:-0}" "${res:-0}" "${mat:-0}" "${shad:-0}" "${mesh:-0}" "${tex:-0}"
}

echo "### ablation ISS-059 — reproducteur = WorldV2.tscn seule, 1 cycle"
mesurer temoin_sans_ablation  aucune
mesurer abl_kit_scene         kit_scene
mesurer abl_kit_material      kit_material
mesurer abl_registry_model    registry_model
mesurer abl_kit_scene_registry kit_scene+registry_model
mesurer abl_tout              tout
