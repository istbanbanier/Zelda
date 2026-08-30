# -*- coding: utf-8 -*-
"""ISS-075 (tranche gameplay_shell) — inventaire REPRODUCTIBLE des littéraux.

Ce script est le miroir Python du détecteur GDScript ajouté à
`tests/integration/test_localisation_iss075.gd`. Les règles sont IDENTIQUES ;
en cas de divergence, c'est le détecteur GDScript qui fait foi (c'est lui qui
garde le dépôt), et ce script doit être réaligné.

Pourquoi le compteur officiel (tools/inventaire_textes_joueur.py) sous-compte :
  1. il ne retient un littéral QUE s'il contient un caractère accentué —
     « Cuisiner », « Reprendre », « CUISINE », « Mains nues », « Arc Link »,
     « Lien rompu » comptent zéro ;
  2. il ne lit que les chaînes entre guillemets doubles sur UNE ligne — les
     chaînes simples quotes et les triple-quotes multilignes lui échappent ;
  3. il ignore le contexte d'affichage : une valeur de table StringName→String
     affichée à l'écran n'est comptée que si elle porte un accent ;
  4. le tiret cadratin (—) et l'apostrophe droite entre lettres ne sont pas
     des signaux pour lui.

Usage :
  python3 inventaire_gameplay_shell.py <racine_worktree>            # CSV tranche
  python3 inventaire_gameplay_shell.py <racine_worktree> --tous     # comptes/fichier
"""
import io
import os
import sys

RACINE = sys.argv[1]
MODE_TOUS = "--tous" in sys.argv[2:]

ACCENTS = "àâäéèêëîïôöùûüçœÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒ"
SIGNAUX = ACCENTS + "«»…’—"
MAJ = "ÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒ"
DIAG = ("push_error", "push_warning", "printerr", "print(", "printt(",
        "print_debug", "print_rich", "assert(", "check(", "check_equal(",
        "check_approx(", "problems.append", "problemes.append",
        "erreurs.append", "errors.append", "_fail_", "_fail(")
SINKS = (".text", "tooltip_text", "_on_notification(", "_announce_resonance(",
         '"notify"')


def est_lettre(c):
    return ("a" <= c <= "z") or ("A" <= c <= "Z") or c in ACCENTS


def a_mot(s):
    """Au moins deux lettres consécutives (accents compris)."""
    run = 0
    for c in s:
        run = run + 1 if est_lettre(c) else 0
        if run >= 2:
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
    """Copie de Textes.ressemble_a_une_cle (textes.gd)."""
    if len(texte) < 3 or "." not in texte:
        return False
    if texte.startswith(".") or texte.endswith(".") or ".." in texte:
        return False
    for segment in texte.split("."):
        if not segment or not ("a" <= segment[0] <= "z"):
            return False
    for c in texte:
        ok = ("a" <= c <= "z") or ("0" <= c <= "9") or c in "._"
        if not ok:
            return False
    return True


def litteraux(source):
    """Lexer minimal : rend [(texte, ligne, precede, ctx_ligne, fonction)].

    Gère : commentaires hors chaîne, chaînes ' et ", triple-quotes multilignes,
    échappements, préfixes & et ^, fonction englobante.
    """
    lignes = source.split("\n")
    out = []
    fonction = ""
    dans_chaine = False
    quote = ""
    triple = False
    contenu = []
    ligne_debut = 0
    precede = ""
    i_ligne = 0
    while i_ligne < len(lignes):
        ligne = lignes[i_ligne]
        col = 0
        if not dans_chaine:
            nu = ligne.strip()
            if nu.startswith("func "):
                fonction = nu[5:].split("(")[0].strip()
        while col < len(ligne):
            c = ligne[col]
            if dans_chaine:
                if c == "\\" and not triple:
                    contenu.append(c)
                    if col + 1 < len(ligne):
                        contenu.append(ligne[col + 1])
                    col += 2
                    continue
                if c == "\\" and triple:
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
                break  # commentaire jusqu'à la fin de la ligne
            if c in "\"'":
                # caractère non blanc précédent, en sautant & et ^
                j = col - 1
                while j >= 0 and ligne[j] in "&^ \t":
                    j -= 1
                precede = ligne[j] if j >= 0 else ""
                triple = ligne[col:col + 3] == c * 3
                quote = c
                contenu = []
                ligne_debut = i_ligne
                dans_chaine = True
                col += 3 if triple else 1
                continue
            col += 1
        if dans_chaine and triple:
            contenu.append("\n")
        elif dans_chaine and not triple:
            # chaîne simple non fermée en fin de ligne : source invalide,
            # on referme pour ne pas avaler le fichier.
            dans_chaine = False
        i_ligne += 1
    return out


