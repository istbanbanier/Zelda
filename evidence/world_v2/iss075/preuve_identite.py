# -*- coding: utf-8 -*-
"""ISS-075 voie B — le français rendu est-il celui d'AVANT migration ?

Compare chaque valeur de `resources/localisation/fr.json` issue de cette passe
au littéral correspondant du fichier tel qu'il était au commit `8c6955c6`.

CE QUE CETTE PREUVE VAUT, ET CE QU'ELLE NE VAUT PAS. Elle compare la table à sa
source de génération : elle attrape une valeur ABÎMÉE APRÈS COUP, pas une
erreur commise PENDANT la génération. C'est exactement le piège qui s'est
produit — les échappements `\\n` recopiés bruts étaient faux dans les DEUX, donc
invisibles ici. Le bras qui a attrapé cela est le jeu de valeurs transcrit À LA
MAIN dans `tests/unit/test_textes_iss075.gd` (`FRANCAIS_ATTENDU`). Les deux sont
nécessaires ; aucun ne remplace l'autre.

  python3 evidence/world_v2/iss075/preuve_identite.py
"""
import io, json, os, subprocess, sys

RACINE = os.path.dirname(os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__)))))
BASE = "8c6955c6"
CIBLE = "scripts/ui/gameplay_shell.gd"

# Un littéral GDScript porte ses ÉCHAPPEMENTS : « \\n » y est DEUX caractères
# que le moteur décode en un saut de ligne. Les comparer sans décoder ferait
# passer pour un écart ce qui n'en est pas un — et l'inverse.
ESC = {"\\n": "\n", "\\t": "\t", "\\r": "\r", '\\"': '"', "\\'": "'",
       "\\\\": "\\"}


def decoder(v):
    out, i = [], 0
    while i < len(v):
        if v[i] == "\\" and v[i:i + 2] in ESC:
            out.append(ESC[v[i:i + 2]])
            i += 2
        else:
            out.append(v[i])
            i += 1
    return "".join(out)


avant = subprocess.run(["git", "-C", RACINE, "show", "%s:%s" % (BASE, CIBLE)],
                       capture_output=True, text=True)
if avant.returncode != 0:
    sys.exit("impossible de lire %s:%s — %s" % (BASE, CIBLE, avant.stderr.strip()))
litteraux_avant = set()
for ligne in avant.stdout.split("\n"):
    if ligne.strip().startswith("#"):
        continue
    parts = ligne.split('"')
    for i in range(1, len(parts), 2):
        litteraux_avant.add(decoder(parts[i]))

table = json.load(io.open(os.path.join(RACINE, "resources/localisation/fr.json"),
                          encoding="utf-8"))
# Les neuf clés de la tranche précédente ne viennent pas de ce fichier.
PRECEDENTES = ("camp.", "vallee.", "interaction.", "menu.options.",
               "menu.sauvegarde.")
conformes, ecarts = 0, []
for cle in sorted(k for k in table if not k.startswith("_")):
    if cle.startswith(PRECEDENTES):
        continue
    if table[cle] in litteraux_avant:
        conformes += 1
    else:
        ecarts.append((cle, table[cle]))

print("clés issues de cette passe : %d" % (conformes + len(ecarts)))
print("valeurs retrouvées MOT POUR MOT dans %s:%s : %d" % (BASE, CIBLE, conformes))
for cle, v in ecarts:
    print("   ÉCART  %-34s %r" % (cle, v))
sys.exit(1 if ecarts else 0)
