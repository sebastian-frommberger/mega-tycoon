# 15 Welt-Regelwerk v1.1 (Design Sprint Welt, Phase 3b, 02.11.2026)
Fortschreibung von `12_welt_regelwerk_v1.md` nach Bastis Entscheidungen **E6–E11** (`charter.md`). Alles aus v1, das hier nicht genannt ist, gilt unverändert. Daten: `12_regelwerk_v1_1.json` (gleiche Inhalte, Ganzzahl-Konvention wie v1).
Moderation und Entscheidung: **Jonas (PO)**. Am Tisch: Art Director (AD), Technical Artist (TA), Stadt-/Level-Designer (SLD), Lena, Tobias, Aylin, Sophie, Felix, Daniel.
Status: **entschieden** (PO, gilt) · **Annahme** (gilt bis Messung/S8) · **an Basti** (Grundsatz, Abschnitt F). Kennung [~] = Fachwissen, ungeprüft. [M] = im Code nachgesehen.

## 0 Was sich durch E6–E11 ändert
| Entscheidung | Wirkung auf v1 | Status |
|---|---|---|
| E6 (F1 B) | Ortsklassen 1820 wie v1 §3, [A]-Kennung bei „2 Kleinstädte“ entfällt | entschieden |
| E7 (F2 C) | Ohne Versorgung bleibt ein Ort auf Startgröße (kein Schrumpfen unter Start, Leerstand nur über Startgröße), Wachstum nur mit Versorgung | entschieden |
| E8 (F3) | Partie bis heute: Abschnitt A, Epochen als Daten, Prototyp bleibt 1820 | entschieden, Länge an Basti (F7) |
| E9 (F4 A + Easing) | Sim-Tempo bleibt; Bewegungsprofile je Kategorie, nur Darstellung (Abschnitt B). Rundgang-Schalter Tempo B/C entfällt | entschieden |
| E10 (F5 C/Einstellung) | Kartentyp Flusstal / Seenplatte / Seenreich, sichtbare Nutzung (Abschnitt C) | entschieden, Schiffe an Basti (F10) |
| E11 (F6 B + Konkurrenz) | Welt-Hebel knappe Quellen + Relief gelten; Konkurrenz als Hebel (Abschnitt D), Werte S8 | Skizze, Art der Gegner an Basti (F9) |

---

## A Epochen bis heute (Skizze und Regeln, kein Ausbau)

### A1 Code-Befund
| Was | Stand [M] |
|---|---|
| Epoche in Daten | `vehicles.json` und `goods.json` haben je Eintrag `"epoche": 1`; `vehicles.json` enthält schon `schiff_e1` „Raddampfer“ mit Infrastruktur `hafen` (im Code nicht benutzt) |
| Kalender | `economy_constants.json` `spieljahr_ticks` 7.200 = **12 min je Spieljahr**; 1 Periode = 1 Spielmonat = 1 min |
| Konzept | Lena (`concept/lena.md`): 5 Epochen 1850–2030, Freischaltung über 3 von 5 Epoch-Meilensteinen; Sophie (`concept/sophie.md`): Gebäude werden aufgestockt und angebaut, nicht ausgetauscht; Industrie: Bleibt / Modernisieren / Schrumpft / Umrüsten |
| Folge E8 | 1820 bis 2026 = 206 Spieljahre = **≈ 41 Std.** bei 12 min/Jahr (Transport Fever: ähnliche Größenordnung [~]) → F7 |

### A2 Epochentabelle (Welt-Epoche, Kalender)
| Ep. | Jahre | Leitbild | Gebäudestile (neu) | Straße / Gleis (Breite, Radius) | Fahrzeugkategorien (real L) | Industrien (Bild, neu) |
|---|---|---|---|---|---|---|
| **W1** | 1820–1849 | Postkutsche, Chaussee, Mühlen | Fachwerk, Putz, Klassizismus; Kate, Hof, Handwerker-, Bürgerhaus; Kirche (v1) | Feldweg 3,5; Chaussee 6 (Trasse 11), R 50; Gleis ab 1835 eingleisig 4/7, R 100, 60 ‰ | Fuhrwerk 9,5; Postkutsche 12,5; Adler-Zug (Lok 7,6); Kahn 20–30; Ruderboot 4,5 | Gutshof, Wasser-/Windmühle, Stollen, Eisenhütte, Manufaktur, Kalkofen (v1) |
| **W2** | 1850–1879 | Eisenbahnzeit | Mietshaus 4 Gesch. (16–18 m), Villa, Backstein-Fabrik, Bahnhof mittel | Chaussee gepflastert 6–7; Gleis zweigleisig 9, Hauptbahn R ≥ 300 | Planwagen 4 Pferde 14; Lok + Tender 15–17, Wagen 8–10; Raddampfer 35–50; Pferdebahn ab 1865 | Tiefbauzeche (Malakow 25–35 m), Puddelwerk, Dampfmühle, Ziegelei, Brauerei |
| **W3** | 1880–1919 | Hochindustrialisierung, Gründerzeit | Blockrand 5 Gesch. (Traufe 18–20), Arbeitersiedlung, Rathaus/Kaufhaus, Kirche neugotisch (Turm 60–90), Wasserturm 30–40, Sheddachhalle | Stadtstraße 12–20 m mit Gehweg, Boulevard 30–40; Straßenbahn in der Straße; Gleis R ≥ 300 | Lok + Tender 18–22, Wagen 9–10; Straßenbahn el. 10–12 (ab 1890); Schlepper + Schleppkahn 60–80 | Stahlwerk (Schlote 40–60 m), Kokerei, Chemie, Maschinenfabrik, Kohlekraftwerk, Silo-Großmühle |
| **W4** | 1920–1959 | Motorisierung | Siedlungszeile 3–4 Gesch. (12–15), Einfamilienhaus 8×10, H 8; Tankstelle, Kino, Silo 30–40 | Landstraße Asphalt 6–7,5; Autobahn ab 1935 Trasse 24–28, R ≥ 400; Oberleitung | Lkw 6–8; Bus 9–11; E-Lok 15–20; Diesel-Triebwagen 20–25; Motorgüterschiff 67–85 | Raffinerie, Zementwerk, Autofabrik, Kraftwerk mit Kühlturm |
| **W5** | 1960–1999 | Wachstum, Moderne | Wohnhochhaus 8–20 Gesch. (25–60 m), Plattenzeile, EFH-Teppich, Gewerbehalle 60×40×10, Einkaufszentrum, Fernsehturm (nur Großstadt) | Bundesstraße 7,5–10; Autobahn 4-spurig 30; S-/U-Bahn Großstadt | Sattelzug 16,5, Gliederzug 18,75; Bus 12, Gelenkbus 18; E-/Diesellok 16–20, Wagen 15–20; Binnen-Containerschiff 110 | Tagebau (km-groß), Großkraftwerk (Kühltürme 100–150 m), Chemiepark, Containerterminal, Gewerbegebiet |
| **W6** | 2000–heute | Gegenwart | Büroturm 60–150 m, Logistikhalle 200×100×15, Reihenhaus-Neubau, Windrad (gesamt 180–240 m), Solarpark | Autobahn 6-spurig 36; Schnellfahrstrecke Trasse 14, **R ≥ 3.300 m**, ≤ 40 ‰ (Tunnel, Viadukt) | E-Lkw 16,5; E-Bus 12/18; ICE 200/400; Güterzug bis 740 (30 Felder); Großmotorschiff 110–135 | Logistikzentrum, Windpark, Solarpark, Recycling |

