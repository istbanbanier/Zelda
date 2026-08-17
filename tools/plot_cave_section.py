#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Coupe technique et carte d'épaisseur de la grotte, depuis le GLB LIVRÉ.

POURQUOI CET OUTIL EXISTE
=========================

La revue R2a-3.5 exige, avant tout rendu monde, « une coupe (enveloppe,
galerie, cols, épaisseurs) » et « une carte de chaleur d'épaisseur ». Ni
l'une ni l'autre n'existait : le générateur imprime des nombres, la sonde
`probe_cave_openings.py` rend un verdict, et personne ne pouvait REGARDER
la relation entre le vide intérieur et la masse qui le porte.

Il mesure le `.glb` livré, pas les objets Blender. C'est la leçon d'ISS-018,
où tous les tests étaient verts sur des boîtes englobantes qui ne
décrivaient pas ce que le moteur dessine : **on mesure l'artefact livré.**

CE QU'IL MESURE, ET CE QU'IL NE MESURE PAS
==========================================

Il ne prononce aucun verdict. Il n'a pas de code retour d'échec sur la
forme — seulement sur l'impossibilité de mesurer. Le jugement appartient au
lead ; cet outil pose l'image devant lui.

DEUX NOMBRES POUR L'ÉPAISSEUR, ET C'EST DÉLIBÉRÉ
================================================

Depuis un point du vide, un rayon vers l'extérieur traverse d'abord la
paroi, puis peut ressortir dans un interstice entre deux masses avant de
retraverser de la roche. On publie donc :

* `premiere` — la longueur du PREMIER bloc de roche. C'est la lecture
  conservatrice : une coque de 0,20 m suivie d'un vide EST mince, quelle
  que soit la masse derrière.
* `totale` — la somme des blocs de roche sur le rayon. C'est la lecture
  généreuse.

Publier une seule des deux serait choisir la réponse avant de mesurer. La
carte de chaleur affiche `premiere` ; le JSON porte les deux, et l'écart
entre elles est lui-même un signal (un gros écart = la masse est faite de
morceaux disjoints à cet endroit).

DOMAINE DE VALIDITÉ
===================

**`JAMAIS UN PORTAIL ABSOLU D'ÉPAISSEUR`.** Cet outil sert à VOIR une coupe
et à comparer deux états ; il ne sert pas à décider si une épaisseur passe
un seuil.

Calibration sur un tube cylindrique de réponse connue — journal
`evidence/world_v2/v2_3_r2a/grotte/r2a352_collerette_croisee/calibration_de_ma_coupe.txt` :

    r      0,8     1,0     1,0     1,0     1,5     1,5     2,0   2,0
    R      1,5     2,2     1,6     1,3     2,7     1,8     2,3   3,2
    biais +0,0897 +0,0465 +0,0327 +0,0204 +0,0034 +0,0013 0,000 0,000

Il **SUR-ÉVALUE jusqu'à +0,0897 m**, et le biais dépend de la forme, pas du
pas — il n'est donc pas corrigible par une maille plus fine. La cause
supposée (origine de rayon hors de l'axe, le rayon parcourant une corde et
non un rayon) reste une **HYPOTHÈSE non vérifiée**.

Ce qui reste utilisable sans réserve : **les comptes** et **la structure
des blocs**. Ce qu'il ne faut pas citer : ses chiffres absolus d'épaisseur.
Pour un seuil, employer `tools/cave_collar.py` avec sa borne
`lecture − pas`, croisée avec l'EDT.

