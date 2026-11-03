#!/usr/bin/env python3
import sys, os, json; sys.path.insert(0,'/tmp/claude-0/p4')
from analyze import *
from presets import *
R={}
def g(c,pop):
    f=f'{D}/s3_g_{c}_{pop}.csv'
    if c=='haberau' and pop==900: f=f'{D}/s3_a0_haberau.csv'
    return summarize(load([f])) if os.path.exists(f) else None
# --- Ortsmix-Erwartung
W={'dorf':0.76,'mf':0.14,'ks':0.10}   # Regelwerk: 14 Doerfer : 2,5 Marktflecken : 2 Kleinstaedte
for c,ksref in (('haberau',('b_w1','haberau')),('mittelfurt',('b_w1','mittelfurt'))):
    pts={'dorf':[400,550,650,770,900],'mf':[1200,1550,1900]}
    res={}
    for cls,pops in pts.items():
        ss=[g(c,p) for p in pops if g(c,p)]
        res[cls]={k:st.mean([s[k] for s in ss]) for k in ('b30_pct','bend_pct','net30_mean','senke30_mean')}
        res[cls]['n_pts']=len(ss)
    ks=summarize(load([f'{D}/s2_b_w1_{c}.csv']))
    res['ks']={k:ks[k] for k in ('b30_pct','bend_pct','net30_mean','senke30_mean')}
    mix={k:sum(W[cl]*res[cl][k] for cl in W) for k in ('b30_pct','bend_pct','net30_mean','senke30_mean')}
    R[c]={'klassen':res,'mix':mix}
print(json.dumps(R,indent=1))
