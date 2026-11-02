# 03 Welt-Prinzipien: von der Landschaft zur Siedlungszahl (Art Director Welt mit Lena, Tobias, Aylin, 02.11.2026)
Zweck: Beantwortet E3. Was steht hinter mehr oder weniger Orten, was bedeutet das für Spiel, Strecken und Lieferketten? Dazu Startjahr als Datenparameter (E4).
Status: Skizze, Phase 2. Kennung wie in 01 ([Q], [~], [Annahme], [S7]).

## 1 Die Kette: Warum es dort Orte gibt
Orte entstehen nicht nach einer Zahl. Sie entstehen aus Boden, Wasser, Relief, Markt und Verkehr. Die Siedlungszahl ist darum ein **Ergebnis des Geländes**, kein eigener Regler.

| Ursache (real) | Wirkung um 1820 | Folge im Spiel | Generator-Parameter [Annahme] |
|---|---|---|---|
| Bodengüte (Aue, Löss) | dichte Dörfer, 1 je 3–4 km² [~] | viele Getreidequellen, viele kleine Senken | `dorf_dichte_je_km2` je Biom |
| Wasser (Bach, Fluss) | Orte und Mühlen an Bächen, Furten | Mühlenstandorte, Brücken als Engpass | Ortszentrum ≤ 300 m (12 F) vom Bach bevorzugt |
| Relief | Gebirge: Weiler und Einzelhöfe, Bergbau am Fuß | knappe Rohstoffe, teure Wege | über 600 m oder > 8 % nur Weiler |
| Markt- und Amtsrecht | zentrale Orte im Abstand 7 / 12 / 21 km (Christaller) [~] | Hierarchie der Absatzorte | auf 12,8 km: 2–3 Marktflecken, 1 Kleinstadt |
| Verkehr (Kreuzung, Furt, Chaussee) | Wachstum an Knoten | Fernstrecke folgt dem Altweg | Kleinstadt an Flussübergang + Chaussee |
| Erbrecht (Realteilung SW, Anerbenrecht NW) | viele kleine vs. wenige große Höfe | Regionen-Variation je Seed | optional `erbrecht`: Dorfgröße ×0,7 / ×1,3 |

**Rechnung für die 12,8-km-Karte (164 km²)** [Annahme Flächenanteile]: Ebene/Aue 50 % (82 km² × 0,3 = 25 Dörfer), Hügel 30 % (49 km² × 0,18 = 9), Gebirge 20 % (33 km² × 0,25 = 8 Weiler). Real sind das etwa **34 Dörfer + 8 Weiler** und 10.000–16.000 EW ([~] `referenzen.md` 1a). Mit Spielausdünnung ×0,45 bleiben **15 Spieldörfer**. Die gestrichenen Dörfer werden zu **Kulisse-Weilern** (3–6 Höfe, kein Label, keine Nachfrage). Die Landschaft wirkt so bewohnt wie real, ohne dass die Karte 40 Labels trägt.

