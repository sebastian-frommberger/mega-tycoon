import itertools
from cvd import *
fam={
 "agrar":["#D9A826","#E3B53A","#C99A1E","#E8C14F"],
 "tier_nahrung":["#C7473A","#E36A5D","#D9534F","#B8423A"],
 "holz":["#7A5230","#6B4A2F","#8A6038","#5C4029"],
 "erz_stahl":["#5E7A99","#4A6078","#7088A6","#3E566F"],
 "oel_chemie":["#5E3F85","#8B63B8","#704C9E","#4A3270"],
 "energie":["#19B5C4","#2CC6D6","#0FA3B1","#5ED6E2"],
}
names=list(fam)
rows=[]
for combo in itertools.product(*[fam[n] for n in names]):
    cols=list(combo)+["#F2F2F2"]
    v=999;
    for a,b in itertools.combinations(cols,2):
        for m in MODES:
            d=delta_e(hex2rgb(a),hex2rgb(b),m)
            if d<v: v=d
        if v<7: break
    rows.append((v,combo))
rows.sort(reverse=True)
for r in rows[:6]: print(round(r[0],1), r[1])
