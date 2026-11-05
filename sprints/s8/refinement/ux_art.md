# Position UX und Art S8 – Aylin (UX), Sophie (Art/AD), Technical Artist (TEAM-02), Stadt-/Level-Design

Stand 04.11.2026, Repo HEAD dc14304, nur gelesen. Grundlage: `brief.md`, Entwurf `sprints/s8/planung/loop_s8_2026-11-04.md` (im Folgenden „Entwurf“), `basti_feedback_03-11.md`, `phase4/integration_w2.md`, `phase4/fixpass_w2.md`, Resümees mt-ux/-art/-artdirection/-techart/-stadtdesign, `concept/lena.md`, `concept/industry.md`. Scope nach PO-Nachricht (04.11. 00:27): **15 Arbeitstage, 12 T je Person**, Firmenkauf (F-22) und Skilltree (SK-02) laufen **parallel** zum Strang Loop und Bodentextur.

Marken: [M] gemessen/nachgesehen (Befehl oder Zeile), [R] aus Repo-Zahlen gerechnet, [E] Einzelschätzung. Eigene Messläufe: Python auf `slice/world/data/proto/*` (Höhe, Bodenkarte, Instanzen, Wege). Kein Godot-Lauf, also keine Bilder. Alles, was im Bild sichtbar sein soll, ist **nicht geprüft**.

Leitsatz: Basti testet zwei Dinge, Spiel und Welt. Beides wird nur abgenommen, wenn wir es messen können. „Sieht besser aus“ allein reicht nicht.

---

## 1 Bodentextur („teilweise echt krude“)

### Befund (Ursachen)

| # | Befund | Beleg |
|---|---|---|
| B1 | Die Bodenkarte hat **160 × 144 Texel für 4.000 × 3.600 m, also 25 m je Texel**, gelesen mit `filter_nearest`. Klassenkanten sind hart. Der Rauschversatz (±11 m, `rand_versatz_m` 22) macht aus der 25-m-Treppe ausgefranste Klumpen, aber keine Übergänge | [M] `file proto_boden.png` → 160×144; `proto_terrain.gdshader` Z. 9, 12, 46–49 |
| B2 | Je Klasse gibt es **eine Flachfarbe** und nur 5 % Helligkeitsrauschen. Nah fehlt jedes Detail (Gras, Erde, Spuren), fern fehlt Makro-Variation. Große dunkle Sumpf-/Waldboden-Flecken lesen sich als Farbkleckse (Bild `int_preset_3_markt.jpg`) | [M] Shader Z. 52–53; Palette `proto_meta.json boden.klassen` |
| B3 | **M6 Ackernähte sind teilweise behoben** (Fix-Pass: Voronoi-Schläge, `fwidth`-Ausblendung). Die Schlagtextur liegt aber ebenfalls im 25-m-Raster mit `filter_nearest`, deshalb bleiben Treppen an den Schlaggrenzen (sichtbar oben rechts in `int_preset_3_markt.jpg`, Fischgrätmuster an den Grenzen) | [M] `fixpass_w2.md` Z. 16 „offen: feine Stufung 25-m-Raster“, Z. 72; `proto_terrain.gd` Z. 143–183 |
| B4 | **Das Pflaster (Integration M8) ist behoben** (`proto_flaeche.gdshader`, Fix-Pass M7: Läuferverband, Kies für Höfe) | [M] `fixpass_w2.md` Z. 17 |
| B5 | **Das treppige Flussufer (Integration M7) ist offen.** Der Fix-Pass hat es nicht behandelt, seine Nummer M7 meint den Marktplatz. Die Wasserklasse 11 färbt im 25-m-Texel `c_ufer` | [M] `integration_w2.md` Z. 85; `fixpass_w2.md` (kein Ufer-Eintrag); Shader Z. 68–69 |
| B6 | Triplanar lohnt sich kaum: 76 % des Kerns haben < 3 % Neigung (siehe §2). Fels gibt es nur an Flanken (`fels_ab_hang` 0,42) | [M] eigener Lauf, s. §2 |
| B7 | Die Klassen „wald“ (6.445 Texel) und „heide“ (1.826) sind außerhalb `BAUM_BEREICH` nur Boden mit Tupfen | [M] `proto_terrain.gd` Z. 36–38, Histogramm `proto_boden.png` |

**Konsequenz:** „Krude“ kommt vor allem von B1/B2, also von Auflösung und Detail, und nicht von Einzelfehlern. Ein Fix an Einzelstellen ohne B1/B2 wäre Kosmetik.

### Optionen

| Option | Was | Wirkt auf | Aufwand | Perf |
|---|---|---|---|---|
| A1 Übergänge | Klassen weich überblenden (4 Nachbar-Texel gewichten, Blendbreite 3–6 m, Rausch-Maske statt hartem Schnitt) | B1, B3 | 1 PT [E] | +3 Lookups oder 1 Lookup mit `filter_linear` auf einer Gewichtskarte |
| A2 Makro-Variation | 2 Rauschoktaven 200–800 m, ±6 % Helligkeit und leichte Tonverschiebung je Klasse | B2 fern | 0,25 PT [E] | nur ALU |
| A3 Detailtextur nah | 2 CC0-Detailkarten (Gras/Erde), Welt-UV, Ausblendung über die Distanz (nur < 300 m), zwei Maßstäbe gegeneinander gedreht gegen das Kachelmuster | B2 nah | 1 PT [E] (inkl. Auswahl Sophie 0,5) | +2–4 Lookups, ≤ 6 MB VRAM |
| A4 Schlaggrenzen | Voronoi der Schläge im Shader direkt aus den Keimpunkten rechnen (statt 25-m-Textur), Grenzen mit 2-m-Rain | B3 | 0,5 PT [E] | ALU, 9 Distanzen |
| A5 Ufer | Distanzfeld der Wassermaske im 5-m-Feinraster backen (Feinraster existiert: `proto_fein.r16`, 801×721), Ufersaum aus dem Distanzfeld | B5 | 1 PT [E] | +1 Lookup |
| B Bodenkarte 5 m | `tools_proto/ta_export.py` backt Klassen und Gewichte im 5-m-Raster (800×720) statt 25 m | B1 grundsätzlich | 2 PT [E] (Export, Import, Tests `proto_terrain_test`) | +2 MB |
| C Triplanar | nur für die Felsklasse an Flanken > 20° | B6 | 0,5 PT [E] | +2 Lookups nur an Fels |

**Empfehlung:** Stufe A = A1 + A2 + A3 + A4 + A5 (3,75 PT). Stufe B nur, wenn Stufe A das Abnahmekriterium an Bastis Stellen verfehlt. C erst, wenn §2 Relief verstärkt (Bedingung RL-2).

### Bastis Stellenliste einholen

- **Format A (sofort, heutiger Build):** Windows+Shift+S mit **HUD an** (Taste H), sodass Ansicht/Preset und Abstand im Bild stehen. Dateiname `S8_boden_<nr>_<preset>_<stichwort>.png`. Dazu je Stelle eine Zeile: Nr. | Preset (1–5) oder „frei“ | Himmelsrichtung, in die die Kamera schaut | Was ist krude (Kante/Fleck/Muster/Farbe/Ufer) | Note 1–5. Ziel: 5–15 Stellen. Lücke: Die Kameraposition ist nur ungefähr reproduzierbar, das HUD zeigt kein Ziel x/z (`prototyp_welt.gd` Z. 562).
- **Format B (ab Tag 3, Ticket BT-1):** Taste **F12 „Stelle merken“** speichert PNG + JSON (Ziel x/z, Abstand, Gier, Pitch, Preset, Tick, Build-Hash) nach `user://stellen/`. Nur damit sind Vorher/Nachher-Bilder exakt deckungsgleich. Dieselbe Taste dient beim Basti-Test für alle Stellen (Placement, Relief, Bugs).

