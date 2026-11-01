# Testbarkeit Prototyp v3 (`/tmp/claude-0/gd/proto`) und Soll für den Spike-Build

Daniel Richter, QA · Prüfung mit Godot 4.4.1 stable (`/tmp/claude-0/gd/Godot_v4.4.1-stable_linux.x86_64`) auf einer **Kopie** des Prototyps (Original unverändert). Prüfumgebung: 2 vCPU, 7 GB RAM, keine GPU. Zeiten sind deshalb nur Größenordnungen, keine Benchmarkwerte.

## 1. Was ich getan und gesehen habe

| Prüfung | Vorgehen | Befund |
|---|---|---|
| Import in 4.4.1 | `--headless --import` auf der Kopie | läuft durch, ca. 14 s beim ersten Mal, keine Fehlermeldung in der Ausgabe. `project.godot` führt `4.2` als Feature, README sagt „4.2 oder neuer“ |
| Headless-Start | `--headless --path . --quit-after 120` | Hauptszene startet, Exit-Code 0, keine Warnungen. Das Ende kommt von `--quit-after`, nicht vom Prototyp |
| Skriptgesteuerter Lauf | eigenes `SceneTree`-Skript (`--script`) lädt `main.tscn`, kauft 2 Firmen, baut ein Gleisstück, legt eine Lkw-Linie an, läuft 600 Frames | Ladezeit 94 bis 140 ms in der Prüfumgebung. Aufbau läuft nur über **interne** Funktionen (`_buy`, `_build_track`, `_create_line`) |
| Reproduzierbarkeit | mein Digest (MD5 über Geld ×100, Fahrzeugpositionen in mm, Ladung, Lagerbestände) bei Frame 10, 300, 600, zweimal gelaufen | **mit `--fixed-fps 60`: alle drei Werte in beiden Läufen identisch.** **Ohne `--fixed-fps`: alle drei Werte weichen zwischen den Läufen ab** (Frame-Delta schwankt zwischen 0,0067 und 0,0071 s) |

Einschränkung: Die Reproduzierbarkeit gilt für **ein Fahrzeug, 600 Frames, einen Pfad**. Es war keine Zufallslogik im Spiel beteiligt (keine Fahrzeugkollision, keine Signale). Der Digest ist mein Werkzeug, keine Prüfsumme des Spiels, und er rundet Gleitkommawerte. Ich behaupte nur: „unter festem Frame-Delta bei diesem Szenario deterministisch“.

## 2. Die vier Kernfragen

| Frage | Antwort | Beleg |
|---|---|---|
| **Headless Start** | Ja, mit Einschränkung. Die Szene startet ohne Anzeige. Es gibt **keinen** sauberen Szenario-Start (keine Kommandozeilenargumente, kein Szenarioname, kein Seed) und **keinen** definierten Ausstieg mit Exit-Code | `main.gd` enthält kein `quit()`, keine Auswertung von Kommandozeilenargumenten, kein `print`/`assert`/`push_error` |
| **Zustandsabfrage per ID** | Nein. Gebäude und Fahrzeuge sind `Node3D`-Objekte ohne ID. Zugriff nur über `cell_to_building[Vector2i]` und die Position im Array `vehicles` | `building.gd`/`truck.gd` haben kein `id`-Feld; keine Abfragefunktion in `main.gd` |
| **Prüfsumme** | Nein. Es gibt weder Tick noch Prüfsumme noch Hash über Zustand | `hash(` kommt nur als Seed für Stadtgrundrisse vor (`main.gd:431`) |
| **Wiederholbarkeit** | Nur mit Zwang von außen (`--fixed-fps`). Die Sim läuft in `_process(delta)` jedes Knotens, Geld wird als Gleitkommazahl pro Frame abgezogen (`money -= v.upkeep * delta`) | `main.gd:1006` ff., `truck.gd` `_process` |

## 3. Konkrete Lücken (nach Wirkung auf unsere Tests geordnet)

