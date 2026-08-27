"""Même sonde de cadence, mais MONDE MONTÉ. Une seule variable change par
rapport à la sonde au menu, qui donnait 0,070 s."""
import json, os, select, subprocess, shutil, time
from pathlib import Path
BUILD = Path("/home/user/smoke_lot1r2/resultat_gravite/binaire/EclatsDOrage.x86_64")
PROCS = []
def xvfb(w,h):
    r,wf=os.pipe()
    p=subprocess.Popen(["Xvfb","-displayfd",str(wf),"-screen","0",f"{w}x{h}x24"],
        pass_fds=(wf,),stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    PROCS.append(p); os.close(wf); select.select([r],[],[],15)
    with os.fdopen(r) as f: return f":{f.readline().strip()}"
prof=Path("/tmp/probe_monde")
if prof.exists(): shutil.rmtree(prof)
prof.mkdir(parents=True)
disp=xvfb(1024,768)
env=dict(os.environ,DISPLAY=disp,HOME=str(prof),
    XDG_DATA_HOME=str(prof/"data"),XDG_CONFIG_HOME=str(prof/"config"))
log=prof/"out.log"
with log.open("wb") as fh:
    p=subprocess.Popen(["stdbuf","-oL","-eL",str(BUILD),"--rendering-driver","opengl3"],
        stdout=fh,stderr=subprocess.STDOUT,env=env); PROCS.append(p)
    def xdo(*a): subprocess.run(["xdotool",*a],capture_output=True,
        env=dict(os.environ,DISPLAY=disp),timeout=30)
    win=""
    for _ in range(30):
        time.sleep(2)
        r=subprocess.run(["xdotool","search","--onlyvisible","--name","Eclats d'Orage"],
            capture_output=True,text=True,env=dict(os.environ,DISPLAY=disp))
        ids=[x for x in r.stdout.split() if x.strip()]
        if ids: win=ids[-1]; break
    xdo("windowfocus","--sync",win); time.sleep(2)
    fin=time.time()+90
    while time.time()<fin and "menu principal" not in log.read_text(errors="replace"): time.sleep(1)
    xdo("key","Return")
    fin=time.time()+300
    while time.time()<fin and "fondation V2 vérifiée" not in log.read_text(errors="replace"): time.sleep(2)
    monte = "fondation V2 vérifiée" in log.read_text(errors="replace")
    print("monde monté :", monte, flush=True)
    time.sleep(12)
    xdo("windowfocus","--sync",win)
    xdo("key","F3"); time.sleep(2)
    t0=time.time()
    for _ in range(8):
        xdo("key","F4"); time.sleep(0.05)
    print(f"8 F4 envoyés en {time.time()-t0:.2f} s de temps mural", flush=True)
    time.sleep(5); xdo("key","F3"); time.sleep(3)
    p.terminate(); p.wait(timeout=20)
js=sorted(prof.glob("**/dev_sessions/*/journal.jsonl"))
ts=[];sac=[]
for l in open(js[-1],encoding="utf-8"):
    e=json.loads(l)
    if e.get("type")=="marqueur": ts.append(float(e["t"]))
    if e.get("type")=="saccade": sac.append(e["ms"])
d=[round(ts[i+1]-ts[i],3) for i in range(len(ts)-1)]
print(f"MONDE MONTÉ : {len(ts)} marqueur(s) sur 8 ; écarts {d}")
print(f"saccades >100ms : {len(sac)} -> {sac[:8]}")
for q in reversed(PROCS):
    if q.poll() is None:
        q.terminate()
        try: q.wait(timeout=10)
        except Exception: q.kill()
