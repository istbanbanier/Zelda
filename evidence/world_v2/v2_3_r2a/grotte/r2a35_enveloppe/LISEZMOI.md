# R2a-3.5 — prototypes d'enveloppe : comment lire ces images

Ce dossier ne contient **aucun verdict**. Il contient des silhouettes et de
quoi les reproduire. Le jugement appartient au lead.

## Le piège de nommage, à lire avant tout

Les prototypes sont des GLB **isolés** : le lacet d'implantation de 45°
(`LACET_DEG`) n'est pas cuit dans le maillage, il est appliqué côté Godot par
`waterfall_cave_place.gd`. Les azimuts de capture sont donc décalés de 45° par
rapport à ceux de R2a-3.4, qui capturait le lieu **monté dans le monde**.

| fichier | azimut écrit | azimut MONDE équivalent | vue |
|---|---:|---:|---|
| `silhouette_proto?_100.png` | 100° | **55°** | approche du joueur |
| `silhouette_proto?_145.png` | 145° | **100°** | second azimut |
| `silhouette_proto?_270.png` | 270° | **225°** | arrière, de dos |

Les trois planches `planche_monde_*.png` sont, elles, titrées en azimut
**monde**, et mettent R2a-3.4 en première vignette quand une contrepartie
existe. Il n'y a pas de contrepartie arrière : R2a-3.4 n'a livré aucune
silhouette de dos.

Deuxième écart à ne pas confondre : R2a-3.4 était capturé en mode « lieu dans
le monde monté » avec `--clip-below=3.0` (altitude du plateau) ; ces
prototypes le sont en mode « asset isolé » avec `--clip-below=0.0` (leur sol
local). Les deux excluent la semelle enterrée du cadrage, mais la géométrie
sous le sol reste **rendue** — les hauteurs mesurées sur l'image partent donc
de `Z_PIED = -1,35 m`, pas de 0.

## Reproduire

```bash
flock /home/user/Zelda/.git/heavy_tools.lock -c 'cd <worktree> && \
  blender --background --python-exit-code 1 \
    --python source_assets/blender/environment/make_cave_envelope_protos.py && \
  godot --headless --path . --import && \
  for P in A B C; do \
    xvfb-run -a -s "-screen 0 1400x1500x24" godot --path . \
      --script tools/godot/capture_silhouette.gd -- \
      --scene=res://assets/environment/caves/prototypes/SM_CaveEnvelope_Proto$P.glb \
      --out-dir=evidence/world_v2/v2_3_r2a/grotte/r2a35_enveloppe \
      --name=proto$P --angles=100,145,270 --size=900x1200 --clip-below=0.0; \
  done'
```

`--headless` ne rend rien : `capture_silhouette.gd` sort alors en 2 sur
« rendu nul ». Il faut `xvfb-run` **sans** `--headless`, comme le fait
`tools/validate_release.sh`.

Télémétrie des masses (jamais un critère de réussite, cf. le verdict du lead) :

```bash
python3 tools/measure_silhouette_masses.py \
  evidence/world_v2/v2_3_r2a/grotte/r2a35_enveloppe/manifest_silhouettes_protoA.json \
  --entaille=0.60
```

## Ce que ces prototypes ne sont pas

Ni cavité, ni bouche, ni galerie, ni alcôve, ni matériau, ni strate, ni module
de détail, ni collision. Aucun n'est intégré au tronc, et
`SEUIL_LOCAL` / `LACET_DEG` / `EXHAUSSEMENT` / `APPUIS_MODELE` n'ont pas bougé.