## 2 Drei Szenarien
| | **A Wenige große Orte** | **B Gemischt (Hierarchie)** | **C Viele kleine Orte** |
|---|---|---|---|
| Bild | 2 Städte 5–10k, 2–3 Kleinstädte, 3–5 Dörfer (≈ S7: 12 Orte, 36k EW) | 1 Kleinstadt 2–5k, 2–3 Marktflecken 0,8–1,5k, 12–18 Dörfer, 6–12 Kulisse-Weiler | 35–50 Dörfer, höchstens 1 Marktflecken, 20–30 Weiler |
| EW gesamt / Siedlungsfläche | 20–35k (2–3× real) / ≈ 2,5 % | 9–15k (real) / ≈ 1,2 % | 9–16k (real) / ≈ 2 % |
| Epochentreue 1820 | falsch (Basti: „Städte zu groß“) | richtig in der Hierarchie, Dorfzahl ×0,45 | am realsten bei der Dichte |
| **Wirtschaft** | wenige große Senken, Sättigung früh (Abfall ab 1.000 ‰ [S7]) | eine große Senke, mehrere mittlere, viele kleine. Nachfrage steigt mit Netz und Wachstum | viele winzige Senken, keine Senke für Endprodukte (Werkzeug) |
| **Entscheidungen** | wenige große: welche zwei Städte verbinde ich | gestuft: welche Dörfer sammle ich, wann lohnt die erste Bahn | viele kleine, einzeln unwichtig, Mikromanagement |
| **Tempo** | schneller Profit, flache Mittelphase | langsamer Start mit Fuhrwerk, klarer Sprung mit der ersten Bahn | langsam und gleichförmig, die Bahn lohnt kaum |
| **Streckentypen** | Fernstrecke Stadt–Stadt dominiert, kaum Zubringer | Sammeltour (Fuhrwerk, 2–3 Höfe → Mühle), Zubringer (Dorf → Markt, 2–4 km), Fernstrecke (Markt ↔ Kleinstadt 5–10 km), Massengut-Pendel (Grube → Hütte 0,4–0,8 km) | Sammeltouren und Kurzstrecken, kaum Fernstrecke |
| **Lieferketten (3 Ebenen)** | Veredelung und Produktion ballen sich um die Städte → wieder „Reviere“ (Basti-Kritik) | Jede Ebene hat eigene Ortslogik: Rohstoff in der Fläche, Veredelung am Standortfaktor (Bach, Wald, Erz), Produktion am Marktflecken (Hände, Markt), Senke Kleinstadt | Rohstoff und Veredelung ok, Produktion hat keinen Ort, Ebene 3 schwimmt |
| **Mehrfachquellen** | viele Quellen für wenige Senken. Die nächste gewinnt, der Rest ist Deko | **breit gegen knapp:** Getreide 5–8 Farmen (Wahl nach Trasse), Erz/Kohle je 1–2 nur an einem Gebirge (Lage erzwingt die Strecke) | Quellen überall, die Wahl verliert Gewicht |
| **Technik** (Gebäude / Labels Übersicht / DC Häuser [Annahme: MultiMesh je 1-km-Kachel und Prefab]) | 3.500–4.500 / 7–10 / ≈ 150; Nahsicht Stadt teuer (S7: 1,15 M Tris) | ≈ 2.200 / 16–22 / ≈ 135 | ≈ 3.600 / 36–51 / ≈ 280 (S7-Gate Übersicht: 300 DC gesamt) |
| **Generator** | wie S7 | Abstände 60 F Dorf passen. Dörfer dürfen in Tälern clustern | Mindestabstand wird bindend, gleichmäßige Poisson-Verteilung **sieht konstruiert aus** (Basti-Punkt 8) |

### Ketten in B, gemessen an den S7-Bändern
| Glied | Ebene | Lage | Distanz Felder (m) | Fahrzeug 1820 |
|---|---|---|---|---|
| Farm → Mühle | Rohstoff → Veredelung | Aue → Bach zwischen 2–3 Dörfern | 18–30 (450–750) [S7], Sammeltour bis 60 | Fuhrwerk |
| Mühle → Marktflecken/Kleinstadt | Veredelung → Senke | Bach → Ort | 40–130 (1–3,3 km) [S7] | Fuhrwerk, später Bahn |
| Erz + Holzkohle → Hütte | Rohstoff → Veredelung | Gebirgsfuß + Wald → Wasser im Tal | 15–30 (0,4–0,8 km) [S7] | Fuhrwerk, Pferdebahn |
| Hütte → Manufaktur | Veredelung → Produktion | Tal → Marktflecken-Rand | 30–42 (0,75–1 km) [S7] | Fuhrwerk |
| Manufaktur → Kleinstadt | Produktion → Senke | Marktflecken → Kleinstadt | 200–320 (5–8 km) | **erste Bahn** |

Die Fernstrecke liegt jenseits des Ertragsknicks von 60 F (d_eff 50 % [S7]). Die Bahn lohnt dort über Menge, nicht über Distanz. Das ist historisch richtig, verlangt aber Tobias' Prüfung.

**Folge für die Verteilungsregeln:** R7 [S7] (gleicher Typ ≥ 160 F Abstand) gilt nur für knappe Typen (Grube, Hütte). Breite Typen (Farm, Holz) liegen bei ihrem Dorf, 80–120 F auseinander. Lagerstätten werden je Seed nur an 1–2 Bergflanken vergeben (Basti: Mine nur an manchen Bergen).

## 3 Empfehlung: B mit Kulisse-Weilern, Dorfzahl aus dem Gelände
**Empfehlung (Art Director, Aylin):** Szenario B. Die Hierarchie aus Kleinstadt, Marktflecken und Dörfern erzeugt von selbst die drei Streckentypen und gibt jeder Lieferketten-Ebene einen eigenen Ort. Die Dorfzahl (12–18) rechnet der Generator aus Biom-Flächen. Kulisse-Weiler holen die reale Dichte optisch zurück, ohne Label- und Nachfragelast.

