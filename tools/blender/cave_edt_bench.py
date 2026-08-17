"""BANC EDT — passe l'instrument EDT sur les fixtures analytiques du banc.

    blender --background --python-exit-code 1 \\
        --python tools/blender/cave_edt_bench.py -- --plan <dossier>/plan.json

CE QUE CE FICHIER NE FAIT PAS, ET C'EST L'ESSENTIEL
===================================================

Il ne REIMPLEMENTE pas l'EDT. Il exec, cas par cas, le fichier
`tools/blender/probe_cave_edt_plan_bouche.py` — l'instrument lui-meme, avec
son `edt1d`, son union-find, son critere de goulot et son test de parite a
une seule direction. Un banc qui recoderait l'algorithme calibrerait sa
propre copie, pas l'outil qu'on cite ensuite.

Le seul ajout est un DIAGNOSTIC D'AIRE : on compare l'aire de roche
reellement rasterisee a l'aire analytique de la section. C'est le detecteur
du defaut de parite a une seule direction — celui qui, sur le cylindre du
banc precedent, avait declare « air libre » 18 289 cases creuses. Une
parite qui lache ne se voit pas dans le chiffre de goulot ; elle se voit
tout de suite dans l'aire.
"""

import bpy, json, math, os, sys, tempfile  # noqa: F401

ICI = os.path.dirname(os.path.abspath(__file__))
INSTRUMENT = os.path.join(ICI, "probe_cave_edt_plan_bouche.py")


def _arguments(argv):
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    opts = dict(plan=None)
    i = 0
    while i < len(argv):
        cle = argv[i].lstrip("-").replace("-", "_")
        if cle not in opts:
            raise SystemExit("[banc] argument inconnu : %s" % argv[i])
        opts[cle] = argv[i + 1]
        i += 2
    if not opts["plan"]:
        raise SystemExit("[banc] --plan est obligatoire")
    return opts


def main():
    opts = _arguments(list(sys.argv))
    plan = json.load(open(opts["plan"], encoding="utf-8"))
    dossier = os.path.dirname(os.path.abspath(opts["plan"]))
    resultats = []
    source = open(INSTRUMENT, encoding="utf-8").read()
    argv_original = list(sys.argv)

    for n, cas in enumerate(plan, 1):
        sortie = os.path.join(dossier, "edt_%s_%s.json"
                              % (cas["nom"], ("%.4f" % cas["pas"]).replace(".", "")))
        x0, x1, z0, z1 = cas["boite"]
        # On appelle l'INSTRUMENT, pas une copie de son algorithme.
        sys.argv = ["blender", "--",
                    "--glb", cas["glb"],
                    "--pas", "%.6f" % cas["pas"],
                    "--y", "%.6f" % cas["plan_y"],
                    "--x0", "%.6f" % x0, "--x1", "%.6f" % x1,
                    "--z0", "%.6f" % z0, "--z1", "%.6f" % z1,
                    "--graine-x", "%.6f" % cas["graine"][0],
                    "--graine-z", "%.6f" % cas["graine"][1],
                    "--json", sortie, "--profil", "0"]
        print()
        print("[banc] %d/%d  %s  pas %.4f" % (n, len(plan), cas["nom"],
                                              cas["pas"]))
        espace = dict(__name__="__edt__", __file__=INSTRUMENT)
        erreur = None
        try:
            exec(compile(source, INSTRUMENT, "exec"), espace)
        except SystemExit as sortie_precoce:
            erreur = str(sortie_precoce)
            print("[banc]   SORTIE PRECOCE : %s" % erreur)
        except Exception as bug:                             # noqa: BLE001
            erreur = repr(bug)
            print("[banc]   EXCEPTION : %s" % erreur)
        sys.argv = argv_original

        lu = {}
        if os.path.isfile(sortie):
            lu = json.load(open(sortie, encoding="utf-8"))

        # DIAGNOSTIC D'AIRE — le detecteur du defaut de parite.
        roche = espace.get("roche")
        pas = cas["pas"]
        cases_roche = None
        aire = None
        if roche is not None:
            cases_roche = sum(1 for col in roche for v in col if v)
            aire = cases_roche * pas * pas
        attendue = cas.get("aire_attendue_m2")
        lu.update(dict(nom=cas["nom"], pas=pas, theta_deg=cas["theta_deg"],
                       attendu_m=cas["attendu_m"], erreur=erreur,
                       cases_roche=cases_roche, aire_roche_m2=aire,
                       aire_attendue_m2=attendue))
        resultats.append(lu)
        print("[banc]   collerette %s m | cases de roche %s | aire %s m2"
              % (("%.4f" % lu["collerette_m"])
                 if lu.get("collerette_m") is not None else "AUCUNE",
                 cases_roche, ("%.3f" % aire) if aire is not None else "?"))

    chemin = os.path.join(dossier, "resultats_edt.json")
    with open(chemin, "w", encoding="utf-8") as poignee:
        json.dump(resultats, poignee, indent=1, ensure_ascii=False)
    print()
    print("[banc] %d cas -> %s" % (len(resultats), chemin))


main()
