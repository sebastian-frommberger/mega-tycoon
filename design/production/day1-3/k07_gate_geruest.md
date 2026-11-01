# Gate M0, 27.11.2026: Dokument-Gerüst (K-07)

Katrin Vogel · Stand Mi 18.11.2026 · Status: **Gerüst, keine Messwerte.** Quelle der Kriterien: `refinement/ergebnis.md` (K-07) und `jonas/gate_kriterien.md` (G1–G8). Schwellen sind PO-Vorschläge, von Felix, Daniel und Tobias noch nicht bestätigt (Frist 19.11.). Jede Zeile hat ein messbares Kriterium, einen Verantwortlichen, einen Beleg und den Status heute.

## 0. Lesehilfe

**Belegstufen** (stehen im Gate neben jeder Ampel):

| Stufe | Bedeutung | Darf eine Ampel setzen? |
|---|---|---|
| **M** | gemessen am Zielobjekt: echter Spike-Build, Zielrechner, echte Tester | ja |
| **V** | Voraussetzung oder synthetisch: eigene Tests des Autors, Vorabläufe, Fake-Feed, Entwicklerrechner | nein |
| **R** | Rechnung oder Modell | nur bei G5 und nur als Teil (Jonas) |
| **O** | offen, kein Wert | Kriterium ist weder Grün noch Gelb, Entscheidung wird vertagt |

Fehlt ein Messwert, schreibe ich „offen“. Es wird nichts hochgerechnet.

## 1. Kriterien

