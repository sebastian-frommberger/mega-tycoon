# Misst Kenney-GLB-Proben: Dreiecke je Modell und Bounding-Box in Metern (Szenen-Transforms angewendet).
# Nur Standardbibliothek. Aufruf: python3 -I glb_messung.py <datei.glb> [...]
import sys, json, struct, math, os

CT = {5120:("b",1),5121:("B",1),5122:("h",2),5123:("H",2),5125:("I",4),5126:("f",4)}
NC = {"SCALAR":1,"VEC2":2,"VEC3":3,"VEC4":4,"MAT4":16}

def load(path):
    with open(path,"rb") as f: data=f.read()
    magic, ver, length = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67, "kein GLB"
    off=12; js=None; bin_=None
    while off < length:
        clen, ctype = struct.unpack_from("<II", data, off); off+=8
        chunk = data[off:off+clen]; off+=clen
        if ctype==0x4E4F534A: js=json.loads(chunk.decode("utf-8"))
        elif ctype==0x004E4942: bin_=chunk
    return js, bin_

def read_accessor(js, bin_, idx):
    acc = js["accessors"][idx]; bv = js["bufferViews"][acc["bufferView"]]
    fmt, size = CT[acc["componentType"]]; n = NC[acc["type"]]
    stride = bv.get("byteStride", size*n)
    base = bv.get("byteOffset",0) + acc.get("byteOffset",0)
    out=[]
    for i in range(acc["count"]):
        o = base + i*stride
        out.append(struct.unpack_from("<"+fmt*n, bin_, o))
    return out

def mat_mul(a,b):  # 4x4 column-major lists (glTF)
    r=[0.0]*16
    for c in range(4):
        for rr in range(4):
            r[c*4+rr]=sum(a[k*4+rr]*b[c*4+k] for k in range(4))
    return r

def node_matrix(n):
    if "matrix" in n: return list(n["matrix"])
    t=n.get("translation",[0,0,0]); q=n.get("rotation",[0,0,0,1]); s=n.get("scale",[1,1,1])
    x,y,z,w=q
    R=[1-2*(y*y+z*z), 2*(x*y+z*w), 2*(x*z-y*w), 0,
       2*(x*y-z*w), 1-2*(x*x+z*z), 2*(y*z+x*w), 0,
       2*(x*z+y*w), 2*(y*z-x*w), 1-2*(x*x+y*y), 0,
       0,0,0,1]
    S=[s[0],0,0,0, 0,s[1],0,0, 0,0,s[2],0, 0,0,0,1]
    T=[1,0,0,0, 0,1,0,0, 0,0,1,0, t[0],t[1],t[2],1]
    return mat_mul(T, mat_mul(R,S))

def xform(m,p):
    x,y,z=p
    return (m[0]*x+m[4]*y+m[8]*z+m[12], m[1]*x+m[5]*y+m[9]*z+m[13], m[2]*x+m[6]*y+m[10]*z+m[14])

def measure(path):
    js, bin_ = load(path)
    tris=0; mn=[1e9]*3; mx=[-1e9]*3; prims=0; mats=set()
    def visit(ni, parent):
        nonlocal tris, prims
        n=js["nodes"][ni]; m=mat_mul(parent, node_matrix(n))
        if "mesh" in n:
            for p in js["meshes"][n["mesh"]]["primitives"]:
                prims+=1
                if "material" in p: mats.add(p["material"])
                mode=p.get("mode",4)
                if "indices" in p: cnt=js["accessors"][p["indices"]]["count"]
                else: cnt=js["accessors"][p["attributes"]["POSITION"]]["count"]
                if mode==4: tris+=cnt//3
                elif mode in (5,6): tris+=max(cnt-2,0)
                for v in read_accessor(js,bin_,p["attributes"]["POSITION"]):
                    w=xform(m,v)
                    for k in range(3): mn[k]=min(mn[k],w[k]); mx[k]=max(mx[k],w[k])
        for c in n.get("children",[]): visit(c,m)
    I=[1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]
    scene=js["scenes"][js.get("scene",0)]
    for r in scene["nodes"]: visit(r,I)
    size=[mx[k]-mn[k] for k in range(3)]
    return dict(datei=os.path.basename(path), kit=path.split("/")[-4] if "/" in path else "", tris=tris, prims=prims, materialien=len(mats),
                bbox_x=size[0], bbox_y=size[1], bbox_z=size[2], min_y=mn[1], nodes=len(js["nodes"]), texturen=len(js.get("images",[])))

if __name__=="__main__":
    print("kit;datei;tris;primitives;materialien;bilder;x_m;y_m(hoehe);z_m;min_y")
    for p in sys.argv[1:]:
        r=measure(p)
        print(f"{r['kit']};{r['datei']};{r['tris']};{r['prims']};{r['materialien']};{r['texturen']};{r['bbox_x']:.2f};{r['bbox_y']:.2f};{r['bbox_z']:.2f};{r['min_y']:.2f}")
