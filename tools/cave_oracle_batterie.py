#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""BATTERIE DE CONTROLES NEGATIFS de `cave_oracle_global.py`.

Un oracle qu'on n'a pas essaye de tromper n'est pas un oracle : c'est une
opinion. Les deux instruments precedents ont ete condamnes non pas parce
qu'ils rendaient un mauvais verdict sur le candidat, mais parce que leurs
controles negatifs ne mordaient pas.

Cette batterie enchaine, pour CHAQUE controle, la sequence complete que le
contrat exige — et elle refuse de conclure si une seule etape manque :

  1. DERIVER les placements DU MAILLAGE VISE (`cave_oracle_placement.py`),
     une fois, et les publier ;
  2. FABRIQUER un controle FERME (booleen exact Blender, jamais un retrait
     de triangles), la fermeture etant prouvee AVANT et APRES ;
  3. PROUVER la fermeture du GLB exporte, par un second code que celui de
     la fabrique : 0 bord libre, 0 arete non-manifold. Un sabotage ouvert
     est declare INEXPLOITABLE et n'est PAS compte comme une reussite de
     l'oracle ;
  4. PROUVER qu'un chemin geometrique existe : rayon libre MESURE par
     rayons paralleles, et zero traversee restante sur l'axe. La largeur du
     cutter ne prouve rien ; seule la largeur qui reste ouverte compte ;
  5. obtenir le verdict ATTENDU ;
  6. RESTAURER — obtenu par construction, la source n'etant jamais
     reecrite, et verifie par sha256 avant/apres.

LES DEUX CONTROLES VERTS, ET POURQUOI IL EN FAUT DEUX
=====================================================

`temoin`  : aller-retour glTF sans aucune modification. Sans lui, un ROUGE
            pourrait venir de l'export plutot que du sabotage.

`placebo` : une bosse a demi enfouie dans la peau exterieure. Le maillage
            change VRAIMENT — nombre de faces et sha differents du temoin —
            et aucun defaut n'est cree.

Le second n'est pas un doublon du premier, et son absence etait le defaut
de methode de la version precedente. Six sabotages attendent ROUGE : un
oracle qui rougirait sur TOUT les passerait tous. Le `temoin` ne le
rattraperait pas necessairement, puisqu'il ne modifie rien. Le `placebo`,
lui, presente a l'oracle un maillage modifie et sain : c'est le seul
controle capable de faire echouer la batterie pour SUR-SENSIBILITE.

Une batterie qui ne sait qu'affirmer « detecte » est un test qui ne peut pas
echouer — l'anti-motif deplace d'un cran.

LE COUPLE (MAILLAGE, REPERES) DOIT ETRE COHERENT
================================================

MESURE DU 2026-08-16. Cette batterie a rendu 6/7 puis 7/7 sur la MEME
geometrie candidate, et 0/7 puis 2/7 sur la MEME geometrie R2a-3.4. La
difference n'etait ni le pas, ni la fabrique : c'etait le depot depuis
lequel l'oracle lisait ses reperes. Les `MODELE_*` ont ete re-derives a
R2a-3.5.2, et une geometrie mesuree avec les reperes d'une autre revision
rend un verdict credible sur un couple qui n'existe pas.

`--reperes` est donc transmis a la fabrique ET a l'oracle, et la source est
imprimee. Par defaut c'est le script de lieu du depot courant, ce qui n'est
correct que pour une geometrie de la meme revision.

Usage :
    python3 tools/cave_oracle_batterie.py --entree <glb> --travail <dir>
            [--pas 0.06] [--reperes f.gd] [--verrou <fichier>]
            [--types toit,poche]

