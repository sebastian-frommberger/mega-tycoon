**Zweck:** Stadtmodell der Welt: Haustypen, Ortsklassen, Dorfformen, Wachstum, Stadt-KI, belebte Ortslagen. Grundlage für W-03 (Generator) und die Prototyp-Szene.
**Status:** Skizze, Phase 2 (Stadt-/Level-Designer, 02.11.2026). Zahlen maschinenlesbar in `07_regeln_vorschlag.json`.

Kennzeichnung: **[Q]** Quelle (referenzen.md bzw. Repo-Datei), **[~]** Fachwissen, vor Festlegung prüfen, **[A]** Annahme dieser Rolle. 1 Feld = 25 m, 40 Felder = 1 km. Zeitbasis aus dem Repo [Q `economy_constants.json`]: 1 Spielmonat = 600 Ticks = 60 s bei 1×, 1 Spieljahr = 12 min.
**Abgleich:** Maße, Ortsgrößen und Startjahr-Bänder sind mit `01_skalen.md` und `03_welt_prinzipien.md` (Art Director) abgeglichen. Eigene Abweichungen stehen in den Positionen (Umland-Modell, Erz im Fernband, Dorfabstand mit V9 statt 1,5 km).

## 0. Ausgangslage S7 und Ziel

| | S7 heute [Q `rules_s7.json`, `city_gen.gd`] | Ziel |
|---|---|---|
| Form | ein Raster 75 m, Rautensilhouette, Zonen Kern/Mitte/Rand | Dorfformen nach Gelände, Wege folgen dem Relief, Raster nur im Bahnhofsviertel |
| Größe | Dorf r 225 m ≥ 80 Geb., Kleinstadt r 450 m ≥ 400, Stadt r 800 m ≥ 1.200 | Dorf r 125–200 m mit 25–60 Geb., keine Stadt zum Start 1820 (Abschnitt 2) |
| Herleitung | Radius → Gebäude füllen | **Einwohner → Haustypen → Gebäudezahl → Fläche** (Bastis Vorgabe) |
| Wachstum | nur Sim-Zahl, Bild statisch | Stadt-KI: Lücken, Upgrade am Platz, Vorstadt, Gassen |
| Blöcke | leere graue Kernhöfe (Daniel), Bäume in Lücken | Hofstellen mit Nebengebäude, Garten, Zaun, Baum, Bodenfarbe |

## 1. Haustypen

Maße real = Spiel (E1, Faktor 1,0, keine Überhöhung, auch nicht für Kirchtürme: Art Director 01, G2/G3). Abgeglichen mit `01_skalen.md` (Tab. A, F). Kenney-Basis laut asset_audit (Fantasy Town, Modul 3 m). „Felder“ = Parzellenfläche in Feldern.

