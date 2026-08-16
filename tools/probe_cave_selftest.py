#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ÉPREUVE DE LA SONDE DE GROTTE — une géométrie dont la pose est CONNUE.

POURQUOI CE FICHIER EXISTE.

`tools/probe_cave_openings.py` mesure une grotte dont personne ne connaît la
réponse. C'est le propre d'un instrument, et c'est aussi son danger : rien,
dans son exécution, ne distingue « la géométrie est saine » de « la sonde ne
voit rien ». La revue R2a-3.5 a retenu ce défaut sous sa forme la plus
précise — la transformation monde → modèle du contrôle 3 était `NON VÉRIFIÉ`,
et la tentative de la valider en superposant une silhouette à une capture a
ÉCHOUÉ : 52,4 % de concordance, et décaler l'origine de +3 m améliorait le
score. Quand bouger la mauvaise réponse améliore la note, ce n'est pas
l'origine qui est disqualifiée, c'est la mesure.

La réparation n'est pas de mieux superposer. C'est de **fabriquer une
géométrie dont on connaît exactement la pose et exactement les trous**, puis
d'exiger que la sonde les retrouve. Une réponse connue est la seule chose
qu'aucune image ne pouvait fournir.

CE QUE CE FICHIER ÉPROUVE, ET DANS QUEL ORDRE.

  1. TRANSFORMATION — la chaîne de matrices reproduit-elle l'axe de bouche
     que `waterfall_cave_place.gd` DÉCLARE lui-même (sud-est, 0,707 ; 0,707) ?
     L'aller-retour tient-il sa tolérance ? Et surtout : rougit-il quand on
     casse la transformation exprès ?
  2. DISCRIMINATION — sur six tunnels synthétiques identiques à un trou
     près, la sonde rend-elle des verdicts DIFFÉRENTS ? Un contrôle rouge
     partout est câblé sur l'échec ; un contrôle vert partout ne mesure
     rien. Les deux sont des tests qui ne peuvent pas échouer.
  3. LOCALISATION — le trou est-il retrouvé sur la BONNE FACE, au BON
     endroit, avec la BONNE ouverture ?
  4. SEUIL — un trou de 4 cm est-il vu comme suspect et REFUSÉ à la
     confirmation, tandis qu'un trou de 60 cm est confirmé ? Sans cette
     paire, « percée confirmée » n'est qu'un mot.
  5. LIGNE DE VUE — une caméra posée en MONDE, visant un tunnel dont la
     pose est connue, fait-elle apparaître le trou dans la boîte de pixels
     PRÉDITE indépendamment ? C'est l'épreuve de bout en bout de la
     transformation, avec vérité de terrain.

Rien ici ne touche à la géométrie de production. Les tunnels sont écrits
dans un dossier temporaire et effacés.

Usage :
    python3 tools/probe_cave_selftest.py [--garder <dossier>]

