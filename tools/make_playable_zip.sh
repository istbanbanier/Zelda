#!/usr/bin/env bash
# Archive JOUABLE du projet — à ouvrir dans Godot 4.7.1-stable.
#
# Ce n'est PAS un exécutable autonome : ce conteneur n'a aucun modèle
# d'export, et le binaire Godot y est un `custom_build`, dont les modèles
# officiels ne correspondraient de toute façon pas. Produire un `.exe` ou un
# `.x86_64` demanderait de recompiler la chaîne d'export — le niveau 7 de la
# pyramide, déclaré non exécutable ici (ISS-002).
#
# L'archive contient donc les SOURCES du projet, que Godot ouvre et lance.
# Sont exclus : le cache d'import (Godot le régénère), les preuves, les
# sources DCC lourdes et l'historique git.
set -uo pipefail

cd "$(dirname "$0")/.."
OUT_DIR="${OUT_DIR:-builds}"
STAMP="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
NAME="EclatsDOrage_MondeOuvert_${STAMP}"
STAGE="$(mktemp -d)"
TARGET="$STAGE/$NAME"
mkdir -p "$TARGET" "$OUT_DIR"

echo "=== Archive jouable : $NAME ==="

# Ce que Godot doit trouver pour ouvrir et lancer le projet.
for item in project.godot icon.svg assets scenes scripts resources shaders \
            materials tests tools docs README.md ATTRIBUTIONS.md CLAUDE.md; do
  [ -e "$item" ] || continue
  cp -r "$item" "$TARGET/" 2>/dev/null
done

# Le cache d'import est régénéré au premier lancement ; l'embarquer double le
# poids et se périme au premier changement de version.
rm -rf "$TARGET/.godot"
# Les sources Blender et les preuves ne servent pas à JOUER.
rm -rf "$TARGET/source_assets" "$TARGET/evidence" "$TARGET/builds"

cat > "$TARGET/COMMENT_JOUER.md" <<'GUIDE'
# Éclats d'Orage — comment lancer cette archive

## Ce que c'est

Le projet Godot complet, à ouvrir dans l'éditeur. **Ce n'est pas un
exécutable** : il faut Godot pour le lancer. Voir « Pourquoi » plus bas.

## Prérequis

**Godot 4.7.1-stable**, édition standard (pas .NET/Mono) :
<https://godotengine.org/download/archive/>

La version compte. Le projet utilise des API de 4.7 ; une 4.6 ou une 4.8
peut refuser d'ouvrir des scènes ou changer le comportement de la physique.

## Lancer

1. Décompresser l'archive.
2. Ouvrir Godot, **Importer**, choisir le `project.godot` du dossier.
3. Au premier import, Godot reconstruit son cache : **comptez plusieurs
   minutes**, la fenêtre peut sembler figée. C'est normal et cela n'arrive
   qu'une fois.
4. **F5** pour lancer.

## Commandes (AZERTY)

| Action | Touche |
|---|---|
| Se déplacer | Z Q S D |
| Sauter | Espace |
| Sprint | Maj gauche |
| Interagir | E |
| Attaque légère | clic gauche |
| Attaque lourde | R |
| Viser / tirer | clic droit puis clic gauche |
| Esquive | Ctrl gauche |
| Verrouillage | C ou clic molette |
| Inventaire | Tab |
| Pause | Échap |

Manette prise en charge.

## Ce que vous pouvez voir

La vallée porte **31 lieux** : le village de la rivière (auberge visitable),
deux hameaux, huit ruines, cinq espaces souterrains, dix repères naturels et
cinq territoires ennemis. Chacun se nomme à la première visite et se
sauvegarde.

Chaque lieu porte une récompense, et pas la même : coffres, armes posées au
sol, ingrédients rares, savoirs de cuisine et fragments d'histoire à lire.
Leur emplacement a été éprouvé par un corps physique — sol réel, place pour
s'en approcher, et possibilité de repartir.

La boucle du jeu de base fonctionne : crête de départ → vallée → camp →
donjon électrique → boss → victoire.

## Limites, dites franchement

- **Aucune mesure de performance n'a été faite.** Le conteneur de
  développement n'a pas de GPU ; le jeu n'a jamais tourné sur une vraie carte
  graphique. Le nombre d'images par seconde chez vous est inconnu.
- **Le rendu n'a pas été jugé.** Les captures de contrôle ont été faites en
  rendu logiciel, utilisables pour la régression, pas pour l'esthétique.
  Proportions et échelles de certains modèles sont des valeurs de départ.
- La vallée reste un **graybox** hors du premier plan et des lieux :
  montagnes en boîtes, citadelle sans terrasses.
- Les habitants, leurs routines et les dialogues ne sont pas faits.
- Six lieux — les cinq territoires ennemis et la cavité de cristal — portent
  une récompense dont la **condition d'ouverture n'est pas implémentée** : le
  coffre est là, mais rien n'exige encore d'avoir nettoyé le territoire ou
  résolu l'énigme.

## Pourquoi pas un .exe

Un exécutable autonome exige des « modèles d'export » compilés pour la même
version ET le même build du moteur. Le conteneur de développement n'en a
aucun, et son Godot est un `custom_build` : les modèles officiels 4.7.1 ne
conviendraient pas. Les fabriquer demande de recompiler la chaîne d'export.

Vous pouvez le faire vous-même une fois le projet ouvert :
**Projet → Exporter**, ajouter un preset, installer les modèles quand Godot
le propose, puis exporter.
GUIDE

( cd "$STAGE" && zip -qr "$NAME.zip" "$NAME" )
mv "$STAGE/$NAME.zip" "$OUT_DIR/"
rm -rf "$STAGE"

SIZE="$(du -h "$OUT_DIR/$NAME.zip" | cut -f1)"
echo "  archive : $OUT_DIR/$NAME.zip ($SIZE)"
echo "  commit  : $STAMP"
