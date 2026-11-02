# Misst Bounding-Boxen (Kit-Einheiten) und Dreiecke aller GLB/GLTF im Kenney All-in-1 (nur JSON-Chunk, Knoten-TRS beachtet).
# Aufruf: python3 asset_audit_bbox.py "<...>/3D assets" out.csv   (lief am 02.11. auf Bastis Geraet: 5073 Modelle, 0 Fehler, 77 s)
import os,sys,json,struct,csv
ROOT,OUT=sys.argv[1],sys.argv[2]
def mm(a,b): return [[sum(a[i][k]*b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]
def trs(n):
    if 'matrix' in n: m=n['matrix']; return [[m[c*4+r] for c in range(4)] for r in range(4)]
    t=n.get('translation',[0,0,0]); x,y,z,w=n.get('rotation',[0,0,0,1]); s=n.get('scale',[1,1,1])
    R=[[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]]
    return [[R[i][0]*s[0],R[i][1]*s[1],R[i][2]*s[2],t[i]] for i in range(3)]+[[0,0,0,1]]
def load(p):
    with open(p,'rb') as f:
        if p.lower().endswith('.glb'): h=f.read(20); return json.loads(f.read(struct.unpack('<I',h[12:16])[0]))
        return json.load(f)
def measure(p):
    g=load(p); acc=g.get('accessors',[]); meshes=g.get('meshes',[]); nodes=g.get('nodes',[])
    lo=[1e18]*3; hi=[-1e18]*3; tris=[0]
    sc=g['scenes'][g.get('scene',0)] if g.get('scenes') else {'nodes':list(range(len(nodes)))}
    def walk(ni,M):
        n=nodes[ni]; M2=mm(M,trs(n))
        if 'mesh' in n:
            for pr in meshes[n['mesh']]['primitives']:
                a=acc[pr['attributes']['POSITION']]; tris[0]+=(acc[pr['indices']]['count'] if 'indices' in pr else a['count'])//3
                for cx in (a['min'][0],a['max'][0]):
                    for cy in (a['min'][1],a['max'][1]):
                        for cz in (a['min'][2],a['max'][2]):
                            v=[sum(M2[i][k]*c for k,c in enumerate((cx,cy,cz,1))) for i in range(3)]
                            for i in range(3): lo[i]=min(lo[i],v[i]); hi[i]=max(hi[i],v[i])
        for c in n.get('children',[]): walk(c,M2)
    for ni in sc.get('nodes',[]): walk(ni,[[float(i==j) for j in range(4)] for i in range(4)])
    return None if lo[0]>1e17 else [round(hi[i]-lo[i],3) for i in range(3)]+[round(lo[1],3),tris[0]]
w=csv.writer(open(OUT,'w',newline='')); w.writerow(['kit','fmt','model','x','y','z','ymin','tris'])
for kit in sorted(os.listdir(ROOT)):
    md=os.path.join(ROOT,kit,'Models'); fmt=next((d for d in ('GLB format','GLTF format') if os.path.isdir(os.path.join(md,d))),None)
    if not fmt: continue
    for root,_,fs in os.walk(os.path.join(md,fmt)):
        for fn in sorted(fs):
            if fn.lower().endswith(('.glb','.gltf')):
                try: r=measure(os.path.join(root,fn))
                except Exception: r=None
                w.writerow([kit,fmt.split()[0],os.path.splitext(fn)[0]]+(r or ['ERR']*5))
