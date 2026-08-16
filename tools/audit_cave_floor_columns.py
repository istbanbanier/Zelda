#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Le plancher existe-t-il ? Réponse tirée du MAILLAGE SEUL, sans stations.

POURQUOI CET ORACLE EXISTE, ET POURQUOI IL N'UTILISE AUCUNE STATION
===================================================================

Quatre contrôles disent aujourd'hui que le plancher des stations 6 à 8 est
sain. Trois d'entre eux — `controle_plancher()` du générateur, le contrôle 1
de la sonde sur `points_interieurs`, et la carte de l'agent plancher —
placent leurs points de la MÊME façon : à partir d'une station `u`, le long
de la normale locale, multipliés par `facteur_lateral`. Ils partagent donc
le calcul central dont la variante fautive vient précisément d'être
démasquée dans `carte_du_plancher()`.

La directive l'exige mot pour mot : « deux instruments ne partageant pas le
même calcul central ; une fonction de placement commune ne doit pas pouvoir
aveugler les deux. » Trois instruments d'accord entre eux ne valent rien
s'ils peuvent se tromper ensemble.

Cet oracle ne connaît ni `CAVITE_ASYM`, ni `facteur_lateral`, ni
`normale_de_cavite`, ni `u`. Il ne sait pas où est la galerie. Il balaie des
COLONNES VERTICALES sur toute l'emprise du modèle, et pour chaque colonne il
lit l'alternance roche/vide par parité d'impacts. Un vide assez haut pour
qu'on s'y tienne debout, coiffé de roche, DOIT être fermé par de la roche en
dessous. Sinon le joueur tombe hors du modèle.

C'est la seule question posée, et elle se répond sans savoir dessiner une
grotte.

CE QU'IL NE PROUVE PAS
======================