| # | Lücke | Wirkung | Wer/Wann |
|---|---|---|---|
| L1 | **Keine Signale, Blöcke, Reservierungen, kein Warten auf andere Fahrzeuge.** Der Lkw-Zustand kennt nur Laden, Fahrt hin, Entladen, Fahrt zurück; es gibt kein Blockieren zwischen Fahrzeugen | D-04 und L-06 sind am Prototyp **nicht ausführbar**. Dafür ist F-04 da. Der Prototyp taugt nur als Probe für den Prüfaufbau | Felix, F-04 |
| L2 | **Kein fester Tick.** Alles frameabhängig (`delta`) | „Erkennung in ≤ 50 Ticks“ ist nicht messbar, Läufe sind ohne Zwang nicht wiederholbar | Felix, F-04 (Konzept sieht 10 Hz vor) |
| L3 | **Keine ID-Abfrage und kein Snapshot.** Prüfungen laufen über interne Objektreferenzen | `Tick_Eintritt` (D-04) ist nicht unabhängig bestimmbar; Zustandsdump je Tick nötig | Felix |
| L4 | **Keine Prüfsumme je Tick.** Determinismus und Replay-Treue sind nicht beweisbar | Gültigkeit der F-05-Läufe und Reproduktion von Fehlschlägen (Replay-Pflicht) nur schwach belegbar | Felix |
| L5 | **Kein Szenario- und Seed-Eingang.** Karte, Wälder, Städte kommen aus festen Konstanten (Seeds 1947, 42, 7, `hash(Stadtname)`); es gibt keinen Parameter | D-04 „× 3 Seeds“ braucht einen Seed-Eingang. Im Prototyp variiert nichts | Felix |
| L6 | **Kein Befehlslog, kein Replay.** Eingaben laufen direkt aus Mausereignissen (`_unhandled_input`, `_click`) in den Zustand | Replay-Pflicht bei Fehlschlag nicht erfüllbar; F-06 soll Session-Replay liefern (24.11.), F-04 nicht | Felix |
| L7 | **Kein Ereignis- oder Diagnoseprotokoll.** Der Prototyp schreibt nichts außer UI-Text und Toasts | „Deadlock erkannt“ muss als maschinenlesbares Ereignis mit Tick und IDs erscheinen, sonst muss ich Bildschirm lesen | Felix |
| L8 | **Sim, UI, Kamera und Rendering in einer Datei** (`main.gd`, 1.075 Zeilen; jedes Gebäude und jedes Fahrzeug eigene Nodes, eigene Meshes, eigenes `_process`) | Keine schmale Schnittstelle (`SimWorld.tick()`, Befehlsqueue, Snapshot), also kein Benchmark des Sim-Kerns möglich; F-05 braucht Felix' Neubau | Felix (so im Konzept vorgesehen) |
| L9 | **Geld als Gleitkommazahl, Float-Summen über Frames.** | Konzept sieht Festkomma (Cent) vor; Abweichungen zwischen Läufen verfälschen Gleichheitsprüfungen | Felix/Tobias (F-09-Konvention) |
| L10 | **Testreste im Projektordner** (`_test.gd`, `_shot.gd`, `_shot2.gd` neben dem Spiel) | kein Spielfehler, aber Verwechslungsgefahr zwischen Test- und Spiel-Skripten; der Spike-Build sollte Testcode trennen | Felix |

## 4. Soll für den Spike-Build (Eingangsprüfung 19.11.)

Das sind meine **Wünsche an Felix**, nicht das Akzeptanzkriterium von F-04 (dort stehen nur Exit 0, ≤ 50 Ticks, `get_wait_chain` mit Typ und Koordinaten, A-05-Felder). Je Punkt steht, wofür ich ihn brauche.

