# -*- coding: utf-8 -*-
"""ISS-075 — CLASSER LES LITTÉRAUX PAR RÔLE SYNTAXIQUE, PAS PAR FORME.

POURQUOI CE FICHIER EXISTE, ET CE QU'IL REMPLACE.

`tools/inventaire_textes_joueur.py` décide par la FORME : un littéral compte
comme texte joueur s'il porte un caractère de sa constante `ACC`. Sur
`scripts/ui/gameplay_shell.gd`, il en annonce 39 ; il y en a 78. Les 39 manqués
ne sont pas des cas tordus, ce sont les plus ordinaires : « INVENTAIRE »,
« Commandes », « Mains nues », « Surcharge », « Silence » — du français sans
accent.

ALLONGER `ACC` NE PEUT PAS MARCHER, et c'est démontrable plutôt qu'opinable :
« Cuisiner », « Surcharge », « Silence » sont typographiquement IDENTIQUES à
« Plate », « Title », « Detail » — mêmes lettres ASCII, même casse, même
longueur. Les premiers vont à l'écran, les seconds sont des noms de nœuds.
Aucune règle portant sur les caractères ne peut les séparer, parce que
l'information qui les sépare n'est pas dans la chaîne : elle est dans ce que le
code EN FAIT.

Ce script décide donc sur le RÔLE SYNTAXIQUE : à quoi le littéral est-il
affecté, passé, ou retourné. Chaque littéral sort avec le NOM de la règle qui
l'a classé, pour qu'un désaccord porte sur une règle nommée et non sur une
intuition.

QUATRE CLASSES, et la troisième est celle qui compte :

  J_JOUEUR      le joueur le lit ; il doit passer par une clé.
  N_NON_JOUEUR  identifiant, chemin, clé de dictionnaire, message développeur.
  C_HORS_TRANCHE texte joueur, mais sur un chemin PAR FRAME : le traduire y
                appellerait `Textes.t()` soixante fois par seconde. Hors de
                cette passe À DESSEIN, pas par oubli.
  A_ARBITRER    aucune règle ne tranche. NE PAS ranger dans le camp qui
                arrange : un littéral non classé est un littéral non classé.

La classe `A_ARBITRER` est le seul garde-fou contre le mode de panne de
l'outil précédent — qui, lui, rangeait silencieusement tout ce qu'il ne
reconnaissait pas du côté « pas du texte joueur ».
"""
import io, os, re, sys, json, collections

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# --------------------------------------------------------------------------
# Extraction
# --------------------------------------------------------------------------
# Littéral double-quote, échappements compris. `&"…"` est capté aussi : le
# préfixe est relu ensuite, il porte la règle N-STRINGNAME.
LIT = re.compile(r'"([^"\\]*(?:\\.[^"\\]*)*)"')
LETTRE = re.compile(r"[A-Za-zÀ-ÿ]")

FUNC = re.compile(r"^(\s*)(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)")
CONST_DICT = re.compile(r"^const\s+([A-Z_][A-Z0-9_]*)\s*:\s*Dictionary")
APPEL = re.compile(r"\b(_[A-Za-z0-9_]+|[a-z][A-Za-z0-9_]*)\s*\(")

# `.text =` mais pas `.text ==` / `!=` / `>=` / `<=`
AFFECT_TEXT = re.compile(r"\.text\s*=(?!=)")

DIAG = re.compile(r"push_error|push_warning|printerr|\bprint\b|printt|assert\(")
THEME = re.compile(r"add_theme_[a-z_]*override\s*\(\s*$")
NOM_NOEUD = re.compile(r"\.name\s*=(?!=)\s*$")

# Les portes d'API dont l'argument est un IDENTIFIANT, jamais une phrase.
IDENT_API = re.compile(
    r"\b(?:get_node|get_node_or_null|has_node|find_child|find_children|"
    r"get_nodes_in_group|add_to_group|remove_from_group|is_in_group|"
    r"connect|disconnect|is_connected|emit_signal|has_signal|has_method|"
    r"call|call_deferred|callv|is_action_pressed|is_action_just_pressed|"
    r"is_action_just_released|get_action_strength|load|preload|"
    r"add_theme_[a-z_]*override|get_theme_[a-z_]*|set_meta|get_meta|has_meta|"
    r"instantiate|new|split|join|begins_with|ends_with|contains|find|"
    r"trim_prefix|trim_suffix|get_basename|path_join|has)\s*\(\s*$")

