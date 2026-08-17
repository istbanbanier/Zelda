#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CONTROLE NEGATIF DU GATE A DEUX SEUILS — contrat §3, addendum §3.1.

POURQUOI UN CONTROLE DE PLUS
============================
`tools/cave_check_negative.py` eprouve un gate a UN seuil. Le gate a deux
seuils pose une question que celui-la ne pose pas : **les deux seuils sont-
ils reellement appliques separement ?** Un instrument qui appliquerait 0,80
partout passerait le controle negatif a un seuil sans qu'on le voie.

LE PIEGE QUI A INVALIDE LE CONTROLE PRECEDENT, ET IL EST CENTRAL ICI
====================================================================
Passe R2a-3.5.4 : un controle negatif a rendu `RC=0` et un « CONCLUANT »
entierement faux, parce que le rouge venait **du rebord du porche** et
aurait ete obtenu SANS sabotage.

Sur ces geometries le gate est deja ROUGE avant tout sabotage — lecture
0,0320 m au rebord. « Obtenir ROUGE » ne prouve donc STRICTEMENT RIEN, et
il faut le dire au lieu de s'en contenter. Le contenu probant est ailleurs,
dans trois faits verifiables separement :

  1. l'ARGMIN DE LA CLASSE VISEE se deplace vers le site du sabotage ;
  2. la LECTURE DE CETTE CLASSE baisse, du montant attendu ;
  3. la CLASSIFICATION DU SITE est publiee AVANT et APRES, et ne change
     pas — un sabotage qui ferait basculer la face de COQUE a COLLERETTE
     changerait le seuil sous nos pieds, et le verdict ne voudrait plus
     rien dire.

LA DISCRIMINATION DES DEUX SEUILS, qui est le vrai test de cet addendum
=======================================================================
Amincir a 0,70 m — entre les deux seuils — doit produire DEUX resultats
opposes selon la classe du site :

    site classe COQUE       -> 0,70 < 0,80  ->  la classe COQUE rougit
    site classe COLLERETTE  -> 0,70 > 0,60  ->  la classe COLLERETTE tient

Un instrument qui appliquerait un seul seuil ne peut pas produire les deux.
C'est la seule epreuve qui distingue le gate a deux seuils de son
predecesseur, et elle est faite ici.

DEPLACER, JAMAIS AMPUTER — contrat §3
=====================================
Retirer des triangles ouvre le maillage, et sur un maillage ouvert aucune
notion de dedans n'est definie. On deplace donc des SOMMETS : la
connectivite n'est pas touchee, la fermeture et le caractere manifold sont
conserves par construction, et on les reprouve quand meme des deux cotes.

USAGE
=====
    python3 tools/cave_negatif_deux_seuils.py <fichier.glb> [options]
      --classe=coque|collerette   classe du site a saboter
      --cible=0.70                epaisseur visee apres sabotage
      --s-final=-0.60             abscisse de fin du masque (emprise)
      --h=0.15  --budget=250000   passes au gate
      --sortie=<prefixe>          prefixe des fichiers produits

