# SOURCE DE GÉNÉRATION REPRODUCTIBLE — LA FORMATION FROIDE DU BELVÉDÈRE
# (`valley.poi.overlook_summit.01`, lot 1.R.1, voie A).
#
# ======================================================================
# POURQUOI CE FICHIER A ÉTÉ RÉÉCRIT — LE DÉFAUT ÉTAIT STRUCTUREL
# ======================================================================
#
# La version précédente empilait des BANCS : pour chaque `k`, deux anneaux de
# même rayon (une paroi verticale) puis un anneau de raccord (une vire
# horizontale). Trois passes de réglage ont été mesurées et publiées
# (`evidence/world_v2/v2_3_b/lot1r/voie_a2/ITERATIONS_A.md`, itérations 1, 3,
# 4/5) : retrait « lopside », diaclases profondes + retrait divisé par deux,
# puis valeur dans la face. Chacune a changé les pixels, aucune n'a supprimé la
# lecture, et le verdict d'inspection réelle est resté le même mot pour mot :
#
#     « reste une pile de dalles bleues »
#
# La cause n'est PAS dans les constantes, elle est dans la boucle. Un anneau
# retiré fait le TOUR de la masse ; une pile d'anneaux est une pièce montée.
# Le retrait « lopside » modulait l'AMPLITUDE du retrait, jamais son
# EXISTENCE : la vire faisait toujours le tour, plus large d'un côté. Aucune
# valeur de ce générateur ne pouvait produire une surface continue.
#
# ======================================================================
# CE QUE CE GÉNÉRATEUR FAIT MAINTENANT, ET POURQUOI CHAQUE GESTE
# ======================================================================
#
# Une masse = UNE surface continue `r(θ, t)`, échantillonnée finement en
# azimut et en hauteur. Il n'existe plus de notion de banc, donc plus rien à
# empiler. Six composantes, et aucune n'est décorative :
#
#  1. PROFIL VERTICAL À PALIERS. Le rayon d'ensemble suit une spline sur des
#     points de contrôle tirés par une marche décroissante dont le pas peut
#     être NUL : un palier est une paroi verticale franche, et une falaise en
#     a. Le profil ne remonte PAS — la première écriture le permettait, et
#     mesuré, il produisait une taille de guêpe faisant le tour de la masse
#     (contrôle de surplomb à 32/32, donc infalsifiable). Les surplombs sont
#     LOCAUX et viennent des bombements, jamais du profil.
#
#  2. NERVURES VERROUILLÉES SUR L'AZIMUT. Conservées de la version précédente,
#     et c'est le SEUL trait qui marchait : un relief radial fonction de
#     l'angle seul se retrouve à toute hauteur et devient un contrefort
#     filant. (Leçon héritée des stèles du champ, elles-mêmes héritées de
#     l'arbre foudroyé, où un relief tiré par anneau donnait « du bruit, pas
#     des cannelures ».)
#
#  3. LES STRATES SONT UN RELIEF, PAS UNE TRANCHE. Une rainure douce marque la
#     base de chaque lit — mais son amplitude S'ANNULE sur des secteurs
#     entiers, sa hauteur DÉRIVE avec l'azimut (le lit suit le pendage et
#     ondule), et son épaisseur varie d'un côté à l'autre. Le résultat se lit
#     comme des lits sédimentaires creusés dans une paroi continue, jamais
#     comme des galettes posées. C'est la traduction géométrique exacte de la
#     consigne « les strates peuvent exister comme RELIEF, pas comme
#     empilement de galettes ».
#
#  4. NICHES ET SURPLOMBS. Des gaussiennes signées en (θ, t) creusent des
#     cavités et gonflent des bombements. Un bombement dont la moitié basse
#     regrossit avec la hauteur EST un surplomb ; c'est ce qui rend la masse
#     non convexe et la sort de la famille « caillou ».
#
#  5. CONTREFORTS ET JUPE ENTERRÉE. Le pied s'évase par de larges gaussiennes
#     basses, puis la surface CONTINUE SOUS z = 0 en s'évasant encore. Le
#     modèle a donc un `min Y` NÉGATIF, volontairement — voir la section
#     « CONVENTION D'ASSISE » ci-dessous. Le contact pierre/herbe cesse
#     d'exister comme ligne : la roche sort du sol.
#
#  6. FACE D'ASCENSION, CASSURE DE CRÊTE, PLATEFORME. Un secteur d'azimut
#     reçoit des rainures plus creuses et une pente plus douce (on lit par où
#     ça monte) ; le sommet est coupé par une encoche en V et laisse un replat
#     tourné vers le panorama.
#
# LA MATIÈRE RESTE DANS `COLOR_0`, et elle est désormais DÉRIVÉE DE LA
# GÉOMÉTRIE et non d'un indice de banc : creux local, orientation réelle de la
# normale (une sous-face de surplomb ne voit pas le ciel), hauteur, grain
# verrouillé sur l'azimut. Chiffré sur les stèles du champ : une face quasi
# verticale rendait UNE SEULE valeur (p10-p90 = 1 niveau) pour 465 normales
# distinctes — sous ce ciel l'irradiance ambiante domine et l'orientation ne
# rapporte presque rien. Sans texture, la seule variation gratuite est la
# couleur de sommet.
#
# ======================================================================
# CONVENTION D'ASSISE — `min Y` EST NÉGATIF, ET C'EST VOULU
# ======================================================================
#
# `.claude/rules/assets.md` demande « bas de l'objet au sol : min Y ≈ 0 ». Ce
# modèle y déroge EXPRÈS et le déclare ici, parce que la règle sert à ce qu'un
# asset ne flotte pas — or ici l'exigence est l'inverse : le pied doit PLONGER
# sous le terrain, sans ligne de contact. Le plan z = 0 du modèle est donc le
# PLAN DE SOL prévu, et la jupe descend sous lui.
#
# Conséquence pour l'appelant, et elle est obligatoire : le placeur ne doit
# PAS soustraire `aabb.position.y` pour asseoir la pièce (ce qui la
# remonterait de toute la hauteur de jupe). Il pose `y = sol - enfoncement`.
# `scripts/world_v2/poi/overlook_summit_place.gd::_croc()` porte la même note.
#
# ======================================================================
# CONTRÔLES QUE LE GÉNÉRATEUR S'IMPOSE (il rend 2 et n'écrit rien)
# ======================================================================
#
# Deux d'entre eux sont NEUFS et visent nommément le défaut rejeté. Ils ne
# sont pas calibrés sur le résultat : ils encodent la phrase du verdict.
#
#   * `CEINTURE_MAX` — aucune rainure de strate ne court sans interruption
#     sur plus de 40 % du pourtour (≈ 144°, moins que l'arc visible d'une
#     seule vue) à l'intérieur d'une tranche de 30 cm de hauteur. C'est la
#     définition mesurable de « aucune tranche horizontale répétée ».
#     L'ANCIEN générateur y rendait 100 % à chaque banc.
#   * `SURPLOMBS_MIN` / `SURPLOMBS_MAX_PART` — au moins trois azimuts portant
#     un vrai surplomb (sinon la masse est convexe partout : un caillou), et
#     jamais plus de 70 % des azimuts surplombant À LA MÊME HAUTEUR (sinon ce
#     n'est pas un surplomb, c'est une taille de guêpe). Mesuré sur le profil
#     LISSE, strates EXCLUES : chaque rainure produit mécaniquement un
#     dr/dt > 0 juste au-dessus d'elle, et un contrôle qui les compterait
#     serait vrai par construction — donc faux au sens qui compte
#     (`tools/CLAUDE.md`, « un test vert sur une grandeur qui n'est pas celle
#     qu'on croit mesurer »).
#
# Les DEUX ont rougi pendant l'écriture, et c'est leur seule vraie garantie :
# la ceinture à 0,62 puis 0,57, le surplomb à 32/32 (donc infalsifiable) avant
# d'être redéfini. Un contrôle qui n'a jamais rien refusé ne prouve rien.
#
# Et les contrôles conservés : plan de sol réellement traversé, hauteur dans
# sa fourchette, budget de triangles, aire de facette, présence et étendue de
# la couleur de sommet, absence d'écrêtage (> 1 = écrêté EN SILENCE à
# l'export), MOYENNE de couleur dans sa bande (c'est la dette de l'itération 4
# qui avait fait tomber la crête sous les cailloux de son propre pied), et
# pendage IDENTIQUE sur les deux masses.
#
# Chaîne : tools/blender/export_lieux_voie_a.sh overlook_crags
#
# Usage direct (déconseillé, pas de jeton de fraîcheur) :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/environment/make_overlook_crags.py

