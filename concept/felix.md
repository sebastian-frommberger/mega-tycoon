## Technisches Konzept

*Felix Novak, Technical Lead*

### Ausgangslage aus dem Prototyp
Der Prototyp (v3) taugt als Spielidee, nicht als Technikbasis: Jedes Fahrzeug ist ein `Node3D` mit eigenen Meshes und Materialien, die Sim läuft frameabhängig in `_process(delta)`, das Netz ist ein Bool-Gitter in `AStarGrid2D`, jedes Fahrzeug hält eine eigene Pfadkopie. Mein Benchmark (`scratch_tech/bench/`) zeigt lineares Wachstum der Kosten mit der Node-Anzahl und einen spürbaren Einbruch, wenn alle Fahrzeuge neu pfaden. `bug.gd` belegt Zugpfade durch die Metropole ohne ein einziges Gleis. Wir übernehmen die Spielregeln und schreiben die Technik neu.

### Engine-Entscheidung
**Godot 4.x (Ziel: aktuelle stabile 4.4+), GDScript für Spiellogik, UI und Werkzeuge; die Kernsimulation in C++ als GDExtension (godot-cpp).**

| Option | Pro | Contra | Entscheidung |
|---|---|---|---|
| GDScript | schnell iterierbar, ganzes Team kann es | interpretiert, langsam bei 10.000er-Schleifen | UI, Gameplay-Regeln, Tools |
| C# | deutlich schneller, gute IDE | separater Export-Build, GC-Spitzen, nicht alle Plattformen (zu prüfen) | nein |
| GDExtension C++ | maximale Leistung, Datenlayout (SoA) kontrollierbar, deterministische Ganzzahl-Arithmetik | Build-Pipeline, ABI-Bindung an Engine-Version | Sim-Kern |

Im Vertical Slice beginnen wir die Sim in GDScript hinter einer schmalen Schnittstelle (`SimWorld.tick()`, Befehlsqueue, Snapshot-Abfrage). Den Kern portieren wir erst, wenn der Benchmark das Budget reißt.

### Architektur
- **Simulation als reine Daten**: keine Nodes in der Sim. Fahrzeuge, Züge, Lager und Industrien liegen als Arrays/Structs vor (Struct-of-Arrays) und werden über IDs angesprochen.
- **Fester Tick: 10 Hz** (100 ms), entkoppelt vom Framerate. Ökonomie (Produktion, Nachfrage, Stadtwachstum) läuft langsamer, alle 10 Ticks (1 Hz).
- **Trennung Sim/Rendering**: Das Rendering liest pro Frame einen Snapshot (Position auf der Kante plus Fortschritt) und interpoliert zwischen den letzten beiden Ticks (`alpha = akkumulierte Zeit / Tick-Dauer`).
- **Schnellvorlauf**: 1×/2×/4×/8× bedeutet mehr Ticks pro Frame, mit Obergrenze pro Frame (Tick-Budget). Bei Überlast verlangsamt sich die Spielzeit, statt dass die Frames einbrechen.
- **Determinismus**: Ganzzahl- bzw. Festkomma-Arithmetik in der Sim (Geld in Cent, Position in mm entlang der Kante), ein eigener seedbarer PRNG, feste Iterationsreihenfolge (keine Dictionary-Iteration in der Sim) und alle Spielereingaben als Befehle mit Tick-Nummer. Das liefert Speichern als Befehlslog, Replays, reproduzierbare Bug-Reports für QA und lässt Lockstep-Multiplayer offen. Pro Tick berechnen wir eine Prüfsumme über den Sim-Zustand (Desync-Erkennung im CI).

### Netzmodell
- **Graph aus Knoten und Kanten**. Kanten sind Polylines, die aus Splines gesampelt werden (Bézier oder Klothoiden-Näherung) und Länge, Steigung, Höchstgeschwindigkeit und Typ (Straße/Schiene/Wasser) tragen. Knoten sind Weichen, Kreuzungen, Haltestellen, Lager und Industrie-Anschlüsse. Das Bauraster dient nur noch als Snap- und Hilfsebene für Gebäude und Terrain.
- **Blöcke und Signale**: Signale teilen Kanten in Blöcke. Züge **reservieren Pfadabschnitte** bis zum nächsten freien Haltepunkt (Pfadsignal-Logik wie in OpenTTD). Jede Reservierung kennt ihren Halter, daraus entsteht direkt die Diagnose für UX: „Zug 12 wartet an Signal S4, Block B7 reserviert von Zug 9 (Gegenrichtung)“. Das ist unser USP und wird technisch zuerst gebaut.
- **Pfadsuche**: A* auf dem Kantengraphen (Heuristik: Luftlinie/Höchstgeschwindigkeit). **Route-Caching pro Linie**: Fahrzeuge einer Linie teilen sich eine Route (Kanten-ID-Liste). Eine Netzänderung invalidiert nur die Linien, deren Routen betroffene Kanten enthalten; die Neuberechnung wird über mehrere Ticks verteilt. Ob Godots `AStar3D` dafür reicht oder wir A* selbst schreiben, ist zu prüfen. Ich tendiere zu einer eigenen Implementierung im Sim-Kern, wegen Determinismus und dynamischer Kosten wie Blockbelegung.