# `.get("cle"` / `.has("cle"` / `.erase("cle"` — clé de dictionnaire.
CLE_DICT = re.compile(r"\.\s*(?:get|has|erase|get_or_add)\s*\(\s*$")

# `find_children("*", "StormGuardian", …)` : le 2e argument NOMME UNE CLASSE.
# Règle séparée parce qu'elle porte sur un argument qui n'est pas le premier —
# la confondre avec N-API-IDENT reviendrait à absoudre tout argument de tout
# appel, ce qui laisserait passer `notify(...)`.
CLASSE_RECHERCHEE = re.compile(r"\b(?:find_child|find_children)\s*\([^()]*,\s*$")

# `for x: String in ["A", "B"]:` dont `x` sert ensuite à retrouver un nœud.
BOUCLE_LISTE = re.compile(r"^\s*for\s+([A-Za-z_][A-Za-z0-9_]*)\s*:[^=]*\bin\s*\[")


def lignes(chemin):
    return io.open(chemin, encoding="utf-8").read().split("\n")


# --------------------------------------------------------------------------
# Graphe d'appel — DÉRIVÉ du fichier, pas déclaré à la main
# --------------------------------------------------------------------------
# Le but est unique : savoir ce qui court PAR FRAME. Une liste écrite à la main
# se périme en silence dès qu'un appel bouge ; une clôture calculée non.
def analyser(src):
    """-> (corps, appels, affiche) indexés par nom de fonction."""
    corps = collections.defaultdict(list)      # func -> [(no_ligne, texte)]
    appels = collections.defaultdict(set)      # func -> {func appelée}
    courant = None
    for i, l in enumerate(src, 1):
        m = FUNC.match(l)
        if m:
            courant = m.group(2)
            appels.setdefault(courant, set())
            continue
        if l and not l[0].isspace():           # retour au niveau module
            courant = None
        if courant is None:
            continue
        corps[courant].append((i, l))
        nu = l.strip()
        if nu.startswith("#"):
            continue
        for nom in APPEL.findall(l):
            appels[courant].add(nom)

    # Une fonction AFFICHE si elle écrit un `.text`, ou si elle passe par une
    # porte d'affichage. Point fixe : une fonction qui n'appelle que des
    # fonctions d'affichage affiche aussi.
    PORTES = {"_announce_resonance", "_on_notification", "notify", "_set_label"}
    affiche = set()
    for f, lg in corps.items():
        for _, l in lg:
            if l.strip().startswith("#"):
                continue
            if AFFECT_TEXT.search(l):
                affiche.add(f)
                break
    for f, cs in appels.items():
        if cs & PORTES:
            affiche.add(f)
    # Une fonction dont le RÉSULTAT est écrit dans un `.text` (directement ou
    # via `_set_label`) affiche également : c'est le cas de
    # `_resonance_action_line`, dont les `return "…"` finissent sur un Label.
    texte_complet = "\n".join(src)
    for f in list(appels.keys()):
        for motif in (r"\.text\s*=(?!=)[^\n]*\b%s\s*\(" % re.escape(f),
                      r"_set_label\s*\([\s\S]{0,160}?\b%s\s*\(" % re.escape(f)):
            if re.search(motif, texte_complet):
                affiche.add(f)
                break
    # Appelée PAR une fonction d'affichage, et rendant un littéral : son
    # résultat traverse une variable locale avant le Label (`_effect_display_name`).
    # Bornée aux fonctions qui portent réellement un `return "…"`, sinon la
    # règle absoudrait tout accesseur appelé depuis le HUD.
    rend_litteral = {f for f, lg in corps.items()
                     if any(re.match(r"\s*return\s+\"", l) for _, l in lg)}
    for f, cs in appels.items():
        if f in affiche:
            affiche |= (cs & rend_litteral)
    for _ in range(6):                          # point fixe, borné
        avant = len(affiche)
        for f, cs in appels.items():
            if cs & affiche:
                affiche.add(f)
        if len(affiche) == avant:
            break
    # Les VARIABLES LOCALES qui finissent écrites dans un `.text`. Sans elles,
    # tout texte construit par accumulation (`line += "…"`) reste non classé :
    # c'est le cas de tout l'aperçu de cuisine. Le flux reste INTRA-fonction,
    # donc borné et relisible ; aucune tentative de suivre une valeur entre
    # fonctions, qui demanderait un vrai flot de données.
    vers_texte = collections.defaultdict(set)
    for f, lg in corps.items():
        for _, l in lg:
            m2 = re.search(r"\.text\s*=(?!=)\s*([A-Za-z_][A-Za-z0-9_]*)\s*$", l)
            if m2:
                vers_texte[f].add(m2.group(1))
            # Une locale RENDUE par une fonction d'affichage sort à l'écran
            # aussi sûrement qu'un `.text` : `action` dans
            # `_resonance_action_line` n'est jamais écrit dans un Label ici,
            # il est retourné — et `_set_label` l'écrit une ligne plus loin.
            if f in affiche:
                m3 = re.search(r"^\s*return\s+[^\n]*?\b([A-Za-z_][A-Za-z0-9_]*)\s*$", l)
                if m3:
                    vers_texte[f].add(m3.group(1))
    return corps, appels, affiche, vers_texte


