# -*- coding: utf-8 -*-
"""ISS-075 — sépare le texte JOUEUR du texte DIAGNOSTIC.
La distinction EST le livrable : traduire un log de moteur serait du bruit,
ne pas traduire un message d'écran serait le défaut.

RÉÉCRIT le 2026-08-30 (tranche gameplay_shell). L'ancienne version ne
comptait un littéral QUE s'il contenait un caractère accentué : « Cuisiner »,
« CUISINE », « Mains nues », « Arc Link » et les 35 entrées des tables du HUD
comptaient ZÉRO — c'est la cause racine du « 39 » publié quand le fichier en
portait 76. Le tiret cadratin (U+2014) était absent de son jeu de signaux, et
U+2019 y figurait alors que le dépôt n'en contient aucun : entrée morte, et
piège — une apostrophe typographisée aurait fait monter le compte sans texte
nouveau.

Cette version est le MIROIR du détecteur qui fait foi :
`tests/integration/test_localisation_iss075.gd` (A9). Pour les `.gd` : même
lexer (chaînes ' et ", triple-quotes multilignes, échappements, commentaires
hors chaîne) et même classement — signal français (accents, «»…’—, apostrophe
droite entre lettres), multi-mots avec espace, porte d'affichage (.text,
tooltip_text, _on_notification(, _announce_resonance(, "notify"), position
valeur-de-table (précédé de « : »), fonction englobante prompt_verb. Pour les
`.tscn`/`.tres`, que le détecteur GDScript ne couvre pas : propriétés
d'affichage sérialisées (text, tooltip_text, display_name, …) ou contenu
portant un signal/multi-mots. En cas de divergence avec le détecteur
GDScript, c'est LUI qui a raison et ce miroir qui se corrige.

Usage : python3 tools/inventaire_textes_joueur.py [racine] [dump.json]
"""
import collections
import io
import json
import os
import re
import sys

RACINE = sys.argv[1] if len(sys.argv) > 1 else \
    os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ACCENTS = "àâäéèêëîïôöùûüçœÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒ"
SIGNAUX = ACCENTS + "«»…’—"
MAJ = "ÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒ"
DIAG = ("push_error", "push_warning", "printerr", "print(", "printt(",
        "print_debug", "print_rich", "assert(", "check(", "check_equal(",
        "check_approx(", "problems.append", "problemes.append",
        "erreurs.append", "errors.append", "_fail_", "_fail(")
SINKS = (".text", "tooltip_text", "_on_notification(", "_announce_resonance(",
         '"notify"')
# Scènes/scripts qui ne partent jamais dans une partie jouée.
DEV = re.compile(r"^(scripts/tools/|scenes/tests/|tools/|tests/)")
# Propriétés sérialisées (.tscn/.tres) dont la valeur finit à l'écran.
PROPS_AFFICHAGE = re.compile(
    r"^\s*(text|tooltip_text|placeholder_text|display_name|window_title|"
    r"dialog_text|ok_button_text|cancel_button_text)\s*=")
PROP_LIT = re.compile(r'^\s*[A-Za-z0-9_/]+\s*=\s*"([^"\\]*(?:\\.[^"\\]*)*)"')


def est_lettre(c):
    return ("a" <= c <= "z") or ("A" <= c <= "Z") or c in ACCENTS


def a_mot(s):
    """Au moins deux lettres consécutives (accents compris)."""
    suite = 0
    for c in s:
        suite = suite + 1 if est_lettre(c) else 0
        if suite >= 2:
            return True
    return False


def a_lettre(s):
    return any(est_lettre(c) for c in s)


def a_majuscule(s):
    return any(("A" <= c <= "Z") or c in MAJ for c in s)


def signal_francais(s):
    if any(c in SIGNAUX for c in s):
        return True
    # apostrophe DROITE entre deux lettres : l'axe, s'éveille, L'ORAGE
    for i in range(1, len(s) - 1):
        if s[i] == "'" and est_lettre(s[i - 1]) and est_lettre(s[i + 1]):
            return True
    return False


def ressemble_a_une_cle(texte):
    """Copie de Textes.ressemble_a_une_cle (scripts/localisation/textes.gd)."""
    if len(texte) < 3 or "." not in texte:
        return False
    if texte.startswith(".") or texte.endswith(".") or ".." in texte:
        return False
    for segment in texte.split("."):
        if not segment or not ("a" <= segment[0] <= "z"):
            return False
    for c in texte:
        if not (("a" <= c <= "z") or ("0" <= c <= "9") or c in "._"):
            return False
    return True