import math
import os
import random
import sys

import bpy
import bmesh
from mathutils import Vector

TAG = "[overlook_crags]"

## Échantillonnage de la surface. La résolution verticale n'est pas
## cosmétique : une rainure de strate fait ~25 cm, et il faut trois ou quatre
## échantillons pour qu'elle se lise au lieu de se réduire à une arête.
BUDGET_TRIS = 6400
AIRE_FACETTE_MAX = 1.20
## Contrôles NEUFS — voir l'en-tête. Ils encodent le verdict, pas un résultat.
CEINTURE_MAX = 0.40
CEINTURE_TRANCHE_M = 0.30
## Le contrôle de surplomb est BORNÉ DES DEUX CÔTÉS, et la borne haute n'est
## pas une coquetterie : à la première écriture il rendait 32 azimuts sur 32,
## c'est-à-dire un test qui ne pouvait pas échouer (`PROMPT4_METHOD` §2). La
## cause était réelle et instructive — le profil vertical remontait GLOBALEMENT
## entre deux points de contrôle, donc la masse portait une taille de guêpe qui
## faisait le tour. Un surplomb qui ceinture n'est pas un surplomb, c'est un
## diabolo. Le profil est redevenu décroissant, les surplombs ne viennent plus
## que des bombements LOCAUX, et le contrôle peut désormais rougir des deux
## façons : trop peu (masse convexe = caillou), ou partout (taille de guêpe).
SURPLOMBS_MIN = 3
SURPLOMBS_MAX_PART = 0.70
## Bande de MOYENNE de couleur de sommet. Dette de l'itération 4 : trois
## modulations avaient fait monter l'étendue (31 % → 66 %) et TOMBER la
## moyenne (p10 0,716 → 0,474), et la crête était devenue plus sombre que les
## boulders de kit à son pied (V 0,391 contre 0,540 mesuré dans la MÊME
## image). Le correctif ×1,35 de l'itération 6 a été confirmé sur capture
## (0,468 → 0,549). Cette bande empêche la régression de revenir en douce.
COULEUR_MOYENNE_MIN = 0.55
COULEUR_MOYENNE_MAX = 0.88
ETENDUE_COULEUR_MIN = 0.20

## PENDAGE PARTAGÉ — azimut (degrés, sens trigonométrique dans le plan XY de
## Blender) et angle. Les deux masses le portent à l'identique : c'est ce qui
## les fait lire comme une seule formation rompue en deux, et non comme deux
## rochers voisins. Repère : Godot local (X ; Z) = Blender (x ; −y), donc
## l'azimut 209° sort à (−0,875 ; +0,485) côté Godot, presque exactement la
## direction de visée de `cam05_belvedere_crete` (−0,82 ; +0,573). Les lignes
## de strate regardent donc le panorama.
PENDAGE_AZIMUT = 209.0
PENDAGE_DEG = 13.5
## L'axe ne fait pas que se cisailler : il s'INFLÉCHIT. Un cisaillement pur
## est une transformation affine, et une masse affine se relit « penchée »,
## pas « érodée ». La courbure est partagée elle aussi.
## 0,085 → 0,050 : à la première valeur la masse lisait « penchée comme une
## bougie » sur `iter7`. Le cisaillement de pendage suffit à la faire vivre ;
## la courbure n'est là que pour interdire une transformation affine pure.
COURBURE = 0.050
COURBURE_AZIMUT = 128.0

## ARDOISE FROIDE — INCHANGÉE, et c'est délibéré : la couleur est le seul
## point du lieu que la revue n'a PAS rejeté. Historique complet de sa
## calibration (quatre mesures sur capture) :
##   v1 (0,355 ; 0,395 ; 0,462) → face au soleil RGB(255,255,255), ÉCRÊTÉE.
##       `baseColorFactor` glTF est LINÉAIRE : une valeur qui « a l'air » d'un
##       gris moyen y est claire, et la lumière du monde la pousse au-delà
##       de 1. C'est le piège d'albédo de `scripts/CLAUDE.md`, version glTF.
##   v2 rapport 1 : 1,07 : 1,47 → valeur juste (V 0,50) mais S = 0,02 : gris
##       neutre. La lumière du monde est CHAUDE et mange le biais bleu.
##   v3 rapport 1 : 1,20 : 2,03, obtenu en BAISSANT rouge et vert (monter le
##       bleu réécrêterait) → H 217–229°, S 0,18. Cible atteinte : les
##       boulders de kit refroidis du même lieu rendent H 223° S 0,254 V 0,540.
##   v4 ×1,35 (facteur CALCULÉ : la face à l'ombre demandait 0,253/0,184 en
##       linéaire) → V 0,549 mesuré, contre 0,540 pour la cible, et la vire la
##       plus claire reste sous la falaise V2.2 du fond (0,632) qui plafonne.
MAT_ARDOISE = (0.0767, 0.0919, 0.1557, 1.0)
## Le nu de fracture fraîche : à peine plus clair, franchement plus froid.
MAT_FRACTURE = (0.0890, 0.1060, 0.1794, 1.0)
NIVEAU = 0.82
## Pied : plus sombre, un rien plus vert — la roche rejoint la terre.
TEINTE_PIED = (0.62, 0.68, 0.60)

