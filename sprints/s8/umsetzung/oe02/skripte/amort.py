import csv, sys, math, collections
def pct(v,p):
    v=sorted(v); return v[min(max(math.ceil(p/100*len(v))-1,0),len(v)-1)] if v else None
an,aus,csvan=sys.argv[1],sys.argv[2],sys.argv[3]
def lade(p):
    d=collections.defaultdict(dict)
    for r in csv.DictReader(open(p)):
        if r['strategie']=='plan': d[r['seed']][int(r['periode'])]=int(r['netto_op_cent'])
    return d
A=lade(an); B=lade(aus); A_korr={}
kauf={}
for r in csv.DictReader(open(csvan)):
    if r['strategie']!='plan': continue
    km=float(r['fk_kauf_min']); kp=int(r['fk_preis_cent'] or 0); am_=float(r['fk_ausbau_min'] or -1); ap=int(r['fk_ausbau_cent'] or 0)
    kauf[r['seed']]=(km,kp+ap)
    # Korrektur Doppelzählung (kauf_total enthält seit FX3 den Firmenkauf, der Bot rechnet fk_total zusätzlich heraus): je Kaufperiode abziehen
    if km>=0: A_korr.setdefault(r['seed'],[]).append((int(km),kp))
    if am_>=0: A_korr.setdefault(r['seed'],[]).append((int(am_),ap))
for s_,lst in A_korr.items():
    for p,c in lst: A[s_][p]=A[s_].get(p,0)-c
am=[]; ratio=[]
for s in A:
    km,inv=kauf[s]; k0=int(km)
    cum=0; t=None
    for p in range(k0,45):
        cum+=A[s].get(p,0)-B[s].get(p,0)
        if t is None and cum>=inv: t=p+1-km
    am.append(t if t is not None else 99)
    vor=sum(A[s].get(p,0) for p in range(k0-5,k0))/5; nach=sum(A[s].get(p,0) for p in range(k0+5,k0+10))/5
    ratio.append(nach/vor if vor>0 else float('inf'))
print("Amortisation (kum. Δ Netto op. KAUF−OHNE ≥ Kauf+Ausbau), min nach Kauf: P25 %s P50 %s P75 %s, im Ziel 8-20: %d/%d"%(pct(am,25),pct(am,50),pct(am,75),sum(1 for x in am if 8<=x<=20),len(am)))
print("Schneeball 5-min-Mittel: Netto Minute k+5..k+10 / Minute k-5..k: P25 %.2f P50 %.2f P75 %.2f; >=2: %d/%d"%(pct(ratio,25),pct(ratio,50),pct(ratio,75),sum(1 for x in ratio if x>=2),len(ratio)))
