#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ORACLE GLOBAL — deux methodes disjointes pour un seul verdict d'etancheite.

POURQUOI CET INSTRUMENT REMPLACE LES DEUX PRECEDENTS
====================================================

`cave_voxel_oracle.py` sort en RC 3 depuis qu'il existe. `cave_seal_oracle.py`
rend ETANCHE sur le candidat et **cinq de ses six controles negatifs ne
rougissent pas** : on perce, de la graine jusqu'au dehors, un tunnel de 0,35 a
0,65 m de rayon libre MESURE, et il repond encore ETANCHE. Un acquittement par
aveuglement.

La cause est de fond, et son en-tete la nomme lui-meme : percer en RETIRANT
DES TRIANGLES rend le maillage OUVERT ; la parite n'y definit plus de dedans ;
le vote a trois axes tranche alors 2 contre 1 en faveur de la roche et
REBOUCHE le trou qu'on vient de percer. Le vote, introduit pour corriger un
vrai defaut (26 colonnes de parite impaire), est devenu la cause de la cecite.

On ne repare pas cela en reglant le vote. On le repare en cessant d'avoir
besoin de la parite.

CE QUE MESURE CET ORACLE, ET SUR QUEL NOEUD
===========================================

Le GLB porte deux noeuds. Cet oracle mesure **`SM_WaterfallCave`**, le
maillage RENDU (~20 000 faces) — sauf `--noeud` explicite. `COL_WaterfallCave`
est le proxy de collision (880 faces, un loft entierement distinct) : le
mesurer reviendrait a prouver l'etancheite d'une surface que personne ne voit.
Le nom du noeud mesure est imprime dans l'en-tete de chaque execution.

METHODE A — TOPOLOGIE. Aucune grille, aucun rayon, aucune resolution.
=====================================================================

Soudure des sommets par POSITION (quantification 1e-6 m). Sans elle, les six
primitives de matiere du GLB rendraient des milliers de faux bords libres :
un GLB indexe ses sommets PAR PRIMITIVE, la couture entre deux matieres est
donc dedoublee. On compte ensuite :

  * les composantes de faces ;
  * les aretes a UNE face  -> bords libres  -> le maillage est ouvert ;
  * les aretes a PLUS DE DEUX faces -> non-manifold ;
  * khi = V - E + F, et le genre (2 - khi) / 2 par composante fermee.

Ce que le genre apporte et que l'inondation ne peut pas apporter : il **n'a
aucune limite de resolution**. Un tunnel de 1 mm incremente le genre de 1
exactement comme un tunnel de 1 m. C'est le complement exact de l'angle mort
de la methode B.

Ce qu'il n'apporte PAS : il ne localise rien. Un genre non nul dit qu'une anse
existe, jamais ou. Et il ne distingue pas une ARCHE (boucle de matiere,
legitime) d'une PERCEE (trou cavite -> dehors) : les deux sont exactement le
meme invariant. Seule la methode B tranche entre les deux. Les deux methodes
sont donc tenues SEPAREES dans le journal, pour qu'on voie laquelle parle.

METHODE B — CLASSEMENT D'ESPACE, SANS PARITE NI VOTE
====================================================

Deux cases 6-adjacentes sont RELIEES si et seulement si le segment joignant
leurs centres ne coupe aucun triangle.

C'est tout. Il n'y a pas de notion de dedans, pas de comptage de croisements,
pas de vote. La surface partitionne l'espace a elle seule, et cette
partition reste definie que le maillage soit clos ou non — c'est exactement
la propriete qui manquait aux deux oracles precedents.

Le blocage s'obtient par trois balayages de rayons axes, un rayon par ligne
de grille : meme cout que les balayages de parite qu'il remplace. Un rayon
selon +Z rend toutes les cotes de traversee de sa colonne ; l'adjacence entre
la case k et la case k+1 est bloquee s'il existe une traversee entre leurs
deux centres. La meme lecture donne aussi, gratuitement, la decomposition de
la colonne en SEGMENTS de cases connectees — ce sont eux, et non les
4 millions de cases, que l'union-find manipule.

AIR ou ROCHE : par ORIENTATION, pas par parite. A chaque traversee on connait
le signe de `n . d`. Negatif, le rayon aborde la face par l'avant et ENTRE
dans le solide ; positif, il en SORT. C'est une lecture **locale** : elle ne
demande aucune fermeture et se degrade proprement quand un rayon manque une
peau. Chaque segment recoit jusqu'a deux voix, la composante agrege, et la
marge du vote est publiee.

Traversees coincidentes (rayon passant exactement par une arete partagee) :
si les deux voix ont le MEME signe, le rayon traverse vraiment, on en garde
une ; si elles ont des signes OPPOSES, le rayon ne fait qu'effleurer l'arete
sans changer de cote, et on les jette TOUTES LES DEUX. Cette regle-la est
pourquoi cet oracle n'emploie pas `P.impacts` : sa fusion a 0,01 m garde la
premiere traversee quel que soit son orientation, ce qui est le bon choix
pour compter une parite et le mauvais pour classer un cote.

LES OUVERTURES INTENTIONNELLES, ET POURQUOI IL N'EN RESTE QU'UNE
================================================================

Le cadrage annoncait un modele « ouvert par le dessous, ouvert par
conception », et deux inondations qui atteignaient le bord de la grille pour
cette raison. **Mesure faite : c'est faux.** Les trois geometries portent
ZERO bord libre :

    candidat cc3596c5   V=10045 E=30135 F=20090   bord libre 0   non-man 0
    BASE352  8bc8b9f9   V=9996  E=29984 F=19992   bord libre 0   non-man 4
    R2a-3.4  8bf1a1b3   V=9975  E=29931 F=19954   bord libre 0   non-man 0

Le maillage est FERME. Les inondations s'echappaient donc par la BOUCHE, qui
est intentionnelle, et n'etablissaient rien. Consequence : le masque « limite
inferieure du modele » **n'existe pas** et n'est pas construit. Le plus large
des deux angles morts disparait sans qu'aucune ligne ait ete ecrite pour lui.

Reste une seule ouverture intentionnelle, la bouche, et son masque est
volontairement le plus etroit possible :

  * ce n'est PAS une tranche pleine de cases, comme dans `cave_seal_oracle`,
    ou l'angle mort valait toute l'epaisseur retenue par son balayage ;
  * c'est une BARRIERE DE SURFACE D'EPAISSEUR NULLE : le plan `y = y_bouche`
    ne bloque que les adjacences selon y d'UNE seule couche, et laisse
    intactes toutes les adjacences x et z de cette meme couche.

Un plan qui couvre toute la grille ne peut pas etre contourne — c'est ce qui
faisait fuir le bouchon-ouverture-2D du premier oracle, dont le bord de porche
evase plongeait sous le terrain. Et parce qu'il est une SURFACE et non un
volume, il ne peut pas cacher un defaut situe a 5 cm de lui.

Angle mort restant, enonce d'avance et sans detour : un defaut contenu
entierement dans l'unique couche `y = y_bouche`, et seulement selon y. Plus la
limite de resolution commune a toute grille, que la methode A couvre.

LE VERDICT
==========

