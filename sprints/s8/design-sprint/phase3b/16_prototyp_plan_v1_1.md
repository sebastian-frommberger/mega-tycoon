# 16 Prototyp-Plan v1.1 (Design Sprint Welt, Phase 4, Stand nach E6–E11, 02.11.2026)
Basis: `14_prototyp_plan.md` (gilt, wo hier nichts anderes steht). Regelwerk: `15_regelwerk_v1_1.md`, Daten `12_regelwerk_v1_1.json`. Eigene Szene `prototyp_welt.tscn` hinter Schalter, S7-Welt und Slice bleiben unberührt; die 21 Regressionssuiten laufen unverändert.
Entscheidung Jonas (PO): **Schlank + See + Easing** (13,5 PT, 3,5 Arbeitstage). Volle Variante nur, wenn das Tokenbudget nach Welle 2 noch ≥ 40 % hat.

## 1 Was sich gegenüber v1 ändert
| Punkt | v1 (14) | v1.1 | Grund |
|---|---|---|---|
| Tempo-Schalter A/B/C | 3 Darstellungen | **entfällt**; neu: Schalter **Easing an/aus** | E9: F4 A entschieden |
| Fahrzeuge | 2 Fuhrwerke, 1 Postkutsche | gleich, **mit Easing-Probe** (Fahrlinie = Straßen-Spline, Anfahren/Bremsen, Kurventempo, Wippen, Gangart) | E9 |
| Wasser | Fluss, Bach, Mühl-/Dorfteich | + **See-Nutzungsstück:** 1 See 400–600 m mit Steg, Fischerhütte, Ruderboot, Pfad zum Dorf | E10 |
| Epochen | Startjahr-Feld | **Datenhülle**: `epochen`-Block im JSON, Loader liest W1, Test „Startjahr 1850 ändert nur Daten“ | E8, P7 |
| Wachstum ohne Versorgung | S7-Verhalten (Arbeitsannahme) | stabil auf Startgröße | E7 |
| Kartentyp | – | volle Variante: 3 Generator-Vorschaubilder (Flusstal / Seenplatte / Seenreich), kein Menü | E10 |
| Konkurrenz | – | **nicht in der Szene**; voll: Tobias rechnet Bot-Lauf mit passivem Anteil 15 % (Zahl für S8) | E11 |

## 2 Varianten
| Inhalt | **Schlank** (Minimum für Bastis Rundgang) | **Voll** |
|---|---|---|
| Ausschnitt | 2,0 × 1,6 km (80 × 64 Felder), ds_v2 Seed 7 | 3,2 × 2,0 km (v1) mit Massiv −15 % |
| Fluss, Bach, Teiche | Fluss + 1 Bach + Mühlteich + Dorfteich | wie v1 |
| **See** | 1 See 400–600 m als **Stempel** in die Heightmap (Senke + Pegel), Wasser-Shader Teich-Modus | gleich + Uferzacken-Fix, falls G2 rot |
| **See-Nutzung** | Steg 25 × 2 m, Fischerhütte (Kate + Netzgestell), 1 Ruderboot am Steg (dümpelt), 1 Boot fährt eine langsame Schleife (Kulissen-Animation, keine Sim), Pfad zum Dorf | + Ufergehölz/Schilf, Teichkette am Gutshof |
| Dorf + Weiler | Haufendorf ≈ 250 EW + 1 Weiler (v1) | wie v1 |
| Kleinstadt | **Markt-Ausschnitt**: Markt 60 × 80, Stadtkirche, 1 Tor, 1 Gasse, ≈ 40 Gebäude | ¼-Sektor ≈ 90 Gebäude + Vorstadt-Zeile (v1) |
| Industrie | Gutshof + Wassermühle | wie v1 |
| Wege | Chaussee + Dorfstraßen als Spline-Band, 1 Kreuzung, 1 Steinbogenbrücke | + Bachbrücke, Feldwege |
| **Easing-Probe** | Fuhrwerk + Postkutsche: Fahrlinie = Spline, Anfahren/Bremsen (W 4/5), Kurvenzone, Spur-Versatz, Wippen, Gang-/Radphase im Shader; je Frame für alle (≤ 10 Fahrzeuge, kein Nah-LOD) | + Nah-LOD-Gerüst (128er-Grenze, Bench mit 1.000 Dummy-Fahrzeugen), Abstandshalten |
| Lok | statisch als Messobjekt (Lok + Tender + 2 Wagen) | wie v1 |
| Wachstum (A10) | **Vorher/Nachher-Bild** aus dem Python-Generator (Monat 0 / Monat 12) | Stadt-KI-Stub live in GDScript (v1) |
| Boden | Bodenkarte (Python-Export, 1 Sampler), iGPU-Messung entfällt | + iGPU-Bench auf Bastis Rechner |
| Schilder | Name, Ort-EW, Trend, Bedarf-Icons statisch | + Tooltip Einzugsgebiet, Fernzeichen |
| Epochen-Datenhülle | JSON-Block + Loader + Test | gleich |
| Kartentyp-Vorschau | – | 3 Übersichtsbilder aus `world_gen.py` mit Parametern aus `gewaesser_kartentyp` |
| Perf | Szene gezählt | + Hochrechnung Vollkarte (v1) |

