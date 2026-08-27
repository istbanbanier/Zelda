"""Combien de temps coûte UN marqueur F4 ? Mesuré, pas supposé.
On lance le jeu à trois résolutions et on envoie 8 F4 aussi vite que possible.
La cadence obtenue dit si un vol de 0,683 s est résoluble."""
import json, os, select, subprocess, sys, time, shutil
from pathlib import Path

BUILD = Path("/home/user/smoke_lot1r2/resultat_gravite/binaire/EclatsDOrage.x86_64")
PROCS = []

def xvfb(w, h):
    r, wfd = os.pipe()
    p = subprocess.Popen(["Xvfb", "-displayfd", str(wfd), "-screen", "0", f"{w}x{h}x24"],
                         pass_fds=(wfd,), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    PROCS.append(p); os.close(wfd)
    select.select([r], [], [], 15)
    with os.fdopen(r) as f: n = f.readline().strip()
    return f":{n}"

def essai(w, h):
    prof = Path(f"/tmp/probe_{w}x{h}")
    if prof.exists(): shutil.rmtree(prof)
    prof.mkdir(parents=True)
    disp = xvfb(w, h)
    env = dict(os.environ, DISPLAY=disp, HOME=str(prof),
               XDG_DATA_HOME=str(prof/"data"), XDG_CONFIG_HOME=str(prof/"config"))
    log = prof/"out.log"
    with log.open("wb") as fh:
        p = subprocess.Popen(["stdbuf","-oL","-eL",str(BUILD),"--rendering-driver","opengl3",
                              "--resolution",f"{w}x{h}"], stdout=fh, stderr=subprocess.STDOUT, env=env)
        PROCS.append(p)
        win = ""
        for _ in range(30):
            time.sleep(2)
            r = subprocess.run(["xdotool","search","--onlyvisible","--name","Eclats d'Orage"],
                               capture_output=True, text=True, env=dict(os.environ, DISPLAY=disp))
            ids=[x for x in r.stdout.split() if x.strip()]
            if ids: win=ids[-1]; break
        if not win: print(f"{w}x{h}: PAS DE FENETRE"); return
        def xdo(*a): subprocess.run(["xdotool",*a],capture_output=True,env=dict(os.environ,DISPLAY=disp),timeout=30)
        xdo("windowfocus","--sync",win); time.sleep(2)
        # On reste au MENU : mark() capture l'ecran quelle que soit la scene,
        # donc le cout de la capture se mesure sans monter le monde.
        xdo("key","F3"); time.sleep(2)
        for _ in range(8):
            xdo("key","F4"); time.sleep(0.05)
        time.sleep(4); xdo("key","F3"); time.sleep(2)
        p.terminate(); p.wait(timeout=20)
    js = sorted(prof.glob("**/dev_sessions/*/journal.jsonl"))
    ts=[]
    if js:
        for l in open(js[-1],encoding="utf-8"):
            try: e=json.loads(l)
            except Exception: continue
            if e.get("type")=="marqueur": ts.append(float(e.get("t",0)))
    d=[round(ts[i+1]-ts[i],3) for i in range(len(ts)-1)]
    print(f"{w}x{h}: {len(ts)} marqueur(s) sur 8 ; ecarts {d} ; median {sorted(d)[len(d)//2] if d else '-'}")

for w,h in [(1024,768),(400,300),(200,150)]:
    essai(w,h)
for p in reversed(PROCS):
    if p.poll() is None:
        p.terminate()
        try: p.wait(timeout=10)
        except Exception: p.kill()
