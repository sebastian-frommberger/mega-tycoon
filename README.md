# Mega Tycoon

Transport-Tycoon-Spiel in Godot 4 (Zielversion 4.7.2 (Spikes zusätzlich mit 4.4.1 getestet)). Fokus: logische Güterketten, lesbare Diagnose ("Ort + Ursache"), HQ-Start mit Lizenzen statt Firmenkauf.

Das Team (Jonas, Lena, Tobias, Aylin, Felix, Sophie, Daniel, Katrin) ist simuliert. Alle Ergebnisse ohne echte Tester oder Zielhardware sind als synthetisch, Rechnung oder Voraussetzung gekennzeichnet, nie als Messwert.

## Struktur

| Ordner | Inhalt |
| --- | --- |
| `slice/` | Vertical Slice (Grey-Box, R1): 512²-Karte aus JSON, Ökonomie aus JSON, Startdialog, Lizenz-Knopf, Windows-Export-Presets |
| `prototype/` | Prototyp v3: 192×192-Karte, 5 Städte, 5 Ketten, Lkw/Zug, Lager, Meilensteine |
| `spikes/f04-signal/` | Netz-, Signal- und Diagnose-Spike (Felix), headless testbar |
| `spikes/sim-core/` | Sim-Kern auf SoA mit ereignisgesteuerter Deadlock-Prüfung (Sprint 3, F-10/F-11) |
| `spikes/s03-look/` | Look-Test Diorama vs. Karte (Sophie) |
| `design/economy/` | Startkapital, Lizenz/Kauf-Leiter, Stadtwachstum (Tobias, Python) |
| `design/ux/` | Diagnose-Datenvertrag, Textvorlagen, Testskript (Aylin) |
| `design/game-design/` | Playtest-Szenario, HQ-Startwerte, Paper-Prototyp, Widersprüche (Lena) |
| `design/qa/` | Prüfpläne D-04, Benchmark, Farbcheck, Testbarkeit (Daniel) |
| `design/art/` | Statusformen, Palette, Asset-Liste, Kenney-Messung (Sophie) |
| `design/po/` | Pillar-Fragen, Gate-Kriterien (Jonas) |
| `design/production/` | Daily, Sprintziel-Check, Gate-Gerüst (Katrin) |
| `concept/` | Konzeptdateien je Disziplin, Leitplanken |
| `plan/` | Projektplan je Person |
| `refinement/` | Refinement Sprint 2 (Positionen und Ergebnis) |
| `sprints/s2/` | Briefings, PO-Entscheidungen, Daily-Übersichten je Tag-Block |
| `tools/bench-zielrechner/` | Benchmark-Szenen für Messläufe auf dem Zielrechner (Godot-MCP) |
| `assets/kenney/` | Kenney-Probemodelle (CC0) |

## Starten

```
# Prototyp
godot --path prototype

# Signal-Spike-Tests (Exit 0 = alle Szenarien grün)
godot --headless --path spikes/f04-signal --script res://test_runner.gd
```

## Arbeitsweise

Scrum nach Clinton Keith: Refinement ersetzt das Planning, Spikes mit Leitfrage und Timebox in der Vorproduktion, Art auf Kanban. Ein Branch pro Ticket (`f-04-...`), Merge nach Review durch QA. Dokumentation in den Claude Docs des Projekts: Konzept, Projektplan, Scrum.

## Lizenzen

Kenney-Assets: CC0 (www.kenney.nl).
