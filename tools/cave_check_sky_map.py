#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CARTE DES PERCEES — INSTRUMENT REFUTE. NE PAS CITER SON AIRE.

=============================================================================
STATUT : `REFUTE` comme mesure d'aire.          (2026-08-16, agent C)
Conserve UNIQUEMENT comme trace du resultat negatif qui l'a condamne.
=============================================================================

CE QUI EST REFUTE, ET COMMENT
=============================
Le critere « depuis `az = 1,50`, zero traversee en montant, avec de la roche
en dessous » ne mesure PAS une percee. Il compte toute colonne dont le
sommet du maillage se trouve sous 1,50 m — il confond donc TOIT ABSENT et
ENVELOPPE SIMPLEMENT PLUS BASSE.

Trois mesures le montrent, et je les conserve intactes :

  * dans la fenetre de reference (30 x 30 cm, 3 721 colonnes), la sonde rend
    920 colonnes / 230,00 cm2 — et la DECOMPOSITION EN AMAS montre qu'il y
    en a DEUX : un amas de 873 colonnes qui TOUCHE LE BORD de la fenetre,
    donc tronque, donc non mesure ; et un amas compact de 47 colonnes ;
  * en elargissant a 1,2 x 1,2 m, l'amas compact reste EXACTEMENT a
    47 colonnes / 11,75 cm2, x[0,591 0,626] ay[5,853 5,908], identique a
    `az` = 1,25 et 1,50 ; l'autre passe de 2 767 a 8 286 colonnes et touche
    toujours le bord ;
  * la sensibilite en altitude va de 11,75 cm2 (az <= 1,25) a 730 cm2
    (az = 2,00) dans la meme fenetre.

Une aire qui croit avec la fenetre n'est pas une aire : c'est la fenetre.

CE QUI RESTE VRAI ET UTILE
==========================
  * la DECOMPOSITION EN AMAS et le marquage « TOUCHE LE BORD, TRONQUE » —
    c'est ce qui a permis de voir le defaut. A conserver dans tout outil de
    carte : publier toujours si une emprise touche un bord de fenetre ;
  * l'amas compact et stable de 47 colonnes est, lui, un vrai objet : il ne
    bouge pas quand la fenetre grandit ni quand l'altitude change ;
  * le DIFF DE CARTE (fermees / persistantes / NOUVELLES) reste la bonne
    forme pour distinguer une fermeture d'une migration — c'est le CRITERE
    qui etait faux, pas la comparaison de cartes.

OU EST PASSEE LA QUESTION
=========================
« L'interieur communique-t-il avec le dehors » se tranche desormais dans
`tools/cave_check_hull.py`, par coupure du graphe dual : sans grille, sans
altitude, sans fenetre, et sans resolution — il verrait une communication de
n'importe quelle largeur. C'est la formulation « par chemin » : depuis l'air
canonique, existe-t-il un chemin vers le dehors qui n'emprunte pas la bouche
masquee ?

-----------------------------------------------------------------------------
Documentation d'origine conservee ci-dessous.
-----------------------------------------------------------------------------

LA QUESTION QUE LES TOTAUX NE POSENT PAS
========================================
« 343 colonnes ouvertes avant, 0 apres » ne dit pas si le trou a ete bouche
ou s'il s'est deplace de 40 cm. Un total qui redescend et un total qui se
deplace ont exactement la meme allure. Il faut comparer des CARTES, pas des
nombres :

    fermee     : ouverte avant, fermee apres      -> reparation
    persistante: ouverte des deux cotes           -> non reparee
    NOUVELLE   : fermee avant, ouverte apres      -> MIGRATION, l'alarme

LE CRITERE DE PERCEE, ET POURQUOI PAS CELUI DE LA SONDE DE REFERENCE
====================================================================
La sonde de R2a-3.5.3 sonde une altitude FIXE (`az = 1,50`) dans une fenetre
de 30 x 30 cm autour du defaut connu. C'est juste LA-BAS, et inutilisable
partout ailleurs : sur un flanc de colline il y a de la roche dessous et
rien dessus, donc « perce » — un faux positif a chaque metre carre de
terrain.

