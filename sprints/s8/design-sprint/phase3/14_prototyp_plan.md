# 14 Prototyp-Plan Phase 4 (Design Sprint Welt, 02.11.2026)
Ziel: eine kleine, messbare Welt mit echten Proportionen nach `12_welt_regelwerk_v1`, die Basti in Phase 5 mit Aufgabenkarten abläuft. Der Prototyp ist Pflicht, nicht optional (Charter). Eigene Szene `prototyp_welt.tscn` hinter Schalter, S7-Welt und Slice bleiben unberührt (Retro: Schalter-Prinzip).

## 1 Szene
**Ausschnitt:** 3,2 × 2,0 km (128 × 80 Felder) aus Generator-Profil **ds_v2**, Seed 7, mit Massiv −15 % (K15); gewählt so, dass Fluss, Hügelland-Rand und ein Kuppenhügel im Bild liegen. Außen 1 km Randlandschaft als Proxy.

| Inhalt | Ausführung | Regelwerk |
|---|---|---|
| Fluss | 60–100 m, Mäander, Uferböschung 40 m, Wasser-Shader (A und B umschaltbar) | §5, §6 |
| Bach + Mühlteich + Dorfteich | Bach 5 m mit Gehölzsaum, Mühlteich 90 m, Dorfteich 25 m (eigenes 5-m-Mesh) | §5, K12 |
| Hügel | Hügelland 42 m + Kuppe 14 m mit Windmühle oder Kapelle als Landmarke | §5 |
| **Dorf** | Haufendorf am Bach, Ort-EW ≈ 250 (≈ 35 Wohnhäuser + Kirche, Gasthaus, Schmiede), r ≈ 160 m, Etter-Ring, Ackergürtel an Hofstellen, 1 Weiler (6 Höfe) in 0,8 km | §3 |
| **Kleinstadt-Ausschnitt** | 2,5 km vom Dorf (Abstandsregel eingehalten): ¼-Sektor des Mauerkerns r 250 m mit 1 Tor, Marktplatz 60×80, Stadtkirche 50 m, Marktstraße, 2 Gassen, 1 Vorstadt-Zeile 200 m; ≈ 90 Gebäude | §3 |
| **Industrie 1** | Gutshof (Getreidefarm) 0,6 km vom Dorf, Vierseithof 40×40 + Schläge 200 m (Bodenkarte), Sim-Footprint wie S7 | §2 D |
| **Industrie 2** | Wassermühle am Bach/Mühlteich, 12×12 + Rad + Graben; Plakette mit Ketten-Icon, Gebäude neutral | §2 D |
| Wege | Chaussee Dorf → Kleinstadt (Spline-Band 6 m + Allee), Dorfstraßen, Feldwege, 1 Kreuzung als Knotenstück, 1 Steinbogenbrücke über den Fluss (4–6 Bögen), 1 Bachbrücke im Feld | §7 |
| Fahrzeuge | 2 Fuhrwerke (Farm → Mühle → Dorf, echte Sim-Kette), 1 Postkutsche Dorf ↔ Kleinstadt; Pferd = Quaternius, falls bis Tag 2 da, sonst Kenney-Würfelpferd. **Kein Lkw.** Zusätzlich statisch: Lok + Tender + 2 Wagen auf 200 m Gleis (nur Messobjekt) | §2 C |
| Wald | Wald-Wiesen-Mosaik, Ufergehölz, Obstbäume in Gärten | §5 |
| Belebung | Hofsets, Zäune, Gärten, Heuhaufen, Passanten ≤ 300 m | §3 |
| Schilder | Dorf und Kleinstadt mit Name, Ort-EW, Trend, Bedarf-Icons; Tooltip Einzugsgebiet; Industrie-Plaketten | §3 |
| Schalter (nur Rundgang) | Wasser A/B · Tempo A/B/C (F4) · Stadt-KI „+1 Monat“ und „+12 Monate“ · Gebirge S7/ds_v2 (Bild) · Modelle aus (Zeichentest) | – |

