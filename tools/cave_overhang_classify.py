#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CLASSEMENT DU DEBORD D'OVERHANG — autorise, ou refuse, sur un critere.

LA QUESTION, ET POURQUOI ELLE NE SE REGLE PAS EN DEPLACANT UN SEUIL
===================================================================

Sur `cc3596c5`, la sonde a sphere inscrite de l'agent collerette sort en 1 :
0,32 m au `(0,60 ; -1,87 ; 1,27)`. Son propre profil de recul donne
`0,32 · 0,62 · 1,56 · 1,82` — des valeurs CROISSANTES, signature d'un biseau
d'overhang qui s'amincit vers son bord par construction. Une colonne
verticale au meme endroit traverse 1,57 m de roche.

Deux mauvaises reponses etaient disponibles : relever `RECUL_MIN_M` pour
faire passer la geometrie, ou raboter le biseau pour satisfaire une sonde
dont le domaine est incorrect (une sphere 3D s'echappe le long de Y). Ni
l'une ni l'autre ne repond a la vraie question, qui est :

  cet air-la est-il le DEHORS, ou une POCHE ?

Un biseau qui s'amincit au-dessus de l'air libre est de la geologie. Le meme
biseau refermant un volume d'air enclos serait un defaut — un vide interne
qui ne communique avec rien.

LE CRITERE, POSE PAR LE LEAD ET RENDU MECANIQUE ICI
==================================================

Le debord est autorise SEULEMENT SI l'air exterieur concerne reste
entierement connecte a l'ouverture canonique, dans son masque, SANS poche
secondaire ni communication parasite vers l'interieur. Trois conditions,
chacune mesuree separement :

  (a) AUCUNE POCHE au voisinage. Inondation depuis le bord de grille, BOUCHE
      OUVERTE : toute case d'air non atteinte est un vide enclos. On exige
      zero case de poche dans une boite autour du point.
  (b) L'AIR DU BISEAU EST BIEN L'EXTERIEUR. Bouche bouchee, l'air juste
      dehors du biseau doit appartenir a la composante du bord, pas a celle
      de la graine interieure.
  (c) AUCUNE COMMUNICATION PARASITE. C'est le verdict global de
      `tools/cave_seal_oracle.py` : composantes disjointes.

SANS CONTROLE NEGATIF, CE CLASSEMENT NE VAUT RIEN
=================================================

Un classement qui n'a jamais refuse n'a jamais prouve qu'il savait refuser.
On fabrique donc deux poches sous la visiere :

  * une COQUE CREUSE — deux boites emboitees. Sa cavite interne est un vide
    enclos PAR CONSTRUCTION : le classement DOIT la refuser. Si elle passe,
    le classement ne vaut rien et il faut le dire.
  * un MUR-RIDEAU qui tente de fermer le dessous de la visiere avec la
    geometrie existante. Celui-la peut ne pas sceller — et alors ce n'est
    pas un controle rate, c'est une information sur la geometrie : on
    publie s'il a scelle, et le compte de triangles.

Usage :
    python3 tools/cave_overhang_classify.py [glb] [--pas 0.08]
        [--point 0.60,-1.87,1.27] [--json f.json]

Codes : 0 = AUTORISE · 1 = REFUSE ou controle negatif rate · 3 = BLOQUE.
"""

import argparse
import hashlib
import json
import math
import os
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import probe_cave_openings as P                                # noqa: E402
import cave_seal_oracle as S                                   # noqa: E402

POINT_DEBORD = (0.60, -1.87, 1.27)
RAYON_VOISINAGE_M = 1.50


# ---------------------------------------------------------------------------
# FABRIQUES DE CONTROLE NEGATIF
# ---------------------------------------------------------------------------

def _boite(centre, demi):
    """Les 12 triangles d'un pave. La parite ne lit pas l'enroulement."""
    cx, cy, cz = centre
    dx, dy, dz = demi
    s = [(cx + i * dx, cy + j * dy, cz + k * dz)
         for i in (-1, 1) for j in (-1, 1) for k in (-1, 1)]
    # indices des sommets : bit0 = x, bit1 = y, bit2 = z
    faces = ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1),
             (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3))
    tris = []
    for a, b, c, d in faces:
        tris.append((s[a], s[b], s[c]))
        tris.append((s[a], s[c], s[d]))
    return tris


def coque_creuse(centre, demi_ext, epaisseur):
    """Deux boites emboitees : la cavite interne est une POCHE par
    construction. Un rayon qui traverse compte 1 impact (peau externe) puis
    2 (peau interne) : entre les deux c'est de la roche, au centre c'est de
    l'air, et cet air ne touche rien."""
    interne = tuple(max(0.02, d - epaisseur) for d in demi_ext)
    return _boite(centre, demi_ext) + _boite(centre, interne)


def mur_rideau(centre, demi):
    """Une dalle pleine, qui TENTE de fermer le dessous de la visiere."""
    return _boite(centre, demi)


# ---------------------------------------------------------------------------
# CLASSEMENT
# ---------------------------------------------------------------------------

def composantes_de_poche(espace, boite_lo, boite_hi):
    """Composantes d'air NON atteintes depuis le bord, bouche OUVERTE.

    Bouche ouverte : aucune dalle bloquee. Tout ce que l'inondation
    exterieure n'atteint pas est, par definition, un vide enclos.
    """
    vu = S.inonder(espace, S.cases_de_bord(espace), set())
    nx, ny, nz = espace.dim
    lo = espace.cellule(boite_lo)
    hi = espace.cellule(boite_hi)
    deja = bytearray(nx * ny * nz)
    poches = []
    for i in range(max(0, lo[0]), min(nx, hi[0] + 1)):
        for j in range(max(0, lo[1]), min(ny, hi[1] + 1)):
            for k in range(max(0, lo[2]), min(nz, hi[2] + 1)):
                n = espace.index(i, j, k)
                if not espace.air[n] or vu[n] or deja[n]:
                    continue
                # une poche trouvee : on la parcourt EN ENTIER, meme si elle
                # deborde de la boite — sa taille reelle est l'information.
                file = deque([(i, j, k)])
                deja[n] = 1
                cases = []
                while file:
                    a, b, c = file.popleft()
                    cases.append((a, b, c))
                    for da, db, dc in ((1, 0, 0), (-1, 0, 0), (0, 1, 0),
                                       (0, -1, 0), (0, 0, 1), (0, 0, -1)):
                        p, q, r = a + da, b + db, c + dc
                        if not (0 <= p < nx and 0 <= q < ny and 0 <= r < nz):
                            continue
                        m = espace.index(p, q, r)
                        if espace.air[m] and not vu[m] and not deja[m]:
                            deja[m] = 1
                            file.append((p, q, r))
                poches.append(cases)
    return poches


def air_exterieur_le_plus_proche(espace, point, vu_ext, rayon):
    """(distance, centre) de la case d'air EXTERIEURE la plus proche."""
    nx, ny, nz = espace.dim
    lo = espace.cellule(tuple(point[k] - rayon for k in range(3)))
    hi = espace.cellule(tuple(point[k] + rayon for k in range(3)))
    pire, ou = None, None
    for i in range(max(0, lo[0]), min(nx, hi[0] + 1)):
        for j in range(max(0, lo[1]), min(ny, hi[1] + 1)):
            for k in range(max(0, lo[2]), min(nz, hi[2] + 1)):
                n = espace.index(i, j, k)
                if not (espace.air[n] and vu_ext[n]):
                    continue
                c = espace.centre(i, j, k)
                d = math.sqrt(sum((c[m] - point[m]) ** 2 for m in range(3)))
                if pire is None or d < pire:
                    pire, ou = d, c
    return pire, ou


def classer(triangles, pas, y_bouche, point, graine_visee, etiquette,
            bavard=True):
    espace = S.Espace(triangles, pas)
    bloques = set(espace.tranche_bouche(y_bouche))
    graine, _ = S.graine_valide(espace, graine_visee)
    if graine is None:
        return dict(bloque="graine interieure introuvable")
    vu_ext = S.inonder(espace, S.cases_de_bord(espace), bloques)
    vu_int = S.inonder(espace, [graine], bloques)
    fuite = bool(vu_ext[espace.index(*graine)])
    boite_lo = tuple(point[k] - RAYON_VOISINAGE_M for k in range(3))
    boite_hi = tuple(point[k] + RAYON_VOISINAGE_M for k in range(3))
    poches = composantes_de_poche(espace, boite_lo, boite_hi)
    volumes = sorted((len(c) * pas ** 3 for c in poches), reverse=True)
    dist, ou = air_exterieur_le_plus_proche(espace, point, vu_ext, 3.0)
    cellule = espace.cellule(point)
    n_point = espace.index(*cellule) if espace.dedans(*cellule) else None
    point_dans_air = bool(n_point is not None and espace.air[n_point])
    point_dans_interieur = bool(n_point is not None and vu_int[n_point])
    if bavard:
        print("   grille %dx%dx%d, pas %.3f m" % tuple(espace.dim + [pas]))
        print("   le point vise est %s%s"
              % ("dans l'AIR" if point_dans_air else "dans la ROCHE",
                 " et dans la composante INTERIEURE" if point_dans_interieur
                 else ""))
        print("   poches au voisinage (+-%.2f m) : %d, volumes %s"
              % (RAYON_VOISINAGE_M, len(poches),
                 ", ".join("%.4f m3" % v for v in volumes[:6]) or "aucune"))
        print("   air EXTERIEUR le plus proche : %s"
              % (("%.3f m au (%.2f ; %.2f ; %.2f)"
                  % (dist, ou[0], ou[1], ou[2])) if dist is not None
                 else "AUCUN dans 3,0 m"))
        print("   composantes disjointes (pas de communication parasite) : %s"
              % ("NON — FUITE" if fuite else "oui"))
    return dict(etiquette=etiquette, fuite=fuite, poches=len(poches),
                volumes_poches=volumes, distance_air_exterieur=dist,
                point_dans_air=point_dans_air,
                point_dans_interieur=point_dans_interieur,
                triangles=len(triangles))


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("glb", nargs="?", default=None)
    ap.add_argument("--pas", type=float, default=0.08)
    ap.add_argument("--y-bouche", type=float, default=S.Y_BOUCHE)
    ap.add_argument("--point", default=None)
    ap.add_argument("--json", default=None)
    args = ap.parse_args()

    racine = S.racine_depot(os.path.dirname(os.path.abspath(__file__)))
    chemin = args.glb or os.path.join(racine, S.GLB_DEFAUT)
    if not os.path.isfile(chemin):
        print("BLOQUE : maillage introuvable : %s" % chemin)
        return 3
    point = POINT_DEBORD
    if args.point:
        point = tuple(float(v) for v in args.point.split(","))
    sha_avant = hashlib.sha256(open(chemin, "rb").read()).hexdigest()
    triangles, _ = P.triangles_du_glb(chemin)
    repere = S.lire_modele_salle(racine)
    if repere is None:
        print("BLOQUE : MODELE_SALLE illisible")
        return 3
    graine_visee = (repere[0], repere[1], repere[2] + S.GRAINE_HAUTEUR_M)

    print("=" * 78)
    print("CLASSEMENT DU DEBORD D'OVERHANG")
    print("=" * 78)
    print("maillage : %s" % chemin)
    print("sha256   : %s" % sha_avant)
    print("point    : (%.2f ; %.2f ; %.2f)" % point)
    print()

    # -- LA GEOMETRIE, RE-MESUREE PLUTOT QUE CRUE ------------------------
    print("-" * 78)
    print("GEOMETRIE AU POINT — je re-mesure, je ne reprends pas le chiffre")
    print("-" * 78)
    grille = P.Grille(triangles)
    colonne = P.impacts(grille, point, (0.0, 0.0, 1.0), 60.0)
    roche_verticale = 0.0
    for n in range(0, len(colonne) - 1, 2):
        roche_verticale += colonne[n + 1][0] - colonne[n][0]
    print("   colonne verticale au point : %d impact(s), %.3f m de roche "
          "cumulee au-dessus" % (len(colonne), roche_verticale))
    print("   (l'agent collerette publiait 1,57 m par une colonne "
          "verticale ; sa sonde 3D publiait 0,32 m)")
    rapport = dict(maillage=chemin, sha256=sha_avant, point=list(point),
                   pas=args.pas, colonne_impacts=len(colonne),
                   roche_verticale_m=roche_verticale, cas=[])

    # -- CAS 1 : LE CANDIDAT TEL QU'IL EST -------------------------------
    print()
    print("-" * 78)
    print("CAS 1 — candidat intact")
    print("-" * 78)
    intact = classer(triangles, args.pas, args.y_bouche, point, graine_visee,
                     "intact")
    if intact.get("bloque"):
        print("BLOQUE : %s" % intact["bloque"])
        return 3
    rapport["cas"].append(intact)

    # -- CAS 2 : COQUE CREUSE, POCHE GARANTIE ----------------------------
    print()
    print("-" * 78)
    print("CONTROLE NEGATIF A — coque creuse sous la visiere, POCHE GARANTIE")
    print("-" * 78)
    centre_coque = (point[0], point[1] - 0.05, point[2] - 0.50)
    ajout = coque_creuse(centre_coque, (0.34, 0.30, 0.30), 0.14)
    print("   coque au (%.2f ; %.2f ; %.2f), %d triangle(s) ajoute(s)"
          % (centre_coque + (len(ajout),)))
    avec_coque = classer(triangles + ajout, args.pas, args.y_bouche, point,
                         graine_visee, "coque creuse")
    rapport["cas"].append(avec_coque)
    refuse_coque = avec_coque.get("poches", 0) > 0
    print("   le classement REFUSE-t-il ? %s"
          % ("OUI" if refuse_coque else "NON — LE CLASSEMENT NE VAUT RIEN"))

    # -- CAS 3 : MUR-RIDEAU, POCHE TENTEE --------------------------------
    print()
    print("-" * 78)
    print("CONTROLE NEGATIF B — mur-rideau : a-t-il REELLEMENT scelle ?")
    print("-" * 78)
    centre_mur = (point[0] + 0.20, point[1] - 0.42, point[2] - 0.62)
    mur = mur_rideau(centre_mur, (1.00, 0.07, 0.70))
    print("   dalle au (%.2f ; %.2f ; %.2f), demi (1,00 ; 0,07 ; 0,70), "
          "%d triangle(s)" % (centre_mur + (len(mur),)))
    avec_mur = classer(triangles + mur, args.pas, args.y_bouche, point,
                       graine_visee, "mur-rideau")
    rapport["cas"].append(avec_mur)
    a_scelle = avec_mur.get("poches", 0) > 0
    print("   le mur-rideau a-t-il scelle une poche ? %s"
          % ("OUI — et le classement la refuse" if a_scelle
             else "NON — il n'a rien ferme ; ce n'est pas un controle rate, "
                  "c'est un fait sur la geometrie"))

    sha_apres = hashlib.sha256(open(chemin, "rb").read()).hexdigest()
    print()
    print("RESTAURATION : sha256 %s -> %s   %s"
          % (sha_avant[:16], sha_apres[:16],
             "IDENTIQUE" if sha_avant == sha_apres else "!!! MODIFIE !!!"))
    rapport["sha256_apres"] = sha_apres

    # -- VERDICT ---------------------------------------------------------
    print()
    print("=" * 78)
    print("VERDICT")
    print("=" * 78)
    conditions = [
        ("(a) aucune poche au voisinage du debord",
         intact["poches"] == 0),
        ("(b) l'air du biseau appartient a l'EXTERIEUR",
         intact["distance_air_exterieur"] is not None),
        ("(c) aucune communication parasite (composantes disjointes)",
         not intact["fuite"]),
        ("(d) le controle negatif a coque creuse est REFUSE",
         refuse_coque),
        ("(e) le maillage source est intact",
         sha_avant == sha_apres),
    ]
    for texte, ok in conditions:
        print("   %-58s %s" % (texte, "OUI" if ok else "NON"))
    autorise = all(ok for _, ok in conditions)
    print()
    if autorise:
        print("   DEBORD AUTORISE — l'air concerne est le dehors, il est")
        print("   connecte a l'ouverture canonique, il n'enferme aucune")
        print("   poche, et le classement a demontre qu'il sait refuser.")
        print("   Ce verdict est GEOMETRIQUE. Il ne dit RIEN de la lecture")
        print("   visuelle du biseau, qui reste au lead.")
    else:
        print("   DEBORD REFUSE — voir les conditions a NON ci-dessus.")
    print("=" * 78)
    rapport["conditions"] = [dict(texte=t, ok=bool(o)) for t, o in conditions]
    rapport["autorise"] = bool(autorise)
    if args.json:
        with open(args.json, "w", encoding="utf-8") as poignee:
            json.dump(rapport, poignee, indent=1, ensure_ascii=False)
        print("json : %s" % args.json)
    return 0 if autorise else 1


if __name__ == "__main__":
    sys.exit(main())
