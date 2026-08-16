#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""PLACEMENT DERIVE DES OUTILS DE SABOTAGE — une fabrique par geometrie.

POURQUOI CE FICHIER EXISTE
==========================

MESURE DU 2026-08-16. La fabrique de controles negatifs fonctionnait sur le
candidat `cc3596c5` et echouait sur R2a-3.4 : cinq sabotages sur sept
sortaient `INEXPLOITABLE`, le booleen OUVRANT le maillage (1 bord libre,
2 a 3 aretes non-manifold, khi impair). Le refus etait correct — un vert
obtenu sur un maillage ouvert ne prouve rien — mais il rendait la batterie
inutilisable comme portail : elle ne savait mordre que sur la geometrie pour
laquelle ses constantes avaient ete ecrites.

    `--graine 2.62,2.58,0.99`   `--point 1.50,-0.40,2.00`   `--rayon 0.30`

Ces trois valeurs etaient des CONSTANTES du candidat. Sur une autre
geometrie, la graine peut tomber dans la roche, la sphere de poche peut
affleurer une paroi au lieu d'y etre noyee, et le cylindre peut raser une
lame mince — c'est-a-dire produire exactement les configurations
degenerees ou le solveur `EXACT` laisse un bord ouvert.

La parade n'est pas de regler ces trois nombres une fois par geometrie :
ce serait une fabrique calibree trois fois, pas une fabrique generique.
Elle est de les DERIVER du maillage vise, avant tout appel a Blender, et
de les publier.

CE QUI EST DERIVE, ET COMMENT
=============================

  `graine`    MODELE_SALLE releve, lu dans le script de LIEU qui accompagne
              la geometrie. C'est une donnee du couple (maillage, reperes),
              jamais une constante de fichier. Sa nature AIR est VERIFIEE.
  `degagement` distance a la surface la plus proche selon les six axes,
              MESUREE au point retenu. Elle borne le rayon des tunnels :
              un cylindre plus large que le degagement rase une paroi.
  `rayon`     fraction du plus petit degagement utile, donc derive.
  `longueur`  diagonale de la boite englobante, doublee. Un tunnel qui
              s'arreterait DANS la roche serait un cul-de-sac, pas une
              fuite, et l'oracle aurait raison de rester vert.
  `poche`     point de ROCHE le plus profond, trouve par balayage de
              colonnes : on cherche le plus epais intervalle de matiere,
              puis on confirme son degagement lateral. Une sphere noyee la
              ne peut pas affleurer.
  `bloc`      point d'AIR LIBRE au-dessus de la boite englobante. Disjonction
              garantie par construction, et verifiee par comparaison de
              boites.

Aucun de ces nombres n'est compare a un seuil de qualite : ce sont des
positions, pas des verdicts.

Usage :
    python3 tools/cave_oracle_placement.py <glb> [--reperes f.gd]
            [--pas-sonde 0.20] [--json f.json]