Second piège, hérité de la définition : `premiere` n'est **pas** « la
paroi » s'il existe une structure entre l'axe et le dehors — une nervure
intérieure, par exemple. C'est ainsi que « 24 rayons sous 0,80 m » a été
publié à tort, alors que la paroi réelle faisait 3,2 à 3,9 m.
"""

import argparse
import json
import math
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import probe_cave_openings as sonde                      # noqa: E402

try:
    from PIL import Image, ImageDraw
except ImportError:                                      # pragma: no cover
    sys.stderr.write("PIL est requis (python3-pil).\n")
    raise


## Le rayon part du ciel : la mesure de la roche AU-DESSUS d'un vide ne peut
## pas se faire en tirant vers le haut depuis la clé — sur un solide creux
## ce rayon mesure l'épaisseur de la voûte, pas la roche au-dessus. Erreur
## commise et corrigée en R2a-3.5.
CIEL_Z = 60.0
SOUS_SOL_Z = -40.0

## Une longueur de roche en deçà n'est pas une paroi, c'est une écaille de
## décimation. Même valeur que la sonde.
ECAILLE_M = sonde.ECAILLE_M


class Blocage(Exception):
    """Mesure impossible. Sort en 3, jamais en 0 (`tools/CLAUDE.md`)."""


def lire_seuils_du_generateur(source):
    """`(paroi, collerette)` LUS dans le générateur, jamais recopiés ici.

    POURQUOI CE N'EST PAS UNE CONSTANTE DE MODULE.

    Cet outil portait `EPAISSEUR_CONTRAT_M = 0.60` et traçait ce trait sous
    le titre « minimum contractuel ». 0,60 m est le minimum de la
    COLLERETTE ; celui de la PAROI est 0,80 m (`EPAISSEUR_MIN_M` du
    générateur). La carte déclarait donc conforme toute paroi entre 0,60 et
    0,80 m — l'œil situait la mesure contre le mauvais attendu.

    C'est ISS-044 : une télémétrie qui imprime une mesure sans son attendu,
    ou contre le mauvais, n'est pas un contrôle. Recopier la bonne valeur
    n'aurait déplacé la faute que d'un cran — deux nombres dans deux
    fichiers finissent toujours par diverger. Ils sont donc LUS, et leur
    absence est un blocage, pas un défaut silencieux.
    """
    if not os.path.isfile(source):
        raise Blocage("source du generateur introuvable : %s" % source)
    texte = open(source, "r", encoding="utf-8").read()
    seuils = {}
    for nom in ("EPAISSEUR_MIN_M", "EPAISSEUR_MIN_COLLERETTE_M"):
        marque = "\n%s = " % nom
        if marque not in texte:
            raise Blocage("constante %s absente de %s" % (nom, source))
        lu = texte.split(marque, 1)[1].split("\n", 1)[0].split("#")[0].strip()
        try:
            seuils[nom] = float(lu)
        except ValueError:
            raise Blocage("%s illisible : %r" % (nom, lu))
    return seuils["EPAISSEUR_MIN_M"], seuils["EPAISSEUR_MIN_COLLERETTE_M"]


## LE CÔTÉ est décidé par le SIGNE de la composante latérale du rayon, le
## long de la normale de section — même définition que le générateur et que
## `Profil.lateral()`. Les rayons strictement verticaux (azimut 90 et 270)
## n'appartiennent à AUCUNE paroi : les compter dans un minimum de paroi
## rejouerait la faute de cette passe, un chiffre qui répond à une autre
## question. Ils sont rangés à part, sous `zenith` et `nadir`.
COTE_GAUCHE, COTE_DROITE = "gauche", "droite"
COTE_ZENITH, COTE_NADIR = "zenith", "nadir"
COTES_PAROI = (COTE_GAUCHE, COTE_DROITE)


def cote_de_l_azimut(deg, tolerance=1e-9):
    """Range un azimut dans EXACTEMENT une classe. Partition, pas filtre."""
    rad = math.radians(deg)
    c = math.cos(rad)
    if c > tolerance:
        return COTE_DROITE
    if c < -tolerance:
        return COTE_GAUCHE
    return COTE_ZENITH if math.sin(rad) > 0.0 else COTE_NADIR


## L'ÉTAT D'UN RAYON — quatre cas, jamais fondus en un seul nombre.
##
## La version précédente écrivait `premiere = blocs[0] if blocs else 0.0`.
## « 0,00 m » y désignait indifféremment une paroi inexistante, la bouche de
## la grotte vue de côté, et un trou traversant. Un minimum calculé sur cette
## colonne rend donc « 0,00 m » au porche — vrai, alarmant, et sans rapport
## avec l'épaisseur d'une paroi. C'est la faute de cette passe en miniature :
## un chiffre qui répond à une autre question.
ETAT_MESURE = "MESURE"                  # de la roche, épaisseur exploitable
ETAT_BOUCHE = "AUCUNE_ROCHE_BOUCHE"     # sort par l'ouverture : normal
ETAT_TROU = "AUCUNE_ROCHE_TROU"         # sort ailleurs : percée traversante
ETAT_NON_MESURABLE = "NON_MESURABLE"    # origine hors du vide

## LA FIN DU PORCHE, et pourquoi la frontière n'est pas choisie par moi.
##
## `Profil.sol()` applique `porche_denivele` pour `u < 1.0` et pas au-delà :
## la station 0 est la BOUCHE, la station 1 le SEUIL. Le profil porte donc
## déjà la frontière, et la reprendre évite d'en inventer une.
##
## MESURÉ, ET C'EST CE QUI A FAILLI ME FAIRE PUBLIER 126 TROUS. Au porche,
## un rayon horizontal partant de l'axe ne rencontre aucune roche — ni à
## gauche ni à droite, et un décalage de 0,08 m le long de l'axe n'y change
## rien, donc ce n'est pas un artefact de rasance. C'est simplement que
## l'OUVERTURE est là : latéralement, au plan de bouche, on est devant le
## massif, pas dedans. Compter ces rayons comme des percées aurait été la
## faute même que cet outil doit rendre impossible — un chiffre alarmant
## qui répond à une autre question.
##
## Conséquence : sur `u < 1`, l'épaisseur de PAROI n'est pas définie. Le
## contrat applicable y est la COLLERETTE (l'anneau de roche autour de
## l'ouverture), et c'est ce seuil-là qui est imprimé en face des mesures.
U_PORCHE_FIN = 1.0


def zone_de_la_station(u):
    return "porche" if u < U_PORCHE_FIN else "galerie"


# --------------------------------------------------------------------------
# Mesure
# --------------------------------------------------------------------------

def _hauteur_enveloppe(grille, x, y):
    """Altitude du point le plus haut de la roche à l'aplomb de (x, y).

    Rayon DESCENDANT depuis le ciel : le premier impact est le sommet réel,
    quel que soit le nombre de vides en dessous.
    """
    frappes = sonde.impacts(grille, (x, y, CIEL_Z), (0.0, 0.0, -1.0),
                            portee=CIEL_Z - SOUS_SOL_Z)
    if not frappes:
        return None
    return CIEL_Z - frappes[0][0]


def _blocs_de_roche(grille, origine, direction, portee=60.0):
    """Longueurs des blocs pleins traversés, dans l'ordre.

    On ne se fie pas à l'orientation des faces — une normale retournée est
    un défaut fréquent et il ferait mentir la lecture. On compte par
    PARITÉ : entre le 1er et le 2e impact il y a de la matière, entre le 2e
    et le 3e du vide, et ainsi de suite. C'est la même convention que
    `controle_jour` de la sonde.
    """
    frappes = sonde.impacts(grille, origine, direction, portee=portee)
    ts = [t for t, _ in frappes]
    blocs = []
    for i in range(0, len(ts) - 1, 2):
        longueur = ts[i + 1] - ts[i]
        if longueur >= ECAILLE_M:
            blocs.append(longueur)
    return blocs


def _direction_transverse(profil, u):
    """Vecteur unitaire perpendiculaire à l'axe, horizontal."""
    du = 0.05
    a = profil.station(max(0.0, u - du))
    b = profil.station(min(len(profil.cavite) - 1.0, u + du))
    tx, ty = b[0] - a[0], b[1] - a[1]
    norme = math.hypot(tx, ty) or 1.0
    return (ty / norme, -tx / norme)


