#!/usr/bin/env python3
"""D3 — LE DÉTECTEUR DE RÉPÉTITION du lot 1 de V2.3-B.

Compare les silhouettes en aplat noir des six nouveaux lieux entre eux ET
contre le corpus déjà accepté, à trois distances de lecture, et applique la
règle de seuil **R-D3 pré-enregistrée** dans `docs/V2_3_B_LOT1_CONTROLES.md`
§3 — un document committé AVANT la première mesure, pour que le seuil ne
puisse pas être choisi après avoir vu ce qu'il doit juger.

CE QU'IL LIT. Les PNG produits par `tools/godot/capture_silhouette.gd` :
projection ORTHOGONALE, cadrage dérivé de l'AABB du sujet, deux valeurs de
pixel seulement (l'outil de capture refuse d'écrire une image non bimodale).
Le cadrage AABB normalise l'échelle : la comparaison porte donc sur la FORME,
qui est la question posée — « ces deux lieux se ressemblent-ils ? » — et non
sur la taille, qui n'a jamais été le défaut reproché.

LES TROIS DISTANCES SANS DÉPLACER LA CAMÉRA. La projection est orthogonale :
reculer ne changerait rien. Ce que la distance retire vraiment, c'est de la
RÉSOLUTION. Pour un sujet de hauteur H vu à d mètres, avec le FOV vertical réel
du jeu (`camera_fov = 44,0`, `KEEP_HEIGHT`, `resources/tuning/
locomotion_default.tres`) sur un écran 1080p :

    h_px(d) = 1080 * H / (2 * d * tan(44° / 2))

La silhouette est sous-échantillonnée à cette hauteur (moyenne d'aire, `BOX`),
puis ré-échantillonnée sur une toile commune de 96×96 pour que deux sujets
soient comparables. Le sous-échantillonnage EST la perte ; la toile commune ne
fait que rendre les masques superposables.

DEUX MESURES, PUBLIÉES ENSEMBLE. Une seule se contourne ; deux qui se
contredisent se voient.

    IoU      intersection sur union des masques — le LIANT
    dprofil  distance L1 normalisée entre les profils supérieurs, la
             statistique dont `tools/measure_silhouette_masses.py` a montré
             qu'elle porte la lecture d'une formation — publiée, non liante

LA RÈGLE R-D3, recopiée ici pour qu'on n'ait pas à la chercher : le seuil S(d)
est le MAXIMUM d'IoU observé entre deux sujets DISTINCTS du corpus ACCEPTÉ à
cette distance, tous angles confondus. Une paire du lot 1 est signalée si son
IoU dépasse S(d). En français : deux lieux du lot n'ont pas le droit de se
ressembler davantage que deux lieux que le lead a DÉJÀ jugés distincts.

    R-D3b  si S(d) ≥ 0,90, la calibration est INVALIDE et le verdict est
           BLOQUÉ, jamais PASS. À ce niveau deux masques se recouvrent sur
           neuf dixièmes de leur aire : deux bâtis différents ne peuvent pas
           y parvenir, donc c'est l'instrument ou le cadrage qui est cassé —
           et un seuil dérivé d'un instrument cassé absout tout.
    R-D3c  moins de 6 sujets acceptés ⇒ BLOQUÉ. Sous ce compte, `max` sur si
           peu de paires n'est plus une statistique, c'est un accident.

LE TÉMOIN DÉGÉNÉRÉ. Le détecteur compare aussi une silhouette acceptée à
ELLE-MÊME. Elle doit rendre IoU = 1,000 et être SIGNALÉE. S'il ne signale pas
ce couple-là, il ne signale rien, et son verdict est jeté (BLOQUÉ). C'est le
contrôle négatif intégré : un détecteur qui ne peut pas rougir ne prouve rien.

Usage :
    python3 tools/lot1_repetition.py --manifestes evidence/.../silhouettes
    python3 tools/lot1_repetition.py --manifestes <dir> --out <verdict.json>
    python3 tools/lot1_repetition.py --autotest

Codes : 0 = PASS · 1 = FAIL (au moins une paire signalée) · 3 = BLOQUÉ
"""

