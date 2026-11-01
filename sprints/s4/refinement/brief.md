# Refinement Sprint 4 (14.–25.12.2026) – Briefing
Release R1 "Spielbarer Loop" (Review 15.01.). Sprint 4 ist der letzte Sprint vor dem R1-Review (S5 im Januar mit Gameplay-Programmierer).
Grundregeln: D15 Genre-Standards übernehmen (Referenz nennen), Arbeit nur in unsere Unterschiede; D16 keine externen Tester, Basti testet selbst.
Stand: /tmp/claude-0/gd/sprint3/day8-10/review/review_s3.md, retro_s3.md, s4_kandidaten.md; Entscheidungen /tmp/claude-0/gd/sprint3/decisions_04-12.md.
NEU: Export-Templates 4.7.2 sind auf dem Zielrechner (Bastis PC) installiert → F-12 Release-Export möglich. Godot-MCP auf dem Zielrechner hat ein Export-Toolset. Ein exportiertes .exe kann der Koordinator nicht selbst starten; Basti müsste es einmal doppelklicken (Ergebnisdatei neben der .exe ablegen, dann liest der Koordinator sie).
Kandidaten (Owner, Tage grob):
| ID | Ticket | Owner | T |
|---|---|---|---|
| F-14 | Grey-Box-Slice: Karte aus S-09-JSON laden (Städte, Industrien, Gelände), Fläche ausgeglichen | Felix 4, Sophie 1 | 5 |
| F-16 | Ökonomie aus T-06-JSON im SoA-Kern: Ertrag nur beim Endabnehmer, Luftlinie, Herkunftsstempel, Sättigung, Lizenz/Kauf/Kredit | Felix 2,5, Tobias 1 | 3,5 |
| F-15 | Kontextdialog (A-07) und Lizenz-Kauf-Flow (A-09) als Godot-UI | Felix 3, Aylin 1 | 4 |
| A-08 | Diagnose-Meldung mit Ein-Klick-Aktion (Spec + Bau) | Aylin 1,5, Felix 1 | 2,5 |
| F-12 | Release-Export + Messung am Zielrechner (Bench als .exe, Ergebnis neben .exe) | Felix 1, Daniel 0,5 | 1,5 |
| F-17 | 8×-Tempo-Entscheidung umsetzen (z. B. Sim-Thread oder 8× nur bis 5k) | Felix 1 | 1 |
| B-01..04 | Bugs Bau-Tool und Schema (B-03 required-Listen) | Felix 1, Tobias 0,5 | 1,5 |
| T-12 | Kalibrierung nach T-11 (Bankrott 10–30 %), auf Grey-Box nachrechnen | Tobias 1,5 | 1,5 |
| L-10 | Holz/Baustoff-Lücke im Slice lösen (Regel oder kleine Quelle), L-08 korrigieren (Stufe 2 = 2.000 $) | Lena 1,5 | 1,5 |
| S-10 | Slice-Karte überarbeiten: Fläche ausgleichen, Abstände großzügig | Sophie 1,5 | 1,5 |
| S-08 | Look Lesbarkeit (Kontrast ≥ 3:1, Ghost-Kontrast B-04) | Sophie 1,5 | 1,5 |
| D-06 | CI/Testautomatisierung + Messlauf am Zielrechner pro Sprint | Daniel 2 | 2 |
| J-07 | R1-Review vorbereiten: Demo-Skript für Basti, Pfeiler-Checkliste | Jonas 1 | 1 |
Felix-Last weit über 8 T (Weihnachtswoche: 22.–25.12. nur 2 Tage → Kapazität je Person 7 T).
