#!/usr/bin/env python3
import sys, os, glob
sys.path.insert(0,'/tmp/claude-0/p4')
from analyze import *
out=[]
def P(s=''): out.append(s)
def have(f): return os.path.exists(f)
C=['mittelfurt','haberau','kohlberg']
CN={'mittelfurt':'Mittelfurt','haberau':'Haberau','kohlberg':'Kohlberg'}
def row_cells(s):
    ci=f"{s['b30_pct']:.1f} ({s['ci'][0]:.0f}–{s['ci'][1]:.0f})"
    return [ci, fmt(s['bend_pct']), fmt(s['t_erste_zahlung_med']), f"{fmt(s['t_breakeven_med'])} ({fmt(s['t_breakeven_reach'],0)} %)", f"{fmt(s['t_z7_med'])} ({fmt(100-s['no_z7_pct'],0)} %)",
            f"{fmt(s['t_m7proxy_med'])} ({fmt(s['t_m7proxy_reach'],0)} %)", f"{s['net30_mean']:.0f} / {s['net30_med']:.0f}", fmt(s['no_m7_alive_pct'])]
HDR='| Variante | Bankrott@30 % (95%-KI) | Bankrott@60 % | erste Zahlung min (Median) | Break-even min (erreicht) | Ziel 7 min (erreicht) | Proxy-M7 min (erreicht in 60 min) | Netto 30 min Ø / Median $ | ohne Abschluss % |\n|---|---|---|---|---|---|---|---|---|'
# ---- Stufe 1
P('## Stufe 1: 3 Seeds × 3 Läufe (formal)')
if have(D+'/stufe1_a0.csv'):
    a0=load([D+'/stufe1_a0.csv'])
    bw={w:load([D+f'/stufe1_b_w{w}.csv']) for w in (1,2,3) if have(D+f'/stufe1_b_w{w}.csv')}
    for c in C:
        P(f'\n### {CN[c]}\n'+HDR)
        ra=[r for r in a0 if r['stadt']==c]
        P('| (a) heute, 9 Läufe | '+' | '.join(row_cells(summarize(ra)))+' |')
        for w,rows in bw.items():
            rb=[r for r in rows if r['stadt']==c]
            seeds={int(r['seed']) for r in rb}
            rap=[r for r in ra if int(r['seed']) in seeds]
            P(f'| (a) gleiche Läufe wie W{w} | '+' | '.join(row_cells(summarize(rap)))+' |')
            P(f'| (b) Welt W{w} | '+' | '.join(row_cells(summarize(rb)))+' |')
        allb=[r for rows in bw.values() for r in rows if r['stadt']==c]
        P('| (b) alle 3 Welten, 9 Läufe | '+' | '.join(row_cells(summarize(allb)))+' |')
# ---- Stufe 2
P('\n## Stufe 2: n = 300 je Variante und Standort (gleiche Verhaltens-Seeds 1–300)')
variants=[('a0','(a0) heute: Slice-Karte unverändert',lambda c:f'{D}/s2_a0_{c}.csv'),
          ('a1','(a1) heute: S7-Welt-Werte (Mittelfurt 4.250, Haberau 750)',lambda c:f'{D}/s2_a1_{c}.csv'),
          ('w1','(b) Welt W1',lambda c:f'{D}/s2_b_w1_{c}.csv'),('w2','(b) Welt W2',lambda c:f'{D}/s2_b_w2_{c}.csv'),('w3','(b) Welt W3',lambda c:f'{D}/s2_b_w3_{c}.csv')]
S2={}
for c in C:
    P(f'\n### {CN[c]}\n'+HDR)
    for key,name,fn in variants:
        if have(fn(c)):
            rows=load([fn(c)]); S2[(key,c)]=rows
            pop=rows[0]['einw_senke']+' '+rows[0]['stufe_senke']
            P(f'| {name} (Senke {pop}) | '+' | '.join(row_cells(summarize(rows)))+' |')
    ws=[S2[(k,c)] for k in ('w1','w2','w3') if (k,c) in S2]
    if len(ws)==3:
        P('| (b) W1–W3 gepoolt (n=900) | '+' | '.join(row_cells(summarize([r for x in ws for r in x])))+' |')
for k in ('w2','w3'):
    if ('a0','kohlberg') in S2 and (k,'kohlberg') not in S2 and (k,'mittelfurt') in S2:
        S2[(k,'kohlberg')]=S2[('a0','kohlberg')]     # Kohlberg: keine Senke, bitgleich (W1 n=300, Stufe 1) -> a0 uebernommen