Le critere employe ici ne fixe aucune altitude et ne connait aucune station.
Pour chaque colonne on empile les intervalles, et on distingue :

    POCHE   : un intervalle d'air BORNE des deux cotes -> une cavite
    PERCEE  : pas de poche ici, alors qu'une colonne VOISINE en a une, et
              l'altitude de cette poche voisine tombe ici dans l'intervalle
              d'air qui monte jusqu'au ciel, avec de la roche en dessous

Autrement dit : la cavite existe autour, et ici son plafond a disparu. Sur
une colline il n'y a de poche nulle part, donc aucune percee — le confondant
s'evapore de lui-meme au lieu d'etre exclu a la main.

LE PIEGE DE PARITE, paye trois fois par quelqu'un d'autre
=========================================================
`tools/CLAUDE.md` : « cette lecture s'ecrit UNE fois, dans une fonction
nommee, et se reutilise — pas une fois par branche, ou on la redderive et ou
on se trompe ». C'est `empiler()`, et rien d'autre ne lit la parite.

Un nombre IMPAIR de croisements est geometriquement impossible sur un
maillage ferme : la colonne rase une arete ou un sommet. On ne devine pas,
on la compte a part et on la publie.

USAGE
=====
  python3 tools/cave_check_sky_map.py <a.glb> [<b.glb>] [options]
     --pas=0.05           pas de la grille
     --fenetre=x0,x1,y0,y1   restreindre (defaut : tout le modele)
     --autour-du-defaut   fenetre elargie 1,2 m autour du trou R2a-3.5.3
"""

import hashlib
import math
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cave_check_mesh as M  # noqa: E402

# Le defaut etabli en R2a-3.5.3, repere modele. Sert de CENTRE de fenetre,
# jamais de domaine de verdict.
DEFAUT_X = (0.468, 0.623)
DEFAUT_AY = (5.850, 6.045)


def empreinte(chemin):
    h = hashlib.sha256()
    with open(chemin, "rb") as f:
        for bloc in iter(lambda: f.read(1 << 20), b""):
            h.update(bloc)
    return h.hexdigest()


class ColonneVerticale:
    """Croisements d'une verticale avec le maillage, par seaux 2D."""

    def __init__(self, positions, faces, cellule=0.5):
        self.pos = positions
        self.faces = faces
        self.c = cellule
        self.seaux = defaultdict(list)
        for fi, (a, b, c) in enumerate(faces):
            pa, pb, pc = positions[a], positions[b], positions[c]
            x0 = min(pa[0], pb[0], pc[0]); x1 = max(pa[0], pb[0], pc[0])
            y0 = min(pa[1], pb[1], pc[1]); y1 = max(pa[1], pb[1], pc[1])
            for i in range(int(math.floor(x0 / cellule)),
                           int(math.floor(x1 / cellule)) + 1):
                for j in range(int(math.floor(y0 / cellule)),
                               int(math.floor(y1 / cellule)) + 1):
                    self.seaux[(i, j)].append(fi)

    def croisements(self, x, y):
        """Altitudes ou la verticale (x, y) traverse la surface, triees."""
        cle = (int(math.floor(x / self.c)), int(math.floor(y / self.c)))
        zs = []
        for fi in self.seaux.get(cle, ()):
            a, b, c = self.faces[fi]
            pa, pb, pc = self.pos[a], self.pos[b], self.pos[c]
            d = ((pb[1] - pc[1]) * (pa[0] - pc[0])
                 + (pc[0] - pb[0]) * (pa[1] - pc[1]))
            if d == 0.0:
                continue
            l1 = ((pb[1] - pc[1]) * (x - pc[0])
                  + (pc[0] - pb[0]) * (y - pc[1])) / d
            l2 = ((pc[1] - pa[1]) * (x - pc[0])
                  + (pa[0] - pc[0]) * (y - pc[1])) / d
            l3 = 1.0 - l1 - l2
            if l1 < 0.0 or l2 < 0.0 or l3 < 0.0:
                continue
            zs.append(l1 * pa[2] + l2 * pb[2] + l3 * pc[2])
        zs.sort()
        return zs