def classer(s, precede, ctx, fonction):
    """-> 'joueur' | 'developpeur' | 'technique'"""
    if s.startswith("res://") or s.startswith("user://"):
        return "technique"
    if ressemble_a_une_cle(s):
        return "technique"
    if "/" in s and " " not in s:
        return "technique"  # chemin de nœud, jamais du texte
    if not (a_mot(s) or (signal_francais(s) and a_lettre(s))):
        return "technique"  # symboles, formats purs (%s  ×%d), suffixes
    if any(d in ctx for d in DIAG):
        return "developpeur"
    if signal_francais(s):
        return "joueur"                                     # (a)
    if " " in s and a_mot(s):
        return "joueur"                                     # (b)
    if a_mot(s) and any(t in ctx for t in SINKS) \
            and (a_majuscule(s) or " " in s):
        return "joueur"                                     # (c)
    if a_mot(s) and precede == ":" and (a_majuscule(s) or " " in s):
        return "joueur"                                     # (d) valeur de table
    if a_mot(s) and fonction == "prompt_verb":
        return "joueur"                                     # (e)
    return "technique"


def scan_fichier(chemin):
    src = io.open(chemin, encoding="utf-8").read()
    return litteraux(src)


if MODE_TOUS:
    import collections
    joueur = collections.Counter()
    horsbuild = collections.Counter()
    for r, _, fs in os.walk(os.path.join(RACINE, "scripts")):
        for f in sorted(fs):
            if not f.endswith(".gd"):
                continue
            p = os.path.join(r, f)
            rel = os.path.relpath(p, RACINE).replace(os.sep, "/")
            for (s, ligne, precede, ctx, fonction) in scan_fichier(p):
                if classer(s, precede, ctx, fonction) == "joueur":
                    if rel.startswith("scripts/tools/"):
                        horsbuild[rel] += 1
                    else:
                        joueur[rel] += 1
    print("TEXTE JOUEUR (détecteur ISS-075b) : %d littéraux, %d fichiers"
          % (sum(joueur.values()), len(joueur)))
    for rel in sorted(joueur):
        print('\t"%s": %d,' % (rel, joueur[rel]))
    print("HORS BUILD (scripts/tools/) : %d littéraux, %d fichiers"
          % (sum(horsbuild.values()), len(horsbuild)))
    sys.exit(0)