Regeln: **E1 gilt in allen Epochen** (nichts überzeichnet, Fahrzeuge ≤ 1,2× real, Landmarken in echter Höhe: Windrad 8 Felder hoch, Kühlturm 5). Ein Zug ist so lang wie seine Wagen in echter Länge (Sim-Wagenzahl × reale Wagenlänge). Werte [~] aus Fachwissen, Prüfung je Epoche erst beim Ausbau.

### A3 Ortsklassen je Epoche (Ort-EW sichtbar; Band = Spätstart, Obergrenze = durch Versorgung erreichbar)
| Klasse | W1 1820 | W2 1850 | W3 1880 | W4 1920 | W5 1960 | W6 2000 |
|---|---|---|---|---|---|---|
| Dorf | 150–350 | 200–450 | 250–600 | 300–800 | 400–1.500 (Neubaugebiet) | 400–2.000 |
| Marktflecken | 0,8–1,3k | 1,2–2,5k | 1,5–4k | 2–5k | 3–8k | 3–10k |
| Kleinstadt | 2–4k | 4–8k | 5–15k | 8–20k | 10–25k | 10–30k |
| Mittelstadt (20–100k) | – | 0–1 × 10k (Wachstum) | 0–1 × 15–40k | 0–1 × 20–60k | 0–1 × 30–80k | 0–1 × 30–100k |
| Großstadt (≥ 100k) | – | – | – | – | 0–1, nur Wachstum | 0–1, bis ~100–120k [A] F8 |
| Metropole (≥ 1 Mio.) | – | – | – | – | – | **nicht auf der Standardkarte** (F8) |
| Siedlungsfläche gesamt (P4) | < 3 % | < 4 % | < 6 % | < 8 % | < 12 % | < 15 % (DE heute ≈ 14 % [~]) |

Rechnung Großstadt (Daniel, Tobias): 100.000 EW bei ≈ 6.500 EW/km² Siedlungsfläche [~] = **≈ 15 km² ≈ 9 % der Karte** (164 km² innen). Dazu die übrigen Orte → P4 ≤ 15 % hält nur mit einer Großstadt bis ~120k. Größer geht nur mit größerer Karte (F8). Sim-Stufe bleibt Schwelle 1.000/5.000/20.000 (Großstadt = `metropole`-Korb); Nachfrage einer 100k-Stadt ist 5× die einer 20k-Stadt → Ökonomie-Kalibrierung späterer Epochen ist ein eigener Sprint (Tobias), nicht Welt.

### A4 Wachstum Großstadt und Stadt-KI je Epoche
| Epoche | zusätzliche Stadt-KI-Schritte (nach v1 §3 Schritt 1–6) | Raster erlaubt |
|---|---|---|
| W1 | wie v1 (Lücke, Upgrade am Platz, Hofteilung, Vorstadt, Gasse, Platz) | nein |
| W2 | Ringstraße auf geschleifter Mauer; Bahnhofsviertel am Spieler-Bahnhof (max. 2×3 Blöcke) | nur Bahnhofsviertel |
| W3 | Stadterweiterung (Fluchtlinienplan): Blöcke 80–120 m am Ring/Bahnhofsviertel, Straßen ±10° aus Gelände; Altstadt-Upgrade bis Traufe 15 m | Erweiterung, **≤ 40 % der Stadtfläche** |
| W4 | Siedlungszeilen und Gartenstadt am Rand, Bänder an Ausfallstraßen; Dörfer bekommen EFH-Ränder | Siedlungszeilen |
| W5 | Großsiedlung (Hochhaus) am Rand **nur mit Spieler-Haltestelle** (×3 wie Vorstadt v1); Gewerbegebiet am Straßen-/Autobahnanschluss; Ortsumgehung | Großsiedlung, Gewerbe |
| W6 | Nachverdichtung (Lücke, Aufstockung), Logistik am Autobahnanschluss, Windpark auf Höhen ≥ 1 km von Siedlung [~] | wie W5 |

**Nie:** Raster in Altstadt oder Dorf; Hochhaus im historischen Kern; Wachstum ohne Versorgung (E7).

