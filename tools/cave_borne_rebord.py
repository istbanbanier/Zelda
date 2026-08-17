#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""L'epaisseur est BORNEE PAR LA DISTANCE AU REBORD. Demonstration et consequences.

POURQUOI CE FICHIER EXISTE
==========================

`docs/ADDENDUM_MASQUE_BOUCHE.md` §2bis pose la loi de rebord progressive :

    e_requise(p) = min( d(p) , 0,80 m )

ou `d(p)` est la distance geodesique, sur la peau interieure, du point `p` au
contour de bouche Gamma. La directive exige de plus que le portail porte sur la
BORNE CONSERVATRICE `lecture - h`, jamais sur la mesure centrale.

J'ai commit `8034885` prouvant que cette loi est de pente 1, donc la loi d'un
rebord a angle exactement droit. Ce fichier va plus loin et etablit que la
situation est pire : la loi n'est saturee par AUCUNE geometrie avec la moindre
marge, et ce n'est pas une propriete de cette grotte.

LE THEOREME, EN TROIS LIGNES
============================

`docs/CONTRAT_COQUE_STRUCTURELLE.md` §2.6 definit l'epaisseur en un point de la
peau interieure comme la distance euclidienne a la surface EXTERIEURE la plus
proche :

    e(p) = dist( p , S_ext )

Gamma est, par construction, la courbe ou la peau interieure s'arrete et ou la
surface exterieure commence : Gamma est donc CONTENUE dans S_ext. Alors

    (1)  e(p) = dist(p, S_ext)  <=  dist(p, Gamma)      car Gamma est dans S_ext
    (2)  dist(p, Gamma)         <=  d(p)                euclidien <= geodesique

    ==>  e(p) <= d(p)   pour TOUT point p, sur TOUTE geometrie.          [QED]

Consequences immediates, aucune ne depend de la grotte :

  * `e >= min(d, 0,80)` force `e = d` exactement partout ou `d < 0,80`. La loi
    n'est donc pas un plancher : c'est le MAJORANT lui-meme. La marge maximale
    atteignable y vaut ZERO.
  * Avec la borne conservatrice, il faut `e - h >= d`, donc `e >= d + h`, ce que
    (1)+(2) interdisent. La loi est INSATISFIABLE sur `d < 0,80`, pour tout
    `h > 0`, sur toute geometrie, y compris une geometrie parfaite.
  * Le meme argument condamne tout seuil CONSTANT `S` en dessous de `d = S` :
    la collerette a 0,60 m est insatisfiable a moins de 0,60 m du rebord, et le
    seuil structurel a 0,80 m l'est a moins de 0,80 m. C'est exactement ce que
    R2a-3.5.5 a mesure sans le nommer : `lecture / h` constant a un facteur 8
    pres sur DEUX geometries independantes, signature d'une arete.
  * Le plus petit `d` ou un seuil constant `S` redevient atteignable avec la
    marge `h` est `d_c = S + h`. A `S = 0,80` et `h = 0,05`, `d_c = 0,85 m` —
    le meme 0,85 que la directive §4 exigeait deja comme borne garantie hors de
    la zone progressive. Le nombre n'est pas choisi, il tombe.

CE QUE CE FICHIER NE FAIT PAS
=============================

Il n'abaisse aucun seuil. `EPAISSEUR_MIN_M = 0,80` et
`EPAISSEUR_MIN_COLLERETTE_M = 0,60` restent inchanges, et restent exiges partout
ou ils sont atteignables. Il etablit ou ils ne le sont pas, et pourquoi aucune
sculpture ne pourra jamais les y rendre atteignables.

Il ne propose pas non plus « une bande exclue des controles » — la directive le
refuse, a juste titre. Il montre que dans cette bande la grandeur decidable
n'est pas une EPAISSEUR mais un ANGLE : l'angle de levre theta, sans dimension,
donc insensible a la resolution. `theta >= theta_min` equivaut localement a
`e >= sin(theta_min) . d`, et se mesure directement sur le maillage.

