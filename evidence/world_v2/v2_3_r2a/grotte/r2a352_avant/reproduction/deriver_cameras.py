#!/usr/bin/env python3
"""Derive les cameras de la passe R2a-3.5.2 depuis les coordonnees MODELE.

POURQUOI CE SCRIPT EXISTE. Une camera tapee a la main dans un JSON est un
nombre sans provenance. Ici chaque camera est DERIVEE d'un point du modele
Blender (celui que les mesures citent) par la chaine de repere du depot,
publiee dans `docs/CODEX_HANDOFF.md` ANNEXE C :

    1 unite = 1 m ; Blender Z-up, glTF/Godot Y-up
    modele -> GLB : (gx, gy, gz) = (ax, az, -ay)
    LACET_DEG = 45 (rotation.y de l'ouvrage, `waterfall_cave_place.gd`)
    azimut_glb = azimut_monde + 45

DEUX CONTROLES, ET LE SECOND EST NE D'UN ECHEC MESURE
=====================================================

1. CHAINE DE REPERE. Le modele sort de la bouche vers son +Z local et doit
   ressortir au sud-est monde (0,707 ; 0,707). Verifie, sinon on leve.

2. DEGAGEMENT. Premier jet du 2026-08-16 : sur quatre cameras derivees,
   **trois etaient inexploitables** — 09 et 11 posees DANS le massif (un
   aplat gris pleine image), 08 cadree si serre qu'elle ne montrait que
   l'ouverture noire et le fond de galerie. La derivation etait juste ; il
   lui manquait de savoir ou est la roche.

   On calcule donc la FONCTION D'APPUI de la boite englobante dans la
   direction de la camera, et on exige que la camera se projette au-dela,
   avec marge. La boite employee est l'UNION des deux geometries de l'A/B —
   `8bf1a1b3` et `cc3596c5` — parce qu'aucune des deux ne contient l'autre :
   l'APRES est plus courte de 1,45 m mais deborde de 0,48 m en -x. Une
   camera degagee sur une seule des deux pourrait etre muree sur l'autre.

   Ce controle ne remplace pas le rendu : une boite englobante ne connait
   pas les creux. Il elimine seulement le cas grossier, qui est celui qui
   s'est produit.

IMPLANTATION, relue depuis le depot (pas de memoire) :
  resources/world_v2/world_v2_layout.json  -> v2_site = [-110, 3, 6]
  waterfall_cave_place.gd : SEUIL_LOCAL = (4.0, -2.5) ; LACET_DEG = 45.0 ;
                            EXHAUSSEMENT = 0.50
  terrain gele sous (-106 ; 3,5) : 3,00 — MESURE par
  `probe_site_section.gd --center=-106,3.5 --span=8 --step=2`, plateau plat
  a 3,0 sur tout le voisinage. `P0.y = 3,50` n'est donc plus une deduction.

FOV : Godot `KEEP_HEIGHT` par defaut ⇒ `fov` est le FOV **VERTICAL**
(VISUAL_ASSET_BIBLE 3.1). Tout est vertical ici ; l'horizontal 16:9 est
imprime a cote pour qu'on ne puisse pas confondre en relisant.
"""
from __future__ import annotations

import json
import math
import sys

# ---------------------------------------------------------------- implantation
V2_SITE = (-110.0, 3.0, 6.0)
SEUIL_LOCAL = (4.0, -2.5)
EXHAUSSEMENT = 0.50
TERRAIN_MESURE = 3.00          # sonde du 2026-08-16, plateau plat
LACET_DEG = 45.0

P0 = (V2_SITE[0] + SEUIL_LOCAL[0],
      TERRAIN_MESURE + EXHAUSSEMENT,
      V2_SITE[2] + SEUIL_LOCAL[1])

# Boites englobantes GLB, lues par `tools/gltf_inspect.py` sur les deux
# fichiers reels. UNION : aucune ne contient l'autre.
BBOX_AVANT = ((-8.2934, -3.5503, -12.2514), (8.9118, 9.6435, 3.9919))
BBOX_APRES = ((-8.7717, -3.5509, -11.8987), (8.1739, 8.1923, 3.2305))
GX_MIN = min(BBOX_AVANT[0][0], BBOX_APRES[0][0])
GX_MAX = max(BBOX_AVANT[1][0], BBOX_APRES[1][0])
GZ_MIN = min(BBOX_AVANT[0][2], BBOX_APRES[0][2])
GZ_MAX = max(BBOX_AVANT[1][2], BBOX_APRES[1][2])

