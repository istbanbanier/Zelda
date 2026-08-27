#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""SECOND ORACLE — etancheite par classement de l'espace, sans aucune station.

=============================================================================
STATUT : `NON VALIDE`. NE PAS CITER SON VERDICT.        (2026-08-16)
=============================================================================

Cet oracle rend `ETANCHE` sur `cc3596c5`. **Ce verdict ne prouve rien** et
ne doit etre repris nulle part, parce que CINQ de ses six controles
negatifs ne rougissent pas : on perce, de la graine interieure jusqu'au
dehors, un tunnel dont la largeur libre MESUREE vaut 0,35 a 0,65 m de rayon
— trois a six cases — et l'oracle continue de repondre `ETANCHE`.

Un oracle dont les controles negatifs ne mordent pas est exactement ce qui
a fait condamner `cave_voxel_oracle.py` : un acquittement par aveuglement.
Il est donc livre comme INSTRUMENT DE DIAGNOSTIC, pas comme portail, et la
Phase I reste sans second oracle operationnel.

LA CAUSE, ET ELLE EST DE FOND — pas un reglage
==============================================

Percer en RETIRANT DES TRIANGLES produit un maillage OUVERT. Or la parite
ne definit un « dedans » que sur un maillage CLOS ; sur un maillage ouvert,
deux axes donnent deux reponses, toutes deux correctes pour leur rayon.

Apres avoir perce une cheminee verticale :

  * le long de +Z, le rayon traverse la cheminee sans rien rencontrer :
    parite paire, la case est de l'AIR ;
  * le long de +X et de +Y, le rayon ne passe pas par la cheminee, entre
    dans le massif et en ressort : la case est de la ROCHE.

Le vote a la majorite tranche 2 contre 1 en faveur de la roche et REBOUCHE
le trou qu'on vient de percer. Le vote — introduit pour corriger un vrai
defaut, les 26 colonnes de parite impaire — devient ici la cause de la
cecite. C'est le meme couteau des deux cotes.

CE QU'IL FAUDRAIT POUR LE VALIDER, et ce n'est pas un ajustement : un
sabotage qui laisse le maillage CLOS — creuser un vrai conduit avec sa
paroi, ou retirer une portion d'enveloppe assez large pour que les trois
axes traversent l'ouverture. Tant que ce sabotage n'existe pas, aucune
lecture de cet oracle n'est probante.

CE QU'IL A REELLEMENT ETABLI, et qui vaut d'etre garde :

  * la TRACE DU CHEMIN de fuite, qui localise une communication au voxel
    pres ;
  * la mesure du toit a **0,054 m** vers `(x 0,58 ; y 5,80)`, hors de la
    cavite declaree — c'est elle qui a fait corriger les domaines de
    `tools/cave_frame.py` et `tools/probe_cave_openings.py` ;
  * les 26 colonnes de parite impaire sur 33 950, qui sont un fait sur le
    MAILLAGE et non sur l'instrument.

POURQUOI CELUI-CI REMPLACE `cave_voxel_oracle.py`
=================================================

L'oracle precedent sort en RC 3 depuis qu'il existe. Sa cause est lisible
dans son propre code : il pose son bouchon sur **l'OUVERTURE 2D** de la
tranche `y = Y_BOUCHE`, c'est-a-dire sur les cases creuses de cette tranche
qui ne touchent pas le bord du plan.

Or a `y = -1,15` cette ouverture n'est PAS close lateralement. Ce n'est pas
une supposition : `tools/cave_collar.py` doit reculer a `y = -0,95` sur
l'avant pour exactement cette raison, et son commentaire le dit — « le plan
de bouche lui-meme est ouvert lateralement ». Le porche est evase et son sol
plonge sous le terrain. Un bouchon defini comme « le creux clos de la
tranche » y est donc structurellement incomplet, et l'inondation contourne
par-dessous.

Sa toute premiere version rendait « 0 fuite » en confinant l'inondation a
une tranche de facade : un acquittement par aveuglement, le pire mode
d'echec possible pour un oracle. Il ne pouvait donc etre ni cite, ni retire
sans remplacement.

CE QUE CET ORACLE FAIT DIFFEREMMENT
===================================

  * LE BOUCHON EST UNE TRANCHE PLEINE centree sur `Y_BOUCHE`, sur toute
    l'etendue x et z de la grille. Pas une ouverture devinee. Par
    construction elle couvre TOUTE l'ouverture evasee, y compris sa partie
    sous le terrain — ce qui faisait fuir l'autre.

  * SON EPAISSEUR N'EST PAS CHOISIE, ELLE EST MESUREE. Ma premiere version
    bouchait UNE case, et le candidat intact sortait en FUITE. Ce n'etait ni
    un trou ni un defaut d'inondation : LA BOUCHE N'EST PAS PLANE. Le bord
    du porche evase court sur une plage de `y`, un plan ne coupe donc pas
    l'entonnoir, et l'air passe par-dessus le plan sans jamais le traverser.
    C'est la meme cause, plus profonde, que le RC 3 de l'ancien oracle :
    ce n'est pas que son ouverture 2D etait incomplete, c'est qu'AUCUN
    bouchon plan ne peut couper cette bouche. L'epaisseur utile se lit
    desormais dans un balayage publie.

  * L'INONDATION EXTERIEURE EST GLOBALE : elle part de TOUTES les cases du
    bord de grille, jamais d'une tranche de facade.

  * LE VERDICT EST UNE DISJONCTION DE COMPOSANTES : la composante de la
    graine interieure ne doit pas contenir de case de bord. On ne compte
    rien, on ne seuille rien.