| Stimme | Position |
|---|---|
| **Tobias (schärfste Gegenposition)** | Mit nur einer Kleinstadt gibt es **keine Fernstrecke zwischen zwei gleichwertigen Senken**. Genau davon leben Railway Empire und Transport Fever. Außerdem sinkt die Gesamtnachfrage gegenüber S7 auf etwa ein Drittel (12k statt 36k EW). Kreditstart, Zins und die Bankrottquote 15/17/18 % sind auf S7 kalibriert und kippen. Sein Vorschlag: B+ mit 2 Kleinstädten an den Enden des Flusstals. |
| Lena | Sie neigt zu C: Die Fuhrwerk-Ära lebt von Sammeltouren und vielen Dörfern, und „×0,45“ ist eine Zahl, die wir doch wieder setzen. Sie akzeptiert B, wenn Sammeltouren als eigener Streckentyp im UI erkennbar sind. |
| Aylin | Für B. Bei C sind es 40–50 Labels in der Übersicht, unlesbar. Label-Hierarchie: Kleinstadt und Marktflecken immer, Dorf unter 3 km Kamera, Weiler nie. |
| Art Director: Antwort an Tobias | Die zweite Senke liegt **außerhalb**: ein **Kartenrand-Markt** (Großstadt jenseits der Karte, erreichbar über Chaussee oder Fluss). Das ist real (die 12,8 km sind ein Ausschnitt), liefert die Fernstrecke und hält die Karte epochentreu. Die Nachfrage-Kalibrierung muss Tobias in jedem Fall neu messen. |

## 4 Startjahr als Datenparameter (grob)
Grundsatz: Die **Zahl** der Orte ändert sich zwischen 1820 und 1860 kaum, denn Dörfer bestehen seit Jahrhunderten. Es ändern sich **Größe**, Haustypen, Landmarken, Industrieformen und Fahrzeuge.

| Parameter | 1820 (Standard) | 1840 | 1860 |
|---|---|---|---|
| Kleinstadt EW | 2.000–4.000 | 3.000–6.000 | 4.000–8.000 (eine darf Stadt 10k sein) |
| Marktflecken / Dorf EW | 800–1.300 / 150–350 | 1.000–1.800 / 180–400 | 1.200–2.500 / 200–450 |
| EW Karte gesamt | 9–12k | 11–14k | 13–18k |
| Haustypen | S, M, L | + XL Mietshaus im Kern | + Bahnhofsviertel (Raster), Mauer teils abgerissen |
| Höchster Punkt im Ort | Kirchturm | Kirchturm, erste Schornsteine 25–30 m | Schornstein 40–60 m ≈ Kirchturm |
| Wege beim Start | 1 Chaussee (Kleinstadt → Kartenrand), sonst Feldwege | 2–3 Chausseen | Chausseenetz, evtl. Fremdbahn am Rand |
| Industrieformen | Gutshof, Wasser-/Windmühle, Stollen, Holzkohlehütte, Hammerwerk, Säge, Manufaktur, Köhlerei | + Tiefbauzeche (Malakow), Kokshochofen, Maschinenfabrik | + Puddel-/Walzwerk (Stahl), Dampffabrik, Ziegelei, Gasanstalt |
| Fahrzeuge | Fuhrwerk, Postkutsche, Kahn; Lok erst durch Fortschritt (Adler 1835) | Lok 1. Gen (Adler-Klasse, 30–40 km/h), Raddampfer | Lok 2. Gen (11–13 m + Tender, 50–70 km/h), Wagen 7–8 m |
| Preisindex Waren / Bahnbau [~]/[Annahme] | 100 / 100 | 95 / 100 | 110 / 80 |
| Startkapital [Annahme] | 6.000 $ [S7] | 8.000 $ | 10.000 $ |

Datenskizze: `"epoche": {"startjahr": 1820, "presets": {"1820": {"ort_ew_mult": 1.0, "haustypen": ["S","M","L"], "landmarke_max": "kirche", "industrie_set": "e1820", "fahrzeuge": ["fuhrwerk","kutsche","kahn"], "preisindex": 100, "startkapital_cent": 600000}, "1840": {…}, "1860": {…}}}`. Assets: 1820 vollständig, 1840/1860 tauschen nur Landmarken, Fahrzeuge und XL-Häuser.

## Offene Fragen an Basti
1. **Zweite Senke:** Darf es einen Kartenrand-Markt geben (Großstadt außerhalb der Karte über Chaussee oder Fluss), oder müssen alle Senken auf der Karte liegen (dann B+ mit 2 Kleinstädten)?
2. **Spielhorizont:** Bis wann wird ab 1820 gespielt (1870? 1900?), und soll die Kleinstadt bis dahin zur Stadt mit 10.000+ EW wachsen können? Davon hängen Haus XL, das Bahnhofsviertel und das Stadt-Raster ab.
3. **Siedlungszahl variabel:** Darf die Dorfzahl je Seed aus dem Gelände schwanken (12–18), oder soll jede Karte gleich viele Orte haben (Vergleichbarkeit, Balancing)?
