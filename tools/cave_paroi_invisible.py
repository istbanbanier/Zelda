#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""PAROI INVISIBLE — `COL_` compare a `SM_` sur le MEME rayon, du MEME point.

CONVENTION DE CODES RETOUR — R2a-3.5.8, ICI SEULEMENT
=====================================================
    0 = PASS      1 = FAIL      3 = BLOQUE      >=4 = erreur d'outil

POURQUOI CE FICHIER EXISTE, ALORS QUE 3.5.7 A DEJA COMPARE COL ET SM
====================================================================
La comparaison de 3.5.7 etait DEUX passes independantes de largeur aux
stations d'axe. Elle ne peut pas voir une plaque de collision locale HORS
AXE — exactement le cas des 0,845 m de la niche qui a motive le refus du
reglage 0,50. Aucun instrument existant ne mesure `d_SM` et `d_COL` sur le
meme rayon depuis le meme point, et aucun ne marche de la salle a la niche.

LA REFERENCE DE MARGE EST FIGEE, ET C'EST UN ARBITRAGE DU LEAD
==============================================================
Premiere consigne : lire la marge dans la revision du GLB mesure. ANNULEE
par le lead lui-meme — c'est une circularite : si la revision mesuree change
le terme d'alcove, une marge lue chez elle la suit, et l'instrument ne voit
jamais la paroi qu'il doit mesurer. Un instrument dont la reference bouge
avec le sujet ne mesure rien.

Regle corrigee : `marge_prevue` se fige sur l'etat `86b01ece` — la pile
f39b232 + massif_lissage.patch (5b9d4734…) + patch intersections
(sha256 86b01ece…). Cet etat a ete RECONSTRUIT depuis les patches et prouve
identique au bit pres a l'arbre b_chaine (5e09940e…), puis epingle dans
l'evidence. L'outil exige le sha256 de la reference (`--sha-reference`) et
rend BLOQUE si le fichier a bouge.

LE MODELE DE MARGE DE `86b01ece`, LU DANS SON CODE, PAS SUPPOSE
===============================================================
`anneau_interieur` y fait, pour la cavite de collision :

    hw'  = max(0.05, hw - COL_MARGE_LAT)
    demi = hw' * asym_cote
    ampl_alcove = max(0.0, ALCOVE["ampl"] - COL_MARGE_LAT * asym_cote)
    n    = demi*w + ampl_alcove*F - rentree        (F = le_long*fenetre*gauss)

et pour la cavite visible : les memes formules a retraits nuls. Le recul
perpendiculaire COL derriere SM vaut donc EXACTEMENT :

    dn(tf) = ML*asym*w(tf) + min(AMPL, ML*asym) * F(tf, u, v)

borne superieure (w <= 1+AMP exactement — la somme des coefficients de
`bruit()` vaut 1,00 ; F <= 1) :

    marge_prevue(u, cote) = ML*asym(u,cote)*(1+AMP)
                          + [cote alcove et u dans [i0,i1]] * min(AMPL, ML*asym)

Le terme d'alcove est applique sur TOUTE la fenetre de stations et d'azimut
du cote alcove — sur-inclusif, donc CONSERVATEUR : il ne peut qu'elargir la
marge admise, jamais fabriquer un faux rouge.

DEFINITION EXECUTABLE APPLIQUEE (plan §2 approuve, reference corrigee)
======================================================================
En un point p du volume jouable, azimut horizontal theta, hauteur y de la
bande du corps :

    ecart(p,theta,y) = d_SM - d_COL          (premier impact, exact ~1e-9 m)
    paroi invisible <=> ecart*cos(beta) - marge_prevue > PLANCHER_VERDICT_M

`cos(beta)` rabat l'ecart le long du rayon sur la perpendiculaire aux
surfaces ; les rayons rasants |cos| < COS_MIN ne portent pas de verdict et
sont comptes. `ecart < 0` = COL DERRIERE la roche visible : penetration,
couloir de l'agent collision — publie, jamais juge ici. Les rayons qui ne
touchent qu'UN des deux maillages (saillie exterieure preexistante, bouche)
sont comptes et etiquetes, jamais juges : « prexistant » est le mot du lead.

VERDICT FONCTIONNEL, EN PLUS DU CHAMP
=====================================
Marche du chemin canonique (abscisse en LONGUEUR D'ARC, jamais un indice de
station) et du segment salle->niche, capsule de
`cave_largeur_seuil.ajustement_capsule` (le critere paye trois fois : la
capsule REPOSE sur le sol) contre COL_ et SM_ :

    paroi invisible fonctionnelle <=> la capsule tient contre SM_ avec un
    jeu >= marge_prevue_max + plancher, et NE tient PAS contre COL_.

Un echec contre les DEUX maillages est un PASSAGE ETROIT — defaut de
traversabilite, pas de paroi invisible — etiquete separement.

LA JAUGE DE POCHE DE LA NICHE (contre-pouvoir du plafond du lead)
=================================================================
Le lead a donne a l'agent collision un plancher chiffre : la profondeur de
poche de l'alcove en collision ne descend pas sous 0,524 m (l'etat 0,40
juge acceptable ; le refus du 0,50 venait de sa chute a 0,355 m).
Definition operatoire publiee avec le chiffre : depuis le point d'axe le
plus proche de l'ancre de niche, au meme plan de coupe, la profondeur de
poche d'un maillage est

    poche(X) = max des d_X dans la fenetre angulaire de l'alcove
             - d_X de reference hors fenetre (paroi de galerie, mediane
               des azimuts a plus de dtheta+15 deg du centre, meme cote)

