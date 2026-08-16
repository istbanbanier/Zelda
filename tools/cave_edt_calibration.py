#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""BANC DE CALIBRATION ELARGI — dalles inclinees, frontieres irregulieres.

POURQUOI CE FICHIER EXISTE, ET CE QUE LE BANC PRECEDENT NE POUVAIT PAS VOIR
==========================================================================

`tools/cave_collar_calibration.py` mesure les deux instruments de collerette
sur un tube cylindrique. Il a rendu un service reel : il a montre que la
mesure B sous-estimait d'exactement une maille, et la correction `+ pas` en
est sortie.

Mais un cylindre concentrique a une propriete qui le rend AVEUGLE a la
question suivante : son epaisseur est la meme dans TOUTES les directions.
Le minimum est donc atteint aussi bien le long de X que dans n'importe
quelle diagonale, et une metrique de chanfrein — qui ne se trompe QUE hors
des axes — y rend le bon chiffre pour une mauvaise raison.

Or `cave_collar.mesure_b` n'est pas une distance euclidienne : c'est un
DIJKSTRA 8-CONNEXE de poids {1, racine de 2}. Un chanfrein {1, V2}
SUR-ESTIME l'euclidien d'un facteur `(max + 0,4142 x min) / hypot`, soit
+8,24 % a 22,5 degres, +5,25 % a 36 degres, et exactement 0 a 0 et
45 degres. Sur un cercle aligne a la grille, ce terme est nul. Sur le
jambage reel de la grotte, incline a 36 degres, il ne l'est pas.

C'est la clef possible de la tension d'etalonnage restee ouverte : la
methode B non corrigee lit 0,5657 au pas 0,05, l'EDT lit 0,5657 au pas 0,04.
Deux pas differents, le meme nombre a quatre decimales — presente comme une
convergence. Or `10 x 0,04 = 0,40 = 8 x 0,05` et `0,40 x V2 = 0,5657` : les
deux nombres peuvent n'etre que LA MEME DIAGONALE DE MAILLE vue deux fois.

PREDICTION FALSIFIABLE, ecrite AVANT la mesure
==============================================

  * biais(B) ~ +(chanfrein(theta) - 1) x t : maximal a 22,5 deg, NUL a 0 et
    45 deg. Il depend de l'ANGLE, pas du pas.
  * biais(EDT) : independant de theta, et compris entre 0 et +pas selon la
    PHASE de la forme dans la grille. Sur une dalle d'epaisseur `t = m x pas`
    la lecture vaut `t` si `m` est pair et `t + pas` si `m` est impair.
  * biais(A) : proche de zero partout, A ne discretise rien.

Si ces trois-la ne se verifient pas, la prediction est fausse et il faut le
dire aussi nettement que si elle tenait.

LES FORMES, ET CE QUE CHACUNE TRANCHE
=====================================

Toutes sont des TUBES : peau interieure, peau exterieure, bouche ouverte,
fond ferme — la meme topologie que le banc precedent, pour que le passage
de l'un a l'autre ne change qu'une variable.

  `anneau_centre`     deux cercles concentriques. Le temoin : l'epaisseur
                      est la meme dans toutes les directions, theta n'a
                      aucun sens, et les trois instruments doivent coincider.

  `decentre_XXdeg`    peau exterieure DECALEE de `d` dans la direction
                      `theta + 180`. L'ecart minimal vaut alors exactement
                      `R - r - d`, il est atteint EN UN POINT, et la
                      direction de ce minimum est `theta`. C'est la seule
                      facon d'imposer un angle a la mesure sans changer
                      autre chose.

  `bruite`            rayon exterieur module par trois harmoniques a phases
                      fixes : une frontiere irreguliere, non alignee a la
                      grille, dont la reponse reste calculable exactement.

  `fente_sous_maille` CONTROLE NEGATIF CONNU. Ecart de 0,03 m pour un pas de
                      0,04 : la roche est plus mince qu'une case. On SAIT
                      que les instruments doivent echouer. Un banc dont
                      aucune forme n'echoue ne calibre rien — il ne fait que
                      confirmer ce qu'on esperait.

  `rasant`            rayon exterieur pose EXACTEMENT sur un centre de case,
                      pour eprouver le test de parite a une seule direction
                      que l'EDT a herite. C'est le defaut qui, sur le
                      cylindre du banc precedent, avait declare « air
                      libre » 18 289 cases creuses.

