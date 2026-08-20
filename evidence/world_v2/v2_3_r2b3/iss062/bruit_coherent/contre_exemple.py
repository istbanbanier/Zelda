#!/usr/bin/env python3
"""CONTRE-EXEMPLE ADVERSE ISS-062 : boites soudees + bruit COHERENT.

Part du GLB deja sabote (boites droites soudees par les coins) et deplace
CHAQUE POSITION UNIQUE d'un vecteur pseudo-aleatoire borne. Le bruit est
applique par POSITION et non par SOMMET : les coins soudes le restent, donc
le nombre de composantes ne bouge pas et `mesure_boititude.py` reste aveugle.
Mais les faces cessent d'etre des quadrilateres plans a angles droits, donc
`mesure_rectangularite.py` s'effondre.
"""
import json, struct, sys, hashlib

GLB_MAGIC=0x46546C67; CJSON=0x4E4F534A; CBIN=0x004E4942

def lire(p):
    d=open(p,'rb').read()
    magic,ver,total=struct.unpack_from('<III',d,0)
    assert magic==GLB_MAGIC
    off=12; js=None; bina=None
    while off<total:
        ln,ty=struct.unpack_from('<II',d,off); off+=8
        ch=d[off:off+ln]; off+=ln
        if ty==CJSON: js=json.loads(ch.decode('utf-8'))
        elif ty==CBIN: bina=bytearray(ch)
    return js,bina

def ecrire(p,js,bina):
    jb=json.dumps(js,separators=(',',':')).encode('utf-8')
    jb+=b' '*((4-len(jb)%4)%4)
    bb=bytes(bina); bb+=b'\0'*((4-len(bb)%4)%4)
    total=12+8+len(jb)+8+len(bb)
    out=struct.pack('<III',GLB_MAGIC,2,total)
    out+=struct.pack('<II',len(jb),CJSON)+jb
    out+=struct.pack('<II',len(bb),CBIN)+bb
    open(p,'wb').write(out)

def bruit(v, amp):
    h=hashlib.sha256(("%.6f_%.6f_%.6f"%v).encode()).digest()
    return tuple(v[i]+((h[i]/255.0)*2.0-1.0)*amp for i in range(3))

src,dst,amp=sys.argv[1],sys.argv[2],float(sys.argv[3])
js,bina=lire(src)
cibles={"SM_Farm_Debris_A","SM_Farm_Debris_B"}
acc_ids=set()
for m in js["meshes"]:
    if m.get("name") in cibles:
        for pr in m["primitives"]:
            acc_ids.add(pr["attributes"]["POSITION"])

# 1) collecte de toutes les positions uniques des meshes cibles
table={}
lus=[]
for a in sorted(acc_ids):
    acc=js["accessors"][a]; bv=js["bufferViews"][acc["bufferView"]]
    base=bv.get("byteOffset",0)+acc.get("byteOffset",0)
    stride=bv.get("byteStride") or 12
    assert acc["componentType"]==5126 and acc["type"]=="VEC3"
    for i in range(acc["count"]):
        o=base+i*stride
        v=struct.unpack_from('<fff',bina,o)
        k=tuple(round(x,6) for x in v)
        if k not in table: table[k]=bruit(k,amp)
        lus.append((o,k))
# 2) reecriture
for o,k in lus:
    struct.pack_into('<fff',bina,o,*table[k])
# 3) min/max des accesseurs
for a in sorted(acc_ids):
    acc=js["accessors"][a]; bv=js["bufferViews"][acc["bufferView"]]
    base=bv.get("byteOffset",0)+acc.get("byteOffset",0)
    stride=bv.get("byteStride") or 12
    pts=[struct.unpack_from('<fff',bina,base+i*stride) for i in range(acc["count"])]
    acc["min"]=[min(p[j] for p in pts) for j in range(3)]
    acc["max"]=[max(p[j] for p in pts) for j in range(3)]
ecrire(dst,js,bina)
print("positions uniques bruitees=%d amplitude=%.4f m"%(len(table),amp))
