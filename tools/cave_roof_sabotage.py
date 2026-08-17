#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CONTRÔLE NÉGATIF FERMÉ du contrôle d'épaisseur de domaine.

CE QU'IL FAUT PROUVER, ET POURQUOI C'EST DÉLICAT
================================================

Un contrôle qui n'a jamais rougi n'est pas un contrôle, c'est une opinion.
Mais le sabotage qui l'éprouve doit RETIRER LA CHOSE TESTÉE, et le cadrage
de la passe est formel sur le piège :

    « retirer des triangles OUVRE le maillage. La parité n'y définit plus
      de dedans, et tout instrument qui vote ou compte des croisements
      devient indéfini. »

Un maillage ouvert ferait rougir l'instrument POUR LA MAUVAISE RAISON, et
on en conclurait à tort qu'il voit les lames.

On sabote donc par DÉPLACEMENT DÉTERMINISTE DE SOMMETS, jamais par ablation :
la topologie est rigoureusement inchangée, donc le maillage reste fermé et
manifold — ce qui est vérifié et publié, pas supposé. On abaisse le toit
dans un disque, avec une décroissance douce, jusqu'à ce que le banc de roche
passe sous `EPAISSEUR_MIN_M` à l'endroit visé, et nulle part ailleurs par
accident.

Le protocole est en cinq temps, et chacun publie sa mesure :

    1. AVANT     : le point visé est épais -> l'instrument est VERT ici
    2. SABOTAGE  : N sommets déplacés, fermeture et manifold revérifiés
    3. MESURE INDEPENDANTE : l'épaisseur a-t-elle réellement baissé ?
    4. APRES     : l'instrument est ROUGE ici
    5. RESTAURATION : coordonnées remises, empreinte identique, VERT à nouveau

Usage (sous verrou) :
    blender --background --python-exit-code 1 \\
        --python tools/cave_roof_sabotage.py -- <glb> [ax,ay] [rayon] [chute]
