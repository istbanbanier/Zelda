#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""LE MAILLAGE EST-IL VRAIMENT FERME ? — et le genre publie est-il vrai ?

POURQUOI CE FICHIER EXISTE
==========================
`tools/cave_topology_check.py` compte les aretes a 1 face (bord libre) et a
plus de 2 faces (non-manifold), puis publie `khi = V - E + F` et le genre
`(2 - khi) / 2`. Ces trois chiffres ont ete verses dans un document pousse :

    candidat cc3596c5  khi =  0   genre 1
    BASE352            khi =  4   genre non defini (4 aretes non-manifold)
    R2a-3.4 livree     khi = -2   genre 2

IL MANQUE UN TEST, ET SON ABSENCE FAUSSE `khi`.

Un SOMMET PINCE — deux nappes de surface qui se touchent en un point unique,
comme deux cones opposes par la pointe — ne cree NI bord libre NI arete
non-manifold. Toutes ses aretes ont exactement deux faces. Aucun compteur
d'aretes ne peut le voir.

Mais il fausse `khi` : ce sommet devrait compter pour DEUX sommets (un par
nappe), et il n'en compte qu'un. Chaque pincement retire donc 1 a `khi`, et
`(2 - khi) / 2` rend un demi-genre de trop.

LE TEST QUI LE VOIT — le lien de sommet
=======================================
Sur une surface fermee et manifold, le voisinage d'un sommet est un disque :
les faces qui l'entourent forment un anneau unique. Son LIEN — le graphe
forme par les aretes opposees a `v` dans chacune de ses faces — est donc un
CYCLE UNIQUE.

    lien connexe, tous degres = 2   -> sommet sain
    lien a k cycles, k > 1          -> SOMMET PINCE, (k-1) pincements
    un degre != 2                   -> bord libre ou non-manifold incident

`khi` corrige = `khi` naif + somme des pincements.

CE QUE CE TEST NE PEUT PAS FAIRE
================================
Il ne dit rien de l'auto-intersection : deux nappes qui se traversent sans
partager de sommet restent invisibles ici. C'est une limite reelle, et le
genre corrige ne la couvre pas non plus.

USAGE
=====
    python3 tools/cave_check_closure.py <a.glb> [<b.glb> ...] [--noeud NOM]

