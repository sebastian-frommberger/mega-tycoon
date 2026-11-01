# T-05 Startkapital und Lizenz/Kauf-Leiter -- Ergebnis (Tobias Brandt)

Modellrechnung, keine Spielerdaten. Skripte: `t05_modell.py` (deterministisch, kein Zufall), Tabellen als CSV im selben Ordner. Eingaben: Lizenz 10 % des Kaufpreises je 30 min, im Radius -30 %, ausserhalb +3 %/Feld; 50 % der Gebuehren beim Kauf angerechnet; Werksmarge 15 %; Unterhalt 20 $/min x Stufe; Lkw 400 $ / 90 $/min; Strasse 10 $/Feld; Ertrag E = M x P_gut x D_eff x F_saett (tobias.md). Lenas HQ-Dateien (`lena/hq_startwerte.md`, `wachstumsgewichte.md`) lagen bei Abschluss nicht vor: Stadtgroessen, Radius, Baufaktoren und Startkapital stammen aus `concept/hq.md` und sind **Annahme**. Ebenfalls **Annahme** von mir: Start-Kette, Kaufpreis-Basis je Firma (Getreidefarm 1.000, Holz 1.000, Erz 1.800, Vieh 1.200, Muehle 2.000, Saegewerk 2.000, Stahlwerk 4.000, Schlachthof 2.500), Distanzen, Abnehmermarkt, Export-Fixpreis = P_gut x 40 Felder, KI-Marktanteil 40 % ab Minute 15.

## Tabelle 1: Startkapital, Lizenz- und Kaufpreise je Archetyp (Vorschlag)

| Archetyp | Startkapital neu (hq.md) | Lizenz Rohstoff / Verarb. je 30 min | Kauf Rohstoff / Verarb. | 3 Lizenzen | Startpaket | Rest nach 3 Lizenzen + Startpaket | Rest nach Kauf Verarb. + Startpaket |
|---|---|---|---|---|---|---|---|
| Agrar | **4.500 $** (30.000 $) | 70 / 140 $ | 1.000 / 2.000 $ | 350 $ | 1.367 $ | 2.783 $ | 1.133 $ |
| Hafen | **4.500 $** (25.000 $) | 70 / 140 $ | 1.000 / 2.000 $ | 350 $ | 1.460 $ | 2.690 $ | 1.040 $ |
| Bergbau | **7.000 $** (25.000 $) | 126 / 280 $ | 1.800 / 4.000 $ | 686 $ | 1.664 $ | 4.650 $ | 1.336 $ |
| Handel | **5.000 $** (20.000 $) | 84 / 175 $ | 1.200 / 2.500 $ | 434 $ | 1.325 $ | 3.241 $ | 1.175 $ |

"3 Lizenzen" = Rohstoff + Verarbeiter + eine dritte Firma zum Verarbeiterpreis, ohne Gratis-Lizenz. Startkapital = Kaufpreis Verarbeiter + 1,5 x Startpaket + Lizenz Rohstoff, aufgerundet auf 500 $.

## Tabelle 2: Break-even Lizenz vs. Kauf, 5 Startfaelle je Archetyp

Break-even Cash = Minute, ab der die Kauf-Route (Kauf in Minute 0) dauerhaft mehr Bargeld hat als die Dauer-Lizenz-Route (inkl. Werksmarge 15 %, Unterhalt, Wegfall der Lizenzgebuehr, Exklusivitaet gegen KI-Teilung). "Mit Firmenwert" rechnet 60 % des Kaufpreises als Vermoegen mit. Kapital hier unbegrenzt (reiner Wirtschaftlichkeitsvergleich).

