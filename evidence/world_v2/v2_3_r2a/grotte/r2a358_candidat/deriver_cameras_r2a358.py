#!/usr/bin/env python3
"""Re-derive les 15 cameras de la passe R2a-3.5.8 — AUCUN nombre tape a la main.

POURQUOI. R2a-3.5.7 a etabli que les cameras de `shots_r2a352.json` sont
perimees (la salle a ete deplacee dans le modele) et que toute camera sans
provenance est un nombre mort. Chaque camera ici est DERIVEE :
  - soit d'une ANCRE du depot (waterfall_cave_place.gd : MODELE_SEUIL_DEHORS,
    MODELE_SALLE, MODELE_NICHE) passee par la chaine de repere publiee ;
  - soit REPRISE A L'IDENTIQUE du manifeste R2a-3.4 (`tranche4_final/
    manifest.json`, commit 55c4803c, repo_dirty=false) pour les 4 vues A/B —
    un A/B compare deux geometries depuis LE MEME point de vue, la camera ne
    doit donc PAS etre re-derivee.

CHAINE DE REPERE (docs/CODEX_HANDOFF.md ANNEXE C, relue le 2026-08-18) :
  world(p) = ORIGINE + R_y(45 deg) . p        (p en repere GLB)
  ORIGINE = v2_site + (SEUIL_LOCAL.x, assise, SEUIL_LOCAL.y)
          = (-110,3,6) + (4.0, 0.5 + terrain 3.0 - 3.0(site y), -2.5)
          = (-106.0, 3.50, 3.50)   [terrain gele 3.00 mesure, +0.50 EXHAUSSEMENT]
CONTROLE 1 : +Z modele doit sortir au sud-est monde (0.707, 0.707) — leve sinon.
CONTROLE 2 (degagement) : la camera doit se projeter AU-DELA de la fonction
d'appui de l'AABB monde de la geometrie BASELINE 40714c46 (mesuree par
tools/gltf_inspect.py, log 03), marge 1.0 m. Une AABB ne connait pas les
creux : les vues INTERIEURES (04, 05) sont volontairement DANS la boite et
portent `interieur=true` — le controle ne s'applique qu'aux exterieures.
FOV : Godot KEEP_HEIGHT ⇒ `fov` est le FOV VERTICAL (VISUAL_ASSET_BIBLE §3.1).
"""
import json
import math
import sys

ORIGINE = (-106.0, 3.50, 3.50)
LACET = math.radians(45.0)
# AABB GLB de la baseline 40714c46 (gltf_inspect, log 03_gltf_inspect_baseline)
BB_MIN = (-8.7717, -3.5509, -11.8987)
BB_MAX = (8.1739, 8.1923, 3.2305)
# Ancres modele (waterfall_cave_place.gd, HEAD 52ce1b5)
SEUIL = (0.0, 0.10, 1.60)
SALLE = (1.05, 0.22, -6.25)
NICHE = (-1.20, 0.43, -8.20)


def monde(p):
    c, s = math.cos(LACET), math.sin(LACET)
    x = c * p[0] + s * p[2]
    z = -s * p[0] + c * p[2]
    return (ORIGINE[0] + x, ORIGINE[1] + p[1], ORIGINE[2] + z)


def controle_axe():
    a, b = monde((0, 0, 0)), monde((0, 0, 1))
    dx, dz = b[0] - a[0], b[2] - a[2]
    assert abs(dx - 0.7071) < 1e-3 and abs(dz - 0.7071) < 1e-3, \
        "chaine de repere fausse : +Z modele ne sort pas au sud-est"


def coins_monde():
    for cx in (BB_MIN[0], BB_MAX[0]):
        for cy in (BB_MIN[1], BB_MAX[1]):
            for cz in (BB_MIN[2], BB_MAX[2]):
                yield monde((cx, cy, cz))


def degage(cam, vise, marge=1.0):
    """Fonction d'appui : la camera est-elle au-dela de l'AABB monde,
    dans SA direction de vue ? (heritee de deriver_cameras.py 3.5.2)"""
    d = tuple(c - v for c, v in zip(cam, vise))
    n = math.sqrt(sum(x * x for x in d))
    d = tuple(x / n for x in d)
    appui = max(sum(c * u for c, u in zip(coin, d)) for coin in coins_monde())
    proj = sum(c * u for c, u in zip(cam, d))
    return proj >= appui + marge, proj - appui


def vers(anchor_m, azimut_deg, dist, hauteur, fov, nom, but, interieur=False,
         ab_reference=None, monde_deja=False, look_m=None):
    a = anchor_m if monde_deja else monde(anchor_m)
    if look_m is not None:
        a_look = look_m if monde_deja else monde(look_m)
    else:
        a_look = a
    az = math.radians(azimut_deg)
    cam = (a[0] + dist * math.sin(az), a[1] + hauteur, a[2] + dist * math.cos(az))
    return {"name": nom, "from": [round(v, 2) for v in cam],
            "look": [round(v, 2) for v in a_look], "fov": fov, "but": but,
            "interieur": interieur, "ab_reference": ab_reference,
            "derivation": "ancre %s, azimut monde %g deg, distance %g m, +%g m"
                          % (list(anchor_m), azimut_deg, dist, hauteur)}


