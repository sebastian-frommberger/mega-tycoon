# 12 Welt-Regelwerk v1 (Design Sprint Welt, Phase 3, 02.11.2026)
Gilt für Generator (W-03/W-05/W-06), Import-Skript, Stadt-KI und die Prototyp-Szene. Entschieden durch Jonas (PO), Herleitung in `11_streitprotokoll.md` (K1–K20). Daten: `12_regelwerk_v1.json` (gleiche Inhalte, Ganzzahl-Konvention wie `rules_s7`).
Kennung: **[A]** = PO-Annahme bis Bastis Antwort (`13_fragen_an_basti.md`, F1–F6) oder Prototyp-Messung. Ohne Kennung = entschieden.
Detaildateien: Skalen `phase2/01`, Prinzipien `02/03`, Schwierigkeit `04`, Stadtmodell `05`, Verteilung `06/07`, Landschaft `08`, Wasser `09`, Assets `10` + `10_import_faktoren.json`.

## 1 Design-Prinzipien
**Die Welt:** eine stille, große Landschaft um 1820, in der kleine Orte wie Inseln liegen. Alles steht im echten Verhältnis zueinander (E1). Das Netz der Spielenden verbindet und verändert sie. Man sieht, warum jeder Ort und jede Industrie dort steht.

| # | Prinzip | Test |
|---|---|---|
| P1 | Verhältnis vor Größe: oberes Ende des Realbands, nie ein Faktor | Haus, Fuhrwerk, Straße, Lok, Mühle nebeneinander: alles ±25 %, Fahrzeuge ≤ 1,2× |
| P2 | Zeichen statt Maßstab: Icon, Name, Linie mit Mindestbreite im Bildraum | Übersicht ohne Modelle: Orte, Industrien, Linien, eigene Fahrzeuge eindeutig |
| P3 | Gewachsen, nicht konstruiert | kein Ort mit zwei gleichen Blöcken, jede Straße hat einen Grund |
| P4 | Landschaft dominiert | Siedlung < 3 % der Fläche; ≥ 5 Dorfdurchmesser zwischen Dörfern |
| P5 | Gelände ist Spielelement | „steht hier, weil …“ für jeden Ort; jede Strecke > 2 km hat eine Geländeentscheidung |
| P6 | Belebt im Detail, ruhig im Ganzen | bei 40 m kein leerer Block, bei 5 km keine Rauschflecken |
| P7 | Epoche ist ein Parameter | anderes Startjahr ändert nur Daten |

**Nie:** Objekte vergrößern (außer Fahrzeuge ≤ 1,2×) · Gebäude einfärben · Raster (außer Bahnhofsviertel) · Ort ohne Lagegrund · Modernes ohne Epochenfreigabe · 1820 eine Industrie größer als das Dorf daneben.

## 2 Skalen-Tabelle (final)
1 Feld = 25 m. Toleranz im Prototyp ±25 % (bei Bändern: Band ±25 %). Fahrzeuge: 0,9–1,2 × real, Toleranz **nicht** addiert. Feld ≠ Objekt: Das Feld ist Rechenzelle, keine Bildfläche.

### A Gebäude
| Objekt | Spiel (m) B×T, H | Felder | EW |
|---|---|---|---|
| Haus S (Kate) | 8×6, H 6–7 | 0,32 | 4–6 |
| Haus M (Bauern-/Handwerkerhaus) | 12×9, H 9–11 | 0,48 | 6–10 |
| Hofstelle (Haus M + Scheune + Hof) | 25×25 | 1,0 | (6–10) |
| Scheune/Stall | 18×10, H 8–10 | 0,72 | 0 |
| Haus L (Bürgerhaus, 3 Gesch.) | 12×14, Traufe **9,5–12**, First 12,5–15 | 0,48 | 12–20 |
| Haus XL (Mietshaus, ab 1840) | 16×12, H 16–18 | 0,64 | 25–40 |
| Dorfkirche / Stadtkirche | 20×10, Turm 30 / 35×15, Turm 45–55 | 0,8 / 1,4 | – |
| Marktplatz | 40×60 bis 60×80 | 1,6–3,2 | – |
| Bahnhof früh | 30×12, H 10; Bahnsteig 110×4 | 1,2; 4,4 | – |
| HQ 1820 (Kontor) [A] | 16×12, 2–3 Gesch., Hofmauer | 0,64 | 0 |