### A5 Entscheidungen Abschnitt A
| # | Thema | Positionen | Entscheidung | Begründung | Status |
|---|---|---|---|---|---|
| K21 | Welt-Epoche aus Kalender oder Meilensteinen | Lena: Epochenwechsel über Meilensteine (Konzept). Tobias: Welt muss deterministisch rechnen. AD: Häuserstil folgt dem Jahr, nicht dem Spielerfolg. | **Welt-Epoche (Bild, Haustypen, Ortsbänder) folgt dem Kalender.** Ob Meilensteine Fahrzeuge/Ketten zusätzlich sperren, entscheidet S8-Progression (G-01) | Welt bleibt reproduzierbar je Seed und Jahr; Meilensteine sind Spielfortschritt, nicht Welt | entschieden |
| K22 | Startjahr und Fortschritt | Aylin: Startjahr ist eigene Option (K19). SLD: Spätstart muss gewachsen aussehen. | Startjahr wählt Epoche W_s; Generator baut Orte im Band von W_s mit **Altersmix** (Start 1960: Kern W1–W2 30 %, W3 30 %, W4 20 %, W5 20 %). Im Spiel gelten Freischaltungen ab ihrem Jahr (wie v1 §9) | Spätstart sieht gewachsen aus; P7 „anderes Startjahr ändert nur Daten“ bleibt | entschieden |
| K23 | Gebäude-Upgrade nach Epoche | Sophie: aufstocken/anbauen statt tauschen. Felix: globaler Stiltausch = Neubau aller Instanzen. Lena: unversorgter Ort sähe 2000 aus wie 1820. | **Kein globaler Stilwechsel.** Neue und ersetzte Häuser im Stil ihrer Bauepoche; Upgrade am Platz = Ersatzneubau. **Altstadtschutz:** ≥ 30 % der W1-Häuser im Kern bleiben. **Bestandserneuerung** ohne EW-Änderung: max. 1 % je Spieljahr der Häuser, die ≥ 2 Epochen alt sind | Gewachsene Städte zeigen ihre Geschichte (P3); unversorgte Orte altern sichtbar, wachsen aber nicht (E7) | Annahme |
| K24 | Raster in späten Epochen | AD: Raster nur mit Grund. SLD: Gründerzeit war Raster/Fächer. Basti (02.11.): „Geometrisches“ stört. | Raster nur in den Fällen A4, mit Anteilsdeckel; nie Altstadt/Dorf | Historisch begründet, bleibt Ausnahme | entschieden |
| K25 | Größte Stadt / Karte | Tobias: Großstadt ist das sichtbare Ziel. Daniel: P4 reißt ab ~120k. Felix: größere Karte = Terrain ×4. | Standardkarte: bis Mittelstadt, Großstadt bis ~100–120k nur durch Wachstum; Metropole nicht auf Standardkarte | Echter Maßstab (E1) begrenzt die Fläche | Annahme, **an Basti F8** |
| K26 | Partielänge 1820–heute | Lena: 41 Std. sind Genre, aber ohne Ziele zäh. Tobias: Wirtschaft rechnet je Minute, Kalender ist trennbar. | Kalender und Wirtschaft entkoppeln (Wirtschaftsmonat bleibt 1 min); Jahreslänge als Datenfeld `spieljahr_min` (Standard 12) | Erst Bastis Wahl, dann Ökonomie-Folgen | **an Basti F7** |

### A6 Performance (Gate Übersicht ≤ 1,0 M Dreiecke / ≤ 300 DC gilt in jeder Epoche)
| Sichtstufe | Kamera | Darstellung Stadt | Budget |
|---|---|---|---|
| Nah | ≤ 400 m | Prefab je Haus, MultiMesh je Typ und 400-m-Kachel (v1) | Kleinstadt nah ≤ 2,9 M (v1) |
| Mittel | 0,4–1,4 km | Haus-LOD1 (Hochhaus 50, Haus 100–300 Tris) | – |
| Fern | 1,4–3 km | **Block-Proxy:** je Baublock 1 extrudiertes Mesh (40–80 Tris), 1 DC je 400-m-Kachel | – |
| Übersicht | > 3 km | **Stadtteppich:** 1 Mesh je 3,2-km-Kachel (≤ 20k Tris) + ≤ 200 Landmarken-Proxys (Türme, Kühltürme, Windräder) | Großstadt ≈ 80k + 10k Tris, ≤ 20 DC |

Hochrechnung W6 Übersicht: Terrain 0,76 M / 250 DC (S7) + Stadt 0,09 M + Bäume 0,12 M + Wasser ≈ **0,98 M / ≈ 275 DC → knapp**. Folge: **Terrain-LOD (Geomipmapping, S8-Backlog) ist Voraussetzung für W4+**, nicht für 1820. Felix bestätigt: Fahrzeuge 1.000+ laufen schon heute über MultiMesh (3 Puffer), Grenze ist das Terrain.

### A7 Asset-Mapping je Epoche
| Epoche | Kenney-Kits (vorhanden) | Lücke | Behelf / Empfehlung |
|---|---|---|---|
| W1 | Fantasy Town, Nature, Train (Lok a), Survival, Graveyard, Castle, Prototype, Watercraft (v1) | Pferd, Kutsche, Kahn | Quaternius Farm Animals (v1, Basti besorgt); Hilfsmeshes |
| W2 | + Train (Lok b/c, Wagen) | Backstein-Mietshaus, Fabrik, Bahnhof mittel, Raddampfer | Kitbash Fantasy `wall` (Stein) + flache Dächer + `chimney` gestapelt |
| W3 | Train, Castle (Türme) | **größte Lücke:** Gründerzeit-Blockrand, Straßenbahn, Stahlwerk, Schlote, Schleppkahn | kein passendes Kenney-Kit → Pack-Prüfung (unten) |
| W4 | City Kit Suburban (EFH), City Roads, Car Kit (teilweise) [~] | Oldtimer-Lkw/-Bus, Siedlungszeile, E-Lok | Kitbash; Car Kit nur nach Stilprobe |
| W5 | City Kit Suburban/Commercial/Industrial, City Roads, Car Kit, Watercraft (modern) [~] | Kühlturm, Plattenbau, Containerkran | Hilfsmesh Kühlturm (Hyperboloid, ~200 Tris) |
| W6 | wie W5 | Windrad, ICE, Logistikhalle | Hilfsmesh Windrad (Mast + 3 Blätter, ~150 Tris), Halle = Quader |

Regeln: City Kits und Car Kit sind **ab W4 erlaubt** (vorher verboten wie v1), eigene Texturen auf die Hauspalette umfärben, Faktor je Rolle (R1). Empfehlung Packs (nur Empfehlung, nichts laden, frühestens S9): ein CC0-Low-Poly-Pack für **1850–1950** (Backstein, Gründerzeit, Fabrik, Straßenbahn, Oldtimer). Kriterien: flache Farben ohne Textur, Module im 3-m-Raster, Stilprobe neben Fantasy Town Pflicht. Kandidaten aus Quaternius-Reihe [~, Inhalt und Lizenz vor Download prüfen]. Für Prototyp und S8 ist **kein** weiteres Pack nötig außer dem Pferd.

---

## B Fahrzeug-Easing (E9)

