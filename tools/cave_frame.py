#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""REPÈRE LOCAL ET COUVERTURE — ce qu'un « 0 percée » a le droit de signifier.

POURQUOI CET OUTIL EXISTE
=========================

`tools/probe_cave_openings.py` rend un compte de percées. Un compte n'est
une preuve d'étanchéité que si l'on sait CE QUI A ÉTÉ REGARDÉ. Le tour
précédent l'a montré de la pire façon : la sonde annonçait 38 percées, et
les 38 étaient fausses parce que les points de départ étaient placés
symétriquement le long de l'axe monde X sur une galerie dissymétrique et
infléchie. Le compte était précis, plausible, et sans rapport avec la
question.

Le mode d'échec inverse est plus dangereux encore, parce qu'il clôt un
gate : un « 0 percée » obtenu en ne regardant que 36 % du côté large est un
angle mort déguisé en acquittement. C'est celui-ci que cet outil interdit.

> **Un « zéro percée » sans démonstration de couverture n'est pas un gate.**

CE QU'IL PUBLIE, ET POURQUOI CHAQUE COLONNE
===========================================

  1. LE REPÈRE LOCAL, station par station — tangente de galerie, normale
     latérale, verticale, largeur de CHAQUE côté, sol, toit. Sans ce repère
     publié, « côté droit » est une opinion : le générateur décide le côté
     sur le signe de l'offset NORMAL, et entre les stations 7 et 8 la
     normale est à 45° de X. Une mesure qui parle de côté sans publier sa
     normale n'est pas relisable.

  2. LA COUVERTURE, côté par côté — largeur réelle, plage effectivement
     sondée, taux de couverture, espacement maximal entre deux échantillons
     voisins. Le taux est défini de la seule façon qui engage à quelque
     chose : la part de la bande [0, paroi] située à moins d'un demi-pas
     d'un échantillon RÉELLEMENT dans le vide. Un échantillon visé mais
     tombé dans la roche ne couvre rien, et il est compté comme tel.

  3. L'ÉPAISSEUR MINIMALE et son point, côté par côté — parce qu'une paroi
     saine en moyenne n'est pas une paroi saine.

  4. LA VALIDITÉ DES ORIGINES — chaque point de départ est-il dans le vide
     du maillage, dans l'enveloppe nominale, et suffisamment enclos ? Un
     rayon parti d'un point hors cavité fabrique des percées ; c'est ce qui
     a produit les 403 puis les 38 faux positifs.

  5. LES SEPT ZONES OBLIGATOIRES — toit, plancher, les deux parois, les
     raccords entre stations, le porche, la fermeture arrière. Une zone non
     couverte est nommée, pas tue.

CE QU'IL NE FAIT PAS
====================

Il ne juge pas l'étanchéité. Il dit ce qu'un jugement d'étanchéité a le
droit de couvrir. Les deux verdicts restent séparés, exprès : les mélanger
permettrait à une bonne couverture de compenser une percée, ou l'inverse.

DOMAINE DE VALIDITÉ — ET LA LIMITE QUI COMPTE LE PLUS
=====================================================

`EXPLOITABLE`. Le pas latéral est métrique et non une fraction de la
demi-largeur : c'est ce qui donne au taux de couverture un sens du côté
large. Aucun biais connu sur la mesure elle-même.

MAIS : **« 100 % des deux côtés » veut dire 100 % de la CAVITÉ DÉCLARÉE.**
Cet outil, comme tous ceux qui s'ancrent sur `CAVITE`, ne regarde que le
long de l'axe déclaré. Or `CAVITE` s'arrête à `ay = 3,17`.

Mesure du 2026-08-16 sur `cc3596c5`, colonnes verticales, pas de station :

    y      2,60   3,40   4,20   4,60   5,00   5,40   5,80   6,20   7,00
    toit   4,79   3,74   2,70   1,22   0,52   0,53   0,05   1,50   2,08
    (épaisseur de roche au-dessus du vide, en m, à x = 0,58)

Il y a donc du vide connecté à la galerie jusqu'à `y ≈ 7,0` au moins —
presque quatre mètres au-delà de la dernière station — et le toit y tombe
à **0,054 m**, mesuré, contre `EPAISSEUR_MIN_M = 0,80`.

Aucun instrument ancré sur les stations ne peut voir cette zone : elle
n'est pas mal couverte, elle est HORS du domaine. Un « 100 % » d'ici ne
doit donc jamais être lu comme « tout le vide a été regardé ». Ce qui
regarde sans station : `tools/cave_seal_oracle.py` et
`tools/audit_cave_floor_columns.py`.

Usage :
    python3 tools/cave_frame.py [glb] [--pas-lateral 0.20] [--pas-long 0.25]
        [--json sortie.json] [--couverture-min 1.00]

