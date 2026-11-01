## Art Direction

*Sophie Martin, Art Director / Technical Artist*

**Befund Prototyp v3:** Bäume sind so groß wie Häuser, die Metropole ist kleiner als zwei Getreidefelder, Industrien sind formlose Platten. Das wirkt wie ein Spielbrett, nicht wie ein Land.

### 1. Karte vs. Diorama: Mischung mit fester Zoom-Regel

**Entscheidung: „Nah = Diorama, fern = Karte“, mit drei festen Zoomstufen und weichen Übergängen.**

| Zoomstufe | Kamerahöhe | Darstellung |
|---|---|---|
| **Nah (Diorama)** | < 150 m | Volle Modelle, animierte Fahrzeuge, Schatten, Rauch, Ladegut auf Wagen sichtbar. Hier wird gebaut und bewundert. |
| **Mittel (Betrieb)** | 150–800 m | Vereinfachte Modelle (LOD1), Netz wird leicht verbreitert und gesättigt. Fahrzeuge sind Impostor bzw. MultiMesh-Quader in Güterfarbe. |
| **Fern (Karte)** | > 800 m | Gelände flach und entsättigt, Städte als Flächen mit Umriss, Industrien als Silhouetten-Icons. Das Netz ist ein dickes, farbiges Liniennetz. Güterflüsse erscheinen als Pfeilbänder. Hier wird diagnostiziert. |

So bedienen wir Bauen (Diorama) und lesbare Komplexität (Karte). UX-Diagnose-Overlays liegen ab „Mittel“ auf der Kartenebene.

**Referenzen:** *Mini Metro* (Fernansicht: Netz als Grafik), *Railway Empire 2* (Bau-Nahansicht), *Cities: Skylines* (Info-Overlays), *Townscaper* (Formsprache und Wärme des Dioramas), *Anno 1800* (sichtbare Warenketten).

### 2. Maßstabsregeln: die Welt muss groß wirken

Grundeinheit: **1 Logikfeld = 10 m.** Alles leitet sich davon ab und ist in einer Referenzszene „Maßstabsband“ festgehalten. Kein Asset geht ohne Abgleich damit in den Build.

| Objekt | Grundfläche | Höhe |
|---|---|---|
| Baum | Krone 0,4–0,6 Feld | 1–2 Felder |
| Wohnhaus | 1×1 bis 1×2 Felder | 0,6–1,2 Felder (Epoche 1), bis 6 Felder (Hochhaus, späte Epochen) |
| Straße | 1 Feld (zweispurig) | – |
| Gleis | 0,5 Feld pro Gleis | – |
| Lkw | 1 Feld lang | – |
| Zug | 8–20 Felder lang | – |
| Fabrik / Verarbeiter | 8×8 bis 15×15 Felder | 2–5 Felder, Schornstein bis 8 |
| Farmfelder | 20×20 bis 40×40 Felder | – |
| Kleinstadt | 30×30 Felder | – |
| Metropole | 100×100 Felder | – |

**Wichtigste Regel:** Industrien sind größer als jedes Haus, aber kleiner als jede Stadt. Bäume stehen in Gruppen und Wäldern, nie als Einzelwürfel im Raster. Die Distanz zwischen Clustern beträgt mindestens 3× den Stadtdurchmesser. Die Kartengröße muss deshalb auf mindestens **1.024×1.024 Felder (≈ 10 km)** wachsen. Das ist an Felix adressiert: Terrain-Chunks plus Instancing sind Voraussetzung.

### 3. Formensprache

**Industrien: eine Silhouette, ein Gut.** Jede Industrie muss als schwarzer Schattenriss auf 64 px erkennbar sein.