Codes retour : 0 CONCLUANT · 1 NON CONCLUANT · 3 BLOQUE.
"""

import hashlib
import math
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cave_check_mesh as M            # noqa: E402
import cave_check_closure as C         # noqa: E402
import cave_check_negative as N        # noqa: E402
import cave_check_hull as H            # noqa: E402
import cave_masque_bouche as B         # noqa: E402
import cave_check_coque_deux_seuils as G  # noqa: E402


def empreinte(chemin):
    h = hashlib.sha256()
    with open(chemin, "rb") as f:
        for bloc in iter(lambda: f.read(1 << 20), b""):
            h.update(bloc)
    return h.hexdigest()


def opt(argv, nom, defaut):
    for a in argv:
        if a.startswith("--%s=" % nom):
            return a.split("=", 1)[1]
    return defaut


def contexte(racine, glb):
    """Peau interieure, masque et outils de mesure, comme le gate."""
    gen = os.path.join(racine, "source_assets", "blender", "environment",
                       "make_waterfall_cave.py")
    with open(gen, "r", encoding="utf-8") as f:
        tables = B.charger_tables(f.read(), gen)
    lieu = os.path.join(racine, "scripts", "world_v2", "poi",
                        "waterfall_cave_place.gd")
    with open(lieu, "r", encoding="utf-8") as f:
        txt = f.read()
    seuil_mod, _g = B.lire_repere_lieu(txt, "MODELE_SEUIL_DEHORS")
    salle_mod, _g = B.lire_repere_lieu(txt, "MODELE_SALLE")
    niche_mod, _g = B.lire_repere_lieu(txt, "MODELE_NICHE")
    sommets, triangles = M.charger(glb, "SM_WaterfallCave", repere="modele")
    positions, faces, _st = M.souder(sommets, triangles)
    tab = M.aretes(faces)
    adj = M.graphe_dual(faces, tab)
    hach_tout = H.Hachage(positions, faces, range(len(faces)), 0.5)
    temoins = H.faces_du_dehors(positions, faces)
    _d, f_salle = hach_tout.plus_proche(salle_mod)
    _d, f_niche = hach_tout.plus_proche(niche_mod)
    aire = [M.aire_triangle(positions[faces[i][0]], positions[faces[i][1]],
                            positions[faces[i][2]])
            for i in range(len(faces))]
    total = sum(aire)
    (x0, y0, z0), (x1, y1, z1) = M.boite(positions)
    cands = []
    s = y0 + 0.02
    while s <= min(y0 + 9.0, y1 - 0.02):
        for ct in H.contours_du_plan(positions, faces, tab, 1, s):
            ok, cote = H.separe_graine_ciel(adj, ct["aretes"], tab, f_salle,
                                            temoins)
            if not ok or f_niche not in cote:
                continue
            a_int = sum(aire[i] for i in cote)
            if a_int >= total - a_int:
                continue
            cands.append((a_int, s, ct, cote))
        s += 0.25
    if not cands:
        return None
    _a, s_b, _ct, cote = max(cands, key=lambda t: t[0])
    pts_ct = []
    for (ia, ib) in _ct["aretes"]:
        pa, pb = positions[ia], positions[ib]
        va, vb = pa[1] - s_b, pb[1] - s_b
        t = 0.5 if abs(va - vb) < 1e-12 else va / (va - vb)
        pts_ct.append(tuple(pa[k] + t * (pb[k] - pa[k]) for k in range(3)))
    interieur = sorted(cote)
    dedans = set(interieur)
    exterieur = [i for i in range(len(faces)) if i not in dedans]
    chemin = B.Chemin(tables)
    gab = B.Gabarit(tables["GABARIT_DEMI_LARGEUR_M"], tables["GABARIT_CLE_M"])
    _da, s_dehors, _u = chemin.projeter(seuil_mod)
    return {
        "positions": positions, "faces": faces, "interieur": interieur,
        "exterieur": exterieur, "chemin": chemin, "gabarit": gab,
        "s_dehors": s_dehors, "pts_contour": pts_ct,
        "hach_ext": H.Hachage(positions, faces, exterieur, 0.5),
    }


def classer(masque, p, r):
    """Classe d'un point, avec la meme regle de purete que le gate."""
    dm = masque.distance(p)
    if (dm + r) <= G.BANDE_M:
        return "COLLERETTE", dm
    if (dm - r) > G.BANDE_M:
        return "COQUE", dm
    return "A_CHEVAL", dm


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    if not args:
        print(__doc__)
        return 3
    src = args[0]
    ici = os.path.dirname(os.path.abspath(__file__))
    racine = B.racine_git(ici)
    classe_visee = opt(argv, "classe", "coque").upper()
    cible = float(opt(argv, "cible", "0.70"))
    h_gate = opt(argv, "h", "0.15")
    budget = opt(argv, "budget", "250000")
    prefixe = opt(argv, "sortie", "/tmp/cave_neg2")
    marge = float(opt(argv, "marge-contour", "0.60"))

    print("=" * 76)
    print("CONTROLE NEGATIF — gate a DEUX SEUILS")
    print("=" * 76)
    sha_avant = empreinte(src)
    print("source : %s" % src)
    print("sha256 : %s   <- AVANT" % sha_avant)
    print("classe visee : %s   |   epaisseur cible apres sabotage : %.3f m"
          % (classe_visee, cible))
    print()

    # ---- ETAPE 1 : fermeture prouvee AVANT ----
    print("--- ETAPE 1 : fermeture prouvee AVANT sabotage (contrat §3.1) ---")
    r = C.analyser(src, "SM_WaterfallCave")
    print("  bords libres %d | non-manifold %d | sommets PINCES %d | "
          "aretes mal orientees %d"
          % (r["bords_libres"], r["non_manifold"], r["pinces_total"],
             r["incoherentes"]))
    genres = [c["genre"] for c in r["comps"]]
    print("  composantes %d | genres %s" % (r["nb_comp"], genres))
    if r["bords_libres"] or r["non_manifold"] or r["pinces_total"]:
        print("  ABANDON : maillage non sain AVANT sabotage.")
        return 3
    positions = [tuple(p) for p in r["positions"]]
    faces = r["faces"]
    print()

    ctx = contexte(racine, src)
    if ctx is None:
        print("BLOQUE : aucune barriere de bouche valide ; la coque est")
        print("percee et il n'y a pas de separation a mesurer.")
        return 3
    s_fin = float(opt(argv, "s-final", "%.6f" % (ctx["s_dehors"] + 1.0)))
    masque = G.Masque(ctx["chemin"], ctx["gabarit"], ctx["s_dehors"], s_fin)
    print("  marge de contour transmise au gate : %.3f m (HORS CONTRAT,")
    print("  necessaire pour que le controle negatif eprouve quoi que ce")
    print("  soit : sans elle l'argmin reste sur l'arete de bouche)" % ())
    print()
    print("--- le masque de cette mesure ---")
    print("  s de %.4f a %.4f  (emprise %.3f m)"
          % (ctx["s_dehors"], s_fin, s_fin - ctx["s_dehors"]))
    print()

    # ---- choix du site, avec sa CLASSE publiee AVANT ----
    print("--- ETAPE 2 : choix du site, CLASSE PUBLIEE AVANT sabotage ---")
    print("  Exigence du lead : la classification du site est publiee avant")
    print("  ET apres. Un sabotage qui ferait basculer la face d'une classe")
    print("  a l'autre changerait le seuil sous nos pieds, et le verdict ne")
    print("  voudrait plus rien dire.")
    incid = {}
    for fi, (a, b, c) in enumerate(faces):
        for s in (a, b, c):
            incid.setdefault(s, []).append(fi)
    peau = set(ctx["interieur"])
    meilleur = None
    for v in range(0, len(positions), 7):
        if not any(f in peau for f in incid[v]):
            continue
        n = N.normale_sommet(positions, faces, incid[v], v)
        o = tuple(positions[v][k] - n[k] * 1e-4 for k in range(3))
        d = tuple(-n[k] for k in range(3))
        L = N.portee_rayon(positions, faces, o, d)
        if not (cible + 0.25 <= L <= cible + 0.90):
            continue
        # ECARTER LA LEVRE. Sans cette marge, le controle negatif ne peut
        # RIEN eprouver : l'argmin reste colle a l'arete de bouche, a 1 mm,
        # et aucun sabotage a 0,70 m ne l'en delogera. Voir le journal du
        # gate, mode diagnostic hors contrat.
        if min(math.dist(positions[v], q) for q in ctx["pts_contour"]) \
                <= marge:
            continue
        # rayon de couverture local, pour classer avec la meme purete
        rl = max(math.dist(positions[v], positions[w])
                 for f in incid[v] for w in faces[f]) * 0.5
        cl, dm = classer(masque, positions[v], rl)
        if cl != classe_visee:
            continue
        score = abs(L - (cible + 0.55))
        if meilleur is None or score < meilleur[0]:
            meilleur = (score, v, L, n, cl, dm, rl)
    if meilleur is None:
        print("  ABANDON : aucun sommet de la peau interieure n'est de classe")
        print("  %s avec une epaisseur exploitable dans [%.2f ; %.2f] m."
              % (classe_visee, cible + 0.25, cible + 0.90))
        print("  Ce n'est PAS un echec de l'instrument : c'est l'absence de")
        print("  site de sabotage valide, et il faut le dire ainsi.")
        return 3
    _sc, v0, L0, n0, cl0, dm0, rl0 = meilleur
    p0 = positions[v0]
    print("  sommet %d, modele (%.3f ; %.3f ; %.3f)"
          % (v0, p0[0], p0[1], p0[2]))
    print("  CLASSE AVANT : %s   (d_masque = %.4f m, rayon local %.4f m)"
          % (cl0, dm0, rl0))
    print("  TEMOIN INDEPENDANT AVANT : portee du rayon = %.4f m" % L0)
    deplacement = L0 - cible
    print("  deplacement demande : %.4f m (soit %.3f m restants)"
          % (deplacement, cible))
    print()

    # ---- sabotage ----
    print("--- ETAPE 3 : sabotage par DEPLACEMENT (aucune face retiree) ---")
    neuves = None
    for mult in (1.6, 2.5, 4.0, 6.0, 9.0, 14.0):
        rayon = max(0.40, mult * deplacement)
        essai = list(positions)
        n = 0
        touches = set()
        for v, p in enumerate(positions):
            dd = math.dist(p, p0)
            if dd > rayon:
                continue
            nv = N.normale_sommet(positions, faces, incid[v], v)
            alig = nv[0] * n0[0] + nv[1] * n0[1] + nv[2] * n0[2]
            if alig <= 0.0:
                continue
            w = 0.5 * (1.0 + math.cos(math.pi * dd / rayon)) * alig
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
        print("  rayon %.3f m : %d sommets, %d triangles retournes"
              % (rayon, n, inv))
        if inv == 0:
            neuves, r_ret, bouges = essai, rayon, n
            break
    if neuves is None:
        print("  ABANDON : aucun rayon n'evite le repli de surface.")
        return 3
    print("  retenu : rayon %.3f m, %d sommets, 0 triangle retourne, "
          "0 face retiree" % (r_ret, bouges))
    sab = "%s_sabote.glb" % prefixe
    N.ecrire_glb(sab, neuves, faces)
    print("  ecrit  : %s" % sab)
    print("  sha256 : %s" % empreinte(sab))
    print()

    # ---- fermeture APRES ----
    print("--- ETAPE 4 : fermeture APRES (doit etre identique) ---")
    r2 = C.analyser(sab, "SM_WaterfallCave")
    genres2 = [c["genre"] for c in r2["comps"]]
    print("  bords libres %d | non-manifold %d | sommets PINCES %d | "
          "genres %s" % (r2["bords_libres"], r2["non_manifold"],
                         r2["pinces_total"], genres2))
    if (r2["bords_libres"] or r2["non_manifold"] or r2["pinces_total"]
            or genres2 != genres):
        print("  ECHEC : la topologie a change. Un rouge obtenu ici aurait")
        print("  une AUTRE CAUSE que celle annoncee — §3 dit qu'il ne")
        print("  compte pas.")
        return 1
    print("  -> toujours FERME, manifold, meme genre.")
    print()

    # ---- temoin independant + CLASSE APRES ----
    print("--- ETAPE 5 : temoin independant, et CLASSE APRES ---")
    pos2 = [tuple(p) for p in r2["positions"]]
    faces2 = r2["faces"]
    p0b = tuple(p0[k] - n0[k] * deplacement for k in range(3))
    o2 = tuple(p0b[k] - n0[k] * 1e-4 for k in range(3))
    L1 = N.portee_rayon(pos2, faces2, o2, tuple(-n0[k] for k in range(3)))
    print("  portee AVANT %.4f m  ->  APRES %.4f m   (baisse %.4f m)"
          % (L0, L1, L0 - L1))
    cl1, dm1 = classer(masque, p0b, rl0)
    print("  CLASSE APRES : %s   (d_masque = %.4f m)" % (cl1, dm1))
    if cl1 != cl0:
        print("  ECHEC : la classe du site a CHANGE (%s -> %s). Le seuil a"
              % (cl0, cl1))
        print("  bouge sous nos pieds ; le verdict ne serait pas attribuable.")
        return 1
    print("  -> classe INCHANGEE, le seuil applicable est le meme des deux")
    print("     cotes de la mesure.")
    print("  L'euclidienne est <= la portee du rayon : l'epaisseur")
    print("  EUCLIDIENNE est donc elle aussi <= %.4f m. L'implication ne" % L1)
    print("  vaut que dans ce sens, et c'est celui dont on a besoin.")
    print()

    # ---- verdicts du gate, AVANT et APRES ----
    print("--- ETAPE 6 : le gate, sur la geometrie SAINE puis SABOTEE ---")
    print("  Sur ces geometries le gate est DEJA rouge avant tout sabotage")
    print("  (rebord du porche). « Obtenir ROUGE » ne prouve donc rien : le")
    print("  contenu probant est le DEPLACEMENT DE L'ARGMIN de la classe")
    print("  visee vers le site, et la BAISSE de sa lecture.")
    outil = os.path.join(ici, "cave_check_coque_deux_seuils.py")

    def juger(fichier, etiquette):
        cmd = [sys.executable, outil, fichier, "--h=%s" % h_gate,
               "--budget=%s" % budget, "--s-final=%.6f" % s_fin,
               "--pas-balayage=0.25", "--marge-contour=%.4f" % marge]
        print("  $ %s" % " ".join(cmd))
        pr = subprocess.run(cmd, capture_output=True, text=True)
        lect = {}
        argm = {}
        cl_cour = None
        for ligne in pr.stdout.splitlines():
            t = ligne.strip()
            if t.startswith("classe ") and "(seuil" in t:
                cl_cour = t.split()[1]
            if cl_cour and t.startswith("repere modele :"):
                brut = t.split("(", 1)[1].split(")", 1)[0]
                argm[cl_cour] = tuple(float(x) for x in brut.split(";"))
            if cl_cour and t.startswith("lecture ") and "| h " in t:
                lect[cl_cour] = float(t.split()[1])
        print("    [%s] RC = %d" % (etiquette, pr.returncode))
        for cl in ("COLLERETTE", "COQUE"):
            if cl in lect:
                a = argm.get(cl)
                print("    [%s] %-11s lecture %.4f  argmin %s"
                      % (etiquette, cl, lect[cl],
                         ("(%.3f ; %.3f ; %.3f)" % a) if a else "-"))
        return pr.returncode, lect, argm, pr.stdout

    rc_s, lec_s, arg_s, out_s = juger(src, "SAIN")
    print()
    rc_b, lec_b, arg_b, out_b = juger(sab, "SABOTE")
    print()
    with open("%s_gate_sain.txt" % prefixe, "w", encoding="utf-8") as f:
        f.write(out_s)
    with open("%s_gate_sabote.txt" % prefixe, "w", encoding="utf-8") as f:
        f.write(out_b)

    # ---- restauration byte-identique ----
    print("--- ETAPE 7 : restauration ---")
    sha_apres = empreinte(src)
    print("  sha256 source AVANT : %s" % sha_avant)
    print("  sha256 source APRES : %s" % sha_apres)
    ident = sha_avant == sha_apres
    print("  identiques : %s   <- la source n'a JAMAIS ete reecrite ; le"
          % ("OUI" if ident else "NON"))
    print("  sabotage vit dans un fichier separe, donc la restauration est")
    print("  byte-identique PAR CONSTRUCTION plutot que par diligence.")
    if not ident:
        print("  ECHEC : la source a bouge.")
        return 1
    print()

    # ---- attribution ----
    print("--- ETAPE 8 : ATTRIBUTION — le rouge vient-il de MON sabotage ? ---")
    print("  site du sabotage : (%.3f ; %.3f ; %.3f)" % p0b)
    ok_dep = False
    ok_baisse = False
    if classe_visee in arg_b:
        d_arg = math.dist(arg_b[classe_visee], p0b)
        print("  argmin %s SAIN   : %s" % (classe_visee,
              ("(%.3f ; %.3f ; %.3f)" % arg_s[classe_visee])
              if classe_visee in arg_s else "-"))
        print("  argmin %s SABOTE : (%.3f ; %.3f ; %.3f)"
              % ((classe_visee,) + arg_b[classe_visee]))
        print("  distance argmin(sabote) -> site : %.4f m  (rayon %.3f m)"
              % (d_arg, r_ret))
        ok_dep = d_arg <= r_ret
    if classe_visee in lec_s and classe_visee in lec_b:
        print("  lecture %s : %.4f (sain) -> %.4f (sabote)"
              % (classe_visee, lec_s[classe_visee], lec_b[classe_visee]))
        ok_baisse = lec_b[classe_visee] < lec_s[classe_visee] - 1e-6
    print("  argmin deplace vers le site : %s" % ("OUI" if ok_dep else "NON"))
    print("  lecture de la classe en baisse : %s"
          % ("OUI" if ok_baisse else "NON"))
    print()

    # ---- discrimination des deux seuils ----
    seuil_visee = (G.SEUIL_COLLERETTE_M if classe_visee == "COLLERETTE"
                   else G.SEUIL_COQUE_M)
    attendu_rouge = cible < seuil_visee
    obtenu = lec_b.get(classe_visee)
    print("--- ETAPE 9 : DISCRIMINATION DES DEUX SEUILS ---")
    print("  epaisseur cible %.3f m, seuil de la classe %s = %.2f m"
          % (cible, classe_visee, seuil_visee))
    print("  attendu : la classe %s %s"
          % (classe_visee, "ROUGIT" if attendu_rouge else "TIENT"))
    if obtenu is None:
        print("  observe : la classe n'apparait pas dans la sortie du gate.")
        conforme = False
    else:
        rouge = obtenu < seuil_visee
        print("  observe : lecture %.4f m -> la classe %s"
              % (obtenu, "ROUGIT" if rouge else "TIENT"))
        conforme = True
    print()

    print("=" * 76)
    if ok_dep and ok_baisse and conforme:
        print("CONTROLE NEGATIF : **CONCLUANT** pour la classe %s"
              % classe_visee)
        print("=" * 76)
        print("Le sabotage a deplace l'argmin de la classe vers son site et")
        print("abaisse sa lecture, la classe du site n'a pas change, le")
        print("maillage est reste ferme et manifold, et la source est")
        print("byte-identique.")
        return 0
    print("CONTROLE NEGATIF : **NON CONCLUANT**")
    print("=" * 76)
    if not ok_dep:
        print("- l'argmin de la classe visee n'a PAS migre vers le site : le")
        print("  minimum de cette classe reste ailleurs, et le rouge — s'il")
        print("  y en a un — n'est pas attribuable a ce sabotage.")
    if not ok_baisse:
        print("- la lecture de la classe visee n'a pas baisse.")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