Code retour : 0 tous fermes et sains · 1 au moins un defaut · 3 lecture
impossible.
"""

import hashlib
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cave_check_mesh as M  # noqa: E402


def empreinte(chemin):
    h = hashlib.sha256()
    with open(chemin, "rb") as f:
        for bloc in iter(lambda: f.read(1 << 20), b""):
            h.update(bloc)
    return h.hexdigest()


def lien_du_sommet(faces_du_sommet, faces, v):
    """Rend (nb_cycles, degre_max) du lien de `v`.

    Le lien est le graphe dont les aretes sont, pour chaque face incidente a
    `v`, l'arete opposee a `v` dans cette face.
    """
    adj = defaultdict(list)
    for fi in faces_du_sommet:
        a, b, c = faces[fi]
        autres = [s for s in (a, b, c) if s != v]
        if len(autres) != 2:
            continue
        u, w = autres
        adj[u].append(w)
        adj[w].append(u)
    if not adj:
        return 0, 0
    degre_max = max(len(v2) for v2 in adj.values())
    vus = set()
    cycles = 0
    for depart in adj:
        if depart in vus:
            continue
        cycles += 1
        pile = [depart]
        vus.add(depart)
        while pile:
            n = pile.pop()
            for m in adj[n]:
                if m not in vus:
                    vus.add(m)
                    pile.append(m)
    return cycles, degre_max


def analyser(chemin, nom_noeud):
    sommets, triangles = M.charger(chemin, nom_noeud, repere="modele")
    positions, faces, stats = M.souder(sommets, triangles)
    tab = M.aretes(faces)

    bords_libres = [a for a, inc in tab.items() if len(inc) == 1]
    non_manifold = [a for a, inc in tab.items() if len(inc) > 2]

    adj = M.graphe_dual(faces, tab)
    etiq, nb_comp = M.composantes_faces(faces, adj)

    # Orientation coherente : sur chaque arete manifold, les deux faces
    # doivent parcourir l'arete en sens OPPOSES. Sinon `(2 - khi) / 2`
    # n'est pas un genre.
    sens = defaultdict(list)
    for fi, (a, b, c) in enumerate(faces):
        for u, v in ((a, b), (b, c), (c, a)):
            cle = (u, v) if u < v else (v, u)
            sens[cle].append(1 if u < v else -1)
    incoherentes = sum(1 for a, inc in tab.items()
                       if len(inc) == 2 and sum(sens[a]) != 0)

    # Faces incidentes a chaque sommet, par composante.
    par_comp = defaultdict(lambda: defaultdict(list))
    for fi, (a, b, c) in enumerate(faces):
        k = etiq[fi]
        for s in (a, b, c):
            par_comp[k][s].append(fi)

    comps = []
    pinces_total = 0
    for k in range(nb_comp):
        f_idx = [i for i in range(len(faces)) if etiq[i] == k]
        sommets_k = par_comp[k]
        # Degre d'arete compte DANS la composante, pas globalement. Sans
        # cela, une arete que la composante partage avec une lamelle
        # exterieure la ferait declarer ouverte alors qu'elle est close sur
        # elle-meme — c'est le cas de BASE352, dont le corps principal est
        # une surface fermee de genre 1 accompagnee de 4 lamelles a volume
        # nul.
        deg_k = defaultdict(int)
        for fi in f_idx:
            a, b, c = faces[fi]
            for u, v in ((a, b), (b, c), (c, a)):
                deg_k[(u, v) if u < v else (v, u)] += 1
        aretes_k = set(deg_k)
        V, E, F = len(sommets_k), len(aretes_k), len(f_idx)
        khi_naif = V - E + F
        bords_k = sum(1 for d in deg_k.values() if d == 1)
        nm_k = sum(1 for d in deg_k.values() if d > 2)
        partagees_k = sum(1 for a, d in deg_k.items()
                          if d == 2 and len(tab[a]) > 2)

        pinces = 0
        details_pinces = []
        anormaux = 0
        for v, fs in sommets_k.items():
            cycles, dmax = lien_du_sommet(fs, faces, v)
            if dmax != 2:
                anormaux += 1
                continue
            if cycles > 1:
                pinces += cycles - 1
                details_pinces.append((v, cycles, positions[v]))
        pinces_total += pinces

        khi_corrige = khi_naif + pinces
        ferme_k = (bords_k == 0 and nm_k == 0)
        genre = None
        if ferme_k and incoherentes == 0 and khi_corrige % 2 == 0:
            genre = (2 - khi_corrige) // 2

        aire_k = sum(M.aire_triangle(positions[faces[i][0]],
                                     positions[faces[i][1]],
                                     positions[faces[i][2]]) for i in f_idx)
        comps.append({
            "id": k, "V": V, "E": E, "F": F, "aire": aire_k,
            "khi_naif": khi_naif, "khi_corrige": khi_corrige,
            "pinces": pinces, "details_pinces": details_pinces,
            "sommets_anormaux": anormaux, "ferme": ferme_k, "genre": genre,
            "bords_k": bords_k, "nm_k": nm_k, "partagees_k": partagees_k,
        })

    # Sommets partages entre plusieurs composantes de faces : ce ne sont pas
    # des pincements au sens de `khi` (chaque composante reste saine), mais
    # ce sont des points de contact et il faut les nommer.
    appartenance = defaultdict(set)
    for fi, (a, b, c) in enumerate(faces):
        for s in (a, b, c):
            appartenance[s].add(etiq[fi])
    partages = sum(1 for s, cs in appartenance.items() if len(cs) > 1)

    return {
        "chemin": chemin, "sha256": empreinte(chemin), "noeud": nom_noeud,
        "stats": stats, "positions": positions, "faces": faces,
        "bords_libres": len(bords_libres), "non_manifold": len(non_manifold),
        "incoherentes": incoherentes, "nb_comp": nb_comp,
        "comps": comps, "pinces_total": pinces_total,
        "partages_inter_comp": partages,
        "boite": M.boite(positions),
    }


def imprimer(r):
    print("=" * 74)
    print("FICHIER : %s" % r["chemin"])
    print("sha256  : %s" % r["sha256"])
    print("noeud   : %s   (leve si absent — pas de repli sur COL_)" % r["noeud"])
    s = r["stats"]
    print("soudure : %d sommets bruts -> %d soudes (%d doublons fusionnes)"
          % (s["sommets_bruts"], s["sommets_soudes"], s["doublons_fusionnes"]))
    print("          %d triangles -> %d retenus (%d degeneres retires)"
          % (s["triangles_bruts"], s["triangles_retenus"],
             s["triangles_degeneres"]))
    (x0, y0, z0), (x1, y1, z1) = r["boite"]
    print("boite modele : x[%.3f %.3f] ay[%.3f %.3f] az[%.3f %.3f]"
          % (x0, x1, y0, y1, z0, z1))
    print("-" * 74)
    print("aretes a 1 face  (bord libre)   : %d" % r["bords_libres"])
    print("aretes a >2 faces (non-manifold): %d" % r["non_manifold"])
    print("aretes mal orientees            : %d" % r["incoherentes"])
    print("SOMMETS PINCES (lien a >1 cycle): %d      <-- LE TEST QUI MANQUAIT"
          % r["pinces_total"])
    print("sommets partages entre composantes : %d" % r["partages_inter_comp"])
    print("composantes de faces : %d" % r["nb_comp"])
    print("-" * 74)
    for c in r["comps"]:
        print("  comp %d : V=%d E=%d F=%d  aire %.6f m2"
              % (c["id"], c["V"], c["E"], c["F"], c["aire"]))
        print("           dans la composante : %d bord(s) libre(s), "
              "%d non-manifold, %d arete(s) partagee(s) au dehors"
              % (c["bords_k"], c["nm_k"], c["partagees_k"]))
        print("           khi naif = %d   pincements = %d   khi CORRIGE = %d"
              % (c["khi_naif"], c["pinces"], c["khi_corrige"]))
        if c["genre"] is None:
            print("           genre : NON DEFINI (ouvert, mal oriente, ou khi impair)")
        else:
            print("           genre = %d %s" % (
                c["genre"],
                "(sphere — aucune anse)" if c["genre"] == 0 else "(ANSES)"))
        if c["sommets_anormaux"]:
            print("           sommets a lien non cyclique : %d"
                  % c["sommets_anormaux"])
        for (v, cyc, p) in c["details_pinces"][:12]:
            print("           pince : sommet %d, %d nappes, "
                  "modele (%.4f ; %.4f ; %.4f)" % (v, cyc, p[0], p[1], p[2]))
        if len(c["details_pinces"]) > 12:
            print("           ... et %d autres" % (len(c["details_pinces"]) - 12))
    print()


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    noeud = "SM_WaterfallCave"
    for a in argv[1:]:
        if a.startswith("--noeud="):
            noeud = a.split("=", 1)[1]
    if not args:
        print(__doc__)
        return 3

    defaut = False
    for chemin in args:
        if not os.path.exists(chemin):
            print("ABSENT : %s" % chemin)
            return 3
        try:
            r = analyser(chemin, noeud)
        except M.ErreurGLB as e:
            print("LECTURE IMPOSSIBLE : %s" % e)
            return 3
        imprimer(r)
        if (r["bords_libres"] or r["non_manifold"] or r["incoherentes"]
                or r["pinces_total"]):
            defaut = True

    print("=" * 74)
    if defaut:
        print("VERDICT : au moins une geometrie porte un defaut de fermeture.")
        return 1
    print("VERDICT : toutes fermees, manifold, orientees, sans sommet pince.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