RESOLUTION — CE QUE CET ORACLE NE PEUT PAS VOIR
===============================================

Il travaille sur une grille de pas `--pas`. Deux limites en decoulent, et
elles vont dans des sens opposes :

  * une FEUILLE DE ROCHE plus mince que le pas est conservee, parce qu'une
    case traversee par la peau est classee roche. Sans cette regle, le
    candidat intact sortait en FUITE par une cheminee imaginaire : le toit
    du vide mesure 0,023 m au (x 0,58 ; y 5,82) et disparaissait entre deux
    centres de case ;
  * en contrepartie, un TROU plus etroit que le pas est invisible. Et ce
    n'est pas theorique : le premier jeu de controles negatifs percait des
    tunnels de 0,40 m de RAYON DE BARYCENTRE, et CINQ sur six sortaient
    ETANCHE. Le sabotage retirait bien 10 a 81 triangles, mais les voisins
    gardes couvraient encore l'ouverture et la refermaient au niveau de la
    grille. Chaque controle MESURE donc desormais la largeur qu'il ouvre
    reellement (`largeur_libre`) et se declare BLOQUE plutot que rate s'il
    n'ouvre pas deux cases.

Enonce honnete : **cet oracle detecte les communications plus larges que
`pas`.** Pour en voir de plus fines, reduire le pas et refaire tourner les
controles negatifs — pas croire qu'il les voyait deja.

ANGLE MORT, MESURE ET PUBLIE
============================

Un bouchon-tranche masque tout trou entierement contenu dans la tranche.
C'est le prix du choix conservateur, il est borne, et il vaut EXACTEMENT
l'epaisseur retenue par le balayage — donc il grandit avec elle.

Sur `cc3596c5` au pas 0,10 m, le balayage retient UNE case : l'angle mort
se confond alors avec la limite de resolution deja enoncee, et il n'y a
rien de plus a demontrer. Le controle correspondant le DIT au lieu de
fabriquer une epreuve degeneree — une epreuve qui ne peut pas echouer n'est
pas une epreuve. Si un jour le balayage retient une tranche plus epaisse,
le controle redevient necessaire et se rejoue.

CE QU'IL NE PARTAGE PAS, ET C'EST LA MOITIE DE SON INTERET
==========================================================

Aucun helper de placement de `probe_cave_openings.py` : ni
`points_interieurs`, ni `offsets_lateraux`, ni `dans_enveloppe`, ni
`dans_le_noyau`, ni `_emprise_noyau`, ni `sort_par_la_bouche`, ni
`Profil.normale`, ni `Profil.demi_largeur`, ni `Profil.sol`. Il n'a besoin
d'aucune de ces notions : il ne place pas de points, il classe l'espace.

Quatorze occurrences du MEME defaut de placement ont deja ete trouvees dans
cette famille de code. Un second oracle qui reutiliserait la fonction de
placement du premier serait aveugle avec lui, dans le meme sens, avec des
chiffres qui se confirment mutuellement.

Ce qu'il partage, et qui est nomme plutot que tu : le lecteur de GLB et
l'intersection rayon-triangle (`P.triangles_du_glb`, `P.Grille`,
`P.impacts`). Si l'intersection etait fausse, les deux methodes seraient
fausses ensemble ; c'est pourquoi cette brique-la est eprouvee separement
par `tools/probe_cave_selftest.py`, et non par elle-meme.

Usage :
    python3 tools/cave_seal_oracle.py [glb] [--pas 0.10] [--sabotages]
                                      [--classer x,y,z] [--json f.json]