def empiler(zs):
    """LA lecture de parite — ecrite ICI, une fois, et nulle part ailleurs.

    Sous le plus bas croisement on est DEHORS (air). Chaque croisement bascule
    l'etat. Sur un maillage ferme le nombre de croisements est donc PAIR ;
    un compte impair signale une verticale qui rase une arete ou un sommet,
    et on refuse de l'interpreter.

    Rend (air, roche, poches, impair) ou `poches` sont les intervalles d'air
    BORNES DES DEUX COTES — les cavites.
    """
    if len(zs) % 2 == 1:
        return [], [], [], True
    air, roche = [], []
    if not zs:
        return [(float("-inf"), float("inf"))], [], [], False
    air.append((float("-inf"), zs[0]))
    for k in range(0, len(zs) - 1, 2):
        roche.append((zs[k], zs[k + 1]))
        if k + 2 < len(zs):
            air.append((zs[k + 1], zs[k + 2]))
    air.append((zs[-1], float("inf")))
    poches = [i for i in air
              if i[0] != float("-inf") and i[1] != float("inf")]
    return air, roche, poches, False


def carte(chemin, pas, fenetre):
    sommets, triangles = M.charger(chemin, "SM_WaterfallCave", repere="modele")
    positions, faces, _st = M.souder(sommets, triangles)
    col = ColonneVerticale(positions, faces)
    (x0, x1, y0, y1) = fenetre

    donnees = {}
    impairs = 0
    nx = int(round((x1 - x0) / pas)) + 1
    ny = int(round((y1 - y0) / pas)) + 1
    for i in range(nx):
        x = x0 + i * pas
        for j in range(ny):
            y = y0 + j * pas
            zs = col.croisements(x, y)
            air, roche, poches, impair = empiler(zs)
            if impair:
                impairs += 1
                continue
            donnees[(i, j)] = {"zs": zs, "air": air, "poches": poches}
    return {"positions": positions, "faces": faces, "grille": donnees,
            "nx": nx, "ny": ny, "pas": pas, "x0": x0, "y0": y0,
            "impairs": impairs, "sha256": empreinte(chemin), "chemin": chemin}


def cavite_et_percees(c, graine, germes=None):
    """Inonde la CAVITE dans le graphe des intervalles, puis lit ou elle
    debouche sur le ciel.

    POURQUOI CETTE FORME, APRES DEUX FAUSSES PISTES MESUREES
    ========================================================
    1. « pas de poche ici, une poche a 3 cellules » : au pas de 5 mm cela
       fait 1,5 cm, et le CENTRE du trou, a 5 cm de la premiere poche, etait
       declare sain. Mesure : 11,75 cm2, le trou vu par sa seule couronne.
    2. la meme chose avec propagation a 30 cm : 164,25 cm2, et l'emprise
       touchait les DEUX bords de la fenetre — signe qu'on debordait. Le
       flanc de colline au-dela de la grotte satisfait « roche dessous, air
       dessus » des que le terrain descend sous l'altitude de la galerie.
       C'est le confondant, et il est structurel.

    La seule question juste est celle que posait la sonde de reference :
    L'AIR OU LE JOUEUR SE TIENT COMMUNIQUE-T-IL AVEC LE CIEL ? On la pose
    donc directement. Les intervalles d'air de deux colonnes voisines sont
    relies s'ils se recouvrent en `az` ; on inonde depuis l'intervalle qui
    contient `MODELE_SALLE` ; une colonne est PERCEE si l'inondation atteint
    chez elle l'intervalle qui monte jusqu'au ciel.

    Aucune altitude fixee, aucune station, aucun rayon. L'intervalle
    inferieur (sous le massif) est exclu du graphe : il n'est pas la cavite.
    """
    g = c["grille"]
    pas = c["pas"]
    # noeuds : (colonne, index d'intervalle d'air), hors intervalle inferieur
    voisins = {}
    for k, v in g.items():
        for idx in range(1, len(v["air"])):
            voisins[(k, idx)] = v["air"][idx]

    def relie(k):
        i, j = k
        return ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1))

    depart = set()
    if germes:
        for (k, zlo, zhi) in germes:
            v = g.get(k)
            if not v:
                continue
            for idx in range(1, len(v["air"])):
                a, b = v["air"][idx]
                if min(b, zhi) > max(a, zlo):
                    depart.add((k, idx))
    else:
        gk = (int(round((graine[0] - c["x0"]) / pas)),
              int(round((graine[1] - c["y0"]) / pas)))
        v = g.get(gk)
        if not v:
            return None, None, "graine hors fenetre"
        for idx in range(1, len(v["air"])):
            a, b = v["air"][idx]
            if a <= graine[2] <= b:
                depart.add((gk, idx))
        if not depart:
            return None, None, ("graine dans la ROCHE a la colonne %s "
                                "— on ne devine pas la galerie" % (gk,))

    vus = set(depart)
    pile = list(depart)
    while pile:
        (k, idx) = pile.pop()
        a, b = g[k]["air"][idx]
        for vk in relie(k):
            v2 = g.get(vk)
            if not v2:
                continue
            for idx2 in range(1, len(v2["air"])):
                if (vk, idx2) in vus:
                    continue
                a2, b2 = v2["air"][idx2]
                if min(b, b2) > max(a, a2):
                    vus.add((vk, idx2))
                    pile.append((vk, idx2))

    perc = {}
    cav = {}
    for (k, idx) in vus:
        a, b = g[k]["air"][idx]
        cav.setdefault(k, []).append((a, b))
        if b == float("inf"):
            perc[k] = a
    return cav, perc, None


