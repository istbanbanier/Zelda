#!/usr/bin/env python3
"""PRÉ-CONTRÔLE D'OCCLUSION — itération 12 de la source (`valley.poi.turquoise_spring.01`).

POURQUOI CE FICHIER EXISTE. Les itérations 10 et 11 ont échoué sur la même
famille d'erreur : vérifier le geste qu'on CROYAIT avoir fait, jamais celui que
le fichier porte — et simuler un déplacement par PEINTURE de masques, alors
qu'une silhouette est une UNION (reculer une pièce découvre ce qui était
derrière). Ce contrôle fait l'inverse, AVANT toute géométrie :

  1. il relève par grep les positions RÉELLES portées par les deux fichiers
     source (l'état iter11 dont on part), et les positions PRÉVUES (iter12) ;
  2. il reconstruit la surface exacte des quatre masses (port pur-Python du
     champ `Bloc` de make_spring_maw.py, validé au millimètre contre le log
     Blender committé `voie_a/pipeline/voie_a_spring_maw_make.log`) ;
  3. il pose chaque pièce sur le SOL MESURÉ (grille de la fonction de terrain
     gelée, sondée sous moteur : `sol_iter12.log`, RC 0) ;
  4. il calcule, par bande de hauteur de 25 cm, l'UNION des intervalles X
     (projection 90°) et Z (projection 0°) occupés par CHAQUE pièce — masses,
     lobes du rebord, couronne, dalles de kit, nappes d'eau — et prouve que :
       * le corridor en X prévu est VIDE sur toute la bande où il doit se
         lire (au-dessus de 0,30 m), couronne et lobes compris ;
       * le vide doit exister sur les DEUX axes : au 0°, un vide central
         au-dessus de la couronne, et deux respirations latérales sous elle.

AXES, tranchés sur la source de capture_silhouette.gd (iter11) : à 0° la
caméra est en +X, base droite (0,0,−1) → le masque 0° résout Z ; le masque
90° résout X. Un profil qui doit se lire aux deux angles existe sur les deux
axes.

Usage :
    python3 controle_occlusion_iter12.py            # preuve avant géométrie
    python3 controle_occlusion_iter12.py --verifie-fichiers
        # APRÈS l'édition des fichiers, AVANT tout export : vérifie que les
        # fichiers portent exactement les mètres prévus ici.

Sortie 0 = PASS ; 1 = FAIL. Aucune valeur rendue n'est prédite ici : ce
contrôle ne parle que de GÉOMÉTRIE (occupation de colonnes), pas de pixels.
"""

import argparse
import math
import random
import re
import sys
from pathlib import Path

ICI = Path(__file__).resolve().parent
RACINE = ICI.parents[5]
PLACE_GD = RACINE / "scripts/world_v2/poi/turquoise_spring_place.gd"
MAW_PY = RACINE / "source_assets/blender/environment/make_spring_maw.py"
SOL_LOG = ICI / "sol_iter12.log"

# ---------------------------------------------------------------------------
# LE PLAN ITER12 — l'arbitrage du lead : séparer réellement les masses en X,
# de l'ordre de 2,5 à 4 m entre faces en regard. Le geste retenu :
#   * les mâchoires et la couronne restent le groupe OUEST (la fente),
#     amincies en X (demi_a — la profondeur vue depuis la caméra joueur,
#     invisible pour elle) et écartées en Z (l'anneau grandit autour de
#     l'œil : z −3,4 → −5,0 et +4,2 → +6,1) ;
#   * les lobes nord et sud du rebord deviennent les FLANCS EST de la
#     couronne : ils passent de x −7,6/−8,2 (collés au groupe ouest) à
#     x −3,1 — de l'autre côté du corridor — et montent (rim H 1,70 → 3,00) ;
#   * l'écrin du fruit et l'ancre de récompense ne bougent pas ; la logique
#     de l'eau (vasque, langue, tête d'affluent) ne bouge pas.
# ---------------------------------------------------------------------------

