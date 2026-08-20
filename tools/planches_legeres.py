#!/usr/bin/env python3
"""Planches A/B légères R2B.2 → R2B.3, consultables par un humain.

Ne rend RIEN. Dérive quatre planches des PNG déjà présents dans
`evidence/world_v2/v2_3_r2b3/preuves_lead/`, sous une contrainte de poids et de
largeur qui les rende ouvrables sans outil.

Le seul point qui compte pour la valeur de preuve : le rectangle de recadrage
est UNE variable, lue dans `RECADRAGE`, appliquée aux DEUX côtés. Il n'existe
pas de chemin de code où l'avant et l'après reçoivent des rectangles différents
— c'est vérifiable à la lecture, pas sur parole.

Traitements appliqués, et rien d'autre :
  1. recadrage — identique des deux côtés, par construction ;
  2. conversion RGBA -> RGB — les sources ont un alpha à 255 partout, donc sans
     effet sur les pixels ;
  3. encodage JPEG unique du montage — un seul appel, donc des réglages
     forcément identiques pour les deux moitiés.

Aucun redimensionnement : les panneaux sortent à leur taille native. C'est
possible parce que 1280 px tient sous le plafond de 1600 px demandé, et c'est
préférable — un rééchantillonnage est un traitement de plus à défendre, et la
différence à juger sur les vues d'orbite est faible.

Usage :
    python3 tools/planches_legeres.py
"""

import hashlib
import os
import sys

from PIL import Image, ImageDraw, ImageFont

VUES = ["debris_a_proche", "debris_b_proche", "ferme_laterale", "ferme_orb090"]

# Rectangle de recadrage (gauche, haut, droite, bas) en pixels, par vue.
# UN seul tuple par vue : il sert au panneau AVANT comme au panneau APRÈS.
# Ici : image entière. Le cadrage n'est pas resserré à dessein — un cadrage
# choisi après coup peut flatter un côté, et personne ne pourrait le montrer.
RECADRAGE = {
    "debris_a_proche": (0, 0, 1280, 720),
    "debris_b_proche": (0, 0, 1280, 720),
    "ferme_laterale": (0, 0, 1280, 720),
    "ferme_orb090": (0, 0, 1280, 720),
}

SRC_AVANT = os.path.join("evidence", "world_v2", "v2_3_r2b3",
                         "preuves_lead", "avant_r2b2")
SRC_APRES = os.path.join("evidence", "world_v2", "v2_3_r2b3",
                         "preuves_lead", "apres_r2b3")
SORTIE = os.path.join("evidence", "world_v2", "v2_3_r2b3_1", "revue_legere")

LARGEUR_MAX = 1600
# Deux lectures possibles de « moins de 900 Ko » : 921 600 (kibioctet) ou
# 900 000 (kilooctet). On retient la STRICTE — un garde-fou réglé au-dessus
# de la contrainte qu'il protège laisserait passer une planche de 921 599
# octets en la déclarant conforme. Signalé par la contre-épreuve du
# 2026-08-20 ; l'écart était de 21 600 octets.
POIDS_MAX = 900_000             # strictement inférieur
QUALITES = [92, 90, 88, 85, 82, 80, 78, 75, 72, 70, 65, 60]

BANDE = 46                      # hauteur d'une étiquette
PAD = 12
FOND = (18, 18, 20)
TEXTE = (232, 232, 232)
TEXTE_FAIBLE = (150, 150, 155)

POLICES_TITRE = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
]
POLICES_MONO = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf",
]


def police(candidats, taille):
    """Première police système trouvée, sinon la police embarquée de Pillow."""
    for chemin in candidats:
        if os.path.exists(chemin):
            return ImageFont.truetype(chemin, taille)
    return ImageFont.load_default(size=taille)


def sha256(chemin):
    h = hashlib.sha256()
    with open(chemin, "rb") as f:
        for bloc in iter(lambda: f.read(1 << 20), b""):
            h.update(bloc)
    return h.hexdigest()


