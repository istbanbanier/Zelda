#!/usr/bin/env bash
# ISS-062 — sabotage puis RESTAURATION BYTE-IDENTIQUE, sous le verrou du dépôt.
#
# POURQUOI TOUT TIENT DANS UN SEUL SCRIPT VERROUILLÉ : l'arbre est partagé. Si
# le GLB saboté restait en place entre deux invocations, une autre session le
# verrait et rendrait un verdict sur une géométrie qui n'existe pas. Le verrou
# sérialise, le `trap` garantit la restauration même sur interruption.
#
# PIÈGE EXPLICITE DU BRIEF, RESPECTÉ : après TOUT changement de .glb, relancer
# `--import`. Sans cela le cache décrit la géométrie PRÉCÉDENTE et le test rend
# un résultat parfaitement crédible et faux.
set -u

CIBLE="assets/architecture/farm/SM_Farm_Ruins.glb"
SHA_PRISTINE="ead79105e3deaf70629c1bd928e68d355261217dbd2d5150384b4a7590cf9060"
SP="$1"          # répertoire de travail (hors dépôt)
OUT="$2"         # répertoire des journaux (dans evidence/)
GODOT=/usr/local/bin/godot

restaurer() {
  cp -f "$SP/SM_Farm_Ruins.PRISTINE.glb" "$CIBLE"
  echo "--- RESTAURATION ---"
  sha256sum "$CIBLE"
  XDG_DATA_HOME="$SP/ud" timeout 1200 "$GODOT" --headless --path . --import \
    > "$OUT/06_import_apres_restauration.log" 2>&1
  echo "import apres restauration RC=$?"
}
trap restaurer EXIT

mkdir -p "$OUT" "$SP/ud"

echo "=== 0. etat de depart ==="
sha256sum "$CIBLE"
if [ "$(sha256sum "$CIBLE" | cut -d' ' -f1)" != "$SHA_PRISTINE" ]; then
  echo "BLOQUE : le fichier de depart n'est pas le sha256 attendu"; exit 3
fi

echo "=== 1. installation du GLB sabote ==="
cp -f "$SP/SABOTE.glb" "$CIBLE"
sha256sum "$CIBLE"

echo "=== 2. reimport (le cache doit decrire la NOUVELLE geometrie) ==="
XDG_DATA_HOME="$SP/ud" timeout 1200 "$GODOT" --headless --path . --import \
  > "$OUT/04_import_sabote.log" 2>&1
echo "import RC=$?"

echo "=== 3. le filet, attendu ROUGE ==="
XDG_DATA_HOME="$SP/ud" timeout 2400 "$GODOT" --headless --path . \
  --script tools/godot/test_runner.gd -- --filter=r2b3_debris \
  > "$OUT/05_filet_ROUGE_sabote.log" 2>&1
echo "runner RC=$?"