def clore(appels, racines):
    """Fermeture transitive des appels depuis `racines`."""
    vus, pile = set(), list(racines)
    while pile:
        f = pile.pop()
        if f in vus:
            continue
        vus.add(f)
        pile.extend(appels.get(f, ()))
    return vus


# --------------------------------------------------------------------------
# La règle qui tranche
# --------------------------------------------------------------------------
def classer(ligne, avant, texte, en_const, const_affichee, dans_func,
            func_affiche, par_frame, idents_boucle, accumulateurs):
    """-> (classe, regle). `avant` est le préfixe de la ligne AVANT le
    littéral : c'est lui qui porte le rôle syntaxique."""
    nu = ligne.strip()

    # --- identifiants et chemins : indiscutables, testés en premier ---
    if avant.rstrip().endswith("&"):
        return "N_NON_JOUEUR", "N-STRINGNAME"
    if texte.startswith("res://") or texte.startswith("user://"):
        return "N_NON_JOUEUR", "N-CHEMIN"
    if DIAG.search(ligne):
        return "N_NON_JOUEUR", "N-DIAG"
    if THEME.search(avant):
        return "N_NON_JOUEUR", "N-THEME"
    if NOM_NOEUD.search(avant):
        return "N_NON_JOUEUR", "N-NOM-NOEUD"
    if CLE_DICT.search(avant):
        return "N_NON_JOUEUR", "N-CLE-DICT"
    if IDENT_API.search(avant):
        return "N_NON_JOUEUR", "N-API-IDENT"
    if CLASSE_RECHERCHEE.search(avant):
        return "N_NON_JOUEUR", "N-CLASSE"
    if texte in idents_boucle:
        return "N_NON_JOUEUR", "N-IDENT-BOUCLE"
    # `match x:` puis `"attack":` — une étiquette de branche, pas une phrase.
    # Distinguée d'une entrée de dictionnaire par l'absence de bloc `const`.
    if en_const is None and re.match(r'^"[^"]*"\s*:\s*$', nu):
        return "N_NON_JOUEUR", "N-CASSE"
    if texte == "":
        return "N_NON_JOUEUR", "N-VIDE"
    if not LETTRE.search(texte):
        # « %s%s\n%d/%d », « ❖ », « — », « , » : aucun mot, donc rien à traduire.
        return "N_NON_JOUEUR", "N-GABARIT"

    # --- portes d'affichage ---
    porte = None
    if AFFECT_TEXT.search(avant):
        porte = "J-TEXT"
    elif re.search(r"(?:_on_notification\s*\(|\"notify\"\s*,)\s*$", avant):
        porte = "J-NOTIFY"
    elif re.search(r"_announce_resonance\s*\(\s*$", avant):
        porte = "J-ANNONCE"
    elif en_const and const_affichee and re.search(r":\s*$", avant):
        porte = "J-TABLE"
    elif nu.startswith("return ") and dans_func in func_affiche:
        porte = "J-RETOUR"
    else:
        ma = re.search(r"(?:var\s+)?\b([A-Za-z_][A-Za-z0-9_]*)\s*"
                       r"(?::\s*[A-Za-z_][A-Za-z0-9_]*\s*)?\+?=\s*$", avant)
        if ma and ma.group(1) in accumulateurs:
            porte = "J-ACCUM"

    if porte is None:
        if len(texte) < 3:
            return "A_ARBITRER", "A-COURT"
        return "A_ARBITRER", "A-SANS-ROLE"

    if (dans_func in par_frame) or (en_const and en_const in par_frame):
        return "C_HORS_TRANCHE", porte + "/PAR-FRAME"
    return "J_JOUEUR", porte