## 3 Wellen (Agenten auf Opus/Sonnet, kein Fable)
| Welle | Zeit | Parallel | Agent (Modell) | Aufgabe | Ergebnis / Gate |
|---|---|---|---|---|---|
| **0** | 0,5 Tag | – | Jonas (Hauptsitzung) | Ausschnitt festlegen, `12_regelwerk_v1_1.json` als einzige Datenquelle, Aufgabenliste je Agent | Startfreigabe |
| **1** | Tag 1 | 3 | **TA** (Opus) | Ausschnitt-Export (Heightmap, Fluss-Maske, Bach), **See-Stempel**, Bodenkarte, Import-Skript mit Faktoren | Gelände + Wasser in Szene |
| | | | **Stadt** (Sonnet) | Haufendorf + Weiler + Markt-Ausschnitt als Instanzlisten; Vorher/Nachher-Liste (schlank) | Instanzlisten |
| | | | **Felix** (Opus) | Szene, Schalter, Spline-Band (Chaussee, Dorfstraße, Kreuzung), Messsuite-Gerüst, Epochen-Loader | Szene läuft, Spline da |
| **2** | Tag 2 | 3 | **TA + Sophie** (Opus) | Prefabs Welle 1, Gespann + Kutsche, Gutshof, Mühle, **Steg, Fischerhütte, Boot**, Palette, Gang-/Rad-Shader | Assets in Szene |
| | | | **Felix** (Opus) | **Easing-Probe** (Fahrlinie-Abbildung, Fenster, Kurvenzone, Haltung via `INSTANCE_CUSTOM`), Fahrzeuge auf echter Sim-Kette Farm → Mühle → Dorf | Easing an/aus |
| | | | **Aylin** (Sonnet) | Schilder, Bedarf-Icons, Aufgabenkarten v1.1 | Karten |
| **3** | Tag 3 | 2 | **Daniel** (Sonnet) | Messprotokoll M1–M14, V1–V8, E1–E7, G1–G3; Regression unberührt | Liste rot/grün |
| | | | **TA/Felix** (Opus) | Fixes aus Messung, Perf-Zählung | grün |
| **4** | Tag 3,5 | 1 | **Art Director** (Sonnet) + Jonas | Look-Abnahme G1–G2, Kamera-Presets, Bilder für den Rundgang | Freigabe Rundgang |
| (voll) | +1,5 Tage | 2 | TA, Felix, Stadt, Tobias | großer Ausschnitt, Kleinstadt-Sektor, Stadt-KI-Stub, Nah-LOD-Bench, Kartentyp-Bilder, iGPU-Bench, Bot-Lauf Konkurrenz | – |