## Les deux masses.
##
## `azim_*` sont des azimuts BLENDER en degrés. Ils ne sont pas décoratifs :
##   * la face visible depuis `overlook_summit_joueur` est à ≈ 180° (la caméra
##     regarde la crête presque plein est) ;
##   * la face visible depuis `overlook_summit_identite` est à ≈ 146° ;
##   * le panorama et l'approche sont à ≈ 215°.
## Donc : ascension et plateforme regardent l'approche et le vide, l'encoche
## de crête se découpe dans la vue d'identité.
##
## nom | H m | demi_a | demi_b | jupe m | graine | asc° | plateforme° | encoche°
## Demi-axes RECALÉS SUR L'EMPRISE MESURÉE, pas choisis. Le profil est
## désormais décroissant (il ne remonte plus), donc à demi-axes égaux la masse
## est plus étroite qu'avant : mesuré 6,75 m d'emprise visible contre 8,10 m
## pour la version rejetée. Or c'est la PRÉSENCE qu'il faut gagner, pas la
## perdre. Les demi-axes sont donc multipliés par 8,20/6,75 ≈ 1,21 pour revenir
## au-dessus de l'emprise précédente. Le vide entre les deux masses reste franc
## : centres à 14,29 m l'un de l'autre, demi-emprises 4,1 et 3,2 → ≈ 7,0 m
## d'herbe (7,47 m avant), et c'est ce vide qui tient le PASS D3.
## LOT 1.R.1, TROISIÈME VOIE — DEUX CHANGEMENTS, ET AUCUN NE TOUCHE À
## L'ÉROSION CONTINUE ACQUISE.
##
##  * les masses S'AFFINENT (crête 3,45/2,78 → 3,05/2,50, éperon 2,16/1,84 →
##    1,92/1,66). Le VIDE entre elles passe de ≈ 7,0 à ≈ 7,8 m sans qu'aucune
##    implantation ne bouge. C'est ce vide qui distingue le lieu en aplat noir,
##    et il s'était refermé quand les masses avaient grossi ;
##  * les JUPES raccourcissent (0,85 → 0,40 ; 0,62 → 0,35). Elles sont
##    ENTERRÉES, donc invisibles, mais elles comptent dans l'AABB qui cadre la
##    silhouette du détecteur. Les raccourcir baisse la hauteur de silhouette
##    sans retirer un centimètre de ce que le joueur voit.
## La crête perd 35 cm de hauteur (6,90 → 6,55), et c'est le seul prélèvement
## sur le visible de toute la passe.
CROCS = [
    ("SM_Overlook_Crest", 6.55, 3.05, 2.50, 0.40, 51703, 196.0, 214.0, 142.0),
    ("SM_Overlook_Spur", 4.30, 1.92, 1.66, 0.35, 28841, 186.0, 206.0, 118.0),
]
## Multiplicateur de couleur de sommet, par masse. L'éperon rendait V 0,631
## contre 0,643 pour la falaise V2.2 du fond (mesuré `iter9/_identite`) : il ne
## s'en détachait pas. Il descend d'un cran ; la crête ne bouge pas.
TEINTE_MASSE = {"SM_Overlook_Crest": 1.0, "SM_Overlook_Spur": 0.88}
## Résolution par masse (azimuts, tranches au-dessus du sol, tranches de jupe).
RESOLUTION = {
    "SM_Overlook_Crest": (26, 26, 4),
    "SM_Overlook_Spur": (22, 20, 3),
}


def _purge() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _delta_angle(a: float, b: float) -> float:
    """Écart angulaire signé minimal, dans (−π ; π]."""
    return (a - b + math.pi) % math.tau - math.pi


def _spline(controles, t: float) -> float:
    """Catmull-Rom sur des points de contrôle ÉQUIDISTANTS en t ∈ [0 ; 1].

    Utilisée pour le profil vertical. Elle interpole, donc les valeurs tirées
    sont réellement atteintes ; et elle ne force aucune monotonie, ce qui est
    tout l'intérêt : une masse qui se resserre puis regrossit porte un
    surplomb.
    """
    n = len(controles) - 1
    x = max(0.0, min(1.0, t)) * n
    i = min(n - 1, int(math.floor(x)))
    f = x - i
    p0 = controles[max(0, i - 1)]
    p1 = controles[i]
    p2 = controles[i + 1]
    p3 = controles[min(n, i + 2)]
    return 0.5 * ((2.0 * p1)
                  + (-p0 + p2) * f
                  + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * f * f
                  + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * f * f * f)


