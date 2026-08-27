#!/usr/bin/env python3
"""VERDICT — la seule logique de code de sortie du dépôt.

POURQUOI CE MODULE EXISTE, ET POURQUOI IL EST PARTAGÉ.

Trois harnais portaient chacun leur copie de la même ligne :

    echecs = [c for c in constats if c["verdict"] == "FAIL"]
    return 1 if echecs else 0

Un `PARTIAL` retombait dans le `else 0`. La checklist de la build publiée
contenait 16 `PASS` et un `PARTIAL` sur « saut puis retour au sol », rendait
RC=0, imprimait « 17 points observés, 0 FAIL », et ce résumé a été relayé en
« 17/17 » — ce qui affirme 17 réussites. Le produit n'a jamais menti ;
l'appareil et son compte rendu, si.

Corrigé une première fois dans UN seul harnais. Les deux autres portaient
encore le défaut trois jours plus tard. C'est exactement la leçon déjà écrite
dans `tools/CLAUDE.md` : *quand un défaut de mesure est trouvé dans un outil,
chercher tout de suite les AUTRES endroits qui font la même mesure.* D'où ce
module, et la règle de trois de `PROMPT4_METHOD` §8 : au troisième exemplaire,
on extrait.

LES TROIS FAÇONS DE DEVENIR VERT SANS RIEN PROUVER, toutes fermées ici :

1. **par omission de gravité** — un `PARTIAL` compté comme rien. Fermé par
   `CODES` : tout verdict autre que `PASS` rend un code non nul.
2. **par le vide** — zéro constat, donc zéro échec, donc vert. Fermé par
   `code_sortie` : une liste vide rend **3**. C'est la même famille que le
   `diff` sur deux fichiers absents qui rend 0, déjà consigné.
3. **par point manquant** — le harnais n'exécute jamais le contrôle qui
   fâche, et rend vert sur les autres. Fermé par `exiger()` : chaque harnais
   déclare ses points OBLIGATOIRES ; un point absent devient un constat
   `NON VÉRIFIÉ` synthétique, donc code 3.

`BLOQUÉ` et `NON VÉRIFIÉ` gardent un code **distinct (3)** : « je n'ai pas pu
mesurer » n'est pas « ça rate », et confondre les deux fait chercher un défaut
du produit là où il n'y a qu'un environnement absent.
"""
from __future__ import annotations

CODES: dict[str, int] = {
    "PASS": 0,
    "PARTIAL": 1,
    "FAIL": 1,
    "NON VÉRIFIÉ": 3,
    "BLOQUÉ": 3,
}

#: Ordre de gravité croissante, pour choisir le pire verdict d'un lot.
GRAVITE: list[str] = ["PASS", "PARTIAL", "FAIL", "NON VÉRIFIÉ", "BLOQUÉ"]


def note(constats: list[dict], cle: str, verdict: str, mesure: str,
         muet: bool = False) -> None:
    """Ajoute un constat et l'imprime. `verdict` doit être une clé de CODES ;
    un verdict inconnu n'est PAS rejeté ici — il est conservé tel quel et
    `code_sortie` le fera bloquer. Rejeter au moment de l'écriture masquerait
    l'erreur au lieu de la publier."""
    constats.append({"point": cle, "verdict": verdict, "mesure": mesure})
    if not muet:
        print(f"[{verdict:12s}] {cle} — {mesure}", flush=True)


def exiger(constats: list[dict], obligatoires: dict[str, str],
           muet: bool = False) -> int:
    """Vérifie que chaque point OBLIGATOIRE a bien été observé.

    `obligatoires` : {libellé lisible -> motif cherché dans le champ `point`}.
    Chaque point absent produit un constat `NON VÉRIFIÉ` synthétique — donc un
    code 3. Rend le nombre de points manquants.

    C'est le garde-fou contre le vert obtenu **en ne faisant pas le contrôle
    qui fâche**. Un harnais qui saute la gravité ne peut plus rendre 0 : il
    rend 3, et il dit lequel de ses points manque."""
    vus = " || ".join(c.get("point", "") for c in constats)
    manquants = 0
    for libelle, motif in obligatoires.items():
        if motif not in vus:
            manquants += 1
            note(constats, f"point obligatoire absent : {libelle}",
                 "NON VÉRIFIÉ",
                 f"aucun constat ne porte le motif « {motif} » — le harnais "
                 f"n'a pas exécuté ce contrôle, il ne peut donc pas être vert",
                 muet=muet)
    return manquants


