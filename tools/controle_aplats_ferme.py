#!/usr/bin/env python3
"""CONTRÔLE D'APLATS DE LA FERME — porte de R2B.2, seuils du lead INCHANGÉS.

POURQUOI CE FICHIER EXISTE. `tools/mesure_aplats.py` MESURE ; il ne juge pas.
Le jugement était jusqu'ici tenu à la main, donc absent des journaux. Ici il
est exécutable, et il porte les trois critères arbitrés le 2026-08-19 :

  1. PORTAIL DU LEAD, recopié tel quel depuis `mesure_aplats.py`, jamais
     redéfini : `max_pct <= 8.0` et `total_pct <= 12.0`. Aucun chiffre du lead
     n'est touché ici — ils sont IMPORTÉS du module de mesure.

  2. RETOUR SOUS LA BASELINE R2B (arbitrage du lead). Le plancher d'aplat
     imposé par le kit lui-même est présent dans l'AVANT comme dans l'APRÈS,
     donc il s'annule dans la comparaison : la régression introduite par R2B.1
     doit être ENTIÈREMENT effacée. Mesuré le 2026-08-19 sur
     `evidence/world_v2/v2_3_r2b1/avant/` :

         approche 3.92 · composition 3.03 · arriere 6.89 · facade 4.83
         laterale 11.91 · seuil 23.74

  3. CONTRÔLE INTERNE AJOUTÉ (agent A) : `max_pct <= 3.0`. Ce n'est PAS un
     assouplissement — c'est plus strict que le portail du lead. Il vise la
     tache unique qui fait « carton » plutôt que la somme diffuse : sur
     `ferme_seuil`, la composante #0 vaut 7,32 % à elle seule et c'est le
     tableau droit `SM_Farm_Jamb_Breach`.

PIÈGE MESURÉ (2026-08-19) : à FOV 66 et ~2 m du mur, chaque pierre peinte de
`T_UnevenBrick` dépasse `MIN_COMPOSANTE = 1500 px`. Les bandes de PUR kit de
`ferme_seuil` donnent 8,11 % à elles seules. Le portail « total <= 12 % » sur
cette vue ne laisse donc que 3,9 points au bâti ajouté : c'est une propriété du
cadrage, pas un défaut de l'instrument, et c'est pourquoi le critère 2 existe.

Usage :
  python3 tools/controle_aplats_ferme.py <dossier_de_captures>
Sortie : 0 tout vert · 1 un critère échoue.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mesure_aplats import (  # noqa: E402  (import après ajustement du path)
    PORTAIL_MAX_PCT, PORTAIL_TOTAL_PCT, mesure)

# Baseline R2B, avant la première corrective. Littéraux figés : un contrôle qui
# relit sa propre référence à chaque passage suit la dérive au lieu de l'attraper.
BASELINE_R2B = {
    "ferme_approche": 3.92, "ferme_composition": 3.03, "ferme_arriere": 6.89,
    "ferme_facade": 4.83, "ferme_laterale": 11.91, "ferme_seuil": 23.74,
}
MAX_COMPOSANTE_PCT = 3.0


def main(argv):
    if len(argv) != 1:
        print("usage: controle_aplats_ferme.py <dossier_de_captures>",
              file=sys.stderr)
        return 2
    dossier = argv[0]
    echecs = []
    print("%-20s %8s %8s %8s %10s" % ("vue", "max %", "total %", "baseline",
                                      "verdict"))
    for nom in sorted(BASELINE_R2B):
        chemin = os.path.join(dossier, nom + ".png")
        if not os.path.exists(chemin):
            echecs.append("%s : capture absente (%s)" % (nom, chemin))
            print("%-20s %8s %8s %8.2f %10s" % (nom, "-", "-",
                                                BASELINE_R2B[nom], "ABSENTE"))
            continue
        r = mesure(chemin)
        motifs = []
        if r["max_pct"] > PORTAIL_MAX_PCT:
            motifs.append("max %.2f > %.1f (portail lead)"
                          % (r["max_pct"], PORTAIL_MAX_PCT))
        if r["total_pct"] > PORTAIL_TOTAL_PCT:
            motifs.append("total %.2f > %.1f (portail lead)"
                          % (r["total_pct"], PORTAIL_TOTAL_PCT))
        if r["total_pct"] >= BASELINE_R2B[nom]:
            motifs.append("total %.2f >= baseline R2B %.2f — regression non "
                          "effacee" % (r["total_pct"], BASELINE_R2B[nom]))
        if r["max_pct"] > MAX_COMPOSANTE_PCT:
            motifs.append("composante unique %.2f > %.1f (controle interne)"
                          % (r["max_pct"], MAX_COMPOSANTE_PCT))
        print("%-20s %8.2f %8.2f %8.2f %10s" % (nom, r["max_pct"],
              r["total_pct"], BASELINE_R2B[nom],
              "VERT" if not motifs else "ROUGE"))
        for m in motifs:
            print("      %s" % m)
            echecs.append("%s : %s" % (nom, m))
    print("portail lead (importe, non modifie) : max <= %.1f %%, total <= "
          "%.1f %% ; controle interne : composante unique <= %.1f %%"
          % (PORTAIL_MAX_PCT, PORTAIL_TOTAL_PCT, MAX_COMPOSANTE_PCT))
    if echecs:
        print("ROUGE : %d critere(s) en echec" % len(echecs))
        return 1
    print("VERT : les six vues passent les trois criteres")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