Usage :
    python3 tools/cave_borne_rebord.py --banc
    python3 tools/cave_borne_rebord.py --tables
"""

import math
import random
import sys

SEUIL_STRUCTUREL = 0.80
SEUIL_COLLERETTE = 0.60


def epaisseur_coin(d, theta_deg):
    """Epaisseur exacte au point situe a la distance `d` du rebord, sur la peau
    interieure d'un coin de matiere d'ouverture `theta`.

    Repere : le rebord est a l'origine, la peau interieure est le demi-axe des
    x positifs, la surface exterieure est le demi-axe a l'angle -theta. Le point
    mesure est p = (d, 0).

    Le pied de la perpendiculaire a la DROITE porteuse se trouve au parametre
    `d.cos(theta)`. Pour theta < 90 il tombe sur le demi-axe et la distance vaut
    `d.sin(theta)`. Pour theta >= 90 il tombe DERRIERE l'origine, donc hors du
    demi-axe : le point le plus proche est alors l'origine elle-meme, c'est-a-dire
    le rebord, et la distance vaut exactement `d`.

    Cette bascule est le piege que j'ai commis puis corrige dans ma table de
    pente : au-dela de 90 degres, ouvrir davantage le coin n'apporte plus rien,
    parce que c'est le REBORD qui devient le point le plus proche. C'est deja le
    theoreme, vu sur un cas particulier.
    """
    t = math.radians(theta_deg)
    return d * math.sin(t) if theta_deg < 90.0 else d


def distance_a_segment(p, a, b):
    """Distance d'un point a un segment. Sert au controle numerique du theoreme."""
    ax, ay, az = a
    bx, by, bz = b
    px, py, pz = p
    vx, vy, vz = bx - ax, by - ay, bz - az
    wx, wy, wz = px - ax, py - ay, pz - az
    dd = vx * vx + vy * vy + vz * vz
    t = 0.0 if dd == 0.0 else max(0.0, min(1.0, (wx * vx + wy * vy + wz * vz) / dd))
    cx, cy, cz = ax + t * vx, ay + t * vy, az + t * vz
    return math.sqrt((px - cx) ** 2 + (py - cy) ** 2 + (pz - cz) ** 2)


