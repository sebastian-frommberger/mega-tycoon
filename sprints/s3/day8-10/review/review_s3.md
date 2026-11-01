# Sprint-Review S3 (11.12.2026) – Katrin Vogel (Moderation), Jonas Weber (Abnahme)

## Sprintziel
| Teil | Stand |
|---|---|
| SoA-Kern, Deadlock, 10k ≤4,0 ms, p99 ≤6 ms, bit-identisch | **Ja** (Zielrechner, Editor-Build: Median 2,27–2,32 ms, p99 3,3–3,8 ms; Prüfsummen identisch, auch zur Linux-Sandbox; Deadlock 10 von 10) |
| Windows-Export am Zielrechner | **Nein** (F-12 offen: Export-Templates fehlen) |
| Bau per Ziehen | **Teilweise** (38/38 und 48/50 Tests, 0 Geld-Exploits; B-01; echter Mausdrag nie von Hand getestet) |
| Slice-Regeln als validiertes JSON | **Teilweise** (valide, aber Schema-Lücken B-03) |
| Stretch | Undo: nein. S-09-Karte: als JSON/PNG da, nicht im Testbuild |

Offen: 8x-Tempo kostet bei 10k ca. 19 ms pro Frame (Budget 8 ms), Entscheidung nötig.

## Ticket-Endstatus
| Status | Tickets |
|---|---|
| Done | F-10, F-11, F-06-Testbuild (Labels, Standzeit), S-07, A-07, L-07 |
| Mit Auflagen | F-13 (B-01, B-02, B-04), T-06 (B-03), T-07 (Daniels 20 Exploits abgenommen; Tobias' Datei fehlt), L-08 (Entwurf, D19-Korrektur, Seitenumfang ungeprüft), S-09 (Kartenschema nicht von Tobias abgezeichnet; Fläche ungleich genutzt), A-09 (Entwurf, Abgleich mit L-08 offen) |
| Nicht Done | F-12, T-11 (Bankrott 7 % statt 10–30 %), A-08, S-08, D-06, J-06, K-08; F-09b ohne Beleg in den Berichten |
| Gestrichen/geschoben | L-09 (D16, gestrichen); F-14, Undo, F-15, Skilltree (S4) |

Review-Punkt Sophie: Alle Ketten liegen links-mittig, die rechte Hälfte der 512²-Fläche ist fast leer (spielbarer Kern ca. 250×290).

## Demo für Basti in Godot (C:\Dev\mega-tycoon\…, Zuordnung der Ordner vom Koordinator bestätigen)
- Bau-Tool, Abriss [X]: `felix\prototype\main.tscn` (Ghost weiß/rot, Kosten am Cursor; bitte echten Mausdrag testen)
- Labels und Standzeit: `felix\f06\f06_main.tscn`
- Kernmessung: `_bench\bench_core.tscn`
- Kenney-Kits: `sophie\s07\proj\probe.tscn`
- Karte (nur Bild): `sophie\s09\slice_map.png`

## Offene Bugs
- **B-01 Mittel:** Linie nicht entfernbar, Abriss dauerhaft gesperrt.
- **B-02 Niedrig:** Gleis auf Stadtstraße kostet 0 $, Züge fahren trotzdem.
- **B-03 Mittel:** Schema ohne `required`, 81 von 275 Key-Löschungen unerkannt, Anteile über 100 % zulässig.
- **B-04 Niedrig:** Ghost auf Gras Kontrast ca. 1,5:1 (Ziel ≥3:1).

## Korrektur Demo-Pfade (Koordinator, geprüft im Repo/lokalen Klon C:\Dev\mega-tycoon)
- Bau-Tool F-13: `prototype\` öffnen, F5 → [B] Firma kaufen → [1]/[2] ziehen, [X] Abriss
- Diagnose-Testbuild F-06 mit Ortslabels: `spikes\f04-signal\` öffnen, F5
- SoA-Kern F-10/F-11: `spikes\sim-core\` (headless Tests); Messszenen `prototype\_bench\bench_core.tscn` (nur lokal) bzw. `tools\bench-zielrechner\sim-core\`
- Slice-Karte S-09: `sprints\s3\day4-7\sophie\s09\slice_map.png` und `slice_map.json`
- Kenney-Probeszene S-07: `sprints\s3\day4-7\sophie\` (Unterordner der Probeszene)
