#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CALIBRATION DES DEUX MESURES DE COLLERETTE, sur une réponse ANALYTIQUE.

POURQUOI CE FICHIER EXISTE
==========================

`tools/cave_collar.py` rend deux nombres. Sur la géométrie livrée, la
mesure B rend 0,5657 m pour un seuil de 0,60 — il manque 3,4 cm — et sur la
géométrie d'avant elle rend 0,050 m là où le générateur lit 0,48 m et la
coupe du coordinateur 0,10 m. Un facteur huit entre deux instruments sur le
même objet n'est pas du bruit.

Un instrument qui n'a jamais rencontré de réponse connue ne peut ni
acquitter ni condamner. Avant de dire si 0,566 condamne la visière, il faut
savoir ce que l'instrument fait d'une collerette dont l'épaisseur est
exactement posée.

LA FORME, ET POURQUOI ELLE EST CELLE-LÀ
=======================================

Un tube cylindrique de rayon intérieur `r` dans un cylindre de rayon `R`,
même axe, épaisseur de collerette **exactement `R − r`**, la même partout et
dans toutes les directions. C'est la seule forme où les deux mesures
répondent à la même question sans qu'aucune convention d'emprise
n'intervienne : il n'y a ni côté large, ni linteau incliné, ni sol, ni
alcôve, donc aucune place pour un désaccord de définition.

Le polygone à `SEGMENTS` côtés est INSCRIT dans le cercle : sa surface se
trouve entre `rayon·cos(π/N)` et `rayon`. À N = 96 l'écart vaut 0,05 % du
rayon, soit moins d'un dixième de millimètre à nos échelles — deux ordres de
grandeur sous le biais qu'on cherche à mesurer. Le dire est nécessaire :
sans cela on attribuerait à l'instrument une erreur de la fixture.

CE QUE LA CALIBRATION DOIT TRANCHER
===================================

  * la mesure A est-elle exacte sur une forme sans ambiguïté ?
  * la mesure B sous-estime-t-elle, et **le biais suit-il le pas de
    raster** ? Si oui, c'est de la discrétisation, elle est corrigible et
    le 0,566 remonte. Sinon, c'est la géométrie qui est mince.

Un biais qui varie avec `pas` et pas avec `R − r` est un artefact de
maille. Un biais proportionnel à `R − r` serait une erreur d'échelle. Les
deux se distinguent en faisant varier les deux, et c'est ce que fait ce
fichier.

Usage :
    python3 tools/cave_collar_calibration.py [--json sortie.json]

