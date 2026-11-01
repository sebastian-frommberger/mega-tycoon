#!/usr/bin/env python3
"""Auswertung des Klick-Tests (S-03): python3 auswerten.py pid_1.csv pid_2.csv ...
Eine Person gilt als bestanden, wenn alle drei Ziele (Stadt, Industrie, Strecke) mit Treffer UND < 10 s
gefunden wurden (Annahme: 10 s gilt je Ziel, nicht fuer alle drei zusammen).
Gesamtkriterium: mindestens 4 von 6 Personen bestanden. Zeilen mit '# FUNKTIONSTEST' sind simuliert."""
import csv, sys

def lese(pfad):
    simuliert = False
    zeilen = []
    with open(pfad, newline="") as f:
        raw = f.read().splitlines()
    if raw and raw[0].startswith("#"):
        simuliert = "FUNKTIONSTEST" in raw[0]
        raw = raw[1:]
    for r in csv.DictReader(raw):
        zeilen.append(r)
    return simuliert, zeilen

ergebnis = []
sim_any = False
for p in sys.argv[1:]:
    sim, rows = lese(p)
    sim_any = sim_any or sim
    pid = rows[0]["pid"] if rows else "?"
    erst = {}
    for r in rows:
        if r["treffer"] == "1" and r["ziel"] not in erst:
            erst[r["ziel"]] = int(r["zeit_ms"])
    ok = all(z in erst and erst[z] < 10000 for z in ("Stadt", "Industrie", "Strecke"))
    fehl = sum(1 for r in rows if r["treffer"] == "0" and r["hinweis"] != "timeout")
    print("Person %s: %s | Zeiten ms %s | Fehlklicks %d%s" % (pid, "bestanden" if ok else "NICHT bestanden", erst, fehl, " (SIMULIERT)" if sim else ""))
    ergebnis.append(ok)
n = len(ergebnis)
print("Ergebnis: %d von %d bestanden; Kriterium >= 4 von 6: %s" % (sum(ergebnis), n, "erfuellt" if n >= 6 and sum(ergebnis) >= 4 else "nicht erfuellt / nicht auswertbar (n=%d)" % n))
if sim_any:
    print("ACHTUNG: enthaelt simulierte Funktionstest-Daten, keine Messwerte von Personen.")