### Tickets

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| BT-0 | Stellenformat A an Basti (eine Seite) und Auswertung der Liste | Aylin 0,25 | Vorlage liegt Tag 1 bei Basti; Liste mit ≥ 5 Stellen bis Tag 4, sonst greift der Schnitt (s. u.) | – | [E] |
| BT-1 | Stellen-Shot F12 (PNG + JSON) und Messskript: (a) **Treppenmetrik** = Anteil der Klassengrenz-Kanten mit Ausrichtung 0°/90° ±5° zur Weltachse in einem senkrechten Ortho-Shot (1 px = 1 m, Modelle aus); isotrope Erwartung ≈ 11 %. (b) **Kachelmetrik** = höchster Nebenpeak der 2D-Autokorrelation der Leuchtdichte auf Wiese bei 40 und 120 m Abstand. (c) **Detail** = Leuchtdichte-Streuung in 64×64-px-Fenstern auf Wiese bei 40 m. (d) Frametime über xvfb/llvmpipe, 5 Presets | TA 1 | Skript läuft headless/xvfb < 2 min, schreibt CSV; Baseline auf heutigem Stand gemessen und eingecheckt | Format B für Basti; Testweg aller BT-Tickets | [E] |
| BT-2 | Stufe A: A1 Übergänge, A2 Makro, A3 Detail, A4 Schläge im Shader | TA 2,75, Sophie 0,5 (Detailtexturen CC0 auswählen, Stilrahmen) | Treppenmetrik ≤ 50 % der Baseline **und** ≤ 17 % absolut; Kachel-Nebenpeak ≤ 0,25; Detail-Streuung bei 40 m ≥ 2× Baseline, bei 3 km ≤ 1,2× (kein Grieß); an jeder Basti-Stelle ein Vorher/Nachher-Paar | BT-1; Stellen aus BT-0 | [E] |
| BT-3 | Ufer aus Distanzfeld (A5), Integration M7 | TA 1 | Treppenmetrik nur Uferkante ≤ 50 % Baseline; Shot `int_preset_3_markt`-Standort Ufer unten links ohne Raster-Stufe (Daniel + Sophie, blind A/B) | BT-1 | [E] |
| BT-4 | Stufe B: Bodenkarte 5 m (bedingt) | TA 2 | wie BT-2, falls BT-2 an ≥ 1 Basti-Stelle verfehlt | **hängt an D6** (Entwurf: 2 PT timeboxed). Alternative ohne BT-4: −2 T TA | [E] |
| BT-5 | Basti-Abnahme Bodentextur | Aylin 0,25 (Formular), Basti | je Stelle Urteil besser/gleich/schlechter: ≥ 80 % „besser“, 0 „schlechter“ | L2-Karte (§6) | [E] |

**Perf-Budget (Gate für BT-2 bis BT-4):** Geometrie unverändert, also gilt das Übersichts-Gate ≤ 1,0 M Dreiecke / ≤ 300 DC weiter (heute 146 k / 118 DC, `fixpass_w2.md` Z. 51). Neu: ≤ 6 Textur-Lookups je Fragment im Normalfall (heute 2: `boden`, `schlag`), VRAM +≤ 8 MB, Ladezeit ≤ 3 s (heute 1,6–1,9 s), Frametime xvfb/llvmpipe je Preset +≤ 15 % gegen die Baseline. llvmpipe rastert auf der CPU und reagiert stark auf Fragmentlast, ist hier also ein strenger Proxy, aber keine GPU-Frametime (`resuemee/mt-techart.md` §5.1). Zielrechner: ein Bench-Lauf Bastis vor und nach BT-2 (optional, D16).

**Risiko:** mittel. Ohne Stellen und Metrik wird es Geschmacksarbeit (Entwurf D6). Die Metriken sind Proxys. Die Schwellen sind [E] und werden nach der Baseline in BT-1 einmal justiert, danach eingefroren.
**Schnitt:** Kommt Bastis Liste nicht bis Tag 4, arbeitet TA an 8 eigenen Standorten (5 Presets + Markt-Ufer + 2 Ackerränder), und Basti bewertet in L2.
**Testweg:** BT-1-Skript in der schnellen Regressionsstufe (< 2 min); Vorher/Nachher-Tafel je Stelle; Blind-A/B mit 3 Personen.

---

## 2 Relief sichtbar machen

### Befund

| # | Befund | Beleg |
|---|---|---|
| R1 | **Stub oder TA lässt sich prüfen, ohne den Code zu lesen:** Die HUD-Zeile zeigt „Gelände: TA“, „Stub (flach)“ oder „Stub (TA-Fehler)“. Bastis Fehlerbild „keine Hügel“ würde zum Stub passen. Prüfweg: ein Screenshot mit HUD an (H) vom Start. Alle Integrationsbilder zeigen „Gelände: TA“ | [M] `prototyp_welt.gd` Z. 199–209, 562; Bild `int_preset_3_markt.jpg` |
| R2 | Die Daten haben 33,6–154,0 m (bestätigt), **der Kern (2,0 × 1,6 km) aber nur 35,0–117,2 m**. Neigung im Kern: Median 0,8 %, 75 %-Quantil 2,7 %, 90 % 11,4 %. **76 % des Kerns sind flacher als 3 %.** Das ist gewollt: S7-Regel „Städte und Industrien auf Plateau < 3 %“ | [M] Python auf `proto_hoehe.r16` (161×145, ×0,05), Kern = Felder 40–120 / 40–104 laut `proto_meta.json fenster` |
| R3 | Das Licht macht flach: Sonne 42° hoch, `light_energy` 0,52, Umgebungslicht 0,36 (Farbquelle, also richtungslos), Tonemap linear. Bei 6 % Hang ändert die Sonne allein die Helligkeit um ±6,5 %, mit dem Umgebungslicht bleiben rund ±3–4 %. Das liegt an der Wahrnehmungsschwelle, auf gemustertem Boden darunter | [M] `prototyp_welt.gd` Z. 177–195; [R] Lambert sin(42° ± atan s)/sin 42° |
| R4 | Die Kamera blickt steil (Pitch 36° nah bis 62° fern, FOV 50°). Von oben verschwinden Silhouetten. Schatten gibt es nur bis `abstand × 1,4` (≤ 2,5 km) | [M] Z. 44–47, 310–312, 334 |

**Konsequenz:** Daten und Darstellung tragen beide bei. Im Kern ist das Relief schwach angelegt, und Licht und Kamera verstecken den Rest. Zuerst die Darstellung (billig, reversibel), dann über die Amplitude entscheiden.