def ligne(dessin, xy, texte, fonte, couleur):
    dessin.text(xy, texte, font=fonte, fill=couleur)


def compose(vue, racine):
    rect = RECADRAGE[vue]
    p_av = os.path.join(racine, SRC_AVANT, "%s.png" % vue)
    p_ap = os.path.join(racine, SRC_APRES, "%s.png" % vue)

    brut_av = Image.open(p_av)
    brut_ap = Image.open(p_ap)
    if brut_av.size != brut_ap.size:
        raise SystemExit("ECHEC %s : sources de tailles differentes %s vs %s"
                         % (vue, brut_av.size, brut_ap.size))
    for nom, im in (("avant", brut_av), ("apres", brut_ap)):
        if rect[2] > im.size[0] or rect[3] > im.size[1]:
            raise SystemExit("ECHEC %s : recadrage %s hors de %s (%s)"
                             % (vue, rect, im.size, nom))

    av = brut_av.crop(rect).convert("RGB")
    ap = brut_ap.crop(rect).convert("RGB")
    if av.size != ap.size:
        raise SystemExit("ECHEC %s : panneaux de tailles differentes" % vue)

    w, h = av.size
    if w > LARGEUR_MAX:
        raise SystemExit("ECHEC %s : largeur %d au-dessus du plafond %d"
                         % (vue, w, LARGEUR_MAX))

    f_titre = police(POLICES_TITRE, 27)
    f_mono = police(POLICES_MONO, 13)

    h_av, h_ap = sha256(p_av), sha256(p_ap)
    # PROVENANCE LISIBLE. La contre-épreuve du 2026-08-20 a mesuré le pied de
    # page à 11-14 px d'encre, soit 0,68 a 0,86 % de la hauteur de planche —
    # moins de la moitié du seuil de 1,5 %. C'était l'information la plus petite
    # de la planche, alors que c'est celle qui permet de remonter à la source.
    #
    # Correction sans toucher un pixel d'image : le hachage est coupé en deux
    # moitiés de 32 caractères sur deux lignes, ce qui laisse la place d'une
    # police assez grande. Les 64 caractères restent tous présents et
    # concaténables — on ne tronque rien, on replie.
    #
    # Les chemins sont donnes RELATIVEMENT au dossier de preuves, nomme une
    # fois en tete : ecrits en entier, la ligne DEBORDAIT du cadre a droite et
    # le rectangle de recadrage etait coupe — donc invisible, donc invérifiable.
    # Constate en ouvrant la planche, pas deduit.
    base = "evidence/world_v2/v2_3_r2b3/preuves_lead"
    pied = [
        "sources sous %s/" % base,
        "AVANT  avant_r2b2/%s.png   crop %s" % (vue, rect),
        "  sha256 %s" % h_av[:32],
        "         %s" % h_av[32:],
        "APRES  apres_r2b3/%s.png   crop %s" % (vue, rect),
        "  sha256 %s" % h_ap[:32],
        "         %s" % h_ap[32:],
    ]
    # Descend la police seulement si une ligne déborde, et JAMAIS sous le
    # plancher de lisibilité : 25 px de corps donnent >= 1,5 % de hauteur
    # d'encre sur une planche de ~1900 px.
    sonde = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    for taille in (28, 27, 26, 25):
        f_mono = police(POLICES_MONO, taille)
        if max(sonde.textlength(t, font=f_mono) for t in pied) <= w - 2 * PAD:
            break
    pas = taille + 4
    h_pied = pas * len(pied) + 2 * PAD

    total_h = BANDE + h + BANDE + h + h_pied
    out = Image.new("RGB", (w, total_h), FOND)
    out.paste(av, (0, BANDE))
    out.paste(ap, (0, BANDE + h + BANDE))

    d = ImageDraw.Draw(out)
    ligne(d, (PAD, 10), "AVANT (R2B.2)   —   %s" % vue, f_titre, TEXTE)
    ligne(d, (PAD, BANDE + h + 10), "APRÈS (R2B.3)   —   %s" % vue, f_titre, TEXTE)
    y = BANDE + h + BANDE + h + PAD
    for t in pied:
        ligne(d, (PAD, y), t, f_mono, TEXTE_FAIBLE)
        y += pas

    dest = os.path.join(racine, SORTIE, "ab_leger_%s.jpg" % vue)
    for q in QUALITES:
        out.save(dest, "JPEG", quality=q, optimize=True, subsampling=0)
        taille_octets = os.path.getsize(dest)
        if taille_octets < POIDS_MAX:
            break
    else:
        raise SystemExit("ECHEC %s : %d octets, plafond %d inatteignable"
                         % (vue, taille_octets, POIDS_MAX))

    return {
        "vue": vue, "rect": rect, "taille_source": brut_av.size,
        "panneau": (w, h), "planche": (w, total_h),
        "sha_avant": h_av, "sha_apres": h_ap,
        "qualite": q, "octets": taille_octets, "fichier": dest,
    }