- Farm: flache Felder mit Scheune und **Rundsilo**
- Viehweide: Zaunraster und Stall mit **Satteldach**
- Mühle: **Windmühle** (Epoche 1) bzw. hoher **Siloturm** (spätere Epochen)
- Ölfeld: **Pferdekopfpumpen**, Bohrturm als Gitterpyramide
- Raffinerie: **Kugeltanks** und Kolonne mit Fackel
- Forst / Sägewerk: **Rundholzstapel** und lange Halle mit Sheddach
- Mine: **Förderturm** (Doppelrad)
- Stahlwerk: **Hochofen** mit Schrägaufzug und 3 Schornsteinen
- Werkzeugfabrik: **Sägezahndach**
- Kraftwerk: **Kühlturm** (Hyperboloid)
- Lager / Umschlag: **Portalkran** und Hallen mit Rampentoren, also bewusst „Hub-Optik“

**Städte** wachsen sichtbar in Ringen: Kern hoch und dicht, Rand niedrig und mit Gärten. Der Versorgungsgrad zeigt sich im Diorama über Details wie Markisen, Laternen und Dachgärten. Unterversorgte Viertel bekommen keine Ruinen, sie wirken nur grauer.

**Epochen-Look.** Pro Epoche gibt es ein Materialset (Ziegel/Holz → Beton/Stahl → Glas). Gebäude werden nicht ausgetauscht, sie werden **aufgestockt und angebaut**. Das passt zur Regel „Industrien bleiben über Epochen und werden erweitert“. Fahrzeuge aus alten Epochen bleiben fahrbar, verblassen aber leicht und zeigen Patina (Shader-Parameter `age`). So sieht man auf einen Blick, wo modernisiert werden sollte.

### 3b. Fernlesbarkeit von Gut, Kette und Zustand

- **Gut erkennen:** Jede Industrie trägt sichtbares **Lagergut** in Güterfarbe, also Kornhaufen, Holzstapel oder Erzhalden. Die Menge wächst mit dem Lagerbestand, ein voller Hof bedeutet einen Stau beim Abholen. In der Kartenansicht wird das zu einem Icon-Pin: Piktogramm des Ausgangsguts mit Füllring.
- **Kette erkennen:** Alle Gebäude einer Kette teilen einen **Familien-Akzent**. Dächer, Fahnen und Silo-Banderolen tragen die Güterfamilienfarbe (Getreidekette = Ocker, Schwerindustrie = Blaugrau). Fährt man in der Karte über eine Industrie, leuchtet die gesamte Kette auf und Wunschlinien zu den fehlenden Gliedern werden gestrichelt angezeigt.
- **Modernisiert:** Ausbaustufen werden **additiv** ergänzt. Ein neuer Anbau steht im aktuellen Epochenmaterial direkt neben dem alten Ziegelkern, dazu kommen eine weitere Halle, ein zweiter Schornstein oder ein Förderband. In der Karte erhält das Icon 1–3 Ausbaupunkte und einen Epochenrahmen (Bronze, Silber, Gold).
- **Rückläufig:** Die Industrie entsättigt sich, Schornsteine rauchen schwächer, Hallen stehen teilweise leer (dunkle Fenster) und Lagerflächen werden von Unkraut bewachsen. In der Karte zeigt das Icon einen grauen Rand mit Abwärtspfeil, die Info nennt den Grund („Epoche 3: Dampfmühlen −20 %, Modernisierung verfügbar“). Ruinen gibt es nicht: Rückgang ist ein Handlungsangebot und keine Strafe.

### 4. Farbsprache