### Tickets

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| RL-0 | Prüfweg Stub/TA: Basti schickt Start-Screenshot mit HUD; L1-Karte fragt es ab | Aylin 0,1 | Feld „Gelände: TA“ im Formular ausgefüllt. Bei „Stub“ ein Bug-Ticket an Felix (Pfad/Import auf Windows) mit höchster Priorität | vor RL-1 | [M] Prüfweg |
| RL-1 | Darstellung: Sonne 25–30° hoch, Umgebungslicht 0,36 → ~0,2 mit Himmelsquelle statt Farbe, Hangschattierung im Terrain-Shader (Schummerungsterm aus `w_nrm`, Stärke als Uniform), leichte Höhentönung (Tal satter, Kuppe trockener), SSAO-A/B in Compat (TA-Empfehlung, ab Godot 4.6). Licht in eine eigene Datei `world/proto_licht.gd` auslagern (Kollisionsschutz, §7) | TA 1,25, Sophie 0,25 (Look-Abnahme) | Shot „Modelle aus“, Preset 1 und 2: mittlere Leuchtdichte sonnenzugewandter gegen abgewandter Hänge (5–15 % Neigung) unterscheidet sich um ≥ 12 % (heute rechnerisch ~7 % [R]); 3 Personen markieren in der Übersicht höchsten Punkt und tiefste Senke, 3/3 richtig; Basti benennt in L1 3 vorgegebene Hügel/Senken ohne Hilfe | RL-0; Gate Perf wie BT | [E] |
| RL-2 | Amplitude (bedingt): Höhen außerhalb der Bau-Plateaus ×1,5–2 im `ta_export.py`, Plateaus bleiben < 3 %; neu backen und Proto-Suiten (terrain, band_hoehe, mass, welt) laufen lassen | TA 1,5, Stadt 0,5 (Validator `stadt_validate.py` Hang/Wege-Steigung) | Kernspanne ≥ 150 m, Plateauregel hält (Validator 0 FAIL), Wege-Steigung ≤ Sollwerte (`WEG_SOLL`), Easing-Tests grün | **hängt an D-R (neu):** nur wenn RL-1 die Personenprobe verfehlt. Alternative ohne: −2 T | [E] |

**Risiko:** mittel. Flacheres Licht macht die Bodentextur dunkler und kontrastärmer, deshalb RL-1 vor BT-2 abschließen und dann einfrieren. RL-2 ändert Fahrlinien und Brücken (Band-Höhe, E5/E6) und kann das Easing erneut verschieben.
**Testweg:** BT-1-Skript mit Hangmaske (Neigung aus `proto_hoehe.r16`) für die Leuchtdichte-Differenz; Personenprobe mit Daniel und 2 weiteren.

---

## 3 Gebäude-Placement „ziemlich off“, Baumallee „konstruiert“

### Messung heute (grob, eigener Lauf)

85 Hauptgebäude (ohne Nebengebäude), jeweils gegen das nächste Wegsegment aus `proto_wege.json`:

| Größe | Median | p90 | Max | Auffällig |
|---|---|---|---|---|
| Winkelabweichung zur Straße (mod 90°) | 2,5° | 7,2° | 40,9° | 3 > 15°: Wassermühle 40,9° (zum Gutsweg, steht aber am Bach), Fischerhütte 40,7°, Gutshof 18° |
| Abstand Mittelpunkt–Weg | 12,2 m | 31,3 m | 75,7 m | 12 > 25 m, meist Lindenfurt (Bezug ist der Marktplatz, keine Weglinie) |
| Höhenspreizung im Footprint (25-m-Raster) | 0,13 m | 0,17 m | 0,33 m | im Grobraster keine schwebenden Häuser (Feinraster nicht geprüft) |
| Bodenklasse unter dem Gebäude | 134 von 137 auf „Aue“ | | | 1 Gutshof auf Acker |

[M] mit Vorbehalt: Die Vorzeichenkonvention von `rot_deg` ist nicht geprüft (Minimum über beide Vorzeichen genommen), der Marktplatz ist als Bezugslinie nicht berücksichtigt. **Was Basti mit „off“ meint, ist damit nicht bewiesen.** Die Kandidaten lauten: Ausrichtung an Sonderbauten, kein Hofzugang (Gutsweg endet ≈ 20 m vor dem Hoftor, `fixpass_w2.md` Z. 69), Häuser in der Aue (Flussnähe), Abstand und Baulinie.

Der Validator (`tools_proto/stadt_validate.py`) prüft Überlappung, Wasser, Hang, Gebäude auf Wegen und Parzellengrenzen. Er prüft **nicht**: Ausrichtung zur Bezugslinie, Baulinie, Hofzugang/Torweg und Fundament im Feinraster [M] (Grep der `T.add`-Zeilen).

**Allee, Ursache [M]:** `stadt_gen.py` Z. 584–619: genau 12 m Takt, beidseitig gespiegelt in 7,0 m Abstand, Arten strikt im Wechsel Laubbaum/Eiche (`idx % 2`), Streuung nur ±0,8 m, keine Lücken, keine Größenvariation. Das ist der konstruierte Eindruck, mit Zahlen belegt.

### Level-Design-Regeln (neu, als Daten im Regelwerk)

1. Bezugslinie je Gebäude: Straße, Platz oder Wasser (Mühle, Fischerhütte). Traufe oder Giebel ±10° dazu.
2. Baulinie: Dorf 3–15 m, Kleinstadt 0–3 m (geschlossen) von der Bezugskante.
3. Jeder Betrieb und jede Hofstelle hat eine Zufahrt bis ins Tor bzw. an den Ladeplatz (§4 LP-1).
4. Fundament: Höhendifferenz im Footprint (Feinraster 5 m) ≤ 0,5 m, sonst Sockel oder Verschiebung.
5. Allee: Takt 12 m ±3 m, 10–15 % Lücken, Arten gewichtet zufällig (kein Wechsel), Größe ±15 %, Versatz ±1,5 m, abschnittsweise einseitig.

### Tickets

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| PL-1 | Validator um die Regeln 1–4 erweitern (Messung wie oben, Bezugslinie inkl. Platz und Wasser) | Stadt 1 | Neue Prüfungen laufen in der Regression; Liste der Verstöße heute als Baseline | – | [E] |
| PL-2 | Verstöße und Bastis Stellen beheben (Generator-Regeln, nicht von Hand) | Stadt 1 | Validator 0 FAIL; an jeder Basti-Stelle Vorher/Nachher (F12-Format); Basti-Urteil ≥ 80 % „passt jetzt“ | PL-1; Stellen aus L1/L2 | [E] |
| PL-3 | Allee nach Regel 5, plus Validator-Prüfung: Variationskoeffizient der Abstände ≥ 0,15, Anteil strikter Artwechsel < 60 % | Stadt 0,5 | beide Werte im Validator; Blind-A/B alt/neu mit 3 Personen, ≥ 2/3 nennen neu „natürlicher“ | Entwurf streicht T-S2; **wir halten dagegen**, s. Widersprüche | [E] |

**Risiko:** gering bis mittel. Generator-Änderungen verschieben Gebäude, und Wege-Halte (`knoten_halt` ≤ 40 m) können wandern. `proto_sim_test` und `proto_welt_test` müssen grün bleiben.
**Testweg:** `python3 tools_proto/stadt_validate.py` (Exit 1 bei FAIL) in der schnellen Stufe.

---

## 4 Ladeplatz, Fuhrwerk/Kutsche, Altersstufen, Easing nach Tempo, Ortsschild

### Befund