Codes de sortie : 0 = toutes les épreuves passent · 1 = au moins une échoue
· 3 = BLOQUÉ.
"""

import argparse
import json
import math
import os
import shutil
import struct
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import probe_cave_openings as P                                # noqa: E402


# ---------------------------------------------------------------------------
# Le tunnel d'épreuve. Cotes rondes, choisies pour que toute erreur se lise.
# Repère MODÈLE BLENDER : galerie vers +Y, bouche vers -Y, sol à z = 0.
# ---------------------------------------------------------------------------

Y_BOUCHE = -1.15
Y_FOND = 9.25
DEMI_LARGEUR = 1.50
CLE = 2.50
EPAISSEUR = 0.80

## Profil analytique du tunnel synthétique. Droit, sans palier ni cuvette :
## toute déviation observée vient donc de la sonde, jamais du profil.
PROFIL_TUNNEL = P.Profil(
    cavite=[(0.0, Y_BOUCHE + (Y_FOND - Y_BOUCHE) * i / 8.0, DEMI_LARGEUR, CLE)
            for i in range(9)],
    palier=tuple([0.0] * 9), sag=0.0, porche_denivele=0.0, asym=1.0,
    nom="tunnel_synthetique")


def _quad(sommets, trou=None):
    """Un quad plan, éventuellement percé, en triangles.

    `sommets` est donné dans l'ordre direct vu depuis la normale sortante.
    `trou` est une BOÎTE MÉTRIQUE 3D `(min, max)` : le quad la projette dans
    son propre paramétrage et se perce si elle le traverse.

    LE TROU EST MÉTRIQUE, ET C'EST LE POINT. Décrire un trou en paramètres
    de face percerait la face intérieure et la face extérieure à des
    endroits DIFFÉRENTS — elles n'ont pas la même étendue — et le « trou »
    ne traverserait rien. La boîte traverse l'épaisseur, donc les deux faces
    qu'elle croise sont percées au même endroit, et la percée est réelle.
    """
    a, b, c, d = sommets
    vec_u = tuple(b[k] - a[k] for k in range(3))
    vec_v = tuple(d[k] - a[k] for k in range(3))

    def _point(u, v):
        return tuple(a[k] + vec_u[k] * u + vec_v[k] * v for k in range(3))

    bornes = None
    if trou is not None:
        mini, maxi = trou
        nu = sum(x * x for x in vec_u)
        nv = sum(x * x for x in vec_v)
        us, vs = [], []
        for cx in (mini[0], maxi[0]):
            for cy in (mini[1], maxi[1]):
                for cz in (mini[2], maxi[2]):
                    r = (cx - a[0], cy - a[1], cz - a[2])
                    us.append(sum(r[k] * vec_u[k] for k in range(3)) / nu)
                    vs.append(sum(r[k] * vec_v[k] for k in range(3)) / nv)
        u0, u1, v0, v1 = min(us), max(us), min(vs), max(vs)
        # Le quad n'est percé que si la boîte TRAVERSE son plan et si son
        # emprise est strictement intérieure. Un trou au bord ouvrirait une
        # fente le long d'une arête, ce qui n'est pas le défaut à fabriquer.
        normale = (vec_u[1] * vec_v[2] - vec_u[2] * vec_v[1],
                   vec_u[2] * vec_v[0] - vec_u[0] * vec_v[2],
                   vec_u[0] * vec_v[1] - vec_u[1] * vec_v[0])
        axe = max(range(3), key=lambda k: abs(normale[k]))
        if mini[axe] < a[axe] < maxi[axe] \
                and 0.0 < u0 and u1 < 1.0 and 0.0 < v0 and v1 < 1.0:
            bornes = (u0, u1, v0, v1)

    if bornes is None:
        return [(a, b, c), (a, c, d)]
    u0, u1, v0, v1 = bornes
    bandes = [(0.0, 1.0, 0.0, v0), (0.0, 1.0, v1, 1.0),
              (0.0, u0, v0, v1), (u1, 1.0, v0, v1)]
    tris = []
    for pu0, pu1, pv0, pv1 in bandes:
        if pu1 - pu0 < 1e-9 or pv1 - pv0 < 1e-9:
            continue
        p0, p1 = _point(pu0, pv0), _point(pu1, pv0)
        p2, p3 = _point(pu1, pv1), _point(pu0, pv1)
        tris += [(p0, p1, p2), (p0, p2, p3)]
    return tris


def boite_du_trou(face, centre, cote):
    """Boîte métrique d'un trou carré de `cote` mètres sur une face nommée.

    `centre` est donné dans les deux coordonnées qui varient sur la face ;
    la troisième traverse l'épaisseur de la coque, du vide de la galerie
    jusqu'au-delà de la surface extérieure.
    """
    demi = cote / 2.0
    marge = EPAISSEUR + 0.50
    a, b = centre
    if face == "toit":
        return ((a - demi, b - demi, CLE - marge),
                (a + demi, b + demi, CLE + marge))
    if face == "plancher":
        return ((a - demi, b - demi, -marge), (a + demi, b + demi, marge))
    if face == "fond":
        return ((a - demi, Y_FOND - marge, b - demi),
                (a + demi, Y_FOND + marge, b + demi))
    if face == "paroi_plus_x":
        return ((DEMI_LARGEUR - marge, a - demi, b - demi),
                (DEMI_LARGEUR + marge, a + demi, b + demi))
    return ((-DEMI_LARGEUR - marge, a - demi, b - demi),
            (-DEMI_LARGEUR + marge, a + demi, b + demi))


def centre_du_trou(face, centre):
    """Centre MÉTRIQUE du trou sur la face INTÉRIEURE — vérité de terrain."""
    a, b = centre
    if face == "toit":
        return (a, b, CLE)
    if face == "plancher":
        return (a, b, 0.0)
    if face == "fond":
        return (a, Y_FOND, b)
    if face == "paroi_plus_x":
        return (DEMI_LARGEUR, a, b)
    return (-DEMI_LARGEUR, a, b)


def tunnel(trou=None):
    """Coque fermée d'un tunnel rectangulaire, percée ou non.

    `trou` est une boîte métrique `(min, max)` traversant l'épaisseur : elle
    perce la face intérieure ET la face extérieure qu'elle croise, si bien
    que le trou joint réellement la galerie au dehors. Un trou percé d'un
    seul côté ne serait pas un trou.
    """
    hx, hy = DEMI_LARGEUR, CLE
    ox, oz0, oz1 = hx + EPAISSEUR, -EPAISSEUR, hy + EPAISSEUR
    oy = Y_FOND + EPAISSEUR
    t = trou
    tris = []
    # --- surfaces EXTÉRIEURES, normale vers le dehors ---------------------
    tris += _quad([(ox, Y_BOUCHE, oz0), (ox, oy, oz0), (ox, oy, oz1),
                   (ox, Y_BOUCHE, oz1)], t)
    tris += _quad([(-ox, Y_BOUCHE, oz0), (-ox, Y_BOUCHE, oz1), (-ox, oy, oz1),
                   (-ox, oy, oz0)], t)
    tris += _quad([(-ox, oy, oz0), (-ox, oy, oz1), (ox, oy, oz1),
                   (ox, oy, oz0)], t)
    tris += _quad([(-ox, Y_BOUCHE, oz1), (ox, Y_BOUCHE, oz1), (ox, oy, oz1),
                   (-ox, oy, oz1)], t)
    tris += _quad([(-ox, Y_BOUCHE, oz0), (-ox, oy, oz0), (ox, oy, oz0),
                   (ox, Y_BOUCHE, oz0)], t)
    # --- l'anneau de la bouche, en quatre bandes --------------------------
    #
    # ORDRE DES SOMMETS : l'anneau regarde -Y, comme le reste de la face
    # avant. Le premier jet l'avait enroule a l'envers, et l'EPREUVE 3 l'a
    # pris : 19 272 pixels percants au lieu d'une centaine, soit exactement
    # 60 % de la formation — la part de la face avant occupee par l'anneau.
    # Une coque dont l'anneau regarde le dedans est invisible sur une
    # capture fixe et evidente pour un test de face avant. C'est le genre de
    # faute que la superposition de silhouette d'hier ne pouvait pas voir.
    for bande in ((-ox, -hx, oz0, oz1), (hx, ox, oz0, oz1),
                  (-hx, hx, oz0, 0.0), (-hx, hx, hy, oz1)):
        x0, x1, z0, z1 = bande
        tris += _quad([(x0, Y_BOUCHE, z0), (x1, Y_BOUCHE, z0),
                       (x1, Y_BOUCHE, z1), (x0, Y_BOUCHE, z1)])
    # --- surfaces INTÉRIEURES, normale vers la galerie --------------------
    tris += _quad([(hx, Y_BOUCHE, 0.0), (hx, Y_BOUCHE, hy), (hx, Y_FOND, hy),
                   (hx, Y_FOND, 0.0)], t)
    tris += _quad([(-hx, Y_BOUCHE, 0.0), (-hx, Y_FOND, 0.0), (-hx, Y_FOND, hy),
                   (-hx, Y_BOUCHE, hy)], t)
    tris += _quad([(-hx, Y_FOND, 0.0), (hx, Y_FOND, 0.0), (hx, Y_FOND, hy),
                   (-hx, Y_FOND, hy)], t)
    tris += _quad([(-hx, Y_BOUCHE, hy), (-hx, Y_FOND, hy), (hx, Y_FOND, hy),
                   (hx, Y_BOUCHE, hy)], t)
    tris += _quad([(-hx, Y_BOUCHE, 0.0), (hx, Y_BOUCHE, 0.0), (hx, Y_FOND, 0.0),
                   (-hx, Y_FOND, 0.0)], t)
    return tris


# ---------------------------------------------------------------------------
# Écriture GLB. Volontairement minimale : un nœud, un maillage, une
# primitive. La sonde lit ce fichier par le MÊME chemin que le GLB de
# production — si l'écriture et la lecture divergeaient, les épreuves
# suivantes n'auraient aucun sens.
# ---------------------------------------------------------------------------

def ecrire_glb(chemin, triangles, nom="SM_WaterfallCave"):
    positions = []
    indices = []
    for tri in triangles:
        for sommet in tri:
            # modèle Blender -> GLB Y-up. Inverse exact de la conversion de
            # `triangles_du_glb` : (X, Y, Z)_glb -> (X, -Z, Y)_blender.
            x, y, z = sommet
            indices.append(len(positions))
            positions.append((x, z, -y))
    bin_pos = b"".join(struct.pack("<fff", *p) for p in positions)
    bin_idx = b"".join(struct.pack("<I", i) for i in indices)
    pad_pos = bin_pos + b"\x00" * ((4 - len(bin_pos) % 4) % 4)
    binaire = pad_pos + bin_idx
    binaire += b"\x00" * ((4 - len(binaire) % 4) % 4)
    mini = [min(p[k] for p in positions) for k in range(3)]
    maxi = [max(p[k] for p in positions) for k in range(3)]
    gltf = {
        "asset": {"version": "2.0", "generator": "probe_cave_selftest"},
        "scene": 0, "scenes": [{"nodes": [0]}],
        "nodes": [{"name": nom, "mesh": 0}],
        "materials": [{"name": "MAT_Synthetique"}],
        "meshes": [{"name": nom, "primitives": [
            {"attributes": {"POSITION": 0}, "indices": 1, "material": 0,
             "mode": 4}]}],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": len(positions),
             "type": "VEC3", "min": mini, "max": maxi},
            {"bufferView": 1, "componentType": 5125, "count": len(indices),
             "type": "SCALAR"}],
        "bufferViews": [
            {"buffer": 0, "byteOffset": 0, "byteLength": len(bin_pos)},
            {"buffer": 0, "byteOffset": len(pad_pos),
             "byteLength": len(bin_idx)}],
        "buffers": [{"byteLength": len(binaire)}],
    }
    brut = json.dumps(gltf).encode("utf-8")
    brut += b" " * ((4 - len(brut) % 4) % 4)
    total = 12 + 8 + len(brut) + 8 + len(binaire)
    with open(chemin, "wb") as poignee:
        poignee.write(struct.pack("<III", P.GLB_MAGIC, 2, total))
        poignee.write(struct.pack("<II", len(brut), P.CHUNK_JSON))
        poignee.write(brut)
        poignee.write(struct.pack("<II", len(binaire), P.CHUNK_BIN))
        poignee.write(binaire)
    return chemin


# ---------------------------------------------------------------------------
# Le journal d'épreuve.
# ---------------------------------------------------------------------------

class Journal(object):
    def __init__(self):
        self.lignes = []
        self.echecs = 0

    def verifier(self, condition, titre, detail=""):
        etat = "PASS" if condition else "FAIL"
        if not condition:
            self.echecs += 1
        self.lignes.append((etat, titre, detail))
        print("   [%s] %-58s %s" % (etat, titre, detail))
        return bool(condition)


# ---------------------------------------------------------------------------
# ÉPREUVE 1 — la transformation.
# ---------------------------------------------------------------------------

def epreuve_transformation(journal, pose):
    print()
    print("-" * 74)
    print("EPREUVE 1 — TRANSFORMATION MONDE <-> MODELE")
    print("-" * 74)

    # 1a. L'axe de bouche que le script de lieu DÉCLARE en toutes lettres :
    #     « Le modèle sort de la bouche vers son +Z local ; ce lacet
    #       l'oriente vers le sud-est monde (0,707 ; 0,707) ».
    #     La bouche regarde -Y en repère modèle. Si la chaîne de matrices
    #     est juste, sa direction monde doit valoir (0,707 ; 0 ; 0,707).
    #     C'est une VÉRITÉ DE TERRAIN écrite par l'auteur du lieu, pas une
    #     valeur que la sonde se donne à elle-même.
    bouche = pose.direction_vers_monde((0.0, -1.0, 0.0))
    attendu = (math.sqrt(0.5), 0.0, math.sqrt(0.5))
    ecart = max(abs(bouche[k] - attendu[k]) for k in range(3))
    journal.verifier(
        ecart < 1e-9,
        "axe de bouche = sud-est (0,707 ; 0 ; 0,707), declare par le lieu",
        "calcule (%.4f ; %.4f ; %.4f), ecart %.2e" % (bouche + (ecart,)))

    # 1b. Aller-retour entre les DEUX implémentations.
    pire, details = pose.controle_aller_retour()
    journal.verifier(
        pire <= P.TOLERANCE_ALLER_RETOUR_M,
        "aller-retour matrices <-> forme fermee",
        "ecart max %.3e m, tolerance %.0e m" % (pire, P.TOLERANCE_ALLER_RETOUR_M))

    # 1c. LE TEST DE MUTATION. Un aller-retour qui passe ne prouve rien tant
    #     qu'on n'a pas vu ce qu'il faut pour le faire rougir. On casse la
    #     forme fermée exactement comme on la casserait par erreur — signe
    #     de lacet inversé, puis axes Y et Z échangés — et on exige que
    #     l'écart explose. Si le test restait vert ici, il serait un test
    #     qui ne peut pas échouer (`PROMPT4_METHOD` §2).
    original = P.monde_vers_modele
    mutations = []
    try:
        P.monde_vers_modele = lambda p, o, l: original(p, o, -l)
        pire_signe, _ = pose.controle_aller_retour()
        mutations.append(("lacet de signe inverse", pire_signe))

        def _axes_echanges(point, origine, lacet):
            r = original(point, origine, lacet)
            return (r[0], r[2], r[1])
        P.monde_vers_modele = _axes_echanges
        pire_axes, _ = pose.controle_aller_retour()
        mutations.append(("axes Y et Z echanges", pire_axes))
    finally:
        P.monde_vers_modele = original

    for nom, valeur in mutations:
        journal.verifier(
            valeur > 1.0,
            "MUTATION « %s » fait rougir l'aller-retour" % nom,
            "ecart %.3f m, soit %.0e fois la tolerance"
            % (valeur, valeur / P.TOLERANCE_ALLER_RETOUR_M))

    # 1d. Et la mutation ne doit pas seulement rougir : elle doit rougir
    #     BEAUCOUP. C'est l'argument qui justifie la tolerance de 1e-9 m —
    #     entre le bruit numerique et la plus petite faute reelle, il y a
    #     des ordres de grandeur, et le seuil est pose au milieu.
    journal.verifier(
        min(v for _, v in mutations) / max(pire, 1e-18) > 1e6,
        "la marge entre bruit numerique et faute reelle depasse 1e6",
        "bruit %.2e m, plus petite faute %.3f m"
        % (pire, min(v for _, v in mutations)))
    return pose


# ---------------------------------------------------------------------------
# ÉPREUVE 2 — discrimination, localisation et seuil.
# ---------------------------------------------------------------------------

## Les six tunnels. Le trou est donné en paramètres de face ; sa taille
## métrique est recalculée pour être annoncée, et vérifiée par la sonde.
## Les six tunnels. Chaque trou est un CARRÉ de côté donné, centré sur une
## face nommée. Les côtés sont choisis pour encadrer le seuil de
## confirmation (0,10 m) : 0,60 / 0,50 / 0,40 / 0,70 bien au-dessus, 0,04
## bien en dessous. Sans les deux côtés du seuil, on ne saurait pas si la
## sonde mesure ou si elle acquiesce.
CAS = [
    dict(nom="scelle", face=None, attendu=0),
    dict(nom="toit_perce", face="toit", centre=(0.40, 4.00), cote=0.60,
         attendu=1),
    dict(nom="plancher_perce", face="plancher", centre=(-0.60, 2.50),
         cote=0.50, attendu=1),
    dict(nom="paroi_percee", face="paroi_plus_x", centre=(6.50, 1.20),
         cote=0.40, attendu=1),
    dict(nom="fond_perce", face="fond", centre=(0.20, 1.40), cote=0.70,
         attendu=1),
    dict(nom="trou_d_epingle", face="toit", centre=(0.40, 4.00), cote=0.04,
         attendu=0),
]


def mesurer_cas(chemin, cas):
    """Passe un tunnel à la sonde et rend ce qu'elle en dit."""
    tris, _ = P.triangles_du_glb(chemin)
    grille = P.Grille(tris, cote=0.30)
    echantillons = _points_du_tunnel()
    directions = P.directions_sphere(7, 14)
    _, _, _, _, suspects = P.controle_jour_profil(
        grille, echantillons, directions, PROFIL_TUNNEL)
    confirmees, ecartees = P.confirmer_percees(
        grille, suspects, PROFIL_TUNNEL)
    surfaces = P.controle_surfaces(grille, PROFIL_TUNNEL, 0.05)
    return dict(suspects=len(suspects), confirmees=confirmees,
                ecartees=ecartees, surfaces=surfaces, grille=grille)


