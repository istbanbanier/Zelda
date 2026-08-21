#!/usr/bin/env bash
# LE GEL V2.3-B, RENDU EXÉCUTABLE.
#
# La directive de clôture R2B.3.1 §4 gèle V2.2, les quatre golden masters R2a,
# les lieux du lot pilote validés, les géométries et cadrages R2B.3, et les
# seuils acquis : « aucun élément gelé ne peut être modifié sans régression
# précise, reproductible et explicitement démontrée ».
#
# Un gel qui n'est qu'une phrase dans un document se dégrade en silence — c'est
# le principe directeur de PROMPT4_METHOD §0. Celui-ci est un sha256 par fichier,
# committé, et vérifié à chaque `validate_fast`. Le jour où quelqu'un touche un
# élément gelé, il l'apprend en secondes, pas trois semaines plus tard.
#
# CE QUI N'EST DÉLIBÉRÉMENT PAS GELÉ, et pourquoi :
#   * `world_v2_places_builder.gd` — son `REGISTRY` DOIT accueillir les nouveaux
#     lieux ; le geler interdirait V2.3-B lui-même.
#   * `world_v2_place_kit.gd` — c'est le kit partagé ; de nouvelles familles de
#     modules doivent pouvoir y entrer.
#   * tout ce qui est neuf : un lieu non encore construit n'a rien à geler.
#
# CE QUE CE GEL NE COUVRE PAS, nommé par la revue contradictoire plutôt que
# découvert plus tard :
#
#  1. LES SEUILS. La directive gèle « les seuils et contrôles acquis » ; aucun
#     fichier de seuil n'est ici. Un seuil peut donc être abaissé sans que le
#     gel bronche. Le garde-fou qui reste est la revue du diff et la règle
#     `tools/CLAUDE.md` : ne jamais changer la mesure ET fixer un nouveau seuil
#     dans la même passe. C'est un garde-fou humain, pas exécutable — dit ici
#     pour que personne ne croie le contraire.
#  2. LE KIT PARTAGÉ. `scripts/world_v2/poi/world_v2_place_kit.gd` n'est PAS
#     gelé, parce que V2.3-B doit pouvoir y ajouter des familles de modules. Or
#     un lieu gelé s'en sert : modifier le kit change la géométrie de ce lieu
#     sans qu'un seul sha256 bouge. La contrepartie est que chaque lot rejoue
#     les captures des lieux existants — c'est là, et seulement là, que cette
#     dérive se verrait.
#  3. AJOUTER N'EST PAS TOUCHER. Le périmètre est ÉNUMÉRÉ, jamais globé sur un
#     répertoire qui va grossir : créer un nouveau lieu ne rougit pas. En
#     échange, un fichier qui DEVRAIT entrer dans le gel n'y entre pas tout
#     seul — il faut l'ajouter à `gel_fichiers()`. C'est un choix : un gel qui
#     empêche de construire serait contourné dès le premier lot.
#
# LEVER LE GEL SUR UN FICHIER se fait en régénérant le manifeste
# (`--ecrire`) ET en justifiant la régression dans `docs/DECISIONS.md`. Le
# manifeste est committé : le changement se voit en revue. Il n'existe
# volontairement aucune variable d'environnement pour désarmer ce contrôle —
# un garde-fou désactivable finit désactivé.
set -uo pipefail
cd "$(dirname "$0")/.."
MANIFESTE="docs/contrats/gel_v2_3_b.sha256"