### B1 Code-Befund [M]
| Stelle | Befund | Folge |
|---|---|---|
| `main.gd:549` `_setup_astar` | `DIAGONAL_MODE_NEVER`: Wege nur waagrecht/senkrecht | Jede Richtungsänderung ist eine 90°-Ecke; Diagonalen sind Treppen. Regelwerk v1 §7 sagt „8 Richtungen“ → Widerspruch, Klärung in W-04b |
| `fleet_soa.gd` `route_from_cells`, `_fill_range` | Route = gerade Kanten zwischen Eckpunkten; Position = lineare Interpolation auf der Kante, Richtung = Kantenrichtung | Richtung springt an jeder Ecke von einem Tick zum nächsten |
| `core/sim_world.gd` | konstantes Tempo je Fahrzeug (`v_speed`), Halt und Anfahren sofort | kein Anfahren, kein Bremsen |
| `main.gd:3348–3489` | 3 MultiMeshes (Lkw, Zug, Ladung), Puffer je Sim-Tick (12 Floats), Render-Split über 4 Frames, Engine interpoliert zwischen Ticks (`set_buffer_interpolated`) | Tick = 100 ms; Fuhrwerk fährt **15 m je Tick**, eine 90°-Ecke liegt in 1–2 Ticks |
| `MultiMesh.physics_interpolation_quality` | nicht gesetzt = `INTERP_QUALITY_FAST` (Godot-4.7-Doku im Repo) | Basis wird linear gemischt: in der Ecke schrumpft das Modell auf ≈ 71 % und dreht als Sehne → der „Schuhkarton“ |
| `render_batch.gd` | nur statische Quader (Straßen, Lager) | betrifft Easing nicht |
| Züge | ein Quader je Zug | Wagen müssen später einzeln der Fahrlinie folgen |

### B2 Entscheidungen Abschnitt B
| # | Thema | Positionen | Entscheidung | Begründung | Status |
|---|---|---|---|---|---|
| K27 | Easing in Sim oder nur Bild | Felix: Parität exakt halten (parity 8/8, slice_test 74/74). Tobias: jede Fahrzeitänderung kippt T-15 und die Bot-Quoten (d08_bankrott). Lena: Pferde dürfen nicht galoppieren, die Gangart entscheidet. | **Nur Darstellung.** Bild folgt Sim mit begrenztem Zeitversatz; Sim liest nichts zurück | Fahrzeiten, Kalibrierung, alle Tests unverändert; „echte“ Fahrdynamik (Anfahrzeit, Steigungsabschlag) bleibt S8-Kandidat K3 | entschieden |
| K28 | Fahrlinie | AD: Fahrzeug muss auf dem Straßenband fahren, nicht daneben. Felix: Band ist Spline durch Feldmitten (v1 §7), dieselben Anker wie die Sim. Sophie: Rechtsverkehr, sonst fahren Gespanne ineinander. | **Fahrlinie = Spline des Straßen-/Gleisbands** + Spur-Versatz; Sim-Kante ↔ Spline-Abschnitt zwischen denselben Feldmitten, längentreu-proportional | Kurven ohne Knick; Treppen werden Diagonalen; kein eigener Bahnplaner | entschieden |
| K29 | Anfahren/Bremsen | Daniel: Zeitversatz begrenzen und messen. Aylin: Klick trifft das sichtbare Fahrzeug. | **Gleitender Mittelwert der Fahrstrecke** über W Ticks (kausal): Rampen statt Sprünge, Versatz ≤ W/2 Ticks. Klick und Tooltip nutzen die Bildposition | kein Blick in die Zukunft nötig, O(1) je Fahrzeug | entschieden |
| K30 | Kurventempo | Lena: Gespann bremst vor der Kurve. Felix: Zeit darf nicht driften. | Je Kurvenzone **zeiterhaltende Umparametrisierung**: Tempo an den Zonenrändern = Sim, Minimum in der Mitte = Kurvenfaktor, Überhöhung ≤ +15 % | Bild und Sim treffen sich am Zonenrand wieder | entschieden |
| K31 | Kosten bei 1.000+ Fahrzeugen | Felix: 5.000-Lkw-Bench (F-12) darf nicht kippen; Ecke liegt in einem Tick, also reicht Tick-Abtastung nah nicht. | **Nah-LOD:** Kamera ≤ 600 m, im Bild, max. 128 Fahrzeuge → je Frame ausgewertet, eigenes MultiMesh ohne Engine-Interpolation, Haltung (Rollen/Nicken/Wippen) über `INSTANCE_CUSTOM` im Shader. **Fern:** je Tick wie heute + Spline-Abbildung, `physics_interpolation_quality = HIGH` [prüfen] | Teuer nur, wo man es sieht; gleiche Funktion nah und fern → kein Sprung beim Wechsel | Annahme (Messung Prototyp) |

### B3 Bewegungsprofile je Kategorie (Daten, `fahrzeug_easing` im JSON)
| Kategorie | Sim F/Tick | Fenster W (Ticks) | Versatz max (s bei 1×) | Kurvenfaktor min | Überhöhung max | Mindestradius Fahrlinie (m) | Spur-Versatz (m) | Rollen max | Nicken max | Wippen (Amplitude / Takt-Deckel) | Animation (Deckel) | Abstand (m) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Fuhrwerk | 0,6 | 4 | 0,2 | 0,55 | +15 % | 8 | 1,5 | 3° | 2° | 0,12 m / 2,0 Hz | Bein 2,5 Hz Schritt/Trab, nie Galopp; Rad 3 U/s | 3 |
| Postkutsche | 0,6 [A] | 5 | 0,25 | 0,60 | +15 % | 10 | 1,5 | 4° (Federung) | 2,5° | 0,18 m / 1,5 Hz | Bein 2,5 Hz; Rad 3 U/s | 4 |
| Dampfzug | 1,0 | 8 | 0,4 | 0,80 | +10 % | 100 (Gleis) | 0 | 0° | 0,5° | Lok-Zittern 0,02 m | Treibstange 4 U/s, Rauch nach Tempo | Sim-Block |
| Diesel-/E-Zug (W4+) | offen | 6 / 5 | 0,3 / 0,25 | 0,85 | +10 % | 300 | 0 | 1,5° | 0,5° | – | – | Sim-Block |
| Lkw (W4+) | 0,6 | 3 | 0,15 | 0,60 | +15 % | 12 | 1,75 | 2° | 1,5° | 0,03 m | Rad 5 U/s | 4 |
| Bus (W4+) | offen | 4 | 0,2 | 0,60 | +15 % | 12 | 1,75 | 3° | 1,5° | 0,04 m | Rad 5 U/s | 5 |
| Schiff | 0,4 | 20 | 1,0 | 0,85 | +5 % | 3 × Länge | Fahrrinnenmitte | 4° Krängung | 1° + Dünung | Dümpeln 0,1 m / 0,3 Hz | Schaufelrad 1 U/s, Kielwasser | 2 Längen |

