# Lernlog mt-qa

Zweck: Kompromisse, Workarounds und "wusste ich nicht"-Momente zählen (Lern-Routine, Punkt 5). Zähler 2 für dasselbe Thema löst eine Recherche aus (Trigger b). Geschlossene Lücken wandern in den Skill, dann hier als erledigt markieren.

| Datum | Situation | Kompromiss / Lücke | Zähler | Folge (Recherche, Quelle, Skill-Eintrag) |
|---|---|---|---|---|
| 2026-11-03 | Einführung der Routine | (noch kein Eintrag) | 0 | |
| 2026-11-03 | Abnahme A21 | Wall-Clock-Assertion mit aufgeweiteter Toleranz (tmax <= 150+40 ms) | 2 | Tick-Assertion statt Zeit; im Repo bei d07_abnahme.gd:271 bestätigt |
| 2026-11-03 | Integration W2 | Regression nicht neu gelaufen | 2 | Pflichtlauf |
| 2026-11-03 | Perf-Aussagen | Zählwert statt Livewert | 3 | Messart-Feld in jeder Perf-Zahl |
| 2026-11-03 | Validator/Spiel | Verschiedene Regeln in Spiel und Validator | 2 | Gemeinsamer Test vorgeschlagen |
| 2026-11-05 | QT-01a Baseline | Veralteter Klassencache (.godot) nach Fast-Forward: Proto-Suite hing 10+ min ohne quit; ersten d07-Lauf (747 s) verworfen. Wusste ich nicht: neue class_name-Dateien brauchen --import, Suiten ohne timeout hängen bei Parse-Fehler | 1 | timeout je Aufruf (regress_fast/d07), Hinweis in QT-01.md; bei 2. Mal Skill-Eintrag |