LA REPONSE DE REFERENCE N'EST PAS LE CERCLE IDEAL
=================================================

Elle est la distance minimale entre les deux POLYGONES REELLEMENT
EXPORTES. Le maillage est un 96-gone, pas un cercle ; prendre `R - r` comme
verite attribuerait a l'instrument l'erreur de la fixture. On calcule donc
point-a-segment entre les deux polylignes fermees, ce qui est exact au
maillage pres et coute quelques centaines de milliers d'operations.

USAGE
=====

    python3 tools/cave_edt_calibration.py --etape fixtures --dossier <d>
    blender --background --python-exit-code 1 \\
        --python tools/blender/cave_edt_bench.py -- --plan <d>/plan.json
    python3 tools/cave_edt_calibration.py --etape verdict --dossier <d>

L'etape `fixtures` ecrit les GLB, mesure A et B, et emet `plan.json`.
L'etape blender mesure l'EDT sur LES MEMES OCTETS. L'etape `verdict`
joint les deux et publie le tableau.
"""

import argparse
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import probe_cave_openings as P                                # noqa: E402
import cave_collar as C                                        # noqa: E402
from probe_cave_adversarial import ecrire_glb                  # noqa: E402

SEGMENTS = 96
Y_DEBUT = -1.15
Y_FIN = 6.85


# ---------------------------------------------------------------------------
# LES FORMES
# ---------------------------------------------------------------------------

def _contour(rayon_de, n=SEGMENTS, centre=(0.0, 0.0)):
    """Polygone ferme de la section, dans le plan (x, z)."""
    pts = []
    for k in range(n):
        a = 2.0 * math.pi * k / n
        r = rayon_de(a)
        pts.append((centre[0] + r * math.cos(a), centre[1] + r * math.sin(a)))
    return pts


def _bruit(amplitude, graine):
    """Modulation deterministe du rayon — trois harmoniques, phases fixes."""
    phases = [1.1 + 0.7 * graine, 2.3 + 0.3 * graine, 0.4 + 1.9 * graine]

    def _f(a):
        return amplitude * (0.60 * math.sin(3.0 * a + phases[0])
                            + 0.30 * math.sin(7.0 * a + phases[1])
                            + 0.25 * math.sin(11.0 * a + phases[2]))
    return _f


def section(forme):
    """(polygone interieur, polygone exterieur) d'une forme du banc."""
    r, R = forme["r"], forme["R"]
    d = forme.get("d", 0.0)
    theta = math.radians(forme.get("theta_deg", 0.0))
    amp = forme.get("bruit", 0.0)
    graine = forme.get("graine", 0)
    # LE DECALAGE VA DANS `theta + 180` : l'ecart minimal se creuse donc du
    # cote `theta`, et c'est LUI qui porte la direction qu'on veut imposer.
    centre_ext = (-d * math.cos(theta), -d * math.sin(theta))
    f = _bruit(amp, graine) if amp else (lambda a: 0.0)
    dedans = _contour(lambda a: r)
    dehors = _contour(lambda a: R + f(a), centre=centre_ext)
    return dedans, dehors


def _dist_point_segment(p, a, b):
    vx, vy = b[0] - a[0], b[1] - a[1]
    wx, wy = p[0] - a[0], p[1] - a[1]
    ll = vx * vx + vy * vy
    t = 0.0 if ll <= 0.0 else max(0.0, min(1.0, (wx * vx + wy * vy) / ll))
    dx, dy = a[0] + t * vx - p[0], a[1] + t * vy - p[1]
    return math.hypot(dx, dy)


def reponse_exacte(dedans, dehors, densite=40):
    """Distance minimale entre les DEUX POLYGONES EXPORTES.

    On densifie la polyligne interieure — un sommet tous les `densite`-iemes
    d'arete — puis on prend la distance point-a-segment vers l'exterieure.
    L'erreur residuelle est celle de la densification, bornee par la moitie
    d'un sous-segment, soit moins de 1e-4 m a nos echelles ; deux ordres
    sous le biais cherche.
    """
    pire = None
    n_in, n_out = len(dedans), len(dehors)
    for i in range(n_in):
        a0, a1 = dedans[i], dedans[(i + 1) % n_in]
        for s in range(densite):
            t = s / float(densite)
            p = (a0[0] + t * (a1[0] - a0[0]), a0[1] + t * (a1[1] - a0[1]))
            for j in range(n_out):
                d = _dist_point_segment(p, dehors[j], dehors[(j + 1) % n_out])
                if pire is None or d < pire:
                    pire = d
    return pire