def mesurer_epaisseurs(grille, profil, pas_station=0.25, pas_azimut=10):
    """Épaisseur de roche autour de la cavité, station par station.

    L'origine de chaque rayon est le point d'axe remonté à mi-clé : il est
    franchement dans le vide, donc la première paroi rencontrée est bien la
    paroi de la galerie.
    """
    lignes = []
    u = 0.0
    umax = float(len(profil.cavite) - 1)
    while u <= umax + 1e-9:
        ax, ay, _, cle, palier = profil.station(u)
        sol = profil.sol(u, 0.0)
        origine = (ax, ay, sol + 0.5 * (palier + cle - sol))
        tx, ty = _direction_transverse(profil, u)
        # LE PROFIL EST NOMINAL, LA CAVITÉ RÉELLE EST MODELÉE. Aux stations
        # extrêmes — porche évasé, calotte du fond — le point d'axe théorique
        # peut tomber DANS la roche. Y tirer un rayon rend une « épaisseur »
        # de 0,00 m qui n'est pas un trou mais une mesure impossible.
        # Publier 0,00 dans ce cas serait un chiffre faux dans le sens le
        # plus dangereux : alarmant et infondé. On mesure `None`, et on le
        # compte à part.
        # PIÈGE MESURÉ : `dans_le_vide` rend un COUPLE `(bool, compte)`, et
        # `(False, 0)` est vrai en Python. La première écriture,
        # `mesurable = sonde.dans_le_vide(...)`, ne déclenchait donc jamais
        # sa propre garde et publiait « 0,00 m d'épaisseur » à la station 8,
        # là où le point d'axe théorique est simplement HORS du maillage.
        # Un garde-fou qui ne peut pas se fermer est pire que pas de
        # garde-fou : il donne confiance.
        mesurable, _ = sonde.dans_le_vide(grille, origine)
        mesures = []
        for deg in range(0, 360, pas_azimut):
            cote = cote_de_l_azimut(deg)
            if not mesurable:
                mesures.append(dict(azimut=deg, cote=cote, premiere=None,
                                    totale=None, blocs=0, vide=None,
                                    etat=ETAT_NON_MESURABLE))
                continue
            rad = math.radians(deg)
            # (tx, ty) EST la normale de section : la composante latérale du
            # rayon vaut donc cos(azimut), et son signe donne le côté.
            # 0° = vers +normale (droite), 180° = vers -normale (gauche),
            # 90° = zénith, 270° = nadir.
            dx = tx * math.cos(rad)
            dy = ty * math.cos(rad)
            dz = math.sin(rad)
            frappes = sonde.impacts(grille, origine, (dx, dy, dz), portee=60.0)
            ts = [t for t, _ in frappes]
            blocs = _blocs_de_roche(grille, origine, (dx, dy, dz))
            if blocs:
                etat, premiere = ETAT_MESURE, blocs[0]
            else:
                # AUCUNE ROCHE SUR 60 m. Deux causes très différentes, et les
                # confondre serait la faute de cette passe : au porche, un
                # rayon latéral sort par l'OUVERTURE, ce qui est le
                # fonctionnement d'une grotte ; ailleurs, c'est un trou
                # traversant. On demande l'arbitrage à la sonde elle-même,
                # dont le test de bouche est désormais correct par côté.
                premiere = None
                etat = (ETAT_BOUCHE
                        if (zone_de_la_station(u) == "porche"
                            or sonde.sort_par_la_bouche(origine, (dx, dy, dz),
                                                        profil))
                        else ETAT_TROU)
            mesures.append(dict(azimut=deg, cote=cote,
                                premiere=premiere,
                                totale=(sum(blocs) if blocs else None),
                                blocs=len(blocs), etat=etat,
                                # Distance du premier impact = demi-largeur
                                # RÉELLE du vide dans cette direction. C'est
                                # elle qui rend l'asymétrie visible.
                                vide=(round(ts[0], 3) if ts else None)))
        gauche, droite, inclinaison = profil.asym_station(u)
        hw = profil.station(u)[2]
        lignes.append(dict(u=round(u, 3), ax=round(ax, 3), ay=round(ay, 3),
                           origine_z=round(origine[2], 3),
                           mesurable=bool(mesurable), mesures=mesures,
                           # Le NOMINAL par côté, à côté du mesuré : sans lui
                           # la carte montre une asymétrie sans dire si elle
                           # est celle qui était voulue.
                           nominal=dict(hw=round(hw, 3),
                                        gauche=round(hw * gauche, 3),
                                        droite=round(hw * droite, 3),
                                        facteur_gauche=round(gauche, 3),
                                        facteur_droite=round(droite, 3),
                                        inclinaison=round(inclinaison, 3))))
        u += pas_station
    return lignes


def journal_des_minima(lignes, seuil_paroi, seuil_collerette):
    """Minimum PAR STATION ET PAR CÔTÉ, avec l'azimut qui le porte.

    C'EST LE LIVRABLE QUI REMPLACE LE CHIFFRE UNIQUE. La passe précédente a
    été validée sur « +1,36 m au linteau, 9/9 stations » : une mesure du
    TOIT, présentée comme un verdict d'enveloppe, pendant qu'un flanc
    traversait la roche sur 0,11 m. Un minimum global aurait dit la même
    chose ici — un seul nombre ne peut pas répondre pour deux parois.

    Chaque ligne porte donc sa valeur ET son seuil. Une valeur sans son
    attendu n'est pas un contrôle (ISS-044).
    """
    journal = []
    for ligne in lignes:
        zone = zone_de_la_station(ligne["u"])
        # LE SEUIL SUIT LA ZONE. Imprimer 0,80 m en face d'une mesure de
        # collerette, ou 0,60 m en face d'une paroi, serait la même faute
        # sous deux formes : une valeur comparée au mauvais attendu.
        seuil = seuil_collerette if zone == "porche" else seuil_paroi
        for cote in COTES_PAROI:
            duCote = [m for m in ligne["mesures"] if m["cote"] == cote]
            trous = [m for m in duCote if m["etat"] == ETAT_TROU]
            mesures = [m for m in duCote if m["etat"] == ETAT_MESURE]
            # UN TROU PRIME SUR UNE ÉPAISSEUR. Publier « 1,40 m » pour un
            # côté qui porte par ailleurs une percée traversante serait
            # exactement la faute qu'on répare : le minimum d'une colonne
            # ne dit rien de ce qui manque dans une autre.
            if trous:
                journal.append(dict(
                    u=ligne["u"], cote=cote, zone=zone,
                    azimut=trous[0]["azimut"], metres=None, totale=None,
                    seuil=seuil, verdict="TROU",
                    azimuts_troues=[m["azimut"] for m in trous],
                    detail="%d rayon(s) sans aucune roche, hors bouche"
                           % len(trous)))
                continue
            if not mesures:
                bouche = [m for m in duCote if m["etat"] == ETAT_BOUCHE]
                journal.append(dict(
                    u=ligne["u"], cote=cote, zone=zone, azimut=None,
                    metres=None, totale=None, seuil=seuil,
                    verdict=("BOUCHE" if bouche else "NON MESURABLE"),
                    detail=("%d rayon(s) sortent par l'ouverture" % len(bouche)
                            if bouche else "origine hors du vide")))
                continue
            pire = min(mesures, key=lambda m: m["premiere"])
            journal.append(dict(
                u=ligne["u"], cote=cote, zone=zone, azimut=pire["azimut"],
                metres=round(pire["premiere"], 3),
                totale=round(pire["totale"], 3),
                seuil=seuil,
                verdict=("PASS" if pire["premiere"] >= seuil else "FAIL")))
    return journal


def mesurer_crete(grille, profil, pas_y=0.20, pas_x=0.25):
    """Deux profils de hauteur le long de l'axe, et leur écart.

    * `axe`  — la roche à l'aplomb exact de la galerie ;
    * `crete` — le point le plus haut de TOUTE la tranche transverse.

    C'est leur ÉCART qui répond à la question de cette passe : une galerie
    rangée sous la masse dominante a une crête proche de son axe ; une
    galerie qui file sous les cols a une crête très à côté.
    """
    xs_lo = min(s[0] for s in profil.cavite) - 12.0
    xs_hi = max(s[0] for s in profil.cavite) + 12.0
    points = []
    u = 0.0
    umax = float(len(profil.cavite) - 1)
    while u <= umax + 1e-9:
        ax, ay, _, cle, palier = profil.station(u)
        haut_axe = _hauteur_enveloppe(grille, ax, ay)
        meilleur, meilleur_x = None, None
        x = xs_lo
        while x <= xs_hi:
            h = _hauteur_enveloppe(grille, x, ay)
            if h is not None and (meilleur is None or h > meilleur):
                meilleur, meilleur_x = h, x
            x += pas_x
        points.append(dict(
            u=round(u, 3), ax=round(ax, 3), ay=round(ay, 3),
            toit_galerie=round(palier + cle, 3),
            sol_galerie=round(profil.sol(u, 0.0), 3),
            enveloppe_sur_axe=(None if haut_axe is None
                               else round(haut_axe, 3)),
            crete_tranche=(None if meilleur is None else round(meilleur, 3)),
            crete_x=(None if meilleur_x is None else round(meilleur_x, 3))))
        u += max(0.05, pas_y / max(0.05, abs(
            profil.cavite[-1][1] - profil.cavite[0][1]) / umax))
    return points