def _points_du_tunnel():
    """Points d'échantillonnage dans le vide du tunnel synthétique."""
    points = []
    y = Y_BOUCHE + 0.60
    while y <= Y_FOND - 0.30:
        for x in (-0.90, -0.45, 0.0, 0.45, 0.90):
            for z in (0.45, 1.20, 1.95):
                points.append(dict(u=0.0, station=int(
                    round((y - Y_BOUCHE) / (Y_FOND - Y_BOUCHE) * 8.0)),
                    lateral=x / DEMI_LARGEUR, hauteur=z,
                    p=(x, y, z), sol_attendu=0.0, hw=DEMI_LARGEUR, cle=CLE))
        y += 0.40
    return points


def taille_du_trou(cas):
    return cas.get("cote", 0.0)


def epreuve_discrimination(journal, dossier):
    print()
    print("-" * 74)
    print("EPREUVE 2 — DISCRIMINATION, LOCALISATION, SEUIL")
    print("-" * 74)
    print("Six tunnels identiques a un trou pres. Une sonde qui rend le meme")
    print("verdict sur les six ne mesure rien, quelle que soit sa couleur.")
    print()
    resultats = {}
    for cas in CAS:
        chemin = os.path.join(dossier, "tunnel_%s.glb" % cas["nom"])
        trou = None
        if cas.get("face"):
            trou = boite_du_trou(cas["face"], cas["centre"], cas["cote"])
        ecrire_glb(chemin, tunnel(trou))
        mesure = mesurer_cas(chemin, cas)
        resultats[cas["nom"]] = mesure
        conf_surf = sum(len(mesure["surfaces"][s]["confirmees"])
                        for s in P.SURFACES)
        print("   %-16s trou %5.3f m sur %-13s suspects %3d  confirmees "
              "c2=%d c4=%d"
              % (cas["nom"], taille_du_trou(cas), cas["face"] or "-",
                 mesure["suspects"], len(mesure["confirmees"]), conf_surf))

    # 2a. LE VERDICT DOIT DIFFÉRER. C'est la condition minimale pour que la
    #     sonde mesure quoi que ce soit.
    verdicts = {nom: (len(m["confirmees"]) > 0
                      or any(m["surfaces"][s]["confirmees"] for s in P.SURFACES))
                for nom, m in resultats.items()}
    journal.verifier(
        len(set(verdicts.values())) == 2,
        "les six tunnels ne recoivent PAS le meme verdict",
        "verts : %s | rouges : %s"
        % (", ".join(n for n, v in verdicts.items() if not v),
           ", ".join(n for n, v in verdicts.items() if v)))

    # 2b. Le tunnel scellé passe. Un gate qui rougit sur une géométrie saine
    #     finit désactivé, et il a raison de finir désactivé.
    journal.verifier(
        not verdicts["scelle"],
        "tunnel SCELLE : aucune percee confirmee",
        "%d rayon(s) suspect(s), tous ecartes" % resultats["scelle"]["suspects"])

    # 2c. Chaque face percée est trouvée, et NOMMÉE. Le toit est le cas qui
    #     manquait : la version precedente n'en avait aucune carte.
    for cas in CAS:
        if cas["attendu"] != 1:
            continue
        mesure = resultats[cas["nom"]]
        faces_c2 = set(c["surface"] for c in mesure["confirmees"])
        faces_c4 = set(s for s in P.SURFACES
                       if mesure["surfaces"][s]["confirmees"])
        journal.verifier(
            cas["face"] in (faces_c2 | faces_c4),
            "%-16s : percee confirmee sur la face %s" % (cas["nom"],
                                                        cas["face"]),
            "controle 2 -> %s ; controle 4 -> %s"
            % (sorted(faces_c2) or "-", sorted(faces_c4) or "-"))

    # 2d. LOCALISATION. Le trou est-il retrouvé là où on l'a mis ?
    for cas in CAS:
        if cas["attendu"] != 1:
            continue
        mesure = resultats[cas["nom"]]
        centre = centre_du_trou(cas["face"], cas["centre"])
        sorties = [c["sortie"] for c in mesure["confirmees"]]
        if not sorties:
            journal.verifier(False, "%-16s : localisation" % cas["nom"],
                             "aucune sortie a comparer")
            continue
        distances = [math.sqrt(sum((s[k] - centre[k]) ** 2 for k in range(3)))
                     for s in sorties]
        # Tolérance : la demi-diagonale du trou, plus la maille
        # d'agrégation des amas (0,25 m) et le pas du faisceau. La sortie
        # est un point SUR la coque, pas le centre géométrique du carré.
        tolerance = cas["cote"] * 0.71 + 0.25 + P.PAS_OUVERTURE_M
        journal.verifier(
            min(distances) <= tolerance,
            "%-16s : sortie a moins de %.2f m du centre du trou"
            % (cas["nom"], tolerance),
            "centre reel (%.2f ; %.2f ; %.2f), sortie la plus proche a %.2f m"
            % (centre[0], centre[1], centre[2], min(distances)))

    # 2e. LE SEUIL DISCRIMINE. Un trou de 4 cm produit des rayons suspects
    #     — donc la sonde le VOIT — mais il est refusé à la confirmation.
    #     Sans les deux moitiés de cette phrase, « percée confirmée » ne
    #     serait qu'un mot : un seuil qui ne refuse rien n'est pas un seuil,
    #     et un seuil qui aveugle la sonde ne mesure plus.
    epingle = resultats["trou_d_epingle"]
    petit = taille_du_trou([c for c in CAS if c["nom"] == "trou_d_epingle"][0])
    journal.verifier(
        epingle["suspects"] > 0,
        "trou d'epingle %.3f m de cote : VU (rayons suspects)" % petit,
        "%d rayon(s) suspect(s)" % epingle["suspects"])
    journal.verifier(
        not verdicts["trou_d_epingle"],
        "trou d'epingle : REFUSE a la confirmation",
        "plus grande ouverture mesuree %.3f m, seuil %.2f m"
        % (max([e["ouverture_m"] for e in epingle["ecartees"]] or [0.0]),
           P.OUVERTURE_CONFIRMEE_M))

    # 2f. L'ouverture MESURÉE doit approcher l'ouverture RÉELLE. Un gate qui
    #     dit « perce » sans savoir de combien ne sert qu'a une fois.
    for cas in CAS:
        if cas["attendu"] != 1:
            continue
        mesure = resultats[cas["nom"]]
        toutes = ([c["ouverture_m"] for c in mesure["confirmees"]]
                  + [c["ouverture_m"] for s in P.SURFACES
                     for c in mesure["surfaces"][s]["confirmees"]])
        petit = taille_du_trou(cas)
        if not toutes:
            journal.verifier(False, "%-16s : ouverture mesuree" % cas["nom"],
                             "aucune")
            continue
        mesuree = max(toutes)
        journal.verifier(
            mesuree <= petit + P.PAS_OUVERTURE_M,
            "%-16s : ouverture mesuree <= cote reel du trou" % cas["nom"],
            "mesuree %.3f m, cote reel %.3f m — la mesure ne SURESTIME pas"
            % (mesuree, petit))
    return resultats


