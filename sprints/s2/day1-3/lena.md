# Lena – Sprint 2, Tag 1–3
(Die Tageseinträge sind die Arbeitsreihenfolge meiner Sitzung, keine gemessenen Kalendertage.)

## Daily Tag 1 (16.11.)
Gestern: Brief, Plan, Refinement-Beschluss und Konzepte gelesen. Heute: Dateien von Felix, Aylin, Daniel, Jonas und Tobias gegen mein Ticket geprüft, Widersprüche gesammelt. Blocker: keiner.

## Daily Tag 2 (17.11.)
Gestern: Rechenbasis gelegt, Tobias' Modell unverändert nachgerechnet (Einkommen, Soft-Lock). Heute: HQ-Startwerte und Wachstumsgewichte geschrieben. Blocker: Frist 17.11. nur als Entwurf, Tobias hat bei seinem Abschluss meine Dateien nicht gesehen.

## Daily Tag 3 (18.11.)
Gestern: beide Dateien als Entwurf. Heute: Szenario, Zählregel, Plan B und Paper-Plan, Widerspruchsliste. Blocker: keine Rückmeldung von Felix, Aylin, Daniel zur Fehlerliste.

## Ergebnisse
- **L-06 Szenario: in Arbeit (Entwurf).** `lena/playtest_szenario.md`. Kriterium „3 Fehler mit Wurzelursache und Zielzeit dokumentiert“: **teilweise**. Fehler, Zählregel mit Grenzfällen, Protokoll-Bestätigung und Plan B stehen. Die Zielzeit ist nur die 60-s-Messgrenze, keine eigene Erwartung. Nicht abgestimmt, kein Build, keine Tester.
- **HQ-Startwerte und Wachstumsgewichte: geliefert als Entwurf, Bestätigung offen.** `lena/hq_startwerte.md`, `lena/wachstumsgewichte.md`. Kriterium „bis 17.11. an Tobias“: **teilweise**, Dateien existieren, ob sie bei ihm ankamen, ist offen. Zielzeiten bis zur ersten Gewinnkette sind Setzungen.
- **L-05 Paper-Prototyp: in Arbeit, Restaufwand ca. 0,75 T.** `lena/paper_prototyp_plan.md`. Kriterien (3 Runden, Kette, Startkapital, Kaufwunsch) **nicht erfüllbar vor 20.11.**, Material und Messung sind entworfen, nicht gedruckt.
- **Widersprüche:** `lena/widersprueche.md`, 24 Punkte mit Vorschlägen, keiner entschieden.

## Annahmen und offene Fragen an andere (mit Namen)
- **Tobias:** Option A (Startkapital 4.500 / 4.500 / 7.000 / 5.000 $) und Variante B (1,8 %, +25 %) bestätigen. Ausbaupfad und Kohle-Zufluss im Bergbau ergänzen.
- **Jonas:** Casual-Gefühl bei kleinem Kapital, Personenverkehr nur als Zuschlag, Plan-B-Wertung höchstens Gelb auch bei geskripteter echter Kette?
- **Felix:** Streckenlänge, Gleiszahl, Füllstand und `n_lkw` liefern, Fehler mindestens 120 s sichtbar.
- **Aylin, Daniel:** F2 mit 4 Zügen, Kreis muss benannt werden, Vorschlag im Test ausgeblendet, D-04-Szenarien neu schneiden.
- **Katrin:** externe Tester statt Kollegen für L-05, Einwilligungstext.
- Annahme: Preise, Ketten und Distanzen stammen von Tobias, die Zielzeiten 6 / 8 / 10 / 8 min sind Setzungen.

## Risiko für das Sprintziel
Die Messgröße ist wegen des Deckeneffekts leicht zu erreichen und mit n = 6 ein Münzwurf im mittleren Bereich. Fällt F-04 aus, zählt der Test höchstens Gelb. Das Gate-Kriterium Leiter braucht meinen Paper-Test, der noch keine Runde hatte.
