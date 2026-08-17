"""COLLERETTE DANS LE PLAN DE BOUCHE — EDT euclidienne sur GRILLE + coupe minimale.

    blender --background --python-exit-code 1 \\
        --python tools/blender/probe_cave_edt_plan_bouche.py -- \\
        --glb assets/environment/caves/SM_WaterfallCave.glb [--pas 0.04] ...

    blender --background <blend> --python-exit-code 1 \\
        --python tools/blender/probe_cave_edt_plan_bouche.py -- --objet SM_WaterfallCave

=============================================================================
DOMAINE DE VALIDITE — a lire avant de citer un chiffre de ce fichier
=============================================================================

`EXPLOITABLE, AVEC DEUX RESERVES MESUREES` — banc :
`tools/cave_edt_calibration.py`, journal `banc_verdict.log`, 2026-08-16.

Ce que cet instrument mesure exactement : le GOULOT DE LA COUPE MINIMALE
dans UN plan, exprime comme `2 x rayon d'erosion`. C'est la plus grande
erosion que la roche supporte avant que le vide de l'ouverture communique
avec le vide exterieur.

Ce n'est PAS une « distance exacte ». C'est une **distance exacte SUR LA
GRILLE DISCRETE**, de centre de case a centre de case.

RESERVE 1 — IL SOUS-ESTIME D'ENVIRON UNE MAILLE. Mesure sur 20 cas du banc,
huit formes, quatre pas : le biais est NEGATIF PARTOUT, entre -0,0234 et
-0,0785 m, soit -0,76 a -1,12 fois le pas. Sur un anneau de reponse
0,7996 m :

    pas     0,100    0,050    0,040    0,025
    biais  -0,0785  -0,0380  -0,0449  -0,0234

Consequence pratique, et elle est confortable : **la lecture brute est deja
une borne inferieure** de l'epaisseur reelle, pour la classe de formes du
banc. `2*seuil - pas` reste disponible comme marge de securite doublee.
Cela vaut pour dalles droites, inclinees de 0 a 45 degres et frontieres
irregulieres — PAS universellement. Ne jamais la presenter comme une
garantie generale.

RESERVE 2 — IL PEUT ECHOUER FRANCHEMENT, PAS SEULEMENT DERIVER. Voir le
defaut connu plus bas : sur la forme `rasant` du banc, au pas 0,04, il rend
**0,08 m pour une reponse de 0,60 m** — une erreur de -0,52 m, pas un biais.
Un chiffre de cet instrument ne doit donc jamais etre cite seul : il se
recoupe avec `cave_collar.py`, dont le vote a quatre parites tient sur la
meme forme (biais +0,0003 m).

=============================================================================
CE FICHIER EST UN PORTAGE, PAS UNE REECRITURE
=============================================================================

Original : `b_collerette/tools/blender/probe_cave_edt_plan_bouche.py`,
sha256 `bda6fe9a14efb9bd...`, ecrit par l'agent collerette.

Ce qui a change, et RIEN d'autre :

  * LA SOURCE DES DONNEES. L'original lit `bpy.data.objects[...]` du
    `.blend` ouvert. Cette copie sait aussi importer un `.glb`, afin que cet
    instrument et `tools/cave_collar.py` mesurent LES MEMES OCTETS. Sans
    cela, comparer leurs chiffres compare aussi deux fichiers.
  * LA PARAMETRISATION. `PAS`, `Y`, la boite et la graine d'ouverture
    etaient des constantes de module ; elles deviennent des arguments, sans
    quoi aucune etude de convergence n'est possible.
  * `matrix_world` est applique aux sommets. L'original suppose l'identite,
    ce qui est vrai du `.blend` et FAUX d'un objet importe depuis glTF.
  * une sortie JSON, et l'impression de la borne conservatrice.

CE QUI N'A PAS CHANGE, ET NE DOIT PAS CHANGER : `edt1d` (Felzenszwalb, deux
passes sur les distances au carre), `compo`, l'union-find, le critere de
goulot, l'ordre de parcours, et le test de parite `dedans()`. Un instrument
de controle ajuste pour ressembler a celui qu'il controle ne controle plus
rien.

EQUIVALENCE EXIGEE AVANT TOUT USAGE : cette copie doit rendre 1,040 m sur
`cc3596c5`, chiffre publie par l'agent B avec l'original. Si elle ne le rend
pas, on ne « corrige » pas jusqu'a l'obtenir : on rapporte l'ecart.

=============================================================================
DEFAUT CONNU, HERITE DE L'ORIGINAL ET NON CORRIGE
=============================================================================

`dedans()` vote sur UNE SEULE direction (+Z). C'est exactement le defaut que
`cave_collar.coupe_du_plan` a d'abord porte puis corrige par un vote sur
quatre parites : un rayon qui rase une arete perd une intersection et la
parite de toute la fin de colonne s'inverse. Sur le cylindre de calibration,
ce defaut avait declare « air libre » les 18 289 cases creuses.

Il n'est PAS corrige ici, et c'est delibere : corriger le controleur pour
qu'il ressemble au controle detruit l'independance. Le banc le MESURE a la
place — voir `tools/cave_edt_calibration.py`.
"""