# nom -> (H, demi_a, demi_b, jupe, graine, pente, lobes[(bx, by, échelle)])
MASSES_ITER12 = {
    "SM_Spring_MawN": (3.80, 1.50, 2.05, 0.45, 90311, (0.055, -0.085),
                       [(0.0, 0.0, 1.0)]),
    "SM_Spring_MawS": (3.60, 1.30, 2.00, 0.45, 40277, (0.040, 0.095),
                       [(0.0, 0.0, 1.0)]),
    "SM_Spring_Crown": (1.90, 1.65, 1.62, 0.45, 71553, (-0.070, 0.020),
                        [(0.0, 0.0, 1.0)]),
    "SM_Spring_Rim": (3.00, 1.95, 1.60, 0.50, 26489, (0.030, 0.030),
                      [(2.45, 5.3, 0.92), (3.9, -3.7, 0.30),
                       (2.45, -6.0, 0.80)]),
}
RESOLUTION = {"SM_Spring_MawN": (22, 18, 3), "SM_Spring_MawS": (22, 18, 3),
              "SM_Spring_Crown": (20, 16, 3), "SM_Spring_Rim": (18, 13, 3)}

# nom -> (x, z, yaw_deg, enfoncement, recentrer)
POSITIONS_ITER11 = {
    "SM_Spring_MawN": (-9.9, -3.4, 18.0, 0.22, True),
    "SM_Spring_MawS": (-10.1, 4.2, -24.0, 0.22, True),
    "SM_Spring_Crown": (-11.0, 0.3, 40.0, 0.35, True),
    "SM_Spring_Rim": (-5.4, 0.2, 0.0, 0.30, False),
}
POSITIONS_ITER12 = {
    "SM_Spring_MawN": (-9.9, -5.2, 18.0, 0.22, True),
    "SM_Spring_MawS": (-10.1, 6.1, -24.0, 0.22, True),
    "SM_Spring_Crown": (-10.6, 0.85, 40.0, 0.35, True),
    "SM_Spring_Rim": (-5.4, 0.2, 0.0, 0.30, False),
}
LOBES_ITER11 = [(-2.2, 3.6, 0.92), (3.9, -3.7, 0.46), (-2.8, -4.2, 0.80)]

# Dalles de kit (inchangées) : (x, z, demi-largeur boîte, hauteur).
DALLES = [(-1.2, -3.4, 0.91, 0.12), (0.6, -4.4, 0.71, 0.15),
          (1.6, -5.0, 0.91, 0.12)]

# Le corridor prévu, et la bande de hauteur où il doit se lire.
Y_BAS_CORRIDOR = 0.30          # sous cette hauteur : nappe, lit, jupes
CORRIDOR_MIN = 2.5             # l'arbitrage : 2,5 à 4 m entre faces en regard
BANDE = 0.25


# --- Port du champ Bloc (mêmes tirages, mêmes lois que make_spring_maw.py) --
def _da(a, b):
    return (a - b + math.pi) % math.tau - math.pi