### B Wege und Gleis
| Objekt | Breite (m) | Radius min | Steigung hart |
|---|---|---|---|
| Feldweg | 3,5 | – | 200 ‰ |
| Dorfstraße / Ortsdurchfahrt | 6 / bis 10 | 25 m | 200 ‰ |
| Stadtgasse | 5 | – | 200 ‰ |
| Chaussee (Fahrbahn / Trasse) | 6 / 11 | 50 m | generiert ≤ 50 ‰ |
| Gleis eingleisig (Bettung / Trasse) | 4 / 7 | 100 m | **60 ‰**, Fallback 80 ‰ [A] |
| Gleis zweigleisig | 9 | 100 m | wie oben |

### C Fahrzeuge (Ausnahme ≤ 1,2×)
| Objekt | Spiel L × B (m) | real L | Faktor | ersetzt |
|---|---|---|---|---|
| Pferd | 3,0 × 0,8 | 2,4–2,8 | 1,1 | – |
| Fuhrwerk, 2 Pferde | 9,5 × 2,2 | 8–9 | 1,1 | Lkw |
| Postkutsche, 4 Pferde | 12,5 × 2,2 | 10–12 | 1,1 | Bus |
| Dampflok (Adler-Klasse) | **7,6** × 3,7, H 4,3 | 7,62 | 1,0 | – |
| Tender | 4,8 | ~4 | 1,2 | – |
| Personen-/Güterwagen | 6,9 | 5–5,7 | 1,2 | – |
| Zug: Lok + Tender + 8 Wagen | 67,6 (2,7 F) | ~57 | 1,19 | – |
| Kahn / Raddampfer | 28 × 5 / 50 × 12 | 20–30 / 35–50 | 1,0–1,1 | – |

### D Industrie 1820 (Gebäude real, Werksgelände = echter Inhalt)
| Typ (Sim-Slot) | Hauptgebäude (m) | Landmarke H | Gelände m | Signal |
|---|---|---|---|---|
| Gutshof (getreidefarm) | 40×40 | 12–15 | 150–300 | Getreideschläge |
| Wassermühle (muehle) | 12×12, Rad Ø 5 | 12 | 50–150 | Graben, Wehr, Teich |
| Windmühle (muehle, Variante) | Ø 8 | 20–25, Flügel Ø 20 | 25 | Flügel |
| Grube/Stollen (kohle-/erzmine) | 15×10 | 10–15 | 75–125 | Halde Ø 30–60 |
| Eisenhütte (stahlwerk) | Ofen 10×10 + Gießhaus 25×12 | 15–20 | 150–250 | Kohlplatz, Erzhaufen, Teich |
| Manufaktur (werkzeugfabrik, Senke) | 40×12, 3 Gesch. | 14–16 | 75–100 | Lagerhof, Fuhrwerke |
| Kalkofen/Ziegelei (kraftwerk) [A] | 15×10 | Ofen 8–12 | 50–100 | Kalkhalde, Ziegelstapel |
| ab 1840: Tiefbauzeche | 30×15 | Malakow 25–35 | 150–250 | Halde, Gleis |
Regel V7: Hauptgebäude ≤ 4 × Grundfläche Haus M. Farbe nur Icon, Name, Plakette, optional Wimpel. Sim-Footprint bleibt S7 (K14), das Bild füllt ihn mit Werksgelände.

### E Wasser, Brücken, Bäume
| Objekt | Spiel (m) | Darstellung |
|---|---|---|
| Mühlgraben | 3 | Band-Mesh |
| Bach | 4–6 + Gehölzsaum 10–20 je Seite | Band-Mesh, ab 1 km Zeichenlinie |
| Nebenfluss | 15–25 | Band/Wasser-Mesh, Rinne 1,5 m |
| Fluss (Hauptfluss) | 60–100 (Band 60–120); Aue 5–20 × Breite | Rinne + Wasser-Mesh |
| Strom | nicht im Standard 1820 | – |
| Dorfteich / Mühlteich / See | 15–30 / 50–150 / 300–800 (0–2 Seen [A], F5) | eigenes Mesh unter 3 Feldern |
| Brücken | Felder = ⌈Breite/25⌉ + 1 Rampe je Seite, max. 8; Steinbogen 15 m, Holzjoch 8 m; Bachbrücke im Feld | |
| Laub- / Obst- / Nadelbaum | H 15–25 / 6–8 / 20–30 | MultiMesh |