def _lacet(pts):
    """Aire d'un polygone ferme, formule du lacet. Sert au DIAGNOSTIC
    D'AIRE : une parite qui lache ne se voit pas dans le chiffre de goulot,
    elle se voit tout de suite dans l'aire rasterisee."""
    s = 0.0
    n = len(pts)
    for i in range(n):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % n]
        s += x1 * y2 - x2 * y1
    return abs(s) / 2.0


def maillage(dedans, dehors, n_stations=9):
    """Tube ferme, meme topologie que `cave_collar_calibration.cylindre`."""
    ys = [Y_DEBUT + (Y_FIN - Y_DEBUT) * i / (n_stations - 1.0)
          for i in range(n_stations)]
    peau_in = [[(p[0], y, p[1]) for p in dedans] for y in ys]
    peau_out = [[(p[0], y, p[1]) for p in dehors] for y in ys]
    tris = []

    def _quad(a, b, c, d):
        tris.append((a, b, c))
        tris.append((a, c, d))

    n = len(dedans)
    for i in range(n_stations - 1):
        for k in range(n):
            k2 = (k + 1) % n
            _quad(peau_in[i][k], peau_in[i + 1][k],
                  peau_in[i + 1][k2], peau_in[i][k2])
            _quad(peau_out[i][k2], peau_out[i + 1][k2],
                  peau_out[i + 1][k], peau_out[i][k])
    # Couronne de bouche : referme l'epaisseur, laisse le fut ouvert.
    for k in range(n):
        k2 = (k + 1) % n
        _quad(peau_in[0][k2], peau_out[0][k2], peau_out[0][k], peau_in[0][k])
    # Fond : deux disques separes, pour que la parite reste paire dedans.
    recul = 0.60
    fin_in = peau_in[-1]
    fin_out = [(p[0], p[1] + recul, p[2]) for p in peau_out[-1]]
    c_in = (0.0, Y_FIN, 0.0)
    c_out = (0.0, Y_FIN + recul, 0.0)
    for k in range(n):
        k2 = (k + 1) % n
        tris.append((fin_in[k], fin_in[k2], c_in))
        tris.append((fin_out[k2], fin_out[k], c_out))
        _quad(peau_out[-1][k], fin_out[k], fin_out[k2], peau_out[-1][k2])
    return tris


def profil_de(r):
    """`Profil` droit centre sur l'axe, pour la mesure A."""
    n = 9
    cavite = [(0.0, Y_DEBUT + (Y_FIN - Y_DEBUT) * i / (n - 1.0), r, r)
              for i in range(n)]
    return P.Profil(cavite, [-0.90] * n, 0.0, 0.0, 1.0, "banc")


# ---------------------------------------------------------------------------
# LE PLAN D'EXPERIENCE
# ---------------------------------------------------------------------------

## Ecart vise 0,80 m : l'erreur de chanfrein predite vaut alors +0,066 m a
## 22,5 degres, tres au-dessus du pas de 0,04. Avec un ecart de 0,30 m elle
## serait de 0,025 m, sous le pas, et la mesure ne trancherait rien.
ECART = 0.80
R_INT = 1.60
DECALAGE = 0.60

PAS_CONVERGENCE = (0.10, 0.05, 0.04, 0.025)
PAS_COURANT = (0.05, 0.04)