def percees_sonde(c, az):
    """LA sonde : depuis l'altitude `az`, y a-t-il de la roche AU-DESSUS ?

    C'EST LA FORMULATION DE REFERENCE, ET C'EST DELIBERE. J'ai essaye trois
    criteres « a moi » avant de revenir a celui-la, et les trois ont echoue
    de facon mesurable :

      1. poche voisine a 3 cellules  -> 11,75 cm2 : le CENTRE du trou manque ;
      2. propagation a 0,30 m        -> 164,25 cm2 et l'emprise touche les
         deux bords de la fenetre — le flanc de colline entre ;
      3. inondation d'intervalles depuis la salle -> 80 427 colonnes sur
         80 427 : l'air de la galerie communique avec le ciel PAR LA BOUCHE,
         ce qui est le fonctionnement normal d'une grotte. Sans sceller la
         bouche, l'inondation ne peut rien dire — et la sceller est le
         travail de `cave_check_hull.py`, pas d'une carte de colonnes.

    La sensibilite au rayon publiee par le critere 2 croissait de 11,75 a
    164,25 cm2 sans jamais se stabiliser : ce n'est pas une mesure, c'est un
    reglage. On garde donc la sonde locale, dont la comparabilite avec la
    mesure publiee est en soi une vertu pour une TELEMETRIE.

    Parite : le nombre de croisements SOUS la sonde doit etre PAIR, sinon la
    sonde est DANS la roche et la colonne ne prouve rien (`tools/CLAUDE.md`,
    trois verdicts faux avant un juste). Zero croisement au-dessus ET de la
    roche en dessous : la colonne voit le ciel.
    """
    sortie = {}
    for k, v in c["grille"].items():
        zs = v["zs"]
        dessous = sum(1 for z in zs if z < az)
        dessus = len(zs) - dessous
        if dessus == 0 and dessous > 0 and dessous % 2 == 0:
            sortie[k] = az
    return sortie


