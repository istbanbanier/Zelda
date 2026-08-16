#!/usr/bin/env python3
"""Complete un manifeste de capture avec ce que les outils Godot n'ecrivent pas.

CE QUI MANQUE AUX OUTILS DU DEPOT, mesure sur leurs sorties reelles :

  `tools/godot/capture_poi_batch.gd`  ecrit scene, engine, renderer, adapter,
  size, commit, repo_dirty, provenance, shots[{name,image,from,look,fov}].
  `tools/godot/capture_silhouette.gd` ecrit en plus mode, place_id,
  projection, clip_below, emprise_m, vues[].

  AUCUN des deux n'ecrit :
    - le SHA256 du GLB reellement rendu — `provenance` donne le dernier
      COMMIT qui a touche le chemin, ce qui n'est pas une empreinte de
      contenu. Un GLB reexporte a l'identique et un GLB different partagent
      le meme commit tant qu'ils ne sont pas commites.
    - l'exposition de la scene.
    - la nature VERTICALE du champ `fov`.

Ces trois manques ont chacun une histoire dans ce depot :
  * l'empreinte : `tools/CLAUDE.md`, « exporter a la main apres une chaine
    interrompue rend l'ANCIEN maillage » — nom neuf, date neuve, octets
    identiques. Seule une empreinte de contenu tranche.
  * l'exposition : exigee au 12 de la directive R2a-3.5.2.
  * le FOV : `VISUAL_ASSET_BIBLE` 3.1 — avec KEEP_HEIGHT (defaut Godot),
    `Camera3D.fov` est le FOV VERTICAL. 68 saisi comme vertical donne une
    image beaucoup trop large. On inscrit donc les deux, nommes.

RIEN N'EST SAISI A LA MAIN. Tout est lu depuis git et le systeme de
fichiers. Un chemin absent rend une valeur explicitement inconnue, jamais
une valeur plausible.

Usage :
    python3 enrichir_manifeste.py --arbre <racine> --manifeste <in.json> \\
        --sortie <out.json> [--glb assets/environment/caves/SM_WaterfallCave.glb]

Code retour : 0 complete, 1 manifeste illisible, 3 BLOQUE (arbre sale, ou
empreinte impossible a etablir).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys

GLB_DEFAUT = "assets/environment/caves/SM_WaterfallCave.glb"
SCENE_MONDE = "scenes/world_v2/WorldV2.tscn"


def git(arbre: str, *args: str) -> str:
    try:
        out = subprocess.run(["git", "-C", arbre, *args],
                             capture_output=True, text=True, timeout=60)
    except Exception:
        return ""
    return out.stdout.strip() if out.returncode == 0 else ""


def sha256_fichier(chemin: str) -> str | None:
    if not os.path.isfile(chemin):
        return None
    h = hashlib.sha256()
    with open(chemin, "rb") as f:
        for bloc in iter(lambda: f.read(1 << 20), b""):
            h.update(bloc)
    return h.hexdigest()


def exposition_de_la_scene(arbre: str) -> dict:
    """Lit l'exposition dans la scene, plutot que de la declarer.

    Godot n'ecrit pas dans le .tscn les proprietes laissees au defaut :
    `tonemap_exposure` absent VEUT DIRE 1.0, et il faut le dire ainsi
    plutot que d'ecrire « inconnu » ou d'omettre le champ.
    """
    chemin = os.path.join(arbre, SCENE_MONDE)
    if not os.path.isfile(chemin):
        return {"source": SCENE_MONDE, "etat": "scene introuvable"}
    texte = open(chemin, encoding="utf-8").read()
    modes = {0: "LINEAR", 1: "REINHARD", 2: "FILMIC", 3: "ACES", 4: "AGX"}

    def lire(cle: str):
        m = re.search(r"^%s\s*=\s*([-\d.]+)" % re.escape(cle), texte, re.M)
        return float(m.group(1)) if m else None

    mode = lire("tonemap_mode")
    expo = lire("tonemap_exposure")
    blanc = lire("tonemap_white")
    ambiant = lire("ambient_light_energy")
    auto = re.search(r"^auto_exposure_enabled\s*=\s*true", texte, re.M) is not None
    return {
        "source": SCENE_MONDE,
        "tonemap_mode": modes.get(int(mode) if mode is not None else 0,
                                  "?%s" % mode),
        "tonemap_exposure": 1.0 if expo is None else expo,
        "tonemap_exposure_origine": "defaut Godot (absent du .tscn)"
                                    if expo is None else "declare",
        "tonemap_white": 1.0 if blanc is None else blanc,
        "ambient_light_energy": ambiant,
        "auto_exposure_enabled": auto,
        "note": "exposition FIXE : aucune auto-exposition, donc identique "
                "des deux cotes d'un A/B",
    }


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--arbre", required=True)
    p.add_argument("--manifeste", required=True)
    p.add_argument("--sortie", required=True)
    p.add_argument("--glb", default=GLB_DEFAUT)
    p.add_argument("--cote", default="", help="etiquette AVANT / APRES")
    p.add_argument("--tolerer-sale", action="store_true",
                   help="ESSAI UNIQUEMENT — jamais pour une preuve")
    a = p.parse_args()

    try:
        manif = json.load(open(a.manifeste, encoding="utf-8"))
    except Exception as exc:
        print("[enrichir] manifeste illisible : %s" % exc, file=sys.stderr)
        return 1

    # --- l'arbre doit etre propre, sinon la capture ne prouve rien -------
    porcelain = git(a.arbre, "status", "--porcelain", "--untracked-files=no")
    sales = [l for l in porcelain.splitlines()
             if l.strip() and not l[2:].strip().startswith("evidence/")]
    if sales and not a.tolerer_sale:
        print("[enrichir] BLOQUE : arbre SALE, %d fichier(s) hors evidence/. "
              "Une capture d'arbre sale ne prouve rien "
              "(.claude/rules/evidence.md)." % len(sales), file=sys.stderr)
        for l in sales[:10]:
            print("[enrichir]   %s" % l, file=sys.stderr)
        return 3

    glb_abs = os.path.join(a.arbre, a.glb)
    empreinte = sha256_fichier(glb_abs)
    if empreinte is None:
        print("[enrichir] BLOQUE : GLB introuvable — %s" % glb_abs,
              file=sys.stderr)
        return 3

    manif["preuve"] = {
        "cote": a.cote or "non etiquete",
        "arbre_de_capture": os.path.abspath(a.arbre),
        "sha_code": git(a.arbre, "rev-parse", "HEAD") or "inconnu",
        "sha_code_court": git(a.arbre, "rev-parse", "--short", "HEAD") or "inconnu",
        "branche": git(a.arbre, "rev-parse", "--abbrev-ref", "HEAD") or "inconnu",
        "repo_dirty": bool(sales),
        "geometrie": {
            "chemin": a.glb,
            "sha256": empreinte,
            "sha256_court": empreinte[:16],
            "octets": os.path.getsize(glb_abs),
            "dernier_commit_du_chemin":
                git(a.arbre, "log", "-1", "--format=%H", "--", a.glb) or "inconnu",
        },
        "exposition": exposition_de_la_scene(a.arbre),
        "fov": {
            "convention": "Camera3D.keep_aspect = KEEP_HEIGHT (defaut Godot)",
            "champ_fov_signifie": "FOV VERTICAL en degres",
            "piege": "VISUAL_ASSET_BIBLE 3.1 — un FOV horizontal de 68 deg "
                     "vaut ~41,6 deg vertical en 16:9. Ne jamais saisir 68 "
                     "comme fov.",
        },
        "environnement": {
            "gpu": "ABSENT — rendu logiciel Mesa llvmpipe sous Xvfb",
            "interdit": "aucune mesure de performance ne peut sortir de ces "
                        "images (CLAUDE.md, limites de l'environnement)",
        },
    }

    # FOV horizontal equivalent, ajoute a chaque plan sans toucher `fov`.
    import math
    for cle in ("shots", "vues"):
        for plan in manif.get(cle, []) or []:
            if isinstance(plan, dict) and "fov" in plan:
                v = float(plan["fov"])
                plan["fov_vertical_deg"] = v
                plan["fov_horizontal_16_9_deg"] = round(math.degrees(
                    2.0 * math.atan(math.tan(math.radians(v) / 2.0)
                                    * 16.0 / 9.0)), 2)

    os.makedirs(os.path.dirname(os.path.abspath(a.sortie)) or ".", exist_ok=True)
    with open(a.sortie, "w", encoding="utf-8") as f:
        json.dump(manif, f, ensure_ascii=False, indent=2, sort_keys=True)
    print("[enrichir] %s" % a.sortie)
    print("[enrichir] cote=%s  code=%s  glb=%s  dirty=%s"
          % (a.cote or "-", manif["preuve"]["sha_code_court"],
             empreinte[:16], manif["preuve"]["repo_dirty"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
