# S-06a Asset-Liste Vertical Slice (Gate-Input K-07 / G9)

Sophie Martin, Art Lead · Stand 23.11.2026 · Status: **Entwurf fertig, mit Katrin NICHT abgestimmt** (Termin 24.11.) · Tabelle: `s06a_assetliste.csv` (51 Zeilen, Semikolon), Rechnung `s06a_build.py`, Summen `s06a_summen.txt`.

Alle Aufwände sind **meine Schätzungen in Personentagen (PT)**, keine Planning-Poker-Werte. Polygonbudgets sind Zielvorgaben (Referenz Lkw LOD0 = 300 Tris), keine gemessenen Werte.

## 1. Grundlage und Scope-Spalte

- Konzept §7 (VS-Minimum), `industry.md`, `city.md`, `hq.md`; Karte 512² (D5); 4 HQ-Archetypen (Hafen, Bergbau, Agrar, Handelsknoten).
- **Ketten-Scope ist nicht entschieden.** Das Briefing nennt 5 Ketten (Tobias: Getreide, Vieh, Holz, Kohle, Erz→Stahl→Werkzeug). `plan/katrin_overview.md` empfiehlt für den VS nur 3 (Getreide, Kohle→Kraftwerk, Erz+Kohle→Stahl; Vieh/Holz/Werkzeug erst M2), `refinement/ergebnis.md` spricht von „6 VS-Industrien“. Ich habe deshalb jede Zeile markiert:
  - **KERN** = 3-Ketten-Minimum plus Pipeline, Stadt, Netz, Fahrzeuge (Farm, Mühle, Kohle- und Erzmine, Stahlwerk, Kraftwerk, Lager = die 6 aus dem Refinement, plus 1 Mine-Variante)
  - **5K** = nur bei 5 Ketten (Werkzeugfabrik, Viehweide, Schlachthof, Forst/Sägewerk, Aufstockung E2)
  - **ARCH** = nur, wenn der Archetyp im VS spielbar sein soll (Hafen + Schiff, Fluss + Lastkahn, Fels-Module, Stadt-Geschosse für Handelsknoten)
- Was Konzept §7 nicht nannte, aber `hq.md` erzwingt: **Hafen und Küstenschiff** (Hafenstadt: „Schiffslinie ab Minute 1“), **HQ-Gebäude**, **Geschossmodule** für eine 12.000-Einwohner-Stadt. Das ist Scope, den jemand entscheiden muss (Lena/Jonas), nicht ich.

## 2. Summen (PT)

| Owner | KERN | 5K | ARCH | Summe |
|---|---|---|---|---|
| Sophie (Shader, Pipeline, 2D, Review) | 48,0 | 0 | 0 | **48,0** |
| 3D-Artist (Modelling) | 46,0 | 11,0 | 10,5 | **67,5** |
| Outsourcing Audio (nur Steuerung) | 2,0 | 0 | 0 | 2,0 |
| **Gesamt** | **96,0** | 11,0 | 10,5 | **117,5** |

Mit Kenney (Abschnitt 4, 18 Proben gemessen, Rest geschätzt): Sophie 45,5 · Artist 36,0 / 8,0 / 5,0 = **49,0** · Gesamt 96,5. Details `kenney_messung.md`.

Größte Posten: Terrain-Shader und Karten-Rendermodus (je 6 PT, Sophie), Review-Anteil Artist-Assets (9 PT, Sophie, 20 % der Artist-PT), Industrien KERN (7 Stück, 16 PT Artist), Stadt (C1–C8, 18 PT Artist inkl. ARCH).

## 3. Kapazität M1 (30.11.2026–26.03.2027) – Annahmen, nicht abgestimmt

| | Arbeitstage | Verfügbar für diese Liste | Annahme |
|---|---|---|---|
| Sophie | ca. 80 (abzüglich Feiertage) | **ca. 56 PT** | 30 % für Lead-Aufgaben außerhalb der Liste (Gate, S-05-Presets, Abstimmung Felix/Aylin, Daily). Der Review-Anteil R3 steckt schon in der Liste |
| 3D-Artist, Start **01.12.** | ca. 80 | **ca. 68 PT** | 15 % Onboarding und Meetings. Start 01.12. ist eine Annahme aus dem Briefing („ab Dezember“); `plan/sophie.md` sagt „spätestens 04.01.“, Jonas' Freigabe (20.11.) ist in keinem Bericht belegt |
| 3D-Artist, Start 04.01. | ca. 58 | **ca. 49 PT** | gleiche Abschläge |

