# Sprint 7 – Review und Retro (02.11.2026, über Nacht ohne Basti)

## Review (Jonas)
**Sprintziel erreicht, mit Auflagen:** Die neue Welt `--welt=s7` ist spielbar (Daniel: 5 von 5 Starts erreichen die erste Kette, kein Blocker). Der Default bleibt bis zu Bastis Rundgang der alte Slice.
- **Maßstab (W-01):** 1 Feld = 25 m, 512² Felder = 12,8 km spielbar plus 7,5 km Randlandschaft, Kamera 40 m bis 5,6 km, Fahrzeuge in Feldern wie bisher (Sim-Parität exakt).
- **Gelände (W-02):** Vorgebackene Heightmap (Seed 7, 29–1.083 m), Fluss als Rinne, Gebirgsring am Rand, Kamera sieht bei Max-Zoom weder Himmel noch Kante. Höhe zählt in der Sim nur für Baukosten und die Sperre „zu steil“.
- **Generator (W-06):** `tools/world_gen.py` und `world_validate.py`, gleicher Seed = gleiche Dateien (md5), 20 von 20 Seeds ohne Regelverstoß.
- **Städte (W-03):** Raster mit Zonen, Ausfransung an Ausfallstraßen, Bahnhof am Rand, drei Stufen (Dorf 228 m, Kleinstadt ~450 m, Stadt ~800 m Radius).
- **Straßen und Gleise (W-04):** Kenney-Kacheln, schmal, Kurven und Kreuzungen, Brücken; Stadtanschluss repariert (Z-01).
- **Industrie-Lage und Lesbarkeit (W-05):** Lage-Regeln R1–R8 (Farm in Ebene/Aue, Mine am Gebirgsfuß, Mühle am Fluss oder Stadtrand …), Signalflächen und Plaketten, aus 4 km lesbar.
- **Balance (T-15):** Zug:Lkw 2,9:1, Kredit ab Minute 12, 3 % Zins, Bankrottquote 15 %/17 %/18 % im Band, Mehl-Exploit geschlossen (M7 30,4 statt 20 min).
- **U-03 / U8:** Fehlertexte mit Lösung, Vorwarnung 90 s vor dem Bankrott, „Nächster Schritt“ mit Preis.
- **Perf-Gate S7:** Übersicht 0,76 M Dreiecke / 250 Draw Calls (Gate 1,0 M / 300), Stadt nah 1,15 M (Gate 2,9 M), Ladezeit 2,0–2,2 s. Gemessen sind Zählwerte, keine FPS.
- **Regression:** 21 Suiten grün, neu: s7_boot, s7_validator, s7_city, s7_industrie, s7_w04, s7_u03, s7_mira, u03_play (S7).

**Abnahme (Daniel):** abgenommen: Nahsicht der Städte, Industrie-Plaketten, Breite der Straßen und Gleise, Gebirge und Fluss mit Auflage. Nicht abgenommen: Städte aus der Übersicht (Raster, gleiche Rautenform), HQ-Vorschau „Wagnis“.

**Nicht geschafft / verschoben nach S8:** Firmenkauf (F-22), Skilltree-Bau (SK-02), A-08 Diagnose-Toast, Terrain-LOD (Geomipmapping), Stadtbrücken, Städte-Silhouetten, Verteilung der Industrien in Revieren (M1), Gleis-Grenze 12 %, neuer Bench-Lauf auf Bastis Rechner, Initial-Window-Fix.

## Retro (Katrin)
- **Gut:** Der Schalter `--welt=s7` ließ den Slice unberührt, jeder Block ging einzeln durch die Regression. Daniels Spielen auf der echten Karte fand, was die Suiten nicht fanden (Labels FOV, Brückenrampe, play.sh-Projektion). Der Perf-Messfehler (Faktor 2,5) wurde durch Nachrechnen entdeckt, nicht durch Kürzen.
- **Schlecht:** Mehrere Tests liefen auf der Platzhalterkarte und wurden rot, sobald die echte Karte kam (s7_city, s7_industrie, play.sh). Zwei Agenten rannten ins 5-Stunden-Limit; Fable-Läufe verbrauchen es sehr schnell.
- **Ändern:** (1) Tests auf der echten Karte schreiben, sobald sie existiert (Daniel-Kandidaten 1–3, 8, 9). (2) Spiel und Validator rechnen dieselbe Regel (Brückenrampe als Vorbild). (3) Kein Fable ohne Basti-Freigabe; Opus/Sonnet für Standardarbeit, Sprint-Takt an das Limit anpassen.
- **Rolle:** TEAM-02 (Technical Artist / Level Designer) ab S8, begründet durch die Pipeline aus S7 (Heightmap, Generator, Validator, LOD, Baum-Deckel). Sophie war der Engpass für Terrain, Städte und Look.

## Kandidaten Sprint 8
1. Firmenkauf (R2) und Skilltree-Bau; Progression nach M7 (G-01: Stadtwachstum, Druck).
2. Energie und Mitarbeitende (Bastis Anregung 02.11.): Städte stellen Arbeitskräfte, Kraftwerke versorgen Industrie und Stadt, Gewerbe bringt Boni. Als Konzept (Lena, Tobias), Karte mit Radien statt Zahlenpflege. Zahlen aus der Slice-Regelung (Energie-Radius 25 Felder, +25 %, Arbeit 80–110 %) existieren, im Code ist nichts davon aktiv.
3. Industrie-Ebenen (Rohstoff, Veredelung, Produktion), Verteilung ohne Baukasten-Cluster, Süd-Zentrum ohne Industrie (Daniel M1/M2).
4. HQ-Vorschau „Wagnis“ aus der echten Kettenrechnung (Daniel H3), Radius an den S7-Maßstab.
5. Städte aus der Übersicht (Silhouetten, kein Millimeterpapier), Stadtbrücken, Terrain-LOD, Schnee und Randmarkierung der Baufläche.
6. S7-Welt als Default; Tempo-Frage (Fahrzeuge wirken schneller als real?) nach Bastis Rundgang; neuer Bench auf dem Zielrechner.
