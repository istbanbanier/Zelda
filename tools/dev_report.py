#!/usr/bin/env python3
"""Transforme une session enregistrée en rapport lisible, prêt à consigner.

Le mode développement du jeu (F3) écrit un dossier par session. Ce script le
lit et en tire un texte en français que l'on peut coller tel quel dans
`docs/KNOWN_ISSUES.md`, `docs/TEST_REPORT.md` ou un message.

Il ne juge rien et n'invente rien : il ordonne ce qui a été enregistré, met en
avant les moments signalés (F4) et les saccades, et dit franchement ce que le
journal ne contient pas.

Usage :
    python3 tools/dev_report.py <dossier_de_session> [> rapport.md]
    python3 tools/dev_report.py --dernier          # la session la plus récente
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

# Emplacement des sessions écrites par le jeu (`user://` de Godot sous Linux).
USER_ROOTS = [
    Path.home() / ".local/share/godot/app_userdata/Eclats d'Orage/dev_sessions",
    Path.home() / "Library/Application Support/Godot/app_userdata/Eclats d'Orage/dev_sessions",
    Path.home() / "AppData/Roaming/Godot/app_userdata/Eclats d'Orage/dev_sessions",
]


def latest_session() -> Path | None:
    candidates: list[Path] = []
    for root in USER_ROOTS:
        if root.is_dir():
            candidates.extend(p for p in root.iterdir() if p.is_dir())
    if not candidates:
        return None
    return max(candidates, key=lambda p: p.stat().st_mtime)


def load_events(folder: Path) -> list[dict]:
    journal = folder / "journal.jsonl"
    if not journal.is_file():
        raise SystemExit(f"Pas de journal dans {folder}")
    events: list[dict] = []
    for line in journal.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            # Une session interrompue par un plantage finit souvent sur une
            # ligne coupée. On la signale plutôt que d'échouer.
            events.append({"type": "ligne_illisible", "t": -1.0})
    return events


def horodatage(seconds: float) -> str:
    if seconds < 0:
        return "  ?  "
    return f"{int(seconds // 60):02d}:{seconds % 60:04.1f}"


def describe(event: dict) -> str:
    kind = event.get("type", "?")
    if kind == "marqueur":
        note = event.get("note") or "(rien écrit)"
        lieu = ""
        if "x" in event:
            lieu = f" — à ({event['x']:.0f}, {event['y']:.0f}, {event['z']:.0f})"
        etat = f", état « {event['etat']} »" if "etat" in event else ""
        return f"**PROBLÈME SIGNALÉ n°{event.get('numero', '?')}** : {note}{lieu}{etat}"
    if kind == "saccade":
        return f"image bloquée {event.get('ms', 0):.0f} ms"
    if kind == "message":
        return f"le jeu affiche : « {event.get('texte', '')} »"
    if kind == "scene":
        return f"changement de scène → {event.get('chemin', '?')}"
    if kind == "session":
        return f"session : {event.get('etat', '?')} {event.get('verdict', '')}".strip()
    if kind == "capture":
        return f"capture d'écran : {event.get('fichier', '?')}"
    if kind == "position":
        return ""      # trop fréquent pour la chronologie
    return kind


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    if sys.argv[1] in ("--dernier", "--latest"):
        folder = latest_session()
        if folder is None:
            raise SystemExit("Aucune session trouvée. Le mode dev a-t-il tourné ?")
    else:
        folder = Path(sys.argv[1])
    if not folder.is_dir():
        raise SystemExit(f"Dossier introuvable : {folder}")

    events = load_events(folder)
    environment: dict = {}
    env_file = folder / "environnement.json"
    if env_file.is_file():
        environment = json.loads(env_file.read_text(encoding="utf-8"))

    duration = max((e.get("t", 0.0) for e in events), default=0.0)
    markers = [e for e in events if e.get("type") == "marqueur"]
    hitches = [e for e in events if e.get("type") == "saccade"]
    positions = [e for e in events if e.get("type") == "position"]
    scenes = [e for e in events if e.get("type") == "scene"]

    out: list[str] = []
    out.append(f"# Session de jeu — {folder.name}")
    out.append("")
    out.append(f"- Durée : **{duration / 60.0:.1f} minute(s)**")
    out.append(f"- Événements : {len(events)}")
    out.append(f"- Problèmes signalés (F4) : **{len(markers)}**")
    out.append(f"- Saccades de plus de 100 ms : **{len(hitches)}**")
    if environment:
        out.append(f"- Moteur : {environment.get('moteur', '?')} · "
                   f"{environment.get('plateforme', '?')}")
        out.append(f"- Carte graphique : {environment.get('rendu', '?')}")
        taille = environment.get("fenetre", [])
        if taille:
            out.append(f"- Fenêtre : {taille[0]}×{taille[1]}")
    out.append("")

    if markers:
        out.append("## Ce que la personne a signalé")
        out.append("")
        for event in markers:
            out.append(f"- `{horodatage(event.get('t', 0.0))}` {describe(event)}")
        out.append("")
        out.append("Les captures correspondantes sont dans le même dossier, "
                   "nommées `marqueur_NN.png`.")
        out.append("")

    if hitches:
        worst = max(hitches, key=lambda e: e.get("ms", 0.0))
        out.append("## Fluidité")
        out.append("")
        out.append(f"- Pire image : **{worst.get('ms', 0):.0f} ms** "
                   f"à `{horodatage(worst.get('t', 0.0))}`")
        out.append(f"- Nombre de blocages : {len(hitches)}")
        out.append("")
        out.append("> Une mesure prise sur cette machine, avec cette carte "
                   "graphique et cette fenêtre. Elle ne vaut que pour elles.")
        out.append("")

    if scenes:
        out.append("## Parcours")
        out.append("")
        for event in scenes:
            out.append(f"- `{horodatage(event.get('t', 0.0))}` "
                       f"{event.get('chemin', '?')}")
        out.append("")

    out.append("## Chronologie")
    out.append("")
    written = 0
    for event in events:
        text = describe(event)
        if not text or event.get("type") == "position":
            continue
        out.append(f"- `{horodatage(event.get('t', 0.0))}` {text}")
        written += 1
        if written >= 200:
            out.append("- … (chronologie tronquée à 200 lignes ; "
                       "le journal complet reste dans `journal.jsonl`)")
            break
    out.append("")

    out.append("## Ce que ce rapport NE dit pas")
    out.append("")
    out.append("- Il ne dit pas si le jeu était agréable : aucun enregistrement "
               "ne mesure ça, seul un avis humain le peut.")
    out.append("- Les images par seconde relevées valent pour CETTE machine, "
               "pas pour un budget de performance.")
    if not markers:
        out.append("- Aucun problème n'a été signalé pendant la session "
                   "(touche F4). L'absence de signalement n'est pas une "
                   "absence de défaut.")
    if not positions:
        out.append("- Aucune position de héros n'a été échantillonnée : la "
                   "session s'est peut-être déroulée hors d'une scène jouable.")
    out.append("")

    print("\n".join(out))


if __name__ == "__main__":
    main()