class Bloc:
    T_MAX = 0.92

    def __init__(self, h, da, db, jupe, graine, pente):
        self.H = h
        self.demi_a = da
        self.demi_b = db
        self.t_jupe = -jupe / h
        self.pente = pente
        rng = random.Random(graine)
        self.dome_q = rng.uniform(3.2, 4.6)
        self.dome_e = rng.uniform(0.16, 0.26)
        self.harmoniques = [(o, a, rng.uniform(0.0, math.tau))
                            for o, a in ((2, 0.205), (3, 0.145), (5, 0.084),
                                         (7, 0.046))]
        self.fentes = [(rng.uniform(0.0, math.tau), rng.uniform(0.26, 0.38),
                        rng.uniform(0.085, 0.155)) for _ in range(2)]
        self.bosses = []
        for _ in range(2):
            self.bosses.append((rng.uniform(0.0, math.tau),
                                rng.uniform(0.30, 0.66),
                                rng.uniform(0.40, 0.80),
                                rng.uniform(0.10, 0.18),
                                -rng.uniform(0.12, 0.20)))
        for _ in range(2):
            self.bosses.append((rng.uniform(0.0, math.tau),
                                rng.uniform(0.34, 0.70),
                                rng.uniform(0.45, 0.90),
                                rng.uniform(0.11, 0.17),
                                rng.uniform(0.13, 0.20)))
        for _ in range(3):
            self.bosses.append((rng.uniform(0.0, math.tau),
                                rng.uniform(0.0, 0.13),
                                rng.uniform(0.70, 1.20),
                                rng.uniform(0.16, 0.24),
                                rng.uniform(0.18, 0.30)))
        self.haut_azimut = rng.uniform(0.0, math.tau)
        self.encoche = self.haut_azimut + rng.uniform(1.9, 4.4)

    def nervure(self, th):
        v = sum(a * math.sin(o * th + p) for o, a, p in self.harmoniques)
        for c, prof, larg in self.fentes:
            d = abs(_da(th, c))
            if d < larg:
                v -= prof * (0.5 + 0.5 * math.cos(math.pi * d / larg))
        return v

    def bosse(self, th, t):
        v = 0.0
        for bth, bt, sth, stt, amp in self.bosses:
            e = (_da(th, bth) / sth) ** 2 + ((t - bt) / stt) ** 2
            if e < 9.0:
                v += amp * math.exp(-e)
        return v

    def dome(self, t):
        if t >= 0.0:
            u = min(1.0, max(0.0, t))
            return max(0.02, (1.0 - u ** self.dome_q) ** self.dome_e)
        u = min(1.0, t / self.t_jupe)
        return 1.0 + 0.32 * u * (2.0 - u)

    def couronne(self, th):
        base = 0.150 * (1.0 - math.exp(-(abs(_da(th, self.haut_azimut))
                                         / 0.70) ** 2))
        return base + 0.110 * math.exp(-(abs(_da(th, self.encoche))
                                         / 0.30) ** 2)

    def point(self, th, t):
        r = self.dome(t) * (1.0 + self.nervure(th)) * (1.0 + self.bosse(th, t))
        z = t * self.H
        return (math.cos(th) * self.demi_a * r + self.pente[0] * max(0.0, z),
                math.sin(th) * self.demi_b * r + self.pente[1] * max(0.0, z),
                z)


def sommets(nom, params):
    h, da, db, jupe, graine, pente, lobes = params
    bloc = Bloc(h, da, db, jupe, graine, pente)
    na, nt, nj = RESOLUTION[nom]
    thetas = [math.tau * j / na for j in range(na)]
    ts = [bloc.t_jupe * (1.0 - k / float(nj)) for k in range(nj)]
    ts += [bloc.T_MAX * k / float(nt - 1) for k in range(nt)]
    verts = []
    for dx, dy, ech in lobes:
        anneaux = []
        for t in ts:
            ligne = []
            for th in thetas:
                p = bloc.point(th, t)
                pz = p[2]
                if t > 0.0:
                    poids = max(0.0, (t - 0.55) / 0.45)
                    pz -= bloc.couronne(th) * bloc.H * poids * poids
                ligne.append((p[0] * ech + dx, p[1] * ech + dy, pz * ech))
            anneaux.append(ligne)
        dernier = anneaux[-1]
        cx = sum(v[0] for v in dernier) / na
        cy = sum(v[1] for v in dernier) / na
        hauts = [v[2] for v, th in zip(dernier, thetas)
                 if abs(_da(th, bloc.haut_azimut)) < 0.7]
        z_haut = (sum(hauts) / len(hauts)) if hauts else \
            sum(v[2] for v in dernier) / na
        apex = (cx + math.cos(bloc.haut_azimut) * bloc.demi_a * ech * 0.26,
                cy + math.sin(bloc.haut_azimut) * bloc.demi_b * ech * 0.26,
                z_haut + 0.030 * bloc.H * ech)
        for f in (0.34, 0.68):
            anneaux.append([(v[0] + (apex[0] - v[0]) * f,
                             v[1] + (apex[1] - v[1]) * f,
                             v[2] + (apex[2] - v[2]) * f) for v in dernier])
        anneaux.append([apex])
        z_fond = min(v[2] for v in anneaux[0])
        for fac in (0.76, 0.52, 0.28, 0.0):
            anneaux.append([(dx + (v[0] - dx) * fac, dy + (v[1] - dy) * fac,
                             z_fond) for v in anneaux[0]])
        for ligne in anneaux:
            verts.extend(ligne)
    return verts


