#!/usr/bin/env python3
"""SOCLE CHIFFRÉ — les nombres de l'audit, mesurés à la main, hors agents.

POURQUOI CET OUTIL EXISTE. Un audit conduit par des sous-agents produit des
chiffres que personne n'a vérifiés. Ce script mesure INDÉPENDAMMENT les
grandeurs structurantes, pour que les rapports puissent être confrontés à une
base qu'ils n'ont pas écrite. C'est l'application de la règle du dépôt :
un verdict doit publier la TAILLE de ce qu'il a examiné.

Il ne lance ni Godot ni Blender. Il lit le dépôt et l'historique git.
"""
from __future__ import annotations

import json
import pathlib
import re
import subprocess

SORTIE = "evidence/world_v2/audit_jeu_long/mesures_independantes.md"
# Premier commit du chantier World V2, ancre stable de l'historique.
ANCRE_V2 = "62ef876"
LIEUX = ["riverside_village", "abandoned_farm", "stone_bridge",
         "waterfall_cave", "thunderstruck_tree", "ember_raider",
         "conductive_basin", "watchtower_ruin", "overlook_summit",
         "turquoise_spring", "forest_shrine", "barrow_cemetery",
         "flower_field"]


def sh(c: str) -> str:
    return subprocess.run(c, shell=True, capture_output=True,
                          text=True).stdout.strip()