def main():
    racine = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.makedirs(os.path.join(racine, SORTIE), exist_ok=True)
    lignes = []
    for vue in VUES:
        r = compose(vue, racine)
        lignes.append(r)
        print("%-17s %sx%s  q=%d  %d octets  (marge %d)"
              % (r["vue"], r["planche"][0], r["planche"][1], r["qualite"],
                 r["octets"], POIDS_MAX - r["octets"]))

    doc = [
        "# Sources des planches A/B légères — R2B.2 vs R2B.3",
        "",
        "Aucun rendu n'a été relancé. Les huit PNG ci-dessous étaient déjà dans le",
        "dépôt ; les planches en sont dérivées par `tools/planches_legeres.py`.",
        "",
        "Traitements appliqués, et rien d'autre : recadrage, conversion RGBA→RGB",
        "(alpha à 255 partout, donc sans effet), encodage JPEG du montage. Aucun",
        "redimensionnement, aucun réglage de contraste, luminosité, saturation ou",
        "netteté. Le rectangle de recadrage est une seule variable par vue, lue dans",
        "`RECADRAGE` et appliquée aux deux côtés : il ne peut pas différer.",
        "",
        "| vue | côté | source | dimensions | recadrage (g,h,d,b) | SHA-256 |",
        "|---|---|---|---|---|---|",
    ]
    for r in lignes:
        for cote, dossier, sha in (("AVANT", SRC_AVANT, r["sha_avant"]),
                                   ("APRÈS", SRC_APRES, r["sha_apres"])):
            doc.append("| `%s` | %s | `%s` | %d×%d | `%s` | `%s` |" % (
                r["vue"], cote, os.path.join(dossier, "%s.png" % r["vue"]),
                r["taille_source"][0], r["taille_source"][1],
                ",".join(str(v) for v in r["rect"]), sha))
    doc += [
        "",
        "## Planches produites",
        "",
        "| fichier | dimensions | qualité JPEG | octets | plafond 900 000 octets |",
        "|---|---|---|---|---|",
    ]
    for r in lignes:
        doc.append("| `%s` | %d×%d | %d (4:4:4) | %d | marge %d octets |" % (
            os.path.basename(r["fichier"]), r["planche"][0], r["planche"][1],
            r["qualite"], r["octets"], POIDS_MAX - r["octets"]))
    doc += [
        "",
        "Reproduire : `python3 tools/planches_legeres.py` depuis la racine du dépôt.",
        "",
    ]
    chemin_doc = os.path.join(racine, SORTIE, "SOURCES.md")
    with open(chemin_doc, "w", encoding="utf-8") as f:
        f.write("\n".join(doc))
    print(chemin_doc)
    return 0


if __name__ == "__main__":
    sys.exit(main())
