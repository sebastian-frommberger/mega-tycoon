# Daniel – Sprint 2, Tag 4–6
## Daily Tag 4 (19.11.)
Gestern: Prüfpläne, Farbcheck-Skript. Heute: D1–D14 eingearbeitet, D-04-Harness auf 6 Szenarien × 3 Varianten, Farbcheck mit Sophies Palette und Ghost-Weiß. Blocker: Übergabe lag anfangs nicht vor, erster Lauf am Stand 18.11.
## Daily Tag 5 (20.11.)
Gestern: Harness, Farbcheck. Heute: Fehlalarm-Test eigenes Normalnetz, Befund B8 mit Replay, L-06-Vorlage v2. Blocker: Zielrechner, keine Tester-Info von Katrin.
## Daily Tag 6 (23.11.)
Gestern: Übergabe eingetroffen. Heute: D-04 komplett am Übergabe-Stand wiederholt, Felix' Benchmark und SoA nachgemessen, Auswertung. Blocker: Zielrechner, F-06 fehlt.

## Ergebnisse
- **D-04: fertig.** `daniel/d04_protokoll.md`, `.csv` (42 Zeilen), `daniel_d04_lauf_v2.gd`, `build_md5.txt` (identisch zu Felix). Godot 4.4.1 headless, Sandbox. **G3: 6/6 Szenarien** (3 F-04, Ring 6, Auffahrer, eigenes „drei Teilnetze“), 18/18 Läufe Typ/Objekt/Ort richtig, Validator leer; **0 Fehlalarme** in 3 × 6.000 Ticks auf eigenem Normalnetz; 21 Wiederholungspaare identisch → **Grün nach Tabelle**. G4-Wiederholungen 9/9, Smoke offen (F-06) → **offen**. **Neu B8 (S1):** `get_wait_chain()` bricht ab, wenn ein Kettenglied auf einen im selben Tick freigegebenen Block wartet (80/6.000 Ticks), auch am Übergabe-Stand; Replay `daniel_b8_replay.gd`. Erste Normalnetz-Fassung hatte einen echten Deadlock (offen gelegt, kein Fehlalarm).
- **F-05: nachgemessen, zählt nicht.** `f05_messprotokoll.md`, Rohdaten `f05_daniel_*`. Sandbox, Editor-Binary. Felix' Zahlen reproduziert (Prüfsummen gleich): Spike 10k/1× 71,8 ms (Felix 67,4), 5k 34,3 (34,1); SoA 10k 2,26 ms, p95 4,97. 1k instabil (Streuung 28 %). G2 offen.
- **Farbcheck S-05: fertig.** `farbcheck_ergebnis_s05.md`: 21 Kollisionen, identisch mit Sophies Gegenprobe; Status-Farben ok. **D10:** Ghost-Weiß gegen `#F2F2F2` ΔE 0,4–2,6 → dunkle Kontur Pflicht; Stadtfläche 11–18 ok. Feld-Ocker/Stadtfläche kollidiert auch normalsichtig.
- **L-06 Vorlage v2: fertig (Entwurf).** `l06_protokollvorlage_v2.md`: G1-Lesart, Plan B = Gelb-Deckel, Berichtssatz mit Wilson, Zeilenklicks / Nur-letzte-Zeile-Leser / Median definiert, `T_STEHT`, Vorschlag aus, F2-Regel bestätigt. Kein Test.

## Annahmen und offene Fragen an andere (mit Namen)
- **Felix:** B8 vor Freeze fixen; S6 als API (`build_s6`) übernehmen; Export-Hauptszene.
- **Jonas:** Wende-/Lade-Deadlock = bekannte Ursache, kein Fehlalarm (mein Vorschlag); zählt Skript-Projekt ohne Export als Spike-Build (G3 = M)?; SoA als Teil-Beleg?
- **Sophie:** Ghost-Hex festlegen (Annahme `#FFFFFF`/`#F0F0F0`), Kontur oder Konsum-Farbe ändern.
- **Lena, Aylin:** 20-s-Regel „Nur-letzte-Zeile-Leser“; CSV-Spalten.
- **Katrin:** Zielrechner, Tester.
- Annahmen: 1 Feld = 100 m; Varianten statt Seeds.

## Risiko für das Sprintziel (1–3 Sätze, ehrlich)
G3 ist gemessen und gut, aber im Mini-Modell. B8 kann am Testtag jeden Klick treffen, solange Verkehr fährt. G2 ist ohne Zielrechner nicht messbar, und der Spike-Kern wäre dort Rot.
