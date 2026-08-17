# Grotte — R2a-3.6 : le dos de l'alcôve

Objectif unique de ce tour, et rien d'autre. Aucun verdict artistique.

| rôle | commit |
|---|---|
| source, `.blend`, `.glb`, manifeste | `c4016c2` |
| base | `43129b3` (tronc) / `d8a3b84` (worktree) |

## La commande, en toutes lettres

```
cd /home/user/zelda-r2a34/seuil_fix
python3 tools/probe_cave_openings.py assets/environment/caves/SM_WaterfallCave.glb
```

**Sans `--rapide`.** Ce drapeau échantillonne dix fois moins et m'a fait
publier des chiffres faux d'un facteur dix au tour précédent, ainsi qu'une
conclusion fausse (« dispersées » là où elles convergeaient). Les deux
journaux versés ici viennent de la commande ci-dessus.

## La cible, localisée avant d'être traitée

En mode complet, les percées convergeaient :

```
19 rayon(s) quittent la galerie en x~-0.23 y~+8.76 z~+1.32  (stations 2,3,4,5,6)
17 rayon(s) quittent la galerie en x~+0.21 y~+8.92 z~+1.37  (stations 3,4,5,6,7)
 4 rayon(s) quittent la galerie en x~+0.65 y~+9.09 z~+1.48  (stations 6,7)
```

Quarante rayons, six stations d'alimentation, quand **toutes** les autres
mailles plafonnaient à trois.

Rapportées aux sections de `CAVITE`, les trois fuites tombent sur celle de la
**station 6** :

| | écart hors section | rayon le long de −normale |
|---|---:|---:|
| station 5 | 1,92 m | 2,06 m |
| **station 6** | **0,21 m** | **2,17 m** |
| station 7 | 1,39 m | 2,05 m |

soit l'azimut ≈ 153°, le rayon ≈ 2,8 m, `v ≈ 0,45` — c'est-à-dire le dos de
la poche, à mi-hauteur.

## Pourquoi la gaine ne les couvrait pas

Elle porte pourtant la poussée d'alcôve depuis R2a-3.5. Mais elle **se pose
en X** : `ax + rayon·cos θ`. À la station 6, la normale au chemin est à 26,6°
de X ; à 4,06 m de rayon, la couronne se retrouve **déplacée de 1,87 m** du
flanc réel.

Poser la gaine entière sur la normale a été essayé au tour précédent et
refusé : `controle_epaisseur` tombait de 1,09 à 0,60 m, parce que ce contrôle
tire lui aussi ses rayons dans le plan `(cos θ, 0, sin θ)`.

**On ne déplace donc rien : on ajoute.**

## `rochers_dos_alcove()` — dérivée, pas posée

Neuf roches. La position de chacune est le **point de paroi** que
`anneau_interieur()` calcule pour l'alcôve : même `le_long`, même `fenetre`,
même gaussienne en `v`, même normale. Si `ALCOVE` change, le remblai suit ;
aucune cote n'est recopiée.

Elle **ne peut pas** toucher la composition : son sommet est plafonné à
`DOS_ALCOVE_PLAFOND_M = 4,20 m`, sous les deux cols mesurés (4,58 m à l'est,
5,65 m à l'ouest). C'est la leçon des quatre refus précédents — toute matière
ajoutée autour du tube remonte vers un col, donc une famille qui n'a pas à
monter se plafonne. Vérifié statiquement avant génération : sommets réels
2,15 à 3,68 m.

## Avant / après

| | avant (`d8a3b84`) | après (`c4016c2`) |
|---|---|---|
| percées | 113 | **73** |
| plus grosse maille | **19 rayons** | **3 rayons** |
| zone `y ≈ 8,8–9,1` | 40 rayons | **absente de la liste** |
| plancher | 454 points, 0 faute | 454 points, 0 faute |
| fond de galerie | « aucune case ouverte » | « aucune case ouverte » |

Les huit plus grosses mailles restantes comptent 3, 3, 3, 2, 2, 2, 2, 2
rayons : **plus aucune convergence**, ce qui est le critère du lead pour des
points isolés.

## La composition n'a pas bougé d'un centimètre

```
masse epaule_gauche     largeur 5.66 m  faite 7.32 m  proeminence 1.67  porteurs 8
masse dominante         largeur 3.58 m  faite 9.52 m  proeminence 7.57  porteurs 5
masse contrefort_droit  largeur 2.17 m  faite 7.06 m  proeminence 2.53  porteurs 4
    (100°)              6.42 / 3.64 / 2.22            1.51 / 7.53 / 2.47
```

Identiques à R2a-3.5. `controle_amas` vert.

## Chaîne, RC = 0

```
202 roches : 90 gaine (dont 9 dos d'alcove), 53 semelle, 35 majeur,
             16 intermediaire, 8 secondaire
budget            : 19 954 tris dans [12 000 ; 25 000]
epaisseur         : 1.09 m en paroi, 0.61 m au linteau — INCHANGEE
plancher          : 96 points sondes vers le bas, 0 faute
export            : VALIDE, 20 834 triangles
runner filtre     : 67 reussis, 0 echoue
```

## Ce qui reste ouvert

* **73 percées isolées** — le verdict global de la sonde reste `FAIL`, donc
  `PARTIAL`. Aucune ne converge ; elles se répartissent sur les huit stations
  et deux d'entre elles (`x~+2,2 ; y~0,0`) relèvent de la collerette mince.
* **Linteau à 0,61 m**, **contrefort « en retrait »**, comme convenu : partent
  au lead en `NON SATISFAITE`, avec leurs mesures et leurs refus motivés.
* Une seule tentative a été nécessaire sur les deux accordées.