Formeln: Rollen = k·v²·κ (gedeckelt), Nicken = k·a_längs + Geländeneigung aus dem Höhengitter (`h_grid`, geglättet über 2 Felder), Wippen = A·sin(Gangphase). Gangphase und Raddrehung laufen mit gedeckelter Frequenz, nicht mit der echten Strecke (sonst 100 Hz Beinflackern bei 150 m/s). Wagen eines Zugs folgen derselben Fahrlinie mit Versatz n × Wagenlänge (knickt richtig). Abstandshalten nur Straße, nur Nah-LOD, Versatz ≤ 1 Fahrzeuglänge, sonst Überlappung zulassen (Annahme).

### B4 Ablauf (rein lesend, Reihenfolge je Fahrzeug)
| Schritt | Was | Kosten |
|---|---|---|
| 1 | Sim (unverändert) liefert Route, Kante, Position mm, Zustand | 0 |
| 2 | Fahrstrecken-Zähler (Darstellung, monoton) je Tick | O(1) |
| 3 | Gleitender Mittelwert über W Ticks (Ringpuffer, laufende Summe) → Anfahren/Bremsen | O(1); 5.000 × 20 × 4 B = 400 kB |
| 4 | Kurvenzone: zeiterhaltende Umparametrisierung | O(1) mit Zonentabelle je Route |
| 5 | Abbildung auf Spline-Abschnitt + Spur-Versatz → Position, Gier | O(1) mit Abschnittstabelle |
| 6 | Haltung (nur nah): Rollen, Nicken, Wippen, Gang-/Radphase → `INSTANCE_CUSTOM` | Shader |
| 7 | Routenwechsel/Kauf/Verkauf: Puffer neu setzen (einziger erlaubter Sprung, im Test ausgenommen und protokolliert) | – |

### B5 Messprotokoll (`easing_test.gd`, headless, plus Rundgang)
| # | Prüfung | Grenze |
|---|---|---|
| E1 | Sim-Prüfsumme mit Easing an/aus bitgleich; parity, slice_test, d08_bankrott unverändert grün | exakt |
| E2 | kein Positionssprung: \|Δp je Frame\| ≤ 1,2 × v_bild_max × Δt + 0,05 m | hart |
| E3 | kein Richtungssprung: Gierrate ≤ ω_max (Fuhrwerk 270°/s, Kutsche 240°/s, Zug 60°/s, Schiff 30°/s, Bildschirmzeit bei 1×) | hart |
| E4 | max. Querbeschleunigung v²·κ ≤ 1,25 × Profilwert (z. B. Fuhrwerk auf Dorfstraße R 25 m: (0,55 × 150)² / 25 ≈ 270 m/s² Spielzeit) über 10 Testrouten mit 90°-Ecken und Treppen | hart, Regressionszahl |
| E5 | Halt exakt: Bild steht ≤ 0,1 m am Sim-Haltepunkt, spätestens W/2 Ticks nach der Sim | hart |
| E6 | Zeitversatz jederzeit ≤ W/2 Ticks | hart |
| E7 | keine Stauchung: Basisspalten-Norm 1 ± 1 % in jedem Frame | hart |
| E8 | Kosten: Nah ≤ 1,5 ms/Frame bei 128 Fahrzeugen (Bastis Rechner); `fill_buffers` p95 im F-12-Gate (5.000er-Bench) | Gate |
| E9 | Rundgang A7: Easing an/aus, Bewertung 1–5 | Sicht (Basti) |

Kandidaten-Aufwand S8 (Ticket „E-01 Fahrzeug-Easing“): Felix 3,0 PT (Zähler + Filter 0,5, Spline-Abbildung 1,0, Nah-LOD/MultiMesh 1,0, Haltung 0,5), TA 1,0 (Gang-/Rad-Shader), Daniel 1,0 (Test, Bench), Sophie 0,5 (Profile), Aylin 0,25 (Klick auf Bildposition) = **≈ 5,75 PT**. Abhängigkeit: Spline-Band (W-04b); bis dahin Fallback „Kreisbogen an der Sim-Ecke“ (r = min(Mindestradius, 0,45 × kürzere Kante)).

---

## C Gewässer-Setting (E10)

### C1 Befund
Generator (`code_ws_c/world_gen.py`) kennt **einen** Hauptfluss (`river_u`, `is_water`), v1 ergänzt Bäche, Nebenflüsse, Teiche, 0–2 Seen. Validator prüft „Netz zusammenhängend per Land“ (V-E3) und Flussquerung (V-E4, V-L2). Keine Seenlogik, keine Inseln, keine Fähre. Daten haben schon `schiff_e1` + `hafen` (unbenutzt).

### C2 Kartentypen als Generator-Parameter
| Parameter | **Flusstal** (Standard) | **Seenplatte** | **Seenreich** |
|---|---|---|---|
| Vorbild | Süd-/Mitteldeutsches Mittelgebirge | Mecklenburg, Brandenburg | Alpenvorland, Skandinavien (TF3) |
| Wasseranteil innen | 3–5 % | 8–12 % | 15–25 % |
| Hauptfluss | 1 × 60–100 m | 1 × 40–80 m, verbindet Seen (Durchflussseen) | 0–1, Seen über Sunde/Flussstücke verbunden |
| Nebenflüsse / Bäche | 1–2 / 4–8 | 1–2 / 3–6 | 0–2 / 2–5 |
| Seen (Anzahl, Ø) | 0–2, 0,3–0,8 km | 4–8, 0,5–3 km, 1 großer bis 4 km | 8–15, 0,3–5 km |
| Buchten / Uferrauschen | gering | mittel | hoch (Halbinseln) |
| Inseln | 0 | 0–3 | 3–8 |
| Relief | ds_v2 | flacher: Hügelland 25–60 m dominant, Gebirge ≤ 5 % | ds_v2 + glaziale Rinnen und Becken |
| Methode | v1 | Becken-Rauschen + Senkenfüllung (Pegel = Überlaufhöhe), Abfluss als Bach/Fluss | wie Seenplatte, mehr Becken, Inseln = Kuppen über Pegel |

