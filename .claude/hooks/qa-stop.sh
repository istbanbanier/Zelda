#!/usr/bin/env bash
# Garde-fou instantané d'Éclats d'Orage, exécuté à la fin de CHAQUE tour (hook Stop).
#
# Il ne fait QUE des contrôles à coût quasi nul sur les lignes AJOUTÉES par l'arbre de
# travail (diff non indexé des fichiers suivis + fichiers non suivis en texte). Il ne
# lance JAMAIS Godot, `validate_fast.sh`, ni un sous-agent :
#   - un hook Stop se déclenche à chaque tour : un contrôle lourd taxerait chaque
#     itération, et la suite met une vingtaine de minutes (COMMENT_TRAVAILLER §3) ;
#   - un hook est une commande shell, il ne peut de toute façon pas invoquer d'agent.
# Le plancher déterministe (parse par script) est dans `.githooks/pre-push`, et la
# revue de jugement reste `adversarial-qa` + la compétence `gate-review`.
#
# CE QU'IL BLOQUE — uniquement des invariants DURS du CLAUDE.md, tous détectables
# instantanément et sans faux positif :
#   1. contenu Nintendo dans le code, les scènes ou les ressources ;
#   2. l'image de référence North Star employée comme asset ;
#   3. une édition à la main du cache `.godot/imported/` ;
#   4. une déclaration GDScript non typée (`var x = ...`), alors que le dépôt en
#      compte zéro aujourd'hui : ce garde-fou est purement anti-régression.
#
# CE QU'IL NE BLOQUE PAS, DÉLIBÉRÉMENT : la règle « pas de print() sur le chemin
# critique » n'est pas ici, parce qu'elle ne se distingue pas d'un journal de
# diagnostic structuré (`boot.gd` en contient 11, légitimes). Un gate qui crie au
# loup finit contourné ; celui-ci ne se déclenche que sur du certain.
#
# Ce script est versionné et tourne chez tout contributeur. Il est volontairement
# petit et auditable : bash + git + perl, il ne lit que `git diff`, n'écrit rien et
# ne fait aucun appel réseau. Voir `.claude/hooks/README.md`.
set -uo pipefail

input=$(cat)

# Garde anti-boucle : si l'on a déjà bloqué une fois dans ce tour, laisser finir.
if printf '%s' "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$dir" 2>/dev/null || exit 0
command -v git >/dev/null 2>&1 || exit 0
command -v perl >/dev/null 2>&1 || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Les trois cahiers des charges CITENT les termes interdits pour les interdire ;
# `docs/` et les règles sont donc hors périmètre du scan de noms.
pathspec=(
  .
  ':(exclude)docs'
  ':(exclude).claude/hooks'
  ':(exclude).claude/rules'
  ':(exclude)ATTRIBUTIONS.md'
)

# Modifications suivies (git diff) + fichiers non suivis synthétisés comme
# entièrement ajoutés, afin qu'un fichier tout neuf soit scanné lui aussi.
stream=$(
  git diff -U0 --no-color -- "${pathspec[@]}" 2>/dev/null
  git ls-files --others --exclude-standard -- "${pathspec[@]}" 2>/dev/null \
    | grep -Ei '\.(gd|tscn|tres|godot|gdshader|md|py|sh|json|csv|cfg)$' \
    | while IFS= read -r f; do
        [ -f "$f" ] || continue
        printf '+++ b/%s\n' "$f"
        sed 's/^/+/' "$f" 2>/dev/null
      done
)

# Édition manuelle du cache d'import : se détecte sur le NOM de fichier, pas sur
# une ligne ajoutée (une suppression compte aussi). Contrôle séparé.
imported=$(git status --porcelain -- '.godot/imported' 2>/dev/null | head -5)

[ -n "$stream" ] || [ -n "$imported" ] || exit 0

out=$(IMPORTED="$imported" perl -CSD -e '
  my @hits; my $file = "";

  if (length($ENV{IMPORTED} // "")) {
    for my $l (split /\n/, $ENV{IMPORTED}) {
      $l =~ s/^\s+|\s+$//g;
      next unless length $l;
      push @hits, "$l [cache d import edite a la main]";
    }
  }

  # Noms de code imposes par le CLAUDE.md : raider_red/blue/black, ravine_troll,
  # centaur_hunter. Toute marque Nintendo dans le code est un invariant dur.
  my $nintendo = qr/\b(bokoblin|lynel|hyrule|sheikah|ganon(?:dorf)?|korok|triforce|deku|zonai|moblin|hylian|master\s+sword|breath\s+of\s+the\s+wild)\b/i;

  while (my $line = <STDIN>) {
    if ($line =~ m{^\+\+\+\s+b/(.+)$}) { $file = $1; $file =~ s/\s+$//; next; }
    next unless $line =~ /^\+/;
    next if $line =~ /^\+\+\+/;
    my $c = substr($line, 1);
    chomp $c;
    my $cat = "";

    if ($c =~ $nintendo) {
      $cat = "contenu Nintendo (noms de code imposes : raider_red/blue/black, ravine_troll, centaur_hunter)";
    } elsif ($file =~ /\.(tscn|tres|gdshader|material)$/
             && $c =~ /NORTH_STAR|docs\/references\//i) {
      $cat = "image de reference employee comme asset (jamais skybox, billboard ni texture)";
    } elsif ($file =~ /\.gd$/
             && $c =~ /^\s*(?:\@export(?:_[a-z_]+)?(?:\([^)]*\))?\s+)?(?:static\s+)?var\s+[A-Za-z_]\w*\s*=\s*\S/) {
      $cat = "declaration GDScript non typee (utiliser := ou : Type =)";
    }

    next unless $cat;
    my $snip = $c; $snip =~ s/^\s+//; $snip =~ s/\s+$//; $snip = substr($snip, 0, 90);
    push @hits, "$file [$cat] : $snip";
    last if @hits >= 20;
  }

  exit 0 unless @hits;
  my $n = scalar @hits;
  my $body = "Garde-fou QA : $n ligne(s) de ce changement violent un invariant dur du CLAUDE.md. "
    . "Corrige chacune avant de terminer (aucun contenu Nintendo ; l image de reference n est "
    . "jamais un asset ; ne jamais editer .godot/imported/ a la main ; GDScript type partout) :";
  $body .= "\n- $_" for @hits;
  $body =~ s/([\\"])/\\$1/g;
  $body =~ s/([\x00-\x1f])/sprintf("\\u%04x", ord($1))/ge;
  print "{\"decision\":\"block\",\"reason\":\"$body\"}";
' <<< "$stream")

if [ -n "$out" ]; then
  printf '%s' "$out"
fi
exit 0