| Typ | Stufe | Grundriss m | Geschosse / First m | EW (Ø) | Parzelle m (Felder) | Ort ab | Quelle |
|---|---|---|---|---|---|---|---|
| Kate (Tagelöhner) | S | 8×6 | 1 / 6–7 | 4–6 (5) | 12,5×25 (0,5) | Weiler | [~] ref 1c, 01 |
| Bauernhof (Wohnstallhaus + Scheune) | M-Dorf | Haus 12×9, Scheune 18×10 | 1½ / 9–11 | 6–10 (8) | **25×25 (1,0)** | Weiler | [~], 01 „1 Hof = 1 Feld“ |
| Großhof (Dreiseithof) | L-Dorf | Haus 12×9, Scheune 18×10, Stall 12×8 | 2 / 11 | 10–14 (12) | 37,5×37,5 (2,25) | Dorf | [~] |
| Handwerkerhaus | M | 9×12 | 2 / 9–11 | 6–9 (7) | 12,5×25 (0,5) | Dorf | [~] ref 1c, asset_audit |
| Bürgerhaus | L | 12×14 | 3 / Traufe 12, First 15 | 12–20 (14) | 12,5×37,5 (0,75) | Marktflecken | [~], 01 |
| Mietshaus mit Hinterhaus | XL | 16×12 + 8×10 | 4 / 16–18 | 25–40 (30) | 16×40 (1,0) | Kleinstadt ≥ 4.000, **Jahr ≥ 1840** | [~], 01 |
| Kirche + Kirchhof | Sonder | Dorf 20×10, Stadt 35×15 | Turm 30 / 45–55 | 0 | 37,5×37,5 / 62,5×50 | Dorf | [~], 01 (oberes Band statt Faktor) |
| Kapelle | Sonder | 10×7 | Dachreiter 12 | 0 | 15×15 | Weiler (1 von 3) | [A] |
| Pfarrhaus | Sonder | 12×10 | 2 / 10 | 5 | 25×30 | Dorf | [~] |
| Gasthaus | Sonder | 14×12 | 2 / 11 | 6–8 | 25×35 | Dorf | [~] |
| Schmiede | Sonder | 9×7 + Hof | 1 / 6 | 4–6 | 15×20 | Dorf (Anger, Ortseingang) | [~] ref 1c |
| Schule | Sonder | 12×9 | 1–2 / 9 | 2 | 20×25 | Dorf ≥ 250 EW | [A] |
| Rathaus/Amtshaus | Sonder | 16×12 | 3 / 14 | 0–4 | 18×25 | Marktflecken | [~] |
| Speicher/Lagerhaus | Sonder | 20×12 | 3 / 13 | 0 | 25×30 | Marktflecken | [~] |
| Stadttor/Mauerturm | Sonder | 8×8 | Turm 15–20 | 0 | – | Kleinstadt (Mauer 1820 zu 70 % erhalten, Hebel) | [~] ref 1b |
| Bahnhof (Empfangsgebäude) | Sonder | 30×12 | 2 / 10, Bahnsteig 110 | 2–4 | 40×150 | **nur durch Spieler**, Jahr ≥ 1835 | [Q] ref 3, 01 |
| Nebengebäude (Scheune, Stall, Schuppen) | Neben | 6×4 bis 18×10 | 1 / 4–10 | 0 | auf Hof-Parzelle | alle | [~] |

**Ø EW je Wohnhaus nach Ortsklasse** [A, aus Mix]: Weiler 7, Dorf 7 (S 30 %, M 70 % wie 01: Kate 30 %, Hof 60 %, Handwerker 10 %), Marktflecken 8,5, Kleinstadt 11, Stadt 14.
**Parzellen** liegen auf dem 12,5-m-Halbfeld-Unterraster aus 01 (Jitter ±2 m, ±8°). Die Sim zählt Gebäude und EW je Feld über den Mittelpunkt.

Positionen:
- **Sophie:** 7 Wohntypen + 10 Sonderbauten sind 25–30 Prefabs (asset_audit: 10–14 geplant). Vorschlag: Sonderbauten Kirche, Gasthaus, Schmiede zuerst; Pfarrhaus/Schule als Farbvariante Handwerkerhaus.
- **Lena (Gegenposition):** Spieler sehen Typen nicht einzeln; 4 Stufen (S/M/L/XL) + Kirche reichen. Mehr Typen sind Art-Aufwand ohne Spielwirkung.
- **Empfehlung:** Daten mit allen Typen (Generator kennt sie), Prefabs in zwei Wellen: Welle 1 Kate, Hof, Handwerker, Bürger, Kirche, Gasthaus, Schmiede (7); Welle 2 Rest als Varianten.

## 2. Ortsklassen

**Ort-EW** = in Häusern sichtbar (Σ Haus-EW ±10 %). **Umland-EW** = Gemarkung (Einzelhöfe, Weiler, Gesinde, Mühlen). **Sim-EW = Ort + Umland** geht unverändert in die Ökonomie (Abschnitt 6).

Ort-EW-Bänder = Startjahr 1820 aus `03_welt_prinzipien.md` Abschnitt 4, Radien/Dichten aus `01_skalen.md` Tab. F.