### Bau-Tool
- **Vertical Slice: 45°-Raster mit Kurven-Glättung** (Kurvenradius-Stufen, Snap an Knoten). Das ist schnell robust, die Gleisgeometrie bleibt validierbar, und es reicht, um Signale und Lager zu testen.
- **Release: freie Kurven** im Stil von Railway Empire (Ziehen mit Mindestradius, Live-Kostenvorschau, Steigungsanzeige in Farbe), der 45°-Modus bleibt als Option. Weil das Datenmodell von Anfang an Spline-Kanten nutzt, ist der Wechsel ein reines Tool-Thema und kein Umbau.
- **Steigungen** als Kantenattribut mit Grenzwert je Typ (Schiene ca. 3–4 %, Straße ca. 10 %), die Zugleistung wirkt über die Steigung auf die Geschwindigkeit. **Brücken und Tunnel** werden automatisch vorgeschlagen, wenn die Höhendifferenz zum Terrain eine Schwelle überschreitet; der Spieler kann das überschreiben. **Terrain-Anpassung**: Damm und Einschnitt entlang der Kante (Heightmap lokal deformieren). Ob wir ein eigenes Heightmap-Terrain bauen oder das Plugin Terrain3D nutzen, ist zu prüfen.
- Pflicht laut Prototyp-Feedback: **Abriss und Rückbau** (gegen Soft-Lock) sowie Undo der letzten Bauaktion.

### Rendering
- **Fahrzeuge über `MultiMeshInstance3D`**: ein MultiMesh pro Fahrzeugmodell und LOD-Stufe, Transforms pro Frame aus dem Snapshot, Ladegut-Farbe über Instanzfarbe (`use_colors`). Lange Züge ergeben ein Instanz-Element pro Wagen.
- **Strecken-Meshes** werden pro Chunk (z. B. 256×256 m) per `SurfaceTool`/`ArrayMesh` zu einem Mesh zusammengefasst und bei Änderungen nur im betroffenen Chunk neu gebaut.
- **LOD**: Mesh-LOD und Sichtbarkeitsdistanz (`visibility_range_*`). Im Fernzoom werden Fahrzeuge zu Punkten bzw. Linienfarben auf der Karte (Kartenmodus statt Diorama, Abstimmung mit Sophie).
- **Label-LOD**: Labels nur für die Top-N nach Wichtigkeit und Bildschirmnähe, Update mit 2–4 Hz statt pro Frame, gepoolt.

### Performance-Budget
- **Zielhardware**: GTX 1660 / RX 5600, 6-Kern-CPU, 16 GB RAM, 1080p60. Steam-Deck-Tauglichkeit ist zu prüfen.
- **Ziel**: 10.000 Fahrzeuge, Sim ≤ 4 ms pro Tick (bei 1×), Render-Update der Fahrzeuge ≤ 2 ms, gesamtes Frame ≤ 16,6 ms. Bei 8× darf die Sim maximal 8 ms pro Frame belegen, danach greift das Tick-Budget.
- **Messkonzept**: headless Benchmark-Szenen (fixe Seeds: 1.000/5.000/10.000 Fahrzeuge, Netzänderung mit Repath-Welle, Late-Game-Spielstand) laufen bei jedem Merge in CI. Gemessen werden Median und p95 pro Tick, die Ergebnisse gehen in eine Zeitreihe, und bei mehr als 10 % Regression schlägt der Build rot an. Ergänzend gibt es ein In-Game-Overlay mit Sim-ms, Render-ms und Draw Calls.

### Speichern, Modding, Plattform
- **Speichern**: versioniertes Binärformat (Sim-Snapshot plus Befehlslog seit dem Snapshot), komprimiert, mit Migrationsfunktion pro Version. Autosave im Hintergrund aus dem Snapshot.
- **Modding**: Spieldaten (Güter, Ketten, Fahrzeuge, Epochen, Skilltree-Knoten) in JSON mit Schema-Validierung. Modelle als glTF. Mods sind Datenpakete, die gemerged werden; Script-Mods kommen frühestens nach dem Release.
- **Plattform**: PC/Steam zuerst (Windows, Linux nativ, Steam Deck als Bonus); Steam Workshop für Datenmods.

### Technische Risiken (Top 4)
| Risiko | Gegenmaßnahme |
|---|---|
| Signal-/Reservierungslogik erzeugt Deadlocks oder ist unverständlich | als Erstes bauen; Deadlock-Erkennung (Zyklus in der Wartegraph-Kette) mit UI-Hinweis; automatisierte Szenariotests |
| Freies Kurven-Tool frisst Zeit und fühlt sich trotzdem schlecht an | Vertical Slice im 45°-Raster; Spline-Datenmodell von Tag 1; früher Playtest gegen Railway Empire als Referenz |
| Performance-Ziel von 10.000 Fahrzeugen verfehlt | SoA-Daten, Route-Caching, MultiMesh; Benchmarks im CI ab Woche 2; GDExtension-Port als vorbereiteter Plan B |
| Determinismus bricht (Floats, Iterationsreihenfolge) | Festkomma in der Sim, Prüfsumme pro Tick, Replay-Vergleichstest im CI |
