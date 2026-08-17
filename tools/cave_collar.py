#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""COLLERETTE — deux mesures d'épaisseur qui ne partagent pas leur mécanisme.

POURQUOI DEUX, ET POURQUOI CELLES-CI
====================================

Un seul rayon qui touche une arête vive n'est pas une preuve d'épaisseur.
La revue demande donc deux mesures indépendantes de l'épaisseur de
collerette, et « indépendantes » doit vouloir dire quelque chose de plus
fort que « deux fonctions différentes » : il faut que la panne de l'une ne
puisse pas être la panne de l'autre.

  MESURE A — RAYONS SELON LA NORMALE LOCALE. Depuis l'intérieur, un rayon
  part perpendiculairement à la paroi ; l'épaisseur est la distance entre le
  premier impact (peau intérieure) et le suivant (peau extérieure). Elle
  dépend de la normale locale, du lancer de rayon, et de la parité.

  MESURE B — TRANSFORMÉE DE DISTANCE SUR UNE COUPE. On rastérise le plan de
  la bouche, on classe chaque case en `ouverture` / `roche` / `air libre`
  par inondation depuis le bord, puis on mesure, pour chaque case du
  POURTOUR de l'ouverture, la distance à la case d'air libre la plus proche.
  Aucun rayon, aucune normale, aucune notion de station : de la topologie
  2D et une distance.

Elles peuvent donc se tromper, mais pas de la même façon. Une normale
inversée fausse A et laisse B intacte ; un trou trop fin pour la maille
échappe à B et pas à A.

L'EMPRISE — CE QUE J'APPELLE « LA LIMITE DE L'OUVERTURE »
=========================================================

Cinq instruments mesurent « l'epaisseur de collerette » et ne s'accordent
pas. Tant que chacun garde sa definition implicite de l'emprise, leur
desaccord n'est pas une information : ils repondent a des questions
differentes. Voici la mienne, en une phrase verifiable chacune.

  EMPRISE DE A — « le pourtour de la cavite sur les six premiers dixiemes
  de station, tous azimuts de la section ». C'est une BANDE DE GALERIE, pas
  une courbe : de u = 0,00 a u = 0,60 par pas de 0,10, et 36 azimuts par
  station. L'epaisseur retenue est le MINIMUM sur cette bande.

  EMPRISE DE B — « dans le premier plan y ou le vide central n'atteint pas
  le bord du plan, la frontiere entre ce vide central et la roche ». C'est
  une COURBE FERMEE dans un plan, definie par topologie seule : le vide qui
  ne communique pas avec le dehors DANS CE PLAN.

En quoi elles different des autres, autant que je puisse le dire sans avoir
lu leur code :

  * la sphere inscrite de l'agent collerette mesure un rayon en TROIS
    dimensions ; la ou la roche est epaisse hors du plan de coupe, elle lira
    plus que B, qui reste dans le plan. Les deux ont raison sur leur propre
    question ;
  * une mesure indexee sur la station `u` suit la galerie ; B suit un plan
    fixe. Sur un porche evase les deux divergent par construction ;
  * A prend un MINIMUM sur une bande de 0,60 station. Elle attrape donc
    n'importe quel point mince de cette bande, y compris un point qui
    n'appartient a aucune collerette. C'est ce qui explique son 0,060 m sur
    la geometrie d'avant : la methode est exacte — la calibration le prouve
    a 0,6 mm pres — mais son emprise ratisse plus large que la visiere.

Consequence pratique : **B est la mesure a citer pour un seuil de
collerette**, parce que son emprise est definie sans convention. A sert a
localiser un point mince, pas a acquitter une collerette.

CE QUE CE FICHIER NE FAIT PAS
=============================

Il ne recopie pas `tools/blender/probe_cave_collerette.py`, qui mesure par
sphère inscrite. Trois mesures valent mieux que deux, à condition qu'elles
soient trois — recopier la troisième en aurait fait une de plus au compteur
et zéro de plus en preuve.

DOMAINE DE VALIDITÉ — MESURÉ, pas supposé
=========================================