from __future__ import annotations

import argparse
import json
import math
import subprocess
import sys
from pathlib import Path

from PIL import Image

# --- Constantes de la règle, toutes pré-enregistrées -------------------------
DISTANCES_M = (30.0, 80.0, 160.0)
FOV_VERTICAL_DEG = 44.0          # locomotion_default.tres, KEEP_HEIGHT
HAUTEUR_ECRAN_PX = 1080
TOILE = 96                       # toile commune de comparaison
SEUIL_BINAIRE = 118              # entre 0,045 et 0,88 de luminance × 255
PLAFOND_CALIBRATION = 0.90       # R-D3b
CORPUS_MINIMUM = 6               # R-D3c

LOT1 = [
    "valley.poi.watchtower_ruin.01",
    "valley.poi.overlook_summit.01",
    "valley.poi.turquoise_spring.01",
    "valley.poi.forest_shrine.01",
    "valley.poi.barrow_cemetery.01",
    "valley.poi.flower_field.01",
]
CORPUS_ACCEPTE = [
    "camp",
    "valley.poi.riverside_village.01",
    "valley.poi.abandoned_farm.01",
    "valley.poi.stone_bridge.01",
    "valley.poi.waterfall_cave.01",
    "valley.poi.thunderstruck_tree.01",
    "valley.poi.ember_raider_camps.01",
    "valley.poi.conductive_basin.01",
    "pylon",
]


class Vue:
    """Une silhouette : un sujet, un angle, une hauteur réelle en mètres."""

    def __init__(self, place_id: str, sujet: str, angle: float,
                 chemin: Path, hauteur_m: float) -> None:
        self.place_id = place_id
        self.sujet = sujet
        self.angle = angle
        self.chemin = chemin
        self.hauteur_m = hauteur_m
        self._masques: dict[float, tuple[list[bool], list[int]]] = {}

    def masque(self, distance_m: float) -> tuple[list[bool], list[int]]:
        """Masque binaire 96×96 et profil supérieur, à la distance donnée."""
        if distance_m in self._masques:
            return self._masques[distance_m]
        image = Image.open(self.chemin).convert("L")
        cible = hauteur_apparente_px(self.hauteur_m, distance_m)
        # On ne SUR-échantillonne jamais : à 30 m un petit sujet peut occuper
        # plus de pixels que la capture n'en porte, et inventer du détail
        # rendrait la comparaison plus fine qu'elle ne peut l'être.
        if cible < image.height:
            largeur = max(1, round(image.width * cible / image.height))
            image = image.resize((largeur, max(1, round(cible))), Image.BOX)
        image = image.resize((TOILE, TOILE), Image.BOX)
        pixels = list(image.getdata())
        masque = [p < SEUIL_BINAIRE for p in pixels]
        profil = profil_superieur(masque)
        self._masques[distance_m] = (masque, profil)
        return self._masques[distance_m]


def hauteur_apparente_px(hauteur_m: float, distance_m: float) -> float:
    demi = math.tan(math.radians(FOV_VERTICAL_DEG) / 2.0)
    return HAUTEUR_ECRAN_PX * hauteur_m / (2.0 * distance_m * demi)


def profil_superieur(masque: list[bool]) -> list[int]:
    """Pour chaque colonne, la première ligne de sujet en partant du haut.

    `TOILE` (et non 0) quand la colonne est vide : le sentinel doit être la
    valeur la PLUS BASSE possible, sinon une colonne vide se lit comme un
    sommet, et deux silhouettes étroites se ressemblent par leurs vides.
    """
    profil = []
    for x in range(TOILE):
        trouve = TOILE
        for y in range(TOILE):
            if masque[y * TOILE + x]:
                trouve = y
                break
        profil.append(trouve)
    return profil