def main() -> int:
    d = json.loads(pathlib.Path(
        "resources/world_v2/world_v2_layout.json").read_text(encoding="utf-8"))
    src = pathlib.Path(
        "scripts/world_v2/poi/world_v2_places_builder.gd").read_text(
            encoding="utf-8")
    bloc = src[src.index("const REGISTRY"):]
    bloc = bloc[:bloc.index("\n}")]
    montes = set(re.findall(r'&"([^"]+)"', bloc))
    pois = {p["id"] for p in d["pois"]}
    sites = {p["id"] for p in d["systemic_sites"]}
    declares = pois | sites
    reste = sorted(declares - montes)

    # État de l'arbre EN EXCLUANT le fichier qu'on est en train d'écrire :
    # se déclarer sale à cause de sa propre sortie serait une fausse alerte.
    sale = [l for l in sh("git status --porcelain").splitlines()
            if SORTIE not in l]

    out: list[str] = []
    w = out.append
    w("# Mesures indépendantes — socle chiffré de l'audit\n")
    w("Produit par `tools/mesures_socle.py`. Prises **avant** de lire les")
    w("rapports des sous-agents, pour que ces rapports puissent être")
    w("confrontés à une base qu'ils n'ont pas écrite. Aucun chiffre de cette")
    w("page ne vient d'un agent.\n")
    w(f"Commit : `{sh('git rev-parse HEAD')[:7]}` · arbre "
      + ("**propre**" if not sale
         else f"**{len(sale)} fichier(s) modifié(s)** hors cette sortie")
      + "\n")

    b = d["bounds"]
    w("## Le monde\n")
    w("| Grandeur | Valeur |\n|---|---:|")
    w(f"| Étendue du terrain | {b['extent_m']} × {b['extent_m']} m |")
    w(f"| Rayon jouable max | {b['playable_radius_max_m']} m |")
    w(f"| Régions déclarées | {len(d['regions'])} |")
    w(f"| Lignes de vue | {len(d['sightlines'])} |")
    w(f"| Checkpoints | {len(d['checkpoints'])} |")
    w(f"| Espaces de donjon | {len(d['dungeon_spaces'])} |")
    w(f"| Étapes de progression | {len(d['progression'])} |")

    w("\n## Lieux : construits contre déclarés\n")
    w("| | Nombre |\n|---|---:|")
    w(f"| POI déclarés au layout | {len(pois)} |")
    w(f"| Sites systémiques déclarés | {len(sites)} |")
    w(f"| **Total déclaré** | **{len(declares)}** |")
    w(f"| Montés dans le REGISTRY | {len(montes)} |")
    w(f"| dont hors liste (camp, pylône) | {len(montes - declares)} |")
    w(f"| **Déclarés et NON construits** | **{len(reste)}** |")
    pct = 100 * len(montes & declares) // len(declares)
    w(f"\nAchèvement de la région 1 : **{pct} %** des sujets déclarés.\n")
    w("Non construits :\n")
    for r in reste:
        w(f"- `{r}`")

    w("\n## Coût de production mesuré\n")
    debut = sh("git log --reverse --format=%ad --date=short "
               "-- scripts/world_v2/ | head -1")
    fin = sh("git log -1 --format=%ad --date=short -- scripts/world_v2/")
    n = sh(f"git log --oneline {ANCRE_V2}..HEAD | wc -l")
    w(f"Chantier World V2 : **{debut} → {fin}**, **{n} commits** au total.\n")
    w("Commits touchant les fichiers de chaque lieu construit :\n")
    w("| Lieu | Commits |\n|---|---:|")
    vals: list[int] = []
    for p in LIEUX:
        v = int(sh(f'git log --oneline {ANCRE_V2}..HEAD -- "*{p}*" | wc -l'))
        vals.append(v)
        w(f"| {p} | {v} |")
    vals.sort()
    med = vals[len(vals) // 2]
    w(f"\nMédiane **{med} commits par lieu** ; minimum {vals[0]}, "
      f"maximum {vals[-1]}.\n")
    w("**Projection — c'est une ESTIMATION, pas une mesure.** Au rythme")
    w(f"observé, les **{len(reste)} lieux restants de la SEULE région 1**")
    w(f"représentent de l'ordre de **{med * len(reste)} commits**. Le chiffre")
    w("vaut pour l'ordre de grandeur, pas pour la décimale : il suppose que")
    w("les lieux restants coûtent comme les précédents, ce qui est faux dans")
    w("les deux sens — le pipeline s'est amélioré, mais les sujets faciles")
    w("ont été faits en premier.\n")

    w("## Code et tests\n")
    w("| Domaine | Fichiers `.gd` |\n|---|---:|")
    for dd in sorted(pathlib.Path("scripts").iterdir()):
        if dd.is_dir():
            w(f"| scripts/{dd.name} | {len(list(dd.rglob('*.gd')))} |")
    w("\n| Suite | Fichiers `.gd` |\n|---|---:|")
    for dd in sorted(pathlib.Path("tests").iterdir()):
        if dd.is_dir():
            w(f"| tests/{dd.name} | {len(list(dd.rglob('*.gd')))} |")
    w(f"\nScènes `.tscn` : **{len(list(pathlib.Path('scenes').rglob('*.tscn')))}**"
      f" · ressources `.tres` : "
      f"**{len(list(pathlib.Path('resources').rglob('*.tres')))}**")
    # --- SONDES CIBLEES : les systemes dont l'ABSENCE decide de 30-50 h ---
    # Un grep sur un mot-cle ment : « quest » matche `request`. On cherche des
    # CLASSES DECLAREES, qu'aucune sous-chaine ne peut fabriquer. La lecture se
    # fait en Python, PAS en shell : passer un motif a travers heredoc, chaine
    # Python, shell et grep a deja produit un motif vide qui declarait TOUT
    # absent — un faux negatif silencieux, exactement ce qu'on traque.
    #
    # SECOND PIEGE, mesure ici meme : un autoload n'a JAMAIS de `class_name`.
    # Son nom est deja un identifiant global et Godot refuse qu'une classe le
    # masque (l'en-tete de dev_mode.gd l'explique). Une sonde qui ne
    # regarderait que `class_name` declarerait `SaveSystem` ABSENT alors qu'il
    # est autoloade et porte `save_slot`/`load_slot`. Fausse accusation —
    # l'erreur symetrique du faux vert, et tout aussi grave.
    classes: set[str] = set()
    for gd in pathlib.Path("scripts").rglob("*.gd"):
        for m in re.finditer(r"^class_name\s+(\w+)", gd.read_text(
                encoding="utf-8", errors="replace"), re.M):
            classes.add(m.group(1))
    autoloads = [l.split("=")[0] for l in
                 pathlib.Path("project.godot").read_text(
                     encoding="utf-8").splitlines()
                 if re.match(r"^[A-Za-z_]+=\"?\*?res://", l)]

    w("\n## Sondes ciblees — presence d'un systeme, pas d'un mot\n")
    w(f"{len(classes)} `class_name` declares dans `scripts/`, "
      f"{len(autoloads)} autoloads.\n")
    w("| Systeme | `class_name` | Autoload | Verdict |")
    w("|---|---|---|---|")
    sondes = [
        ("Quetes",                 ["quest"],                    "quest"),
        ("Dialogues",              ["dialog"],                   "dialog"),
        ("PNJ",                    ["npc"],                      "npc"),
        ("New Game +",             ["newgame"],                  "newgame"),
        ("Streaming de region",    ["stream"],                   "stream"),
        ("Artisanat hors cuisine", ["craft"],                    "craft"),
        ("Marchand / economie",    ["shop", "merchant", "vendor"], "shop"),
        ("Meteo / cycle jour",     ["weather", "daynight"],      "weather"),
        ("Cuisine",                ["cook", "recipe", "meal"],   "cook"),
        ("Sauvegarde",             ["save"],                     "save"),
        ("Resonance / Bracelet",   ["resonance", "bracelet"],    "resonance"),
        ("Reaction materiaux",     ["reaction", "materialprofile"], "reaction"),
        ("Graphe electrique",      ["electric"],                 "electric"),
        ("Boss",                   ["boss"],                     "boss"),
        ("IA utilitaire",          ["utility", "perception", "behavior"], "perception"),
        ("Inventaire",             ["inventory", "equipment"],   "inventory"),
        ("Etat de jeu",            ["gamestate"],                "gamestate"),
    ]
    for nom, motifs, cle in sondes:
        trouve = sorted(c for c in classes
                        if any(m in c.lower() for m in motifs))
        auto = [a for a in autoloads if cle in a.lower()]
        present = bool(trouve) or bool(auto)
        w("| %s | %s | %s | %s |" % (
            nom,
            ("`%s`" % " ".join(trouve)) if trouve else "—",
            ("`%s`" % " ".join(auto)) if auto else "—",
            "present" if present else "**ABSENT**"))
    w("\nUne absence de classe ET d'autoload est un signal fort dans ce depot,")
    w("ou `CLAUDE.md` impose `class_name` pour tout type reutilisable. Elle ne")
    w("vaut pas preuve formelle : un sujet peut vivre sans type nomme.\n")

    chemin = pathlib.Path(SORTIE)
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"écrit -> {SORTIE}")
    print(f"  {len(declares)} sujets déclarés, {len(montes)} montés, "
          f"{len(reste)} restants ; médiane {med} commits/lieu")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
