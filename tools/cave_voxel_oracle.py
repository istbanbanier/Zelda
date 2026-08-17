#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ORACLE VOXEL — étanchéité et volume jouable, SANS le profil analytique.

POURQUOI CET INSTRUMENT EXISTE
==============================

La revue exige que le verdict d'étanchéité soit corroboré par **deux
méthodes ne partageant pas le même calcul central**, et qu'aucune fonction
commune de placement ne puisse les aveugler ensemble. L'exigence n'est pas
théorique : `points_interieurs()` alimentait à elle seule le contrôle 2, le
contrôle 1 et la carte du plancher, et quand elle plaçait ses points le
long de l'axe monde X sur une galerie infléchie, les trois se trompaient
ensemble, dans le même sens, avec des chiffres qui se confirmaient
mutuellement.

CE QUE CET ORACLE N'EMPLOIE PAS, ET C'EST LA MOITIÉ DE SON INTÉRÊT
==================================================================

Il n'appelle ni `points_interieurs`, ni `offsets_lateraux`, ni
`dans_enveloppe`, ni `dans_le_noyau`, ni `_emprise_noyau`, ni
`sort_par_la_bouche`, ni `Profil.normale`, ni `Profil.demi_largeur`, ni
`Profil.sol`. Il n'a besoin d'AUCUNE de ces notions, parce qu'il ne place
pas de points : il **classe l'espace**.

Ce qu'il partage avec la sonde se réduit au lecteur de GLB et au lancer de
rayon (`Grille`, `impacts`). C'est un partage réel et il est nommé ici
plutôt que tu : si l'intersection rayon-triangle était fausse, les deux
méthodes seraient fausses ensemble. C'est pourquoi cette brique-là est
éprouvée séparément, sur une géométrie de réponse connue, par
`tools/probe_cave_selftest.py`, et non par elle-même.

CE QU'IL A DÉJÀ TROUVÉ, ET QUE LE PROFIL NE POUVAIT PAS VOIR
============================================================

`CAVITE` déclare un axe qui s'arrête à `y = +3,17`. Le vide du maillage,
lui, court jusqu'à `y ≈ +8,25`. Toute mesure ancrée sur `CAVITE` est donc
aveugle à plus de la moitié de la longueur de la galerie — et c'est là que
se trouvent la salle et la niche de récompense déclarées par
`waterfall_cave_place.gd`. Un oracle qui ne lit que le maillage n'a pas
cette limite.

MÉTHODE
=======

  1. COLONNES. Pour chaque colonne `(x, y)` de la grille, un seul rayon
     vertical rend tous ses impacts. Les intervalles entre impacts pairs
     donnent le vide de la colonne. Un rayon par colonne au lieu de six par
     voxel : c'est ce qui rend un pas de 10 cm abordable en Python pur.

  2. ÉTANCHÉITÉ PAR INONDATION. On bloque le plan de la bouche, puis on
     inonde le vide depuis un coin du dehors. Tout voxel creux situé
     DERRIÈRE le plan de bouche et néanmoins atteint a été atteint sans
     passer par la bouche : c'est la définition géométrique d'une fuite,
     et elle ne demande ni normale, ni demi-largeur, ni station.

  3. VOLUME JOUABLE. Un voxel est PRATICABLE si la capsule canonique du
     joueur y tient — rayon et hauteur lus dans `scenes/player/Player.tscn`
     — et si de la matière le porte. On inonde ensuite ces voxels depuis le
     seuil : ce qui n'est pas connexe au seuil n'est pas jouable, si
     accueillant soit-il.

Usage :
    python3 tools/cave_voxel_oracle.py [glb] [--pas 0.10] [--json sortie.json]

