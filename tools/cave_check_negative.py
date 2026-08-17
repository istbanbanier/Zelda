#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CONTROLE NEGATIF FERME — sans lui, `cave_check_hull.py` ne vaut rien.

« Un controle qui n'a jamais rougi n'est pas un controle »
(`docs/CONTRAT_COQUE_STRUCTURELLE.md` §3).

CE QUE LE CONTRAT EXIGE, ET DANS CET ORDRE
==========================================
1. prouver la fermeture AVANT : 0 bord libre, 0 non-manifold, 0 sommet pince ;
2. prouver par une MESURE INDEPENDANTE que l'epaisseur a bien baisse a
   l'endroit vise — pas la mesure eprouvee, une autre ;
3. obtenir ROUGE ;
4. restaurer byte-identique, empreintes publiees des deux cotes ;
5. obtenir VERT.

« Un rouge obtenu pour une autre cause que celle annoncee ne compte pas. »

DEPLACER, JAMAIS AMPUTER
========================
Retirer des triangles OUVRE le maillage. Sur un maillage ouvert la parite ne
definit plus de dedans, et — mesure en R2a-3.5.3 — le vote a trois axes
REBOUCHE le trou qu'on vient de percer : cinq sabotages sur six n'ont pas
rougi, avec un tunnel de 0,35 a 0,65 m de rayon libre MESURE. Un
acquittement par aveuglement.

On deplace donc des SOMMETS. La connectivite n'est pas touchee : la
fermeture et le caractere manifold sont conserves PAR CONSTRUCTION, et on
les reprouve quand meme.

LA MESURE INDEPENDANTE, ET POURQUOI L'IMPLICATION EST SAINE
===========================================================
L'instrument eprouve mesure une distance EUCLIDIENNE. Le temoin mesure ici
une distance LE LONG D'UN RAYON. Or pour tout point et toute direction :

    distance euclidienne  <=  distance le long du rayon

Donc « rayon < 0,80 » IMPLIQUE « euclidienne < 0,80 ». L'implication ne vaut
que dans ce sens, et c'est celui dont on a besoin : le temoin ne peut pas
faire croire a un amincissement qui n'existe pas.

LE PIEGE DU SABOTAGE QUI RATE SA CIBLE
======================================
`tools/CLAUDE.md` : un premier controle negatif retirait la matiere sous
`z = 0` alors que le plancher vit a `z ~ 0,1..0,37`. Il laissait la peau
intacte, l'outil restait vert, et on aurait pu conclure que l'outil etait
aveugle. On verifie donc ce que le sabotage a REELLEMENT fait avant de
croire le verdict qu'il produit.

USAGE
=====
    python3 tools/cave_check_negative.py <fichier.glb> [--cible=0.45]
