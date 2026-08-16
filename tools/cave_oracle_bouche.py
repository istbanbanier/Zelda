#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""DERIVATION DE LA BOUCHE CANONIQUE — la barriere de scellement.

POURQUOI CE FICHIER EXISTE
==========================

`docs/CONTRAT_COQUE_STRUCTURELLE.md` §2.1 exige que la barriere de bouche
soit :

  * d'EPAISSEUR NULLE — une tranche pleine de cellules ampute la cavite au
    lieu de la fermer ;
  * DERIVEE — « position obtenue par balayage du profil d'etancheite,
    publiee avec ce balayage » — et non declaree en constante ;
  * INDEPENDANTE DU VERDICT QU'ELLE SERT — « elle ne partage aucune logique
    avec le verdict qu'elle sert ».

`cave_oracle_global.py` respectait la premiere clause et violait les deux
autres : `Y_BOUCHE_DEFAUT = -1.15` est une CONSTANTE, heritee de deux oracles
condamnes. Et la seule chose qui la corroborait, `balayer_bouche()`, mesure
« a quel plan la composante de la graine cesse de toucher le bord » —
c'est-a-dire C3 lui-meme. Choisir la barriere par ce balayage rendrait C3
vrai par construction : un controle qui ne peut pas echouer.

CE QUE CE FICHIER MESURE A LA PLACE, ET POURQUOI C'EST INDEPENDANT
==================================================================

