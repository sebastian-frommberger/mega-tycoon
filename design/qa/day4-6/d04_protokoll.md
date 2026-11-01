# D-04 Deadlock-Prüfung: Protokoll (Tag 4–6, Stand 23.11.2026)

Daniel Richter, QA · Prüfung nach D3 (6 darstellbare Szenarien, keine Tick-Schwelle) und G3/G4 aus `day1-3/jonas/gate_kriterien.md`.
Rohdaten: `d04_protokoll.csv` (42 Zeilen = 36 Szenario-Läufe + 6 Normalnetz-Läufe), Konsole `d04_lauf_ausgabe.txt`, Harness `daniel_d04_lauf.gd`, Replay B8 `daniel_b8_replay.gd` + `b8_replay_ausgabe.txt`, Prüfsummen `build_md5.txt`.

## 0. Build-Stand und Umgebung (Pflichtangabe)

- **Geprüft wurde Felix' Tag-1–3-Stand** `day1-3/felix/spike/` (md5 in `build_md5.txt`, z. B. `diagnostics.gd b59187c3…`). In `day4-6/felix/` lag beim Start **keine** Übergabe-Datei und keine Tag-4–6-Version. Die für 19.11., 12:00 zugesagte Übergabe (B2) und die D9-Änderungen (kanonischer Ort, Zusatzfelder) sind **nicht** in dem Build, den ich geprüft habe. Alle Läufe sind damit Läufe am Vor-Übergabe-Stand; sobald Felix' Build mit Hash kommt, laufen sie erneut (Harness ist dafür gebaut, Aufwand < 0,5 h).
- Umgebung: **Sandbox 2 vCPU Xeon 2,8 GHz, 8 GB, keine GPU, Godot 4.4.1 stable Editor-Binary headless.** Ticks sind hardwareunabhängig, deshalb ist die Umgebung für D-04 unkritisch; für F-05 nicht (siehe `f05_messprotokoll.md`).
- Harness läuft im selben Prozess gegen eine Kopie des Spikes (Felix' Ordner unverändert). Orakel für `Tick_Eintritt`: eigener größter Fixpunkt der wartenden Fahrzeuge, nutzt `find_wait_cycles` nicht.
- Keine Seeds: die Sim hat keinen PRNG. **Varianten** = andere Startpositionen, Start-Offsets, ID-Reihenfolge (ändert die Step-Reihenfolge). Jeder Lauf wurde **zweimal** ausgeführt (Wiederholung, G4); alle 21 Wiederholungen liefern identische Ereignisse und Ketten.

## 1. Die 6 Szenarien × 3 Varianten (G3)

Prüfung je Lauf: **Typ** = Ursache-Code aus Felix' Enum (D9), **Objekt** = Zyklusmitglieder bzw. Lagerknoten (letztes Kettenglied `INDUSTRIE#id`), **Ort** = `root_pos` ist Mitte eines umkämpften Blocks (Warteblock eines Zyklusmitglieds) und ≤ 2 Felder (Annahme A5: 1 Feld = 100 m) vom anfragenden Fahrzeug; bei Ladung = Lagerknoten. Zusätzlich **kanonisch (D9)**: `root_pos == kette[-1].pos`.

| Szenario | Varianten | Typ ok | Objekt ok | Ort ok | kanonisch D9 | Ergebnis |
|---|---|---|---|---|---|---|
| S1 Gegenverkehr eingleisig (F-04 S1) | Original · Offsets 15/0 · 5 Knoten, Start bei N1, IDs vertauscht | 3/3 | 3/3 (`[1,2]`) | 3/3 | **0/3** | erkannt |
| S2 Deadlock-Kreis 4 Züge (F-04 S2) | Original · gestaffelt 0/7/14/21 · rotiert, IDs rückwärts | 3/3 | 3/3 | 3/3 | **0/3** | erkannt |
| S3 Warten auf Ladung (F-04 S3) | Original · Nachschub zu langsam (1/100 Ticks) · 3 Lkw in Kette | 3/3 | 3/3 (`INDUSTRIE#1`) | 3/3 | 3/3 | erkannt |
| S4 Ring 6 Züge (D3) | Offsets 0 · gestaffelt · rotiert, IDs rückwärts, Abfrage mittleres Mitglied | 3/3 | 3/3 (6 Mitglieder) | 3/3 | **0/3** | erkannt |
| S5 Gegenverkehr mit Auffahrer (D3) | Auffahrer ab Tick 70 · ab Tick 30 · auf der Gegenseite, 5 Knoten | 3/3 | 3/3 (Zyklus `[1,2]`, Auffahrer nicht im Kreis, `is_deadlock` true, Orakel zählt ihn als festgefahren) | 3/3 | **0/3** | erkannt |
| S6 Daniels drittes: drei Teilnetze gleichzeitig (Gegenverkehr + Ring 4 + Ladung + 2 Kontrollzüge K1 in einer Welt, Vorläufer der L-06-Testkarte) | Reihenfolge/IDs · Kontrollzüge steppen zuerst, Offsets gestaffelt · Ring rotiert, Zug startet bei N1 | 3/3 (genau 2 Ereignisse mit richtigem Typ, Ladungskette `WARTEN_AUF_LADUNG`) | 3/3 (Mitglieder je Teilnetz, `INDUSTRIE#201`, Kontrollzüge fahren 6 Läufe) | 3/3 (root_pos je im eigenen Teilnetz) | n. a. | erkannt |

**G3-Zählung: 6/6 Szenarien erkannt mit richtigem Typ, Objekt und Ort (18/18 Läufe).** Jede Zeile ist mit Zeitstempel und Tick in der CSV belegt (z. B. S1 V1: Eintritt Orakel 101 = `tick_formed` 101, erkannt 105).

**Aber: der kanonische Ort nach D9 ist in 12 von 15 Deadlock-Läufen nicht erfüllt** (`root_pos` ≠ Ort des letzten Kettenglieds, Befund B2 aus Tag 3, unverändert). Nur bei Ladung stimmt er. Das ist kein D-04-Fehlschlag (Ort ist nach meinem Kriterium korrekt, auf einem umkämpften Block), aber es ist genau das, was D9 Felix bis 19.11., 12:00 auferlegt hat, und Aylins Validator V3 lehnt diese Meldungen ab. Für G4 zählt D9 ausdrücklich („kanonischer Ort“), siehe Abschnitt 3.

## 2. Fehlalarm-Test (G3): Daniels Normalnetz, 3 Varianten × 6.000 Ticks (10 min Spielzeit)

Netz N (eigenes, nicht Felix' K1): zweigleisige Hauptstrecke A–B–C–D mit 3 pendelnden Zügen (Stau in gleicher Richtung, Wenden an den Enden), eingleisige Zweigstrecke D–E mit Ausweichstelle E–F (2 Gleise) und F–G, 2 gegenläufige Züge; eigene Straße P–Q–R mit 1 Lkw, der bei Q lädt (1 Einheit/30 Ticks, Bedarf 10). Varianten: Offsets, Geschwindigkeiten, ID-Reihenfolge.

| Variante | Deadlock-Meldungen | Orakel-Stillstand-Ticks | Warte-Fahrzeug-Ticks | längste Wartephase | Läufe je Fahrzeug | Kettentypen (Stichprobe alle 50 Ticks) |
|---|---|---|---|---|---|---|
| N1 | **0** | 0 | 8.895 | 249 Ticks | 31/30/29/39/40/19 | BLOCK_BELEGT_UNTERWEGS 70, WARTEN_AUF_LADUNG 81 |
| N2 | **0** | 0 | 9.081 | 249 Ticks | 29/31/29/40/39/19 | 108 / 81 |
| N3 | **0** | 0 | 6.526 | 225 Ticks | 29/29/29/39/39/19 | 46 / 80 |

**0 Fehlalarme in 3 × 6.000 Ticks**, bei nicht-trivialer Last (Wartephasen bis 249 Ticks, weit über der alten 50er-Schwelle; alle Fahrzeuge fahren weiter). Sinnprobe: derselbe Build schlägt in S1–S6 an.

**Ehrlich dazu:** Meine **erste Fassung** des Normalnetzes (Lkw lädt direkt auf einem Block der Hauptstrecke) hat sich nach ca. 240 Ticks **wirklich** festgefahren (Orakel: 5.625 Stillstand-Ticks, 1 Meldung `DEADLOCK`, siehe `d04_lauf_ausgabe.txt`-Vorläufer in meiner Scratch-Umgebung, Beschreibung im Harness-Kommentar). Das war **kein Fehlalarm**, sondern ein echter Hold-and-Wait-Deadlock durch mein Layout, korrekt erkannt. Ich habe das Netz umgebaut (Lkw auf eigene Straße), nicht die Zählung. Nebenbefund für Lena/Felix: ein Lkw, der auf einem Streckenblock lädt, legt in diesem Modell eine ganze Strecke lahm, weil der Block während des Ladens gehalten wird.

## 3. Wiederholbarkeit (G4)

G4 verlangt 3 Szenarien × 3 Wiederholungen mit korrektem Typ **und kanonischem Ort (D9)**. Gemessen an den drei F-04-Szenarien S1–S3 (je 3 Varianten, je 2× gelaufen, identisch):

| | Typ korrekt | kanonischer Ort D9 | G4-Zählung |
|---|---|---|---|
| S1 | 3/3 | 0/3 | 0/3 |
| S2 | 3/3 | 0/3 | 0/3 |
| S3 | 3/3 | 3/3 | 3/3 |
| **Summe** | 9/9 | 3/9 | **3/9 → Rot nach G4-Schwelle (≤ 6/9)** |

Das ist eine Folge des Build-Stands (D9-Änderung fehlt), keine Instabilität: die Ergebnisse sind in allen Wiederholungen identisch. Mit Felix' D9-Fix (root_pos = Ort des letzten Kettenglieds) wäre nach denselben Läufen 9/9 zu erwarten, **das ist aber eine Erwartung, kein Messwert.** F-06-Smoke (3/3 Fehler auslösbar, ≥ 120 s sichtbar) ist nicht Teil dieses Protokolls (Build fehlt).

## 4. Fehlschläge und Befunde (Replay-Beschreibung)

Kein Lauf der 6 Szenarien und keiner der Normalnetz-Läufe ist gescheitert. Zwei Befunde mit Replay:

| # | Befund | Schwere | Replay | Wirkung |
|---|---|---|---|---|
| **B8 (neu)** | **`get_wait_chain()` stürzt ab** (`Invalid access to key -1`, `diagnostics.gd:54`), wenn irgendwo in der Warte-Kette ein Fahrzeug im Zustand `WARTET_BLOCK` steht, dessen Block im selben Tick bereits freigegeben wurde (`holder = -1`; der Halter mit höherer ID steppt später im Tick). Rückgabe ist dann `{}`. Im Normalnetz N1 ist der Zustand in **80 von 6.000 Ticks** vorhanden (erster Tick 704). | **S1** für F-06/L-06: die UI darf die Kette jederzeit anfragen; ein Klick in so einem Tick liefert nichts oder wirft einen Fehler. Für D-04 selbst unkritisch (Deadlocks sind stabil). | `daniel_b8_replay.gd`: Normalnetz V1, `run_ticks(3451)`, `get_wait_chain(1)` → Fehler; einen Tick später ist Zug 1 eingefahren. 2× reproduziert, identischer Tick. | Felix: entweder in `_try_enter` beim Freigeben die Wartenden sofort nachziehen, oder in `build_wait_chain` `holder == -1` als Kettenende „Block frei, Einfahrt im nächsten Tick“ behandeln. |
| **B2 (offen seit 18.11.)** | `root_pos` ≠ `kette[-1].pos` bei allen Zyklen (12/12 Läufe mit Zyklus und Anfrager im Kreis). | S2 (D9-Pflicht) | jede Zeile mit `kanonisch_D9 = nein` in der CSV | Aylins Validator V3 lehnt die Meldung ab; G4 Rot (Abschnitt 3). |

Nicht geprüft (per D3 benannt, M1-Auflage): Weiche ohne Signal, kurzes Ausweichgleis, Kurven/Polylines, Pfadsignale, mehr als 6 Züge in einem Zyklus.

## 5. Bewertung gegen G3/G4 (Vorschlag für Jonas, Belegstufe)

- **G3: 6/6 Szenarien, 0 Fehlalarme → nach Tabelle Grün.** Belegstufe: gemessen am Code-Stand 18.11., **nicht am übergebenen Spike-Build** (Übergabe mit Hash fehlt). Nach Messwert-Regel D7 („Daniels Vorabläufe = Voraussetzung“) trage ich das als **V, nicht M** ein, bis dieselben Läufe am übergebenen Build mit Hash wiederholt sind. Dann ist es M.
- **G4: 3/9 → Rot**, Ursache D9-Fix fehlt im Build. Kein Zufall, keine Instabilität (alle Wiederholungen identisch). Wenn Felix D9 liefert, laufen die 9 Läufe erneut; erst dann gibt es einen G4-Messwert.
- **Neuer Blocker für L-06/F-06: B8** (Absturz der Kettenabfrage im Tick-Zwischenstand).
