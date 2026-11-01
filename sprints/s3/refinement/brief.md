# Refinement Sprint 3 (Sprint 30.11.–11.12.2026) – Briefing

Release R1 "Spielbarer Loop" (S3–S5, Review 15.01.). Gate M0 wurde am 27.11. auf 02.12. VERTAGT (Datei /tmp/claude-0/gd/sprint2/day7-10/gate/gate_m0.md): bis 02.12. braucht es L-06 mit 6 echten Testern und L-05 mit 3 Runden (beides führt der Auftraggeber Basti selbst durch, das Team liefert nur Material/Build), F-05 als Release-Export mit Deadlock-Prüfung, den F-08-Record (Kartengröße) und die Slice-Schätzung. Sprint 3 startet trotzdem.
PO-Entscheidungen 27.11.: /tmp/claude-0/gd/sprint2/day7-10/gate/entscheidungen_27-11.md (3 Ketten im Slice; Kenney als Platzhalter für Natur/Industrie-Anbauten/Schiff mit Faktor je Kit, Fahrzeuge nein; SoA-Umbau ja, Deadlock-Prüfung ereignisgesteuert; kanonischer Ort nach Felix; Wende-Deadlock = DEADLOCK).
Retro-Verbesserungen: /tmp/claude-0/gd/sprint2/day7-10/gate/retro_s2.md.
Echte Messung am Zielrechner (Bastis PC, Ryzen 7 5800X3D, Godot 4.7.2): Spike-Kern 10k = 22–26 ms/Tick (Rot), SoA 10k = 1,9 ms (ohne Deadlock-Prüfung). Der Zielrechner ist ab jetzt über Godot-MCP erreichbar.

NEUE GRUNDREGEL DES AUFTRAGGEBERS (verbindlich, D15): "Was es in anderen Spielen schon gibt, erfinden wir nicht neu und erforschen es nicht mühsam." Genre-Standards (TF2, OpenTTD, Railway Empire, Cities Skylines, Anno) sind die Grundlage: z. B. Klick auf ein Objekt öffnet einen Dialog mit kontextbezogenen Infos und Aktionen; Strecken-/Straßenbau per Ziehen mit Raster-Snap, Ghost-Vorschau, Kosten am Cursor. Diese Muster werden direkt beschrieben und gebaut, nicht vorher per Test "herausgefunden". Prototyp-Bau muss nicht perfekt sein. Spikes und Tests nur noch dort, wo wir bewusst vom Genre abweichen oder verfeinern (Diagnose mit Ort+Ursache, Lizenz→Kauf-Leiter, HQ-Start, Skilltree-Ränge, Energie-Radius, Lager als Hub, Ketten-Logik). Konsequenz: Tickets, die Standardverhalten "untersuchen", werden zu Bau-Tickets mit Referenz ("wie OpenTTD/TF2: …").

Kandidaten (vorläufig, Owner und Tage; Kapazität je Person 8 T, Felix einziger Programmierer, ein Gameplay-Programmierer ab Januar):
| ID | Ticket | Owner | T |
|---|---|---|---|
| F-10 | Sim-Kern auf SoA umbauen (Fahrzeuge, Reservierung), Determinismus/Prüfsumme bleibt | Felix | 4 |
| F-11 | Deadlock-Prüfung ereignisgesteuert (nur bei neuem Warten) | Felix | 1,5 |
| F-12 | Release-Export-Pipeline Windows + Messung am Zielrechner (G2-Nachweis bis 02.12.) | Felix, Daniel | 1 |
| F-13 | Bau-Tool nach Genre-Standard (Ziehen, 45°-Snap, Ghost weiß/rot, Kosten am Cursor, Abriss, Undo) – Referenz OpenTTD/TF2 | Felix | 3 |
| F-14 | Grey-Box-Slice-Karte 512² mit 3 Ketten, Städten, Gelände (Kenney-Platzhalter) | Felix, Sophie | 3 |
| A-07 | Kontextdialog-Standard: Klick auf Industrie/Stadt/Fahrzeug/Station öffnet Panel mit Infos + Aktionen (Referenz TF2/Anno), Spezifikation | Aylin | 2 |
| A-08 | Diagnose-Meldung mit sichtbarem Vorschlag/Aktion (Test hat gezeigt: ohne Handlung Abbruch), Kontextdialog-Anbindung | Aylin | 1,5 |
| L-07 | Material und Ablaufplan für Bastis echte Tests L-06/L-05 bis 02.12. (Tester-Briefing, Bogen, Build-Anleitung) | Lena | 1,5 |
| L-08 | Spielregeln Slice-Loop schriftlich (HQ → Lizenz → Lieferung → Kauf → Ausbau) als Spec für Felix | Lena | 2 |
| T-06 | Ökonomie in die Sim (Ertrag nur beim Endabnehmer, Lizenz/Kauf/Kredit) als Datenmodell + Werte | Tobias | 3 |
| T-07 | Exploit-Katalog v1 mit Gegenregeln | Tobias, Daniel | 1 |
| F-09b | JSON-Konvention Rest + CI-Validator, Abzeichnung Felix | Tobias | 1,5 |
| S-07 | Kenney-Import mit Skalierungsfaktoren je Kit, Statusformen (S-05) in UI-Atlas | Sophie | 2 |
| S-08 | Slice-Look v1 in Grey-Box (Licht, Palette, Kartenstufe als Scroll-Ansicht) | Sophie | 3 |
| D-06 | Testautomatisierung: Smoke + D-04 + Bench im CI, Messlauf am Zielrechner per MCP pro Sprint | Daniel | 2 |
| J-06 | Slice-Ziel und Pfeiler-Checkliste nach D15 aktualisieren; was ist Genre-Standard, was ist unser Unterschied (Liste) | Jonas | 1 |
| K-08 | Gate 02.12. organisieren, Termine mit Basti, Slice-Schätzung im Refinement | Katrin | 1,5 |
Summe deutlich über Kapazität bei Felix.