Codes de sortie : 0 = couverture conforme · 1 = couverture insuffisante
· 3 = BLOQUÉ (fichier absent ou illisible).
"""

import argparse
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import probe_cave_openings as P                                # noqa: E402


## Part de directions rencontrant de la roche au-dessus de laquelle un point
## est tenu pour « dans une cavité » et non « en plein air ». Repris tel quel
## de la sonde : deux seuils différents pour la même notion divergeraient.
ENCLOSURE_MIN = P.ENCLOSURE_MIN

## Sous cette épaisseur, deux impacts successifs sont le même pli de surface
## vu deux fois. Repris de la sonde pour la même raison.
ECAILLE_M = P.ECAILLE_M

## Les sept zones dont la couverture est exigée par la revue.
ZONES = ("plancher", "toit", "paroi_gauche", "paroi_droite",
         "raccords_entre_stations", "porche", "fermeture_arriere")


# ---------------------------------------------------------------------------
# 1. LE REPÈRE LOCAL
# ---------------------------------------------------------------------------

def repere_local(profil, u):
    """Le repère de section en `u`, entièrement explicite.

    Rend un dictionnaire plutôt qu'un tuple parce que ces sept grandeurs
    sont destinées à être RELUES par quelqu'un d'autre. Un tuple de sept
    flottants se déballe dans le mauvais ordre une fois sur trois, et
    silencieusement.

    La tangente est dérivée par différences finies sur ±0,02 station, comme
    `Profil.normale`, et la normale en est la rotation de -90° dans le plan
    (x, y). La verticale est l'axe Z du modèle : la galerie ne roule pas,
    et si elle roulait un jour cette ligne serait le premier endroit à
    corriger.
    """
    ax, ay, hw, cle, palier = profil.station(u)
    nx, ny = profil.normale(u)
    # La tangente est la normale tournée de +90° : (nx, ny) = (ty, -tx)
    # donc (tx, ty) = (-ny, nx).
    tx, ty = -ny, nx
    gauche, droite, inclinaison = profil.asym_station(u)
    return dict(
        u=round(u, 4),
        station=int(round(u)),
        axe=[round(ax, 4), round(ay, 4)],
        tangente=[round(tx, 5), round(ty, 5)],
        normale=[round(nx, 5), round(ny, 5)],
        verticale=[0.0, 0.0, 1.0],
        demi_largeur_nominale_m=round(hw, 4),
        # `demi_largeur` choisit le côté sur le SIGNE du latéral : -1 est le
        # côté `gauche` du générateur, +1 le côté `droite`.
        largeur_cote_gauche_m=round(profil.demi_largeur(u, -1.0), 4),
        largeur_cote_droite_m=round(profil.demi_largeur(u, +1.0), 4),
        facteur_gauche=round(gauche, 4),
        facteur_droite=round(droite, 4),
        inclinaison_linteau=round(inclinaison, 4),
        sol_axe_m=round(profil.sol(u, 0.0), 4),
        sol_bord_m=round(profil.sol(u, 1.0), 4),
        toit_axe_m=round(palier + cle, 4),
        toit_bord_gauche_m=round(palier + profil.cle_au_lateral(u, -1.0), 4),
        toit_bord_droite_m=round(palier + profil.cle_au_lateral(u, +1.0), 4),
        palier_m=round(palier, 4),
    )


def point_lateral(profil, u, lateral_m, hauteur_sur_sol):
    """Point du modèle à l'offset NORMAL `lateral_m`, `h` au-dessus du sol.

    C'est la seule façon dont ce fichier place un point. Aucune fonction
    d'ici ne construit `(ax + quelque_chose, ay, z)` : c'est précisément la
    forme qui a produit sept fautes successives dans la sonde.
    """
    ax, ay, _, _, _ = profil.station(u)
    nx, ny = profil.normale(u)
    demi = profil.demi_largeur(u, lateral_m)
    fraction = (lateral_m / demi) if demi else 0.0
    z = profil.sol(u, fraction) + hauteur_sur_sol
    return (ax + lateral_m * nx, ay + lateral_m * ny, z)


# ---------------------------------------------------------------------------
# 2. LA COUVERTURE
# ---------------------------------------------------------------------------

def intervalle_galerie(grille, profil, u, hauteurs, directions,
                       portee=8.0, pas_scan=0.05):
    """Intervalle d'offsets NORMAUX réellement creux, à la station `u`.

    POURQUOI CETTE MESURE EXISTE, ET CE QU'ELLE A RÉVÉLÉ.
    ====================================================

    Toute la sonde suppose que l'axe déclaré (`CAVITE`) traverse le vide.
    C'est vrai du porche au coude, et FAUX au-delà : mesuré sur `f3afa0e`,
    aux stations 5 à 8 le point d'axe est enfermé dans la roche —
    `dans_le_vide` rend 0 direction paire sur 6, ce qui est la signature
    d'un point noyé, pas d'un point rasant.

        u=5  vide reel  -3,20 .. -0,40   axe declare a 0,00  -> DANS LA ROCHE
        u=8  vide reel  -3,20 .. -0,80   axe declare a 0,00  -> DANS LA ROCHE

    Conséquence, et c'est elle qui compte : chaque garde analytique —
    `dans_enveloppe`, `dans_le_noyau`, `_emprise_noyau`, `sort_par_la_bouche`
    — est CENTRÉE SUR UN POINT QUI N'EST PAS DANS LA GALERIE à ces stations.
    Un « 0 percée » y couvre donc beaucoup moins qu'il n'en a l'air, et le
    dire est le travail de cet outil.

    La bande à couvrir ne peut donc pas être ancrée sur l'axe déclaré. Elle
    est mesurée : on balaie la normale, on garde les cases creuses, et on
    écarte celles qui sont du plein air à côté du rocher (test d'enclosure,
    même seuil que la sonde). Rend `(o_min, o_max)` ou None.
    """
    hauteur = hauteurs[len(hauteurs) // 2]
    ax, ay, _, _, _ = profil.station(u)
    nx, ny = profil.normale(u)
    z = profil.sol(u, 0.0) + hauteur
    creux = []
    o = -portee
    while o <= portee + 1e-9:
        p = (ax + o * nx, ay + o * ny, z)
        vide, _ = P.dans_le_vide(grille, p)
        creux.append((o, vide))
        o += pas_scan
    # Segments creux contigus.
    segments, debut = [], None
    for o, vide in creux:
        if vide and debut is None:
            debut = o
        elif not vide and debut is not None:
            segments.append((debut, o - pas_scan))
            debut = None
    if debut is not None:
        segments.append((debut, creux[-1][0]))
    # ÉCARTER LE PLEIN AIR. Un segment dont le milieu ne voit de la roche
    # que dans moins de la moitié des directions n'est pas la galerie :
    # c'est le ciel à côté du rocher, et le compter gonflerait la bande
    # jusqu'à rendre n'importe quelle couverture triviale.
    retenus = []
    for a, b in segments:
        if b - a < 0.10:
            continue
        milieu = (a + b) / 2.0
        p = (ax + milieu * nx, ay + milieu * ny, z)
        rencontres = sum(1 for d in directions
                         if P.impacts(grille, p, d, 40.0))
        if rencontres / float(len(directions)) >= ENCLOSURE_MIN:
            retenus.append((a, b))
    if not retenus:
        return None
    # LE SEGMENT RETENU EST CELUI QUI RECOUVRE LE PLUS LA BANDE NOMINALE,
    # et non le plus large. Mesuré : à la station 1 le plus large est
    # `[-8,00 ; -2,85]`, 5,15 m d'AIR LIBRE à côté du rocher, qui passe le
    # test d'enclosure à 0,63 parce qu'un gros massif occupe encore plus de
    # la moitié du ciel quand on se tient contre lui. Le retenir aurait
    # gonflé la bande à couvrir avec du dehors, et fait chuter un taux qui
    # ne mesurait plus rien.
    #
    # S'ancrer sur le nominal n'est pas y revenir : le nominal choisit
    # QUEL creux est la galerie, le creux mesuré en donne les BORNES.
    g_nom = -profil.demi_largeur(u, -1.0)
    d_nom = profil.demi_largeur(u, +1.0)
    def _recouvrement(seg):
        return max(0.0, min(seg[1], d_nom) - max(seg[0], g_nom))
    avec = [(seg, _recouvrement(seg)) for seg in retenus]
    avec = [x for x in avec if x[1] > 1e-9]
    if not avec:
        return None
    return max(avec, key=lambda x: x[1])[0]


def couverture_bande(offsets, largeur, pas):
    """Part de [0, largeur] à moins de `pas/2` d'un des `offsets`.

    LA DÉFINITION EST LE CŒUR DU GATE, elle est donc écrite ici et nulle
    part ailleurs. « Couvert » ne veut pas dire « il y a des points » : il
    veut dire qu'aucun point de la bande n'est à plus d'un demi-pas d'un
    échantillon. C'est la seule formulation qui interdise à un trou de la
    taille visée de se glisser entre deux mesures — le critère de Nyquist,
    appliqué au placement plutôt qu'au raster.

    Les offsets sont donnés en valeur ABSOLUE, sur un seul côté.
    """
    if largeur <= 1e-9:
        return 1.0, 0.0
    demi = pas / 2.0
    segments = []
    for o in sorted(offsets):
        a, b = max(0.0, o - demi), min(largeur, o + demi)
        if b > a:
            segments.append((a, b))
    if not segments:
        return 0.0, largeur
    fusion = [list(segments[0])]
    for a, b in segments[1:]:
        if a <= fusion[-1][1] + 1e-9:
            fusion[-1][1] = max(fusion[-1][1], b)
        else:
            fusion.append([a, b])
    couvert = sum(b - a for a, b in fusion)
    # L'ESPACEMENT MAXIMAL est le plus grand trou entre deux segments
    # couverts, bornes 0 et `largeur` comprises. Un trou contre la paroi
    # compte : c'est là que se trouve la matière qu'on prétend vérifier.
    trous = [fusion[0][0]] + [fusion[i + 1][0] - fusion[i][1]
                              for i in range(len(fusion) - 1)] \
        + [largeur - fusion[-1][1]]
    return min(1.0, couvert / largeur), max(0.0, max(trous))


def epaisseur_paroi(grille, origine, direction, portee=60.0):
    """Épaisseur de la première paroi rencontrée, ou None.

    Deux impacts consécutifs séparés de plus de `ECAILLE_M` bornent une
    paroi. En deçà, c'est le même pli vu deux fois — le seuil est repris de
    la sonde, pas réinventé.
    """
    liste = P.impacts(grille, origine, direction, portee)
    if len(liste) < 2:
        return None
    entree = liste[0][0]
    for t, _ in liste[1:]:
        if t - entree > ECAILLE_M:
            return t - entree
    return None


def couverture_station(grille, profil, u, pas_lateral, hauteurs,
                       marge_paroi, directions):
    """Couverture et épaisseurs à une station, CÔTÉ PAR CÔTÉ.

    LA BANDE À COUVRIR EST L'INTERVALLE CREUX MESURÉ, pas la bande nominale.
    Trois raisons, chacune mesurée sur `f3afa0e` :

      * là où la coque RENTRE en deçà du nominal, les derniers échantillons
        tombent dans la roche : le taux chute sans qu'aucun air soit manqué ;
      * là où l'ALCÔVE pousse au-delà du nominal — jusqu'à 3,2 m à gauche
        aux stations 4 à 8 — de l'air réel reste hors de la bande nominale,
        donc jamais visité, et le nominal ne sait même pas qu'il existe ;
      * aux stations 5 à 8, l'axe déclaré est DANS LA ROCHE : une bande
        ancrée sur lui ne décrit rien.

    Les deux « côtés » sont donc définis par rapport à l'axe déclaré mais
    bornés par le vide réel. Quand l'axe est hors du vide, un côté est vide
    de toute bande à couvrir et l'autre porte l'intégralité de la galerie ;
    c'est dit explicitement plutôt que masqué par une moyenne.
    """
    repere = repere_local(profil, u)
    nx, ny = profil.normale(u)
    bande = intervalle_galerie(grille, profil, u, hauteurs, directions)
    p_axe = point_lateral(profil, u, 0.0, hauteurs[len(hauteurs) // 2])
    axe_dans_le_vide, _ = P.dans_le_vide(grille, p_axe)

    resultat = dict(repere=repere, cotes={},
                    bande_creuse_mesuree_m=([round(bande[0], 3),
                                             round(bande[1], 3)]
                                            if bande else None),
                    axe_declare_dans_le_vide=bool(axe_dans_le_vide))

    for nom, signe in (("gauche", -1.0), ("droite", +1.0)):
        nominale = profil.demi_largeur(u, signe)
        # Part de la bande creuse située de CE côté de l'axe déclaré.
        if bande is None:
            largeur = 0.0
            debut = 0.0
        elif signe < 0:
            debut = max(0.0, -min(0.0, bande[1]))
            largeur = max(0.0, -bande[0]) - debut
        else:
            debut = max(0.0, bande[0])
            largeur = max(0.0, bande[1]) - debut
        largeur = max(0.0, largeur)

        # ÉCHANTILLONNAGE — sur la bande creuse mesurée, pas sur la nominale.
        offsets = []
        if largeur > 1e-9:
            n = int(math.floor((largeur - marge_paroi) / pas_lateral))
            offsets = [debut + i * pas_lateral for i in range(0, n + 1)]
            fin = debut + largeur - marge_paroi
            if fin > debut and (not offsets or abs(fin - offsets[-1]) > 1e-6):
                offsets.append(fin)

        dans_vide, hors_vide, hors_enveloppe, peu_enclos = [], [], [], []
        for o in offsets:
            ok = False
            for h in hauteurs:
                p = point_lateral(profil, u, signe * o, h)
                vide, _ = P.dans_le_vide(grille, p)
                if not vide:
                    continue
                rencontres = sum(1 for d in directions
                                 if P.impacts(grille, p, d, 40.0))
                if rencontres / float(len(directions)) < ENCLOSURE_MIN:
                    peu_enclos.append(round(o, 3))
                    continue
                # ONZIÈME CONSTAT. `dans_enveloppe` est un test du profil
                # NOMINAL, et le nominal N'INCLUT PAS L'ALCÔVE : le
                # générateur la fabrique par le terme `pousse`, que la
                # classe `Profil` de la sonde ne reproduit nulle part. Un
                # point réellement dans l'alcôve, dans le vide, enclos de
                # toutes parts, y est donc déclaré « hors cavité ».
                #
                # L'employer pour DISQUALIFIER un échantillon de couverture
                # revenait à ne couvrir que l'air que le profil déclaré
                # connaît — c'est-à-dire à ne jamais inspecter l'alcôve,
                # qui est précisément l'endroit dont la revue veut la
                # preuve. Le fait est donc COMPTÉ, pas opposé : ce qui
                # écarte l'air libre est l'enclosure, qui, elle, se mesure
                # sur le maillage.
                if not P.dans_enveloppe(p, profil):
                    hors_enveloppe.append(round(o, 3))
                ok = True
                break
            (dans_vide if ok else hors_vide).append(o)

        taux, espacement = couverture_bande(
            [o - debut for o in dans_vide], largeur, pas_lateral)

        # ÉPAISSEUR — depuis un point RÉELLEMENT dans la galerie, le long de
        # la normale. Partir de l'axe déclaré donnerait, aux stations 5 à 8,
        # l'épaisseur vue depuis l'intérieur de la roche : un nombre, faux.
        epaisseurs = []
        if bande is not None:
            interieur = (bande[0] + bande[1]) / 2.0
            for h in hauteurs:
                p = point_lateral(profil, u, interieur, h)
                vide, _ = P.dans_le_vide(grille, p)
                if not vide:
                    continue
                e = epaisseur_paroi(grille, p, (signe * nx, signe * ny, 0.0))
                if e is not None:
                    epaisseurs.append((e, round(h, 2)))
        mini = min(epaisseurs) if epaisseurs else (None, None)

        resultat["cotes"][nom] = dict(
            largeur_reelle_m=round(largeur, 4),
            largeur_nominale_m=round(nominale, 4),
            depart_bande_m=round(debut, 4),
            ecart_nominal_reel_m=round(largeur - nominale, 4),
            bande_vide=(largeur <= 1e-9),
            normale_employee=[round(signe * nx, 5), round(signe * ny, 5)],
            offsets_vises=len(offsets),
            offsets_dans_la_cavite=len(dans_vide),
            plage_sondee_m=[round(min(dans_vide), 3),
                            round(max(dans_vide), 3)] if dans_vide else None,
            taux_couverture=round(taux, 4),
            espacement_max_m=round(espacement, 4),
            rejets=dict(hors_vide=len(hors_vide),
                        hors_enveloppe=len(hors_enveloppe),
                        peu_enclos=len(peu_enclos)),
            epaisseur_min_m=round(mini[0], 4) if mini[0] is not None else None,
            epaisseur_min_hauteur_m=mini[1],
        )
    return resultat


# ---------------------------------------------------------------------------
# 3. LES ZONES OBLIGATOIRES
# ---------------------------------------------------------------------------

def couverture_zones(profil, pas_long, pas_lateral, hauteurs, stations):
    """Une ligne par zone exigée : couverte, par quoi, et à quel pas.

    Rendre « couvert » sans dire PAR QUOI serait une case à cocher. Chaque
    zone nomme l'instrument qui la couvre et le pas auquel il la couvre ;
    une zone dont l'instrument n'existe pas est écrite `NON COUVERTE`, ce
    qui est le seul état honnête d'un contrôle absent.
    """
    u_max = float(len(profil.cavite) - 1)
    taux_gauche = [s["cotes"]["gauche"]["taux_couverture"] for s in stations]
    taux_droite = [s["cotes"]["droite"]["taux_couverture"] for s in stations]
    return {
        "plancher": dict(
            couverte=True, pas_m=pas_lateral,
            par="carte_du_plancher + controle_plancher, rayon -Z depuis "
                "chaque offset lateral metrique",
            note="le pas lateral borne l'espacement ; le pas longitudinal "
                 "%.2f m borne l'espacement le long de l'axe" % pas_long),
        "toit": dict(
            couverte=True, pas_m=P.OUVERTURE_CONFIRMEE_M / 2.0,
            par="raster_surface('toit') depuis le dehors + controle_jour "
                "(sphere entiere, elevations jusqu'a +90)",
            note="le raster vise le NOYAU : une percee ouvrant sur la marge "
                 "n'est vue que par le controle 2"),
        "paroi_gauche": dict(
            couverte=min(taux_gauche) >= 0.999 if taux_gauche else False,
            pas_m=pas_lateral, taux_min=round(min(taux_gauche), 4) if taux_gauche else None,
            par="offsets lateraux metriques le long de la NORMALE, cote "
                "gauche (offset normal negatif)"),
        "paroi_droite": dict(
            couverte=min(taux_droite) >= 0.999 if taux_droite else False,
            pas_m=pas_lateral, taux_min=round(min(taux_droite), 4) if taux_droite else None,
            par="offsets lateraux metriques le long de la NORMALE, cote "
                "droite (offset normal positif)"),
        "raccords_entre_stations": dict(
            couverte=True, pas_m=pas_long,
            par="u continu de 0 a %.0f par pas de %.2f station" % (u_max, pas_long),
            note="les stations ne sont pas des points de mesure isoles : "
                 "l'echantillonnage est CONTINU le long de u, donc les "
                 "raccords sont sondes comme le reste"),
        "porche": dict(
            couverte=True, pas_m=pas_lateral,
            par="stations 0 et 1 incluses dans l'echantillonnage ; le "
                "PLANCHER y est juge, le JOUR y est ECARTE (ouvert par "
                "construction)",
            note="l'etancheite du porche ne se mesure pas par le jour — "
                 "c'est une ouverture. Sa COLLERETTE se mesure par "
                 "tools/cave_collar.py, qui est l'instrument prevu."),
        "fermeture_arriere": dict(
            couverte=True, pas_m=0.25,
            par="carte_du_fond (rayons -Y depuis y=+14) + "
                "raster_surface('fond')",
            note="emprise bornee cote par cote le long de la normale de la "
                 "derniere station, plus une marge ADDITIVE de 0,40 m"),
    }


# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(
        description="Repere local par station et couverture de "
                    "l'echantillonnage.")
    ap.add_argument("glb", nargs="?",
                    default="assets/environment/caves/SM_WaterfallCave.glb")
    ap.add_argument("--pas-lateral", type=float, default=0.20)
    ap.add_argument("--pas-long", type=float, default=0.25)
    ap.add_argument("--marge-paroi", type=float, default=0.05)
    ap.add_argument("--couverture-min", type=float, default=1.00,
                    help="taux exige sur CHAQUE cote de CHAQUE station")
    ap.add_argument("--json", default=None)
    args = ap.parse_args()

    print("=" * 78)
    print("REPERE LOCAL ET COUVERTURE — Grotte du Couchant")
    print("=" * 78)

    if not os.path.isfile(args.glb):
        print("BLOQUE: maillage introuvable : %s" % args.glb)
        return 3
    try:
        tris, _ = P.triangles_du_glb(args.glb)
    except P.Blocage as erreur:
        print("BLOQUE: %s" % erreur)
        return 3
    grille = P.Grille(tris)
    profil = P.PROFIL_GROTTE
    hauteurs = (0.35, 0.90, 1.50)
    directions = P.directions_sphere(5, 10)

    print("maillage : %s, %d triangles" % (args.glb, len(tris)))
    print("pas lateral %.2f m (METRIQUE), pas longitudinal %.2f station, "
          "marge de paroi %.2f m" % (args.pas_lateral, args.pas_long,
                                     args.marge_paroi))
    print()

    # -- 1. LE REPERE LOCAL --------------------------------------------
    print("-" * 78)
    print("1. REPERE LOCAL PAR STATION")
    print("-" * 78)
    print("La NORMALE est l'axe lateral de section. Le cote `gauche` du")
    print("generateur est l'offset normal NEGATIF ; `droite` le positif.")
    print("Entre les stations 7 et 8 la normale est a 45 deg de X : mesurer")
    print("le long de X y designerait le mauvais flanc.")
    print()
    print("  st |  axe (x, y)     | tangente        | normale         |"
          " larg.G | larg.D |  sol   |  toit")
    print("  ---+-----------------+-----------------+-----------------+"
          "--------+--------+--------+-------")
    reperes = []
    for i in range(len(profil.cavite)):
        r = repere_local(profil, float(i))
        reperes.append(r)
        print("  %2d | %+6.2f, %+6.2f | %+6.3f, %+6.3f | %+6.3f, %+6.3f |"
              " %6.3f | %6.3f | %+6.3f | %+6.3f"
              % (r["station"], r["axe"][0], r["axe"][1],
                 r["tangente"][0], r["tangente"][1],
                 r["normale"][0], r["normale"][1],
                 r["largeur_cote_gauche_m"], r["largeur_cote_droite_m"],
                 r["sol_axe_m"], r["toit_axe_m"]))
    ratios = [r["largeur_cote_gauche_m"] / r["largeur_cote_droite_m"]
              for r in reperes if r["largeur_cote_droite_m"] > 1e-9]
    print()
    print("  dissymetrie G/D : de %.2f a %.2f — une demi-largeur unique ne "
          "peut donc" % (min(ratios), max(ratios)))
    print("  pas decrire cette galerie, et le long de X encore moins.")

    # -- 2. LA COUVERTURE ----------------------------------------------
    print()
    print("-" * 78)
    print("2. COUVERTURE, CENT PAR CENT DES DEUX COTES OU RIEN")
    print("-" * 78)
    print("taux = part de la bande [axe .. paroi] a moins d'un DEMI-PAS d'un")
    print("echantillon REELLEMENT dans la cavite. Un offset vise mais tombe")
    print("dans la roche ne couvre rien et n'est pas compte comme couvrant.")
    print()
    stations = []
    u = 0.0
    u_max = float(len(profil.cavite) - 1)
    while u <= u_max + 1e-9:
        stations.append(couverture_station(grille, profil, u, args.pas_lateral,
                                           hauteurs, args.marge_paroi,
                                           directions))
        u += args.pas_long
    print("  u    | cote   | nomin. | reelle | plage sondee  | vis/cav |"
          "  taux  | espac. | ep.min")
    print("  -----+--------+--------+--------+---------------+---------+"
          "--------+--------+-------")
    manquements = []
    axes_dans_la_roche = []
    for s in stations:
        for nom in ("gauche", "droite"):
            c = s["cotes"][nom]
            plage = ("%.2f..%.2f" % tuple(c["plage_sondee_m"])
                     if c["plage_sondee_m"] else "   aucune   ")
            print("  %4.2f | %-6s | %6.3f | %6.3f | %13s | %3d/%-3d | %s |"
                  " %6.3f | %s"
                  % (s["repere"]["u"], nom, c["largeur_nominale_m"],
                     c["largeur_reelle_m"], plage,
                     c["offsets_vises"], c["offsets_dans_la_cavite"],
                     ("  n/a " if c["bande_vide"]
                      else "%5.1f%%" % (100.0 * c["taux_couverture"])),
                     c["espacement_max_m"],
                     ("%.3f" % c["epaisseur_min_m"])
                     if c["epaisseur_min_m"] is not None else "  -  "))
            # LE CONTRÔLE APPARTIENT À LA BOUCLE `nom`, ET IL EN ÉTAIT SORTI.
            # Une substitution textuelle l'avait désindenté d'un cran : il
            # ne s'exécutait plus qu'une fois par STATION, sur la dernière
            # valeur de `c`, et seulement quand l'axe tombait dans la roche.
            # `manquements` restait donc vide, et le verdict imprimait
            # SUFFISANTE au-dessus d'une table descendue à 17,9 %.
            # C'est l'autocontrôle plus bas qui l'a attrapé — pas une
            # relecture, et c'est bien pour cela qu'il existe.
            if (not c["bande_vide"]
                    and c["taux_couverture"] < args.couverture_min - 1e-9):
                manquements.append(
                    dict(u=s["repere"]["u"], cote=nom,
                         taux=c["taux_couverture"],
                         espacement_max_m=c["espacement_max_m"],
                         largeur_m=c["largeur_reelle_m"],
                         rejets=c["rejets"]))
        if not s["axe_declare_dans_le_vide"]:
            axes_dans_la_roche.append(
                (s["repere"]["u"], s["bande_creuse_mesuree_m"]))

    taux_tous = [s["cotes"][n]["taux_couverture"]
                 for s in stations for n in ("gauche", "droite")
                 if not s["cotes"][n]["bande_vide"]] or [0.0]
    espac_max = max([s["cotes"][n]["espacement_max_m"]
                     for s in stations for n in ("gauche", "droite")
                     if not s["cotes"][n]["bande_vide"]] or [0.0])
    print()
    print("  taux minimal sur toutes les stations et les deux cotes : %.1f%%"
          % (100.0 * min(taux_tous)))
    print("  espacement maximal entre deux echantillons voisins   : %.3f m"
          % espac_max)

    # -- 3. LES ORIGINES ------------------------------------------------
    print()
    print("-" * 78)
    print("3. VALIDITE DES ORIGINES DE RAYON")
    print("-" * 78)
    echantillons = P.points_interieurs(args.pas_long, None, hauteurs, profil,
                                       pas_lateral_m=args.pas_lateral,
                                       marge_paroi_m=args.marge_paroi)
    dedans = hors_maillage = hors_env = 0
    for e in echantillons:
        vide, _ = P.dans_le_vide(grille, e["p"])
        if not vide:
            hors_maillage += 1
        elif not P.dans_enveloppe(e["p"], profil):
            hors_env += 1
        else:
            dedans += 1
    print("%d origine(s) generee(s) :" % len(echantillons))
    print("   %5d dans le vide du MAILLAGE **et** dans l'enveloppe NOMINALE"
          % dedans)
    print("   %5d dans la ROCHE — ecartees par dans_le_vide, jamais tirees"
          % hors_maillage)
    print("   %5d dans le vide mais HORS enveloppe — ecartees ; c'est cette"
          % hors_env)
    print("         classe qui fabriquait les 403 puis les 38 faux positifs")

    # -- 4. LES ZONES ---------------------------------------------------
    print()
    print("-" * 78)
    print("4. LES SEPT ZONES DONT LA COUVERTURE EST EXIGEE")
    print("-" * 78)
    zones = couverture_zones(profil, args.pas_long, args.pas_lateral,
                             hauteurs, stations)
    zones_rouges = []
    for nom in ZONES:
        z = zones[nom]
        etat = "COUVERTE" if z["couverte"] else "NON COUVERTE"
        print("   %-24s %-13s pas %.3f m" % (nom, etat, z["pas_m"]))
        print("        par  : %s" % z["par"])
        if z.get("taux_min") is not None:
            print("        taux : %.1f%% minimum" % (100.0 * z["taux_min"]))
        if z.get("note"):
            print("        note : %s" % z["note"])
        if not z["couverte"]:
            zones_rouges.append(nom)

    # -- VERDICT ---------------------------------------------------------
    print()
    print("=" * 78)
    print("VERDICT DE COUVERTURE (distinct du verdict d'etancheite)")
    print("=" * 78)
    if manquements:
        print("INSUFFISANTE — %d couple(s) (station, cote) sous %.0f%% :"
              % (len(manquements), 100.0 * args.couverture_min))
        for m in sorted(manquements, key=lambda x: x["taux"])[:12]:
            print("   u %4.2f  %-6s  largeur %.3f m  taux %5.1f%%  "
                  "espacement %.3f m  rejets %s"
                  % (m["u"], m["cote"], m["largeur_m"], 100.0 * m["taux"],
                     m["espacement_max_m"], m["rejets"]))
    else:
        print("SUFFISANTE — les deux cotes de toutes les stations sont "
              "couverts a %.0f%%," % (100.0 * args.couverture_min))
        print("avec un espacement maximal de %.3f m." % espac_max)

    # AUTOCONTROLE — le verdict ne peut pas contredire sa propre table.
    #
    # La premiere version de CE fichier a imprime « SUFFISANTE ... couverts
    # a 100% » au-dessus d'une table ou huit lignes affichaient 0,0 %. Le
    # defaut que cet outil est cense empecher, commis par l'outil lui-meme,
    # au premier essai. La regle « faire attention » ayant deja echoue une
    # fois, elle est remplacee par une comparaison.
    pire = min(taux_tous)
    coherent = (bool(manquements) == (pire < args.couverture_min - 1e-9))
    if not coherent:
        print()
        print("INCOHERENCE INTERNE — le verdict et la table ne disent pas la")
        print("meme chose : taux minimal tabule %.1f%%, manquements listes %d."
              % (100.0 * pire, len(manquements)))
        print("Le verdict est FORCE a INSUFFISANTE : entre une table et une")
        print("conclusion qui divergent, c'est la mesure qui a raison.")
        manquements = manquements or [dict(u=None, cote="?", taux=pire,
                                           espacement_max_m=espac_max,
                                           largeur_m=None,
                                           rejets="incoherence_interne")]
    if axes_dans_la_roche:
        print()
        print("AXE DECLARE DANS LA ROCHE — %d station(s) sur %d."
              % (len(axes_dans_la_roche), len(stations)))
        print("Ce n'est pas un defaut de couverture, c'est un ECART entre le")
        print("profil declare et la geometrie livree, et il prive de sens tous")
        print("les gardes analytiques centres sur cet axe : dans_enveloppe,")
        print("dans_le_noyau, _emprise_noyau, sort_par_la_bouche. Un « 0 percee »")
        print("y couvre donc nettement moins qu'il n'en a l'air.")
        for u_p, bande in axes_dans_la_roche[:14]:
            print("   u %4.2f  axe a 0.00 dans la roche ; vide reel %s"
                  % (u_p, ("%+.2f .. %+.2f" % tuple(bande)) if bande
                     else "AUCUN segment enclos trouve"))
    if zones_rouges:
        print("ZONES NON COUVERTES : %s" % ", ".join(zones_rouges))
    print()
    print("Ce verdict n'affirme AUCUNE etancheite. Il borne ce qu'un verdict")
    print("d'etancheite a le droit de couvrir — c'est tout, et c'est ce qui")
    print("manquait au « 0 percee » du tour precedent.")
    print("=" * 78)

    if args.json:
        dossier = os.path.dirname(args.json)
        if dossier and not os.path.isdir(dossier):
            os.makedirs(dossier)
        with open(args.json, "w", encoding="utf-8") as poignee:
            json.dump(dict(glb=args.glb, triangles=len(tris),
                           pas_lateral_m=args.pas_lateral,
                           pas_long=args.pas_long,
                           reperes=reperes, stations=stations, zones=zones,
                           origines=dict(total=len(echantillons),
                                         valides=dedans,
                                         dans_la_roche=hors_maillage,
                                         hors_enveloppe=hors_env),
                           taux_min=min(taux_tous),
                           espacement_max_m=espac_max,
                           manquements=manquements,
                           axes_dans_la_roche=[[u_p, b] for u_p, b in axes_dans_la_roche],
                           zones_non_couvertes=zones_rouges,
                           verdict=("INSUFFISANTE"
                                    if manquements or zones_rouges
                                    or axes_dans_la_roche
                                    else "SUFFISANTE")),
                      poignee, indent=1, sort_keys=True, ensure_ascii=False)
        print("sortie brute : %s" % args.json)

    return 1 if (manquements or zones_rouges or axes_dans_la_roche) else 0


if __name__ == "__main__":
    sys.exit(main())