# ---------------------------------------------------------------------------
# ÉPREUVE 3 — la ligne de vue, avec vérité de terrain.
# ---------------------------------------------------------------------------

def projeter(prise, pose, point_modele):
    """Pixel d'un point MODÈLE, par une projection écrite INDÉPENDAMMENT.

    Cette fonction ne partage aucune ligne avec `controle_ligne_de_vue` :
    elle projette un point (monde -> pixel), là où la sonde lance un rayon
    (pixel -> modèle). Si les deux se contredisaient, l'épreuve rougirait —
    c'est exactement ce qu'on lui demande de pouvoir faire.
    """
    monde = pose.vers_monde(point_modele)
    camera, cible, fov = prise["from"], prise["look"], prise["fov"]
    largeur, hauteur = prise["taille"]
    avant = P._normaliser((cible[0] - camera[0], cible[1] - camera[1],
                           cible[2] - camera[2]))
    axe_z = tuple(-c for c in avant)
    axe_x = P._normaliser(P._croix((0.0, 1.0, 0.0), axe_z))
    axe_y = P._croix(axe_z, axe_x)
    v = tuple(monde[k] - camera[k] for k in range(3))
    profondeur = sum(v[k] * avant[k] for k in range(3))
    if profondeur <= 1e-6:
        return None
    dx = sum(v[k] * axe_x[k] for k in range(3))
    dy = sum(v[k] * axe_y[k] for k in range(3))
    demi_v = math.tan(math.radians(fov) * 0.5)
    demi_h = demi_v * largeur / float(hauteur)
    ndc_x = (dx / profondeur) / demi_h
    ndc_y = (dy / profondeur) / demi_v
    return ((ndc_x + 1.0) * 0.5 * largeur, (1.0 - ndc_y) * 0.5 * hauteur)


