#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""COQUE STRUCTURELLE A DEUX SEUILS — addendum §3, execute.

CE QUI CHANGE PAR RAPPORT A `cave_check_hull.py`
================================================
Le masque de bouche n'EXCLUT plus, il CLASSE (addendum §0.1) :

    d_masque(p) <= 0,60  ->  COLLERETTE, seuil 0,60 m
    d_masque(p) >  0,60  ->  COQUE,      seuil 0,80 m

Plus rien n'est exempte. C'est strictement plus exigeant que la version
precedente, ou l'emprise du masque n'etait pas mesuree du tout. Les trois
verdicts du contrat §5.1 s'appliquent SEPAREMENT a chaque classe, avec son
propre seuil, et le verdict global est LE PLUS FAIBLE des deux — jamais leur
moyenne.

LA TERMINAISON EST UN COMPORTEMENT DE PREMIERE CLASSE
=====================================================
`cave_check_hull.py` NE TERMINE PAS sur R2a-3.4. Mesure du predecesseur :
628 m2 de peau interieure demandaient 16 854 916 echantillons a h = 0,15,
soit un pas effectif de 6 mm — vingt-cinq fois plus fin que necessaire —
parce que la subdivision est 4-AIRE ET UNIFORME : quelques triangles a grand
rayon imposent leur profondeur a toute la face. Son journal s'arrete sans
`RC=`, et l'epaisseur de R2a-3.4 n'a donc JAMAIS ete mesuree.

La couverture restait prouvee ; c'est le COUT qui ne l'etait pas. Un
sur-echantillonnage ne rend rien faux, il rend la mesure inatteignable.

On remplace la subdivision uniforme par une SEPARATION ET EVALUATION
(branch and bound) qui ne raffine que ce qui peut encore changer le verdict :

  * chaque cellule porte son centroide `g` et son rayon de couverture EXACT
    `r = max_i |V_i - g|` ;
  * la distance `d(g)` a la peau exterieure est 1-lipschitzienne, donc sur
    toute la cellule :   d(g) - r  <=  d_vrai  <=  d(g) + r ;
  * les cellules sont traitees par `d - r` CROISSANT — d'abord la ou le
    minimum peut vivre. La lecture chute vite, et tout le reste s'elague ;
  * une cellule qui ne peut plus ni abaisser la lecture ni faire basculer le
    verdict (`d - r >= lecture` ET `d - r >= seuil`) est finalisee telle
    quelle ;
  * les autres sont coupees en quatre par les milieux d'aretes.

LA BORNE EST `min_i (d_i - r_i)`, ET C'EST PLUS FORT QUE `lecture - h`.
Le contrat §2.6 ecrit `borne = lecture - h` parce que la version uniforme
n'avait qu'un seul `h` global. Ici chaque cellule porte SON rayon, et la
minoration exacte se prend cellule par cellule. C'est la meme inegalite,
appliquee au bon endroit : elle est toujours au moins aussi forte, et le `h`
publie devient `lecture - borne`, MESURE au lieu d'etre demande.

Pourquoi cela comptait : la premiere version s'arretait de raffiner des que
`d < seuil` (FAIL avere). Elle rendait donc `lecture 0,0320` avec une cellule
de rayon 1,297 m, soit une borne de -0,1179 m — une epaisseur negative, qui
ne dit rien d'autre que « la resolution ne permet pas de conclure ici ».

Si le budget d'echantillons est epuise avant que la question soit tranchee,
l'outil sort en **BLOQUE (RC=3)** avec le `h` reellement atteint et le cout
mesure. Un instrument qui ne termine pas doit le DIRE — jamais s'arreter en
silence, jamais laisser un journal sans `RC=` passer pour un verdict.

L'AMBIGUITE DE `s_enclos`, ET ELLE N'EST PAS TRANCHEE ICI
=========================================================
Mesure (voir `cave_masque_bouche.py`) : la condition §2.5 — « 72 rayons
rencontrent tous de la roche avant de sortir de la boite englobante » — est
vraie PARTOUT sur cette geometrie, des `s_dehors`. Deux causes mesurees :

  1. les rayons restent DANS LE PLAN DE SECTION, perpendiculaire a l'axe ;
     or une bouche de tunnel s'ouvre le LONG DE L'AXE. Lateralement, meme a
     la levre du porche, il y a le jambage ;
  2. « avant de sortir de la boite » est faible : la boite fait 17 x 16 x
     13 m, et un rayon lateral frappe le massif d'en face a 3 ou 4 m.