def percees(c, rayon_m):
    """Colonnes ou une cavite voisine a perdu son plafond.

    Aucune altitude fixee, aucune station : la cavite se declare elle-meme
    par la presence de poches autour.

    PROPAGATION, ET POURQUOI PAS UN VOISINAGE DIRECT. Un premier jet
    cherchait une colonne a poche dans un carre de 3 cellules. Au pas de
    5 mm cela fait 1,5 cm : les colonnes du CENTRE du trou, a 5 cm de la
    premiere poche, n'en trouvaient aucune et etaient declarees saines.
    Resultat mesure : 11,75 cm2 la ou il y en a bien davantage — le trou vu
    par sa seule couronne. On propage donc l'altitude de poche par un
    parcours en largeur multi-source, ce qui donne a chaque colonne celle de
    la poche la plus proche, en O(N) et sans rayon en cellules.
    """
    g = c["grille"]
    pas = c["pas"]
    portee = int(math.ceil(rayon_m / pas))
    from collections import deque
    dist = {}
    alt = {}
    file = deque()
    for k, v in g.items():
        if v["poches"]:
            dist[k] = 0
            alt[k] = max(0.5 * (b + h) for (b, h) in v["poches"])
            file.append(k)
    while file:
        k = file.popleft()
        if dist[k] >= portee:
            continue
        i, j = k
        for vk in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)):
            if vk in g and vk not in dist:
                dist[vk] = dist[k] + 1
                alt[vk] = alt[k]
                file.append(vk)

    sortie = {}
    for k, v in g.items():
        if v["poches"] or not v["zs"] or k not in alt:
            continue
        a = alt[k]
        haut = v["air"][-1]           # intervalle d'air qui monte au ciel
        # l'altitude de la cavite voisine tombe-t-elle ici dans l'air ouvert
        # sur le ciel, avec de la roche EN DESSOUS ? La roche en dessous
        # ecarte le confondant « ce point est deja au-dessus du massif ».
        if haut[0] < a < haut[1] and any(z < a for z in v["zs"]):
            sortie[k] = a
    return sortie


def diff(ca, pa, cb, pb, nom_a, nom_b):
    fermees = sorted(set(pa) - set(pb))
    nouvelles = sorted(set(pb) - set(pa))
    persistantes = sorted(set(pa) & set(pb))
    aire = ca["pas"] ** 2

    def gp(c, k):
        return (c["x0"] + k[0] * c["pas"], c["y0"] + k[1] * c["pas"])

    print("-" * 74)
    print("DIFF DE CARTE  %s  ->  %s" % (nom_a, nom_b))
    print("-" * 74)
    print("  fermees      : %5d colonnes  (%8.2f cm2)  reparation"
          % (len(fermees), len(fermees) * aire * 1e4))
    print("  persistantes : %5d colonnes  (%8.2f cm2)  NON reparees"
          % (len(persistantes), len(persistantes) * aire * 1e4))
    print("  NOUVELLES    : %5d colonnes  (%8.2f cm2)  <== MIGRATION"
          % (len(nouvelles), len(nouvelles) * aire * 1e4))
    if nouvelles:
        pts = [gp(cb, k) for k in nouvelles]
        cx = sum(p[0] for p in pts) / len(pts)
        cy = sum(p[1] for p in pts) / len(pts)
        print("    centre des nouvelles : modele (%.4f ; %.4f)" % (cx, cy))
        if fermees:
            pa_ = [gp(ca, k) for k in fermees]
            ax = sum(p[0] for p in pa_) / len(pa_)
            ay = sum(p[1] for p in pa_) / len(pa_)
            print("    centre des fermees   : modele (%.4f ; %.4f)" % (ax, ay))
            print("    DEPLACEMENT          : %.4f m"
                  % math.dist((cx, cy), (ax, ay)))
        print("    emprise : x[%.4f %.4f] ay[%.4f %.4f]"
              % (min(p[0] for p in pts), max(p[0] for p in pts),
                 min(p[1] for p in pts), max(p[1] for p in pts)))
        print()
        print("    LECTURE : un defaut qui se ferme ici et s'ouvre la n'est pas")
        print("    repare. Le total seul aurait montre la meme chose qu'une")
        print("    vraie fermeture.")
    else:
        print("    aucune colonne nouvellement ouverte dans cette fenetre.")
    print()