| Klasse | Ort-EW (1820) | Umland-EW | Sim-EW → Sim-Stufe | Wohnhäuser + Sonder (= Hauptgeb.) | Radius Ortslage | Dichte EW/ha | Formen | Anzahl Start 1820 |
|---|---|---|---|---|---|---|---|---|
| Weiler | 20–60 | – (zählt zum nächsten Ort) | kein Knoten | 4–10 Höfe | 40–75 m | – | Weiler | 6–12 (Kulisse, ohne Label) |
| Dorf | 150–350 | 250–550 | 400–900 → dorf | 22–50 + 3–6 = **25–56** | 125–200 m (Straßendorf 400–800 m lang) | 25–40 | Haufen, Straße, Anger | **12–16** |
| Marktflecken | 800–1.300 | 400–600 | 1.200–1.900 → kleinstadt | 94–153 + 8–12 = **100–165** | 175–250 m | 60–100 | Haufendorf + Marktplatz | 2–3 |
| Kleinstadt (Amtsstadt) | 2.000–4.000 | 400–700 | 2.400–4.700 → kleinstadt | 180–365 + 12–18 = **195–380** | Kern 200–300 m (Mauer), Vorstädte bis 350–450 m | Kern 120–200, Vorstadt 40 | Mauerkern + Vorstädte | 1–2 |
| Stadt | 10.000–20.000 | 500–1.000 | 10.500–21.000 → stadt/metropole | 900–1.500 | 600–900 m | 150–250 | Altstadt, Ring (≥ 1840), Vorstädte, Bahnhofsviertel | **0** (nur Wachstum, Startjahr ≥ 1860: 0–1) |

**Sim-Stufe und Ortsklasse sind entkoppelt:** Die Sim-Stufe (Schwellen 1.000 / 5.000 / 20.000 [Q `wachstum`]) steuert Warenkorb und Nachfrage. Die Ortsklasse steuert das Bild. Eine Kleinstadt mit Ort-EW ≥ 4.300 ist in der Sim schon „stadt“, sieht aber bis Ort-EW 10.000 wie eine Kleinstadt aus.

Herleitung [~] ref 1a: Dorf 100–400 EW / 15–60 Häuser, Marktflecken 800–2.000, Kleinstadt 2.000–5.000, Mittelstadt 10.000+. Ort-Summe Start ≈ 8.000–13.000 EW sichtbar (03: 9–12k), Sim-Summe ≈ 14.500–22.000 (S7: 36.250). Reale Dichte 60–100 EW/km² auf 164 km² = 10.000–16.000 [~] ref 1a: passt.

Gegen S7: Dorf 0,4× Gebäude, Kleinstadt-Kern 0,55× Radius, keine Stadt. Hauptgebäude gesamt Start ≈ 1.500 (S7 ≥ 4.500).

Positionen:
- **Tobias:** Sim-EW pro Dorf darf nicht fallen (T-15: Mühle→Haberau +399 $/min bei 750 EW). Das Umland-Modell hält die Dorf-Bänder. Die Summe sinkt auf 40–60 % von S7 statt auf ein Drittel (03 rechnet ohne Umland mit 12k), dafür gibt es 4–9 Knoten mehr. Eine T-15-Stichprobe ist nötig.
- **Lena (Gegenposition):** Eine Zahl am Label, die nicht zu den Häusern passt, ist unehrlich. Lieber Ort-EW = Sim-EW und Nachfrage über `demand_mult` anpassen.
- **Empfehlung:** Umland-Modell (Ökonomie bleibt), Label zeigt Sim-EW mit Zusatz „inkl. Gemarkung“ im Tooltip (Aylin). Siehe Streitpunkt 1.

## 3. Dorfformen und Generator-Schritte

Gemeinsam für alle Formen [A]:
- **Wege** wie in 01 („Straße und Gleis im 25-m-Raster“): Die Sim-Kante läuft zwischen Feldmitten (8 Richtungen), gesucht per A* mit Kosten `1 + 8·Steigung + 3·Richtungswechsel`. Das Bild ist eine geglättete Kurve durch die Feldmitten (Radius Dorfstraße ≥ 25 m), keine Treppen (M5). Breiten aus 01: Dorfstraße 6 m (Ortsdurchfahrt bis 10), Gasse 5 m, Feldweg/Wirtschaftsweg 3,5 m.
- **Hofstelle** = Parzelle mit Hauptgebäude an der Straße (Rücksprung 2–8 m), Nebengebäude hinten, Hoffläche (Lehm), Garten, 1–3 Bäume, Zaunzug.
- **Orientierung:** Giebel oder Traufe zur Straße, Jitter ±8° und ±2 m auf dem Halbfeld-Unterraster (01). Nie exakt parallel zueinander.
- **Rand:** Ring aus Gärten/Obstwiesen 30–60 m („Etter“), dann Felder (Bodenfarbe).
- **Zufall:** `rng = PCG(hash(welt_seed, ort_id, "form"))`.