Codes de sortie : 0 = toute la batterie conforme · 1 = au moins un controle
n'a pas rendu le verdict attendu, ou la source n'est pas verte · 3 = BLOQUE.
"""

import argparse
import hashlib
import json
import os
import subprocess
import sys
import time

ICI = os.path.dirname(os.path.abspath(__file__))

## Ce que chaque controle doit produire, et par quel axe le prouver.
## `axe` a None : le defaut n'est pas un tunnel, il se prouve par la
## topologie (composantes) et non par un rayon libre.
PLAN = [
    ("temoin",          None,             "VERT"),
    ("placebo",         None,             "VERT"),
    ("toit",            (0.0, 0.0, 1.0),  "ROUGE"),
    ("paroi_est",       (1.0, 0.0, 0.0),  "ROUGE"),
    ("paroi_ouest",     (-1.0, 0.0, 0.0), "ROUGE"),
    ("plancher",        (0.0, 0.0, -1.0), "ROUGE"),
    ("poche",           None,             "ROUGE"),
    ("roche_flottante", None,             "ROUGE"),
]


def sha256(chemin):
    return hashlib.sha256(open(chemin, "rb").read()).hexdigest()


def lancer(cmd, verrou=None, journal=None):
    """Execute, rend `(rc, sortie, duree)`. Le tube ne masque JAMAIS le RC.

    `tools/CLAUDE.md` : `cmd | tail` rend le code de TAIL. On capture donc
    sans tube, et `rc` est celui de la commande.
    """
    if verrou:
        # forme `flock FICHIER COMMANDE ARGS...`, sans `-c` : aucun shell
        # intermediaire, donc aucune citation a reussir. Un chemin porteur
        # d'espace casserait la forme `-c`.
        cmd = ["flock", verrou] + cmd
    debut = time.time()
    proc = subprocess.run(cmd, capture_output=True, text=True, cwd=ICI + "/..")
    duree = time.time() - debut
    texte = proc.stdout + proc.stderr
    if journal:
        with open(journal, "w", encoding="utf-8") as f:
            f.write("$ %s\n" % " ".join(cmd))
            f.write(texte)
            f.write("\nRC=%d\n" % proc.returncode)
    return proc.returncode, texte, duree


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--entree", required=True)
    ap.add_argument("--travail", required=True)
    ap.add_argument("--pas", type=float, default=0.06,
                    help="pas du portail d'etancheite. Le contrat impose "
                         "0,06 m au maximum : le meme oracle rend VERT a "
                         "0,10 et ROUGE a 0,06 sur la meme geometrie.")
    ap.add_argument("--reperes", default=None,
                    help="script de LIEU accompagnant CETTE geometrie")
    ap.add_argument("--verrou", default="/home/user/Zelda/.git/heavy_tools.lock")
    ap.add_argument("--types", default=None)
    ap.add_argument("--tentatives", type=int, default=6)
    ap.add_argument("--json", default=None)
    args = ap.parse_args()

    entree = os.path.abspath(args.entree)
    if not os.path.isfile(entree):
        print("BLOQUE : entree introuvable : %s" % entree)
        return 3
    if args.pas > 0.06 + 1e-9:
        print("BLOQUE : pas %.3f m > 0,06 m. Un portail dont le pas depasse "
              "la taille du defaut ne dit rien (contrat §5)." % args.pas)
        return 3
    os.makedirs(args.travail, exist_ok=True)
    travail = os.path.abspath(args.travail)
    sha_source_debut = sha256(entree)

    voulus = set(args.types.split(",")) if args.types else None
    plan = [p for p in PLAN if voulus is None or p[0] in voulus]

    print("=" * 78)
    print("BATTERIE DE CONTROLES NEGATIFS")
    print("=" * 78)
    print("source        : %s" % entree)
    print("source sha256 : %s" % sha_source_debut)
    print("pas de grille : %.3f m" % args.pas)
    print("reperes       : %s" % (args.reperes or "(depot courant)"))
    print()

    # --- 1. placements DERIVES, une fois, publies ------------------------
    print("-" * 78)
    print("PLACEMENTS DERIVES DE CE MAILLAGE")
    print("-" * 78)
    cmd = ["python3", "tools/cave_oracle_placement.py", entree,
           "--json", os.path.join(travail, "PLACEMENTS.json")]
    if args.reperes:
        cmd += ["--reperes", os.path.abspath(args.reperes)]
    rc, txt, _ = lancer(cmd, journal=os.path.join(travail, "0_placements.log"))
    for ligne in txt.splitlines():
        if ligne.startswith("   ") or "DERIVATION IMPOSSIBLE" in ligne:
            print(ligne)
    if rc != 0:
        print("BLOQUE : placements non derivables (rc=%d). Sans eux, la "
              "fabrique retomberait sur des constantes d'une autre "
              "geometrie." % rc)
        return 3
    chemin_plc = os.path.join(travail, "PLACEMENTS.json")
    plc = json.load(open(chemin_plc, encoding="utf-8"))
    graine = ",".join("%.4f" % v for v in plc["graine"]["point"])
    print()

    # --- 1 bis. LE VERDICT DE LA SOURCE, MESURE D'ABORD ------------------
    #
    # Sans ce garde-fou, la batterie est un test qui ne peut pas echouer.
    # Six de ses huit controles attendent ROUGE. Sur une source DEJA
    # defectueuse, ces six-la rougissent de toute facon — pour le defaut de
    # la source, pas pour le sabotage — et seraient comptes CONFORMES. La
    # batterie afficherait alors un bon score en ne demontrant rien.
    #
    # Mesure du 2026-08-16 : le candidat `cc3596c5` est VERT au pas de
    # 0,10 m et ROUGE au pas de 0,06 m, sa percee de 85,8 cm2 etant sous la
    # resolution du premier. Une batterie jouee a 0,10 sur cette geometrie
    # rendait donc 7/7 sans que rien ne le signale.
    print("-" * 78)
    print("VERDICT DE LA SOURCE, AVANT TOUT SABOTAGE")
    print("-" * 78)
    cmd = ["python3", "tools/cave_oracle_global.py", entree,
           "--pas", "%.3f" % args.pas]
    if args.reperes:
        cmd += ["--reperes", os.path.abspath(args.reperes)]
    rc, txt, dt = lancer(
        cmd, journal=os.path.join(travail, "0b_source_avant.log"))
    verdict_avant = "ROUGE" if rc == 1 else ("VERT" if rc == 0 else "BLOQUE")
    print("   oracle sur la source en %.0f s : %s   (RC=%d)"
          % (dt, verdict_avant, rc))
    for l in txt.splitlines():
        if l.strip().startswith(("C1 :", "C2 :", "C3 :", "C4 :", "T1 :",
                                 "T2 :", "T3 :")):
            print("      %s" % l.strip()[:150])
    source_saine = (verdict_avant == "VERT")
    if not source_saine:
        print()
        print("   AVERTISSEMENT : la source n'est pas VERTE a ce pas.")
        print("   Les controles attendus ROUGE deviennent NON INFORMATIFS :")
        print("   ils rougiraient pour le defaut de la source, pas pour le")
        print("   sabotage. Ils sont joues et publies, mais ne comptent pas")
        print("   comme preuve de falsifiabilite de l'oracle.")
    print()

    resultats = []
    for nom, axe, attendu in plan:
        print("-" * 78)
        print("CONTROLE : %s     (attendu : %s)" % (nom, attendu))
        print("-" * 78)
        fiche = dict(nom=nom, attendu=attendu, axe=axe)

        # 2. fabriquer -----------------------------------------------------
        rc, txt, dt = lancer(
            ["python3", "tools/cave_oracle_sabotage.py",
             "--entree", entree, "--sortie", travail, "--type", nom,
             "--placements", chemin_plc,
             "--tentatives", str(args.tentatives)],
            verrou=args.verrou,
            journal=os.path.join(travail, "1_fabrique_%s.log" % nom))
        fiche["fabrique_rc"] = rc
        glb = os.path.join(travail, "SABOTAGE_%s.glb" % nom)
        for ligne in txt.splitlines():
            if "SABOTAGE-FERMETURE-AVANT" in ligne or \
               "SABOTAGE-FACES-A" in ligne or \
               "SABOTAGE-TENTATIVES" in ligne or \
               "SABOTAGE-ECHEC" in ligne:
                print("   %s" % ligne.strip())
        for ligne in txt.splitlines():
            if "SABOTAGE-TENTATIVES :" in ligne:
                fiche["tentatives"] = int(ligne.split(":")[1])
        if rc != 0 or not os.path.isfile(glb):
            print("   BLOQUE : fabrication impossible (rc=%d)" % rc)
            fiche["etat"] = "BLOQUE"
            resultats.append(fiche)
            continue
        fiche["glb"] = glb
        fiche["sha256"] = sha256(glb)
        print("   fabrique en %.0f s   sha256 %s" % (dt, fiche["sha256"][:16]))

        # 3. fermeture, mesuree sur le GLB exporte -------------------------
        rc, txt, _ = lancer(
            ["python3", "tools/cave_oracle_global.py", glb,
             "--topologie-seule"],
            journal=os.path.join(travail, "2_fermeture_%s.log" % nom))
        for ligne in txt.splitlines():
            if "bords libres" in ligne or "composante 0" in ligne or \
               "composante 1" in ligne:
                print("  %s" % ligne)
        ouvert = "bords libres 0" not in txt or \
                 "aretes non-manifold 0" not in txt
        fiche["ferme"] = not ouvert
        if ouvert:
            print("   INEXPLOITABLE : le sabotage a OUVERT le maillage.")
            print("   Un vert obtenu ici ne prouverait rien sur l'oracle —")
            print("   c'est exactement l'erreur de la passe precedente.")
            fiche["etat"] = "INEXPLOITABLE"
            resultats.append(fiche)
            continue

        # 3 bis. le placebo doit avoir REELLEMENT change le maillage -------
        if nom == "placebo":
            temoin = [f for f in resultats if f["nom"] == "temoin"]
            if temoin and temoin[0].get("sha256") == fiche["sha256"]:
                print("   INEXPLOITABLE : le placebo est identique au "
                      "temoin — il ne prouve rien sur la sur-sensibilite.")
                fiche["etat"] = "INEXPLOITABLE"
                resultats.append(fiche)
                continue
            fiche["different_du_temoin"] = True

        # 4. chemin geometrique reel --------------------------------------
        if axe is not None:
            # `--vers=-1,0,0` et non `--vers -1,0,0` : argparse prend un
            # argument commencant par `-` pour une option et sort en 2.
            # Mesure du 2026-08-16 : `paroi_ouest` a ete rapporte « axe
            # encore barre » alors que le tunnel etait parfaitement perce.
            # Le sabotage etait bon, l'appel etait faux, et le journal
            # accusait la geometrie.
            rc, txt, _ = lancer(
                ["python3", "tools/cave_oracle_percee.py", glb,
                 "--depuis=" + graine,
                 "--vers=%g,%g,%g" % axe],
                journal=os.path.join(travail, "3_percee_%s.log" % nom))
            for ligne in txt.splitlines():
                if "RAYON LIBRE" in ligne or "traversees restantes" in ligne \
                        or "AXE " in ligne:
                    print("   %s" % ligne)
            fiche["percee_rc"] = rc
            for ligne in txt.splitlines():
                if "RAYON LIBRE" in ligne:
                    fiche["rayon_libre_m"] = float(ligne.split(":")[1]
                                                   .split("m")[0])
            # UN ECHEC D'OUTIL N'EST PAS UN CONSTAT SUR LA GEOMETRIE.
            # `cave_oracle_percee.py` rend 1 quand l'axe est reellement
            # barre — un fait mesure — et 2 ou 3 quand il n'a pas pu
            # mesurer. Les confondre revient a faire accuser le maillage
            # par un bug d'appel, ce qui est arrive ici meme.
            if rc >= 2:
                print("   BLOQUE : la mesure de percee n'a pas pu s'executer "
                      "(rc=%d). Ce n'est PAS un constat sur la geometrie."
                      % rc)
                fiche["etat"] = "BLOQUE"
                resultats.append(fiche)
                continue
            if rc == 1:
                print("   INEXPLOITABLE : l'axe est encore barre (mesure).")
                fiche["etat"] = "INEXPLOITABLE"
                resultats.append(fiche)
                continue

        # 5. verdict de l'oracle ------------------------------------------
        cmd = ["python3", "tools/cave_oracle_global.py", glb,
               "--pas", "%.3f" % args.pas]
        if args.reperes:
            cmd += ["--reperes", os.path.abspath(args.reperes)]
        rc, txt, dt = lancer(
            cmd, journal=os.path.join(travail, "4_oracle_%s.log" % nom))
        verdict = "ROUGE" if rc == 1 else ("VERT" if rc == 0 else "BLOQUE")
        fiche["oracle_rc"] = rc
        fiche["verdict"] = verdict
        motifs = [l.strip() for l in txt.splitlines()
                  if l.strip().startswith(("C1 :", "C2 :", "C3 :", "C4 :",
                                           "T1 :", "T2 :", "T3 :"))]
        fiche["motifs"] = motifs
        print("   oracle en %.0f s : %s   (RC=%d)" % (dt, verdict, rc))
        for m in motifs:
            print("      %s" % m[:150])
        if verdict != attendu:
            fiche["etat"] = "NON CONFORME"
        elif attendu == "ROUGE" and not source_saine:
            # Il a bien rougi, mais la source rougissait deja : ce rouge ne
            # prouve rien sur le sabotage.
            fiche["etat"] = "NON INFORMATIF"
        else:
            fiche["etat"] = "CONFORME"
        print("   -> %s" % fiche["etat"])
        resultats.append(fiche)
        print()

    # 6. restauration + vert sur la source --------------------------------
    print("-" * 78)
    print("RESTAURATION ET VERT SUR LA SOURCE")
    print("-" * 78)
    sha_source_fin = sha256(entree)
    print("   sha256 source AVANT batterie : %s" % sha_source_debut)
    print("   sha256 source APRES batterie : %s" % sha_source_fin)
    identique = sha_source_debut == sha_source_fin
    print("   -> %s" % ("BYTE-IDENTIQUE" if identique
                        else "LA SOURCE A ETE MODIFIEE !"))
    cmd = ["python3", "tools/cave_oracle_global.py", entree,
           "--pas", "%.3f" % args.pas]
    if args.reperes:
        cmd += ["--reperes", os.path.abspath(args.reperes)]
    rc, txt, dt = lancer(
        cmd, journal=os.path.join(travail, "5_source_restauree.log"))
    verdict_source = "ROUGE" if rc == 1 else ("VERT" if rc == 0 else "BLOQUE")
    print("   oracle sur la source en %.0f s : %s   (RC=%d)"
          % (dt, verdict_source, rc))

    print()
    print("=" * 78)
    print("%-18s %-8s %-8s %-14s %-10s %s"
          % ("controle", "attendu", "obtenu", "etat", "tentatives",
             "rayon libre"))
    print("-" * 78)
    for f in resultats:
        rl = ("%.3f m" % f["rayon_libre_m"]) if "rayon_libre_m" in f else "-"
        print("%-18s %-8s %-8s %-14s %-10s %s"
              % (f["nom"], f["attendu"], f.get("verdict", "-"),
                 f["etat"], f.get("tentatives", "-"), rl))
    print("-" * 78)
    mauvais = [f for f in resultats if f["etat"] != "CONFORME"]
    ok = ((not mauvais) and identique and verdict_source == "VERT"
          and source_saine)
    print("BATTERIE : %s" % ("CONFORME" if ok else "NON CONFORME"))
    if not source_saine:
        print("   MOTIF PREMIER : la source est %s a ce pas. La batterie ne "
              "peut pas" % verdict_avant)
        print("   demontrer la falsifiabilite de l'oracle sur une geometrie "
              "deja defectueuse ;")
        print("   corriger la geometrie, puis rejouer.")
    if mauvais:
        print("   non conformes : %s"
              % ", ".join("%s (%s)" % (f["nom"], f["etat"]) for f in mauvais))
    print("=" * 78)

    if args.json:
        json.dump(dict(source=entree, sha256_debut=sha_source_debut,
                       sha256_fin=sha_source_fin, pas=args.pas,
                       reperes=args.reperes, placements=plc,
                       resultats=resultats, verdict_source=verdict_source),
                  open(args.json, "w"), indent=2)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