class Masse:
    """Le champ `r(θ, t)` d'une masse — tout est ici, rien n'est empilé.

    `t` vaut 0 au plan de sol et 1 au sommet ; il descend en NÉGATIF dans la
    jupe enterrée. Chaque composante est séparée pour qu'un contrôle puisse en
    mesurer une SANS les autres — c'est ce qui rend le test de surplomb
    honnête (voir `SURPLOMBS_MIN` dans l'en-tête).
    """

    def __init__(self, hauteur, demi_a, demi_b, jupe, graine,
                 azim_asc, azim_plateforme, azim_encoche):
        self.H = hauteur
        self.demi_a = demi_a
        self.demi_b = demi_b
        self.jupe = jupe
        self.t_jupe = -jupe / hauteur
        self.asc = math.radians(azim_asc)
        self.plateforme = math.radians(azim_plateforme)
        self.encoche = math.radians(azim_encoche)
        rng = random.Random(graine)
        self.rng = rng

        # --- 1. PROFIL VERTICAL, DÉCROISSANT MAIS À PALIERS ----------------
        # Sept points de contrôle. Le pas ne remonte JAMAIS — mesuré à la
        # première écriture : un profil qui remontait globalement donnait une
        # taille de guêpe faisant le tour de la masse, et le contrôle de
        # surplomb rendait 32/32, donc ne mesurait rien. Les surplombs doivent
        # être LOCAUX ; ils viennent des bombements, pas du profil.
        # En revanche le pas peut être NUL : un palier est une paroi verticale
        # franche, et une falaise en a. Les paliers sont plus probables en bas
        # (une formation a un socle vertical) et la perte s'accélère en haut.
        val = 1.0
        ctrl = [val]
        for k in range(6):
            if rng.random() < 0.42 - 0.04 * k:
                pas = 0.0
            else:
                pas = -rng.uniform(0.045, 0.085 + 0.030 * k)
            val = max(0.40, val + pas)
            ctrl.append(val)
        # Le sommet ne peut pas être aussi large que le pied : une masse dont
        # la couronne égale la base se relit « fût », pas « croc ».
        ctrl[-1] = min(ctrl[-1], 0.60)
        ctrl[-2] = min(ctrl[-2], 0.80)
        self.profil_ctrl = ctrl

        # --- 2. NERVURES VERROUILLÉES SUR L'AZIMUT --------------------------
        self.harmoniques = [(ordre, amplitude, rng.uniform(0.0, math.tau))
                            for ordre, amplitude in ((2, 0.170), (3, 0.122),
                                                     (5, 0.071), (8, 0.040))]
        self.entailles = [(rng.uniform(0.0, math.tau),
                           rng.uniform(0.20, 0.30),
                           rng.uniform(0.13, 0.23)) for _ in range(3)]

        # --- 3. STRATES EN RELIEF ------------------------------------------
        self.strate_periode = rng.uniform(0.78, 1.02)
        # 0,075–0,098 → 0,135–0,165 : à l'ancienne amplitude les rainures
        # existaient dans la géométrie et ne se voyaient pas à dix mètres.
        self.strate_ampli = rng.uniform(0.135, 0.165)
        self.strate_phases = tuple(rng.uniform(0.0, math.tau) for _ in range(5))
        # Amplitude de la DÉRIVE en hauteur du lit, en mètres, et de la
        # variation d'ÉPAISSEUR du lit. Les deux sont nécessaires et elles ne
        # font pas le même travail — mesuré : avec la seule dérive, l'éperon
        # rendait une ceinture de 0,61 (plafond 0,50). Une dérive supérieure à
        # une période se replie sur elle-même et n'améliore plus rien ; ce qui
        # décorrèle vraiment les rainures d'un azimut à l'autre, c'est que
        # l'ÉCHELLE de la ladder change — les rungs s'écartent d'un côté et se
        # resserrent de l'autre, donc leurs hauteurs divergent avec l'altitude.
        self.strate_derive = self.strate_periode * rng.uniform(0.62, 0.88)
        self.strate_biseau = rng.uniform(0.48, 0.62)

        # --- 4. NICHES ET SURPLOMBS ----------------------------------------
        # (θ, t, σθ, σt, amplitude). Amplitude négative = niche creusée ;
        # positive placée haut = bombement dont la moitié basse SURPLOMBE.
        self.bosses = []
        for _ in range(3):
            self.bosses.append((rng.uniform(0.0, math.tau),
                                rng.uniform(0.28, 0.74),
                                rng.uniform(0.42, 0.86),
                                rng.uniform(0.09, 0.17),
                                -rng.uniform(0.14, 0.24)))
        for _ in range(3):
            self.bosses.append((rng.uniform(0.0, math.tau),
                                rng.uniform(0.40, 0.78),
                                rng.uniform(0.50, 0.95),
                                rng.uniform(0.10, 0.16),
                                rng.uniform(0.13, 0.21)))
        # --- 5. CONTREFORTS DE PIED ----------------------------------------
        # Larges, bas, positifs : le pied s'étale en éperons au lieu de
        # rencontrer l'herbe sur un cercle.
        for _ in range(3):
            self.bosses.append((rng.uniform(0.0, math.tau),
                                rng.uniform(0.0, 0.14),
                                rng.uniform(0.75, 1.25),
                                rng.uniform(0.17, 0.26),
                                rng.uniform(0.20, 0.33)))

    # ------------------------------------------------------------------
    def nervure(self, theta: float) -> float:
        v = 0.0
        for ordre, amplitude, phase in self.harmoniques:
            v += amplitude * math.sin(ordre * theta + phase)
        for centre, profondeur, largeur in self.entailles:
            d = abs(_delta_angle(theta, centre))
            if d < largeur:
                v -= profondeur * (0.5 + 0.5 * math.cos(math.pi * d / largeur))
        return v

    def ascension(self, theta: float) -> float:
        """Poids du secteur d'ascension : 1 dans son axe, 0 hors du secteur."""
        d = abs(_delta_angle(theta, self.asc))
        return math.exp(-(d / 0.72) ** 2)

    def strate_amplitude(self, theta: float, z: float = 0.0) -> float:
        """Amplitude de la rainure de lit, par AZIMUT **et par HAUTEUR**.

        Deux masques, et le second a été ajouté sur MESURE, pas par goût.

        Le premier annule la rainure sur des secteurs d'azimut entiers. Il ne
        suffisait pas : mesuré, la pire fenêtre tenait encore 20 azimuts sur
        32 (0,62 pour un plafond de 0,50). La cause est mécanique et vaut
        d'être écrite — la dérive du lit est une fonction LISSE de l'azimut,
        donc elle a des extrema, et au voisinage d'un extremum toute une bande
        d'azimuts partage la même phase. Ces azimuts-là portent alors leur
        rainure à la même hauteur : une ceinture, malgré le pendage.

        Le second masque dépend de θ ET de z : la rainure n'existe que par
        PLAQUES. Un lit s'interrompt, reprend trois mètres plus loin à une
        autre hauteur — ce sont les « arêtes cassées » et les « redents
        irréguliers » demandés, et c'est ce qui rend impossible une ligne
        continue quelle que soit la géologie.

        La face d'ascension échappe aux deux : ses rainures sont les prises,
        et une prise qui s'interrompt ne se lit plus comme un chemin.
        """
        p1, p2 = self.strate_phases[0], self.strate_phases[1]
        w = 0.55 * (0.5 + 0.5 * math.sin(2.0 * theta + p1)) \
            + 0.45 * (0.5 + 0.5 * math.sin(3.0 * theta + p2))
        w = max(0.0, min(1.0, (w - 0.34) / 0.42))
        w = w * w * (3.0 - 2.0 * w)
        p3, p4, p5 = self.strate_phases[2:5]
        q = 0.55 * (0.5 + 0.5 * math.sin(2.0 * theta + p4 + 1.35 * z)) \
            + 0.45 * (0.5 + 0.5 * math.sin(5.0 * theta + p5 - 0.85 * z))
        q = max(0.0, min(1.0, (q - 0.30) / 0.34))
        q = q * q * (3.0 - 2.0 * q)
        asc = self.ascension(theta)
        plaque = q + asc * (1.0 - q)
        return self.strate_ampli * (w + 0.85 * asc * (1.0 - w)) * plaque

    def strate(self, theta: float, t: float) -> float:
        """Rainure douce à la base de chaque lit — un CREUX, jamais un gradin.

        La hauteur du lit dérive avec l'azimut (il suit le pendage et ondule)
        et son épaisseur varie d'un côté à l'autre de la masse.
        """
        z = t * self.H
        amp = self.strate_amplitude(theta, z)
        if amp <= 1e-6:
            return 0.0
        p1, p2, p3, p4, p5 = self.strate_phases
        periode = self.strate_periode * (1.0 + self.strate_biseau * (
            0.62 * math.sin(theta + p3) + 0.38 * math.sin(2.0 * theta + p4)))
        derive = self.strate_derive * (
            0.44 * math.cos(theta - math.radians(PENDAGE_AZIMUT))
            + 0.32 * math.sin(2.0 * theta + p4)
            + 0.24 * math.sin(5.0 * theta + p5))
        u = (z - derive) / periode
        f = u - math.floor(u)
        # Creux à la base du lit, éteint au tiers de sa hauteur : le nu du lit
        # reste une paroi continue, la rainure est un TRAIT dans cette paroi.
        if f >= 0.34:
            return 0.0
        return -amp * (0.5 + 0.5 * math.cos(math.pi * f / 0.34))

    def bosse(self, theta: float, t: float) -> float:
        v = 0.0
        for th, tt, sth, stt, amp in self.bosses:
            dth = _delta_angle(theta, th) / sth
            dt = (t - tt) / stt
            e = dth * dth + dt * dt
            if e < 9.0:
                v += amp * math.exp(-e)
        return v

    def profil(self, t: float) -> float:
        """Rayon d'ensemble, jupe comprise."""
        if t >= 0.0:
            return _spline(self.profil_ctrl, t)
        # JUPE : sous le plan de sol la masse s'évase franchement. Le talus
        # n'est pas décoratif — c'est lui qui supprime la ligne de contact.
        u = min(1.0, t / self.t_jupe)
        return self.profil_ctrl[0] * (1.0 + 0.30 * u * (2.0 - u))

    def rayon_lisse(self, theta: float, t: float) -> float:
        """Le rayon SANS les rainures de strate.

        C'est sur lui que se mesurent les surplombs : compter les dr/dt > 0
        produits par les rainures elles-mêmes rendrait le contrôle vrai par
        construction.
        """
        return self.profil(t) * (1.0 + self.nervure(theta)) \
            * (1.0 + self.bosse(theta, t))

    def rayon(self, theta: float, t: float) -> float:
        return self.rayon_lisse(theta, t) * (1.0 + self.strate(theta, t))

    def couronne(self, theta: float) -> float:
        """Abaissement du sommet, en fraction de H.

        Zéro dans le secteur de la plateforme (c'est le point haut, et il est
        tourné vers le panorama), franc ailleurs, et une ENCOCHE EN V — la
        cassure de crête — sur un azimut étroit.
        """
        d_plat = abs(_delta_angle(theta, self.plateforme))
        base = 0.135 * (1.0 - math.exp(-(d_plat / 0.62) ** 2))
        d_enc = abs(_delta_angle(theta, self.encoche))
        return base + 0.115 * math.exp(-(d_enc / 0.24) ** 2)

    def point(self, theta: float, t: float) -> Vector:
        r = self.rayon(theta, t)
        z = t * self.H
        x = math.cos(theta) * self.demi_a * r
        y = math.sin(theta) * self.demi_b * r
        return Vector((x, y, z)) + self.decalage(z)

    def decalage(self, z: float) -> Vector:
        """Cisaillement de pendage + inflexion de l'axe."""
        az = math.radians(PENDAGE_AZIMUT)
        cz = math.radians(COURBURE_AZIMUT)
        shear = Vector((math.cos(az), math.sin(az), 0.0)) \
            * (math.tan(math.radians(PENDAGE_DEG)) * z)
        u = max(0.0, z) / self.H
        courbe = Vector((math.cos(cz), math.sin(cz), 0.0)) \
            * (COURBURE * self.H * u * u)
        return shear + courbe