def epreuve_ligne_de_vue(journal, dossier, pose):
    print()
    print("-" * 74)
    print("EPREUVE 3 — LIGNE DE VUE, POSE CONNUE, TROU CONNU")
    print("-" * 74)
    print("Une camera posee en MONDE regarde un tunnel dont on connait la pose")
    print("et le trou. La sonde doit faire apparaitre le trou dans la boite de")
    print("pixels PREDITE. C'est ce qu'aucune superposition d'image ne pouvait")
    print("etablir : ici, la reponse est connue avant la mesure.")
    print()

    face, centre, cote = "fond", (0.20, 1.40), 0.70
    chemin = ecrire_glb(os.path.join(dossier, "tunnel_ligne_de_vue.glb"),
                        tunnel(boite_du_trou(face, centre, cote)))
    tris, _ = P.triangles_du_glb(chemin)
    grille = P.Grille(tris, cote=0.30)

    # La caméra est placée en MONDE, sur l'axe de la galerie, devant la
    # bouche. Sa position se calcule par la chaîne de matrices — donc si la
    # chaîne est fausse, la caméra ne regarde pas dans le tunnel et
    # l'épreuve rougit.
    oeil_modele = (0.0, Y_BOUCHE - 6.0, 1.25)
    vise_modele = (0.0, Y_FOND, 1.25)
    prise = dict(name="synthetique_axe",
                 **{"from": list(pose.vers_monde(oeil_modele)),
                    "look": list(pose.vers_monde(vise_modele))})
    prise["fov"] = 40.0
    prise["taille"] = (1280, 720)

    traversants, suspects = P.controle_ligne_de_vue(
        grille, prise, pose.origine, pose.lacet_deg, 4, PROFIL_TUNNEL)
    boites = P.grouper_pixels(suspects, 4)

    journal.verifier(
        traversants > 1000,
        "la camera monde voit bien la formation",
        "%d pixel(s) touchent la coque" % traversants)

    milieu = centre_du_trou(face, centre)
    coins = [(milieu[0] + sx * cote / 2.0, milieu[1],
              milieu[2] + sz * cote / 2.0)
             for sx in (-1.0, 1.0) for sz in (-1.0, 1.0)]
    pixels = [projeter(prise, pose, c) for c in coins]
    pixels = [p for p in pixels if p is not None]
    px0 = min(p[0] for p in pixels)
    px1 = max(p[0] for p in pixels)
    py0 = min(p[1] for p in pixels)
    py1 = max(p[1] for p in pixels)
    print("   boite PREDITE (projection independante) : x[%.0f..%.0f] "
          "y[%.0f..%.0f]" % (px0, px1, py0, py1))
    if boites:
        b = boites[0]
        print("   boite MESUREE  (lancer de rayon de la sonde) : "
              "x[%d..%d] y[%d..%d], %d pixel(s)"
              % (b["x0"], b["x1"], b["y0"], b["y1"], b["pixels"]))

    journal.verifier(bool(boites), "le trou du fond produit des pixels percants",
                     "%d boite(s), %d pixel(s)"
                     % (len(boites), len(suspects)))
    if boites:
        b = boites[0]
        marge = 8.0                      # deux pas de pixel
        dedans = (px0 - marge <= b["x0"] and b["x1"] <= px1 + marge
                  and py0 - marge <= b["y0"] and b["y1"] <= py1 + marge)
        journal.verifier(
            dedans,
            "les pixels percants tombent dans la boite PREDITE",
            "ecarts x %+.0f/%+.0f, y %+.0f/%+.0f pixel(s)"
            % (b["x0"] - px0, b["x1"] - px1, b["y0"] - py0, b["y1"] - py1))

        # LA MUTATION, ENCORE. Décalé de 3 m — le décalage exact qui
        # « améliorait » la superposition d'hier — le résultat doit changer
        # franchement. Si un décalage de 3 m laissait la mesure indifférente,
        # c'est la mesure qui serait plate, et le contrôle 3 resterait
        # `NON VÉRIFIÉ` quoi qu'il rende.
        faux = pose.decalee(3.0, 0.0, 0.0)
        t_faux, s_faux = P.controle_ligne_de_vue(
            grille, prise, faux.origine, faux.lacet_deg, 4, PROFIL_TUNNEL)
        b_faux = P.grouper_pixels(s_faux, 4)
        bouge = (abs(t_faux - traversants) > 0.10 * traversants
                 or not b_faux
                 or abs(b_faux[0]["x0"] - b["x0"]) > 2 * marge)
        journal.verifier(
            bouge,
            "une origine fausse de 3 m CHANGE franchement le resultat",
            "pixels sur la coque %d -> %d ; boites %d -> %d"
            % (traversants, t_faux, len(boites), len(b_faux)))


