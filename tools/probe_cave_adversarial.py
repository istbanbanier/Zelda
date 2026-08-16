#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ÉPREUVES ADVERSARIALES — chaque contrôle rougi EXPRÈS, puis rendu vert.

POURQUOI CE FICHIER EXISTE
==========================

Un contrôle vert ne prouve rien tant qu'on n'a pas vu qu'il sait rougir.
C'est le mode d'échec d'ISS-018, où « tous les tests étaient verts » pendant
que les créatures s'affichaient en pièces détachées, et c'est le mode
d'échec de cette passe-ci : la sonde a rendu « 0 percée » sur un
échantillonnage qui ne regardait que 36 % du côté large, puis « 38 percées »
dont 38 étaient fausses.

Chaque épreuve suit donc le même protocole, et il n'y a pas d'exception :

    SABOTAGE  ->  ROUGE MESURÉ  ->  JOURNAL ARCHIVÉ  ->  RESTAURATION
    EXACTE  ->  VERT

La restauration est vérifiée par empreinte : on compare le `sha256` de la
géométrie d'avant et d'après. Une restauration « à peu près » laisserait la
suite mesurer autre chose que ce qu'elle croit, et c'est exactement la
famille de piège que `tools/CLAUDE.md` documente sous « exporter à la main
après une chaîne interrompue rend l'ANCIEN maillage ».

CE QUI EST ÉPROUVÉ, ET DANS QUEL ORDRE
======================================

  1. COQUE SYMÉTRIQUE — ancien et nouvel échantillonnage doivent être
     IDENTIQUES. Une correction qui déplace des points là où il n'y avait
     rien à corriger est une régression déguisée en amélioration.
  2. COQUE ASYMÉTRIQUE à deux épaisseurs connues — la mesure doit rendre
     les deux valeurs posées, et du bon côté.
  3. TROU DANS LE TOIT -> rouge.
  4. TROU DANS LE PLANCHER -> rouge.
  5. COLLERETTE amputée localement -> rouge.
  6. PAROI LATÉRALE amincie sous le seuil -> rouge.
  7. TRANSFORMATION rotation + translation + ÉCHELLE NON TRIVIALE — mêmes
     mesures en repère modèle et en repère monde.
  8. JOURNAL — un acquittement ne peut pas être imprimé sous un `<-- TROU`.
  9. GÉOMÉTRIE INTACTE restaurée -> vert.
 10. COURBURE + PLANCHER MONTANT — la fixture de la septième occurrence :
     l'échantillonnage le long de X rougit, celui le long de la normale
     passe. Demandée par l'agent plancher, qui a trouvé la faute.

Usage :
    python3 tools/probe_cave_adversarial.py [--garder <dossier>]

Codes de sortie : 0 = toutes les épreuves tiennent · 1 = au moins une
échoue · 3 = BLOQUÉ.
"""

import argparse
import contextlib
import hashlib
import io
import json
import math
import os
import shutil
import struct
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import probe_cave_openings as P                                # noqa: E402
import cave_collar as C                                        # noqa: E402


# ---------------------------------------------------------------------------
# Une géométrie d'épreuve dont on connaît TOUT.
# ---------------------------------------------------------------------------

SEGMENTS = 12


def _anneau(centre, normale, demi_gauche, demi_droite, sol, toit):
    """Section polygonale fermée, DISSYMÉTRIQUE, dans le plan de normale.

    Le côté est décidé par le signe de l'offset normal, exactement comme le
    générateur de production : c'est ce qui rend l'épreuve pertinente.
    """
    ax, ay = centre
    nx, ny = normale
    sortie = []
    for k in range(SEGMENTS):
        theta = 2.0 * math.pi * k / SEGMENTS
        u, v = math.cos(theta), math.sin(theta)
        demi = demi_gauche if u < 0.0 else demi_droite
        lat = demi * u
        z = (toit * v) if v >= 0.0 else (sol * -v * -1.0)
        z = toit * v if v >= 0.0 else sol * (-v)
        z = toit * v if v >= 0.0 else -sol * (-v)
        sortie.append((ax + lat * nx, ay + lat * ny, z))
    return sortie


def tunnel(stations, epaisseur_gauche=0.80, epaisseur_droite=0.80,
           epaisseur_toit=0.80, epaisseur_sol=0.80, trous=(), collerette=None,
           prolonge=0.60):
    """Tunnel fermé : peau intérieure + peau extérieure + bouchons.

    `stations` : liste de `(ax, ay, demi_gauche, demi_droite, sol, toit)`.
    `trous` : liste de `(indice_station, face, demi_cote)` où `face` vaut
    `toit`, `plancher`, `gauche`, `droite` ou `collerette`. Un trou retire
    les triangles dont le barycentre tombe dans une boîte centrée sur la
    face visée — c'est une amputation FRANCHE, dont on connaît la taille.
    """
    n = len(stations)
    normales = []
    for i in range(n):
        a = stations[max(0, i - 1)]
        b = stations[min(n - 1, i + 1)]
        tx, ty = b[0] - a[0], b[1] - a[1]
        d = math.hypot(tx, ty) or 1.0
        normales.append((ty / d, -tx / d))

    interieur, exterieur = [], []
    for i, st in enumerate(stations):
        ax, ay, dg, dd, sol, toit = st
        interieur.append(_anneau((ax, ay), normales[i], dg, dd, sol, toit))
        exterieur.append(_anneau((ax, ay), normales[i],
                                 dg + epaisseur_gauche, dd + epaisseur_droite,
                                 sol + epaisseur_sol, toit + epaisseur_toit))

    tris = []

    def _quad(a, b, c, d):
        tris.append((a, b, c))
        tris.append((a, c, d))

    for i in range(n - 1):
        for k in range(SEGMENTS):
            k2 = (k + 1) % SEGMENTS
            # peau intérieure, normales vers l'intérieur du solide
            _quad(interieur[i][k], interieur[i + 1][k],
                  interieur[i + 1][k2], interieur[i][k2])
            _quad(exterieur[i][k2], exterieur[i + 1][k2],
                  exterieur[i + 1][k], exterieur[i][k])
    # PROLONGE AVANT — comme `PROLONGE_PORCHE_M` du generateur.
    #
    # Sans lui, la station 0 EST le bord du maillage : un rayon vertical
    # tire depuis y = -1,15 rase l'arete de la premiere nappe et la manque
    # numeriquement. La carte du plancher rendait 13 « absences » de sol a
    # cette seule station, sur une fixture parfaitement close. Le vrai
    # generateur prolonge le tube de 3,05 m devant le porche pour la meme
    # raison ; la fixture doit le faire aussi, sinon elle eprouve un cas que
    # la production ne rencontre jamais.
    if prolonge > 0.0:
        tgx, tgy = -normales[0][1], normales[0][0]
        avance = (-tgx * prolonge, -tgy * prolonge)
        devant_in = [(p[0] + avance[0], p[1] + avance[1], p[2])
                     for p in interieur[0]]
        devant_out = [(p[0] + avance[0], p[1] + avance[1], p[2])
                      for p in exterieur[0]]
        for k in range(SEGMENTS):
            k2 = (k + 1) % SEGMENTS
            _quad(devant_in[k], interieur[0][k], interieur[0][k2],
                  devant_in[k2])
            _quad(exterieur[0][k2], devant_out[k2], devant_out[k],
                  exterieur[0][k])
        interieur[0] = devant_in
        exterieur[0] = devant_out

    # BOUCHON AVANT SEULEMENT. L'arriere en avait un aussi, et depuis que
    # le fond est un vrai solide cet anneau le TRAVERSE : c'est une membrane
    # interne, elle rend la parite impaire, et elle fabriquait des percees
    # sur une fixture saine.
    for i, sens in ((0, 1),):
        for k in range(SEGMENTS):
            k2 = (k + 1) % SEGMENTS
            if sens > 0:
                _quad(interieur[i][k2], exterieur[i][k2],
                      exterieur[i][k], interieur[i][k])
            else:
                _quad(interieur[i][k], exterieur[i][k],
                      exterieur[i][k2], interieur[i][k2])
    # FOND PLEIN — ET IL DOIT ETRE UN SOLIDE, PAS UNE MEMBRANE.
    #
    # Premiere version : un simple disque fermait la section interieure. Un
    # rayon partant de l'interieur vers +Y le traversait UNE fois, donc en
    # parite IMPAIRE, et la sonde comptait une percee. Elle avait raison :
    # une membrane d'epaisseur nulle n'est pas de la roche. Resultat, 599
    # « percees » sur un tunnel cense etre intact, et quatre epreuves en
    # echec pour un defaut de la FIXTURE, pas de l'instrument.
    #
    # C'est le meme piege que la sonde elle-meme a subi : mesurer avec
    # assurance quelque chose qui n'est pas ce qu'on croit. Le fond porte
    # donc deux peaux separees par l'epaisseur, comme partout ailleurs.
    tan_x = stations[n - 1][0] - stations[n - 2][0]
    tan_y = stations[n - 1][1] - stations[n - 2][1]
    norme = math.hypot(tan_x, tan_y) or 1.0
    recul = (tan_x / norme * epaisseur_toit, tan_y / norme * epaisseur_toit)
    dernier = interieur[n - 1]
    dehors = [(p[0] + recul[0], p[1] + recul[1], p[2])
              for p in exterieur[n - 1]]
    c_in = tuple(sum(p[k] for p in dernier) / SEGMENTS for k in range(3))
    c_out = tuple(sum(p[k] for p in dehors) / SEGMENTS for k in range(3))
    for k in range(SEGMENTS):
        k2 = (k + 1) % SEGMENTS
        tris.append((dernier[k], dernier[k2], c_in))
        tris.append((dehors[k2], dehors[k], c_out))
        # jonction entre l'anneau exterieur de la derniere station et le
        # capot exterieur recule : sans elle, le solide reste ouvert.
        _quad(exterieur[n - 1][k], dehors[k], dehors[k2],
              exterieur[n - 1][k2])

    # COLLERETTE — un bourrelet autour de la bouche, épaisseur `collerette`.
    if collerette:
        ax, ay, dg, dd, sol, toit = stations[0]
        nx, ny = normales[0]
        avant = (ax - nx * 0.0, ay - 0.0, 0.0)
        anneau_in = _anneau((ax, ay), (nx, ny), dg, dd, sol, toit)
        anneau_out = _anneau((ax, ay), (nx, ny), dg + collerette,
                             dd + collerette, sol + collerette,
                             toit + collerette)
        # translaté vers l'avant du tunnel (le long de -tangente)
        tx, ty = -ny, nx
        dec = (-tx * 0.30, -ty * 0.30, 0.0)
        a_in = [(p[0] + dec[0], p[1] + dec[1], p[2]) for p in anneau_in]
        a_out = [(p[0] + dec[0], p[1] + dec[1], p[2]) for p in anneau_out]
        for k in range(SEGMENTS):
            k2 = (k + 1) % SEGMENTS
            _quad(a_in[k], a_out[k], a_out[k2], a_in[k2])
            _quad(anneau_in[k2], anneau_out[k2], a_out[k2], a_in[k2])

    # AMPUTATIONS.
    for indice, face, demi in trous:
        ax, ay, dg, dd, sol, toit = stations[indice]
        nx, ny = normales[indice]
        if face == "toit":
            cible = (ax, ay, toit)
        elif face == "plancher":
            cible = (ax, ay, -sol)
        elif face == "gauche":
            cible = (ax - dg * nx, ay - dg * ny, 0.0)
        elif face == "droite":
            cible = (ax + dd * nx, ay + dd * ny, 0.0)
        else:
            # LA CIBLE EST LE BOURRELET LUI-MEME, recule de 0,30 m devant la
            # bouche le long de la tangente. Viser le plafond de la station 0
            # n'amputait rien : le sabotage ne mordait pas, et une epreuve
            # dont le sabotage ne mord pas ne prouve rien.
            tgx, tgy = -normales[indice][1], normales[indice][0]
            cible = (ax - tgx * 0.30, ay - tgy * 0.30, toit)
        garde = []
        for t in tris:
            bary = tuple(sum(s[k] for s in t) / 3.0 for k in range(3))
            if all(abs(bary[k] - cible[k]) <= demi for k in range(3)):
                continue
            garde.append(t)
        tris = garde
    return tris


def ecrire_glb(chemin, triangles, nom="SM_WaterfallCave"):
    """GLB minimal, Y-up, converti depuis le repère modèle Blender."""
    sommets, index, table = [], [], {}
    for t in triangles:
        for s in t:
            # modèle Blender (x, y, z) -> glTF Y-up (x, z, -y)
            cle = (round(s[0], 6), round(s[2], 6), round(-s[1], 6))
            if cle not in table:
                table[cle] = len(sommets)
                sommets.append(cle)
            index.append(table[cle])
    bin_pos = b"".join(struct.pack("<fff", *s) for s in sommets)
    bin_idx = b"".join(struct.pack("<I", i) for i in index)
    tampon = bin_pos + bin_idx
    while len(tampon) % 4:
        tampon += b"\0"
    lo = [min(s[k] for s in sommets) for k in range(3)]
    hi = [max(s[k] for s in sommets) for k in range(3)]
    gltf = dict(
        asset=dict(version="2.0"),
        scenes=[dict(nodes=[0])], scene=0,
        nodes=[dict(mesh=0, name=nom)],
        meshes=[dict(name=nom, primitives=[dict(
            attributes=dict(POSITION=0), indices=1)])],
        buffers=[dict(byteLength=len(tampon))],
        bufferViews=[
            dict(buffer=0, byteOffset=0, byteLength=len(bin_pos), target=34962),
            dict(buffer=0, byteOffset=len(bin_pos), byteLength=len(bin_idx),
                 target=34963)],
        accessors=[
            dict(bufferView=0, componentType=5126, count=len(sommets),
                 type="VEC3", min=lo, max=hi),
            dict(bufferView=1, componentType=5125, count=len(index),
                 type="SCALAR")])
    js = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    while len(js) % 4:
        js += b" "
    total = 12 + 8 + len(js) + 8 + len(tampon)
    with open(chemin, "wb") as poignee:
        poignee.write(struct.pack("<III", 0x46546C67, 2, total))
        poignee.write(struct.pack("<II", len(js), 0x4E4F534A))
        poignee.write(js)
        poignee.write(struct.pack("<II", len(tampon), 0x004E4942))
        poignee.write(tampon)
    return chemin


def empreinte(chemin):
    with open(chemin, "rb") as poignee:
        return hashlib.sha256(poignee.read()).hexdigest()


# ---------------------------------------------------------------------------

class Journal(object):
    """Compte les épreuves, et refuse de conclure sans preuve des deux états."""

    def __init__(self, dossier):
        self.dossier = dossier
        self.lignes = []
        self.echecs = []
        self.epreuves = []

    def dire(self, texte=""):
        print(texte)
        self.lignes.append(texte)

    def epreuve(self, numero, titre):
        self.dire()
        self.dire("-" * 74)
        self.dire("EPREUVE %-2s — %s" % (numero, titre))
        self.dire("-" * 74)
        self.courante = dict(numero=numero, titre=titre, rouge=None,
                             vert=None, empreinte_avant=None,
                             empreinte_apres=None, details=[])
        self.epreuves.append(self.courante)
        return self.courante

    def rouge_puis_vert(self, rouge_vu, vert_vu, detail_rouge, detail_vert):
        """Les DEUX états sont exigés. Un seul ne prouve rien."""
        self.courante["rouge"] = bool(rouge_vu)
        self.courante["vert"] = bool(vert_vu)
        self.courante["details"] = [detail_rouge, detail_vert]
        self.dire("   sabotage  -> %s   %s"
                  % ("ROUGE" if rouge_vu else "PAS DE ROUGE", detail_rouge))
        self.dire("   restaure  -> %s   %s"
                  % ("VERT" if vert_vu else "PAS DE VERT", detail_vert))
        ok = rouge_vu and vert_vu
        if not ok:
            raison = ("le sabotage n'a pas fait rougir : le controle ne peut "
                      "pas echouer" if not rouge_vu else
                      "la restauration ne redonne pas le vert")
            self.echecs.append("%s — %s" % (self.courante["numero"], raison))
            self.dire("   >>> ECHEC : %s" % raison)
        else:
            self.dire("   PASS — le controle sait rougir ET sait se taire")
        return ok

    def restauration(self, avant, apres):
        """La restauration est prouvée par empreinte, pas par intention."""
        self.courante["empreinte_avant"] = avant
        self.courante["empreinte_apres"] = apres
        if avant != apres:
            self.dire("   >>> ECHEC : restauration INEXACTE")
            self.dire("       avant %s" % avant[:16])
            self.dire("       apres %s" % apres[:16])
            self.echecs.append("%s — restauration inexacte"
                               % self.courante["numero"])
            return False
        self.dire("   restauration exacte : sha256 %s identique" % avant[:16])
        return True

    def archiver(self, nom, texte):
        chemin = os.path.join(self.dossier, nom)
        with open(chemin, "w", encoding="utf-8") as poignee:
            poignee.write(texte)
        self.dire("   journal archive : %s" % chemin)
        return chemin


# ---------------------------------------------------------------------------
# Les géométries de référence
# ---------------------------------------------------------------------------

def stations_droites(demi=1.50, sol=0.60, toit=2.20, n=9, pas=1.30):
    """Tunnel DROIT et SYMÉTRIQUE, le long de +Y."""
    return [(0.0, -1.15 + i * pas, demi, demi, sol, toit) for i in range(n)]


def stations_asym(gauche=2.20, droite=0.80, sol=0.60, toit=2.20, n=9,
                  pas=1.30):
    """Tunnel DROIT mais DISSYMÉTRIQUE, deux largeurs connues."""
    return [(0.0, -1.15 + i * pas, gauche, droite, sol, toit)
            for i in range(n)]


## LA PENTE DE LA FIXTURE, RECALEE SUR LA GROTTE REELLE.
##
## La fixture rendait UNE faute sur 72, partout dans son balayage de
## robustesse. Un rouge qui tient sur une observation peut basculer a zero
## sans que personne le remarque, et l'epreuve devient « ne peut pas
## echouer » — l'anti-motif de `docs/PROMPT4_METHOD.md` §2, celui-la meme
## qu'elle est censee interdire.
##
## La tentation etait de durcir la fixture jusqu'a la voir rougir. C'est le
## miroir exact d'un seuil qu'on abaisse, et `tools/CLAUDE.md` le nomme :
## « calibrer sur le sujet ». On a donc MESURE la grotte reelle et recale la
## fixture dessus, en publiant les deux colonnes :
##
##                          | grotte reelle | fixture avant | fixture apres
##   ecart de normale a X   |   0..60,1 deg |  0..69,9 deg  |  0..69,9 deg
##   pente moyenne du sol   |    0,206 m/m  |   0,062 m/m   |   0,206 m/m
##   pente locale maximale  |    0,664 m/m  |   0,127 m/m   |   0,681 m/m
##
## Le resultat de la mesure a corrige mon hypothese de depart, et il faut
## le dire : je croyais la COURBURE sous-modelee. Elle ne l'etait pas — la
## fixture depasse deja le reel (69,9 contre 60,1 degres). Le seul ecart
## reel etait la PENTE DU PLANCHER, sous-modelee d'un facteur 3,3 — et
## c'est precisement la grandeur qui convertit un decalage axial en erreur
## de HAUTEUR. La courbure est laissee telle quelle.
##
## Le compte de fautes qui en resulte n'a pas ete choisi : il est la
## CONSEQUENCE de la pente reelle. Il passe de 1 a 4.
PENTE_SOL_TOTAL_M = 1.67          # -> pente moyenne 0,206 m/m, comme le reel
PENTE_SOL_LARGEUR = 0.60          # -> pente locale 0,681 m/m, comme le reel
PENTE_SOL_DEPART_M = 1.75         # profondeur initiale ; reste > 0 partout

## Nombre MINIMAL de fautes exigees de l'ancien echantillonnage. L'ancien
## verdict se contentait de `> 0`, donc d'une seule observation. Exiger
## trois est un DURCISSEMENT — on ne descend aucun seuil, on en monte un.
FAUTES_MIN_ANCIEN = 3


def _rampe(t, largeur):
    """Marche lisse centree, de derivee nulle aux deux bouts."""
    debut = 0.5 - largeur / 2.0
    x = (t - debut) / largeur
    if x <= 0.0:
        return 0.0
    if x >= 1.0:
        return 1.0
    return 3.0 * x * x - 2.0 * x * x * x


def stations_coudees(n=9, trous_plancher=False):
    """Tunnel COURBE dont le plancher MONTE — la fixture de la 7e occurrence.

    Deux propriétés, et il faut les deux :

      * la normale s'écarte franchement de X — le coude tourne de 45°, donc
        au-delà du coude la normale porte une composante en y comparable à
        sa composante en x. Un échantillonnage le long de X y sort de la
        cavité ;
      * le plancher MONTE le long de la galerie, à la PENTE MESURÉE sur la
        grotte réelle. C'est ce qui transforme une erreur de placement en
        erreur de HAUTEUR mesurable : sur un plancher plat, viser à côté ne
        se voit pas — et c'est pour cela que la faute a survécu six
        corrections.
    """
    stations = []
    for i in range(n):
        t = i / float(n - 1)
        angle = math.radians(45.0) * max(0.0, t - 0.3) / 0.7
        ax = 3.6 * (t ** 2) * math.sin(angle) * 2.0
        ay = -1.15 + 5.2 * t
        sol = PENTE_SOL_DEPART_M - PENTE_SOL_TOTAL_M * _rampe(
            t, PENTE_SOL_LARGEUR)
        stations.append((ax, ay, 2.20, 0.80, sol, 2.20))
    return stations


def pentes_du_profil(stations):
    """`(pente moyenne, pente locale maximale)` du plancher, en m/m.

    Sert deux fois : à recaler la fixture sur la grotte réelle, et à
    PUBLIER les deux colonnes côte à côte. Un recalage qu'on ne montre pas
    est un réglage.
    """
    longueur, locale = 0.0, 0.0
    for i in range(len(stations) - 1):
        a, b = stations[i], stations[i + 1]
        pas = math.hypot(b[0] - a[0], b[1] - a[1])
        longueur += pas
        if pas > 1.0e-9:
            locale = max(locale, abs(a[4] - b[4]) / pas)
    sols = [-st[4] for st in stations]
    moyenne = (max(sols) - min(sols)) / longueur if longueur else 0.0
    return moyenne, locale


def profil_de(stations, nom):
    """`Profil` correspondant EXACTEMENT aux stations d'épreuve.

    L'épreuve n'a de valeur que si la sonde mesure la géométrie avec le
    profil qui la décrit. Un profil approché rendrait des écarts qu'on
    attribuerait à la sonde alors qu'ils viendraient du profil.
    """
    cavite, asym, palier = [], [], []
    for ax, ay, dg, dd, sol, toit in stations:
        hw = max(dg, dd)
        cavite.append((ax, ay, hw, toit))
        asym.append((dg / hw, dd / hw, 0.0))
        palier.append(-sol)
    return P.Profil(cavite, palier, 0.0, 0.0, 1.0, nom, cavite_asym=asym)


def compter_percees(chemin, profil, pas_lateral=0.25, pas_long=0.5):
    """Percées confirmées sur une géométrie d'épreuve."""
    tris, _ = P.triangles_du_glb(chemin)
    grille = P.Grille(tris)
    ech = P.points_interieurs(pas_long, None, (0.30, 0.90, 1.40), profil,
                              pas_lateral_m=pas_lateral)
    dirs = P.directions_sphere(5, 10)
    _, _, _, _, suspects = P._controle_jour(grille, ech, dirs, profil)
    confirmees, ecartes = P.confirmer_percees(grille, suspects, profil)
    ouverture = max([c["ouverture_m"] for c in confirmees]
                    + [e["ouverture_m"] for e in ecartes] + [0.0])
    return len(confirmees), len(suspects), ouverture