import bpy, math, sys, os, json
from mathutils import Vector
from mathutils.bvhtree import BVHTree


def _arguments(argv):
    """Arguments apres `--`. Pas d'argparse : bpy en avale une partie."""
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    opts = dict(glb=None, objet="SM_WaterfallCave", pas=0.04, y=-1.15,
                x0=-4.40, x1=3.60, z0=-0.80, z1=4.40,
                graine_x=0.0, graine_z=1.10, json=None, profil=1)
    i = 0
    while i < len(argv):
        cle = argv[i].lstrip("-").replace("-", "_")
        if cle not in opts:
            raise SystemExit("[edt] argument inconnu : %s" % argv[i])
        val = argv[i + 1]
        if cle in ("glb", "objet", "json"):
            opts[cle] = val
        elif cle == "profil":
            opts[cle] = int(val)
        else:
            opts[cle] = float(val)
        i += 2
    return opts


O = _arguments(list(sys.argv))
PAS = O["pas"]
Y = O["y"]
X0, X1 = O["x0"], O["x1"]
Z0, Z1 = O["z0"], O["z1"]

if O["glb"]:
    # SOURCE GLB. On vide la scene pour qu'aucun objet d'un `.blend` ouvert
    # ne se melange a l'import, puis on cherche l'objet par nom.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(O["glb"]))
    candidats = [x for x in bpy.data.objects
                 if x.type == "MESH" and x.name.split(".")[0] == O["objet"]]
    if not candidats:
        raise SystemExit("[edt] objet %s absent du glb %s (presents : %s)"
                         % (O["objet"], O["glb"],
                            ", ".join(x.name for x in bpy.data.objects)))
    o = candidats[0]
    print("[edt] source GLB : %s -> objet %s" % (O["glb"], o.name))
else:
    o = bpy.data.objects[O["objet"]]
    print("[edt] source BLEND : objet %s" % o.name)

# matrix_world APPLIQUE. L'original lisait `v.co` brut, ce qui suppose
# l'identite : vrai du .blend, faux d'un objet importe depuis glTF, ou
# l'importeur pose une rotation pour repasser de Y-up a Z-up.
M = o.matrix_world
sv = [M @ v.co for v in o.data.vertices]
pl = [tuple(p.vertices) for p in o.data.polygons]
t = BVHTree.FromPolygons(sv, pl, all_triangles=False, epsilon=0.0)
up = Vector((0, 0, 1.0))
lo = [min(v[k] for v in sv) for k in range(3)]
hi = [max(v[k] for v in sv) for k in range(3)]
print("[edt] %d sommets, %d polygones, bbox x %.3f..%.3f y %.3f..%.3f "
      "z %.3f..%.3f" % (len(sv), len(pl), lo[0], hi[0], lo[1], hi[1],
                        lo[2], hi[2]))


def dedans(x, z):
    n = 0
    dep = Vector((x, Y, z))
    for _ in range(64):
        h = t.ray_cast(dep, up, 60.0)
        if h is None or h[0] is None:
            break
        n += 1
        dep = h[0] + up * 1e-4
    return n % 2 == 1


W = int(round((X1 - X0) / PAS))
H = int(round((Z1 - Z0) / PAS))
roche = [[dedans(X0 + (i + 0.5) * PAS, Z0 + (j + 0.5) * PAS)
          for j in range(H)] for i in range(W)]
print("[edt] grille %dx%d, pas %.4f m, plan y=%.2f" % (W, H, PAS, Y))

INF = 1e18


def edt1d(f):
    n = len(f)
    v = [0] * n
    z = [0.0] * (n + 1)
    k = 0
    v[0] = 0
    z[0] = -INF
    z[1] = INF
    for q in range(1, n):
        while True:
            s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2.0 * q - 2.0 * v[k])
            if s <= z[k]:
                k -= 1
            else:
                break
        k += 1
        v[k] = q
        z[k] = s
        z[k + 1] = INF
    k = 0
    out = [0.0] * n
    for q in range(n):
        while z[k + 1] < q:
            k += 1
        out[q] = (q - v[k]) ** 2 + f[v[k]]
    return out


# EDT^2 sur les cellules de ROCHE, distance au VIDE le plus proche
g = [[0.0 if not roche[i][j] else INF for j in range(H)] for i in range(W)]
for i in range(W):
    g[i] = edt1d(g[i])
cols = [[g[i][j] for i in range(W)] for j in range(H)]
for j in range(H):
    cols[j] = edt1d(cols[j])