### F Verhältnisse (prüfbar, ±25 %)
V1 Haus M : Dorfstraße : Fuhrwerk = 12 : 6 : 9,5 · V2 Straße : Fahrzeugbreite ≥ 2,5 · V3 Hofstelle = 1 Feld · V4 Lok + Tender ≈ 1 Haus M (nie > 1,5) · V5 Zug 68 m passt an Bahnsteig 110 m · V6 Kirchturm ≥ 3 × Traufe Haus M (bis 1840) · V7 Industrie ≤ 4 Haus M · V8 Fluss = 5–8 Hauslängen · V9 Dorf–Dorf ≥ 5 Dorfdurchmesser.

### Fernsicht (E1: Lesbarkeit aus Zeichen)
Ab 2 km: Fahrzeuge als Icon/Punkt in Linienfarbe, Wege und Bäche als Linie ≥ 2 px (Bach ab 1 km). Schild-Hierarchie: Kleinstadt und Marktflecken immer, Dorf unter 3 km Kamera, Weiler nie. Geometrie bleibt real.

## 3 Ortsklassen und Stadtmodell
### Ortsklassen (Start 1820)
| Klasse | Ort-EW (sichtbar) | Umland-EW | Sim-EW → Sim-Stufe | Hauptgebäude | Radius Ortslage | Anzahl |
|---|---|---|---|---|---|---|
| Weiler | 20–60 | – | kein Knoten | 4–10 Höfe | 40–75 m | 6–12 Kulisse |
| Dorf | 150–350 | 250–550 | 400–900 → dorf | 25–56 | 125–200 m (Straßendorf 400–800 lang) | 12–16 |
| Marktflecken | 800–1.300 | 400–600 | 1.200–1.900 → kleinstadt | 100–165 | 175–250 m | 2–3 |
| Kleinstadt | 2.000–4.000 | 400–700 | 2.400–4.700 → kleinstadt | 195–380 | Kern 200–300 m + Vorstädte bis 450 m | **2** (min. 1) [A] F1 |
| Stadt | 10.000–20.000 | 500–1.000 | → stadt/metropole | 900–1.500 | 600–900 m | 0 (nur Wachstum/Spätstart) |

**Umland-Modell:** Sim-EW = Ort-EW + Umland-EW. Umland fest ab Generierung, Wachstum nur im Ort; ≥ 30 % des Umlands sichtbar als Weiler/Einzelhöfe in der Gemarkung (Voronoi der Knoten). Sim-Stufe (1.000/5.000/20.000) steuert nur Warenkorb und Nachfrage, die Ortsklasse das Bild.
**Schild:** Name · Ort-EW · Trendpfeil · bis 3 Bedarf-Icons. Tooltip: „Einzugsgebiet N (Nachfrage)“.
**Erwartung:** Ort-EW ≈ 12.000 (real 10–16k), Sim-EW ≈ 20.000 (12–29,5k; S7 36.250). T-15 nicht neu kalibrieren, Bot-Stichprobe (K1).

### Haustypen
Kate (S, 5 EW) · Bauernhof (M-Dorf, 8, 1 Feld) · Großhof (L-Dorf, 12) · Handwerkerhaus (M, 7) · Bürgerhaus (L, 14, ab Marktflecken) · Mietshaus (XL, 30, Kleinstadt ≥ 4.000 und ab 1840) · Sonderbauten Kirche, Kapelle, Pfarrhaus, Gasthaus, Schmiede, Schule, Rathaus, Speicher, Stadttor, Bahnhof (nur Spieler, ab 1835), HQ (Spieler). Ø EW je Wohnhaus: Weiler/Dorf 7, Marktflecken 9, Kleinstadt 11, Stadt 14. Prefabs Welle 1: Kate, Hof, Handwerker, Bürger, Kirche, Gasthaus, Schmiede.

### Dorfformen
Gewicht Haufendorf 50 %, Straßendorf 25 %, Angerdorf 15 %, Weiler 10 %; **Form nach Lage** (Talboden/Bach → Straßendorf, Mulde + Wasser → Angerdorf, Kreuzung/Ebene → Haufendorf), dazu je Seed ein Regionsgewicht +30 % für eine dominante Form [A]. Generator-Schritte wie `05` §3a–3e. Gemeinsam: Hofstelle mit Haus an der Straße (Rücksprung 2–8 m), Nebengebäude hinten, Garten, 1–3 Bäume, Zaun; Halbfeld-Unterraster 12,5 m, Jitter ±2 m/±8°; Etter-Ring 30–60 m, dann Acker. Kleinstadt: ovaler Mauerkern, 2–4 Tore, verzogene Gassen-Leiter (30–60 m ±30 %, ±15°), Vorstädte als Straßendörfer. Raster nur im Bahnhofsviertel (Spieler-Bahnhof ≤ 400 m, Ort ≥ 3.000, max. 2×3 Blöcke).