## 2 Einbau der Skizzen-Teile
| Teil | Quelle | Einbau | Wer |
|---|---|---|---|
| Generator-Profil | `code_ws_c/world_gen.py --relief ds_v2` | + Massiv-Radius 2,8–3,4 km, Massivrand-Rauschen, Bäche (Tiefenlinien), Uferböschung 40 m, Plateaus nach Ortsform; Ausschnitt als Heightmap + `fluss_maske` + Bodenkarte exportieren | Technical Artist |
| Boden | `tools_ds/boden_vorschau.py` | Regeln als Bodenkarte 512² (hier 128×80) RGBA8 in `terrain.gdshader`, Fluss-Maske 1 Zugriff; Mosaik-Regel neu | Technical Artist, Felix (Shader-Messung) |
| Wasser | `water.gdshader`, `water_s7.gd` | Builder auf Ausschnitt, Bach als Band-Mesh, Teiche eigenes Mesh; Uniform-Set A und B | Technical Artist |
| Assets | `10_import_faktoren.json` | Import-Skript liest Faktoren (inkl. Quer-/Längsfaktor), merged Prefabs Welle 1 (7 Typen) + Scheune, Gespann, Lok + Tender, Flussbrücke; Halde/Meiler/Kalkofen nicht nötig (keine Montan in der Szene) | Technical Artist, Sophie (Palette) |
| Stadtmodell | `05`, `07`/`12_regelwerk_v1.json` | Python-Generator Haufendorf + Kleinstadt-Sektor (Parzellen 12,5 m, Jitter, Hofstellen), Ausgabe als Instanzliste; Stadt-KI-Stub in GDScript (Regeln 1–4: Lücke, Upgrade, Teilung, Vorstadt) für die Wachstumsschalter | Stadt-/Level-Designer, Felix |
| Straße | §7 | Spline-Band (Dorfstraße, Chaussee), 1 Kreuzungsstück, Brücke aus Castle-Bögen | Felix |
| Messung | `asset_audit_bbox.py` | Godot-Testsuite `proto_mass.gd`: AABB jedes Instanztyps × 25 → Meter, Vergleich gegen `12_regelwerk_v1.json` `skalen`, CSV-Ausgabe | Felix, Daniel |

## 3 Messprotokoll (gegen Skalen-Tabelle, automatisch + Sichtprüfung)
Regel: jedes Objekt ±25 % zum Spielwert bzw. Band; **Fahrzeuge 0,9–1,2 × real**, ohne Toleranz-Zuschlag. Ausgabe `proto_mass.csv` (Objekt, Soll, Ist, Abw. %, OK).

| # | Objekt / Verhältnis | Soll | Methode | Grenze |
|---|---|---|---|---|
| M1 | Haus S / M / L | 8×6×6–7 / 12×9×9–11 / 12×14, Traufe 9,5–12 | AABB | ±25 % |
| M2 | Hofstelle | 25×25 | Parzellen-Rechteck | ±25 % |
| M3 | Dorf- / Stadtkirche Turm | 30 / 45–55 | AABB y | ±25 % |
| M4 | Dorfstraße / Chaussee / Feldweg | 6 / 6 (+ Trasse 11) / 3,5 | Band-Querschnitt | ±25 % |
| M5 | Pferd / Fuhrwerk / Postkutsche | 3,0 / 9,5×2,2 / 12,5 | AABB Länge, Breite | 0,9–1,2 × real (Fuhrwerk 7,2–10,8 m) |
| M6 | Lok / Tender / Wagen | 7,6 / 4,8 / 6,9 | AABB | 0,9–1,2 × real |
| M7 | Mühle Gebäude / Rad | 12×12 / Ø 5 | AABB | ±25 % |
| M8 | Gutshof | 40×40, Schläge 150–300 | AABB, Bodenkarte | ±25 % |
| M9 | Fluss / Bach / Mühlteich | 60–100 / 4–6 / 50–150 | Querschnitt Wasser-Mesh alle 100 m | ±25 % |
| M10 | Brücke | Bögen 15, Felder = ⌈B/25⌉ + 2 | Zählung | exakt |
| M11 | Bäume Laub / Obst / Nadel | 15–25 / 6–8 / 20–30 | AABB je Typ | ±25 % |
| M12 | Dorf: Radius, Wohnhäuser, Σ Haus-EW | 125–200 m, 25–56, Ort-EW ±10 % | Konvexe Hülle, Zählung | Band |
| M13 | Kleinstadt-Sektor: Kern-Radius, Dichte | 200–300 m, 120–200 EW/ha | Hülle, Zählung | Band |
| V1 | Haus M : Straße : Fuhrwerk | 12 : 6 : 9,5 | aus M1/M4/M5 | ±25 % |
| V2 | Straße : Fahrzeugbreite | ≥ 2,5 | M4/M5 | hart |
| V4 | Lok + Tender : Haus M | ≈ 1 (≤ 1,5) | M6/M1 | hart |
| V6 | Kirchturm : Traufe Haus M | ≥ 3 | M3/M1 | hart |
| V7 | Mühle : Haus M (Grundfläche) | ≤ 4 | M7/M1 | hart |
| V8 | Fluss : Haus M | 5–8 | M9/M1 | ±25 % |
| G1 | Gebäudefarbe Industrie | neutral (Hauspalette) | Sicht + Material-ID | Pflicht |
| G2 | Uferzacken | keine sichtbaren 25-m-Stufen bei 160 m Kamera | Bild nah/mittel | Sicht (Art Director) |
| G3 | Kontrast Wasser A/B, Bodenklassen | ≥ 3:1 Saum oder Marker | Farbmessung | hart (Aylin) |
Abnahme: 0 rote Zeilen bei M/V, G durch Art Director und Daniel. Abweichungen nur mit Eintrag „bewusst, Grund“ (Charter).