def fautes_plancher(chemin, profil, pas_lateral=0.25, pas_long=0.5):
    tris, _ = P.triangles_du_glb(chemin)
    grille = P.Grille(tris)
    carte = P.carte_du_plancher(grille, pas_long, None, profil,
                                pas_lateral_m=pas_lateral)
    return sum(l["absents"] for l in carte), carte


# ---------------------------------------------------------------------------
# LES ÉPREUVES
# ---------------------------------------------------------------------------

def epreuve_1_symetrique(journal, dossier):
    """Sur une coque SYMÉTRIQUE, ancien et nouvel échantillonnage coïncident.

    C'est l'épreuve de NON-RÉGRESSION de la correction elle-même. Une
    correction qui déplace des points là où le profil est droit n'est pas une
    correction : c'est un second défaut, qui rendrait incomparables toutes
    les mesures antérieures.
    """
    journal.epreuve("1", "coque SYMETRIQUE : ancien et nouvel "
                         "echantillonnage IDENTIQUES")
    stations = stations_droites()
    profil = profil_de(stations, "droit")
    # ANCIEN : fractions de `hw`, decalees le long de X.
    anciens = []
    u = 0.0
    while u <= len(profil.cavite) - 1 + 1e-9:
        ax, ay, hw, cle, palier = profil.station(u)
        for f in (-0.60, -0.30, 0.0, 0.30, 0.60):
            anciens.append((round(ax + f * hw, 6), round(ay, 6)))
        u += 0.5
    # NOUVEAU : offsets metriques le long de la NORMALE. Sur un profil droit
    # oriente +Y, la normale est (1, 0) : les deux doivent coincider aux
    # memes fractions.
    nouveaux = []
    u = 0.0
    while u <= len(profil.cavite) - 1 + 1e-9:
        ax, ay, hw, cle, palier = profil.station(u)
        nx, ny = profil.normale(u)
        for f in (-0.60, -0.30, 0.0, 0.30, 0.60):
            lat = f * profil.demi_largeur(u, f)
            nouveaux.append((round(ax + lat * nx, 6), round(ay + lat * ny, 6)))
        u += 0.5
    ecart = max((math.hypot(a[0] - b[0], a[1] - b[1])
                 for a, b in zip(anciens, nouveaux)), default=0.0)
    journal.dire("   %d point(s) compares, ecart maximal %.2e m"
                 % (len(anciens), ecart))
    # SABOTAGE : une asymetrie de 1,8 doit FAIRE DIVERGER les deux.
    stations_b = stations_asym(gauche=2.70, droite=1.50)
    profil_b = profil_de(stations_b, "asym")
    divergents = []
    u = 0.0
    while u <= len(profil_b.cavite) - 1 + 1e-9:
        ax, ay, hw, cle, palier = profil_b.station(u)
        nx, ny = profil_b.normale(u)
        for f in (-0.60, 0.60):
            ancien = ax + f * hw
            lat = f * profil_b.demi_largeur(u, f)
            divergents.append(abs(ancien - (ax + lat * nx)))
        u += 0.5
    divergence = max(divergents)
    journal.dire("   sur une coque ASYMETRIQUE, les deux divergent de %.3f m"
                 % divergence)
    journal.archiver("epreuve1_symetrie.txt",
                     "ecart symetrique %.3e m\ndivergence asymetrique %.3f m\n"
                     % (ecart, divergence))
    return journal.rouge_puis_vert(
        divergence > 0.30, ecart < 1e-9,
        "asymetrie 1,8 : les deux echantillonnages divergent de %.2f m"
        % divergence,
        "profil droit : ecart %.1e m, la correction ne deplace RIEN" % ecart)