def mesurer_section(grille, profil, u, pas_azimut=4):
    """Contours cavité et enveloppe dans le plan transverse à la station u."""
    ax, ay, _, cle, palier = profil.station(u)
    sol = profil.sol(u, 0.0)
    origine = (ax, ay, sol + 0.5 * (palier + cle - sol))
    tx, ty = _direction_transverse(profil, u)
    contour = []
    for deg in range(0, 360, pas_azimut):
        rad = math.radians(deg)
        dx, dy, dz = tx * math.cos(rad), ty * math.cos(rad), math.sin(rad)
        frappes = sonde.impacts(grille, origine, (dx, dy, dz), portee=60.0)
        ts = [t for t, _ in frappes]
        contour.append(dict(azimut=deg,
                            cavite=(ts[0] if ts else None),
                            enveloppe=(ts[-1] if ts else None)))
    return dict(u=round(u, 3), ax=round(ax, 3), ay=round(ay, 3),
                origine_z=round(origine[2], 3), contour=contour)


# --------------------------------------------------------------------------
# Dessin — PIL seulement, ni matplotlib ni numpy dans ce conteneur
# --------------------------------------------------------------------------

FOND = (250, 249, 246)
ENCRE = (36, 40, 48)
GRIS = (150, 155, 165)
ROCHE = (196, 178, 152)
VIDE = (86, 132, 168)
CRETE = (176, 82, 62)
ACCENT = (28, 118, 128)


class Repere(object):
    """Conversion données -> pixels, avec marges."""

    def __init__(self, boite, x0, y0, x1, y1):
        self.dx0, self.dy0, self.dx1, self.dy1 = boite
        self.px0, self.py0, self.px1, self.py1 = x0, y0, x1, y1
        self.sx = (x1 - x0) / max(1e-6, self.dx1 - self.dx0)
        self.sy = (y1 - y0) / max(1e-6, self.dy1 - self.dy0)

    def __call__(self, x, y):
        return (self.px0 + (x - self.dx0) * self.sx,
                self.py1 - (y - self.dy0) * self.sy)


def _cadre(d, rep, titre, pas_x=1.0, pas_y=1.0):
    d.rectangle([rep.px0, rep.py0, rep.px1, rep.py1], outline=GRIS)
    d.text((rep.px0, rep.py0 - 16), titre, fill=ENCRE)
    v = math.ceil(rep.dx0 / pas_x) * pas_x
    while v <= rep.dx1:
        px, _ = rep(v, rep.dy0)
        d.line([px, rep.py0, px, rep.py1], fill=(232, 232, 230))
        d.text((px + 2, rep.py1 + 3), "%g" % round(v, 3), fill=GRIS)
        v += pas_x
    v = math.ceil(rep.dy0 / pas_y) * pas_y
    while v <= rep.dy1:
        _, py = rep(rep.dx0, v)
        d.line([rep.px0, py, rep.px1, py], fill=(232, 232, 230))
        d.text((rep.px0 - 26, py - 6), "%g" % round(v, 3), fill=GRIS)
        v += pas_y


def _courbe(d, rep, points, couleur, largeur=2):
    prec = None
    for x, y in points:
        if y is None:
            prec = None
            continue
        cur = rep(x, y)
        if prec is not None:
            d.line([prec, cur], fill=couleur, width=largeur)
        prec = cur


def dessiner_coupe(crete, sections, profil, chemin, sous_titre):
    largeur, hauteur = 1600, 1180
    img = Image.new("RGB", (largeur, hauteur), FOND)
    d = ImageDraw.Draw(img)
    d.text((24, 18), "GROTTE DU COUCHANT - COUPE TECHNIQUE", fill=ENCRE)
    d.text((24, 34), sous_titre, fill=GRIS)

    ys = [p["ay"] for p in crete]
    zs = [v for p in crete
          for v in (p["crete_tranche"], p["enveloppe_sur_axe"],
                    p["sol_galerie"], p["toit_galerie"]) if v is not None]
    rep = Repere((min(ys) - 0.4, min(zs) - 0.6, max(ys) + 0.4, max(zs) + 0.9),
                 90, 92, largeur - 40, 560)
    _cadre(d, rep, "A - profil longitudinal — y du modele (m) / altitude (m)")

    # Masse de roche au-dessus de la galerie : entre le toit et l'enveloppe.
    for a, b in zip(crete, crete[1:]):
        if a["enveloppe_sur_axe"] is None or b["enveloppe_sur_axe"] is None:
            continue
        d.polygon([rep(a["ay"], a["toit_galerie"]),
                   rep(b["ay"], b["toit_galerie"]),
                   rep(b["ay"], b["enveloppe_sur_axe"]),
                   rep(a["ay"], a["enveloppe_sur_axe"])],
                  fill=(238, 230, 216))
    for a, b in zip(crete, crete[1:]):
        d.polygon([rep(a["ay"], a["sol_galerie"]),
                   rep(b["ay"], b["sol_galerie"]),
                   rep(b["ay"], b["toit_galerie"]),
                   rep(a["ay"], a["toit_galerie"])],
                  fill=(219, 233, 243))

    _courbe(d, rep, [(p["ay"], p["crete_tranche"]) for p in crete], CRETE, 3)
    _courbe(d, rep, [(p["ay"], p["enveloppe_sur_axe"]) for p in crete],
            ROCHE, 3)
    _courbe(d, rep, [(p["ay"], p["toit_galerie"]) for p in crete], VIDE, 2)
    _courbe(d, rep, [(p["ay"], p["sol_galerie"]) for p in crete], VIDE, 2)
    p0, p1 = rep(rep.dx0, 0.0), rep(rep.dx1, 0.0)
    d.line([p0, p1], fill=(120, 150, 120), width=1)

    d.text((rep.px0 + 8, rep.py0 + 8),
           "rouge = crete la plus haute de la tranche   "
           "sable = enveloppe a l'aplomb de l'axe   "
           "bleu = galerie (sol et cle)   vert = z zero", fill=ENCRE)

    # Panneau B : de combien la crête est-elle DÉCALÉE de l'axe ?
    rep2 = Repere((rep.dx0, -0.2, rep.dx1,
                   max(1.0, max(abs(p["crete_x"] - p["ax"])
                                for p in crete
                                if p["crete_x"] is not None) + 0.4)),
                  90, 640, largeur - 40, 812)
    _cadre(d, rep2, "B - ecart horizontal entre la crete et l'axe de galerie"
                    " (m) — proche de zero = la galerie est SOUS la masse",
           pas_y=0.5)
    _courbe(d, rep2, [(p["ay"],
                       None if p["crete_x"] is None
                       else abs(p["crete_x"] - p["ax"])) for p in crete],
            CRETE, 3)

    # Panneaux C : sections transverses.
    n = len(sections)
    marge, large = 90, (largeur - 130 - 30 * (n - 1)) // max(1, n)
    for k, sec in enumerate(sections):
        gx = marge + k * (large + 30)
        rayons = [c["enveloppe"] for c in sec["contour"] if c["enveloppe"]]
        rmax = (max(rayons) if rayons else 6.0) + 0.5
        rep3 = Repere((-rmax, -rmax, rmax, rmax), gx, 900, gx + large, 1140)
        _cadre(d, rep3, "C%d - section transverse, station u = %.2f"
               % (k + 1, sec["u"]), pas_x=2.0, pas_y=2.0)
        for cle, couleur, ferme in (("enveloppe", ROCHE, True),
                                    ("cavite", VIDE, True)):
            pts = []
            for c in sec["contour"]:
                if c[cle] is None:
                    continue
                rad = math.radians(c["azimut"])
                pts.append(rep3(c[cle] * math.cos(rad),
                                c[cle] * math.sin(rad)))
            if len(pts) > 2:
                d.line(pts + ([pts[0]] if ferme else []), fill=couleur,
                       width=2)
        d.line([rep3(-0.15, 0), rep3(0.15, 0)], fill=ENCRE)
        d.line([rep3(0, -0.15), rep3(0, 0.15)], fill=ENCRE)

    img.save(chemin)
    return chemin