### 3a Haufendorf (Ebene, Kreuzung, Altsiedelland; Gewicht Süd/West 50 %)
1. Kern = Schnittpunkt der 2–4 Ausfallwege (Richtungen zu den Gabriel-Nachbarn aus 06). Kirche auf dem höchsten Punkt im Umkreis 60 m.
2. Ausfallwege vom Kern 1,0–1,4 r lang, je mit Richtungsrauschen ±15°.
3. 1–3 Gassen verbinden benachbarte Ausfallwege auf 0,4–0,8 r (Bogen, 60–150 m). Keine Gasse, wenn Steigung > 8 %.
4. Hofstellen: Poisson-Disk (d_min 25 m) im Band ≤ 35 m beidseits aller Wege, Annahme-Wahrscheinlichkeit `p = 1 − (d_kern/r)²`. Hofstelle 1 Feld (25×25 m), Großhof 1,5×1,5 Felder.
5. Sonderbauten: Gasthaus an der Hauptkreuzung, Schmiede am Ortseingang der wichtigsten Straße, Pfarrhaus neben Kirche, Schule am Kern.
6. Füllen bis Σ Haus-EW = Ort-EW (Mix Kate/Hof/Handwerker), Lücken 10–20 % bleiben (Obstwiese).

### 3b Straßendorf (Talboden, Bach, Landstraße; 25 %)
1. Achse = Talrichtung oder Verbindung zweier Nachbarn, 400–800 m, sanft gekrümmt.
2. Hofstellen beidseits in Reihe: Breite 25–37,5 m (Halbfeld-Schritte, Jitter), Tiefe 25–50 m; Haus giebelständig, Scheune quer hinten (Hakenhof).
3. Hinter den Höfen Gärten, dann Hufen-Streifen 25–50 m breit senkrecht zur Achse (Felder als Bodenfarbe).
4. Kirche etwa mittig (40–60 % der Länge), Gasthaus am Ende oder an der Kreuzung, Schmiede am Ortseingang.
5. 10–20 % der Parzellen leer; Abstand Haus–Haus 6–20 m.

### 3c Angerdorf (flache Mulde mit Wasser, Ost/Mitte; 15 %)
1. Anger = Linse 150–350 × 40–100 m, Längsachse entlang des Gefälles [Q] ref 1b Angerdorf.
2. Straße teilt sich an beiden Enden und umschließt den Anger (zwei Ortseingänge).
3. 12–30 Hofstellen ringsum außen, Traufseite zur Straße, Scheunen hinten.
4. Auf dem Anger: Kirche + Kirchhof, Teich (wenn Wasser ≤ 200 m), Schmiede, Linde; Rest grün.
5. Wirtschaftsweg (3,5 m) als Ring hinter den Scheunen.

### 3d Weiler (Hang, Waldrand, Talende; Rest 10 % plus alle Weiler)
1. 4–10 Hofstellen, Abstand 25–45 m, r 40–75 m, kein Kern, an einem Wegende oder einer Kreuzung.
2. Ein Feldweg (3,5 m) zum nächsten Ort, sonst keine Straßen.
3. Jeder dritte Weiler eine Kapelle. Weiler bleiben statisch (keine Stadt-KI).