- Halt heißt heute: Wegende oder Kreuzung ≤ 40 m vom Gebäude (`proto_sim.gd` Z. 185–187). Einen sichtbaren Ladeplatz gibt es nicht. Das Gespann hält am Gutshof „im Weg“, 20 m vor dem Tor (`fixpass_w2.md` Z. 12, 69) [M].
- Die Ladung ist nicht sichtbar (Integration M10, im Fix-Pass nicht behandelt, kein Prefab-Teil „Ladung“ außer am Floß) [M] Grep `ladung` in `proto_prefabs.gd`.
- Das Pferd ist ein Kenney-Block-Behelf (Zähler 3+). Die Quaternius-Lizenz ist nur aus einer Repo-Notiz bekannt, im Web nicht geprüft (`resuemee/mt-art.md` §4, §7).
- `INSTANCE_CUSTOM` ist bei Fahrzeugen **voll belegt** (x Gang, y Variante, z Nicken, w Wanken, `integration_w2.md` I7). Frei ist nur **`COLOR`** (`use_colors`, heute Weiß, I1) [M]. Altersstufe und Firmenfarbe (F-22) konkurrieren um diesen einen Kanal, also braucht es einen Belegungsvertrag (TA).
- Easing hängt an v_sim: Das E4-Profil ist (Kurvenfaktor · v_sim)²/R (`proto_easing.gd` Z. 104), der Gangdeckel steht bei 2,5 Hz (Z. 49). Bei k = 8 (18,75 m/s) läge die Schrittfrequenz ohne Deckel bei ≈ 7 Hz [R]. Die Gangphase als Halbfloat über 240 m springt bis 17° (`resuemee/mt-techart.md` §4).
- Schild-Kontrast: **Die Platte allein** hat bei Erlenbach in der Fernstufe 2,95:1 gegen die Umgebung, **mit Rand 3,26:1** (`aylin_welle2.md` Z. 76–79, `aylin_kontrast_bild.csv`). Ob das ein Fail ist, hängt an der Gate-Definition. Wir führen es als Fail (Lernlog Aylin) und heben die Platte an. Der Status auf dem Schild (Trend „gleich“, Bedarf „wird gebraucht“) ist ein Platzhalter (`aufgabenkarten_v1_1.md` Z. 31).

### Tickets

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| LP-1 | Ladeplatz je Betrieb und Abladestelle je Ort: Kies-Hoffläche (`flaeche_hof`, gibt es), Rampe als Prefab, Lagergut-Haufen in Güterfarbe mit 3 Füllstufen nach Bestand (`concept/sophie.md` Z. 62); Weg bis zum Ladeplatz; Halteknoten = Ladeplatz | Stadt 0,75 (Daten/Wege), Sophie 1 (Haufen Getreide/Mehl, Rampe), TA 0,25 (Prefab-Regeln R1–R6), Felix 0,25 (Halt = Ladeplatz) | Für Farm, Mühle, Gutshof, Dorf und Kleinstadt gilt: Gespann-Heck ≤ 3 m vom Ladeplatz (Test in `proto_fixpass_test` erweitern); aus 170 m zeigen 3/3 Personen auf den Ladeplatz; Füllstufe ändert sich mit dem Lager (Test) | ProtoSim-Bestand je Halt (Felix/E1) | [E] |
| FW-1 | Ladung sichtbar (M10) und Pferd (Lizenz prüfen, einbauen oder bewusst als Behelf streichen) | TA 0,5, Sophie 1 | Beladenes Fuhrwerk zeigt die Ladung aus 80 m (3/3); Pferd mit Lizenzzeile in `asset_audit`, AABB in `proto_mass` grün | COLOR-Vertrag (FW-2) | [E] |
| FW-2 | Altersstufen neu/gebraucht/alt als Patina über `COLOR` (Sättigung −, Ton dunkler, Planenflecken); Belegungsvertrag `COLOR.rgb` = Firmenfarbe, `COLOR.a` = Alter 0–1 | TA 0,5, Sophie 0,25 (Look-Definition) | 5 Personen unterscheiden neu/alt aus 80 m in ≥ 4/5 Fällen; Draw Calls unverändert | **hängt an D5** (ohne Alterung entfällt FW-2: −0,75 T) | [E] |
| FW-3 | Folgemodell „Frachtwagen (4 Pferde, Plane)“ mit klar anderer Silhouette (Länge, 4 Pferde, Plane), eigenes Prefab | Sophie 1,25, TA 0,25 | aus 300 m 5/5 Personen „anderes Fahrzeug“; Maße nach E1 in `proto_mass` | **hängt an D5 + Entwurf F4 (KANN)**. Ohne: −1,5 T | [E] |
| FW-4 | Easing und Gang nach Tempoentscheid: Profile E1–E8 neu messen, Gangdeckel für Schritt/Trab 1,5–2,5 Hz, Gangphase je Doppelschritt (2,6 m) statt 240 m (Halbfloat-Fix) | TA 1, Felix 0,5 (Profil an v_sim) | `proto_easing_test` 0 FAIL, E6 ≤ 1,3 × W/2 oder ABW begründet; Beinphasen-Sprung ≤ 3° (Rechnung im Test); Basti in L1: „Tempo glaubwürdig“ ja | **hängt an D2** (k = 4–8); Entwurf T2 | [R]/[E] |
| OS-1 | Ortsschild-Status: Versorgung je Ware (Icon + Füllring), Sättigung als Zustandsform (Zustand vor Zahl, `concept/aylin.md` Z. 7), Zeile „gebremst durch X“; Platte 88 → 94 % Deckung oder Rand 2 px | Aylin 0,75, Mira 0,5 (Anbindung ProtoSim) | Alle 15 Bildmessungen: Platte ≥ 3:1 **und** Text ≥ 7:1 (`proto_schilder_shots.gd`); Status = Sim-Wert (Test je sichtbarer Zahl, Retro S6) | E2 Sättigung (Entwurf) | [M] Kontrast heute / [E] |

**Risiko:** mittel. Der COLOR-Kanal ist ein Engpass zwischen Alter, Firmenfarbe und Variante, deshalb braucht es den Vertrag vor dem ersten Merge. Das Pferd kann an der Lizenz scheitern, dann bleibt der Behelf, offen benannt.
**Testweg:** `proto_mass`, `proto_easing_test`, `proto_fixpass_test` (erweitert), Personenproben mit Daniel und 2 weiteren.

---

## 5 UX des Loops (Erkennen → Bauen → Verbinden → Beobachten → Optimieren)

Grundregeln: Gültigkeit und Kosten getrennt zeigen (Form/Farbe = baubar, Zahl = Preis, `concept/aylin.md` Z. 8). Keine stumme Ablehnung (U-03). Eine Meldung zugleich, 4–10 s, Inhalt bleibt im Protokoll (`resuemee/mt-ux.md` R3). Texte ab 18 px bei 1080p (R1). Achtung Tastenbelegung: 1–5 sind Kamera-Presets und dürfen nicht für Werkzeuge oder Abfragen benutzt werden.