def _teinte(masse: Masse, theta: float, t: float, normale: Vector,
            creux: float, teinte_masse: float = 1.0) -> tuple:
    """Couleur de sommet DÉRIVÉE DE LA GÉOMÉTRIE.

    Quatre modulations, et chacune décrit un fait de la surface plutôt qu'un
    indice de boucle :
      * `creux` — déficit de rayon par rapport au profil lisse : les rainures
        de strate, les entailles et les niches s'assombrissent ;
      * `normale.z` — une face qui regarde le ciel le reçoit ; une sous-face
        de surplomb ne le voit pas, elle est plus sombre ET plus froide ;
      * la hauteur — le pied s'assombrit et verdit, la roche rejoint la terre ;
      * un grain VERROUILLÉ SUR L'AZIMUT : il survit d'une tranche à l'autre
        et devient une trace verticale, au lieu d'un bruit qui change d'étage.
    """
    up = max(-1.0, min(1.0, normale.z))
    v = 1.0
    v *= 1.0 - 0.52 * max(0.0, min(1.0, creux))
    if up > 0.0:
        v *= 1.0 + 0.13 * up
    else:
        v *= 1.0 + 0.26 * up
    pied = max(0.0, 1.0 - max(0.0, t) * 2.3)
    v *= 1.0 + 0.075 * math.sin(7.0 * theta + 2.1) * math.cos(3.0 * theta + 0.7)
    v *= 1.0 + 0.048 * math.sin(11.0 * theta + 0.4)
    r = NIVEAU * v * teinte_masse
    g = NIVEAU * v * teinte_masse
    b = NIVEAU * v * teinte_masse
    r *= (1.0 - 0.22 * pied)
    g *= (1.0 - 0.10 * pied)
    b *= (1.0 - 0.26 * pied)
    # Sous-face : plus froide encore. Un surplomb qui ne bleuit pas se relit
    # comme une ombre plate.
    if up < -0.25:
        froid = min(1.0, (-up - 0.25) / 0.75)
        r *= 1.0 - 0.10 * froid
        b *= 1.0 + 0.06 * froid
    borne = lambda x: max(0.28, min(1.0, x))
    return (borne(r), borne(g), borne(b))