def inventorier(chemin, racines_par_frame):
    src = lignes(chemin)
    corps, appels, affiche, vers_texte = analyser(src)
    par_frame = clore(appels, racines_par_frame)

    # Une table `const` est « affichée » si elle est INDEXÉE depuis une
    # fonction d'affichage ; elle est « par frame » si elle l'est depuis une
    # fonction qui court par frame. Dérivé, jamais déclaré.
    tables_affichees, tables_par_frame = set(), set()
    for f, lg in corps.items():
        for _, l in lg:
            for nom in re.findall(r"\b([A-Z][A-Z0-9_]{2,})\s*[\[.]", l):
                if f in affiche:
                    tables_affichees.add(nom)
                if f in par_frame:
                    tables_par_frame.add(nom)

    # Littéraux d'une liste de boucle dont la variable sert à retrouver un
    # nœud : `for panel_name in ["PausePanel", …]` puis `get_node("%" + panel_name)`.
    idents_boucle = set()
    for f, lg in corps.items():
        texte_f = "\n".join(l for _, l in lg)
        for _, l in lg:
            mb = BOUCLE_LISTE.match(l)
            if mb and re.search(r"(?:get_node|get_node_or_null|has_node|find_child)"
                                r"[^\n]*\b%s\b" % re.escape(mb.group(1)), texte_f):
                idents_boucle |= set(LIT.findall(l))

    out, en_const, dans_func = [], None, None
    for i, l in enumerate(src, 1):
        m = FUNC.match(l)
        if m:
            dans_func = m.group(2)
        elif l and not l[0].isspace():
            dans_func = None
        mc = CONST_DICT.match(l)
        if mc:
            en_const = mc.group(1)
        elif en_const and l.startswith("}"):
            en_const = None
        if l.strip().startswith("#"):
            continue
        for mm in LIT.finditer(l):
            texte = mm.group(1)
            avant = l[:mm.start()]
            cls, regle = classer(
                l, avant, texte, en_const,
                en_const in tables_affichees if en_const else False,
                dans_func, affiche,
                par_frame | tables_par_frame,
                idents_boucle, vers_texte.get(dans_func, set()))
            out.append({"ligne": i, "texte": texte, "classe": cls,
                        "regle": regle, "fonction": dans_func or "",
                        "table": en_const or ""})
    return out, sorted(par_frame), sorted(tables_par_frame)