| Schritt | Was der Spieler sieht | Ticket |
|---|---|---|
| Erkennen | Schild/Plakette → Klick → Panel: Ware, Bestand, Abnehmer mit Sättigung, Lizenzstatus, „Linie von hier“ | UX-2 |
| Bauen | Lizenz im Panel; Stichweg: Ghost von Gebäude zu Knoten, Preis inkl. Hangfaktor daneben, rote Fehlstelle mit Ursache + Lösung | UX-3 |
| Verbinden | Linie: Quelle → Ziel klicken; Vorschau Route, Fahrzeit, Ertrag je Fuhre, €/min, Fixkosten; Fuhrwerk wählen und kaufen | UX-2 |
| Beobachten | Fahrt mit sichtbarer Ladung, Lagerhaufen am Ladeplatz, „+x $“ an der Abladestelle, Linienliste €/min | UX-8, LP-1 |
| Optimieren | Sättigungswarnung, Diagnose-Toast mit einer Aktion, Fahrzeugkarte Alter/Ersetzen, Ziele F1/F2 | UX-4, UX-5, UX-7, UX-6 |

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| UX-1 | Loop-Flow-Spezifikation: Zustände, Übergänge, Fehlerfälle je Schritt, Wireframes (Fluss oben) | Aylin 1 | Jeder Schritt hat ≥ 1 Erfolgs- und ≥ 1 Fehlerweg mit Text; Mira bestätigt die Umsetzbarkeit Tag 3 | Grundlage P1–P3, U1–U4 (Entwurf) | [E] |
| UX-2 | Panel Betrieb/Ort und Linienanlage, Spec + Texte | Aylin 0,5 | Linie in ≤ 4 Klicks ab Panel (play.sh-Lauf); Vorschau zeigt €/min ±5 % gegen den gemessenen Wert nach 5 min | UX-1; Mira P1/P2 | [E] |
| UX-3 | Stichweg-Vorschau (Ghost, Preis, Hang, Fehlstelle) | Aylin 0,25 | 0 stumme Ablehnungen in allen Fehlerfällen (play.sh); Preis = gebuchter Preis (Test) | **hängt an D3**; Felix P3 | [E] |
| UX-4 | Sättigungswarnung am Ort und in der Linienliste: ab 100 % gelb, ab 130 % rot, Text „Lindenfurt hat genug Mehl (130 %). Jede weitere Fuhre bringt nur noch 40 %. Verbinde einen zweiten Abnehmer.“ | Aylin 0,5 | Schwellen gleich `economy.gd f_saett_promille` (Test); Basti in L3 nennt die Ursache des Ertragsrückgangs selbst | E2 (Entwurf) | [E] |
| UX-5 | **A-08** Diagnose-Toast: Ort + Ursache + eine Aktion, Klick springt zur Kamera, Queue + Protokoll. Katalog ≥ 6 Fälle: wartet auf Ladung, Abnehmer gesättigt, Lizenz läuft ab, Linie mit Verlust, Fuhrwerk alt/Unterhalt hoch, Kasse reicht < 60 s für Fixkosten | Aylin 1,25, Mira (Entwurf U4) | Jeder Toast erfüllt das Textschema (Test); in L3 „verstanden ja“ ≥ 80 % aller gezeigten Toasts; 0 überlappende Toasts | Zähler 4. Muss ins Sprintziel, nicht in den Stretch | [R] Entwurf U4 |
| UX-6 | Ziele F1/F2 + „Nächster Schritt“ aus dem Slice übernehmen, Texte | Aylin 0,25 | Jedes Ziel hakt nur beim richtigen Objekt ab (Regel aus S7 B-xx) | Z1 (Entwurf) | [E] |
| UX-7 | Fuhrwerk-Lebenszyklus in der UI: Kauf beim Linienbau (Entwurf F1), Fahrzeugkarte mit Alter (Balken Jahre/Lebensdauer), Unterhalt/min inkl. Alterungsaufschlag, „Ersetzen durch … – Restwert x, neu y, spart z/min“, Hinweis „Neu verfügbar: Frachtwagen (+80 % Ladung)“ | Aylin 0,75 | Alle Zahlen gleich Sim (Test); Basti in L3 ersetzt ein Fahrzeug ohne Hilfe | **hängt an D5** (ohne Alterung: −0,5 T, nur Kauf/Verkauf) | [E] |
| UX-8 | Lieferung und Übergabe sichtbar: Lade-/Entladebalken am Gespann, „+x $“, Fuhren/min in der Linienliste | Aylin 0,25 | Basti in L2 beschreibt, wo geladen und wo abgegeben wird | LP-1, U6 (Entwurf) | [E] |

**Risiko:** hoch auf der Seite der Umsetzung. Alles läuft über Mira (Entwurf §4: 6–9 PT P1/P2/U1–U4) und dazu F-22/SK-02 im selben Sprint. UX-Spezifikationen ohne Mira-Kapazität bleiben Papier.
**Testweg:** play.sh-Durchläufe je Fehlerfall, Textschema-Test, Basti-Karten L2/L3, 3 Fremdtester (D16 aufbrechen, §8).

---

## 6 Basti-Test

### Startweg ohne Konsole
Startmenü-Eintrag „Welt spielen“ als sichtbarer Knopf, nicht nur Taste P (`start_menu.gd` Z. 137). Wenn Felix 1 PT hat (Entwurf Q3), ein Windows-Build (`export_presets.cfg` vorhanden). Die Aufgabenkarten nennen einen einzigen Startweg. Main-Run-Args-Anleitungen entfallen.

### Aufgabenkarten

| Karte | Dauer | Inhalt | Abfrage |
|---|---|---|---|
| L1 (Etappe 1, Tag 5) | 10 min | Welt aus dem Menü starten, HUD-Screenshot (RL-0), Pause/2×/4×, Fuhrwerk Farm → Mühle mit Stoppuhr, Schalter alt/neu fürs Tempo, 3 Hügel/Senken benennen, **mit F12 Stellen für Boden/Placement sammeln** | Tempo glaubwürdig ja/nein; Hügel 0–3 gefunden; Stellenliste |
| L2 (Etappe 2, Tag 10) | 20 min | ohne fertige Kette starten, Lizenz, Getreide → Mühle → Dorf anlegen, 2. Fuhrwerk, Kredit ab Minute 12, Gewinn je Linie ablesen; **Bodentextur/Placement vorher/nachher an den eigenen Stellen** | je Schritt geklappt ja/teils/nein + Minuten; je Stelle besser/gleich/schlechter |
| L3 (Etappe 3, Tag 13) | 45 min | freies Spiel mit F1/F2, Sättigung, Ersetzen, Diagnose | Interessenkurve alle 5 min (1–5); je Toast verstanden ja/nein; 5 Schlussfragen |

**Testmodus im Spiel (Ticket TK-2):** Alle 5 min unten rechts eine kleine Leiste mit 5 Knöpfen, ohne Pause und ohne Tasten 1–5, verschwindet nach 20 s. An jedem Toast im Testmodus zwei Knöpfe „verstanden ja/nein“. Alles geht nach `user://test_log.csv` (Zeit, Antwort, Kasse, Linien, aktive Toasts, Ziele). So liegen Interesse und Spielzustand auf derselben Zeitachse, und Basti muss nichts mitschreiben.

