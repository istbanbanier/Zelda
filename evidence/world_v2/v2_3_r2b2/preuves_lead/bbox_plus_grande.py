import sys
from collections import deque
from PIL import Image
RAYON, SEUIL, MIN_C = 3, 18, 1500
def famille(c):
    r,v,b=c
    if r>60 and r>v>b and 18<(r-b)<110: return "beige"
    if max(c)-min(c)<=16: return "gris/neutre"
    if v>r and v>b: return "vert"
    if b>=r and b>=v: return "bleu"
    return "chaud hors beige"
def run(p):
    im=Image.open(p).convert("RGB"); L,H=im.size; px=im.load()
    plat=[[False]*H for _ in range(L)]
    for x in range(RAYON,L-RAYON):
        for y in range(RAYON,H-RAYON):
            c=px[x,y]; uni=True
            for dx,dy in ((RAYON,0),(-RAYON,0),(0,RAYON),(0,-RAYON)):
                n=px[x+dx,y+dy]
                if abs(c[0]-n[0])+abs(c[1]-n[1])+abs(c[2]-n[2])>SEUIL: uni=False;break
            plat[x][y]=uni
    vu=[[False]*H for _ in range(L)]; best=None
    for x in range(RAYON,L-RAYON):
        for y in range(RAYON,H-RAYON):
            if not plat[x][y] or vu[x][y]: continue
            q=deque([(x,y)]); vu[x][y]=True
            pts=[]; fams={}
            while q:
                cx,cy=q.popleft(); pts.append((cx,cy))
                f=famille(px[cx,cy]); fams[f]=fams.get(f,0)+1
                for nx,ny in ((cx+1,cy),(cx-1,cy),(cx,cy+1),(cx,cy-1)):
                    if RAYON<=nx<L-RAYON and RAYON<=ny<H-RAYON and plat[nx][ny] and not vu[nx][ny]:
                        vu[nx][ny]=True; q.append((nx,ny))
            if len(pts)>=MIN_C and (best is None or len(pts)>len(best[0])):
                best=(pts,fams)
    pts,fams=best
    xs=[a for a,_ in pts]; ys=[b for _,b in pts]
    dom=max(fams.items(),key=lambda kv:kv[1])[0]
    r=sum(px[a,b][0] for a,b in pts)//len(pts); g=sum(px[a,b][1] for a,b in pts)//len(pts); bl=sum(px[a,b][2] for a,b in pts)//len(pts)
    print(f"{p}")
    print(f"  plus grande composante plate : {100.0*len(pts)/(L*H):.2f} %  famille {dom}")
    print(f"  boite  X {min(xs)}..{max(xs)}  Y {min(ys)}..{max(ys)}  (image {L}x{H})")
    print(f"  couleur moyenne RGB ({r},{g},{bl})")
    print(f"  remplissage de sa boite : {100.0*len(pts)/max(1,(max(xs)-min(xs)+1)*(max(ys)-min(ys)+1)):.0f} %")
for p in sys.argv[1:]: run(p)