La lettre de l'addendum donne donc `s_enclos = s_dehors`, c'est-a-dire un
masque VIDE et tout classe COQUE a 0,80 m. C'est la lecture CONSERVATRICE :
elle ne peut pas rendre un vert qu'un masque plus long rendrait rouge.

On l'applique donc telle quelle, et on publie EN REGARD la sensibilite : le
verdict pour `s_final` = 0,5 / 1,0 / 1,5 / 2,0 / 2,5 m. Si le verdict ne
bouge pas, l'ambiguite n'est pas bloquante pour cette passe et cela se voit.
Si le verdict bouge, le resultat est BLOQUE et la question remonte.

USAGE
=====
    python3 tools/cave_check_coque_deux_seuils.py <fichier.glb> [options]
      --anciens-reperes    graines d'avant la re-derivation R2a-3.5.2
      --git=<objet>        tables du generateur par `git show`
      --git-lieu=<objet>   script de lieu par `git show`
      --h=0.15             rayon de couverture VISE (le h atteint est mesure)
      --budget=250000      plafond d'echantillons avant BLOQUE
      --pas-balayage=0.25  pas du balayage de derivation de la bouche
      --capsule            section du masque a la capsule reelle 0,35 / 1,80
      --json=<chemin>      ecrit le resultat

Codes retour : 0 PASS · 1 FAIL · 3 BLOQUE.
"""

import hashlib
import heapq
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cave_check_mesh as M          # noqa: E402
import cave_check_hull as H          # noqa: E402
import cave_masque_bouche as B       # noqa: E402

SEUIL_COLLERETTE_M = 0.60
SEUIL_COQUE_M = 0.80
# La bande de classification VAUT le seuil de collerette (addendum §3) :
# « la roche qui borde directement le masque » est celle qui se trouve a
# moins que son epaisseur exigee du passage. Aucune constante nouvelle.
BANDE_M = SEUIL_COLLERETTE_M

# Emprises de sensibilite publiees en regard de la lettre (voir en-tete).
SENSIBILITE_M = (0.0, 0.5, 1.0, 1.5, 2.0, 2.5)


def empreinte(chemin):
    h = hashlib.sha256()
    with open(chemin, "rb") as f:
        for bloc in iter(lambda: f.read(1 << 20), b""):
            h.update(bloc)
    return h.hexdigest()


def godot_de_modele(p):
    """Repere Godot depuis le repere modele : gx = ax ; gy = az ; gz = -ay."""
    return (p[0], p[2], -p[1])


# ==========================================================================
# Distance au volume MASQUE
# ==========================================================================

class Masque(object):
    """Volume balaye entre `s_dehors` et `s_final`, et distance a ce volume.

    `d_masque(p)` vaut 0 si `p` est DANS le volume, sinon la distance a sa
    frontiere. On calcule d'abord la distance a la frontiere, qui MAJORE
    `d_masque` ; le test d'appartenance n'est fait que pour les points assez
    loin de la frontiere pour que la reponse puisse changer la classe, et
    seulement s'ils sont dans la boite du masque. Le cout reste borne.
    """

    def __init__(self, chemin, gabarit, s0, s1):
        self.vide = (s1 - s0) <= 1e-9
        self.s0, self.s1 = s0, s1
        if self.vide:
            self.positions, self.faces = [], []
            return
        self.positions, self.faces, self.ss = B.maillage_masque(
            chemin, gabarit, s0, s1)
        self.hach = H.Hachage(self.positions, self.faces,
                              range(len(self.faces)), 0.5)
        lo, hi = M.boite(self.positions)
        self.lo, self.hi = lo, hi

    def distance(self, p):
        if self.vide:
            return float("inf")
        d, _f = self.hach.plus_proche(p)
        if d <= BANDE_M:
            return d          # deja collerette, l'appartenance ne change rien
        dans_boite = all(self.lo[k] - 1e-9 <= p[k] <= self.hi[k] + 1e-9
                         for k in range(3))
        if not dans_boite:
            return d
        w = H.enroulement(self.positions, self.faces, p)
        return 0.0 if abs(w) > 0.5 else d


# ==========================================================================
# Separation et evaluation — la terminaison, rendue explicite
# ==========================================================================

def cellules_initiales(positions, faces, indices):
    """Une cellule par triangle de la peau interieure."""
    out = []
    for fi in indices:
        a, b, c = faces[fi]
        t = (positions[a], positions[b], positions[c])
        r, g = H.rayon_de_couverture(*t)
        out.append((t, g, r, fi))
    return out


def couper(cellule):
    """Coupe en quatre par les milieux d'aretes. Les sous-triangles sont
    SEMBLABLES au parent, de rapport 1/2 : le rayon de couverture est divise
    par deux a chaque niveau, quel que soit l'aplatissement."""
    (p, q, r_), _g, _r, fi = cellule
    pq = tuple((p[k] + q[k]) / 2 for k in range(3))
    qr = tuple((q[k] + r_[k]) / 2 for k in range(3))
    rp = tuple((r_[k] + p[k]) / 2 for k in range(3))
    out = []
    for t in ((p, pq, rp), (pq, q, qr), (rp, qr, r_), (pq, qr, rp)):
        rc, g = H.rayon_de_couverture(*t)
        out.append((t, g, rc, fi))
    return out