### Wachstum und Stadt-KI
- **Wie viel:** Sim-Rate unverändert (180/45/0/−45 bp je Monat nach Versorgung 80/50/30/<30 %). Ohne Versorgung: S7-Verhalten mit Leerstand statt Abriss [A] F2.
- **Wo und wie (je Spielmonat, deterministisch je Ort):** 1 Lücke füllen → 2 Upgrade am Platz (Kate → Handwerker ab 300 EW +2; Hof → Großhof ab 250 +4; Handwerker → Bürger ab 1.000 im Kern +7; Bürger → Mietshaus ab 4.000 und 1840 +16) → 3 Hofteilung im Kern ab 1.000 → 4 Vorstadt an Ausfallstraße (×3 bei Spieler-Anschluss, Stopp bei halber Mindestlücke) → 5 Gasse (Kern ≥ 85 % gefüllt, max. 1–2 je Spieljahr) → 6 Platz bei Klassenwechsel (800 / 2.000 / 10.000 Ort-EW).
- Jede positive Rate erzeugt im selben Monat ≥ 1 sichtbare Aktion; Gerüst 1 Monat; max. 1 Ort je Tick.
- KI-Straßen: nur hinzufügen, nie Gleis kreuzen, Anschluss an Spielerstraßen nur über Kreuzung.
- **HQ-Bonus [A]:** nächster Ort Rate ×1,05 (nur bei positiver Rate, im Zuschlag-Deckel 250 ‰), Stadt-KI-Richtung zum HQ ×1,5. Keine Pflicht, Abnahme Tobias S8.
- Belebung: je Hofstelle 1–2 Nebengebäude, 1 Hofset (gemergt), 6–20 Zaunsegmente, 1–3 Bäume; MultiMesh je 400-m-Kachel, Proxy ab 1,1 km je 3,2-km-Kachel, Instanz-Puffer +30 %.

## 4 Verteilungsregeln
### Abstände (Zentrum zu Zentrum)
| Paar | Minimum | typisch |
|---|---|---|
| Weiler – jeder Ort | 0,6 km | 0,8–1,5 km |
| Dorf – Dorf | max(1,6 km; 5 × Dorfdurchmesser) | 1,8–3 km |
| Dorf – Marktflecken / Kleinstadt | 2,5 km | 3–5 km |
| Marktflecken – Marktflecken | 5 km | 5–7 km |
| Kleinstadt – Marktflecken | 4 km | 4–6 km |
| Kleinstadt – Kleinstadt | 7 km | 7–9 km |
| Dorf → nächster zentraler Ort | max. 6 km | – |
Mindestlücke im Endausbau 0,8 km Freiland (Weiler 0,4 km); Randabstand Knoten und Industrie 1 km.

### Platzierung
Orte zuerst, dann Industrie in die Zwischenräume. Eignung S (Wasser 100–400 m +300, Furt +250, Talkreuzung +200, Talrand +150, Ebene +100, Aue direkt −400, steil −500, Waldinneres −200, Gebirge aus). Zentrale Orte „best candidate“ (k = 30, S ≥ 600), Dörfer Bridson-Poisson mit Annahme p = S/1.000, **nicht sättigen**, keine Relaxation. Dorfzahl ergibt sich, 16 ist Obergrenze. Clark-Evans Orte 1,0–1,6, Industrien 0,9–1,5. Erfüllbarkeit ≥ 18/20 Seeds.

### Industrie-Ebenen
| Ebene | Typ | Anzahl | Lage |
|---|---|---|---|
| Rohstoff | Gutshof | 5–8 | Ebene/Aue, breit gestreut |
| | Kohle / Erz | 2–3 / 1–2 | nur Lagerstätten an 1–2 Bergflanken, Flecken r 300–600 m, Kohle–Erz ≥ 0,75 km getrennt, gleiches Massiv erlaubt; Relief ≥ 60 m in 500 m |
| | Holz (ab S8) | 3–5 | Nutzwald |
| Veredelung | Mühle | 3–5 | ≤ 200 m an Bach oder Fluss |
| | Eisenhütte | 2–3 | Tal, Wasser ≤ 400 m |
| | Kalkofen/Ziegelei [A] | 2–3 | Ebene/Waldrand |
| Produktion/Senke | Manufaktur | 1–3, max. 1 je zentralem Ort | Vorstadt, nie im Kern |