def epreuve_2_asymetrique(journal, dossier):
    """Deux épaisseurs connues, et le bon côté nommé."""
    journal.epreuve("2", "coque ASYMETRIQUE a deux epaisseurs CONNUES")
    stations = stations_asym(gauche=2.20, droite=0.80)
    profil = profil_de(stations, "asym")
    chemin = ecrire_glb(os.path.join(dossier, "asym.glb"),
                        tunnel(stations, epaisseur_gauche=1.40,
                               epaisseur_droite=0.50))
    tris, _ = P.triangles_du_glb(chemin)
    grille = P.Grille(tris)
    u = 4.0
    ax, ay, _, _, _ = profil.station(u)
    nx, ny = profil.normale(u)
    depart = (ax, ay, profil.sol(u, 0.0) + 0.90)
    mesures = {}
    for nom, signe, pose in (("gauche", -1.0, 1.40), ("droite", 1.0, 0.50)):
        liste = P.impacts(grille, depart, (signe * nx, signe * ny, 0.0))
        if len(liste) >= 2:
            mesures[nom] = (liste[1][0] - liste[0][0], pose)
        else:
            mesures[nom] = (None, pose)
    for nom in ("gauche", "droite"):
        mesuree, pose = mesures[nom]
        journal.dire("   cote %-7s epaisseur posee %.2f m, mesuree %s m"
                     % (nom, pose,
                        ("%.3f" % mesuree) if mesuree is not None else "AUCUNE"))
    justes = all(m is not None and abs(m - p) < 0.12
                 for m, p in mesures.values())
    # SABOTAGE : ECHANGER les deux epaisseurs doit ECHANGER le verdict. Sans
    # cette moitie, une convention de cote inversee passerait par chance.
    chemin_b = ecrire_glb(os.path.join(dossier, "asym_echange.glb"),
                          tunnel(stations, epaisseur_gauche=0.50,
                                 epaisseur_droite=1.40))
    tris_b, _ = P.triangles_du_glb(chemin_b)
    grille_b = P.Grille(tris_b)
    echange = {}
    for nom, signe in (("gauche", -1.0), ("droite", 1.0)):
        liste = P.impacts(grille_b, depart, (signe * nx, signe * ny, 0.0))
        echange[nom] = (liste[1][0] - liste[0][0]) if len(liste) >= 2 else None
    journal.dire("   apres ECHANGE : gauche %s m, droite %s m"
                 % (("%.3f" % echange["gauche"]) if echange["gauche"] else "-",
                    ("%.3f" % echange["droite"]) if echange["droite"] else "-"))
    inverse = (echange["gauche"] is not None and echange["droite"] is not None
               and echange["gauche"] < echange["droite"])
    journal.archiver("epreuve2_asymetrie.json",
                     json.dumps(dict(pose=dict(gauche=1.40, droite=0.50),
                                     mesure={k: v[0] for k, v in mesures.items()},
                                     echange=echange), indent=1))
    return journal.rouge_puis_vert(
        inverse, justes,
        "epaisseurs echangees : le verdict s'echange aussi",
        "epaisseurs rendues a 0,12 m pres, du bon cote")


def _epreuve_trou(journal, numero, face, titre, dossier, demi=0.55):
    """Sabotage d'une face, ROUGE mesuré, restauration prouvée, VERT."""
    journal.epreuve(numero, titre)
    stations = stations_asym(gauche=2.20, droite=0.80)
    profil = profil_de(stations, "asym")
    intact = os.path.join(dossier, "intact_%s.glb" % face)
    ecrire_glb(intact, tunnel(stations))
    avant = empreinte(intact)
    perce = os.path.join(dossier, "perce_%s.glb" % face)
    ecrire_glb(perce, tunnel(stations, trous=((4, face, demi),)))
    n_perce, s_perce, o_perce = compter_percees(perce, profil)
    n_intact, s_intact, o_intact = compter_percees(intact, profil)
    journal.dire("   perce  : %d percee(s) confirmee(s), %d suspect(s), "
                 "ouverture max %.3f m" % (n_perce, s_perce, o_perce))
    journal.dire("   intact : %d percee(s) confirmee(s), %d suspect(s), "
                 "ouverture max %.3f m" % (n_intact, s_intact, o_intact))
    # RESTAURATION : on reecrit la geometrie intacte et on prouve par sha256
    # qu'elle est bien celle d'avant.
    ecrire_glb(intact, tunnel(stations))
    apres = empreinte(intact)
    journal.restauration(avant, apres)
    journal.archiver("epreuve%s_%s.json" % (numero, face),
                     json.dumps(dict(face=face, demi_cote_m=demi,
                                     perce=dict(confirmees=n_perce,
                                                suspects=s_perce,
                                                ouverture=o_perce),
                                     intact=dict(confirmees=n_intact,
                                                 suspects=s_intact,
                                                 ouverture=o_intact),
                                     sha_avant=avant, sha_apres=apres),
                                indent=1))
    return journal.rouge_puis_vert(
        n_perce > 0, n_intact == 0,
        "trou de %.2f m sur %s : %d percee(s) confirmee(s)"
        % (2 * demi, face, n_perce),
        "geometrie intacte : %d percee(s)" % n_intact)


## LE MAILLAGE MESURE — RELATIF A LA RACINE DU DEPOT, JAMAIS ABSOLU.
##
## Ce chemin valait `/home/user/zelda-r2a352/b_collerette/assets/...` : un
## worktree ETRANGER, d'une passe precedente, hors du socle. Le jour ou il a
## ete mesure il portait par chance le meme sha256 que le candidat du socle
## (`cc3596c5`), donc l'epreuve 5 mesurait la bonne chose — PAR CHANCE. Rien
## ne le garantissait : il suffisait qu'on regenere l'autre worktree pour que
## la suite rende un verdict precis, plausible, et portant sur une geometrie
## que personne n'avait sous les yeux. C'est la famille exacte du piege
## consigne dans `tools/CLAUDE.md` — « avant de mesurer un artefact, prouver
## qu'il vient d'etre produit » — et celle d'ISS-018 : mesurer avec assurance
## quelque chose qui n'est pas ce qu'on croit.
##
## Deux consequences, et la seconde compte autant que la premiere :
##
##   * le chemin est calcule depuis `__file__`, donc chaque worktree mesure
##     SON maillage. Un chemin absolu ferait revenir le defaut au premier
##     worktree suivant ;
##   * l'empreinte est IMPRIMEE a chaque execution, et n'est PAS epinglee.
##     L'imprimer rend une substitution visible ; l'epingler transformerait
##     cette suite en obstacle des que la geometrie sera corrigee — et une
##     epreuve adversariale qui interdit de corriger le sujet a change de
##     camp.
RACINE_DEPOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAILLAGE_COLLERETTE = os.path.join(
    RACINE_DEPOT, "assets", "environment", "caves", "SM_WaterfallCave.glb")

## La matiere que l'agent collerette a livree, et la SEULE que l'epreuve 5
## a le droit d'amputer. Voir `matiere_par_triangle` juste dessous pour
## pourquoi il a fallu l'ecrire.
MATIERE_COLLERETTE = "MAT_CaveRock_Collar"

## Les matieres de la PEAU DE CAVITE. Elles servent a deux choses distinctes
## qu'il ne faut pas confondre : (1) EXCLURE ces sommets du sabotage, pour
## que le masque d'ouverture ne puisse pas bouger ; (2) fournir la surface
## de reference de la mesure independante `epaisseur_a_la_cavite`.
PREFIXE_CAVITE = "MAT_CaveIn_"


def matiere_par_triangle(chemin, noeud_voulu="SM_WaterfallCave"):
    """Nom de matiere de CHAQUE triangle, dans l'ordre de `triangles_du_glb`.

    POURQUOI CETTE FONCTION EXISTE — un defaut mesure le 2026-08-16.

    `P.triangles_du_glb` rend `(triangles, par_matiere)` ou `par_matiere` est
    un DICTIONNAIRE nom -> compte. Il dit combien de triangles porte chaque
    matiere ; il ne dit pas LESQUELS. L'epreuve 5 croyait donc amputer
    `MAT_CaveRock_Collar` — sa docstring le disait — et retirait en realite
    1440 triangles TOUTES MATIERES CONFONDUES dans une boite de 3 m :
    `MAT_CaveRock_Face` (7093 tri au total) et `MAT_CaveRock_Base` (8081)
    tombaient avec la collerette (3750).

    Un sabotage qui ne sait pas ce qu'il a retire ne prouve rien de ce qu'il
    croit prouver. C'est la meme famille que le piege deja consigne dans
    `tools/CLAUDE.md` : « le sabotage doit retirer la chose testee, pas ce
    qui est en dessous ».

    On refait donc le parcours des primitives — la MEME boucle que
    `triangles_du_glb`, y compris son `range(0, len(indices) - 2, 3)`, pour
    que les index coincident exactement — et on etiquette. La coincidence
    est VERIFIEE par une assertion plutot que supposee.
    """
    gltf, binaire = P.lire_glb(chemin)
    maillage = None
    for noeud in gltf.get("nodes", []):
        if noeud.get("name") == noeud_voulu:
            maillage = gltf["meshes"][noeud["mesh"]]
            break
    if maillage is None:
        raise P.Blocage("noeud %s absent de %s" % (noeud_voulu, chemin))
    materiaux = [m.get("name", "?") for m in gltf.get("materials", [])]
    etiquettes = []
    for prim in maillage["primitives"]:
        if "indices" in prim:
            n = len(P.lire_accessor(gltf, binaire, prim["indices"]))
        else:
            n = len(P.lire_accessor(gltf, binaire,
                                    prim["attributes"]["POSITION"]))
        nom = (materiaux[prim["material"]]
               if prim.get("material") is not None else "(sans matiere)")
        etiquettes.extend([nom] * len(range(0, n - 2, 3)))
    return etiquettes


# ---------------------------------------------------------------------------
# BOITE A OUTILS DU SABOTAGE PAR DEPLACEMENT
#
# POURQUOI CETTE SECTION EXISTE — le fait mesure qui a coule l'epreuve 5.
#
# Trois ablations ont ete essayees au tour precedent, et AUCUNE ne pouvait
# mordre :
#
#   * retirer 164 triangles de `MAT_CaveRock_Collar` laisse A et B
#     STRICTEMENT inchangees — la matiere nommee ne porte pas la mesure ;
#   * retirer 101 triangles au goulot fait MONTER B (1,1000 -> 1,1107),
#     parce que l'emprise de B EST l'ouverture : la roche retiree devient de
#     l'air, l'ouverture retrecit (3625 -> 3515 cases) et son point le plus
#     mince disparait AVEC elle. B n'est pas monotone sous ablation locale ;
#   * retirer la peau exterieure dans une direction DEVINEE n'a retire qu'un
#     seul triangle : la direction etait fausse (voir `bande_du_goulot`).
#
# La conclusion n'est pas « l'instrument est aveugle », elle est « l'ablation
# est le mauvais outil ». Retirer des triangles OUVRE le maillage ; la parite
# n'y definit plus de dedans, et tout instrument qui vote ou compte des
# croisements devient indefini.
#
# Le sabotage correct DEPLACE des sommets sans toucher au tampon d'indices.
# La topologie est alors identique par construction — donc la fermeture
# aussi — et on le VERIFIE plutot que de l'argumenter, parce qu'un controle
# qui repose sur un argument de construction est exactement ce que cette
# passe demonte.
# ---------------------------------------------------------------------------

## Grille de soudure. Le maillage porte SIX primitives (une par matiere) qui
## dupliquent leurs sommets le long des coutures. Deplacer un coin sans son
## jumeau dechirerait la surface : on soude donc par position arrondie, et
## les jumeaux bougent ensemble.
PAS_SOUDURE_M = 1.0e-5


def cle_soudure(sommet):
    return tuple(int(round(sommet[k] / PAS_SOUDURE_M)) for k in range(3))


def souder(triangles):
    """`cle -> [(indice_triangle, indice_coin), ...]`, et la position."""
    groupes = {}
    for ti, tri in enumerate(triangles):
        for ci in range(3):
            groupes.setdefault(cle_soudure(tri[ci]), []).append((ti, ci))
    return groupes


def fermeture(triangles):
    """`(sommets, aretes, {degre: compte})` sur les sommets SOUDES.

    Une arete de degre 2 est une arete interieure d'une surface fermee ; tout
    autre degre est un bord ou une non-variete. On mesure sur les sommets
    soudes et non sur les indices du GLB, sinon les coutures entre primitives
    compteraient comme des bords et la mesure serait fausse dans le sens qui
    rassure — le pire.
    """
    index = {}
    aretes = {}
    for tri in triangles:
        trio = []
        for ci in range(3):
            cle = cle_soudure(tri[ci])
            if cle not in index:
                index[cle] = len(index)
            trio.append(index[cle])
        a, b, c = trio
        for u, v in ((a, b), (b, c), (c, a)):
            paire = (u, v) if u < v else (v, u)
            aretes[paire] = aretes.get(paire, 0) + 1
    degres = {}
    for compte in aretes.values():
        degres[compte] = degres.get(compte, 0) + 1
    return len(index), len(aretes), degres


def distance2_point_triangle(point, tri):
    """Carre de la distance EXACTE d'un point a un triangle plein.

    Region de Voronoi classique (Ericson) : sommets, aretes, puis interieur.
    Aucun rayon, aucune grille, aucune parite — c'est la propriete qui rend
    cette mesure independante de A comme de B.
    """
    a, b, c = tri
    ab = [b[k] - a[k] for k in range(3)]
    ac = [c[k] - a[k] for k in range(3)]
    ap = [point[k] - a[k] for k in range(3)]
    d1 = sum(ab[k] * ap[k] for k in range(3))
    d2 = sum(ac[k] * ap[k] for k in range(3))
    if d1 <= 0.0 and d2 <= 0.0:
        return sum(ap[k] * ap[k] for k in range(3))
    bp = [point[k] - b[k] for k in range(3)]
    d3 = sum(ab[k] * bp[k] for k in range(3))
    d4 = sum(ac[k] * bp[k] for k in range(3))
    if d3 >= 0.0 and d4 <= d3:
        return sum(bp[k] * bp[k] for k in range(3))
    vc = d1 * d4 - d3 * d2
    if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
        v = d1 / (d1 - d3) if (d1 - d3) != 0.0 else 0.0
        return sum((ap[k] - v * ab[k]) ** 2 for k in range(3))
    cp = [point[k] - c[k] for k in range(3)]
    d5 = sum(ab[k] * cp[k] for k in range(3))
    d6 = sum(ac[k] * cp[k] for k in range(3))
    if d6 >= 0.0 and d5 <= d6:
        return sum(cp[k] * cp[k] for k in range(3))
    vb = d5 * d2 - d1 * d6
    if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
        w = d2 / (d2 - d6) if (d2 - d6) != 0.0 else 0.0
        return sum((ap[k] - w * ac[k]) ** 2 for k in range(3))
    va = d3 * d6 - d5 * d4
    if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
        den = (d4 - d3) + (d5 - d6)
        w = (d4 - d3) / den if den != 0.0 else 0.0
        return sum((bp[k] + w * (cp[k] - bp[k])) ** 2 for k in range(3))
    den = va + vb + vc
    v, w = vb / den, vc / den
    return sum((ap[k] - v * ab[k] - w * ac[k]) ** 2 for k in range(3))