### C3 Verteilung und Validator
| Regel | Inhalt | Status |
|---|---|---|
| Eignung S (neu) | Seeufer 100–400 m +300 · Seeausfluss/Engstelle +250 (Brücken-/Fährort) · Buchtkopf +200 (Anlegerort) · Halbinselhals −100 · Insel aus · Uferstreifen < 50 m aus | Annahme |
| Ortszahl | ergibt sich weiter (E3); Obergrenze Dörfer skaliert mit Landanteil (16 × Landanteil / 0,95) | Annahme |
| Abstände | Luftlinie wie v1; zusätzlich Landweg Dorf → zentraler Ort ≤ 2,0 × Luftlinie | Annahme |
| **V-W1** Erreichbarkeit (ersetzt V-E3) | jeder Knoten über Land oder Brücke (≤ 8 Brückenfelder) erreichbar; Umweg ≤ 1,5 / 1,8 / 2,2 je Typ; ≥ 2 Querungen je Fluss bleibt | Annahme |
| **V-W2** Querungsstellen | je See > 1 km Länge ≥ 1 Engstelle ≤ 200 m; Abstand zwischen Querungen ≤ 3 km, sonst Fährstelle markieren | Annahme |
| **V-W3** Nutzung | jedes Gewässer ≥ 300 m (bzw. je 2 km Fluss) hat ≥ 1 sichtbare Nutzung ≤ 500 m vom Ufer, an sinnvoller Lage (C4) | entschieden |
| **V-W4** Anteile | Wasseranteil, Seenzahl und -größe im Band des Typs | entschieden |
| **V-W5** Inseln | Inseln ohne Brückenstelle ≤ 200 m tragen keine Knoten (nur Kulisse: Kapelle, Wald, Ruine) | entschieden |
| Furt / Fähre | Bach blockiert nicht (v1); Fluss-Furt nur Bild (Breite ≤ 40 m, flach); Fähre als Spielfunktion = S9-Kandidat (F10) | entschieden |

### C4 Sichtbare Nutzung je Gewässer
| Nutzung | Gewässer | Lage-Regel (Sinn) | Bild | Art | ab |
|---|---|---|---|---|---|
| Wassermühle | Bach, Mühlgraben, Seeausfluss | Gefälle, ≤ 200 m Wasser (V-L3) | Haus + Rad + Graben + Teich | **Mechanik** (Industrie `muehle`) | W1 |
| Fischer mit Steg und Boot | See, Fluss | ≤ 1,5 km zu einem Ort, ruhiges Ufer | Kate, Steg 20–30 × 2 m, Netzgestell, Ruderboot 4,5 m | Kulisse mit Funktion (Weiler, zählt ins Umland) → Mechanik-Kandidat „Fisch“ (TF3-Fischerei) S9+ | W1 |
| Teichwirtschaft | Teichkette am Bach | bei Gutshof/Kloster | 3–6 Teiche 50–150 m, Damm | Kulisse mit Funktion (gehört zum Gutshof-Gelände) | W1 |
| Furt | Bach, flacher Nebenfluss | wo Weg kreuzt, keine Brücke | Weg führt durchs Wasser | Kulisse (Sim blockiert ohnehin nicht) | W1 |
| Fähre | Fluss, Sund | Straße auf beiden Ufern, keine Brücke ≤ 2 km | Fährhaus, Gierfähre (Floß + Seil) pendelt | Kulisse → **Mechanik-Kandidat S9** (Straßenkante mit Wartezeit) | W1 |
| Anleger / Lände | Fluss ≥ 60 m, See | an Ort am Ufer | Kai 30–60 m, Tretkran, Kähne | Kulisse → Mechanik mit Schiffen (Hafen) | W1 |
| Holztrift / Floß | Fluss, Gebirgsbach | Nutzwald oberhalb, Sägemühle unterhalb | Floß aus Stämmen treibt, Holzstapel am Ufer | Kulisse mit Funktion (zeigt Holzkette S8) | W1 |
| Schiffsverkehr | Fluss ≥ 60 m, Seen | Fahrrinne, Häfen an Orten | Kahn, Raddampfer, später Motorschiff | **Mechanik** (Transportmittel) → F10 | W1/W2 |
| Kanal, Schleuse | zwischen Flüssen/Seen | Engstelle, Gefälle | gerades Band, Schleusenkammer | Mechanik-Kandidat | W2+ |
| Strandbad, Segelboote | See | nahe Stadt | Steg, Boote | Kulisse | W4+ |
| Staudamm, Wasserkraftwerk | Tal mit Fluss | enges Tal | Mauer, Stausee | Mechanik-Kandidat (Energie S8-Konzept) | W4+ |

### C5 Entscheidungen Abschnitt C
| # | Thema | Positionen | Entscheidung | Begründung | Status |
|---|---|---|---|---|---|
| K32 | Kartentyp | AD: Flusstal ist 1820-Mitteleuropa. Lena: Wahl erhöht Wiederspielwert. Tobias: Seen verlängern Wege, Ökonomie anders. Daniel: jeder Typ braucht eigene Erfüllbarkeit ≥ 18/20 Seeds. | Kartentyp = **Startoption** (neben Startjahr, Schwierigkeit), Standard Flusstal; Generator kann alle drei ab S8; **Seenreich erst wählbar, wenn Fähre oder Schiff spielbar ist** | ohne Wasserverkehr wird Seenreich zum Umweg-Labyrinth | Annahme (F10) |
| K33 | Nutzung sichtbar | Aylin: Nutzung muss man erkennen, sonst ist es Deko. Sophie: Steg und Boot reichen als Zeichen. Felix: Kulisse ohne Sim kostet nur Instanzen. | Regel V-W3 + Tabelle C4: jede Nutzung steht da, wo sie Sinn ergibt; Kulisse mit Funktion gehört zu einem Ort oder einer Kette | P5 „steht hier, weil …“ gilt auch fürs Wasser | entschieden |
| K34 | Mechanik oder Kulisse | Tobias: Schiffe sind eine eigene Kette mit Kalibrierung. Lena: Fähre ist billig und spürbar. | 1820/S8: nur Mühle ist Mechanik; Fähre und Schiffe sind Kandidaten | Grundsatz Wasserverkehr bei Basti | **an Basti F10** |
| K35 | Seeufer im 25-m-Raster | Daniel: Uferzacken (v1 K7) werden am See länger. Felix: 12,5-m-Unterteilung im Uferstreifen +10k Tris je km Ufer. | Uferböschung 40 m (v1) + Ufer-Unterteilung nur, wenn G2 im Prototyp rot | messen statt vorbeugen | Annahme |

