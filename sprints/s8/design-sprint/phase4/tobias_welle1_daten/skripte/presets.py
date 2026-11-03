#!/usr/bin/env python3
"""Zusatzfrage: Schwierigkeits-Presets (Geld) aus Messdaten, ohne neuen Lauf. Erste Naeherung:
 - Startkapital-Verschiebung dS: Bankrott@30' = Anteil Laeufe mit min_kasse30 + dS - dZins < 0 (gleiche Entscheidungen des Bots angenommen)
 - Zins: dZins = (z' - 3 %) * max_Kredit30 * 9 min (halbe Kredit-Exposition 12..30 min)
 - Konkurrenz (passiver Anteil 15 % der Senken-Nachfrage ab Minute T): Ertragsverlust der Senke = Anteil * Senken-Ertrag der Restzeit * (Saettigungsfaktor)
Rahmen/Sperre (Leicht 3.000 $ ab Min 6, Schwer 1.500 $) sind offline nicht abbildbar."""
import sys; sys.path.insert(0,'/tmp/claude-0/p4')
from analyze import *
def bk30_shifted(rows, dS_usd, z_new=0.03):
    n=len(rows); k=0
    for r in rows:
        mk=int(r['min_kasse30_cent'])/100
        loan=int(r['max_kredit30_cent'])/100
        dz=(z_new-0.03)*loan*9
        if mk + dS_usd - dz < 0: k+=1
    return 100*k/n