**Gleicher Typ (ersetzt R7):** Rohstoff ≥ 1,2 km, Veredelung ≥ 3 km, Produktion ≥ 4 km.
**Kanten:** Farm → Mühle nah 0,45–0,75 km + Pflicht-Fernquelle 0,75–2 km · Kohle → Hütte 0,4–0,75 km · Erz → Hütte 0,75–3 km, **≥ 1 Erzfleck ≤ 2 km** · Hütte → Manufaktur 0,75–2 km · Mühle → Ort 1–3,25 km.
**Anti-Revier:** AR1 max. 3 Industrien und keine volle Kette je 1,5-km-Kreis · AR2 keine kongruenten Gruppen (±20 %) · AR3 Quellen aus ≥ 2 Richtungen **nur für Mühlen** (Hütte: Erz und Kohle aus verschiedenen Richtungen; Kalkofen ausgenommen) · AR4 ≥ 70 % der Rohstoffe mit ≥ 2 Abnehmern in 2,5 km · AR5 Clark-Evans · AR6 jede 4×4-km-Kachel ≥ 1 Industrie (außer > 60 % Gebirge/Wasser) · AR7 Lage sichtbar.

### Validator (Spiel und Validator rechnen dieselbe Funktion)
V-E1 Pflichtkante per Straße (≤ 200 ‰, Umweg ≤ 1,6) · V-E2 je Montangruppe 1 Kette als Gleis (**≤ 60 ‰** [A], Umweg ≤ 2,0) · V-E3 Netz zusammenhängend, ≥ 2 Querungen je Fluss · V-E4 Flussspalten gerade querbar ≥ 80 % · V-E5 Industrie-Zufahrt · V-E6 Ortsanschluss · V-E7 ≥ 60 % der Knoten mit Agrarkette in 2,5 km · V-V1–3 Abstände, Hierarchie, Verteilung · **neu** V-L1 Reliefstufen-Anteile (ersetzt Hügelquote ab Prototyp-Abnahme) · V-L2 Fluss max. Querschnitt ≤ 6, Median 3–5, gerade querbar ≥ 85 % · V-L3 Bäche 4–8, jede Mühle ≤ 200 m Wasser. Generator grob (4×4-A*), Validator fein (1×1), Validator ist das Gate.

## 5 Landschaft
### Relief (Profil ds_v2 + K15)
| Stufe | Spanne in 500 m | Ziel innen | ds_v2 gemessen |
|---|---|---|---|
| Ebene | < 25 m | 20–30 % | 20,5 % |
| Hügelland | 25–90 m | 30–40 % | 29,6 % |
| Mittelgebirge | 90–280 m | 15–20 % | 18,4 % |
| Gebirge | > 280 m | **≤ 20 %** (Ziel 15 %) [A] | 31,6 % → Massiv kleiner |
Parameter: Grat aus der Summe (Domäne 31° gedreht), 4 Oktaven, Gain 0,42; Grundwelle Massiv 1/2/Rand 2,6/2,0/3,0 km; Exponent 1,35/1,3; **Massiv-1-Radius 2,8–3,4 km, Rand ±25 % verrauscht** [A]; Reliefzonen-Maske 6 km (Ebene 4 m, Hügelland 42 m, Kuppen 900 m/14 m); Tal flach bis 700 m, Übergang bis 2 km. Kein Gebiet über 3 km ohne Stufenwechsel, Vorland ≥ 1 km. Stadtplateaus nur im Kern, nach Ortsform, Terrassen quer zum Gefälle, kein Kreisring.