### C6 Asset-Lücken Wasser
| Bedarf | Behelf aus Kenney | Schwere |
|---|---|---|
| Steg | Fantasy `planks` + `poles` (Kitbash) | gering |
| Fischerhütte | Haus S + Netzgestell (`poles`) | gering |
| Ruderboot/Fischerboot | Watercraft `boat-row-small` (Faktor 0,066) | vorhanden |
| Gierfähre, Floß | Floß aus `planks`; Floß aus Nature `log_stack` | gering |
| Kai, Anleger | Castle `wall` umgefärbt + Fantasy `planks` | gering |
| Tretkran | Pirate Kran [~] umgefärbt | mittel |
| Kahn 20–30 m | Hilfsmesh Rumpf (~200 Tris) | mittel |
| Raddampfer 35–50 m | Rumpf-Hilfsmesh + Fantasy `watermill` seitlich + `chimney` | mittel (nur mit F10) |
| Schilf | Nature-Gras [~] | gering |

---

## D Konkurrenz als Schwierigkeitshebel (E11, Skizze, Entscheidung S8)

### D1 Code-Befund
| Was | Stand [M] |
|---|---|
| KI-Firmen | **gibt es nicht** (kein Code, `04_schwierigkeit`: „erst mit KI-Firmen“) |
| „Bot“ | `tests/d08_bankrott.gd` (T-16): Test-Spieler, spielt Spielertypen des Modells (sorgfältig/normal/hastig, Kredit, Lkw je Bedarf) mit **echten Spielbefehlen**, deterministisch je Seed; Drift-Wächter, kein Spielerbeleg. Tobias' Stichprobe (K1) läuft damit |
| Konzept | G-01 (`s7/block-b/g01_progression.md`): „KI-Konkurrenz light“: passiver KI-Spediteur nimmt Sättigungsanteil an 1 Industrie/Stadt, S8 nur passiv, abschaltbar, ab Min 35, kein Kauf, keine Sabotage, Platzhalter 15 %; aggressiv und Übernahmen erst mit Firmenkauf (F-22, S8) |
| Andockpunkte | Sättigung je Stadt und Kategorie (`saettigung`, `economy.gd`), Lizenzen mit Laufzeit und Verlängerung (+10 %), Gratis-Lizenz nur im HQ-Radius, Firmenkauf F-22 (S8) |

### D2 Hebel
| Hebel | Bereich | Wirkung auf die Welt |
|---|---|---|
| Anzahl KI-Firmen | 0–3 | Firmenfarbe als Wimpel/Plane (Einfärberegel v1) |
| Startzeit | ab Min 20 / 35 / 45 | – |
| Aggressivität | passiv (nur Marktanteil) / aktiv (Lizenzen, eigene Fuhrwerke, Stichstraßen) / aggressiv (+ Gleise, Preiskampf, Übernahmeangebote; erst mit F-22) | aktiv: Fahrzeuge auf öffentlichen Straßen; aggressiv: eigene Gleise in der Landschaft |
| Ziele | Kettenfokus (Agrar / Personen / Montan), bevorzugt Spieler-Senken ja/nein | – |
| Marktanteil-Deckel je Senke | 10 / 15 / 20 % der Sättigung | – |
| Lizenzbelegung | max. Zahl, nur Fernband oder auch nah | Plakette „belegt von …, frei ab mm:ss“ an der Industrie |
| Preiskampf | Lieferpreis-Abschlag an gemeinsamer Senke (−10 % für 10 min) [A] | – |
| Übernahme (F-22) | Spieler kauft KI-Lizenz/-Firma; KI übernimmt unbelieferte Spieler-Lizenz nach Ablauf; **nie** die Spielerfirma | – |

### D3 Entscheidungen Abschnitt D
| # | Thema | Positionen | Entscheidung | Begründung | Status |
|---|---|---|---|---|---|
| K36 | Wo sitzt der Hebel | Tobias: Balancing-Hebel, messbar im Bot. Lena: Sandbox ohne. Aylin: einzeln einstellbar. | Konkurrenz steckt im Schwierigkeits-Preset und ist unter „Benutzerdefiniert“ einzeln einstellbar; Sandbox ohne | wie Startjahr eigene Stellschraube, aber im Preset vorbelegt | Annahme |
| K37 | Sichtbarkeit | Aylin: unsichtbarer Ertragsabfall wirkt wie ein Bug. AD: KI-Netze verändern die Welt und müssen E1/Prinzipien einhalten. Felix: KI-Fahrzeuge sind normale Fahrzeuge in `fleet_soa`, 1.000+ gehen. | Konkurrenz ist **sichtbar** (Farbe, Fahrzeuge, belegte Lizenzen, Rangliste Firmenwert); Ausmaß an Basti | Genre-Standard (Railroad Tycoon, OpenTTD [~]); Bastis Regel „nicht neu erfinden“ | **an Basti F9** |
| K38 | Technische Basis | Felix: der T-16-Bot spielt schon echte Befehle. Daniel: deterministisch je Seed, sonst kein Test. | KI-Firma = Bot aus `d08_bankrott` als Spielfigur (gleiche Befehle, eigene Kasse), deterministisch je Seed | Wiederverwendung statt Neubau | Annahme |
| K39 | Fairness mit F6 B | Daniel: auf „Schwer“ gibt es 1 Quelle je knappem Rohstoff, die KI könnte sie sperren. Lena: Druck ja, Sackgasse nie. AD: KI baut nie an Engstellen. | **Schutzregeln:** KI belegt nie die letzte freie Quelle eines knappen Rohstoffs in 4 km um das HQ; vor Min 45 keine knappe Quelle; KI-Gleise nie an den ≥ 2 Fluss-/See-Querungen (V-W1/V-W2) allein; neuer Bot-Check **V-K1** „nach KI-Belegung je Kette ≥ 1 freie Quelle in Reichweite“ | Schwierigkeit über Druck, nicht über Pech | entschieden |
| K40 | Abnahme | Tobias: Bankrottquote je Stufe gilt inklusive Konkurrenz. | Ziel-Bankrottquoten (≤ 5 / 15–18 / 30–40 %) im Bot-Lauf **mit** Konkurrenz | eine Messgröße je Stufe | entschieden |

