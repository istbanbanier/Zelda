#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ISS-071 — la règle de normalisation des noms, en IMPLÉMENTATION DE RÉFÉRENCE,
et les sabotages nommés qui doivent la faire rougir.

POURQUOI CE FICHIER EXISTE
--------------------------
`tests/fixtures/iss071_noms.json` fige la règle attendue, cas par cas. Une table
de fixtures qu'aucun code n'exécute est une intention, pas un contrat : rien ne
garantit qu'elle soit cohérente, ni qu'un test qui la consomme rougirait
vraiment. Ce fichier l'exécute.

CE QU'IL PROUVE, ET CE QU'IL NE PROUVE PAS
------------------------------------------
IL PROUVE  : que la table est cohérente, et qu'une règle SABOTÉE est attrapée
             par elle — donc que le test GDScript qui la consommera aura de
             quoi rougir.
IL NE PROUVE PAS : que le code de production applique cette règle. Sur
             `cb8c5d7` il ne l'applique pas du tout — c'est le défaut. La
             vérification côté moteur appartient au test GDScript (agent B) et
             au portail d'export (`tools/gate_export_parite.sh`).

Codes : 0 = la règle demandée satisfait la table · 1 = écart(s) · 3 = BLOQUÉ.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

SUFFIXE_IMPORT = ".import"
EXTENSIONS = (".gltf", ".glb")


def base_sans_derniere_extension(nom: str) -> str:
    """Équivalent de `String.get_basename()` de Godot : retire la DERNIÈRE
    extension seulement. `A.B.glb` -> `A.B`, et surtout pas `A`."""
    point = nom.rfind(".")
    return nom if point <= 0 else nom[:point]


def normaliser(fichier: str, repertoire: str,
               sabotage: str = "") -> tuple[bool, str, str]:
    """Règle documentée dans `tests/fixtures/iss071_noms.json`.

    Rend (indexé, clé, chemin). `sabotage` injecte un défaut nommé : c'est le
    seul moyen de savoir si la table attrape quoi que ce soit. Un contrôle
    négatif qui ne rougit pas signale un contrôle aveugle, pas un code sain.
    """
    minuscule = fichier.lower()
    source = fichier

    # 1. retrait de « .import », INSENSIBLE À LA CASSE comme le test
    #    d'extension qui suit. Un `trim_suffix(".import")` brut est sensible à
    #    la casse : « Foo.GLB.IMPORT » serait alors rejeté pendant que son
    #    jumeau minuscule passe, et rien ne le crierait.
    if sabotage != "sans-import":
        if sabotage == "casse":
            if fichier.endswith(SUFFIXE_IMPORT):        # sensible à la casse
                source = fichier[: -len(SUFFIXE_IMPORT)]
                minuscule = source.lower()
        elif minuscule.endswith(SUFFIXE_IMPORT):
            source = fichier[: -len(SUFFIXE_IMPORT)]
            minuscule = minuscule[: -len(SUFFIXE_IMPORT)]

    # 2. test d'extension, APRÈS le retrait et jamais avant.
    acceptees = list(EXTENSIONS)
    if sabotage == "bin-accepte":
        acceptees.append(".bin")
    if sabotage == "tres-accepte":
        acceptees.append(".tres")
    if not any(minuscule.endswith(e) for e in acceptees):
        return False, "", ""

    # 3. clé canonique.
    if sabotage == "split-point":
        cle = source.split(".")[0]
    else:
        cle = base_sans_derniere_extension(source)

    # 4. chemin de la SOURCE, jamais celui du fichier de métadonnées.
    if sabotage == "chemin-import":
        chemin = f"{repertoire}/{fichier}"
    elif sabotage == "extension-remplacee":
        chemin = f"{repertoire}/{base_sans_derniere_extension(source)}.scn"
    else:
        chemin = f"{repertoire}/{source}"
    return True, cle, chemin