Codes de sortie : 0 = etanche · 1 = fuite ou controle negatif rate ·
3 = BLOQUE.
"""

import argparse
import json
import math
import os
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import probe_cave_openings as P                                # noqa: E402

## Plan de la bouche, en y modele. C'est la SEULE cote empruntee au profil
## declare, et elle ne sert qu'a savoir par ou l'on a le droit d'entrer.
Y_BOUCHE = -1.15

## Repere de gameplay servant de graine interieure. Lu dans le script de
## lieu plutot que recopie : une constante recopiee derive en silence.
SCRIPT_LIEU = "scripts/world_v2/poi/waterfall_cave_place.gd"
GRAINE_HAUTEUR_M = 0.90        # a hauteur de torse, pas au ras du sol

GLB_DEFAUT = "assets/environment/caves/SM_WaterfallCave.glb"


def racine_depot(depart):
    d = os.path.abspath(depart)
    while d != "/":
        if os.path.isdir(os.path.join(d, ".git")) or \
           os.path.isfile(os.path.join(d, ".git")):
            return d
        d = os.path.dirname(d)
    return os.path.abspath(depart)


def lire_modele_salle(racine):
    """`MODELE_SALLE` du script de lieu, converti en repere MODELE.

    Godot -> Blender : `(X, Y, Z)` devient `(X, -Z, Y)`. La conversion est
    ecrite ici une fois, et le point converti est VERIFIE dans le vide avant
    usage — une graine dans la roche rendrait « etanche » sans rien prouver.
    """
    chemin = os.path.join(racine, SCRIPT_LIEU)
    if not os.path.isfile(chemin):
        return None
    for ligne in open(chemin, encoding="utf-8"):
        if "MODELE_SALLE" not in ligne or "Vector3(" not in ligne:
            continue
        brut = ligne.split("Vector3(", 1)[1].split(")", 1)[0]
        try:
            gx, gy, gz = [float(v) for v in brut.split(",")]
        except ValueError:
            return None
        return (gx, -gz, gy)
    return None


# ---------------------------------------------------------------------------
# LA LECTURE DE PARITE — ECRITE UNE FOIS, DANS UNE FONCTION NOMMEE
# ---------------------------------------------------------------------------

def hauteurs_de_transition(grille, x, y, z_depart, portee):
    """Cotes z ou une colonne verticale traverse une face, triees.

    Le rayon PART SOUS TOUT LE MAILLAGE, donc dans l'air. La lecture qui en
    decoule est donc, sans exception :

        un point est DANS LA ROCHE si le nombre de transitions SOUS lui est
        IMPAIR.

    `tools/CLAUDE.md` consigne trois verdicts faux dus a cette lecture, tous
    dans le meme fichier, dont deux a vingt minutes d'intervalle. La lecon
    n'est pas que la parite est subtile : c'est qu'elle s'ecrit UNE fois,
    ici, et se reutilise — jamais redérivée par branche.
    """
    return sorted(z_depart + t for t, _ in
                  P.impacts(grille, (x, y, z_depart), (0.0, 0.0, 1.0),
                            portee))


class Espace(object):
    """Grille de voxels : `air[i][j][k]` vrai si la case est dans le vide.

    LA CLASSIFICATION VOTE SUR TROIS AXES, ET VOICI POURQUOI — mesure du
    2026-08-16, sur `cc3596c5`, au pas 0,10 m.

    La premiere version ne lisait la parite que le long de +Z, une colonne
    par case du plan (x, y). Le candidat INTACT sortait alors en FUITE, et
    aucune epaisseur de bouchon jusqu'a 3,00 m ne la faisait disparaitre.
    Ce n'etait ni un trou dans la roche, ni un defaut d'inondation, ni la
    forme de la bouche.

    C'etait la parite. Sur un maillage clos, toute colonne doit compter un
    nombre PAIR d'impacts — le rayon entre autant de fois qu'il sort. Un
    comptage direct en donne :

        axe +Z : 33 950 colonnes, 26 IMPAIRES (0,077 %), max 6 impacts
        axe +X : 24 850 colonnes, 15 IMPAIRES (0,060 %), max 10 impacts

    Vingt-six colonnes fausses suffisent : chacune est une cheminee de
    10 cm qui relie la galerie au ciel d'un bout a l'autre du massif, et
    l'inondation exterieure s'y engouffre. Le compte etait precis,
    reproductible, et sans rapport avec la geometrie.

    C'est la MEME faute que `cave_collar.coupe_du_plan` a portee puis
    corrigee par un vote a quatre parites — la ou, sur un cylindre, 18 289
    cases creuses avaient ete declarees « air libre » — et la MEME que
    `tools/blender/probe_cave_edt_plan_bouche.py` porte encore, ou le banc
    la mesure a -0,52 m sur la forme `rasant`. Je l'ai ecrite une troisieme
    fois, dans mon propre oracle, apres l'avoir documentee chez les autres.

    Un rayon rasant se trompe le long d'UN axe ; il est tres improbable
    qu'il se trompe le long de trois. On lit donc la parite selon +X, +Y et
    +Z, et une case est de l'air si AU MOINS DEUX des trois le disent. Le
    desaccord residuel est compte et publie : s'il explose, c'est le
    maillage qui est en cause, pas le vote.
    """

    AXES = ((0, "+X"), (1, "+Y"), (2, "+Z"))

    def __init__(self, triangles, pas, marge=0.80, bavard=False):
        self.pas = pas
        grille = P.Grille(triangles)
        lo, hi = grille.aabb()
        self.lo = [lo[k] - marge for k in range(3)]
        self.hi = [hi[k] + marge for k in range(3)]
        self.dim = [max(1, int(math.ceil((self.hi[k] - self.lo[k]) / pas)))
                    for k in range(3)]
        nx, ny, nz = self.dim
        total = nx * ny * nz
        votes = []
        self.colonnes_impaires = {}
        for axe, nom in self.AXES:
            grille_axe, impaires, colonnes = self._parite_selon(grille, axe)
            votes.append(grille_axe)
            self.colonnes_impaires[nom] = (impaires, colonnes)
            if bavard:
                print("   parite %s : %d colonne(s) sur %d de parite IMPAIRE "
                      "(%.3f %%)" % (nom, impaires, colonnes,
                                     100.0 * impaires / max(1, colonnes)))
        self.air = bytearray(total)
        desaccords = 0
        a, b, c = votes
        for n in range(total):
            s = a[n] + b[n] + c[n]
            if s >= 2:
                self.air[n] = 1
            if s == 1 or s == 2:
                desaccords += 1
        self.desaccords = desaccords
        if bavard:
            print("   vote a trois axes : %d case(s) en desaccord sur %d "
                  "(%.4f %%)" % (desaccords, total,
                                 100.0 * desaccords / max(1, total)))

    def _parite_selon(self, grille, axe):
        """Grille de parite obtenue en balayant selon UN seul axe."""
        nx, ny, nz = self.dim
        dim = (nx, ny, nz)
        u, v = [k for k in range(3) if k != axe]
        direction = tuple(1.0 if k == axe else 0.0 for k in range(3))
        portee = (self.hi[axe] - self.lo[axe]) + 2.0
        sortie = bytearray(nx * ny * nz)
        impaires = 0
        colonnes = 0
        pas = self.pas
        for iu in range(dim[u]):
            for iv in range(dim[v]):
                depart = [0.0, 0.0, 0.0]
                depart[u] = self.lo[u] + (iu + 0.5) * pas
                depart[v] = self.lo[v] + (iv + 0.5) * pas
                depart[axe] = self.lo[axe] - 0.5
                bornes = sorted(depart[axe] + t for t, _ in
                                P.impacts(grille, tuple(depart), direction,
                                          portee))
                colonnes += 1
                if len(bornes) % 2:
                    impaires += 1
                pointeur = 0
                dedans = False
                traversant = 0
                cellule = [0, 0, 0]
                cellule[u] = iu
                cellule[v] = iv
                for iw in range(dim[axe]):
                    w0 = self.lo[axe] + iw * pas
                    w1 = w0 + pas
                    w = w0 + 0.5 * pas
                    while pointeur < len(bornes) and bornes[pointeur] <= w:
                        pointeur += 1
                        dedans = not dedans
                    # UNE CASE TRAVERSEE PAR UNE PEAU EST DE LA ROCHE.
                    #
                    # Echantillonner le seul CENTRE fait disparaitre toute
                    # feuille plus mince qu'une maille. Mesure du
                    # 2026-08-16 : au (x 0,58 ; y 5,82) le toit du vide ne
                    # fait que 0,023 m ; au pas de 0,10 m aucun centre de
                    # case ne tombe dedans, le toit s'evapore, et l'oracle
                    # annoncait une CHEMINEE de la galerie jusqu'au ciel. Le
                    # verdict etait faux, precis et parfaitement plausible.
                    #
                    # C'est la forme `fente_sous_maille` du banc, rencontree
                    # dans la nature. On classe donc en roche toute case que
                    # la peau TRAVERSE, meme d'un cheveu.
                    while traversant < len(bornes) and bornes[traversant] < w0:
                        traversant += 1
                    coupee = (traversant < len(bornes)
                              and bornes[traversant] < w1)
                    if (not dedans) and not coupee:
                        cellule[axe] = iw
                        sortie[(cellule[0] * ny + cellule[1]) * nz
                               + cellule[2]] = 1
        return sortie, impaires, colonnes

    def index(self, i, j, k):
        return (i * self.dim[1] + j) * self.dim[2] + k

    def cellule(self, point):
        return tuple(int((point[k] - self.lo[k]) / self.pas)
                     for k in range(3))

    def centre(self, i, j, k):
        return tuple(self.lo[m] + (c + 0.5) * self.pas
                     for m, c in enumerate((i, j, k)))

    def dedans(self, i, j, k):
        return (0 <= i < self.dim[0] and 0 <= j < self.dim[1]
                and 0 <= k < self.dim[2])

    def compte_air(self):
        return sum(self.air)

    def tranche_bouche(self, y_bouche, epaisseur=None):
        """Indices j du BOUCHON, centre sur `y_bouche`.

        POURQUOI CE N'EST PLUS UNE SEULE CASE — mesure du 2026-08-16.

        La premiere version bouchait UNE dalle, et le candidat intact
        `cc3596c5` sortait en FUITE : la graine rejoignait le bord malgre le
        bouchon. Ce n'est ni un trou dans la roche ni un defaut d'inondation.

        C'est que LA BOUCHE N'EST PAS PLANE. Le porche est evase : le bord
        de son ouverture ne vit pas dans le plan `y = -1,15`, il court sur
        une PLAGE de `y`. Un bouchon plan — qu'il soit l'ouverture 2D de
        l'ancien oracle ou ma dalle pleine — ne coupe donc pas l'entonnoir,
        et l'air passe par-dessus ou par-dessous le plan sans jamais le
        traverser.

        Le bouchon est donc une TRANCHE EPAISSE, et son epaisseur minimale
        utile est MESUREE par balayage plutot que choisie : c'est le nombre
        que publie `--balayage`. L'angle mort de l'instrument vaut exactement
        cette epaisseur, et il est publie avec elle.
        """
        e = self.pas if epaisseur is None else epaisseur
        j0 = int(math.floor((y_bouche - 0.5 * e - self.lo[1]) / self.pas))
        j1 = int(math.floor((y_bouche + 0.5 * e - self.lo[1]) / self.pas))
        return [v for v in range(j0, j1 + 1) if 0 <= v < self.dim[1]]


def inonder(espace, graines, bloques):
    """Composante connexe en 6-voisinage. `bloques` : set d'indices j."""
    nx, ny, nz = espace.dim
    vu = bytearray(nx * ny * nz)
    file = deque()
    for i, j, k in graines:
        if not espace.dedans(i, j, k):
            continue
        if j in bloques:
            continue
        n = espace.index(i, j, k)
        if espace.air[n] and not vu[n]:
            vu[n] = 1
            file.append((i, j, k))
    while file:
        i, j, k = file.popleft()
        for di, dj, dk in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0),
                           (0, 0, 1), (0, 0, -1)):
            a, b, c = i + di, j + dj, k + dk
            if not (0 <= a < nx and 0 <= b < ny and 0 <= c < nz):
                continue
            if b in bloques:
                continue
            n = espace.index(a, b, c)
            if espace.air[n] and not vu[n]:
                vu[n] = 1
                file.append((a, b, c))
    return vu