## 4 Perf-Gate
| Ansicht | Gate | Messung | Erwartung |
|---|---|---|---|
| **Übersicht (5,6 km)** | **≤ 1,0 M Dreiecke / ≤ 300 DC** | 2-stufig: (1) Szene gezählt; (2) Hochrechnung Vollkarte = S7-Terrain 0,76 M/250 DC + Wasser +7k/+3 + Gebäude-Proxys (≈ 2.800 × 12–14 Tris je 3,2-km-Kachel) + Baumdeckel 120k − alte Stadtgeometrie | ≈ 0,85–0,95 M / ≈ 280 DC (knapp: Baumdeckel und DC genau beobachten) |
| Kleinstadt nah (300 m) | ≤ 2,9 M | Szene gezählt | ≈ 1,0–1,4 M |
| Bodenkarte iGPU | ≤ 0,3 ms Mehrkosten, sonst Vertexfarben | Felix auf Bastis Rechner (neuer Bench, Retro) | – |
| Ladezeit Szene | ≤ 3 s | Log | – |
Gemessen werden Zählwerte (wie S7) plus ein FPS-Lauf auf Bastis Rechner, wenn erreichbar.

## 5 Aufwand je Rolle (Personentage)
| Rolle | Aufgaben | Tage |
|---|---|---|
| Technical Artist (TEAM-02) | Generator-Ausschnitt + Bäche + Massiv + Böschung (1,0), Bodenkarte (1,0), Wasser A/B einbauen (0,5), Import-Skript (0,5), Prefabs Welle 1 + Scheune + Gespann + Lok + Brücke (2,0), Industrie-Kitbash Gutshof + Mühle (0,5) | **5,5** |
| Stadt-/Level-Designer | Haufendorf-Generator (1,0), Kleinstadt-Sektor (1,0), Belebung/Hofsets-Verteilung (0,5), Stadt-KI-Stub-Regeln mit Felix (0,5) | **3,0** |
| Felix (Technik) | Szene/Schalter (0,5), Spline-Band + Kreuzung + Brücke (1,5), Stadt-KI-Stub (0,5), Messsuite `proto_mass.gd` (0,5), Perf/Bench + Seed-Lauf Gleis 60 ‰ (0,5) | **3,5** |
| Sophie (Art) | Hauspalette, Dachfarben, Fremdpaletten umfärben (0,5), Ufergehölz/Wald-Mosaik-Look (0,5), Look-Pass (0,5) | **1,5** |
| Art Director | Kamera-Presets, Look-Abnahme G1–G2, Rundgang-Vorbereitung | **1,0** |
| Aylin (UX) | Schilder mit Bedarf-Icons + Tooltip, Zeichen in der Ferne, Kontrast G3, Aufgabenkarten | **1,5** |
| Daniel (QA) | Messprotokoll fahren, Regression (21 Suiten unberührt), Rundgang-Protokoll | **1,5** |
| Tobias (Ökonomie) | Bot-Stichprobe Umland-Modell (K1), Marktflecken-Knick, HQ-Bonus (parallel, nicht Szene) | **1,0** |
| Lena (Game Design) | Kette in der Szene spielbar, Aufgabenkarten mit Aylin | **0,5** |
| Jonas/Katrin | Steuerung, Abnahme, Rundgang-Termin | **0,5** |
| **Summe** | | **≈ 19,5 PT**, Durchlauf **4 Arbeitstage** parallel (+ 0,5 Tag Puffer) |

