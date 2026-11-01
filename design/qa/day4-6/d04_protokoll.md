# D-04 Deadlock-Prüfung: Protokoll (Tag 4–6, Stand 23.11.2026)

Daniel Richter, QA · Prüfung nach D3 (6 darstellbare Szenarien, keine Tick-Schwelle) und G3/G4 aus `day1-3/jonas/gate_kriterien.md`.
Rohdaten: `d04_protokoll.csv` (42 Zeilen = 36 Szenario-Läufe + 6 Normalnetz-Läufe), Konsole `d04_lauf_ausgabe.txt`, Harness `daniel_d04_lauf_v2.gd`, Replay B8 `daniel_b8_replay.gd` + `b8_replay_ausgabe.txt`, Prüfsummen `build_md5.txt`, Nachlauf Felix' Runner `felix_runner_nachlauf.txt`. Der frühere Lauf am Stand 18.11. liegt archiviert in `vor_uebergabe_18-11/`.

## 0. Build-Stand und Umgebung (Pflichtangabe)

- **Geprüft: Felix' Übergabe** `day4-6/felix/spike/` laut `uebergabe_daniel.md`. Kein Export, kein Hash (Skript-Projekt); Build-ID = `md5sum *.gd`, auf meiner Kopie **identisch** zu Felix' `build_md5.txt` (z. B. `diagnostics.gd 2adbb60d…`, `sim_world.gd 93fe3ad8…`). Felix' Runner bei mir 2× Exit 0, Ausgabe identisch zu seiner `test_output.txt` (außer Dauer).
- Ablauf ehrlich: Als ich anfing, lag die Übergabe noch nicht vor; ich habe zuerst am Stand 18.11. geprüft (archiviert, dort G4 3/9 wegen fehlendem D9). Alle Zahlen unten stammen aus dem **Lauf am Übergabe-Stand**, Harness v2 (Kriterien an D9 angepasst, siehe unten).
- Umgebung: **Sandbox 2 vCPU Xeon 2,8 GHz, 8 GB, keine GPU, Godot 4.4.1 stable Editor-Binary headless.** Ticks sind hardwareunabhängig, für D-04 unkritisch.
- Harness läuft im selben Prozess gegen eine Kopie (Felix' Ordner unverändert). Orakel für `Tick_Eintritt`: eigener größter Fixpunkt wartender Fahrzeuge, nutzt `find_wait_cycles` nicht.
- **Keine Seeds** (Sim ohne PRNG). Varianten = andere Startpositionen, Start-Offsets, ID-Reihenfolge (ändert die Step-Reihenfolge). Jeder Lauf **zweimal** ausgeführt; alle 21 Wiederholungspaare identisch.

## 1. Die 6 Szenarien × 3 Varianten (G3)

Kriterien je Lauf: **Typ** = Felix' Enum (D9). **Objekt** = Zyklusmitglieder (Ereignis und `cycle`) bzw. letztes Glied `URSACHE` mit `obj_kind LAGER` und Lager-ID. **Ort** = `root_pos` gleich dem **unabhängig aus dem Fahrzeugzustand berechneten** Schwerpunkt der umkämpften Blöcke, ≤ 2 Felder (200 m, Annahme A5) vom nächsten umkämpften Block, und **gleich für alle Mitglieder**; bei Ladung = Lagerknoten. **Kanonisch (D9)**: `root_pos == kette[-1].pos`. Zusätzlich Felix' `Diagnostics.validate()` leer. Ein Lauf ist OK nur, wenn alles stimmt.

| Szenario | Varianten | Typ | Objekt | Ort | D9 | validate | Ergebnis |
|---|---|---|---|---|---|---|---|
| S1 Gegenverkehr eingleisig (F-04 S1) | Original · Offsets 15/0 · 5 Knoten, Start bei N1, IDs vertauscht | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | erkannt |
| S2 Deadlock-Kreis 4 Züge (F-04 S2) | Original · gestaffelt 0/7/14/21 · rotiert, IDs rückwärts | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | erkannt |
| S3 Warten auf Ladung (F-04 S3, mit 1 Zulieferer-Lkw) | Original · Eigenproduktion zu langsam · dritter wartender Zug | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | erkannt; `params` z. B. `fuell_ist 2 / fuell_soll 40 / n_lkw 1` |
| S4 Ring 6 Züge (D3) | Offsets 0 · gestaffelt · rotiert, IDs rückwärts | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | erkannt |
| S5 Gegenverkehr mit Auffahrer (D3) | Auffahrer ab Tick 70 · ab 30 · auf der Gegenseite | 3/3 | 3/3 (Zyklus `[1,2]`, Auffahrer nicht im Kreis, `is_deadlock` true, gleicher `root_pos`) | 3/3 | 3/3 | 3/3 | erkannt |
| S6 Daniels drittes: drei Teilnetze gleichzeitig (Gegenverkehr + Ring 4 + Ladung + 2 Kontrollzüge K1 in einer Welt, Vorläufer der L-06-Testkarte) | IDs/Reihenfolge · Kontrollzüge steppen zuerst, gestaffelt · Ring rotiert | 3/3 (genau 2 Ereignisse) | 3/3 (Mitglieder je Teilnetz, `URSACHE(LAGER)#201`, Kontrollzüge 6 Läufe) | 3/3 (je im eigenen Teilnetz) | – | 0 Validator-Fehler auf allen wartenden Ketten | erkannt |

**G3: 6/6 Szenarien, 18/18 Läufe richtig in Typ, Objekt und Ort.** Belegt je Zeile in der CSV (z. B. S1 V1: Orakel-Eintritt 101 = `tick_formed` 101, erkannt 105, `root_pos (400000,0)`). S6 als API-Aufruf für Felix' `scenarios.gd`: Funktion `build_s6(v)` in `daniel_d04_lauf_v2.gd`.

Hinweis Ort: Bei Ringen ist der kanonische Ort die **Ringmitte** (dort liegt kein Gleis). Das ist Felix' Definition nach D9 und für einen Kamerasprung sinnvoll; für eine Markierung „auf dem Gleis“ muss die UI `params.bloecke` nehmen. Info an Aylin, kein Fehlschlag.

## 2. Fehlalarm-Test (G3): Daniels Normalnetz, 3 Varianten × 6.000 Ticks (10 min Spielzeit)

Netz N (eigenes, nicht Felix' K1): zweigleisige Hauptstrecke A–B–C–D mit 3 pendelnden Zügen (gleiche Richtung, Wenden an den Enden), eingleisige Zweigstrecke D–E, Ausweichstelle E–F (2 Gleise), F–G mit 2 gegenläufigen Zügen; eigene Straße P–Q–R mit 1 Lkw, der bei Q lädt (1 Einheit/30 Ticks, Bedarf 10). Varianten: Offsets, Geschwindigkeiten, ID-Reihenfolge.

| Variante | Deadlock-Meldungen | Orakel-Stillstand-Ticks | Warte-Fahrzeug-Ticks | längste Wartephase | Läufe je Fahrzeug |
|---|---|---|---|---|---|
| N1 | **0** | 0 | 8.895 | 249 Ticks | 31/30/29/39/40/19 |
| N2 | **0** | 0 | 9.081 | 249 Ticks | 29/31/29/40/39/19 |
| N3 | **0** | 0 | 6.526 | 225 Ticks | 29/29/29/39/39/19 |

**0 Fehlalarme in 3 × 6.000 Ticks** bei nicht-trivialer Last (Wartephasen bis 249 Ticks, alle Fahrzeuge fahren weiter); Sinnprobe: derselbe Build schlägt in S1–S6 an. Am Stand 18.11. und am Übergabe-Stand sind die N-Ergebnisse identisch.

**Erste Fassung des Normalnetzes (offen gelegt):** Der Lkw lud direkt auf einem Block der Hauptstrecke; das Netz hat sich nach ca. 240 Ticks **wirklich** festgefahren (Orakel 5.625 Stillstand-Ticks, 1 Meldung `DEADLOCK`). Das war kein Fehlalarm, sondern ein echter Hold-and-Wait-Stillstand durch mein Layout, korrekt erkannt. Ich habe das Netz geändert, nicht die Zählung.

**Antwort auf Felix' Frage (Wende-Deadlock, Grenze 2):** Ein Stillstand, bei dem die Fahrzeuge laut Orakel tatsächlich nur noch aufeinander warten, ist nach meiner Zählregel **kein Fehlalarm**, sondern eine **bekannte Ursache** des Spike-Modells (Hold-and-Wait am Wendepunkt bzw. beim Laden auf der Strecke). Fehlalarm = Meldung ohne objektiven Wartekreis. Das Gate nennt die Modellgrenze ausdrücklich. Entscheidung Jonas (mein Vorschlag).

## 3. Wiederholbarkeit (G4)

G4: 3 Szenarien × 3 Wiederholungen mit korrektem Typ und kanonischem Ort (D9). Gezählt an den drei F-04-Szenarien S1–S3 (je 3 Varianten, je 2× gelaufen, identisch): **Typ 9/9, kanonischer Ort 9/9 → 9/9.** F-06-Smoke (3/3 Fehler auslösbar, ≥ 120 s sichtbar) ist nicht Teil dieses Protokolls; F-06 ist nicht gebaut (Felix: Build 24.11., 12:00). G4 hat damit **noch keinen vollständigen Messwert**.

## 4. Befunde mit Replay

| # | Befund | Schwere | Replay | Wirkung / Vorschlag |
|---|---|---|---|---|
| **B8 (neu, am Übergabe-Stand bestätigt)** | **`get_wait_chain()` bricht ab** (`Invalid access to key -1`, `diagnostics.gd:108`), wenn ein Fahrzeug der Kette im Zustand `WARTET_BLOCK` auf einen Block wartet, der im selben Tick nach seinem eigenen Schritt freigegeben wurde (`holder = -1`; der Halter mit höherer ID steppt später). Rückgabe `{}`. Im Normalnetz N1 liegt dieser Zustand **nach** 80 von 6.000 vollständigen Ticks vor (erster Tick 704), also auch zwischen zwei Ticks, wenn die UI fragt. | **S1 für F-06/L-06** (jeder Klick kann ihn treffen, sobald neben den Testfehlern Verkehr fährt, z. B. die zwei Kontrollzüge). Für D-04 selbst unkritisch: Deadlocks sind stabil. | `daniel_b8_replay.gd`: Normalnetz V1, `run_ticks(3451)`, `get_wait_chain(1)` → Fehler; einen Tick später ist Zug 1 eingefahren. 2× reproduziert, gleicher Tick, am Stand 18.11. (Zeile 54) und am Übergabe-Stand (Zeile 108). | Felix: in `build_wait_chain` `holder == -1` als Kettenende „Block frei, Einfahrt im nächsten Tick“ behandeln (keine Meldung), oder Wartende beim Freigeben sofort nachziehen. Testfall in den Runner. |
| B2 (18.11.) | `root_pos ≠ kette[-1].pos` | – | – | **behoben** am Übergabe-Stand (15/15 Zyklus-Läufe kanonisch). |

Nicht geprüft (per D3 benannt, M1-Auflage): Weiche ohne Signal, kurzes Ausweichgleis, Kurven/Polylines, Pfadsignale, mehr als 6 Züge in einem Zyklus.

## 5. Bewertung gegen G3/G4 (Vorschlag an Jonas, mit Belegstufe)

- **G3: 6/6 Szenarien und 0 Fehlalarme → Grün nach Tabelle.** Gemessen am übergebenen Spike (md5 identisch), mit meinem Harness, nicht mit Felix' Runner. Belegstufe aus meiner Sicht **M**; Jonas entscheidet, ob ein Skript-Projekt ohne Export als „echter Spike-Build“ zählt. Einschränkungen: Szenarien und Normalnetz von mir gebaut (Autor der Prüfung, nicht des Spikes), Modell klein (≤ 6 Fahrzeuge je Zyklus, nur gerade Kanten).
- **G4: Wiederholungen 9/9; Smoke offen** (F-06 fehlt) → G4 derzeit **offen**, nicht Grün.
- **B8 ist der wichtigste Befund dieser Woche:** er betrifft nicht die Erkennung, sondern die Abfrage im Testbuild. Vor dem Freeze beheben, sonst Risiko für den Testtag.