- **Sättigung gehört dem Spieler.** Gelände, Wald und Wasser liegen bei maximal 35 % Sättigung, mit warmen Grau-Grün- und Ocker-Tönen. Fremde Netze und Konkurrenz-KI bekommen eine gedeckte Eigenfarbe.
- **Spielernetz:** eine wählbare Firmenfarbe als kräftiger Akzent, im Default Signalorange.
- **Güterfarben nach Familien:** Agrar = Gelb/Ocker, Tier/Nahrung = Rot, Holz = Braun, Erz/Stahl = Blaugrau, Öl/Chemie = Violett/Schwarz, Energie = Cyan, Konsum/Endprodukte = Weiß mit farbigem Rand. Endprodukte sind heller als ihre Rohstoffe.
- **Farbsehschwäche:** Farbe ist nie allein Bedeutungsträger. Jedes Gut hat zusätzlich ein **Piktogramm** und ein **Muster** auf Kartenbändern (Streifen, Punkte, Raster). Statusfarben (ok/Engpass/blockiert) kombinieren Form und Farbe: Kreis, Dreieck, Achteck. Es gibt Paletten-Presets für Deuteranopie, Protanopie und Tritanopie. Alle Kartenfarben werden per Simulator geprüft (Daniel nimmt das in die QA-Checkliste auf).
- **Bau-Ghost** (UX-Feedback): Blau = baubar, Gelb mit Schraffur = teuer/außerhalb des Einflusses, Rot mit Kreuz = unmöglich. Der Grund steht immer am Cursor.

### 5. Kamera und Atmosphäre

- **FOV 40° (schmal).** Das reduziert die Spielbrett-Verzerrung und lässt die Welt weiter wirken. Die Neigung verläuft fließend von 30° (nah) bis 70° (Karte).
- **Höhennebel und Luftperspektive:** Ferne wird bläulich und entsättigt. Das ist der billigste Trick gegen „Brett“ und versteckt außerdem LOD-Wechsel.
- **Licht:** Sonne leicht schräg, weiche Schatten nur in Nah, SSAO für die Diorama-Haptik.
- **Tageszeit:** nur als langsamer kosmetischer Zyklus, abschaltbar. Nachts leuchten Städte und Netz, was die Abdeckung gut zeigt. **Kein Wetter im Vertical Slice.** Epochenwechsel bekommen einen Farbton-Shift im Color Grading (Sepia → neutral → kühl).

### 6. Audio-Stimmung

Ruhig und mechanisch-zufrieden: eine Ambient-Schicht aus Wind und Vögeln, die beim Zoomen in Industrie- und Stadtgeräusche überblendet. Klare, kurze UI-Cues: ein „Klick-Rasten“ beim Bauen, eine Registrierkasse bei Lieferungen. Engpässe und blockierte Züge haben einen eigenen, nicht nervenden Warnton mit Richtungsinformation. Die Musik ist epochengebunden instrumentiert (Ragtime-Klavier → Swing → Synth), aber stets zurückhaltend, damit sie stundenlanges Optimieren trägt.

### 7. Minimum für den Vertical Slice

1. Maßstabsband-Szene plus Terrain-Shader (Gras, Fels, Sand, Wasser, Höhennebel)
2. Bäume: 3 Arten × 2 LOD, Wald-Scatter-Tool
3. Häuser: 6 Wohnmodule, 2 Gewerbe, 1 Bahnhof, Epoche 1 (plus Aufstockungs-Teile für Epoche 2)
4. Industrien: 5 Silhouetten (Farm, Mühle, Mine, Stahlwerk, Kraftwerk) plus Lager/Umschlag, jeweils mit LOD und Karten-Icon
5. Straße, Gleis, Brücke, Kreuzung und Weiche als modulare Spline-Meshes, Signal (2 Zustände)
6. Fahrzeuge: 2 Lkw, 1 Lok, 3 Wagentypen (offen, Silo, Tank), 1 Bus, Ladegut-Varianten
7. Güter-Piktogramme (12) plus Musteratlas, Statusformen
8. Karten-Rendermodus (Shader-Umschaltung nach Zoom), Ghost-Material
9. Audio: 1 Ambient-Loop, 10 UI-/Feedback-Sounds, 1 Musikstück

Machbar in ca. 3 Monaten mit 1 Artist plus mir (Low-Poly, Flat-Shading, ein Farbatlas statt eigener Texturen).
