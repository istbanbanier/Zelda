"""Reproduction lead R2a-3.5.8 — jauge de poche T3d, instrument INDEPENDANT.

Balayage en eventail 360 deg depuis l'axe publie par B (ventre u=6.00,
(3.10,-2.88), y=sol+0.50) contre SM_ et COL_ du GLB 5ff4ec6e. Publie :
  - d_SM et d_COL dans chaque direction ou les deux touchent ;
  - le MAX de (d_SM - d_COL) sur le demi-plan cote alcove -> estimateur
    conservateur ampl_col = 1.20 - diff_max + 0.676 ;
  - la direction qui reproduit les valeurs publiees par B.
Möller-Trumbore, aucune dependance, aucune ligne de B reutilisee.
"""
import json, struct, sys, math

def charge_glb(chemin):
    with open(chemin, "rb") as f:
        data = f.read()
    assert data[:4] == b"glTF"
    off = 12; chunks = {}
    while off < len(data):
        ln, ty = struct.unpack_from("<I4s", data, off); off += 8
        chunks[ty] = data[off:off+ln]; off += ln
    gltf = json.loads(chunks[b"JSON"]); binc = chunks[b"BIN\x00"]
    return gltf, binc

def accessor(gltf, binc, idx):
    a = gltf["accessors"][idx]; bv = gltf["bufferViews"][a["bufferView"]]
    off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    n = a["count"]
    ncomp = {"SCALAR":1, "VEC2":2, "VEC3":3, "VEC4":4}[a["type"]]
    fmt = {5126:"f", 5125:"I", 5123:"H", 5121:"B"}[a["componentType"]]
    sz = struct.calcsize(fmt)
    stride = bv.get("byteStride", ncomp*sz)
    out = []
    for i in range(n):
        out.append(struct.unpack_from("<"+fmt*ncomp, binc, off+i*stride))
    return out

def tris_du_noeud(gltf, binc, nom):
    for nd in gltf["nodes"]:
        if nd.get("name") == nom:
            assert "matrix" not in nd, "transform matriciel non gere"
            t = nd.get("translation", [0,0,0])
            assert nd.get("rotation", [0,0,0,1]) == [0,0,0,1], "rotation non geree"
            assert nd.get("scale", [1,1,1]) == [1,1,1], "echelle non geree"
            mesh = gltf["meshes"][nd["mesh"]]
            tris = []
            for prim in mesh["primitives"]:
                pos = accessor(gltf, binc, prim["attributes"]["POSITION"])
                pos = [(p[0]+t[0], p[1]+t[1], p[2]+t[2]) for p in pos]
                ind = [i[0] for i in accessor(gltf, binc, prim["indices"])]
                for k in range(0, len(ind), 3):
                    tris.append((pos[ind[k]], pos[ind[k+1]], pos[ind[k+2]]))
            return tris
    raise SystemExit("noeud absent : " + nom)

def raycast(tris, o, d, tmax=50.0):
    """Premier impact Möller-Trumbore, double face."""
    best = None
    for (a, b, c) in tris:
        e1 = (b[0]-a[0], b[1]-a[1], b[2]-a[2])
        e2 = (c[0]-a[0], c[1]-a[1], c[2]-a[2])
        px = d[1]*e2[2]-d[2]*e2[1]; py = d[2]*e2[0]-d[0]*e2[2]; pz = d[0]*e2[1]-d[1]*e2[0]
        det = e1[0]*px + e1[1]*py + e1[2]*pz
        if abs(det) < 1e-12: continue
        inv = 1.0/det
        tv = (o[0]-a[0], o[1]-a[1], o[2]-a[2])
        u = (tv[0]*px + tv[1]*py + tv[2]*pz) * inv
        if u < -1e-9 or u > 1+1e-9: continue
        qx = tv[1]*e1[2]-tv[2]*e1[1]; qy = tv[2]*e1[0]-tv[0]*e1[2]; qz = tv[0]*e1[1]-tv[1]*e1[0]
        v = (d[0]*qx + d[1]*qy + d[2]*qz) * inv
        if v < -1e-9 or u+v > 1+1e-9: continue
        tt = (e2[0]*qx + e2[1]*qy + e2[2]*qz) * inv
        if 1e-6 < tt < tmax and (best is None or tt < best):
            best = tt
    return best

glb = sys.argv[1]
gltf, binc = charge_glb(glb)
sm = tris_du_noeud(gltf, binc, "SM_WaterfallCave")
col = tris_du_noeud(gltf, binc, "COL_WaterfallCave")
print("tris SM=%d COL=%d" % (len(sm), len(col)))

ax, az = 3.10, -2.88
# sol par maillage : rayon vertical descendant depuis y=3.0
sol_s = raycast(sm, (ax, 1.2, az), (0, -1, 0))
sol_c = raycast(col, (ax, 1.2, az), (0, -1, 0))
ys = 1.2 - sol_s + 0.50; yc = 1.2 - sol_c + 0.50
print("sol SM y=%.4f  sol COL y=%.4f  (rayons a y_SM=%.4f / y_COL=%.4f)"
      % (1.2-sol_s, 1.2-sol_c, ys, yc))

# eventail 360 deg, pas 1 deg
res = []
for deg in range(360):
    r = math.radians(deg)
    d = (math.cos(r), 0.0, math.sin(r))
    dsm = raycast(sm, (ax, ys, az), d)
    dcol = raycast(col, (ax, yc, az), d)
    if dsm is not None and dcol is not None:
        res.append((deg, dsm, dcol, dsm-dcol))

# direction la plus proche des valeurs publiees par B
cible = min(res, key=lambda x: abs(x[1]-4.8422)+abs(x[2]-3.5490))
print("B publiait d_SM=4.8422 d_COL=3.5490 diff=1.2932")
print("plus proche : theta=%d  d_SM=%.4f d_COL=%.4f diff=%.4f" % cible)

# max de diff toutes directions (et top 5)
res.sort(key=lambda x: -x[3])
print("top 5 (d_SM - d_COL) toutes directions :")
for deg, dsm, dcol, df in res[:5]:
    print("  theta=%3d  d_SM=%.4f  d_COL=%.4f  diff=%.4f  -> ampl_col=%.4f"
          % (deg, dsm, dcol, df, 1.20 - df + 0.676))
print("FIN NOMINALE")

# secteur alcove (225-255) et secteur 110-125 : detail
print("secteur alcove 225-255 :")
for deg, dsm, dcol, df in sorted([r for r in res if 225 <= r[0] <= 255]):
    print("  theta=%3d  d_SM=%.4f  d_COL=%.4f  diff=%.4f" % (deg, dsm, dcol, df))
print("secteur 110-125 (jonction salle-couloir) :")
for deg, dsm, dcol, df in sorted([r for r in res if 110 <= r[0] <= 125]):
    print("  theta=%3d  d_SM=%.4f  d_COL=%.4f  diff=%.4f" % (deg, dsm, dcol, df))
