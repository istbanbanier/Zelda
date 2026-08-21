#!/usr/bin/env python3
"""Assemble `SITES.md` à partir des DEUX documents de mesure du lot 1.

Il n'existe pas pour économiser de la frappe : il existe pour qu'aucun nombre
du tableau publié ne soit recopié à la main. Un chiffre retapé diverge de sa
source sans que personne ne le remarque — c'est la règle d'ancrage du
`CLAUDE.md`, et ce dépôt l'a déjà payée.

Entrées :
  * `geometrie_xz.json`   — tools/mesure_implantation_lot1.py --json
  * `sonde.json`          — bloc entre === IMPLANTATION_BEGIN/END === de
                            tools/godot/sonde_implantation_lot1.gd

Usage :
  python3 tools/publier_sites_lot1.py \\
      --geometrie evidence/.../geometrie_xz.json \\
      --sonde     evidence/.../sonde.json \\
      > evidence/.../SITES.md

Le script ÉCHOUE en 3 si un sujet manque d'un côté ou de l'autre : un tableau
à trous se lit comme un tableau complet.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

SUJETS = [
    "valley.poi.watchtower_ruin.01",
    "valley.poi.overlook_summit.01",
    "valley.poi.turquoise_spring.01",
    "valley.poi.forest_shrine.01",
    "valley.poi.barrow_cemetery.01",
    "valley.poi.flower_field.01",
]

CAMERAS = ["cam01_spawn_vista", "cam02_camp_pylone", "cam03_pylone_marche",
           "cam04_falaise_cuvette", "cam05_belvedere_crete",
           "cam06_plateau_vallee"]


def court(poi_id: str) -> str:
    return poi_id.replace("valley.poi.", "").replace(".01", "")


def fr(valeur, gabarit: str = "%.2f") -> str:
    """Nombre à la française — la virgule décimale, comme partout ailleurs."""
    if isinstance(valeur, str):
        return valeur
    return (gabarit % valeur).replace(".", ",")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--geometrie", required=True, type=Path)
    ap.add_argument("--sonde", required=True, type=Path)
    args = ap.parse_args()

    geo = json.loads(args.geometrie.read_text(encoding="utf-8"))["sujets"]
    doc = json.loads(args.sonde.read_text(encoding="utf-8"))
    son = doc["sujets"]

    manquants = [s for s in SUJETS if s not in geo or s not in son]
    if manquants:
        print("BLOQUÉ : sujets absents d'un des deux documents : %s"
              % ", ".join(manquants), file=sys.stderr)
        return 3
    if doc.get("bloques"):
        print("BLOQUÉ : la sonde a signalé %d blocage(s) : %s"
              % (len(doc["bloques"]), " ; ".join(doc["bloques"])), file=sys.stderr)
        return 3

    repere = doc.get("repere_vegetation", {})
    out: list[str] = []
    a = out.append

    a("# Lot 1 — implantation des six sites : ce que le terrain gelé permet")
    a("")
    a("**VIVANT.** Voie A de V2.3-B, lot 1. Une ligne par sujet, mesurée, avec")
    a("un verdict `POSABLE` / `CONTRAINT (raison)` / `IMPOSSIBLE (raison)`.")
    a("")
    a("Rien ici n'est un jugement artistique : ce document dit si un lieu **tient**")
    a("à son site, et ce qu'il en coûtera à la voie B. Il ne dit rien de ce qu'il")
    a("faut y bâtir.")
    a("")
    a("## Provenance")
    a("")
    a("| | |")
    a("|---|---|")
    a("| commit mesuré | `%s` |" % doc.get("commit", "inconnu"))
    a("| arbre sale au moment de la mesure | `%s` |" % doc.get("repo_dirty", "?"))
    a("| sonde | `%s` |" % doc.get("sonde", "?"))
    a("| géométrie XZ | `tools/mesure_implantation_lot1.py` |")
    a("| rayon de végétation | %s m |" % fr(doc.get("rayon_vegetation_m", 0), "%.0f"))
    a("| disque de pente | %s m |" % fr(doc.get("rayon_pente_m", 0), "%.0f"))
    a("| fraction de visée exigée libre | %s |" % fr(
        doc.get("clear_sight_fraction", 0), "%.2f"))
    a("")
    a("Reproduction :")
    a("")
    a("```bash")
    a("python3 tools/mesure_implantation_lot1.py --json > geometrie_xz.json")
    a("tools/lancer_godot.sh --headless --path . --import")
    a("tools/lancer_godot.sh --headless --path . \\")
    a("    --script tools/godot/sonde_implantation_lot1.gd > sonde.log")
    a("# extraire le bloc entre === IMPLANTATION_BEGIN === et === IMPLANTATION_END ===")
    a("python3 tools/publier_sites_lot1.py --geometrie geometrie_xz.json \\")
    a("    --sonde sonde.json > SITES.md")
    a("```")
    a("")
    a("**Repère de la végétation, vérifié avant tout comptage.** Les origines")
    a("brutes de `instance_origins` collent au sol à %s m de résidu moyen ; les"
      % fr(repere.get("residu_ancrage_brut_m", 0), "%.3f"))
    a("mêmes points remultipliés par `global_transform` s'en écartent de %s m."
      % fr(repere.get("residu_ancrage_transforme_m", 0), "%.3f"))
    a("La lecture retenue est donc « coordonnées MONDE », et la sonde aurait")
    a("bloqué si les deux s'étaient valus (%d instance(s) échantillonnée(s) sur"
      % repere.get("echantillons", 0))
    a("%d cellule(s))." % repere.get("cellules", 0))
    a("")
    a("## Le tableau")
    a("")
    a("| sujet | site v2 | sol | écart | pente max | pente moy | dénivelé | route | gué | cours | affluent | eau | végét. | verdict |")
    a("|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|")
    for pid in SUJETS:
        s = son[pid]
        site = s["v2_site"]
        a("| `%s` | (%g, %g, %g) | %s | %s | %s° | %s° | %s | %s | %s | %s | %s | %s | %d | %s |" % (
            court(pid), site[0], site[1], site[2],
            fr(s["hauteur_terrain_m"]),
            fr(s["ecart_layout_m"], "%+.2f"),
            fr(s["pente_max_deg"], "%.1f"),
            fr(s["pente_moyenne_deg"], "%.1f"),
            fr(s["denivele_disque_m"]),
            fr(s["route_la_plus_proche"][1], "%.1f"),
            fr(s["gue_le_plus_proche"][1], "%.1f"),
            fr(s["cours_principal_m"], "%.1f"),
            fr(s["affluent_m"], "%.1f"),
            s["eau_echantillons_mouilles"],
            s["vegetation_dans_rayon"],
            s["verdict"].split(" (")[0],
        ))
    a("")
    a("`sol` : `height_at` au site. `écart` : sol − `y` du layout (le bâtisseur")
    a("pose la racine au sol, pas au `y`). `eau` : nombre d'échantillons sous une")
    a("surface d'eau, sur %d sondés. `végét.` : instances gelées dans %s m."
      % (son[SUJETS[0]]["eau_echantillons"],
         fr(doc.get("rayon_vegetation_m", 0), "%.0f")))
    a("")
    a("## Les six fenêtres gelées : distance latérale et GARDE du rayon")
    a("")
    a("La distance latérale ne décide de rien à elle seule. Ce qui décide, c'est")
    a("la hauteur du rayon de visée au-dessus du terrain, au point où il passe le")
    a("plus près du site : c'est le plafond sous lequel une masse peut monter")
    a("sans couper la fenêtre. `—` signale que le site est **derrière**")
    a("l'objectif (paramètre d'approche nul).")
    a("")
    entete = "| sujet | " + " | ".join(c.replace("_", " ") for c in CAMERAS) + " |"
    a(entete)
    a("|---|" + "---:|" * len(CAMERAS))
    for pid in SUJETS:
        cams = son[pid]["cameras"]
        cellules = []
        for nom in CAMERAS:
            c = cams.get(nom)
            if c is None:
                cellules.append("?")
                continue
            marque = " ⟂" if c["derriere_la_camera"] else ""
            cellules.append("%s / %s%s" % (
                fr(c["distance_segment_vise_xz_m"], "%.1f"),
                fr(c["garde_rayon_sur_sol_m"], "%.1f"), marque))
        a("| `%s` | %s |" % (court(pid), " | ".join(cellules)))
    a("")
    a("Lecture d'une cellule : `distance latérale au segment / garde du rayon")
    a("au-dessus du sol`, en mètres. `⟂` : site derrière l'objectif.")
    a("")
    a("## Sujet par sujet")
    a("")
    for pid in SUJETS:
        s = son[pid]
        g = geo[pid]
        a("### `%s`" % pid)
        a("")
        a("**%s**" % s["verdict"])
        a("")
        a("| grandeur | valeur |")
        a("|---|---|")
        a("| site du layout | (%g, %g, %g) |" % tuple(s["v2_site"]))
        a("| sol gelé au site | %s m (écart %s m avec le `y` du layout) |"
          % (fr(s["hauteur_terrain_m"]), fr(s["ecart_layout_m"], "%+.2f")))
        a("| pente au centre | %s° |" % fr(s["pente_centre_deg"], "%.2f"))
        a("| pente max sur le disque | %s° en (%s ; %s) |" % (
            fr(s["pente_max_deg"], "%.2f"),
            fr(s["pente_max_xz"][0], "%.1f"), fr(s["pente_max_xz"][1], "%.1f")))
        a("| hauteurs sur le disque | %s → %s m (dénivelé %s m) |" % (
            fr(s["hauteur_min_disque_m"]), fr(s["hauteur_max_disque_m"]),
            fr(s["denivele_disque_m"])))
        a("| route la plus proche | %s à %s m (marge %s m) |" % (
            s["route_la_plus_proche"][0], fr(s["route_la_plus_proche"][1]),
            fr(g["marge_route_m"], "%+.2f")))
        a("| gué le plus proche | %s à %s m |" % (
            s["gue_le_plus_proche"][0], fr(s["gue_le_plus_proche"][1])))
        a("| cours principal | %s m (bande %s m, marge %s m) |" % (
            fr(s["cours_principal_m"]), fr(s["cours_principal_bande_m"], "%.1f"),
            fr(s["cours_principal_m"] - s["cours_principal_bande_m"], "%+.2f")))
        a("| affluent | %s m (bande %s m, marge %s m) |" % (
            fr(s["affluent_m"]), fr(s["affluent_bande_m"], "%.1f"),
            fr(s["affluent_m"] - s["affluent_bande_m"], "%+.2f")))
        a("| lac | %s m du centre (bande %s m) |" % (
            fr(s["lac_centre_m"]), fr(s["lac_bande_m"], "%.1f")))
        a("| eau sous le site | %d échantillon(s) mouillé(s) sur %d ; %s |" % (
            s["eau_echantillons_mouilles"], s["eau_echantillons"],
            ("surface − sol max %s m" % fr(s["eau_submersion_max_m"]))
            if not isinstance(s["eau_submersion_max_m"], str)
            else s["eau_submersion_max_m"]))
        a("| végétation gelée dans le rayon | %d instance(s), la plus proche à %s |" % (
            s["vegetation_dans_rayon"],
            ("%s m" % fr(s["vegetation_plus_proche_m"]))
            if not isinstance(s["vegetation_plus_proche_m"], str)
            else s["vegetation_plus_proche_m"]))
        a("| colliders végétaux dans le rayon | %d |"
          % len(s["colliders_vegetaux_dans_rayon"]))
        a("| voisin de layout le plus proche | %s à %s m |" % (
            g["voisin_le_plus_proche"][0], fr(g["voisin_le_plus_proche"][1])))
        a("| lieu déjà bâti le plus proche | %s à %s m |" % (
            g["lieu_bati_le_plus_proche"][0], fr(g["lieu_bati_le_plus_proche"][1])))
        a("")
        if s["vegetation_par_couche"]:
            couches = sorted(s["vegetation_par_couche"].items(),
                             key=lambda kv: -kv[1])
            a("Végétation gelée par couche, à composer **autour** : %s."
              % ", ".join("%s ×%d" % (nom, n) for nom, n in couches))
            a("")
        if s["colliders_vegetaux_dans_rayon"]:
            a("Colliders végétaux gelés dans le rayon — ce sont des obstacles")
            a("réels, pas du décor :")
            a("")
            for c in sorted(s["colliders_vegetaux_dans_rayon"],
                            key=lambda c: c["distance_m"]):
                a("* `%s` à %s m, en (%s ; %s)" % (
                    c["nom"], fr(c["distance_m"]),
                    fr(c["xz"][0], "%.1f"), fr(c["xz"][1], "%.1f")))
            a("")
    return 0


if __name__ == "__main__":
    sys.exit(main())