# --- LE PÉRIMÈTRE GELÉ, énuméré ici et nulle part ailleurs -------------------
# LES CHEMINS SONT ÉNUMÉRÉS, JAMAIS GLOBÉS SUR UN RÉPERTOIRE QUI VA GROSSIR.
# Une première version faisait `ls scenes/world_v2/poi/*.tscn`. Conséquence
# mesurée par la revue contradictoire : créer `WatchtowerRuinPlace.tscn` portait
# le périmètre à 43 contre 42 au manifeste, donc `[GEL INCOMPLET]`, donc
# `validate_fast` ROUGE. **Le lot 1 n'aurait pas pu ajouter un seul lieu.**
# Un gel doit interdire de TOUCHER l'existant, pas d'AJOUTER du neuf.
gel_fichiers() {
  # V2.2 : terrain, eau, végétation, routes, frontières, lumière, orage, caméras.
  ls scripts/world_v2/*.gd 2>/dev/null
  # Le layout canonique : la SEULE source de position d'un lieu.
  echo resources/world_v2/world_v2_layout.json
  # Les quatre golden masters R2a + les géométries R2B.3.
  echo assets/architecture/village/SM_Village_Wall.glb
  echo assets/architecture/village/SM_Village_Quay.glb
  echo assets/architecture/stone_bridge/SM_StoneBridge_Arch.glb
  echo assets/architecture/pylon/SM_Pylon_Resonance.glb
  echo assets/environment/caves/SM_WaterfallCave.glb
  echo assets/environment/caves/SM_WaterfallCave_r2a358.glb
  echo assets/architecture/farm/SM_Farm_Ruins.glb
  echo assets/architecture/flora/SM_ThunderstruckTree.glb
  # Les lieux du lot pilote validés — scripts et scènes.
  for f in abandoned_farm_place camp_checkpoint_place conductive_basin_place \
           ember_raider_camp_place resonance_pylon_landmark riverside_village_place \
           stone_bridge_place thunderstruck_tree_place waterfall_cave_place \
           world_v2_place; do
    echo "scripts/world_v2/poi/$f.gd"
  done
  for s in AbandonedFarmPlace CampCheckpointPlace ConductiveBasinPlace \
           EmberRaiderCampPlace RiversideVillagePlace StoneBridgePlace \
           ThunderstruckTreePlace WaterfallCavePlace; do
    echo "scenes/world_v2/poi/$s.tscn"
  done
  echo scenes/world_v2/landmarks/ResonancePylon.tscn
  # Le CONTRAT du portail de fuite. La géométrie était protégée, la ligne de
  # base du portail qui la surveille ne l'était pas — c'était le chemin le plus
  # court pour rendre vert un dépôt qui fuit. Trouvé par la revue.
  echo docs/contrats/residu_cache_moteur.json
  # Les cadrages R2B.3 : le plan de prises de vue qui rend les A/B comparables.
  echo evidence/world_v2/v2_3_r2b3/preuves_lead/shots_r2b3.json
}

if [ "${1:-}" = "--ecrire" ]; then
  {
    echo "# GEL V2.3-B — sha256 des éléments gelés par la directive de clôture R2B.3.1 §4."
    echo "# Régénéré volontairement le $(date -u +%Y-%m-%d) ; toute ligne modifiée doit être"
    echo "# justifiée dans docs/DECISIONS.md par une régression démontrée."
    gel_fichiers | sort -u | while IFS= read -r f; do
      [ -f "$f" ] && sha256sum "$f"
    done
  } > "$MANIFESTE"
  echo "manifeste écrit : $MANIFESTE ($(grep -c '^[0-9a-f]' "$MANIFESTE") fichiers)"
  exit 0
fi

if [ ! -f "$MANIFESTE" ]; then
  echo "  BLOQUÉ : manifeste de gel absent ($MANIFESTE)." >&2
  exit 3
fi

ECARTS=0
ABSENTS=0
while read -r attendu chemin; do
  case "$attendu" in \#*|"") continue ;; esac
  if [ ! -f "$chemin" ]; then
    echo "  [GEL ROMPU] fichier gelé ABSENT : $chemin"
    ABSENTS=$((ABSENTS + 1)); continue
  fi
  obtenu="$(sha256sum "$chemin" | cut -d' ' -f1)"
  if [ "$obtenu" != "$attendu" ]; then
    echo "  [GEL ROMPU] $chemin"
    echo "               attendu ${attendu:0:16}  obtenu ${obtenu:0:16}"
    ECARTS=$((ECARTS + 1))
  fi
done < "$MANIFESTE"

# Un fichier qui ENTRE dans le périmètre gelé sans être au manifeste passerait
# inaperçu : le manifeste couvrirait moins que le périmètre sans que rien ne le
# dise. On compare donc les deux ensembles, pas seulement les hachages.
PERIMETRE=$(gel_fichiers | sort -u | while IFS= read -r f; do [ -f "$f" ] && echo "$f"; done | wc -l)
AU_MANIFESTE=$(grep -c '^[0-9a-f]' "$MANIFESTE")
if [ "$PERIMETRE" != "$AU_MANIFESTE" ]; then
  echo "  [GEL INCOMPLET] $PERIMETRE fichier(s) dans le périmètre, $AU_MANIFESTE au manifeste"
  ECARTS=$((ECARTS + 1))
fi

if [ $((ECARTS + ABSENTS)) -eq 0 ]; then
  echo "  $AU_MANIFESTE élément(s) gelé(s) intacts au sha256."
  exit 0
fi
echo "  gel rompu : $ECARTS écart(s), $ABSENTS absent(s). Voir la directive R2B.3.1 §4."
exit 1
