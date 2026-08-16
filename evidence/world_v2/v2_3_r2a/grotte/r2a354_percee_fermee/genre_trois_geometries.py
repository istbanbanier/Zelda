import sys
sys.path.insert(0, "/home/user/zelda-r2a354/a_percee/tools")
from cave_topology_check import analyser
for c, e in [("/tmp/nc/original.glb", "AVANT sabotage"),
             ("/tmp/nc/sabote.glb", "APRES sabotage")]:
    analyser(c, e)
