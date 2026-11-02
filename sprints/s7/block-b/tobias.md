# T-15 Teil 2 und T-16 (Tobias Brandt, Sprint 7 Block B)

"Spiel" = play.sh im echten Slice (deterministisch). "Modell" = Modellrechnung (t13_sim, Setzungen). Arbeitskopie: /tmp/claude-0/gd/sprint7/b/tobias/slice (Vorher-Kopie: ../slice_vorher). Belege: play/, bot/, modell/.

## 1. Zug : Lkw (Farm 2 -> Mühle 2, Lkw 149 Felder, Gleis 133 Felder, Lenas Situation ab 42:06, Gewinn/min der Linie, Spiel)
Änderung data/vehicles.json: Dampflok Fix 90 -> 170 $/min, Güterwaggon 10 -> 6 E (Zug 40 -> 24 E). Gleispreis, Lkw, Tempo unverändert.
| Fenster (Alter der Linie) | Zug vorher | Zug nachher | 1 Lkw | 3 Lkw |
|---|---|---|---|---|
| 8 min (Lenas Messung) | 1.091 | 518 | 105 | – |
| 8-80 min | 490 | 466 | 102 | – |
| 80-140 min (Altbestand verbraucht, stabil) | 352 | 282 | 97 | 227 |
Verhältnis stabil: Zug : 1 Lkw 3,6 -> 2,9 : 1; Zug : 3 Lkw (volle Auslastung der Farm) 1,6 -> 1,2 : 1. Nach Gleisunterhalt (64 $/min) liegt der Zug auf Höhe von 3 Lkw, trägt aber 24 E/Fahrt (Platz für zweite Quelle). Zug dominiert nicht mehr.
**Nicht erfüllt: das Anfangsfenster.** Zug : 1 Lkw bleibt 4,9 : 1 (statt 10,4 : 1) in den ersten ~80 min nach dem Kauf. Ursache (Befund): Rohstoffquellen sammeln Bestand ab Spielstart (s_born in economy.gd), nicht ab der ersten Lizenz; Farm 2 hat bei Lizenzkauf 17:06 schon ~340 E, bei 42 min ~840 E. Ein Zug leert das in Minuten. Mit Gewinn pro Einheit nur ca. 30-100 % (Los-Alter). Weitere Daten-Hebel würden den stabilen Zustand unter den Lkw drücken (Zug lohnt nie). Vorschlag (nicht gemacht, economy.gd, ändert die Kalibrierung aus Block A): Bestand erst ab Erstlizenz (3 Zeilen in buy_licence). Danach wäre das Anfangsfenster gleich dem stabilen 2,9 : 1. Entscheidung Jonas/Felix.
Modell: modell/zug_lkw.py (grob, Lkw-Ladezeit überschätzt; Spiel gilt).

## 2. Wagnis-Vorschau (tools/hq_vorschau_gen.py, data/hq_vorschau.json neu erzeugt)
Hinweis ist jetzt gerechnet (günstigste Mehl-Startkette in 2 Bauschritten, Lizenzfaktor wie Spiel, Gratis nur im Radius, Farm-Linie finanziert Schritt 2 abzüglich Verlängerung). Geeicht: Steinbach Rechnung 4.181 $, Spiel 4.258 $.
Messung nach Block A (Spiel): Steinbach 7/7 bei 5:32, Kasse 24.035 $ nach 45 min (vorher 27.776), tiefster Stand 2.171 $. Eichwald 7/7 bei 5:32, 8.935 $ nach 25 min. Weidenau (Farm 2, kurze Linie) bleibt bei 206 $ stehen, "Kasse reicht noch ~8 s" bei 30 min: Farm-Linie trägt sich nicht.
Texte: Steinbach "Spielbar, aber teuer: Startkette ca. 4.200 $ von 6.000 $, Absatz Mittelfurt." Eichwald "Spielbar, aber knapp: ... Mühle ab Minute 5 bezahlbar." Lindach und Weidenau "Farm-Linie trägt sich nicht ... Im Slice nicht spielbar." Seehafen "Zäh: ... Mühle erst ab Minute 141". Seehafen und Lindach nicht im Spiel nachgespielt (Brücke "nur geradeaus" im Weg), nur Rechnung.