Sans barriere, sur le maillage brut :

  C1. exactement UNE composante ROCHE   -> sinon roche flottante ;
  C2. exactement UNE composante AIR     -> sinon poche d'air parasite.

Avec la barriere de bouche :

  C3. la composante de la graine interieure ne touche AUCUNE case de bord ;
  C4. elle contient la salle ET la niche — un scellement obtenu en amputant
      la cavite n'est pas un scellement.

Aucun seuil n'intervient. Aucun comptage n'est compare a une valeur calibree.

Usage :
    python3 tools/cave_oracle_global.py [glb] [--pas 0.10] [--noeud SM_...]
            [--y-bouche -1.15] [--balayage] [--json f.json] [--topologie-seule]

Codes de sortie : 0 = etanche · 1 = defaut · 3 = BLOQUE.
"""

import argparse
import array
import hashlib
import json
import math
import os
import sys
from collections import defaultdict, deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import probe_cave_openings as P                                # noqa: E402


NOEUD_DEFAUT = "SM_WaterfallCave"

## Repere de gameplay. Lu dans le script de LIEU, pas dans le generateur :
## `waterfall_cave_place.gd` decrit ou le joueur se tient, il ne decrit pas
## comment la roche a ete fabriquee. Aucune constante de
## `probe_cave_openings.py` n'est employee ici.
SCRIPT_LIEU = "scripts/world_v2/poi/waterfall_cave_place.gd"
GRAINE_HAUTEUR_M = 0.90        # a hauteur de torse, pas au ras du sol

## RELEVEMENT DES TEMOINS — decalage EXPLICITE, pas une coordonnee.
##
## Les `MODELE_*` designent un point AU SOL : `waterfall_cave_place.gd` y
## pose des objets, il n'y decrit pas un volume d'air. Un point exactement
## au sol tombe sur la surface, ou la case de grille est indecise. On releve
## donc, et ce chiffre doit rester un DECALAGE NOMME : une valeur relevee
## par convention tacite survit trois passes sans que personne ne sache d'ou
## elle vient, et passe dans la roche en silence le jour ou le sol remonte.
##
## `cave_oracle_bouche.py` MESURE sol et plafond a l'aplomb de chaque repere
## et publie les deux : le relevement est donc verifiable a chaque execution
## au lieu d'etre suppose.
TEMOIN_RELEVEMENT_M = 0.30
TEMOIN_RELEVEMENT_MOTIF = ("les MODELE_* designent un point au SOL ; au ras "
                           "de la surface la case est indecise")

## Plan de bouche par defaut. Meme valeur que les deux oracles precedents,
## pour que les resultats restent comparables. Surchargeable, et TOUJOURS
## corrobore par le balayage (`--balayage`), jamais cru sur parole.
Y_BOUCHE_DEFAUT = -1.15

## Quantum de soudure des sommets. Un GLB indexe PAR PRIMITIVE : les six
## matieres de cet asset dedoublent chaque sommet de couture. Sans soudure,
## la topologie compterait des milliers de faux bords libres.
QUANTUM_SOUDURE_M = 1e-6

## Tolerance de coincidence de deux traversees le long d'un meme rayon.
## Bien plus fine que la fusion a 0,01 m de `P.impacts` : ici on ne cherche
## qu'a reconnaitre deux faces partageant l'arete exacte que le rayon coupe.
COINCIDENCE_M = 1e-5


class Blocage(Exception):
    pass


# ===========================================================================
# METHODE A — TOPOLOGIE. Combinatoire pure : ni grille, ni rayon, ni pas.
# ===========================================================================

def souder(triangles, quantum=QUANTUM_SOUDURE_M):
    """Rend `(faces, nb_sommets)`, sommets identifies par POSITION."""
    inv = 1.0 / quantum
    index = {}
    faces = []
    for tri in triangles:
        f = []
        for s in tri:
            cle = (int(round(s[0] * inv)), int(round(s[1] * inv)),
                   int(round(s[2] * inv)))
            n = index.get(cle)
            if n is None:
                n = len(index)
                index[cle] = n
            f.append(n)
        faces.append(tuple(f))
    return faces, len(index)


def pincements(faces):
    """Sommets NON-MANIFOLD dont toutes les aretes sont pourtant manifold.

    POURQUOI CE CONTROLE EXISTE — mesure du 2026-08-16, et il a failli
    manquer.

    Un premier tunnel de toit a rendu un maillage a 0 bord libre, 0 arete
    non-manifold, 1 composante... et **khi = -3**. Or khi est PAIR sur toute
    surface fermee orientable, et l'enroulement etait coherent (aucune
    demi-arete repetee sur 61 290). L'impossibilite etait donc dans MA
    mesure, pas dans le maillage.

    La cause : un sommet PINCE. Deux nappes de surface se touchent en un
    point unique sans partager d'arete. Toutes les aretes restent a deux
    faces, le compteur d'aretes ne voit rien, et le sommet compte pour UN
    alors que la surface en demanderait DEUX. Chaque pincement retire donc
    exactement 1 a khi et rend le genre absurde.

    Sans ce controle, l'oracle aurait imprime « genre indefini » sur un
    maillage parfaitement exploitable, ou pire, un genre faux. Il imprime
    desormais le nombre de pincements et le khi DEPINCE.

    Rend la liste `(sommet, nombre de nappes)`.
    """
    incidentes = defaultdict(list)
    for indice, f in enumerate(faces):
        for v in f:
            incidentes[v].append(indice)
    par_arete = defaultdict(list)
    for indice, f in enumerate(faces):
        for a in range(3):
            u, w = f[a], f[(a + 1) % 3]
            cle = (u, w) if u < w else (w, u)
            par_arete[(u, cle)].append(indice)
            par_arete[(w, cle)].append(indice)

    mauvais = []
    for v, lot in incidentes.items():
        if len(lot) < 3:
            continue
        rang = {f: n for n, f in enumerate(lot)}
        parent = list(range(len(lot)))

        def trouver(x):
            while parent[x] != x:
                parent[x] = parent[parent[x]]
                x = parent[x]
            return x

        for i in lot:
            f = faces[i]
            for a in range(3):
                u, w = f[a], f[(a + 1) % 3]
                if v != u and v != w:
                    continue
                cle = (u, w) if u < w else (w, u)
                for j in par_arete[(v, cle)]:
                    if j in rang:
                        ra, rb = trouver(rang[i]), trouver(rang[j])
                        if ra != rb:
                            parent[ra] = rb
        nappes = len({trouver(x) for x in range(len(lot))})
        if nappes > 1:
            mauvais.append((v, nappes))
    return mauvais


def topologie(triangles):
    """Bords libres, non-manifold (aretes ET sommets), composantes, genre.

    Ne rend JAMAIS d'exception sur une geometrie mal formee : un maillage
    porteur d'aretes non-manifold — `BASE352` en porte quatre — doit etre
    MESURE et non refuse. Le genre est alors declare indefini, parce qu'il
    l'est reellement, et le rapport le dit au lieu de rendre un nombre.
    """
    faces, nb_sommets = souder(triangles)
    aretes = defaultdict(list)
    for indice, f in enumerate(faces):
        for a in range(3):
            cle = (f[a], f[(a + 1) % 3])
            if cle[0] > cle[1]:
                cle = (cle[1], cle[0])
            aretes[cle].append(indice)

    degres = defaultdict(int)
    for cle, lot in aretes.items():
        degres[len(lot)] += 1
    bords_libres = [c for c, lot in aretes.items() if len(lot) == 1]
    non_manifold = [c for c, lot in aretes.items() if len(lot) > 2]

    # composantes de FACES, par arete partagee
    parent = list(range(len(faces)))

    def trouver(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for lot in aretes.values():
        for autre in lot[1:]:
            ra, rb = trouver(lot[0]), trouver(autre)
            if ra != rb:
                parent[ra] = rb

    comp = defaultdict(list)
    for indice in range(len(faces)):
        comp[trouver(indice)].append(indice)

    pinces = pincements(faces)
    pince_de = {v: n for v, n in pinces}

    details = []
    for racine, lot in sorted(comp.items(), key=lambda e: -len(e[1])):
        sommets = set()
        ar = set()
        for indice in lot:
            f = faces[indice]
            sommets.update(f)
            for a in range(3):
                cle = (f[a], f[(a + 1) % 3])
                ar.add(cle if cle[0] < cle[1] else (cle[1], cle[0]))
        libres = sum(1 for c in ar if len(aretes[c]) == 1)
        nonman = sum(1 for c in ar if len(aretes[c]) > 2)
        n_pince = sum(1 for v in sommets if v in pince_de)
        # depincement : un sommet partage en k nappes vaut k sommets.
        rattrapage = sum(pince_de[v] - 1 for v in sommets if v in pince_de)
        khi = len(sommets) - len(ar) + len(lot)
        khi_deplie = khi + rattrapage
        if libres == 0 and nonman == 0 and khi_deplie % 2 == 0:
            genre = (2 - khi_deplie) // 2
        else:
            genre = None
        details.append(dict(faces=len(lot), sommets=len(sommets),
                            aretes=len(ar), bords_libres=libres,
                            non_manifold=nonman, sommets_pinces=n_pince,
                            khi=khi, khi_deplie=khi_deplie, genre=genre))

    return dict(sommets=nb_sommets, aretes=len(aretes), faces=len(faces),
                degres={str(k): v for k, v in sorted(degres.items())},
                bords_libres=len(bords_libres),
                non_manifold=len(non_manifold),
                sommets_pinces=len(pinces),
                composantes=len(comp),
                khi=nb_sommets - len(aretes) + len(faces),
                detail_composantes=details)


# ===========================================================================
# METHODE B — CLASSEMENT D'ESPACE.
# ===========================================================================

def traversees(grille, origine, direction, portee):
    """Cotes de traversee le long d'un rayon axe, et leur ORIENTATION.

    Rend une liste triee de `(t, signe)` ou `signe` vaut -1 quand le rayon
    ENTRE dans le solide (face abordee par l'avant) et +1 quand il en SORT.

    POURQUOI CETTE FONCTION PLUTOT QUE `P.impacts`
    ----------------------------------------------

    `P.impacts` fusionne deux impacts distants de moins de 0,01 m en gardant
    LE PREMIER, quelle que soit son orientation, et plafonne a 64 impacts.
    Ces deux choix sont bons pour compter une parite et mauvais ici :

      * la fusion a 0,01 m ecrase une VRAIE paroi mince de 5 mm, alors que
        cet oracle veut precisement conserver toute peau qui separe deux
        cases ;
      * le plafond a 64 tronque silencieusement le blocage au-dela, sur un
        massif de 17 m ou une colonne rasante peut compter davantage ;
      * garder le premier impact d'une paire coincidente classe a l'envers
        le cote d'un rayon qui ne fait qu'EFFLEURER une arete.

    Regle appliquee ici pour les traversees coincidentes (le rayon passe
    exactement par une arete partagee, donc deux faces repondent) : memes
    signes -> le rayon traverse vraiment, on en garde une ; signes opposes
    -> il effleure sans changer de cote, on les jette toutes les deux.
    """
    bruts = []
    tris = grille.tris
    for indice in grille.candidats(origine, direction, portee):
        r = P.croiser_triangle(origine, direction, tris[indice])
        if r is not None:
            t, nd = r
            bruts.append((t, -1 if nd < 0.0 else 1))
    if not bruts:
        return []
    bruts.sort()
    sortie = []
    i = 0
    n = len(bruts)
    while i < n:
        j = i + 1
        while j < n and bruts[j][0] - bruts[i][0] < COINCIDENCE_M:
            j += 1
        lot = bruts[i:j]
        if len(lot) == 1:
            sortie.append(lot[0])
        else:
            plus = sum(1 for _, s in lot if s > 0)
            moins = len(lot) - plus
            # effleurement : autant d'entrees que de sorties -> aucun
            # changement de cote, on ne garde rien.
            reste = plus - moins
            if reste > 0:
                sortie.append((lot[0][0], 1))
            elif reste < 0:
                sortie.append((lot[0][0], -1))
        i = j
    return sortie


class Espace(object):
    """Partition de l'espace par la SURFACE seule.

    Aucune parite, aucun vote, aucune notion de dedans : deux cases voisines
    sont reliees si le segment joignant leurs centres ne coupe rien.
    """

    def __init__(self, triangles, pas, marge=0.80, bavard=False):
        self.pas = pas
        self.bavard = bavard
        grille = P.Grille(triangles)
        lo, hi = grille.aabb()
        self.lo = [lo[k] - marge for k in range(3)]
        self.hi = [hi[k] + marge for k in range(3)]
        self.dim = [max(2, int(math.ceil((self.hi[k] - self.lo[k]) / pas)))
                    for k in range(3)]
        nx, ny, nz = self.dim
        self.n_total = nx * ny * nz
        self.bx = bytearray(self.n_total)   # (i,j,k) -> (i+1,j,k) bloquee
        self.by = bytearray(self.n_total)   # (i,j,k) -> (i,j+1,k) bloquee
        # les traversees selon z servent DEUX fois : blocage en z, et
        # decoupage de la colonne en segments. On ne balaie donc pas z deux
        # fois, on garde le resultat.
        self._balayer_z(grille)
        self._balayer_lateral(grille, axe=0, cible=self.bx)
        self._balayer_lateral(grille, axe=1, cible=self.by)

    # -- centres ----------------------------------------------------------
    def centre(self, k, axe):
        return self.lo[axe] + (k + 0.5) * self.pas

    def case_de(self, point):
        """Indice de case contenant ce point, ou None s'il est hors grille."""
        idx = []
        for k in range(3):
            i = int(math.floor((point[k] - self.lo[k]) / self.pas))
            if i < 0 or i >= self.dim[k]:
                return None
            idx.append(i)
        return tuple(idx)

    def rang(self, i, j, k):
        return (i * self.dim[1] + j) * self.dim[2] + k

    # -- balayages --------------------------------------------------------
    def _balayer_z(self, grille):
        """Un rayon montant par colonne. Donne blocage z, segments, voix."""
        nx, ny, nz = self.dim
        portee = (self.hi[2] - self.lo[2]) + 2.0
        depart_z = self.lo[2] - 0.5
        centres = [self.centre(k, 2) for k in range(nz)]
        self.segments = []                    # (i, j, k0, k1)
        self.seg_voix = []                    # (voix_air, voix_roche)
        self.seg_de_colonne = [None] * (nx * ny)
        self.rang_segment = array.array('i', bytes(4 * self.n_total))
        for i in range(nx):
            x = self.centre(i, 0)
            base_col = i * ny
            for j in range(ny):
                y = self.centre(j, 1)
                tr = traversees(grille, (x, y, depart_z), (0.0, 0.0, 1.0),
                                portee)
                zs = [depart_z + t for t, _ in tr]
                sg = [s for _, s in tr]
                # decoupage en segments : une coupure entre k et k+1 des
                # qu'une traversee tombe dans ]centre(k), centre(k+1)].
                coupures = []
                p = 0
                for k in range(nz - 1):
                    haut = centres[k + 1]
                    coupe = False
                    while p < len(zs) and zs[p] <= centres[k]:
                        p += 1
                    q = p
                    while q < len(zs) and zs[q] <= haut:
                        coupe = True
                        q += 1
                    if coupe:
                        coupures.append(k)
                liste = []
                k0 = 0
                bornes = coupures + [nz - 1]
                for k1 in bornes:
                    rid = len(self.segments)
                    self.segments.append((i, j, k0, k1))
                    self.seg_voix.append(self._voix(centres, k0, k1, zs, sg))
                    base = self.rang(i, j, 0)
                    for k in range(k0, k1 + 1):
                        self.rang_segment[base + k] = rid
                    liste.append(rid)
                    k0 = k1 + 1
                self.seg_de_colonne[base_col + j] = liste

    @staticmethod
    def _voix(centres, k0, k1, zs, sg):
        """(voix AIR, voix ROCHE) d'un segment, par ORIENTATION.

        Traversee juste SOUS le segment : signe -1 (le rayon entre dans le
        solide en montant) -> ce qui est au-dessus est de la ROCHE.
        Traversee juste AU-DESSUS : signe -1 -> ce qui est en dessous est de
        l'AIR. Lecture strictement locale, ecrite une seule fois.
        """
        air = roche = 0
        bas, haut = centres[k0], centres[k1]
        dessous = None
        dessus = None
        for z, s in zip(zs, sg):
            if z <= bas:
                dessous = s
            elif z > haut:
                dessus = s
                break
        if dessous is not None:
            if dessous < 0:
                roche += 1
            else:
                air += 1
        if dessus is not None:
            if dessus < 0:
                air += 1
            else:
                roche += 1
        return (air, roche)

    def _balayer_lateral(self, grille, axe, cible):
        """Blocage selon +X (axe 0) ou +Y (axe 1), un rayon par ligne."""
        nx, ny, nz = self.dim
        u, v = [k for k in range(3) if k != axe]
        direction = tuple(1.0 if k == axe else 0.0 for k in range(3))
        portee = (self.hi[axe] - self.lo[axe]) + 2.0
        depart = self.lo[axe] - 0.5
        centres = [self.centre(k, axe) for k in range(self.dim[axe])]
        for iu in range(self.dim[u]):
            cu = self.centre(iu, u)
            for iv in range(self.dim[v]):
                cv = self.centre(iv, v)
                o = [0.0, 0.0, 0.0]
                o[axe] = depart
                o[u] = cu
                o[v] = cv
                ts = sorted(depart + t for t, _ in
                            traversees(grille, tuple(o), direction, portee))
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
                        cible[self.rang(idx[0], idx[1], idx[2])] = 1

    # -- composantes ------------------------------------------------------
    def composantes(self, j_barriere=None):
        """Union-find sur les SEGMENTS, jamais sur les cases.

        `j_barriere` : indice de couche y dont TOUTES les adjacences vers
        `j+1` sont coupees. C'est la barriere de bouche — une surface
        d'epaisseur nulle qui couvre toute la grille, donc incontournable,
        et qui ne masque aucune adjacence x ou z.
        """
        nx, ny, nz = self.dim
        n_seg = len(self.segments)
        parent = list(range(n_seg))

        def trouver(x):
            while parent[x] != x:
                parent[x] = parent[parent[x]]
                x = parent[x]
            return x

        def unir(a, b):
            ra, rb = trouver(a), trouver(b)
            if ra != rb:
                parent[ra] = rb

        seg = self.segments
        col = self.seg_de_colonne

        def relier(colonne_a, colonne_b, masque, base_a):
            """Unit deux colonnes voisines en scrutant leurs recouvrements.

            `bytearray.find` fait le balayage en C : on ne parcourt jamais
            les quatre millions de cases en Python.
            """
            la, lb = col[colonne_a], col[colonne_b]
            ia = ib = 0
            while ia < len(la) and ib < len(lb):
                a, b = la[ia], lb[ib]
                a0, a1 = seg[a][2], seg[a][3]
                b0, b1 = seg[b][2], seg[b][3]
                lo = a0 if a0 > b0 else b0
                hi = a1 if a1 < b1 else b1
                if lo <= hi and masque.find(0, base_a + lo,
                                            base_a + hi + 1) >= 0:
                    unir(a, b)
                if a1 < b1:
                    ia += 1
                elif b1 < a1:
                    ib += 1
                else:
                    ia += 1
                    ib += 1

        for i in range(nx - 1):
            for j in range(ny):
                relier(i * ny + j, (i + 1) * ny + j, self.bx,
                       self.rang(i, j, 0))
        for i in range(nx):
            for j in range(ny - 1):
                if j == j_barriere:
                    continue
                relier(i * ny + j, i * ny + j + 1, self.by,
                       self.rang(i, j, 0))

        groupes = defaultdict(list)
        for s in range(n_seg):
            groupes[trouver(s)].append(s)
        return trouver, groupes

    # -- lecture ----------------------------------------------------------
    def tracer_vers_bord(self, seg_depart, j_barriere=None):
        """Chemin de segments du depart jusqu'a la PREMIERE case de bord.

        Le genre dit qu'une anse existe ; il ne dit jamais OU. L'inondation,
        elle, peut le dire — a condition de garder les predecesseurs. Ce
        parcours en largeur rend donc le chemin le plus COURT en nombre de
        segments, ce qui pointe la communication au lieu de la deduire.

        Parcours en largeur explicite, et non union-find : on a besoin de
        l'arbre des predecesseurs, qu'un union-find ecrase.
        """
        nx, ny, nz = self.dim
        seg = self.segments
        col = self.seg_de_colonne
        masques = (self.bx, self.by)

        def voisins(s):
            i, j, k0, k1 = seg[s]
            sortie = []
            for axe, (di, dj) in enumerate(((1, 0), (0, 1))):
                for signe in (1, -1):
                    i2, j2 = i + di * signe, j + dj * signe
                    if i2 < 0 or i2 >= nx or j2 < 0 or j2 >= ny:
                        continue
                    if axe == 1 and j_barriere is not None and \
                            min(j, j2) == j_barriere:
                        continue
                    base = self.rang(min(i, i2), min(j, j2), 0)
                    for t in col[i2 * ny + j2]:
                        lo = max(k0, seg[t][2])
                        hi = min(k1, seg[t][3])
                        if lo <= hi and masques[axe].find(
                                0, base + lo, base + hi + 1) >= 0:
                            sortie.append(t)
            return sortie

        precedent = {seg_depart: None}
        file = deque([seg_depart])
        while file:
            s = file.popleft()
            i, j, k0, k1 = seg[s]
            if i == 0 or i == nx - 1 or j == 0 or j == ny - 1 or \
                    k0 == 0 or k1 == nz - 1:
                chemin = []
                while s is not None:
                    chemin.append(s)
                    s = precedent[s]
                return list(reversed(chemin))
            for t in voisins(s):
                if t not in precedent:
                    precedent[t] = s
                    file.append(t)
        return None

    def segment_du_point(self, point):
        c = self.case_de(point)
        if c is None:
            return None
        return self.rang_segment[self.rang(*c)]

    def cases_du_groupe(self, lot):
        return sum(self.segments[s][3] - self.segments[s][2] + 1
                   for s in lot)

    def touche_bord(self, lot):
        """Cases de bord de grille atteintes par ce groupe (comptees)."""
        nx, ny, nz = self.dim
        n = 0
        exemples = []
        for s in lot:
            i, j, k0, k1 = self.segments[s]
            if i == 0 or i == nx - 1 or j == 0 or j == ny - 1:
                n += k1 - k0 + 1
                if len(exemples) < 6:
                    exemples.append((i, j, k0))
            else:
                if k0 == 0:
                    n += 1
                    if len(exemples) < 6:
                        exemples.append((i, j, 0))
                if k1 == nz - 1:
                    n += 1
                    if len(exemples) < 6:
                        exemples.append((i, j, nz - 1))
        return n, exemples

    def emprise(self, lot):
        nx, ny, nz = self.dim
        lo = [None] * 3
        hi = [None] * 3
        for s in lot:
            i, j, k0, k1 = self.segments[s]
            for axe, (a, b) in enumerate(((i, i), (j, j), (k0, k1))):
                ca, cb = self.centre(a, axe), self.centre(b, axe)
                if lo[axe] is None or ca < lo[axe]:
                    lo[axe] = ca
                if hi[axe] is None or cb > hi[axe]:
                    hi[axe] = cb
        return lo, hi

    def nature(self, lot):
        """('AIR'|'ROCHE'|'INDECIS', voix_air, voix_roche)."""
        air = roche = 0
        for s in lot:
            a, r = self.seg_voix[s]
            air += a
            roche += r
        if air > roche:
            return "AIR", air, roche
        if roche > air:
            return "ROCHE", air, roche
        return "INDECIS", air, roche


# ===========================================================================
# Lecture des reperes de gameplay.
# ===========================================================================

def racine_depot(depart):
    d = os.path.abspath(depart)
    while d != "/":
        if os.path.exists(os.path.join(d, ".git")):
            return d
        d = os.path.dirname(d)
    return os.path.abspath(depart)


def lire_reperes(racine, chemin=None):
    """`MODELE_*` du script de lieu, convertis en repere MODELE Blender.

    Godot -> Blender : `(X, Y, Z)` devient `(X, -Z, Y)`. Ecrite ICI une
    fois, jamais redérivée par branche.

    `chemin` PERMET DE NOMMER LA SOURCE, et ce n'est pas un confort.
    MESURE DU 2026-08-16 : les reperes ont ete re-derives a R2a-3.5.2. Le
    tronc porte `MODELE_SALLE (1,05 ; 0,22 ; -6,25)`, la base R2a-3.5.2
    porte `(2,62 ; 0,09 ; -2,58)` — deux points distants de plus de quatre
    metres. Mesurer une geometrie avec les reperes d'une AUTRE revision
    rend un verdict parfaitement credible sur un couple qui n'existe pas.
    C'est la meme famille que l'ISS-018 : mesurer avec assurance autre
    chose que ce qu'on croit. La source employee est donc imprimee avec son
    sha256, toujours, et jamais deduite du silence.
    """
    chemin = chemin or os.path.join(racine, SCRIPT_LIEU)
    if not os.path.isfile(chemin):
        return {}
    sortie = {}
    for ligne in open(chemin, encoding="utf-8"):
        ligne = ligne.strip()
        if not ligne.startswith("const MODELE_") or "Vector3(" not in ligne:
            continue
        nom = ligne.split("const ", 1)[1].split(":", 1)[0].strip()
        brut = ligne.split("Vector3(", 1)[1].split(")", 1)[0]
        try:
            gx, gy, gz = [float(v) for v in brut.split(",")]
        except ValueError:
            continue
        sortie[nom] = (gx, -gz, gy)
    return sortie


# ===========================================================================
# Jugement
# ===========================================================================

def juger(espace, y_bouche, graine, temoins, bavard=True, tracer=False):
    """Applique C1..C4. Rend un dictionnaire ; ne decide pas du code retour."""
    r = dict(y_bouche=y_bouche, defauts=[])

    # --- C1 / C2 : sans barriere -----------------------------------------
    _, groupes = espace.composantes(j_barriere=None)
    natures = []
    for racine, lot in sorted(groupes.items(),
                              key=lambda e: -espace.cases_du_groupe(e[1])):
        nat, va, vr = espace.nature(lot)
        cases = espace.cases_du_groupe(lot)
        lo, hi = espace.emprise(lot)
        nb_bord, _ = espace.touche_bord(lot)
        natures.append(dict(nature=nat, voix_air=va, voix_roche=vr,
                            cases=cases,
                            volume_m3=cases * espace.pas ** 3,
                            bord=nb_bord,
                            emprise_lo=[round(v, 3) for v in lo],
                            emprise_hi=[round(v, 3) for v in hi]))
    r["composantes_sans_barriere"] = natures

    ## COMPOSANTES D'UNE SEULE CASE : le plancher de resolution, pas un
    ## constat. MESURE du 2026-08-16, au pas 0,06 puis 0,04 m.
    ##
    ## Une case dont les six voisines sont toutes bloquees forme a elle
    ## seule une composante. Cela n'apprend rien sur le solide : c'est ce
    ## qui arrive des qu'une peau mince passe entre une case et chacune de
    ## ses voisines, et le compte AUGMENTE quand on affine la grille — 1
    ## sur le candidat a 0,06 m, 2 a 0,04 m, 5 sur BASE352. Un vrai corps
    ## detache, lui, ne change pas de nombre quand on affine.
    ##
    ## Les compter comme des defauts ferait rougir toute geometrie des
    ## qu'on regarde de plus pres, ce qui est le contraire d'un instrument.
    ## Ils sont donc ECARTES de C1 et C2, et PUBLIES a part.
    ##
    ## Ce n'est pas un angle mort : un corps detache reellement plus petit
    ## qu'une case reste vu par la METHODE A, qui compte les composantes de
    ## SURFACE et n'a aucune resolution. Les deux controles negatifs
    ## concernes (`poche` 0,30 m de rayon, `roche_flottante` 0,60 m de
    ## cote) sont tres au-dessus du pas et restent rouges.
    sous_resolution = [c for c in natures if c["cases"] <= 1]
    retenues = [c for c in natures if c["cases"] > 1]
    r["sous_resolution"] = len(sous_resolution)
    if sous_resolution and bavard:
        print("   dont %d composante(s) d'UNE SEULE CASE, ecartee(s) de C1/C2"
              % len(sous_resolution))
        print("      (plancher de resolution de la grille : leur nombre "
              "croit quand le pas")
        print("       diminue. La methode A, sans resolution, couvre ce "
              "cas.)")

    n_air = sum(1 for c in retenues if c["nature"] == "AIR")
    n_roche = sum(1 for c in retenues if c["nature"] == "ROCHE")
    n_indecis = sum(1 for c in retenues if c["nature"] == "INDECIS")
    r["n_air"] = n_air
    r["n_roche"] = n_roche
    r["n_indecis"] = n_indecis

    if bavard:
        print("   composantes d'espace (sans barriere) : %d" % len(natures))
        for c in natures[:8]:
            print("      %-8s %10d case(s)  %9.2f m3  bord %7d  "
                  "voix air/roche %d/%d"
                  % (c["nature"], c["cases"], c["volume_m3"], c["bord"],
                     c["voix_air"], c["voix_roche"]))
        if len(natures) > 8:
            print("      ... %d autre(s)" % (len(natures) - 8))

    if n_roche != 1:
        r["defauts"].append(
            "C1 : %d composante(s) ROCHE au lieu d'une seule "
            "-> roche flottante ou massif scinde" % n_roche)
    if n_air != 1:
        r["defauts"].append(
            "C2 : %d composante(s) AIR au lieu d'une seule "
            "-> poche d'air parasite" % n_air)
    if n_indecis:
        r["defauts"].append(
            "C1/C2 : %d composante(s) de nature INDECISE (vote a egalite)"
            % n_indecis)

    # --- C3 / C4 : avec la barriere de bouche ----------------------------
    j_bar = None
    for j in range(espace.dim[1] - 1):
        if espace.centre(j, 1) < y_bouche <= espace.centre(j + 1, 1):
            j_bar = j
            break
    if j_bar is None:
        r["bloque"] = ("plan de bouche y=%.3f hors de la grille "
                       "[%.3f .. %.3f]" % (y_bouche, espace.lo[1],
                                           espace.hi[1]))
        return r
    r["j_barriere"] = j_bar
    r["y_barriere_reelle"] = round(espace.centre(j_bar, 1) + espace.pas / 2.0,
                                   4)

    seg_graine = espace.segment_du_point(graine)
    if seg_graine is None:
        r["bloque"] = "graine interieure hors grille : %s" % (graine,)
        return r

    trouver, groupes = espace.composantes(j_barriere=j_bar)
    racine_int = trouver(seg_graine)
    lot_int = groupes[racine_int]
    nat, va, vr = espace.nature(lot_int)
    cases = espace.cases_du_groupe(lot_int)
    nb_bord, exemples = espace.touche_bord(lot_int)
    lo, hi = espace.emprise(lot_int)
    r["interieur"] = dict(nature=nat, voix_air=va, voix_roche=vr,
                          cases=cases, volume_m3=cases * espace.pas ** 3,
                          bord=nb_bord,
                          emprise_lo=[round(v, 3) for v in lo],
                          emprise_hi=[round(v, 3) for v in hi],
                          exemples_bord=[
                              [round(espace.centre(e[0], 0), 2),
                               round(espace.centre(e[1], 1), 2),
                               round(espace.centre(e[2], 2), 2)]
                              for e in exemples])

    if bavard:
        print("   barriere de bouche : couche j=%d, surface a y=%.3f "
              "(epaisseur nulle)" % (j_bar, r["y_barriere_reelle"]))
        print("   composante de la graine : %s, %d case(s) = %.2f m3, "
              "emprise x[%.2f %.2f] y[%.2f %.2f] z[%.2f %.2f]"
              % (nat, cases, cases * espace.pas ** 3, lo[0], hi[0],
                 lo[1], hi[1], lo[2], hi[2]))

    if nat != "AIR":
        r["bloque"] = ("la graine interieure tombe dans une composante %s : "
                       "une graine dans la roche rendrait ETANCHE sans rien "
                       "prouver" % nat)
        return r

    if nb_bord:
        r["defauts"].append(
            "C3 : la composante interieure atteint %d case(s) de bord de "
            "grille alors que la bouche est barree -> COMMUNICATION "
            "NON INTENTIONNELLE. Exemples (repere MODELE) : %s"
            % (nb_bord, r["interieur"]["exemples_bord"]))
        if tracer:
            chemin = espace.tracer_vers_bord(seg_graine, j_barriere=j_bar)
            if chemin:
                pts = []
                for s in chemin:
                    i, j, k0, k1 = espace.segments[s]
                    pts.append((round(espace.centre(i, 0), 3),
                                round(espace.centre(j, 1), 3),
                                round(espace.centre(k0, 2), 3),
                                round(espace.centre(k1, 2), 3)))
                r["trace_fuite"] = pts
                if bavard:
                    print()
                    print("   TRACE DE LA FUITE — chemin le plus court, en "
                          "segments, de la graine")
                    print("   jusqu'a la premiere case de bord (%d etape(s)) :"
                          % len(pts))
                    pas_aff = max(1, len(pts) // 24)
                    for n in range(0, len(pts), pas_aff):
                        x, y, zb, zh = pts[n]
                        print("      %4d : x=%7.3f  y=%7.3f  z=[%7.3f %7.3f]"
                              % (n, x, y, zb, zh))
                    x, y, zb, zh = pts[-1]
                    print("      %4d : x=%7.3f  y=%7.3f  z=[%7.3f %7.3f]  "
                          "<- BORD" % (len(pts) - 1, x, y, zb, zh))

    # --- C4, ET LA DISTINCTION QUI MANQUAIT --------------------------------
    #
    # MESURE DU 2026-08-16, et c'est la cause du `C4` reste non tranche
    # toute une passe. Un temoin peut manquer a l'appel pour DEUX raisons
    # qui n'ont rien a voir :
    #
    #   1. il est dans l'AIR, mais dans une autre composante que la graine
    #      -> le scellement ampute vraiment, ou la cavite est coupee en
    #         deux. C'est un DEFAUT de la geometrie : C4, ROUGE ;
    #   2. il est dans la ROCHE -> le repere ne decrit pas cette geometrie.
    #      Rien n'a ete ampute : le couple (maillage, reperes) est
    #      incoherent. Rendre ROUGE ici accuse la geometrie d'un defaut
    #      qu'elle n'a pas.
    #
    # L'oracle appliquait deja cette lecture a la GRAINE — « une graine dans
    # la roche rendrait ETANCHE sans rien prouver » — et ne l'appliquait pas
    # aux TEMOINS. Cette asymetrie a produit un rouge credible et faux :
    # candidat cc3596c5 juge avec les reperes du tronc a4e91dc, dont
    # MODELE_NICHE (-1,20 ; 8,20 ; 0,73) tombe dans la roche pleine. Avec
    # SES propres reperes, la meme geometrie est VERTE.
    manquants = []
    egares = []
    for nom, point in sorted(temoins.items()):
        s = espace.segment_du_point(point)
        if s is None:
            nat_t = "HORS-GRILLE"
            dedans = False
        else:
            racine_t = trouver(s)
            nat_t = espace.nature(groupes[racine_t])[0]
            dedans = racine_t == racine_int
        r.setdefault("temoins", {})[nom] = dict(
            point=[round(v, 3) for v in point], dans_interieur=bool(dedans),
            nature=nat_t)
        if bavard:
            print("      temoin %-22s (%.2f ; %.2f ; %.2f) : %-22s [%s]"
                  % (nom, point[0], point[1], point[2],
                     "DANS la cavite scellee" if dedans else "DEHORS", nat_t))
        if dedans:
            continue
        if nat_t == "AIR":
            manquants.append(nom)
        else:
            egares.append("%s (%s)" % (nom, nat_t))

    if egares:
        r["bloque"] = (
            "temoin(s) hors de l'air de cette geometrie : %s. Le repere ne "
            "decrit pas ce maillage — rien n'a ete ampute, le couple "
            "(maillage, reperes) est incoherent. Mesurer avec les reperes "
            "de LA revision qui a produit ce maillage, ou dire que la paire "
            "n'existe pas ; ne pas lire ceci comme un defaut de la "
            "geometrie." % ", ".join(egares))
        return r
    if manquants:
        r["defauts"].append(
            "C4 : temoin(s) dans l'AIR mais hors de la cavite scellee : %s "
            "-> le scellement ampute la cavite au lieu de la fermer, ou la "
            "cavite est coupee en deux" % ", ".join(manquants))
    return r


def balayer_bouche(espace, graine, y_min, y_max, bavard=True):
    """Fenetre des plans qui scellent. Diagnostic, jamais un portail.

    On ne CHOISIT pas la position de la bouche a partir de ce balayage — ce
    serait calibrer sur le sujet. On le publie pour que le lecteur voie si
    le scellement prend effet a l'avant du modele, la ou la bouche est
    censee etre, ou bien plus loin, ce qui trahirait une seconde ouverture.
    """
    seg = espace.segment_du_point(graine)
    if seg is None:
        return []
    profil = []
    for j in range(espace.dim[1] - 1):
        y = espace.centre(j, 1) + espace.pas / 2.0
        if y < y_min or y > y_max:
            continue
        trouver, groupes = espace.composantes(j_barriere=j)
        lot = groupes[trouver(seg)]
        nb_bord, _ = espace.touche_bord(lot)
        cases = espace.cases_du_groupe(lot)
        profil.append(dict(j=j, y=round(y, 3), bord=nb_bord,
                           cases=cases,
                           volume_m3=round(cases * espace.pas ** 3, 3),
                           scelle=bool(nb_bord == 0)))
        if bavard:
            print("      y=%7.3f : %-8s  composante graine %8d case(s) "
                  "= %8.2f m3   bord %d"
                  % (y, "SCELLE" if nb_bord == 0 else "OUVERT", cases,
                     cases * espace.pas ** 3, nb_bord))
    return profil


# ===========================================================================

def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("glb", nargs="?", default=None,
                    help="chemin du GLB. AUCUN chemin en dur : sans argument "
                         "l'oracle prend le GLB du depot qui le contient.")
    ap.add_argument("--noeud", default=NOEUD_DEFAUT)
    ap.add_argument("--pas", type=float, default=0.10)
    ap.add_argument("--y-bouche", type=float, default=Y_BOUCHE_DEFAUT)
    ap.add_argument("--reperes", default=None,
                    help="script de LIEU d'ou lire les MODELE_*. Par defaut "
                         "celui du depot qui contient l'oracle. A NOMMER "
                         "explicitement des qu'on mesure une geometrie "
                         "d'une autre revision que l'arbre courant.")
    ap.add_argument("--tracer", action="store_true",
                    help="en cas de fuite, publie le chemin le plus court "
                         "de la graine au bord : le genre ne localise pas, "
                         "l'inondation si")
    ap.add_argument("--balayage", action="store_true",
                    help="publie la fenetre des plans qui scellent")
    ap.add_argument("--topologie-seule", action="store_true")
    ap.add_argument("--json", default=None)
    args = ap.parse_args()

    racine = racine_depot(os.path.dirname(os.path.abspath(__file__)))
    chemin = args.glb or os.path.join(
        racine, "assets/environment/caves/SM_WaterfallCave.glb")
    if not os.path.isfile(chemin):
        print("BLOQUE : maillage introuvable : %s" % chemin)
        return 3

    sha = hashlib.sha256(open(chemin, "rb").read()).hexdigest()
    try:
        triangles, matieres = P.triangles_du_glb(chemin, args.noeud)
    except Exception as exc:                                   # noqa: BLE001
        print("BLOQUE : lecture du GLB impossible : %s" % exc)
        return 3

    print("=" * 78)
    print("ORACLE GLOBAL — topologie + classement d'espace")
    print("=" * 78)
    print("maillage : %s" % chemin)
    print("sha256   : %s" % sha)
    print("noeud    : %s   (COL_WaterfallCave, proxy de collision, "
          "n'est PAS mesure)" % args.noeud)
    print("triangles: %d   matieres : %s"
          % (len(triangles), ", ".join(sorted(matieres))))
    lo = [min(s[k] for t in triangles for s in t) for k in range(3)]
    hi = [max(s[k] for t in triangles for s in t) for k in range(3)]
    print("AABB     : x[%.3f %.3f] y[%.3f %.3f] z[%.3f %.3f]"
          % (lo[0], hi[0], lo[1], hi[1], lo[2], hi[2]))
    print()

    rapport = dict(maillage=chemin, sha256=sha, noeud=args.noeud,
                   triangles=len(triangles), pas=args.pas)

    # ---------------- METHODE A ------------------------------------------
    print("-" * 78)
    print("METHODE A — TOPOLOGIE (combinatoire pure, sans grille ni rayon)")
    print("-" * 78)
    topo = topologie(triangles)
    rapport["topologie"] = topo
    print("   sommets soudes %d   aretes %d   faces %d"
          % (topo["sommets"], topo["aretes"], topo["faces"]))
    print("   aretes par nombre de faces : %s" % topo["degres"])
    print("   bords libres %d   aretes non-manifold %d   sommets pinces %d"
          "   composantes %d"
          % (topo["bords_libres"], topo["non_manifold"],
             topo["sommets_pinces"], topo["composantes"]))
    for n, c in enumerate(topo["detail_composantes"]):
        g = "indefini" if c["genre"] is None else str(c["genre"])
        if c["khi_deplie"] != c["khi"]:
            print("      composante %d : F=%d V=%d E=%d  khi=%d, DEPINCE %d "
                  "(%d sommet(s) pince(s))  genre %s"
                  % (n, c["faces"], c["sommets"], c["aretes"], c["khi"],
                     c["khi_deplie"], c["sommets_pinces"], g))
        else:
            print("      composante %d : F=%d V=%d E=%d  khi=%d  genre %s"
                  % (n, c["faces"], c["sommets"], c["aretes"], c["khi"], g))
    if topo["sommets_pinces"]:
        print("   NOTE : %d sommet(s) PINCE(S) — deux nappes qui se touchent"
              % topo["sommets_pinces"])
        print("          en un point sans partager d'arete. Toutes les")
        print("          aretes restent a deux faces, donc aucun compteur")
        print("          d'aretes ne les voit ; chacun retire pourtant 1 a")
        print("          khi et rendrait le genre absurde. Le genre publie")
        print("          ci-dessus est celui du maillage DEPINCE, qui borne")
        print("          le meme solide.")
    if topo["non_manifold"]:
        print("   NOTE : la presence d'aretes non-manifold rend le genre")
        print("          INDEFINI. L'oracle le DIT au lieu d'imprimer un")
        print("          nombre : une surface non-manifold n'est pas une")
        print("          surface, et (2-khi)/2 n'y signifie rien.")
    if topo["bords_libres"]:
        print("   NOTE : %d bord(s) libre(s) -> le maillage est OUVERT."
              % topo["bords_libres"])
        print("          La methode B reste valide : elle ne suppose nulle")
        print("          part que le maillage soit clos.")
    defauts_topo = []
    if topo["composantes"] != 1:
        defauts_topo.append("T1 : %d composantes de surface au lieu d'une "
                            "-> corps detache" % topo["composantes"])
    if topo["bords_libres"]:
        defauts_topo.append("T2 : %d bord(s) libre(s) -> maillage ouvert"
                            % topo["bords_libres"])
    if topo["non_manifold"]:
        defauts_topo.append("T3 : %d arete(s) non-manifold"
                            % topo["non_manifold"])
    rapport["defauts_topologie"] = defauts_topo
    for d in defauts_topo:
        print("   DEFAUT %s" % d)
    print()

    if args.topologie_seule:
        if args.json:
            json.dump(rapport, open(args.json, "w"), indent=2)
        print("TOPOLOGIE SEULE : %s"
              % ("ROUGE" if defauts_topo else "VERT"))
        return 1 if defauts_topo else 0

    # ---------------- METHODE B ------------------------------------------
    source_reperes = args.reperes or os.path.join(racine, SCRIPT_LIEU)
    reperes = lire_reperes(racine, args.reperes)
    if "MODELE_SALLE" not in reperes:
        print("BLOQUE : MODELE_SALLE illisible dans %s" % source_reperes)
        return 3
    salle = reperes["MODELE_SALLE"]
    graine = (salle[0], salle[1], salle[2] + GRAINE_HAUTEUR_M)
    temoins = {}
    for nom in ("MODELE_SALLE", "MODELE_NICHE"):
        if nom in reperes:
            p = reperes[nom]
            temoins[nom] = (p[0], p[1], p[2] + TEMOIN_RELEVEMENT_M)

    print("-" * 78)
    print("METHODE B — CLASSEMENT D'ESPACE (segment centre-a-centre)")
    print("-" * 78)
    sha_rep = hashlib.sha256(
        open(source_reperes, "rb").read()).hexdigest() \
        if os.path.isfile(source_reperes) else "?"
    print("   reperes lus dans : %s" % source_reperes)
    print("   sha256 de cette source : %s" % sha_rep)
    print("   AVERTISSEMENT : une geometrie doit etre mesuree avec SES")
    print("   reperes. Les reperes ont ete re-derives a R2a-3.5.2 ; croiser")
    print("   une geometrie et les reperes d'une autre revision rend un")
    print("   verdict credible sur un couple qui n'existe pas.")
    rapport["reperes_source"] = source_reperes
    rapport["reperes_sha256"] = sha_rep
    rapport["reperes"] = {k: [round(v, 4) for v in p]
                          for k, p in sorted(reperes.items())}
    ## PROVENANCE IMPRIMEE, PAS DEDUITE. Trois passes ont bute sur cette
    ## symetrie : le GLB et le script de lieu doivent venir du MEME etat.
    ## Un desaccord ne se voit nulle part ailleurs — il produit un verdict
    ## parfaitement credible sur un couple qui n'existe pas.
    print("   valeurs lues (repere MODELE, apres conversion "
          "Godot -> Blender) :")
    for _nom, _p in sorted(reperes.items()):
        print("      %-22s (%8.3f ; %8.3f ; %8.3f)"
              % (_nom, _p[0], _p[1], _p[2]))
    print("   le GLB mesure et ce script doivent provenir du MEME etat du")
    print("   depot ; sinon le verdict porte sur un couple qui n'existe pas.")
    print("   graine interieure = MODELE_SALLE relevee de %.2f m "
          "(hauteur de torse) : (%.2f ; %.2f ; %.2f)"
          % (GRAINE_HAUTEUR_M, graine[0], graine[1], graine[2]))
    print("   temoins = repere releve de %.2f m (%s)"
          % (TEMOIN_RELEVEMENT_M, TEMOIN_RELEVEMENT_MOTIF))
    espace = Espace(triangles, args.pas)
    print("   grille %dx%dx%d = %d case(s), pas %.3f m"
          % (espace.dim[0], espace.dim[1], espace.dim[2],
             espace.n_total, args.pas))
    print("   segments (colonnes repliees) : %d" % len(espace.segments))
    rapport["grille"] = dict(dim=espace.dim, cases=espace.n_total,
                             segments=len(espace.segments))

    r = juger(espace, args.y_bouche, graine, temoins,
              tracer=args.tracer)
    rapport["jugement"] = r
    if r.get("bloque"):
        print()
        print("BLOQUE : %s" % r["bloque"])
        if args.json:
            json.dump(rapport, open(args.json, "w"), indent=2)
        return 3

    if args.balayage:
        print()
        print("   BALAYAGE (diagnostic, PAS un portail) — fenetre des plans")
        print("   qui scellent la composante de la graine :")
        seuil = reperes.get("MODELE_SEUIL_DEHORS")
        y_min = seuil[1] - 0.5 if seuil else espace.lo[1]
        rapport["balayage"] = balayer_bouche(espace, graine, y_min,
                                             graine[1])
        scellants = [p["y"] for p in rapport["balayage"] if p["scelle"]]
        if scellants:
            print("      -> plan scellant le plus AVANT : y=%.3f" %
                  min(scellants))
        else:
            print("      -> AUCUN plan ne scelle : l'ouverture est derriere "
                  "la graine, ou multiple.")

    print()
    print("=" * 78)
    defauts = defauts_topo + r["defauts"]
    if defauts:
        print("VERDICT : ROUGE")
        for d in defauts:
            print("   %s" % d)
    else:
        print("VERDICT : VERT — une composante ROCHE, une composante AIR,")
        print("          cavite scellee par la seule bouche, temoins dedans.")
        g = topo["detail_composantes"][0]["genre"]
        if g:
            print()
            print("   Corroboration croisee, et elle est le resultat le plus")
            print("   utile de cette execution : le genre vaut %d, donc %d"
                  % (g, g))
            print("   anse(s) existe(nt). L'inondation montre que la cavite")
            print("   NE communique PAS avec le dehors une fois la bouche")
            print("   barree. Une anse qui ne relie pas la cavite au dehors")
            print("   est une ARCHE de matiere, pas une percee. Les deux")
            print("   methodes se corroborent sans partager de calcul.")
    print("=" * 78)
    rapport["verdict"] = "ROUGE" if defauts else "VERT"
    rapport["defauts"] = defauts
    if args.json:
        json.dump(rapport, open(args.json, "w"), indent=2)
        print("rapport JSON : %s" % args.json)
    return 1 if defauts else 0


if __name__ == "__main__":
    sys.exit(main())