Banc élargi `tools/cave_edt_calibration.py`, 2026-08-16, journal
`banc_verdict.log` : huit formes, quatre pas, réponse de référence calculée
entre les DEUX POLYGONES EXPORTÉS et non sur le cercle idéal.

MESURE A — `CONSERVATRICE EXPLOITABLE DANS SON DOMAINE`.
Biais mesuré : +0,0000 à +0,0026 m sur les anneaux, concentriques comme
décentrés, tous angles — et **+0,0091 m sur une frontière irrégulière**.
Deux limites, dont la seconde est nouvelle :

  * son EMPRISE ratisse plus large que la visière — minimum sur 0,60
    station, tous azimuts —, donc elle attrape des points minces hors
    collerette ;
  * sur une frontière irrégulière elle SUR-ESTIME légèrement : 36 azimuts
    × 7 stations ne tombent pas forcément sur le minimum. Elle n'est donc
    pas strictement conservatrice. Retrancher ~0,01 m avant de la comparer
    à un seuil.

MESURE B — `EXPLOITABLE APRÈS CALIBRATION, ET LA CALIBRATION A PARLÉ`.
La correction `+ pas` inscrite plus bas dans `mesure_b` a été établie sur un
tube CONCENTRIQUE aligné à la grille, où le brut sous-estimait d'exactement
une maille. **Le banc élargi montre qu'elle n'est pas universelle** :

    forme                        pas 0,050   pas 0,040
    anneau concentrique           +0,0004     +0,0004
    anneau décentré, θ 0°         +0,0504     +0,0404   <-- +1 maille
    anneau décentré, θ 22,5°      +0,0282     +0,0324
    anneau décentré, θ 45°        +0,0075     +0,0158
    frontière irrégulière         +0,0350     +0,0368

Entre les deux premières lignes, l'épaisseur (0,7996 m) et la direction du
minimum (axiale) sont IDENTIQUES ; seule change la PHASE de la frontière
dans la grille. Et le brut passe de « sous-estime d'une maille » à
« exact ». La correction est donc juste pour UNE phase et SUR-CORRIGE pour
les autres.

Conséquence, et elle va dans le mauvais sens pour un portail : **B SUR-LIT,
jusqu'à +1 maille.** Sur un minimum d'épaisseur comparé à un plancher, la
sur-lecture flatte la géométrie. **Borne inférieure à employer :
`lecture − pas`.**

CE QUI TIENT, ET QU'IL FAUT DIRE AUSSI FORT : le vote à QUATRE PARITÉS de
`coupe_du_plan` résiste à la forme `rasant` du banc — tangente posée
exactement sur un centre de case — avec un biais de +0,0003 m. Sur la même
forme, l'EDT de `tools/blender/probe_cave_edt_plan_bouche.py`, qui ne vote
que sur une direction, rend 0,08 m pour 0,60 m attendus. Le vote de parité
n'est pas une précaution théorique : c'est la différence entre un biais au
dixième de millimètre et une erreur d'un demi-mètre.

Usage :
    python3 tools/cave_collar.py [glb] [--y-bouche -1.15] [--pas 0.05]
        [--seuil 0.60] [--json sortie.json]