def code_sortie(constats: list[dict]) -> int:
    """0 = tout PASS · 1 = PARTIAL/FAIL · 3 = BLOQUÉ / NON VÉRIFIÉ / vide.

    **Une liste vide rend 3.** Un harnais qui n'a rien observé n'a rien prouvé,
    et « aucun échec » n'est pas « aucun défaut »."""
    if not constats:
        print("BLOQUÉ: aucun constat — un harnais qui n'observe rien ne "
              "prouve rien", flush=True)
        return 3
    verdicts = {c.get("verdict") for c in constats}
    inconnus = verdicts - set(CODES)
    if inconnus:
        print(f"BLOQUÉ: verdict(s) inconnu(s) : {sorted(map(str, inconnus))}",
              flush=True)
        return 3
    if "BLOQUÉ" in verdicts or "NON VÉRIFIÉ" in verdicts:
        return 3
    if "FAIL" in verdicts or "PARTIAL" in verdicts:
        return 1
    return 0


def pire(constats: list[dict]) -> str:
    """Le verdict le plus grave du lot — jamais leur moyenne (PROMPT4 §12)."""
    if not constats:
        return "BLOQUÉ"
    rang = -1
    for c in constats:
        v = c.get("verdict")
        rang = max(rang, GRAVITE.index(v) if v in GRAVITE else len(GRAVITE))
    return GRAVITE[rang] if rang < len(GRAVITE) else "BLOQUÉ"


def publier_verdict(constats: list[dict],
                    obligatoires: dict[str, str] | None = None) -> int:
    """Résumé qui compte CHAQUE classe de verdict, puis code de sortie.

    Jamais la formule « N points observés, 0 FAIL » : elle laisse croire à N
    réussites quand un `PARTIAL` se cache dedans. C'est cette phrase-là qui a
    produit le « 17/17 »."""
    if obligatoires:
        exiger(constats, obligatoires)
    code = code_sortie(constats)
    comptes = {v: sum(1 for c in constats if c.get("verdict") == v)
               for v in CODES}
    detail = " · ".join(f"{n} {v}" for v, n in comptes.items() if n)
    autres = sum(1 for c in constats if c.get("verdict") not in CODES)
    if autres:
        detail += f" · {autres} INCONNU"
    print(f"\n=== {len(constats)} point(s) observé(s) : "
          f"{detail or 'AUCUN'} — verdict {pire(constats)} — code {code} ===",
          flush=True)
    for c in constats:
        if c.get("verdict") != "PASS":
            print(f"    [{c.get('verdict')}] {c.get('point')} "
                  f":: {c.get('mesure')}", flush=True)
    return code