# --- Sol mesuré (grille sondée sous moteur, pad du site à 12,0) -------------
def charge_sol():
    xs, zs, rows = None, [], []
    for ligne in SOL_LOG.read_text(encoding="utf-8").splitlines():
        if "z\\x" in ligne:
            xs = [-154.0 + 1.5 * k for k in range(len(ligne.split()) - 1)]
            continue
        if xs is None:
            continue
        parts = ligne.replace("~", " ").split()
        if len(parts) == len(xs) + 1:
            try:
                vals = [float(p) for p in parts]
            except ValueError:
                continue
            zs.append(22.0 + 1.5 * len(rows))
            rows.append(vals[1:])
    return xs, zs, rows


_XS, _ZS, _ROWS = None, None, None


def sol(x, z):
    global _XS, _ZS, _ROWS
    if _XS is None:
        _XS, _ZS, _ROWS = charge_sol()
    wx = min(max(-136.0 + x, _XS[0]), _XS[-1] - 1e-6)
    wz = min(max(40.0 + z, _ZS[0]), _ZS[-1] - 1e-6)
    i = min(int((wx - _XS[0]) / 1.5), len(_XS) - 2)
    j = min(int((wz - _ZS[0]) / 1.5), len(_ZS) - 2)
    t = (wx - _XS[i]) / 1.5
    u = (wz - _ZS[j]) / 1.5
    v = (_ROWS[j][i] * (1 - t) + _ROWS[j][i + 1] * t) * (1 - u) \
        + (_ROWS[j + 1][i] * (1 - t) + _ROWS[j + 1][i + 1] * t) * u
    return v - 12.0


def poser(nom, params, pose):
    """Sommets monde-local du lieu, posés comme `_masse()` : Blender→Godot
    (X,Y,Z)=(bx,bz,−by), yaw autour de Y, recentrage sur la boîte tournée
    conservatrice (celle de Godot), y = sol − enfoncement."""
    x, z, yaw_deg, enf, recentrer = pose
    verts_b = sommets(nom, params)
    verts_g = [(v[0], v[2], -v[1]) for v in verts_b]
    yaw = math.radians(yaw_deg)
    c, s = math.cos(yaw), math.sin(yaw)

    def rot(v):
        return (c * v[0] + s * v[2], v[1], -s * v[0] + c * v[2])

    xs = [v[0] for v in verts_g]
    ys = [v[1] for v in verts_g]
    zs = [v[2] for v in verts_g]
    coins = [rot((a, b, d)) for a in (min(xs), max(xs))
             for b in (min(ys), max(ys)) for d in (min(zs), max(zs))]
    dx, dz = x, z
    if recentrer:
        dx = x - (min(cc[0] for cc in coins) + max(cc[0] for cc in coins)) / 2
        dz = z - (min(cc[2] for cc in coins) + max(cc[2] for cc in coins)) / 2
    y0 = sol(x, z) - enf
    return [(rv[0] + dx, rv[1] + y0, rv[2] + dz)
            for rv in (rot(v) for v in verts_g)]


