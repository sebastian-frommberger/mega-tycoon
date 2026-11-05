import csv, sys, math, collections
def pct(v,p):
    v=sorted(v); return v[min(max(math.ceil(p/100*len(v))-1,0),len(v)-1)] if v else None
def wil(k,n,z=1.96):
    p=k/n; den=1+z*z/n; mid=(p+z*z/(2*n))/den; h=z*math.sqrt(p*(1-p)/n+z*z/(4*n*n))/den
    return f"{max(0,mid-h)*100:.0f}-{min(1,mid+h)*100:.0f}"
X=int(sys.argv[1])*100
for pf in sys.argv[2:]:
    rows=list(csv.DictReader(open(pf)))
    ser=collections.defaultdict(lambda: collections.defaultdict(dict))
    for r in csv.DictReader(open(pf+'.serie.csv')):
        ser[r['strategie']][r['seed']][int(r['periode'])]=(int(r['netto_op_cent']),int(r['kredit_cent']))
    for s in ["naiv","normal","plan"]:
        R=[x for x in rows if x['strategie']==s]
        if not R: continue
        n=len(R); b=sum(int(x['bankrott']) for x in R)
        # Korrektur Doppelzählung FK in netto_op (QT-03b-Bot nach FX3)
        for x in R:
            d=ser[s][x['seed']]
            for mcol,ccol in (('fk_kauf_min','fk_preis_cent'),('fk_ausbau_min','fk_ausbau_cent')):
                m=float(x[mcol] or -1)
                if m>=0 and int(m) in d:
                    v,k=d[int(m)]; d[int(m)]=(v-int(x[ccol] or 0),k)
        def mittel(a,bb): return pct([sum(d.get(p,(0,0))[0] for p in range(a,bb))/(bb-a)/100 for d in ser[s].values()],50)
        f2m=[];f2p=[]
        for d in ser[s].values():
            ps=sorted(d); a=bq=None; run=0
            for i,p in enumerate(ps):
                v,k=d[p]; run=run+1 if (v>=X and k==0) else 0
                if bq is None and run>=5: bq=p+1
                if a is None and i>=4 and all(d[q][1]==0 for q in ps[i-4:i+1]) and sum(d[q][0] for q in ps[i-4:i+1])/5>=X: a=p+1
            if a: f2m.append(a)
            if bq: f2p.append(bq)
        luck=[float(x['luecke_max_min']) for x in R]; tief=[int(x['kasse_tief_5_20_cent'])/100 for x in R]
        n30=[int(x['netto5_op_min30_cent'])/100 for x in R]
        ers=[float(x['ers_spart_min']) for x in R if x['ers_spart_min'] not in ('','-1','-1.0')]
        ersd=[float(x['ersetzt_erst_min']) for x in R if x['ersetzt_erst_min'] not in ('','-1','-1.0')]
        dist=len(set(x['pruefsumme'] for x in R))
        print(f"{pf.split('/')[-2]}/{pf.split('/')[-1]:18s} {s:6s} n={n} Bankrott {b} ({100*b/n:.0f} %, Wilson {wil(b,n)}) | Luecke P90 {pct(luck,90)} | Tief P50 {pct(tief,50):.0f} $ | Netto Min30 P50 {pct(n30,50):.0f} | 10-min 10-20 {mittel(10,20):.0f} 20-30 {mittel(20,30):.0f} 30-40 {mittel(30,40):.0f} 35-45 {mittel(35,45):.0f} | F2 X={X//100}: 5er-Mittel {len(f2m)}/{n} P50 {pct(f2m,50)}, je Periode {len(f2p)}/{n} P50 {pct(f2p,50)} | Ersetzen spart ab P50 {pct(ers,50)}, ersetzt P50 {pct(ersd,50)} ({len(ersd)}) | Verläufe {dist}")