def cases_de_bord(espace):
    nx, ny, nz = espace.dim
    bord = []
    for i in range(nx):
        for j in range(ny):
            bord.append((i, j, 0))
            bord.append((i, j, nz - 1))
    for i in range(nx):
        for k in range(nz):
            bord.append((i, 0, k))
            bord.append((i, ny - 1, k))
    for j in range(ny):
        for k in range(nz):
            bord.append((0, j, k))
            bord.append((nx - 1, j, k))
    return bord


def graine_valide(espace, point):
    """Case d'air la plus proche du point vise, en montant. Ou None."""
    i, j, k = espace.cellule(point)
    for montee in range(0, 40):
        c = k + montee
        if not espace.dedans(i, j, c):
            break
        if espace.air[espace.index(i, j, c)]:
            return (i, j, c), montee
    return None, None


def juger(triangles, pas, y_bouche, point_graine, bavard=True,
          epaisseur=None, espace=None, rapide=False):
    """Rend un dictionnaire de verdict. Aucun seuil, une disjonction."""
    if espace is None:
        espace = Espace(triangles, pas)
    bloques = set(espace.tranche_bouche(y_bouche, epaisseur))
    graine, montee = graine_valide(espace, point_graine)
    if graine is None:
        return dict(bloque="graine interieure introuvable dans le vide")
    vu = inonder(espace, cases_de_bord(espace), bloques)
    fuite = bool(vu[espace.index(*graine)])
    volume_ext = sum(vu)
    # EN MODE RAPIDE on saute l'inondation interieure : le balayage n'a
    # besoin que du booleen de fuite, et chaque inondation coute une passe
    # sur quatre millions de cases.
    vu_int = None if rapide else inonder(espace, [graine], bloques)
    volume_int = None if rapide else sum(vu_int)
    if bavard:
        print("   grille %dx%dx%d, pas %.3f m, %d case(s) d'air sur %d"
              % (espace.dim[0], espace.dim[1], espace.dim[2], pas,
                 espace.compte_air(),
                 espace.dim[0] * espace.dim[1] * espace.dim[2]))
        print("   dalle bouchee : j = %s, soit y dans [%.3f, %.3f)"
              % (sorted(bloques),
                 espace.lo[1] + min(bloques) * pas,
                 espace.lo[1] + (max(bloques) + 1) * pas)
              if bloques else "   AUCUNE dalle bouchee")
        print("   graine interieure : case %s, centre (%.2f ; %.2f ; %.2f), "
              "montee de %d case(s) depuis le repere"
              % (graine, espace.centre(*graine)[0], espace.centre(*graine)[1],
                 espace.centre(*graine)[2], montee))
        print("   composante EXTERIEURE %d case(s) = %.1f m3 | composante de "
              "la GRAINE %s"
              % (volume_ext, volume_ext * pas ** 3,
                 ("%d case(s) = %.1f m3" % (volume_int, volume_int * pas ** 3))
                 if volume_int is not None else "(non calculee)"))
    return dict(fuite=fuite, volume_exterieur=volume_ext,
                volume_graine=volume_int, graine=list(graine),
                dalle=sorted(bloques), pas=pas,
                dim=list(espace.dim), air=espace.compte_air(),
                espace=espace)