| ID | Kriterium (messbar) | Grün / Gelb / Rot | Verantwortlich | Beleg (Ort, Termin) | Status heute |
|---|---|---|---|---|---|
| **G1** Kette lesbar (Pfeiler 1) | Anteil der 6 Tester, die die Wurzelursache von ≥ 2 der 3 Fehler in < 60 s nach Klick laut nennen | ≥ 4/6 · 3/6 · ≤ 2/6. Weniger als 6 gültige Tester: offen. Plan B: höchstens Gelb (E6) | Lena (Auswertung), Daniel (Durchführung, Protokoll), Aylin (Zweitbeobachtung) | Rohdaten-CSV 25.11., Auswertung 26.11., OBS-Videos, Replay-Dateien. Vorlage: `daniel/l06_protokollvorlage.md` | **O.** Kein Build, 0 von 6 Testern (Rekrutierung nicht belegt). Vorhanden (V): Szenario, Skript, Protokoll als Entwurf. |
| **G2** Sim-Kern bleibt GDScript | Median und p95 Sim-ms pro Tick, 10k Fahrzeuge × 1×, 3 Läufe à 5 min, Zielrechner, gegen 4 ms | Median ≤ 4 ms bei 10k · Median ≤ 4 ms nur bis 5k (Kartengröße-Rückfall greift) · Median > 4 ms bei 5k. Rot ohne tragfähigen Alternativplan mit Kostenrahmen: No-Go | Daniel (Messung), Felix (Entscheidung), Jonas (Ampel) | Messprotokoll (18 Läufe) 23.11., Entscheidungsfolie 25.11. Vorlage: `daniel/benchmark_pruefplan.md` | **O.** Keine Szene, kein Zielrechner, 0 von 18 Läufen. Lesebefunde zu Per-Tick-Sortierung und Dictionary-Fahrzeugen sind keine Messung. |
| **G3** Deadlock erkannt | Erkannte Szenarien (Soll ≥ 5/6) mit richtigem Typ, Objekt, Ort, und Fehlalarme in 10 min Normalbetrieb | ≥ 5/6 und 0 · 4/6 oder 1 Fehlalarm mit bekannter Ursache · ≤ 3/6 oder ≥ 2 Fehlalarme | Daniel (Messung), Felix (Fix) | D-04-Protokoll 23.11. (`daniel/d04_prueffplan.md`), Replay je Fehlschlag | **O.** Spike: 3 F-04-Szenarien Exit 0 (**V**). D-04 beginnt 19.11. „≥ 5/6“ ist mit dem Spike nicht erreichbar, Umdefinition offen (E3). Schwelle „≤ 50 Ticks“ unterscheidet nichts (Parameter 5 Ticks). |
| **G4** Ursache reproduzierbar (Pfeiler 5) | Wiederholungen mit korrektem Wurzelursache-Typ (3 Szenarien × 3 Wiederholungen) | 9/9 · 7–8/9 · ≤ 6/9 | Daniel | D-04-Protokoll, F-06-Smoke-Test (3/3 Fehler auslösbar) | **O.** Vorabläufe 12 von 12 (**V**, zählt nicht). Sim ohne Zufall, „Seeds“ bringen keine Varianz: im Gate als „Wiederholung“ führen. |
| **G5** Lizenz/Kauf-Leiter konsistent | Archetypen von 4 mit ≥ 1 Startfall, in dem die Lizenzroute im Break-even vor dem Kauf liegt (**R**), **und** L-05: Kaufwunsch vor Minute 25 in ≥ 2/3 Runden, Startkapital reicht in 3/3 Runden für 3 Lizenzen (**M**), **und** Decision Record 15–30 k vs. 1–4 k × Stufe | 4/4 und L-05 erfüllt und DR bestätigt · 3/4 oder Startkapital nur 2/3 · ≤ 2/4 oder Kaufwunsch in < 2/3 Runden | Tobias (Tabelle), Lena (L-05), Jonas (DR) | `tobias/t05_ergebnis.md`, `t05_decision_record.md`, L-05-Protokoll und Auswertung bis 25.11. | **Teilweise.** R: 4/4 formal (Agrar über F4 und F5, siehe `daily_tag3.md`, Belegprüfung 5). DR unbestätigt. L-05: 0 von 3 Runden, Material nicht gedruckt, Tester nicht belegt. |
| **G6** Kartengröße entschieden | Decision Record mit Zielgröße und Rückfall, begründet mit Median/p95 aus F-05 und Lesbarkeitsgrenze aus S-03, float32-Check dokumentiert | liegt 24.11. vor, beide Zahlen belegt · liegt vor, S-03-Grenze nur teilweise belegt · kein Record oder Zahlen erfunden | Jonas (mit Felix, Sophie) | F-08-Record 24.11., Eingänge: F-05-Tabelle, `sophie/s03_…befund…md`, float32-Notiz Felix | **O.** Eingänge fehlen: F-05 ohne Zahl, S-03 vorläufig (Rechnung, Rückfall 512² als Argument), float32-Check in keinem Bericht. Bestwert Gelb. |
| **G7** Look-Test | Kein Frame > 33 ms bei Fahrt 50→1000 m in 5 s · 3/4 Reviewer ohne Popping · 4/6 Kollegen finden Stadt, Industrie, Strecke in < 10 s (je Ziel, Annahme Sophie) | alle drei · zwei von drei · ≤ eins | Sophie | GPU-Messlauf auf Zielrechner, Reviewer-Bogen, Klick-Log (`sophie/s03_testaufbau_kollegentest.md`) | **O** (1 von 3 belegt: Szene mit 200 Quadern). Frame-Zeit nicht belegt (Software-Renderer, ca. 290 ms), Popping nur Proxy (5,8× hart gegen 1,5× Blend), Kollegentest nicht gelaufen. |
| **G8** Bau-Gefühl (Pfeiler 2) | 10 Segmente in < 60 s, 0 ungültig, Jonas' Ja/Nein | Ja · nicht gebaut: „nicht nachgewiesen“ mit Auflage „Bau-Spike als erstes M1-Ticket“ (immer Gelb) · Nein | Jonas (Felix baut) | F-07-Replay, Zeitprotokoll durch Daniel oder Katrin | **Nicht begonnen.** Empfehlung: Stretch streichen, „nicht nachgewiesen“ (E7). |
| **G9** VS-Backlog geschätzt (K-07) | Anteil der VS-Epics mit T-Shirt-Größe aus 2-h-Planning-Poker mit Felix, Abgleich mit Kapazität | 100 % und ≤ 85 % Kapazität (Overview 31.10.) · 100 %, aber > 85 % mit dokumentierter Kürzungsliste · < 100 % | Katrin (Moderation), Felix (Schätzung), Sophie (S-06a) | Poker-Protokoll, Epic-Liste, Asset-Liste S-06a (mit mir abgestimmt bis 24.11.) | **O.** Poker nicht terminiert (Felix 0,25 T), S-06a in keinem Bericht. Schwelle ist mein Vorschlag, nicht von Jonas. |
| **H1** Konzept-Hygiene (Vorschlag) | Gate-relevante Widersprüche aus `lena/widersprueche.md` (Nr. 1, 4, 5, 7, 12, 21, 23) entschieden und im Entscheidungslog | 7/7 · 5–6/7 · < 5/7. Kein Gate-Kriterium, solange der PO es nicht aufnimmt | Lena (Vorbereitung), Jonas (Entscheidung) | Entscheidungslog | **0 von 7** laut Lena („keiner entschieden“). Der Stand des Logs vom 13.11. ist in den Berichten nicht belegt. |

## 2. Entscheidungsregel und offene Lücken

Regel (Jonas): **Go** = G1 bis G6 jeweils Grün oder Gelb mit Auflage, höchstens 2 Gelb, kein Rot, alle Messwerte vorhanden. **No-Go** = G1 Rot, oder G2 Rot ohne Alternativplan mit Kostenrahmen, oder G3 Rot. **Vertagen** = ein Messwert fehlt. G7 und G8 fließen in die Empfehlung, G7 ist Eingang für G6.

