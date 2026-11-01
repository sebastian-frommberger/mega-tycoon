# T-15 Teil 1 (Slice): Mehl-Exploit schließen, Zins (Tobias Brandt, Sprint 7 Block A)

Kennzeichnung: "Spiel" = gemessen mit tools/play.sh im echten Slice (deterministisch, ein Spieler je Skript). "Modell" = Modellrechnung (t13_sim, Verhalten und Karten sind Setzungen). Proxy-M7 = Kasse minus offener Kredit >= 12.000 $ (Slice hat kein M7).

## Befund (warum der erste Gedanke nicht trägt)
- Der Kredit treibt den Exploit nicht. Die Mittelfurt-Kette kostet am Start nur 2.574 $ (Lizenz Mühle 2 1.064 $, Straßen 1.510 $), Farm 3 war gratis, weil die Gratis-Lizenz auch außerhalb des Radius galt. 6.000 $ reichen ohne Kredit. Zins und Rahmen sind deshalb kein Hebel für M7 (Rendite ca. 10 %/min, Zins 1 %/min).
- Die Mehl-Menge ist durch Farm und Mühle (je 20 E/min, Stufe 1) gedeckelt, Mittelfurt (Nachfrage 120 E/min) sättigt nie. Sättigung ist also auch kein Hebel. Ein niedrigerer Mehl- oder Getreidepreis träfe Haberau und Mittelfurt (Band 35-50 min im Modell), darum nicht angefasst.
- Rund 40 % der Einnahmen kommen vom Getreide bei der Mühle (Farm 3 liegt 78 Felder entfernt), nicht vom Mehl.
- Gerechnet wird mit dem Zuschlag je Feld außerhalb des Radius: Kosten Farm 3 + Mühle 2 = 300 $ + 51 $ x Zuschlag(‰). Ab Tick-0-Kredit fließt zusätzlich Geld, das Getreide-Einkommen finanziert aber den Rest nach (gestaffelter Aufbau).

## Hebel (Reihenfolge nach Größe des Eingriffs), Werte
| Hebel | vorher | nachher | Datei |
|---|---|---|---|
| Lizenzzuschlag je Feld außerhalb Radius | 30 ‰ | 120 ‰ (Farm 3: 766 -> 2.764 $, Mühle 2: 1.064 -> 3.656 $ bei HQ Kohlberg) | data/economy_slice.json lizenz.licence_surcharge_per_field_promille, economy_constants.json lizenz.ausserhalb_zuschlag_promille_pro_feld |
| Gratis-Lizenz nur im HQ-Radius | überall | nur im Radius (neues Flag `licence_free_only_in_radius_flag`) | economy.gd (3 Zeilen), economy_slice.json |
| Kreditsperre | ab Tick 0 | ab Tick 7.200 (12 Spielminuten) | economy_slice.json kredit.credit_available_from_ticks, economy_constants.json kredit.ab_tick |
| Kredit-Zins je Minute | 1 % (10 ‰) | 3 % (30 ‰), Dauerkredit 2.000 $ kostet 60 $/min | beide JSON |
| Rahmen, Schritt | 2.000 $, 500 $ | unverändert | |
Nicht gewählt: Rahmen kleiner (trifft nur Kreditnehmer, nicht den Exploit), Sättigung (greift nicht), Mehl-/Getreidepreis (Haberau/Mittelfurt aus dem Band), Kredit-Sperre allein (ohne höheren Zuschlag baut der Spieler gestaffelt über das Getreide-Einkommen schon bei Minute 4).
Abgeleitet: `data/hq_vorschau.json` neu erzeugt (`python3 -I tools/hq_vorschau_gen.py .`), weil die Vorschau-Faktoren den Zuschlag tragen (Test d08_lizenzfaktor).

## Messung (Spiel, play.sh, Proxy-M7 in Spielminuten)
| Spielweise | vorher | nachher |
|---|---|---|
| A. Tagebuch-Befehlsfolge E1 (credit+ x4, Farm 3 + Mühle 2 sofort, 2 Gratis-Lkw, Lkw nach 8 min) | 20,1 min (Kasse 14.159 $, Kredit 2.000 $, netto 12.159 $ bei 20:06) | geht nicht: `credit +` gesperrt, "Dir fehlen 420 $", Mühle-Lizenz fehlt; bei 20:06 netto 5.310 $ |
| B. Beste Variante nachher: Getreide-Linie mit beiden Gratis-Lkw zuerst, Mühle/Straße/Lkw bei 12:06 mit 2 Kreditschritten | (nicht nötig, A war schneller) | 30,4 min (netto 9.678 $ bei 27:54, 13.318 $ bei 31:54) |
| C. Normale gute Partie: Kohlberg-Kette, ab 18:06 Mittelfurt-Ast (Kredit x4) | 32,9 min (netto 9.894 $ bei 30:00, 12.776 $ bei 34:00; Tagebuch 33) | 39,4 min (netto 7.550 $ bei 34:00, 10.992 $ bei 38:00, 13.903 $ bei 42:00) |
| D. Nur Kohlberg-Kette ohne Ast | ca. 43 min (Tagebuch, hochgerechnet) | unverändert ca. 43 min, nicht in diesem Ticket |
Zwischenwerte der Zuschlag-Suche (Spiel): bei 100 ‰ und Sperre 8 min war B 25 min, C 38,6 min; bei 125 ‰ scheiterte A am Geld, C ging bei 18:10 bankrott (zu dünn). 120 ‰ + Sperre 12 min ist der Punkt, an dem B 30 min erreicht und C unter 40 min bleibt. B und C liegen nur ca. 9 min auseinander, mit reinen Kosten-Hebeln ist kein größerer Abstand zu haben. Tuning-Spielraum nach oben fehlt: höherer Zuschlag schiebt C über 40 min.