def litteraux_gd(source):
    """Lexer .gd : [(texte, ligne0, precede, ctx_ligne, fonction)]."""
    lignes = source.split("\n")
    out = []
    fonction = ""
    dans_chaine = False
    quote = ""
    triple = False
    contenu = []
    ligne_debut = 0
    precede = ""
    for i, ligne in enumerate(lignes):
        if not dans_chaine:
            nu = ligne.strip()
            if nu.startswith("func "):
                fonction = nu[5:].split("(")[0].strip()
        col = 0
        while col < len(ligne):
            c = ligne[col]
            if dans_chaine:
                if c == "\\":
                    contenu.append(c)
                    if col + 1 < len(ligne):
                        contenu.append(ligne[col + 1])
                    col += 2
                    continue
                if triple and ligne[col:col + 3] == quote * 3:
                    out.append(("".join(contenu), ligne_debut, precede,
                                lignes[ligne_debut], fonction))
                    dans_chaine = False
                    col += 3
                    continue
                if not triple and c == quote:
                    out.append(("".join(contenu), ligne_debut, precede,
                                lignes[ligne_debut], fonction))
                    dans_chaine = False
                    col += 1
                    continue
                contenu.append(c)
                col += 1
                continue
            if c == "#":
                break
            if c in "\"'":
                j = col - 1
                while j >= 0 and ligne[j] in "&^ \t":
                    j -= 1
                precede = ligne[j] if j >= 0 else ""
                triple = ligne[col:col + 3] == c * 3
                quote = c
                contenu = []
                ligne_debut = i
                dans_chaine = True
                col += 3 if triple else 1
                continue
            col += 1
        if dans_chaine:
            if triple:
                contenu.append("\n")
            else:
                dans_chaine = False  # chaîne non fermée : source invalide
    return out


def classer_gd(s, precede, ctx, fonction):
    """-> 'joueur' | 'developpeur' | 'technique' (miroir du détecteur A9)."""
    if s.startswith("res://") or s.startswith("user://"):
        return "technique"
    if ressemble_a_une_cle(s):
        return "technique"
    if "/" in s and " " not in s:
        return "technique"  # chemin de nœud
    if not (a_mot(s) or (signal_francais(s) and a_lettre(s))):
        return "technique"  # symboles, formats purs, suffixes
    if any(d in ctx for d in DIAG):
        return "developpeur"
    if signal_francais(s):
        return "joueur"
    if " " in s and a_mot(s):
        return "joueur"
    if a_mot(s) and (a_majuscule(s) or " " in s):
        if any(t in ctx for t in SINKS):
            return "joueur"
        if precede == ":":
            return "joueur"  # valeur de table — &"attack": "Attaque"
    if a_mot(s) and fonction == "prompt_verb":
        return "joueur"
    return "technique"


def joueur_serialise(ligne, s):
    """.tscn/.tres : la propriété est affichée, ou le contenu parle français."""
    if s.startswith("res://") or s.startswith("user://"):
        return False
    if ressemble_a_une_cle(s):
        return False
    if "/" in s and " " not in s:
        return False
    if not (a_mot(s) or (signal_francais(s) and a_lettre(s))):
        return False
    if PROPS_AFFICHAGE.match(ligne):
        return True
    return signal_francais(s) or (" " in s and a_mot(s))


def walk(d, ext):
    for r, _, fs in os.walk(os.path.join(RACINE, d)):
        if "/.godot" in r:
            continue
        for f in sorted(fs):
            if f.endswith(ext):
                yield os.path.join(r, f)


joueur = collections.defaultdict(list)
diag = collections.Counter()
dev = collections.Counter()

for p in walk("scripts", ".gd"):
    rel = os.path.relpath(p, RACINE).replace(os.sep, "/")
    src = io.open(p, encoding="utf-8").read()
    for (s, ligne0, precede, ctx, fonction) in litteraux_gd(src):
        cls = classer_gd(s, precede, ctx, fonction)
        if cls == "technique":
            continue
        if DEV.match(rel):
            dev[rel] += 1
        elif cls == "developpeur":
            diag[rel] += 1
        else:
            joueur[rel].append((ligne0 + 1, s))

for ext, dirs in ((".tscn", ["scenes"]), (".tres", ["resources"])):
    for d in dirs:
        for p in walk(d, ext):
            rel = os.path.relpath(p, RACINE).replace(os.sep, "/")
            for i, ligne in enumerate(io.open(p, encoding="utf-8"), 1):
                m = PROP_LIT.match(ligne)
                if m is None:
                    continue
                s = m.group(1)
                if not joueur_serialise(ligne, s):
                    continue
                if DEV.match(rel):
                    dev[rel] += 1
                else:
                    joueur[rel].append((i, s))

nj = sum(len(v) for v in joueur.values())
print("TEXTE JOUEUR    : %4d littéraux, %d fichiers" % (nj, len(joueur)))
print("TEXTE DIAGNOSTIC: %4d littéraux, %d fichiers" % (sum(diag.values()), len(diag)))
print("HORS BUILD JOUÉ : %4d littéraux, %d fichiers" % (sum(dev.values()), len(dev)))
print()
print("=== TEXTE JOUEUR, par fichier ===")
for rel, v in sorted(joueur.items(), key=lambda kv: (-len(kv[1]), kv[0])):
    print("%4d  %s" % (len(v), rel))
if len(sys.argv) > 2:
    json.dump({k: v for k, v in joueur.items()},
              io.open(sys.argv[2], "w", encoding="utf-8"),
              ensure_ascii=False, indent=1)