Codes de sortie : 0 = aucune fuite et volume jouable atteint la récompense
· 1 = fuite ou récompense hors d'atteinte · 3 = BLOQUÉ.
"""

import argparse
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import probe_cave_openings as P                                # noqa: E402


## LA CAPSULE CANONIQUE, lue dans `scenes/player/Player.tscn`.
## Le `CollisionShape3D` du joueur porte `radius = 0.35`, `height = 1.8`.
## Recopiées ici et VÉRIFIÉES à l'exécution contre la scène : une capsule
## recopiée qui dérive mesurerait un couloir imaginaire.
CAPSULE_RAYON_M = 0.35
CAPSULE_HAUTEUR_M = 1.80
SCENE_JOUEUR = "scenes/player/Player.tscn"

## Portée d'interaction, lue dans `scripts/player/player_controller.gd`
## (`const INTERACT_RANGE: float = 2.2`). Même règle de vérification.
INTERACT_RANGE_M = 2.20
SCRIPT_JOUEUR = "scripts/player/player_controller.gd"

## Repères de gameplay, en repère GODOT, lus dans le script de lieu.
## Conversion vers le repère MODÈLE BLENDER : x_bl = X, y_bl = -Z, z_bl = Y.
SCRIPT_LIEU = "scripts/world_v2/poi/waterfall_cave_place.gd"

## Plan de la bouche, en y modèle. Au-delà (vers -Y) c'est le dehors ; la
## galerie est derrière. C'est la SEULE cote empruntée au profil déclaré,
## et elle ne sert qu'à savoir par où l'on a le droit d'entrer.
Y_BOUCHE = -1.15


def godot_vers_modele(v):
    """(X, Y, Z) Godot -> (x, y, z) modèle Blender."""
    return (v[0], -v[2], v[1])


# ---------------------------------------------------------------------------
# Lecture des constantes RÉELLES, plutôt que confiance aux copies.
# ---------------------------------------------------------------------------

def lire_capsule(racine):
    """Rayon et hauteur du CollisionShape3D du joueur, ou None."""
    chemin = os.path.join(racine, SCENE_JOUEUR)
    if not os.path.isfile(chemin):
        return None
    rayon = hauteur = None
    for ligne in open(chemin, encoding="utf-8"):
        ligne = ligne.strip()
        if ligne.startswith("radius = ") and rayon is None:
            rayon = float(ligne.split("=", 1)[1])
        elif ligne.startswith("height = ") and hauteur is None:
            hauteur = float(ligne.split("=", 1)[1])
        if rayon is not None and hauteur is not None:
            break
    return (rayon, hauteur) if rayon and hauteur else None


def lire_portee(racine):
    chemin = os.path.join(racine, SCRIPT_JOUEUR)
    if not os.path.isfile(chemin):
        return None
    for ligne in open(chemin, encoding="utf-8"):
        if "INTERACT_RANGE" in ligne and "=" in ligne and "const" in ligne:
            return float(ligne.split("=", 1)[1].strip())
    return None


def lire_reperes(racine):
    """`MODELE_*` du script de lieu, en repère MODÈLE."""
    chemin = os.path.join(racine, SCRIPT_LIEU)
    sortie = {}
    if not os.path.isfile(chemin):
        return sortie
    for ligne in open(chemin, encoding="utf-8"):
        ligne = ligne.strip()
        if not ligne.startswith("const MODELE_"):
            continue
        nom = ligne.split(":", 1)[0].replace("const", "").strip()
        if "Vector3(" not in ligne:
            continue
        brut = ligne.split("Vector3(", 1)[1].split(")", 1)[0]
        try:
            v = [float(x) for x in brut.split(",")]
        except ValueError:
            continue
        if len(v) == 3:
            sortie[nom] = godot_vers_modele(v)
    return sortie


# ---------------------------------------------------------------------------
# 1. LA GRILLE DE VOXELS, par colonnes
# ---------------------------------------------------------------------------

class Voxels(object):
    """Occupation du volume, `True` = vide.

    L'axe rapide est z, parce que c'est lui qu'un rayon de colonne remplit
    d'un coup.
    """

    def __init__(self, grille, pas, marge=0.60):
        lo, hi = grille.aabb()
        self.pas = pas
        self.origine = tuple(lo[k] - marge for k in range(3))
        self.dim = tuple(int(math.ceil((hi[k] - lo[k] + 2.0 * marge) / pas)) + 1
                         for k in range(3))
        nx, ny, nz = self.dim
        self.vide = bytearray(nx * ny * nz)
        base_z = self.origine[2] - 1.0
        portee = (hi[2] - lo[2]) + 2.0 * marge + 4.0
        for i in range(nx):
            x = self.origine[0] + i * pas
            for j in range(ny):
                y = self.origine[1] + j * pas
                liste = P.impacts(grille, (x, y, base_z), (0.0, 0.0, 1.0),
                                  portee)
                # PARITÉ LE LONG DE LA COLONNE. Hors de la matière au
                # départ (on part sous l'emprise), le vide est l'union des
                # intervalles [t_pair, t_impair].
                zs = [base_z + t for t, _ in liste]
                debut = 0
                k = 0
                bornes = zs + [1e9]
                while k < nz:
                    z = self.origine[2] + k * pas
                    # nombre d'impacts strictement sous z
                    while debut < len(bornes) and bornes[debut] <= z:
                        debut += 1
                    if debut % 2 == 0:
                        self.vide[(i * ny + j) * nz + k] = 1
                    k += 1

    def index(self, i, j, k):
        return (i * self.dim[1] + j) * self.dim[2] + k

    def cellule(self, point):
        return tuple(int(round((point[k] - self.origine[k]) / self.pas))
                     for k in range(3))

    def centre(self, i, j, k):
        return (self.origine[0] + i * self.pas,
                self.origine[1] + j * self.pas,
                self.origine[2] + k * self.pas)

    def dedans(self, i, j, k):
        return (0 <= i < self.dim[0] and 0 <= j < self.dim[1]
                and 0 <= k < self.dim[2])

    def est_vide(self, i, j, k):
        return self.dedans(i, j, k) and self.vide[self.index(i, j, k)] == 1


def inonder(vox, graines, passable):
    """Inondation 6-connexe. `passable(i, j, k)` décide de la propagation."""
    nx, ny, nz = vox.dim
    vu = bytearray(nx * ny * nz)
    pile = []
    for g in graines:
        if passable(*g):
            idx = vox.index(*g)
            if not vu[idx]:
                vu[idx] = 1
                pile.append(g)
    while pile:
        i, j, k = pile.pop()
        for di, dj, dk in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0),
                           (0, 0, 1), (0, 0, -1)):
            a, b, c = i + di, j + dj, k + dk
            if not vox.dedans(a, b, c):
                continue
            idx = vox.index(a, b, c)
            if vu[idx] or not passable(a, b, c):
                continue
            vu[idx] = 1
            pile.append((a, b, c))
    return vu


# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(
        description="Oracle voxel : etancheite par inondation et volume "
                    "jouable, sans profil analytique.")
    ap.add_argument("glb", nargs="?",
                    default="assets/environment/caves/SM_WaterfallCave.glb")
    ap.add_argument("--racine", default=".")
    ap.add_argument("--pas", type=float, default=0.10)
    ap.add_argument("--json", default=None)
    args = ap.parse_args()

    print("=" * 78)
    print("ORACLE VOXEL — inondation du vide, sans profil analytique")
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

    # -- LES CONSTANTES, LUES ET NON SUPPOSEES --------------------------
    capsule = lire_capsule(args.racine)
    portee = lire_portee(args.racine)
    reperes = lire_reperes(args.racine)
    ecarts = []
    if capsule is None:
        ecarts.append("capsule illisible dans %s" % SCENE_JOUEUR)
    elif abs(capsule[0] - CAPSULE_RAYON_M) > 1e-6 \
            or abs(capsule[1] - CAPSULE_HAUTEUR_M) > 1e-6:
        ecarts.append("capsule %s dans la scene, %s recopiee ici"
                      % (capsule, (CAPSULE_RAYON_M, CAPSULE_HAUTEUR_M)))
    if portee is None:
        ecarts.append("INTERACT_RANGE illisible dans %s" % SCRIPT_JOUEUR)
    elif abs(portee - INTERACT_RANGE_M) > 1e-6:
        ecarts.append("INTERACT_RANGE %.2f dans le script, %.2f recopiee ici"
                      % (portee, INTERACT_RANGE_M))
    if ecarts:
        # UNE COPIE QUI A DERIVE MESURE UN AUTRE JEU. C'est BLOQUE, pas un
        # avertissement : le meme choix que `controle_coherence_cotes`.
        for e in ecarts:
            print("BLOQUE: %s" % e)
        return 3
    rayon, hauteur = capsule
    print("capsule joueur : rayon %.2f m, hauteur %.2f m  (lue dans %s)"
          % (rayon, hauteur, SCENE_JOUEUR))
    print("portee d'interaction : %.2f m  (lue dans %s)"
          % (portee, SCRIPT_JOUEUR))
    for nom in sorted(reperes):
        print("   %-22s modele (%+.2f ; %+.2f ; %+.2f)"
              % (nom, reperes[nom][0], reperes[nom][1], reperes[nom][2]))

    print()
    print("voxelisation au pas %.2f m ..." % args.pas)
    vox = Voxels(grille, args.pas)
    nx, ny, nz = vox.dim
    creux = sum(vox.vide)
    print("   grille %d x %d x %d = %d voxel(s), dont %d creux (%.1f %%)"
          % (nx, ny, nz, nx * ny * nz, creux,
             100.0 * creux / float(nx * ny * nz)))

    # -- 2. ETANCHEITE PAR INONDATION ------------------------------------
    print()
    print("-" * 78)
    print("A. ETANCHEITE — inondation depuis le DEHORS, bouche condamnee")
    print("-" * 78)
    print("Le plan de bouche (y = %+.2f) est rendu infranchissable. Tout" % Y_BOUCHE)
    print("voxel creux situe DERRIERE ce plan et neanmoins atteint depuis le")
    print("dehors l'a ete SANS passer par la bouche : c'est une fuite, au sens")
    print("geometrique, sans qu'aucune normale ni demi-largeur n'intervienne.")
    j_bouche = int(round((Y_BOUCHE - vox.origine[1]) / vox.pas))

    # L'OUVERTURE EST UNE SURFACE, PAS UN DEMI-ESPACE — ET J'AI COMMENCE PAR
    # L'INVERSE.
    #
    # Premiere version : l'inondation exterieure interdisait `j >= j_bouche`.
    # Elle ne pouvait donc PAS contourner le rocher, et n'atteignait ni ses
    # flancs, ni son dos, ni son toit. Elle rendait « 0 fuite » — un
    # acquittement obtenu en ne regardant que la facade, exactement le mode
    # d'echec que cet oracle est cense fermer. Mesure qui l'a trahi : la
    # composante ainsi trouvee faisait 3 567 m3, soit tout le ciel, pour une
    # galerie de quelques dizaines de metres cubes.
    #
    # La bouche correcte est l'APERTURE : dans la tranche `y = Y_BOUCHE`, les
    # cases creuses qui ne touchent PAS le bord de la tranche. L'air libre
    # autour du rocher touche le bord ; le trou de la bouche, non. On bloque
    # cette aperture-la, et rien d'autre — le dehors reste libre de faire le
    # tour.
    aperture = set()
    bord = []
    for i in range(nx):
        for k in (0, nz - 1):
            bord.append((i, k))
    for k in range(nz):
        for i in (0, nx - 1):
            bord.append((i, k))
    libre = set()
    pile = [c for c in bord if vox.est_vide(c[0], j_bouche, c[1])]
    libre.update(pile)
    while pile:
        i, k = pile.pop()
        for di, dk in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            a, c = i + di, k + dk
            if 0 <= a < nx and 0 <= c < nz and (a, c) not in libre \
                    and vox.est_vide(a, j_bouche, c):
                libre.add((a, c))
                pile.append((a, c))
    for i in range(nx):
        for k in range(nz):
            if vox.est_vide(i, j_bouche, k) and (i, k) not in libre:
                aperture.add((i, k))
    print("aperture ENCLOSE dans la tranche de bouche : %d case(s), %.2f m2"
          % (len(aperture), len(aperture) * args.pas * args.pas))
    print("   la tranche ENTIERE est neanmoins condamnee : voir `passable`,")
    print("   le porche evase communique lateralement avec l'air libre.")

    # LA TRANCHE ENTIERE EST CONDAMNEE, ET LA RAISON EST MESUREE.
    #
    # Ne bloquer que l'aperture « enclose » ne suffit pas : le porche est
    # evase et son sol PLONGE SOUS LE TERRAIN (`PORCHE_DENIVELE = -0,58`,
    # commentaire du generateur : « porche evase, sol sous le terrain »).
    # Le creux de la bouche communique donc lateralement avec l'air libre
    # DANS LA TRANCHE, il n'y est pas enclos, et il echappait au blocage :
    # l'inondation ressortait par la porte d'entree et rendait 4 614 m3 de
    # « galerie », c'est-a-dire le ciel.
    #
    # Condamner la tranche entiere n'a pas ce defaut. Partant de
    # l'INTERIEUR, une galerie etanche ne franchit jamais cette tranche, et
    # une fuite ailleurs la fait sortir. L'angle mort qui subsiste est
    # nomme : une fuite situee exactement dans les %.2f m de la tranche
    # serait masquee.
    def passable(i, j, k):
        if j == j_bouche:
            return False
        return vox.est_vide(i, j, k)

    # LA GRAINE EST UN REPERE DE GAMEPLAY, pas une station du profil : c'est
    # ce qui garde cet oracle independant de `CAVITE`.
    salle = reperes.get("MODELE_SALLE")
    if salle is None:
        print("BLOQUE: MODELE_SALLE introuvable dans %s" % SCRIPT_LIEU)
        return 3
    graine_int = vox.cellule(salle)
    if not vox.est_vide(*graine_int):
        print("BLOQUE: MODELE_SALLE n'est pas dans le vide du maillage.")
        return 3
    interieur = inonder(vox, [graine_int], passable)
    cells_int = [(i, j, k) for i in range(nx) for j in range(ny)
                 for k in range(nz) if interieur[vox.index(i, j, k)]]
    volume = len(cells_int) * args.pas ** 3
    print("composante interieure depuis MODELE_SALLE, bouche condamnee : "
          "%d voxel(s) = %.1f m3" % (len(cells_int), volume))

    # LA FUITE SE LIT SUR LE BORD DE LA GRILLE. Si l'interieur, bouche
    # fermee, atteint le bord de l'emprise, il communique avec le dehors par
    # autre chose que la bouche. Aucune normale, aucune station, aucune
    # demi-largeur n'intervient dans cette phrase.
    fuites = [c for c in cells_int
              if c[0] in (0, nx - 1) or c[1] in (0, ny - 1)
              or c[2] in (0, nz - 1)]
    print("%d voxel(s) de la composante interieure touchent le bord de "
          "l'emprise" % len(fuites))
    if fuites:
        amas = {}
        for i, j, k in fuites:
            amas.setdefault((i // 5, j // 5, k // 5), []).append((i, j, k))
        print("   %d amas ; les plus gros :" % len(amas))
        for cle, lot in sorted(amas.items(), key=lambda kv: -len(kv[1]))[:8]:
            c = vox.centre(*lot[0])
            print("      %4d voxel(s) autour de modele (%+.2f ; %+.2f ; %+.2f)"
                  % (len(lot), c[0], c[1], c[2]))
        print("   >>> FUITE — surface equivalente >= %.3f m2"
              % (len(fuites) * args.pas * args.pas))
    else:
        print("   PASS — bouche condamnee, l'interieur ne rejoint pas le "
              "dehors : le seul chemin est la bouche")
    if volume > 500.0:
        # UN GARDE-FOU CONTRE MOI-MEME, ET IL SORT EN BLOQUE.
        #
        # Une « galerie » de plusieurs centaines de metres cubes signifie que
        # l'inondation s'est echappee ; le compte de fuites qui suit ne
        # mesure alors plus la grotte mais le ciel. Rendre FAIL serait aussi
        # trompeur que rendre PASS : dans les deux cas on publierait un
        # verdict tire d'un instrument qui n'a pas fonctionne.
        #
        # `.claude/rules/evidence.md` : une etape impossible sort en 3, pas
        # en 0 — et pas davantage en 1 deguise en mesure.
        print()
        print("BLOQUE: la composante dite interieure fait %.0f m3. Une galerie"
              % volume)
        print("        de cette taille n'existe pas : l'inondation a fui hors")
        print("        de l'emprise et le compte de fuites ne mesure rien.")
        print("        Cause connue a instruire : le porche evase plonge sous")
        print("        le terrain, et la tranche de bouche ne suffit pas a")
        print("        separer l'interieur du dehors. L'ETANCHEITE PAR")
        print("        INONDATION EST DONC `NON VERIFIEE` sur ce maillage,")
        print("        et ne doit PAS etre citee comme corroboration.")
        return 3

    # -- 3. VOLUME JOUABLE ------------------------------------------------
    print()
    print("-" * 78)
    print("B. VOLUME JOUABLE — ou la capsule canonique tient ET est connexe")
    print("-" * 78)
    # LA CLARTE VERTICALE EST PRECALCULEE PAR COLONNE, sinon le test de
    # capsule coute `disque x hauteur` a CHAQUE voxel visite et l'oracle ne
    # tourne plus a un pas utile. `montee[i][j][k]` = nombre de voxels
    # creux consecutifs vers le haut a partir de (i, j, k).
    r_vox = int(math.ceil(rayon / args.pas))
    h_vox = int(math.ceil(hauteur / args.pas))
    # HAUTEUR DE MARCHE — le joueur franchit une marche, il ne vole pas.
    # `player_controller.gd` la fixe entre 0,30 et 0,38 m ; on prend 0,35.
    marche_vox = max(1, int(round(0.35 / args.pas)))
    print("capsule : %d voxel(s) de rayon, %d de hauteur ; marche %d voxel(s)"
          % (r_vox, h_vox, marche_vox))

    montee = bytearray(nx * ny * nz)
    for i in range(nx):
        for j in range(ny):
            compte = 0
            base = (i * ny + j) * nz
            for k in range(nz - 1, -1, -1):
                compte = compte + 1 if vox.vide[base + k] else 0
                montee[base + k] = min(compte, 255)

    disque = [(di, dj) for di in range(-r_vox, r_vox + 1)
              for dj in range(-r_vox, r_vox + 1)
              if math.hypot(di, dj) * args.pas <= rayon + 1e-9]

    def capsule_tient(i, j, k):
        """Le cylindre englobant de la capsule est-il entierement creux ?

        Le cylindre MAJORE la capsule : ce qui passe ici passe a coup sur,
        ce qui bloque ici pourrait passer de justesse. Le biais est donc
        PESSIMISTE et assume — un oracle de jouabilite qui se trompe doit
        se tromper en refusant, jamais en promettant un passage.
        """
        for di, dj in disque:
            a, b = i + di, j + dj
            if not (0 <= a < nx and 0 <= b < ny):
                return False
            if montee[(a * ny + b) * nz + k] < h_vox:
                return False
        return True

    # CANDIDATS : voxels creux POSES sur de la matiere. Les enumerer d'abord
    # ramene le test de capsule de 5 millions d'appels a quelques dizaines
    # de milliers.
    candidats = set()
    for i in range(nx):
        for j in range(ny):
            base = (i * ny + j) * nz
            for k in range(1, nz):
                if vox.vide[base + k] and not vox.vide[base + k - 1]:
                    if capsule_tient(i, j, k):
                        candidats.add((i, j, k))
    print("%d voxel(s) porteurs ou la capsule tient (avant connexite)"
          % len(candidats))

    # LA GRAINE EST INTERIEURE. Partir de `MODELE_SEUIL_DEHORS` — qui est
    # DEHORS, son nom le dit — donnait 147 voxels arretes a y = -1,19 : le
    # volume jouable du PARVIS, pas celui de la galerie. Un chiffre precis
    # qui repondait a une autre question.
    gi, gj, gk = vox.cellule(salle)
    graine = min((c for c in candidats),
                 key=lambda c: (c[0] - gi) ** 2 + (c[1] - gj) ** 2
                 + (c[2] - gk) ** 2, default=None)
    if graine is None:
        print("BLOQUE: aucun voxel praticable — la capsule ne tient nulle part.")
        return 3
    print("graine praticable : modele (%+.2f ; %+.2f ; %+.2f)"
          % vox.centre(*graine))

    # CONNEXITE AVEC MARCHE. Le joueur passe d'une case a sa voisine si le
    # denivele ne depasse pas la hauteur de marche. Une inondation 6-connexe
    # stricte couperait la galerie a chaque ressaut du sol et rendrait un
    # volume jouable faussement minuscule.
    par_colonne = {}
    for i, j, k in candidats:
        par_colonne.setdefault((i, j), []).append(k)
    vus = {graine}
    pile = [graine]
    while pile:
        i, j, k = pile.pop()
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1),
                       (1, 1), (1, -1), (-1, 1), (-1, -1)):
            for k2 in par_colonne.get((i + di, j + dj), ()):
                if abs(k2 - k) > marche_vox:
                    continue
                c = (i + di, j + dj, k2)
                if c not in vus:
                    vus.add(c)
                    pile.append(c)
    cellules = sorted(vus)
    empreinte = set((i, j) for i, j, _ in cellules)
    print("%d voxel(s) jouables et connexes a la salle, soit %.2f m2 de sol"
          % (len(cellules), len(empreinte) * args.pas * args.pas))
    if not cellules:
        print("BLOQUE: volume jouable vide.")
        return 3
    ys = [vox.centre(*c)[1] for c in cellules]
    print("   emprise le long de y : %+.2f .. %+.2f m" % (min(ys), max(ys)))
    print("   LIMITE JOUABLE (y le plus profond ou la capsule tient) : %+.2f m"
          % max(ys))

    # -- 4. LA RECOMPENSE EST-ELLE ATTEIGNABLE ? -------------------------
    print()
    print("-" * 78)
    print("C. LA RECOMPENSE, A LA PORTEE D'INTERACTION REELLE")
    print("-" * 78)
    niche = reperes.get("MODELE_NICHE")
    resultat_niche = None
    if niche is None:
        print("BLOQUE: MODELE_NICHE introuvable dans %s" % SCRIPT_LIEU)
        return 3
    print("niche declaree : modele (%+.2f ; %+.2f ; %+.2f)" % niche)
    # La portee se mesure depuis la TETE du joueur autant que depuis ses
    # pieds ; on prend le point le plus favorable de la capsule, ce qui est
    # le seul choix qui ne fabrique pas un faux blocage.
    meilleur = None
    for c in cellules:
        px, py, pz = vox.centre(*c)
        for dz in (0.0, hauteur * 0.5, hauteur - rayon):
            d = math.sqrt((px - niche[0]) ** 2 + (py - niche[1]) ** 2
                          + (pz + dz - niche[2]) ** 2)
            if meilleur is None or d < meilleur[0]:
                meilleur = (d, (px, py, pz), dz)
    distance, pied, dz = meilleur
    print("point jouable le plus proche : modele (%+.2f ; %+.2f ; %+.2f), "
          "a %+.2f m de haut" % (pied[0], pied[1], pied[2], dz))
    print("distance a la niche : %.3f m   (portee d'interaction %.2f m)"
          % (distance, portee))
    atteignable = distance <= portee + 1e-9
    print("   %s" % ("PASS — la recompense est a portee depuis le volume "
                     "jouable" if atteignable else
                     ">>> HORS D'ATTEINTE de %.3f m — la recompense ne peut "
                     "pas etre ramassee" % (distance - portee)))
    resultat_niche = dict(niche_modele=[round(c, 3) for c in niche],
                          distance_m=round(distance, 4),
                          portee_m=portee,
                          atteignable=atteignable,
                          point_jouable=[round(c, 3) for c in pied])

    # -- VERDICT ----------------------------------------------------------
    print()
    print("=" * 78)
    print("VERDICT DE L'ORACLE VOXEL")
    print("=" * 78)
    print("fuites (voxels)          : %d" % len(fuites))
    print("volume jouable (voxels)  : %d" % len(cellules))
    print("limite jouable en y      : %+.2f m" % max(ys))
    print("recompense a portee      : %s" % ("oui" if atteignable else "NON"))
    echoue = bool(fuites) or not atteignable
    print("VERDICT : %s" % ("FAIL" if echoue else "PASS"))
    print("=" * 78)

    if args.json:
        dossier = os.path.dirname(args.json)
        if dossier and not os.path.isdir(dossier):
            os.makedirs(dossier)
        with open(args.json, "w", encoding="utf-8") as poignee:
            json.dump(dict(
                glb=args.glb, pas_m=args.pas, triangles=len(tris),
                capsule=dict(rayon_m=rayon, hauteur_m=hauteur),
                portee_interaction_m=portee,
                reperes={k: [round(c, 3) for c in v]
                         for k, v in reperes.items()},
                fuites_voxels=len(fuites),
                fuites_surface_equivalente_m2=round(
                    len(fuites) * args.pas * args.pas, 4),
                volume_jouable_voxels=len(cellules),
                limite_jouable_y_m=round(max(ys), 3),
                emprise_jouable_y_m=[round(min(ys), 3), round(max(ys), 3)],
                recompense=resultat_niche,
                verdict="FAIL" if echoue else "PASS"),
                poignee, indent=1, sort_keys=True, ensure_ascii=False)
        print("sortie brute : %s" % args.json)
    return 1 if echoue else 0


if __name__ == "__main__":
    sys.exit(main())