def _construire(nom: str, masse: Masse, mat_corps, mat_fracture):
    na, nt, nj = RESOLUTION[nom]
    teinte_masse = TEINTE_MASSE.get(nom, 1.0)
    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()

    # Grille (θ, t). Les t vont de la jupe au sommet ; le sommet de chaque
    # colonne est abaissé par `couronne(θ)` de façon PROGRESSIVE, pour que la
    # cassure de crête n'aille pas cisailler la masse entière.
    thetas = [math.tau * j / na for j in range(na)]
    ts = [masse.t_jupe * (1.0 - k / float(nj)) for k in range(nj)]
    ts += [k / float(nt - 1) for k in range(nt)]

    anneaux = []
    infos = []
    for t in ts:
        ligne = []
        info = []
        for theta in thetas:
            p = masse.point(theta, t)
            if t > 0.0:
                # Abaissement de couronne, appliqué seulement dans le tiers
                # haut et en douceur.
                poids = max(0.0, (t - 0.60) / 0.40)
                p.z -= masse.couronne(theta) * masse.H * poids * poids
            ligne.append(bm.verts.new(p))
            lisse = masse.profil(t) * (1.0 + max(0.0, masse.nervure(theta))) \
                * (1.0 + max(0.0, masse.bosse(theta, t)))
            reel = masse.rayon(theta, t)
            info.append((theta, t, max(0.0, 1.0 - reel / max(lisse, 1e-6))))
        anneaux.append(ligne)
        infos.append(info)

    faces_corps = []
    for i in range(len(anneaux) - 1):
        bas = anneaux[i]
        haut = anneaux[i + 1]
        for j in range(na):
            m = (j + 1) % na
            faces_corps.append(bm.faces.new((bas[j], bas[m], haut[m], haut[j])))

    # LA COURONNE. Le sommet n'est pas un cône : c'est un replat incliné,
    # ancré du côté de la plateforme. Un apex centré redonnerait un couvercle,
    # et un couvercle est exactement la lecture qu'on répare.
    faces_fracture = []
    dernier = anneaux[-1]
    centre = Vector((0.0, 0.0, 0.0))
    for v in dernier:
        centre += v.co
    centre /= na
    vers_plateforme = Vector((math.cos(masse.plateforme),
                              math.sin(masse.plateforme), 0.0))
    # Hauteur du replat : celle des sommets du secteur de plateforme, moins un
    # rien. Elle penche donc naturellement vers l'encoche.
    hauts = [v.co.z for v, (theta, _, _) in zip(dernier, infos[-1])
             if abs(_delta_angle(theta, masse.plateforme)) < 0.65]
    z_plat = (sum(hauts) / len(hauts)) if hauts else centre.z
    apex = Vector((centre.x + vers_plateforme.x * masse.demi_a * 0.30,
                   centre.y + vers_plateforme.y * masse.demi_b * 0.30,
                   z_plat + 0.035 * masse.H))
    # UN ÉVENTAIL DIRECT DEPUIS L'APEX REND DES FACETTES DE 2 m² — mesuré, la
    # chaîne a rougi dessus (plafond 1,20 m²). Une couronne intermédiaire, donc.
    # C'est le même mode de panne que celui déjà consigné dans ce fichier pour
    # le fond de jupe : sur un rayon de plusieurs mètres, un éventail depuis un
    # point unique fabrique de grandes faces planes, et une grande face plane
    # est précisément ce que le contrôle existe pour interdire.
    faîte = bm.verts.new(apex)
    # DEUX couronnes intermédiaires depuis que la résolution a baissé pour
    # l'ombrage à facettes : à 26 azimuts, une seule ne suffisait plus et la
    # chaîne a rougi à 1,377 m² pour un plafond de 1,20.
    couronne_mid = []
    for facteur in (0.34, 0.68):
        couronne_mid.append([bm.verts.new(v.co.lerp(apex, facteur))
                             for v in dernier])
    for j in range(na):
        m = (j + 1) % na
        faces_fracture.append(bm.faces.new((dernier[j], dernier[m],
                                            couronne_mid[0][m],
                                            couronne_mid[0][j])))
        faces_fracture.append(bm.faces.new((couronne_mid[0][j],
                                            couronne_mid[0][m],
                                            couronne_mid[1][m],
                                            couronne_mid[1][j])))
        faces_fracture.append(bm.faces.new((couronne_mid[1][j],
                                            couronne_mid[1][m], faîte)))

    # FOND DE JUPE. Le solide est fermé sous le terrain : un solide ouvert
    # laisserait voir son intérieur au moindre écart d'assise, et l'assise
    # d'ici est justement irrégulière.
    premier = anneaux[0]
    z_fond = min(v.co.z for v in premier)
    # DEUX couronnes intermédiaires, pas une : le pied évasé atteint 4,5 m de
    # rayon, et un éventail depuis le centre y rendait des facettes bien
    # au-dessus du plafond.
    milieu = []
    for facteur in (0.76, 0.52, 0.28):
        anneau_bas = []
        for v in premier:
            anneau_bas.append(bm.verts.new(Vector((v.co.x * facteur,
                                                   v.co.y * facteur, z_fond))))
        milieu.append(anneau_bas)
    centre_bas = bm.verts.new(Vector((0.0, 0.0, z_fond)))
    for j in range(na):
        m = (j + 1) % na
        faces_corps.append(bm.faces.new((premier[m], premier[j], milieu[0][j],
                                         milieu[0][m])))
        faces_corps.append(bm.faces.new((milieu[0][m], milieu[0][j],
                                         milieu[1][j], milieu[1][m])))
        faces_corps.append(bm.faces.new((milieu[1][m], milieu[1][j],
                                         milieu[2][j], milieu[2][m])))
        faces_corps.append(bm.faces.new((milieu[2][m], milieu[2][j],
                                         centre_bas)))

    for face in faces_fracture:
        face.material_index = 1

    bm.normal_update()

    # Couleur de sommet, après calcul des normales : elle DÉCRIT la surface
    # produite au lieu de décrire l'intention du générateur.
    couleurs = {}
    for ligne, info in zip(anneaux, infos):
        for v, (theta, t, creux) in zip(ligne, info):
            couleurs[v] = _teinte(masse, theta, t, v.normal, creux,
                                  teinte_masse)
    teinte_pied = tuple(c * NIVEAU * teinte_masse for c in TEINTE_PIED)
    for anneau_bas in milieu:
        for v in anneau_bas:
            couleurs[v] = teinte_pied
    couleurs[centre_bas] = teinte_pied
    sommet_teinte = _teinte(masse, masse.plateforme, 1.0, Vector((0, 0, 1)),
                            0.0, teinte_masse)
    couleurs[faîte] = sommet_teinte
    for anneau_haut in couronne_mid:
        for v in anneau_haut:
            couleurs[v] = sommet_teinte

    couche = bm.loops.layers.float_color.new("Col")
    bm.verts.index_update()
    for face in bm.faces:
        for boucle in face.loops:
            t = couleurs.get(boucle.vert, (1.0, 1.0, 1.0))
            boucle[couche] = (t[0], t[1], t[2], 1.0)

    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.normal_update()
    bm.to_mesh(maillage)
    bm.free()

    # OMBRAGE À FACETTES — et c'est le correctif du défaut « cire fondue »
    # mesuré sur `voie_a3/iter7`. Des normales de sommet LISSÉES sur une
    # surface dense produisent un dégradé continu : la masse rendait molle et
    # coulante là où TOUT le monde autour d'elle — falaises V2.2, rochers de
    # kit, éboulis — est franchement facetté. Elle n'appartenait pas à la même
    # matière. Le relief, lui, était bien là et mesuré ; c'est l'ombrage qui
    # le dissolvait. La résolution suit ce choix : une facette doit se LIRE, et
    # à 20 cm l'ombrage à facettes ne rendrait que du bruit.
    for polygone in maillage.polygons:
        polygone.use_smooth = False

    # La couche doit être l'attribut de couleur ACTIF et celui de RENDU :
    # l'exporter glTF 4.0 n'écrit `COLOR_0` que pour celui-là (ISS-066).
    if "Col" in maillage.color_attributes:
        maillage.color_attributes.active_color_index = \
            maillage.color_attributes.find("Col")
        maillage.color_attributes.render_color_index = \
            maillage.color_attributes.find("Col")

    maillage.materials.append(mat_corps)
    maillage.materials.append(mat_fracture)
    objet = bpy.data.objects.new(nom, maillage)
    bpy.context.scene.collection.objects.link(objet)
    return objet