def epaisseur_a_la_cavite(point, triangles_cavite):
    """LA MESURE INDEPENDANTE. Distance du point a la peau de cavite.

    C'est l'epaisseur physique de roche a cet endroit, obtenue par distance
    point-triangle exacte. Elle ne partage AUCUN mecanisme avec les deux
    mesures qu'elle sert a controler :

        A  = rayons + normale locale + parite  -> aucun rayon ici ;
        B  = rasterisation + inondation 2D + transformee de distance
             -> aucune grille, aucune inondation ici.

    Sans elle, un rouge pourrait venir d'autre chose que de ce qu'on croit
    tester, et un vert d'un sabotage qui n'a rien fait. C'est la regle qui
    manquait au tour precedent.
    """
    return math.sqrt(min(distance2_point_triangle(point, t)
                         for t in triangles_cavite))


def _segment_coupe_triangle(p0, p1, tri, marge=1.0e-7):
    """Möller-Trumbore borne au segment, bords EXCLUS par `marge`."""
    a, b, c = tri
    e1 = [b[k] - a[k] for k in range(3)]
    e2 = [c[k] - a[k] for k in range(3)]
    d = [p1[k] - p0[k] for k in range(3)]
    h = [d[1] * e2[2] - d[2] * e2[1],
         d[2] * e2[0] - d[0] * e2[2],
         d[0] * e2[1] - d[1] * e2[0]]
    det = sum(e1[k] * h[k] for k in range(3))
    if abs(det) < 1.0e-14:
        return False
    inv = 1.0 / det
    s = [p0[k] - a[k] for k in range(3)]
    u = inv * sum(s[k] * h[k] for k in range(3))
    if u <= marge or u >= 1.0 - marge:
        return False
    q = [s[1] * e1[2] - s[2] * e1[1],
         s[2] * e1[0] - s[0] * e1[2],
         s[0] * e1[1] - s[1] * e1[0]]
    v = inv * sum(d[k] * q[k] for k in range(3))
    if v <= marge or u + v >= 1.0 - marge:
        return False
    t = inv * sum(e2[k] * q[k] for k in range(3))
    return marge < t < 1.0 - marge


def auto_intersections(triangles, indices_touches):
    """Compte les traversees franches entre triangles deplaces et voisins.

    Le coordinateur a raison d'exiger la MESURE : « pondération lisse, donc
    pas d'auto-intersection » est un argument de construction, et cette passe
    existe pour demonter les arguments de construction. On teste donc les
    trois aretes de chaque triangle deplace contre les triangles voisins, en
    ecartant les paires qui PARTAGENT un sommet soude — deux triangles
    adjacents se touchent legitimement, et les compter serait fabriquer une
    alarme.
    """
    grille = P.Grille(triangles)
    sommets = [set(cle_soudure(s) for s in tri) for tri in triangles]
    trouves = 0
    exemples = []
    for ti in indices_touches:
        tri = triangles[ti]
        for ci in range(3):
            p0, p1 = tri[ci], tri[(ci + 1) % 3]
            longueur = math.sqrt(sum((p1[k] - p0[k]) ** 2 for k in range(3)))
            if longueur < 1.0e-9:
                continue
            direction = tuple((p1[k] - p0[k]) / longueur for k in range(3))
            for tj in grille.candidats(p0, direction, longueur):
                if tj == ti or sommets[ti] & sommets[tj]:
                    continue
                if _segment_coupe_triangle(p0, p1, triangles[tj]):
                    trouves += 1
                    if len(exemples) < 5:
                        exemples.append((ti, tj))
    return trouves, exemples


def bande_du_goulot(coupe, point):
    """Ou est l'air libre le PLUS PROCHE du goulot, et dans quelle direction.

    MESUREE, PAS DEVINEE — et c'est tout l'ecart avec le sabotage 3 du tour
    precedent, qui prenait la direction « du centre de l'ouverture vers le
    goulot », trouvait (0,68 ; -0,74), et ne retirait qu'UN triangle parce
    que la vraie direction est (1,00 ; 0,04), c'est-a-dire +X presque pur.
    Une direction devinee avait 90 degres d'erreur et personne ne pouvait
    le voir dans le journal.
    """
    pas, x0, z0 = coupe["pas"], coupe["x0"], coupe["z0"]
    libre = coupe["libre"]
    gi = int(round((point[0] - x0) / pas))
    gk = int(round((point[1] - z0) / pas))
    meilleur = None
    for i in range(coupe["nx"]):
        for k in range(coupe["nz"]):
            if not libre[i][k]:
                continue
            d = math.hypot(i - gi, k - gk)
            if meilleur is None or d < meilleur[0]:
                meilleur = (d, i, k)
    if meilleur is None:
        raise P.Blocage("aucune case d'air libre dans la coupe")
    d, ai, ak = meilleur
    air = (x0 + ai * pas, z0 + ak * pas)
    n = max(d, 1.0e-9)
    return dict(epaisseur_m=d * pas, air=air,
                direction=((ai - gi) / n, (ak - gk) / n))


def deplacer_vers(triangles, etiquettes, centre, direction, rayon, delta):
    """Deplace les sommets NON-CAVITE d'une boule, avec un fondu lisse.

    Le tampon d'indices n'est pas touche : seules des coordonnees changent.
    Deux garanties en decoulent, et la seconde est celle qui compte :

      * la fermeture est preservee par construction (verifiee quand meme) ;
      * les sommets de la peau de cavite sont EXCLUS, donc le bord de
        l'ouverture ne peut pas bouger. C'est ce qui separe « j'ai aminci la
        roche » de « j'ai deplace l'ouverture » — la confusion exacte qui a
        fait MONTER B au tour precedent.

    Le fondu `1 - 3u^2 + 2u^3` vaut 1 au centre, 0 au bord, et sa derivee
    s'annule aux deux bouts : pas de crete, pas de repli.
    """
    cavite = set()
    for tri, mat in zip(triangles, etiquettes):
        if mat.startswith(PREFIXE_CAVITE):
            for s in tri:
                cavite.add(cle_soudure(s))
    groupes = souder(triangles)
    neuf = [list(t) for t in triangles]
    bouges = []
    touches = set()
    for cle, coins in groupes.items():
        if cle in cavite:
            continue
        ti, ci = coins[0]
        s = triangles[ti][ci]
        r = math.sqrt(sum((s[k] - centre[k]) ** 2 for k in range(3)))
        if r >= rayon:
            continue
        u = r / rayon
        poids = 1.0 - 3.0 * u * u + 2.0 * u * u * u
        neuve = tuple(s[k] + delta * poids * direction[k] for k in range(3))
        for ti, ci in coins:
            neuf[ti][ci] = neuve
            touches.add(ti)
        bouges.append(dict(avant=s, apres=neuve, poids=poids))
    return [tuple(t) for t in neuf], bouges, sorted(touches)


def _mesure_b_au_plan(grille, y, pas=0.05):
    """Mesure B a un plan IMPOSE — pas de recul automatique.

    `C.mesurer()` avance dans la galerie tant que la section n'est pas une
    ouverture close, et c'est une propriete legitime de l'instrument. Mais
    elle rend la COMPARAISON avant/apres trompeuse : au dernier tour,
    l'epreuve 5 lisait `intact 1,1000 m (plan y -1,15)` puis
    `ampute 0,1000 m (plan y -0,75)`. Deux plans differents ne comparent
    rien. On impose donc le plan des deux cotes, et on rapporte separement
    ce que le recul automatique aurait dit.
    """
    coupe = C.coupe_du_plan(grille, y, pas)
    b, point, cases = C.mesure_b(coupe)
    return b, point, cases