## Modell: Bankrott (300 Läufe je Standort, Seeds 1-300 / 301-600, Kredit-Mix 35/45/15/5, 6.000 $, Karte wie T-14b)
| Variante | Mittelfurt | Haberau | Kohlberg |
|---|---|---|---|
| vorher (Zins 1 %, keine Sperre), reproduziert | 14,0 / 15,0 % | 10,7 / 13,3 % | 12,0 / 14,0 % |
| nachher (Zins 3 %, Sperre 12 min) | 16,3 / 15,0 % | 14,0 / 13,7 % | 14,7 / 14,3 % |
Zwischenvarianten: Zins 3 % allein 15,0-15,0 / 12,0-13,3 / 13,3-14,7; Sperre 5/8/10/15 min zusätzlich höchstens +1,7 Pp. Band 10-30 % bleibt überall. Median-M7 im Modell unverändert (52 / 49 / 24 min, inkl. Vorkosten). Der Zuschlag und die Gratis-Regel kommen im Modell nicht vor, weil Modellspieler nur im Radius lizenzieren. Die Zinsen schlagen im Median nicht durch (Median 0 $, weil die meisten Spieler tilgen). Skript: modell/t15_run.py (Aufruf `python3 -I t15_run.py 30 200000 12` = Zins ‰, Rahmen Cent, Sperre min), Sim modell/t13_sim.py mit einer Erweiterung (`kredit_ab_min`, Kreditsperre).
Bot im echten Spiel (d08_bankrott, Drift-Wächter, kein Spielerbeleg): vorher 2 / 35 / 38 %, nachher 2 / 38 / 39 % (Mittelfurt/Haberau/Kohlberg), Korridor eingehalten.

## Tests
- `bash tests/d07_regression.sh <godot> /home/claude/mega-tycoon/spikes` aus slice/: GRÜN (alle 13 Suiten, 621 s; slice_test 74/74, d07 kredit 17/17, d08_lizenzfaktor 8/8, d08_bankrott-Wächter 10/10). Erster Lauf nach der Datenänderung war rot (slice_test 3, kredit 5, lizenzfaktor 5 Fehler), siehe nächste Zeilen.
- Angepasste Erwartungen (begründet): slice_test.gd und d07_abnahme.gd Block Kredit liefen bisher implizit mit Kredit ab Tick 0 (Aufnehmen direkt nach der HQ-Gründung). Sie prüfen jetzt zuerst die Sperre (neu: "S7 T-15 Kredit vor Tick 7200 gesperrt", "B0") und spulen dann bis `credit_available_from_ticks` vor. Ohne die Anpassung wären B7/B10/B11 leer durchgelaufen (Kredit 0, grün ohne Aussage). Neu: "S7 T-15 Gratis-Lizenz nur im HQ-Radius" (slice_test.gd).
- d08_lizenzfaktor: Vorschau-Datei neu erzeugt (kein Testcode geändert).

## Geänderte Dateien (Arbeitskopie /tmp/claude-0/gd/sprint7/a/tobias/slice)
data/economy_slice.json, data/economy_constants.json, data/hq_vorschau.json (generiert), economy.gd (Flag, 3 Zeilen), tests/slice_test.gd, tests/d07_abnahme.gd. main.gd und credit.gd unberührt. Sicherung der Ausgangsstände: ../slice_vorher (vollständige Kopie vor der Änderung, für Vorher-Läufe).
Belege: play/ (Befehlsfolgen und state.md je Lauf: vorher/, g/ nachher, h/ vorher Partie C, e/ f/ b/ c/ Zwischenstände), modell/ (Skripte, Logs t15_log_*.txt).

## Offene Punkte für andere
- UI (Mira/Aylin, U-03): Der [+]-Knopf ist in den ersten 12 min nur grau, ohne Grund. Der Hinweistext fehlt in main.gd ("Kredit ab Minute 12", Tooltip). Ohne Text wirkt es wie ein Fehler.
- Pure Kohlberg-Kette (Spielweise D) bleibt ca. 43 min, der Modell-M7 für Kohlberg (24 min) und das Spiel (33-43) liegen weiter auseinander. Hebel dafür sind Stahlpreis/Zubringer (Vorschlag S6), gehört zu T-16/Block B, nicht hierher.
- HQ-Umsetzen nach Mittelfurt (2-min-Fenster) wurde nicht getestet; ein Mittelfurt-HQ kann die Kette ohnehin im Radius und schneller starten (Radius-Rabatt 0,70), das ist die Standortlogik, kein Exploit.
- Auto-Verlängerung kostet für die Fernlizenzen alle 30 min den hohen Preis (bei 120 ‰ rund 6.400 $ für Farm 3 + Mühle 2): fällig 30 min nach dem Kauf, bei B (Kauf 12:06) bei 42:06, bei C (Kauf ca. 18:06) bei 48:06, also nach M7.