def _controle_ceinture(masse: Masse, na: int) -> tuple:
    """« Aucune tranche horizontale répétée » — rendu mesurable.

    On repère les rainures de strate le long de chaque colonne d'azimut (les
    minima locaux du facteur de strate), on les range par tranche de hauteur,
    et on regarde quelle est la tranche la PLUS peuplée. Si une tranche
    contient une rainure sur plus de `CEINTURE_MAX` des azimuts, alors il
    existe un replat qui fait presque le tour — c'est la pièce montée.

    L'ancien générateur, qui posait une vire par banc à hauteur constante,
    rendait ici 1,00 : le contrôle mesure bien le défaut rejeté.

    LA FENÊTRE GLISSE, elle ne se range pas dans des cases fixes. Un découpage
    en tranches alignées sur zéro laisserait passer une ceinture posée à cheval
    sur deux cases — le verdict dépendrait alors de l'origine de l'axe, pas de
    la forme. Ici, pour CHAQUE rainure trouvée, on regarde les azimuts qui en
    portent une à moins d'une demi-tranche : même question, sans l'arbitraire.

    ON COMPTE UN ARC CONTIGU, PAS UN TOTAL — et cette correction a été faite
    après une mesure, pas avant. La première écriture comptait TOUS les azimuts
    partageant une hauteur, où qu'ils soient. Deux rainures de même altitude
    sur des faces OPPOSÉES y comptaient double alors qu'aucun regard ne les
    voit ensemble : la grandeur mesurée n'était pas celle qui fait lire
    « dalle ». Et le prix de cette erreur était réel — pour faire tomber le
    chiffre, j'avais raréfié les strates au point de fabriquer une masse lisse,
    c'est-à-dire un autre défaut. Ce qui fait la dalle est une rainure
    CONTINUE sur l'arc qu'on voit d'un coup d'œil, donc c'est un arc contigu
    (cyclique) qu'il faut mesurer, et un plafond de 0,40 vaut ≈ 144° — moins
    que l'arc visible d'une seule vue.

    Même famille que les deux fenêtres de mesure fausses déjà trouvées dans
    cette passe, et que la leçon de `tools/CLAUDE.md` : quand un défaut résiste
    à un contrôle, demander d'abord ce que le contrôle mesure réellement.
    """
    rainures = []
    pas = 240
    for j in range(na):
        theta = math.tau * j / na
        precedent = None
        avant = None
        for k in range(pas + 1):
            t = k / float(pas)
            s = masse.strate(theta, t)
            if precedent is not None and avant is not None:
                if precedent < avant and precedent <= s and precedent < -1e-4:
                    rainures.append(((k - 1) / float(pas) * masse.H, j))
            avant = precedent
            precedent = s
    if not rainures:
        return 0.0, 0
    demi = CEINTURE_TRANCHE_M * 0.5
    pire = 0
    for z0, _ in rainures:
        presents = set(j for z, j in rainures if abs(z - z0) <= demi)
        # Le plus long arc CONTIGU d'azimuts présents, en tenant compte du
        # bouclage : c'est ce qu'un regard voit d'un seul tenant.
        if len(presents) >= na:
            pire = na
            continue
        depart = next(j for j in range(na) if j not in presents)
        courant = 0
        for k in range(1, na + 1):
            j = (depart + k) % na
            courant = courant + 1 if j in presents else 0
            pire = max(pire, courant)
    return pire / float(na), len(rainures)


def _controle_surplombs(masse: Masse, na: int) -> tuple:
    """Les surplombs, mesurés DEUX FOIS parce qu'il y a deux questions.

    Mesuré sur `rayon_lisse` — strates EXCLUES — et au-dessus de t = 0,26,
    donc hors de la zone d'évasement du pied, où un dr/dt > 0 ne serait que le
    talus. Un surplomb ne compte que si le rayon regagne au moins 3,5 % sur
    une remontée continue : sans ce plancher, la moindre remontée après une
    niche compte, et le contrôle rend « partout » sans rien distinguer.

    1. `secteurs` — combien d'azimuts portent un surplomb quelque part. Trop
       peu = masse convexe = caillou. C'est le plancher.
    2. `ceinture` — la plus grande fraction d'azimuts qui surplombent À LA
       MÊME HAUTEUR. C'est le plafond, et c'est la vraie question : un
       bombement local est un surplomb, une remontée simultanée sur tout le
       pourtour est une taille de guêpe. Compter les azimuts qui surplombent
       « quelque part » ne distinguait pas les deux — mesuré à la première
       écriture : 28 sur 28 pour l'éperon, un test qui ne pouvait pas échouer.
    """
    montee = [[False] * na for _ in range(35)]
    for j in range(na):
        theta = math.tau * j / na
        precedent = masse.rayon_lisse(theta, 0.26)
        gain = 0.0
        for k in range(35):
            t = 0.28 + 0.02 * k
            r = masse.rayon_lisse(theta, t)
            if r > precedent:
                gain += r - precedent
                if gain > 0.035:
                    montee[k][j] = True
            else:
                gain = 0.0
            precedent = r
    secteurs = sum(1 for j in range(na) if any(montee[k][j] for k in range(35)))
    ceinture = max(sum(1 for j in range(na) if montee[k][j])
                   for k in range(35)) / float(na)
    return secteurs, ceinture


def _materiau(nom: str, couleur, avec_couleur_sommet: bool = True):
    """Matériau : `Base Color = couleur × attribut « Col »`.

    LE BRANCHEMENT N'EST PAS COSMÉTIQUE (ISS-066) : l'exporter glTF de Blender
    4.0 n'écrit `COLOR_0` que si le MATÉRIAU consomme réellement l'attribut.
    Sans lui, le `.glb` sort avec POSITION et NORMAL seulement — aucune erreur,
    aucun avertissement, un asset silencieusement plat.
    """
    mat = bpy.data.materials.new(nom)
    mat.use_nodes = True
    arbre = mat.node_tree
    principled = arbre.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = couleur
    if avec_couleur_sommet:
        attribut = arbre.nodes.new("ShaderNodeVertexColor")
        attribut.layer_name = "Col"
        attribut.location = (-600, 200)
        melange = arbre.nodes.new("ShaderNodeMix")
        melange.data_type = "RGBA"
        melange.blend_type = "MULTIPLY"
        melange.location = (-300, 200)
        melange.inputs["Factor"].default_value = 1.0
        melange.inputs[6].default_value = couleur
        arbre.links.new(attribut.outputs["Color"], melange.inputs[7])
        arbre.links.new(melange.outputs[2], principled.inputs["Base Color"])
    if "Roughness" in principled.inputs:
        principled.inputs["Roughness"].default_value = 0.94
    if "Metallic" in principled.inputs:
        principled.inputs["Metallic"].default_value = 0.0
    if "Specular IOR Level" in principled.inputs:
        principled.inputs["Specular IOR Level"].default_value = 0.18
    elif "Specular" in principled.inputs:
        principled.inputs["Specular"].default_value = 0.18
    return mat