# ---------------------------------------------------------------------------
# SABOTAGES — chacun doit retirer LA CHOSE TESTEE, et le prouver
# ---------------------------------------------------------------------------

def largeur_libre(triangles, origine, direction, rayon_max=1.20, pas=0.05):
    """Rayon autour de l'axe ou le percement laisse VRAIMENT passer.

    POURQUOI CETTE MESURE EXISTE — echec du 2026-08-16.

    Le premier percement retirait les triangles dont le BARYCENTRE tombe a
    moins de 0,40 m de l'axe. Trente-neuf triangles partaient, la geometrie
    changeait pour de bon... et l'oracle rendait ETANCHE. Le trou etait
    ouvert au sens de la geometrie et FERME au sens de la grille : les
    triangles voisins, gardes parce que leur barycentre etait dehors,
    couvraient encore une partie de l'ouverture, et la regle « une case
    traversee par une peau est de la roche » refermait le passage.

    Un sabotage doit donc prouver la LARGEUR qu'il ouvre, pas le nombre de
    triangles qu'il retire. On tire des rayons paralleles a l'axe, a
    distance croissante, et on rend la plus grande distance a laquelle
    AUCUN rayon ne rencontre plus rien.
    """
    grille = P.Grille(triangles)
    n = math.sqrt(sum(v * v for v in direction))
    d = tuple(v / n for v in direction)
    # deux vecteurs perpendiculaires a l'axe
    ref = (0.0, 0.0, 1.0) if abs(d[2]) < 0.9 else (1.0, 0.0, 0.0)
    u = (d[1] * ref[2] - d[2] * ref[1], d[2] * ref[0] - d[0] * ref[2],
         d[0] * ref[1] - d[1] * ref[0])
    nu = math.sqrt(sum(v * v for v in u)) or 1.0
    u = tuple(v / nu for v in u)
    w = (d[1] * u[2] - d[2] * u[1], d[2] * u[0] - d[0] * u[2],
         d[0] * u[1] - d[1] * u[0])
    libre = 0.0
    r = 0.0
    while r <= rayon_max + 1e-9:
        propre = True
        for k in range(8):
            a = 2.0 * math.pi * k / 8.0
            dep = tuple(origine[m] + r * (math.cos(a) * u[m]
                                          + math.sin(a) * w[m])
                        for m in range(3))
            if P.impacts(grille, dep, d, 60.0):
                propre = False
                break
        if not propre:
            break
        libre = r
        r += pas
    return libre


