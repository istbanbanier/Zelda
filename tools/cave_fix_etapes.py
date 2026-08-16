#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ATTRIBUTION D'ÉTAPE de la percée de la grotte — instrumentation, pas géométrie.

LA QUESTION, ET ELLE EST EN DEUX MORCEAUX
=========================================

La percée de 85,8 cm² du candidat `cc3596c5` vit en `x ∈ [0,468 ; 0,623]`,
`ay ∈ [5,850 ; 6,045]`. Deux questions distinctes s'y posent, et les
confondre coûte une itération :

  * QUELLE PIÈCE porte le pincement — c'est de la géométrie source ;
  * QUELLE ÉTAPE l'ouvre — remaillage voxel, stratification, décimation ou
    soustraction booléenne.

Ce script répond à la seconde. Il enveloppe les cinq étapes de `main()`,
exporte le maillage après chacune, et surtout MESURE L'ÉPAISSEUR AU MÊME
POINT à chaque fois. Le facteur de marge « combien perd-on entre la source
et le livrable » cesse alors d'être une hypothèse de rédaction : c'est une
colonne de nombres.

CE QU'IL NE TOUCHE PAS
======================

Pas une ligne du générateur. Il le CHARGE comme module — donc sans
déclencher `main()`, qui ne part que sous `__name__ == "__main__"` —,
remplace cinq attributs par des enveloppes, puis appelle `main()`. La
séquence exécutée est exactement la sienne : aucune cote, aucun seuil,
aucun paramètre de décimation modifié.

`main()` enregistre un `.blend` à côté de `__file__`. On lui donne donc le
`__file__` réel du générateur de CE worktree : le `.blend` produit est
celui de ce worktree, et rien n'est écrit ailleurs.

LA LECTURE DE COLONNE S'ÉCRIT UNE FOIS
======================================

`tools/CLAUDE.md` : « cette lecture s'écrit UNE fois, dans une fonction
nommée, et se réutilise — pas une fois par branche, où on la redérive et où
on se trompe ». Trois verdicts faux ont été payés pour l'apprendre. Ici
c'est `colonne()`, et elle est appelée par tout le reste.

Elle lit par ENLACEMENT et non par parité, pour la raison mesurée en
R2a-3.5.3 : ce maillage se traverse lui-même — `controle_repli()` le mesure
et le tolère — et une séquence de normales qui n'alterne pas rend la parité
indéfinie. On accumule donc les traversées signées depuis le ciel.

DEUX GARDE-FOUS, TOUS DEUX PAYÉS PAR QUELQU'UN
==============================================

1. Avant remaillage, `joindre()` rend une CONCATÉNATION, pas un solide :
   les lentilles d'enveloppe s'interpénètrent et leurs peaux se croisent.
   L'enlacement y reste défini (il compte des traversées signées), mais
   l'épaisseur qu'il rend est celle de l'union, ce qui est bien la question
   posée. On imprime la liste brute des impacts pour que le chiffre soit
   auditable et non cru sur parole.
2. Le `.glb` livré contient DEUX maillages, dont `COL_WaterfallCave` qui
   REBOUCHE la galerie. Ici on ne mesure jamais un `.glb` : on mesure
   l'objet Blender qu'on vient de produire, nommément. La confusion est
   impossible par construction.