def iou(a: list[bool], b: list[bool]) -> float:
    inter = 0
    union = 0
    for i in range(len(a)):
        if a[i] or b[i]:
            union += 1
            if a[i] and b[i]:
                inter += 1
    return 0.0 if union == 0 else inter / union


def dprofil(a: list[int], b: list[int]) -> float:
    total = sum(abs(a[i] - b[i]) for i in range(TOILE))
    return total / (TOILE * TOILE)


def charger(dossier: Path) -> list[Vue]:
    vues: list[Vue] = []
    for manifeste in sorted(dossier.rglob("manifest_silhouettes_*.json")):
        meta = json.loads(manifeste.read_text(encoding="utf-8"))
        emprise = meta.get("emprise_m") or [0.0, 0.0, 0.0]
        hauteur = float(emprise[1])
        if hauteur <= 0.0:
            print(f"[répétition] IGNORÉ {manifeste} : emprise nulle",
                  file=sys.stderr)
            continue
        place_id = str(meta.get("place_id") or "").strip()
        sujet = str(meta.get("sujet") or manifeste.stem)
        if not place_id:
            # Un asset isolé (mode `--scene=...glb`) n'a pas de place_id : il
            # n'appartient à aucun des deux ensembles et ne peut ni calibrer
            # ni être jugé. On le dit plutôt que de le compter en douce.
            print(f"[répétition] IGNORÉ {sujet} : sans place_id (asset isolé)",
                  file=sys.stderr)
            continue
        for vue in meta.get("vues", []):
            chemin = Path(str(vue["image"]))
            if not chemin.is_absolute():
                chemin = Path.cwd() / chemin
            if not chemin.exists():
                chemin = manifeste.parent / Path(str(vue["image"])).name
            if not chemin.exists():
                print(f"[répétition] IGNORÉ {sujet} : image absente "
                      f"({vue['image']})", file=sys.stderr)
                continue
            vues.append(Vue(place_id, sujet, float(vue.get("angle_deg", 0.0)),
                            chemin, hauteur))
    return vues


def par_sujet(vues: list[Vue]) -> dict[str, list[Vue]]:
    groupes: dict[str, list[Vue]] = {}
    for v in vues:
        groupes.setdefault(v.place_id, []).append(v)
    return groupes


def similarite(a: list[Vue], b: list[Vue], distance_m: float) -> tuple[float, float]:
    """Similarité entre deux SUJETS : le maximum sur les couples d'angles.

    Le maximum, et non la moyenne : deux lieux qui se confondent sous un seul
    angle se confondent, et une moyenne diluerait exactement le cas qu'on
    cherche.
    """
    meilleur = 0.0
    profil_associe = 1.0
    for va in a:
        ma, pa = va.masque(distance_m)
        for vb in b:
            mb, pb = vb.masque(distance_m)
            valeur = iou(ma, mb)
            if valeur > meilleur:
                meilleur = valeur
                profil_associe = dprofil(pa, pb)
    return meilleur, profil_associe


def git(args: list[str], defaut: str = "") -> str:
    try:
        return subprocess.run(["git"] + args, capture_output=True, text=True,
                              check=False).stdout.strip() or defaut
    except OSError:
        return defaut


