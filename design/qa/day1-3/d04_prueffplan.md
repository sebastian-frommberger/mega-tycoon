# D-04 Prüfplan: Deadlock-Prüfung des Signal-Spikes

Daniel Richter, QA · Stand Tag 3 (18.11.2026) · Ausführung ab 19.11. (Spike-Build von Felix), fertig 23.11.
Status: **Plan fertig, D-04-Ausführung nicht begonnen** (offizielle Übergabe ist am 19.11.; Felix' `felix.md` nennt sie „offen, Restaufwand ca. 0,5 T“). Die Ergebnisspalten in Abschnitt 4 sind leer. Felix' Code liegt in `felix/spike/`, ich habe ihn gelesen und **vorab** geprüft (Abschnitt 9). Diese Vorabprüfung zählt nicht als D-04-Messwert: die Übergabe fehlt, zwei der drei D-04-Szenarien sind in diesem Build nicht darstellbar, und sie lief auf einem Rechner ohne Gate-Bedeutung (Ticks sind allerdings hardwareunabhängig).

## 1. Was geprüft wird und was zählt

Quelle: Refinement-Beschluss (D-04), Jonas' Gate-Kriterien G3 und G4 (`jonas/gate_kriterien.md`), Pfeiler-Frage 5.

| Größe | Definition | Schwelle |
|---|---|---|
| Szenario | 3 manuelle Szenarien (unten) + 3 automatisierte aus F-04 = 6 | ≥ 5 von 6 „erkannt“ (G3 Grün) |
| „Szenario erkannt“ | **alle 3 Seeds** erkannt, ≤ 50 Ticks, Wurzelursache korrekt (Typ + Objekt + Ort, siehe 4) | Daniels Auslegung, siehe Annahme A1 |
| Erkennungszeit | `Tick_erkannt − Tick_Eintritt` in Ticks (10 Hz, 50 Ticks = 5,0 s Spielzeit) | ≤ 50 |
| Fehlalarm | Deadlock- oder Kritisch-Meldung ohne objektiven Wartekreis in 10 min Normalbetrieb | 0 (G3: 1 mit bekannter Ursache = Gelb) |
| Wurzelursache korrekt | 9 Läufe (3 Szenarien × 3 Seeds): Typ, Objekt-ID und Ort stimmen | 9/9 Grün, 7–8 Gelb (G4) |

Gezählt wird nur am echten Spike-Build (Jonas' Messwert-Regel). Die F-04-Automatik (Exit 0) ist nur Voraussetzung. Als Messwert für „≤ 50 Ticks“ zählt dieser Plan.

## 2. Die drei manuellen Szenarien

**Wichtig vorab (Befund aus der Vorabprüfung, Abschnitt 9):** In Felix' Spike lassen sich D4-S2 (Weiche ohne Signal) und D4-S3 (Ausweichgleis zu kurz) **nicht bauen**. Jede Kante bekommt automatisch Signale, ein „fehlendes Signal“ gibt es im Modell nicht, und Züge haben keine Länge, also kann ein Gleis nicht „zu kurz“ sein. Nur D4-S1 ist darstellbar, und das ist dasselbe wie Felix' S2 „Deadlock-Kreis“. Die Tabelle unten ist der Soll-Plan des Beschlusses. Wie es weitergeht, ist offen (Abschnitt 8, Frage Q1).

Topologie fix, der Seed variiert nur Startzeiten (A2). Erwartete Wurzelursachen sind **Annahmen**. Felix liefert Codes (`DEADLOCK`, `EINGLEISIG_GEGENVERKEHR`, `WARTEN_AUF_LADUNG`), Aylin plant andere (`KREIS_BLOCKIERUNG`, `ZULIEFERUNG_ZU_GERING`) und einen Typ `INFRASTRUKTUR`/`LADUNG`, den Felix' API nicht liefert (Felix: „nicht unterschieden: Geld, Nachfrage, fehlende Infrastruktur“). Der Abgleich der beiden ist offen. Weil alle drei D-04-Szenarien „Infrastruktur“ wären, reicht der Typ allein nicht. Es zählt Code plus Objekt plus Ort.

| ID | Szenario | Aufbau (Schiene, Wegwerf-Testkarte) | Erwartetes Verhalten | Erwartete Wurzelursache (Annahme) | Playtest-Fehler? |
|---|---|---|---|---|---|
| D4-S1 | Kreisverkehr voll | Gleisring mit 4 Blöcken, 2 Ein-/Ausfädelweichen, so viele Züge wie Blöcke. Jeder Zug wartet auf den Block seines Vorgängers. | Wartekreis über alle Ringzüge, Meldung „Deadlock“, Kette nennt alle Ringglieder | Infrastruktur / Kreis-Deadlock, Objekt: Ring (Block-IDs), Ort: Ringmitte ± 2 Felder | offen (A3) |
| D4-S2 | Weiche ohne Signal | Zwei Zweiggleise münden in eine Weiche, Signal an der Weiche fehlt, zwei Züge nähern sich gleichzeitig. | System erkennt die ungesicherte Weiche **bevor** oder **wenn** beide Züge sich blockieren; Ursache „Signal fehlt“ | Infrastruktur / Signal fehlt, Objekt: Weichenknoten-ID, Ort: Weiche ± 2 Felder | offen (A3) |
| D4-S3 | Ausweichgleis zu kurz | Eingleisige Strecke, Ausweichgleis kürzer als der Zug (z. B. Zug 4 Wagen, Gleis 3), Gegenverkehr. | Beide Züge stehen sich gegenüber, Erkennung als Deadlock, Ursache „Ausweichgleis zu kurz“ | Infrastruktur / Ausweichgleis zu kurz, Objekt: Ausweichgleis-ID, Ort: Gleismitte ± 2 Felder | offen (A3) |

Abgrenzung zu F-04 (Felix automatisiert): Gegenverkehr eingleisig, Deadlock-Kreis, Warten auf Ladung. D4-S1 darf kein Duplikat des „Deadlock-Kreis“ sein. Unterschied: bei D4-S1 entsteht der Kreis durch **volle Auslastung** eines Rings, nicht durch eine gekreuzte Zweier-Konstellation (A4).

**Seeds** (A2): 101, 202, 303, vor dem ersten Lauf festgelegt und nicht nachträglich getauscht. Der Seed bestimmt Abfahrt-Offset je Zug (0 bis 20 Ticks) und Zugreihenfolge am Startpunkt. Ein Seed, der kein Problem auslöst (kein Deadlock tritt ein), ist selbst ein Befund: Pfeiler 5 verlangt, dass der Fehler ohne Zufallselement aus dem Netzzustand entsteht. Dann steht „Fehler nicht seedunabhängig“ im Protokoll.

## 3. Ablauf je Lauf

**Eingangsprüfung des Builds (30 min, am 19.11., vor dem ersten Lauf).** Fällt ein Punkt durch, ist das ein Blocker an Felix, kein D-04-Fehlschlag. Die Spalte „Stand 18.11.“ zeigt, was ich am Code in `felix/spike/` schon gesehen habe.

| # | Prüfpunkt | Beleg | Stand 18.11. (Code-Stand, Vorabprüfung) |
|---|---|---|---|
| E1 | Headless-Start, Exit-Code 0 bei Erfolg, ≠ 0 bei Fehler | Konsolenausgabe | **teilweise:** `test_runner.gd` beendet mit `quit(0/1)`, ich habe 2 Läufe selbst gemacht (beide Exit 0, 70 ms). Szenarien sind fest eingebaut, **kein** Aufruf mit Szenario-Name/Seed |
| E2 | Tick-Nummer auslesbar, fest 10 Hz | Gleiche Tick-Nummer bei gleichem Ereignis | **ja:** `sim.tick_count`, `SimWorld.step()` wird vom Aufrufer getaktet, keine Framezeit in der Sim |
| E3 | Ereignis „Deadlock erkannt“ mit Tick, IDs, Ursache, Koordinaten | Ereignisliste | **teilweise:** `sim.deadlock_events` (Pull, im Speicher), kein Ereignis-Log und kein Push |
| E4 | `get_wait_chain(vehicle_id)` mit Kette und Koordinaten | Aufruf-Ausgabe | **ja** (siehe Abschnitt 9, Befunde B1 bis B3) |
| E5 | Gleiches Szenario zweimal: identische Ereignisse | Diff | **ja:** Felix' Runner und mein Harness (je 2 Läufe, 3 Offset-Varianten) liefern identische Ereignisse |
| E6 | Szenarioaufbau ohne Eingriff in Felix' Quelltext | Szenario als Datei/Befehle | **teilweise:** Aufbau per GDScript-API (`add_node`, `add_edge`, `add_vehicle`), ich kann Szenarien in einem eigenen Skript bauen (`d04_vorabpruefung.gd`), aber nicht per Datei/CLI |
| E7 | Zustand je ID abfragbar (Fahrzeug, Block, Halter) | unabhängiges Orakel für `Tick_Eintritt` | **ja, nur im Speicher:** `sim.vehicles[id]`, `sim.graph.blocks[id]` als Dictionaries. Keine API, keine Prüfsumme |
| E8 | Seed-Eingang oder PRNG | Szenarien mit Seeds | **nein:** die Sim hat keinen PRNG (Felix bestätigt in `felix.md`). Mein „Seed“ ist ein Zufallszahlengenerator im Prüfskript für Start-Offsets |

Siehe auch `testbarkeit_proto.md`. Fehlt E2 oder E5, wäre die Erkennungszeit in Ticks nicht belastbar messbar. Beides ist erfüllt.

**Lauf (je Szenario × Seed, 9 Läufe):**
1. Build-ID, Seed, Szenario eintragen.
2. Lauf starten, bis Erkennung oder Tick `Tick_Eintritt + 200` (Abbruch „nicht erkannt“).
3. `Tick_Eintritt` bestimmen aus der **unabhängigen Referenz**: erster Tick, ab dem der Wartekreis bzw. der Stillstand objektiv besteht (alle beteiligten Fahrzeuge stehen und warten ausschließlich aufeinander). Ermittlung aus dem Zustand der Fahrzeuge je Tick, nicht aus der Meldung des Systems. Dafür gibt es mein Orakel in `d04_vorabpruefung.gd` (`stuck_set`: größter Fixpunkt der wartenden Fahrzeuge, eigene Implementierung, nutzt `find_wait_cycles` der Sim nicht). Es braucht nur `sim.vehicles` und `sim.graph.blocks`, also den In-Process-Zugriff (E7).
4. `get_wait_chain()` für ein beteiligtes Fahrzeug aufrufen, Ergebnis wörtlich ins Protokoll.
5. Vergleich mit Erwartung (Abschnitt 2): Typ, Objekt-ID, Ort (Toleranz ± 2 Felder, A5), Kettenglieder vollständig?
6. Ergebnis eintragen, Log-Datei und Replay (siehe 6) ablegen.

## 4. Protokollvorlage (eine Zeile je Lauf)

| Lauf | Szenario | Seed | Build-ID | Tick_Eintritt | Tick_erkannt | Δ Ticks | erkannt ≤ 50 | Typ ok | Objekt ok | Ort ok (≤ 2 Felder) | Kette vollständig | Fehlschlag-Art | Replay-Datei | Tracker-ID | Bemerkung |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | D4-S1 | 101 | | | | | | | | | | | | | |
| 2 | D4-S1 | 202 | | | | | | | | | | | | | |
| 3 | D4-S1 | 303 | | | | | | | | | | | | | |
| 4 | D4-S2 | 101 | | | | | | | | | | | | | |
| 5 | D4-S2 | 202 | | | | | | | | | | | | | |
| 6 | D4-S2 | 303 | | | | | | | | | | | | | |
| 7 | D4-S3 | 101 | | | | | | | | | | | | | |
| 8 | D4-S3 | 202 | | | | | | | | | | | | | |
| 9 | D4-S3 | 303 | | | | | | | | | | | | | |

Fehlschlag-Art: `nicht erkannt` · `zu spät (> 50)` · `Typ falsch` · `Objekt/Ort falsch` · `Kette unvollständig` · `Absturz` · `nicht reproduzierbar` · `Fehler trat nicht ein`.
Zusatzspalte für Felix' eigenes Ziel (≤ 10 Ticks laut refinement/felix.md): `erkannt ≤ 10`. Sie zählt nicht fürs Gate, nur zur Information.

Gesamtauswertung (erst nach allen Läufen auszufüllen):

| Kennzahl | Wert | Gate (Jonas G3/G4) |
|---|---|---|
| Manuelle Szenarien erkannt (3/3 Seeds) | _ von 3 | |
| F-04-Szenarien erkannt (aus Felix' Testausgabe, nur mit Tick-Werten) | _ von 3 | |
| Summe | _ von 6 | ≥ 5 Grün · 4 Gelb · ≤ 3 Rot |
| Wurzelursache korrekt (Läufe) | _ von 9 | 9 Grün · 7–8 Gelb · ≤ 6 Rot |
| Fehlalarme (Abschnitt 5) | _ | 0 Grün · 1 mit bekannter Ursache Gelb · ≥ 2 Rot |

## 5. Fehlalarm-Test: 10 min Normalbetrieb

- **Dauer:** 10 Minuten **Spielzeit** = 6.000 Ticks bei 10 Hz, nicht Wanduhr (headless darf schneller laufen). Je Seed ein Lauf (101, 202, 303), also 3 × 6.000 Ticks. Ticket verlangt 10 min; die drei Seeds sind mein Zusatz, um nicht auf einem Zufallslauf „0“ zu behaupten.
- **Normalnetz (Annahme A6):** zweigleisige Hauptstrecke plus eine eingleisige Zweigstrecke mit **korrekt langem** Ausweichgleis, alle Weichen signalisiert, 6 Züge, ein Lager mit Ladezeit. Das Netz muss echte, harmlose Wartezeiten erzeugen, sonst testet es nichts.
- **Provokation:** mindestens ein Zug wartet zwischenzeitlich länger als 50 Ticks (Ladezeit, Gegenzug im Ausweichgleis) und löst sich von selbst. Das System darf das als Wartezeit oder Ladung melden, **nicht** als Deadlock.
- **Zählregel:** Fehlalarm = jede Meldung vom Typ Deadlock oder Kritisch-Netzstillstand, während kein Wartekreis besteht. Eine Meldung „wartet auf Ladung“ ist kein Fehlalarm. Zweifelsfälle prüfe ich im Zustandsdump: Kreis ja/nein.
- **Zusatzmessung:** Zahl aller Meldungen je Typ, damit „0 Fehlalarme“ nicht daran liegt, dass das System generell schweigt. Sinnprobe: Derselbe Build muss in D4-S1 anschlagen.

## 6. Replay-Pflicht bei Fehlschlag

Jeder Fehlschlag (jede Art aus Abschnitt 4 sowie jeder Fehlalarm) bekommt:
1. **Replay-Datei** (Seed + Befehlslog bzw. Szenariodatei) und **Tick-Nummer** des Fehlers, abgelegt neben dem Protokoll.
2. **Tracker-Eintrag** mit Pflichtfeldern Schweregrad, Build, Seed, Tick, Komponente, erwartet/tatsächlich, Replay-Anhang. Schweregrad-Vorschlag: nicht erkannt / Absturz / nicht reproduzierbar = S1; zu spät, falscher Typ/Ort = S2.
3. **Reproduktionsnachweis:** Replay zweimal abspielen, beide Male gleicher Fehler-Tick. Weicht ein Lauf ab, ist das ein eigener S1-Fehler „Determinismus“ (Prüfsumme je Tick, falls vorhanden).
4. Ein Fehlschlag ohne Replay zählt als **nicht belegt**, nicht als bestanden.

**Lücke:** F-04 fordert weder Replay noch Befehlslog (nur Exit 0, ≤ 50 Ticks, `get_wait_chain`). Replay in der Session-Form kommt erst mit F-06 (24.11.). Mindestersatz für D-04: Szenario-Name + Seed + Build-ID + Tick, wenn der Lauf damit wiederholbar ist (E5). Offene Frage an Felix.

## 7. Zeitplan

| Tag | Inhalt |
|---|---|
| 19.11. | Spike-Build entgegennehmen, Eingangsprüfung E1 bis E6 (0,5 T), Lauf D4-S1 |
| 20.11. | D4-S2, D4-S3 (Felix: F-05 Szene, Fragestunde 14–15 Uhr) |
| 21.11. | Fehlalarm-Test 3 × 6.000 Ticks, erste Fehlschläge an Felix |
| 23.11. | Nachprüfung von Fixes, Gesamtauswertung, Eintrag für K-07 und QA-Bewertung |

Puffer: Daniels 2 T (fängt späten Spike-Build ab). Schrumpft D-04 laut Refinement-Forderung auf weniger Szenarien, wenn der Build nach 19.11. kommt, steht das im Daily, nicht erst im Protokoll.

## 8. Annahmen und offene Fragen

- **A1 (Felix, Katrin):** „Szenario erkannt“ = 3/3 Seeds. Ein Szenario mit 2/3 gilt als nicht erkannt. Die Brief-Schwelle „≥ 5/6“ lässt offen, ob Szenario oder Lauf gemeint ist. Bitte bis 19.11. bestätigen.
- **A2:** Seeds 101/202/303, Seed variiert Startzeit und Reihenfolge, nicht die Topologie.
- **A3 (Lena, Felix):** Welche **2** der 3 D-04-Szenarien sind Playtest-Fehler? Mein Lesart (Annahme): D4-S1 „Kreisverkehr voll“ entspricht Testfehler 2 (Deadlock-Kreis), D4-S3 „Ausweichgleis zu kurz“ entspricht Testfehler 1 (Gegenverkehr eingleisig, Ausweichgleis fehlt bzw. reicht nicht). Die drei Testfehler (Aylin, Felix) sind Gegenverkehr, Deadlock-Kreis, Warten auf Ladung. Jonas' Pfeiler 5 verlangt, dass **alle 3 Testfehler** × 3 Seeds laufen. Das deckt D-04 in dieser Form nur teilweise ab: „Warten auf Ladung“ steht in keinem D-04-Szenario (F-04 testet es automatisiert, aber nur einmal und ohne Seeds). Lenas Fehlerliste liegt nicht vor.
- **A4 (Felix):** D4-S1 als Schienenring: Felix' Spike kennt nur Schiene/Blöcke, ein Ring aus 4 Kanten mit 4 Zügen ist dort bereits sein S2. Der Unterschied „volle Auslastung“ aus meinem Plan ist kein eigener Test mehr. Ich teste stattdessen Ringe von 4 und 6 Zügen und einen Ring mit freiem Block (Abschnitt 9).
- **A5 (Aylin):** Orts-Toleranz ± 2 Felder und „Objekt-ID muss stimmen“ als Kriterium für „Wurzelursache korrekt“. Textvorlagen für die Erwartung fehlen noch.
- **A6:** Aufbau des Normalnetzes ist mein Vorschlag. Felix müsste es per Konfiguration bereitstellen.
- **Auslegung 50 vs. 10 Ticks:** Felix' Refinement nennt ≤ 10 Ticks, der Beschluss ≤ 50. Ich messe gegen 50 und notiere ≤ 10 zusätzlich.
- **Q1 (Felix, Lena, Katrin, Jonas) für den Daily am 19.11.:** Die D-04-Szenarien „Weiche ohne Signal“ und „Ausweichgleis zu kurz“ sind im Spike nicht darstellbar. Optionen: (a) Felix ergänzt Zuglänge und die Möglichkeit, ein Signal wegzulassen (nicht im F-04-Akzeptanzkriterium, Felix hat keinen Puffer), (b) D-04 prüft nur, was darstellbar ist (Ring 4/6, Gegenverkehr, Auffahrer, Normalbetrieb), dann ist „≥ 5 von 6“ aus dem Beschluss **nicht erreichbar** und G3 bleibt laut Jonas offen („fehlt ein Messwert, weder Grün noch Gelb“), (c) die zwei Szenarien kommen mit M1. Ich empfehle (b) für Sprint 2 und (c) für die fehlenden Szenarien, und dass das im Gate steht. Entscheidung gehört nicht mir.
- **Q2 (Felix):** Der Schwellenwert „≤ 50 Ticks“ unterscheidet nichts. Die Erkennung dauert in allen meinen Läufen 4 Ticks, weil `DEADLOCK_CONFIRM_TICKS = 5` ein Parameter ist. Das ist keine Schwäche, aber das Gate-Kriterium G3 prüft damit nicht die Erkennungsgeschwindigkeit, sondern die **Abdeckung** (wird jeder Fall überhaupt erkannt, richtig benannt, am richtigen Ort).

## 9. Vorabprüfung am Spike-Code (Stand 18.11., zählt nicht fürs Gate)

Gelesen: `felix/spike/` (782 Zeilen: `net_graph.gd`, `sim_world.gd`, `diagnostics.gd`, `scenarios.gd`, `test_runner.gd`). Ausgeführt auf einer **Kopie** (Felix' Ordner unverändert), Godot 4.4.1, Rohausgabe liegt in meiner Scratch-Umgebung, der Harness ist `d04_vorabpruefung.gd`.

**1. Felix' Runner unabhängig nachgelaufen:** 2 Läufe, beide Exit 0, 70 ms, alle Prüfungen grün, Ausgabe bis auf die Dauer identisch zu seiner `test_output.txt`. Seine Aussagen „drei Szenarien grün, Erkennung nach 4 Ticks, Kontrolle 10 min ohne Meldung“ sind damit nachvollzogen. Das heißt nur: der Runner prüft, was in ihm steht. Die Erwartungswerte hat Felix von Hand ins Skript geschrieben (er sagt es selbst).

**2. Mein Harness (eigene Szenarien, Start-Offsets 0 bis 20 Ticks aus Seeds 101/202/303, eigenes Orakel für `Tick_Eintritt`):**

| Fall | Läufe | Ergebnis |
|---|---|---|
| A Gegenverkehr eingleisig | 3 Seeds | je 1 Ereignis, Ursache `EINGLEISIG_GEGENVERKEHR` bei beiden Zügen, Erkennung 4 Ticks nach Orakel-Eintritt |
| B Ring, 4 Züge / 4 Blöcke | 3 Seeds | je 1 Ereignis, `DEADLOCK`, alle 4 Mitglieder, 4 Ticks |
| B2 Ring, 6 Züge / 6 Blöcke | 3 Seeds | je 1 Ereignis, `DEADLOCK`, alle 6 Mitglieder, 4 Ticks |
| C Ring, 3 Züge, ein Block frei | 3 Seeds | 0 Ereignisse, alle Züge am Ziel (kein Fehlalarm, kein Stillstand laut Orakel) |
| D Gegenverkehr auf Doppelgleis | 3 Seeds | 0 Ereignisse, beide Züge am Ziel |
| E Gegenverkehr + dritter Zug dahinter | 3 Seeds | Zyklus aus Zug 1 und 2 erkannt, Zug 3 als „nicht im Kreis, aber `is_deadlock = true`“ mit gleicher Ursache; Orakel zählt Zug 3 korrekt als festgefahren |
| N Normalbetrieb (Felix' K1) 6.000 Ticks | 3 Seeds | je 0 Ereignisse, 0 Orakel-Stillstand, 1.138 bis 1.142 Warte-Ticks (nicht trivial), 39/40 Läufe der Züge |
| Wiederholung | alle | jeweils zweiter Lauf identisch (Ereignis-JSON) |

Das Orakel stimmt in allen 12 Deadlock-Fällen (A, B, B2, E je 3 Seeds) mit `tick_formed` der Sim überein (Abweichung 0). Mein Harness meldete 0 Auffälligkeiten der Art „falsche Ursache, nicht erkannt, Fehlalarm“. **Einschränkung:** Die Offsets ändern am Ergebnis nichts. Mit Hold-and-Wait und ohne Ausweichmöglichkeit tritt der Deadlock in diesen Topologien zwangsläufig ein. Die „3 Seeds“ bringen hier **keine Varianz**, nur Wiederholung. Echte Varianz käme aus anderen Topologien.

**3. Befunde (zu klären mit Felix und Aylin):**

| # | Befund | Wirkung |
|---|---|---|
| B1 | **`root_pos` ist nicht der Ort „des“ Deadlocks, sondern der Ort des Blocks, auf den das *angefragte* Fahrzeug wartet.** Die zwei Züge desselben Gegenverkehr-Deadlocks liefern zwei verschiedene `root_pos` (in allen drei Seeds 200 m auseinander), im Ring 4 bzw. 6 verschiedene Orte (je Mitglied einer). Zug 3 (Auffahrer) bekommt je nach Seed (500000,0) oder (300000,0). | „Wurzelursache am richtigen Ort“ (mein Prüfkriterium, Toleranz ± 2 Felder) und „Klick springt zum Ort“ (F-06, L-06) sind nicht eindeutig. Es braucht einen kanonischen Ort je Deadlock (z. B. Mitte der Kreisglieder, oder der Block, den die Soll-Beschreibung nennt) |
| B2 | **`root_pos` stimmt nicht mit dem letzten Kettenglied überein** (Zug 1 Gegenverkehr: letztes Glied BLOCK#2 bei (300000,0), `root_pos` (500000,0)). Aylins Datenvertrag verlangt `kette[-1] == ursache` (Prüfregel V3, V4). | Aylins Validator würde diese Meldung ablehnen. Die zwei Felder sind nicht abgeglichen (Felix: „Felder-Abgleich offen“) |
| B3 | **Die Kette endet im Block, nicht in einem Wurzelursache-Objekt.** Es gibt kein Kettenglied „Strecke ist eingleisig“ oder „Kreis“, nur Fahrzeug, Signal, Block, Halter. Die Ursache steht im Feld `root_cause`. | Für L-06 muss der UI-Text das letzte Glied aus `root_cause` bilden (Aylin plant das mit `W_EINGLEISIG` etc.). Dann hängt die Messgröße an dieser Abbildung, nicht an der Sim |
| B4 | **Codes unterschiedlich benannt:** Felix `DEADLOCK`, `WARTEN_AUF_LADUNG`; Aylin `KREIS_BLOCKIERUNG`, `ZULIEFERUNG_ZU_GERING`. Typ (`LADUNG`/`INFRASTRUKTUR`) liefert Felix nicht. | Erwartungstabelle in Abschnitt 2 ist bis zum Abgleich nicht verbindlich |
| B5 | **Keine Zuglänge, kein Weg, ein Signal zu entfernen, kein Zufall.** | D4-S2 und D4-S3 sind nicht baubar (siehe Abschnitt 2, Q1) |
| B6 | **Wartezeit bis Erkennung ist 4 Ticks per Parameter.** | Q2 |
| B7 | **Schnittstelle ist Pull im Speicher:** kein Ereignis-Log, keine Prüfsumme, kein Szenario-/Seed-Aufruf, Replay = Szenarioname plus Offsets. | Für D-04 ausreichend (ich laufe im selben Prozess), für CI und Replay-Pflicht (L6 in `testbarkeit_proto.md`) nicht |

**Was ich damit nicht gezeigt habe:** keine Weiche ohne Signal, kein zu kurzes Ausweichgleis, keine Netze mit Kurven oder Polylines (Felix: nur gerade Kanten), keine Pfadsignale, keine Fahrzeugzahl über 6. Die Aussage „Deadlock-Erkennung funktioniert“ gilt für Ringe und eingleisige Gegenverkehrsstrecken mit festem Routenumlauf, nicht für beliebige Netze (so auch Felix' eigenes Risiko).