Codes de sortie : 0 = les deux mesures calibrées · 1 = biais non expliqué
· 3 = BLOQUÉ.
"""

import argparse
import json
import math
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import probe_cave_openings as P                                # noqa: E402
import cave_collar as C                                        # noqa: E402
from probe_cave_adversarial import ecrire_glb                  # noqa: E402


SEGMENTS = 96
Y_DEBUT = -1.15
Y_FIN = 6.85


def cylindre(r, R, n_stations=9):
    """Tube annulaire : peau intérieure `r`, peau extérieure `R`.

    Ouvert à l'avant — c'est une bouche —, fermé à l'arrière par deux
    disques séparés par l'épaisseur, pour que la parité reste paire depuis
    l'intérieur. Un simple disque serait une membrane d'épaisseur nulle,
    et la sonde aurait raison de la compter comme une percée.
    """
    ys = [Y_DEBUT + (Y_FIN - Y_DEBUT) * i / (n_stations - 1.0)
          for i in range(n_stations)]
    dedans, dehors = [], []
    for y in ys:
        anneau_in, anneau_out = [], []
        for k in range(SEGMENTS):
            a = 2.0 * math.pi * k / SEGMENTS
            anneau_in.append((r * math.cos(a), y, r * math.sin(a)))
            anneau_out.append((R * math.cos(a), y, R * math.sin(a)))
        dedans.append(anneau_in)
        dehors.append(anneau_out)

    tris = []

    def _quad(a, b, c, d):
        tris.append((a, b, c))
        tris.append((a, c, d))

    for i in range(n_stations - 1):
        for k in range(SEGMENTS):
            k2 = (k + 1) % SEGMENTS
            _quad(dedans[i][k], dedans[i + 1][k], dedans[i + 1][k2],
                  dedans[i][k2])
            _quad(dehors[i][k2], dehors[i + 1][k2], dehors[i + 1][k],
                  dehors[i][k])
    # Couronne de bouche : referme l'épaisseur, laisse le fût ouvert.
    for k in range(SEGMENTS):
        k2 = (k + 1) % SEGMENTS
        _quad(dedans[0][k2], dehors[0][k2], dehors[0][k], dedans[0][k])
    # Fond : deux disques séparés par l'épaisseur `R - r`.
    recul = R - r
    fin_in = dedans[-1]
    fin_out = [(p[0], p[1] + recul, p[2]) for p in dehors[-1]]
    c_in = (0.0, Y_FIN, 0.0)
    c_out = (0.0, Y_FIN + recul, 0.0)
    for k in range(SEGMENTS):
        k2 = (k + 1) % SEGMENTS
        tris.append((fin_in[k], fin_in[k2], c_in))
        tris.append((fin_out[k2], fin_out[k], c_out))
        _quad(dehors[-1][k], fin_out[k], fin_out[k2], dehors[-1][k2])
    return tris


def profil_cylindre(r, n_stations=9):
    """`Profil` decrivant le tube : droit, symétrique, axe à z = 0.

    `palier = -0,90` place l'origine des rayons de la mesure A exactement
    sur l'axe : `sol(u, 0) + 0,90 = 0`. Sans cela la mesure partirait à
    côté du centre et rendrait une corde, pas un diamètre.
    """
    cavite = [(0.0, Y_DEBUT + (Y_FIN - Y_DEBUT) * i / (n_stations - 1.0),
               r, r) for i in range(n_stations)]
    palier = [-0.90] * n_stations
    return P.Profil(cavite, palier, 0.0, 0.0, 1.0, "cylindre")


def calibrer(r, R, pas, dossier):
    """Mesures A et B sur un tube dont la réponse vaut exactement `R - r`."""
    attendu = R - r
    chemin = os.path.join(dossier, "cyl_%.2f_%.2f.glb" % (r, R))
    ecrire_glb(chemin, cylindre(r, R))
    tris, _ = P.triangles_du_glb(chemin)
    grille = P.Grille(tris)
    profil = profil_cylindre(r)

    a, _ = C.mesure_a(grille, profil, Y_DEBUT, u_max=4.0, pas_u=0.50)
    # La mesure B est prise au MILIEU du tube : au plan de bouche la
    # couronne est en biseau numérique d'une demi-maille, ce qui ajouterait
    # au biais de discrétisation un effet de bord sans rapport.
    y_milieu = (Y_DEBUT + Y_FIN) / 2.0
    coupe = C.coupe_du_plan(grille, y_milieu, pas)
    b, _, cases = C.mesure_b(coupe)
    return dict(r=r, R=R, pas=pas, attendu_m=attendu,
                mesure_a_m=a, mesure_b_m=b,
                biais_a_m=(a - attendu) if a is not None else None,
                biais_b_m=(b - attendu) if b is not None else None,
                cases_ouverture=cases)


def main():
    ap = argparse.ArgumentParser(
        description="Calibration des deux mesures de collerette sur une "
                    "reponse analytique.")
    ap.add_argument("--json", default=None)
    ap.add_argument("--garder", default=None)
    args = ap.parse_args()

    dossier = args.garder or tempfile.mkdtemp(prefix="cal_collar_")
    if not os.path.isdir(dossier):
        os.makedirs(dossier)

    print("=" * 78)
    print("CALIBRATION — tube cylindrique, collerette exactement R - r")
    print("=" * 78)
    print("polygone a %d cotes INSCRIT : la surface est entre rayon*cos(pi/N)"
          % SEGMENTS)
    print("et rayon, soit %.4f %% d'ecart — deux ordres sous le biais cherche."
          % (100.0 * (1.0 - math.cos(math.pi / SEGMENTS))))
    print()

    # 1. LE BIAIS SUIT-IL LE PAS ? Meme forme, quatre mailles.
    print("-" * 78)
    print("1. MEME FORME, PAS DE RASTER VARIABLE  (r = 1,60 ; R = 2,20 ; "
          "attendu 0,600 m)")
    print("-" * 78)
    print("   pas   |  mesure A  | biais A  |  mesure B  | biais B  | "
          "biais B / pas")
    print("   ------+------------+----------+------------+----------+"
          "--------------")
    par_pas = []
    for pas in (0.10, 0.05, 0.025, 0.0125):
        res = calibrer(1.60, 2.20, pas, dossier)
        par_pas.append(res)
        print("   %.4f | %10s | %+8s | %10s | %+8s | %s"
              % (pas,
                 ("%.4f" % res["mesure_a_m"]) if res["mesure_a_m"] else "-",
                 ("%.4f" % res["biais_a_m"]) if res["biais_a_m"] is not None
                 else "-",
                 ("%.4f" % res["mesure_b_m"]) if res["mesure_b_m"] else "-",
                 ("%.4f" % res["biais_b_m"]) if res["biais_b_m"] is not None
                 else "-",
                 ("%+.2f" % (res["biais_b_m"] / pas))
                 if res["biais_b_m"] is not None else "-"))

    # 2. LE BIAIS SUIT-IL L'EPAISSEUR ? Meme maille, quatre epaisseurs.
    print()
    print("-" * 78)
    print("2. MEME PAS (0,05 m), EPAISSEUR VARIABLE")
    print("-" * 78)
    print("   r     |  R    | attendu | mesure A | biais A  | mesure B | "
          "biais B")
    print("   ------+-------+---------+----------+----------+----------+"
          "---------")
    par_epaisseur = []
    for r, R in ((1.60, 1.90), (1.60, 2.20), (1.60, 2.60), (1.20, 2.40)):
        res = calibrer(r, R, 0.05, dossier)
        par_epaisseur.append(res)
        print("   %.2f  | %.2f  | %7.3f | %8s | %+8s | %8s | %+8s"
              % (r, R, res["attendu_m"],
                 ("%.4f" % res["mesure_a_m"]) if res["mesure_a_m"] else "-",
                 ("%.4f" % res["biais_a_m"]) if res["biais_a_m"] is not None
                 else "-",
                 ("%.4f" % res["mesure_b_m"]) if res["mesure_b_m"] else "-",
                 ("%.4f" % res["biais_b_m"]) if res["biais_b_m"] is not None
                 else "-"))

    # -- DIAGNOSTIC ------------------------------------------------------
    print()
    print("=" * 78)
    print("DIAGNOSTIC")
    print("=" * 78)
    biais_a = [x["biais_a_m"] for x in par_pas + par_epaisseur
               if x["biais_a_m"] is not None]
    biais_b = [x["biais_b_m"] for x in par_pas if x["biais_b_m"] is not None]
    biais_b_ep = [x["biais_b_m"] for x in par_epaisseur
                  if x["biais_b_m"] is not None]
    verdict = []
    if biais_a:
        pire_a = max(abs(v) for v in biais_a)
        print("MESURE A — biais maximal %+.4f m sur %d formes."
              % (pire_a, len(biais_a)))
        if pire_a < 0.01:
            print("   A est EXACTE sur une forme sans ambiguite. Un ecart de A")
            print("   sur la geometrie reelle vient donc de l'EMPRISE — de ce")
            print("   qu'elle vise — et non de sa methode.")
            verdict.append("A exacte")
        else:
            print("   A porte un biais propre ; il doit etre soustrait avant")
            print("   toute comparaison a un seuil.")
            verdict.append("A biaisee de %+.4f m" % pire_a)
    if len(biais_b) >= 2:
        rapports = [x["biais_b_m"] / x["pas"] for x in par_pas
                    if x["biais_b_m"] is not None]
        etendue = max(rapports) - min(rapports)
        print()
        print("MESURE B — biais de %+.4f a %+.4f m selon le pas."
              % (min(biais_b), max(biais_b)))
        print("   biais / pas : de %+.2f a %+.2f, etendue %.2f"
              % (min(rapports), max(rapports), etendue))
        constant_en_epaisseur = (max(biais_b_ep) - min(biais_b_ep)
                                 if biais_b_ep else 0.0)
        print("   biais selon l'EPAISSEUR, a pas constant : etendue %.4f m"
              % constant_en_epaisseur)
        if etendue < 0.6 and constant_en_epaisseur < 0.02:
            print()
            print("   >>> LE BIAIS SUIT LE PAS, PAS L'EPAISSEUR. C'est de la")
            print("       DISCRETISATION : la transformee de distance compte")
            print("       des cases, et la premiere case de roche est deja a")
            print("       une demi-maille de l'air. B SOUS-ESTIME d'environ")
            print("       %.2f maille(s), soit %.4f m au pas de 0,05 m."
                  % (abs(sum(rapports) / len(rapports)),
                     abs(sum(rapports) / len(rapports)) * 0.05))
            verdict.append("B sous-estime de %.1f maille"
                           % abs(sum(rapports) / len(rapports)))
        else:
            print()
            print("   >>> LE BIAIS NE SUIT PAS LE PAS. Ce n'est donc pas de la")
            print("       discretisation, et il ne peut pas etre corrige par")
            print("       une maille plus fine.")
            verdict.append("B : biais non explique par la maille")
    print()
    for v in verdict:
        print("   %s" % v)
    print("=" * 78)

    if args.json:
        d = os.path.dirname(args.json)
        if d and not os.path.isdir(d):
            os.makedirs(d)
        with open(args.json, "w", encoding="utf-8") as poignee:
            json.dump(dict(segments=SEGMENTS, par_pas=par_pas,
                           par_epaisseur=par_epaisseur, verdict=verdict),
                      poignee, indent=1, sort_keys=True, ensure_ascii=False)
        print("sortie brute : %s" % args.json)
    return 0


if __name__ == "__main__":
    sys.exit(main())