### Boden und Biome
Bodenkarte 512² RGBA8 (R Acker, G Heide, B Sumpf, A Wald), Rest prozedural; Fallback Vertexfarben bei > 0,3 ms iGPU.
| Klasse | Farbe | Regel (Kurz) | Anteil ds_v2 |
|---|---|---|---|
| Wiese | #73945C | Grundfläche | 39 % |
| Auenboden / Sumpf | #7D9959 / #5F7352 | Aue < 500 m, flach / fleckig nass | 7 % / 0,7 % |
| Acker hell / dunkel | #C2A866 / #8F7350 | Gürtel bis 4 Ortsradien (max. 1,6 km) **an Hofstellen**, Gewann 200×125 m, nicht in der Aue | 9 % |
| Heide | #8C8462 | trocken, 180–520 m | 2 % |
| Bergheide/Geröll [A] | Heide/Schotter | Gürtel 750–1.000 m (TF3-Biomverlauf) | neu |
| Waldboden | #55734A | Hänge, Höhen, Wald-Polygone; **Mosaik: Flecken 100–800 m, 3–8 Feldgehölze je km², Hecken an Rainen** [A] | 30 % |
| Schotter / Fels | #A39D90 / #807361 | Hangschutt > 550 m / > 60 % | 3 % / 7 % |
| Schnee | #F2F2F7 | **über 1.000 m**, Neigung < 55 % | 0,2 % |
| Ufer / Wasser | #6B7054 / #345F7E | 1 Feld Saum / Flussmaske | – |
Alle Klassen 3:1 gegen Saum oder Marker.

### Wald
Bäume real (Laub 18 m, Nadel 25 m). Dichte je Feld: Laubwald 6–8 (Rand 3–4), Bergwald 8–10, Aue 0,5, Wiese 0,1, Ufergehölz 1 je 10 m, Chaussee-Allee 1 je 12 m. Ab 2,5 km nur Waldboden + Kronentupfen im Shader. Deckel: Übersicht ≤ 120k Baum-Dreiecke, nah ≤ 6.000 Bäume, Gartenbäume 1,2 je Gebäude, Baum-Tris ≤ 60 % der Ort-Tris.

### Wasser
Fluss 60–100 m (halbe Breite 30–34 m + 16 m Zuwachs ±3 m), Mäander λ = 11–15 × Breite, Amplitude 90–140 m, moduliert 25–100 %; Rinne 3,5 m; **Uferböschung 40 m**. **4–8 Bäche** (Tiefenlinien) und **1–2 Nebenflüsse**. Aue 5–20 × Breite, Spanne < 5 m, kein Acker. Mühlteich an jeder Wassermühle, Dorfteich am Anger. **0–2 Seen** 300–800 m in Hügelland/Gebirgsfuß [A] F5. Kein Strom.

## 6 Wasser-Shader-Parameter (`water.gdshader`, opak, Compatibility)
| Uniform | v1 (A) | Variante B [A] (TF3, A/B im Rundgang) |
|---|---|---|
| c_flach / c_tief / c_ufer | #55909C / #345F7E / #6B7054 | c_tief #2F6E7C |
| tiefe_voll_m | 2,5 | 3,5 |
| ufer_breite_m (Bach) | 0,35 (0,25) | 0,35 |
| saum_staerke | 0,10 | 0,10 |
| wellen_skala / wellen_staerke | 0,10/m / 0,55 | gleich |
| fliess_periode_s | 8 | gleich |
| fresnel_staerke / fresnel_basis | 0,55 / 0,04 | gleich |
| rauheit / specular | 0,30 / 0,35 | gleich |
| tiefe_skala_m / m_pro_einheit | 8 / 25 | gleich |
Teich: Fließvektor 0, Wellen ×0,45. Bach: Band 5 m, Tiefe quer 0 → 0,8 → 0 m. Builder: Pegel = tiefster Knoten im 6er-Umkreis + 3,5 m, 3× geglättet, Uferring 2 Felder, Fließen 0,6 m/s. Kosten: Übersicht +3 DC, +7,2k Dreiecke, ~200 ALU, 0 Texturen. Flowmap (Sophie) später als Tausch von `wellen_grad()`.

## 7 Straße und Gleis im Bild
Sim: Kante zwischen Feldmitten (8 Richtungen). Bild: durchgehendes **Spline-Band** durch geglättete Feldmitten, keine Kacheln; Knotenstücke je Kreuzungstyp; Brücke = Sim-Brückenfelder mit Band darüber; Ortsstraßen bis ±20°/±8 m Abweichung im Feldband. Restfläche des Feldes = Bankett, Graben, Baumreihe oder Vorgarten, keine 25-m-Schneise. Spielernetz wird gleich geglättet (W-04b).

## 8 Asset-Mapping (Kurzform, voll in `10_asset_mapping.md` / `10_import_faktoren.json`)
| Regel | Inhalt |
|---|---|
| R1 | Faktor je Rolle: `faktor_szene = Ziel_m / Modell_u / 25` |
| R2 | Bezugsachse = kleinste Toleranz (Gebäude: Modul 3 m) |
| R3 | Quer- oder Längsfaktor nur Fahrzeuge/Brücken, ±35 % (Fuhrwerk x 0,65, Lok z 1,13, Flussbrücke x 0,47) |
| R4–R6 | 1 Prefab = 1 Mesh (MultiMesh), Fernproxy ab 1,4 km, Pivot normieren |