def autotest() -> int:
    """Cas témoin analytique : le détecteur doit voir une copie exacte.

    Deux masques identiques rendent 1,0 ; un masque et son complémentaire
    rendent 0,0. Si l'un des deux échoue, aucun chiffre produit par cet outil
    ne mérite d'être lu.
    """
    plein = [True] * (TOILE * TOILE)
    vide = [False] * (TOILE * TOILE)
    moitie = [i < (TOILE * TOILE) // 2 for i in range(TOILE * TOILE)]
    ok = True
    for nom, valeur, attendu in (
            ("identique", iou(plein, plein), 1.0),
            ("disjoint", iou(moitie, [not m for m in moitie]), 0.0),
            ("moitie", iou(plein, moitie), 0.5),
            ("vide", iou(vide, vide), 0.0)):
        marque = "OK " if abs(valeur - attendu) < 1e-9 else "ÉCHEC"
        if marque != "OK ":
            ok = False
        print(f"  [{marque}] {nom} : IoU = {valeur:.4f} (attendu {attendu:.4f})")
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifestes", type=Path,
                    help="dossier contenant les manifest_silhouettes_*.json")
    ap.add_argument("--out", type=Path,
                    default=Path("evidence/world_v2/v2_3_b/lot1/controles/"
                                 "verdict_repetition.json"))
    ap.add_argument("--autotest", action="store_true")
    args = ap.parse_args()

    if args.autotest:
        return autotest()
    if args.manifestes is None:
        ap.error("--manifestes est requis (ou --autotest)")

    vues = charger(args.manifestes)
    groupes = par_sujet(vues)
    acceptes = [p for p in CORPUS_ACCEPTE if p in groupes]
    nouveaux = [p for p in LOT1 if p in groupes]
    manquants = [p for p in LOT1 if p not in groupes]

    verdict: dict = {
        "regle": "R-D3",
        "source_regle": "docs/V2_3_B_LOT1_CONTROLES.md §3",
        "distances_m": list(DISTANCES_M),
        "fov_vertical_deg": FOV_VERTICAL_DEG,
        "toile_px": TOILE,
        "corpus_accepte": acceptes,
        "lot1_present": nouveaux,
        "lot1_manquant": manquants,
        "commit": git(["rev-parse", "HEAD"], "inconnu"),
        "repo_dirty": git(["status", "--porcelain"]) != "",
        "seuils": {},
        "temoin_degenere": {},
        "signalees": [],
        "matrice": {},
    }

    # --- R-D3c : le corpus doit pouvoir calibrer ----------------------------
    if len(acceptes) < CORPUS_MINIMUM:
        verdict["verdict"] = "BLOQUE"
        verdict["resume"] = (
            f"corpus accepté réduit à {len(acceptes)} sujet(s) ; R-D3c en exige "
            f"{CORPUS_MINIMUM}. Sous ce compte, max() n'est plus une "
            f"statistique mais un accident.")
        ecrire(args.out, verdict)
        print(verdict["resume"])
        return 3

    signalees: list[dict] = []
    for d in DISTANCES_M:
        # 1. CALIBRATION sur les paires ACCEPTÉES, et sur elles seules.
        seuil = 0.0
        pire_paire = ("", "")
        for i in range(len(acceptes)):
            for j in range(i + 1, len(acceptes)):
                valeur, _ = similarite(groupes[acceptes[i]],
                                       groupes[acceptes[j]], d)
                if valeur > seuil:
                    seuil = valeur
                    pire_paire = (acceptes[i], acceptes[j])
        verdict["seuils"][str(int(d))] = {
            "S": round(seuil, 4),
            "paire_calibrante": list(pire_paire),
            "paires_acceptees": len(acceptes) * (len(acceptes) - 1) // 2,
        }
        # R-D3b : une calibration trop haute n'est pas un seuil généreux,
        # c'est un instrument cassé.
        if seuil >= PLAFOND_CALIBRATION:
            verdict["verdict"] = "BLOQUE"
            verdict["resume"] = (
                f"calibration INVALIDE à {int(d)} m : S = {seuil:.4f} ≥ "
                f"{PLAFOND_CALIBRATION} entre deux sujets acceptés "
                f"({pire_paire[0]} / {pire_paire[1]}). R-D3b : c'est "
                f"l'instrument ou le cadrage qui est cassé, pas l'art.")
            ecrire(args.out, verdict)
            print(verdict["resume"])
            return 3

        # 2. LE TÉMOIN DÉGÉNÉRÉ : un sujet contre lui-même.
        masque_temoin = groupes[acceptes[0]][0].masque(d)[0]
        temoin = iou(masque_temoin, masque_temoin)
        vu = temoin > seuil
        verdict["temoin_degenere"][str(int(d))] = {
            "sujet": acceptes[0], "iou": round(temoin, 4), "signale": vu}
        if not vu:
            verdict["verdict"] = "BLOQUE"
            verdict["resume"] = (
                f"témoin dégénéré NON SIGNALÉ à {int(d)} m : "
                f"{acceptes[0]} comparé à lui-même rend {temoin:.4f} ≤ "
                f"S = {seuil:.4f}. Un détecteur qui ne voit pas une copie "
                f"exacte ne voit rien ; son verdict est jeté.")
            ecrire(args.out, verdict)
            print(verdict["resume"])
            return 3

        # 3. LE JUGEMENT : lot × lot, puis lot × corpus.
        lignes: list[dict] = []
        paires: list[tuple[str, str]] = []
        for i in range(len(nouveaux)):
            for j in range(i + 1, len(nouveaux)):
                paires.append((nouveaux[i], nouveaux[j]))
        for n in nouveaux:
            for a in acceptes:
                paires.append((n, a))
        for gauche, droite in paires:
            valeur, prof = similarite(groupes[gauche], groupes[droite], d)
            lignes.append({"a": gauche, "b": droite,
                           "iou": round(valeur, 4), "dprofil": round(prof, 4),
                           "signale": valeur > seuil})
            if valeur > seuil:
                signalees.append({"distance_m": d, "a": gauche, "b": droite,
                                  "iou": round(valeur, 4),
                                  "seuil": round(seuil, 4),
                                  "dprofil": round(prof, 4)})
        verdict["matrice"][str(int(d))] = lignes

    verdict["signalees"] = signalees
    if manquants:
        verdict["verdict"] = "BLOQUE"
        verdict["resume"] = (
            "silhouettes absentes pour " + ", ".join(manquants) +
            " — un détecteur qui ne voit pas un sujet ne peut pas le "
            "déclarer distinct.")
        code = 3
    elif signalees:
        verdict["verdict"] = "FAIL"
        verdict["resume"] = "; ".join(
            f"{s['a']} ≈ {s['b']} à {int(s['distance_m'])} m "
            f"(IoU {s['iou']:.3f} > S {s['seuil']:.3f})" for s in signalees[:5])
        code = 1
    else:
        verdict["verdict"] = "PASS"
        verdict["resume"] = (
            f"{len(nouveaux)} sujet(s) du lot, aucun ne dépasse le seuil "
            "calibré sur le corpus accepté (" + ", ".join(
                f"{k} m : S = {v['S']:.3f}"
                for k, v in verdict["seuils"].items()) + ")")
        code = 0

    ecrire(args.out, verdict)
    rendre(verdict)
    return code


def ecrire(chemin: Path, verdict: dict) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text(json.dumps(verdict, indent=2, ensure_ascii=False),
                      encoding="utf-8")


def rendre(verdict: dict) -> None:
    print(f"règle {verdict['regle']} — {verdict['source_regle']}")
    print(f"commit {verdict['commit'][:12]} · dirty={verdict['repo_dirty']}")
    for d, info in verdict["seuils"].items():
        print(f"\n--- {d} m — seuil S = {info['S']:.4f} "
              f"(calibré sur {info['paires_acceptees']} paires acceptées, "
              f"paire calibrante : {' / '.join(info['paire_calibrante'])}) ---")
        print(f"{'a':38s} {'b':38s} {'IoU':>7s} {'dprofil':>8s}")
        for ligne in sorted(verdict["matrice"][d],
                            key=lambda r: -r["iou"]):
            marque = "  <== SIGNALÉ" if ligne["signale"] else ""
            print(f"{ligne['a']:38s} {ligne['b']:38s} "
                  f"{ligne['iou']:7.4f} {ligne['dprofil']:8.4f}{marque}")
    print(f"\nVERDICT : {verdict['verdict']} — {verdict['resume']}")


if __name__ == "__main__":
    sys.exit(main())