# Clés proposées : littéral exact -> clé fr.json. « Arc Step » apparaît deux
# fois (table + message) et partage UNE clé ; le pluriel du Pulse éclate en
# DEUX clés (une/plusieurs) pour sortir le « s » conditionnel du code.
CLES = {
    "INVENTAIRE": "inventaire.titre",
    "Conductivité": "inventaire.conductivite",
    "Tab / Échap — Fermer": "inventaire.fermer",
    "Commandes": "menu.pause.commandes",
    "Dégâts  %.0f\\nPortée  %.1f m\\nDurabilité  %d / %d": "inventaire.detail.stats",
    "Flèches : %d": "hud.fleches",
    "Plats : %d  (F)": "hud.plats",
    "Mains nues": "hud.arme.mains_nues",
    "E — %s": "hud.invite.format",
    "%.4f rad/px": "menu.pause.sensibilite",
    "Attaque": "hud.buff.attaque",
    "Défense": "hud.buff.defense",
    "Endurance": "hud.buff.endurance",
    "Résist. élec.": "hud.buff.resist_elec",
    "%s — %d s": "hud.buff.format",
    "CUISINE": "cuisine.titre",
    "Cuisiner": "cuisine.confirmer",
    "Retirer le dernier": "cuisine.retirer_dernier",
    "Reprendre": "cuisine.reprendre",
    "Réserve de plats pleine": "cuisine.reserve_pleine",
    "Cuisiné : %s": "cuisine.fait",
    "Plat": "cuisine.plat_defaut",
    "Attaque renforcée": "cuisine.effet.attack",
    "Défense renforcée": "cuisine.effet.defense",
    "Endurance renforcée": "cuisine.effet.stamina",
    "Résistance à la foudre": "cuisine.effet.elec_resist",
    "Choisis 1 à 5 ingrédients": "cuisine.choisir",
    "Choisis (%d/5) : %s": "cuisine.choisir_compte",
    "%s — soigne %d PV": "cuisine.apercu.soin",
    "\\n%s pendant %d s": "cuisine.apercu.effet",
    "\\n(mélange instable : le soin est fortement réduit)": "cuisine.apercu.instable",
    "Le Gardien s'éveille": "boss.phase.intro",
    "Armure chargée": "boss.phase.phase1",
    "Mis à la terre — le noyau est nu": "boss.phase.grounded_stun",
    "L'armure se fend": "boss.phase.transition12",
    "Surcharge": "boss.phase.phase2",
    "SURCHARGE — le métal renvoie": "boss.phase.overload",
    "La tempête monte": "boss.phase.transition23",
    "Tempête": "boss.phase.phase3",
    "Chancelant": "boss.phase.stagger",
    "Silence": "boss.phase.dead",
    "GARDIEN DE L'ORAGE": "boss.nom",
    "Arc Link": "resonance.action.port",
    "Polarité (Maj : repousser)": "resonance.action.polarity",
    "Mise à la terre": "resonance.action.material",
    "Arc Step": "resonance.action.arc_anchor",
    "Bracelet en recharge": "resonance.refus.cooldown",
    "Aucune cible": "resonance.refus.aucune_cible",
    "Cible invalide": "resonance.refus.invalide",
    "Trop loin": "resonance.refus.hors_portee",
    "Les deux ports sont trop écartés": "resonance.refus.trop_loin",
    "Un obstacle coupe le trajet": "resonance.refus.pas_de_vue",
    "Ce n'est pas du métal": "resonance.refus.pas_metal",
    "Cet objet n'est pas chargé": "resonance.refus.pas_charge",
    "Trop lourd pour la Polarité": "resonance.refus.trop_lourd",
    "Rien à mettre à la terre": "resonance.refus.pas_de_charge",
    "Il faut les pieds au sol": "resonance.refus.pas_au_sol",
    "Mise à la terre déjà en cours": "resonance.refus.occupe",
    "Le trajet est barré": "resonance.refus.obstacle",
    "Pas de sol à l'arrivée": "resonance.refus.pas_de_sol",
    "Endurance insuffisante": "resonance.refus.endurance",
    "Cible perdue": "resonance.refus.cible_perdue",
    "Interrompu": "resonance.refus.interrompu",
    "Lien établi": "resonance.message.lien_etabli",
    "Polarité engagée": "resonance.message.polarite_engagee",
    "Impulsion — aucune cible à portée": "resonance.message.pulse_vide",
    "Impulsion — %d cible%s révélée%s":
        "resonance.message.pulse_une|resonance.message.pulse_plusieurs",
    "Lien rompu": "resonance.message.lien_rompu",
    "Mise à la terre effectuée": "resonance.message.terre_effectuee",
    "Mise à la terre annulée — %s": "resonance.message.terre_annulee",
    "Bracelet de Résonance": "resonance.viseur.titre",
    "Arc Link — relier": "resonance.viseur.lier",
    "Clic gauche : %s": "resonance.viseur.action",
    "Port retenu — vise le second port SANS lâcher G": "resonance.viseur.port_retenu",
    "Aucune cible dans l'axe — approche (18 m) et dégage la vue":
        "resonance.viseur.aucune_cible",
}

CIBLE = os.path.join(RACINE, "scripts/ui/gameplay_shell.gd")
n_joueur = 0
print("fichier;ligne;texte;contexte;classification;cle-proposee")
for (s, ligne, precede, ctx, fonction) in scan_fichier(CIBLE):
    cls = classer(s, precede, ctx, fonction)
    if cls == "technique":
        continue
    if cls == "joueur":
        n_joueur += 1
    aff = s.replace("\n", "\\n").replace(";", ",")
    print("scripts/ui/gameplay_shell.gd;%d;%s;%s;%s;%s" % (
        ligne + 1, aff, (fonction or "<module>"), cls, CLES.get(aff, "")))
sys.stderr.write("COMPTE JOUEUR gameplay_shell.gd : %d\n" % n_joueur)