### Rückmeldung strukturiert
- Formular als Tabelle (Markdown oder CSV): Karte | Schritt | geklappt | Minuten | Note 1–5 | Stelle-ID (F12) | Stichwort.
- Screenshot-Format: F12-Paar (PNG + JSON), Dateiname `S8_<karte>_<mm-ss>_<stichwort>`. Ersatzweise Format A aus §1.
- Ein Ordner wird gezippt zurückgegeben: `stellen/`, `test_log.csv`, Formular.

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| TK-1 | Karten L1/L2/L3, Formular, Auswertungsvorlage (Interessenkurve gegen die Annahme aus G-01, Toast-Quote) | Aylin 1,5, Lena (Entwurf Q5) | Karten im Ton von v1.1, je Karte ≤ 1 Seite; Auswertung binnen 0,5 T nach Eingang | Etappen-Builds | [R] L-14 = 1,5 |
| TK-2 | Testmodus: Interessenleiste, Toast-Knöpfe, `test_log.csv`, F12 (gemeinsam mit BT-1) | Mira 0,5, TA (F12 in BT-1) | Lauf von 45 min erzeugt 9 Interessenwerte und je Toast eine Zeile; abschaltbar, im Normalspiel unsichtbar | BT-1 | [E] |
| TK-3 | Startknopf „Welt spielen“ | Mira 0,25 | Basti startet ohne Editor-Einstellungen (Karte L1 Schritt 1 „geklappt“) | Q3/Q4 Entwurf | [R] |

**Risiko:** mittel. n = 1, und Basti kennt das Konzept. Deshalb dieselben Karten mit 3 Fremdtestern (§8). Absturz im P-Menü (Entwurf Q4) ist nicht geprüft, der Startknopf darf nicht über denselben Pfad laufen, bis Q4 reproduziert ist.

---

## 7 Parallelstrang Firmenkauf (F-22) und Skilltree (SK-02), UX-/Art-Seite

Vorab [M]: Ein Besitzer-Datenmodell gibt es nicht (0 Treffer, Entwurf §1). KI-Konkurrenz gibt es im Code ebenfalls nicht (Grep `rival|konkurren|competitor|ki_firma` in `slice/**/*.gd`: nur `tests/parity_test.gd`). Der Skilltree existiert nur als Platzhalter-Text (`ui/fehlertexte.gd` Z. 219–220). UX und Art können **bis zur Abnahme am Mock** liefern. Erlebbar wird es nur, wenn Felix/Tobias Besitz und KI liefern.

### 7a Firmenkauf

**Entscheidung nötig (D-F, neu):** „Firmenkauf“ meint zwei Dinge (`lenses…/auswertung.md` Befund 12): **C1** Industrie kaufen (Lizenz → Kauf, 50 % der Lizenzgebühren angerechnet, Werksmarge 15 %, `concept/industry.md` Z. 9–19), braucht keine KI. **C2** KI-Firma übernehmen (Gebot 130 % nach 3 Verlustmonaten, Z. 74), braucht KI und Konkurrenz (E14). Bastis Wunsch „Konkurrenzfirma sehen“ zielt auf C2. Empfehlung: **S8 = C1 voll**, plus Sichtbarkeit fremder Lizenznehmer, falls ein KI-Bot läuft. C2 als UI-Spec ohne Bau. Delta C2 in der UX/Art-Seite: +1,5 T (Aylin 0,5, Sophie 0,5, TA 0,5), auf der Technik-Seite deutlich mehr (nicht unsere Schätzung).

UI-Fluss (D21: keine grauen Modals, Bestätigung inline im Panel):
1. **Sehen:** Das Betriebs-Panel zeigt die Besitz-Leiter (keine/Lizenz/Besitz), den Besitzer mit Firmenfarbe, Lizenznehmer (max. 2) und die Werksmarge-Vorschau. Kaufpreis = Preis − angerechnete Lizenzgebühren, beide Zahlen sichtbar.
2. **Angebot:** Knopf „Kaufen für 3.400 $ (−600 $ angerechnet)“ und die Zeile „rechnet sich nach ~N min bei heutigem Durchsatz“, aus der Sim und nicht geschätzt.
3. **Bestätigung:** Inline-Leiste mit Folgenliste: exklusiv, Fremdlizenz von X wird mit Y $ ausgezahlt, Unterhalt +20 $/min × Stufe, Kasse nachher, Kreditrahmen nachher.
4. **Folgen sichtbar:** Pin-Rand voll in Firmenfarbe (gestrichelt = Lizenz, `concept/industry.md` Z. 79), Hofschild/Fahne am Betrieb, Toast „Erlenmühle gehört dir. Werksmarge 15 % ab jetzt, Unterhalt 20 $/min.“, Finanzzeile „Werksmarge“.
5. **C2 (Spec):** Schwäche-Signal vorher („Firma X: 2 Verlustmonate“, Befund 15), Gebot erst danach.

Fehlertexte (Ursache + Lösung, U-03): Geld fehlt („Dir fehlen 1.240 $. Nimm Kredit (frei: 2.000 $) oder kauf erst die Lizenz für 340 $.“) · Exklusivlizenz der KI („… bis Monat 14, danach kaufbar.“) · gehört schon dir · Gebot abgelehnt (C2: „… nimmt erst nach 3 Verlustmonaten an; heute 1.“) · Bankrott-Vorwarnung aktiv („Kauf gesperrt, solange die Kasse die Fixkosten nicht deckt.“).

Besitz und Firmenfarben in der Welt: Fahrzeuge tragen die Firmenfarbe an Plane/Kasten über `COLOR.rgb` (E14 „sichtbar auf den Straßen“, Vertrag FW-2), Pins und Hofschild ebenso. Palette: Spieler + 3 KI, nicht Rot/Grün/Gelb (Statusfarben), nicht in den Güterfarben, ΔE2000 ≥ 20 untereinander und unter Farbfehlsicht-Simulation (Vorschlag Sophie, `resuemee/mt-artdirection.md` §6).

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| FK-U1 | UI-Fluss C1 + Fehlertexte + C2-Spec | Aylin 1,25 | Kauf in ≤ 3 Klicks ab Panel; jede Ablehnung mit Ursache + Lösung (play.sh); alle Folgezahlen = Sim (Test); 3 Fremdtester nennen nach dem Kauf 3/3 Folgen richtig | **hängt an D-F**; Besitzfeld (Felix/Tobias) | [E] |
| FK-A1 | Firmenfarben-Palette, Pin-Rand Lizenz/Besitz, Hofschild/Fahne als Prefab, Firmenfarbe im Fahrzeug-Shader | Sophie 1, TA 0,5 | ΔE2000 ≥ 20 paarweise, auch unter Deuteranopie-Simulation; 3/3 Personen ordnen aus 300 m Fahrzeug und Betrieb der richtigen Firma zu; DC unverändert | FW-2 Vertrag | [E] |

### 7b Skilltree

**Widerspruch im Konzept, Entscheidung nötig (D-S, neu):** Punktequelle Ast-XP aus Transport (`concept/lena.md` Z. 107) gegen „Meilensteine + Etappenziele, keine XP“ (`s7/refinement/ergebnis.md` Z. 91). Respec „kostet 25 % der Ast-XP“ (lena Z. 124) lässt sich ohne XP nicht abbilden. Solange D-S offen ist, kann die UI Punkte und Respec nicht abschließen.

