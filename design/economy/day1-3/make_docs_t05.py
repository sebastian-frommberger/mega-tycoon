#!/usr/bin/env python3
"""Baut t05_ergebnis.md aus den CSV-Dateien (Tabellen werden nicht von Hand getippt)."""
import csv
rd = lambda f: list(csv.DictReader(open(f, encoding="utf-8"), delimiter=";"))
fmt = lambda x: f"{int(round(float(x))):,}".replace(",", ".")
neu = {r["Archetyp"]: r for r in rd("t05_startkapital_neu.csv")}
hq = {r["Archetyp"]: r for r in rd("t05_archetypen_hq_ist.csv")}
be = rd("t05_breakeven.csv")
pin = rd("t05_startkapital_pinch.csv")

t1 = ["| Archetyp | Startkapital neu (hq.md) | Lizenz Rohstoff / Verarb. je 30 min | Kauf Rohstoff / Verarb. | 3 Lizenzen | Startpaket | Rest nach 3 Lizenzen + Startpaket | Rest nach Kauf Verarb. + Startpaket |",
      "|---|---|---|---|---|---|---|---|"]
for a in neu:
    n, h = neu[a], hq[a]
    t1.append(f"| {a} | **{fmt(n['C_neu'])} $** ({fmt(h['Startkapital_hq'])} $) | {fmt(h['Lizenz_R_je30min'])} / {fmt(h['Lizenz_V_je30min'])} $ | {fmt(h['K_R'])} / {fmt(h['K_V'])} $ | {fmt(n['Drei_Lizenzen_Summe'])} $ | {fmt(n['S0'])} $ | {fmt(n['Rest_Casual_nach_Startpaket_und_3Lizenzen'])} $ | {fmt(n['Rest_nach_Kauf_und_Startpaket'])} $ |")

t2 = ["| Archetyp | Startfall | Kauf $ | Lizenz $/30 min | Mehrertrag Besitz $/min | Break-even Cash (min) | mit Firmenwert (min) | Lizenzroute vorn (> 30 min) |",
      "|---|---|---|---|---|---|---|---|"]
for r in be:
    t2.append(f"| {r['Archetyp']} | {r['Fall']} {r['Firma']}: {r['Beschreibung']} | {fmt(r['Kaufpreis'])} | {fmt(r['Lizenz_je30min'])} | {fmt(r['Mehrertrag_Besitz_pro_min'])} | {r['Break_even_Cash_min']} | {r['Break_even_Netto_min']} | {'ja' if r['Urteil_Schwelle_30min']=='Lizenz vorn' else 'nein'} |")

t3 = ["| Archetyp | Startkapital | Min. Einkommen der ersten Kette, die das Startkapital deckt | Linie voll ab Minute (Kauf sofort / Lizenz) | Nettovermoegen Min. 30 Kauf sofort / Lizenz | Min. 60 Kauf sofort / Lizenz |",
      "|---|---|---|---|---|---|"]
for r in pin:
    lab = "hq.md" if r["Variante"].startswith("hq") else "neu"
    t3.append(f"| {r['Archetyp']} ({lab}) | {fmt(r['Startkapital'])} $ | {r['Startkapital_in_min_Einkommen']} | {r['K0_t_Linie_voll']} / {r['L_t_Linie_voll']} | {fmt(r['K0_NW_min30'])} / {fmt(r['L_NW_min30'])} $ | {fmt(r['K0_NW_min60'])} / {fmt(r['L_NW_min60'])} $ |")