# --- Relevé par grep des fichiers source ------------------------------------
def releve_fichiers():
    gd = PLACE_GD.read_text(encoding="utf-8")
    py = MAW_PY.read_text(encoding="utf-8")
    poses = {}
    for m in re.finditer(
            r'_masse\(&"(SM_Spring_\w+)",\s*"[^"]+",\s*'
            r'(-?[\d.]+),\s*(-?[\d.]+),\s*(-?[\d.]+),', gd):
        poses[m.group(1)] = (float(m.group(2)), float(m.group(3)),
                             float(m.group(4)))
    bx = re.search(r"const BASSIN_X: float = (-?[\d.]+)", gd)
    bz = re.search(r"const BASSIN_Z: float = (-?[\d.]+)", gd)
    if "SM_Spring_Rim" not in poses and bx and bz:
        poses["SM_Spring_Rim"] = (float(bx.group(1)), float(bz.group(1)), 0.0)
    dims = {}
    for m in re.finditer(
            r'\("(SM_Spring_\w+)",\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),', py):
        dims[m.group(1)] = (float(m.group(2)), float(m.group(3)),
                            float(m.group(4)))
    lobes_rim = None
    m = re.search(r'"SM_Spring_Rim".*?\[(.*?)\]\),\n\]', py, re.S)
    if m:
        lobes_rim = re.findall(r'\((-?[\d.]+),\s*(-?[\d.]+),\s*([\d.]+)\)',
                               m.group(1))
    return poses, dims, lobes_rim


