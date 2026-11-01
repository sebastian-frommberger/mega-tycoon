# Refinement Sprint 2 (16.11.–27.11.2026) – Briefing

## Neue Arbeitsweise (nach Clinton Keith, „Agile Game Development“)
- Es gibt **kein separates Sprint Planning** mehr. Das **Refinement** am Ende des laufenden Sprints legt Sprintziel, Sprint-Backlog und Akzeptanzkriterien verbindlich fest. Am Sprintstart gibt es nur einen 15-min-Zielcheck.
- **Releases** bündeln mehrere Sprints unter einem Release-Ziel: R0 Vorproduktion (S1–S2, Gate 27.11.), R1 Spielbarer Loop (S3–S5, Review 15.01.), R2 Vertical Slice (S6–S10, Gate 26.03.).
- **Phasen:** Vorproduktion = Spaß und Machbarkeit finden → Spikes statt Features. Produktion = Scrum für Code/Design, Kanban für Art/Audio. Beta = Kanban.
- **Spike:** Leitfrage + Timebox in Tagen + Ergebnis (Entscheidung oder Messwert). Akzeptanzkriterium = Frage beantwortet und dokumentiert, nicht „Feature fertig“. Spike-Code ist Wegwerfcode.
- **User Story** (nur wo schon Produktion): „Als Spieler … möchte ich … damit …“ + Akzeptanzkriterien (Gegeben/Wenn/Dann) + Story Points.
- **Asset-Karten** (Art/Audio) laufen auf dem Kanban-Board (Briefing → Blockout → Modell → Textur/Material → Import → Abnahme), WIP-Limit 2 pro Person, nicht im Sprint-Commitment.
- **Spielgefühl** wird über Playtest-Messgrößen abgenommen (z. B. „4 von 6 finden die Ursache in < 30 s“).
- Kapazität Sprint 2: 10 Arbeitstage, davon ca. 8 Tage für Tickets pro Person. Felix ist einziger Programmierer.

## Sprintziel-Entwurf S2
„Der Diagnose-Playtest mit kaputtem Netz ist gelaufen, Benchmark und Bau-Spike liegen vor – das Gate am 27.11. kann Go/No-Go entscheiden.“

## Kandidaten (vorläufige Schätzung in Tagen/SP, Summe 90 SP – zu viel)
| ID | Ticket | Owner | SP | Epic |
|---|---|---|---|---|
| F-03 | Graph-Netz und Route-Caching | Felix | 3 | E2 |
| F-04 | Signal-/Reservierungs-Spike mit Diagnose-API | Felix | 8 | E2, E3 |
| F-05 | MultiMesh und Benchmark 10.000 Fahrzeuge | Felix | 5 | E1 |
| F-06 | Testbuild für den Diagnose-Playtest | Felix | 2 | E12 |
| F-07 | Bau-Tool-Spike 45° mit Kurvenglättung | Felix | 5 | E4 |
| F-08 | Terrain-Entscheidung und Kartengröße | Felix | 2 | E1 |
| F-09 | JSON-Datenformate mit Tobias | Felix, Tobias | 2 | E1, E5 |
| L-03 | Onboarding-Meilensteinleiste v1 mit HQ und Lizenzen | Lena | 3 | E6 |
| L-04 | Skilltree E1 als Datentabelle | Lena | 3 | E8 |
| L-05 | Paper-Prototyp HQ-Start und Lizenz-Leiter | Lena | 3 | E6 |
| L-06 | Diagnose-Playtest: Szenario, Durchführung, Auswertung | Lena, Aylin, Daniel | 5 | E12 |
| T-04 | Sättigung und Stadtwachstum simulieren | Tobias | 3 | E5, E7 |
| T-05 | Startkapital und Lizenz/Kauf-Leiter neu rechnen | Tobias | 3 | E6 |
| T-06 | Balance-Targets und Exploit-Katalog | Tobias, Daniel | 2 | E5, E11 |
| T-07 | Headless-Simulation der Ökonomie | Tobias | 5 | E5 |
| A-04 | Problem-Feed mit Ursachenkette als Klickprototyp | Aylin | 3 | E3, E9 |
| A-05 | Diagnose-Datenvertrag | Aylin, Felix | 2 | E3 |
| A-06 | Bau-Tool-Spike UX begleiten | Aylin | 2 | E4 |
| S-03 | Look-Test Diorama vs. Karte | Sophie | 5 | E10 |
| S-04 | Kamera, Nebel, Licht | Sophie | 3 | E10 |
| S-05 | Farbatlas und Farbsehschwäche-Prüfung | Sophie | 3 | E10 |
| S-06 | Silhouetten-Sheet und Asset-Liste Slice | Sophie | 5 | E10 |
| D-04 | Signal-Spike mit 6 Deadlock-Szenarien testen | Daniel | 3 | E11 |
| D-05 | Benchmark auf Zielhardware mitmessen | Daniel | 2 | E11 |
| K-06 | Diagnose-Playtest organisieren | Katrin | 2 | E12 |
| K-07 | Slice-Backlog schätzen, Gate M0 vorbereiten | Katrin | 3 | E12 |
| J-05 | Pillar-Review der Spikes, One-Pager, Go/No-Go-Empfehlung | Jonas | 3 | E12 |

## Hintergrund
- Konzept: /tmp/claude-0/gd/concept/*.md
- Persönliche To-dos mit Details: /tmp/claude-0/gd/plan/<vorname>.md
- Bekannte Konflikte: Felix ist im Sprint 2 laut eigener Planung > 100 % ausgelastet (Benchmark, Signal-Spike, Bau-Spike, Testbuild, Terrain, Datenformat); viele Tickets anderer hängen an ihm (Diagnose-Playtest braucht Signal-Spike + Testbuild; Aylins Datenvertrag; Tobias' Headless-Sim braucht SimWorld-Schnittstelle; Sophies Look-Test braucht MultiMesh-Szene).
