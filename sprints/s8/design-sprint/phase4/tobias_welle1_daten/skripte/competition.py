#!/usr/bin/env python3
import sys, os, json; sys.path.insert(0,'/tmp/claude-0/p4')
from analyze import *
def series(c):
    pts=[]
    for p in (400,550,650,770,900,1200,1550,1900,2400):
        f=f'{D}/s3_g_{c}_{p}.csv'
        if os.path.exists(f):
            rows=load([f]); stg=rows[0]['stufe_senke']; d=p*(2 if stg=='dorf' else 1)/100
            pts.append((d,summarize(rows)['senke30_mean']))
    a0=f'{D}/s3_a0_{c}.csv'
    rows=load([a0]); d=int(rows[0]['einw_senke'])*(2 if rows[0]['stufe_senke']=='dorf' else 1)/100
    pts.append((d,summarize(rows)['senke30_mean']))
    pts=sorted(pts); return pts
def S(pts,d):
    if d<=pts[0][0]: return pts[0][1]*d/pts[0][0]
    if d>=pts[-1][0]: return pts[-1][1]
    for (x0,y0),(x1,y1) in zip(pts,pts[1:]):
        if x0<=d<=x1: return y0+(y1-y0)*(d-x0)/(x1-x0)
def ratio(pts,d,share=0.15): return S(pts,d*(1-share))/S(pts,d)
if __name__=='__main__':
    for c in ('haberau','mittelfurt'):
        pts=series(c); print(c,[(round(d,1),round(v)) for d,v in pts])
        for d in (8,10,13,16,18,24,40):
            print('   d',d,'Ertragsfaktor Senke bei 15 % passiv:',round(ratio(pts,d),3))

def apply(rows, pts, share, tc, d):
    """Erste Naeherung: Ertragsverlust Senke = (1-r(d)) * Senken-Ertrag der Spanne [max(tc,30)..60] (linear), Kasse/Netto am Ende sinken darum; M7/Bankrott neu bewertet."""
    r=ratio(pts,d,share); n=len(rows); bk60=0; m7=0; nets=[]; base_bk=0; base_m7=0
    for x in rows:
        senke_end=int(x['senke_ertrag_end_usd']); s30=int(x['senke_ertrag30_usd'])
        bank_end=int(x['bankrott_ende']); t7=int(x['t_m7proxy']); net_end=int(x['netto_ende_cent'])/100; cash_end=int(x['kasse_ende_cent'])/100
        base_bk+=bank_end; base_m7+= (t7>=0)
        if bank_end: bk60+=1; continue
        # Senken-Ertrag in [tc, 60] (min); vor 30 min gilt senke30 (linear bis 30), ab 30 senke_end - senke30
        rate_late=(senke_end-s30)/30.0
        rate_early=s30/max(1.0, 30.0-(int(x['t_erste_zahlung'])/600.0)) if int(x['t_erste_zahlung'])>=0 else 0
        loss=0.0
        t=tc
        if tc<30: loss+= (1-r)*rate_early*(30-tc)
        loss+= (1-r)*rate_late*(60-max(tc,30))
        net_new=net_end-loss; cash_new=cash_end-loss
        nets.append(net_new)
        if cash_new<0: bk60+=1; continue
        if t7>=0 and t7/600.0<=tc: m7+=1
        elif net_new>=12000: m7+=1
    return {'r':r,'bk60':100*bk60/n,'m7':100*m7/n,'net60':st.mean(nets) if nets else float('nan'),'bk60_base':100*base_bk/n,'m7_base':100*base_m7/n}