def _pointille(d, rep, points, couleur, tiret=6, largeur=2):
    """Courbe en tirets — sert à distinguer le NOMINAL du MESURÉ."""
    prec = None
    reste = 0.0
    trace = True
    for x, y in points:
        if y is None:
            prec = None
            continue
        cur = rep(x, y)
        if prec is not None:
            dx, dy = cur[0] - prec[0], cur[1] - prec[1]
            longueur = math.hypot(dx, dy)
            parcouru = 0.0
            while parcouru < longueur:
                pas = min(tiret - reste, longueur - parcouru)
                a = (prec[0] + dx * parcouru / longueur,
                     prec[1] + dy * parcouru / longueur)
                b = (prec[0] + dx * (parcouru + pas) / longueur,
                     prec[1] + dy * (parcouru + pas) / longueur)
                if trace:
                    d.line([a, b], fill=couleur, width=largeur)
                parcouru += pas
                reste += pas
                if reste >= tiret - 1e-9:
                    reste = 0.0
                    trace = not trace
        prec = cur


def _extreme_par_cote(ligne, cote, cle):
    """Min de `cle` sur les rayons d'un côté. None si aucun n'est mesurable."""
    valeurs = [m[cle] for m in ligne["mesures"]
               if m["cote"] == cote and m.get(cle) is not None]
    return min(valeurs) if valeurs else None


def demi_largeur_mesuree(ligne, cote):
    """Distance à la paroi sur le rayon HORIZONTAL du côté.

    ET SURTOUT PAS le minimum sur tout l'hémisphère de ce côté. Un rayon à
    60° d'élévation touche la voûte : sa distance au premier impact est une
    hauteur sous plafond, pas une demi-largeur. Prendre le minimum des deux
    rend un nombre qui répond à une autre question — la faute même que cet
    outil existe pour rendre impossible, et que j'ai commise ici avant de
    REGARDER le dessin : le profil « mesuré » s'effondrait à 1,3 m dans la
    salle, non parce que la salle est étroite, mais parce que la voûte y est
    plus proche que la paroi.

    L'azimut horizontal vaut 0° pour `droite` (+normale) et 180° pour
    `gauche` (-normale).
    """
    vise = 0 if cote == COTE_DROITE else 180
    for m in ligne["mesures"]:
        if m["azimut"] == vise:
            return m.get("vide")
    return None


def dessiner_asymetrie(lignes, chemin, sous_titre, seuil_paroi):
    """VUE EN PLAN de la galerie : le vide et la roche, côté par côté.

    C'est la coupe que la revue réclame — « les profils asymétriques station
    par station » — et elle est construite pour qu'AUCUNE lecture ne puisse
    fusionner les deux flancs : `droite` se lit au-dessus de l'axe,
    `gauche` en dessous, à la même échelle. Une galerie symétrique y est un
    dessin symétrique ; un flanc aminci se voit sans lire un chiffre.

    Panneau A — demi-largeur du VIDE : nominale (tirets) contre mesurée
    (plein). Leur écart dit si l'asymétrie obtenue est celle qui était
    voulue, question à laquelle une carte d'épaisseur seule ne répond pas.

    Panneau B — épaisseur de ROCHE restante, minimum du côté. La bande
    rouge est le domaine sous contrat : elle est tracée depuis le seuil LU
    dans le générateur, pas depuis une constante de cet outil.
    """
    largeur, hauteur = 1600, 900
    img = Image.new("RGB", (largeur, hauteur), FOND)
    d = ImageDraw.Draw(img)
    d.text((24, 18), "GROTTE DU COUCHANT - PROFIL ASYMETRIQUE, "
                     "VUE EN PLAN (droite en haut, gauche en bas)", fill=ENCRE)
    d.text((24, 34), sous_titre, fill=GRIS)

    us = [l["u"] for l in lignes]
    u0, u1 = min(us), max(us)

    # ---- Panneau A : demi-largeur du vide, nominale contre mesurée -----
    larges = [l["nominal"]["gauche"] for l in lignes] \
        + [l["nominal"]["droite"] for l in lignes] \
        + [v for l in lignes for v in
           (demi_largeur_mesuree(l, COTE_GAUCHE),
            demi_largeur_mesuree(l, COTE_DROITE)) if v is not None]
    lim = max(larges) + 0.6
    repA = Repere((u0 - 0.2, -lim, u1 + 0.2, lim), 90, 92, largeur - 300, 430)
    _cadre(d, repA, "A - demi-largeur du VIDE (m). tirets = nominal "
                    "CAVITE_ASYM   plein = mesure sur le GLB", pas_y=1.0)
    d.line([repA(u0 - 0.2, 0.0), repA(u1 + 0.2, 0.0)], fill=(120, 150, 120))

    _pointille(d, repA, [(l["u"], l["nominal"]["droite"]) for l in lignes],
               ACCENT)
    _pointille(d, repA, [(l["u"], -l["nominal"]["gauche"]) for l in lignes],
               ACCENT)
    _courbe(d, repA, [(l["u"], demi_largeur_mesuree(l, COTE_DROITE))
                      for l in lignes], VIDE, 3)
    _courbe(d, repA, [(l["u"],
                       None if demi_largeur_mesuree(l, COTE_GAUCHE) is None
                       else -demi_largeur_mesuree(l, COTE_GAUCHE))
                      for l in lignes], VIDE, 3)
    d.text((repA.px0 + 8, repA.py0 + 8), "DROITE (+normale)", fill=ENCRE)
    d.text((repA.px0 + 8, repA.py1 - 20), "GAUCHE (-normale)", fill=ENCRE)

    # ---- Panneau B : roche restante, par côté -------------------------
    epais = [v for l in lignes for v in
             (_extreme_par_cote(l, COTE_GAUCHE, "premiere"),
              _extreme_par_cote(l, COTE_DROITE, "premiere")) if v is not None]
    haut = max(epais + [seuil_paroi]) + 0.5
    repB = Repere((u0 - 0.2, -haut, u1 + 0.2, haut), 90, 520, largeur - 300,
                  850)
    # La bande sous contrat est peinte AVANT les courbes : le rouge est le
    # domaine interdit, pas une couleur de courbe.
    # `Repere` inverse Y (l'écran croît vers le bas) : les coins doivent être
    # renormalisés, sinon PIL refuse y1 < y0.
    ca, cb = repB(u0 - 0.2, seuil_paroi), repB(u1 + 0.2, -seuil_paroi)
    d.rectangle([min(ca[0], cb[0]), min(ca[1], cb[1]),
                 max(ca[0], cb[0]), max(ca[1], cb[1])], fill=(252, 232, 228))
    _cadre(d, repB, "B - epaisseur de ROCHE restante, minimum du cote (m). "
                    "bande rouge = sous le minimum contractuel", pas_y=1.0)
    d.line([repB(u0 - 0.2, 0.0), repB(u1 + 0.2, 0.0)], fill=(120, 150, 120))
    for signe in (1.0, -1.0):
        p0, p1 = repB(u0 - 0.2, signe * seuil_paroi), \
            repB(u1 + 0.2, signe * seuil_paroi)
        d.line([p0, p1], fill=CRETE, width=2)
    _courbe(d, repB, [(l["u"], _extreme_par_cote(l, COTE_DROITE, "premiere"))
                      for l in lignes], ENCRE, 3)
    _courbe(d, repB, [(l["u"],
                       None if _extreme_par_cote(l, COTE_GAUCHE,
                                                 "premiere") is None
                       else -_extreme_par_cote(l, COTE_GAUCHE, "premiere"))
                      for l in lignes], ENCRE, 3)
    d.text((repB.px0 + 8, repB.py0 + 8), "DROITE (+normale)", fill=ENCRE)
    d.text((repB.px0 + 8, repB.py1 - 20), "GAUCHE (-normale)", fill=ENCRE)

    # ---- Légende chiffrée : la valeur ET son attendu -------------------
    lx = largeur - 285
    d.text((lx, 100), "MINIMA PAR COTE", fill=ENCRE)
    d.text((lx, 118), "seuil paroi lu au generateur : %.2f m" % seuil_paroi,
           fill=CRETE)
    y = 142
    for cote in COTES_PAROI:
        pires = [(l["u"], _extreme_par_cote(l, cote, "premiere"))
                 for l in lignes]
        pires = [(u, v) for u, v in pires if v is not None]
        if not pires:
            d.text((lx, y), "%-7s : NON MESURABLE" % cote, fill=GRIS)
            y += 18
            continue
        u_pire, v_pire = min(pires, key=lambda e: e[1])
        etat = "PASS" if v_pire >= seuil_paroi else "FAIL"
        d.text((lx, y), "%-7s min %.2f m / %.2f  %s"
               % (cote, v_pire, seuil_paroi, etat),
               fill=(ENCRE if etat == "PASS" else CRETE))
        d.text((lx + 12, y + 15), "a la station u = %.2f" % u_pire, fill=GRIS)
        y += 40
    img.save(chemin)
    return chemin


