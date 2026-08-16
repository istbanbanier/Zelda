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

## Minimum contractuel d'épaisseur, tracé sur la carte. Il n'est PAS un
## seuil de cet outil : il est là pour que l'œil situe ce qu'il regarde.
EPAISSEUR_CONTRAT_M = 0.60


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
            if not mesurable:
                mesures.append(dict(azimut=deg, premiere=None, totale=None,
                                    blocs=0))
                continue
            rad = math.radians(deg)
            # 0° = transverse « droite », 90° = vers le haut.
            dx = tx * math.cos(rad)
            dy = ty * math.cos(rad)
            dz = math.sin(rad)
            blocs = _blocs_de_roche(grille, origine, (dx, dy, dz))
            mesures.append(dict(azimut=deg,
                                premiere=(blocs[0] if blocs else 0.0),
                                totale=sum(blocs),
                                blocs=len(blocs)))
        lignes.append(dict(u=round(u, 3), ax=round(ax, 3), ay=round(ay, 3),
                           origine_z=round(origine[2], 3),
                           mesurable=bool(mesurable), mesures=mesures))
        u += pas_station
    return lignes


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


def dessiner_carte(lignes, chemin, sous_titre, plafond=4.0):
    cell_x, cell_y = 26, 22
    n_l, n_c = len(lignes), len(lignes[0]["mesures"])
    largeur = 150 + n_l * cell_x + 260
    hauteur = 110 + n_c * cell_y + 60
    img = Image.new("RGB", (largeur, hauteur), FOND)
    d = ImageDraw.Draw(img)
    d.text((24, 18), "CARTE DE CHALEUR D'EPAISSEUR - premiere paroi, en m",
           fill=ENCRE)
    d.text((24, 34), sous_titre, fill=GRIS)
    d.text((24, 52), "rouge = mince   bleu = epais   "
                     "trait noir = minimum contractuel %.2f m"
                     % EPAISSEUR_CONTRAT_M, fill=ENCRE)

    x0, y0 = 150, 100
    for i, ligne in enumerate(lignes):
        if abs(ligne["u"] - round(ligne["u"])) < 1e-6:
            d.text((x0 + i * cell_x + 3, y0 - 16), "%d" % round(ligne["u"]),
                   fill=ENCRE)
        for j, m in enumerate(ligne["mesures"]):
            couleur = _teinte(m["premiere"], 0.0, plafond)
            px, py = x0 + i * cell_x, y0 + j * cell_y
            d.rectangle([px, py, px + cell_x - 1, py + cell_y - 1],
                        fill=couleur)
            if m["premiere"] is None:
                # Station non mesurable : on hachure, on n'invente pas.
                for k in range(0, cell_x + cell_y, 5):
                    d.line([px, py + k, px + k, py], fill=(196, 196, 196))
            elif m["premiere"] < EPAISSEUR_CONTRAT_M:
                d.rectangle([px, py, px + cell_x - 1, py + cell_y - 1],
                            outline=(0, 0, 0), width=2)
                d.text((px + 2, py + 4), "%.2f" % m["premiere"],
                       fill=(255, 255, 255))
    for j, m in enumerate(lignes[0]["mesures"]):
        if m["azimut"] % 30 == 0:
            d.text((x0 - 60, y0 + j * cell_y + 5), "%3d deg" % m["azimut"],
                   fill=ENCRE)
    d.text((x0, y0 + n_c * cell_y + 10), "station u de la galerie ->",
           fill=ENCRE)
    d.text((24, y0 + n_c * cell_y + 30),
           "0 deg = transverse droite   90 deg = zenith   "
           "180 deg = transverse gauche   270 deg = nadir", fill=GRIS)
    img.save(chemin)
    return chemin


# --------------------------------------------------------------------------

def _sha_du_fichier(chemin):
    try:
        sortie = subprocess.check_output(
            ["git", "log", "-1", "--format=%H", "--", chemin],
            stderr=subprocess.DEVNULL).decode().strip()
        return sortie or "inconnu"
    except Exception:                                    # pragma: no cover
        return "inconnu"


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
    args = ap.parse_args()

    if not os.path.isdir(args.out_dir):
        os.makedirs(args.out_dir)

    tris, par_matiere = sonde.triangles_du_glb(args.glb, args.noeud)
    grille = sonde.Grille(tris)
    profil = sonde.PROFIL_GROTTE
    print("triangles : %d  ·  matieres : %d" % (len(tris), len(par_matiere)))

    crete = mesurer_crete(grille, profil)
    epaisseurs = mesurer_epaisseurs(grille, profil, args.pas_station,
                                    args.pas_azimut)
    sections = [mesurer_section(grille, profil, float(u))
                for u in args.sections.split(",")]

    sha_glb = _sha_du_fichier(args.glb)
    sous_titre = ("%s - geometrie %s - mesure du GLB LIVRE, "
                  "pas des objets Blender" % (os.path.basename(args.glb),
                                              sha_glb[:7]))

    coupe = dessiner_coupe(crete, sections, profil,
                           os.path.join(args.out_dir, "coupe_technique.png"),
                           sous_titre)
    carte = dessiner_carte(epaisseurs,
                           os.path.join(args.out_dir, "carte_epaisseur.png"),
                           sous_titre)

    minima = [(l["u"], m["azimut"], m["premiere"])
              for l in epaisseurs for m in l["mesures"]
              if m["premiere"] is not None]
    minima.sort(key=lambda e: e[2])
    ecarts = [(p["ay"], abs(p["crete_x"] - p["ax"]))
              for p in crete if p["crete_x"] is not None]
    non_mesurables = [l["u"] for l in epaisseurs if not l["mesurable"]]

    resume = dict(
        glb=args.glb, glb_commit=sha_glb, triangles=len(tris),
        epaisseur_min=dict(u=minima[0][0], azimut=minima[0][1],
                           metres=round(minima[0][2], 3)),
        sous_contrat=sum(1 for e in minima if e[2] < EPAISSEUR_CONTRAT_M),
        rayons_mesures=len(minima),
        stations_non_mesurables=non_mesurables,
        ecart_crete_axe=dict(
            min=round(min(e[1] for e in ecarts), 3),
            max=round(max(e[1] for e in ecarts), 3),
            moyen=round(sum(e[1] for e in ecarts) / len(ecarts), 3)),
        images=[coupe, carte])
    with open(os.path.join(args.out_dir, "coupe.json"), "w",
              encoding="utf-8") as poignee:
        json.dump(dict(resume=resume, crete=crete, epaisseurs=epaisseurs,
                       sections=sections), poignee, indent=1,
                  ensure_ascii=False)

    print("epaisseur minimale : %.2f m (u = %.2f, azimut %d)"
          % (minima[0][2], minima[0][0], minima[0][1]))
    print("rayons sous %.2f m : %d sur %d"
          % (EPAISSEUR_CONTRAT_M, resume["sous_contrat"], len(minima)))
    print("ecart crete/axe : min %.2f  moyen %.2f  max %.2f m"
          % (resume["ecart_crete_axe"]["min"],
             resume["ecart_crete_axe"]["moyen"],
             resume["ecart_crete_axe"]["max"]))
    print("images : %s , %s" % (coupe, carte))
    # Aucun verdict : cet outil DESSINE, il ne juge pas.
    return 0


if __name__ == "__main__":
    sys.exit(main())