## 3. T-16 Bankrott-Bot (tests/d08_bankrott.gd)
Bot spielt jetzt wie die Modell-Spieler: Typen sorgfältig/normal/hastig (Bauverzögerung, Extra-Lkw, 50 % Fehlverbindung bei hastig), Kredit nie/bedarf/voll/hebel 35/45/15/5 (erst ab Sperre), Lkw je Strecke nach Bedarf (20 E/min), alles auf einmal bei Bezahlbarkeit, ungerade Seeds mit Lager-Zweitinvestition. Alter Bot (Lkw 1-3 zufällig): 2/38/39 %.
Ohne Kalibrierfaktor: 6/18/6 %. Gefittet (nicht gemessen): Extra-Faktor je Standort KALIB Mittelfurt/Kohlberg 2, Haberau 1 (Hebel 2). Begründung: Auf den echten, längeren Karten von Mittelfurt und Kohlberg ist die Kette ertragreicher als im Modell (Modell-Mittelfurt: Farm 28 Felder, echte Strecke 83); dieselbe Pleitenähe braucht doppelt so viele Extra-Lkw. Das zeigt: Echtes Mittelfurt ist leichter als das Modell sagt.
Ergebnis 300 Läufe je Standort (Bot / Modell Seeds 1-300): Mittelfurt 14,3 / 16,3, Haberau 18,3 / 14,0 (Hebel 2), Kohlberg 14,0 / 14,7 -> alle innerhalb ±5 Pp. Haberau am Rand (4,3 Pp).
Erwartungen: B3 neu (Bot gegen Modellquote; bei n >= 300 ±5 Pp, bei n=100 ±10 Pp wegen Rauschen, Regression läuft n=100), B4 neu (sorgfältig ohne Kredit nie pleite), alter Wächter-Korridor entfällt. Strenger Lauf: `godot --headless --path . -s res://tests/d08_bankrott.gd -- --n=300`.

## 4. Band 10-30 % (Modell, 300 Läufe, Zins 3 %, Sperre 12 min, Fahrzeugdaten aus Block B)
Seeds 1-300: Mittelfurt 16,3, Haberau 14,0, Kohlberg 14,7. Seeds 301-600: 15,0 / 13,7 / 14,3. Band hält (Skript modell/t16_band.py). Zug-Änderungen berühren das Modell nicht.

## Regression
Siehe Ende der Notiz.

## Offen
- Bestand ab Spielstart statt ab Erstlizenz (siehe 1): Entscheidung nötig.
- Steinbach-Eichwald-Hinweistexte nutzen Gewinn Farm-Linie nach Eichung; bei neuer Karte (S7-Welt) neu erzeugen.

## Regression (Block B, slice/ Arbeitskopie, Laufzeit ca. 30 min)
Grün: slice_test 74/74 (soa und alt), d07_abnahme ui/kredit/parity/lager/hq, d08_bankrott 10/10 (n=100: Mittelfurt 15, Haberau 17, Kohlberg 18 %), d08_lizenzfaktor 8/8, s7_mira 33/33, u03_play slice und s7.
**Rot, nicht von mir:** s7_w04 (2 SCRIPT ERROR "visible on bool", tritt in slice_vorher ohne meine Änderungen gleich auf; Tests 23/23 OK) und s7_u03 (6 Fehler: B8, L12, K1 je Welt; Kredit-Hinweistext "Kredit ab Minute 12" und Länge 124 Zeichen, UI-Text in main.gd, Mira/Aylin U-03). Meine Dateien (vehicles.json, hq_vorschau.json, Generator, d08_bankrott.gd) berühren beides nicht. Daher: Regression gesamt NICHT grün, offen bei Mira.