def main() -> int:
    _purge()
    mat_corps = _materiau("MAT_Crag_Slate", MAT_ARDOISE)
    mat_fracture = _materiau("MAT_Crag_Fracture", MAT_FRACTURE)

    total_tris = 0
    for (nom, hauteur, demi_a, demi_b, jupe, graine, azim_asc, azim_plat,
         azim_enc) in CROCS:
        masse = Masse(hauteur, demi_a, demi_b, jupe, graine, azim_asc,
                      azim_plat, azim_enc)
        objet = _construire(nom, masse, mat_corps, mat_fracture)
        maillage = objet.data
        tris = len(maillage.polygons)
        total_tris += tris

        zs = [v.co.z for v in maillage.vertices]
        xs = [v.co.x for v in maillage.vertices]
        ys = [v.co.y for v in maillage.vertices]
        haut_reel = max(zs)
        fond = min(zs)
        emprise = max(max(xs) - min(xs), max(ys) - min(ys))
        # Emprise VISIBLE : la jupe est enterrée, elle ne compte pas dans la
        # silhouette. Les deux nombres sont publiés — un seul choisirait la
        # réponse avant de mesurer (`tools/CLAUDE.md`).
        sur_sol = [v for v in maillage.vertices if v.co.z >= -0.02]
        e_vis = max(max(v.co.x for v in sur_sol) - min(v.co.x for v in sur_sol),
                    max(v.co.y for v in sur_sol) - min(v.co.y for v in sur_sol))
        aire_max = max(p.area for p in maillage.polygons)

        attribut = maillage.color_attributes.get("Col")
        if attribut is None:
            print("%s ERREUR: %s sans couche de couleur de sommet" % (TAG, nom))
            return 2
        luminances = sorted(
            0.2126 * d.color[0] + 0.7152 * d.color[1] + 0.0722 * d.color[2]
            for d in attribut.data)
        p10 = luminances[len(luminances) // 10]
        p90 = luminances[9 * len(luminances) // 10]
        moyenne = sum(luminances) / len(luminances)
        etendue = (p90 - p10) / max(moyenne, 1e-6)

        na = RESOLUTION[nom][0]
        ceinture, nb_rainures = _controle_ceinture(masse, na)
        surplombs, ceint_surplomb = _controle_surplombs(masse, na)

        print("%s %s : %d tris, hauteur %.3f m, fond de jupe %.3f m, "
              "emprise totale %.3f m, emprise visible %.3f m, "
              "facette max %.4f m2" % (TAG, nom, tris, haut_reel, fond,
                                       emprise, e_vis, aire_max))
        print("%s %s : ceinture max %.2f (plafond %.2f) sur %d rainures, "
              "surplombs %d/%d azimuts (plancher %d), ceinture de surplomb "
              "%.2f (plafond %.2f), couleur moy %.3f p10 %.3f p90 %.3f "
              "(etendue %.1f %%)"
              % (TAG, nom, ceinture, CEINTURE_MAX, nb_rainures, surplombs, na,
                 SURPLOMBS_MIN, ceint_surplomb, SURPLOMBS_MAX_PART,
                 moyenne, p10, p90, 100.0 * etendue))

        if fond > -0.05:
            print("%s ERREUR: %s ne descend pas sous le plan de sol (%.3f) — "
                  "sans jupe le contact redevient une ligne" % (TAG, nom, fond))
            return 2
        if not (hauteur * 0.92 <= haut_reel <= hauteur * 1.08):
            print("%s ERREUR: %s hauteur %.3f hors fourchette autour de %.3f"
                  % (TAG, nom, haut_reel, hauteur))
            return 2
        if ceinture > CEINTURE_MAX:
            print("%s ERREUR: %s une rainure couvre %.0f %% des azimuts dans "
                  "une tranche de %.2f m (> %.0f %%) — c'est un replat qui "
                  "fait le tour, donc la pile de dalles rejetee"
                  % (TAG, nom, 100.0 * ceinture, CEINTURE_TRANCHE_M,
                     100.0 * CEINTURE_MAX))
            return 2
        if surplombs < SURPLOMBS_MIN:
            print("%s ERREUR: %s n'a que %d secteur(s) de surplomb (< %d) — "
                  "une masse convexe partout est un caillou, pas une formation"
                  % (TAG, nom, surplombs, SURPLOMBS_MIN))
            return 2
        if ceint_surplomb > SURPLOMBS_MAX_PART:
            print("%s ERREUR: %s surplombe sur %.0f %% des azimuts A LA MEME "
                  "HAUTEUR (> %.0f %%) — un surplomb qui ceinture n'est pas un "
                  "surplomb, c'est une taille de guepe"
                  % (TAG, nom, 100.0 * ceint_surplomb,
                     100.0 * SURPLOMBS_MAX_PART))
            return 2
        if aire_max > AIRE_FACETTE_MAX:
            print("%s ERREUR: %s porte une facette de %.4f m2 (> %.4f)"
                  % (TAG, nom, aire_max, AIRE_FACETTE_MAX))
            return 2
        if etendue < ETENDUE_COULEUR_MIN:
            print("%s ERREUR: %s etendue de couleur %.1f %% < %.1f %% — "
                  "la face rendrait un aplat" % (TAG, nom, 100.0 * etendue,
                                                 100.0 * ETENDUE_COULEUR_MIN))
            return 2
        if not (COULEUR_MOYENNE_MIN <= moyenne <= COULEUR_MOYENNE_MAX):
            print("%s ERREUR: %s moyenne de couleur %.3f hors bande "
                  "[%.2f ; %.2f] — c'est la regression mesuree de l'iteration "
                  "4 (crete plus sombre que les cailloux de son pied)"
                  % (TAG, nom, moyenne, COULEUR_MOYENNE_MIN,
                     COULEUR_MOYENNE_MAX))
            return 2
        if p90 > 1.0001:
            print("%s ERREUR: %s couleur de sommet > 1 (%.3f) — ecretee a "
                  "l export sans avertissement" % (TAG, nom, p90))
            return 2

    print("%s pendage partage : azimut %.1f deg, angle %.1f deg, courbure %.3f"
          % (TAG, PENDAGE_AZIMUT, PENDAGE_DEG, COURBURE))
    print("%s total %d triangles (plafond %d)" % (TAG, total_tris, BUDGET_TRIS))
    if total_tris > BUDGET_TRIS:
        print("%s ERREUR: budget de triangles depasse" % TAG)
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_OverlookCrags.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("%s source enregistree -> %s" % (TAG, sortie))
    print("FIN NOMINALE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