MARGE_DEGAGEMENT_M = 2.0       # au-dela de la boite, pour les creux qu'elle ignore


def modele_vers_glb(ax, ay, az):
    return (ax, az, -ay)


def glb_vers_monde(gx, gy, gz):
    t = math.radians(LACET_DEG)
    c, s = math.cos(t), math.sin(t)
    return (P0[0] + gx * c + gz * s, P0[1] + gy, P0[2] - gx * s + gz * c)


def modele_vers_monde(ax, ay, az):
    return glb_vers_monde(*modele_vers_glb(ax, ay, az))


def appui_bbox(phi_deg: float) -> float:
    """Fonction d'appui de l'union des boites, direction GLB `phi`."""
    c, s = math.cos(math.radians(phi_deg)), math.sin(math.radians(phi_deg))
    return (GX_MAX * c if c > 0 else GX_MIN * c) + \
           (GZ_MAX * s if s > 0 else GZ_MIN * s)


def _controle_chaine() -> None:
    o = modele_vers_monde(0.0, 0.0, 0.0)
    d = modele_vers_monde(0.0, -1.0, 0.0)
    v = (d[0] - o[0], d[2] - o[2])
    n = math.hypot(*v)
    ux, uz = v[0] / n, v[1] / n
    if abs(ux - 0.7071) > 2e-3 or abs(uz - 0.7071) > 2e-3:
        raise SystemExit("chaine de repere FAUSSE : bouche vers (%.4f ; %.4f)"
                         % (ux, uz))
    print("[chaine] OK — bouche au sud-est (%.4f ; %.4f), azimut monde 45,00"
          % (ux, uz))
    print("[chaine] P0 = (%.3f ; %.3f ; %.3f)   terrain MESURE %.2f + %.2f"
          % (P0[0], P0[1], P0[2], TERRAIN_MESURE, EXHAUSSEMENT))
    print("[chaine] union des boites GLB : x[%.3f ; %.3f]  z[%.3f ; %.3f]"
          % (GX_MIN, GX_MAX, GZ_MIN, GZ_MAX))


def fov_h_16_9(v: float) -> float:
    return math.degrees(2.0 * math.atan(
        math.tan(math.radians(v) / 2.0) * 16.0 / 9.0))


def camera(cible_modele, azimut_monde, distance, hauteur_rel, fov_v, nom,
           pourquoi):
    gx, gy, gz = modele_vers_glb(*cible_modele)
    phi = (azimut_monde + LACET_DEG) % 360.0
    c, s = math.cos(math.radians(phi)), math.sin(math.radians(phi))
    projection_cible = gx * c + gz * s
    appui = appui_bbox(phi)
    degagement = (projection_cible + distance) - appui
    cx, cy, cz = glb_vers_monde(gx, gy, gz)
    a = math.radians(azimut_monde)
    fx, fz = cx + math.cos(a) * distance, cz + math.sin(a) * distance
    fy = cy + hauteur_rel
    pitch = math.degrees(math.atan2(cy - fy, math.hypot(cx - fx, cz - fz)))
    champ_v = 2.0 * distance * math.tan(math.radians(fov_v) / 2.0)
    return {
        "name": nom,
        "from": [round(fx, 3), round(fy, 3), round(fz, 3)],
        "look": [round(cx, 3), round(cy, 3), round(cz, 3)],
        "fov": fov_v,
        "_repere": {
            "cible_modele": list(cible_modele),
            "azimut_monde_deg": azimut_monde,
            "azimut_glb_deg": phi,
            "distance_m": distance,
            "pitch_deg": round(pitch, 2),
            "fov_vertical_deg": fov_v,
            "fov_horizontal_16_9_deg": round(fov_h_16_9(fov_v), 2),
            "champ_vertical_m": round(champ_v, 2),
            "champ_horizontal_m": round(champ_v * 16.0 / 9.0, 2),
            "appui_bbox_m": round(appui, 3),
            "degagement_m": round(degagement, 3),
            "pourquoi": pourquoi,
        },
    }