### 3e Größere Orte
- **Marktflecken** = Haufendorf + Marktplatz (Rechteck oder Dreieck, 40×60 bis 60×80 m, wie 01) an der Hauptkreuzung, am Markt geschlossene Reihe (Lücken ≤ 3 m) aus Bürger-/Handwerkerhäusern, Rathaus, Gasthaus.
- **Kleinstadt** = ovaler Mauerkern (r 200–300 m), 2–4 Tore an den Ausfallstraßen. Innen eine Marktstraße zwischen zwei Toren (15–25 m breit), Gassen 5 m als **verzogene Leiter**: Abstand 30–60 m (±30 %), Winkel ±15°, nie durchgehendes Raster. Parzellen schmal (8–12 m Front), geschlossen. Vor den Toren Vorstädte als Straßendörfer, 150–400 m lang.
- **Stadt** (nur durch Wachstum, Ort ≥ 10.000) = wie Kleinstadt, Kern größer. Ab Jahr ≥ 1840 Ringstraße statt Mauer (Hebel). Bahnhofsviertel nur nach Spieler-Bahnhof (4c).
- **Raster:** einzig im Bahnhofsviertel (Ort ≥ 3.000, max 2×3 Blöcke, Achse an der Bahnlinie). Sophie: historisch belegt, Kontrast zur Altstadt. Gegenposition (Bastis Feedback): „geometrisch“ ist das Hauptproblem, also lieber gar kein Raster. Empfehlung: erlauben, aber erst spät im Spiel und klein.

Positionen:
- **Felix/Art Director (01):** Eine Wahrheit: Sim-Kante zwischen Feldmitten, Bild geglättet. Dann gelten Z-01, A* und Spielerstraßen ohne Sonderfall.
- **Sophie (Gegenposition):** 8 Richtungen zwingen Gassen auf 45°-Vielfache. Im 25-m-Raster wirkt ein Haufendorf dann wieder konstruiert, nur in Schräg.
- **Empfehlung:** Sim-Kante nach 01. Im Bild darf eine **Ortsstraße** bis ±20° und ±8 m von der Kante abweichen, solange sie im Feldband bleibt (Kurve durch Hilfspunkte statt Feldmitten). Häuser folgen der Bildkurve, nicht dem Raster.

## 4. Wachstum und Stadt-KI

### 4a Wer entscheidet was
| Ebene | Entscheidet | Quelle |
|---|---|---|
| **Wie viel** | Sim-Wachstum wie heute: 180 bp/Monat bei Versorgung ≥ 80 %, 45 bei ≥ 50 %, 0 bei ≥ 30 %, −45 darunter | [Q `economy_constants.json` wachstum] unverändert |
| **Wo und wie** | Stadt-KI je Ort (Dorf und größer), nur Bild + `city_streets` | [A] |
| **Ziel** | `Ort-EW_soll = Sim-EW − Umland-EW` (Umland fest ab Generierung, wächst nicht: Landflucht) | [A], historisch [~] ref 1a |

### 4b Ablauf je Spielmonat (600 Ticks)
```
defizit = Ort_EW_soll − Σ Haus_EW
aktionen = clamp(ceil(defizit / 8), 0, 1 + Ort_EW_soll / 500)        # Dorf 1–2, Stadt bis 10
rng = PCG(hash(welt_seed, ort_id, monat))                              # deterministisch, unabhängig von anderen Orten
für jede Aktion, erste zulässige Regel gewinnt:
  1 LÜCKE:   leere Parzelle an bestehender Straße, nächste zum Kern → Typ nach Klasse (S/M)
  2 UPGRADE: Haus mit Alter ≥ 3 Monate, Schwelle erfüllt (Tabelle 4c), Gewicht ×2 im Haltestellen-Radius → nächste Stufe am Platz
  3 TEILUNG: Hof im Kern, Ort ≥ 1.000 EW → 2 Handwerkerhäuser (Parzelle halbiert, Scheune weg)
  4 VORSTADT: neue Hofstelle/Haus am Ende einer Ausfallstraße, Richtungsgewicht ×3 bei Spieler-Anschluss, Stopp bei halber Mindestlücke zum Nachbarort (06)
  5 GASSE:   nur wenn Kern-Füllgrad ≥ 85 % und Upgrade-Kandidaten < 10 %; 60–150 m, Abzweig 60–120°, schließt an Straße ≤ 80 m an (Schleife statt Sackgasse); max 1 je Spieljahr (Dorf), 2 (Stadt)
  6 PLATZ:   Klassenwechsel (siehe 4c) → einmalig Marktplatz/Rathaus bzw. Bahnhofstraße
bei defizit < 0 (Schrumpfen): Haus wird „Leerstand“ (Fenster dunkel, Dach grau), kein Abriss; Leerstand wird bei Wachstum zuerst wieder belegt
```
Takt: Je Tick höchstens 1 Ort (Orte über die 600 Ticks verteilt), keine Frame-Spitzen. Neubau zeigt 1 Monat ein Gerüst-Prefab.

