#!/usr/bin/env python3
import csv, math, statistics as st, sys, glob, os, json
D='/tmp/claude-0/gd/designsprint/p4/tobias/sprints/s8/design-sprint/phase4/tobias_welle1_daten'
TICKS_MIN=600
def load(files):
    rows=[]
    for f in files:
        for r in csv.DictReader(open(f)):
            rows.append(r)
    return rows
def wilson(k,n,z=1.96):
    if n==0: return (float('nan'),float('nan'))
    p=k/n; d=1+z*z/n; c=p+z*z/(2*n); a=z*math.sqrt(p*(1-p)/n+z*z/(4*n*n))
    return (100*(c-a)/d,100*(c+a)/d)
def med(xs):
    return st.median(xs) if xs else float('nan')
def pct(xs,q):
    if not xs: return float('nan')
    xs=sorted(xs); i=min(len(xs)-1,int(round(q*(len(xs)-1)))); return xs[i]
def mins(t): return t/TICKS_MIN
def summarize(rows):
    n=len(rows)
    b30=sum(int(r['bankrott30']) for r in rows)
    bend=sum(int(r['bankrott_ende']) for r in rows)
    lo,hi=wilson(b30,n)
    out={'n':n,'b30':b30,'b30_pct':100*b30/n if n else float('nan'),'ci':(lo,hi),'bend_pct':100*bend/n if n else float('nan')}
    def tvals(col,only_ok=False):
        xs=[int(r[col]) for r in rows if int(r[col])>=0]
        return xs
    for col in ('t_erste_zahlung','t_breakeven','t_m7proxy','t_z2','t_z3','t_z4','t_z5','t_z6','t_z7'):
        xs=tvals(col)
        out[col+'_reach']=100*len(xs)/n if n else float('nan')
        out[col+'_med']=mins(med(xs)) if xs else float('nan')
        out[col+'_p90']=mins(pct(xs,0.9)) if xs else float('nan')
    net=[int(r['netto30_cent'])/100 for r in rows]
    ok=[int(r['netto30_cent'])/100 for r in rows if int(r['bankrott30'])==0]
    out['net30_mean']=st.mean(net) if net else float('nan'); out['net30_med']=med(net)
    out['net30_ok_mean']=st.mean(ok) if ok else float('nan'); out['net30_ok_med']=med(ok)
    # ohne Abschluss: nicht pleite@60 und kein Proxy-M7 in 60 min ; und Pleite separat
    no_m7=sum(1 for r in rows if int(r['t_m7proxy'])<0)
    no_m7_alive=sum(1 for r in rows if int(r['t_m7proxy'])<0 and int(r['bankrott_ende'])==0)
    out['no_m7_pct']=100*no_m7/n if n else float('nan'); out['no_m7_alive_pct']=100*no_m7_alive/n if n else float('nan')
    no_z7=sum(1 for r in rows if int(r['t_z7'])<0)
    out['no_z7_pct']=100*no_z7/n if n else float('nan')
    out['m7_within30_pct']=100*sum(1 for r in rows if 0<=int(r['t_m7proxy'])<=18000)/n if n else float('nan')
    out['senke30_mean']=st.mean([int(r['senke_ertrag30_usd']) for r in rows]) if rows else float('nan')
    return out

def fmt(x,d=1):
    if x!=x: return '–'
    return f'{x:.{d}f}'
def paired(rows_a,rows_b):
    A={(r['stadt'],int(r['seed'])):r for r in rows_a}
    flips_up=flips_dn=0; dn=[]; n=0
    for r in rows_b:
        k=(r['stadt'],int(r['seed']))
        if k not in A: continue
        ra=A[k]; n+=1
        a=int(ra['bankrott30']); b=int(r['bankrott30'])
        if a==0 and b==1: flips_up+=1
        if a==1 and b==0: flips_dn+=1
        dn.append((int(r['netto30_cent'])-int(ra['netto30_cent']))/100)
    return {'n':n,'ok_to_bk':flips_up,'bk_to_ok':flips_dn,'dnet_mean':st.mean(dn) if dn else float('nan'),'dnet_med':med(dn)}