def main():
    controle_axe()
    seuil_w, salle_w, niche_w = monde(SEUIL), monde(SALLE), monde(NICHE)
    centre_w = tuple((mn + mx) / 2 for mn, mx in
                     zip(*[(min(c[i] for c in coins_monde()),
                            max(c[i] for c in coins_monde()))
                           for i in range(3)])) if False else \
        tuple(sum(c[i] for c in coins_monde()) / 8 for i in range(3))
    shots = []
    # --- 7 vues nommees, intentions du jeu de reference R2a-3.1 ; azimuts
    #     de la famille frontale alignes sur les cameras R2a-3.4 relues
    #     (AB_approche_joueur : azimut 33.5 deg du seuil monde) ---
    shots.append(vers(SEUIL, 35, 16.0, 3.0, 44.0, "01_composition",
                      "les trois masses et la bouche dans un seul cadre"))
    shots.append(vers(SEUIL, 33, 9.0, 1.6, 55.0, "02_approche_joueur",
                      "hauteur d'oeil joueur, sentier d'approche"))
    shots.append(vers(SEUIL, 40, 6.0, 1.2, 28.0, "03_gros_plan_seuil",
                      "linteau et joues du seuil, lisibilite du passage"))
    shots.append(vers(SALLE, 0, 0.0, 1.4, 65.0, "04_interieur_sortie",
                      "depuis la salle vers la lumiere de la bouche",
                      interieur=True, look_m=SEUIL))
    shots.append(vers(SALLE, 0, 0.0, 1.4, 60.0, "05_interieur_niche",
                      "la niche et son champignon (recompense)",
                      interieur=True, look_m=NICHE))
    shots.append(vers(SEUIL, 100, 15.0, 2.5, 45.0, "06_flanc_strates",
                      "strates du flanc est, raccord terrain"))
    shots.append(vers(SEUIL, 38, 15.0, 4.5, 45.0, "07_trois_masses",
                      "silhouette des trois masses, cadre large"))
    # --- 4 vues A/B : cameras EXACTES de R2a-3.4 (tranche4_final) ---
    t4 = json.load(open("/home/user/Zelda/evidence/world_v2/v2_3_r2a/grotte/"
                        "tranche4_final/manifest.json"))
    for s in t4["shots"]:
        shots.append({"name": "AB_" + s["name"], "from": s["from"],
                      "look": s["look"], "fov": s["fov"],
                      "but": "A/B contre R2a-3.4 — MEME camera, deux geometries",
                      "interieur": False, "ab_reference": s["image"],
                      "derivation": "reprise a l'identique de tranche4_final/"
                                    "manifest.json (commit 55c4803c)"})
    # --- 4 tournette cardinales autour du centre monde ---
    for az in (0, 90, 180, 270):
        shots.append(vers(centre_w, az, 22.0, 6.0, 40.0,
                          "tournette_%03d" % az,
                          "rotation cardinale, controle des raccords",
                          ab_reference="evidence/world_v2/v2_3_r2a/grotte/"
                                       "tournette_%03d.png" % az,
                          monde_deja=True))
    # --- controle de degagement ---
    fautes = 0
    for s in shots:
        if s["interieur"]:
            s["degagement"] = "n/a (vue interieure, hors controle AABB)"
            continue
        ok, marge = degage(tuple(s["from"]), tuple(s["look"]))
        s["degagement"] = "%s (marge %.2f m)" % ("OK" if ok else "MUREE", marge)
        if not ok:
            fautes += 1
    doc = {"passe": "R2a-3.5.8", "geometrie_baseline":
           "40714c46544e27d23fce271d2814020c0683aa78f71106934215ee8666dc11a0",
           "origine_monde": ORIGINE, "lacet_deg": 45.0,
           "fov_convention": "VERTICAL (Godot KEEP_HEIGHT)",
           "taille": "1280x720", "shots": shots,
           "silhouettes": {"angles_deg": [55, 100, 225],
                           "outil": "capture_silhouette.gd puis "
                                    "measure_silhouette_masses.py --entaille=0.90",
                           "reference": "tranche4_final/"
                                        "manifest_silhouettes_grotte_r2a34.json"},
           "note": "cameras derivees, captures NON faites — elles attendent "
                   "l'arbre committe (regle evidence.md).",
           }
    out = sys.argv[1] if len(sys.argv) > 1 else "shots_r2a358.json"
    json.dump(doc, open(out, "w"), indent=1, ensure_ascii=False)
    print("15 vues ecrites dans %s ; %d camera(s) muree(s)" % (out, fautes))
    for s in shots:
        print("  %-22s from=%s fov=%g %s" % (s["name"], s["from"], s["fov"],
                                             s["degagement"]))
    return 1 if fautes else 0


if __name__ == "__main__":
    sys.exit(main())