### 4c Schwellen (Verdichten vor Ausdehnen)
| Übergang | Bedingung | EW-Zuwachs | Quelle |
|---|---|---|---|
| Kate → Handwerkerhaus (S→M) | Ort ≥ 300 EW, an Straße ≥ 6 m | +2 | [A], OpenTTD-Prinzip [Q] ref 2 |
| Hof → Großhof (M→L Dorf) | Ort ≥ 250, Hof ≥ 30 m vom Nachbarn | +4 | [A] |
| Handwerker → Bürgerhaus (M→L) | Ort ≥ 1.000 und im Kern (≤ 0,7 r_kern) | +5 | [A], Anno-Prinzip [Q] ref 2 |
| Bürgerhaus → Mietshaus (L→XL) | Ort ≥ 4.000 und Spieljahr ≥ 1840 | +18 | [~] ref 1c |
| Dorf → Marktflecken | Ort-EW ≥ 800 | Marktplatz, Rathaus | [A], Band aus 03 |
| Marktflecken → Kleinstadt | Ort-EW ≥ 2.000 | Marktstraße, Tore als Deko | [A], Band aus 03 |
| Kleinstadt → Stadt | Ort-EW ≥ 10.000 | Ring (≥ 1840) | [~] 01 Tab. F |
| (Sim-Stufen, nur Warenkorb/Nachfrage) | Sim-EW ≥ 1.000 / 5.000 / 20.000 | kein Bildwechsel | [Q] `wachstum` |
| Bahnhofsviertel | Spieler-Bahnhof ≤ 400 m vom Kern, Ort ≥ 1.500 | Bahnhofstraße; ab 3.000 Raster 2×3 Blöcke à 60×80 m | [~] ref 1b |

Tempo-Check: Dorf mit Sim 650 wächst bei voller Versorgung 11,7 EW/Monat ≈ 1,5 Hof-Äquivalente pro Minute. Dorf→Kleinstadt-Stufe dauert laut Repo 11–13 min [Q `wachstum` ziel_dorf_kleinstadt 6.600–7.800 Ticks]; sichtbar sind etwa 15–20 Änderungen im Ort, also eine alle 30–50 s.

### 4d Reaktion auf Anschluss und Fracht
- **Fracht/Versorgung** bestimmt nur die Rate (Sim, unverändert).
- **Anschluss** bestimmt die Richtung: Ausfallstraße mit Spieler-Straße ×3, Haltestellen-Radius (Bus 5, Bahnhof 10 Felder [Q `genre_standard`]) ×2 für Upgrades.
- **Bahnhof** des Spielers erzeugt Bahnhofstraße zum Kern (Gasse-Regel, aber auch ohne Füllgrad).
- KI-Straßen kreuzen **nie** ein Gleis und schließen an Spieler-Straßen nur über eine Kreuzung an.

Positionen:
- **Lena:** Automatisches Wachstum ohne Spieler macht die Welt lebendig (Basti: „Städte wachsen automatisch“).
- **Tobias (Gegenposition):** Wachstum ist die Belohnung für Versorgung; Grundwachstum entwertet die Kette.
- **Felix:** KI-Straßen ändern A* zur Laufzeit; nur Zellen hinzufügen, nie entfernen, und Pfade der Fahrzeuge nicht invalidieren.
- **Empfehlung:** Rate bleibt Sim (also kein Wachstum ohne Versorgung), aber Sichtbarkeit garantiert: Jede positive Rate erzeugt im selben Monat mindestens 1 sichtbare Aktion. Siehe Streitpunkt 3.

## 5. Belebte Ortslagen ohne Drawcall-Explosion