| Rolle | Modell | Faktor |
|---|---|---|
| Häuser (Module) | Fantasy Town `wall*`, `roof-high*`, `chimney` | 0,12 |
| Fuhrwerk | Fantasy `cart` + 2 × Prototype `animal-horse` | 0,149 (x 0,65) / 0,115 |
| Dampflok | Train `train-locomotive-a` | 0,104 (z 1,13) |
| Wagen | Train `train-carriage-*` | 0,102 |
| Laub-/Nadelbaum | Nature `tree_default` / `tree_pineDefaultA` | 0,42 / 0,65 |
| Obstbaum, Zaun | Fantasy `tree`, `fence` | 0,116 |
| Windmühlenflügel / Wasserrad | Fantasy `windmill` / `watermill` | 0,257 / 0,111 |
| Flussbrücke | Castle `bridge-straight-pillar` | 0,645 (x 0,47, y 0,5) |
| Halde, Meiler, Turmhelm, Tender | Hilfsmeshes | – |
Erlaubt: Fantasy Town, Nature, Train, Survival, Graveyard, Castle, Prototype, Watercraft, Pirate (Fremdpaletten umfärben). Nicht: Retro Fantasy, City-Kits, Car Kit, Hexagon-Gebäude. Gebäude neutral (Hauspalette), Kettenfarbe nur Icon/Plakette/Wimpel. Zukauf: Quaternius Farm Animal Pack (Pferd) empfohlen, Basti besorgt.

## 9 Startjahr-Hebel (E4, eigene Option)
| Parameter | 1820 (Standard) | 1835 | 1840 | 1860 |
|---|---|---|---|---|
| Ort-EW Dorf / MF / KS | 150–350 / 800–1.300 / 2.000–4.000 | – | 180–400 / 1.000–1.800 / 3.000–6.000 | 200–450 / 1.200–2.500 / 4.000–8.000 (+ 0–1 Stadt 10k) |
| Haustypen | S, M, L | – | + XL | + Bahnhofsviertel |
| Mauer erhalten / Ring | 70 % / nein | – | 40 % / ja | 15 % / ja |
| Bahn | nein (Fortschritt) | **ja** | ja | ja |
| Industrie extra | – | – | Tiefbauzeche | Puddelwerk, Öl |
| Start-Chaussee / Startkapital | 1 / 6.000 $ | – | 2–3 / 8.000 $ | Netz / 10.000 $ |
| Landmarke | Kirchturm | – | + Schornstein 25–30 m | Schornstein ≈ Kirchturm |
Freischaltungen nach Jahr gelten auch, wenn das Spieljahr sie während des Spiels erreicht. Fahrzeuge nach Baujahr verfügbar (TF3 bestätigt das Muster).

## 10 Schwierigkeits-Hebel Welt (E5, Entscheidung S8)
| Hebel | Leicht | Normal (= S7) | Schwer |
|---|---|---|---|
| Startkapital / Kredit | 9.000 / 3.000 ab Min. 6 | 6.000 / 2.000 ab Min. 12 | 4.500 / 1.500 ab Min. 12 |
| Zins / Bankrott / Vorwarnung | 2 %/min / 15 min / 180 s | 3 % / 10 min / 90 s | 4 % / 7 min / 60 s |
| Nachfrage / Baukosten | ×1,25 / ×0,8 | ×1,0 / ×1,0 | ×0,8 / ×1,25 |
| Welt: knappe Quellen (Erz, Kohle je Typ) [A] F6 | 2 | 1–2 | 1, weiter weg |
| Welt: Relief [A] F6 | flacher Seed | ds_v2 | bewegter, 1 Brückenstelle weniger |
Kein Hebel: Siedlungsdichte, Startjahr, Skalen. Fehlertexte mit Lösung immer. Abnahme über Ziel-Bankrottquote im Bot-Lauf (≤ 5 % / 15–18 % / 30–40 %).

