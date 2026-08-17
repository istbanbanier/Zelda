#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""RAFFINEMENT ADAPTATIF DU PORTAIL D'ETANCHEITE — 0,06 m puis 0,005 m.

POURQUOI CE FICHIER EXISTE
==========================

`docs/CONTRAT_COQUE_STRUCTURELLE.md` §5 : « Resolution du portail
d'etancheite : 0,06 m au maximum, avec raffinement adaptatif jusqu'a
0,005 m autour de toute anomalie ou couture. »

La raison est mesuree, pas theorique : le meme oracle rend VERT au pas de
0,10 m et ROUGE a 0,06 sur la MEME geometrie — le candidat `cc3596c5`,
mesure ici les deux fois. Un portail dont le pas depasse la taille du
defaut ne dit rien.

Aucune AIRE d'ouverture n'est citee ici, et c'est deliberé. La metrique
d'aire employee jusqu'au 2026-08-16 a ete RETIREE par son auteur : son
test — « depuis z = 1,50, zero traversee en montant » — comptait aussi les
colonnes dont le sommet du maillage est sous z = 1,50, confondant « toit
absent » et « enveloppe plus basse ». L'aire annoncee passait de 85,8 a
2 638 puis 47 264 cm2 selon la largeur de la fenetre, ce qu'un vrai defaut
ne fait pas. Ce qui subsiste de ce dossier, ce sont les GENRES :

    candidat cc3596c5   genre 1   (anse reelle)
    agent A  c184c8dc   genre 0
    R2a-3.4  livree     genre 2

Le genre ne depend d'aucune fenetre ni d'aucun pas.

Mais 0,005 m partout est hors de portee : la grille du massif ferait
3 900 x 3 500 x 2 800 cases, soit quarante milliards. La seule voie est le
raffinement LOCAL, et donc la question : ou raffiner ?

CE QUE CE FICHIER FAIT
======================

  1. inondation globale au pas grossier (0,06 m par defaut), qui donne la
     composante d'AIR INTERIEUR et les composantes d'AIR EXTERIEUR ;
  2. recherche des QUASI-CONTACTS : toute case d'air interieur separee
     d'une case d'air exterieur par une epaisseur de roche inferieure ou
     egale a `--sauts` cases grossieres. C'est la definition operatoire de
     « couture » : l'endroit ou la coque est trop mince pour que la grille
     grossiere puisse trancher ;
  3. autour de chaque quasi-contact, reconstruction d'une grille LOCALE au
     pas fin (0,005 m par defaut) dans une boite, et test de connexite
     entre les deux cotes DANS CETTE BOITE ;
  4. verdict : une seule boite ou le passage fin existe suffit a rougir.

CE QUE CE FICHIER NE PROUVE PAS, ET IL FAUT LE DIRE
===================================================

Il ne rend pas la grille fine PARTOUT. Une communication fine situee la ou
la grille grossiere ne voit aucun quasi-contact resterait invisible : si la
roche fait 30 cm d'epaisseur et qu'un canal de 2 mm la traverse, aucun
quasi-contact ne sera signale a 0,06 m, et aucune boite ne sera posee.

C'est un angle mort ASSUME, et c'est precisement celui que le GENRE
topologique couvre : `cave_oracle_global.py` methode A detecte une anse de
n'importe quelle largeur, sans aucune resolution, mais ne la localise pas.
Les deux instruments sont donc APPARIES et leurs journaux restent SEPARES.
Ce fichier localise ce que le genre annonce ; il ne le remplace pas.

Usage :
    python3 tools/cave_oracle_raffinement.py <glb> [--pas 0.06]
            [--pas-fin 0.005] [--sauts 2] [--boite 0.30] [--reperes f.gd]
            [--max-boites 40] [--json f.json]