Tobias (Sonnet) läuft in Welle 1 parallel außerhalb der Szene: Bot-Stichprobe Umland-Modell (K1), 3 Seeds × 3 Läufe.

## 4 Aufwand (Personentage)
| Rolle | Schlank | Voll | Inhalt (schlank → voll) |
|---|---|---|---|
| Technical Artist | 4,0 | 7,0 | Ausschnitt + Bach 0,75, See-Stempel 0,5, Bodenkarte 0,5, Wasser A/B 0,5, Import 0,5, Prefabs + Gespann + Industrie 1,0, Gang-/Rad-Shader 0,25 → + großer Ausschnitt/Massiv 0,75, Prefabs voll 1,0, Kartentyp-Bilder 0,5, iGPU 0,25, Uferfix 0,5 |
| Stadt-/Level-Designer | 1,5 | 3,5 | Dorf 0,75, Markt-Ausschnitt 0,5, See-Lage + Vorher/Nachher 0,25 → + Kleinstadt-Sektor 1,0, Stadt-KI-Regeln 0,5, Belebung 0,5 |
| Felix | 3,0 | 5,5 | Szene/Schalter 0,5, Spline + Kreuzung + Brücke 1,0, Easing-Probe 1,0, Messsuite + Epochen-Loader 0,5 → + Stadt-KI-Stub 0,5, Nah-LOD + Bench 1,0, Abstandshalten 0,5, Perf-Hochrechnung 0,5 |
| Sophie | 1,0 | 2,0 | Palette 0,5, Steg/Hütte/Boot-Look 0,5 → + Wald-Mosaik, Look-Pass |
| Art Director | 0,5 | 1,0 | Abnahme, Kamera-Presets |
| Aylin | 1,0 | 1,75 | Schilder, Karten → + Tooltip, Fernzeichen, Kontrast-Messung |
| Daniel | 1,25 | 2,25 | Messprotokoll inkl. E1–E7, Epochen-Test → + Nah-LOD-Bench, Endmessung voll |
| Tobias | 0,5 | 1,5 | Bot-Stichprobe → + Bot-Lauf Konkurrenz 15 %, HQ-Bonus |
| Lena | 0,25 | 0,5 | Kette spielbar, Karten |
| Jonas | 0,5 | 0,5 | Steuerung, Abnahme |
| **Summe** | **13,5 PT**, 3,5 Arbeitstage | **25,5 PT**, 5 Arbeitstage | |

## 5 Messprotokoll v1.1 (Ergänzungen zu 14 §3)
| # | Objekt / Prüfung | Soll | Grenze |
|---|---|---|---|
| M14 | See Ø / Steg / Fischerhütte / Ruderboot | 400–600 m / 25 × 2 m / 8 × 6 m / 4,5 m | ±25 %, Boot 0,9–1,2 × real |
| M15 | See-Nutzung (V-W3) | ≥ 1 Nutzung ≤ 500 m vom Ufer, Pfad zum Ort | Pflicht |
| E1–E7 | Easing (15 §B5) | Parität bitgleich, kein Sprung, Gierrate, Querbeschleunigung, Halt, Versatz, keine Stauchung | hart |
| E8 | Easing-Kosten | schlank: ≤ 0,5 ms/Frame bei 10 Fahrzeugen; voll: ≤ 1,5 ms bei 128 | Gate |
| P7 | Epochen-Datenhülle | Startjahr 1850 statt 1820 ändert nur Werte aus `epochen`/`startjahr_hebel`, kein Code-Pfad | Test grün |
| G2 | Uferzacken am See | keine sichtbaren 25-m-Stufen bei 160 m Kamera | Sicht (AD) |
Entfällt: Tempo-Schalter-Prüfung (A7 alt).