def _teinte(valeur, mini, maxi):
    """Bleu (épais) -> ivoire -> rouge (mince). Rouge = danger."""
    if valeur is None:
        return (225, 225, 225)
    t = 0.0 if maxi <= mini else (valeur - mini) / (maxi - mini)
    t = max(0.0, min(1.0, t))
    if t < 0.5:
        f = t / 0.5
        return (int(196 + (246 - 196) * f), int(72 + (238 - 72) * f),
                int(58 + (222 - 58) * f))
    f = (t - 0.5) / 0.5
    return (int(246 - (246 - 42) * f), int(238 - (238 - 96) * f),
            int(222 - (222 - 148) * f))


def dessiner_carte(lignes, chemin, sous_titre, seuil_paroi, plafond=4.0):
    """Carte station × azimut, AVEC le côté rendu explicite.

    Les lignes sont regroupées par côté et séparées par un trait : la carte
    ne peut plus être lue comme une seule paroi. Le seuil marqué est celui
    de la PAROI, lu au générateur — la version précédente traçait 0,60 m,
    minimum de la collerette, et déclarait donc conformes les parois entre
    0,60 et 0,80 m.
    """
    cell_x, cell_y = 26, 22
    n_l, n_c = len(lignes), len(lignes[0]["mesures"])
    # Ordre d'affichage : les deux parois en blocs contigus, les rayons
    # verticaux à part. Sans ce regroupement, `droite` est coupée en deux
    # (0-80° en haut, 280-350° en bas) et l'œil ne peut pas la lire.
    ordre = ([j for j, m in enumerate(lignes[0]["mesures"])
              if m["cote"] == COTE_DROITE]
             + [j for j, m in enumerate(lignes[0]["mesures"])
                if m["cote"] == COTE_ZENITH]
             + [j for j, m in enumerate(lignes[0]["mesures"])
                if m["cote"] == COTE_GAUCHE]
             + [j for j, m in enumerate(lignes[0]["mesures"])
                if m["cote"] == COTE_NADIR])
    largeur = 190 + n_l * cell_x + 300
    hauteur = 130 + n_c * cell_y + 70
    img = Image.new("RGB", (largeur, hauteur), FOND)
    d = ImageDraw.Draw(img)
    d.text((24, 18), "CARTE DE CHALEUR D'EPAISSEUR - premiere paroi, en m - "
                     "LES DEUX PAROIS, SEPAREES", fill=ENCRE)
    d.text((24, 34), sous_titre, fill=GRIS)
    d.text((24, 52), "rouge = mince   bleu = epais   "
                     "cadre noir + valeur = SOUS le minimum contractuel de "
                     "paroi %.2f m (lu au generateur)" % seuil_paroi,
           fill=ENCRE)
    d.text((24, 68), "croix pourpre = AUCUNE ROCHE hors bouche (percee)   "
                     "hachure bleue = sort par l'ouverture (normal)   "
                     "hachure grise = non mesurable", fill=GRIS)

    x0, y0 = 190, 118
    sous = 0
    for i, ligne in enumerate(lignes):
        if abs(ligne["u"] - round(ligne["u"])) < 1e-6:
            d.text((x0 + i * cell_x + 3, y0 - 16), "%d" % round(ligne["u"]),
                   fill=ENCRE)
        for rang, j in enumerate(ordre):
            m = ligne["mesures"][j]
            couleur = _teinte(m["premiere"], 0.0, plafond)
            px, py = x0 + i * cell_x, y0 + rang * cell_y
            d.rectangle([px, py, px + cell_x - 1, py + cell_y - 1],
                        fill=couleur)
            if m["premiere"] is None:
                # TROIS ABSENCES DIFFERENTES, TROIS MARQUES DIFFERENTES.
                # Les rendre identiques ferait disparaitre la percee — le
                # defaut le plus grave — dans le gris du « non mesurable ».
                if m["etat"] == ETAT_TROU:
                    d.rectangle([px, py, px + cell_x - 1, py + cell_y - 1],
                                fill=(122, 28, 74))
                    d.line([px + 3, py + 3, px + cell_x - 4, py + cell_y - 4],
                           fill=(255, 255, 255), width=2)
                    d.line([px + cell_x - 4, py + 3, px + 3, py + cell_y - 4],
                           fill=(255, 255, 255), width=2)
                elif m["etat"] == ETAT_BOUCHE:
                    d.rectangle([px, py, px + cell_x - 1, py + cell_y - 1],
                                fill=(226, 232, 236))
                    for k in range(0, cell_x + cell_y, 6):
                        d.line([px, py + k, px + k, py], fill=(168, 186, 198))
                else:
                    for k in range(0, cell_x + cell_y, 5):
                        d.line([px, py + k, px + k, py], fill=(196, 196, 196))
            elif m["premiere"] < seuil_paroi:
                sous += 1
                d.rectangle([px, py, px + cell_x - 1, py + cell_y - 1],
                            outline=(0, 0, 0), width=2)
                d.text((px + 2, py + 4), "%.2f" % m["premiere"],
                       fill=(255, 255, 255))

    # Étiquettes d'azimut + bandes de côté + séparateurs.
    precedent = None
    for rang, j in enumerate(ordre):
        m = lignes[0]["mesures"][j]
        py = y0 + rang * cell_y
        if m["azimut"] % 30 == 0:
            d.text((x0 - 62, py + 5), "%3d deg" % m["azimut"], fill=ENCRE)
        if m["cote"] != precedent:
            if precedent is not None:
                d.line([x0 - 70, py, x0 + n_l * cell_x, py], fill=ENCRE,
                       width=2)
            d.text((24, py + 4), m["cote"].upper(), fill=ACCENT)
            precedent = m["cote"]
    d.rectangle([x0, y0, x0 + n_l * cell_x, y0 + n_c * cell_y], outline=GRIS)
    d.text((x0, y0 + n_c * cell_y + 12), "station u de la galerie ->",
           fill=ENCRE)
    d.text((24, y0 + n_c * cell_y + 34),
           "0 deg = +normale (droite)   90 deg = zenith   "
           "180 deg = -normale (gauche)   270 deg = nadir   "
           "%d case(s) sous %.2f m" % (sous, seuil_paroi), fill=GRIS)
    img.save(chemin)
    return chemin