def amas(c, p):
    """Amas connexes de colonnes ouvertes, du plus grand au plus petit.

    Un total ne distingue pas UN trou de DIX. Et surtout : un amas qui
    TOUCHE LE BORD DE LA FENETRE n'est pas mesure, il est tronque — sa
    surface ne veut rien dire, et le lire comme une aire de percee est une
    faute. On le marque.
    """
    reste = set(p)
    sortie = []
    imax, jmax = c["nx"] - 1, c["ny"] - 1
    while reste:
        d = reste.pop()
        bloc = [d]
        pile = [d]
        while pile:
            (i, j) = pile.pop()
            for vk in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)):
                if vk in reste:
                    reste.discard(vk)
                    bloc.append(vk)
                    pile.append(vk)
        xs = [c["x0"] + k[0] * c["pas"] for k in bloc]
        ys = [c["y0"] + k[1] * c["pas"] for k in bloc]
        borde = any(k[0] in (0, imax) or k[1] in (0, jmax) for k in bloc)
        sortie.append({"n": len(bloc), "x": (min(xs), max(xs)),
                       "y": (min(ys), max(ys)), "borde": borde})
    sortie.sort(key=lambda a: -a["n"])
    return sortie


def resume(c, p, nom):
    aire = c["pas"] ** 2
    print("  %-26s %6d colonnes ouvertes / %d   %9.2f cm2   impairs %d"
          % (nom, len(p), len(c["grille"]), len(p) * aire * 1e4, c["impairs"]))
    if p:
        xs = [c["x0"] + k[0] * c["pas"] for k in p]
        ys = [c["y0"] + k[1] * c["pas"] for k in p]
        print("     %-23s emprise x[%.4f %.4f] ay[%.4f %.4f]"
              % ("", min(xs), max(xs), min(ys), max(ys)))


SALLE = (2.62, 2.58, 0.09)
SALLE_ANCIEN = (1.05, 6.25, 0.22)