### D4 Presets (Skizze)
| Hebel | Leicht | Normal | Schwer |
|---|---|---|---|
| Anzahl | 1 | 2 | 3 |
| Start | Min 45 | Min 35 | Min 20 |
| Aggressivität | passiv | passiv, ab Min 60 aktiv | aktiv; aggressiv ab F-22 |
| Ziele | nur Agrar | Agrar + Personen | alle Ketten, bevorzugt Spieler-Senken |
| Marktanteil-Deckel | 10 % | 15 % (G-01) | 20 % |
| Lizenzbelegung | keine | max. 2, nicht im HQ-Radius | max. 4, auch nah (außer HQ-Radius) |
| Preiskampf | aus | aus | an |
| Übernahme | aus | Spieler kauft KI (F-22) | beidseitig, nie Spielerfirma |
| Welt-Hebel F6 B (zum Vergleich) | 2 Quellen, flach | 1–2, ds_v2 | 1, bewegt |
| Schutzregeln K39 | immer | immer | immer |

---

## E Prototyp-Plan v1.1
Eigene Datei `16_prototyp_plan_v1_1.md` (schlank 13,5 PT / voll 25,5 PT, Empfehlung **schlank + See + Easing**).

---

## F Fragen an Basti (max. 4)
Eine Antwort mit Buchstaben genügt („F7 A, F8 A …“). Bis zur Antwort gilt die Arbeitsannahme; nichts davon betrifft den Prototyp.

### F7 Wie lange dauert eine ganze Partie von 1820 bis heute?
**Worum es geht:** Ein Spieljahr dauert heute 12 Minuten. Bis heute sind es 206 Jahre, also rund 41 Stunden. Transport Fever liegt ähnlich. Ein schnellerer Kalender macht die Partie kürzer, aber Städte haben dann bis zur Moderne weniger Zeit zu wachsen.
| Option | Was du erlebst | Folge |
|---|---|---|
| A Wie heute | 12 min je Jahr, ganze Partie ≈ 41 Std.; kürzer über ein späteres Startjahr | nichts neu zu rechnen |
| B Doppelt so schnell | 6 min je Jahr, ≈ 21 Std. | Städte zur Moderne kleiner, Fahrzeuge veralten schneller |
| **C Wählbar** | Kalendertempo 12 / 6 / 3 min als Option, Standard 12 | Wirtschaft rechnet weiter je Minute, nur das Datum läuft anders |

**Empfehlung: C** mit Standard 12 Minuten. **Arbeitsannahme: A.**

### F8 Wie groß darf die größte Stadt am Ende werden?
**Worum es geht:** Weil nichts überzeichnet wird, braucht eine Stadt mit 100.000 Menschen etwa 15 km², ein Zehntel unserer Karte (13 × 13 km). Eine Millionenstadt passt in echtem Maßstab auf keine spielbare Karte.
| Option | Bild am Ende | Folge |
|---|---|---|
| **A Heutige Karte** | eine Großstadt bis ~100.000, sonst Mittel- und Kleinstädte, Landschaft bleibt prägend | passt zu E1, Technik machbar |
| B Größere Karte wählbar | z. B. 25 × 25 km, Großstadt bis ~250.000 und mehr Orte | Gelände-Technik ×4, längere Ladezeit, eigener Ausbau |
| C Metropole außerhalb | Millionenstadt als Ziel am Kartenrand, nicht begehbar | neue Regel für einen Außenmarkt |

**Empfehlung: A jetzt, B als spätere Option.** **Arbeitsannahme: A.**

### F9 Wie sichtbar sind die Konkurrenten?
**Worum es geht:** Konkurrenz macht das Spiel schwerer. Sie kann sich nur in Zahlen zeigen oder als Firmen, die du auf der Karte siehst.
| Option | Was du siehst | Folge |
|---|---|---|
| A Nur in Zahlen | weniger Nachfrage, belegte Lizenzen | billig, fühlt sich aber leicht wie ein Fehler an |
| **B Sichtbar auf den Straßen** | Firmen mit eigener Farbe, eigene Fuhrwerke auf öffentlichen Straßen, belegte Lizenzen, Rangliste | gut lesbar, mittlerer Aufwand, keine fremden Bahnen |
| C Volle Gegner | bauen eigene Bahnstrecken, Preiskampf, Übernahmen (wie Railroad Tycoon) | größter Aufwand, verändert die Landschaft stark |

**Empfehlung: B** in S8/S9, C erst mit dem Firmenkauf. **Arbeitsannahme: B.**

### F10 Ab wann ist Wasser ein Verkehrsweg?
**Worum es geht:** Seen und Flüsse bekommen sichtbare Nutzung (Mühle, Fischer, Fähre, Anleger). Ob Boote und Schiffe auch Waren für dich fahren, ist eine eigene große Funktion. Ohne sie werden viele Seen zu Umwegen.
| Option | Was du tun kannst | Folge |
|---|---|---|
| A Nur Kulisse | Wasser wird genutzt, aber nicht von dir; Seenreich nicht wählbar | kein Aufwand, Seen bleiben Hindernis |
| **B Erst Fähre, dann Schiffe** | Fähre als Straßenverbindung über Wasser (S9), Kahn/Raddampfer danach; Seenplatte und Seenreich ab Fähre wählbar | kleiner Schritt mit spürbarer Wirkung |
| C Schiffe sofort | Kähne und Raddampfer mit Anlegern in S9 | eigene Kette, Ökonomie neu messen |

**Empfehlung: B.** **Arbeitsannahme: B.**
