#!/usr/bin/env bash
# Le test de B rougit quand la fonction MANQUE. Rougit-il quand elle est FAUSSE ?
# Deux mutations, chacune un correctif plausible et faux. Un test qui reste vert
# sur l'une des deux n'épingle pas ce qu'il prétend épingler.
set -uo pipefail
W=/home/user/wt-b
F="$W/scripts/core/asset_registry.gd"
cd "$W"
git checkout -q 3ef33d6
AVANT=$(sha256sum "$F" | cut -d' ' -f1)
echo "### sain : sha256 $AVANT"

muter() {   # $1 = nom, $2 = python de mutation
  python3 - "$F" <<PY
import pathlib, sys
p = pathlib.Path(sys.argv[1]); s = p.read_text(encoding="utf-8")
$2
p.write_text(s, encoding="utf-8")
PY
  echo "### MUTATION $1 — sha256 $(sha256sum "$F" | cut -d' ' -f1)"
  git diff --stat -- scripts/core/asset_registry.gd | tail -1
  tools/lancer_godot.sh --path "$W" --script tools/godot/test_runner.gd -- --filter=iss071_normalisation > "/tmp/mut_$1.log" 2>&1
  echo "RC_$1=$?"
  grep -aE "^=== RÉSULTAT" "/tmp/mut_$1.log"
  grep -acE "^\s+ÉCHEC" "/tmp/mut_$1.log" | sed 's/^/  assertions en échec : /'
  git checkout -q -- scripts/core/asset_registry.gd
  APRES=$(sha256sum "$F" | cut -d' ' -f1)
  [ "$APRES" = "$AVANT" ] && echo "  restauration EXACTE ($APRES)" || echo "  RESTAURATION FAUSSE"
}

# M1 : l'ordre inversé — on vérifie l'extension AVANT de retirer .import.
#      C'est le correctif « évident » et faux : les entrées .gltf.import
#      redeviennent invisibles, donc l'index d'une build resterait vide.
muter M1 '
avant = """	var source: String = fichier
	if source.to_lower().ends_with(SUFFIXE_IMPORT):
		source = source.substr(0, source.length() - SUFFIXE_IMPORT.length())
	if not EXTENSIONS_MODELE.has(source.get_extension().to_lower()):
		return PackedStringArray()"""
apres = """	var source: String = fichier
	if not EXTENSIONS_MODELE.has(source.get_extension().to_lower()):
		return PackedStringArray()
	if source.to_lower().ends_with(SUFFIXE_IMPORT):
		source = source.substr(0, source.length() - SUFFIXE_IMPORT.length())"""
assert s.count(avant) == 1, "motif M1 introuvable"
s = s.replace(avant, apres, 1)
'

# M2 : le retrait sans revérification — .bin.import et .tres.import entrent
#      dans un index de PackedScene.
muter M2 '
avant = """	if not EXTENSIONS_MODELE.has(source.get_extension().to_lower()):
		return PackedStringArray()
	return PackedStringArray([source.get_basename(), source])"""
apres = """	return PackedStringArray([source.get_basename(), source])"""
assert s.count(avant) == 1, "motif M2 introuvable"
s = s.replace(avant, apres, 1)
'

echo "### arbre final"
git status --porcelain | grep -v "iss071_manifeste_editeur.gd.uid" | wc -l
echo "RC=0"