def plan_experience():
    formes = []
    formes.append(dict(nom="anneau_centre", r=R_INT, R=R_INT + ECART,
                       d=0.0, theta_deg=0.0,
                       pas=PAS_CONVERGENCE, role="temoin, convergence"))
    for theta in (0.0, 18.0, 22.5, 36.0, 45.0):
        pas = PAS_CONVERGENCE if abs(theta - 22.5) < 1e-9 else PAS_COURANT
        formes.append(dict(nom="decentre_%04.1fdeg" % theta, r=R_INT,
                           R=R_INT + ECART + DECALAGE, d=DECALAGE,
                           theta_deg=theta, pas=pas,
                           role="angle impose %.1f deg" % theta))
    formes.append(dict(nom="bruite", r=R_INT, R=R_INT + ECART + 0.30,
                       d=0.30, theta_deg=27.0, bruit=0.18, graine=7,
                       pas=PAS_COURANT, role="frontiere irreguliere"))
    formes.append(dict(nom="fente_sous_maille", r=R_INT, R=R_INT + 0.03,
                       d=0.0, theta_deg=0.0, pas=PAS_COURANT,
                       role="CONTROLE NEGATIF : la roche est plus mince "
                            "qu'une case, les instruments DOIVENT echouer"))
    # `rasant` : R choisi pour qu'un CENTRE de case tombe exactement sur la
    # tangente x = R au pas de 0,04, afin d'eprouver la parite a une seule
    # direction. Boite = R + 1,50 -> X0 = -(R+1,50) ; centre de case i a
    # X0 + (i+0,5) x pas ; on veut (2R + 1,50) / pas = i + 0,5.
    formes.append(dict(nom="rasant", r=R_INT, R=2.20, d=0.0, theta_deg=0.0,
                       pas=PAS_COURANT, marge=1.50,
                       role="tangente posee sur un centre de case"))
    return formes


def etape_fixtures(dossier):
    formes = plan_experience()
    plan = []
    print("=" * 78)
    print("BANC ELARGI — fixtures, reponse exacte, mesures A et B")
    print("=" * 78)
    print("polygone a %d cotes ; la reponse de reference est la distance "
          "minimale" % SEGMENTS)
    print("entre les DEUX POLYGONES EXPORTES, pas `R - r`.")
    print()
    entete = ("   %-20s | %5s | %8s | %8s | %8s | %8s | %8s"
              % ("forme", "pas", "attendu", "A", "biais A", "B", "biais B"))
    print(entete)
    print("   " + "-" * (len(entete) - 3))
    for forme in formes:
        dedans, dehors = section(forme)
        attendu = reponse_exacte(dedans, dehors)
        chemin = os.path.join(dossier, "%s.glb" % forme["nom"])
        ecrire_glb(chemin, maillage(dedans, dehors))
        tris, _ = P.triangles_du_glb(chemin)
        grille = P.Grille(tris)
        profil = profil_de(forme["r"])
        a, _ = C.mesure_a(grille, profil, Y_DEBUT, u_max=4.0, pas_u=0.50)
        aire = _lacet(dehors) - _lacet(dedans)
        rayon_max = max(math.hypot(*p) for p in dehors)
        marge = forme.get("marge", 0.60)
        boite = [-(rayon_max + marge), rayon_max + marge,
                 -(rayon_max + marge), rayon_max + marge]
        for pas in forme["pas"]:
            y_milieu = (Y_DEBUT + Y_FIN) / 2.0
            coupe = C.coupe_du_plan(grille, y_milieu, pas)
            b, _, cases = C.mesure_b(coupe)
            print("   %-20s | %5.3f | %8.4f | %8s | %+8s | %8s | %+8s"
                  % (forme["nom"], pas, attendu,
                     ("%.4f" % a) if a is not None else "-",
                     ("%.4f" % (a - attendu)) if a is not None else "-",
                     ("%.4f" % b) if b is not None else "-",
                     ("%.4f" % (b - attendu)) if b is not None else "-"))
            plan.append(dict(nom=forme["nom"], role=forme["role"],
                             theta_deg=forme["theta_deg"], pas=pas,
                             glb=os.path.abspath(chemin),
                             attendu_m=attendu, plan_y=y_milieu,
                             boite=boite, graine=[0.0, 0.0],
                             mesure_a_m=a, biais_a_m=(a - attendu)
                             if a is not None else None,
                             mesure_b_m=b, biais_b_m=(b - attendu)
                             if b is not None else None,
                             cases_ouverture=cases,
                             aire_attendue_m2=aire))
    chemin_plan = os.path.join(dossier, "plan.json")
    with open(chemin_plan, "w", encoding="utf-8") as poignee:
        json.dump(plan, poignee, indent=1, ensure_ascii=False)
    print()
    print("plan : %s  (%d cas)" % (chemin_plan, len(plan)))
    print("etape suivante : blender --background --python-exit-code 1 \\")
    print("    --python tools/blender/cave_edt_bench.py -- --plan %s"
          % chemin_plan)
    return 0


# ---------------------------------------------------------------------------
# VERDICT
# ---------------------------------------------------------------------------