def percer(triangles, origine, direction, rayon=0.90, marge=0.60):
    """Retire les triangles d'un tunnel cylindrique le long d'une direction.

    Rend `(garde, retires, portee_z, portee_t)`. Le tunnel part de la graine
    et va jusqu'au-dela de la derniere peau rencontree : il traverse donc
    TOUTES les peaux, et pas seulement la premiere. On publie le nombre
    retire et leur emprise, parce qu'un sabotage dont on ne sait pas ce
    qu'il a enleve ne prouve rien du verdict qu'il produit.
    """
    grille = P.Grille(triangles)
    n = math.sqrt(sum(v * v for v in direction))
    d = tuple(v / n for v in direction)
    liste = P.impacts(grille, origine, d, 60.0)
    if not liste:
        return triangles, 0, None, None
    t_max = liste[-1][0] + marge
    garde, retires = [], 0
    lo = [None, None, None]
    hi = [None, None, None]
    for tri in triangles:
        b = tuple(sum(s[k] for s in tri) / 3.0 for k in range(3))
        w = tuple(b[k] - origine[k] for k in range(3))
        t = sum(w[k] * d[k] for k in range(3))
        if 0.0 <= t <= t_max:
            perp = math.sqrt(max(0.0, sum(w[k] * w[k] for k in range(3))
                                 - t * t))
            if perp <= rayon:
                retires += 1
                for s in tri:
                    for k in range(3):
                        if lo[k] is None or s[k] < lo[k]:
                            lo[k] = s[k]
                        if hi[k] is None or s[k] > hi[k]:
                            hi[k] = s[k]
                continue
        garde.append(tri)
    return garde, retires, (lo, hi), t_max