## 6 Abnahmekriterien (Gate vor Phase 5)
| # | Kriterium |
|---|---|
| 1 | Messprotokoll ohne rote Zeile (M1–M15, V1–V8, E1–E7); Abweichung nur als „bewusst, Grund“ |
| 2 | Perf-Gate Szene eingehalten (Übersicht ≤ 1,0 M / ≤ 300 DC, Kleinstadt nah ≤ 2,9 M), Ladezeit ≤ 3 s |
| 3 | Kette Farm → Mühle → Dorf läuft mit Easing; Easing an/aus ändert die Sim-Prüfsumme nicht |
| 4 | See zeigt seine Nutzung ohne Erklärung (AD + Aylin Sichtprüfung) |
| 5 | Epochen-Test grün, keine Assets nach 1849 in der Szene |
| 6 | 21 Regressionssuiten unberührt grün (Daniel) |

## 7 Aufgabenkarten v1.1 (Änderungen zu 14 §7)
| Karte | Aufgabe | Frage an Basti | prüft |
|---|---|---|---|
| A5 Kleinstadt (schlank) | Markt, Tor, Gasse ansehen | Wirkt der Ort wie eine Kleinstadt um 1820? Zu geometrisch? | P3 |
| **A7 Fahren** (neu) | Fuhrwerk und Postkutsche durch die Kreuzung und um die Dorfkurve verfolgen, Schalter Easing an/aus | Fährt noch etwas „wie ein Schuhkarton“? Wirken Anfahren, Bremsen und Gangart richtig? | E9 |
| **A8 Wasser** (erweitert) | Fluss, Bach, dann zum See mit Steg und Fischerhütte; Wasser A/B | Siehst du, wozu der See da ist? Reicht das ruhige Wasser? | E2, E10 |
| A10 Wachstum (schlank) | Vorher/Nachher-Bild Dorf nach 12 Monaten | Wächst das Dorf glaubwürdig? | Stadt-KI |
| A12 Kartentyp (voll) | 3 Übersichtsbilder Flusstal / Seenplatte / Seenreich | Welche Landschaft willst du als Standard? | E10 |
Die übrigen Karten (A1–A4, A6, A9, A11) bleiben wie v1; A9 schlank nur mit Bildern aus Phase 2.

## 8 Risiken
| Risiko | Wirkung | Gegenmaßnahme |
|---|---|---|
| Spline-Band nicht rechtzeitig fertig | Easing-Probe ohne Fahrlinie | Fallback Kreisbogen an der Sim-Ecke (15 §B4), gleiche Tests |
| Easing in GDScript je Frame zu teuer | E8 rot | schlank nur ≤ 10 Fahrzeuge; Haltung in den Shader; Messung entscheidet K31 |
| Uferzacken am See (25-m-Raster) | G2 rot, Basti sieht Treppen | See als eigenes Mesh mit 5-m-Raster wie Teiche (v1), sonst 12,5-m-Unterteilung |
| Pferde-Pack fehlt | Würfelpferd mit Gangart wirkt komisch | Gangart trotzdem zeigen, Hinweis auf der Karte A7 |
| Tokenlimit | Welle 3/4 bricht ab | schlanke Variante, max. 3 Agenten je Welle, Messung vor Feinschliff |
| Scope-Sog Epochen | jemand baut 1850er-Häuser | Abnahmekriterium 5: keine Assets nach 1849 |
| Markt-Ausschnitt zu klein für Bastis Punkt „Städte“ | Rundgang-Urteil zu Kleinstadt schwach | als bekannte Lücke auf Karte A5 nennen, voller Sektor in S8 |

## 9 Sicher nicht im Prototyp
Spätere Epochen im Bild (nur Daten) · Konkurrenz in der Szene · Schiffe oder Fähre als Spielfunktion · Seenplatte/Seenreich-Generator in der Szene (nur Vorschaubilder, voll) · Lkw, Bus, Züge im Betrieb · Großstadt-LOD, Terrain-LOD · Kartentyp-Menü · neue Spielregeln · Änderungen an Slice, S7-Welt oder Sim.