def chanfrein(theta_deg):
    """Facteur de sur-estimation d'un chanfrein 8-connexe {1, V2}."""
    a = math.radians(theta_deg % 90.0)
    c, s = abs(math.cos(a)), abs(math.sin(a))
    return (max(c, s) + (math.sqrt(2.0) - 1.0) * min(c, s)) / math.hypot(c, s)


def etape_verdict(dossier):
    plan = json.load(open(os.path.join(dossier, "plan.json"),
                          encoding="utf-8"))
    chemin_edt = os.path.join(dossier, "resultats_edt.json")
    if not os.path.isfile(chemin_edt):
        print("BLOQUE : %s absent — l'etape blender n'a pas tourne."
              % chemin_edt)
        return 3
    edt = {(e["nom"], round(e["pas"], 6)): e
           for e in json.load(open(chemin_edt, encoding="utf-8"))}

    print("=" * 78)
    print("VERDICT — trois instruments, memes octets, meme reponse de "
          "reference")
    print("=" * 78)
    entete = ("   %-20s | %5s | %7s | %+7s | %+7s | %+7s | %+7s"
              % ("forme", "pas", "attendu", "biais A", "biais B",
                 "biais EDT", "predit B"))
    print(entete)
    print("   " + "-" * (len(entete) - 3))
    lignes = []
    for cas in plan:
        cle = (cas["nom"], round(cas["pas"], 6))
        e = edt.get(cle)
        biais_edt = None
        lecture_edt = None
        if e and e.get("collerette_m") is not None:
            lecture_edt = e["collerette_m"]
            biais_edt = lecture_edt - cas["attendu_m"]
        predit = (chanfrein(cas["theta_deg"]) - 1.0) * cas["attendu_m"]
        print("   %-20s | %5.3f | %7.4f | %7s | %7s | %7s | %7.4f"
              % (cas["nom"], cas["pas"], cas["attendu_m"],
                 ("%+.4f" % cas["biais_a_m"])
                 if cas["biais_a_m"] is not None else "AUCUNE",
                 ("%+.4f" % cas["biais_b_m"])
                 if cas["biais_b_m"] is not None else "AUCUNE",
                 ("%+.4f" % biais_edt) if biais_edt is not None else "AUCUNE",
                 predit))
        lignes.append(dict(cas, lecture_edt_m=lecture_edt,
                           biais_edt_m=biais_edt, predit_chanfrein_m=predit,
                           edt=e))

    print()
    print("-" * 78)
    print("1. LA PREDICTION SUR B : biais(B) suit-il l'ANGLE ?")
    print("-" * 78)
    angulaires = [x for x in lignes if x["nom"].startswith("decentre")
                  and x["biais_b_m"] is not None]
    for pas in sorted({x["pas"] for x in angulaires}):
        serie = sorted((x for x in angulaires if x["pas"] == pas),
                       key=lambda x: x["theta_deg"])
        if not serie:
            continue
        print("   pas %.3f :" % pas)
        for x in serie:
            print("      theta %5.1f deg : biais B %+.4f m, predit %+.4f m, "
                  "ecart %+.4f m"
                  % (x["theta_deg"], x["biais_b_m"], x["predit_chanfrein_m"],
                     x["biais_b_m"] - x["predit_chanfrein_m"]))
    if angulaires:
        ecarts = [abs(x["biais_b_m"] - x["predit_chanfrein_m"])
                  for x in angulaires]
        pire = max(ecarts)
        print("   ecart maximal a la prediction : %.4f m" % pire)
        if pire < 0.02:
            print("   >>> LA PREDICTION TIENT. Le biais de B est le terme de")
            print("       CHANFREIN, il depend de l'angle et pas du pas. La")
            print("       correction `+ pas` est donc juste sur un cercle")
            print("       aligne et INCOMPLETE sur une frontiere inclinee.")
        else:
            print("   >>> LA PREDICTION NE TIENT PAS. Le biais de B n'est pas")
            print("       explique par le chanfrein seul.")

    print()
    print("-" * 78)
    print("2. LA PREDICTION SUR L'EDT : biais entre 0 et +pas, INDEPENDANT "
          "de theta ?")
    print("-" * 78)
    avec_edt = [x for x in lignes if x["biais_edt_m"] is not None
                and x["nom"] != "fente_sous_maille"]
    for x in sorted(avec_edt, key=lambda v: (v["nom"], v["pas"])):
        dans = -1e-9 <= x["biais_edt_m"] <= x["pas"] + 1e-9
        print("      %-20s pas %5.3f : biais EDT %+.4f m  (0..%+.3f) %s"
              % (x["nom"], x["pas"], x["biais_edt_m"], x["pas"],
                 "OK" if dans else "<-- HORS DE LA BANDE PREDITE"))
    if avec_edt:
        hors = [x for x in avec_edt
                if not (-1e-9 <= x["biais_edt_m"] <= x["pas"] + 1e-9)]
        angles_edt = [x for x in avec_edt if x["nom"].startswith("decentre")]
        if angles_edt:
            etendue = (max(x["biais_edt_m"] for x in angles_edt)
                       - min(x["biais_edt_m"] for x in angles_edt))
            print("   etendue du biais EDT sur les angles : %.4f m" % etendue)
        print("   %d cas sur %d hors de la bande [0, pas]."
              % (len(hors), len(avec_edt)))

    print()
    print("-" * 78)
    print("3. LE CONTROLE NEGATIF — la fente sous la maille")
    print("-" * 78)
    for x in lignes:
        if x["nom"] != "fente_sous_maille":
            continue
        vu_b = x["mesure_b_m"] is not None and x["cases_ouverture"] > 0
        e = x.get("edt") or {}
        vu_edt = (e.get("collerette_m") is not None
                  and not e.get("ouverture_deja_reliee", False))
        print("      pas %5.3f (ecart pose %.3f m) : B %s | EDT %s"
              % (x["pas"], x["attendu_m"],
                 ("%.4f m" % x["mesure_b_m"]) if x["mesure_b_m"] is not None
                 else "AUCUNE",
                 ("%.4f m" % e["collerette_m"])
                 if e.get("collerette_m") is not None else "AUCUNE"))
        print("         l'instrument ECHOUE comme attendu : B %s, EDT %s"
              % ("non" if vu_b else "oui", "non" if vu_edt else "oui"))

    print()
    print("-" * 78)
    print("4. LE CONTROLE RASANT — la parite a une seule direction de l'EDT")
    print("-" * 78)
    for x in lignes:
        if x["nom"] != "rasant":
            continue
        e = x.get("edt") or {}
        print("      pas %5.3f : biais EDT %s ; cases de roche %s ; "
              "aire rasterisee %s m2 pour %s m2 attendus"
              % (x["pas"],
                 ("%+.4f m" % x["biais_edt_m"])
                 if x["biais_edt_m"] is not None else "AUCUNE",
                 e.get("cases_roche", "?"),
                 ("%.3f" % e["aire_roche_m2"])
                 if e.get("aire_roche_m2") is not None else "?",
                 ("%.3f" % e["aire_attendue_m2"])
                 if e.get("aire_attendue_m2") is not None else "?"))
        if (e.get("aire_roche_m2") is not None
                and e.get("aire_attendue_m2")):
            ecart = abs(e["aire_roche_m2"] - e["aire_attendue_m2"])
            part = ecart / e["aire_attendue_m2"]
            print("         ecart d'aire %.1f %% — %s"
                  % (100.0 * part,
                     "la parite tient" if part < 0.03
                     else "LA PARITE A UNE SEULE DIRECTION A LACHE"))

    chemin = os.path.join(dossier, "verdict.json")
    with open(chemin, "w", encoding="utf-8") as poignee:
        json.dump(lignes, poignee, indent=1, ensure_ascii=False)
    print()
    print("verdict brut : %s" % chemin)
    print("=" * 78)
    print("RAPPEL DE VOCABULAIRE : aucune de ces trois mesures n'est une")
    print("« distance exacte ». Chacune est une distance exacte SUR SA")
    print("GRILLE. Ce qu'on publie a cote d'un seuil est une BORNE")
    print("INFERIEURE, valable pour LA CLASSE DE FORMES DE CE BANC.")
    print("=" * 78)
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--etape", choices=("fixtures", "verdict"),
                    required=True)
    ap.add_argument("--dossier", required=True)
    args = ap.parse_args()
    if not os.path.isdir(args.dossier):
        os.makedirs(args.dossier)
    if args.etape == "fixtures":
        return etape_fixtures(args.dossier)
    return etape_verdict(args.dossier)


if __name__ == "__main__":
    sys.exit(main())