def epreuve_5_collerette(journal, dossier):
    """Collerette AMINCIE sur le MAILLAGE REEL, par deplacement -> rouge.

    POURQUOI CETTE EPREUVE A ETE RECONSTRUITE.

    Elle a echoue trois tours de suite, et jamais par un defaut de reglage :
    elle etait batie sur une ABLATION, et l'ablation ne peut pas mordre ici.
    Les trois faits, tous mesures et tous conserves plus bas comme telemetrie
    parce qu'un resultat negatif vaut mieux qu'un vert :

      * S1 — retirer 164 triangles de `MAT_CaveRock_Collar` laisse A et B
        STRICTEMENT inchangees. La matiere qui porte le NOM ne porte pas la
        MESURE ;
      * S2 — retirer 101 triangles au goulot fait MONTER B, de 1,1000 a
        1,1107. L'emprise de B EST l'ouverture : la roche retiree devient de
        l'air, l'ouverture retrecit (3625 -> 3515 cases), et son point le
        plus mince disparait avec elle ;
      * S3 — retirer la peau exterieure dans une direction DEVINEE n'a
        retire qu'un triangle : la direction etait fausse de 90 degres.

    Une epreuve batie sur « ablater donc la mesure tombe » ne peut donc pas
    fonctionner. Le verdict repose desormais sur un SABOTAGE PAR DEPLACEMENT
    qui conserve tout ce que l'ablation detruisait :

      connectivite ......... le tampon d'indices n'est pas touche
      fermeture ............ verifiee, pas supposee (aretes soudees)
      plan de mesure ....... impose des deux cotes
      masque d'ouverture ... les sommets de cavite sont EXCLUS du deplacement
      matiere porteuse ..... la bande est MESUREE, pas devinee

    Et surtout : le sabotage est PROUVE AVANT que la sonde ne parle, par une
    mesure independante — la distance point-triangle a la peau de cavite.
    Sans cette regle, un rouge peut venir d'autre chose que de ce qu'on croit
    tester, et un vert d'un sabotage qui n'a rien fait.

    Le maillage source n'est jamais reecrit : les variantes vivent en
    memoire, et la restauration se prouve par sha256 avant/apres.
    """
    journal.epreuve("5", "COLLERETTE AMINCIE sur le MAILLAGE REEL")
    if not os.path.isfile(MAILLAGE_COLLERETTE):
        journal.dire("   BLOQUE : maillage introuvable : %s"
                     % MAILLAGE_COLLERETTE)
        journal.courante["rouge"] = False
        journal.courante["vert"] = False
        journal.echecs.append("5 — maillage absent : %s" % MAILLAGE_COLLERETTE)
        return False
    avant = empreinte(MAILLAGE_COLLERETTE)
    tris, _ = P.triangles_du_glb(MAILLAGE_COLLERETTE)
    etiquettes = matiere_par_triangle(MAILLAGE_COLLERETTE)
    if len(etiquettes) != len(tris):
        raise P.Blocage("etiquetage desaligne : %d etiquettes pour %d "
                        "triangles" % (len(etiquettes), len(tris)))
    ## L'EMPREINTE EST IMPRIMEE, PAS EPINGLEE. Voir le commentaire de
    ## `MAILLAGE_COLLERETTE` : imprimer rend une substitution visible ;
    ## epingler interdirait de corriger la geometrie.
    journal.dire("   maillage mesure : %s" % MAILLAGE_COLLERETTE)
    journal.dire("   sha256 %s — %d triangles (empreinte IMPRIMEE, non "
                 "epinglee)" % (avant[:16], len(tris)))
    total_matiere = {}
    for nom in etiquettes:
        total_matiere[nom] = total_matiere.get(nom, 0) + 1
    journal.dire("   matieres : %s"
                 % ", ".join("%s %d" % (n, c)
                             for n, c in sorted(total_matiere.items())))

    cavite = [t for t, m in zip(tris, etiquettes)
              if m.startswith(PREFIXE_CAVITE)]
    if not cavite:
        raise P.Blocage("aucune matiere %s* : la mesure independante n'a pas "
                        "de surface de reference" % PREFIXE_CAVITE)
    y_impose = C.Y_BOUCHE_DEFAUT

    def _mesurer(liste):
        grille = P.Grille(liste)
        a, _ = C.mesure_a(grille, P.PROFIL_GROTTE, y_impose)
        b, point, cases = _mesure_b_au_plan(grille, y_impose)
        return dict(mesure_a_m=a, mesure_b_plan_impose_m=b, point_b=point,
                    cases_ouverture=cases, triangles=len(liste))

    def _dire(nom, m):
        journal.dire("   %-14s : A %s m | B %s m | ouverture %d case(s)"
                     % (nom,
                        ("%.4f" % m["mesure_a_m"])
                        if m["mesure_a_m"] is not None else "AUCUNE",
                        ("%.4f" % m["mesure_b_plan_impose_m"])
                        if m["mesure_b_plan_impose_m"] is not None
                        else "AUCUNE",
                        m["cases_ouverture"]))

    intact = _mesurer(tris)
    journal.dire("   plan de mesure impose : y %+.2f (les deux cotes)"
                 % y_impose)
    _dire("intact", intact)
    if intact["point_b"] is None:
        raise P.Blocage("mesure B sans point : impossible de viser le goulot")
    journal.dire("   goulot de B au (x %.2f, z %.2f)" % tuple(intact["point_b"]))

    som0, ar0, deg0 = fermeture(tris)
    journal.dire("   fermeture intacte : %d sommets soudes, %d aretes, "
                 "degres %s" % (som0, ar0, deg0))
    ferme_avant = (list(deg0.keys()) == [2])

    # -- OU EST LA BANDE, VRAIMENT. -------------------------------------
    grille0 = P.Grille(tris)
    coupe0 = C.coupe_du_plan(grille0, y_impose, 0.05)
    bande = bande_du_goulot(coupe0, intact["point_b"])
    dx, dz = bande["direction"]
    journal.dire("   bande MESUREE : goulot -> air libre en %.3f m, "
                 "direction (%.3f ; %.3f), air libre au (x %.2f, z %.2f)"
                 % (bande["epaisseur_m"], dx, dz,
                    bande["air"][0], bande["air"][1]))
    journal.dire("   (l'ancien S3 DEVINAIT (0.678 ; -0.735) : 90 degres "
                 "d'erreur, 1 seul triangle retire, et rien ne le criait)")

    # -- LE SABOTAGE : ON RAPPROCHE L'AIR LIBRE SANS PERCER. ------------
    #
    # On pousse la peau EXTERIEURE vers le goulot. La peau de cavite est
    # exclue, donc le bord de l'ouverture ne bouge pas : meme masque, meme
    # plan, et la roche entre les deux s'amincit vraiment.
    centre = (bande["air"][0], y_impose, bande["air"][1])
    direction = (-dx, 0.0, -dz)
    RAYON_M, DELTA_M = 1.00, 0.60
    sabote, bouges, touches = deplacer_vers(tris, etiquettes, centre,
                                            direction, RAYON_M, DELTA_M)
    journal.dire("   SABOTAGE — deplacement de %d sommet(s) soude(s) sur %d, "
                 "%d triangle(s) touche(s) ; centre (%.2f, %.2f, %.2f), "
                 "rayon %.2f m, amplitude %.2f m vers le goulot"
                 % (len(bouges), som0, len(touches), centre[0], centre[1],
                    centre[2], RAYON_M, DELTA_M))
    journal.dire("   AUCUN triangle retire : le tampon d'indices est "
                 "intact, seules des coordonnees changent.")

    # -- PREUVE 1 : LA FERMETURE TIENT. ---------------------------------
    som1, ar1, deg1 = fermeture(sabote)
    identique = (som1, ar1, deg1) == (som0, ar0, deg0)
    journal.dire("   fermeture sabotee : %d sommets, %d aretes, degres %s "
                 "-> %s" % (som1, ar1, deg1,
                            "IDENTIQUE" if identique else "CHANGEE"))

    # -- PREUVE 2 : PAS D'AUTO-INTERSECTION. ----------------------------
    croisements, exemples = auto_intersections(sabote, touches)
    journal.dire("   auto-intersections MESUREES sur les %d triangle(s) "
                 "deplace(s) : %d%s"
                 % (len(touches), croisements,
                    "" if not croisements else (" — exemples %s" % exemples)))

    # -- PREUVE 3 : LA MESURE INDEPENDANTE. -----------------------------
    #
    # Elle passe AVANT le verdict de la sonde. Si l'epaisseur physique n'a
    # pas baisse a l'endroit vise, aucun rouge de A ou de B ne compte.
    coeur = [b for b in bouges if b["poids"] >= 0.5]
    t_avant = [epaisseur_a_la_cavite(b["avant"], cavite) for b in coeur]
    t_apres = [epaisseur_a_la_cavite(b["apres"], cavite) for b in coeur]
    med = lambda v: sorted(v)[len(v) // 2]
    journal.dire("   MESURE INDEPENDANTE — distance point-triangle a la peau "
                 "de cavite,")
    journal.dire("   ni rayon (donc pas A), ni rasterisation (donc pas B), "
                 "sur les %d sommet(s) du coeur du patch :" % len(coeur))
    journal.dire("      minimum  %.3f -> %.3f m   (%+.3f)"
                 % (min(t_avant), min(t_apres), min(t_apres) - min(t_avant)))
    journal.dire("      mediane  %.3f -> %.3f m   (%+.3f)"
                 % (med(t_avant), med(t_apres), med(t_apres) - med(t_avant)))
    aminci = med(t_apres) < med(t_avant) - 0.05 and min(t_apres) > 0.0
    journal.dire("      => l'epaisseur physique a %s ; la peau exterieure "
                 "n'a PAS traverse la cavite (minimum %.3f m > 0)"
                 % ("BAISSE" if aminci else "N'A PAS BAISSE", min(t_apres)))

    # -- ET SEULEMENT MAINTENANT, LA SONDE. -----------------------------
    apres = _mesurer(sabote)
    _dire("aminci", apres)
    meme_ouverture = (apres["cases_ouverture"] == intact["cases_ouverture"])
    journal.dire("   MASQUE D'OUVERTURE : %d -> %d case(s) — %s"
                 % (intact["cases_ouverture"], apres["cases_ouverture"],
                    "INCHANGE, on a bien aminci la roche"
                    if meme_ouverture
                    else "CHANGE : on a deplace l'ouverture, pas la roche"))

    # -- LE MINIMUM DE A A-T-IL MIGRE DANS LE PATCH ? -------------------
    #
    # A tombe, mais il faut prouver que c'est POUR LA CAUSE ANNONCEE. On
    # refait la boucle de `mesure_a` et on regarde ou vit le rayon minimal :
    # si son second impact tombe dans le patch, A a trouve la paroi qu'on
    # vient d'amincir. Sinon, le rouge vient d'ailleurs et ne compte pas.
    def _ou_est_a(grille):
        profil, pire, ou = P.PROFIL_GROTTE, None, None
        u = 0.0
        while u <= 0.60 + 1e-9:
            ax, ay, _, _, _ = profil.station(u)
            nx, ny = profil.normale(u)
            depart = (ax, ay, profil.sol(u, 0.0) + 0.90)
            vide, _ = P.dans_le_vide(grille, depart)
            if not vide:
                u += 0.10
                continue
            for k in range(36):
                theta = 2.0 * math.pi * k / 36
                d = (nx * math.cos(theta), ny * math.cos(theta),
                     math.sin(theta))
                liste = P.impacts(grille, depart, d, 60.0)
                if len(liste) < 2:
                    continue
                entree, orient = liste[0]
                ep = None
                for t, o in liste[1:]:
                    if t - entree <= P.ECAILLE_M or o == orient:
                        continue
                    ep = t - entree
                    break
                if ep is None:
                    continue
                if pire is None or ep < pire:
                    pire = ep
                    ou = dict(u=round(u, 2),
                              azimut_deg=round(math.degrees(theta), 1),
                              impact1=[round(depart[i] + entree * d[i], 3)
                                       for i in range(3)],
                              impact2=[round(depart[i] + (entree + ep) * d[i],
                                             3) for i in range(3)])
            u += 0.10
        return pire, ou

    a0, ou0 = _ou_est_a(grille0)
    a1, ou1 = _ou_est_a(P.Grille(sabote))
    journal.dire("   minimum de A intact : %.4f m a u=%.2f az=%.1f deg, "
                 "2e impact %s" % (a0, ou0["u"], ou0["azimut_deg"],
                                   ou0["impact2"]))
    journal.dire("   minimum de A aminci : %.4f m a u=%.2f az=%.1f deg, "
                 "2e impact %s" % (a1, ou1["u"], ou1["azimut_deg"],
                                   ou1["impact2"]))
    dist_patch = math.sqrt(sum((ou1["impact2"][k] - centre[k]) ** 2
                               for k in range(3)))
    dans_patch = dist_patch <= RAYON_M
    journal.dire("   le 2e impact du nouveau minimum est a %.3f m du centre "
                 "du patch (rayon %.2f) — %s"
                 % (dist_patch, RAYON_M,
                    "DANS le patch : A est tombe pour la cause annoncee"
                    if dans_patch else "HORS du patch : cause NON etablie"))

    # -- TELEMETRIE : LES TROIS ABLATIONS QUI NE PEUVENT PAS MORDRE. ----
    #
    # Conservees integralement. Elles ne fondent AUCUN verdict — elles
    # expliquent pourquoi le verdict a change de mecanisme, et un resultat
    # negatif qu'on efface est un piege repose pour la session suivante.
    def _amputer(test):
        garde, n, par_mat = [], 0, {}
        for tri, nom_mat in zip(tris, etiquettes):
            bary = tuple(sum(s[k] for s in tri) / 3.0 for k in range(3))
            if test(bary, nom_mat):
                n += 1
                par_mat[nom_mat] = par_mat.get(nom_mat, 0) + 1
                continue
            garde.append(tri)
        return garde, n, par_mat

    journal.dire("   -- TELEMETRIE : les ablations du tour precedent, "
                 "conservees, aucun verdict --")
    gx, gz = intact["point_b"]
    g1, n1, _ = _amputer(
        lambda b, mat: (mat == MATIERE_COLLERETTE
                        and abs(b[1] - y_impose) <= 1.50
                        and abs(b[0]) <= 3.00 and -1.0 <= b[2] <= 3.50))
    a_s1 = _mesurer(g1)
    journal.dire("      S1 matiere nommee : %d tri retires -> A %.4f, "
                 "B %.4f, ouverture %d  [%s]"
                 % (n1, a_s1["mesure_a_m"], a_s1["mesure_b_plan_impose_m"],
                    a_s1["cases_ouverture"],
                    "INCHANGE" if abs(a_s1["mesure_b_plan_impose_m"]
                                      - intact["mesure_b_plan_impose_m"]) < 1e-9
                    else "deplace"))
    g2, n2, _ = _amputer(
        lambda b, mat: (abs(b[0] - gx) <= 0.45 and abs(b[2] - gz) <= 0.45
                        and abs(b[1] - y_impose) <= 1.20))
    a_s2 = _mesurer(g2)
    journal.dire("      S2 au goulot     : %d tri retires -> A %.4f, "
                 "B %.4f, ouverture %d  [B %s, ouverture RETRECIE]"
                 % (n2, a_s2["mesure_a_m"], a_s2["mesure_b_plan_impose_m"],
                    a_s2["cases_ouverture"],
                    "MONTE" if a_s2["mesure_b_plan_impose_m"]
                    > intact["mesure_b_plan_impose_m"] else "baisse"))
    som2, ar2, deg2 = fermeture(g2)
    journal.dire("      S2 fermeture     : degres %s -> le maillage est "
                 "OUVERT, la parite n'y definit plus de dedans" % deg2)

    journal.restauration(avant, empreinte(MAILLAGE_COLLERETTE))
    journal.archiver(
        "epreuve5_collerette.json",
        json.dumps(dict(
            maillage=MAILLAGE_COLLERETTE, sha256=avant,
            plan_impose_y=y_impose, total_par_matiere=total_matiere,
            intact=intact,
            fermeture_avant=dict(sommets=som0, aretes=ar0, degres=deg0),
            fermeture_apres=dict(sommets=som1, aretes=ar1, degres=deg1),
            bande_mesuree=bande,
            sabotage=dict(mecanisme="deplacement de sommets",
                          centre=list(centre), direction=list(direction),
                          rayon_m=RAYON_M, delta_m=DELTA_M,
                          sommets_deplaces=len(bouges),
                          triangles_touches=len(touches),
                          triangles_retires=0),
            auto_intersections=croisements,
            mesure_independante=dict(
                sommets=len(coeur),
                min_avant=min(t_avant), min_apres=min(t_apres),
                median_avant=med(t_avant), median_apres=med(t_apres)),
            apres=apres,
            minimum_a=dict(intact=ou0, aminci=ou1,
                           distance_au_patch_m=dist_patch,
                           dans_le_patch=dans_patch),
            telemetrie_ablations=dict(
                s1=dict(retires=n1, a=a_s1["mesure_a_m"],
                        b=a_s1["mesure_b_plan_impose_m"],
                        ouverture=a_s1["cases_ouverture"]),
                s2=dict(retires=n2, a=a_s2["mesure_a_m"],
                        b=a_s2["mesure_b_plan_impose_m"],
                        ouverture=a_s2["cases_ouverture"],
                        degres_fermeture=deg2))), indent=1))

    def _tombe(cle, marge=0.02):
        a, b = intact[cle], apres[cle]
        return a is not None and (b is None or b < a - marge)

    b_tombe, a_tombe = _tombe("mesure_b_plan_impose_m"), _tombe("mesure_a_m")

    ## LE ROUGE EXIGE LA CHAINE COMPLETE, PAS SEULEMENT UNE MESURE QUI BAISSE.
    ## Un rouge obtenu pendant que l'ouverture bouge, que le maillage s'ouvre
    ## ou que l'epaisseur physique n'a pas change serait « un rouge pour une
    ## autre raison » — et le cadrage le refuse explicitement.
    rouge = (ferme_avant and identique and croisements == 0 and aminci
             and meme_ouverture and b_tombe and a_tombe and dans_patch)
    vert = (intact["mesure_a_m"] is not None
            and intact["mesure_b_plan_impose_m"] is not None
            and ferme_avant)
    return journal.rouge_puis_vert(
        rouge, vert,
        "epaisseur physique mediane %.3f -> %.3f m (independante) ; "
        "B %.4f -> %.4f m ; A %.4f -> %.4f m ; ouverture %d -> %d ; "
        "fermeture identique ; %d auto-intersection(s)"
        % (med(t_avant), med(t_apres),
           intact["mesure_b_plan_impose_m"], apres["mesure_b_plan_impose_m"],
           intact["mesure_a_m"], apres["mesure_a_m"],
           intact["cases_ouverture"], apres["cases_ouverture"], croisements),
        "maillage livre au plan impose y %+.2f : A %.4f m, B %.4f m, "
        "surface fermee (%d aretes toutes de degre 2)"
        % (y_impose, intact["mesure_a_m"],
           intact["mesure_b_plan_impose_m"], ar0))


def epreuve_6_paroi_mince(journal, dossier):
    """Paroi latérale sous 0,80 m -> rouge."""
    journal.epreuve("6", "PAROI LATERALE amincie sous 0,80 m")
    stations = stations_asym(gauche=2.20, droite=0.80)
    profil = profil_de(stations, "asym")
    seuil = 0.80
    resultats = {}
    for nom, epaisseur in (("saine", 1.00), ("mince", 0.42)):
        chemin = os.path.join(dossier, "paroi_%s.glb" % nom)
        ecrire_glb(chemin, tunnel(stations, epaisseur_gauche=epaisseur,
                                  epaisseur_droite=1.00))
        tris, _ = P.triangles_du_glb(chemin)
        grille = P.Grille(tris)
        u = 4.0
        ax, ay, _, _, _ = profil.station(u)
        nx, ny = profil.normale(u)
        depart = (ax, ay, profil.sol(u, 0.0) + 0.90)
        liste = P.impacts(grille, depart, (-nx, -ny, 0.0))
        resultats[nom] = (liste[1][0] - liste[0][0]) if len(liste) >= 2 else None
        journal.dire("   paroi %-6s posee %.2f m, mesuree %s m  -> %s"
                     % (nom, epaisseur,
                        ("%.3f" % resultats[nom]) if resultats[nom] else "-",
                        "SOUS LE SEUIL" if resultats[nom] is not None
                        and resultats[nom] < seuil else "au-dessus"))
    journal.archiver("epreuve6_paroi.json", json.dumps(resultats, indent=1))
    return journal.rouge_puis_vert(
        resultats["mince"] is not None and resultats["mince"] < seuil,
        resultats["saine"] is not None and resultats["saine"] >= seuil,
        "0,42 m pose -> %.3f m mesure, sous le seuil de %.2f m"
        % (resultats["mince"] or 0.0, seuil),
        "1,00 m pose -> %.3f m mesure, au-dessus du seuil"
        % (resultats["saine"] or 0.0))


def epreuve_7_transformation(journal, dossier):
    """Rotation + translation + ÉCHELLE NON TRIVIALE.

    L'échelle est ce que l'épreuve précédente n'avait pas. Une chaîne de
    matrices qui ignore l'échelle donne un aller-retour parfait tant que
    l'échelle vaut 1 — c'est-à-dire tant qu'on ne l'éprouve pas. On prend
    donc 1,37, un nombre qui n'est ni 1, ni 2, ni l'inverse d'un entier :
    toute confusion entre multiplier et diviser se voit.
    """
    journal.epreuve("7", "TRANSFORMATION rotation + translation + ECHELLE "
                         "non triviale")
    lacet = math.radians(37.0)
    origine = (-106.0, 3.5, 3.5)
    echelle = 1.37
    cos, sin = math.cos(lacet), math.sin(lacet)

    def vers_monde(p):
        # modèle -> monde : échelle, puis lacet autour de Y, puis translation.
        x, y, z = p[0] * echelle, p[1] * echelle, p[2] * echelle
        # repère Godot : X = x, Y = z, Z = -y
        gx, gy, gz = x, z, -y
        rx = gx * cos + gz * sin
        rz = -gx * sin + gz * cos
        return (rx + origine[0], gy + origine[1], rz + origine[2])

    def vers_modele(p):
        gx = p[0] - origine[0]
        gy = p[1] - origine[1]
        gz = p[2] - origine[2]
        rx = gx * cos - gz * sin
        rz = gx * sin + gz * cos
        return (rx / echelle, -rz / echelle, gy / echelle)

    points = [(0.0, 0.0, 0.0), (1.5, -1.15, 0.8), (-2.2, 6.4, 2.1),
              (3.58, 3.17, -0.62), (0.22, 1.05, 0.84)]
    ecart_ar = max(max(abs(vers_modele(vers_monde(p))[k] - p[k])
                       for k in range(3)) for p in points)
    journal.dire("   aller-retour modele -> monde -> modele : ecart max %.2e m"
                 % ecart_ar)

    # UNE DISTANCE MESUREE DANS LES DEUX REPERES. Une echelle oubliee ne se
    # voit PAS sur un aller-retour (elle s'annule), elle se voit sur une
    # LONGUEUR. C'est le piege que cette epreuve vise.
    a, b = (0.0, 0.0, 0.0), (3.0, 4.0, 0.0)
    d_modele = math.dist(a, b)
    d_monde = math.dist(vers_monde(a), vers_monde(b))
    journal.dire("   distance en repere modele %.4f m, en repere monde %.4f m"
                 % (d_modele, d_monde))
    journal.dire("   rapport %.4f, echelle posee %.2f" % (d_monde / d_modele,
                                                          echelle))
    coherent = abs(d_monde / d_modele - echelle) < 1e-9

    # SABOTAGE : une transformation qui OUBLIE l'echelle doit faire diverger
    # la longueur, et l'aller-retour doit rester parfait — c'est justement ce
    # qui rend l'oubli invisible a qui ne mesure que l'aller-retour.
    def vers_monde_sans_echelle(p):
        gx, gy, gz = p[0], p[2], -p[1]
        return (gx * cos + gz * sin + origine[0], gy + origine[1],
                -gx * sin + gz * cos + origine[2])

    d_faux = math.dist(vers_monde_sans_echelle(a), vers_monde_sans_echelle(b))
    journal.dire("   transformation SANS echelle : distance monde %.4f m "
                 "(devrait etre %.4f)" % (d_faux, d_monde))
    rouge = abs(d_faux - d_monde) > 0.5
    journal.archiver("epreuve7_transformation.json",
                     json.dumps(dict(lacet_deg=37.0, echelle=echelle,
                                     origine=list(origine),
                                     aller_retour_m=ecart_ar,
                                     distance_modele=d_modele,
                                     distance_monde=d_monde,
                                     distance_sans_echelle=d_faux), indent=1))
    return journal.rouge_puis_vert(
        rouge, coherent and ecart_ar < 1e-9,
        "echelle omise : la longueur monde tombe a %.3f au lieu de %.3f"
        % (d_faux, d_monde),
        "aller-retour %.1e m et rapport de longueurs exactement %.2f"
        % (ecart_ar, echelle))


def epreuve_8_journal(journal, dossier):
    """Un acquittement ne peut pas etre imprime sous un `<-- TROU`.

    C'EST L'EPREUVE DE MON PROPRE DEFAUT. Le journal de la passe precedente
    portait, a trente lignes d'intervalle :

        y +3.06  station 7  .  0/1  ...  <-- TROU
        PASS — un sol existe sous chaque point sonde

    et la seconde ligne a ete recopiee dans un rapport. On n'eprouve donc
    pas ici une regle de lecture : on verifie que la machine REFUSE.
    """
    journal.epreuve("8", "JOURNAL — acquittement interdit sous un `<-- TROU`")
    # SABOTAGE : une section qui porte un marqueur de defaut.
    j = P.Journal()
    j.section("plancher")
    j("      y +3.06  station 7  .   0/1   <-- TROU")
    accepte_apres_trou = j.dire_pass("   PASS — un sol existe sous chaque "
                                     "point sonde")
    incoherences_apres = j.incoherences()
    journal.dire("   section portant un TROU : dire_pass rend %s, "
                 "incoherences %d"
                 % (accepte_apres_trou, len(incoherences_apres)))
    # CONTOURNEMENT : un site futur qui imprimerait sans passer par
    # dire_pass doit etre attrape quand meme par le rebalayage.
    j2 = P.Journal()
    j2.section("plancher")
    j2("      y +3.06  station 7  .   0/1   <-- TROU")
    j2("   PASS — imprime sans passer par dire_pass")
    contourne = len(j2.incoherences())
    journal.dire("   acquittement imprime SANS dire_pass : %d incoherence(s) "
                 "detectee(s) par le rebalayage" % contourne)
    # LA PORTEE EST LA SECTION, ET C'EST DELIBERE : un acquittement des
    # parois reste legitime pendant que le plancher est rouge.
    j3 = P.Journal()
    j3.section("plancher")
    j3("      y +3.06  station 7  .   0/1   <-- TROU")
    j3.section("parois")
    accepte_autre = j3.dire_pass("   PASS — aucun rayon ne sort des parois")
    journal.dire("   acquittement d'une AUTRE section : dire_pass rend %s "
                 "(la portee est la section, pas le journal entier)"
                 % accepte_autre)
    # VERT : sans marqueur, l'acquittement passe.
    j4 = P.Journal()
    j4.section("plancher")
    j4("      y +3.06  station 7  #####  5/5")
    accepte_propre = j4.dire_pass("   PASS — un sol existe sous chaque point")
    journal.dire("   section sans defaut : dire_pass rend %s, incoherences %d"
                 % (accepte_propre, len(j4.incoherences())))
    journal.archiver("epreuve8_journal.json",
                     json.dumps(dict(refus_apres_trou=not accepte_apres_trou,
                                     incoherences_apres=len(incoherences_apres),
                                     contournement_attrape=contourne,
                                     autre_section_acceptee=accepte_autre,
                                     section_propre_acceptee=accepte_propre),
                                indent=1))
    return journal.rouge_puis_vert(
        (not accepte_apres_trou) and len(incoherences_apres) > 0
        and contourne > 0,
        accepte_propre and accepte_autre,
        "sous un TROU : refus a la source ET rebalayage qui attrape le "
        "contournement",
        "sans TROU, et dans une autre section : l'acquittement passe")


def epreuve_9_intacte(journal, dossier):
    """Geometrie intacte restauree -> vert, sur les quatre faces a la fois."""
    journal.epreuve("9", "GEOMETRIE INTACTE restauree -> VERT")
    stations = stations_asym(gauche=2.20, droite=0.80)
    profil = profil_de(stations, "asym")
    chemin = os.path.join(dossier, "intacte_finale.glb")
    ecrire_glb(chemin, tunnel(stations))
    avant = empreinte(chemin)
    # SABOTAGE : les quatre faces percees ensemble.
    saccage = os.path.join(dossier, "saccage.glb")
    ecrire_glb(saccage, tunnel(stations, trous=(
        (2, "toit", 0.55), (4, "plancher", 0.55),
        (5, "gauche", 0.55), (6, "droite", 0.45))))
    n_sac, _, o_sac = compter_percees(saccage, profil)
    # RESTAURATION.
    ecrire_glb(chemin, tunnel(stations))
    apres = empreinte(chemin)
    n_int, s_int, o_int = compter_percees(chemin, profil)
    f_int, _ = fautes_plancher(chemin, profil)
    journal.dire("   quatre faces percees : %d percee(s), ouverture max %.3f m"
                 % (n_sac, o_sac))
    journal.dire("   restauree : %d percee(s), %d suspect(s), %d faute(s) de "
                 "plancher" % (n_int, s_int, f_int))
    journal.restauration(avant, apres)
    journal.archiver("epreuve9_intacte.json",
                     json.dumps(dict(saccage=n_sac, intacte=n_int,
                                     suspects=s_int, fautes_plancher=f_int,
                                     sha=avant), indent=1))
    return journal.rouge_puis_vert(
        n_sac > 0, n_int == 0 and f_int == 0,
        "quatre faces percees : %d percee(s) confirmee(s)" % n_sac,
        "geometrie restauree : 0 percee, 0 faute de plancher")


def epreuve_10_courbure(journal, dossier):
    """LA FIXTURE DE LA SEPTIEME OCCURRENCE, en TROIS bras.

    Une galerie COURBE dont le PLANCHER MONTE a la pente de la grotte
    reelle. Il faut les deux :

      * la courbure ecarte la normale de X, donc un echantillonnage le long
        de X sort de la cavite ou change de station ;
      * le plancher qui monte transforme cette erreur de placement en erreur
        de HAUTEUR mesurable. Sur un plancher plat, viser a cote ne se voit
        pas — et c'est pour cela que la faute a survecu six corrections.

    POURQUOI TROIS BRAS, ET PAS DEUX.

    Les deux premiers bras n'affirment qu'une chose : « l'ancien placement
    est mauvais ». En durcissant le rouge pour qu'une fluctuation 1/72 ne
    compte plus, on rend aussi plus difficile de REMARQUER QUE LE NOUVEAU
    EST CASSE. Poussee a la limite, l'epreuve deviendrait verte quoi qu'il
    arrive : l'anti-motif se serait simplement deplace d'un cran.

    Le troisieme bras ferme cette porte. Sur la MEME fixture percee d'un
    VRAI trou de plancher, le NOUVEAU placement doit fauter. S'il se tait,
    il est aveugle, et l'epreuve echoue. « L'ancien est mauvais » et « le
    nouveau est bon » sont deux affirmations differentes ; seule la seconde
    est un gate.
    """
    journal.epreuve("10", "COURBURE + PLANCHER MONTANT — fixture de la 7e "
                          "occurrence, TROIS bras")
    stations = stations_coudees()
    profil = profil_de(stations, "coude")
    chemin = os.path.join(dossier, "coude.glb")
    ecrire_glb(chemin, tunnel(stations))
    grille = P.Grille(P.triangles_du_glb(chemin)[0])

    # CE QUE VAUT LA FIXTURE, FACE A LA GROTTE REELLE.
    #
    # On mesure les deux et on publie les deux colonnes. Un recalage qu'on
    # ne montre pas est un reglage ; montre, c'est une decision verifiable.
    ecarts = []
    for i in range(len(stations)):
        nx, ny = profil.normale(float(i))
        ecarts.append(math.degrees(math.atan2(abs(ny), abs(nx))))
    ecarts_reels = []
    u = 0.0
    while u <= len(P.PROFIL_GROTTE.cavite) - 1 + 1e-9:
        nx, ny = P.PROFIL_GROTTE.normale(u)
        ecarts_reels.append(math.degrees(math.atan2(abs(ny), abs(nx))))
        u += 0.5
    stations_reelles = [(c[0], c[1], 0.0, 0.0,
                         -P.PROFIL_GROTTE.sol(float(i), 0.0), 0.0)
                        for i, c in enumerate(P.PROFIL_GROTTE.cavite)]
    moy_r, loc_r = pentes_du_profil(stations_reelles)
    moy_f, loc_f = pentes_du_profil(stations)
    journal.dire("   la fixture est RECALEE sur la grotte reelle, pas sur un "
                 "compte de fautes voulu :")
    journal.dire("      grandeur                | grotte reelle | fixture")
    journal.dire("      ecart de normale a X    | %5.1f deg max | %5.1f deg "
                 "max" % (max(ecarts_reels), max(ecarts)))
    journal.dire("      pente moyenne du sol    | %8.3f m/m | %8.3f m/m"
                 % (moy_r, moy_f))
    journal.dire("      pente locale maximale   | %8.3f m/m | %8.3f m/m"
                 % (loc_r, loc_f))
    journal.dire("   (la COURBURE n'a pas ete touchee : elle depassait deja "
                 "le reel. Seule la PENTE etait sous-modelee, d'un facteur "
                 "3,3, et c'est elle qui convertit un decalage axial en "
                 "erreur de hauteur.)")

    # À MÊME JEU DE POINTS — SEUL LE PLACEMENT CHANGE.
    #
    # La première version comparait 6 fautes sur 73 points à 5 sur 85. Deux
    # nombres qui ne portent pas sur le même échantillon ne comparent rien :
    # le dénominateur bougeait parce que les points de l'ancien placement
    # tombaient dans la roche et étaient sautés. L'épreuve mesurait donc à la
    # fois la perte de couverture ET l'erreur de hauteur, mélangées.
    PAS_U_CANONIQUE = 0.5
    F_CANONIQUE = (-0.60, -0.30, 0.0, 0.30, 0.60)

    def _couples(pas_u, fs):
        liste = []
        u = 0.0
        while u <= len(profil.cavite) - 1 + 1e-9:
            for f in fs:
                liste.append((u, f))
            u += pas_u
        return liste

    couples = _couples(PAS_U_CANONIQUE, F_CANONIQUE)

    def _place(u, f, le_long_de_x):
        ax, ay, hw, cle, palier = profil.station(u)
        nx, ny = profil.normale(u)
        if le_long_de_x:
            # ANCIEN : le long de X, demi-largeur SYMETRIQUE, sol lu a la
            # station NOMINALE.
            px, py = ax + f * hw, ay
            sol = profil.sol(u, f)
        else:
            # NOUVEAU : le long de la NORMALE, largeur du COTE, sol lu a la
            # station REELLE du point.
            lat = f * profil.demi_largeur(u, f)
            px, py = ax + lat * nx, ay + lat * ny
            sol = profil.sol(P.station_reelle_du_point(profil, (px, py, 0.0)), f)
        return (px, py, sol + 0.90)

    def _verdict(g, depart):
        """`(dans_le_vide, faute, erreur)`. L'ERREUR est la marge mesuree.

        Un compte de fautes seul ne dit pas de combien on a rate : deux
        epreuves a une faute peuvent etre a 1 mm et a 3 m de la tolerance.
        On rend donc l'ecart, et le verdict le publie.
        """
        vide, _ = P.dans_le_vide(g, depart)
        if not vide:
            return False, False, None
        liste = P.impacts(g, depart, (0.0, 0.0, -1.0))
        if not liste:
            return True, True, float("inf")
        erreur = liste[0][0] - 0.90
        return True, (erreur > P.PLANCHER_TOLERANCE_M), erreur

    def _compter(g, liste):
        v_a = v_n = com = 0
        err_a, err_n = [], []
        for u_c, f_c in liste:
            va, fa, ra = _verdict(g, _place(u_c, f_c, True))
            vn, fn, rn = _verdict(g, _place(u_c, f_c, False))
            v_a += 1 if va else 0
            v_n += 1 if vn else 0
            if va and vn:
                com += 1
                err_a.append(ra)
                err_n.append(rn)
        fautes = lambda e: [v for v in e if v > P.PLANCHER_TOLERANCE_M]
        return dict(vide_ancien=v_a, vide_nouveau=v_n, communs=com,
                    err_ancien=err_a, err_nouveau=err_n,
                    ancien=len(fautes(err_a)), nouveau=len(fautes(err_n)))

    def _texte(v):
        return "inf" if v == float("inf") else "%.3f" % v

    # ================= BRAS 1 — ROCHE SAINE, ANCIEN vs NOUVEAU ==========
    journal.dire("   -- BRAS 1 : roche SAINE, meme jeu de points, deux "
                 "placements --")
    r1 = _compter(grille, couples)
    journal.dire("   %d couple(s) (u, f) engendres UNE fois, deux placements"
                 % len(couples))
    journal.dire("   tombent dans le vide : ANCIEN %d, NOUVEAU %d"
                 % (r1["vide_ancien"], r1["vide_nouveau"]))
    journal.dire("   sur les %d couple(s) ou LES DEUX sont dans le vide :"
                 % r1["communs"])
    journal.dire("      ANCIEN  (X, largeur symetrique, station nominale) : "
                 "%d faute(s)" % r1["ancien"])
    journal.dire("      NOUVEAU (normale, largeur du cote, station reelle) : "
                 "%d faute(s)" % r1["nouveau"])
    journal.dire("   meme roche, meme jeu de points, meme denominateur : "
                 "l'ecart est entierement produit par le placement.")

    # LA MARGE — CE QUI MANQUAIT.
    #
    # `tolerance` n'est PAS touchee (0,25 m). On publie de combien on la
    # depasse, des deux cotes.
    pires = sorted(( v for v in r1["err_ancien"]
                     if v > P.PLANCHER_TOLERANCE_M), reverse=True)
    marge_ancien = ((pires[FAUTES_MIN_ANCIEN - 1] - P.PLANCHER_TOLERANCE_M)
                    if len(pires) >= FAUTES_MIN_ANCIEN else None)
    finis_n = [v for v in r1["err_nouveau"] if v != float("inf")]
    pire_nouveau = max(finis_n) if finis_n else float("inf")
    marge_nouveau = P.PLANCHER_TOLERANCE_M - pire_nouveau
    journal.dire("   MARGE (tolerance %.2f m, INCHANGEE) :"
                 % P.PLANCHER_TOLERANCE_M)
    journal.dire("      erreurs fautives de l'ANCIEN, decroissantes : %s"
                 % ", ".join(_texte(v) for v in pires))
    journal.dire("      il faut %d faute(s) : la %de plus grande erreur vaut "
                 "%s m, soit %s au-dessus de la tolerance"
                 % (FAUTES_MIN_ANCIEN, FAUTES_MIN_ANCIEN,
                    _texte(pires[FAUTES_MIN_ANCIEN - 1])
                    if len(pires) >= FAUTES_MIN_ANCIEN else "-",
                    ("+%.3f m" % marge_ancien) if marge_ancien is not None
                    else "AUCUNE MARGE"))
    journal.dire("      pire erreur du NOUVEAU : %s m, soit %.3f m SOUS la "
                 "tolerance" % (_texte(pire_nouveau), marge_nouveau))

    # ================= BRAS 2 — LE NOUVEAU DOIT VOIR UN VRAI TROU =======
    #
    # Sans ce bras, on aurait prouve « l'epreuve sait dire que l'ancien est
    # mauvais », pas « elle sait dire que le nouveau est bon ».
    journal.dire("   -- BRAS 2 (troisieme bras) : MEME fixture, VRAI trou de "
                 "plancher — le NOUVEAU doit fauter --")
    STATION_TROUEE, DEMI_TROU = 4, 0.55
    chemin_troue = os.path.join(dossier, "coude_troue.glb")
    ecrire_glb(chemin_troue,
               tunnel(stations, trous=((STATION_TROUEE, "plancher",
                                        DEMI_TROU),)))
    tris_sain, _ = P.triangles_du_glb(chemin)
    tris_troue, _ = P.triangles_du_glb(chemin_troue)
    journal.dire("   SABOTAGE : trou de %.2f m au plancher de la station %d "
                 "— %d triangle(s) retire(s) sur %d"
                 % (2 * DEMI_TROU, STATION_TROUEE,
                    len(tris_sain) - len(tris_troue), len(tris_sain)))
    r2 = _compter(P.Grille(tris_troue), couples)
    finis2 = [v for v in r2["err_nouveau"] if v != float("inf")]
    journal.dire("   sur les %d couple(s) communs : ANCIEN %d faute(s), "
                 "NOUVEAU %d faute(s)"
                 % (r2["communs"], r2["ancien"], r2["nouveau"]))
    journal.dire("   pire erreur du NOUVEAU sur roche percee : %s m "
                 "(tolerance %.2f) -> le nouveau placement %s"
                 % (_texte(max(r2["err_nouveau"]) if r2["err_nouveau"] else 0.0),
                    P.PLANCHER_TOLERANCE_M,
                    "VOIT le defaut" if r2["nouveau"] > 0
                    else "EST AVEUGLE"))

    # ================= ROBUSTESSE — TELEMETRIE ==========================
    journal.dire("   robustesse du BRAS 1 (telemetrie, ne fonde aucun "
                 "verdict) :")
    journal.dire("      pas_u | positions f            | communs | ANCIEN | "
                 "NOUVEAU")
    balayage = []
    for pas_u in (0.25, 0.5, 1.0):
        for etiquette, fs in (
                ("3 (-0,6 0 0,6)", (-0.60, 0.0, 0.60)),
                ("5 canonique", F_CANONIQUE),
                ("7 (+-0,15)", (-0.60, -0.30, -0.15, 0.0, 0.15, 0.30, 0.60))):
            r = _compter(grille, _couples(pas_u, fs))
            balayage.append(dict(pas_u=pas_u, positions=etiquette,
                                 communs=r["communs"], ancien=r["ancien"],
                                 nouveau=r["nouveau"]))
            journal.dire("      %5.2f | %-22s | %7d | %6d | %7d%s"
                         % (pas_u, etiquette, r["communs"], r["ancien"],
                            r["nouveau"],
                            "   <-- SOUS LE MINIMUM DE %d"
                            % FAUTES_MIN_ANCIEN
                            if r["ancien"] < FAUTES_MIN_ANCIEN else ""))
    faibles = [b for b in balayage if b["ancien"] < FAUTES_MIN_ANCIEN]
    bruyants = [b for b in balayage if b["nouveau"] > 0]
    journal.dire("      %d combinaison(s) sur %d sous le minimum de %d ; "
                 "%d ou le NOUVEAU fauterait."
                 % (len(faibles), len(balayage), FAUTES_MIN_ANCIEN,
                    len(bruyants)))

    journal.archiver("epreuve10_courbure.json", json.dumps(dict(
        tolerance_m=P.PLANCHER_TOLERANCE_M,
        fautes_min_ancien=FAUTES_MIN_ANCIEN,
        recalage=dict(
            ecart_normale_max_deg=dict(reel=max(ecarts_reels),
                                       fixture=max(ecarts)),
            pente_moyenne=dict(reel=moy_r, fixture=moy_f),
            pente_locale_max=dict(reel=loc_r, fixture=loc_f)),
        bras1=dict(couples=len(couples), communs=r1["communs"],
                   vide_ancien=r1["vide_ancien"],
                   vide_nouveau=r1["vide_nouveau"],
                   ancien=r1["ancien"], nouveau=r1["nouveau"],
                   erreurs_fautives_ancien=[_texte(v) for v in pires],
                   marge_ancien_m=marge_ancien,
                   pire_nouveau_m=_texte(pire_nouveau),
                   marge_nouveau_m=marge_nouveau),
        bras2=dict(station=STATION_TROUEE, demi_trou_m=DEMI_TROU,
                   triangles_retires=len(tris_sain) - len(tris_troue),
                   communs=r2["communs"], ancien=r2["ancien"],
                   nouveau=r2["nouveau"]),
        balayage_robustesse=balayage), indent=1))

    ## LE ROUGE EXIGE LES DEUX RAISONS DE ROUGIR.
    ##
    ## Bras 1 : l'ancien placement faute PLUSIEURS fois, avec une marge
    ## mesuree au-dessus d'une tolerance qu'on n'a pas touchee.
    ## Bras 2 : le nouveau placement voit un VRAI trou.
    ##
    ## Si le nouveau devenait aveugle, le bras 2 tomberait a zero et
    ## l'epreuve ECHOUERAIT — c'est exactement la porte que le troisieme
    ## bras ferme.
    rouge = (r1["ancien"] >= FAUTES_MIN_ANCIEN
             and marge_ancien is not None and marge_ancien > 0.0
             and r2["nouveau"] > 0)
    vert = (r1["nouveau"] == 0 and marge_nouveau > 0.0)
    return journal.rouge_puis_vert(
        rouge, vert,
        "BRAS 1 le long de X : %d faute(s) >= %d sur %d couples communs, "
        "marge +%s m au-dessus de la tolerance %.2f, roche saine — "
        "BRAS 2 trou reel : le NOUVEAU faute %d fois, il n'est pas aveugle"
        % (r1["ancien"], FAUTES_MIN_ANCIEN, r1["communs"],
           ("%.3f" % marge_ancien) if marge_ancien is not None else "AUCUNE",
           P.PLANCHER_TOLERANCE_M, r2["nouveau"]),
        "le long de la normale : %d faute(s) sur les MEMES %d couples, "
        "pire erreur %s m soit %.3f m sous la tolerance"
        % (r1["nouveau"], r1["communs"], _texte(pire_nouveau), marge_nouveau))


# ---------------------------------------------------------------------------
# MUTATIONS — LA PREUVE QUE CES EPREUVES SAVENT ENCORE ECHOUER
#
# POURQUOI CE BANC EXISTE.
#
# `docs/PROMPT4_METHOD.md` §2 nomme le mode d'echec : « le piege du test qui
# ne peut pas echouer ». Un test vert n'est pas une preuve ; un test qui
# ECHOUERAIT sans le correctif en est une. Les epreuves 5 et 10 viennent
# d'etre reconstruites : affirmer qu'elles savent rougir sans pouvoir le
# REJOUER retomberait exactement au niveau de ce qu'elles denoncent.
#
# Chaque mutation casse UNE chose, et le banc exige deux resultats, pas un :
#
#   1. l'epreuve doit ECHOUER — sinon la mutation n'est pas detectee ;
#   2. elle doit echouer POUR LA CAUSE ANNONCEE — verifiee dans le JSON
#      archive par l'epreuve, pas dans son texte. Une epreuve qui echoue
#      pour une autre raison ne prouve rien de sa falsifiabilite, et c'est
#      la meme regle que celle imposee aux sabotages eux-memes.
#
# M4 est la plus importante : elle est la SEULE a etablir que le troisieme
# bras de l'epreuve 10 est PORTEUR et non decoratif. Elle exige que le bras 1
# reste parfaitement vert pendant que l'epreuve echoue.
# ---------------------------------------------------------------------------


def _remplacer_global(nom, neuf):
    """Remplace un nom du module, et rend de quoi le remettre."""
    ancien = globals()[nom]
    globals()[nom] = neuf
    return lambda: globals().__setitem__(nom, ancien)


def _remplacer_dans(module, nom, neuf):
    ancien = getattr(module, nom)
    setattr(module, nom, neuf)
    return lambda: setattr(module, nom, ancien)


def _m1_amplitude_nulle():
    """Le sabotage ne deplace RIEN : l'epaisseur ne doit pas bouger."""
    origine = deplacer_vers
    return _remplacer_global(
        "deplacer_vers",
        lambda t, e, c, d, r, delta: origine(t, e, c, d, r, 0.0))


def _m2_sabotage_inverse():
    """Le sabotage EPAISSIT au lieu d'amincir."""
    origine = deplacer_vers
    return _remplacer_global(
        "deplacer_vers",
        lambda t, e, c, d, r, delta: origine(
            t, e, c, tuple(-v for v in d), r, delta))


def _m3_nouvel_echantillonnage_regresse():
    """Un des trois sous-correctifs est annule : le sol est relu a la
    station NOMINALE, comme avant. C'est la regression realiste."""
    return _remplacer_dans(P, "station_reelle_du_point",
                           lambda profil, point: 0.0)


def _m4_trou_du_troisieme_bras_supprime():
    """Le troisieme bras n'a plus rien a voir : le trou disparait."""
    origine = tunnel
    return _remplacer_global(
        "tunnel",
        lambda st, **kw: origine(
            st, **dict((k, v) for k, v in kw.items() if k != "trous")))


def _cause_m1(archive):
    avant = archive["mesure_independante"]["median_avant"]
    apres = archive["mesure_independante"]["median_apres"]
    return (abs(apres - avant) < 1.0e-9,
            "epaisseur mediane %.3f -> %.3f m : le sabotage n'a rien "
            "deplace" % (avant, apres))


def _cause_m2(archive):
    avant = archive["mesure_independante"]["median_avant"]
    apres = archive["mesure_independante"]["median_apres"]
    return (apres > avant + 0.05,
            "epaisseur mediane %.3f -> %.3f m : le sabotage a EPAISSI"
            % (avant, apres))


def _cause_m3(archive):
    n = archive["bras1"]["nouveau"]
    return (n > 0,
            "bras 1 : le NOUVEAU echantillonnage faute %d fois sur roche "
            "saine — la regression est vue" % n)


def _cause_m4(archive):
    b1, b2 = archive["bras1"], archive["bras2"]
    bras1_vert = (b1["ancien"] >= archive["fautes_min_ancien"]
                  and b1["nouveau"] == 0)
    return (bras1_vert and b2["nouveau"] == 0,
            "bras 1 INTACT (ancien %d >= %d, nouveau %d) et bras 2 muet "
            "(nouveau %d) : l'echec vient du SEUL troisieme bras, il est "
            "donc porteur" % (b1["ancien"], archive["fautes_min_ancien"],
                              b1["nouveau"], b2["nouveau"]))


def _cause_m0(archive):
    avant = archive["mesure_independante"]["median_avant"]
    apres = archive["mesure_independante"]["median_apres"]
    return (apres < avant - 0.05,
            "epaisseur mediane %.3f -> %.3f m : l'epreuve a bien tourne pour "
            "de vrai, et elle est restee verte" % (avant, apres))


## LE TEMOIN NEGATIF, ET POURQUOI IL EST PERMANENT.
##
## Un banc qui ne saurait dire que « DETECTEE » serait lui-meme un test qui
## ne peut pas echouer — l'anti-motif deplace d'un cran, ce qui est la facon
## habituelle dont il survit. M0 ne casse RIEN : l'epreuve doit donc rester
## VERTE, et le banc doit l'exiger. S'il declarait M0 « detectee », il
## declarerait n'importe quoi.
##
## `attendu` vaut donc "echec" pour les mutations reelles et "vert" pour le
## temoin. Un ecart dans un sens ou dans l'autre est un defaut.
MUTATIONS = (
    dict(code="M0", titre="TEMOIN NEGATIF — mutation INERTE",
         prouve="le banc REFUSE de crier au loup : rien de casse, donc vert",
         attendu="vert",
         poser=lambda: (lambda: None), epreuve=epreuve_5_collerette,
         archive="epreuve5_collerette.json", cause=_cause_m0),
    dict(code="M1", titre="epreuve 5 — sabotage d'amplitude NULLE",
         prouve="sans deplacement reel, aucun rouge n'est accorde",
         poser=_m1_amplitude_nulle, epreuve=epreuve_5_collerette,
         archive="epreuve5_collerette.json", cause=_cause_m1),
    dict(code="M2", titre="epreuve 5 — sabotage a l'ENVERS (epaissit)",
         prouve="un sabotage qui epaissit ne peut pas produire de rouge",
         poser=_m2_sabotage_inverse, epreuve=epreuve_5_collerette,
         archive="epreuve5_collerette.json", cause=_cause_m2),
    dict(code="M3", titre="epreuve 10 — NOUVEAU echantillonnage regresse",
         prouve="une regression du placement corrige est vue",
         poser=_m3_nouvel_echantillonnage_regresse,
         epreuve=epreuve_10_courbure,
         archive="epreuve10_courbure.json", cause=_cause_m3),
    dict(code="M4", titre="epreuve 10 — trou du 3e bras SUPPRIME",
         prouve="le troisieme bras est PORTEUR : bras 1 vert, epreuve rouge",
         poser=_m4_trou_du_troisieme_bras_supprime,
         epreuve=epreuve_10_courbure,
         archive="epreuve10_courbure.json", cause=_cause_m4),
)


def lancer_mutations(dossier):
    """Rejoue les quatre mutations. Rend le nombre de mutations NON detectees.

    La sortie des epreuves est capturee : elle est verbeuse, et ce qui
    importe ici est le verdict plus la cause. Elle est neanmoins ecrite dans
    le dossier de travail, pour qu'un desaccord se tranche sur piece.
    """
    print("=" * 74)
    print("MUTATIONS — les epreuves 5 et 10 savent-elles ENCORE echouer ?")
    print("=" * 74)
    print("dossier de travail : %s" % dossier)
    print("regle : une mutation doit faire ECHOUER l'epreuve, et l'echec")
    print("        doit venir de la CAUSE ANNONCEE — verifiee dans le JSON")
    print("        archive, pas dans le texte du journal.")
    manques = []
    resume = []
    for mutation in MUTATIONS:
        code = mutation["code"]
        sous = os.path.join(dossier, code.lower())
        if not os.path.isdir(sous):
            os.makedirs(sous)
        print()
        print("-" * 74)
        print("%s — %s" % (code, mutation["titre"]))
        print("     doit prouver : %s" % mutation["prouve"])
        print("-" * 74)
        journal = Journal(sous)
        tampon = io.StringIO()
        rendre = mutation["poser"]()
        try:
            with contextlib.redirect_stdout(tampon):
                verte = mutation["epreuve"](journal, sous)
        except Exception as erreur:                      # noqa: BLE001
            rendre()
            print("   BLOQUE : la mutation a leve %r" % (erreur,))
            manques.append("%s — exception" % code)
            resume.append((code, "BLOQUE"))
            continue
        finally:
            rendre()
        with open(os.path.join(sous, "%s.log" % code.lower()), "w",
                  encoding="utf-8") as poignee:
            poignee.write(tampon.getvalue())

        chemin_archive = os.path.join(sous, mutation["archive"])
        cause_ok, cause_texte = (False, "archive absente : %s"
                                 % chemin_archive)
        if os.path.isfile(chemin_archive):
            with open(chemin_archive, encoding="utf-8") as poignee:
                cause_ok, cause_texte = mutation["cause"](json.load(poignee))

        attendu = mutation.get("attendu", "echec")
        print("   attendu              : %s"
              % ("l'epreuve doit rester VERTE" if attendu == "vert"
                 else "l'epreuve doit ECHOUER"))
        print("   verdict de l'epreuve : %s" % ("VERTE" if verte else "ECHEC"))
        print("   cause mesuree        : %s" % cause_texte)
        print("   journal complet      : %s"
              % os.path.join(sous, "%s.log" % code.lower()))
        conforme = (verte if attendu == "vert" else not verte)
        if not conforme and attendu == "vert":
            print("   >>> DEFAUT : le temoin negatif a fait ECHOUER "
                  "l'epreuve — le banc crie au loup, ses autres verdicts ne "
                  "valent plus rien.")
            manques.append("%s — le temoin negatif a echoue" % code)
            resume.append((code, "TEMOIN CASSE"))
        elif not conforme:
            print("   >>> DEFAUT : l'epreuve reste verte sous cette "
                  "mutation — elle ne peut pas echouer.")
            manques.append("%s — l'epreuve reste VERTE" % code)
            resume.append((code, "NON DETECTEE"))
        elif not cause_ok:
            print("   >>> DEFAUT : verdict conforme, mais PAS pour la cause "
                  "annoncee — un resultat obtenu pour une autre raison ne "
                  "prouve rien.")
            manques.append("%s — verdict pour une autre cause" % code)
            resume.append((code, "MAUVAISE CAUSE"))
        else:
            resume.append((code, "TEMOIN OK" if attendu == "vert"
                           else "DETECTEE"))
            print("   OK — %s, et pour la bonne raison."
                  % ("temoin reste vert" if attendu == "vert"
                     else "detectee"))

    print()
    print("=" * 74)
    print("BILAN DES MUTATIONS")
    print("=" * 74)
    for code, etat in resume:
        print("   %-4s %s" % (code, etat))
    print()
    print("%d mutation(s) dont 1 temoin negatif, %d non conforme(s)"
          % (len(MUTATIONS), len(manques)))
    for m in manques:
        print("   DEFAUT %s" % m)
    with open(os.path.join(dossier, "mutations.json"), "w",
              encoding="utf-8") as poignee:
        json.dump(dict(resume=[dict(code=c, etat=e) for c, e in resume],
                       defauts=manques), poignee, indent=1,
                  ensure_ascii=False)
    print("bilan : %s" % os.path.join(dossier, "mutations.json"))
    return len(manques)


def main():
    ap = argparse.ArgumentParser(
        description="Epreuves adversariales des instruments de grotte.")
    ap.add_argument("--garder", default=None,
                    help="dossier ou conserver geometries et journaux")
    ap.add_argument("--mutations", action="store_true",
                    help="rejoue les quatre mutations et ECHOUE si l'une "
                         "d'elles laisse son epreuve VERTE")
    args = ap.parse_args()

    dossier = args.garder or tempfile.mkdtemp(prefix="cave_adv_")
    if not os.path.isdir(dossier):
        os.makedirs(dossier)

    ## LE BANC DE MUTATIONS EST UN MODE A PART, ET C'EST VOULU.
    ##
    ## Il ne mesure pas la geometrie : il mesure LES EPREUVES. Les melanger
    ## dans un seul bilan rendrait ambigu ce qu'un rouge accuse — la
    ## geometrie ou l'instrument. Deux questions, deux codes retour.
    if args.mutations:
        manques = lancer_mutations(dossier)
        if args.garder is None:
            print("(dossier temporaire conserve : %s)" % dossier)
        return 1 if manques else 0

    print("=" * 74)
    print("EPREUVES ADVERSARIALES — sabotage, rouge, archive, restauration, "
          "vert")
    print("=" * 74)
    print("dossier de travail : %s" % dossier)

    journal = Journal(dossier)
    try:
        epreuve_1_symetrique(journal, dossier)
        epreuve_2_asymetrique(journal, dossier)
        _epreuve_trou(journal, "3", "toit", "TROU dans le TOIT", dossier)
        _epreuve_trou(journal, "4", "plancher", "TROU dans le PLANCHER",
                      dossier)
        epreuve_5_collerette(journal, dossier)
        epreuve_6_paroi_mince(journal, dossier)
        epreuve_7_transformation(journal, dossier)
        epreuve_8_journal(journal, dossier)
        epreuve_9_intacte(journal, dossier)
        epreuve_10_courbure(journal, dossier)
    except Exception as erreur:                          # noqa: BLE001
        print()
        print("BLOQUE: une epreuve a leve une exception : %r" % (erreur,))
        import traceback
        traceback.print_exc()
        return 3

    print()
    print("=" * 74)
    print("BILAN")
    print("=" * 74)
    for e in journal.epreuves:
        etat = ("PASS" if e["rouge"] and e["vert"] else "FAIL")
        print("   %-3s %-58s %s" % (e["numero"], e["titre"][:58], etat))
    print()
    print("%d epreuve(s), %d echec(s)" % (len(journal.epreuves),
                                          len(journal.echecs)))
    for e in journal.echecs:
        print("   ECHEC %s" % e)
    with open(os.path.join(dossier, "bilan.json"), "w",
              encoding="utf-8") as poignee:
        json.dump(dict(epreuves=journal.epreuves, echecs=journal.echecs),
                  poignee, indent=1, ensure_ascii=False)
    print("bilan : %s" % os.path.join(dossier, "bilan.json"))
    if args.garder is None:
        print("(dossier temporaire conserve pour inspection : %s)" % dossier)
    return 1 if journal.echecs else 0


if __name__ == "__main__":
    sys.exit(main())
