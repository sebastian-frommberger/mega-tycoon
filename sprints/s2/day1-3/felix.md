# Felix – Sprint 2, Tag 1–3
## Daily Tag 1 (16.11.)
Gestern: Brief und Plan gelesen. Heute: Graph, Blöcke, Signale, A*, SimWorld mit festem Tick. Blocker: keiner.
## Daily Tag 2 (17.11.)
Gestern: Netz und Sim stehen. Heute: Warte-Graph, Zykluserkennung, `get_wait_chain()`, Szenarien. Blocker: Aylins Felder lagen nicht als Datei vor, Pairing nicht belegt, deshalb Annahme.
## Daily Tag 3 (18.11.)
Gestern: Diagnose und Tests geschrieben. Heute: Testlauf, Mutationsprobe, Übersicht; F-05 nicht begonnen. Blocker: Felder-Abgleich mit Aylin offen.
## Ergebnisse
**F-04: in Arbeit, Code und Tests fertig, Übergabe offen (Restaufwand ca. 0,5 T).**
Liegt vor in `felix/spike/`: `project.godot`, `net_graph.gd`, `sim_world.gd`, `diagnostics.gd`, `scenarios.gd`, `test_runner.gd`, `test_output.txt`. Start: `godot --headless --path felix/spike --script res://test_runner.gd`.
- Drei Szenarien headless, Exit 0: **ja**, Beleg `test_output.txt` (echter Lauf, Godot 4.4.1, 72 ms, alle Prüfungen grün).
- Deadlock in ≤ 50 Ticks: **ja**, gemessen Gegenverkehr 4 Ticks, Kreis 4 Ticks (Zyklus gebildet Tick 101 bzw. 51, erkannt 105 bzw. 55). Die 4 sind kein Rechenerfolg, sondern Parameter `DEADLOCK_CONFIRM_TICKS = 5` (Zyklus muss 5 Ticks bestehen).
- Wurzelursache plus Koordinaten: **ja**. Erwartungswerte (Typ, Kettenlänge, root_pos) sind von Hand ins Test-Skript geschrieben. Mutationsprobe: Bestätigungsfenster 60 oder Klassifikation vertauscht lässt den Runner mit Exit 1 scheitern.
- Jedes A-05-Feld geliefert oder als fehlend markiert: **teilweise** (Tabelle unten, ohne Abgleich mit Aylin).
- Spike-Build an Daniel 19.11.: **offen**.
- Extra: A* = AStar2D-Pfadkosten (20 Paare); Kontrolle 10 min (6000 Ticks), 0 Meldungen bei 1140 Warte-Ticks, nur für dieses Layout.

**Diagnose-Felder (Eingang für Aylin)**
| Feld | Stand |
|---|---|
| Ort | liefert: `root_pos` plus `pos` je Kettenglied (mm). |
| Ursache | liefert: Typ `DEADLOCK`, `EINGLEISIG_GEGENVERKEHR`, `WARTEN_AUF_LADUNG`, dazu `BLOCK_BELEGT_UNTERWEGS`, `KEINE`. Nicht unterschieden: Geld, Nachfrage, fehlende Infrastruktur. |
| Vorschlag | teilweise: nur `suggestion_id`, fest je Ursache gemappt, nicht berechnet. Kein Text, keine Kosten, keine Alternativen. |
| Kette | liefert: geordnete Glieder Fahrzeug, Signal, Block, Halter, Lager, Industrie, plus `cycle`, `wait_ticks`. |
| fehlt | Schweregrad, Bündelung gleichartiger Meldungen, Push-Ereignis (nur Pull-API plus `deadlock_events`), Textvorlagen. |

Grenzen: nur gerade Kanten, nur ein Block Vorausreservierung (kein Pfadsignal), Kreis-Routen explizit.
## Annahmen und offene Fragen an andere (mit Namen)
- Annahme: Aylins Felder (Ort, Ursache, Vorschlag, Kette) wie im Ticket; keine Datei von ihr gesehen. **Aylin:** Reicht Typ plus ID, oder braucht die Meldung Text und Schweregrad aus der Sim?
- Annahme: Gegenverkehr heißt Zyklus aus lauter Gegenrichtungs-Waiten auf eingleisigen Blöcken. **Lena:** Passt das zu deinem Szenario "fehlendes Ausweichgleis"?
- **Daniel:** Übergabe 19.11. als Ordner plus Aufruf oben; Seeds für D-04 fehlen, der Spike hat keinen PRNG.
## Risiko für das Sprintziel (1–3 Sätze, ehrlich)
Die Leitfrage ist für drei Spezialfälle bejaht, nicht für beliebige Netze. Größtes Risiko: offener Feldvertrag mit Aylin und D-04-Fälle, die der Spike nicht abdeckt.