def markdown(cible, items, pf, tpf):
    n = collections.Counter(x["classe"] for x in items)
    L = []
    A = L.append
    A("# Inventaire des littéraux — `%s`" % cible)
    A("")
    A("**VIVANT — GÉNÉRÉ.** Ne pas éditer à la main : régénérer par")
    A("```bash")
    A("python3 tools/classer_textes_joueur.py %s _refresh_resonance_hud \\" % cible)
    A("  docs/localisation/INVENTAIRE_gameplay_shell.md")
    A("```")
    A("")
    A("## Pourquoi cet inventaire remplace le compteur précédent")
    A("")
    A("`tools/inventaire_textes_joueur.py` annonce **39** littéraux joueur pour ce")
    A("fichier. Il y en a **%d**. Son critère est la FORME : un caractère de sa" % (n["J_JOUEUR"] + n["C_HORS_TRANCHE"]))
    A("constante `ACC` doit être présent. Les manqués ne sont pas des cas tordus,")
    A("ce sont les plus ordinaires — « INVENTAIRE », « Commandes », « Mains nues »,")
    A("« Surcharge », « Silence » : du français sans accent.")
    A("")
    A("**Allonger `ACC` ne peut pas marcher**, et c'est démontrable :")
    A("« Cuisiner », « Surcharge », « Silence » sont typographiquement IDENTIQUES")
    A("à « Plate », « Title », « Detail » — mêmes lettres ASCII, même casse. Les")
    A("premiers vont à l'écran, les seconds nomment des nœuds. L'information qui")
    A("les sépare n'est pas dans la chaîne : elle est dans ce que le code EN FAIT.")
    A("")
    A("Ce document classe donc par **rôle syntaxique**, et chaque ligne porte le")
    A("**nom de la règle** qui l'a classée : un désaccord porte sur une règle")
    A("nommée, pas sur une intuition.")
    A("")
    A("## Portée, et ce que cet outil ne sait PAS encore faire")
    A("")
    A("Les règles ont été calibrées sur `gameplay_shell.gd`. Passé sur d'autres")
    A("fichiers, l'outil range beaucoup dans `A_ARBITRER` — mesuré le 2026-08-31 :")
    A("104 pour `training_grounds.gd`, 47 pour `options_panel.gd`. Ces deux-là")
    A("déclarent leurs libellés dans des **dictionnaires en ligne**, un idiome")
    A("qu'aucune règle ne couvre encore.")
    A("")
    A("**C'est le comportement voulu, pas un défaut.** L'outil qu'il remplace")
    A("rangeait silencieusement tout ce qu'il ne reconnaissait pas du côté « pas")
    A("du texte joueur » ; celui-ci le déclare. Le compte de `A_ARBITRER` est donc")
    A("la mesure honnête de ce qui reste à couvrir, fichier par fichier.")
    A("")
    A("## Les quatre classes")
    A("")
    A("| Classe | Compte | Sens |")
    A("|---|---:|---|")
    A("| `J_JOUEUR` | %d | le joueur le lit ; passe par une clé |" % n["J_JOUEUR"])
    A("| `C_HORS_TRANCHE` | %d | texte joueur sur un chemin **par frame** ; hors passe À DESSEIN |" % n["C_HORS_TRANCHE"])
    A("| `A_ARBITRER` | %d | aucune règle ne tranche — **non classé, pas absous** |" % n["A_ARBITRER"])
    A("| `N_NON_JOUEUR` | %d | identifiant, chemin, clé, message développeur |" % n["N_NON_JOUEUR"])
    A("| **total** | **%d** | tous les littéraux du fichier |" % len(items))
    A("")
    A("## Les règles, et ce que chacune constate")
    A("")
    A("| Règle | Constat syntaxique |")
    A("|---|---|")
    for r, d in REGLES:
        A("| `%s` | %s |" % (r, d))
    A("")
    A("## Le chemin PAR FRAME, dérivé et non déclaré")
    A("")
    A("`_refresh_resonance_hud` court à chaque frame. La clôture transitive de ses")
    A("appels est **calculée** par l'outil, pas écrite à la main — une liste écrite")
    A("à la main se périme en silence dès qu'un appel bouge :")
    A("")
    A("```")
    A("\n".join(pf))
    A("```")
    A("")
    A("Tables indexées depuis ce chemin : `%s`." % ("`, `".join(tpf) or "aucune"))
    A("Tout littéral joueur atteint par cette clôture est `C_HORS_TRANCHE` : le")
    A("traduire appellerait `Textes.t()` soixante fois par seconde.")
    A("")
    for cls, titre in (("J_JOUEUR", "Texte joueur — dans la tranche"),
                       ("C_HORS_TRANCHE", "Texte joueur — HORS tranche (par frame)"),
                       ("A_ARBITRER", "À arbitrer — aucune règle ne tranche"),
                       ("N_NON_JOUEUR", "Non joueur")):
        A("## %s (%d)" % (titre, n[cls]))
        A("")
        A("| Ligne | Règle | Site | Texte |")
        A("|---:|---|---|---|")
        for x in items:
            if x["classe"] != cls:
                continue
            site = x["table"] or x["fonction"] or "—"
            t = x["texte"].replace("|", "\\|")
            A("| %d | `%s` | `%s` | `%s` |" % (x["ligne"], x["regle"], site, t))
        A("")
    return "\n".join(L) + "\n"