def banc():
    """Banc a reponse CONNUE. Sans lui, ce fichier est une opinion.

    Trois familles d'epreuves :
      1. la forme close du coin, contre une recherche numerique brutale du point
         le plus proche sur la surface exterieure ;
      2. la chaine du theoreme, sur des configurations tirees au hasard : le
         rebord est une polyligne quelconque, le point est place n'importe ou, et
         l'on verifie e <= dist(p, Gamma) <= d ;
      3. le controle NEGATIF : une levre franchement trop vive doit rougir. Un
         banc qui ne contient que des cas verts ne prouve rien.
    """
    ok = 0
    ko = 0

    def verifier(nom, obtenu, attendu, tol=1e-9):
        nonlocal ok, ko
        bon = abs(obtenu - attendu) <= tol
        print("  %-52s %12.9f  attendu %12.9f  %s"
              % (nom, obtenu, attendu, "OK" if bon else "ECHEC"))
        if bon:
            ok += 1
        else:
            ko += 1

    def affirmer(nom, condition, detail=""):
        nonlocal ok, ko
        print("  %-52s %s%s" % (nom, "OK" if condition else "ECHEC",
                                ("  " + detail) if detail else ""))
        if condition:
            ok += 1
        else:
            ko += 1

    print("=== 1. forme close du coin, contre recherche numerique ===")
    for theta in (15.0, 30.0, 36.0, 45.0, 60.0, 70.0, 89.0, 90.0, 100.0, 120.0):
        d = 0.37
        p = (d, 0.0, 0.0)
        # demi-axe exterieur, echantillonne finement puis raffine
        t = math.radians(theta)
        dirx, diry = math.cos(t), -math.sin(t)
        meilleur = float("inf")
        s = 0.0
        pas = 1.0
        while pas > 1e-12:
            base = s
            for k in range(-40, 41):
                cand = base + k * pas
                if cand < 0.0:
                    continue
                q = (cand * dirx, cand * diry, 0.0)
                dist = math.sqrt((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2)
                if dist < meilleur:
                    meilleur = dist
                    s = cand
            pas *= 0.1
        verifier("coin theta=%6.1f deg" % theta, epaisseur_coin(d, theta),
                 meilleur, tol=1e-7)

    print()
    print("=== 2. chaine du theoreme, 400 configurations tirees au hasard ===")
    alea = random.Random(20260817)
    pire_marge_1 = float("inf")
    pire_marge_2 = float("inf")
    stricts_1 = 0
    for _ in range(400):
        # rebord : polyligne quelconque de 6 sommets
        gamma = [(alea.uniform(-3, 3), alea.uniform(-3, 3), alea.uniform(-3, 3))
                 for _ in range(6)]
        p = (alea.uniform(-3, 3), alea.uniform(-3, 3), alea.uniform(-3, 3))
        d_gamma = min(distance_a_segment(p, gamma[i], gamma[i + 1])
                      for i in range(len(gamma) - 1))
        ## S_ext CONTIENT Gamma, et ne s'y reduit pas : on lui ajoute des
        ## facettes quelconques. Sans cet ajout, `e` vaudrait `d_gamma` par
        ## construction et la marge serait nulle a chaque tirage — un controle
        ## qui ne peut pas echouer, exactement ce que `PROMPT4_METHOD` §2
        ## interdit. Avec l'ajout, l'inegalite devient STRICTE la plupart du
        ## temps, et une erreur de minimum la ferait rougir.
        s_ext = list(zip(gamma[:-1], gamma[1:]))
        for _ in range(5):
            s_ext.append(((alea.uniform(-4, 4), alea.uniform(-4, 4),
                           alea.uniform(-4, 4)),
                          (alea.uniform(-4, 4), alea.uniform(-4, 4),
                           alea.uniform(-4, 4))))
        e = min(distance_a_segment(p, a, b) for a, b in s_ext)
        # la distance geodesique sur la peau majore l'euclidienne ; on prend un
        # chemin brise quelconque de p vers le point de Gamma le plus proche
        etapes = [p]
        for _ in range(3):
            etapes.append((alea.uniform(-3, 3), alea.uniform(-3, 3),
                           alea.uniform(-3, 3)))
        j = min(range(len(gamma)),
                key=lambda k: math.dist(p, gamma[k]))
        etapes.append(gamma[j])
        d_geo = sum(math.dist(etapes[i], etapes[i + 1])
                    for i in range(len(etapes) - 1))
        pire_marge_1 = min(pire_marge_1, d_gamma - e)
        pire_marge_2 = min(pire_marge_2, d_geo - d_gamma)
        if d_gamma - e > 1e-9:
            stricts_1 += 1
    affirmer("(1)  e <= dist(p, Gamma)", pire_marge_1 >= -1e-12,
             "pire marge %.3e, inegalite STRICTE %d/400 fois"
             % (pire_marge_1, stricts_1))
    affirmer("(2)  dist(p, Gamma) <= d_geodesique", pire_marge_2 >= -1e-12,
             "pire marge %.3e" % pire_marge_2)

    print()
    print("=== 3. controle NEGATIF : une levre vive doit rougir ===")
    # levre a 36 degres, a 0,50 m du rebord : l'epaisseur vaut 0,50.sin(36)
    e_vive = epaisseur_coin(0.50, 36.0)
    affirmer("levre 36 deg a d=0,50 : e < min(d, 0,80)",
             e_vive < min(0.50, SEUIL_STRUCTUREL) - 1e-9,
             "e = %.4f m  contre %.4f m exiges" % (e_vive, 0.50))
    # levre a angle droit, meme point : e = d exactement, donc PASS a l'egalite
    e_droite = epaisseur_coin(0.50, 90.0)
    affirmer("levre 90 deg a d=0,50 : e == min(d, 0,80) A L'EGALITE",
             abs(e_droite - 0.50) < 1e-12,
             "e = %.4f m, marge %.1e" % (e_droite, e_droite - 0.50))
    # et la borne conservatrice la fait basculer
    affirmer("levre 90 deg, borne conservatrice h=0,05 : ECHOUE",
             (e_droite - 0.05) < 0.50,
             "borne %.4f m < %.4f m exiges" % (e_droite - 0.05, 0.50))

    print()
    print("  banc : %d vert(s), %d rouge(s)" % (ok, ko))
    return 0 if ko == 0 else 1


def tables():
    """Les consequences chiffrees, pour le contrat."""
    print("=== A. deficit de la loi min(d, 0,80) selon l'angle de levre ===")
    print("    e(d) = d.sin(theta) si theta < 90, = d sinon.  Exige : e >= d.")
    print()
    print("    theta     e/d      marge relative     verdict a d = 0,50 m")
    for theta in (15.0, 30.0, 36.0, 45.0, 60.0, 70.0, 80.0, 90.0, 120.0, 179.0):
        r = epaisseur_coin(1.0, theta)
        etat = "PASS a l'egalite" if r >= 1.0 - 1e-12 else "FAIL"
        print("    %6.1f  %7.4f   %+9.4f          %s" % (theta, r, r - 1.0, etat))
    print()
    print("    Aucun angle ne rend une marge STRICTEMENT positive. Ouvrir la")
    print("    levre au-dela de 90 degres n'aide pas : le point le plus proche")
    print("    devient le rebord lui-meme, et la distance sature a d.")

    print()
    print("=== B. distance critique d_c = S + h : ou un seuil CONSTANT redevient")
    print("       atteignable avec la marge de mesure ===")
    print()
    print("        h (m)    S=0,60 collerette     S=0,80 structurel")
    for h in (0.20, 0.10, 0.05, 0.025, 0.010):
        print("      %7.3f    %14.3f      %16.3f"
              % (h, SEUIL_COLLERETTE + h, SEUIL_STRUCTUREL + h))
    print()
    print("    A h = 0,05 m : d_c = 0,85 m pour le seuil structurel. C'est")
    print("    exactement la borne garantie que la directive R2a-3.5.6 §4")
    print("    exigeait deja hors zone progressive. Le nombre n'a pas ete")
    print("    choisi pour tomber juste : il tombe.")

    print()
    print("=== C. largeur de la bande ou la BORNE CONSERVATRICE ne peut trancher,")
    print("       pour une loi de pente alpha < 1 ===")
    print("    condition : e - h >= alpha.d  avec e <= d  ==>  d >= h / (1 - alpha)")
    print()
    print("        alpha   theta_min     largeur a h=0,05   a h=0,01")
    for theta_min in (30.0, 36.0, 45.0, 60.0, 70.0):
        a = math.sin(math.radians(theta_min))
        print("      %7.4f  %7.1f deg   %14.3f m %10.3f m"
              % (a, theta_min, 0.05 / (1.0 - a), 0.01 / (1.0 - a)))
    print()
    print("    Aucun choix d'alpha < 1 ne ramene cette bande a zero. Une")
    print("    epaisseur ne peut donc pas etre le critere au voisinage immediat")
    print("    du rebord, quelle que soit la loi et quelle que soit la finesse.")
    print("    La grandeur qui reste decidable la est l'ANGLE de levre : sans")
    print("    dimension, il ne retrecit pas avec h.")
    return 0


if __name__ == "__main__":
    if "--banc" in sys.argv:
        sys.exit(banc())
    if "--tables" in sys.argv:
        sys.exit(tables())
    print(__doc__.strip().splitlines()[0])
    print()
    print("usage : cave_borne_rebord.py --banc")
    print("        cave_borne_rebord.py --tables")
    print()
    print("Aucun mode par defaut : un defaut par defaut est un chemin qui")
    print("pourrit en silence. Nommer ce qu'on mesure.")
    sys.exit(2)
