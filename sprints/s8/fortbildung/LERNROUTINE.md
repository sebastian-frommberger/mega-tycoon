# Lern-Routine für alle Rollen-Skills (gültig ab 2026-11-03)

Auftrag von Basti: Jeder Skill enthält eine Routine, die regelt, (1) wann Insights in den Skill aufgenommen werden und (2) vor allem, wann Skill und Allgemeinwissen nicht reichen und die Rolle erneut recherchiert. Beispiele von Basti: "Ich musste x-mal einen Kompromiss eingehen" oder "ich wusste die Antwort nicht, deshalb recherchiere ich jetzt".

Die verbindliche Kurzfassung steht in jedem `SKILL.md` (Abschnitt "Lern-Routine"). Hier die Begründung und die Handhabung.

## Ablauf in einem Satz
Wissenscheck, bei Lücke laut ansagen und recherchieren, Ergebnis belegt in den Skill, jeden Kompromiss ins LERNLOG zählen.

## Trigger zur Recherche (a bis h)
a) Ich weiß es nicht oder rate. b) Derselbe Kompromiss oder Workaround zum 2. Mal. c) Eintrag steht unter "Offene Lücken" oder ist [E]/[W]/niedrig, und die Entscheidung hängt daran. d) Skill, Repo, Doku oder Messung widersprechen sich. e) Engine, Tool oder Version ist neuer als der Skill-Stand. f) Basti korrigiert oder eine Entscheidung wird zurückgenommen. g) Teure oder unumkehrbare Entscheidung bei Konfidenz unter mittel. h) Derselbe Fix scheitert 2x.

Warum 2x bei b): Ein Kompromiss ist normal. Der zweite gleiche Kompromiss zeigt ein Muster, das Wissen oder Werkzeug fehlt. Damit das nicht im Gedächtnis hängt, zählt das LERNLOG.

## Wann nicht recherchieren
- Billig prüfbar: Test, Doku-Dump greppen, Mini-Versuch gehen vor Web.
- Geschmacks- und Designfragen: Prototyp oder Basti entscheidet, das Web liefert hier nur Meinungen.
- Reddit bleibt blockiert (SITE_BLOCKED); nicht umgehen.

## Aufnahme von Insights
Alle vier Bedingungen: wiederverwendbar (2x gebraucht oder über 1 Stunde Aufwand), belegt (Messung, Quelle oder Basti), noch nicht im Skill, kein Tagesstand. Sofort aufnehmen bei Basti-Korrektur, bestätigtem Fehler im Skill oder Engine-Falle mit Repro. Alles andere sammelt die Rolle im LERNLOG und nimmt es zum Sprintende in der Retro auf.

Pflege: eine Zeile mit Belegmarke, Datum, Quelle. Widerspruch ersetzt den alten Eintrag (nicht anhäufen). Geschlossene Lücke aus "Offene Lücken" streichen. Der kompakte Skill bleibt bei ca. 10.000 Zeichen; Details gehören in die Vollfassung im Repo.

## Wo wird gespeichert
- Repo: `sprints/s8/fortbildung/<rolle>/SKILL.md` (Vollfassung), `LERNBERICHT.md`, `LERNLOG.md`.
- Account-Skill: nur per Vorschlagskarte (`propose_skills`), Basti speichert. Die Rolle schlägt vor, sobald ein Insight die vier Bedingungen erfüllt, spätestens zum Sprintende gebündelt.

## Rollen-Trigger
Jeder Skill nennt zusätzlich typische Trigger der eigenen Disziplin (Zeile "Rollen-Trigger").

## Retro-Auswertung (Sprintende, Katrin moderiert, Daniel liest mit)
1. LERNLOG je Rolle: Zähler 2 oder höher? Wurde recherchiert? 2. Welche Lücken sind geschlossen, welche bleiben? 3. Welche Skill-Einträge wurden durch Messung widerlegt? 4. Ein Vorschlagspaket an Basti.