Baum-UI:
- 6 Äste als Spalten, Epochenstufen als Zeilen. Sichtbar sind nur die aktuelle und die nächste Stufe (lena Z. 99). In S8 also Epoche I aktiv und II ausgegraut: max. 6 × (4 + 4) = 48 sichtbare Knoten. Das Datenmodell ist für ~110 Knoten ausgelegt.
- Rangknoten mit Pips (1/3, 1/5). Schlüsselfähigkeiten größer, mit einem Satz „Was kann ich jetzt, was vorher nicht ging?“ (lena Z. 100).
- **Nutzen vorab als effektiver Wert im aktuellen Spiel**, nicht als Nominalwert: „+8 % Ausstoß“ bringt bei 160 % Versorgung nur +0,9 % (`lenses…/auswertung.md` Befund 6). Die Vorschau zeigt „heute +x $/min“ aus der Sim. Sonst lügt die UI.
- Punktezähler mit Herkunft („+1 aus Ziel F1“). Respec je Knoten mit Kostenzeile. Gesperrte Schlüssel mit Schloss und dem Text „frei beim Epochenwechsel“.
- Zustände gesperrt/verfügbar/bezahlbar/gekauft über Form **und** Farbe. Text ≥ 18 px, 7:1.

| ID | Ticket | Owner T | Akzeptanz messbar | Folge/Abhängigkeit | Marke |
|---|---|---|---|---|---|
| SK-U1 | Baum-UI-Spec, Zustände, Nutzen-Vorschau, Respec, Texte Epoche I | Aylin 1,5 | 3 Fremdtester finden den Knoten zu einer Aufgabe („mehr Ertrag in Städten“) in < 30 s, 3/3; erklären die Respec-Kosten richtig 3/3; Vorschau-Wert ±10 % gegen den gemessenen Effekt (Test) | **hängt an D-S**; Lena (Knoteninhalte), Mira (Bau) | [E] |
| SK-A1 | Icons Epoche I: 6 Ast-Icons, 6 Schlüssel-Icons, Rahmen für 4 Zustände, ~4 Modifikator-Symbole; Rangknoten = Ast-Icon + Symbol aus dem vorhandenen Satz | Sophie 1,5 (oder UI-Artist, §8) | Stil wie `ui/icons.json` (weiße Silhouette 100×100, `make_icons.py`); 3 Personen ordnen 6/6 Ast-Icons dem Ast-Namen zu | SK-U1 | [E] |

Später (nicht S8): ~110 Knoten bis Epoche V brauchen rund 6 Ast- + 30 Schlüssel- + ~20 Modifikator-Icons, also ≈ 56 Icons [E].

---

## 8 Fehlende Rollen und Kompetenzen (Gesamtpaket)

| Lücke | Beleg | Folge ohne | Vorschlag |
|---|---|---|---|
| **UI-Artist/Icon-Designer** | 33 UI-Icons (`ui/icons.json`), S8 braucht ≈ 25–30 neue (Loop ~10: Fuhrwerk, Kutsche, Alter, Wartung, Sättigung, Ladeplatz …; Firma ~5; Skilltree ~16) | Sophie trägt es (2,5 T in der Tabelle) und fehlt dann bei Pferd/Folgemodell | 5–8 T extern oder Teilzeit; sonst Schnitt SK-A1 auf 6 Ast-Icons |
| **Gameplay-/UI-Entwickler Nr. 2** | Mira trägt P1–P3, U1–U4 (Entwurf 6–9 PT) **plus** F-22/SK-02-UI | Die UX-Specs aus 5/7 bleiben Papier. Das ist der größte Engpass, keine Art-Frage | dringend, sonst SK-02 nur als Spec |
| **Audio** | nur 3 Kenney-Klicks (`ui/assets/sounds`) | 45 min ohne Rückmelde-Ton (Lieferung, Kasse, Warnung) schwächt Toasts und Interesse | 1–2 T: 6–8 CC0-Sounds + Ambient, auch als Kuration durch TA möglich |
| **3D-Modellierung Fahrzeuge/Tiere** | Pferd als Block (Zähler 3+), „Kenney passt nicht“ (Zähler 7+) | Folgemodell und Altersstufen wirken behelfsmäßig | Teilzeit 3–5 T oder CC0-Pack mit geprüfter Lizenz |
| **UX-Research/Fremdtester** | n = 1 seit S3 (D16, `resuemee/mt-ux.md` §5.2) | Verständlichkeit von Toasts, Skilltree, Firmenkauf ist ungeprüft | 3 Personen, die das Konzept nicht kennen: 0,5 T Vorbereitung + 1 T Sitzungen (Aylin, im Puffer) |
| Level-Design (Spiel) | Stadtdesign platziert nach Regeln; Loop-Layout (2. Farm, kaufbare Betriebe, Gewässer je Kartentyp) ist Spiel-Level-Design | Karte passt zur Optik, nicht zum Loop | vorhandene Stadt-Rolle mit Lena koppeln (Tickets W4, LV-1), keine neue Person |

---

## 9 Kapazität (15 Arbeitstage, 12 T je Person)

| Person | Kap. | Plan | Puffer | Belegung |
|---|---|---|---|---|
| Aylin | 12 | 10,35 | 1,65 | UX-1 1 · UX-2 0,5 · UX-3 0,25 · UX-4 0,5 · UX-5 1,25 · UX-6 0,25 · UX-7 0,75 · UX-8 0,25 · OS-1 0,75 · BT-0/BT-5 0,5 · RL-0 0,1 · TK-1 1,5 · FK-U1 1,25 · SK-U1 1,5 |
| Sophie | 12 | 10 | 2 | BT-2 0,5 · RL-1 0,25 · LP-1 1 · FW-1 1 · FW-2 0,25 · FW-3 1,25 · FK-A1 1 · SK-A1 1,5 · Loop-Icons 1 · Look-Abnahmen je Etappe 0,75 · Vergleichstafeln für Basti 0,5 · Fremdtest-Unterstützung 1 |
| Technical Artist | 12 | 9,5 + 3,5 bedingt | 2,5 (geht zuerst in bedingte Tickets) | BT-1 1 · BT-2 2,75 · BT-3 1 · RL-1 1,25 · FW-1 0,5 · FW-2 0,5 · FW-3 0,25 · FW-4 1 · LP-1 0,25 · FK-A1 0,5 · Perf-Messung 0,5 · **bedingt:** BT-4 2 / RL-2 1,5 |
| Stadt-/Level-Design | 12 | 6,5 (+0,5 bedingt) | 5 | PL-1 1 · PL-2 1 · PL-3 0,5 · LP-1 0,75 · W4 Loop-Inhalt (2. Farm, Kleinstadt als Mehlabnehmer am Netz, Entwurf) 1 · LV-1 Gewässer Kartentyp Flusstal: Binsensee zur Kulisse verkleinern oder Nutzung (hängt an Bastis T-W1-Entscheid) 0,75 · kaufbare/fremde Betriebe in der Karte für F-22 0,5 · Fremdtest Placement 1 · **bedingt:** RL-2 0,5 |

**Ehrlich:** Wenn sowohl BT-4 als auch RL-2 nötig werden, fehlt TA ≈ 1 T. Dann fällt RL-2 (Relief per Licht reicht dann für S8, die Amplitude kommt S9). Stadtdesign ist kein Engpass. Die 5 T Puffer gehen **nicht** in neue Features, sondern bei Bedarf in E4 Wachstumsbild (Häuser je Stufe, Entwurf SOLL) oder als Gehilfe für LP-1/Ladeplätze. Sophies Plan setzt voraus, dass niemand für Icons dazukommt. Kommt ein UI-Artist, werden 2,5 T frei für Pferd/Folgemodell-Qualität.