# --------------------------------------------------------------------------
def autotest() -> int:
    """Autotest du module, sabotages compris.

    Chaque cas nomme le PIÈGE qu'il ferme. Un cas qui ne rougirait pas sans le
    correctif ne serait pas un test (PROMPT4 §2)."""
    def lot(*verdicts: str) -> list[dict]:
        return [{"point": f"p{i}", "verdict": v, "mesure": "m"}
                for i, v in enumerate(verdicts)]

    cas: list[tuple[str, list[dict], int]] = [
        ("tout PASS", lot("PASS", "PASS", "PASS"), 0),
        ("UN SEUL PARTIAL parmi des PASS — LE FAUX VERT DE S1 : "
         "doit rendre un code NON NUL", lot("PASS", "PASS", "PARTIAL"), 1),
        ("un FAIL", lot("PASS", "FAIL"), 1),
        ("PARTIAL et FAIL mêlés", lot("PARTIAL", "FAIL"), 1),
        ("un BLOQUÉ prime sur un FAIL", lot("FAIL", "BLOQUÉ"), 3),
        ("un NON VÉRIFIÉ prime sur un PARTIAL",
         lot("PARTIAL", "NON VÉRIFIÉ"), 3),
        ("BLOQUÉ seul", lot("BLOQUÉ"), 3),
        ("SABOTAGE — liste VIDE : ne rien observer n'est pas réussir",
         [], 3),
        ("SABOTAGE — verdict inventé : ne doit pas retomber dans le vert",
         lot("PASS", "SUPER"), 3),
        ("SABOTAGE — verdict absent de la clé",
         [{"point": "p", "mesure": "m"}], 3),
        ("SABOTAGE — casse différente : « pass » n'est pas « PASS »",
         lot("pass"), 3),
    ]

    echecs = 0
    for titre, liste, attendu in cas:
        obtenu = code_sortie(liste)
        ok = obtenu == attendu
        echecs += 0 if ok else 1
        print(f"[{'OK  ' if ok else 'ÉCHEC'}] {titre} -> code {obtenu} "
              f"(attendu {attendu})", flush=True)

    # --- exiger() : le vert par point manquant ------------------------------
    print("\n--- exiger() : fermeture du vert PAR OMISSION ---", flush=True)
    OBLI = {"gravité": "saut", "menu": "menu"}

    complet = [{"point": "le saut puis retour au sol", "verdict": "PASS",
                "mesure": "m"},
               {"point": "menu principal", "verdict": "PASS", "mesure": "m"}]
    manque = [{"point": "menu principal", "verdict": "PASS", "mesure": "m"}]

    n = exiger(complet, OBLI, muet=True)
    ok = n == 0 and code_sortie(complet) == 0
    echecs += 0 if ok else 1
    print(f"[{'OK  ' if ok else 'ÉCHEC'}] tous les points obligatoires "
          f"présents -> 0 manquant, code 0 (obtenu {n}, "
          f"{code_sortie(complet)})", flush=True)

    n = exiger(manque, OBLI, muet=True)
    ok = n == 1 and code_sortie(manque) == 3
    echecs += 0 if ok else 1
    print(f"[{'OK  ' if ok else 'ÉCHEC'}] SABOTAGE — la gravité OMISE : "
          f"1 manquant et code 3, jamais 0 (obtenu {n}, "
          f"{code_sortie(manque)})", flush=True)

    vide: list[dict] = []
    n = exiger(vide, OBLI, muet=True)
    ok = n == 2 and code_sortie(vide) == 3
    echecs += 0 if ok else 1
    print(f"[{'OK  ' if ok else 'ÉCHEC'}] SABOTAGE — harnais totalement vide "
          f"-> 2 manquants et code 3 (obtenu {n}, {code_sortie(vide)})",
          flush=True)

    # --- pire() -------------------------------------------------------------
    for titre, liste, attendu in [
            ("pire() d'un lot tout PASS", lot("PASS", "PASS"), "PASS"),
            ("pire() PASS+PARTIAL", lot("PASS", "PARTIAL"), "PARTIAL"),
            ("pire() FAIL+BLOQUÉ", lot("FAIL", "BLOQUÉ"), "BLOQUÉ"),
            ("pire() d'un lot vide", [], "BLOQUÉ")]:
        obtenu = pire(liste)
        ok = obtenu == attendu
        echecs += 0 if ok else 1
        print(f"[{'OK  ' if ok else 'ÉCHEC'}] {titre} -> {obtenu} "
              f"(attendu {attendu})", flush=True)

    print(f"\n=== AUTOTEST verdict.py : {echecs} échec(s) ===", flush=True)
    return 1 if echecs else 0


if __name__ == "__main__":
    import sys
    sys.exit(autotest())