# --------------------------------------------------------------------- vues
# Cibles MODELE citees par les mesures du handoff.
LEVRE = (-0.60, -1.20, 3.00)    # masse de la levre, au-dessus de la bouche
EPAULE = (-2.06, -1.20, 2.70)   # goulot 1,040 m, epaule GAUCHE (10.2)
SOUS = (-0.80, -1.30, 2.35)     # sous-face du surplomb
ORTEIL = (1.55, -1.40, 0.60)    # orteil de crete + pied elargi (10.2)

VUES = [
    camera(LEVRE, 45.0, 13.0, 1.20, 30.0, "08_visiere_face",
           "Q1. Premier jet a 8 m / fov 28 : le cadre etait rempli par "
           "l'ouverture noire et le fond de galerie. A 13 m / fov 30 le champ "
           "vertical passe de 3,99 a 6,97 m : la ROCHE au-dessus de la bouche "
           "domine, l'ouverture devient un element parmi d'autres."),
    camera(LEVRE, 100.0, 13.0, 1.50, 30.0, "09_visiere_profil",
           "Q1. DEUX jets rejetes avant celui-ci. Azimut 315 : camera DANS le "
           "massif (appui 8,91 pour une projection de 5,94). Azimut 135 : "
           "degagee, mais un profil a 90 deg RASE la face et le flanc du "
           "massif masque le porche — image dominee par un pilier au premier "
           "plan. L'azimut 100 est un TROIS-QUARTS a 55 deg de l'axe de "
           "bouche : il montre a la fois la face et la profondeur du "
           "surplomb, ce qu'un profil pur ne peut pas faire. C'est aussi "
           "l'azimut de la silhouette de composition, donc les deux se lisent "
           "ensemble."),
    camera(SOUS, 45.0, 9.0, -1.35, 36.0, "10_visiere_dessous",
           "Q2. Le premier jet etait deja structurellement juste : on voit "
           "l'arc de bouche par en dessous. Recule de 5 a 9 m et fov elargi "
           "pour que la sous-face tienne dans le cadre sans etre rognee."),
    camera(ORTEIL, 50.0, 6.0, 0.80, 34.0, "11_orteil_pied",
           "Q2. TROIS jets rejetes avant celui-ci. Azimut 350 : rasant, a "
           "demi enterre. Azimut 20 a 12 m : trop loin, trop a l'est, un "
           "rocher occupe le tiers droit. Azimut 35 a 7,5 m : le pied +x est "
           "bien au premier plan mais il masque la bouche, composition "
           "confuse. L'azimut 50 a 6 m est a 5 deg de l'axe de bouche : le "
           "pied se lit de trois-quarts AVEC le porche derriere lui, au lieu "
           "de le cacher. C'est la zone ou le lot collerette a cree puis "
           "comble une poche de 0,24 m en (1,43 ; -1,51 ; -0,28), et aucune "
           "autre vue ne la regarde. Degagement 2,52 m : le plus serre du "
           "lot, mais au-dessus de la marge."),
]


def main() -> int:
    _controle_chaine()
    print()
    dur = 0
    for v in VUES:
        r = v["_repere"]
        etat = "DEGAGE" if r["degagement_m"] >= MARGE_DEGAGEMENT_M else "!! DANS LA BOITE !!"
        if r["degagement_m"] < MARGE_DEGAGEMENT_M:
            dur += 1
        print("%-20s from %s  look %s" % (v["name"], v["from"], v["look"]))
        print("%-20s fov_v %.1f (h %.1f) | champ %.2f x %.2f m | pitch %+.1f"
              % ("", r["fov_vertical_deg"], r["fov_horizontal_16_9_deg"],
                 r["champ_horizontal_m"], r["champ_vertical_m"], r["pitch_deg"]))
        print("%-20s az monde %.0f / glb %.0f | d %.1f m | appui %.2f | "
              "degagement %+.2f m  %s"
              % ("", r["azimut_monde_deg"], r["azimut_glb_deg"], r["distance_m"],
                 r["appui_bbox_m"], r["degagement_m"], etat))
        print()
    if dur:
        print("ECHEC : %d camera(s) sous la marge de %.1f m." % (dur, MARGE_DEGAGEMENT_M))
        return 1
    if len(sys.argv) > 1:
        with open(sys.argv[1], "w", encoding="utf-8") as f:
            json.dump(VUES, f, ensure_ascii=False, indent=2)
        print("[ecrit] %s" % sys.argv[1])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