Usage (Blender, sous verrou d'outil lourd) :
    flock /home/user/Zelda/.git/heavy_tools.lock -c \\
      'cd /home/user/zelda-r2a354/a_percee && blender --background \\
       --python-exit-code 1 --python tools/cave_fix_etapes.py -- --diagnostic'
"""

import os
import sys
import types

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(RACINE, "source_assets", "blender", "environment",
                      "make_waterfall_cave.py")
SORTIE = os.path.join(RACINE, "evidence", "world_v2", "v2_3_r2a", "grotte",
                      "r2a354_percee", "etapes")

## Le point de la percée, et deux témoins de part et d'autre du col. Les
## trois sont dans le repère MODÈLE = repère Blender du générateur.
## `defaut` est le centre des 343 colonnes ouvertes ; `amont` et `aval`
## disent si la correction déplace le pincement au lieu de le fermer.
POINTS = (("defaut", 0.55, 5.95),
          ("amont", 0.55, 5.20),
          ("aval", 0.55, 6.40),
          ("galerie", 0.55, 2.60))

ETAPES = (("joindre", "0_joint"),
          ("remailler_voxel", "1_remaille"),
          ("stratifier", "2_stratifie"),
          ("decimer", "3_decime"),
          ("soustraire", "4_soustrait"))

_JOURNAL = []


def colonne(arbre, ax, ay, z_ciel, z_fond):
    """Tranches roche/vide d'une verticale, LUES PAR ENLACEMENT.

    Rend `(tranches, impacts)` où `tranches` est une liste
    `(nature, haut, bas)` du haut vers le bas, et `impacts` la liste brute
    `(z, signe)` — publiée pour que le chiffre soit vérifiable.

    +1 quand la face regarde vers le haut (le rayon descendant ENTRE dans
    la matière), -1 sinon. Enlacement >= 1 = roche. Les tranches de même
    nature qui se touchent sont fusionnées, sans quoi un pli interne
    découperait une roche continue en fausses lames.
    """
    depart = Vector((ax, ay, z_ciel))
    direction = Vector((0.0, 0.0, -1.0))
    portee = z_ciel - z_fond
    impacts, parcouru = [], 0.0
    for _ in range(256):
        touche = arbre.ray_cast(depart, direction, portee - parcouru)
        if touche is None or touche[0] is None:
            break
        z, nz = touche[0].z, touche[1].z
        if abs(nz) > 1e-6:
            signe = +1 if nz > 0.0 else -1
            if not impacts or abs(impacts[-1][0] - z) > 1e-4 \
                    or impacts[-1][1] != signe:
                impacts.append((z, signe))
        avance = (touche[0] - depart).length + 1e-4
        parcouru += avance
        depart = touche[0] + direction * 1e-4
        if parcouru >= portee:
            break
    brut, enlacement = [], 0
    for k in range(len(impacts) - 1):
        enlacement += impacts[k][1]
        brut.append(("roche" if enlacement >= 1 else "vide",
                     impacts[k][0], impacts[k + 1][0]))
    tranches = []
    for nature, haut, bas in brut:
        if tranches and tranches[-1][0] == nature:
            tranches[-1] = (nature, tranches[-1][1], bas)
        else:
            tranches.append((nature, haut, bas))
    return tranches, impacts


def toit_au_dessus_du_vide(tranches, vide_min=0.30):
    """(banc, cumul, hauteur_du_vide) au-dessus du vide qualifiant le plus HAUT.

    `banc` est la roche du PREMIER banc surmontant ce vide — c'est lui qui
    dit « plaque ». `cumul` est toute la roche au-dessus — c'est lui qui
    dit « combien sépare du dehors ». On publie les deux, parce qu'un seul
    nombre choisit la réponse avant de mesurer.

    Le seuil de vide est ici plus bas que le `VIDE_QUALIFIANT_M = 1,00` du
    générateur, ET C'EST VOULU : avant soustraction le creux sous
    l'enveloppe peut être plus court qu'un mètre, et l'écarter ferait
    disparaître le point mesuré de la colonne d'attribution. Le seuil est
    imprimé à chaque ligne.
    """
    for k, (nature, haut, bas) in enumerate(tranches):
        if nature != "vide" or (haut - bas) < vide_min:
            continue
        cumul, banc = 0.0, None
        for nature2, haut2, bas2 in tranches[:k]:
            if nature2 != "roche":
                continue
            cumul += haut2 - bas2
            banc = haut2 - bas2
        return (banc if banc is not None else 0.0, cumul, haut - bas)
    return None


def mesurer(obj, etiquette):
    """Épaisseur aux points témoins, sur l'objet Blender COURANT."""
    if obj is None or not hasattr(obj, "data"):
        print("[etapes] %s : pas d'objet a mesurer" % etiquette)
        return
    arbre = BVHTree.FromPolygons(
        [tuple(v.co) for v in obj.data.vertices],
        [tuple(p.vertices) for p in obj.data.polygons], all_triangles=False)
    zs = [v.co.z for v in obj.data.vertices]
    z_ciel, z_fond = max(zs) + 1.0, min(zs) - 1.0
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    for nom, ax, ay in POINTS:
        tranches, impacts = colonne(arbre, ax, ay, z_ciel, z_fond)
        trouve = toit_au_dessus_du_vide(tranches)
        haut_massif = tranches[0][1] if tranches else float("nan")
        if trouve is None:
            ligne = ("%-11s %-9s AUCUN vide >= 0,30 m — colonne pleine ou "
                     "hors solide (%d impact(s))"
                     % (etiquette, nom, len(impacts)))
            _JOURNAL.append((etiquette, nom, None, None, None, tris))
        else:
            banc, cumul, vide = trouve
            ligne = ("%-11s %-9s banc %6.3f m  cumul %6.3f m  vide %5.2f m  "
                     "sommet massif %6.3f m  (%d impacts)"
                     % (etiquette, nom, banc, cumul, vide, haut_massif,
                        len(impacts)))
            _JOURNAL.append((etiquette, nom, banc, cumul, vide, tris))
        print("[etapes] %s" % ligne)
        print("[etapes]     impacts (z/signe) : %s"
              % (" ".join("%.3f/%+d" % t for t in impacts) or "aucun"))


def exporter(obj, etiquette):
    if obj is None or not hasattr(obj, "select_set"):
        return
    if not os.path.isdir(SORTIE):
        os.makedirs(SORTIE)
    chemin = os.path.join(SORTIE, "etape_%s.glb" % etiquette)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    voulu = dict(filepath=chemin, export_format="GLB", use_selection=True)
    connues = set(bpy.ops.export_scene.gltf.get_rna_type().properties.keys())
    bpy.ops.export_scene.gltf(**dict(
        (k, v) for k, v in voulu.items() if k == "filepath" or k in connues))
    octets = os.path.getsize(chemin) if os.path.isfile(chemin) else -1
    print("[etapes] %s -> %s (%d octets)" % (etiquette, chemin, octets))


def main():
    if not os.path.isfile(SOURCE):
        print("[etapes] BLOQUE: generateur introuvable : %s" % SOURCE)
        return 3
    source = open(SOURCE, "r", encoding="utf-8").read()
    module = types.ModuleType("gen_cave_sujet")
    module.__file__ = SOURCE
    sys.modules["gen_cave_sujet"] = module
    exec(compile(source, SOURCE, "exec"), module.__dict__)

    manquantes = [n for n, _ in ETAPES if not hasattr(module, n)]
    if manquantes:
        print("[etapes] BLOQUE: fonctions absentes : %s"
              % ", ".join(manquantes))
        return 3

    for nom, etiquette in ETAPES:
        original = getattr(module, nom)

        def enveloppe(*args, _o=original, _e=etiquette, **kwargs):
            resultat = _o(*args, **kwargs)
            cible = resultat if hasattr(resultat, "data") else (
                args[0] if args and hasattr(args[0], "data") else None)
            mesurer(cible, _e)
            exporter(cible, _e)
            return resultat

        setattr(module, nom, enveloppe)
        print("[etapes] enveloppe posee sur %s() -> etape_%s.glb"
              % (nom, etiquette))

    print("[etapes] lancement de main() du generateur")
    code = module.main()
    print("[etapes] main() rend %s" % code)

    print("[etapes] " + "=" * 66)
    print("[etapes] TABLEAU D'ATTRIBUTION — banc de roche au-dessus du vide")
    print("[etapes] %-11s %-9s %8s %8s %8s %9s"
          % ("etape", "point", "banc", "cumul", "vide", "tris"))
    for etape, point, banc, cumul, vide, tris in _JOURNAL:
        if banc is None:
            print("[etapes] %-11s %-9s %8s %8s %8s %9d"
                  % (etape, point, "-", "-", "-", tris))
        else:
            print("[etapes] %-11s %-9s %8.3f %8.3f %8.2f %9d"
                  % (etape, point, banc, cumul, vide, tris))
    print("[etapes] " + "=" * 66)
    produits = sorted(os.listdir(SORTIE)) if os.path.isdir(SORTIE) else []
    print("[etapes] fichiers d'etape : %s" % (", ".join(produits) or "AUCUN"))
    # Le code de la chaine n'est PAS le verdict de ce script : on mesure des
    # etapes, on ne livre rien. Mais l'absence de mesure est un blocage —
    # un script d'instrumentation qui n'instrumente rien ne rend pas 0.
    if len(_JOURNAL) < len(ETAPES):
        print("[etapes] BLOQUE: %d mesure(s) pour %d etape(s) attendues"
              % (len(_JOURNAL), len(ETAPES)))
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main())