Codes de sortie : 0 = placements derives · 1 = derivation impossible ·
3 = BLOQUE (maillage ou reperes illisibles).
"""

import argparse
import hashlib
import json
import math
import os
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ICI)

import cave_oracle_global as G                                 # noqa: E402
import probe_cave_openings as P                                # noqa: E402

AXES = ((1.0, 0.0, 0.0), (-1.0, 0.0, 0.0),
        (0.0, 1.0, 0.0), (0.0, -1.0, 0.0),
        (0.0, 0.0, 1.0), (0.0, 0.0, -1.0))

## Part du degagement mesure qu'un cylindre a le droit d'occuper. En dessous
## de 1, il reste de l'air entre la paroi du cutter et la roche : c'est cette
## marge qui evite les faces coincidentes ou le solveur EXACT se degrade.
## Ce n'est pas un seuil de verdict — aucun controle ne le compare a rien.
PART_DEGAGEMENT = 0.55
RAYON_MIN_M = 0.08
RAYON_MAX_M = 0.30


def degagement(grille, point, portee):
    """Distance a la premiere surface selon les six axes. Rend (min, detail).

    `None` sur un axe : aucune surface rencontree — le point voit le dehors
    dans cette direction, ce qui n'est pas une contrainte de largeur.
    """
    detail = {}
    for d in AXES:
        tr = G.traversees(grille, point, d, portee)
        nom = "%+g%+g%+g" % d
        detail[nom] = round(tr[0][0], 4) if tr else None
    finis = [v for v in detail.values() if v is not None]
    return (min(finis) if finis else None), detail


def dans_air(grille, point, lo, hi):
    """Parite des traversees SOUS le point. Impair -> dans la roche.

    Lecture ecrite une seule fois, comme l'exige `tools/CLAUDE.md` : trois
    verdicts faux ont ete payes pour l'apprendre.
    """
    depart = (point[0], point[1], lo[2] - 1.0)
    portee = (hi[2] - lo[2]) + 2.0
    tr = G.traversees(grille, depart, (0.0, 0.0, 1.0), portee)
    dessous = sum(1 for t, _ in tr if depart[2] + t <= point[2])
    return dessous % 2 == 0, dessous


def intervalles_roche(grille, x, y, lo, hi):
    """Intervalles [z0, z1] de MATIERE le long de la verticale (x, y).

    Signe -1 : le rayon montant ENTRE dans le solide. Signe +1 : il en sort.
    """
    depart = (x, y, lo[2] - 1.0)
    portee = (hi[2] - lo[2]) + 2.0
    tr = G.traversees(grille, depart, (0.0, 0.0, 1.0), portee)
    zs = [(depart[2] + t, s) for t, s in tr]
    sortie = []
    entree = None
    for z, s in zs:
        if s < 0 and entree is None:
            entree = z
        elif s > 0 and entree is not None:
            sortie.append((entree, z))
            entree = None
    return sortie


def deriver_poche(triangles, grille, lo, hi, pas_sonde, bavard=True):
    """Point de roche le plus profond : plus epais intervalle, puis lateral."""
    portee = max(hi[k] - lo[k] for k in range(3)) * 2.0 + 4.0
    candidats = []
    nx = max(2, int((hi[0] - lo[0]) / pas_sonde))
    ny = max(2, int((hi[1] - lo[1]) / pas_sonde))
    for a in range(nx):
        x = lo[0] + (a + 0.5) * (hi[0] - lo[0]) / nx
        for b in range(ny):
            y = lo[1] + (b + 0.5) * (hi[1] - lo[1]) / ny
            for z0, z1 in intervalles_roche(grille, x, y, lo, hi):
                candidats.append((z1 - z0, x, y, (z0 + z1) / 2.0))
    if not candidats:
        return None
    candidats.sort(reverse=True)
    # les 24 plus epais reçoivent la mesure laterale, qui coute 6 rayons.
    meilleur = None
    for ep, x, y, z in candidats[:24]:
        p = (x, y, z)
        d, detail = degagement(grille, p, portee)
        if d is None:
            continue
        air, _ = dans_air(grille, p, lo, hi)
        if air:
            continue                       # l'intervalle etait mal lu
        if meilleur is None or d > meilleur[0]:
            meilleur = (d, p, ep, detail)
    if meilleur is None:
        return None
    d, p, ep, detail = meilleur
    if bavard:
        print("   poche  : (%.3f ; %.3f ; %.3f)  roche, epaisseur verticale "
              "%.3f m, degagement %.3f m" % (p[0], p[1], p[2], ep, d))
    return dict(point=[round(v, 4) for v in p], degagement=round(d, 4),
                epaisseur_verticale=round(ep, 4), detail=detail)


def deriver_placebo(grille, lo, hi, pas_sonde, rayon_max, bavard=True):
    """Point de la peau EXTERIEURE superieure ou la roche dessous est epaisse.

    Le premier intervalle de matiere rencontre en DESCENDANT depuis le ciel
    est la peau exterieure. On retient la colonne ou il est le plus epais :
    une sphere centree sur cette peau reste alors entierement dans la roche
    du cote interieur, et ne deborde que dans l'air libre au-dessus.
    """
    meilleur = None
    nx = max(2, int((hi[0] - lo[0]) / pas_sonde))
    ny = max(2, int((hi[1] - lo[1]) / pas_sonde))
    for a in range(nx):
        x = lo[0] + (a + 0.5) * (hi[0] - lo[0]) / nx
        for b in range(ny):
            y = lo[1] + (b + 0.5) * (hi[1] - lo[1]) / ny
            iv = intervalles_roche(grille, x, y, lo, hi)
            if not iv:
                continue
            z0, z1 = iv[-1]              # le plus haut = la peau du dessus
            ep = z1 - z0
            if meilleur is None or ep > meilleur[0]:
                meilleur = (ep, x, y, z1)
    if meilleur is None:
        return None
    ep, x, y, z = meilleur
    ## rayon borne par l'epaisseur locale : la bosse ne doit pas traverser
    ## la peau de part en part et ressortir dans la cavite.
    rayon = max(RAYON_MIN_M, min(rayon_max, 0.45 * ep))
    if bavard:
        print("   placebo: (%.3f ; %.3f ; %.3f)  peau exterieure, roche "
              "dessous %.3f m, rayon %.3f m" % (x, y, z, ep, rayon))
    return dict(point=[round(v, 4) for v in (x, y, z)],
                rayon=round(rayon, 4), epaisseur_peau=round(ep, 4))


def deriver(chemin, noeud, reperes_chemin=None, pas_sonde=0.20, bavard=True):
    racine = G.racine_depot(ICI)
    triangles, _ = P.triangles_du_glb(chemin, noeud)
    grille = P.Grille(triangles)
    lo, hi = grille.aabb()
    diag = math.sqrt(sum((hi[k] - lo[k]) ** 2 for k in range(3)))
    portee = diag * 2.0 + 4.0

    r = dict(maillage=chemin,
             sha256=hashlib.sha256(open(chemin, "rb").read()).hexdigest(),
             noeud=noeud,
             aabb=dict(lo=[round(v, 4) for v in lo],
                       hi=[round(v, 4) for v in hi],
                       diagonale=round(diag, 4)))

    reperes = G.lire_reperes(racine, reperes_chemin)
    source = reperes_chemin or os.path.join(racine, G.SCRIPT_LIEU)
    r["reperes_source"] = source
    r["reperes_sha256"] = (hashlib.sha256(open(source, "rb").read()).hexdigest()
                           if os.path.isfile(source) else None)
    if "MODELE_SALLE" not in reperes:
        r["bloque"] = "MODELE_SALLE illisible dans %s" % source
        return r

    salle = reperes["MODELE_SALLE"]
    graine = (salle[0], salle[1], salle[2] + G.GRAINE_HAUTEUR_M)
    air, dessous = dans_air(grille, graine, lo, hi)
    d_graine, detail_graine = degagement(grille, graine, portee)
    r["graine"] = dict(point=[round(v, 4) for v in graine], air=bool(air),
                       traversees_dessous=dessous,
                       degagement=round(d_graine, 4)
                       if d_graine is not None else None,
                       detail=detail_graine)
    if bavard:
        print("   graine : (%.3f ; %.3f ; %.3f)  %s  degagement %s"
              % (graine[0], graine[1], graine[2], "AIR" if air else "ROCHE",
                 "%.3f m" % d_graine if d_graine is not None else "infini"))
    if not air:
        r["bloque"] = (
            "la graine derivee de MODELE_SALLE tombe dans la ROCHE de ce "
            "maillage : le couple (maillage, reperes) est incoherent. "
            "Nommer les reperes de LA revision qui a produit ce maillage "
            "(--reperes), ou dire que la paire n'existe pas.")
        return r

    ## RAYON DERIVE. On ne veut pas qu'un cylindre rase une paroi : c'est la
    ## configuration ou le solveur EXACT laisse des bords ouverts. On prend
    ## donc une part du degagement mesure, bornee pour rester un tunnel
    ## franchissable et non une aiguille.
    if d_graine is None:
        rayon = RAYON_MAX_M
    else:
        rayon = max(RAYON_MIN_M, min(RAYON_MAX_M,
                                     PART_DEGAGEMENT * d_graine))
    r["rayon"] = round(rayon, 4)
    r["longueur"] = round(diag * 2.0, 4)
    if bavard:
        print("   rayon  : %.4f m   (= %.2f x degagement, borne a [%.2f %.2f])"
              % (rayon, PART_DEGAGEMENT, RAYON_MIN_M, RAYON_MAX_M))
        print("   longueur de tunnel : %.3f m  (2 x diagonale AABB)"
              % r["longueur"])

    poche = deriver_poche(triangles, grille, lo, hi, pas_sonde, bavard=bavard)
    if poche is None:
        r["bloque"] = "aucun point de roche assez profond pour une poche"
        return r
    ## Le rayon de poche doit tenir DANS la roche : une sphere qui affleure
    ## produit une entaille ouverte, pas une cavite interne fermee.
    r["poche"] = poche
    r["rayon_poche"] = round(max(RAYON_MIN_M,
                                 min(rayon, 0.55 * poche["degagement"])), 4)

    ## PLACEBO : une bosse a demi enfouie dans la peau EXTERIEURE, la ou la
    ## roche est epaisse. C'est une REUNION : elle ne peut ouvrir aucun
    ## passage ni isoler aucun volume, donc elle ne cree aucun defaut. Elle
    ## doit malgre tout changer le maillage pour de bon — sinon elle ne
    ## prouve rien sur la sur-sensibilite de l'oracle.
    ##
    ## On la pose sur le point du toit exterieur ou l'intervalle de matiere
    ## sous la peau est le plus epais : la sphere reste ainsi entierement
    ## dans la roche cote interieur, et deborde seulement dans l'air libre
    ## au-dessus.
    placebo = deriver_placebo(grille, lo, hi, pas_sonde, rayon, bavard)
    if placebo is None:
        r["bloque"] = "aucun point de peau exterieure epais pour un placebo"
        return r
    r["placebo"] = placebo

    ## Bloc flottant : au-dessus de la boite englobante, donc disjoint par
    ## construction. On l'ecarte de deux rayons pour que sa propre boite ne
    ## touche pas celle du massif.
    r_bloc = rayon
    bloc = ((lo[0] + hi[0]) / 2.0, (lo[1] + hi[1]) / 2.0,
            hi[2] + 3.0 * r_bloc)
    r["bloc"] = dict(point=[round(v, 4) for v in bloc],
                     rayon=round(r_bloc, 4),
                     disjoint=bool(bloc[2] - r_bloc > hi[2]))
    if bavard:
        print("   bloc   : (%.3f ; %.3f ; %.3f)  rayon %.3f  disjoint %s"
              % (bloc[0], bloc[1], bloc[2], r_bloc,
                 "OUI" if r["bloc"]["disjoint"] else "NON"))
    if not r["bloc"]["disjoint"]:
        r["bloque"] = "le bloc flottant n'est pas disjoint du massif"
    return r


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("glb")
    ap.add_argument("--noeud", default=G.NOEUD_DEFAUT)
    ap.add_argument("--reperes", default=None)
    ap.add_argument("--pas-sonde", type=float, default=0.20)
    ap.add_argument("--json", default=None)
    args = ap.parse_args()

    if not os.path.isfile(args.glb):
        print("BLOQUE : maillage introuvable : %s" % args.glb)
        return 3
    print("=" * 78)
    print("PLACEMENT DERIVE DES OUTILS DE SABOTAGE")
    print("=" * 78)
    try:
        r = deriver(args.glb, args.noeud, args.reperes, args.pas_sonde)
    except Exception as exc:                                   # noqa: BLE001
        print("BLOQUE : %s" % exc)
        return 3
    print("   maillage : %s" % r["maillage"])
    print("   sha256   : %s" % r["sha256"][:16])
    print("   reperes  : %s" % r["reperes_source"])
    if args.json:
        json.dump(r, open(args.json, "w"), indent=2)
    if r.get("bloque"):
        print()
        print("DERIVATION IMPOSSIBLE : %s" % r["bloque"])
        return 1
    print()
    print("PLACEMENTS DERIVES")
    return 0


if __name__ == "__main__":
    sys.exit(main())
