#!/usr/bin/env python3
"""Planche contact d'une vidéo AVI/MJPEG — la preuve COMMITTABLE d'un film.

POURQUOI CET OUTIL EXISTE (décision matérielle du lead, 2026-08-24).

Le `.git` de ce dépôt pèse déjà 1,9 Go. Une vidéo joueur de trente secondes
produite par le MovieMaker natif de Godot pèse ~250 Mo : six vidéos
ajouteraient plus d'un gigaoctet d'historique IRRÉVERSIBLE, git ne libérant
pas un blob supprimé. La règle est donc : **aucun `.avi` n'entre dans git**.
La vidéo part en pièce jointe de Release, comme l'archive jouable.

Ce qui est committé à sa place, et qui doit suffire à juger sans elle :
  * cette PLANCHE CONTACT — N images régulièrement réparties, numérotées et
    horodatées, montées en PNG ;
  * le sha256 du `.avi`, sa durée, son nombre d'images, sa résolution et sa
    cadence — imprimés ici et repris dans le manifeste.

POURQUOI UN BALAYAGE DE MARQUEURS, ET PAS UNE BIBLIOTHÈQUE. Ce conteneur
n'a ni ffmpeg, ni imageio, ni cv2 — seulement PIL. Un AVI MJPEG est une
suite de JPEG complets dans un conteneur RIFF : chaque image commence par
`FF D8 FF` (SOI) et finit par `FF D9` (EOI). Ces deux marqueurs ne peuvent
PAS apparaître dans les données entropiques d'un JPEG valide, où tout `FF`
est suivi de `00` ou d'un marqueur de redémarrage `D0`-`D7`. Le balayage
est donc exact pour ce format, et chaque image candidate est en plus
DÉCODÉE par PIL avant d'être comptée : une image qui ne s'ouvre pas n'est
pas une image.

L'en-tête `avih` du RIFF donne la cadence et le nombre d'images déclarés.
Ils sont imprimés À CÔTÉ du nombre réellement trouvé, jamais à sa place :
un conteneur peut annoncer ce qu'il n'a pas écrit.

ÉCHECS BRUYANTS (jamais 0 sur une entrée absente — piège mesuré du dépôt,
où un diff de fichiers absents rend « identique ») :
  * fichier absent, vide ou illisible ;
  * aucune image décodable ;
  * moins d'images trouvées que demandé ;
  * écriture de la planche impossible.
Tous rendent 2.

Usage :
    tools/lot1r_video_planche.py <video.avi> --out <planche.png>
        [--images 12] [--colonnes 4] [--largeur 380] [--json <manifeste>]
        [--titre "..."]
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import mmap
import os
import struct
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:  # pragma: no cover - environnement sans PIL
    print("ECHEC: PIL (Pillow) est requis", file=sys.stderr)
    raise SystemExit(2)

SOI = b"\xff\xd8\xff"
EOI = b"\xff\xd9"
POLICES = (
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/usr/share/fonts/truetype/freefont/FreeSans.ttf",
)
POLICES_GRASSES = (
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
)

FOND = (24, 26, 30)
TEXTE = (232, 232, 228)
TEXTE_FAIBLE = (150, 154, 160)
CADRE = (70, 74, 82)


def echec(message: str) -> None:
    print("ECHEC: %s" % message, file=sys.stderr)
    raise SystemExit(2)


def police(taille: int, grasse: bool = False):
    for chemin in (POLICES_GRASSES if grasse else POLICES):
        if os.path.isfile(chemin):
            try:
                return ImageFont.truetype(chemin, taille)
            except OSError:
                continue
    # Sans police vectorielle la planche reste lisible, en plus petit : on
    # le dit plutôt que de la produire silencieusement dégradée.
    print("AVERT: aucune police vectorielle trouvée — étiquettes en police "
          "bitmap par défaut", file=sys.stderr)
    return ImageFont.load_default()


def entete_avi(donnees: mmap.mmap) -> dict:
    """Cadence, images déclarées et résolution, lus dans le chunk `avih`.

    Rendu vide si l'en-tête est absent : le balayage reste la source de
    vérité sur le nombre d'images, l'en-tête n'est qu'un renseignement.
    """
    if donnees[:4] != b"RIFF" or donnees[8:12] != b"AVI ":
        return {}
    marque = donnees.find(b"avih", 0, 65536)
    if marque < 0:
        return {}
    taille = struct.unpack_from("<I", donnees, marque + 4)[0]
    if taille < 40:
        return {}
    champs = struct.unpack_from("<10I", donnees, marque + 8)
    micro_par_image = champs[0]
    if micro_par_image <= 0:
        return {}
    return {
        "fps": round(1e6 / micro_par_image, 3),
        "images_declarees": champs[4],
        "largeur": champs[8],
        "hauteur": champs[9],
    }


def bornes_images(donnees: mmap.mmap) -> list[tuple[int, int]]:
    """Offsets (début, fin) de chaque JPEG du flux, par balayage de marqueurs."""
    bornes: list[tuple[int, int]] = []
    curseur = donnees.find(SOI)
    while curseur >= 0:
        fin = donnees.find(EOI, curseur + 3)
        if fin < 0:
            break
        bornes.append((curseur, fin + 2))
        curseur = donnees.find(SOI, fin + 2)
    return bornes


def sha256(chemin: Path) -> str:
    empreinte = hashlib.sha256()
    with chemin.open("rb") as flux:
        for bloc in iter(lambda: flux.read(1 << 20), b""):
            empreinte.update(bloc)
    return empreinte.hexdigest()


def indices_repartis(total: int, combien: int) -> list[int]:
    """`combien` indices régulièrement répartis, premier et dernier compris."""
    if combien == 1:
        return [0]
    return [round(i * (total - 1) / (combien - 1)) for i in range(combien)]


def main(argv: list[str]) -> int:
    analyseur = argparse.ArgumentParser(
        prog="lot1r_video_planche",
        description="Planche contact d'un AVI MJPEG (PIL seul, sans ffmpeg).")
    analyseur.add_argument("video", help="chemin du .avi MJPEG")
    analyseur.add_argument("--out", required=True, help="planche PNG à écrire")
    analyseur.add_argument("--images", type=int, default=12,
                           help="nombre de vignettes (défaut 12)")
    analyseur.add_argument("--colonnes", type=int, default=4,
                           help="colonnes de la planche (défaut 4)")
    analyseur.add_argument("--largeur", type=int, default=380,
                           help="largeur d'une vignette en px (défaut 380)")
    analyseur.add_argument("--json", default="",
                           help="manifeste JSON à écrire à côté")
    analyseur.add_argument("--titre", default="",
                           help="titre imprimé en tête de planche")
    args = analyseur.parse_args(argv)

    if args.images < 1:
        echec("--images doit valoir au moins 1")
    if args.colonnes < 1:
        echec("--colonnes doit valoir au moins 1")

    chemin = Path(args.video)
    if not chemin.is_file():
        echec("vidéo absente — %s" % chemin)
    taille_octets = chemin.stat().st_size
    if taille_octets == 0:
        echec("vidéo vide (0 octet) — %s" % chemin)

    with chemin.open("rb") as flux:
        donnees = mmap.mmap(flux.fileno(), 0, access=mmap.ACCESS_READ)
        try:
            entete = entete_avi(donnees)
            bornes = bornes_images(donnees)
            if not bornes:
                echec("aucun marqueur JPEG trouvé — ce fichier n'est pas un "
                      "AVI MJPEG (%s)" % chemin)
            if len(bornes) < args.images:
                echec("%d image(s) trouvée(s) pour %d demandée(s) — %s"
                      % (len(bornes), args.images, chemin))

            choisis = indices_repartis(len(bornes), args.images)
            vignettes = []
            for rang in choisis:
                debut, fin = bornes[rang]
                brut = donnees[debut:fin]
                try:
                    image = Image.open(io.BytesIO(brut))
                    image.load()
                    image = image.convert("RGB")
                except Exception as erreur:  # image tronquée ou corrompue
                    echec("image %d indécodable (%s) — %s"
                          % (rang, erreur, chemin))
                vignettes.append((rang, image))
        finally:
            donnees.close()

    fps = float(entete.get("fps", 0.0))
    trouvees = len(bornes)
    duree = trouvees / fps if fps > 0 else 0.0
    resolution = "%dx%d" % (vignettes[0][1].width, vignettes[0][1].height)

    print("[planche] %s" % chemin)
    print("[planche] octets      : %d" % taille_octets)
    print("[planche] sha256      : %s" % sha256(chemin))
    print("[planche] images      : %d trouvées par balayage%s"
          % (trouvees,
             (", %d déclarées dans l'en-tête" % entete["images_declarees"])
             if "images_declarees" in entete else ""))
    print("[planche] cadence     : %s"
          % ("%.3f i/s" % fps if fps > 0 else "inconnue (en-tête absent)"))
    print("[planche] duree       : %s"
          % ("%.2f s" % duree if fps > 0 else "inconnue"))
    print("[planche] resolution  : %s" % resolution)

    # --- Montage -----------------------------------------------------------
    largeur_v = args.largeur
    ratio = vignettes[0][1].height / vignettes[0][1].width
    hauteur_v = max(1, round(largeur_v * ratio))
    colonnes = min(args.colonnes, len(vignettes))
    lignes = (len(vignettes) + colonnes - 1) // colonnes

    marge = 18
    legende = 34
    haut_entete = 96 if args.titre else 74
    largeur = marge + colonnes * (largeur_v + marge)
    hauteur = haut_entete + lignes * (hauteur_v + legende + marge) + marge // 2

    planche = Image.new("RGB", (largeur, hauteur), FOND)
    dessin = ImageDraw.Draw(planche)
    f_titre = police(20, grasse=True)
    f_meta = police(14)
    f_legende = police(15)

    y = 16
    if args.titre:
        dessin.text((marge, y), args.titre, font=f_titre, fill=TEXTE)
        y += 28
    dessin.text((marge, y), chemin.name, font=f_titre if not args.titre
                else f_meta, fill=TEXTE if not args.titre else TEXTE_FAIBLE)
    y += 24 if not args.titre else 18
    resume = ("%d images  |  %s  |  %s  |  %s  |  %.1f Mo  |  sha256 %s"
              % (trouvees,
                 "%.3f i/s" % fps if fps > 0 else "cadence inconnue",
                 "%.2f s" % duree if fps > 0 else "duree inconnue",
                 resolution, taille_octets / 1048576.0,
                 sha256(chemin)[:16]))
    dessin.text((marge, y), resume, font=f_meta, fill=TEXTE_FAIBLE)

    for rang_grille, (rang, image) in enumerate(vignettes):
        col = rang_grille % colonnes
        lig = rang_grille // colonnes
        x = marge + col * (largeur_v + marge)
        yv = haut_entete + lig * (hauteur_v + legende + marge)
        planche.paste(image.resize((largeur_v, hauteur_v), Image.LANCZOS),
                      (x, yv))
        dessin.rectangle([x, yv, x + largeur_v - 1, yv + hauteur_v - 1],
                         outline=CADRE)
        horodatage = ("t = %.2f s" % (rang / fps)) if fps > 0 else "t inconnu"
        dessin.text((x, yv + hauteur_v + 8),
                    "image %d / %d    %s" % (rang, trouvees - 1, horodatage),
                    font=f_legende, fill=TEXTE_FAIBLE)

    sortie = Path(args.out)
    if sortie.parent and not sortie.parent.exists():
        sortie.parent.mkdir(parents=True, exist_ok=True)
    try:
        planche.save(sortie)
    except OSError as erreur:
        echec("écriture impossible — %s (%s)" % (sortie, erreur))
    print("[planche] ecrite      : %s (%d x %d)"
          % (sortie, planche.width, planche.height))

    if args.json:
        manifeste = {
            "video": str(chemin),
            "octets": taille_octets,
            "sha256": sha256(chemin),
            "images_trouvees": trouvees,
            "images_declarees": entete.get("images_declarees"),
            "fps": fps if fps > 0 else None,
            "duree_s": round(duree, 3) if fps > 0 else None,
            "resolution": resolution,
            "planche": str(sortie),
            "vignettes": [
                {"image": rang,
                 "t_s": round(rang / fps, 3) if fps > 0 else None}
                for rang, _ in vignettes],
            "note": ("La video elle-meme n'entre pas dans git (decision lead "
                     "2026-08-24) : elle part en piece jointe de Release. "
                     "Cette planche et ce sha256 sont la preuve committee."),
        }
        chemin_json = Path(args.json)
        if chemin_json.parent and not chemin_json.parent.exists():
            chemin_json.parent.mkdir(parents=True, exist_ok=True)
        chemin_json.write_text(json.dumps(manifeste, indent=2,
                                          ensure_ascii=False) + "\n",
                               encoding="utf-8")
        print("[planche] manifeste   : %s" % chemin_json)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