REGLES = [
    ("N-STRINGNAME", "littéral préfixé `&` : un `StringName` nomme un thème, un signal, un groupe ou une clé — jamais une phrase"),
    ("N-CHEMIN", "commence par `res://` ou `user://`"),
    ("N-DIAG", "la ligne porte `push_error`, `push_warning`, `print`, `assert` — message développeur"),
    ("N-THEME", "premier argument d'un `add_theme_*_override(` — nom d'item de thème"),
    ("N-NOM-NOEUD", "membre droit d'un `.name =` — nom de nœud"),
    ("N-CLE-DICT", "premier argument d'un `.get(` / `.has(` / `.erase(` — clé de dictionnaire"),
    ("N-API-IDENT", "premier argument d'une porte d'API qui prend un identifiant (`get_node`, `connect`, `is_action_pressed`, `load`, …)"),
    ("N-CLASSE", "deuxième argument d'un `find_children(` — nom de classe"),
    ("N-IDENT-BOUCLE", "élément d'une liste de boucle dont la variable sert ensuite à retrouver un nœud"),
    ("N-CASSE", "étiquette de branche d'un `match`, hors bloc `const`"),
    ("N-VIDE", "chaîne vide"),
    ("N-GABARIT", "aucune lettre : gabarit de format, glyphe ou ponctuation — rien à traduire"),
    ("J-TEXT", "membre droit d'un `.text =`"),
    ("J-NOTIFY", "argument d'un `_on_notification(` ou d'un `call(\"notify\", …)`"),
    ("J-ANNONCE", "argument d'un `_announce_resonance(`"),
    ("J-TABLE", "valeur d'une table `const` indexée depuis une fonction qui écrit un Label"),
    ("J-RETOUR", "`return` d'une fonction dont le résultat atteint un Label"),
    ("J-ACCUM", "affecté ou concaténé à une variable locale qui finit dans un `.text` ou dans le `return` d'une fonction d'affichage"),
    ("A-SANS-ROLE", "aucune porte d'affichage et aucune porte d'identifiant ne s'applique"),
    ("A-COURT", "moins de trois caractères : ne peut porter une phrase, mais porte peut-être un fragment"),
]


if __name__ == "__main__":
    cible = sys.argv[1] if len(sys.argv) > 1 else "scripts/ui/gameplay_shell.gd"
    racines = sys.argv[2].split(",") if len(sys.argv) > 2 \
        else ["_refresh_resonance_hud"]
    items, pf, tpf = inventorier(os.path.join(RACINE, cible), racines)
    n = collections.Counter(x["classe"] for x in items)
    print("CIBLE : %s" % cible)
    print("PAR FRAME (clôture depuis %s) : %s" % (",".join(racines), ", ".join(pf)))
    print("TABLES PAR FRAME : %s" % (", ".join(tpf) or "(aucune)"))
    print()
    for c in ("J_JOUEUR", "C_HORS_TRANCHE", "A_ARBITRER", "N_NON_JOUEUR"):
        print("%-16s %4d" % (c, n[c]))
    print("%-16s %4d" % ("TOTAL", len(items)))
    if len(sys.argv) > 3 and sys.argv[3].endswith(".json"):
        json.dump(items, io.open(sys.argv[3], "w", encoding="utf-8"),
                  ensure_ascii=False, indent=1)
    elif len(sys.argv) > 3:
        io.open(sys.argv[3], "w", encoding="utf-8").write(
            markdown(cible, items, pf, tpf))