def evaluer(cellules, hach_ext, masque, budget, h_vise, journal,
            filtre=None):
    """Separation et evaluation, par classe et par seuil.

    Rend un dictionnaire par classe : verdict, lecture (le plus petit `d`
    atteint), `h` MESURE (le plus grand rayon encore indecis), argmin, et le
    cout. Le budget plafonne le nombre d'evaluations de distance ; s'il est
    epuise avant decision, la classe sort en BLOQUE avec son `h` atteint.

    LE CLASSEMENT EXIGE UNE CELLULE PURE, ET C'EST UNE CORRECTION MESUREE.
    `d_masque` est 1-lipschitzienne, donc sur une cellule de rayon `r` elle
    vit dans `[dm - r ; dm + r]`. Une cellule n'est donc classee que si cet
    intervalle tombe entierement d'un cote de la bande :

        dm + r <= 0,60   -> toute la cellule est COLLERETTE
        dm - r >  0,60   -> toute la cellule est COQUE
        sinon            -> A CHEVAL : on RAFFINE, on ne classe pas

    Premiere version, et son defaut mesure : elle classait « COLLERETTE si
    dm + r <= 0,60, COQUE sinon », en croyant etre conservatrice. Resultat
    sur `c184c8dc` : ZERO cellule collerette, a toutes les emprises. La
    cause n'etait pas geometrique — les cellules du porche s'arretaient de
    se raffiner des que `d < 0,80` (FAIL avere), gardaient donc leur rayon
    initial, jusqu'a 1,64 m, et `dm + r <= 0,60` ne pouvait plus etre vrai.
    Le conservatisme se retournait : il supprimait la classe douce au lieu
    de la restreindre. On raffine donc AUSSI pour departager la classe.

    Une cellule a cheval que le budget ne permet plus de departager est
    comptee a part, publiee, et jugee au seuil DUR — la, le conservatisme
    est legitime, parce qu'il porte sur ce qui reste vraiment indecis.
    """
    etat = {
        "COLLERETTE": {"seuil": SEUIL_COLLERETTE_M, "lecture": float("inf"),
                       "argmin": None, "borne": float("inf"), "cell": 0,
                       "sous_seuil": 0},
        "COQUE": {"seuil": SEUIL_COQUE_M, "lecture": float("inf"),
                  "argmin": None, "borne": float("inf"), "cell": 0,
                  "sous_seuil": 0},
    }
    # LA BORNE EST LE MINIMUM DES `d - r`, PAS `lecture - h_global`.
    # Le contrat §2.6 pose `borne = lecture - h` parce que la version
    # uniforme n'avait qu'un seul `h`. Ici chaque cellule porte SON rayon,
    # et la minoration exacte est   min_vrai >= min_i (d_i - r_i)   sur
    # toutes les cellules qui recouvrent la peau. C'est la meme inegalite,
    # appliquee cellule par cellule au lieu du pire cas global : elle est
    # donc toujours au moins aussi FORTE, et le `h` publie devient
    # `lecture - borne`, MESURE au lieu d'etre demande.
    tas = []
    compteur = 0
    evaluations = 0
    a_cheval = 0

    def pousser(cel):
        """Evalue une cellule et la range par `d - r` croissant."""
        nonlocal evaluations, compteur
        (_t, g, r, fi) = cel
        # Le filtre de diagnostic s'applique AUSSI aux sous-cellules : une
        # cellule initiale retenue peut engendrer des filles qui reviennent
        # sur l'arete. Mesure : filtrer les seules cellules initiales a
        # 0,60 m du contour laissait la lecture a 0,0108 m — l'arete
        # revenait par la subdivision.
        if filtre is not None and not filtre(g, r):
            return
        dm = masque.distance(g)
        d, f_ext = hach_ext.plus_proche(g)
        evaluations += 1
        compteur += 1
        heapq.heappush(tas, (d - r, compteur, cel, d, dm, f_ext))

    for cel in cellules:
        if evaluations >= budget:
            break
        pousser(cel)

    def finaliser(classe, d, r, g, fi, dm, f_ext):
        e = etat[classe]
        e["cell"] += 1
        if d < e["lecture"]:
            e["lecture"] = d
            e["argmin"] = (g, fi, dm, f_ext, r)
        e["borne"] = min(e["borne"], d - r)
        if d < e["seuil"]:
            e["sous_seuil"] += 1

    epuise = False
    while tas:
        prio, _c, cel, d, dm, f_ext = heapq.heappop(tas)
        (_t, g, r, fi) = cel
        pur_collerette = (dm + r) <= BANDE_M
        pur_coque = (dm - r) > BANDE_M
        indetermine = not (pur_collerette or pur_coque)
        classe = ("COQUE" if (pur_coque or indetermine) else "COLLERETTE")
        e = etat[classe]
        # Une cellule qui ne peut ni abaisser la lecture ni faire basculer
        # le verdict est FINALISEE telle quelle : elle contribue a la borne
        # et on ne la coupe pas. C'est tout l'elagage.
        inutile = (prio >= e["lecture"]) and (prio >= e["seuil"])
        if r <= h_vise or inutile:
            if indetermine:
                a_cheval += 1
            finaliser(classe, d, r, g, fi, dm, f_ext)
            continue
        if evaluations + 4 > budget:
            epuise = True
            if indetermine:
                a_cheval += 1
            finaliser(classe, d, r, g, fi, dm, f_ext)
            continue
        for fille in couper(cel):
            pousser(fille)
    journal["evaluations"] = evaluations
    journal["budget_epuise"] = epuise
    journal["reste_en_file"] = len(tas)
    journal["a_cheval"] = a_cheval
    for cl, e in etat.items():
        e["h"] = (e["lecture"] - e["borne"]) if e["argmin"] is not None else 0.0
    for cl, e in etat.items():
        if e["argmin"] is None:
            e["verdict"] = "VIDE"
            continue
        # Contrat §5.1, applique tel quel, avec la borne fine.
        if e["lecture"] < e["seuil"]:
            e["verdict"] = "FAIL"        # mesure : `lecture` est ATTEINTE
        elif e["borne"] >= e["seuil"]:
            e["verdict"] = "PASS"        # garanti sur toute la classe
        else:
            e["verdict"] = "BLOQUE"      # la resolution ne tranche pas
    return etat