**Vergleich:**
- Sophie: 48 von 56 PT = **86 %**, passt knapp, kein Puffer für Überraschungen bei Terrain/Chunks (G3/G4 hängen an Felix).
- Artist ab 01.12., nur KERN: 46 von 68 = 68 %, **passt**. KERN + 5K + ARCH: 67,5 von 68 = **99 %, kein Puffer**.
- Artist ab 04.01.: KERN 46 von 49 = 94 %, passt gerade so; **5K und ARCH passen nicht.**
- Fazit: **Mit 3 Ketten und ohne Hafen/Fluss ist der Slice mit Sophie + 1 Artist machbar. 5 Ketten und alle 4 Archetypen sind es nur bei Start 01.12. ohne jeden Puffer.** Kürzungskandidaten in Reihenfolge: F6/I14 Hafen+Schiff (5 PT), F5 Lastkahn (2), C4 Aufstockung E2 (1,5), F3 Tankwagen (0,5, kein Gut im VS), C8 HQ Stufe 2 (1).

## 4. Kenney Game Assets All-in-1 3.7.0 (neu, 23.11.)

Grundlage: `sprint2/kenney_inventar.md` (Dateinamen) und **18 gemessene Proben** (`kenney_messung.md`: Tris, Maße, Godot-Import, Screenshots). Alles, was nicht in den Proben ist (Signale, Bahnhof, Bus, Factory Kit, Road Pack, Stadtgebäude), bleibt ungeprüft. Spalte `kenney_abdeckung` in der CSV: ja 6 Zeilen, teilweise 25, nein 20.

**Wofür Kenney im Slice taugt**
1. **Platzhalter in Spikes und Grey-Box, sofort:** Industrial-Hallen und Schornsteine, Road Pack als Straßen-Tiles im 45°-Raster, Train-Kit-Gleise für den Bau-Spike (M1-Auflage aus D6), Prototype Kit für Grauboxen mit echter Silhouette. Das spart dem Spike nichts an Code, aber den Entwicklern das Raten („ist das ein Werk oder ein Haus?“).
2. **Final denkbar (gemessen):** Bäume (114/230 Tris), Felsen (80), Industrie-Anbauten (Hallen 1.552–2.046, Schornstein 212), Frachtschiff (1.060), vermutlich Brücken und Signale (ungemessen). Low-Poly mit flachen Farben ist unser Materialmodell, die Atlanten müssen aber auf Palette v1 umgelegt werden. **Fahrzeuge sind NICHT final:** Lkw 2.082–2.488 Tris (7–8× Budget 300), Lok 1.666 (2,8×), Wagen ca. 1.150 (4,6×), bei 10.000 Instanzen untragbar; Retopo kostet so viel wie Neubau. Ersparnis beim Artist ca. **18,5 PT** (67,5 → 49,0), davon 10 PT im KERN.
3. **Audio-Platzhalter** (A1) und evtl. UI-Icons.