"""

import hashlib
import struct
import sys

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

EPAISSEUR_MIN_M = 0.80      # LU, jamais modifié — c'est le seuil du contrat
VIDE_QUALIFIANT_M = 1.00
NOEUD_VISUEL = "SM_WaterfallCave"


def tranches_bvh(arbre, ax, ay, z_ciel, z_fond):
    """Même lecture que `_tranches_verticales` du générateur."""
    depart = Vector((ax, ay, z_ciel))
    direction = Vector((0.0, 0.0, -1.0))
    portee = z_ciel - z_fond
    impacts, parcouru = [], 0.0
    for _ in range(64):
        touche = arbre.ray_cast(depart, direction, portee - parcouru)
        if touche is None or touche[0] is None:
            break
        z, nz = touche[0].z, touche[1].z
        if abs(nz) > 1e-6:
            delta = +1 if nz > 0.0 else -1
            if not impacts or abs(impacts[-1][0] - z) > 1e-4 \
                    or impacts[-1][1] != delta:
                impacts.append((z, delta))
        parcouru += (touche[0] - depart).length + 1e-4
        depart = touche[0] + direction * 1e-4
        if parcouru >= portee:
            break
    brut, enl = [], 0
    for k in range(len(impacts) - 1):
        enl += impacts[k][1]
        brut.append(("roche" if enl >= 1 else "vide",
                     impacts[k][0], impacts[k + 1][0]))
    tr = []
    for nature, haut, bas in brut:
        if tr and tr[-1][0] == nature:
            tr[-1] = (nature, tr[-1][1], bas)
        else:
            tr.append((nature, haut, bas))
    return tr


def cumul(tranches):
    """(cumul de roche, hauteur du vide, bancs) au-dessus du vide qualifiant."""
    for k, (nature, haut, bas) in enumerate(tranches):
        if nature != "vide" or (haut - bas) < VIDE_QUALIFIANT_M:
            continue
        c = sum(h - b for n, h, b in tranches[:k] if n == "roche")
        bancs = sum(1 for n, _, _ in tranches[:k] if n == "roche")
        return (c, haut - bas, bancs)
    return None


def empreinte_coords(maillage):
    h = hashlib.sha256()
    for v in maillage.vertices:
        h.update(struct.pack("<3d", v.co.x, v.co.y, v.co.z))
    return h.hexdigest()


def integrite(obj):
    """(aretes de bord, aretes non-manifold). Doit rester (0, 0)."""
    maillage = obj.data
    compte = {}
    for poly in maillage.polygons:
        n = len(poly.vertices)
        for i in range(n):
            a, b = poly.vertices[i], poly.vertices[(i + 1) % n]
            cle = (a, b) if a < b else (b, a)
            compte[cle] = compte.get(cle, 0) + 1
    bord = sum(1 for v in compte.values() if v == 1)
    nm = sum(1 for v in compte.values() if v > 2)
    return bord, nm


def arbre_de(obj):
    return BVHTree.FromPolygons(
        [tuple(v.co) for v in obj.data.vertices],
        [tuple(p.vertices) for p in obj.data.polygons], all_triangles=False)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if not argv:
        print("[sab] usage: ... -- <glb> [ax,ay] [rayon] [chute]")
        return 2
    chemin = argv[0]
    ax, ay = [float(v) for v in (argv[1] if len(argv) > 1
                                 else "0.90,5.80").split(",")]
    rayon = float(argv[2]) if len(argv) > 2 else 0.45
    chute = float(argv[3]) if len(argv) > 3 else 1.10

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=chemin)
    objets = [o for o in bpy.context.scene.objects
              if o.type == "MESH" and o.name.startswith(NOEUD_VISUEL)]
    if len(objets) != 1:
        print("[sab] BLOQUE: %d maillage(s) nomme(s) %s*"
              % (len(objets), NOEUD_VISUEL))
        return 3
    obj = objets[0]
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # SOUDURE OBLIGATOIRE AVANT TOUTE MESURE DE TOPOLOGIE.
    # L'export glTF DÉDOUBLE les sommets par face (normales, UV) : le
    # maillage importé a 54 810 sommets pour 20 090 polygones, et aucune
    # arête n'est partagée. Un comptage d'arêtes par indices y voit alors
    # 54 812 « arêtes de bord » sur un solide parfaitement fermé, et le
    # contrôle négatif s'arrête sur une fausse ouverture — mesuré, c'est
    # exactement ce qui est arrivé au premier essai.
    # On ressoude donc, comme le fait `_souder_et_reboucher()` du
    # générateur, et on publie les deux comptes.
    import bmesh
    avant_sommets = len(obj.data.vertices)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    print("[sab] soudure : %d -> %d sommets (l'export glTF les dedouble "
          "par face)" % (avant_sommets, len(obj.data.vertices)))

    sommets = obj.data.vertices
    z_ciel = max(v.co.z for v in sommets) + 1.0
    z_fond = min(v.co.z for v in sommets) - 1.0
    origine = [v.co.copy() for v in sommets]
    sha_avant = empreinte_coords(obj.data)
    bord0, nm0 = integrite(obj)
    print("[sab] maillage %s : %d sommets, %d polygones"
          % (obj.name, len(sommets), len(obj.data.polygons)))
    print("[sab] empreinte des coordonnees AVANT : %s" % sha_avant[:32])
    print("[sab] integrite AVANT : %d arete(s) de bord, %d non-manifold"
          % (bord0, nm0))

    # ---- 1. AVANT ----------------------------------------------------
    tr = tranches_bvh(arbre_de(obj), ax, ay, z_ciel, z_fond)
    av = cumul(tr)
    if av is None:
        print("[sab] BLOQUE: pas de vide qualifiant en (%.2f ; %.2f) — le "
              "sabotage n'aurait rien a amincir" % (ax, ay))
        return 3
    print("[sab] 1. AVANT   : cumul %.3f m sur un vide de %.2f m (%d banc)"
          % (av[0], av[1], av[2]))
    if av[0] < EPAISSEUR_MIN_M:
        print("[sab] BLOQUE: le point est DEJA sous le seuil — un controle "
              "negatif doit partir du vert")
        return 3
    print("[sab]            -> VERT ici (%.3f >= %.2f)"
          % (av[0], EPAISSEUR_MIN_M))

    # ---- 2. SABOTAGE : deplacement, jamais ablation --------------------
    # ON REMONTE LE PLAFOND DU VIDE, ON N'ABAISSE PAS LE TOIT.
    # Premier essai mesuré : abaisser la surface superieure de 1,10 m n'a
    # fait passer le toit que de 1,481 a 1,119 m, parce que le vide
    # descendait AVEC lui (1,63 -> 1,08 m). Le sabotage se combattait
    # lui-meme, et pousser plus loin aurait fait tomber le vide sous le
    # seuil de qualification : la colonne aurait alors disparu du controle
    # au lieu d'y rougir — un faux vert par disparition du sujet.
    # Remonter le PLANCHER du banc amincit la roche ET agrandit le vide :
    # les deux effets vont dans le meme sens, et le vide reste qualifiant.
    import math
    z_haut, z_bas = tr[0][1], tr[0][2]
    bouges = 0
    for i, v in enumerate(sommets):
        d = ((v.co.x - ax) ** 2 + (v.co.y - ay) ** 2) ** 0.5
        if d > rayon or abs(v.co.z - z_bas) > 0.60:
            continue
        f = 0.5 * (1.0 + math.cos(math.pi * min(1.0, d / rayon)))
        if f <= 0.0:
            continue
        # jamais au-dela du sommet du banc : on amincit, on ne retourne pas
        marge = max(0.0, (z_haut - 0.05) - v.co.z)
        v.co.z += min(chute * f, marge)
        bouges += 1
    obj.data.update()
    bord1, nm1 = integrite(obj)
    print("[sab] 2. SABOTAGE : %d sommets deplaces (disque r=%.2f m, chute "
          "max %.2f m) ; 0 triangle retire" % (bouges, rayon, chute))
    print("[sab]            integrite APRES : %d arete(s) de bord, %d "
          "non-manifold" % (bord1, nm1))
    if bouges == 0:
        print("[sab] BLOQUE: aucun sommet deplace — le sabotage n'a rien fait")
        return 3
    if (bord1, nm1) != (0, 0):
        print("[sab] BLOQUE: le sabotage a OUVERT le maillage — le verdict "
              "qui suivrait serait indefini")
        return 3

    # ---- 3. MESURE INDEPENDANTE de la baisse ---------------------------
    tr2 = tranches_bvh(arbre_de(obj), ax, ay, z_ciel, z_fond)
    ap = cumul(tr2)
    if ap is None:
        print("[sab] BLOQUE: le vide qualifiant a disparu — le sabotage a "
              "change autre chose que l'epaisseur")
        return 3
    print("[sab] 3. MESURE  : toit %.3f m -> %.3f m (%+.3f m) ; vide %.2f -> "
          "%.2f m" % (av[0], ap[0], ap[0] - av[0], av[1], ap[1]))
    if ap[0] >= av[0]:
        print("[sab] BLOQUE: l'epaisseur n'a pas baisse — le sabotage n'a pas "
              "retire la chose testee")
        return 3

    # ---- 4. APRES ------------------------------------------------------
    if ap[0] >= EPAISSEUR_MIN_M:
        print("[sab] ECHEC: apres sabotage le point reste a %.3f m, au-dessus "
              "du seuil : sabotage trop faible, augmenter la chute" % ap[0])
        return 1
    print("[sab] 4. APRES   : ROUGE ici (%.3f < %.2f)"
          % (ap[0], EPAISSEUR_MIN_M))

    # ---- 5. RESTAURATION ------------------------------------------------
    for i, v in enumerate(sommets):
        v.co = origine[i]
    obj.data.update()
    sha_apres = empreinte_coords(obj.data)
    bord2, nm2 = integrite(obj)
    tr3 = tranches_bvh(arbre_de(obj), ax, ay, z_ciel, z_fond)
    re = cumul(tr3)
    print("[sab] 5. RESTAURE: empreinte %s" % sha_apres[:32])
    print("[sab]            identique a l'originale : %s"
          % ("OUI" if sha_apres == sha_avant else "NON"))
    print("[sab]            integrite : %d bord, %d non-manifold"
          % (bord2, nm2))
    print("[sab]            cumul %.3f m -> %s"
          % (re[0], "VERT" if re[0] >= EPAISSEUR_MIN_M else "ROUGE"))
    if sha_apres != sha_avant:
        print("[sab] ECHEC: restauration NON byte-identique")
        return 1
    if abs(re[0] - av[0]) > 1e-9:
        print("[sab] ECHEC: la mesure restauree differe de l'originale")
        return 1
    print("[sab] CONTROLE NEGATIF CONCLUANT : vert -> rouge -> vert, "
          "maillage ferme et manifold a chaque etape")
    return 0


if __name__ == "__main__":
    sys.exit(main())
