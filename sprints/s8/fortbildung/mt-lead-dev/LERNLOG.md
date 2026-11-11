# Lernlog mt-lead-dev

Zweck: Kompromisse, Workarounds und "wusste ich nicht"-Momente zählen (Lern-Routine, Punkt 5). Zähler 2 für dasselbe Thema löst eine Recherche aus (Trigger b). Geschlossene Lücken wandern in den Skill, dann hier als erledigt markieren.

| Datum | Situation | Kompromiss / Lücke | Zähler | Folge (Recherche, Quelle, Skill-Eintrag) |
|---|---|---|---|---|
| 2026-11-03 | Einführung der Routine | (noch kein Eintrag) | 0 | |
| 2026-11-03 | Recherche | Skill behauptete atomares DirAccess.rename | 1 | Windows entfernt das Ziel zuerst (Engine-Quelltext). Skill-Korrektur vorgeschlagen; vor Übernahme selbst nachlesen |
| 2026-11-03 | Skill gegen Repo | set_buffer_interpolated als 'offen' geführt | 1 | Im Repo seit S4 (main.gd 3484/3485) bestätigt |
| 2026-11-03 | S7/S8 | Perf-Zahlen ohne Etikett (Messung/Schätzung, Szene/Welt) | 2 | Einheit, Szene, Messart Pflicht |
| 2026-11-03 | S8 | Regression ohne Zeitlimit | 1 | slice/tools/play.sh enthält 0 mal timeout (bestätigt); Suite-Aufteilung vorgeschlagen |
| 2026-11-13 | Demo Teil 5 (Ziehen) | Zwei Bedeutungen für die gehaltene linke Taste (Kamera schieben / Trasse ziehen) ließen sich nicht beide halten: die Kamera verliert sie im Baumodus und bekommt die mittlere Taste | 1 | Entscheidung im Entscheidungslog; geprüft in demo_ui_test B14 und demo_bau_befund N12. Offen: ob Mäuse ohne Mittelklick damit auskommen (WASD/Mausrad bleiben) |
| 2026-11-13 | Demo Teil 5 (Messung) | Messwert erst NACH dem Bau geholt: `knoten_richtung` gibt null zurück, sobald der Startknoten zwei Nachbarn hat — der Bogen erschien als r_min = inf | 1 | Regel: Angebotswerte vor dem Bau sichern. Kein Code-Fehler, Messfehler im Testskript (N13c korrigiert, Lauf wiederholt) |