Codes de sortie : 0 = aucun passage fin trouve · 1 = passage fin trouve ·
3 = BLOQUE.
"""

import argparse
import hashlib
import json
import math
import os
import sys
from collections import deque

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ICI)

import cave_oracle_global as G                                 # noqa: E402
import cave_oracle_bouche as B                                 # noqa: E402
import probe_cave_openings as P                                # noqa: E402


# ===========================================================================
# Grille locale au pas fin, bornee a une boite.
# ===========================================================================

class Boite(object):
    """Grille reguliere au pas fin sur une boite, blocage par rayons axes.

    Meme principe que `Espace` — deux cases voisines sont reliees si le
    segment joignant leurs centres ne coupe aucun triangle — mais sur un
    domaine restreint, et sans repli en segments : a cette echelle la boite
    est petite et la simplicite vaut mieux que l'astuce.
    """

    def __init__(self, triangles, lo, hi, pas):
        self.pas = pas
        self.lo = list(lo)
        self.dim = [max(2, int(math.ceil((hi[k] - lo[k]) / pas)))
                    for k in range(3)]
        self.hi = [self.lo[k] + self.dim[k] * pas for k in range(3)]
        ## Les triangles sont filtres a la boite AVANT de construire
        ## l'accelerateur : sans ce filtre, chaque boite paierait le cout
        ## du massif entier, et quarante boites couteraient quarante fois
        ## la scene complete.
        garde = []
        for t in triangles:
            mn = [min(s[k] for s in t) for k in range(3)]
            mx = [max(s[k] for s in t) for k in range(3)]
            if all(mx[k] >= self.lo[k] - pas and mn[k] <= self.hi[k] + pas
                   for k in range(3)):
                garde.append(t)
        self.triangles = garde
        self.n_tri = len(garde)
        if not garde:
            self.grille = None
            return
        self.grille = P.Grille(garde, cote=max(0.05, pas * 8))
        nx, ny, nz = self.dim
        self.bloc = [bytearray(nx * ny * nz) for _ in range(3)]
        for axe in range(3):
            self._balayer(axe)

    def rang(self, i, j, k):
        return (i * self.dim[1] + j) * self.dim[2] + k

    def centre(self, i, axe):
        return self.lo[axe] + (i + 0.5) * self.pas

    def _balayer(self, axe):
        u, v = [k for k in range(3) if k != axe]
        direction = tuple(1.0 if k == axe else 0.0 for k in range(3))
        portee = (self.hi[axe] - self.lo[axe]) + 2.0 * self.pas
        depart = self.lo[axe] - self.pas
        centres = [self.centre(m, axe) for m in range(self.dim[axe])]
        cible = self.bloc[axe]
        for iu in range(self.dim[u]):
            cu = self.centre(iu, u)
            for iv in range(self.dim[v]):
                cv = self.centre(iv, v)
                o = [0.0, 0.0, 0.0]
                o[axe] = depart
                o[u] = cu
                o[v] = cv
                ts = sorted(depart + t for t, _ in
                            G.traversees(self.grille, tuple(o), direction,
                                         portee))
                if not ts:
                    continue
                p = 0
                for m in range(self.dim[axe] - 1):
                    while p < len(ts) and ts[p] <= centres[m]:
                        p += 1
                    if p < len(ts) and ts[p] <= centres[m + 1]:
                        idx = [0, 0, 0]
                        idx[axe] = m
                        idx[u] = iu
                        idx[v] = iv
                        cible[self.rang(*idx)] = 1

    def case_de(self, point):
        idx = []
        for k in range(3):
            i = int(math.floor((point[k] - self.lo[k]) / self.pas))
            if i < 0 or i >= self.dim[k]:
                return None
            idx.append(i)
        return tuple(idx)

    def relie(self, depart, arrivees):
        """Inondation depuis `depart`. Rend `(atteintes, visitees, bord)`.

        `bord` compte les cases visitees qui TOUCHENT LE BORD DE LA BOITE,
        et il n'est pas decoratif.

        MESURE DU 2026-08-16, publiee par l'integrateur CONTRE son propre
        resultat : une aire d'ouverture annoncee a 85,8 cm2 est passee a
        2 638 puis a 47 264 cm2 a mesure que la fenetre de mesure
        s'elargissait. Un defaut ne grandit pas quand on elargit la
        fenetre : c'est la fenetre qu'on mesurait, et la metrique entiere a
        du etre retiree.

        La regle qui en sort vaut pour toute boite de raffinement : si
        l'inondation atteint le bord, le resultat est un MINORANT et la
        boite doit etre elargie. On le publie donc toujours, meme — surtout
        — quand le verdict est favorable.
        """
        nx, ny, nz = self.dim
        cibles = set(arrivees)
        vu = set([depart])
        file = deque([depart])
        atteintes = set()
        bord = 0
        while file:
            i, j, k = file.popleft()
            if (i, j, k) in cibles:
                atteintes.add((i, j, k))
            if i in (0, nx - 1) or j in (0, ny - 1) or k in (0, nz - 1):
                bord += 1
            for axe, (di, dj, dk) in enumerate(((1, 0, 0), (0, 1, 0),
                                                (0, 0, 1))):
                for signe in (1, -1):
                    i2, j2, k2 = i + di * signe, j + dj * signe, k + dk * signe
                    if not (0 <= i2 < nx and 0 <= j2 < ny and 0 <= k2 < nz):
                        continue
                    if (i2, j2, k2) in vu:
                        continue
                    a = (min(i, i2), min(j, j2), min(k, k2))
                    if self.bloc[axe][self.rang(*a)]:
                        continue
                    vu.add((i2, j2, k2))
                    file.append((i2, j2, k2))
        return atteintes, len(vu), bord


# ===========================================================================
# Quasi-contacts sur la grille grossiere.
# ===========================================================================

def quasi_contacts(espace, racine_int, trouver, groupes, sauts, bavard=True):
    """Cases d'air interieur separees de l'air EXTERIEUR par <= `sauts`.

    On ne regarde que selon les trois axes : une communication qui n'est
    fine que dans une diagonale n'existe pas physiquement, elle passe par
    une face.
    """
    nx, ny, nz = espace.dim
    lot_int = groupes[racine_int]
    interieur = set(lot_int)

    ## composantes d'AIR autres que l'interieur, touchant le bord de grille
    ## = l'exterieur. On les prend par leur racine.
    exterieures = set()
    for racine, lot in groupes.items():
        if racine == racine_int:
            continue
        if espace.nature(lot)[0] != "AIR":
            continue
        if espace.touche_bord(lot)[0]:
            exterieures.add(racine)
    if bavard:
        print("   composantes d'air exterieur retenues : %d"
              % len(exterieures))

    contacts = []
    vus = set()
    for s in lot_int:
        i, j, k0, k1 = espace.segments[s]
        for k in range(k0, k1 + 1):
            for axe, (di, dj, dk) in enumerate(((1, 0, 0), (0, 1, 0),
                                                (0, 0, 1))):
                for signe in (1, -1):
                    for d in range(1, sauts + 1):
                        i2 = i + di * signe * d
                        j2 = j + dj * signe * d
                        k2 = k + dk * signe * d
                        if not (0 <= i2 < nx and 0 <= j2 < ny
                                and 0 <= k2 < nz):
                            break
                        s2 = espace.rang_segment[espace.rang(i2, j2, k2)]
                        if s2 in interieur:
                            continue
                        if trouver(s2) in exterieures:
                            cle = (i, j, k, axe, signe)
                            if cle not in vus:
                                vus.add(cle)
                                contacts.append(dict(
                                    case=[i, j, k], axe=axe, signe=signe,
                                    sauts=d,
                                    point=[round(espace.centre(i, 0), 4),
                                           round(espace.centre(j, 1), 4),
                                           round(espace.centre(k, 2), 4)]))
                            break
    return contacts, exterieures


def grouper(contacts, rayon_cases):
    """Regroupe les quasi-contacts voisins : une couture, une boite."""
    restants = list(contacts)
    lots = []
    while restants:
        germe = restants.pop(0)
        lot = [germe]
        garde = []
        for c in restants:
            if all(abs(c["case"][k] - germe["case"][k]) <= rayon_cases
                   for k in range(3)):
                lot.append(c)
            else:
                garde.append(c)
        restants = garde
        lots.append(lot)
    return lots


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("glb", nargs="?", default=None)
    ap.add_argument("--noeud", default=G.NOEUD_DEFAUT)
    ap.add_argument("--pas", type=float, default=0.06)
    ap.add_argument("--pas-fin", type=float, default=0.005)
    ap.add_argument("--sauts", type=int, default=2,
                    help="epaisseur maximale de roche, en cases grossieres, "
                         "qui declenche un raffinement")
    ap.add_argument("--boite", type=float, default=0.30,
                    help="demi-cote de la boite fine, en metres")
    ap.add_argument("--max-boites", type=int, default=40)
    ap.add_argument("--reperes", default=None)
    ap.add_argument("--y-bouche", type=float, default=None,
                    help="par defaut : DERIVE par cave_oracle_bouche.py")
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
    reperes = G.lire_reperes(racine, args.reperes)
    if "MODELE_SALLE" not in reperes:
        print("BLOQUE : MODELE_SALLE illisible")
        return 3
    salle = reperes["MODELE_SALLE"]
    graine = (salle[0], salle[1], salle[2] + G.GRAINE_HAUTEUR_M)

    print("=" * 78)
    print("RAFFINEMENT ADAPTATIF DU PORTAIL D'ETANCHEITE")
    print("=" * 78)
    print("maillage    : %s" % chemin)
    print("sha256      : %s" % sha)
    print("pas grossier: %.4f m      pas fin : %.4f m" % (args.pas,
                                                          args.pas_fin))
    print("sauts       : %d case(s) grossiere(s)   boite : +/-%.3f m"
          % (args.sauts, args.boite))
    print()

    espace = G.Espace(triangles, args.pas)
    print("   grille grossiere %dx%dx%d, %d segment(s)"
          % (espace.dim[0], espace.dim[1], espace.dim[2],
             len(espace.segments)))

    if args.y_bouche is None:
        print("   derivation de la bouche (aucune constante) ...")
        rb = B.deriver_bouche(espace, graine, bavard=False)
        if rb.get("bloque"):
            print("BLOQUE : bouche non derivable : %s" % rb["bloque"])
            return 3
        y_bouche = rb["y_barriere"]
        j_bar = rb["j_barriere"]
        print("   bouche DERIVEE : y = %.4f  (barriere j=%d)"
              % (y_bouche, j_bar))
    else:
        y_bouche = args.y_bouche
        j_bar = None
        for j in range(espace.dim[1] - 1):
            if espace.centre(j, 1) < y_bouche <= espace.centre(j + 1, 1):
                j_bar = j
                break
        print("   bouche IMPOSEE : y = %.4f  (barriere j=%s)"
              % (y_bouche, j_bar))
    if j_bar is None:
        print("BLOQUE : plan de bouche hors grille")
        return 3

    trouver, groupes = espace.composantes(j_barriere=j_bar)
    seg = espace.segment_du_point(graine)
    if seg is None:
        print("BLOQUE : graine hors grille")
        return 3
    racine_int = trouver(seg)
    nat = espace.nature(groupes[racine_int])[0]
    print("   composante de la graine : %s, %d case(s)"
          % (nat, espace.cases_du_groupe(groupes[racine_int])))
    if nat != "AIR":
        print("BLOQUE : la graine tombe dans une composante %s ; le couple "
              "(maillage, reperes) est incoherent." % nat)
        return 3

    print()
    print("-" * 78)
    print("QUASI-CONTACTS SUR LA GRILLE GROSSIERE")
    print("-" * 78)
    contacts, exterieures = quasi_contacts(espace, racine_int, trouver,
                                           groupes, args.sauts)
    print("   quasi-contacts bruts : %d" % len(contacts))
    lots = grouper(contacts, rayon_cases=max(1, int(args.boite / args.pas)))
    print("   coutures regroupees  : %d" % len(lots))
    lots.sort(key=lambda lt: (min(c["sauts"] for c in lt), -len(lt)))
    if len(lots) > args.max_boites:
        print("   (les %d coutures les plus minces sont raffinees ; %d "
              "autres sont listees dans le JSON)"
              % (args.max_boites, len(lots) - args.max_boites))

    print()
    print("-" * 78)
    print("RAFFINEMENT LOCAL A %.4f m" % args.pas_fin)
    print("-" * 78)
    rapport_boites = []
    passages = 0
    for n, lot in enumerate(lots[:args.max_boites]):
        cx = sum(c["point"][0] for c in lot) / len(lot)
        cy = sum(c["point"][1] for c in lot) / len(lot)
        cz = sum(c["point"][2] for c in lot) / len(lot)
        lo = [cx - args.boite, cy - args.boite, cz - args.boite]
        hi = [cx + args.boite, cy + args.boite, cz + args.boite]
        boite = Boite(triangles, lo, hi, args.pas_fin)
        fiche = dict(n=n, centre=[round(cx, 4), round(cy, 4), round(cz, 4)],
                     sauts_min=min(c["sauts"] for c in lot),
                     contacts=len(lot), triangles=boite.n_tri)
        if boite.grille is None:
            fiche["etat"] = "VIDE"
            rapport_boites.append(fiche)
            continue

        ## Germes : les cases fines contenant un centre de case grossiere
        ## d'air INTERIEUR (depart) et d'air EXTERIEUR (arrivee).
        depart = None
        arrivees = []
        for c in lot:
            i, j, k = c["case"]
            pi = (espace.centre(i, 0), espace.centre(j, 1),
                  espace.centre(k, 2))
            cd = boite.case_de(pi)
            if cd is not None and depart is None:
                depart = cd
            di, dj, dk = ((1, 0, 0), (0, 1, 0), (0, 0, 1))[c["axe"]]
            d = c["sauts"] * c["signe"]
            pe = (espace.centre(i + di * d, 0), espace.centre(j + dj * d, 1),
                  espace.centre(k + dk * d, 2))
            ce = boite.case_de(pe)
            if ce is not None:
                arrivees.append(ce)
        if depart is None or not arrivees:
            fiche["etat"] = "GERMES-HORS-BOITE"
            rapport_boites.append(fiche)
            continue

        atteintes, visitees, bord = boite.relie(depart, arrivees)
        fiche["arrivees"] = len(set(arrivees))
        fiche["atteintes"] = len(atteintes)
        fiche["cases_visitees"] = visitees
        fiche["cases_au_bord_de_boite"] = bord
        fiche["tronque_par_la_boite"] = bool(bord)
        fiche["etat"] = "PASSAGE" if atteintes else "SEPARE"
        if atteintes:
            passages += 1
        print("   boite %2d  centre (%7.3f ; %7.3f ; %7.3f)  roche %d case(s) "
              "grossiere(s)  %d tri  -> %-7s  bord de boite : %s"
              % (n, cx, cy, cz, fiche["sauts_min"], boite.n_tri,
                 fiche["etat"],
                 "%d case(s) — RESULTAT MINORANT" % bord if bord
                 else "non atteint"))
        rapport_boites.append(fiche)

    print()
    print("=" * 78)
    print("boites raffinees : %d      passages fins trouves : %d"
          % (len(rapport_boites), passages))
    verdict = "ROUGE" if passages else "VERT"
    print("RAFFINEMENT : %s" % verdict)
    if not passages:
        print("   Rappel de l'angle mort : une communication fine situee la")
        print("   ou la grille grossiere ne voit aucun quasi-contact n'a pas")
        print("   ete raffinee. Le genre topologique la verrait ; il est")
        print("   publie separement par cave_oracle_global.py.")
    print("=" * 78)

    if args.json:
        json.dump(dict(maillage=chemin, sha256=sha, pas=args.pas,
                       pas_fin=args.pas_fin, sauts=args.sauts,
                       boite=args.boite, y_bouche=y_bouche,
                       contacts=len(contacts), coutures=len(lots),
                       boites=rapport_boites, passages=passages,
                       verdict=verdict),
                  open(args.json, "w"), indent=2)
    return 1 if passages else 0


if __name__ == "__main__":
    sys.exit(main())
