# -*- coding: utf-8 -*-
"""Reproduit la règle de B10 hors moteur, sur la version corrigée ET sur la
version buguée. Voir 11_PREUVE_B10.md."""
import io, os, sys

RACINE = os.path.dirname(os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__)))))
CIBLE = os.path.join(RACINE, "scripts/ui/gameplay_shell.gd")

CORRIGE = '''	_on_notification(Textes.t("cuisine.plat_cuisine")
		% String(result.get("name", "Plat")))'''
BUGUE = '''	_on_notification("Cuisiné : %s" % String(result.get("name", "Plat")))'''

# Le chemin par frame, tel que B4 le calcule depuis `_refresh_resonance_hud`.
PAR_FRAME = {"RESONANCE_ACTIONS", "_resonance_action_line",
             "_resonance_state_line", "_refresh_resonance_hud", "_set_label"}
ACC = set("àâéèêëîïôöùûüçÉÈÊÀÎÔÛÇ")


def alpha(s):
    return s != "" and all("a" <= c.lower() <= "z" for c in s)


def sent_le_francais(t):
    if any(c in ACC for c in t):
        return True
    m = t.split(" ")
    return len(m) >= 2 and any(
        len(m[j]) >= 2 and alpha(m[j]) and m[j + 1] != "" and alpha(m[j + 1][0])
        for j in range(len(m) - 1))


def litteraux(l):
    p = l.split('"')
    return [p[i] for i in range(1, len(p), 2)]


def hors_chemin(source):
    portee, out = "", []
    for l in source.split("\n"):
        if l.startswith("func ") or l.startswith("static func "):
            portee = l[l.find("func ") + 5:]
            portee = portee[:portee.find("(")]
        elif l.startswith("const "):
            portee = l[6:].split(":")[0].split(" ")[0].split("=")[0]
        if l.strip().startswith("#"):
            continue
        for t in litteraux(l):
            if sent_le_francais(t) and portee not in PAR_FRAME:
                out.append((portee, t))
    return out


src = io.open(CIBLE, encoding="utf-8").read()
if CORRIGE not in src:
    sys.exit("ATTENDU : le site corrigé du §8 est introuvable dans %s" % CIBLE)
for nom, s in (("CORRIGÉE", src), ("BUGUÉE", src.replace(CORRIGE, BUGUE, 1))):
    h = hors_chemin(s)
    print("B10 sur la version %-9s — français hors chemin par frame : %d"
          % (nom, len(h)))
    for p, t in h:
        print("   ROUGE  %-20s %r" % (p, t))