# --------------------------------------------------------------------------

def _sha_du_fichier(chemin):
    """DERNIER COMMIT touchant ce chemin. Ce n'est PAS le contenu."""
    try:
        sortie = subprocess.check_output(
            ["git", "log", "-1", "--format=%H", "--", chemin],
            stderr=subprocess.DEVNULL).decode().strip()
        return sortie or "inconnu"
    except Exception:                                    # pragma: no cover
        return "inconnu"


def _sha256_du_contenu(chemin):
    """sha256 des OCTETS du fichier mesuré.

    POURQUOI IL S'AJOUTE AU COMMIT, ET NE LE REMPLACE PAS.

    La chaîne d'export n'enregistre le `.blend` qu'à la dernière ligne de
    `main()` : une sortie anticipée rend un GLB au nom neuf, à la date
    neuve, et aux OCTETS DE LA VEILLE. Un commit git ne distingue pas ces
    deux cas — le fichier n'est pas encore indexé. Seul le hachage du
    contenu le fait, et il doit être comparé AVANT de croire une mesure.
    """
    import hashlib
    poids = hashlib.sha256()
    with open(chemin, "rb") as poignee:
        for morceau in iter(lambda: poignee.read(1 << 20), b""):
            poids.update(morceau)
    return poids.hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--glb",
                    default="assets/environment/caves/SM_WaterfallCave.glb")
    ap.add_argument("--noeud", default="SM_WaterfallCave")
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--sections", default="1,3,5",
                    help="stations u des coupes transverses")
    ap.add_argument("--pas-station", type=float, default=0.25)
    ap.add_argument("--pas-azimut", type=int, default=10)
    ap.add_argument("--source",
                    default="source_assets/blender/environment/"
                            "make_waterfall_cave.py",
                    help="generateur d'ou les SEUILS sont lus")
    args = ap.parse_args()

    if not os.path.isfile(args.glb):
        sys.stderr.write("BLOQUE: GLB introuvable : %s\n" % args.glb)
        return 3
    try:
        seuil_paroi, seuil_collerette = lire_seuils_du_generateur(args.source)
    except Blocage as erreur:
        sys.stderr.write("BLOQUE: %s\n" % erreur)
        return 3

    if not os.path.isdir(args.out_dir):
        os.makedirs(args.out_dir)

    tris, par_matiere = sonde.triangles_du_glb(args.glb, args.noeud)
    grille = sonde.Grille(tris)
    profil = sonde.PROFIL_GROTTE
    sha256 = _sha256_du_contenu(args.glb)
    print("triangles : %d  ·  matieres : %d" % (len(tris), len(par_matiere)))
    print("glb sha256 : %s" % sha256)
    print("seuils LUS au generateur : paroi %.2f m · collerette %.2f m"
          % (seuil_paroi, seuil_collerette))

    crete = mesurer_crete(grille, profil)
    epaisseurs = mesurer_epaisseurs(grille, profil, args.pas_station,
                                    args.pas_azimut)
    sections = [mesurer_section(grille, profil, float(u))
                for u in args.sections.split(",")]
    journal = journal_des_minima(epaisseurs, seuil_paroi, seuil_collerette)

    sha_glb = _sha_du_fichier(args.glb)
    sous_titre = ("%s - commit %s - sha256 %s - mesure du GLB LIVRE, "
                  "pas des objets Blender"
                  % (os.path.basename(args.glb), sha_glb[:7], sha256[:12]))

    coupe = dessiner_coupe(crete, sections, profil,
                           os.path.join(args.out_dir, "coupe_technique.png"),
                           sous_titre)
    carte = dessiner_carte(epaisseurs,
                           os.path.join(args.out_dir, "carte_epaisseur.png"),
                           sous_titre, seuil_paroi)
    asym = dessiner_asymetrie(
        epaisseurs, os.path.join(args.out_dir, "profil_asymetrique.png"),
        sous_titre, seuil_paroi)

    # LE JOURNAL DES MINIMA, en CSV : station, cote, azimut, valeur, seuil.
    chemin_csv = os.path.join(args.out_dir, "journal_minima.csv")
    with open(chemin_csv, "w", encoding="utf-8") as poignee:
        poignee.write("station_u,zone,cote,azimut_deg,epaisseur_premiere_m,"
                      "epaisseur_totale_m,seuil_m,verdict,detail\n")
        for e in journal:
            poignee.write("%.2f,%s,%s,%s,%s,%s,%.2f,%s,%s\n" % (
                e["u"], e["zone"], e["cote"],
                "" if e["azimut"] is None else e["azimut"],
                "" if e["metres"] is None else "%.3f" % e["metres"],
                "" if e.get("totale") is None else "%.3f" % e["totale"],
                e["seuil"], e["verdict"],
                (e.get("detail") or "").replace(",", ";")))

    ecarts = [(p["ay"], abs(p["crete_x"] - p["ax"]))
              for p in crete if p["crete_x"] is not None]
    non_mesurables = [l["u"] for l in epaisseurs if not l["mesurable"]]

    # LES MINIMA SONT PAR CÔTÉ, ET SEULEMENT PAR CÔTÉ. Il n'y a plus de
    # champ « epaisseur_min » global : c'est ce chiffre unique qui a validé
    # une enveloppe dont un flanc faisait 0,11 m.
    par_cote = {}
    for cote in COTES_PAROI:
        # LA GALERIE SEULE porte le contrat de PAROI. Le porche est l'ouverture
        # elle-meme ; l'y melanger rendrait un minimum de 0,00 m qui parle de
        # la bouche et pas d'une paroi.
        duCote = [e for e in journal
                  if e["cote"] == cote and e["zone"] == "galerie"]
        mesurables = [e for e in duCote if e["metres"] is not None]
        trous = [e for e in duCote if e["verdict"] == "TROU"]
        info = dict(seuil=seuil_paroi,
                    stations_trouees=len(trous),
                    stations_trouees_u=[e["u"] for e in trous],
                    stations_sous_seuil=sum(1 for e in mesurables
                                            if e["verdict"] == "FAIL"),
                    stations_mesurees=len(mesurables))
        if mesurables:
            pire = min(mesurables, key=lambda e: e["metres"])
            info.update(mesurable=True, u=pire["u"], azimut=pire["azimut"],
                        metres=pire["metres"], verdict=pire["verdict"])
        else:
            info.update(mesurable=False)
        par_cote[cote] = info

    galerie = [l for l in epaisseurs
               if zone_de_la_station(l["u"]) == "galerie"]
    porche = [l for l in epaisseurs
              if zone_de_la_station(l["u"]) == "porche"]
    rayons = [(l["u"], m["cote"], m["azimut"], m["premiere"])
              for l in galerie for m in l["mesures"]
              if m["etat"] == ETAT_MESURE and m["cote"] in COTES_PAROI]
    rayons_troues = [(l["u"], m["cote"], m["azimut"])
                     for l in galerie for m in l["mesures"]
                     if m["etat"] == ETAT_TROU and m["cote"] in COTES_PAROI]
    rayons_bouche = sum(1 for l in epaisseurs for m in l["mesures"]
                        if m["etat"] == ETAT_BOUCHE
                        and m["cote"] in COTES_PAROI)
    # LE PORCHE A SON PROPRE CONTRAT : la collerette.
    collerette = [(l["u"], m["cote"], m["azimut"], m["premiere"])
                  for l in porche for m in l["mesures"]
                  if m["etat"] == ETAT_MESURE and m["cote"] in COTES_PAROI]

    resume = dict(
        glb=args.glb, glb_commit=sha_glb, glb_sha256=sha256,
        triangles=len(tris),
        seuil_paroi_m=seuil_paroi, seuil_collerette_m=seuil_collerette,
        seuils_source=args.source,
        minima_par_cote=par_cote,
        rayons_paroi_mesures=len(rayons),
        rayons_paroi_sous_seuil=sum(1 for r in rayons if r[3] < seuil_paroi),
        rayons_paroi_troues=len(rayons_troues),
        rayons_paroi_troues_detail=[dict(u=u, cote=c, azimut=a)
                                    for u, c, a in rayons_troues],
        rayons_paroi_par_la_bouche=rayons_bouche,
        collerette=dict(
            rayons_mesures=len(collerette),
            rayons_sous_seuil=sum(1 for r in collerette
                                  if r[3] < seuil_collerette),
            minimum_m=(round(min(r[3] for r in collerette), 3)
                       if collerette else None),
            seuil_m=seuil_collerette),
        stations_non_mesurables=non_mesurables,
        ecart_crete_axe=dict(
            min=round(min(e[1] for e in ecarts), 3),
            max=round(max(e[1] for e in ecarts), 3),
            moyen=round(sum(e[1] for e in ecarts) / len(ecarts), 3)),
        images=[coupe, carte, asym], journal_csv=chemin_csv)
    with open(os.path.join(args.out_dir, "coupe.json"), "w",
              encoding="utf-8") as poignee:
        json.dump(dict(resume=resume, crete=crete, epaisseurs=epaisseurs,
                       sections=sections, journal_minima=journal), poignee,
                  indent=1, ensure_ascii=False)

    # LA VALEUR EST TOUJOURS IMPRIMÉE AVEC SON ATTENDU (ISS-044).
    print()
    print("MINIMA PAR COTE — valeur / seuil  (jamais un chiffre unique)")
    for cote in COTES_PAROI:
        info = par_cote[cote]
        if info["mesurable"]:
            print("  %-7s : %.2f m / %.2f m  %s   (station u = %.2f, "
                  "azimut %d deg)"
                  % (cote, info["metres"], info["seuil"], info["verdict"],
                     info["u"], info["azimut"]))
        else:
            print("  %-7s : aucune epaisseur exploitable" % cote)
        print("            stations sous seuil %d/%d · stations TROUEES %d%s"
              % (info["stations_sous_seuil"], info["stations_mesurees"],
                 info["stations_trouees"],
                 ("" if not info["stations_trouees_u"] else
                  "  (u = %s)" % ", ".join("%.2f" % u for u
                                           in info["stations_trouees_u"][:8])))
              )
    print("rayons de paroi sous %.2f m : %d sur %d mesures  (galerie seule)"
          % (seuil_paroi, resume["rayons_paroi_sous_seuil"], len(rayons)))
    print("rayons de paroi SANS ROCHE dans la galerie : %d  "
          "(indication de percee — la CONFIRMATION appartient a "
          "probe_cave_openings)" % len(rayons_troues))
    col = resume["collerette"]
    print("PORCHE (u < %.1f) — contrat COLLERETTE : minimum %s / %.2f m, "
          "%d rayon(s) sous seuil sur %d ; %d rayon(s) sans roche = "
          "l'OUVERTURE, pas un defaut"
          % (U_PORCHE_FIN,
             ("n/a" if col["minimum_m"] is None
              else "%.2f m" % col["minimum_m"]),
             col["seuil_m"], col["rayons_sous_seuil"], col["rayons_mesures"],
             rayons_bouche))
    print("stations non mesurables : %s"
          % (", ".join("%.2f" % u for u in non_mesurables) or "aucune"))
    print("ecart crete/axe : min %.2f  moyen %.2f  max %.2f m"
          % (resume["ecart_crete_axe"]["min"],
             resume["ecart_crete_axe"]["moyen"],
             resume["ecart_crete_axe"]["max"]))
    print("images  : %s" % ", ".join([coupe, carte, asym]))
    print("journal : %s" % chemin_csv)
    # Aucun verdict de sortie : cet outil MESURE et DESSINE, il ne juge pas.
    # Le gate appartient a la sonde et au lead.
    return 0


if __name__ == "__main__":
    sys.exit(main())
