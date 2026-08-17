#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""LA LEVRE EST-ELLE UNE ARETE OU UN AMINCISSEMENT ? — le test discriminant.

LA QUESTION, ET POURQUOI AUCUNE MESURE PONCTUELLE N'Y REPOND
============================================================
Le gate d'epaisseur rend, sur `c184c8dc`, une lecture de 0,0320 m a `h =
0,15`, puis 0,0010 m a `h = 0,043`. Deux chiffres, deux ordres de grandeur,
la MEME geometrie. Demander « la levre fait-elle 3 cm ou 60 cm ? » n'a donc
pas de reponse tant qu'on n'a pas repondu a une autre question :

    la lecture CONVERGE-T-ELLE vers une valeur non nulle quand `h` diminue,
    ou tend-elle vers ZERO ?

Les deux cas sont physiquement opposes :

  * **amincissement reel** : la lecture converge vers une epaisseur `e > 0`.
    Raffiner la precise, elle ne bouge plus. Le defaut est dans la roche, et
    il faut le reparer.
  * **arete geometrique** : au contour de la bouche, la peau interieure
    REJOINT la peau exterieure. La distance de l'une a l'autre y vaut
    exactement ZERO, par construction. Un echantillon a distance `r` du
    contour lit environ `r` : la lecture est donc PROPORTIONNELLE a `h`, et
    tend vers 0 avec lui. Aucun raffinement ne la fera remonter, et aucune
    correction de la roche non plus — il n'y a rien a reparer.

`cave_check_hull.py` portait deja la phrase juste : « Au REBORD MEME de la
bouche l'epaisseur tend vers zero : c'est une arete, pas un defaut. » Il en
tirait un masque geodesique. L'addendum a remplace ce masque par une
classification qui commence a `s_dehors` — et la levre vit AU-DELA. Ce
programme mesure si ce deplacement a ouvert un trou.

CE QU'IL PUBLIE
===============
Pour chaque `h` : la lecture, la borne `min(d - r)`, l'argmin, et surtout
la DISTANCE DE L'ARGMIN AU CONTOUR DE BOUCHE. Une lecture qui suit `h` et un
argmin colle au contour signent l'arete. Une lecture stable et un argmin
loin du contour signent un amincissement.

Le rapport `lecture / h` est publie : proche d'une constante, c'est une
arete ; decroissant vers 0, c'est que la lecture a converge.

USAGE
=====
    python3 tools/cave_levre_convergence.py <fichier.glb> [options]
      --hs=0.4,0.2,0.1,0.05,0.025   suite de `h`
      --budget=400000
      --git=<objet> --git-lieu=<objet>

Code retour : 0 mesure faite · 3 BLOQUE.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cave_check_mesh as M              # noqa: E402
import cave_check_hull as H              # noqa: E402
import cave_masque_bouche as B           # noqa: E402
import cave_check_coque_deux_seuils as G  # noqa: E402


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    if not args:
        print(__doc__)
        return 3
    glb = args[0]
    ici = os.path.dirname(os.path.abspath(__file__))
    racine = B.racine_git(ici)
    hs = [float(v) for v in G.opt(argv, "hs",
                                  "0.40,0.20,0.10,0.05,0.025").split(",")]
    budget = int(float(G.opt(argv, "budget", "400000")))
    objet_gen = G.opt(argv, "git", None)
    objet_lieu = G.opt(argv, "git-lieu", None)

    print("=" * 76)
    print("LEVRE DU PORCHE — arete ou amincissement ?")
    print("=" * 76)
    print("GLB    : %s" % glb)
    print("sha256 : %s" % G.empreinte(glb))
    if objet_gen:
        tables = B.tables_depuis_git(objet_gen, racine)
    else:
        gen = os.path.join(racine, "source_assets", "blender", "environment",
                           "make_waterfall_cave.py")
        with open(gen, "r", encoding="utf-8") as f:
            tables = B.charger_tables(f.read(), gen)
    if objet_lieu:
        txt = B.texte_depuis_git(objet_lieu, racine)
        org = "git:%s" % objet_lieu
    else:
        lieu = os.path.join(racine, "scripts", "world_v2", "poi",
                            "waterfall_cave_place.gd")
        with open(lieu, "r", encoding="utf-8") as f:
            txt = f.read()
        org = lieu
    print("tables : %s" % tables["_origine"])
    print("lieu   : %s" % org)
    salle, _g = B.lire_repere_lieu(txt, "MODELE_SALLE")
    niche, _g = B.lire_repere_lieu(txt, "MODELE_NICHE")
    seuil, _g = B.lire_repere_lieu(txt, "MODELE_SEUIL_DEHORS")
    print()

    sommets, triangles = M.charger(glb, "SM_WaterfallCave", repere="modele")
    positions, faces, _st = M.souder(sommets, triangles)
    tab = M.aretes(faces)
    adj = M.graphe_dual(faces, tab)
    hach_tout = H.Hachage(positions, faces, range(len(faces)), 0.5)
    temoins = H.faces_du_dehors(positions, faces)
    _d, f_salle = hach_tout.plus_proche(salle)
    _d, f_niche = hach_tout.plus_proche(niche)
    aire = [M.aire_triangle(positions[faces[i][0]], positions[faces[i][1]],
                            positions[faces[i][2]]) for i in range(len(faces))]
    total = sum(aire)
    (x0, y0, z0), (x1, y1, z1) = M.boite(positions)
    cands = []
    s = y0 + 0.02
    while s <= min(y0 + 9.0, y1 - 0.02):
        for ct in H.contours_du_plan(positions, faces, tab, 1, s):
            ok, cote = H.separe_graine_ciel(adj, ct["aretes"], tab, f_salle,
                                            temoins)
            if not ok or f_niche not in cote:
                continue
            a_int = sum(aire[i] for i in cote)
            if a_int >= total - a_int:
                continue
            cands.append((a_int, s, ct, cote))
        s += 0.25
    if not cands:
        print("BLOQUE : coque percee, aucune barriere de bouche valide.")
        return 3
    _a, s_b, ct, cote = max(cands, key=lambda t: t[0])
    interieur = sorted(cote)
    exterieur = [i for i in range(len(faces)) if i not in set(cote)]
    pts_ct = []
    for (ia, ib) in ct["aretes"]:
        pa, pb = positions[ia], positions[ib]
        va, vb = pa[1] - s_b, pb[1] - s_b
        t = 0.5 if abs(va - vb) < 1e-12 else va / (va - vb)
        pts_ct.append(tuple(pa[k] + t * (pb[k] - pa[k]) for k in range(3)))
    print("bouche derivee a ay = %.3f | peau interieure %d faces"
          % (s_b, len(interieur)))
    hach_ext = H.Hachage(positions, faces, exterieur, 0.5)
    chemin = B.Chemin(tables)
    gab = B.Gabarit(tables["GABARIT_DEMI_LARGEUR_M"], tables["GABARIT_CLE_M"])
    _da, s_dehors, _u = chemin.projeter(seuil)
    masque = G.Masque(chemin, gab, s_dehors, s_dehors)   # la LETTRE : vide
    cells = G.cellules_initiales(positions, faces, interieur)
    print()
    print("  masque : la LETTRE de l'addendum §2.5, donc VIDE -> tout COQUE")
    print()
    print("  %-8s %-11s %-11s %-9s %-11s %s"
          % ("h vise", "lecture", "borne", "lect./h", "d(contour)",
             "argmin (ax ; ay ; az)"))
    lignes = []
    for h in hs:
        journal = {}
        etat = G.evaluer(cells, hach_ext, masque, budget, h, journal)
        e = etat["COQUE"]
        if e["argmin"] is None:
            print("  %-8.3f (aucune cellule)" % h)
            continue
        (g, fi, _dm, _fe, r) = e["argmin"]
        d_ct = min(math.dist(g, q) for q in pts_ct)
        print("  %-8.3f %-11.5f %-11.5f %-9.3f %-11.4f (%.3f ; %.3f ; %.3f)"
              % (h, e["lecture"], e["borne"], e["lecture"] / h, d_ct,
                 g[0], g[1], g[2]))
        lignes.append((h, e["lecture"], d_ct))
    print()
    if len(lignes) >= 2:
        h0, l0, _c0 = lignes[0]
        h1, l1, _c1 = lignes[-1]
        facteur_h = h0 / h1 if h1 > 0 else float("inf")
        facteur_l = l0 / l1 if l1 > 0 else float("inf")
        print("--- lecture ---")
        print("  `h` divise par %.1f  ->  lecture divisee par %.1f"
              % (facteur_h, facteur_l))
        if facteur_l >= 0.5 * facteur_h:
            print()
            print("  La lecture SUIT `h`. C'est la signature d'une ARETE :")
            print("  au contour de bouche la peau interieure rejoint la peau")
            print("  exterieure, donc un echantillon pose a distance `r` du")
            print("  contour lit environ `r`. Il n'y a pas d'epaisseur a")
            print("  mesurer la — il y a un BORD.")
            print()
            print("  Consequence, et elle ne depend pas de la geometrie : le")
            print("  gate d'epaisseur applique a une peau interieure qui")
            print("  INCLUT SON PROPRE BORD ne peut passer sur AUCUNE")
            print("  geometrie de cette famille, si soignee soit-elle.")
        else:
            print()
            print("  La lecture CONVERGE vers %.4f m sans suivre `h` : c'est"
                  % l1)
            print("  un amincissement REEL, et il est dans la roche.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