| Archetyp | Startfall | Kauf $ | Lizenz $/30 min | Mehrertrag Besitz $/min | Break-even Cash (min) | mit Firmenwert (min) | Lizenzroute vorn (> 30 min) |
|---|---|---|---|---|---|---|---|
| Agrar | F1 Muehle: Verarbeiter im Radius, KI aus (Standard) | 2.000 | 140 | 120 | 17 | 6 | nein |
| Agrar | F2 Muehle: Verarbeiter im Radius, KI teilt Lizenz ab min 15 | 2.000 | 140 | 52 | 18 | 6 | nein |
| Agrar | F3 Muehle: Verarbeiter 12 Felder ausserhalb Radius (+36 %) | 2.720 | 272 | 124 | 22 | 8 | nein |
| Agrar | F4 Getreidefarm: Rohstoff-Firma im Radius, KI aus | 1.000 | 70 | 3 | >120 | 91 | ja |
| Agrar | F5 Muehle: Verarbeiter im Radius, kleiner Abnehmermarkt (nur 9 E/min Nachfrage = Dorf 900 Einw.) | 2.000 | 140 | -2 | >120 | >120 | ja |
| Hafen | F1 Saegewerk: Verarbeiter im Radius, KI aus (Standard) | 2.000 | 140 | 93 | 22 | 8 | nein |
| Hafen | F2 Saegewerk: Verarbeiter im Radius, KI teilt Lizenz ab min 15 | 2.000 | 140 | 39 | 31 | 8 | ja |
| Hafen | F3 Saegewerk: Verarbeiter 12 Felder ausserhalb Radius (+36 %) | 2.720 | 272 | 97 | 28 | 10 | nein |
| Hafen | F4 Holzfaeller: Rohstoff-Firma im Radius, KI aus | 1.000 | 70 | -2 | >120 | >120 | ja |
| Hafen | F5 Saegewerk: Verarbeiter im Radius, kleiner Abnehmermarkt (nur 9 E/min Nachfrage = Dorf 900 Einw.) | 2.000 | 140 | 34 | 61 | 24 | ja |
| Bergbau | F1 Stahlwerk: Verarbeiter im Radius, KI aus (Standard) | 4.000 | 280 | 109 | 35 | 14 | ja |
| Bergbau | F2 Stahlwerk: Verarbeiter im Radius, KI teilt Lizenz ab min 15 | 4.000 | 280 | 49 | 61 | 14 | ja |
| Bergbau | F3 Stahlwerk: Verarbeiter 12 Felder ausserhalb Radius (+36 %) | 5.440 | 544 | 118 | 44 | 17 | ja |
| Bergbau | F4 Erzmine: Rohstoff-Firma im Radius, KI aus | 1.800 | 126 | 11 | >120 | 61 | ja |
| Bergbau | F5 Stahlwerk: Verarbeiter im Radius, kleiner Abnehmermarkt (nur 9 E/min Nachfrage = Dorf 900 Einw.) | 4.000 | 280 | 1 | >120 | >120 | ja |
| Handel | F1 Schlachthof: Verarbeiter im Radius, KI aus (Standard) | 2.500 | 175 | 44 | 56 | 22 | ja |
| Handel | F2 Schlachthof: Verarbeiter im Radius, KI teilt Lizenz ab min 15 | 2.500 | 175 | 16 | >120 | 31 | ja |
| Handel | F3 Schlachthof: Verarbeiter 12 Felder ausserhalb Radius (+36 %) | 3.400 | 340 | 49 | 62 | 27 | ja |
| Handel | F4 Viehhof: Rohstoff-Firma im Radius, KI aus | 1.200 | 84 | 13 | 91 | 32 | ja |
| Handel | F5 Schlachthof: Verarbeiter im Radius, kleiner Abnehmermarkt (nur 9 E/min Nachfrage = Dorf 900 Einw.) | 2.500 | 175 | -8 | >120 | >120 | ja |

**Akzeptanzkriterium Startfall:** 4 von 4 Archetypen haben mindestens einen Startfall, in dem die Lizenzroute laenger als eine Lizenzperiode (30 min) vorne liegt: Agrar F4/F5 (nie), Hafen F2/F4/F5, Bergbau alle Faelle, Handel alle Faelle. Kaufen ist **nicht** immer besser (7 von 20 Faellen: nie innerhalb von 120 min), Lizenz auch nicht (Agrar F1-F3 und Hafen F1, F3: Kauf nach 17-28 min vorn). Verteilung der 20 Faelle: 5 mal Break-even <= 30 min, 8 mal 31-120 min, 7 mal > 120 min.

## Befunde