def percer_boite(triangles, centre, demi):
    """Retire les triangles d'une boite — sert au controle de l'angle mort."""
    garde, retires = [], 0
    for tri in triangles:
        b = tuple(sum(s[k] for s in tri) / 3.0 for k in range(3))
        if all(abs(b[k] - centre[k]) <= demi[k] for k in range(3)):
            retires += 1
            continue
        garde.append(tri)
    return garde, retires


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("glb", nargs="?", default=None)
    ap.add_argument("--pas", type=float, default=0.10)
    ap.add_argument("--y-bouche", type=float, default=Y_BOUCHE)
    ap.add_argument("--sabotages", action="store_true",
                    help="joue la batterie de controles negatifs")
    ap.add_argument("--json", default=None)
    args = ap.parse_args()

    racine = racine_depot(os.path.dirname(os.path.abspath(__file__)))
    chemin = args.glb or os.path.join(racine, GLB_DEFAUT)
    if not os.path.isfile(chemin):
        print("BLOQUE : maillage introuvable : %s" % chemin)
        return 3
    import hashlib
    sha_avant = hashlib.sha256(open(chemin, "rb").read()).hexdigest()
    triangles, matieres = P.triangles_du_glb(chemin)
    repere = lire_modele_salle(racine)
    if repere is None:
        print("BLOQUE : MODELE_SALLE illisible dans %s" % SCRIPT_LIEU)
        return 3
    graine_visee = (repere[0], repere[1], repere[2] + GRAINE_HAUTEUR_M)

    print("=" * 78)
    print("ORACLE D'ETANCHEITE — classement de l'espace, sans station")
    print("=" * 78)
    print("maillage : %s" % chemin)
    print("sha256   : %s" % sha_avant)
    print("triangles: %d   matieres : %s"
          % (len(triangles), ", ".join(sorted(matieres))))
    print("graine visee (repere MODELE, depuis %s + %.2f m) : "
          "(%.2f ; %.2f ; %.2f)"
          % (SCRIPT_LIEU, GRAINE_HAUTEUR_M, graine_visee[0], graine_visee[1],
             graine_visee[2]))
    print()

    rapport = dict(maillage=chemin, sha256=sha_avant,
                   triangles=len(triangles), pas=args.pas,
                   graine_visee=list(graine_visee), controles=[])

    print("-" * 78)
    print("BALAYAGE — quelle EPAISSEUR de bouchon coupe l'entonnoir ?")
    print("-" * 78)
    print("   La bouche n'est pas plane : le bord du porche evase court sur")
    print("   une plage de y. On ne CHOISIT donc pas l'epaisseur du bouchon,")
    print("   on la MESURE — et l'angle mort de l'instrument vaut exactement")
    print("   l'epaisseur retenue.")
    espace_ref = Espace(triangles, args.pas, bavard=True)
    print("   grille %dx%dx%d, %d case(s) d'air"
          % (espace_ref.dim[0], espace_ref.dim[1], espace_ref.dim[2],
             espace_ref.compte_air()))
    balayage = []
    epaisseur = None
    # BALAYAGE GEOMETRIQUE PUIS RAFFINEMENT. Chaque essai coute une
    # inondation sur quatre millions de cases ; 25 essais lineaires
    # couteraient dix minutes pour la meme information.
    essais = [1, 2, 3, 5, 8, 12, 17, 23, 30]
    for n_cases in essais:
        e = n_cases * args.pas
        r = juger(triangles, args.pas, args.y_bouche, graine_visee,
                  bavard=False, epaisseur=e, espace=espace_ref, rapide=True)
        r.pop("espace", None)
        if r.get("bloque"):
            print("BLOQUE : %s" % r["bloque"])
            return 3
        balayage.append(dict(cases=n_cases, epaisseur_m=e,
                             fuite=bool(r["fuite"]),
                             volume_graine=r["volume_graine"]))
        print("      %2d case(s) = %.2f m : %s, composante EXTERIEURE "
              "%8d case(s)"
              % (n_cases, e, "FUITE  " if r["fuite"] else "ETANCHE",
                 r["volume_exterieur"]))
        if not r["fuite"]:
            epaisseur = e
            break
    rapport["balayage_bouchon"] = balayage
    echecs = []
    if epaisseur is None:
        print()
        print("   >>> AUCUNE epaisseur jusqu'a %.2f m ne coupe la bouche."
              % (max(essais) * args.pas))
        print("       Deux lectures possibles, et l'instrument ne les separe")
        print("       pas : soit la cavite communique avec le dehors")
        print("       AILLEURS qu'a la bouche, soit l'entonnoir est plus")
        print("       profond que la plage balayee.")
        echecs.append("aucun bouchon ne coupe la bouche")
        rapport["epaisseur_bouchon_m"] = None
        print("=" * 78)
        print("VERDICT GLOBAL : BLOQUE")
        print("=" * 78)
        if args.json:
            with open(args.json, "w", encoding="utf-8") as poignee:
                json.dump(rapport, poignee, indent=1, ensure_ascii=False)
        return 3
    print()
    print("   >>> EPAISSEUR RETENUE : %.2f m (%d case[s]). ANGLE MORT DE"
          % (epaisseur, int(round(epaisseur / args.pas))))
    print("       L'INSTRUMENT : tout trou entierement contenu dans cette")
    print("       tranche est invisible. Mesure ci-dessous.")
    rapport["epaisseur_bouchon_m"] = epaisseur

    print()
    print("-" * 78)
    print("REFERENCE — maillage intact, bouchon canonique en place")
    print("-" * 78)
    base = juger(triangles, args.pas, args.y_bouche, graine_visee,
                 epaisseur=epaisseur, espace=espace_ref)
    base.pop("espace", None)
    print("   VERDICT : %s" % ("FUITE" if base["fuite"] else "ETANCHE"))
    rapport["reference"] = base
    if base["fuite"]:
        echecs.append("le maillage intact fuit")

    if args.sabotages:
        controles = []

        # 1. CONTROLE DE NON-VACUITE. Sans bouchon, l'exterieur DOIT
        #    rejoindre la graine par la bouche. Si ce controle est vert,
        #    l'oracle ne mesure rien du tout.
        print()
        print("-" * 78)
        print("CONTROLE 0 — bouche NON bouchee : la fuite est ATTENDUE")
        print("-" * 78)
        sans = juger(triangles, args.pas, -1e9, graine_visee,
                     epaisseur=epaisseur, espace=espace_ref)
        sans.pop("espace", None)
        print("   VERDICT : %s   (attendu : FUITE)"
              % ("FUITE" if sans["fuite"] else "ETANCHE"))
        controles.append(dict(nom="bouche ouverte", attendu="fuite",
                              obtenu="fuite" if sans["fuite"] else "etanche",
                              ok=bool(sans["fuite"]), retires=0))
        if not sans["fuite"]:
            echecs.append("bouche ouverte : pas de fuite — l'oracle est vide")

        # 2. TROUS DIRECTIONNELS. « Lateral » n'a aucun sens dans un oracle
        #    qui ignore les stations : on perce selon les axes MODELE depuis
        #    la graine, et on publie ou chaque trou est reellement sorti.
        graine_reelle = espace_ref.centre(*base["graine"])
        directions = (("toit (+Z)", (0.0, 0.0, 1.0)),
                      ("plancher (-Z)", (0.0, 0.0, -1.0)),
                      ("flanc +X", (1.0, 0.0, 0.0)),
                      ("flanc -X", (-1.0, 0.0, 0.0)),
                      ("fond +Y", (0.0, 1.0, 0.0)),
                      ("avant -Y", (0.0, -1.0, 0.0)))
        for nom, d in directions:
            print()
            print("-" * 78)
            print("CONTROLE — trou vers le %s" % nom)
            print("-" * 78)
            garde, retires, emprise, t_max = percer(triangles, graine_reelle,
                                                    d)
            if not retires:
                print("   BLOQUE : le percement n'a retire AUCUN triangle — "
                      "le controle ne prouve rien")
                controles.append(dict(nom=nom, attendu="fuite",
                                      obtenu="sabotage vide", ok=False,
                                      retires=0))
                echecs.append("%s : sabotage vide" % nom)
                continue
            lo, hi = emprise
            print("   %d triangle(s) retire(s) sur %d ; tunnel jusqu'a "
                  "t = %.2f m" % (retires, len(triangles), t_max))
            print("   emprise du retrait : x %.2f..%.2f  y %.2f..%.2f  "
                  "z %.2f..%.2f" % (lo[0], hi[0], lo[1], hi[1], lo[2], hi[2]))
            # LA LARGEUR REELLEMENT OUVERTE, pas le compte de triangles.
            libre = largeur_libre(garde, graine_reelle, d)
            print("   largeur libre mesuree : rayon %.2f m (%.1f case[s]) "
                  "sans aucun impact" % (libre, libre / args.pas))
            if libre < 2.0 * args.pas:
                print("   BLOQUE : le trou ouvre moins de deux cases. Ce "
                      "controle ne prouve RIEN sur l'oracle — il mesure la "
                      "faiblesse du sabotage.")
                controles.append(dict(nom=nom, attendu="fuite",
                                      obtenu="sabotage trop etroit", ok=False,
                                      retires=retires, largeur_libre=libre))
                echecs.append("%s : sabotage trop etroit (%.2f m)"
                              % (nom, libre))
                continue
            r = juger(garde, args.pas, args.y_bouche, graine_visee,
                      epaisseur=epaisseur)
            r.pop("espace", None)
            obtenu = "fuite" if r.get("fuite") else "etanche"
            print("   VERDICT : %s   (attendu : FUITE)" % obtenu.upper())
            ok = bool(r.get("fuite"))
            controles.append(dict(nom=nom, attendu="fuite", obtenu=obtenu,
                                  ok=ok, retires=retires,
                                  largeur_libre=libre,
                                  emprise=dict(lo=lo, hi=hi)))
            if not ok:
                echecs.append("%s : trou non detecte" % nom)

        # 3. L'ANGLE MORT, MESURE PLUTOT QUE TU.
        print()
        print("-" * 78)
        print("CONTROLE — l'ANGLE MORT du bouchon, mesure")
        print("-" * 78)
        if epaisseur <= args.pas * 1.001:
            print("   SANS OBJET : le balayage a retenu UNE case (%.2f m)."
                  % epaisseur)
            print("   L'angle mort du bouchon se confond alors avec la limite")
            print("   de resolution de la grille, deja enoncee et deja bornee.")
            print("   Fabriquer ici une epreuve reviendrait a mesurer deux")
            print("   fois la meme cecite, et a la presenter comme deux")
            print("   garanties. Elle redeviendra necessaire si un bouchon")
            print("   plus epais est un jour retenu.")
            controles.append(dict(nom="angle mort", attendu="sans objet",
                                  obtenu="sans objet", ok=True, retires=0,
                                  raison="bouchon d'une seule case"))
            rapport["controles"] = controles
            sha_apres = __import__("hashlib").sha256(
                open(chemin, "rb").read()).hexdigest()
            print()
            print("-" * 78)
            print("RESTAURATION : sha256 %s -> %s   %s"
                  % (sha_avant[:16], sha_apres[:16],
                     "IDENTIQUE" if sha_avant == sha_apres
                     else "!!! MODIFIE !!!"))
            print("-" * 78)
            if sha_avant != sha_apres:
                echecs.append("le maillage source a ete modifie")
            rapport["sha256_apres"] = sha_apres
            print()
            print("=" * 78)
            if echecs:
                for e in echecs:
                    print("ECHEC : %s" % e)
                print("VERDICT GLOBAL : FAIL")
            else:
                print("VERDICT GLOBAL : PASS — le maillage est etanche, et "
                      "chaque controle negatif a rougi")
            print("=" * 78)
            rapport["echecs"] = echecs
            if args.json:
                with open(args.json, "w", encoding="utf-8") as poignee:
                    json.dump(rapport, poignee, indent=1, ensure_ascii=False)
                print("json : %s" % args.json)
            return 1 if echecs else 0
        print("   Le bouchon fait %.2f m d'epaisseur. Tout trou entierement"
              % epaisseur)
        print("   contenu dedans lui est invisible : c'est le prix du choix")
        print("   conservateur, et il se mesure. On perce donc DANS la")
        print("   tranche, puis JUSTE DERRIERE elle. Le premier DOIT etre")
        print("   masque, le second DOIT etre vu — sinon l'angle mort n'est")
        print("   pas celui qu'on annonce.")
        pas = args.pas
        demi = 0.5 * epaisseur - 0.25 * pas
        for etiquette, y_centre, attendu in (
                ("dans la tranche", args.y_bouche, "etanche"),
                ("juste derriere", args.y_bouche + 0.5 * epaisseur
                 + demi + 0.5 * pas, "fuite")):
            garde, retires = percer_boite(
                triangles, (-3.60, y_centre, 1.20), (1.20, demi, 1.20))
            print()
            print("   trou %s (y = %+.3f, demi-epaisseur %.3f) : %d "
                  "triangle(s) retire(s)"
                  % (etiquette, y_centre, demi, retires))
            if not retires:
                print("      BLOQUE : sabotage vide, ce controle ne prouve "
                      "rien")
                controles.append(dict(nom="angle mort %s" % etiquette,
                                      attendu=attendu, obtenu="sabotage vide",
                                      ok=False, retires=0))
                continue
            r = juger(garde, pas, args.y_bouche, graine_visee, bavard=False,
                      epaisseur=epaisseur)
            r.pop("espace", None)
            obtenu = "fuite" if r.get("fuite") else "etanche"
            print("      VERDICT : %s   (attendu : %s)"
                  % (obtenu.upper(), attendu.upper()))
            controles.append(dict(nom="angle mort %s" % etiquette,
                                  attendu=attendu, obtenu=obtenu,
                                  ok=(obtenu == attendu), retires=retires))

        rapport["controles"] = controles

    sha_apres = hashlib.sha256(open(chemin, "rb").read()).hexdigest()
    print()
    print("-" * 78)
    print("RESTAURATION : sha256 %s -> %s   %s"
          % (sha_avant[:16], sha_apres[:16],
             "IDENTIQUE" if sha_avant == sha_apres else "!!! MODIFIE !!!"))
    print("-" * 78)
    if sha_avant != sha_apres:
        echecs.append("le maillage source a ete modifie")
    rapport["sha256_apres"] = sha_apres

    # LE VIDE N'EST PAS VERT. Un oracle qui n'a exerce AUCUN controle rendait
    # 0 faute d'echec — la meme famille que le `diff` sur deux fichiers absents
    # deja consignee dans tools/CLAUDE.md. Un verdict doit publier la TAILLE
    # de ce qu'il a examine, pas seulement son resultat.
    if not controles:
        echecs.append("aucun controle exerce : un oracle qui n examine rien "
                      "ne prouve rien")
    print()
    print("=" * 78)
    print("CONTROLES EXERCES : %d" % len(controles))
    if echecs:
        for e in echecs:
            print("ECHEC : %s" % e)
        print("VERDICT GLOBAL : FAIL")
    else:
        print("VERDICT GLOBAL : PASS — le maillage est etanche, et chaque "
              "controle negatif a rougi")
    print("=" * 78)
    rapport["echecs"] = echecs
    if args.json:
        with open(args.json, "w", encoding="utf-8") as poignee:
            json.dump(rapport, poignee, indent=1, ensure_ascii=False)
        print("json : %s" % args.json)
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main())