Il ne mesure pas la PENTE du plancher, ni sa continuité le long d'un
parcours, ni le gabarit. Un plancher présent mais en marches d'escalier
passerait ici. Il répond à « y a-t-il de la roche sous le vide », pas à
« ce sol est-il praticable ». Publier l'un pour l'autre serait refaire la
faute que cette passe traque : un seul nombre, qui répond à une autre
question que celle posée.
"""

import argparse
import json
import os
import sys

## PIÈGE : un `sys.path` relatif se résout contre le RÉPERTOIRE COURANT
## de la session, pas contre le script. Depuis un autre arbre de
## travail il importerait la sonde du voisin. Toujours ancrer au
## fichier.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import probe_cave_openings as sonde                      # noqa: E402

CIEL_Z = 60.0
SOUS_SOL_Z = -40.0

## Un vide plus bas que cela n'est pas un endroit où l'on se tient : c'est
## une fissure de décimation, une poche entre deux blocs, un artefact de
## remaillage. Le gabarit joueur en clé vaut 2,05 m ; on descend volontai-
## rement plus bas pour ne pas s'aveugler soi-même sur les zones basses.
HAUTEUR_VIDE_MIN_M = 1.20

## En deçà, ce n'est pas un plancher, c'est une écaille.
ECAILLE_M = sonde.ECAILLE_M

## Épaisseur de roche sous le vide en deçà de laquelle on signale, sans
## prononcer d'échec : ce n'est PAS un seuil contractuel, c'est un repère.
SOUS_PLANCHER_MINCE_M = 0.30


def colonnes(bmin, bmax, pas):
    x = bmin[0]
    while x <= bmax[0] + 1e-9:
        y = bmin[1]
        while y <= bmax[1] + 1e-9:
            yield (x, y)
            y += pas
        x += pas


def vides_de_la_colonne(grille, x, y):
    """Alternance roche/vide sous le ciel, par parité d'impacts.

    On ne se fie pas à l'orientation des faces : une normale retournée est
    un défaut fréquent, et elle ferait mentir la lecture. Depuis le ciel, le
    1er impact entre dans la roche, le 2e en sort, le 3e y rentre à nouveau.
    Entre le 2e et le 3e il y a donc un VIDE INTÉRIEUR — coiffé de roche par
    construction, puisqu'on vient d'en sortir.
    """
    frappes = sonde.impacts(grille, (x, y, CIEL_Z), (0.0, 0.0, -1.0),
                            portee=CIEL_Z - SOUS_SOL_Z)
    zs = [CIEL_Z - t for t, _ in frappes]
    trouves = []
    ## i impair = on QUITTE la roche ; le vide va de zs[i] à zs[i+1].
    for i in range(1, len(zs) - 1, 2):
        haut, bas = zs[i], zs[i + 1]
        hauteur = haut - bas
        if hauteur < HAUTEUR_VIDE_MIN_M:
            continue
        ## Épaisseur du bloc de roche IMMÉDIATEMENT sous ce vide.
        ##
        ## LA MÊME INVERSION, DEUX FOIS DANS CE FICHIER, EN VINGT MINUTES.
        ## S'il n'y a plus d'impact après l'entrée dans le plancher, le rayon
        ## a fini sa course DANS LA ROCHE : le plancher est plein jusqu'en
        ## bas, c'est le cas le plus sûr. La première écriture rendait
        ## `sous = None` puis `ferme = False`, et accusait donc de « plancher
        ## absent » quatre colonnes du tronc R2a-3.4 dont le sol est
        ## infiniment épais.
        ##
        ## La leçon n'est pas « la parité est subtile ». Elle est : quand un
        ## rayon cesse de rencontrer des faces, cela veut dire PLEIN, et
        ## cette lecture s'écrit UNE fois — pas une fois par branche, où on
        ## la redérive et où on se trompe.
        if i + 2 < len(zs):
            sous = zs[i + 1] - zs[i + 2]
            ferme = sous >= ECAILLE_M
        else:
            sous = float("inf")
            ferme = True
        trouves.append(dict(plafond=haut, sol=bas, hauteur=hauteur,
                            sous_plancher=sous, ferme=ferme))
    ## PIÈGE MESURÉ, ET JE L'AI POSÉ MOI-MÊME AVANT DE LE VOIR.
    ##
    ## La première écriture signalait « vide ouvert vers le bas » sur une
    ## parité IMPAIRE d'impacts. C'est l'exact contraire de la vérité. Un
    ## rayon descendant qui compte un nombre impair d'impacts a fait son
    ## dernier geste en ENTRANT dans la roche : tout ce qui est en dessous
    ## est plein. C'est la signature d'un solide OUVERT PAR LE BAS — la
    ## forme normale d'un rocher planté dans le terrain, et le cas le plus
    ## sûr qui soit.
    ##
    ## L'oracle a donc rendu « FAIL — 3 vides sans roche dessous » sur trois
    ## colonnes dont le rayon finissait à 3 mètres de profondeur DANS la
    ## roche. Même faute que celles que cette passe traque depuis le début :
    ## un contrôle qui répond à une autre question que celle posée.
    ##
    ## Le danger réel est l'inverse : une parité PAIRE dont la dernière
    ## sortie est haute, c'est-à-dire un vide qui s'échappe vers le bas sans
    ## jamais retrouver de matière.
    if len(zs) >= 2 and len(zs) % 2 == 0:
        derniere_sortie = zs[-1]
        trouves.append(dict(plafond=derniere_sortie, sol=SOUS_SOL_Z,
                            hauteur=derniere_sortie - SOUS_SOL_Z,
                            sous_plancher=None, ferme=False,
                            sous_le_massif=True))
    return trouves


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--glb", required=True)
    ap.add_argument("--noeud", default="SM_WaterfallCave")
    ap.add_argument("--pas", type=float, default=0.25)
    ap.add_argument("--json")
    ap.add_argument("--fenetre", metavar="X0,X1,Y0,Y1",
                    help="restreint le VERDICT a cette fenetre horizontale ; "
                         "le decompte global reste imprime")
    ## CONTRÔLE NÉGATIF. Un oracle qui n'a jamais rougi n'est pas un oracle,
    ## c'est une formalité. On perce le fond du modèle en retirant toute la
    ## matière sous une altitude, dans une fenêtre horizontale donnée, et on
    ## exige que l'oracle le voie. RED puis GREEN, sur le même maillage.
    ap.add_argument("--saboter", metavar="Z,X0,X1,Y0,Y1",
                    help="retire les triangles sous Z dans la fenetre donnee")
    args = ap.parse_args()

    tris, par_matiere = sonde.triangles_du_glb(args.glb, args.noeud)
    if args.saboter:
        z0, x0, x1, y0, y1 = [float(v) for v in args.saboter.split(",")]
        garde = []
        for s in tris:
            cx = sum(p[0] for p in s) / 3.0
            cy = sum(p[1] for p in s) / 3.0
            cz = sum(p[2] for p in s) / 3.0
            if cz < z0 and x0 <= cx <= x1 and y0 <= cy <= y1:
                continue
            garde.append(s)
        print("SABOTAGE : %d triangles retires sur %d (sous z=%.2f, "
              "x %.2f..%.2f, y %.2f..%.2f)"
              % (len(tris) - len(garde), len(tris), z0, x0, x1, y0, y1))
        tris = garde
    grille = sonde.Grille(tris)

    xs = [s[i][0] for s in tris for i in range(3)]
    ys = [s[i][1] for s in tris for i in range(3)]
    zs = [s[i][2] for s in tris for i in range(3)]
    bmin = (min(xs), min(ys), min(zs))
    bmax = (max(xs), max(ys), max(zs))
    print("glb        : %s" % args.glb)
    print("triangles  : %d  ·  matieres : %d" % (len(tris), len(par_matiere)))
    print("emprise    : x %.2f..%.2f  y %.2f..%.2f  z %.2f..%.2f"
          % (bmin[0], bmax[0], bmin[1], bmax[1], bmin[2], bmax[2]))
    print("pas        : %.2f m  ·  vide retenu a partir de %.2f m de haut"
          % (args.pas, HAUTEUR_VIDE_MIN_M))

    total_colonnes = 0
    bruts = []
    for x, y in colonnes(bmin, bmax, args.pas):
        total_colonnes += 1
        for v in vides_de_la_colonne(grille, x, y):
            v["x"], v["y"] = round(x, 3), round(y, 3)
            bruts.append(v)

    ## L'ALTITUDE DE RÉFÉRENCE VIENT DU MAILLAGE, PAS D'UNE TABLE.
    ## Le dessous du massif est lui aussi « du vide sans roche dessous », et
    ## c'est parfaitement normal : un rocher planté dans le terrain est
    ## ouvert par le bas. Ce qui serait un défaut, c'est du vide À HAUTEUR DE
    ## PLANCHER DE GROTTE sans rien dessous. On prend donc pour repère la
    ## médiane des sols réellement trouvés, et on ne retient comme faute que
    ## ce qui s'ouvre au-dessus de ce niveau.
    fermes = [v for v in bruts if v["ferme"]]
    if fermes:
        sols_tries = sorted(v["sol"] for v in fermes)
        sol_median = sols_tries[len(sols_tries) // 2]
    else:
        sol_median = bmin[2]
    plancher_ref = sol_median - 0.50

    ## SECOND FILTRE, ET IL EST NÉCESSAIRE.
    ## Le critère d'altitude seul accuse le bord aminci du massif : à sa
    ## lisière, le dessous du rocher remonte jusqu'au niveau du plancher de
    ## la grotte, et une colonne y est légitimement ouverte par le bas — il
    ## n'y a pas de grotte à cet endroit. Vingt-trois colonnes ont été
    ## signalées ainsi, toutes entre x -8,5 et -6,8, à huit mètres de la
    ## galerie.
    ##
    ## L'EMPRISE DE LA CAVITÉ SE LIT DANS LE MAILLAGE : ce sont les colonnes
    ## qui portent un vide BORNÉ, coiffé et planchéié. Une ouverture n'est un
    ## trou dans le plancher que si elle touche cette emprise.
    footprint = set((v["x"], v["y"]) for v in fermes)
    RAYON_VOISINAGE_M = 0.75

    def touche_la_cavite(v):
        for cx, cy in footprint:
            if (abs(cx - v["x"]) <= RAYON_VOISINAGE_M
                    and abs(cy - v["y"]) <= RAYON_VOISINAGE_M):
                return True
        return False

    vides = fermes
    candidats = [v for v in bruts
                 if not v["ferme"] and v["plafond"] > plancher_ref]
    ouverts = [v for v in candidats if touche_la_cavite(v)]
    hors_cavite = len(candidats) - len(ouverts)

    ## LA BOUCHE EST OUVERTE, ET C'EST SON MÉTIER.
    ## À l'aplomb du porche il n'y a légitimement pas de plancher DANS le
    ## modèle : le terrain le fournit. Une fenêtre explicite permet donc de
    ## poser la question à un endroit précis — les stations terminales, par
    ## exemple — sans jamais effacer le décompte global, qui reste imprimé.
    if args.fenetre:
        fx0, fx1, fy0, fy1 = [float(v) for v in args.fenetre.split(",")]
        retenus = [v for v in ouverts
                   if fx0 <= v["x"] <= fx1 and fy0 <= v["y"] <= fy1]
        print("fenetre du verdict : x %.2f..%.2f  y %.2f..%.2f"
              % (fx0, fx1, fy0, fy1))
        print("ouvertures hors fenetre, non jugees : %d"
              % (len(ouverts) - len(retenus)))
        ouverts = retenus
        ## LE MINIMUM D'ÉPAISSEUR DOIT SUIVRE LA FENÊTRE, SINON IL RÉPOND À
        ## UNE AUTRE QUESTION. Mesuré : après avoir retiré tout le sous-sol
        ## des stations terminales, le minimum GLOBAL restait imprimé à
        ## 2,521 m — parce qu'il vit ailleurs, à la bouche. Un chiffre juste
        ## au mauvais endroit est un chiffre faux.
        dans = [v for v in vides
                if fx0 <= v["x"] <= fx1 and fy0 <= v["y"] <= fy1]
        if dans:
            m = min(dans, key=lambda v: v["sous_plancher"])
            print("roche sous le vide DANS LA FENETRE, minimum : %.3f m "
                  "en (%.2f ; %.2f)  sur %d vide(s)"
                  % (m["sous_plancher"], m["x"], m["y"], len(dans)))
        else:
            print("roche sous le vide DANS LA FENETRE : aucun vide borne")
    sous_massif = len(bruts) - len(fermes) - len(candidats)
    avec_vide = len(footprint)

    print("")
    print("colonnes balayees          : %d" % total_colonnes)
    print("colonnes portant un vide   : %d" % avec_vide)
    print("vides interieurs >= %.2f m : %d" % (HAUTEUR_VIDE_MIN_M, len(vides)))
    print("sol median mesure          : %.2f m  (repere a %.2f m)"
          % (sol_median, plancher_ref))
    print("colonnes ouvertes SOUS le massif, normal : %d" % sous_massif)
    print("VIDES OUVERTS A HAUTEUR DE PLANCHER : %d" % len(ouverts))

    if vides:
        if fermes:
            mince = min(fermes, key=lambda v: v["sous_plancher"])
            print("roche sous le vide, minimum : %.3f m en (%.2f ; %.2f)"
                  % (mince["sous_plancher"], mince["x"], mince["y"]))
            rares = [v for v in fermes
                     if v["sous_plancher"] < SOUS_PLANCHER_MINCE_M]
            print("vides dont la roche sous le sol est < %.2f m : %d sur %d"
                  % (SOUS_PLANCHER_MINCE_M, len(rares), len(fermes)))
        sols = sorted(v["sol"] for v in vides)
        print("altitude des sols : min %.2f  median %.2f  max %.2f"
              % (sols[0], sols[len(sols) // 2], sols[-1]))

    for v in ouverts[:12]:
        print("  OUVERT (%.2f ; %.2f)  plafond %.2f  sol %.2f  haut %.2f%s"
              % (v["x"], v["y"], v["plafond"], v["sol"], v["hauteur"],
                 "  [parite impaire]" if v.get("parite_impaire") else ""))

    if args.json:
        with open(args.json, "w", encoding="utf-8") as poignee:
            json.dump(dict(glb=args.glb, pas=args.pas,
                           hauteur_vide_min=HAUTEUR_VIDE_MIN_M,
                           colonnes=total_colonnes, avec_vide=avec_vide,
                           vides=len(vides), ouverts=len(ouverts),
                           detail_ouverts=ouverts[:200]),
                      poignee, indent=1, ensure_ascii=False)

    print("")
    if ouverts:
        print("VERDICT : FAIL — %d vide(s) interieur(s) sans roche dessous"
              % len(ouverts))
        return 1
    print("VERDICT : PASS — tout vide interieur habitable repose sur de la "
          "roche")
    return 0


if __name__ == "__main__":
    sys.exit(main())