P('\n### Alle drei Standorte gepoolt')
P('| Variante | n | Bankrott@30 % (95%-KI) | Bankrott@60 % | Netto 30 min Ø $ | Proxy-M7 in 60 min % | ohne Abschluss % |\n|---|---|---|---|---|---|---|')
for key,name,fn in variants:
    rows=[r for c in C for r in S2.get((key,c),[])]
    if key=='a1' and rows:   # Kohlberg unveraendert (a0)
        rows=rows+[r for r in S2.get(('a0','kohlberg'),[])]
    if rows:
        s=summarize(rows)
        P(f"| {name} | {s['n']} | {s['b30_pct']:.1f} ({s['ci'][0]:.0f}–{s['ci'][1]:.0f}) | {s['bend_pct']:.1f} | {s['net30_mean']:.0f} | {s['t_m7proxy_reach']:.0f} | {s['no_m7_alive_pct']:.1f} |")
allb=[r for c in C for k in ('w1','w2','w3') for r in S2.get((k,c),[])]
if allb:
    s=summarize(allb)
    P(f"| (b) W1–W3 gepoolt | {s['n']} | {s['b30_pct']:.1f} ({s['ci'][0]:.0f}–{s['ci'][1]:.0f}) | {s['bend_pct']:.1f} | {s['net30_mean']:.0f} | {s['t_m7proxy_reach']:.0f} | {s['no_m7_alive_pct']:.1f} |")
P('\n### Gepaart gegen (a0): gleiche Verhaltens-Seed, nur die Ortsdaten ändern sich')
P('| Standort | Variante | n | ok → Bankrott | Bankrott → ok | Δ Netto 30 min Ø $ | Δ Netto Median $ |\n|---|---|---|---|---|---|---|')
for c in C:
    for key,name,fn in variants[1:]:
        if (key,c) in S2 and ('a0',c) in S2:
            p=paired(S2[('a0',c)],S2[(key,c)])
            P(f"| {CN[c]} | {name.split(':')[0]} | {p['n']} | {p['ok_to_bk']} | {p['bk_to_ok']} | {p['dnet_mean']:.0f} | {p['dnet_med']:.0f} |")
# ---- Stufe 3
P('\n## Stufe 3: Raster Sim-EW der Senke (n = 150)')
for c in ('mittelfurt','haberau'):
    pops=[400,550,650,770,900,1200,1550,1900,2400,3550,4700]
    files=[(p,f'{D}/s3_g_{c}_{p}.csv') for p in pops]
    if not any(have(f) for _,f in files): continue
    P(f'\n### Senke bei {CN[c]}\n')
    P('| Sim-EW Senke (Stufe) | Nachfrage/min | Bankrott@30 % (KI) | Bankrott@60 % | Netto 30 min Ø / Median $ | Senke-Ertrag 30 min Ø $ | Proxy-M7 erreicht % | M7 Median min | Break-even Median min (erreicht %) |\n|---|---|---|---|---|---|---|---|---|')
    ref=f'{D}/s3_a0_{c}.csv'
    if have(ref):
        s=summarize(load([ref])); P(f"| 12.000 Stadt (a0) | 120 | {s['b30_pct']:.1f} ({s['ci'][0]:.0f}–{s['ci'][1]:.0f}) | {s['bend_pct']:.1f} | {s['net30_mean']:.0f} / {s['net30_med']:.0f} | {s['senke30_mean']:.0f} | {s['t_m7proxy_reach']:.0f} | {fmt(s['t_m7proxy_med'])} | {fmt(s['t_breakeven_med'])} ({fmt(s['t_breakeven_reach'],0)} %) |") if c=='mittelfurt' else P(f"| 900 Dorf (a0) | 18 | {s['b30_pct']:.1f} ({s['ci'][0]:.0f}–{s['ci'][1]:.0f}) | {s['bend_pct']:.1f} | {s['net30_mean']:.0f} / {s['net30_med']:.0f} | {s['senke30_mean']:.0f} | {s['t_m7proxy_reach']:.0f} | {fmt(s['t_m7proxy_med'])} | {fmt(s['t_breakeven_med'])} ({fmt(s['t_breakeven_reach'],0)} %) |")
    for p,f in files:
        if not have(f): continue
        rows=load([f]); s=summarize(rows); stg=rows[0]['stufe_senke']
        dem=p*(2 if stg=='dorf' else 1)/100
        P(f"| {p:,} ({stg}) | {dem:.1f} | {s['b30_pct']:.1f} ({s['ci'][0]:.0f}–{s['ci'][1]:.0f}) | {s['bend_pct']:.1f} | {s['net30_mean']:.0f} / {s['net30_med']:.0f} | {s['senke30_mean']:.0f} | {s['t_m7proxy_reach']:.0f} | {fmt(s['t_m7proxy_med'])} | {fmt(s['t_breakeven_med'])} ({fmt(s['t_breakeven_reach'],0)} %) |".replace(',','.'))
open('/tmp/claude-0/p4/tables.md','w').write('\n'.join(out)+'\n')
print('\n'.join(out))