## 6 Reihenfolge
| Tag | Technical Artist | Stadt-/Level-Designer | Felix | Rest |
|---|---|---|---|---|
| 1 | Generator-Ausschnitt, Bäche, Massiv, Böschung; Import-Skript | Haufendorf-Generator auf Ausschnitt | Szene, Schalter, Messsuite-Gerüst | Sophie Palette; Tobias Bot-Lauf startet |
| 2 | Bodenkarte, Wasser A/B; Prefabs Häuser | Kleinstadt-Sektor | Spline-Band, Kreuzung | Aylin Schilder; Pferde-Pack falls da |
| 3 | Prefabs Lok, Gespann, Brücke, Gutshof, Mühle | Belebung, KI-Regeln | Stadt-KI-Stub, Brücke | Daniel erste Messung (M1–M13) |
| 4 | Fixes aus Messung | Fixes | Perf-Gate, Bench, Gleis-Seed-Lauf | Art-Director-Abnahme G, Daniel Endmessung, Aufgabenkarten final |
| 4,5 | Puffer, Bilder für den Rundgang | | | Jonas: Freigabe Rundgang |
Gate vor Phase 5: Messprotokoll grün, Perf-Gate eingehalten, Kette Farm → Mühle → Dorf läuft.

## 7 Aufgabenkarten-Skizze für Bastis Rundgang (Phase 5)
Je Karte: Aufgabe, was Basti tut, eine Frage, Bewertung 1–5 + ein Satz. Daniel protokolliert, Aylin beobachtet, wo Basti sucht.
| Karte | Aufgabe | Frage an Basti | prüft |
|---|---|---|---|
| A1 Übersicht | Kamera 5 km: Finde das Dorf, die Kleinstadt und die Mühle. | Fandest du alles ohne Suchen? Wirken Orte wie Inseln in der Landschaft? | P2, P4, Schilder |
| A2 Zeichen | Schalter „Modelle aus“, dann wieder an. | Reichen Schild, Icon und Linie, um alles zuzuordnen? | P2, E1 |
| A3 Proportion | Kamera 60 m an die Dorfstraße: Haus, Fuhrwerk, Straße, Zaun. | Stimmt das Verhältnis? Wirkt irgendetwas zu groß oder zu klein? | V1, V2, Bastis Punkt 2 |
| A4 Dorf nah | Durch das Dorf fahren (40–200 m). | Wirkt das wie ein Dorf um 1820? Ist in den Höfen etwas los? Was fehlt? | P3, P6, Bastis Punkt 4 |
| A5 Kleinstadt | Mauer, Tor, Markt, Vorstadt ansehen. | Zu geometrisch? Zu groß gegenüber dem Dorf? | P3, Bastis Punkt 4/7 |
| A6 Industrie | Gutshof und Mühle nah und aus 2 km. | Erkennst du sie ohne Farbe am Gebäude? Passt die Größe zu den Häusern? | V7, Bastis Punkt 3/5 |
| A7 Tempo | Fuhrwerk Farm → Mühle verfolgen, Schalter Tempo A/B/C. | Welche Geschwindigkeit fühlt sich richtig an? | **F4** |
| A8 Wasser | Fluss nah, mittel, fern; Bach in 1 km; Schalter Wasser A/B. | Reicht das ruhige Wasser? A oder B? Ist der Bach fern noch da? | E2, K7 |
| A9 Gelände | Über Hügel und Fluss zur Kuppe; Gebirgsbild S7/ds_v2 vergleichen. | Ist das Gelände abwechslungsreich genug? Gebirge ruhig genug, kleiner? | Bastis Punkt 6/9, K15 |
| A10 Wachstum | Dorf versorgt, „+12 Monate“ drücken, zusehen. | Wächst das Dorf glaubwürdig (Lücken, Umbau, Vorstadt)? | Stadt-KI, **F2** |
| A11 Gesamtbild | Freie Fahrt 2 Minuten. | Was würdest du als Erstes ändern? Freigabe für den Generator in S8? | Freigabe W-03/W-05/W-06 |
Ergebnis Phase 5: Bewertungstabelle, Antworten F1–F6, Liste „Feinschliff vor S8“, Freigabe ja/nein.
