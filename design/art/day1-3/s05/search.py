import itertools
from cvd import *
reds=["#B3261E","#C62828","#D93A2B","#A61C1C","#8E1B1B","#E04B3A"]
yel=["#F2C230","#FFD43B","#F5D000","#FFCC33","#FFE14D","#E8B923"]
blu=["#3D8FE0","#4A9BE8","#2F7FD1","#5AA9F0","#1F6FD0","#7DB9F5"]
org=["#FF8A1F","#FF7A00","#FF9124","#F57C00","#FF6A13","#E8660A"]
def mn(a,b,modes):
    return min(delta_e(hex2rgb(a),hex2rgb(b),m) for m in modes)
rg=["Normal","Deuteranopie","Protanopie","Tritanopie","Graustufen"]
res=[]
for r,y,b,o in itertools.product(reds,yel,blu,org):
    pairs=[(r,y),(r,b),(y,b),(r,o),(y,o),(b,o)]
    v=min(mn(a,c,rg) for a,c in pairs)
    res.append((v,r,y,b,o))
res.sort(reverse=True)
for x in res[:8]: print([round(x[0],1)]+list(x[1:]))
