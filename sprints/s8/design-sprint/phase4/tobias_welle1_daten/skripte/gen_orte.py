#!/usr/bin/env python3
"""Welt-Draws fuer die Stichprobe K1: 3 Seeds. Je Seed: 2 Kleinstaedte, 2-3 Marktflecken, Rest Doerfer (Regelwerk v1 §3, 8 Orte der Slice-Karte),
Zuordnung zufaellig, Sim-EW gleichverteilt im Band (Dorf 400-900, Marktflecken 1.200-1.900, Kleinstadt 2.400-4.700), auf 10 gerundet.
Sim-Stufe: Dorf -> dorf, Marktflecken/Kleinstadt -> kleinstadt (Regelwerk: Sim-Stufe steuert Warenkorb/Nachfrage)."""
import random, sys, json
TOWNS=['kohlberg','lindach','weidenau','seehafen','eichwald','mittelfurt','steinbach','haberau']
BAND={'dorf':(400,900),'marktflecken':(1200,1900),'kleinstadt':(2400,4700)}
def draw(seed):
    r=random.Random(40000+seed)
    n_mf=r.choice([2,3])
    order=TOWNS[:]; r.shuffle(order)
    cls={}
    for i,t in enumerate(order):
        cls[t]='kleinstadt' if i<2 else ('marktflecken' if i<2+n_mf else 'dorf')
    out={}
    for t in TOWNS:
        lo,hi=BAND[cls[t]]
        out[t]=(cls[t], int(round(r.uniform(lo,hi),-1)))
    return out
def orte_arg(d):
    return ','.join(f"{t}:{pop}:{'dorf' if c=='dorf' else 'kleinstadt'}" for t,(c,pop) in d.items())
if __name__=='__main__':
    for w in (1,2,3):
        d=draw(w)
        print(w, orte_arg(d))
        print('   ', {t:(c[:2],p) for t,(c,p) in d.items()}, 'Summe', sum(p for c,p in d.values()))
