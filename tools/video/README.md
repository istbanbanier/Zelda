# tools/video — séquence de stabilité §30.1 (reproductible)

Chaîne complète, depuis un arbre COMMITTÉ :

```bash
xvfb-run -a -s "-screen 0 960x540x24" "$GODOT_BIN" --path . \
  --rendering-driver opengl3 --audio-driver Dummy \
  scenes/lookdev/StabilityDolly.tscn \
  --write-movie /tmp/dolly/frame.png --fixed-fps 12
python3 tools/video/probe_hold.py /tmp/dolly/frame      # sondes vent/ciel
python3 tools/video/assemble_webp.py /tmp/dolly/frame \
  evidence/cycle3/herolab_v6_stabilite.webp 12
```

Sondes (`probe_hold.py`) : diffs de luminance moyenne (0-255, PIL) sur
la PHASE IMMOBILE (36 premières frames) — zone d'herbe bas-gauche
(0,0-41 % X × 62-100 % Y de l'image 1152×648) entre frames espacées de
0,5 s ; sans parallaxe, toute différence vient du vent, de la tempête
ou d'une instabilité. Contrôle : bande de ciel (26-78 % X × 0-19 % Y),
attendue quasi nulle hors flash. Référence : herbe FIGÉE = 0,00 ;
vent du lot 3 = 1,6-2,0. Rendu logiciel : jamais une mesure de
performance (ISS-002).
