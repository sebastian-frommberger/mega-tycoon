# Felix – Sprint 2, Tag 4–6
## Daily Tag 4 (19.11.)
Gestern: F-04-Tests grün, Feldabgleich offen. Heute: D9 umgesetzt (kanonischer Ort, Zusatzfelder, Validator), Pairing-Antworten, Übergabe an Daniel. Blocker: keiner.
## Daily Tag 5 (20.11.)
Gestern: F-04 übergeben. Heute: Benchmark-Szene F-05, Lauf 1 auf der Sandbox. Blocker: kein Zielrechner, keine Export-Templates.
## Daily Tag 6 (23.11.)
Gestern: Lauf 1. Heute: Läufe 2/3, SoA-Vergleich, float32-Check (dabei int32-Bug gefunden und behoben), F-06 geschätzt. Blocker: Zielrechner; F-06 ist größer als geplant.
## Ergebnisse
- **F-04: fertig (Code), Übergabe erfolgt.** `felix/spike/`, `uebergabe_daniel.md`, `pairing_antworten.md`. Der Runner läuft echt mit Exit 0 (`test_output.txt`), zweimal identisch, Mutationsproben (4) liefern Exit 1. AK D9: `root_pos == links[-1].pos` und gleich für alle Mitglieder und Auffahrer: **ja**. `fuell_ist/soll`, `n_lkw`, Streckenlänge, Gleiszahl: **ja**. Fehler 3 mit Zulieferer-Lkw (2/40, n_lkw 1, steht nach 1.300 Ticks noch): **ja, datenseitig lösbar**. Die Lösbarkeit für Tester belegt erst L-06. Neu: Ring 6, Auffahrer, Prüfsumme. Vorher unentdeckt: `vehicle_pos` lief über (int32) und gab für fahrende Fahrzeuge falsche Orte aus. Behoben, Test K4.
- **Pairing Aylin: teilweise.** 10 Antworten und Feldtabelle liegen schriftlich vor. Aylins Gegenbestätigung fehlt (keine echte Sitzung).
- **F-05: in Arbeit.** `f05_benchmark.md`, `bench_results.csv`, `bench_summary.csv`, `bench_soa_results.csv`. 18 + 9 Läufe **auf der Sandbox gemessen** (2 vCPU, Editor-Binary). Spike 10k/1×: Median 67,4 ms, p95 98,2 ms. SoA-Bewegungskern 10k: 2,18 / 4,73 ms. AK **nein**: kein Zielrechner, kein Release-Export, 3.000 Ticks statt 5 min (Abweichung dokumentiert). Zählt nicht für G2 (V).
- **Vorab-Einschätzung:** GDScript bleibt, **bedingt** (SoA-Umbau, ereignisgesteuerte Deadlock-Prüfung, Messpunkt Zielrechner). Spike-Sim am Zielrechner = Rot erwartet.
- **float32-Check: fertig.** `float32_check.md`. Bei 512² höchstens 0,24 mm Fehler, kein Origin-Shifting nötig.
- **F-06: geschätzt, nicht gebaut.** `f06_vorbereitung.md`: 1,35 T statt 1 T. Build realistisch 24.11., **12:00 statt 10:00**.
## Annahmen und offene Fragen an andere
- **Aylin:** Dreiergruppe (Signal, Abschnitt, Halter) = eine Kettenzeile? Typ/Code-Tabelle als Datei.
- **Daniel:** Wende-Deadlock (Hold-and-Wait) als bekannte Ursache oder als Fehlalarm? Drittes D-04-Szenario als API-Aufruf.
- **Katrin:** Zielrechner plus Export-Templates 4.4.1; ohne beides bleibt G2 offen.
- **Jonas:** Am Zielrechner beide Runner messen. Zählt SoA als Teil-Beleg (Gelb mit Auflage)?
- **Lena:** Namen final für die Namenstabelle in F-06.
- Annahme: 1 px ≈ 36 mm bei der Nahstufe (nicht gemessen).
## Risiko für das Sprintziel
G2 ist ohne Zielrechner nicht messbar. Gemessen würde nur der Spike, und der ist Rot. Ohne Zielrechner bis 24.11. gilt nach D8 „Vertagen“. F-06 braucht den Puffer vollständig; jede weitere Anforderung schiebt den Build hinter 12:00 und damit den Testtag auf den 26.11.
