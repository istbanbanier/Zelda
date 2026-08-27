#!/usr/bin/env python3
"""SONDE D'HORLOGE — une seule variable change : on ne presse AUCUN F4.

Hypothèse à éprouver : le décrochage d'horloge mesuré (rapport 0,013) est
causé par `mark()`, qui fait une relecture GPU par marqueur. Si c'est vrai,
un enregistrement SANS marqueur doit rendre un rapport proche de 1, et
l'échantillonneur automatique de `DevMode` (`position`, toutes les 1,0 s de
temps moteur, sans capture) devient un traceur d'altitude gratuit.

Contrôle interne : trois phases, repos / sauts / repos, sans jamais toucher
F4. Le nombre d'événements `position` mesure directement le temps moteur.
"""
import sys, time, json, subprocess, pathlib
sys.path.insert(0, "/home/user/Zelda/tools")
import fumee_gravite as G

PHASE_S = 40.0
T_SAUT = 1.7

def main() -> int:
    if G.empreinte(G.ZIP) != G.SHA256_ZIP_ATTENDU:
        print("BLOQUÉ: archive non conforme"); return 3
    import shutil, os
    for d in (G.OUT, G.PROFIL):
        if d.exists(): shutil.rmtree(d)
        d.mkdir(parents=True)
    deballe = G.OUT / "binaire"; deballe.mkdir(parents=True, exist_ok=True)
    subprocess.run(["unzip","-o","-q",str(G.ZIP),"-d",str(deballe)], check=True)
    build = deballe / G.NOM_BINAIRE; build.chmod(0o755)

    xvfb, disp = G.demarrer_xvfb(G.W, G.H)
    if xvfb is None: print("BLOQUÉ: Xvfb"); return 3
    G.DISPLAY = disp
    journal = G.OUT / "jeu_stdout.log"
    env = dict(os.environ, DISPLAY=disp, HOME=str(G.PROFIL),
               XDG_DATA_HOME=str(G.PROFIL/"data"),
               XDG_CONFIG_HOME=str(G.PROFIL/"config"))
    with journal.open("wb") as fh:
        proc = subprocess.Popen(["stdbuf","-oL","-eL",str(build),
                                 "--rendering-driver","opengl3"],
                                stdout=fh, stderr=subprocess.STDOUT, env=env)
        G.PROCS_POSSEDES.append(proc)
        fenetre = ""
        for _ in range(30):
            time.sleep(2)
            r = subprocess.run(["xdotool","search","--onlyvisible","--name",
                                G.TITRE], capture_output=True, text=True,
                               env=dict(os.environ, DISPLAY=disp))
            ids=[x for x in r.stdout.split() if x.strip()]
            if ids: fenetre=ids[-1]; break
        if not fenetre: print("BLOQUÉ: fenêtre"); return 3
        G.xdo("windowfocus","--sync",fenetre); G.xdo("windowraise",fenetre)
        time.sleep(2)
        if not G.attendre_motif(journal,"menu principal",90):
            print("BLOQUÉ: menu"); return 3
        G.xdo("key","Return")
        if not G.attendre_motif(journal,G.JALON,300):
            print("BLOQUÉ: monde"); return 3
        time.sleep(12)
        G.xdo("windowfocus","--sync",fenetre)

        G.xdo("key","F3")                      # enregistrement ON
        t0 = time.time()
        time.sleep(PHASE_S)                    # phase 1 : repos, ZÉRO entrée
        t1 = time.time()
        fin = time.time() + PHASE_S            # phase 2 : sauts, ZÉRO F4
        prochain = time.time()
        while time.time() < fin:
            if time.time() >= prochain:
                G.xdo("key","space"); prochain += T_SAUT
            time.sleep(0.02)
        t2 = time.time()
        time.sleep(PHASE_S)                    # phase 3 : repos de nouveau
        t3 = time.time()
        G.xdo("key","F3")                      # enregistrement OFF
        time.sleep(3)
    G.nettoyer_processus()

    racine = G.PROFIL/"data"/"godot"/"app_userdata"/"Eclats d'Orage"
    evts = G.lire_evenements(racine)
    pos = [e for e in evts if e.get("type")=="position"]
    mar = [e for e in evts if e.get("type")=="marqueur"]
    mural = t3 - t0
    print(f"temps mural enregistré  : {mural:.1f} s")
    print(f"événements position     : {len(pos)}  (= {len(pos):.0f} s moteur)")
    print(f"marqueurs F4            : {len(mar)}  (doit être 0)")
    print(f"RAPPORT horloge         : {len(pos)/mural:.3f}")
    print(f"phases murales          : repos {t1-t0:.0f}s | sauts {t2-t1:.0f}s"
          f" | repos {t3-t2:.0f}s")
    print("\ntrack d'altitude (position, 1 Hz temps moteur) :")
    for e in pos:
        print(f"  t={e['t']:7.2f}  y={e.get('y','?'):6}  fps={e.get('fps','?')}"
              f"  {e.get('etat','?')}")
    out = pathlib.Path("/tmp/probe_horloge_journal.jsonl")
    out.write_text("\n".join(json.dumps(e,ensure_ascii=False) for e in evts),
                   encoding="utf-8")
    print(f"\njournal copié -> {out}")
    return 0

if __name__ == "__main__":
    rc = 3
    try: rc = main()
    finally: G.nettoyer_processus()
    print(f"RC={rc}", flush=True)