La bouche est une propriete de la FORME de la grotte, pas du verdict
d'etancheite. On la trouve donc sans jamais inonder en 3D :

  1. on decoupe le massif en TRANCHES `y` (le plan d'une barriere possible) ;
  2. dans chaque tranche, connexite strictement 2D `(x, z)` — jamais `y` ;
  3. une composante d'air de tranche est CLOSE si elle ne touche aucun bord
     de sa tranche : de la roche l'entoure de tous cotes DANS CE PLAN.
     Sinon elle est OUVERTE ;
  4. on part de la tranche de `MODELE_SALLE` et on suit la section close
     de la galerie vers l'AVANT, tranche apres tranche ;
  5. la premiere tranche ou la section cesse d'etre close est le dehors :
     la bouche est le plan qui la separe de la derniere tranche close.

Le critere d'arret — « close dans sa tranche » — est LOCAL et 2D. C3 et C4
sont GLOBAUX et 3D. Aucun seuil n'intervient : « touche le bord de sa
tranche » est un fait combinatoire, pas une valeur comparee.

Le chainage d'une tranche a la suivante emploie l'adjacence reelle (masque
`by`), et non un simple recouvrement d'indices : on suit le tunnel la ou il
passe vraiment. Ce chainage ne decide de rien — seul le critere de cloture
decide de l'arret.

CE QUE CE FICHIER NE PROUVE PAS
===============================

Que la bouche derivee est la SEULE ouverture. C'est precisement la question
de C3, et y repondre ici reintroduirait la circularite qu'on retire. Le
profil complet est publie : si une seconde ouverture existe, elle se voit
comme une seconde suite de tranches ouvertes, et le lecteur la voit.

Usage :
    python3 tools/cave_oracle_bouche.py [glb] [--pas 0.06] [--json f.json]
            [--profil]

Codes de sortie : 0 = bouche derivee · 1 = derivation impossible (la
section de la salle n'est pas close, ou aucune tranche ouverte devant) ·
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


# ===========================================================================
# Connexite 2D d'une tranche y.
# ===========================================================================

def composantes_tranche(espace, j):
    """Composantes connexes de la tranche `y = centre(j)`, en 2D `(x, z)`.

    Rend `(trouver, groupes)` sur les SEGMENTS de cette tranche. La
    connexite selon z est deja portee par le decoupage en segments : un
    segment est un intervalle z maximal sans traversee, deux segments
    empiles dans la meme colonne sont donc separes par de la matiere. Il ne
    reste qu'a relier selon x, exactement comme `Espace.composantes`, mais
    SANS jamais relier selon y.
    """
    nx, ny, _ = espace.dim
    seg = espace.segments
    col = espace.seg_de_colonne

    ids = []
    for i in range(nx):
        ids.extend(col[i * ny + j])
    rang_local = {s: n for n, s in enumerate(ids)}
    parent = list(range(len(ids)))

    def trouver_local(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def unir(a, b):
        ra, rb = trouver_local(a), trouver_local(b)
        if ra != rb:
            parent[ra] = rb

    for i in range(nx - 1):
        la, lb = col[i * ny + j], col[(i + 1) * ny + j]
        base = espace.rang(i, j, 0)
        ia = ib = 0
        while ia < len(la) and ib < len(lb):
            a, b = la[ia], lb[ib]
            a0, a1 = seg[a][2], seg[a][3]
            b0, b1 = seg[b][2], seg[b][3]
            lo = a0 if a0 > b0 else b0
            hi = a1 if a1 < b1 else b1
            if lo <= hi and espace.bx.find(0, base + lo, base + hi + 1) >= 0:
                unir(rang_local[a], rang_local[b])
            if a1 < b1:
                ia += 1
            elif b1 < a1:
                ib += 1
            else:
                ia += 1
                ib += 1

    groupes = {}
    for s in ids:
        groupes.setdefault(trouver_local(rang_local[s]), []).append(s)

    def trouver(s):
        if s not in rang_local:
            return None
        return trouver_local(rang_local[s])

    return trouver, groupes


def close_dans_sa_tranche(espace, lot):
    """Vrai si aucun segment du lot ne touche le bord de SA TRANCHE.

    Bord de tranche = `i = 0`, `i = nx-1`, `k = 0`, `k = nz-1`. Le bord
    selon `y` n'existe pas ici : c'est la direction qu'on traverse.
    """
    nx, _, nz = espace.dim
    for s in lot:
        i, _, k0, k1 = espace.segments[s]
        if i == 0 or i == nx - 1 or k0 == 0 or k1 == nz - 1:
            return False
    return True


def voisins_tranche_suivante(espace, lot, j, dj):
    """Segments de la tranche `j + dj` reellement adjacents a `lot`.

    Adjacence REELLE : le masque `by` porte le blocage `(i,j,k) ->
    (i,j+1,k)`. On suit donc le tunnel la ou il passe, pas la ou ses indices
    se recouvrent par hasard.
    """
    nx, ny, _ = espace.dim
    seg = espace.segments
    col = espace.seg_de_colonne
    j2 = j + dj
    if j2 < 0 or j2 >= ny:
        return []
    base_j = min(j, j2)
    sortie = set()
    for s in lot:
        i, _, k0, k1 = seg[s]
        base = espace.rang(i, base_j, 0)
        for t in col[i * ny + j2]:
            lo = max(k0, seg[t][2])
            hi = min(k1, seg[t][3])
            if lo <= hi and espace.by.find(0, base + lo, base + hi + 1) >= 0:
                sortie.add(t)
    return sorted(sortie)


# ===========================================================================
# Derivation.
# ===========================================================================

def deriver_bouche(espace, point_salle, bavard=True):
    """Suit la section close de la galerie vers l'avant. Rend un rapport."""
    nx, ny, nz = espace.dim
    r = dict(profil=[], bloque=None)

    case = espace.case_de(point_salle)
    if case is None:
        r["bloque"] = "le repere de salle est hors grille : %s" % (
            point_salle,)
        return r
    j_salle = case[1]
    seg_salle = espace.segment_du_point(point_salle)
    trouver, groupes = composantes_tranche(espace, j_salle)
    racine = trouver(seg_salle)
    lot = groupes[racine]
    nat, va, vr = espace.nature(lot)
    close = close_dans_sa_tranche(espace, lot)
    r["tranche_salle"] = dict(j=j_salle, y=round(espace.centre(j_salle, 1), 4),
                              nature=nat, close=close,
                              segments=len(lot),
                              cases=espace.cases_du_groupe(lot))
    if bavard:
        print("   tranche de MODELE_SALLE : j=%d  y=%.3f  section %s  %s"
              % (j_salle, espace.centre(j_salle, 1), nat,
                 "CLOSE" if close else "OUVERTE"))
    if nat != "AIR":
        r["bloque"] = ("la section de la salle est de nature %s : la "
                       "derivation part d'un point qui n'est pas dans l'air"
                       % nat)
        return r
    if not close:
        r["bloque"] = ("la section de la salle n'est pas close dans sa "
                       "tranche : la galerie y touche deja le bord de "
                       "grille, aucune bouche ne peut etre derivee en amont")
        return r

    # marche vers l'AVANT = y decroissant.
    courant = lot
    j = j_salle
    derniere_close = j_salle
    while True:
        r["profil"].append(dict(
            j=j, y=round(espace.centre(j, 1), 4), close=True,
            segments=len(courant), cases=espace.cases_du_groupe(courant),
            emprise=[[round(v, 3) for v in b]
                     for b in espace.emprise(courant)]))
        suivants = voisins_tranche_suivante(espace, courant, j, -1)
        if not suivants:
            r["bloque"] = ("la section close s'arrete a j=%d (y=%.3f) sans "
                           "atteindre de tranche ouverte : la galerie est "
                           "un cul-de-sac vers l'avant"
                           % (j, espace.centre(j, 1)))
            return r
        j2 = j - 1
        trouver2, groupes2 = composantes_tranche(espace, j2)
        lots = {}
        for t in suivants:
            racine2 = trouver2(t)
            if racine2 is not None:
                lots[racine2] = groupes2[racine2]
        # on ne retient que l'air : traverser une paroi n'est pas suivre la
        # galerie. La nature vient des voix d'orientation, pas d'un seuil.
        retenus = {rc: lt for rc, lt in lots.items()
                   if espace.nature(lt)[0] == "AIR"}
        if not retenus:
            r["bloque"] = ("aucune section d'AIR devant j=%d : la galerie "
                           "bute sur de la roche" % j)
            return r
        toutes_closes = all(close_dans_sa_tranche(espace, lt)
                            for lt in retenus.values())
        if not toutes_closes:
            # C'EST LA BOUCHE. La tranche j2 voit le dehors dans son propre
            # plan ; la tranche j est la derniere close.
            ouvertes = [rc for rc, lt in retenus.items()
                        if not close_dans_sa_tranche(espace, lt)]
            r["profil"].append(dict(
                j=j2, y=round(espace.centre(j2, 1), 4), close=False,
                segments=sum(len(retenus[rc]) for rc in ouvertes),
                cases=sum(espace.cases_du_groupe(retenus[rc])
                          for rc in ouvertes),
                emprise=None))
            derniere_close = j
            break
        courant = []
        for lt in retenus.values():
            courant.extend(lt)
        j = j2
        if j == 0:
            r["bloque"] = ("la section reste close jusqu'au bord de grille "
                           "j=0 : aucune bouche")
            return r

    j_bar = derniere_close - 1
    r["j_derniere_close"] = derniere_close
    r["j_barriere"] = j_bar
    # plan de separation entre la couche j_bar et la couche j_bar+1
    r["y_barriere"] = round(espace.centre(j_bar, 1) + espace.pas / 2.0, 4)
    r["y_bouche"] = r["y_barriere"]
    if bavard:
        print("   derniere tranche CLOSE : j=%d  y=%.3f"
              % (derniere_close, espace.centre(derniere_close, 1)))
        print("   premiere tranche OUVERTE devant : j=%d  y=%.3f"
              % (j_bar, espace.centre(j_bar, 1)))
        print("   -> BOUCHE DERIVEE : plan y = %.4f  (barriere j=%d, "
              "epaisseur nulle)" % (r["y_barriere"], j_bar))
    return r


def sonder_temoin(triangles, point, bavard=True, nom=""):
    """Sol et plafond MESURES a l'aplomb du repere, par rayon vertical.

    Publie de quoi juger un relevement : un decalage tacite au-dessus du sol
    survit trois passes sans que personne ne sache d'ou il vient, et passe
    dans la roche en silence le jour ou le sol remonte.
    """
    grille = P.Grille(triangles)
    lo, hi = grille.aabb()
    depart = (point[0], point[1], lo[2] - 1.0)
    portee = (hi[2] - lo[2]) + 2.0
    tr = G.traversees(grille, depart, (0.0, 0.0, 1.0), portee)
    zs = [depart[2] + t for t, _ in tr]
    sg = [s for _, s in tr]
    sol = plafond = None
    for z, s in zip(zs, sg):
        if s > 0 and z <= point[2]:      # sortie de matiere sous le point
            sol = z
        if s < 0 and z > point[2] and plafond is None:
            plafond = z
    # parite : nombre de traversees sous le point. Impair -> DANS la roche.
    dessous = sum(1 for z in zs if z <= point[2])
    dans_air = (dessous % 2 == 0)
    if bavard:
        print("      %-16s (%.3f ; %.3f ; %.3f) : %s   sol %s   plafond %s"
              % (nom, point[0], point[1], point[2],
                 "AIR" if dans_air else "ROCHE",
                 "%.3f" % sol if sol is not None else "-",
                 "%.3f" % plafond if plafond is not None else "-"))
    return dict(point=[round(v, 3) for v in point], dans_air=bool(dans_air),
                sol=round(sol, 4) if sol is not None else None,
                plafond=round(plafond, 4) if plafond is not None else None,
                traversees_dessous=dessous)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("glb", nargs="?", default=None)
    ap.add_argument("--noeud", default=G.NOEUD_DEFAUT)
    ap.add_argument("--pas", type=float, default=0.06)
    ap.add_argument("--profil", action="store_true",
                    help="imprime le profil de tranches complet")
    ap.add_argument("--json", default=None)
    args = ap.parse_args()

    racine = G.racine_depot(ICI)
    chemin = args.glb or os.path.join(
        racine, "assets/environment/caves/SM_WaterfallCave.glb")
    if not os.path.isfile(chemin):
        print("BLOQUE : maillage introuvable : %s" % chemin)
        return 3
    sha = hashlib.sha256(open(chemin, "rb").read()).hexdigest()
    try:
        triangles, _ = P.triangles_du_glb(chemin, args.noeud)
    except Exception as exc:                                   # noqa: BLE001
        print("BLOQUE : lecture du GLB impossible : %s" % exc)
        return 3

    reperes = G.lire_reperes(racine)
    if "MODELE_SALLE" not in reperes:
        print("BLOQUE : MODELE_SALLE illisible")
        return 3

    print("=" * 78)
    print("DERIVATION DE LA BOUCHE CANONIQUE")
    print("=" * 78)
    print("maillage : %s" % chemin)
    print("sha256   : %s" % sha)
    print("pas      : %.4f m" % args.pas)
    print()

    print("-" * 78)
    print("REPERES DE GAMEPLAY — sol et plafond MESURES a leur aplomb")
    print("-" * 78)
    sondes = {}
    for nom in sorted(reperes):
        sondes[nom] = sonder_temoin(triangles, reperes[nom], nom=nom)
    print()

    espace = G.Espace(triangles, args.pas)
    print("   grille %dx%dx%d, pas %.4f m, %d segment(s)"
          % (espace.dim[0], espace.dim[1], espace.dim[2], args.pas,
             len(espace.segments)))
    salle = reperes["MODELE_SALLE"]
    graine = (salle[0], salle[1], salle[2] + G.GRAINE_HAUTEUR_M)
    print("   graine de derivation (salle relevee de %.2f m) : "
          "(%.2f ; %.2f ; %.2f)" % (G.GRAINE_HAUTEUR_M, graine[0], graine[1],
                                    graine[2]))
    print()

    print("-" * 78)
    print("MARCHE VERS L'AVANT — connexite 2D par tranche, jamais selon y")
    print("-" * 78)
    r = deriver_bouche(espace, graine)

    if args.profil and r["profil"]:
        print()
        print("   PROFIL DE TRANCHES (de la salle vers l'avant) :")
        print("      %-6s %-9s %-8s %9s %12s" %
              ("j", "y", "section", "segments", "cases"))
        for p in r["profil"]:
            print("      %-6d %-9.3f %-8s %9d %12d"
                  % (p["j"], p["y"], "CLOSE" if p["close"] else "OUVERTE",
                     p["segments"], p["cases"]))

    rapport = dict(maillage=chemin, sha256=sha, pas=args.pas,
                   reperes={k: [round(v, 3) for v in p]
                            for k, p in reperes.items()},
                   sondes=sondes, derivation=r)
    if args.json:
        json.dump(rapport, open(args.json, "w"), indent=2)

    print()
    if r.get("bloque"):
        print("DERIVATION IMPOSSIBLE : %s" % r["bloque"])
        return 1
    print("BOUCHE DERIVEE : y = %.4f   (barriere j=%d, epaisseur nulle)"
          % (r["y_barriere"], r["j_barriere"]))
    print("   a comparer a la CONSTANTE historique Y_BOUCHE_DEFAUT = %.3f  "
          "-> ecart %.4f m" % (G.Y_BOUCHE_DEFAUT,
                               r["y_barriere"] - G.Y_BOUCHE_DEFAUT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
