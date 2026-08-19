#!/usr/bin/env python3
"""CONTRÔLE D'APLATS DE LA FERME — porte de R2B.2, seuils du lead INCHANGÉS.

POURQUOI CE FICHIER EXISTE. `tools/mesure_aplats.py` MESURE ; il ne juge pas.
Le jugement était jusqu'ici tenu à la main, donc absent des journaux. Ici il
est exécutable, et il porte les trois critères arbitrés le 2026-08-19 :

  1. `max_pct <= 8.0` — PORTAIL DU LEAD, importé de `mesure_aplats.py`, jamais
     recopié ni redéfini. Inchangé depuis R2B.1 ; c'est le seul seuil du lead
     qui reste liant sur cet instrument.

  2. `max_pct <= 3.0` — CONTRÔLE INTERNE de l'agent A, plus strict que le
     précédent, jamais un assouplissement. Il vise la tache unique qui fait
     « carton » plutôt que la somme diffuse : sur `ferme_seuil`, la composante
     la plus grosse valait 7,32 % à elle seule et c'était le tableau droit
     `SM_Farm_Jamb_Breach`.

  3. `total_pct` et l'écart à la baseline R2B — PUBLIÉS SANS VERDICT.

  4. `gris %` et `gris max %` — PUBLIÉS SANS VERDICT, ajoutés le 2026-08-19
     à la demande du lead. UN PORTAIL QUI NE VOIT QU'UNE TEINTE DOIT AU MOINS
     DIRE LAQUELLE IL IGNORE. `est_beige` exige `r > v > b` STRICT et
     `r - b > 18` : une surface NEUTRE ne peut pas satisfaire ce prédicat, et
     lui est donc rigoureusement invisible. Mesuré par le lead sur le
     `ferme_seuil` de R2B.1 : 10,12 % de plus grande composante GRISE, quand
     l'instrument liant en rapportait 2,92 en beige. Le défaut est ANTÉRIEUR
     au geste R2B.2 — ce n'est pas une régression, c'est un angle mort.
     Le liant n'est ni relevé, ni abaissé, ni retiré : il est COMPLÉTÉ.
     Attribution de la géométrie fautive : l'audit indépendant, pas ici.

POURQUOI LE CRITÈRE SUR `total_pct` A ÉTÉ RETIRÉ, ET PAR QUI.
Il était liant dans la première version de ce fichier (`total <= 12 %`, plus
un retour sous la baseline R2B par vue). Le LEAD l'a RETIRÉ le 2026-08-19,
décisions 2 et 3 de `evidence/world_v2/v2_3_r2b2/ARBITRAGE_PLANS_R2B2.md`, sur
une mesure de l'audit indépendant : le PLANCHER de `ferme_seuil` — la part
d'aplat produite par la seule maçonnerie du kit, AVEC ZÉRO PIÈCE AJOUTÉE — vaut
**21,85 %** à l'ancienne orientation et **26,37 %** à l'orientation livrée. Le
seuil de 12 % était donc inatteignable quoi qu'on modélise : il ne mesurait pas
le travail, il mesurait le cadrage. Un critère qu'aucune correction ne peut
satisfaire n'est pas une exigence, c'est un mur.

Il n'a pas été RELEVÉ — il a été RETIRÉ, et la colonne reste affichée comme
TÉMOIN. Ne pas la retransformer en verdict sans refaire la mesure de plancher.
La seconde grandeur liante, la DENSITÉ d'aplat (part attribuée ÷ couverture
d'écran), est mesurée par l'AUDIT INDÉPENDANT sur son propre instrument : cet
outil-ci mesure et publie, l'audit conclut. Deux instruments qui rendent le
même verdict, c'est une confirmation ; deux qui se contredisent, c'est une
session perdue.

PIÈGE MESURÉ (2026-08-19), qui explique le plancher : à FOV 66 et ~2 m du mur,
chaque pierre peinte de `T_UnevenBrick` dépasse `MIN_COMPOSANTE = 1500 px`.

Usage :
  python3 tools/controle_aplats_ferme.py <dossier_de_captures>
Sortie : 0 tout vert · 1 un critère échoue.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mesure_aplats import (  # noqa: E402  (import après ajustement du path)
    PORTAIL_MAX_PCT, PORTAIL_TOTAL_PCT, mesure)

# Baseline R2B, avant la première corrective. TÉMOIN désormais, plus un critère.
# Littéraux figés : une référence relue à chaque passage suivrait la dérive.
BASELINE_R2B = {
    "ferme_approche": 3.92, "ferme_composition": 3.03, "ferme_arriere": 6.89,
    "ferme_facade": 4.83, "ferme_laterale": 11.91, "ferme_seuil": 23.74,
}
MAX_COMPOSANTE_PCT = 3.0

# Seuil de neutralité repris À L'IDENTIQUE de l'outil du lead
# (`evidence/world_v2/v2_3_r2b2/preuves_lead/aplats_toutes_teintes.py`,
# commit 8508f87) pour que les deux mesures soient comparables : deux
# instruments qui rendent des nombres différents sur la même image sont pires
# qu'un seul. L'herbe à l'ombre reste verte (écart max-min de l'ordre de 30),
# le ciel reste bleu ; seul le bâti neutre tombe ici.
NEUTRE_ECART_MAX = 16


def est_neutre(couleur):
    return max(couleur) - min(couleur) <= NEUTRE_ECART_MAX and max(couleur) > 24


def mesure_famille(chemin, predicat):
    """Même prédicat de PLATITUDE que `mesure_aplats`, autre filtre de teinte.

    La connexité est restreinte aux pixels de la famille, exactement comme
    `mesure_aplats` la restreint au beige : c'est ce qui rend les deux nombres
    comparables. L'outil du lead, lui, connecte d'abord puis étiquette — ses
    composantes peuvent donc fusionner deux familles voisines.
    """
    from collections import deque

    from PIL import Image

    from mesure_aplats import MIN_COMPOSANTE, RAYON, SEUIL

    image = Image.open(chemin).convert("RGB")
    largeur, hauteur = image.size
    px = image.load()
    plat = [[False] * hauteur for _ in range(largeur)]
    for x in range(RAYON, largeur - RAYON):
        for y in range(RAYON, hauteur - RAYON):
            c = px[x, y]
            if not predicat(c):
                continue
            uni = True
            for dx, dy in ((RAYON, 0), (-RAYON, 0), (0, RAYON), (0, -RAYON)):
                v = px[x + dx, y + dy]
                if (abs(c[0] - v[0]) + abs(c[1] - v[1])
                        + abs(c[2] - v[2])) > SEUIL:
                    uni = False
                    break
            plat[x][y] = uni
    vu = [[False] * hauteur for _ in range(largeur)]
    tailles = []
    for x in range(RAYON, largeur - RAYON):
        for y in range(RAYON, hauteur - RAYON):
            if not plat[x][y] or vu[x][y]:
                continue
            file = deque([(x, y)])
            vu[x][y] = True
            taille = 0
            while file:
                cx, cy = file.popleft()
                taille += 1
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1),
                               (cx, cy - 1)):
                    if (RAYON <= nx < largeur - RAYON
                            and RAYON <= ny < hauteur - RAYON
                            and plat[nx][ny] and not vu[nx][ny]):
                        vu[nx][ny] = True
                        file.append((nx, ny))
            if taille >= MIN_COMPOSANTE:
                tailles.append(taille)
    tailles.sort(reverse=True)
    pixels = largeur * hauteur
    return (100.0 * sum(tailles) / pixels,
            100.0 * (tailles[0] if tailles else 0) / pixels)


def main(argv):
    if len(argv) != 1:
        print("usage: controle_aplats_ferme.py <dossier_de_captures>",
              file=sys.stderr)
        return 2
    dossier = argv[0]
    echecs = []
    print("%-20s %7s %7s %8s %7s %7s %8s" % ("vue", "max %", "total %",
                                             "baseline", "gris %", "grisMax",
                                             "verdict"))
    for nom in sorted(BASELINE_R2B):
        chemin = os.path.join(dossier, nom + ".png")
        if not os.path.exists(chemin):
            echecs.append("%s : capture absente (%s)" % (nom, chemin))
            print("%-20s %7s %7s %8.2f %7s %7s %8s"
                  % (nom, "-", "-", BASELINE_R2B[nom], "-", "-", "ABSENTE"))
            continue
        r = mesure(chemin)
        motifs = []
        if r["max_pct"] > PORTAIL_MAX_PCT:
            motifs.append("max %.2f > %.1f (portail lead)"
                          % (r["max_pct"], PORTAIL_MAX_PCT))
        if r["max_pct"] > MAX_COMPOSANTE_PCT:
            motifs.append("composante unique %.2f > %.1f (controle interne)"
                          % (r["max_pct"], MAX_COMPOSANTE_PCT))
        # `total`, l'ecart a la baseline et le GRIS : TEMOINS, pas verdicts.
        gris_total, gris_max = mesure_famille(chemin, est_neutre)
        print("%-20s %7.2f %7.2f %8.2f %7.2f %7.2f %8s"
              % (nom, r["max_pct"], r["total_pct"], BASELINE_R2B[nom],
                 gris_total, gris_max, "VERT" if not motifs else "ROUGE"))
        for m in motifs:
            print("      %s" % m)
            echecs.append("%s : %s" % (nom, m))
    print("LIANT   : max <= %.1f %% (portail lead, importe) et composante "
          "unique <= %.1f %% (controle interne)"
          % (PORTAIL_MAX_PCT, MAX_COMPOSANTE_PCT))
    print("TEMOINS : gris %% et grisMax — surface PLATE que le liant ne peut pas")
    print("          voir (est_beige exige r > v > b strict). Publies sans")
    print("          verdict ; attribution de la geometrie : audit independant.")
    print("TEMOINS : total %% et ecart a la baseline R2B — publies SANS "
          "verdict ; le seuil total <= %.1f %% a ete RETIRE par le lead le "
          "2026-08-19 (plancher de kit mesure a 21,85 / 26,37 %% sur "
          "ferme_seuil, zero piece ajoutee). Voir l'en-tete du fichier."
          % PORTAIL_TOTAL_PCT)
    if echecs:
        print("ROUGE : %d critere(s) en echec" % len(echecs))
        return 1
    print("VERT : les six vues passent les trois criteres")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