doc = f"""# T-05 Startkapital und Lizenz/Kauf-Leiter -- Ergebnis (Tobias Brandt)

Modellrechnung, keine Spielerdaten. Skripte: `t05_modell.py` (deterministisch, kein Zufall), Tabellen als CSV im selben Ordner. Eingaben: Lizenz 10 % des Kaufpreises je 30 min, im Radius -30 %, ausserhalb +3 %/Feld; 50 % der Gebuehren beim Kauf angerechnet; Werksmarge 15 %; Unterhalt 20 $/min x Stufe; Lkw 400 $ / 90 $/min; Strasse 10 $/Feld; Ertrag E = M x P_gut x D_eff x F_saett (tobias.md). Lenas HQ-Dateien (`lena/hq_startwerte.md`, `wachstumsgewichte.md`) lagen bei Abschluss nicht vor: Stadtgroessen, Radius, Baufaktoren und Startkapital stammen aus `concept/hq.md` und sind **Annahme**. Ebenfalls **Annahme** von mir: Start-Kette, Kaufpreis-Basis je Firma (Getreidefarm 1.000, Holz 1.000, Erz 1.800, Vieh 1.200, Muehle 2.000, Saegewerk 2.000, Stahlwerk 4.000, Schlachthof 2.500), Distanzen, Abnehmermarkt, Export-Fixpreis = P_gut x 40 Felder, KI-Marktanteil 40 % ab Minute 15.

## Tabelle 1: Startkapital, Lizenz- und Kaufpreise je Archetyp (Vorschlag)

{chr(10).join(t1)}

"3 Lizenzen" = Rohstoff + Verarbeiter + eine dritte Firma zum Verarbeiterpreis, ohne Gratis-Lizenz. Startkapital = Kaufpreis Verarbeiter + 1,5 x Startpaket + Lizenz Rohstoff, aufgerundet auf 500 $.

## Tabelle 2: Break-even Lizenz vs. Kauf, 5 Startfaelle je Archetyp

Break-even Cash = Minute, ab der die Kauf-Route (Kauf in Minute 0) dauerhaft mehr Bargeld hat als die Dauer-Lizenz-Route (inkl. Werksmarge 15 %, Unterhalt, Wegfall der Lizenzgebuehr, Exklusivitaet gegen KI-Teilung). "Mit Firmenwert" rechnet 60 % des Kaufpreises als Vermoegen mit. Kapital hier unbegrenzt (reiner Wirtschaftlichkeitsvergleich).

{chr(10).join(t2)}

**Akzeptanzkriterium Startfall:** 4 von 4 Archetypen haben mindestens einen Startfall, in dem die Lizenzroute laenger als eine Lizenzperiode (30 min) vorne liegt: Agrar F4/F5 (nie), Hafen F2/F4/F5, Bergbau alle Faelle, Handel alle Faelle. Kaufen ist **nicht** immer besser (7 von 20 Faellen: nie innerhalb von 120 min), Lizenz auch nicht (Agrar F1-F3 und Hafen F1, F3: Kauf nach 17-28 min vorn). Verteilung der 20 Faelle: 5 mal Break-even <= 30 min, 8 mal 31-120 min, 7 mal > 120 min.

## Befunde

1. **Das Startkapital taktet das Spiel kaum.** Die erste Kette (Stufe 1, 20 E/min) bringt je nach Archetyp 437-959 $/min. Das hq-Startkapital entspricht 32-50 Minuten dieses Einkommens (Tabelle 3). Ein Kauf ist ab Minute 1 bezahlbar, egal ob 4.500 oder 30.000 $ am Start liegen. Entscheidend sind Break-even (17-56 min) und das Kaufangebot-Gate (M5b), nicht der Kontostand.
2. **Rabatt-Stapelung:** Kaufrabatt -20 % (lizenzierte Firma im Radius, hq.md) plus 50 % Anrechnung macht "Lizenz zuerst, nach 30 min kaufen" billiger als Direktkauf: Gesamtausgabe 0,87 x Kaufpreis (nach 1 Verlaengerung) statt 1,00; ohne Rabatt waeren es 1,07. Direktkauf ist damit nur wegen frueherer Marge sinnvoll, nie wegen des Preises. Siehe `t05_rabatt_stapelung.csv`.
3. **Besitz eines Rohstoffbetriebs lohnt nicht:** Werksmarge 15 % auf Rohstofferloes ergibt 16-30 $/min bei 20 $/min Unterhalt (Stufe 1). Break-even > 120 min, beim Holzfaeller (Hafen) sogar negativ (Marge 16 $/min < Unterhalt 20 $/min). Besitz lohnt erst beim Verarbeiter (Mehrertrag 44-120 $/min = 11-15 % der Linie).
4. **Soft-Lock-Gefahr bei knappem Kapital:** Mit knappem Kapital (K_V + 0,6 x Startpaket: Hafen 3.000 $, Bergbau 5.000 $) bleibt nach dem Direktkauf des Verarbeiters kein Geld fuer den zweiten Lkw: nur Unterhalt, nie Stufe-2-Einnahmen, Bargeld nach 90 min -1.600 bzw. -1.916 $ (`t05_softlock_test.csv`). Darum braucht der Vorschlag 1,5 x Startpaket als Puffer und einen Kreditrahmen ab Minute 0 (Empfehlung an Felix/Lena).

## Tabelle 3: Was das Startkapital bewirkt

{chr(10).join(t3)}

## Grenzen der Rechnung

Einkommen basiert auf der Ertragsformel mit Stufe-1-Durchsatz und sofortigem Aufbau (Spielerzeit fuer das Bauen fehlt). Passagiereinnahmen (Handelsknoten: 80 Fahrtwuensche/min), Lager, Zug und Sattigung durch mehrere Kunden sind nicht modelliert. Werksmarge wird als Zuschlag auf den Transportertrag der eigenen Fahrzeuge gelesen (Annahme; Lesart "nur Fremdabholer" macht Besitz noch unattraktiver). Die Kauf-Preisbasen je Firma sind meine Setzung innerhalb 1.000-4.000 $.
"""
open("t05_ergebnis.md", "w", encoding="utf-8").write(doc)
print("ok")