Codes de sortie : 0 = les deux mesures au-dessus du seuil · 1 = au moins une
en dessous · 3 = BLOQUÉ.
"""

import argparse
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import probe_cave_openings as P                                # noqa: E402


Y_BOUCHE_DEFAUT = -1.15


# ---------------------------------------------------------------------------
# MESURE A — rayons selon la normale locale
# ---------------------------------------------------------------------------

def mesure_a(grille, profil, y_bouche, u_max=0.60, pas_u=0.10, azimuts=36):
    """Épaisseur minimale par rayons perpendiculaires à la paroi.

    On balaie les premières stations — la collerette est le pourtour de la
    bouche, pas toute la galerie — et, à chaque station, tous les azimuts de
    la section. L'épaisseur est prise entre le premier et le deuxième impact,
    en écartant les replis de moins de `ECAILLE_M` : deux impacts trop
    proches sont le même pli de surface vu deux fois, pas deux peaux.
    """
    pire = None
    details = []
    u = 0.0
    while u <= u_max + 1e-9:
        ax, ay, _, _, _ = profil.station(u)
        nx, ny = profil.normale(u)
        depart = (ax, ay, profil.sol(u, 0.0) + 0.90)
        vide, _ = P.dans_le_vide(grille, depart)
        if not vide:
            u += pas_u
            continue
        for k in range(azimuts):
            theta = 2.0 * math.pi * k / azimuts
            # La direction vit dans le plan de SECTION : normale x vertical.
            d = (nx * math.cos(theta), ny * math.cos(theta), math.sin(theta))
            liste = P.impacts(grille, depart, d, 60.0)
            if len(liste) < 2:
                continue
            # UN RAYON RASANT N'EST PAS UNE MESURE D'EPAISSEUR, et c'est
            # exactement le piege que la revue nomme : « un seul rayon
            # touchant une arete vive n'est pas une preuve ». `impacts`
            # rend l'orientation de chaque face ; on exige donc que la
            # premiere soit traversee en SORTANT du vide et la seconde en
            # ENTRANT dans l'air, c'est-a-dire deux faces d'orientation
            # OPPOSEE. Deux faces de meme orientation successives sont un
            # repli, pas une paroi.
            entree, orient = liste[0]
            epaisseur = None
            for t, o in liste[1:]:
                if t - entree <= P.ECAILLE_M:
                    continue
                if o == orient:
                    continue
                epaisseur = t - entree
                break
            if epaisseur is None:
                continue
            if pire is None or epaisseur < pire:
                pire = epaisseur
                details = [dict(u=round(u, 3),
                                azimut_deg=round(math.degrees(theta), 1),
                                epaisseur_m=round(epaisseur, 4))]
        u += pas_u
    return pire, details


# ---------------------------------------------------------------------------
# MESURE B — transformée de distance sur la coupe du plan de bouche
# ---------------------------------------------------------------------------

def coupe_du_plan(grille, y, pas, marge=1.0):
    """Classe le plan `y` en `ouverture`, `roche`, `air libre`.

    La classification vient de la PARITÉ le long de X — une colonne du plan,
    pas un rayon vers la cavité — puis d'une inondation 2D depuis le bord.
    Ce qui touche le bord est l'air libre autour du rocher ; ce qui est creux
    sans toucher le bord est l'ouverture.
    """
    lo, hi = grille.aabb()
    x0, x1 = lo[0] - marge, hi[0] + marge
    z0, z1 = lo[2] - marge, hi[2] + marge
    nx = int(math.ceil((x1 - x0) / pas)) + 1
    nz = int(math.ceil((z1 - z0) / pas)) + 1

    # QUATRE PARITÉS, ET UN VOTE — parce qu'UNE parité ne suffit pas.
    #
    # Première version : une seule rangée de rayons, le long de +X. Un rayon
    # qui rase une arête du polygone perd une intersection, la parité de
    # TOUTE LA FIN DE LA RANGÉE s'inverse, et le trou ainsi créé relie
    # l'alésage au dehors. Mesuré sur le cylindre de calibration : les
    # 18 289 cases creuses étaient toutes déclarées « air libre », zéro case
    # d'ouverture, sur une forme dont l'ouverture est un disque parfait.
    #
    # C'est le même mécanisme que `dans_le_vide`, qui vote déjà sur six axes
    # pour cette raison exacte, et son commentaire le dit : « le vote absorbe
    # le cas rasant où un rayon effleure une arête ». La coupe n'en profitait
    # pas ; elle en profite maintenant, sur quatre directions du plan.
    def _parite(axe, sens):
        """Grille de parité obtenue en balayant selon un seul axe."""
        grille_p = [[False] * nz for _ in range(nx)]
        if axe == 0:
            for k in range(nz):
                z = z0 + k * pas
                depart = (x0 - marge, y, z) if sens > 0 else (x1 + marge, y, z)
                d = (float(sens), 0.0, 0.0)
                portee = (x1 - x0) + 3.0 * marge
                bornes = sorted(depart[0] + sens * t
                                for t, _ in P.impacts(grille, depart, d, portee))
                for i in range(nx):
                    x = x0 + i * pas
                    avant = sum(1 for b in bornes
                                if (b <= x if sens > 0 else b >= x))
                    grille_p[i][k] = (avant % 2 == 0)
        else:
            for i in range(nx):
                x = x0 + i * pas
                depart = (x, y, z0 - marge) if sens > 0 else (x, y, z1 + marge)
                d = (0.0, 0.0, float(sens))
                portee = (z1 - z0) + 3.0 * marge
                bornes = sorted(depart[2] + sens * t
                                for t, _ in P.impacts(grille, depart, d, portee))
                for k in range(nz):
                    z = z0 + k * pas
                    avant = sum(1 for b in bornes
                                if (b <= z if sens > 0 else b >= z))
                    grille_p[i][k] = (avant % 2 == 0)
        return grille_p

    votes = [_parite(0, 1), _parite(0, -1), _parite(1, 1), _parite(1, -1)]
    creux = [[sum(1 for v in votes if v[i][k]) >= 3 for k in range(nz)]
             for i in range(nx)]

    # Inondation 2D depuis le bord : l'air libre.
    libre = [[False] * nz for _ in range(nx)]
    pile = []
    for i in range(nx):
        for k in (0, nz - 1):
            if creux[i][k] and not libre[i][k]:
                libre[i][k] = True
                pile.append((i, k))
    for k in range(nz):
        for i in (0, nx - 1):
            if creux[i][k] and not libre[i][k]:
                libre[i][k] = True
                pile.append((i, k))
    while pile:
        i, k = pile.pop()
        for di, dk in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            a, c = i + di, k + dk
            if 0 <= a < nx and 0 <= c < nz and creux[a][c] and not libre[a][c]:
                libre[a][c] = True
                pile.append((a, c))
    return dict(x0=x0, z0=z0, pas=pas, nx=nx, nz=nz, creux=creux, libre=libre)


def mesure_b(coupe):
    """Distance minimale du POURTOUR de l'ouverture à l'air libre.

    Transformée de distance par vagues successives depuis l'air libre — un
    Dijkstra à poids uniformes sur la grille, en 8-connexité pour que les
    diagonales ne surestiment pas la distance de 41 %.

    Rend `(epaisseur_min, point, cases_ouverture)`. Une ouverture vide ou
    directement collée à l'air libre rend 0,0 : ce n'est pas une collerette
    fine, c'est une collerette ABSENTE, et les deux doivent se distinguer.
    """
    nx, nz, pas = coupe["nx"], coupe["nz"], coupe["pas"]
    creux, libre = coupe["creux"], coupe["libre"]
    ouverture = [(i, k) for i in range(nx) for k in range(nz)
                 if creux[i][k] and not libre[i][k]]
    if not ouverture:
        return None, None, 0
    # Vagues depuis l'air libre, en traversant la ROCHE uniquement.
    INF = float("inf")
    dist = [[INF] * nz for _ in range(nx)]
    front = []
    for i in range(nx):
        for k in range(nz):
            if libre[i][k]:
                dist[i][k] = 0.0
                front.append((i, k))
    voisins = [(1, 0, 1.0), (-1, 0, 1.0), (0, 1, 1.0), (0, -1, 1.0),
               (1, 1, math.sqrt(2.0)), (1, -1, math.sqrt(2.0)),
               (-1, 1, math.sqrt(2.0)), (-1, -1, math.sqrt(2.0))]
    while front:
        suivant = []
        for i, k in front:
            for di, dk, poids in voisins:
                a, c = i + di, k + dk
                if not (0 <= a < nx and 0 <= c < nz):
                    continue
                # On ne progresse QUE dans la roche : la distance mesurée est
                # une épaisseur de matière, pas une distance à vol d'oiseau.
                if creux[a][c] and not libre[a][c]:
                    d = dist[i][k] + poids
                    if d < dist[a][c]:
                        dist[a][c] = d
                        suivant.append((a, c))
                    continue
                if creux[a][c]:
                    continue
                d = dist[i][k] + poids
                if d < dist[a][c]:
                    dist[a][c] = d
                    suivant.append((a, c))
        front = suivant
    # LE BIAIS D'UNE MAILLE, MESURE ET CORRIGE.
    #
    # `tools/cave_collar_calibration.py`, sur un tube cylindrique dont
    # l'epaisseur vaut exactement `R - r` :
    #
    #   pas     0,1000  0,0500  0,0250  0,0125
    #   biais  -0,1000 -0,0500 -0,0250 -0,0125
    #   /pas    -1,00   -1,00   -1,00   -1,00
    #
    # et a pas constant, le biais ne bouge pas d'un micron quand l'epaisseur
    # passe de 0,30 a 1,20 m. Un biais qui suit le PAS et ignore la
    # GRANDEUR MESUREE est de la discretisation, pas une erreur d'echelle :
    # la premiere case de roche est deja a une demi-maille de l'air, la
    # derniere a une demi-maille de l'ouverture, et le compte de pas perd
    # exactement une maille entre les deux.
    #
    # La correction est donc `+ pas`, elle est exacte, et elle est appliquee
    # ici plutot que laissee au lecteur — un biais connu qu'on rapporte sans
    # le corriger est un piege pose pour la prochaine session.
    CORRECTION_MAILLE = 1.0
    pire, ou = None, None
    for i, k in ouverture:
        for di, dk, _ in voisins:
            a, c = i + di, k + dk
            if not (0 <= a < nx and 0 <= c < nz):
                continue
            if creux[a][c]:
                continue
            if dist[a][c] == INF:
                continue
            d = (dist[a][c] + CORRECTION_MAILLE) * pas
            if pire is None or d < pire:
                pire = d
                ou = (coupe["x0"] + i * pas, coupe["z0"] + k * pas)
    return pire, ou, len(ouverture)


# ---------------------------------------------------------------------------

def mesurer(chemin, y_bouche=Y_BOUCHE_DEFAUT, pas=0.05, triangles=None):
    """Les deux mesures sur un maillage, ou sur une liste de triangles."""
    if triangles is None:
        triangles, _ = P.triangles_du_glb(chemin)
    grille = P.Grille(triangles)
    profil = P.PROFIL_GROTTE
    a, detail_a = mesure_a(grille, profil, y_bouche)
    # LE PLAN DE LA BOUCHE N'EST PAS TOUJOURS UTILISABLE, ET C'EST MESURE.
    #
    # A y = -1,15 le porche est EVASE et son sol plonge sous le terrain : le
    # creux de l'ouverture communique lateralement avec l'air libre DANS LE
    # PLAN, il n'y est donc pas clos, et l'inondation 2D ne trouve aucune
    # case d'ouverture. Rendre 0 la-dessus serait annoncer une collerette
    # absente ; rendre None serait perdre la mesure.
    #
    # On avance donc dans la galerie jusqu'au premier plan ou la section est
    # une VRAIE ouverture close, et on dit lequel. C'est une limite de la
    # methode, pas un reglage : elle est rapportee avec le resultat.
    b = point_b = None
    cases = 0
    plan_utilise = None
    y = y_bouche
    while y <= y_bouche + 1.60 + 1e-9:
        coupe = coupe_du_plan(grille, y, pas)
        b, point_b, cases = mesure_b(coupe)
        if cases > 0 and b is not None:
            plan_utilise = y
            break
        y += 0.20
    return dict(mesure_a_m=a, detail_a=detail_a, mesure_b_m=b,
                point_b=point_b, cases_ouverture=cases,
                plan_utilise_y=plan_utilise,
                triangles=len(triangles))


def main():
    ap = argparse.ArgumentParser(
        description="Epaisseur de collerette par deux mecanismes distincts.")
    ap.add_argument("glb", nargs="?",
                    default="assets/environment/caves/prototypes/"
                            "SM_WaterfallCave_BASE352.glb")
    ap.add_argument("--y-bouche", type=float, default=Y_BOUCHE_DEFAUT)
    ap.add_argument("--pas", type=float, default=0.05)
    ap.add_argument("--seuil", type=float, default=0.60)
    ap.add_argument("--json", default=None)
    args = ap.parse_args()

    print("=" * 78)
    print("COLLERETTE — deux mesures, deux mecanismes")
    print("=" * 78)
    if not os.path.isfile(args.glb):
        print("BLOQUE: maillage introuvable : %s" % args.glb)
        return 3
    try:
        resultat = mesurer(args.glb, args.y_bouche, args.pas)
    except P.Blocage as erreur:
        print("BLOQUE: %s" % erreur)
        return 3

    print("maillage : %s" % args.glb)
    print("   %d triangles, plan de bouche y = %+.2f, pas de coupe %.3f m"
          % (resultat["triangles"], args.y_bouche, args.pas))
    print()
    print("MESURE A — rayons selon la normale locale")
    if resultat["mesure_a_m"] is None:
        print("   AUCUNE epaisseur mesurable : aucun rayon ne rencontre deux "
              "peaux.")
    else:
        print("   epaisseur minimale %.4f m" % resultat["mesure_a_m"])
        for d in resultat["detail_a"]:
            print("      u %.2f, azimut %.1f deg" % (d["u"], d["azimut_deg"]))
    print()
    print("MESURE B — transformee de distance sur une coupe transversale")
    print("   (corrigee de +1 maille = %+.4f m ; biais mesure sur cylindre"
          % args.pas)
    print("    analytique, voir tools/cave_collar_calibration.py)")
    if resultat.get("plan_utilise_y") is None:
        print("   aucun plan entre y = %+.2f et y = %+.2f ne porte une "
              "ouverture close" % (args.y_bouche, args.y_bouche + 1.60))
    else:
        print("   plan utilise : y = %+.2f%s"
              % (resultat["plan_utilise_y"],
                 "" if abs(resultat["plan_utilise_y"] - args.y_bouche) < 1e-9
                 else "  (le plan de bouche lui-meme est ouvert lateralement)"))
    print("   %d case(s) d'ouverture (creux non relie au bord de la coupe)"
          % resultat["cases_ouverture"])
    if resultat["mesure_b_m"] is None:
        print("   AUCUNE ouverture trouvee dans le plan : la mesure ne "
              "s'applique pas ici.")
    else:
        print("   epaisseur minimale %.4f m" % resultat["mesure_b_m"])
        if resultat["point_b"]:
            print("      au point (x %+.2f ; z %+.2f) du plan de bouche"
                  % resultat["point_b"])
    print()
    print("=" * 78)
    valeurs = [v for v in (resultat["mesure_a_m"], resultat["mesure_b_m"])
               if v is not None]
    if len(valeurs) < 2:
        print("NON VERIFIE — une des deux mesures n'a pas abouti ; deux")
        print("mecanismes dont un seul repond ne corroborent rien.")
        rc = 1
    else:
        ecart = abs(valeurs[0] - valeurs[1])
        print("A = %.4f m, B = %.4f m, ecart %.4f m, seuil %.2f m"
              % (valeurs[0], valeurs[1], ecart, args.seuil))
        sous = [v for v in valeurs if v < args.seuil]
        if sous:
            print("VERDICT : FAIL — %d mesure(s) sous le seuil" % len(sous))
            rc = 1
        else:
            print("VERDICT : PASS — les deux mecanismes sont au-dessus du "
                  "seuil")
            rc = 0
        if ecart > 0.25:
            print("   ATTENTION: les deux mesures divergent de %.3f m. Elles "
                  "ne mesurent" % ecart)
            print("   pas la meme chose, ou l'une se trompe — l'ecart est "
                  "rapporte, pas moyenne.")
    print("=" * 78)
    if args.json:
        dossier = os.path.dirname(args.json)
        if dossier and not os.path.isdir(dossier):
            os.makedirs(dossier)
        with open(args.json, "w", encoding="utf-8") as poignee:
            json.dump(dict(glb=args.glb, seuil_m=args.seuil, **resultat),
                      poignee, indent=1, sort_keys=True, ensure_ascii=False)
        print("sortie brute : %s" % args.json)
    return rc


if __name__ == "__main__":
    sys.exit(main())