**Wo es mit dem Ziel-Look oder der Maßstabsregel kollidiert**
- **Silhouetten-Regel („eine Silhouette, ein Gut“, 64 px):** Mühle, Kraftwerk/Kühlturm, Bergwerk/Förderturm, Rundsilo, Portalkran, Hochofen fehlen laut Inventar. Die Industrie-Kerne bleiben eigene Modelle; Kenney liefert nur Anbauten (Hallen, Schornsteine, Förderbänder). Das ist der Teil, an dem die Fernlesbarkeit hängt, und der bleibt bei uns.
- **Epochen-Look:** City Kit Suburban/Commercial ist US-Vorort und Gegenwart, nicht Ziegel/Holz Epoche 1. Für Grey-Box ja, als finales Stadtbild wahrscheinlich nein. Die Aufstockungsregel (Gebäude werden angebaut, nicht getauscht) ist mit Modular Buildings immerhin testbar.
- **Maßstab 1 Feld = 10 m:** Kits sind untereinander **nicht** maßstäblich (gemessen): Car Kit ×3,4, Train Kit ×3,7, Industrial ×10, Nature ×8, Watercraft ×10. Fahrzeuge sind damit 10 m lang, aber **5 m breit** (doppelte Realbreite, Spielzeug-Proportion). Gleiskacheln (1,0 × 4,0 Einheiten) treffen bei keinem Faktor Raster und Wagenbreite zugleich. Jedes Kenney-Modell braucht den Faktor im Import-Preset und den Abgleich im Maßstabsband (G1).
- **Ladegut:** Kenney-Wagen tragen das Gut als eigenes Modell (Kohle-, Holz-, Tankwagen). Felix' Pfad ist Instanzfarbe (`use_colors`) auf einem Wagentyp. Entweder Ladegut vom Wagen abtrennen oder ein MultiMesh je Wagentyp. Abstimmung Felix, betrifft F-05.
- **Spline-Netz:** Road Pack und Train-Kit-Gleise sind Kacheln. Unser Netz ist Spline-Mesh pro Chunk (N1/N2, KW-49-Termin). Als Platzhalter im Raster brauchbar, final nicht, es sei denn, das `spline-track`-Segment lässt sich als Profil ausschlachten (Prüfaufgabe).
- **Stil-Einheit:** Mischung aus Kenney-Fahrzeugen und eigenen Industrien funktioniert nur, wenn alles durch denselben Farbatlas läuft (Texturen der Kits ersetzen, Umfärben auf Palette v1). Kostet ca. 0,25 PT je Kit, in den neuen Aufwänden enthalten.

**Konsequenz für die Refinement-Regel „Keine Platzhalter-Meshes für die Spikes, Felix nutzt Würfel und Grauboxen“** (`refinement/ergebnis.md` Z. 44). Die Regel sollte schützen, dass ich keine Wegwerf-Meshes baue. Mit Kenney entfällt der Grund. **Vorschlag zur Änderung (Entscheidung Jonas):** „Spikes dürfen Kenney-Modelle als Platzhalter nutzen, ohne Abnahme durch Art. Bedingungen: (1) Skalierung je Kit aus dem Maßstabsband (G1, Sophie 2 PT, liegt vor dem Bau-Spike), (2) Polygonzahl der Fahrzeuge im Benchmark ≤ 300 Tris oder auf Quader reduziert, damit F-05 das Ziel-Budget misst und nicht Kenneys, (3) kein Kenney-Modell gilt als final, bevor es durch Maßstabsband und Farbatlas gelaufen ist.“ Für F-05 ändert sich nichts: Benchmark mit Quadern oder 300-Tris-Lkw, nicht mit ungeprüften Kit-Modellen.

**Offene Prüfaufgaben (Modelle nicht in den Proben, `glb_messung.py` liegt bereit, 5 min je Datei):** Signale, Bahnhof (existiert er?), Bus/Van, `spline-track` (Profil extrahierbar?), Factory-Kit-Förderband, Road-Pack-Kreuzung, City Kit Suburban/Commercial Haus, Modular Buildings Etage, Scheune/Zaun/Sheddach. Erledigt (siehe `kenney_messung.md`): Tris und Maße der 18 Proben, Faktor je Kit, Godot-Import (Pivot, Y-up, ein Atlas je Kit, vier verschiedene Atlanten).

## 5. Mit Katrin abzustimmen (offen, 24.11.)

- Starttermin 3D-Artist (01.12. oder 04.01.) und Jonas' Freigabe: entscheidet, ob 5K/ARCH überhaupt rechnerisch passen.
- Ketten-Scope 3 oder 5 und Archetypen im VS (Jonas/Lena/Tobias) vor dem Poker.
- Freelancer-Pakete: Industrien I1–I7 als Paket 1 (Dez.), Stadt C1–C5 Paket 2 (Jan.), Fahrzeuge F1–F4 Paket 3 (Feb.) oder Kenney.
- Audio-Budget (A2).
- Ob die Kenney-Prüfaufgaben vor dem Gate (27.11.) möglich sind; sonst gehen die Zahlen „mit Kenney“ nicht ins Gate.