dt = [[math.sqrt(cols[j][i]) * PAS for j in range(H)] for i in range(W)]


# composantes de vide : celle du dehors (bord de grille) et celle de l'ouverture
def compo(depart):
    vu = [[False] * H for _ in range(W)]
    pile = list(depart)
    for i, j in depart:
        vu[i][j] = True
    while pile:
        i, j = pile.pop()
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            a, b = i + di, j + dj
            if 0 <= a < W and 0 <= b < H and not vu[a][b] and not roche[a][b]:
                vu[a][b] = True
                pile.append((a, b))
    return vu


bord = [(i, j) for i in range(W) for j in (0, H - 1) if not roche[i][j]] + \
       [(i, j) for j in range(H) for i in (0, W - 1) if not roche[i][j]]
dehors = compo(bord)
ia = int((O["graine_x"] - X0) / PAS)
ja = int((O["graine_z"] - Z0) / PAS)
if not (0 <= ia < W and 0 <= ja < H):
    raise SystemExit("[edt] ERREUR: graine d'ouverture hors de la boite")
if roche[ia][ja]:
    raise SystemExit("[edt] ERREUR: le point d'ouverture est dans la roche")
ouv = compo([(ia, ja)])
deja = bool(dehors[ia][ja])
print("[edt] l'ouverture est-elle DEJA reliee au dehors ? %s" % deja)

# goulot : union-find sur cellules de roche triees par dt croissante
parent = list(range(W * H + 2))
DEH = W * H
OUV = W * H + 1


def rac(x):
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x


def uni(a, b):
    ra, rb = rac(a), rac(b)
    if ra != rb:
        parent[ra] = rb


actif = [[False] * H for _ in range(W)]
cells = sorted((dt[i][j], i, j) for i in range(W) for j in range(H)
               if roche[i][j])
seuil = None
ou = None
for d, i, j in cells:
    actif[i][j] = True
    k = i * H + j
    for di in (-1, 0, 1):
        for dj in (-1, 0, 1):
            a, b = i + di, j + dj
            if not (0 <= a < W and 0 <= b < H) or (di == 0 and dj == 0):
                continue
            if roche[a][b] and actif[a][b]:
                uni(k, a * H + b)
            elif not roche[a][b]:
                if dehors[a][b]:
                    uni(k, DEH)
                if ouv[a][b]:
                    uni(k, OUV)
    if rac(DEH) == rac(OUV):
        seuil = d
        ou = (X0 + (i + 0.5) * PAS, Z0 + (j + 0.5) * PAS)
        break

if seuil is None:
    print("[edt] AUCUN goulot : l'ouverture et le dehors ne se rejoignent "
          "jamais par la roche (forme close ?)")
    collerette = None
    borne = None
else:
    collerette = 2.0 * seuil
    borne = max(0.0, collerette - PAS)
    print("[edt] GOULOT : demi-epaisseur %.4f m -> COLLERETTE %.4f m, "
          "au (x %.2f, z %.2f)" % (seuil, collerette, ou[0], ou[1]))
    # LA BORNE, ET POURQUOI ELLE EXISTE. La classification est prise au
    # CENTRE des cases : selon la phase de la forme dans la grille, le
    # goulot vaut `t` ou `t + pas` sur une dalle d'epaisseur `t`. On publie
    # donc la lecture ET la borne inferieure, jamais la lecture seule.
    print("[edt] BORNE INFERIEURE CONSERVATRICE (lecture - pas) : %.4f m"
          % borne)
    print("[edt] distance exacte SUR LA GRILLE, pas distance exacte.")

if O["profil"]:
    # profil : max de dt le long du bandeau, par tranche de z, cote droit
    print("[edt] plus grande dt de roche par tranche z, cote x>0.6 (m) :")
    for jz in range(0, H, max(1, int(round(0.20 / PAS)))):
        z = Z0 + (jz + 0.5) * PAS
        best = 0.0
        bx = None
        for i in range(W):
            x = X0 + (i + 0.5) * PAS
            if x > 0.6 and roche[i][jz] and dt[i][jz] > best:
                best, bx = dt[i][jz], x
        if bx is not None and z < 3.0:
            print("[edt]   z=%5.2f  2*dt=%.3f m  a x=%.2f" % (z, 2 * best, bx))

if O["json"]:
    with open(O["json"], "w", encoding="utf-8") as poignee:
        json.dump(dict(source=O["glb"] or "blend", objet=o.name, pas=PAS,
                       plan_y=Y, boite=[X0, X1, Z0, Z1],
                       grille=[W, H], graine=[O["graine_x"], O["graine_z"]],
                       ouverture_deja_reliee=deja,
                       demi_epaisseur_m=seuil, collerette_m=collerette,
                       borne_inferieure_m=borne,
                       point=list(ou) if ou else None), poignee, indent=1)
    print("[edt] json : %s" % O["json"])