# ---- Zielzeiten Z1-Z7 (Stufe 2)
Z=[]
Z.append('\n## Zielzeiten Z1–Z7 (Median in Spielminuten, erreicht in 60 min in Klammern)')
Z.append('| Standort | Variante | Z1 Firma | Z2 Lizenz | Z3 Straße | Z4 Lkw-Linie | Z5 erste Lieferung | Z6 3 Lieferungen | Z7 Endprodukt beim Abnehmer | Proxy-M7 (Netto ≥ 12.000 $) |\n|---|---|---|---|---|---|---|---|---|---|')
for c in C:
    for key,name in (('a0','(a0) heute'),('a1','(a1) S7-Welt-Werte'),('b','(b) W1–W3 gepoolt')):
        rows=S2.get((key,c)) if key!='b' else [r for k in ('w1','w2','w3') for r in S2.get((k,c),[])]
        if not rows or (c=='kohlberg' and key=='a1'): continue
        s=summarize(rows)
        cells=[f"{fmt(s[f't_z{i}_med'])} ({fmt(s[f't_z{i}_reach'],0)} %)" for i in range(2,8)]
        Z.append(f"| {CN[c]} | {name} | 0,0 | "+' | '.join(cells)+f" | {fmt(s['t_m7proxy_med'])} ({fmt(s['t_m7proxy_reach'],0)} %) |")
out.extend(Z)
open('/tmp/claude-0/p4/tables.md','w').write('\n'.join(out)+'\n')

# ---- Stufe 5: Gegenmittel demand_per_100 x k (Sim-EW x k, Stufe unveraendert), n=150, gepaart gegen Stufe 2 (Seeds 1-150)
T5=[]
T5.append('\n## Stufe 5: Gegenmittel „Nachfrage je 100 EW × k“ (n = 150 je Welt und Standort, Seeds 1–150; Vergleich mit Stufe 2, gleiche Seeds)')
T5.append('| Standort | Welt (Senke, Nachfrage/min) | k | Bankrott@30 % | Bankrott@60 % | Netto 30 min Ø $ | Senke-Ertrag 30 min Ø $ | Proxy-M7 erreicht % |\n|---|---|---|---|---|---|---|---|')
from gen_orte import draw
def dem(pop,cls): return pop*(2 if cls=='dorf' else 1)/100
for c in ('mittelfurt','haberau'):
    for w in (1,2,3):
        d=draw(w)
        cls,pop=d[c]
        base=[r for r in S2.get((f'w{w}',c),[]) if int(r['seed'])<=150]
        if base:
            s=summarize(base)
            T5.append(f"| {CN[c]} | W{w} ({pop} {cls[:2]}., {dem(pop,cls):.1f}) | 1,0 | {s['b30_pct']:.1f} | {s['bend_pct']:.1f} | {s['net30_mean']:.0f} | {s['senke30_mean']:.0f} | {s['t_m7proxy_reach']:.0f} |")
        for k in (1.25,1.5):
            f=f'{D}/s5_b_w{w}_x{k}_{c}.csv'
            if os.path.exists(f):
                s=summarize(load([f])); popk=int(round(pop*k,-1))
                T5.append(f"| {CN[c]} | W{w} ({popk} {cls[:2]}., {dem(popk,cls):.1f}) | {str(k).replace('.',',')} | {s['b30_pct']:.1f} | {s['bend_pct']:.1f} | {s['net30_mean']:.0f} | {s['senke30_mean']:.0f} | {s['t_m7proxy_reach']:.0f} |")
# gepoolt je Standort
T5.append('\n| Standort (3 Welten gepoolt, n=450) | k | Bankrott@30 % (95%-KI) | Bankrott@60 % | Netto 30 min Ø $ | Proxy-M7 erreicht % |\n|---|---|---|---|---|---|')
for c in ('mittelfurt','haberau'):
    base=[r for w in (1,2,3) for r in S2.get((f'w{w}',c),[]) if int(r['seed'])<=150]
    if base:
        s=summarize(base); T5.append(f"| {CN[c]} | 1,0 | {s['b30_pct']:.1f} ({s['ci'][0]:.0f}–{s['ci'][1]:.0f}) | {s['bend_pct']:.1f} | {s['net30_mean']:.0f} | {s['t_m7proxy_reach']:.0f} |")
    for k in (1.25,1.5):
        fs=[f'{D}/s5_b_w{w}_x{k}_{c}.csv' for w in (1,2,3)]
        if all(os.path.exists(f) for f in fs):
            s=summarize(load(fs)); T5.append(f"| {CN[c]} | {str(k).replace('.',',')} | {s['b30_pct']:.1f} ({s['ci'][0]:.0f}–{s['ci'][1]:.0f}) | {s['bend_pct']:.1f} | {s['net30_mean']:.0f} | {s['t_m7proxy_reach']:.0f} |")
out.extend(T5)
open('/tmp/claude-0/p4/tables.md','w').write('\n'.join(out)+'\n')