# ==========================================================================
# Pilote
# ==========================================================================

def opt(argv, nom, defaut):
    for a in argv:
        if a.startswith("--%s=" % nom):
            return a.split("=", 1)[1]
    return defaut


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    if not args:
        print(__doc__)
        return 3
    glb = args[0]
    ici = os.path.dirname(os.path.abspath(__file__))
    racine = B.racine_git(ici)
    h_vise = float(opt(argv, "h", "0.15"))
    budget = int(float(opt(argv, "budget", "250000")))
    pas_bal = float(opt(argv, "pas-balayage", "0.25"))
    anciens = "--anciens-reperes" in argv
    capsule = "--capsule" in argv
    objet_gen = opt(argv, "git", None)
    objet_lieu = opt(argv, "git-lieu", None)
    sortie = opt(argv, "json", None)
    s_final_force = opt(argv, "s-final", None)

    print("=" * 76)
    print("COQUE STRUCTURELLE A DEUX SEUILS — addendum §3")
    print("=" * 76)

    # ------------------------------------------------------------------
    # C3 — PROVENANCE, avant toute mesure
    # ------------------------------------------------------------------
    print()
    print("--- PROVENANCE (addendum §4) — publiee AVANT toute mesure ---")
    sha = empreinte(glb)
    print("  GLB     : %s" % glb)
    print("  sha256  : %s" % sha)
    if objet_gen:
        tables = B.tables_depuis_git(objet_gen, racine)
    else:
        gen = os.path.join(racine, "source_assets", "blender", "environment",
                           "make_waterfall_cave.py")
        with open(gen, "r", encoding="utf-8") as f:
            tables = B.charger_tables(f.read(), gen)
    if objet_lieu:
        txt_lieu = B.texte_depuis_git(objet_lieu, racine)
        org_lieu = "git:%s" % objet_lieu
    else:
        lieu = os.path.join(racine, "scripts", "world_v2", "poi",
                            "waterfall_cave_place.gd")
        with open(lieu, "r", encoding="utf-8") as f:
            txt_lieu = f.read()
        org_lieu = lieu
    print("  tables du generateur : %s" % tables["_origine"])
    print("  script de lieu       : %s" % org_lieu)
    seuil_mod, seuil_god = B.lire_repere_lieu(txt_lieu, "MODELE_SEUIL_DEHORS")
    salle_mod, salle_god = B.lire_repere_lieu(txt_lieu, "MODELE_SALLE")
    niche_mod, niche_god = B.lire_repere_lieu(txt_lieu, "MODELE_NICHE")
    print("  valeurs lues (Godot -> modele) :")
    for nom, gd, md in (("MODELE_SEUIL_DEHORS", seuil_god, seuil_mod),
                        ("MODELE_SALLE", salle_god, salle_mod),
                        ("MODELE_NICHE", niche_god, niche_mod)):
        print("    %-20s (%.3f ; %.3f ; %.3f) -> (%.3f ; %.3f ; %.3f)"
              % ((nom,) + tuple(gd) + tuple(md)))
    if anciens:
        salle_mod, niche_mod = H.SALLE_ANCIEN, H.NICHE_ANCIEN
        print("  --anciens-reperes : graines forcees aux valeurs pre-3.5.2")
    print()

    sommets, triangles = M.charger(glb, "SM_WaterfallCave", repere="modele")
    positions, faces, _st = M.souder(sommets, triangles)
    tab = M.aretes(faces)
    adj = M.graphe_dual(faces, tab)
    bl = sum(1 for inc in tab.values() if len(inc) == 1)
    nm = sum(1 for inc in tab.values() if len(inc) > 2)
    print("  fermeture : %d bords libres, %d non-manifold, %d faces"
          % (bl, nm, len(faces)))
    if bl or nm:
        print()
        print("BLOQUE (RC=3) : maillage ouvert ou non-manifold. Aucune notion")
        print("de dedans n'y est definie.")
        return 3

    print()
    print("  appartenance des reperes a l'AIR interieur (angle solide) :")
    faute_provenance = False
    for nom, p in (("MODELE_SALLE", salle_mod), ("MODELE_NICHE", niche_mod)):
        w = H.enroulement(positions, faces, p)
        dedans = abs(w) > 0.5
        print("    %-13s modele (%.3f ; %.3f ; %.3f)  enroulement %+.4f -> %s"
              % (nom, p[0], p[1], p[2], w, "ROCHE" if dedans else "AIR"))
        if dedans:
            faute_provenance = True
    if faute_provenance:
        print()
        print("=" * 76)
        print("BLOQUE (RC=3) : DEFAUT DE PROVENANCE, pas defaut de roche.")
        print("=" * 76)
        print("Un repere tombe dans la roche : le couple (maillage, reperes)")
        print("n'est pas coherent. Addendum §4 — « le verdict correct dans ce")
        print("cas est BLOQUE, jamais ROUGE ». Rendre ROUGE accuserait la")
        print("geometrie d'une faute qui appartient au script de lieu.")
        print("Si la geometrie est anterieure a R2a-3.5.2 : --anciens-reperes")
        return 3
    print("  -> provenance COHERENTE, la mesure peut commencer.")
    print()

    # ------------------------------------------------------------------
    # Peau interieure — meme derivation que `cave_check_hull.py`
    # ------------------------------------------------------------------
    print("--- peau interieure (contrat §2.1 a §2.4) ---")
    hach_tout = H.Hachage(positions, faces, range(len(faces)), 0.5)
    temoins = H.faces_du_dehors(positions, faces)
    _d, f_salle = hach_tout.plus_proche(salle_mod)
    _d, f_niche = hach_tout.plus_proche(niche_mod)
    aire_face = [M.aire_triangle(positions[faces[i][0]],
                                 positions[faces[i][1]],
                                 positions[faces[i][2]])
                 for i in range(len(faces))]
    aire_totale = sum(aire_face)
    (x0, y0, z0), (x1, y1, z1) = M.boite(positions)
    candidats = []
    s = y0 + 0.02
    fin_bal = min(y0 + 9.0, y1 - 0.02)
    while s <= fin_bal:
        for ct in H.contours_du_plan(positions, faces, tab, 1, s):
            ok, cote = H.separe_graine_ciel(adj, ct["aretes"], tab,
                                            f_salle, temoins)
            if not ok or f_niche not in cote:
                continue
            a_int = sum(aire_face[i] for i in cote)
            if a_int >= aire_totale - a_int:
                continue
            candidats.append((a_int, s, ct, cote))
        s += pas_bal
    if not candidats:
        print("  AUCUNE barriere de bouche valide n'isole l'interieur.")
        print()
        print("=" * 76)
        print("GATE TOPOLOGIQUE : **ROUGE** (RC=1)")
        print("=" * 76)
        print("La cavite communique avec le dehors AILLEURS que par la bouche.")
        print("L'epaisseur n'est pas mesuree : mesurer l'epaisseur d'une coque")
        print("trouee n'a pas de sens (contrat §5).")
        return 1
    a_int, s_bouche, ct, cote = max(candidats, key=lambda t: t[0])
    # POINTS DU CONTOUR DE BOUCHE. Ils servent au diagnostic decisif de
    # l'argmin : au contour, la peau interieure REJOINT la peau exterieure,
    # donc la distance de l'une a l'autre y tend vers zero PAR
    # CONSTRUCTION. Un argmin colle au contour signale une ARETE, pas un
    # amincissement — et aucun raffinement ne le fera remonter.
    pts_contour = []
    for (ia, ib) in ct["aretes"]:
        pa, pb = positions[ia], positions[ib]
        va, vb = pa[1] - s_bouche, pb[1] - s_bouche
        if abs(va - vb) < 1e-12:
            pts_contour.append(pa)
            continue
        t = va / (va - vb)
        pts_contour.append(tuple(pa[k] + t * (pb[k] - pa[k])
                                 for k in range(3)))
    interieur = sorted(cote)
    dedans = set(interieur)
    exterieur = [i for i in range(len(faces)) if i not in dedans]
    aire_int = sum(aire_face[i] for i in interieur)
    print("  bouche derivee a ay = %.3f, perimetre %.3f m"
          % (s_bouche, ct["perimetre"]))
    print("  peau INTERIEURE : %d faces, %.2f m2" % (len(interieur), aire_int))
    print("  peau EXTERIEURE : %d faces" % len(exterieur))
    print()

    # ------------------------------------------------------------------
    # Le masque
    # ------------------------------------------------------------------
    chemin = B.Chemin(tables)
    dl = B.CAPSULE_DEMI_LARGEUR_M if capsule else \
        tables["GABARIT_DEMI_LARGEUR_M"]
    cle = B.CAPSULE_CLE_M if capsule else tables["GABARIT_CLE_M"]
    gab = B.Gabarit(dl, cle)
    _da, s_dehors, u_deh = chemin.projeter(seuil_mod)
    print("--- le masque (addendum §2) ---")
    print("  section : %s, demi-largeur %.3f m, cle %.3f m"
          % ("CAPSULE REELLE" if capsule else "GABARIT CONTRACTUEL", dl, cle))
    print("  s_dehors = %.4f m (u = %.4f), mesure par projection"
          % (s_dehors, u_deh))
    print()

    hach_ext = H.Hachage(positions, faces, exterieur, 0.5)
    cells = cellules_initiales(positions, faces, interieur)
    # --- option de DIAGNOSTIC, explicitement HORS CONTRAT ---
    # Le contrat §2.5 n'exclut QUE la bouche masquee ; rien d'autre. Cette
    # marge n'est donc PAS un masque et ne participe a aucun verdict de
    # gate. Elle sert a une seule chose : rendre le CONTROLE NEGATIF
    # possible. Tant que la levre du porche domine tout argmin a 0,5 mm,
    # aucun sabotage a 0,70 m ne peut deplacer le minimum vers lui, et le
    # controle negatif ne peut RIEN eprouver. La marge ecarte la levre le
    # temps d'eprouver l'instrument, et le journal le dit a chaque fois.
    marge_ct = float(opt(argv, "marge-contour", "0.0"))
    filtre = None
    if marge_ct > 0.0:
        def filtre(g, r):
            return min(math.dist(g, q) for q in pts_contour) - r > marge_ct
        avant = len(cells)
        cells = [c for c in cells if filtre(c[1], 0.0)]
        print("  *** MODE DIAGNOSTIC HORS CONTRAT : marge de %.3f m autour du"
              % marge_ct)
        print("      contour de bouche, appliquee AUSSI aux sous-cellules."
              "  %d cellules initiales sur %d ecartees."
              % (avant - len(cells), avant))
        print("      Le contrat §2.5 n'exclut QUE la bouche masquee : ce")
        print("      resultat N'EST PAS un verdict de gate. Il sert au")
        print("      controle negatif, qui ne peut rien eprouver tant que la")
        print("      levre domine tout argmin.")
        print()
    r_max = max(c[2] for c in cells)
    print("  peau interieure : %d cellules initiales" % len(cells))
    print("  rayon de couverture maximal %.4f m ; h vise %.4f m ; "
          "budget %d evaluations" % (r_max, h_vise, budget))
    print()

    # ------------------------------------------------------------------
    # Sensibilite a `s_final` — la lettre d'abord, puis les autres
    # ------------------------------------------------------------------
    emprises = list(SENSIBILITE_M)
    if s_final_force is not None:
        emprises = [float(s_final_force) - s_dehors]
    liste = opt(argv, "emprises", None)
    if liste:
        emprises = [float(v) for v in liste.split(",")]
    print("--- verdicts, par emprise de masque ---")
    print("  emprise 0,00 = la LETTRE de l'addendum §2.5 mesuree sur cette")
    print("  geometrie : la condition des 72 rayons y est vraie des")
    print("  `s_dehors`, donc le masque est VIDE et tout est COQUE a 0,80 m.")
    print("  C'est la lecture CONSERVATRICE. Les autres lignes disent si le")
    print("  verdict DEPEND de cette ambiguite. Elles ne la tranchent pas.")
    print()
    print("  %-9s %-11s %-9s %-9s %-9s %-11s %s"
          % ("emprise", "classe", "cellules", "lecture", "h", "borne",
             "verdict"))
    resultats = []
    for emp in emprises:
        s_fin = s_dehors + emp
        masque = Masque(chemin, gab, s_dehors, s_fin)
        journal = {}
        etat = evaluer(cells, hach_ext, masque, budget, h_vise, journal,
                       filtre)
        for cl in ("COLLERETTE", "COQUE"):
            e = etat[cl]
            if e["verdict"] == "VIDE":
                print("  %-9.2f %-11s %-9d %s" % (emp, cl, 0, "(aucune)"))
                continue
            print("  %-9.2f %-11s %-9d %-9.4f %-9.4f %-11.4f %s"
                  % (emp, cl, e["cell"], e["lecture"], e["h"], e["borne"],
                     e["verdict"]))
        resultats.append((emp, etat, journal))
        print("     evaluations %d | cellules a cheval non departagees %d%s"
              % (journal["evaluations"], journal["a_cheval"],
                 "   <- BUDGET EPUISE" if journal["budget_epuise"] else ""))
    print()

    # ------------------------------------------------------------------
    # Le gate : la LETTRE
    # ------------------------------------------------------------------
    emp0, etat0, journal0 = resultats[0]
    print("=" * 76)
    print("ARGMINS (addendum §3.2) — emprise de la lettre, %.2f m" % emp0)
    print("=" * 76)
    for cl in ("COLLERETTE", "COQUE"):
        e = etat0[cl]
        print()
        print("  classe %s   (seuil %.2f m)" % (cl, e["seuil"]))
        if e["argmin"] is None:
            print("    aucune cellule de cette classe.")
            continue
        (g, fi, dm, f_ext, r) = e["argmin"]
        gd = godot_de_modele(g)
        d_axe, s_p, u_p = chemin.projeter(g)
        st = chemin.station(u_p)
        print("    repere modele : (%.3f ; %.3f ; %.3f)" % g)
        print("    repere Godot  : (%.3f ; %.3f ; %.3f)" % gd)
        print("    projection    : s = %+.4f m, u = %+.4f, ay de la station "
              "interpolee = %+.3f" % (s_p, u_p, st[1]))
        print("                    distance a l'axe du chemin = %.4f m"
              % d_axe)
        print("    raison        : d_masque = %s, %s le seuil de %.2f m"
              % ("+inf (masque vide)" if dm == float("inf")
                 else "%.4f m" % dm,
                 "au-dela de" if dm > BANDE_M else "en deca de", BANDE_M))
        print("    lecture %.4f m | h %.4f m | lecture - h %.4f m | seuil "
              "%.2f m" % (e["lecture"], e["h"], e["borne"], e["seuil"]))
        print("    face porteuse : index %d (peau interieure), face "
              "exterieure la plus proche : %d" % (fi, f_ext))
        print("    rayon de couverture de la cellule argmin : %.5f m" % r)
        d_ct = min(math.dist(g, q) for q in pts_contour) if pts_contour \
            else float("inf")
        print("    DISTANCE AU CONTOUR DE BOUCHE : %.4f m" % d_ct)
        if d_ct <= 3.0 * max(r, 0.02):
            print("      -> l'argmin est COLLE AU CONTOUR. La peau interieure")
            print("         y rejoint la peau exterieure : la distance de")
            print("         l'une a l'autre tend vers ZERO par construction.")
            print("         C'est une ARETE, pas un amincissement, et aucun")
            print("         raffinement ne la fera remonter — le raffiner")
            print("         fait au contraire DESCENDRE la lecture vers 0.")
    print()

    verdicts = [etat0[c]["verdict"] for c in ("COLLERETTE", "COQUE")
                if etat0[c]["verdict"] != "VIDE"]
    ordre = {"FAIL": 0, "BLOQUE": 1, "PASS": 2}
    global_ = min(verdicts, key=lambda v: ordre[v]) if verdicts else "BLOQUE"

    stable = True
    for (emp, etat, _j) in resultats[1:]:
        v = [etat[c]["verdict"] for c in ("COLLERETTE", "COQUE")
             if etat[c]["verdict"] != "VIDE"]
        g2 = min(v, key=lambda x: ordre[x]) if v else "BLOQUE"
        if g2 != global_:
            stable = False
    print("=" * 76)
    if marge_ct > 0.0:
        print("RESULTAT DE DIAGNOSTIC (HORS CONTRAT) : **%s**" % global_)
        print("=" * 76)
        print("  marge de contour %.3f m appliquee : ce n'est PAS un verdict"
              % marge_ct)
        print("  de gate, et il ne doit jamais etre cite comme tel.")
    else:
        print("VERDICT GLOBAL : **%s**   (le PLUS FAIBLE des deux, jamais la "
              "moyenne)" % global_)
        print("=" * 76)
    print("  sensibilite a l'emprise de masque : %s"
          % ("STABLE — le verdict ne depend pas de l'ambiguite de §2.5"
             if stable else
             "INSTABLE — le verdict DEPEND de l'emprise ; voir plus haut"))
    if journal0["budget_epuise"]:
        print("  BUDGET EPUISE : %d evaluations, %d cellules non traitees."
              % (journal0["evaluations"], journal0["reste_en_file"]))
        print("  Le `h` publie est celui REELLEMENT ATTEINT, pas celui vise.")
    if not stable:
        print()
        print("  L'ambiguite de §2.5 devient BLOQUANTE : elle change le")
        print("  verdict. La question remonte au lead, elle n'est pas")
        print("  tranchee ici.")
    if sortie:
        def serialiser(e):
            out = {k: v for k, v in e.items() if k != "argmin"}
            if e.get("argmin") is not None:
                (g, fi, dm, f_ext, r) = e["argmin"]
                d_axe, s_p, u_p = chemin.projeter(g)
                out["argmin"] = {
                    "modele": list(g), "godot": list(godot_de_modele(g)),
                    "face": fi, "face_exterieure": f_ext,
                    "d_masque": None if dm == float("inf") else dm,
                    "rayon_cellule": r, "s": s_p, "u": u_p,
                    "ay_station": chemin.station(u_p)[1],
                    "distance_axe": d_axe,
                }
            for k, v in list(out.items()):
                if isinstance(v, float) and math.isinf(v):
                    out[k] = None
            return out

        with open(sortie, "w", encoding="utf-8") as f:
            json.dump({
                "glb": glb, "sha256": sha, "tables": tables["_origine"],
                "lieu": org_lieu, "anciens_reperes": anciens,
                "capsule": capsule, "h_vise": h_vise, "budget": budget,
                "s_dehors": s_dehors, "verdict_global": global_,
                "stable": stable,
                "resultats": [
                    {"emprise": emp, "journal": j,
                     "classes": {cl: serialiser(e) for cl, e in etat.items()}}
                    for (emp, etat, j) in resultats],
            }, f, indent=1, ensure_ascii=False)
        print("  ecrit : %s" % sortie)
    return {"PASS": 0, "FAIL": 1, "BLOQUE": 3}[global_]


if __name__ == "__main__":
    sys.exit(main(sys.argv))