# ---------------------------------------------------------------------------
# ÉPREUVE 4 — la mutation SUR LA GÉOMÉTRIE DE PRODUCTION.
# ---------------------------------------------------------------------------

def epreuve_mutation_reelle(journal, glb):
    """Le gate distingue-t-il sur le maillage LIVRÉ, et pas seulement sur
    un tunnel de laboratoire ?

    On retire du maillage réel les triangles qui croisent une colonne
    verticale de 0,25 m au toit de la station 4, et rien d'autre. Aucun
    fichier n'est modifié : la mutation vit en mémoire.

    C'est l'épreuve qui empêche de conclure trop vite. Un `PASS` sur le
    maillage intact ne vaut que si le MÊME contrôle, sur le MÊME maillage
    à six triangles près, rend `FAIL`. Sans cette paire, un vert ne
    distingue pas « la grotte est fermée » de « la sonde ne regarde pas ».
    """
    print()
    print("-" * 74)
    print("EPREUVE 4 — MUTATION DU MAILLAGE LIVRE")
    print("-" * 74)
    if not os.path.isfile(glb):
        journal.verifier(False, "maillage de production lisible", glb)
        return
    tris, _ = P.triangles_du_glb(glb)
    profil = P.PROFIL_GROTTE
    echantillons = P.points_interieurs(
        0.25, (-0.60, -0.30, 0.0, 0.30, 0.60), (0.35, 0.90, 1.50))
    directions = P.directions_sphere(7, 14)

    def _juger(triangles, titre):
        grille = P.Grille(triangles)
        _, _, _, _, suspects = P.controle_jour(grille, echantillons, directions)
        confirmees, ecartees = P.confirmer_percees(grille, suspects, profil)
        ouverture = max([e["ouverture_m"] for e in ecartees]
                        + [c["ouverture_m"] for c in confirmees] + [0.0])
        print("   %-30s %5d tris  %3d suspect(s)  %3d confirmee(s)  "
              "ouverture max %.3f m"
              % (titre, len(triangles), len(suspects), len(confirmees),
                 ouverture))
        return len(confirmees), ouverture, len(suspects)

    intact, ouv_intact, susp_intact = _juger(tris, "maillage LIVRE, intact")

    ax, ay, _, cle, palier = profil.station(4.0)
    demi, seuil_z = 0.125, palier + cle - 0.60
    perce = [t for t in tris
             if not any(abs(s[0] - ax) <= demi and abs(s[1] - ay) <= demi
                        and s[2] > seuil_z for s in t)]
    retires = len(tris) - len(perce)
    mute, ouv_mute, susp_mute = _juger(
        perce, "toit perce 0,25 m, station 4")

    journal.verifier(
        retires > 0,
        "la mutation retire bien de la matiere du maillage livre",
        "%d triangle(s) retire(s) sur %d" % (retires, len(tris)))
    journal.verifier(
        intact == 0,
        "maillage LIVRE intact : 0 percee confirmee",
        "%d rayon(s) suspect(s), ouverture max %.3f m"
        % (susp_intact, ouv_intact))
    journal.verifier(
        mute > 0,
        "maillage MUTE : le gate rougit",
        "%d percee(s) confirmee(s), ouverture %.3f m, suspects %d -> %d"
        % (mute, ouv_mute, susp_intact, susp_mute))
    journal.verifier(
        intact != mute,
        "le verdict CHANGE pour %d triangle(s) de difference" % retires,
        "intact PASS, mute FAIL — le vert du maillage livre est une mesure, "
        "pas un reglage")


# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(
        description="Epreuve de tools/probe_cave_openings.py sur une "
                    "geometrie a pose connue.")
    ap.add_argument("--garder", default=None,
                    help="dossier ou conserver les GLB d'epreuve")
    ap.add_argument("--place",
                    default="scripts/world_v2/poi/waterfall_cave_place.gd")
    ap.add_argument("--layout",
                    default="resources/world_v2/world_v2_layout.json")
    ap.add_argument("--poi", default="valley.poi.waterfall_cave.01")
    ap.add_argument("--reel",
                    default="assets/environment/caves/SM_WaterfallCave.glb",
                    help="maillage de production, pour l'epreuve 4")
    args = ap.parse_args()

    print("=" * 74)
    print("EPREUVE DE LA SONDE — geometrie synthetique a pose connue")
    print("=" * 74)

    try:
        pose = P.Pose.depuis_les_sources(args.place, args.layout, args.poi)
    except P.Blocage as erreur:
        print("BLOQUE: %s" % erreur)
        return 3

    print("pose eprouvee : origine (%.3f ; %.3f ; %.3f), lacet %.1f deg"
          % (pose.origine + (pose.lacet_deg,)))

    dossier = args.garder or tempfile.mkdtemp(prefix="cave_selftest_")
    if not os.path.isdir(dossier):
        os.makedirs(dossier)
    journal = Journal()
    try:
        epreuve_transformation(journal, pose)
        epreuve_discrimination(journal, dossier)
        epreuve_ligne_de_vue(journal, dossier, pose)
        epreuve_mutation_reelle(journal, args.reel)
    finally:
        if not args.garder:
            shutil.rmtree(dossier, ignore_errors=True)

    print()
    print("=" * 74)
    total = len(journal.lignes)
    print("EPREUVES : %d / %d passees" % (total - journal.echecs, total))
    print("VERDICT : %s" % ("PASS" if journal.echecs == 0
                            else "FAIL — %d epreuve(s) rouge(s)"
                                 % journal.echecs))
    print("=" * 74)
    return 1 if journal.echecs else 0


if __name__ == "__main__":
    sys.exit(main())
