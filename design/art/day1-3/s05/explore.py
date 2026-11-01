import itertools, sys
from cvd import *
cands = {
 "status": {"hinweis_blau":"#2F7FD1","warnung_gelb":"#F2C230","kritisch_rot":"#D93A2B","ok_grau":"#C9D0D6"},
 "netz": {"spieler_orange":"#FF8A1F","ki_blaugrau":"#6E8B9A","ki_graulila":"#8A7F9A","ki_ockergrau":"#9A9272"},
 "gueter": {"agrar":"#D9A826","tier_nahrung":"#C7473A","holz":"#7A5230","erz_stahl":"#5E7A99","oel_chemie":"#5E3F85","energie":"#19B5C4","konsum":"#F2F2F2"},
}
for g,d in cands.items():
    print("==",g)
    for (na,ha),(nb,hb) in itertools.combinations(d.items(),2):
        v={m:delta_e(hex2rgb(ha),hex2rgb(hb),m) for m in MODES}
        mn=min(v.values()); worst=min(v,key=v.get)
        print(f"{na:15s} {nb:15s} min {mn:5.1f} ({worst:12s})", "KOLLISION" if mn<10 else "")
print("== marker auf Netz")
for ns,hs in cands["status"].items():
    for nn,hn in [("spieler_orange","#FF8A1F")]:
        v={m:delta_e(hex2rgb(hs),hex2rgb(hn),m) for m in MODES}
        mn=min(v.values()); print(ns,nn,round(mn,1),min(v,key=v.get))