SABOTAGES: dict[str, str] = {
    "": "aucun — la règle documentée telle quelle",
    "sans-import": "le suffixe « .import » n'est plus retiré — c'est EXACTEMENT "
                   "le défaut d'ISS-071, reproduit à l'échelle de la règle",
    "chemin-import": "le chemin indexé devient celui du .import au lieu de la "
                     "source — I2 rougit, et load() échouerait",
    "extension-remplacee": "faux chemin source reconstruit : l'extension est "
                           "remplacée par .scn — le chemin n'existe pas",
    "bin-accepte": "les fichiers .bin sont indexés — doublon de clé avec le "
                   "modèle qu'ils accompagnent",
    "tres-accepte": "les .tres.import sont indexés — l'index gonfle de "
                    "centaines d'entrées qui ne sont pas des modèles",
    "split-point": "la clé est prise par split('.')[0] — « A.B.glb » devient "
                   "« A » et n'est plus résoluble",
    "casse": "le retrait de « .import » redevient sensible à la casse — "
             "« Foo.GLB.IMPORT » est rejeté sans un mot",
}


def verifier(table: Path, sabotage: str) -> int:
    if not table.exists() or table.stat().st_size == 0:
        print(f"BLOQUÉ : table de fixtures absente ou vide : {table}",
              file=sys.stderr)
        return 3
    data = json.loads(table.read_text(encoding="utf-8"))
    cas = data.get("cas", [])
    repertoire = data.get("repertoire_exemple", "res://x")
    if not cas:
        print("BLOQUÉ : la table ne contient aucun cas", file=sys.stderr)
        return 3

    ecarts: list[str] = []
    for c in cas:
        indexe, cle, chemin = normaliser(c["entree"], repertoire, sabotage)
        att = (bool(c["indexe"]), c["cle_attendue"], c["chemin_source_attendu"])
        obt = (indexe, cle if indexe else "", chemin if indexe else "")
        if obt != att:
            ecarts.append(f"{c['entree']:24s} attendu {att} · obtenu {obt}")

    # Le même contrôle sur les listages de répertoire : c'est I1/I2 à l'échelle
    # d'un test unitaire — deux environnements, un seul index attendu.
    for ex in data.get("repertoires_exemples", []):
        rep = ex["repertoire"]
        for cle_listage in ("listage_editeur", "listage_export"):
            index: dict[str, str] = {}
            collisions: list[str] = []
            for fichier in ex[cle_listage]:
                ok, k, p = normaliser(fichier, rep, sabotage)
                if not ok:
                    continue
                if k in index and index[k] != p:
                    collisions.append(f"{k}: {index[k]} vs {p}")
                index.setdefault(k, p)
            if index != ex["index_attendu"]:
                ecarts.append(
                    f"{cle_listage:16s} index obtenu {index} · "
                    f"attendu {ex['index_attendu']}")
            if collisions != ex.get("collisions_attendues", []):
                ecarts.append(
                    f"{cle_listage:16s} collisions {collisions} · "
                    f"attendu {ex.get('collisions_attendues', [])}")

    n_listages = sum(len(e[k]) for e in data.get("repertoires_exemples", [])
                     for k in ("listage_editeur", "listage_export"))
    etiquette = sabotage or "(règle documentée, sans sabotage)"
    print(f"table   : {table}")
    print(f"sabotage: {etiquette} — {SABOTAGES.get(sabotage, 'inconnu')}")
    print(f"examiné : {len(cas)} cas nommés + {n_listages} entrées de listage "
          f"réparties sur {len(data.get('repertoires_exemples', []))} "
          "répertoire(s)")
    print(f"écarts  : {len(ecarts)}")
    for e in ecarts:
        print(f"    - {e}")
    return 1 if ecarts else 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--table", type=Path,
                   default=Path(__file__).resolve().parents[1]
                   / "tests/fixtures/iss071_noms.json")
    p.add_argument("--saboter", default="", choices=sorted(SABOTAGES),
                   help="injecte un défaut nommé dans la règle de référence")
    p.add_argument("--lister-sabotages", action="store_true")
    a = p.parse_args(argv)
    if a.lister_sabotages:
        for nom, desc in SABOTAGES.items():
            print(f"{nom or '(aucun)':22s} {desc}")
        return 0
    return verifier(a.table, a.saboter)


if __name__ == "__main__":
    sys.exit(main())