Je Hofstelle [A]: Hauptgebäude, 1–2 Nebengebäude, 1 Hofset (gemergt: Misthaufen/Holzstapel/Fässer/Karren), 6–20 Zaunsegmente (3 m), 1–3 Bäume, Bodenfarbe (Hof Lehm, Garten dunkelgrün mit Reihen, Obstwiese, Anger hellgrün) als Vertexfarbe bzw. ein Boden-Mesh je Kachel.

| Ebene | Inhalt | Instancing | Dreiecke Ø | Sichtweite |
|---|---|---|---|---|
| Boden | Hof, Garten, Anger, Wege als Vertexfarbe/Decal-Mesh | 1 Mesh je 400-m-Kachel | – | immer |
| Häuser | 7 Prefabs Welle 1 × 2–3 Varianten, gemergt | MultiMesh je (Kachel, Prefab), Palette ≤ 8 Prefabs je Ort | 2.000–4.000 | bis 1,4 km, dann Proxy |
| Nebengebäude | 3 Typen | MultiMesh je Kachel | 200–500 | bis 1,0 km, dann Proxy |
| Hofsets | 4 gemergte Sets | MultiMesh je Kachel | 300 | bis 600 m |
| Zaun | 1 Segment, 2 Varianten | MultiMesh je Kachel | 40 | bis 600 m |
| Bäume | Obstbaum, Linde, 2 Laub | MultiMesh je Kachel, Deckel wie S7 (≤ 60 % Ort-Dreiecke) | 150–400 | bis 1,8 km |
| Proxy fern | Haus-Quader Sattel/Flach (14/10 Tris), Nebengebäude-Quader, Baumtupfen | **1 MultiMesh je Typ und 3,2-km-Kachel** (16 Kacheln) | 10–14 | ab 1,1 km |

**Perf-Rechnung Übersicht** (Gate ≤ 1,0 M Tris, ≤ 300 DC [Q review_retro]): 1.500 Haupt- + 1.300 Nebengebäude als Proxy ≈ 38.000 Tris, Baumtupfen ≈ 30.000; DC ≤ 16 Kacheln × 4 Typen = 64. S7 lag bei 0,76 M / 250 DC mit mehr Gebäuden. Puffer: etwa 0,2 M / 50 DC.
**Nah** (Gate 2,9 M): Kleinstadt 380 × 3.000 + Neben/Streu/Bäume ≈ 1,4 M; DC je Ort ≈ 8 Häuser + 3 Neben + 4 Hofsets + 2 Zaun + 4 Bäume + 1 Boden = 22 je Kachel.

Positionen:
- **Sophie:** Gärten und Zäune sind das, was Railway Empire „halb leer, aber nicht kahl“ macht [Q] ref 2.
- **Felix (Gegenposition):** Streuobjekte vervielfachen Instanzen (50 Höfe × 15 = 750 je Dorf). Das ist bei MultiMesh unkritisch, aber das Neuaufbauen bei KI-Wachstum ist es nicht.
- **Empfehlung:** Instanz-Puffer je Kachel +30 % vorbelegen, `visible_instance_count` statt Neuaufbau; Hofsets gemergt statt Einzelteile.

## 6. Brücke Einwohner → Nachfrage (bestehendes Spiel, nichts geändert)

`city_demand = Sim-EW × 1 / 100 × demand_mult` je Periode (60 s), demand_mult Dorf 2.000 ‰, sonst 1.000 ‰ [Q `economy.gd` Z. 375, `economy_slice.json` saettigung].

| Klasse | Sim-EW typ. | Nachfrage/Monat | ≈ Fuhrwerk-Ladungen (10 Einh.) | Warenkorb [Q] |
|---|---|---|---|---|
| Dorf | 650 | 13 | 1,3 | Nahrung |
| Marktflecken | 1.550 | 15–16 | 1,5 | Nahrung |
| Kleinstadt | 3.500 | 35 | 3,5 | Nahrung |
| Kleinstadt, gewachsen auf Sim-Stufe stadt | 6.000 | 60 | 6 | Nahrung, Stahl |