Vor dem 27.11. zu klären (Vorlagen in `daily_tag3.md`, E3 und E6):
1. G1: „kein echter Build = Rot“ gegen „Plan B höchstens Gelb“. Beides steht in Jonas' Dateien.
2. Drei Gelb: weder Go noch No-Go in der Regel. Mein Vorschlag: Go = kein Rot, alle Messwerte da, höchstens 2 Gelb in G1 bis G3, übrige Gelb nur mit Auflage, Owner, Termin.
3. G3 wie beschlossen nicht erreichbar, Umdefinition auf darstellbare Szenarien.
4. G2: Definition pro Tick (Median, Ampel), p95 Pflichtangabe mit Warnschwelle 6 ms, 8× pro Frame nur berichtet, nur Release-Export (sonst „obere Schranke“).
5. Vertagen mit Datum: Nachfrist-Termin Mi 02.12. reserviert.
6. G2-Alternativplan: Skelett (GDExtension, Kostenrahmen) einplanen, sonst kann ein Rot nicht anders als No-Go enden.

## 3. Was im Gate nicht stehen darf

- „Deadlock in 4 Ticks erkannt“ als Geschwindigkeit. Es ist ein Parameter.
- „Startkapital passt zur Leiter“ als Beleg. Es ist so gesetzt, dass der Satz stimmt. Der Beleg ist L-05.
- „Zielzeiten 12 und 80 min bestätigt“. Sie folgen aus +2 %/Monat.
- „Diagnose trägt“ oder „USP belegt“. Gelesen wird: Die Kette ist in 3 bekannten Fällen für 6 Personen lesbar.
- Ergebnisse aus Vorabläufen, Fake-Feed oder Entwicklerrechner als Messwert.
- Pfeiler 3 und 4 als „Grün“. Sie haben in S2 keinen Test (steht als Risiko für M1).

## 4. Ablauf

| Wann | Was | Wer |
|---|---|---|
| 19.11. | Schwellen G1–G8 und G2-Definition bestätigen, Entscheidungen E1–E7 | Jonas, Felix, Daniel, Tobias |
| 24.11. | F-08-Record, S-06a mit mir abgestimmt, Poker-Termin | Jonas, Felix, Sophie, Katrin |
| 25.11. | Messprotokolle G2 und G3 fertig, Rohdaten G1, Ampel-Entwurf J-05 | Daniel, Lena, Jonas |
| 26.11. | Auswertung L-06, Go/No-Go-Empfehlung (J-05), Poker, Dokument-Freeze 16:00 | Lena, Jonas, Katrin |
| 27.11. | Gate, 90 min (Vorschlag): 5 min Regeln und Belegstufen · je Kriterium 5 min (Zahl, Beleg, Ampel durch Verantwortlichen) · 15 min Risiken für M1 (Pfeiler 2, 3, 4) · 15 min Entscheidung · 10 min Auflagen mit Owner und Datum | Alle, Entscheidung Jonas |
| 02.12. | Nachfrist-Termin (nur bei Vertagen), 2 h | Alle |

## 5. Protokollvorlage Go/No-Go (leer)

| Feld | Eintrag |
|---|---|
| Entscheidung | Go / No-Go / Vertagen auf (Datum) |
| Ampel G1–G9 mit Belegstufe | |
| Begründung (max. 5 Sätze) | |
| Offene Messwerte (je Owner, Datum) | |
| Auflagen (je Owner, Datum) | |
| Risiken für M1 (Pfeiler 2, 3, 4, Neueinstellung, Zielhardware) | |
| Abweichungen vom Beschluss (z. B. G3 neu gefasst, Datum des PO-Entscheids) | |
| Protokoll | Katrin Vogel, Freigabe Jonas Weber |

## 6. Ehrliche Grenzen, die ins Gate gehören

1. Der Spike deckt Ringe und eingleisige Gegenverkehrsstrecken mit festem Umlauf ab, nicht beliebige Netze (gerade Kanten, 1 Block Vorausreservierung, keine Zuglänge, kein Weglassen von Signalen, kein Zufall).
2. Der Playtest hat n = 6 und einen Deckeneffekt (Kette endet in der Wurzelursache). Plan B misst nur die Oberfläche.
3. Der Benchmark gilt für das Layout der Szene auf der gewählten Zielrechner-Konfiguration. Das CPU-Modell wird im Protokoll genannt.
4. Die Wirtschaftszahlen sind Modell: Preisbasen, KI-Anteil und Distanzen sind Setzungen. Kein Ausbaupfad, daher ist Meilenstein 7 (5.000 $/min in 35–50 min) nicht belegt.
5. Personenverkehr fehlt im Paper-Test. Kapital und Kaufwunsch sind mit Spielgeld und Spielleiter-Karten angeregt, nicht frei entstanden.
6. Pfeiler 3 (Nischen je Verkehrsmittel), Pfeiler 4 (Spezialisierung) und Pfeiler 2 (Bau-Gefühl) sind in S2 nicht geprüft.