"""

import hashlib
import json
import math
import os
import struct
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cave_check_mesh as M  # noqa: E402
import cave_check_closure as C  # noqa: E402


def empreinte(chemin):
    h = hashlib.sha256()
    with open(chemin, "rb") as f:
        for bloc in iter(lambda: f.read(1 << 20), b""):
            h.update(bloc)
    return h.hexdigest()


# --------------------------------------------------------------------------
# Rayon / triangle — Moller-Trumbore. Sert UNIQUEMENT au temoin independant.
# --------------------------------------------------------------------------

def impact_rayon(o, d, a, b, c):
    e1 = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    e2 = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    p = (d[1] * e2[2] - d[2] * e2[1],
         d[2] * e2[0] - d[0] * e2[2],
         d[0] * e2[1] - d[1] * e2[0])
    det = e1[0] * p[0] + e1[1] * p[1] + e1[2] * p[2]
    if abs(det) < 1e-12:
        return None
    inv = 1.0 / det
    t = (o[0] - a[0], o[1] - a[1], o[2] - a[2])
    u = (t[0] * p[0] + t[1] * p[1] + t[2] * p[2]) * inv
    if u < 0.0 or u > 1.0:
        return None
    q = (t[1] * e1[2] - t[2] * e1[1],
         t[2] * e1[0] - t[0] * e1[2],
         t[0] * e1[1] - t[1] * e1[0])
    v = (d[0] * q[0] + d[1] * q[1] + d[2] * q[2]) * inv
    if v < 0.0 or u + v > 1.0:
        return None
    s = (e2[0] * q[0] + e2[1] * q[1] + e2[2] * q[2]) * inv
    return s if s > 1e-7 else None


def portee_rayon(positions, faces, o, d):
    """Distance libre du point `o` dans la direction `d`. LE TEMOIN."""
    best = float("inf")
    for (ia, ib, ic) in faces:
        s = impact_rayon(o, d, positions[ia], positions[ib], positions[ic])
        if s is not None and s < best:
            best = s
    return best


# --------------------------------------------------------------------------
# Ecriture d'un GLB minimal — positions + indices, un seul noeud nomme
# --------------------------------------------------------------------------

def ecrire_glb(chemin, positions_modele, faces, nom="SM_WaterfallCave"):
    """Ecrit un GLB. Les positions sont donnees en repere MODELE et
    reconverties en repere glTF : gx = ax ; gy = az ; gz = -ay."""
    pos = [(p[0], p[2], -p[1]) for p in positions_modele]
    bpos = b"".join(struct.pack("<fff", *p) for p in pos)
    bidx = b"".join(struct.pack("<III", *f) for f in faces)
    while len(bpos) % 4:
        bpos += b"\0"
    binaire = bpos + bidx
    while len(binaire) % 4:
        binaire += b"\0"
    mn = [min(p[k] for p in pos) for k in range(3)]
    mx = [max(p[k] for p in pos) for k in range(3)]
    js = {
        "asset": {"version": "2.0", "generator": "cave_check_negative"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"name": nom, "mesh": 0}],
        "meshes": [{"name": nom, "primitives": [
            {"attributes": {"POSITION": 0}, "indices": 1, "mode": 4}]}],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": len(pos),
             "type": "VEC3", "min": mn, "max": mx},
            {"bufferView": 1, "componentType": 5125, "count": len(faces) * 3,
             "type": "SCALAR"},
        ],
        "bufferViews": [
            {"buffer": 0, "byteOffset": 0, "byteLength": len(bpos)},
            {"buffer": 0, "byteOffset": len(bpos), "byteLength": len(bidx)},
        ],
        "buffers": [{"byteLength": len(binaire)}],
    }
    bjs = json.dumps(js, separators=(",", ":")).encode("utf-8")
    while len(bjs) % 4:
        bjs += b" "
    total = 12 + 8 + len(bjs) + 8 + len(binaire)
    with open(chemin, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(bjs), 0x4E4F534A))
        f.write(bjs)
        f.write(struct.pack("<II", len(binaire), 0x004E4942))
        f.write(binaire)


# --------------------------------------------------------------------------

def normale_sommet(positions, faces, incid, v):
    nx = ny = nz = 0.0
    for fi in incid:
        a, b, c = faces[fi]
        n = M.normale(positions[a], positions[b], positions[c])
        nx += n[0]; ny += n[1]; nz += n[2]
    L = math.sqrt(nx * nx + ny * ny + nz * nz)
    return (nx / L, ny / L, nz / L) if L > 0 else (0.0, 0.0, 1.0)


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    if not args:
        print(__doc__)
        return 3
    src = args[0]
    cible = 0.45
    for a in argv:
        if a.startswith("--cible="):
            cible = float(a.split("=", 1)[1])
    h_instr = 0.15
    masque = 0.60
    for a in argv:
        if a.startswith("--masque="):
            masque = float(a.split("=", 1)[1])

    print("=" * 76)
    print("CONTROLE NEGATIF FERME — contrat §3")
    print("=" * 76)
    sha_avant = empreinte(src)
    print("source  : %s" % src)
    print("sha256  : %s   <- AVANT" % sha_avant)
    print("cible d'epaisseur apres sabotage : %.3f m (seuil %.2f)"
          % (cible, 0.80))
    print()

    # ---- etape 1 : fermeture AVANT ----
    print("--- ETAPE 1 : fermeture prouvee AVANT sabotage ---")
    r = C.analyser(src, "SM_WaterfallCave")
    print("  bords libres %d | non-manifold %d | sommets PINCES %d | "
          "aretes mal orientees %d"
          % (r["bords_libres"], r["non_manifold"], r["pinces_total"],
             r["incoherentes"]))
    genres = [c["genre"] for c in r["comps"]]
    print("  composantes %d | genres %s" % (r["nb_comp"], genres))
    if r["bords_libres"] or r["non_manifold"] or r["pinces_total"]:
        print("  ABANDON : le maillage n'est pas sain AVANT sabotage.")
        return 3
    positions = [tuple(p) for p in r["positions"]]
    faces = r["faces"]
    print()

    # ---- choix de la cible ----
    print("--- choix du point a amincir ---")
    incid = {}
    for fi, (a, b, c) in enumerate(faces):
        for s in (a, b, c):
            incid.setdefault(s, []).append(fi)
    meilleur = None
    for v in range(0, len(positions), 37):
        n = normale_sommet(positions, faces, incid[v], v)
        o = tuple(positions[v][k] - n[k] * 1e-4 for k in range(3))
        d = tuple(-n[k] for k in range(3))
        L = portee_rayon(positions, faces, o, d)
        if 0.85 <= L <= 1.30:
            if meilleur is None or abs(L - 1.0) < abs(meilleur[1] - 1.0):
                meilleur = (v, L, n)
    if meilleur is None:
        print("  ABANDON : aucun point d'epaisseur 0,85-1,30 m trouve.")
        return 3
    v0, L0, n0 = meilleur
    p0 = positions[v0]
    print("  sommet %d, modele (%.3f ; %.3f ; %.3f)" % (v0, p0[0], p0[1], p0[2]))
    print("  TEMOIN AVANT : portee du rayon vers l'interieur = %.4f m" % L0)
    deplacement = L0 - cible
    print("  deplacement demande : %.4f m (soit %.3f m restants)"
          % (deplacement, cible))
    print()

    # ---- sabotage : deplacement de sommets, aucune face retiree ----
    print("--- ETAPE 2 : sabotage par DEPLACEMENT (aucune face retiree) ---")
    print("  Le rayon est ASSERVI au deplacement, et augmente jusqu'a ce")
    print("  qu'aucun triangle ne se retourne. Mesure : un deplacement de")
    print("  1,16 m dans un disque de 0,40 m REPLIE la surface (3 triangles")
    print("  retournes) ; a 1,86 m il en reste 1. Un maillage auto-intersecte")
    print("  n'est pas un amincissement de coque, et le rouge qu'il produit")
    print("  aurait une AUTRE CAUSE que celle annoncee — §3 l'interdit.")
    print("  %-9s %-9s %s" % ("rayon", "sommets", "triangles retournes"))
    neuves = None
    rayon = None
    for mult in (1.6, 2.5, 4.0, 6.0, 9.0, 14.0):
        r = max(0.40, mult * deplacement)
        essai = list(positions)
        n = 0
        touches = set()
        for v, p in enumerate(positions):
            dd = math.dist(p, p0)
            if dd > r:
                continue
            # NE DEPLACER QUE LA NAPPE PROCHE. Mesure : avec un disque de
            # 2,90 m, le sabotage entrainait AUSSI la paroi opposee, et
            # l'ecart ne se refermait que de 1,61 a 0,94 m — au-dessus du
            # seuil. Un sabotage qui deplace les deux bords ne les rapproche
            # pas. On filtre donc par l'orientation de la normale du sommet.
            nv = normale_sommet(positions, faces, incid[v], v)
            alig = nv[0] * n0[0] + nv[1] * n0[1] + nv[2] * n0[2]
            if alig <= 0.0:
                continue
            # Ponderation CONTINUE par l'alignement. Un seuil DUR a 0,30
            # creait une marche entre sommets voisins et repliait la surface
            # (17 a 1 444 triangles retournes selon le rayon). La continuite
            # du champ de deplacement n'est pas un raffinement : sans elle,
            # tout sabotage large produit une auto-intersection.
            w = 0.5 * (1.0 + math.cos(math.pi * dd / r)) * alig
            if w <= 1e-6:
                continue
            essai[v] = tuple(p[k] - n0[k] * deplacement * w for k in range(3))
            n += 1
            touches.update(incid.get(v, []))
        inv = 0
        for fi in touches:
            a, b, c = faces[fi]
            na = M.normale(positions[a], positions[b], positions[c])
            nb = M.normale(essai[a], essai[b], essai[c])
            if na[0] * nb[0] + na[1] * nb[1] + na[2] * nb[2] <= 0.0:
                inv += 1
        print("  %-9.3f %-9d %d" % (r, n, inv))
        if inv == 0:
            neuves, rayon, bouges = essai, r, n
            break
    if neuves is None:
        print("  ABANDON : aucun rayon ne evite le repli de surface.")
        return 3
    print("  retenu : rayon %.3f m, %d sommets deplaces, 0 triangle retourne"
          % (rayon, bouges))
    print("  faces retirees : 0   <- la connectivite est intacte")
    print()

    sab = "/tmp/cave_sabote_ferme.glb"
    ecrire_glb(sab, neuves, faces)
    print("  ecrit : %s" % sab)
    print("  sha256 sabote : %s" % empreinte(sab))
    print()

    # ---- fermeture APRES ----
    print("--- fermeture APRES sabotage (doit etre identique) ---")
    r2 = C.analyser(sab, "SM_WaterfallCave")
    print("  bords libres %d | non-manifold %d | sommets PINCES %d | "
          "aretes mal orientees %d"
          % (r2["bords_libres"], r2["non_manifold"], r2["pinces_total"],
             r2["incoherentes"]))
    genres2 = [c["genre"] for c in r2["comps"]]
    print("  composantes %d | genres %s" % (r2["nb_comp"], genres2))
    ferme_ok = (r2["bords_libres"] == 0 and r2["non_manifold"] == 0
                and r2["pinces_total"] == 0 and genres2 == genres)
    if not ferme_ok:
        print("  ECHEC : le sabotage a change la topologie. Un rouge obtenu")
        print("  ici serait obtenu POUR UNE AUTRE CAUSE que celle annoncee,")
        print("  et §3 dit qu'il ne compte pas.")
        return 3
    print("  -> maillage toujours FERME, manifold, meme genre.")
    print()

    # ---- temoin independant APRES ----
    print("--- ETAPE 3 : le TEMOIN INDEPENDANT confirme l'amincissement ---")
    pos2 = [tuple(p) for p in r2["positions"]]
    faces2 = r2["faces"]
    # on resonde depuis le point deplace, meme direction
    p0b = tuple(p0[k] - n0[k] * deplacement for k in range(3))
    o2 = tuple(p0b[k] - n0[k] * 1e-4 for k in range(3))
    L1 = portee_rayon(pos2, faces2, o2, tuple(-n0[k] for k in range(3)))
    print("  portee du rayon AVANT : %.4f m" % L0)
    print("  portee du rayon APRES : %.4f m" % L1)
    print("  baisse mesuree        : %.4f m" % (L0 - L1))
    if L1 >= 0.80:
        print("  ECHEC : le temoin ne descend pas sous 0,80 m. Le sabotage")
        print("  n'a pas atteint sa cible — verifier ce qu'il a REELLEMENT")
        print("  fait avant de croire un verdict.")
        return 3
    print("  euclidienne <= portee du rayon, donc l'epaisseur EUCLIDIENNE")
    print("  y est aussi < 0,80 m. L'implication ne vaut que dans ce sens,")
    print("  et c'est celui dont on a besoin.")
    print()

    # ---- ETAPE 4 : l'instrument doit ROUGIR, ET POUR LA BONNE CAUSE ----
    print("--- ETAPE 4 : verdict de l'instrument ---")
    print("  §3 : « Un rouge obtenu pour une AUTRE CAUSE que celle annoncee")
    print("  ne compte pas. » On mesure donc AUSSI la geometrie saine, et on")
    print("  exige que l'argmin se DEPLACE vers le site du sabotage.")
    ici = os.path.dirname(os.path.abspath(__file__))

    def juger(fichier, etiquette):
        cmd = [sys.executable, os.path.join(ici, "cave_check_hull.py"),
               fichier, "--pas-balayage=0.25", "--h=%.3f" % h_instr,
               "--masque=%.2f" % masque]
        print("  %s" % " ".join(cmd))
        pr = subprocess.run(cmd, capture_output=True, text=True)
        arg = None
        lec = None
        for ligne in pr.stdout.splitlines():
            if ("GATE" in ligne or "LECTURE" in ligne or "BORNE" in ligne
                    or "ARGMIN" in ligne):
                print("    [%s] %s" % (etiquette, ligne.strip()))
            if "ARGMIN" in ligne and "(" in ligne:
                try:
                    txt = ligne.split("modele (")[1].split(")")[0]
                    arg = tuple(float(v) for v in txt.split(";"))
                except (IndexError, ValueError):
                    arg = None
            if "LECTURE brute" in ligne:
                try:
                    lec = float(ligne.split(":")[1].split("m")[0])
                except (IndexError, ValueError):
                    lec = None
        print("    [%s] RC = %d" % (etiquette, pr.returncode))
        return pr.returncode, arg, lec

    rc_sain, arg_sain, lec_sain = juger(src, "SAIN")
    print()
    rc_sab, arg_sab, lec_sab = juger(sab, "SABOTE")
    print()
    pr = type("R", (), {"returncode": rc_sab})()

    # ---- ETAPE 5 : la source n'a jamais ete reecrite ----
    sha_apres = empreinte(src)
    print("--- ETAPE 5 : restauration ---")
    print("  sha256 source AVANT : %s" % sha_avant)
    print("  sha256 source APRES : %s" % sha_apres)
    print("  identiques : %s   <- la source n'a JAMAIS ete reecrite ; le"
          % ("OUI" if sha_avant == sha_apres else "NON"))
    print("  sabotage vit dans un fichier separe, donc la restauration est")
    print("  byte-identique par construction plutot que par diligence.")
    if sha_avant != sha_apres:
        print("  ECHEC : la source a bouge.")
        return 3
    print()

    print("--- ATTRIBUTION : le rouge vient-il de MON sabotage ? ---")
    d_arg = None
    if arg_sab is not None:
        d_arg = math.dist(arg_sab, p0b)
        print("  site du sabotage   : (%.3f ; %.3f ; %.3f)"
              % (p0b[0], p0b[1], p0b[2]))
        print("  argmin SAIN        : %s" % (
            "(%.3f ; %.3f ; %.3f)" % arg_sain if arg_sain else "-"))
        print("  argmin SABOTE      : (%.3f ; %.3f ; %.3f)" % arg_sab)
        print("  distance argmin(sabote) -> site : %.3f m" % d_arg)
    attribue = (d_arg is not None and d_arg <= rayon)
    print("  attribue au sabotage : %s" % ("OUI" if attribue else "NON"))
    print()

    print("=" * 76)
    if rc_sain == 1 and not attribue:
        print("CONTROLE NEGATIF : **NON CONCLUANT**")
        print("=" * 76)
        print("L'instrument rougit DEJA sur la geometrie saine (RC=%d), et"
              % rc_sain)
        print("l'argmin du maillage sabote reste loin du site (%s)."
              % ("%.3f m" % d_arg if d_arg is not None else "non localise"))
        print()
        print("Le rouge n'est donc PAS imputable au sabotage : il aurait ete")
        print("obtenu sans lui. §3 : « un rouge obtenu pour une autre cause")
        print("que celle annoncee ne compte pas. » Ce controle ne falsifie")
        print("rien tant que la geometrie de reference n'est pas VERTE — il")
        print("faut d'abord un masque qui ecarte le rebord de bouche.")
        return 1
    if rc_sab == 1 and attribue:
        print("CONTROLE NEGATIF : **CONCLUANT** — la coque amincie ROUGIT,")
        print("l'argmin s'est deplace SUR le site du sabotage, le maillage")
        print("est reste ferme, et la baisse est prouvee par un instrument")
        print("different de celui qu'on eprouve.")
        return 0
    print("CONTROLE NEGATIF : **NON CONCLUANT** — RC sabote=%d, attribue=%s."
          % (rc_sab, attribue))
    print("Sans rouge attribuable, `cave_check_hull.py` reste NON FALSIFIE")
    print("et son vert ne prouve rien. C'est ce que §3 refuse.")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