Folgen: (1) Dorf-Nachfrage bleibt im S7-Band. (2) Marktflecken hat wegen ×2-Dorfbonus kaum mehr Nachfrage als ein großes Dorf (Stufensprung bei 1.000 Sim-EW halbiert den Multiplikator), an Tobias. (3) Zum Start liegt keine Sim-Stufe „stadt“ auf der Karte (Kleinstadt max. Sim 4.700). Es gibt also keinen Abnehmer mit Stahl im Warenkorb, bis eine Kleinstadt wächst (Streitpunkt 6).

## Streitpunkte

| # | Konflikt | Position A | Position B | Empfehlung |
|---|---|---|---|---|
| 1 | **Ehrliche Einwohner vs. stabile Nachfrage** | Lena: Label = sichtbare Häuser (Dorf 150–400). Nachfrage über `demand_mult` neu kalibrieren. | Tobias: Sim-EW Dorf 400–999 bleibt, sonst T-15 neu (Ertrag, Bankrottquote). | **Umland-Modell:** Sim = Ort + Gemarkung, Umland ab Generierung fest, Wachstum nur im Ort; ≥ 30 % des Umlands als Weiler/Einzelhöfe sichtbar. Ökonomie bleibt, Häuser stimmen mit Ort-EW. |
| 2 | Dorfgröße realistisch vs. lesbar | Basti/Recherche: 25–60 Häuser, r ≤ 200 m. | Sophie/Daniel: Aus 4 km ist ein 30-Häuser-Dorf ein Fleck; Label trägt alles (H1 offen). | Real bauen, Lesbarkeit über Kirchturm, Bodenfarbe (Gärten, Felder) und Label; kein Mindest-Gebäudezahl-Gate mehr, sondern EW-Gate. |
| 3 | Wachstum automatisch vs. nur durch Versorgung | Lena: Welt soll von selbst leben. | Tobias: Wachstum ist Belohnung, bleibt an Versorgung. | Rate = Sim (Versorgung), KI garantiert Sichtbarkeit jeder positiven Rate. Unversorgte Orte stagnieren sichtbar (Leerstand bei Schrumpfen). |
| 4 | KI-Straßen frei vs. Grammatik | Sophie: organische Gassen wie OpenTTD. | Felix: Laufzeit-A*, Konflikte mit Spielerstraßen und Gleisen. | Nur Grammatik der Dorfform (verlängern, Gasse mit Anschluss, Platz), nur Zellen hinzufügen, nie Gleis kreuzen. |
| 5 | Wenige Orte vs. Auswahl für Linien | Tobias/Sophie: 10–12 Orte wie S7, gebündelte Nachfrage, ruhige Übersicht, weniger Labels (H1). | Lena: Realistisch wären 30+ Dörfer (03: 34); mehr Ziele = mehr Linienwahl und Sammeltouren. | **15–21 Knoten** (12–16 Dörfer, 06: Dorf–Dorf ≥ 1,6 km und ≥ 5 Dorfdurchmesser) + 6–12 Kulisse-Weiler ohne Knoten und Label. Deckt 03 Szenario B. |
| 6 | Stadt zum Start 1820 | Recherche/Basti: eher Dörfer, Stadt erst durch Wachstum. | Tobias: Stahl im Warenkorb nur bei Sim-Stufe stadt, die Montankette hat keinen Endkunden; er will B+ mit 2 Kleinstädten (03). | **Keine Stadt 1820**, aber 2 Kleinstädte an den Enden des Flusstals, wenn das Gelände es trägt (06: KS–KS ≥ 7 km). Endkunde Montan: Kartenrand-Markt (Vorschlag Art Director, 03) oder Stahl im Kleinstadt-Korb. Das entscheidet Tobias, nicht die Welt. |

## Offene Fragen an Basti
1. Darf die angezeigte Einwohnerzahl die Gemarkung einschließen (Dorf 300 sichtbar, Label 700), oder müssen Label und Häuser 1:1 übereinstimmen?
2. Soll ein Ort ohne Versorgung sichtbar stagnieren/schrumpfen (Leerstand), oder wachsen alle Orte langsam von selbst?
3. Sollen die Dorfformen je Karte gemischt nach Gelände entstehen (Haufen-, Straßen-, Angerdorf), oder soll eine Region den Charakter prägen, z. B. Südwesten mit Haufendörfern und Einzelhöfen?