## 11 Abgleich Transport Fever 3 (Bastis Referenz tf3_01–09, „kein macht es genau so“)
| | Inhalt |
|---|---|
| **Bestätigt** | Kleine Orte in großer Landschaft, Lesbarkeit über Schilder (Name, EW, Trend, Bedarf); Orte mit 296/538 EW sind ~40–120 Gebäude (passt zu Dorf/Marktflecken); Fahrzeuge real groß (Kesselwagen 9,6 m, Lok + 2 Wagen 26 m), Menschen winzig, Gleis schmal → **E1 ist Genre-Stand**; Bäume 20 m+; geschwungene, schmale Ortsstraßen; Industrie kompakt, neutral, nur Plakette farbig; ruhiges Wasser mit Tiefenverlauf und Ufersaum; Schneekappe nur auf dem höchsten Gipfel; Fahrzeuge nach Baujahr (passt zu E4); Mehrfachquellen je Fabrik. |
| **Übernommen** [A] | Wald-Wiesen-Mosaik, Bergheide-/Geröllgürtel, Bedarf-Icons im Schild, Wasser-Variante B (A/B), HQ-Wachstumsbonus (§3). |
| **Widerspricht** | Viele Seen/Buchten (bei uns Fluss + Bäche + Teiche) → F5. Wald bis an die Häuser (bei uns 1820 Acker-/Gartengürtel, bewusst). Fahrzeuge nahe Echtzeit mit gerafftem Kalender (bei uns gerafft) → F4. |
| **Dichte** | 15–21 Knoten auf 164 km² ist dichter als der TF3-Ausschnitt [E], weil wir Dörfer als eigene Knoten führen; plausibel, Prüfung im Rundgang. |

## 12 Aufgelöste Widersprüche zwischen den Skizzen
| Thema | Skizzen | v1 |
|---|---|---|
| Überhöhung Fahrzeuge/Bäume | Audit ×1,5/×1,2 | ≤ 1,2 / 1,0 |
| Bach | ref 8–12 m, 01 4–6 m | 4–6 m + Saum + Fernlinie |
| Strom | ref 200–300 m, 01 250–350 oder keiner | keiner im Standard |
| Kleinstädte | 03: 1 + Kartenrand-Markt; Tobias 2 | 2 (min. 1), kein Kartenrand-Markt |
| Marktflecken / Kleinstadt EW | 01 800–1.500 / 2.000–5.000; 03 800–1.300 / 2.000–4.000 | 03 (1820) |
| Dorfabstand | 03 1,5 km; 06 max(1,6; 5 × Ø) | 06 |
| EW-Zuwachs, EW je Haus MF | 05 +5/+18, 8,5; 07 +7/+16, 9 | 07 |
| Gleis-Steigung | 01 4 %; Backlog 12 %; Validator 120 ‰ | 60 ‰ (Fallback 80) |
| R7 | S7 160 F alle Typen | 1,2 / 3 / 4 km |
| AR3 vs. knappe Kohle | 06 alle Veredler | nur Mühle |
| Mühle ≤ 200 m Wasser vs. nur ein Fluss | 06 / 08 | Bäche + Nebenflüsse |
| Gebirge innen | 08 Ziel ≤ 15 %, gemessen 31,6 % | Massiv −15 %, Gate ≤ 20 % |
| Kraftwerk-Slot | Köhlerei | Kalkofen/Ziegelei |
| Lok / Haus L | 01 9 m / Traufe 12; 10 6,7 m / 9 m | 7,6 m / 9,5–12 m |
| Bodenumsetzung | 08 Bodenkarte; Felix Vertexfarben | Bodenkarte, Fallback Vertex |
| Schneelinie | 1.000 vs. 780 m | 1.000 m |
| Hügelquote | ≥ 10 % (13,8 % knapp) | Reliefstufen V-L1 |
| Startjahr als Schwierigkeit | 04 Leicht = 1840 | getrennte Option |

## 13 Spätere Kopplungen (nicht Teil dieses Sprints, S8-Konzept Lena/Tobias)
Arbeitskräfte (Orte stellen Arbeiter, Radius statt Zahlenpflege), Energie (Versorgung von Industrie und Stadt), Wohnen/Einkaufen/Arbeit mit Wegezeiten und Lärm/Verschmutzung (TF3 tf3_05/06), Lieferketten als Pfeilbänder über der Karte und Aufträge mit Belohnung/Strafe (tf3_09). Andockpunkte in der Welt: Gemarkung (Voronoi), Haltestellen-Radius, Industrie-Ebenen.

## 14 Offen
F1–F6 in `13_fragen_an_basti.md`. Messung aller [A]-Werte im Prototyp (`14_prototyp_plan.md`).