### Reihenfolge und Kollisionsschutz (Art-Strang parallel zum Loop)

| Tage | TA | Sophie | Stadt | Aylin |
|---|---|---|---|---|
| 1–2 | BT-1 Messwerkzeug + F12, RL-1 Licht | Stilrahmen Boden, Detailtexturen, Palette Firmen | PL-1, W4 | UX-1, BT-0, OS-1-Spec, Karten L1 |
| 3–4 | FW-4 Easing nach k (sobald Felix T2 mergt) | FW-1 Pferd, LP-1 Haufen/Rampe | LP-1 Daten, PL-3 Allee | UX-2/3/4, FK-U1 |
| 5 | **L1 bei Basti** (Stellen per F12) | | | Auswertung L1 |
| 6–9 | BT-2, BT-3 an Bastis Stellen | FW-3 Folgemodell, FK-A1 | PL-2 an Bastis Stellen | UX-5 A-08, UX-7, SK-U1 |
| 10 | **L2 bei Basti** (Boden/Placement vorher/nachher) | | | Auswertung, Fremdtest Firmenkauf/Skilltree am Mock |
| 11–12 | bedingt BT-4 oder RL-2, FW-2, FK-A1 Shader | SK-A1 Icons, Loop-Icons | LV-1 | Texte final, Abnahmen |
| 13 | **L3 bei Basti** (45 min) | | | |
| 14–15 | nur Fixes aus L3, Perf-Messung, Abnahme | Abnahme | Abnahme | Auswertung, Review |

Dateibesitz (keine Doppelbelegung): TA besitzt `proto_terrain.gdshader`, `proto_terrain.gd`, `ta_export.py`, `proto_prefab.gdshader` (COLOR-Vertrag) und neu `world/proto_licht.gd`. Das Licht wird aus `prototyp_welt.gd` ausgelagert, weil Felix und Mira diese Datei für den Loop umbauen. Firmenkauf- und Skilltree-UI kommen als eigene Szenen (`ui/firmenkauf.tscn`, `ui/skilltree.tscn`), nicht in `main.gd` oder `prototyp_welt.gd`. Stadt besitzt `tools_proto/stadt_*.py` und `proto_instanzen/wege/orte.json`. Merge-Gate je Etappe: schnelle Regression < 5 min inkl. `stadt_validate.py` und BT-1-Messung.

**Zur Sprintlänge:** 15 Tage sind für unsere Seite sinnvoll, weil zwischen L1 (Stellen) und L2 (vorher/nachher) Zeit für BT-2/PL-2 liegen muss. Bei 10 Tagen fällt der Vorher/Nachher-Zyklus an Bastis Stellen weg. Länger als 15 Tage bringt uns nichts: Der Engpass ist Mira, nicht Art.

---

## 10 Widersprüche zum Entwurf (`loop_s8_2026-11-04.md`, stichprobenartig gegen das Repo geprüft)

1. **W2 Z. 58: „M6 Ackernähte, M8 Pflaster, M7 Ufer offen“ stimmt so nicht.** Der Fix-Pass (Commit 9eaa538, 03.11. 09:09, also vor Bastis Rundgang um 23:11) hat M6 teilweise behoben (Voronoi-Schläge, Restraster 25 m) und Pflaster/Kies gebaut (`fixpass_w2.md` Z. 16–17). Offen sind das Ufer (Integration M7) und die 25-m-Bodenkarte als Grundursache. Der Fix-Pass nummeriert anders als die Integration (Fix-M7 = Marktplatz): Gefahr der Verwechslung im Backlog.
2. **W1 Z. 57: „fällt still auf den Stub zurück“ stimmt nur halb.** Die HUD-Zeile zeigt die Geländequelle (`prototyp_welt.gd` Z. 562). Der Prüfweg ist ein Screenshot und kostet 0 PT. Neu ist außerdem: Die 33,6–153,8 m gelten für das ganze Fenster. Im Kern sind es 35–117 m, und 76 % sind < 3 % geneigt [M]. Das Relief ist im Spielbereich also auch von den Daten her schwach (Plateauregel), nicht nur wegen der Darstellung.
3. **U5 Z. 81: „Schild 2,95:1 unter Gate“ ist ungenau.** 2,95 ist die Platte allein bei einem Schild (Erlenbach fern), mit Rand sind es 3,26:1 (`aylin_welle2.md` Z. 76–79). Eine zweite 2,95 gibt es bei Wasser B gegen Acker hell (G3, `aylin_kontrast_g3_wasser.csv`). Das ist eine andere Metrik. Wir führen es trotzdem als Fail und beheben es in OS-1.
4. **Streichliste Z. 149: Baumallee T-S2 „gering, Kulisse“.** Basti hat sie ausdrücklich genannt, die Ursache ist im Code eindeutig (12-m-Takt, strikter Artwechsel, `stadt_gen.py` Z. 584–619), der Fix kostet 0,5 T bei freier Stadt-Kapazität. Wir nehmen sie rein (PL-3).
5. **Etappe 1 Z. 111: L1 mit „Bodentextur an den eigenen Stellen vorher/nachher“ ist nicht machbar.** Die Stellen gibt es noch nicht (Entwurf W2 selbst). Vorher/Nachher gehört in L2, L1 sammelt die Stellen (F12).
6. **D6 Z. 160: „2 PT timeboxed“ reicht nicht für die Ursache.** Stufe A kostet ~3,75 T TA+Sophie, Stufe B weitere 2 T. Mit 15 Tagen und TA außerhalb des Loop-Pfads passt das. 2 PT behandeln nur Symptome an Einzelstellen.
7. **W3 Z. 59: „keine Messung“ stimmt nicht mehr.** Eine Grobmessung liegt vor (§3, Winkel/Abstand/Bodenklasse). Was Basti meint, ist trotzdem ungeklärt. Neu ist außerdem: Der Validator kennt Ausrichtung, Baulinie und Hofzugang nicht.
8. **F2/FW (Z. 68–70): Zur Sichtbarkeit von Alter und Folgemodell fehlt die Grafikseite.** `INSTANCE_CUSTOM` ist voll (I7). Alter und Firmenfarbe (F-22, E14) teilen sich `COLOR`, ein Vertrag ist nötig. Der Entwurf schätzt F4 nur als Datensatz und Menü, ohne Prefab (≈ +1,5 T Art).
9. **Q5 Z. 113 / Interessenkurve:** Tasten 1–5 sind Kamera-Presets. Eine Abfrage „1–5“ per Taste kollidiert damit. Wir lösen es mit Knopfleiste + Log (TK-2) statt Papier.
10. **Streichliste Z. 141–142 (Firmenkauf, Skilltree) ist durch die PO-Nachricht überholt.** Für F-22 ist offen, ob C1 oder C2 gemeint ist (D-F). Für SK-02 widersprechen sich Punktequelle und Respec-Regel (D-S). Beides muss vor Tag 3 entschieden sein, sonst bleibt die UX-Arbeit im Mock.

Nicht geprüft: Bilder nach Änderungen (kein Godot-Lauf), Feinraster-Fundamente, Vorzeichen von `rot_deg`, Wirkung von SSAO in Compat, Lizenz Quaternius, Absturz P-Menü.
