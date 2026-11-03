#!/usr/bin/env python3
import re, csv, os, sys
sys.path.insert(0,'/tmp/claude-0/p4')
OUT='/tmp/claude-0/gd/designsprint/p4/tobias/sprints/s8/design-sprint/phase4/tobias_welle1.md'
D='/tmp/claude-0/gd/designsprint/p4/tobias/sprints/s8/design-sprint/phase4/tobias_welle1_daten'
T=open('/tmp/claude-0/p4/tables.md').read()
secs={}
for part in re.split(r'\n(?=## )', '\n'+T):
    part=part.strip('\n')
    if part.startswith('## '):
        h=part.split('\n',1)[0]; secs[h]=part.split('\n',1)[1].strip('\n') if '\n' in part else ''
def sec(prefix):
    for h,b in secs.items():
        if h.startswith('## '+prefix): return b
    return '(fehlt)'
# Stufe 1 kompakt
def keep1(txt):
    out=[]
    for l in txt.split('\n'):
        if l.startswith('| (a) gleiche'): continue
        out.append(l)
    return '\n'.join(out)
s1=keep1(sec('Stufe 1'))
s2=sec('Stufe 2'); s3=sec('Stufe 3'); zz=sec('Zielzeiten'); s5=sec('Stufe 5')
# Stufe 4
def s4tab():
    rows={}
    for k in 'BC':
        for r in csv.DictReader(open(f'{D}/s4_skript_{k}.csv')):
            m=int(r['m7proxy_tick']); rows.setdefault(r['variante'],{})[k]=(f"{m/600:.1f}" if m>0 else 'nicht erreicht', int(r['netto_ende_usd']), r['bankrott'])
    order=['a0_12000_stadt','4250_kleinstadt','3550_kleinstadt','2490_kleinstadt','1900_kleinstadt','1670_kleinstadt','1550_kleinstadt','1460_kleinstadt','1200_kleinstadt','900_dorf','650_dorf','520_dorf','400_dorf']
    L=['| Senke Mittelfurt (Sim-EW, Stufe) | Nachfrage/min | B: M7 min | B: Netto 60 min $ | C: M7 min | C: Netto 60 min $ | Bankrott B/C |','|---|---|---|---|---|---|---|']
    for v in order:
        if v not in rows: continue
        if v.startswith('a0'): lab='12.000 Stadt (heute)'; dem='120'
        else:
            pop=int(v.split('_')[0]); st=v.split('_')[1]; lab=f'{pop:,} {st}'.replace(',','.'); dem=f"{pop*(2 if st=='dorf' else 1)/100:.1f}"
        b=rows[v]['B']; c=rows[v]['C']
        L.append(f"| {lab} | {dem} | {b[0]} | {b[1]:,} | {c[0]} | {c[1]:,} | {b[2]}/{c[2]} |".replace(',','.') if False else f"| {lab} | {dem} | {b[0]} | {b[1]} | {c[0]} | {c[1]} | {b[2]}/{c[2]} |")
    return '\n'.join(L)
S4=s4tab()
meth=open('/tmp/claude-0/p4/doc_methode.md').read()
tpl=open('/tmp/claude-0/p4/doc_tpl.md').read()
for k,v in {'{{METHODE}}':meth,'{{S1}}':s1,'{{S2}}':s2,'{{S3}}':s3,'{{ZZ}}':zz,'{{S4}}':S4,'{{S5}}':s5}.items():
    tpl=tpl.replace(k,v)
open(OUT,'w').write(tpl)
print(len(tpl.split('\n')),'Zeilen')