def bandes_intervalles(pieces, y_max):
    """pieces : nom -> sommets. Rend {bande_y: {nom: (x0,x1,z0,z1)}}."""
    table = {}
    y = -0.8
    while y < y_max:
        ligne = {}
        for nom, pts in pieces.items():
            sel = [p for p in pts if y <= p[1] < y + BANDE]
            if sel:
                ligne[nom] = (min(p[0] for p in sel), max(p[0] for p in sel),
                              min(p[2] for p in sel), max(p[2] for p in sel))
        if ligne:
            table[round(y, 2)] = ligne
        y += BANDE
    return table


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--verifie-fichiers", action="store_true")
    args = ap.parse_args()

    poses, dims, lobes_rim = releve_fichiers()
    print("=== 1. CE QUE LES FICHIERS PORTENT (grep, pas mémoire) ===")
    for nom in MASSES_ITER12:
        p = poses.get(nom)
        d = dims.get(nom)
        print("  %-16s place.gd (x;z;yaw) = %s   make.py (H;demi_a;demi_b) = %s"
              % (nom, p, d))
    print("  lobes du rebord (make.py, Blender) : %s" % lobes_rim)

    if args.verifie_fichiers:
        print("\n=== 2. LES FICHIERS PORTENT-ILS LE PLAN ITER12 ? ===")
        ecarts = []
        for nom, cible in POSITIONS_ITER12.items():
            p = poses.get(nom)
            if p is None or abs(p[0] - cible[0]) > 1e-6 \
                    or abs(p[1] - cible[1]) > 1e-6:
                ecarts.append("%s : place.gd porte %s, plan (%.1f ; %.1f)"
                              % (nom, p, cible[0], cible[1]))
        for nom, cible in MASSES_ITER12.items():
            d = dims.get(nom)
            if d is None or abs(d[0] - cible[0]) > 1e-6 \
                    or abs(d[1] - cible[1]) > 1e-6 \
                    or abs(d[2] - cible[2]) > 1e-6:
                ecarts.append("%s : make.py porte %s, plan (%.2f ; %.2f ; %.2f)"
                              % (nom, d, cible[0], cible[1], cible[2]))
        cible_lobes = [tuple(map(float, l)) for l in
                       [(str(a), str(b), str(c))
                        for a, b, c in MASSES_ITER12["SM_Spring_Rim"][6]]]
        lus = [tuple(float(v) for v in l) for l in (lobes_rim or [])]
        if lus != [tuple(l) for l in cible_lobes]:
            ecarts.append("lobes du rebord : lus %s, plan %s"
                          % (lus, cible_lobes))
        if ecarts:
            print("  FAIL — le geste écrit n'est pas le geste prévu :")
            for e in ecarts:
                print("   * " + e)
            return 1
        print("  PASS — chaque mètre du plan est dans les fichiers.")
        return 0

    print("\n=== 2. LE PLAN ITER12 (mètres, pas intentions) ===")
    for nom, cible in POSITIONS_ITER12.items():
        av = POSITIONS_ITER11[nom]
        print("  %-16s (%.1f ; %.1f) -> (%.1f ; %.1f)"
              % (nom, av[0], av[1], cible[0], cible[1]))
    print("  lobes du rebord (Blender) : %s -> %s"
          % (LOBES_ITER11, MASSES_ITER12["SM_Spring_Rim"][6]))

    pieces = {}
    for nom, params in MASSES_ITER12.items():
        pieces[nom] = poser(nom, params, POSITIONS_ITER12[nom])
    for k, (dx, dz, demi, haut) in enumerate(DALLES):
        y0 = sol(dx, dz) - 0.05
        pieces["dalle_%d" % k] = [(dx + sx * demi, y0 + sy * haut,
                                   dz + sz * demi)
                                  for sx in (-1, 1) for sy in (0, 1)
                                  for sz in (-1, 1)]

    y_max = max(p[1] for pts in pieces.values() for p in pts)
    table = bandes_intervalles(pieces, y_max)

    ouest = ("SM_Spring_MawN", "SM_Spring_MawS", "SM_Spring_Crown")
    # Faces en regard du corridor, au-dessus de la bande basse.
    x_ouest = max(p[0] for n in ouest for p in pieces[n]
                  if p[1] >= Y_BAS_CORRIDOR)
    x_est = min(p[0] for p in pieces["SM_Spring_Rim"]
                if p[1] >= Y_BAS_CORRIDOR)
    corridor = (x_ouest, x_est)
    print("\n=== 3. CORRIDOR EN X (masque 90°) ===")
    print("  face est du groupe ouest  : x = %.2f" % x_ouest)
    print("  face ouest des flancs est : x = %.2f" % x_est)
    print("  corridor : %.2f m (arbitrage : %.1f à 4 m)"
          % (x_est - x_ouest, CORRIDOR_MIN))
    echec = False
    if x_est - x_ouest < CORRIDOR_MIN:
        print("  FAIL — corridor sous l'arbitrage")
        echec = True

    print("\n  Occupation des colonnes du corridor [%.2f ; %.2f], par bande :"
          % corridor)
    for y in sorted(table):
        intrus = []
        for nom, (x0, x1, _, _) in table[y].items():
            if x0 < corridor[1] and x1 > corridor[0]:
                intrus.append("%s [%.2f;%.2f]" % (nom, x0, x1))
        marque = "vide" if not intrus else "OCCUPÉ par " + ", ".join(intrus)
        regle = y + 1e-9 >= Y_BAS_CORRIDOR
        if intrus and regle:
            echec = True
            marque += "  <== FAIL (bande où le corridor doit se lire)"
        elif intrus:
            marque += "  (bande basse : nappe/lit/jupes, admise)"
        print("   y %+5.2f..%+5.2f : %s" % (y, y + BANDE, marque))
    print("  NB : la nappe (plan à +0,08), le lit (+0,03) et la langue qui")
    print("  épouse le sol restent sous %.2f m : ils traversent le corridor" %
          Y_BAS_CORRIDOR)
    print("  dans la bande basse, ce qui est le déversoir lui-même — voulu.")

    print("\n=== 4. LES DEUX VIDES DU MASQUE 0° (axe Z) ===")
    # Au-dessus de la couronne : le centre doit être vide entre les deux tours.
    top_couronne = max(p[1] for p in pieces["SM_Spring_Crown"])
    z_tour_n = max(p[2] for n in ("SM_Spring_MawN",) for p in pieces[n]
                   if p[1] >= top_couronne)
    z_tour_s = min(p[2] for n in ("SM_Spring_MawS",) for p in pieces[n]
                   if p[1] >= top_couronne)
    print("  sommet de la couronne : y = %.2f" % top_couronne)
    print("  au-dessus : tour nord jusqu'à z %.2f, tour sud depuis z %.2f "
          "-> vide central %.2f m" % (z_tour_n, z_tour_s, z_tour_s - z_tour_n))
    if z_tour_s - z_tour_n < 4.0:
        print("  FAIL — vide central < 4 m au-dessus de la couronne")
        echec = True
    # Sous la couronne : deux respirations latérales N–C et C–S.
    respi_nc, respi_cs = 99.0, 99.0
    for y in sorted(table):
        if y + 1e-9 < Y_BAS_CORRIDOR or y >= top_couronne - BANDE:
            continue
        zN = table[y].get("SM_Spring_MawN")
        zC = table[y].get("SM_Spring_Crown")
        zS = table[y].get("SM_Spring_MawS")
        if zN and zC:
            respi_nc = min(respi_nc, zC[2] - zN[3])
        if zC and zS:
            respi_cs = min(respi_cs, zS[2] - zC[3])
    print("  sous la couronne : respiration nord–couronne ≥ %.2f m, "
          "couronne–sud ≥ %.2f m" % (respi_nc, respi_cs))
    if respi_nc < 0.5 or respi_cs < 0.5:
        print("  FAIL — une respiration latérale < 0,5 m : le 0° redevient "
              "un bloc")
        echec = True

    print("\n=== 5. GARDES DE FICTION (rien d'autre ne bouge) ===")
    ancre = (-2.4, 2.6)
    marge_ancre = min(math.hypot(p[0] - ancre[0], p[2] - ancre[1])
                      for p in pieces["SM_Spring_Rim"]
                      if p[1] >= 0.1 and p[0] < -2.6)
    print("  flancs vs ancre du fruit (gelée, (−2,4 ; 2,6)) : %.2f m"
          % marge_ancre)
    if marge_ancre < 0.40:
        print("  FAIL — un flanc mord la berge de la récompense")
        echec = True
    fil = (0.803, -0.596)
    marge_langue = 99.0
    for k in range(21):
        t = k / 20.0
        lx = -5.4 + fil[0] * (3.40 + 4.25 * t)
        lz = 0.2 + fil[1] * (3.40 + 4.25 * t)
        demi = (1.55 * (1 - t) + 0.60 * t) * 0.5
        for p in pieces["SM_Spring_Rim"]:
            if p[1] < 0.0:
                continue
            marge_langue = min(marge_langue,
                               math.hypot(p[0] - lx, p[2] - lz) - demi)
    print("  flancs vs langue du déversoir (inchangée) : %.2f m" % marge_langue)
    if marge_langue < 0.15:
        print("  FAIL — un flanc pince la langue")
        echec = True
    tete = (6.0, -6.0)
    # Le contrat du lot protège la bande de l'affluent des COLLIDERS ; les
    # dalles de kit (inchangées) n'en portent pas. Colliders prévus : les
    # deux mâchoires et les deux flancs.
    colliders = [("machoire_nord", -9.9, -5.2), ("machoire_sud", -10.1, 6.1),
                 ("flanc_nord", -3.1, -5.1), ("flanc_sud", -3.1, 6.2)]
    for nom, cx2, cz2 in colliders:
        d = math.hypot(cx2 - tete[0], cz2 - tete[1])
        if d < 5.0 + 2.0:
            print("  FAIL — collider %s à %.1f m de la tête d'affluent"
                  % (nom, d))
            echec = True
    print("  tous les colliders prévus ≥ 7 m de la tête d'affluent : vérifié")
    bouche_x = -5.4 - 4.27 - 1.60      # rivage ouest maxi + bosse de bouche
    jaws_ouest = min(p[0] for n in ouest for p in pieces[n])
    print("  la bouche ouest (x ≈ %.1f) reste SOUS le groupe des mâchoires "
          "(x min %.2f) : %s" % (bouche_x, jaws_ouest,
                                 "vérifié" if jaws_ouest < bouche_x else
                                 "FAIL"))
    if jaws_ouest >= bouche_x:
        echec = True

    print("\nVERDICT PRÉ-CONTRÔLE : %s" % ("FAIL" if echec else "PASS"))
    return 1 if echec else 0


if __name__ == "__main__":
    sys.exit(main())