1. **Das Startkapital taktet das Spiel kaum.** Die erste Kette (Stufe 1, 20 E/min) bringt je nach Archetyp 437-959 $/min. Das hq-Startkapital entspricht 32-50 Minuten dieses Einkommens (Tabelle 3). Ein Kauf ist ab Minute 1 bezahlbar, egal ob 4.500 oder 30.000 $ am Start liegen. Entscheidend sind Break-even (17-56 min) und das Kaufangebot-Gate (M5b), nicht der Kontostand.
2. **Rabatt-Stapelung:** Kaufrabatt -20 % (lizenzierte Firma im Radius, hq.md) plus 50 % Anrechnung macht "Lizenz zuerst, nach 30 min kaufen" billiger als Direktkauf: Gesamtausgabe 0,87 x Kaufpreis (nach 1 Verlaengerung) statt 1,00; ohne Rabatt waeren es 1,07. Direktkauf ist damit nur wegen frueherer Marge sinnvoll, nie wegen des Preises. Siehe `t05_rabatt_stapelung.csv`.
3. **Besitz eines Rohstoffbetriebs lohnt nicht:** Werksmarge 15 % auf Rohstofferloes ergibt 16-30 $/min bei 20 $/min Unterhalt (Stufe 1). Break-even > 120 min, beim Holzfaeller (Hafen) sogar negativ (Marge 16 $/min < Unterhalt 20 $/min). Besitz lohnt erst beim Verarbeiter (Mehrertrag 44-120 $/min = 11-15 % der Linie).
4. **Soft-Lock-Gefahr bei knappem Kapital:** Mit knappem Kapital (K_V + 0,6 x Startpaket: Hafen 3.000 $, Bergbau 5.000 $) bleibt nach dem Direktkauf des Verarbeiters kein Geld fuer den zweiten Lkw: nur Unterhalt, nie Stufe-2-Einnahmen, Bargeld nach 90 min -1.600 bzw. -1.916 $ (`t05_softlock_test.csv`). Darum braucht der Vorschlag 1,5 x Startpaket als Puffer und einen Kreditrahmen ab Minute 0 (Empfehlung an Felix/Lena).

## Tabelle 3: Was das Startkapital bewirkt

| Archetyp | Startkapital | Min. Einkommen der ersten Kette, die das Startkapital deckt | Linie voll ab Minute (Kauf sofort / Lizenz) | Nettovermoegen Min. 30 Kauf sofort / Lizenz | Min. 60 Kauf sofort / Lizenz |
|---|---|---|---|---|---|
| Agrar (hq.md) | 30.000 $ | 35.5 | 1 / 1 | 57.282 / 54.492 $ | 85.977 / 79.597 $ |
| Hafen (hq.md) | 25.000 $ | 39.9 | 1 / 1 | 44.932 / 42.952 $ | 66.324 / 61.564 $ |
| Bergbau (hq.md) | 25.000 $ | 32.0 | 1 / 1 | 48.992 / 47.312 $ | 75.290 / 70.330 $ |
| Handel (hq.md) | 20.000 $ | 50.1 | 1 / 1 | 31.456 / 31.126 $ | 44.492 / 42.832 $ |
| Agrar (neu) | 4.500 $ | 5.3 | 1 / 1 | 31.782 / 28.992 $ | 60.477 / 54.097 $ |
| Hafen (neu) | 4.500 $ | 7.2 | 1 / 1 | 24.432 / 22.452 $ | 45.824 / 41.064 $ |
| Bergbau (neu) | 7.000 $ | 9.0 | 1 / 1 | 30.992 / 29.312 $ | 57.290 / 52.330 $ |
| Handel (neu) | 5.000 $ | 12.5 | 1 / 1 | 16.456 / 16.126 $ | 29.491 / 27.831 $ |

## Grenzen der Rechnung

Einkommen basiert auf der Ertragsformel mit Stufe-1-Durchsatz und sofortigem Aufbau (Spielerzeit fuer das Bauen fehlt). Passagiereinnahmen (Handelsknoten: 80 Fahrtwuensche/min), Lager, Zug und Sattigung durch mehrere Kunden sind nicht modelliert. Werksmarge wird als Zuschlag auf den Transportertrag der eigenen Fahrzeuge gelesen (Annahme; Lesart "nur Fremdabholer" macht Besitz noch unattraktiver). Die Kauf-Preisbasen je Firma sind meine Setzung innerhalb 1.000-4.000 $.
