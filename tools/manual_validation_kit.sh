#!/usr/bin/env bash
# Prépare et clôt la campagne de validation manuelle du Gate A.
# Protocole complet : docs/MANUAL_VALIDATION.md
#
#   tools/manual_validation_kit.sh              prépare evidence/gateA/
#   tools/manual_validation_kit.sh --finalize   écrit le manifeste et contrôle
#
# Ce script ne valide rien par lui-même : il prépare le terrain et vérifie que
# les preuves attendues sont là. Le verdict reste humain.
set -uo pipefail

cd "$(dirname "$0")/.."
DIR="evidence/gateA"
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"

# Fichiers attendus par étape. Une entrée absente n'est pas une erreur fatale :
# elle devient `NON VÉRIFIÉ`, ce que le manifeste consigne explicitement.
EXPECTED=(
  "01_lancement.png:1. Lancement avec écran"
  "01_lancement.log:1. Journal de lancement"
  "02_azerty_bandeau.png:2. Bandeau de disposition AZERTY"
  "02_azerty_q_gauche.png:2. Q maintenu, move_left ACTIF"
  "02_azerty_tableau.md:2. Tableau clavier rempli"
  "03_manette_detectee.png:3. Manette détectée"
  "03_manette_tableau.md:3. Tableau manette rempli"
  "04_menu_focus.png:4. Focus visible dans le menu"
  "04_menu_petit.png:4. Menu en petite fenêtre"
  "04_menu_grand.png:4. Menu en grande fenêtre"
  "04_menu_confirmation.png:4. Confirmation d'écrasement"
  "05_reprise.md:5. Reprise chronométrée"
  "05_validate_fast.log:5. validate_fast sur clone neuf"
  "RAPPORT.md:6. Rapport rempli"
)

finalize() {
  echo "=== Manifeste du Gate A ==="
  local manifest="$DIR/MANIFESTE.txt"
  {
    echo "commit          : $(git rev-parse HEAD 2>/dev/null)"
    echo "commit_court    : $(git rev-parse --short HEAD 2>/dev/null)"
    echo "arbre_propre    : $(test -z "$(git status --porcelain 2>/dev/null)" && echo oui || echo non)"
    echo "date_utc        : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "machine         : $(uname -srm)"
    echo "godot           : $("$GODOT_BIN" --version 2>/dev/null || echo ABSENT)"
    echo "operateur       : ${VALIDATION_OPERATOR:-<non renseigné : exporter VALIDATION_OPERATOR>}"
    echo
    echo "--- fichiers de preuve ---"
    for entry in "${EXPECTED[@]}"; do
      local file="${entry%%:*}"
      local label="${entry#*:}"
      if [ -f "$DIR/$file" ]; then
        printf '%-34s PRÉSENT  sha256=%s  %s\n' "$file" \
          "$(sha256sum "$DIR/$file" | cut -c1-16)" "$label"
      else
        printf '%-34s NON VÉRIFIÉ  %s\n' "$file" "$label"
      fi
    done
  } | tee "$manifest"

  local missing=0
  for entry in "${EXPECTED[@]}"; do
    [ -f "$DIR/${entry%%:*}" ] || missing=$((missing + 1))
  done

  echo
  if [ "$missing" -eq 0 ]; then
    echo "=== Toutes les preuves attendues sont présentes. ==="
    echo "Le verdict reste humain : remplir le tableau final de RAPPORT.md."
    return 0
  fi
  echo "=== $missing preuve(s) manquante(s) — Gate A ne peut pas être déclaré PASS. ==="
  echo "Chaque absence doit apparaître comme NON VÉRIFIÉ et motivée dans RAPPORT.md."
  # Code 3 = BLOQUÉ, cohérent avec tools/validate_release.sh.
  return 3
}

if [ "${1:-}" = "--finalize" ]; then
  [ -d "$DIR" ] || { echo "ÉCHEC: $DIR absent — lancer le kit sans option d'abord." >&2; exit 1; }
  finalize
  exit $?
fi

echo "=== Préparation de la campagne de validation manuelle du Gate A ==="
mkdir -p "$DIR"
tools/env_report.sh "$DIR/00_environnement.txt" > /dev/null 2>&1 && \
  echo "  environnement -> $DIR/00_environnement.txt"

if [ ! -f "$DIR/RAPPORT.md" ]; then
  cat > "$DIR/RAPPORT.md" <<'TEMPLATE'
# RAPPORT DE VALIDATION MANUELLE — Gate A

Protocole : `docs/MANUAL_VALIDATION.md`. Remplir en exécutant, pas de mémoire.

- **Opérateur** :
- **Date** :
- **Commit testé** :
- **Machine** (OS, écran, clavier, manette) :
- **Disposition clavier système** :

---

## Étape 1 — Lancement avec écran
- Observé :
- Erreurs dans le journal :
- **Verdict** : PASS / FAIL / NON VÉRIFIÉ

## Étape 2 — Clavier AZERTY, Q = gauche
- Verdict affiché par la sonde :
- Actions ne répondant pas :
- `Q` active-t-il `lock_on` ? (doit être NON) :
- **Verdict** : PASS / FAIL / NON VÉRIFIÉ

## Étape 3 — Manette
- Modèle :
- Entrées mortes :
- **Verdict** : PASS / FAIL / NON VÉRIFIÉ

## Étape 4 — Lisibilité et focus du menu
- Focus toujours visible ? :
- La navigation boucle-t-elle ? :
- Un bouton désactivé est-il atteignable ? (doit être NON) :
- Tenue au redimensionnement :
- Lisibilité (subjectif, à dire franchement) :
- **Verdict** : PASS / FAIL / NON VÉRIFIÉ

## Étape 5 — Reprise depuis une session neuve
- Lecteur (a-t-il construit le projet ?) :
- Durée chronométrée :
- Où en est le projet ? :
- Prochain jalon et première action ? :
- Qu'est-ce qui est bloqué ? :
- Quelle commande valider d'abord ? :
- Questions restées sans réponse, et document fautif :
- `validate_fast.sh` : code retour ___ , ___ tests
- **Verdict** : PASS / FAIL / NON VÉRIFIÉ

## Étape 6 — Archivage
- `MANIFESTE.txt` généré : oui / non
- Preuves manquantes :
- **Verdict** : PASS / FAIL / NON VÉRIFIÉ

---

## Verdict global du Gate A

Le plus faible des six, jamais la moyenne (§0.7).

**GATE A : PASS / FAIL / EN ATTENTE**

Réserves et défauts à ouvrir dans `docs/KNOWN_ISSUES.md` :
TEMPLATE
  echo "  gabarit       -> $DIR/RAPPORT.md"
else
  echo "  gabarit       -> $DIR/RAPPORT.md (déjà présent, conservé)"
fi

cat <<EOF

Commandes de la campagne :

  1. Lancement          godot --path . 2>&1 | tee $DIR/01_lancement.log
  2. Clavier AZERTY     godot --path . --scene res://scenes/tests/InputProbe.tscn
  3. Manette            même scène, manette branchée AVANT le lancement
  4. Menu               godot --path .
  5. Reprise            clone neuf + chronomètre, puis tools/validate_fast.sh
  6. Clôture            tools/manual_validation_kit.sh --finalize

Déposer les captures dans $DIR/ avec les noms attendus par le protocole.
Protocole détaillé et critères PASS/FAIL : docs/MANUAL_VALIDATION.md
EOF