Publiee pour COL_ et SM_. `--plancher-poche 0.524` arme le verdict (GLB de
l'agent A) ; sans lui la jauge publie sans juger (rodage).

TROIS DEFAUTS PAYES AU RODAGE (40714c46), CORRIGES EN v2
========================================================
1. QUATRIEME OCCURRENCE DU PIEGE DU PLANCHER. `ajustement_capsule` (3.5.7)
   mesure la distance 3D de l'axe a TOUTE la geometrie : sur un sol en
   pente d'angle a, le plan du sol est a r*cos(a) du bas de l'axe, donc
   jeu = r*(cos a - 1) < 0 SANS AUCUNE PAROI. Mesure au rodage : -0,0216 m
   identique sur COL_ et SM_ (leurs sols sont identiques par conception),
   soit a = 18 deg — la rampe de la cuvette. Le critere juste est celui du
   journal 23 de 3.5.7 : LARGEUR DE BANDE cylindrique [sol+r, sol+h-r],
   distance HORIZONTALE exacte — un sol de pente s n'entre dans la bande
   qu'a une distance horizontale r/s > r tant que s < 1 (45 deg). La
   capsule juge donc ici sur la bande ; le jeu 3D reste au CSV.
2. LE LONG DU RAYON N'EST PAS LA PROFONDEUR — NI LE LONG DE LA NORMALE.
   v1 : un rayon quasi axial touche COL_ au virage et SM_ au fond, ecart
   enorme sans paroi. v2 (normale de la face touchee) : quand les parois
   ne sont pas paralleles, le rayon normal court parallelement au mur SM
   et traverse le vide (+4,9 m mesures pour une marge de 0,13). v3 : la
   profondeur est la DISTANCE 2D de l'impact COL a la surface SM la plus
   proche du meme plan de coupe — une distance point->surface, seule
   grandeur qui dit « la collision se dresse a X m de toute roche
   visible ».
3. VERDICT SUR POINTS OCCUPABLES SEULEMENT. La definition (plan §2) dit
   « point du volume jouable » ; v1 jugeait aussi le fond inoccupable et
   le porche. v2 ne fait porter le verdict du champ que sur les points ou
   la capsule tient contre SM_ (bande) ; le reste est telemetrie.

CE QUE L'OUTIL PUBLIE TOUJOURS (piege paye : « publier la taille de ce
qu'on a examine ») : triangles par maillage, echantillons, rayons lances,
touches, rasants ecartes, impacts uniques, et la detectabilite angulaire
d*sin(pas) au pire impact.
"""

import argparse
import ast
import hashlib
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from cave_exact_intersect import lire_glb  # noqa: E402
from cave_largeur_seuil import (  # noqa: E402
    lire_maillage, sol_sous, ajustement_capsule, couper_demi_espace,
    distance_horizontale, CAPSULE_HAUTEUR_M, TOLERANCE_TANGENCE_M,
    CAVITE_MODELE)

PLANCHER_VERDICT_M = 0.01   # arrondi + termes croises interp + pas d'axe
COS_MIN = 0.30
PORTEE_RAYON_M = 12.0
RAYON_PREFILTRE_M = 1.6


## ------------------------------------------------------------ reference figee
def lire_reference_figee(chemin, sha_attendu):
    """Constantes de marge de l'etat 86b01ece, verifiees par sha256.

    BLOQUE si le fichier a change, si la formule d'alcove attendue n'y est
    pas mot pour mot, ou si sa table CAVITE ne correspond pas a la copie en
    dur des instruments repris (garde de tables)."""
    donnees = open(chemin, "rb").read()
    sha = hashlib.sha256(donnees).hexdigest()
    if not sha.startswith(sha_attendu):
        raise SystemExit("BLOQUE: reference figee alteree — sha256 %s, "
                         "attendu %s…" % (sha[:16], sha_attendu[:16]))
    src = donnees.decode("utf-8")
    if 'ampl_alcove = max(0.0, ALCOVE["ampl"] - retrait_alcove * asym)' \
            not in src:
        raise SystemExit("BLOQUE: la formule d'alcove attendue n'est pas "
                         "dans la reference — le modele de marge ne vaut pas")
    if "retrait_alcove=retrait_lat" not in src:
        raise SystemExit("BLOQUE: `construire()` de la reference ne passe "
                         "pas retrait_alcove=retrait_lat")

    def constante(nom):
        m = re.search(r"^%s = ([0-9.]+)" % nom, src, re.M)
        if not m:
            raise SystemExit("BLOQUE: %s introuvable dans la reference" % nom)
        return float(m.group(1))

    ml = constante("COL_MARGE_LAT")
    amp = constante("AMP_INTERIEUR")
    m = re.search(r"^CAVITE_ASYM = \[(.*?)^\]", src, re.S | re.M)
    asym = ast.literal_eval("[" + re.sub(r"#[^\n]*", "", m.group(1)) + "]")
    m = re.search(r"^ALCOVE = dict\((.*?)\)\n", src, re.S | re.M)
    corps = m.group(1)
    alcove = {}
    for cle in ("i0", "i1", "ampl", "dtheta"):
        mm = re.search(r"%s\s*=\s*(math\.radians\()?([0-9.]+)" % cle, corps)
        v = float(mm.group(2))
        alcove[cle] = math.radians(v) if mm.group(1) else v
    if lire_cavite_source(src) != arrondie(CAVITE_MODELE):
        raise SystemExit("BLOQUE: CAVITE de la reference != table en dur "
                         "des instruments repris (garde de tables)")
    return dict(ml=ml, amp=amp, asym=asym, alcove=alcove, sha=sha)


def lire_cavite_source(src):
    m = re.search(r"^CAVITE = \[(.*?)^\]", src, re.S | re.M)
    if not m:
        raise SystemExit("BLOQUE: CAVITE introuvable")
    cav = ast.literal_eval("[" + re.sub(r"#[^\n]*", "", m.group(1)) + "]")
    return arrondie([(ax, -ay) for (ax, ay, hw, cle) in cav])


def arrondie(pts):
    return [(round(a, 6), round(b, 6)) for (a, b) in pts]


def marge_prevue(ref, u, cote_gauche, cote_alcove_est_gauche=True):
    """Borne superieure du recul nominal COL derriere SM a l'abscisse u."""
    asym = ref["asym"]
    i = max(0, min(len(asym) - 1, int(math.floor(u))))
    j = min(len(asym) - 1, i + 1)
    t = max(0.0, min(1.0, u - i))
    g = asym[i][0] * (1.0 - t) + asym[j][0] * t
    d = asym[i][1] * (1.0 - t) + asym[j][1] * t
    a = g if cote_gauche else d
    marge = ref["ml"] * a * (1.0 + ref["amp"])
    en_fenetre = (ref["alcove"]["i0"] - 0.5 <= u <= ref["alcove"]["i1"] + 0.5)
    if en_fenetre and (cote_gauche == cote_alcove_est_gauche):
        marge += min(ref["alcove"]["ampl"], ref["ml"] * a)
    return marge


## ------------------------------------------------------------------ chemin
def polyligne_arc(points, pas):
    """(t_m, x, z, u) le long d'une polyligne — abscisse en LONGUEUR D'ARC,
    jamais un indice de station (les tables different entre revisions).
    `u` n'est publie que comme etiquette."""
    longueurs = []
    total = 0.0
    for i in range(len(points) - 1):
        d = math.hypot(points[i + 1][0] - points[i][0],
                       points[i + 1][1] - points[i][1])
        longueurs.append(d)
        total += d
    sortie = []
    n = max(1, int(math.ceil(total / pas)))
    for k in range(n + 1):
        t = total * k / float(n)
        reste = t
        for i, d in enumerate(longueurs):
            if reste <= d or i == len(longueurs) - 1:
                f = 0.0 if d < 1e-12 else min(1.0, reste / d)
                x = points[i][0] + (points[i + 1][0] - points[i][0]) * f
                z = points[i][1] + (points[i + 1][1] - points[i][1]) * f
                sortie.append((t, x, z, i + f))
                break
            reste -= d
    return sortie, total


def u_le_plus_proche(points, x, z):
    meilleur, meilleur_d = 0.0, float("inf")
    for i in range(len(points) - 1):
        ax, az = points[i]
        bx, bz = points[i + 1]
        dx, dz = bx - ax, bz - az
        l2 = dx * dx + dz * dz
        f = 0.0 if l2 < 1e-18 else max(
            0.0, min(1.0, ((x - ax) * dx + (z - az) * dz) / l2))
        d = math.hypot(x - (ax + dx * f), z - (az + dz * f))
        if d < meilleur_d:
            meilleur_d, meilleur = d, i + f
    return meilleur


def point_polyligne(points, u):
    u = max(0.0, min(len(points) - 1.0, u))
    i = min(len(points) - 2, int(math.floor(u)))
    f = u - i
    return (points[i][0] + (points[i + 1][0] - points[i][0]) * f,
            points[i][1] + (points[i + 1][1] - points[i][1]) * f)


def normale_laterale(points, u):
    eps = 0.02
    ax, az = point_polyligne(points, u - eps)
    bx, bz = point_polyligne(points, u + eps)
    tx, tz = bx - ax, bz - az
    n = math.hypot(tx, tz)
    if n < 1e-9:
        return (1.0, 0.0)
    return (-tz / n, tx / n)


## ------------------------------------------------------- coupe et rayons 2D
def filtre_2d(P, T, x, z, r=RAYON_PREFILTRE_M):
    """Triangles dont la boite horizontale approche (x,z) a moins de `r`.
    Exact pour tout minimum < r — vrai dans une galerie ou le sol existe."""
    sortie = []
    for tri in T:
        a, b, c = P[tri[0]], P[tri[1]], P[tri[2]]
        if min(a[0], b[0], c[0]) - x > r or x - max(a[0], b[0], c[0]) > r:
            continue
        if min(a[2], b[2], c[2]) - z > r or z - max(a[2], b[2], c[2]) > r:
            continue
        sortie.append(tri)
    return sortie


def segments_au_plan(P, T, y):
    """Coupe chaque triangle par le plan horizontal y -> segments 2D."""
    segs = []
    for (ia, ib, ic) in T:
        tri = (P[ia], P[ib], P[ic])
        ys = [p[1] for p in tri]
        if min(ys) > y or max(ys) < y:
            continue
        pts = []
        for k in range(3):
            a, b = tri[k], tri[(k + 1) % 3]
            da, db = a[1] - y, b[1] - y
            if da == 0.0 and db == 0.0:
                continue
            if (da > 0.0 and db < 0.0) or (da < 0.0 and db > 0.0):
                f = da / (da - db)
                pts.append((a[0] + (b[0] - a[0]) * f,
                            a[2] + (b[2] - a[2]) * f))
            elif da == 0.0:
                pts.append((a[0], a[2]))
        if len(pts) >= 2:
            (x0, z0), (x1, z1) = pts[0], pts[1]
            if (x0 - x1) ** 2 + (z0 - z1) ** 2 > 1e-18:
                segs.append((x0, z0, x1, z1))
    return segs


def premier_impact(segs, px, pz, dx, dz):
    meilleur_t, meilleur_cos = None, None
    for (ax, az, bx, bz) in segs:
        ex, ez = bx - ax, bz - az
        den = dx * ez - dz * ex
        if abs(den) < 1e-15:
            continue
        t = ((ax - px) * ez - (az - pz) * ex) / den
        s = ((ax - px) * dz - (az - pz) * dx) / den
        if t <= 1e-9 or t > PORTEE_RAYON_M or s < 0.0 or s > 1.0:
            continue
        if meilleur_t is None or t < meilleur_t:
            ln = math.hypot(ex, ez)
            meilleur_cos = abs(dx * (-ez / ln) + dz * (ex / ln))
            meilleur_t = t
    return meilleur_t, meilleur_cos


def largeur_bande(P, T, x, z, sol, rayon, hauteur):
    """Largeur libre de la partie CYLINDRIQUE de la capsule — le critere du
    journal 23 de 3.5.7. Bande [sol+r, sol+h-r] : le plancher (appui) et la
    calotte haute en sont exclus PAR CONSTRUCTION. Distance horizontale
    exacte (decoupage par plans + distance 2D fermee), erreur ~1e-9 m."""
    bas, haut = sol + rayon, sol + hauteur - rayon
    pire = float("inf")
    for (ia, ib, ic) in T:
        tri = [P[ia], P[ib], P[ic]]
        if min(p[1] for p in tri) > haut or max(p[1] for p in tri) < bas:
            continue
        poly = couper_demi_espace(tri, True, bas)
        poly = couper_demi_espace(poly, False, haut)
        if not poly:
            continue
        d = distance_horizontale(poly, x, z)
        if d < pire:
            pire = d
    return pire


def dist_point_segment_2d(px, pz, ax, az, bx, bz):
    ex, ez = bx - ax, bz - az
    l2 = ex * ex + ez * ez
    if l2 < 1e-18:
        return math.hypot(px - ax, pz - az)
    t = max(0.0, min(1.0, ((px - ax) * ex + (pz - az) * ez) / l2))
    return math.hypot(px - (ax + ex * t), pz - (az + ez * t))


def profondeur_2d(segs_col, segs_sm, px, pz, dx, dz):
    """Impact COL du rayon, puis distance 2D de cet impact a la surface SM
    LA PLUS PROCHE dans le meme plan de coupe.

    v2 mesurait derriere l'impact le long de la NORMALE de la face : paye
    au rodage — quand les parois COL et SM ne sont pas paralleles (virage,
    coin de facette), le rayon normal court PARALLELEMENT au mur SM et
    traverse le vide (+4,9 m mesures pour une marge de 0,13). La
    profondeur d'une paroi invisible est une distance POINT->SURFACE, pas
    un rayon : « a quelle distance de toute roche visible la collision
    se dresse-t-elle ». Rend (d_col, d_sm_rayon, prof, cos_beta)."""
    meilleur_t, cosb = None, None
    for (ax, az, bx, bz) in segs_col:
        ex, ez = bx - ax, bz - az
        den = dx * ez - dz * ex
        if abs(den) < 1e-15:
            continue
        t = ((ax - px) * ez - (az - pz) * ex) / den
        s = ((ax - px) * dz - (az - pz) * dx) / den
        if t <= 1e-9 or t > PORTEE_RAYON_M or s < 0.0 or s > 1.0:
            continue
        if meilleur_t is None or t < meilleur_t:
            ln = math.hypot(ex, ez)
            cosb = abs(dx * (-ez / ln) + dz * (ex / ln))
            meilleur_t = t
    d_sm, _ = premier_impact(segs_sm, px, pz, dx, dz)
    if meilleur_t is None:
        return None, d_sm, None, None
    hx = px + dx * meilleur_t
    hz = pz + dz * meilleur_t
    prof = None
    for (ax, az, bx, bz) in segs_sm:
        d = dist_point_segment_2d(hx, hz, ax, az, bx, bz)
        if prof is None or d < prof:
            prof = d
    return meilleur_t, d_sm, prof, cosb


## -------------------------------------------------------------------- poche
def jauge_poche(Pc, Tc, Ps, Ts, points_axe, niche, ref, signe_gauche, et):
    """Poche de l'alcove — par le DIFFERENTIEL SM-COL dans sa direction.

    Trois versions payees au rodage : (v1) fenetre de scan plus etroite que
    la bande de reference — jauge muette ; (v3) reference par bandes
    adjacentes — contaminee par la forme de la salle (rayons frolant le
    vide du couloir, "poche" de 1,9 a 2,5 m pour une amplitude de 1,2).

    v4 s'appuie sur l'ALGEBRE MEME du plafond du lead. Ses chiffres
    (1,20 / 0,524 / 0,355) sont les valeurs d'`ampl_alcove` :

        ampl_col = max(0, AMPL - retrait * asym)          [86b01ece]

    Dans la direction de la poche, au ventre du fondu (F ~ 1, w ~ 1) :

        d_SM - d_COL = ML*asym*w + (AMPL - ampl_col)*F

    d'ou l'ESTIMATEUR, publie avec ses hypotheses :

        ampl_col_estime = AMPL - (d_SM - d_COL) + ML*asym_local

    Erreur annoncee : |w-1| <= AMP et F <= 1 au point vise ->
    +- (AMP*ML*asym + (1-F)*termes), dominee par ~0,06 m si l'on vise le
    ventre. C'est une jauge de gate, pas un micromometre : le plafond du
    lead est un MINIMUM exige, et l'estimateur est publie avec d_SM, d_COL
    et la direction pour que la revue refasse le calcul.

    Deux directions visees, publiees toutes deux :
      * depuis l'axe au ventre du fondu (u = (i0+i1)/2), le long du cote
        alcove (gauche) ;
      * depuis l'axe le plus proche de l'ancre de niche, vers l'ancre —
        la direction que le joueur emprunte reellement.
    """
    i0, i1 = ref["alcove"]["i0"], ref["alcove"]["i1"]
    ampl = ref["alcove"]["ampl"]
    cibles = []
    u_v = (i0 + i1) / 2.0
    axv = point_polyligne(points_axe, u_v)
    nv = normale_laterale(points_axe, u_v)
    cibles.append(("ventre", u_v, axv,
                   (nv[0] * signe_gauche, nv[1] * signe_gauche)))
    u_n = u_le_plus_proche(points_axe, niche[0], niche[1])
    axn = point_polyligne(points_axe, u_n)
    dxn, dzn = niche[0] - axn[0], niche[1] - axn[1]
    ln = math.hypot(dxn, dzn)
    if ln > 1e-9:
        cibles.append(("vers l'ancre", u_n, axn, (dxn / ln, dzn / ln)))
    resultats = {}
    for nom_c, u_c, (ax, az), (dx, dz) in cibles:
        sol_c = sol_sous(Pc, Tc, ax, az, 0.09)
        sol_s = sol_sous(Ps, Ts, ax, az, 0.09)
        if sol_c is None or sol_s is None:
            print("%s[poche] %s : aucun sol a l'axe u=%.2f" % (et, nom_c, u_c))
            continue
        ## viser bas dans la bande du corps : la gaussienne en v de la
        ## poche culmine pres de v0=0.05, donc pres de l'horizontale.
        y = 0.50
        segs_c = segments_au_plan(Pc, Tc, sol_c + y)
        segs_s = segments_au_plan(Ps, Ts, sol_s + y)
        d_col, _ = premier_impact(segs_c, ax, az, dx, dz)
        d_sm, _ = premier_impact(segs_s, ax, az, dx, dz)
        if d_col is None or d_sm is None:
            print("%s[poche] %s : rayon sans impact (COL %s, SM %s)"
                  % (et, nom_c, d_col, d_sm))
            continue
        i = max(0, min(len(ref["asym"]) - 1, int(round(u_c))))
        asym_g = ref["asym"][i][0]
        estime = ampl - (d_sm - d_col) + ref["ml"] * asym_g
        resultats[nom_c] = dict(d_sm=d_sm, d_col=d_col, estime=estime,
                                u=u_c, y=y)
        print("%s[poche] %s : u=%.2f axe (%.2f, %.2f) y=sol+%.2f | "
              "d_SM=%.4f d_COL=%.4f diff=%.4f | ampl_col estime = %.4f m "
              "(AMPL=%.2f, ML*asym=%.3f ; hypotheses F~1, w~1, "
              "erreur ~0,06 m)"
              % (et, nom_c, u_c, ax, az, y, d_sm, d_col, d_sm - d_col,
                 estime, ampl, ref["ml"] * asym_g))
    return resultats


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("glb")
    ap.add_argument("--reference", required=True,
                    help="source figee 86b01ece (marge_prevue)")
    ap.add_argument("--sha-reference", required=True,
                    help="sha256 attendu de la reference (prefixe accepte)")
    ap.add_argument("--provenance-glb", default="",
                    help="source du generateur de la revision du GLB mesure "
                         "— garde de tables CAVITE, RC=3 si divergence")
    ap.add_argument("--salle", default="2.62,-2.58")
    ap.add_argument("--niche", default="2.78,-4.09")
    ap.add_argument("--rayons", default="0.45,0.35")
    ap.add_argument("--pas-chemin", type=float, default=0.10)
    ap.add_argument("--pas-angle", type=float, default=2.0)
    ap.add_argument("--hauteurs", default="0.50,0.95,1.30")
    ap.add_argument("--borne-etalonnage", type=float, default=0.0,
                    help="borne de discretisation MESUREE sur l'etat de "
                         "reference (rodage/06_etalonnage_borne.log) ; "
                         "s'ajoute au plancher pour le verdict du champ")
    ap.add_argument("--plancher-poche", type=float, default=None,
                    help="arme le verdict de poche (0.524 pour le GLB A)")
    ap.add_argument("--csv", default="")
    ap.add_argument("--etiquette", default="")
    args = ap.parse_args()

    et = ("[%s] " % args.etiquette) if args.etiquette else ""
    ref = lire_reference_figee(args.reference, args.sha_reference)
    print("%s[paroi] reference figee %s… : ML=%.2f AMP=%.3f "
          "ALCOVE(ampl=%.2f, i0=%.0f, i1=%.0f, dtheta=%.0f deg)"
          % (et, ref["sha"][:16], ref["ml"], ref["amp"],
             ref["alcove"]["ampl"], ref["alcove"]["i0"], ref["alcove"]["i1"],
             math.degrees(ref["alcove"]["dtheta"])))
    if args.provenance_glb:
        cav_prov = lire_cavite_source(
            open(args.provenance_glb, encoding="utf-8").read())
        if cav_prov != arrondie(CAVITE_MODELE):
            print("%s[paroi] BLOQUE: CAVITE de la provenance du GLB != "
                  "table des instruments (garde de tables)" % et)
            return 3
        print("%s[paroi] garde de tables : CAVITE provenance GLB == "
              "instruments (%d stations)" % (et, len(CAVITE_MODELE)))

    rayons = [float(v) for v in args.rayons.split(",")]
    hauteurs = [float(v) for v in args.hauteurs.split(",")]
    salle = tuple(float(v) for v in args.salle.split(","))
    niche = tuple(float(v) for v in args.niche.split(","))

    gltf, blob = lire_glb(args.glb)
    Pc, Tc = lire_maillage(gltf, blob, "COL_WaterfallCave")
    Ps, Ts = lire_maillage(gltf, blob, "SM_WaterfallCave")
    if Pc is None or Ps is None:
        print("BLOQUE: COL_ ou SM_ absent du GLB")
        return 3
    print("%s[paroi] COL %d tris, SM %d tris ; plancher %.3f m ; "
          "|cos| >= %.2f ; pas angulaire %.1f deg"
          % (et, len(Tc), len(Ts), PLANCHER_VERDICT_M, COS_MIN,
             args.pas_angle))

    canon, long_canon = polyligne_arc(CAVITE_MODELE, args.pas_chemin)
    t_seuil = math.hypot(CAVITE_MODELE[1][0] - CAVITE_MODELE[0][0],
                         CAVITE_MODELE[1][1] - CAVITE_MODELE[0][1])
    seg_n, long_niche = polyligne_arc([salle, niche], args.pas_chemin)
    echantillons = ([("canon", t, x, z, u) for (t, x, z, u) in canon]
                    + [("niche", t, x, z,
                        u_le_plus_proche(CAVITE_MODELE, x, z))
                       for (t, x, z, u) in seg_n])
    print("%s[paroi] chemin canonique %.2f m (%d pts) + salle->niche "
          "%.2f m (%d pts), pas %.2f m"
          % (et, long_canon, len(canon), long_niche, len(seg_n),
             args.pas_chemin))

    ## CALIBRATION DU COTE sur la geometrie, pas sur une convention. A la
    ## station la plus asymetrique, le cote le plus LARGE de SM_ est le cote
    ## qui porte le plus grand multiplicateur.
    u_cal = max(range(len(ref["asym"])),
                key=lambda i: abs(ref["asym"][i][0] - ref["asym"][i][1]))
    u_cal = float(min(u_cal, len(CAVITE_MODELE) - 2))
    cx, cz = point_polyligne(CAVITE_MODELE, u_cal)
    signe_gauche = -1.0
    sol_cal = sol_sous(Ps, Ts, cx, cz, 0.09)
    if sol_cal is not None:
        segs_cal = segments_au_plan(Ps, Ts, sol_cal + 0.95)
        nx, nz = normale_laterale(CAVITE_MODELE, u_cal)
        dplus, _ = premier_impact(segs_cal, cx, cz, nx, nz)
        dmoins, _ = premier_impact(segs_cal, cx, cz, -nx, -nz)
        if dplus is not None and dmoins is not None:
            i = int(u_cal)
            gauche_est_large = ref["asym"][i][0] > ref["asym"][i][1]
            signe_gauche = (+1.0 if (gauche_est_large == (dplus > dmoins))
                            else -1.0)
    print("%s[paroi] calibration du cote a u=%.1f : gauche = normale %s"
          % (et, u_cal, "+" if signe_gauche > 0 else "-"))
    ## L'alcove (theta section = 180 deg) est du cote GAUCHE du generateur.
    cote_alcove_est_gauche = True

    n_angles = int(round(360.0 / args.pas_angle))
    csv = open(args.csv, "w", encoding="utf-8") if args.csv else None
    if csv:
        csv.write("famille,t_m,x,z,u,theta_deg,y,d_SM,d_COL,ecart,cos_beta,"
                  "marge_prevue,prof_normale,exces,occupable_sm\n")

    lancers = touches = rasants = negatifs = uniques = 0
    pires = []
    pire_detect = 0.0
    lignes = []
    for (fam, t, x, z, u) in echantillons:
        sol_c = sol_sous(Pc, Tc, x, z, 0.09)
        sol_s = sol_sous(Ps, Ts, x, z, 0.09)
        if sol_c is None or sol_s is None:
            lignes.append((fam, t, x, z, u, None, None, None, None,
                           "aucun sol (%s)"
                           % ("COL" if sol_c is None else "SM")))
            continue
        plans_c = {y: segments_au_plan(Pc, Tc, sol_c + y) for y in hauteurs}
        plans_s = {y: segments_au_plan(Ps, Ts, sol_c + y) for y in hauteurs}
        nx, nz = normale_laterale(CAVITE_MODELE, u)
        ## OCCUPABILITE d'abord : le verdict du champ ne porte que sur les
        ## points ou la capsule tient contre SM_ (bande — v2, defaut 1 et 3).
        r0 = rayons[0]
        Tc_f = filtre_2d(Pc, Tc, x, z)
        Ts_f = filtre_2d(Ps, Ts, x, z)
        larg_c = largeur_bande(Pc, Tc_f, x, z, sol_c, r0, CAPSULE_HAUTEUR_M)
        larg_s = largeur_bande(Ps, Ts_f, x, z, sol_s, r0, CAPSULE_HAUTEUR_M)
        jeu_c, jeu_s = larg_c - r0, larg_s - r0
        occupable_sm = jeu_s >= -TOLERANCE_TANGENCE_M
        ## Le porche est HORS CONTRAT : la jupe de collision (SKIRT_COL) y
        ## est couverte par le terrain gele, un corps que cet outil ne voit
        ## pas — limite documentee par 3.5.7. Telemetrie, pas verdict.
        en_contrat = not (fam == "canon" and t < t_seuil - 1e-9)
        occupable_sm = occupable_sm and en_contrat
        pire_exces, pire_adr = -float("inf"), "-"
        pire_ecart = -float("inf")
        for k in range(n_angles):
            th = math.radians(k * args.pas_angle)
            dx, dz = math.cos(th), math.sin(th)
            for y in hauteurs:
                lancers += 1
                d_col, d_sm, prof, cosb = profondeur_2d(
                    plans_c[y], plans_s[y], x, z, dx, dz)
                ## LA MARGE EST LOCALE A L'IMPACT, PAS A L'ECHANTILLON.
                ## Paye au rodage v3 : un rayon quasi axial parti de u=2
                ## touche la paroi a u=6, ou la marge vaut 0,676 m
                ## (0,40 x 1,69) — la comparer a celle de u=2 (0,25)
                ## fabrique un faux exces de +0,43.
                if d_col is not None:
                    hx_, hz_ = x + dx * d_col, z + dz * d_col
                    u_hit = u_le_plus_proche(CAVITE_MODELE, hx_, hz_)
                    nhx, nhz = normale_laterale(CAVITE_MODELE, u_hit)
                    ahx, ahz = point_polyligne(CAVITE_MODELE, u_hit)
                    cote_gauche = ((hx_ - ahx) * nhx + (hz_ - ahz) * nhz) \
                        * signe_gauche > 0.0
                    mp = marge_prevue(ref, u_hit, cote_gauche,
                                      cote_alcove_est_gauche)
                else:
                    cote_gauche = (dx * nx + dz * nz) * signe_gauche > 0.0
                    mp = marge_prevue(ref, u, cote_gauche,
                                      cote_alcove_est_gauche)
                if d_sm is None or d_col is None:
                    if d_sm is not None or d_col is not None:
                        uniques += 1
                    continue
                touches += 1
                ecart = d_sm - d_col
                if ecart < -PLANCHER_VERDICT_M:
                    negatifs += 1
                exces = None
                if prof is None:
                    rasants += 1     # aucun segment SM dans ce plan
                else:
                    exces = prof - mp
                    if occupable_sm and exces > pire_exces:
                        pire_exces = exces
                        pire_adr = ("th=%03.0f y=%.2f cote=%s prof=%.3f "
                                    "d_COL=%.3f mp=%.3f"
                                    % (math.degrees(th), y,
                                       "G" if cote_gauche else "D",
                                       prof, d_col, mp))
                        pire_detect = max(
                            pire_detect,
                            d_col * math.sin(math.radians(args.pas_angle)))
                if ecart > pire_ecart:
                    pire_ecart = ecart
                if csv:
                    csv.write("%s,%.2f,%.3f,%.3f,%.2f,%.1f,%.2f,%.4f,%.4f,"
                              "%.4f,%.3f,%.4f,%s,%s,%d\n"
                              % (fam, t, x, z, u, math.degrees(th), y,
                                 d_sm, d_col, ecart,
                                 cosb if cosb is not None else float("nan"),
                                 mp,
                                 "%.4f" % prof if prof is not None else "",
                                 "%.4f" % exces if exces is not None else "",
                                 1 if occupable_sm else 0))
        mp_max = max(marge_prevue(ref, u, True, cote_alcove_est_gauche),
                     marge_prevue(ref, u, False, cote_alcove_est_gauche))
        lignes.append((fam, t, x, z, u, jeu_c, jeu_s, pire_exces,
                       pire_ecart, mp_max, sol_c - sol_s, occupable_sm,
                       en_contrat))
        if occupable_sm and pire_exces > -float("inf"):
            pires.append((pire_exces, fam, t, x, z, pire_adr))
    if csv:
        csv.close()

    print()
    print("%s      %-6s %-6s %-7s %-7s %-5s %9s %9s %8s %9s %6s" %
          (et, "fam", "t_m", "x", "z", "u", "jeuB_COL", "jeuB_SM",
           "dsol", "exces_max", "occ_SM"))
    fonctionnels, etroits = [], []
    seuil_champ = PLANCHER_VERDICT_M + args.borne_etalonnage
    atteinte_niche = None
    for l in lignes:
        fam, t, x, z, u = l[0], l[1], l[2], l[3], l[4]
        if l[5] is None:
            print("%s      %-6s %-6.2f %-7.2f %-7.2f %-5.2f  %s"
                  % (et, fam, t, x, z, u, l[9]))
            continue
        (jeu_c, jeu_s, exces, _ecart, mp_max, dsol, occ, en_contrat) = (
            l[5], l[6], l[7], l[8], l[9], l[10], l[11], l[12])
        marque = ""
        if not en_contrat and jeu_c < -TOLERANCE_TANGENCE_M:
            ## v4d — paye au controle (c) : le marqueur fonctionnel flambait
            ## aussi sur le porche, hors contrat (jupe/terrain non
            ## mesurables ici). Telemetrie, pas verdict.
            marque = "hors contrat (porche)"
        elif jeu_c < -TOLERANCE_TANGENCE_M:
            ## v4b — la premiere regle (jeu_SM >= mp_max + plancher) etait
            ## quasi inatteignable : la galerie est a peine plus large que
            ## la marge maximale, donc TOUT echec COL se classait etroit,
            ## meme un mur artificiel de 0,35 m au seuil. Le discriminant
            ## juste est le DIFFERENTIEL jeu_SM - jeu_COL : quand les deux
            ## jeux se prennent sur la meme paroi, il est borne par le
            ## recul nominal ; au-dela, la collision se dresse dans du
            ## vide visible. Seuil = mp_max + plancher + etalonnage.
            if (jeu_s - jeu_c) > mp_max + seuil_champ:
                marque = "PAROI INVISIBLE (fonctionnelle)"
                fonctionnels.append((fam, t, x, z, jeu_c, jeu_s))
            else:
                marque = "etroit (COL et SM)"
                etroits.append((fam, t, x, z, jeu_c, jeu_s))
        elif fam == "niche":
            d_reste = math.hypot(x - niche[0], z - niche[1])
            if atteinte_niche is None or d_reste < atteinte_niche:
                atteinte_niche = d_reste
        print("%s      %-6s %-6.2f %-7.2f %-7.2f %-5.2f %9.4f %9.4f %8.4f "
              "%9.4f %6s  %s"
              % (et, fam, t, x, z, u, jeu_c, jeu_s, dsol,
                 exces if exces > -float("inf") else float("nan"),
                 "oui" if occ else "non", marque))
    if atteinte_niche is not None:
        print()
        print("%s[paroi] ATTEINTE DE LA NICHE : la capsule r=%.2f tient "
              "contre COL_ jusqu'a %.3f m de l'ancre de niche (portee "
              "d'interaction du projet : 1,8-2,4 m)"
              % (et, rayons[0], atteinte_niche))

    print()
    print("%s[paroi] examine : %d rayons, %d doubles touches, %d rasants "
          "ecartes, %d ecarts negatifs (COL derriere SM — couloir "
          "collision, publie non juge), %d impacts uniques (bouche/"
          "saillie exterieure : preexistant, publie non juge)"
          % (et, lancers, touches, rasants, negatifs, uniques))
    print("%s[paroi] detectabilite au pire impact retenu : une plaque plus "
          "etroite que %.3f m peut passer entre deux rayons"
          % (et, pire_detect))
    pires.sort(key=lambda p: p[0], reverse=True)
    print("%s[paroi] cinq pires exces (ecart*cos - marge_prevue) :" % et)
    for (e, fam, t, x, z, adr) in pires[:5]:
        print("%s        %+8.4f m  %s t=%.2f (%.2f, %.2f)  %s"
              % (et, e, fam, t, x, z, adr))

    poches = jauge_poche(Pc, Tc, Ps, Ts, CAVITE_MODELE, niche, ref,
                         signe_gauche, et)

    champ_rouge = [p for p in pires if p[0] > seuil_champ]
    echec = False
    if champ_rouge:
        echec = True
        print("%s[paroi] CHAMP : %d point(s) au-dela du seuil %.3f m "
              "(plancher %.3f + etalonnage %.3f) -> PAROI INVISIBLE"
              % (et, len(champ_rouge), seuil_champ, PLANCHER_VERDICT_M,
                 args.borne_etalonnage))
    else:
        print("%s[paroi] CHAMP : aucun exces au-dela du seuil %.3f m "
              "(plancher %.3f + etalonnage %.3f)"
              % (et, seuil_champ, PLANCHER_VERDICT_M,
                 args.borne_etalonnage))
    if fonctionnels:
        echec = True
        print("%s[paroi] FONCTIONNEL : capsule r=%.2f bloquee par COL_ "
              "dans du vide SM_ a %d point(s)"
              % (et, rayons[0], len(fonctionnels)))
    else:
        print("%s[paroi] FONCTIONNEL : la capsule r=%.2f n'est bloquee "
              "par COL_ dans du vide SM_ nulle part" % (et, rayons[0]))
    if etroits:
        print("%s[paroi] NOTE : %d passage(s) etroit(s) contre les DEUX "
              "maillages — traversabilite, pas paroi invisible : %s"
              % (et, len(etroits),
                 "; ".join("%s t=%.2f" % (f, t)
                           for (f, t, _x, _z, _jc, _js) in etroits[:4])))
    if atteinte_niche is not None and atteinte_niche > 2.4:
        echec = True
        print("%s[paroi] ATTEINTE : %.3f m > 2,4 m (portee d'interaction "
              "max du projet) -> la recompense est INATTEIGNABLE" %
              (et, atteinte_niche))
    if args.plancher_poche is not None and poches:
        ## v4c — paye au controle negatif (b) : le verdict ne regardait que
        ## la direction du VENTRE ; un mur artificiel dans la direction de
        ## l'ancre (estime -0,97) passait vert. Le verdict porte sur le MIN
        ## des directions mesurees — la poche doit tenir PARTOUT ou le
        ## joueur la traverse. NB : dans la fenetre d'alcove le CHAMP est
        ## aveugle PAR CONSTRUCTION (la marge figee y admet le recul
        ## legitime de 86b01ece, ~1,41 m) ; cette jauge est le controle
        ## qui police la poche.
        pire_dir = min(poches, key=lambda k: poches[k]["estime"])
        est = poches[pire_dir]["estime"]
        if est < args.plancher_poche:
            echec = True
            print("%s[paroi] POCHE : ampl_col estime %.4f m (direction "
                  "'%s') < plancher %.3f m (arbitrage lead) -> ROUGE DE "
                  "GATE" % (et, est, pire_dir, args.plancher_poche))
        else:
            print("%s[paroi] POCHE : ampl_col estime %.4f m (pire "
                  "direction '%s') >= plancher %.3f m"
                  % (et, est, pire_dir, args.plancher_poche))
    print("FIN NOMINALE")
    return 1 if echec else 0


if __name__ == "__main__":
    sys.exit(main())