def graine_effective(c, marqueur):
    """Intervalle d'air contenant le marqueur, ou le premier au-dessus.

    Le marqueur de gameplay est pose AU SOL : il peut tomber dans la peau du
    plancher. On releve alors jusqu'au premier air, et ON PUBLIE le relevage
    — c'est une telemetrie, pas un gate ; le refus dur appartient a
    `cave_check_hull.py` §2.3.
    """
    pas = c["pas"]
    gk = (int(round((marqueur[0] - c["x0"]) / pas)),
          int(round((marqueur[1] - c["y0"]) / pas)))
    v = c["grille"].get(gk)
    if not v:
        return None, "colonne de la graine hors fenetre"
    for idx in range(1, len(v["air"])):
        a, b = v["air"][idx]
        if a <= marqueur[2] <= b:
            return (marqueur[0], marqueur[1], marqueur[2]), None
    for idx in range(1, len(v["air"])):
        a, b = v["air"][idx]
        if a > marqueur[2]:
            z = min(a + 0.05, 0.5 * (a + b))
            return (marqueur[0], marqueur[1], z), \
                "graine RELEVEE de %.3f m (marqueur dans la roche du sol)" \
                % (z - marqueur[2])
    return None, "aucun air au-dessus du marqueur"


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    if not args:
        print(__doc__)
        return 3
    pas = 0.05
    grossier = 0.05
    for a in argv:
        if a.startswith("--pas="):
            pas = float(a.split("=", 1)[1])
        if a.startswith("--pas-grossier="):
            grossier = float(a.split("=", 1)[1])
    marqueur = SALLE_ANCIEN if "--anciens-reperes" in argv else SALLE

    fen = None
    for a in argv:
        if a.startswith("--fenetre="):
            fen = tuple(float(v) for v in a.split("=", 1)[1].split(","))
    if "--autour-du-defaut" in argv:
        cx = 0.5 * (DEFAUT_X[0] + DEFAUT_X[1])
        cy = 0.5 * (DEFAUT_AY[0] + DEFAUT_AY[1])
        fen = (cx - 0.60, cx + 0.60, cy - 0.60, cy + 0.60)

    print("=" * 74)
    print("CARTE DES PERCEES — telemetrie de non-regression (contrat §4)")
    print("=" * 74)
    print("critere : l'air ou se tient le joueur communique-t-il avec le ciel ?")
    print("graine  : %s modele (%.3f ; %.3f ; %.3f)"
          % ("ANCIENS reperes" if "--anciens-reperes" in argv else "COURANTS",
             marqueur[0], marqueur[1], marqueur[2]))
    print()

    cartes = []
    for chemin in args:
        print("-" * 74)
        print("fichier : %s" % chemin)
        print("sha256  : %s   <- lu AVANT la mesure" % empreinte(chemin))
        s, t = M.charger(chemin, "SM_WaterfallCave", repere="modele")
        pos, _fc, _ = M.souder(s, t)
        (bx0, by0, _z0), (bx1, by1, _z1) = M.boite(pos)
        plein = (bx0, bx1, by0, by1)

        print("passe GROSSIERE  pas %.3f m  x[%.3f %.3f] ay[%.3f %.3f]"
              % (grossier, plein[0], plein[1], plein[2], plein[3]))
        cg = carte(chemin, grossier, plein)
        gr, note = graine_effective(cg, marqueur)
        if note:
            print("  %s" % note)
        if gr is None:
            print("  ABANDON : %s" % note)
            return 3
        cav_g, perc_g, err = cavite_et_percees(cg, gr)
        if err:
            print("  ABANDON : %s" % err)
            return 3
        print("  cavite : %d colonnes | percees : %d colonnes (%.2f cm2)"
              % (len(cav_g), len(perc_g), len(perc_g) * grossier ** 2 * 1e4))
        print("  colonnes a croisements IMPAIRS (verticale rasante) : %d"
              % cg["impairs"])

        cf = carte(chemin, pas, fen if fen is not None else plein)
        print("passe FINE       pas %.3f m  x[%.3f %.3f] ay[%.3f %.3f]"
              % (pas, cf["x0"], cf["x0"] + (cf["nx"] - 1) * pas,
                 cf["y0"], cf["y0"] + (cf["ny"] - 1) * pas))
        print("  impairs : %d" % cf["impairs"])
        print()
        print("  SENSIBILITE A L'ALTITUDE DE SONDE — on ne choisit pas, on")
        print("  publie. Une emprise STABLE sur plusieurs altitudes est le")
        print("  signe d'une percee verticale franche ; une emprise qui")
        print("  derive avec l'altitude serait un artefact de sondage.")
        print("  %-9s %-9s %-11s %s" % ("az sonde", "colonnes", "aire cm2",
                                        "emprise x / ay"))
        choisi = None
        for az in (1.00, 1.25, 1.50, 1.75, 2.00):
            p = percees_sonde(cf, az)
            if p:
                xs = [cf["x0"] + k[0] * pas for k in p]
                ys = [cf["y0"] + k[1] * pas for k in p]
                emp = "x[%.3f %.3f] ay[%.3f %.3f]" % (min(xs), max(xs),
                                                      min(ys), max(ys))
            else:
                emp = "-"
            print("  %-9.2f %-9d %-11.2f %s"
                  % (az, len(p), len(p) * pas ** 2 * 1e4, emp))
            if abs(az - 1.50) < 1e-9:
                choisi = p
        print("  -> retenu pour le diff : az = 1,50 m (celle de la reference)")
        print()
        print("  DECOMPOSITION EN AMAS — un total ne distingue pas un trou")
        print("  de dix, et un amas qui touche le bord de la fenetre est")
        print("  TRONQUE : son aire ne mesure rien.")
        for az in (1.25, 1.50):
            p = percees_sonde(cf, az)
            blocs = amas(cf, p)
            print("   az=%.2f : %d amas" % (az, len(blocs)))
            for a in blocs[:5]:
                print("     %6d col. %8.2f cm2  x[%.3f %.3f] ay[%.3f %.3f] %s"
                      % (a["n"], a["n"] * pas ** 2 * 1e4, a["x"][0], a["x"][1],
                         a["y"][0], a["y"][1],
                         "<== TOUCHE LE BORD, TRONQUE" if a["borde"] else ""))
            if len(blocs) > 5:
                print("     ... et %d amas plus petits" % (len(blocs) - 5))
        print()
        cartes.append((cf, choisi, os.path.basename(chemin)))

    print("-" * 74)
    print("RESUME")
    print("-" * 74)
    for (c, p, nom) in cartes:
        resume(c, p, nom)
    print()

    for i in range(len(cartes) - 1):
        (ca, pa, na) = cartes[i]
        (cb, pb, nb) = cartes[i + 1]
        diff(ca, pa, cb, pb, na, nb)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