| # | Soll | Brauche ich für |
|---|---|---|
| S1 | Aufruf `godot --headless -- --scenario=<name> --seed=<n> [--ticks=<n>]`, Exit 0 bei Erfolg, ≠ 0 bei Fehler/Absturz | D-04, F-04-Exit-Code, CI später |
| S2 | Fester Tick 10 Hz, Tick-Nummer abfragbar, unabhängig von Framerate | Ticks bis Erkennung |
| S3 | Zustandsabfrage per ID: Fahrzeug (Position, Zustand, wartet auf), Block (Halter), Signal | `Tick_Eintritt` unabhängig bestimmen, Kette prüfen |
| S4 | Ereignisprotokoll als Zeilen (Tick, Typ, IDs, Wurzelursache-Typ, Koordinaten) | Erkennung, Fehlalarmzählung |
| S5 | Prüfsumme des Sim-Zustands je Tick oder mindestens am Ende | Determinismus, Gültigkeit F-05-Läufe, Replay |
| S6 | Szenario ohne Quelltext-Eingriff beschreibbar (Datei/Befehle) plus Seed-Eingang | meine 3 Szenarien, Normalbetrieb |
| S7 | Replay: Seed + Befehlslog, zweimal abspielen = gleiche Prüfsumme | Replay-Pflicht D-04, L-06-Reproduktion |
| S8 | Normalbetrieb-Szenario mit absichtlich langen, harmlosen Wartezeiten | Fehlalarm-Test |
| S9 | Klick auf Meldung als Ereignis im Replay (nur F-06) | Stoppuhr-Startpunkt L-06 |

Priorität, wenn Felix knapp ist: S2, S4, S1 (ohne die ist „≤ 50 Ticks“ nicht messbar), dann S5/S7, dann S3.

## 5. Wiederverwendbar aus dem Prototyp

- Der Prüfaufbau (Szenario per Skript aufbauen, mit festem Delta laufen lassen, Digest vergleichen) funktioniert und ist in 10 Zeilen übertragbar. Das Prüfskript liegt als `proto_probe.gd` neben diesem Dokument (Aufruf auf einer Kopie des Prototyps: `godot --headless --path <kopie> --fixed-fps 60 --script proto_probe.gd`).
- Die Regressionsszenarien aus `scratch_qa/` (Lager-Pingpong, Geldsenke, Linien-Spam, Zug ohne Gleis, Soft-Lock) sind Ökonomietests und nach S3 verschoben (T-06/T-07). Hier nicht Gegenstand.

## 6. Nachtrag: Testbarkeit des Spike-Codes von Felix (`felix/spike/`, Stand 18.11.)

Aus Lesen und Ausführen (Kopie, Godot 4.4.1). Abgleich mit Abschnitt 3: Lücken L2, L3, L8 sind im Spike weitgehend geschlossen, die übrigen nicht.

| Frage | Stand im Spike | Beleg |
|---|---|---|
| Headless starten, Exit-Code | **ja**, aber nur der feste Test-Runner (`--script res://test_runner.gd`, `quit(0/1)`). Kein Aufruf mit Szenario-Name oder Seed | 2 Läufe, Exit 0, Ausgabe identisch zu Felix' `test_output.txt` |
| Fester Tick | **ja:** `SimWorld.step()` vom Aufrufer getaktet, `tick_count`, Ganzzahl-Arithmetik (mm) | `sim_world.gd` |
| Zustand per ID | **ja, im Speicher:** `sim.vehicles[id]`, `sim.graph.blocks[id]`. Keine Abfrage-API | mein Orakel nutzt nur das |
| Prüfsumme | **nein** | keine Funktion, kein Hash |
| Seed / Zufall | **nein**, die Sim hat keinen PRNG (Felix bestätigt) | `felix.md` |
| Replay / Befehlslog | **nein.** Ein Szenario ist eine deterministische Aufbaufunktion; zweiter Lauf identisch (Felix' Runner, mein Harness) | Determinismus ja, Replay-Datei nein |
| Ereignisprotokoll | **Pull:** `deadlock_events` im Speicher, kein Log, kein Push | `sim_world.gd` |
| Szenario von außen beschreibbar | **nein**, nur per GDScript-API | `scenarios.gd` |
| Netz-Umfang | gerade Kanten, ein Block Vorausreservierung, Signale automatisch je Kante, keine Zuglänge, keine Weichen als eigenes Objekt | Felix' Grenzen, mein Befund B5 |

Prototyp v3 ist damit für Deadlock-/Diagnosetests nur noch als Referenz für Spielregeln relevant, nicht als Testobjekt. Die Details der Vorabprüfung stehen in `d04_prueffplan.md`, Abschnitt 9.

